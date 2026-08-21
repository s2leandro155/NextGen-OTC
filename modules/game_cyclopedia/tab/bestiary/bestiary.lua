-- chunkname: @/game_cyclopedia/tab/bestiary/bestiary.lua

local UI
local STAGES = {
	CREATURE = 3,
	CATEGORY = 1,
	SEARCH = 4,
	CREATURES = 2
}
local BESTIARY_PAGE_SIZE = 15

Cyclopedia.Bestiary = Cyclopedia.Bestiary or {}
Cyclopedia.Bestiary.Stage = Cyclopedia.Bestiary.Stage or STAGES.CATEGORY
Cyclopedia.Bestiary.ReturnTarget = Cyclopedia.Bestiary.ReturnTarget or {}

local function clearTabBackRestore()
	Cyclopedia.Bestiary.TabBackRestore = false
end

local storedRaceIDs = {}

Cyclopedia.storedTrackerData = Cyclopedia.storedTrackerData or nil
Cyclopedia.storedBosstiaryTrackerData = Cyclopedia.storedBosstiaryTrackerData or nil

local animusMasteryPoints = 0
local BESTIARY_CHARM_SLOT = {
	minor = 2,
	major = 1
}
local bestiaryCharmSelectorUpdating = false
local bestiaryAssignCharmConfirmWindow

local function getBestiaryCreatureInfo()
	if not UI or not UI.ListBase or not UI.ListBase.CreatureInfo then
		return nil
	end

	return UI.ListBase.CreatureInfo
end

local function applyEchoRaidCharmIndicator(widget, ecoraid, charmPoints)
	if not widget then
		return
	end

	local indicator = widget.EchoRaidCharmPoints or widget.LeftBase and widget.LeftBase.EchoRaidCharmPoints

	if not indicator then
		return
	end

	ecoraid = ecoraid or 0
	charmPoints = charmPoints or 0

	if ecoraid == 1 or charmPoints > 0 then
		indicator:setVisible(true)
		indicator:setTooltip(string.format("You received %d Charm Points for defeating an Echo Warden of this creature type for the first time.", charmPoints))
		indicator:raise()
	else
		indicator:removeTooltip()
		indicator:setVisible(false)
	end
end

local function getBestiaryCharmSlotWidget(category)
	local info = getBestiaryCreatureInfo()

	if not info then
		return nil
	end

	if category == BESTIARY_CHARM_SLOT.major then
		return info.MajorCharm
	end

	if category == BESTIARY_CHARM_SLOT.minor then
		return info.MinorCharm
	end

	return nil
end

local function getBestiaryCharmSlotCategory(widget)
	local info = getBestiaryCreatureInfo()

	if not info or not widget then
		return nil
	end

	if widget == info.MajorCharm then
		return BESTIARY_CHARM_SLOT.major
	end

	if widget == info.MinorCharm then
		return BESTIARY_CHARM_SLOT.minor
	end

	return nil
end

local function findCharmOnCreature(raceId, category)
	raceId = tonumber(raceId) or raceId

	for _, charmData in ipairs(Cyclopedia.Charms.List or {}) do
		local charmRaceId = tonumber(charmData.raceId) or charmData.raceId

		if charmData.asignedStatus and charmRaceId == raceId and charmData.category == category then
			return charmData
		end
	end

	return nil
end

local function canAffordBestiaryGoldCost(player, cost)
	if not player then
		return false
	end

	if player.getTotalMoney then
		return cost <= (player:getTotalMoney() or 0)
	end

	local bank = player:getResourceBalance(ResourceBank) or 0
	local inventory = player:getResourceBalance(ResourceInventary) or 0

	return cost <= bank + inventory
end

local function setBestiaryCharmSlotDisplay(slotWidget, charmData)
	if not slotWidget or slotWidget:isDestroyed() then
		return
	end

	local icon = slotWidget.majorCharmIcon or slotWidget.minorCharmIcon
	local gradeBorder = slotWidget.majorCharmGradeBorder or slotWidget.minorCharmGradeBorder

	if not icon or not gradeBorder then
		return
	end

	if charmData and Cyclopedia.isCharmUnlocked(charmData) then
		icon:setImageSource("/game_cyclopedia/images/charms/monster-bonus-effects")
		icon:setImageClip(charmData.id * 32 .. " 0 32 32")
		icon:setVisible(true)

		local tier = charmData.tier or 0

		if tier > 0 then
			gradeBorder:setImageSource("/game_cyclopedia/images/charms/border/backdrop_charmgrade" .. tier)
			gradeBorder:setVisible(true)
		else
			gradeBorder:setVisible(false)
		end
	else
		icon:setVisible(false)
		gradeBorder:setVisible(false)
	end
end

local function updateBestiaryCharmSelectionBorders(selectedCategory)
	local info = getBestiaryCreatureInfo()

	if not info then
		return
	end

	local raceId = Cyclopedia.Bestiary.SelectedRaceId
	local slots = {
		{
			widget = info.MajorCharm,
			category = BESTIARY_CHARM_SLOT.major
		},
		{
			widget = info.MinorCharm,
			category = BESTIARY_CHARM_SLOT.minor
		}
	}

	for _, entry in ipairs(slots) do
		local slot = entry.widget
		local category = entry.category

		if slot then
			local selectionBorder = slot.majorCharmSelectionBorder or slot.minorCharmSelectionBorder
			local gradeBorder = slot.majorCharmGradeBorder or slot.minorCharmGradeBorder
			local isSelected = category == selectedCategory
			local assigned = raceId and findCharmOnCreature(raceId, category)

			if selectionBorder then
				if isSelected and assigned then
					selectionBorder:setImageSource("/game_cyclopedia/images/charms/border/border_charmgrades")
					selectionBorder:setBorderWidth(0)
					selectionBorder:setVisible(true)
				else
					selectionBorder:setImageSource("")
					selectionBorder:setBorderWidth(1)
					selectionBorder:setBorderColor("#ffffff")
					selectionBorder:setVisible(isSelected)
				end
			end

			if gradeBorder then
				if assigned and (assigned.tier or 0) > 0 then
					gradeBorder:setImageSource("/game_cyclopedia/images/charms/border/backdrop_charmgrade" .. assigned.tier)
					gradeBorder:setVisible(true)
				elseif not assigned then
					gradeBorder:setVisible(false)
				end
			end
		end
	end
end

local function updateBestiaryAssignButtonState()
	local info = getBestiaryCreatureInfo()

	if not info then
		return
	end

	local selector = info.CharmSelector
	local assignButton = info.SelectButton
	local clearButton = info.ClearButton
	local clearPriceBase = info.ClearPriceBase
	local clearPriceRow = clearPriceBase and clearPriceBase.priceRow
	local clearPriceValue = clearPriceRow and clearPriceRow.Value

	if not selector or not assignButton then
		return
	end

	local raceId = Cyclopedia.Bestiary.SelectedRaceId
	local selectedCategory = Cyclopedia.Bestiary.SelectedCharmCategory

	if raceId and selectedCategory then
		local assignedCharm = findCharmOnCreature(raceId, selectedCategory)

		if assignedCharm then
			assignButton:setEnabled(false)
			assignButton:setVisible(false)

			if clearButton then
				clearButton:setVisible(true)
				clearButton:setEnabled(true)
			end

			if clearPriceBase then
				clearPriceBase:setVisible(true)
			end

			if clearPriceValue then
				local removeCost = assignedCharm.removeRuneCost or 0

				clearPriceValue:setText(comma_value(removeCost))

				local player = g_game.getLocalPlayer()
				local canAfford = canAffordBestiaryGoldCost(player, removeCost)

				clearPriceValue:setColor(canAfford and "#C0C0C0" or "#D33C3C")
			end

			return
		end

		if not Cyclopedia.isCreatureCharmAssignable(raceId, selectedCategory) then
			assignButton:setEnabled(false)
			assignButton:setVisible(true)

			if clearButton then
				clearButton:setEnabled(false)
				clearButton:setVisible(false)
			end

			if clearPriceBase then
				clearPriceBase:setVisible(false)
			end

			return
		end
	end

	local option = selector:getCurrentOption()
	local canAssignCharm = selector:isEnabled() and option and option.data ~= nil

	assignButton:setEnabled(canAssignCharm)
	assignButton:setVisible(true)

	if clearButton then
		clearButton:setEnabled(false)
		clearButton:setVisible(false)
	end

	if clearPriceBase then
		clearPriceBase:setVisible(false)
	end
end

local function populateBestiaryCharmSelector(category, raceId)
	local info = getBestiaryCreatureInfo()

	if not info or not info.CharmSelector then
		return
	end

	local selector = info.CharmSelector

	bestiaryCharmSelectorUpdating = true

	selector:clearOptions()
	selector:setEnabled(false)
	selector:setColor("#C0C0C0")

	local assigned = findCharmOnCreature(raceId, category)

	if assigned and assigned.name then
		selector:addOption(assigned.name, assigned)
		selector:setCurrentOption(assigned.name)
		selector:setEnabled(false)
		selector:setColor("#707070")

		bestiaryCharmSelectorUpdating = false

		return
	end

	if not raceId or not Cyclopedia.isCreatureCharmAssignable(raceId, category) then
		bestiaryCharmSelectorUpdating = false

		return
	end

	local hasOption = false

	for _, charmData in ipairs(Cyclopedia.Charms.List or {}) do
		if charmData.category == category and Cyclopedia.isCharmUnlocked(charmData) and (not charmData.asignedStatus or charmData.raceId == raceId) then
			selector:addOption(charmData.name, charmData)

			hasOption = true
		end
	end

	if hasOption then
		selector:setEnabled(true)
		selector:setColor("#C0C0C0")
	end

	bestiaryCharmSelectorUpdating = false
end

local function updateBestiaryCharmControls()
	local info = getBestiaryCreatureInfo()

	if not info then
		return
	end

	local raceId = Cyclopedia.Bestiary.SelectedRaceId

	if raceId then
		setBestiaryCharmSlotDisplay(info.MajorCharm, findCharmOnCreature(raceId, BESTIARY_CHARM_SLOT.major))
		setBestiaryCharmSlotDisplay(info.MinorCharm, findCharmOnCreature(raceId, BESTIARY_CHARM_SLOT.minor))
	end

	local selectedCategory = Cyclopedia.Bestiary.SelectedCharmCategory

	if not selectedCategory then
		updateBestiaryCharmSelectionBorders(nil)

		if info.CharmSelector then
			bestiaryCharmSelectorUpdating = true

			info.CharmSelector:clearOptions()
			info.CharmSelector:setEnabled(false)
			info.CharmSelector:setColor("#C0C0C0")

			bestiaryCharmSelectorUpdating = false
		end

		if info.SelectButton then
			info.SelectButton:setEnabled(false)
			info.SelectButton:setVisible(true)
		end

		if info.ClearButton then
			info.ClearButton:setEnabled(false)
			info.ClearButton:setVisible(false)
		end

		if info.ClearPriceBase then
			info.ClearPriceBase:setVisible(false)
		end

		return
	end

	updateBestiaryCharmSelectionBorders(selectedCategory)
	populateBestiaryCharmSelector(selectedCategory, raceId)
	updateBestiaryAssignButtonState()

	local player = g_game.getLocalPlayer()

	if info.BalanceBase and info.BalanceBase.GoldBalance and player then
		local totalGold = 0

		if player.getTotalMoney then
			totalGold = player:getTotalMoney() or 0
		else
			totalGold = (player:getResourceBalance(ResourceBank) or 0) + (player:getResourceBalance(ResourceInventary) or 0)
		end

		info.BalanceBase.GoldBalance:setText(comma_value(totalGold))
	end
end

