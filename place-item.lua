--1
local ws = require('websocket')
local conf = {}

function init()
    if fs.exists('var/place-item.conf') then
        local file = fs.open('var/place-item.conf', 'r')
        conf = textutils.unserialise(file.readAll())
        file.close()
    else
        conf = {
            compName = "Item placer",
            methodKey = "Item placed"
        }
        local file = fs.open('var/place-item.conf', 'w')
        file.write(textutils.serialise(conf))
        file.close()
    end
    ws.methods({
        {
            type = "toggle",
            key = conf.methodKey,
            value = turtle.detect(),
            fn = function(place)
                if place then
                    turtle.place()
                else
                    turtle.dig()
                end
                return turtle.detect()
            end
        }
    })
end

init()
ws.connect(conf.compName, true)
ws.runtime()