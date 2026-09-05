-- chunkname: @/game_prey/prey.lua

preyWindow = nil
preyButton = nil
preyWindowButton = nil
preyTracker = nil

local cyclopediaPreyCache = {}
local killTrackerHeightInitialized = false
local timeLeftRerrol = {}
local FREE_REROLL_MAX_SECONDS = 72000

local function getPreyButtonsRowWidgets(buttonsPanel)
	if not buttonsPanel then
		return nil, nil
	end

	local rowContainer = buttonsPanel.buttonsRow or buttonsPanel
	local buttonsEmpty = rowContainer.buttonsEmpty
	local buttonsFilled = rowContainer.buttonsFilled

	if not buttonsEmpty and not buttonsFilled then
		buttonsEmpty = buttonsPanel.buttonsEmpty
		buttonsFilled = buttonsPanel.buttonsFilled
	end

	return buttonsEmpty, buttonsFilled
end

local function getPreyButtonsRow(buttonsPanel, useFilled)
	if not buttonsPanel then
		return nil
	end

	local buttonsEmpty, buttonsFilled = getPreyButtonsRowWidgets(buttonsPanel)

	if buttonsEmpty or buttonsFilled then
		if useFilled == true then
			return buttonsFilled
		end

		if useFilled == false then
			return buttonsEmpty
		end

		if buttonsFilled and buttonsFilled:isVisible() then
			return buttonsFilled
		end

		return buttonsEmpty
	end

	return buttonsPanel
end

local function forEachPreyButtonsRow(buttonsPanel, callback)
	if not buttonsPanel then
		return
	end

	local buttonsEmpty, buttonsFilled = getPreyButtonsRowWidgets(buttonsPanel)

	if buttonsEmpty and buttonsFilled then
		callback(buttonsEmpty)
		callback(buttonsFilled)
	else
		callback(buttonsPanel)
	end
end

local function configurePreyButtonsPanel(buttonsPanel, useFilled)
	local buttonsEmpty, buttonsFilled = getPreyButtonsRowWidgets(buttonsPanel)

	if not buttonsEmpty or not buttonsFilled then
		return
	end

	buttonsEmpty:setVisible(not useFilled)
	buttonsFilled:setVisible(useFilled)
end

local creatureList = {}

function applyPreyCreaturePreview(spriteWidget)
	if not spriteWidget then
		return
	end

	spriteWidget:setCenter(true)
	spriteWidget:setFixedCreatureSize(true)
	spriteWidget:setBaseScale(true)
	spriteWidget:setIgnoreDisplacementShift(true)

	local creature = spriteWidget:getCreature()

	if creature then
		creature:setStaticWalking(0)
	end
end

local function buildCreatureMap(list)
	local map = {}

	for _, race in ipairs(list) do
		map[race.raceId] = race
	end

	return map
end

local onWildcardValueChange
local itemListMin = {}
local itemListMax = {}
local itemSize = {}
local maxFitItems = {}
local poolSize = {}
local itemsPool = {}
local currentRaces = {}
local currentSearchRaces = {}
local lastSelectedLabel = {}
local selectedMonster = {}
local updateRerollEvent, supportWindow, preyTrackerButton
local bankGold = 0
local inventoryGold = 0
local rerollPrice = 0
local bonusRerolls = 0

local function syncPreyGoldBalances()
	local player = g_game.getLocalPlayer()

	if not player then
		return
	end

	bankGold = player:getResourceBalance(ResourceBank) or 0
	inventoryGold = player:getResourceBalance(ResourceInventary) or 0
end

local function getPreyTotalGold()
	if getTotalMoney then
		return getTotalMoney()
	end

	local player = g_game.getLocalPlayer()

	if player and player.getTotalMoney then
		return player:getTotalMoney() or 0
	end

	syncPreyGoldBalances()

	return bankGold + inventoryGold
end

local function updatePreyGoldDisplay()
	if not preyWindow or preyWindow:isDestroyed() then
		return
	end

	syncPreyGoldBalances()

	local totalGold = getPreyTotalGold()
	local moneyTooltip = {}

	setStringColor(moneyTooltip, "Cash: " .. comma_value(inventoryGold), "#3f3f3f")
	setStringColor(moneyTooltip, " $", "#f7e6fe")
	setStringColor(moneyTooltip, "\nBank: " .. comma_value(bankGold), "#3f3f3f")
	setStringColor(moneyTooltip, " $", "#f7e6fe")
	preyWindow.gold.text:setTooltip(moneyTooltip)
	preyWindow.gold.text:setText(comma_value(totalGold))
end

local function refreshPreyGoldDisplay()
	if g_game.requestResource then
		g_game.requestResource(ResourceBank)
		g_game.requestResource(ResourceInventary)
	end

	syncPreyGoldBalances()
	updatePreyGoldDisplay()
end

local PREY_BONUS_DAMAGE_BOOST = 0
local PREY_BONUS_DAMAGE_REDUCTION = 1
local PREY_BONUS_XP_BONUS = 2
local PREY_BONUS_IMPROVED_LOOT = 3
local PREY_BONUS_NONE = 4
local PREY_ACTION_LISTREROLL = 0
local PREY_ACTION_BONUSREROLL = 1
local PREY_ACTION_MONSTERSELECTION = 2
local PREY_ACTION_REQUEST_ALL_MONSTERS = 3
local PREY_ACTION_LOCK_PREY = 5
local PREY_UNLOCK_STORE = 1
local SLOT_STATE_LOCKED = 0
local SLOT_STATE_INACTIVE = 1
local SLOT_STATE_ACTIVE = 2
local SLOT_STATE_SELECTION = 3
local SLOT_STATE_WILDCARD = 4
local WILDCARD_LABEL_HEIGHT = 16
local WILDCARD_VISIBLE_LABELS = 11

local function getWildcardMonsterList(wildcardPanel)
	if not wildcardPanel then
		return nil
	end

	return wildcardPanel:recursiveGetChildById("monsterList")
end

local preyDescription = {}
local searchFilterText = ""
local PREY_STAR_EMPTY = ";"
local PREY_STAR_FILLED = "^"

local function buildStarBonusString(grade)
	grade = grade or 0

	local starBonus = ""

	for i = 1, 10 do
		if i <= grade then
			starBonus = starBonus .. PREY_STAR_FILLED
		else
			starBonus = starBonus .. PREY_STAR_EMPTY
		end
	end

	return starBonus
end

function bonusDescription(bonusType, bonusValue, bonusGrade)
	if bonusType == PREY_BONUS_DAMAGE_BOOST then
		return "Damage bonus (" .. bonusGrade .. "/10)"
	elseif bonusType == PREY_BONUS_DAMAGE_REDUCTION then
		return "Damage reduction bonus (" .. bonusGrade .. "/10)"
	elseif bonusType == PREY_BONUS_XP_BONUS then
		return "XP bonus (" .. bonusGrade .. "/10)"
	elseif bonusType == PREY_BONUS_IMPROVED_LOOT then
		return "Loot bonus (" .. bonusGrade .. "/10)"
	elseif bonusType == PREY_BONUS_DAMAGE_BOOST then
		return "-"
	end

	return "Uknown bonus"
end

function bonusTypeTranslate(bonusType)
	if bonusType == PREY_BONUS_DAMAGE_BOOST then
		return "Damage Boost"
	elseif bonusType == PREY_BONUS_DAMAGE_REDUCTION then
		return "Damage Reduction"
	elseif bonusType == PREY_BONUS_XP_BONUS then
		return "Bonus XP"
	elseif bonusType == PREY_BONUS_IMPROVED_LOOT then
		return "Improved Loot"
	end

	return "None"
end

function bonusTypeTranslateText(bonusType, percent)
	local text = "No active bonus."

	if bonusType == PREY_BONUS_DAMAGE_BOOST then
		text = tr("You deal +%s%s extra damage against your prey creature.", percent, "%")
	elseif bonusType == PREY_BONUS_DAMAGE_REDUCTION then
		text = tr("You take %s%s less damage from your prey creature.", percent, "%")
	elseif bonusType == PREY_BONUS_XP_BONUS then
		text = tr("Killing you prey creature rewards +%s%s extra XP.", percent, "%")
	elseif bonusType == PREY_BONUS_IMPROVED_LOOT then
		text = tr("Your prey creature has a +%s%s chance do drop additional loot.", percent, "%")
	end

	return text
end

local function formatRerollPrice(price, abbrevThreshold)
	if price < (abbrevThreshold or 100000) then
		return comma_value(price)
	end

	return math.floor(price / 1000) .. " k"
end

local function getRerollTimerLabel(timeWidget)
	return timeWidget:getChildById("textLabel") or timeWidget
end

local function setRerollTimerText(timeWidget, text)
	getRerollTimerLabel(timeWidget):setText(text)
end

local function getRerollTimerText(timeWidget)
	return getRerollTimerLabel(timeWidget):getText()
end

local function getFreeRerollSecondsLeft(slot)
	local data = timeLeftRerrol[slot]

	if not data then
		return nil
	end

	local elapsed = os.time() - data.startTime
	local secondsLeft = data.secondsLeft

	if secondsLeft == nil and data.minutesLeft ~= nil then
		secondsLeft = data.minutesLeft * 60
	end

	if secondsLeft == nil then
		return nil
	end

	return math.max(0, secondsLeft - elapsed)
end

local function isFreeRerollAvailable(slot)
	local secondsLeft = getFreeRerollSecondsLeft(slot)

	if secondsLeft == nil then
		return false
	end

	return secondsLeft <= 0
end

local function setRerollPriceDisplay(pricePanel, isFree)
	if not pricePanel then
		return
	end

	local priceWidget = pricePanel.text
	local priceOffWidget = pricePanel.textOff

	if isFree then
		priceWidget:setText("0")
		priceWidget:setColor("#c0c0c0")
		priceOffWidget:setText(formatRerollPrice(rerollPrice, 10000))
		priceOffWidget:setVisible(true)
	else
		priceWidget:setText(formatRerollPrice(rerollPrice, 100000))
		priceWidget:setColor("#c0c0c0")
		priceOffWidget:setVisible(false)
	end
