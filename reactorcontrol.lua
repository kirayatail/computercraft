--2
local r = peripheral.wrap('back')
local targetWaste = 2000
local targetSteam = math.floor(r.getHotFluidAmountMax() * 0.5)
local stopSteam = math.floor(r.getHotFluidAmountMax() * 0.9)
local prevSteam = -1

function getMaxControl() 
  return r.getNumberOfControlRods() * 100
end

function getControl()
  local rods = r.getNumberOfControlRods()
  local level = 0
  for i = 0, rods do
    level = level + r.getControlRodLevel(i)
  end
  return level
end

local controlLevel = getControl()


function setControl(val)
    local rods = r.getNumberOfControlRods()
    local base = math.floor(val / rods)
    local rest = math.fmod(val, rods)
    for i = 0, rods do
        if i < rest then
            r.setControlRodLevel(i, base + 1)
        else
            r.setControlRodLevel(i, base)
        end
    end
end

function display() 
    term.clear()
    term.setCursorPos(2,2)
    term.write("Steam produced: ")
    term.write(math.floor(r.getHotFluidProducedLastTick() + 0.5))
    term.write(" mB")
    term.setCursorPos(2,3)
    term.write("Temperature: ")
    term.write(math.floor(r.getFuelTemperature() + 0.5))
    term.write(" C")
    term.setCursorPos(2,4)
    term.write("Activity level: ")
    local level = (getMaxControl() - controlLevel) / r.getNumberOfControlRods()
--    level = r.getActive() and level or 0
    term.write((getMaxControl() - controlLevel) .. "/" .. (getMaxControl()))
    term.setCursorPos(2,5)
    local efficiency = (r.getHotFluidProducedLastTick() / r.getFuelConsumedLastTick())
    efficiency = r.getActive() and efficiency or 0
    term.write("Efficiency (steam/fuel): ")
    term.write(math.floor(efficiency* 100) / 100)
end

while r.getWasteAmount() < (targetWaste - 20) do
  steam = r.getHotFluidAmount() + r.getHotFluidProducedLastTick()
  if steam < targetSteam and steam <= prevSteam and controlLevel > 0 then
    controlLevel = controlLevel - 1
  end
  
  if steam > targetSteam and steam >= prevSteam and controlLevel < getMaxControl() then
    controlLevel = controlLevel + 1
  end
  prevSteam = steam
  
  r.setActive(steam < stopSteam)
  setControl(controlLevel)
  display()
  sleep(0.2)
end

while r.getWasteAmount() < targetWaste do
  sleep(0.1)
end
r.setActive(false)
