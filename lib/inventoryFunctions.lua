---@alias peripheral table
---@enum storageType
local storageType = { item = 0, fluid = 1, energy = 2 }
---@enum requestStatus
local requestStatus = { queued = 0, processing = 1, sending = 2, complete = 3, outOfStock = 4, denied = 5, failed = 6 }
---@alias resource {name: string, displayName: string, type: storageType, count: integer, tag: string}
---@alias container {containerName: string, inventoryTypes: table<storageType, true>, inventoryPeripheralName: string}
---@alias request {requested: resource[], status: requestStatus, targetInventory: StorageGroup}

---A collection of containers (inventories, tanks, and batteries), as well as the methods to act upon those inventories.
---@class StorageGroup
---@field name string A unique identifier of the StorageGroup.
---@field displayName string A human-readable identifier of the Storage Group.
---@field stock resource[]
---@field linkedInventories container[]
---@field requestQueue request[]
---@field errorQueue {logTime: string, request: request}[]
local StorageGroup = {
	stock = {},
	linkedInventories = {},
	inventoryEnum = {},
	requestQueue = {},
	errorQueue = {}
}

---Creates a StorageGroup with given name.
---@param name string A name to identify the storage group.
---@param displayName string? A name to show any users.
---@return StorageGroup new A new StorageGroup ready for use.
function StorageGroup:new(name, displayName)
	local name = assert(name, "No name provided while instantiating StorageGroup!")
	local displayName = displayName or name
	---@type StorageGroup
	local new = {
		name = name,
		displayName = displayName,
		stock = {},
		linkedInventories = {},
		requestQueue = {},
		errorQueue = {}
	}
	setmetatable(new, { __index = self })
	return new
end

---Adds a container to this inventory group.\
---Note the order inventories are added might affect some iteration functions.
---@param containerName string?	What name the container should have. Defaults to its item name with a number attached.
---@param inventoryTypes table<storageType, true>	What types of resources this container holds. e.g. `{storageType.item, storageType.fluid}`
---@param inventoryPeripheralName string	The name of the peripheral of the inventory.
---@return StorageGroup self
function StorageGroup:AddContainer(containerName, inventoryTypes, inventoryPeripheralName)
	self.linkedInventories[#self.linkedInventories + 1] = {
		containerName = containerName,
		inventoryTypes = inventoryTypes,
		inventoryPeripheralName = inventoryPeripheralName
	}
	self.inventoryEnum[containerName] = #self.linkedInventories
	for _, resource in pairs(self:CountContainerStock(containerName)) do
		local found = false
		for _, itemStock in ipairs(self.stock) do
			if itemStock.name == resource.name and itemStock.type == resource.type and itemStock.tag == resource.tag then
				itemStock.count = itemStock.count + resource.count
				found = true
			end
		end
		if not found then
			table.insert(self.stock, resource)
		end
	end
	os.queueEvent("inventory_updated", self.name)
	return self
end

---Gets a container from the container name.
---@param containerName string
---@return container
---Throws if the container cannot be accessed or is not part of this container group.
function StorageGroup:GetContainer(containerName)
	return assert(
		self.linkedInventories[assert(
			self.inventoryEnum[assert(
				containerName,
				"No container name provided while trying to search for container!"
			)],
			("Container %s is not registered in the inventory enum of StorageGroup %s!"):format(containerName, self.name)
		)],
		("Container %s is not a part of StorageGroup %s!"):format(containerName, self.name)
	)
end

---Gets a container peripheral from the container name.
---@param containerName string
---@return peripheral
---Throws if the container cannot be accessed or is not part of this container group.
function StorageGroup:GetContainerPeripheral(containerName)
	return assert(
		peripheral.wrap(self:GetContainer(containerName).inventoryPeripheralName),
		("Peripheral error while trying to bind to peripheral %s."):format(self.linkedInventories
		[self.inventoryEnum[containerName]].inventoryPeripheralName)
	)
end

---Get the count of a specific item in the inventory
---@param itemname string
---@return integer
function StorageGroup:GetItemCount(itemname)
	for _, v in pairs(self.stock) do if v.name == itemname then return v.count end end
	return 0
