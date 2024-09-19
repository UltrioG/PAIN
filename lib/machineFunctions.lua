---@alias recipe {name: string, displayName: string, inputMaterials: resource[], outputMaterials: resource[]}
---@alias craftingRequest {recipeName: string, status: requestStatus, batchCount: integer, timeout: number}
local _, _, requestStatus = require("lib.inventoryFunctions")()

local common = require("lib.common")

---@class CraftingNetworkEdge
---@field name string	A unique name for this craftingNetworkEdge.
---@field displayName string	A human readable name for this craftingNetworkEdge. Can repeat.
---@field machineDisplayName string	A human readable name for the machine this edge drives.
---@field sourceInventory StorageGroup	The inventory wherefrom items are pulled from.
---@field inputInventory StorageGroup	The inventory which acts as the input for the physical system of processing.
---@field outputInventory StorageGroup	The inventory which acts as the output for the physical system of processing. Crafting signal ends when outputInventory has enough output.
---@field craftingSignal boolean	Whether the machine is crafting.
---@field craftingSignalRedstoneIndicator peripheral	The peripheral of the redstone integrator which controls whether the machine is crafting.
---@field learntRecipes	recipe[]	The list of recipes this craftingNetworkEdge can make
---@field craftingRequestQueue craftingRequest[]	A list of queued crafting requests.
---@field craftingErrorQueue craftingRequest[]	A list of crafting requests which failed for whatever reason.
local craftingNetworkEdge = {}

---Creates a new craftingNetworkEdge
---@param name string The unique identifier for the machine.
---@param sourceInventory StorageGroup The inventory to pull for materials
---@param inputInventory StorageGroup The input of the machine. Used by 
---@param outputInventory StorageGroup outputInventory
---@param indicator peripheral The computer which dictates whether 
---@param machineDisplayName string What to call the machine this craftingNetworkEdge drives
---@return CraftingNetworkEdge new	The resultant craftingNetworkEdge.
function craftingNetworkEdge:new(name, displayName, sourceInventory, inputInventory, outputInventory, indicator, machineDisplayName)
	---@type CraftingNetworkEdge
	local new = {
		name = name,
		displayName = displayName or machineDisplayName,
		sourceInventory = sourceInventory,
		inputInventory = inputInventory,
		outputInventory = outputInventory,
		craftingSignal = false,
		craftingSignalRedstoneIndicator = indicator,
		machineDisplayName = machineDisplayName,
		learntRecipes = {},
		craftingRequestQueue = {},
		craftingErrorQueue = {}
	}
	setmetatable(new, {__index = self})
	return new
end

---Teach this edge a new recipe. Remember to include leftover materials as well!
---@param name string	A unique name to identify the recipe.
---@param displayName string	A name to call the recipe by. not necessarily unique.
---@param input resource[]		The inputs to the recipe, in order.
---@param output resource[]		The outputs to the recipe. Crafting stops when the output inventory has all of these resources.
function craftingNetworkEdge:LearnRecipe(name, displayName, input, output)
	table.insert(self.learntRecipes, {name = name, displayName = displayName or name, inputMaterials = input, outputMaterials = output})
end

---Get all recipe names with a resource in the output, in learnt order.
---@param target resource
---@return string[]
function craftingNetworkEdge:GetRecipesForResource(target)
	---@type string[]
	local recipeNames = {}
	for _, v in ipairs(self.learntRecipes) do
		for _, resultant in ipairs(v.outputMaterials) do
			if resultant.name == target.name and resultant.tag == target.tag then table.insert(recipeNames, v.name) break end
		end
	end
	return recipeNames
end

---Queue a given recipe.
---@param recipeName string	The name of the recipe to craft.
---@param batchCount integer	How many batches to craft. Defaults to one.
---@param timeout number?	How long to wait until giving up on the recipe.
---@return craftingRequest
function craftingNetworkEdge:QueueRecipe(recipeName, batchCount, timeout)
	local request = {
		recipeName = recipeName,
		status = requestStatus.queued,
		batchCount = batchCount or 1,
		timeout = timeout or math.huge
	}
	table.insert(self.craftingRequestQueue, request)
	return request
end

---Finds a recipe.
---@param recipeName string
---@return recipe?
function craftingNetworkEdge:GetRecipe(recipeName)
	for _, v in ipairs(self.learntRecipes) do
		if v.name == recipeName then return v end
	end
	return nil