end

function timeleftTranslation(timeleft)
	if timeleft == 0 then
		return tr("Free")
	end

	local hours = math.floor(timeleft / 3600)
	local mins = math.floor(timeleft % 3600 / 60)

	return string.format("%02d:%02d", hours, mins)
end

function init()
	connect(g_game, {
		onGameStart = check,
		onGameEnd = onGameEnd,
		onResourceBalance = onResourceBalance,
		onPreyFreeRolls = onPreyFreeRolls,
		onPreyTimeLeft = onPreyTimeLeft,
		onPreyRerollPrice = onPreyRerollPrice,
		onPreyLocked = onPreyLocked,
		onPreyWildcard = onPreyWildcard,
		onPreyInactive = onPreyInactive,
		onPreyActive = onPreyActive,
		onPreySelection = onPreySelection,
		onPreyListSelection = onPreyListSelection,
		onPreySelectionChangeMonster = onPreySelectionChangeMonster
	})

	preyWindow = g_ui.displayUI("prey")

	preyWindow:hide()

	for i = 1, 3 do
		local slot = preyWindow["slot" .. i]

		if slot then
			configurePreyButtonsPanel(slot.active.buttonsPanel, true)
			configurePreyButtonsPanel(slot.inactive.buttonsPanel, false)
			configurePreyButtonsPanel(slot.select.buttonsPanel, false)
			bindNoCreatureInfoHover(slot.locked.noCreature)
			bindNoCreatureInfoHover(slot.inactive.inactivePanel)
		end
	end

	preyTracker = g_ui.createWidget("PreyTracker", modules.game_interface.getRightPanel())

	preyTracker:setup()
	preyTracker:setContentMinimumHeight(49)
	preyTracker:close()
	scheduleEvent(updateTrackerHeight, 0)

	preyWindowButton = preyWindow:recursiveGetChildById("preyWindowButton")

	if g_game.isOnline() then
		check()
	end

	Keybind.new("Dialogs", "Open Prey Dialog", "Ctrl+Y", "")
	Keybind.bind("Dialogs", "Open Prey Dialog", {
		{
			type = KEY_DOWN,
			callback = function()
				if not g_game.isOnline() or not g_game.getFeature(GamePrey) then
					return
				end

				toggle()
			end
		}
	}, modules.game_interface.getRootPanel())
end

local descriptionTable = {
	preyWindow = "",
	choosePreyButtonBonus = "Click on this button to confirm %s as your prey creature for the next 2 hours hunting time. You will benefit from the following bonus: %s",
	time = "You will get your next Free List Reroll in %s.\nYou get a Free List Reroll every 20 hours for each slot.",
	choosePreyButtonDisabled = "You still need to select a prey creature. Choose one by clicking on it. To confirm your choice, click on this button.",
	time_free = "Your next List Reroll is free of charge.\nYou get a Free List Reroll every 20 hours for each slot.",
	choosePreyButton = "Click on this button to confirm %s as your prey creature for the next 2 hours hunting time. The bonus for your prey will be selected randomly from one of the following: damage boost, damage reduction, bonus XP, improved loot.",
	preyCandidate = "Select a new prey creature for the next 2 hours hunting time.",
	rerollButtonDisabled = "You do not have enough gold to buy a List Reroll. You get a Free List Reroll every 20 hours for each prey slot. You can also purchase further List Rerolls. The gold for the purchase needs to be in your inventory or in your bank account.",
	rerollButtonBonus = "If you like to select another prey creature, click here to get a new list with 9 creatures to choose from.\nThe newly selected prey will be active for 2 hours hunting time again.\nYour current bonus %s will not be affected.",
	rerollButton = "Click here for a new list with 9 creatures to select a new prey creature from.\nThis prey will be active for the next 2 hours hunting time.\nThe bonus for your prey will be selected randomly from one of the following: damage boost, damage reduction, bonus XP, improved loot.",
	pickSpecificPreyDisabled = "You do not have enough Prey Wildcards to choose a creature directly from all possible creatures.",
	pickSpecificPreyDisabledStore = "Go to the Store to get more Prey Wildcards.",
	pickSpecificPreyBonus = "If you like to select another prey creature, click here to choose from all available creatures.\nThe newly selected prey will be active for 2 hours hunting time again.\nYour current bonus %s will not be affected.",
	pickSpecificPrey = "Click here to choose your new prey creature from all available prey creatures.\nThis prey will be active for the next 2 hours hunting time.\nThe bonus for your prey will be selected randomly from one of the following: damage boost, damage reduction, bonus XP, improved loot.",
	lockPreyCheckBeware = "Beware! Each time the Lock Prey is triggered, 5 of your Prey Wildcards _ will be consumed. If there are not enough Prey Wildcards _ left, this function will be deactivated.",
	selectPrey = "Click here to get a bonus with a higher value. The bonus for your prey will be selected randomly from one of the following: damage boost, damage reduction, bonus XP, improved loot. Your prey will be active for 2 hours hunting time again. Your prey creature will stay the same.",
	lockPreyCheckMain = "If you tick this option, you will lock your prey creature and prey bonus. This means whenever your prey is about to expire its hunting time is simply extended by another 2 hours.",
	noBonusIcon = "This prey is not available for your character yet.\nCheck the large blue button(s) to learn how to unlock this prey slot",
	autoRerollCheckBeware = "Beware! Each time the Automatic Bonus Reroll is triggered, 1 of your Prey Wildcards _ will be consumed. If there are not enough Prey Wildcards _ left, this function will be deactivated.",
	shopPermButton = "Go to the Store to purchase the Permanent Prey Slot. Once you have completed the purchase, you can activate a prey here, no matter if your character is on a free or a Premium account.",
	autoRerollCheckMain = "If you tick this option, you will automatically roll for a new prey bonus whenever your prey is about to expire. This will also extend the hunting time of your active prey creature for another 2 hours.",
	rerollBonus = "Click here to get a bonus with a higher value. The bonus for your prey will be selected randomly from one of the following: damage boost, damage reduction, bonus XP, improved loot. Your prey will be active for 2 hours hunting time again. Your prey creature will stay the same.",
	selectionList = "Select a new prey creature for the next 2 hours hunting time. You will benefit from the following bonus:"
}

local function slotHasDeterminedPreyBonus(bonusType, bonusValue, bonusGrade)
	if bonusType == nil or bonusType == PREY_BONUS_NONE then
		return false
	end

	if bonusType == 0 and (bonusValue or 0) == 0 and (bonusGrade or 0) == 0 then
		return false
	end

	return bonusType >= PREY_BONUS_DAMAGE_BOOST and bonusType <= PREY_BONUS_IMPROVED_LOOT
end

local function getChoosePreyCreatureName(preySlot)
	if not preySlot then
		return nil
	end

	if preySlot.wildcard:isVisible() then
		local wildcardMonsterList = getWildcardMonsterList(preySlot.wildcard)
		local focused = wildcardMonsterList and wildcardMonsterList:getFocusedChild()

		if focused then
			return focused:getText()
		end
	elseif preySlot.select:isVisible() then
		local focusedChild = preySlot.select.list:getFocusedChild()

		if focusedChild and focusedChild.creature then
			return focusedChild.creature:getTooltip()
		end
	end

	return nil
end

local function getPreyBonusLabel(bonusType, bonusValue)
	if bonusType == PREY_BONUS_XP_BONUS then
		return tr("+%s%% Bonus XP", bonusValue)
	end

	return tr("+%s%s %s", bonusValue, "%", getBonusDescription(bonusType))
end

local PREY_DESCRIPTION_DEFAULT_COLOR = "#c0c0c0"
local PREY_DESCRIPTION_LINK_COLOR = "#1872c3"
local PREY_DESCRIPTION_WARN_COLOR = "#d33c3c"
local PREY_DESCRIPTION_ICON_COLOR = "#ffffff"
local PREY_WILDCARD_ICON = "_"

