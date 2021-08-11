--5
function S()
    local conf = {}
    local socket = nil
    local id = nil
    local computerType = nil
    local info = {}
    local methods = {}
    local reconnect = false
    local printVerbose = false

    local function map(tbl, f)
        local t = {}
        for k,v in pairs(tbl) do
            t[k] = f(v)
        end
        return t
    end

    local function find(tbl, f)
        for k,v in pairs(tbl) do 
            if f(v) then return tbl[k], k end
        end
        return nil
    end

    local function clean(tbl) 
        return map(tbl, function (m)
            local obj = {
                type = m.type,
                key = m.key,
            }
            if m.value then
                obj['value'] = m.value
            end
            if m.name then
                obj['name'] = m.name
            end
            if m.options then 
                obj['options'] = m.options
            end
            if m.min then
                obj['min'] = m.min
            end
            if m.max then
                obj['max'] = m.max
            end
            return obj
        end)
    end

    local function saveConf()
        local file = fs.open('var/websocket.conf', 'w')
        file.write(textutils.serialise(conf))
        file.close()
    end

    if not fs.exists('var/websocket.conf') and fs.exists('websocket.conf') then
       fs.move('websocket.conf', 'var/websocket.conf') 
    end

    if fs.exists('var/websocket.conf') then
        local file = fs.open('var/websocket.conf', 'r')
        conf = textutils.unserialise(file.readAll())
        file.close()
    end

    if not conf.address then
        term.clear()
        print('Which address should Websocket connect to?')
        local input = read()
        if not string.match(input, '^wss?://') then
            input = 'ws://' .. input
        end
        conf.address = input
        saveConf()
    end

    function connect(type)
        if socket and id then
            disconnect()
        end
        computerType = type or 'computer'
        http.websocketAsync(conf.address)
    end

    function disconnect()
        if socket and id then
            socket.close()
            socket = nil
            id = nil
            reconnect = false
        end
    end

    function info(data)
        info = data
        if socket and id then
            socket.send(textutils.serialiseJSON({
                type = 'info',
                id = id,
                payload = info
            }));
        end
    end

    function methods(data)
        methods = data
        if socket and id then
            socket.send(textutils.serialiseJSON({
                type = 'methods',
                id = id,
                payload = clean(methods)
            }));
        end
    end

    function verbose(f)
        printVerbose = f
    end

    function isConnected()
        return socket and id
    end

    function id()
        return id
    end

    function socketRuntime()
        while true do
            local eventData = {os.pullEvent()}
            if eventData[1] == 'websocket_success' then
                socket = eventData[3]
                socket.send(textutils.serialiseJSON({
                    type = 'handshake', payload = computerType
                }))
            end
            if eventData[1] == 'websocket_failure' then
            end
            if eventData[1] == 'websocket_closed' then
                id = nil
                socket = nil
            end
            if eventData[1] == 'websocket_message' then
                local message = textutils.unserialiseJSON(eventData[3])
                if printVerbose then
                    print(eventData[3])
                end
                if message.type == 'handshake' then
                    id = message.id
                    socket.send(textutils.serialiseJSON({
                        type = 'methods', id = id,
                        payload = clean(methods)
                    }))
                end
                if message.type == 'command' then
                    local m,i = find(methods, function(m) return m.key == message.payload.key end)
                    if m.type == 'void' then
                        m.fn()
                    else
                        local res = m.fn(message.payload.value)
                        if res ~= nil then
                            methods[i].value = res
                            socket.send(textutils.serialiseJSON({
                                type = 'methods', id = id,
                                payload = clean(methods)
                            }))
                        end
                    end
                end
            end
        end
    end
    return {
        connect = connect,
        disconnect = disconnect,
        id = id,
        info = info,
        isConnected = isConnected,
        methods = methods,
        runtime = socketRuntime,
        verbose = verbose
    }
end
return S()