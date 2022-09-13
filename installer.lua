--10
local url = 'https://raw.githubusercontent.com/kirayatail/computercraft/master/'
local Term = nil
local Tbl = nil
local fileList = {}
local offset = 0
local cursor = 1
local width, height = term.getSize()
local args = {...}

function init() 
  if not fs.exists('lib/term.lua') then
    shell.run('installer', 'lib/term.lua')
  end
  if not fs.exists('lib/table.lua') then
    --shell.run('installer', 'lib/table.lua')
  end
  Tbl = require('lib/table')
  Term = require('lib/term')
end

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
    if record.name == getStartup() then
      toggleStartup(index)
    end
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
    updateOffset(height - 4)
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

function getStartup() 
  if fs.exists('/startup.lua') then
    file = fs.open('/startup.lua', 'r')
    startupFile = string.match(file.readLine() or "", "[^'\"]+\.lua")
    file.close()
    return startupFile;
  end
  return ""
end

function toggleStartup(index)
  local filename = fileList[index].name  
  if filename ~= getStartup() then
    setStartup(index, true)
  else
    setStartup(index, false)
  end
end

function setStartup(index, enable)
  local record = fileList[index]
  local command = ""
  if enable then
    if not record.localVersion then
      install(index)
    end
    command = "shell.run('"..record.name.."')"
  end
  local file = fs.open('startup.lua', 'w')
  file.write(command)
  file.close()
end

function displayPocket()
  local startupFile = getStartup()
  term.clear()
  Term.out('Pocket Installer', 1, 3)
  term.setBackgroundColor(colors.white)
  term.setTextColor(colors.black)
  Term.out('                        ', 2, 2)
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
  for line = 1,8 do
    if line == cursor - offset then
      Term.out('>', line * 2 + 1, 1)
    end
    if (line + offset <= table.getn(fileList)) then
      local file = fileList[line + offset]
      if file == startupFile then
        Term.out('*', line * 2 + 1, 2)
      end
      Term.out(file.name, line * 2 + 1, 3)
      term.setBackgroundColor(colors.white)
      term.setTextColor(colors.black)
      Term.out('                        ', line * 2 + 2)
      Term.out(string.format("Version: %d ", file.version), line * 2 + 2, 3)
      if file.localVersion then 
        Term.out(string.format("Local: %d", file.localVersion))
      end
      term.setBackgroundColor(colors.black)
      term.setTextColor(colors.white)
    end
  end
  Term.initial('install ', 'f', '0', 20, 1)
  Term.initial('remove ', 'f', '0')
  Term.initial('update ', 'f', '0')
  Term.initial('quit', 'f', '0')
end

function displayStandard()
  local startupFile = getStartup()
  term.clear()
  Term.out('Program Installer', 1, 3)
  term.setBackgroundColor(colors.white)
  term.setTextColor(colors.black)
  Term.out('  Name                      Version   Installed ', 2, 2)
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
  for line = 1,height-4 do
    if (line == cursor - offset) then
      Term.out('>', line + 2, 1)
    end
    if (line + offset <= table.getn(fileList)) then
      local file = fileList[line + offset]
      if file.name == startupFile then
        Term.out('*', line + 2, 2)
      end
      Term.out(file.name, line + 2, 4)
      Term.out(string.format("%d", file.version), line + 2, 30)
      if file.localVersion then
        Term.out(string.format("%d", file.localVersion), line + 2, 40)
      end
    end
  end
  
  Term.initial('install  ', 'f', '0', height, 4)
  Term.initial('autostart  ', 'f', '0')
  Term.initial('remove  ', 'f', '0')
  Term.initial('update all  ', 'f', '0')
  Term.initial('quit', 'f', '0')
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
    if key == keys.a then
      toggleStartup(cursor)
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

function cli()
  local helpFlag = Tbl.find(args, function (v) return string.lower(v) == "-h" end)
  local autostartFlag = Tbl.find(args, function (v) return string.lower(v) == "-a" end)
  local path = args[#args]
  if helpFlag ~= nil then
    print('Installer CLI')
    print('Usage: installer [flags] <file path>')
    print('-a \tSet autostart for the installed file')
    print('-h \tPrint this help text')
    return true
  end

  local _, index = Tbl.find(fileList, function (entry) return path == entry.name end)
  if index == nil then return false end

  print('installing '..path)
  if autostartFlag then
    setStartup(index)
  else
    install(index)
  end
  return true
end

init()
refresh()
if #args == 0 then 
  display()
  parallel.waitForAll(keyListener)
else
  return cli()
end
