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


