-- 2
local function out(value, row, col)
  if row ~= nil and col ~= nil then
    term.setCursorPos(col, row)
  end
  term.write(value)
end
local function initial(value, bg, fg, row, col)
  if row ~= nil and col ~= nil then
    term.setCursorPos(col, row)
  end
  term.blit(string.sub(value, 1, 1), bg, fg)
  term.write(string.sub(value, 2, -1))
end
local function rightAlign(value, row, col)
  local length = #(tostring(val))
  term.setCursorPos(col + 1 - #(tostring(value)), row)
  term.write(value)
end
return {
  initial = initial,
  out = out,
  rightAlign = rightAlign
}
