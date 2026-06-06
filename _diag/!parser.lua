-- dont load these files, copy the tests over to diagnostic instead

add_test('parser_1', function()
    local tokens = core.TOKN('local x = 1')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and tgetn(ast.body) == 1
       and ast.body[1].type == 'Block'
       and tgetn(ast.body[1].stmts) == 1
       and ast.body[1].stmts[1].type == 'LocalDecl'
end)

add_test('parser_2', function()
    local tokens = core.TOKN('do end')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and tgetn(ast.body) == 1
       and ast.body[1].type == 'Block'
       and tgetn(ast.body[1].stmts) == 1
       and ast.body[1].stmts[1].type == 'DoBlock'
       and tgetn(ast.body[1].stmts[1].block.stmts) == 0
end)

add_test('parser_3', function()
    local tokens = core.TOKN('local x')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and tgetn(ast.body) == 1
       and ast.body[1].type == 'Block'
       and tgetn(ast.body[1].stmts) == 1
       and ast.body[1].stmts[1].type == 'LocalDecl'
       and tgetn(ast.body[1].stmts[1].names) == 1
       and tgetn(ast.body[1].stmts[1].values) == 0
end)

add_test('parser_4', function()
    local tokens = core.TOKN("local x = 'hello'")
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and tgetn(ast.body) == 1
       and ast.body[1].type == 'Block'
       and tgetn(ast.body[1].stmts) == 1
       and ast.body[1].stmts[1].type == 'LocalDecl'
       and tgetn(ast.body[1].stmts[1].names) == 1
       and tgetn(ast.body[1].stmts[1].values) == 1
       and ast.body[1].stmts[1].values[1].type == 'Literal'
end)

add_test('parser_5', function()
    local tokens = core.TOKN('x = 1')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and tgetn(ast.body) == 1
       and ast.body[1].type == 'Block'
       and tgetn(ast.body[1].stmts) == 1
       and ast.body[1].stmts[1].type == 'Assignment'
       and tgetn(ast.body[1].stmts[1].targets) == 1
       and tgetn(ast.body[1].stmts[1].values) == 1
end)

add_test('parser_6', function()
    local tokens = core.TOKN('local a, b = 1, 2')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and tgetn(ast.body) == 1
       and ast.body[1].type == 'Block'
       and tgetn(ast.body[1].stmts) == 1
       and ast.body[1].stmts[1].type == 'LocalDecl'
       and tgetn(ast.body[1].stmts[1].names) == 2
       and tgetn(ast.body[1].stmts[1].values) == 2
end)

add_test('parser_7', function()
    local tokens = core.TOKN('')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and tgetn(ast.body) == 1
       and ast.body[1].type == 'Block'
       and tgetn(ast.body[1].stmts) == 0
end)

add_test('parser_8', function()
    local tokens = core.TOKN('x = 1')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and tgetn(ast.body) == 1
       and ast.body[1].type == 'Block'
       and tgetn(ast.body[1].stmts) == 1
       and ast.body[1].stmts[1].type == 'Assignment'
       and ast.body[1].stmts[1]['local'] == false
       and tgetn(ast.body[1].stmts[1].targets) == 1
       and tgetn(ast.body[1].stmts[1].values) == 1
end)

add_test('parser_9', function()
    local tokens = core.TOKN('foo()')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and tgetn(ast.body) == 1
       and ast.body[1].type == 'Block'
       and tgetn(ast.body[1].stmts) == 1
       and ast.body[1].stmts[1].type == 'FunctionCall'
       and ast.body[1].stmts[1].call.type == 'CallExpr'
       and tgetn(ast.body[1].stmts[1].call.args) == 0
       and ast.body[1].stmts[1].call.is_method == false
end)

add_test('parser_10', function()
    local tokens = core.TOKN('return 1')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and tgetn(ast.body) == 1
       and ast.body[1].type == 'Block'
       and tgetn(ast.body[1].stmts) == 0
       and ast.body[1].ret ~= nil
       and ast.body[1].ret.type == 'Return'
       and tgetn(ast.body[1].ret.exprs) == 1
end)

add_test('parser_11', function()
    local tokens = core.TOKN('return')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].ret ~= nil
       and ast.body[1].ret.type == 'Return'
       and tgetn(ast.body[1].ret.exprs) == 0
end)

add_test('parser_12', function()
    local tokens = core.TOKN('if true then end')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].type == 'IfStatement'
       and tgetn(ast.body[1].stmts[1].clauses) == 1
       and ast.body[1].stmts[1].elseblock == nil
end)

add_test('parser_13', function()
    local tokens = core.TOKN('if true then else end')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].type == 'IfStatement'
       and tgetn(ast.body[1].stmts[1].clauses) == 1
       and ast.body[1].stmts[1].elseblock ~= nil
       and ast.body[1].stmts[1].elseblock.type == 'Block'
