-- chunkname: @/game_minimap/minimap.lua

local minimapWidget, oldPos, fullscreenWidget
local virtualFloor = 7
local dragStartMouseY = 0
local dragStartMargin = 0
local persistentMinimapDataLoaded = false
local hdMinimapEnabled = true
local loadedSatelliteDir
local normalMinimapZoom
local HD_MINIMAP_ZOOM = 4
local findMinimapWidget
local currentDayTime = {
	m = 0,
	h = 12
}
local LAYER_FLOOR_MIN = 0
local LAYER_FLOOR_MAX = 15
local MINIMAP_OTMM_PATH = "/assets/minimap/minimap.otmm"
local MINIMAP_OTMM_FALLBACK_PATHS = {
	"/assets/minimap/minimap.otmm",
	"/minimap/minimap.otmm",
	-- our prebuilt file lives at data/minimap.otmm, i.e. in the root of the virtual filesystem;
	-- without this path the 7 MB of discovered map never loaded and the minimap started empty
	"/minimap.otmm"
}
local BUNDLED_MARKERS_PATH = "/minimap/markers.json"

-- The player's discovery progress. MUST have a different name than /minimap.otmm: the data/
-- directory is mounted on top (pushFront), so a file with the same name in the write directory
-- would be SHADOWED on read by the prebuilt map from the bundle and would never get loaded.
local USER_MINIMAP_OTMM_PATH = "/user_minimap.otmm"

local function refreshHdMinimap()
	if not mapController or not mapController.ui then
		return
	end

	local mini = findMinimapWidget and findMinimapWidget(mapController.ui) or
		(mapController.ui.minimapBorder and mapController.ui.minimapBorder.minimap)
	if not mini or mini:isDestroyed() then
		return
	end

	if not mini.setSatelliteMode then
		return
	end

	if not hdMinimapEnabled or not g_game.isOnline() then
		mini:setSatelliteMode(false)
		if normalMinimapZoom and mini.setZoom then
			mini:setZoom(normalMinimapZoom)
			normalMinimapZoom = nil
		end
		return
	end

	local satelliteDir = "/things/" .. g_game.getClientVersion()
	if loadedSatelliteDir ~= satelliteDir and g_satelliteMap and g_satelliteMap.loadFloors then
		g_satelliteMap.loadFloors(satelliteDir, 0, 15)
		loadedSatelliteDir = satelliteDir
	end

	mini:setSatelliteMode(true)
	if mini.getZoom and mini.setZoom and normalMinimapZoom == nil then
		normalMinimapZoom = mini:getZoom()
		mini:setZoom(HD_MINIMAP_ZOOM)
	end
end

function setHdMinimapEnabled(enabled)
	hdMinimapEnabled = enabled == true
	refreshHdMinimap()
end

local function normalizeFsPath(path)
	if not path or path == "" then
		return ""
	end

	path = path:gsub("\\", "/"):gsub("/+$", "")

	return path:lower()
end

local function isWriteDirPath(realDir, writeDir)
	local normalizedReal = normalizeFsPath(realDir)
	local normalizedWrite = normalizeFsPath(writeDir)

	return normalizedReal ~= "" and normalizedReal == normalizedWrite
end

local function loadMinimapOtmm()
	if not g_minimap.loadOtmm then
		g_logger.warning("[game_minimap] g_minimap.loadOtmm is not available")

		return nil
	end

	local writeDir = g_resources.getWriteDir()
	local foundAny = false
	local foundBundled = false

	for _, path in ipairs(MINIMAP_OTMM_FALLBACK_PATHS) do
		if not g_resources.fileExists(path) then
			-- block empty
		else
			foundAny = true

			local realDir = g_resources.getRealDir(path)

			if isWriteDirPath(realDir, writeDir) then
				-- block empty
			else
				foundBundled = true

				if g_minimap.loadOtmm(path) then
					return path
				end

				g_logger.warning(string.format("[game_minimap] loadOtmm failed for %s", path))
			end
		end
	end

	if not foundAny then
		g_logger.warning("[game_minimap] minimap.otmm not found in bundled paths")
	elseif not foundBundled then
		g_logger.warning("[game_minimap] minimap.otmm only found in user write dir; bundled load skipped")
	else
		g_logger.warning("[game_minimap] minimap.otmm found but failed to load (corrupt or unsupported version)")
	end

	return nil
end

