-- chunkname: @/game_containers/containers.lua
local applySortToOpenContainers -- forward declaration (used before its declaration in the decompiled file)

containerSettings = nil

local containerDragHoveredSlot

local function getGridSpacing(layout)
	local spacing = layout:getCellSpacing()

	if spacing > 0 then
		return spacing, spacing
	end

	local spacingX = layout:getCellSpacingWidth()
	local spacingY = layout:getCellSpacingHeight()

	if spacingX <= 0 then
		spacingX = spacing
	end

	if spacingY <= 0 then
		spacingY = spacing
	end

	return spacingX, spacingY
end

local function getContainerSlotItemWidget(slotWidget)
	if not slotWidget then
		return nil
	end

	if slotWidget.item and slotWidget.item:getClassName() == "UIItem" then
		return slotWidget.item
	end

	if slotWidget:getClassName() == "UIItem" then
		return slotWidget
	end

	return nil
end

local function setContainerSlotAmount(slotWidget, item)
	local amountLabel = slotWidget and slotWidget.amount

	if not amountLabel then
		return
	end

	if not item then
		amountLabel:setText("")
		amountLabel:setVisible(false)

		return
	end

	if item:isFluidContainer() or not item:isStackable() then
		amountLabel:setText("")
		amountLabel:setVisible(false)

		return
	end

	local count = item:getCount() or 0

	if count > 1 then
		amountLabel:setText(tostring(count))
		amountLabel:setVisible(true)
	else
		amountLabel:setText("")
		amountLabel:setVisible(false)
	end
end

local function refreshContainerSlotQuickLootIcon(slotWidget, item)
	local icon = slotWidget.quickloot or slotWidget:getChildById("quickloot")

	if not icon then
		return
	end

	local show = false

	if item and item:isContainer() then
		show = item:getQuickLootFlags() ~= 0 or item:getObtainLootFlags() ~= 0
	end

	icon:setVisible(show)

	if show then
		local iconTooltip = ""

		if modules.game_quickloot and modules.game_quickloot.QuickLoot and modules.game_quickloot.QuickLoot.getQuickLootIconTooltip then
			iconTooltip = modules.game_quickloot.QuickLoot.getQuickLootIconTooltip(item:getQuickLootFlags(), item:getObtainLootFlags())
		end

		icon:setTooltip(iconTooltip)
	else
		icon:setTooltip("")
	end
end

local function refreshContainerSlotBoxedIcon(slotWidget, item)
	local icon = slotWidget.boxed or slotWidget:getChildById("boxed")

	if not icon then
		return
	end

	local show = item ~= nil and item:isDecoKit()

	icon:setVisible(show)
end

function applyContainerSlotVisuals(slotWidget, item)
	if not slotWidget then
		return
	end

	local itemUi = getContainerSlotItemWidget(slotWidget)

	if itemUi then
		itemUi:setUseDecoKitContainerSprite(item ~= nil and item:isDecoKit())
		itemUi:setItem(item)
	end

	if slotWidget.rarity then
		if item then
			ItemsDatabase.setRarityItem(slotWidget.rarity, item)
			ItemsDatabase.syncRarityWidgetVisibility(slotWidget.rarity)
		else
			ItemsDatabase.setRarityItem(slotWidget.rarity, nil)
			slotWidget.rarity:setVisible(false)
		end

		ItemsDatabase.applyContainerRarityStackOrder(slotWidget)
	end

	ItemsDatabase.setTier(slotWidget, item or 0)
	setContainerSlotAmount(slotWidget, item)
	refreshContainerSlotQuickLootIcon(slotWidget, item)
	refreshContainerSlotBoxedIcon(slotWidget, item)

	if modules.client_options.getOption("showExpiryInContainers") then
		ItemsDatabase.setCharges(slotWidget, item)
		ItemsDatabase.setDuration(slotWidget, item)
	else
		if slotWidget.charges then
			slotWidget.charges:setText("")
		end

		if slotWidget.duration then
			slotWidget.duration:setText("")
		end
	end
end

local function bindContainerSlotPosition(slotWidget, position)
	if not slotWidget or not position then
		return
	end

	local itemUi = getContainerSlotItemWidget(slotWidget)

	if itemUi then
		itemUi.position = position
	end
end

local CONTAINER_TITLE_COLOR_DEFAULT = "#9d9d9dff"
local CONTAINER_TITLE_COLOR_MANUAL_SORT = "#c28400"

local function applyContainerTitleStyle(containerWindow)
	if not containerWindow or containerWindow:isDestroyed() then
		return
	end

	local titleWidget = containerWindow:getChildById("miniwindowTitle")

	if not titleWidget then
		return
	end

	local isManualSortEnabled = containerSettings and containerSettings.useManualSortMode == 1

	if isManualSortEnabled then
		titleWidget:setColor(CONTAINER_TITLE_COLOR_MANUAL_SORT)
	else
		titleWidget:setColor(CONTAINER_TITLE_COLOR_DEFAULT)
	end
end

local function refreshAllContainerTitleStyles()
	for _, container in pairs(g_game.getContainers()) do
		if container.window and not container.window:isDestroyed() then
			applyContainerTitleStyle(container.window)
		end
	end
end

local SORT_MODE_TO_INDEX = {
	sortDescByStackSize = 7,
	sortAscByStackSize = 6,
	sortDescByExpiry = 5,
	sortAscByExpiry = 4,
	sortDescByWeight = 3,
	sortAscByWeight = 2,
	sortDescByName = 1,
	sortAscByName = 0
}
local shouldApplyContainerSort

local function getContainerFromWidget(widget)
	while widget do
		local id = widget.getId and widget:getId() or nil

		if id then
			local containerId = tonumber(id:match("^container(%d+)$"))

			if containerId then
				return g_game.getContainer(containerId)
			end
		end

		widget = widget:getParent()
	end

	return nil
end

local function getContainerOrganizeFlags()
	local containersFirst = containerSettings and containerSettings.sortContainersFirst == 1
	local nestedContainers = containerSettings and containerSettings.sortNestedContainers == 1

	return containersFirst, nestedContainers
end

local function requestContainerSort(container, sortMode, onlyThisContainer)
	if not container or not sortMode or sortMode == "none" then
		return
	end

	if not shouldApplyContainerSort(container) then
		return
	end

	local index = SORT_MODE_TO_INDEX[sortMode]

	if index == nil then
		return
	end

	local containersFirst, nestedContainers = getContainerOrganizeFlags()

	if onlyThisContainer then
		nestedContainers = false
	end

	g_game.organizeContainer(container, false, index, containersFirst, nestedContainers, false)
end

local function requestMoveToObtainContainers(container)
	if not container then
		return
	end

	local moveNested = containerSettings and containerSettings.moveNestedContainers == 1
	local index = moveNested and 1 or 0
	local containersFirst, nestedContainers = getContainerOrganizeFlags()

	g_game.organizeContainer(container, true, index, containersFirst, nestedContainers, false)
end

local function getLowestOpenContainer()
	local lowestContainer, lowestId

	for id, container in pairs(g_game.getContainers()) do
		if shouldApplyContainerSort(container) and container.window and container.window:isVisible() and (lowestId == nil or id < lowestId) then
			lowestId = id
			lowestContainer = container
		end
	end

	return lowestContainer
end

local function requestNestedContainersSort(sortMode)
	local rootContainer = getLowestOpenContainer()

	if not rootContainer then
		return
	end

	local index = SORT_MODE_TO_INDEX[sortMode]

	if index == nil then
		return
	end

	local containersFirst = containerSettings and containerSettings.sortContainersFirst == 1

	g_game.organizeContainer(rootContainer, false, index, containersFirst, true, false)
end

local function shouldAskBeforeNestedAction(optionKey)
	if modules.client_options and modules.client_options.getOption then
		local value = modules.client_options.getOption(optionKey)

		if value ~= nil then
			return value
		end
	end

	return true
end

local function closeNestedConfirmWindow(confirmWindow)
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

