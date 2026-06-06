--[[ improvements v1 ] ==================================================
    ============================================================================
    1. string.sub(src, i, i): string.byte(src, i) for all single-character lookups
            strsub returns a 1-character string -> GC allocation every call.
            strbyte returns a plain number so noo GC allocation. in the main
            tokenizer loop, strsub was called on every single character of the
            sourcee, the single biggest source of GC garbage in the entire
            pipeline! strbyte eliminates ~22,000 string allocations per 1000
            lines of source transpiled... kinda dumb not to use strbyte right.

       what changed:
       - every if/while condition that compared a single character now uses
         strbyte and compares against a byte constant instead of a
         string literal, so no more nonsennse GC allocations
       - is_letter(), is_digit(), is_alphanum() now accept a byte
         instead of a 1-char string
       - the final error message uses strchar(c) to convert the byte back to
         a readable character for user

    2. Lua 5.0 32-upvalue limit (what a fun one):
            every local variable at file level becomes an upvalue for every
            inner function, with 35 individual BYTE_xxx locals, the tokenizer
            exceeded lua 5.0s hard limit of 32 upvalues, causing a load error:
            "too many upvalues (limit=32) near 'then'", hehe.

        solution: all byte constants are stored as fields of a single local
        table 'byte'. a table is just one upvalue regardless of how many fields
        it holds, so its no problem to exceed the limit.
        lua makes perfect sense, it just makes sense.
    ============================================================================
]]

local core = ___Lua51reg'tokenizer'

if ( core.TOKN ) then return end

local DEBG = DEBG
local error = error
local table = table
local string = string
local tgetn = table.getn
local strsub = string.sub
local strlen = string.len
local strrep = string.rep
local strbyte = string.byte
local strchar = string.char
local tinsert = table.insert

local byte = {
    A_UPPER    = 65,   Z_UPPER    = 90,
    A_LOWER    = 97,
    UNDERSCORE = 95,
    ZERO       = 48,   NINE       = 57,
    NEWLINE    = 10,   CARRIAGE   = 13,
    SPACE      = 32,   TAB        = 9,
    FORMFEED   = 12,   VTAB       = 11,
    SQUOTE     = 39,   DQUOTE     = 34,
    DOT        = 46,   DASH       = 45,
    LBRACKET   = 91,   RBRACKET   = 93,
    EQUALS     = 61,
    PLUS       = 43,   SUB        = 45,
    STAR       = 42,   SLASH      = 47,
    CARET      = 94,   PERCENT    = 37,
    TILDE      = 126,
    LT         = 60,   GT         = 62,
    HASH       = 35,
    LPAREN     = 40,   RPAREN     = 41,
    LBRACE     = 123,  RBRACE     = 125,
    SEMICOLON  = 59,   COLON      = 58,
    COMMA      = 44,
    X_LOWER    = 120,  X_UPPER    = 88,
    E_LOWER    = 101,  E_UPPER    = 69,
    BACKSLASH  = 92,   Z_LOWER    = 122,
}

local keywords = {
    ['and']      = true, ['break'] = true, ['do']    = true, ['else']   = true,
    ['return']   = true, ['then']  = true, ['true']  = true, ['until']  = true,
    ['elseif']   = true, ['end']   = true, ['false'] = true, ['for']    = true,
    ['function'] = true, ['if']    = true, ['in']    = true, ['local']  = true,
    ['nil']      = true, ['not']   = true, ['or']    = true, ['repeat'] = true,
    ['while']    = true,
}

local function is_letter(c) -- v2
    if not c then return false end
    return (c >= byte.A_LOWER and c <= byte.Z_LOWER) or
           (c >= byte.A_UPPER and c <= byte.Z_UPPER) or
           c == byte.UNDERSCORE
end

local function is_digit(c)
    if not c then return false end
    return c >= byte.ZERO and c <= byte.NINE
end

local function is_alphanum(c)
    return is_letter(c) or is_digit(c)
end

local function emit(tokens, typ, value, line, col)
    local token = { type = typ, value = value, line = line, column = col }
    tinsert(tokens, token)
    DEBG(2, "[tokenizer] Ln " .. line .. " Col " .. col .. " : " .. typ .. " '" .. value .. "'")
end

local function scan_identifier(src, pos)
    local start = pos
    while pos <= strlen(src) and is_alphanum(strbyte(src, pos)) do
        pos = pos + 1
    end
    local word = strsub(src, start, pos - 1)
    local typ = 'identifier'
    if keywords[word] then
        typ = 'keyword'
    end
    DEBG(2, "[tokenizer] scan_identifier: '" .. word .. "' -> " .. typ)
    return pos, typ, word
end

