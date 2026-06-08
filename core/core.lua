if ( _LUA51_CORE_VERSION ) then return end

if not _LUA51_CORE_DEBUG_CONTROLLER then _LUA51_CORE_DEBUG_CONTROLLER = 0 end

_LUA51_CORE_VERSION = '1.0'

local type = type
local pairs = pairs
local pcall = pcall
local error = error
local assert = assert
local string = string
local _G = getfenv(0)
local tstr = tostring
local GetTime = GetTime
local setfenv = setfenv
local tonumber = tonumber
local strfind = string.find
local debugstack = debugstack
local loadstring = loadstring
local debugprint = debugprint
local strformat = string.format
local CHAT = DEFAULT_CHAT_FRAME
local setmetatable = setmetatable
local SlashCmdList = SlashCmdList
local IsAddOnLoaded = IsAddOnLoaded
local geterrorhandler = geterrorhandler

local dbg_ready = IsAddOnLoaded'!Debugger'

local core, namespaces = {}, {}
local env = setmetatable({_G=_G}, {__index=_G})

--------- settings ------------------------

if not _LUA51_CORE_DEBUG_FLAGS then _LUA51_CORE_DEBUG_FLAGS = {
    core        = false,
    tokenizer   = false,
    parser      = false,
    transpiler  = false,
    diagnostics = false,
}end

local RUN_TOKENIZER     = true
local RUN_PARSER        = true
local RUN_TRANSPILER    = false
local RUN_LOADER        = false

--------- core ----------------------------

local function debugp(lvl, msg)
    if _LUA51_CORE_DEBUG_CONTROLLER == 0 then return end
    assert(type(lvl) == 'number', 'debugp: lvl ~= number')
    if lvl > _LUA51_CORE_DEBUG_CONTROLLER then return end

    local _, _, file = strfind(debugstack(2, 1, 1), '([^\\]+%.lua)')
    local matched = false
    for fragment, flag in pairs(_LUA51_CORE_DEBUG_FLAGS) do
        if strfind(file, fragment) then
            matched = true
            if not flag then return end
            break
        end
    end
    if not matched then return end
    if dbg_ready then debugprint(msg) return end
    CHAT:AddMessage(msg, 1, 1, 0)
end

local function print_flags()
    local function c(data)
        if type(data) == 'number' then
            return (data == 0) and '|cffff0000' or '|cffffffff'
        else
            return data and '|cffffffff' or '|cffff0000'
        end
    end
    debugp(1, '=========== |cFFFFFFFFLUA5.1 FLAG STATUS|r ==')
    debugp(1, '|cFFFFFFFFACTIVE LEVEL:     ' .. _LUA51_CORE_DEBUG_CONTROLLER)
    debugp(1, '')
    debugp(1, c(_LUA51_CORE_DEBUG_FLAGS.core)       .. 'FLAG CORE:        ' .. tstr(_LUA51_CORE_DEBUG_FLAGS.core))
    debugp(1, c(_LUA51_CORE_DEBUG_FLAGS.tokenizer)  .. 'FLAG TOKE:        ' .. tstr(_LUA51_CORE_DEBUG_FLAGS.tokenizer))
    debugp(1, c(_LUA51_CORE_DEBUG_FLAGS.parser)     .. 'FLAG parser:        ' .. tstr(_LUA51_CORE_DEBUG_FLAGS.parser))
    debugp(1, c(_LUA51_CORE_DEBUG_FLAGS.transpiler) .. 'FLAG TRAN:        ' .. tstr(_LUA51_CORE_DEBUG_FLAGS.transpiler))
    debugp(1, c(_LUA51_CORE_DEBUG_FLAGS.diagnostics).. 'FLAG DIAG:         ' .. tstr(_LUA51_CORE_DEBUG_FLAGS.diagnostics)) -- i need an extra space here, or its not in aligned, nice
    debugp(1, '')
    debugp(1, c(RUN_LOADER)     .. 'FLAG on_call:        ' .. tstr(RUN_LOADER))
end

local function register_module(name)
    if not core.tokenizer then debugp(1, '================== |cFFFFFFFFENV STATUS|r ==') end
    setfenv(2, env)
    debugp(1, 'register_module: set to: '..name)
    return core
end