local function displayNestedContainersConfirmBox(title, content, optionKey, onConfirm)
	local confirmWindow = g_ui.createWidget("SortNestedContainersConfirmModal", rootWidget)

	confirmWindow:getChildById("title"):setText(title)
	confirmWindow:getChildById("content"):setText(content)

	local doNotShowAgain = confirmWindow:recursiveGetChildById("doNotShowAgain")

	local function cancelFunc()
		closeNestedConfirmWindow(confirmWindow)
	end

	local function confirmFunc()
		if doNotShowAgain and doNotShowAgain:isChecked() and modules.client_options and modules.client_options.setOption then
			modules.client_options.setOption(optionKey, false, true)
		end

		closeNestedConfirmWindow(confirmWindow)
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

local function handleContainerSortAction(container, sortMode)
	containerSettings.currentSortMode = sortMode

	g_settings.setNode("containers", containerSettings)

	local _, nestedContainersEnabled = getContainerOrganizeFlags()

	if nestedContainersEnabled then
		local function doSort()
			requestNestedContainersSort(sortMode)
		end

		if shouldAskBeforeNestedAction("askBeforeSorting") then
			displayNestedContainersConfirmBox(tr("Confirmation to Sort Nested Containers"), tr("You are about to sort the contents of all containers and their nested subcontainers. Do you want to proceed?"), "askBeforeSorting", doSort)
		else
			doSort()
		end
	elseif container then
		requestContainerSort(container, sortMode, true)
	else
		applySortToOpenContainers(sortMode, true)
	end
end

applySortToOpenContainers = function(sortMode, skipConfirm)
	if not sortMode or sortMode == "none" then
		return
	end

	local _, nestedContainers = getContainerOrganizeFlags()

	if nestedContainers then
		if skipConfirm then
			requestNestedContainersSort(sortMode)
		else
			handleContainerSortAction(nil, sortMode)
		end

		return
	end

	for _, container in pairs(g_game.getContainers()) do
		if shouldApplyContainerSort(container) and container.window and container.window:isVisible() then
			requestContainerSort(container, sortMode, true)
		end
	end
end

local function applyMoveToObtainToOpenContainers()
	local _, nestedContainers = getContainerOrganizeFlags()
	local containers = g_game.getContainers()

	if nestedContainers then
		local lowestContainer, lowestId

		for id, container in pairs(containers) do
			if container.window and container.window:isVisible() and (lowestId == nil or id < lowestId) then
				lowestId = id
				lowestContainer = container
			end
		end

		if lowestContainer then
			requestMoveToObtainContainers(lowestContainer)
		end
	else
		for _, container in pairs(containers) do
			if container.window and container.window:isVisible() then
				requestMoveToObtainContainers(container)
			end
		end
	end
end

local function getContainerSeekFilter(container)
	if container and container.getSelectedFilter then
		return container:getSelectedFilter()
	end

	return 0
end

local STORE_INBOX_FILTER_ALL = 0
local STORE_INBOX_FILTER_CONSUMABLES = 1
local STORE_INBOX_FILTER_FLOOR_COVERING = 3
local STORE_INBOX_FILTER_WIDGET_IDS = {
	"filterAll",
	"filterConsumables",
	"filterFloorCovering"
}
local STORE_INBOX_CONSUMABLE_CATEGORIES = {
	[6] = true,
	[10] = true,
	[12] = true,
	[22] = true
}

if MarketCategory then
	STORE_INBOX_CONSUMABLE_CATEGORIES[MarketCategory.Food] = true
	STORE_INBOX_CONSUMABLE_CATEGORIES[MarketCategory.Potions] = true
	STORE_INBOX_CONSUMABLE_CATEGORIES[MarketCategory.Runes] = true
	STORE_INBOX_CONSUMABLE_CATEGORIES[MarketCategory.PremiumScrolls] = true
end

local STORE_INBOX_FLOOR_COVERING_CATEGORIES = {
	[5] = true
}

if MarketCategory then
	STORE_INBOX_FLOOR_COVERING_CATEGORIES[MarketCategory.Decoration] = true
end

local function isStoreInboxContainer(container)
	if not container then
		return false
	end

	if container.hasFilters and container:hasFilters() then
		return true
	end

	local name = container:getName():lower()

	return name:find("store inbox", 1, true) ~= nil
end

local function isConsumableStoreInboxItem(item)
	if not item or not g_things or not g_things.getThingType then
		return false
	end

	local thingType = g_things.getThingType(item:getId(), ThingCategoryItem)

	if not thingType or not thingType.getMarketData then
		return false
	end

	local marketData = thingType:getMarketData()

	return marketData and marketData.category and STORE_INBOX_CONSUMABLE_CATEGORIES[marketData.category] == true
end

local function isFloorCoveringStoreInboxItem(item)
	if not item or not g_things or not g_things.getThingType then
		return false
	end

	local thingType = g_things.getThingType(item:getId(), ThingCategoryItem)

	if not thingType or not thingType.getMarketData then
		return false
	end

	local marketData = thingType:getMarketData()

	return marketData and marketData.category and STORE_INBOX_FLOOR_COVERING_CATEGORIES[marketData.category] == true
end

local function containerHasItemsMatching(container, itemMatcher)
	if not container or not itemMatcher then
		return false
	end

	if container.getItems then
		for _, item in pairs(container:getItems()) do
			if itemMatcher(item) then
				return true
			end
		end
	end

	for slot = 0, container:getCapacity() - 1 do
		if itemMatcher(container:getItem(slot)) then
			return true
		end
	end

	return false
end

local function containerHasConsumableItems(container)
	return containerHasItemsMatching(container, isConsumableStoreInboxItem)
end

local function containerHasFloorCoveringItems(container)
	return containerHasItemsMatching(container, isFloorCoveringStoreInboxItem)
end

local function hasStoreInboxFilterById(container, filterId, namePattern)
	if not container or not container.getFiltersCount then
		return false
	end

	for i = 0, container:getFiltersCount() - 1 do
		if container:getFilterId(i) == filterId then
			return true
		end

		if namePattern then
			local name = container:getFilterName(i):lower()

			if name:find(namePattern, 1, true) then
				return true
			end
		end
	end

	return false
end

local function hasStoreInboxConsumablesFilter(container)
	return hasStoreInboxFilterById(container, STORE_INBOX_FILTER_CONSUMABLES, "consumable")
end

local function hasStoreInboxFloorCoveringFilter(container)
	return hasStoreInboxFilterById(container, STORE_INBOX_FILTER_FLOOR_COVERING, "floor")
end

local function getStoreInboxFilterState(container)
	local hasConsumables = containerHasConsumableItems(container)
	local hasFloorCovering = containerHasFloorCoveringItems(container)

	if container and container:hasPages() then
		hasConsumables = hasConsumables or hasStoreInboxConsumablesFilter(container)
		hasFloorCovering = hasFloorCovering or hasStoreInboxFloorCoveringFilter(container)
	end

	return {
		hasConsumables = hasConsumables,
		hasFloorCovering = hasFloorCovering
	}
end

local function isStoreInboxFilterOptionVisible(filterKey, filterState)
	if filterKey == "filterAll" then
		return true
	end

	if filterKey == "filterConsumables" then
		return filterState.hasConsumables
	end

	if filterKey == "filterFloorCovering" then
		return filterState.hasFloorCovering
	end

	return false
end

local function resolveStoreInboxFilterId(container, filterKey)
	if not container then
		return STORE_INBOX_FILTER_ALL
	end

	local targetId = STORE_INBOX_FILTER_ALL

	if filterKey == "filterConsumables" then
		targetId = STORE_INBOX_FILTER_CONSUMABLES
	elseif filterKey == "filterFloorCovering" then
		targetId = STORE_INBOX_FILTER_FLOOR_COVERING
	end

	for i = 0, container:getFiltersCount() - 1 do
		if container:getFilterId(i) == targetId then
			return targetId
		end
	end

	if filterKey == "filterAll" then
		for i = 0, container:getFiltersCount() - 1 do
			local name = container:getFilterName(i):lower()

			if name == "all" then
				return container:getFilterId(i)
			end
		end

		return STORE_INBOX_FILTER_ALL
	end

	if filterKey == "filterConsumables" then
		for i = 0, container:getFiltersCount() - 1 do
			local name = container:getFilterName(i):lower()

			if name:find("consumable", 1, true) then
				return container:getFilterId(i)
			end
		end

		return STORE_INBOX_FILTER_CONSUMABLES
	end

	if filterKey == "filterFloorCovering" then
		for i = 0, container:getFiltersCount() - 1 do
			local name = container:getFilterName(i):lower()

			if name:find("floor", 1, true) then
				return container:getFilterId(i)
			end
		end

		return STORE_INBOX_FILTER_FLOOR_COVERING
	end

	return STORE_INBOX_FILTER_ALL
