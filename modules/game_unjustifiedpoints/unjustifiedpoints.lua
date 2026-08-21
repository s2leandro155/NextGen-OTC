-- chunkname: @/game_unjustifiedpoints/unjustifiedpoints.lua

unjustifiedPointsWindow = nil
unjustifiedPointsButton = nil
contentsPanel = nil
openPvpSituationsLabel = nil
currentSkullWidget = nil
skullTimeLabel = nil
dayProgressBar = nil
weekProgressBar = nil
monthProgressBar = nil
dayProgressBarBackground = nil
weekProgressBarBackground = nil
monthProgressBarBackground = nil
daySkullWidget = nil
weekSkullWidget = nil
monthSkullWidget = nil

function init()
	connect(g_game, {
		onGameStart = online,
		onGameEnd = offline,
		onUnjustifiedPointsChange = onUnjustifiedPointsChange,
		onOpenPvpSituationsChange = onOpenPvpSituationsChange,
		onAttackingCreatureChange = onAttack
	})
	connect(LocalPlayer, {
		onSkullChange = onSkullChange
	})

	unjustifiedPointsWindow = g_ui.loadUI("unjustifiedpoints")

	unjustifiedPointsWindow:disableResize()
	unjustifiedPointsWindow:setup()

	contentsPanel = unjustifiedPointsWindow:getChildById("contentsPanel")

	local titleWidget = unjustifiedPointsWindow:getChildById("miniwindowTitle")

	if titleWidget then
		titleWidget:setText("Unjustified Points")
	else
		unjustifiedPointsWindow:setText("Unjustified Points")
	end

	local iconWidget = unjustifiedPointsWindow:getChildById("miniwindowIcon")

	if iconWidget then
		iconWidget:setImageSource("/images/icons/icon-unjustified-points-widget")
	end

	openPvpSituationsLabel = contentsPanel:getChildById("openPvpSituationsLabel")
	currentSkullWidget = contentsPanel:getChildById("currentSkullWidget")
	skullTimeLabel = contentsPanel:getChildById("skullTimeLabel")
	dayProgressBar = contentsPanel:getChildById("dayProgressBar")
	weekProgressBar = contentsPanel:getChildById("weekProgressBar")
	monthProgressBar = contentsPanel:getChildById("monthProgressBar")
	dayProgressBarBackground = contentsPanel:getChildById("dayProgressBarBackground")
	weekProgressBarBackground = contentsPanel:getChildById("weekProgressBarBackground")
	monthProgressBarBackground = contentsPanel:getChildById("monthProgressBarBackground")
	daySkullWidget = contentsPanel:getChildById("daySkullWidget")
	weekSkullWidget = contentsPanel:getChildById("weekSkullWidget")
	monthSkullWidget = contentsPanel:getChildById("monthSkullWidget")

	local toggleFilterButton = unjustifiedPointsWindow:recursiveGetChildById("toggleFilterButton")

	if toggleFilterButton then
		toggleFilterButton:setVisible(false)
	end

	local contextMenuButton = unjustifiedPointsWindow:recursiveGetChildById("contextMenuButton")

	if contextMenuButton then
		contextMenuButton:setVisible(false)
	end

	local newWindowButton = unjustifiedPointsWindow:recursiveGetChildById("newWindowButton")

	if newWindowButton then
		newWindowButton:setVisible(false)
	end

	local lockButton = unjustifiedPointsWindow:recursiveGetChildById("lockButton")
	local minimizeButton = unjustifiedPointsWindow:recursiveGetChildById("minimizeButton")

	if lockButton and minimizeButton then
		lockButton:breakAnchors()
		lockButton:addAnchor(AnchorTop, minimizeButton:getId(), AnchorTop)
		lockButton:addAnchor(AnchorRight, minimizeButton:getId(), AnchorLeft)
		lockButton:setMarginRight(7)
		lockButton:setMarginTop(0)
	end

	if g_game.isOnline() then
		online()
	end
end

function terminate()
	disconnect(g_game, {
		onGameStart = online,
		onGameEnd = offline,
		onUnjustifiedPointsChange = onUnjustifiedPointsChange,
		onOpenPvpSituationsChange = onOpenPvpSituationsChange,
		onAttackingCreatureChange = onAttack
	})
	disconnect(LocalPlayer, {
		onSkullChange = onSkullChange
	})
	unjustifiedPointsWindow:destroy()

	if unjustifiedPointsButton then
		unjustifiedPointsButton:destroy()

		unjustifiedPointsButton = nil
	end
end

