--1
local ws = require('websocket')
local conf = {}
local sides = {
    "left", "right", "back"
}

function setSides(count)
    for i = 1, table.getn(conf.sides) do
        redstone.setOutput(conf.sides[i], i <= count)
    end
end

function init()
    if fs.exists('var/tri-signal.conf') then
        local file = fs.open('var/tri-signal.conf', 'r')
        conf = textutils.unserialise(file.readAll())
        file.close()
    else
        conf = {
            sides = { 'back' },
            computerName = 'Signal slider',
            methodKey = 'Level'
        }
        local file = fs.open('var/tri-signal.conf', 'w')
        file.write(textutils.serialise(conf))
        file.close()
    end
    ws.methods({
        {
            type = "slider",
            key = conf.methodKey,
            value = 0,
            min = 0,
            max = table.getn(conf.sides),
            fn = function (level)
                setSides(level)
                return level
            end
        }
    })
end

init()
ws.connect(conf.computerName)
ws.runtime()