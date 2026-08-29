-- chunkname: @/game_analysers/analyser.lua

analyserMiniWindow = nil

if not configPopupWindow then
	configPopupWindow = {}
end

openedWindows = {}

local MISC_PROC_OPCODE = 204

local ANALYSER_CHAR_MINIWINDOW_IDS = {
	lootAnalyserMiniWindow = true,
	huntingAnalyserMiniWindow = true,
	analyserMiniWindow = true,
	bossCdAnalyserMiniWindow = true,
	miscAnalyserMiniWindow = true,
	phAnalyserMiniWindow = true,
	dropTrackerMiniWindow = true,
	xpAnalyserMiniWindow = true,
	inputAnalyserMiniWindow = true,
	impactAnalyserMiniWindow = true,
	supplyAnalyserMiniWindow = true
}

ANALYZER_HEAL = 0
ANALYZER_DAMAGE_DEALT = 1
ANALYZER_DAMAGE_RECEIVED = 2
PriceTypeEnum = {
	Market = 0,
	Leader = 1
}
LoadedPlayer = LoadedPlayer or {}

function LoadedPlayer:isLoaded()
	return g_game.getLocalPlayer() ~= nil
end

function LoadedPlayer:getId()
	local p = g_game.getLocalPlayer()

	return p and p:getId() or 0
end

local relocateAnalyserMiniWindowIfNeeded

local function sanitizeAnalyserMiniWindowDockLayout(char)
	if not char or char == "" then
		return
	end

	local settings = g_settings.getNode("CharMiniWindows")

	if not settings or not settings[char] then
		return
	end

	local rw = rawget(_G, "rootWidget")
	local changed = false

	for widgetId, _ in pairs(ANALYSER_CHAR_MINIWINDOW_IDS) do
		local s = settings[char][widgetId]

		if s then
			if s.index ~= nil and s.index ~= "" then
				local idx = tonumber(s.index)

				if not idx or idx ~= math.floor(idx) or idx < 1 or idx > 1000 then
					s.parentId = nil
					s.index = nil
					s.position = nil
					changed = true
				end
			end

			if s.parentId and s.parentId ~= "" then
				local parent

				if rw and rw.recursiveGetChildById then
					parent = rw:recursiveGetChildById(s.parentId)
				end

				local badDock = false

				if parent == nil or type(parent) ~= "userdata" then
					badDock = true
				elseif parent.isDestroyed and parent:isDestroyed() then
					badDock = true
				elseif parent.getClassName and parent:getClassName() ~= "UIMiniWindowContainer" then
					badDock = true
				elseif parent.isVisible and not parent:isVisible() then
					badDock = true
				elseif parent.isOn and type(parent.isOn) == "function" and not parent:isOn() then
					badDock = true
				elseif s.index and type(parent.scheduleInsert) ~= "function" then
					badDock = true
				end

				if badDock then
					s.parentId = nil
					s.index = nil
					s.position = nil
					changed = true
				end
			end
		end
	end

	if changed then
		g_settings.setNode("CharMiniWindows", settings)
	end
end

local function forEachAnalyserMiniWindow(fn)
	if analyserMiniWindow and not analyserMiniWindow:isDestroyed() then
		fn(analyserMiniWindow)
	end

	for _, w in pairs(openedWindows) do
		if w and not w:isDestroyed() then
			fn(w)
		end
	end
end

local function setupAnalyserMiniWindowsOnChar()
	if not g_game.isOnline() then
		return
	end

	local char = g_game.getCharacterName()

	if not char or char == "" then
		return
	end

	sanitizeAnalyserMiniWindowDockLayout(char)
	forEachAnalyserMiniWindow(function(w)
		if not w.setupOnStart or w:isDestroyed() then
			return
		end

		if w.getClassName and w:getClassName() ~= "UIMiniWindow" then
			return
		end

		local wid = w.getId and w:getId() or "?"
		local ok, err = pcall(function()
			w:setupOnStart()
		end)

		if not ok then
			g_logger.warning("[game_analysers] setupOnStart falhou para " .. tostring(wid) .. ": " .. tostring(err))
		end

		relocateAnalyserMiniWindowIfNeeded(w)
	end)
end

local function persistAnalyserMiniWindowsLayout()
	local char = g_game.getCharacterName()

	if not char or char == "" then
		return
	end

	forEachAnalyserMiniWindow(function(w)
		if not w.saveSelfIndex then
			return
		end

		local p
		local okP = pcall(function()
			p = w:getParent()
		end)

		if not okP then
			return
		end

		if p and type(p) == "userdata" and (not p.isDestroyed or not p:isDestroyed()) and p.getClassName and p:getClassName() == "UIMiniWindowContainer" then
			pcall(function()
				w:saveSelfIndex()

				if w.isResizeable and w:isResizeable() and not w:isOn() then
					w:setSettings({
						height = w:getHeight()
					})
				end
			end)
		end
	end)
end

local ANALYSER_GRAPH_LINE_COLOR = "#FF0000"

