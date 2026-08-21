-- chunkname: @/game_cyclopedia/tab/items/items.lua

Cyclopedia.Items = {}
Cyclopedia.CategoryItems = {
	{
		name = "Armors",
		id = 1
	},
	{
		name = "Amulets",
		id = 2
	},
	{
		name = "Boots",
		id = 3
	},
	{
		name = "Containers",
		id = 4
	},
	{
		name = "Creature Products",
		id = 24
	},
	{
		name = "Decoration",
		id = 5
	},
	{
		name = "Food",
		id = 6
	},
	{
		name = "Gold",
		id = 30
	},
	{
		name = "Helmets and Hats",
		id = 7
	},
	{
		name = "Legs",
		id = 8
	},
	{
		name = "Others",
		id = 9
	},
	{
		name = "Potions",
		id = 10
	},
	{
		name = "Quivers",
		id = 25
	},
	{
		name = "Rings",
		id = 11
	},
	{
		name = "Runes",
		id = 12
	},
	{
		name = "Shields",
		id = 13
	},
	{
		name = "Soul Cores",
		id = 26
	},
	{
		name = "Tools",
		id = 14
	},
	{
		name = "Unsorted",
		id = 31
	},
	{
		name = "Valuables",
		id = 15
	},
	{
		name = "Weapons: Ammo",
		id = 16
	},
	{
		name = "Weapons: Axe",
		id = 17
	},
	{
		name = "Weapons: Clubs",
		id = 18
	},
	{
		name = "Weapons: Distance",
		id = 19
	},
	{
		name = "Weapons: Fist",
		id = 27
	},
	{
		name = "Weapons: Swords",
		id = 20
	},
	{
		name = "Weapons: Wands",
		id = 21
	},
	{
		name = "Weapons: All",
		id = 1000
	}
}

local UI
local ITEMS_BATCH_SIZE = 15
local ITEMS_CHUNKED_THRESHOLD = 15
local ITEMS_SEARCH_DEBOUNCE_MS = 150
local ITEMS_SEARCH_RESULT_CAP = 200
local ITEMS_ROW_HEIGHT = 36
local ITEMS_VIRTUAL_POOL_SIZE = 14
local ITEMS_VIRTUAL_THRESHOLD = 14
local ITEMS_INDEX_PRELOAD_DELAY_MS = 400
local ITEMS_INDEX_PRELOAD_BATCH = 300
local itemsRenderGeneration = 0
local itemsSearchDebounceEvent
local ignoreSearchTextChange = false
local itemsIndexPreloadGeneration = 0
local itemsIndexPreloadEvent, itemsIndexPreloadScheduled
local itemsVirtualMode = false
local itemsVirtualEntries = {}
local itemsVirtualPool = {}
local itemsVirtualFirstIndex = 1

local function cancelItemsListRender()
	itemsRenderGeneration = itemsRenderGeneration + 1
end

local function cancelItemsSearchDebounce()
	if itemsSearchDebounceEvent then
		removeEvent(itemsSearchDebounceEvent)

		itemsSearchDebounceEvent = nil
	end
end

local function cancelItemsIndexPreload()
	itemsIndexPreloadGeneration = itemsIndexPreloadGeneration + 1

	if itemsIndexPreloadEvent then
		removeEvent(itemsIndexPreloadEvent)

		itemsIndexPreloadEvent = nil
	end

	if itemsIndexPreloadScheduled then
		removeEvent(itemsIndexPreloadScheduled)

		itemsIndexPreloadScheduled = nil
	end

	Cyclopedia.ItemsIndexPreloading = false
end

local function setSearchEditTextSilent(text)
	if not UI or not UI.SearchEdit then
		return
	end

	ignoreSearchTextChange = true

	UI.SearchEdit:setText(text or "")

	ignoreSearchTextChange = false
end

local function resolveThingType(data)
	if type(data) == "table" and data.thingType then
		return data.thingType, data
	end

	return data, nil
end

local function getEntryDisplayName(data)
	if type(data) == "table" and data.name then
		return data.name
	end

	local thingType = resolveThingType(data)

	return Cyclopedia.getItemDisplayName(thingType)
end

local function getEntryNameLower(data)
	if type(data) == "table" and data.nameLower then
		return data.nameLower
	end

	return string.lower(getEntryDisplayName(data) or "")
end

function Cyclopedia.invalidateItemsIndex()
	cancelItemsListRender()
	cancelItemsSearchDebounce()
	cancelItemsIndexPreload()

	Cyclopedia.ItemsIndexBuilt = false
	Cyclopedia.ItemsIndexPreloading = false
	Cyclopedia.ItemList = {}
	Cyclopedia.AllItemList = {}
end

local function focusItemsSearchEdit()
	if not UI or not UI.SearchEdit or UI.SearchEdit:isDestroyed() then
		return
	end

	local edit = UI.SearchEdit

	edit:setFocusable(true)

	local cyclopediaUi = controllerCyclopedia and controllerCyclopedia.ui

	if cyclopediaUi and not cyclopediaUi:isDestroyed() and cyclopediaUi:isVisible() then
		cyclopediaUi:raise()
	end

	edit:focus()
	pcall(function()
		edit:grabKeyboard()
	end)
	pcall(function()
		edit:setEditable(true)
		edit:setCursorVisible(true)
		edit:setCursorPos(-1)
	end)
end

local function setupItemsSearchEdit()
	if not UI or not UI.SearchEdit or UI.SearchEdit:isDestroyed() then
		return
	end

	local edit = UI.SearchEdit

	edit:setFocusable(true)

	function edit.onFocusChange(widget, focused)
		if focused and not widget:isDestroyed() then
			pcall(function()
				widget:grabKeyboard()
			end)
			pcall(function()
				widget:setCursorVisible(true)
			end)
		else
			pcall(function()
				widget:ungrabKeyboard()
			end)
		end
	end

	function edit.onKeyDown(widget, keyCode, keyboardModifiers)
		if keyboardModifiers ~= KeyboardNoModifier then
			return false
		end

		if keyCode == KeyEscape then
			Cyclopedia.releaseItemsSearchFocus()

			if toggle then
				toggle()
			end

			return true
		end

		return false
	end
end

function Cyclopedia.releaseItemsSearchFocus()
	if UI and UI.SearchEdit and not UI.SearchEdit:isDestroyed() then
		pcall(function()
			UI.SearchEdit:ungrabKeyboard()
		end)
	end
end

