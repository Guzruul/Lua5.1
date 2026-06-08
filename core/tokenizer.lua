local core = ___Lua51reg'tokenizer'

if ( core.tokenizer ) then return end

local error = error
local table = table
local debugp = debugp
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
    BELL       = 7,    BKSP       = 8,
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
    EXCLAMATION = 33,
}

local keywords = {
    ['and']      = true, ['break'] = true, ['do']    = true, ['else']   = true,
    ['return']   = true, ['then']  = true, ['true']  = true, ['until']  = true,
    ['elseif']   = true, ['end']   = true, ['false'] = true, ['for']    = true,
    ['function'] = true, ['if']    = true, ['in']    = true, ['local']  = true,
    ['nil']      = true, ['not']   = true, ['or']    = true, ['repeat'] = true,
    ['while']    = true,
}

local function is_letter(c)
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

local function emit(tokens, typ, value, line, col, extra)
    local token = { type = typ, value = value, line = line, column = col }
    if extra then
        for k, v in extra do
            token[k] = v
        end
    end
    tinsert(tokens, token)
    debugp(2, "[tokenizer] Ln " .. line .. " Col " .. col .. " : " .. typ .. " '" .. value .. "'")
end

local function create_input(src)
    return {
        src = src,
        len = strlen(src),
        pos = 1,
        line = 1,
        col = 1,
    }
end

local function input_peek(input)
    return input.pos <= input.len and strbyte(input.src, input.pos) or nil
end

local function input_peek_offset(input, n)
    local p = input.pos + n
    return p <= input.len and strbyte(input.src, p) or nil
end

local function input_next(input)
    if input.pos > input.len then return nil end
    local c = strbyte(input.src, input.pos)
    input.pos = input.pos + 1
    if c == byte.NEWLINE then
        input.line = input.line + 1
        input.col = 1
    elseif c == byte.CARRIAGE then
        input.line = input.line + 1
        input.col = 1
        if input.pos <= input.len and strbyte(input.src, input.pos) == byte.NEWLINE then
            input.pos = input.pos + 1
        end
    else
        input.col = input.col + 1
    end
    return c
end

local function try_scan_long_bracket(input)
    local saved_pos = input.pos
    local saved_line = input.line
    local saved_col = input.col

    if input_peek(input) ~= byte.LBRACKET then
        return false
    end
    input_next(input)  -- consume '['

    local equals = 0
    while input_peek(input) == byte.EQUALS do
        equals = equals + 1
        input_next(input)
    end

    if input_peek(input) ~= byte.LBRACKET then
        -- not a valid long bracket; restore
        input.pos = saved_pos
        input.line = saved_line
        input.col = saved_col
        return false
    end
    input_next(input)  -- consume second '['
    return true, equals
end

local function scan_identifier(input, tokens)
    local start_pos = input.pos
    local tok_line = input.line
    local tok_col = input.col
    while input_peek(input) and is_alphanum(input_peek(input)) do
        input_next(input)
    end
    local word = strsub(input.src, start_pos, input.pos - 1)
    local typ = 'identifier'
    if keywords[word] then
        typ = 'keyword'
    end
    emit(tokens, typ, word, tok_line, tok_col)
end

