--1
local config = {}
local Table = nil
local Term = nil
local port = nil

local function init() 
  if fs.exists('var/smeltery-tank.conf') then
    local file = fs.open('var/smeltery-tank.conf', 'r')
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
  if config.tankSize == nil then
    setTankSize()
  end
  if config.percentage == nil then
    config.percentage = 0
  end
  if config.invert == nil then
    config.invert = false
  end

  port = peripheral.wrap(config.portSide)
end

function writeConfig()
  local file = fs.open('var/smeltery-tank.conf', 'w')
  file.write(textutils.serialise(config))
  file.close()
end

function setPortSide()
  term.clear()
  print('Which side is the port on?')
  config.portSide = read()
  writeConfig()
end

function setTankSize()
  term.clear()
  print('How big is the smeltery tank (in mB)')
  config.tankSize = tonumber(read())
  writeConfig()
end

function display()
  term.clear()
  Term.out(config.percentage..'%', 2,2)
  if config.invert then
    Term.out('Signal inverted', 4,2)
  end
end

function getFillAmount()
  return Table.reduce(
    port.getController().getMolten(),
    function (acc, entry) return acc + entry.amount end,
    0
  )
end

function xor(a, b)
  return (a ~= nil and a ~= false) ~= (b ~= nil and b ~= false)
end

function keyListener()
  local running = true
  while running do 
    local _, key = os.pullEvent('key')
    
    if key == keys.up and config.percentage < 90 then
      config.percentage = config.percentage + 10
      writeConfig()
    end

    if key == keys.down and config.percentage > 0 then
      config.percentage = config.percentage - 10
      writeConfig()
    end
    if key == keys.space then
      config.invert = not config.invert
      writeConfig()
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
    local fillRatio = (100 * getFillAmount()) / config.tankSize
    rs.setOutput(
      config.portSide,
      xor(config.invert, fillRatio < config.percentage)
    )
    sleep(0.05)
  end
end

init()
display()
parallel.waitForAny(keyListener, signal)
