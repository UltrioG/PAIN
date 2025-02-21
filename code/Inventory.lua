local Object = require("Object")
local Resource = require("Resource")
---@class Inventory: Object
---@field name string A unique identifier for the inventory. If this repeats with another inventory, things WILL go wrong.
---@field displayName string A human-readable identifier for the inventory. Can repeat with other inventories, but is advised not.
---@field peripheralName string? The peripheral this inventory ought to bind to.
---@field peripheral InventoryPeripheralWrapped? The wrapped inventory peripheral.
---@field itemSlots list<Resource> The various slots for items in the inventory.
---@field fluidSlots list<Resource> The various tanks for fluids in the inventory.
local Inventory = Object:extend(function (class)
	---Initializes an inventory
	---@param name string A unique identifier for the inventory. If this repeats with another inventory, things WILL go wrong.
	---@param displayName string A human-readable identifier for the inventory. Can repeat with other inventories, but is advised not.
	---@param peripheralName string? The peripheral this inventory ought to bind to.
	function class:init(name, displayName, peripheralName)
		self.name = assert(name, "No name provided for inventory initialization!")
		self.displayName = displayName or name
		self.slots = {}
		self.peripheralName = peripheralName or ""
		if peripheralName then self:bindToInventory(peripheralName) end
	end

	---Binds this inventory to a given peripheral
	---@param inventoryPeripheral string The peripheral name to bind to
	---@return InventoryPeripheralWrapped
	function class:bindToInventory(inventoryPeripheral)
		self.peripheralName = inventoryPeripheral
		self.peripheral = peripheral.wrap(self.peripheralName)
		return self.peripheral
	end

	---@async
	---Scans the currently bound inventory and updates the internal slots cache.
	function class:scanInventoryAsync()
		---@type InventoryPeripheralWrapped
		local selfPeripheral = self.peripheral
		---@type Flags
		local inventoryTypes = {}

		if selfPeripheral["list"] then inventoryTypes.item = true end
		if selfPeripheral["tanks"] then inventoryTypes.fluid = true end
		if selfPeripheral["getEnergy"] then inventoryTypes.fluid = true end
		
		local toRun = {}
		if inventoryTypes.item then
			local size = selfPeripheral.size()
			for i = 1, size do
				table.insert(toRun, function ()
					local details = selfPeripheral.getItemDetail(i)
					-- TODO: Finish this
					---@type Resource
					---@diagnostic disable-next-line
					local newResource = Resource:new()
				end)
			end
		end
		parallel.waitForAll(table.unpack(toRun))
	end
end)

return Inventory