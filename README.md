# Lua5.1 - Service Transpiler for WoW Vanilla 1.12.1

***`Lua5.1` is a stand-alone runtime mini-transpiler and service layer for World of Warcraft Vanilla 1.12.1 that tries to emulate Lua5.1 and Blizzard's private table system introduced in Wotlk 3.0.***

### THIS ADDON IS ONLY FOR DEVELOPERS - ITS USELESS FOR PLAYERS

*If you are a beginner dev, don' rely to much on this since you wont be able to debug.
Use only small functions or small code blocks inside Lua51. Keep things isolated.
And enjoy the private namespace!* :)

    ALPHA PHASE! EXPECT BUGS PLEASE! REPORT PLEASE! YOU CAN USE IT ALREADY
    AS A MINI COMPILER; BUT DONT WRITE AN ENTIRE UI ADDON IN HERE YET!
    YOUR ERRORS MIGHT GET SUPER OBFUSCATED!

- 100% Lua
- 100% stand-alone

## Features

- It translates `Lua5.1` syntax down to Lua 5.0
- It emulates the WotlK private namespace system for every addon/file

MAIN `Lua5.1` Function:
- `___Lua51([[ < your Lua5.1 code > ]])` - returns up to 2 optional arguments of your choice.

NEW `Lua5.1` Operators for WoW Vanilla:
- `#`
- `%`
- `...`  - NOW fully usable as expression! `local a1,a2,a3 = ...`

NEW `Lua5.1` Functions for WoW Vanilla:
- 'select()'

## Lua 5.1 Code Syntax

### Lua 5.1 Inline

Example 1

    ___Lua51([[ print( 10 % 3 ) ]])

Example 2

    ___Lua51([[
        local addonname, namespace = ... -- provides name, and private table like Wotlk
        print(addonname) -- will print your addon name
        print(namespace) -- will print out private table's memory adress in wow process
    ]])

Example 3

    ___Lua51([[
        local function test(...)
            print(select('#', ...)) -- prints 3
            local a, b = select(2, ...)
            print(a .. b) -- prints 23
        end
        test(1, 2, 3)
    ]])

Example 4

    ___Lua51([[
        local function minmax(a, b, c)
            local mn = a
            local mx = a
            if b > mx then mx = b end
            if b < mn then mn = b end
            if c > mx then mx = c end
            if c < mn then mn = c end
            return mn, mx
        end

        local a, b = minmax(select(2, 'x', 10, 30, 5)) --  will be a = 5 and b = 30
    ]])

### Lua 5.1 Extract

    local calculate = ___Lua51([[ return 10 % 3 ]]) -- returns up to 2 args from the pipeline
    print(calculate) -- will print out 1 from the transpiled code

### Enviroment Switch

You can easily switch in and out of the Lua5.1 environment, its super flexible.

    local x = 1 -- do some operations in regular wow environment

    ___Lua51([[ -- switch to Lua51 env and do some stuff...

    local f = CreateFrame('Frame')
    f:SetPoint('CENTER', UIParent)
    f:SetWidth(300)
    f:SetHeight(100)
    f:SetBackdrop({bgFile = 'Interface\\Buttons\\WHITE8X8'})

    ]])

    print(x) -- back to wow's regular env

    local Y = ___Lua51([[ return 10]]) -- quick accesss to lua51, extract...

    print(Y) -- ... into lua50. :)

    ... and so on.

### Lua 5.1 NEW Command Line

    /lua51 run print(10 % 3)
    /l51 run <some lua 5.1 code>

### Lua5.1 Other Slash commands

    /lua51 diag <module?>   -- runs the diagnostic system
    /lua51 lvl <0-3>        -- sets the current debug level

### WotlK Namespace System

- `___Lua51` provides each caller with addonname + namespace, no registry needed, any caller gets it

Inline:

    ___Lua51([[
        local addon, ns = ...
        print(addon)
        print(ns)
    ]])

Extracted from Lua5.1 to Lua5.0:

    local addon, ns = ___Lua51([[ local addon, ns = ... ; return addon, ns ]])
    print(addon)
    print(ns)

## More 'select()' Code Examples

| Command | Output | Description |
|---|---|---|
| `/lua51 run print(select('#', 1, 2, 3))` | `3` | Hash count, explicit args |
| `/lua51 run print(select('#', 'a', 'b', 'c', 'd'))` | `4` | Hash with strings |
| `/lua51 run print(select('#', 1))` | `1` | Hash with single arg |
| `/lua51 run print(select(1, 10, 20, 30))` | `10` | Pick first |
| `/lua51 run print(select(2, 10, 20, 30))` | `20` | Pick middle |
| `/lua51 run print(select(3, 10, 20, 30))` | `30` | Pick last |
| `/lua51 run print(select(4, 10, 20, 30))` | `nil` | Out of range |
| `/lua51 run local a, b = select(2, 'x', 'y', 'z'); print(a .. ', ' .. b)` | `y, z` | Multi-return assignment |
| `/lua51 run local a, b, c = select(1, 'x', 'y', 'z'); print(a .. ', ' .. b .. ', ' .. c)` | `x, y, z` | Multi-return all |
| `/lua51 run print(select(1+1, 10, 20, 30))` | `20` | Dynamic expression index |


## Installation
- Put the folder `Lua5.1` anywhere in your addon
- Add the `_init.xml` to your `.toc` or `.xml` entry point
- Use `___Lua51([[ < your code in here > ]])` to enter transpiler environment

## Known Limitations
> C-engine functions cant be reproduced in Lua, stuff like `collectgarbage('count')` etc.

## Performance
> Pretty good honestly, even in tight OnUpdate loops, the pipeline runs stable.

    CreateFrame'Frame':SetScript('OnUpdate', function() ___Lua51([[  local a, b, c = select(1, 'x', 'y', 'z'); print(a .. ', ' .. b .. ', ' .. c)  ]]) end)

> Full pipeline getting blasted @60FPS, no memory leaks. DONT do this tho, cache or inline!

## Issues
- The addon is still in developement.
- Error messages might end up obscure due to transpiling
- Due to the complexity of this addon, bugs can and will occur initially.
- Please report them all on the Github, to make the transpiler stable.
- Report with proper logs please and how to reproduce.

## Github
Source: https://github.com/Guzruul/Lua5.1

# Author' Note

If you want to know why... I like compiler engineering and low level stuff.

If you enjoy the framework and want to support me:

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/guzruul)

- Please try not to fork this, instead push a PR please
- Help is always welcome

Take care turtles, Guzruul.

Aπό τι είναι φτιαγμένη η φαντασία...?