local function setupOwnValueEdit()
	if not UI or not UI.InfoBase or not UI.InfoBase.OwnValueEdit then
		return
	end

	local edit = UI.InfoBase.OwnValueEdit

	edit:setFocusable(true)

	function edit.onFocusChange(widget, focused)
		if focused and not widget:isDestroyed() then
			Cyclopedia.releaseItemsSearchFocus()
		end
	end
end

local function clearItemsListSelection()
	if UI then
		UI.selectItem = nil
		UI.selectedItemId = nil
	end
end

function Cyclopedia.clearItemsUI()
	cancelItemsListRender()
	cancelItemsSearchDebounce()
	Cyclopedia.releaseItemsSearchFocus()

	itemsVirtualMode = false
	itemsVirtualEntries = {}
	itemsVirtualPool = {}
	itemsVirtualFirstIndex = 1

	if UI then
		UI.selectItem = nil
		UI.selectedItemId = nil
		UI.selectedCategory = nil
	end

	UI = nil
end

local ignoreLootValueSourceCheck = false
local refreshLootValuePanel
local ITEM_PRICES_FILE = "itemprices.json"

local function getItemPricesFile()
	local player = g_game.getLocalPlayer()

	if not player then
		return nil
	end

	return "/characterdata/" .. player:getId() .. "/" .. ITEM_PRICES_FILE
end

local function itemPriceKey(itemId)
	return tostring(itemId)
end

function Cyclopedia.initItemPrices()
	Cyclopedia.ItemPrices = {
		customSalePrices = {},
		primaryLootValueSources = {}
	}
end

function Cyclopedia.loadItemPrices()
	Cyclopedia.initItemPrices()

	local file = getItemPricesFile()

	if not file or not g_resources.fileExists(file) then
		return
	end

	local status, result = pcall(function()
		return json.decode(g_resources.readFileContents(file))
	end)

	if not status then
		g_logger.error("Error while reading itemprices.json. Details: " .. tostring(result))

		return
	end

	if type(result) ~= "table" then
		return
	end

	if type(result.customSalePrices) == "table" then
		Cyclopedia.ItemPrices.customSalePrices = result.customSalePrices
	end

	if type(result.primaryLootValueSources) == "table" then
		Cyclopedia.ItemPrices.primaryLootValueSources = result.primaryLootValueSources
	end

	if UI and UI.ItemListBase and UI.ItemListBase.List then
		Cyclopedia.refreshItemListPrices()
	end
end

function Cyclopedia.saveItemPrices()
	if not Cyclopedia.ItemPrices then
		return
	end

	local file = getItemPricesFile()

	if not file then
		return
	end

	local config = {
		customSalePrices = Cyclopedia.ItemPrices.customSalePrices,
		primaryLootValueSources = Cyclopedia.ItemPrices.primaryLootValueSources
	}
	local status, result = pcall(function()
		return json.encode(config, 2)
	end)

	if not status then
		g_logger.error("Error while saving itemprices.json. Details: " .. tostring(result))

		return
	end

	if result:len() > 104857600 then
		g_logger.error("itemprices.json is above 100MB, won't be saved")

		return
	end

	g_resources.writeFileContents(file, result)
end

function Cyclopedia.getItemCustomSalePrice(itemId)
	if not Cyclopedia.ItemPrices then
		return nil
	end

	local price = Cyclopedia.ItemPrices.customSalePrices[itemPriceKey(itemId)]

	if price == nil then
		return nil
	end

	return tonumber(price)
end

function Cyclopedia.setItemCustomSalePrice(itemId, price)
	if not Cyclopedia.ItemPrices then
		Cyclopedia.initItemPrices()
	end

	local key = itemPriceKey(itemId)

	if price and price > 0 then
		Cyclopedia.ItemPrices.customSalePrices[key] = math.floor(price)
	else
		Cyclopedia.ItemPrices.customSalePrices[key] = nil
	end
end

function Cyclopedia.getItemLootValueSource(itemId)
	if Cyclopedia.ItemPrices and Cyclopedia.ItemPrices.primaryLootValueSources then
		local source = Cyclopedia.ItemPrices.primaryLootValueSources[itemPriceKey(itemId)]

		if source == "market" or source == "npc" then
			return source
		end
	end

	return Cyclopedia.Items.LootValueSource or "npc"
end

function Cyclopedia.setItemLootValueSource(itemId, source)
	if not Cyclopedia.ItemPrices then
		Cyclopedia.initItemPrices()
	end

	local key = itemPriceKey(itemId)

	if source == "market" then
		Cyclopedia.ItemPrices.primaryLootValueSources[key] = "market"
	else
		Cyclopedia.ItemPrices.primaryLootValueSources[key] = nil
	end
end

function Cyclopedia.refreshItemListPrices()
	if not UI or not UI.ItemListBase or not UI.ItemListBase.List then
		return
	end

	for _, child in ipairs(UI.ItemListBase.List:getChildren()) do
		local itemId = tonumber(child:getId())

		if itemId and itemId > 0 then
			local thingType = g_things.getThingType(itemId, ThingCategoryItem)

			if thingType then
				child.Value = Cyclopedia.computeLootPrice(thingType)
			end
		end
	end
end

function Cyclopedia.refreshSelectedItemPrices()
	if not UI or not UI.selectItem then
		return
	end

	local itemId = tonumber(UI.selectItem:getId())

	if not itemId then
		return
	end

	refreshLootValuePanel()

	local price = UI.selectItem.Value or 0

	for _, child in ipairs(UI.ItemListBase.List:getChildren()) do
		if tonumber(child:getId()) == itemId then
			child.Value = price

			break
		end
	end
end

local function applyItemLootValueSourceToUI(itemId)
	if not UI or not UI.LootValue then
		return
	end

	local source = Cyclopedia.getItemLootValueSource(itemId)

	ignoreLootValueSourceCheck = true

	UI.LootValue.NpcBuyCheck:setChecked(source ~= "market")
	UI.LootValue.MarketCheck:setChecked(source == "market")

	ignoreLootValueSourceCheck = false
end

local function applyItemCustomSalePriceToUI(itemId)
	if not UI or not UI.InfoBase or not UI.InfoBase.OwnValueEdit then
		return
	end

	local ownValueEdit = UI.InfoBase.OwnValueEdit
	local price = Cyclopedia.getItemCustomSalePrice(itemId)

	ownValueEdit._suppressOwnValueChange = true

	if price and price > 0 then
		ownValueEdit:setText(tostring(price))
	else
		ownValueEdit:setText("")
	end

	ownValueEdit._suppressOwnValueChange = false

	if UI.InfoBase.OwnValuePlaceholder then
		UI.InfoBase.OwnValuePlaceholder:setVisible(ownValueEdit:getText():len() == 0)
	end