function applyBundledMarkers(minimapWidget)
	if not minimapWidget or minimapWidget:isDestroyed() then
		return 0
	end

	minimapWidget:clearBundledFlags()

	local total = minimapWidget:loadBundledMarkerData(BUNDLED_MARKERS_PATH)

	if total == 0 and g_resources.fileExists(BUNDLED_MARKERS_PATH) then
		g_logger.warning(string.format("[game_minimap] Failed to parse bundled markers from %s", BUNDLED_MARKERS_PATH))

		return 0
	end

	minimapWidget:scheduleBundledFlagsRefresh()

	return total
end

local function loadBundledMinimapMarkers()
	local minimap = mapController.ui and mapController.ui.minimapBorder and mapController.ui.minimapBorder.minimap

	applyBundledMarkers(minimap)
end

local function loadPersistentMinimapData()
	if persistentMinimapDataLoaded then
		return true
	end

	local ui = mapController.ui
	local minimap = ui and not ui:isDestroyed() and ui.minimapBorder and ui.minimapBorder.minimap

	if not minimap or minimap:isDestroyed() then
		return false
	end

	g_minimap.clean()
	loadMinimapOtmm()

	-- Overlay of the player's progress ON TOP of the prebuilt map from the bundle: blocks loaded
	-- from OTMM are marked as seen, so every subsequent save is a safe union of both sources.
	if g_minimap.loadOtmm and g_resources.fileExists(USER_MINIMAP_OTMM_PATH) then
		if not g_minimap.loadOtmm(USER_MINIMAP_OTMM_PATH) then
			g_logger.warning("[game_minimap] failed to load minimap progress " .. USER_MINIMAP_OTMM_PATH)
		end
	end

	minimap:load()
	loadBundledMinimapMarkers()

	persistentMinimapDataLoaded = true

	return true
end

local function layerMarginTopForFloor(z)
	z = math.max(LAYER_FLOOR_MIN, math.min(LAYER_FLOOR_MAX, z))

	return (z + 1) * 4 - 4
end

local function refreshVirtualFloors()
	local layersPanel = mapController.ui and mapController.ui.layersPanel

	if not layersPanel or layersPanel:isDestroyed() then
		return
	end

	local mark = layersPanel:getChildById("layersMark")

	if not mark or mark:isDestroyed() then
		return
	end

	mark:setMarginTop(layerMarginTopForFloor(virtualFloor))
end

local function setupLayersMarkDrag(mark)
	if not mark or mark:isDestroyed() then
		return
	end

	function mark.onMousePress(widget, pos, button)
		if button == MouseLeftButton then
			dragStartMouseY = pos.y
			dragStartMargin = layerMarginTopForFloor(virtualFloor)
		end
	end

	function mark.onMouseMove(widget, mousePos, mouseMoved)
		if not widget:isPressed() then
			return
		end

		local dyTotal = mousePos.y - dragStartMouseY
		local rawMargin = dragStartMargin + dyTotal
		local minM = layerMarginTopForFloor(LAYER_FLOOR_MIN)
		local maxM = layerMarginTopForFloor(LAYER_FLOOR_MAX)

		rawMargin = math.max(minM, math.min(maxM, rawMargin))

		local newFloor = math.floor(rawMargin / 4)

		if newFloor ~= virtualFloor then
			local mini = mapController.ui.minimapBorder.minimap

			while newFloor > virtualFloor do
				if not mini:floorDown() then
					break
				end

				virtualFloor = virtualFloor + 1
			end

			while newFloor < virtualFloor do
				if not mini:floorUp() then
					break
				end

				virtualFloor = virtualFloor - 1
			end
		end

		widget:setMarginTop(rawMargin)
	end

	function mark.onMouseRelease(widget, pos, button)
		if button == MouseLeftButton then
			refreshVirtualFloors()
		end
	end
end

local function setupLayersPanelWheel(layersPanel)
	if not layersPanel or layersPanel:isDestroyed() then
		return
	end

	local automapLayers = layersPanel:getChildById("automapLayers")

	if not automapLayers or automapLayers:isDestroyed() then
		return
	end

	local function onLayersWheel(widget, mousePos, direction)
		if not automapLayers:containsPoint(mousePos) then
			return false
		end

		if direction == MouseWheelUp then
			upLayer()
		elseif direction == MouseWheelDown then
			downLayer()
		end

		return true
	end

	layersPanel.onMouseWheel = onLayersWheel

	for _, child in ipairs(layersPanel:getChildren()) do
		child.onMouseWheel = onLayersWheel
	end
end

