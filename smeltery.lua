-- 7
local config = {}
local Term = nil
local Table = nil
local port = nil
local cursor = 1
local purge = false

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
  if config.limit == nil then
    config.limit = false
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
  return Table.map(port.getController().getMolten(), function(entry)
    return {
      name = entry.displayName,
      amount = entry.amount
    }
  end)
end

local function display()
  local current = getCurrent()
  if cursor > #current then
    cursor = #current
  end
  if cursor == 0 then
    cursor = 1
  end
  term.clear()
  if config.limit and not purge then
    Term.out('Limit active', 2, 5)
  end
  if purge then
    Term.out('Purge', 2, 5)
  end
  for i = 1, #current do
    if cursor == i then
      Term.out(">", i + 3, 1)
    end
    if Table.indexOf(config.metals, current[i].name) > -1 then
      Term.out('*', i + 3, 3)
    end
    Term.out(current[i].name, i + 3, 5)
    Term.rightAlign(current[i].amount, i + 3, 38)
  end
end

function keyListener()

  local running = true
  while running do
    local _, key = os.pullEvent('key')
    local current = getCurrent()

    if key == keys.up and cursor > 1 then
      cursor = cursor - 1
    end
    if key == keys.down and cursor < #current then
      cursor = cursor + 1
    end
    if key == keys.space then
      if Table.indexOf(config.metals, current[cursor].name) > -1 then
        config.metals = Table.filter(config.metals, function(item)
          return item ~= current[cursor].name
        end)
      else
        Table.push(config.metals, current[cursor].name)
      end
      writeConfig()
    end
    if key == keys.enter then
      port.getController().selectMolten(cursor)
    end
    if key == keys.l then
      config.limit = not config.limit
      writeConfig()
    end
    if key == keys.p then
      purge = not purge
    end
    if key == keys.q then
      running = false
    end
    display()
  end
  term.clear()
  term.setCursorPos(1, 1)
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
      local aboveLimit = (not config.limit) or entry.amount > 20000 or allFlushable
      local shouldOutput = purge or (Table.indexOf(config.metals, entry.displayName) > -1 and aboveLimit)
      rs.setOutput(config.portSide, shouldOutput)
    else
      purge = false
      rs.setOutput(config.portSide, false)
    end
    display()
    sleep(0.05)
  end
end

init()
display()

parallel.waitForAny(keyListener, signal)
rs.setOutput(config.portSide, false)