end)

add_test('parser_14', function()
    local tokens = core.TOKN('if true then elseif false then else end')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].type == 'IfStatement'
       and tgetn(ast.body[1].stmts[1].clauses) == 2
       and ast.body[1].stmts[1].elseblock ~= nil
end)

add_test('parser_15', function()
    local tokens = core.TOKN('while true do end')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].type == 'WhileLoop'
       and ast.body[1].stmts[1].condition ~= nil
       and ast.body[1].stmts[1].block.type == 'Block'
       and tgetn(ast.body[1].stmts[1].block.stmts) == 0
end)

add_test('parser_16', function()
    local tokens = core.TOKN('repeat until true')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].type == 'RepeatLoop'
       and ast.body[1].stmts[1].condition ~= nil
       and ast.body[1].stmts[1].block.type == 'Block'
       and tgetn(ast.body[1].stmts[1].block.stmts) == 0
end)

add_test('parser_17', function()
    local tokens = core.TOKN('for i = 1, 10 do end')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].type == 'ForNumeric'
       and ast.body[1].stmts[1].var.name == 'i'
       and ast.body[1].stmts[1].start ~= nil
       and ast.body[1].stmts[1].stop ~= nil
       and ast.body[1].stmts[1].step == nil
       and ast.body[1].stmts[1].block.type == 'Block'
end)

add_test('parser_18', function()
    local tokens = core.TOKN('for i = 1, 10, 2 do end')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].type == 'ForNumeric'
       and ast.body[1].stmts[1].step ~= nil
end)

add_test('parser_19', function()
    local tokens = core.TOKN('for k, v in pairs(t) do end')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].type == 'ForGeneric'
       and tgetn(ast.body[1].stmts[1].vars) == 2
       and tgetn(ast.body[1].stmts[1].iters) == 1
       and ast.body[1].stmts[1].block.type == 'Block'
end)

add_test('parser_20', function()
    local tokens = core.TOKN('function foo() end')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].type == 'FunctionDecl'
       and ast.body[1].stmts[1].is_local == false
       and ast.body[1].stmts[1].name.type == 'Identifier'
       and ast.body[1].stmts[1].name.name == 'foo'
       and ast.body[1].stmts[1].params.has_vararg == false
       and tgetn(ast.body[1].stmts[1].params.names) == 0
end)

add_test('parser_21', function()
    local tokens = core.TOKN('local function foo() end')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].type == 'FunctionDecl'
       and ast.body[1].stmts[1].is_local == true
       and ast.body[1].stmts[1].name.name == 'foo'
end)

add_test('parser_22', function()
    local tokens = core.TOKN('local x = 1 + 2')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].type == 'LocalDecl'
       and ast.body[1].stmts[1].values[1].type == 'BinaryOp'
       and ast.body[1].stmts[1].values[1].op == 'op_add'
end)

add_test('parser_23', function()
    local tokens = core.TOKN('local x = -1')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].type == 'LocalDecl'
       and ast.body[1].stmts[1].values[1].type == 'UnaryOp'
       and ast.body[1].stmts[1].values[1].op == 'op_sub'
end)

add_test('parser_24', function()
    local tokens = core.TOKN('local t = {}')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].type == 'LocalDecl'
       and ast.body[1].stmts[1].values[1].type == 'TableConstructor'
       and tgetn(ast.body[1].stmts[1].values[1].fields) == 0
end)

add_test('parser_25', function()
    local tokens = core.TOKN('while true do break end')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].type == 'WhileLoop'
       and ast.body[1].stmts[1].block.ret ~= nil
       and ast.body[1].stmts[1].block.ret.type == 'Break'
       and tgetn(ast.body[1].stmts[1].block.stmts) == 0
end)

add_test('parser_26', function()
    local tokens = core.TOKN('a, b = 1, 2')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].type == 'Assignment'
       and tgetn(ast.body[1].stmts[1].targets) == 2
       and tgetn(ast.body[1].stmts[1].values) == 2
end)

add_test('parser_27', function()
    local tokens = core.TOKN('local x = nil')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].type == 'LocalDecl'
       and ast.body[1].stmts[1].values[1].type == 'Literal'
       and ast.body[1].stmts[1].values[1].value == nil
       and ast.body[1].stmts[1].values[1].raw == 'nil'
end)

add_test('parser_28', function()
    local tokens = core.TOKN('local x = true')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].type == 'LocalDecl'
       and ast.body[1].stmts[1].values[1].type == 'Literal'
       and ast.body[1].stmts[1].values[1].value == true
end)