local function onPositionChange()
	local player = g_game.getLocalPlayer()

	if not player then
		return
	end

	local pos = player:getPosition()

	if not pos then
		return
	end

	local minimapWidget = mapController.ui.minimapBorder.minimap

	if not minimapWidget or minimapWidget:isDragging() then
		return
	end

	if not minimapWidget.fullMapView then
		minimapWidget:setCameraPosition(pos)
		minimapWidget:scheduleBundledFlagsRefresh()
	end

	minimapWidget:setCrossPosition(pos)

	virtualFloor = pos.z
	refreshVirtualFloors()
end

local function onUpdatePlayerPartyPosition(playerName, vocationId, position, isLeader)
	local mini = mapController and mapController.ui and mapController.ui.minimapBorder and mapController.ui.minimapBorder.minimap

	if not mini or mini:isDestroyed() then
		return
	end

	if not playerName or not position then
		return
	end

	local localPlayer = g_game.getLocalPlayer()

	if localPlayer and localPlayer:getName() == playerName then
		return
	end

	mini:setPartyMemberPosition(playerName, vocationId, {
		x = position.x,
		y = position.y,
		z = position.z
	}, isLeader)
end

mapController = Controller:new()

mapController:setUI("minimap", modules.game_interface.getMainRightPanel())

local function getLayoutRoot(ui, horizontal)
	if not ui or ui:isDestroyed() then
		return nil
	end

	return ui:getChildById(horizontal and "layoutHorizontal" or "layoutDefault")
end

local function getLayoutWidget(layoutRoot, widgetId)
	if not layoutRoot or layoutRoot:isDestroyed() then
		return nil
	end

	return layoutRoot:getChildById(widgetId)
end

local function findPhantomStyleBackground(ui)
	if not ui or ui:isDestroyed() then
		return nil
	end

	if ui._phantomStyleBackground and not ui._phantomStyleBackground:isDestroyed() then
		return ui._phantomStyleBackground
	end

	local children = ui:getChildren()

	for i = 1, #children do
		local child = children[i]

		if child and not child:isDestroyed() then
			local id = child:getId()

			if id ~= "layoutDefault" and id ~= "layoutHorizontal" then
				local src = child.getImageSource and child:getImageSource() or ""

				if src:find("/images/ui/background", 1, true) then
					ui._phantomStyleBackground = child

					return child
				end
			end
		end
	end

	return nil
end

local function setPhantomStyleBackgroundVisible(ui, visible)
	local background = findPhantomStyleBackground(ui)

	if background then
		background:setVisible(visible)
	end
end

findMinimapWidget = function(ui)
	if not ui or ui:isDestroyed() then
		return nil
	end

	local defaultBorder = getLayoutWidget(getLayoutRoot(ui, false), "minimapBorder")
	local mini = defaultBorder and defaultBorder:getChildById("minimap")

	if mini and not mini:isDestroyed() then
		return mini
	end

	local horizontalBorder = getLayoutWidget(getLayoutRoot(ui, true), "minimapBorder")

	return horizontalBorder and horizontalBorder:getChildById("minimap")
end

local function syncMinimapLayoutAliases(layoutRoot)
	local ui = mapController.ui

	if not ui or ui:isDestroyed() or not layoutRoot or layoutRoot:isDestroyed() then
		return
	end

	ui.minimapBorder = getLayoutWidget(layoutRoot, "minimapBorder")
	ui.layersPanel = getLayoutWidget(layoutRoot, "layersPanel")
	ui.minimapControls = getLayoutWidget(layoutRoot, "minimapControls")
	ui.rosePanel = getLayoutWidget(layoutRoot, "rosePanel")
end

local function recalcMainRightPanelHeight()
	if modules.game_mainpanel and modules.game_mainpanel.reloadMainPanelSizes then
		modules.game_mainpanel.reloadMainPanelSizes()

		return
	end

	local mainRightPanel = modules.game_interface.getMainRightPanel()

	if not mainRightPanel or mainRightPanel:isDestroyed() then
		return
	end

	local usedHeight = mainRightPanel:getPaddingTop() + mainRightPanel:getPaddingBottom()
	local children = mainRightPanel:getChildren()

	for i = 1, #children do
		local child = children[i]

		if child and child:isExplicitlyVisible() then
			usedHeight = usedHeight + child:getHeight() + child:getMarginTop() + child:getMarginBottom()
		end
	end

	if usedHeight > 0 then
		mainRightPanel:setHeight(usedHeight)
	end
end

local function findMinimapDropTarget(window, mousePos)
	local root = g_ui.getRootWidget()

	if not root or not window then
		return nil
	end

	local children = root:recursiveGetChildrenByPos(mousePos)

	for i = 1, #children do
		local child = children[i]

		if child ~= window and child:getClassName() == "UIMiniWindowContainer" and type(child.onDrop) == "function" and child:onDrop(window, mousePos) then
			return child
		end
	end

	return nil
