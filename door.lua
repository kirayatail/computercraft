-- 2
local conf = {
    doorSide = 'right'
}
local ws = nil

function init()
    if not fs.exists('lib/websocket.lua') then
        shell.run('installer lib/websocket.lua')
    end
    ws = require('lib/websocket')
end

init()

ws.methods({{
    type = 'toggle',
    key = 'Open',
    value = false,
    fn = function(state)
        redstone.setOutput(conf.doorSide, state)
        return state
    end
}})

ws.connect('Door', true)
ws.runtime()
