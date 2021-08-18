--4
local url = 'https://raw.githubusercontent.com/kirayatail/computercraft/master/'
local fileList = {}
local offset = 0
local cursor = 1

function refresh()
    fileList = textutils.unserialiseJSON(http.get(url..'list.json').readAll())
    for i,entry in pairs(fileList) do
        if fs.exists(entry.name) then
            local v = tonumber(string.sub(fs.open(entry.name, 'r').readLine(),3))
            fileList[i].localVersion = v
        end
    end
end

function install(index)
    local record = fileList[index]
    if record.localVersion then
        if record.version == record.localVersion then
            return
        end
        fs.delete(record.name)
    end
    local res = http.get(url..record.name, nil, true).readAll()
    local file = fs.open(record.name, 'wb')
    file.write(res)
    file.close()
    refresh()
end

function remove(index)
    local record = fileList[index]
    if record.localVersion and fs.exists(record.name) then
        fs.delete(record.name)
    end
    refresh()
end

function update()
    for i,r in pairs(fileList) do
        if r.localVersion and r.localVersion < r.version then
            install(i)
        end
    end
    refresh()
end

function display()
    if pocket then 
        updateOffset(8)
        displayPocket()
    else
        updateOffset(15)
        displayStandard()
    end
end

function updateOffset(lines)
    if cursor > offset + lines then
        offset = cursor - lines
    end
    if cursor <= offset then
        offset = cursor - 1
    end
end

function displayPocket()
    term.clear()
    term.setCursorPos(3,1)
    term.write('Pocket Installer')
    term.setCursorPos(2,2)
    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.black)
    term.write('                        ')
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    for line = 1,8 do
        if line == cursor - offset then
            term.setCursorPos(1, line*2 + 1)
            term.write('>')
        end
        if (line + offset <= table.getn(fileList)) then
            local file = fileList[line + offset]
            term.setCursorPos(3, line*2 + 1)
            term.write(file.name)
            term.setCursorPos(3, line*2 + 2)
            term.write(string.format("Version: %d Local: %d", file.version, file.localVersion or ""))
        end
    end
    term.setCursorPos(1, 20)
    term.blit('i', 'f', '0')
    term.write('nstall ')
    term.blit('r', 'f', '0')
    term.write('emove ')
    term.blit('u', 'f', '0')
    term.write('pdate ')
    term.blit('q', 'f', '0')
    term.write('uit')
end

function displayStandard()
    term.clear()
    term.setCursorPos(3,1)
    term.write('Program Installer')
    term.setCursorPos(2,2)
    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.black)
    term.write(' Name                       Version   Installed ')
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    for line = 1,15 do
        if (line == cursor - offset) then
            term.setCursorPos(1, line + 2)
            term.write('>')
        end
        if (line + offset <= table.getn(fileList)) then
            local file = fileList[line + offset]
            term.setCursorPos(3, line + 2)
            term.write(file.name)
            term.setCursorPos(30, line + 2)
            term.write(string.format("%d", file.version))
            if file.localVersion then
                term.setCursorPos(40, line + 2)
                term.write(string.format("%d", file.localVersion))
            end
        end
    end
    term.setCursorPos(5, 19)
    term.blit('i', 'f', '0')
    term.write('nstall     ')
    term.blit('r', 'f', '0')
    term.write('emove     ')
    term.blit('u', 'f', '0')
    term.write('pdate all     ')
    term.blit('q', 'f', '0')
    term.write('uit')
end

function keyListener()
    while true do
        local event, key = os.pullEvent('key')
        if key == keys.up and cursor > 1 then
            cursor = cursor - 1
        end
        if key == keys.down and cursor < table.getn(fileList) then
            cursor = cursor + 1
        end
        if key == keys.i or key == keys.enter then
            install(cursor)
        end
        if key == keys.u then
            update()
        end
        if key == keys.r or key == keys.delete then
            remove(cursor)
        end
        if key == keys.q then
            term.clear()
            term.setCursorPos(1,1)
            sleep(0.05)
            return
        end
        display()
    end
end

refresh()
display()

parallel.waitForAll(keyListener)
