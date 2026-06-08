# Lua5.1 for WoW Vanilla 1.12.1

**`Lua5.1` is a mini-transpiler for World of Warcraft Vanilla 1.12.1 that tries to emulate `Lua5.1` and Blizzard's private table system introduced in Wotlk 3.0.**

## Features

- It translates `Lua 5.1` syntax down to `Lua 5.0`
- It emulates the WotlK private namespace system for every addon/file

## Main Function

- `___Lua51([[ < your Lua 5.1 code > ]])` - returns up to 2 optional arguments of your choice.

## Lua 5.1 Operators for WoW Vanilla
- `#`   - lenght operator
- `%`   - modulo operator
- `...` - vararg operator - now usable as expression

        local a1,a2,a3 = ...

## Lua 5.1 Functions for WoW Vanilla

- `select`(n: number, ...: any)  - returns values from index n onward

- `match`(s: string, pattern: string, init?: number) - returns matched string or captures, or nil

- `gmatch`(s: string, pattern: string) - returns an iterator function yielding all matches or captures from pattern over string s

- `print`(...: any)  - prints to DEFAULT_CHAT_FRAME | multi-arguments seperated by commas

        print(a, b, c) → "a  b  c"


## Code Syntax

### Inline Usage

Example 1

    ___Lua51([[ print( 10 % 3 ) ]])

Example 2

    ___Lua51([[
        local addonname, namespace = ...                -- provides name, and private table like Wotlk
        print(addonname)                                -- will print your addon name
        print(namesp)                                   -- will print out private table's mem adress
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

### Return Usage

Example 1:

    local addon, ns = ___Lua51([[ local a, b = ... ; return a, b ]])
    print(addon)                                    -- your addon name
    print(tostring(ns))                             -- your private table

Example 2:

    local _L = ___Lua51                             -- short-cut
    local calculate = _L([[ return 10 % 3 ]])       -- returns up to 2 args from the pipeline
    print(calculate)                                -- will print out 1

## Lua 5.0 / 5.1 Interop

You can easily switch between Lua5.1 and Lua5.0 directly in the file:

    local x = 1                                     -- do some stuff in Lua 5.0 (regular env)

    ___Lua51([[                                     -- switch to Lua 5.1 env and do some stuff...

        < some lua 5.1 code >

    ]])

    print(x)                                        -- back to Lua 5.0

    local Y = ___Lua51([[ return 10]])              -- quick accesss into Lua 5.1, extract...

    print(Y)                                        -- and back into Lua5.0

    ... and so on.

Example:

    local _, core = ___Lua51([[ local addon,core =...;return addon,core ]])

    -- do some stuff in lua 5.0
    core.sometable = {}

    -- then define a func that uses select or other stuff from Lua 5.1
    ___Lua51([[
        local addon, core = ...

        function core.complexFunc()
            local a, b = select(1, 'x', 'y', 'z')
            return a, b
        end
    ]])

    -- now the func is defined and can be used in lua 5.0
    local a, b = core.complexFunc()
    print(a .. ', ' .. b)

## Command Line

    /lua51 run print(10 % 3)
    /l51 run <some lua 5.1 code>

## Other Slash commands

    /lua51 diag <module?>                           -- runs the diagnostic system
    /lua51 lvl <0-3>                                -- sets the current debug level

## WotlK Namespace System

- `___Lua51` provides each caller with addonname + namespace, no registry needed, any caller gets it

Inline:

    ___Lua51([[
        local addon, ns = ...
        print(addon)
        print(ns)
    ]])

Return:

    local addon, ns = ___Lua51([[ local addon, ns = ... ; return addon, ns ]])
    print(addon)
    print(ns)

## Scope

`___Lua51()` executes inside WoW's global environment.

However, each `___Lua51()` call has its own local scope.

    ___Lua51([[ local var = 1 ]])
    ___Lua51([[ new = var + 1 ]])                   -- nil here

Or:

    ___Lua51([[ local var = 1 ]])
    print(var)                                      -- nil here too

Do not work. Keep that in mind.

You either return values, or add them to a shared table if you want to use them outside the scope.

## Some 'select()' Code Examples

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

## Known Limitations
- C-engine functions cant be reproduced in Lua, stuff like `collectgarbage('count')` etc.

## Performance
Pretty good honestly.

## Error Messages

`___Lua51()` reports errors with the exact line and column from your source code.
Note: This is not your file's line number! It is the line number inside the function call. Keep that in mind.

Parser errors:

    ___Lua51([[ local x = s #"hello" ]])            -- invalid syntax

>Message: Parser: line 1 col 14: unexpected symbol '#'


Transpiler errors:

    ___Lua51([[
    local f = function()
        return ...
    end
    ]])

>Message: '...' used outside a vararg function – cannot transpile at line 3

## Issues
- Due to the complexity of this addon, bugs may occur initially
- Please report properly on Github to make the transpiler stable

## Installation
- Place the `Lua5.1` folder anywhere in your addon
- Load the `Lua5.1\core\_init.xml` file via your `.toc` or `.xml` entry point

## Last Note
- Help is always welcome

Take care turtles, Guzruul.
