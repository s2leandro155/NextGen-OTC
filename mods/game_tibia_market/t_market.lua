-- chunkname: @/mods/game_tibia_market/t_market.lua

marketWindow = nil

local marketItems = {}
local allMarketItems = {}
local categoryList = {}
local depotLockerItems = {}
local buyOffers = {}
local sellOffers = {}
local lastSelectedCategory
local lastSelectedItem = {}

lastSelectedMySell = nil
lastSelectedMyBuy = nil
lastSelectedHistorySell = nil
lastSelectedHistoryBuy = nil

local showLockerOnly = false
local mainMarket
local playerAtDepot = false
local lastItemID = 0
local lastItemTier = 0
local currentActionType = 1
local suppressSearchCallbacks = false
local suppressFilterCallbacks = false
local cache = {
	SCROLL_MARKET_ITEMS = {
		listMax = 0,
		listMin = 0,
		scrollDelay = 0,
		offset = 0,
		listPool = 14,
		listFit = 0,
		listData = {}
	},
	SCROLL_SELL_OFFERS = {
		listMax = 0,
		listMin = 0,
		lastSelected = 0,
		listPool = 14,
		listFit = 0,
		listData = {}
	},
	SCROLL_BUY_OFFERS = {
		listMax = 0,
		listMin = 0,
		lastSelected = 0,
		listPool = 14,
		listFit = 0,
		listData = {}
	}
}
local sortButtons = {
	tierFilter = 0,
	classFilter = -1,
	twoButton = false,
	oneButton = false,
	vocButton = false,
	levelButton = false
}
local enableCategories = {
	17,
	18,
	19,
	20,
	21,
	27,
	32
}
local enableClassification = {
	1,
	3,
	7,
	8,
	15,
	17,
	18,
	19,
	20,
	21,
	24,
	27,
	32
}
local MARKET_ITEM_ROW_HEIGHT = 36

local function resetItemListScrollOffset(itemList)
	if itemList then
		itemList:setVirtualOffset({
			x = 0,
			y = 0
		})
	end
end

local function getMarketItemListFit(itemList)
	if not itemList then
		return 8
	end

	return math.max(1, math.floor(itemList:getHeight() / MARKET_ITEM_ROW_HEIGHT) + 1)
end

local function setupItemListScrollbar(itemList)
	local scroll = marketWindow:recursiveGetChildById("itemListScroll")

	if not scroll or not itemList then
		return
	end

	resetItemListScrollOffset(itemList)
	scroll:setValue(0)
	scroll:setMinimum(cache.SCROLL_MARKET_ITEMS.listMin or 0)

	local visibleCount = cache.SCROLL_MARKET_ITEMS.listFit or 8
	local dataCount = #cache.SCROLL_MARKET_ITEMS.listData

	scroll:setMaximum(math.max(0, dataCount - visibleCount))

	function scroll:onValueChange(value, delta)
		onItemListValueChange(self, value, delta)
	end

	function itemList.onMouseWheel(widget, mousePos, direction)
		local itemListScroll = marketWindow:recursiveGetChildById("itemListScroll")

		if not itemListScroll then
			return false
		end

		if direction == MouseWheelUp then
			itemListScroll:setValue(math.max(itemListScroll:getValue() - itemListScroll:getStep(), itemListScroll:getMinimum()))
		elseif direction == MouseWheelDown then
			itemListScroll:setValue(math.min(itemListScroll:getValue() + itemListScroll:getStep(), itemListScroll:getMaximum()))
		end

		return true
	end

	addEvent(function()
		local list = marketWindow and marketWindow:recursiveGetChildById("itemList")

		resetItemListScrollOffset(list)
	end)
end

local function sortByUnitPriceAsc(list)
	table.sort(list, function(a, b)
		if not a then
			return false
		end

		if not b then
			return true
		end

		local pa, pb = a.price or 0, b.price or 0

		if pa == pb then
			if (a.timestamp or 0) ~= (b.timestamp or 0) then
				return (a.timestamp or 0) < (b.timestamp or 0)
			end

			if (a.counter or 0) ~= (b.counter or 0) then
				return (a.counter or 0) < (b.counter or 0)
			end

			return tostring(a.playerName or "") < tostring(b.playerName or "")
		end

		return pa < pb
	end)
end

local function compareMarketItemsByNameCaseInsensitive(a, b)
	local nameA = string.lower(a.marketData.name or "")
	local nameB = string.lower(b.marketData.name or "")

	return nameA < nameB
end

local function normalizeMarketSearchText(text)
	if not text then
		return ""
	end

	return text:match("^%s*(.-)%s*$") or ""
end

local function marketItemNameMatchesSearch(itemName, searchTerm)
	searchTerm = normalizeMarketSearchText(searchTerm)

	if searchTerm == "" then
		return false
	end

	return string.lower(itemName or ""):find(string.lower(searchTerm), 1, true) ~= nil
end

local function formatAmountShort(n)
	if not n or n < 1 then
		return nil
	end

	local step, unit = 1, ""

	if n >= 1000000000 then
		step, unit = 1000000000, "b"
	elseif n >= 1000000 then
		step, unit = 1000000, "m"
	elseif n >= 1000 then
		step, unit = 1000, "k"
	end

	local v = math.floor(n / step)
	local plus = n % step ~= 0 and "+" or ""

	return tostring(v) .. unit .. plus
end

local function fmtQty(n)
	n = tonumber(n) or 0

	if n < 1 then
		return "0"
	end

	if n < 1000 then
		return tostring(n)
	end

	if n < 1000000 then
		return string.format("%dk", math.floor(n / 1000))
	end

	if n < 1000000000 then
		return string.format("%dm", math.floor(n / 1000000))
	end

	return string.format("%db", math.floor(n / 1000000000))
end

local function setAmount(label, n)
	if not label then
		return
	end

	label:setText(fmtQty(n))
	label:setVisible(true)
end

local function getMarketPreviewPanel()
	return marketWindow and marketWindow.contentPanel
end

local function getMarketPreviewAmountLabel()
	local panel = getMarketPreviewPanel()

	return panel and panel.amount
end

local function clearMarketPreviewSelectedItem(selectedItemWidget)
	if not selectedItemWidget then
		return
	end

	if selectedItemWidget.clearItem then
		selectedItemWidget:clearItem()
	else
		selectedItemWidget:setItemId(0)
	end

	selectedItemWidget:setTier(0)
end

local function applyMarketItemRarity(rarityWidget, itemId)
	if not rarityWidget then
		return
	end

	if not itemId then
		ItemsDatabase.setRarityItem(rarityWidget, nil)
		rarityWidget:setImageSource("")
		rarityWidget:setImageClip("0 0 0 0")
		rarityWidget:setVisible(false)

		return
	end

	local thing = g_things.getThingType(itemId, ThingCategoryItem)

	if not thing then
		ItemsDatabase.setRarityItem(rarityWidget, nil)
		rarityWidget:setImageSource("")
		rarityWidget:setImageClip("0 0 0 0")
		rarityWidget:setVisible(false)

		return
	end

	ItemsDatabase.setRarityItem(rarityWidget, thing:getMeanPrice())
	rarityWidget:setVisible(rarityWidget:getImageSource() ~= "")
end

local function applyMarketItemTierBadge(holderWidget, tier)
	if not holderWidget or not holderWidget.tier then
		return
	end

	ItemsDatabase.setTier(holderWidget, tier or 0)
end

local function applyMarketItemNameColor(nameWidget, count)
	if not nameWidget then
		return
	end

	nameWidget:setColor(count > 0 and "#c0c0c0" or "#707070")
end

local MARKET_ITEM_EMPTY_SLOT_OPACITY = 0.5
local MARKET_ITEM_EMPTY_TINT = "#808080"
local MARKET_ITEM_NORMAL_TINT = "#ffffff"

local function setMarketAmountScrollRange(scrollBar, minVal, maxVal)
	if not scrollBar then
		return
	end

	scrollBar:setRange(minVal, maxVal)

	local slider = scrollBar:getChildById("sliderButton")

	if slider then
		slider:setVisible(minVal < maxVal and maxVal > 1)
	end
end

local function applyMarketItemSlotOpacity(rowWidget, count)
	if not rowWidget then
		return
	end

	local empty = count == 0
	local slotOpacity = empty and MARKET_ITEM_EMPTY_SLOT_OPACITY or 1

	if rowWidget.itemSlot then
		rowWidget.itemSlot:setOpacity(slotOpacity)
	end

	if rowWidget.tier then
		rowWidget.tier:setOpacity(slotOpacity)
	end

	if rowWidget.amount then
		rowWidget.amount:setOpacity(slotOpacity)
	end

	if rowWidget.rarity then
		rowWidget.rarity:setOpacity(slotOpacity)
	end

	if rowWidget.item then
		rowWidget.item:setOpacity(slotOpacity)
		rowWidget.item:setColor(empty and MARKET_ITEM_EMPTY_TINT or MARKET_ITEM_NORMAL_TINT)
	end
end

local function resetSelectedItemPreviewVisual()
	local panel = marketWindow and marketWindow.contentPanel

	if not panel then
		return
	end

	if panel.itemSlot then
		panel.itemSlot:setOpacity(1)
	end

	if panel.tier then
		panel.tier:setOpacity(1)
	end

	if panel.rarity then
		panel.rarity:setOpacity(1)
	end

	if panel.selectedItem then
		panel.selectedItem:setOpacity(1)
		panel.selectedItem:setColor(MARKET_ITEM_NORMAL_TINT)
	end

	local amountLabel = panel.amount

	if amountLabel then
		amountLabel:setOpacity(1)
	end
end

local function resetMarketPreviewPanel()
	local panel = getMarketPreviewPanel()

	if not panel then
		return
	end

	clearMarketPreviewSelectedItem(panel.selectedItem)
	applyMarketItemRarity(panel.rarity, nil)
	applyMarketItemTierBadge(panel, 0)

	local amountLabel = panel.amount

	if amountLabel then
		amountLabel:setText("")
		amountLabel:setVisible(false)
	end

	resetSelectedItemPreviewVisual()
end

local function resetCreateOfferType()
	currentActionType = 1

	if not mainMarket then
		return
	end

	mainMarket.createOfferSell:setChecked(true)
	mainMarket.createOfferBuy:setChecked(false)
	mainMarket.grossProfit:setText("Gross Profit:")
	mainMarket.profitLabel:setText("Total Profit:")
	mainMarket.piecePriceCreate:clearText()
	mainMarket.anonymous:setChecked(false)
end

local function resetMarketViewState()
	if not marketWindow then
		return
	end

	local contentPanel = marketWindow.contentPanel
	local marketHistory = marketWindow.MarketHistory
	local mainMarket = contentPanel and contentPanel:getChildById("mainMarket")
	local detailsMarket = contentPanel and contentPanel:getChildById("detailsMarket")
	local closeButton = contentPanel and contentPanel:getChildById("closeButton")
	local marketButton = contentPanel and contentPanel:getChildById("marketButton")

	if marketHistory then
		marketHistory:setVisible(false)
	end

	if contentPanel then
		contentPanel:setVisible(true)
	end

	if mainMarket then
		mainMarket:setVisible(true)
	end

	if detailsMarket then
		detailsMarket:setVisible(false)
	end

	if closeButton then
		closeButton:setVisible(true)
	end

	if marketButton then
		marketButton:setVisible(false)
	end

	setMyOffersHeaderHistoryMode(false)
	updateMarketWindowTitle("market")
	resetMarketFilterButtons()
	resetCreateOfferType()
end

function resetMarketFilterButtons()
	if not marketWindow or not marketWindow.contentPanel then
		return
	end

	local panel = marketWindow.contentPanel

	showLockerOnly = false

	if panel.lockerOnly then
		panel.lockerOnly:setChecked(false)
	end

	for _, id in ipairs({
		"levelButton",
		"vocButton",
		"oneButton",
		"twoButton"
	}) do
		sortButtons[id] = false

		local btn = panel:getChildById(id)

		if btn then
			btn:setChecked(false)
		end
	end
end

local function restoreMarketListItemRow(rowWidget)
	if not rowWidget or not rowWidget.item or not rowWidget.name then
		return
	end

	local id = rowWidget.item:getItemId()
	local tier = rowWidget.item:getItem():getTier() or 0
	local count = getDepotItemCount(id, tier)

	applyMarketItemNameColor(rowWidget.name, count)
	applyMarketItemSlotOpacity(rowWidget, count)
end

local function applyAmountLabel(label, n)
	if not label then
		return
	end

	if n and n >= 1 then
		label:setText(formatAmountShort(n) or "")
		label:setVisible(true)
	else
		label:setVisible(false)
	end
end

local function sortByUnitPriceDesc(list)
	table.sort(list, function(a, b)
		if not a then
			return false
		end

		if not b then
			return true
		end

		local pa, pb = a.price or 0, b.price or 0

		if pa == pb then
			if (a.timestamp or 0) ~= (b.timestamp or 0) then
				return (a.timestamp or 0) < (b.timestamp or 0)
			end

			if (a.counter or 0) ~= (b.counter or 0) then
				return (a.counter or 0) < (b.counter or 0)
			end

			return tostring(a.playerName or "") < tostring(b.playerName or "")
		end

		return pb < pa
	end)
end

local function isMarketOfferConsumed(offer)
	if not offer then
		return true
	end

	if (offer.amount or 0) == 0 then
		return true
	end

	local state = offer.state

	return state == MarketOfferState.Accepted or state == MarketOfferState.AcceptedEx or state == MarketOfferState.Cancelled or state == MarketOfferState.Expired
end

