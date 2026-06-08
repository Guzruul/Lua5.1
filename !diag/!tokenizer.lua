-- dont load these files, copy the tests over to diagnostic instead

add_test('tokenizer_1', function()
    local tokens = core.tokenizer('')
    return tgetn(tokens) == 0
end)

add_test('tokenizer_2', function()
    local tokens = core.tokenizer('hello')
    return tgetn(tokens) == 1
        and tokens[1].type == 'identifier'
        and tokens[1].value == 'hello'
        and tokens[1].line == 1
        and tokens[1].column == 1
end)

add_test('tokenizer_3', function()
    local tokens = core.tokenizer('local x')
    return tgetn(tokens) == 2
        and tokens[1].type == 'keyword' and tokens[1].value == 'local'
        and tokens[2].type == 'identifier' and tokens[2].value == 'x'
end)

add_test('tokenizer_4', function()
    local tokens = core.tokenizer('local x')
    return tgetn(tokens) == 2
        and tokens[1].type == 'keyword' and tokens[1].value == 'local'
        and tokens[2].type == 'identifier' and tokens[2].value == 'x'
end)

add_test('tokenizer_5', function()
    local tokens = core.tokenizer('"hello"')
    return tgetn(tokens) == 1 and tokens[1].type == 'string'
end)

add_test('tokenizer_6', function()
    local tokens = core.tokenizer('local')
    return tgetn(tokens) == 1 and tokens[1].type == 'keyword' and tokens[1].value == 'local'
end)

add_test('tokenizer_7', function()
    local tokens = core.tokenizer('42')
    return tgetn(tokens) == 1 and tokens[1].type == 'number' and tokens[1].value == '42'
end)

add_test('tokenizer_8', function()
    local tokens = core.tokenizer("'hello'")
    return tgetn(tokens) == 1 and tokens[1].type == 'string'
end)

add_test('tokenizer_9', function()
    local tokens = core.tokenizer('[[hello]]')
    return tgetn(tokens) == 1 and tokens[1].type == 'string_long'
end)

add_test('tokenizer_10', function()
    local tokens = core.tokenizer('3.14')
    return tgetn(tokens) == 1 and tokens[1].type == 'number' and tokens[1].value == '3.14'
end)

add_test('tokenizer_11', function()
    local tokens = core.tokenizer('0xFF')
    return tgetn(tokens) == 1 and tokens[1].type == 'number' and tokens[1].value == '0xFF'
end)

add_test('tokenizer_12', function()
    local tokens = core.tokenizer('1e10')
    return tgetn(tokens) == 1 and tokens[1].type == 'number' and tokens[1].value == '1e10'
end)

add_test('tokenizer_13', function()
    local tokens = core.tokenizer('-- this is a comment')
    return tgetn(tokens) == 0
end)

add_test('tokenizer_14', function()
    local tokens = core.tokenizer('--[[this is a long comment]]')
    return tgetn(tokens) == 0
end)

add_test('tokenizer_15', function()
    local tokens = core.tokenizer('..')
    return tgetn(tokens) == 1 and tokens[1].type == 'concat'
end)

add_test('tokenizer_16', function()
    local tokens = core.tokenizer('...')
    return tgetn(tokens) == 1 and tokens[1].type == 'vararg'
end)

add_test('tokenizer_17', function()
    local tokens = core.tokenizer('.')
    return tgetn(tokens) == 1 and tokens[1].type == 'dot'
end)

add_test('tokenizer_18', function()
    local tokens = core.tokenizer('==')
    return tgetn(tokens) == 1 and tokens[1].type == 'op_eq'
end)

add_test('tokenizer_19', function()
    local tokens = core.tokenizer('~=')
    return tgetn(tokens) == 1 and tokens[1].type == 'op_ne'
end)

add_test('tokenizer_20', function()
    local tokens = core.tokenizer('<=')
    return tgetn(tokens) == 1 and tokens[1].type == 'op_le'
end)

add_test('tokenizer_21', function()
    local tokens = core.tokenizer('>=')
    return tgetn(tokens) == 1 and tokens[1].type == 'op_ge'
end)

add_test('tokenizer_22', function()
    local tokens = core.tokenizer('<')
    return tgetn(tokens) == 1 and tokens[1].type == 'op_lt'
end)

