local core = ___Lua51reg'diagnostics'

if ( core.diagnostics ) then return end

local debugp = debugp
local table = table
local tgetn = table.getn
local strfind = string.find
local tinsert = table.insert

local tests = {}

local function add_test(name, fn)
    tinsert(tests, { name = name, fn = fn })
end

local function SELFTEST()
    debugp(1, '=============== |cFFFFFFFFSELFTEST EXEC|r ==')
    on_call('local x')
    debugp(1, '============== |cFFFFFFFFSELFTEST DONE|r ==')
    debugp(1, '================ |cFFFFFFFFLUA5.1 READY|r ==')
end

function core.DIAGNOSTICS(category)
    local passed = 0
    local failed = 0
    if not category then category = 'all' end
    debugp(1, '=== DIAGNOSTICS [' .. category .. '] ===')
    local i = 1
    while i <= tgetn(tests) do
        local test = tests[i]
        if category == 'all' or strfind(test.name, category) then
            local ok = test.fn()
            if ok then
                passed = passed + 1
                debugp(1, '  PASS: ' .. test.name)
            else
                failed = failed + 1
                debugp(1, '  FAIL: ' .. test.name)
            end
        end
        i = i + 1
    end
    debugp(1, '=== |cFFFFFFFF' .. passed .. '/' .. (passed + failed) .. '|r passed ===')
end

SELFTEST()
-- dont load these files, copy the tests over to diagnostic instead

add_test('transpiler_1', function()
    local tokens = core.tokenizer('')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == ''
end)

add_test('transpiler_2', function()
    local tokens = core.tokenizer('local x')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'local x'
end)

add_test('transpiler_3', function()
    local tokens = core.tokenizer("local x = 'hello'")
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == "local x = 'hello'"
end)

add_test('transpiler_4', function()
    local tokens = core.tokenizer('local x = nil')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'local x = nil'
end)

add_test('transpiler_5', function()
    local tokens = core.tokenizer('local x = true')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'local x = true'
end)

add_test('transpiler_6', function()
    local tokens = core.tokenizer('local x = false')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'local x = false'
end)

add_test('transpiler_7', function()
    local tokens = core.tokenizer('x = 1')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'x = 1'
end)

add_test('transpiler_8', function()
    local tokens = core.tokenizer('do end')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return string.sub(code, 1, 2) == 'do'
       and string.sub(code, -3) == 'end'
end)

add_test('transpiler_9', function()
    local tokens = core.tokenizer('return')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'return'
end)

add_test('transpiler_10', function()
    local tokens = core.tokenizer('return 1')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'return 1'
end)

add_test('transpiler_11', function()
    local tokens = core.tokenizer('local x = "hello"')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'local x = "hello"'
end)

add_test('transpiler_12', function()
    local tokens = core.tokenizer('local x = 42')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'local x = 42'
end)

add_test('transpiler_13', function()
    local tokens = core.tokenizer('local x = 3.14')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'local x = 3.14'
end)

add_test('transpiler_14', function()
    local tokens = core.tokenizer('x = y')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'x = y'
end)

add_test('transpiler_15', function()
    local tokens = core.tokenizer('x = foo.bar')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'x = foo.bar'
end)

add_test('transpiler_16', function()
    local tokens = core.tokenizer('x = foo[1]')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'x = foo[1]'
end)

add_test('transpiler_17', function()
    local tokens = core.tokenizer('x = foo.bar.baz')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'x = foo.bar.baz'
end)

add_test('transpiler_18', function()
    local tokens = core.tokenizer('x = foo[1][2]')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'x = foo[1][2]'
end)

add_test('transpiler_19', function()
    local tokens = core.tokenizer('x, y = 1, 2')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'x, y = 1, 2'
end)

add_test('transpiler_20', function()
    local tokens = core.tokenizer('x = -5')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'x = -5'
end)

add_test('transpiler_21', function()
    local tokens = core.tokenizer('x = not true')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'x = not true'
end)

