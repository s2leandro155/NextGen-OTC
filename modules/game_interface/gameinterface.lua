-- chunkname: @/game_interface/gameinterface.lua
local closeCountWindow -- forward declaration (used before its declaration in the decompiled file)

gameRootPanel = nil
gameMapPanel = nil
gameMainRightPanel = nil
gameRightPanel = nil
gameRightExtraPanel = nil
gameLeftPanel = nil
gameLeftExtraPanel = nil
gameLeftExtraPanels = {}
gameRightExtraPanels = {}
gameActionBarLeftPanel = nil
gameActionBarRightPanel = nil
mapVerticalLineLeft = nil
mapVerticalLineRight = nil
gameLeftTopPanel = nil
gameRightTopPanel = nil
gameSelectedPanel = nil
panelsList = {}
panelsRadioGroup = nil
gameTopPanel = nil
gameBottomStatsBarPanel = nil
gameBottomPanel = nil
showTopMenuButton = nil
logoutButton = nil
logOutMainButton = nil
mouseGrabberWidget = nil
countWindow = nil
logoutWindow = nil
exitWindow = nil

local function clearExitWindow()
	if not exitWindow then
		return
	end

	if not exitWindow:isDestroyed() then
		exitWindow:destroy()
	end

	exitWindow = nil
end

bottomSplitter = nil
limitedZoom = false
currentViewMode = 0
leftIncreaseSidePanels = nil
leftDecreaseSidePanels = nil
rightIncreaseSidePanels = nil
rightDecreaseSidePanels = nil
hookedMenuOptions = {}

local SIDEBAR_COLUMN_WIDTH = 178
local SIDEBAR_INNER_BORDER_GAP = 2
local ABSOLUTE_MIN_MAP_WIDTH = 160
local DEFAULT_WINDOW_MIN_WIDTH = 1020
local DEFAULT_WINDOW_MIN_HEIGHT = 644
local MAX_HORIZONTAL_SIDEBAR_COLUMNS = 2
local VERTICAL_COLUMNS_UNDER_HORIZONTAL = 2
local pendingSidebarLayoutEvent
local lastStopAction = 0
local supplyStashMenuEnabled = false
local attackTargetOutlineEvent
local outlinedAttackCreature
local mobileConfig = {
	mobileHeightShortcuts = 0,
	mobileHeightJoystick = 0,
	mobileWidthShortcuts = 0,
	mobileWidthJoystick = 0
}

local function updateAttackTargetOutline()
	attackTargetOutlineEvent = nil

	local creature = g_game.isOnline() and g_game.getAttackingCreature() or nil

	if outlinedAttackCreature and outlinedAttackCreature ~= creature and outlinedAttackCreature.hideStaticSquare then
		outlinedAttackCreature:hideStaticSquare()
	end

	outlinedAttackCreature = creature

	if creature and creature.showStaticSquare then
		-- Reapply it because creature-mark packets from the server can clear the
		-- static square even though the attack itself is still active.
		creature:showStaticSquare("#ff0000")
	end

	attackTargetOutlineEvent = scheduleEvent(updateAttackTargetOutline, 100)
end

function onAttackingCreatureChange(creature, oldCreature)
	if oldCreature and oldCreature ~= creature and oldCreature.hideStaticSquare then
		oldCreature:hideStaticSquare()
	end

	outlinedAttackCreature = creature

	if creature and creature.showStaticSquare then
		creature:showStaticSquare("#ff0000")
	end
end

function init()
	g_ui.importStyle("styles/countwindow")
	g_ui.importStyle("styles/stowContainerConfirmWindow")
	connect(g_game, {
		onGameStart = onGameStart,
		onGameEnd = onGameEnd,
		onAttackingCreatureChange = onAttackingCreatureChange,
		onLoginAdvice = onLoginAdvice,
		onInspectionState = onInspectionState,
		onSpecialContainer = onSpecialContainer
	}, true)
	updateAttackTargetOutline()
	connect(Container, {
		onOpen = onDepotContainerOpen
	})
	connect(g_app, {
		onRun = load
	})
	connect(g_app, {
		onExit = save
	})

	gameRootPanel = g_ui.displayUI("gameinterface")

	gameRootPanel:hide()
	gameRootPanel:lower()

	function gameRootPanel.onGeometryChange()
		updateStretchShrink()
		scheduleSidebarLayoutUpdate()
	end

	mouseGrabberWidget = gameRootPanel:getChildById("mouseGrabber")
	mouseGrabberWidget.onMouseRelease = onMouseGrabberRelease
	bottomSplitter = gameRootPanel:getChildById("bottomSplitter")
	gameMapPanel = gameRootPanel:getChildById("gameMapPanel")

	function gameMapPanel.onMouseWheel(widget, mousePos, direction)
		requestSmoothZoom(direction == MouseWheelUp and -2 or 2)

		return true
	end

	gameMainRightPanel = gameRootPanel:getChildById("gameMainRightPanel")
	gameRightPanel = gameRootPanel:getChildById("gameRightPanel")
	gameRightExtraPanel = gameRootPanel:getChildById("gameRightExtraPanel")
	gameLeftExtraPanel = gameRootPanel:getChildById("gameLeftExtraPanel")
	gameLeftExtraPanels = {
		gameLeftExtraPanel
	}
	gameRightExtraPanels = {
		gameRightExtraPanel
	}
	gameActionBarLeftPanel = gameRootPanel:getChildById("gameActionBarLeftPanel")
	gameActionBarRightPanel = gameRootPanel:getChildById("gameActionBarRightPanel")
	mapVerticalLineLeft = gameRootPanel:getChildById("mapVerticalLineLeft")
	mapVerticalLineRight = gameRootPanel:getChildById("mapVerticalLineRight")
	gameLeftPanel = gameRootPanel:getChildById("gameLeftPanel")
	gameLeftTopPanel = gameRootPanel:getChildById("gameLeftTopPanel")
	gameRightTopPanel = gameRootPanel:getChildById("gameRightTopPanel")
	gameBottomPanel = gameRootPanel:getChildById("gameBottomPanel")
	gameTopPanel = gameRootPanel:getChildById("gameTopPanel")
	gameBottomStatsBarPanel = gameRootPanel:getChildById("gameBottomStatsBarPanel")
	leftIncreaseSidePanels = gameRootPanel:getChildById("leftIncreaseSidePanels")
	leftDecreaseSidePanels = gameRootPanel:getChildById("leftDecreaseSidePanels")
	rightIncreaseSidePanels = gameRootPanel:getChildById("rightIncreaseSidePanels")
	rightDecreaseSidePanels = gameRootPanel:getChildById("rightDecreaseSidePanels")

	updateSidebarControlStates()

	if gameMainRightPanel and not gameMainRightPanel:isDestroyed() then
		gameMainRightPanel:raise()
	end

	syncMainRightPanelClearance()

	if g_platform.isMobile() then
		gameRightPanel:setMarginBottom(mobileConfig.mobileHeightShortcuts)
		gameLeftPanel:setMarginBottom(mobileConfig.mobileHeightJoystick)
	end

	panelsList = {
		{
			panel = gameRightPanel,
			checkbox = gameRootPanel:getChildById("gameSelectRightColumn")
		},
		{
			panel = gameRightExtraPanel,
			checkbox = gameRootPanel:getChildById("gameSelectRightExtraColumn")
		},
		{
			panel = gameLeftPanel,
			checkbox = gameRootPanel:getChildById("gameSelectLeftColumn")
		},
		{
			panel = gameLeftExtraPanel,
			checkbox = gameRootPanel:getChildById("gameSelectLeftExtraColumn")
		}
	}
	panelsRadioGroup = UIRadioGroup.create()

	for k, v in pairs(panelsList) do
		panelsRadioGroup:addWidget(v.checkbox)
		connect(v.checkbox, {
			onCheckChange = onSelectPanel
		})
	end

	panelsRadioGroup:selectWidget(panelsList[1].checkbox)

	local function onSidebarVisibilityChange()
		scheduleSidebarLayoutUpdate()
	end

	connect(gameLeftPanel, {
		onVisibilityChange = onSidebarVisibilityChange
	})
	connect(gameLeftExtraPanel, {
		onVisibilityChange = onSidebarVisibilityChange
	})
	connect(gameRightPanel, {
		onVisibilityChange = onSidebarVisibilityChange
	})
	connect(gameRightExtraPanel, {
		onVisibilityChange = onSidebarVisibilityChange
	})
	connect(gameLeftTopPanel, {
		onVisibilityChange = onSidebarVisibilityChange,
		onGeometryChange = onSidebarVisibilityChange
	})
	connect(gameRightTopPanel, {
		onVisibilityChange = onSidebarVisibilityChange,
		onGeometryChange = onSidebarVisibilityChange
	})

	logoutButton = modules.client_topmenu.addTopRightToggleButton("logoutButton", tr("Exit"), "/images/topbuttons/logout", tryLogout, true)
	showTopMenuButton = gameMapPanel:getChildById("showTopMenuButton")

	function showTopMenuButton.onClick()
		modules.client_topmenu.toggle()
	end

	bindKeys()

	if g_game.isOnline() then
		show()
	end

	StatsBar.init()
end

-- smooth game window zoom: animation towards the target via setFloatZoom (fractional crop in C++),
-- convergence to the exact target after releasing the key/wheel (no drift)
local smoothZoom = {
	target = nil,
	event = nil
}

local function smoothZoomStep()
	smoothZoom.event = nil

	if not gameMapPanel or gameMapPanel:isDestroyed() or not smoothZoom.target then
		smoothZoom.target = nil

		return
	end

	if not gameMapPanel.getFloatZoom then
		gameMapPanel:setZoom(math.floor(smoothZoom.target + 0.5))

		smoothZoom.target = nil

		return
	end

	local current = gameMapPanel:getFloatZoom()
	local diff = smoothZoom.target - current

	if math.abs(diff) < 0.03 then
		gameMapPanel:setFloatZoom(smoothZoom.target)

		smoothZoom.target = nil

		return
	end

	gameMapPanel:setFloatZoom(current + diff * 0.3)

	smoothZoom.event = scheduleEvent(smoothZoomStep, 16)
end

function requestSmoothZoom(delta)
	if not gameMapPanel then
		return
	end

	if g_game.isZoomEnabled and not g_game.isZoomEnabled() then
		return
	end

	local base = smoothZoom.target

	if not base then
		base = gameMapPanel.getFloatZoom and gameMapPanel:getFloatZoom() or gameMapPanel:getZoom()
	end

	smoothZoom.target = math.max(gameMapPanel:getMaxZoomIn(), math.min(gameMapPanel:getMaxZoomOut(), base + delta))

	if not smoothZoom.event then
		smoothZoom.event = scheduleEvent(smoothZoomStep, 16)
	end
end

function bindKeys()
	gameRootPanel:setAutoRepeatDelay(50)
	g_keyboard.bindKeyPress("Ctrl+=", function()
		requestSmoothZoom(-1)
	end, gameRootPanel)
	g_keyboard.bindKeyPress("Ctrl+-", function()
		requestSmoothZoom(1)
	end, gameRootPanel)
	Keybind.new("Movement", "Stop All Actions", "Escape", "", true)
	Keybind.bind("Movement", "Stop All Actions", {
		{
			type = KEY_PRESS,
			callback = function()
				if lastStopAction + 50 > g_clock.millis() then
					return
				end

				lastStopAction = g_clock.millis()

				g_game.cancelAttackAndFollow()
			end
		}
	}, gameRootPanel)
	Keybind.new("Misc", "Logout", "Ctrl+L", "Ctrl+Q")
	Keybind.bind("Misc", "Logout", {
		{
			type = KEY_PRESS,
			callback = function()
				tryLogout(false)
			end
		}
	}, gameRootPanel)
	Keybind.new("Misc", "Clear oldest message from Game Window", "Alt+W", "")
	Keybind.bind("Misc", "Clear oldest message from Game Window", {
		{
			type = KEY_DOWN,
			callback = function()
				modules.game_textmessage.clearOldestMessage()

				return false
			end
		}
	}, gameRootPanel)

	if modules.game_textmessage and modules.game_textmessage.bindClearOldestHotkey then
		modules.game_textmessage.bindClearOldestHotkey(gameRootPanel)
	end

	g_keyboard.bindKeyDown("Ctrl+.", nextViewMode, gameRootPanel)
end

function terminate()
	if attackTargetOutlineEvent then
		removeEvent(attackTargetOutlineEvent)
		attackTargetOutlineEvent = nil
	end
	if outlinedAttackCreature and outlinedAttackCreature.hideStaticSquare then
		outlinedAttackCreature:hideStaticSquare()
	end
	outlinedAttackCreature = nil
	StatsBar.terminate()
	hide()
	disconnect(g_app, {
		onRun = load
	})
	disconnect(g_app, {
		onExit = save
	})

	hookedMenuOptions = {}

	disconnect(g_game, {
		onGameStart = onGameStart,
		onGameEnd = onGameEnd,
		onAttackingCreatureChange = onAttackingCreatureChange,
		onLoginAdvice = onLoginAdvice,
		onInspectionState = onInspectionState,
		onSpecialContainer = onSpecialContainer
	})
	disconnect(Container, {
		onOpen = onDepotContainerOpen
	})

	for k, v in pairs(panelsList) do
		disconnect(v.checkbox, {
			onCheckChange = onSelectPanel
		})
	end

	if gameLeftExtraPanels then
		for index = #gameLeftExtraPanels, 2, -1 do
			local panel = gameLeftExtraPanels[index]

			if panel and not panel:isDestroyed() then
				local checkbox = gameRootPanel and gameRootPanel:recursiveGetChildById(panel:getId() .. "Select")

				if checkbox and not checkbox:isDestroyed() then
					if panelsRadioGroup then
						panelsRadioGroup:removeWidget(checkbox)
					end

					checkbox:destroy()
				end

				panel:destroy()
			end
		end
	end

	if gameRightExtraPanels then
		for index = #gameRightExtraPanels, 2, -1 do
			local panel = gameRightExtraPanels[index]

			if panel and not panel:isDestroyed() then
				local checkbox = gameRootPanel and gameRootPanel:recursiveGetChildById(panel:getId() .. "Select")

				if checkbox and not checkbox:isDestroyed() then
					if panelsRadioGroup then
						panelsRadioGroup:removeWidget(checkbox)
					end

					checkbox:destroy()
				end

				panel:destroy()
			end
		end
	end

	if not g_platform.isMobile() then
		g_window.setMinimumSize({
			width = DEFAULT_WINDOW_MIN_WIDTH,
			height = DEFAULT_WINDOW_MIN_HEIGHT
		})
	end

	logoutButton:destroy()
	gameRootPanel:destroy()
	Keybind.delete("Movement", "Stop All Actions")
	Keybind.delete("Misc", "Logout")
	Keybind.delete("Misc", "Clear oldest message from Game Window")
end

function onGameStart()
	if gameMapPanel and gameMapPanel.resetDisplayReady then
		gameMapPanel:resetDisplayReady()
	end

	show()

	if g_ui.setWidgetLeakCheckPaused then
		g_ui.setWidgetLeakCheckPaused(true)
	end

	updateSidebarControlStates()

	if g_platform.isMobile() then
		gameRightPanel:setMarginBottom(mobileConfig.mobileHeightShortcuts)
		gameLeftPanel:setMarginBottom(mobileConfig.mobileHeightJoystick)
	end

	addEvent(function()
		for _, container in pairs(g_game.getContainers()) do
			if container.isInDepot and container:isInDepot() then
				supplyStashMenuEnabled = true

				break
			end
		end
	end)
end

local function cancelPendingSidebarLayoutUpdate()
	if pendingSidebarLayoutEvent then
		removeEvent(pendingSidebarLayoutEvent)

		pendingSidebarLayoutEvent = nil
	end
end

function onGameEnd()
	supplyStashMenuEnabled = false

	cancelPendingSidebarLayoutUpdate()

	creatureInspectionFlags = {}

	save()
	hide()
	addEvent(function()
		flushGameSettingsOnLogout()

		if g_ui.setWidgetLeakCheckPaused then
			g_ui.setWidgetLeakCheckPaused(false)
		end
	end)
end

function show()
	connect(g_app, {
		onClose = tryExit
	})

	if gameMainRightPanel and not gameMainRightPanel:isDestroyed() then
		local layoutSettings = g_settings.getNode("game_interface")
		local savedHeight = layoutSettings and tonumber(layoutSettings.mainRightPanelHeight)

		if savedHeight and savedHeight > 0 then
			gameMainRightPanel:setHeight(savedHeight)
		end
	end

	syncMainRightPanelClearance()
	gameRootPanel:show()
	applyGameInterfaceLayoutSettings()
	gameRootPanel:focus()
	gameMapPanel:followCreature(g_game.getLocalPlayer())
	updateStretchShrink()
	logoutButton:setTooltip(tr("Logout"))
	setupViewMode(0)

	if g_platform.isMobile() then
		mobileConfig.mobileWidthJoystick = modules.game_joystick.getPanel():getWidth()
		mobileConfig.mobileWidthShortcuts = modules.game_shortcuts.getPanel():getWidth()
		mobileConfig.mobileHeightJoystick = modules.game_joystick.getPanel():getHeight()
		mobileConfig.mobileHeightShortcuts = modules.game_shortcuts.getPanel():getHeight()

		setupViewMode(1)
		setupViewMode(2)
	end

	addEvent(function()
		if not limitedZoom or g_game.isGM() then
			gameMapPanel:setMaxZoomOut(513)
			gameMapPanel:setLimitVisibleRange(false)
		else
			gameMapPanel:setMaxZoomOut(11)
			gameMapPanel:setLimitVisibleRange(true)
		end
	end)