end

local function getStoreInboxActiveFilterKey(container, selectedFilter)
	if selectedFilter == resolveStoreInboxFilterId(container, "filterConsumables") then
		return "filterConsumables"
	end

	if selectedFilter == resolveStoreInboxFilterId(container, "filterFloorCovering") then
		return "filterFloorCovering"
	end

	return "filterAll"
end

local function normalizeStoreInboxActiveFilterKey(container, selectedFilter, filterState)
	local activeKey = getStoreInboxActiveFilterKey(container, selectedFilter)

	if activeKey == "filterConsumables" and not filterState.hasConsumables then
		return "filterAll"
	end

	if activeKey == "filterFloorCovering" and not filterState.hasFloorCovering then
		return "filterAll"
	end

	return activeKey
end

local function shouldShowStoreInboxFilterButton(container)
	if not isStoreInboxContainer(container) then
		return false
	end

	local filterState = getStoreInboxFilterState(container)

	return filterState.hasConsumables or filterState.hasFloorCovering
end

function shouldApplyContainerSort(container)
	if not container then
		return false
	end

	if container.isInDepot and container:isInDepot() then
		return false
	end

	if isStoreInboxContainer(container) then
		return false
	end

	return true
end

local function setStoreInboxFilter(container, filterKey)
	if not container then
		return
	end

	local filterId = resolveStoreInboxFilterId(container, filterKey)

	g_game.seekInContainer(container:getId(), container:getFirstIndex(), filterId)
end

local function showStoreInboxContextMenu(widget, mousePos, mouseButton, container)
	local menu = g_ui.createWidget("StoreInboxSubMenu")

	if not menu then
		return false
	end

	menu:setGameMenu(true)

	local filterState = getStoreInboxFilterState(container)
	local selectedFilter = container:getSelectedFilter()
	local updatingChecks = false
	local filterWidgets = {}

	for _, widgetId in ipairs(STORE_INBOX_FILTER_WIDGET_IDS) do
		filterWidgets[widgetId] = menu:getChildById(widgetId)
	end

	for _, widgetId in ipairs(STORE_INBOX_FILTER_WIDGET_IDS) do
		local widget = filterWidgets[widgetId]

		if widget then
			local visible = isStoreInboxFilterOptionVisible(widgetId, filterState)

			widget:setVisible(visible)

			if not visible then
				widget:setChecked(false)
			end
		end
	end

	local function setFilterChecks(activeKey)
		updatingChecks = true

		for _, widgetId in ipairs(STORE_INBOX_FILTER_WIDGET_IDS) do
			local widget = filterWidgets[widgetId]

			if widget and widget:isVisible() then
				widget:setChecked(widgetId == activeKey)
			end
		end

		updatingChecks = false
	end

	local activeKey = normalizeStoreInboxActiveFilterKey(container, selectedFilter, filterState)

	setFilterChecks(activeKey)

	for _, widgetId in ipairs(STORE_INBOX_FILTER_WIDGET_IDS) do
		local widget = filterWidgets[widgetId]

		if widget and widget:isVisible() then
			function widget.onCheckChange()
				if updatingChecks then
					return
				end

				if widget:isChecked() then
					setFilterChecks(widgetId)
					setStoreInboxFilter(container, widgetId)
				elseif widgetId ~= "filterAll" then
					setFilterChecks("filterAll")
					setStoreInboxFilter(container, "filterAll")
				else
					setFilterChecks("filterAll")
				end

				menu:destroy()
			end
		end
	end

	local buttonPos = widget:getPosition()
	local buttonSize = widget:getSize()
	local menuWidth = menu:getWidth()
	local buttonCenterX = buttonPos.x + buttonSize.width / 2
	local buttonCenterY = buttonPos.y + buttonSize.height / 2
	local menuX = buttonCenterX - menuWidth
	local menuY = buttonCenterY

	menu:display({
		x = menuX,
		y = menuY
	})

	return true
end

local DROP_TRANSPARENT_WIDGET_IDS = {
	globalDragPreviewItem = true,
	modalBlocker = true,
	mapDragPreviewItem = true
}

local function isDropTransparentWidget(widget)
	if not widget then
		return true
	end

	if widget:isPhantom() then
		return true
	end

	local id = widget.getId and widget:getId() or ""

	return DROP_TRANSPARENT_WIDGET_IDS[id] == true
end

local function isWidgetDescendantOf(widget, ancestor)
	while widget do
		if widget == ancestor then
			return true
		end

		widget = widget:getParent()
	end

	return false
end

local function getPrimaryDropBlockingWidget(mousePos)
	local children = rootWidget:recursiveGetChildrenByPos(mousePos)

	for i = 1, #children do
		local child = children[i]

		if not isDropTransparentWidget(child) then
			return child
		end
	end

	return nil
end

local function shouldContainerPanelAcceptDrop(containerWindow, mousePos)
	if not containerWindow or containerWindow:isDestroyed() then
		return false
	end

	local blocker = getPrimaryDropBlockingWidget(mousePos)

	if not blocker then
		return false
	end

	if blocker:getClassName() == "UIGameMap" then
		return false
	end

	if blocker ~= containerWindow and not isWidgetDescendantOf(blocker, containerWindow) then
		return false
	end

	return true
end

local function findContainerSlotWidgetAtPos(itemsPanel, mousePos)
	if not itemsPanel or not itemsPanel:containsPaddingPoint(mousePos) then
		return nil
	end

	local layout = itemsPanel:getLayout()

	if not layout or not layout:isUIGridLayout() then
		return nil
	end

	local paddingRect = itemsPanel:getPaddingRect()
	local virtualOffset = itemsPanel:getVirtualOffset()
	local localX = mousePos.x - paddingRect.x + virtualOffset.x
	local localY = mousePos.y - paddingRect.y + virtualOffset.y

	if localX < 0 or localY < 0 then
		return nil
	end

	local cellSize = layout:getCellSize()
	local spacingX, spacingY = getGridSpacing(layout)
	local stepX = cellSize.width + spacingX
	local stepY = cellSize.height + spacingY

	if stepX <= 0 or stepY <= 0 then
		return nil
	end

	local numColumns = layout:getNumColumns()

	if numColumns <= 0 then
		return nil
	end

	local col = math.floor((localX + spacingX / 2) / stepX)
	local row = math.floor((localY + spacingY / 2) / stepY)

	if col < 0 or row < 0 or numColumns <= col then
		return nil
	end

	local numLines = layout:getNumLines()

	if numLines > 0 and numLines <= row then
		return nil
	end

	local slotIndex = row * numColumns + col

	return itemsPanel:getChildById("item" .. slotIndex)
end

local function clearContainerDragHoveredSlot()
	if containerDragHoveredSlot then
		containerDragHoveredSlot:setBorderWidth(0)

		containerDragHoveredSlot = nil
	end
end

function clearContainerDragHover()
	clearContainerDragHoveredSlot()

	local draggingWidget = g_ui.getDraggingWidget()

	if draggingWidget and draggingWidget.hoveredWho then
		draggingWidget.hoveredWho:setBorderWidth(0)

		draggingWidget.hoveredWho = nil
	end
end

local function setContainerDragHoveredSlot(slotWidget, draggingWidget)
	local itemWidget = getContainerSlotItemWidget(slotWidget)

	if itemWidget == containerDragHoveredSlot then
		return
	end

	clearContainerDragHoveredSlot()

	if itemWidget and draggingWidget and itemWidget ~= draggingWidget then
		itemWidget:setBorderWidth(1)

		draggingWidget.hoveredWho = itemWidget
		containerDragHoveredSlot = itemWidget
	end
end