end

---Tally the contents of a container.
---@param containerName string
---@return resource[]
function StorageGroup:CountContainerStock(containerName)
	if self.requestQueue[1] and self.requestQueue[1].status == requestStatus.processing then
		error("Stocks cannot be recounted during request processing.")
	end
	local inventoryLookup = {}
	---@type resource[]
	local resourceStock = {}
	local container = self:GetContainer(containerName)
	local containerPeripheral = self:GetContainerPeripheral(containerName)
	if container.inventoryTypes[storageType.item] then
		local slots = containerPeripheral.list()
		local toRun = {}
		for i = 1, containerPeripheral.size() do
			if slots[i] then
				table.insert(toRun, function()
					local key = slots[i].name .. (slots[i].nbt or "")
					if not inventoryLookup[key] then
						inventoryLookup[key] = #resourceStock + 1
						resourceStock[inventoryLookup[key]] = {}
						resourceStock[inventoryLookup[key]].name = slots[i].name
						resourceStock[inventoryLookup[key]].type = storageType.item
						resourceStock[inventoryLookup[key]].count = 0
						resourceStock[inventoryLookup[key]].tag = slots[i].nbt or ""
						resourceStock[inventoryLookup[key]].displayName = containerPeripheral.getItemDetail(i).displayName or "DISPERR"
					end
					-- print(key, inventoryLookup[key], textutils.serialise(resourceStock))
					resourceStock[inventoryLookup[key]].count = resourceStock[inventoryLookup[key]].count + slots[i].count
				end)
			end
		end
		parallel.waitForAll(table.unpack(toRun))
	end
	if container.inventoryTypes[storageType.fluid] then
		local maxTank = 0
		local tanks = containerPeripheral.tanks()
		for i, _ in pairs(tanks) do
			maxTank = math.max(i, maxTank)
		end
		local toRun = {}
		for i = 1, maxTank do
			table.insert(toRun, function()
				local key = tanks[i].name .. (tanks[i].tag or "")
				if not inventoryLookup[key] then
					inventoryLookup[key] = #resourceStock
					resourceStock[inventoryLookup[key]] = {
						name = key,
						displayName = name:match(":(.+)$"),
						type = storageType.fluid,
						count = 0,
						tag = tanks[i].tag or ""
					}
				end
				resourceStock[inventoryLookup[key]].count = resourceStock[inventoryLookup[key]].count + tanks[i].amount
			end)
		end
		parallel.waitForAll(table.unpack(toRun))
	end
	if container.inventoryTypes[storageType.energy] then
		if not inventoryLookup["FE"] then inventoryLookup["FE"] = 0 end
		inventoryLookup["FE"] = inventoryLookup["FE"] + containerPeripheral.getEnergy()
	end
	return resourceStock
end

---Tally the size of a container.
---@param containerName string
---@return { itemCapacity: integer, fluidCapacity: integer, energyCapacity: integer }
function StorageGroup:CountContainerSize(containerName)
	local itemCapacity = 0
	local fluidCapacity = 0
	local energyCapacity = 0
	local container = self:GetContainer(containerName)
	local containerPeripheral = self:GetContainerPeripheral(containerName)
	if container.inventoryTypes[storageType.item] then
		local toRun = {}
		for i = 1, containerPeripheral.size() do
			toRun[i] = function()
				itemCapacity = itemCapacity + containerPeripheral.getItemDetail(i).maxCount
			end
		end
		parallel.waitForAll(table.unpack(toRun))
	end
	if container.inventoryTypes[storageType.fluid] then
		local toRun = {}
		for _, v in pairs(containerPeripheral.tanks()) do
			table.insert(toRun, function()
				fluidCapacity = fluidCapacity + v.getInfo().capacity
			end)
		end
		parallel.waitForAll(table.unpack(toRun))
	end
	if container.inventoryTypes[storageType.energy] then
		energyCapacity = energyCapacity + containerPeripheral.getEnergyCapacity()
	end
	return { itemCapacity = itemCapacity, fluidCapacity = fluidCapacity, energyCapacity = energyCapacity }
