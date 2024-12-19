local flags = {}
local args = {}
for _, v in ipairs(arg) do
	if v:match("^%-") then flags[v] = true else table.insert(args, v) end
end

local types = {}
if flags["-i"] or flags["--item"] then types[0] = true end
if flags["-f"] or flags["--fluid"] then types[1] = true end
if flags["-e"] or flags["--energy"] then types[2] = true end

os.queueEvent("PAINServerAddMainInventory", args[1], types)