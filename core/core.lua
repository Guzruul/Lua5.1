-- wow vanilla transpiler and service framework
-- source: https://github.com/Guzruul/Lua5.1

if ( _LUA51_CORE_VERSION ) then return end

if not _LUA51_CORE_DEBUG_CONTROLLER then _LUA51_CORE_DEBUG_CONTROLLER = 0 end

_LUA51_CORE_VERSION = '1.0'

local type = type
local pairs = pairs
local PCLL = pcall
local error = error
local ASRT = assert
local string = string
local _G = getfenv(0)
local tstr = tostring
local DBST = debugstack
local LSTR = loadstring
local GetTime = GetTime
local setfenv = setfenv
local tonumber = tonumber
local strfind = string.find
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
    -- keep false; control = !debug; var = filename, no '.lua'
    core        = false,
    tokenizer   = false,
    parser      = false,
    transpiler  = false,
    diagnostics = false,
}end

local RUN_TOKENIZER     = true
local RUN_PARSER        = true
local RUN_TRANSPILER    = true
local RUN_LOADER        = true

--------- core ----------------------------

local function DEBG(lvl, msg)
    if _LUA51_CORE_DEBUG_CONTROLLER == 0 then return end
    ASRT(type(lvl) == 'number', 'DEBG: lvl ~= number')
    if lvl > _LUA51_CORE_DEBUG_CONTROLLER then return end

    local _, _, file = strfind(DBST(2, 1, 1), '([^\\]+%.lua)')
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

local function FLGS()
    local function c(data)
        if type(data) == 'number' then
            return (data == 0) and '|cffff0000' or '|cffffffff'
        else
            return data and '|cffffffff' or '|cffff0000'
        end
    end
    DEBG(1, '=========== |cFFFFFFFFLUA5.1 FLAG STATUS|r ==')
    DEBG(1, '|cFFFFFFFFACTIVE LEVEL:     ' .. _LUA51_CORE_DEBUG_CONTROLLER)
    DEBG(1, '')
    DEBG(1, c(_LUA51_CORE_DEBUG_FLAGS.core)       .. 'FLAG CORE:        ' .. tstr(_LUA51_CORE_DEBUG_FLAGS.core))
    DEBG(1, c(_LUA51_CORE_DEBUG_FLAGS.tokenizer)  .. 'FLAG TOKE:        ' .. tstr(_LUA51_CORE_DEBUG_FLAGS.tokenizer))
    DEBG(1, c(_LUA51_CORE_DEBUG_FLAGS.parser)     .. 'FLAG PARS:        ' .. tstr(_LUA51_CORE_DEBUG_FLAGS.parser))
    DEBG(1, c(_LUA51_CORE_DEBUG_FLAGS.transpiler) .. 'FLAG TRAN:        ' .. tstr(_LUA51_CORE_DEBUG_FLAGS.transpiler))
    DEBG(1, c(_LUA51_CORE_DEBUG_FLAGS.diagnostics).. 'FLAG DIAG:         ' .. tstr(_LUA51_CORE_DEBUG_FLAGS.diagnostics)) -- i need an extra space here, or its not in aligned, nice
    DEBG(1, '')
    DEBG(1, c(RUN_LOADER)     .. 'FLAG L51X:        ' .. tstr(RUN_LOADER))
end

local function SENV(name)
    if not core.TOKN then DEBG(1, '================== |cFFFFFFFFENV STATUS|r ==') end
    setfenv(2, env)
    DEBG(1, 'SENV: set to: '..name)
    return core
end

local function CHKF(param)
    -- aka 'the bouncer', we keep him running even tho we capture all funcs
    DEBG(1, '================= |cFFFFFFFFFUNCHECK|r ==')
    -- we use PCLL as the base for our state checks,
    -- assuming safe; if not = client too corrupt;
    -- using other tools (xpcall) would start infinite loop
    local err_state, dbg_state, ls_state
    -- if error() throws, it returns false to PCLL -> (is_broken = false) -> good
    -- if error() doesn't throw, it returns true -> (is_broken = true) -> BAD!
    -- blizz must return false + string + exact msg
    -- + geterrorhandler == _ERRORMESSAGE checks
    if param == 'err' or param == nil then
        local ok, result = PCLL(error, '1') -- must pass dummy string
        if ok == false and result == '1' and geterrorhandler and _ERRORMESSAGE and geterrorhandler() == _ERRORMESSAGE then
            err_state = true
            DEBG(1, 'CHKF: ERR check 1: ' .. tstr(err_state))
        elseif ok == false and (result ~= '1' or not geterrorhandler or not _ERRORMESSAGE or geterrorhandler() ~= _ERRORMESSAGE) then
            err_state = 'tainted'
            DEBG(1, 'CHKF: ERR check 2: ' .. tstr(err_state))
        else
            err_state = 'broken'
            DEBG(1, 'CHKF: ERR check 3: ' .. tstr(err_state))
        end
        if param == 'err' then return err_state end
    end
    -- must return true + string
    if param == 'dbg' or param == nil then
        local ok, result = PCLL(DBST, 1, 1, 1)
        dbg_state = (ok and type(result) == 'string')
        DEBG(1, 'CHKF: DBG state check: ' .. tstr(dbg_state))
        if param == 'dbg' then return dbg_state end
    end
    -- must return true + function
    if param == 'ls' or param == nil then
        local ok, result = PCLL(LSTR, '')
        ls_state = (ok and type(result) == 'function')
        DEBG(1, 'CHKF: LS state check: ' .. tstr(ls_state))
        if param == 'ls' then return ls_state end
    end
    return err_state, dbg_state, ls_state
