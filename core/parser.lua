--[[ improvements  v1 ] =======================================================
    ============================================================================
    1. colon method syntax in function declarations
       function t:f() end now correctly preserves the colon in the AST! finally.
       previously, the method name after ':' was appended as a plain MemberExpr
       (~ iddentical to dot syntax), making t:f() and t.f() indistinguisable.

       fix: the method name is now stored as 'node.method' on the FunctionDecl
       node instead of being appended to the name chain via MemberExpr.
       the companion transpiler change emits ':' when node.method is present.
       this should fix the issue.

       example:
         input:  function t:f(x) end
         ast:    FunctionDecl{ name=Identifier('t'), method='f', params={x} }
         output: function t:f(x)
]]
local core = ___Lua51reg'parser'

if ( core.PARS ) then return end

local type = type
local DEBG = DEBG
local table = table
local error = error
local string = string
local ipairs = ipairs
local tgetn = table.getn
local tonumber = tonumber
local tostring = tostring
local strrep = string.rep
local tinsert = table.insert
local parse_exp, parse_block

local precedence = {
    ['or']      = 1,
    ['and']     = 2,
    ['op_eq']   = 3, ['op_ne']  = 3, ['op_lt']  = 3, ['op_gt'] = 3, ['op_le'] = 3, ['op_ge'] = 3,
    ['concat']  = 4,
    ['op_add']  = 5, ['op_sub'] = 5,
    ['op_mul']  = 6, ['op_div'] = 6, ['op_mod'] = 6,
    ['not']     = 7, ['len']    = 7,
    ['op_pow']  = 8,
}

local function is_binop(typ)
    return typ == 'or' or typ == 'and' or typ == 'op_eq' or typ == 'op_ne' or
           typ == 'op_lt' or typ == 'op_gt' or typ == 'op_le' or typ == 'op_ge' or
           typ == 'concat' or typ == 'op_add' or typ == 'op_sub' or
           typ == 'op_mul' or typ == 'op_div' or typ == 'op_mod' or typ == 'op_pow'
end

local function is_literal(tok)
    return tok.type == 'keyword' and (tok.value == 'nil' or tok.value == 'true' or tok.value == 'false')
end

local function make_state(tokens)
    DEBG(2, "[parser] make_state: " .. tgetn(tokens) .. " tokens")
    return { tokens = tokens, pos = 1, loop_depth = 0 }
end

local function peek(s, offset)
    offset = offset or 0
    local idx = s.pos + offset
    if idx > tgetn(s.tokens) then return nil end
    return s.tokens[idx]
end

local function advance(s)
    local tok = s.tokens[s.pos]
    s.pos = s.pos + 1
    DEBG(2, "[parser] advance: " .. tok.type .. " '" .. tok.value .. "' at Ln " .. tok.line .. " Col " .. tok.column)
    return tok
end

local function accept(s, typ, value)
    local tok = peek(s)
    if not tok then return nil end
    if tok.type ~= typ then return nil end
    if value ~= nil and tok.value ~= value then return nil end
    return advance(s)
end

local function expect(s, typ, value)
    local tok = accept(s, typ, value)
    if not tok then
        local near = peek(s)
        local msg = "Parser: line ? col ?: expected '"
        if value then msg = msg .. value .. "'"
        elseif typ == 'keyword' then msg = msg .. "keyword"
        else msg = msg .. typ end
        msg = msg .. "'"
        if near then
            msg = msg .. " near '" .. near.value .. "' at line " .. near.line .. " col " .. near.column
        end
        error(msg)
    end
    return tok
end

local function parser_error(s, msg)
    local tok = peek(s)
    if tok then
        error("Parser: line " .. tok.line .. " col " .. tok.column .. ": " .. msg)
    else
        error("Parser: " .. msg .. " at end of file")
    end
end