end

---Tally the total contents of the storage
---@return resource[]
function StorageGroup:CountStorageStock()
	---@type resource[]
	local newStock = {}
	for _, container in ipairs(self.linkedInventories) do
		for index, resource in ipairs(self:CountContainerStock(container.containerName)) do
			if not newStock[index] then newStock[index] = {
				name = resource.name,
				displayName = resource.displayName,
				tag = resource.tag,
				count = 0,
				type = resource.type
			} end
			newStock[index].count = newStock[index].count + resource.count
		end
	end
	return newStock
end

---Tally the total size of the storage
---@return { itemCapacity: integer, fluidCapacity: integer, energyCapacity: integer }
function StorageGroup:CountStorageSize()
	local newSize = { itemCapacity = 0, fluidCapacity = 0, energyCapacity = 0 }
	for _, container in ipairs(self.linkedInventories) do
		local capacity = self:CountContainerSize(container.containerName)
		newSize.itemCapacity = newSize.itemCapacity + capacity.itemCapacity
		newSize.fluidCapacity = newSize.fluidCapacity + capacity.fluidCapacity
		newSize.energyCapacity = newSize.energyCapacity + capacity.energyCapacity
	end
	return newSize
end

---Recount the stock of the StorageGroup to be accurate
---@return StorageGroup self
function StorageGroup:RecountStock()
	if self.requestQueue[1] and self.requestQueue[1].status == requestStatus.processing then
		warn("Stocks cannot be recounted during request processing.")
		return self
	end
	self.stock = self:CountStorageStock()
	return self
end

---Request a delivery to another inventory.
---@param request resource[] What to get
---@param targetInventory StorageGroup Which storage group to send it to
---@return request
function StorageGroup:RequestDelivery(request, targetInventory)
	local req = {
		requested = request,
		targetInventory = targetInventory,
		status = requestStatus.queued
	}
	table.insert(self.requestQueue, req)
	return req
end

---Gets a free slot from the entire inventory, blacklisting a given resource.
---@param inventoryType storageType What type of free slot will be needed
---@param blacklist string? Which resource name to blacklist
---@return {inventoryName: string, slot: integer, availableSpace: integer}?
function StorageGroup:GetFreeSlot(inventoryType, blacklist, minimumSpace)
	local minimumSpace = minimumSpace or 1
	for _, inventory in ipairs(self.linkedInventories) do
		local correct = inventory.inventoryTypes[inventoryType]
		if correct then
			local I = peripheral.wrap(inventory.inventoryPeripheralName)
			if inventoryType == storageType.item then
				local minimumFoundSlot = math.huge
				local toRun = {}
				for i = 1, I.size() do
					table.insert(toRun,function()
						local slot = I.getItemDetail(i)
						if (not slot) or ((slot.name == blacklist) and (slot.maxCount - slot.count >= minimumSpace)) then
							if minimumFoundSlot > i then minimumFoundSlot = i end
						end
					end)
				end
				parallel.waitForAll(table.unpack(toRun))
				if minimumFoundSlot == math.huge then minimumFoundSlot = 1 end
				local detail = I.getItemDetail(minimumFoundSlot)
				return {
					inventoryName = inventory.inventoryPeripheralName,
					slot = minimumFoundSlot,
					availableSpace = detail and (detail.maxCount - detail.count) or I.getItemLimit(minimumFoundSlot)
				}
			end
			if inventoryType == storageType.fluid then
				local minimumFoundSlot = math.huge
				for slotCount, slot in pairs(I.tanks()) do
					if (not slot) or slot.name == blacklist then
						if minimumFoundSlot > slotCount then minimumFoundSlot = slotCount end
					end
				end
				return {
					inventoryName = inventory.inventoryPeripheralName,
					slot = minimumFoundSlot
				}
			end
		end
	end
	return nil
end

