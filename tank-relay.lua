--1
local config = {
  tankSide = "back",
  signalSide = "bottom"
}

local function init()
  if not fs.exists('var/tank-relay.conf') then
    local file = fs.open('var/tank-relay.conf', 'w')
    file.write(textutils.serialise(config))
    file.close()
  end
  local file = fs.open('var/tank-relay.conf', 'r')
  config = textutils.unserialise(file.readAll())
  file.close()
end

local function watcher()
  local p = peripheral.wrap(config.tankSide)
  local running = true
  while running do
    local tanks = p.getTanks()
    if #tanks < 1 then
      term.clear()
      term.write('Tank not found')
      running = false
      return
    end
    rs.setOutput(config.signalSide, tanks[1].amount ~= nil)
    sleep(5)
  end
end

watcher()