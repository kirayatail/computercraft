--2
-- This program should be run by a turtle which is equipped with a pickaxe or other tool that allows it to perform dig().
-- It will detect if there's a block placed in front of it, and alternate between mining that block and placing it back.
-- Useful example: Place in front of a power line and use this program as a connection switch.
-- Configuration: First time use will create a default configuration file at /var/place-item.conf. 
-- Modify this file to set the name of the turtle and the action it performs.

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
    sendMethods()
end

function toggleDig() 
    if not turtle.detect() then
        turtle.place()
    else
        turtle.dig()
    end
end

function sendMethods()
    ws.methods({
        {
            type = "toggle",
            key = conf.methodKey,
            value = turtle.detect(),
            fn = function(place)
                toggleDig()
                return turtle.detect()
            end
        }
    })
end

function keyListener()
    local running = true
    while running do
        local evt, key = os.pullEvent('key')
        if key == keys.enter then
            toggleDig()
            sendMethods()
        end
    end
end


init()
ws.connect(conf.compName, true)
parallel.waitForAny(ws.runtime, keyListener)
