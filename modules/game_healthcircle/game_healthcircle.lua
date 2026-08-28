-- chunkname: @/game_healthcircle/game_healthcircle.lua

imageSizeBroad = 0
imageSizeThin = 0
mapPanel = modules.game_interface.getMapPanel()

function currentViewMode()
	return modules.game_interface.currentViewMode
end

healthCircle = nil
manaCircle = nil
manaShieldCircle = nil
harmonyCircle = nil
sereneCircle = nil
arcConditionsBar = nil
manaShieldImageSizeBroad = 0
manaShieldImageSizeThin = 0

local HARMONY_ARC_SLOTS = 5
local ARC_BASE_WIDTH_AT_100 = 33
local ARC_BASE_HEIGHT_AT_100 = 120
local ARC_THICKNESS_AT_100 = 10
local SERENE_INSET_FROM_HEALTH_WIDGET_RIGHT_AT_BASE = 10
local SERENE_DIAMETER_AT_100 = 11.5
local SERENE_MIN_DIAMETER = 5
local SERENE_DIAMETER_PRESET_MUL = {
	large = 1,
	default = 1,
	small = 0.8
}
local CONDITION_BAR_WIDTH_AT_100 = 13
local CONDITION_BAR_MIN_HEIGHT_AT_100 = 21
local CONDITION_BAR_ICON_AT_100 = 9
local CONDITION_BAR_ICON_SPACING_AT_100 = 4
local CONDITION_BAR_CAP_PAD_AT_100 = 6
local CONDITION_BAR_GAP_FROM_HEALTH_AT_100 = 7
local MAP_BASE_WIDTH_AT_100 = 480
local MAP_BASE_HEIGHT_AT_100 = 352
local ARC_VERTICAL_OFFSET = -14
local ARC_DISTANCE_SCROLL_RANGE = {
	small = {
		min = 0,
		max = 695
	},
	default = {
		min = 0,
		max = 392
	},
	large = {
		min = 0,
		max = 217
	}
}

hudArcsSizePreset = "default"

local HUD_ARC_SCALE_PRESET_SMALL = 0.6
local HUD_ARC_SCALE_PRESET_LARGE = 1.61

hudArcScaleMul = 1
isHealthCircle = not g_settings.getBoolean("healthcircle_hpcircle")
isManaCircle = not g_settings.getBoolean("healthcircle_mpcircle")
distanceFromCenter = g_settings.getNumber("healthcircle_distfromcenter")

local function arcDistanceScrollLoHi()
	local row = ARC_DISTANCE_SCROLL_RANGE[hudArcsSizePreset]

	row = row or ARC_DISTANCE_SCROLL_RANGE.default

	return row.min, row.max
end

function arcScrollPercentToDistancePixels(percent)
	if type(percent) ~= "number" then
		return 0
	end

	percent = math.max(0, math.min(100, percent))

	local lo, hi = arcDistanceScrollLoHi()

	return math.floor(lo + (hi - lo) * percent / 100 + 0.5)
end

function arcDistancePixelsToScrollPercent(px)
	if type(px) ~= "number" then
		return 0
	end

	local lo, hi = arcDistanceScrollLoHi()

	px = math.max(lo, math.min(hi, px))

	return math.floor((px - lo) / (hi - lo) * 100 + 0.5)
end

statsBarMenuLoaded = false

local hudArcsAllowed = false
local vitalsRefreshEvent, lastManaShieldSplitKey, lastHarmonySplitKey

local function hudOptionBool(key)
	local co = modules.client_options

	if not co or not co.getOption then
		return false
	end

	return co.getOption(key) == true
end

local function hudArcsShown()
	return hudArcsAllowed
end

local function computeHarmonySplit()
	if not hudOptionBool("showOwnHarmony") then
		return false, nil
	end

	local player = g_game.isOnline() and g_game.getLocalPlayer() or nil

	if not player then
		return false, nil
	end

	local voc = player:getVocation()

	if voc ~= VocationsClient.Monk and voc ~= VocationsClient.ExaltedMonk then
		return false, nil
	end

	if hudOptionBool("harmonyNextToHealth") then
		return true, "health"
	end

	if hudOptionBool("harmonyNextToMana") then
		return true, "mana"
	end

	return false, nil
end

function updateSereneDisplay()
	if not sereneCircle then
		return
	end

	if not hudArcsShown() then
		sereneCircle:setVisible(false)

		return
	end

	local player = g_game.isOnline() and g_game.getLocalPlayer() or nil

	if not player then
		sereneCircle:setVisible(false)

		return
	end

	local hSplit = computeHarmonySplit()

	if not hSplit then
		sereneCircle:setVisible(false)

		return
	end

	sereneCircle:setVisible(true)

	if player:isSerene() then
		sereneCircle:setPercent(100)
		sereneCircle:setFillColor("#D437FFBF")
	else
		sereneCircle:setPercent(0)
		sereneCircle:setTrackColor("#0000003C")
	end
end

local function computeManaShieldSplit()
	if not hudOptionBool("showManaShield") then
		return false, nil
	end

	local player = g_game.isOnline() and g_game.getLocalPlayer() or nil

	if not player or player:getManaShield() <= 0 then
		return false, nil
	end

	if hudOptionBool("manaShieldNextToMana") then
		return true, "mana"
	end

	if hudOptionBool("manaShieldNextToHealth") then
		return true, "health"
	end

	return false, nil
end

local function getMapArcLayoutScale()
	if not mapPanel then
		return 1
	end

	local mapWidth = mapPanel:getWidth()
	local mapHeight = mapPanel:getHeight()

	if mapWidth <= 0 or mapHeight <= 0 then
		return 1
	end

	local scaleByWidth = mapWidth / MAP_BASE_WIDTH_AT_100
	local scaleByHeight = mapHeight / MAP_BASE_HEIGHT_AT_100
	local scale = math.min(scaleByWidth, scaleByHeight) * hudArcScaleMul

	if not scale or scale <= 0 then
		return 1
	end

	return scale
end

local function getArcLayoutHalfGap()
	local arcGap = math.max(0, math.floor((distanceFromCenter or 0) * getMapArcLayoutScale() + 0.5))

	return math.floor(arcGap / 2 + 0.5)
end

