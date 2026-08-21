-- chunkname: @/game_customisepodium/game_customisepodium.lua

customisePodiumWindow = nil
currentThing = nil
selectedCreatureSlot = nil
initialRaceId = 0
creatureEntries = {}
podiumProtocolData = nil

local previewPodiumWidget, previewCreatureWidget, previewRow, previewFloor
local podiumRequestEvent
local podiumRequestPending = false
local previewFloorTiles = {}
local previewDirection = Directions.South
local previewOutfit, previewItem
local previewInitialized = false
local SLOT_CREATURE_DIRECTION = Directions.South
local showCreature = true
local showPodium = true
local showPodiumBeforeCreatureOff = true
local PODIUM_OPTION_ENABLED_COLOR = "#c0c0c0"
local PODIUM_OPTION_DISABLED_COLOR = "#707070"
local floorTileWidth = 318
local floorTileHeight = 128
local floorTileColumns = 3
local floorTileRows = 3
local floorOffsetX = 0
local floorOffsetY = 0

local function copyOutfit(outfit)
	if not outfit then
		return nil
	end

	return {
		type = outfit.type or 0,
		auxType = outfit.auxType or 0,
		head = outfit.head or 0,
		body = outfit.body or 0,
		legs = outfit.legs or 0,
		feet = outfit.feet or 0,
		addons = outfit.addons or 0,
		mount = outfit.mount or 0,
		mountHead = outfit.mountHead or 0,
		mountBody = outfit.mountBody or 0,
		mountLegs = outfit.mountLegs or 0,
		mountFeet = outfit.mountFeet or 0,
		familiar = outfit.familiar or 0,
		wings = outfit.wings or 0,
		aura = outfit.aura or 0,
		auras = outfit.auras or 0,
		effects = outfit.effects or 0,
		shaders = outfit.shaders or ""
	}
end

local function outfitHasDisplay(outfit)
	if not outfit then
		return false
	end

	return (outfit.type or 0) > 0 or (outfit.auxType or 0) > 0
end

local function outfitsMatch(a, b)
	if not a or not b then
		return false
	end

	return (a.type or 0) == (b.type or 0) and (a.auxType or 0) == (b.auxType or 0) and (a.head or 0) == (b.head or 0) and (a.body or 0) == (b.body or 0) and (a.legs or 0) == (b.legs or 0) and (a.feet or 0) == (b.feet or 0) and (a.addons or 0) == (b.addons or 0)
end

local function resolveCreatureEntry(entry, isBoss)
	local raceId = entry.raceId or 0
	local name = entry.name or ""
	local outfit = copyOutfit(entry.outfit)

	if raceId > 0 then
		local raceData = g_things.getRaceData(raceId)

		if raceData and raceData.raceId and raceData.raceId > 0 then
			if name == "" then
				name = raceData.name or ""
			end

			if not outfitHasDisplay(outfit) and raceData.outfit then
				outfit = copyOutfit(raceData.outfit)
			end
		end
	end

	if name == "" and raceId > 0 then
		name = string.format("Race %d", raceId)
	end

	return {
		id = raceId,
		raceId = raceId,
		name = name,
		outfit = outfit,
		isBoss = isBoss == true
	}
end

local function shouldIncludeEntry(entry)
	if not entry then
		return false
	end

	return (entry.raceId or 0) > 0 or outfitHasDisplay(entry.outfit) or (entry.name or "") ~= ""
end

local function getProtocolCreatures(data)
	if not data or not data.creatures then
		return {}
	end

	local creatures = {}

	for _, creature in ipairs(data.creatures) do
		table.insert(creatures, creature)
	end

	return creatures
end

local function buildCreatureEntries(creatures, isBoss)
	local entries = {}

	for _, entry in ipairs(creatures or {}) do
		local resolved = resolveCreatureEntry(entry, isBoss)

		if shouldIncludeEntry(resolved) then
			table.insert(entries, resolved)
		end
	end

	return entries
end

local function applyFloorRowScrollMargins()
	if not previewFloorTiles or #previewFloorTiles == 0 then
		return
	end

	for index, tile in ipairs(previewFloorTiles) do
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

