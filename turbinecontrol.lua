local t = peripheral.wrap('back')
local state = {}
local active = {
    'shutdown',
    'idle',
    'online'
}
local options = {
    {
        name = 'state',
        min = 1,
        max = 3,
        pos = 6
    },
    {
        name = 'rpm',
        min = 0,
        max = 9000,
        pos = 25
    },
    {
        name = 'flow',
        min = 0,
        max = 2000,
        pos = 37
    }
}

local actFlow = t.getFluidFlowRateMax()
local targetFlow = 0


function init() 
    if fs.exists('turbineState.tbl') then
        stateFile = fs.open('turbineState.tbl', 'r')
        state = textutils.unserialise(stateFile.readAll())
        stateFile.close()
        state.cursor = 1
    else 
        state = {
            target = {},
            active = 1,
            level = 1,
            cursor = 1
        }
        writeState()
    end
end

function writeState()
    stateFile = fs.open('turbineState.tbl', 'w')
    stateFile.write(textutils.serialise(state))
    stateFile.close()
end

function keyListener()
   while true do 
       local event, key = os.pullEvent('key')
       if key <= keys.nine and key >= keys.one then
           state.level = key - keys.one + 1
           if state.target[state.level] == nil then
               state.target[state.level] = {
                   rpm = 0,
                   flow = 0
               }
           end
       end
       if key == keys.up then
           increase()
       end
       if key == keys.down then
           decrease()
       end
       if key == keys.left then
           back()
       end 
       if key == keys.right then
           forward()
       end
       writeState()
       display()
   end
end

function increase() 
    local opt = options[state.cursor]
    if opt.name == 'state' then 
        local amt = state.active + 1
        if amt <= opt.max then
            state.active = amt
        end
    else
        local amt = state.target[state.level][opt.name] + 1
        if amt <= opt.max then
            state.target[state.level][opt.name] = amt
        end
    end
end
function decrease() 
    local opt = options[state.cursor]
    if opt.name == 'state' then 
        local amt = state.active - 1
        if amt >= opt.min then
            state.active = amt
        end
    else
        local amt = state.target[state.level][opt.name] - 1
        if amt >= opt.min then
            state.target[state.level][opt.name] = amt
        end
    end
end
function back() 
    local crs = state.cursor - 1
    if crs < 1 then
        crs = table.getn(options)
    end
    state.cursor = crs
end
function forward()
    local crs = state.cursor + 1
    if crs > table.getn(options) then
        crs = 1
    end
    state.cursor = crs
end

function displayLevel() 
    for i = 1,9 do
        term.setCursorPos(5*i, 1)
        if i == state.level then
            term.setTextColor(colors.black)
            term.setBackgroundColor(colors.white)
        end
        term.write('   ')
        term.setCursorPos(5*i, 2)
        term.write(string.format(' %d ', i))
        term.setCursorPos(5*i, 3)
        term.write('   ')
        term.setTextColor(colors.white)
        term.setBackgroundColor(colors.black)
    end
end

function displayInfo() 
    local rf = t.getEnergyProducedLastTick()
    local rpm = t.getRotorSpeed()
    local flow = t.getFluidFlowRate()
    local storage = t.getEnergyStored()
    local bladeEfficiency = t.getBladeEfficiency()
    local efficiency = 0
    if rf > 0 and flow > 0 then
        efficiency = rf / flow
    end
    term.setCursorPos(6, 5)
    term.write(string.format("RPM: %1.2f", rpm))
    term.setCursorPos(6, 7)
    term.write(string.format("RF: %1.2f", rf))
    term.setCursorPos(6, 9)
    term.write(string.format("Flow: %d", actFlow))
    term.setCursorPos(6, 11)
    term.write(string.format("RF/mB: %1.2f", efficiency))
    term.setCursorPos(6, 13)
    term.write(string.format("Blades: %1.2f%%", bladeEfficiency))
    if storage > 2 * rf then
        term.setCursorPos(26, 5)
        term.write("WARNING! Storing energy!")
    end
end

function displayOptions() 
    for i = 1, table.getn(options) do
        local op = options[i]
        local value = ""
        if i == state.cursor then
            term.setTextColor(colors.black)
            term.setBackgroundColor(colors.white)
        end
        term.setCursorPos(op.pos, 16)
        if op.name == 'state' then
            value = active[state.active]
        else 
            value = string.format("%d", state.target[state.level][op.name])
        end
        term.write(string.format("%s:", op.name))
        term.setTextColor(colors.white)
        term.setBackgroundColor(colors.black)
        term.write(string.format(" %s", value))
    end
end

function display()
    term.clear()
    displayLevel()
    displayInfo()
    displayOptions()
end

function control()
    while true do
        local rpm = t.getRotorSpeed()
        local targetRPM = state.target[state.level].rpm
        
        if state.active == 1 then -- Shutdown mode
            targetFlow = 0
            --t.setFluidFlowRateMax(0)
            
            t.setInductorEngaged(true)
            t.setActive(true)
        end
        if state.active == 2 then -- Idle mode
            t.setActive(true)
            t.setInductorEngaged(false)

            if rpm < (targetRPM - 10) then
                targetFlow = 5 * state.level
            end
            if rpm > (targetRPM + 10) then 
                targetFlow = 0
            end
        end
        if state.active == 3 then -- Online mode
            t.setActive(true)
            if rpm < (targetRPM + 200) then
                targetFlow = state.target[state.level].flow
                -- t.setFluidFlowRateMax(targetFlow)
            else
                targetFlow = 0
            end
            if rpm < (targetRPM - 1) then
                t.setInductorEngaged(false)
            end
            if rpm > (targetRPM + 1) then 
                t.setInductorEngaged(true)
            end
        end
        display()
        sleep(0.1)
    end
end

function flowUpdate()
    while true do
        if actFlow < targetFlow then
            actFlow = actFlow + 1
        elseif actFlow > targetFlow then
            actFlow = actFlow - 1
        end
        t.setFluidFlowRateMax(actFlow)
        sleep(0.15)
    end    
end

init()
parallel.waitForAll(keyListener, control, flowUpdate)
