-- 6
local shouldRun = true
local currentProgram = 1
local programSteps = {"Filling items", "Wait for items", "Wait for signal", "Pushing items to machine",
                      "Cleaning up inventory"}
local pc = 0

function itemCount()
  local count = 0
  for i = 1, 6 do
    count = count + turtle.getItemCount(i)
  end
  return count
end

function fill()
  pc = 1
  display()
  turtle.select(1)
  while itemCount() < (6 * 64) and shouldRun do
    local gotItems = turtle.suckDown()
    if not gotItems then
      pc = 2
      display()
      sleep(10)
    else
      pc = 1
      display()
    end
  end
end

function unload()
  pc = 4
  display()
  for i = 1, 6 do
    turtle.select(i)
    turtle.dropUp()
  end
  turtle.select(1)
end

function empty()
  pc = 5
  display()
  for i = 1, 16 do
    turtle.select(i)
    turtle.dropDown()
  end
  turtle.select(1)
end

function runner()
  while shouldRun do
    fill()
    while not redstone.getInput('left') and shouldRun do
      pc = 3
      display()
      sleep(10)
    end
    if shouldRun then
      unload()
    end
    empty()
    if shouldRun then
      sleep(10)
    end
  end
end

function display()
  term.clear()
  for i, text in pairs(programSteps) do
    if i == pc then
      term.setCursorPos(2, i + 1)
      term.blit("  ", "f0", "0f")
    end
    term.setCursorPos(4, i + 1)
    term.write(text)
  end
  if not shouldRun then
    term.setCursorPos(2, #programSteps + 2)
    term.blit("  ", "f0", "0f")
  end
  term.setCursorPos(4, #programSteps + 2)
  print('Loader will stop')
end

function keyListener()
  while true do
    local evt, key = os.pullEvent('key')
    if key == keys.q then
      shouldRun = false
    end
    display()
  end
end

parallel.waitForAny(keyListener, runner)

return true
