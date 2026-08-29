-- chunkname: @/game_analysers/menus/XPAnalyser.lua

if not XPAnalyser then
	XPAnalyser = {
		target = 0,
		level = 0,
		rawXpHour = 0,
		xpHour = 0,
		xpGain = 0,
		rawXPGain = 0,
		xpForRate = 0,
		rawXpForRate = 0,
		startExp = 0,
		session = 0,
		launchTime = 0
	}
	XPAnalyser.__index = XPAnalyser
end

local targetMaxMargin = 144

function expForLevel(level)
	return math.floor(50 * level * level * level / 3 - 100 * level * level + 850 * level / 3 - 200)
end

function expToAdvance(currentLevel, currentExp)
	return expForLevel(currentLevel + 1) - currentExp
end

local function formatXpShown(n)
	return formatMoney(math.floor((tonumber(n) or 0) + 0.5))
end

function XPAnalyser:refreshXpRatesFromSession()
	XPAnalyser.xpHour = AnalyserSession:perHourFromTotal(XPAnalyser.xpForRate)
	XPAnalyser.rawXpHour = AnalyserSession:perHourFromTotal(XPAnalyser.rawXpForRate)
end

local function updateXpTargetArrow()
	local xpBG = XPAnalyser.window and XPAnalyser.window.contentsPanel and XPAnalyser.window.contentsPanel.xpBG

	if not xpBG or not xpBG.xpArrow then
		return
	end

	local arrow = xpBG.xpArrow
	local target = XPAnalyser.target or 0
	local current = XPAnalyser.xpHour or 0

	if target <= 0 and current <= 0 then
		arrow:setMarginLeft(math.floor(targetMaxMargin / 2))

		return
	end

	if target <= 0 then
		arrow:setMarginLeft(targetMaxMargin)

		return
	end

	local targetValue = math.max(1, target)
	local ratio = current / targetValue

	if ratio < 0 then
		ratio = 0
	elseif ratio > 1 then
		ratio = 1
	end

	arrow:setMarginLeft(math.floor(targetMaxMargin * ratio + 0.5))
end

function XPAnalyser.create()
	XPAnalyser.window = openedWindows.xpButton
	XPAnalyser.session = 0
	XPAnalyser.startExp = 0
	XPAnalyser.rawXPGain = 0
	XPAnalyser.xpGain = 0
	XPAnalyser.rawXpForRate = 0
	XPAnalyser.xpForRate = 0
	XPAnalyser.xpHour = 0
	XPAnalyser.rawXpHour = 0
	XPAnalyser.level = 0
	XPAnalyser.target = 0

	function XPAnalyser.window.contentsPanel.xpBG.onMousePress(widget, mousePosition, mouseButton)
		if mouseButton == MouseRightButton then
			onXPExtra(mousePosition, "gaude")

			return true
		end
	end

	function XPAnalyser.window.contentsPanel.graphPanel.onMousePress(widget, mousePosition, mouseButton)
		if mouseButton == MouseRightButton then
			onXPExtra(mousePosition, "graph")

			return true
		end
	end
end

function XPAnalyser:reset(allTimeDps, allTimeHps)
	XPAnalyser.session = 0
	XPAnalyser.startExp = 0
	XPAnalyser.rawXPGain = 0
	XPAnalyser.xpGain = 0
	XPAnalyser.rawXpForRate = 0
	XPAnalyser.xpForRate = 0
	XPAnalyser.xpHour = 0
	XPAnalyser.rawXpHour = 0
	XPAnalyser.level = 0
	XPAnalyser.target = 0

	if XPAnalyser.window and XPAnalyser.window.contentsPanel and XPAnalyser.window.contentsPanel.graphPanel then
		analyserUIGraphReset(XPAnalyser.window.contentsPanel.graphPanel, nil, ANALYSER_GRAPH_CAPACITY_60_MIN)
	end

	pcall(function()
		XPAnalyser:updateWindow(true)
	end)

	if LoadedPlayer and LoadedPlayer.isLoaded and LoadedPlayer:isLoaded() then
		pcall(function()
			XPAnalyser:loadConfigJson()
		end)
		pcall(function()
			XPAnalyser:updateWindow(true)
		end)
	end
end