ANALYSER_GRAPH_CAPACITY_60_MIN = 60
ANALYSER_GRAPH_PUSH_INTERVAL_60_MIN_MS = 60000
ANALYSER_GRAPH_CAPACITY_4_MIN = 240
ANALYSER_GRAPH_PUSH_INTERVAL_4_MIN_MS = 1000

function analyserUIGraphSetCapacity(graphWidget, capacity)
	if not graphWidget or graphWidget:isDestroyed() or not graphWidget.setCapacity then
		return
	end

	graphWidget:setCapacity(math.max(1, tonumber(capacity) or 1))
end

function analyserUIGraphEnsureSeries(graphWidget, lineColor)
	if not graphWidget or graphWidget:isDestroyed() then
		return false
	end

	lineColor = lineColor or ANALYSER_GRAPH_LINE_COLOR

	if graphWidget.getGraphsCount and graphWidget:getGraphsCount() == 0 then
		graphWidget:createGraph()

		if graphWidget.setLineWidth then
			graphWidget:setLineWidth(1, 1)
		end

		if graphWidget.setLineColor then
			graphWidget:setLineColor(1, lineColor)
		end
	end

	return true
end

function analyserUIGraphReset(graphWidget, lineColor, capacity)
	if not graphWidget then
		return
	end

	if capacity then
		analyserUIGraphSetCapacity(graphWidget, capacity)
	end

	graphWidget:clear()
	analyserUIGraphEnsureSeries(graphWidget, lineColor)
	graphWidget:addValue(1, 0)
end

function analyserConfigureGraphWidgets()
	if LootAnalyser and LootAnalyser.window and LootAnalyser.window.contentsPanel then
		analyserUIGraphSetCapacity(LootAnalyser.window.contentsPanel.graphPanel, ANALYSER_GRAPH_CAPACITY_60_MIN)
	end

	if SupplyAnalyser and SupplyAnalyser.window and SupplyAnalyser.window.contentsPanel then
		analyserUIGraphSetCapacity(SupplyAnalyser.window.contentsPanel.graphPanel, ANALYSER_GRAPH_CAPACITY_60_MIN)
	end

	if XPAnalyser and XPAnalyser.window and XPAnalyser.window.contentsPanel then
		analyserUIGraphSetCapacity(XPAnalyser.window.contentsPanel.graphPanel, ANALYSER_GRAPH_CAPACITY_60_MIN)
	end

	if ImpactAnalyser and ImpactAnalyser.window and ImpactAnalyser.window.contentsPanel then
		local cp = ImpactAnalyser.window.contentsPanel

		analyserUIGraphSetCapacity(cp.graphDpsPanel, ANALYSER_GRAPH_CAPACITY_4_MIN)
		analyserUIGraphSetCapacity(cp.graphHealPanel, ANALYSER_GRAPH_CAPACITY_4_MIN)
	end

	if InputAnalyser and InputAnalyser.window and InputAnalyser.window.contentsPanel then
		analyserUIGraphSetCapacity(InputAnalyser.window.contentsPanel.graphPanel, ANALYSER_GRAPH_CAPACITY_4_MIN)
	end
end

function analyserUIGraphPushValue(graphWidget, value, lineColor)
	if not analyserUIGraphEnsureSeries(graphWidget, lineColor) then
		return
	end

	local v = math.floor(math.max(0, tonumber(value) or 0))

	graphWidget:addValue(1, v)
end

local analyserWindows = {
	damageButton = "menus/InputAnalyser",
	bossButton = "menus/BossCooldown",
	miscButton = "menus/MiscAnalyser",
	impactButton = "menus/ImpactAnalyser",
	supplyButton = "menus/SupplyAnalyser",
	lootButton = "menus/LootAnalyser",
	huntingButton = "menus/HuntingAnalyser",
	partyButton = "menus/PartyHuntAnalyser",
	dropButton = "menus/DropTrackerAnalyser",
	xpButton = "menus/XPAnalyser"
}

function formatMoney(n)
	local s = string.format("%.0f", n)
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

function getItemServerName(itemId)
	local id = tonumber(itemId)

	if not id then
		return ""
	end

	local thingType = g_things.getThingType(id, ThingCategoryItem)

	if not thingType then
		return ""
	end

	local name = thingType:getName()

	if type(name) == "string" and name ~= "" then
		return name
	end

	local marketData = thingType:getMarketData()

	if marketData and type(marketData.name) == "string" and marketData.name ~= "" then
		return marketData.name
	end

	return string.format("#%d", id)
end

local function analyserColumnSlack(panel, widget, minH)
	if not panel or panel:isDestroyed() or not panel.getClassName or panel:getClassName() ~= "UIMiniWindowContainer" then
		return -math.huge
	end

	if panel.ignoreFillAll then
		return math.huge
	end

	local containerPanel = widget:getChildById("contentsPanel")

	if not containerPanel then
		return -math.huge
	end

	local ind = containerPanel:getMarginTop() + containerPanel:getMarginBottom() + containerPanel:getPaddingTop() + containerPanel:getPaddingBottom()
	local totalHeight = 0
	local children = panel:getChildren()

	for i = 1, #children do
		if children[i]:isVisible() then
			totalHeight = totalHeight + children[i]:getHeight()
		end
	end

	local available = panel:getHeight() - panel:getPaddingTop() - panel:getPaddingBottom() - totalHeight

	return available - ind - minH
