-- 2
local Table = nil
local socket = nil
local selectedIndex = 1
local selectedAmount = 1
local playername = ''
local itemList = {{
    name = 'Iron ore',
    stackSize = 64,
    code = 'minecraft:iron_ore',
    dmg = 0
}, {
    name = 'Silver ore',
    stackSize = 64,
    code = 'thermalfoundation:ore',
    dmg = 2
}, {
    name = 'Copper ore',
    stackSize = 64,
    code = 'thermalfoundation:ore',
    dmg = 0
}, {
    name = 'Cinnabar ore',
    stackSize = 64,
    code = 'thaumcraft:ore_cinnabar',
    dmg = 0
}, {
    name = 'Block of Enderpearl',
    stackSize = 64,
    code = 'actuallyadditions:block_misc',
    dmg = 6
}}

local function init()
    if not fs.exists('lib/table.lua') then
        shell.run('installer lib/table.lua')
    end
    Table = require('lib/table')
    if not fs.exists('websocket.lua') then
        shell.run('installer websocket.lua')
    end
    socket = require('websocket')
end

local function sendMethods()
    if socket then
        socket.info({
            key = "Version",
            value = 2,
            type = 'number'
        })
        socket.methods({{
            type = 'text',
            key = 'playername',
            name = 'Player',
            value = playername,
            fn = function(value)
                playername = value
                return value
            end
        }, {
            type = 'dropdown',
            key = 'itemcode',
            name = 'Item',
            options = Table.map(itemList, function(item)
                return item.name
            end),
            value = itemList[selectedIndex].name,
            fn = function(value)
                local _, index = Table.find(itemList, function(item)
                    return item.name == value
                end)
                selectedIndex = index
                return value
            end
        }, {
            type = 'number',
            key = 'selectedAmount',
            name = 'Amount',
            value = selectedAmount,
            min = 1,
            fn = function(value)
                if value == nil or value < 1 then
                    value = 1
                end
                selectedAmount = value
                return value
            end
        }, {
            type = 'void',
            key = 'exec',
            name = 'Give items',
            fn = function()
                local item = itemList[selectedIndex]
                local count = selectedAmount
                print('Giving ' .. playername .. ' ' .. count .. ' ' .. item.name)
                while count > 1 do
                    if count > 64 then
                        commands.exec(string.format("/give %s %s %d %d", playername, item.code, 64, item.dmg))
                        count = count - 64
                    else
                        commands.exec(string.format("/give %s %s %d %d", playername, item.code, 64, item.dmg))
                        count = 0
                    end
                end
            end
        }, {
            type = 'void',
            key = 'update',
            name = 'Update program',
            fn = function()
                shell.run('installer.lua item-gift.lua')
                os.reboot()
            end
        }})
    end
end

init()
sendMethods()
socket.connect('Give items', true)
socket.runtime()
