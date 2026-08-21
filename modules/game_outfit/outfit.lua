-- chunkname: @/game_outfit/outfit.lua
local setStoreAppearanceNameRowPressNudge -- forward declaration (used before its declaration in the decompiled file)

local statesOutft = {
	goldenOutfitTooltip = 2,
	store = 1,
	available = 0
}
local pendingCyclopediaFocus, activeCyclopediaPending
local cyclopediaViewMode = false
local restoreCyclopediaOnClose = false
local CYClOPEDIA_VIEW_TITLES = {
	familiars = "View Familiars",
	mounts = "View Mounts",
	outfits = "View Outfits"
}
local window, podiumContext, hirelingContext, appearanceGroup, colorModeGroup, colorBoxGroup, floor, movementCheck, showFloorCheck, showOutfitCheck, showFamiliarCheck, podiumPlatformCheck, podiumOutfitCheck
local showPlatformBeforeOutfitOff = true
local PODIUM_OPTION_ENABLED_COLOR = "#c0c0c0"
local PODIUM_OPTION_DISABLED_COLOR = "#707070"
local colorBoxes = {}
local currentColorBox, previewCreature, previewFamiliar, previewRow, previewPodiumWidget, previewPodiumItem
local podiumPreviewInitialized = false

previewMovementWarmup = {
	token = 0,
	retryMs = 16
}

local pendingRenamePresetId

ignoreNextOutfitWindow = 0

local floorTileWidth = 318
local floorTileHeight = 128
local floorTileColumns = 3
local floorTileRows = 3
local floorOffsetX = 0
local floorOffsetY = 0
local floorEventRunning = false
local floorRowWidgets = {}

local function getSelectionListGrid()
	if not window or not window.selectionList then
		return nil
	end

	local grid = window.selectionList.selectionListGrid

	if not grid or grid:isDestroyed() then
		return window.selectionList
	end

	return grid
end

local function getSelectionListFocusedChild()
	local grid = getSelectionListGrid()

	return grid and grid:getFocusedChild() or nil
end

local function setSelectionListFocusHandler(handler)
	if window and window.selectionList then
		window.selectionList.onChildFocusChange = nil
	end

	local grid = getSelectionListGrid()

	if grid then
		grid.onChildFocusChange = handler
	end
end

local function clearSelectionListFocus()
	local grid = getSelectionListGrid()

	if grid and grid.focusChild then
		grid:focusChild(nil)
	end
end

local function resetSelectionListScrollPosition()
	if not window or not window.selectionList then
		return
	end

	local panel = window.selectionList

	if panel.getVirtualOffset and panel.setVirtualOffset then
		local offset = panel:getVirtualOffset() or {
			y = 0,
			x = 0
		}

		offset.x = 0
		offset.y = 0

		panel:setVirtualOffset(offset)
	end

	if window.selectionScroll then
		window.selectionScroll:setValue(window.selectionScroll:getMinimum())
	end
end

local SELECTION_BUTTON_BATCH_SIZE = 20
local SELECTION_BUTTON_CHUNKED_THRESHOLD = 20
local selectionListBuildToken = 0
local selectionHydrationEvent
local SELECTION_CARD_HEIGHT = 102
local SELECTION_CARD_WIDTH = 108
local SELECTION_CARD_SPACING = 2
local SELECTION_HYDRATION_BUFFER_ROWS = 2
local SELECTION_HYDRATION_BATCH_SIZE = 8
local SELECTION_HYDRATION_MAX_ITEMS = 24
local OUTFIT_CLOSE_DESTROY_BATCH_SIZE = 12
local OUTFIT_CLOSE_CLEANUP_INTERVAL_MS = 16
local OUTFIT_CLOSE_LUA_GC_STEP_SIZE = 256
local isSelectionListBuildStale, selectionWarmupEvent
local selectionTextureCache = {
	hydrationToken = 0,
	hydratedButtons = {}
}
local outfitLuaGcEvent
local outfitLuaGcPassesRemaining = 0
local memoryScenarioSelectionSequence = 0

local function traceMemoryScenario(eventName, details)
	if not g_logger or not g_logger.info then
		return
	end

	local timestamp = g_clock and g_clock.realMillis and g_clock.realMillis() or 0

	g_logger.info(string.format("[memory-scenario] t=%d event=%s%s", timestamp, tostring(eventName), details and " " .. details or ""))
end

local function clearSelectionHydrationEvent()
	selectionTextureCache.hydrationToken = selectionTextureCache.hydrationToken + 1

	if selectionHydrationEvent then
		removeEvent(selectionHydrationEvent)

		selectionHydrationEvent = nil
	end
end

local function clearSelectionWarmupEvent()
	if selectionWarmupEvent then
		removeEvent(selectionWarmupEvent)

		selectionWarmupEvent = nil
	end
end

function clearPreviewMovementReadyEvent()
	previewMovementWarmup.token = previewMovementWarmup.token + 1

	if previewMovementWarmup.event then
		removeEvent(previewMovementWarmup.event)

		previewMovementWarmup.event = nil
	end
end

function selectionTextureCache.getButtonKey(button)
	return button and tostring(button:getId()) or ""
end

local function requestIncrementalOutfitGarbageCollection()
	outfitLuaGcPassesRemaining = math.max(outfitLuaGcPassesRemaining, 2)

	if outfitLuaGcEvent then
		return
	end

	local function collectNextStep()
		outfitLuaGcEvent = nil

		if collectgarbage("step", OUTFIT_CLOSE_LUA_GC_STEP_SIZE) then
			outfitLuaGcPassesRemaining = outfitLuaGcPassesRemaining - 1
		end

		if outfitLuaGcPassesRemaining > 0 then
			outfitLuaGcEvent = scheduleEvent(collectNextStep, OUTFIT_CLOSE_CLEANUP_INTERVAL_MS)
		end
	end

	outfitLuaGcEvent = scheduleEvent(collectNextStep, OUTFIT_CLOSE_CLEANUP_INTERVAL_MS)
end

local function appendDeferredDestroyChildren(children, container)
	if not container or container:isDestroyed() then
		return
	end

	local layout = container:getLayout()

	if layout then
		layout:disableUpdates()
	end

	for _, child in ipairs(container:getChildren()) do
		table.insert(children, child)
	end
end

local function destroyOutfitWindowIncrementally(win)
	if not win or win:isDestroyed() then
		requestIncrementalOutfitGarbageCollection()

		return
	end

	local children = {}
	local selectionList = win.selectionList
	local selectionGrid = selectionList and selectionList.selectionListGrid or selectionList
	local colorSection = win.appearance and win.appearance.colorSection
	local colorBackground = colorSection and colorSection.colorBoxBackground

	appendDeferredDestroyChildren(children, selectionGrid)
	appendDeferredDestroyChildren(children, colorBackground and colorBackground.colorBoxPanel)
	appendDeferredDestroyChildren(children, win.presetsList)

	local childIndex = 1
	local childCount = #children

	local function destroyNextBatch()
		if win:isDestroyed() then
			requestIncrementalOutfitGarbageCollection()

			return
		end

		local batchEnd = math.min(childIndex + OUTFIT_CLOSE_DESTROY_BATCH_SIZE - 1, childCount)

		for index = childIndex, batchEnd do
			local child = children[index]

			children[index] = nil

			if child and not child:isDestroyed() then
				child:destroy()
			end
		end

		childIndex = batchEnd + 1

		if childIndex <= childCount then
			scheduleEvent(destroyNextBatch, OUTFIT_CLOSE_CLEANUP_INTERVAL_MS)

			return
		end

		win:destroy()
		requestIncrementalOutfitGarbageCollection()
	end

	scheduleEvent(destroyNextBatch, OUTFIT_CLOSE_CLEANUP_INTERVAL_MS)
end

local function markSelectionButtonDeferred(button, outfitPayload)
	if not button then
		return
	end

	button.__selectionOutfitPayload = outfitPayload
	button.__selectionOutfitHydrated = false
	button.__selectionSheetsRequested = false
	button.__selectionTextureRequested = false
	selectionTextureCache.hydratedButtons[selectionTextureCache.getButtonKey(button)] = nil

	if button.outfit then
		button.outfit:setCreature(nil)
		button.outfit:setVisible(false)
	end
end

local function requestSelectionSpriteSheets(button, payload)
	if not button or button:isDestroyed() then
		return nil
	end

	local lookType = payload and payload.type or 0

	if lookType <= 0 then
		return nil
	end

	local thingType = g_things.getThingType(lookType, ThingCategoryCreature)

	if not thingType then
		return nil
	end

	if not button.__selectionSheetsRequested then
		thingType:prefetchSpriteSheetsForPreview(0)

		button.__selectionSheetsRequested = true
	end

	return thingType
end

local function requestVisibleSelectionTexture(button, payload)
	if not button or button:isDestroyed() or button.__selectionTextureRequested then
		return
	end

	local thingType = requestSelectionSpriteSheets(button, payload)

	if not thingType then
		return
	end

	thingType:prefetchTexturePhase(0)

	button.__selectionTextureRequested = true
end

local function hydrateSelectionButton(button)
	if not button or button:isDestroyed() then
		return false
	end

	local payload = button.__selectionOutfitPayload

	if not payload or not button.outfit then
		return false
	end

	if button.__selectionOutfitHydrated then
		button.outfit:setVisible(true)
		requestVisibleSelectionTexture(button, payload)

		return false
	end

	button.outfit:setOutfit(payload)

	local creature = button.outfit:getCreature()

	if creature then
		creature:setAnimate(false)
	end

	requestSelectionSpriteSheets(button, payload)
	requestVisibleSelectionTexture(button, payload)

	button.__selectionOutfitHydrated = true
	selectionTextureCache.hydratedButtons[selectionTextureCache.getButtonKey(button)] = button

	button.outfit:setVisible(true)

	return true
end

function selectionTextureCache.dehydrateButton(button)
	if not button or not button.__selectionOutfitHydrated then
		return false
	end

	if not button:isDestroyed() and button.outfit then
		button.outfit:setVisible(false)
		button.outfit:setCreature(nil)
	end

	button.__selectionOutfitHydrated = false
	button.__selectionSheetsRequested = false
	button.__selectionTextureRequested = false
	selectionTextureCache.hydratedButtons[selectionTextureCache.getButtonKey(button)] = nil

	return true
end

function selectionTextureCache.releaseHydration()
	local hydrated = {}

	for _, button in pairs(selectionTextureCache.hydratedButtons) do
		table.insert(hydrated, button)
	end

	for _, button in ipairs(hydrated) do
		selectionTextureCache.dehydrateButton(button)
	end

	selectionTextureCache.hydratedButtons = {}
end

local function getSelectionHydrationWindow(totalCount, bufferRows)
	local panel = window and window.selectionList
	local grid = getSelectionListGrid()

	if not panel or not grid or totalCount <= 0 then
		return 1, 0
	end

	local viewportHeight = panel:getHeight() - panel:getPaddingTop() - panel:getPaddingBottom()

	if viewportHeight <= 0 then
		viewportHeight = panel:getHeight()
	end

	local gridWidth = grid:getWidth() - grid:getPaddingLeft() - grid:getPaddingRight()

	if gridWidth <= 0 then
		gridWidth = grid:getWidth()
	end

	local columns = math.max(1, math.floor((gridWidth + SELECTION_CARD_SPACING) / (SELECTION_CARD_WIDTH + SELECTION_CARD_SPACING)))
	local scrollY = 0

	if window and window.selectionScroll then
		scrollY = window.selectionScroll:getValue()
	end

	bufferRows = bufferRows == nil and SELECTION_HYDRATION_BUFFER_ROWS or bufferRows

	local firstVisibleRow = math.max(0, math.floor(scrollY / SELECTION_CARD_HEIGHT))
	local startRow = math.max(0, firstVisibleRow - bufferRows)
	local visibleRows = math.max(1, math.ceil(viewportHeight / SELECTION_CARD_HEIGHT))
	local endRow = firstVisibleRow + visibleRows + bufferRows
	local startIndex = startRow * columns + 1
	local endIndex = math.min(totalCount, (endRow + 1) * columns)

	if startIndex <= endIndex then
		endIndex = math.min(endIndex, startIndex + SELECTION_HYDRATION_MAX_ITEMS - 1)
	end

	return startIndex, endIndex
end

