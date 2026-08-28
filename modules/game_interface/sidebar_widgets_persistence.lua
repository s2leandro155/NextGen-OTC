-- chunkname: @/game_interface/sidebar_widgets_persistence.lua

SidebarWidgetsPersistence = {}

local SECTION_WIDGETS_MANAGER = "sidebarWidgetsMangerOptions"
local HORIZONTAL_PARENT_IDS = {
	"gameRightTopPanel",
	"gameLeftTopPanel"
}
local SECTION_FIELD_ORDER = {
	"leftHorizontalSidebar",
	"rightHorizontalSidebar",
	"leftSidebarCount",
	"openWidgetsOrderPerHorizontalSidebar",
	"openWidgetsOrderPerSidebar"
}
local applyScheduled = false
local placementByWidgetId = {}
local fullOrderRestoreEvent
local delayedRestoreEvents = {}
local WIDGET_TYPE_TO_ID = {
	dropTracker = "dropTrackerMiniWindow",
	analyticsSelector = "analyserMiniWindow",
	bossCooldown = "bossCdAnalyserMiniWindow",
	helperStats = "helperStatsWindow",
	minimap = "mainmappanel",
	spellList = "spellListMiniWindow",
	unjustifiedPoints = "unjustifiedPointsWindow",
	questTracker = "QuestLogTracker",
	imbuementTracker = "imbuementTracker",
	bosstiaryTracker = "BosstiaryTrackerWindow",
	prey = "preyTracker",
	bestiaryTracker = "BestiaryTrackerWindow",
	battleList = "battleWindow",
	xpAnalyser = "xpAnalyserMiniWindow",
	partyList = "partyWindow",
	partyHuntAnalyser = "phAnalyserMiniWindow",
	vip = "vipWindow",
	huntingSessionAnalyser = "huntingAnalyserMiniWindow",
	skills = "skillWindow",
	damageInputAnalyser = "inputAnalyserMiniWindow",
	impactAnalyser = "impactAnalyserMiniWindow",
	supplyAnalyser = "supplyAnalyserMiniWindow",
	lootAnalyser = "lootAnalyserMiniWindow"
}
local WIDGET_TYPE_TO_MODULE = {
	dropTracker = "game_analysers",
	analyticsSelector = "game_analysers",
	bossCooldown = "game_analysers",
	helperStats = "game_helper",
	minimap = "game_minimap",
	spellList = "game_spelllist",
	unjustifiedPoints = "game_unjustifiedpoints",
	questTracker = "game_questlog",
	imbuementTracker = "game_imbuementtracker",
	bosstiaryTracker = "game_cyclopedia",
	prey = "game_prey",
	bestiaryTracker = "game_cyclopedia",
	battleList = "game_battle",
	xpAnalyser = "game_analysers",
	partyList = "game_party",
	partyHuntAnalyser = "game_analysers",
	vip = "game_viplist",
	huntingSessionAnalyser = "game_analysers",
	skills = "game_skills",
	damageInputAnalyser = "game_analysers",
	impactAnalyser = "game_analysers",
	supplyAnalyser = "game_analysers",
	lootAnalyser = "game_analysers"
}

local function resolveWidgetId(widgetType, instance)
	if widgetType == "container" then
		return "container" .. tostring(instance or 0)
	end

	if widgetType == "battleList" then
		instance = tonumber(instance) or 0

		if instance == 0 then
			return "battleWindow"
		end

		return "battleWindow_" .. instance
	end

	local localId = WIDGET_TYPE_TO_ID[widgetType]

	if localId then
		return localId
	end

	if CipImportMappings and CipImportMappings.resolveSidebarWidgetId then
		return CipImportMappings.resolveSidebarWidgetId(widgetType, instance)
	end

	return nil
end