local function syncUnjustifiedPointsMainPanelButton()
	if SidebarWidgetOptions and SidebarWidgetOptions.syncToggleButton then
		SidebarWidgetOptions.syncToggleButton(unjustifiedPointsWindow, unjustifiedPointsButton, "Open Unjustified Points Window", "Close Unjustified Points Window")

		return
	end

	if not unjustifiedPointsButton or unjustifiedPointsButton:isDestroyed() then
		return
	end

	local on = false

	if unjustifiedPointsWindow and not unjustifiedPointsWindow:isDestroyed() then
		on = unjustifiedPointsWindow:isVisible()
	end

	unjustifiedPointsButton:setOn(on)

	if unjustifiedPointsButton.setTooltip then
		unjustifiedPointsButton:setTooltip(tr(on and "Close Unjustified Points Window" or "Open Unjustified Points Window"))
	end
end

function onMiniWindowOpen()
	syncUnjustifiedPointsMainPanelButton()
end

function onMiniWindowClose()
	syncUnjustifiedPointsMainPanelButton()
end

function toggle()
	if unjustifiedPointsWindow:isVisible() then
		unjustifiedPointsWindow:closeAndForgetLayout()
	else
		if not unjustifiedPointsWindow:getParent() then
			local panel = modules.game_interface.findContentPanelAvailable(unjustifiedPointsWindow, unjustifiedPointsWindow:getMinimumHeight())

			if not panel then
				return
			end

			panel:addChild(unjustifiedPointsWindow)
		end

		unjustifiedPointsWindow:open()
		unjustifiedPointsWindow:saveParent()
	end

	syncUnjustifiedPointsMainPanelButton()
end

function online()
	if g_game.getFeature(GameUnjustifiedPoints) and not unjustifiedPointsButton then
		unjustifiedPointsButton = modules.game_mainpanel.addToggleButton("unjustifiedPointsButton", tr("Open Unjustified Points Window"), "/images/options/button_unjustified", toggle)

		unjustifiedPointsWindow:setupOnStart()
		syncUnjustifiedPointsMainPanelButton()
	end

	refresh()
	addEvent(function()
		if g_game.isOnline() and g_game.getFeature(GameUnjustifiedPoints) then
			refresh()
		end
	end, 1)
	addEvent(function()
		if g_game.isOnline() and g_game.getFeature(GameUnjustifiedPoints) then
			refresh()
		end
	end, 10)
end

function offline()
	if g_game.getFeature(GameUnjustifiedPoints) then
		if unjustifiedPointsWindow and unjustifiedPointsWindow.save then
			unjustifiedPointsWindow:saveSelfIndex()
		end

		if not SidebarPersistence or not SidebarPersistence.lastSessionActive then
			unjustifiedPointsWindow:setParent(nil, true)
		end
	end
end

function refresh()
	local unjustifiedPoints = g_game.getUnjustifiedPoints()

	onUnjustifiedPointsChange(unjustifiedPoints)

	local localPlayer = g_game.getLocalPlayer()

	if localPlayer then
		onSkullChange(localPlayer, localPlayer:getSkull())
	end

	onOpenPvpSituationsChange(g_game.getOpenPvpSituations())
end

local function setSkullWidgetIcon(widget, skullId)
	local imagePath, clip = getSkullHudImagePath(skullId)

	if not imagePath then
		widget:setIcon("")

		return
	end

	widget:setIcon(imagePath)

	if clip then
		widget:setIconClip(torect(clip))
	end
end

function onSkullChange(localPlayer, skull)
	if not localPlayer:isLocalPlayer() then
		return
	end

	if skull == SkullRed or skull == SkullBlack then
		setSkullWidgetIcon(currentSkullWidget, skull)
		currentSkullWidget:setTooltip("Remaining skull time")
	else
		currentSkullWidget:setIcon("")
		currentSkullWidget:setTooltip("You have no skull")
	end

	local nextSkull = getNextSkullId(skull)

	setSkullWidgetIcon(daySkullWidget, nextSkull)
	setSkullWidgetIcon(weekSkullWidget, nextSkull)
	setSkullWidgetIcon(monthSkullWidget, nextSkull)
end

function onOpenPvpSituationsChange(amount)
	local validAmount = tonumber(amount) or 0

	openPvpSituationsLabel:setText("Open: " .. validAmount)
end

local function getImageByKills(kills, maxKills, period)
	if period == "day" then
		if kills <= maxKills / 3 then
			return "/images/ui/unjustified-points-bar-texture-green"
		elseif kills <= maxKills * 2 / 3 then
			return "/images/ui/unjustified-points-bar-texture-yellow"
		else
			return "/images/ui/unjustified-points-bar-texture-red"
		end
	elseif period == "week" then
		if kills <= math.floor(maxKills * 2 / 5) then
			return "/images/ui/unjustified-points-bar-texture-green"
		elseif kills <= math.floor(maxKills * 3 / 5) then
			return "/images/ui/unjustified-points-bar-texture-yellow"
		else
			return "/images/ui/unjustified-points-bar-texture-red"
		end
	elseif period == "month" then
		if kills <= math.floor(maxKills * 4 / 10) then
			return "/images/ui/unjustified-points-bar-texture-green"
		elseif kills <= math.floor(maxKills * 8 / 10) then
			return "/images/ui/unjustified-points-bar-texture-yellow"
		else
			return "/images/ui/unjustified-points-bar-texture-red"
		end
	end

	return "/images/ui/unjustified-points-bar-texture-green"
