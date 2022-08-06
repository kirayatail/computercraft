--14
local t = nil
local state = {}
local socket = nil
local active = {
    'shutdown',
    'stop',
    'coast',
    'online'
}
local actFlow = nil
local targetFlow = 0

local function indexOf(tbl, val)
    local index = {}
    for k,v in pairs(tbl) do
        index[v] = k
    end
    return index[val]
end

local options = {
    {
        name = 'state',
        min = 1,
        max = #active,
        pos = 6
    },
    {
        name = 'rpm',
        min = 0,
        max = 10000,
        pos = 25
    },
    {
        name = 'flow',
        min = 0,
        max = 2000,
        pos = 37
    }
}

function init() 
    if fs.exists('turbineState.tbl') and not fs.exists('var/turbineState.tbl') then
        fs.move('turbineState.tbl', 'var/turbineState.tbl')
    end
    if fs.exists('var/turbineState.tbl') then
        stateFile = fs.open('var/turbineState.tbl', 'r')
        state = textutils.unserialise(stateFile.readAll())
        stateFile.close()
        state.cursor = 1
    else 
        state = {
            target = {
                {
                    rpm = 0,
                    flow = 0
                }
            },
            active = 1,
            level = 1,
            cursor = 1
        }
        writeState()
    end
    if state.portSide == nil then
        setPortSide()
    end
    t = peripheral.wrap(state.portSide)
    actFlow = t.getFluidFlowRateMax()
    

    if fs.exists('websocket.lua') then
        socket = require('websocket');
    end
end

function setPortSide()
    term.clear()
    print('Which side is the port on?')
    state.portSide = read()
    writeState()
    term.clear()
end

function setLevel(l)
    state.level = tonumber(l)
    if state.target[state.level] == nil then
        state.target[state.level] = {
            rpm = 0,
            flow = 0
        }
    end
end

function sendMethods()
    if socket then
        socket.methods({
            {
                type='dropdown',
                key='preset',
                name='Preset',
                options={1,2,3,4,5,6,7,8,9},
                value=state.level,
                fn = function(value)
                    setLevel(value)
                    writeState()
                    sendMethods()
                end
            },
            {
                type='radio',
                key= 'state',
                name = 'Power',
                options = active,
                value = active[state.active],
                fn = function(value)
                    state.active = indexOf(active, value)
                    writeState()
                    return value
                end
            },
            {
                type ='number',
                key ='speed',
                name = 'RPM',
                min = 0,
                max = 10000,
                value = state.target[state.level]['rpm'],
                fn = function(value)
                    if value == nil or value < 0 then
                        value = 0
                    end
                    if value > 10000 then
                        value = 10000
                    end
                    state.target[state.level]['rpm'] = value
                    writeState()
                    return value
                end
            },
            {
                type ='number',
                key ='flow',
                name = 'Steam',
                min = 0,
                max = 2000,
                value = state.target[state.level]['flow'],
                fn = function(value)
                    if value == nil or value < 0 then
                        value = 0
                    end
                    if value > 2000 then
                        value = 2000
                    end
                    state.target[state.level]['flow'] = value
                    writeState()
                    return value
                end
            }
        })
    end
end

function sendInfo()
    if socket then
        local rf = t.getEnergyProducedLastTick()
        local flow = t.getFluidFlowRate()
        local efficiency = 0
        if rf > 0 and flow > 0 then
            efficiency = rf / flow
        end
        socket.info({
            {
                key = 'RPM',
                value = t.getRotorSpeed(),
                type = 'number'
            },
            {
                key = 'RF',
                value = rf,
                type= 'number'
            },
            {
                key = 'Efficiency',
                value = efficiency,
                type =  'number'
            },
            {
                key = 'Low Flow',
                value = flow < actFlow,
                type = 'warning'
            },
            {
                key = 'Storing energy',
                value = t.getEnergyStored() > 10000,
                type = 'warning'
            }
        })
    end
end

function writeState()
    stateFile = fs.open('var/turbineState.tbl', 'w')
    stateFile.write(textutils.serialise(state))
    stateFile.close()
end

function keyListener()
    while true do 
        local event, key = os.pullEvent('key')
        if key <= keys.nine and key >= keys.one then
            setLevel(key - keys.one + 1)            
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
        if key == keys.enter and socket then
            if not socket.isConnected() then
                socket.connect('turbine', true)
            else
                socket.disconnect()
            end
        end
        writeState()
        sendMethods()
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
    term.write(string.format("Target flow: %d", targetFlow))
    if storage > 2 * rf then
        term.setCursorPos(26, 5)
        term.write("WARNING! Storing energy!")
    end
    term.setCursorPos(26, 7)
    if socket then
        if socket.isConnected() then
            term.write('Websocket ID: '..socket.id())
        else
            term.write('Websocket available')
            term.setCursorPos(26, 9)
            term.write('Press Enter to connect')
        end
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
    sendInfo()
end

function flowCalc(target, targetRPM, rpm) 
    local maxFlow = math.max(t.getNumberOfBlades() * 25, target)
    local rampFactor = 0.025 * t.getNumberOfBlades() + 0.1
    return math.max(0, math.min(maxFlow, target + math.floor((targetRPM - rpm) * rampFactor)))
end

function control()
    while true do
        local rpm = t.getRotorSpeed()
        local targetRPM = state.target[state.level].rpm
        t.setActive(true)

        if state.active == 1 then -- Shutdown mode
            targetFlow = 0
            t.setInductorEngaged(true)
        end
        if state.active == 2 then -- Stop mode (no output)
            t.setInductorEngaged(false)
            targetFlow = flowCalc(0, targetRPM, rpm)
        end
        if state.active == 3 then -- Coast mode (idle and output)
            targetFlow = flowCalc(0, targetRPM, rpm)

            if rpm < (targetRPM - 1) then
                t.setInductorEngaged(false)
            end
            if rpm >= targetRPM then 
                t.setInductorEngaged(true)
            end
        end
        if state.active == 4 then -- Online mode
            targetFlow = flowCalc(state.target[state.level].flow, targetRPM, rpm)
            
            if rpm < (targetRPM - 1) then
                t.setInductorEngaged(false)
            end
            if rpm >= targetRPM then 
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

local loops = {
    keyListener,
    control,
    flowUpdate
}

if socket then
    table.insert(loops, socket.runtime)
end

parallel.waitForAll(unpack(loops))
