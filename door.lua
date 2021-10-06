--1
-- Requires websocket
local conf = {}
local ws = require('websocket')

function init()
  if fs.exists('var/door.conf') then 
    local file = fs.open('var/door.conf', 'r')
    conf = textutils.unserialise(file.readAll())
    file.close()
  else
    conf = {
      doorSide = 'right'
    }
    local file = fs.open('var/door.conf', 'w')
    file.write(textutils.serialise(conf))
    file.close()
  end
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
end

init()
ws.connect('Door', true)
ws.runtime()