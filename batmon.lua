-- 7
local socket = nil
local Table = nil
local conf = {}
local total = 0
local bats = {peripheral.find('thermalexpansion:storage_cell')}
local previous = 0

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
  if fs.exists('lib/websocket.lua') then
    socket = require('websocket')
  end
end

local function sum(tbl)
  Table.reduce(tbl, function(a, b)
    return a + b
  end)
end

function start()
  if socket then
    socket.connect('Big battery', true)
  end
end

function monitor()
  while true do
    local stored = sum(Table.map(bats, function(b)
      return b.getRFStored()
    end)) / 1000
    local total = sum(Table.map(bats, function(b)
      return b.getRFCapacity()
    end)) / 1000
    if socket then
      socket.info({{
        key = 'level',
        name = 'Battery Level',
        value = stored,
        type = 'progress',
        min = 0,
        max = total
      }, {
        key = 'increasing',
        name = 'Increasing',
        value = stored > previous,
        type = 'boolean'
      }, {
        key = 'decreasing',
        name = 'Decreasing',
        value = stored < previous,
        type = 'boolean'
      }})
    end
    previous = stored
    sleep(1)
  end
end

init()
local loops = {start, monitor}
if socket then
  table.insert(loops, socket.runtime)
end

parallel.waitForAll(unpack(loops))
