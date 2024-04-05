--3
local config = {}
local Term = nil
local Table = nil
local port = nil
local cursor = 1
local limit = false

local function init() 
  if fs.exists('var/smeltery.conf') then
    local file = fs.open('var/smeltery.conf', 'r')
    config = textutils.unserialise(file.readAll())
    file.close()
  end
  if not fs.exists('lib/term.lua') then 
    shell.run('installer lib/term.lua')
  end
  if not fs.exists('lib/table.lua') then 
    shell.run('installer lib/table.lua')
  end
  Term = require('lib/term')
  Table = require('lib/table')
  if config.portSide == nil then
    setPortSide()
  end
  if config.metals == nil then
    config.metals = {}
  end

  port = peripheral.wrap(config.portSide)
end

function writeConfig()
  local file = fs.open('var/smeltery.conf', 'w')
  file.write(textutils.serialise(config))
  file.close()
end

function setPortSide()
  term.clear()
  print('Which side is the port on?')
  config.portSide = read()
  writeConfig()
end

local function getCurrent()
  return Table.map(port.getController().getMolten(),
    function (entry) return entry.displayName end
  )
end

local function display()
  local current = getCurrent()
  if cursor > #current then cursor = #current end
  if cursor == 0 then cursor = 1 end
  term.clear()
  if limit then
    Term.out('Limit active', 1, 5)
  end
  for i = 1, #current do
    if cursor == i then
      Term.out(">", i+2, 1)
    end
    if Table.indexOf(config.metals, current[i]) > -1 then
      Term.out('*', i+2, 3)
    end
    Term.out(current[i], i+2, 5)
  end
end

function keyListener()
  
  local running = true
  while running do
    local _, key = os.pullEvent('key')
    local current = getCurrent()
    
    if key == keys.up and cursor > 1 then
      cursor = cursor -1
    end
    if key == keys.down and cursor < #current then
      cursor = cursor +1
    end
    if key == keys.space then 
      if Table.indexOf(config.metals, current[cursor]) > -1 then
        config.metals = Table.filter(config.metals, function (item)
          return item ~= current[cursor]
        end)
      else
        Table.push(config.metals, current[cursor])
      end
      writeConfig()
    end
    if key == keys.enter then
      port.getController().selectMolten(cursor)
    end
    if key == keys.l then
      limit = not limit
    end
    if key == keys.q then 
      running = false
    end
    display()
  end
  term.clear()
  term.setCursorPos(1,1)
  sleep(0.05)
  return
end

function signal()
  while true do
    local moltenList = port.getController().getMolten()
    if (#moltenList > 0) then
      local entry = moltenList[1]
      local allFlushable = Table.every(moltenList, function(item)
        return Table.indexOf(config.metals, item.displayName) > -1
      end)
      local aboveLimit = (not limit) or entry.amount > 20000 or allFlushable
      rs.setOutput(config.portSide, Table.indexOf(config.metals, entry.displayName) > -1 and aboveLimit)
    else
      rs.setOutput(config.portSide, false)
    end
    display()
  end
end

init()
display()

parallel.waitForAny(keyListener, signal)
rs.setOutput(config.portSide, false)
