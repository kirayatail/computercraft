-- 2
local configFilepath = 'var/refinery.conf'
local Term = nil
local chest = nil
local tank = nil

local config = {
    tankIn = 'back',
    tankOut = 'bottom',
    chestIn = 'right',
    chestOut = 'right',
    state = 'chest'
}

local function init()
    if not fs.exists('lib/term.lua') then
        shell.run('installer lib/term.lua')
    end
    Term = require('lib/term')

    if not fs.exists(configFilepath) then
        local file = fs.open(configFilepath, 'w')
        file.write(textutils.serialise(config))
        file.close()
    end
    local file = fs.open(configFilepath, 'r')
    config = textutils.unserialise(file.readAll())
    file.close()
    chest = peripheral.wrap(config.chestIn)
    tank = peripheral.wrap(config.tankIn)
end

function writeConfig()
    local file = fs.open(configFilepath, 'w')
    file.write(textutils.serialise(config))
    file.close()
end

local function display()
    term.clear()
    Term.out('Output:', 2, 2)
    Term.out(config.state, 2, 10)
end

local function watcher()
    local running = chest ~= nil and tank ~= nil;
    while running do
        local hasTankContent = tank.getTanks()[1].amount ~= nil
        local hasChestContent = chest.getItem(1) ~= nil

        if hasChestContent and not hasTankContent then
            config.state = 'chest'
        end
        if hasTankContent and not hasChestContent then
            config.state = 'tank'
        end

        if config.state == 'chest' then
            rs.setOutput(config.chestOut, true)
            rs.setOutput(config.tankOut, false)
        else
            rs.setOutput(config.tankOut, true)
            rs.setOutput(config.chestOut, false)
        end

        writeConfig()

        display()
        sleep(20)
    end
end

init()
watcher()
