-- 1
local shouldRun = true

function itemCount()
  local count = 0
  for i = 1, 6 do
    count = count + turtle.getItemCount()
  end
  return count
end

function fill()
  while itemCount() < (6 * 64) do
    local gotItems = turtle.suckDown()
    if not gotItems then
      sleep(10)
    end
  end
end

function unload()
  for i = 1, 6 do
    turtle.select(i)
    turtle.dropUp()
  end
  turtle.select(1)
end

function empty()
  for i = 1, 16 do
    turtle.select(i)
    turtle.dropDown()
  end
  turtle.select(1)
end

function cycle()
  fill()
  unload()
  empty()
  sleep(1)
end

function runner()
  while shouldRun do
    if redstone.getInput('left') then
      cycle()
    else
      sleep(10)
    end
  end
end

function keyListener()
  while true do
    local evt, key = os.pullEvent('key')
    if key == keys.q then
      shouldRun = false
    end
  end
end

parallel.waitForAny(keyListener, runner)

return true