add_test('parser_29', function()
    local tokens = core.TOKN('local x = false')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].type == 'LocalDecl'
       and ast.body[1].stmts[1].values[1].type == 'Literal'
       and ast.body[1].stmts[1].values[1].value == false
end)

add_test('parser_30', function()
    local tokens = core.TOKN('return 1, 2, 3')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].ret.type == 'Return'
       and tgetn(ast.body[1].ret.exprs) == 3
end)

add_test('parser_31', function()
    local tokens = core.TOKN('local x = 1 local y = 2')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and tgetn(ast.body[1].stmts) == 2
       and ast.body[1].stmts[1].type == 'LocalDecl'
       and ast.body[1].stmts[2].type == 'LocalDecl'
end)

add_test('parser_32', function()
    local tokens = core.TOKN('if true then return end')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].type == 'IfStatement'
       and ast.body[1].stmts[1].clauses[1].block.ret.type == 'Return'
       and tgetn(ast.body[1].stmts[1].clauses[1].block.ret.exprs) == 0
end)

add_test('parser_33', function()
    local tokens = core.TOKN('function foo(x, y) end')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].type == 'FunctionDecl'
       and tgetn(ast.body[1].stmts[1].params.names) == 2
       and ast.body[1].stmts[1].params.has_vararg == false
end)

add_test('parser_34', function()
    local tokens = core.TOKN('local t = {1, 2, 3}')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].type == 'LocalDecl'
       and ast.body[1].stmts[1].values[1].type == 'TableConstructor'
       and tgetn(ast.body[1].stmts[1].values[1].fields) == 3
end)

add_test('parser_35', function()
    local tokens = core.TOKN('local x = not true')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].type == 'LocalDecl'
       and ast.body[1].stmts[1].values[1].type == 'UnaryOp'
       and ast.body[1].stmts[1].values[1].op == 'not'
end)

add_test('parser_36', function()
    local tokens = core.TOKN("local x = #'hello'")
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].type == 'LocalDecl'
       and ast.body[1].stmts[1].values[1].type == 'UnaryOp'
       and ast.body[1].stmts[1].values[1].op == 'len'
end)

add_test('parser_37', function()
    local tokens = core.TOKN('obj:method(1)')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].type == 'FunctionCall'
       and ast.body[1].stmts[1].call.is_method == true
       and ast.body[1].stmts[1].call.method == 'method'
end)

add_test('parser_38', function()
    local tokens = core.TOKN('local x = a.b.c')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].type == 'LocalDecl'
       and ast.body[1].stmts[1].values[1].type == 'Var'
       and ast.body[1].stmts[1].values[1].base.type == 'Var'
       and ast.body[1].stmts[1].values[1].base.base.base.name == 'a'
       and ast.body[1].stmts[1].values[1].indexer.member == 'c'
end)

add_test('parser_39', function()
    local tokens = core.TOKN('foo(1, 2)')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].type == 'FunctionCall'
       and ast.body[1].stmts[1].call.type == 'CallExpr'
       and tgetn(ast.body[1].stmts[1].call.args) == 2
end)

add_test('parser_40', function()
    local tokens = core.TOKN('local f = function() end')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].type == 'LocalDecl'
       and ast.body[1].stmts[1].values[1].type == 'FunctionExpression'
end)

add_test('parser_41', function()
    local tokens = core.TOKN("foo 'hello'")
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].type == 'FunctionCall'
       and tgetn(ast.body[1].stmts[1].call.args) == 1
       and ast.body[1].stmts[1].call.args[1].type == 'Literal'
end)

add_test('parser_42', function()
    local tokens = core.TOKN('foo{1, 2}')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].type == 'FunctionCall'
       and tgetn(ast.body[1].stmts[1].call.args) == 1
       and ast.body[1].stmts[1].call.args[1].type == 'TableConstructor'
end)

add_test('parser_43', function()
    local tokens = core.TOKN('function a.b.c() end')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].type == 'FunctionDecl'
       and ast.body[1].stmts[1].name.type == 'Var'
       and ast.body[1].stmts[1].name.base.type == 'Var'
       and ast.body[1].stmts[1].name.base.base.name == 'a'
       and ast.body[1].stmts[1].name.indexer.member == 'c'
end)

add_test('parser_44', function()
    local tokens = core.TOKN('local x = 2 ^ 3 ^ 4')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].values[1].type == 'BinaryOp'
       and ast.body[1].stmts[1].values[1].op == 'op_pow'
       and ast.body[1].stmts[1].values[1].left.value == 2
       and ast.body[1].stmts[1].values[1].right.type == 'BinaryOp'
       and ast.body[1].stmts[1].values[1].right.op == 'op_pow'
end)

