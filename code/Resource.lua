local common = require("common")
local Object = require("Object")

---@class Resource: Object
---@field resourceName string The name of the resource. DOES NOT CONTAIN THE MODNAME.
---@field resourceType ResourceType
---@field resourceMod string | "minecraft" The mod of the resource.
---@field count integer The quantity of the resource. For items, item count. For fluids, milibuckets. For energy, FE.
---@field nbtHash string The nbt hash of the resource, if any.
---@field details table<string, any> The detailed data of the resource. Includes the above information as well.
---A class that represents an item, fluid, or energy.
local Resource = Object:extend(function (class)
	---Defines the resource.
	---@param type ResourceType The type of resource which is defined.
	---@param name string The name of the resource. DOES NOT CONTAIN THE MODNAME.
	---@param mod string | "minecraft" The mod of the resource.
	---@param count integer
	---@param nbtHash any
	---@param details any
	function class:init(type, name, mod, count, nbtHash, details)
		local type = type or "null"
		self.resourceType = type or "null"
		if type == "null" then return end
		self.resourceName = assert(name, "No name for the given resource given!")
		self.resourceMod = mod or "minecraft" if not mod then warn("No mod name given for resource initialization. Defaulting to minecraft.") end
		self.count = count or 0
		self.nbtHash = nbtHash or ""
		self.details = details or {}
	end

	---@alias sameResourceSetting
	---|"t" t for same Tag allowed
	---|"d" d for same durability

	---Checks whether two resources are the same.<br>
	---Example of checking whether an item in a drawer is iron:
	---```
	---local iron = Resource:new("item", "iron", "minecraft")
	---local item = Drawer1[1]
	---
	---if item:isSameResourceAs(iron) then Drawer:moveSlot(1, Drawer2) end
	---```
	---Settings:<br>
	---- "t" for same Tag allowed
	---- "d" for same durability
	---- "n" for different nbts allowed
	---@param other Resource
	---@param setting list<sameResourceSetting>
	---@return boolean
	function class:isSameResourceAs(other, setting)
		if other.resourceType ~= self.resourceType then return false end
		if common.hasValue(setting, "t") then
			-- Check tags
			local cont = true
			if cont and common.dictEmpty(self.details)		 	then cont = false end
			if cont and not self.details.tags				 	then cont = false end
			if cont and common.dictEmpty(self.details.tags)	 	then cont = false end
			if cont and common.dictEmpty(other.details)		 	then cont = false end
			if cont and not other.details.tags				 	then cont = false end
			if cont and common.dictEmpty(other.details.tags) 	then cont = false end
			if cont then
				local cotag = false
				for _, tag in pairs(self.details.tags) do
					cotag = cotag or common.hasValue(other.details.tags, tag)
				end
				if not cotag then return false end
			end
		else
			-- Check whether mod and item is the same
			if other.resourceName ~= self.resourceName then return false end
			if other.resourceMod ~= self.resourceMod then return false end
		end
		if common.hasValue(setting, "d") then warn("Sorry! Unimplemented at the moment.") end
		if not common.hasValue(setting, "n") and self.nbtHash ~= other.nbtHash then return false end
		return true
	end

	---Checks whether this resource has a certain tag.
	---@param tag string The tag to check for
	---@return boolean
	function class:hasTag(tag)
		if common.dictEmpty(self.details)		 	then return false end
		if not self.details.tags				 	then return false end
		if common.dictEmpty(self.details.tags)	 	then return false end
		return common.hasValue(self.details.tags, tag)
	end
end)

return Resource