local function updateContainerDragHover(mousePos)
	local draggingWidget = g_ui.getDraggingWidget()

	if not draggingWidget or not draggingWidget.currentDragThing then
		clearContainerDragHoveredSlot()

		return
	end

	for _, container in pairs(g_game.getContainers()) do
		local itemsPanel = container.itemsPanel

		if itemsPanel and itemsPanel.containerDropTarget and itemsPanel:containsPaddingPoint(mousePos) then
			local slotWidget = findContainerSlotWidgetAtPos(itemsPanel, mousePos)
			local itemWidget = getContainerSlotItemWidget(slotWidget)

			if itemWidget then
				local hoveredWidget = rootWidget:recursiveGetChildByPos(mousePos, false)

				if hoveredWidget == itemWidget then
					if containerDragHoveredSlot and containerDragHoveredSlot ~= itemWidget then
						clearContainerDragHoveredSlot()
					end

					return
				end

				setContainerDragHoveredSlot(slotWidget, draggingWidget)
			else
				clearContainerDragHoveredSlot()
			end

			return
		end
	end

	clearContainerDragHoveredSlot()
end

local function setupContainerDropTarget(containerPanel, containerWindow)
	containerPanel.containerDropTarget = true
	containerPanel.containerWindow = containerWindow

	function containerPanel:onDrop(draggedWidget, mousePos)
		if self:isDestroyed() then
			return false
		end

		local containerWin = self.containerWindow

		if not containerWin or containerWin:isDestroyed() then
			return false
		end

		if not shouldContainerPanelAcceptDrop(containerWin, mousePos) then
			return false
		end

		if not self:containsPaddingPoint(mousePos) then
			return false
		end

		local slotWidget = findContainerSlotWidgetAtPos(self, mousePos)
		local itemWidget = getContainerSlotItemWidget(slotWidget)

		if itemWidget then
			return itemWidget:onDrop(draggedWidget, mousePos, true)
		end

		return false
	end

	function containerPanel:onHoverChange(hovered)
		UIWidget.onHoverChange(self, hovered)

		if hovered then
			updateContainerDragHover(g_window.getMousePosition())
		else
			clearContainerDragHoveredSlot()
		end
	end

	function containerPanel:onMouseMove(mousePos, mouseMoved)
		if g_ui.getDraggingWidget() then
			updateContainerDragHover(mousePos)
		end
	end
end

local layoutRestoreScheduled = false
local savingContainerLayoutsOnLogout = false
local LAYOUT_RESTORE_MAX_ATTEMPTS = 30
local nextContainerOpenInvocation = 0
local containersLayoutRestoredThisLogin = false

local function getSidebarWidgetOptionsPersistence()
	return modules.game_interface and modules.game_interface.SidebarWidgetOptionsPersistence
end

local function clearContainerLayoutForId(windowId)
	if not windowId then
		return
	end

	local id = tostring(windowId):match("^container(%d+)$")

	if not id then
		return
	end

	local swop = getSidebarWidgetOptionsPersistence()

	if swop and swop.clearContainerOptions then
		swop.clearContainerOptions(tonumber(id))
	end
end

local function getSidebarWidgetsPersistence()
	return modules.game_interface and modules.game_interface.SidebarWidgetsPersistence
end

local function getSavedLayoutForWindow(window)
	if not window or not window.getId then
		return nil, nil
	end

	local savedParentId = window:getSettings("parentId")
	local savedIndex = window:getSettings("index")
	local swp = getSidebarWidgetsPersistence()

	if not savedParentId and swp and swp.getWidgetPlacement then
		local placement = swp.getWidgetPlacement(window:getId())

		if placement then
			savedParentId = placement.parentId
			savedIndex = placement.index
		end
	end

	if not savedParentId and SidebarLayoutState and SidebarLayoutState.getWidgets then
		local data = SidebarLayoutState.getWidgets()[window:getId()]

		if data then
			savedParentId = data.parentId
			savedIndex = data.index
		end
	end

	return savedParentId, savedIndex
end

local function clearContainerWindowLayout(window)
	if not window or not window.getId then
		return
	end

	clearContainerLayoutForId(window:getId())
end

local function ensureSidebarForSavedLayout(parentId)
	if not parentId or not modules.client_options then
		return
	end

	local optionKey

	if parentId == "gameLeftPanel" then
		optionKey = "showLeftPanel"
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
	end
end

local function computeExpectedNumLines(layout, container)
	local numColumns = layout:getNumColumns()

	if numColumns <= 0 then
		return math.max(layout:getNumLines(), 1)
	end

	local capacity = container:getCapacity()

	return math.max(math.ceil(capacity / numColumns), 1)
end

local function applyDefaultContentHeightForWindow(containerWindow, layout, cellSize, container)
	local minRows = 1

	if modules.client_options.getOption("openMaximized") then
		local numLines = math.max(computeExpectedNumLines(layout, container), minRows)

		containerWindow:setContentHeight(cellSize.height * numLines)
	else
		local filledLines = math.max(math.ceil(container:getItemsCount() / layout:getNumColumns()), minRows)

		containerWindow:setContentHeight(filledLines * cellSize.height)
	end
end

local function applyContainerHeight(containerWindow, container, layout, cellSize)
	if not containerWindow or containerWindow:isDestroyed() then
		return
	end

	if containerWindow.preservedHeight and containerWindow.preservedHeight > 0 then
		containerWindow:setHeight(containerWindow.preservedHeight)

		containerWindow.preservedHeight = nil

		return
	end

	local swop = getSidebarWidgetOptionsPersistence()
	local containerOpts = swop and swop.getContainerOptions and swop.getContainerOptions(container:getId())

	if containerOpts and type(containerOpts.contentHeight) == "number" and containerOpts.contentHeight > 0 then
		containerWindow:setContentHeight(containerOpts.contentHeight)

		return
	end

	local legacyHeight = containerWindow:getSettings("height")

	if legacyHeight and legacyHeight > 0 then
		containerWindow:setHeight(legacyHeight)

		return
	end

	applyDefaultContentHeightForWindow(containerWindow, layout, cellSize, container)
end

