--4
local ws = require('websocket')
local conf = {}
local localLevel = 0


function setSides(count)
    if count > table.getn(conf.sides) then
        count = table.getn(conf.sides)
    end
    if count < 0 then 
        count = 0
    end
    localLevel = count
    for i = 1, table.getn(conf.sides) do
        redstone.setOutput(conf.sides[i], i <= count)
    end
    sendMethods()
    display()
end

function init()
    local filename = 'var/signal.conf'
    if fs.exists(filename) then
        local file = fs.open(filename, 'r')
        conf = textutils.unserialise(file.readAll())
        file.close()
    else
        conf = {
            sides = { 'back' },
            computerName = 'Signal slider',
            methodKey = 'Level'
        }
        local file = fs.open(filename, 'w')
        file.write(textutils.serialise(conf))
        file.close()
    end
    display()
    ws.connect(conf.computerName, true)
    sendMethods()
end

function sendMethods() 
    ws.methods({
        {
            type = "slider",
            key = conf.methodKey,
            value = localLevel,
            min = 0,
            max = table.getn(conf.sides),
            fn = function (level)
                setSides(tonumber(level))
            end
        }
    })
end

function keyListener()
    local running = true
    while running do
        
        local evt, key = os.pullEvent()

        if evt == 'key' and key == keys.up then
            setSides(localLevel + 1)
        end
        if evt == 'key' and key == keys.down then
            setSides(localLevel - 1)
        end
        if evt == 'key' and key == keys.q then
            running = false
        end
        if evt == 'mouse_scroll' then
            setSides(localLevel + key)
        end
    end
    ws.disconnect()
    term.clear()
end

function display()
    term.clear()
    term.setCursorPos(2, 2)
    term.write('Signal Slider');
    term.setCursorPos(2, 4);
    term.write(string.format('Level: %d/%d', localLevel, table.getn(conf.sides)))
    local w, h = term.getSize()
    term.setCursorPos(2, h-1)
    term.blit('q', 'f', '0')
    term.write('uit')
end


init()
parallel.waitForAny(ws.runtime, keyListener)