end

function Cyclopedia.onOwnValueEditChange()
	if not UI or not UI.InfoBase or not UI.InfoBase.OwnValueEdit then
		return
	end

	local ownValueEdit = UI.InfoBase.OwnValueEdit

	if ownValueEdit._suppressOwnValueChange then
		return
	end

	if not UI.selectItem then
		return
	end

	local itemId = tonumber(UI.selectItem:getId())

	if not itemId then
		return
	end

	local text = ownValueEdit:getText():match("^%s*(.-)%s*$") or ""

	if text == "" then
		Cyclopedia.setItemCustomSalePrice(itemId, nil)
	else
		local price = tonumber(text)

		if not price or price < 0 then
			return
		end

		Cyclopedia.setItemCustomSalePrice(itemId, price)
	end

	Cyclopedia.saveItemPrices()
	Cyclopedia.refreshSelectedItemPrices()
end

local ITEM_LIST_NAME_COLOR_DEFAULT = "#c0c0c0"
local ITEM_LIST_NAME_COLOR_TRACKED = "#ff9854"

local function isItemDropTracked(itemId)
	if DropTrackerAnalyser and DropTrackerAnalyser.isInDropTracker then
		return DropTrackerAnalyser:isInDropTracker(itemId)
	end

	if isInDropTracker then
		return isInDropTracker(itemId)
	end

	return false
end

local function getItemListNameColor(itemId)
	if isItemDropTracked(itemId) then
		return ITEM_LIST_NAME_COLOR_TRACKED
	end

	return ITEM_LIST_NAME_COLOR_DEFAULT
end

local function updateItemListRowTrackColor(row, itemId)
	if not row or not row.Name then
		return
	end

	local id = itemId or tonumber(row:getId())

	if id then
		row.Name:setColor(getItemListNameColor(id))
	end
end

local function updateItemListTrackColorForId(itemId)
	if not UI or not UI.ItemListBase or not UI.ItemListBase.List then
		return
	end

	for _, child in ipairs(UI.ItemListBase.List:getChildren()) do
		if tonumber(child:getId()) == itemId then
			updateItemListRowTrackColor(child, itemId)
		end
	end
end

local UNSORTED_CATEGORY_ID = 31

function Cyclopedia.getItemListCategory(thingType)
	if thingType:isMarketable() then
		local marketData = thingType:getMarketData()

		if marketData and marketData.category then
			return marketData.category
		end
	end

	return UNSORTED_CATEGORY_ID
end

function Cyclopedia.getItemDisplayName(thingType)
	local marketData = thingType:getMarketData()

	if thingType:isMarketable() and marketData and marketData.name and marketData.name ~= "" then
		return marketData.name
	end

	local name = thingType:getName()

	if name and name ~= "" then
		return name
	end

	if g_things.getCyclopediaItemName then
		local cycName = g_things.getCyclopediaItemName(thingType:getId())

		if cycName and cycName ~= "" then
			return cycName
		end
	end

	return "Item #" .. tostring(thingType:getId())
end

local function normalizeSearchText(text)
	if not text then
		return ""
	end

	return text:match("^%s*(.-)%s*$") or ""
end

local function itemNameMatchesSearch(itemNameLower, searchTermLower)
	if searchTermLower == "" then
		return false
	end

	return itemNameLower:find(searchTermLower, 1, true) ~= nil
end

function Cyclopedia.onItemTrackCheckChange(widget, checked)
	if widget._suppressTrackCheckChange then
		return
	end

	if not UI or not UI.selectItem then
		return
	end

	local itemId = tonumber(UI.selectItem:getId())

	if not itemId then
		return
	end

	if managerDropTracker then
		managerDropTracker(itemId, checked)
	elseif DropTrackerAnalyser and DropTrackerAnalyser.managerDropItem then
		DropTrackerAnalyser:managerDropItem(itemId, checked)
	end

	updateItemListTrackColorForId(itemId)
end

function Cyclopedia.computeLootPrice(thingType)
	if not thingType then
		return 0
	end

	local itemId = thingType:getId()
	local customPrice = Cyclopedia.getItemCustomSalePrice(itemId)

	if customPrice and customPrice > 0 then
		return customPrice
	end

	if Cyclopedia.getItemLootValueSource(itemId) == "market" then
		return thingType:getMeanPrice() or 0
	end

	local maxNpcBuy = 0
	local npcData = thingType:getNpcSaleData()

	if npcData then
		for i = 1, #npcData do
			local row = npcData[i]

			if row and row.buyPrice and maxNpcBuy < row.buyPrice then
				maxNpcBuy = row.buyPrice
			end
		end
	end

	return maxNpcBuy
end

function refreshLootValuePanel()
	if not UI or not UI.selectItem then
		return
	end

	local itemId = tonumber(UI.selectItem:getId())
	local internalData = g_things.getThingType(itemId, ThingCategoryItem)

	if not internalData then
		return
	end

	local price = Cyclopedia.computeLootPrice(internalData)

	if UI.selectItem then
		UI.selectItem.Value = price
	end

	UI.InfoBase.ResultGoldBase.Value:setText(Cyclopedia.formatGold(price))

	if UI.InfoBase.MarketGoldPriceBase and UI.InfoBase.MarketGoldPriceBase.Value then
		UI.InfoBase.MarketGoldPriceBase.Value:setText(Cyclopedia.formatGold(internalData:getMeanPrice() or 0))
	end

	if price > 0 then
		ItemsDatabase.setRarityItem(UI.InfoBase.ResultGoldBase.Rarity, price)
		ItemsDatabase.setRarityItem(UI.SelectedItem.Rarity, price)
	else
		UI.InfoBase.ResultGoldBase.Rarity:setImageSource("")
		UI.SelectedItem.Rarity:setImageSource("")
	end
end

function Cyclopedia.onLootValueSourceChange(widget, checked)
	if ignoreLootValueSourceCheck then
		return
	end

	if not checked then
		ignoreLootValueSourceCheck = true

		widget:setChecked(true)

		ignoreLootValueSourceCheck = false

		return
	end

	ignoreLootValueSourceCheck = true

	if widget == UI.LootValue.NpcBuyCheck then
		UI.LootValue.MarketCheck:setChecked(false)

		Cyclopedia.Items.LootValueSource = "npc"
	else
		UI.LootValue.NpcBuyCheck:setChecked(false)

		Cyclopedia.Items.LootValueSource = "market"
	end

	ignoreLootValueSourceCheck = false

	if UI and UI.selectItem then
		local itemId = tonumber(UI.selectItem:getId())

		if itemId then
			Cyclopedia.setItemLootValueSource(itemId, Cyclopedia.Items.LootValueSource)
			Cyclopedia.saveItemPrices()
		end
	end

	refreshLootValuePanel()

	if UI and UI.ItemListBase and UI.ItemListBase.List and UI.selectItem then
		local itemId = tonumber(UI.selectItem:getId())
		local price = UI.selectItem.Value or 0

		if itemId then
			for _, child in ipairs(UI.ItemListBase.List:getChildren()) do
				if tonumber(child:getId()) == itemId then
					child.Value = price

					break
				end
			end
		end
	end