---Complete a delivery. Is to be used in an update function.
---@return self
function StorageGroup:ProcessDelivery()
	local request = self.requestQueue[1]
	if not request then return self end
	-- Error processing/Request waiting
	if request.status ~= requestStatus.queued then
		if request.status == requestStatus.complete then
			table.remove(self.requestQueue, 1)
		elseif
			request.status == requestStatus.outOfStock
			or request.status == requestStatus.failed
			or request.status == requestStatus.denied
		then
			table.remove(self.requestQueue, 1)
			table.insert(self.errorQueue, { logTime = os.date(), request = request })
			if #self.errorQueue > 12 then table.remove(self.errorQueue, 1) end
		end
		return self
	end

	--#region Actual processing
	request.status = requestStatus.processing

	-- 1. Check if can
	for _, requestedResource in ipairs(request.requested) do
		if self:GetItemCount(requestedResource.name) < requestedResource.count then
			request.status = requestStatus.outOfStock
			return self
		end
	end

	-- 2. Allocate
	---@type {inventory: string, slot: integer, count: integer, type: storageType, currentOccupant: string}[]
	local inventorySlotToTakeFrom = {}
	for _, requestedResource in ipairs(request.requested) do
		-- print(("%s: To deliver: %s x %i (tag: '%s')"):format(self.displayName, requestedResource.name, requestedResource.count, requestedResource.tag))
		if request.status == requestStatus.denied then break end
		for _, stockedResource in ipairs(self.stock) do
			if request.status == requestStatus.denied then break end
			if stockedResource.name == requestedResource.name then
				stockedResource.count = stockedResource.count - requestedResource.count
				local toTake = requestedResource.count
				for _, inventory in ipairs(self.linkedInventories) do
					local isRightType = inventory.inventoryTypes[requestedResource.type]
					if isRightType then
						local inventoryPeripheral = peripheral.wrap(inventory.inventoryPeripheralName)
						if requestedResource.type == storageType.item then
							for slotCount, slot in pairs(inventoryPeripheral.list()) do
								if slot and slot.name .. (slot.nbt or "") == requestedResource.name then
									local details = inventoryPeripheral.getItemDetail(slotCount)
									local taking = math.min(details.maxCount, toTake, slot.count)
									table.insert(inventorySlotToTakeFrom, {
										inventory = inventory.inventoryPeripheralName,
										slot = slotCount,
										count = taking,
										type = storageType.item,
										currentOccupant = requestedResource.name
									})
									toTake = toTake - taking
								end
								if toTake == 0 then break end
							end
						end
						if requestedResource.type == storageType.fluid then
							for tankCount, tank in pairs(inventoryPeripheral.tanks()) do
								if tank.name == requestedResource.name then
									table.insert(inventorySlotToTakeFrom, {
										inventory = inventory.inventoryPeripheralName,
										slot = tankCount,
										count = math.min(inventoryPeripheral.getInfo().capacity, toTake),
										type = storageType.fluid,
										currentOccupant = requestedResource.name
									})
								end
							end
						end
						if requestedResource.type == storageType.energy then
							request.status = requestStatus.denied
							break
						end
					end
				end
			end
		end
	end
	
	if request.status == requestStatus.denied then
		print("Denied")
		return self
	end

	-- 3. Move
	for _, v in ipairs(inventorySlotToTakeFrom) do
		local inventoryPeripheral = peripheral.wrap(v.inventory)
		local moved = 0
		local lastMoved = 0
		repeat
			local freeSlot = request.targetInventory:GetFreeSlot(v.type, v.currentOccupant)
			lastMoved = moved
			if not freeSlot then
				request.status = requestStatus.failed
				break
			end
			if v.type == storageType.item then
				moved = moved + inventoryPeripheral.pushItems(freeSlot.inventoryName, v.slot, v.count, freeSlot.slot)
			end
			if v.type == storageType.fluid then
				moved = moved + inventoryPeripheral.pushFluid(freeSlot.inventoryName, v.count, v.currentOccupant)
			end
		until moved == lastMoved or moved == v.count
	end

	request.status = requestStatus.complete
	--#endregion Actual processing

	self:RecountStock()
	os.queueEvent("inventory_updated", self.name)
	return self
end

---REMEMBER TO CALL THE RETURN VALUE
return function() return StorageGroup, storageType, requestStatus end