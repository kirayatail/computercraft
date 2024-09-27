--1

-- Constant
local density = 10
local materials = {
  { name = 'Ludicrite', dragC = 0.35, bonus = 1.02, efficiency = 1.155}
}

-- Configuration
local currentMaterialIndex = 1
local blades = 1
local shaftCount = 10
local coilCount = 1

function erCalc()
  local points = {}
  local mat = materials[currentMaterialIndex]
  for steam = 1, 2000 do
    local torque = 0
    local bladeCap = blades * 25
    if bladeCap >= steam then
      torque = steam * density
    else
      local bladeReq = steamIn / 25
      torque = (bladeCap + (steam - bladeCap) * (1 - ((bladeReq - blades) / bladeReq))) * density
    end

    local rpm = math.max(0, (torque - ((blades + shaft)/10) / (mat.dragC * coilCount + blades/4000)))
    
    local turbineEfficiency = 0;
    if (rpm )
    local power = 
  end
end