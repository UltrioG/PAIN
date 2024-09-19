local IVUI = require("lib.mainUI")
local IV, storeType, reqStat = require("lib.inventoryFunctions")()
local main = IV:new("Main", "Main Inventory"):AddContainer("chest1", {[storeType.item] = true}, "minecraft:chest_0")
local out = IV:new("Output1", "Output Inventory"):AddContainer("chest2", {[storeType.item] = true}, "minecraft:chest_1")

-- textutils.pagedPrint(textutils.serialise(main.stock))
parallel.waitForAny(
	function ()
		IVUI.matchTermToInventory(term, main, out)
	end,
	function ()
		while true do sleep(1/20)
			main:ProcessDelivery()
		end
	end
)