add_test('parser_45', function()
    local tokens = core.TOKN('local t = {x = 1, [1] = 2}')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].values[1].type == 'TableConstructor'
       and tgetn(ast.body[1].stmts[1].values[1].fields) == 2
       and ast.body[1].stmts[1].values[1].fields[1].kind == 'keyvalue'
       and ast.body[1].stmts[1].values[1].fields[2].kind == 'key'
end)

add_test('parser_46', function()
    local tokens = core.TOKN('function foo(...) end')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].type == 'FunctionDecl'
       and ast.body[1].stmts[1].params.has_vararg == true
       and tgetn(ast.body[1].stmts[1].params.names) == 0
end)

add_test('parser_47', function()
    local tokens = core.TOKN('x = 1; y = 2')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and tgetn(ast.body[1].stmts) == 2
       and ast.body[1].stmts[1].type == 'Assignment'
       and ast.body[1].stmts[2].type == 'Assignment'
end)

add_test('parser_48', function()
    local tokens = core.TOKN("local x = 'a' .. 'b' .. 'c'")
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].values[1].type == 'BinaryOp'
       and ast.body[1].stmts[1].values[1].op == 'concat'
       and ast.body[1].stmts[1].values[1].left.type == 'Literal'
       and ast.body[1].stmts[1].values[1].right.type == 'BinaryOp'
       and ast.body[1].stmts[1].values[1].right.op == 'concat'
end)

add_test('parser_49', function()
    local tokens = core.TOKN('local x = a[b][c]')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].values[1].type == 'Var'
       and ast.body[1].stmts[1].values[1].base.type == 'Var'
       and ast.body[1].stmts[1].values[1].indexer.index.base.name == 'c'
       and ast.body[1].stmts[1].values[1].base.indexer.index.base.name == 'b'
end)

add_test('parser_50', function()
    local tokens = core.TOKN('local x = a.b[c]')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].values[1].type == 'Var'
       and ast.body[1].stmts[1].values[1].base.base.base.name == 'a'
       and ast.body[1].stmts[1].values[1].base.indexer.member == 'b'
       and ast.body[1].stmts[1].values[1].indexer.index.base.name == 'c'
end)

add_test('parser_51', function()
    local tokens = core.TOKN('local x = foo()()')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].values[1].type == 'CallExpr'
       and ast.body[1].stmts[1].values[1].func.type == 'CallExpr'
       and ast.body[1].stmts[1].values[1].func.func.base.name == 'foo'
       and tgetn(ast.body[1].stmts[1].values[1].args) == 0
       and tgetn(ast.body[1].stmts[1].values[1].func.args) == 0
end)

add_test('parser_52', function()
    local tokens = core.TOKN('local x = a:b().c')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].values[1].type == 'Var'
       and ast.body[1].stmts[1].values[1].base.type == 'CallExpr'
       and ast.body[1].stmts[1].values[1].base.is_method == true
       and ast.body[1].stmts[1].values[1].base.method == 'b'
       and ast.body[1].stmts[1].values[1].indexer.member == 'c'
end)

add_test('parser_53', function()
    local tokens = core.TOKN('if a == b then end')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].type == 'IfStatement'
       and ast.body[1].stmts[1].clauses[1].condition.type == 'BinaryOp'
       and ast.body[1].stmts[1].clauses[1].condition.op == 'op_eq'
end)

add_test('parser_54', function()
    local tokens = core.TOKN('local x = a or b')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].values[1].type == 'BinaryOp'
       and ast.body[1].stmts[1].values[1].op == 'or'
end)

add_test('parser_55', function()
    local tokens = core.TOKN('local x = a and b')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].values[1].type == 'BinaryOp'
       and ast.body[1].stmts[1].values[1].op == 'and'
end)

add_test('parser_56', function()
    local tokens = core.TOKN('if not x then end')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].type == 'IfStatement'
       and ast.body[1].stmts[1].clauses[1].condition.type == 'UnaryOp'
       and ast.body[1].stmts[1].clauses[1].condition.op == 'not'
end)

add_test('parser_57', function()
    local tokens = core.TOKN('function foo() return 1, 2 end')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].type == 'FunctionDecl'
       and ast.body[1].stmts[1].body.ret.type == 'Return'
       and tgetn(ast.body[1].stmts[1].body.ret.exprs) == 2
end)

add_test('parser_58', function()
    local tokens = core.TOKN('while true do return 1 end')
    local ast = core.PARS(tokens)
    return ast.type == 'Chunk'
       and ast.body[1].stmts[1].type == 'WhileLoop'
       and ast.body[1].stmts[1].block.ret.type == 'Return'
       and tgetn(ast.body[1].stmts[1].block.ret.exprs) == 1
end)