end

function hide()
	setupViewMode(0)
	disconnect(g_app, {
		onClose = tryExit
	})
	logoutButton:setTooltip(tr("Exit"))

	if logoutWindow then
		logoutWindow:destroy()

		logoutWindow = nil
	end

	clearExitWindow()

	if countWindow then
		closeCountWindow()
	end

	gameRootPanel:hide()
	modules.client_background.show()
end

CHAT_MIN_HEIGHT = 98
COOLDOWN_PANEL_HEIGHT = 26

local MIN_GAME_MAP_HEIGHT = 300
local BOTTOM_STATS_BAR_GAP_BELOW_ACTION_BAR = 4
local CENTER_TO_SIDE_DOCK_GAP = 0
local MAP_ASPECT_RATIO = 1.3636363636363635

local function getMapAspectRatio()
	if gameMapPanel and not gameMapPanel:isDestroyed() then
		local dim = gameMapPanel:getVisibleDimension()

		if dim and dim.width and dim.height and dim.height > 0 then
			return dim.width / dim.height
		end
	end

	return MAP_ASPECT_RATIO
end

local function getMapContentSize()
	if not gameMapPanel or gameMapPanel:isDestroyed() then
		return 0, 0
	end

	local rect = gameMapPanel:getPaddingRect()

	return rect.width, rect.height
end

local function getMinimumMapContentHeight()
	local contentWidth, contentHeight = getMapContentSize()

	if contentWidth <= 0 or contentHeight <= 0 then
		return MIN_GAME_MAP_HEIGHT
	end

	local aspectMinHeight = math.ceil(contentWidth / getMapAspectRatio())

	if contentHeight < aspectMinHeight then
		return MIN_GAME_MAP_HEIGHT
	end

	return math.max(MIN_GAME_MAP_HEIGHT, aspectMinHeight)
end

local function getRequiredCenterWidth()
	return ABSOLUTE_MIN_MAP_WIDTH
end

local function getBottomSplitterMaxMarginBottom(parentH)
	local minM = getBottomSplitterMinMarginBottom()

	return math.max(minM, parentH - getMinimumMapContentHeight())
end

local function getBottomActionBarsDockHeight()
	if not gameBottomPanel then
		return 0
	end

	local height = 0

	for barId = 1, 3 do
		local bar = gameBottomPanel:getChildById("actionBar" .. barId)

		if bar and not bar:isDestroyed() and bar:isVisible() then
			height = height + math.max(0, bar:getHeight())
		end
	end

	return height
end

local function getBottomActionBarsCount()
	if not gameBottomPanel then
		return 0
	end

	local count = 0

	for barId = 1, 3 do
		local bar = gameBottomPanel:getChildById("actionBar" .. barId)

		if bar and not bar:isDestroyed() and bar:isVisible() and bar:getHeight() > 0 then
			count = count + 1
		end
	end

	return count
end

local function getCooldownVisibleExtraHeight()
	local cd = modules.game_cooldown and modules.game_cooldown.cooldownWindow

	if not cd or cd:isDestroyed() or not cd:isVisible() or cd:getHeight() <= 0 then
		return 0
	end

	return COOLDOWN_PANEL_HEIGHT
end

local function getBottomStatsBarHeight()
	if not gameBottomStatsBarPanel or gameBottomStatsBarPanel:isDestroyed() then
		return 0
	end

	if g_settings.getString("statsbar_placement") ~= "bottom" then
		return 0
	end

	if not gameBottomStatsBarPanel:isVisible() then
		return 0
	end

	local h = gameBottomStatsBarPanel:getHeight()

	return h > 0 and h or 0
end

function getBottomSplitterMinMarginBottom()
	local cooldownH = getCooldownVisibleExtraHeight()
	local statsH = getBottomStatsBarHeight()
	local actionH = getBottomActionBarsDockHeight()
	local barCount = getBottomActionBarsCount()
	local physicalTotal = actionH - barCount

	if cooldownH > 0 then
		physicalTotal = physicalTotal + cooldownH + 1
	end

	if statsH > 0 then
		physicalTotal = physicalTotal + statsH - 3
	end

	if physicalTotal < 0 then
		physicalTotal = 0
	end

	return CHAT_MIN_HEIGHT + physicalTotal
end

function applyBottomSplitterLayoutHeight()
	if not bottomSplitter then
		return
	end

	local minM = getBottomSplitterMinMarginBottom()

	if minM > bottomSplitter:getMarginBottom() then
		bottomSplitter:setMarginBottom(minM)
	end

	bottomSplitterOnGeometryChange(bottomSplitter)
end

function maximizeMapAfterSidebarRemoval()
	if currentViewMode ~= 0 then
		return
	end

	if modules.client_options.getOption("dontStretchShrink") then
		return
	end

	if not gameMapPanel or gameMapPanel:isDestroyed() then
		return
	end

	if not bottomSplitter or bottomSplitter:isDestroyed() then
		return
	end

	local contentWidth, contentHeight = getMapContentSize()
	local aspect = getMapAspectRatio()

	if contentWidth <= 0 or contentHeight <= 0 or aspect <= 0 then
		return
	end

	local desiredHeight = math.floor(contentWidth / aspect)

	if desiredHeight <= contentHeight + 1 then
		return
	end

	local parent = bottomSplitter:getParent()
	local parentH = parent and parent:getHeight() or 0
	local minM = getBottomSplitterEffectiveMinMargin(parentH)
	local maxM = getBottomSplitterMaxMarginBottom(parentH)
	local current = bottomSplitter:getMarginBottom()
	local target = math.max(minM, math.min(current - (desiredHeight - contentHeight), maxM))

	if target < current then
		bottomSplitter:setMarginBottom(target)
		save()
	end
end

function syncMainRightPanelClearance()
	if not gameRightPanel or gameRightPanel:isDestroyed() then
		return
	end

	if not gameMainRightPanel or gameMainRightPanel:isDestroyed() then
		return
	end

	local mainHeight = gameMainRightPanel:getHeight() or 0

	if mainHeight < 0 then
		mainHeight = 0
	end

	if gameRightPanel:getPaddingTop() ~= mainHeight then
		gameRightPanel:setPaddingTop(mainHeight)
	end
end

function onMainRightPanelGeometryChange()
	syncMainRightPanelClearance()
end

function bottomSplitterCanUpdateMargin(splitter, newMargin)
	if modules.client_options.getOption("dontStretchShrink") then
		return splitter:getMarginBottom()
	end

	local parent = splitter:getParent()

	if not parent then
		return newMargin
	end

	local parentH = parent:getHeight()
	local minM = getBottomSplitterEffectiveMinMargin(parentH)
	local maxM = getBottomSplitterMaxMarginBottom(parentH)

	return math.max(math.min(newMargin, maxM), minM)
end

function bottomSplitterOnGeometryChange(splitter)
	local parent = splitter:getParent()

	if not parent then
		return
	end

	local parentH = parent:getHeight()
	local minM = getBottomSplitterEffectiveMinMargin(parentH)
	local maxM = getBottomSplitterMaxMarginBottom(parentH)
	local m = splitter:getMarginBottom()
	local clamped = math.min(math.max(m, minM), maxM)

	if clamped ~= m then
		splitter:setMarginBottom(clamped)
	end
end

function onBottomSplitterMouseRelease(splitter)
	if not splitter:isHovered() then
		if splitter.cursortype then
			g_mouse.popCursor(splitter.cursortype)
		end

		g_effects.fadeOut(splitter)

		splitter.hovering = false
	end

	addEvent(function()
		updateSidebarControlStates()
		save()
	end)
end

function save()
	local settings = g_settings.getNode("game_interface") or {}

	if bottomSplitter and not bottomSplitter:isDestroyed() then
		settings.splitterMarginBottom = bottomSplitter:getMarginBottom()
	end

	if gameMainRightPanel and not gameMainRightPanel:isDestroyed() then
		local h = gameMainRightPanel:getHeight()

		if h and h > 0 then
			settings.mainRightPanelHeight = h
		end
	end

	g_settings.setNode("game_interface", settings)
	g_settings.save()
end

function load()
	local settings = g_settings.getNode("game_interface")

	if settings then
		if settings.leftExtraPanelCount ~= nil then
			g_settings.set("leftExtraPanelCount", settings.leftExtraPanelCount)
		end

		if settings.rightExtraPanelCount ~= nil then
			g_settings.set("rightExtraPanelCount", settings.rightExtraPanelCount)
		end
	end
end

function applyGameInterfaceLayoutSettings()
	restoreSidebarColumnCounts()

	local settings = g_settings.getNode("game_interface")

	if settings and settings.splitterMarginBottom and bottomSplitter and not bottomSplitter:isDestroyed() then
		bottomSplitter:setMarginBottom(settings.splitterMarginBottom)
	end

	if bottomSplitter and not bottomSplitter:isDestroyed() then
		applyBottomSplitterLayoutHeight()
		bottomSplitterOnGeometryChange(bottomSplitter)
	end

	updateSidebarControlStates()
end

function onLoginAdvice(message)
	displayInfoBox(tr("For Your Information"), message)
end

function forceExit()
	g_game.cancelLogin()
	clearExitWindow()
	scheduleEvent(exit, 10)

	return true
end

function saveSidebarsBeforeLogout()
	if SidebarPersistence and SidebarPersistence.saveNow then
		SidebarPersistence.saveNow()
	end
end

function tryExit()
	if exitWindow and not exitWindow:isDestroyed() then
		exitWindow:raise()
		exitWindow:focus()

		return true
	end

	exitWindow = nil

	local function exitFunc()
		saveSidebarsBeforeLogout()
		g_game.safeLogout()
		forceExit()
	end

	local function logoutFunc()
		saveSidebarsBeforeLogout()
		g_game.safeLogout()
		clearExitWindow()
	end

	local function cancelFunc()
		clearExitWindow()
	end

	exitWindow = displayGeneralBox(tr("Warning"), tr("If you shut down the program, your character might stay in the game.\nClick on 'Logout' to ensure that you character leaves the game properly.\nClick on 'Exit' if you want to exit the program without logging out your character."), {
		{
			text = tr("Cancel"),
			callback = cancelFunc
		},
		{
			text = tr("Logout"),
			callback = logoutFunc
		},
		{
			text = tr("Exit"),
			callback = exitFunc
		},
		anchor = AnchorHorizontalCenter
	}, logoutFunc, cancelFunc)

	function exitWindow.onDestroy()
		exitWindow = nil
	end

	return true
end