end

local function analyserSidebarPanelsInPriorityOrder()
	local gi = modules.game_interface

	if not gi or not gi.getMiniWindowSidebarPanelsInOrder then
		return {}
	end

	return gi.getMiniWindowSidebarPanelsInOrder()
end

local function analysersSidebarContainerOk(panel)
	if panel == nil or type(panel) ~= "userdata" then
		return false
	end

	if panel.isDestroyed and panel:isDestroyed() then
		return false
	end

	if not panel.getClassName or panel:getClassName() ~= "UIMiniWindowContainer" then
		return false
	end

	return true
end

local function analyserWidgetMinimumHeight(win)
	if not win or win:isDestroyed() or not win.getMinimumHeight then
		return 0
	end

	return tonumber(win:getMinimumHeight()) or 0
end

local function analyserSubWindowShowsOpen(win)
	if not win or win:isDestroyed() then
		return false
	end

	if win.isHidden then
		return not win:isHidden()
	end

	if win.isVisible then
		return win:isVisible()
	end

	return false
end

local function analyserPanelAcceptsWidget(panel, widget, minH)
	if not analysersSidebarContainerOk(panel) then
		return false
	end

	if not panel:isVisible() then
		return false
	end

	if panel.isOn and not panel:isOn() then
		return false
	end

	minH = minH or analyserWidgetMinimumHeight(widget)

	local parent = widget and widget:getParent()

	if widget and parent == panel and not analyserSubWindowShowsOpen(widget) then
		return analyserColumnSlack(panel, widget, minH) >= 0
	end

	if not panel.fits then
		return false
	end

	return panel:fits(widget, minH, 0) >= 0
end

local function findAnalyserSidebarPanelFor(widget, minH)
	minH = minH or analyserWidgetMinimumHeight(widget)

	for _, panel in ipairs(analyserSidebarPanelsInPriorityOrder()) do
		if analyserPanelAcceptsWidget(panel, widget, minH) then
			return panel
		end
	end

	return nil
end

local function attachAnalyserToSidebarPanel(widget, panel)
	if not widget or widget:isDestroyed() or not analysersSidebarContainerOk(panel) then
		return false
	end

	local oldParent = widget:getParent()

	if oldParent == panel then
		return true
	end

	if oldParent and not oldParent:isDestroyed() then
		pcall(function()
			oldParent:removeChild(widget)
		end)
	end

	local attached = false

	if panel.scheduleInsert then
		local ok = pcall(function()
			panel:scheduleInsert(widget, panel:getChildCount() + 1)
		end)

		attached = ok and widget:getParent() == panel
	end

	if not attached then
		local ok = pcall(function()
			if not panel:hasChild(widget) then
				panel:addChild(widget)
			end
		end)

		attached = ok and widget:getParent() == panel
	end

	if not attached then
		return false
	end

	if panel.fitAll then
		pcall(function()
			panel:fitAll(widget)
		end)
	end

	if widget.saveParent then
		pcall(function()
			widget:saveParent(panel)
		end)
	end

	if panel.order then
		addEvent(function()
			if panel and not panel:isDestroyed() then
				pcall(function()
					panel:order()
				end)
			end
		end)
	end

	return true
end

local function addAnalyserToPanel(widget)
	if not widget or widget:isDestroyed() then
		return false
	end

	local minH = analyserWidgetMinimumHeight(widget)
	local panel = findAnalyserSidebarPanelFor(widget, minH)

	if not panel then
		return false
	end

	if widget:getParent() == panel then
		return true
	end

	local ok = attachAnalyserToSidebarPanel(widget, panel)

	return ok
end

local function moveAnalyserToPanelEnd(widget)
	if not widget or widget:isDestroyed() then
		return
	end

	local parent = widget:getParent()

	if not parent or parent:isDestroyed() or not parent.moveChildToIndex then
		return
	end

	local n = parent.getChildCount and parent:getChildCount() or 0

	if n < 1 then
		return
	end

	parent:moveChildToIndex(widget, n)
end

local ANALYSER_SELECTOR_STACK_ID = "__selector__"
local analyserOpenStack = {}

local function untrackAnalyserClosed(buttonId)
	for i = #analyserOpenStack, 1, -1 do
		if analyserOpenStack[i] == buttonId then
			table.remove(analyserOpenStack, i)
		end
	end
end