add_test('tokenizer_23', function()
    local tokens = core.tokenizer('>')
    return tgetn(tokens) == 1 and tokens[1].type == 'op_gt'
end)

add_test('tokenizer_24', function()
    local tokens = core.tokenizer('=')
    return tgetn(tokens) == 1 and tokens[1].type == 'op_assign'
end)

add_test('tokenizer_25', function()
    local tokens = core.tokenizer('_private')
    return tgetn(tokens) == 1 and tokens[1].type == 'identifier' and tokens[1].value == '_private'
end)

add_test('tokenizer_26', function()
    local tokens = core.tokenizer('local x')
    return tokens[2].column == 7
end)

add_test('tokenizer_27', function()
    local tokens = core.tokenizer('a\nb')
    return tgetn(tokens) == 2 and tokens[2].line == 2 and tokens[2].column == 1
end)

add_test('tokenizer_28', function()
    local tokens = core.tokenizer('-- comment\nhello')
    return tgetn(tokens) == 1 and tokens[1].type == 'identifier' and tokens[1].value == 'hello'
end)

add_test('tokenizer_29', function()
    local tokens = core.tokenizer('.5')
    return tgetn(tokens) == 1 and tokens[1].type == 'number' and tokens[1].value == '.5'
end)

add_test('tokenizer_30', function()
    local tokens = core.tokenizer('1e+10')
    return tgetn(tokens) == 1 and tokens[1].type == 'number' and tokens[1].value == '1e+10'
end)

add_test('tokenizer_31', function()
    local tokens = core.tokenizer('1e-10')
    return tgetn(tokens) == 1 and tokens[1].type == 'number' and tokens[1].value == '1e-10'
end)

add_test('tokenizer_32', function()
    local tokens = core.tokenizer('[==[hello]==]')
    return tgetn(tokens) == 1 and tokens[1].type == 'string_long'
end)

add_test('tokenizer_33', function()
    local tokens = core.tokenizer('[1]')
    return tgetn(tokens) == 3
        and tokens[1].type == 'lbracket'
        and tokens[2].type == 'number'
        and tokens[3].type == 'rbracket'
end)

add_test('tokenizer_34', function()
    local tokens = core.tokenizer('"\\n"')
    return tgetn(tokens) == 1 and tokens[1].type == 'string'
end)

add_test('tokenizer_35', function()
    local tokens = core.tokenizer('"\\\\"')
    return tgetn(tokens) == 1 and tokens[1].type == 'string'
end)

add_test('tokenizer_36', function()
    local tokens = core.tokenizer('"hello\\z   world"')
    return tgetn(tokens) == 1 and tokens[1].type == 'string'
end)

add_test('tokenizer_37', function()
    local tokens = core.tokenizer('[[line1\nline2]]')
    return tgetn(tokens) == 1 and tokens[1].type == 'string_long'
end)

add_test('tokenizer_38', function()
    local tokens = core.tokenizer('x -- comment')
    return tgetn(tokens) == 1 and tokens[1].type == 'identifier' and tokens[1].value == 'x'
end)

add_test('tokenizer_39', function()
    local tokens = core.tokenizer('--[[ignored]]\nhello')
    return tgetn(tokens) == 1 and tokens[1].type == 'identifier' and tokens[1].value == 'hello'
end)

add_test('tokenizer_40', function()
    local tokens = core.tokenizer('a\nb\nc')
    return tgetn(tokens) == 3
        and tokens[3].line == 3
        and tokens[3].column == 1
end)

add_test('tokenizer_41', function()
    local tokens = core.tokenizer('x = 1')
    return tgetn(tokens) == 3
        and tokens[1].column == 1
        and tokens[2].column == 3
        and tokens[3].column == 5
end)

add_test('tokenizer_42', function()
    local kws = {'and','break','do','else','elseif','end','false','for',
                 'function','if','in','nil','not','or','repeat',
                 'return','then','true','until','while'}
    local i = 1
    while i <= tgetn(kws) do
        local tokens = core.tokenizer(kws[i])
        if tgetn(tokens) ~= 1 or tokens[1].type ~= 'keyword' or tokens[1].value ~= kws[i] then
            return false
        end
        i = i + 1
    end
    return true
end)