local function layoutPreviewCreatureForPodium(showPlatform, item)
	if not previewCreatureWidget then
		return
	end

	previewCreatureWidget:breakAnchors()
	previewCreatureWidget:addAnchor(AnchorHorizontalCenter, "parent", AnchorHorizontalCenter)
	previewCreatureWidget:addAnchor(AnchorVerticalCenter, "parent", AnchorVerticalCenter)

	if showPlatform then
		local elevation = getPodiumPlatformElevation(item or previewItem)
		local previewOffset = elevation > 0 and elevation * 2 or 12

		previewCreatureWidget:setMarginLeft(-previewOffset)
		previewCreatureWidget:setMarginTop(-previewOffset)
	else
		previewCreatureWidget:setMarginLeft(0)
		previewCreatureWidget:setMarginTop(0)
	end

	if previewRow and previewRow.updateLayout then
		previewRow:updateLayout()
	end
end

local function setupPreviewFloor()
	if not customisePodiumWindow or customisePodiumWindow:isDestroyed() then
		return
	end

	previewFloor = customisePodiumWindow:recursiveGetChildById("floor")
	previewRow = customisePodiumWindow:recursiveGetChildById("previewRow")
	previewPodiumWidget = customisePodiumWindow:recursiveGetChildById("podiumPreview")
	previewCreatureWidget = customisePodiumWindow:recursiveGetChildById("creaturePreview")

	if not previewFloor or not previewPodiumWidget or not previewCreatureWidget then
		return
	end

	previewFloorTiles = {}

	for row = 1, floorTileRows do
		for col = 1, floorTileColumns do
			local tile = previewFloor["floorR" .. row .. "C" .. col]

			if tile then
				tile:setSize(string.format("%d %d", floorTileWidth, floorTileHeight))
				table.insert(previewFloorTiles, tile)
			end
		end
	end

	floorOffsetX = 0
	floorOffsetY = 0

	applyFloorRowScrollMargins()
	previewFloor:setSize(string.format("%d %d", floorTileColumns * floorTileWidth, floorTileRows * floorTileHeight))
	previewFloor:setMargin(0)
	previewFloor:hide()
	previewPodiumWidget:setVirtual(true)
	previewPodiumWidget:setPodiumPreview(true)
	previewPodiumWidget:setFixedItemSize(false)
	previewPodiumWidget:setSize("70 70")
	previewPodiumWidget:setItemVisible(false)
	previewCreatureWidget:hide()

	previewInitialized = true
end

local function applyPreviewCreatureScale(spriteWidget)
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

local CREATURE_LIST_INSET = 6
local CREATURE_LIST_INSET_SCROLLED = 1

local function applyCreatureListScrollInsets(panel, offsetY, offsetX)
	if not panel or panel:isDestroyed() then
		return
	end

	offsetY = offsetY or 0
	offsetX = offsetX or 0

	panel:setPaddingTop(offsetY > 0 and CREATURE_LIST_INSET_SCROLLED or CREATURE_LIST_INSET)
	panel:setPaddingLeft(offsetX > 0 and CREATURE_LIST_INSET_SCROLLED or CREATURE_LIST_INSET)
	panel:setPaddingRight(CREATURE_LIST_INSET_SCROLLED)
	panel:setPaddingBottom(CREATURE_LIST_INSET_SCROLLED)
end

local function setupCreatureListScrollInsets()
	local panel = getCreatureListPanel()

	if not panel then
		return
	end

	local offset = panel.getVirtualOffset and panel:getVirtualOffset() or {
		y = 0,
		x = 0
	}

	applyCreatureListScrollInsets(panel, offset.y, offset.x)

	function panel.onScrollChange(widget, virtualOffset)
		applyCreatureListScrollInsets(widget, virtualOffset.y, virtualOffset.x)
	end
end

local function ensureWindow()
	if customisePodiumWindow and not customisePodiumWindow:isDestroyed() then
		return
	end

	customisePodiumWindow = g_ui.createWidget("CustomisePodiumWindow", rootWidget)
	customisePodiumWindow.onEscape = hide

	setupPreviewFloor()
	setupCreatureListScrollInsets()