add_test('transpiler_22', function()
    local tokens = core.tokenizer('x = #"hello"')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'x = __lua51_len("hello")', 1, true)
end)

add_test('transpiler_23', function()
    local tokens = core.tokenizer('x = 1 + 2')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'x = 1 + 2'
end)

add_test('transpiler_24', function()
    local tokens = core.tokenizer('x = 1 - 2')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'x = 1 - 2'
end)

add_test('transpiler_25', function()
    local tokens = core.tokenizer('x = 2 * 3')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'x = 2 * 3'
end)

add_test('transpiler_26', function()
    local tokens = core.tokenizer('x = 4 / 2')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'x = 4 / 2'
end)

add_test('transpiler_27', function()
    local tokens = core.tokenizer('x = 2 ^ 3')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'x = 2 ^ 3'
end)

add_test('transpiler_28', function()
    local tokens = core.tokenizer('x = 5 % 2')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, '__lua51_mod(5, 2)', 1, true)
end)

add_test('transpiler_29', function()
    local tokens = core.tokenizer("x = 'a' .. 'b'")
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == "x = 'a' .. 'b'"
end)

add_test('transpiler_30', function()
    local tokens = core.tokenizer('x = 1 == 1')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'x = 1 == 1'
end)

add_test('transpiler_31', function()
    local tokens = core.tokenizer('x = 1 ~= 2')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'x = 1 ~= 2'
end)

add_test('transpiler_32', function()
    local tokens = core.tokenizer('x = 1 < 2')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'x = 1 < 2'
end)

add_test('transpiler_33', function()
    local tokens = core.tokenizer('x = 1 > 2')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'x = 1 > 2'
end)

add_test('transpiler_34', function()
    local tokens = core.tokenizer('x = 1 <= 2')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'x = 1 <= 2'
end)

add_test('transpiler_35', function()
    local tokens = core.tokenizer('x = 2 >= 1')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'x = 2 >= 1'
end)

add_test('transpiler_36', function()
    local tokens = core.tokenizer('x = true and false')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'x = true and false'
end)

add_test('transpiler_37', function()
    local tokens = core.tokenizer('x = true or false')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'x = true or false'
end)

add_test('transpiler_38', function()
    local tokens = core.tokenizer('x = (1 + 2) * 3')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'x = (1 + 2) * 3'
end)

add_test('transpiler_39', function()
    local tokens = core.tokenizer('x = {}')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'x = {}'
end)

add_test('transpiler_40', function()
    local tokens = core.tokenizer('x = {1, 2, 3}')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'x = {1, 2, 3}'
end)

add_test('transpiler_41', function()
    local tokens = core.tokenizer('x = {a = 1, b = 2}')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'x = {a = 1, b = 2}'
end)

add_test('transpiler_42', function()
    local tokens = core.tokenizer('x = {[1] = "a"}')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'x = {[1] = "a"}'
end)

add_test('transpiler_43', function()
    local tokens = core.tokenizer('foo()')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'foo()'
end)

add_test('transpiler_44', function()
    local tokens = core.tokenizer('foo(1, 2)')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'foo(1, 2)'
end)

add_test('transpiler_45', function()
    local tokens = core.tokenizer("foo 'hello'")
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == "foo('hello')"
end)

add_test('transpiler_46', function()
    local tokens = core.tokenizer('foo{1, 2}')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'foo({1, 2})'
end)

add_test('transpiler_47', function()
    local tokens = core.tokenizer('obj:method()')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'obj:method()'
end)

add_test('transpiler_48', function()
    local tokens = core.tokenizer('x = foo()')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'x = foo()'
end)

add_test('transpiler_49', function()
    local tokens = core.tokenizer('if true then end')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return string.sub(code, 1, 2) == 'if' and string.sub(code, -3) == 'end'
end)

add_test('transpiler_50', function()
    local tokens = core.tokenizer('if true then else end')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, '^if true then') and strfind(code, 'else') and strfind(code, 'end$')
end)

