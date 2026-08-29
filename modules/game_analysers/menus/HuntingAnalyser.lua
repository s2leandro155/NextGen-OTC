-- chunkname: @/game_analysers/menus/HuntingAnalyser.lua

if not HuntingAnalyser then
	HuntingAnalyser = {
		healingHour = 0,
		healing = 0,
		damageHour = 0,
		damage = 0,
		balance = 0,
		supplies = 0,
		loot = 0,
		rawXpHour = 0,
		xpHour = 0,
		xpGain = 0,
		rawXPGain = 0,
		xpForRate = 0,
		rawXpForRate = 0,
		startExp = 0,
		session = 0,
		launchTime = 0,
		killedMonsters = {},
		lootedItems = {},
		suppliesItems = {},
		healingTicks = {},
		damageTicks = {},
		lootedItemsName = {}
	}
	HuntingAnalyser.__index = HuntingAnalyser
end

-- The Hunt Analyser is intentionally narrow. Keep large signed XP values from
-- growing over the label; full precision remains available in copy/export and
-- in the dedicated XP Analyser tooltip.
local function formatHuntXpValue(value)
	local number = tonumber(value) or 0
	local absolute = math.abs(number)
	local sign = number < 0 and "-" or ""

	if absolute >= 1000000000 then
		return sign .. string.format("%.2f", absolute / 1000000000):gsub("%.?0+$", "") .. "kkk"
	elseif absolute >= 1000000 then
		return sign .. string.format("%.1f", absolute / 1000000):gsub("%.?0+$", "") .. "kk"
	end

	local rounded = number >= 0 and math.floor(number + 0.5) or math.ceil(number - 0.5)
	return formatMoney(rounded)
end

function HuntingAnalyser:create()
	HuntingAnalyser.launchTime = 0
	HuntingAnalyser.session = 0
	HuntingAnalyser.startExp = 0
	HuntingAnalyser.rawXPGain = 0
	HuntingAnalyser.xpGain = 0
	HuntingAnalyser.rawXpForRate = 0
	HuntingAnalyser.xpForRate = 0
	HuntingAnalyser.xpHour = 0
	HuntingAnalyser.rawXpHour = 0
	HuntingAnalyser.loot = 0
	HuntingAnalyser.supplies = 0
	HuntingAnalyser.balance = 0
	HuntingAnalyser.damage = 0
	HuntingAnalyser.damageHour = 0
	HuntingAnalyser.healing = 0
	HuntingAnalyser.healingHour = 0
	HuntingAnalyser.killedMonsters = {}
	HuntingAnalyser.lootedItems = {}
	HuntingAnalyser.suppliesItems = {}
	HuntingAnalyser.healingTicks = {}
	HuntingAnalyser.damageTicks = {}
	HuntingAnalyser.lootedItemsName = {}
	HuntingAnalyser.window = openedWindows.huntingButton
end

function onHuntingExtra(mousePosition)
	if cancelNextRelease then
		cancelNextRelease = false

		return false
	end

	local menu = g_ui.createWidget("PopupMenu")

	menu:setGameMenu(true)
	menu:addOption(tr("Start New Session"), function()
		modules.game_analysers.startNewSession()
	end)
	menu:addSeparator()
	menu:addCheckBoxOption(tr("Show Raw XP"), function()
		HuntingAnalyser:setShowBaseXp(not HuntingAnalyser.window.contentsPanel.rawXpGain:isVisible())
	end, "", HuntingAnalyser.window.contentsPanel.rawXpGain:isVisible())
	menu:addSeparator()
	menu:addOption(tr("Copy to Clipboard"), function()
		HuntingAnalyser:clipboardData()
	end)
	menu:addOption(tr("Save to File"), function()
		HuntingAnalyser:saveToFile()
	end)
	menu:addOption(tr("Export to Json"), function()
		HuntingAnalyser:saveToJson()
	end)
	menu:display(mousePosition)

	return true
end