local function format_ast(node, indent)
    indent = indent or 0
    local pad = strrep('  ', indent)
    if not node or type(node) ~= 'table' then return pad .. tostring(node) end
    local typ = node.type or '?'
    local result = pad .. typ
    if typ == 'Identifier' then
        result = result .. " '" .. (node.name or '?') .. "'"
    elseif typ == 'Literal' then
        result = result .. " " .. tostring(node.raw or node.value)
    elseif typ == 'VarArg' then
        result = result .. " ..."
    elseif typ == 'Assignment' then
        result = result .. " (local=" .. tostring(node['local']) .. ")"
    elseif typ == 'FunctionCall' then
        result = result .. " (method=" .. tostring(node.is_method or false) .. ")"
    elseif typ == 'ParameterList' then
        result = result .. " (vararg=" .. tostring(node.has_vararg) .. ")"
    elseif typ == 'BinaryOp' or typ == 'UnaryOp' then
        result = result .. " op=" .. (node.op or '?')
    elseif typ == 'Field' then
        result = result .. " kind=" .. (node.kind or 'value')
    end
    result = result .. '\n'

    if typ == 'Chunk' or typ == 'Block' then
        local list = node.body or node.stmts
        if list then
            for _, item in ipairs(list) do
                result = result .. format_ast(item, indent + 1)
            end
        end
        if node.ret then
            result = result .. format_ast(node.ret, indent + 1)
        end
    elseif typ == 'Assignment' then
        for _, t in ipairs(node.targets or {}) do result = result .. format_ast(t, indent + 1) end
        for _, v in ipairs(node.values or {}) do result = result .. format_ast(v, indent + 1) end
    elseif typ == 'FunctionCall' then
        result = result .. format_ast(node.call or node, indent + 1)
    elseif typ == 'DoBlock' then
        result = result .. format_ast(node.block, indent + 1)
    elseif typ == 'WhileLoop' then
        result = result .. format_ast(node.condition, indent + 1)
        result = result .. format_ast(node.block, indent + 1)
    elseif typ == 'RepeatLoop' then
        result = result .. format_ast(node.block, indent + 1)
        result = result .. format_ast(node.condition, indent + 1)
    elseif typ == 'IfStatement' then
        for _, clause in ipairs(node.clauses or {}) do
            result = result .. pad .. "  IfClause\n"
            result = result .. format_ast(clause.condition, indent + 2)
            result = result .. format_ast(clause.block, indent + 2)
        end
        if node.elseblock then
            result = result .. pad .. "  ElseBlock\n"
            result = result .. format_ast(node.elseblock, indent + 2)
        end
    elseif typ == 'ForNumeric' then
        result = result .. format_ast(node.var, indent + 1)
        result = result .. format_ast(node.start, indent + 1)
        result = result .. format_ast(node.stop, indent + 1)
        if node.step then result = result .. format_ast(node.step, indent + 1) end
        result = result .. format_ast(node.block, indent + 1)
    elseif typ == 'ForGeneric' then
        for _, v in ipairs(node.vars or {}) do result = result .. format_ast(v, indent + 1) end
        for _, e in ipairs(node.iters or {}) do result = result .. format_ast(e, indent + 1) end
        result = result .. format_ast(node.block, indent + 1)
    elseif typ == 'FunctionDecl' then
        if node.name then result = result .. format_ast(node.name, indent + 1) end
        result = result .. format_ast(node.params, indent + 1)
        result = result .. format_ast(node.body, indent + 1)
    elseif typ == 'LocalDecl' then
        for _, n in ipairs(node.names or {}) do result = result .. format_ast(n, indent + 1) end
        for _, v in ipairs(node.values or {}) do result = result .. format_ast(v, indent + 1) end
    elseif typ == 'Return' then
        for _, e in ipairs(node.exprs or {}) do result = result .. format_ast(e, indent + 1) end
    elseif typ == 'Var' then
        result = result .. format_ast(node.base, indent + 1)
        if node.indexer then result = result .. format_ast(node.indexer, indent + 1) end
    elseif typ == 'IndexExpr' then
        result = result .. format_ast(node.index, indent + 1)
    elseif typ == 'MemberExpr' then
        result = result .. pad .. "  ." .. (node.member or '?') .. '\n'
    elseif typ == 'CallExpr' then
        result = result .. format_ast(node.func, indent + 1)
        if node.is_method then result = result .. pad .. "  :" .. (node.method or '?') .. '\n' end
        for _, a in ipairs(node.args or {}) do result = result .. format_ast(a, indent + 1) end
    elseif typ == 'BinaryOp' then
        result = result .. format_ast(node.left, indent + 1)
        result = result .. format_ast(node.right, indent + 1)
    elseif typ == 'UnaryOp' then
        result = result .. format_ast(node.expr, indent + 1)
    elseif typ == 'TableConstructor' then
        for _, f in ipairs(node.fields or {}) do result = result .. format_ast(f, indent + 1) end
    elseif typ == 'FunctionExpression' then
        result = result .. format_ast(node.params, indent + 1)
        result = result .. format_ast(node.body, indent + 1)
    elseif typ == 'Parens' then
        result = result .. format_ast(node.expr, indent + 1)
    end
    return result