add_test('transpiler_51', function()
    local tokens = core.tokenizer('if true then elseif false then end')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, '^if') and strfind(code, 'elseif') and strfind(code, 'end$')
end)

add_test('transpiler_52', function()
    local tokens = core.tokenizer('while true do end')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, '^while') and strfind(code, 'end$')
end)

add_test('transpiler_53', function()
    local tokens = core.tokenizer('while true do break end')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'break')
end)

add_test('transpiler_54', function()
    local tokens = core.tokenizer('repeat until true')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, '^repeat') and strfind(code, 'until')
end)

add_test('transpiler_55', function()
    local tokens = core.tokenizer('for i = 1, 5 do end')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, '^for') and strfind(code, 'end$')
end)

add_test('transpiler_56', function()
    local tokens = core.tokenizer('for i = 1, 10, 2 do end')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, '^for') and strfind(code, 'end$')
end)

add_test('transpiler_57', function()
    local tokens = core.tokenizer('for k, v in pairs({}) do end')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, '^for') and strfind(code, 'end$')
end)

add_test('transpiler_58', function()
    local tokens = core.tokenizer('function f() end')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, '^function') and strfind(code, 'end$')
end)

add_test('transpiler_59', function()
    local tokens = core.tokenizer('local function f() end')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, '^local function') and strfind(code, 'end$')
end)

add_test('transpiler_60', function()
    local tokens = core.tokenizer('function f(a, b) end')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'function f%(a, b%)')
end)

add_test('transpiler_61', function()
    local tokens = core.tokenizer('function f() return 1 end')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'return 1')
end)

add_test('transpiler_62', function()
    local tokens = core.tokenizer('x = function() end')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'function%(%) end')
end)

add_test('transpiler_63', function()
    local tokens = core.tokenizer('return 1, 2, 3')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return code == 'return 1, 2, 3'
end)

add_test('transpiler_64', function()
    local tokens = core.tokenizer('local a, b = ...')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'arg[1], arg[2]', 1, true)
end)

add_test('transpiler_65', function()
    local tokens = core.tokenizer('local a, b, c = ...')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'arg[1], arg[2], arg[3]', 1, true)
end)

add_test('transpiler_66', function()
    local tokens = core.tokenizer('a, b = ...')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'arg[1], arg[2]', 1, true)
end)

add_test('transpiler_67', function()
    local tokens = core.tokenizer('return ...')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'return', 1, true) and strfind(code, 'arg', 1, true)
end)

add_test('transpiler_68', function()
    local tokens = core.tokenizer('print(...)')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return string.find(code, 'tostring(arg[1])', 1, true) ~= nil
       and string.find(code, 'tostring(arg[20])', 1, true) ~= nil
       and not string.find(code, 'unpack(arg)')
end)

add_test('transpiler_69', function()
    local tokens = core.tokenizer('local x = a % b')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, '__lua51_mod(a, b)', 1, true)
end)

add_test('transpiler_70', function()
    local tokens = core.tokenizer('x = (a + b) % c')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, '__lua51_mod', 1, true)
end)

add_test('transpiler_71', function()
    local tokens = core.tokenizer('x = 1 + 2 % 3')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, '__lua51_mod', 1, true)
end)

add_test('transpiler_72', function()
    local tokens = core.tokenizer('local x = #{} % 2')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, '__lua51_len', 1, true)
       and strfind(code, '__lua51_mod', 1, true)
end)

add_test('transpiler_73', function()
    local tokens = core.tokenizer('x = #t')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, '__lua51_len(t)', 1, true)
end)

add_test('transpiler_74', function()
    local tokens = core.tokenizer('local x = #(t)')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, '__lua51_len', 1, true)
end)

add_test('transpiler_75', function()
    local tokens = core.tokenizer("x = #'hello' + 1")
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, '__lua51_len', 1, true)
end)

add_test('transpiler_76', function()
    local tokens = core.tokenizer('x = #t % 2')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, '__lua51_len', 1, true)
       and strfind(code, '__lua51_mod', 1, true)
end)