local function scan_number(input, tokens)
    local start_pos = input.pos
    local tok_line = input.line
    local tok_col = input.col
    local numtype = 'integer'

    local c = input_peek(input)

    if c == byte.ZERO then
        local nxt = input_peek_offset(input, 1)
        if nxt == byte.X_LOWER or nxt == byte.X_UPPER then
            -- hex integer
            input_next(input)  -- '0'
            input_next(input)  -- 'x'/'X'
            if not is_digit(input_peek(input)) and
               not (input_peek(input) >= 97 and input_peek(input) <= 102) and
               not (input_peek(input) >= 65 and input_peek(input) <= 70) then
                error("tokenizer:  error at line " .. input.line .. " col " .. input.col .. ": malformed hex number")
            end
            while true do
                local b = input_peek(input)
                if not b then break end
                if not (is_digit(b) or (b >= 97 and b <= 102) or (b >= 65 and b <= 70)) then break end
                input_next(input)
            end
            local val = strsub(input.src, start_pos, input.pos - 1)
            emit(tokens, 'number', val, tok_line, tok_col, { numtype = 'hex' })
            return
        end
    end

    -- integer part
    while is_digit(input_peek(input)) do
        input_next(input)
    end

    -- fractional part
    if input_peek(input) == byte.DOT then
        local nxt = input_peek_offset(input, 1)
        -- consume dot if NOT followed by another dot (which would be `..` concat)
        if nxt and nxt ~= byte.DOT then
            input_next(input)  -- consume dot
            numtype = 'float'
            while is_digit(input_peek(input)) do
                input_next(input)
            end
        end
    end

    -- exponent part
    local e = input_peek(input)
    if e == byte.E_LOWER or e == byte.E_UPPER then
        input_next(input)
        numtype = 'float'
        local sign = input_peek(input)
        if sign == 43 or sign == 45 then
            input_next(input)
        end
        if not is_digit(input_peek(input)) then
            error("tokenizer:  error at line " .. tok_line .. " col " .. tok_col .. ": malformed number")
        end
        while is_digit(input_peek(input)) do
            input_next(input)
        end
    end

    local val = strsub(input.src, start_pos, input.pos - 1)
    emit(tokens, 'number', val, tok_line, tok_col, { numtype = numtype })
end

local function scan_short_string(input, tokens)
    local start_pos = input.pos
    local tok_line = input.line
    local tok_col = input.col
    local quote = input_peek(input)
    input_next(input)  -- consume opening quote

    while true do
        local c = input_peek(input)
        if not c then
            error("tokenizer:  error at line " .. tok_line .. " col " .. tok_col .. ": unfinished string")
        end

        if c == byte.BACKSLASH then
            input_next(input)  -- consume backslash
            local next_c = input_peek(input)
            if not next_c then
                error("tokenizer:  error at line " .. tok_line .. " col " .. tok_col .. ": unfinished string")
            elseif next_c == byte.Z_LOWER then
                -- \z: skip all following whitespace
                input_next(input)  -- consume 'z'
                while true do
                    local ws = input_peek(input)
                    if not ws then break end
                    if ws == byte.SPACE or ws == byte.TAB or ws == byte.VTAB or ws == byte.FORMFEED or ws == byte.NEWLINE or ws == byte.CARRIAGE then
                        input_next(input)
                    else
                        break
                    end
                end
            elseif next_c == byte.X_LOWER or next_c == byte.X_UPPER then
                error("tokenizer:  error at line " .. input.line .. " col " .. input.col .. ": invalid escape '\\x' in Lua 5.1")
            elseif is_digit(next_c) then
                -- \ddd: 1-3 decimal digits
                input_next(input)  -- consume first digit
                for i = 1, 2 do
                    local d = input_peek(input)
                    if is_digit(d) then
                        input_next(input)
                    else
                        break
                    end
                end
            elseif next_c == byte.NEWLINE or next_c == byte.CARRIAGE then
                -- \<newline>: consumes newline, inserts newline char
                input_next(input)  -- consume newline (input_next handles CRLF)
            else
                -- Lua 5.1 valid escapes: \a \b \f \ng \r \t \v \\ \" \' \[ \]
                -- next_c is the SOURCE character after backslash (e.g. 'n' for \n)
                if next_c == byte.A_LOWER or next_c == 98 or next_c == 102 or next_c == 110 or next_c == 114 or next_c == 116 or next_c == 118 or next_c == byte.BACKSLASH or next_c == byte.DQUOTE or next_c == byte.SQUOTE or next_c == byte.LBRACKET or next_c == byte.RBRACKET then
                    input_next(input)
                else
                    error("tokenizer:  error at line " .. input.line .. " col " .. input.col .. ": invalid escape '\\" .. strchar(next_c) .. "' in Lua 5.1")
                end
            end
        elseif c == quote then
            input_next(input)  -- consume closing quote
            local val = strsub(input.src, start_pos, input.pos - 1)
            emit(tokens, 'string', val, tok_line, tok_col)
            return
        elseif c == byte.NEWLINE or c == byte.CARRIAGE then
            error("tokenizer:  error at line " .. input.line .. " col " .. input.col .. ": unfinished string")
        else
            input_next(input)
        end
    end
