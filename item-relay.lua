-- 1
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
    local count = slots[config.chestSlot].amount
    rs.setOutput(config.signalSide, count ~= nil and count > config.chestLimit)
    sleep(5)
  end
end

init()
watcher()