function Cyclopedia.refreshBestiaryCharmUI()
	local info = getBestiaryCreatureInfo()

	if not info then
		return
	end

	local raceId = Cyclopedia.Bestiary.SelectedRaceId

	if not raceId then
		return
	end

	-- The creature detail used to start with neither slot selected, leaving the
	-- selector empty and the Assign Charm button disabled. Select the most
	-- useful slot automatically: an assigned slot first, then an assignable one.
	if not Cyclopedia.Bestiary.SelectedCharmCategory then
		if findCharmOnCreature(raceId, BESTIARY_CHARM_SLOT.major) then
			Cyclopedia.Bestiary.SelectedCharmCategory = BESTIARY_CHARM_SLOT.major
		elseif findCharmOnCreature(raceId, BESTIARY_CHARM_SLOT.minor) then
			Cyclopedia.Bestiary.SelectedCharmCategory = BESTIARY_CHARM_SLOT.minor
		elseif Cyclopedia.isCreatureCharmAssignable(raceId, BESTIARY_CHARM_SLOT.major) then
			Cyclopedia.Bestiary.SelectedCharmCategory = BESTIARY_CHARM_SLOT.major
		elseif Cyclopedia.isCreatureCharmAssignable(raceId, BESTIARY_CHARM_SLOT.minor) then
			Cyclopedia.Bestiary.SelectedCharmCategory = BESTIARY_CHARM_SLOT.minor
		end
	end

	setBestiaryCharmSlotDisplay(info.MajorCharm, findCharmOnCreature(raceId, BESTIARY_CHARM_SLOT.major))
	setBestiaryCharmSlotDisplay(info.MinorCharm, findCharmOnCreature(raceId, BESTIARY_CHARM_SLOT.minor))
	updateBestiaryCharmControls()
end

function Cyclopedia.onBestiaryCharmSlotClick(slotWidget)
	local category = type(slotWidget) == "number" and slotWidget or getBestiaryCharmSlotCategory(slotWidget)
	local raceId = Cyclopedia.Bestiary.SelectedRaceId

	if not category or not raceId then
		return
	end

	if Cyclopedia.Bestiary.SelectedCharmCategory == category then
		Cyclopedia.Bestiary.SelectedCharmCategory = nil
	else
		Cyclopedia.Bestiary.SelectedCharmCategory = category
	end

	updateBestiaryCharmControls()
end

function Cyclopedia.onBestiaryMajorCharmSlotClick()
	Cyclopedia.onBestiaryCharmSlotClick(BESTIARY_CHARM_SLOT.major)
end

function Cyclopedia.onBestiaryMinorCharmSlotClick()
	Cyclopedia.onBestiaryCharmSlotClick(BESTIARY_CHARM_SLOT.minor)
end

function Cyclopedia.onBestiaryAssignCharmClick()
	local info = getBestiaryCreatureInfo()
	local raceId = Cyclopedia.Bestiary.SelectedRaceId
	local category = Cyclopedia.Bestiary.SelectedCharmCategory

	if not info or not raceId or not category or not Cyclopedia.isCreatureCharmAssignable(raceId, category) then
		return
	end

	local option = info.CharmSelector:getCurrentOption()

	if not option or not option.data then
		return
	end

	if bestiaryAssignCharmConfirmWindow then
		bestiaryAssignCharmConfirmWindow:destroy()

		bestiaryAssignCharmConfirmWindow = nil
	end

	local charmData = option.data
	local charmName = charmData.name or ""

	local function closeConfirmWindow()
		if bestiaryAssignCharmConfirmWindow then
			bestiaryAssignCharmConfirmWindow:destroy()

			bestiaryAssignCharmConfirmWindow = nil
		end
	end

	local function yesCallback()
		if Cyclopedia.sendCharmAction and Cyclopedia.CHARM_ACTION then
			Cyclopedia.sendCharmAction(Cyclopedia.CHARM_ACTION.SELECT, charmData, raceId)
		end

		closeConfirmWindow()

		if show then
			Cyclopedia._pendingBestiaryRaceId = raceId

			show("bestiary")
		end
	end

	local function noCallback()
		closeConfirmWindow()

		if show then
			Cyclopedia._pendingBestiaryRaceId = raceId

			show("bestiary")
		end
	end

	if hide then
		hide()
	end

	bestiaryAssignCharmConfirmWindow = displayGeneralBox(tr("Confirm Selected Charm"), tr("Do you want to use the Charm %s for this creature?", charmName), {
		{
			text = tr("No"),
			callback = noCallback
		},
		{
			text = tr("Yes"),
			callback = yesCallback
		},
		anchor = AnchorHorizontalCenter
	}, yesCallback, noCallback)
end

function Cyclopedia.onBestiaryClearCharmClick()
	local info = getBestiaryCreatureInfo()
	local raceId = Cyclopedia.Bestiary.SelectedRaceId
	local category = Cyclopedia.Bestiary.SelectedCharmCategory

	if not info or not raceId or not category then
		return
	end

	local assignedCharm = findCharmOnCreature(raceId, category)

	if not assignedCharm then
		return
	end

	if bestiaryAssignCharmConfirmWindow then
		bestiaryAssignCharmConfirmWindow:destroy()

		bestiaryAssignCharmConfirmWindow = nil
	end

	local charmName = assignedCharm.name or ""
	local removeCost = assignedCharm.removeRuneCost or 0

	local function closeConfirmWindow()
		if bestiaryAssignCharmConfirmWindow then
			bestiaryAssignCharmConfirmWindow:destroy()

			bestiaryAssignCharmConfirmWindow = nil
		end
	end

	local function yesCallback()
		if Cyclopedia.sendCharmAction and Cyclopedia.CHARM_ACTION then
			Cyclopedia.sendCharmAction(Cyclopedia.CHARM_ACTION.CLEAR, assignedCharm)
		end

		closeConfirmWindow()

		if show then
			Cyclopedia._pendingBestiaryRaceId = raceId
			Cyclopedia._pendingBestiaryCharmCategory = category

			show("bestiary")
		end
	end

	local function noCallback()
		closeConfirmWindow()

		if show then
			Cyclopedia._pendingBestiaryRaceId = raceId
			Cyclopedia._pendingBestiaryCharmCategory = category

			show("bestiary")
		end
	end

	if hide then
		hide()
	end

	bestiaryAssignCharmConfirmWindow = displayGeneralBox(tr("Confirm Charm Removal"), tr("Do you want to remove the Charm %s from this creature? This will coast you %s gold pieces.", charmName, comma_value(removeCost)), {
		{
			text = tr("No"),
			callback = noCallback
		},
		{
			text = tr("Yes"),
			callback = yesCallback
		},
		anchor = AnchorHorizontalCenter
	}, yesCallback, noCallback)
end

local function setupBestiaryCharmUI()
	local info = getBestiaryCreatureInfo()

	if not info then
		return
	end

	Cyclopedia.Bestiary.SelectedCharmCategory = nil

	if info.CharmSelector then
		function info.CharmSelector.onOptionChange()
			if bestiaryCharmSelectorUpdating then
				return
			end

			updateBestiaryAssignButtonState()
		end
	end
end

local function formatTrackerCreatureName(name, truncate)
	local formatted = name:gsub("(%a)([%w']*)", function(first, rest)
		return first:upper() .. rest:lower()
	end)

	if truncate and #formatted > 16 then
		return formatted:sub(1, 16) .. "..."
	end

	return formatted
end

local function applyBestiaryCreaturePreview(spriteWidget)
	if not spriteWidget then
		return
	end

	spriteWidget:setCenter(true)
	spriteWidget:setFixedCreatureSize(true)
	spriteWidget:setBaseScale(true)
	spriteWidget:setIgnoreDisplacementShift(true)
end

local BESTIARY_SLOT_OVERLAYS = {
	"Stackable",
	"eventMask",
	"undefinedItem"
}

local function isBestiaryEventLoot(specialEvent)
	return specialEvent and bit.band(specialEvent, 1) ~= 0
end

local function applyBestiaryLootEventOverlay(itemWidget, specialEvent)
	if not itemWidget or not itemWidget.eventMask then
		return
	end

	local showMask = isBestiaryEventLoot(specialEvent) and itemWidget.id and itemWidget.id > 0

	itemWidget.eventMask:setVisible(showMask)
end

local function applyBestiaryLootRarityOverlay(itemWidget)
	if not itemWidget or not itemWidget.rarity then
		return
	end

	local itemUi = itemWidget.item
	local item = itemUi and itemUi:getItem()
	local opt = modules.client_options.getOption("framesRarity")

	if not g_game.getFeature(GameColorizedLootValue) or opt == "none" or not item or item:getId() <= 0 then
		itemWidget.rarity:setVisible(false)
		ItemsDatabase.applyContainerRarityStackOrder(itemWidget, BESTIARY_SLOT_OVERLAYS)

		return
	end

	ItemsDatabase.setRarityItem(itemWidget.rarity, item)

	local imageSource = itemWidget.rarity:getImageSource()

	if imageSource and imageSource ~= "" and imageSource ~= "/images/ui/item" then
		itemWidget.rarity:setVisible(true)
	else
		itemWidget.rarity:setVisible(false)
	end

	ItemsDatabase.applyContainerRarityStackOrder(itemWidget, BESTIARY_SLOT_OVERLAYS)
end

local function isBestiaryCreatureUnlocked(creature)
	return creature and creature.currentLevel and creature.currentLevel >= 1
end

local function sendBestiaryOverviewSearch(raceIds)
	-- The overview packet already supports search mode and a list of race ids.
	-- Use the long-standing binding directly so this works with older binaries too.
	g_game.requestBestiaryOverview("", true, raceIds)

	return true
end

local function clearBestiarySearchInput()
	if not UI or not UI.SearchEdit or UI.SearchEdit:isDestroyed() then
		return
	end

	UI.SearchEdit:setText("")
	Cyclopedia.BestiarySearchText("")
end

local function finishBestiarySearchNavigation()
	Cyclopedia.Bestiary.SearchPending = false
end

local function resetBestiarySearchNoResult()
	finishBestiarySearchNavigation()
	Cyclopedia.verifyBestiaryButtons()
end

local function scheduleBestiarySearchFallback(requestId)
	scheduleEvent(function()
		if Cyclopedia.Bestiary.SearchPending and Cyclopedia.Bestiary.SearchRequestId == requestId then
			resetBestiarySearchNoResult()
		end
	end, 400)
end

local function normalizeRaceId(raceId)
	return tonumber(raceId) or raceId
end

local function getOverviewEchoRaid(raceId)
	local cache = Cyclopedia.Bestiary.OverviewCache

	if not cache then
		return 0, 0
	end

	raceId = normalizeRaceId(raceId)

	for _, creatures in pairs(cache) do
		for _, entry in ipairs(creatures) do
			if normalizeRaceId(entry.id) == raceId then
				return entry.charmPoints or 0, entry.ecoraid or 0
			end
		end
	end

	return 0, 0
end

local function getCreatureCategory(data)
	if not data then
		return nil
	end

	return data.bestClass or data.class
end

local function findCategoryPage(categoryName)
	local categories = Cyclopedia.Bestiary.Categories

	if not categories or not categoryName then
		return 1
	end

	for page = 1, Cyclopedia.Bestiary.TotalCategoriesPages or 1 do
		local pageCategories = categories[page]

		if pageCategories then
			for _, category in ipairs(pageCategories) do
				if category.name == categoryName then
					return page
				end
			end
		end
	end

	return 1
end

local function findCreaturePageInList(creatureData, raceId)
	raceId = normalizeRaceId(raceId)

	for i = 1, #creatureData do
		if normalizeRaceId(creatureData[i].id) == raceId then
			return math.floor((i - 1) / BESTIARY_PAGE_SIZE) + 1
		end
	end

	return 1
end

local function findCreaturePage(raceId, categoryName)
	raceId = normalizeRaceId(raceId)

	if not raceId then
		return 1
	end

	if categoryName and Cyclopedia.Bestiary.OverviewCache and Cyclopedia.Bestiary.OverviewCache[categoryName] then
		return findCreaturePageInList(Cyclopedia.Bestiary.OverviewCache[categoryName], raceId)
	end

	if Cyclopedia.Bestiary.Creatures and Cyclopedia.Bestiary.CreaturesCategory == categoryName then
		for page, pageCreatures in pairs(Cyclopedia.Bestiary.Creatures) do
			for _, creature in ipairs(pageCreatures) do
				if normalizeRaceId(creature.id) == raceId then
					return page
				end
			end
		end
	end

	return 1