end

local function parse_funcbody(s)
    expect(s, 'lparen')
    DEBG(2, "[parser] parse_funcbody")
    local params = { type = 'ParameterList', names = {}, has_vararg = false }
    if peek(s) and peek(s).type ~= 'rparen' then
        if peek(s).type == 'vararg' then
            advance(s)
            params.has_vararg = true
        else
            tinsert(params.names, { type = 'Identifier', name = expect(s, 'identifier').value })
            while accept(s, 'comma') do
                if peek(s) and peek(s).type == 'vararg' then
                    advance(s)
                    params.has_vararg = true
                    break
                else
                    tinsert(params.names, { type = 'Identifier', name = expect(s, 'identifier').value })
                end
            end
        end
    end
    expect(s, 'rparen')
    local body = parse_block(s, false)
    expect(s, 'keyword', 'end')
    DEBG(2, "[parser] parse_funcbody done")
    return params, body
end

local function parse_var(s)
    local tok = expect(s, 'identifier')
    DEBG(2, "[parser] parse_var: '" .. tok.value .. "'")
    local node = { type = 'Var', base = { type = 'Identifier', name = tok.value } }
    while true do
        local next = peek(s)
        if not next then break end

        if next.type == 'lbracket' then
            advance(s)
            local idx = parse_exp(s, 0)
            expect(s, 'rbracket')
            node = { type = 'Var', base = node, indexer = { type = 'IndexExpr', index = idx } }
        elseif next.type == 'dot' then
            advance(s)
            local name = expect(s, 'identifier')
            node = { type = 'Var', base = node, indexer = { type = 'MemberExpr', member = name.value } }
        elseif next.type == 'lparen' or next.type == 'lbrace' or next.type == 'string' or next.type == 'colon' then
            break
        else
            break
        end
    end
    return node
end

local function parse_prefix(s)
    local tok = peek(s)
    if not tok then parser_error(s, "unexpected end of file") end
    DEBG(2, "[parser] parse_prefix: " .. tok.type .. " '" .. (tok.value or '') .. "'")

    if is_literal(tok) then
        advance(s)
        local val
        if tok.value == 'nil' then val = nil
        elseif tok.value == 'true' then val = true
        else val = false end
        return { type = 'Literal', value = val, raw = tok.value }
    end

    if tok.type == 'number' then
        advance(s)
        return { type = 'Literal', value = tonumber(tok.value), raw = tok.value }
    end

    if tok.type == 'string' then
        advance(s)
        return { type = 'Literal', value = tok.value, raw = tok.value }
    end

    if tok.type == 'vararg' then
        advance(s)
        return { type = 'VarArg' }
    end

    if tok.type == 'op_sub' or (tok.type == 'keyword' and tok.value == 'not') or tok.type == 'len' then
        advance(s)
        local op
        if tok.type == 'keyword' and tok.value == 'not' then
            op = 'not'
        else
            op = tok.type
        end
        local expr = parse_exp(s, precedence['not'])
        return { type = 'UnaryOp', op = op, expr = expr }
    end

    if tok.type == 'lparen' then
        advance(s)
        local expr = parse_exp(s, 0)
        expect(s, 'rparen')
        return { type = 'Parens', expr = expr }
    end

    if tok.type == 'lbrace' then
        advance(s)
        local fields = {}
        while peek(s) and peek(s).type ~= 'rbrace' do
            local field
            local first = peek(s)
            if first.type == 'lbracket' then
                advance(s)
                local key = parse_exp(s, 0)
                expect(s, 'rbracket')
                expect(s, 'op_assign')
                local val = parse_exp(s, 0)
                field = { type = 'Field', kind = 'key', key = key, value = val }
            elseif first.type == 'identifier' and peek(s, 1) and peek(s, 1).type == 'op_assign' then
                advance(s)
                local name = first.value
                advance(s)
                local val = parse_exp(s, 0)
                field = { type = 'Field', kind = 'keyvalue', key = { type = 'Identifier', name = name }, value = val }
            else
                local val = parse_exp(s, 0)
                field = { type = 'Field', kind = 'value', value = val }
            end
            tinsert(fields, field)
            accept(s, 'comma')
            accept(s, 'semicolon')
        end
        expect(s, 'rbrace')
        return { type = 'TableConstructor', fields = fields }
    end

    if tok.type == 'keyword' and tok.value == 'function' then
        advance(s)
        local params, body = parse_funcbody(s)
        return { type = 'FunctionExpression', params = params, body = body }
    end

    if tok.type == 'identifier' then
        return parse_var(s)
    end

    parser_error(s, "unexpected symbol '" .. (tok.value or '?') .. "'")
