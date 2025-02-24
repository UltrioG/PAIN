local Object = require("Object")
local Resource = require("Resource")

---An abstract representation of a *single* inventory of items, fluids and/or energy.
---@class Inventory: Object
---@field name string A unique identifier for the inventory. If this repeats with another inventory, things WILL go wrong.
---@field displayName string A human-readable identifier for the inventory. Can repeat with other inventories, but is advised not.
---@field peripheralName string? The peripheral this inventory ought to bind to.
---@field peripheral InventoryPeripheralWrapped? The wrapped inventory peripheral.
---@field itemSlots list<Resource> The various slots for items in the inventory.
---@field fluidSlots list<Resource> The various tanks for fluids in the inventory.
---@field boundEvents dictionary<fun(): integer>
local Inventory = Object:extend()

---Initializes an inventory
---@param name string A unique identifier for the inventory. If this repeats with another inventory, things WILL go wrong.
---@param displayName string A human-readable identifier for the inventory. Can repeat with other inventories, but is advised not.
---@param peripheralName string? The peripheral this inventory ought to bind to.
function Inventory:init(name, displayName, peripheralName)
	self.name = assert(name, "No name provided for inventory initialization!")
	self.displayName = displayName or name
	self.itemSlots = {}
	self.fluidSlots = {}
	self.peripheralName = peripheralName or ""
	if peripheralName then self:bindToInventory(peripheralName) end
end

---Binds this inventory to a given peripheral.\
---Does not update its internal states. For that, use `Inventory:scanInventoryAsync()`.
---@param inventoryPeripheral string The peripheral name to bind to
---@return InventoryPeripheralWrapped
function Inventory:bindToInventory(inventoryPeripheral)
	self.peripheralName = inventoryPeripheral
	self.peripheral = peripheral.wrap(self.peripheralName)
	return self.peripheral
end

---Checks whether the inventory has a peripheral.\
---@return boolean
function Inventory:hasPeripheral()
	return not not self.peripheral
end

--#region Inventory sorting methods

---# Internal function.
---Creates a function for each slot of the inventory\
---Each function will update the slot of the inventory to the corresponding resource.\
---@param toRun list<function>
function Inventory:__createItemRegisterFunctions(toRun)
	if not self:hasPeripheral() then error("No peripheral attached to inventory!") end
	local size = self.peripheral.size()
	for i = 1, size do
		local function addResourceToList()
			local details = self.peripheral.getItemDetail(i)
			-- TODO: Finish this
			---@type Resource
			---@diagnostic disable-next-line
			local newResource = Resource:new("item", details.name, nil, details.count, details.tags, details)
			self.itemSlots[i] = newResource
		end
		table.insert(toRun, addResourceToList)
	end
end

---# UNFINISHED
---Scans the currently bound inventory and updates the internal slots cache.
---@async
function Inventory:scanInventoryAsync()
	if not self:hasPeripheral() then error("No peripheral attached to inventory!") end

	---@type InventoryPeripheralWrapped
	---@type Flags
	local inventoryTypes = {}

	if self.peripheral["list"] then inventoryTypes.item = true end
	if self.peripheral["tanks"] then inventoryTypes.fluid = true end
	if self.peripheral["getEnergy"] then inventoryTypes.fluid = true end
	
	local toRun = {}
	if inventoryTypes.item then self:__createItemRegisterFunctions(toRun) end
	parallel.waitForAll(table.unpack(toRun))
	return true
end

---Gets a list of slots as well as how many items are allowed to be inserted.
---@param itemCount count How many items to allocate for
---@param itemAllowedToStack Resource? Which item, if any, to allow stacking within.
---@return slotList slotSpace
function Inventory:getFreeItemSlots(itemCount, itemAllowedToStack)
	local inventorySize = self.peripheral.size()
	local freeSlots = {}
	for i = 1, inventorySize do
		local currentSlotResource = self.itemSlots[i]
		if not currentSlotResource or (itemAllowedToStack and itemAllowedToStack:isSameResourceAs(currentSlotResource) or false) then
			table.insert(freeSlots, {i, self.peripheral.getItemLimit(i) - (currentSlotResource and currentSlotResource.count or 0)})
		end
	end
	return freeSlots
end

---# Internal function.
---Moves some stuff from a slot of this inventory to a slot of otherInventory.
---Does not do any checks, only does what it's told
---@param otherInventory Inventory
---@param fromSlot integer
---@param toSlot integer
---@param count integer
function Inventory:__moveSlotToSlotInOtherInventory(otherInventory, fromSlot, toSlot, count)
	self.itemSlots[fromSlot].count = self.itemSlots[fromSlot].count - count
	self.peripheral.pushItems(otherInventory.peripheralName, fromSlot, count, toSlot)
	otherInventory.itemSlots[toSlot].count = otherInventory.itemSlots[toSlot].count + count
end

---# Internal function.
---Gets the slots from which the inventory may pull an items.\
---Returns "Not enough" if there is not enough of the item.
---@param itemResource Resource
---@return slotList | "Not enough"
function Inventory:__getSlotsForAllottedItems(itemResource)
	---@type slotList
	local slots = {}
	local count = itemResource.count
	for i = 1, self.peripheral.size() do
		local slot = self.itemSlots[i]
		if itemResource:isSameResourceAs(slot) then
			if count > slot.count then
				count = count - slot.count
				table.insert(slots, {i, slot.count})
			else
				table.insert(slots, {i, count})
				count = 0
			end
		end
	end
	if count > 0 then return "Not enough" else return slots --[[@as slotList]] end
end

---Moves item from this inventory to the targetInventory.
---@param Resource Resource
---@param targetInventory Inventory
function Inventory:moveItems(Resource, targetInventory)
	local targetSlots = targetInventory:getFreeItemSlots(Resource.count, Resource)
	local sourceSlots = self:__getSlotsForAllottedItems(Resource)
	if sourceSlots == "Not enough" then print("Item insufficient in inventory < "..self.displayName.." >.") return end
	local sourceSlots = sourceSlots --[[@as slotList]]
	local slotI = 1
	for targetSlot, count in pairs(targetSlots) do
		self:__moveSlotToSlotInOtherInventory(targetInventory, sourceSlots[slotI], targetSlot, count)
		if sourceSlots[slotI].count == 0 then slotI = slotI + 1 end
	end
end

--#endregion Inventory sorting methods
--#region Event binding method

---@alias InventoryCallbackEvents
---	| "itemAdded"
---	| "itemRemoved"
---	| "fluidAdded"
--- | "fluidRemoved"
--- | "resourceAdded"
--- | "resourceRemoved"


function Inventory:bindToInventoryEvent(event, callback)
	
end

--#endregion Event binding method

return Inventory