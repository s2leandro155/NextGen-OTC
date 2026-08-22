-- chunkname: @/game_npcmodal/game_npcmodal.lua
local updateNpcTradePlayerBalanceLabel -- forward declaration (used before its declaration in the decompiled file)

mainNpcModal = nil
BuyNpcTradeItems = {}
SellNpcTradeItems = {}
playerItems = {}
npcOutfit = nil
multiNpc = nil
npcNameLabel = nil

local sayButtonsActive = {}
local NPC_MODAL_MIN_W = 307
local NPC_MODAL_MIN_H = 332
local NPC_MODAL_MAX_W = 837
local NPC_MODAL_MAX_H = 653
local NPC_MODAL_DEFAULT_W = 439
local NPC_MODAL_DEFAULT_H = 424
local MINIBORDER_RESIZE_CURSOR = "diagonal-nw"
local npcModalResizeState
local NPC_MODAL_DRAG_MOVE_OPACITY = 0.8
local NPC_MODAL_TRADE_EXTRA_W = 204
local npcModalTrade = false
local LOOT_POUCH_ITEM_ID = 23721
local GOLD_COIN_ITEM_ID = 3031
local npcTradeCurrencyId, menuButton, sep1, label1, currencyName, item, buyButton, sellButton, itemsSelling, searchEdit, clearSearch, countScrollBar, label3, label4, label5, labelPrice, playerBalance, userInput, item2, BuySellButton
local npcTradeFilterText = ""
local NPC_MODAL_SETTINGS_FILE = "/settings/npc_modal.json"
local sortByName = true
local sortByPrice = false
local sortByWeight = false
local buyInShoppingBags = false
local ignoreCapacity = false
local sellEquipped = false
local showSearchField = true
local doNotShowWarningLargeAmounts = true
local npcTradeSelectedEntry, npcTradeLookThing
local npcTradeCurrentUnitPrice = 0
local npcTradeQuantity = 0
local sellAllModal, sellAllButton, sellAllPendingEvent

lootPouchItems = {}
sellAllIgnoredItems = {}

local FilterText2 = ""
local FilterText3 = ""

local function isSameNpcTradeItem(itemA, itemB)
	if not itemA or not itemB then
		return false
	end

	if itemA:getId() ~= itemB:getId() then
		return false
	end

	return itemA:getSubType() == itemB:getSubType()
end

local function setNpcTradeItemIcon(icon, item)
	if not icon or not item or not item:getId() or item:getId() == 0 then
		return
	end

	icon:setItem(Item.create(item:getId(), item:getCountOrSubType()))
end

local function updateNpcTradeItem2QuantityPreview(quantity)
	local item2w = mainNpcModal and mainNpcModal:recursiveGetChildById("item2")

	if not item2w or item2w:isDestroyed() or not npcTradeSelectedEntry then
		return
	end

	local tradeItem = npcTradeSelectedEntry.item

	if tradeItem:isFluidContainer() then
		return
	end

	local isChargeable = false
	local itemType = g_things.getThingType(tradeItem:getId(), ThingCategoryItem)

	if itemType then
		isChargeable = itemType:isChargeable()
	end

	if tradeItem:isStackable() or isChargeable then
		if quantity < 1 then
			return
		end

		item2w:setItemCount(quantity)
	end
end

local function wireEscapeToClose(widget, onEscape)
	if not widget or widget:isDestroyed() then
		return
	end

	function widget:onKeyDown(keyCode, keyboardModifiers)
		if keyboardModifiers == KeyboardNoModifier and keyCode == KeyEscape then
			onEscape()

			return true
		end

		return false
	end

	local function wireTextEditChildren(parent)
		if not parent or parent:isDestroyed() then
			return
		end

		if parent.getClassName and parent:getClassName() == "UITextEdit" then
			connect(parent, {
				onKeyDown = function(_, keyCode, keyboardModifiers)
					if keyboardModifiers == KeyboardNoModifier and keyCode == KeyEscape then
						onEscape()

						return true
					end

					return false
				end
			})
		end

		for _, child in ipairs(parent:getChildren()) do
			wireTextEditChildren(child)
		end
	end

	wireTextEditChildren(widget)
end

local function capitalizeWords(str)
	return (str:gsub("(%a)([%w_']*)", function(first, rest)
		return first:upper() .. rest:lower()
	end))
end

local function formatNumberWithCommas(n)
	local s = tostring(n)
	local pos = string.len(s) % 3

	if pos == 0 then
		pos = 3
	end

	local t = s:sub(1, pos)

	for i = pos + 1, #s, 3 do
		t = t .. "," .. s:sub(i, i + 2)
	end

	return t
end

local function getPlayerMoney()
	local player = g_game.getLocalPlayer()

	if not player then
		return 0
	end

	return player:getTotalMoney() or 0
end

local function isNpcTradeGoldCurrency()
	return npcTradeCurrencyId == nil or npcTradeCurrencyId == GOLD_COIN_ITEM_ID
end

local function getNpcTradeBalance()
	local player = g_game.getLocalPlayer()

	if not player then
		return 0
	end

	if isNpcTradeGoldCurrency() then
		return player:getTotalMoney() or 0
	end

	if npcTradeCurrencyId == 0 then
		return player:getResourceBalance(ResourceTypes.NPC_CURRENCY_AMOUNT) or 0
	end

	local balance = player:getResourceBalance(ResourceTypes.CURRENCY_CUSTOM_EQUIPPED) or 0

	if player.getInventoryCount then
		local inventoryCount = player:getInventoryCount(npcTradeCurrencyId, 0) or 0

		return math.max(balance, inventoryCount)
	end

	return balance
end

local function playerHasLootPouch()
	local player = g_game.getLocalPlayer()

	if player and player.getInventoryCount and player:getInventoryCount(LOOT_POUCH_ITEM_ID, 0) > 0 then
		return true
	end

	if g_game.findPlayerItem and g_game.findPlayerItem(LOOT_POUCH_ITEM_ID, -1, 0) then
		return true
	end

	return next(lootPouchItems) ~= nil
end

local function refreshSellAllButtonVisibility()
	if not sellAllButton or sellAllButton:isDestroyed() then
		return
	end

	sellAllButton:setVisible(npcModalTrade and playerHasLootPouch())
end

local function getEquippedItemCounts()
	local counts = {}
	local player = g_game.getLocalPlayer()

	if not player then
		return counts
	end

	local firstSlot = InventorySlotFirst or 1
	local lastSlot = InventorySlotLast or 10

	for slot = firstSlot, lastSlot do
		local invItem = player:getInventoryItem(slot)

		if invItem then
			local id = invItem:getId()
			local qty = invItem:getCount() or 1

			if qty < 1 then
				qty = 1
			end

			counts[id] = (counts[id] or 0) + qty
		end
	end

	return counts
end

local function getSellablePlayerItemCount(itemId)
	local total = playerItems and playerItems[itemId] or 0

	if total <= 0 then
		return 0
	end

	if sellEquipped then
		return total
	end

	local equipped = getEquippedItemCounts()[itemId] or 0
	local effective = total - equipped

	if effective < 0 then
		effective = 0
	end

	return effective
end