end

local function parse_infix(s, left, prec)
    local tok = peek(s)
    if not tok then return left end

    if is_binop(tok.type) then
        if precedence[tok.type] <= prec then return left end
        advance(s)
        local op = tok.type
        local next_prec = precedence[op]
        if op == 'op_pow' or op == 'concat' then next_prec = next_prec - 1 end
        local right = parse_exp(s, next_prec)
        return { type = 'BinaryOp', op = op, left = left, right = right }
    end

    if tok.type == 'keyword' and (tok.value == 'or' or tok.value == 'and') then
        if precedence[tok.value] <= prec then return left end
        advance(s)
        local op = tok.value
        local next_prec = precedence[op]
        local right = parse_exp(s, next_prec)
        return { type = 'BinaryOp', op = op, left = left, right = right }
    end

    if tok.type == 'lparen' then
        advance(s)
        local args = {}
        if peek(s) and peek(s).type ~= 'rparen' then
            args = { parse_exp(s, 0) }
            while accept(s, 'comma') do
                tinsert(args, parse_exp(s, 0))
            end
        end
        expect(s, 'rparen')
        return { type = 'CallExpr', func = left, args = args, is_method = false }
    end

    if tok.type == 'lbrace' then
        local table_node = parse_prefix(s)
        return { type = 'CallExpr', func = left, args = { table_node }, is_method = false }
    end

    if tok.type == 'string' then
        local str_node = parse_prefix(s)
        return { type = 'CallExpr', func = left, args = { str_node }, is_method = false }
    end

    if tok.type == 'colon' then
        advance(s)
        local method_name = expect(s, 'identifier')
        local args = {}
        if accept(s, 'lparen') then
            if peek(s) and peek(s).type ~= 'rparen' then
                args = { parse_exp(s, 0) }
                while accept(s, 'comma') do
                    tinsert(args, parse_exp(s, 0))
                end
            end
            expect(s, 'rparen')
        elseif peek(s) and peek(s).type == 'lbrace' then
            args = { parse_prefix(s) }
        elseif peek(s) and peek(s).type == 'string' then
            args = { parse_prefix(s) }
        end
        return { type = 'CallExpr', func = left, args = args, is_method = true, method = method_name.value }
    end

    if tok.type == 'lbracket' then
        advance(s)
        local index = parse_exp(s, 0)
        expect(s, 'rbracket')
        return { type = 'Var', base = left, indexer = { type = 'IndexExpr', index = index } }
    end

    if tok.type == 'dot' then
        advance(s)
        local name = expect(s, 'identifier')
        return { type = 'Var', base = left, indexer = { type = 'MemberExpr', member = name.value } }
    end

    return left
end

local function parse_retstat(s, can_break)
    if accept(s, 'keyword', 'break') then
        DEBG(2, "[parser] parse_retstat: break")
        if not can_break then parser_error(s, "'break' not inside a loop") end
        return { type = 'Break' }
    end
    expect(s, 'keyword', 'return')
    DEBG(2, "[parser] parse_retstat: return")
    local node = { type = 'Return', exprs = {} }
    local nxt = peek(s)
    if not nxt or (nxt.type == 'keyword' and
       (nxt.value == 'end' or nxt.value == 'else' or nxt.value == 'elseif' or nxt.value == 'until')) then
        -- skip no expressions
    else
        node.exprs = { parse_exp(s, 0) }
        while accept(s, 'comma') do
            tinsert(node.exprs, parse_exp(s, 0))
        end
    end
    accept(s, 'semicolon')
    return node
end

