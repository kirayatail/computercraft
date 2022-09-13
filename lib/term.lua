--1
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
  term.blit(string.sub(value, 1,1), bg, fg)
  term.write(string.sub(value, 2,-1))
end
return {
  initial = initial,
  out = out
}