local function saveNpcModalSettings()
	if not mainNpcModal or mainNpcModal:isDestroyed() then
		return
	end

	pcall(function()
		if not g_resources.directoryExists("/settings/") then
			g_resources.makeDir("/settings/")
		end
	end)

	local data = {}

	if g_resources.fileExists(NPC_MODAL_SETTINGS_FILE) then
		local ok, decoded = pcall(function()
			return json.decode(g_resources.readFileContents(NPC_MODAL_SETTINGS_FILE))
		end)

		if ok and type(decoded) == "table" then
			data = decoded
		end
	end

	local pos = mainNpcModal:getPosition()
	local size = mainNpcModal:getSize()
	local saveW = size.width

	if npcModalTrade then
		saveW = saveW - NPC_MODAL_TRADE_EXTRA_W
	end

	saveW = math.min(NPC_MODAL_MAX_W, math.max(NPC_MODAL_MIN_W, saveW))

	local saveH = math.min(NPC_MODAL_MAX_H, math.max(NPC_MODAL_MIN_H, size.height))

	data.npcDialogOptions = {
		x = pos.x,
		y = pos.y,
		width = saveW,
		height = saveH
	}

	local ok, serialized = pcall(function()
		return json.encode(data, 2)
	end)

	if ok and serialized then
		pcall(function()
			g_resources.writeFileContents(NPC_MODAL_SETTINGS_FILE, serialized)
		end)
	end
end

local function loadNpcModalSettings()
	if not mainNpcModal or mainNpcModal:isDestroyed() then
		return
	end

	if not g_resources.fileExists(NPC_MODAL_SETTINGS_FILE) then
		return
	end

	local ok, decoded = pcall(function()
		return json.decode(g_resources.readFileContents(NPC_MODAL_SETTINGS_FILE))
	end)

	if ok and type(decoded) == "table" then
		local settingsData = decoded
		local npcOpts = settingsData.npcDialogOptions

		if not npcOpts and settingsData.height and tonumber(settingsData.height) then
			npcOpts = settingsData
		end

		if npcOpts then
			local nx = tonumber(npcOpts.x)
			local ny = tonumber(npcOpts.y)
			local hasPos = nx ~= nil and ny ~= nil

			if hasPos then
				mainNpcModal:breakAnchors()
			end

			local w = tonumber(npcOpts.width)
			local h = tonumber(npcOpts.height)
			local validW = w and w >= NPC_MODAL_MIN_W and w <= NPC_MODAL_MAX_W
			local validH = h and h >= NPC_MODAL_MIN_H and h <= NPC_MODAL_MAX_H

			if validW and validH then
				mainNpcModal:setWidth(w)
				mainNpcModal:setHeight(h)
			else
				mainNpcModal:setWidth(NPC_MODAL_DEFAULT_W)
				mainNpcModal:setHeight(NPC_MODAL_DEFAULT_H)
			end

			if hasPos then
				mainNpcModal:setPosition({
					x = nx,
					y = ny
				})
				mainNpcModal:bindRectToParent()
			end
		end

		return decoded
	end

	return nil
end

local function sellAllGetCharacterName()
	local p = g_game.getLocalPlayer()

	if not p then
		return nil
	end

	local ok, name = pcall(function()
		return p:getName()
	end)

	if ok and type(name) == "string" and name ~= "" then
		return name
	end

	return nil
end

local function saveSellAllIgnoreList()
	pcall(function()
		if not g_resources.directoryExists("/settings/") then
			g_resources.makeDir("/settings/")
		end
	end)

	local data = {}

	if g_resources.fileExists(NPC_MODAL_SETTINGS_FILE) then
		local ok, decoded = pcall(function()
			return json.decode(g_resources.readFileContents(NPC_MODAL_SETTINGS_FILE))
		end)

		if ok and type(decoded) == "table" then
			data = decoded
		end
	end

	local characterName = sellAllGetCharacterName()

	if not characterName then
		return
	end

	local ids = {}
	local seen = {}

	for itemId, active in pairs(sellAllIgnoredItems) do
		local id = tonumber(itemId)

		if id and active == true and not seen[id] then
			seen[id] = true

			table.insert(ids, id)
		end
	end

	table.sort(ids)

	local byIds = data.sellAllIgnoreIdsByCharacter

	if type(byIds) ~= "table" then
		byIds = {}
		data.sellAllIgnoreIdsByCharacter = byIds
	end

	byIds[characterName] = ids

	local legacyByChar = data.sellAllIgnoreListByCharacter

	if type(legacyByChar) == "table" then
		legacyByChar[characterName] = nil

		if next(legacyByChar) == nil then
			data.sellAllIgnoreListByCharacter = nil
		end
	end

	data.sellAllIgnoreList = nil

	local ok, serialized = pcall(function()
		return json.encode(data, 2)
	end)

	if ok and serialized then
		pcall(function()
			g_resources.writeFileContents(NPC_MODAL_SETTINGS_FILE, serialized)
		end)
	end
end