local function parse_statement(s, can_break)
    local tok = peek(s)
    if not tok then return nil end
    DEBG(2, "[parser] parse_statement: " .. tok.type .. " '" .. (tok.value or '') .. "'")

    if accept(s, 'semicolon') then return parse_statement(s, can_break) end

    if accept(s, 'keyword', 'do') then
        local block = parse_block(s, true)
        expect(s, 'keyword', 'end')
        return { type = 'DoBlock', block = block }
    end

    if accept(s, 'keyword', 'while') then
        local cond = parse_exp(s, 0)
        expect(s, 'keyword', 'do')
        s.loop_depth = s.loop_depth + 1
        local block = parse_block(s, true)
        s.loop_depth = s.loop_depth - 1
        expect(s, 'keyword', 'end')
        return { type = 'WhileLoop', condition = cond, block = block }
    end

    if accept(s, 'keyword', 'repeat') then
        s.loop_depth = s.loop_depth + 1
        local block = parse_block(s, true)
        s.loop_depth = s.loop_depth - 1
        expect(s, 'keyword', 'until')
        local cond = parse_exp(s, 0)
        return { type = 'RepeatLoop', block = block, condition = cond }
    end

    if accept(s, 'keyword', 'if') then
        local clauses = {}
        local cond = parse_exp(s, 0)
        expect(s, 'keyword', 'then')
        local block = parse_block(s, can_break)
        tinsert(clauses, { condition = cond, block = block })
        while accept(s, 'keyword', 'elseif') do
            cond = parse_exp(s, 0)
            expect(s, 'keyword', 'then')
            block = parse_block(s, can_break)
            tinsert(clauses, { condition = cond, block = block })
        end
        local elseblock
        if accept(s, 'keyword', 'else') then
            elseblock = parse_block(s, can_break)
        end
        expect(s, 'keyword', 'end')
        return { type = 'IfStatement', clauses = clauses, elseblock = elseblock }
    end

    if accept(s, 'keyword', 'for') then
        local name = expect(s, 'identifier')
        if accept(s, 'op_assign') then
            local start = parse_exp(s, 0)
            expect(s, 'comma')
            local stop = parse_exp(s, 0)
            local step
            if accept(s, 'comma') then step = parse_exp(s, 0) end
            expect(s, 'keyword', 'do')
            s.loop_depth = s.loop_depth + 1
            local block = parse_block(s, true)
            s.loop_depth = s.loop_depth - 1
            expect(s, 'keyword', 'end')
            return {
                type = 'ForNumeric',
                var = { type = 'Identifier', name = name.value },
                start = start, stop = stop, step = step,
                block = block
            }
        else
            local vars = { { type = 'Identifier', name = name.value } }
            while accept(s, 'comma') do
                tinsert(vars, { type = 'Identifier', name = expect(s, 'identifier').value })
            end
            expect(s, 'keyword', 'in')
            local iters = { parse_exp(s, 0) }
            while accept(s, 'comma') do
                tinsert(iters, parse_exp(s, 0))
            end
            expect(s, 'keyword', 'do')
            s.loop_depth = s.loop_depth + 1
            local block = parse_block(s, true)
            s.loop_depth = s.loop_depth - 1
            expect(s, 'keyword', 'end')
            return { type = 'ForGeneric', vars = vars, iters = iters, block = block }
        end
    end

    if accept(s, 'keyword', 'function') then
        local is_local = false -- TODO logos
        local name_node
        local method_name
        local tok2 = peek(s)
        if tok2 and tok2.type == 'identifier' then
            local name_parts = { expect(s, 'identifier').value }
            while accept(s, 'dot') do
                tinsert(name_parts, expect(s, 'identifier').value)
            end
            if accept(s, 'colon') then
                method_name = expect(s, 'identifier').value
            end
            name_node = { type = 'Identifier', name = name_parts[1] }
            for i = 2, tgetn(name_parts) do
                name_node = { type = 'Var', base = name_node, indexer = { type = 'MemberExpr', member = name_parts[i] } }
            end
        -- method name is stored separately on FunctionDecl to preserve colon syntax
        end
        local params, body = parse_funcbody(s)
    return { type = 'FunctionDecl', is_local = is_local, name = name_node, params = params, body = body, method = method_name }
    end

    if accept(s, 'keyword', 'local') then
        if accept(s, 'keyword', 'function') then
            local name = expect(s, 'identifier')
            local params, body = parse_funcbody(s)
            return { type = 'FunctionDecl', is_local = true, name = { type = 'Identifier', name = name.value }, params = params, body = body }
        end
        local names = { { type = 'Identifier', name = expect(s, 'identifier').value } }
        while accept(s, 'comma') do
            tinsert(names, { type = 'Identifier', name = expect(s, 'identifier').value })
        end
        local values = {}
        if accept(s, 'op_assign') then
            values = { parse_exp(s, 0) }
            while accept(s, 'comma') do
                tinsert(values, parse_exp(s, 0))
            end
        end
        return { type = 'LocalDecl', names = names, values = values }
    end

    if tok.type == 'keyword' and tok.value == 'return' then
        return parse_retstat(s, can_break)
    end

    if tok.type == 'keyword' and tok.value == 'break' then
        advance(s)
        if not can_break then parser_error(s, "'break' not inside a loop") end
        return { type = 'Break' }
    end

    if tok.type == 'identifier' then
        local first_var = parse_var(s)
        local tok2 = peek(s)

        if tok2 and (tok2.type == 'lparen' or tok2.type == 'lbrace' or tok2.type == 'string' or tok2.type == 'colon') then
            local call_node = first_var
            while true do
                local next = parse_infix(s, call_node, 0)
                if next == call_node then break end
                call_node = next
            end
            return { type = 'FunctionCall', call = call_node }
        end

        if tok2 and tok2.type == 'op_assign' then
            local targets = { first_var }
            while accept(s, 'comma') do
                tinsert(targets, parse_var(s))
            end
            expect(s, 'op_assign')
            local values = { parse_exp(s, 0) }
            while accept(s, 'comma') do
                tinsert(values, parse_exp(s, 0))
            end
            return { type = 'Assignment', targets = targets, values = values, ['local'] = false }
        end

        if tok2 and tok2.type == 'comma' then -- TODO logos
            local targets = { first_var }
            while accept(s, 'comma') do
                tinsert(targets, parse_var(s))
            end
            expect(s, 'op_assign')
            local values = { parse_exp(s, 0) }
            while accept(s, 'comma') do
                tinsert(values, parse_exp(s, 0))
            end
            return { type = 'Assignment', targets = targets, values = values, ['local'] = false }
        end

        return { type = 'FunctionCall', call = { type = 'CallExpr', func = first_var, args = {} } }
    end

    if tok.type == 'lparen' then
        advance(s)
        local expr = parse_exp(s, 0)
        expect(s, 'rparen')
        local tok2 = peek(s)
        if tok2 and tok2.type == 'lparen' then
            local call_node = parse_infix(s, { type = 'Parens', expr = expr }, 0)
            return { type = 'FunctionCall', call = call_node }
        end
        if tok2 and tok2.type == 'op_assign' then
            parser_error(s, "invalid assignment target")
        end
        parser_error(s, "syntax error near ')'")
    end

    parser_error(s, "unexpected symbol '" .. (tok.value or '?') .. "'")
