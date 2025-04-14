-- 2
local config = {}
local configPath = 'var/radio-door.conf'
local Button = nil
local monitor = nil
local buttons = {}

function init()
  if fs.exists(configPath) then
    local file = fs.open(configPath, 'r')
    config = textutils.unserialise(file.readAll())
    file.close()
  end
  if not fs.exists('lib/button.lua') then
    shell.run('installer lib/button.lua')
  end
  if config.modem == nil then
    setModem()
  end
  Button = require('lib/button')
  monitor = peripheral.find('monitor')
  buttons = {stdButton(4, 3, 'Open'), stdButton(4, 7, 'Close')}
  Button.setMonitor(monitor)
  Button.clearMon()

  monitor.setCursorPos(8, 1)
  monitor.write('Door')
  term.clear()
  print('Press Q to quit')
end

function stdButton(x, y, name)
  local btn = Button.create(name).setPos(x, y)
  btn.setColor(colors.white).setBlinkColor(colors.lightGray)
  btn.setSize(12, 3).onClickReturn(name)
  return btn
end

function writeConfig()
  local file = fs.open(configPath, 'w')
  file.write(textutils.serialise(config))
  file.close()
end

function setModem()
  term.clear()
  print('Which side is modem on?')
  config.modem = read()
  writeConfig()
end

function send(message)
  rednet.open(config.modem)
  if message == 'Open' then
    sleep(0.5)
    rednet.broadcast(false, 'door2')
    sleep(0.5)
    rednet.broadcast(false, 'door1')
  end
  if message == 'Close' then
    sleep(0.5)
    rednet.broadcast(true, 'door1')
    sleep(0.5)
    rednet.broadcast(true, 'door2')
  end
  rednet.close()
end

function buttonListener()
  while true do
    local command = Button.await(buttons)
    send(command)
  end
end

function keyListener()
  local running = true
  while running do
    local evt, key = os.pullEvent('key')
    if key == keys.q then
      running = false
    end
  end
  monitor.clear()
  term.clear()
  term.setCursorPos(1, 1)
end

init()
parallel.waitForAny(keyListener, buttonListener)
return true
