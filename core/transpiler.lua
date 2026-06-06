--[[ improvements  v1 ] =======================================================
    ============================================================================
    1. the '...' token can only appear in a function parameter list or at the
       top level of a chunk (as in wow addon loading). top‑level '...' is
       allowed and will be converted to the 'arg' table.
       valid:   function f(...) end   and   local addon, ns = ...
       default behavior: invalid: {...}  or  select(2, ...)  or
       local t = {...}   (inside a function without '...')

    2. in a vararg function, lua 5.0 automatically creates a local table named 'arg'
       containing all extra arguments. use 'arg' directly.
       example: local args = arg   -- instead of local args = {...}

    3. to emulate select('#', ...)   -> use table.getn(arg)
    4. to emulate select(n, ...) where n is a number >= 1:
       - standard lua would use unpack(arg, n) but in wow, unpack(arg, n) returns
       elements starting from index 1 (broken behavior).
       - therefore, expand select(n, ...) into explicit arg indexes:
       for local a, b = select(2, ...)   -> emit: local a, b = arg[2], arg[3]
       for print(select(2, ...))         -> emit: print(arg[2])


    ============================================================================
    expand_select v1 helper: given a select call node and the expected number
    of return values (or nil if unknown), return a string of
    expressions (comma separated) to replace the call.
    ============================================================================
]]
--[[ improvements v2 ] =======================================================
    ============================================================================
    1. multi‑return select() in assignments
       only the *last* value on the right‑hand side of an assignment or local
       declaration receives the expected‑return count, exactly matching lua's
       semantics. earlier select() calls (or any callexpr) are truncated to a
       single value.

    2. select() in return statements
       return select(n, ...) now expands to up to max_vararg (20) explicit
       arguments: arg[n], arg[n+1], ... , arg[n+19]. this avoids the broken
       unpack() and preserves correct multi‑return behaviour within that limit.

    3. vararg context validation
       using '...' outside a vararg function now raises a clear transpile‑time
       error instead of silently producing a nil reference bug. functions with
       '...' correctly propagate an in_vararg flag to their bodies.
       top‑level '...' is allowed (chunk is treated as an implicit vararg function).

    4. local function without name
       a local function declaration missing a name now throws an explicit error
       rather than silently dropping the 'local' keyword.

    5. defensive field access
       added (node.xxx or {}) guards in several places to prevent crashes on
       malformed ast nodes, making error messages more descriptive.

    6. context pass‑through
       the rendering functions now pass a 'context' table consistently (through
       expressions, statements, and blocks), enabling proper handling of
       in_vararg and expected_returns without global state pollution.

    ============================================================================
    notes: max_vararg is set to 20 we might need to raise.
    the generated code prepends __lua51_len and __lua51_mod helpers only when
    the '#/len' or '%/mod' operators are actually used.
    ============================================================================
]]
--[[ improvements v3 ] =======================================================
    ============================================================================
    1. vararg multi‑return expansion
       local addon, ns = ...  now emits: local addon, ns = arg[1], arg[2]
       previously emitted: local addon, ns = arg  (assigns whole table to addon)

       render_expression for vararg: when context.expected_returns is set,
       expand to arg[1], arg[2], ... instead of bar 'arg'.
       render_statement for assignment/localdecl: treat vararg like callexpr
       for multi‑return (only last value expands to fill targets).

    2. loader wrapper (lua5.1.lua)
       transpiled code is wrapped in (function(...) ... end) so lua 5.0
       creates local 'arg'. without this, loadstring() creates a plain
       function with no '...', and 'arg' would be nil global.

    3. addon name detection (lua5.1.lua)
       run() extracts caller addon folder from debugstack.
       addon_namespaces table stores one namespace per addon.
       runner(addon_name, addon_namespaces[addon_name]) replaces old
       hardcoded runner('lua5_1', {}).

       multiple files in the same addon folder receive the same ns table,
       matching wow's native addon loading behaviour.
     ============================================================================
]]
--[[ improvements v4 ] =======================================================
    ============================================================================
    1. explicit select() argument handling
       select() now works correctly with both explicit values and varargs.
       select('#', 1, 2, 3)  -> count: returns "3"
       select(2, 'x', 'y', 'z')  -> pick: returns "y"
       local a, b = select(2, 'x', 'y', 'z')  -> multi-return: a='y', b='z'
       previously all select() calls assumed varargs via arg[] table.

    2. has_vararg() guard
       new helper checks if select() arguments contain a VarArg token.
       if all args are explicit literals, bypasses the arg[] expansion
       and renders them directly. no more broken table.getn(arg) for
       explicit argument lists.

    3. dynamic index with explicit args
       select(i, 10, 20, 30) with a variable index now builds a runtime
       table {10, 20, 30} and indexes into it: ({10, 20, 30})[i] (still unsure why tho, so its TODO ...)
       this covers edge cases where neither the index nor the values
       are vararg-bound.

    4. litteral index optimization
       when the select index is a literal number (e.g. select(1, ...)),
       the emitted code now uses clean direct indices:
       arg[1], arg[2], arg[3]  instead of  arg[1], arg[1 + 1], arg[1 + 2]
       same for expand_select_multi -> return statements emit
       arg[1], ..., arg[20]  instead of  arg[1 + 0], ..., arg[1 + 19].

    5. off‑by‑one fix in expand_select_multi
       return select(2, 10, 20, 30) now correctly returns "20, 30"
       instead of just "30". the condition was i > 1 + idx,
       changed to i >= 1 + idx.

    6. hash select in expand_select_multi
       return select('#', ...) now correctly emits 'table.getn(arg)'
       instead of expanding '#' as a numeric index into
       arg['#'], arg['#' + 1], ..., arg['#' + 19].
       this affected return statements inside vararg functions.
       added an is_hash guard before the vararg expansion path.

    7. context leak fix in nested call arguments (keep an eye out for #6 stilll...)
       bug: when select() appears as an argument inside another function call,
       e.g. local a, b = minmax(select(2, 'x', 10, 30, 5)), the assignment's
       expected_returns (2) leaked through context into expand_select, causing
       it to output only 2 values ("10, 30") instead of all 3 ("10, 30, 5").
       fix A: non-select CallExpr arg rendering now creates a clean arg_context
       without expected_returns, only preserving in_vararg.
       fix B: expand_select nil-count path now expands all remaining explicit
       values (num_remaining = #args - (1 + idx) + 1) instead of returning
       just the first one. done for now... more transpiler work soonTM.
    ============================================================================
]]

-- WORK IN PROGRESS - this is a warzone in here so be careful

local core = ___Lua51reg'transpiler'

if ( core.TPIL ) then return end

local type = type
local error = error
local table = table
local DEBG = DEBG
local ipairs = ipairs
local getn = table.getn
local strrep = string.rep
local tostring = tostring
local concat = table.concat
local tinsert = table.insert

local render_block
local render_statement
local render_expression
local needs_mod = false
local needs_len = false
local needs_match = false

local MAX_VARARG = 20 -- we keep this at 20 for now, quie generous

local op_map = {
    op_add = '+', op_sub = '-', op_mul  = '*', op_div   = '/', op_pow   = '^',
    op_mod = '%', op_eq  = '==', op_ne  = '~=', op_lt   = '<', op_gt    = '>',
    op_le  = '<=', op_ge = '>=', concat = '..', ['and'] = 'and', ['or'] = 'or',
}

local function render_identifier(node)
    if not node or type(node) ~= 'table' or node.type ~= 'Identifier' then
        error('expected Identifier node')
    end
    return node.name
end

local function get_function_name(node)
    if node.type == 'Identifier' then
        return node.name
    elseif node.type == 'Var' then
        if node.base and node.base.type == 'Identifier' and not node.indexer then
            return node.base.name
        end
    end
    return nil
end

local function render_name(node)
    if not node or type(node) ~= 'table' then
        error('expected function name node')
    end
    if node.type == 'Identifier' then
        return render_identifier(node)
    end
    if node.type == 'Var' then
        local base = render_name(node.base)
        if node.indexer then
            if node.indexer.type == 'MemberExpr' then
                return base .. '.' .. node.indexer.member
            elseif node.indexer.type == 'IndexExpr' then
                return base .. '[' .. render_expression(node.indexer.index) .. ']'
            end
        end
        return base
    end
    error('invalid function name node type: ' .. tostring(node.type))
end

local function render_parameters(params)
    if not params or type(params) ~= 'table' then
        return ''
    end
    local names = {}
    for _, id in ipairs(params.names or {}) do
        tinsert(names, render_identifier(id))
    end
    if params.has_vararg then
        tinsert(names, '...')
    end
    return concat(names, ', ')
end

local function render_field(field)
    if not field or type(field) ~= 'table' or not field.kind then
        error('invalid table field node')
    end
    if field.kind == 'key' then
        return '[' .. render_expression(field.key) .. '] = ' .. render_expression(field.value)
    elseif field.kind == 'keyvalue' then
        return render_expression(field.key) .. ' = ' .. render_expression(field.value)
    elseif field.kind == 'value' then
        return render_expression(field.value)
    end
    error('unsupported field kind: ' .. tostring(field.kind))
end

local function has_vararg(node)
    -- checks if select() arguments contain a vararg token after first arg
    for i = 2, getn(node.args or {}) do
        if node.args[i].type == 'VarArg' then
            return true
        end
    end
    return false
end

local function expand_select(node, expected_count)
    -- index type    |  args type   |  result
    -- literal '#'   |  explicit    |  count as string literal
    -- literal '#'   |  vararg      |  table.getn(arg)
    -- literal n     |  explicit    |  inline the nth+ args directly
    -- literal n     |  vararg      |  arg[n], arg[n+1], ...
    -- dynamic expr  |  explicit    |  build runtime table {args}[expr]
    -- dynamic expr  |  vararg      |  arg[expr], arg[expr+1], ...
    if getn(node.args or {}) < 2 then
        error('select() requires at least two arguments')
    end
    local first_arg = node.args[1]
    local is_hash = false
    if first_arg.type == 'Literal' then
        if first_arg.value == '#' or first_arg.raw == "'#'" or first_arg.raw == '"#"' then
            is_hash = true
        end
    end

    -- if all arguments are explicit = no vararg, handle directly
    if not has_vararg(node) then
        if is_hash then
            -- select('#', explicit...) -> count explicit args
            return tostring(getn(node.args) - 1)
        end
        -- select(n, explicit...) where n is a literal number -> inline arg accesses
        if first_arg.type == 'Literal' and type(first_arg.value) == 'number' and first_arg.value >= 1 then
            local idx = first_arg.value
            if expected_count and expected_count > 0 then
                local items = {}
                for i = 0, expected_count - 1 do
                    local arg_idx = 1 + idx + i  -- 1 = skip first_arg in node.args
                    if arg_idx <= getn(node.args) then
                        tinsert(items, render_expression(node.args[arg_idx]))
                    else
                        tinsert(items, 'nil')
                    end
                end
                return concat(items, ', ')
            else
                local num_remaining = getn(node.args) - (1 + idx) + 1
                if num_remaining <= 1 then
                    local arg_idx = 1 + idx
                    if arg_idx <= getn(node.args) then
                        return render_expression(node.args[arg_idx])
                    end
                    return 'nil'
                else
                    local items = {}
                    for i = 0, num_remaining - 1 do
                        tinsert(items, render_expression(node.args[1 + idx + i]))
                    end
                    return concat(items, ', ')
                end
            end
        else
            -- dynamic index with explicit args -> build table at runtime
            local args_exprs = {}
            for i = 2, getn(node.args) do
                tinsert(args_exprs, render_expression(node.args[i]))
            end
            local tbl = '{' .. concat(args_exprs, ', ') .. '}'
            local idx_expr = render_expression(first_arg)
            if expected_count and expected_count > 0 then
                local items = {}
                for i = 0, expected_count - 1 do
                    if i == 0 then
                        tinsert(items, '(' .. tbl .. ')[' .. idx_expr .. ']')
                    else
                        tinsert(items, '(' .. tbl .. ')[' .. idx_expr .. ' + ' .. i .. ']')
                    end
                end
                return concat(items, ', ')
            end
            return '(' .. tbl .. ')[' .. idx_expr .. ']'
        end
    end

    -- vararg path = existing behavior)
    if is_hash then
        return 'table.getn(arg)' -- single value
    end

    local idx_expr = render_expression(first_arg)
    if expected_count and expected_count > 0 then
        local items = {}
        -- if first arg is a literal number, compute direct indices for cleaner output
        if first_arg.type == 'Literal' and type(first_arg.value) == 'number' then
            local base = first_arg.value
            for i = 0, expected_count - 1 do
                tinsert(items, 'arg[' .. (base + i) .. ']')
            end
        else
            for i = 1, expected_count do
                local offset = i - 1
                if offset == 0 then
                    tinsert(items, 'arg[' .. idx_expr .. ']')
                else
                    tinsert(items, 'arg[' .. idx_expr .. ' + ' .. offset .. ']')
                end
            end
        end
        return concat(items, ', ')
    else
        -- no context (e.g. used as a single value in an expression), just take first returned value
        return 'arg[' .. idx_expr .. ']'
    end
