--1
local configFile = 'var/config-loader.conf'
local config = {}
local args = {...}

function init()
  if fs.exists(configFile) then
    local file = fs.open(configFile, 'r')
    config = textutils.unserialise(file.readAll())
    file.close()
  else
    term.clear()
    print('What is the root URL for the config server?')
    config = {
      url = read()
    }
    local file = fs.open(configFile, 'w')
    file.write(textutils.serialise(config))
    file.close()
  end
end

function getKey()
  if #args == 1 then
    return args[1]
  else
    term.clear()
    print('Please provide a key')
    return read()
  end
end

function fetch()
  local response = textutils.unserialiseJSON(http.get(config.url..'/api/file/'..getKey()).readAll())
  local file = fs.open(response.path, 'w')
  if response.type == 'text' then
    file.write(response.content);
  end

  if response.type == 'json' then
    file.write(textutils.serialise(response.content))
  end
  file.close()
end

init()
fetch()