local function scan_number(src, pos, line, col)
    local start = pos
    local c = strbyte(src, pos)

    -- hex: 0x or 0X
    if c == byte.ZERO then
        local next = strbyte(src, pos + 1)
        if next == byte.X_LOWER or next == byte.X_UPPER then
            pos = pos + 2
            DEBG(2, "[tokenizer] scan_number: hex prefix at Ln " .. line .. " Col " .. col)
            local h = strbyte(src, pos)
            if not is_digit(h) and not (h >= 97 and h <= 102) and not (h >= 65 and h <= 70) then
                error("TOKN:  error at line " .. line .. " col " .. col .. ": malformed hex number")
            end
            while true do
                local b = strbyte(src, pos)
                if not b then break end
                if not (is_digit(b) or (b >= 97 and b <= 102) or (b >= 65 and b <= 70)) then break end
                pos = pos + 1
            end
            DEBG(2, "[tokenizer] scan_number: hex literal '" .. strsub(src, start, pos - 1) .. "'")
            return pos, 'number', strsub(src, start, pos - 1)
        end
    end

    -- decimal integer part
    while is_digit(strbyte(src, pos)) do
        pos = pos + 1
    end

    -- fractional parrt
    if strbyte(src, pos) == byte.DOT then
        local next = strbyte(src, pos + 1)
        if is_digit(next) then
            pos = pos + 1
            while is_digit(strbyte(src, pos)) do
                pos = pos + 1
            end
        else
            DEBG(2, "[tokenizer] scan_number: '" .. strsub(src, start, pos - 1) .. "'")
            return pos, 'number', strsub(src, start, pos - 1)
        end
    end

    -- exponent
    local e = strbyte(src, pos)
    if e == byte.E_LOWER or e == byte.E_UPPER then
        pos = pos + 1
        local sign = strbyte(src, pos)
        if sign == 43 or sign == 45 then  -- '+' or '-'
            pos = pos + 1
        end
        if not is_digit(strbyte(src, pos)) then
            error("TOKN:  error at line " .. line .. " col " .. col .. ": malformed number")
        end
        while is_digit(strbyte(src, pos)) do
            pos = pos + 1
        end
    end

    DEBG(2, "[tokenizer] scan_number: '" .. strsub(src, start, pos - 1) .. "'")
    return pos, 'number', strsub(src, start, pos - 1)
end

local function scan_short_string(src, pos, line, col)
    local quote = strbyte(src, pos)
    pos = pos + 1
    local start = pos
    DEBG(2, "[tokenizer] scan_short_string: opening " .. strchar(quote) .. " at Ln " .. line .. " Col " .. col)

    while pos <= strlen(src) do
        local c = strbyte(src, pos)

        if c == byte.BACKSLASH then
            local next_c = strbyte(src, pos + 1)
            if next_c == byte.Z_LOWER then
                pos = pos + 2
                while pos <= strlen(src) do
                    local wsc = strbyte(src, pos)
                    if wsc ~= byte.SPACE and wsc ~= byte.TAB and wsc ~= byte.FORMFEED and wsc ~= byte.VTAB and wsc ~= byte.NEWLINE and wsc ~= byte.CARRIAGE then
                        break
                    end
                    if wsc == byte.NEWLINE then
                        line = line + 1
                    elseif wsc == byte.CARRIAGE then
                        line = line + 1
                        if strbyte(src, pos + 1) == byte.NEWLINE then
                            pos = pos + 1
                        end
                    end
                    pos = pos + 1
                end
            else
                pos = pos + 2
            end
        elseif c == quote then
            local str = strsub(src, start - 1, pos)
            pos = pos + 1
            DEBG(2, "[tokenizer] scan_short_string: closed at Ln " .. line)
            return pos, 'string', str
        elseif c == byte.NEWLINE or c == byte.CARRIAGE then
            error("TOKN:  error at line " .. line .. " col " .. col .. ": unfinished string")
        else
            pos = pos + 1
        end
    end

    error("TOKN:  error at line " .. line .. " col " .. col .. ": unfinished string")
end

