--1
local function filter(tbl, f)
  if tbl == nil then return nil end
  if f == nil then return {} end
  local t = {}
  for k,v in pairs(tbl) do 
    if f(v,k,tbl) then t[#t+1] = v end
  end
  return t
end
local function find(tbl, f)
  if tbl == nil then return nil end
  if f == nil then return nil end
  for k,v in pairs(tbl) do
    if f(v,k,tbl) then return v, k end
  end
  return nil
end
local function map(tbl, f)
  if tbl == nil then return nil end
  if f == nil then return tbl end
  local t = {}
  for k,v in pairs(tbl) do
    t[k] = f(v,k,tbl)
  end
  return t
end
local function reduce(tbl, f, initial)
  if tbl == nil then return nil end
  if f == nil then return tbl end
  local result
  local startIndex = 1
  if initial then
    result = initial
  else
    result = tbl[1]
    startIndex = 2
  end
  for i = startIndex,#tbl do
    result = f(result, tbl[i], i, tbl)
  end
  return result
end

return {
  filter = filter,
  find = find,
  map = map,
  reduce = reduce
}