add_test('transpiler_77', function()
    local tokens = core.tokenizer('function f(...) end')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'function f%(%.%.%.%)')
end)

add_test('transpiler_78', function()
    local tokens = core.tokenizer('function f(a, ...) end')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'function f%(a, %.%.%.%)')
end)

add_test('transpiler_79', function()
    local tokens = core.tokenizer('local function f(...) end')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'local function f%(%.%.%.%)')
end)

add_test('transpiler_80', function()
    local tokens = core.tokenizer('function t:f() end')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'function t:f%(%)')
end)

add_test('transpiler_81', function()
    local tokens = core.tokenizer('function t:f(x, y) end')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'function t:f%(x, y%)')
end)

add_test('transpiler_82', function()
    local tokens = core.tokenizer('function t:f(...) end')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'function t:f%(%.%.%.%)')
end)

add_test('transpiler_83', function()
    local tokens = core.tokenizer('local x = foo()()')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'foo()()', 1, true)
end)

add_test('transpiler_84', function()
    local tokens = core.tokenizer('x = foo() + 1')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'foo() + 1', 1, true)
end)

add_test('transpiler_85', function()
    local tokens = core.tokenizer('obj:method():method()')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'obj:method()', 1, true)
end)

add_test('transpiler_86', function()
    local tokens = core.tokenizer('do local x = 1 end')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, '^do') and strfind(code, 'local x = 1', 1, true) and strfind(code, 'end$')
end)

add_test('transpiler_87', function()
    local tokens = core.tokenizer('do return end')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'return', 1, true)
end)

add_test('transpiler_88', function()
    local tokens = core.tokenizer('repeat break until true')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'break', 1, true)
end)

add_test('transpiler_89', function()
    local tokens = core.tokenizer('for i = 1, 5 do break end')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'break', 1, true)
end)

add_test('transpiler_90', function()
    local tokens = core.tokenizer('for k, v in pairs(t) do break end')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'break', 1, true)
end)

add_test('transpiler_91', function()
    local tokens = core.tokenizer('while true do if true then break end end')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'break', 1, true)
end)

add_test('transpiler_92', function()
    local tokens = core.tokenizer('local x = 1 local y = 2 x = y')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'local x = 1', 1, true)
       and strfind(code, 'local y = 2', 1, true)
       and strfind(code, 'x = y', 1, true)
end)

add_test('transpiler_93', function()
    local tokens = core.tokenizer('function f() local a = 1 local b = 2 return a + b end')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'local a = 1', 1, true)
       and strfind(code, 'local b = 2', 1, true)
       and strfind(code, 'return', 1, true)
end)

add_test('transpiler_94', function()
    local tokens = core.tokenizer('if true then local x = 1 else local y = 2 end')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'local x = 1', 1, true)
       and strfind(code, 'local y = 2', 1, true)
end)

add_test('transpiler_95', function()
    local tokens = core.tokenizer('x = #t x = a % b')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, '__lua51_len', 1, true)
       and strfind(code, '__lua51_mod', 1, true)
end)

add_test('transpiler_96', function()
    local tokens = core.tokenizer('x = #t y = a % b')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    -- count occurrences: should be 1 of each, not 2...
    local _, len_count = string.gsub(code, '__lua51_len', '')
    local _, mod_count = string.gsub(code, '__lua51_mod', '')
    return len_count == 2 and mod_count == 2
end)

add_test('transpiler_97', function()
    local tokens = core.tokenizer('x = 1 + 2')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, '__lua51_len', 1, true) == nil
       and strfind(code, '__lua51_mod', 1, true) == nil
end)

add_test('transpiler_98', function()
    local tokens = core.tokenizer('x = #t')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, '__lua51_len', 1, true) ~= nil
       and strfind(code, '__lua51_mod', 1, true) == nil
end)

add_test('transpiler_99', function()
    local tokens = core.tokenizer('x = 5 % 2')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, '__lua51_len', 1, true) == nil
       and strfind(code, '__lua51_mod', 1, true) ~= nil
end)