end

local function findPodiumThing(position, itemClientId)
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

local function getListThumbnailColors(lookId, outfit)
	if not lookId or lookId < 1 or not outfit then
		return 0, 0, 0, 0
	end

	if thingTypeHasVariableColors(getCreatureThingType(lookId)) then
		return outfit.head or 0, outfit.body or 0, outfit.legs or 0, outfit.feet or 0
	end

	return 0, 0, 0, 0
end

local function buildListThumbnailOutfit(outfit)
	local lookType = outfit.type or 0

	if lookType < 1 and (outfit.auxType or 0) > 0 then
		return {
			familiar = 0,
			type = 0,
			mount = 0,
			addons = 0,
			feet = 0,
			legs = 0,
			body = 0,
			head = 0,
			auxType = outfit.auxType or 0
		}
	end

	local head, body, legs, feet = getListThumbnailColors(lookType, outfit)

	return {
		familiar = 0,
		mount = 0,
		type = lookType,
		auxType = outfit.auxType or 0,
		head = head,
		body = body,
		legs = legs,
		feet = feet,
		addons = outfit.addons or 0
	}
end

local function setupSlotCreatureSprite(sprite, outfit)
	if not sprite or not outfitHasDisplay(outfit) then
		return
	end

	sprite:setOutfit(buildListThumbnailOutfit(outfit))

	local creature = sprite:getCreature()

	if creature then
		creature:setStaticWalking(0)
		creature:setDirection(SLOT_CREATURE_DIRECTION)
	end
end

local function buildPreviewItem(thing, itemClientId)
	if thing and thing.isItem and thing:isItem() and thing.clone then
		return thing:clone()
	end

	if itemClientId and itemClientId > 0 then
		return Item.create(itemClientId)
	end

	return nil
end

local function getPreviewOutfit()
	if previewOutfit and outfitHasDisplay(previewOutfit) then
		return previewOutfit
	end

	if previewItem and previewItem.hasPodiumDisplay and previewItem:hasPodiumDisplay() then
		return copyOutfit(previewItem:getPodiumOutfit())
	end

	return nil
end

local function findEntryOutfitForRaceId(raceId)
	if not raceId or raceId <= 0 then
		return nil
	end

	for _, entry in ipairs(creatureEntries) do
		if (entry.raceId or entry.id or 0) == raceId and outfitHasDisplay(entry.outfit) then
			return copyOutfit(entry.outfit)
		end
	end

	return nil
end

local function getPreviewCreatureOutfit()
	local outfit = getPreviewOutfit()

	if not outfit then
		return nil
	end

	if (outfit.type or 0) > 0 then
		return outfit
	end

	if selectedCreatureSlot and outfitHasDisplay(selectedCreatureSlot.creatureOutfit) and (selectedCreatureSlot.creatureOutfit.type or 0) > 0 then
		return copyOutfit(selectedCreatureSlot.creatureOutfit)
	end

	local raceId = initialRaceId

	raceId = selectedCreatureSlot and (selectedCreatureSlot.raceId or selectedCreatureSlot.creatureId) or raceId

	local entryOutfit = findEntryOutfitForRaceId(raceId)

	if entryOutfit and (entryOutfit.type or 0) > 0 then
		return entryOutfit
	end

	return outfitHasDisplay(outfit) and outfit or nil
end

local function creatureWouldDisplay()
	if not showCreature then
		return false
	end

	return outfitHasDisplay(getPreviewCreatureOutfit())
end

local function getEffectivePodiumFlags()
	local effectiveShowCreature = showCreature
	local effectiveShowPlatform = showPodium

	if not effectiveShowCreature then
		effectiveShowPlatform = true
	elseif not creatureWouldDisplay() then
		effectiveShowPlatform = true
	end

	return effectiveShowPlatform, effectiveShowCreature
end

