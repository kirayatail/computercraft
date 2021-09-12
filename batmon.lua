--2
local socket = nil
local conf = {}
local bats = { peripheral.find('thermalexpansion:storage_cell') }
local total = 0

local function map(tbl, f)
    local t = {}
    for k,v in pairs(tbl) do
        t[k] = f(v)
    end
    return t
end

local function sum(tbl)
    local sum = 0
    for _,v in pairs(tbl) do
        sum = sum + v
    end
    return sum
end

function init()
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

    total = sum(map(bats, function(b) return b.getRFCapacity() end)) / 1000
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
        local value = sum(map(bats, function(b) return b.getRFStored() end)) / 1000
        if socket then
            socket.info({
                {
                    key = 'stored',
                    value = value,
                    type = 'number'
                },
                {
                    key = 'total',
                    value = total,
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