end

local function scan_long_string(input, tokens, equals, tok_line, tok_col)
    -- try_scan_long_bracket already consumed the opening '[=*['
    -- equals tells us the level, and input.pos now points at the content start
    local start_pos = input.pos - 2 - equals  -- position of opening '['

    local close_pat = ']' .. strrep('=', equals) .. ']'
    local close_len = equals + 2

    while input_peek(input) do
        if input_peek(input) == byte.RBRACKET then
            local sub = strsub(input.src, input.pos, input.pos + close_len - 1)
            if sub == close_pat then
                local full = strsub(input.src, start_pos, input.pos + close_len - 1)
                -- advance past closing bracket
                for i = 1, close_len do
                    input_next(input)
                end
                emit(tokens, 'string_long', full, tok_line, tok_col)
                return
            end
        end
        input_next(input)
    end

    error("tokenizer:  error at line " .. tok_line .. " col " .. tok_col .. ": unfinished long string")
end

local function skip_short_comment(input)
    -- skip until newline or EOF, but do NOT consume the newline
    -- (the main loop's whitespace handling will consume it)
    while true do
        local c = input_peek(input)
        if not c then
            break
        end
        if c == byte.NEWLINE or c == byte.CARRIAGE then
            break
        end
        input_next(input)
    end
end

local function skip_long_comment(input, equals)
    local close_pat = ']' .. strrep('=', equals) .. ']'
    local close_len = equals + 2

    while input_peek(input) do
        if input_peek(input) == byte.RBRACKET then
            local sub = strsub(input.src, input.pos, input.pos + close_len - 1)
            if sub == close_pat then
                for i = 1, close_len do
                    input_next(input)
                end
                return
            end
        end
        input_next(input)
    end

    -- comment runs to EOF: not an error in Lua (comment is terminated by EOF)
end

function core.tokenizer(src)
    debugp(1, '=== tokenizer START ===')
    local input = create_input(src)
    local tokens = {}

    -- shebang check at start
    if input_peek(input) == byte.HASH and input_peek_offset(input, 1) == byte.EXCLAMATION then
        while input_peek(input) do
            local c = input_next(input)
            if c == byte.NEWLINE or c == byte.CARRIAGE then
                break
            end
        end
    end

    while input.pos <= input.len do
        local c = input_peek(input)

        -- whitespace
        if c == byte.SPACE or c == byte.TAB or c == byte.FORMFEED or c == byte.VTAB then
            input_next(input)

        -- newlines
        elseif c == byte.NEWLINE or c == byte.CARRIAGE then
            input_next(input)

        -- backslash outside string: not valid in Lua 5.1
        elseif c == byte.BACKSLASH then
            error("tokenizer:  error at line " .. input.line .. " col " .. input.col .. ": unexpected '\\' outside string")

        -- comments
        elseif c == byte.DASH and input_peek_offset(input, 1) == byte.DASH then
            input_next(input)  -- consume first '-'
            input_next(input)  -- consume second '-'

            local is_long, equals = try_scan_long_bracket(input)
            if is_long then
                skip_long_comment(input, equals)
            else
                skip_short_comment(input)
            end

        -- identifiers
        elseif is_letter(c) then
            scan_identifier(input, tokens)

        -- numbers (including leading dot)
        elseif is_digit(c) then
            scan_number(input, tokens)

        elseif c == byte.DOT then
            local nxt = input_peek_offset(input, 1)

            if is_digit(nxt) then
                scan_number(input, tokens)

            elseif nxt == byte.DOT then
                local third = input_peek_offset(input, 2)
                if third == byte.DOT then
                    emit(tokens, 'vararg', '...', input.line, input.col)
                    input_next(input)
                    input_next(input)
                    input_next(input)
                else
                    emit(tokens, 'concat', '..', input.line, input.col)
                    input_next(input)
                    input_next(input)
                end
            else
                emit(tokens, 'dot', '.', input.line, input.col)
                input_next(input)
            end

        -- short strings
        elseif c == byte.SQUOTE or c == byte.DQUOTE then
            scan_short_string(input, tokens)

        -- long strings / lbracket
        elseif c == byte.LBRACKET then
            local tok_line = input.line
            local tok_col = input.col
            local is_long, equals = try_scan_long_bracket(input)
            if is_long then
                scan_long_string(input, tokens, equals, tok_line, tok_col)
            else
                emit(tokens, 'lbracket', '[', tok_line, tok_col)
                input_next(input)
            end

        elseif c == byte.PLUS then
            emit(tokens, 'op_add', '+', input.line, input.col)
            input_next(input)

        elseif c == byte.SUB then
            emit(tokens, 'op_sub', '-', input.line, input.col)
            input_next(input)

        elseif c == byte.STAR then
            emit(tokens, 'op_mul', '*', input.line, input.col)
            input_next(input)

        elseif c == byte.SLASH then
            emit(tokens, 'op_div', '/', input.line, input.col)
            input_next(input)

        elseif c == byte.CARET then
            emit(tokens, 'op_pow', '^', input.line, input.col)
            input_next(input)

        elseif c == byte.PERCENT then
            emit(tokens, 'op_mod', '%', input.line, input.col)
            input_next(input)

        elseif c == byte.TILDE then
            if input_peek_offset(input, 1) == byte.EQUALS then
                emit(tokens, 'op_ne', '~=', input.line, input.col)
                input_next(input)
                input_next(input)
            else
                error("tokenizer:  error at line " .. input.line .. " col " .. input.col .. ": unexpected symbol '~'")
            end

        elseif c == byte.EQUALS then
            if input_peek_offset(input, 1) == byte.EQUALS then
                emit(tokens, 'op_eq', '==', input.line, input.col)
                input_next(input)
                input_next(input)
            else
                emit(tokens, 'op_assign', '=', input.line, input.col)
                input_next(input)
            end

        elseif c == byte.LT then
            if input_peek_offset(input, 1) == byte.EQUALS then
                emit(tokens, 'op_le', '<=', input.line, input.col)
                input_next(input)
                input_next(input)
            else
                emit(tokens, 'op_lt', '<', input.line, input.col)
                input_next(input)
            end

        elseif c == byte.GT then
            if input_peek_offset(input, 1) == byte.EQUALS then
                emit(tokens, 'op_ge', '>=', input.line, input.col)
                input_next(input)
                input_next(input)
            else
                emit(tokens, 'op_gt', '>', input.line, input.col)
                input_next(input)
            end

        elseif c == byte.HASH then
            emit(tokens, 'len', '#', input.line, input.col)
            input_next(input)

        elseif c == byte.LPAREN then
            emit(tokens, 'lparen', '(', input.line, input.col)
            input_next(input)

        elseif c == byte.RPAREN then
            emit(tokens, 'rparen', ')', input.line, input.col)
            input_next(input)

        elseif c == byte.LBRACE then
            emit(tokens, 'lbrace', '{', input.line, input.col)
            input_next(input)

        elseif c == byte.RBRACE then
            emit(tokens, 'rbrace', '}', input.line, input.col)
            input_next(input)

        elseif c == byte.RBRACKET then
            emit(tokens, 'rbracket', ']', input.line, input.col)
            input_next(input)

        elseif c == byte.SEMICOLON then
            emit(tokens, 'semicolon', ';', input.line, input.col)
            input_next(input)

        elseif c == byte.COLON then
            emit(tokens, 'colon', ':', input.line, input.col)
            input_next(input)

        elseif c == byte.COMMA then
            emit(tokens, 'comma', ',', input.line, input.col)
            input_next(input)

        else
            error("tokenizer:  error at line " .. input.line .. " col " .. input.col .. ": unexpected symbol '" .. strchar(c) .. "'")
        end
    end

    debugp(1, "Tokenizer produced " .. tgetn(tokens) .. " tokens.")
    debugp(1, "Tokenization complete at Ln " .. input.line)
    debugp(1, '=== tokenizer END ===')
    return tokens
end