local function getArcOutfitPlacementOffset()
	if g_game.getFeature and g_game.getFeature(GameNegativeOffset) then
		return 0, 0
	end

	local player = g_game.isOnline() and g_game.getLocalPlayer() or nil

	if not player or not g_things or not g_things.getThingType then
		return 0, 0
	end

	local outfit = player:getOutfit()

	if not outfit or not outfit.type or outfit.type <= 0 then
		return 0, 0
	end

	local lookType = outfit.type

	if outfit.mount and outfit.mount > 0 then
		lookType = outfit.mount
	end

	local thingType = g_things.getThingType(lookType, ThingCategoryCreature)

	if not thingType then
		return 0, 0
	end

	local dispX = thingType:getDisplacementX() or 0
	local dispY = thingType:getDisplacementY() or 0
	local scale = getMapArcLayoutScale()

	return -math.floor(dispX * scale + 0.5), -math.floor(dispY * scale + 0.5)
end

local function getHealthArcBaseLayoutXY()
	if not mapPanel then
		return 0, 0
	end

	local halfGap = getArcLayoutHalfGap()

	if currentViewMode() == 2 then
		return math.floor(mapPanel:getWidth() / 2 - imageSizeThin - halfGap), math.floor(mapPanel:getHeight() / 2 - imageSizeBroad / 2 + ARC_VERTICAL_OFFSET)
	end

	return math.floor(mapPanel:getX() + mapPanel:getWidth() / 2 - imageSizeThin - halfGap), math.floor(mapPanel:getY() + mapPanel:getHeight() / 2 - imageSizeBroad / 2 + ARC_VERTICAL_OFFSET)
end

local function getManaArcLeftNudge()
	return math.max(0, math.floor(1 * getMapArcLayoutScale() + 0.5))
end

local function getManaArcLayoutX()
	if not mapPanel then
		return 0
	end

	local ox = getArcOutfitPlacementOffset()
	local halfGap = getArcLayoutHalfGap()
	local nudge = getManaArcLeftNudge()

	if currentViewMode() == 2 then
		return math.floor(mapPanel:getWidth() / 2 + halfGap) + ox - nudge
	end

	return math.floor(mapPanel:getX() + mapPanel:getWidth() / 2 + halfGap) + ox - nudge
end

local arcHudLayoutGuard = false
local arcHudLayoutPending = false
local arcConditionsRefreshScheduled = false

local function getConditionsBarScale()
	if healthCircle and healthCircle:getHeight() > 0 then
		return healthCircle:getHeight() / ARC_BASE_HEIGHT_AT_100
	end

	return getMapArcLayoutScale()
end

local function arcConditionsBarMetrics(iconCount, scale)
	scale = scale or getConditionsBarScale()

	local iconSize = math.max(1, math.floor(CONDITION_BAR_ICON_AT_100 * scale + 0.5))
	local iconSpacing = math.max(0, math.floor(CONDITION_BAR_ICON_SPACING_AT_100 * scale + 0.5))
	local capPad = math.max(1, math.floor(CONDITION_BAR_CAP_PAD_AT_100 * scale + 0.5))
	local gapCount = math.max(0, iconCount - 1)
	local contentH = iconCount * iconSize + gapCount * iconSpacing
	local barHeight = math.max(math.floor(CONDITION_BAR_MIN_HEIGHT_AT_100 * scale + 0.5), capPad * 2 + contentH)

	return {
		iconSize = iconSize,
		iconSpacing = iconSpacing,
		contentH = contentH,
		barHeight = barHeight,
		iconsY = math.max(0, math.floor((barHeight - contentH) / 2 + 0.5))
	}
end

local function arcConditionsBarHeight(iconCount, scale)
	if iconCount <= 0 then
		return 0
	end

	return arcConditionsBarMetrics(iconCount, scale).barHeight
end

local function resetArcConditionsBarLayout()
	if not arcConditionsBar then
		return
	end

	if arcConditionsBar.breakAnchors then
		arcConditionsBar:breakAnchors()
	end

	arcConditionsBar:setMarginTop(0)
	arcConditionsBar:setMarginBottom(0)
	arcConditionsBar:setMarginLeft(0)
	arcConditionsBar:setMarginRight(0)
end

local function resetArcConditionsIconsPanel(iconsPanel)
	if not iconsPanel then
		return
	end

	if iconsPanel.breakAnchors then
		iconsPanel:breakAnchors()
	end

	iconsPanel:setPosition({
		x = 0,
		y = 0
	})
	iconsPanel:setPaddingTop(0)
	iconsPanel:setPaddingBottom(0)
	iconsPanel:setPaddingLeft(0)
	iconsPanel:setPaddingRight(0)
	iconsPanel:setMarginTop(0)
	iconsPanel:setMarginBottom(0)
	iconsPanel:setMarginLeft(0)
	iconsPanel:setMarginRight(0)
end

local function sortArcConditionEntries(list)
	table.sort(list, function(a, b)
		if modules.client_options and modules.client_options.getConditionDisplayOrderIndex then
			local orderA = modules.client_options.getConditionDisplayOrderIndex(a.info.id)
			local orderB = modules.client_options.getConditionDisplayOrderIndex(b.info.id)

			if orderA ~= orderB then
				return orderA < orderB
			end
		end

		return a.state < b.state
	end)
end

local function collectActiveConditionStates(states)
	local list = {}
	local redSwordsActive = bit.band(states, PlayerStates.RedSwords) ~= 0

	for state, info in pairs(Icons) do
		local overriddenByRedSwords = state == PlayerStates.Swords and redSwordsActive

		if not overriddenByRedSwords and type(state) == "number" and state > 0 and info and info.id and bit.band(states, state) ~= 0 and (not modules.client_options or not modules.client_options.isSpecialConditionId(info.id) or modules.client_options.isConditionVisibleInHud(info.id)) then
			list[#list + 1] = {
				state = state,
				info = info
			}
		end
	end

	sortArcConditionEntries(list)

	return list
end

local function appendVirtualArcCondition(list, info, sortState, conditionId, displayInfo)
	if not info or not info.id then
		return
	end

	displayInfo = displayInfo or info

	local visible = true

	if modules.client_options and modules.client_options.isSpecialConditionId(conditionId or info.id) and modules.client_options.isConditionVisibleInHud then
		visible = modules.client_options.isConditionVisibleInHud(conditionId or info.id)
	end

	if not visible then
		return
	end

	for _, entry in ipairs(list) do
		if entry.info.id == info.id then
			return
		end
	end

	list[#list + 1] = {
		state = sortState,
		info = displayInfo
	}

	sortArcConditionEntries(list)
