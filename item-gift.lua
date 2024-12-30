-- 8
local version = 8
local Table = nil
local socket = nil
local config = {
    selectedIndex = 1,
    selectedAmount = 1,
    playername = ''
}
local configPath = 'var/item-gift.conf'
local itemList = {{
    name = 'Iron ore',
    stackSize = 64,
    code = 'minecraft:iron_ore',
    dmg = 0
}, {
    name = 'Copper ore',
    stackSize = 64,
    code = 'thermalfoundation:ore',
    dmg = 0
}, {
    name = 'Silver ore',
    stackSize = 64,
    code = 'thermalfoundation:ore',
    dmg = 2
}, {
    name = 'Lead ore',
    stackSize = 64,
    code = 'thermalfoundation:ore',
    dmg = 3
}, {
    name = 'Cinnabar ore',
    stackSize = 64,
    code = 'thaumcraft:ore_cinnabar',
    dmg = 0
}, {
    name = 'Uranium ore',
    stackSize = 64,
    code = 'ic2:resource',
    dmg = 4
}, {
    name = 'Block of Enderpearl',
    stackSize = 64,
    code = 'actuallyadditions:block_misc',
    dmg = 6
}, {
    name = 'Oil Sand',
    stackSize = 64,
    code = "thermalfoundation:ore_fluid",
    dmg = 0
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

    if not fs.exists(configPath) then
        local file = fs.open(configPath, 'w')
        file.write(textutils.serialise(config))
        file.close()
    end
    local file = fs.open(configPath, 'r')
    config = textutils.unserialise(file.readAll())
    file.close()
end

local function setConfig(key, value)
    config[key] = value
    local file = fs.open(configPath, 'w')
    file.write(textutils.serialise(config))
    file.close()
end

local function sendMethods()
    if socket then
        socket.info({{
            key = "Version",
            value = version,
            type = 'number'
        }})
        socket.methods({{
            type = 'text',
            key = 'playername',
            name = 'Player',
            value = config.playername,
            fn = function(value)
                setConfig('playername', value)
                return value
            end
        }, {
            type = 'dropdown',
            key = 'itemcode',
            name = 'Item',
            options = Table.map(itemList, function(item)
                return item.name
            end),
            value = itemList[config.selectedIndex].name,
            fn = function(value)
                local _, index = Table.find(itemList, function(item)
                    return item.name == value
                end)
                setConfig('selectedIndex', index)
                return value
            end
        }, {
            type = 'number',
            key = 'selectedAmount',
            name = 'Amount',
            value = config.selectedAmount,
            min = 1,
            fn = function(value)
                if value == nil or value < 1 then
                    value = 1
                end
                setConfig('selectedAmount', value)
                return value
            end
        }, {
            type = 'void',
            key = 'exec',
            name = 'Give items',
            fn = function()
                local item = itemList[config.selectedIndex]
                local count = config.selectedAmount
                while count >= 1 do
                    print('Giving ' .. config.playername .. ' ' .. count .. ' ' .. item.name)
                    if count > 64 then
                        commands.give(config.playername, item.code, 64, item.dmg)
                        count = count - 64
                    else
                        commands.give(config.playername, item.code, count, item.dmg)
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