local function applyOpenStateFromTileItem(data)
	if not previewItem or not previewItem.hasPodiumDisplay or not previewItem:hasPodiumDisplay() then
		showCreature = data.showCreature ~= false
		showPodium = data.showPlatform ~= false

		return copyOutfit(data.podiumOutfit)
	end

	local outfit = copyOutfit(previewItem:getPodiumOutfit())

	if not outfitHasDisplay(outfit) then
		outfit = copyOutfit(data.podiumOutfit)
	end

	previewDirection = previewItem:getPodiumDirection() or previewDirection
	showPodium = previewItem:isPodiumShowPlatform()

	if previewItem.isPodiumShowCreature then
		showCreature = previewItem:isPodiumShowCreature()
	else
		showCreature = data.showCreature ~= false
	end

	return outfit
end

local function resolveInitialRaceId(outfit, entries)
	if not outfitHasDisplay(outfit) then
		return 0
	end

	for _, entry in ipairs(entries or {}) do
		if outfitsMatch(entry.outfit, outfit) then
			return entry.raceId or entry.id or 0
		end
	end

	return 0
end

local function resolveOpenPreviewOutfit(outfit)
	initialRaceId = resolveInitialRaceId(outfit, creatureEntries)

	if initialRaceId > 0 then
		local entryOutfit = findEntryOutfitForRaceId(initialRaceId)

		if entryOutfit then
			return entryOutfit
		end
	end

	return outfit
end

function updatePreview()
	if not previewInitialized or not previewPodiumWidget then
		return
	end

	if not previewItem then
		previewItem = buildPreviewItem(currentThing, podiumProtocolData and podiumProtocolData.itemClientId)
	end

	if not previewItem then
		previewPodiumWidget:setItemVisible(false)

		if previewCreatureWidget then
			previewCreatureWidget:hide()
		end

		layoutPreviewCreatureForPodium(false, previewItem)

		return
	end

	local outfit = getPreviewCreatureOutfit()
	local hasOutfit = outfitHasDisplay(outfit)
	local isBossPodium = podiumProtocolData and podiumProtocolData.isBoss
	local podiumSize = isBossPodium and 70 or 68
	local podiumMargin = isBossPodium and 29 or 30

	previewItem:setPodium({}, previewDirection, showPodium, false)
	previewPodiumWidget:setSize(string.format("%d %d", podiumSize, podiumSize))
	previewPodiumWidget:setMarginTop(podiumMargin)
	previewPodiumWidget:setMarginLeft(podiumMargin)
	previewPodiumWidget:setItem(previewItem)
	previewPodiumWidget:setItemVisible(showPodium)

	if previewRow then
		previewRow:setWidth(262)
		previewRow:setMarginLeft(1)
	end

	if previewCreatureWidget then
		if showCreature and hasOutfit then
			previewCreatureWidget:setOutfit(copyOutfit(outfit))

			local creature = previewCreatureWidget:getCreature()

			if creature then
				creature:setDirection(previewDirection)
				creature:setStaticWalking(0)
			end

			applyPreviewCreatureScale(previewCreatureWidget)
			previewCreatureWidget:show()
		else
			previewCreatureWidget:hide()
		end
	end

	layoutPreviewCreatureForPodium(showPodium, previewItem)
end

function rotate(value)
	if not previewInitialized then
		return
	end

	previewDirection = previewDirection + value

	if previewDirection > Directions.West then
		previewDirection = Directions.North
	elseif previewDirection < Directions.North then
		previewDirection = Directions.West
	end

	updatePreview()
end

local function syncShowPodiumOptionState()
	if not customisePodiumWindow or customisePodiumWindow:isDestroyed() then
		return
	end

	local showPodiumCheck = customisePodiumWindow:recursiveGetChildById("showPodiumCheck")
	local showPodiumLabel = customisePodiumWindow:recursiveGetChildById("showPodiumLabel")

	if not showPodiumCheck then
		return
	end

	if showCreature and creatureWouldDisplay() then
		showPodiumCheck:setEnabled(true)
		showPodiumCheck:setColor(PODIUM_OPTION_ENABLED_COLOR)

		if showPodiumLabel then
			showPodiumLabel:setColor(PODIUM_OPTION_ENABLED_COLOR)
		end

		showPodiumCheck:setChecked(showPodium)

		return
	end

	showPodium = true

	showPodiumCheck:setChecked(true)
	showPodiumCheck:setEnabled(false)
	showPodiumCheck:setColor(PODIUM_OPTION_DISABLED_COLOR)

	if showPodiumLabel then
		showPodiumLabel:setColor(PODIUM_OPTION_DISABLED_COLOR)
	end
