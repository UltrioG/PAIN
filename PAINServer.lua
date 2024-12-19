local INV, storageType, requestStatus = (require "lib.inventoryFunctions")()
local mainInventory = INV:new("main", "Main inventory")

print("Initiating...")
local logs, errmsg = io.open(("/logs/%s"):format(os.date("%S-%M-%H-%d-%m-%Y")), "w")
if errmsg then
	print(("LOGFAIL:\n%s\nBREAKING"):format(errmsg))
	return
end
io.output(logs)
local function printl(x)
	print(x)
	io.write(tostring(x).."\n")
end
if not term.isColor() then
	printl("Computer is not advanced. Breaking...")
	return
end

local registeredComputerOutputInventories = {

}

local registeredInputInventories = {

}

local registeredUITerminals = {

}

local oldShellPath = shell.path()
shell.setPath("/serverCLIPrograms")

term.write("Initiation complete!\nRefer to logs for more info.")

local eventCallbacks = {
	PAINServerAddMainInventory = function (invType, invPeripheral)
		mainInventory:AddContainer(nil, invType, invPeripheral)
	end
}

peripheral.find("modem", rednet.open)

local breakFlag = false
while not breakFlag do
	parallel.waitForAny(
		function()
			local EVENT = {os.pullEvent()}
			local event = EVENT[1]
			local args = {} if #EVENT > 1 then for i = 2, #EVENT do args[i-1] = EVENT[i] end end
			if event == "PAINServerShutdown" then breakFlag = true end
			for e, f in pairs(eventCallbacks) do if e == event then f(table.unpack(args)) break end end
		end,
		function ()
			local redMsg = rednet.receive("PAIN")
		end
	)
end
shell.setPath(oldShellPath)


