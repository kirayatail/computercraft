--1
local filename = 'var/seq-client.conf'
local config = {}

function init()
    if fs.exists(filename) then
        local file = fs.open(filename, 'r')
        config = textutils.unserialise(file.readAll())
        file.close()
    else 
        config = {
            phases = {},
            modem = "left"
        }
        write()
    end
    rednet.open(config.modem)
end

function write()
    local file = fs.open(filename, 'w')
    file.write(textutils.serialise(config))
    file.close()
end

function set(phase, value) 
    if phase == nil then
        return
    end
    for _,side in pairs(phase) do
        rs.setOutput(side, value)
    end
end

function run()
    while true do
        local _, state, proto = rednet.receive()
        set(config.phases[proto], state)
    end
end

init()
run()
