-- 4
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

  -- Migration v3 -> v4
  if config.outputSide then
    config.output = {{
      side = config.outputSide,
      level = 15
    }}
    config.outputSide = nil
  end

  if config.inventorySide == nil then
    config.inventorySide = Term.prompt('Which side has the inventory?')
  end
  if config.maxCount == nil then
    config.maxCount = tonumber(Term.prompt('Maximum capacity count'))
  end
  if config.output == nil then
    config.output = {}
    local sideInput = Term.prompt('Which side outputs Redstone signal?')
    local amountInput = ""
    while sideInput ~= "" do
      amountInput = Term.prompt('How many levels does this side have?')
      if amountInput ~= "" then
        Table.push(config.output, {
          side = sideInput,
          level = tonumber(amountInput)
        })
        sideInput = Term.prompt('Which side outputs Redstone signal?')
      else
        sideInput = ""
      end
    end
  end
  if config.inverted == nil then
    config.inverted = false
  end
  writeConfig()
  port = peripheral.wrap(config.inventorySide)
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

local function sense()
  local maxLevel = Table.reduce(config.output, function(acc, entry)
    return acc + entry.level
  end, 0)
  while true do
    local itemlist = port.list()
    local itemcount = Table.reduce(Table.map(itemlist, function(item)
      return item.count
    end), function(a, b)
      return a + b
    end, 0)
    level = math.floor(math.min((maxLevel * itemcount) / config.maxCount, maxLevel) + 0.5)
    if config.inverted then
      level = maxLevel - level
    end
    display()
    sleep(1)
  end
end

local function signal()
  while true do
    local countedLevel = level
    for i, entry in pairs(config.output) do
      local applyLevel = math.min(countedLevel, entry.level)
      countedLevel = countedLevel - applyLevel
      rs.setAnalogOutput(entry.side, applyLevel)
    end
    sleep(1)
  end
end

local function keyListener()
  while true do
    local evt, key = os.pullEvent('key')
    if key == keys.i then
      config.inverted = not config.inverted
      writeConfig()
    end
  end
end

init()
display()
parallel.waitForAny(sense, signal, keyListener)