end

local function syncConfigurePanel(defaultShowFloor)
	if not customisePodiumWindow or customisePodiumWindow:isDestroyed() then
		return
	end

	local showCreatureCheck = customisePodiumWindow:recursiveGetChildById("showCreatureCheck")
	local showPodiumCheck = customisePodiumWindow:recursiveGetChildById("showPodiumCheck")
	local showFloorCheck = customisePodiumWindow:recursiveGetChildById("showFloorCheck")

	if showCreatureCheck then
		showCreatureCheck:setChecked(showCreature)
	end

	if showPodiumCheck then
		showPodiumCheck:setChecked(showPodium)
	end

	if showFloorCheck then
		local checked = defaultShowFloor ~= false

		showFloorCheck:setChecked(checked)
		onShowFloorChange(checked)
	end

	syncShowPodiumOptionState()
end

local function clearCreatureListFocus()
	local panel = getCreatureListPanel()

	if panel then
		panel:focusChild(nil)
	end
end

local function presentWindow()
	customisePodiumWindow:show()
	customisePodiumWindow:raise()
	customisePodiumWindow:focus()

	if g_modalManager then
		g_modalManager.show(customisePodiumWindow)
	end

	addEvent(function()
		if not customisePodiumWindow or customisePodiumWindow:isDestroyed() then
			return
		end

		clearCreatureListFocus()
	end)
end

function onConfigureBossPodium(data)
	if not data then
		return
	end

	podiumProtocolData = data
	selectedCreatureSlot = nil

	local position = data.position

	currentThing = findPodiumThing(position, data.itemClientId)
	previewItem = buildPreviewItem(currentThing, data.itemClientId)
	previewDirection = data.direction or Directions.South
	previewOutfit = applyOpenStateFromTileItem(data)
	creatureEntries = buildCreatureEntries(getProtocolCreatures(data), data.isBoss)
	previewOutfit = resolveOpenPreviewOutfit(previewOutfit)
	showPodiumBeforeCreatureOff = showPodium

	ensureWindow()
	syncConfigurePanel(true)
	refreshCreatureList(creatureEntries)
	updatePreview()
	presentWindow()
end

function requestConfigurePodium(thing)
	if not thing or not thing.isPodium or not thing:isPodium() then
		return
	end

	currentThing = thing
	podiumRequestPending = true

	-- Client opcode 0x86: configure show-off socket (podium).
	-- O build nao expoe Game.requestConfigurePodium no C++, portanto enviamos
	-- o mesmo pacote diretamente pelo ProtocolGame.
	if podiumRequestEvent then
		removeEvent(podiumRequestEvent)
	end

	podiumRequestEvent = scheduleEvent(function()
		podiumRequestEvent = nil

		if g_game.isOnline() and currentThing == thing then
			local protocolGame = g_game.getProtocolGame()

			if not protocolGame then
				return
			end

			local message = OutputMessage.create()
			message:addByte(0x86)
			message:addPosition(thing:getPosition())
			message:addU16(thing:getId())
			message:addByte(thing:getStackPos())
			protocolGame:send(message)
		end
	end, 350)
end

function consumePendingOutfitWindow(player, outfitList, creatureMount, mountList)
	if not podiumRequestPending or not currentThing then
		return false
	end

	podiumRequestPending = false

	local data = {
		position = currentThing:getPosition(),
		itemClientId = currentThing:getId(),
		stackpos = currentThing:getStackPos(),
		direction = currentThing.getPodiumDirection and currentThing:getPodiumDirection() or Directions.South,
		showPlatform = currentThing.isPodiumShowPlatform and currentThing:isPodiumShowPlatform() or true,
		showCreature = true,
		showMount = true
	}

	if modules.game_outfit and modules.game_outfit.onOpenPlayerPodiumWindow then
		modules.game_outfit.onOpenPlayerPodiumWindow(player, outfitList, creatureMount, mountList, data)
	end

	return true