end

local function itemListClearSelectionHighlight(row)
	if not row then
		return
	end

	row:setBackgroundColor("#00000000")

	if row.SelectionFill then
		row.SelectionFill:setBackgroundColor("#00000000")
	end
end

local function itemListSetSelectionHighlight(row)
	if not row then
		return
	end

	row:setBackgroundColor("#00000000")

	if row.SelectionFill then
		row.SelectionFill:setBackgroundColor("#585858")
	else
		row:setBackgroundColor("#585858")
	end
end

function Cyclopedia.ResetItemCategorySelection(list)
	for i, child in pairs(list:getChildren()) do
		child:setChecked(false)
		child:setBackgroundColor(child.BaseColor)
	end
end

function showItems()
	Cyclopedia.clearItemsUI()

	UI = g_ui.loadUI("items", contentContainer)

	function UI.onDestroy()
		UI = nil
	end

	UI:show()

	UI.VocFilter = false
	UI.LevelFilter = false
	UI.h1Filter = false
	UI.h2Filter = false
	UI.ClassificationFilter = 0
	UI.SelectedCategory = nil
	Cyclopedia.Items.VocFilter = false
	Cyclopedia.Items.LevelFilter = false
	Cyclopedia.Items.h1Filter = false
	Cyclopedia.Items.h2Filter = false
	Cyclopedia.Items.ClassificationFilter = 0
	Cyclopedia.Items.LootValueSource = "npc"

	UI.LootValue.NpcBuyCheck:setChecked(true)
	UI.LootValue.MarketCheck:setChecked(false)

	UI.LootValue.NpcBuyCheck.onCheckChange = Cyclopedia.onLootValueSourceChange
	UI.LootValue.MarketCheck.onCheckChange = Cyclopedia.onLootValueSourceChange

	local ownValueEdit = UI.InfoBase.OwnValueEdit
	local ownValuePlaceholder = UI.InfoBase.OwnValuePlaceholder

	local function updateOwnValuePlaceholder()
		ownValuePlaceholder:setVisible(ownValueEdit:getText():len() == 0)
	end

	function ownValueEdit.onTextChange()
		updateOwnValuePlaceholder()
		Cyclopedia.onOwnValueEditChange()
	end

	updateOwnValuePlaceholder()
	UI.EmptyLabel:setVisible(true)
	UI.InfoBase:setVisible(false)
	UI.LootValue:setVisible(false)
	UI.H1Button:disable()
	UI.H2Button:disable()
	UI.ItemFilter:disable()
	controllerCyclopedia.ui.MajorCharmsBase:setVisible(false)
	controllerCyclopedia.ui.GoldBase:setVisible(false)
	controllerCyclopedia.ui.BestiaryTrackerButton:setVisible(false)
	controllerCyclopedia.ui.MinorCharmsBase:setVisible(false)

	local CategoryColor = "#484848"

	for _, data in ipairs(Cyclopedia.CategoryItems) do
		local ItemCat = g_ui.createWidget("ItemCategory", UI.CategoryList)

		ItemCat:setFocusable(false)
		ItemCat:setId(data.id)
		ItemCat:setText(data.name)
		ItemCat:setBackgroundColor(CategoryColor)
		ItemCat:setPhantom(false)

		ItemCat.BaseColor = CategoryColor

		function ItemCat:onClick()
			Cyclopedia.ResetItemCategorySelection(UI.CategoryList)
			self:setChecked(true)
			self:setBackgroundColor("#585858")
		end

		CategoryColor = CategoryColor == "#484848" and "#414141" or "#484848"
	end

	Cyclopedia.loadItemsCategories()
	setupItemsSearchEdit()
	setupOwnValueEdit()
	focusItemsSearchEdit()
	scheduleEvent(focusItemsSearchEdit, 50)
end

function Cyclopedia.onCategoryChange(widget)
	if widget:isChecked() then
		Cyclopedia.selectItemCategory(tonumber(widget:getId()))

		UI.selectedCategory = widget
	end
end

function Cyclopedia.vocationFilter(value)
	Cyclopedia.Items.VocFilter = value

	Cyclopedia.applyFilters()
end

function Cyclopedia.levelFilter(value)
	Cyclopedia.Items.LevelFilter = value

	Cyclopedia.applyFilters()
end

local ignoreRecursiveCalls = false

local function setCheckedWithoutRecursion(h1Val, h2Val)
	ignoreRecursiveCalls = true

	UI.H1Button:setChecked(h1Val)
	UI.H2Button:setChecked(h2Val)

	ignoreRecursiveCalls = false
end

function Cyclopedia.handFilter(h1Val, h2Val)
	Cyclopedia.Items.h1Filter = h1Val
	Cyclopedia.Items.h2Filter = h2Val

	if ignoreRecursiveCalls then
		return
	end

	setCheckedWithoutRecursion(h1Val, h2Val)
	Cyclopedia.applyFilters()
end

function Cyclopedia.classificationFilter(data)
	Cyclopedia.Items.ClassificationFilter = tonumber(data)

	Cyclopedia.applyFilters()
end

local function itemPassesFilters(data)
	local thingType = resolveThingType(data)

	if not thingType then
		return false
	end

	local player = g_game.getLocalPlayer()

	if not player then
		return true
	end

	local vocation = player:getVocation()
	local level = player:getLevel()
	local classification = thingType:getClassification()
	local marketData = thingType:getMarketData()
	local hasMarket = thingType:isMarketable() and marketData and not table.empty(marketData)
	local vocFilter = Cyclopedia.Items.VocFilter
	local levelFilter = Cyclopedia.Items.LevelFilter
	local h1Filter = Cyclopedia.Items.h1Filter
	local h2Filter = Cyclopedia.Items.h2Filter
	local classificationFilter = Cyclopedia.Items.ClassificationFilter

	if vocFilter and hasMarket and tonumber(marketData.restrictVocation) > 0 then
		local demotedVoc = vocation > 10 and vocation - 10 or vocation
		local vocBitMask = Bit.bit(tonumber(demotedVoc))

		if not Bit.hasBit(marketData.restrictVocation, vocBitMask) then
			return false
		end
	end

	if levelFilter and hasMarket and level < marketData.requiredLevel then
		return false
	end

	if h1Filter and thingType:getClothSlot() ~= 6 then
		return false
	end

	if h2Filter and thingType:getClothSlot() ~= 0 then
		return false
	end

	if classificationFilter == -1 and classification ~= 0 then
		return false
	elseif classificationFilter == 1 and classification ~= 1 then
		return false
	elseif classificationFilter == 2 and classification ~= 2 then
		return false
	elseif classificationFilter == 3 and classification ~= 3 then
		return false
	elseif classificationFilter == 4 and classification ~= 4 then
		return false
	end

	return true