end

local function collectArcConditionEntries(player)
	local list = collectActiveConditionStates(player:getStates())

	if isPlayerHungry(player) then
		local hungryInfo = Icons[PlayerStates.Hungry]

		if hungryInfo then
			appendVirtualArcCondition(list, hungryInfo, PlayerStates.Hungry, hungryInfo.id)
		end
	end

	if isPlayerInRestingArea() then
		local restingInfo = getPlayerRestingAreaIconInfo()

		if restingInfo then
			appendVirtualArcCondition(list, SpecialConditionExtraIcons.condition_restingarea, 1, "condition_restingarea", restingInfo)
		end
	end

	return list
end

local function getArcConditionsClusterWidth()
	if not hudArcsShown() or not isHealthCircle or not healthCircle or not healthCircle:isVisible() then
		return 0
	end

	if not g_game.isOnline() or not g_game.getLocalPlayer() then
		return 0
	end

	local scale = getConditionsBarScale()
	local barW = math.max(1, math.floor(CONDITION_BAR_WIDTH_AT_100 * scale + 0.5))
	local gap = math.max(1, math.floor(CONDITION_BAR_GAP_FROM_HEALTH_AT_100 * scale + 0.5))

	return barW + gap
end

local function getHealthOutfitPlacementInwardCompensation()
	local ox, oy = getArcOutfitPlacementOffset()

	return math.max(0, -ox), math.max(0, -oy)
end

local function getHealthConditionsInwardOffset()
	local lo, hi = arcDistanceScrollLoHi()
	local dist = distanceFromCenter or 0

	if dist <= lo then
		return 0
	end

	local t = 1

	if lo < hi then
		t = math.min(1, (dist - lo) / (hi - lo))
	end

	local inward = 0
	local cluster = getArcConditionsClusterWidth()

	if cluster > 0 then
		inward = math.floor(cluster * t + 0.5)
	end

	local outfitInX, _ = getHealthOutfitPlacementInwardCompensation()

	return inward + math.floor(outfitInX * t + 0.5)
end

local function getMapPanelLayoutLeftTop()
	if not mapPanel then
		return 0, 0
	end

	if currentViewMode() == 2 then
		return 0, 0
	end

	return mapPanel:getX(), mapPanel:getY()
end

local function clampHealthArcLayoutXY(healthX, healthY)
	if not mapPanel then
		return healthX, healthY
	end

	local mapLeft, mapTop = getMapPanelLayoutLeftTop()
	local cluster = getArcConditionsClusterWidth()

	if cluster > 0 then
		local leftEdge = healthX - cluster

		if leftEdge < mapLeft then
			healthX = healthX + (mapLeft - leftEdge)
		end
	elseif healthX < mapLeft then
		healthX = mapLeft
	end

	if healthY < mapTop then
		healthY = mapTop
	end

	return healthX, healthY
end

local function getHealthArcLayoutXY()
	local x, y = getHealthArcBaseLayoutXY()
	local ox, oy = getArcOutfitPlacementOffset()
	local _, outfitInY = getHealthOutfitPlacementInwardCompensation()
	local inward = getHealthConditionsInwardOffset()

	x = x + inward + ox
	y = y + oy + outfitInY

	return clampHealthArcLayoutXY(x, y)
end

local function createArcConditionIcon(parent, info, iconSize)
	local icon = g_ui.createWidget("ArcConditionIcon", parent)

	icon:setId(info.id)
	applyPlayerStateIcon(icon, info)

	local tooltip = info.tooltip

	if tooltip == "You are GoshnarTaint" then
		tooltip = "Goshnar's Lairs Penalties:\n" .. "- 10% chance of creature teleportation to you\n" .. "- 0.5% chance of new creature spawn when hitting another\n" .. "- 15% increased damage received\n" .. "- 10% chance of creature full heal instead of dying\n" .. "- Lose 10% of current HP and mana every 10 seconds"
	end

	icon:setTooltip(tooltip)
	icon:setSize({
		width = iconSize,
		height = iconSize
	})
	icon:setImageSize(tosize(iconSize .. " " .. iconSize))

	return icon
end

local function ensureArcConditionsIconsLayout(iconsPanel)
	local layout = iconsPanel:getLayout()

	if layout and layout.setSpacing then
		return layout
	end

	layout = UIVerticalLayout.create(iconsPanel)

	iconsPanel:setLayout(layout)

	return layout
end

local function layoutArcConditionIcons(iconsPanel, active, metrics, barWidth)
	local sidePad = math.max(0, math.floor((barWidth - metrics.iconSize) / 2 + 0.5))
	local padBottom = math.max(0, metrics.barHeight - metrics.iconsY - metrics.contentH)

	iconsPanel:setPaddingTop(metrics.iconsY)
	iconsPanel:setPaddingBottom(padBottom)
	iconsPanel:setPaddingLeft(sidePad)
	iconsPanel:setPaddingRight(sidePad)

	local layout = ensureArcConditionsIconsLayout(iconsPanel)

	layout:setSpacing(metrics.iconSpacing)

	for _, entry in ipairs(active) do
		createArcConditionIcon(iconsPanel, entry.info, metrics.iconSize)
	end

	iconsPanel:updateLayout()
end

local function layoutArcConditionsPosition()
	if not arcConditionsBar or not healthCircle or not mapPanel or not arcConditionsBar:isVisible() then
		return
	end

	local scale = getMapArcLayoutScale()
	local gap = math.max(1, math.floor(CONDITION_BAR_GAP_FROM_HEALTH_AT_100 * scale + 0.5))
	local barW = arcConditionsBar:getWidth()
	local barH = arcConditionsBar:getHeight()
	local healthX, healthY = getHealthArcLayoutXY()

	if arcConditionsBar.breakAnchors then
		arcConditionsBar:breakAnchors()
	end

	arcConditionsBar:setPosition({
		x = healthX - gap - barW,
		y = healthY + math.floor((imageSizeBroad - barH) / 2 + 0.5)
	})
end

