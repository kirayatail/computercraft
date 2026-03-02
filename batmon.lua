-- 9
local socket = nil
local Table = nil
local conf = {}
local total = 0
local stored = 0
local bats = {peripheral.find('thermalexpansion:storage_cell')}
local fullCells = 0
local partialBats = {}
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
    socket = require('lib/websocket')
  end
end

function start()
  if socket then
    socket.connect('Big battery', true)
  end
  total = #bats * 50000
end

function coarseMonitor()
  while true do
    local full = 0
    for chunk = 0, (#bats / 4) do
      for i = 1, 4 do
        local index = chunk * 4 + i
        if bats[index] then
          local stored = bats[index].getRFStored() or 0
          if stored > 49975000 then
            full = full + 1
          elseif stored > 25000 then
            partialBats[index] = bats[index]
          end
        end
      end
      if (full > fullCells) then
        fullCells = full
      end
      sleep(0.5)
    end
    fullCells = full
    sleep(5)
  end
end

function fineMonitor()
  while true do
    local partialStored = 0
    for key, bat in pairs(partialBats) do
      local current = bat.getRFStored() or 0
      partialStored = partialStored + current
      if current < 25000 or current > 49975000 then
        partialBats[key] = nil
      end
    end
    stored = fullCells * 50000 + partialStored / 1000
    sleep(1)
  end
end

function monitor()
  while true do
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
    sleep(5)
  end
end

init()
local loops = {start, monitor, coarseMonitor, fineMonitor}
if socket then
  table.insert(loops, socket.runtime)
end

parallel.waitForAll(unpack(loops))