end

local function collectFilteredEntries(entries)
	local result = {}

	for i = 1, #entries do
		local data = entries[i]

		if itemPassesFilters(data) then
			result[#result + 1] = data
		end
	end

	return result
end

function Cyclopedia.onItemListRowClick(widget)
	if not UI or not widget or widget:isDestroyed() then
		return
	end

	UI.InfoBase.SellBase.List:destroyChildren()
	UI.InfoBase.BuyBase.List:destroyChildren()

	local oldSelected = UI.selectItem
	local lootValue = UI.LootValue
	local clickedItemId = tonumber(widget:getId())

	if not clickedItemId then
		return
	end

	local internalData = g_things.getThingType(clickedItemId, ThingCategoryItem)

	if not internalData then
		return
	end

	if oldSelected then
		itemListClearSelectionHighlight(oldSelected)
	end

	g_game.inspectionObject(3, clickedItemId, 1)

	if not lootValue:isVisible() then
		lootValue:setVisible(true)
	end

	UI.EmptyLabel:setVisible(false)
	UI.InfoBase:setVisible(true)
	applyItemLootValueSourceToUI(clickedItemId)
	applyItemCustomSalePriceToUI(clickedItemId)

	local price = Cyclopedia.computeLootPrice(internalData)

	widget.Value = price

	UI.InfoBase.ResultGoldBase.Value:setText(Cyclopedia.formatGold(price))

	if UI.InfoBase.MarketGoldPriceBase and UI.InfoBase.MarketGoldPriceBase.Value then
		UI.InfoBase.MarketGoldPriceBase.Value:setText(Cyclopedia.formatGold(internalData:getMeanPrice() or 0))
	end

	UI.SelectedItem.Sprite:setItemId(clickedItemId)

	if price > 0 then
		ItemsDatabase.setRarityItem(UI.SelectedItem.Rarity, price)
		ItemsDatabase.setRarityItem(UI.InfoBase.ResultGoldBase.Rarity, price)
	else
		UI.InfoBase.ResultGoldBase.Rarity:setImageSource("")
		UI.SelectedItem.Rarity:setImageSource("")
	end

	itemListSetSelectionHighlight(widget)

	if modules.game_quickloot.QuickLoot.data.filter == 2 then
		UI.InfoBase.quickLootCheck:setText("Loot when Quick Looting")
	else
		UI.InfoBase.quickLootCheck:setText("Skip when Quick Looting")
	end

	function UI.InfoBase.quickLootCheck:onCheckChange(checked)
		if checked then
			modules.game_quickloot.QuickLoot.addLootList(clickedItemId, modules.game_quickloot.QuickLoot.data.filter)
		else
			modules.game_quickloot.QuickLoot.removeLootList(clickedItemId, modules.game_quickloot.QuickLoot.data.filter)
		end
	end

	UI.InfoBase.quickLootCheck:setChecked(modules.game_quickloot.QuickLoot.lootExists(clickedItemId, modules.game_quickloot.QuickLoot.data.filter))

	local trackCheck = UI.InfoBase.TrackCheck

	trackCheck._suppressTrackCheckChange = true

	trackCheck:setChecked(isItemDropTracked(clickedItemId))

	trackCheck._suppressTrackCheckChange = false
	trackCheck.onCheckChange = Cyclopedia.onItemTrackCheckChange

	local buy, sell = Cyclopedia.formatSaleData(internalData:getNpcSaleData())
	local sellColor = "#484848"

	for index, value in ipairs(sell) do
		local t_widget = g_ui.createWidget("UIWidget", UI.InfoBase.SellBase.List)

		t_widget:setId(index)
		t_widget:setText(value)
		t_widget:setTextAlign(AlignLeft)
		t_widget:setBackgroundColor(sellColor)
		t_widget:setFont("Verdana Bold-11px-new")

		t_widget.BaseColor = sellColor

		function t_widget:onClick()
			Cyclopedia.ResetItemCategorySelection(UI.InfoBase.SellBase.List)
			self:setChecked(true)
			self:setBackgroundColor("#585858")
		end

		sellColor = sellColor == "#484848" and "#414141" or "#484848"
	end

	local buyColor = "#484848"

	for index, value in ipairs(buy) do
		local t_widget = g_ui.createWidget("UIWidget", UI.InfoBase.BuyBase.List)

		t_widget:setId(index)
		t_widget:setText(value)
		t_widget:setTextAlign(AlignLeft)
		t_widget:setBackgroundColor(buyColor)
		t_widget:setFont("Verdana Bold-11px-new")

		t_widget.BaseColor = buyColor

		function t_widget:onClick()
			Cyclopedia.ResetItemCategorySelection(UI.InfoBase.BuyBase.List)
			self:setChecked(true)
			self:setBackgroundColor("#585858")
		end

		buyColor = buyColor == "#484848" and "#414141" or "#484848"
	end

	UI.selectItem = widget
	UI.selectedItemId = clickedItemId
end

local function bindItemListRow(item, data)
	local thingType, entry = resolveThingType(data)

	if not thingType or not item then
		return
	end

	local marketData = thingType:getMarketData()
	local hasMarket = thingType:isMarketable() and marketData and not table.empty(marketData)
	local itemId = entry and entry.id or thingType:getId()
	local displayName = entry and entry.name or Cyclopedia.getItemDisplayName(thingType)

	item:setId(itemId)
	item.Sprite:setItemId(itemId)
	item.Name:setText(displayName)
	item.Name:setColor(getItemListNameColor(itemId))

	item.Value = 0
	item.Vocation = hasMarket and marketData.restrictVocation or 0

	if item.Rarity then
		item.Rarity:setImageSource("")
	end

	item._entry = data
	item.onClick = Cyclopedia.onItemListRowClick
end

function Cyclopedia.internalCreateItem(data)
	local thingType = resolveThingType(data)

	if not thingType then
		return
	end

	local item = g_ui.createWidget("ItemsListBaseItem", UI.ItemListBase.List)

	item:setFocusable(false)
	bindItemListRow(item, data)

	return item
end

local function clearItemListWidgets()
	if not UI or not UI.ItemListBase or not UI.ItemListBase.List then
		return
	end

	local list = UI.ItemListBase.List
	local layout = list:getLayout()

	if layout then
		layout:enableUpdates()
		layout:disableUpdates()
	end

	list:destroyChildren()

	if layout then
		layout:enableUpdates()
		layout:update()
	end

	itemsVirtualMode = false
	itemsVirtualEntries = {}
	itemsVirtualPool = {}
	itemsVirtualFirstIndex = 1

	if list.setKeepScrollRange then
		list:setKeepScrollRange(false)
	end

	list.onScrollChange = nil
end

local function getItemsListVisibleRows()
	if not UI or not UI.ItemListBase or not UI.ItemListBase.List then
		return ITEMS_VIRTUAL_POOL_SIZE
	end

	local list = UI.ItemListBase.List
	local height = list:getPaddingRect().height

	if height <= 0 then
		height = list:getHeight()
	end

	return math.max(1, math.floor(height / ITEMS_ROW_HEIGHT) + 2)
end

local function rebindVirtualItemPool(firstIndex)
	if not itemsVirtualMode or not UI or not UI.ItemListBase then
		return
	end

	local count = #itemsVirtualEntries

	firstIndex = math.max(1, math.min(firstIndex, math.max(1, count)))
	itemsVirtualFirstIndex = firstIndex

	local selectedId = UI.selectedItemId

	UI.selectItem = nil

	for i = 1, #itemsVirtualPool do
		local widget = itemsVirtualPool[i]
		local dataIndex = firstIndex + i - 1
		local data = itemsVirtualEntries[dataIndex]

		if data then
			widget:setVisible(true)
			bindItemListRow(widget, data)

			if selectedId and tonumber(widget:getId()) == selectedId then
				itemListSetSelectionHighlight(widget)

				UI.selectItem = widget
			else
				itemListClearSelectionHighlight(widget)
			end
		else
			widget:setVisible(false)
			widget:setId(0)

			if widget.Sprite then
				widget.Sprite:setItemId(0)
			end

			if widget.Name then
				widget.Name:setText("")
			end

			itemListClearSelectionHighlight(widget)
		end
	end
end

local function onVirtualItemsScroll(scrollArea, offset)
	if not itemsVirtualMode or not UI or not UI.ItemListBase then
		return
	end

	local scrollbar = UI.ItemListBase.ListScrollbar

	if not scrollbar then
		return
	end

	if scrollArea and scrollArea.setVirtualOffset then
		local vo = scrollArea:getVirtualOffset()

		if vo then
			vo.x = 0
			vo.y = 0

			scrollArea:setVirtualOffset(vo)
		end
	end

	local value = scrollbar:getValue() or 0
	local firstIndex = math.floor(value / ITEMS_ROW_HEIGHT) + 1

	if firstIndex ~= itemsVirtualFirstIndex then
		rebindVirtualItemPool(firstIndex)
	end
end

local function renderItemEntriesVirtual(entries, options)
	options = options or {}

	local list = UI.ItemListBase.List
	local scrollbar = UI.ItemListBase.ListScrollbar
	local layout = list:getLayout()

	clearItemsListSelection()

	if layout then
		layout:enableUpdates()
		layout:disableUpdates()
	end

	list:destroyChildren()

	itemsVirtualMode = true
	itemsVirtualEntries = entries
	itemsVirtualPool = {}
	itemsVirtualFirstIndex = 1

	if list.setKeepScrollRange then
		list:setKeepScrollRange(true)
	end

	local poolSize = math.min(ITEMS_VIRTUAL_POOL_SIZE, math.max(getItemsListVisibleRows(), 1))

	poolSize = math.min(poolSize, #entries)

	for i = 1, poolSize do
		local widget = g_ui.createWidget("ItemsListBaseItem", list)

		widget:setFocusable(false)

		itemsVirtualPool[i] = widget
	end

	if layout then
		layout:enableUpdates()
		layout:update()
	end

	local visibleRows = math.max(1, math.floor((list:getPaddingRect().height > 0 and list:getPaddingRect().height or list:getHeight()) / ITEMS_ROW_HEIGHT))
	local maxScroll = math.max(0, (#entries - visibleRows) * ITEMS_ROW_HEIGHT)

	if scrollbar then
		scrollbar:setMinimum(0)
		scrollbar:setMaximum(maxScroll)
		scrollbar:setValue(0)
		scrollbar:setStep(ITEMS_ROW_HEIGHT)
	end

	list.onScrollChange = onVirtualItemsScroll

	rebindVirtualItemPool(1)

	if options.onComplete then
		options.onComplete()
	end
end

local function renderItemEntries(entries, options)
	options = options or {}

	if not UI or not UI.ItemListBase or not UI.ItemListBase.List then
		return
	end

	cancelItemsListRender()

	local generation = itemsRenderGeneration
	local count = #entries

	if not options.sync and count > ITEMS_VIRTUAL_THRESHOLD then
		renderItemEntriesVirtual(entries, options)

		return
	end

	clearItemsListSelection()

	local list = UI.ItemListBase.List
	local layout = list:getLayout()

	if list.setKeepScrollRange then
		list:setKeepScrollRange(false)
	end

	list.onScrollChange = nil
	itemsVirtualMode = false
	itemsVirtualEntries = {}
	itemsVirtualPool = {}

	if layout then
		layout:enableUpdates()
		layout:disableUpdates()
	end

	list:destroyChildren()

	local function finishRender()
		if generation ~= itemsRenderGeneration then
			return
		end

		if layout and not list:isDestroyed() then
			layout:enableUpdates()
			layout:update()
		end

		if options.onComplete then
			options.onComplete()
		end
	end

	local sync = options.sync or count <= ITEMS_CHUNKED_THRESHOLD

	if sync then
		for i = 1, count do
			Cyclopedia.internalCreateItem(entries[i])
		end

		finishRender()

		return
	end

	local index = 1

	local function createNextBatch()
		if generation ~= itemsRenderGeneration then
			return
		end

		if not UI or not UI.ItemListBase or list:isDestroyed() then
			return
		end

		local endIndex = math.min(index + ITEMS_BATCH_SIZE - 1, count)

		for i = index, endIndex do
			Cyclopedia.internalCreateItem(entries[i])
		end

		index = endIndex + 1

		if index <= count then
			addEvent(createNextBatch)
		else
			finishRender()
		end
	end

	createNextBatch()
end

local function collectCategoryEntries(id)
	local idsToProcess

	if id == 1000 then
		idsToProcess = {
			17,
			18,
			19,
			20,
			21
		}
	else
		idsToProcess = {
			id
		}
	end

	local tempTable = {}
	local needsSort = #idsToProcess > 1

	for i = 1, #idsToProcess do
		local idToProcess = idsToProcess[i]
		local categoryList = Cyclopedia.ItemList[idToProcess]

		if categoryList and #categoryList > 0 then
			for j = 1, #categoryList do
				tempTable[#tempTable + 1] = categoryList[j]
			end
		end
	end

	if needsSort then
		table.sort(tempTable, Cyclopedia.compareItems)
	end

	return collectFilteredEntries(tempTable)
end

local function processItemsById(id, options)
	renderItemEntries(collectCategoryEntries(id), options)
end

function Cyclopedia.applyFilters()
	if not UI then
		return
	end

	local isSearching = normalizeSearchText(UI.SearchEdit:getText()) ~= ""

	if not isSearching then
		if UI.selectedCategory then
			processItemsById(tonumber(UI.selectedCategory:getId()))
		end
	else
		Cyclopedia.ItemSearch(UI.SearchEdit:getText(), false)
	end
end

function Cyclopedia.onSearchClearButtonClick()
	if not UI or normalizeSearchText(UI.SearchEdit:getText()) == "" then
		return
	end

	cancelItemsSearchDebounce()
	Cyclopedia.ItemSearch("", true)
end

function Cyclopedia.onItemSearchTextChange(text)
	if ignoreSearchTextChange or not UI then
		return
	end

	cancelItemsSearchDebounce()

	itemsSearchDebounceEvent = scheduleEvent(function()
		itemsSearchDebounceEvent = nil

		if not UI or UI:isDestroyed() then
			return
		end

		Cyclopedia.ItemSearch(UI.SearchEdit:getText(), false)
	end, ITEMS_SEARCH_DEBOUNCE_MS)
end

function Cyclopedia.ItemSearch(text, clearTextEdit, options)
	options = options or {}
	text = normalizeSearchText(text)

	if not UI or not UI.ItemListBase then
		return
	end

	if text ~= "" then
		UI.SelectedItem.Sprite:setItemId(0)
		UI.SelectedItem.Rarity:setImageSource("")

		local searchedItems = {}
		local searchTermLower = string.lower(text)
		local oldSelected = UI.selectedCategory

		if oldSelected then
			oldSelected:setBackgroundColor(oldSelected.BaseColor)
			oldSelected:setChecked(false)

			UI.selectedCategory = nil
		end

		local allItems = Cyclopedia.AllItemList or {}

		for i = 1, #allItems do
			local data = allItems[i]

			if itemNameMatchesSearch(getEntryNameLower(data), searchTermLower) then
				searchedItems[#searchedItems + 1] = data

				if #searchedItems >= ITEMS_SEARCH_RESULT_CAP then
					break
				end
			end
		end

		renderItemEntries(collectFilteredEntries(searchedItems), options)
	else
		cancelItemsListRender()
		clearItemsListSelection()
		clearItemListWidgets()
		UI.SelectedItem.Sprite:setItemId(0)
		UI.SelectedItem.Rarity:setImageSource("")

		if options.onComplete then
			options.onComplete()
		end
	end

	if clearTextEdit then
		setSearchEditTextSilent("")
	end
end

local function isHandWeapon(id)
	if id >= 17 and id <= 21 or id == 1000 then
		return true
	end
end

function Cyclopedia.selectItemCategory(id)
	if not isHandWeapon(id) then
		setCheckedWithoutRecursion(false, false)
	end

	if normalizeSearchText(UI.SearchEdit:getText()) ~= "" then
		cancelItemsSearchDebounce()
		setSearchEditTextSilent("")
	end

	if Cyclopedia.hasClassificationFilter(id) then
		UI.ItemFilter:clearOptions()
		UI.ItemFilter:addOption("All", 0, true)
		UI.ItemFilter:addOption("None", -1, true)

		for class = 1, 4 do
			UI.ItemFilter:addOption("Class " .. class, class, true)
		end

		UI.ItemFilter:enable()
	else
		UI.ItemFilter:clearOptions()

		Cyclopedia.Items.ClassificationFilter = 0
	end

	processItemsById(id)

	if Cyclopedia.hasHandedFilter(id) then
		UI.H1Button:enable()
		UI.H2Button:enable()
	else
		UI.H1Button:disable()
		UI.H2Button:disable()
	end

	scheduleEvent(focusItemsSearchEdit, 0)
end

local function finalizeItemsIndex(tempItemList, generation)
	if generation ~= itemsIndexPreloadGeneration then
		return
	end

	table.sort(Cyclopedia.AllItemList, Cyclopedia.compareItems)

	local categories = {}

	for category, _ in pairs(tempItemList) do
		categories[#categories + 1] = category
	end

	local catIndex = 1

	local function sortNextCategory()
		if generation ~= itemsIndexPreloadGeneration then
			return
		end

		local endIndex = math.min(catIndex + 4, #categories)

		for i = catIndex, endIndex do
			local category = categories[i]
			local itemList = tempItemList[category]

			table.sort(itemList, Cyclopedia.compareItems)

			Cyclopedia.ItemList[category] = itemList
		end

		catIndex = endIndex + 1

		if catIndex <= #categories then
			itemsIndexPreloadEvent = addEvent(sortNextCategory)
		else
			itemsIndexPreloadEvent = nil
			Cyclopedia.ItemsIndexBuilt = true
			Cyclopedia.ItemsIndexPreloading = false
		end
	end

	if #categories == 0 then
		Cyclopedia.ItemsIndexBuilt = true
		Cyclopedia.ItemsIndexPreloading = false

		return
	end

	sortNextCategory()
end

local function buildItemsIndexChunked(forceSync)
	if Cyclopedia.ItemsIndexBuilt and Cyclopedia.AllItemList and #Cyclopedia.AllItemList > 0 then
		return
	end

	cancelItemsIndexPreload()

	local generation = itemsIndexPreloadGeneration

	Cyclopedia.ItemList = {}
	Cyclopedia.AllItemList = {}
	Cyclopedia.ItemsIndexPreloading = true

	local types

	if g_things.getCyclopediaItems then
		types = g_things.getCyclopediaItems()
	else
		types = g_things.getThingTypes(ThingCategoryItem)
	end

	local tempItemList = {}
	local total = #types

	if forceSync or total == 0 then
		for i = 1, total do
			local data = types[i]

			if data and (not data.isCyclopediaItem or data:isCyclopediaItem()) then
				local category = Cyclopedia.getItemListCategory(data)
				local name = Cyclopedia.getItemDisplayName(data)
				local entry = {
					thingType = data,
					id = data:getId(),
					name = name,
					nameLower = string.lower(name or ""),
					category = category
				}

				if not tempItemList[category] then
					tempItemList[category] = {}
				end

				Cyclopedia.AllItemList[#Cyclopedia.AllItemList + 1] = entry
				tempItemList[category][#tempItemList[category] + 1] = entry
			end
		end

		table.sort(Cyclopedia.AllItemList, Cyclopedia.compareItems)

		for category, itemList in pairs(tempItemList) do
			table.sort(itemList, Cyclopedia.compareItems)

			Cyclopedia.ItemList[category] = itemList
		end

		Cyclopedia.ItemsIndexBuilt = true
		Cyclopedia.ItemsIndexPreloading = false

		return
	end

	local index = 1

	local function processBatch()
		if generation ~= itemsIndexPreloadGeneration then
			return
		end

		local endIndex = math.min(index + ITEMS_INDEX_PRELOAD_BATCH - 1, total)

		for i = index, endIndex do
			local data = types[i]

			if data and (not data.isCyclopediaItem or data:isCyclopediaItem()) then
				local category = Cyclopedia.getItemListCategory(data)
				local name = Cyclopedia.getItemDisplayName(data)
				local entry = {
					thingType = data,
					id = data:getId(),
					name = name,
					nameLower = string.lower(name or ""),
					category = category
				}

				if not tempItemList[category] then
					tempItemList[category] = {}
				end

				Cyclopedia.AllItemList[#Cyclopedia.AllItemList + 1] = entry
				tempItemList[category][#tempItemList[category] + 1] = entry
			end
		end

		index = endIndex + 1

		if index <= total then
			itemsIndexPreloadEvent = addEvent(processBatch)
		else
			itemsIndexPreloadEvent = nil

			finalizeItemsIndex(tempItemList, generation)
		end
	end

	processBatch()
end

function Cyclopedia.startItemsIndexPreload()
	if Cyclopedia.ItemsIndexBuilt and Cyclopedia.AllItemList and #Cyclopedia.AllItemList > 0 then
		return
	end

	if Cyclopedia.ItemsIndexPreloading then
		return
	end

	if not g_game.isOnline() then
		return
	end

	buildItemsIndexChunked(false)
end

function Cyclopedia.scheduleItemsIndexPreload()
	if itemsIndexPreloadScheduled then
		removeEvent(itemsIndexPreloadScheduled)

		itemsIndexPreloadScheduled = nil
	end

	itemsIndexPreloadScheduled = scheduleEvent(function()
		itemsIndexPreloadScheduled = nil

		if g_game.isOnline() then
			Cyclopedia.startItemsIndexPreload()
		end
	end, ITEMS_INDEX_PRELOAD_DELAY_MS)
end

function Cyclopedia.loadItemsCategories()
	if Cyclopedia.ItemsIndexBuilt and Cyclopedia.AllItemList and #Cyclopedia.AllItemList > 0 then
		return
	end

	buildItemsIndexChunked(true)
end

function Cyclopedia.FillItemList()
	local types = g_things.findThingTypeByAttr(ThingAttrMarket, 0)

	for i = 1, #types do
		local itemType = types[i]
		local item = Item.create(itemType:getId())

		if item then
			local marketData = itemType:getMarketData()

			if not table.empty(marketData) then
				item:setId(marketData.showAs)

				local marketItem = {
					displayItem = item,
					thingType = itemType,
					marketData = marketData
				}

				if Cyclopedia.ItemList[marketData.category] ~= nil then
					table.insert(Cyclopedia.ItemList[marketData.category], marketItem)
				end
			end
		end
	end
end

function Cyclopedia.loadItemDetail(itemId, descriptions)
	if not UI or UI:isDestroyed() or not UI.InfoBase then
		return
	end

	UI.InfoBase.DetailsBase.List:destroyChildren()

	local internalData = g_things.getThingType(itemId, ThingCategoryItem)

	if not internalData then
		return
	end

	descriptions = descriptions or {}

	g_logger.info(string.format("[cyc-items] loadItemDetail itemId=%s opisow=%d listaSzerokosc=%s",
		tostring(itemId), #descriptions, tostring(UI.InfoBase.DetailsBase.List:getWidth())))

	for _, description in ipairs(descriptions) do
		local key = description.key or description[1] or ""
		local value = description.value or description[2] or ""
		Cyclopedia.appendDetailKeyValueRow(UI.InfoBase.DetailsBase.List, tostring(key), tostring(value))
	end
end

function Cyclopedia.openItemInCyclopedia(itemId)
	itemId = tonumber(itemId) or 0

	if itemId <= 0 then
		return false
	end

	local itemType = g_things.getThingType(itemId, ThingCategoryItem)

	if not itemType or not itemType:isCyclopediaItem() then
		return false
	end

	SelectWindow("items")

	if not UI then
		return false
	end

	Cyclopedia.loadItemsCategories()

	local displayName = Cyclopedia.getItemDisplayName(itemType)
	local singleEntry = {
		thingType = itemType,
		id = itemId,
		name = displayName,
		nameLower = string.lower(displayName or ""),
		category = Cyclopedia.getItemListCategory(itemType)
	}

	renderItemEntries({
		singleEntry
	}, {
		sync = true
	})

	local selectedWidget

	if itemsVirtualMode and itemsVirtualPool[1] then
		selectedWidget = itemsVirtualPool[1]
	elseif UI.ItemListBase and UI.ItemListBase.List then
		local children = UI.ItemListBase.List:getChildren()

		selectedWidget = children and children[1] or nil
	end

	if selectedWidget and selectedWidget.onClick then
		selectedWidget.onClick(selectedWidget)

		return true
	end

	UI.EmptyLabel:setVisible(false)
	UI.InfoBase:setVisible(true)
	UI.SelectedItem.Sprite:setItemId(itemId)
	UI.SelectedItem.Rarity:setImageSource("")
	UI.InfoBase.ResultGoldBase.Value:setText(Cyclopedia.formatGold(0))
	UI.InfoBase.ResultGoldBase.Rarity:setImageSource("")

	if g_game.isOnline() then
		g_game.inspectionObject(3, itemId, 1)
	end

	return true
end