local function updateArcConditionsDisplay()
	if not arcConditionsBar then
		return
	end

	local iconsPanel = arcConditionsBar:getChildById("icons")

	if not iconsPanel then
		return
	end

	if not hudArcsShown() or not isHealthCircle or not healthCircle or not healthCircle:isVisible() then
		arcConditionsBar:setVisible(false)
		iconsPanel:destroyChildren()

		return
	end

	local player = g_game.isOnline() and g_game.getLocalPlayer() or nil

	if not player then
		arcConditionsBar:setVisible(false)
		iconsPanel:destroyChildren()

		return
	end

	local scale = getConditionsBarScale()
	local barWidth = math.max(1, math.floor(CONDITION_BAR_WIDTH_AT_100 * scale + 0.5))
	local active = collectArcConditionEntries(player)
	local iconCount = #active

	if iconCount == 0 then
		arcConditionsBar:setVisible(false)
		iconsPanel:destroyChildren()

		return
	end

	arcConditionsBar:setVisible(false)
	resetArcConditionsBarLayout()
	resetArcConditionsIconsPanel(iconsPanel)
	iconsPanel:destroyChildren()

	local ok, err = pcall(function()
		local metrics = arcConditionsBarMetrics(iconCount, scale)

		arcConditionsBar:setSize({
			width = barWidth,
			height = metrics.barHeight
		})
		iconsPanel:setSize({
			width = barWidth,
			height = metrics.barHeight
		})
		layoutArcConditionIcons(iconsPanel, active, metrics, barWidth)
	end)

	if ok and iconsPanel:getChildCount() > 0 then
		arcConditionsBar:setVisible(true)
		layoutArcConditionsPosition()
		arcConditionsBar:raise()
	else
		arcConditionsBar:setVisible(false)
		iconsPanel:destroyChildren()

		if not ok then
			g_logger.error("[game_healthcircle] updateArcConditionsDisplay: %s", tostring(err))
		end
	end
end

local function scheduleArcConditionsRefresh()
	if arcConditionsRefreshScheduled then
		return
	end

	arcConditionsRefreshScheduled = true

	addEvent(function()
		arcConditionsRefreshScheduled = false

		updateArcConditionsDisplay()
	end)
end

function refreshArcConditionsBarDeferred()
	scheduleArcConditionsRefresh()
end

local function repairArcConditionsIfMissing()
	if not arcConditionsBar or not arcConditionsBar:isVisible() then
		return
	end

	local iconsPanel = arcConditionsBar:getChildById("icons")

	if not iconsPanel or iconsPanel:getChildCount() > 0 then
		return
	end

	if not hudArcsShown() or not isHealthCircle or not healthCircle or not healthCircle:isVisible() then
		return
	end

	local player = g_game.isOnline() and g_game.getLocalPlayer() or nil

	if not player or #collectArcConditionEntries(player) == 0 then
		return
	end

	updateArcConditionsDisplay()
end

local function layoutHealthManaArcPositions()
	if not mapPanel or not healthCircle or not manaCircle then
		return
	end

	local healthX, healthY = getHealthArcLayoutXY()
	local manaX = getManaArcLayoutX()

	healthCircle:setX(healthX)
	manaCircle:setX(manaX)
	healthCircle:setY(healthY)
	manaCircle:setY(healthY)

	local hSplit, hPair = computeHarmonySplit()

	if hudArcsShown() and harmonyCircle and hSplit and hPair == "mana" then
		harmonyCircle:setX(manaCircle:getX())
		harmonyCircle:setY(manaCircle:getY())
		manaCircle:raise()
		harmonyCircle:raise()
	elseif hudArcsShown() and harmonyCircle and hSplit and hPair == "health" then
		harmonyCircle:setX(healthCircle:getX())
		harmonyCircle:setY(healthCircle:getY())
		healthCircle:raise()
		harmonyCircle:raise()
	end

	local split, pair = computeManaShieldSplit()

	if hudArcsShown() and manaShieldCircle and split and pair == "mana" then
		manaShieldCircle:setX(manaCircle:getX())
		manaShieldCircle:setY(manaCircle:getY())
		manaCircle:raise()

		if harmonyCircle and hSplit and hPair == "mana" then
			harmonyCircle:raise()
		end
	elseif hudArcsShown() and manaShieldCircle and split and pair == "health" then
		manaShieldCircle:setX(healthCircle:getX())
		manaShieldCircle:setY(healthCircle:getY())
		healthCircle:raise()

		if harmonyCircle and hSplit and hPair == "health" then
			harmonyCircle:raise()
		end
	end

	if sereneCircle and healthCircle and manaCircle then
		local sw = sereneCircle:getWidth()
		local sh = sereneCircle:getHeight()

		if sw > 0 and sh > 0 then
			local serenePullLeft = math.max(0, math.floor(SERENE_INSET_FROM_HEALTH_WIDGET_RIGHT_AT_BASE * (imageSizeThin / ARC_BASE_WIDTH_AT_100) + 0.5))
			local hSplit, hPair = computeHarmonySplit()

			if hSplit and hPair == "mana" then
				sereneCircle:setX(manaCircle:getX() + serenePullLeft)
				sereneCircle:setY(manaCircle:getY() + math.floor((imageSizeBroad - sh) / 2))
			else
				sereneCircle:setX(healthCircle:getX() + imageSizeThin - sw - serenePullLeft)
				sereneCircle:setY(healthCircle:getY() + math.floor((imageSizeBroad - sh) / 2))
			end

			if hudArcsShown() and sereneCircle:isVisible() then
				sereneCircle:raise()
			end
		end
	end

	layoutArcConditionsPosition()
	repairArcConditionsIfMissing()
end

local function whenLocalPlayerOutfitChange(localPlayer, outfit, oldOutfit)
	if not mapPanel or not healthCircle or not manaCircle then
		return
	end

	layoutHealthManaArcPositions()
	updateArcConditionsDisplay()
end

local function whenLocalPlayerStatesChange(localPlayer, now, old)
	if now == old then
		return
	end

	updateArcConditionsDisplay()
end

local function whenRegenerationChange(localPlayer, now, old)
	if now == old then
		return
	end

	updateArcConditionsDisplay()
end

local function cancelVitalsRefresh()
	if vitalsRefreshEvent then
		removeEvent(vitalsRefreshEvent)

		vitalsRefreshEvent = nil
	end
end

local function scheduleVitalsRefresh()
	if vitalsRefreshEvent then
		return
	end

	vitalsRefreshEvent = addEvent(function()
		vitalsRefreshEvent = nil

		whenHealthChange()
		whenManaChange()
	end)
end