end

local function expand_select_multi(node)
    -- for return / last argument expansion -> outputs all values
    if getn(node.args or {}) < 2 then
        error('select() requires at least two arguments')
    end

    local first_arg = node.args[1]
    local is_hash = false
    if first_arg.type == 'Literal' then
        if first_arg.value == '#' or first_arg.raw == "'#'" or first_arg.raw == '"#"' then
            is_hash = true
        end
    end

    -- if all arguments are explicit = no vararg, handle directly
    if not has_vararg(node) then
        if is_hash then
            return tostring(getn(node.args) - 1)
        end
        -- select(n, explicit...) in return context -> output remaining args from n
        if first_arg.type == 'Literal' and type(first_arg.value) == 'number' and first_arg.value >= 1 then
            local idx = first_arg.value
            local items = {}
            for i = 1, getn(node.args) do
                if i >= 1 + idx then  -- skip first_arg + indices before idx
                    tinsert(items, render_expression(node.args[i]))
                end
            end
            if getn(items) == 0 then return '' end
            return concat(items, ', ')
        end
    end

    -- vararg path: expand to MAX_VARARG explicit arg[n] references
    first_arg = node.args[1]
    -- handle select('#', ...) with vararg -> single count
    if is_hash then
        return 'table.getn(arg)'
    end
    local items = {}
    if first_arg.type == 'Literal' and type(first_arg.value) == 'number' then
        local base = first_arg.value
        for i = 0, MAX_VARARG - 1 do
            tinsert(items, 'arg[' .. (base + i) .. ']')
        end
    else
        local idx_expr = render_expression(first_arg)
        for i = 0, MAX_VARARG - 1 do
            local offset = i
            if offset == 0 then
                tinsert(items, 'arg[' .. idx_expr .. ']')
            else
                tinsert(items, 'arg[' .. idx_expr .. ' + ' .. offset .. ']')
            end
        end
    end
    return concat(items, ', ')