end

local function ERRT(err_state)
    DEBG(1, '================= |cFFFFFFFFERROR HANDLER|r ==')
    -- ERRT need special handling for transpiler bugs for 3 reasons:
    -- 1) transpiler bugs bypass blizz proper error handle due to error (LSTR returns [string :] err msg)
    -- 2) other addons fiddling with the errorhandler -> double prints
    -- 3) TPIL bugs must propagate at all cost
    -----------> THIS FUNC IS STRICTLY FOR TPIL ERRORS!! <--------
    -- assert has no level control, wich we need, so we use
    -- error(msg, 3) to point the error to the ___Lua51() caller
    -- blizz errorhandler uses _ERRORMESSAGE() (BasicControls.xml) which depends on
    -- ScriptErrors, if ScriptErrors = nil, error() silently returns --v1
    local msg = 'Lua5.1 INTERNAL ERRT: '..err_state..'  |  Please report this on Github!'
    -- check core func : error()
    local err_state_check = CHKF'err'
    local is_broken = (err_state_check == 'broken')
    if not is_broken then
        -- try to detect if blizzards errhandler is active
        if err_state_check == true then
            -- case1: blizzards original handler + frame
            if ScriptErrors then
                -- transpiler errors need more frame space
                ScriptErrors:SetHeight(160)
                DEBG(1, 'CASE 1 ERRT: '..msg)
                -- error(msg, 2) -- v1: i think this is wrong,lvl1 is this, lvl2 is L51X, so lvl3 should be ___Lua51()...
                error(msg, 3) --v2
            else
                -- case2: blizzards handler active but no frame
                CHAT:AddMessage(msg, 1,0,0)
                DEBG(1, 'CASE 2 ERRT: '..msg)
                -- we still call error here for proper background processing
                ---> doing /run error('test') will print + ScriptErrors, but error('test') in code does not print!!!
                -- error(msg, 2) -- v1: i think this is wrong,lvl1 is this, lvl2 is L51X, so lvl3 should be ___Lua51()...
                error(msg, 3) --v2
            end
        else
            -- case 3: no blizzard handler
            -- custom handlers usually disable blizz frame, so we just
            -- throw error at them, they do teh rest
            DEBG(1, 'CASE 3 ERRT: '..msg)
            -- error(msg, 2) -- v1: i think this is wrong,lvl1 is this, lvl2 is L51X, so lvl3 should be ___Lua51()...
            error(msg, 3) --v2
        end
    else
        -- case 4: error() is broken or whatever, give up
        -- and print. its not our problem anymore
        DEBG(1, 'CASE 4 ERRT: '..msg)
        CHAT:AddMessage(msg, 1,0,0)
    end
    -- TODO: case 5: ...
end