end

---To be thrown into an update function. Processes craftingRequests.
function craftingNetworkEdge:ProcessCrafts()
	if next(self.outputInventory.stock) then
		warn("Cannot process craft when output inventory is not clear.")
		return self
	end
	local request = self.craftingRequestQueue[1]
	if not request then return end
	-- Error processing/Request waiting
	if request.status ~= requestStatus.queued then
		if request.status == requestStatus.complete then
			table.remove(self.craftingRequestQueue, 1)
		elseif
			request.status == requestStatus.outOfStock
			or request.status == requestStatus.failed
			or request.status == requestStatus.denied
		then
			table.remove(self.craftingRequestQueue, 1)
			table.insert(self.craftingErrorQueue, { logTime = os.date(), request = request })
			if #self.craftingErrorQueue > 12 then table.remove(self.craftingErrorQueue, 1) end
		elseif request.status == requestStatus.processing then

		end
		return
	end
	self.craftingSignal = false
	self.craftingSignalRedstoneIndicator.setOutput("top", false)
	self.craftingSignalRedstoneIndicator.setOutput("bottom", false)
	self.craftingSignalRedstoneIndicator.setOutput("left", false)
	self.craftingSignalRedstoneIndicator.setOutput("right", false)
	self.craftingSignalRedstoneIndicator.setOutput("front", false)
	self.craftingSignalRedstoneIndicator.setOutput("back", false)
	request.status = requestStatus.processing
	local recipe = self:GetRecipe(request.recipeName)
	if not self.sourceInventory then request.status = requestStatus.denied return end
	if not self.inputInventory then request.status = requestStatus.denied return end
	if not self.outputInventory then request.status = requestStatus.denied return end
	if not self.craftingSignalRedstoneIndicator then request.status = requestStatus.denied return end
	if not recipe then request.status = requestStatus.denied return end
	local inputNeeded = recipe.inputMaterials
	local outputNeeded = recipe.outputMaterials
	for _, v in pairs(inputNeeded) do v.count = v.count * request.batchCount end
	for _, v in pairs(outputNeeded) do v.count = v.count * request.batchCount end
	local itemRequest = self.sourceInventory:RequestDelivery(inputNeeded, self.inputInventory)
	repeat os.sleep(1) until itemRequest.status ~= requestStatus.queued and itemRequest.status ~= requestStatus.processing
	if itemRequest.status ~= requestStatus.complete then request.status = requestStatus.failed return end
	self.craftingSignal = true
	self.craftingSignalRedstoneIndicator.setOutput("top", true)
	self.craftingSignalRedstoneIndicator.setOutput("bottom", true)
	self.craftingSignalRedstoneIndicator.setOutput("left", true)
	self.craftingSignalRedstoneIndicator.setOutput("right", true)
	self.craftingSignalRedstoneIndicator.setOutput("front", true)
	self.craftingSignalRedstoneIndicator.setOutput("back", true)
	local startTime = os.clock()
	repeat
		self.outputInventory:RecountStock()
		os.sleep(1)
	until (common.tableSuperShallowEqual(self.outputInventory.stock, outputNeeded)) or (os.clock() - startTime > request.timeout)
	print("CraftingDone")
	self.craftingSignal = false
	self.craftingSignalRedstoneIndicator.setOutput("top", false)
	self.craftingSignalRedstoneIndicator.setOutput("bottom", false)
	self.craftingSignalRedstoneIndicator.setOutput("left", false)
	self.craftingSignalRedstoneIndicator.setOutput("right", false)
	self.craftingSignalRedstoneIndicator.setOutput("front", false)
	self.craftingSignalRedstoneIndicator.setOutput("back", false)
	if not (common.tableSuperShallowEqual(self.outputInventory.stock, outputNeeded)) then request.status = requestStatus.failed return end
	print("Stock is had")
	self.outputInventory:RecountStock()
	local returnRequest = self.outputInventory:RequestDelivery(common.deepCloneTable(self.outputInventory.stock), self.sourceInventory)
	repeat
		self.outputInventory:ProcessDelivery()
		sleep(1)
	until returnRequest.status == requestStatus.complete
	request.status = requestStatus.complete
end

return craftingNetworkEdge