function XPAnalyser:updateWindow(ignoreVisible)
	if not XPAnalyser.window:isVisible() and not ignoreVisible then
		return
	end

	local contentsPanel = XPAnalyser.window.contentsPanel

	XPAnalyser:refreshXpRatesFromSession()

	if contentsPanel.xpGain then
		contentsPanel.xpGain:setText(formatXpShown(XPAnalyser.xpGain))
	end

	if contentsPanel.rawXpGain then
		contentsPanel.rawXpGain:setText(formatXpShown(XPAnalyser.rawXPGain))
	end

	if contentsPanel.xpHour then
		contentsPanel.xpHour:setText(formatXpShown(XPAnalyser.xpHour))
	end

	if contentsPanel.rawXpHour then
		contentsPanel.rawXpHour:setText(formatXpShown(XPAnalyser.rawXpHour))
	end

	updateXpTargetArrow()
	XPAnalyser:updateTooltip()
end

function XPAnalyser:setupStartExp(value)
	if XPAnalyser.startExp == 0 then
		XPAnalyser.startExp = value
	end
end

function XPAnalyser:setupLevel(level, percent)
	XPAnalyser.level = level

	XPAnalyser.window.contentsPanel.percent:setPercent(math.floor(percent))
	XPAnalyser.window.contentsPanel.nextLevel:setText("-")
end

function XPAnalyser:updateNextLevel(hours, minutes)
	local nl = XPAnalyser.window and XPAnalyser.window.contentsPanel and XPAnalyser.window.contentsPanel.nextLevel
	local text = "-"

	if not nl then
		return
	end

	if XPAnalyser.xpHour == 0 then
		nl:setText(text)

		return
	end

	if hours < 80 then
		if hours > 0 then
			text = tr("%dh %dmin", hours, minutes)
		elseif minutes > 0 then
			text = tr("%d minutes", minutes)
		else
			text = tr("1 minute")
		end
	end

	nl:setText(text)
end

function XPAnalyser:pushGraphSample()
	if not XPAnalyser.window or not XPAnalyser.window.contentsPanel then
		return
	end

	local panel = XPAnalyser.window.contentsPanel.graphPanel

	if not panel then
		return
	end

	XPAnalyser:refreshXpRatesFromSession()

	local xpHr = tonumber(XPAnalyser.xpHour) or 0

	analyserUIGraphPushValue(panel, math.max(0, math.floor(xpHr + 0.5)))
end

function XPAnalyser:checkExpHour()
	local player = g_game.getLocalPlayer()

	if not player or not XPAnalyser.window or XPAnalyser.window:isDestroyed() then
		return
	end

	local contentsPanel = XPAnalyser.window.contentsPanel

	if not contentsPanel then
		return
	end

	XPAnalyser:refreshXpRatesFromSession()

	if contentsPanel.xpHour then
		contentsPanel.xpHour:setText(formatXpShown(XPAnalyser.xpHour))
	end

	if contentsPanel.rawXpHour then
		contentsPanel.rawXpHour:setText(formatXpShown(XPAnalyser.rawXpHour))
	end

	local xpHr = tonumber(XPAnalyser.xpHour) or 0

	if xpHr > 0 then
		local curExp = tonumber(player:getExperience()) or 0
		local nextLevelExp = expForLevel(math.max(0, player:getLevel() + 1))
		local hoursLeft = (nextLevelExp - curExp) / xpHr
		local minutesLeft = math.floor(math.max(0, (hoursLeft - math.floor(hoursLeft)) * 60))

		hoursLeft = math.floor(hoursLeft)

		XPAnalyser:updateNextLevel(hoursLeft, minutesLeft)
	else
		XPAnalyser:updateNextLevel(0, 0)
	end

	updateXpTargetArrow()

	local pct = tonumber(player:getLevelPercent())

	if contentsPanel.percent then
		if pct ~= pct then
			pct = 0
		end

		local percentDisplay = math.floor(pct / 1000 * 10)

		contentsPanel.percent:setPercent(math.min(100, math.max(0, percentDisplay)))
	end

	XPAnalyser:updateTooltip()
end

function XPAnalyser:addRawXPGain(value, countForRate)
	XPAnalyser.rawXPGain = XPAnalyser.rawXPGain + value
	if countForRate ~= false and value > 0 then
		XPAnalyser.rawXpForRate = XPAnalyser.rawXpForRate + value
	end

	XPAnalyser:updateWindow(true)
end

function XPAnalyser:addXpGain(value, countForRate)
	XPAnalyser.xpGain = XPAnalyser.xpGain + value
	if countForRate ~= false and value > 0 then
		XPAnalyser.xpForRate = XPAnalyser.xpForRate + value
	end

	XPAnalyser:updateWindow(true)
end