end

local minimapDragDockRefreshEvent

local function refreshMinimapDragDockLayout()
	minimapDragDockRefreshEvent = nil

	if modules.game_interface and modules.game_interface.refreshStatsBarDockLayout then
		modules.game_interface.refreshStatsBarDockLayout()
	end

	local ui = mapController.ui

	if ui and not ui:isDestroyed() and ui._horizontalDragActive then
		ui:raise()
	end

	addEvent(recalcMainRightPanelHeight)
end

local function queueMinimapDragDockLayoutRefresh()
	if minimapDragDockRefreshEvent then
		return
	end

	minimapDragDockRefreshEvent = addEvent(refreshMinimapDragDockLayout)
end

local function setupHorizontalDragHandle(handle)
	if not handle or handle:isDestroyed() then
		return
	end

	local window = mapController.ui

	if not window or window:isDestroyed() then
		return
	end

	function handle.onMousePress(_, mousePos, button)
		if button ~= MouseLeftButton then
			return false
		end

		window:raise()

		if window.onDragEnter then
			window:onDragEnter(mousePos)
		end

		window._horizontalDragActive = true

		queueMinimapDragDockLayoutRefresh()

		return true
	end

	function handle.onMouseMove(_, mousePos, mouseMoved)
		if not window._horizontalDragActive or not window.onDragMove then
			return false
		end

		local moved = window:onDragMove(mousePos, mouseMoved)

		queueMinimapDragDockLayoutRefresh()

		return moved
	end

	function handle.onMouseRelease(_, mousePos, button)
		if button ~= MouseLeftButton or not window._horizontalDragActive then
			return false
		end

		window._horizontalDragActive = false

		if window.onDragLeave then
			local dropped = findMinimapDropTarget(window, mousePos)

			window:onDragLeave(dropped, mousePos)
		end

		queueMinimapDragDockLayoutRefresh()

		return true
	end
end

local lastHorizontalSide

local function resolveHorizontalSide(container)
	local current = container

	for _ = 1, 12 do
		if not current then
			break
		end

		local id = current.getId and current:getId() or nil

		if id == "gameLeftTopPanel" then
			return "left"
		end

		if id == "gameRightTopPanel" then
			return "right"
		end

		current = current.getParent and current:getParent() or nil
	end

	return "right"
end

local function applyHorizontalControlsLayout(controls, mirror)
	if not controls or controls:isDestroyed() then
		return
	end

	local layerDown = controls:getChildById("layerDown")
	local zoomIn = controls:getChildById("zoomIn")
	local layerUp = controls:getChildById("layerUp")
	local zoomOut = controls:getChildById("zoomOut")

	if not layerDown or not zoomIn or not layerUp or not zoomOut then
		return
	end

	local layerDownId = layerDown:getId()
	local layerUpId = layerUp:getId()

	if mirror then
		layerDown:breakAnchors()
		layerDown:addAnchor(AnchorLeft, "parent", AnchorLeft)
		layerDown:addAnchor(AnchorBottom, "parent", AnchorBottom)
		zoomIn:breakAnchors()
		zoomIn:addAnchor(AnchorLeft, layerDownId, AnchorRight)
		zoomIn:addAnchor(AnchorBottom, "parent", AnchorBottom)
		zoomIn:setMarginLeft(2)
		zoomIn:setMarginRight(0)
		layerUp:breakAnchors()
		layerUp:addAnchor(AnchorLeft, "parent", AnchorLeft)
		layerUp:addAnchor(AnchorBottom, layerDownId, AnchorTop)
		layerUp:setMarginBottom(2)
		zoomOut:breakAnchors()
		zoomOut:addAnchor(AnchorLeft, layerUpId, AnchorRight)
		zoomOut:addAnchor(AnchorBottom, layerUpId, AnchorBottom)
		zoomOut:setMarginLeft(2)
		zoomOut:setMarginRight(0)
	else
		layerDown:breakAnchors()
		layerDown:addAnchor(AnchorRight, "parent", AnchorRight)
		layerDown:addAnchor(AnchorBottom, "parent", AnchorBottom)
		zoomIn:breakAnchors()
		zoomIn:addAnchor(AnchorRight, layerDownId, AnchorLeft)
		zoomIn:addAnchor(AnchorBottom, "parent", AnchorBottom)
		zoomIn:setMarginRight(2)
		zoomIn:setMarginLeft(0)
		layerUp:breakAnchors()
		layerUp:addAnchor(AnchorRight, "parent", AnchorRight)
		layerUp:addAnchor(AnchorBottom, layerDownId, AnchorTop)
		layerUp:setMarginBottom(2)
		zoomOut:breakAnchors()
		zoomOut:addAnchor(AnchorRight, layerUpId, AnchorLeft)
		zoomOut:addAnchor(AnchorBottom, layerUpId, AnchorBottom)
		zoomOut:setMarginRight(2)
		zoomOut:setMarginLeft(0)
	end