local function getRightExtraCountFromSection(section)
	local order = section.openWidgetsOrderPerSidebar

	if type(order) ~= "table" then
		return 0
	end

	local leftSidebarCount = tonumber(section.leftSidebarCount) or 0

	return math.max(0, #order - 1 - leftSidebarCount)
end

local function getParentIdForVerticalSlot(slotIndex, section)
	local leftSidebarCount = tonumber(section.leftSidebarCount) or 0
	local rightExtraCount = getRightExtraCountFromSection(section)

	if slotIndex == 1 then
		return "gameRightPanel"
	end

	if slotIndex <= 1 + rightExtraCount then
		local extraIndex = slotIndex - 1

		if extraIndex == 1 then
			return "gameRightExtraPanel"
		end

		return "gameRightExtraPanel_" .. extraIndex
	end

	local leftSlotIndex = slotIndex - 1 - rightExtraCount

	if leftSlotIndex == 1 then
		return "gameLeftPanel"
	end

	local leftExtraIndex = leftSlotIndex - 1

	if leftExtraIndex == 1 then
		return "gameLeftExtraPanel"
	end

	return "gameLeftExtraPanel_" .. leftExtraIndex
end

function SidebarWidgetsPersistence.noteWidgetPlacement(widget)
	if SidebarLayoutState and SidebarLayoutState.noteWidgetPlacement then
		SidebarLayoutState.noteWidgetPlacement(widget)
	end
end

function SidebarWidgetsPersistence.clearRuntimeState()
	placementByWidgetId = {}

	if SidebarLayoutState and SidebarLayoutState.clear then
		SidebarLayoutState.clear()
	end
end

function SidebarWidgetsPersistence.getRuntimeWidgets()
	if SidebarLayoutState and SidebarLayoutState.getWidgets then
		return SidebarLayoutState.getWidgets()
	end

	return {}
end

function SidebarWidgetsPersistence.getWidgetPlacement(widgetId)
	return placementByWidgetId[widgetId]
end

local function ensureWidgetModuleLoaded(widgetType)
	local moduleName = WIDGET_TYPE_TO_MODULE[widgetType]

	if not moduleName or not g_modules or not g_modules.ensureModuleLoaded then
		return
	end

	g_modules.ensureModuleLoaded(moduleName)
end

local function findWidgetById(widgetId, widgetType)
	local rootWidget = g_ui.getRootWidget()
	local widget = rootWidget and rootWidget:recursiveGetChildById(widgetId)

	if widget and not widget:isDestroyed() then
		return widget
	end

	local registryWidget = g_ui.loadedWidgetsById and g_ui.loadedWidgetsById[widgetId]

	if registryWidget and not registryWidget:isDestroyed() then
		return registryWidget
	end

	local moduleName = WIDGET_TYPE_TO_MODULE[widgetType]

	if moduleName then
		local module = modules[moduleName]

		if module and module[widgetId] and not module[widgetId]:isDestroyed() then
			return module[widgetId]
		end
	end

	return nil
end

local function addWidgetsToPlacementMap(widgetList, parentId)
	if type(widgetList) ~= "table" or not parentId then
		return
	end

	for index, entry in ipairs(widgetList) do
		if type(entry) == "table" and type(entry.type) == "string" then
			ensureWidgetModuleLoaded(entry.type)

			local widgetId = resolveWidgetId(entry.type, entry.instance)

			if widgetId and not placementByWidgetId[widgetId] then
				placementByWidgetId[widgetId] = {
					parentId = parentId,
					index = index,
					type = entry.type
				}
			end
		end
	end
end

function SidebarWidgetsPersistence.buildPlacementMap(section)
	placementByWidgetId = {}

	if type(section) ~= "table" then
		return
	end

	if type(section.openWidgetsOrderPerSidebar) == "table" then
		for slotIndex, widgetList in ipairs(section.openWidgetsOrderPerSidebar) do
			addWidgetsToPlacementMap(widgetList, getParentIdForVerticalSlot(slotIndex, section))
		end
	end

	if type(section.openWidgetsOrderPerHorizontalSidebar) == "table" then
		local slotIndex = 0

		if section.rightHorizontalSidebar == true then
			slotIndex = slotIndex + 1

			addWidgetsToPlacementMap(section.openWidgetsOrderPerHorizontalSidebar[slotIndex], HORIZONTAL_PARENT_IDS[1])
		end

		if section.leftHorizontalSidebar == true then
			slotIndex = slotIndex + 1

			addWidgetsToPlacementMap(section.openWidgetsOrderPerHorizontalSidebar[slotIndex], HORIZONTAL_PARENT_IDS[2])
		end
	end

	SidebarWidgetsPersistence.seedRegistryFromPlacement()
end

function SidebarWidgetsPersistence.seedRegistryFromPlacement()
	if not SidebarLayoutState then
		return
	end

	for widgetId, placement in pairs(placementByWidgetId) do
		local widgetType, instance = SidebarLayoutState.resolveTypeFromWidgetId(widgetId)

		if widgetType then
			SidebarLayoutState.widgets[widgetId] = {
				type = widgetType,
				instance = instance or 0,
				parentId = SidebarLayoutState.canonicalParentId(placement.parentId),
				index = placement.index
			}
		end
	end
end

local function ensureSidebarForParentId(parentId)
	if not parentId or not modules.client_options then
		return
	end

	local optionKey

	if parentId == "gameLeftPanel" then
		optionKey = "showLeftPanel"
	elseif parentId == "gameLeftTopPanel" then
		optionKey = "showLeftHorizontalPanel"
	elseif parentId == "gameRightTopPanel" then
		optionKey = "showRightHorizontalPanel"
	elseif parentId:find("^gameLeftExtraPanel") then
		optionKey = "showLeftExtraPanel"
	elseif parentId:find("^gameRightExtraPanel") then
		optionKey = "showRightExtraPanel"
	end

	if optionKey and not modules.client_options.getOption(optionKey) then
		modules.client_options.setOption(optionKey, true, true)

		if modules.game_interface.updateSidebarControlStates then
			modules.game_interface.updateSidebarControlStates()
		end

		if (parentId == "gameLeftTopPanel" or parentId == "gameRightTopPanel") and modules.game_interface.updateHorizontalPanelWidths then
			modules.game_interface.updateHorizontalPanelWidths()
		end
	end
end

local function resolveParentPanel(parentId)
	if not parentId or not modules.game_interface then
		return nil
	end

	if parentId == "gameRightPanel" and modules.game_interface.getRightPanel then
		return modules.game_interface.getRightPanel()
	end

	if parentId == "gameLeftPanel" and modules.game_interface.getLeftPanel then
		return modules.game_interface.getLeftPanel()
	end

	if parentId == "gameRightTopPanel" and modules.game_interface.getRightTopPanel then
		return modules.game_interface.getRightTopPanel()
	end

	if parentId == "gameLeftTopPanel" and modules.game_interface.getLeftTopPanel then
		return modules.game_interface.getLeftTopPanel()
	end

	if parentId == "gameRightExtraPanel" or parentId:find("^gameRightExtraPanel") then
		local extraIndex = 1
		local numbered = parentId:match("^gameRightExtraPanel_(%d+)$")

		if numbered then
			extraIndex = tonumber(numbered)
		end

		if modules.game_interface.getRightExtraPanelByIndex then
			return modules.game_interface.getRightExtraPanelByIndex(extraIndex)
		end

		return modules.game_interface.getRightExtraPanel and modules.game_interface.getRightExtraPanel()
	end

	if parentId == "gameLeftExtraPanel" or parentId:find("^gameLeftExtraPanel") then
		local extraIndex = 1
		local numbered = parentId:match("^gameLeftExtraPanel_(%d+)$")

		if numbered then
			extraIndex = tonumber(numbered)
		end

		if modules.game_interface.getLeftExtraPanelByIndex then
			return modules.game_interface.getLeftExtraPanelByIndex(extraIndex)
		end

		return modules.game_interface.getLeftExtraPanel and modules.game_interface.getLeftExtraPanel()
	end

	local rootWidget = g_ui.getRootWidget()

	if not rootWidget then
		return nil
	end

	return rootWidget:recursiveGetChildById(parentId)
end

local function placeWidgetInSidebar(widget, parentId, index)
	if not widget or widget:isDestroyed() then
		return false
	end

	ensureSidebarForParentId(parentId)

	local parent = resolveParentPanel(parentId)

	if not parent or parent:isDestroyed() then
		return false
	end

	local isSidePanel = modules.game_interface and modules.game_interface.isGameSidePanelId and modules.game_interface.isGameSidePanelId(parent:getId())
	local isHorizontalPanel = parentId == "gameLeftTopPanel" or parentId == "gameRightTopPanel"
	local panelReady = parent:isVisible() or isSidePanel and parent:isOn() or isHorizontalPanel and parent:isOn()

	if not panelReady then
		return false
	end

	local currentParent = widget:getParent()

	if currentParent and not currentParent:isDestroyed() and currentParent ~= parent then
		currentParent:removeChild(widget)
	end

	widget.miniLoaded = false
	widget.miniIndex = nil

	if parent:getClassName() == "UIMiniWindowContainer" and index and type(parent.scheduleInsert) == "function" then
		widget.miniIndex = index

		parent:scheduleInsert(widget, index)
	elseif widget:getParent() ~= parent then
		parent:addChild(widget)
	end

	if parent:getClassName() == "UIMiniWindowContainer" then
		addEvent(function()
			if parent and not parent:isDestroyed() then
				parent:order()
			end
		end)
	end

	SidebarWidgetsPersistence.noteWidgetPlacement(widget)

	return true
end

function SidebarWidgetsPersistence.collectWidgetsManagerOptions()
	local options = {}

	if SidebarLayoutState and SidebarLayoutState.syncFromPanels then
		SidebarLayoutState.syncFromPanels()
	end

	if SidebarLayoutState and SidebarLayoutState.pruneUntrackedWidgets then
		SidebarLayoutState.pruneUntrackedWidgets()
	end

	if modules.client_options and modules.client_options.getOption then
		options.leftHorizontalSidebar = modules.client_options.getOption("showLeftHorizontalPanel") == true
		options.rightHorizontalSidebar = modules.client_options.getOption("showRightHorizontalPanel") == true
	end

	if modules.game_interface and modules.game_interface.countVisibleLeftSidebarSlots then
		options.leftSidebarCount = modules.game_interface.countVisibleLeftSidebarSlots()
	else
		options.leftSidebarCount = 0
	end

	if SidebarLayoutState and SidebarLayoutState.collectVerticalWidgetOrder then
		options.openWidgetsOrderPerSidebar = SidebarLayoutState.collectVerticalWidgetOrder()
	else
		options.openWidgetsOrderPerSidebar = {}
	end

	if SidebarLayoutState and SidebarLayoutState.collectHorizontalWidgetOrder then
		options.openWidgetsOrderPerHorizontalSidebar = SidebarLayoutState.collectHorizontalWidgetOrder()
	else
		options.openWidgetsOrderPerHorizontalSidebar = {}
	end

	return options
end

function SidebarWidgetsPersistence.applySidebarLayout(section)
	if type(section) ~= "table" then
		return
	end

	if section.leftHorizontalSidebar ~= nil and modules.client_options then
		modules.client_options.setOption("showLeftHorizontalPanel", section.leftHorizontalSidebar == true, true)
	end

	if section.rightHorizontalSidebar ~= nil and modules.client_options then
		modules.client_options.setOption("showRightHorizontalPanel", section.rightHorizontalSidebar == true, true)
	end

	local leftSidebarCount = tonumber(section.leftSidebarCount) or 0
	local leftExtraCount = math.max(0, leftSidebarCount - 1)
	local rightExtraCount = getRightExtraCountFromSection(section)

	if modules.client_options then
		modules.client_options.setOption("showLeftPanel", leftSidebarCount > 0, true)
	end

	if modules.game_interface and modules.game_interface.restoreSidebarColumnCounts then
		modules.game_interface.restoreSidebarColumnCounts(leftExtraCount, rightExtraCount)
	end
end

function SidebarWidgetsPersistence.applyWidgetPlacements()
	if table.empty(placementByWidgetId) then
		return true
	end

	local rootWidget = g_ui.getRootWidget()

	if not rootWidget then
		return false
	end

	local stillPending = false

	for widgetId, placement in pairs(placementByWidgetId) do
		local widget = findWidgetById(widgetId, placement.type)

		if widget and not widget:isDestroyed() then
			local currentParent = widget:getParent()
			local currentParentId = currentParent and currentParent:getId()
			local sameParent = SidebarLayoutState and SidebarLayoutState.canonicalParentId(currentParentId) == SidebarLayoutState.canonicalParentId(placement.parentId)

			if sameParent and currentParent and not currentParent:isDestroyed() then
				if currentParent:getClassName() == "UIMiniWindowContainer" and placement.index and type(currentParent.scheduleInsert) == "function" and widget.miniIndex ~= placement.index then
					widget.miniIndex = placement.index

					currentParent:scheduleInsert(widget, placement.index)
				end

				if SidebarLayoutState and SidebarLayoutState.noteWidgetPlacement then
					SidebarLayoutState.noteWidgetPlacement(widget)
				end
			elseif not placeWidgetInSidebar(widget, placement.parentId, placement.index) then
				stillPending = true
			end
		else
			local widgetType = SidebarLayoutState and SidebarLayoutState.resolveTypeFromWidgetId(widgetId)

			if widgetType ~= "container" then
				stillPending = true
			end
		end
	end

	if not stillPending and modules.game_interface and modules.game_interface.getMiniWindowSidebarPanelsInOrder then
		for _, panel in ipairs(modules.game_interface.getMiniWindowSidebarPanelsInOrder()) do
			if panel and not panel:isDestroyed() and panel.order then
				panel:order()
			end
		end
	end

	if not stillPending and modules.game_containers and modules.game_containers.scheduleContainersLayoutRestore then
		modules.game_containers.scheduleContainersLayoutRestore()
	end

	return not stillPending
end

function SidebarWidgetsPersistence.enforceLayoutClosedState()
	if not SidebarPersistence or not SidebarPersistence.active then
		return
	end

	local allowedIds = {}

	for widgetId in pairs(placementByWidgetId) do
		allowedIds[widgetId] = true
	end

	if not modules.game_interface or not modules.game_interface.getMiniWindowSidebarPanelsInOrder then
		return
	end

	for _, panel in ipairs(modules.game_interface.getMiniWindowSidebarPanelsInOrder()) do
		if panel and not panel:isDestroyed() then
			for _, child in ipairs(panel:getChildren()) do
				if child.save and child.getId and not child:isDestroyed() then
					local widgetId = child:getId()
					local widgetType = SidebarLayoutState.resolveTypeFromWidgetId(widgetId)

					if widgetType and not allowedIds[widgetId] and child.close then
						child:close(true)
					end
				end
			end
		end
	end
end

local function applyFullOrderToPanel(parentId, widgetList)
	if not parentId or type(widgetList) ~= "table" or #widgetList == 0 then
		return
	end

	local rootWidget = g_ui.getRootWidget()

	if not rootWidget then
		return
	end

	local parent = resolveParentPanel(parentId)

	if not parent or parent:isDestroyed() then
		return
	end

	if parent:getClassName() ~= "UIMiniWindowContainer" then
		return
	end

	local orderedWidgets = {}

	for _, entry in ipairs(widgetList) do
		local widgetId = resolveWidgetId(entry.type, entry.instance)

		if widgetId then
			local widget = rootWidget:recursiveGetChildById(widgetId)

			if widget and not widget:isDestroyed() and widget:getParent() == parent then
				orderedWidgets[#orderedWidgets + 1] = widget
			end
		end
	end

	if #orderedWidgets == 0 then
		return
	end

	for saveIdx, targetWidget in ipairs(orderedWidgets) do
		local children = parent:getChildren()
		local saveCount = 0
		local slotRawIdx

		for i = 1, #children do
			if children[i] and children[i].save then
				saveCount = saveCount + 1

				if saveCount == saveIdx then
					slotRawIdx = i

					break
				end
			end
		end

		local targetRawIdx = slotRawIdx or parent:getChildCount()
		local currentRawIdx = parent:getChildIndex(targetWidget)

		if currentRawIdx ~= targetRawIdx then
			pcall(function()
				parent:moveChildToIndex(targetWidget, targetRawIdx)
			end)
		end
	end
end

local function applyAllPanelsOrder(section)
	if type(section) ~= "table" then
		return
	end

	if type(section.openWidgetsOrderPerSidebar) == "table" then
		for slotIndex, widgetList in ipairs(section.openWidgetsOrderPerSidebar) do
			if type(widgetList) == "table" and #widgetList > 0 then
				local parentId = getParentIdForVerticalSlot(slotIndex, section)

				if parentId then
					applyFullOrderToPanel(parentId, widgetList)
				end
			end
		end
	end

	if type(section.openWidgetsOrderPerHorizontalSidebar) == "table" then
		local slotIndex = 0

		if section.rightHorizontalSidebar == true then
			slotIndex = slotIndex + 1

			local widgetList = section.openWidgetsOrderPerHorizontalSidebar[slotIndex]

			if type(widgetList) == "table" and #widgetList > 0 then
				applyFullOrderToPanel(HORIZONTAL_PARENT_IDS[1], widgetList)
			end
		end

		if section.leftHorizontalSidebar == true then
			slotIndex = slotIndex + 1

			local widgetList = section.openWidgetsOrderPerHorizontalSidebar[slotIndex]

			if type(widgetList) == "table" and #widgetList > 0 then
				applyFullOrderToPanel(HORIZONTAL_PARENT_IDS[2], widgetList)
			end
		end
	end
end

local function applySavedOrderToPanel(section)
	applyAllPanelsOrder(section)
end

function SidebarWidgetsPersistence.scheduleFullOrderRestore()
	if not SidebarPersistence or not SidebarPersistence.active then
		return
	end

	if fullOrderRestoreEvent then
		removeEvent(fullOrderRestoreEvent)

		fullOrderRestoreEvent = nil
	end

	fullOrderRestoreEvent = scheduleEvent(function()
		fullOrderRestoreEvent = nil

		local section = SidebarPersistence.getSection(SECTION_WIDGETS_MANAGER)

		applyAllPanelsOrder(section)
	end, 150)
end

function SidebarWidgetsPersistence.applyAll()
	if not SidebarPersistence or not SidebarPersistence.active then
		return true
	end

	local section = SidebarPersistence.getSection(SECTION_WIDGETS_MANAGER)

	if type(section) ~= "table" then
		placementByWidgetId = {}

		return true
	end

	SidebarWidgetsPersistence.applySidebarLayout(section)
	SidebarWidgetsPersistence.buildPlacementMap(section)

	return SidebarWidgetsPersistence.applyWidgetPlacements()
end

local layoutRestoreAttempts = 0
local LAYOUT_RESTORE_MAX_ATTEMPTS = 30

function SidebarWidgetsPersistence.scheduleApply()
	if applyScheduled then
		return
	end

	applyScheduled = true

	local function attempt()
		applyScheduled = false
		layoutRestoreAttempts = layoutRestoreAttempts + 1

		local complete

		if layoutRestoreAttempts == 1 then
			complete = SidebarWidgetsPersistence.applyAll()
		else
			complete = SidebarWidgetsPersistence.applyWidgetPlacements()
		end

		if not complete and layoutRestoreAttempts < LAYOUT_RESTORE_MAX_ATTEMPTS then
			applyScheduled = true

			scheduleEvent(function()
				attempt()
			end, 50)
		else
			if complete then
				layoutRestoreAttempts = 0
			end

			SidebarWidgetsPersistence.enforceLayoutClosedState()

			if SidebarWidgetOptionsPersistence and SidebarWidgetOptionsPersistence.scheduleApply then
				SidebarWidgetOptionsPersistence.scheduleApply()
			end
		end
	end

	addEvent(attempt)
end

local function assignOrderedSection(section, data)
	for i = 1, #SECTION_FIELD_ORDER do
		local key = SECTION_FIELD_ORDER[i]
		local value = data[key]

		if value ~= nil then
			section[key] = value
		end
	end

	section._jsonKeyOrder = SECTION_FIELD_ORDER
end

function SidebarWidgetsPersistence.register()
	if not SidebarPersistence or not SidebarPersistence.registerProvider then
		return
	end

	SidebarPersistence.registerProvider(SECTION_WIDGETS_MANAGER, {
		collect = function(section)
			local data = SidebarWidgetsPersistence.collectWidgetsManagerOptions()

			if type(data) ~= "table" then
				return
			end

			assignOrderedSection(section, data)
		end
	})
end

connect(g_game, {
	onGameEnd = function()
		if fullOrderRestoreEvent then
			removeEvent(fullOrderRestoreEvent)

			fullOrderRestoreEvent = nil
		end

		for _, event in ipairs(delayedRestoreEvents) do
			removeEvent(event)
		end

		delayedRestoreEvents = {}
	end,
	onGameStart = function()
		layoutRestoreAttempts = 0

		SidebarWidgetsPersistence.clearRuntimeState()

		do
			local panels = {}

			if modules.game_interface then
				if modules.game_interface.getRightPanel then
					panels[#panels + 1] = modules.game_interface.getRightPanel()
				end

				if modules.game_interface.getMiniWindowSidebarPanelsInOrder then
					for _, p in ipairs(modules.game_interface.getMiniWindowSidebarPanelsInOrder()) do
						panels[#panels + 1] = p
					end
				end
			end

			local seen = {}

			for _, panel in ipairs(panels) do
				if panel and not panel:isDestroyed() and not seen[panel] then
					seen[panel] = true

					for _, child in ipairs(panel:getChildren()) do
						if child and child.save then
							child.miniIndex = nil
							child.miniLoaded = nil
						end
					end

					if type(panel.scheduledWidgets) == "table" then
						panel.scheduledWidgets = {}
					end
				end
			end
		end

		local section = SidebarPersistence.getSection(SECTION_WIDGETS_MANAGER)

		if type(section) == "table" then
			SidebarWidgetsPersistence.applySidebarLayout(section)
			SidebarWidgetsPersistence.buildPlacementMap(section)
		end

		local complete = SidebarWidgetsPersistence.applyWidgetPlacements()

		if complete then
			layoutRestoreAttempts = 0

			SidebarWidgetsPersistence.enforceLayoutClosedState()

			local section = SidebarPersistence.getSection(SECTION_WIDGETS_MANAGER)

			applySavedOrderToPanel(section)
			addEvent(function()
				if SidebarWidgetOptionsPersistence then
					SidebarWidgetOptionsPersistence.applyAll()
					SidebarWidgetOptionsPersistence.syncAllButtons()

					if modules.game_containers and modules.game_containers.restoreAllContainerLayoutsNow then
						modules.game_containers.restoreAllContainerLayoutsNow()
					end

					local section = SidebarPersistence.getSection(SECTION_WIDGETS_MANAGER)

					applyAllPanelsOrder(section)
					scheduleEvent(function()
						if SidebarPersistence and SidebarPersistence.active then
							local s = SidebarPersistence.getSection(SECTION_WIDGETS_MANAGER)

							applyAllPanelsOrder(s)
						end
					end, 500)
				end
			end)
		else
			SidebarWidgetsPersistence.scheduleApply()
		end

		-- Several game modules are loaded after game_interface and may open their
		-- default miniwindows after the first restore pass. Reapply the saved
		-- character layout while those late modules finish starting up.
		for _, event in ipairs(delayedRestoreEvents) do
			removeEvent(event)
		end

		delayedRestoreEvents = {}

		for _, delay in ipairs({ 500, 1500, 3000, 5000 }) do
			local event

			event = scheduleEvent(function()
				for index, pendingEvent in ipairs(delayedRestoreEvents) do
					if pendingEvent == event then
						table.remove(delayedRestoreEvents, index)
						break
					end
				end

				if SidebarPersistence and SidebarPersistence.active then
					layoutRestoreAttempts = 0
					SidebarWidgetsPersistence.scheduleApply()
					SidebarWidgetsPersistence.scheduleFullOrderRestore()
				end
			end, delay)

			table.insert(delayedRestoreEvents, event)
		end
	end
})
connect(Container, {
	onOpen = function()
		SidebarWidgetsPersistence.scheduleFullOrderRestore()
	end
})
SidebarWidgetsPersistence.register()