local function applyContainerLayout(container, cellSize, layout)
	local containerWindow = container.window

	if not containerWindow or containerWindow:isDestroyed() then
		return false
	end

	local savedParentId, savedIndex = getSavedLayoutForWindow(containerWindow)
	local swop = getSidebarWidgetOptionsPersistence()
	local containerOpts = swop and swop.getContainerOptions and swop.getContainerOptions(container:getId())
	local savedHeight = containerWindow:getSettings("height")
	local savedContentHeight
	local savedMinimized = containerWindow:getSettings("minimized")
	local savedClosed = false

	if containerOpts then
		if containerOpts.contentHeight == 0 and containerOpts.contentMaximized == true then
			savedClosed = true
			savedMinimized = false
		elseif containerOpts.contentMaximized == false then
			savedMinimized = true
		elseif containerOpts.contentMaximized == true then
			savedMinimized = false
		end

		if type(containerOpts.contentHeight) == "number" and containerOpts.contentHeight > 0 then
			savedContentHeight = containerOpts.contentHeight
		end
	end

	if not savedParentId then
		local currentParent = containerWindow:getParent()

		if currentParent and type(currentParent) == "userdata" and not currentParent:isDestroyed() then
			container._needsLayoutRestore = nil

			return true
		end

		local panel = modules.game_interface.findContentPanelAvailable(containerWindow, cellSize.height)

		if not panel or type(panel) ~= "userdata" then
			panel = modules.game_interface.getRightPanel()
		end

		if panel and type(panel) == "userdata" and containerWindow:getParent() ~= panel then
			panel:addChild(containerWindow)
		end

		applyDefaultContentHeightForWindow(containerWindow, layout, cellSize, container)

		container._needsLayoutRestore = nil

		return true
	end

	ensureSidebarForSavedLayout(savedParentId)

	local currentParent = containerWindow:getParent()

	if currentParent then
		currentParent:removeChild(containerWindow)
	end

	containerWindow.miniLoaded = false
	containerWindow.miniIndex = nil

	local parent = rootWidget:recursiveGetChildById(savedParentId)

	if not parent or type(parent) ~= "userdata" then
		container._needsLayoutRestore = true

		return false
	end

	local isSidePanel = modules.game_interface and modules.game_interface.isGameSidePanelId and modules.game_interface.isGameSidePanelId(parent:getId())
	local panelReady = parent:isVisible() or isSidePanel and parent:isOn()

	if not panelReady then
		container._needsLayoutRestore = true

		return false
	end

	if parent:getClassName() == "UIMiniWindowContainer" and savedIndex and type(parent.scheduleInsert) == "function" then
		local requestedIdx = tonumber(savedIndex)

		if requestedIdx then
			local actualIndex
			local children = parent:getChildren()
			local saveCount = 0

			for i = 1, #children do
				local child = children[i]

				if child and child.save then
					saveCount = saveCount + 1
				end

				if requestedIdx <= saveCount then
					actualIndex = i

					break
				end
			end

			actualIndex = actualIndex or parent:getChildCount() + 1
			containerWindow.miniIndex = requestedIdx

			parent:scheduleInsert(containerWindow, actualIndex)
		else
			containerWindow.miniIndex = nil

			parent:addChild(containerWindow)
		end
	else
		local savedPosition = containerWindow:getSettings("position")

		if savedPosition then
			containerWindow:setParent(parent, true)
			containerWindow:setPosition(topoint(savedPosition))
		else
			local idx = tonumber(savedIndex)

			if idx and type(parent.insertChild) == "function" then
				local children = parent:getChildren()
				local saveCount = 0
				local actualIndex

				for i = 1, #children do
					local child = children[i]

					if child and child.save then
						saveCount = saveCount + 1
					end

					if idx <= saveCount then
						actualIndex = i

						break
					end
				end

				actualIndex = actualIndex or parent:getChildCount() + 1

				parent:insertChild(actualIndex, containerWindow)
			else
				parent:addChild(containerWindow)
			end
		end
	end

	containerWindow.miniLoaded = true

	containerWindow:eraseSettings({
		closed = true
	})

	if savedClosed then
		containerWindow:close(true)
	else
		if containerWindow.preservedHeight and containerWindow.preservedHeight > 0 then
			containerWindow:setHeight(containerWindow.preservedHeight)

			containerWindow.preservedHeight = nil
		elseif savedContentHeight and containerWindow:isResizeable() then
			containerWindow:setContentHeight(savedContentHeight)
		elseif savedHeight and containerWindow:isResizeable() then
			containerWindow:setHeight(savedHeight)
		end

		containerWindow:open(true)

		if savedMinimized then
			containerWindow:minimize(true)
		end
	end

	if SidebarLayoutState and SidebarLayoutState.noteWidgetPlacement then
		SidebarLayoutState.noteWidgetPlacement(containerWindow)
	end

	if parent:getClassName() == "UIMiniWindowContainer" then
		addEvent(function()
			if parent and not parent:isDestroyed() then
				parent:order()
			end
		end)
	end

	container._needsLayoutRestore = nil
	container._layoutRestoreAttempts = nil

	return true
end

local function applyDefaultPanelFallback(container, cellSize, layout)
	local containerWindow = container.window

	if not containerWindow or containerWindow:isDestroyed() then
		return
	end

	local currentParent = containerWindow:getParent()

	if currentParent then
		currentParent:removeChild(containerWindow)
	end

	local panel = modules.game_interface.findContentPanelAvailable(containerWindow, cellSize.height)

	if not panel or type(panel) ~= "userdata" then
		panel = modules.game_interface.getRightPanel()
	end

	if panel and type(panel) == "userdata" then
		panel:addChild(containerWindow)
	end

	applyDefaultContentHeightForWindow(containerWindow, layout, cellSize, container)
	containerWindow:open(true)

	container._needsLayoutRestore = nil
	container._layoutRestoreAttempts = nil
end

local function restoreAllContainerLayouts()
	local stillPending = false

	for _, container in pairs(g_game.getContainers()) do
		local window = container.window

		if not window or window:isDestroyed() then
			-- block empty
		else
			local savedParentId = getSavedLayoutForWindow(window)
			local currentParent = window:getParent()
			local currentParentId = currentParent and currentParent:getId()

			if savedParentId and (container._needsLayoutRestore or savedParentId ~= currentParentId) then
				local containerPanel = window:getChildById("contentsPanel")
				local layout = containerPanel and containerPanel:getLayout()

				if layout then
					local cellSize = layout:getCellSize()

					applyContainerLayout(container, cellSize, layout)
					toggleContainerPages(window, container)
					applyContainerContextLayout(window)

					if container._needsLayoutRestore then
						container._layoutRestoreAttempts = (container._layoutRestoreAttempts or 0) + 1

						if container._layoutRestoreAttempts > LAYOUT_RESTORE_MAX_ATTEMPTS then
							applyDefaultPanelFallback(container, cellSize, layout)
							toggleContainerPages(window, container)
							applyContainerContextLayout(window)
						else
							stillPending = true
						end
					end
				end
			elseif container._needsLayoutRestore and not savedParentId then
				container._needsLayoutRestore = nil
			end
		end
	end

	if stillPending then
		scheduleContainersLayoutRestore()
	end
end

function restoreAllContainerLayoutsNow()
	if containersLayoutRestoredThisLogin then
		return
	end

	containersLayoutRestoredThisLogin = true

	restoreAllContainerLayouts()
end

function scheduleContainersLayoutRestore()
	if layoutRestoreScheduled then
		return
	end

	layoutRestoreScheduled = true

	addEvent(function()
		layoutRestoreScheduled = false

		restoreAllContainerLayouts()
	end)
end

function toggleManualSortMode()
	if not containerSettings then
		return
	end

	local newState = containerSettings.useManualSortMode ~= 1

	containerSettings.useManualSortMode = newState and 1 or 0

	g_settings.setNode("containers", containerSettings)
	g_game.setManualContainerSort(newState)
	refreshAllContainerTitleStyles()
end

function init()
	g_ui.importStyle("container")
	g_ui.importStyle("sortNestedContainersConfirm")

	containerSettings = g_settings.getNode("containers")

	if not containerSettings then
		containerSettings = {}
		containerSettings.useManualSortMode = 0
		containerSettings.currentSortMode = "none"
		containerSettings.sortContainersFirst = 0
		containerSettings.sortNestedContainers = 0

		g_settings.setNode("containers", containerSettings)
	end

	if not containerSettings.manualSortMigrated then
		containerSettings.useManualSortMode = 0
		containerSettings.manualSortMigrated = 1

		g_settings.setNode("containers", containerSettings)
	end

	if containerSettings.sortNestedContainers == nil then
		containerSettings.sortNestedContainers = 0
	end

	if containerSettings.sortContainersFirst == nil then
		containerSettings.sortContainersFirst = 0
	end

	if containerSettings.useManualSortMode == nil then
		containerSettings.useManualSortMode = 0
	end

	g_game.setManualContainerSort(containerSettings.useManualSortMode == 1)
	connect(Container, {
		onOpen = onContainerOpen,
		onClose = onContainerClose,
		onSizeChange = onContainerChangeSize,
		onUpdateItem = onContainerUpdateItem
	})
	connect(g_game, {
		onGameEnd = onGameEnd,
		onGameStart = onContainersGameStart
	})
	Keybind.new("Containers", "Toggle Manual Sort Mode", {
		[CHAT_MODE.ON] = "",
		[CHAT_MODE.OFF] = "Shift+S"
	}, "")
	Keybind.bind("Containers", "Toggle Manual Sort Mode", {
		{
			type = KEY_DOWN,
			callback = function()
				if not g_game.isOnline() then
					return
				end

				toggleManualSortMode()
			end
		}
	})

	if not UIItem._containerDragMoveWrapped then
		UIItem._containerDragMoveWrapped = true

		local originalOnDragMove = UIItem.onDragMove

		function UIItem:onDragMove(mousePos, mouseMoved)
			if originalOnDragMove then
				originalOnDragMove(self, mousePos, mouseMoved)
			end

			updateContainerDragHover(mousePos)
		end

		local originalOnDragLeave = UIItem.onDragLeave

		function UIItem:onDragLeave(droppedWidget, mousePos)
			clearContainerDragHoveredSlot()

			if originalOnDragLeave then
				return originalOnDragLeave(self, droppedWidget, mousePos)
			end

			return true
		end
	end

	reloadContainers()
end

