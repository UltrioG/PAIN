local BASALT = require("lib.Basalt-master.Basalt")

local void = function()end
local module = {}

---@param term any
---@param mainInventory StorageGroup
---@param outputInventory StorageGroup
function module.matchTermToInventory(term, mainInventory, outputInventory)
	local main = BASALT.addFrame():setTheme({FrameBG = colors.black, FrameFG = colors.lightGray})
	local stockDebounce = false
	local inventoryList = {}

	local views = {
		inventory = main:addFrame():setPosition(1, 2):setSize("parent.w", "parent.h - 2"),
		crafting = main:addFrame():setPosition(1, 2):setSize("parent.w", "parent.h - 2"):hide(),
		settings = main:addFrame():setPosition(1, 2):setSize("parent.w", "parent.h - 2"):hide()
	}
	local currentView = "inventory"
	local lastView = "inventory"

	local function switchView(new)
		local success = false
		if new == currentView then
			local cache = currentView
			currentView = lastView
			lastView = cache
		else
			lastView = currentView
			currentView = new
			success = true
		end
		for _, v in pairs(views) do v:hide() end
		views[currentView]:show()
		return success
	end

	--#region Topbar
	local topBar = main:addFrame():setPosition(1,1):setSize("parent.w", 1):setBackground(colors.red)
	topBar:addLabel():setText("PAIN - PAINful Allocative Inventory Network"):setPosition(2,1):setForeground(colors.black)
	topBar:addButton():setPosition("parent.w-1",1):setSize(1,1)	-- Close button
		:setText("x"):setBackground(colors.red):setForeground(colors.white)
		:onClick(function (self)
			self:setBackground(colors.blue):setForeground(colors.black)
		end)
		:onClickUp(function (self)
			os.shutdown()
		end)
	topBar:addButton():setPosition("parent.w-2",1):setSize(1,1)	-- Reboot button
		:setText("R"):setBackground(colors.orange):setForeground(colors.black)
		:onClick(function (self)
			self:setBackground(colors.black):setForeground(colors.red)
		end)
		:onClickUp(function (self)
			os.reboot()
		end)
	topBar:addButton():setPosition("parent.w-3",1):setSize(1,1)	-- Settings button
		:setText(string.char(164)):setBackground(colors.cyan):setForeground(colors.black)
		:onClick(function (self)
			self:setBackground(colors.black):setForeground(colors.red)
		end)
		:onRelease(function (self)
			self
				:setBackground(settingsView and colors.black or colors.cyan)
				:setForeground(settingsView and colors.white or colors.black)
		end)
		:onClickUp(function (self)
			local settingsView = switchView("settings")
		end)
	--#endregion Topbar
	
	local bottomBar = main:addLabel()
		:setBackground(colors.gray):setForeground(colors.white)
		:setSize("parent.w", 1):setPosition(1, "parent.h")
		:setText("Actions done will be displayed here.")
	local function dprint(text) bottomBar:setText(tostring(text)) end

	--#region Inventory View
	local detailedView = false

	local searchBox = views.inventory:addFrame():setSize("parent.w", 3):setPosition(1,"parent.y-1")
	searchBox:setBackground(colors.gray)
	searchBox:addLabel():setSize("parent.w", 1):setPosition(1,"parent.y")
		:setBackground(false):setForeground(colors.white):setText("Search for items")
	searchBox:addButton("RefreshItemListButton")
		:setBackground(false):setForeground(colors.white):setText("Refresh"):setPosition("parent.w - 10", "parent.y"):setSize(9, 1)
		:onClick(function (self)
			self:setBackground(colors.black)
		end)
		:onRelease(function (self)
			self:setBackground(false)
		end)
		:onClickUp(function (self)
			mainInventory:RecountStock()
			updateList()
		end)
	searchBox:addInput():setSize("parent.w-2", 1):setPosition(2,"parent.y+1")
		:setBackground(colors.black):setForeground(colors.white):setDefaultText("Search")
	views.inventory:addLabel():setSize('parent.w', 1):setPosition(1, "parent.y+2"):setText("Items:"):setForeground(colors.white)

	local lastSelection = -1
	local itemList = views.inventory:addList():setSize("math.floor(parent.w/2)", "parent.h-5"):setPosition(2, "parent.y+3")
	itemList:setBackground(colors.black):setScrollable(true):setSelectionColor(colors.gray, colors.white)

	local function addItemToItemList(name, ...)
		itemList:addItem(name, colors.black, colors.white, {...})
	end

	local itemDetail = views.inventory:addFrame()
		:setSize("math.floor(parent.w/2)-2","parent.h-5"):setPosition("math.floor(parent.w/2)+3", "parent.y+3")
		:setBackground(colors.gray)
	local itemDetailItemName = itemDetail:addLabel()
		:setParent(itemDetail)
		:setPosition(2,3):setSize("parent.w-2", 2)
		:setForeground(colors.white):setBackground(colors.black)
		:setText("Item")
	local itemDetailModName = itemDetail:addLabel()
		:setParent(itemDetail)
		:setPosition(2,2):setSize("parent.w-2", 1)
		:setForeground(colors.white):setBackground(colors.blue)
		:setText("Mod")
	local itemDetailCountBox = itemDetail:addLabel()
		:setPosition("parent.w-self.w", 5):setSize("math.floor(parent.w/2)", 1)
		:setBackground(colors.black):setForeground(colors.white)
		:setTextAlign("right")
		:setText("1")
	local itemDetailGetCountBox = itemDetail:addInput()
		:setPosition(2, "parent.h-1"):setSize("parent.w-2", 1)
		:setBackground(colors.black):setForeground(colors.white)
		:setDefaultText("Count")
		:setInputType("number")
	local function addDeltaButton(name, x, y, w, h, delta, text)
		itemDetail:addButton(name)
			:setPosition(x, y):setSize(w, h)
			:setBackground(delta > 0 and colors.green or colors.red):setForeground(colors.white)
			:setHorizontalAlign("right")
			:setText(text)
			:onClick(function (self)
				self:setBackground(colors.black)
			end)
			:onRelease(function (self)
				self:setBackground(delta > 0 and colors.green or colors.red)
			end)
			:onClickUp(function (self)
				itemDetailGetCountBox:setValue(math.max(0, (tonumber(itemDetailGetCountBox:getValue()) or 0) + delta))
			end)
	end
	addDeltaButton("+1B", "parent.w-3", "parent.h-2", 3, 1, 1, "+1")
	addDeltaButton("-1B", 2, "parent.h-2", 3, 1, -1, "-1")
	addDeltaButton("+8B", "parent.w-7", "parent.h-2", 3, 1, 8, "+8")
	addDeltaButton("-8B", 6, "parent.h-2", 3, 1, -8, "-8")
	addDeltaButton("+16B", "parent.w-3", "parent.h-3", 3, 1, 16, "+16")
	addDeltaButton("-16B", 2, "parent.h-3", 3, 1, -16, "-16")
	addDeltaButton("+64B", "parent.w-7", "parent.h-3", 3, 1, 64, "+64")
	addDeltaButton("-64B", 6, "parent.h-3", 3, 1, -64, "-64")
	itemDetail:addButton("reqButton")
		:setPosition("math.floor(parent.w/2-self.w/2)+1", "parent.h-4")
		:setSize(5,3)
		:setBackground(colors.lightBlue):setForeground(colors.black)
		:setVerticalAlign("center"):setHorizontalAlign("center")
		:setText("REQ")
		:onClick(function (self)
			self:setBackground(colors.white)
		end)
		:onRelease(function (self)
			self:setBackground(colors.lightBlue)
		end)
		:onClickUp(function (self)
			mainInventory:RequestDelivery({{
				name = inventoryList[itemList:getItemIndex()].name,
				displayName = inventoryList[itemList:getItemIndex()].displayName,
				count = math.floor(itemDetailGetCountBox:getValue()),
				type = inventoryList[itemList:getItemIndex()].type,
				tag = inventoryList[itemList:getItemIndex()].tag
			}}, outputInventory)
			dprint(("Transferring %ix%s..."):format(math.floor(itemDetailGetCountBox:getValue()), inventoryList[itemList:getItemIndex()].displayName))
		end)
	itemDetail:hide()
	itemList:setSize("parent.w-2", "parent.h-5")
	itemList:onSelect(function (self, event, item)
		detailedView = (not detailedView) or lastSelection ~= itemList:getItemIndex()
		
		local val = inventoryList[itemList:getItemIndex()]
		local modName, itemName = string.match(val.name, "^([^:]-):(.+)$")
		local itemDisplayName = val.displayName
		if #itemDisplayName > 35 then itemDisplayName = itemDisplayName:sub(1,35):gsub("%s%S+$", "...") end
		dprint(itemDisplayName)
		itemDetailItemName:setText(itemDisplayName)
		itemDetailModName:setText(modName)
		itemDetailCountBox:setText(val.count..(val.type == 1 and " mB" or ""))
		if not detailedView then
			itemDetail:hide()
			itemList:setSize("parent.w-2", "parent.h-5")
		else
			itemDetail:show()
			itemList:setSize("math.floor(parent.w/2)", "parent.h-5")
		end
		lastSelection = itemList:getItemIndex()
	end)

	--TODO: Code UI update when inventory updates
	--#endregion Inventory View

	function updateList()
		inventoryList = {}
		itemList:clear()

		for _, v in ipairs(mainInventory.stock) do
			table.insert(inventoryList, v)
		end
		table.sort(inventoryList, function (a, b)
			if a.count > b.count then return true end
			if a.count == b.count then return a.displayName:sub(1,1):byte() < b.displayName:sub(1,1):byte() end
			return false
		end)
		for _, v in ipairs(inventoryList) do
			addItemToItemList(v.displayName)
		end
		local val = inventoryList[itemList:getItemIndex()]
		local modName, itemName = string.match(val.name, "^([^:]-):(.+)$")
		local itemDisplayName = val.displayName
		if #itemDisplayName > 35 then itemDisplayName = itemDisplayName:sub(1,35):gsub("%s%S+$", "...") end
		itemDetailItemName:setText(itemDisplayName)
		itemDetailModName:setText(modName)
		itemDetailCountBox:setText(val.count..(val.type == 1 and " mB" or ""))
		if not detailedView then
			itemDetail:hide()
			itemList:setSize("parent.w-2", "parent.h-5")
		else
			itemDetail:show()
			itemList:setSize("math.floor(parent.w/2)", "parent.h-5")
		end
	end
	updateList()
	BASALT.onEvent(function (event)
		if event == "inventory_updated" then updateList() end
	end)
	

	BASALT.autoUpdate()
end

return module