end

function parse_block(s, can_break)
    local stmts = {}
    local ret

    while peek(s) do
        local tok = peek(s)

        if tok.type == 'keyword' then
            if tok.value == 'end' or tok.value == 'else' or tok.value == 'elseif' or tok.value == 'until' then
                break
            end
        end

        if tok.type == 'keyword' and (tok.value == 'return' or tok.value == 'break') then
            ret = parse_retstat(s, can_break)
            break
        end

        local stmt = parse_statement(s, can_break)
        if stmt then
            tinsert(stmts, stmt)
        end
    end

    return { type = 'Block', stmts = stmts, ret = ret }
end

function parse_exp(s, prec)
    prec = prec or 0
    local left = parse_prefix(s)
    while true do
        local tok = peek(s)
        if not tok then break end
        local next = parse_infix(s, left, prec)
        if next == left then break end
        left = next
    end
    return left
end

function core.PARS(tokens)
    DEBG(1, "=== PARS START ===")
    DEBG(1, "Tokens: " .. tgetn(tokens))
    if not tokens then tokens = {} end

    local s = make_state(tokens)
    local body = parse_block(s, false)

    if peek(s) then
        local tok = peek(s)
        parser_error(s, "unexpected symbol '" .. tok.value .. "' at line " .. tok.line .. " col " .. tok.column)
    end

    local ast = { type = 'Chunk', body = { body } }
    DEBG(1, "Parser produced AST.")
    DEBG(2, "AST:\n" .. format_ast(ast))
    DEBG(1, "=== PARS END ===")
    return ast
end