end

local function applyHorizontalPanelLayout(horizontalRoot, side)
	if not horizontalRoot or horizontalRoot:isDestroyed() then
		return
	end

	local borderId = "minimapBorder"
	local fullMap = getLayoutWidget(horizontalRoot, "fullMap")
	local controls = getLayoutWidget(horizontalRoot, "minimapControls")
	local rose = getLayoutWidget(horizontalRoot, "rosePanel")
	local drag = getLayoutWidget(horizontalRoot, "horizontalDragHandle")

	if not fullMap or not controls or not rose or not drag then
		return
	end

	local mirror = side == "left"

	if mirror then
		fullMap:breakAnchors()
		fullMap:addAnchor(AnchorRight, borderId, AnchorRight)
		fullMap:addAnchor(AnchorBottom, borderId, AnchorBottom)
		fullMap:setMarginRight(3)
		fullMap:setMarginLeft(0)
		fullMap:setMarginBottom(3)
		controls:breakAnchors()
		controls:addAnchor(AnchorLeft, borderId, AnchorLeft)
		controls:addAnchor(AnchorBottom, borderId, AnchorBottom)
		controls:setMarginLeft(3)
		controls:setMarginRight(0)
		controls:setMarginBottom(3)
		rose:breakAnchors()
		rose:addAnchor(AnchorTop, borderId, AnchorTop)
		rose:addAnchor(AnchorLeft, borderId, AnchorLeft)
		rose:setMarginTop(3)
		rose:setMarginLeft(3)
		rose:setMarginRight(0)
		drag:breakAnchors()
		drag:addAnchor(AnchorTop, borderId, AnchorTop)
		drag:addAnchor(AnchorRight, borderId, AnchorRight)
		drag:setMarginTop(1)
		drag:setMarginRight(1)
		drag:setMarginLeft(0)
		drag:setImageSource("/images/ui/miniborder-top-right")
	else
		fullMap:breakAnchors()
		fullMap:addAnchor(AnchorLeft, borderId, AnchorLeft)
		fullMap:addAnchor(AnchorBottom, borderId, AnchorBottom)
		fullMap:setMarginLeft(3)
		fullMap:setMarginRight(0)
		fullMap:setMarginBottom(3)
		controls:breakAnchors()
		controls:addAnchor(AnchorRight, borderId, AnchorRight)
		controls:addAnchor(AnchorBottom, borderId, AnchorBottom)
		controls:setMarginRight(3)
		controls:setMarginLeft(0)
		controls:setMarginBottom(3)
		rose:breakAnchors()
		rose:addAnchor(AnchorTop, borderId, AnchorTop)
		rose:addAnchor(AnchorRight, borderId, AnchorRight)
		rose:setMarginTop(3)
		rose:setMarginRight(3)
		rose:setMarginLeft(0)
		drag:breakAnchors()
		drag:addAnchor(AnchorTop, borderId, AnchorTop)
		drag:addAnchor(AnchorLeft, borderId, AnchorLeft)
		drag:setMarginTop(1)
		drag:setMarginLeft(1)
		drag:setMarginRight(0)
		drag:setImageSource("/images/ui/miniborder-top-left")
	end

	applyHorizontalControlsLayout(controls, mirror)

	lastHorizontalSide = side
end