local function pruneConsumedOffers(list)
	for i = #list, 1, -1 do
		if isMarketOfferConsumed(list[i]) then
			table.remove(list, i)
		end
	end
end

local function isPartialMarketBrowseUpdate(buyList, sellList)
	buyList = buyList or {}
	sellList = sellList or {}

	return #buyList + #sellList <= 1
end

local function mergeMarketOfferList(current, incoming)
	incoming = incoming or {}

	if #incoming == 0 then
		return current
	end

	if #incoming == 1 and #current > 0 then
		local updateItem = incoming[1]

		for i, data in ipairs(current) do
			if data.counter == updateItem.counter and data.timestamp == updateItem.timestamp then
				if isMarketOfferConsumed(updateItem) then
					table.remove(current, i)
				else
					current[i] = updateItem
				end

				return current
			end
		end
	end

	local merged = incoming

	pruneConsumedOffers(merged)

	return merged
end

function updateMarketWindowTitle(view)
	if not marketWindow then
		return
	end

	if view == "offerHistory" then
		marketWindow:setText(tr("Offer History"))
	elseif view == "myOffers" then
		marketWindow:setText(tr("My Offers"))
	else
		marketWindow:setText(tr("Market"))
	end
end

local function showMarketWindow()
	if not marketWindow then
		return
	end

	updateMarketWindowTitle("market")
	marketWindow:show(true)
	g_modalManager.show(marketWindow)
	marketWindow.contentPanel.searchText:focus()
end

local function hideMarketWindow()
	if not marketWindow then
		return
	end

	g_modalManager.hide(marketWindow)
	marketWindow:hide()
end

local function onSpecialContainer(supplyStashAvailable, marketAvailable)
	playerAtDepot = marketAvailable == true
end

local function onDepotContainerOpen(container)
	if container and container.isInDepot and container:isInDepot() then
		playerAtDepot = true
	end
end

local function onGameEndDepot()
	playerAtDepot = false
end

local function canShowInMarket(menuPosition, lookThing, useThing, creatureThing)
	if not playerAtDepot then
		return false
	end

	local item = lookThing or useThing

	if not item or not item.isItem or not item:isItem() then
		return false
	end

	return item:isMarketable()
end

local function showInMarketCallback(menuPosition, lookThing, useThing, creatureThing)
	local item = lookThing or useThing

	if not item then
		return
	end

	showItemInMarket(item)
end

function showItemInMarket(item)
	if not item then
		return
	end

	if marketWindow and marketWindow:isVisible() then
		onRedirect(item)
	else
		g_game.sendMarketAction(1)
		scheduleEvent(function()
			if not marketWindow or not marketWindow:isVisible() then
				show()
			end

			onRedirect(item)
		end, 400)
	end
end

function init()
	marketWindow = g_ui.displayUI("t_market")

	if not marketWindow then
		g_logger.error("[game_market] failed to load t_market.otui")

		return
	end

	mainMarket = marketWindow.contentPanel.mainMarket

	function marketWindow.contentPanel.lockerOnly:onCheckChange(checked)
		toggleShowLockerOnly(self, checked)
	end

	setMarketAmountScrollRange(mainMarket.amountSellScrollBar, 0, 0)
	setMarketAmountScrollRange(mainMarket.amountBuyScrollBar, 0, 0)
	setMarketAmountScrollRange(mainMarket.amountCreateScrollBar, 0, 0)
	hide()
	resetCreateOfferType()
	connect(g_game, {
		onUpdateResourceValue = onUpdateResourceValue,
		onResourceBalance = onResourceBalance,
		onGameEnd = hide,
		onGameStart = hide,
		onMarketEnter = onMarketEnter,
		onMarketBrowse = onEngineMarketBrowse,
		onMarketDetail = onMarketDetail,
		onParseMyOffers = MarketOwnOffers.onParseMyOffers,
		onParseMarketHistory = MarketHistory.onParseMarketHistory,
		onMarketLeave = hide,
		onCoinBalance = onCoinBalance,
		onParseStoreGetCoin = onMarketStoreGetCoin,
		onSpecialContainer = onSpecialContainer
	})
	connect(g_game, {
		onGameEnd = onGameEndDepot
	})
	connect(Container, {
		onOpen = onDepotContainerOpen
	})

	if modules.game_interface then
		modules.game_interface.addMenuHook("market", tr("Show in Market"), showInMarketCallback, canShowInMarket)
	end
end

local function clearMarketItemRefs()
	lastSelectedItem = {}
	cache.SCROLL_MARKET_ITEMS.listPool = {}
	cache.SCROLL_MARKET_ITEMS.listData = {}
	cache.SCROLL_MARKET_ITEMS.listMax = 0
	cache.SCROLL_MARKET_ITEMS.listMin = 0

	if not marketWindow then
		return
	end

	local itemListScroll = marketWindow:recursiveGetChildById("itemListScroll")

	if itemListScroll then
		itemListScroll.onValueChange = nil
	end
end

local function clearMarketWidgetRefs()
	clearMarketItemRefs()

	lastSelectedMySell = nil
	lastSelectedMyBuy = nil
	lastSelectedHistorySell = nil
	lastSelectedHistoryBuy = nil

	if MarketHistory and MarketHistory.clearPools then
		MarketHistory.clearPools()
	end

	if not marketWindow then
		return
	end

	local currentOffers = marketWindow.MarketHistory and marketWindow.MarketHistory.currentOffers

	if currentOffers then
		currentOffers.sellOffersList:focusChild(nil)
		currentOffers.buyOffersList:focusChild(nil)
		currentOffers.sellOffersList:destroyChildren()
		currentOffers.buyOffersList:destroyChildren()
	end
end

function terminate()
	if modules.game_interface then
		modules.game_interface.removeMenuHook("market", tr("Show in Market"))
	end

	disconnect(Container, {
		onOpen = onDepotContainerOpen
	})
	disconnect(g_game, {
		onGameEnd = onGameEndDepot
	})

	playerAtDepot = false

	disconnect(g_game, {
		onUpdateResourceValue = onUpdateResourceValue,
		onResourceBalance = onResourceBalance,
		onGameStart = onMarketLeave,
		onGameEnd = onMarketLeave,
		onMarketEnter = onMarketEnter,
		onMarketBrowse = onEngineMarketBrowse,
		onMarketDetail = onMarketDetail,
		onParseMyOffers = MarketOwnOffers.onParseMyOffers,
		onParseMarketHistory = MarketHistory.onParseMarketHistory,
		onMarketLeave = hide,
		onCoinBalance = onCoinBalance,
		onParseStoreGetCoin = onMarketStoreGetCoin,
		onSpecialContainer = onSpecialContainer
	})

	if marketWindow then
		clearMarketWidgetRefs()
		g_modalManager.hide(marketWindow)
		marketWindow:destroy()

		marketWindow = nil
	end
end

function toggle()
	if marketWindow:isVisible() then
		hideMarketWindow()
		modules.game_console.getConsole():focus()
	else
		showMarketWindow()
	end
end

function onMarketLeave()
	g_game.leaveMarket()
end

function hide()
	resetMarketViewState()
	resetMarketPreviewPanel()
	clearMarketWidgetRefs()
	onClearMainMarket(true)
	hideMarketWindow()
	onClearSearch()
end

function returnToMainMarket()
	if not marketWindow then
		return false
	end

	local marketHistory = marketWindow.MarketHistory

	if not marketHistory or not marketHistory:isVisible() then
		return false
	end

	local marketPanel = marketWindow.contentPanel:getChildById("mainMarket")
	local detailsMarket = marketWindow.contentPanel:getChildById("detailsMarket")
	local marketMain = marketWindow:getChildById("contentPanel")
	local closeButton = marketWindow.contentPanel:getChildById("closeButton")

	resetMyOffersPanelView()
	updateMarketWindowTitle("market")
	marketHistory:setVisible(false)
	marketMain:setVisible(true)
	detailsMarket:setVisible(false)
	marketPanel:setVisible(true)
	closeButton:setVisible(true)
	refreshSelectedMarketBrowse()
	refreshSelectedItemDepotDisplay()

	return true
end

function onMarketEscape()
	if not marketWindow or not marketWindow:isVisible() then
		return
	end

	if returnToMainMarket() then
		return
	end

	local detailsMarket = marketWindow.contentPanel:getChildById("detailsMarket")

	if detailsMarket and detailsMarket:isVisible() then
		offersButton()

		return
	end

	close()
end

function show()
	resetMarketViewState()
	resetMarketPreviewPanel()
	showMarketWindow()

	sortButtons.classFilter = -1
	sortButtons.tierFilter = 0
end

function close()
	if g_game.isOnline() then
		g_game.leaveMarket()
	else
		hide()
	end
end

function detailsButton()
	local mainMarket = marketWindow.contentPanel:getChildById("mainMarket")
	local detailsMarket = marketWindow.contentPanel:getChildById("detailsMarket")
	local closeButton = marketWindow.contentPanel:getChildById("closeButton")
	local marketButton = marketWindow.contentPanel:getChildById("marketButton")

	if detailsMarket:isVisible() then
		return
	end

	if mainMarket:isVisible() then
		mainMarket:setVisible(false)
		detailsMarket:setVisible(true)
		closeButton:setVisible(false)
		marketButton:setVisible(true)
	else
		detailsMarket:setVisible(false)
		mainMarket:setVisible(true)
		marketButton:setVisible(false)
		closeButton:setVisible(true)
		refreshSelectedMarketBrowse()
		refreshSelectedItemDepotDisplay()
	end
end

function offersButton()
	local mainMarket = marketWindow.contentPanel:getChildById("mainMarket")
	local detailsMarket = marketWindow.contentPanel:getChildById("detailsMarket")
	local closeButton = marketWindow.contentPanel:getChildById("closeButton")
	local marketButton = marketWindow.contentPanel:getChildById("marketButton")

	if not mainMarket:isVisible() then
		detailsMarket:setVisible(false)
		mainMarket:setVisible(true)
		marketButton:setVisible(false)
		closeButton:setVisible(true)
		refreshSelectedMarketBrowse()
		refreshSelectedItemDepotDisplay()
	end
end

function myOffersButton(widget)
	local marketPanel = marketWindow.contentPanel:getChildById("mainMarket")
	local detailsMarket = marketWindow.contentPanel:getChildById("detailsMarket")
	local marketMain = marketWindow:getChildById("contentPanel")
	local marketHistory = marketWindow:getChildById("MarketHistory")
	local sellButton = marketWindow.MarketHistory.currentOffers.buyCancelOffer
	local closeButton = marketWindow.contentPanel:getChildById("closeButton")

	MarketOwnOffers.myBuyOffers = {}
	MarketOwnOffers.mySellOffers = {}

	if widget:getId() == "myOffers" then
		g_game.sendMarketAction(2)
	elseif widget:getId() == "currentOffers" then
		lastSelectedHistorySell = nil
		lastSelectedHistoryBuy = nil

		MarketHistory.clearPools()
		setMyOffersHeaderHistoryMode(false)
		updateMarketWindowTitle("myOffers")
		g_game.sendMarketAction(2)

		return
	elseif widget:getId() == "historyButton" then
		lastSelectedMySell = nil
		lastSelectedMyBuy = nil

		local currentOffers = marketWindow.MarketHistory.currentOffers

		if currentOffers then
			currentOffers.sellOffersList:focusChild(nil)
			currentOffers.buyOffersList:focusChild(nil)
		end

		setMyOffersHeaderHistoryMode(true)
		updateMarketWindowTitle("offerHistory")
		g_game.sendMarketAction(1)

		return
	end

	if marketMain:isVisible() then
		resetMyOffersPanelView()
		updateMarketWindowTitle("myOffers")
		marketMain:setVisible(false)
		closeButton:setVisible(false)
		marketHistory:setVisible(true)
	else
		returnToMainMarket()
	end
end

function getDepotItemCount(itemId, tier)
	local t = tier or 0

	for _, data in pairs(depotLockerItems) do
		if data.itemId == itemId and (data.tier or 0) == t then
			return data.count or 0
		end
	end

	if itemId == 22118 then
		return g_game.getTransferableTibiaCoins()
	end

	return 0
end

function adjustDepotLockerItemCount(itemId, tier, delta)
	if not itemId or delta == 0 then
		return
	end

	local t = tier or 0

	for _, data in pairs(depotLockerItems) do
		if data.itemId == itemId and (data.tier or 0) == t then
			data.count = math.max(0, (data.count or 0) + delta)

			return
		end
	end

	if delta > 0 then
		table.insert(depotLockerItems, {
			itemId = itemId,
			tier = t,
			count = delta
		})
	end
end

function refreshSelectedItemDepotDisplay()
	if table.empty(lastSelectedItem) or not marketWindow then
		return
	end

	local itemId = lastSelectedItem.itemId
	local tier = lastSelectedItem.tier or 0

	onUpdateChildItem(itemId, tier)

	local selCount = itemId == 22118 and g_game.getTransferableTibiaCoins() or getDepotItemCount(itemId, tier)

	marketWindow.contentPanel.selectedItem:getItem():setCount(selCount)
	setAmount(getMarketPreviewAmountLabel(), selCount)
	resetSelectedItemPreviewVisual()
end

function refreshSelectedMarketBrowse()
	if table.empty(lastSelectedItem) or not lastSelectedItem.itemId or lastSelectedItem.itemId == 0 then
		return
	end

	lastItemID = 0
	lastItemTier = 0

	g_game.sendMarketAction(3, lastSelectedItem.itemId, lastSelectedItem.tier or 0)
end