function tryLogout(prompt)
	if type(prompt) ~= "boolean" then
		prompt = true
	end

	if not g_game.isOnline() then
		exit()

		return
	end

	if logoutWindow then
		return
	end

	local msg, yesCallback

	if not g_game.isConnectionOk() then
		msg = "Your connection is failing, if you logout now your character will be still online, do you want to force logout?"

		function yesCallback()
			saveSidebarsBeforeLogout()
			g_game.forceLogout()

			if logoutWindow then
				logoutWindow:destroy()

				logoutWindow = nil
			end
		end
	else
		msg = "Are you sure you want to logout?"

		function yesCallback()
			saveSidebarsBeforeLogout()
			g_game.safeLogout()

			if logoutWindow then
				logoutWindow:destroy()

				logoutWindow = nil
			end
		end
	end

	local function noCallback()
		logoutWindow:destroy()

		logoutWindow = nil
	end

	if prompt then
		logoutWindow = displayGeneralBox(tr("Logout"), tr(msg), {
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
	else
		yesCallback()
	end
end

function updateStretchShrink()
	if modules.client_options.getOption("dontStretchShrink") and not alternativeView then
		gameMapPanel:setVisibleDimension({
			height = 11,
			width = 15
		})
		bottomSplitter:setMarginBottom(bottomSplitter:getMarginBottom() + (gameMapPanel:getHeight() - 352) - 13)
	end
end

function onMouseGrabberRelease(self, mousePosition, mouseButton)
	if selectedThing == nil then
		return false
	end

	if mouseButton == MouseLeftButton then
		local clickedWidget = gameRootPanel:recursiveGetChildByPos(mousePosition, false)

		if clickedWidget then
			if selectedType == "use" then
				onUseWith(clickedWidget, mousePosition)
			elseif selectedType == "trade" then
				onTradeWith(clickedWidget, mousePosition)
			end
		end
	end

	selectedThing = nil

	g_mouse.popCursor("target")
	self:ungrabMouse()

	return true
end

function onUseWith(clickedWidget, mousePosition)
	if clickedWidget:getClassName() == "UIGameMap" then
		local tile = clickedWidget:getTile(mousePosition)

		if tile then
			if selectedThing:isFluidContainer() or selectedThing:isMultiUse() then
				g_game.useWith(selectedThing, tile:getTopMultiUseThing())
			else
				g_game.useWith(selectedThing, tile:getTopUseThing())
			end
		end
	elseif clickedWidget:getClassName() == "UIItem" and not clickedWidget:isVirtual() then
		g_game.useWith(selectedThing, clickedWidget:getItem())
	elseif clickedWidget:getClassName() == "UICreatureButton" then
		local creature = clickedWidget:getCreature()

		if creature then
			g_game.useWith(selectedThing, creature)
		end
	end
end

function onTradeWith(clickedWidget, mousePosition)
	if clickedWidget:getClassName() == "UIGameMap" then
		local tile = clickedWidget:getTile(mousePosition)

		if tile then
			g_game.requestTrade(selectedThing, tile:getTopCreature())
		end
	elseif clickedWidget:getClassName() == "UICreatureButton" then
		local creature = clickedWidget:getCreature()

		if creature then
			g_game.requestTrade(selectedThing, creature)
		end
	end
end

function startUseWith(thing)
	if not thing then
		return
	end

	if g_ui.isMouseGrabbed() then
		if selectedThing then
			selectedThing = thing
			selectedType = "use"
		end

		return
	end

	selectedType = "use"
	selectedThing = thing

	mouseGrabberWidget:grabMouse()
	g_mouse.pushCursor("target")
end

function startTradeWith(thing)
	if not thing then
		return
	end

	if g_ui.isMouseGrabbed() then
		if selectedThing then
			selectedThing = thing
			selectedType = "trade"
		end

		return
	end

	selectedType = "trade"
	selectedThing = thing

	mouseGrabberWidget:grabMouse()
	g_mouse.pushCursor("target")
end

function isMenuHookCategoryEmpty(category)
	if category then
		for _, opt in pairs(category) do
			if opt then
				return false
			end
		end
	end

	return true
end

function addMenuHook(category, name, callback, condition, shortcut)
	if not hookedMenuOptions[category] then
		hookedMenuOptions[category] = {}
	end

	hookedMenuOptions[category][name] = {
		callback = callback,
		condition = condition,
		shortcut = shortcut
	}
end

function removeMenuHook(category, name)
	if not name then
		hookedMenuOptions[category] = {}
	else
		hookedMenuOptions[category][name] = nil
	end
end

local function resolveHirelingUseThing(useThing, creatureThing)
	if creatureThing and creatureThing.isHireling and creatureThing:isHireling() then
		return creatureThing
	end

	return useThing
end

local function getMenuControlMode()
	if g_platform.isMobile() then
		return "mobile"
	end

	local classicControl = modules.client_options.getOption("classicControl")

	if classicControl == "classic" or classicControl == true then
		return "classic"
	elseif classicControl == "leftSmart" then
		return "leftSmart"
	end

	return "regular"
end

local function getLookMenuShortcut()
	if g_platform.isMobile() then
		return nil
	end

	return "(Shift)"
end

local function getOpenMenuShortcut()
	if g_platform.isMobile() then
		return nil
	end

	if getMenuControlMode() == "classic" then
		return "(Alt)"
	end

	return "(Ctrl)"
end

local function getTalkMenuShortcut()
	if g_platform.isMobile() then
		return nil
	end

	if getMenuControlMode() == "leftSmart" then
		return nil
	end

	return "(Alt)"
end

local function getAttackMenuShortcut()
	if g_platform.isMobile() then
		return nil
	end

	if getMenuControlMode() == "leftSmart" then
		return nil
	end

	return "(Alt)"
end

local function getUseMenuShortcut()
	if g_platform.isMobile() then
		return nil
	end

	if getMenuControlMode() == "regular" then
		return "(Ctrl)"
	end

	return nil
end

local function getUseWithMenuShortcut()
	if g_platform.isMobile() then
		return nil
	end

	local mode = getMenuControlMode()

	if mode == "classic" then
		return "(Alt)"
	elseif mode == "regular" then
		return "(Ctrl)"
	end

	return nil
end

local function getUseThingMenuShortcuts()
	return {
		open = getOpenMenuShortcut(),
		use = getUseMenuShortcut(),
		useWith = getUseWithMenuShortcut()
	}
end

local function addUseThingMenuOptions(menu, thing, shortcuts)
	shortcuts = shortcuts or getUseThingMenuShortcuts()

	local openShortcut = shortcuts.open
	local useShortcut = shortcuts.use
	local useWithShortcut = shortcuts.useWith

	if not thing then
		return
	end

	if thing.isCreature and thing:isCreature() and thing.isHireling and thing:isHireling() then
		menu:addOption(tr("Use"), function()
			g_game.useHireling(thing)
		end, useShortcut)

		if g_game.getFeature(GameBrowseField) and thing:getPosition().x ~= 65535 then
			menu:addOption(tr("Browse Field"), function()
				g_game.browseField(thing:getPosition())
			end)
		end

		return
	end

	if thing:isContainer() then
		if thing:getParentContainer() then
			menu:addOption(tr("Open"), function()
				g_game.open(thing, thing:getParentContainer())
			end, openShortcut)
			menu:addOption(tr("Open in new window"), function()
				g_game.open(thing)
			end)
		else
			menu:addOption(tr("Open"), function()
				g_game.open(thing)
			end, openShortcut)
		end
	elseif thing:isMultiUse() then
		menu:addOption(tr("Use with ..."), function()
			startUseWith(thing)
		end, useWithShortcut)
	else
		menu:addOption(tr("Use"), function()
			g_game.use(thing)
		end, useShortcut)
	end

	if thing:isRotateable() or thing:isPodium() then
		menu:addOption(tr("Rotate"), function()
			g_game.rotate(thing)
		end)
	end

	if thing:isPodium() then
		menu:addOption(tr("Customise Podium"), function()
			if modules.game_customisepodium then
				modules.game_customisepodium.requestConfigurePodium(thing)
			end
		end)
	end

	local function onWrapItem()
		g_game.wrap(thing)
	end

	if thing:isWrapable() then
		menu:addOption(tr("Wrap"), onWrapItem)
	end

	if thing:isUnwrapable() then
		menu:addOption(tr("Unwrap"), onWrapItem)
	end

	if g_game.getFeature(GameBrowseField) and thing:getPosition().x ~= 65535 then
		menu:addOption(tr("Browse Field"), function()
			g_game.browseField(thing:getPosition())
		end)
	end

	if thing:getId() == 19250 then
		menu:addOption(tr("Collect All"), function()
			g_game.sendRewardCollectAll(thing:getPosition(), thing:getId(), thing:getStackPos())
		end)
	end

	if thing:isLyingCorpse() and not thing:isPlayerCorpse() and g_game.getFeature(GameThingQuickLoot) and modules.game_quickloot and thing:getPosition().x ~= 65535 then
		menu.addOption(menu, tr("Loot corpse"), function()
			g_game.sendQuickLoot(1, thing)
		end)
	end
end

local function resolveMenuTilePosition(mapTilePos, lookThing, useThing, creatureThing)
	if mapTilePos and mapTilePos.x and mapTilePos.x ~= 65535 then
		return mapTilePos
	end

	for _, thing in ipairs({
		creatureThing,
		useThing,
		lookThing
	}) do
		if thing then
			local pos = thing:getPosition()

			if pos and pos.x ~= 65535 then
				return pos
			end
		end
	end

	return nil
end

local function normalizeInspectionFlag(flag)
	flag = flag or 0

	if flag == 2 or flag == 3 then
		return InspectionFlags and InspectionFlags.AskAndRevoke or 1
	end

	if flag == 6 or flag == 7 then
		return InspectionFlags and InspectionFlags.InspectAndRevoke or 5
	end

	if flag >= 9 and flag <= 11 then
		return InspectionFlags and InspectionFlags.AskAndAllow or 8
	end

	if flag >= 13 then
		return flag % 13
	end

	return flag
end

local function canInspectPlayer(flag)
	return flag == 4 or flag == 5 or flag == 12
end

local function canRevokeInspectMe(flag)
	return flag == 1 or flag == 5 or flag == 12
end

local function canAllowInspectMe(flag)
	return flag == (InspectionFlags and InspectionFlags.AskAndAllow or 8)
end

local function isLocalAllowAllInspectEnabled()
	if not modules.client_options or not modules.client_options.getOption then
		return false
	end

	return modules.client_options.getOption("allowInspect") == true
end

local creatureInspectionFlags = {}

local function syncCreatureInspectionFlag(creatureId, flag)
	creatureInspectionFlags[creatureId] = flag

	local creature = g_map.getCreatureById(creatureId)

	if creature and creature.setInspectionFlag then
		creature:setInspectionFlag(flag)
	end
end

local function getCreatureInspectionFlag(creatureThing)
	local creatureId = creatureThing:getId()

	if creatureInspectionFlags[creatureId] ~= nil then
		return creatureInspectionFlags[creatureId]
	end

	if creatureThing.getInspectionFlag then
		return creatureThing:getInspectionFlag()
	end

	return 0
end

local function predictInspectionFlagAfterAction(currentFlag, actionType)
	currentFlag = normalizeInspectionFlag(currentFlag)

	local inviteFlag = InspectionParseFlags and InspectionParseFlags.Invite or 1
	local revokeFlag = InspectionParseFlags and InspectionParseFlags.Revoke or 5
	local askFlag = InspectionParseFlags and InspectionParseFlags.Ask or 2
	local allowFlag = InspectionParseFlags and InspectionParseFlags.Allow or 3

	if actionType == inviteFlag then
		if canInspectPlayer(currentFlag) then
			return InspectionFlags and InspectionFlags.InspectAndRevoke or 5
		end

		return InspectionFlags and InspectionFlags.AskAndRevoke or 1
	end

	if actionType == revokeFlag then
		if canInspectPlayer(currentFlag) then
			return InspectionFlags and InspectionFlags.InspectAndInvite or 4
		end

		return InspectionFlags and InspectionFlags.AskAndInvite or 0
	end

	if actionType == askFlag then
		return currentFlag
	end

	if actionType == allowFlag then
		if canInspectPlayer(currentFlag) then
			return InspectionFlags and InspectionFlags.InspectAndRevoke or 5
		end

		return InspectionFlags and InspectionFlags.AskAndRevoke or 1
	end

	return currentFlag
end

local function sendInspectionPlayerAction(actionType, creatureThing, creatureName)
	if not g_game.inspectionPlayer then
		g_logger.warning("[game_interface] g_game.inspectionPlayer unavailable — recompile the client.")

		return
	end

	local creatureId = creatureThing:getId()

	if not creatureId or creatureId == 0 then
		g_logger.warning("[game_interface] invalid creature id for inspect action on %s", creatureName or "?")

		return
	end

	local currentFlag = normalizeInspectionFlag(getCreatureInspectionFlag(creatureThing))

	g_game.inspectionPlayer(actionType, creatureId)
	syncCreatureInspectionFlag(creatureId, predictInspectionFlagAfterAction(currentFlag, actionType))
end

function onInspectionState(creatureId, state)
	if not creatureId or creatureId == 0 then
		return
	end

	local creature = g_map.getCreatureById(creatureId)
	local previousFlag = creatureInspectionFlags[creatureId]

	if previousFlag == nil and creature and creature.getInspectionFlag then
		previousFlag = creature:getInspectionFlag()
	end

	syncCreatureInspectionFlag(creatureId, state)

	local creatureName = creature and creature:getName() or tr("a player")
	local normalized = normalizeInspectionFlag(state)
	local previousNormalized = normalizeInspectionFlag(previousFlag or 0)

	if previousNormalized == normalized then
		return
	end

	if canInspectPlayer(normalized) and not canInspectPlayer(previousNormalized) then
		if modules.game_textmessage and modules.game_textmessage.displayGameMessage then
			modules.game_textmessage.displayGameMessage(tr("%s has granted you permission to inspect their character.", creatureName))
		end
	elseif canAllowInspectMe(normalized) and not canAllowInspectMe(previousNormalized) and modules.game_textmessage and modules.game_textmessage.displayGameMessage then
		modules.game_textmessage.displayGameMessage(tr("%s asked for permission to inspect your character.", creatureName))
	end
end

local function addOtherPlayerInspectOptions(menu, creatureThing, creatureName)
	local creatureId = creatureThing:getId()
	local flag = normalizeInspectionFlag(getCreatureInspectionFlag(creatureThing))
	local askFlag = InspectionParseFlags and InspectionParseFlags.Ask or 2
	local inspectFlag = InspectionParseFlags and InspectionParseFlags.Inspect or 4
	local inviteFlag = InspectionParseFlags and InspectionParseFlags.Invite or 1
	local revokeFlag = InspectionParseFlags and InspectionParseFlags.Revoke or 5
	local allowFlag = InspectionParseFlags and InspectionParseFlags.Allow or 3

	if canInspectPlayer(flag) then
		menu:addOption(tr("Inspect %s", creatureName), function()
			if modules.game_inspect and modules.game_inspect.beginCharacterInspectRequest then
				modules.game_inspect.beginCharacterInspectRequest(creatureId)
			end

			sendInspectionPlayerAction(inspectFlag, creatureThing, creatureName)
		end)
	else
		menu:addOption(tr("Ask to inspect %s", creatureName), function()
			sendInspectionPlayerAction(askFlag, creatureThing, creatureName)
		end)
	end

	if isLocalAllowAllInspectEnabled() then
		return
	end

	if canAllowInspectMe(flag) then
		menu:addOption(tr("Allow %s to inspect me", creatureName), function()
			sendInspectionPlayerAction(allowFlag, creatureThing, creatureName)
		end)
	elseif canRevokeInspectMe(flag) then
		menu:addOption(tr("Revoke %s's allowance to inspect me", creatureName), function()
			sendInspectionPlayerAction(revokeFlag, creatureThing, creatureName)
		end)
	else
		menu:addOption(tr("Invite %s to inspect me", creatureName), function()
			sendInspectionPlayerAction(inviteFlag, creatureThing, creatureName)
		end)
	end
end

local function addOtherPlayerVipOption(menu, localPlayer, creatureName)
	if not localPlayer:hasVip(creatureName) then
		menu:addOption(tr("Add %s to VIP list", creatureName), function()
			g_game.addVip(creatureName)
		end)
	end
end

local function addOtherPlayerPartyOption(menu, localPlayer, creatureThing, creatureName)
	local localPlayerShield = localPlayer:getShield()
	local creatureShield = creatureThing:getShield()

	if localPlayerShield == ShieldNone or localPlayerShield == ShieldWhiteBlue then
		if creatureShield == ShieldWhiteYellow then
			menu:addOption(tr("Join %s's Party", creatureName), function()
				g_game.partyJoin(creatureThing:getId())
			end)
		else
			menu:addOption(tr("Invite %s to Party", creatureName), function()
				g_game.partyInvite(creatureThing:getId())
			end)
		end
	elseif localPlayerShield == ShieldWhiteYellow then
		if creatureShield == ShieldWhiteBlue then
			menu:addOption(tr("Revoke %s's Invitation", creatureName), function()
				g_game.partyRevokeInvitation(creatureThing:getId())
			end)
		end
	elseif localPlayerShield == ShieldYellow or localPlayerShield == ShieldYellowSharedExp or localPlayerShield == ShieldYellowNoSharedExpBlink or localPlayerShield == ShieldYellowNoSharedExp then
		if creatureShield == ShieldWhiteBlue then
			menu:addOption(tr("Revoke %s's Invitation", creatureName), function()
				g_game.partyRevokeInvitation(creatureThing:getId())
			end)
		elseif creatureShield == ShieldBlue or creatureShield == ShieldBlueSharedExp or creatureShield == ShieldBlueNoSharedExpBlink or creatureShield == ShieldBlueNoSharedExp then
			menu:addOption(tr("Pass Leadership to %s", creatureName), function()
				g_game.partyPassLeadership(creatureThing:getId())
			end)
		else
			menu:addOption(tr("Invite %s to Party", creatureName), function()
				g_game.partyInvite(creatureThing:getId())
			end)
		end
	end

	addOtherPlayerInspectOptions(menu, creatureThing, creatureName)
end

function createBattleListCreatureMenu(menuPosition, creature)
	if not g_game.isOnline() or not creature or creature:isLocalPlayer() then
		return
	end

	local localPlayer = g_game.getLocalPlayer()

	if not localPlayer then
		return
	end

	local menu = g_ui.createWidget("GamePopupMenu")

	menu:setGameMenu(true)

	local talkShortcut = getTalkMenuShortcut()
	local lookShortcut = getLookMenuShortcut()
	local attackShortcut = getAttackMenuShortcut()
	local localPosition = localPlayer:getPosition()
	local creatureName = creature:getName()
	local creaturePos = creature:getPosition()
	local sameFloor = creaturePos and localPosition and creaturePos.z == localPosition.z

	if sameFloor then
		if creature:isNpc() then
			menu:addOption(tr("Talk"), function()
				g_game.cancelAttack()
				g_game.talk("hi")
			end, talkShortcut)
		elseif g_game.getAttackingCreature() ~= creature then
			menu:addOption(tr("Attack"), function()
				g_game.attack(creature)
			end, attackShortcut)
		else
			menu:addOption(tr("Stop Attack"), function()
				g_game.cancelAttack()
			end, attackShortcut)
		end

		if g_game.getFollowingCreature() ~= creature then
			menu:addOption(tr("Follow"), function()
				g_game.follow(creature)
			end)
		else
			menu:addOption(tr("Stop Follow"), function()
				g_game.cancelFollow()
			end)
		end
	end

	menu:addOption(tr("Look"), function()
		g_game.look(creature, true)
	end, lookShortcut)

	if creature:isPlayer() then
		menu:addSeparator()
		menu:addOption(tr("Message to %s", creatureName), function()
			g_game.openPrivateChannel(creatureName)
		end)
		addOtherPlayerVipOption(menu, localPlayer, creatureName)

		if modules.game_console.isIgnored(creatureName) then
			menu:addOption(tr("Unignore %s", creatureName), function()
				modules.game_console.removeIgnoredPlayer(creatureName)
			end)
		else
			menu:addOption(tr("Ignore %s", creatureName), function()
				modules.game_console.addIgnoredPlayer(creatureName)
			end)
		end

		addOtherPlayerPartyOption(menu, localPlayer, creature, creatureName)
		menu:addSeparator()
		menu:addOption(tr("Report Name"), function()
			modules.game_ruleviolation.openNameReport(creatureName)
		end)
		menu:addOption(tr("Report Bot/Macro"), function()
			modules.game_ruleviolation.openBotMacroReport(creatureName)
		end)
	end

	menu:addSeparator()
	menu:addOption(tr("Copy Name"), function()
		g_window.setClipboardText(creatureName)
	end)
	menu:display(menuPosition)
end

local SUPPLY_STASH_ACTION_STOW_ITEM = 0
local SUPPLY_STASH_ACTION_STOW_CONTAINER = 1
local SUPPLY_STASH_ACTION_STOW_STACK = 2
local SUPPLY_STASH_CLIENT_ID = 28750

local function isSupplyStashItem(thing)
	if not thing or not thing.getId then
		return false
	end

	if thing:getId() == SUPPLY_STASH_CLIENT_ID then
		return true
	end

	local thingType = g_things.getThingType(thing:getId(), ThingCategoryItem)

	if thingType and thingType.getName then
		local name = thingType:getName():lower()

		if name:find("supply stash", 1, true) then
			return true
		end
	end

	return false
end

function onSpecialContainer(supplyStashAvailable, marketAvailable)
	if supplyStashAvailable == true or marketAvailable == true then
		supplyStashMenuEnabled = true
	elseif supplyStashAvailable == false and marketAvailable == false then
		supplyStashMenuEnabled = false
	end
end

function onDepotContainerOpen(container)
	if container and container.isInDepot and container:isInDepot() then
		supplyStashMenuEnabled = true
	end
end

local function isSupplyStashMenuAvailable()
	if g_game.isSupplyStashMenuAvailable and g_game.isSupplyStashMenuAvailable() then
		return true
	end

	if supplyStashMenuEnabled then
		return true
	end

	local player = g_game.getLocalPlayer()

	if player and player.isSupplyStashAvailable and player:isSupplyStashAvailable() then
		return true
	end

	return false
end

local function isStowTargetThing(thing)
	if not thing or thing:isCreature() or isSupplyStashItem(thing) then
		return false
	end

	local pos = thing:getPosition()

	if not pos or pos.x ~= 65535 then
		return false
	end

	if thing:isContainer() then
		return true
	end

	return thing:isPickupable()
end

closeCountWindow = function()
	if not countWindow then
		return
	end

	if g_modalManager then
		g_modalManager.hide(countWindow)
	end

	if not countWindow:isDestroyed() then
		countWindow:destroy()
	end

	countWindow = nil
end

local function hasMarketThingType(item)
	if not item or not item.getId then
		return false
	end

	if item.isMarketable and item:isMarketable() then
		return true
	end

	local thingType = g_things.getThingType(item:getId(), ThingCategoryItem)

	if thingType and thingType.isMarketable and thingType:isMarketable() then
		return true
	end

	return false
end

local function canStowItem(item)
	if not item or item:isCreature() or not item:isPickupable() then
		return false
	end

	if item:isContainer() then
		return false
	end

	if not hasMarketThingType(item) then
		return false
	end

	local tier = item.getTier and item:getTier() or 0

	if tier ~= 0 then
		return false
	end

	return true
end

local function stowItem(item, count)
	g_game.stashStowItem(item:getPosition(), item:getId(), count, item:getStackPos(), SUPPLY_STASH_ACTION_STOW_ITEM)
end

local function stowAllItemsOfType(item)
	g_game.stashStowItem(item:getPosition(), item:getId(), 0, item:getStackPos(), SUPPLY_STASH_ACTION_STOW_STACK)
end

local function openItemCountWindow(item, onConfirm, hotkeyId)
	if countWindow then
		return
	end

	local count = item:getCount()

	countWindow = g_ui.createWidget("CountWindow", rootWidget)
	countWindow.hotkeyBlock = HotkeyUtils.createHotkeyBlock(hotkeyId or "stackable_item_dialog")

	local itembox = countWindow:getChildById("item")
	local scrollbar = countWindow:getChildById("countScrollBar")

	itembox:setItemId(item:getId())
	itembox:setItemCount(count)
	scrollbar:setMaximum(count)
	scrollbar:setMinimum(1)
	scrollbar:setValue(count)

	local spinbox = countWindow:getChildById("spinBox")

	spinbox:setMaximum(count)
	spinbox:setMinimum(0)
	spinbox:setValue(0)
	spinbox:hideButtons()
	spinbox:focus()

	spinbox.firstEdit = true

	local function spinBoxValueChange(self, value)
		spinbox.firstEdit = false

		scrollbar:setValue(value)
	end

	spinbox.onValueChange = spinBoxValueChange

	local function check()
		if spinbox.firstEdit then
			spinbox:setValue(spinbox:getMaximum())

			spinbox.firstEdit = false
		end
	end

	g_keyboard.bindKeyPress("Up", function()
		check()
		spinbox:upSpin()
	end, spinbox)
	g_keyboard.bindKeyPress("Down", function()
		check()
		spinbox:downSpin()
	end, spinbox)
	g_keyboard.bindKeyPress("PageUp", function()
		check()
		spinbox:setValue(spinbox:getValue() + 10)
	end, spinbox)
	g_keyboard.bindKeyPress("PageDown", function()
		check()
		spinbox:setValue(spinbox:getValue() - 10)
	end, spinbox)

	function scrollbar:onValueChange(value)
		itembox:setItemCount(value)

		spinbox.onValueChange = nil

		spinbox:setValue(value)

		spinbox.onValueChange = spinBoxValueChange
	end

	local okButton = countWindow:getChildById("buttonOk")

	local function confirmFunc()
		onConfirm(itembox:getItemCount())
		closeCountWindow()
	end

	local cancelButton = countWindow:getChildById("buttonCancel")

	local function cancelFunc()
		closeCountWindow()
	end

	countWindow.onEnter = confirmFunc
	countWindow.onEscape = cancelFunc
	okButton.onClick = confirmFunc
	cancelButton.onClick = cancelFunc

	countWindow:raise()
	countWindow:focus()

	if g_modalManager then
		g_modalManager.show(countWindow)
	end
end

local function requestStowItem(item)
	local count = item:getCount()

	if count > 1 then
		openItemCountWindow(item, function(selectedCount)
			stowItem(item, selectedCount)
		end, "stow_item_dialog")
	else
		stowItem(item, 1)
	end
end

local function closeStowConfirmWindow(confirmWindow)
	if not confirmWindow then
		return
	end

	if g_modalManager then
		g_modalManager.hide(confirmWindow)
	end

	if not confirmWindow:isDestroyed() then
		confirmWindow:destroy()
	end
end

local function displayStowContainerConfirmBox(onConfirm)
	local confirmWindow = g_ui.createWidget("StowContainerConfirmModal", rootWidget)

	confirmWindow:getChildById("title"):setText(tr("Confirmation of Stowing Container's Content"))
	confirmWindow:getChildById("content"):setText(tr("You are about to move all stowable content of this container into the stash.\nThis action is irreversible. Do you want to proceed?"))

	local doNotShowAgain = confirmWindow:recursiveGetChildById("doNotShowAgain")

	local function cancelFunc()
		closeStowConfirmWindow(confirmWindow)
	end

	local function confirmFunc()
		if doNotShowAgain and doNotShowAgain:isChecked() and modules.client_options and modules.client_options.setOption then
			modules.client_options.setOption("askBeforeStowing", false, true)
		end

		closeStowConfirmWindow(confirmWindow)
		onConfirm()
	end

	local buttonNo = confirmWindow:recursiveGetChildById("buttonNo")
	local buttonYes = confirmWindow:recursiveGetChildById("buttonYes")

	if buttonNo then
		buttonNo.onClick = cancelFunc
	end

	if buttonYes then
		buttonYes.onClick = confirmFunc
	end

	connect(confirmWindow, {
		onEnter = confirmFunc,
		onEscape = cancelFunc
	})
	confirmWindow:raise()
	confirmWindow:focus()

	if g_modalManager then
		g_modalManager.show(confirmWindow)
	end

	return confirmWindow
end

local function stowContainerContent(container)
	local function doStow()
		g_game.stashStowItem(container:getPosition(), container:getId(), 0, container:getStackPos(), SUPPLY_STASH_ACTION_STOW_CONTAINER)
	end

	if modules.client_options.getOption("askBeforeStowing") then
		displayStowContainerConfirmBox(doStow)
	else
		doStow()
	end
end

local function getThingTypeName(thing)
	if not thing or not thing.getId then
		return ""
	end

	local thingType = g_things.getThingType(thing:getId(), ThingCategoryItem)

	if thingType and thingType.getName then
		return thingType:getName():lower()
	end

	return ""
end

local function isDepotLockerContainer(container)
	if not container then
		return false
	end

	if container.getName then
		local name = container:getName():lower()

		if name == "locker" or name:find("locker", 1, true) then
			return true
		end
	end

	if not container.getCapacity then
		return false
	end

	for slot = 0, container:getCapacity() - 1 do
		local item = container:getItem(slot)

		if item then
			if isSupplyStashItem(item) then
				return true
			end

			local itemName = getThingTypeName(item)

			if itemName:find("the market", 1, true) or itemName:find("your inbox", 1, true) or itemName:find("depot chest", 1, true) then
				return true
			end
		end
	end

	return false
end

local function getDepotLockerItemKind(thing)
	if not thing or not thing.getParentContainer then
		return nil
	end

	local parent = thing:getParentContainer()

	if not isDepotLockerContainer(parent) then
		return nil
	end

	if isSupplyStashItem(thing) then
		return "stash"
	end

	local name = getThingTypeName(thing)

	if name:find("supply stash", 1, true) then
		return "stash"
	end

	if name:find("the market", 1, true) then
		return "market"
	end

	if name:find("your inbox", 1, true) then
		return "mailbox"
	end

	if name:find("depot chest", 1, true) then
		return "depot"
	end

	return nil
end

local function addManageContainersMenuOption(menu)
	menu:addOption(tr("Manage Containers"), function()
		local quickLoot = modules.game_quickloot and modules.game_quickloot.QuickLoot

		if quickLoot and quickLoot.toggle then
			quickLoot.toggle()
		end
	end)
end

local function createDepotLockerItemMenu(menu, thing, kind, lookShortcut, openShortcut)
	menu:addOption(tr("Look"), function()
		g_game.look(thing)
	end, lookShortcut)

	local parentContainer = thing:getParentContainer()

	if kind == "market" or kind == "stash" then
		menu:addOption(tr("Open"), function()
			g_game.use(thing)
		end, openShortcut)
	else
		menu:addOption(tr("Open"), function()
			g_game.open(thing, parentContainer)
		end, openShortcut)
		menu:addOption(tr("Open in new window"), function()
			g_game.open(thing)
		end)
	end

	menu:addSeparator()
	addManageContainersMenuOption(menu)

	if (kind == "depot" or kind == "mailbox") and isSupplyStashMenuAvailable() then
		menu:addSeparator()
		menu:addOption(tr("Stow container's content"), function()
			stowContainerContent(thing)
		end)
	end
end

local function shouldShowDepotManageContainers(thing)
	if not thing or not thing.isContainer or not thing:isContainer() then
		return false
	end

	if not isSupplyStashMenuAvailable() then
		return false
	end

	if getDepotLockerItemKind(thing) then
		return true
	end

	local parent = thing.getParentContainer and thing:getParentContainer()

	if parent and parent.isInDepot and parent:isInDepot() then
		return true
	end

	return parent and isDepotLockerContainer(parent) or false
end

local function isSupplyStashContainer(container)
	if not container then
		return false
	end

	if container.getName then
		local name = container:getName():lower()

		if name:find("supply stash", 1, true) then
			return true
		end
	end

	local containerItem = container.getContainerItem and container:getContainerItem()

	return containerItem and isSupplyStashItem(containerItem) or false
end

local function canShowMoveUpOption(thing)
	if not thing or thing:isCreature() then
		return false
	end

	if thing:isNotMoveable() or not thing:isPickupable() then
		return false
	end

	local parentContainer = thing:getParentContainer()

	if not parentContainer or not parentContainer:hasParent() then
		return false
	end

	if isSupplyStashContainer(parentContainer) or isDepotLockerContainer(parentContainer) then
		return false
	end

	return true
end

function canContainerShowUpButton(container)
	if not container or not container.hasParent or not container:hasParent() then
		return false
	end

	return true
end

local function isPotionItem(thing)
	if not thing or not thing.isItem or not thing:isItem() then
		return false
	end

	if not thing.getMarketData then
		return false
	end

	local marketData = thing:getMarketData()

	if not marketData then
		return false
	end

	local potionsCategory = MarketCategory and MarketCategory.Potions or 10

	return marketData.category == potionsCategory
end

local OTC_TOGGLE_COLOR_ENABLED = "#44ad25"
local OTC_TOGGLE_COLOR_DISABLED = "#ff9854"
local LOOT_POUCH_ITEM_ID = 23721

local function addOtcToggleMenuOption(menu, opCode, enabledLabel, disabledLabel, defaultEnabled)
	local enabled = defaultEnabled and true or false

	if g_game.isOtcToggleEnabled then
		enabled = g_game.isOtcToggleEnabled(opCode) and true or false
	end

	local option = menu:addOption(enabled and tr(enabledLabel) or tr(disabledLabel), function()
		if not g_game.sendOtcToggle then
			return
		end

		g_game.sendOtcToggle(opCode, enabled and 0 or 1)
	end)

	if option then
		option:setColor(enabled and OTC_TOGGLE_COLOR_ENABLED or OTC_TOGGLE_COLOR_DISABLED)
	end
end

local function addFlaskCreationMenuOption(menu)
	local opCode = OtcOpCode and OtcOpCode.TOGGLE_FLASK or 2

	addOtcToggleMenuOption(menu, opCode, "Enabled flask creation", "Disabled flask creation", true)
end

local function isLootPouchItem(thing)
	return thing and thing.isItem and thing:isItem() and thing:getId() == LOOT_POUCH_ITEM_ID
end

local function addAutoLootMenuOption(menu)
	local opCode = OtcOpCode and OtcOpCode.TOGGLE_AUTOLOOT or 1

	addOtcToggleMenuOption(menu, opCode, "Enabled auto loot", "Disabled auto loot", false)
end

function createThingMenu(menuPosition, lookThing, useThing, creatureThing, mapTilePos)
	if not g_game.isOnline() then
		return
	end

	local menu = g_ui.createWidget("GamePopupMenu")

	menu:setGameMenu(true)

	local lookShortcut = getLookMenuShortcut()
	local useThingShortcuts = getUseThingMenuShortcuts()
	local talkShortcut = getTalkMenuShortcut()
	local attackShortcut = getAttackMenuShortcut()
	local lockerThing = lookThing or useThing
	local lockerKind = lockerThing and getDepotLockerItemKind(lockerThing)

	if lockerKind then
		createDepotLockerItemMenu(menu, lockerThing, lockerKind, lookShortcut, useThingShortcuts.open)
		menu:display(menuPosition)

		return
	end

	if lookThing then
		menu:addOption(tr("Look"), function()
			g_game.look(lookThing)
		end, lookShortcut)

		if lookThing:isItem() and lookThing:isPickupable() then
			menu:addOption(tr("Inspect"), function()
				local pos = lookThing:getPosition()
				local count = lookThing:getCount()

				if not count or count < 1 then
					count = 1
				end

				g_game.inspectionNormalObject(pos)
			end)
		end

		local modCyc = modules.game_cyclopedia
		local cycApi = modCyc and modCyc.Cyclopedia

		if lookThing:isItem() and lookThing:isCyclopediaItem() and cycApi and cycApi.openItemInCyclopedia then
			menu:addOption(tr("Cyclopedia"), function()
				local itemId = lookThing:getId()

				if modCyc.show then
					modCyc.show("items")
				end

				cycApi.openItemInCyclopedia(itemId)
			end)
		end

		if not lookThing:isCreature() and not lookThing:isNotMoveable() and lookThing:isPickupable() and lookThing:getProficiencyId() > 0 then
			menu:addOption(tr("Weapon Proficiency"), function()
				modules.game_proficiency.requestOpenWindow(lookThing)
			end)
		end
	end

	local effectiveUseThing = resolveHirelingUseThing(useThing, creatureThing)

	-- Classic behavior: exactly ONE use-options block. Adding a second block for lookThing
	-- duplicated identical "Use / Browse Field" pairs whenever the looked item and the used
	-- item were different things on the same tile (e.g. a field on top of the ground).
	if effectiveUseThing then
		addUseThingMenuOptions(menu, effectiveUseThing, useThingShortcuts)
	elseif lookThing and lookThing:isItem() then
		addUseThingMenuOptions(menu, lookThing, useThingShortcuts)
	end

	local manageThing = lookThing or effectiveUseThing

	if manageThing and shouldShowDepotManageContainers(manageThing) and not lockerKind then
		menu:addSeparator()
		addManageContainersMenuOption(menu)
	end

	local tilePos = resolveMenuTilePosition(mapTilePos, lookThing, useThing, creatureThing)

	if tilePos then
		menu:addSeparator()
		menu:addOption(tr("Report Coordinate"), function()
			if modules.game_bugreport and modules.game_bugreport.showCoordinateReport then
				modules.game_bugreport.showCoordinateReport(tilePos)
			end
		end)
	end

	if lookThing and not lookThing:isCreature() and not lookThing:isNotMoveable() and lookThing:isPickupable() then
		menu:addSeparator()
		menu:addOption(tr("Trade with ..."), function()
			startTradeWith(lookThing)
		end)

		if isPotionItem(lookThing) then
			menu:addSeparator()
			addFlaskCreationMenuOption(menu)
		end

		if isLootPouchItem(lookThing) then
			menu:addSeparator()
			addAutoLootMenuOption(menu)
		end
	end

	if lookThing and canShowMoveUpOption(lookThing) then
		menu:addOption(tr("Move up"), function()
			g_game.moveToParentContainer(lookThing, lookThing:getCount())
		end)
	end

	if creatureThing and creatureThing:isPlayer() and not creatureThing:isLocalPlayer() and g_game.getFeature(GameBrowseField) then
		local pos = creatureThing:getPosition()

		if pos and pos.x ~= 65535 then
			local browseAlreadyAdded = useThing and useThing:getPosition().x == pos.x and useThing:getPosition().y == pos.y and useThing:getPosition().z == pos.z

			if not browseAlreadyAdded then
				menu:addOption(tr("Browse Field"), function()
					g_game.browseField(pos)
				end)
			end
		end
	end

	if creatureThing then
		local localPlayer = g_game.getLocalPlayer()

		menu:addSeparator()

		if creatureThing:isLocalPlayer() then
			menu:addOption(tr(g_game.getClientVersion() >= 1000 and "Customise Character" or "Set Outfit"), function()
				g_game.requestOutfit()
			end)

			if g_game.getFeature(GamePlayerMounts) then
				if not localPlayer:isMounted() then
					menu:addOption(tr("Mount"), function()
						localPlayer:mount()
					end)
				else
					menu:addOption(tr("Dismount"), function()
						localPlayer:dismount()
					end)
				end
			end

			if g_game.getFeature(GamePrey) then
				menu:addOption(tr("Open Prey Dialog"), function()
					modules.game_prey.show()
				end)
			end

			if modules.game_inspect and g_game.inspectionPlayer then
				local playerName = localPlayer:getName()

				menu:addOption(tr("Inspect %s", playerName), function()
					local inspectFlag = InspectionParseFlags and InspectionParseFlags.Inspect or 4

					if modules.game_inspect.beginCharacterInspectRequest then
						modules.game_inspect.beginCharacterInspectRequest(localPlayer:getId())
					end

					g_game.inspectionPlayer(inspectFlag, 0)
				end)
			end

			menu:addSeparator()
			menu:addOption(tr("Copy Name"), function()
				g_window.setClipboardText(localPlayer:getName())
			end)

			if creatureThing:isPartyMember() then
				if creatureThing:isPartyLeader() then
					if creatureThing:isPartySharedExperienceActive() then
						menu:addOption(tr("Disable Shared Experience"), function()
							g_game.partyShareExperience(false)
						end)
					else
						menu:addOption(tr("Enable Shared Experience"), function()
							g_game.partyShareExperience(true)
						end)
					end
				end

				menu:addOption(tr("Leave Party"), function()
					g_game.partyLeave()
				end)
			end
		else
			local localPosition = localPlayer:getPosition()
			local creatureName = creatureThing:getName()
			local isHireling = creatureThing.isHireling and creatureThing:isHireling()

			if isHireling then
				menu:addOption(tr("Talk"), function()
					g_game.attack(creatureThing)
				end, talkShortcut)
				menu:addSeparator()
				menu:addOption(tr(g_game.getClientVersion() >= 1000 and "Customise Character" or "Set Outfit"), function()
					g_game.requestHirelingOutfit(creatureThing:getId())
				end)
				menu:addOption(tr("Change Name/Sex"), function()
					if modules.game_store and modules.game_store.openHirelingSexChange then
						modules.game_store.openHirelingSexChange()
					end
				end, tr("(Store)"), false, {
					minWidth = 220,
					shortcutColor = "#1872c3"
				})
				menu:addSeparator()
				menu:addOption(tr("Report Name"), function()
					modules.game_ruleviolation.openNameReport(creatureName)
				end)
				menu:addSeparator()
				menu:addOption(tr("Copy Name"), function()
					g_window.setClipboardText(creatureName)
				end)
			elseif creatureThing:getPosition().z == localPosition.z then
			if creatureThing:isNpc() then
					menu:addOption(tr("Talk"), function()
						g_game.cancelAttack()
						g_game.talk("hi")
					end, talkShortcut)
				elseif g_game.getAttackingCreature() ~= creatureThing then
					menu:addOption(tr("Attack"), function()
						g_game.attack(creatureThing)
					end, attackShortcut)
				else
					menu:addOption(tr("Stop Attack"), function()
						g_game.cancelAttack()
					end, attackShortcut)
				end

				if g_game.getFollowingCreature() ~= creatureThing then
					menu:addOption(tr("Follow"), function()
						g_game.follow(creatureThing)
					end)
				else
					menu:addOption(tr("Stop Follow"), function()
						g_game.cancelFollow()
					end)
				end
			end

			if not isHireling then
				if creatureThing:isPlayer() then
					menu:addSeparator()
					menu:addOption(tr("Message to %s", creatureName), function()
						g_game.openPrivateChannel(creatureName)
					end)
					addOtherPlayerVipOption(menu, localPlayer, creatureName)

					if modules.game_console.isIgnored(creatureName) then
						menu:addOption(tr("Unignore %s", creatureName), function()
							modules.game_console.removeIgnoredPlayer(creatureName)
						end)
					else
						menu:addOption(tr("Ignore %s", creatureName), function()
							modules.game_console.addIgnoredPlayer(creatureName)
						end)
					end

					addOtherPlayerPartyOption(menu, localPlayer, creatureThing, creatureName)
					menu:addSeparator()
					menu:addOption(tr("Report Name"), function()
						modules.game_ruleviolation.openNameReport(creatureName)
					end)
					menu:addOption(tr("Report Bot/Macro"), function()
						modules.game_ruleviolation.openBotMacroReport(creatureName)
					end)
					menu:addSeparator()
					menu:addOption(tr("Copy Name"), function()
						g_window.setClipboardText(creatureName)
					end)
				else
					menu:addSeparator()
					menu:addOption(tr("Copy Name"), function()
						g_window.setClipboardText(creatureName)
					end)
				end
			end
		end

		if modules.game_ruleviolation.hasWindowAccess() and creatureThing:isPlayer() then
			menu:addSeparator()
			menu:addOption(tr("Rule Violation"), function()
				modules.game_ruleviolation.show(creatureThing:getName())
			end)
		end
	end

	for _, category in pairs(hookedMenuOptions) do
		if not isMenuHookCategoryEmpty(category) then
			local hasVisible = false

			for name, opt in pairs(category) do
				if opt and opt.condition(menuPosition, lookThing, useThing, creatureThing) then
					hasVisible = true

					break
				end
			end

			if hasVisible then
				menu:addSeparator()

				for name, opt in pairs(category) do
					if opt and opt.condition(menuPosition, lookThing, useThing, creatureThing) then
						menu:addOption(name, function()
							opt.callback(menuPosition, lookThing, useThing, creatureThing)
						end, opt.shortcut)
					end
				end
			end
		end
	end

	if g_game.getFeature(GameThingQuickLoot) and modules.game_quickloot and lookThing and not lookThing:isCreature() and lookThing:isPickupable() then
		local quickLoot = modules.game_quickloot.QuickLoot

		menu:addSeparator()

		if lookThing:isContainer() then
			menu:addOption(tr("Manage Loot Containers"), function()
				quickLoot.toggle()
			end)
		end

		local lootExists = quickLoot.lootExists(lookThing:getId())
		local optionText = lootExists and "Remove from" or "Add to"
		local actionFunction = lootExists and quickLoot.removeLootList or quickLoot.addLootList

		menu:addOption(tr(optionText .. " loot list"), function()
			actionFunction(lookThing:getId())
		end)
	end

	if isSupplyStashMenuAvailable() then
		local stowThing = useThing or lookThing

		if stowThing and isStowTargetThing(stowThing) then
			if stowThing:isContainer() then
				menu:addSeparator()
				menu:addOption(tr("Stow container's content"), function()
					stowContainerContent(stowThing)
				end)
			elseif canStowItem(stowThing) then
				menu:addSeparator()
				menu:addOption(tr("Stow"), function()
					requestStowItem(stowThing)
				end)
				menu:addOption(tr("Stow all items of this type"), function()
					stowAllItemsOfType(stowThing)
				end)
			end
		end
	end

	menu:display(menuPosition)
end

local function canQuickLoot()
	return g_game.getFeature(GameThingQuickLoot) and modules.game_quickloot
end

local function isGroundCorpse(thing)
	if not thing or thing:getParentContainer() then
		return false
	end

	local pos = thing:getPosition()

	if not pos or pos.x == 65535 then
		return false
	end

	return thing:isLyingCorpse()
end

local function isGroundLootTarget(thing)
	return isGroundCorpse(thing) and not thing:isPlayerCorpse()
end

local function resolveGroundCorpse(useThing, lookThing)
	if isGroundCorpse(useThing) then
		return useThing
	end

	if isGroundCorpse(lookThing) then
		return lookThing
	end

	return nil
end

local function resolveGroundLootTarget(useThing, lookThing)
	if isGroundLootTarget(useThing) then
		return useThing
	end

	if isGroundLootTarget(lookThing) then
		return lookThing
	end

	return nil
end

local function tryQuickLootCorpse(useThing, lookThing)
	local corpse = resolveGroundCorpse(useThing, lookThing)

	if not corpse then
		return false
	end

	if corpse:isPlayerCorpse() or not canQuickLoot() then
		g_game.open(corpse)

		return true
	end

	g_game.sendQuickLoot(1, corpse)

	return true
end

local function handleContainerOrCorpse(thing, quickLoot)
	if not thing or not thing:isContainer() and not thing:isLyingCorpse() then
		return false
	end

	if thing:getParentContainer() then
		g_game.open(thing, thing:getParentContainer())

		return true
	end

	if quickLoot and isGroundLootTarget(thing) and canQuickLoot() then
		g_game.sendQuickLoot(1, thing)

		return true
	end

	if thing:isPickupable() then
		g_game.open(thing)

		return true
	end

	g_game.open(thing)

	return true
end

local function handleUseThing(thing, quickLootContainers)
	if not thing then
		return false
	end

	if thing.isHireling and thing:isHireling() then
		g_game.useHireling(thing)

		return true
	end

	if thing:isContainer() or thing:isLyingCorpse() then
		return handleContainerOrCorpse(thing, quickLootContainers)
	elseif thing:isMultiUse() then
		startUseWith(thing)

		return true
	else
		g_game.use(thing)

		return true
	end
end

local function tryClassicAttack(player, attackCreature, creatureThing, autoWalkPos)
	local npc = attackCreature and attackCreature:isNpc() and attackCreature or creatureThing and creatureThing:isNpc() and creatureThing

	if npc then
		g_game.cancelAttack()
		g_game.talk("hi")

		return true
	end

	if attackCreature and attackCreature ~= player then
		g_game.attack(attackCreature)

		return true
	end

	if creatureThing and creatureThing ~= player and creatureThing:getPosition().z == autoWalkPos.z then
		g_game.attack(creatureThing)

		return true
	end

	return false
end

function processMouseAction(menuPosition, mouseButton, autoWalkPos, lookThing, useThing, creatureThing, attackCreature)
	local keyboardModifiers = g_keyboard.getModifiers()
	local classicControl = modules.client_options.getOption("classicControl")
	local player = g_game.getLocalPlayer()

	if not player then
		return false
	end

	local effectiveUseThing = resolveHirelingUseThing(useThing, creatureThing)
	local clickedNpc = creatureThing and creatureThing:isNpc() and creatureThing or attackCreature and attackCreature:isNpc() and attackCreature

	-- NPCs are never attack targets. A normal left click greets them and lets the
	-- server open the NPC dialog, regardless of the selected mouse-control mode.
	if clickedNpc and ((mouseButton == MouseLeftButton and keyboardModifiers == KeyboardNoModifier) or g_keyboard.isAltPressed()) then
		g_game.cancelAttack()
		g_game.talk("hi")

		return true
	end

	if g_platform.isMobile() then
		if mouseButton == MouseRightButton then
			createThingMenu(menuPosition, lookThing, useThing, creatureThing, autoWalkPos)

			return true
		end

		local shortcut = modules.game_shortcuts.getShortcut()

		if shortcut == "look" then
			if lookThing then
				modules.game_shortcuts.resetShortcuts()
				g_game.look(lookThing)

				return true
			end

			return true
		elseif shortcut == "use" then
			if effectiveUseThing then
				modules.game_shortcuts.resetShortcuts()

				if effectiveUseThing:isContainer() then
					if effectiveUseThing:getParentContainer() then
						g_game.open(effectiveUseThing, effectiveUseThing:getParentContainer())
					else
						g_game.open(effectiveUseThing)
					end

					return true
				elseif effectiveUseThing:isMultiUse() then
					startUseWith(effectiveUseThing)

					return true
				else
					handleUseThing(effectiveUseThing, false)

					return true
				end
			end

			return true
		elseif shortcut == "attack" then
			if attackCreature and attackCreature ~= player then
				modules.game_shortcuts.resetShortcuts()
				g_game.attack(attackCreature)

				return true
			elseif creatureThing and creatureThing ~= player and creatureThing:getPosition().z == autoWalkPos.z then
				modules.game_shortcuts.resetShortcuts()
				g_game.attack(creatureThing)

				return true
			end

			return true
		elseif shortcut == "follow" then
			if attackCreature and attackCreature ~= player then
				modules.game_shortcuts.resetShortcuts()
				g_game.follow(attackCreature)

				return true
			elseif creatureThing and creatureThing ~= player and creatureThing:getPosition().z == autoWalkPos.z then
				modules.game_shortcuts.resetShortcuts()
				g_game.follow(creatureThing)

				return true
			end

			return true
		elseif not autoWalkPos and useThing then
			createThingMenu(menuPosition, lookThing, useThing, creatureThing, autoWalkPos)

			return true
		end
	elseif classicControl ~= "classic" and classicControl ~= true then
		-- Left Smart Click: a plain left click performs the smart action instead of only
		-- walking. Priority: attack a hostile creature, greet an NPC ("hi" opens its dialog),
		-- open/use the thing under the cursor. Without this branch a left click on an NPC just
		-- walked toward it and the dialog never opened.
		if classicControl == "leftSmart" and mouseButton == MouseLeftButton and keyboardModifiers == KeyboardNoModifier then
			-- NPC BEFORE attack: the clicked NPC shows up as attackCreature too, so checking
			-- attack first would try to attack the NPC instead of greeting it.
			if clickedNpc then
				g_game.cancelAttack()
				g_game.talk("hi")

				return true
			elseif attackCreature and attackCreature ~= player and not attackCreature:isNpc() then
				g_game.attack(attackCreature)

				return true
			elseif effectiveUseThing then
				if effectiveUseThing:isContainer() then
					if effectiveUseThing:getParentContainer() then
						g_game.open(effectiveUseThing, effectiveUseThing:getParentContainer())
					else
						g_game.open(effectiveUseThing)
					end

					return true
				elseif effectiveUseThing:isMultiUse() then
					startUseWith(effectiveUseThing)

					return true
				else
					handleUseThing(effectiveUseThing, false)

					return true
				end
			end
		end

		if keyboardModifiers == KeyboardNoModifier and mouseButton == MouseRightButton then
			createThingMenu(menuPosition, lookThing, useThing, creatureThing, autoWalkPos)

			return true
		elseif lookThing and keyboardModifiers == KeyboardShiftModifier and (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) then
			g_game.look(lookThing)

			return true
		elseif effectiveUseThing and keyboardModifiers == KeyboardCtrlModifier and (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) then
			if effectiveUseThing:isContainer() then
				if effectiveUseThing:getParentContainer() then
					g_game.open(effectiveUseThing, effectiveUseThing:getParentContainer())
				else
					g_game.open(effectiveUseThing)
				end

				return true
			elseif effectiveUseThing:isMultiUse() then
				startUseWith(effectiveUseThing)

				return true
			else
				handleUseThing(effectiveUseThing, false)

				return true
			end

			return true
		elseif useThing and useThing:isContainer() and keyboardModifiers == KeyboardCtrlShiftModifier and (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) then
			g_game.open(useThing)

			return true
		elseif attackCreature and g_keyboard.isAltPressed() and (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) then
			g_game.attack(attackCreature)

			return true
		elseif creatureThing and creatureThing:getPosition().z == autoWalkPos.z and g_keyboard.isAltPressed() and (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) then
			g_game.attack(creatureThing)

			return true
		end
	else
		local lootSide = modules.client_options.getOption("lootSide") or "right"

		if lootSide == "right" then
			if mouseButton == MouseRightButton and keyboardModifiers == KeyboardNoModifier and not g_mouse.isPressed(MouseLeftButton) then
				if tryClassicAttack(player, attackCreature, creatureThing, autoWalkPos) then
					return true
				elseif effectiveUseThing and handleUseThing(effectiveUseThing, true) then
					return true
				elseif lookThing and not lookThing:isCreature() and lookThing:isPickupable() then
					g_game.move(lookThing, lookThing:getPosition(), 1)

					return true
				end
			elseif mouseButton == MouseRightButton and keyboardModifiers == KeyboardShiftModifier and effectiveUseThing and handleUseThing(effectiveUseThing, false) then
				return true
			end
		elseif lootSide == "shiftRight" then
			if mouseButton == MouseRightButton and keyboardModifiers == KeyboardNoModifier and not g_mouse.isPressed(MouseLeftButton) then
				if tryClassicAttack(player, attackCreature, creatureThing, autoWalkPos) then
					return true
				elseif effectiveUseThing and handleUseThing(effectiveUseThing, false) then
					return true
				end
			elseif mouseButton == MouseRightButton and keyboardModifiers == KeyboardShiftModifier then
				if tryQuickLootCorpse(useThing, lookThing) then
					return true
				elseif lookThing and not lookThing:isCreature() and lookThing:isPickupable() then
					g_game.move(lookThing, lookThing:getPosition(), 1)

					return true
				end
			end
		elseif lootSide == "left" then
			if mouseButton == MouseLeftButton and keyboardModifiers == KeyboardNoModifier then
				if tryQuickLootCorpse(useThing, lookThing) then
					return true
				elseif lookThing and not lookThing:isCreature() and lookThing:isPickupable() then
					g_game.move(lookThing, lookThing:getPosition(), 1)

					return true
				end
			elseif mouseButton == MouseRightButton and keyboardModifiers == KeyboardNoModifier and not g_mouse.isPressed(MouseLeftButton) then
				if tryClassicAttack(player, attackCreature, creatureThing, autoWalkPos) then
					return true
				elseif effectiveUseThing and handleUseThing(effectiveUseThing, false) then
					return true
				elseif not effectiveUseThing then
					createThingMenu(menuPosition, lookThing, useThing, creatureThing, autoWalkPos)

					return true
				end
			end
		end

		if useThing and useThing:isContainer() and keyboardModifiers == KeyboardCtrlShiftModifier and (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) then
			g_game.open(useThing)

			return true
		elseif lookThing and keyboardModifiers == KeyboardShiftModifier and (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) then
			g_game.look(lookThing)

			return true
		elseif lookThing and (g_mouse.isPressed(MouseLeftButton) and mouseButton == MouseRightButton or g_mouse.isPressed(MouseRightButton) and mouseButton == MouseLeftButton) then
			g_game.look(lookThing)

			return true
		elseif useThing and keyboardModifiers == KeyboardCtrlModifier and (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) then
			createThingMenu(menuPosition, lookThing, useThing, creatureThing, autoWalkPos)

			return true
		elseif attackCreature and g_keyboard.isAltPressed() and (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) then
			g_game.attack(attackCreature)

			return true
		elseif creatureThing and creatureThing:getPosition().z == autoWalkPos.z and g_keyboard.isAltPressed() and (mouseButton == MouseLeftButton or mouseButton == MouseRightButton) then
			g_game.attack(creatureThing)

			return true
		end
	end

	local player = g_game.getLocalPlayer()

	player:stopAutoWalk()

	if autoWalkPos and keyboardModifiers == KeyboardNoModifier and mouseButton == MouseLeftButton then
		local classic = classicControl == "classic" or classicControl == true
		local lootSide = modules.client_options.getOption("lootSide") or "right"

		if classic and lootSide == "left" then
			local lootTarget = resolveGroundLootTarget(useThing, lookThing)

			if not lootTarget and (not lookThing or lookThing:isCreature() or not lookThing:isPickupable()) then
				player:autoWalk(autoWalkPos)

				if g_game.isAttacking() and g_game.getChaseMode() == ChaseOpponent then
					g_game.setChaseMode(DontChase)
				end
			end
		else
			player:autoWalk(autoWalkPos)

			if g_game.isAttacking() and g_game.getChaseMode() == ChaseOpponent then
				g_game.setChaseMode(DontChase)
			end
		end

		return true
	end

	return false
end

function moveStackableItem(item, toPos)
	local actionbar = modules.game_actionbar

	if actionbar and actionbar.isEquipmentAssignBlockingItemMove and actionbar.isEquipmentAssignBlockingItemMove() then
		return
	end

	if countWindow then
		return
	end

	if g_keyboard.isShiftPressed() then
		g_game.move(item, toPos, 1)

		return
	elseif g_keyboard.isCtrlPressed() == modules.client_options.getOption("moveStack") then
		g_game.move(item, toPos, item:getCount())

		return
	end

	openItemCountWindow(item, function(selectedCount)
		g_game.move(item, toPos, selectedCount)
	end)
end

function onSelectPanel(self, checked)
	if checked then
		for k, v in pairs(panelsList) do
			if v.checkbox == self then
				gameSelectedPanel = v.panel

				break
			end
		end
	end
end

function getRootPanel()
	return gameRootPanel
end

function getMapPanel()
	return gameMapPanel
end

function getRightPanel()
	return gameRightPanel
end

function getMainRightPanel()
	return gameMainRightPanel
end

function getLeftPanel()
	return gameLeftPanel
end

function getRightExtraPanel()
	if gameRightExtraPanels[1] and not gameRightExtraPanels[1]:isDestroyed() then
		return gameRightExtraPanels[1]
	end

	return gameRightExtraPanel
end

function getLeftExtraPanel()
	if gameLeftExtraPanels[1] and not gameLeftExtraPanels[1]:isDestroyed() then
		return gameLeftExtraPanels[1]
	end

	return gameLeftExtraPanel
end

function isGameSidePanelId(panelId)
	return panelId == "gameLeftPanel" or panelId == "gameRightPanel" or panelId:find("^gameLeftExtraPanel") ~= nil or panelId:find("^gameRightExtraPanel") ~= nil
end

function getActionBarLeftPanel()
	return gameActionBarLeftPanel
end

function getActionBarRightPanel()
	return gameActionBarRightPanel
end

function getLeftTopPanel()
	return gameLeftTopPanel
end

function getRightTopPanel()
	return gameRightTopPanel
end

local function visibleSidebarWidth(panel)
	if not panel or panel:isDestroyed() or not panel:isVisible() then
		return 0
	end

	if not panel:isOn() then
		return 0
	end

	return panel:getWidth()
end

local function isSidebarPanelOpen(panel)
	return visibleSidebarWidth(panel) > 0
end

local function getOrderedLeftPanels()
	local panels = {}

	if gameLeftPanel and not gameLeftPanel:isDestroyed() then
		table.insert(panels, gameLeftPanel)
	end

	for _, panel in ipairs(gameLeftExtraPanels) do
		if panel and not panel:isDestroyed() then
			table.insert(panels, panel)
		end
	end

	return panels
end

local function getOrderedRightPanelsFromMap()
	local panels = {}

	for i = #gameRightExtraPanels, 1, -1 do
		local panel = gameRightExtraPanels[i]

		if panel and not panel:isDestroyed() then
			table.insert(panels, panel)
		end
	end

	if gameRightPanel and not gameRightPanel:isDestroyed() then
		table.insert(panels, gameRightPanel)
	end

	return panels
end

function getLeftMapEdgePanel()
	local lastVisible = gameLeftPanel

	for _, panel in ipairs(getOrderedLeftPanels()) do
		if isSidebarPanelOpen(panel) then
			lastVisible = panel
		end
	end

	return lastVisible
end

function getRightMapEdgePanel()
	for _, panel in ipairs(getOrderedRightPanelsFromMap()) do
		if isSidebarPanelOpen(panel) then
			return panel
		end
	end

	return gameRightPanel
end

function getMiniWindowSidebarPanelsInOrder()
	local panels = {}

	local function appendIfEligible(panel)
		if not panel or panel:isDestroyed() then
			return
		end

		if panel.getClassName and panel:getClassName() ~= "UIMiniWindowContainer" then
			return
		end

		if not isSidebarPanelOpen(panel) then
			return
		end

		if panel.isOn and not panel:isOn() then
			return
		end

		panels[#panels + 1] = panel
	end

	if gameRightPanel then
		appendIfEligible(gameRightPanel)
	end

	for _, panel in ipairs(gameRightExtraPanels or {}) do
		appendIfEligible(panel)
	end

	if gameLeftPanel then
		appendIfEligible(gameLeftPanel)
	end

	for _, panel in ipairs(gameLeftExtraPanels or {}) do
		appendIfEligible(panel)
	end

	return panels
end

local function getSideExtraPanelList(side)
	return side == "left" and gameLeftExtraPanels or gameRightExtraPanels
end

local function getTotalSidebarWidth(panels)
	local width = 0

	for _, panel in ipairs(panels) do
		width = width + visibleSidebarWidth(panel)
	end

	return width
end

local function getOccupiedSidebarWidth(side)
	local width = 0

	if side == "right" and gameMainRightPanel and not gameMainRightPanel:isDestroyed() and gameMainRightPanel:isOn() and gameMainRightPanel:getHeight() > 0 then
		width = width + visibleSidebarWidth(gameMainRightPanel)

		if width <= 0 then
			width = SIDEBAR_COLUMN_WIDTH
		end
	end

	local panels = side == "left" and getOrderedLeftPanels() or getOrderedRightPanelsFromMap()

	return width + getTotalSidebarWidth(panels)
end

local function getTotalOccupiedSidebarWidth()
	return getOccupiedSidebarWidth("left") + getOccupiedSidebarWidth("right")
end

local function getOccupiedSideActionBarWidth(side)
	local panel = side == "left" and gameActionBarLeftPanel or gameActionBarRightPanel

	if not panel or panel:isDestroyed() or not panel:isVisible() or panel:getWidth() <= 0 then
		return 0
	end

	return panel:getWidth()
end

local function getSideDockGapForMapLimit(side)
	if getOccupiedSidebarWidth(side) > 0 or getOccupiedSideActionBarWidth(side) > 0 then
		return CENTER_TO_SIDE_DOCK_GAP
	end

	return 0
end

local function getTotalOccupiedMapLimitWidth()
	return getTotalOccupiedSidebarWidth() + getOccupiedSideActionBarWidth("left") + getOccupiedSideActionBarWidth("right") + getSideDockGapForMapLimit("left") + getSideDockGapForMapLimit("right")
end

function getMaxMapContentHeightForSidebarLayout()
	if not gameRootPanel or gameRootPanel:isDestroyed() then
		return MIN_GAME_MAP_HEIGHT
	end

	local availableCenterWidth = gameRootPanel:getWidth() - getTotalOccupiedMapLimitWidth()

	if availableCenterWidth < getRequiredCenterWidth() then
		return MIN_GAME_MAP_HEIGHT
	end

	local maxHeight = math.max(MIN_GAME_MAP_HEIGHT, math.floor(availableCenterWidth / getMapAspectRatio()))

	return math.floor(maxHeight * 1.2)
end

function getBottomSplitterEffectiveMinMargin(parentH)
	local baseMin = getBottomSplitterMinMarginBottom()

	if gameMapPanel and not gameMapPanel:isDestroyed() and bottomSplitter and not bottomSplitter:isDestroyed() then
		local widgetWidth = gameMapPanel:getWidth()
		local paddingH = gameMapPanel:getPaddingLeft() + gameMapPanel:getPaddingRight()
		local paddingV = gameMapPanel:getPaddingTop() + gameMapPanel:getPaddingBottom()
		local internalWidth = widgetWidth - paddingH

		if internalWidth > 0 then
			local idealInternalHeight = math.floor(internalWidth / getMapAspectRatio() + 0.5)
			local idealWidgetHeight = idealInternalHeight + paddingV
			local currentWidgetHeight = gameMapPanel:getHeight()
			local currentSplitterMargin = bottomSplitter:getMarginBottom()
			local totalHeight = currentWidgetHeight + currentSplitterMargin
			local ceilingMarginBottom = totalHeight - idealWidgetHeight

			if ceilingMarginBottom < 0 then
				ceilingMarginBottom = 0
			end

			if baseMin < ceilingMarginBottom then
				return ceilingMarginBottom
			end
		end
	end

	return baseMin
end

local function getMaxTotalSidebarWidth()
	if not gameRootPanel or gameRootPanel:isDestroyed() then
		return 0
	end

	return math.max(0, gameRootPanel:getWidth() - getRequiredCenterWidth())
end

local function gameRootFitsSidebarWidth(side, columnsToAdd)
	if not gameRootPanel or gameRootPanel:isDestroyed() then
		return false
	end

	columnsToAdd = columnsToAdd or 1

	local extraWidth = SIDEBAR_COLUMN_WIDTH * columnsToAdd
	local leftWidth = getOccupiedSidebarWidth("left")
	local rightWidth = getOccupiedSidebarWidth("right")

	if side == "left" then
		leftWidth = leftWidth + extraWidth
	else
		rightWidth = rightWidth + extraWidth
	end

	return leftWidth + rightWidth + getRequiredCenterWidth() <= gameRootPanel:getWidth()
end

local function getSidebarExpansionSlack()
	local mapWidth = getMapContentSize()

	if mapWidth <= 0 then
		return 0
	end

	return math.max(0, mapWidth - getRequiredCenterWidth())
end

function canAddSidebarColumn(side)
	if getSidebarExpansionSlack() < SIDEBAR_COLUMN_WIDTH then
		return false
	end

	return gameRootFitsSidebarWidth(side, 1)
end

local function canIncreaseLeftSidePanels()
	if getSidebarExpansionSlack() < SIDEBAR_COLUMN_WIDTH then
		return false
	end

	if not modules.client_options.getOption("showLeftPanel") then
		return true
	end

	return canAddSidebarColumn("left")
end

local function canIncreaseRightSidePanels()
	return canAddSidebarColumn("right")
end

local function getRequiredGameRootWidth()
	return getTotalOccupiedSidebarWidth() + getRequiredCenterWidth()
end

local function setSidebarPanelVisible(panel, visible)
	if not panel or panel:isDestroyed() then
		return false
	end

	panel:setOn(visible)
	panel:setVisible(visible)

	return true
end

local function hideSidebarPanel(panel)
	if panel and not panel:isDestroyed() and panel:isOn() then
		return setSidebarPanelVisible(panel, false)
	end

	return false
end

local function hideLastOverflowSidebarColumn()
	for index = #gameRightExtraPanels, 1, -1 do
		if hideSidebarPanel(gameRightExtraPanels[index]) then
			return true
		end
	end

	for index = #gameLeftExtraPanels, 1, -1 do
		if hideSidebarPanel(gameLeftExtraPanels[index]) then
			return true
		end
	end

	return false
end

local function clampSidebarPanelsToAvailableSpace()
	if not gameRootPanel or gameRootPanel:isDestroyed() then
		return false
	end

	local maxSidebarWidth = getMaxTotalSidebarWidth()
	local changed = false

	while maxSidebarWidth < getTotalOccupiedSidebarWidth() do
		if not hideLastOverflowSidebarColumn() then
			break
		end

		changed = true
	end

	return changed
end

local function stackGameCenterAboveSidebars()
	for _, panel in ipairs(getOrderedLeftPanels()) do
		if panel and not panel:isDestroyed() then
			panel:lower()
		end
	end

	for _, panel in ipairs(getOrderedRightPanelsFromMap()) do
		if panel and not panel:isDestroyed() then
			panel:lower()
		end
	end

	if gameMainRightPanel and not gameMainRightPanel:isDestroyed() then
		gameMainRightPanel:raise()
	end

	local centerWidgets = {
		gameLeftTopPanel,
		gameRightTopPanel,
		gameActionBarLeftPanel,
		gameActionBarRightPanel,
		mapVerticalLineLeft,
		mapVerticalLineRight,
		gameTopPanel,
		gameMapPanel,
		bottomSplitter,
		gameBottomPanel,
		gameBottomStatsBarPanel
	}

	for _, widget in ipairs(centerWidgets) do
		if widget and not widget:isDestroyed() then
			widget:raise()
		end
	end

	if gameMainRightPanel and not gameMainRightPanel:isDestroyed() then
		gameMainRightPanel:raise()
	end

	if modules.game_textmessage and modules.game_textmessage.raiseMessagesPanel then
		modules.game_textmessage.raiseMessagesPanel()
	end

	if leftIncreaseSidePanels and not leftIncreaseSidePanels:isDestroyed() then
		leftIncreaseSidePanels:raise()
	end

	if leftDecreaseSidePanels and not leftDecreaseSidePanels:isDestroyed() then
		leftDecreaseSidePanels:raise()
	end

	if rightIncreaseSidePanels and not rightIncreaseSidePanels:isDestroyed() then
		rightIncreaseSidePanels:raise()
	end

	if rightDecreaseSidePanels and not rightDecreaseSidePanels:isDestroyed() then
		rightDecreaseSidePanels:raise()
	end

	-- Floating mini-windows must sit above the map (which we just raised), otherwise every
	-- sidebar toggle / geometry change would bury them under the game view.
	if UIMiniWindow and UIMiniWindow.raiseAllFloating then
		UIMiniWindow.raiseAllFloating()
	end
end

function countVisibleExtraPanels(side)
	local count = 0

	for _, panel in ipairs(getSideExtraPanelList(side)) do
		if panel and not panel:isDestroyed() and panel:isOn() then
			count = count + 1
		end
	end

	return count
end

function countVisibleLeftSidebarSlots()
	local count = 0

	if gameLeftPanel and not gameLeftPanel:isDestroyed() and isSidebarPanelOpen(gameLeftPanel) then
		count = count + 1
	end

	for _, panel in ipairs(gameLeftExtraPanels or {}) do
		if panel and not panel:isDestroyed() and isSidebarPanelOpen(panel) then
			count = count + 1
		end
	end

	return count
end

function getVerticalSidebarPanelsInStorageOrder()
	local panels = {}

	local function addIfVisible(panel)
		if panel and not panel:isDestroyed() and isSidebarPanelOpen(panel) then
			panels[#panels + 1] = panel
		end
	end

	addIfVisible(gameRightPanel)

	for _, panel in ipairs(gameRightExtraPanels or {}) do
		addIfVisible(panel)
	end

	addIfVisible(gameLeftPanel)

	for _, panel in ipairs(gameLeftExtraPanels or {}) do
		addIfVisible(panel)
	end

	return panels
end

function getHorizontalSidebarPanelsInStorageOrder()
	local panels = {}
	local rightEnabled = modules.client_options and modules.client_options.getOption("showRightHorizontalPanel") == true
	local leftEnabled = modules.client_options and modules.client_options.getOption("showLeftHorizontalPanel") == true

	if rightEnabled and gameRightTopPanel and not gameRightTopPanel:isDestroyed() then
		panels[#panels + 1] = gameRightTopPanel
	end

	if leftEnabled and gameLeftTopPanel and not gameLeftTopPanel:isDestroyed() then
		panels[#panels + 1] = gameLeftTopPanel
	end

	return panels
end

function getRightExtraPanelByIndex(index)
	index = tonumber(index) or 1

	local panel = gameRightExtraPanels and gameRightExtraPanels[index]

	if panel and not panel:isDestroyed() then
		return panel
	end

	return nil
end

function getLeftExtraPanelByIndex(index)
	index = tonumber(index) or 1

	local panel = gameLeftExtraPanels and gameLeftExtraPanels[index]

	if panel and not panel:isDestroyed() then
		return panel
	end

	return nil
end

local function hasVisibleExtraSidebarPanels()
	return countVisibleExtraPanels("left") > 0 or countVisibleExtraPanels("right") > 0
end

function updateGameWindowMinimumSize()
	if g_platform.isMobile() then
		return
	end

	g_window.setMinimumSize({
		width = math.max(DEFAULT_WINDOW_MIN_WIDTH, getRequiredGameRootWidth()),
		height = DEFAULT_WINDOW_MIN_HEIGHT
	})
end

function scheduleSidebarLayoutUpdate()
	if not g_game.isOnline() then
		return
	end

	if pendingSidebarLayoutEvent then
		return
	end

	pendingSidebarLayoutEvent = addEvent(function()
		pendingSidebarLayoutEvent = nil

		if not g_game.isOnline() then
			return
		end

		refreshSidebarLayout()
	end)
end

local function reanchorAllVerticalSidebarPanels()
	reanchorVerticalSidebarPanels("left")
	reanchorVerticalSidebarPanels("right")
end

local function fitAllVerticalSidebars()
	local function fitPanel(panel)
		if not panel or panel:isDestroyed() or not panel:isOn() then
			return
		end

		if panel.getClassName and panel:getClassName() ~= "UIMiniWindowContainer" then
			return
		end

		if type(panel.fitAll) == "function" then
			panel:fitAll()
		end
	end

	fitPanel(gameRightPanel)

	for _, panel in ipairs(gameRightExtraPanels or {}) do
		fitPanel(panel)
	end

	fitPanel(gameLeftPanel)

	for _, panel in ipairs(gameLeftExtraPanels or {}) do
		fitPanel(panel)
	end
end

local applyStatsBarDockAnchors
local applyingStatsBarDock = false

function refreshSidebarLayout()
	if not g_game.isOnline() then
		return
	end

	updateHorizontalPanelWidths()
	reanchorAllVerticalSidebarPanels()

	local clamped = clampSidebarPanelsToAvailableSpace()

	if clamped then
		reanchorAllVerticalSidebarPanels()
	end

	reanchorCenterToSidebars()
	stackGameCenterAboveSidebars()
	updateSidebarControlStates()
	updateGameWindowMinimumSize()
	applyBottomSplitterLayoutHeight()

	if applyStatsBarDockAnchors and not applyingStatsBarDock then
		applyingStatsBarDock = true

		applyStatsBarDockAnchors()

		applyingStatsBarDock = false
	end

	addEvent(fitAllVerticalSidebars)

	if clamped then
		save()
	end
end

local function closeSidebarMiniwindows(mainpanel)
	if not mainpanel or mainpanel:isDestroyed() then
		return
	end

	local children = mainpanel:getChildren()

	for i = #children, 1, -1 do
		local widget = children[i]

		if widget and not widget:isDestroyed() and widget.UIMiniWindowContainer and widget.close and widget:isExplicitlyVisible() then
			widget:close()
		end
	end
end

local function isHorizontalBarActive(side)
	local topPanel = side == "left" and gameLeftTopPanel or gameRightTopPanel

	if not topPanel or topPanel:isDestroyed() or not topPanel:isOn() then
		return false
	end

	return topPanel:getWidth() > 0 and topPanel:getHeight() > 0
end

local function applyVerticalSidebarAnchors(panel, side, columnIndex, chainHookId)
	if not panel or panel:isDestroyed() or not panel:isOn() then
		return
	end

	local topPanelId = side == "left" and "gameLeftTopPanel" or "gameRightTopPanel"
	local underHorizontal = isHorizontalBarActive(side) and columnIndex <= VERTICAL_COLUMNS_UNDER_HORIZONTAL

	panel:breakAnchors()

	if side == "left" then
		if columnIndex == 1 then
			panel:addAnchor(AnchorLeft, "parent", AnchorLeft)
		else
			panel:addAnchor(AnchorLeft, chainHookId, AnchorRight)
		end

		if underHorizontal then
			panel:addAnchor(AnchorTop, topPanelId, AnchorBottom)
		else
			panel:addAnchor(AnchorTop, "parent", AnchorTop)
		end

		panel:addAnchor(AnchorBottom, "parent", AnchorBottom)
		panel:setMarginTop(underHorizontal and 1 or 0)

		if columnIndex > 1 then
			panel:setMarginLeft(1)
		end
	else
		if columnIndex == 1 then
			panel:addAnchor(AnchorRight, chainHookId or "parent", AnchorRight)
		else
			panel:addAnchor(AnchorRight, chainHookId, AnchorLeft)
		end

		if underHorizontal then
			panel:addAnchor(AnchorTop, topPanelId, AnchorBottom)
		else
			panel:addAnchor(AnchorTop, "parent", AnchorTop)
		end

		panel:addAnchor(AnchorBottom, "parent", AnchorBottom)
		panel:setMarginTop(underHorizontal and 1 or 0)

		if columnIndex > 1 then
			panel:setMarginRight(1)
		end
	end
end

function reanchorVerticalSidebarPanels(side)
	if side == "left" then
		if gameLeftPanel and not gameLeftPanel:isDestroyed() and gameLeftPanel:isOn() then
			applyVerticalSidebarAnchors(gameLeftPanel, "left", 1, nil)
		end

		local hookId = gameLeftPanel and not gameLeftPanel:isDestroyed() and gameLeftPanel:isOn() and gameLeftPanel:getId() or nil
		local columnIndex = 1

		for _, panel in ipairs(gameLeftExtraPanels) do
			if panel and not panel:isDestroyed() and panel:isOn() then
				columnIndex = columnIndex + 1

				local chainHookId = hookId or gameLeftPanel and gameLeftPanel:getId()

				if chainHookId then
					applyVerticalSidebarAnchors(panel, "left", columnIndex, chainHookId)

					hookId = panel:getId()
				end
			end
		end

		return
	end

	local hookId = gameRightPanel and not gameRightPanel:isDestroyed() and gameRightPanel:isOn() and gameRightPanel:getId() or nil
	local columnIndex = 1

	for _, panel in ipairs(gameRightExtraPanels) do
		if panel and not panel:isDestroyed() and panel:isOn() then
			columnIndex = columnIndex + 1

			local chainHookId = hookId or gameRightPanel and gameRightPanel:getId()

			if chainHookId then
				applyVerticalSidebarAnchors(panel, "right", columnIndex, chainHookId)

				hookId = panel:getId()
			end
		end
	end
end

local function countHorizontalSidebarColumns(side)
	local count = 0

	if side == "left" then
		if gameLeftPanel and isSidebarPanelOpen(gameLeftPanel) then
			count = count + 1
		end

		if gameLeftExtraPanels[1] and isSidebarPanelOpen(gameLeftExtraPanels[1]) then
			count = count + 1
		end
	else
		if gameRightPanel and isSidebarPanelOpen(gameRightPanel) then
			count = count + 1
		end

		if gameRightExtraPanels[1] and isSidebarPanelOpen(gameRightExtraPanels[1]) then
			count = count + 1
		end
	end

	return math.min(count, MAX_HORIZONTAL_SIDEBAR_COLUMNS)
end

local function countVisibleLeftColumns()
	local count = 0

	for _, panel in ipairs(getOrderedLeftPanels()) do
		if isSidebarPanelOpen(panel) then
			count = count + 1
		end
	end

	return count
end

local function countVisibleRightColumns()
	local count = 0

	for _, panel in ipairs(getOrderedRightPanelsFromMap()) do
		if isSidebarPanelOpen(panel) then
			count = count + 1
		end
	end

	return count
end

local function unregisterPanelEntry(panel, checkbox)
	for index, entry in ipairs(panelsList) do
		if entry.panel == panel then
			table.remove(panelsList, index)

			break
		end
	end

	if panelsRadioGroup and checkbox and not checkbox:isDestroyed() then
		panelsRadioGroup:removeWidget(checkbox)
		checkbox:destroy()
	end
end

local function registerPanelEntry(panel, checkbox)
	table.insert(panelsList, {
		panel = panel,
		checkbox = checkbox
	})

	if panelsRadioGroup and checkbox then
		panelsRadioGroup:addWidget(checkbox)
		connect(checkbox, {
			onCheckChange = onSelectPanel
		})
	end

	connect(panel, {
		onVisibilityChange = scheduleSidebarLayoutUpdate
	})
end

local function createSelectColumnButton(panel)
	local checkbox = g_ui.createWidget("SelectColumnButton", gameRootPanel)

	checkbox:setId(panel:getId() .. "Select")
	checkbox:addAnchor(AnchorRight, panel:getId(), AnchorRight)
	checkbox:addAnchor(AnchorBottom, panel:getId(), AnchorBottom)
	registerPanelEntry(panel, checkbox)

	return checkbox
end

local function destroySideExtraPanel(side, index)
	local list = getSideExtraPanelList(side)
	local panel = list[index]

	if not panel or index <= 1 then
		return false
	end

	closeSidebarMiniwindows(panel)

	local checkbox = gameRootPanel:recursiveGetChildById(panel:getId() .. "Select")

	unregisterPanelEntry(panel, checkbox)
	panel:destroy()
	table.remove(list, index)
	refreshSidebarLayout()
	save()
	addEvent(maximizeMapAfterSidebarRemoval)

	return true
end

local function insertSideExtraPanelForRestore(side)
	local list = getSideExtraPanelList(side)
	local index = #list + 1
	local panel = g_ui.createWidget("GameSidePanel", gameRootPanel)

	panel:setId((side == "left" and "gameLeftExtraPanel_" or "gameRightExtraPanel_") .. index)
	panel:setPaddingTop(0)
	setSidebarPanelVisible(panel, true)
	table.insert(list, panel)
	createSelectColumnButton(panel)

	return panel
end

local function insertSideExtraPanel(side)
	if not canAddSidebarColumn(side) then
		return nil
	end

	return insertSideExtraPanelForRestore(side)
end

function createSideExtraPanel(side)
	local panel = insertSideExtraPanel(side)

	if not panel then
		return nil
	end

	refreshSidebarLayout()
	save()

	return panel
end

function restoreSidebarColumnCounts(leftCount, rightCount)
	if leftCount == nil and rightCount == nil then
		leftCount = 0
		rightCount = 0
	else
		leftCount = tonumber(leftCount) or 0
		rightCount = tonumber(rightCount) or 0
	end

	while leftCount > #gameLeftExtraPanels do
		insertSideExtraPanelForRestore("left")
	end

	while rightCount > #gameRightExtraPanels do
		insertSideExtraPanelForRestore("right")
	end

	for index, panel in ipairs(gameLeftExtraPanels) do
		setSidebarPanelVisible(panel, index <= leftCount)
	end

	for index, panel in ipairs(gameRightExtraPanels) do
		setSidebarPanelVisible(panel, index <= rightCount)
	end

	modules.client_options.setOption("showLeftExtraPanel", leftCount > 0, true)
	modules.client_options.setOption("showRightExtraPanel", rightCount > 0, true)
	refreshSidebarLayout()
	save()
end

function reanchorCenterToSidebars()
	if not gameRootPanel or gameRootPanel:isDestroyed() then
		return
	end

	local leftEdge = getLeftMapEdgePanel()
	local rightEdge = getRightMapEdgePanel()

	if not leftEdge or not rightEdge then
		return
	end

	local leftId = leftEdge:getId()
	local rightId = rightEdge:getId()

	if gameActionBarLeftPanel and not gameActionBarLeftPanel:isDestroyed() then
		gameActionBarLeftPanel:breakAnchors()
		gameActionBarLeftPanel:addAnchor(AnchorLeft, leftId, AnchorRight)
		gameActionBarLeftPanel:addAnchor(AnchorTop, "parent", AnchorTop)
		gameActionBarLeftPanel:addAnchor(AnchorBottom, "gameBottomPanel", AnchorTop)
	end

	if gameActionBarRightPanel and not gameActionBarRightPanel:isDestroyed() then
		gameActionBarRightPanel:breakAnchors()
		gameActionBarRightPanel:addAnchor(AnchorRight, rightId, AnchorLeft)
		gameActionBarRightPanel:addAnchor(AnchorTop, "parent", AnchorTop)
		gameActionBarRightPanel:addAnchor(AnchorBottom, "gameBottomPanel", AnchorTop)
	end

	local leftActionBarOpen = gameActionBarLeftPanel and not gameActionBarLeftPanel:isDestroyed() and gameActionBarLeftPanel:isVisible() and gameActionBarLeftPanel:getWidth() > 0
	local rightActionBarOpen = gameActionBarRightPanel and not gameActionBarRightPanel:isDestroyed() and gameActionBarRightPanel:isVisible() and gameActionBarRightPanel:getWidth() > 0

	if mapVerticalLineLeft and not mapVerticalLineLeft:isDestroyed() then
		mapVerticalLineLeft:breakAnchors()
		mapVerticalLineLeft:addAnchor(AnchorLeft, "gameActionBarLeftPanel", AnchorRight)
		mapVerticalLineLeft:addAnchor(AnchorTop, "gameActionBarLeftPanel", AnchorTop)
		mapVerticalLineLeft:addAnchor(AnchorBottom, "gameActionBarLeftPanel", AnchorBottom)
		mapVerticalLineLeft:setMarginLeft(1)
		mapVerticalLineLeft:setVisible(leftActionBarOpen == true)
	end

	if mapVerticalLineRight and not mapVerticalLineRight:isDestroyed() then
		mapVerticalLineRight:breakAnchors()
		mapVerticalLineRight:addAnchor(AnchorRight, "gameActionBarRightPanel", AnchorLeft)
		mapVerticalLineRight:addAnchor(AnchorTop, "gameActionBarRightPanel", AnchorTop)
		mapVerticalLineRight:addAnchor(AnchorBottom, "gameActionBarRightPanel", AnchorBottom)
		mapVerticalLineRight:setMarginRight(1)
		mapVerticalLineRight:setVisible(rightActionBarOpen == true)
	end

	if gameMapPanel and not gameMapPanel:isDestroyed() then
		local leftMapAnchor = leftActionBarOpen and "mapVerticalLineLeft" or leftId
		local rightMapAnchor = rightActionBarOpen and "mapVerticalLineRight" or rightId

		gameMapPanel:breakAnchors()
		gameMapPanel:addAnchor(AnchorLeft, leftMapAnchor, AnchorRight)
		gameMapPanel:addAnchor(AnchorRight, rightMapAnchor, AnchorLeft)
		gameMapPanel:addAnchor(AnchorTop, "gameTopPanel", AnchorBottom)
		gameMapPanel:addAnchor(AnchorBottom, "gameBottomPanel", AnchorTop)
	end

	if gameBottomPanel and not gameBottomPanel:isDestroyed() then
		gameBottomPanel:breakAnchors()
		gameBottomPanel:addAnchor(AnchorLeft, leftId, AnchorRight)
		gameBottomPanel:addAnchor(AnchorRight, rightId, AnchorLeft)
		gameBottomPanel:addAnchor(AnchorTop, "bottomSplitter", AnchorBottom)
		gameBottomPanel:addAnchor(AnchorBottom, "parent", AnchorBottom)
	end

	if gameTopPanel and not gameTopPanel:isDestroyed() then
		gameTopPanel:breakAnchors()
		gameTopPanel:addAnchor(AnchorLeft, leftId, AnchorRight)
		gameTopPanel:addAnchor(AnchorRight, rightId, AnchorLeft)
		gameTopPanel:addAnchor(AnchorTop, "parent", AnchorTop)
	end

	if gameBottomStatsBarPanel and not gameBottomStatsBarPanel:isDestroyed() then
		gameBottomStatsBarPanel:breakAnchors()
		gameBottomStatsBarPanel:addAnchor(AnchorLeft, leftId, AnchorRight)
		gameBottomStatsBarPanel:addAnchor(AnchorRight, rightId, AnchorLeft)
		gameBottomStatsBarPanel:addAnchor(AnchorTop, "bottomSplitter", AnchorBottom)
	end

	if bottomSplitter and not bottomSplitter:isDestroyed() then
		bottomSplitter:breakAnchors()
		bottomSplitter:addAnchor(AnchorLeft, leftId, AnchorRight)
		bottomSplitter:addAnchor(AnchorRight, rightId, AnchorLeft)
		bottomSplitter:addAnchor(AnchorBottom, "parent", AnchorBottom)
	end

	if leftIncreaseSidePanels and not leftIncreaseSidePanels:isDestroyed() then
		leftIncreaseSidePanels:breakAnchors()
		leftIncreaseSidePanels:addAnchor(AnchorLeft, leftId, AnchorRight)
		leftIncreaseSidePanels:addAnchor(AnchorTop, "parent", AnchorTop)
	end

	if rightIncreaseSidePanels and not rightIncreaseSidePanels:isDestroyed() then
		rightIncreaseSidePanels:breakAnchors()
		rightIncreaseSidePanels:addAnchor(AnchorRight, rightId, AnchorLeft)
		rightIncreaseSidePanels:addAnchor(AnchorTop, "parent", AnchorTop)
	end

	if gameActionBarLeftPanel and not gameActionBarLeftPanel:isDestroyed() then
		gameActionBarLeftPanel:setMarginLeft(1)
		gameActionBarLeftPanel:setMarginTop(0)
	end

	if gameActionBarRightPanel and not gameActionBarRightPanel:isDestroyed() then
		gameActionBarRightPanel:setMarginRight(SIDEBAR_INNER_BORDER_GAP - 1)
		gameActionBarRightPanel:setMarginTop(0)
	end

	if gameBottomPanel and not gameBottomPanel:isDestroyed() then
		gameBottomPanel:setMarginLeft(SIDEBAR_INNER_BORDER_GAP - 1)
		gameBottomPanel:setMarginRight(SIDEBAR_INNER_BORDER_GAP - 1)
	end

	if gameBottomStatsBarPanel and not gameBottomStatsBarPanel:isDestroyed() then
		gameBottomStatsBarPanel:setMarginLeft(SIDEBAR_INNER_BORDER_GAP - 1)
		gameBottomStatsBarPanel:setMarginRight(SIDEBAR_INNER_BORDER_GAP - 1)
	end

	if bottomSplitter and not bottomSplitter:isDestroyed() then
		bottomSplitter:setMarginLeft(SIDEBAR_INNER_BORDER_GAP - 1)
		bottomSplitter:setMarginRight(SIDEBAR_INNER_BORDER_GAP - 1)
	end
end

function updateSidebarControlStates()
	if not leftIncreaseSidePanels or leftIncreaseSidePanels:isDestroyed() then
		return
	end

	local leftPrimaryOn = modules.client_options.getOption("showLeftPanel")

	leftIncreaseSidePanels:setEnabled(canIncreaseLeftSidePanels())

	if g_platform.isMobile() then
		leftDecreaseSidePanels:setEnabled(false)
	else
		leftDecreaseSidePanels:setEnabled(leftPrimaryOn or countVisibleExtraPanels("left") > 0)
	end

	rightIncreaseSidePanels:setEnabled(canIncreaseRightSidePanels())
	rightDecreaseSidePanels:setEnabled(countVisibleExtraPanels("right") > 0)
end

function updateHorizontalPanelWidths()
	local leftColumns = countVisibleLeftColumns()
	local rightColumns = countVisibleRightColumns()
	local leftHorizontalColumns = countHorizontalSidebarColumns("left")
	local rightHorizontalColumns = countHorizontalSidebarColumns("right")

	if gameLeftTopPanel and not gameLeftTopPanel:isDestroyed() then
		local leftWidth = SIDEBAR_COLUMN_WIDTH * leftHorizontalColumns

		if leftWidth <= 0 then
			gameLeftTopPanel:setWidth(0)
			gameLeftTopPanel:setVisible(false)
		else
			gameLeftTopPanel:setWidth(leftWidth)

			if gameLeftTopPanel:isOn() then
				gameLeftTopPanel:setVisible(true)
				gameLeftTopPanel:raise()
			end

			if type(gameLeftTopPanel.redistributeChildrenWidths) == "function" then
				gameLeftTopPanel:redistributeChildrenWidths()
			end
		end
	end

	if gameRightTopPanel and not gameRightTopPanel:isDestroyed() then
		local rightWidth = SIDEBAR_COLUMN_WIDTH * rightHorizontalColumns

		if rightWidth <= 0 then
			gameRightTopPanel:setWidth(0)
			gameRightTopPanel:setVisible(false)
		else
			gameRightTopPanel:setWidth(rightWidth)

			if gameRightTopPanel:isOn() then
				gameRightTopPanel:setVisible(true)
				gameRightTopPanel:raise()
			end

			if type(gameRightTopPanel.redistributeChildrenWidths) == "function" then
				gameRightTopPanel:redistributeChildrenWidths()
			end
		end
	end

	if leftIncreaseSidePanels and not leftIncreaseSidePanels:isDestroyed() then
		leftIncreaseSidePanels:setMarginLeft(leftColumns > 0 and -1 or 1)
		leftIncreaseSidePanels:raise()
	end

	if leftDecreaseSidePanels and not leftDecreaseSidePanels:isDestroyed() then
		leftDecreaseSidePanels:raise()
	end

	if rightIncreaseSidePanels and not rightIncreaseSidePanels:isDestroyed() then
		rightIncreaseSidePanels:setMarginRight(rightColumns > 0 and -1 or 1)
		rightIncreaseSidePanels:raise()
	end

	if rightDecreaseSidePanels and not rightDecreaseSidePanels:isDestroyed() then
		rightDecreaseSidePanels:raise()
	end
end

function getSelectedPanel()
	return gameSelectedPanel
end

function getBottomPanel()
	return gameBottomPanel
end

function getShowTopMenuButton()
	return showTopMenuButton
end

function getGameTopStatsBar()
	return gameTopPanel
end

function getGameBottomStatsBar()
	return gameBottomStatsBarPanel
end

function isBottomStatsBarDockActive()
	if not gameBottomStatsBarPanel or gameBottomStatsBarPanel:isDestroyed() then
		return false
	end

	if g_settings.getString("statsbar_placement") ~= "bottom" then
		return false
	end

	local dim = g_settings.getString("statsbar_dimension")

	if dim == "" or dim == "hide" then
		return false
	end

	return gameBottomStatsBarPanel:isVisible() and gameBottomStatsBarPanel:getHeight() > 0
end

function getGameMapPanel()
	return gameMapPanel
end

function findContentPanelAvailable(child, minContentHeight)
	local function panelFits(panel)
		return panel and not panel:isDestroyed() and panel:isOn() and panel:isVisible() and panel:fits(child, minContentHeight, 0) >= 0
	end

	if panelFits(gameSelectedPanel) then
		return gameSelectedPanel
	end

	for _, entry in ipairs(panelsList) do
		local panel = entry.panel

		if panel ~= gameSelectedPanel and panelFits(panel) then
			return panel
		end
	end

	if panelFits(gameLeftPanel) then
		return gameLeftPanel
	end

	if panelFits(gameRightPanel) then
		return gameRightPanel
	end

	return gameSelectedPanel
end

function nextViewMode()
	setupViewMode((currentViewMode + 1) % 3)
end

function setupViewMode(mode)
	if mode == currentViewMode then
		return
	end

	updateSidebarControlStates()

	if g_platform.isMobile() then
		gameRightPanel:setMarginBottom(mobileConfig.mobileHeightShortcuts)
		gameLeftPanel:setMarginBottom(mobileConfig.mobileHeightJoystick)
	end

	if currentViewMode == 2 then
		gameMapPanel:addAnchor(AnchorLeft, "gameLeftPanel", AnchorRight)
		gameMapPanel:addAnchor(AnchorRight, "gameRightPanel", AnchorLeft)
		gameMapPanel:addAnchor(AnchorRight, "gameRightExtraPanel", AnchorLeft)
		gameMapPanel:addAnchor(AnchorBottom, "gameBottomPanel", AnchorTop)
		gameRootPanel:addAnchor(AnchorTop, "parent", AnchorTop)
		gameLeftPanel:setOn(modules.client_options.getOption("showLeftPanel"))
		gameRightExtraPanel:setOn(modules.client_options.getOption("showRightExtraPanel"))
		gameLeftExtraPanel:setOn(modules.client_options.getOption("showLeftExtraPanel"))
		gameLeftPanel:setImageColor("white")
		gameRightPanel:setImageColor("white")
		gameRightExtraPanel:setImageColor("white")
		gameLeftExtraPanel:setImageColor("white")
		gameLeftPanel:setMarginTop(0)
		gameRightPanel:setMarginTop(0)
		gameRightExtraPanel:setMarginTop(0)
		gameLeftExtraPanel:setMarginTop(0)
		gameBottomPanel:setImageColor("white")

		if g_platform.isMobile() then
			gameRightPanel:setMarginBottom(mobileConfig.mobileHeightShortcuts)
			gameLeftPanel:setMarginBottom(mobileConfig.mobileHeightJoystick)
		end
	end

	if mode == 0 then
		gameMapPanel:setKeepAspectRatio(true)
		gameMapPanel:setLimitVisibleRange(false)
		gameMapPanel:setZoom(11)
		gameMapPanel:setVisibleDimension({
			height = 11,
			width = 15
		})

		if g_platform.isMobile() then
			gameRightPanel:setMarginBottom(mobileConfig.mobileHeightShortcuts)
			gameLeftPanel:setMarginBottom(mobileConfig.mobileHeightJoystick)
		end
	elseif mode == 1 then
		gameMapPanel:setKeepAspectRatio(false)
		gameMapPanel:setLimitVisibleRange(true)
		gameMapPanel:setZoom(11)
		gameMapPanel:setVisibleDimension({
			height = 11,
			width = 15
		})

		if g_platform.isMobile() then
			gameRightPanel:setMarginBottom(mobileConfig.mobileHeightShortcuts)
			gameLeftPanel:setMarginBottom(mobileConfig.mobileHeightJoystick)
		end
	elseif mode == 2 then
		local limit = limitedZoom and not g_game.isGM()

		gameMapPanel:setLimitVisibleRange(limit)
		gameMapPanel:setZoom(11)
		gameMapPanel:setVisibleDimension({
			height = 11,
			width = 15
		})
		gameMapPanel:fill("parent")
		gameRootPanel:fill("parent")
		gameLeftPanel:setImageColor("alpha")
		gameRightPanel:setImageColor("alpha")
		gameRightExtraPanel:setImageColor("alpha")
		gameLeftExtraPanel:setImageColor("alpha")
		gameLeftPanel:setOn(true)
		gameLeftPanel:setVisible(true)
		gameRightPanel:setOn(true)
		gameRightExtraPanel:setOn(false)
		gameRightExtraPanel:setVisible(false)
		gameLeftExtraPanel:setOn(false)
		gameLeftExtraPanel:setVisible(false)
		gameMapPanel:setOn(true)
		gameBottomPanel:setImageColor("#ffffff88")

		if g_platform.isMobile() then
			gameRightPanel:setMarginBottom(mobileConfig.mobileHeightShortcuts)
			gameLeftPanel:setMarginBottom(mobileConfig.mobileHeightJoystick)
		end
	end

	currentViewMode = mode

	testExtendedView(mode)
end

function limitZoom()
	limitedZoom = true
end

function refreshConditionIconsFromSettings()
	if StatsBar and StatsBar.refreshConditionIconsFromSettings then
		StatsBar.refreshConditionIconsFromSettings()
	end
end

function updateStatsBar(dimension, placement)
	placement = string.lower(tostring(placement or g_settings.getString("statsbar_placement")))

	if placement ~= "bottom" then
		placement = "top"
	end

	g_settings.set("statsbar_dimension", dimension)
	g_settings.set("statsbar_placement", placement)

	if placement == "top" or placement == "bottom" then
		g_settings.set("statsbar_dock", "full")
	end

	g_settings.save()

	if dimension == "hide" then
		StatsBar.updateCurrentStats("hide", placement)
		StatsBar.hideAll()
	else
		local dimLabel = dimension:sub(1, 1):upper() .. dimension:sub(2)

		constructStatsBar(dimLabel, placement)
	end

	if modules.client_options and modules.client_options.syncShowCustomisableStatusBarsOption then
		modules.client_options.syncShowCustomisableStatusBarsOption(dimension ~= "hide")
	end

	refreshStatsBarDockLayout()
end

local function getBottomStatsBarMarginTop()
	local margin = getBottomActionBarsDockHeight() - getBottomActionBarsCount()

	if g_settings.getString("statsbar_placement") == "bottom" then
		margin = margin + BOTTOM_STATS_BAR_GAP_BELOW_ACTION_BAR
	end

	return margin
end

function applyStatsBarDockAnchors()
	if not gameTopPanel or not gameBottomStatsBarPanel or not gameRootPanel then
		return
	end

	local dim = g_settings.getString("statsbar_dimension")
	local plac = g_settings.getString("statsbar_placement")
	local dock = g_settings.getString("statsbar_dock")

	if dock == "" then
		dock = "full"
	end

	local leftEdge = getLeftMapEdgePanel()
	local rightEdge = getRightMapEdgePanel()

	if not leftEdge or not rightEdge then
		return
	end

	local leftId = leftEdge:getId()
	local rightId = rightEdge:getId()

	gameTopPanel:breakAnchors()
	gameTopPanel:addAnchor(AnchorLeft, leftId, AnchorRight)
	gameTopPanel:addAnchor(AnchorRight, rightId, AnchorLeft)
	gameTopPanel:addAnchor(AnchorTop, "parent", AnchorTop)
	gameBottomStatsBarPanel:breakAnchors()
	gameBottomStatsBarPanel:addAnchor(AnchorLeft, leftId, AnchorRight)
	gameBottomStatsBarPanel:addAnchor(AnchorRight, rightId, AnchorLeft)
	gameBottomStatsBarPanel:addAnchor(AnchorTop, "bottomSplitter", AnchorBottom)
	gameBottomStatsBarPanel:setMarginTop(getBottomStatsBarMarginTop())
	gameBottomStatsBarPanel:setMarginLeft(SIDEBAR_INNER_BORDER_GAP - 1)
	gameBottomStatsBarPanel:setMarginRight(SIDEBAR_INNER_BORDER_GAP - 1)

	if dim == "" or dim == "hide" then
		return
	end

	if plac == "top" then
		if dock == "left" then
			gameTopPanel:breakAnchors()
			gameTopPanel:addAnchor(AnchorLeft, leftId, AnchorRight)
			gameTopPanel:addAnchor(AnchorRight, "parent", AnchorHorizontalCenter)
			gameTopPanel:addAnchor(AnchorTop, "parent", AnchorTop)
		elseif dock == "right" then
			gameTopPanel:breakAnchors()
			gameTopPanel:addAnchor(AnchorLeft, "parent", AnchorHorizontalCenter)
			gameTopPanel:addAnchor(AnchorRight, rightId, AnchorLeft)
			gameTopPanel:addAnchor(AnchorTop, "parent", AnchorTop)
		end
	elseif plac == "bottom" then
		if dock == "left" then
			gameBottomStatsBarPanel:breakAnchors()
			gameBottomStatsBarPanel:addAnchor(AnchorLeft, leftId, AnchorRight)
			gameBottomStatsBarPanel:addAnchor(AnchorRight, "parent", AnchorHorizontalCenter)
			gameBottomStatsBarPanel:addAnchor(AnchorTop, "bottomSplitter", AnchorBottom)
			gameBottomStatsBarPanel:setMarginTop(getBottomStatsBarMarginTop())
			gameBottomStatsBarPanel:setMarginLeft(SIDEBAR_INNER_BORDER_GAP - 1)
			gameBottomStatsBarPanel:setMarginRight(SIDEBAR_INNER_BORDER_GAP - 1)
		elseif dock == "right" then
			gameBottomStatsBarPanel:breakAnchors()
			gameBottomStatsBarPanel:addAnchor(AnchorLeft, "parent", AnchorHorizontalCenter)
			gameBottomStatsBarPanel:addAnchor(AnchorRight, rightId, AnchorLeft)
			gameBottomStatsBarPanel:addAnchor(AnchorTop, "bottomSplitter", AnchorBottom)
			gameBottomStatsBarPanel:setMarginTop(getBottomStatsBarMarginTop())
			gameBottomStatsBarPanel:setMarginLeft(SIDEBAR_INNER_BORDER_GAP - 1)
			gameBottomStatsBarPanel:setMarginRight(SIDEBAR_INNER_BORDER_GAP - 1)
		end
	end
end

function refreshStatsBarDockLayout()
	if not gameTopPanel or not gameBottomStatsBarPanel or not gameRootPanel then
		return
	end

	refreshSidebarLayout()

	if modules.game_actionbar and modules.game_actionbar.refreshBottomCooldownDock then
		modules.game_actionbar.refreshBottomCooldownDock()
	end

	if modules.game_actionbar and modules.game_actionbar.refreshSideActionBarOffsets then
		modules.game_actionbar.refreshSideActionBarOffsets()
		scheduleEvent(function()
			if modules.game_actionbar and modules.game_actionbar.refreshSideActionBarOffsets then
				modules.game_actionbar.refreshSideActionBarOffsets()
			end
		end, 0)
	end

	applyBottomSplitterLayoutHeight()
end

function onIncreaseLeftPanels()
	if not canIncreaseLeftSidePanels() then
		return
	end

	if not modules.client_options.getOption("showLeftPanel") then
		modules.client_options.setOption("showLeftPanel", true, true)
		refreshSidebarLayout()
		save()

		return
	end

	for _, panel in ipairs(gameLeftExtraPanels) do
		if panel and not panel:isDestroyed() and not panel:isOn() then
			if canAddSidebarColumn("left") then
				setSidebarPanelVisible(panel, true)
				modules.client_options.setOption("showLeftExtraPanel", true, true)
				refreshSidebarLayout()
				save()
			end

			return
		end
	end

	if createSideExtraPanel("left") then
		modules.client_options.setOption("showLeftExtraPanel", true, true)
	end
end

function onDecreaseLeftPanels()
	for index = #gameLeftExtraPanels, 1, -1 do
		local panel = gameLeftExtraPanels[index]

		if panel and not panel:isDestroyed() and panel:isOn() then
			if index > 1 then
				destroySideExtraPanel("left", index)
			else
				closeSidebarMiniwindows(panel)
				setSidebarPanelVisible(panel, false)
				scheduleSidebarLayoutUpdate()
				addEvent(maximizeMapAfterSidebarRemoval)
			end

			modules.client_options.setOption("showLeftExtraPanel", countVisibleExtraPanels("left") > 0, true)
			save()

			return
		end
	end

	if not g_platform.isMobile() and modules.client_options.getOption("showLeftPanel") then
		modules.client_options.setOption("showLeftPanel", false)
		closeSidebarMiniwindows(gameLeftPanel)
		refreshSidebarLayout()
		save()
		addEvent(maximizeMapAfterSidebarRemoval)
	end
end

function onIncreaseRightPanels()
	if not canIncreaseRightSidePanels() then
		return
	end

	for _, panel in ipairs(gameRightExtraPanels) do
		if panel and not panel:isDestroyed() and not panel:isOn() then
			if canAddSidebarColumn("right") then
				setSidebarPanelVisible(panel, true)
				modules.client_options.setOption("showRightExtraPanel", true, true)
				refreshSidebarLayout()
				save()
			end

			return
		end
	end

	if createSideExtraPanel("right") then
		modules.client_options.setOption("showRightExtraPanel", true, true)
	end
end

function onDecreaseRightPanels()
	for index = #gameRightExtraPanels, 1, -1 do
		local panel = gameRightExtraPanels[index]

		if panel and not panel:isDestroyed() and panel:isOn() then
			if index > 1 then
				destroySideExtraPanel("right", index)
			else
				closeSidebarMiniwindows(panel)
				setSidebarPanelVisible(panel, false)
				scheduleSidebarLayoutUpdate()
				addEvent(maximizeMapAfterSidebarRemoval)
			end

			modules.client_options.setOption("showRightExtraPanel", countVisibleExtraPanels("right") > 0, true)
			save()

			return
		end
	end
end

function setupOptionsMainButton()
	if logOutMainButton then
		return
	end

	logOutMainButton = modules.game_mainpanel.addSpecialToggleButton("logoutButton", tr("Exit"), "/images/options/button_logout", tryLogout)
end

function checkAndOpenLeftPanel()
	leftDecreaseSidePanels:setEnabled(true)

	if not modules.client_options.getOption("showLeftPanel") then
		modules.client_options.setOption("showLeftPanel", true)

		return
	end
end

function testExtendedView(mode)
	local extendedView = mode == 2

	if extendedView then
		local buttons = {
			leftIncreaseSidePanels,
			rightIncreaseSidePanels,
			rightDecreaseSidePanels,
			leftDecreaseSidePanels
		}

		for _, button in ipairs(buttons) do
			button:hide()
		end

		if not g_platform.isMobile() then
			gameBottomPanel:breakAnchors()
			gameBottomPanel:bindRectToParent()
			gameBottomPanel:setDraggable(true)
		else
			gameBottomPanel:setWidth(g_window.getWidth() - mobileConfig.mobileWidthJoystick - mobileConfig.mobileWidthShortcuts)
			gameBottomPanel:setPosition({
				x = mobileConfig.mobileWidthJoystick,
				y = gameBottomPanel:getY()
			})
		end

		gameBottomPanel:getChildById("rightResizeBorder"):setMaximum(gameBottomPanel:getWidth())
		gameBottomPanel:getChildById("bottomResizeBorder"):enable()
		gameBottomPanel:getChildById("rightResizeBorder"):enable()
		bottomSplitter:setVisible(false)
		gameMainRightPanel:setHeight(0)
		gameMainRightPanel:setImageColor("alpha")
	else
		gameMainRightPanel:setHeight(200)
		gameMainRightPanel:setMarginTop(0)
		gameMainRightPanel:setImageColor("white")

		local buttons = {
			leftIncreaseSidePanels,
			rightIncreaseSidePanels,
			rightDecreaseSidePanels,
			leftDecreaseSidePanels
		}

		for _, button in ipairs(buttons) do
			button:setMarginTop(0)
			button:show()
		end

		gameBottomPanel:setDraggable(false)
		bottomSplitter:setVisible(true)

		if not g_platform.isMobile() then
			refreshSidebarLayout()
		end

		gameBottomPanel:getChildById("bottomResizeBorder"):disable()
		gameBottomPanel:getChildById("rightResizeBorder"):disable()

		local children = gameRightPanel:getChildren()

		for _, child in ipairs(children) do
			if child.moveOnlyToMain then
				child:setParent(gameMainRightPanel)
			end
		end
	end

	addEvent(function()
		modules.game_console.setExtendedView(extendedView)
		modules.game_healthinfo.extendedView(extendedView)
		modules.game_inventory.extendedView(extendedView)
		modules.client_topmenu.extendedView(extendedView)
		modules.game_mainpanel.toggleExtendedViewButtons(extendedView)
	end)
end

function openHelper()
	modules.game_helper.toggle()
end