end

local function setReturnTarget(raceId, category)
	raceId = normalizeRaceId(raceId)

	if not raceId then
		return
	end

	Cyclopedia.Bestiary.ReturnTarget = Cyclopedia.Bestiary.ReturnTarget or {}

	local target = Cyclopedia.Bestiary.ReturnTarget

	if category and category ~= "" then
		target.raceId = raceId
		target.category = category
		target.creaturePage = findCreaturePage(raceId, category)
		target.categoryPage = findCategoryPage(category)
	end
end

local CREATURE_DETAIL_SHOW_DELAY = 50
local creatureDetailShowEvent
local creatureDetailShowToken = 0

local function cancelCreatureDetailShow()
	if creatureDetailShowEvent then
		removeEvent(creatureDetailShowEvent)

		creatureDetailShowEvent = nil
	end
end

local function navigateBackFromCreature()
	clearTabBackRestore()
	cancelCreatureDetailShow()

	creatureDetailShowToken = creatureDetailShowToken + 1
	Cyclopedia.Bestiary.DeferCreatureUI = false
	Cyclopedia.Bestiary.Search = {}

	local target = Cyclopedia.Bestiary.ReturnTarget

	if not target or not target.category or target.category == "" then
		if Cyclopedia.Bestiary.ActiveCreatureRaceId then
			g_game.requestBestiarySearch(Cyclopedia.Bestiary.ActiveCreatureRaceId)
		end

		return
	end

	if target.raceId then
		target.creaturePage = findCreaturePage(target.raceId, target.category)
	end

	Cyclopedia.Bestiary.CurrentCategory = target.category
	Cyclopedia.Bestiary.Page = target.creaturePage or 1
	Cyclopedia.Bestiary.Stage = STAGES.CREATURES

	local cache = Cyclopedia.Bestiary.OverviewCache and Cyclopedia.Bestiary.OverviewCache[target.category]

	if cache then
		Cyclopedia.loadBestiaryCreatures(cache, target.category)
		Cyclopedia.onStageChange()
		g_game.requestBestiaryOverview(target.category, false, {})

		return
	end

	Cyclopedia.Bestiary.PendingPageRaceId = Cyclopedia.Bestiary.ActiveCreatureRaceId

	Cyclopedia.ShowBestiaryCreatures(target.category)
	Cyclopedia.onStageChange()
end

local function navigateBackFromCreaturesList()
	clearTabBackRestore()

	Cyclopedia.Bestiary.Stage = STAGES.CATEGORY
	Cyclopedia.Bestiary.Page = Cyclopedia.Bestiary.ReturnTarget.categoryPage or Cyclopedia.Bestiary.LastCategoryPage or 1

	Cyclopedia.onStageChange()
end

local function navigateBackFromSearch()
	clearTabBackRestore()

	Cyclopedia.Bestiary.Stage = STAGES.CATEGORY
	Cyclopedia.Bestiary.Page = Cyclopedia.Bestiary.LastCategoryPage or 1

	Cyclopedia.onStageChange()
end

function Cyclopedia.handleBestiaryBack()
	if not UI then
		return false
	end

	if Cyclopedia.Bestiary.TabBackRestore then
		Cyclopedia.Bestiary.TabBackRestore = false

		return false
	end

	local stage = Cyclopedia.Bestiary.Stage

	if stage == STAGES.CREATURE then
		navigateBackFromCreature()

		return true
	end

	if stage == STAGES.CREATURES then
		navigateBackFromCreaturesList()

		return true
	end

	if stage == STAGES.SEARCH then
		navigateBackFromSearch()

		return true
	end

	return false
end