local function scheduleSelectionListHydration(reason)
	clearSelectionHydrationEvent()

	local buildToken = selectionListBuildToken
	local hydrationToken = selectionTextureCache.hydrationToken

	local function updateHydration()
		selectionHydrationEvent = nil

		if isSelectionListBuildStale(buildToken) or hydrationToken ~= selectionTextureCache.hydrationToken then
			return
		end

		local grid = getSelectionListGrid()

		if not grid then
			return
		end

		local children = grid:getChildren()
		local visibleChildren = {}

		for _, child in ipairs(children) do
			if child:isVisible() then
				table.insert(visibleChildren, child)
			end
		end

		local totalCount = #visibleChildren

		if totalCount == 0 then
			selectionTextureCache.releaseHydration()

			return
		end

		local startIndex, endIndex = getSelectionHydrationWindow(totalCount)
		local visibleStartIndex, visibleEndIndex = getSelectionHydrationWindow(totalCount, 0)
		local desired = {}
		local focusedChild = getSelectionListFocusedChild()

		if focusedChild and focusedChild:isVisible() then
			desired[selectionTextureCache.getButtonKey(focusedChild)] = true
		end

		for index = visibleStartIndex, visibleEndIndex do
			local child = visibleChildren[index]

			if child then
				desired[selectionTextureCache.getButtonKey(child)] = true
			end
		end

		for index = visibleStartIndex, visibleEndIndex do
			hydrateSelectionButton(visibleChildren[index])
		end

		local staleButtons = {}

		for key, button in pairs(selectionTextureCache.hydratedButtons) do
			if not desired[key] then
				table.insert(staleButtons, button)
			end
		end

		for _, button in ipairs(staleButtons) do
			selectionTextureCache.dehydrateButton(button)
		end

		local pending = {}

		focusedChild = getSelectionListFocusedChild()

		local focusedKey = selectionTextureCache.getButtonKey(focusedChild)

		if focusedChild and desired[focusedKey] and not focusedChild.__selectionOutfitHydrated then
			table.insert(pending, focusedChild)
		end

		for index = startIndex, endIndex do
			local child = visibleChildren[index]

			if child and selectionTextureCache.getButtonKey(child) ~= focusedKey and not child.__selectionOutfitHydrated then
				table.insert(pending, child)
			end
		end

		if #pending == 0 then
			return
		end

		local pendingIndex = 1

		local function hydrateBatch()
			if isSelectionListBuildStale(buildToken) or hydrationToken ~= selectionTextureCache.hydrationToken then
				return
			end

			local batchEnd = math.min(pendingIndex + SELECTION_HYDRATION_BATCH_SIZE - 1, #pending)

			for i = pendingIndex, batchEnd do
				local button = pending[i]

				requestSelectionSpriteSheets(button, button and button.__selectionOutfitPayload)
			end

			pendingIndex = batchEnd + 1

			if pendingIndex <= #pending then
				addEvent(hydrateBatch)

				return
			end
		end

		hydrateBatch()
	end

	if reason == "scroll" then
		updateHydration()
	else
		selectionHydrationEvent = scheduleEvent(updateHydration, 16)
	end
end

local function startSelectionWarmupPump(context)
	clearSelectionWarmupEvent()
end

local function makeThumbnailStatic(uiCreature)
	local creature = uiCreature and uiCreature:getCreature()

	if creature then
		creature:setAnimate(false)
	end
end

local function beginSelectionListBuild()
	selectionListBuildToken = selectionListBuildToken + 1

	return selectionListBuildToken
end

function isSelectionListBuildStale(buildToken)
	return not window or not window.selectionList or buildToken ~= selectionListBuildToken
end

local function buildSelectionListBatched(items, buildItem, onComplete)
	local panel = getSelectionListGrid()
	local layout = panel:getLayout()

	if layout then
		layout:disableUpdates()
	end

	local buildToken = selectionListBuildToken

	local function finish()
		if isSelectionListBuildStale(buildToken) then
			if layout then
				layout:enableUpdates()
			end

			return
		end

		if layout then
			layout:enableUpdates()

			if layout.update then
				layout:update()
			end
		end

		if onComplete then
			onComplete()
		end
	end

	local count = #items

	if count <= SELECTION_BUTTON_CHUNKED_THRESHOLD then
		for index, item in ipairs(items) do
			buildItem(item, index)
		end

		finish()

		return
	end

	local index = 1

	local function createNextBatch()
		if isSelectionListBuildStale(buildToken) then
			if layout then
				layout:enableUpdates()
			end

			return
		end

		local endIndex = math.min(index + SELECTION_BUTTON_BATCH_SIZE - 1, count)

		for i = index, endIndex do
			buildItem(items[i], i)
		end

		index = endIndex + 1

		if index <= count then
			addEvent(createNextBatch)
		else
			finish()
		end
	end

	createNextBatch()
end

local function applyFloorRowScrollMargins()
	if not floorRowWidgets or #floorRowWidgets == 0 then
		return
	end

	for index, tile in ipairs(floorRowWidgets) do
		local row = math.floor((index - 1) / floorTileColumns) + 1
		local col = (index - 1) % floorTileColumns + 1

		tile:setMarginTop((row - 1) * floorTileHeight - floorOffsetY)
		tile:setMarginLeft((col - 1) * floorTileWidth - floorOffsetX)
	end
end

local function resetFloorScrollOffsets()
	floorOffsetX = 0
	floorOffsetY = 0

	applyFloorRowScrollMargins()
end

local settingsFile = "/settings/outfit.json"
local settings = {}
local movementEnabledForSession = false
local outfitWindowDefaultWidth = 756
local outfitWindowDefaultHeight = 537
local outfitWindowDefaultMarginTop = 43
local outfitWindowCompactMarginTop = 32
local configurePanelDefaultHeight = 234
local appearancePanelDefaultHeight = 234
local appearanceSettingsDefaultHeight = 86
local missingFamiliarCompactionHeight = 22
local missingPresetCompactionHeight = 22
local hirelingWindowHeight = 471
local hirelingAppearanceCompactionHeight = 44
local defaultButtonImage = "/images/ui/1pixel-down-frame"
local storeButtonImage = "/images/ui/outfits/button_store_mount"
local storeButtonClipNormal = "0 0 230 20"
local storeButtonClipPressed = "0 20 230 20"
local storeButtonIcon = "/images/icons/icon-store-16x10"
local appearanceNameTextOffsetY = 1
local appearanceNameStoreRowTextExtraY = 3
local storeNameRowIconGap = 4
local storeNameRowIconFallbackW = 12
local storeNameRowPressNudge = 1
local storeNameRowLayoutBase = {}
local storeNameRowPressed = {}

local function appearanceNameRowUsesStoreChrome(widget)
	if not widget or widget:isDestroyed() then
		return false
	end

	local src = widget:getImageSource() or ""

	if src == storeButtonImage then
		return true
	end

	return string.find(src, "button_store_mount", 1, true) ~= nil
end

local function storeNameRowLayoutBaseKey(widget)
	if not widget or widget:isDestroyed() then
		return ""
	end

	local parent = widget:getParent()

	if not parent or parent:isDestroyed() then
		return "noparent/" .. (widget:getId() or "name")
	end

	return parent:getId() .. "/" .. (widget:getId() or "name")
end

local function resetAppearanceNameRowStoreLayout(widget)
	if not widget or widget:isDestroyed() then
		return
	end

	local key = storeNameRowLayoutBaseKey(widget)

	storeNameRowLayoutBase[key] = nil
	storeNameRowPressed[key] = nil

	widget:setIconAlign(AlignNone)
	widget:setIconOffset(topoint("0 0"))
	widget:setTextAlign(AlignCenter)
	widget:setTextOffset(topoint("0 " .. appearanceNameTextOffsetY))
end

local function layoutStoreAppearanceNameRowCentered(widget)
	if not widget or widget:isDestroyed() then
		return
	end

	if not appearanceNameRowUsesStoreChrome(widget) then
		return
	end

	local clip = widget:getIconClip()
	local iconW = clip and clip.width or 0

	if iconW <= 0 then
		iconW = storeNameRowIconFallbackW
	end

	local textW = widget:getTextSize().width
	local total = iconW + storeNameRowIconGap + textW
	local w = widget:getWidth()
	local groupX = math.max(0, math.floor((w - total) / 2))

	widget:setIconAlign(AlignLeftCenter)
	widget:setIconOffset(topoint(groupX .. " 0"))
	widget:setTextAlign(AlignLeft)

	local textY = appearanceNameTextOffsetY + appearanceNameStoreRowTextExtraY
	local textX = groupX + iconW + storeNameRowIconGap

	widget:setTextOffset(topoint(textX .. " " .. textY))

	local key = storeNameRowLayoutBaseKey(widget)

	storeNameRowLayoutBase[key] = {
		iconY = 0,
		iconX = groupX,
		textX = textX,
		textY = textY
	}

	if storeNameRowPressed[key] then
		setStoreAppearanceNameRowPressNudge(widget, true)
	end
end

setStoreAppearanceNameRowPressNudge = function(widget, pressed)
	if not widget or widget:isDestroyed() then
		return
	end

	local key = storeNameRowLayoutBaseKey(widget)

	if key == "" then
		return
	end

	if not pressed then
		storeNameRowPressed[key] = false
	end

	local b = storeNameRowLayoutBase[key]

	if not b then
		layoutStoreAppearanceNameRowCentered(widget)

		b = storeNameRowLayoutBase[key]
	end

	if not b then
		return
	end

	if pressed then
		storeNameRowPressed[key] = true
	end

	local d = pressed and storeNameRowPressNudge or 0

	widget:setIconOffset(topoint(b.iconX + d .. " " .. b.iconY + d))
	widget:setTextOffset(topoint(b.textX + d .. " " .. b.textY + d))
end

local function scheduleStoreAppearanceNameRowReleaseSnap(widget)
	addEvent(function()
		if not widget or widget:isDestroyed() then
			return
		end

		if not appearanceNameRowUsesStoreChrome(widget) then
			return
		end

		local key = storeNameRowLayoutBaseKey(widget)

		if key == "" or storeNameRowPressed[key] then
			return
		end

		local b = storeNameRowLayoutBase[key]

		if not b then
			return
		end

		widget:setIconOffset(topoint(b.iconX .. " " .. b.iconY))
		widget:setTextOffset(topoint(b.textX .. " " .. b.textY))
	end)
end

local function scheduleLayoutStoreAppearanceNameRow(widget)
	addEvent(function()
		if not widget or widget:isDestroyed() or not appearanceNameRowUsesStoreChrome(widget) then
			return
		end

		layoutStoreAppearanceNameRowCentered(widget)
	end)
end

local outfitColorCache = {
	body = 0,
	head = 0,
	feet = 0,
	legs = 0
}
local mountColorCache = {
	body = 0,
	head = 0,
	feet = 0,
	legs = 0
}
local familiarColorCache = {
	body = 0,
	head = 0,
	feet = 0,
	legs = 0
}
local colorPickerProgrammatic = false

local function applyOutfitPreviewSpriteScale(spriteWidget)
	if not spriteWidget then
		return
	end

	local creature = spriteWidget:getCreature()

	if not creature then
		return
	end

	spriteWidget:setCenter(false)
	spriteWidget:setFixedCreatureSize(false)
	spriteWidget:setCreatureSize(100)
	spriteWidget:setBaseScale(true)
end

local function setupPodiumPreviewWidget()
	if not previewRow then
		return false
	end

	previewPodiumWidget = previewRow:recursiveGetChildById("podiumPreview")

	if not previewPodiumWidget then
		return false
	end

	previewPodiumWidget:setVirtual(true)
	previewPodiumWidget:setPodiumPreview(true)
	previewPodiumWidget:setFixedItemSize(false)
	previewPodiumWidget:setSize("70 70")
	previewPodiumWidget:setItemVisible(false)

	podiumPreviewInitialized = true

	return true
end

local function getPodiumSourceThing(position, itemClientId)
	if modules.game_customisepodium and modules.game_customisepodium.currentThing then
		local thing = modules.game_customisepodium.currentThing

		if thing and thing.isPodium and thing:isPodium() then
			return thing
		end
	end

	if position then
		local tile = g_map.getTile(position)

		if tile then
			local thing = tile:getTopUseThing()

			if thing and thing.isPodium and thing:isPodium() then
				return thing
			end
		end
	end

	if itemClientId and itemClientId > 0 then
		return Item.create(itemClientId)
	end

	return nil
end

local function buildPodiumPreviewItem(thing, itemClientId)
	if thing and thing.isItem and thing:isItem() and thing.clone then
		return thing:clone()
	end

	if itemClientId and itemClientId > 0 then
		return Item.create(itemClientId)
	end

	return nil
end

local function restoreNormalPreviewCreatureLayout()
	if not previewCreature then
		return
	end

	previewCreature:breakAnchors()
	previewCreature:addAnchor(AnchorLeft, "parent", AnchorLeft)
	previewCreature:addAnchor(AnchorVerticalCenter, "parent", AnchorVerticalCenter)
	previewCreature:setMarginLeft(0)
	previewCreature:setMarginTop(0)

	if previewRow and previewRow.updateLayout then
		previewRow:updateLayout()
	end
end

local function getPodiumPlatformElevation(item)
	if not item or not item.getId then
		return 0
	end

	local thingType = g_things.getThingType(item:getId(), ThingCategoryItem)

	if thingType and thingType.hasElevation and thingType:hasElevation() then
		return thingType:getElevation()
	end

	return 0
end

local function getPodiumShowOutfit()
	if podiumOutfitCheck then
		return podiumOutfitCheck:isChecked()
	end

	return settings.showOutfit ~= false
end

local function getPodiumShowMount()
	if not g_game.getFeature(GamePlayerMounts) then
		return false
	end

	if not window or not window.configure or not window.configure.mount or not window.configure.mount.check then
		return false
	end

	return window.configure.mount.check:isChecked()
end

local function getPodiumShowPlatform()
	if podiumPlatformCheck then
		return podiumPlatformCheck:isChecked()
	end

	if podiumContext then
		return podiumContext.showPlatform ~= false
	end

	return true
end

local function layoutPreviewCreatureForPodium(showPlatform, item)
	if not previewCreature then
		return
	end

	previewCreature:breakAnchors()
	previewCreature:addAnchor(AnchorHorizontalCenter, "parent", AnchorHorizontalCenter)
	previewCreature:addAnchor(AnchorVerticalCenter, "parent", AnchorVerticalCenter)

	if showPlatform then
		local elevation = getPodiumPlatformElevation(item or previewPodiumItem)
		local previewOffset = elevation > 0 and elevation * 2 or 12

		previewCreature:setMarginLeft(-previewOffset)
		previewCreature:setMarginTop(-previewOffset)
	else
		previewCreature:setMarginLeft(0)
		previewCreature:setMarginTop(0)
	end

	if previewRow and previewRow.updateLayout then
		previewRow:updateLayout()
	end
end

local function updatePodiumPreview()
	if not podiumContext or not podiumPreviewInitialized or not previewPodiumWidget then
		return
	end

	if not previewPodiumItem then
		previewPodiumItem = buildPodiumPreviewItem(podiumContext.sourceThing, podiumContext.itemClientId)
	end

	if not previewPodiumItem then
		previewPodiumWidget:setItemVisible(false)
		layoutPreviewCreatureForPodium(false, previewPodiumItem)

		return
	end

	local showPodium = podiumPlatformCheck and podiumPlatformCheck:isChecked()

	if showPodium == nil then
		showPodium = podiumContext.showPlatform ~= false
	end

	local direction = Directions.South

	if previewCreature and previewCreature:getCreature() then
		direction = previewCreature:getDirection()
	elseif podiumContext.direction then
		direction = podiumContext.direction
	end

	previewPodiumItem:setPodium({}, direction, showPodium, false)
	previewPodiumWidget:setItem(previewPodiumItem)
	previewPodiumWidget:setItemVisible(showPodium)
	layoutPreviewCreatureForPodium(showPodium, previewPodiumItem)
end

local function syncPreviewWalkingState()
	local walkingSpeed = not podiumContext and not hirelingContext and settings.movement and 1000 or 0
	local mainCreature = previewCreature and previewCreature:getCreature()

	if mainCreature then
		mainCreature:setStaticWalking(walkingSpeed)
	end

	if g_game.getFeature(GamePlayerFamiliars) then
		local familiarCreature = previewFamiliar and previewFamiliar:getCreature()

		if familiarCreature then
			familiarCreature:setStaticWalking(walkingSpeed)
		end
	end
end

local tempOutfit = {}
local didAcceptCustomize = false
local clipboardChangeWatchEvent
local lastClipboardChangeCount = 0
local ServerData = {
	currentOutfit = {},
	outfits = {},
	mounts = {},
	familiars = {}
}

local function getPreferredInitialMountId(mounts)
	if table.empty(mounts) then
		return 0
	end

	for _, mountData in ipairs(mounts) do
		local state = mountData[3]

		if state == nil or state == statesOutft.available then
			return mountData[1]
		end
	end

	return mounts[1][1]
end

local function isPodiumMountShown()
	if not podiumContext or not tempOutfit then
		return false
	end

	return getPodiumShowMount() and (tempOutfit.mount or 0) > 0
end

local function podiumCreatureWouldDisplay()
	if not podiumContext then
		return false
	end

	return getPodiumShowOutfit() or isPodiumMountShown()
end

local function getEffectivePodiumShowPlatform()
	if not podiumCreatureWouldDisplay() then
		return true
	end

	return getPodiumShowPlatform()
end

local function syncShowPodiumOptionState()
	if not podiumContext or not podiumPlatformCheck then
		return
	end

	if podiumCreatureWouldDisplay() then
		podiumPlatformCheck:setEnabled(true)
		podiumPlatformCheck:setColor(PODIUM_OPTION_ENABLED_COLOR)

		local checked = podiumContext.showPlatform ~= false

		podiumPlatformCheck:setChecked(checked)

		podiumContext.showPlatform = checked

		return
	end

	podiumContext.showPlatform = true

	podiumPlatformCheck:setChecked(true)
	podiumPlatformCheck:setEnabled(false)
	podiumPlatformCheck:setColor(PODIUM_OPTION_DISABLED_COLOR)
end

local function ensurePodiumMountSelection()
	if not podiumContext or not tempOutfit or not getPodiumShowMount() then
		return
	end

	if (tempOutfit.mount or 0) > 0 or table.empty(ServerData.mounts) then
		return
	end

	tempOutfit.mount = getPreferredInitialMountId(ServerData.mounts)
end

local function getMountStateById(mountId)
	if not mountId or mountId < 1 or table.empty(ServerData.mounts) then
		return nil
	end

	for _, mountData in ipairs(ServerData.mounts) do
		if mountData[1] == mountId then
			return mountData[3]
		end
	end

	return nil
end

local function getMountOfferIdById(mountId)
	if not mountId or mountId < 1 or table.empty(ServerData.mounts) then
		return 0
	end

	for _, mountData in ipairs(ServerData.mounts) do
		if mountData[1] == mountId then
			return mountData[4] or 0
		end
	end

	return 0
end

local function getOutfitStateById(outfitId)
	if not outfitId or outfitId < 1 or table.empty(ServerData.outfits) then
		return nil
	end

	for _, outfitData in ipairs(ServerData.outfits) do
		if outfitData[1] == outfitId then
			return outfitData[4]
		end
	end

	return nil
end

local function getOutfitOfferIdById(outfitId)
	if not outfitId or outfitId < 1 or table.empty(ServerData.outfits) then
		return 0
	end

	for _, outfitData in ipairs(ServerData.outfits) do
		if outfitData[1] == outfitId then
			return outfitData[5] or 0
		end
	end

	return 0
end

function getOutfitNameByLookType(lookType)
	if not lookType or lookType < 1 or table.empty(ServerData.outfits) then
		return nil
	end

	for _, outfitData in ipairs(ServerData.outfits) do
		if outfitData[1] == lookType then
			return outfitData[2]
		end
	end

	return nil
end

local function redirectToStoreOffer(offerId)
	if offerId <= 0 then
		return
	end

	if window then
		destroy()
	end

	if modules and modules.game_store and modules.game_store.openOfferById then
		modules.game_store.openOfferById(offerId)

		return
	end

	g_game.openStore()
	addEvent(function()
		g_game.sendRequestStoreOfferById(offerId)
	end, 250)
end

function onOutfitNameClick()
	local outfitId = tempOutfit and tempOutfit.type or 0
	local state = getOutfitStateById(outfitId)
	local offerId = getOutfitOfferIdById(outfitId)

	if state and state ~= statesOutft.available and offerId > 0 then
		redirectToStoreOffer(offerId)
	end
end

function onMountNameClick()
	local mountId = tempOutfit and tempOutfit.mount or 0
	local state = getMountStateById(mountId)
	local offerId = getMountOfferIdById(mountId)

	if state and state ~= statesOutft.available and offerId > 0 then
		redirectToStoreOffer(offerId)
	end
end

local function onMountNameMousePress(widget, mousePos, mouseButton)
	if mouseButton ~= MouseLeftButton then
		return false
	end

	widget:setImageClip(storeButtonClipPressed)
	setStoreAppearanceNameRowPressNudge(widget, true)

	return true
end

local function onMountNameMouseRelease(widget, mousePos, mouseButton)
	if mouseButton ~= MouseLeftButton then
		return false
	end

	widget:setImageClip(storeButtonClipNormal)
	setStoreAppearanceNameRowPressNudge(widget, false)
	scheduleStoreAppearanceNameRowReleaseSnap(widget)

	if widget:containsPoint(mousePos) then
		onMountNameClick()
	end

	return true
end

local function updateMountAppearanceNameVisual(mountId)
	if not window or not window.appearance or not window.appearance.settings or not window.appearance.settings.mount or not window.appearance.settings.mount.name then
		return
	end

	local mountNameWidget = window.appearance.settings.mount.name
	local state = getMountStateById(mountId)
	local offerId = getMountOfferIdById(mountId)
	local isStoreMount = state ~= nil and state ~= statesOutft.available and offerId > 0

	if isStoreMount then
		mountNameWidget:setImageSource(storeButtonImage)
		mountNameWidget:setImageClip(storeButtonClipNormal)
		mountNameWidget:setIcon(storeButtonIcon)
		mountNameWidget:setTooltip("Open store offer")
		mountNameWidget:setPhantom(false)
		mountNameWidget:setFocusable(true)

		mountNameWidget.onMousePress = onMountNameMousePress
		mountNameWidget.onMouseRelease = onMountNameMouseRelease

		layoutStoreAppearanceNameRowCentered(mountNameWidget)
		scheduleLayoutStoreAppearanceNameRow(mountNameWidget)
	else
		mountNameWidget:setImageSource(defaultButtonImage)
		mountNameWidget:setImageClip(nil)
		mountNameWidget:setIcon("")
		resetAppearanceNameRowStoreLayout(mountNameWidget)
		mountNameWidget:setTooltip("")
		mountNameWidget:setPhantom(true)
		mountNameWidget:setFocusable(false)

		mountNameWidget.onMousePress = nil
		mountNameWidget.onMouseRelease = nil
	end
end

local function updateOutfitAppearanceNameVisual(outfitId)
	if not window or not window.appearance or not window.appearance.settings or not window.appearance.settings.outfit or not window.appearance.settings.outfit.name then
		return
	end

	local outfitNameWidget = window.appearance.settings.outfit.name
	local state = getOutfitStateById(outfitId)
	local offerId = getOutfitOfferIdById(outfitId)
	local isStoreOutfit = state ~= nil and state ~= statesOutft.available and offerId > 0

	if isStoreOutfit then
		outfitNameWidget:setImageSource(storeButtonImage)
		outfitNameWidget:setImageClip(storeButtonClipNormal)
		outfitNameWidget:setIcon(storeButtonIcon)
		outfitNameWidget:setTooltip("Open store offer")
		outfitNameWidget:setPhantom(false)
		outfitNameWidget:setFocusable(true)

		function outfitNameWidget.onMousePress(widget, mousePos, mouseButton)
			if mouseButton ~= MouseLeftButton then
				return false
			end

			widget:setImageClip(storeButtonClipPressed)
			setStoreAppearanceNameRowPressNudge(widget, true)

			return true
		end

		function outfitNameWidget.onMouseRelease(widget, mousePos, mouseButton)
			if mouseButton ~= MouseLeftButton then
				return false
			end

			widget:setImageClip(storeButtonClipNormal)
			setStoreAppearanceNameRowPressNudge(widget, false)
			scheduleStoreAppearanceNameRowReleaseSnap(widget)

			if widget:containsPoint(mousePos) then
				onOutfitNameClick()
			end

			return true
		end

		layoutStoreAppearanceNameRowCentered(outfitNameWidget)
		scheduleLayoutStoreAppearanceNameRow(outfitNameWidget)
	else
		outfitNameWidget:setImageSource(defaultButtonImage)
		outfitNameWidget:setImageClip(nil)
		outfitNameWidget:setIcon("")
		resetAppearanceNameRowStoreLayout(outfitNameWidget)
		outfitNameWidget:setTooltip("")
		outfitNameWidget:setPhantom(true)
		outfitNameWidget:setFocusable(false)

		outfitNameWidget.onMousePress = nil
		outfitNameWidget.onMouseRelease = nil
	end
end

local function initColorCachesFromOutfit(outfit)
	if not outfit then
		return
	end

	local h = outfit.head or 0
	local b = outfit.body or 0
	local l = outfit.legs or 0
	local f = outfit.feet or 0

	outfitColorCache = {
		head = h,
		body = b,
		legs = l,
		feet = f
	}

	local mh = outfit.mountHead

	if mh == nil then
		mh = 0
	end

	local mb = outfit.mountBody

	if mb == nil then
		mb = 0
	end

	local ml = outfit.mountLegs

	if ml == nil then
		ml = 0
	end

	local mf = outfit.mountFeet

	if mf == nil then
		mf = 0
	end

	mountColorCache = {
		head = mh,
		body = mb,
		legs = ml,
		feet = mf
	}
	familiarColorCache = {
		head = h,
		body = b,
		legs = l,
		feet = f
	}
end

local function applyGlobalColorCachesFromSettings()
	if settings and (settings.currentPreset or 0) > 0 then
		return
	end

	if settings and settings.outfitColorCache and type(settings.outfitColorCache) == "table" then
		local c = settings.outfitColorCache

		outfitColorCache = {
			head = c.head or 0,
			body = c.body or 0,
			legs = c.legs or 0,
			feet = c.feet or 0
		}
	end

	if g_game.getFeature(GamePlayerMounts) and settings and settings.mountColorCache and type(settings.mountColorCache) == "table" then
		local c = settings.mountColorCache

		mountColorCache = {
			head = c.head or 0,
			body = c.body or 0,
			legs = c.legs or 0,
			feet = c.feet or 0
		}
	end
end

local function getAppearanceCategoryName()
	if not appearanceGroup or not window or not window.appearance or not window.appearance.settings then
		return "outfit"
	end

	local w = appearanceGroup:getSelectedWidget()

	if not w then
		return "outfit"
	end

	local parent = w:getParent()

	if not parent or not parent.getId then
		return "outfit"
	end

	return parent:getId() or "outfit"
end

local function getCreatureThingType(lookId)
	if not lookId or lookId < 1 then
		return nil
	end

	return g_things.getThingType(lookId, ThingCategoryCreature)
end

local function thingTypeHasVariableColors(thingType)
	if not thingType then
		return false
	end

	local ok, layers = pcall(function()
		return thingType:getLayers()
	end)

	return ok and layers and layers >= 2
end

local function headBodyForListThumbnail(lookId, cache)
	if not cache or not lookId or lookId < 1 then
		return 0, 0, 0, 0
	end

	if thingTypeHasVariableColors(getCreatureThingType(lookId)) then
		return cache.head or 0, cache.body or 0, cache.legs or 0, cache.feet or 0
	end

	return 0, 0, 0, 0
end

local function isColorContextActive()
	local app = getAppearanceCategoryName()

	if app == "preset" then
		return false
	end

	if app == "outfit" then
		return thingTypeHasVariableColors(getCreatureThingType(tempOutfit and tempOutfit.type))
	end

	if app == "mount" then
		if not g_game.getFeature(GamePlayerMounts) or not tempOutfit or (tempOutfit.mount or 0) < 1 then
			return false
		end

		return thingTypeHasVariableColors(getCreatureThingType(tempOutfit.mount))
	end

	if app == "familiar" then
		if not g_game.getFeature(GamePlayerFamiliars) or not tempOutfit or (tempOutfit.familiar or 0) < 1 then
			return false
		end

		return thingTypeHasVariableColors(getCreatureThingType(tempOutfit.familiar))
	end

	return false
end

local function getColorCacheForAppearance(app)
	if app == "mount" then
		return mountColorCache
	end

	if app == "familiar" then
		return familiarColorCache
	end

	return outfitColorCache
end

local function getColorIdFromMode(cache, colorMode)
	if not cache or not colorMode then
		return 0
	end

	if colorMode == "head" then
		return cache.head or 0
	elseif colorMode == "primary" then
		return cache.body or 0
	elseif colorMode == "secondary" then
		return cache.legs or 0
	elseif colorMode == "detail" then
		return cache.feet or 0
	end

	return 0
end

local function applyColorIdToMode(cache, colorMode, colorId)
	if not cache or not colorMode then
		return
	end

	if colorMode == "head" then
		cache.head = colorId
	elseif colorMode == "primary" then
		cache.body = colorId
	elseif colorMode == "secondary" then
		cache.legs = colorId
	elseif colorMode == "detail" then
		cache.feet = colorId
	end
end

local function applyOutfitColorsToTemp()
	if not tempOutfit or not outfitColorCache then
		return
	end

	tempOutfit.head = outfitColorCache.head
	tempOutfit.body = outfitColorCache.body
	tempOutfit.legs = outfitColorCache.legs
	tempOutfit.feet = outfitColorCache.feet
end

local function applyMountColorsToOutfitTable(outfitTable)
	if not outfitTable then
		return
	end

	if not g_game.getFeature(GamePlayerMounts) or (outfitTable.mount or 0) < 1 then
		outfitTable.mountHead = 0
		outfitTable.mountBody = 0
		outfitTable.mountLegs = 0
		outfitTable.mountFeet = 0

		return
	end

	if thingTypeHasVariableColors(getCreatureThingType(outfitTable.mount)) then
		outfitTable.mountHead = mountColorCache.head
		outfitTable.mountBody = mountColorCache.body
		outfitTable.mountLegs = mountColorCache.legs
		outfitTable.mountFeet = mountColorCache.feet
	else
		outfitTable.mountHead = 0
		outfitTable.mountBody = 0
		outfitTable.mountLegs = 0
		outfitTable.mountFeet = 0
	end
end

local function syncTempOutfitFromSelection()
	if not window or not window.selectionList or not appearanceGroup then
		return
	end

	local tabId = getAppearanceCategoryName()
	local focusedChild = getSelectionListFocusedChild()

	if not focusedChild or focusedChild:isDestroyed() then
		return
	end

	if tabId == "outfit" then
		local outfitType = tonumber(focusedChild:getId())

		if outfitType then
			tempOutfit.type = outfitType
		end
	elseif tabId == "mount" then
		tempOutfit.mount = tonumber(focusedChild:getId()) or 0
	elseif tabId == "familiar" then
		tempOutfit.familiar = tonumber(focusedChild:getId()) or 0
	end
end

local function buildOutfitPayloadForSend()
	syncTempOutfitFromSelection()
	applyOutfitColorsToTemp()

	local outfitToSend = table.copy(tempOutfit)

	applyMountColorsToOutfitTable(outfitToSend)

	return outfitToSend
end

local function selectFirstColorBoxForDisabledState()
	if not window or not colorBoxGroup then
		return
	end

	local csec = window.appearance and window.appearance.colorSection
	local panel = csec and csec.colorBoxBackground and csec.colorBoxBackground.colorBoxPanel

	if not panel then
		return
	end

	local box0 = panel.colorBox0

	if not box0 then
		return
	end

	colorPickerProgrammatic = true

	colorBoxGroup:selectWidget(box0)

	colorPickerProgrammatic = false
end

local decodeCopyColoursCode, decodeCopyAllCode, refreshColorBoxForCurrentContext, setPasteButtonMode, classifyPasteClipboardCode
local currentPasteMode = "colours"

local function updateColorControlsState()
	if not window or not window.appearance then
		return
	end

	local canColor = isColorContextActive()

	if window.appearance.colorSection and window.appearance.colorSection.colorBoxBackground and window.appearance.colorSection.colorBoxBackground.colorBoxPanel and window.appearance.colorSection.colorBoxBackground.colorBoxPanel.setEnabled then
		window.appearance.colorSection.colorBoxBackground.colorBoxPanel:setEnabled(canColor)
	end

	if window.appearance.colorSection.colorMode then
		for _, c in pairs(window.appearance.colorSection.colorMode:getChildren()) do
			if c.setEnabled then
				c:setEnabled(canColor)
			end
		end
	end

	if window.appearance.colorSection then
		local overlay = window.appearance.colorSection.colorsDisabledOverlay

		if overlay and overlay.setVisible then
			overlay:setVisible(not canColor)
		end
	end

	if window.appearance.colorCopyButtons then
		local copyAllButton = window.appearance.colorCopyButtons.copyAll

		if copyAllButton and copyAllButton.setEnabled then
			copyAllButton:setEnabled(true)
		end

		local copyColoursButton = window.appearance.colorCopyButtons.copyColours

		if copyColoursButton and copyColoursButton.setEnabled then
			copyColoursButton:setEnabled(canColor)
		end

		local pasteColoursButton = window.appearance.colorCopyButtons.pasteColours

		if pasteColoursButton and pasteColoursButton.setEnabled then
			local hasValidClipboard = false
			local pasteMode = currentPasteMode

			if g_window and g_window.getClipboardText then
				local clipboardText = g_window.getClipboardText()
				local detectedMode = classifyPasteClipboardCode(clipboardText, canColor)

				if detectedMode == "all" then
					hasValidClipboard = true
					pasteMode = "all"
				elseif detectedMode == "colours" then
					hasValidClipboard = true
					pasteMode = "colours"
				end
			end

			if hasValidClipboard then
				setPasteButtonMode(pasteMode)
			end

			pasteColoursButton:setEnabled(hasValidClipboard)
		end
	end

	if not canColor then
		selectFirstColorBoxForDisabledState()
	end
end

local function stopClipboardChangeWatcher()
	if clipboardChangeWatchEvent then
		removeEvent(clipboardChangeWatchEvent)

		clipboardChangeWatchEvent = nil
	end
end

local function startClipboardChangeWatcher()
	stopClipboardChangeWatcher()

	if not g_window or not g_window.getClipboardChangeCount or not g_window.getPlatformType or not string.find(g_window.getPlatformType(), "WIN32", 1, true) then
		return
	end

	lastClipboardChangeCount = g_window.getClipboardChangeCount()

	local function watch()
		if not window then
			clipboardChangeWatchEvent = nil

			return
		end

		local currentCount = g_window.getClipboardChangeCount()

		if currentCount ~= lastClipboardChangeCount then
			lastClipboardChangeCount = currentCount

			updateColorControlsState()
		end

		clipboardChangeWatchEvent = scheduleEvent(watch, 80)
	end

	clipboardChangeWatchEvent = scheduleEvent(watch, 80)
end

local function encodeCborUnsigned(value)
	value = math.max(0, math.floor(tonumber(value) or 0))

	if value < 24 then
		return string.char(value)
	end

	if value < 256 then
		return string.char(24, value)
	end

	if value < 65536 then
		local hi = math.floor(value / 256)
		local lo = value % 256

		return string.char(25, hi, lo)
	end

	return string.char(26, math.floor(value / 16777216) % 256, math.floor(value / 65536) % 256, math.floor(value / 256) % 256, value % 256)
end

local function encodeCborText(value)
	value = tostring(value or "")

	local len = #value

	if len < 24 then
		return string.char(96 + len) .. value
	end

	if len < 256 then
		return string.char(120, len) .. value
	end

	return string.char(121, math.floor(len / 256) % 256, len % 256) .. value
end

local function encodeCborBool(value)
	return value and string.char(245) or string.char(244)
end

local function base64Encode(data)
	local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	local out = {}
	local len = #data
	local i = 1

	while i <= len do
		local b1 = data:byte(i) or 0
		local b2 = data:byte(i + 1) or 0
		local b3 = data:byte(i + 2) or 0
		local n = b1 * 65536 + b2 * 256 + b3
		local c1 = math.floor(n / 262144) % 64 + 1
		local c2 = math.floor(n / 4096) % 64 + 1
		local c3 = math.floor(n / 64) % 64 + 1
		local c4 = n % 64 + 1

		out[#out + 1] = chars:sub(c1, c1)
		out[#out + 1] = chars:sub(c2, c2)
		out[#out + 1] = len >= i + 1 and chars:sub(c3, c3) or "="
		out[#out + 1] = len >= i + 2 and chars:sub(c4, c4) or "="
		i = i + 3
	end

	return table.concat(out)
end

local function base64Decode(data)
	local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	local lookup = {}

	for i = 1, #chars do
		lookup[chars:sub(i, i)] = i - 1
	end

	local clean = (data or ""):gsub("%s+", "")

	if clean == "" or clean:find("[^A-Za-z0-9+/=]") then
		return nil
	end

	local rem = #clean % 4

	if rem == 1 then
		return nil
	elseif rem > 1 then
		clean = clean .. string.rep("=", 4 - rem)
	end

	local out = {}
	local i = 1

	while i <= #clean do
		local c1 = clean:sub(i, i)
		local c2 = clean:sub(i + 1, i + 1)
		local c3 = clean:sub(i + 2, i + 2)
		local c4 = clean:sub(i + 3, i + 3)

		if not c1 or not c2 or not c3 or not c4 then
			return nil
		end

		if c1 == "=" or c2 == "=" or c3 == "=" and c4 ~= "=" then
			return nil
		end

		local v1 = lookup[c1]
		local v2 = lookup[c2]
		local v3 = c3 == "=" and 0 or lookup[c3]
		local v4 = c4 == "=" and 0 or lookup[c4]

		if v1 == nil or v2 == nil or v3 == nil or v4 == nil then
			return nil
		end

		local n = v1 * 262144 + v2 * 4096 + v3 * 64 + v4

		out[#out + 1] = string.char(math.floor(n / 65536) % 256)

		if c3 ~= "=" then
			out[#out + 1] = string.char(math.floor(n / 256) % 256)
		end

		if c4 ~= "=" then
			out[#out + 1] = string.char(n % 256)
		end

		i = i + 4
	end

	return table.concat(out)
end

local function readCborUnsigned(data, pos, addl)
	if addl < 24 then
		return addl, pos
	end

	if addl == 24 then
		local b = data:byte(pos)

		if not b then
			return nil, pos
		end

		return b, pos + 1
	end

	if addl == 25 then
		local b1 = data:byte(pos)
		local b2 = data:byte(pos + 1)

		if not b1 or not b2 then
			return nil, pos
		end

		return b1 * 256 + b2, pos + 2
	end

	if addl == 26 then
		local b1 = data:byte(pos)
		local b2 = data:byte(pos + 1)
		local b3 = data:byte(pos + 2)
		local b4 = data:byte(pos + 3)

		if not b1 or not b2 or not b3 or not b4 then
			return nil, pos
		end

		return b1 * 16777216 + b2 * 65536 + b3 * 256 + b4, pos + 4
	end

	return nil, pos
end

local function looksLikeOutfitClipboardCode(code)
	if type(code) ~= "string" then
		return false
	end

	local trimmed = code:match("^%s*(.-)%s*$") or ""

	if #trimmed < 8 then
		return false
	end

	if trimmed:find("[^A-Za-z0-9+/=]") then
		return false
	end

	local rem = #trimmed % 4

	return rem ~= 1
end

local function readCborValue(data, pos, depth)
	depth = depth or 0

	if depth > 16 then
		return nil, pos
	end

	local ib = data:byte(pos)

	if not ib then
		return nil, pos
	end

	pos = pos + 1

	local major = math.floor(ib / 32)
	local addl = ib % 32

	if major == 0 then
		return readCborUnsigned(data, pos, addl)
	end

	if major == 3 then
		local len

		len, pos = readCborUnsigned(data, pos, addl)

		if not len then
			return nil, pos
		end

		local value = data:sub(pos, pos + len - 1)

		if #value ~= len then
			return nil, pos
		end

		return value, pos + len
	end

	if major == 5 then
		local mapLen

		mapLen, pos = readCborUnsigned(data, pos, addl)

		if not mapLen then
			return nil, pos
		end

		local map = {}

		for _ = 1, mapLen do
			local key

			key, pos = readCborValue(data, pos, depth + 1)

			if type(key) ~= "string" then
				return nil, pos
			end

			local value

			value, pos = readCborValue(data, pos, depth + 1)

			if value == nil then
				return nil, pos
			end

			map[key] = value
		end

		return map, pos
	end

	if major == 7 then
		if addl == 20 then
			return false, pos
		end

		if addl == 21 then
			return true, pos
		end
	end

	return nil, pos
end

function decodeCopyColoursCode(code)
	if not looksLikeOutfitClipboardCode(code) then
		return nil
	end

	local raw = base64Decode(code)

	if not raw or #raw < 2 then
		return nil
	end

	local pos = 1
	local first = raw:byte(pos)

	if not first then
		return nil
	end

	pos = pos + 1

	local major = math.floor(first / 32)
	local addl = first % 32

	if major ~= 5 then
		return nil
	end

	local mapSize

	mapSize, pos = readCborUnsigned(raw, pos, addl)

	if not mapSize or mapSize < 1 then
		return nil
	end

	local result = {}

	for _ = 1, mapSize do
		local keyHdr = raw:byte(pos)

		if not keyHdr then
			return nil
		end

		pos = pos + 1

		local keyMajor = math.floor(keyHdr / 32)
		local keyAddl = keyHdr % 32

		if keyMajor ~= 3 then
			return nil
		end

		local keyLen

		keyLen, pos = readCborUnsigned(raw, pos, keyAddl)

		if not keyLen or keyLen < 1 then
			return nil
		end

		local key = raw:sub(pos, pos + keyLen - 1)

		if #key ~= keyLen then
			return nil
		end

		pos = pos + keyLen

		local valueHdr = raw:byte(pos)

		if not valueHdr then
			return nil
		end

		pos = pos + 1

		local valueMajor = math.floor(valueHdr / 32)
		local valueAddl = valueHdr % 32

		if valueMajor ~= 0 then
			return nil
		end

		local value

		value, pos = readCborUnsigned(raw, pos, valueAddl)

		if value == nil then
			return nil
		end

		result[key] = value
	end

	if result.head == nil or result.torso == nil or result.legs == nil or result.detail == nil then
		return nil
	end

	return {
		head = result.head,
		body = result.torso,
		legs = result.legs,
		feet = result.detail
	}
end

function decodeCopyAllCode(code)
	if not looksLikeOutfitClipboardCode(code) then
		return nil
	end

	local raw = base64Decode(code)

	if not raw or #raw < 8 then
		return nil
	end

	local root = readCborValue(raw, 1, 0)

	if type(root) ~= "table" then
		return nil
	end

	if type(root.outfit) ~= "table" or type(root.mount) ~= "table" or type(root.summon) ~= "table" then
		return nil
	end

	if type(root.outfit.color) ~= "table" or type(root.mount.color) ~= "table" then
		return nil
	end

	if root.outfit.id == nil or root.mount.id == nil or root.summon.id == nil then
		return nil
	end

	return root
end

function setPasteButtonMode(mode)
	currentPasteMode = mode == "all" and "all" or "colours"

	if not window or not window.appearance or not window.appearance.colorCopyButtons then
		return
	end

	local button = window.appearance.colorCopyButtons.pasteColours

	if not button or not button.setStyle then
		return
	end

	if currentPasteMode == "all" then
		button:setStyle("OutfitPasteAllButton")
	else
		button:setStyle("OutfitPasteColoursButton")
	end
end

function classifyPasteClipboardCode(clipboardText, canColor)
	if not looksLikeOutfitClipboardCode(clipboardText) then
		return nil
	end

	local raw = base64Decode(clipboardText)

	if not raw or #raw < 2 then
		return nil
	end

	local hasAllSignature = raw:find("mount", 1, true) and raw:find("outfit", 1, true) and raw:find("summon", 1, true)

	if hasAllSignature then
		return "all"
	end

	if not canColor then
		return nil
	end

	local hasColourSignature = raw:find("detail", 1, true) and raw:find("head", 1, true) and raw:find("legs", 1, true) and raw:find("torso", 1, true)

	if hasColourSignature then
		return "colours"
	end

	return nil
end

local function buildCopyColoursCode(cache)
	if not cache then
		return nil
	end

	local cbor = table.concat({
		string.char(164),
		string.char(102),
		"detail",
		encodeCborUnsigned(cache.feet or 0),
		string.char(100),
		"head",
		encodeCborUnsigned(cache.head or 0),
		string.char(100),
		"legs",
		encodeCborUnsigned(cache.legs or 0),
		string.char(101),
		"torso",
		encodeCborUnsigned(cache.body or 0)
	})
	local encoded = base64Encode(cbor)

	return encoded and encoded:gsub("=+$", "") or nil
end

local function buildCopyAllCode()
	if not tempOutfit then
		return nil
	end

	local mountColors = mountColorCache or {}
	local outfitColors = outfitColorCache or {}
	local addons = tempOutfit.addons or 0
	local firstAddOn = addons == 1 or addons == 3
	local secondAddOn = addons == 2 or addons == 3
	local cbor = table.concat({
		string.char(164),
		encodeCborText("mount"),
		string.char(162),
		encodeCborText("color"),
		string.char(164),
		encodeCborText("detail"),
		encodeCborUnsigned(mountColors.feet or 0),
		encodeCborText("head"),
		encodeCborUnsigned(mountColors.head or 0),
		encodeCborText("legs"),
		encodeCborUnsigned(mountColors.legs or 0),
		encodeCborText("torso"),
		encodeCborUnsigned(mountColors.body or 0),
		encodeCborText("id"),
		encodeCborUnsigned(tempOutfit.mount or 0),
		encodeCborText("name"),
		encodeCborText(""),
		encodeCborText("outfit"),
		string.char(164),
		encodeCborText("color"),
		string.char(164),
		encodeCborText("detail"),
		encodeCborUnsigned(outfitColors.feet or 0),
		encodeCborText("head"),
		encodeCborUnsigned(outfitColors.head or 0),
		encodeCborText("legs"),
		encodeCborUnsigned(outfitColors.legs or 0),
		encodeCborText("torso"),
		encodeCborUnsigned(outfitColors.body or 0),
		encodeCborText("firstAddOn"),
		encodeCborBool(firstAddOn),
		encodeCborText("id"),
		encodeCborUnsigned(tempOutfit.type or 0),
		encodeCborText("secondAddOn"),
		encodeCborBool(secondAddOn),
		encodeCborText("summon"),
		string.char(161),
		encodeCborText("id"),
		encodeCborUnsigned(tempOutfit.familiar or 0)
	})
	local encoded = base64Encode(cbor)

	return encoded and encoded:gsub("=+$", "") or nil
end

local function onCopyAllClick()
	local code = buildCopyAllCode()

	if code and g_window and g_window.setClipboardText then
		g_window.setClipboardText(code)
		updateColorControlsState()
	end
end

local function onCopyColoursClick()
	if not isColorContextActive() then
		return
	end

	local app = getAppearanceCategoryName()
	local cache = getColorCacheForAppearance(app)
	local code = buildCopyColoursCode(cache)

	if code and g_window and g_window.setClipboardText then
		g_window.setClipboardText(code)
		updateColorControlsState()
	end
end

local function onPasteColoursClick()
	if not g_window or not g_window.getClipboardText then
		return
	end

	local clipboardText = g_window.getClipboardText()
	local detectedMode = classifyPasteClipboardCode(clipboardText, isColorContextActive())

	if detectedMode == "all" then
		local decodedAll = decodeCopyAllCode(clipboardText)

		if not decodedAll then
			updateColorControlsState()

			return
		end

		local outfitData = decodedAll.outfit or {}
		local outfitColors = outfitData.color or {}
		local mountData = decodedAll.mount or {}
		local mountColors = mountData.color or {}
		local summonData = decodedAll.summon or {}

		tempOutfit.type = tonumber(outfitData.id) or tempOutfit.type
		tempOutfit.mount = tonumber(mountData.id) or 0
		tempOutfit.familiar = tonumber(summonData.id) or 0
		tempOutfit.addons = (outfitData.firstAddOn and 1 or 0) + (outfitData.secondAddOn and 2 or 0)
		outfitColorCache.head = tonumber(outfitColors.head) or 0
		outfitColorCache.body = tonumber(outfitColors.torso) or 0
		outfitColorCache.legs = tonumber(outfitColors.legs) or 0
		outfitColorCache.feet = tonumber(outfitColors.detail) or 0
		mountColorCache.head = tonumber(mountColors.head) or 0
		mountColorCache.body = tonumber(mountColors.torso) or 0
		mountColorCache.legs = tonumber(mountColors.legs) or 0
		mountColorCache.feet = tonumber(mountColors.detail) or 0

		applyOutfitColorsToTemp()
		updateAppearanceTexts(tempOutfit)
		refreshColorBoxForCurrentContext()
		updatePreview()
		refreshFilterListForCurrentColorChange()
		updateColorControlsState()

		return
	end

	if detectedMode ~= "colours" then
		updateColorControlsState()

		return
	end

	if not isColorContextActive() then
		return
	end

	local decoded = decodeCopyColoursCode(clipboardText)

	if not decoded then
		updateColorControlsState()

		return
	end

	local app = getAppearanceCategoryName()
	local cache = getColorCacheForAppearance(app)

	if not cache then
		return
	end

	cache.head = decoded.head
	cache.body = decoded.body
	cache.legs = decoded.legs
	cache.feet = decoded.feet

	if app == "outfit" then
		applyOutfitColorsToTemp()
	end

	refreshColorBoxForCurrentContext()
	updatePreview()
	refreshFilterListForCurrentColorChange()
	updateColorControlsState()
end

function refreshColorBoxForCurrentContext()
	if not window or not colorBoxGroup or not colorModeGroup then
		return
	end

	if not isColorContextActive() then
		return
	end

	local app = getAppearanceCategoryName()
	local cache = getColorCacheForAppearance(app)

	if not cache then
		return
	end

	local sm = colorModeGroup:getSelectedWidget()

	if not sm then
		return
	end

	local colorMode = sm:getId()
	local id = getColorIdFromMode(cache, colorMode)
	local box = window.appearance.colorSection.colorBoxBackground.colorBoxPanel["colorBox" .. id]

	if box and colorBoxGroup then
		colorPickerProgrammatic = true

		colorBoxGroup:selectWidget(box)

		colorPickerProgrammatic = false
	end
end

local AppearanceData = {
	"preset",
	"outfit",
	"mount",
	"familiar"
}

function init()
	connect(g_game, {
		onOpenOutfitWindow = onOpenPlayerOutfitWindow,
		onOpenHirelingOutfitWindow = onOpenHirelingOutfitWindow,
		onOpenPlayerPodiumWindow = onOpenPlayerPodiumWindow,
		onGameEnd = destroy
	})
end

function terminate()
	disconnect(g_game, {
		onOpenOutfitWindow = onOpenPlayerOutfitWindow,
		onOpenHirelingOutfitWindow = onOpenHirelingOutfitWindow,
		onOpenPlayerPodiumWindow = onOpenPlayerPodiumWindow,
		onGameEnd = destroy
	})
	destroy()
end

function onOpenPlayerOutfitWindow(player, outfitList, creatureMount, mountList, familiarList)
	if modules.game_customisepodium and modules.game_customisepodium.consumePendingOutfitWindow and
		modules.game_customisepodium.consumePendingOutfitWindow(player, outfitList, creatureMount, mountList) then
		return
	end

	hirelingContext = nil
	memoryScenarioSelectionSequence = 0

	traceMemoryScenario("outfit-window-open", string.format("outfits=%d mounts=%d familiars=%d", outfitList and #outfitList or 0, mountList and #mountList or 0, familiarList and #familiarList or 0))
	create(player, outfitList, creatureMount, mountList, familiarList)
end

function onOpenHirelingOutfitWindow(player, outfitList, creatureId)
	hirelingContext = {
		creatureId = creatureId
	}

	create(player, outfitList, nil, {}, {})
	applyHirelingWindowMode()
end

local function hidePreviewOption(optionWidget)
	if not optionWidget then
		return
	end

	optionWidget:setVisible(false)
	optionWidget:setHeight(0)
	optionWidget:setPadding(0)
end

local function hideConfigureOption(optionWidget)
	if not optionWidget then
		return
	end

	optionWidget:setVisible(false)
	optionWidget:setHeight(0)
	optionWidget:setPadding(0)
end

function applyHirelingWindowMode()
	if not window or not hirelingContext then
		return
	end

	window:setText(tr("Customise Hireling"))
	hidePreviewOption(window.preview.options.movement)
	hidePreviewOption(window.preview.options.showOutfit)
	hidePreviewOption(window.preview.options.showFamiliar)

	settings.movement = false

	if movementCheck then
		local movementHandler = movementCheck.onCheckChange

		movementCheck.onCheckChange = nil

		movementCheck:setChecked(false)

		movementCheck.onCheckChange = movementHandler
	end

	syncPreviewWalkingState()

	if window.appearance and window.appearance.settings then
		local settingsPanel = window.appearance.settings

		for _, key in ipairs({
			"mount",
			"familiar",
			"preset"
		}) do
			local row = settingsPanel[key]

			if row then
				row:hide()
				row:setHeight(0)
			end
		end

		settingsPanel:setHeight(settingsPanel:getHeight() - hirelingAppearanceCompactionHeight)
	end

	if window.configure then
		hideConfigureOption(window.configure.addon1)
		hideConfigureOption(window.configure.addon2)
		hideConfigureOption(window.configure.mount)
	end

	if window.presetButtons then
		window.presetButtons:hide()
		window.presetButtons:setHeight(0)
		window.presetButtons:setPadding(0)
	end

	if window.selectionList and window.listSearch then
		window.selectionList:breakAnchors()
		window.selectionList:addAnchor(AnchorTop, "listSearch", AnchorBottom)
		window.selectionList:addAnchor(AnchorLeft, "listSearch", AnchorLeft)
		window.selectionList:addAnchor(AnchorRight, "parent", AnchorRight)
		window.selectionList:addAnchor(AnchorBottom, "separator", AnchorTop)
		window.selectionList:setMarginTop(6)
		window.selectionList:setMarginBottom(6)
		window.selectionList:setMarginLeft(0)
	end

	if window.configure then
		window.configure:setHeight(window.configure:getHeight() - hirelingAppearanceCompactionHeight)
	end

	if window.appearance then
		window.appearance:setHeight(window.appearance:getHeight() - hirelingAppearanceCompactionHeight)
	end

	window:setSize(string.format("%d %d", outfitWindowDefaultWidth, hirelingWindowHeight))
	window:setMarginTop(outfitWindowCompactMarginTop)
	updatePreview()
end

function onOpenPlayerPodiumWindow(player, outfitList, creatureMount, mountList, data)
	hirelingContext = nil
	podiumContext = data
	podiumContext.sourceThing = getPodiumSourceThing(data.position, data.itemClientId)
	showPlatformBeforeOutfitOff = data.showPlatform ~= false
	previewPodiumItem = nil
	podiumPreviewInitialized = false

	create(player, outfitList, creatureMount, mountList, {})
	applyPodiumWindowMode()
end

local function showConfigureOption(optionWidget)
	if not optionWidget then
		return
	end

	optionWidget:setVisible(true)
	optionWidget:setHeight(22)
	optionWidget:setPadding(5)
end

function applyPodiumWindowMode()
	if not window or not podiumContext then
		return
	end

	window:setText(tr("Customise Podium"))
	hidePreviewOption(window.preview.options.movement)
	hidePreviewOption(window.preview.options.showOutfit)
	hidePreviewOption(window.preview.options.showFamiliar)

	if window.configure and window.configure.outfit and window.configure.outfit.check then
		showConfigureOption(window.configure.outfit)
		window.configure.addon1:setMarginTop(0)

		podiumOutfitCheck = window.configure.outfit.check
		podiumOutfitCheck.onCheckChange = onPodiumOutfitChange
		settings.showOutfit = podiumContext.showCreature ~= false

		podiumOutfitCheck:setChecked(settings.showOutfit)
		onPodiumOutfitChange(podiumOutfitCheck, settings.showOutfit)
		syncShowOutfitOptionState()
	end

	if window.configure and window.configure.podium and window.configure.podium.check then
		showConfigureOption(window.configure.podium)

		podiumPlatformCheck = window.configure.podium.check
		podiumPlatformCheck.onCheckChange = onPodiumPlatformChange

		podiumPlatformCheck:setChecked(podiumContext.showPlatform ~= false)

		podiumContext.showPlatform = podiumPlatformCheck:isChecked()

		syncShowPodiumOptionState()
	end

	if g_game.getFeature(GamePlayerMounts) and window.configure.mount and window.configure.mount.check then
		window.configure.mount.check:setEnabled((tempOutfit.mount or 0) > 0 or not table.empty(ServerData.mounts))
		window.configure.mount.check:setChecked(podiumContext.showMount == true)

		if podiumContext.showMount and (tempOutfit.mount or 0) == 0 and not table.empty(ServerData.mounts) then
			tempOutfit.mount = getPreferredInitialMountId(ServerData.mounts)
		end

		syncShowOutfitOptionState()
	end

	updatePreview()
end

function onPodiumPlatformChange(checkBox, checked)
	if not podiumContext or not podiumCreatureWouldDisplay() then
		syncShowPodiumOptionState()

		return
	end

	podiumContext.showPlatform = checked

	updatePreview()
end

function onPodiumOutfitChange(checkBox, checked)
	local showOutfit = checked

	if showOutfit == nil and checkBox then
		showOutfit = checkBox:isChecked()
	end

	settings.showOutfit = showOutfit

	if podiumContext then
		if showOutfit then
			podiumContext.showPlatform = showPlatformBeforeOutfitOff
		else
			showPlatformBeforeOutfitOff = podiumContext.showPlatform ~= false
		end

		podiumContext.showCreature = showOutfit
	end

	syncPodiumAddonCheckState()
	updatePreview()
end

function onMovementChange(checkBox, checked)
	local enabled = checked == true

	movementEnabledForSession = enabled
	settings.movement = enabled

	traceMemoryScenario("movement-change", string.format("enabled=%s", tostring(enabled)))

	if previewCreature and previewCreature:getCreature() then
		updatePreview()
	else
		syncPreviewWalkingState()
	end
end

function onShowFloorChange(checkBox, checked)
	if checked then
		floor:show()

		if floorEventRunning then
			settings.showFloor = checked

			return
		end

		floorEventRunning = true

		local delay = 50

		periodicalEvent(function()
			if not podiumContext and not hirelingContext and settings.movement and previewCreature and previewCreature:getCreature() then
				local dir = previewCreature:getDirection()
				local step = 8

				if dir == Directions.North then
					floorOffsetY = (floorOffsetY - step + floorTileHeight) % floorTileHeight
				elseif dir == Directions.South then
					floorOffsetY = (floorOffsetY + step) % floorTileHeight
				elseif dir == Directions.East then
					floorOffsetX = (floorOffsetX + step) % floorTileWidth
				elseif dir == Directions.West then
					floorOffsetX = (floorOffsetX - step + floorTileWidth) % floorTileWidth
				end

				applyFloorRowScrollMargins()
			else
				floor:setMargin(0)
				resetFloorScrollOffsets()
			end
		end, function()
			local keepRunning = window and floor and showFloorCheck and showFloorCheck:isChecked()

			if not keepRunning then
				floorEventRunning = false
			end

			return keepRunning
		end, delay, delay)
	else
		floor:hide()
		floor:setMargin(0)

		floorEventRunning = false

		resetFloorScrollOffsets()
	end

	settings.showFloor = checked
end

function onShowFamiliarChange(checkBox, checked)
	local hasFamiliars = ServerData and ServerData.familiars and not table.empty(ServerData.familiars)

	if not hasFamiliars then
		settings.showFamiliar = false

		if checkBox and checkBox:isChecked() then
			checkBox:setChecked(false)
		end

		updatePreview()

		return
	end

	settings.showFamiliar = checked

	updatePreview()
end

function syncShowOutfitOptionState()
	local outfitCheck = podiumContext and podiumOutfitCheck or showOutfitCheck

	if not window or not outfitCheck then
		return
	end

	local hasFamiliars = ServerData and ServerData.familiars and not table.empty(ServerData.familiars)

	if podiumContext then
		outfitCheck:setEnabled(true)
		outfitCheck:setColor("#c0c0c0")
		syncPodiumAddonCheckState()
		syncShowPodiumOptionState()

		return
	end

	if not g_game.getFeature(GamePlayerMounts) or not window.configure.mount or not window.configure.mount.check then
		outfitCheck:setEnabled(true)
		outfitCheck:setColor("#c0c0c0")

		if showFamiliarCheck and not podiumContext then
			if hasFamiliars then
				showFamiliarCheck:setEnabled(settings.showOutfit)
				showFamiliarCheck:setColor(settings.showOutfit and "#c0c0c0" or "#707070")
			else
				settings.showFamiliar = false

				showFamiliarCheck:setChecked(false)
				showFamiliarCheck:setEnabled(true)
				showFamiliarCheck:setColor("#707070")
			end
		end

		return
	end

	local mountOn = window.configure.mount.check:isChecked()

	if not mountOn then
		settings.showOutfit = true

		local h = outfitCheck.onCheckChange

		outfitCheck.onCheckChange = nil

		outfitCheck:setChecked(true)

		outfitCheck.onCheckChange = h

		if podiumContext then
			podiumContext.showCreature = true
		end
	end

	outfitCheck:setEnabled(mountOn)
	outfitCheck:setColor(mountOn and "#c0c0c0" or "#707070")

	if showFamiliarCheck and not podiumContext then
		if hasFamiliars then
			showFamiliarCheck:setEnabled(settings.showOutfit)
			showFamiliarCheck:setColor(settings.showOutfit and "#c0c0c0" or "#707070")
		else
			settings.showFamiliar = false

			showFamiliarCheck:setChecked(false)
			showFamiliarCheck:setEnabled(true)
			showFamiliarCheck:setColor("#707070")
		end
	end
end

function onShowOutfitChange(checkBox, checked)
	settings.showOutfit = checked

	local hasFamiliars = ServerData and ServerData.familiars and not table.empty(ServerData.familiars)

	if hasFamiliars then
		showFamiliarCheck:setEnabled(settings.showOutfit)
		showFamiliarCheck:setColor(settings.showOutfit and "#c0c0c0" or "#707070")
	else
		settings.showFamiliar = false

		showFamiliarCheck:setChecked(false)
		showFamiliarCheck:setEnabled(true)
		showFamiliarCheck:setColor("#707070")
	end

	updatePreview()
end

function onConfigureMountChange(checkBox, checked)
	if podiumContext then
		podiumContext.showMount = checked

		if checked then
			ensurePodiumMountSelection()
		end

		syncShowPodiumOptionState()
	else
		syncShowOutfitOptionState()
	end

	updatePreview()
end

function mergeCyclopediaPendingIntoTempOutfit(pending, outfitTable)
	if pending.tabType == "outfits" then
		outfitTable.type = pending.lookType
		outfitTable.addons = pending.addons or 0
	elseif pending.tabType == "mounts" then
		outfitTable.mount = pending.lookType
	elseif pending.tabType == "familiars" then
		outfitTable.familiar = pending.lookType
	end

	if pending.colors then
		outfitTable.head = pending.colors.head or outfitTable.head
		outfitTable.body = pending.colors.body or outfitTable.body
		outfitTable.legs = pending.colors.legs or outfitTable.legs
		outfitTable.feet = pending.colors.feet or outfitTable.feet
	end
end

function applyCyclopediaViewMode(pending)
	cyclopediaViewMode = true

	window:setText(tr(CYClOPEDIA_VIEW_TITLES[pending.tabType] or "View Outfits"))

	local acceptButton = window:recursiveGetChildById("acceptButton")

	if acceptButton then
		acceptButton:hide()
	end

	local presetSetting = window.appearance and window.appearance.settings and window.appearance.settings.preset

	if presetSetting then
		presetSetting:hide()
		presetSetting:setHeight(0)
	end

	if window.appearance and window.appearance.settings then
		window.appearance.settings:setHeight(window.appearance.settings:getHeight() - missingPresetCompactionHeight)
	end

	if window.appearance then
		window.appearance:setHeight(window.appearance:getHeight() - missingPresetCompactionHeight)
	end

	if window.configure then
		window.configure:setHeight(window.configure:getHeight() - missingPresetCompactionHeight)
	end

	window:setSize(string.format("%d %d", window:getWidth(), window:getHeight() - missingPresetCompactionHeight))

	function window.onEnter()
		destroy()
	end
end

function focusCyclopediaAppearanceSelection(pending)
	local tabWidgets = {
		outfits = window.appearance.settings.outfit.check,
		mounts = window.appearance.settings.mount.check,
		familiars = window.appearance.settings.familiar.check
	}
	local tabWidget = tabWidgets[pending.tabType]

	if appearanceGroup and tabWidget then
		appearanceGroup:selectWidget(tabWidget)
	end

	local list = window.selectionList
	local grid = getSelectionListGrid()

	if not list or not list:isVisible() then
		updatePreview()

		return
	end

	local lookId = pending.lookType
	local focusedWidget = grid and (grid:getChildById(tostring(lookId)) or grid[lookId])
	local appearanceKey = pending.tabType == "mounts" and "mount" or pending.tabType == "familiars" and "familiar" or "outfit"

	if pending.tabType == "outfits" then
		tempOutfit.type = lookId
		tempOutfit.addons = pending.addons or 0

		configureAddons(tempOutfit.addons)
	elseif pending.tabType == "mounts" then
		tempOutfit.mount = lookId

		local mountConfigureCheck = window.configure and window.configure.mount and window.configure.mount.check

		if mountConfigureCheck then
			mountConfigureCheck:setEnabled(true)
			mountConfigureCheck:setChecked(true)
		end
	elseif pending.tabType == "familiars" then
		tempOutfit.familiar = lookId
	end

	if focusedWidget then
		setSelectionListFocusHandler(nil)
		focusedWidget:focus()
		list:ensureChildVisible(focusedWidget, {
			y = 196,
			x = 0
		})

		if pending.tabType == "mounts" then
			onMountSelect(grid, focusedWidget, nil, nil)
		elseif pending.tabType == "familiars" then
			onFamiliarSelect(grid, focusedWidget, nil, nil)
		end
	end

	updatePreview()

	if pending.name then
		updateAppearanceText(appearanceKey, pending.name)
	end

	if pending.tabType == "outfits" then
		setSelectionListFocusHandler(onOutfitSelect)
	elseif pending.tabType == "mounts" then
		setSelectionListFocusHandler(onMountSelect)
	elseif pending.tabType == "familiars" then
		setSelectionListFocusHandler(onFamiliarSelect)
	end
end

function applyPendingCyclopediaFocus()
	if not pendingCyclopediaFocus or not window then
		return
	end

	local pending = pendingCyclopediaFocus

	pendingCyclopediaFocus = nil
	activeCyclopediaPending = pending

	local tabWidgets = {
		outfits = window.appearance.settings.outfit.check,
		mounts = window.appearance.settings.mount.check,
		familiars = window.appearance.settings.familiar.check
	}
	local tabWidget = tabWidgets[pending.tabType] or tabWidgets.outfits

	appearanceGroup:selectWidget(tabWidget)
	addEvent(function()
		if not window then
			activeCyclopediaPending = nil

			return
		end

		focusCyclopediaAppearanceSelection(pending)
		applyCyclopediaViewMode(pending)
		updateColorControlsState()
		refreshColorBoxForCurrentContext()

		activeCyclopediaPending = nil
	end)
end

function openFromCyclopedia(appearanceData)
	if not appearanceData or not appearanceData.outfit then
		g_game.requestOutfit()

		return
	end

	pendingCyclopediaFocus = {
		viewMode = true,
		tabType = appearanceData.type,
		lookType = appearanceData.outfit.type,
		addons = appearanceData.outfit.addons or 0,
		name = appearanceData.name,
		colors = {
			head = appearanceData.outfit.head,
			body = appearanceData.outfit.body,
			legs = appearanceData.outfit.legs,
			feet = appearanceData.outfit.feet
		}
	}
	restoreCyclopediaOnClose = true

	g_game.requestOutfit()
end

local PreviewOptions = {
	showFloor = onShowFloorChange,
	showOutfit = onShowOutfitChange,
	showFamiliar = onShowFamiliarChange
}

function create(player, outfitList, creatureMount, mountList, familiarList)
	if ignoreNextOutfitWindow and g_clock.millis() < ignoreNextOutfitWindow + 1000 then
		return
	end

	local cyclopediaPending = pendingCyclopediaFocus
	local restoreCyclopedia = restoreCyclopediaOnClose
	local currentOutfit = player:getOutfit()

	if window then
		destroy({
			skipCyclopediaRestore = true
		})
	end

	pendingCyclopediaFocus = cyclopediaPending
	restoreCyclopediaOnClose = restoreCyclopedia

	loadSettings()

	ServerData = {
		currentOutfit = currentOutfit,
		outfits = outfitList,
		mounts = mountList,
		familiars = familiarList
	}
	window = g_ui.displayUI("outfitwindow")

	g_modalManager.show(window)

	floor = window.preview.panel.floor
	floorRowWidgets = {}

	for r = 1, floorTileRows do
		for c = 1, floorTileColumns do
			local tile = floor["floorR" .. r .. "C" .. c]

			tile:setSize(string.format("%d %d", floorTileWidth, floorTileHeight))
			table.insert(floorRowWidgets, tile)
		end
	end

	floorOffsetX = 0
	floorOffsetY = 0

	applyFloorRowScrollMargins()
	floor:setSize(string.format("%d %d", floorTileColumns * floorTileWidth, floorTileRows * floorTileHeight))
	floor:setMargin(0)

	floorEventRunning = false

	floor:hide()

	for _, appKey in ipairs(AppearanceData) do
		updateAppearanceText(appKey, "None")
	end

	previewCreature = window.preview.panel:recursiveGetChildById("creature")
	previewFamiliar = window.preview.panel:recursiveGetChildById("UIfamiliar")
	previewRow = window.preview.panel:recursiveGetChildById("previewRow")

	setupPodiumPreviewWidget()

	previewPodiumItem = nil
	movementCheck = window.preview.options.movement.check
	showFloorCheck = window.preview.options.showFloor.check
	showOutfitCheck = window.preview.options.showOutfit.check
	showFamiliarCheck = window.preview.options.showFamiliar.check

	if settings.currentPreset == nil then
		loadDefaultSettings()
		print("game_outfit error funtion loadSettings()")
	end

	settings.currentPreset = 0
	didAcceptCustomize = false
	tempOutfit = table.copy(currentOutfit)

	if cyclopediaPending then
		mergeCyclopediaPendingIntoTempOutfit(cyclopediaPending, tempOutfit)
	end

	initColorCachesFromOutfit(tempOutfit)
	applyGlobalColorCachesFromSettings()
	applyOutfitColorsToTemp()

	if g_game.getFeature(GamePlayerMounts) then
		local cyclopediaMountPreview = cyclopediaPending and cyclopediaPending.tabType == "mounts"

		if cyclopediaMountPreview then
			window.configure.mount.check:setEnabled(true)
			window.configure.mount.check:setChecked(true)
		else
			local isMount = g_game.getLocalPlayer():isMounted()

			if isMount then
				window.configure.mount.check:setEnabled(true)
				window.configure.mount.check:setChecked(true)
			else
				window.configure.mount.check:setEnabled(currentOutfit.mount > 0)
				window.configure.mount.check:setChecked(isMount and currentOutfit.mount > 0)
			end
		end

		window.configure.mount.check.onCheckChange = onConfigureMountChange
	end

	if tempOutfit.addons == 3 then
		window.configure.addon1.check:setChecked(true)
		window.configure.addon2.check:setChecked(true)
	elseif tempOutfit.addons == 2 then
		window.configure.addon1.check:setChecked(false)
		window.configure.addon2.check:setChecked(true)
	elseif tempOutfit.addons == 1 then
		window.configure.addon1.check:setChecked(true)
		window.configure.addon2.check:setChecked(false)
	end

	window.configure.addon1.check.onCheckChange = onAddonChange
	window.configure.addon2.check.onCheckChange = onAddonChange

	configureAddons(tempOutfit.addons)

	for _, option in ipairs(window.preview.options:getChildren()) do
		local handler = PreviewOptions[option:getId()]

		if handler then
			option.check.onCheckChange = handler
		end
	end

	movementCheck.onCheckChange = nil

	movementCheck:setChecked(movementEnabledForSession)

	movementCheck.onCheckChange = onMovementChange

	onMovementChange(movementCheck, movementCheck:isChecked())
	showFloorCheck:setChecked(settings.showFloor)

	if showFloorCheck:isChecked() and not floor:isVisible() then
		onShowFloorChange(showFloorCheck, true)
	end

	showOutfitCheck:setChecked(settings.showOutfit)

	local hasFamiliars = not table.empty(ServerData.familiars)

	showFamiliarCheck:setChecked(hasFamiliars and settings.showFamiliar or false)
	updatePreview()
	updateAppearanceTexts(tempOutfit)

	colorBoxGroup = UIRadioGroup.create()

	for j = 0, 6 do
		for i = 0, 18 do
			local colorBox = g_ui.createWidget("OutfitColorBox", window.appearance.colorSection.colorBoxBackground.colorBoxPanel)
			local outfitColor = getOutfitColor(j * 19 + i)

			colorBox.color:setImageColor(outfitColor)
			colorBox:setId("colorBox" .. j * 19 + i)

			colorBox.colorId = j * 19 + i

			if colorBox.colorId == outfitColorCache.head then
				currentColorBox = colorBox

				colorBox:setChecked(true)
			end

			colorBoxGroup:addWidget(colorBox)
		end
	end

	colorBoxGroup.onSelectionChange = onColorCheckChange
	appearanceGroup = UIRadioGroup.create()

	appearanceGroup:addWidget(window.appearance.settings.outfit.check)
	appearanceGroup:addWidget(window.appearance.settings.mount.check)
	appearanceGroup:addWidget(window.appearance.settings.familiar.check)
	appearanceGroup:addWidget(window.appearance.settings.preset.check)

	appearanceGroup.onSelectionChange = onAppearanceChange

	if not cyclopediaPending then
		appearanceGroup:selectWidget(window.appearance.settings.outfit.check)
	end

	colorModeGroup = UIRadioGroup.create()

	colorModeGroup:addWidget(window.appearance.colorSection.colorMode.head)
	colorModeGroup:addWidget(window.appearance.colorSection.colorMode.primary)
	colorModeGroup:addWidget(window.appearance.colorSection.colorMode.secondary)
	colorModeGroup:addWidget(window.appearance.colorSection.colorMode.detail)

	colorModeGroup.onSelectionChange = onColorModeChange

	colorModeGroup:selectWidget(window.appearance.colorSection.colorMode.head)

	if window.appearance and window.appearance.colorCopyButtons and window.appearance.colorCopyButtons.copyAll then
		window.appearance.colorCopyButtons.copyAll.onClick = onCopyAllClick
	end

	if window.appearance and window.appearance.colorCopyButtons and window.appearance.colorCopyButtons.copyColours then
		window.appearance.colorCopyButtons.copyColours.onClick = onCopyColoursClick
	end

	if window.appearance and window.appearance.colorCopyButtons and window.appearance.colorCopyButtons.pasteColours then
		window.appearance.colorCopyButtons.pasteColours.onClick = onPasteColoursClick
	end

	window.configure.mount:setVisible(g_game.getFeature(GamePlayerMounts))
	window.appearance.settings.mount:setVisible(g_game.getFeature(GamePlayerMounts))
	window.preview.options.showFamiliar:setVisible(g_game.getFeature(GamePlayerFamiliars))
	window.appearance.settings.familiar:setVisible(g_game.getFeature(GamePlayerFamiliars))

	if showFamiliarCheck then
		if hasFamiliars then
			showFamiliarCheck:setEnabled(settings.showOutfit)
			showFamiliarCheck:setColor(settings.showOutfit and "#c0c0c0" or "#707070")
		else
			settings.showFamiliar = false

			showFamiliarCheck:setChecked(false)
			showFamiliarCheck:setEnabled(true)
			showFamiliarCheck:setColor("#707070")
		end
	end

	if window.appearance and window.appearance.settings and window.appearance.settings.familiar then
		local familiarSetting = window.appearance.settings.familiar

		familiarSetting:setVisible(hasFamiliars)
	end

	if window and window.appearance and window.appearance.settings then
		window.appearance.settings:setHeight(hasFamiliars and appearanceSettingsDefaultHeight or appearanceSettingsDefaultHeight - missingFamiliarCompactionHeight)
	end

	if window and window.configure then
		window.configure:setHeight(hasFamiliars and configurePanelDefaultHeight or configurePanelDefaultHeight - missingFamiliarCompactionHeight)
	end

	if window and window.appearance then
		window.appearance:setHeight(hasFamiliars and appearancePanelDefaultHeight or appearancePanelDefaultHeight - missingFamiliarCompactionHeight)
	end

	if window then
		window:setSize(string.format("%d %d", outfitWindowDefaultWidth, hasFamiliars and outfitWindowDefaultHeight or outfitWindowDefaultHeight - missingFamiliarCompactionHeight))
		window:setMarginTop(hasFamiliars and outfitWindowDefaultMarginTop or outfitWindowCompactMarginTop)
	end

	if previewCreature and previewCreature:getCreature() then
		previewCreature:getCreature():setDirection(2)
	end

	window.listSearch.search.onKeyPress = onFilterSearch
	window.listSearch.onlyMine.onCheckChange = onFilterOnlyMine

	if window.selectionScroll then
		function window.selectionScroll.onValueChange(scrollbar, value)
			scheduleSelectionListHydration("scroll")
		end
	end

	updateColorControlsState()
	startClipboardChangeWatcher()

	if window.configure and window.configure.outfit then
		window.configure.outfit:setVisible(false)
		window.configure.outfit:setHeight(0)
		window.configure.outfit:setPadding(0)
	end

	if window.configure and window.configure.addon1 then
		window.configure.addon1:setMarginTop(-3)
	end

	if window.configure and window.configure.podium then
		window.configure.podium:setVisible(false)
		window.configure.podium:setHeight(0)
		window.configure.podium:setPadding(0)
	end

	podiumOutfitCheck = nil
	podiumPlatformCheck = nil

	if cyclopediaPending then
		applyPendingCyclopediaFocus()
	end
end

function destroy(options)
	options = options or {}

	clearSelectionWarmupEvent()
	clearSelectionHydrationEvent()
	clearPreviewMovementReadyEvent()
	selectionTextureCache.releaseHydration()

	if not window then
		podiumContext = nil
		hirelingContext = nil

		return
	end

	local shouldRestoreCyclopedia = restoreCyclopediaOnClose and not options.skipCyclopediaRestore

	if not options.skipCyclopediaRestore then
		restoreCyclopediaOnClose = false
	end

	local win = window

	window = nil

	traceMemoryScenario("outfit-window-close", string.format("selections=%d movement=%s", memoryScenarioSelectionSequence, tostring(settings and settings.movement == true)))
	win:hide()

	if g_modalManager then
		g_modalManager.hide(win)

		if g_modalManager.pruneOrphanBlockers then
			g_modalManager.pruneOrphanBlockers()
		end
	end

	if modules.game_containers and modules.game_containers.clearContainerDragHover then
		modules.game_containers.clearContainerDragHover()
	end

	stopClipboardChangeWatcher()

	pendingCyclopediaFocus = nil
	activeCyclopediaPending = nil
	cyclopediaViewMode = false
	pendingRenamePresetId = nil
	floor = nil
	floorRowWidgets = {}
	movementCheck = nil
	showFloorCheck = nil
	showOutfitCheck = nil
	showFamiliarCheck = nil
	podiumOutfitCheck = nil
	podiumPlatformCheck = nil
	colorBoxes = {}
	currentColorBox = nil

	if previewCreature then
		previewCreature:destroy()

		previewCreature = nil
	end

	if previewFamiliar then
		previewFamiliar:destroy()

		previewFamiliar = nil
	end

	previewRow = nil
	previewPodiumWidget = nil
	previewPodiumItem = nil
	podiumPreviewInitialized = false

	if appearanceGroup then
		appearanceGroup:destroy()

		appearanceGroup = nil
	end

	if colorModeGroup then
		colorModeGroup:destroy()

		colorModeGroup = nil
	end

	if colorBoxGroup then
		colorBoxGroup:destroy()

		colorBoxGroup = nil
	end

	ServerData = {
		currentOutfit = {},
		outfits = {},
		mounts = {},
		familiars = {}
	}

	if didAcceptCustomize and settings and type(settings) == "table" then
		settings.outfitColorCache = {
			head = outfitColorCache.head or 0,
			body = outfitColorCache.body or 0,
			legs = outfitColorCache.legs or 0,
			feet = outfitColorCache.feet or 0
		}

		if g_game.getFeature(GamePlayerMounts) then
			settings.mountColorCache = {
				head = mountColorCache.head or 0,
				body = mountColorCache.body or 0,
				legs = mountColorCache.legs or 0,
				feet = mountColorCache.feet or 0
			}
		end
	end

	saveSettings()

	settings = {}

	destroyOutfitWindowIncrementally(win)

	podiumContext = nil
	hirelingContext = nil

	if shouldRestoreCyclopedia and modules.game_cyclopedia and modules.game_cyclopedia.restoreFromOverlay then
		addEvent(function()
			modules.game_cyclopedia.restoreFromOverlay()
		end)
	end
end

local function getCurrentOutfitAvailableAddons()
	if not tempOutfit or not ServerData or not ServerData.outfits then
		return 0
	end

	for _, outfitData in ipairs(ServerData.outfits) do
		if outfitData[1] == tempOutfit.type then
			return outfitData[3] or 0
		end
	end

	return tempOutfit.addons or 0
end

function syncPodiumAddonCheckState()
	if not podiumContext or not window or not window.configure then
		return
	end

	if not settings.showOutfit then
		tempOutfit.addons = 0
		window.configure.addon1.check.onCheckChange = nil
		window.configure.addon2.check.onCheckChange = nil

		window.configure.addon1.check:setChecked(false)
		window.configure.addon2.check:setChecked(false)
		window.configure.addon1.check:setEnabled(false)
		window.configure.addon2.check:setEnabled(false)
		window.configure.addon1.check:setColor("#707070")
		window.configure.addon2.check:setColor("#707070")

		window.configure.addon1.check.onCheckChange = onAddonChange
		window.configure.addon2.check.onCheckChange = onAddonChange

		return
	end

	configureAddons(getCurrentOutfitAvailableAddons())
end

function configureAddons(addons)
	local hasAddon1 = addons == 1 or addons == 3
	local hasAddon2 = addons == 2 or addons == 3

	window.configure.addon1.check:setEnabled(hasAddon1)
	window.configure.addon2.check:setEnabled(hasAddon2)

	window.configure.addon1.check.onCheckChange = nil
	window.configure.addon2.check.onCheckChange = nil

	window.configure.addon1.check:setChecked(false)
	window.configure.addon2.check:setChecked(false)

	if tempOutfit.addons == 3 then
		window.configure.addon1.check:setChecked(true)
		window.configure.addon2.check:setChecked(true)
	elseif tempOutfit.addons == 2 then
		window.configure.addon1.check:setChecked(false)
		window.configure.addon2.check:setChecked(true)
	elseif tempOutfit.addons == 1 then
		window.configure.addon1.check:setChecked(true)
		window.configure.addon2.check:setChecked(false)
	end

	window.configure.addon1.check.onCheckChange = onAddonChange
	window.configure.addon2.check.onCheckChange = onAddonChange

	if podiumContext then
		window.configure.addon1.check:setColor(hasAddon1 and "#c0c0c0" or "#707070")
		window.configure.addon2.check:setColor(hasAddon2 and "#c0c0c0" or "#707070")
	end
end

local function getPresetButtonCreature(widget)
	local row = widget.presetIconRow

	return row and row.creature or widget.creature
end

local function getPresetButtonFamiliar(widget)
	local row = widget.presetIconRow

	return row and row.presetFamiliar
end

local function layoutPresetIconRowOutfitSingleOrDual(presetWidget, dualMode)
	local row = presetWidget.presetIconRow
	local creature = getPresetButtonCreature(presetWidget)
	local fam = getPresetButtonFamiliar(presetWidget)

	if not row or not creature or not creature.breakAnchors then
		return
	end

	creature:breakAnchors()

	if dualMode and fam then
		creature:addAnchor(AnchorLeft, "parent", AnchorLeft)
		creature:addAnchor(AnchorVerticalCenter, "parent", AnchorVerticalCenter)
		creature:setMarginLeft(0)
		creature:setMarginRight(0)
		fam:breakAnchors()
		fam:addAnchor(AnchorLeft, "creature", AnchorRight)
		fam:addAnchor(AnchorVerticalCenter, "parent", AnchorVerticalCenter)
		fam:setMarginLeft(1)
		fam:show()
	else
		if fam then
			fam:breakAnchors()
			fam:hide()
		end

		creature:addAnchor(AnchorHorizontalCenter, "parent", AnchorHorizontalCenter)
		creature:addAnchor(AnchorVerticalCenter, "parent", AnchorVerticalCenter)
		creature:setMarginLeft(0)
	end

	if row.updateLayout then
		row:updateLayout()
	end
end

local function applyPresetListFamiliarThumb(widget, preset)
	local famWidget = getPresetButtonFamiliar(widget)

	if not famWidget then
		return
	end

	if not g_game.getFeature(GamePlayerFamiliars) then
		famWidget:hide()
		layoutPresetIconRowOutfitSingleOrDual(widget, false)

		return
	end

	local outfitTbl = preset and preset.outfit
	local fid = outfitTbl and outfitTbl.familiar or preset.familiar or 0

	if type(fid) == "string" then
		fid = tonumber(fid) or 0
	end

	if fid < 1 then
		layoutPresetIconRowOutfitSingleOrDual(widget, false)

		return
	end

	local fc = preset.familiarColorCache
	local h, b, l, f = 0, 0, 0, 0

	if fc and type(fc) == "table" then
		h = fc.head or 0
		b = fc.body or 0
		l = fc.legs or 0
		f = fc.feet or 0
	end

	famWidget:setOutfit({
		type = fid,
		head = h,
		body = b,
		legs = l,
		feet = f
	})
	makeThumbnailStatic(famWidget)

	local mainCreature = getPresetButtonCreature(widget)

	if mainCreature and mainCreature:getCreature() and famWidget:getCreature() then
		famWidget:getCreature():setDirection(mainCreature:getCreature():getDirection())
	end

	layoutPresetIconRowOutfitSingleOrDual(widget, true)
end

local function updatePresetManageActionButtonsEnabled()
	if not window or not window.presetButtons then
		return
	end

	local pb = window.presetButtons
	local renameBtn = pb.presetRename
	local saveBtn = pb.presetSave
	local deleteBtn = pb.presetDelete

	if not renameBtn or not saveBtn or not deleteBtn then
		return
	end

	local list = window.presetsList
	local hasSelection = list and list:isVisible() and list:getFocusedChild() ~= nil

	renameBtn:setEnabled(hasSelection)
	saveBtn:setEnabled(hasSelection)
	deleteBtn:setEnabled(hasSelection)
end

function newPreset()
	if not settings.presets then
		settings.presets = {}
	end

	local presetWidget = g_ui.createWidget("PresetButton", window.presetsList)
	local presetId = #settings.presets + 1

	presetWidget:setId(presetId)
	presetWidget.title:setText("Preset")
	applyOutfitColorsToTemp()
	applyMountColorsToOutfitTable(tempOutfit)

	local outfitCopy = table.copy(tempOutfit)

	getPresetButtonCreature(presetWidget):setOutfit(outfitCopy)
	makeThumbnailStatic(getPresetButtonCreature(presetWidget))

	settings.presets[presetId] = {
		familiar = 0,
		title = "Preset",
		outfit = outfitCopy,
		mounted = window.configure.mount.check:isChecked()
	}

	applyPresetListFamiliarThumb(presetWidget, settings.presets[presetId])
	window.presetsList:ensureChildVisible(presetWidget, {
		y = 0,
		x = 0
	})
	updatePresetManageActionButtonsEnabled()
end

function deletePreset()
	local presetId = settings.currentPreset

	if presetId == 0 then
		local focused = window.presetsList:getFocusedChild()

		if focused then
			presetId = tonumber(focused:getId())
		end
	end

	if not presetId or presetId == 0 then
		return
	end

	table.remove(settings.presets, presetId)
	window.presetsList[presetId]:destroy()

	settings.currentPreset = 0

	local newId = 1

	for _, child in ipairs(window.presetsList:getChildren()) do
		child:setId(newId)

		newId = newId + 1
	end

	updateAppearanceText("preset", "No Preset")
	updatePresetManageActionButtonsEnabled()
end

function savePreset()
	local presetId = settings.currentPreset

	if presetId == 0 then
		local focused = window.presetsList:getFocusedChild()

		if focused then
			presetId = tonumber(focused:getId())
		end
	end

	if not presetId or presetId == 0 then
		return
	end

	local listCreature = getPresetButtonCreature(window.presetsList[presetId])

	applyOutfitColorsToTemp()
	applyMountColorsToOutfitTable(tempOutfit)

	local outfitCopy = table.copy(tempOutfit)

	listCreature:setOutfit(outfitCopy)
	makeThumbnailStatic(listCreature)

	settings.presets[presetId].outfit = outfitCopy
	settings.presets[presetId].mounted = window.configure.mount.check:isChecked()

	if g_game.getFeature(GamePlayerFamiliars) then
		local fid = tempOutfit.familiar or 0

		settings.presets[presetId].familiar = fid

		if fid > 0 then
			settings.presets[presetId].familiarColorCache = {
				head = familiarColorCache.head or 0,
				body = familiarColorCache.body or 0,
				legs = familiarColorCache.legs or 0,
				feet = familiarColorCache.feet or 0
			}
		else
			settings.presets[presetId].familiarColorCache = nil
		end
	else
		settings.presets[presetId].familiar = tempOutfit.familiar or 0
	end

	settings.currentPreset = presetId

	applyPresetListFamiliarThumb(window.presetsList[presetId], settings.presets[presetId])
end

function cancelRenamePresetModal()
	pendingRenamePresetId = nil

	if not window or not window.renamePresetModal then
		return
	end

	local modal = window.renamePresetModal

	if modal.renamePresetInput then
		modal.renamePresetInput:setText("")
	end

	modal:hide()
end

function confirmRenamePresetModal()
	if not window or not window.renamePresetModal or not pendingRenamePresetId then
		cancelRenamePresetModal()

		return
	end

	local presetId = pendingRenamePresetId
	local modal = window.renamePresetModal
	local newTitle = modal.renamePresetInput:getText():trim()

	modal.renamePresetInput:setText("")
	modal:hide()

	pendingRenamePresetId = nil

	local presetWidget = window.presetsList[presetId]

	if not presetWidget then
		return
	end

	presetWidget.title:setText(newTitle)

	settings.presets[presetId].title = newTitle

	if presetId == settings.currentPreset then
		updateAppearanceText("preset", newTitle)
	end
end

function renamePreset()
	if not window then
		return
	end

	local presetId = settings.currentPreset

	if presetId == 0 then
		local focused = window.presetsList:getFocusedChild()

		if focused then
			presetId = tonumber(focused:getId())
		end
	end

	if not presetId or presetId == 0 then
		return
	end

	if not window.renamePresetModal then
		return
	end

	local preset = settings.presets and settings.presets[presetId]
	local initial = preset and preset.title or ""

	pendingRenamePresetId = presetId

	local modal = window.renamePresetModal

	modal.renamePresetInput:setText(initial)
	modal:show()
	modal:raise()
	modal.renamePresetInput:focus()
end

function onAppearanceChange(widget, selectedWidget)
	local id = selectedWidget:getParent():getId()

	if id == "preset" then
		showPresets()
	elseif id == "outfit" then
		showOutfits()
	elseif id == "mount" then
		showMounts()
	elseif id == "familiar" then
		showFamiliars()
	end

	updateColorControlsState()
	refreshColorBoxForCurrentContext()
end

function showPresets()
	clearSelectionHydrationEvent()
	selectionTextureCache.releaseHydration()
	window.listSearch:hide()
	window.selectionList:hide()
	window.selectionScroll:hide()

	if window.presetsList:getChildCount() == 0 and settings.presets then
		for presetId, preset in ipairs(settings.presets) do
			local presetWidget = g_ui.createWidget("PresetButton", window.presetsList)

			presetWidget:setId(presetId)
			presetWidget.title:setText(preset.title)

			local rowCreature = getPresetButtonCreature(presetWidget)

			rowCreature:setOutfit(preset.outfit)
			makeThumbnailStatic(rowCreature)
			applyPresetListFamiliarThumb(presetWidget, preset)
		end
	end

	window.presetsList.onChildFocusChange = nil

	local pid = settings.currentPreset
	local toFocus

	if pid and pid > 0 then
		toFocus = window.presetsList[pid]
	end

	if toFocus and not toFocus:isDestroyed() then
		toFocus:focus()
	else
		window.presetsList:focusChild(nil)
	end

	window.presetsList.onChildFocusChange = onPresetSelect

	window.presetsList:show()
	window.presetsScroll:show()
	window.presetButtons:show()
	updatePresetManageActionButtonsEnabled()
	addEvent(function()
		if not window or not window.presetsList or not window.presetsScroll then
			return
		end

		if window.presetsList:isVisible() and window.presetsScroll:isVisible() then
			local min = window.presetsScroll:getMinimum()

			if window.presetsScroll:getValue() == min then
				local vo = window.presetsList:getVirtualOffset()

				if vo and vo.y ~= 0 then
					vo.y = 0

					window.presetsList:setVirtualOffset(vo)
				end
			end
		end
	end)
end

function showOutfits()
	window.presetsList:hide()
	window.presetsScroll:hide()
	window.presetButtons:hide()

	local listGrid = getSelectionListGrid()

	if not listGrid then
		return
	end

	setSelectionListFocusHandler(nil)
	clearSelectionWarmupEvent()
	clearSelectionHydrationEvent()
	selectionTextureCache.releaseHydration()
	listGrid:destroyChildren()
	beginSelectionListBuild()

	local focused
	local sortedOutfits = {}

	for _, outfitData in ipairs(ServerData.outfits) do
		table.insert(sortedOutfits, outfitData)
	end

	table.sort(sortedOutfits, function(a, b)
		local stateA = a[4]

		if stateA == nil then
			stateA = statesOutft.available
		end

		local stateB = b[4]

		if stateB == nil then
			stateB = statesOutft.available
		end

		local availableA = stateA == statesOutft.available
		local availableB = stateB == statesOutft.available

		if availableA ~= availableB then
			return availableA
		end

		if a[1] ~= b[1] then
			return a[1] < b[1]
		end

		return tostring(a[2] or "") < tostring(b[2] or "")
	end)
	buildSelectionListBatched(sortedOutfits, function(outfitData)
		local button = g_ui.createWidget("SelectionButton", listGrid)

		button:setId(outfitData[1])

		local outfit = table.copy(tempOutfit)
		local availableAddons = outfitData[3] or 0

		outfit.type = outfitData[1]
		outfit.addons = 0

		local h, b, l, f = headBodyForListThumbnail(outfitData[1], outfitColorCache)

		outfit.head, outfit.body, outfit.legs, outfit.feet = h, b, l, f
		outfit.mount = 0
		outfit.familiar = 0
		button.selectionAvailableAddons = availableAddons
		button.selectionOutfitData = outfit

		markSelectionButtonDeferred(button, outfit)
		makeThumbnailStatic(button.outfit)

		local state = outfitData[4]

		if state then
			button.state = state

			if state ~= statesOutft.available then
				button:setImageSource("/images/ui/button-blue-up")
			end
		end

		button.name:setText(outfitData[2])

		if tempOutfit.type == outfitData[1] then
			focused = outfitData[1]

			configureAddons(outfitData[3])
		end
	end, function()
		local function enableOutfitSelectionHandler()
			setSelectionListFocusHandler(onOutfitSelect)
		end

		setSelectionListFocusHandler(nil)

		if focused then
			local grid = getSelectionListGrid()
			local w = grid and grid[focused]

			if w then
				hydrateSelectionButton(w)
				w:focus()
				window.selectionList:ensureChildVisible(w, {
					y = 196,
					x = 0
				})
			end

			local focusedId = focused

			addEvent(function()
				if not window or not window.selectionList or not window.selectionList:isVisible() then
					enableOutfitSelectionHandler()

					return
				end

				local grid = getSelectionListGrid()
				local delayedFocused = grid and grid[focusedId]

				if delayedFocused then
					delayedFocused:focus()
					window.selectionList:ensureChildVisible(delayedFocused, {
						y = 196,
						x = 0
					})
				end

				enableOutfitSelectionHandler()
			end)
		else
			enableOutfitSelectionHandler()
		end

		window.selectionList:show()
		window.selectionScroll:show()
		resetSelectionListScrollPosition()
		scheduleSelectionListHydration("showOutfits")
		startSelectionWarmupPump("outfits")
		window.listSearch:setText("Filter Outfits")
		window.listSearch:show()
	end)
end

function showMounts()
	window.presetsList:hide()
	window.presetsScroll:hide()
	window.presetButtons:hide()

	local mountCheck = window.configure and window.configure.mount and window.configure.mount.check
	local previousMountChecked = mountCheck and mountCheck:isChecked() or false
	local cyclopediaMountFocus

	if activeCyclopediaPending and activeCyclopediaPending.tabType == "mounts" then
		cyclopediaMountFocus = {
			lookType = activeCyclopediaPending.lookType,
			name = activeCyclopediaPending.name
		}
		previousMountChecked = true
	end

	local listGrid = getSelectionListGrid()

	if not listGrid then
		return
	end

	setSelectionListFocusHandler(nil)
	clearSelectionWarmupEvent()
	clearSelectionHydrationEvent()
	selectionTextureCache.releaseHydration()
	listGrid:destroyChildren()
	beginSelectionListBuild()

	local focused
	local sortedMounts = {}

	for _, mountData in ipairs(ServerData.mounts) do
		table.insert(sortedMounts, mountData)
	end

	table.sort(sortedMounts, function(a, b)
		local stateA = a[3]

		if stateA == nil then
			stateA = statesOutft.available
		end

		local stateB = b[3]

		if stateB == nil then
			stateB = statesOutft.available
		end

		local availableA = stateA == statesOutft.available
		local availableB = stateB == statesOutft.available

		if availableA ~= availableB then
			return availableA
		end

		if a[1] ~= b[1] then
			return a[1] < b[1]
		end

		return tostring(a[2] or "") < tostring(b[2] or "")
	end)
	buildSelectionListBatched(sortedMounts, function(mountData)
		local button = g_ui.createWidget("SelectionButton", listGrid)

		button:setId(mountData[1])

		local h, b, l, f = headBodyForListThumbnail(mountData[1], mountColorCache)
		local mountOutfit = {
			type = mountData[1],
			head = h,
			body = b,
			legs = l,
			feet = f
		}

		button.selectionOutfitData = mountOutfit

		markSelectionButtonDeferred(button, mountOutfit)
		makeThumbnailStatic(button.outfit)
		button.name:setText(mountData[2])

		if tempOutfit.mount == mountData[1] then
			focused = mountData[1]
		end

		local state = mountData[3]

		if state then
			button.state = state

			if state ~= statesOutft.available then
				button:setImageSource("/images/ui/button-blue-up")
			end
		end
	end, function()
		if cyclopediaMountFocus then
			tempOutfit.mount = cyclopediaMountFocus.lookType
			focused = cyclopediaMountFocus.lookType
		end

		if focused == nil and #sortedMounts > 0 then
			local firstMount = sortedMounts[1]

			tempOutfit.mount = firstMount[1]
			focused = firstMount[1]

			updateAppearanceText("mount", firstMount[2] or "None")
		end

		if #ServerData.mounts == 1 then
			clearSelectionListFocus()
		end

		if mountCheck then
			mountCheck:setEnabled(focused ~= nil)

			local showMounted = previousMountChecked

			if cyclopediaMountFocus then
				showMounted = true
			end

			mountCheck:setChecked(showMounted and focused ~= nil)
		end

		updatePreview()

		if cyclopediaMountFocus and cyclopediaMountFocus.name then
			updateAppearanceText("mount", cyclopediaMountFocus.name)
			updateMountAppearanceNameVisual(tempOutfit.mount)
		end

		if focused ~= nil then
			local grid = getSelectionListGrid()
			local w = grid and grid[focused]

			if w then
				hydrateSelectionButton(w)
				w:focus()
				window.selectionList:ensureChildVisible(w, {
					y = 196,
					x = 0
				})
			end
		end

		setSelectionListFocusHandler(onMountSelect)
		window.selectionList:show()
		window.selectionScroll:show()
		resetSelectionListScrollPosition()
		scheduleSelectionListHydration("showMounts")
		startSelectionWarmupPump("mounts")
		window.listSearch:setText("Filter Mounts")
		window.listSearch:show()
	end)
end

function showFamiliars()
	window.presetsList:hide()
	window.presetsScroll:hide()
	window.presetButtons:hide()

	local listGrid = getSelectionListGrid()

	if not listGrid then
		return
	end

	setSelectionListFocusHandler(nil)
	clearSelectionWarmupEvent()
	clearSelectionHydrationEvent()
	selectionTextureCache.releaseHydration()
	listGrid:destroyChildren()
	beginSelectionListBuild()

	if table.empty(ServerData.familiars) then
		window.selectionList:hide()
		window.selectionScroll:hide()
		window.listSearch:hide()

		return
	end

	local focused

	buildSelectionListBatched(ServerData.familiars, function(familiarData)
		local button = g_ui.createWidget("SelectionButton", listGrid)

		button:setId(familiarData[1])

		local h, b, l, f = headBodyForListThumbnail(familiarData[1], familiarColorCache)
		local familiarOutfit = {
			type = familiarData[1],
			head = h,
			body = b,
			legs = l,
			feet = f
		}

		button.selectionOutfitData = familiarOutfit

		markSelectionButtonDeferred(button, familiarOutfit)
		makeThumbnailStatic(button.outfit)
		button.name:setText(familiarData[2])

		if tempOutfit.familiar == familiarData[1] then
			focused = familiarData[1]
		end
	end, function()
		if #ServerData.familiars == 1 and (tempOutfit.familiar or 0) == 0 then
			clearSelectionListFocus()
		end

		if focused then
			local grid = getSelectionListGrid()
			local w = grid and grid[focused]

			if w then
				hydrateSelectionButton(w)
				w:focus()
				window.selectionList:ensureChildVisible(w, {
					y = 196,
					x = 0
				})
			end
		end

		setSelectionListFocusHandler(onFamiliarSelect)
		window.selectionList:show()
		window.selectionScroll:show()
		resetSelectionListScrollPosition()
		scheduleSelectionListHydration("showFamiliars")
		startSelectionWarmupPump("familiars")
		window.listSearch:setText("Filter Familiars")
		window.listSearch:show()
	end)
end

function refreshFilterListForCurrentColorChange()
	if not appearanceGroup or not window then
		return
	end

	local w = appearanceGroup:getSelectedWidget()

	if not w or not w.getParent then
		return
	end

	local id = w:getParent():getId()

	if id == "outfit" then
		showOutfits()
	elseif id == "mount" then
		showMounts()
	elseif id == "familiar" then
		showFamiliars()
	end
end

function onPresetSelect(list, focusedChild, unfocusedChild, reason)
	if focusedChild then
		local presetId = tonumber(focusedChild:getId())
		local preset = settings.presets[presetId]

		tempOutfit = table.copy(preset.outfit)

		initColorCachesFromOutfit(tempOutfit)
		applyOutfitColorsToTemp()

		if preset.familiarColorCache and type(preset.familiarColorCache) == "table" then
			familiarColorCache.head = preset.familiarColorCache.head or 0
			familiarColorCache.body = preset.familiarColorCache.body or 0
			familiarColorCache.legs = preset.familiarColorCache.legs or 0
			familiarColorCache.feet = preset.familiarColorCache.feet or 0
		elseif (tempOutfit.familiar or 0) > 0 then
			familiarColorCache.head = 0
			familiarColorCache.body = 0
			familiarColorCache.legs = 0
			familiarColorCache.feet = 0
		end

		for _, outfitData in ipairs(ServerData.outfits) do
			if tempOutfit.type == outfitData[1] then
				configureAddons(outfitData[3])

				break
			end
		end

		if g_game.getFeature(GamePlayerMounts) then
			window.configure.mount.check:setChecked(preset.mounted and tempOutfit.mount > 0)
		end

		settings.currentPreset = presetId

		updatePreview()
		updateAppearanceTexts(tempOutfit)
		updateColorControlsState()
		refreshColorBoxForCurrentContext()
	end

	updatePresetManageActionButtonsEnabled()
end

function onOutfitSelect(list, focusedChild, unfocusedChild, reason)
	if focusedChild then
		hydrateSelectionButton(focusedChild)

		local outfit = focusedChild.selectionOutfitData
		local availableAddons = focusedChild.selectionAvailableAddons

		if not outfit then
			local creature = focusedChild.outfit and focusedChild.outfit:getCreature()

			outfit = creature and creature:getOutfit()
		end

		if not outfit then
			return
		end

		if availableAddons == nil then
			availableAddons = outfit.addons or 0
		end

		memoryScenarioSelectionSequence = memoryScenarioSelectionSequence + 1

		traceMemoryScenario("outfit-select", string.format("sequence=%d type=%s movement=%s reason=%s", memoryScenarioSelectionSequence, tostring(outfit.type or 0), tostring(settings and settings.movement == true), tostring(reason)))

		tempOutfit.type = outfit.type
		tempOutfit.addons = math.min(tempOutfit.addons or 0, availableAddons)

		configureAddons(availableAddons)
		updatePreview()
		updateAppearanceText("outfit", focusedChild.name:getText())
		updateColorControlsState()
		refreshColorBoxForCurrentContext()
	end
end

function onMountSelect(list, focusedChild, unfocusedChild, reason)
	if focusedChild then
		local mountType = tonumber(focusedChild:getId())

		tempOutfit.mount = mountType

		local mountCheck = window and window.configure and window.configure.mount and window.configure.mount.check

		if mountCheck then
			local previousMountChecked = mountCheck:isChecked()

			mountCheck:setEnabled(tempOutfit.mount > 0)
			mountCheck:setChecked(previousMountChecked and tempOutfit.mount > 0)
		end

		updatePreview()
		updateAppearanceText("mount", focusedChild.name:getText())
		updateMountAppearanceNameVisual(mountType)
		updateColorControlsState()
		refreshColorBoxForCurrentContext()
	end
end

function onFamiliarSelect(list, focusedChild, unfocusedChild, reason)
	if focusedChild then
		local familiarType = tonumber(focusedChild:getId())

		tempOutfit.familiar = familiarType

		previewFamiliar:setOutfit({
			type = familiarType
		})

		if previewFamiliar:getCreature() then
			local fo = previewFamiliar:getCreature():getOutfit()

			if fo then
				familiarColorCache.head = fo.head or 0
				familiarColorCache.body = fo.body or 0
				familiarColorCache.legs = fo.legs or 0
				familiarColorCache.feet = fo.feet or 0
			end
		end

		updateColorControlsState()
		refreshColorBoxForCurrentContext()
		updatePreview()
		updateAppearanceText("familiar", focusedChild.name:getText())
	end
end

function updateAppearanceText(widget, text)
	if window.appearance.settings[widget] then
		window.appearance.settings[widget].name:setText(text)

		if widget == "mount" then
			updateMountAppearanceNameVisual(tempOutfit and tempOutfit.mount or 0)
		elseif widget == "outfit" then
			updateOutfitAppearanceNameVisual(tempOutfit and tempOutfit.type or 0)
		end
	end
end

function updateAppearanceTexts(outfit)
	for _, appKey in ipairs(AppearanceData) do
		if appKey ~= "preset" then
			updateAppearanceText(appKey, "None")
		end
	end

	local serverListKey = {
		familiar = "familiars",
		mount = "mounts"
	}

	for key, value in pairs(outfit) do
		local listKey = serverListKey[key] or key
		local appKey = key

		if key == "type" then
			listKey = "outfits"
			appKey = "outfit"
		end

		local dataTable = ServerData[listKey]

		if dataTable then
			for _, data in ipairs(dataTable) do
				if (outfit[key] == data[1] or outfit[key] == data[2]) and appKey and data[2] then
					updateAppearanceText(appKey, data[2])
				end
			end
		end
	end

	local presetId = settings.currentPreset

	if presetId and presetId > 0 and settings.presets and settings.presets[presetId] then
		updateAppearanceText("preset", settings.presets[presetId].title)
	else
		updateAppearanceText("preset", "No Preset")
	end
end

function onAddonChange(widget, checked)
	local addonId = widget:getParent():getId()
	local addons = tempOutfit.addons

	if addonId == "addon1" then
		addons = checked and addons + 1 or addons - 1
	elseif addonId == "addon2" then
		addons = checked and addons + 2 or addons - 2
	end

	tempOutfit.addons = addons

	updatePreview()

	if appearanceGroup:getSelectedWidget() == window.appearance.settings.outfit.check then
		showOutfits()
	end
end

function onColorModeChange(widget, selectedWidget)
	if colorPickerProgrammatic or not selectedWidget then
		return
	end

	if not isColorContextActive() then
		return
	end

	local app = getAppearanceCategoryName()
	local cache = getColorCacheForAppearance(app)

	if not cache then
		return
	end

	local colorMode = selectedWidget:getId()
	local id = getColorIdFromMode(cache, colorMode)
	local box = window.appearance.colorSection.colorBoxBackground.colorBoxPanel["colorBox" .. id]

	if box and colorBoxGroup then
		colorPickerProgrammatic = true

		colorBoxGroup:selectWidget(box)

		colorPickerProgrammatic = false
	end
end

function onColorCheckChange(widget, selectedWidget)
	if colorPickerProgrammatic or not selectedWidget then
		return
	end

	if not isColorContextActive() then
		return
	end

	local colorId = selectedWidget.colorId
	local colorMode = colorModeGroup:getSelectedWidget():getId()
	local app = getAppearanceCategoryName()
	local cache = getColorCacheForAppearance(app)

	if not cache then
		return
	end

	applyColorIdToMode(cache, colorMode, colorId)

	if app == "outfit" then
		applyOutfitColorsToTemp()
	end

	updatePreview()
	refreshFilterListForCurrentColorChange()
end

function prepareMovementThingType(lookType)
	lookType = tonumber(lookType) or 0

	if lookType <= 0 then
		return true
	end

	local thingType = g_things.getThingType(lookType, ThingCategoryCreature)

	if not thingType then
		return true
	end

	return thingType:preparePreviewMovementTexture()
end

function isPreviewMovementReady(previewOutfit, showPreviewCreature)
	if podiumContext or hirelingContext or not settings.movement then
		return true
	end

	local ready = true

	if showPreviewCreature then
		if not prepareMovementThingType(previewOutfit.type) then
			ready = false
		end

		if (previewOutfit.mount or 0) > 0 and not prepareMovementThingType(previewOutfit.mount) then
			ready = false
		end
	end

	if previewFamiliar and settings.showFamiliar and (previewOutfit.familiar or 0) > 0 and not prepareMovementThingType(previewOutfit.familiar) then
		ready = false
	end

	return ready
end

function schedulePreviewMovementRetry(token)
	if token ~= previewMovementWarmup.token or previewMovementWarmup.event then
		return
	end

	previewMovementWarmup.event = scheduleEvent(function()
		previewMovementWarmup.event = nil

		if token ~= previewMovementWarmup.token or not window then
			return
		end

		applyPreviewUpdate(token)
	end, previewMovementWarmup.retryMs)
end

function applyPreviewUpdate(token)
	if token ~= previewMovementWarmup.token or not window or not previewCreature then
		return
	end

	if podiumContext and podiumOutfitCheck then
		settings.showOutfit = getPodiumShowOutfit()
	end

	syncShowOutfitOptionState()

	local direction = previewCreature:getDirection()

	applyOutfitColorsToTemp()

	local previewOutfit = table.copy(tempOutfit)

	previewOutfit.head = outfitColorCache.head
	previewOutfit.body = outfitColorCache.body
	previewOutfit.legs = outfitColorCache.legs
	previewOutfit.feet = outfitColorCache.feet

	local showOutfitLayers = settings.showOutfit
	local showPreviewCreature = settings.showOutfit

	if podiumContext then
		ensurePodiumMountSelection()

		showOutfitLayers = getPodiumShowOutfit()
		showPreviewCreature = showOutfitLayers or isPodiumMountShown()

		if not getPodiumShowMount() then
			previewOutfit.mount = 0
		end

		if not showOutfitLayers then
			previewOutfit.addons = 0
		end
	end

	if not podiumContext and g_game.getFeature(GamePlayerMounts) and window and window.configure and window.configure.mount and window.configure.mount.check and not window.configure.mount.check:isChecked() then
		previewOutfit.mount = 0
	end

	applyMountColorsToOutfitTable(previewOutfit)

	if not isPreviewMovementReady(previewOutfit, showPreviewCreature) then
		schedulePreviewMovementRetry(token)

		return
	end

	if showPreviewCreature then
		previewCreature:show()
	else
		previewCreature:hide()
	end

	if previewFamiliar then
		if not settings.showFamiliar then
			previewOutfit.familiar = 0

			previewFamiliar:setVisible(settings.showFamiliar)
		elseif previewOutfit.familiar and previewOutfit.familiar > 0 then
			previewFamiliar:setOutfit({
				type = previewOutfit.familiar,
				head = familiarColorCache.head,
				body = familiarColorCache.body,
				legs = familiarColorCache.legs,
				feet = familiarColorCache.feet
			})
			previewFamiliar:setVisible(true)
		end
	end

	if previewRow then
		if podiumContext then
			previewRow:setWidth(262)
			previewRow:setMarginLeft(1)
		else
			local gapBetweenCreatures = 1
			local showDual = settings.showFamiliar and (previewOutfit.familiar or 0) > 0

			previewRow:setWidth(showDual and 128 + gapBetweenCreatures + 128 or 128)
			previewRow:setMarginLeft(showDual and 2 or 1)
		end
	end

	previewCreature:setOutfit(previewOutfit)

	local previewCreaturePtr = previewCreature:getCreature()

	previewCreaturePtr:setDirection(direction)

	local mountShown = (previewOutfit.mount or 0) > 0

	if podiumContext then
		previewCreaturePtr:setDrawOutfitLayers(showOutfitLayers)
	else
		previewCreaturePtr:setDrawOutfitLayers(not mountShown or settings.showOutfit)
	end

	applyOutfitPreviewSpriteScale(previewCreature)

	if previewFamiliar and previewFamiliar:isVisible() and previewFamiliar:getCreature() then
		applyOutfitPreviewSpriteScale(previewFamiliar)
	end

	syncPreviewWalkingState()

	if podiumContext then
		previewCreaturePtr:setDrawOutfitLayers(showOutfitLayers)
		updatePodiumPreview()
	elseif previewPodiumWidget then
		previewPodiumWidget:setItemVisible(false)
		restoreNormalPreviewCreatureLayout()
	end
end

function updatePreview()
	clearPreviewMovementReadyEvent()
	applyPreviewUpdate(previewMovementWarmup.token)
end

function rotate(value)
	if not previewCreature or not previewCreature:getCreature() then
		return
	end

	local direction = previewCreature:getDirection()

	direction = direction + value

	if direction > Directions.West then
		direction = Directions.North
	elseif direction < Directions.North then
		direction = Directions.West
	end

	previewCreature:getCreature():setDirection(direction)

	if g_game.getFeature(GamePlayerFamiliars) and previewFamiliar and previewFamiliar:getCreature() then
		previewFamiliar:getCreature():setDirection(direction)
	end

	if podiumContext then
		updatePodiumPreview()
	end

	if floor then
		floor:setMargin(0)
		resetFloorScrollOffsets()
	end
end

function onFilterOnlyMine(self, checked)
	addEvent(function()
		if not window or not window.selectionList then
			return
		end

		local grid = getSelectionListGrid()

		if not grid then
			return
		end

		local children = grid:getChildren()

		for _, child in ipairs(children) do
			if checked and (not child.state or child.state ~= 0) then
				clearSelectionListFocus()
				child:hide()
			else
				child:show()
			end
		end

		scheduleSelectionListHydration("filterOnlyMine")
	end)
end

function onFilterSearch()
	addEvent(function()
		if not window or not window.listSearch or not window.listSearch.search or not window.selectionList then
			return
		end

		local searchText = window.listSearch.search:getText():lower():trim()
		local grid = getSelectionListGrid()

		if not grid then
			return
		end

		local children = grid:getChildren()

		if searchText:len() >= 1 then
			for _, child in ipairs(children) do
				local text = child.name:getText():lower()

				if text:find(searchText) then
					child:show()
				else
					child:hide()
				end
			end
		else
			for _, child in ipairs(children) do
				child:show()
			end
		end

		scheduleSelectionListHydration("filterSearch")
	end)
end

function clearFilterSearch()
	if not window or not window.listSearch then
		return
	end

	window.listSearch.search:setText("")
	onFilterSearch()
	window.listSearch.search:focus()
end

function saveSettings()
	if not g_resources.fileExists(settingsFile) then
		g_resources.makeDir("/settings")
		g_resources.writeFileContents(settingsFile, "[]")
	end

	local fullSettings = {}

	do
		local json_status, json_data = pcall(function()
			return json.decode(g_resources.readFileContents(settingsFile))
		end)

		if not json_status then
			g_logger.error("[saveSettings] Couldn't load JSON: " .. json_data)

			return
		end

		fullSettings = json_data
	end

	local persistedSettings = table.copy(settings)

	persistedSettings.movement = nil
	fullSettings[g_game.getCharacterName()] = persistedSettings

	local json_status, json_data = pcall(function()
		return json.encode(fullSettings)
	end)

	if not json_status then
		g_logger.error("[saveSettings] Couldn't save JSON: " .. json_data)

		return
	end

	g_resources.writeFileContents(settingsFile, json.encode(fullSettings))
end

function loadSettings()
	if not g_resources.fileExists(settingsFile) then
		g_resources.makeDir("/settings")
	end

	if g_resources.fileExists(settingsFile) then
		local json_status, json_data = pcall(function()
			return json.decode(g_resources.readFileContents(settingsFile))
		end)

		if not json_status then
			g_logger.error("[loadSettings] Couldn't load JSON: " .. json_data)

			return
		end

		settings = json_data[g_game.getCharacterName()]

		if not settings then
			loadDefaultSettings()
		else
			settings.movement = movementEnabledForSession
		end
	else
		loadDefaultSettings()
	end
end

function loadDefaultSettings()
	settings = {
		showOutfit = true,
		showFloor = true,
		currentPreset = 0,
		showFamiliar = true,
		movement = movementEnabledForSession,
		presets = {}
	}
	settings.currentPreset = 0
end

function accept()
	if cyclopediaViewMode then
		destroy()

		return
	end

	didAcceptCustomize = true

	local shouldToggleMount = false
	local isMountedChecked = false

	if not podiumContext and not hirelingContext and g_game.getFeature(GamePlayerMounts) and window and window.configure and window.configure.mount and window.configure.mount.check then
		isMountedChecked = window.configure.mount.check:isChecked()
		shouldToggleMount = true

		if settings.currentPreset > 0 then
			settings.presets[settings.currentPreset].mounted = isMountedChecked
		end
	end

	if g_game.getFeature(GamePlayerFamiliars) and settings.currentPreset > 0 then
		local p = settings.presets[settings.currentPreset]

		if p then
			local fid = tempOutfit.familiar or 0

			p.familiar = fid

			if fid > 0 then
				p.familiarColorCache = {
					head = familiarColorCache.head or 0,
					body = familiarColorCache.body or 0,
					legs = familiarColorCache.legs or 0,
					feet = familiarColorCache.feet or 0
				}
			else
				p.familiarColorCache = nil
			end
		end
	end

	local outfitToSend = buildOutfitPayloadForSend()
	local podiumRequest
	local isHirelingOutfit = hirelingContext ~= nil

	if podiumContext then
		local showPlatform = getEffectivePodiumShowPlatform()
		local showOutfit = getPodiumShowOutfit()
		local showMount = getPodiumShowMount()
		local direction = podiumContext.direction

		if previewCreature and previewCreature:getCreature() then
			direction = previewCreature:getDirection()
		end

		local podiumOutfit = table.copy(outfitToSend)

		if not showOutfit then
			podiumOutfit.type = 0
			podiumOutfit.addons = 0
		end

		if not showMount then
			podiumOutfit.mount = 0
		end

		applyMountColorsToOutfitTable(podiumOutfit)

		podiumRequest = {
			outfit = podiumOutfit,
			position = podiumContext.position,
			itemClientId = podiumContext.itemClientId,
			stackpos = podiumContext.stackpos,
			direction = direction,
			showPlatform = showPlatform,
			showOutfit = showOutfit
		}
	end

	ignoreNextOutfitWindow = g_clock.millis()

	destroy()
	addEvent(function()
		if g_modalManager and g_modalManager.pruneOrphanBlockers then
			g_modalManager.pruneOrphanBlockers()
		end

		if modules.game_containers and modules.game_containers.clearContainerDragHover then
			modules.game_containers.clearContainerDragHover()
		end

		if g_client and g_client.setInputLockWidget then
			pcall(function()
				g_client.setInputLockWidget(nil)
			end)
		end

		local draggingWidget = g_ui.getDraggingWidget()

		if draggingWidget and draggingWidget.hoveredWho then
			draggingWidget.hoveredWho:setBorderWidth(0)

			draggingWidget.hoveredWho = nil
		end
	end)

	if podiumRequest then
		g_game.changeOutfitPodium(podiumRequest.outfit, podiumRequest.position, podiumRequest.itemClientId, podiumRequest.stackpos, podiumRequest.direction, podiumRequest.showPlatform, podiumRequest.showOutfit)
	elseif isHirelingOutfit then
		g_game.changeHirelingOutfit(outfitToSend)
	else
		g_game.changeOutfit(outfitToSend)

		if shouldToggleMount then
			local player = g_game.getLocalPlayer()

			if player then
				if not player:isMounted() and isMountedChecked then
					player:mount()
				elseif player:isMounted() and not isMountedChecked then
					player:dismount()
				end
			end
		end
	end
end