local function onGameEndForHealthCircle()
	cancelVitalsRefresh()

	if not arcConditionsBar then
		return
	end

	resetPlayerRestingAreaState()
	arcConditionsBar:setVisible(false)
	resetArcConditionsBarLayout()

	local iconsPanel = arcConditionsBar:getChildById("icons")

	if iconsPanel then
		iconsPanel:destroyChildren()
		resetArcConditionsIconsPanel(iconsPanel)
	end
end

local function onGameStartForHealthCircle()
	whenMapResizeChange()

	if modules.client_options and modules.client_options.getOption then
		syncShowArcsFromClientOptions(modules.client_options.getOption("showArcs"), nil)
	end
end

function init()
	mapPanel = modules.game_interface.getMapPanel()

	g_ui.importStyle("game_healthcircle.otui")

	healthCircle = g_ui.createWidget("HealthProgressArc", mapPanel)
	manaCircle = g_ui.createWidget("ManaProgressArc", mapPanel)
	manaShieldCircle = g_ui.createWidget("ManaShieldProgressArc", mapPanel)
	harmonyCircle = g_ui.createWidget("HarmonyProgressArc", mapPanel)
	sereneCircle = g_ui.createWidget("SereneStatusCircle", mapPanel)
	arcConditionsBar = g_ui.createWidget("ArcConditionsBar", mapPanel)

	arcConditionsBar:setVisible(false)

	if modules.client_options and modules.client_options.getOption then
		local s = modules.client_options.getOption("showArcsSize") or "default"

		if s == "small" then
			hudArcsSizePreset = "small"
			hudArcScaleMul = HUD_ARC_SCALE_PRESET_SMALL
		elseif s == "large" then
			hudArcsSizePreset = "large"
			hudArcScaleMul = HUD_ARC_SCALE_PRESET_LARGE
		else
			hudArcsSizePreset = "default"
			hudArcScaleMul = 1
		end
	end

	imageSizeBroad = math.max(1, healthCircle:getHeight())
	imageSizeThin = math.max(1, healthCircle:getWidth())
	manaShieldImageSizeBroad = math.max(1, manaShieldCircle:getHeight())
	manaShieldImageSizeThin = math.max(1, manaShieldCircle:getWidth())

	manaShieldCircle:setVisible(false)
	harmonyCircle:setVisible(false)
	sereneCircle:setVisible(false)
	whenMapResizeChange()
	initOnHpAndMpChange()
	initOnGeometryChange()
	initOnLoginChange()

	hudArcsAllowed = g_settings.getBoolean("showArcs")

	if not isHealthCircle then
		healthCircle:setVisible(false)
	end

	if not isManaCircle then
		manaCircle:setVisible(false)
	end

	addToOptionsModule()
	addEvent(function()
		if modules.client_options and modules.client_options.getOption then
			syncShowArcsFromClientOptions(modules.client_options.getOption("showArcs"), nil)
		end
	end)
end

function terminate()
	cancelVitalsRefresh()
	healthCircle:destroy()

	healthCircle = nil

	manaCircle:destroy()

	manaCircle = nil

	manaShieldCircle:destroy()

	manaShieldCircle = nil

	harmonyCircle:destroy()

	harmonyCircle = nil

	sereneCircle:destroy()

	sereneCircle = nil

	arcConditionsBar:destroy()

	arcConditionsBar = nil

	terminateOnHpAndMpChange()
	terminateOnGeometryChange()
	terminateOnLoginChange()
	destroyOptionsModule()

	statsBarMenuLoaded = false
end

function initOnHpAndMpChange()
	connect(LocalPlayer, {
		onHealthChange = scheduleVitalsRefresh,
		onManaChange = scheduleVitalsRefresh,
		onManaShieldChange = scheduleVitalsRefresh,
		onHarmonyChange = whenHarmonyChange,
		onSereneChange = whenSereneChange,
		onVocationChange = whenLocalPlayerVocationChange,
		onOutfitChange = whenLocalPlayerOutfitChange,
		onStatesChange = whenLocalPlayerStatesChange,
		onRegenerationChange = whenRegenerationChange
	})
end

function terminateOnHpAndMpChange()
	disconnect(LocalPlayer, {
		onHealthChange = scheduleVitalsRefresh,
		onManaChange = scheduleVitalsRefresh,
		onManaShieldChange = scheduleVitalsRefresh,
		onHarmonyChange = whenHarmonyChange,
		onSereneChange = whenSereneChange,
		onVocationChange = whenLocalPlayerVocationChange,
		onOutfitChange = whenLocalPlayerOutfitChange,
		onStatesChange = whenLocalPlayerStatesChange,
		onRegenerationChange = whenRegenerationChange
	})
end

function initOnGeometryChange()
	connect(mapPanel, {
		onGeometryChange = whenMapResizeChange
	})
end

function terminateOnGeometryChange()
	disconnect(mapPanel, {
		onGeometryChange = whenMapResizeChange
	})
end

local function onRestingAreaStateForArc(zone, state, message)
	if updatePlayerRestingAreaState(zone, state, message) then
		updateArcConditionsDisplay()
	end
end

function initOnLoginChange()
	connect(g_game, {
		onGameStart = onGameStartForHealthCircle,
		onGameEnd = onGameEndForHealthCircle,
		onRestingAreaState = onRestingAreaStateForArc
	})
end

function terminateOnLoginChange()
	disconnect(g_game, {
		onGameStart = onGameStartForHealthCircle,
		onGameEnd = onGameEndForHealthCircle,
		onRestingAreaState = onRestingAreaStateForArc
	})
end

function whenHealthChange()
	if g_game.isOnline() then
		local healthPercent = math.floor(g_game.getLocalPlayer():getHealth() / g_game.getLocalPlayer():getMaxHealth() * 100)

		healthCircle:setPercent(healthPercent)
		healthCircle:setFillColor(getHealthColorByPercentWithAlpha(healthPercent))
	end
end

local function updateHarmonyDisplay()
	if not harmonyCircle or not manaCircle or not healthCircle then
		return
	end

	if not hudArcsShown() then
		harmonyCircle:setVisible(false)
		updateSereneDisplay()

		if lastHarmonySplitKey ~= nil then
			lastHarmonySplitKey = nil

			applyArcScaleByMapPanel()
			layoutHealthManaArcPositions()
		end

		return
	end

	local split, pair = computeHarmonySplit()
	local player = g_game.isOnline() and g_game.getLocalPlayer() or nil

	if not split or not player then
		harmonyCircle:setVisible(false)
		updateSereneDisplay()

		if lastHarmonySplitKey ~= nil then
			lastHarmonySplitKey = nil

			applyArcScaleByMapPanel()
			layoutHealthManaArcPositions()
		end

		return
	end

	harmonyCircle:setVisible(true)
	local harmony = math.min(HARMONY_ARC_SLOTS, math.max(0, player:getHarmony()))
	harmonyCircle:setPercent(harmony * (100 / HARMONY_ARC_SLOTS))

	if pair ~= lastHarmonySplitKey then
		lastHarmonySplitKey = pair

		applyArcScaleByMapPanel()
		layoutHealthManaArcPositions()
	end

	updateSereneDisplay()