end

function render_expression(node, context)
    context = context or {}
    if not node or type(node) ~= 'table' or not node.type then
        error('invalid expression node')
    end
    if node.type == 'Identifier' then
        return render_identifier(node)
    elseif node.type == 'Literal' then
        if node.raw then
            return node.raw
        end
        if node.value == nil then
            return 'nil'
        elseif node.value == true then
            return 'true'
        elseif node.value == false then
            return 'false'
        else
            return tostring(node.value)
        end
    elseif node.type == 'VarArg' then
        if not context.in_vararg then
            error("'...' used outside a vararg function – cannot transpile")
        end
        if context.expected_returns then
            local items = {}
            for i = 1, context.expected_returns do
                tinsert(items, 'arg[' .. i .. ']')
            end
            return concat(items, ', ')
        end
        return 'arg'
    elseif node.type == 'Var' then
        local text = render_expression(node.base, context)
        if node.indexer then
            if node.indexer.type == 'IndexExpr' then
                text = text .. '[' .. render_expression(node.indexer.index, context) .. ']'
            elseif node.indexer.type == 'MemberExpr' then
                text = text .. '.' .. node.indexer.member
            else
                error('invalid Var indexer type: ' .. tostring(node.indexer.type))
            end
        end
        return text
    elseif node.type == 'CallExpr' then
        local func_name = get_function_name(node.func)
        if func_name == 'select' then
            local expected = context.expected_returns
            return expand_select(node, expected)
        elseif func_name == 'print' then
            local args = {}
            for _, arg in ipairs(node.args or {}) do
                tinsert(args, 'tostring(' .. render_expression(arg, context) .. ')')
            end
            return 'DEFAULT_CHAT_FRAME:AddMessage(' .. concat(args, ' .. "  " .. ') .. ')'
        elseif func_name == 'match' then
            needs_match = true
            local args = {}
            for _, arg in ipairs(node.args or {}) do
                tinsert(args, render_expression(arg, context))
            end
            return '__lua51_match(' .. concat(args, ', ') .. ')'
        end

        local func = render_expression(node.func, context)
        local arg_context = {}
        if context.in_vararg then
            arg_context.in_vararg = true
        end
        local args = {}
        for _, arg in ipairs(node.args or {}) do
            tinsert(args, render_expression(arg, arg_context))
        end
        local arg_text = '(' .. concat(args, ', ') .. ')'
        if node.is_method then
            if not node.method then
                error('CallExpr is_method true but missing method name')
            end
            return func .. ':' .. node.method .. arg_text
        end
        return func .. arg_text
    elseif node.type == 'BinaryOp' then
        if node.op == 'op_mod' then
            needs_mod = true
            return '__lua51_mod(' .. render_expression(node.left, context) .. ', ' .. render_expression(node.right, context) .. ')'
        end
        local op = op_map[node.op] or node.op
        return render_expression(node.left, context) .. ' ' .. op .. ' ' .. render_expression(node.right, context)
    elseif node.type == 'UnaryOp' then
        if node.op == 'op_sub' then
            return '-' .. render_expression(node.expr, context)
        elseif node.op == 'not' then
            return 'not ' .. render_expression(node.expr, context)
        elseif node.op == 'len' then
            needs_len = true
            return '__lua51_len(' .. render_expression(node.expr, context) .. ')'
        end
        error('unsupported unary operator: ' .. tostring(node.op))
    elseif node.type == 'TableConstructor' then
        if getn(node.fields or {}) == 1 and node.fields[1].kind == 'value' and node.fields[1].value.type == 'VarArg' then
            return 'arg'
        end
        local fields = {}
        for _, field in ipairs(node.fields or {}) do
            tinsert(fields, render_field(field))
        end
        return '{' .. concat(fields, ', ') .. '}'
    elseif node.type == 'FunctionExpression' then
        local params = render_parameters(node.params)
        local body_context = {}
        if node.params and node.params.has_vararg then
            body_context.in_vararg = true
        end
        local body = render_block(node.body, 1, body_context)
        if body == '' then
            return 'function(' .. params .. ') end'
        end
        return 'function(' .. params .. ')\n' .. body .. '\nend'
    elseif node.type == 'Parens' then
        return '(' .. render_expression(node.expr, context) .. ')'
    end
    error('unsupported expression node: ' .. tostring(node.type))