local function scan_long_bracket(src, pos, line)
    local start = pos
    local equals = 0
    pos = pos + 1

    while strbyte(src, pos) == byte.EQUALS do
        equals = equals + 1
        pos = pos + 1
    end

    if strbyte(src, pos) ~= byte.LBRACKET then
        DEBG(2, "[tokenizer] scan_long_bracket: not a long bracket at Ln " .. line .. ", returning pos")
        return pos, nil, nil, nil, false
    end

    pos = pos + 1
    DEBG(2, "[tokenizer] scan_long_bracket: opening with " .. equals .. " equals at Ln " .. line)

    local close = ']' .. strrep('=', equals) .. ']'
    local close_len = equals + 2

    while pos <= strlen(src) do
        if strbyte(src, pos) == byte.RBRACKET then
            local sub = strsub(src, pos, pos + close_len - 1)
            if sub == close then
                local full = strsub(src, start, pos + close_len - 1)
                pos = pos + close_len
                DEBG(2, "[tokenizer] scan_long_bracket: closed at Ln " .. line)
                return pos, 'string', full, line, true
            end
        end

        if strbyte(src, pos) == byte.NEWLINE then
            line = line + 1
        elseif strbyte(src, pos) == byte.CARRIAGE then
            line = line + 1
            if strbyte(src, pos + 1) == byte.NEWLINE then
                pos = pos + 1
            end
        end

        pos = pos + 1
    end

    error("TOKN:  error at line " .. line .. " col 1: unfinished long string")
end

local function count_newlines(str)
    local nl = 0
    local i = 1
    local len = strlen(str)

    while i <= len do
        local c = strbyte(str, i)
        if c == byte.NEWLINE then
            nl = nl + 1
        elseif c == byte.CARRIAGE then
            nl = nl + 1
            if strbyte(str, i + 1) == byte.NEWLINE then
                i = i + 1
            end
        end
        i = i + 1
    end

    return nl
end

