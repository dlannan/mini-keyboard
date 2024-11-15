-- usage: lua luac.lua [file.lua]* [-L [module.lua]*]
--
-- creates a precompiled chunk that preloads all modules listed after
-- -L and then runs all programs listed before -L.
--
-- assumptions:
--	file xxx.lua contains module xxx
--	'/' is the directory separator (could have used package.config)
--	int and size_t take 4 bytes (could have read sizes from header)
--	does not honor package.path
--
-- Luiz Henrique de Figueiredo <lhf@tecgraf.puc-rio.br>
-- Tue Aug  5 22:57:33 BRT 2008
-- This code is hereby placed in the public domain.
--
-- This has been hevily midified to utilize a different method to concatenate the 
-- chunks without losing the package module mapping.
-- ref: https://www.lua-users.org/wiki/LuaCompilerInLua

-- Load a chunk manually so we can name it
local function loader(filepath)
  local data = ""
  local fh = io.open(filepath, "r")
  if(fh) then 
    data = fh:read("*a")
    fh:close() 
  end 
  return data 
end

local MARK="////////"
local NAME="luac"

local OUTPUT=NAME..".out"
NAME="=("..NAME..")"

local n=#arg
local m=n
local b

for i=1,n do
	if arg[i]=="-L" then m=i-1 break end
end
if m+2<=n then b="local t=package.preload;\n" else b="local t;\n" end

local ts = {}
table.insert(ts, 1, "local t=package.preload;")

for i=m+2,n do
  local modulename = string.gsub(arg[i], "^%.[/\\]", "")
  modulename = string.gsub(modulename, "[/\\]", "%.")
  modulename = string.gsub(modulename, "%.lua", "")
  b=b..string.format("t['%s']=function()end;\n",modulename)
  local loaded = load(loader(arg[i]), modulename)
  
  local loaded_chunk = assert(load( loader(arg[i]),modulename ))
  table.insert(ts, ("t['%s']=load(%q);"):format(modulename, string.dump(loaded_chunk)) )
end
b=b.."t='"..MARK.."';\n"

for i=1,m do
	b=b.."(function()end)();\n"
  table.insert(ts, ("load(%q)(...);"):format(string.dump(assert(loadfile(arg[i])))) )
end

local chunks = assert(load(table.concat(ts)))

local f=assert(io.open(OUTPUT,"wb"))
local data = string.dump(chunks)
f:write(data)
assert(f:close())