end

function init()
	g_ui.importStyle("game_customisepodium")
	connect(g_game, {
		onGameEnd = destroy,
		onConfigureBossPodium = onConfigureBossPodium
	})
end

function terminate()
	disconnect(g_game, {
		onGameEnd = destroy,
		onConfigureBossPodium = onConfigureBossPodium
	})
	destroy()
end

function destroy()
	if podiumRequestEvent then
		removeEvent(podiumRequestEvent)
		podiumRequestEvent = nil
	end

	podiumRequestPending = false

	if customisePodiumWindow and not customisePodiumWindow:isDestroyed() then
		if g_modalManager then
			g_modalManager.hide(customisePodiumWindow)
		end

		customisePodiumWindow:destroy()
	end

	customisePodiumWindow = nil
	currentThing = nil
	selectedCreatureSlot = nil
	initialRaceId = 0
	creatureEntries = {}
	podiumProtocolData = nil
	previewPodiumWidget = nil
	previewCreatureWidget = nil
	previewRow = nil
	previewFloor = nil
	previewFloorTiles = {}
	previewDirection = Directions.South
	previewOutfit = nil
	previewItem = nil
	previewInitialized = false
	showCreature = true
	showPodium = true
end

function hide()
	if not customisePodiumWindow or customisePodiumWindow:isDestroyed() then
		return
	end

	if g_modalManager then
		g_modalManager.hide(customisePodiumWindow)
	end

	customisePodiumWindow:hide()
end

function getCreatureListPanel()
	if not customisePodiumWindow or customisePodiumWindow:isDestroyed() then
		return nil
	end

	return customisePodiumWindow:recursiveGetChildById("creatureListPanel")
end

function show(thing)
	requestConfigurePodium(thing)
end

function syncFromThing(thing)
	if not customisePodiumWindow or customisePodiumWindow:isDestroyed() then
		return
	end

	showCreature = true
	showPodium = true
	previewItem = buildPreviewItem(thing, nil)

	if previewItem and previewItem.hasPodiumDisplay and previewItem:hasPodiumDisplay() then
		previewOutfit = copyOutfit(previewItem:getPodiumOutfit())
		previewDirection = previewItem:getPodiumDirection()
		showPodium = previewItem:isPodiumShowPlatform()

		if previewItem.isPodiumShowCreature then
			showCreature = previewItem:isPodiumShowCreature()
		end
	end

	local showFloorCheck = customisePodiumWindow:recursiveGetChildById("showFloorCheck")

	if showFloorCheck and not showFloorCheck:isChecked() then
		showFloorCheck:setChecked(true)
		onShowFloorChange(true)
	end

	syncConfigurePanel(true)
	updatePreview()
end

function setCreatureEntries(entries)
	creatureEntries = entries or {}

	refreshCreatureList(creatureEntries)
end

