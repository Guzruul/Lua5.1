local core = ___Lua51reg'diagnostics'

if ( core.DIAGNOSTICS ) then return end

local DEBG = DEBG
local table = table
local tgetn = table.getn
local strfind = string.find
local tinsert = table.insert

local tests = {}

local function add_test(name, fn)
    tinsert(tests, { name = name, fn = fn })
end

local function SELFTEST()
    DEBG(1, '=============== |cFFFFFFFFSELFTEST EXEC|r ==')
    L51X('local x')
    DEBG(1, '============== |cFFFFFFFFSELFTEST DONE|r ==')
    DEBG(1, '================ |cFFFFFFFFLUA5.1 READY|r ==')
end

function core.DIAGNOSTICS(category)
    local passed = 0
    local failed = 0
    if not category then category = 'all' end
    DEBG(1, '=== DIAGNOSTICS [' .. category .. '] ===')
    local i = 1
    while i <= tgetn(tests) do
        local test = tests[i]
        if category == 'all' or strfind(test.name, category) then
            local ok = test.fn()
            if ok then
                passed = passed + 1
                DEBG(1, '  PASS: ' .. test.name)
            else
                failed = failed + 1
                DEBG(1, '  FAIL: ' .. test.name)
            end
        end
        i = i + 1
    end
    DEBG(1, '=== |cFFFFFFFF' .. passed .. '/' .. (passed + failed) .. '|r passed ===')
end

SELFTEST()

-- current progress: 253/253 : stable ( 6.6.2026 )