local function check_functions(param)
    debugp(1, '================= |cFFFFFFFFFUNCHECK|r ==')
    local err_state, dbg_state, ls_state
    -- blizz must return false + string + exact msg
    -- + geterrorhandler == _ERRORMESSAGE checks
    if param == 'err' or param == nil then
        local ok, result = pcall(error, '1') -- must pass dummy string
        if ok == false and result == '1' and geterrorhandler and _ERRORMESSAGE and geterrorhandler() == _ERRORMESSAGE then
            err_state = true
            debugp(1, 'check_functions: ERR check 1: ' .. tstr(err_state))
        elseif ok == false and (result ~= '1' or not geterrorhandler or not _ERRORMESSAGE or geterrorhandler() ~= _ERRORMESSAGE) then
            err_state = 'tainted'
            debugp(1, 'check_functions: ERR check 2: ' .. tstr(err_state))
        else
            err_state = 'broken'
            debugp(1, 'check_functions: ERR check 3: ' .. tstr(err_state))
        end
        if param == 'err' then return err_state end
    end
    -- must return true + string
    if param == 'dbg' or param == nil then
        local ok, result = pcall(debugstack, 1, 1, 1)
        dbg_state = (ok and type(result) == 'string')
        debugp(1, 'check_functions: DBG state check: ' .. tstr(dbg_state))
        if param == 'dbg' then return dbg_state end
    end
    -- must return true + function
    if param == 'ls' or param == nil then
        local ok, result = pcall(loadstring, '')
        ls_state = (ok and type(result) == 'function')
        debugp(1, 'check_functions: LS state check: ' .. tstr(ls_state))
        if param == 'ls' then return ls_state end
    end
    return err_state, dbg_state, ls_state
end

local function on_error(err_state)
    debugp(1, '================= |cFFFFFFFFERROR HANDLER|r ==')
    local msg = 'Lua5.1 INTERNAL on_error: '..err_state..'  |  Please report this on Github!'
    -- check core func : error()
    local err_state_check = check_functions'err'
    local is_broken = (err_state_check == 'broken')
    if not is_broken then
        -- try to detect if blizzards errhandler is active
        if err_state_check == true then
            -- case1: blizzards original handler + frame
            if ScriptErrors then
                ScriptErrors:SetHeight(160)
                debugp(1, 'CASE 1 on_error: '..msg)
                error(msg, 3) --v2
            else
                -- case2: blizzards handler active but no frame
                CHAT:AddMessage(msg, 1,0,0)
                debugp(1, 'CASE 2 on_error: '..msg)
                -- still call error here for proper background processing
                ---> doing /run error('test') will print + ScriptErrors, but error('test') in code does not print
                error(msg, 3) --v2
            end
        else
            -- case 3: no blizzard handler
            -- custom handlers usually disable blizz frame, so just
            -- throw error at them, they do teh rest
            debugp(1, 'CASE 3 on_error: '..msg)
            error(msg, 3) --v2
        end
    else
        -- case 4: error() is broken or whatever, give up
        -- and print. its not our problem anymore
        debugp(1, 'CASE 4 on_error: '..msg)
        CHAT:AddMessage(msg, 1,0,0)
    end
end