function XPAnalyser:updateTooltip()
	local player = g_game.getLocalPlayer()

	if not player then
		return
	end

	local text = "Raw XP Gain: " .. formatMoney(XPAnalyser.rawXPGain)

	text = text .. "\nXP Gain: " .. formatMoney(XPAnalyser.xpGain)
	text = text .. "\nCurrent Raw XP Per Hour: " .. formatMoney(XPAnalyser.rawXpHour)
	text = text .. "\nCurrent XP Per Hour: " .. formatMoney(XPAnalyser.xpHour)
	text = text .. "\nTarget XP Per Hour: " .. (XPAnalyser.target and formatMoney(XPAnalyser.target) or "0")
	text = text .. "\n" .. formatMoney(expToAdvance(player:getLevel(), player:getExperience())) .. " XP until next level."

	local lp = tonumber(player:getLevelPercent()) or 0
	local percentToGo

	if lp >= 1000 then
		percentToGo = 100 - lp / 100
	else
		percentToGo = 100 - lp / 100
	end

	text = text .. "\nYou have " .. string.format("%.2f", math.max(0, percentToGo)) .. " percent to go."

	if XPAnalyser.window and not XPAnalyser.window:isDestroyed() then
		XPAnalyser.window:setTooltip(text)
	end
end

function onXPExtra(mousePosition, mode)
	if cancelNextRelease then
		cancelNextRelease = false

		return false
	end

	local rawXpVisible = XPAnalyser.window.contentsPanel.rawXpLabel:isVisible()
	local gaugeVisible = XPAnalyser.window.contentsPanel.xpBG:isVisible()
	local graphVisible = XPAnalyser.window.contentsPanel.graphPanel:isVisible()
	local menu = g_ui.createWidget("PopupMenu")

	menu:setGameMenu(true)

	if mode == "false" then
		menu:addOption(tr("Reset Data"), function()
			XPAnalyser:reset()
		end)
		menu:addSeparator()
		menu:addCheckBoxOption(tr("Show Raw XP"), function()
			XPAnalyser:setRawXPVisible(not rawXpVisible)
		end, "", rawXpVisible)
		menu:addSeparator()
		menu:addOption(tr("Set XP Per Hour Target"), function()
			XPAnalyser:openTargetConfig()
		end)
		menu:addCheckBoxOption(tr("XP Per Hour Gauge"), function()
			XPAnalyser:setGaugeVisible(not gaugeVisible)
		end, "", gaugeVisible)
		menu:addCheckBoxOption(tr("XP Per Hour Graph"), function()
			XPAnalyser:setGraphVisible(not graphVisible)
		end, "", graphVisible)
		menu:display(mousePosition)

		return true
	end

	if mode == "gaude" then
		menu:addOption(tr("Set XP Per Hour Target"), function()
			XPAnalyser:openTargetConfig()
		end)
		menu:addCheckBoxOption(tr("XP Per Hour Gauge"), function()
			XPAnalyser:setGaugeVisible(not gaugeVisible)
		end, "", gaugeVisible)
	end

	if mode == "graph" then
		menu:addCheckBoxOption(tr("XP Per Hour Graph"), function()
			XPAnalyser:setGraphVisible(not graphVisible)
		end, "", graphVisible)
	end

	menu:display(mousePosition)

	return true
end

function XPAnalyser:checkAnchos()
	if XPAnalyser.window.contentsPanel.rawXpLabel:isVisible() then
		XPAnalyser.window.contentsPanel.xpLabel:addAnchor(AnchorTop, "rawXpLabel", AnchorBottom)
		XPAnalyser.window.contentsPanel.xpGain:addAnchor(AnchorTop, "rawXpGain", AnchorBottom)
		XPAnalyser.window.contentsPanel.xpLabel:setMarginTop(4)
		XPAnalyser.window.contentsPanel.xpGain:setMarginTop(4)
		XPAnalyser.window:setHeight(254)
		XPAnalyser.window:getChildById("bottomResizeBorder"):setMaximum(254)
	else
		XPAnalyser.window.contentsPanel.xpLabel:setMarginTop(-2)
		XPAnalyser.window.contentsPanel.xpLabel:addAnchor(AnchorTop, "topParent", AnchorBottom)
		XPAnalyser.window.contentsPanel.xpGain:addAnchor(AnchorTop, "xpLabel", AnchorTop)
		XPAnalyser.window.contentsPanel.xpGain:setMarginTop(0)
		XPAnalyser.window:setHeight(218)
		XPAnalyser.window:getChildById("bottomResizeBorder"):setMaximum(218)
	end

	if XPAnalyser.window.contentsPanel.rawXpHourLabel:isVisible() then
		XPAnalyser.window.contentsPanel.xpHourLabel:addAnchor(AnchorTop, "rawXpHourLabel", AnchorBottom)
		XPAnalyser.window.contentsPanel.xpHour:addAnchor(AnchorTop, "xpHourLabel", AnchorTop)
	else
		XPAnalyser.window.contentsPanel.xpHourLabel:addAnchor(AnchorTop, "xpLabel", AnchorBottom)
		XPAnalyser.window.contentsPanel.xpHour:addAnchor(AnchorTop, "xpHourLabel", AnchorTop)
	end

	if XPAnalyser.window.contentsPanel.xpBG:isVisible() then
		XPAnalyser.window.contentsPanel.graphPanel:addAnchor(AnchorTop, "separatorGauge", AnchorBottom)
	else
		XPAnalyser.window.contentsPanel.graphPanel:addAnchor(AnchorTop, "separatorPercent", AnchorBottom)
	end