end

local function updateManaShieldDisplay()
	if not manaShieldCircle or not manaCircle or not healthCircle then
		return
	end

	if not hudArcsShown() then
		manaShieldCircle:setVisible(false)

		if lastManaShieldSplitKey ~= nil then
			lastManaShieldSplitKey = nil

			applyArcScaleByMapPanel()
			layoutHealthManaArcPositions()
		end

		updateHarmonyDisplay()

		return
	end

	local split, pair = computeManaShieldSplit()
	local player = g_game.isOnline() and g_game.getLocalPlayer() or nil

	if not split or not player then
		manaShieldCircle:setVisible(false)

		if lastManaShieldSplitKey ~= nil then
			lastManaShieldSplitKey = nil

			applyArcScaleByMapPanel()
			layoutHealthManaArcPositions()
		end
	else
		local maxShield = player:getMaxManaShield()
		local remainingShield = player:getManaShield()

		if maxShield <= 0 then
			maxShield = remainingShield
		end

		local clampedShield = math.max(math.min(remainingShield, maxShield), 0)
		local shieldPercent = 100 * clampedShield / maxShield

		manaShieldCircle:setVisible(true)
		manaShieldCircle:setPercent(shieldPercent)

		if pair ~= lastManaShieldSplitKey then
			lastManaShieldSplitKey = pair

			applyArcScaleByMapPanel()
			layoutHealthManaArcPositions()
		end
	end

	updateHarmonyDisplay()
end

function whenHarmonyChange()
	updateHarmonyDisplay()
end

function whenSereneChange()
	updateSereneDisplay()
	layoutHealthManaArcPositions()
end

function whenLocalPlayerVocationChange()
	updateManaShieldDisplay()
end

function whenManaShieldChange()
	updateManaShieldDisplay()
end

function whenManaChange()
	if g_game.isOnline() then
		local player = g_game.getLocalPlayer()
		local maxMana = player:getMaxMana()

		if maxMana <= 0 then
			manaCircle:setVisible(false)

			if manaShieldCircle then
				manaShieldCircle:setVisible(false)
			end

			if harmonyCircle then
				harmonyCircle:setVisible(false)
			end

			if sereneCircle then
				sereneCircle:setVisible(false)
			end

			return
		elseif isManaCircle then
			manaCircle:setVisible(true)
		end

		updateManaShieldDisplay()

		local currentMana = player:getMana()
		local manaPercent = math.floor(currentMana / maxMana * 100)

		if manaPercent >= 99.5 then
			manaPercent = 100
		elseif manaPercent < 0 then
			manaPercent = 0
		end

		manaCircle:setPercent(manaPercent)
	end
end

function whenMapResizeChange()
	if arcHudLayoutGuard then
		arcHudLayoutPending = true

		return
	end

	arcHudLayoutGuard = true

	local ok, err = pcall(function()
		applyArcScaleByMapPanel()

		if g_game.isOnline() then
			whenHealthChange()
			whenManaChange()
		end

		updateManaShieldDisplay()
		updateSereneDisplay()
		layoutHealthManaArcPositions()
		updateArcConditionsDisplay()
	end)

	arcHudLayoutGuard = false

	if not ok then
		g_logger.error("[game_healthcircle] whenMapResizeChange: %s", tostring(err))
	end

	if arcHudLayoutPending then
		arcHudLayoutPending = false

		whenMapResizeChange()

		return
	end

	scheduleArcConditionsRefresh()
end