local function on_call(src)
    assert(type(src) == 'string', 'on_call: src ~= string')
    debugp(1, '================== |cFFFFFFFFLOAD START|r ==')
    debugp(1, '|cFFFFFFFFLOAD: Raw src: '..src)
    local total_start = GetTime()
    local tokens, ast, code, func, err_state

    if not RUN_TOKENIZER then return end
    local t_start = GetTime()
    tokens = core.tokenizer(src)
    assert(tokens, 'on_call: tokenizer returned nil')
    local t_end = GetTime()
    debugp(1, 'tokenizer passed, processing...')
    debugp(3, strformat('on_call: Tokenize: %.3f ms', (t_end - t_start) * 1000))

    if not RUN_PARSER then return end
    local p_start = GetTime()
    ast = core.parser(tokens)
    assert(ast, 'on_call: parser returned nil')
    local p_end = GetTime()
    debugp(1, 'parser passed, processing...')
    debugp(3, strformat('on_call: Parse: %.3f ms', (p_end - p_start) * 1000))

    if not RUN_TRANSPILER then return end
    local tr_start = GetTime()
    code = core.transpiler(ast)
    assert(code, 'on_call: transpiler returned nil')
    local tr_end = GetTime()
    debugp(1, 'transpiler passed, processing...')
    debugp(3, strformat('on_call: Transpile: %.3f ms', (tr_end - tr_start) * 1000))

    if not RUN_LOADER then return end
    local l_start = GetTime()
    -- get addons name and files for namespaces
    assert(check_functions'dbg', 'on_call: debugstack broken, cannot parse source file')
    local stack = debugstack(2, 1, 1)
    assert(stack, 'on_call: debugstack returned nil')
    local _, _, src_file = strfind(stack, 'AddOns\\(.+)%.lua')
    assert(src_file, 'on_call: Could not extract source file from debugstack')
    local _, _, addon = strfind(src_file, '([^\\]+)\\')
    assert(addon, 'on_call: Could not extract addon name from: ' .. src_file)
    debugp(1, 'on_call: Src file: ' .. src_file .. ' - HOST: ' .. addon)

    -- create wrapper to get the vararg table
    local wrapper = 'return (function(...)\n' .. code .. '\nend)'
    assert(check_functions'ls', 'on_call: loadstring broken, cannot on_call code')
    func, err_state = loadstring(wrapper, '@' .. src_file)
    debugp(1, 'on_call: Loadstring returned: ' .. tstr(func) .. ' and err_state: ' .. tstr(err_state))
    -- main error path
    if not func then on_error(err_state) return end --v2 : has to return for case4 hits
    debugp(1, 'on_call: No errors loadstring, proceeding...')
    local l_end = GetTime()
    debugp(3, strformat('on_call: loadstring: %.3f ms', (l_end - l_start) * 1000))

    local transpile_end = GetTime()
    local transpile_ms = (transpile_end - total_start) * 1000

    local exec_start = GetTime()
    local runner = func()  -- returns the inner vararg function
    assert(type(runner) == 'function', 'on_call: runner ~= function')

    -- create private namespace table for each addon
    if not namespaces[addon] then namespaces[addon] = {} end
    debugp(1, 'on_call: namespace created: ' .. addon .. ' - TBL: ' .. tstr(namespaces[addon]))
    -- execute vararg func with full context
    local a1, a2 = runner(addon, namespaces[addon]) -- v3: capture return values now
    debugp(1, 'on_call: |cFFFFFFFFCODE executed!')

    local exec_end = GetTime()
    local exec_ms = (exec_end - exec_start) * 1000
    debugp(1, strformat('on_call: Transpile (total): %.3f ms', transpile_ms))
    debugp(1, strformat('on_call: Execution: %.3f ms', exec_ms))
    debugp(1, strformat('on_call: Overall: %.3f ms', (exec_end - total_start) * 1000))
    debugp(1, '==================== |cFFFFFFFFLOAD END|r ==')
    debugp(1, 'on_call: Passing a1: ' .. tstr(a1) .. ' and a2: ' .. tstr(a2))
    return a1, a2
end

print_flags()

--------- intern --------------------------

env.debugp   = debugp
env.on_call  = on_call
env.on_error = on_error
___Lua51reg  = register_module

--------- API ----------------------------

___Lua51    = on_call

--------- /lua51 ------------------------

if _LUA51_CORE_DEBUG_CONTROLLER == 0 then return end

SLASH_LUA511 = '/lua51'; SLASH_LUA512 = '/l51'
SlashCmdList.LUA51 = function(msg)
    debugp(1, 'CMD: '..msg)
    local _, _, cmd, rest = strfind(msg, '^%s*(%S+)%s*(.-)%s*$')
    if not cmd then
        CHAT:AddMessage'Usage: /lua51 run <code> | /lua51 lvl <0-3> | /lua51 diag <module>'
        return
    end
    if cmd == 'lvl' then
        local lvl = tonumber(rest)
        if type(lvl) ~= 'number' or lvl < 0 or lvl > 3 then
            CHAT:AddMessage'Usage: /lua51 lvl <0-3>'
            return
        end
        _LUA51_CORE_DEBUG_CONTROLLER = lvl
        CHAT:AddMessage('_LUA51_CORE_DEBUG_CONTROLLER set to ' .. _LUA51_CORE_DEBUG_CONTROLLER, 0, 1, 0)
        return
    end
    if cmd == 'run' then
        if rest == '' then
            CHAT:AddMessage'Usage: /lua51 run <code>'
            return
        end
        on_call(rest)
        return
    end
    if cmd == 'diag' then
        if rest == '' then rest = nil end
        for k, _ in pairs(_LUA51_CORE_DEBUG_FLAGS) do _LUA51_CORE_DEBUG_FLAGS[k] = false end
        if rest then
            _LUA51_CORE_DEBUG_FLAGS[rest] = true
        else
            for k, _ in pairs(_LUA51_CORE_DEBUG_FLAGS) do _LUA51_CORE_DEBUG_FLAGS[k] = true end
        end
        core.DIAGNOSTICS(rest)
        return
    end
    CHAT:AddMessage('Unknown command: ' .. cmd, 1, 0, 0)
end
