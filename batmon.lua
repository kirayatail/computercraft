--5
local socket = nil
local Table = nil
local conf = {}
local total = 0

local function map(tbl, f)
    local t = {}
    for k,v in pairs(tbl) do
        t[k] = f(v)
    end
    return t
end 

local function sum(tbl)
    Table.reduce(tbl, function (a, b) return a + b end)
end

function init()
    if not fs.exists('lib/table.lua') then
        shell.run('installer', 'lib/table.lua')
    end
    Table = require('lib/table')
    if fs.exists('var/batmon.conf') then
        local file = fs.open('var/batmon.conf', 'r')
        conf = textutils.unserialise(file.readAll())
        file.close()
    else 
        conf = {
            hidden = false,
            group = nil
        }
        local file = fs.open('var/batmon.conf', 'w')
        file.write(textutils.serialise(conf))
        file.close()
    end
    if fs.exists('websocket.lua') then 
        socket = require('websocket')
    end
end

function start()
    if socket then
        socket.group(conf.group or nil)
        socket.hidden(conf.hidden or false)
        socket.connect('batmon', true)
    end
end

function monitor()
    while true do
        local bats = { peripheral.find('thermalexpansion:storage_cell') }
        local stored = sum(Table.map(bats, function(b) return b.getRFStored() end)) / 1000
        local total = sum(Table.map(bats, function(b) return b.getRFCapacity() end)) / 1000
        if socket then
            socket.info({
                {
                    key = 'stored',
                    value = stored,
                    type = 'number'
                },
                {
                    key = 'total',
                    value = total,
                    type = 'number'
                },
                {
                    key = 'percent',
                    value = total > 0 and (stored * 100 / total) or 0,
                    type = 'number'
                }
            })
        end
        sleep(1)
    end
end

init()
local loops = {
    start, monitor
}
if socket then table.insert(loops, socket.runtime) end

parallel.waitForAll(unpack(loops))
