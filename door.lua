--1
-- Requires websocket
local conf = {
  doorSide = 'right'
}
local ws = require('websocket')

ws.methods({
  {
    type = 'toggle',
    key = 'Open',
    value = false,
    fn = function(state)
      redstone.setOutput(conf.doorSide, state)
      return state
    end
  }
})  

ws.connect('Door', true)
ws.runtime()