local function formatPreyDescriptionWithInlineIcons(text, textColor, iconColor)
	if not text:find(PREY_WILDCARD_ICON, 1, true) then
		return "{" .. text .. ", " .. textColor .. "}"
	end

	iconColor = iconColor or PREY_DESCRIPTION_ICON_COLOR

	local parts = {}
	local pos = 1

	while pos <= #text do
		local iconPos = text:find(PREY_WILDCARD_ICON, pos, true)

		if not iconPos then
			local segment = text:sub(pos)

			if segment ~= "" then
				parts[#parts + 1] = "{" .. segment .. ", " .. textColor .. "}"
			end

			break
		end

		local before = text:sub(pos, iconPos - 1)

		if before ~= "" then
			parts[#parts + 1] = "{" .. before .. ", " .. textColor .. "}"
		end

		parts[#parts + 1] = "{" .. PREY_WILDCARD_ICON .. ", " .. iconColor .. "}"
		pos = iconPos + #PREY_WILDCARD_ICON
	end

	return table.concat(parts)
end

local function setPreyCheckboxWarnDescription(mainKey, bewareKey, lineBreak)
	local main = tr(descriptionTable[mainKey])
	local beware = tr(descriptionTable[bewareKey])

	preyWindow.description:setColoredText("{" .. main .. ", " .. PREY_DESCRIPTION_DEFAULT_COLOR .. "}" .. (lineBreak or "\n") .. formatPreyDescriptionWithInlineIcons(beware, PREY_DESCRIPTION_WARN_COLOR))
end

local function setPickSpecificPreyDisabledDescription()
	local storeLine = tr(descriptionTable.pickSpecificPreyDisabledStore)
	local restLine = tr(descriptionTable.pickSpecificPreyDisabled)

	preyWindow.description:setColoredText("{" .. storeLine .. ", " .. PREY_DESCRIPTION_LINK_COLOR .. "}\n{" .. restLine .. ", " .. PREY_DESCRIPTION_DEFAULT_COLOR .. "}")
end

local function getPreySlotFromWidget(widget)
	local current = widget

	while current do
		local widgetId = current:getId()

		if widgetId then
			local slotIndex = widgetId:match("^slot(%d)$")

			if slotIndex and preyWindow then
				return preyWindow[widgetId], tonumber(slotIndex) - 1
			end
		end

		current = current:getParent()
	end

	return nil, nil
end

function onHover(widget)
	if type(widget) == "string" then
		return preyWindow.description:setText(descriptionTable[widget])
	elseif type(widget) == "number" then
		local preySlot = preyWindow["slot" .. widget + 1]

		if not preySlot or not preySlot.active:isVisible() then
			return
		end

		local creatureAndBonus = preySlot.active.creatureAndBonus
		local preyName = preySlot.title:getText()
		local timeleft = timeleftTranslation(preySlot.timeLeft)
		local typeDesc = bonusTypeTranslate(preySlot.bonusType)
		local bonusDescription = bonusTypeTranslateText(preySlot.bonusType, preySlot.bonusValue)
		local starBonus = buildStarBonusString(preySlot.bonusGrade)
		local text = tr("Creature: %s\nDuration: %s\nValue: %s\nType: %s\n%s", preyName, timeleft, starBonus, typeDesc, bonusDescription)

		return preyWindow.description:setText(text)
	end

	if not widget:isVisible() then
		return false
	end

	local id = widget:getId()

	if id == "autoRerollCheck" then
		setPreyCheckboxWarnDescription("autoRerollCheckMain", "autoRerollCheckBeware", "\n\n")

		return
	elseif id == "lockPreyCheck" then
		setPreyCheckboxWarnDescription("lockPreyCheckMain", "lockPreyCheckBeware", "\n\n")

		return
	end

	local desc = descriptionTable[id]

	if not desc then
		return
	end

	if id == "choosePreyButton" then
		if not widget:isOn() or widget:getActionId() == 0 then
			desc = descriptionTable.choosePreyButtonDisabled
		else
			local preySlot = preyWindow["slot" .. widget:getActionId()]
			local creatureName = getChoosePreyCreatureName(preySlot)

			if creatureName then
				if slotHasDeterminedPreyBonus(preySlot.bonusType, preySlot.bonusValue, preySlot.bonusGrade) then
					local bonusDesc = getPreyBonusLabel(preySlot.bonusType, preySlot.bonusValue)

					desc = tr(descriptionTable.choosePreyButtonBonus, creatureName, bonusDesc)
				else
					desc = tr(descriptionTable.choosePreyButton, creatureName)
				end
			end
		end
	elseif id == "pickSpecificPrey" then
		local preySlot = getPreySlotFromWidget(widget)

		if not preySlot then
			return
		end

		if not widget:isOn() then
			setPickSpecificPreyDisabledDescription()

			return
		elseif slotHasDeterminedPreyBonus(preySlot.bonusType, preySlot.bonusValue, preySlot.bonusGrade) then
			local bonusDesc = getPreyBonusLabel(preySlot.bonusType, preySlot.bonusValue)

			desc = tr(descriptionTable.pickSpecificPreyBonus, bonusDesc)
		else
			desc = descriptionTable.pickSpecificPrey
		end
	elseif id == "rerollButton" then
		local preySlot, slotIndex = getPreySlotFromWidget(widget)

		if not preySlot then
			return
		end

		if not widget:isOn() and not isFreeRerollAvailable(slotIndex) then
			desc = descriptionTable.rerollButtonDisabled
		elseif slotHasDeterminedPreyBonus(preySlot.bonusType, preySlot.bonusValue, preySlot.bonusGrade) then
			local bonusDesc = getPreyBonusLabel(preySlot.bonusType, preySlot.bonusValue)

			desc = tr(descriptionTable.rerollButtonBonus, bonusDesc)
		else
			desc = descriptionTable.rerollButton
		end
	elseif id == "time" then
		local widgetText = getRerollTimerText(widget)

		if widgetText == tr("Free") or widgetText == "Free" then
			desc = descriptionTable.time_free
		else
			desc = tr(desc, getRerollTimerText(widget))
		end
	end

	preyWindow.description:setText(desc)
end

function onSpecialHover(widget, bonusType, bonusValue)
	local message = descriptionTable[widget]

	if widget == "selectionList" then
		if bonusType == PREY_BONUS_NONE then
			preyWindow.description:setText(descriptionTable.selectPrey)
		else
			message = tr("%s +%s%s %s", message, bonusValue, "%", getBonusDescription(bonusType))

			preyWindow.description:setText(message)
		end
	end
end

function terminate()
	Keybind.delete("Dialogs", "Open Prey Dialog")
	disconnect(g_game, {
		onGameStart = check,
		onGameEnd = hide,
		onResourceBalance = onResourceBalance,
		onPreyFreeRolls = onPreyFreeRolls,
		onPreyTimeLeft = onPreyTimeLeft,
		onPreyRerollPrice = onPreyRerollPrice,
		onPreyLocked = onPreyLocked,
		onPreyWildcard = onPreyWildcard,
		onPreyInactive = onPreyInactive,
		onPreyActive = onPreyActive,
		onPreySelection = onPreySelection,
		onPreyListSelection = onPreyListSelection,
		onPreySelectionChangeMonster = onPreySelectionChangeMonster
	})

	if preyButton then
		preyButton:destroy()
	end

	if preyTrackerButton then
		preyTrackerButton:destroy()
	end

	if g_modalManager then
		g_modalManager.hide(preyWindow)
	end

	preyWindow:destroy()
	preyTracker:destroy()

	if supportWindow then
		supportWindow:destroy()

		supportWindow = nil
	end
end

function setUnsupportedSettings()
	local t = {
		"slot1",
		"slot2",
		"slot3"
	}

	for i, slot in ipairs(t) do
		local panel = preyWindow[slot]
		-- Capture a stable value for callbacks. Using the loop variable `i`
		-- directly makes every delayed click target the last slot (slot 3).
		local slotIndex = i - 1

		for j, state in pairs({
			panel.active,
			panel.inactive,
			panel.select
		}) do
			local useFilled = state == panel.active
			local row = getPreyButtonsRow(state.buttonsPanel, useFilled)

			if row then
				row.select.price.text:setText("5")
				row.select.button.pickSpecificPrey:setOn(true)
				row.select.price.text:setColor("#c0c0c0")

				if bonusRerolls < 5 then
					row.select.price.text:setColor("#d33c3c")
					row.select.button.pickSpecificPrey:setOn(false)
				end

				function row.select.button.pickSpecificPrey.onClick()
					if not row.select.button.pickSpecificPrey:isOn() then
						return
					end

					if bonusRerolls - 5 < 0 then
						return
					end

					onConfirmUsingWildcard(slotIndex, 5, PREY_ACTION_REQUEST_ALL_MONSTERS)
				end

				local preySlot = slotIndex
				local rerollPricePanel = row.reroll.price

				setRerollPriceDisplay(rerollPricePanel, isFreeRerollAvailable(preySlot))
				row.reroll.button.rerollButton:setOn(true)

				if getPreyTotalGold() < rerollPrice and not isFreeRerollAvailable(preySlot) then
					rerollPricePanel.text:setColor("#d33c3c")
					row.reroll.button.rerollButton:setOn(false)
				end

				local progressBar = row.reroll.button.time

				progressBar:setPercent(progressBar:getPercent())
			end
		end

		local activeRow = getPreyButtonsRow(panel.active.buttonsPanel, true)

		if activeRow and activeRow.choose then
			activeRow.choose.price.text:setText("1")
			activeRow.choose.price.text:setColor("#c0c0c0")
			activeRow.choose.button.rerollBonus:setOn(true)

			function activeRow.choose.button.rerollBonus.onClick()
				if not activeRow.choose.button.rerollBonus:isOn() then
					return
				end

				onConfirmUsingWildcard(slotIndex, 1, PREY_ACTION_BONUSREROLL)
			end

			if bonusRerolls < 1 then
				activeRow.choose.price.text:setColor("#d33c3c")
				activeRow.choose.button.rerollBonus:setOn(false)
			end
		end

		for k, state in pairs({
			panel.active,
			panel.inactive
		}) do
			state.buttonsPanel.autoRerollPrice.text:setText("1")
			state.buttonsPanel.autoRerollPrice.text:setColor("#c0c0c0")

			if bonusRerolls < 1 then
				state.buttonsPanel.autoRerollPrice.text:setColor("#d33c3c")
			end

			state.buttonsPanel.lockPreyPrice.text:setText("5")
			state.buttonsPanel.lockPreyPrice.text:setColor("#c0c0c0")

			if bonusRerolls < 5 then
				state.buttonsPanel.lockPreyPrice.text:setColor("#d33c3c")
			end

			function state.buttonsPanel.autoReroll.autoRerollCheck.onClick()
				if state.buttonsPanel.autoReroll.autoRerollCheck:isChecked() then
					g_game.preyAction(slotIndex, PREY_ACTION_LOCK_PREY, 0)
				else
					onEnableAutoReroll(slotIndex)
				end
			end

			function state.buttonsPanel.lockPrey.lockPreyCheck.onClick()
				if state.buttonsPanel.lockPrey.lockPreyCheck:isChecked() then
					g_game.preyAction(slotIndex, PREY_ACTION_LOCK_PREY, 0)
				else
					onEnableLockPrey(slotIndex)
				end
			end

			state.buttonsPanel.autoReroll.autoRerollCheck:setChecked(false)
			state.buttonsPanel.lockPrey.lockPreyCheck:setChecked(false)

			if panel.lockType == 1 then
				state.buttonsPanel.autoReroll.autoRerollCheck:setChecked(true)
			elseif panel.lockType == 2 then
				state.buttonsPanel.lockPrey.lockPreyCheck:setChecked(true)
			end
		end
	end
end

local function syncPreyTrackerButton()
	if not preyTrackerButton or preyTrackerButton:isDestroyed() then
		return
	end

	local on = false

	if preyTracker and not preyTracker:isDestroyed() then
		on = preyTracker:isVisible()
	end

	preyTrackerButton:setOn(on)

	if preyTrackerButton.setTooltip then
		preyTrackerButton:setTooltip(tr(on and "Close Kill Tracker Window" or "Open Kill Tracker Window"))
	end
end

function onPreyTrackerWindowOpen()
	syncPreyTrackerButton()

	if modules.game_taskboard and modules.game_taskboard.TaskBoard and modules.game_taskboard.TaskBoard.BountyTask then
		local bounty = modules.game_taskboard.TaskBoard.BountyTask

		if bounty.refreshKillTracker then
			bounty.refreshKillTracker()
		end

		if bounty.requestTrackerData then
			bounty.requestTrackerData()
		end
	end
end

function onPreyTrackerWindowClose()
	syncPreyTrackerButton()
end

function check()
	creatureList = buildCreatureMap(g_things.getMonsterList())

	if g_game.getFeature(GamePrey) then
		if not preyButton then
			preyButton = modules.client_topmenu.addRightGameToggleButton("preyButton", tr("Open Prey Dialog"), "/images/options/button_prey_dialog", toggle)
		end

		if not preyTrackerButton then
			preyTrackerButton = modules.client_topmenu.addRightGameToggleButton("preyTrackerButton", tr("Open Kill Tracker Window"), "/images/options/button_kill_tracker", toggleTracker)
		end

		if preyTracker then
			preyTracker:setupOnStart()
			scheduleEvent(updateTrackerHeight, 0)
		end

		syncPreyTrackerButton()
		scheduleEvent(syncPreyTrackerButton, 100)
		scheduleEvent(refreshPreyGoldDisplay, 0)
	elseif preyButton then
		preyButton:destroy()

		preyButton = nil
	end
end

function toggleTracker()
	if preyTracker:isVisible() then
		preyTracker:closeAndForgetLayout()
	else
		local parent = preyTracker:getParent()
		local root = g_ui.getRootWidget()
		local docked = parent and parent ~= root and parent:getClassName() == "UIMiniWindowContainer"

		if not docked then
			local panel = modules.game_interface.findContentPanelAvailable(preyTracker, preyTracker:getMinimumHeight())

			if not panel then
				return
			end

			panel:addChild(preyTracker)
		end

		preyTracker:open()
		preyTracker:getParent():moveChildToIndex(preyTracker, #preyTracker:getParent():getChildren())
	end

	syncPreyTrackerButton()
end

function onGameEnd()
	preyWindow.slot3.lockType = nil

	hide()
end

function hide(ignoreTracker)
	creatureList = nil

	if g_modalManager then
		g_modalManager.hide(preyWindow)
	end

	preyWindow:hide()

	if not ignoreTracker then
		preyTracker:close(true)
	end

	preyWindowButton:setChecked(false)

	if supportWindow then
		supportWindow:destroy()

		supportWindow = nil
	end

	if updateRerollEvent then
		removeEvent(updateRerollEvent)

		updateRerollEvent = nil
	end
end

local function restorePreyWindowFocus()
	preyWindow:show(true)

	if g_modalManager then
		g_modalManager.show(preyWindow)
	end

	preyWindow:raise()
	preyWindow:focus()
end

function show(position)
	preyWindowButton:setChecked(true)
	preyWindow:show(true)

	if g_modalManager then
		g_modalManager.show(preyWindow)
	end

	preyWindow:raise()
	preyWindow:focus()

	if position ~= nil then
		preyWindow:setPosition(position)
	end

	refreshPreyGoldDisplay()
	setUnsupportedSettings()

	local localPlayer = g_game.getLocalPlayer()

	if localPlayer then
		onResourceBalance(ResourcePreyBonus, localPlayer:getResourceBalance(ResourcePreyBonus))
	end

	if creatureList == nil then
		creatureList = buildCreatureMap(g_things.getMonsterList())
	end

	updateWildCardWindow()

	updateRerollEvent = cycleEvent(function()
		updateRerollTime()
	end, 1000)
end

function toggle()
	if preyWindow:isVisible() then
		return hide(true)
	end

	show()
end

function onPreyFreeRolls(slot, timeleftMinutes)
	local prey = preyWindow["slot" .. slot + 1]

	if not prey then
		return
	end

	local timeleftSeconds = timeleftMinutes * 60
	local percent = timeleftSeconds / FREE_REROLL_MAX_SECONDS * 100
	local desc = timeleftTranslation(timeleftSeconds)

	timeLeftRerrol[slot] = {
		secondsLeft = timeleftSeconds,
		startTime = os.time()
	}

	for i, panel in pairs({
		prey.active,
		prey.inactive
	}) do
		forEachPreyButtonsRow(panel.buttonsPanel, function(row)
			local progressBar = row.reroll.button.time

			setRerollTimerText(progressBar, desc)
			setRerollPriceDisplay(row.reroll.price, timeleftSeconds <= 0)
			progressBar:setPercent(percent)
		end)
	end
end

function onPreyTimeLeft(slot, timeLeft)
	preyDescription[slot] = preyDescription[slot] or {
		two = "",
		one = ""
	}

	local text = preyDescription[slot].one .. timeleftTranslation(timeLeft) .. preyDescription[slot].two
	local slotKey = "slot" .. slot + 1
	local percent = timeLeft / 7200 * 100

	if preyTracker and not preyTracker:isDestroyed() and preyTracker.contentsPanel then
		local preyTrackerSlot = preyTracker.contentsPanel[slotKey]

		if preyTrackerSlot then
			local tipStr = preyTrackerSlot:getTooltip()

			if type(tipStr) ~= "string" then
				tipStr = ""
			end

			local durLine = timeleftTranslation(timeLeft)
			local replacement = "Duration: " .. durLine .. "\n"
			local updatedTime

			if tipStr == "" then
				updatedTime = replacement
			else
				updatedTime = string.gsub(tipStr, "[^\n]*Duration: [^\n]*\n?", replacement)

				if updatedTime == tipStr and not string.find(tipStr, "Duration:", 1, true) then
					updatedTime = tipStr .. (string.sub(tipStr, -1) == "\n" and "" or "\n") .. replacement
				end
			end

			preyTrackerSlot:setTooltip(updatedTime)
		end

		local tracker = preyTracker.contentsPanel[slotKey]

		if tracker and tracker.time then
			tracker.time:setPercent(percent)

			for i, element in pairs({
				tracker.creatureName,
				tracker.creature,
				tracker.preyType,
				tracker.time
			}) do
				if element then
					element:setTooltip(text)

					function element.onClick()
						show()
					end
				end
			end
		end
	end

	if not preyWindow or preyWindow:isDestroyed() then
		return
	end

	local prey = preyWindow[slotKey]

	if not prey then
		return
	end

	local progressbar = prey.active.creatureAndBonus.timeLeft
	local textLabel = prey.active.creatureAndBonus.textLabel
	local desc = timeleftTranslation(timeLeft, true)

	textLabel:setText(desc)
	progressbar:setPercent(percent)

	prey.timeLeft = timeLeft

	if cyclopediaPreyCache[slot] then
		cyclopediaPreyCache[slot].timeLeft = timeLeft
	end
end

function onPreyRerollPrice(price, wildcardPrice, selectDirectPrice)
	rerollPrice = price

	for slotIndex = 0, 2 do
		local panel = preyWindow["slot" .. slotIndex + 1]

		if panel then
			local isFree = isFreeRerollAvailable(slotIndex)

			for j, state in pairs({
				panel.active,
				panel.inactive,
				panel.select
			}) do
				if state.buttonsPanel then
					forEachPreyButtonsRow(state.buttonsPanel, function(row)
						if row.reroll then
							setRerollPriceDisplay(row.reroll.price, isFree)
						end

						if selectDirectPrice and row.select then
							row.select.price.text:setText(tostring(selectDirectPrice))
						end
					end)
				end
			end
		end
	end

	setUnsupportedSettings()
end

function setTimeUntilFreeReroll(slot, timeUntilFreeRerollSeconds)
	-- the server computes (freeRerollTimeStamp - now)/1000 as u32: when the time has already passed, the difference is
	-- negative and wraps around to ~4.29e9 (hence "1191578:16"). We treat such values as 0.
	timeUntilFreeRerollSeconds = tonumber(timeUntilFreeRerollSeconds) or 0

	if timeUntilFreeRerollSeconds < 0 or timeUntilFreeRerollSeconds > FREE_REROLL_MAX_SECONDS then
		timeUntilFreeRerollSeconds = 0
	end

	timeLeftRerrol[slot] = {
		secondsLeft = timeUntilFreeRerollSeconds,
		startTime = os.time()
	}

	local prey = preyWindow["slot" .. slot + 1]

	if not prey then
		return
	end

	local percent = timeUntilFreeRerollSeconds / FREE_REROLL_MAX_SECONDS * 100
	local desc = timeleftTranslation(timeUntilFreeRerollSeconds)

	for i, panel in pairs({
		prey.active,
		prey.inactive,
		prey.select
	}) do
		forEachPreyButtonsRow(panel.buttonsPanel, function(row)
			local reroll = row.reroll.button.time

			reroll:setPercent(percent)
			setRerollTimerText(reroll, desc)
			setRerollPriceDisplay(row.reroll.price, timeUntilFreeRerollSeconds <= 0)

			function row.reroll.button.rerollButton.onClick()
				if not row.reroll.button.rerollButton:isOn() then
					return
				end

				onRerollButtonAction(slot, timeUntilFreeRerollSeconds <= 0)
			end
		end)
	end
end

function bindActivePreyInfoHover(slot)
	local prey = preyWindow["slot" .. slot + 1]

	if not prey or not prey.active or not prey.active.creatureAndBonus then
		return
	end

	local hoverPanel = prey.active.creatureAndBonus.activeInfoHover

	if not hoverPanel then
		return
	end

	hoverPanel:setVisible(true)
	hoverPanel:setEnabled(true)
	hoverPanel:raise()

	function hoverPanel.onHoverChange(hovered)
		if hovered then
			onHover(slot)
		end
	end
end

function bindNoCreatureInfoHover(noCreaturePanel)
	if not noCreaturePanel then
		return
	end

	local hoverPanel = noCreaturePanel.noCreatureInfoHover

	if not hoverPanel then
		return
	end

	hoverPanel:setVisible(true)
	hoverPanel:setEnabled(true)
	hoverPanel:raise()

	function hoverPanel.onHoverChange(hovered)
		if hovered then
			onHover("noBonusIcon")
		end
	end
end

function setBonusGradeStars(slot, grade)
	local prey = preyWindow["slot" .. slot + 1]
	local gradePanel = prey.active.creatureAndBonus.bonus.grade

	gradePanel:destroyChildren()

	for i = 1, 10 do
		if i <= grade then
			g_ui.createWidget("Star", gradePanel)
		else
			g_ui.createWidget("NoStar", gradePanel)
		end
	end
end

function getBigIconPath(bonusType)
	local path = "/images/game/prey/"

	if bonusType == PREY_BONUS_DAMAGE_BOOST then
		return path .. "prey-bonus-damage-boost"
	elseif bonusType == PREY_BONUS_DAMAGE_REDUCTION then
		return path .. "prey-bonus-damage-reduction"
	elseif bonusType == PREY_BONUS_XP_BONUS then
		return path .. "prey-bonus-improved-xp"
	elseif bonusType == PREY_BONUS_IMPROVED_LOOT then
		return path .. "prey-bonus-improved-loot"
	end
end

function getSmallIconPath(bonusType)
	local path = "/images/game/prey/"

	if bonusType == nil or bonusType == PREY_BONUS_NONE then
		return path .. "prey-bonus-none-small"
	end

	if bonusType == PREY_BONUS_DAMAGE_BOOST then
		return path .. "prey-bonus-damage-boost-small"
	elseif bonusType == PREY_BONUS_DAMAGE_REDUCTION then
		return path .. "prey-bonus-damage-reduction-small"
	elseif bonusType == PREY_BONUS_XP_BONUS then
		return path .. "prey-bonus-improved-xp-small"
	elseif bonusType == PREY_BONUS_IMPROVED_LOOT then
		return path .. "prey-bonus-improved-loot-small"
	end

	return path .. "prey-bonus-none-small"
end

function getExtendIcon(lockType)
	local path = "/images/game/prey/"
	local player = g_game.getLocalPlayer()

	if not player then
		return path .. "prey-auto-extend-disabled"
	end

	local balance = player:getResourceBalance(ResourcePreyBonus)

	if lockType == 1 then
		return balance < 1 and path .. "prey-auto-reroll-enabled-failing" or path .. "prey-auto-reroll-enabled"
	elseif lockType == 2 then
		return balance < 5 and path .. "prey-lock-prey-enabled-failing" or path .. "prey-lock-prey-enabled"
	end

	return path .. "prey-auto-extend-disabled"
end

function getBonusDescription(bonusType)
	if bonusType == PREY_BONUS_DAMAGE_BOOST then
		return "Damage Boost"
	elseif bonusType == PREY_BONUS_DAMAGE_REDUCTION then
		return "Damage Reduction"
	elseif bonusType == PREY_BONUS_XP_BONUS then
		return "XP Bonus"
	elseif bonusType == PREY_BONUS_IMPROVED_LOOT then
		return "Improved Loot"
	end

	return "None"
end

function getTooltipBonusDescription(bonusType, bonusValue)
	if bonusType == PREY_BONUS_DAMAGE_BOOST then
		return "You deal +" .. bonusValue .. "% extra damage against your prey creature."
	elseif bonusType == PREY_BONUS_DAMAGE_REDUCTION then
		return "You take " .. bonusValue .. "% less damage from your prey creature."
	elseif bonusType == PREY_BONUS_XP_BONUS then
		return "Killing your prey creature rewards +" .. bonusValue .. "% extra XP."
	elseif bonusType == PREY_BONUS_IMPROVED_LOOT then
		return "Your creature has a +" .. bonusValue .. "% chance to drop additional loot."
	end
end

function capitalFormatStr(str)
	local formatted = ""

	str = string.split(str, " ")

	for i, word in ipairs(str) do
		formatted = formatted .. " " .. string.gsub(word, "^%l", string.upper)
	end

	return formatted:trim()
end

local KILL_TRACKER_NAME_MAX_LEN = 14
local KILL_TRACKER_HEIGHT_PADDING = 23

function formatKillTrackerCreatureName(name)
	if not name or name == "" then
		return name or ""
	end

	name = name:gsub("^Selected:%s*", "")

	local formatted = name:gsub("(%a)([%w']*)", function(first, rest)
		return first:upper() .. rest:lower()
	end)

	if #formatted > KILL_TRACKER_NAME_MAX_LEN then
		return formatted:sub(1, KILL_TRACKER_NAME_MAX_LEN) .. "..."
	end

	return formatted
end

local function resetPreySelectionTitle(prey)
	prey.title:setText(tr("Select your prey creature"))
	prey.title:setTextAlign(AlignCenter)
	prey.title:setTextOffset("0 1")
end

local function clearPreySlotSelection(slot)
	local prey = preyWindow["slot" .. slot]

	if not prey or not prey.select:isVisible() then
		return
	end

	resetPreySelectionTitle(prey)

	local selectRow = getPreyButtonsRow(prey.select.buttonsPanel, false)
	local chooseButton = selectRow.choose.button.choosePreyButton

	chooseButton:setOn(false)
	chooseButton:setActionId(0)

	local list = prey.select.list

	for _, child in pairs(list:getChildren()) do
		child:setChecked(false)

		if child.highlight then
			child.highlight:setBackgroundColor("alpha")
		end

		child:setBorderWidth(1)
		child:setBorderColor("alpha")
	end
end

function onItemBoxChecked(widget, lastWidget, slot)
	if not widget then
		clearPreySlotSelection(slot)

		return
	end

	if lastWidget then
		lastWidget:setChecked(false)

		if lastWidget.highlight then
			lastWidget.highlight:setBackgroundColor("alpha")
		end

		lastWidget:setBorderWidth(1)
		lastWidget:setBorderColor("alpha")
	end

	if widget.creature then
		local name = tr("Selected: %s", widget.creature:getTooltip())

		preyWindow["slot" .. slot].title:setText(short_text(name, 28))
		preyWindow["slot" .. slot].title:setTextAlign(AlignLeft)
		preyWindow["slot" .. slot].title:setTextOffset(topoint("3 1"))

		local selectRow = getPreyButtonsRow(preyWindow["slot" .. slot].select.buttonsPanel, false)
		local chooseButton = selectRow.choose.button.choosePreyButton

		chooseButton:setOn(true)
		chooseButton:setActionId(slot)
	end

	if widget.highlight then
		widget.highlight:setBackgroundColor("white")
		widget:setChecked(true)
	end

	widget:setBorderWidth(1)
	widget:setBorderColor("white")
end

function onResourceBalance(resourceType, balance)
	if resourceType == ResourceBank then
		bankGold = balance
	elseif resourceType == ResourceInventary then
		inventoryGold = balance
	elseif resourceType == ResourcePreyBonus then
		bonusRerolls = balance

		preyWindow.wildCards.text:setText(bonusRerolls)
		setUnsupportedSettings()

		return
	end

	if resourceType == ResourceBank or resourceType == ResourceInventary then
		updatePreyGoldDisplay()
		setUnsupportedSettings()
	end
end

function onWildcardChange(prey, selected, lastSelected, slot)
	if not prey then
		return
	end

	if not selected then
		prey.wildcard.choose.button.choosePreyButton:setOn(false)
		prey.wildcard.choose.button.choosePreyButton:setActionId(0)

		lastSelectedLabel[slot] = nil
		selectedMonster[slot] = nil

		prey.title:setText("Select your prey creature")
		prey.wildcard.panel.creature:setOutfit({})
		applyPreyCreaturePreview(prey.wildcard.panel.creature)

		return
	end

	prey.wildcard.choose.button.choosePreyButton:setOn(true)
	prey.wildcard.choose.button.choosePreyButton:setActionId(string.match(prey:getId(), "%d+$"))
	selected:setBackgroundColor("#585858")

	if lastSelected then
		lastSelected:setBackgroundColor(lastSelected.background)
	end

	if lastSelectedLabel[slot] then
		lastSelectedLabel[slot]:setBackgroundColor(lastSelectedLabel[slot].background)
		lastSelectedLabel[slot]:setColor("#c0c0c0")
	end

	lastSelectedLabel[slot] = selected
	selectedMonster[slot] = tonumber(selected:getId())

	local creature = creatureList[selectedMonster[slot]]

	if not creature then
		return
	end

	prey.title:setText("Selected: " .. short_text(creature.name, 18))
	prey.wildcard.panel.creature:setOutfit(creature.outfit)
	applyPreyCreaturePreview(prey.wildcard.panel.creature)
end

function onTextEdit(widget)
	searchFilterText = widget:getText()

	updateSearchWildcard(widget:getParent():getParent())
end

function move(panel, height, minimized)
	preyTracker:setParent(panel)
	preyTracker:open()

	if minimized then
		preyTracker:setHeight(height)
		preyTracker:minimize()
	else
		preyTracker:maximize()
		preyTracker:setHeight(height)
	end

	return preyTracker
end

function isThirdSlotLocked()
	local preySlot = preyWindow.slot3
	local lockType = preySlot.lockType

	if lockType == nil then
		return true
	end

	if lockType ~= nil and lockType >= 0 then
		return false
	end

	return true
end

function updatePreyWidget(slot, state)
	local preyTrackerSlot = preyTracker.contentsPanel["slot" .. slot + 1]

	if state == SLOT_STATE_LOCKED then
		preyTrackerSlot:setVisible(false)
		updateTrackerHeight()

		return
	end

	local preySlot = preyWindow["slot" .. slot + 1]

	if slot == 2 then
		preyTrackerSlot:setVisible(true)
	end

	if state == SLOT_STATE_ACTIVE then
		local creatureAndBonus = preySlot.active.creatureAndBonus

		-- UICreature::getOutfit exists in C++ but is not exposed to Lua in this
		-- build. Reuse the outfit received in onPreyActive instead.
		if preySlot.currentHolderOutfit then
			preyTrackerSlot.creature:setOutfit(preySlot.currentHolderOutfit)
		end
		preyTrackerSlot.creature:getCreature():setStaticWalking(1000)
		preyTrackerSlot.creatureName:setText(formatKillTrackerCreatureName(preySlot.title:getText()))
		preyTrackerSlot.time:setPercent(creatureAndBonus.timeLeft:getPercent())
		preyTrackerSlot.preyType:setImageSource(getSmallIconPath(preySlot.bonusType))
		preyTrackerSlot.preyAutoExtend:setImageSource(getExtendIcon(preySlot.lockType))
		preyTrackerSlot.creature:show()
		preyTrackerSlot.noCreature:hide()

		local preyName = preySlot.title:getText()
		local timeleft = timeleftTranslation(preySlot.timeLeft)
		local typeDesc = bonusTypeTranslate(preySlot.bonusType)
		local lockType = preySlot.lockType or 0
		local extendedDesc

		if lockType == 1 then
			extendedDesc = tr("Automatic Bonus Reroll: enabled")
		elseif lockType == 2 then
			extendedDesc = tr("Lock Prey: enabled")
		else
			extendedDesc = tr("Automatic Extend Prey: disabled")
		end

		local bonusDescription = bonusTypeTranslateText(preySlot.bonusType, preySlot.bonusValue)
		local starBonus = buildStarBonusString(preySlot.bonusGrade)
		local text = "Creature: %s\nDuration: %s\nValue: %s\nType: %s\n%s\n%s\n\nClick in this window to open the prey dialog."

		preyTrackerSlot:setTooltip(tr(text, preyName, timeleft, starBonus, typeDesc, extendedDesc, bonusDescription))

		function preyTrackerSlot.onClick()
			show()
		end
	else
		preyTrackerSlot.creature:hide()
		preyTrackerSlot.noCreature:show()
		preyTrackerSlot.creatureName:setText("Inactive")
		preyTrackerSlot.time:setPercent(0)
		preyTrackerSlot.preyAutoExtend:setImageSource(getExtendIcon(preySlot.lockType))

		local trackerBonusType = PREY_BONUS_NONE

		if state == SLOT_STATE_SELECTION or state == SLOT_STATE_WILDCARD then
			local bt, bv, bg = preySlot.bonusType, preySlot.bonusValue, preySlot.bonusGrade

			if bt ~= nil and bt ~= PREY_BONUS_NONE and (bt ~= 0 or bv ~= 0 or bg ~= 0) then
				trackerBonusType = bt
			end
		end

		preyTrackerSlot.preyType:setImageSource(getSmallIconPath(trackerBonusType))
		preyTrackerSlot:setTooltip("Inactive Prey. \n\nUse the prey dialog to activate it. You can open the prey dialog by cliking in this window.")

		function preyTrackerSlot.onClick()
			show()
		end
	end

	updateTrackerHeight()
end

function onRerollButtonAction(slot, freeReroll)
	if supportWindow then
		return
	end

	preyWindow:hide()

	local function okFunc()
		g_game.preyAction(slot, PREY_ACTION_LISTREROLL, 0)
		supportWindow:destroy()

		supportWindow = nil

		restorePreyWindowFocus()
	end

	local function cancelFunc()
		supportWindow:destroy()

		supportWindow = nil

		restorePreyWindowFocus()
	end

	local confirmText = "Are you sure you want to use the Free List Reroll?"

	if not freeReroll then
		confirmText = tr("Do you want to spend %s gold for a List Reroll?\nYou currently have %s gold available for the purchase.", comma_value(rerollPrice), comma_value(getPreyTotalGold()))
	end

	supportWindow = displayGeneralBox(tr("Confirm of Using List Reroll"), confirmText, {
		{
			text = tr("No"),
			callback = cancelFunc
		},
		{
			text = tr("Yes"),
			callback = okFunc
		}
	}, okFunc, cancelFunc)
end

function onConfirmUsingWildcard(slot, price, action)
	if supportWindow then
		return
	end

	preyWindow:hide()

	local function okFunc()
		g_game.preyAction(slot, action, 0)
		supportWindow:destroy()

		supportWindow = nil

		restorePreyWindowFocus()
	end

	local function cancelFunc()
		supportWindow:destroy()

		supportWindow = nil

		restorePreyWindowFocus()
	end

	local confirmText = tr("Are you sure you want to use %s of your remaining %s Prey Wildcards?", price, bonusRerolls)

	supportWindow = displayGeneralBox(tr("Confirmation of Using Prey Wildcards"), confirmText, {
		{
			text = tr("No"),
			callback = cancelFunc
		},
		{
			text = tr("Yes"),
			callback = okFunc
		}
	}, okFunc, cancelFunc)
end

function onEnableAutoReroll(slot)
	if supportWindow then
		return
	end

	preyWindow:hide()

	local function okFunc()
		g_game.preyAction(slot, PREY_ACTION_LOCK_PREY, 1)
		supportWindow:destroy()

		supportWindow = nil

		restorePreyWindowFocus()
	end

	local function cancelFunc()
		supportWindow:destroy()

		supportWindow = nil

		restorePreyWindowFocus()
	end

	local confirmText = tr("Do you want to enable the Automatic Bonus Reroll?\nEach time the Automatic Bonus Reroll is triggered, 1 of your Prey Wildcards will be consumed.")

	supportWindow = displayGeneralBox(tr("Confirmation of Using Prey Wildcards"), confirmText, {
		{
			text = tr("No"),
			callback = cancelFunc
		},
		{
			text = tr("Yes"),
			callback = okFunc
		}
	}, okFunc, cancelFunc)
end

function onEnableLockPrey(slot)
	if supportWindow then
		return
	end

	preyWindow:hide()

	local function okFunc()
		g_game.preyAction(slot, PREY_ACTION_LOCK_PREY, 2)
		supportWindow:destroy()

		supportWindow = nil

		restorePreyWindowFocus()
	end

	local function cancelFunc()
		supportWindow:destroy()

		supportWindow = nil

		restorePreyWindowFocus()
	end

	local confirmText = tr("Do you want to enable the Lock Prey?\nEach time the Lock Prey is triggered, 5 of your Prey Wildcards will be consumed.")

	supportWindow = displayGeneralBox(tr("Confirmation of Using Prey Wildcards"), confirmText, {
		{
			text = tr("No"),
			callback = cancelFunc
		},
		{
			text = tr("Yes"),
			callback = okFunc
		}
	}, okFunc, cancelFunc)
end

function onPreyActive(slot, currentHolderName, currentHolderOutfit, bonusType, bonusValue, bonusGrade, timeLeft, timeUntilFreeReroll, lockType)
	local prey = preyWindow["slot" .. slot + 1]

	if not prey then
		return
	end

	local percent = timeLeft / 7200 * 100

	prey.inactive:hide()
	prey.locked:hide()
	prey.wildcard:hide()
	prey.select:hide()
	configurePreyButtonsPanel(prey.active.buttonsPanel, true)
	prey.active:show()
	prey.title:setText(capitalFormatStr(currentHolderName))
	prey.currentHolderOutfit = currentHolderOutfit

	local creatureAndBonus = prey.active.creatureAndBonus

	creatureAndBonus.creature:setOutfit(currentHolderOutfit)
	applyPreyCreaturePreview(creatureAndBonus.creature)
	setTimeUntilFreeReroll(slot, timeUntilFreeReroll)
	creatureAndBonus.bonus.icon:setImageSource(getBigIconPath(bonusType))
	setBonusGradeStars(slot, bonusGrade)
	bindActivePreyInfoHover(slot)
	creatureAndBonus.timeLeft:setPercent(percent)
	creatureAndBonus.textLabel:setText(timeleftTranslation(timeLeft))

	local activeRow = getPreyButtonsRow(prey.active.buttonsPanel, true)

	function activeRow.reroll.button.rerollButton.onClick()
		if not activeRow.reroll.button.rerollButton:isOn() then
			return
		end

		onRerollButtonAction(slot, timeUntilFreeReroll <= 0)
	end

	prey.bonusType = bonusType
	prey.bonusValue = bonusValue
	prey.bonusGrade = bonusGrade
	prey.lockType = lockType
	prey.timeLeft = timeLeft
	cyclopediaPreyCache[slot] = {
		name = capitalFormatStr(currentHolderName),
		bonusType = bonusType,
		bonusValue = bonusValue,
		timeLeft = timeLeft
	}

	setUnsupportedSettings()
	updatePreyWidget(slot, SLOT_STATE_ACTIVE)
end

-- signature matched to our C++ (protocolgameparse PREY_STATE_SELECTION):
-- (slot, names, outfits, nextFreeReroll, wildcards); bonuses are not sent in this state
function onPreySelection(slot, names, outfits, timeUntilFreeReroll, wildcards)
	local bonusType, bonusValue, bonusGrade, lockType = 0, 0, 0, nil
	local prey = preyWindow["slot" .. slot + 1]

	if not prey then
		return
	end

	prey.active:hide()
	prey.locked:hide()
	prey.wildcard:hide()
	prey.inactive:hide()
	configurePreyButtonsPanel(prey.select.buttonsPanel, false)
	prey.select:show()
	resetPreySelectionTitle(prey)

	local list = prey.select.list

	list:destroyChildren()

	local selectRow = getPreyButtonsRow(prey.select.buttonsPanel, false)
	local chooseButton = selectRow.choose.button.choosePreyButton

	chooseButton:setOn(false)
	chooseButton:setActionId(0)

	for i, name in ipairs(names) do
		local box = g_ui.createWidget("PreyCreatureBox", list)

		function box.onHoverChange()
			onSpecialHover("selectionList", bonusType, bonusValue)
		end

		function box.onClick()
			list:focusChild(box)
		end

		name = capitalFormatStr(name)

		box.creature:setTooltip(name)
		box.creature:setOutfit(outfits[i])
		applyPreyCreaturePreview(box.creature)
	end

	list:focusChild(nil)

	function list.onChildFocusChange(_, selected, lastSelected)
		if not selected then
			clearPreySlotSelection(slot + 1)

			return
		end

		onItemBoxChecked(selected, lastSelected, slot + 1)
	end

	function chooseButton.onClick()
		if not chooseButton:isOn() then
			return true
		end

		local focused = list:getFocusedChild()

		if not focused then
			return true
		end

		g_game.preyAction(slot, PREY_ACTION_MONSTERSELECTION, list:getChildIndex(focused) - 1)
	end

	function selectRow.reroll.button.rerollButton.onClick()
		if not selectRow.reroll.button.rerollButton:isOn() then
			return
		end

		onRerollButtonAction(slot, timeUntilFreeReroll <= 0)
	end

	prey.lockType = lockType

	if bonusType == 0 and bonusValue == 0 and bonusGrade == 0 then
		prey.bonusType = PREY_BONUS_NONE
	else
		prey.bonusType = bonusType
	end

	prey.bonusValue = bonusValue
	prey.bonusGrade = bonusGrade

	setTimeUntilFreeReroll(slot, timeUntilFreeReroll)
	setUnsupportedSettings()
	updatePreyWidget(slot, SLOT_STATE_SELECTION)
end

-- State 4 uses the same creature grid as the normal selection state, but
-- keeps the already rolled bonus. This event was parsed by C++ and never
-- connected by the Lua module, leaving the panel blank after a list reroll.
function onPreySelectionChangeMonster(slot, names, outfits, bonusType, bonusValue, bonusGrade, timeUntilFreeReroll, wildcards)
	onPreySelection(slot, names, outfits, timeUntilFreeReroll, wildcards)

	local prey = preyWindow and preyWindow["slot" .. slot + 1]
	if prey then
		prey.bonusType = bonusType
		prey.bonusValue = bonusValue
		prey.bonusGrade = bonusGrade
	end
end

function onPreyListSelection(slot, races, timeUntilFreeReroll, wildcards)
	-- The server sends the complete creature list in this state after the player
	-- spends wildcards. Reuse the wildcard picker with no preselected bonus.
	return onPreyWildcard(slot, races, timeUntilFreeReroll, wildcards, 0, 0, 0)
end

function updateSearchWildcard(prey)
	local monsterList = getWildcardMonsterList(prey.wildcard)

	if not monsterList then
		return
	end

	monsterList:focusChild(nil)

	if searchFilterText == "" then
		updateWildCardWindow()

		return
	end

	local slot = tonumber(prey:getId():match("%d+")) - 1

	currentSearchRaces[slot] = {}

	for _, raceId in pairs(currentRaces[slot]) do
		local creature = creatureList[raceId]

		if creature then
			local searchFilterTextEscaped = string.searchEscape(searchFilterText:lower())

			if string.find(creature.name:lower(), searchFilterTextEscaped) then
				table.insert(currentSearchRaces[slot], raceId)
			end
		end
	end

	for i, monsterLabel in ipairs(itemsPool[slot]) do
		if i > #currentSearchRaces[slot] then
			monsterLabel:setBackgroundColor("alpha")
			monsterLabel:setText("")
			monsterLabel.icon:setVisible(false)
			monsterLabel:setFocusable(false)
		else
			local monsterInfo = currentSearchRaces[slot][i]
			local color = i % 2 == 1 and "#484848" or "#414141"

			monsterLabel:setFocusable(true)
			monsterLabel:setBackgroundColor(color)

			monsterLabel.background = color

			monsterLabel:setId(monsterInfo)
			monsterLabel:setColor("#c0c0c0")

			local creature = creatureList[monsterInfo]

			if creature then
				monsterLabel:setText(string.capitalize(creature.name))
			end

			monsterLabel.icon:setVisible(false)
			monsterLabel:setTextOffset("0 0")
		end
	end

	local scrollbar = prey.wildcard:recursiveGetChildById("monsterListScrollBar")

	scrollbar:setMinimum(itemListMin[slot])
	scrollbar:setMaximum(#currentSearchRaces[slot])

	function scrollbar:onValueChange(value, delta)
		onSearchValueChange(self, value, delta, slot)
	end
end

function onSearchValueChange(scrollbar, value, delta, slot)
	local prey = preyWindow["slot" .. slot + 1]

	if not prey then
		return
	end

	local monsterList = getWildcardMonsterList(prey.wildcard)

	if not monsterList then
		return
	end

	local startItem = math.max(itemListMin[slot], value)
	local endItem = startItem + maxFitItems[slot] - 1

	if endItem > #currentSearchRaces[slot] then
		endItem = #currentSearchRaces[slot]
		startItem = endItem - maxFitItems[slot] + 1
	end

	for i, monsterLabel in ipairs(itemsPool[slot]) do
		local itemId = value > 0 and startItem + i - 1 or startItem + i
		local monsterInfo = currentSearchRaces[slot][itemId]
		local color = itemId % 2 == 1 and "#484848" or "#414141"

		monsterLabel:setBackgroundColor(color)

		monsterLabel.background = color

		monsterLabel:setId(monsterInfo)
		monsterLabel:setColor("#c0c0c0")

		local creature = creatureList[monsterInfo]

		if not creature then
			-- block empty
		else
			if creature then
				monsterLabel:setText(string.capitalize(creature.name))
			end

			if selectedMonster[slot] == monsterInfo then
				monsterList:focusChild(monsterLabel)
				monsterLabel:setBackgroundColor("#585858")
				monsterLabel:setColor("#f4f4f4")

				lastSelectedLabel[slot] = monsterLabel
			end

			monsterLabel.icon:setVisible(false)
			monsterLabel:setTextOffset("0 0")
		end
	end
end

function onWildcardValueChange(_, value, _, slot)
	local prey = preyWindow["slot" .. slot + 1]

	if not prey then
		return
	end

	local monsterList = getWildcardMonsterList(prey.wildcard)

	if not monsterList then
		return
	end

	local startItem = math.max(itemListMin[slot], value)
	local endItem = startItem + maxFitItems[slot] - 1

	if endItem > itemListMax[slot] then
		endItem = itemListMax[slot]
		startItem = endItem - maxFitItems[slot] + 1
	end

	for i, monsterLabel in ipairs(itemsPool[slot]) do
		local itemId = value > 0 and startItem + i - 1 or startItem + i
		local monsterInfo = currentRaces[slot][itemId]
		local color = itemId % 2 == 1 and "#484848" or "#414141"

		monsterLabel:setBackgroundColor(color)

		monsterLabel.background = color

		monsterLabel:setId(monsterInfo)
		monsterLabel:setColor("#c0c0c0")

		local creature = creatureList[monsterInfo]

		if creature then
			monsterLabel:setText(string.capitalize(creature.name))
		end

		if selectedMonster[slot] == monsterInfo then
			monsterList:focusChild(monsterLabel)
			monsterLabel:setBackgroundColor("#585858")
			monsterLabel:setColor("#f4f4f4")

			lastSelectedLabel[slot] = monsterLabel
		end

		monsterLabel.icon:setVisible(false)
		monsterLabel:setTextOffset("0 0")
	end
end

function updateWildCardWindow()
	for i = 0, 2 do
		local prey = preyWindow["slot" .. i + 1]

		if not prey or not prey.wildcard:isVisible() then
			-- block empty
		else
			table.sort(currentRaces[i], function(a, b)
				local creatureA = creatureList[a]
				local creatureB = creatureList[b]

				if not creatureA or not creatureB then
					return false
				end

				return creatureA.name < creatureB.name
			end)

			local monsterList = getWildcardMonsterList(prey.wildcard)

			if not monsterList then
				-- block empty
			else
				itemsPool[i] = {}

				monsterList:destroyChildren()

				local count = 0

				for k = 1, poolSize[i] do
					local monsterInfo = currentRaces[i][k]

					if monsterInfo == nil then
						break
					end

					local monster = g_ui.createWidget("WildcardLabel", monsterList)

					monster:setId(monsterInfo)
					monster:setActionId(i + 1)
					monster:setTextAlign(AlignLeft)

					count = count + 1

					local color = count % 2 == 1 and "#484848" or "#414141"

					monster:setBackgroundColor(color)

					monster.background = color

					local creature = creatureList[monsterInfo]

					if creature then
						monster:setText(string.capitalize(creature.name))
					end

					monster:setTextOffset("0 0")

					function monster.onHoverChange(monster, hovered)
						onSpecialHover("selectionList", bonusType, bonusValue)
					end

					table.insert(itemsPool[i], monster)
				end

				prey.wildcard:recursiveGetChildById("monsterListScrollBar"):setValue(0)

				maxFitItems[i] = math.floor(monsterList:getHeight() / itemSize[i])

				local scrollbar = prey.wildcard:recursiveGetChildById("monsterListScrollBar")

				scrollbar:setMinimum(itemListMin[i])
				scrollbar:setMaximum(itemListMax[i])

				function scrollbar:onValueChange(value, delta)
					onWildcardValueChange(self, value, delta, i)
				end
			end
		end
	end
end

function onPreyWildcard(slot, races, _, lockType, bonusType, bonusValue, bonusGrade)
	local prey = preyWindow["slot" .. slot + 1]

	if not prey then
		return
	end

	itemListMin[slot] = 0
	itemListMax[slot] = #races
	currentRaces[slot] = races
	currentSearchRaces[slot] = {}
	itemSize[slot] = WILDCARD_LABEL_HEIGHT
	maxFitItems[slot] = 0
	poolSize[slot] = WILDCARD_VISIBLE_LABELS
	itemsPool[slot] = {}

	prey.title:setText("Select your prey creature")
	prey.inactive:hide()
	prey.active:hide()
	prey.locked:hide()
	prey.select:hide()
	prey.wildcard:show()

	local monsterList = getWildcardMonsterList(prey.wildcard)

	if not monsterList then
		return
	end

	monsterList:focusChild(nil)
	monsterList:destroyChildren()

	for i = 1, poolSize[slot] do
		local monster = g_ui.createWidget("WildcardLabel", monsterList)

		table.insert(itemsPool[slot], monster)
	end

	maxFitItems[slot] = math.floor(monsterList:getHeight() / itemSize[slot])

	local scrollbar = prey.wildcard:recursiveGetChildById("monsterListScrollBar")

	scrollbar:setMinimum(itemListMin[slot])
	scrollbar:setMaximum(itemListMax[slot])

	function scrollbar:onValueChange(value, delta)
		onWildcardValueChange(self, value, delta, slot)
	end

	prey.wildcard:recursiveGetChildById("searchText"):clearText(true)

	function monsterList:onChildFocusChange(selected, lastSelected)
		onWildcardChange(prey, selected, lastSelected, slot)
	end

	local preyPanel = prey.wildcard.panel

	function preyPanel.onHoverChange()
		onSpecialHover("selectionList", bonusType, bonusValue)
	end

	prey.wildcard.choose.button.choosePreyButton:setActionId(slot + 1)

	function prey.wildcard.choose.button.choosePreyButton.onClick()
		return g_game.preyAction(slot, 4, selectedMonster[slot])
	end

	prey.lockType = lockType
	prey.bonusValue = bonusValue
	prey.bonusGrade = bonusGrade

	if bonusType == 0 and bonusValue == 0 and bonusGrade == 0 then
		prey.bonusType = PREY_BONUS_NONE
	else
		prey.bonusType = bonusType
	end

	setUnsupportedSettings()
	updatePreyWidget(slot, SLOT_STATE_WILDCARD)
	updateWildCardWindow()
end

function onPreyLocked(slot, unlockState, timeUntilFreeReroll, lockType)
	local prey = preyWindow["slot" .. slot + 1]

	if not prey then
		return
	end

	prey.title:setText("Locked")
	prey.inactive:hide()
	prey.active:hide()
	prey.select:hide()
	prey.wildcard:hide()
	prey.locked:show()
	prey.locked.perm:setVisible(unlockState == PREY_UNLOCK_STORE)

	if timeUntilFreeReroll then
		setTimeUntilFreeReroll(slot, timeUntilFreeReroll)
	end

	prey.lockType = lockType

	setUnsupportedSettings()
	updatePreyWidget(slot, SLOT_STATE_LOCKED)
end

function onPreyInactive(slot, timeUntilFreeReroll, lockType)
	local prey = preyWindow["slot" .. slot + 1]

	if not prey then
		return
	end

	prey.title:setText("Inactive")
	setTimeUntilFreeReroll(slot, timeUntilFreeReroll)
	prey.active:hide()
	prey.locked:hide()
	prey.wildcard:hide()
	prey.select:hide()
	configurePreyButtonsPanel(prey.inactive.buttonsPanel, false)
	prey.inactive:show()

	local inactiveRow = getPreyButtonsRow(prey.inactive.buttonsPanel, false)

	function inactiveRow.reroll.button.rerollButton.onClick()
		if not inactiveRow.reroll.button.rerollButton:isOn() then
			return
		end

		onRerollButtonAction(slot, timeUntilFreeReroll <= 0)
	end

	setUnsupportedSettings()

	prey.lockType = lockType
	prey.bonusType = PREY_BONUS_NONE
	prey.bonusValue = 0
	prey.bonusGrade = 0
	cyclopediaPreyCache[slot] = nil

	updatePreyWidget(slot, SLOT_STATE_INACTIVE)
end

function storeRedirect(offerType)
	if g_modalManager then
		g_modalManager.hide(preyWindow)
	end

	preyWindow:hide()

	if modules.game_store and modules.game_store.openUsefulThings then
		modules.game_store.openUsefulThings(offerType)
	else
		g_game.openStore()
		scheduleEvent(function()
			g_game.sendRequestUsefulThings(offerType or 0)
		end, 250)
	end
end

function focusPrevWildcardLabel(list)
	local c = list:getFocusedChild()

	if not c then
		return
	end

	local cIndex = list:getChildIndex(c)

	if cIndex > 1 then
		list:focusPreviousChild(KeyboardFocusReason)
	else
		local scrollbar = list:getParent():recursiveGetChildById("monsterListScrollBar")

		scrollbar:setValue(scrollbar:getValue() - 1)

		if cIndex == 1 then
			list:focusPreviousChild(KeyboardFocusReason)
		end
	end
end

function focusNextWildcardLabel(list)
	local c = list:getFocusedChild()
	local cIndex = list:getChildIndex(c)
	local cCount = list:getChildCount()

	if cIndex < cCount then
		list:focusNextChild(KeyboardFocusReason)
	else
		local scrollbar = list:getParent():recursiveGetChildById("monsterListScrollBar")

		scrollbar:setValue(scrollbar:getValue() + 1)

		if cIndex == cCount then
			list:focusNextChild(KeyboardFocusReason)
		end
	end
end

function updateRerollTime()
	if not g_game.isOnline() or not preyWindow:isVisible() then
		removeEvent(updateRerollEvent)

		updateRerollEvent = nil

		return
	end

	for slot, data in pairs(timeLeftRerrol) do
		local elapsed = os.time() - data.startTime

		if elapsed > 0 then
			local secondsLeft = data.secondsLeft

			if secondsLeft == nil and data.minutesLeft ~= nil then
				secondsLeft = data.minutesLeft * 60
			end

			if secondsLeft then
				setTimeUntilFreeReroll(slot, math.max(0, secondsLeft - elapsed))
			end
		end
	end
end

local function calculateTrackerContentHeight(contentsPanel)
	contentsPanel:updateLayout()

	local layout = contentsPanel:getLayout()
	local spacing = layout and layout.getSpacing and layout:getSpacing() or 0
	local total = 0
	local visibleCount = 0

	for _, child in ipairs(contentsPanel:getChildren()) do
		if child:isExplicitlyVisible() then
			visibleCount = visibleCount + 1
			total = total + child:getMarginTop() + child:getHeight() + child:getMarginBottom()
		end
	end

	if visibleCount > 1 then
		total = total + spacing * (visibleCount - 1)
	end

	return math.max(49, total + KILL_TRACKER_HEIGHT_PADDING)
end

local function hasSavedKillTrackerHeight()
	if not SidebarPersistence or not SidebarPersistence.getSection then
		return false
	end

	local options = SidebarPersistence.getSection("preyWidgetOptions")

	return type(options) == "table" and type(options.contentHeight) == "number" and options.contentHeight > 0
end

function updateTrackerHeight()
	if not preyTracker or preyTracker:isDestroyed() then
		return
	end

	local contentsPanel = preyTracker.contentsPanel

	if not contentsPanel then
		return
	end

	local contentHeight = calculateTrackerContentHeight(contentsPanel)

	preyTracker:setContentMaximumHeight(contentHeight)

	if not preyTracker:isOn() then
		if not killTrackerHeightInitialized then
			killTrackerHeightInitialized = true

			if not hasSavedKillTrackerHeight() then
				preyTracker:setContentHeight(contentHeight)
			end
		end

		local maxHeight = preyTracker:getMaximumHeight()

		if maxHeight < preyTracker:getHeight() then
			preyTracker:setHeight(maxHeight)
		end

		preyTracker:fitOnParent()
	end
end

function formatCyclopediaPreyDescription(creatureName, bonusType, bonusValue, timeLeft)
	local bonusName = bonusTypeTranslate(bonusType)
	local hours = math.floor((timeLeft or 0) / 3600)
	local mins = math.floor((timeLeft or 0) % 3600 / 60)

	return string.format("%s (%s +%d%%, remaining %d:%dh)", creatureName, bonusName, bonusValue or 0, hours, mins)
end

function getCyclopediaActivePreySlots()
	local activeSlots = {}

	for slotIndex = 0, 2 do
		local cached = cyclopediaPreyCache[slotIndex]

		if cached and cached.name and cached.name ~= "" then
			table.insert(activeSlots, {
				slot = slotIndex,
				description = formatCyclopediaPreyDescription(cached.name, cached.bonusType, cached.bonusValue, cached.timeLeft)
			})
		end
	end

	if #activeSlots > 0 then
		return activeSlots
	end

	if not preyWindow or preyWindow:isDestroyed() then
		return activeSlots
	end

	for slotIndex = 0, 2 do
		local prey = preyWindow["slot" .. slotIndex + 1]

		if prey and prey.active and prey.active:isVisible() then
			local creatureName = prey.title:getText()

			if creatureName and creatureName ~= "" and creatureName ~= "Inactive" then
				table.insert(activeSlots, {
					slot = slotIndex,
					description = formatCyclopediaPreyDescription(creatureName, prey.bonusType, prey.bonusValue, prey.timeLeft)
				})
			end
		end
	end

	return activeSlots
end