add_test('tokenizer_43', function()
    local ok = pcall(core.tokenizer, '~')
    return ok == false
end)

add_test('tokenizer_44', function()
    local ok = pcall(core.tokenizer, '"hello')
    return ok == false
end)

add_test('tokenizer_45', function()
    local ok = pcall(core.tokenizer, "'hello")
    return ok == false
end)

add_test('tokenizer_46', function()
    local ok = pcall(core.tokenizer, '0xG')
    return ok == false
end)

add_test('tokenizer_47', function()
    local ok = pcall(core.tokenizer, '1eX')
    return ok == false
end)

add_test('tokenizer_48', function()
    local ok = pcall(core.tokenizer, '[[hello')
    return ok == false
end)

add_test('tokenizer_49', function()
    local ok = pcall(core.tokenizer, '[=[hello]==]')
    return ok == false
end)

add_test('tokenizer_50', function()
    local ok = pcall(core.tokenizer, '$')
    return ok == false
end)

add_test('tokenizer_51', function()
    local ok = pcall(core.tokenizer, '@')
    return ok == false
end)

add_test('tokenizer_52', function()
    local tokens = core.tokenizer('a\r\nb')
    return tgetn(tokens) == 2
        and tokens[2].line == 2
        and tokens[2].column == 1
end)

add_test('tokenizer_53', function()
    local tokens = core.tokenizer('a\rb')
    return tgetn(tokens) == 2
        and tokens[2].line == 2
        and tokens[2].column == 1
end)

add_test('tokenizer_54', function()
    local tokens = core.tokenizer('1.')
    return tgetn(tokens) == 2
        and tokens[1].type == 'number' and tokens[1].value == '1'
        and tokens[2].type == 'dot'
end)

add_test('tokenizer_55', function()
    local tokens = core.tokenizer('1..2')
    return tgetn(tokens) == 3
        and tokens[1].type == 'number' and tokens[1].value == '1'
        and tokens[2].type == 'concat'
        and tokens[3].type == 'number' and tokens[3].value == '2'
end)

add_test('tokenizer_56', function()
    local tokens = core.tokenizer('.5.')
    return tgetn(tokens) == 2
        and tokens[1].type == 'number' and tokens[1].value == '.5'
        and tokens[2].type == 'dot'
end)

add_test('tokenizer_57', function()
    local tokens = core.tokenizer('locally')
    return tgetn(tokens) == 1
        and tokens[1].type == 'identifier'
        and tokens[1].value == 'locally'
end)

add_test('tokenizer_58', function()
    local tokens = core.tokenizer('iffy')
    return tgetn(tokens) == 1
        and tokens[1].type == 'identifier'
        and tokens[1].value == 'iffy'
end)

add_test('tokenizer_59', function()
    local tokens = core.tokenizer('a+b*c')
    return tgetn(tokens) == 5
        and tokens[1].type == 'identifier' and tokens[1].value == 'a'
        and tokens[2].type == 'op_add'
        and tokens[3].type == 'identifier' and tokens[3].value == 'b'
        and tokens[4].type == 'op_mul'
        and tokens[5].type == 'identifier' and tokens[5].value == 'c'
end)

add_test('tokenizer_60', function()
    local tokens = core.tokenizer('[[]]')
    return tgetn(tokens) == 1 and tokens[1].type == 'string_long'
end)

add_test('tokenizer_61', function()
    local tokens = core.tokenizer('0xABCDEF')
    return tgetn(tokens) == 1
        and tokens[1].type == 'number'
        and tokens[1].value == '0xABCDEF'
end)

add_test('tokenizer_62', function()
    local tokens = core.tokenizer('"hello\\z\nworld"')
    return tgetn(tokens) == 1 and tokens[1].type == 'string'
end)

add_test('tokenizer_63', function()
    local tokens = core.tokenizer('[[a\nb\nc]]\nafter')
    return tgetn(tokens) == 2
        and tokens[1].type == 'string_long'
        and tokens[2].type == 'identifier'
        and tokens[2].line == 4
end)

add_test('tokenizer_64', function()
    local tokens = core.tokenizer('--[x\nhello')
    return tgetn(tokens) == 1
        and tokens[1].type == 'identifier'
        and tokens[1].value == 'hello'
end)