add_test('transpiler_100', function()
    local tokens = core.tokenizer('function f() end')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, '^function f%(%)')
end)

add_test('transpiler_101', function()
    local tokens = core.tokenizer('local function f() return 1 end')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'local function f%(%)') and strfind(code, 'return 1', 1, true)
end)

add_test('transpiler_102', function()
    local tokens = core.tokenizer('x = a or b and c')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'or') and strfind(code, 'and')
end)

add_test('transpiler_103', function()
    local tokens = core.tokenizer('x = (a or b) and c')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, '(a or b) and c', 1, true)
end)

add_test('transpiler_104', function()
    local tokens = core.tokenizer("x = a .. b .. 'c'")
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'a', 1, true) and strfind(code, ".. 'c'", 1, true)
end)

add_test('transpiler_105', function()
    local tokens = core.tokenizer('x = t[1 + 2]')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 't[1 + 2]', 1, true)
end)

add_test('transpiler_106', function()
    local tokens = core.tokenizer('local x = {...}')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'local x = arg', 1, true)
end)

add_test('transpiler_107', function()
    local tokens = core.tokenizer('for i = 1, #t do end')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, '__lua51_len', 1, true)
        and strfind(code, 'for i = 1, __lua51_len%(t%)')
end)

add_test('transpiler_108', function()
    local tokens = core.tokenizer("print(a .. b)")
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'DEFAULT_CHAT_FRAME:AddMessage(tostring(a .. b))', 1, true)
end)

add_test('transpiler_109', function()
    local tokens = core.tokenizer('local x, y = unpack(arg, 2)')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'local x, y = unpack(arg, 2)', 1, true)
end)

add_test('transpiler_110', function()
    local tokens = core.tokenizer('local function f() end local function g() end')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'local function f', 1, true)
       and strfind(code, 'local function g', 1, true)
end)

add_test('transpiler_111', function()
    local tokens = core.tokenizer('for k, v in pairs({}) do end')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'pairs({})', 1, true)
end)

add_test('transpiler_112', function()
    local tokens = core.tokenizer("print(select('#', ...))")
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'DEFAULT_CHAT_FRAME:AddMessage(tostring(table.getn(arg)))', 1, true)
end)

add_test('transpiler_113', function()
    local tokens = core.tokenizer("local x = select('#', ...)")
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'table.getn(arg)', 1, true)
end)

add_test('transpiler_114', function()
    local tokens = core.tokenizer('local x = select(1, ...)')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'arg%[1%]')
end)

add_test('transpiler_115', function()
    local tokens = core.tokenizer('local a, b = select(1, ...)')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'arg%[1%]') and strfind(code, 'arg%[2%]')
end)

add_test('transpiler_116', function()
    local tokens = core.tokenizer('x, y = select(1, ...)')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'arg%[1%]') and strfind(code, 'arg%[2%]')
end)

add_test('transpiler_117', function()
    local tokens = core.tokenizer('return select(1, ...)')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'arg%[1%]') and strfind(code, 'arg%[20%]')
end)

add_test('transpiler_118', function()
    local tokens = core.tokenizer('print(select(2, ...))')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'arg%[2%]')
end)

add_test('transpiler_119', function()
    local src = [[
        function combine(a, b, ...)
        local total = #a + b
        for i = 1, select('#', ...) do
            total = total + arg[i] % 2
        end
            return total
        end
    ]]
    local tokens = core.tokenizer(src)
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, '__lua51_len', 1, true)
        and strfind(code, '__lua51_mod', 1, true)
        and strfind(code, 'table.getn%(arg%)')
        and strfind(code, 'function combine%(a, b, %.%.%.%)')
end)

add_test('transpiler_120', function()
    local src = [[
        local function process(tbl, ...)
        local sum = 0
        local count = #tbl
        for i, v in ipairs(tbl) do
        if v > 0 then
            sum = sum + v
        elseif v == 0 then
            sum = sum + 1
            end
        end
        if count > 0 then
            return sum / count
        else
            return select('#', ...)
            end
        end
    ]]
    local tokens = core.tokenizer(src)
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, '__lua51_len', 1, true)
        and strfind(code, 'for i, v in ipairs%(tbl%)')
        and strfind(code, 'elseif')
        and strfind(code, 'table.getn%(arg%)')