end

local function setProgressBarImage(progressBar, progressBarBackground, currentKills, maxKills, tooltip, period)
	progressBar:setTooltip(tooltip)

	if progressBarBackground then
		progressBarBackground:setTooltip(tooltip)
	end

	if currentKills == 0 then
		progressBar:setImageSource("")
		progressBar:setVisible(false)

		return
	end

	progressBar:setVisible(true)

	local percentage = currentKills / maxKills
	local backgroundWidth = progressBarBackground:getWidth()
	local foregroundWidth = math.floor(backgroundWidth * percentage)

	progressBar:breakAnchors()
	progressBar:addAnchor(AnchorTop, progressBarBackground:getId(), AnchorTop)
	progressBar:addAnchor(AnchorLeft, progressBarBackground:getId(), AnchorLeft)
	progressBar:setWidth(foregroundWidth)
	progressBar:setHeight(progressBarBackground:getHeight() - 2)
	progressBar:setMarginTop(1)
	progressBar:setMarginBottom(1)

	local imagePath = getImageByKills(currentKills, maxKills, period)

	progressBar:setImageSource(imagePath)
	progressBar:setImageBorder(1)
	progressBar:setImageBorderTop(1)
	progressBar:setImageBorderBottom(1)
end

local function isUnjustifiedPointsFreshState(up)
	return (up.skullTime or 0) == 0 and (up.killsDay or 0) == 0 and (up.killsDayRemaining or 0) == 0 and (up.killsWeek or 0) == 0 and (up.killsWeekRemaining or 0) == 0 and (up.killsMonth or 0) == 0 and (up.killsMonthRemaining or 0) == 0
end

function onUnjustifiedPointsChange(unjustifiedPoints)
	unjustifiedPoints = unjustifiedPoints or {}

	if unjustifiedPoints.skullTime and unjustifiedPoints.skullTime > 0 then
		skullTimeLabel:setText(unjustifiedPoints.skullTime .. " days")
		skullTimeLabel:setTooltip("Remaining skull time")
	else
		skullTimeLabel:setText("")
		skullTimeLabel:setTooltip("")
	end

	if isUnjustifiedPointsFreshState(unjustifiedPoints) then
		local tipDay = "Unjustified points gained during the last 24 hours."
		local tipWeek = "Unjustified points gained during the last 7 days."
		local tipMonth = "Unjustified points gained during the last 30 days."

		setProgressBarImage(dayProgressBar, dayProgressBarBackground, 0, 7, tipDay, "day")
		setProgressBarImage(weekProgressBar, weekProgressBarBackground, 0, 49, tipWeek, "week")
		setProgressBarImage(monthProgressBar, monthProgressBarBackground, 0, 210, tipMonth, "month")

		return
	end

	local localPlayer = g_game.getLocalPlayer()
	local hasRedBlackSkull = false

	if localPlayer then
		local sk = localPlayer:getSkull()

		hasRedBlackSkull = sk == SkullRed or sk == SkullBlack
	end

	local maxDayKills = hasRedBlackSkull and 14 or 7
	local maxWeekKills = hasRedBlackSkull and 98 or 49
	local maxMonthKills = hasRedBlackSkull and 420 or 210
	local remDay = unjustifiedPoints.killsDayRemaining
	local remWeek = unjustifiedPoints.killsWeekRemaining
	local remMonth = unjustifiedPoints.killsMonthRemaining

	if remDay == nil then
		remDay = maxDayKills
	end

	if remWeek == nil then
		remWeek = maxWeekKills
	end

	if remMonth == nil then
		remMonth = maxMonthKills
	end

	local actualDayKills = math.max(0, maxDayKills - remDay)
	local actualWeekKills = math.max(0, maxWeekKills - remWeek)
	local actualMonthKills = math.max(0, maxMonthKills - remMonth)
	local dayTooltip = string.format("Unjustified points gained during the last 24 hours.\n%i kill%s left.", remDay, remDay == 1 and "" or "s")

	setProgressBarImage(dayProgressBar, dayProgressBarBackground, actualDayKills, maxDayKills, dayTooltip, "day")

	local weekTooltip = string.format("Unjustified points gained during the last 7 days.\n%i kill%s left.", remWeek, remWeek == 1 and "" or "s")

	setProgressBarImage(weekProgressBar, weekProgressBarBackground, actualWeekKills, maxWeekKills, weekTooltip, "week")

	local monthTooltip = string.format("Unjustified points gained during the last 30 days.\n%i kill%s left.", remMonth, remMonth == 1 and "" or "s")

	setProgressBarImage(monthProgressBar, monthProgressBarBackground, actualMonthKills, maxMonthKills, monthTooltip, "month")
end