local function applyLayoutMode(isHorizontal, container)
	local ui = mapController.ui

	if not ui or ui:isDestroyed() then
		return
	end

	local defaultRoot = getLayoutRoot(ui, false)
	local horizontalRoot = getLayoutRoot(ui, true)

	if not defaultRoot or defaultRoot:isDestroyed() or not horizontalRoot or horizontalRoot:isDestroyed() then
		return
	end

	local showHorizontal = isHorizontal == true
	local horizontalSide = showHorizontal and resolveHorizontalSide(container) or nil
	local dragHandle = getLayoutWidget(horizontalRoot, "horizontalDragHandle")

	setPhantomStyleBackgroundVisible(ui, not showHorizontal)

	if defaultRoot:isVisible() == not showHorizontal and horizontalRoot:isVisible() == showHorizontal then
		if showHorizontal then
			if lastHorizontalSide ~= horizontalSide then
				applyHorizontalPanelLayout(horizontalRoot, horizontalSide)
				addEvent(function()
					if ui and not ui:isDestroyed() then
						ui:updateLayout()
					end
				end)
			end

			if dragHandle and not dragHandle:isDestroyed() then
				dragHandle:raise()
			end
		else
			lastHorizontalSide = nil
		end

		return
	end

	local mini = findMinimapWidget(ui)

	defaultRoot:setVisible(not showHorizontal)
	horizontalRoot:setVisible(showHorizontal)

	local activeRoot = showHorizontal and horizontalRoot or defaultRoot
	local border = getLayoutWidget(activeRoot, "minimapBorder")

	if mini and not mini:isDestroyed() and border and not border:isDestroyed() and mini:getParent() ~= border then
		mini:setParent(border)
		mini:fill("parent")
		mini:setMargin(1)
	end

	syncMinimapLayoutAliases(activeRoot)

	if showHorizontal then
		applyHorizontalPanelLayout(horizontalRoot, horizontalSide)
	else
		lastHorizontalSide = nil
	end

	if showHorizontal and dragHandle and not dragHandle:isDestroyed() then
		dragHandle:raise()
	end

	addEvent(function()
		if not ui or ui:isDestroyed() then
			return
		end

		ui:updateLayout()

		if not showHorizontal and ui.minimapBorder and not ui.minimapBorder:isDestroyed() then
			ui.minimapBorder:setSize({
				width = 108,
				height = 111
			})
		end

		if showHorizontal and dragHandle and not dragHandle:isDestroyed() then
			dragHandle:raise()
		end
	end)
end

local function applyContainerLayout(container)
	if not container or container:isDestroyed() then
		return
	end

	local ui = mapController.ui

	if not ui or ui:isDestroyed() then
		return
	end

	local isHorizontal = container.isHorizontalPanel == true
	local defaultHeight = ui.panelHeight or 115

	if isHorizontal then
		local available = container:getHeight() - container:getPaddingTop() - container:getPaddingBottom()

		if available > 0 then
			ui:setHeight(available)
		end
	else
		ui:setHeight(defaultHeight)
	end

	applyLayoutMode(isHorizontal, container)
	addEvent(recalcMainRightPanelHeight)
end

local function adjustMinimapToContainer(_, container)
	applyContainerLayout(container)
end

function onChangeWorldTime(hour, minute)
	currentDayTime = {
		h = hour % 24,
		m = minute
	}

	mapController:scheduleEvent(function()
		local nextH = currentDayTime.h
		local nextM = currentDayTime.m + 12

		if nextM >= 60 then
			nextH = nextH + 1
			nextM = nextM - 60
		end

		onChangeWorldTime(nextH, nextM)
	end, 30000, "dayTime")

	local position = math.floor(0.08611111111111111 * (hour * 60 + minute))
	local mainWidth = 31
	local secondaryWidth = 0

	if position + 31 >= 124 then
		secondaryWidth = position + 31 - 124 + 1
		mainWidth = 31 - secondaryWidth
	end

	local function applyWorldTimeToRose(rosePanel)
		if not rosePanel or rosePanel:isDestroyed() then
			return
		end

		local ambients = rosePanel.ambients

		if not ambients or ambients:isDestroyed() then
			return
		end

		ambients.main:setWidth(mainWidth)
		ambients.secondary:setWidth(secondaryWidth)

		if secondaryWidth == 0 then
			ambients.secondary:hide()
		else
			ambients.secondary:setImageClip("0 0 " .. secondaryWidth .. " 31")
			ambients.secondary:show()
		end

		if mainWidth == 0 then
			ambients.main:hide()
		else
			ambients.main:setImageClip(position .. " 0 " .. mainWidth .. " 31")
			ambients.main:show()
		end
	end

	local ui = mapController.ui

	if ui and not ui:isDestroyed() then
		applyWorldTimeToRose(getLayoutWidget(getLayoutRoot(ui, false), "rosePanel"))
		applyWorldTimeToRose(getLayoutWidget(getLayoutRoot(ui, true), "rosePanel"))
	end
end