local function applyMarketCoinPanels(transferableCoins, coinTooltip)
	marketWindow.contentPanel.coinPanel.gold:setText(comma_value(transferableCoins))
	marketWindow.contentPanel.coinPanel.gold:setTooltip(coinTooltip)
	marketWindow.MarketHistory.currentOffers.coinPanel.gold:setText(comma_value(transferableCoins))
	marketWindow.MarketHistory.currentOffers.coinPanel.gold:setTooltip(coinTooltip)

	local offerHistory = marketWindow.MarketHistory.offerHistory

	if offerHistory then
		offerHistory.coinPanel.gold:setText(comma_value(transferableCoins))
		offerHistory.coinPanel.gold:setTooltip(coinTooltip)
	end
end

local function refreshMarketTibiaCoinItemWidgets(transferableCoins)
	local selectedItem = marketWindow.contentPanel.selectedItem:getItem()

	if selectedItem and selectedItem:getId() == 22118 then
		selectedItem:setCount(transferableCoins)
		setAmount(getMarketPreviewAmountLabel(), transferableCoins)
	end

	local itemList = marketWindow:recursiveGetChildById("itemList")

	if not itemList then
		return
	end

	for _, widget in pairs(itemList:getChildren()) do
		local widgetItem = widget.item:getItem()

		if widgetItem and widgetItem:getId() == 22118 then
			widgetItem:setCount(transferableCoins)
			setAmount(widget.amount or widget:getChildById("amount"), transferableCoins)

			break
		end
	end
end

function onUpdateResourceValue()
	if not g_game.isOnline() or not marketWindow or not marketWindow:isVisible() then
		return
	end

	local player = g_game.getLocalPlayer()

	if not player then
		return
	end

	local playerBank = player:getResourceBalance(ResourceTypes.BANK_BALANCE)
	local playerInventory = player:getResourceBalance(ResourceTypes.GOLD_EQUIPPED)
	local normalCoins = player:getResourceBalance(ResourceTypes.COIN_NORMAL) or 0
	local transferableCoins = player:getResourceBalance(ResourceTypes.COIN_TRANSFERRABLE) or 0

	if transferableCoins == 0 then
		transferableCoins = g_game.getTransferableTibiaCoins() or 0
	end

	if normalCoins == 0 and transferableCoins == 0 then
		normalCoins = g_game.getTibiaCoins() or 0
	end

	g_game.setTibiaCoins(normalCoins, transferableCoins)

	local moneyTooltip = {}

	setStringColor(moneyTooltip, "Cash: " .. comma_value(playerInventory), "#3f3f3f")
	setStringColor(moneyTooltip, " $", "#f7e6fe")
	setStringColor(moneyTooltip, "\nBank: " .. comma_value(playerBank), "#3f3f3f")
	setStringColor(moneyTooltip, " $", "#f7e6fe")

	local coinTooltip = {}

	setStringColor(coinTooltip, "Total Tibia Coins: " .. comma_value(normalCoins + transferableCoins), "#3f3f3f")
	setStringColor(coinTooltip, " $", "#f7e6fe")
	setStringColor(coinTooltip, "\nIncluded transferable Tibia Coins: " .. comma_value(transferableCoins), "#3f3f3f")
	setStringColor(coinTooltip, " $", "#f7e6fe")

	local totalGold = playerBank + playerInventory

	marketWindow.contentPanel.moneyPanel.gold:setText(comma_value(totalGold))
	marketWindow.contentPanel.moneyPanel.gold:setTooltip(moneyTooltip)
	applyMarketCoinPanels(transferableCoins, coinTooltip)
	marketWindow.MarketHistory.currentOffers.moneyPanel.gold:setText(comma_value(totalGold))
	marketWindow.MarketHistory.currentOffers.moneyPanel.gold:setTooltip(moneyTooltip)

	local offerHistory = marketWindow.MarketHistory.offerHistory

	if offerHistory then
		offerHistory.moneyPanel.gold:setText(comma_value(totalGold))
		offerHistory.moneyPanel.gold:setTooltip(moneyTooltip)
	end

	refreshMarketTibiaCoinItemWidgets(transferableCoins)
end

local function refreshMarketSellOfferMoneyColors()
	local scroll = marketWindow:recursiveGetChildById("sellOffersListScroll")

	if scroll and scroll.onValueChange then
		scroll.onValueChange(scroll, scroll:getValue(), 0)
	end
end

function requestMarketGoldRefresh()
	if not g_game.isOnline() or not marketWindow or not marketWindow:isVisible() then
		return
	end

	onUpdateResourceValue()
	g_game.sendResourceBalance()
	scheduleEvent(function()
		if marketWindow and marketWindow:isVisible() then
			onUpdateResourceValue()
			refreshMarketSellOfferMoneyColors()
		end
	end, 150)
end

function onResourceBalance(resourceType, balance)
	if not marketWindow or not marketWindow:isVisible() then
		return
	end

	if resourceType == ResourceTypes.BANK_BALANCE or resourceType == ResourceTypes.GOLD_EQUIPPED then
		onUpdateResourceValue()
		refreshMarketSellOfferMoneyColors()
	elseif resourceType == ResourceTypes.COIN_NORMAL or resourceType == ResourceTypes.COIN_TRANSFERRABLE then
		onUpdateResourceValue()
	end
end

function onCoinBalance(coins, transferableCoins)
	if not marketWindow or not marketWindow:isVisible() then
		return
	end

	if coins and transferableCoins then
		g_game.setTibiaCoins(coins, transferableCoins)
	end

	onUpdateResourceValue()
end

function onMarketStoreGetCoin(coins, transferableCoins)
	if not marketWindow or not marketWindow:isVisible() then
		return
	end

	onCoinBalance(coins, transferableCoins)
end

function configureList()
	marketItems = {}
	allMarketItems = {}

	for c = MarketCategory.First, MarketCategory.WeaponsAll do
		marketItems[c] = {}
	end

	local types = g_things.findThingTypeByAttr(ThingAttrMarket, 0)

	for _, itemType in pairs(types) do
		if itemType:getId() == 49870 then
			-- block empty
		else
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

					if marketItems[marketData.category] ~= nil then
						table.insert(marketItems[marketData.category], marketItem)
					end

					table.insert(allMarketItems, marketItem)
				end
			end
		end
	end

	for c = MarketCategory.Ammunition, MarketCategory.WandsRods do
		for _, data in pairs(marketItems[c]) do
			table.insert(marketItems[MarketCategory.WeaponsAll], data)
		end
	end

	for c = MarketCategory.First, MarketCategory.WeaponsAll do
		if marketItems[c] then
			table.sort(marketItems[c], compareMarketItemsByNameCaseInsensitive)
		end
	end

	table.sort(allMarketItems, compareMarketItemsByNameCaseInsensitive)

	local MARKET_CATEGORY_NAMES = {
		"Armors",
		"Amulets",
		"Boots",
		"Containers",
		"Decoration",
		"Food",
		"Helmets and Hats",
		"Legs",
		"Others",
		"Potions",
		"Rings",
		"Runes",
		"Shields",
		"Tools",
		"Valuables",
		"Weapons: Ammo",
		"Weapons: Axes",
		"Weapons: Clubs",
		"Weapons: Distance",
		"Weapons: Swords",
		"Weapons: Wands",
		nil,
		"Tibia Coins",
		"Creature Products",
		"Quivers",
		"Soul Cores",
		"Weapons: Fist",
		nil,
		nil,
		nil,
		nil,
		"Weapons: All"
	}
	local hiddenMarketCategories = {
		[MarketCategory.PremiumScrolls] = true
	}

	for c = MarketCategory.First, MarketCategory.WeaponsAll do
		if marketItems[c] and #marketItems[c] > 0 and not MARKET_CATEGORY_NAMES[c] and not hiddenMarketCategories[c] then
			MARKET_CATEGORY_NAMES[c] = ("Category %d"):format(c)
		end
	end

	local marketCategoryOrder = {
		MarketCategory.Armors,
		MarketCategory.Amulets,
		MarketCategory.Boots,
		MarketCategory.Containers,
		MarketCategory.CreatureProducs,
		MarketCategory.Decoration,
		MarketCategory.Food,
		MarketCategory.HelmetsHats,
		MarketCategory.Legs,
		MarketCategory.Others,
		MarketCategory.Potions,
		MarketCategory.Quivers,
		MarketCategory.Rings,
		MarketCategory.Runes,
		MarketCategory.Shields,
		MarketCategory.SoulCore,
		MarketCategory.TibiaCoins,
		MarketCategory.Tools,
		MarketCategory.Valuables,
		MarketCategory.Ammunition,
		MarketCategory.Axes,
		MarketCategory.Clubs,
		MarketCategory.DistanceWeapons,
		MarketCategory.FistWeapons,
		MarketCategory.Swords,
		MarketCategory.WandsRods
	}

	categoryList = {}

	local addedCategories = {}

	local function addCategory(id)
		if addedCategories[id] or id == MarketCategory.WeaponsAll or hiddenMarketCategories[id] then
			return
		end

		local name = MARKET_CATEGORY_NAMES[id]

		if not name then
			return
		end

		table.insert(categoryList, {
			id,
			"category_" .. tostring(id),
			name
		})

		addedCategories[id] = true
	end

	for _, id in ipairs(marketCategoryOrder) do
		addCategory(id)
	end

	local leftover = {}

	for id, name in pairs(MARKET_CATEGORY_NAMES) do
		if not addedCategories[id] and id ~= MarketCategory.WeaponsAll and not hiddenMarketCategories[id] then
			table.insert(leftover, {
				id,
				"category_" .. tostring(id),
				name
			})
		end
	end

	table.sort(leftover, function(a, b)
		return a[1] < b[1]
	end)

	for _, entry in ipairs(leftover) do
		table.insert(categoryList, entry)
	end

	table.insert(categoryList, {
		MarketCategory.WeaponsAll,
		"weapons_all",
		"Weapons: All"
	})
end

local function updateCategoryRowColors()
	local category = marketWindow and marketWindow.contentPanel and marketWindow.contentPanel.category

	if not category then
		return
	end

	for i, child in ipairs(category:getChildren()) do
		local color = i % 2 == 1 and "#484848" or "#414141"

		child.color = color

		if child ~= lastSelectedCategory then
			child:setBackgroundColor(color)
			child:setColor("#c0c0c0")
		end
	end
end

local function updateCategoryShopButtons(categoryId)
	local mainMarket = marketWindow and marketWindow.contentPanel and marketWindow.contentPanel.mainMarket

	if not mainMarket then
		return
	end

	mainMarket.getPotionsButton:setVisible(categoryId == MarketCategory.Potions)
	mainMarket.getRunesButton:setVisible(categoryId == MarketCategory.Runes)
end

local function openStoreFromMarket(storeCategoryName)
	if not storeCategoryName or storeCategoryName == "" then
		return
	end

	if not modules.game_store or not modules.game_store.openStoreCategory then
		return
	end

	hideMarketWindow()
	modules.game_store.openStoreCategory(storeCategoryName)
end

function openStorePotionsCategory()
	openStoreFromMarket("Potions")
end

function openStoreRunesCategory()
	openStoreFromMarket("Runes")
end

local MY_OFFERS_END_WIDTH_CURRENT = 220
local MY_OFFERS_END_WIDTH_HISTORY = 150
local MY_OFFERS_STATUS_WIDTH = 58

local function applyMyOffersHeaderLayout(header, historyMode)
	if not header or not header.endButton then
		return
	end

	local endBtn = header.endButton
	local statusSep = header.statusSeparator
	local statusBtn = header.statusButton

	endBtn:breakAnchors()
	endBtn:addAnchor(AnchorTop, "parent", AnchorTop)
	endBtn:addAnchor(AnchorLeft, "totalpriceButton", AnchorRight)
	endBtn:setMarginLeft(2)

	if historyMode then
		endBtn:setText(tr("Ended At"))
		endBtn:setWidth(MY_OFFERS_END_WIDTH_HISTORY)
		endBtn:setMarginRight(0)
		statusSep:setVisible(true)
		statusBtn:setVisible(true)
		statusBtn:setWidth(MY_OFFERS_STATUS_WIDTH)
		statusSep:setMarginRight(1)
		endBtn:addAnchor(AnchorRight, statusSep:getId(), AnchorLeft)
	else
		endBtn:setText(tr("Ends At"))
		endBtn:setWidth(MY_OFFERS_END_WIDTH_CURRENT)
		statusSep:setVisible(false)
		statusBtn:setVisible(false)
		endBtn:addAnchor(AnchorRight, "parent", AnchorRight)
		endBtn:setMarginRight(12)
	end
end

function setMyOffersHeaderHistoryMode(historyMode)
	local currentOffers = marketWindow and marketWindow.MarketHistory and marketWindow.MarketHistory.currentOffers

	if not currentOffers or not currentOffers.sellOffersHeader then
		return
	end

	applyMyOffersHeaderLayout(currentOffers.sellOffersHeader, historyMode)
	applyMyOffersHeaderLayout(currentOffers.buyOffersHeader, historyMode)
end

