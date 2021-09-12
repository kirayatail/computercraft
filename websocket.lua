--8
function S()
    local conf = {}
    local socket = nil
    local id = nil
    local computerType = nil
    local state = {
        group = nil,
        hidden = false,
        info = nil,
        methods = nil
    }
    local reconnect = false
    local printVerbose = false

    local function map(tbl, f)
        if tbl == nil then return nil end
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

    local function all()
        return {
            id = id,
            type = computerType,
            info = state['info'],
            methods = clean(state['methods']),
            group = state['group'],
            hidden = state['hidden'],
        }
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

    function connect(type, recon)
        if socket and id then
            disconnect()
        end
        reconnect = recon
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

    function sendState(type)
        return function(data)
            if type == 'methods' then
                data = clean(data)
            end
            state[type] = data
            if socket and id then
                socket.send(textutils.serialiseJSON({
                    type = type,
                    id = id,
                    payload = state[type]
                }));
            end    
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
                if reconnect then 
                    sleep(5)
                    connect(computerType, true)
                end
            end
            if eventData[1] == 'websocket_closed' then
                id = nil
                socket = nil
                if reconnect then 
                    sleep(5)
                    connect(computerType, true)
                end
            end
            if eventData[1] == 'websocket_message' then
                local message = textutils.unserialiseJSON(eventData[3])
                if printVerbose then
                    print(eventData[3])
                end
                if message.type == 'handshake' then
                    id = message.id
                    socket.send(textutils.serialiseJSON({
                        type = 'all', id = id,
                        payload = all()
                    }))
                end
                if message.type == 'command' then
                    local m,i = find(state['methods'], function(m) return m.key == message.payload.key end)
                    if m.type == 'void' then
                        m.fn()
                    else
                        local res = m.fn(message.payload.value)
                        if res ~= nil then
                            state['methods'][i].value = res
                            socket.send(textutils.serialiseJSON({
                                type = 'methods', id = id,
                                payload = clean(state['methods'])
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
        group = sendState('group'),
        hidden = sendState('hidden'),
        id = id,
        info = sendState('info'),
        isConnected = isConnected,
        methods = sendState('methods'),
        runtime = socketRuntime,
        verbose = verbose
    }
end
return S()