end

function render_statement(node, indent, context)
    context = context or {}
    if not node or type(node) ~= 'table' or not node.type then
        error('invalid statement node')
    end
    local prefix = strrep('  ', indent)
    if node.type == 'Assignment' then
        local targets = {}
        for _, t in ipairs(node.targets or {}) do
            tinsert(targets, render_expression(t, context))
        end
        local values = {}
        local num_values = getn(node.values or {})
        for i, v in ipairs(node.values or {}) do
            local val_text
            if v.type == 'CallExpr' or v.type == 'VarArg' then
                -- only the last value can expand to multiple returns
                if i == num_values then
                    local remaining = getn(targets) - (getn(values))
                    if remaining > 0 then
                        val_text = render_expression(v, { expected_returns = remaining, in_vararg = context.in_vararg })
                    else
                        val_text = render_expression(v, context)
                    end
                else
                    val_text = render_expression(v, context)
                end
            else
                val_text = render_expression(v, context)
            end
            tinsert(values, val_text)
        end
        local result = ''
        if node['local'] then
            result = 'local '
        end
        result = result .. concat(targets, ', ')
        if getn(values) > 0 then
            result = result .. ' = ' .. concat(values, ', ')
        end
        return result
    elseif node.type == 'LocalDecl' then
        local names = {}
        for _, n in ipairs(node.names or {}) do
            tinsert(names, render_identifier(n))
        end
        local values = {}
        local num_values = getn(node.values or {})
        for i, v in ipairs(node.values or {}) do
            local val_text
            if v.type == 'CallExpr' or v.type == 'VarArg' then
                if i == num_values then
                    local remaining = getn(names) - (getn(values))
                    if remaining > 0 then
                        val_text = render_expression(v, { expected_returns = remaining, in_vararg = context.in_vararg })
                    else
                        val_text = render_expression(v, context)
                    end
                else
                    val_text = render_expression(v, context)
                end
            else
                val_text = render_expression(v, context)
            end
            tinsert(values, val_text)
        end
        local result = 'local ' .. concat(names, ', ')
        if getn(values) > 0 then
            result = result .. ' = ' .. concat(values, ', ')
        end
        return result
    elseif node.type == 'FunctionCall' then
        return render_expression(node.call, context)
    elseif node.type == 'DoBlock' then
        local body = render_block(node.block, indent + 1, context)
        return 'do\n' .. body .. '\n' .. prefix .. 'end'
    elseif node.type == 'WhileLoop' then
        local cond = render_expression(node.condition, context)
        local body = render_block(node.block, indent + 1, context)
        return 'while ' .. cond .. ' do\n' .. body .. '\n' .. prefix .. 'end'
    elseif node.type == 'RepeatLoop' then
        local body = render_block(node.block, indent + 1, context)
        local cond = render_expression(node.condition, context)
        return 'repeat\n' .. body .. '\n' .. prefix .. 'until ' .. cond
    elseif node.type == 'IfStatement' then
        local lines = {}
        for i, clause in ipairs(node.clauses or {}) do
            local header = (i == 1) and 'if ' or 'elseif '
            header = header .. render_expression(clause.condition, context) .. ' then'
            tinsert(lines, prefix .. header)
            tinsert(lines, render_block(clause.block, indent + 1, context))
        end
        if node.elseblock then
            tinsert(lines, prefix .. 'else')
            tinsert(lines, render_block(node.elseblock, indent + 1, context))
        end
        tinsert(lines, prefix .. 'end')
        return concat(lines, '\n')
    elseif node.type == 'ForNumeric' then
        local result = 'for ' .. render_identifier(node.var) .. ' = ' .. render_expression(node.start, context) .. ', ' .. render_expression(node.stop, context)
        if node.step then
            result = result .. ', ' .. render_expression(node.step, context)
        end
        local body = render_block(node.block, indent + 1, context)
        return result .. ' do\n' .. body .. '\n' .. prefix .. 'end'
    elseif node.type == 'ForGeneric' then
        local vars = {}
        for _, v in ipairs(node.vars or {}) do
            tinsert(vars, render_identifier(v))
        end
        local iter = {}
        for _, e in ipairs(node.iters or {}) do
            tinsert(iter, render_expression(e, context))
        end
        local body = render_block(node.block, indent + 1, context)
        return 'for ' .. concat(vars, ', ') .. ' in ' .. concat(iter, ', ') .. ' do\n' .. body .. '\n' .. prefix .. 'end'
    elseif node.type == 'FunctionDecl' then
        local header = ''
        if node.is_local then
            if not node.name then
                error('local function declaration must have a name')
            end
            header = 'local '
        end
        if not node.name then
            local params = render_parameters(node.params)
            local body_context = {}
            if node.params and node.params.has_vararg then
                body_context.in_vararg = true
            end
            local body = render_block(node.body, indent + 1, body_context)
            local func_text = 'function(' .. params .. ')\n' .. body .. '\n' .. prefix .. 'end'
            return func_text
        end
        local name_text = render_name(node.name)
        if node.method then
            name_text = name_text .. ':' .. node.method
        end
        header = header .. 'function ' .. name_text .. '(' .. render_parameters(node.params) .. ')'
        local body_context = {}
        if node.params and node.params.has_vararg then
            body_context.in_vararg = true
        end
        local body = render_block(node.body, indent + 1, body_context)
        return header .. '\n' .. body .. '\n' .. prefix .. 'end'
    elseif node.type == 'Return' then
        local exprs = {}
        local num_exprs = getn(node.exprs or {})
        if num_exprs == 1 then
            local e = node.exprs[1]
            if e.type == 'CallExpr' and get_function_name(e.func) == 'select' then
                -- expand multi‑return select in return statement
                return 'return ' .. expand_select_multi(e)
            end
        end
        for _, e in ipairs(node.exprs or {}) do -- TODO logos: both branches do same thing(?)... the if e.type == 'CallExpr' check should be useless i think...// dead code for the single‑select case but needed for other multi‑return functions. so we leave it ...
            local expr_text
            if e.type == 'CallExpr' then
                -- for non‑select calls we still dont expand; call returns its natural multi‑ret
                -- which lua handles correctly. so just render normally
                expr_text = render_expression(e, context)
            else
                expr_text = render_expression(e, context)
            end
            tinsert(exprs, expr_text)
        end
        if getn(exprs) == 0 then
            return 'return'
        end
        return 'return ' .. concat(exprs, ', ')
    elseif node.type == 'Break' then
        return 'break'
    end
    error('unsupported statement node: ' .. tostring(node.type))