local function trackAnalyserOpened(buttonId)
	untrackAnalyserClosed(buttonId)

	analyserOpenStack[#analyserOpenStack + 1] = buttonId
end

local function analyserSidebarHasSpaceFor(win)
	if not win or win:isDestroyed() then
		return true
	end

	return findAnalyserSidebarPanelFor(win) ~= nil
end

function relocateAnalyserMiniWindowIfNeeded(widget)
	if not widget or widget:isDestroyed() then
		return
	end

	local wid = widget.getId and widget:getId()

	if wid ~= "analyserMiniWindow" and not ANALYSER_CHAR_MINIWINDOW_IDS[wid or ""] then
		return
	end

	local cur
	local okGp, gpRet = pcall(function()
		return widget:getParent()
	end)

	cur = okGp and gpRet or nil

	if analysersSidebarContainerOk(cur) then
		return
	end

	addAnalyserToPanel(widget)
end

local function setAnalyserMainPanelButtonOn(on)
	if not modules.game_mainpanel or not modules.game_mainpanel.getButton then
		return
	end

	local b = modules.game_mainpanel.getButton("analyticsSelectorWidget")

	if not b then
		return
	end

	if b.setOn then
		b:setOn(on)
	end

	if b.setTooltip then
		b:setTooltip(tr(on and "Close Analytics Selector Window" or "Open Analytics Selector Window"))
	end
end

local function anyAnalyserSubWindowVisible()
	for _, w in pairs(openedWindows) do
		if analyserSubWindowShowsOpen(w) then
			return true
		end
	end

	return false
end

local function refreshAnalyserMainPanelButtonFromWindows()
	local selectorOpen = analyserMiniWindow and analyserMiniWindow.isVisible and analyserMiniWindow:isVisible()

	setAnalyserMainPanelButtonOn(selectorOpen)
end

local function syncAnalyticsSelectorRowButtons()
	if not analyserMiniWindow or analyserMiniWindow:isDestroyed() then
		return
	end

	for buttonId, win in pairs(openedWindows) do
		local b = analyserMiniWindow:recursiveGetChildById(buttonId)

		if b and b.setOn and win then
			b:setOn(analyserSubWindowShowsOpen(win))
		end
	end

	local helperStatsButton = analyserMiniWindow:recursiveGetChildById("helperStatsButton")
	if helperStatsButton and helperStatsButton.setOn then
		local helperOpen = modules.game_helper and modules.game_helper.isHelperStatsWindowOpen and modules.game_helper.isHelperStatsWindowOpen()
		helperStatsButton:setOn(helperOpen == true)
	end

	refreshAnalyserMainPanelButtonFromWindows()
end

function onHelperStatsVisibilityChange()
	syncAnalyticsSelectorRowButtons()
end

local function closeAnyVisibleAnalyser(excludedButtonId)
	if excludedButtonId ~= ANALYSER_SELECTOR_STACK_ID and analyserMiniWindow and not analyserMiniWindow:isDestroyed() and analyserSubWindowShowsOpen(analyserMiniWindow) then
		analyserMiniWindow:close()

		analyserMiniWindow.isOpen = false

		untrackAnalyserClosed(ANALYSER_SELECTOR_STACK_ID)
		syncAnalyticsSelectorRowButtons()

		return true
	end

	for buttonId, wsub in pairs(openedWindows) do
		if buttonId ~= excludedButtonId and wsub and not wsub:isDestroyed() and analyserSubWindowShowsOpen(wsub) then
			wsub:close()

			wsub.isOpen = false

			untrackAnalyserClosed(buttonId)
			syncAnalyticsSelectorRowButtons()

			return true
		end
	end

	return false
end

local function closeLastOpenedAnalyser(excludedButtonId)
	for i = #analyserOpenStack, 1, -1 do
		local bid = analyserOpenStack[i]

		if bid ~= excludedButtonId then
			table.remove(analyserOpenStack, i)

			if bid == ANALYSER_SELECTOR_STACK_ID then
				if analyserMiniWindow and not analyserMiniWindow:isDestroyed() and analyserSubWindowShowsOpen(analyserMiniWindow) then
					analyserMiniWindow:close()

					analyserMiniWindow.isOpen = false

					syncAnalyticsSelectorRowButtons()

					return true
				end
			else
				local wsub = openedWindows[bid]

				if wsub and not wsub:isDestroyed() and analyserSubWindowShowsOpen(wsub) then
					wsub:close()

					wsub.isOpen = false

					syncAnalyticsSelectorRowButtons()

					return true
				end
			end
		end
	end

	return closeAnyVisibleAnalyser(excludedButtonId)
end

local function ensureAnalyserSidebarSpace(widgetToOpen, excludedButtonId)
	if analyserSidebarHasSpaceFor(widgetToOpen) then
		return true
	end

	local maxAttempts = math.max(#analyserOpenStack, 1) + 8

	for _ = 1, maxAttempts do
		if not closeLastOpenedAnalyser(excludedButtonId) then
			break
		end

		if analyserSidebarHasSpaceFor(widgetToOpen) then
			syncAnalyticsSelectorRowButtons()

			return true
		end
	end

	return analyserSidebarHasSpaceFor(widgetToOpen)
end

local function registerAnalyserMainPanelButton()
	if not modules.game_mainpanel or not modules.game_mainpanel.addToggleButton then
		return
	end

	modules.game_mainpanel.addToggleButton("analyticsSelectorWidget", tr("Open Analytics Selector Window"), "/images/options/button_analytics", function()
		if modules.game_analysers and modules.game_analysers.toggleAnalyserWindow then
			modules.game_analysers.toggleAnalyserWindow()
		end
	end, false, 950)
end

function init()
	registerAnalyserMainPanelButton()

	analyserMiniWindow = g_ui.loadUI("analyser", modules.game_interface.getRightPanel())

	analyserMiniWindow:close()
	analyserMiniWindow:setup()

	configPopupWindow.lootButton = g_ui.displayUI("menus/lootTarget")

	configPopupWindow.lootButton:hide()

	configPopupWindow.supplyButton = g_ui.displayUI("menus/supplyTarget")

	configPopupWindow.supplyButton:hide()

	configPopupWindow.impactButton = g_ui.displayUI("menus/dpshpsTarget")

	configPopupWindow.impactButton:hide()

	configPopupWindow.xpButton = g_ui.displayUI("menus/xpTarget")

	configPopupWindow.xpButton:hide()

	configPopupWindow.dropButton = g_ui.displayUI("menus/dropTarget")

	configPopupWindow.dropButton:hide()

	huntingButton = analyserMiniWindow:recursiveGetChildById("huntingButton")
	lootButton = analyserMiniWindow:recursiveGetChildById("lootButton")
	supplyButton = analyserMiniWindow:recursiveGetChildById("supplyButton")
	impactButton = analyserMiniWindow:recursiveGetChildById("impactButton")
	damageButton = analyserMiniWindow:recursiveGetChildById("damageButton")
	xpButton = analyserMiniWindow:recursiveGetChildById("xpButton")
	dropButton = analyserMiniWindow:recursiveGetChildById("dropButton")
	partyButton = analyserMiniWindow:recursiveGetChildById("partyButton")
	bossButton = analyserMiniWindow:recursiveGetChildById("bossButton")
	miscButton = analyserMiniWindow:recursiveGetChildById("miscButton")
	local helperStatsButton = analyserMiniWindow:recursiveGetChildById("helperStatsButton")
	if helperStatsButton then
		function helperStatsButton.onClick()
			if modules.game_helper and modules.game_helper.toggleHelperStatsWindow then
				modules.game_helper.toggleHelperStatsWindow()
			end
			syncAnalyticsSelectorRowButtons()
		end
	end

	for id, style in pairs(analyserWindows) do
		openedWindows[id] = g_ui.loadUI(style, modules.game_interface.getRightPanel())

		if openedWindows[id] then
			openedWindows[id]:setup()

			openedWindows[id].closeButton.onClick = function()
				toggleAnalysers(id)
			end

			openedWindows[id]:close()

			local scrollbar = openedWindows[id]:getChildById("miniwindowScrollBar")

			if scrollbar then
				scrollbar:mergeStyle({
					["$!on"] = {}
				})
			end
		end
	end

	for bid, _ in pairs(analyserWindows) do
		local bt = analyserMiniWindow and analyserMiniWindow:recursiveGetChildById(bid)

		if bt then
			function bt.onClick()
				toggleAnalysers(bid)
			end
		end

		local mw = openedWindows[bid]

		if mw then
			function mw.onVisibilityChange()
				syncAnalyticsSelectorRowButtons()
			end
		end
	end

	HuntingAnalyser:create()
	HuntingAnalyser:updateWindow(true)
	LootAnalyser:create()
	LootAnalyser:updateWindow(true, true)
	SupplyAnalyser:create()
	SupplyAnalyser:updateWindow(true, true)
	ImpactAnalyser:create()
	ImpactAnalyser:updateWindow(true)
	InputAnalyser:create()
	InputAnalyser:updateWindow(true)
	XPAnalyser:create()
	XPAnalyser:updateWindow(true)
	DropTrackerAnalyser:create()
	DropTrackerAnalyser:updateWindow(true)
	PartyHuntAnalyser:create()
	PartyHuntAnalyser:updateWindow(false, true)
	BossCooldown:create()
	BossCooldown:updateWindow()
	MiscAnalyser:create()
	MiscAnalyser:updateWindow()
	pcall(function()
		ProtocolGame.unregisterExtendedOpcode(MISC_PROC_OPCODE)
	end)
	ProtocolGame.registerExtendedOpcode(MISC_PROC_OPCODE, onMiscProcTracker)
	analyserConfigureGraphWidgets()
	connect(g_game, {
		onGameStart = onlineAnalyser,
		onGameEnd = offlineAnalyser,
		onSupplyTracker = onSupplyTracker,
		onLootStats = onLootStats,
		onImpactTracker = onImpactTracker,
		onKillTracker = onKillTracker,
		onPartyAnalyzer = onPartyAnalyzer,
		onBossCooldown = onBossCooldown,
		onUpdateExperience = onUpdateExperience
	})
	connect(LocalPlayer, {
		onExperienceChange = onExperienceChange,
		onLevelChange = onLevelChange,
		onPartyMembersChange = onPartyMembersChange
	})
	connect(Creature, {
		onShieldChange = onShieldChange
	})

	if g_game.isOnline() then
		addEvent(function()
			setupAnalyserMiniWindowsOnChar()
			syncAnalyticsSelectorRowButtons()
		end)
	end
end

function terminate()
	pcall(function()
		ProtocolGame.unregisterExtendedOpcode(MISC_PROC_OPCODE)
	end)

	if ControllerAnalyser then
		removeEvent(ControllerAnalyser.event250)
		removeEvent(ControllerAnalyser.event1000)
		removeEvent(ControllerAnalyser.event2000)
		removeEvent(ControllerAnalyser.eventGraph)

		ControllerAnalyser.event250 = nil
		ControllerAnalyser.event1000 = nil
		ControllerAnalyser.event2000 = nil
		ControllerAnalyser.eventGraph = nil
	end

	if PartyHuntAnalyser and PartyHuntAnalyser.event then
		PartyHuntAnalyser.event:cancel()

		PartyHuntAnalyser.event = nil
	end

	persistAnalyserMiniWindowsLayout()

	if analyserMiniWindow then
		analyserMiniWindow:destroy()

		analyserMiniWindow = nil
	end

	for _, w in pairs(openedWindows) do
		w:destroy()
	end

	openedWindows = {}
	analyserOpenStack = {}

	for _, w in pairs(configPopupWindow) do
		w:destroy()
	end

	configPopupWindow = {}

	disconnect(g_game, {
		onGameStart = onlineAnalyser,
		onGameEnd = offlineAnalyser,
		onSupplyTracker = onSupplyTracker,
		onLootStats = onLootStats,
		onImpactTracker = onImpactTracker,
		onKillTracker = onKillTracker,
		onPartyAnalyzer = onPartyAnalyzer,
		onBossCooldown = onBossCooldown,
		onUpdateExperience = onUpdateExperience
	})
	disconnect(LocalPlayer, {
		onExperienceChange = onExperienceChange,
		onLevelChange = onLevelChange,
		onPartyMembersChange = onPartyMembersChange
	})
	disconnect(Creature, {
		onShieldChange = onShieldChange
	})
end

function startNewSession(login)
	AnalyserSession:reset()
	HuntingAnalyser:reset()

	if login then
		HuntingAnalyser:loadConfigJson()
	end

	HuntingAnalyser:updateWindow(true)
	LootAnalyser:reset()
	LootAnalyser:updateWindow(true, true)
	SupplyAnalyser:reset()
	SupplyAnalyser:updateWindow(true, true)
	ImpactAnalyser:reset()

	if login then
		ImpactAnalyser:loadConfigJson()
	end

	ImpactAnalyser:updateWindow(true)
	InputAnalyser:reset()

	if login then
		InputAnalyser:loadConfigJson()
	end

	InputAnalyser:updateWindow(true)
	XPAnalyser:reset()
	XPAnalyser:updateWindow(true)
	DropTrackerAnalyser:reset(login)

	if login then
		DropTrackerAnalyser:loadConfigJson()
	end

	DropTrackerAnalyser:updateWindow(true)
	PartyHuntAnalyser:reset()
	PartyHuntAnalyser:updateWindow(true, true)
	MiscAnalyser:reset()
	ControllerAnalyser:startEvent()
end

function onlineAnalyser()
	addEvent(function()
		setupAnalyserMiniWindowsOnChar()
		syncAnalyticsSelectorRowButtons()
	end)
	startNewSession(true)
	loadGainAndWastConfigJson()
	syncAnalyticsSelectorRowButtons()
end

function offlineAnalyser()
	persistAnalyserMiniWindowsLayout()
	HuntingAnalyser:saveConfigJson()
	ImpactAnalyser:saveConfigJson()
	InputAnalyser:saveConfigJson()
	XPAnalyser:saveConfigJson()
	DropTrackerAnalyser:saveConfigJson()
	saveGainAndWastConfigJson()
	BossCooldown:reset()
	MiscAnalyser:reset()
end

-- Public entry point used by protocol/custom modules that know the proc source.
-- category: charm, imbuement, itemUpgrade or awakenedProcs
function onMiscAnalyserEvent(category, name, amount)
	if MiscAnalyser then
		MiscAnalyser:add(category, name, amount)
	end
end

function onMiscProcTracker(protocol, opcode, buffer)
	if MiscAnalyser then
		MiscAnalyser:onProtocolBuffer(buffer)
	end
end

function toggleAnalyserWindow()
	if analyserMiniWindow:isVisible() then
		analyserMiniWindow:close()

		analyserMiniWindow.isOpen = false

		untrackAnalyserClosed(ANALYSER_SELECTOR_STACK_ID)
		syncAnalyticsSelectorRowButtons()
	else
		ensureAnalyserSidebarSpace(analyserMiniWindow, ANALYSER_SELECTOR_STACK_ID)

		if not addAnalyserToPanel(analyserMiniWindow) then
			syncAnalyticsSelectorRowButtons()

			return
		end

		addEvent(function()
			if not analyserMiniWindow or analyserMiniWindow:isDestroyed() then
				return
			end

			analyserMiniWindow:open()

			analyserMiniWindow.isOpen = true

			trackAnalyserOpened(ANALYSER_SELECTOR_STACK_ID)
			syncAnalyticsSelectorRowButtons()
		end)
	end
end

function hideAnalyser()
	analyserMiniWindow:close()

	analyserMiniWindow.isOpen = false

	untrackAnalyserClosed(ANALYSER_SELECTOR_STACK_ID)
	syncAnalyticsSelectorRowButtons()
end

function onOpenAnalyser()
	local isOn = analyserMiniWindow.isOn and analyserMiniWindow:isOn()

	if not isOn then
		analyserMiniWindow:setHeight(276)
	end

	analyserMiniWindow.isOpen = true

	syncAnalyticsSelectorRowButtons()

	local cp = analyserMiniWindow.getChildById and analyserMiniWindow:getChildById("contentsPanel")
	local cpCount = cp and cp.getChildCount and cp:getChildCount() or 0
end

function toggleAnalysers(buttonId)
	local widget = openedWindows[buttonId]

	if not widget then
		return
	end

	if analyserSubWindowShowsOpen(widget) then
		widget:close()

		widget.isOpen = false

		untrackAnalyserClosed(buttonId)
		syncAnalyticsSelectorRowButtons()
	else
		ensureAnalyserSidebarSpace(widget, buttonId)

		if not addAnalyserToPanel(widget) then
			syncAnalyticsSelectorRowButtons()

			return
		end

		widget.isOpen = true

		local selectorButton = analyserMiniWindow and analyserMiniWindow:recursiveGetChildById(buttonId)

		if selectorButton and selectorButton.setOn then
			selectorButton:setOn(true)
		end

		local bid = buttonId

		addEvent(function()
			if not widget or widget:isDestroyed() then
				return
			end

			widget:open()
			trackAnalyserOpened(bid)

			if bid == "impactButton" then
				ImpactAnalyser:checkAnchos()
			elseif bid == "damageButton" then
				InputAnalyser:checkAnchos()
				InputAnalyser:updateWindow(true)
			elseif bid == "xpButton" then
				XPAnalyser:checkAnchos()
			elseif bid == "bossButton" then
				widget:focus()
			elseif bid == "xpAnalyser" then
				XPAnalyser:checkAnchos()
			end

			syncAnalyticsSelectorRowButtons()
		end)
	end
end

function onExperienceChange(localPlayer, value, oldValue)
	HuntingAnalyser:setupStartExp(value)
	XPAnalyser:setupStartExp(value)

	-- Regular monster XP is reported by onUpdateExperience. A death loss only
	-- arrives through LocalPlayer:onExperienceChange, so account for decreases
	-- here without duplicating positive gains.
	value = tonumber(value)
	oldValue = tonumber(oldValue)

	if value and oldValue and oldValue > 0 and value < oldValue then
		local lostExperience = value - oldValue

		HuntingAnalyser:addRawXPGain(lostExperience)
		HuntingAnalyser:addXpGain(lostExperience)
		XPAnalyser:addRawXPGain(lostExperience)
		XPAnalyser:addXpGain(lostExperience)
	end
end

function onUpdateExperience(rawExp, exp)
	HuntingAnalyser:addRawXPGain(rawExp)
	HuntingAnalyser:addXpGain(exp)
	XPAnalyser:addRawXPGain(rawExp)
	XPAnalyser:addXpGain(exp)
end

function onLootStats(item, name)
	HuntingAnalyser:addLootedItems(item, name)
	LootAnalyser:addLootedItems(item, name)
end

function onSupplyTracker(itemId)
	HuntingAnalyser:addSuppliesItems(itemId)
	SupplyAnalyser:addSuppliesItems(itemId)
end

function onImpactTracker(analyzerType, amount, effect, target)
	if analyzerType == ANALYZER_HEAL then
		HuntingAnalyser:addHealing(amount)
		ImpactAnalyser:addHealing(amount)
	elseif analyzerType == ANALYZER_DAMAGE_DEALT then
		HuntingAnalyser:addDealDamage(amount)
		ImpactAnalyser:addDealDamage(amount, effect)
	elseif analyzerType == ANALYZER_DAMAGE_RECEIVED then
		InputAnalyser:addInputDamage(amount, effect, target)
	end
end

function onKillTracker(monsterName, monsterOutfit, dropItems)
	HuntingAnalyser:addMonsterKilled(monsterName)
	DropTrackerAnalyser:checkMonsterKilled(monsterName, monsterOutfit, dropItems)
end

function getCurrentPrice(itemId)
	local thingType = g_things.getThingType(itemId, ThingCategoryItem)

	if not thingType then
		return 0
	end

	local price = 0

	if thingType and thingType.getNpcSaleData then
		local npcSaleData = thingType:getNpcSaleData()

		if npcSaleData then
			for _, npcData in pairs(npcSaleData) do
				if npcData.salePrice and price < npcData.salePrice then
					price = npcData.salePrice
				end
			end
		end
	end

	if itemId == 3031 then
		price = 1
	elseif itemId == 3035 then
		price = 100
	elseif itemId == 3043 then
		price = 10000
	end

	return price
end

function getLootPrice(itemId)
	local id = tonumber(itemId)

	if not id then
		return 0
	end

	local thingType = g_things.getThingType(id, ThingCategoryItem)

	if not thingType then
		return 0
	end

	local cyclopedia = modules.game_cyclopedia and modules.game_cyclopedia.Cyclopedia

	if cyclopedia and cyclopedia.getItemCustomSalePrice then
		local customPrice = cyclopedia.getItemCustomSalePrice(id)

		if customPrice and customPrice > 0 then
			return customPrice
		end
	end

	if id == 3031 then
		return 1
	elseif id == 3035 then
		return 100
	elseif id == 3043 then
		return 10000
	end

	if cyclopedia and cyclopedia.computeLootPrice then
		return cyclopedia.computeLootPrice(thingType) or 0
	end

	local price = 0

	if thingType.getNpcSaleData then
		local npcSaleData = thingType:getNpcSaleData()

		if npcSaleData then
			for _, npcData in pairs(npcSaleData) do
				if npcData.buyPrice and price < npcData.buyPrice then
					price = npcData.buyPrice
				end
			end
		end
	end

	return price
end

function loadGainAndWastConfigJson()
	local config = {
		gainGaugeTarget = 0,
		wasteGraphVisible = true,
		wasteGaugeVisible = true,
		wasteGaugeTarget = 0,
		gainGraphVisible = true,
		gainGaugeVisible = true
	}

	if not LoadedPlayer:isLoaded() then
		return
	end

	local file = "/characterdata/" .. LoadedPlayer:getId() .. "/gainandwaste.json"

	if g_resources.fileExists(file) then
		local status, result = pcall(function()
			return json.decode(g_resources.readFileContents(file))
		end)

		if not status then
			return g_logger.error("Error while reading characterdata file. Details: " .. result)
		end

		config = result
	end

	LootAnalyser:setLootPerHourGauge(config.gainGaugeVisible)
	LootAnalyser:setLootPerHourGraph(config.gainGraphVisible)
	LootAnalyser:setTarget(config.gainGaugeTarget)
	SupplyAnalyser:setSupplyPerHourGauge(config.wasteGaugeVisible)
	SupplyAnalyser:setSupplyPerHourGraph(config.wasteGraphVisible)
	SupplyAnalyser:setTarget(config.wasteGaugeTarget)
end

function saveGainAndWastConfigJson()
	if not LoadedPlayer:isLoaded() then
		return
	end

	local config = {
		gainGaugeTarget = LootAnalyser:getTarget(),
		gainGaugeVisible = LootAnalyser:gaugeIsVisible(),
		gainGraphVisible = LootAnalyser:graphIsVisible(),
		wasteGaugeTarget = SupplyAnalyser:getTarget(),
		wasteGaugeVisible = SupplyAnalyser:gaugeIsVisible(),
		wasteGraphVisible = SupplyAnalyser:graphIsVisible()
	}
	local file = "/characterdata/" .. LoadedPlayer:getId() .. "/gainandwaste.json"
	local status, result = pcall(function()
		return json.encode(config, 2)
	end)

	if not status then
		return g_logger.error("Error while saving profile Analyzer data. Data won't be saved. Details: " .. result)
	end

	if result:len() > 104857600 then
		return g_logger.error("Something went wrong, file is above 100MB, won't be saved")
	end

	g_resources.writeFileContents(file, result)
end

function checkNumber(self, text)
	if text == nil or text == "" then
		return
	end

	local digits = tostring(text):gsub("%D", "")
	local number = tonumber(digits)

	if (not number or number < 0) and #text > 0 then
		self:setText("0", false)
	end
end

function onLevelChange(localPlayer, value, percent)
	XPAnalyser:setupLevel(value, percent)
end

function managerDropTracker(itemId, checked)
	DropTrackerAnalyser:managerDropItem(itemId, checked)
end

function isInDropTracker(itemId)
	return DropTrackerAnalyser:isInDropTracker(itemId)
end

function onPartyAnalyzer(startTime, leaderID, lootType, membersData, membersNameOrIds, nameStrings)
	if type(membersData) == "table" and membersData[1] ~= nil and type(membersData[1]) == "table" then
		local md = {}

		for _, row in ipairs(membersData) do
			local id = tonumber(row[1])

			if id then
				md[id] = {
					tonumber(row[3]) or 0,
					tonumber(row[4]) or 0,
					tonumber(row[5]) or 0,
					tonumber(row[6]) or 0,
					(tonumber(row[2]) or 0) ~= 0
				}
			end
		end

		local mn = {}

		if type(membersNameOrIds) == "table" and membersNameOrIds[1] ~= nil and type(nameStrings) == "table" then
			if type(membersNameOrIds[1]) == "number" then
				for i = 1, #membersNameOrIds do
					local pid = tonumber(membersNameOrIds[i])

					if pid and nameStrings[i] then
						mn[pid] = nameStrings[i]
					end
				end
			elseif type(membersNameOrIds[1]) == "table" and type(membersNameOrIds[1][2]) == "string" then
				for _, pair in ipairs(membersNameOrIds) do
					local pid = tonumber(pair[1])

					if pid and pair[2] then
						mn[pid] = pair[2]
					end
				end
			end
		elseif type(membersNameOrIds) == "table" then
			mn = membersNameOrIds
		end

		PartyHuntAnalyser:onPartyAnalyzer(startTime, leaderID, lootType, md, mn)
	else
		PartyHuntAnalyser:onPartyAnalyzer(startTime, leaderID, lootType, membersData, membersNameOrIds)
	end
end

function onBossCooldown(cooldown)
	BossCooldown:setupCooldown(cooldown)
end