function mapController:onInit()
	if not g_settings.getBoolean("hdMinimapSatelliteInitialized") then
		hdMinimapEnabled = true
		g_settings.set("hdMinimap", true)
		g_settings.set("hdMinimapSatelliteInitialized", true)
	end
	syncMinimapLayoutAliases(getLayoutRoot(self.ui, false))

	local mini = findMinimapWidget(self.ui)

	if mini and not mini:isDestroyed() then
		mini:getChildById("floorUpButton"):hide()
		mini:getChildById("floorDownButton"):hide()
		mini:getChildById("zoomInButton"):hide()
		mini:getChildById("zoomOutButton"):hide()
		mini:getChildById("resetButton"):hide()
	end

	if not Services or not Services.minimap or Services.minimap == "" then
		for _, id in ipairs({ "downloadMapButton", "downloadMapButtonHorizontal" }) do
			local downloadButton = self.ui:recursiveGetChildById(id)
			if downloadButton then
				downloadButton:hide()
			end
		end
	end

	local defaultLayers = getLayoutWidget(getLayoutRoot(self.ui, false), "layersPanel")
	local horizontalLayers = getLayoutWidget(getLayoutRoot(self.ui, true), "layersPanel")

	if defaultLayers then
		setupLayersMarkDrag(defaultLayers:getChildById("layersMark"))
		setupLayersPanelWheel(defaultLayers)
	end

	if horizontalLayers then
		setupLayersMarkDrag(horizontalLayers:getChildById("layersMark"))
		setupLayersPanelWheel(horizontalLayers)
	end

	setupHorizontalDragHandle(getLayoutWidget(getLayoutRoot(self.ui, true), "horizontalDragHandle"))

	self.ui.moveOnlyToMain = true
	self.ui.allowHorizontalDrop = true
	self.ui.onContainerChanged = adjustMinimapToContainer

	local topBar = self.ui:recursiveGetChildById("miniwindowTopBar")

	if topBar and not topBar:isDestroyed() then
		topBar:setPhantom(false)
		topBar:raise()
	end

	applyContainerLayout(self.ui:getParent())
	self:scheduleEvent(loadPersistentMinimapData, 250, "persistentMinimapData")
end

function mapController:onGameStart()
	mapController:registerEvents(g_game, {
		onChangeWorldTime = onChangeWorldTime,
		onUpdatePlayerPartyPosition = onUpdatePlayerPartyPosition
	})
	mapController:registerEvents(LocalPlayer, {
		onPositionChange = onPositionChange
	}):execute()
	self.ui:setupOnStart()
	addEvent(function()
		if self.ui and not self.ui:isDestroyed() then
			applyContainerLayout(self.ui:getParent())
		end
	end)
	loadPersistentMinimapData()

	local minimap = self.ui.minimapBorder and self.ui.minimapBorder.minimap

	if minimap and not minimap:isDestroyed() then
		minimap:clearPartyMembers()
	end
	addEvent(refreshHdMinimap)
end

function mapController:onGameEnd()
	local minimap = self.ui.minimapBorder.minimap

	-- Without this, discovered tiles vanished on every logout: minimap:save() only stores
	-- flags/zoom into settings, and nobody persisted the map data itself. The guard protects the
	-- progress file from being overwritten with a nearly-empty map if game end arrived before the load.
	-- Controller:terminate() also calls onGameEnd when the client is closed while in game.
	if persistentMinimapDataLoaded and g_minimap.saveOtmm then
		g_minimap.saveOtmm(USER_MINIMAP_OTMM_PATH)
	end

	minimap:save()
	minimap:clearPartyMembers()
	minimap:setSatelliteMode(false)
	normalMinimapZoom = nil
end

function mapController:onTerminate()
	persistentMinimapDataLoaded = false
	loadedSatelliteDir = nil
end

function zoomIn()
	mapController.ui.minimapBorder.minimap:zoomIn()
end

function zoomOut()
	mapController.ui.minimapBorder.minimap:zoomOut()
end

function getMinimapZoomLevel()
	local minimap = mapController.ui and mapController.ui.minimapBorder and mapController.ui.minimapBorder.minimap

	if minimap and not minimap:isDestroyed() then
		return minimap:getZoom()
	end

	return nil
end

function setMinimapZoomLevel(zoom)
	local minimap = mapController.ui and mapController.ui.minimapBorder and mapController.ui.minimapBorder.minimap

	if minimap and not minimap:isDestroyed() and type(zoom) == "number" then
		minimap.zoomMinimap = zoom

		minimap:setZoom(zoom)
	end
end

function fullscreen()
	local minimapWidget = mapController.ui.minimapBorder.minimap

	minimapWidget = minimapWidget or fullscreenWidget

	local zoom

	if not minimapWidget then
		return
	end

	if minimapWidget.fullMapView then
		fullscreenWidget = nil

		minimapWidget:setParent(mapController.ui.minimapBorder)
		minimapWidget:fill("parent")
		mapController.ui:show()

		zoom = minimapWidget.zoomMinimap

		g_keyboard.unbindKeyDown("Escape")

		minimapWidget.fullMapView = false
	else
		fullscreenWidget = minimapWidget

		mapController.ui:hide(true)
		minimapWidget:setParent(modules.game_interface.getRootPanel())
		minimapWidget:fill("parent")

		zoom = minimapWidget.zoomFullmap

		g_keyboard.bindKeyDown("Escape", fullscreen)

		minimapWidget.fullMapView = true
	end

	local pos = oldPos or minimapWidget:getCameraPosition()

	oldPos = minimapWidget:getCameraPosition()

	minimapWidget:setZoom(zoom)
	minimapWidget:setCameraPosition(pos)