function HuntingAnalyser:reset()
	HuntingAnalyser.session = 0
	HuntingAnalyser.startExp = 0
	HuntingAnalyser.rawXPGain = 0
	HuntingAnalyser.xpGain = 0
	HuntingAnalyser.rawXpForRate = 0
	HuntingAnalyser.xpForRate = 0
	HuntingAnalyser.xpHour = 0
	HuntingAnalyser.rawXpHour = 0
	HuntingAnalyser.loot = 0
	HuntingAnalyser.supplies = 0
	HuntingAnalyser.balance = 0
	HuntingAnalyser.damage = 0
	HuntingAnalyser.damageHour = 0
	HuntingAnalyser.healing = 0
	HuntingAnalyser.healingHour = 0
	HuntingAnalyser.killedMonsters = {}
	HuntingAnalyser.lootedItems = {}
	HuntingAnalyser.suppliesItems = {}
	HuntingAnalyser.healingTicks = {}
	HuntingAnalyser.damageTicks = {}
	HuntingAnalyser.lootedItemsName = {}

	HuntingAnalyser:updateWindow(true)
end

function HuntingAnalyser:setupStartExp(value)
	if HuntingAnalyser.startExp == 0 then
		HuntingAnalyser.startExp = value
	end
end

function HuntingAnalyser:updateWindow(ignoreVisible)
	if not HuntingAnalyser.window:isVisible() and not ignoreVisible then
		return
	end

	local player = g_game.getLocalPlayer()

	if not player then
		return
	end

	local contentsPanel = HuntingAnalyser.window.contentsPanel

	if not AnalyserSession:isActive() then
		contentsPanel.session:setText("00:00h")
	else
		local duration = math.max(1, AnalyserSession:durationSeconds())
		local hours = math.floor(duration / 3600)
		local minutes = math.floor(duration % 3600 / 60)
		local sessionTimeStr = string.format("%02d:%02dh", hours, minutes)

		if sessionTimeStr ~= contentsPanel.session:getText() then
			contentsPanel.session:setText(sessionTimeStr)
		end
	end

	local experience = HuntingAnalyser.xpGain

	if not contentsPanel.xpGain.lastExperience or contentsPanel.xpGain.lastExperience ~= experience then
		contentsPanel.xpGain:setText(formatHuntXpValue(experience))

		contentsPanel.xpGain.lastExperience = experience
	end

	HuntingAnalyser.xpHour = AnalyserSession:perHourFromTotal(HuntingAnalyser.xpForRate)

	if HuntingAnalyser.xpHour ~= HuntingAnalyser.xpHour then
		HuntingAnalyser.xpHour = 0
	end

	if not contentsPanel.xpHour.lastValue or contentsPanel.xpHour.lastValue ~= HuntingAnalyser.xpHour then
		contentsPanel.xpHour:setText(formatHuntXpValue(HuntingAnalyser.xpHour))

		contentsPanel.xpHour.lastValue = HuntingAnalyser.xpHour
	end

	local rawExperience = HuntingAnalyser.rawXPGain

	HuntingAnalyser.rawXpHour = AnalyserSession:perHourFromTotal(HuntingAnalyser.rawXpForRate)

	if HuntingAnalyser.rawXpHour ~= HuntingAnalyser.rawXpHour then
		HuntingAnalyser.rawXpHour = 0
	end

	if not contentsPanel.rawXpGain.lastValue or contentsPanel.rawXpGain.lastValue ~= rawExperience then
		contentsPanel.rawXpGain:setText(formatHuntXpValue(rawExperience))

		contentsPanel.rawXpGain.lastValue = rawExperience
	end

	if not contentsPanel.rawXpHour.lastValue or contentsPanel.rawXpHour.lastValue ~= HuntingAnalyser.rawXpHour then
		contentsPanel.rawXpHour:setText(formatHuntXpValue(HuntingAnalyser.rawXpHour))

		contentsPanel.rawXpHour.lastValue = HuntingAnalyser.rawXpHour
	end

	if not contentsPanel.loot.lastValue or contentsPanel.loot.lastValue ~= HuntingAnalyser.loot then
		if HuntingAnalyser.loot > 1000000 then
			contentsPanel.loot:setText(formatMoney(HuntingAnalyser.loot))
		else
			contentsPanel.loot:setText(formatMoney(HuntingAnalyser.loot))
		end

		contentsPanel.loot.lastValue = HuntingAnalyser.loot
	end

	if not contentsPanel.supplies.lastValue or contentsPanel.supplies.lastValue ~= HuntingAnalyser.supplies then
		if HuntingAnalyser.supplies > 1000000 then
			contentsPanel.supplies:setText(formatMoney(HuntingAnalyser.supplies))
		else
			contentsPanel.supplies:setText(formatMoney(HuntingAnalyser.supplies))
		end

		contentsPanel.supplies.lastValue = HuntingAnalyser.supplies
	end

	HuntingAnalyser:checkBalance()

	if not contentsPanel.balance.lastValue or contentsPanel.balance.lastValue ~= HuntingAnalyser.balance then
		if HuntingAnalyser.balance > 1000000 then
			contentsPanel.balance:setText(formatMoney(HuntingAnalyser.balance))
		else
			contentsPanel.balance:setText(comma_value(HuntingAnalyser.balance))
		end

		contentsPanel.balance.lastValue = HuntingAnalyser.balance
	end

	contentsPanel.balance:setColor(HuntingAnalyser.balance >= 0 and "#44ad25" or "#ff9854")

	if not contentsPanel.damage.lastValue or contentsPanel.damage.lastValue ~= HuntingAnalyser.damage then
		if HuntingAnalyser.damage > 1000000 then
			contentsPanel.damage:setText(formatMoney(HuntingAnalyser.damage))
		else
			contentsPanel.damage:setText(formatMoney(HuntingAnalyser.damage))
		end

		contentsPanel.damage.lastValue = HuntingAnalyser.damage
	end

	local currentDamagePerHour = AnalyserSession:perHourFromTotal(HuntingAnalyser.damage)

	if not contentsPanel.damageHour.lastValue or contentsPanel.damageHour.lastValue ~= currentDamagePerHour then
		HuntingAnalyser.damageHour = currentDamagePerHour

		if HuntingAnalyser.damageHour > 1000000 then
			contentsPanel.damageHour:setText(formatMoney(HuntingAnalyser.damageHour))
		else
			contentsPanel.damageHour:setText(formatMoney(HuntingAnalyser.damageHour))
		end

		contentsPanel.damageHour.lastValue = HuntingAnalyser.damageHour
	end

	if not contentsPanel.healing.lastValue or contentsPanel.healing.lastValue ~= HuntingAnalyser.healing then
		if HuntingAnalyser.healing > 1000000 then
			contentsPanel.healing:setText(formatMoney(HuntingAnalyser.healing))
		else
			contentsPanel.healing:setText(formatMoney(HuntingAnalyser.healing))
		end

		contentsPanel.healing.lastValue = HuntingAnalyser.healing
	end

	local currentHealingPerHour = AnalyserSession:perHourFromTotal(HuntingAnalyser.healing)

	if not contentsPanel.healHour.lastValue or contentsPanel.healHour.lastValue ~= currentHealingPerHour then
		HuntingAnalyser.healingHour = currentHealingPerHour

		if HuntingAnalyser.healingHour > 1000000 then
			contentsPanel.healHour:setText(formatMoney(HuntingAnalyser.healingHour))
		else
			contentsPanel.healHour:setText(formatMoney(HuntingAnalyser.healingHour))
		end

		contentsPanel.healHour.lastValue = HuntingAnalyser.healingHour
	end

	if table.empty(HuntingAnalyser.killedMonsters) then
		contentsPanel.killedMonsters.monster:setText("None")
		contentsPanel.killedMonsters.monster:setHeight(20)
		contentsPanel.killedMonsters:setHeight(20)
	else
		local lines = {}

		for monster, count in pairs(HuntingAnalyser.killedMonsters) do
			lines[#lines + 1] = string.format("%dx %s", count, monster)
		end

		contentsPanel.killedMonsters.monster:setText(table.concat(lines, "\n"))
		contentsPanel.killedMonsters.monster:setHeight(15 * #lines)
		contentsPanel.killedMonsters:setHeight(15 * #lines)
	end

	if table.empty(HuntingAnalyser.lootedItemsName) then
		contentsPanel.lootedItems.loot:setText("None")
		contentsPanel.lootedItems.loot:setHeight(20)
		contentsPanel.lootedItems:setHeight(20)
	else
		local lines = {}

		for name, count in pairs(HuntingAnalyser.lootedItemsName) do
			lines[#lines + 1] = string.format("%dx %s", count, name)
		end

		contentsPanel.lootedItems.loot:setText(table.concat(lines, "\n"))
		contentsPanel.lootedItems.loot:setHeight(15 * #lines)
		contentsPanel.lootedItems:setHeight(15 * #lines)
	end
end

function HuntingAnalyser:getLaunchTime()
	return HuntingAnalyser.launchTime
end

function HuntingAnalyser:getSession()
	return HuntingAnalyser.session
end

function HuntingAnalyser:getStartExp()
	return HuntingAnalyser.startExp
end

function HuntingAnalyser:getRawXPGain()
	return HuntingAnalyser.rawXPGain
end

function HuntingAnalyser:getXpGain()
	return HuntingAnalyser.xpGain
end

function HuntingAnalyser:getXpHour()
	return HuntingAnalyser.xpHour
end

function HuntingAnalyser:getLoot()
	return HuntingAnalyser.loot
end

function HuntingAnalyser:getSupplies()
	return HuntingAnalyser.supplies
end

function HuntingAnalyser:getBalance()
	return HuntingAnalyser.balance
end

function HuntingAnalyser:getDamage()
	return HuntingAnalyser.damage
end

function HuntingAnalyser:getDamageHour()
	return HuntingAnalyser.damageHour
end

function HuntingAnalyser:getHealing()
	return HuntingAnalyser.healing
end

function HuntingAnalyser:getHealingHour()
	return HuntingAnalyser.healingHour
end

function HuntingAnalyser:getKilledMonsters()
	return HuntingAnalyser.killedMonsters
end

function HuntingAnalyser:getLootedItems()
	return HuntingAnalyser.lootedItems
end

function HuntingAnalyser:getSuppliesItems()
	return HuntingAnalyser.suppliesItems
end

function HuntingAnalyser:getHealingTicks()
	return HuntingAnalyser.healingTicks
end

function HuntingAnalyser:getDamageTicks()
	return HuntingAnalyser.damageTicks
end

function HuntingAnalyser:setLaunchTime(value)
	HuntingAnalyser.launchTime = value
end

function HuntingAnalyser:setSession(value)
	HuntingAnalyser.session = value
end

function HuntingAnalyser:setStartExp(value)
	HuntingAnalyser.startExp = value
end

function HuntingAnalyser:setRawXPGain(value)
	HuntingAnalyser.rawXPGain = value
end

function HuntingAnalyser:setXpGain(value)
	HuntingAnalyser.xpGain = value
end

function HuntingAnalyser:setXpHour(value)
	HuntingAnalyser.xpHour = value
end

function HuntingAnalyser:setLoot(value)
	HuntingAnalyser.loot = value
end

function HuntingAnalyser:setSupplies(value)
	HuntingAnalyser.supplies = value
end

function HuntingAnalyser:setBalance(value)
	HuntingAnalyser.balance = value
end

function HuntingAnalyser:setDamage(value)
	HuntingAnalyser.damage = value
end

function HuntingAnalyser:setDamageHour(value)
	HuntingAnalyser.damageHour = value
end

function HuntingAnalyser:setHealing(value)
	HuntingAnalyser.healing = value
end

function HuntingAnalyser:setHealingHour(value)
	HuntingAnalyser.healingHour = value
end

function HuntingAnalyser:setKilledMonsters(value)
	HuntingAnalyser.killedMonsters = value
end

function HuntingAnalyser:setLootedItems(value)
	HuntingAnalyser.lootedItems = value
end

function HuntingAnalyser:setSuppliesItems(value)
	HuntingAnalyser.suppliesItems = value
end

function HuntingAnalyser:setHealingTicks(value)
	HuntingAnalyser.healingTicks = value
end

function HuntingAnalyser:setDamageTicks(value)
	HuntingAnalyser.damageTicks = value
end

function HuntingAnalyser:addRawXPGain(value, countForRate)
	HuntingAnalyser.rawXPGain = HuntingAnalyser.rawXPGain + value
	if countForRate ~= false and value > 0 then
		HuntingAnalyser.rawXpForRate = HuntingAnalyser.rawXpForRate + value
	end
end

function HuntingAnalyser:addXpGain(value, countForRate)
	HuntingAnalyser.xpGain = HuntingAnalyser.xpGain + value
	if countForRate ~= false and value > 0 then
		HuntingAnalyser.xpForRate = HuntingAnalyser.xpForRate + value
	end
end

function HuntingAnalyser:addLootedItems(item, name)
	local itemId = item:getId()
	local count = item:getCount()
	local data = HuntingAnalyser.lootedItems[itemId]

	if not data then
		local price = getLootPrice(itemId)

		HuntingAnalyser.loot = HuntingAnalyser.loot + price * count
		HuntingAnalyser.lootedItems[itemId] = {
			itemId = itemId,
			name = name,
			count = count,
			price = price
		}
	else
		data.count = data.count + count
		HuntingAnalyser.loot = HuntingAnalyser.loot + data.price * count
	end

	if not HuntingAnalyser.lootedItemsName[name] then
		HuntingAnalyser.lootedItemsName[name] = 0
	end

	HuntingAnalyser.lootedItemsName[name] = HuntingAnalyser.lootedItemsName[name] + count
end

function HuntingAnalyser:addSuppliesItems(itemId)
	local supplyItemInfo = HuntingAnalyser.suppliesItems[itemId]

	if not HuntingAnalyser.suppliesItems[itemId] then
		local price = getCurrentPrice(itemId)

		HuntingAnalyser.suppliesItems[itemId] = {
			count = 0,
			price = price
		}
		supplyItemInfo = HuntingAnalyser.suppliesItems[itemId]
	end

	supplyItemInfo.count = supplyItemInfo.count + 1
	HuntingAnalyser.supplies = HuntingAnalyser.supplies + supplyItemInfo.price
end

function HuntingAnalyser:updateLootedItemValue(itemId, newPrice)
	local itemData = HuntingAnalyser.lootedItems[itemId]

	if not itemData then
		return
	end

	local oldTotalValue = itemData.price * itemData.count
	local newTotalValue = newPrice * itemData.count

	HuntingAnalyser.loot = HuntingAnalyser.loot - oldTotalValue + newTotalValue
	itemData.price = newPrice
end

function HuntingAnalyser:checkBalance()
	HuntingAnalyser.balance = HuntingAnalyser.loot + HuntingAnalyser.supplies * -1
end

function HuntingAnalyser:addHealing(value)
	HuntingAnalyser.healing = HuntingAnalyser.healing + value
	HuntingAnalyser.healingTicks[#HuntingAnalyser.healingTicks + 1] = {
		amount = value,
		tick = g_clock.millis()
	}
end

function HuntingAnalyser:addDealDamage(value)
	HuntingAnalyser.damage = HuntingAnalyser.damage + value
	HuntingAnalyser.damageTicks[#HuntingAnalyser.damageTicks + 1] = {
		amount = value,
		tick = g_clock.millis()
	}
end

function HuntingAnalyser:addMonsterKilled(monsterName)
	if not HuntingAnalyser.killedMonsters[monsterName] then
		HuntingAnalyser.killedMonsters[monsterName] = 0
	end

	HuntingAnalyser.killedMonsters[monsterName] = HuntingAnalyser.killedMonsters[monsterName] + 1
end

local function generateSessionText()
	local duration = math.max(1, AnalyserSession:durationSeconds())
	local hours = math.floor(duration / 3600)
	local minutes = math.floor(duration % 3600 / 60)
	local lines = {}

	lines[#lines + 1] = "Session data: From " .. os.date("%Y-%m-%d, %H:%M:%S", AnalyserSession.startUnix) .. " to " .. os.date("%Y-%m-%d, %H:%M:%S")
	lines[#lines + 1] = "Session: " .. string.format("%02d:%02dh", hours, minutes)
	lines[#lines + 1] = "Raw XP Gain: " .. format_thousand(HuntingAnalyser.rawXPGain)
	lines[#lines + 1] = "XP Gain: " .. format_thousand(HuntingAnalyser.xpGain)
	lines[#lines + 1] = "XP/h: " .. format_thousand(HuntingAnalyser.xpHour)
	lines[#lines + 1] = "Raw XP/h: " .. format_thousand(HuntingAnalyser.rawXpHour)
	lines[#lines + 1] = "Loot: " .. format_thousand(HuntingAnalyser.loot)
	lines[#lines + 1] = "Supplies: " .. format_thousand(HuntingAnalyser.supplies)
	lines[#lines + 1] = "Balance: " .. format_thousand(HuntingAnalyser.balance)
	lines[#lines + 1] = "Damage: " .. format_thousand(HuntingAnalyser.damage)
	lines[#lines + 1] = "Damage/h: " .. format_thousand(HuntingAnalyser.damageHour)
	lines[#lines + 1] = "Healing: " .. format_thousand(HuntingAnalyser.healing)
	lines[#lines + 1] = "Healing/h: " .. format_thousand(HuntingAnalyser.healingHour)

	if table.empty(HuntingAnalyser.killedMonsters) then
		lines[#lines + 1] = "Killed Monsters: \n\tNone"
	else
		local monsterLines = {}

		for monster, count in pairs(HuntingAnalyser.killedMonsters) do
			monsterLines[#monsterLines + 1] = string.format("\t%dx %s", count, monster)
		end

		lines[#lines + 1] = "Killed Monsters: \n" .. table.concat(monsterLines, "\n")
	end

	if table.empty(HuntingAnalyser.lootedItemsName) then
		lines[#lines + 1] = "Looted Items: \n\tNone"
	else
		local lootLines = {}

		for name, count in pairs(HuntingAnalyser.lootedItemsName) do
			lootLines[#lootLines + 1] = string.format("\t%dx %s", count, name)
		end

		lines[#lines + 1] = "Looted Items: \n" .. table.concat(lootLines, "\n")
	end

	return table.concat(lines, "\n")
end

function HuntingAnalyser:clipboardData()
	g_window.setClipboardText(generateSessionText())
end

function HuntingAnalyser:saveToFile()
	local text = generateSessionText()
	local filename = "Hunting_Session_" .. os.date("%Y-%m-%d", AnalyserSession.startUnix) .. "_" .. AnalyserSession.startUnix .. ".txt"

	g_resources.writeFileContents(filename, text)
	modules.game_textmessage.displayStatusMessage(tr("Hunting Session data has been saved to location '%s'", filename))
end

function HuntingAnalyser:saveToJson()
	local huntingData = {}

	huntingData.Balance = formatMoney(HuntingAnalyser.balance, ",")
	huntingData.Damage = formatMoney(HuntingAnalyser.damage, ",")
	huntingData.DamageHour = formatMoney(HuntingAnalyser.damageHour, ",")
	huntingData.Healing = formatMoney(HuntingAnalyser.healing, ",")
	huntingData.HealingHour = formatMoney(HuntingAnalyser.healingHour, ",")
	huntingData.KilledMonsters = {}

	if not table.empty(HuntingAnalyser.killedMonsters) then
		for monster, count in pairs(HuntingAnalyser.killedMonsters) do
			huntingData.KilledMonsters[#huntingData.KilledMonsters + 1] = {
				Count = count,
				Name = monster
			}
		end
	end

	huntingData.Loot = formatMoney(HuntingAnalyser.loot, ",")
	huntingData.LootedItems = {}

	if not table.empty(HuntingAnalyser.lootedItemsName) then
		for name, count in pairs(HuntingAnalyser.lootedItemsName) do
			huntingData.LootedItems[#huntingData.LootedItems + 1] = {
				Count = count,
				Name = name
			}
		end
	end

	huntingData.RawXPGain = formatMoney(HuntingAnalyser.rawXPGain, ",")
	huntingData.SessionEnd = os.date("%Y-%m-%d, %H:%M:%S")

	local duration = math.max(1, AnalyserSession:durationSeconds())
	local hours = math.floor(duration / 3600)
	local minutes = math.floor(duration % 3600 / 60)

	huntingData.SessionLength = string.format("%02d:%02dh", hours, minutes)
	huntingData.SessionStart = os.date("%Y-%m-%d, %H:%M:%S", AnalyserSession.startUnix)
	huntingData.Supplies = formatMoney(HuntingAnalyser.supplies, ",")
	huntingData.XPGain = formatMoney(HuntingAnalyser.xpGain, ",")
	huntingData.XPGainHour = formatMoney(HuntingAnalyser.xpHour, ",")
	huntingData.RawXPGainHour = formatMoney(HuntingAnalyser.rawXpHour, ",")

	local filename = "Hunting_Session_" .. os.date("%Y-%m-%d", AnalyserSession.startUnix) .. "_" .. AnalyserSession.startUnix .. ".json"
	local status, result = pcall(function()
		return json.encode(huntingData, 2)
	end)

	if not status then
		return onError("Error while saving hunting analyzer profile settings. Data won't be saved. Details: " .. result)
	end

	if result:len() > 104857600 then
		return onError("Something went wrong, file is above 100MB, won't be saved")
	end

	g_resources.writeFileContents(filename, result)
	modules.game_textmessage.displayStatusMessage(tr("Hunting Session data has been saved to location '%s'", filename))
end

function HuntingAnalyser:setShowBaseXp(value)
	HuntingAnalyser.window.contentsPanel.rawXpLabel:setVisible(value)
	HuntingAnalyser.window.contentsPanel.rawXpGain:setVisible(value)

	HuntingAnalyser.showBaseXp = value

	if HuntingAnalyser.showBaseXp then
		HuntingAnalyser.window.contentsPanel.xpGain:addAnchor(AnchorTop, "rawXpGain", AnchorBottom)
		HuntingAnalyser.window.contentsPanel.xpLabel:addAnchor(AnchorTop, "rawXpLabel", AnchorBottom)
	else
		HuntingAnalyser.window.contentsPanel.xpGain:addAnchor(AnchorTop, "session", AnchorBottom)
		HuntingAnalyser.window.contentsPanel.xpLabel:addAnchor(AnchorTop, "sessionLabel", AnchorBottom)
	end

	HuntingAnalyser.window.contentsPanel.rawXpHourLabel:setVisible(value)
	HuntingAnalyser.window.contentsPanel.rawXpHour:setVisible(value)

	if HuntingAnalyser.showBaseXp then
		HuntingAnalyser.window.contentsPanel.xpHour:addAnchor(AnchorTop, "rawXpHour", AnchorBottom)
		HuntingAnalyser.window.contentsPanel.xpHourLabel:addAnchor(AnchorTop, "rawXpHourLabel", AnchorBottom)
	else
		HuntingAnalyser.window.contentsPanel.xpHour:addAnchor(AnchorTop, "xpGain", AnchorBottom)
		HuntingAnalyser.window.contentsPanel.xpHourLabel:addAnchor(AnchorTop, "xpLabel", AnchorBottom)
	end
end

function HuntingAnalyser:loadConfigJson()
	local player = g_game.getLocalPlayer()

	if not player then
		return
	end

	HuntingAnalyser.showBaseXp = false

	local file = "/characterdata/" .. player:getId() .. "/huntingsessionanalyser.json"

	if g_resources.fileExists(file) then
		local status, result = pcall(function()
			return json.decode(g_resources.readFileContents(file))
		end)

		if not status then
			return g_logger.error("Error while reading characterdata file. Details: " .. result)
		end

		HuntingAnalyser.showBaseXp = result.showBaseXp
	end

	HuntingAnalyser:setShowBaseXp(HuntingAnalyser.showBaseXp)
end

function HuntingAnalyser:saveConfigJson()
	local config = {
		showBaseXp = HuntingAnalyser.showBaseXp
	}

	if not LoadedPlayer:isLoaded() then
		return
	end

	local file = "/characterdata/" .. LoadedPlayer:getId() .. "/huntingsessionanalyser.json"
	local status, result = pcall(function()
		return json.encode(config, 2)
	end)

	if not status then
		return g_logger.error("Error while saving profile HuntingAnalyzer. Data won't be saved. Details: " .. result)
	end

	if result:len() > 104857600 then
		return g_logger.error("Something went wrong, file is above 100MB, won't be saved")
	end

	g_resources.writeFileContents(file, result)
end