local function loadSellAllIgnoreList()
	for k in pairs(sellAllIgnoredItems) do
		sellAllIgnoredItems[k] = nil
	end

	local characterName = sellAllGetCharacterName()

	if not characterName then
		return
	end

	if not g_resources.fileExists(NPC_MODAL_SETTINGS_FILE) then
		return
	end

	local ok, decoded = pcall(function()
		return json.decode(g_resources.readFileContents(NPC_MODAL_SETTINGS_FILE))
	end)

	if not ok or type(decoded) ~= "table" then
		return
	end

	local function tableNonempty(t)
		return type(t) == "table" and next(t) ~= nil
	end

	local needResaveFormat = false
	local mergedIds = {}
	local got = {}

	local function addIgnoredId(itId)
		itId = tonumber(itId)

		if itId and not got[itId] then
			got[itId] = true
			mergedIds[#mergedIds + 1] = itId
		end
	end

	local byIds = decoded.sellAllIgnoreIdsByCharacter

	if type(byIds) == "table" and tableNonempty(byIds[characterName]) then
		local block = byIds[characterName]

		if #block > 0 then
			for _, v in ipairs(block) do
				addIgnoredId(v)
			end
		elseif next(block) then
			for _, v in pairs(block) do
				addIgnoredId(v)
			end
		end
	end

	local legacyQtyByChar = decoded.sellAllIgnoreListByCharacter
	local hasLegacyQtyForChar = type(legacyQtyByChar) == "table" and tableNonempty(legacyQtyByChar[characterName])

	if hasLegacyQtyForChar then
		needResaveFormat = true

		for k in pairs(legacyQtyByChar[characterName]) do
			addIgnoredId(k)
		end
	end

	local hasPersonalIdsLoaded = #mergedIds > 0 or hasLegacyQtyForChar
	local globalLegacy = decoded.sellAllIgnoreList

	if not hasPersonalIdsLoaded and type(globalLegacy) == "table" and next(globalLegacy) ~= nil then
		needResaveFormat = true

		for k, amt in pairs(globalLegacy) do
			if tonumber(amt) and tonumber(amt) > 0 then
				addIgnoredId(k)
			end
		end
	end

	table.sort(mergedIds)

	for _, itId in ipairs(mergedIds) do
		sellAllIgnoredItems[itId] = true
	end

	if needResaveFormat then
		saveSellAllIgnoreList()
	end
end

local refreshNpcTradeItemList, revalidateNpcTradeQuantity

local function onNpcModalFreeCapacityChange(player, freeCapacity)
	if not npcModalTrade then
		return
	end

	if not mainNpcModal or mainNpcModal:isDestroyed() then
		return
	end

	revalidateNpcTradeQuantity()
end

local function onNpcModalInventoryChange(player, slot, item, oldItem)
	if not npcModalTrade then
		return
	end

	if not mainNpcModal or mainNpcModal:isDestroyed() then
		return
	end

	refreshNpcTradeItemList()
	revalidateNpcTradeQuantity()
	refreshSellAllButtonVisibility()

	if not isNpcTradeGoldCurrency() and npcTradeCurrencyId ~= 0 then
		updateNpcTradePlayerBalanceLabel()
	end
end

local function onNpcModalContainerChange()
	if not npcModalTrade then
		return
	end

	refreshSellAllButtonVisibility()

	if not isNpcTradeGoldCurrency() and npcTradeCurrencyId ~= 0 then
		updateNpcTradePlayerBalanceLabel()
	end
end

local function bindNpcModalPlayerInventoryListener()
	local player = g_game.getLocalPlayer()

	if not player then
		return
	end

	disconnect(player, {
		onInventoryChange = onNpcModalInventoryChange
	})
	connect(player, {
		onInventoryChange = onNpcModalInventoryChange
	})
end

local function unbindNpcModalPlayerInventoryListener()
	local player = g_game.getLocalPlayer()

	if not player then
		return
	end

	disconnect(player, {
		onInventoryChange = onNpcModalInventoryChange
	})
end

local function npcModalOnSellAllGameStart()
	lootPouchItems = {}

	refreshSellAllButtonVisibility()
	loadSellAllIgnoreList()
	bindNpcModalPlayerInventoryListener()
	addEvent(bindNpcModalPlayerInventoryListener)
end

local function updateNpcTradePriceLabel(price)
	if not mainNpcModal or mainNpcModal:isDestroyed() then
		return
	end

	local labelPrice = mainNpcModal:recursiveGetChildById("labelPrice")

	if not labelPrice or labelPrice:isDestroyed() then
		return
	end

	local priceToShow = 0

	if price and price > 0 then
		priceToShow = price
	end

	labelPrice:setText(formatNumberWithCommas(priceToShow))
end

local function getNpcTradeSelectedBuyEntry()
	if not npcTradeSelectedEntry or not buyButton or not buyButton:isOn() then
		return nil
	end

	return npcTradeSelectedEntry
end

local function getNpcTradeCapacityMaxBuyCount()
	if ignoreCapacity then
		return 10000
	end

	local player = g_game.getLocalPlayer()

	if not player then
		return 0
	end

	local entry = getNpcTradeSelectedBuyEntry()
	local weight = entry and entry.weight or 0

	if weight <= 0 then
		return 10000
	end

	local freeCapacity = player:getFreeCapacity() or 0

	return math.floor(freeCapacity / weight)
end

local function computeNpcTradeQuantityRange()
	if not npcTradeSelectedEntry or (npcTradeCurrentUnitPrice or 0) <= 0 then
		return 0, 0
	end

	if not buyButton or not countScrollBar then
		return 1, 1
	end

	local unit = npcTradeCurrentUnitPrice

	if buyButton:isOn() then
		local playerMoney = getNpcTradeBalance()
		local moneyMax = math.floor(playerMoney / unit)
		local capacityMax = getNpcTradeCapacityMaxBuyCount()
		local q = math.min(moneyMax, capacityMax)

		if q < 1 then
			return 0, 0
		end

		return 1, math.min(q, 10000)
	else
		local itemCount = getSellablePlayerItemCount(npcTradeSelectedEntry.item:getId())

		if itemCount < 1 then
			return 0, 0
		end

		return 1, math.min(itemCount, 10000)
	end
end

local function isNpcTradeQuantityAvailable()
	return npcTradeSelectedEntry ~= nil and (npcTradeCurrentUnitPrice or 0) > 0
end

local function setNpcTradeAmountScrollRange(scrollBar, minVal, maxVal)
	if not scrollBar or scrollBar:isDestroyed() then
		return
	end

	scrollBar:setRange(minVal, maxVal)

	local slider = scrollBar:getChildById("sliderButton")

	if slider then
		slider:setVisible(minVal < maxVal and maxVal > 1)
	end
end

local function clearNpcTradeQuantity()
	npcTradeQuantity = 0

	if countScrollBar and not countScrollBar:isDestroyed() then
		setNpcTradeAmountScrollRange(countScrollBar, 0, 0)
		countScrollBar:setValue(0)
	end

	if userInput and not userInput:isDestroyed() then
		userInput:setText("")
	end
end

local function applyNpcTradeQuantity(n)
	if not countScrollBar or not userInput or countScrollBar:isDestroyed() or userInput:isDestroyed() or not npcModalTrade then
		return
	end

	if not isNpcTradeQuantityAvailable() then
		clearNpcTradeQuantity()
		updateNpcTradePriceLabel(nil)

		return
	end

	local minV, maxV = computeNpcTradeQuantityRange()

	if minV == 0 and maxV == 0 then
		clearNpcTradeQuantity()
		updateNpcTradePriceLabel(0)

		return
	end

	n = math.floor(tonumber(n) or 1)
	n = math.max(minV, math.min(maxV, n))

	setNpcTradeAmountScrollRange(countScrollBar, minV, maxV)
	countScrollBar:setValue(n)
	userInput:setText(tostring(n))
	updateNpcTradeItem2QuantityPreview(n)
	updateNpcTradePriceLabel(npcTradeCurrentUnitPrice * n)

	npcTradeQuantity = n
end

function revalidateNpcTradeQuantity()
	if not userInput or userInput:isDestroyed() then
		return
	end

	if not isNpcTradeQuantityAvailable() then
		clearNpcTradeQuantity()

		return
	end

	local n = tonumber(userInput:getText())

	n = n or 1

	applyNpcTradeQuantity(n)
end

updateNpcTradePlayerBalanceLabel = function()
	if not mainNpcModal or mainNpcModal:isDestroyed() or not npcModalTrade then
		return
	end

	local balanceLabel = mainNpcModal:recursiveGetChildById("playerBalance")

	if not balanceLabel or balanceLabel:isDestroyed() then
		return
	end

	if label5 and not label5:isDestroyed() then
		if isNpcTradeGoldCurrency() then
			label5:setText(tr("Gold:"))
		else
			label5:setText(tr("Stock:"))
		end
	end

	balanceLabel:setText(tr("%s", formatNumberWithCommas(getNpcTradeBalance())))

	if isNpcTradeQuantityAvailable() then
		revalidateNpcTradeQuantity()
	end
end

local function refreshNpcTradeCurrencyState()
	if not mainNpcModal or mainNpcModal:isDestroyed() or not npcModalTrade then
		return
	end

	updateNpcTradePlayerBalanceLabel()
	refreshNpcTradeItemList()
end

local function setupNpcTradeQuantityBindings()
	if not countScrollBar or not userInput then
		return
	end

	function countScrollBar:onValueChange(value, delta)
		if not isNpcTradeQuantityAvailable() then
			return
		end

		userInput:setText(tostring(value))
		updateNpcTradeItem2QuantityPreview(value)
		applyNpcTradeQuantity(value)
	end

	function userInput:onTextChange()
		local raw = self:getText() or ""

		if raw:len() == 0 then
			return
		end

		local n = tonumber(raw:match("^%d+"))

		if not n then
			if isNpcTradeQuantityAvailable() then
				applyNpcTradeQuantity(1)
			else
				clearNpcTradeQuantity()
			end

			return
		end

		applyNpcTradeQuantity(n)
	end
end

local function onNpcModalResourcesBalanceChange(value, oldBalance, resourceType)
	if not npcModalTrade then
		return
	end

	if isNpcTradeGoldCurrency() then
		if resourceType ~= ResourceTypes.BANK_BALANCE and resourceType ~= ResourceTypes.GOLD_EQUIPPED then
			return
		end
	elseif npcTradeCurrencyId == 0 then
		if resourceType ~= ResourceTypes.NPC_CURRENCY_AMOUNT then
			return
		end
	elseif resourceType ~= ResourceTypes.CURRENCY_CUSTOM_EQUIPPED then
		return
	end

	refreshNpcTradeCurrencyState()
end

local function setNpcTradeRowHighlight(panel, selectedBox)
	if not panel or panel:isDestroyed() then
		return
	end

	for _, child in pairs(panel:getChildren()) do
		if not child:isDestroyed() and child.setBackgroundColor then
			child:setBackgroundColor("#00000000")
		end
	end

	if selectedBox and not selectedBox:isDestroyed() and selectedBox.setBackgroundColor then
		selectedBox:setBackgroundColor("#585858")
	end
end

local function clearNpcTradeItem2Preview()
	if not mainNpcModal then
		return
	end

	npcTradeCurrentUnitPrice = 0

	local item2w = mainNpcModal:recursiveGetChildById("item2")

	if item2w and not item2w:isDestroyed() then
		item2w:clearItem()
	end

	updateNpcTradePriceLabel(nil)
	clearNpcTradeQuantity()
end

local function applyNpcTradeItem2Preview(entry, price)
	if not entry or not entry.item:getId() or entry.item:getId() == 0 then
		clearNpcTradeItem2Preview()

		return
	end

	if not mainNpcModal then
		return
	end

	local item2w = mainNpcModal:recursiveGetChildById("item2")

	if not item2w or item2w:isDestroyed() then
		return
	end

	setNpcTradeItemIcon(item2w, entry.item)

	npcTradeCurrentUnitPrice = price and price > 0 and price or 0

	if price and price > 0 then
		updateNpcTradePriceLabel(price)
	else
		updateNpcTradePriceLabel(nil)
	end

	if sellButton and sellButton:isOn() then
		local _, maxV = computeNpcTradeQuantityRange()

		applyNpcTradeQuantity(maxV > 0 and maxV or 1)
	else
		applyNpcTradeQuantity(1)
	end
end

local function shortenNpcTradeText(s, maxLen)
	s = tostring(s or "")

	if maxLen < 4 then
		return s
	end

	if maxLen >= #s then
		return s
	end

	return s:sub(1, maxLen - 3) .. "..."
end

local function hideTradeWindowChildrens()
	menuButton:hide()
	sep1:hide()
	label1:hide()
	currencyName:hide()
	item:hide()
	buyButton:hide()
	sellButton:hide()
	itemsSelling:hide()
	searchEdit:hide()
	countScrollBar:hide()
	clearSearch:hide()
	label3:hide()
	label4:hide()
	label5:hide()
	labelPrice:hide()
	playerBalance:hide()
	userInput:hide()
	item2:hide()
	BuySellButton:hide()
	sellAllButton:hide()
end

local function showTradeWindowChildrens()
	menuButton:show()
	sep1:show()
	label1:show()
	currencyName:show()
	item:show()
	buyButton:show()
	sellButton:show()
	itemsSelling:show()
	searchEdit:show()
	countScrollBar:show()
	clearSearch:show()
	label3:show()
	label4:show()
	label5:show()
	labelPrice:show()
	playerBalance:show()
	userInput:show()
	item2:show()
	BuySellButton:show()
	refreshSellAllButtonVisibility()
end

function refreshNpcTradeItemList()
	local panel = itemsSelling:getChildById("npcTradeItemsPanel")

	if panel then
		panel:destroyChildren()
	end

	local buying = buyButton:isOn()
	local items = buying and BuyNpcTradeItems or SellNpcTradeItems
	local rows = {}

	for _, entry in ipairs(items) do
		local price = buying and entry.buyPrice or entry.sellPrice
		local show = true

		if npcTradeFilterText ~= "" then
			local haystack = (entry.name or ""):lower()

			show = haystack:find(npcTradeFilterText, 1, true) ~= nil
		end

		if show then
			table.insert(rows, {
				entry = entry,
				price = price
			})
		end
	end

	if sortByName then
		table.sort(rows, function(a, b)
			local na = (a.entry.name or ""):lower()
			local nb = (b.entry.name or ""):lower()

			if na ~= nb then
				return na < nb
			end

			return (a.entry.item:getId() or 0) < (b.entry.item:getId() or 0)
		end)
	elseif sortByPrice then
		table.sort(rows, function(a, b)
			return a.price < b.price
		end)
	elseif sortByWeight then
		table.sort(rows, function(a, b)
			return a.entry.weight < b.entry.weight
		end)
	end

	if not buying then
		table.sort(rows, function(a, b)
			local idA, idB = a.entry.item:getId(), b.entry.item:getId()
			local hasA = getSellablePlayerItemCount(idA) > 0
			local hasB = getSellablePlayerItemCount(idB) > 0

			if hasA and not hasB then
				return true
			elseif not hasA and hasB then
				return false
			end

			if sortByName then
				local na = (a.entry.name or ""):lower()
				local nb = (b.entry.name or ""):lower()

				if na ~= nb then
					return na < nb
				end

				return idA < idB
			elseif sortByPrice then
				return a.price < b.price
			elseif sortByWeight then
				return a.entry.weight < b.entry.weight
			end

			return idA < idB
		end)
	end

	local selectedBox

	for _, row in ipairs(rows) do
		local entry = row.entry
		local price = row.price
		local box = g_ui.createWidget("NpcItemBox", panel)

		if box.setBackgroundColor then
			box:setBackgroundColor("#00000000")
		end

		if npcTradeSelectedEntry and isSameNpcTradeItem(entry.item, npcTradeSelectedEntry.item) then
			selectedBox = box
		end

		local icon = box:getChildById("itemIcon")

		if icon then
			setNpcTradeItemIcon(icon, entry.item)
		end

		local nameLbl = box:getChildById("nameLabel")
		local infoLbl = box:getChildById("infoLabel")
		local entryId = entry.item:getId()
		local sellableCount = not buying and getSellablePlayerItemCount(entryId) or 0
		local disabled = false

		if not buying then
			disabled = sellableCount <= 0
		elseif buying and price > getNpcTradeBalance() then
			disabled = true
		end

		if nameLbl then
			nameLbl:setText(shortenNpcTradeText(entry.name or "", 26))

			if disabled then
				nameLbl:setColor("#707070")
			end
		end

		if infoLbl then
			local line = tr("Price %d, %.2f oz", price, entry.weight or 0)

			infoLbl:setText(shortenNpcTradeText(line, 36))

			if disabled then
				infoLbl:setColor("#707070")
			end
		end

		local function onRowMousePress(widget, mousePos, mouseButton)
			if mouseButton ~= MouseLeftButton then
				if mouseButton == MouseRightButton then
					npcTradeLookThing = entry.item

					showMenuFilters(true)
				end

				return false
			end

			npcTradeSelectedEntry = entry

			applyNpcTradeItem2Preview(entry, price)
			setNpcTradeRowHighlight(panel, box)

			return true
		end

		box.onMousePress = onRowMousePress

		if icon then
			icon.onMousePress = onRowMousePress
		end

		if nameLbl then
			nameLbl.onMousePress = onRowMousePress
		end

		if infoLbl then
			infoLbl.onMousePress = onRowMousePress
		end
	end

	if npcTradeSelectedEntry then
		if selectedBox then
			for _, row in ipairs(rows) do
				if isSameNpcTradeItem(row.entry.item, npcTradeSelectedEntry.item) then
					applyNpcTradeItem2Preview(row.entry, row.price)

					break
				end
			end
		else
			npcTradeSelectedEntry = nil

			clearNpcTradeItem2Preview()
		end
	end

	setNpcTradeRowHighlight(panel, selectedBox)
	addEvent(function()
		if not itemsSelling or itemsSelling:isDestroyed() then
			return
		end

		local sb = itemsSelling:getChildById("npcTradeItemsScrollBar")
		local p = itemsSelling:getChildById("npcTradeItemsPanel")

		if not sb or not p or p:isDestroyed() then
			return
		end

		if p.updateScrollBars then
			p:updateScrollBars()
		end

		sb:setValue(sb:getMinimum())
	end)
end

function search(text, type)
	if text == nil and mainNpcModal then
		local w

		if type == 1 then
			w = mainNpcModal:recursiveGetChildById("search")
		elseif type == 2 then
			w = sellAllModal:recursiveGetChildById("search2")
		elseif type == 3 then
			w = sellAllModal:recursiveGetChildById("search3")
		end

		text = w and w:getText() or ""
	end

	text = tostring(text or ""):lower():trim()

	if type == 1 then
		npcTradeFilterText = text

		refreshNpcTradeItemList()
	elseif type == 2 then
		FilterText2 = text

		refreshSellAllModalLists()
	elseif type == 3 then
		FilterText3 = text

		refreshSellAllModalLists()
	end
end

function clearTradeSearch(type)
	if type == 1 then
		if mainNpcModal then
			local w = mainNpcModal:recursiveGetChildById("search")

			if w then
				w:clearText()
			end
		end

		npcTradeFilterText = ""

		refreshNpcTradeItemList()
	elseif type == 2 then
		if sellAllModal then
			local w = sellAllModal:recursiveGetChildById("search2")

			if w then
				w:clearText()
			end
		end

		FilterText2 = ""

		refreshSellAllModalLists()
	elseif type == 3 then
		if sellAllModal then
			local w = sellAllModal:recursiveGetChildById("search3")

			if w then
				w:clearText()
			end
		end

		FilterText3 = ""

		refreshSellAllModalLists()
	end
end

function onNpcTradeBuyClick()
	buyButton:setOn(true)
	sellButton:setOn(false)
	BuySellButton:setText(tr("Buy"))
	refreshNpcTradeItemList()
end

function onNpcTradeSellClick()
	sellButton:setOn(true)
	buyButton:setOn(false)
	BuySellButton:setText(tr("Sell"))
	refreshNpcTradeItemList()
end

function onConfirmTrade()
	if not npcTradeSelectedEntry or not npcTradeSelectedEntry.item or npcTradeSelectedEntry.item:getId() == 0 then
		return
	end

	local item = npcTradeSelectedEntry.item
	local amount = math.floor(npcTradeQuantity or 0)

	if amount < 1 then
		return
	end

	amount = math.min(amount, 65535)

	if buyButton:isOn() then
		local itemPrice = npcTradeSelectedEntry.buyPrice or 0
		local totalPrice = itemPrice * amount
		local playerMoney = getNpcTradeBalance()

		if playerMoney < totalPrice then
			return
		end

		if not ignoreCapacity then
			local capacityMax = getNpcTradeCapacityMaxBuyCount()

			if capacityMax < amount then
				return
			end
		end

		g_game.buyItem(item, amount, ignoreCapacity, buyInShoppingBags)
	else
		local itemCount = playerItems and playerItems[item:getId()] or 0

		if not itemCount or itemCount < amount then
			return
		end

		g_game.sellItem(item, amount, not sellEquipped)

		if buyButton:isOn() or not itemCount or itemCount ~= amount or not mainNpcModal then
			return
		end

		local npcTradeItemsPanel = mainNpcModal:recursiveGetChildById("itemsSelling"):getChildById("npcTradeItemsPanel")

		if npcTradeItemsPanel then
			for _, child in ipairs(npcTradeItemsPanel:getChildren()) do
				local itemIcon = child:getChildById("itemIcon")

				if itemIcon and npcTradeSelectedEntry and isSameNpcTradeItem(itemIcon:getItem(), npcTradeSelectedEntry.item) then
					local nameLabel = child:getChildById("nameLabel")

					nameLabel:setColor("#707070")

					local priceLabel = child:getChildById("infoLabel")

					priceLabel:setColor("#707070")

					break
				end
			end
		end

		revalidateNpcTradeQuantity()
	end
end

function onMiniborderRightHover(widget, hovered)
	if hovered then
		if g_mouse.isCursorChanged() or g_mouse.isPressed() then
			return
		end

		g_mouse.pushCursor(MINIBORDER_RESIZE_CURSOR)

		widget._npcModalMiniborderHover = true
	elseif not widget:isPressed() and widget._npcModalMiniborderHover then
		g_mouse.popCursor(MINIBORDER_RESIZE_CURSOR)

		widget._npcModalMiniborderHover = false
	end
end

local function setupNpcModalResizeGrip()
	local grip = mainNpcModal and mainNpcModal:recursiveGetChildById("miniborderRight")

	if not grip then
		return
	end

	function grip.onMousePress(widget, mousePos, mouseButton)
		if mouseButton ~= MouseLeftButton then
			return false
		end

		local win = widget:getParent()

		npcModalResizeState = {
			startX = mousePos.x,
			startY = mousePos.y,
			w0 = win:getWidth(),
			h0 = win:getHeight(),
			window = win
		}

		return true
	end

	function grip.onMouseMove(widget, mousePos, mouseMoved)
		if not npcModalResizeState then
			return false
		end

		local s = npcModalResizeState
		local win = s.window

		if not win then
			npcModalResizeState = nil

			return false
		end

		local dx = mousePos.x - s.startX
		local dy = mousePos.y - s.startY
		local nw = math.min(NPC_MODAL_MAX_W, math.max(npcModalTrade and 509 or NPC_MODAL_MIN_W, s.w0 + dx))
		local nh = math.min(NPC_MODAL_MAX_H, math.max(NPC_MODAL_MIN_H, s.h0 + dy))

		win:setWidth(nw)
		win:setHeight(nh)
		win:bindRectToParent()

		return true
	end

	function grip.onMouseRelease(widget, mousePos, mouseButton)
		if npcModalResizeState then
			npcModalResizeState = nil
		end

		if not widget:isHovered() and widget._npcModalMiniborderHover then
			g_mouse.popCursor(MINIBORDER_RESIZE_CURSOR)

			widget._npcModalMiniborderHover = false
		end

		saveNpcModalSettings()

		return false
	end
end

local function setupNpcModalWindowHeaderDrag()
	if not mainNpcModal or mainNpcModal:isDestroyed() then
		return
	end

	mainNpcModal:setDraggable(false)

	local header = mainNpcModal:recursiveGetChildById("windowMoveHeader")

	if not header or header:isDestroyed() then
		return
	end

	header:setDraggable(true)

	function header:onDragEnter(mousePos)
		local win = self:getParent()

		if not win or win:isDestroyed() then
			return false
		end

		win._npcModalOpacityBeforeDrag = win:getOpacity()

		win:setOpacity(NPC_MODAL_DRAG_MOVE_OPACITY)
		win:breakAnchors()

		win.movingReference = {
			x = mousePos.x - win:getX(),
			y = mousePos.y - win:getY()
		}

		return true
	end

	function header:onDragMove(mousePos, mouseMoved)
		local win = self:getParent()

		if not win or win:isDestroyed() or not win.movingReference then
			return false
		end

		local pos = {
			x = mousePos.x - win.movingReference.x,
			y = mousePos.y - win.movingReference.y
		}

		win:setPosition(pos)
		win:bindRectToParent()

		return true
	end

	function header:onDragLeave(droppedWidget, mousePos)
		local win = self:getParent()

		if win and not win:isDestroyed() then
			win.movingReference = nil

			if win._npcModalOpacityBeforeDrag ~= nil then
				win:setOpacity(win._npcModalOpacityBeforeDrag)

				win._npcModalOpacityBeforeDrag = nil
			end
		end

		saveNpcModalSettings()

		return true
	end
end

local function npcIconClip(index, row)
	row = row or 0

	return string.format("%d %d %d %d", index * 35, row * 35, 35, 35)
end

local imageClips = {
	[0] = {
		normal = npcIconClip(0, 0),
		pressed = npcIconClip(0, 1)
	},
	{
		normal = npcIconClip(1, 0),
		pressed = npcIconClip(1, 1)
	},
	{
		normal = npcIconClip(2, 0),
		pressed = npcIconClip(2, 1)
	},
	{
		normal = npcIconClip(3, 0),
		pressed = npcIconClip(3, 1)
	},
	{
		normal = npcIconClip(4, 0),
		pressed = npcIconClip(4, 1)
	},
	{
		normal = npcIconClip(5, 0),
		pressed = npcIconClip(5, 1)
	},
	{
		normal = npcIconClip(6, 0),
		pressed = npcIconClip(6, 1)
	},
	{
		normal = npcIconClip(7, 0),
		pressed = npcIconClip(7, 1)
	},
	{
		normal = npcIconClip(8, 0),
		pressed = npcIconClip(8, 1)
	},
	{
		normal = npcIconClip(9, 0),
		pressed = npcIconClip(9, 1)
	}
}

function setWindowOpacity(opacity)
	if mainNpcModal then
		mainNpcModal:setOpacity(opacity)
	end
end

function init()
	g_ui.importStyle("game_npcmodal")
	connect(g_game, {
		onGameStart = npcModalOnSellAllGameStart,
		onGameEnd = closeNpcModal,
		onNpcChatWindow = sendNpcModal,
		onOpenNpcTrade = sendNpcTrade,
		onCloseNpcTrade = onCloseNpcTrade,
		onResourcesBalanceChange = onNpcModalResourcesBalanceChange,
		onPlayerGoods = onPlayerGoods
	})
	connect(LocalPlayer, {
		onInventoryChange = onNpcModalInventoryChange,
		onFreeCapacityChange = onNpcModalFreeCapacityChange
	})
	connect(Container, {
		onAddItem = onNpcModalContainerChange,
		onUpdateItem = onNpcModalContainerChange,
		onRemoveItem = onNpcModalContainerChange
	})

	mainNpcModal = g_ui.createWidget("NpcModalWindow", rootWidget)

	setupNpcModalWindowHeaderDrag()

	npcOutfit = mainNpcModal:recursiveGetChildById("npcCreatureBox")
	multiNpc = mainNpcModal:recursiveGetChildById("multipleNpc")
	npcNameLabel = mainNpcModal:recursiveGetChildById("npcName")

	mainNpcModal:hide()
	npcOutfit:hide()
	multiNpc:hide()
	npcNameLabel:hide()

	function mainNpcModal.onFocusChange(widget, focused)
		if focused then
			setWindowOpacity(1)
		else
			setWindowOpacity(0.9)
		end
	end

	setupNpcModalResizeGrip()

	menuButton = mainNpcModal:recursiveGetChildById("menuButton")
	sep1 = mainNpcModal:recursiveGetChildById("sep1")
	label1 = mainNpcModal:recursiveGetChildById("label1")
	currencyName = mainNpcModal:recursiveGetChildById("currencyName")
	item = mainNpcModal:recursiveGetChildById("item")
	buyButton = mainNpcModal:recursiveGetChildById("buyButton")
	sellButton = mainNpcModal:recursiveGetChildById("sellButton")
	itemsSelling = mainNpcModal:recursiveGetChildById("itemsSelling")
	searchEdit = mainNpcModal:recursiveGetChildById("search")
	clearSearch = mainNpcModal:recursiveGetChildById("clearSearch")
	countScrollBar = mainNpcModal:recursiveGetChildById("countScrollBar")
	label3 = mainNpcModal:recursiveGetChildById("label3")
	label4 = mainNpcModal:recursiveGetChildById("label4")
	label5 = mainNpcModal:recursiveGetChildById("label5")
	labelPrice = mainNpcModal:recursiveGetChildById("labelPrice")
	playerBalance = mainNpcModal:recursiveGetChildById("playerBalance")
	userInput = mainNpcModal:recursiveGetChildById("userInput")
	item2 = mainNpcModal:recursiveGetChildById("item2")
	BuySellButton = mainNpcModal:recursiveGetChildById("BuySellButton")
	sellAllButton = mainNpcModal:recursiveGetChildById("sellAllButton")

	hideTradeWindowChildrens()
	setupNpcTradeQuantityBindings()
	loadNpcModalSettings()

	sellAllModal = g_ui.createWidget("SellAllModalWindow", rootWidget)

	sellAllModal:hide()
	wireEscapeToClose(mainNpcModal, closeNpcModal)
	wireEscapeToClose(sellAllModal, closeSellAllWindow)
end

function terminate()
	if sellAllPendingEvent then
		sellAllPendingEvent:cancel()
		sellAllPendingEvent = nil
	end

	saveSellAllIgnoreList()
	disconnect(g_game, {
		onGameStart = npcModalOnSellAllGameStart,
		onGameEnd = closeNpcModal,
		onNpcChatWindow = sendNpcModal,
		onOpenNpcTrade = sendNpcTrade,
		onCloseNpcTrade = onCloseNpcTrade,
		onResourcesBalanceChange = onNpcModalResourcesBalanceChange,
		onPlayerGoods = onPlayerGoods
	})
	disconnect(LocalPlayer, {
		onInventoryChange = onNpcModalInventoryChange,
		onFreeCapacityChange = onNpcModalFreeCapacityChange
	})
	disconnect(Container, {
		onAddItem = onNpcModalContainerChange,
		onUpdateItem = onNpcModalContainerChange,
		onRemoveItem = onNpcModalContainerChange
	})
	unbindNpcModalPlayerInventoryListener()

	if modules.game_console and modules.game_console.detachConsoleTextEditFromNpcModal then
		modules.game_console.detachConsoleTextEditFromNpcModal()
	end

	mainNpcModal:destroy()
end

function closeNpcModal()
	saveSellAllIgnoreList()

	if modules.game_console and modules.game_console.detachConsoleTextEditFromNpcModal then
		modules.game_console.detachConsoleTextEditFromNpcModal()
	end

	if mainNpcModal then
		mainNpcModal:hide()

		if g_game.isOnline() then
			g_game.talkChannel(11, 0, "bye")
		end
	end

	if sellAllModal then
		sellAllModal:hide()
	end
end

function sendNpcModal(data)
	local npcNames = ""
	local npcCount = 0

	for i = 1, #data.npcIds do
		local creature = g_map.getCreatureById(data.npcIds[i])

		if creature then
			npcCount = npcCount + 1

			if npcNames == "" then
				npcNames = creature:getName()
			else
				npcNames = npcNames .. " and " .. creature:getName()
			end
		end
	end

	if npcCount == 0 then
		closeNpcModal()

		return
	end

	if npcCount == 1 then
		if multiNpc then
			multiNpc:hide()
		end

		local creature = g_map.getCreatureById(data.npcIds[1])

		if creature and npcOutfit then
			npcOutfit:setOutfit(creature:getOutfit())
			npcOutfit:show()
		end
	else
		if multiNpc then
			multiNpc:show()
		end

		if npcOutfit then
			npcOutfit:hide()
		end
	end

	npcNameLabel:setText(npcNames)
	npcNameLabel:show()

	local itemsPanel = mainNpcModal:recursiveGetChildById("itemsPanel")

	if itemsPanel then
		itemsPanel:destroyChildren()
	end

	for _, w in pairs(sayButtonsActive) do
		if w and not w:isDestroyed() then
			w:destroy()
		end
	end

	sayButtonsActive = {}

	local readOnlyAnchor = mainNpcModal:recursiveGetChildById("readOnlyPanel")
	local mainLeft = readOnlyAnchor and readOnlyAnchor:getX() or 0

	for i = 1, #data.buttons do
		local button = data.buttons[i]
		local sayButton = g_ui.createWidget("SayButton", mainNpcModal)

		sayButton:setTooltip(button.text)

		local clip = imageClips[button.id]

		if clip then
			sayButton:setImageClip(clip.normal)
		else
			sayButton:setImageClip(imageClips[0].normal)
		end

		local left = mainLeft + 40 * (i - 1)

		sayButton:setMarginLeft(left - mainLeft)

		function sayButton.onMousePress()
			local clip = imageClips[button.id] or imageClips[0]

			if clip and clip.pressed then
				sayButton:setImageClip(clip.pressed)
			end
		end

		function sayButton.onMouseRelease()
			local clip = imageClips[button.id] or imageClips[0]

			if clip and clip.normal then
				sayButton:setImageClip(clip.normal)

				if modules.game_console and modules.game_console.sendNpcModalReply then
					modules.game_console.sendNpcModalReply(button.text)
				end
			end
		end

		table.insert(sayButtonsActive, sayButton)
	end

	if mainNpcModal then
		if modules.game_console and modules.game_console.attachConsoleTextEditToNpcModal then
			modules.game_console.attachConsoleTextEditToNpcModal(mainNpcModal)
		end

		mainNpcModal:show()

		if modules.game_console and modules.game_console.onNpcModalOpened then
			modules.game_console.onNpcModalOpened()
		end

		mainNpcModal:focus()
	end

	if npcModalTrade then
		hideTradeWindowChildrens()

		npcTradeSelectedEntry = nil

		clearNpcTradeItem2Preview()

		npcTradeCurrencyId = nil

		if label5 and not label5:isDestroyed() then
			label5:setText(tr("Gold:"))
		end

		local tradeList = mainNpcModal and mainNpcModal:recursiveGetChildById("npcTradeItemsPanel")

		if tradeList then
			tradeList:destroyChildren()
		end

		if mainNpcModal then
			mainNpcModal:setWidth(mainNpcModal:getWidth() - NPC_MODAL_TRADE_EXTRA_W)
			mainNpcModal:bindRectToParent()
		end

		local readOnlyPanel = mainNpcModal:recursiveGetChildById("readOnlyPanel")

		if readOnlyPanel then
			readOnlyPanel:setMarginRight(16)
		end

		npcModalTrade = false
	end
end

local function onCloseNpcTrade()
	if not npcModalTrade then
		npcTradeCurrencyId = nil

		return
	end

	hideTradeWindowChildrens()

	npcTradeSelectedEntry = nil

	clearNpcTradeItem2Preview()

	npcTradeCurrencyId = nil

	if label5 and not label5:isDestroyed() then
		label5:setText(tr("Gold:"))
	end

	local tradeList = mainNpcModal and mainNpcModal:recursiveGetChildById("npcTradeItemsPanel")

	if tradeList then
		tradeList:destroyChildren()
	end

	if mainNpcModal then
		mainNpcModal:setWidth(mainNpcModal:getWidth() - NPC_MODAL_TRADE_EXTRA_W)
		mainNpcModal:bindRectToParent()
	end

	local readOnlyPanel = mainNpcModal and mainNpcModal:recursiveGetChildById("readOnlyPanel")

	if readOnlyPanel then
		readOnlyPanel:setMarginRight(16)
	end

	npcModalTrade = false
end

function sendNpcTrade(items, currencyId)
	npcTradeCurrencyId = currencyId

	local itemWidget = mainNpcModal and mainNpcModal:recursiveGetChildById("item")

	if itemWidget and currencyId then
		itemWidget:setItemId(currencyId)
		itemWidget:setItemCount(100)
	end

	local currencyLabel = mainNpcModal and mainNpcModal:recursiveGetChildById("currencyName")

	if currencyLabel and currencyId then
		local itemType = g_things.getThingType(currencyId, ThingCategoryItem)

		if itemType then
			currencyLabel:setText(capitalizeWords(itemType:getName()))
		end
	end

	BuyNpcTradeItems = {}
	SellNpcTradeItems = {}

	if items and #items > 0 then
		for i, itemData in ipairs(items) do
			if itemData[4] > 0 then
				table.insert(BuyNpcTradeItems, {
					item = itemData[1],
					name = itemData[2],
					weight = itemData[3] / 100,
					buyPrice = itemData[4],
					sellPrice = itemData[5]
				})
			end

			if itemData[5] > 0 then
				table.insert(SellNpcTradeItems, {
					item = itemData[1],
					name = itemData[2],
					weight = itemData[3] / 100,
					buyPrice = itemData[4],
					sellPrice = itemData[5]
				})
			end
		end
	end

	npcTradeSelectedEntry = nil

	clearNpcTradeItem2Preview()

	npcTradeFilterText = ""

	if mainNpcModal then
		local sw = mainNpcModal:recursiveGetChildById("search")

		if sw then
			sw:clearText()
		end
	end

	if buyButton and sellButton then
		buyButton:setOn(true)
		sellButton:setOn(false)
	end

	refreshNpcTradeItemList()
	showTradeWindow()
	refreshNpcTradeCurrencyState()
	addEvent(function()
		if npcModalTrade and npcTradeCurrencyId ~= nil then
			refreshNpcTradeCurrencyState()
		end
	end)
end

function showTradeWindow()
	if not mainNpcModal then
		return
	end

	if npcModalTrade then
		showTradeWindowChildrens()

		return
	end

	npcModalTrade = true

	bindNpcModalPlayerInventoryListener()

	local readOnlyPanel = mainNpcModal:recursiveGetChildById("readOnlyPanel")

	if readOnlyPanel then
		readOnlyPanel:setMarginRight(220)
	end

	local newW = math.min(NPC_MODAL_MAX_W, mainNpcModal:getWidth() + NPC_MODAL_TRADE_EXTRA_W)

	mainNpcModal:setWidth(newW)
	mainNpcModal:bindRectToParent()
	showTradeWindowChildrens()
end

function onPlayerGoods(money, items, lootPouch)
	playerItems = {}

	-- our engine emits onPlayerGoods without the third argument (lootPouch is a the ported client
	-- client extension) - without the guards pairs(nil) crashed opening trade with an NPC
	items = items or {}
	lootPouch = lootPouch or {}

	for _, data in pairs(items) do
		local ptr = data[1]
		local id = ptr and ptr.getId and ptr:getId() or tonumber(ptr)
		local amount = data[2]

		if id and amount then
			playerItems[id] = (playerItems[id] or 0) + amount
		end
	end

	lootPouchItems = {}

	for _, data in pairs(lootPouch) do
		local ptr = data[1]
		local id = ptr and ptr.getId and ptr:getId() or tonumber(ptr)
		local amount = data[2]

		if id and amount then
			lootPouchItems[id] = (lootPouchItems[id] or 0) + amount
		end
	end

	if npcModalTrade then
		refreshNpcTradeItemList()
		revalidateNpcTradeQuantity()
	end

	refreshSellAllButtonVisibility()
end

local function handleSearchField()
	if not mainNpcModal or mainNpcModal:isDestroyed() then
		return
	end

	if showSearchField then
		searchEdit:hide()
		clearSearch:hide()
		itemsSelling:setMarginBottom(78)
	else
		searchEdit:show()
		clearSearch:show()
		itemsSelling:setMarginBottom(103)
	end

	showSearchField = not showSearchField
end

local function handleSorts(param)
	if param == 1 then
		sortByName = true
		sortByPrice = false
		sortByWeight = false
	elseif param == 2 then
		sortByName = false
		sortByPrice = true
		sortByWeight = false
	elseif param == 3 then
		sortByName = false
		sortByPrice = false
		sortByWeight = true
	end

	refreshNpcTradeItemList()
end

function showMenuFilters(showLook)
	if not g_game.isOnline() then
		return
	end

	local menu = g_ui.createWidget("GamePopupMenu")

	menu:setGameMenu(true)
	menu:setWidth(402)
	menu:setHeight(172)

	if showLook then
		menu:addOption(tr("Look"), function()
			if npcTradeLookThing then
				g_game.look(npcTradeLookThing)
			end
		end)
		menu:addOption(tr("Inspect"), function()
			local count = npcTradeLookThing:getCount()

			if not count or count < 1 then
				count = 1
			end

			g_game.inspectionObject(InspectObjectTypes.NpcTrade, npcTradeLookThing:getId(), count)
		end)
	end

	menu:addCheckBox(tr("Sort by name"), sortByName, function()
		handleSorts(1)
	end)
	menu:addCheckBox(tr("Sort by price"), sortByPrice, function()
		handleSorts(2)
	end)
	menu:addCheckBox(tr("Sort by weight"), sortByWeight, function()
		handleSorts(3)
	end)
	menu:addSeparator()
	menu:addCheckBox(tr("Buy in shopping bags"), buyInShoppingBags, function()
		buyInShoppingBags = not buyInShoppingBags
	end)
	menu:addCheckBox(tr("Ignore capacity"), ignoreCapacity, function()
		ignoreCapacity = not ignoreCapacity

		revalidateNpcTradeQuantity()
	end)
	menu:addSeparator()
	menu:addCheckBox(tr("Sell equipped"), sellEquipped, function()
		sellEquipped = not sellEquipped

		refreshNpcTradeItemList()
		revalidateNpcTradeQuantity()
	end)
	menu:addSeparator()
	menu:addCheckBox(tr("Show search field"), showSearchField, function()
		handleSearchField()
	end)
	menu:addCheckBox(tr("Do not show a warning when trading large amounts"), doNotShowWarningLargeAmounts, function()
		doNotShowWarningLargeAmounts = not doNotShowWarningLargeAmounts
	end)
	menu:display()
	setWindowOpacity(1)
end

local function createSellAllItemBox(panel, itemId, amount, panelKind)
	if not panel or not itemId then
		return
	end

	local box = g_ui.createWidget("ItemBoxSell", panel)

	box.sellAllItemId = itemId
	box.sellAllAmount = amount
	box.sellAllPanelKind = panelKind

	local icon = box:recursiveGetChildById("itemsell")

	if not icon then
		return
	end

	icon:setItemId(itemId)
	icon:setItemCount(amount)

	if panelKind == "sell" then
		local function onDc()
			if not box.sellAllItemId then
				return false
			end

			sellAllIgnoredItems[box.sellAllItemId] = true

			saveSellAllIgnoreList()
			addEvent(function()
				refreshSellAllModalLists()
			end)

			return true
		end

		box.onDoubleClick = onDc
		icon.onDoubleClick = onDc
	elseif panelKind == "ignore" then
		local border = box:recursiveGetChildById("ignoredBorder")

		if border then
			border:show()
			border:raise()
		end

		icon:setShowCount(false)

		local function onDc()
			if not box.sellAllItemId then
				return false
			end

			sellAllIgnoredItems[box.sellAllItemId] = false

			saveSellAllIgnoreList()
			addEvent(function()
				refreshSellAllModalLists()
			end)

			return true
		end

		box.onDoubleClick = onDc
		icon.onDoubleClick = onDc
	end
end

function refreshSellAllModalLists()
	if not sellAllModal then
		return
	end

	local sellItemsPanel = sellAllModal:recursiveGetChildById("npcSellItemsPanel")
	local ignorePanel = sellAllModal:recursiveGetChildById("npcIgnoreItemsPanel")

	if not sellItemsPanel or not ignorePanel then
		return
	end

	sellItemsPanel:destroyChildren()
	ignorePanel:destroyChildren()

	local tempSellAllItems = {}

	for itemId, amount in pairs(lootPouchItems) do
		if sellAllIgnoredItems[itemId] == nil or sellAllIgnoredItems[itemId] == false then
			tempSellAllItems[itemId] = lootPouchItems[itemId]
		end
	end

	table.sort(tempSellAllItems)

	for itemId, total in pairs(tempSellAllItems) do
		local thing = g_things.getThingType(itemId, ThingCategoryItem)
		local itemName = thing:getName()

		itemName = tostring(itemName):lower()

		local filter2 = tostring(FilterText2 or ""):lower()

		if filter2 == "" or itemName:find(filter2, 1, true) then
			createSellAllItemBox(sellItemsPanel, itemId, total, "sell")
		end
	end

	for itemId, active in pairs(sellAllIgnoredItems) do
		if active == true then
			local thing = g_things.getThingType(itemId, ThingCategoryItem)
			local itemName = thing:getName()

			itemName = tostring(itemName):lower()

			local filter3 = tostring(FilterText3 or ""):lower()

			if filter3 == "" or itemName:find(filter3, 1, true) then
				createSellAllItemBox(ignorePanel, itemId, 0, "ignore")
			end
		end
	end
end

function closeSellAllWindow()
	if sellAllModal then
		sellAllModal:hide()
	end

	mainNpcModal:show()
	npcOutfit:show()
	npcNameLabel:show()
	showTradeWindowChildrens()
	setWindowOpacity(1)
end

function openSellAllWindow()
	-- One click sells the complete loot pouch through the NPC's special offer.
	sendSellAll()
end

function sendSellAll()
	if not g_game.isOnline() then
		return
	end

	if sellAllPendingEvent then
		return
	end

	local pouchOffer = nil
	for _, entry in ipairs(SellNpcTradeItems or {}) do
		if entry.item and entry.item:getId() == LOOT_POUCH_ITEM_ID then
			pouchOffer = entry.item
			break
		end
	end

	if not pouchOffer and g_game.findPlayerItem then
		pouchOffer = g_game.findPlayerItem(LOOT_POUCH_ITEM_ID, -1, 0)
	end

	if not pouchOffer then
		local player = g_game.getLocalPlayer()

		if player then
			for slot = InventorySlotFirst or 1, InventorySlotLast or 10 do
				local inventoryItem = player:getInventoryItem(slot)

				if inventoryItem and inventoryItem:getId() == LOOT_POUCH_ITEM_ID then
					pouchOffer = inventoryItem
					break
				end
			end
		end
	end

	if not pouchOffer then
		return
	end

	if sellAllButton and not sellAllButton:isDestroyed() then
		sellAllButton:setEnabled(false)
	end

	-- NPC chat/trade opening shares the action cooldown. Waiting one interval
	-- prevents an immediate click from being rejected as "objects too fast".
	sellAllPendingEvent = scheduleEvent(function()
		sellAllPendingEvent = nil
		if g_game.isOnline() then
			g_game.sellItem(pouchOffer, 1, true)
		end
		if sellAllButton and not sellAllButton:isDestroyed() then
			sellAllButton:setEnabled(true)
		end
		closeSellAllWindow()
	end, 450)
end
