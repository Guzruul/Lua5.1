---@diagnostic disable: duplicate-set-field
--==============================================================--
--[[                !debug controller           --]]
-- we want to keep debug settings off by default in the lib
-- a) load !debug b) copy paste this code c) define the vars urself
--           ... just raise the flags before Lua5.1 loads
--==============================================================--

--[[
0 = off
1 = critical
2 = verbose
3 = full logs]]
_LUA51_CORE_DEBUG_CONTROLLER = 1

--[[
must match filename both the
Lua5.1 folder without the '.lua',
and the table in the Lua5.1\core.lua!
always ships with lvl=1, core and diag. on]]
_LUA51_CORE_DEBUG_FLAGS = {
core        = true,
tokenizer   = false,
parser      = false,
transpiler  = false,
diagnostics = true,
}

--==============================================================--

local DEV_MODE = true

--==============================================================--

function print(msg) DEFAULT_CHAT_FRAME:AddMessage(tostring(msg)) end
print('============ |cFFFFFFFF!debug ACTIVE|r ============',1,1,0)
if _LUA51_CORE_DEBUG_CONTROLLER == 0 then
print('============ |cFFFFFFFFDC LVL: ' .. _LUA51_CORE_DEBUG_CONTROLLER .. '|r ================',1,0,0) end

SLASH_LOAD1 = '/load'
SlashCmdList['L51X'] = function(addon)
    if addon == '' then print('Usage: /load ADDONNAME') return end
    local _, _, _, _, _, reason = GetAddOnInfo(addon)
    if reason ~= 'MISSING' then EnableAddOn(addon) ReloadUI()
    else print('Addon \'' .. addon .. '\' not found.')
    end
end

SLASH_UNLOAD1 = '/unload'
function SlashCmdList.UNLOAD(addon)
    if addon == '' then print('Usage: /unload ADDONNAME') return end
    local _, _, _, _, _, reason = GetAddOnInfo(addon)
    if reason ~= 'MISSING' then DisableAddOn(addon) ReloadUI()
    else print('Addon \'' .. addon .. '\' not found.')
    end
end