end

function upLayer()
	if virtualFloor == LAYER_FLOOR_MIN then
		return
	end

	mapController.ui.minimapBorder.minimap:floorUp()

	virtualFloor = virtualFloor - 1

	refreshVirtualFloors()
end

function downLayer()
	if virtualFloor == LAYER_FLOOR_MAX then
		return
	end

	mapController.ui.minimapBorder.minimap:floorDown()

	virtualFloor = virtualFloor + 1

	refreshVirtualFloors()
end

function onClickRoseButton(dir)
	if dir == "north" then
		mapController.ui.minimapBorder.minimap:move(0, 1)
	elseif dir == "north-east" then
		mapController.ui.minimapBorder.minimap:move(-1, 1)
	elseif dir == "east" then
		mapController.ui.minimapBorder.minimap:move(-1, 0)
	elseif dir == "south-east" then
		mapController.ui.minimapBorder.minimap:move(-1, -1)
	elseif dir == "south" then
		mapController.ui.minimapBorder.minimap:move(0, -1)
	elseif dir == "south-west" then
		mapController.ui.minimapBorder.minimap:move(1, -1)
	elseif dir == "west" then
		mapController.ui.minimapBorder.minimap:move(1, 0)
	elseif dir == "north-west" then
		mapController.ui.minimapBorder.minimap:move(1, 1)
	end
end

function resetMap()
	mapController.ui.minimapBorder.minimap:reset()

	local player = g_game.getLocalPlayer()

	if player then
		virtualFloor = player:getPosition().z

		refreshVirtualFloors()
	end
end

function getMiniMapUi()
	return mapController.ui.minimapBorder.minimap
end

function downloadFullMap()
	local url = Services and Services.minimap
	if not url or url == "" then
		g_logger.error("[game_minimap] Services.minimap URL is not configured.")
		return
	end

	local minimap = getMiniMapUi()
	local button
	if mapController.ui then
		local horizontal = mapController.ui:recursiveGetChildById("downloadMapButtonHorizontal")
		local default = mapController.ui:recursiveGetChildById("downloadMapButton")
		button = horizontal and horizontal:isVisible() and horizontal or default
	end
	if button and not button:isDestroyed() then
		button:setEnabled(false)
		button:setText(tr("Downloading..."))
	end

	HTTP.download(url, "minimap.otmm", function(path, checksum, err)
		if button and not button:isDestroyed() then
			button:setEnabled(true)
			button:setText(tr("Download Map"))
		end

		if err then
			g_logger.error("[game_minimap] Failed to download full map: " .. tostring(err))
			if modules.game_textmessage then
				modules.game_textmessage.displayFailureMessage(tr("Failed to download the map."))
			end
			return
		end

		local content = g_resources.readFileContents("/downloads/" .. path)
		if not content or #content == 0 then
			g_logger.error("[game_minimap] Downloaded map is empty or unavailable.")
			if modules.game_textmessage then
				modules.game_textmessage.displayFailureMessage(tr("Failed to load the downloaded map."))
			end
			return
		end

		-- Some HTTP servers return an HTML error page without surfacing an error to
		-- g_http.download. Never replace the user's minimap unless the OTMM magic is valid.
		if #content < 12 or content:sub(1, 4) ~= "OTMM" then
			g_logger.error("[game_minimap] Downloaded file is not a valid OTMM map.")
			if modules.game_textmessage then
				modules.game_textmessage.displayFailureMessage(tr("The downloaded file is not a valid map."))
			end
			return
		end

		g_resources.writeFileContents(USER_MINIMAP_OTMM_PATH, content)
		g_minimap.clean()
		persistentMinimapDataLoaded = false
		loadPersistentMinimapData()

		local player = g_game.getLocalPlayer()
		if minimap and not minimap:isDestroyed() and player then
			minimap:setCameraPosition(player:getPosition())
		end

		g_logger.info("[game_minimap] Full map downloaded and reloaded successfully.")
		if modules.game_textmessage then
			modules.game_textmessage.displayGameMessage(tr("Map downloaded successfully."))
		end
	end)
end