function resetMyOffersPanelView()
	if not marketWindow or not marketWindow.MarketHistory then
		return
	end

	local window = marketWindow.MarketHistory.currentOffers

	if not window then
		return
	end

	setMyOffersHeaderHistoryMode(false)
	MarketHistory.clearPools()

	MarketOwnOffers.myBuyOffers = {}
	MarketOwnOffers.mySellOffers = {}
	lastSelectedMySell = nil
	lastSelectedMyBuy = nil
	lastSelectedHistorySell = nil
	lastSelectedHistoryBuy = nil

	if window.sellOffersList then
		window.sellOffersList:focusChild(nil)
		window.sellOffersList:destroyChildren()
	end

	if window.buyOffersList then
		window.buyOffersList:focusChild(nil)
		window.buyOffersList:destroyChildren()
	end

	if window.buyCancelOffer then
		window.buyCancelOffer:setVisible(true)
		window.buyCancelOffer:setEnabled(false)
	end

	if window.sellCancelOffer then
		window.sellCancelOffer:setVisible(true)
		window.sellCancelOffer:setEnabled(false)
	end

	local sellScrollbar = marketWindow.MarketHistory:recursiveGetChildById("sellOffersListScroll")
	local buyScrollbar = marketWindow.MarketHistory:recursiveGetChildById("buyOffersListScroll")

	if sellScrollbar then
		sellScrollbar.onValueChange = nil

		sellScrollbar:setValue(0)
		sellScrollbar:setMinimum(0)
		sellScrollbar:setMaximum(0)
	end

	if buyScrollbar then
		buyScrollbar.onValueChange = nil

		buyScrollbar:setValue(0)
		buyScrollbar:setMinimum(0)
		buyScrollbar:setMaximum(0)
	end

	if window.sellOffersLabel then
		window.sellOffersLabel:setText("Sell Offers (0):")
	end

	if window.buyOffersLabel then
		window.buyOffersLabel:setText("Buy Offers (0):")
	end
end

function onMarketEnter(offerCount, items)
	configureList()

	depotLockerItems = items

	marketWindow.contentPanel.category:destroyChildren()

	for _, pair in ipairs(categoryList) do
		local widget = g_ui.createWidget("CategoryItemListLabel", marketWindow.contentPanel.category)

		widget:setActionId(pair[1])
		widget:setId(pair[2])
		widget:setText(pair[3])
	end

	local lastWidget = marketWindow.contentPanel.category:getChildById("weapons_all")

	if lastWidget then
		local lastIndex = marketWindow.contentPanel.category:getChildCount()

		marketWindow.contentPanel.category:moveChildToIndex(lastWidget, lastIndex)
	end

	updateCategoryRowColors()

	local prev = suppressFilterCallbacks

	suppressFilterCallbacks = true

	marketWindow.contentPanel.classFilter:clearOptions()
	marketWindow.contentPanel.tierFilter:clearOptions()

	suppressFilterCallbacks = prev

	local itemListScroll = marketWindow:recursiveGetChildById("itemListScroll")

	itemListScroll:setValue(0)
	itemListScroll:setMinimum(0)
	itemListScroll:setMaximum(0)

	itemListScroll.onValueChange = nil

	function marketWindow.contentPanel.category:onChildFocusChange(selected)
		onSelectChildCategory(self, selected)
	end

	if marketWindow:isVisible() then
		if not table.empty(lastSelectedItem) then
			refreshSelectedItemDepotDisplay()
		end

		requestMarketGoldRefresh()

		return
	end

	show()
	marketWindow:focus()
	requestMarketGoldRefresh()
end

-- The engine emits onMarketBrowse(intOffers, nameOffers, browseState, tier), where each intOffer is
-- {action, amount, counter, itemId, price, state, timestamp, var, tier}, while the module expects
-- (browseState, tier, buyList, sellList) with offers as tables with named fields.
-- Without this, 'browseState' received the offer list and the browseState ~= 3 condition always passed.
local MARKET_ACTION_BUY = 0