local function L51X(src)
    -- main processing func, runs the whole pipeline
    -- we have to deal with 3 error types:
    -- 1) before pipeline -> ASRT() is fine, since regular code
    ----> regular lua errors on the libs file level, ASRT -> lib dev problem
    -- 2) inside pipeline -> ERRT() catches, LSTR obfuscates origin
    ----> transpiler bugs that happen inside LSTR         -> lib dev problem
    -- 3) after execution -> wow handles, @src_file prefix for attribution
    ----> regular lua/wow errors after code translation   -> user problem
    ASRT(type(src) == 'string', 'L51X: src ~= string')
    DEBG(1, '================== |cFFFFFFFFLOAD START|r ==')
    DEBG(1, '|cFFFFFFFFLOAD: Raw src: '..src)
    local total_start = GetTime()
    local tokens, ast, code, func, err_state

    if not RUN_TOKENIZER then return end
    local t_start = GetTime()
    tokens = core.TOKN(src)
    ASRT(tokens, 'L51X: TOKN returned nil')
    local t_end = GetTime()
    DEBG(1, 'TOKN passed, processing...')
    DEBG(3, strformat('L51X: Tokenize: %.3f ms', (t_end - t_start) * 1000))

    if not RUN_PARSER then return end
    local p_start = GetTime()
    ast = core.PARS(tokens)
    ASRT(ast, 'L51X: PARS returned nil')
    local p_end = GetTime()
    DEBG(1, 'PARS passed, processing...')
    DEBG(3, strformat('L51X: Parse: %.3f ms', (p_end - p_start) * 1000))

    if not RUN_TRANSPILER then return end
    local tr_start = GetTime()
    code = core.TPIL(ast)
    ASRT(code, 'L51X: TPIL returned nil')
    local tr_end = GetTime()
    DEBG(1, 'TPIL passed, processing...') -- this is a string
    DEBG(3, strformat('L51X: Transpile: %.3f ms', (tr_end - tr_start) * 1000))

    if not RUN_LOADER then return end
    local l_start = GetTime()
    -- we need to get the addons name and calling files
    -- to assign the right namespace table to each addon,
    -- and for proper error handling due to LSTR (read below)
    ASRT(CHKF'dbg', 'L51X: DBST broken, cannot parse source file')
    local stack = DBST(2, 1, 1)
    ASRT(stack, 'L51X: DBST returned nil')
    local _, _, src_file = strfind(stack, 'AddOns\\(.+)%.lua')
    ASRT(src_file, 'L51X: Could not extract source file from DBST')
    local _, _, addon = strfind(src_file, '([^\\]+)\\')
    ASRT(addon, 'L51X: Could not extract addon name from: ' .. src_file)
    DEBG(1, 'L51X: Src file: ' .. src_file .. ' - HOST: ' .. addon)
    -----------> so! in wotlk, each file gets passed 2 arguments, files
    -- are functions to lua, and they receive addonname and private table.
    -- We emulate this system by wrapping the code in a vararg function.
    -- WoW vanilla only creates arg table for vararg when passed as function param!
    --> wrap code in a vararg function so 'arg' is created by WoW
    ---> allows passing <addonname, namespace> to each addon file like wotlk
    local wrapper = 'return (function(...)\n' .. code .. '\nend)'
    -- since LSTR returns any error as 'string',
    -- and PCLL returns FULL SOURCE CODE (!) up to error line in err_state,
    -- AND because we want to stay as noninvasive as possible (no seterrorhandler()),
    -- all we do is append the src_file to the error, rest is up to users, let blizz handle that
    ASRT(CHKF'ls', 'L51X: LSTR broken, cannot load code')
    func, err_state = LSTR(wrapper, '@' .. src_file) -- v2 i hate lying to lua -> @ prefix = file path in errors (lua 5.0 manual 4.1)
    DEBG(1, 'L51X: Loadstring returned: ' .. tstr(func) .. ' and err_state: ' .. tstr(err_state))
    -- install our main error path
    -- if not func then ERRT(err_state) end --v1
    if not func then ERRT(err_state) return end --v2 : has to return for case4 hits
    DEBG(1, 'L51X: No errors in LSTR, proceeding...')
    local l_end = GetTime()
    DEBG(3, strformat('L51X: LSTR: %.3f ms', (l_end - l_start) * 1000))

    local transpile_end = GetTime()
    local transpile_ms = (transpile_end - total_start) * 1000

    local exec_start = GetTime()
    local runner = func()  -- returns the inner vararg function
    ASRT(type(runner) == 'function', 'L51X: runner ~= function')

    -- create private namespace table for each addon
    if not namespaces[addon] then namespaces[addon] = {} end
    DEBG(1, 'L51X: namespace created: ' .. addon .. ' - TBL: ' .. tstr(namespaces[addon]))
    -- execute vararg func with full context
    -- runner(addon, namespaces[addon]) -- v2
    -- v3: we capture return values now, opens up for on
    -- the fly translation (max 2args for now.) e.g.:
    -- < local x = ___Lua51([[ return 10 % 3 ]]); print(x) > .. lol)
    local a1, a2 = runner(addon, namespaces[addon]) -- v3
    DEBG(1, 'L51X: |cFFFFFFFFCODE executed!')

    local exec_end = GetTime()
    local exec_ms = (exec_end - exec_start) * 1000
    DEBG(1, strformat('L51X: Transpile (total): %.3f ms', transpile_ms))
    DEBG(1, strformat('L51X: Execution: %.3f ms', exec_ms))
    DEBG(1, strformat('L51X: Overall: %.3f ms', (exec_end - total_start) * 1000))
    DEBG(1, '==================== |cFFFFFFFFLOAD END|r ==')
    DEBG(1, 'L51X: Passing a1: ' .. tstr(a1) .. ' and a2: ' .. tstr(a2))
    return a1, a2
end

FLGS()

--------- intern --------------------------

-- you could ignore these...

___Lua51reg = SENV
env.DEBG    = DEBG
env.ERRT    = ERRT
env.L51X    = L51X

--------- API ----------------------------

--[[ entry point for your lua 5.1 env.
i would not recommend using it in a hot
path. it translates 'fast', you can do
on the fly translates np...]]

___Lua51    = L51X     --[[... but i would

still not recommend going crazy with it,
either write it all in ___Lua51 directly
or cache whatever u need once, but dont
pump out ___Lua51 calls in onupdates...
you could do it, i tested it. but be
its still not a good idea...]]

--------- /lua51 ------------------------

-- disable slash for public users
if _LUA51_CORE_DEBUG_CONTROLLER == 0 then return end

SLASH_LUA511 = '/lua51'; SLASH_LUA512 = '/l51'
SlashCmdList.LUA51 = function(msg)
    DEBG(1, 'CMD: '..msg)
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
        L51X(rest)
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


--[[ have fun coding...









...    από τι είναι φτιαγμένη η φαντασία? (••?)  ]]