function refreshCreatureList(entries)
	local panel = getCreatureListPanel()

	if not panel then
		return
	end

	entries = entries or {}

	table.sort(entries, function(a, b)
		return (a.name or ""):lower() < (b.name or ""):lower()
	end)
	panel:destroyChildren()

	selectedCreatureSlot = nil

	for index, entry in ipairs(entries) do
		local slot = g_ui.createWidget("PodiumCreatureSlot", panel)

		if not slot then
			break
		end

		local slotId = entry.raceId or entry.id or index

		slot:setId("creatureSlot_" .. slotId)

		local nameLabel = slot:getChildById("creatureName")

		if nameLabel then
			nameLabel:setText(entry.name or "")
		end

		local sprite = slot:getChildById("creatureSprite")

		setupSlotCreatureSprite(sprite, entry.outfit)

		slot.creatureId = slotId
		slot.raceId = entry.raceId or slotId
		slot.filterName = (entry.name or ""):lower()
		slot.creatureOutfit = copyOutfit(entry.outfit)

		slot:setChecked(false)
		slot:show()
	end

	local layout = panel:getLayout()

	if layout then
		layout:update()
	end

	if panel.updateLayout then
		panel:updateLayout()
	end

	applyCreatureListScrollInsets(panel, 0, 0)

	local scrollbar = customisePodiumWindow and customisePodiumWindow:recursiveGetChildById("creatureListScrollBar")

	if scrollbar then
		scrollbar:setValue(scrollbar:getMinimum())
	end

	local search = customisePodiumWindow and customisePodiumWindow:recursiveGetChildById("creatureSearchEdit")

	if search then
		applyCreatureFilter(search:getText())
	end

	if initialRaceId > 0 then
		for _, slot in ipairs(panel:getChildren()) do
			if (slot.raceId or slot.creatureId or 0) == initialRaceId then
				onCreatureSlotClick(slot)

				break
			end
		end
	end

	clearCreatureListFocus()
end

function applyCreatureFilter(text)
	local panel = getCreatureListPanel()

	if not panel then
		return
	end

	text = (text or ""):lower():trim()

	for _, slot in ipairs(panel:getChildren()) do
		if text == "" or slot.filterName and slot.filterName:find(text, 1, true) then
			slot:show()
		else
			slot:hide()
		end
	end
end

function onCreatureSlotClick(slot)
	local panel = getCreatureListPanel()

	if not panel or not slot then
		return
	end

	for _, child in ipairs(panel:getChildren()) do
		child:setChecked(false)
	end

	slot:setChecked(true)

	selectedCreatureSlot = slot
	previewOutfit = copyOutfit(slot.creatureOutfit)

	syncShowPodiumOptionState()
	updatePreview()
end

function onShowCreatureChange(checked)
	if checked then
		showPodium = showPodiumBeforeCreatureOff
	else
		showPodiumBeforeCreatureOff = showPodium
	end

	showCreature = checked

	syncShowPodiumOptionState()
	updatePreview()
end

function onShowPodiumChange(checked)
	if not showCreature or not creatureWouldDisplay() then
		syncShowPodiumOptionState()

		return
	end

	showPodium = checked

	updatePreview()
end

function onShowFloorChange(checked)
	if not previewFloor then
		previewFloor = customisePodiumWindow and customisePodiumWindow:recursiveGetChildById("floor")
	end

	if not previewFloor then
		return
	end

	if checked then
		previewFloor:show()
	else
		previewFloor:hide()
		previewFloor:setMargin(0)
		resetFloorScrollOffsets()
	end
end

function onCreatureSearchChange(text)
	applyCreatureFilter(text)
end

function clearCreatureSearch()
	if not customisePodiumWindow or customisePodiumWindow:isDestroyed() then
		return
	end

	local search = customisePodiumWindow:recursiveGetChildById("creatureSearchEdit")

	if search then
		search:clearText()
	end
end

local function sendEditPodium()
	if not currentThing then
		return
	end

	local raceId = initialRaceId

	if selectedCreatureSlot then
		raceId = selectedCreatureSlot.raceId or selectedCreatureSlot.creatureId or initialRaceId
	end

	local effectiveShowPlatform, effectiveShowCreature = getEffectivePodiumFlags()

	g_game.confirmEditPodium(raceId, currentThing, previewDirection, effectiveShowPlatform, effectiveShowCreature)
end

function onOk()
	local effectiveShowPlatform, effectiveShowCreature = getEffectivePodiumFlags()

	sendEditPodium()

	if currentThing and currentThing.setPodium then
		local outfit = {}

		if effectiveShowCreature then
			local preview = getPreviewCreatureOutfit()

			if preview and outfitHasDisplay(preview) then
				outfit = copyOutfit(preview)
			end
		end

		currentThing:setPodium(outfit, previewDirection, effectiveShowPlatform, effectiveShowCreature)
	end

	hide()
end

function onCancel()
	hide()
end