function onEngineMarketBrowse(intOffers, nameOffers, browseState, tier)
	local buyList = {}
	local sellList = {}

	for i, raw in ipairs(intOffers or {}) do
		local entry = {
			action = raw[1],
			amount = raw[2],
			counter = raw[3],
			itemId = raw[4],
			price = raw[5],
			state = raw[6],
			timestamp = raw[7],
			tier = raw[9] or 0,
			playerName = nameOffers and nameOffers[i] or ""
		}

		if entry.action == MARKET_ACTION_BUY then
			table.insert(buyList, entry)
		else
			table.insert(sellList, entry)
		end
	end

	-- Requests 1 and 2 are not item browsing. Route them directly to the
	-- corresponding panels; onMarketBrowse intentionally handles only action 3.
	if browseState == 1 then
		g_logger.info(string.format("[market] history received: %d buy, %d sell", #buyList, #sellList))
		MarketHistory.onParseMarketHistory(buyList, sellList)
		return
	elseif browseState == 2 then
		g_logger.info(string.format("[market] own offers received: %d buy, %d sell", #buyList, #sellList))
		MarketOwnOffers.onParseMyOffers(buyList, sellList)
		return
	end

	onMarketBrowse(browseState, tier, buyList, sellList)
end

function onMarketBrowse(browseState, tier, buyList, sellList)
	if table.empty(lastSelectedItem) then
		return
	end

	if browseState ~= 3 then
		return
	end

	local itemId = lastSelectedItem.itemId
	local itemTier = lastSelectedItem.tier or 0

	if lastItemID ~= 0 and (itemId ~= lastItemID or itemTier ~= (lastItemTier or 0)) then
		return
	end

	local hasCachedOffers = #buyOffers > 0 or #sellOffers > 0
	local isIncrementalContext = lastItemID == itemId and lastItemTier == itemTier
	local isPartialUpdate = isPartialMarketBrowseUpdate(buyList, sellList)

	if isIncrementalContext or hasCachedOffers and isPartialUpdate then
		buyOffers = mergeMarketOfferList(buyOffers, buyList)
		sellOffers = mergeMarketOfferList(sellOffers, sellList)
	else
		buyOffers = buyList or {}
		sellOffers = sellList or {}

		pruneConsumedOffers(buyOffers)
		pruneConsumedOffers(sellOffers)
	end

	sortByUnitPriceDesc(buyOffers)
	sortByUnitPriceAsc(sellOffers)

	cache.SCROLL_BUY_OFFERS.listFit = math.floor(mainMarket.buyOffersList:getHeight() / 16) - 1
	cache.SCROLL_BUY_OFFERS.listMin = 0
	cache.SCROLL_BUY_OFFERS.listPool = {}
	cache.SCROLL_BUY_OFFERS.listData = buyOffers
	cache.SCROLL_BUY_OFFERS.lastSelected = 0

	mainMarket.buyOffersList:destroyChildren()

	for i, data in ipairs(buyOffers) do
		if i > cache.SCROLL_BUY_OFFERS.listFit then
			break
		end

		local widget = g_ui.createWidget("MarketOfferWidget", mainMarket.buyOffersList)
		local color = i % 2 == 1 and "#484848" or "#414141"
		local holder = data.playerName or ""

		widget:setId(color)
		widget:setActionId(i)
		widget:setBackgroundColor(color)
		widget.name:setText(short_text(holder, 15))
		widget.amount:setText(tostring(data.amount or 0))
		widget.endAt:setText(os.date("%Y-%m-%d, %H:%M:%S", data.timestamp or 0))

		local totalPrice = (data.price or 0) * (data.amount or 0)
		local unitPrice = data.price or 0

		widget.piecePrice:setText(convertGold(unitPrice))
		widget.totalPrice:setText(convertGold(totalPrice))

		if #holder >= 15 then
			widget.name:setTooltip(holder)
		end

		local count = getDepotItemCount(itemId, itemTier)
		local colorText = count > 0 and "#c0c0c0" or "#808080"

		widget.piecePrice:setColor(colorText)
		widget.totalPrice:setColor(colorText)
		widget.name:setColor(colorText)
		widget.amount:setColor(colorText)
		widget.endAt:setColor(colorText)
		table.insert(cache.SCROLL_BUY_OFFERS.listPool, widget)
	end

	cache.SCROLL_BUY_OFFERS.listMin = #buyOffers > 0 and 1 or 0
	cache.SCROLL_BUY_OFFERS.listMax = #buyOffers + 1

	local buyListScroll = marketWindow:recursiveGetChildById("buyOffersListScroll")

	buyListScroll:setValue(cache.SCROLL_BUY_OFFERS.listMin)
	buyListScroll:setMinimum(cache.SCROLL_BUY_OFFERS.listMin)
	buyListScroll:setMaximum(#cache.SCROLL_BUY_OFFERS.listPool < 11 and 0 or math.max(0, cache.SCROLL_BUY_OFFERS.listMax - #cache.SCROLL_BUY_OFFERS.listPool))

	function buyListScroll:onValueChange(value, delta)
		onBuyListValueChange(self, value, delta)
	end

	cache.SCROLL_SELL_OFFERS.listFit = math.floor(mainMarket.sellOffersList:getHeight() / 16) - 1
	cache.SCROLL_SELL_OFFERS.listMin = 0
	cache.SCROLL_SELL_OFFERS.listPool = {}
	cache.SCROLL_SELL_OFFERS.listData = sellOffers
	cache.SCROLL_SELL_OFFERS.lastSelected = 0

	mainMarket.sellOffersList:destroyChildren()

	for i, data in ipairs(sellOffers) do
		if i > cache.SCROLL_SELL_OFFERS.listFit then
			break
		end

		local widget = g_ui.createWidget("MarketOfferWidget", mainMarket.sellOffersList)
		local color = i % 2 == 1 and "#484848" or "#414141"
		local holder = data.playerName or ""

		widget:setId(color)
		widget:setActionId(i)
		widget:setBackgroundColor(color)
		widget.name:setText(short_text(holder, 15))
		widget.amount:setText(tostring(data.amount or 0))
		widget.endAt:setText(os.date("%Y-%m-%d, %H:%M:%S", data.timestamp or 0))

		local totalPrice = (data.price or 0) * (data.amount or 0)
		local unitPrice = data.price or 0

		widget.piecePrice:setText(convertGold(unitPrice))
		widget.totalPrice:setText(convertGold(totalPrice))

		if #holder >= 15 then
			widget.name:setTooltip(holder)
		end

		if totalPrice > 99999999 then
			widget.totalPrice:setTooltip(comma_value(totalPrice))
		end

		if unitPrice > 99999999 then
			widget.piecePrice:setTooltip(comma_value(unitPrice))
		end

		local hasMoney = unitPrice <= getTotalMoney()
		local colorText = hasMoney and "#c0c0c0" or "#808080"

		widget.piecePrice:setColor(colorText)
		widget.totalPrice:setColor(colorText)
		widget.name:setColor(colorText)
		widget.amount:setColor(colorText)
		widget.endAt:setColor(colorText)
		table.insert(cache.SCROLL_SELL_OFFERS.listPool, widget)
	end

	cache.SCROLL_SELL_OFFERS.listMin = #sellOffers > 0 and 1 or 0
	cache.SCROLL_SELL_OFFERS.listMax = #sellOffers + 1

	local sellListScroll = marketWindow:recursiveGetChildById("sellOffersListScroll")

	sellListScroll:setValue(cache.SCROLL_SELL_OFFERS.listMin)
	sellListScroll:setMinimum(cache.SCROLL_SELL_OFFERS.listMin)
	sellListScroll:setMaximum(#cache.SCROLL_SELL_OFFERS.listPool < 11 and 0 or math.max(0, cache.SCROLL_SELL_OFFERS.listMax - #cache.SCROLL_SELL_OFFERS.listPool))

	function sellListScroll:onValueChange(value, delta)
		onSellListValueChange(self, value, delta)
	end

	lastItemID = itemId
	lastItemTier = itemTier

	function mainMarket.sellOffersList:onChildFocusChange(selected, oldFocus)
		onSelectSellOffer(self, selected, oldFocus)
	end

	function mainMarket.buyOffersList:onChildFocusChange(selected, oldFocus)
		onSelectBuyOffer(self, selected, oldFocus)
	end

	onUpdateChildItem(itemId, itemTier)

	local firstChild = mainMarket.sellOffersList:getChildren()[1]

	if firstChild then
		mainMarket.sellOffersList:focusChild(firstChild)
	end

	firstChild = mainMarket.buyOffersList:getChildren()[1]

	if firstChild then
		mainMarket.buyOffersList:focusChild(firstChild)
	end

	onUpdateResourceValue()
end

function onBuyListValueChange(scroll, value, delta)
	local startLabel = math.max(cache.SCROLL_BUY_OFFERS.listMin, value)
	local endLabel = startLabel + #cache.SCROLL_BUY_OFFERS.listPool - 1

	if endLabel > cache.SCROLL_BUY_OFFERS.listMax then
		endLabel = cache.SCROLL_BUY_OFFERS.listMax
		startLabel = endLabel - #cache.SCROLL_BUY_OFFERS.listPool + 1
	end

	for i, widget in ipairs(cache.SCROLL_BUY_OFFERS.listPool) do
		local index = startLabel + i - 1
		local data = cache.SCROLL_BUY_OFFERS.listData[index]

		if data then
			local color = index % 2 == 1 and "#484848" or "#414141"
			local holder = data.playerName or ""

			widget:setId(color)
			widget:setActionId(index)
			widget:setBackgroundColor(color)
			widget.name:setText(short_text(holder, 15))
			widget.amount:setText(tostring(data.amount or 0))
			widget.endAt:setText(os.date("%Y-%m-%d, %H:%M:%S", data.timestamp or 0))

			if #holder >= 15 then
				widget.name:setTooltip(holder)
			end

			local totalPrice = (data.price or 0) * (data.amount or 0)
			local unitPrice = data.price or 0

			widget.piecePrice:setText(convertGold(unitPrice))
			widget.totalPrice:setText(convertGold(totalPrice))

			local count = getDepotItemCount(lastSelectedItem.itemId, lastSelectedItem.tier or 0)

			widget.piecePrice:setColor(count > 0 and "#c0c0c0" or "#808080")
			widget.totalPrice:setColor(count > 0 and "#c0c0c0" or "#808080")
			widget.name:setColor(count > 0 and "#c0c0c0" or "#808080")
			widget.amount:setColor(count > 0 and "#c0c0c0" or "#808080")
			widget.endAt:setColor(count > 0 and "#c0c0c0" or "#808080")

			if index == cache.SCROLL_BUY_OFFERS.lastSelected then
				widget:setBackgroundColor("#585858")
				widget.piecePrice:setColor("#f4f4f4")
				widget.totalPrice:setColor("#f4f4f4")
				widget.name:setColor("#f4f4f4")
				widget.amount:setColor("#f4f4f4")
				widget.endAt:setColor("#f4f4f4")
			end
		end
	end
end

function onSellListValueChange(scroll, value, delta)
	local startLabel = math.max(cache.SCROLL_SELL_OFFERS.listMin, value)
	local endLabel = startLabel + #cache.SCROLL_SELL_OFFERS.listPool - 1

	if endLabel > cache.SCROLL_SELL_OFFERS.listMax then
		endLabel = cache.SCROLL_SELL_OFFERS.listMax
		startLabel = endLabel - #cache.SCROLL_SELL_OFFERS.listPool + 1
	end

	for i, widget in ipairs(cache.SCROLL_SELL_OFFERS.listPool) do
		local index = startLabel + i - 1
		local data = cache.SCROLL_SELL_OFFERS.listData[index]

		if data then
			local color = index % 2 == 1 and "#484848" or "#414141"
			local holder = data.playerName or ""

			widget:setId(color)
			widget:setActionId(index)
			widget:setBackgroundColor(color)
			widget.name:setText(short_text(holder, 15))
			widget.amount:setText(tostring(data.amount or 0))
			widget.endAt:setText(os.date("%Y-%m-%d, %H:%M:%S", data.timestamp or 0))

			local totalPrice = (data.price or 0) * (data.amount or 0)
			local unitPrice = data.price or 0

			widget.piecePrice:setText(convertGold(unitPrice))
			widget.totalPrice:setText(convertGold(totalPrice))

			if #holder >= 15 then
				widget.name:setTooltip(holder)
			end

			if totalPrice > 99999999 then
				widget.totalPrice:setTooltip(comma_value(totalPrice))
			end

			if unitPrice > 99999999 then
				widget.piecePrice:setTooltip(comma_value(unitPrice))
			end

			local hasMoney = unitPrice <= getTotalMoney()

			widget.piecePrice:setColor(hasMoney and "#c0c0c0" or "#808080")
			widget.totalPrice:setColor(hasMoney and "#c0c0c0" or "#808080")
			widget.name:setColor(hasMoney and "#c0c0c0" or "#808080")
			widget.amount:setColor(hasMoney and "#c0c0c0" or "#808080")
			widget.endAt:setColor(hasMoney and "#c0c0c0" or "#808080")

			if index == cache.SCROLL_SELL_OFFERS.lastSelected then
				widget:setBackgroundColor("#585858")
				widget.piecePrice:setColor("#f4f4f4")
				widget.totalPrice:setColor("#f4f4f4")
				widget.name:setColor("#f4f4f4")
				widget.amount:setColor("#f4f4f4")
				widget.endAt:setColor("#f4f4f4")
			end
		end
	end
end

function onSelectChildCategory(widget, selected, keepFilter)
	lastSelectedCategory = nil

	updateCategoryRowColors()

	local itemList = marketWindow:recursiveGetChildById("itemList")

	if not itemList then
		return true
	end

	lastSelectedCategory = selected

	selected:setBackgroundColor("#585858")
	selected:setColor("#f4f4f4")
	resetItemListScrollOffset(itemList)

	cache.SCROLL_MARKET_ITEMS.listFit = getMarketItemListFit(itemList)
	cache.SCROLL_MARKET_ITEMS.listMin = 0
	cache.SCROLL_MARKET_ITEMS.listPool = {}
	cache.SCROLL_MARKET_ITEMS.listData = {}
	cache.SCROLL_SELL_OFFERS.lastSelected = 0
	cache.SCROLL_BUY_OFFERS.lastSelected = 0

	marketWindow.contentPanel.itemList:destroyChildren()

	local clearHands = not lastSelectedCategory or not table.contains(enableCategories, lastSelectedCategory:getActionId())

	lastSelectedItem = {}

	onClearSearch(clearHands)
	onClearMainMarket(true)
	updateCategoryShopButtons(nil)

	if table.contains(enableCategories, selected:getActionId()) then
		marketWindow.contentPanel.oneButton:setEnabled(true)
		marketWindow.contentPanel.twoButton:setEnabled(true)
	else
		onClearHandFilter()
	end

	if not keepFilter then
		sortButtons.classFilter = -1
		sortButtons.tierFilter = 0

		if table.contains(enableClassification, selected:getActionId()) then
			local prev = suppressFilterCallbacks

			suppressFilterCallbacks = true

			marketWindow.contentPanel.classFilter:clearOptions()
			marketWindow.contentPanel.classFilter:addOption("All", nil, true)
			marketWindow.contentPanel.classFilter:addOption("None", nil, true)

			for i = 1, 4 do
				marketWindow.contentPanel.classFilter:addOption("Class " .. i, nil, true)
			end

			marketWindow.contentPanel.tierFilter:clearOptions()

			for i = 0, 10 do
				marketWindow.contentPanel.tierFilter:addOption("Tier " .. i, nil, true)
			end

			suppressFilterCallbacks = prev
		else
			local prev = suppressFilterCallbacks

			suppressFilterCallbacks = true

			marketWindow.contentPanel.classFilter:clearOptions()
			marketWindow.contentPanel.tierFilter:clearOptions()

			suppressFilterCallbacks = prev
		end
	end

	resetMarketPreviewPanel()

	function itemList:onChildFocusChange(sel, oldFocus)
		onSelectChildItem(self, sel, oldFocus)
	end

	local tier = sortButtons.tierFilter or 0

	for _, itemInfo in pairs(marketItems[selected:getActionId()]) do
		if not checkSortMarketOptions(itemInfo) then
			-- block empty
		else
			local id = itemInfo.thingType:getId()
			local hasCount = 1

			if showLockerOnly then
				hasCount = getDepotItemCount(id, tier)

				if hasCount == 0 and tier > 0 then
					hasCount = getDepotItemCount(id, 0)
				end
			end

			if showLockerOnly and hasCount == 0 then
				-- block empty
			else
				table.insert(cache.SCROLL_MARKET_ITEMS.listData, itemInfo)
			end
		end
	end

	createVisibleItemWidgets(itemList, tier)

	cache.SCROLL_MARKET_ITEMS.listMax = #cache.SCROLL_MARKET_ITEMS.listData

	setupItemListScrollbar(itemList)
	updateCategoryShopButtons(selected:getActionId())
	resetMarketPreviewPanel()
end

function createVisibleItemWidgets(itemList, tier)
	resetItemListScrollOffset(itemList)

	local visibleCount = cache.SCROLL_MARKET_ITEMS.listFit or 8
	local created = 0

	for i = 1, math.min(visibleCount, #cache.SCROLL_MARKET_ITEMS.listData) do
		local itemInfo = cache.SCROLL_MARKET_ITEMS.listData[i]

		if itemInfo then
			local widget = createItemWidget(itemList, itemInfo, i, tier)

			if widget then
				table.insert(cache.SCROLL_MARKET_ITEMS.listPool, widget)

				created = created + 1
			end
		end
	end
end

function createItemWidget(itemList, itemInfo, index, tier)
	if not itemInfo then
		return nil
	end

	local id = itemInfo.thingType:getId()
	local t = tier or 0
	local count = getDepotItemCount(id, t)

	if showLockerOnly and count == 0 and t > 0 then
		count = getDepotItemCount(id, 0)
	end

	if not checkSortMarketOptions(itemInfo) or showLockerOnly and count == 0 then
		return nil
	end

	local widget = g_ui.createWidget("MarketItemList", itemList)

	widget.item:setItemId(id)
	widget.name:setText(itemInfo.marketData.name)

	if widget.name:isOfflimit(20) then
		widget.name:setText(short_text(itemInfo.marketData.name, 20))
		widget.name:setTooltip(itemInfo.marketData.name)
	end

	widget:setBackgroundColor("#404040")
	widget.item:getItem():setCount(count)
	widget.item:setActionId(index)
	widget.item:setTooltip(tr("%s%s%s%s", comma_value(count), "x", count > 65000 and "+ " or " ", itemInfo.marketData.name))
	setAmount(widget.amount or widget:getChildById("amount"), count)
	widget.item:getItem():setTier(t)
	applyMarketItemTierBadge(widget, t)

	if not widget.name:isTextWrap() then
		widget.name:setMarginTop(1)
	end

	applyMarketItemRarity(widget.rarity, id)
	applyMarketItemNameColor(widget.name, count)
	applyMarketItemSlotOpacity(widget, count)

	return widget
end

function onItemListValueChange(scroll, value, delta)
	local itemList = marketWindow:recursiveGetChildById("itemList")

	if not itemList then
		return
	end

	resetItemListScrollOffset(itemList)

	local visibleCount = cache.SCROLL_MARKET_ITEMS.listFit or 8
	local startIndex = value + 1
	local tier = sortButtons.tierFilter or 0

	for i, widget in ipairs(cache.SCROLL_MARKET_ITEMS.listPool) do
		local dataIndex = startIndex + i - 1
		local itemData = cache.SCROLL_MARKET_ITEMS.listData[dataIndex]

		if itemData and dataIndex <= #cache.SCROLL_MARKET_ITEMS.listData then
			updateItemWidget(widget, itemData, dataIndex)
			widget:setVisible(true)
		else
			widget:setVisible(false)
		end
	end
end

function updateItemWidget(widget, data, index)
	local isSelected = lastSelectedItem.itemId == data.thingType:getId()

	if data.tier then
		isSelected = lastSelectedItem.itemId == data.thingType:getId() and data.tier == lastSelectedItem.tier
	end

	widget:setBackgroundColor(isSelected and "#585858" or "#404040")

	if isSelected then
		lastSelectedItem.lastWidget = widget
	end

	local tier = sortButtons.tierFilter or 0
	local id = data.thingType:getId()
	local count = getDepotItemCount(id, tier)

	if showLockerOnly and count == 0 and tier > 0 then
		count = getDepotItemCount(id, 0)
	end

	if not widget.item then
		return
	end

	widget.item:setItemId(id)
	widget.name:setTooltip("")
	widget.name:setText(data.marketData.name)

	if widget.name:isOfflimit(20) then
		widget.name:setText(short_text(data.marketData.name, 20))
		widget.name:setTooltip(data.marketData.name)
	end

	widget.item:getItem():setCount(count)
	widget.item:setActionId(index)
	widget.item:setTooltip(tr("%s%s%s%s", comma_value(count), "x", count > 65000 and "+ " or " ", data.marketData.name))
	widget.item:setTier(data.tier and data.tier or tier)
	setAmount(widget.amount or widget:getChildById("amount"), count)
	applyMarketItemTierBadge(widget, data.tier or tier)

	if not widget.name:isTextWrap() then
		widget.name:setMarginTop(1)
	end

	applyMarketItemRarity(widget.rarity, id)
	applyMarketItemNameColor(widget.name, count)
	applyMarketItemSlotOpacity(widget, count)
end

function onUpdateChildItem(itemID, tier)
	for _, widget in pairs(marketWindow.contentPanel.itemList:getChildren()) do
		if widget.item:getItem():getId() == itemID and widget.item:getItem():getTier() == tier then
			local count = itemID == 22118 and g_game.getTransferableTibiaCoins() or getDepotItemCount(itemID, tier)

			if lastSelectedCategory then
				local itemInfo = marketItems[lastSelectedCategory:getActionId()][widget.item:getActionId()]

				widget.item:setTooltip(tr("%s%s%s%s", comma_value(count), "x", count > 65000 and "+ " or " ", itemInfo.marketData.name))
			end

			widget.item:getItem():setCount(count)
			setAmount(widget.amount or widget:getChildById("amount"), count)
			applyMarketItemNameColor(widget.name, count)
			applyMarketItemSlotOpacity(widget, count)

			break
		end
	end

	local firstChild = mainMarket.sellOffersList:getChildren()[1]

	if firstChild then
		mainMarket.sellOffersList:onChildFocusChange(firstChild, nil, KeyboardFocusReason)
	end

	firstChild = mainMarket.buyOffersList:getChildren()[1]

	if firstChild then
		mainMarket.buyOffersList:onChildFocusChange(firstChild, nil, KeyboardFocusReason)
	end

	if lastSelectedItem and lastSelectedItem.itemId == itemID and lastSelectedItem.tier == tier then
		local selCount = itemID == 22118 and g_game.getTransferableTibiaCoins() or getDepotItemCount(itemID, tier)

		setAmount(getMarketPreviewAmountLabel(), selCount)
		resetSelectedItemPreviewVisual()

		if lastSelectedItem.lastWidget then
			applyMarketItemSlotOpacity(lastSelectedItem.lastWidget, selCount)
		end
	end
end

function onSelectChildItem(widget, selected, oldFocus)
	if not selected then
		return
	end

	if oldFocus then
		oldFocus:setBackgroundColor("#404040")
		restoreMarketListItemRow(oldFocus)
	end

	if lastSelectedItem.lastWidget then
		lastSelectedItem.lastWidget:setBackgroundColor("#404040")
		restoreMarketListItemRow(lastSelectedItem.lastWidget)
	end

	selected:setBackgroundColor("#585858")

	local itemID = selected.item:getItemId()
	local itemTier = selected.item:getItem():getTier()

	if lastSelectedItem.itemId == itemID and lastSelectedItem.tier == itemTier then
		return true
	end

	marketWindow.contentPanel.selectedItem:setItemId(itemID)
	marketWindow.contentPanel.selectedItem:setTier(itemTier)
	applyMarketItemTierBadge(marketWindow.contentPanel, itemTier)
	applyMarketItemRarity(marketWindow.contentPanel.rarity, itemID)

	lastSelectedItem = {
		itemId = itemID,
		tier = itemTier,
		lastWidget = widget
	}

	local selCount

	if itemID == 22118 then
		selCount = g_game.getTransferableTibiaCoins()

		marketWindow.contentPanel.selectedItem:getItem():setCount(selCount)
	else
		selCount = getDepotItemCount(itemID, itemTier)

		marketWindow.contentPanel.selectedItem:getItem():setCount(selCount)
	end

	setAmount(getMarketPreviewAmountLabel(), selCount)
	applyMarketItemNameColor(selected.name, selCount)
	applyMarketItemSlotOpacity(selected, selCount)
	resetSelectedItemPreviewVisual()
	onClearMainMarket(false)
	g_game.sendMarketAction(3, itemID, selected.item:getItem():getTier())
end

function onClearMainMarket(cleanList)
	buyOffers = {}
	sellOffers = {}
	MarketOwnOffers.mySellOffers = {}
	MarketOwnOffers.myBuyOffers = {}
	lastItemID = 0
	lastItemTier = 0
	lastSelectedHistorySell = nil
	lastSelectedHistoryBuy = nil

	mainMarket.sellAcceptButton:setEnabled(false)
	mainMarket.buyAcceptButton:setEnabled(false)
	mainMarket.sellOffersList:destroyChildren()
	mainMarket.buyOffersList:destroyChildren()
	setMarketAmountScrollRange(mainMarket.amountSellScrollBar, 0, 0)
	setMarketAmountScrollRange(mainMarket.amountBuyScrollBar, 0, 0)
	mainMarket.piecePriceCreate:clearText()
	marketWindow.contentPanel.detailsMarket.detailsList:destroyChildren()
	marketWindow.contentPanel.detailsMarket.statisticsList:destroyChildren()

	if cleanList then
		clearMarketItemRefs()
		updateSellCount(nil, 0)
		updateBuyCount(nil, 0)
		resetMarketPreviewPanel()
		marketWindow.contentPanel.itemList:destroyChildren()
	end

	cache.SCROLL_BUY_OFFERS.listMin = 0
	cache.SCROLL_BUY_OFFERS.listMax = 0
	cache.SCROLL_BUY_OFFERS.listFit = 0
	cache.SCROLL_BUY_OFFERS.listMin = 0
	cache.SCROLL_BUY_OFFERS.listPool = {}
	cache.SCROLL_BUY_OFFERS.listData = {}
	cache.SCROLL_BUY_OFFERS.lastSelected = 0
	cache.SCROLL_SELL_OFFERS.listMin = 0
	cache.SCROLL_SELL_OFFERS.listMax = 0
	cache.SCROLL_SELL_OFFERS.listFit = 0
	cache.SCROLL_SELL_OFFERS.listMin = 0
	cache.SCROLL_SELL_OFFERS.listPool = {}
	cache.SCROLL_SELL_OFFERS.listData = {}
	cache.SCROLL_SELL_OFFERS.lastSelected = 0

	local buyListScroll = marketWindow:recursiveGetChildById("buyOffersListScroll")

	buyListScroll.onValueChange = nil

	buyListScroll:setValue(0)
	buyListScroll:setMinimum(0)
	buyListScroll:setMaximum(0)

	local sellListScroll = marketWindow:recursiveGetChildById("sellOffersListScroll")

	sellListScroll.onValueChange = nil

	sellListScroll:setValue(0)
	sellListScroll:setMinimum(0)
	sellListScroll:setMaximum(0)
end

function toggleShowLockerOnly(widget, checked)
	showLockerOnly = checked

	if not lastSelectedCategory then
		if #marketWindow.contentPanel.searchText:getText() > 0 then
			onSearchItem(marketWindow.contentPanel.searchText)
		end

		return true
	end

	onSelectChildCategory(nil, lastSelectedCategory, true)
end

function onSelectSellOffer(widget, selected, oldFocus)
	if not selected then
		return
	end

	local money = getTotalMoney()

	if oldFocus then
		local offer = sellOffers[cache.SCROLL_SELL_OFFERS.lastSelected]
		local offerPrice = offer and offer.price or 0
		local color = offerPrice <= money and "#c0c0c0" or "#808080"

		oldFocus:setBackgroundColor(oldFocus:getId())
		oldFocus.piecePrice:setColor(color)
		oldFocus.totalPrice:setColor(color)
		oldFocus.name:setColor(color)
		oldFocus.amount:setColor(color)
		oldFocus.endAt:setColor(color)
	end

	selected:setBackgroundColor("#585858")
	selected.piecePrice:setColor("#f4f4f4")
	selected.totalPrice:setColor("#f4f4f4")
	selected.name:setColor("#f4f4f4")
	selected.amount:setColor("#f4f4f4")
	selected.endAt:setColor("#f4f4f4")

	cache.SCROLL_SELL_OFFERS.lastSelected = selected:getActionId()

	local currentOffer = sellOffers[cache.SCROLL_SELL_OFFERS.lastSelected]
	local unitPrice = currentOffer.price or 0

	if unitPrice <= 0 then
		unitPrice = 1
	end

	if money < unitPrice then
		mainMarket.sellAcceptButton:setEnabled(false)
		updateSellCount(nil, 0)
		setMarketAmountScrollRange(mainMarket.amountSellScrollBar, 0, 0)

		return
	end

	local maxValue = math.min(currentOffer.amount or 0, math.floor(money / unitPrice))

	mainMarket.amountSellScrollBar:setValue(1)
	setMarketAmountScrollRange(mainMarket.amountSellScrollBar, 1, maxValue)
	mainMarket.amountSellScrollBar:setIncrementStep(1)
	mainMarket.totalValue:setText(comma_value(currentOffer.price or 0))
	mainMarket.sellAcceptButton:setEnabled(true)

	local startValue = 1

	if not table.empty(lastSelectedItem) and lastSelectedItem.itemId == 22118 then
		local sellCount = math.floor(money / (unitPrice * 25))

		if sellCount > 0 then
			setMarketAmountScrollRange(mainMarket.amountSellScrollBar, 25, math.min(currentOffer.amount or 0, sellCount * 25))
			mainMarket.amountSellScrollBar:setValue(25)
			mainMarket.sellAcceptButton:setEnabled(true)
			mainMarket.amountSellScrollBar:setStep(25)
			mainMarket.amountSellScrollBar:setIncrementStep(25)

			startValue = 25
		else
			setMarketAmountScrollRange(mainMarket.amountSellScrollBar, 0, 0)
			mainMarket.amountSellScrollBar:setValue(0)
			mainMarket.sellAcceptButton:setEnabled(false)

			startValue = 0
		end
	end

	updateSellCount(nil, startValue)

	local sellListScroll = marketWindow:recursiveGetChildById("sellOffersListScroll")

	if cache.SCROLL_SELL_OFFERS.listFit > 11 then
		onSellListValueChange(sellListScroll, sellListScroll:getValue(), 0)
	end
end

function onSelectBuyOffer(widget, selected, oldFocus)
	if not selected or table.empty(lastSelectedItem) then
		return
	end

	local count = getDepotItemCount(lastSelectedItem.itemId, lastSelectedItem.tier or 0)

	if oldFocus then
		local color = count > 0 and "#c0c0c0" or "#808080"

		oldFocus:setBackgroundColor(oldFocus:getId())
		oldFocus.piecePrice:setColor(color)
		oldFocus.totalPrice:setColor(color)
		oldFocus.name:setColor(color)
		oldFocus.amount:setColor(color)
		oldFocus.endAt:setColor(color)
	end

	selected:setBackgroundColor("#585858")
	selected.piecePrice:setColor("#f4f4f4")
	selected.totalPrice:setColor("#f4f4f4")
	selected.name:setColor("#f4f4f4")
	selected.amount:setColor("#f4f4f4")
	selected.endAt:setColor("#f4f4f4")

	cache.SCROLL_BUY_OFFERS.lastSelected = selected:getActionId()

	if count == 0 then
		mainMarket.buyAcceptButton:setEnabled(false)
		setMarketAmountScrollRange(mainMarket.amountBuyScrollBar, 0, 0)
		updateBuyCount(nil, 0)

		return
	end

	local currentOffer = buyOffers[cache.SCROLL_BUY_OFFERS.lastSelected]

	mainMarket.amountBuyScrollBar:setValue(lastSelectedItem.itemId == 22118 and 25 or 1)
	setMarketAmountScrollRange(mainMarket.amountBuyScrollBar, 1, math.min(count, currentOffer.amount or 0))
	mainMarket.amountBuyScrollBar:setIncrementStep(1)
	mainMarket.totalSellValue:setText(comma_value(currentOffer.price or 0))
	mainMarket.buyAcceptButton:setEnabled(true)

	local steps = getCoinStepValue(lastSelectedItem.itemId)

	mainMarket.amountBuyScrollBar:setStep(steps)

	if lastSelectedItem.itemId == 22118 then
		local startValue = 0
		local coinBalance = g_game.getTransferableTibiaCoins()
		local buyCount = math.floor(coinBalance / 25)

		if buyCount > 0 then
			setMarketAmountScrollRange(mainMarket.amountBuyScrollBar, 25, math.min(currentOffer.amount or 0, buyCount * 25))
			mainMarket.amountBuyScrollBar:setValue(25)
			mainMarket.buyAcceptButton:setEnabled(true)
			mainMarket.amountBuyScrollBar:setStep(25)
			mainMarket.amountBuyScrollBar:setIncrementStep(25)

			startValue = 25
		else
			setMarketAmountScrollRange(mainMarket.amountBuyScrollBar, 0, 0)
			mainMarket.amountBuyScrollBar:setValue(0)
			mainMarket.buyAcceptButton:setEnabled(false)
		end

		updateBuyCount(nil, startValue)
	end

	local buyListScroll = marketWindow:recursiveGetChildById("buyOffersListScroll")

	if cache.SCROLL_BUY_OFFERS.listFit > 11 then
		onBuyListValueChange(buyListScroll, buyListScroll:getValue(), 0)
	end
end

function updateSellCount(widget, value)
	if table.empty(lastSelectedItem) then
		return
	end

	if widget and widget:getIncrementValue() > 1 then
		value = math.cround(value, widget:getIncrementValue())
	end

	if cache.SCROLL_SELL_OFFERS.lastSelected == 0 then
		mainMarket.amountSell:setText(value)
		mainMarket.totalValue:setText(value)

		return
	end

	local steps = getCoinStepValue(lastSelectedItem.itemId)

	mainMarket.amountSellScrollBar:setStep(steps)

	local currentOffer = sellOffers[cache.SCROLL_SELL_OFFERS.lastSelected]

	if currentOffer then
		mainMarket.amountSell:setText(value)
		mainMarket.totalValue:setText(comma_value((currentOffer.price or 0) * value))
	end
end

function updateBuyCount(widget, value)
	if widget and widget:getIncrementValue() > 1 then
		value = math.cround(value, widget:getIncrementValue())
	end

	if cache.SCROLL_BUY_OFFERS.lastSelected == 0 then
		mainMarket.amountBuy:setText(value)
		mainMarket.totalSellValue:setText(convertGold(value))

		return
	end

	local currentOffer = buyOffers[cache.SCROLL_BUY_OFFERS.lastSelected]

	if currentOffer then
		mainMarket.amountBuy:setText(value)
		mainMarket.totalSellValue:setText(convertGold((currentOffer.price or 0) * value))
	end
end

function onAcceptSellOffer()
	if cache.SCROLL_SELL_OFFERS.lastSelected == 0 then
		return
	end

	local currentOffer = sellOffers[cache.SCROLL_SELL_OFFERS.lastSelected]

	if not currentOffer then
		return
	end

	local amount = tonumber(mainMarket.amountSell:getText())

	g_game.acceptMarketOffer(currentOffer.timestamp, currentOffer.counter, amount)
	requestMarketGoldRefresh()
	refreshSelectedMarketBrowse()
end

function onAcceptBuyOffer()
	if cache.SCROLL_BUY_OFFERS.lastSelected == 0 then
		return
	end

	local currentOffer = buyOffers[cache.SCROLL_BUY_OFFERS.lastSelected]

	if not currentOffer then
		return
	end

	local amount = tonumber(mainMarket.amountBuy:getText())

	adjustDepotLockerItemCount(lastSelectedItem.itemId, lastSelectedItem.tier or 0, -amount)
	g_game.acceptMarketOffer(currentOffer.timestamp, currentOffer.counter, amount)
	requestMarketGoldRefresh()
	refreshSelectedItemDepotDisplay()
	refreshSelectedMarketBrowse()
end

function updateCreateCount(widget, value)
	if widget and widget:getIncrementValue() > 1 then
		value = math.cround(value, widget:getIncrementValue())
	end

	mainMarket.createOfferAmount:setText("Amount: " .. value)
	onPiecePriceEdit(mainMarket.piecePriceCreate)
end

function onPiecePriceEdit(widget)
	if table.empty(lastSelectedItem) then
		return
	end

	if #widget:getText() == 0 then
		mainMarket.grossAmount.value = 0

		mainMarket.profitAmount:setText(0)
		mainMarket.feeAmount:setText(0)
		mainMarket.createButton:setEnabled(false)
		mainMarket.amountCreateScrollBar:setIncrementStep(25)
		setMarketAmountScrollRange(mainMarket.amountCreateScrollBar, 0, 0)

		return
	end

	local currentText = widget:getText():gsub("[^%d]", "")

	widget:setText(currentText)

	if #currentText > 12 then
		currentText = currentText:sub(1, -2)

		widget:setText(currentText)
	end

	local isTibiaCoin = lastSelectedItem.itemId == 22118
	local numericValue = tonumber(currentText)

	if not numericValue then
		return true
	end

	if numericValue >= 999999999999 then
		currentText = "999999999999"

		widget:setText(currentText)
	end

	local amount = mainMarket.amountCreateScrollBar:getValue()

	if mainMarket.amountCreateScrollBar:getIncrementValue() > 1 then
		amount = math.cround(amount, mainMarket.amountCreateScrollBar:getIncrementValue())
	end

	local fee = math.ceil(numericValue / 50 * amount)

	if fee < 20 then
		fee = 20
	elseif fee > 1000000 then
		fee = 1000000
	end

	local thing = g_things.getThingType(lastSelectedItem.itemId)
	local stackable = thing:isStackable()
	local maxCount = stackable and 64000 or 2000
	local maxValue = 999999999999

	if not isTibiaCoin and maxValue <= numericValue * amount then
		local newAmount = math.floor(maxValue / numericValue)

		amount = newAmount
		maxCount = newAmount

		mainMarket.amountCreateScrollBar:setValue(amount)
	end

	local steps = getCoinStepValue(lastSelectedItem.itemId)

	mainMarket.amountCreateScrollBar:setIncrementStep(1)

	if isTibiaCoin then
		steps = 25

		mainMarket.amountCreateScrollBar:setIncrementStep(25)
	end

	mainMarket.amountCreateScrollBar:setStep(steps)

	if currentActionType == 0 then
		local grossProfit = numericValue * amount

		mainMarket.grossAmount:setText(convertGold(grossProfit, true))

		mainMarket.grossAmount.value = numericValue

		mainMarket.profitAmount:setText(convertGold(grossProfit + fee, true))
		mainMarket.createButton:setEnabled(true)
		mainMarket.feeAmount:setText(convertGold(fee))

		local balance = getTotalMoney()
		local barCount = 0

		if isTibiaCoin then
			barCount = math.floor(balance / (numericValue * 25))

			if mainMarket.amountCreateScrollBar:getValue() <= 1 then
				mainMarket.amountCreateScrollBar:setValue(25)
				mainMarket.amountCreateScrollBar:setStep(25)
				mainMarket.amountCreateScrollBar:setIncrementStep(25)
			end

			if barCount > 0 then
				setMarketAmountScrollRange(mainMarket.amountCreateScrollBar, 25, barCount * 25)
			else
				setMarketAmountScrollRange(mainMarket.amountCreateScrollBar, 0, 0)
			end
		else
			if numericValue <= getTotalMoney() then
				barCount = math.min(maxCount, getTotalMoney() / numericValue)
			end

			if barCount > 0 then
				setMarketAmountScrollRange(mainMarket.amountCreateScrollBar, 1, barCount)
			else
				setMarketAmountScrollRange(mainMarket.amountCreateScrollBar, 0, 0)
			end
		end
	else
		local itemCount = isTibiaCoin and g_game.getTransferableTibiaCoins() or getDepotItemCount(lastSelectedItem.itemId, lastSelectedItem.tier)

		if itemCount > 0 then
			if isTibiaCoin and itemCount < 25 then
				mainMarket.amountCreateScrollBar:setValue(0)
				mainMarket.amountCreateScrollBar:setStep(25)
				mainMarket.amountCreateScrollBar:setIncrementStep(25)
			else
				setMarketAmountScrollRange(mainMarket.amountCreateScrollBar, isTibiaCoin and 25 or 1, math.min(maxCount, itemCount))
				mainMarket.createButton:setEnabled(true)
			end
		else
			setMarketAmountScrollRange(mainMarket.amountCreateScrollBar, 0, 0)
		end

		local grossProfit = numericValue * amount

		mainMarket.grossAmount:setText(convertGold(grossProfit, true))

		mainMarket.grossAmount.value = numericValue

		mainMarket.profitAmount:setText(convertGold(grossProfit - fee, true))
		mainMarket.feeAmount:setText(convertGold(fee))
	end
end

function changeOfferType(widget, primary)
	if widget:isChecked() then
		return
	end

	if primary then
		widget:setChecked(true)
		mainMarket.createOfferBuy:setChecked(false)

		currentActionType = 1

		mainMarket.grossProfit:setText("Gross Profit:")
		mainMarket.profitLabel:setText("Total Profit:")
	else
		widget:setChecked(true)
		mainMarket.createOfferSell:setChecked(false)

		currentActionType = 0

		mainMarket.grossProfit:setText("Price:")
		mainMarket.profitLabel:setText("Total Price:")
	end

	mainMarket.piecePriceCreate:clearText()
end

function createMarketOffer()
	if table.empty(lastSelectedItem) then
		return
	end

	local n = mainMarket.createOfferAmount:getText()
	local amount = n:gsub("%D", "")
	local price = tonumber(mainMarket.grossAmount.value)

	if currentActionType == 0 and price > getTotalMoney() then
		return
	end

	setMarketAmountScrollRange(mainMarket.amountCreateScrollBar, 0, 0)
	mainMarket.createButton:setEnabled(false)
	mainMarket.amountCreateScrollBar:setValue(0)
	mainMarket.amountCreateScrollBar:setIncrementStep(1)
	mainMarket.grossAmount:setText("0")

	mainMarket.grossAmount.value = 0

	mainMarket.profitAmount:setText("0")
	mainMarket.feeAmount:setText("0")
	mainMarket.piecePriceCreate:clearText()

	if currentActionType == 1 then
		adjustDepotLockerItemCount(lastSelectedItem.itemId, lastSelectedItem.tier or 0, -tonumber(amount))
		refreshSelectedItemDepotDisplay()
	end

	g_game.createMarketOffer(currentActionType, lastSelectedItem.itemId, lastSelectedItem.tier or 0, amount, price, mainMarket.anonymous:isChecked() and 1 or 0)
	requestMarketGoldRefresh()
	refreshSelectedMarketBrowse()
end

function onSearchItem(textField)
	if suppressSearchCallbacks then
		return
	end

	local searchText = normalizeMarketSearchText(textField and textField:getText() or "")

	lastSelectedItem = {}

	if searchText == "" then
		onClearSearch()

		return
	end

	if lastSelectedCategory then
		lastSelectedCategory = nil

		updateCategoryRowColors()
	end

	local itemList = marketWindow:recursiveGetChildById("itemList")

	if not itemList then
		return true
	end

	resetItemListScrollOffset(itemList)

	cache.SCROLL_MARKET_ITEMS.listFit = getMarketItemListFit(itemList)
	cache.SCROLL_MARKET_ITEMS.listMin = 0
	cache.SCROLL_MARKET_ITEMS.listPool = {}
	cache.SCROLL_MARKET_ITEMS.listData = {}

	marketWindow.contentPanel.itemList:destroyChildren()
	onClearMainMarket(true)
	updateCategoryShopButtons(nil)
	resetMarketPreviewPanel()

	function itemList:onChildFocusChange(selected, oldFocus)
		onSelectChildItem(self, selected, oldFocus)
	end

	if sortButtons.classFilter == -1 then
		local prev = suppressFilterCallbacks

		suppressFilterCallbacks = true

		marketWindow.contentPanel.classFilter:clearOptions()
		marketWindow.contentPanel.classFilter:addOption("All", nil, true)
		marketWindow.contentPanel.classFilter:addOption("None", nil, true)

		for i = 1, 4 do
			marketWindow.contentPanel.classFilter:addOption("Class " .. i, nil, true)
		end

		suppressFilterCallbacks = prev
	end

	if sortButtons.tierFilter == 0 then
		local prev = suppressFilterCallbacks

		suppressFilterCallbacks = true

		marketWindow.contentPanel.tierFilter:clearOptions()

		for i = 0, 10 do
			marketWindow.contentPanel.tierFilter:addOption("Tier " .. i, nil, true)
		end

		suppressFilterCallbacks = prev
	end

	local tier = sortButtons.tierFilter or 0

	for _, data in ipairs(allMarketItems) do
		if not checkSortMarketOptions(data) then
			-- block empty
		else
			local id = data.thingType:getId()
			local hasCount = 1

			if showLockerOnly then
				hasCount = getDepotItemCount(id, tier)

				if hasCount == 0 and tier > 0 then
					hasCount = getDepotItemCount(id, 0)
				end
			end

			if marketItemNameMatchesSearch(data.marketData.name, searchText) and (not showLockerOnly or hasCount > 0) then
				table.insert(cache.SCROLL_MARKET_ITEMS.listData, data)
			end
		end
	end

	table.sort(cache.SCROLL_MARKET_ITEMS.listData, compareMarketItemsByNameCaseInsensitive)

	for i, itemInfo in pairs(cache.SCROLL_MARKET_ITEMS.listData) do
		if #cache.SCROLL_MARKET_ITEMS.listPool >= cache.SCROLL_MARKET_ITEMS.listFit then
			break
		end

		local id = itemInfo.thingType:getId()
		local count = getDepotItemCount(id, tier)

		if showLockerOnly and count == 0 and tier > 0 then
			count = getDepotItemCount(id, 0)
		end

		if not checkSortMarketOptions(itemInfo) or count == 0 and showLockerOnly then
			-- block empty
		else
			local widget = g_ui.createWidget("MarketItemList", itemList)

			widget.item:setItemId(id)
			widget.name:setText(itemInfo.marketData.name)

			if widget.name:isOfflimit(20) then
				widget.name:setText(short_text(itemInfo.marketData.name, 20))
				widget.name:setTooltip(itemInfo.marketData.name)
			end

			widget:setBackgroundColor("#404040")
			widget.item:getItem():setCount(count)
			widget.item:setActionId(i)
			widget.item:setTooltip(tr("%s%s%s%s", comma_value(count), "x", count > 65000 and "+ " or " ", itemInfo.marketData.name))
			setAmount(widget.amount or widget:getChildById("amount"), count)
			widget.item:getItem():setTier(tier)
			applyMarketItemTierBadge(widget, tier)

			if not widget.name:isTextWrap() then
				widget.name:setMarginTop(1)
			end

			applyMarketItemRarity(widget.rarity, id)
			applyMarketItemNameColor(widget.name, count)
			applyMarketItemSlotOpacity(widget, count)
			table.insert(cache.SCROLL_MARKET_ITEMS.listPool, widget)
		end
	end

	cache.SCROLL_MARKET_ITEMS.listMax = #cache.SCROLL_MARKET_ITEMS.listData

	setupItemListScrollbar(itemList)
end

local function getMarketItemMaxTier(thingType)
	if not thingType then
		return 0
	end

	local classification = thingType:getClassification()

	if classification == 0 then
		return 0
	end

	if classification == 4 then
		return 10
	end

	return classification
end

function onShowRedirect(item)
	lastSelectedItem = {}

	if lastSelectedCategory then
		lastSelectedCategory = nil

		updateCategoryRowColors()
	end

	local itemList = marketWindow:recursiveGetChildById("itemList")

	if not itemList then
		return true
	end

	resetItemListScrollOffset(itemList)

	cache.SCROLL_MARKET_ITEMS.listFit = getMarketItemListFit(itemList)
	cache.SCROLL_MARKET_ITEMS.listMin = 0
	cache.SCROLL_MARKET_ITEMS.listPool = {}
	cache.SCROLL_MARKET_ITEMS.listData = {}

	marketWindow.contentPanel.itemList:destroyChildren()
	onClearMainMarket(true)
	updateCategoryShopButtons(nil)
	resetMarketPreviewPanel()

	function itemList:onChildFocusChange(selected, oldFocus)
		onSelectChildItem(self, selected, oldFocus)
	end

	if sortButtons.classFilter == -1 then
		local prev = suppressFilterCallbacks

		suppressFilterCallbacks = true

		marketWindow.contentPanel.classFilter:clearOptions()
		marketWindow.contentPanel.classFilter:addOption("All", nil, true)
		marketWindow.contentPanel.classFilter:addOption("None", nil, true)

		for i = 1, 4 do
			marketWindow.contentPanel.classFilter:addOption("Class " .. i, nil, true)
		end

		suppressFilterCallbacks = prev
	end

	if sortButtons.tierFilter == 0 then
		local prev = suppressFilterCallbacks

		suppressFilterCallbacks = true

		marketWindow.contentPanel.tierFilter:clearOptions()

		suppressFilterCallbacks = prev
	end

	for _, data in ipairs(allMarketItems) do
		if item:getId() == data.thingType:getId() then
			local tierCount = getMarketItemMaxTier(data.thingType)

			for i = 0, tierCount do
				local tableCopy = table.copy(data)

				tableCopy.tier = i

				table.insert(cache.SCROLL_MARKET_ITEMS.listData, tableCopy)
			end

			break
		end
	end

	for i, itemInfo in pairs(cache.SCROLL_MARKET_ITEMS.listData) do
		if #cache.SCROLL_MARKET_ITEMS.listPool >= cache.SCROLL_MARKET_ITEMS.listFit then
			break
		end

		local id = itemInfo.thingType:getId()
		local tier = itemInfo.tier or 0
		local count = getDepotItemCount(id, tier)

		if showLockerOnly and count == 0 and tier > 0 then
			count = getDepotItemCount(id, 0)
		end

		if not checkSortMarketOptions(itemInfo) or count == 0 and showLockerOnly then
			-- block empty
		else
			local widget = g_ui.createWidget("MarketItemList", itemList)

			widget.item:setItemId(id)
			widget.name:setText(itemInfo.marketData.name)

			if widget.name:isOfflimit(20) then
				widget.name:setText(short_text(itemInfo.marketData.name, 20))
				widget.name:setTooltip(itemInfo.marketData.name)
			end

			widget:setBackgroundColor("#404040")
			widget.item:getItem():setCount(count)
			widget.item:setActionId(i)
			widget.item:setTooltip(tr("%s%s%s%s", comma_value(count), "x", count > 65000 and "+ " or " ", itemInfo.marketData.name))
			setAmount(widget.amount or widget:getChildById("amount"), count)
			widget.item:getItem():setTier(tier)
			applyMarketItemTierBadge(widget, tier)

			if not widget.name:isTextWrap() then
				widget.name:setMarginTop(1)
			end

			applyMarketItemRarity(widget.rarity, id)
			applyMarketItemNameColor(widget.name, count)
			applyMarketItemSlotOpacity(widget, count)
			table.insert(cache.SCROLL_MARKET_ITEMS.listPool, widget)
		end
	end

	cache.SCROLL_MARKET_ITEMS.listMax = #cache.SCROLL_MARKET_ITEMS.listData

	setupItemListScrollbar(itemList)
end

function onClearHandFilter()
	marketWindow.contentPanel.oneButton:setEnabled(false)
	marketWindow.contentPanel.oneButton:setChecked(false)
	marketWindow.contentPanel.twoButton:setEnabled(false)
	marketWindow.contentPanel.twoButton:setChecked(false)

	sortButtons.oneButton = false
	sortButtons.twoButton = false
end

function onClearSearch(clearHands)
	local searchEdit = marketWindow and marketWindow.contentPanel and marketWindow.contentPanel.searchText

	if searchEdit then
		local prev = suppressSearchCallbacks

		suppressSearchCallbacks = true

		searchEdit:clearText(true)

		suppressSearchCallbacks = prev
	end

	onClearMainMarket(true)

	if clearHands then
		onClearHandFilter()
	end

	marketWindow.contentPanel.itemList:updateScrollBars()
end

local function normalizeVocationSet(v)
	if v == nil then
		return nil
	end

	local set = {}

	local function add(val)
		local n = tonumber(val)

		if n and n > 0 then
			set[n] = true
		end
	end

	local tv = type(v)

	if tv == "number" then
		add(v)
	elseif tv == "string" then
		for token in v:gmatch("[^,;%s]+") do
			add(token)
		end
	elseif tv == "table" then
		for k, val in pairs(v) do
			if type(k) == "number" and type(val) ~= "boolean" then
				add(val)
			else
				add(k)
			end
		end
	end

	if next(set) == nil then
		return nil
	end

	return set
end

function checkSortMarketOptions(itemData)
	local player = g_game.getLocalPlayer()

	if not player then
		return false
	end

	local playerLevel = player:getLevel()
	local playerVocation = translateWheelVocation(player:getVocation())
	local md = itemData and itemData.marketData or {}
	local tt = itemData and itemData.thingType

	if sortButtons.levelButton and md.requiredLevel and playerLevel < md.requiredLevel then
		return false
	end

	if sortButtons.vocButton then
		local vocSet = normalizeVocationSet(md.restrictVocation)

		if vocSet and not vocSet[playerVocation] then
			return false
		end
	end

	if sortButtons.oneButton and (not tt or tt:getClothSlot() ~= 6) then
		return false
	end

	if sortButtons.twoButton and (not tt or tt:getClothSlot() ~= 0) then
		return false
	end

	if sortButtons.classFilter ~= -1 and (not tt or tt:getClassification() ~= sortButtons.classFilter) then
		return false
	end

	local selectedTier = sortButtons.tierFilter or 0

	if selectedTier > 0 and selectedTier > getMarketItemMaxTier(tt) then
		return false
	end

	return true
end

function onSortMarketFields(widget, checked)
	if suppressFilterCallbacks then
		return
	end

	if table.contains({
		"oneButton",
		"twoButton"
	}, widget:getId()) then
		widget:setChecked(not checked)

		sortButtons[widget:getId()] = not checked

		if widget:getId() == "oneButton" then
			sortButtons.twoButton = false

			marketWindow.contentPanel.twoButton:setChecked(false)
		elseif widget:getId() == "twoButton" then
			marketWindow.contentPanel.oneButton:setChecked(false)

			sortButtons.oneButton = false
		end
	elseif table.contains({
		"classFilter",
		"tierFilter"
	}, widget:getId()) then
		if checked > 1 and widget:getId() == "classFilter" then
			sortButtons.classFilter = checked - 2
		elseif widget:getId() == "tierFilter" then
			sortButtons.tierFilter = checked - 1
		end
	elseif table.contains({
		"levelButton",
		"vocButton"
	}, widget:getId()) then
		widget:setChecked(not checked)

		sortButtons[widget:getId()] = not checked
	end

	if not lastSelectedCategory then
		if #marketWindow.contentPanel.searchText:getText() > 0 then
			onSearchItem(marketWindow.contentPanel.searchText)
		end

		return true
	end

	lastSelectedItem = {}

	onClearMainMarket(true)
	onSelectChildCategory(nil, lastSelectedCategory, true)
end

function onMarketDetail(itemId, tier, details, purchase, sale)
	marketWindow.contentPanel.detailsMarket.detailsList:destroyChildren()

	local sortedKeys = {}

	for k in pairs(details) do
		table.insert(sortedKeys, k)
	end

	table.sort(sortedKeys)

	for _, i in ipairs(sortedKeys) do
		local entry = details[i]
		local desc = entry and entry.desc

		if desc and #desc > 0 then
			local label = MarketDetailNames[i] or "Unknown[" .. tostring(i) .. "]: "
			local widget = g_ui.createWidget("DatailsLabel", marketWindow.contentPanel.detailsMarket.detailsList)

			widget:setText(label .. desc)
		end
	end

	marketWindow.contentPanel.detailsMarket.statisticsList:destroyChildren()

	local purchaseWidget = g_ui.createWidget("StatisticWidget", marketWindow.contentPanel.detailsMarket.statisticsList)

	purchaseWidget.header:setText("Buy Offers:")

	if #purchase > 0 then
		local transactionsText = purchaseWidget.transactions:getText():gsub("0", purchase[1].numTransactions)

		purchaseWidget.transactions:setText(transactionsText)

		local highestText = purchaseWidget.highestPrice:getText():gsub("0", comma_value(purchase[1].highestPrice))

		purchaseWidget.highestPrice:setText(highestText)

		local avgPrice = math.floor(purchase[1].totalPrice / math.max(1, purchase[1].numTransactions))
		local avgText = purchaseWidget.avgPrice:getText():gsub("0", comma_value(avgPrice))

		purchaseWidget.avgPrice:setText(avgText)

		local lowText = purchaseWidget.lowPrice:getText():gsub("0", comma_value(purchase[1].lowestPrice))

		purchaseWidget.lowPrice:setText(lowText)
	end

	local saleWidget = g_ui.createWidget("StatisticWidget", marketWindow.contentPanel.detailsMarket.statisticsList)

	saleWidget.header:setText("Sell Offers:")

	if #sale > 0 then
		local transactionsText = saleWidget.transactions:getText():gsub("0", sale[1].numTransactions)

		saleWidget.transactions:setText(transactionsText)

		local highestText = saleWidget.highestPrice:getText():gsub("0", comma_value(sale[1].highestPrice))

		saleWidget.highestPrice:setText(highestText)

		local avgPrice = math.floor(sale[1].totalPrice / math.max(1, sale[1].numTransactions))
		local avgText = saleWidget.avgPrice:getText():gsub("0", comma_value(avgPrice))

		saleWidget.avgPrice:setText(avgText)

		local lowText = saleWidget.lowPrice:getText():gsub("0", comma_value(sale[1].lowestPrice))

		saleWidget.lowPrice:setText(lowText)
	end
end

function getItemNameById(itemId)
	for c = MarketCategory.First, MarketCategory.WeaponsAll do
		local marketItem = marketItems[c]

		if marketItem then
			for _, data in pairs(marketItem) do
				if data.thingType:getId() == itemId then
					return data.marketData.name
				end
			end
		end
	end

	return ""
end

function onRedirect(item)
	g_game.sendMarketAction(3, item:getId(), 0)
	scheduleEvent(function()
		onShowRedirect(item)
	end, 100)
end

function focusPrevItemWidget(list)
	if cache.SCROLL_MARKET_ITEMS.scrollDelay >= g_clock.millis() then
		return
	end

	local c = list:getFocusedChild()

	if not c then
		return
	end

	local cIndex = list:getChildIndex(c)
	local scrollbar = marketWindow:recursiveGetChildById("itemListScroll")

	if scrollbar:getMaximum() > 0 and cIndex == 1 and scrollbar:getValue() == scrollbar:getMinimum() then
		return
	end

	if cIndex > 1 then
		list:focusPreviousChild(KeyboardFocusReason)
	else
		scrollbar:setValue(scrollbar:getValue() - 1)

		if cIndex == 1 then
			local a = list:getFocusedChild()
			local nextChild = list:getChildByIndex(cIndex + 1)

			if nextChild then
				list:focusChild(nextChild)
			end

			list:focusChild(a)
		end
	end

	resetItemListScrollOffset(list)

	cache.SCROLL_MARKET_ITEMS.scrollDelay = g_clock.millis() + 30
end

function focusNextItemWidget(list)
	if cache.SCROLL_MARKET_ITEMS.scrollDelay >= g_clock.millis() then
		return
	end

	local c = list:getFocusedChild()
	local cIndex = list:getChildIndex(c)
	local cCount = list:getChildCount()
	local scrollbar = marketWindow:recursiveGetChildById("itemListScroll")

	if scrollbar:getMaximum() > 0 and cIndex == cCount and scrollbar:getValue() == scrollbar:getMaximum() then
		return
	end

	if cIndex < cCount - 1 then
		list:focusNextChild(KeyboardFocusReason)
	else
		scrollbar:setValue(scrollbar:getValue() + 1)

		if cIndex == cCount - 1 then
			list:focusNextChild(KeyboardFocusReason)
		elseif cIndex == cCount then
			local prevChild = list:getChildByIndex(cIndex - 1)

			if prevChild then
				list:focusChild(prevChild)
			end

			list:focusChild(c)
		end
	end

	resetItemListScrollOffset(list)

	cache.SCROLL_MARKET_ITEMS.scrollDelay = g_clock.millis() + 30
end

function focusPrevSellLabel(list)
	local c = list:getFocusedChild()

	if not c then
		return
	end

	local cIndex = list:getChildIndex(c)
	local scrollbar = list:getParent():recursiveGetChildById("sellOffersListScroll")

	if cache.SCROLL_SELL_OFFERS.lastSelected - 1 > 0 then
		cache.SCROLL_SELL_OFFERS.lastSelected = cache.SCROLL_SELL_OFFERS.lastSelected - 1
	end

	if cIndex > 1 then
		list:focusPreviousChild(KeyboardFocusReason)
	else
		scrollbar:setValue(scrollbar:getValue() - 1)
		list:focusChild(c)

		if cIndex == 1 then
			list:focusPreviousChild(KeyboardFocusReason)
		end
	end

	scrollbar:setValue(scrollbar:getValue())
end

function focusNextSellLabel(list)
	local scrollbar = list:getParent():recursiveGetChildById("sellOffersListScroll")
	local c = list:getFocusedChild()
	local cIndex = list:getChildIndex(c)
	local cCount = list:getChildCount()

	if cIndex < cCount then
		list:focusNextChild(KeyboardFocusReason)
	else
		scrollbar:setValue(scrollbar:getValue() + 1)
		list:focusChild(c)

		if cIndex == cCount then
			list:focusNextChild(KeyboardFocusReason)
		end
	end

	if cache.SCROLL_SELL_OFFERS.lastSelected + 1 < #cache.SCROLL_SELL_OFFERS.listData then
		cache.SCROLL_SELL_OFFERS.lastSelected = cache.SCROLL_SELL_OFFERS.lastSelected + 1
	end
end

function focusPrevBuyLabel(list)
	local c = list:getFocusedChild()

	if not c then
		return
	end

	local cIndex = list:getChildIndex(c)
	local scrollbar = list:getParent():recursiveGetChildById("buyOffersListScroll")

	if cache.SCROLL_BUY_OFFERS.lastSelected - 1 > 0 then
		cache.SCROLL_BUY_OFFERS.lastSelected = cache.SCROLL_BUY_OFFERS.lastSelected - 1
	end

	if cIndex > 1 then
		list:focusPreviousChild(KeyboardFocusReason)
	else
		scrollbar:setValue(scrollbar:getValue() - 1)
		list:focusChild(c)

		if cIndex == 1 then
			list:focusPreviousChild(KeyboardFocusReason)
		end
	end
end

function focusNextBuyLabel(list)
	local c = list:getFocusedChild()
	local cIndex = list:getChildIndex(c)
	local cCount = list:getChildCount()
	local scrollbar = list:getParent():recursiveGetChildById("buyOffersListScroll")

	if cIndex < cCount then
		list:focusNextChild(KeyboardFocusReason)
	else
		scrollbar:setValue(scrollbar:getValue() + 1)
		list:focusChild(c)

		if cIndex == cCount then
			list:focusNextChild(KeyboardFocusReason)
		end
	end

	if cache.SCROLL_BUY_OFFERS.lastSelected + 1 < #cache.SCROLL_BUY_OFFERS.listData then
		cache.SCROLL_BUY_OFFERS.lastSelected = cache.SCROLL_BUY_OFFERS.lastSelected + 1
	end
end
