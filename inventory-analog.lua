-- 1
local config = {}
local Table = nil
local Term = nil
local configName = 'var/inventory-analog.conf';
local port = nil
local level = 0

local function writeConfig()
  local file = fs.open(configName, 'w')
  file.write(textutils.serialise(config))
  file.close()
end

local function init()
  if fs.exists(configName) then
    local file = fs.open(configName, 'r')
    config = textutils.unserialise(file.readAll())
    file.close()
  end
  if not fs.exists('lib/table.lua') then
    shell.run('installer lib/table.lua')
  end
  Table = require('lib/table')
  if not fs.exists('lib/term.lua') then
    shell.run('installer lib/term.lua')
  end
  Term = require('lib/term')

  if config.outputSide == nil then
    config.outputSide = Term.prompt('Which side outputs Redstone signal?')
  end
  if config.inventorySide == nil then
    config.inventorySide = Term.prompt('Which side has the inventory?')
  end
  if config.maxCount == nil then
    config.maxCount = tonumber(Term.prompt('Which side has the inventory?'))
  end
  if config.inverted == nil then
    config.inverted = false
  end
  writeConfig()
  port = peripheral.wrap(config.inventorySide)
  display()
end

local function level()
  while true do
    local itemlist = port.list()
    local itemcount = Table.reduce(Table.map(itemlist, function(item)
      return item.count
    end), function(a, b)
      return a + b
    end, 0)
    level = math.round(math.min((15 * itemcount) / config.maxCount, 15))
    if config.inverted then
      level = 15 - level
    end
    display()
    sleep(1)
  end
end

local function signal()
  while true do
    rs.setAnalogOutput(config.outputSide, level)
    sleep(1)
  end
end

local function display()
  term.clear()
  term.setCursorPos(2, 2)
  term.write("Current level: " .. tostring(level))
  if config.inverted then
    term.setCursorPos(2, 4)
    term.write("Output inverted")
  end
end

init()
display()
parallel.waitForAny(level, signal)