function core.TOKN(src)
    DEBG(1, '=== TOKN START ===')
    local tokens = {}
    local len = strlen(src)
    local pos = 1
    local line = 1
    local col = 1

    ---> the dispatch loop <---
    while pos <= len do
        local c = strbyte(src, pos)

        -- whitespace is here -->------------------>----------------------->
        if c == byte.SPACE or c == byte.TAB or c == byte.FORMFEED or c == byte.VTAB then
            pos = pos + 1
            col = col + 1

        elseif c == byte.NEWLINE then
            pos = pos + 1
            line = line + 1
            col = 1

        elseif c == byte.CARRIAGE then
            pos = pos + 1
            if strbyte(src, pos) == byte.NEWLINE then
                pos = pos + 1
            end
            line = line + 1
            col = 1

        -- comment: --
        elseif c == byte.DASH and strbyte(src, pos + 1) == byte.DASH then
            pos = pos + 2
            col = col + 2

            local next = strbyte(src, pos)
            if next == byte.LBRACKET then
                local new_pos, typ, val, new_line, is_long = scan_long_bracket(src, pos, line)
                if is_long then
                    local i = 1
                    local vlen = strlen(val)
                    while i <= vlen do
                        local ch = strbyte(val, i)
                        if ch == byte.NEWLINE then
                            line = line + 1
                            col = 1
                        elseif ch == byte.CARRIAGE then
                            line = line + 1
                            col = 1
                            if strbyte(val, i + 1) == byte.NEWLINE then
                                i = i + 1
                            end
                        else
                            col = col + 1
                        end
                        i = i + 1
                    end
                    pos = new_pos
                else
                    while pos <= len do
                        local ch = strbyte(src, pos)
                        if ch == byte.NEWLINE then
                            break
                        elseif ch == byte.CARRIAGE then
                            if strbyte(src, pos + 1) == byte.NEWLINE then
                                pos = pos + 1
                            end
                            break
                        end
                        pos = pos + 1
                        col = col + 1
                    end
                end
            else
                while pos <= len do
                    local ch = strbyte(src, pos)
                    if ch == byte.NEWLINE then
                        break
                    elseif ch == byte.CARRIAGE then
                        if strbyte(src, pos + 1) == byte.NEWLINE then
                            pos = pos + 1
                        end
                        break
                    end
                    pos = pos + 1
                    col = col + 1
                end
            end

        elseif is_letter(c) then
            local new_pos, typ, val = scan_identifier(src, pos)
            emit(tokens, typ, val, line, col)
            col = col + (new_pos - pos)
            pos = new_pos

        elseif is_digit(c) then
            local new_pos, typ, val = scan_number(src, pos, line, col)
            emit(tokens, typ, val, line, col)
            col = col + (new_pos - pos)
            pos = new_pos

        -- dot: . .. ... or leading decimal number
        elseif c == byte.DOT then
            local next = strbyte(src, pos + 1)

            if is_digit(next) then
                local new_pos, typ, val = scan_number(src, pos, line, col)
                emit(tokens, typ, val, line, col)
                col = col + (new_pos - pos)
                pos = new_pos

            elseif next == byte.DOT then
                local third = strbyte(src, pos + 2)
                if third == byte.DOT then
                    emit(tokens, 'vararg', '...', line, col)
                    pos = pos + 3
                    col = col + 3
                else
                    emit(tokens, 'concat', '..', line, col)
                    pos = pos + 2
                    col = col + 2
                end
            else
                emit(tokens, 'dot', '.', line, col)
                pos = pos + 1
                col = col + 1
            end

        elseif c == byte.SQUOTE or c == byte.DQUOTE then
            local new_pos, typ, val = scan_short_string(src, pos, line, col)
            emit(tokens, typ, val, line, col)
            col = col + (new_pos - pos)
            pos = new_pos

        -- long string or left bracket
        elseif c == byte.LBRACKET then
            local new_pos, typ, val, new_line, is_long = scan_long_bracket(src, pos, line)
            if is_long then
                emit(tokens, typ, val, line, col)
                line = line + count_newlines(val)
                col = 1
                pos = new_pos
            else
                emit(tokens, 'lbracket', '[', line, col)
                pos = pos + 1
                col = col + 1
            end

        elseif c == byte.PLUS then
            emit(tokens, 'op_add', '+', line, col)
            pos = pos + 1
            col = col + 1

        elseif c == byte.SUB then
            emit(tokens, 'op_sub', '-', line, col)
            pos = pos + 1
            col = col + 1

        elseif c == byte.STAR then
            emit(tokens, 'op_mul', '*', line, col)
            pos = pos + 1
            col = col + 1

        elseif c == byte.SLASH then
            emit(tokens, 'op_div', '/', line, col)
            pos = pos + 1
            col = col + 1

        elseif c == byte.CARET then
            emit(tokens, 'op_pow', '^', line, col)
            pos = pos + 1
            col = col + 1

        elseif c == byte.PERCENT then
            emit(tokens, 'op_mod', '%', line, col)
            pos = pos + 1
            col = col + 1

        elseif c == byte.TILDE then
            if strbyte(src, pos + 1) == byte.EQUALS then
                emit(tokens, 'op_ne', '~=', line, col)
                pos = pos + 2
                col = col + 2
            else
                error("TOKN:  error at line " .. line .. " col " .. col .. ": unexpected symbol '~'")
            end

        elseif c == byte.EQUALS then
            if strbyte(src, pos + 1) == byte.EQUALS then
                emit(tokens, 'op_eq', '==', line, col)
                pos = pos + 2
                col = col + 2
            else
                emit(tokens, 'op_assign', '=', line, col)
                pos = pos + 1
                col = col + 1
            end

        elseif c == byte.LT then
            if strbyte(src, pos + 1) == byte.EQUALS then
                emit(tokens, 'op_le', '<=', line, col)
                pos = pos + 2
                col = col + 2
            else
                emit(tokens, 'op_lt', '<', line, col)
                pos = pos + 1
                col = col + 1
            end

        elseif c == byte.GT then
            if strbyte(src, pos + 1) == byte.EQUALS then
                emit(tokens, 'op_ge', '>=', line, col)
                pos = pos + 2
                col = col + 2
            else
                emit(tokens, 'op_gt', '>', line, col)
                pos = pos + 1
                col = col + 1
            end

        elseif c == byte.HASH then
            emit(tokens, 'len', '#', line, col)
            pos = pos + 1
            col = col + 1

        elseif c == byte.LPAREN then
            emit(tokens, 'lparen', '(', line, col)
            pos = pos + 1
            col = col + 1

        elseif c == byte.RPAREN then
            emit(tokens, 'rparen', ')', line, col)
            pos = pos + 1
            col = col + 1

        elseif c == byte.LBRACE then
            emit(tokens, 'lbrace', '{', line, col)
            pos = pos + 1
            col = col + 1

        elseif c == byte.RBRACE then
            emit(tokens, 'rbrace', '}', line, col)
            pos = pos + 1
            col = col + 1

        elseif c == byte.RBRACKET then
            emit(tokens, 'rbracket', ']', line, col)
            pos = pos + 1
            col = col + 1

        elseif c == byte.SEMICOLON then
            emit(tokens, 'semicolon', ';', line, col)
            pos = pos + 1
            col = col + 1

        elseif c == byte.COLON then
            emit(tokens, 'colon', ':', line, col)
            pos = pos + 1
            col = col + 1

        elseif c == byte.COMMA then
            emit(tokens, 'comma', ',', line, col)
            pos = pos + 1
            col = col + 1

        else
            error("TOKN:  error at line " .. line .. " col " .. col .. ": unexpected symbol '" .. strchar(c) .. "'")
        end
    end

    DEBG(1, "Tokenizer produced " .. tgetn(tokens) .. " tokens.")
    DEBG(1, "Tokenization complete at Ln " .. line)
    DEBG(1, '=== TOKN END ===')
    return tokens
end