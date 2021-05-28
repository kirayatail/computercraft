local r = peripheral.wrap('back')
local targetWaste = 2000
local targetSteam = math.floor(r.getHotFluidAmountMax() * 0.5)
local stopSteam = math.floor(r.getHotFluidAmountMax() * 0.9)
local active = true
local prevSteam = -1

function getMaxControl() 
    return r.getNumberOfControlRods() * 100
end

local controlRods = getMaxControl() - 1


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
    local level = (getMaxControl() - controlRods) / r.getNumberOfControlRods()
--    level = r.getActive() and level or 0
    term.write((getMaxControl() - controlRods) .. "/" .. (getMaxControl()))
    term.setCursorPos(2,5)
    local efficiency = (r.getHotFluidProducedLastTick() / r.getFuelConsumedLastTick())
    efficiency = r.getActive() and efficiency or 0
    term.write("Efficiency (steam/fuel): ")
    term.write(math.floor(efficiency* 100) / 100)
end

while r.getWasteAmount() < (targetWaste - 20) do
  steam = r.getHotFluidAmount() + r.getHotFluidProducedLastTick()
  if steam < targetSteam and steam <= prevSteam and controlRods > 0 then
    controlRods = controlRods - 1
  end
  
  if steam > targetSteam and steam >= prevSteam and controlRods < getMaxControl() then
    controlRods = controlRods + 1
  end
  prevSteam = steam
  
  active = steam < stopSteam
  r.setActive(active)
  setControl(controlRods)
  display()
  sleep(0.2)
end

while r.getWasteAmount() < targetWaste do
  sleep(0.1)
end
r.setActive(false)
