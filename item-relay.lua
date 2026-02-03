-- 3
local config = {
  chestSide = "back",
  signalSide = "bottom",
  chestSlot = 1,
  chestLimit = 180000
}
local configFileName = 'var/item-relay.conf'

local function init()
  if not fs.exists(configFileName) then
    local file = fs.open(configFileName, 'w')
    file.write(textutils.serialise(config))
    file.close()
  end
  local file = fs.open(configFileName, 'r')
  config = textutils.unserialise(file.readAll())
  file.close()
end

local function display(count, active)
  term.clear()
  term.setCursorPos(1, 1)
  term.write('Item Relay')
  term.setCursorPos(1, 3)
  term.write('Count: ' .. tostring(count))
  term.setCursorPos(1, 4)
  term.write('Limit: ' .. tostring(config.chestLimit))
  term.setCursorPos(1, 5)
  term.write('Active: ' .. tostring(active))
end

local function watcher()
  local p = peripheral.wrap(config.chestSide)
  local running = true
  while running do
    local slots = p.list()
    if #slots < 1 then
      term.clear()
      term.write('Inventory empty')
      running = false
      return
    end
    local count = slots[config.chestSlot].count
    local active = count ~= nil and count > config.chestLimit
    display(count, active)
    rs.setOutput(config.signalSide, active)
    sleep(5)
  end
end

init()
watcher()