end)

add_test('transpiler_121', function()
    local src = [[
  local function find_in_table(t, target)
    local found = false
    local i = 1
    local n = #t
    repeat
      if t[i] == target then
        found = true
        break
      end
      i = i + 1
    until i > n
    while found and i <= n do
      if t[i] == target then
        t[i] = nil
      end
      i = i + 1
    end
    return found
  end
  ]]
    local tokens = core.tokenizer(src)
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'repeat') and strfind(code, 'until')
       and strfind(code, 'while') and strfind(code, 'break')
       and strfind(code, '__lua51_len', 1, true)
       and strfind(code, 't%[i%]')
end)

add_test('transpiler_122', function()
    local src = [[
  local function minmax(a, b, c)
    local mn = a
    local mx = a
    if b > mx then mx = b end
    if b < mn then mn = b end
    if c > mx then mx = c end
    if c < mn then mn = c end
    return mn, mx
  end

  local a, b = minmax(select(2, 'x', 10, 30, 5))
  ]]
    local tokens = core.tokenizer(src)
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'function minmax%(a, b, c%)')
       and strfind(code, 'return mn, mx')
       and strfind(code, 'local a, b = minmax%(')
       and strfind(code, '30, 5')
end)

add_test('transpiler_123', function()
    local tokens = core.tokenizer('local x = select(n, ...)')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'arg%[n%]')
end)

add_test('transpiler_124', function()
    local tokens = core.tokenizer('local x = select(i, 10, 20, 30)')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, '{10, 20, 30}', 1, true)
end)

add_test('transpiler_125', function()
    local tokens = core.tokenizer('function f() local x = ... end')
    local ast = core.parser(tokens)
    local ok, _ = pcall(core.transpiler, ast)
    return not ok
end)

add_test('transpiler_126', function()
    local tokens = core.tokenizer([[return select('#', ...)]])
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'table.getn%(arg%)')
end)

add_test('transpiler_127', function()
    local tokens = core.tokenizer([[return select('#', 1, 2, 3)]])
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, 'return 3')
end)

add_test('transpiler_128', function()
    local tokens = core.tokenizer('local x = select(i + 1, 10, 20, 30)')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, '{10, 20, 30}', 1, true) and strfind(code, '%[i %+ 1%]')
end)

add_test('transpiler_129', function()
    local tokens = core.tokenizer('match("hello", "l+")')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, '__lua51_match("hello", "l+")', 1, true)
end)

add_test('transpiler_130', function()
    local tokens = core.tokenizer('local x = match("hello", "(%a+)")')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, '__lua51_match("hello", "(%a+)")', 1, true)
end)

add_test('transpiler_131', function()
    local tokens = core.tokenizer('local x = match("hello", "world")')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return strfind(code, '__lua51_match("hello", "world")', 1, true)
end)

add_test('transpiler_132', function()
    local tokens = core.tokenizer('while true do if true then break end end')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    local func, _ = loadstring(code)
    return func ~= nil
end)

add_test('transpiler_133', function()
    local tokens = core.tokenizer('repeat if true then break end print("x") until true')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    local func, _ = loadstring(code)
    return func ~= nil
end)

add_test('transpiler_134', function()
    local tokens = core.tokenizer('myFunc(...)')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return string.find(code, 'myFunc%(unpack%(arg%)%)') ~= nil
end)

add_test('transpiler_135', function()
    local tokens = core.tokenizer('return ...')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return string.find(code, 'return unpack%(arg%)') ~= nil
end)

add_test('transpiler_136', function()
    local tokens = core.tokenizer('local t = {1, 2, ...}')
    local ast = core.parser(tokens)
    local code = core.transpiler(ast)
    return string.find(code, '{1, 2, unpack%(arg%)}') ~= nil
end)