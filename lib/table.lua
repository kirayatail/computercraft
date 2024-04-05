--3
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
local function indexOf(tbl, val)
  local index = {}
  for k,v in pairs(tbl) do
      index[v] = k
  end
  return index[val] or -1
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
local function push(tbl, item)
  if tbl == nil then return nil end
  tbl[#tbl + 1] = item
  return tbl
end
local function some(tbl, predicate)
  for k,v in pairs(tbl) do
    if predicate(v, k) then
      return true
    end
  end
  return false;
end
local function every(tbl, predicate)
  for k,v in pairs(tbl) do
    if predicate(v,k) == false then
      return false
    end
  end
  return true
end
return {
  filter = filter,
  find = find,
  indexOf = indexOf,
  map = map,
  reduce = reduce,
  push = push,
  some = some,
  every = every
}