function terminate()
	Keybind.delete("Containers", "Toggle Manual Sort Mode")
	disconnect(Container, {
		onOpen = onContainerOpen,
		onClose = onContainerClose,
		onSizeChange = onContainerChangeSize,
		onUpdateItem = onContainerUpdateItem
	})

	if g_game then
		disconnect(g_game, {
			onGameEnd = onGameEnd,
			onGameStart = onContainersGameStart
		})
	end
end

function onContainersGameStart()
	scheduleContainersLayoutRestore()
end

function onGameEnd()
	savingContainerLayoutsOnLogout = true

	clean()

	savingContainerLayoutsOnLogout = false
	containersLayoutRestoredThisLogin = false
end

function reloadContainers()
	clean()

	for _, container in pairs(g_game.getContainers()) do
		onContainerOpen(container)
	end
end

function clean()
	clearContainerDragHoveredSlot()

	for containerid, container in pairs(g_game.getContainers()) do
		destroy(container)
	end
end

function destroy(container)
	container._needsLayoutRestore = nil

	if container.window then
		local parent = container.window:getParent()

		container.window:destroy()

		container.window = nil
		container.itemsPanel = nil

		if parent and not parent:isDestroyed() and parent:getClassName() == "UIMiniWindowContainer" and type(parent.refreshSidebarFreeSpace) == "function" then
			parent:refreshSidebarFreeSpace()
		end
	end
end

function showContainersContextMenu(widget, mousePos, mouseButton)
	local sourceContainer = getContainerFromWidget(widget)

	if isStoreInboxContainer(sourceContainer) then
		if not shouldShowStoreInboxFilterButton(sourceContainer) then
			return false
		end

		return showStoreInboxContextMenu(widget, mousePos, mouseButton, sourceContainer)
	end

	local menu = g_ui.createWidget("ContainersSubMenu")

	if not menu then
		return false
	end

	menu:setGameMenu(true)

	for _, choice in ipairs(menu:getChildren()) do
		local choiceId = choice:getId()

		if choiceId and choiceId ~= "HorizontalSeparator" then
			local widgetClass = choice:getClassName()
			local isSortingAction = choiceId:find("sortAsc") or choiceId:find("sortDesc")
			local isActionButton = isSortingAction or choiceId == "moveToObtainContainers"

			if isActionButton then
				function choice.onClick()
					onContainersMenuAction(choiceId, sourceContainer)
					menu:destroy()
				end

				function choice.onMouseRelease(widget, mousePos, mouseButton)
					if mouseButton == MouseLeftButton then
						onContainersMenuAction(choiceId, sourceContainer)
						menu:destroy()

						return true
					end

					return false
				end

				if isSortingAction then
					choice:setEnabled(true)
					choice:setColor("#ffffff")
				else
					choice:setEnabled(true)
					choice:setColor("#ffffff")
				end
			else
				local currentState = getContainerOptionState(choiceId)

				choice:setChecked(currentState)
				choice:setEnabled(true)
				choice:setColor("#ffffff")

				function choice.onCheckChange()
					onContainersMenuAction(choiceId, sourceContainer)
					menu:destroy()
				end
			end
		end
	end

	local buttonPos = widget:getPosition()
	local buttonSize = widget:getSize()
	local menuWidth = menu:getWidth()
	local buttonCenterX = buttonPos.x + buttonSize.width / 2
	local buttonCenterY = buttonPos.y + buttonSize.height / 2
	local menuX = buttonCenterX - menuWidth
	local menuY = buttonCenterY

	menu:display({
		x = menuX,
		y = menuY
	})

	return true
end

function getContainerOptionState(optionId)
	if not containerSettings then
		return false
	end

	if optionId == "sortContainersFirst" then
		return containerSettings.sortContainersFirst == 1
	elseif optionId == "sortNestedContainers" then
		return containerSettings.sortNestedContainers == 1
	elseif optionId == "useManualSortMode" then
		return containerSettings.useManualSortMode == 1
	elseif optionId == "moveNestedContainers" then
		return containerSettings.moveNestedContainers == 1
	end

	return false
end

function sortContainerItems(container, sortMode)
	if not container then
		return
	end

	requestContainerSort(container, sortMode)
end

function onContainersMenuAction(actionId, container)
	local isToggleOption = actionId == "sortContainersFirst" or actionId == "sortNestedContainers" or actionId == "useManualSortMode" or actionId == "moveNestedContainers"
	local isActionButton = actionId == "moveToObtainContainers" or actionId:find("sortAsc") or actionId:find("sortDesc")

	if isActionButton then
		if actionId == "moveToObtainContainers" then
			local function doMove()
				if container then
					requestMoveToObtainContainers(container)
				else
					applyMoveToObtainToOpenContainers()
				end
			end

			local movesNested = containerSettings and containerSettings.moveNestedContainers == 1

			if movesNested and shouldAskBeforeNestedAction("askBeforeMoving") then
				displayNestedContainersConfirmBox(tr("Confirmation to Move Nested Containers"), tr("You are about to move the contents of all containers and their nested subcontainers to your Obtain containers. Do you want to proceed?"), "askBeforeMoving", doMove)
			else
				doMove()
			end

			return
		elseif actionId:find("sortAsc") or actionId:find("sortDesc") then
			handleContainerSortAction(container, actionId)

			return
		end
	end

	if isToggleOption then
		local currentState = getContainerOptionState(actionId)
		local newState = not currentState

		containerSettings[actionId] = newState and 1 or 0

		g_settings.setNode("containers", containerSettings)

		if actionId == "useManualSortMode" then
			g_game.setManualContainerSort(newState)
			refreshAllContainerTitleStyles()
		end
	end
end

local applyContainerHeaderButtonLayout

function refreshContainerItems(container)
	for slot = 0, container:getCapacity() - 1 do
		local slotWidget = container.itemsPanel:getChildById("item" .. slot)

		applyContainerSlotVisuals(slotWidget, container:getItem(slot))
		bindContainerSlotPosition(slotWidget, container:getSlotPosition(slot))
	end

	if container:hasPages() then
		refreshContainerPages(container)
	end

	if container.window and isStoreInboxContainer(container) then
		applyContainerHeaderButtonLayout(container.window, container)
	end
end

local function isContainerInHorizontalContext(widget)
	local current = widget

	for _ = 1, 12 do
		if not current then
			break
		end

		if current.isHorizontalPanel then
			return true
		end

		local id = current.getId and current:getId() or nil

		if id == "gameLeftTopPanel" or id == "gameRightTopPanel" then
			return true
		end

		current = current.getParent and current:getParent() or nil
	end

	return false
end

function isContainerMiniWindow(widget)
	if not widget or widget.isDestroyed and widget:isDestroyed() then
		return false
	end

	return widget:getChildById("containerItemWidget") ~= nil
end

function applyContainerContextLayout(containerWindow)
	if not containerWindow or containerWindow.isDestroyed and containerWindow:isDestroyed() then
		return
	end

	if not isContainerMiniWindow(containerWindow) then
		return
	end

	local contents = containerWindow.getChildById and containerWindow:getChildById("contentsPanel")

	if not contents then
		return
	end

	contents:setMarginLeft(isContainerInHorizontalContext(containerWindow) and 1 or 5)
	contents:setMarginRight(1)
end

local CONTAINER_UP_BUTTON_MARGIN = 1
local CONTAINER_HEADER_BUTTON_MARGIN = 5
local CONTAINER_SLOT_BATCH_SIZE = 50

local function createContainerSlotWidget(containerPanel, container, slot)
	local slotWidget = g_ui.createWidget("ContainerItemSlot", containerPanel)

	slotWidget:setId("item" .. slot)
	slotWidget:setMargin(0)
	applyContainerSlotVisuals(slotWidget, container:getItem(slot))
	bindContainerSlotPosition(slotWidget, container:getSlotPosition(slot))

	if not container:isUnlocked() then
		slotWidget:setBorderColor("red")
	end

	return slotWidget
end