end

function XPAnalyser:setRawXPVisible(value)
	XPAnalyser.window.contentsPanel.rawXpLabel:setVisible(value)
	XPAnalyser.window.contentsPanel.rawXpGain:setVisible(value)
	XPAnalyser.window.contentsPanel.rawXpHourLabel:setVisible(value)
	XPAnalyser.window.contentsPanel.rawXpHour:setVisible(value)

	XPAnalyser.rawXpVisible = value

	XPAnalyser:checkAnchos()
end

function XPAnalyser:setGaugeVisible(value)
	XPAnalyser.window.contentsPanel.xpBG:setVisible(value)
	XPAnalyser.window.contentsPanel.separatorGauge:setVisible(value)

	XPAnalyser.gaugeVisible = value

	XPAnalyser:checkAnchos()
end

function XPAnalyser:setGraphVisible(value)
	XPAnalyser.window.contentsPanel.graphPanel:setVisible(value)
	XPAnalyser.window.contentsPanel.graphHorizontal:setVisible(value)

	XPAnalyser.graphVisible = value

	XPAnalyser:checkAnchos()
end

function XPAnalyser:openTargetConfig()
	local window = configPopupWindow.xpButton

	window:show()
	window:setText("Set XP Per Hour Target")
	window.contentPanel.text:setImageSource("/images/game/analyzer/labels/xp")

	local function applyTarget()
		local value = window.contentPanel.xpTarget:getText()

		XPAnalyser.target = tonumber(value) or 0

		XPAnalyser:updateWindow(true)
		window:hide()
	end

	window.onEnter = applyTarget

	window.contentPanel.xpTarget:setText(tonumber(XPAnalyser.target) or "0")

	window.contentPanel.ok.onClick = applyTarget

	function window.contentPanel.cancel.onClick()
		window:hide()
	end
end

function XPAnalyser:gaugeIsVisible()
	return XPAnalyser.gaugeVisible
end

function XPAnalyser:graphIsVisible()
	return XPAnalyser.graphVisible
end

function XPAnalyser:rawXPIsVisible()
	return XPAnalyser.rawXpVisible
end

function XPAnalyser:getTarget()
	return XPAnalyser.target
end

function XPAnalyser:loadConfigJson()
	local config = {
		experienceGaugeTargetValue = 0,
		desiredXPGraphVisible = true,
		desiredExperienceGaugeVisible = true,
		showBaseXp = false
	}
	local player = g_game.getLocalPlayer()

	if not player then
		return
	end

	local file = "/characterdata/" .. player:getId() .. "/xpanalyser.json"

	if g_resources.fileExists(file) then
		local status, result = pcall(function()
			return json.decode(g_resources.readFileContents(file))
		end)

		if not status then
			return g_logger.error("Error while reading characterdata file. Details: " .. result)
		end

		config = result
	end

	XPAnalyser:setRawXPVisible(config.showBaseXp)
	XPAnalyser:setGaugeVisible(config.desiredExperienceGaugeVisible)
	XPAnalyser:setGraphVisible(config.desiredXPGraphVisible)

	XPAnalyser.target = config.experienceGaugeTargetValue

	XPAnalyser:checkAnchos()
end

function XPAnalyser:saveConfigJson()
	local config = {
		desiredExperienceGaugeVisible = XPAnalyser:gaugeIsVisible(),
		desiredXPGraphVisible = XPAnalyser:graphIsVisible(),
		experienceGaugeTargetValue = XPAnalyser:getTarget(),
		showBaseXp = XPAnalyser:rawXPIsVisible()
	}

	if not LoadedPlayer:isLoaded() then
		return
	end

	local file = "/characterdata/" .. LoadedPlayer:getId() .. "/xpanalyser.json"
	local status, result = pcall(function()
		return json.encode(config, 2)
	end)

	if not status then
		return g_logger.error("Error while saving profile XP Analyzer data. Data won't be saved. Details: " .. result)
	end

	if result:len() > 104857600 then
		return g_logger.error("Something went wrong, file is above 100MB, won't be saved")
	end

	g_resources.writeFileContents(file, result)
end