function Cyclopedia.buildBestiaryCategoriesCache(data)
	Cyclopedia.Bestiary.Categories = {}
	Cyclopedia.Bestiary.TotalCategoriesPages = math.max(1, math.ceil(#data / BESTIARY_PAGE_SIZE))

	local page = 1

	Cyclopedia.Bestiary.Categories[page] = {}

	for i = 1, #data do
		if (i - 1) % BESTIARY_PAGE_SIZE == 0 and i > 1 then
			page = page + 1
			Cyclopedia.Bestiary.Categories[page] = {}
		end

		table.insert(Cyclopedia.Bestiary.Categories[page], {
			name = data[i].bestClass,
			amount = data[i].count,
			know = data[i].unlockedCount,
			AnimusMasteryBonus = data[i].AnimusMasteryBonus
		})
	end

	Cyclopedia.Bestiary.CategoriesLoaded = true

	Cyclopedia.scheduleBestiaryOverviewPreload()
end

function Cyclopedia.ensureBestiaryCategoriesRequested()
	if Cyclopedia.Bestiary.CategoriesRequested or not g_game.requestBestiary then
		return
	end

	Cyclopedia.Bestiary.CategoriesRequested = true

	g_game.requestBestiary()
end

function Cyclopedia.scheduleBestiaryOverviewPreload()
	if Cyclopedia.Bestiary.OverviewPreloadScheduled or not g_game.requestBestiaryOverview then
		return
	end

	Cyclopedia.Bestiary.OverviewPreloadScheduled = true

	scheduleEvent(Cyclopedia.preloadBestiaryOverviews, 200)
end

function Cyclopedia.preloadBestiaryOverviews()
	if not Cyclopedia.Bestiary.CategoriesLoaded or not g_game.requestBestiaryOverview then
		Cyclopedia.Bestiary.OverviewPreloadScheduled = false

		return
	end

	Cyclopedia.Bestiary.OverviewCache = Cyclopedia.Bestiary.OverviewCache or {}
	Cyclopedia.Bestiary.OverviewPreloadQueue = {}

	for page = 1, Cyclopedia.Bestiary.TotalCategoriesPages or 1 do
		for _, category in ipairs(Cyclopedia.Bestiary.Categories[page] or {}) do
			if not Cyclopedia.Bestiary.OverviewCache[category.name] then
				table.insert(Cyclopedia.Bestiary.OverviewPreloadQueue, category.name)
			end
		end
	end

	Cyclopedia.Bestiary.OverviewPreloadIndex = 1

	Cyclopedia.requestNextBestiaryOverviewPreload()
end

function Cyclopedia.requestNextBestiaryOverviewPreload()
	local queue = Cyclopedia.Bestiary.OverviewPreloadQueue
	local index = Cyclopedia.Bestiary.OverviewPreloadIndex

	if not queue or not index or index > #queue then
		Cyclopedia.Bestiary.OverviewPreloadScheduled = false
		Cyclopedia.Bestiary.OverviewPreloadQueue = nil
		Cyclopedia.Bestiary.OverviewPreloadIndex = nil

		return
	end

	g_game.requestBestiaryOverview(queue[index], false, {})

	Cyclopedia.Bestiary.OverviewPreloadIndex = index + 1

	scheduleEvent(Cyclopedia.requestNextBestiaryOverviewPreload, 100)
end

function Cyclopedia.clearBestiaryCachedData()
	if not Cyclopedia.Bestiary then
		return
	end

	Cyclopedia.Bestiary.Categories = nil
	Cyclopedia.Bestiary.CategoriesLoaded = false
	Cyclopedia.Bestiary.CategoriesRequested = false
	Cyclopedia.Bestiary.Creatures = nil
	Cyclopedia.Bestiary.CreaturesCategory = nil
	Cyclopedia.Bestiary.OverviewCache = nil
	Cyclopedia.Bestiary.CreatureDetailCache = nil
	Cyclopedia.Bestiary.OverviewPreloadScheduled = false
	Cyclopedia.Bestiary.OverviewPreloadQueue = nil
	Cyclopedia.Bestiary.OverviewPreloadIndex = nil
end

local function resetCreatureInfoPanel()
	if not UI or not UI.ListBase or not UI.ListBase.CreatureInfo then
		return
	end

	local info = UI.ListBase.CreatureInfo
	local resists = {
		"PhysicalProgress",
		"FireProgress",
		"EarthProgress",
		"EnergyProgress",
		"IceProgress",
		"HolyProgress",
		"DeathProgress",
		"HealingProgress"
	}

	for i = 1, 8 do
		info[resists[i]].Fill:setMarginRight(65)
		info[resists[i]]:removeTooltip()
	end

	info.AnimusMastery:setVisible(false)
	info.AnimusMastery:removeTooltip()

	if info.LeftBase and info.LeftBase.EchoRaidCharmPoints then
		info.LeftBase.EchoRaidCharmPoints:setVisible(false)
		info.LeftBase.EchoRaidCharmPoints:removeTooltip()
	end

	info.ItemsBase.Itemlist:destroyChildren()
	info.LocationField.Textlist.Text:setText("")
	info.CanUseSpellsIcon:setVisible(false)
end

local function applyCreatureQuickPreview(raceId)
	if not UI or not UI.ListBase or not UI.ListBase.CreatureInfo or not raceId then
		return
	end

	local raceData = g_things.getRaceData(raceId)

	if not raceData or not raceData.name then
		return
	end

	local info = UI.ListBase.CreatureInfo
	local formattedName = raceData.name:gsub("(%l)(%w*)", function(first, rest)
		return first:upper() .. rest
	end)

	info:setText(formattedName)
	info.LeftBase.Sprite:setOutfit(raceData.outfit)
	applyBestiaryCreaturePreview(info.LeftBase.Sprite)
	info.LeftBase.Sprite:getCreature():setStaticWalking(1000)
end

local function showCreatureDetailPanel()
	if not UI or not UI.ListBase then
		return
	end

	UI.BackPageButton:setEnabled(true)
	UI.ListBase.CategoryList:setVisible(false)
	UI.ListBase.CreatureList:setVisible(false)
	UI.ListBase.CreatureInfo:setVisible(true)

	function UI.BackPageButton.onClick()
		navigateBackFromCreature()
	end

	Cyclopedia.verifyBestiaryButtons()
	scheduleEvent(focusBestiarySearchEdit, 0)
end

local function scheduleCreatureDetailReveal(raceId, token)
	cancelCreatureDetailShow()

	creatureDetailShowEvent = scheduleEvent(function()
		creatureDetailShowEvent = nil

		if token ~= creatureDetailShowToken or not UI then
			return
		end

		if normalizeRaceId(Cyclopedia.Bestiary.ActiveCreatureRaceId) ~= normalizeRaceId(raceId) then
			return
		end

		Cyclopedia.Bestiary.DeferCreatureUI = false
		Cyclopedia.Bestiary.Stage = STAGES.CREATURE

		showCreatureDetailPanel()

		local cache = raceId and Cyclopedia.Bestiary.CreatureDetailCache and Cyclopedia.Bestiary.CreatureDetailCache[raceId]

		if cache then
			Cyclopedia.loadBestiarySelectedCreature(cache)
		else
			resetCreatureInfoPanel()
			applyCreatureQuickPreview(raceId)
			Cyclopedia.refreshBestiaryCharmUI()
		end
	end, CREATURE_DETAIL_SHOW_DELAY)
end

local function openCreatureDetail(raceId, category)
	if not UI then
		return
	end

	clearTabBackRestore()

	raceId = normalizeRaceId(raceId)
	creatureDetailShowToken = creatureDetailShowToken + 1

	local token = creatureDetailShowToken

	Cyclopedia.Bestiary.DeferCreatureUI = true
	Cyclopedia.Bestiary.Stage = STAGES.CREATURE
	Cyclopedia.Bestiary.ActiveCreatureRaceId = raceId
	Cyclopedia.Bestiary.PendingPageRaceId = nil

	if category then
		setReturnTarget(raceId, category)
	end

	scheduleCreatureDetailReveal(raceId, token)
end

local bestiarySearchEnterCallback

local function focusBestiarySearchEdit()
	if not UI or not UI.SearchEdit or UI.SearchEdit:isDestroyed() then
		return
	end

	local cyclopediaUi = controllerCyclopedia and controllerCyclopedia.ui

	if not cyclopediaUi or cyclopediaUi:isDestroyed() or not cyclopediaUi:isVisible() then
		return
	end

	local edit = UI.SearchEdit

	edit:setFocusable(true)
	cyclopediaUi:raise()
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

local function setupBestiarySearchEdit()
	if not UI or not UI.SearchEdit or UI.SearchEdit:isDestroyed() then
		return
	end

	local edit = UI.SearchEdit

	edit:setFocusable(true)

	function edit.onFocusChange(widget, focused)
		if focused and not widget:isDestroyed() then
			local cyclopediaUi = controllerCyclopedia and controllerCyclopedia.ui

			if not cyclopediaUi or cyclopediaUi:isDestroyed() or not cyclopediaUi:isVisible() then
				return
			end

			pcall(function()
				widget:grabKeyboard()
			end)
			pcall(function()
				widget:setCursorVisible(true)
			end)
		end
	end

	function edit.onKeyDown(widget, keyCode, keyboardModifiers)
		if keyboardModifiers ~= KeyboardNoModifier then
			return false
		end

		if keyCode == KeyEscape then
			Cyclopedia.releaseBestiarySearchFocus()

			if toggle then
				toggle()
			end

			return true
		end

		return false
	end

	if bestiarySearchEnterCallback then
		g_keyboard.unbindKeyDown("Enter", bestiarySearchEnterCallback, edit)

		bestiarySearchEnterCallback = nil
	end

	function bestiarySearchEnterCallback()
		if not UI or not UI:isVisible() or not edit or edit:isDestroyed() then
			return
		end

		if edit:getText():trim() ~= "" then
			Cyclopedia.BestiarySearch()
		end
	end

	g_keyboard.bindKeyDown("Enter", bestiarySearchEnterCallback, edit)
end

function Cyclopedia.releaseBestiarySearchFocus()
	local edit = UI and UI.SearchEdit

	if (not edit or edit:isDestroyed()) and contentContainer then
		for _, child in ipairs(contentContainer:getChildren()) do
			local searchEdit = child:recursiveGetChildById("SearchEdit")

			if searchEdit and not searchEdit:isDestroyed() then
				edit = searchEdit

				break
			end
		end
	end

	if edit and not edit:isDestroyed() then
		if bestiarySearchEnterCallback then
			g_keyboard.unbindKeyDown("Enter", bestiarySearchEnterCallback, edit)

			bestiarySearchEnterCallback = nil
		end

		pcall(function()
			edit:ungrabKeyboard()
		end)
	end
end

local function resetBestiaryViewState()
	Cyclopedia.Bestiary.Stage = STAGES.CATEGORY
	Cyclopedia.Bestiary.Page = 1
	Cyclopedia.Bestiary.Search = {}
	Cyclopedia.Bestiary.SearchPending = false
	Cyclopedia.Bestiary.DeferCreatureUI = false
	Cyclopedia.Bestiary.ActiveCreatureRaceId = nil
	Cyclopedia.Bestiary.PendingPageRaceId = nil
	Cyclopedia.Bestiary.CurrentCategory = nil
	Cyclopedia.Bestiary.LastCategoryPage = nil
	Cyclopedia.Bestiary.ReturnTarget = {}
end

function Cyclopedia.clearBestiaryUI(resetState)
	cancelCreatureDetailShow()

	creatureDetailShowToken = creatureDetailShowToken + 1

	if resetState then
		resetBestiaryViewState()

		Cyclopedia.Bestiary.TabBackRestore = false
		Cyclopedia.Bestiary.RestoreView = false
	end

	Cyclopedia.releaseBestiarySearchFocus()

	Cyclopedia.Bestiary.SelectedCharmCategory = nil
	UI = nil
end

function Cyclopedia.loadBestiaryOverview(name, creatures, animusMasteryPoints)
	if name and name ~= "Search" and name ~= "Result" then
		Cyclopedia.Bestiary.OverviewCache = Cyclopedia.Bestiary.OverviewCache or {}
		Cyclopedia.Bestiary.OverviewCache[name] = creatures
	end

	if Cyclopedia.Bestiary.SearchPending then
		Cyclopedia.loadBestiarySearchCreatures(creatures)

		return
	end

	if name == "Search" or name == "Result" then
		Cyclopedia.loadBestiarySearchCreatures(creatures)
	else
		Cyclopedia.loadBestiaryCreatures(creatures, name)
	end

	if animusMasteryPoints and animusMasteryPoints > 0 then
		-- block empty
	end
end

local function restoreBestiaryViewUI()
	local stage = Cyclopedia.Bestiary.Stage

	Cyclopedia.Bestiary.TabBackRestore = true

	if stage == STAGES.CREATURE then
		local raceId = Cyclopedia.Bestiary.ActiveCreatureRaceId
		local cache = raceId and Cyclopedia.Bestiary.CreatureDetailCache and Cyclopedia.Bestiary.CreatureDetailCache[raceId]

		if cache then
			Cyclopedia.Bestiary.DeferCreatureUI = false
			Cyclopedia.Bestiary.Stage = STAGES.CREATURE

			showCreatureDetailPanel()
			Cyclopedia.loadBestiarySelectedCreature(cache)
		elseif raceId then
			openCreatureDetail(raceId, Cyclopedia.Bestiary.ReturnTarget.category)

			Cyclopedia.Bestiary.TabBackRestore = true

			g_game.requestBestiarySearch(raceId)
		else
			Cyclopedia.Bestiary.Stage = STAGES.CATEGORY
			Cyclopedia.Bestiary.Page = 1

			Cyclopedia.onStageChange()
		end

		Cyclopedia.verifyBestiaryButtons()

		return
	end

	if stage == STAGES.CREATURES then
		local category = Cyclopedia.Bestiary.CurrentCategory

		if category then
			local cache = Cyclopedia.Bestiary.OverviewCache and Cyclopedia.Bestiary.OverviewCache[category]

			if cache then
				Cyclopedia.loadBestiaryCreatures(cache, category)
			end

			g_game.requestBestiaryOverview(category, false, {})
		end

		Cyclopedia.onStageChange()

		return
	end

	Cyclopedia.onStageChange()
end

function showBestiary()
	local restore = Cyclopedia.Bestiary.RestoreView

	Cyclopedia.Bestiary.RestoreView = false

	if not restore then
		resetBestiaryViewState()
	end

	UI = g_ui.loadUI("bestiary", contentContainer)

	function UI.onDestroy()
		UI = nil
		bestiarySearchEnterCallback = nil
	end

	UI:show()
	UI.ListBase.CategoryList:setVisible(true)
	UI.ListBase.CreatureList:setVisible(false)
	UI.ListBase.CreatureInfo:setVisible(false)
	controllerCyclopedia.ui.MajorCharmsBase:setVisible(true)
	controllerCyclopedia.ui.GoldBase:setVisible(true)
	controllerCyclopedia.ui.BestiaryTrackerButton:setVisible(true)
	controllerCyclopedia.ui.MinorCharmsBase:setVisible(true)
	Cyclopedia.ensureStoredRaceIDsPopulated()
	setupBestiarySearchEdit()
	setupBestiaryCharmUI()
	Cyclopedia.ensureBestiaryCategoriesRequested()

	if restore then
		restoreBestiaryViewUI()
	elseif Cyclopedia.Bestiary.CategoriesLoaded and Cyclopedia.Bestiary.Categories then
		if UI.PageValue then
			UI.PageValue:setText(string.format("%d / %d", 1, Cyclopedia.Bestiary.TotalCategoriesPages or 1))
		end

		Cyclopedia.loadBestiaryCategory(1)
		Cyclopedia.onStageChange()
		Cyclopedia.verifyBestiaryButtons()
	else
		Cyclopedia.onStageChange()
		Cyclopedia.verifyBestiaryButtons()
	end

	focusBestiarySearchEdit()
	scheduleEvent(focusBestiarySearchEdit, 50)

	if Cyclopedia._pendingBestiaryRaceId then
		local pending = Cyclopedia._pendingBestiaryRaceId

		Cyclopedia._pendingBestiaryRaceId = nil

		openCreatureDetail(pending)
		g_game.requestBestiarySearch(pending)
	end
end

function Cyclopedia.SetBestiaryProgress(fitCenter, firstBar, secondBar, thirdBar, killCount, firstGoal, secondGoal, thirdGoal, fitOuter, fillHeight)
	fitOuter = fitOuter or fitCenter
	fillHeight = fillHeight or 18

	local function calculateWidth(value, max, fit)
		return math.min(math.floor(value / max * fit), fit)
	end

	local allStagesComplete = thirdGoal > 0 and thirdGoal <= killCount
	local fillImage = allStagesComplete and "/images/bars/progressbar-green-large" or "/images/bars/progressbar-orange-large"

	local function setBarVisibility(bar, isVisible, width)
		if not bar then
			return
		end

		isVisible = isVisible and width > 0

		bar:setVisible(isVisible)

		if isVisible then
			local rect = {
				y = 0,
				x = 0,
				height = fillHeight,
				width = width
			}

			bar:setImageRect(rect)
			bar:setImageClip(rect)
			bar:setImageSource(fillImage)
		end
	end

	local firstWidth = calculateWidth(math.min(killCount, firstGoal), firstGoal, fitOuter)

	setBarVisibility(firstBar, killCount > 0, firstWidth)

	local secondWidth = 0

	if firstGoal < killCount then
		secondWidth = calculateWidth(math.min(killCount - firstGoal, secondGoal - firstGoal), secondGoal - firstGoal, fitCenter)
	end

	setBarVisibility(secondBar, firstGoal < killCount, secondWidth)

	local thirdWidth = 0

	if secondGoal < killCount then
		thirdWidth = calculateWidth(math.min(killCount - secondGoal, thirdGoal - secondGoal), thirdGoal - secondGoal, fitOuter)
	end

	setBarVisibility(thirdBar, secondGoal < killCount, thirdWidth)
end

function Cyclopedia.SetBestiaryStars(value)
	local starFill = UI.ListBase.CreatureInfo.StarFill

	for i = 1, 5 do
		local star = starFill:getChildById("StarFill" .. i)

		if star then
			star:setVisible(i <= value)
		end
	end
end

function Cyclopedia.SetBestiaryDiamonds(value)
	UI.ListBase.CreatureInfo.DiamondFill:setWidth(value * 11)
end

function Cyclopedia.CreateCreatureItems(data)
	UI.ListBase.CreatureInfo.ItemsBase.Itemlist:destroyChildren()

	local itemsPerRow = 15
	local maxItemsPerDifficulty = 30
	local firstGroupTopMargin = 5
	local groupsSpacing = 0
	local lastGroupBottomMargin = -4
	local difficultyOrder = {}

	for difficulty, _ in pairs(data) do
		table.insert(difficultyOrder, difficulty)
	end

	table.sort(difficultyOrder)

	for orderIndex, index in ipairs(difficultyOrder) do
		local widget = g_ui.createWidget("BestiaryItemGroup", UI.ListBase.CreatureInfo.ItemsBase.Itemlist)

		widget:setId(index)
		widget:setMarginTop(orderIndex == 1 and firstGroupTopMargin or groupsSpacing)
		widget:setMarginBottom(orderIndex == #difficultyOrder and lastGroupBottomMargin or 0)

		if index == 0 then
			widget.Title:setText(tr("Common") .. ":")
		elseif index == 1 then
			widget.Title:setText(tr("Uncommon") .. ":")
		elseif index == 2 then
			widget.Title:setText(tr("Semi-Rare") .. ":")
		elseif index == 3 then
			widget.Title:setText(tr("Rare") .. ":")
		else
			widget.Title:setText(tr("Very Rare") .. ":")
		end

		for i = 1, itemsPerRow do
			local item = g_ui.createWidget("BestiaryItem", widget.Items)

			item:setId(i)
		end

		for i = 1, itemsPerRow do
			local item = g_ui.createWidget("BestiaryItem", widget.ItemsSecond)

			item:setId(i)
		end

		local lootEntries = data[index] or {}
		local visibleLootCount = math.min(#lootEntries, maxItemsPerDifficulty)
		local hasSecondRow = itemsPerRow < visibleLootCount

		widget.ItemsSecond:setVisible(hasSecondRow)
		widget:setHeight(hasSecondRow and 78 or 44)

		for itemIndex, itemData in ipairs(lootEntries) do
			if maxItemsPerDifficulty < itemIndex then
				break
			end

			local thing = g_things.getThingType(itemData.id, ThingCategoryItem)
			local itemWidget

			if itemIndex <= itemsPerRow then
				itemWidget = widget.Items[itemIndex]
			else
				itemWidget = widget.ItemsSecond[itemIndex - itemsPerRow]
			end

			if not itemWidget then
				break
			end

			local itemSlot = itemWidget.itemSlot
			local itemUi = itemWidget.item

			if itemUi then
				itemUi:setItemId(itemData.id)
			end

			itemWidget.id = itemData.id
			itemWidget.classification = thing:getClassification()

			if itemSlot then
				if itemData.id > 0 then
					itemSlot:setImageSource("/game_cyclopedia/images/bestiary/item-slot")
				else
					itemSlot:setImageSource("/game_cyclopedia/images/bestiary/item-slot-empty")
				end
			end

			if itemData.id == 0 then
				itemWidget.undefinedItem:setVisible(true)
			end

			if itemData.id > 0 then
				if itemData.amount == 1 then
					itemWidget.Stackable:setText("1+")
				else
					itemWidget.Stackable:setText("1")
				end
			end

			applyBestiaryLootRarityOverlay(itemWidget)
			applyBestiaryLootEventOverlay(itemWidget, itemData.specialEvent)

			itemWidget.onMouseRelease = onAddLootClick
		end
	end
end

function Cyclopedia.loadBestiarySelectedCreature(data)
	Cyclopedia.Bestiary.CreatureDetailCache = Cyclopedia.Bestiary.CreatureDetailCache or {}
	Cyclopedia.Bestiary.CreatureDetailCache[data.id] = data

	local category = getCreatureCategory(data)

	if (Cyclopedia.Bestiary.ActiveCreatureRaceId == nil or normalizeRaceId(Cyclopedia.Bestiary.ActiveCreatureRaceId) == normalizeRaceId(data.id)) and category and category ~= "" then
		setReturnTarget(data.id, category)
	end

	if not UI then
		return
	end

	if Cyclopedia.Bestiary.ActiveCreatureRaceId and normalizeRaceId(Cyclopedia.Bestiary.ActiveCreatureRaceId) ~= normalizeRaceId(data.id) then
		return
	end

	if Cyclopedia.Bestiary.SearchPending then
		finishBestiarySearchNavigation()

		if not isBestiaryCreatureUnlocked(data) then
			Cyclopedia.verifyBestiaryButtons()

			return
		end

		Cyclopedia.Bestiary.ActiveCreatureRaceId = data.id
		Cyclopedia.Bestiary.DeferCreatureUI = true
		creatureDetailShowToken = creatureDetailShowToken + 1

		scheduleCreatureDetailReveal(data.id, creatureDetailShowToken)

		return
	end

	if Cyclopedia.Bestiary.DeferCreatureUI then
		return
	end

	local occurence = {
		[0] = 1,
		2,
		3,
		4
	}
	local raceData = g_things.getRaceData(data.id)
	local formattedName = raceData.name:gsub("(%l)(%w*)", function(first, rest)
		return first:upper() .. rest
	end)

	UI.ListBase.CreatureInfo:setText(formattedName)
	Cyclopedia.SetBestiaryDiamonds(occurence[data.ocorrence])
	Cyclopedia.SetBestiaryStars(data.difficulty)
	UI.ListBase.CreatureInfo.LeftBase.Sprite:setOutfit(raceData.outfit)
	applyBestiaryCreaturePreview(UI.ListBase.CreatureInfo.LeftBase.Sprite)
	UI.ListBase.CreatureInfo.LeftBase.Sprite:getCreature():setStaticWalking(1000)
	Cyclopedia.SetBestiaryProgress(60, UI.ListBase.CreatureInfo.ProgressBack, UI.ListBase.CreatureInfo.ProgressBack33, UI.ListBase.CreatureInfo.ProgressBack55, data.killCounter, data.thirdDifficulty, data.secondUnlock, data.lastProgressKillCount, 61)
	UI.ListBase.CreatureInfo.ProgressValue:setText(comma_value(tostring(data.killCounter)))

	local fullText = ""

	if data.killCounter >= data.lastProgressKillCount then
		fullText = "(fully unlocked)"
	end

	UI.ListBase.CreatureInfo.ProgressBorder1:setTooltip(string.format(" %d / %d %s", data.killCounter, data.thirdDifficulty, fullText))
	UI.ListBase.CreatureInfo.ProgressBorder2:setTooltip(string.format(" %d / %d %s", data.killCounter, data.secondUnlock, fullText))
	UI.ListBase.CreatureInfo.ProgressBorder3:setTooltip(string.format(" %d / %d %s", data.killCounter, data.lastProgressKillCount, fullText))

	Cyclopedia.Bestiary.SelectedRaceId = data.id
	Cyclopedia.Bestiary.SelectedCharmCategory = nil
	UI.ListBase.CreatureInfo.LeftBase.TrackCheck.raceId = data.id

	Cyclopedia.ensureStoredRaceIDsPopulated()

	local trackCheck = UI.ListBase.CreatureInfo.LeftBase.TrackCheck

	trackCheck._suppressTrackCheckChange = true

	if table.find(storedRaceIDs, data.id) then
		trackCheck:setChecked(true)
	else
		trackCheck:setChecked(false)
	end

	trackCheck._suppressTrackCheckChange = false

	if data.currentLevel > 1 then
		UI.ListBase.CreatureInfo.Value1:setText(comma_value(tostring(data.maxHealth)))
		UI.ListBase.CreatureInfo.Value2:setText(comma_value(tostring(data.experience)))
		UI.ListBase.CreatureInfo.Value3:setText(data.speed)
		UI.ListBase.CreatureInfo.Value4:setText(data.armor)
		UI.ListBase.CreatureInfo.Value5:setText(string.format("%.2f%%", data.mitigation))
		UI.ListBase.CreatureInfo.BonusValue:setText(data.charmValue)
	else
		UI.ListBase.CreatureInfo.Value1:setText("?")
		UI.ListBase.CreatureInfo.Value2:setText("?")
		UI.ListBase.CreatureInfo.Value3:setText("?")
		UI.ListBase.CreatureInfo.Value4:setText("?")
		UI.ListBase.CreatureInfo.Value5:setText("?")
		UI.ListBase.CreatureInfo.BonusValue:setText("?")
	end

	local modeIcons = {
		[0] = "/game_cyclopedia/images/bestiary/icons/monster-icon-melee.png",
		"/game_cyclopedia/images/bestiary/icons/monster-icon-ranged.png",
		"/game_cyclopedia/images/bestiary/icons/monster-icon-noattack.png"
	}
	local attackModeKey = data.attackMode

	if attackModeKey ~= 0 and attackModeKey ~= 1 then
		attackModeKey = 2
	end

	local iconPath = modeIcons[attackModeKey]
	local attackModeWidget = UI.ListBase.CreatureInfo.AttackMode

	attackModeWidget:setImageSource(iconPath)
	attackModeWidget:setSize("9 9")

	local canUseSpellsIcon = UI.ListBase.CreatureInfo.CanUseSpellsIcon

	if data.canUseSpells then
		canUseSpellsIcon:setVisible(true)
		canUseSpellsIcon:setImageSource("/game_cyclopedia/images/bestiary/icons/monster-icon-spellcaster.png")
		canUseSpellsIcon:setSize("9 9")
	else
		canUseSpellsIcon:setVisible(false)
	end

	local resists = {
		"PhysicalProgress",
		"FireProgress",
		"EarthProgress",
		"EnergyProgress",
		"IceProgress",
		"HolyProgress",
		"DeathProgress",
		"HealingProgress"
	}

	if not table.empty(data.combat) then
		for i = 1, 8 do
			local combat = Cyclopedia.calculateCombatValues(data.combat[i])

			UI.ListBase.CreatureInfo[resists[i]].Fill:setMarginRight(combat.margin)
			UI.ListBase.CreatureInfo[resists[i]].Fill:setBackgroundColor(combat.color)
			UI.ListBase.CreatureInfo[resists[i]]:setTooltip(string.format("Sensitive to %s : %s", string.gsub(resists[i], "Progress", ""):lower(), combat.tooltip))
		end
	else
		for i = 1, 8 do
			UI.ListBase.CreatureInfo[resists[i]].Fill:setMarginRight(65)
		end
	end

	local lootData = {}

	for _, value in ipairs(data.loot) do
		local loot = {
			name = value.name,
			id = value.itemId,
			difficulty = value.diffculty,
			specialEvent = value.specialEvent or 0,
			amount = value.amount or 0
		}

		if not lootData[value.diffculty] then
			lootData[value.diffculty] = {}
		end

		table.insert(lootData[value.diffculty], loot)
	end

	Cyclopedia.CreateCreatureItems(lootData)
	UI.ListBase.CreatureInfo.LocationField.Textlist.Text:setText(data.location)

	if data.AnimusMasteryBonus > 0 then
		local bonusPercent = data.AnimusMasteryBonus / 10
		local masteryPoints = data.AnimusMasteryPoints or animusMasteryPoints or 0

		UI.ListBase.CreatureInfo.AnimusMastery:setTooltip("The Animus Mastery for this creature is unlocked.\nIt yields " .. bonusPercent .. "% bonus experience points, plus an additional 0.1% for every 10 Animus Masteries unlocked, up to a maximum of 4%.\nYou currently benefit from " .. bonusPercent .. "% bonus experience points due to having unlocked " .. masteryPoints .. " Animus Masteries.")
		UI.ListBase.CreatureInfo.AnimusMastery:setVisible(true)
	else
		UI.ListBase.CreatureInfo.AnimusMastery:removeTooltip()
		UI.ListBase.CreatureInfo.AnimusMastery:setVisible(false)
	end

	local overviewCharmPoints, overviewEcoraid = getOverviewEchoRaid(data.id)

	applyEchoRaidCharmIndicator(UI.ListBase.CreatureInfo, overviewEcoraid, math.max(data.charmPoints or 0, overviewCharmPoints))
	Cyclopedia.refreshBestiaryCharmUI()

	if Cyclopedia.Bestiary.Stage == STAGES.CREATURE and UI.ListBase.CreatureInfo:isVisible() then
		scheduleEvent(focusBestiarySearchEdit, 0)
	end
end

function Cyclopedia.ShowBestiaryCreature(raceId, category)
	openCreatureDetail(raceId, category)
end

function Cyclopedia.ShowBestiaryCreatures(Category)
	Cyclopedia.Bestiary.CurrentCategory = Category

	if not UI then
		g_game.requestBestiaryOverview(Category, false, {})

		return
	end

	UI.ListBase.CreatureList:destroyChildren()
	UI.ListBase.CategoryList:setVisible(false)
	UI.ListBase.CreatureInfo:setVisible(false)
	UI.ListBase.CreatureList:setVisible(true)

	local cache = Cyclopedia.Bestiary.OverviewCache and Cyclopedia.Bestiary.OverviewCache[Category]

	if cache then
		Cyclopedia.loadBestiaryCreatures(cache, Category)
	end

	g_game.requestBestiaryOverview(Category, false, {})
end

function Cyclopedia.CreateBestiaryCategoryItem(Data)
	if not UI then
		return
	end

	local widget = g_ui.createWidget("BestiaryCategory", UI.ListBase.CategoryList)

	widget:setFocusable(false)
	widget:setText(Data.name)
	widget.ClassIcon:setImageSource("/game_cyclopedia/images/bestiary/creatures/" .. Data.name:lower():gsub(" ", "_"))

	widget.Category = Data.name

	widget.TotalValue:setText(string.format("Total: %d", Data.amount))
	widget.KnownValue:setText(string.format("Known: %d", Data.know))

	function widget.ClassBase:onClick()
		clearTabBackRestore()
		UI.BackPageButton:setEnabled(true)

		Cyclopedia.Bestiary.LastCategoryPage = Cyclopedia.Bestiary.Page
		Cyclopedia.Bestiary.PendingPageRaceId = nil

		Cyclopedia.ShowBestiaryCreatures(self:getParent().Category)

		Cyclopedia.Bestiary.Stage = STAGES.CREATURES

		Cyclopedia.onStageChange()
	end
end

function Cyclopedia.loadBestiarySearchCreatures(data)
	if not UI then
		return
	end

	finishBestiarySearchNavigation()

	local unlockedCreatures = {}

	for i = 1, #data do
		local entry = data[i]

		if isBestiaryCreatureUnlocked(entry) then
			table.insert(unlockedCreatures, {
				id = entry.id,
				currentLevel = entry.currentLevel,
				AnimusMasteryBonus = entry.creatureAnimusMasteryBonus or entry.AnimusMasteryBonus or 0,
				ecoraid = entry.ecoraid or 0,
				charmPoints = entry.charmPoints or 0
			})
		end
	end

	if #unlockedCreatures == 0 then
		Cyclopedia.verifyBestiaryButtons()

		return
	end

	if #unlockedCreatures == 1 then
		openCreatureDetail(unlockedCreatures[1].id)
		g_game.requestBestiarySearch(unlockedCreatures[1].id)

		return
	end

	UI.ListBase.CategoryList:setVisible(false)
	UI.ListBase.CreatureInfo:setVisible(false)
	UI.ListBase.CreatureList:setVisible(true)
	UI.BackPageButton:setEnabled(true)

	Cyclopedia.Bestiary.Search = {}
	Cyclopedia.Bestiary.Page = 1
	Cyclopedia.Bestiary.TotalSearchPages = math.max(1, math.ceil(#unlockedCreatures / BESTIARY_PAGE_SIZE))

	if Cyclopedia.Bestiary.Page > Cyclopedia.Bestiary.TotalSearchPages then
		Cyclopedia.Bestiary.Page = Cyclopedia.Bestiary.TotalSearchPages
	end

	UI.PageValue:setText(string.format("%d / %d", Cyclopedia.Bestiary.Page, Cyclopedia.Bestiary.TotalSearchPages))

	local page = 1

	Cyclopedia.Bestiary.Search[page] = {}

	for i = 1, #unlockedCreatures do
		if (i - 1) % BESTIARY_PAGE_SIZE == 0 and i > 1 then
			page = page + 1
			Cyclopedia.Bestiary.Search[page] = {}
		end

		table.insert(Cyclopedia.Bestiary.Search[page], unlockedCreatures[i])
	end

	Cyclopedia.Bestiary.Stage = STAGES.SEARCH

	Cyclopedia.onStageChange()
	Cyclopedia.verifyBestiaryButtons()
end

function Cyclopedia.loadBestiaryCreatures(data, categoryName)
	Cyclopedia.Bestiary.Creatures = {}
	Cyclopedia.Bestiary.CreaturesCategory = categoryName
	Cyclopedia.Bestiary.TotalCreaturesPages = math.max(1, math.ceil(#data / BESTIARY_PAGE_SIZE))

	local page = 1

	Cyclopedia.Bestiary.Creatures[page] = {}

	for i = 1, #data do
		if (i - 1) % BESTIARY_PAGE_SIZE == 0 and i > 1 then
			page = page + 1
			Cyclopedia.Bestiary.Creatures[page] = {}
		end

		table.insert(Cyclopedia.Bestiary.Creatures[page], {
			id = data[i].id,
			currentLevel = data[i].currentLevel,
			AnimusMasteryBonus = data[i].creatureAnimusMasteryBonus,
			ecoraid = data[i].ecoraid or 0,
			charmPoints = data[i].charmPoints or 0
		})
	end

	local targetPage = 1
	local target = Cyclopedia.Bestiary.ReturnTarget

	if Cyclopedia.Bestiary.PendingPageRaceId then
		targetPage = findCreaturePage(Cyclopedia.Bestiary.PendingPageRaceId, categoryName)
		Cyclopedia.Bestiary.PendingPageRaceId = nil
	elseif target and target.category == categoryName and target.creaturePage then
		targetPage = target.creaturePage
	end

	Cyclopedia.Bestiary.Page = targetPage

	if not UI then
		return
	end

	if UI.PageValue then
		UI.PageValue:setText(string.format("%d / %d", Cyclopedia.Bestiary.Page, Cyclopedia.Bestiary.TotalCreaturesPages))
	end

	if Cyclopedia.Bestiary.Stage == STAGES.CREATURES and Cyclopedia.Bestiary.CurrentCategory == categoryName then
		Cyclopedia.loadBestiaryCreature(Cyclopedia.Bestiary.Page, false)
	end

	Cyclopedia.verifyBestiaryButtons()
end

function Cyclopedia.BestiarySearch()
	if not UI then
		return
	end

	Cyclopedia.Bestiary.Search = {}

	local text = UI.SearchEdit:getText():trim()

	if text == "" then
		return
	end

	local searchLower = text:lower()
	local raceIds = {}

	for _, race in ipairs(g_things.getMonsterList()) do
		if race.name and race.name:lower():find(searchLower, 1, true) and race.raceId and race.raceId > 0 then
			table.insert(raceIds, race.raceId)
		end
	end

	if #raceIds == 0 then
		clearBestiarySearchInput()

		return
	end

	Cyclopedia.Bestiary.SearchRequestId = (Cyclopedia.Bestiary.SearchRequestId or 0) + 1

	local requestId = Cyclopedia.Bestiary.SearchRequestId

	Cyclopedia.Bestiary.SearchPending = true

	if not sendBestiaryOverviewSearch(raceIds) then
		Cyclopedia.Bestiary.SearchPending = false

		g_logger.warning("[Bestiary] Search is unavailable. Rebuild the client with bestiary overview search support.")

		return
	end

	clearBestiarySearchInput()
	scheduleBestiarySearchFallback(requestId)
end

function Cyclopedia.BestiarySearchText(text)
	if not UI then
		return
	end

	if text ~= "" then
		UI.SearchButton:enable(true)
	else
		UI.SearchButton:disable(false)
	end
end

function Cyclopedia.CreateBestiaryCreaturesItem(data)
	if not UI then
		return
	end

	local raceData = g_things.getRaceData(data.id)

	local function verify(name)
		if #name > 18 then
			return name:sub(1, 15) .. "..."
		else
			return name
		end
	end

	local widget = g_ui.createWidget("BestiaryCreature", UI.ListBase.CreatureList)

	widget:setFocusable(false)
	widget:setId(data.id)

	local formattedName = raceData.name:gsub("(%l)(%w*)", function(first, rest)
		return first:upper() .. rest
	end)

	widget.Name:setText(verify(formattedName))
	widget.Sprite:setOutfit(raceData.outfit)
	applyBestiaryCreaturePreview(widget.Sprite)
	widget.Sprite:getCreature():setStaticWalking(1000)

	if data.AnimusMasteryBonus > 0 then
		widget.AnimusMastery:setTooltip("The Animus Mastery for this creature is unlocked.\nIt yields " .. data.AnimusMasteryBonus .. "% bonus experience points, plus an additional 0.1% for every 10 Animus Masteries unlocked, up to a maximum of 4%.\nYou currently benefit from " .. data.AnimusMasteryBonus .. "% bonus experience points due to having unlocked " .. animusMasteryPoints .. " Animus Masteries.")
		widget.AnimusMastery:setVisible(true)
	else
		widget.AnimusMastery:removeTooltip()
		widget.AnimusMastery:setVisible(false)
	end

	applyEchoRaidCharmIndicator(widget, data.ecoraid, data.charmPoints)

	if data.currentLevel >= 4 then
		widget.Finalized:setVisible(true)
		widget.KillsLabel:setVisible(false)
		widget.Sprite:getCreature():setShader("")
	elseif data.currentLevel < 1 then
		widget.Finalized:setVisible(false)
		widget.KillsLabel:setVisible(true)
		widget.KillsLabel:setText("?")
		widget.Sprite:getCreature():setShader("Outfit - cyclopedia-black")
		widget.Name:setText("Unknown")
		widget.AnimusMastery:setVisible(false)
		widget.AnimusMastery:removeTooltip()
		widget.EchoRaidCharmPoints:setVisible(false)
		widget.EchoRaidCharmPoints:removeTooltip()
	else
		widget.Finalized:setVisible(false)
		widget.KillsLabel:setVisible(true)
		widget.KillsLabel:setText(string.format("%d / 3", data.currentLevel - 1))
		widget.Sprite:getCreature():setShader("")
	end

	function widget.ClassBase:onClick()
		if data.currentLevel < 1 then
			return
		end

		UI.BackPageButton:setEnabled(true)

		local category = Cyclopedia.Bestiary.Stage == STAGES.CREATURES and Cyclopedia.Bestiary.CurrentCategory or nil

		openCreatureDetail(data.id, category)
		g_game.requestBestiarySearch(data.id)
	end
end

function Cyclopedia.loadBestiaryCreature(page, search)
	if not UI then
		return
	end

	local state = "Creatures"

	if search then
		state = "Search"
	end

	local stageData = Cyclopedia.Bestiary[state]

	if not stageData or not stageData[page] then
		return
	end

	UI.ListBase.CreatureList:destroyChildren()

	for _, data in ipairs(stageData[page]) do
		Cyclopedia.CreateBestiaryCreaturesItem(data)
	end
end

function Cyclopedia.loadBestiaryCategories(data)
	Cyclopedia.buildBestiaryCategoriesCache(data)

	if not UI or not UI.PageValue then
		return
	end

	if Cyclopedia.Bestiary.Stage == STAGES.CATEGORY then
		Cyclopedia.Bestiary.Page = Cyclopedia.Bestiary.LastCategoryPage or Cyclopedia.Bestiary.Page or 1
	end

	UI.PageValue:setText(string.format("%d / %d", Cyclopedia.Bestiary.Page, Cyclopedia.Bestiary.TotalCategoriesPages))
	Cyclopedia.loadBestiaryCategory(Cyclopedia.Bestiary.Page)
	Cyclopedia.verifyBestiaryButtons()

	if Cyclopedia.Bestiary.Stage == STAGES.CATEGORY then
		scheduleEvent(focusBestiarySearchEdit, 0)
	end
end

function Cyclopedia.loadBestiaryCategory(page)
	if not UI then
		return
	end

	if not Cyclopedia.Bestiary.Categories[page] then
		return
	end

	UI.ListBase.CategoryList:destroyChildren()

	for _, data in ipairs(Cyclopedia.Bestiary.Categories[page]) do
		Cyclopedia.CreateBestiaryCategoryItem(data)
	end
end

function Cyclopedia.onStageChange()
	if not UI then
		return
	end

	if Cyclopedia.Bestiary.Stage == STAGES.CATEGORY then
		UI.BackPageButton:setEnabled(false)
		UI.ListBase.CategoryList:setVisible(true)
		UI.ListBase.CreatureList:setVisible(false)
		UI.ListBase.CreatureInfo:setVisible(false)

		if Cyclopedia.Bestiary.Categories and Cyclopedia.Bestiary.Categories[Cyclopedia.Bestiary.Page] then
			Cyclopedia.loadBestiaryCategory(Cyclopedia.Bestiary.Page)
		end
	end

	if Cyclopedia.Bestiary.Stage == STAGES.CREATURES then
		UI.BackPageButton:setEnabled(true)
		UI.ListBase.CategoryList:setVisible(false)
		UI.ListBase.CreatureList:setVisible(true)
		UI.ListBase.CreatureInfo:setVisible(false)

		if Cyclopedia.Bestiary.Creatures and Cyclopedia.Bestiary.Creatures[Cyclopedia.Bestiary.Page] then
			Cyclopedia.loadBestiaryCreature(Cyclopedia.Bestiary.Page, false)
		end

		function UI.BackPageButton.onClick()
			navigateBackFromCreaturesList()
		end
	end

	if Cyclopedia.Bestiary.Stage == STAGES.SEARCH then
		UI.BackPageButton:setEnabled(true)
		UI.ListBase.CategoryList:setVisible(false)
		UI.ListBase.CreatureList:setVisible(true)
		UI.ListBase.CreatureInfo:setVisible(false)

		if Cyclopedia.Bestiary.Search and Cyclopedia.Bestiary.Search[Cyclopedia.Bestiary.Page] then
			Cyclopedia.loadBestiaryCreature(Cyclopedia.Bestiary.Page, true)
		end

		function UI.BackPageButton.onClick()
			navigateBackFromSearch()
		end
	end

	if Cyclopedia.Bestiary.Stage == STAGES.CREATURE then
		UI.BackPageButton:setEnabled(true)
		UI.ListBase.CategoryList:setVisible(false)
		UI.ListBase.CreatureList:setVisible(false)
		UI.ListBase.CreatureInfo:setVisible(true)

		function UI.BackPageButton.onClick()
			navigateBackFromCreature()
		end
	end

	Cyclopedia.verifyBestiaryButtons()
	scheduleEvent(focusBestiarySearchEdit, 0)
end

function Cyclopedia.changeBestiaryPage(prev, next)
	if next then
		Cyclopedia.Bestiary.Page = Cyclopedia.Bestiary.Page + 1
	end

	if prev then
		Cyclopedia.Bestiary.Page = Cyclopedia.Bestiary.Page - 1
	end

	local stage = Cyclopedia.Bestiary.Stage

	if stage == STAGES.CATEGORY then
		Cyclopedia.loadBestiaryCategory(Cyclopedia.Bestiary.Page)
	elseif stage == STAGES.CREATURES then
		Cyclopedia.loadBestiaryCreature(Cyclopedia.Bestiary.Page, false)
	elseif stage == STAGES.SEARCH then
		Cyclopedia.loadBestiaryCreature(Cyclopedia.Bestiary.Page, true)
	end

	Cyclopedia.verifyBestiaryButtons()
	scheduleEvent(focusBestiarySearchEdit, 0)
end

function Cyclopedia.verifyBestiaryButtons()
	if not UI then
		return
	end

	local function updateButtonState(button, condition)
		if condition then
			button:enable()
		else
			button:disable()
		end
	end

	local function updatePageValue(currentPage, totalPages)
		UI.PageValue:setText(string.format("%d / %d", currentPage, totalPages))
	end

	updateButtonState(UI.SearchButton, UI.SearchEdit:getText() ~= "")

	local stage = Cyclopedia.Bestiary.Stage
	local totalSearchPages = Cyclopedia.Bestiary.TotalSearchPages
	local page = Cyclopedia.Bestiary.Page

	if stage == STAGES.SEARCH and totalSearchPages then
		local totalPages = totalSearchPages

		updateButtonState(UI.PrevPageButton, page > 1)
		updateButtonState(UI.NextPageButton, page < totalPages)
		updatePageValue(page, totalPages)

		return
	end

	if stage == STAGES.CREATURE then
		UI.PrevPageButton:disable()
		UI.NextPageButton:disable()
		updatePageValue(1, 1)

		return
	end

	local totalCategoriesPages = Cyclopedia.Bestiary.TotalCategoriesPages
	local totalCreaturesPages = Cyclopedia.Bestiary.TotalCreaturesPages

	if stage == STAGES.CATEGORY and totalCategoriesPages or stage == STAGES.CREATURES and totalCreaturesPages then
		local totalPages = stage == STAGES.CATEGORY and totalCategoriesPages or totalCreaturesPages

		updateButtonState(UI.PrevPageButton, page > 1)
		updateButtonState(UI.NextPageButton, page < totalPages)
		updatePageValue(page, totalPages)
	end
end

local TRACKER_TYPE_BESTIARY = 0
local TRACKER_TYPE_BOSSTIARY = 1

local function trackerDataCount(data)
	if not data or type(data) ~= "table" then
		return 0
	end

	local count = #data

	if count > 0 then
		return count
	end

	for _ in pairs(data) do
		count = count + 1
	end

	return count
end

local function normalizeTrackerEntry(entry)
	if type(entry) ~= "table" then
		return nil
	end

	return {
		tonumber(entry[1]) or entry[1],
		tonumber(entry[2]) or 0,
		tonumber(entry[3]) or 0,
		tonumber(entry[4]) or 0,
		tonumber(entry[5]) or 0,
		entry[6]
	}
end

local function normalizeTrackerData(data)
	if not data or type(data) ~= "table" then
		return {}
	end

	local normalized = {}

	for _, entry in ipairs(data) do
		local row = normalizeTrackerEntry(entry)

		if row and row[1] then
			normalized[#normalized + 1] = row
		end
	end

	if #normalized == 0 then
		for _, entry in pairs(data) do
			if type(entry) == "table" then
				local row = normalizeTrackerEntry(entry)

				if row and row[1] then
					normalized[#normalized + 1] = row
				end
			end
		end
	end

	return normalized
end

local function getTrackerWindow(trackerType)
	if trackerType == TRACKER_TYPE_BOSSTIARY then
		return trackerMiniWindowBosstiary
	end

	return trackerMiniWindow
end

local function getStoredTrackerData(trackerType)
	if trackerType == TRACKER_TYPE_BOSSTIARY then
		return Cyclopedia.storedBosstiaryTrackerData
	end

	return Cyclopedia.storedTrackerData
end

local function setStoredTrackerData(trackerType, data)
	if trackerType == TRACKER_TYPE_BOSSTIARY then
		Cyclopedia.storedBosstiaryTrackerData = data
	else
		Cyclopedia.storedTrackerData = data
	end
end

function Cyclopedia.clearTrackerDataForCharacterChange()
	Cyclopedia.storedTrackerData = {}
	Cyclopedia.storedBosstiaryTrackerData = {}
	storedRaceIDs = {}

	if trackerMiniWindow and trackerMiniWindow.contentsPanel then
		trackerMiniWindow.contentsPanel:destroyChildren()
	end

	if trackerMiniWindowBosstiary and trackerMiniWindowBosstiary.contentsPanel then
		trackerMiniWindowBosstiary.contentsPanel:destroyChildren()
	end
end

function Cyclopedia.ensureStoredRaceIDsPopulated()
	if storedRaceIDs and #storedRaceIDs > 0 then
		return
	end

	if not Cyclopedia.storedTrackerData or trackerDataCount(Cyclopedia.storedTrackerData) == 0 then
		return
	end

	storedRaceIDs = {}

	for _, entry in ipairs(Cyclopedia.storedTrackerData) do
		table.insert(storedRaceIDs, entry[1])
	end
end

function Cyclopedia.applyStoredTracker(trackerType)
	local data = getStoredTrackerData(trackerType)

	if data then
		Cyclopedia.onParseCyclopediaTracker(trackerType, data)
	end
end

function Cyclopedia.removeFromTracker(trackerType, raceId)
	raceId = tonumber(raceId)

	if not raceId then
		return
	end

	local isBoss = trackerType == TRACKER_TYPE_BOSSTIARY
	local data = normalizeTrackerData(getStoredTrackerData(trackerType))
	local filtered = {}

	for _, entry in ipairs(data) do
		if tonumber(entry[1]) ~= raceId then
			filtered[#filtered + 1] = entry
		end
	end

	if isBoss then
		Cyclopedia._bosstiaryTrackerOverrides = Cyclopedia._bosstiaryTrackerOverrides or {}
		Cyclopedia._bosstiaryTrackerOverrides[raceId] = 0

		if Cyclopedia.Bosstiary and Cyclopedia.Bosstiary.Creatures then
			for _, page in pairs(Cyclopedia.Bosstiary.Creatures) do
				for _, creature in ipairs(page) do
					if creature.raceId == raceId then
						creature.isTrackerActived = 0
					end
				end
			end
		end
	else
		local info = getBestiaryCreatureInfo()

		if info and info.LeftBase and info.LeftBase.TrackCheck and tonumber(info.LeftBase.TrackCheck.raceId) == raceId then
			info.LeftBase.TrackCheck._suppressTrackCheckChange = true

			info.LeftBase.TrackCheck:setChecked(false)

			info.LeftBase.TrackCheck._suppressTrackCheckChange = false
		end
	end

	Cyclopedia.onParseCyclopediaTracker(trackerType, filtered)
end

function Cyclopedia.onBestiaryTrackCheckChange(widget, checked)
	if not widget or widget._suppressTrackCheckChange then
		return
	end

	local raceId = tonumber(widget.raceId)

	if not raceId then
		return
	end

	g_game.sendStatusTrackerBestiary(raceId, checked)

	if not checked then
		Cyclopedia.removeFromTracker(TRACKER_TYPE_BESTIARY, raceId)
	end
end

function Cyclopedia.onParseCyclopediaTracker(trackerType, data)
	if data == nil then
		return
	end

	data = normalizeTrackerData(data)

	local isBoss = trackerType == TRACKER_TYPE_BOSSTIARY
	local trackerTypeStr = isBoss and "bosstiary" or "bestiary"

	setStoredTrackerData(trackerType, data)

	if not isBoss then
		storedRaceIDs = {}

		for _, entry in ipairs(data) do
			table.insert(storedRaceIDs, entry[1])
		end
	end

	local window = getTrackerWindow(trackerType)

	if not window or window:isDestroyed() then
		return
	end

	window.contentsPanel:destroyChildren()

	if #data == 0 then
		return
	end

	data = Cyclopedia.sortTrackerData(data, trackerTypeStr)

	for _, entry in ipairs(data) do
		local raceId, kills, uno, dos, maxKills = unpack(entry)
		local raceData = g_things.getRaceData(raceId)

		if not raceData or not raceData.name then
			-- block empty
		else
			local widget = g_ui.createWidget("TrackerButton", window.contentsPanel)

			widget:setId(raceId)

			widget.trackerIsBoss = isBoss

			widget.creature:setOutfit(raceData.outfit)
			widget.creature:getCreature():setStaticWalking(1000)
			widget.label:setText(formatTrackerCreatureName(raceData.name, true))
			widget.kills:setText(kills)

			widget.onMouseRelease = onTrackerClick

			widget:setMarginLeft(0)
			widget.label:setColor("#C0C0C0")
			widget.label:setFont("verdana-11px-monochrome")
			widget.kills:setColor("#C0C0C0")
			widget.kills:setFont("verdana-11px-monochrome")
			widget.kills:raise()
			Cyclopedia.SetBestiaryProgress(50, widget.killsBar2, widget.ProgressBack33, widget.ProgressBack55, kills, uno, dos, maxKills, 49, 12)

			if widget.ProgressBorder1 then
				widget.ProgressBorder1:setTooltip(string.format("%d / %d", kills, uno))
			end

			if widget.ProgressBorder2 then
				widget.ProgressBorder2:setTooltip(string.format("%d / %d", kills, dos))
			end

			if widget.ProgressBorder3 then
				widget.ProgressBorder3:setTooltip(string.format("%d / %d", kills, maxKills))
			end
		end
	end
end

local function toggleTrackerWindow(trackerType, syncButtonFn)
	local window = getTrackerWindow(trackerType)
	local button = trackerType == TRACKER_TYPE_BOSSTIARY and trackerButtonBosstiary or trackerButton

	if not window or not button then
		return
	end

	if button:isOn() then
		window:closeAndForgetLayout()
	else
		if not window:getParent() then
			local panel = modules.game_interface.findContentPanelAvailable(window, window:getMinimumHeight())

			if not panel then
				return
			end

			panel:addChild(window)
		end

		Cyclopedia.applyStoredTracker(trackerType)
		window:open()
	end

	syncButtonFn()
end

function Cyclopedia.toggleBestiaryTracker()
	toggleTrackerWindow(TRACKER_TYPE_BESTIARY, Cyclopedia.syncBestiaryTrackerMainPanelButton)
end

function Cyclopedia.toggleBosstiaryTracker()
	toggleTrackerWindow(TRACKER_TYPE_BOSSTIARY, Cyclopedia.syncBosstiaryTrackerMainPanelButton)
end

function Cyclopedia.onTrackerClose(temp)
	return
end

function Cyclopedia.setBarPercent(widget, percent)
	if percent > 92 then
		widget.killsBar:setBackgroundColor("#00C000")
	elseif percent > 60 then
		widget.killsBar:setBackgroundColor("#60C060")
	elseif percent > 30 then
		widget.killsBar:setBackgroundColor("#C0C000")
	elseif percent > 8 then
		widget.killsBar:setBackgroundColor("#C03030")
	elseif percent > 3 then
		widget.killsBar:setBackgroundColor("#C00000")
	else
		widget.killsBar:setBackgroundColor("#600000")
	end

	widget.killsBar:setPercent(percent)
end

local BESTIATYTRACKER_FILTERS = {
	sortByKills = false,
	ShortByPercentage = false,
	sortByName = true,
	sortByDescending = false,
	sortByAscending = true
}
local BOSSTIARYTRACKER_FILTERS = {
	sortByKills = false,
	ShortByPercentage = false,
	sortByName = true,
	sortByDescending = false,
	sortByAscending = true
}

local function trackerSortSectionKey(trackerType)
	return trackerType == "bosstiary" and "bosstiaryTrackerWidgetOptions" or "bestiaryTrackerWidgetOptions"
end

local function filtersFromSortValues(sortKey, sortOrder)
	local filters = {
		sortByKills = false,
		ShortByPercentage = false,
		sortByName = false,
		sortByDescending = false,
		sortByAscending = false
	}

	if sortKey == "completion" then
		filters.ShortByPercentage = true
	elseif sortKey == "remaining" then
		filters.sortByKills = true
	else
		filters.sortByName = true
	end

	if sortOrder == "descending" then
		filters.sortByDescending = true
	else
		filters.sortByAscending = true
	end

	return filters
end

local function sortValuesFromFilters(filters)
	local sortKey = "name"

	if filters.ShortByPercentage then
		sortKey = "completion"
	elseif filters.sortByKills then
		sortKey = "remaining"
	end

	local sortOrder = filters.sortByDescending and "descending" or "ascending"

	return sortKey, sortOrder
end

local function writeTrackerSortToSection(trackerType, filters)
	if not SidebarPersistence or not SidebarPersistence.active then
		return
	end

	local document = SidebarPersistence.document

	if type(document) ~= "table" then
		return
	end

	local sectionKey = trackerSortSectionKey(trackerType)
	local section = document[sectionKey]

	if type(section) ~= "table" then
		section = {}
		document[sectionKey] = section
	end

	section.sortKey, section.sortOrder = sortValuesFromFilters(filters)
end

function Cyclopedia.loadTrackerFilters(trackerType)
	local defaultFilters = trackerType == "bosstiary" and BOSSTIARYTRACKER_FILTERS or BESTIATYTRACKER_FILTERS

	if not SidebarPersistence or not SidebarPersistence.getSection then
		return defaultFilters
	end

	local section = SidebarPersistence.getSection(trackerSortSectionKey(trackerType))

	if type(section) ~= "table" then
		return defaultFilters
	end

	return filtersFromSortValues(section.sortKey, section.sortOrder)
end

function Cyclopedia.saveTrackerFilters(trackerType)
	writeTrackerSortToSection(trackerType, Cyclopedia.loadTrackerFilters(trackerType))
end

function Cyclopedia.getTrackerFilter(trackerType, filter)
	return Cyclopedia.loadTrackerFilters(trackerType)[filter] or false
end

function Cyclopedia.setTrackerFilter(trackerType, filter, value)
	local filters = Cyclopedia.loadTrackerFilters(trackerType)

	if filter == "sortByName" or filter == "ShortByPercentage" or filter == "sortByKills" then
		filters.sortByName = false
		filters.ShortByPercentage = false
		filters.sortByKills = false
		filters[filter] = true
	elseif filter == "sortByAscending" or filter == "sortByDescending" then
		filters.sortByAscending = false
		filters.sortByDescending = false
		filters[filter] = true
	else
		filters[filter] = value
	end

	writeTrackerSortToSection(trackerType, filters)
	Cyclopedia.refreshTracker(trackerType)
end

function Cyclopedia.refreshTracker(trackerType)
	if trackerType == "bosstiary" then
		if trackerMiniWindowBosstiary and Cyclopedia.storedBosstiaryTrackerData then
			Cyclopedia.onParseCyclopediaTracker(1, Cyclopedia.storedBosstiaryTrackerData)
		end
	elseif trackerMiniWindow and Cyclopedia.storedTrackerData then
		Cyclopedia.onParseCyclopediaTracker(0, Cyclopedia.storedTrackerData)
	end
end

function Cyclopedia.sortTrackerData(data, trackerType)
	local filters = Cyclopedia.loadTrackerFilters(trackerType)
	local isDescending = filters.sortByDescending
	local sortedData = {}

	for i, v in ipairs(data) do
		sortedData[i] = v
	end

	if filters.sortByName then
		table.sort(sortedData, function(a, b)
			local nameA = g_things.getRaceData(a[1]).name:lower()
			local nameB = g_things.getRaceData(b[1]).name:lower()

			if isDescending then
				return nameB < nameA
			else
				return nameA < nameB
			end
		end)
	elseif filters.ShortByPercentage then
		table.sort(sortedData, function(a, b)
			local raceIdA, killsA, _, _, maxKillsA = unpack(a)
			local raceIdB, killsB, _, _, maxKillsB = unpack(b)
			local percentA = maxKillsA > 0 and killsA / maxKillsA * 100 or 0
			local percentB = maxKillsB > 0 and killsB / maxKillsB * 100 or 0

			if isDescending then
				return percentB < percentA
			else
				return percentA < percentB
			end
		end)
	elseif filters.sortByKills then
		table.sort(sortedData, function(a, b)
			local remainingA = a[5] - a[2]
			local remainingB = b[5] - b[2]

			if isDescending then
				return remainingB < remainingA
			else
				return remainingA < remainingB
			end
		end)
	else
		table.sort(sortedData, function(a, b)
			local nameA = g_things.getRaceData(a[1]).name:lower()
			local nameB = g_things.getRaceData(b[1]).name:lower()

			if isDescending then
				return nameB < nameA
			else
				return nameA < nameB
			end
		end)
	end

	return sortedData
end

function Cyclopedia.createTrackerContextMenu(trackerType, mousePos)
	local menu = g_ui.createWidget("bestiaryTrackerMenu")

	menu:setGameMenu(true)

	local shortCreature = UIRadioGroup.create()
	local shortAlphabets = UIRadioGroup.create()

	for i, choice in ipairs(menu:getChildren()) do
		if i >= 1 and i <= 3 then
			shortCreature:addWidget(choice)
		elseif i == 5 or i == 6 then
			shortAlphabets:addWidget(choice)
		end
	end

	local filters = Cyclopedia.loadTrackerFilters(trackerType)

	if filters.sortByName then
		menu:getChildById("sortByName"):setChecked(true)
	elseif filters.ShortByPercentage then
		menu:getChildById("ShortByPercentage"):setChecked(true)
	elseif filters.sortByKills then
		menu:getChildById("sortByKills"):setChecked(true)
	else
		menu:getChildById("sortByName"):setChecked(true)
	end

	if filters.sortByDescending then
		menu:getChildById("sortByDescending"):setChecked(true)
	else
		menu:getChildById("sortByAscending"):setChecked(true)
	end

	menu:getChildById("sortByName").onClick = function()
		Cyclopedia.setTrackerFilter(trackerType, "sortByName", true)
		menu:destroy()
	end
	menu:getChildById("ShortByPercentage").onClick = function()
		Cyclopedia.setTrackerFilter(trackerType, "ShortByPercentage", true)
		menu:destroy()
	end
	menu:getChildById("sortByKills").onClick = function()
		Cyclopedia.setTrackerFilter(trackerType, "sortByKills", true)
		menu:destroy()
	end
	menu:getChildById("sortByAscending").onClick = function()
		Cyclopedia.setTrackerFilter(trackerType, "sortByAscending", true)
		menu:destroy()
	end
	menu:getChildById("sortByDescending").onClick = function()
		Cyclopedia.setTrackerFilter(trackerType, "sortByDescending", true)
		menu:destroy()
	end

	menu:display(mousePos)

	return true
end

function Cyclopedia.loadBestiaryTrackerFilters()
	return Cyclopedia.loadTrackerFilters("bestiary")
end

function Cyclopedia.saveBestiaryTrackerFilters()
	return Cyclopedia.saveTrackerFilters("bestiary")
end

function Cyclopedia.getBestiaryTrackerFilter(filter)
	return Cyclopedia.getTrackerFilter("bestiary", filter)
end

function Cyclopedia.setBestiaryTrackerFilter(filter, value)
	return Cyclopedia.setTrackerFilter("bestiary", filter, value)
end

function test(index)
	trackerMiniWindow.contentsPanel:moveChildToIndex(trackerMiniWindow.contentsPanel:getLastChild(), index)
end

function onTrackerClick(widget, mousePosition, mouseButton)
	if mouseButton ~= MouseLeftButton and mouseButton ~= MouseRightButton then
		return false
	end

	local taskId = tonumber(widget:getId())

	if not taskId then
		return false
	end

	if mouseButton == MouseLeftButton then
		if widget.trackerIsBoss then
			Cyclopedia._pendingBosstiaryRaceId = taskId

			show("bosstiary")
		else
			show("bestiary")
			openCreatureDetail(taskId)
			g_game.requestBestiarySearch(taskId)
		end

		return true
	end

	local menu = g_ui.createWidget("PopupMenu")

	menu:setGameMenu(true)

	local creatureName = formatTrackerCreatureName(g_things.getRaceData(taskId).name, false)

	menu:addOption(tr("Stop tracking") .. " \"" .. creatureName .. "\"", function()
		g_game.sendStatusTrackerBestiary(taskId, false)

		local trackerType = widget.trackerIsBoss and TRACKER_TYPE_BOSSTIARY or TRACKER_TYPE_BESTIARY

		Cyclopedia.removeFromTracker(trackerType, taskId)
	end)
	menu:display(mousePosition)

	return true
end

function onAddLootClick(widget, mousePosition, mouseButton)
	local itemIcon = widget.item
	local itemId = itemIcon and itemIcon:getItemId() or widget.id or 0

	if mouseButton == MouseLeftButton then
		Cyclopedia._pendingBestiaryRaceId = Cyclopedia.Bestiary and Cyclopedia.Bestiary.SelectedRaceId or nil

		return Cyclopedia.openItemInCyclopedia(itemId)
	end

	if mouseButton ~= MouseRightButton then
		return false
	end

	if itemId <= 0 then
		return false
	end

	local quickLoot = modules.game_quickloot.QuickLoot
	local lootFilterValue = quickLoot.data.filter
	local menu = g_ui.createWidget("PopupMenu")

	menu:setGameMenu(true)

	if not quickLoot.lootExists(itemId, lootFilterValue) then
		menu:addOption("Add to Loot List", function()
			quickLoot.addLootList(itemId, lootFilterValue)
		end)
	else
		menu:addOption("Remove from Loot List", function()
			quickLoot.removeLootList(itemId, lootFilterValue)
		end)
	end

	menu:display(mousePosition)

	return true
end