function applyArcScaleByMapPanel()
	if not healthCircle or not manaCircle or not manaShieldCircle or not harmonyCircle or not mapPanel then
		return
	end

	local mapWidth = mapPanel:getWidth()
	local mapHeight = mapPanel:getHeight()

	if mapWidth <= 0 or mapHeight <= 0 then
		imageSizeBroad = math.max(1, healthCircle:getHeight())
		imageSizeThin = math.max(1, healthCircle:getWidth())

		return
	end

	local scaleByWidth = mapWidth / MAP_BASE_WIDTH_AT_100
	local scaleByHeight = mapHeight / MAP_BASE_HEIGHT_AT_100
	local scale = math.min(scaleByWidth, scaleByHeight) * hudArcScaleMul

	if not scale or scale <= 0 then
		scale = 1
	end

	local arcWidth = math.max(1, math.floor(ARC_BASE_WIDTH_AT_100 * scale + 0.5))
	local arcHeight = math.max(1, math.floor(ARC_BASE_HEIGHT_AT_100 * scale))
	local arcThickness = math.max(1, math.floor(ARC_THICKNESS_AT_100 * scale + 0.5))
	local sShield, pShield = computeManaShieldSplit()
	local sHarm, pHarm = computeHarmonySplit()

	if not hudArcsShown() then
		sShield, pShield = false
		sHarm, pHarm = false
	end

	local nHealthAux = (sShield and pShield == "health" and 1 or 0) + (sHarm and pHarm == "health" and 1 or 0)
	local nManaAux = (sShield and pShield == "mana" and 1 or 0) + (sHarm and pHarm == "mana" and 1 or 0)
	-- Keep the primary health/mana band visually dominant. Auxiliary resources
	-- (Mana Shield and Monk Harmony) use a thinner inner band, as in the
	-- official HUD, instead of splitting the available width equally.
	local hpAuxThickness = math.max(1, math.floor(arcThickness / (2 + nHealthAux) + 0.5))
	local mpAuxThickness = math.max(1, math.floor(arcThickness / (2 + nManaAux) + 0.5))
	local hpThickness = nHealthAux > 0 and math.max(1, arcThickness - hpAuxThickness * nHealthAux) or arcThickness
	local mpThickness = nManaAux > 0 and math.max(1, arcThickness - mpAuxThickness * nManaAux) or arcThickness

	healthCircle:setWidth(arcWidth)
	healthCircle:setHeight(arcHeight)
	healthCircle:setThickness(hpThickness)
	manaCircle:setWidth(arcWidth)
	manaCircle:setHeight(arcHeight)
	manaCircle:setThickness(mpThickness)
	manaShieldCircle:setWidth(arcWidth)
	manaShieldCircle:setHeight(arcHeight)
	harmonyCircle:setWidth(arcWidth)
	harmonyCircle:setHeight(arcHeight)

	if sereneCircle then
		local presetMul = SERENE_DIAMETER_PRESET_MUL[hudArcsSizePreset] or SERENE_DIAMETER_PRESET_MUL.default
		local sereneSize = math.max(SERENE_MIN_DIAMETER, math.floor(arcWidth * (SERENE_DIAMETER_AT_100 / ARC_BASE_WIDTH_AT_100) * presetMul + 0.5))

		sereneCircle:setWidth(sereneSize)
		sereneCircle:setHeight(sereneSize)
		sereneCircle:setThickness(sereneSize)
	end

	local healthInset = hpThickness
	local manaInset = mpThickness

	if sShield and pShield == "health" then
		manaShieldCircle:setThickness(hpAuxThickness)
		manaShieldCircle:setRadialInset(healthInset)
		healthInset = healthInset + hpAuxThickness
	elseif sShield and pShield == "mana" then
		manaShieldCircle:setThickness(mpAuxThickness)
		manaShieldCircle:setRadialInset(manaInset)
		manaInset = manaInset + mpAuxThickness
	else
		manaShieldCircle:setThickness(arcThickness)
		manaShieldCircle:setRadialInset(0)
	end

	if sHarm and pHarm == "health" then
		harmonyCircle:setThickness(hpAuxThickness)
		harmonyCircle:setRadialInset(healthInset)
	elseif sHarm and pHarm == "mana" then
		harmonyCircle:setThickness(mpAuxThickness)
		harmonyCircle:setRadialInset(manaInset)
	else
		harmonyCircle:setThickness(arcThickness)
		harmonyCircle:setRadialInset(0)
	end

	if sShield and pShield == "mana" then
		manaShieldCircle:setArcLayoutSide("right")
		manaShieldCircle:setStartAngle(45)
		manaShieldCircle:setFullSpan(90)
		manaShieldCircle:setFillFromEnd(true)
	elseif sShield and pShield == "health" then
		manaShieldCircle:setArcLayoutSide("left")
		manaShieldCircle:setStartAngle(225)
		manaShieldCircle:setFullSpan(90)
		manaShieldCircle:setFillFromEnd(false)
	else
		manaShieldCircle:setArcLayoutSide("left")
		manaShieldCircle:setStartAngle(225)
		manaShieldCircle:setFullSpan(90)
		manaShieldCircle:setFillFromEnd(false)
	end

	if sHarm and pHarm == "mana" then
		harmonyCircle:setArcLayoutSide("right")
		harmonyCircle:setStartAngle(45)
		harmonyCircle:setFullSpan(90)
		harmonyCircle:setFillFromEnd(true)
	elseif sHarm and pHarm == "health" then
		harmonyCircle:setArcLayoutSide("left")
		harmonyCircle:setStartAngle(225)
		harmonyCircle:setFullSpan(90)
		harmonyCircle:setFillFromEnd(false)
	else
		harmonyCircle:setArcLayoutSide("left")
		harmonyCircle:setStartAngle(225)
		harmonyCircle:setFullSpan(90)
		harmonyCircle:setFillFromEnd(false)
	end

	imageSizeBroad = math.max(1, healthCircle:getHeight())
	imageSizeThin = math.max(1, healthCircle:getWidth())
	manaShieldImageSizeBroad = math.max(1, manaShieldCircle:getHeight())
	manaShieldImageSizeThin = math.max(1, manaShieldCircle:getWidth())
end

function syncManaShieldHudOptions(options)
	lastManaShieldSplitKey = nil
	lastHarmonySplitKey = nil

	whenMapResizeChange()
end

local function hudOptionValue(options, key)
	if options and type(options) == "table" then
		local o = options[key]

		if type(o) == "table" then
			if o.pendingValue ~= nil then
				return o.pendingValue
			end

			return o.value
		end
	end

	if modules.client_options and modules.client_options.getOption then
		return modules.client_options.getOption(key)
	end

	return nil
end

function syncShowArcsFromClientOptions(show, options)
	show = toboolean(show)
	hudArcsAllowed = show

	if not healthCircle or not manaCircle then
		return
	end

	if not show then
		setHealthCircle(false)
		setManaCircle(false)

		if healthCheckBox then
			healthCheckBox:setChecked(false)
		end

		if manaCheckBox then
			manaCheckBox:setChecked(false)
		end

		if manaShieldCircle then
			manaShieldCircle:setVisible(false)
		end

		if harmonyCircle then
			harmonyCircle:setVisible(false)
		end

		if sereneCircle then
			sereneCircle:setVisible(false)
		end

		if arcConditionsBar then
			arcConditionsBar:setVisible(false)
		end

		lastManaShieldSplitKey = nil
		lastHarmonySplitKey = nil

		applyArcScaleByMapPanel()
		layoutHealthManaArcPositions()
		updateArcConditionsDisplay()

		return
	end

	setHealthCircle(true)
	setManaCircle(true)

	if healthCheckBox then
		healthCheckBox:setChecked(true)
	end

	if manaCheckBox then
		manaCheckBox:setChecked(true)
	end

	local size = hudOptionValue(options, "showArcsSize") or "default"

	if size == "small" then
		hudArcScaleMul = HUD_ARC_SCALE_PRESET_SMALL
		hudArcsSizePreset = "small"
	elseif size == "large" then
		hudArcScaleMul = HUD_ARC_SCALE_PRESET_LARGE
		hudArcsSizePreset = "large"
	else
		hudArcScaleMul = 1
		hudArcsSizePreset = "default"
	end

	local dist = hudOptionValue(options, "showArcsDistanceScroll")

	if type(dist) == "number" then
		setDistanceFromCenter(arcScrollPercentToDistancePixels(dist))
	end

	local op = hudOptionValue(options, "showArcsOpacityScroll")

	if type(op) == "number" then
		op = math.max(20, math.min(100, op))

		local a = op / 100

		healthCircle:setOpacity(a)
		manaCircle:setOpacity(a)

		if manaShieldCircle then
			manaShieldCircle:setOpacity(a)
		end

		if harmonyCircle then
			harmonyCircle:setOpacity(a)
		end

		if sereneCircle then
			sereneCircle:setOpacity(a)
		end
	end

	lastManaShieldSplitKey = nil
	lastHarmonySplitKey = nil

	applyArcScaleByMapPanel()
	whenMapResizeChange()
	updateSereneDisplay()
	updateArcConditionsDisplay()
	scheduleArcConditionsRefresh()