end

function render_block(block, indent, context)
    context = context or {}
    if not block or type(block) ~= 'table' or block.type ~= 'Block' then
        error('expected Block node')
    end
    local lines = {}
    local prefix = strrep('  ', indent)
    for _, stmt in ipairs(block.stmts or {}) do
        tinsert(lines, prefix .. render_statement(stmt, indent, context))
    end
    if block.ret then
        tinsert(lines, prefix .. render_statement(block.ret, indent, context))
    end
    return concat(lines, '\n')
end

function core.TPIL(ast)
    DEBG(1, '=== TPIL START ===')
    if not ast or type(ast) ~= 'table' or ast.type ~= 'Chunk' then
        error('expected AST Chunk node')
    end

    needs_len = false
    needs_mod = false
    needs_match = false

    local parts = {}
    -- top‑level chunk is treated as an implicit vararg function -> like wotlk -- v1
    local top_context = { in_vararg = true }
    for _, body in ipairs(ast.body or {}) do
        if not body or body.type ~= 'Block' then
            error('Chunk body must contain Block nodes')
        end
        tinsert(parts, render_block(body, 0, top_context))
    end

    local code = concat(parts, '\n')
    local helpers = {}
    if needs_len then
        tinsert(helpers, 'local function __lua51_len(v)\n  if type(v) == "string" then return string.len(v) end\n  return table.getn(v)\nend')
    end
    if needs_mod then
        tinsert(helpers, 'local function __lua51_mod(a, b)\n  return a - math.floor(a / b) * b\nend')
    end
    if needs_match then
        tinsert(helpers, 'local function __lua51_match(s, pattern, init)\n  local results = {string.find(s, pattern, init)}\n  if not results[1] then return nil end\n  if table.getn(results) > 2 then\n    return unpack(results, 3)\n  else\n    return string.sub(s, results[1], results[2])\n  end\nend')
    end
    if getn(helpers) > 0 then
        code = concat(helpers, '\n\n') .. '\n\n' .. code
    end

    DEBG(1, '|cFFFFFFFFTranspile returning code: ' .. code)
    DEBG(2, 'CODE:\n' .. code)
    DEBG(1, '=== TPIL END ===')
    return code
end