function applyContainerHeaderButtonLayout(containerWindow, container)
	if not containerWindow or containerWindow.isDestroyed and containerWindow:isDestroyed() then
		return
	end

	local upButton = containerWindow:getChildById("upButton")
	local searchButton = containerWindow:getChildById("searchButton")
	local contextMenuButton = containerWindow:recursiveGetChildById("contextMenuButton")
	local lockButton = containerWindow:recursiveGetChildById("lockButton")
	local minimizeButton = containerWindow:recursiveGetChildById("minimizeButton")

	if not upButton or not contextMenuButton or not minimizeButton then
		return
	end

	local showDepotSearch = container and container.isInDepot and container:isInDepot()
	local showStoreInboxFilter = shouldShowStoreInboxFilterButton(container)

	if searchButton then
		searchButton:setVisible(showDepotSearch)
	end

	contextMenuButton:setVisible(not showDepotSearch and (showStoreInboxFilter or not isStoreInboxContainer(container)))

	local hasParent = container and modules.game_interface.canContainerShowUpButton and modules.game_interface.canContainerShowUpButton(container)

	upButton:setVisible(hasParent)
	upButton:breakAnchors()
	upButton:addAnchor(AnchorTop, minimizeButton:getId(), AnchorTop)
	upButton:addAnchor(AnchorRight, minimizeButton:getId(), AnchorLeft)
	upButton:setMarginRight(CONTAINER_UP_BUTTON_MARGIN)
	upButton:setMarginTop(0)

	local headerButton = showDepotSearch and searchButton or contextMenuButton

	headerButton = headerButton or contextMenuButton

	headerButton:breakAnchors()

	if hasParent then
		headerButton:addAnchor(AnchorTop, upButton:getId(), AnchorTop)
		headerButton:addAnchor(AnchorRight, upButton:getId(), AnchorLeft)
	else
		headerButton:addAnchor(AnchorTop, minimizeButton:getId(), AnchorTop)
		headerButton:addAnchor(AnchorRight, minimizeButton:getId(), AnchorLeft)
	end

	headerButton:setMarginRight(CONTAINER_HEADER_BUTTON_MARGIN)
	headerButton:setMarginTop(0)

	if lockButton then
		lockButton:breakAnchors()
		lockButton:addAnchor(AnchorTop, headerButton:getId(), AnchorTop)
		lockButton:addAnchor(AnchorRight, headerButton:getId(), AnchorLeft)
		lockButton:setMarginRight(CONTAINER_HEADER_BUTTON_MARGIN)
		lockButton:setMarginTop(0)
	end
end

function toggleContainerPages(containerWindow, container)
	local pages = container:hasPages()
	local scrollbar = containerWindow:getChildById("miniwindowScrollBar")
	local pagePanel = containerWindow:getChildById("pagePanel")
	local separator = containerWindow:getChildById("separator")
	local contentsPanel = containerWindow:getChildById("contentsPanel")

	if pages then
		scrollbar:breakAnchors()
		scrollbar:addAnchor(AnchorTop, "closeButton", AnchorBottom)
		scrollbar:addAnchor(AnchorRight, "parent", AnchorRight)
		scrollbar:addAnchor(AnchorBottom, "separator", AnchorTop)
		scrollbar:setMarginTop(1)
		scrollbar:setMarginRight(4)
		scrollbar:setMarginBottom(3)
		contentsPanel:breakAnchors()
		contentsPanel:addAnchor(AnchorTop, "miniwindowTopBar", AnchorBottom)
		contentsPanel:addAnchor(AnchorLeft, "parent", AnchorLeft)
		contentsPanel:addAnchor(AnchorRight, "miniwindowScrollBar", AnchorLeft)
		contentsPanel:addAnchor(AnchorBottom, "separator", AnchorTop)
		contentsPanel:setMarginLeft(isContainerInHorizontalContext(containerWindow) and 1 or 5)
		contentsPanel:setMarginBottom(1)
		contentsPanel:setMarginTop(-2)
		contentsPanel:setMarginRight(1)
	else
		scrollbar:breakAnchors()
		scrollbar:addAnchor(AnchorTop, "parent", AnchorTop)
		scrollbar:addAnchor(AnchorRight, "parent", AnchorRight)
		scrollbar:addAnchor(AnchorBottom, "parent", AnchorBottom)
		scrollbar:setMarginTop(15)
		scrollbar:setMarginRight(4)
		scrollbar:setMarginBottom(4)
		contentsPanel:breakAnchors()
		contentsPanel:addAnchor(AnchorTop, "miniwindowTopBar", AnchorBottom)
		contentsPanel:addAnchor(AnchorLeft, "parent", AnchorLeft)
		contentsPanel:addAnchor(AnchorRight, "miniwindowScrollBar", AnchorLeft)
		contentsPanel:addAnchor(AnchorBottom, "parent", AnchorBottom)
		contentsPanel:setMarginLeft(isContainerInHorizontalContext(containerWindow) and 1 or 5)
		contentsPanel:setMarginBottom(3)
		contentsPanel:setMarginTop(-2)
		contentsPanel:setMarginRight(1)
	end

	applyContainerHeaderButtonLayout(containerWindow, container)
	pagePanel:setVisible(pages)
	separator:setVisible(pages)
end

function refreshContainerPages(container)
	local currentPage = 1 + math.floor(container:getFirstIndex() / container:getCapacity())
	local pages = 1 + math.floor(math.max(0, container:getSize() - 1) / container:getCapacity())

	container.window:recursiveGetChildById("pageLabel"):setText(string.format("Page %i of %i", currentPage, pages))

	local prevPageButton = container.window:recursiveGetChildById("prevPageButton")
	local nextPageButton = container.window:recursiveGetChildById("nextPageButton")

	if pages == 1 then
		prevPageButton:setVisible(false)
		nextPageButton:setVisible(false)
	else
		if currentPage == 1 then
			prevPageButton:setVisible(false)
		else
			prevPageButton:setVisible(true)
			prevPageButton:setEnabled(true)

			function prevPageButton.onClick()
				local currentHeight = container.window:getHeight()

				container.window.preservedHeight = currentHeight

				g_game.seekInContainer(container:getId(), container:getFirstIndex() - container:getCapacity(), getContainerSeekFilter(container))
			end
		end

		if pages <= currentPage then
			nextPageButton:setVisible(false)
		else
			nextPageButton:setVisible(true)
			nextPageButton:setEnabled(true)

			function nextPageButton.onClick()
				local currentHeight = container.window:getHeight()

				container.window.preservedHeight = currentHeight

				g_game.seekInContainer(container:getId(), container:getFirstIndex() + container:getCapacity(), getContainerSeekFilter(container))
			end
		end
	end
end