end

function setHealthCircle(value)
	value = toboolean(value)
	isHealthCircle = value

	if value then
		healthCircle:setVisible(true)
		whenMapResizeChange()
		scheduleArcConditionsRefresh()
	else
		healthCircle:setVisible(false)
		updateManaShieldDisplay()
		updateArcConditionsDisplay()
	end

	g_settings.set("healthcircle_hpcircle", not value)
end

function setManaCircle(value)
	value = toboolean(value)
	isManaCircle = value

	if value then
		manaCircle:setVisible(true)
		whenMapResizeChange()
		scheduleArcConditionsRefresh()
	else
		manaCircle:setVisible(false)
		updateManaShieldDisplay()
	end

	g_settings.set("healthcircle_mpcircle", not value)
end

function setDistanceFromCenter(value)
	distanceFromCenter = value

	whenMapResizeChange()
	g_settings.set("healthcircle_distfromcenter", value)
end

function setCircleOpacity(value)
	return
end

optionPanel = nil
healthCheckBox = nil
manaCheckBox = nil
chooseStatsBarDimension = nil
chooseStatsBarPlacement = nil
distFromCenScrollbar = nil

local suppressStatsBarComboSignal = false

local function isStatsBarComboValid(combo)
	return combo and not combo:isDestroyed() and combo.setCurrentOptionByData ~= nil
end

local function clearStatsBarMenuRefs()
	statsBarMenuLoaded = false
	healthCheckBox = nil
	manaCheckBox = nil
	distFromCenScrollbar = nil
	chooseStatsBarDimension = nil
	chooseStatsBarPlacement = nil
end

function addToOptionsModule()
	if optionPanel then
		modules.client_options.removeButton("Interface", "HP/MP Circle")

		if not optionPanel:isDestroyed() then
			optionPanel:destroy()
		end

		optionPanel = nil
	end

	clearStatsBarMenuRefs()

	optionPanel = g_ui.loadUI("option_healthcircle", modules.client_options:getPanel())
	healthCheckBox = optionPanel:recursiveGetChildById("healthCheckBox")
	manaCheckBox = optionPanel:recursiveGetChildById("manaCheckBox")
	chooseStatsBarDimension = optionPanel:recursiveGetChildById("chooseStatsBarDimension")
	chooseStatsBarPlacement = optionPanel:recursiveGetChildById("chooseStatsBarPlacement")
	distFromCenScrollbar = optionPanel:recursiveGetChildById("distFromCenScrollbar")

	if not isStatsBarComboValid(chooseStatsBarPlacement) or not isStatsBarComboValid(chooseStatsBarDimension) then
		clearStatsBarMenuRefs()

		return
	end

	chooseStatsBarPlacement:addOption(tr("Top"), "top")
	chooseStatsBarPlacement:addOption(tr("Bottom"), "bottom")
	chooseStatsBarDimension:addOption(tr("Hide"), "hide")
	chooseStatsBarDimension:addOption(tr("Compact"), "compact")
	chooseStatsBarDimension:addOption(tr("Default"), "default")
	chooseStatsBarDimension:addOption(tr("Large"), "large")
	chooseStatsBarDimension:addOption(tr("Parallel"), "parallel")

	statsBarMenuLoaded = true
	suppressStatsBarComboSignal = true

	chooseStatsBarDimension:setCurrentOptionByData(g_settings.getString("statsbar_dimension"), true)
	chooseStatsBarPlacement:setCurrentOptionByData(g_settings.getString("statsbar_placement"), true)

	suppressStatsBarComboSignal = false

	function chooseStatsBarPlacement.onOptionChange()
		updateStatsBar()
	end

	function chooseStatsBarDimension.onOptionChange()
		updateStatsBar()
	end

	healthCheckBox:setChecked(isHealthCircle)
	manaCheckBox:setChecked(isManaCircle)

	local distPct = arcDistancePixelsToScrollPercent(distanceFromCenter)

	distFromCenScrollbar:setText(tr("Distance") .. ": " .. distPct .. "%")
	distFromCenScrollbar:setValue(distPct)
	modules.client_options.addButton("Interface", "HP/MP Circle", optionPanel)
end

function updateStatsBar()
	if suppressStatsBarComboSignal or not statsBarMenuLoaded then
		return
	end

	if not isStatsBarComboValid(chooseStatsBarDimension) or not isStatsBarComboValid(chooseStatsBarPlacement) then
		clearStatsBarMenuRefs()

		return
	end

	local dimOpt = chooseStatsBarDimension:getCurrentOption()
	local placOpt = chooseStatsBarPlacement:getCurrentOption()

	if dimOpt and placOpt then
		modules.game_interface.updateStatsBar(dimOpt.data, placOpt.data)
		scheduleArcConditionsRefresh()
	end
end

function setStatsBarOption(dimension, placement)
	if not statsBarMenuLoaded then
		return
	end

	if not isStatsBarComboValid(chooseStatsBarDimension) or not isStatsBarComboValid(chooseStatsBarPlacement) then
		clearStatsBarMenuRefs()

		return
	end

	if placement == nil or placement == "" then
		placement = g_settings.getString("statsbar_placement")

		if placement == "" then
			placement = "top"
		end
	end

	if dimension == nil or dimension == "" or dimension == "hide" then
		dimension = g_settings.getString("statsbar_dimension")

		if dimension == "" or dimension == "hide" then
			dimension = "compact"
		end
	end

	suppressStatsBarComboSignal = true

	chooseStatsBarPlacement:setCurrentOptionByData(placement, true)
	chooseStatsBarDimension:setCurrentOptionByData(dimension, true)

	suppressStatsBarComboSignal = false
end

function destroyOptionsModule()
	modules.client_options.removeButton("Interface", "HP/MP Circle")

	if optionPanel and not optionPanel:isDestroyed() then
		optionPanel:destroy()
	end

	optionPanel = nil

	clearStatsBarMenuRefs()
end