function onContainerOpen(container, previousContainer)
	if not previousContainer and container.window and not container.window:isDestroyed() and container.window:isVisible() then
		clearContainerWindowLayout(container.window)
		g_game.close(container)

		return
	end

	local containerWindow
	local reusedWindow = false

	if previousContainer then
		previousContainer._openToken = (previousContainer._openToken or 0) + 1
		containerWindow = previousContainer.window
		previousContainer.window = nil
		previousContainer.itemsPanel = nil

		if containerWindow and not containerWindow:isDestroyed() then
			reusedWindow = true
		end
	end

	if not containerWindow or containerWindow:isDestroyed() then
		containerWindow = g_ui.createWidget("ContainerWindow")
		reusedWindow = false
	end

	if not containerWindow then
		g_logger.error("onContainerOpen: failed to create ContainerWindow for id " .. container:getId())

		return
	end

	local openToken = (container._openToken or 0) + 1

	container._openToken = openToken
	nextContainerOpenInvocation = nextContainerOpenInvocation + 1

	local invocationId = nextContainerOpenInvocation

	containerWindow._openInvocationId = invocationId

	local function isOpenStale()
		return container._openToken ~= openToken
	end

	local function abortStaleOpen()
		if not containerWindow or containerWindow:isDestroyed() then
			return
		end

		if containerWindow._openInvocationId ~= invocationId then
			return
		end

		containerWindow:destroy()
	end

	containerWindow:setId("container" .. container:getId())

	local containerPanel = containerWindow:getChildById("contentsPanel")
	local containerItemWidget = containerWindow:getChildById("containerItemWidget")
	local scrollbar = containerWindow:getChildById("miniwindowScrollBar")

	scrollbar:mergeStyle({
		["$!on"] = {}
	})

	local upButton = containerWindow:getChildById("upButton")

	function upButton.onClick()
		g_game.openParent(container)
	end

	function containerWindow.onMinimize()
		local pagePanel = containerWindow:getChildById("pagePanel")

		if pagePanel and pagePanel:isVisible() then
			pagePanel.wasVisibleBeforeMinimize = true

			pagePanel:setVisible(false)
		end
	end

	function containerWindow.onMaximize()
		local pagePanel = containerWindow:getChildById("pagePanel")

		if pagePanel and pagePanel.wasVisibleBeforeMinimize then
			pagePanel:setVisible(true)

			pagePanel.wasVisibleBeforeMinimize = nil
		end
	end

	local toggleFilterButton = containerWindow:recursiveGetChildById("toggleFilterButton")

	if toggleFilterButton then
		toggleFilterButton:setVisible(false)
		toggleFilterButton:setOn(false)
	end

	local newWindowButton = containerWindow:recursiveGetChildById("newWindowButton")

	if newWindowButton then
		newWindowButton:setVisible(false)
	end

	local contextMenuButton = containerWindow:recursiveGetChildById("contextMenuButton")

	if contextMenuButton then
		function contextMenuButton.onClick(widget, mousePos, mouseButton)
			return showContainersContextMenu(widget, mousePos, mouseButton)
		end
	end

	local searchButton = containerWindow:getChildById("searchButton")

	if searchButton then
		function searchButton.onClick()
			if modules.game_search_locker and modules.game_search_locker.onRequestSearch then
				modules.game_search_locker.onRequestSearch()
			end
		end
	end

	applyContainerHeaderButtonLayout(containerWindow, container)

	local name = container:getName()

	name = name:sub(1, 1):upper() .. name:sub(2)

	if name:len() > 14 then
		name = name:sub(1, 14) .. "..."
	end

	local titleWidget = containerWindow:getChildById("miniwindowTitle")

	if titleWidget then
		titleWidget:setText(name)
		applyContainerTitleStyle(containerWindow)
	else
		containerWindow:setText(name)
	end

	containerItemWidget:setItem(container:getContainerItem())
	containerItemWidget:setPhantom(true)
	containerPanel:destroyChildren()

	local layout = containerPanel:getLayout()

	layout:disableUpdates()

	local function finishContainerOpen()
		if isOpenStale() then
			layout:enableUpdates()
			abortStaleOpen()

			return
		end

		layout:enableUpdates()
		layout:update()

		container.window = containerWindow
		container.itemsPanel = containerPanel

		setupContainerDropTarget(containerPanel, containerWindow)
		refreshContainerPages(container)

		local cellSize = layout:getCellSize()

		containerWindow:setContentMinimumHeight(cellSize.height)

		local expectedNumLines = computeExpectedNumLines(layout, container)
		local maxHeightOffset = container:hasPages() and 65 or 30

		containerWindow:setContentMaximumHeight(cellSize.height * expectedNumLines + maxHeightOffset)

		local function restrictResize()
			function containerWindow.onResize()
				local minHeight = cellSize.height + 30

				if container:hasPages() then
					minHeight = minHeight + 35
				end

				if minHeight > containerWindow:getHeight() then
					containerWindow:setHeight(minHeight)
				end
			end
		end

		restrictResize()

		function containerWindow.onMinimize()
			local pagePanel = containerWindow:getChildById("pagePanel")

			if pagePanel and pagePanel:isVisible() then
				pagePanel.wasVisibleBeforeMinimize = true

				pagePanel:setVisible(false)
			end

			containerWindow.onResize = nil
		end

		function containerWindow.onMaximize()
			local pagePanel = containerWindow:getChildById("pagePanel")

			if pagePanel and pagePanel.wasVisibleBeforeMinimize then
				pagePanel:setVisible(true)

				pagePanel.wasVisibleBeforeMinimize = nil
			end

			restrictResize()
		end

		local function applyDefaultContentHeight()
			applyDefaultContentHeightForWindow(containerWindow, layout, cellSize, container)
		end

		containerWindow:setup()

		local closeButton = containerWindow:getChildById("closeButton")

		if closeButton then
			function closeButton.onClick()
				local parent = containerWindow:getParent()

				if parent then
					parent:removeChild(containerWindow)

					if parent:getClassName() == "UIMiniWindowContainer" and type(parent.refreshSidebarFreeSpace) == "function" then
						parent:refreshSidebarFreeSpace()
					end
				end

				clearContainerWindowLayout(containerWindow)
				g_game.close(container)
				containerWindow:hide()
			end
		end

		if not reusedWindow then
			local savedParentId = getSavedLayoutForWindow(containerWindow)

			if savedParentId then
				container._needsLayoutRestore = true

				containerWindow:hide()

				if not applyContainerLayout(container, cellSize, layout) then
					applyContainerHeight(containerWindow, container, layout, cellSize)
					scheduleContainersLayoutRestore()
				else
					container._layoutRestoreAttempts = nil
				end
			else
				container._needsLayoutRestore = nil

				local panel = modules.game_interface.findContentPanelAvailable(containerWindow, cellSize.height)

				containerWindow.miniIndex = nil
				containerWindow.miniLoaded = true

				panel:addChild(containerWindow)
				applyContainerHeight(containerWindow, container, layout, cellSize)

				if SidebarLayoutState and SidebarLayoutState.noteWidgetPlacement then
					SidebarLayoutState.noteWidgetPlacement(containerWindow)
				end
			end
		else
			if not containerWindow.preservedHeight or containerWindow.preservedHeight <= 0 then
				containerWindow.preservedHeight = containerWindow:getHeight()
			end

			applyContainerHeight(containerWindow, container, layout, cellSize)

			local currentParent = containerWindow:getParent()

			if not currentParent or currentParent:isDestroyed() or not containerWindow:isVisible() then
				local panel = modules.game_interface.findContentPanelAvailable(containerWindow, cellSize.height)

				if currentParent then
					currentParent:removeChild(containerWindow)
				end

				panel:addChild(containerWindow)
				containerWindow:show()

				if SidebarLayoutState and SidebarLayoutState.noteWidgetPlacement then
					SidebarLayoutState.noteWidgetPlacement(containerWindow)
				end
			end
		end

		toggleContainerPages(containerWindow, container)
		applyContainerContextLayout(containerWindow)
	end

	local capacity = container:getCapacity()
	local firstBatchSize = math.min(capacity, CONTAINER_SLOT_BATCH_SIZE)

	for slot = 0, firstBatchSize - 1 do
		createContainerSlotWidget(containerPanel, container, slot)
	end

	finishContainerOpen()

	if firstBatchSize < capacity then
		local slot = firstBatchSize

		local function createNextBatch()
			if isOpenStale() then
				abortStaleOpen()

				return
			end

			if not container.itemsPanel or container.itemsPanel:isDestroyed() then
				return
			end

			local batchLayout = container.itemsPanel:getLayout()

			if batchLayout then
				batchLayout:disableUpdates()
			end

			local endSlot = math.min(slot + CONTAINER_SLOT_BATCH_SIZE - 1, capacity - 1)

			for s = slot, endSlot do
				createContainerSlotWidget(containerPanel, container, s)
			end

			slot = endSlot + 1

			if batchLayout then
				batchLayout:enableUpdates()
				batchLayout:update()
			end

			if slot < capacity then
				addEvent(createNextBatch)
			end
		end

		addEvent(createNextBatch)
	end
end

function onContainerClose(container)
	local windowId = container.window and container.window:getId()

	destroy(container)

	if windowId and not savingContainerLayoutsOnLogout then
		clearContainerLayoutForId(windowId)
	end
end

function onContainerChangeSize(container, size)
	if not container.window then
		return
	end

	local preservedHeight = container.window.preservedHeight

	refreshContainerItems(container)

	if preservedHeight then
		container.window:setHeight(preservedHeight)

		container.window.preservedHeight = nil
	end
end

function onContainerUpdateItem(container, slot, item, oldItem)
	if not container.window then
		return
	end

	local slotWidget = container.itemsPanel:getChildById("item" .. slot)

	applyContainerSlotVisuals(slotWidget, item)
	bindContainerSlotPosition(slotWidget, container:getSlotPosition(slot))

	if isStoreInboxContainer(container) then
		applyContainerHeaderButtonLayout(container.window, container)
	end
end
