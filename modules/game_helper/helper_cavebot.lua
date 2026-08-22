-- chunkname: @/game_helper/helper_cavebot.lua

HelperCavebot = HelperCavebot or {}

local ctx
local waypoints = {}
local scripts = {}
local selectedIndex
local selectedScriptIndex
local scriptsWindow
local settingsWindow
local suppliesWindow
local currentIndex = 1
local enabled = false
local loopRoute = true
local recording = false
local lastRecordedPosition
local standUntil = 0
local tickEvent
local lastWalkAt = 0
local lastPosition
local stuckSince = 0
local luring = false
local stoppedForCreatures = false
local waypointMode = "Add"
local waypointDirection = "C"
local options = {
	waypointColors = true,
	autoRecorder = false,
	startNearest = true,
	debugHud = false,
	encryptRoute = false,
	debugHudValue = "NONE",
	cavebotDelay = 4,
	autoRecorderStep = 2,
	nodeDistance = 2,
	stopKillDistance = 2,
	walkDelay = 20,
	walkEnabled = true,
	clickEnabled = false,
	zRecovery = true,
	creaturesToStop = 8,
	creaturesToWalk = 2,
	ignoredCreatures = "",
	deathLabel = "(none)"
}

local DIRECTION_OFFSETS = {
	NW = { x = -1, y = -1 }, N = { x = 0, y = -1 }, NE = { x = 1, y = -1 },
	W = { x = -1, y = 0 }, C = { x = 0, y = 0 }, E = { x = 1, y = 0 },
	SW = { x = -1, y = 1 }, S = { x = 0, y = 1 }, SE = { x = 1, y = 1 }
}

local TICK_MS = 250
local WALK_RETRY_MS = 700
local STUCK_MS = 10000

local function widget(id)
	return ctx and ctx.getWidget and ctx.getWidget(id) or nil
end

local function copyPosition(pos)
	return pos and { x = pos.x, y = pos.y, z = pos.z } or nil
end

local function samePosition(a, b)
	return a and b and a.x == b.x and a.y == b.y and a.z == b.z
end

local function distance(a, b)
	if not a or not b or a.z ~= b.z then
		return 9999
	end
	return math.max(math.abs(a.x - b.x), math.abs(a.y - b.y))
end

local function isIgnoredCreature(creature)
	if not creature or not creature.getName then return false end
	local creatureName = (creature:getName() or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
	for name in tostring(options.ignoredCreatures or ""):gmatch("[^,]+") do
		name = name:lower():gsub("^%s+", ""):gsub("%s+$", "")
		if name ~= "" and name == creatureName then return true end
	end
	return false
end

function HelperCavebot.isCreatureIgnored(creature)
	return isIgnoredCreature(creature)
end

local function nearbyMonsterCount(playerPosition)
	local count = 0
	for _, creature in ipairs(g_map.getSpectators(playerPosition, false) or {}) do
		if creature and creature.isMonster and creature:isMonster() and
			(not creature.isDead or not creature:isDead()) and not isIgnoredCreature(creature) then
			count = count + 1
		end
	end
	return count
end

local function directionTo(fromPos, toPos)
	local dx = toPos.x - fromPos.x
	local dy = toPos.y - fromPos.y
	if dx > 0 and dy < 0 then return NorthEast end
	if dx > 0 and dy > 0 then return SouthEast end
	if dx < 0 and dy > 0 then return SouthWest end
	if dx < 0 and dy < 0 then return NorthWest end
	if dx > 0 then return East end
	if dx < 0 then return West end
	if dy > 0 then return South end
	if dy < 0 then return North end
	return nil
end

local function setStatus(text, color)
	local label = widget("cavebotStatus")
	if label then
		label:setText(text)
		label:setColor(color or "#c0c0c0")
	end
end

local function refreshToggleState()
	local value = widget("cavebotToggleValue")
	if value then
		value:setText(enabled and "On" or "Off")
		value:setColor(enabled and "#42d742" or "#ff3030")
	end
	local startStopButton = widget("cavebotStartStopButton")
	if startStopButton then
		startStopButton:setText(enabled and "Stop CaveBot" or "Start CaveBot")
		startStopButton:setColor(enabled and "#ff9090" or "#90e090")
	end
	local helperValue = widget("cavebotHelperStatusValue")
	local helperCheck = widget("checkbox")
	local helperEnabled = helperCheck and helperCheck:isChecked() or false
	if helperValue then
		helperValue:setText(helperEnabled and "Enabled" or "Disabled")
		helperValue:setColor(helperEnabled and "#42d742" or "#ff3030")
	end
end

local function requestSave()
	if ctx and ctx.requestAutoSave then
		ctx.requestAutoSave()
	end
end

local function paintRows()
	local list = widget("cavebotWaypointList")
	if not list then
		return
	end
	for _, row in ipairs(list:getChildren()) do
		if row.cavebotIndex then
			local active = row.cavebotIndex == selectedIndex
			row:setBackgroundColor(active and "#585858" or (row.cavebotIndex % 2 == 0 and "#414141" or "#484848"))
			local waypoint = waypoints[row.cavebotIndex]
			local typeColors = { Walk = "#79c7ff", Stand = "#f0d779", Node = "#b7dd82", ["Start Lure"] = "#ffbd69", ["End Lure"] = "#ff8d69", ["Dyn.Start"] = "#d49cff", ["Dyn.End"] = "#bd7dff", Script = "#71e3c1", Label = "#e3e371" }
			local normalColor = options.waypointColors and (typeColors[waypoint and waypoint.type] or "#c0c0c0") or "#c0c0c0"
			row:setColor(active and "#ff9854" or normalColor)
		end
	end
end

local function refreshList()
	local list = widget("cavebotWaypointList")
	if not list then
		return
	end
	list:destroyChildren()
	if selectedIndex and selectedIndex > #waypoints then
		selectedIndex = nil
	end
	for index, pos in ipairs(waypoints) do
		local row = g_ui.createWidget("Label", list)
		row.cavebotIndex = index
		row:setHeight(19)
		row:setFont("verdana-11px-monochrome")
		row:setText(string.format("%02d   %-10s  %d, %d, %d", index, pos.type or "Walk", pos.x, pos.y, pos.z))
		row:setTextOffset(topoint("5 0"))
		row:setPhantom(false)
		function row.onClick()
			selectedIndex = index
			paintRows()
		end
	end
	paintRows()
	local count = widget("cavebotWaypointCount")
	if count then
		count:setText(string.format("%d waypoint%s", #waypoints, #waypoints == 1 and "" or "s"))
	end
	local routeTitle = widget("cavebotRouteTitle")
	if routeTitle then
		routeTitle:setText(string.format("Route: New Route (%d WPs) *", #waypoints))
	end
end

local function scheduleTick()
	if tickEvent then
		removeEvent(tickEvent)
	end
	tickEvent = scheduleEvent(function()
		tickEvent = nil
		HelperCavebot.tick()
		if enabled or recording then
			scheduleTick()
		end
	end, TICK_MS)
end

function HelperCavebot.start()
	if #waypoints == 0 then
		setStatus("Adicione pelo menos um waypoint.", "#e08282")
		local check = widget("cavebotEnableCheckBox")
		if check then check:setChecked(false) end
		return
	end
	enabled = true
	refreshToggleState()
	if options.startNearest then
		local player = g_game.getLocalPlayer()
		local playerPos = player and player:getPosition()
		local bestDistance = 9999
		for index, waypoint in ipairs(waypoints) do
			local waypointDistance = distance(playerPos, waypoint)
			if waypointDistance < bestDistance then
				bestDistance = waypointDistance
				currentIndex = index
			end
		end
	else
		currentIndex = math.max(1, math.min(currentIndex, #waypoints))
	end
	lastPosition = nil
	stoppedForCreatures = false
	stuckSince = g_clock.millis()
	setStatus("Executando rota", "#82e082")
	local check = widget("cavebotEnableCheckBox")
	if check and not check:isChecked() then check:setChecked(true) end
	scheduleTick()
	requestSave()
end

function HelperCavebot.stop(message)
	enabled = false
	refreshToggleState()
	if tickEvent then
		removeEvent(tickEvent)
		tickEvent = nil
	end
	local player = g_game.getLocalPlayer()
	if player and player.isAutoWalking and player:isAutoWalking() then
		pcall(function() player:stopAutoWalk() end)
	end
	setStatus(message or "Parado", "#c0c0c0")
	local check = widget("cavebotEnableCheckBox")
	if check and check:isChecked() then check:setChecked(false) end
	if recording then scheduleTick() end
	requestSave()
end

function HelperCavebot.tick()
	if not g_game.isOnline() then
		return
	end
	local player = g_game.getLocalPlayer()
	if not player then return end
	local playerPosition = player:getPosition()
	if recording and (not lastRecordedPosition or distance(playerPosition, lastRecordedPosition) >= math.max(1, options.autoRecorderStep)) then
		waypoints[#waypoints + 1] = { x = playerPosition.x, y = playerPosition.y, z = playerPosition.z, type = "Walk" }
		lastRecordedPosition = copyPosition(playerPosition)
		refreshList()
		requestSave()
	end
	if not enabled then return end

	local target = g_game.getAttackingCreature()
	local monsterCount = nearbyMonsterCount(playerPosition)
	if stoppedForCreatures then
		stoppedForCreatures = monsterCount > options.creaturesToWalk
	elseif monsterCount >= options.creaturesToStop then
		stoppedForCreatures = true
	end
	local targetDistance = target and distance(playerPosition, target:getPosition()) or 9999
	if target and target:getHealthPercent() > 0 and not isIgnoredCreature(target) and
		not luring and stoppedForCreatures and targetDistance <= options.stopKillDistance then
		if player.isAutoWalking and player:isAutoWalking() then
			pcall(function() player:stopAutoWalk() end)
		end
		setStatus("Pausado em combate", "#ffcc66")
		return
	end

	local destination = waypoints[currentIndex]
	if not destination then
		if loopRoute then
			currentIndex = 1
			destination = waypoints[currentIndex]
		else
			HelperCavebot.stop("Rota concluida")
			return
		end
	end

	local pos = playerPosition
	if pos.z ~= destination.z then
		if options.zRecovery then
			local nearestIndex, nearestDistance
			for index, waypoint in ipairs(waypoints) do
				if waypoint.z == pos.z then
					local waypointDistance = distance(pos, waypoint)
					if not nearestDistance or waypointDistance < nearestDistance then
						nearestIndex, nearestDistance = index, waypointDistance
					end
				end
			end
			if nearestIndex then currentIndex = nearestIndex; destination = waypoints[currentIndex] end
		end
		if pos.z ~= destination.z then
		setStatus(string.format("Aguardando mudanca para andar %d", destination.z), "#ffcc66")
		return
		end
	end

	local waypointType = destination.type or "Walk"
	if waypointType == "Label" or waypointType == "Script" then
		currentIndex = currentIndex + 1
		setStatus(waypointType .. " " .. tostring(currentIndex - 1), "#ffcc66")
		return
	end
	local arrivalDistance = waypointType == "Node" and options.nodeDistance or 0
	if distance(pos, destination) <= arrivalDistance then
		if waypointType == "Stand" and standUntil == 0 then
			standUntil = g_clock.millis() + 1000
			setStatus("Stand 1s", "#ffcc66")
			return
		elseif standUntil > g_clock.millis() then
			return
		end
		if waypointType == "Start Lure" or waypointType == "Dyn.Start" then
			luring = true
		elseif waypointType == "End Lure" or waypointType == "Dyn.End" then
			luring = false
		end
		if waypointType == "Use" or waypointType == "Rope" or waypointType == "Shovel" or waypointType == "Hole" or waypointType == "Ladder" then
			local tile = g_map.getTile(destination)
			local thing = tile and tile:getTopUseThing()
			if thing then
				if waypointType == "Rope" then
					pcall(function() g_game.useInventoryItemWith(3003, thing, 0, true) end)
				elseif waypointType == "Shovel" or waypointType == "Hole" then
					pcall(function() g_game.useInventoryItemWith(3457, thing, 0, true) end)
				else
					pcall(function() g_game.use(thing) end)
				end
			end
		end
		standUntil = 0
		currentIndex = currentIndex + 1
		if currentIndex > #waypoints then
			if loopRoute then currentIndex = 1 else HelperCavebot.stop("Rota concluida") return end
		end
		lastPosition = copyPosition(pos)
		stuckSince = g_clock.millis()
		setStatus(string.format("Waypoint %d/%d", currentIndex, #waypoints), "#82e082")
		return
	end

	if not samePosition(pos, lastPosition) then
		lastPosition = copyPosition(pos)
		stuckSince = g_clock.millis()
	elseif g_clock.millis() - stuckSince >= STUCK_MS then
		setStatus("Sem caminho; tentando novamente", "#e08282")
		stuckSince = g_clock.millis()
	end

	if not options.walkEnabled and not options.clickEnabled then
		setStatus("Movement desativado", "#ffcc66")
		return
	end
	if g_clock.millis() - lastWalkAt >= math.max(WALK_RETRY_MS, options.walkDelay) then
		lastWalkAt = g_clock.millis()
		if options.clickEnabled and not options.walkEnabled then
			local stepDirection = directionTo(pos, destination)
			if stepDirection then g_game.walk(stepDirection) end
		else
			player:autoWalk(destination)
		end
		setStatus(string.format("Indo para %d/%d", currentIndex, #waypoints), "#82e082")
	end
end

function HelperCavebot.addCurrentPosition(waypointType)
	local player = g_game.getLocalPlayer()
	if not player then return end
	local pos = copyPosition(player:getPosition())
	local offset = DIRECTION_OFFSETS[waypointDirection] or DIRECTION_OFFSETS.C
	pos.x = pos.x + offset.x
	pos.y = pos.y + offset.y
	pos.type = waypointType or "Walk"
	if waypointMode == "Replace" and selectedIndex then
		waypoints[selectedIndex] = pos
	elseif waypointMode == "Insert" and selectedIndex then
		table.insert(waypoints, selectedIndex, pos)
	else
		waypoints[#waypoints + 1] = pos
		selectedIndex = #waypoints
	end
	refreshList()
	requestSave()
end

function HelperCavebot.setWaypointMode(mode)
	if mode == "Replace" or mode == "Add" or mode == "Insert" then waypointMode = mode end
	for _, name in ipairs({ "Replace", "Add", "Insert" }) do
		local check = widget("cavebotMode" .. name)
		if check and check:isChecked() ~= (name == waypointMode) then check:setChecked(name == waypointMode) end
	end
	requestSave()
end

function HelperCavebot.setDirection(direction)
	if DIRECTION_OFFSETS[direction] then waypointDirection = direction end
	setStatus("Direction: " .. waypointDirection, "#c0c0c0")
end

function HelperCavebot.setOption(name, checked)
	if options[name] ~= nil then options[name] = checked == true end
	if name == "autoRecorder" then
		local check = widget("cavebotRecordingCheckBox")
		if check and check:isChecked() ~= (checked == true) then check:setChecked(checked == true) end
		HelperCavebot.onRecordingChange(checked)
	elseif name == "waypointColors" then
		paintRows()
	end
	requestSave()
end

function HelperCavebot.setNumericOption(name, value)
	if options[name] ~= nil then options[name] = tonumber(value) or options[name] end
	requestSave()
end

function HelperCavebot.showInfo(message)
	setStatus(message or "CaveBot", "#c0c0c0")
end

local function refreshScripts()
	local list = scriptsWindow and not scriptsWindow:isDestroyed() and scriptsWindow:recursiveGetChildById("cavebotScriptList") or widget("cavebotScriptList")
	if not list then return end
	list:destroyChildren()
	for index, script in ipairs(scripts) do
		local row = g_ui.createWidget("Label", list)
		row:setHeight(19)
		row:setFont("verdana-11px-monochrome")
		row:setText(script.name or ("Script " .. index))
		row:setTextOffset(topoint("4 0"))
		row:setPhantom(false)
		row:setBackgroundColor(index == selectedScriptIndex and "#585858" or "#414141")
		function row.onClick()
			selectedScriptIndex = index
			refreshScripts()
		end
	end
end

function HelperCavebot.openScriptsWindow()
	if scriptsWindow and not scriptsWindow:isDestroyed() then
		HelperCavebot.closeScriptsWindow()
		return
	end
	scriptsWindow = g_ui.loadUI("cavebot_scripts", g_ui.getRootWidget())
	if scriptsWindow then
		scriptsWindow:show()
		scriptsWindow:raise()
		scriptsWindow:focus()
		refreshScripts()
	end
end

function HelperCavebot.closeScriptsWindow()
	if scriptsWindow and not scriptsWindow:isDestroyed() then
		scriptsWindow:destroy()
	end
	scriptsWindow = nil
end

local function settingsWidget(id)
	return settingsWindow and settingsWindow:recursiveGetChildById(id) or nil
end

local function clampNumber(value, fallback, minimum, maximum)
	value = tonumber(value) or fallback
	return math.max(minimum, math.min(maximum, value))
end

local function setSettingsText(id, value)
	local control = settingsWidget(id)
	if control then control:setText(tostring(value)) end
end

local function populateMovementSettings()
	setSettingsText("movementNodeDistance", options.nodeDistance)
	setSettingsText("movementWalkDelay", options.walkDelay)
	setSettingsText("movementStopKillDistance", options.stopKillDistance)
	setSettingsText("movementCreaturesToStop", options.creaturesToStop)
	setSettingsText("movementCreaturesToWalk", options.creaturesToWalk)
	setSettingsText("movementIgnoredCreatures", options.ignoredCreatures)
	setSettingsText("movementDeathLabel", options.deathLabel)
	local checks = {
		movementWalkCheck = options.walkEnabled,
		movementClickCheck = options.clickEnabled,
		movementRecoveryCheck = options.zRecovery
	}
	for id, checked in pairs(checks) do
		local control = settingsWidget(id)
		if control then control:setChecked(checked == true) end
	end
end

function HelperCavebot.openSettings()
	if settingsWindow and not settingsWindow:isDestroyed() then
		HelperCavebot.closeSettings()
		return
	end
	settingsWindow = g_ui.loadUI("cavebot_settings", g_ui.getRootWidget())
	if settingsWindow then
		populateMovementSettings()
		settingsWindow:show(); settingsWindow:raise(); settingsWindow:focus()
	end
end

function HelperCavebot.applySettings(closeAfter)
	if not settingsWindow then return end
	local function textOf(id)
		local control = settingsWidget(id)
		return control and control:getText() or ""
	end
	options.nodeDistance = clampNumber(textOf("movementNodeDistance"), 2, 1, 3)
	options.walkDelay = clampNumber(textOf("movementWalkDelay"), 20, 10, 5000)
	options.stopKillDistance = clampNumber(textOf("movementStopKillDistance"), 2, 1, 3)
	options.creaturesToStop = clampNumber(textOf("movementCreaturesToStop"), 8, 1, 99)
	options.creaturesToWalk = clampNumber(textOf("movementCreaturesToWalk"), 2, 0, 99)
	options.ignoredCreatures = textOf("movementIgnoredCreatures")
	options.deathLabel = textOf("movementDeathLabel")
	local walkCheck = settingsWidget("movementWalkCheck")
	local clickCheck = settingsWidget("movementClickCheck")
	local recoveryCheck = settingsWidget("movementRecoveryCheck")
	options.walkEnabled = walkCheck and walkCheck:isChecked() or false
	options.clickEnabled = clickCheck and clickCheck:isChecked() or false
	options.zRecovery = recoveryCheck and recoveryCheck:isChecked() or false
	populateMovementSettings()
	local settingsButton = widget("cavebotSettingsButton")
	if settingsButton then settingsButton:setText("CUSTOM") end
	requestSave()
	if closeAfter then HelperCavebot.closeSettings() end
end

function HelperCavebot.closeSettings()
	if settingsWindow and not settingsWindow:isDestroyed() then settingsWindow:destroy() end
	settingsWindow = nil
end

function HelperCavebot.settingsTab(name)
	if not settingsWindow then return end
	for _, panelName in ipairs({"movement", "combat", "supply", "presets"}) do
		local panel = settingsWindow:recursiveGetChildById(panelName .. "Panel")
		if panel then panel:setVisible(panelName == name) end
	end
end

function HelperCavebot.openSupplies()
	if suppliesWindow and not suppliesWindow:isDestroyed() then suppliesWindow:raise(); return end
	suppliesWindow = g_ui.loadUI("cavebot_supplies", g_ui.getRootWidget())
	if suppliesWindow then suppliesWindow:show(); suppliesWindow:raise(); suppliesWindow:focus() end
end

function HelperCavebot.closeSupplies()
	if suppliesWindow and not suppliesWindow:isDestroyed() then suppliesWindow:destroy() end
	suppliesWindow = nil
end

function HelperCavebot.saveScript()
	local nameField = scriptsWindow and scriptsWindow:recursiveGetChildById("cavebotScriptName") or nil
	local name = nameField and nameField:getText() or ""
	name = tostring(name):gsub("^%s+", ""):gsub("%s+$", "")
	if name == "" then name = "Script " .. tostring(#scripts + 1) end
	scripts[#scripts + 1] = { name = name, waypoints = {} }
	for _, pos in ipairs(waypoints) do
		scripts[#scripts].waypoints[#scripts[#scripts].waypoints + 1] = { x = pos.x, y = pos.y, z = pos.z, type = pos.type or "Walk" }
	end
	selectedScriptIndex = #scripts
	if nameField then nameField:setText("") end
	refreshScripts()
	requestSave()
end

function HelperCavebot.loadScript()
	local script = selectedScriptIndex and scripts[selectedScriptIndex]
	if not script then return end
	waypoints = {}
	for _, pos in ipairs(script.waypoints or {}) do
		waypoints[#waypoints + 1] = { x = pos.x, y = pos.y, z = pos.z, type = pos.type or "Walk" }
	end
	currentIndex = 1
	selectedIndex = nil
	refreshList()
	requestSave()
end

function HelperCavebot.deleteScript()
	if not selectedScriptIndex then return end
	table.remove(scripts, selectedScriptIndex)
	selectedScriptIndex = math.min(selectedScriptIndex, #scripts)
	if selectedScriptIndex == 0 then selectedScriptIndex = nil end
	refreshScripts()
	requestSave()
end

function HelperCavebot.onRecordingChange(checked)
	recording = checked == true
	lastRecordedPosition = nil
	local recordingButton = widget("cavebotRecordingCheckBox")
	if recordingButton then
		recordingButton:setText(recording and "Recording" or "Not Recording")
		recordingButton:setColor(recording and "#ffcc66" or "#c0c0c0")
	end
	if recording then
		setStatus("Gravando rota", "#ffcc66")
		scheduleTick()
	elseif not enabled then
		if tickEvent then
			removeEvent(tickEvent)
			tickEvent = nil
		end
		setStatus("Parado", "#c0c0c0")
	end
	requestSave()
end

function HelperCavebot.removeSelected()
	if not selectedIndex then return end
	table.remove(waypoints, selectedIndex)
	selectedIndex = math.min(selectedIndex, #waypoints)
	if selectedIndex == 0 then selectedIndex = nil end
	currentIndex = math.min(currentIndex, math.max(1, #waypoints))
	refreshList()
	requestSave()
end

function HelperCavebot.moveSelected(delta)
	if not selectedIndex then return end
	local target = selectedIndex + delta
	if target < 1 or target > #waypoints then return end
	waypoints[selectedIndex], waypoints[target] = waypoints[target], waypoints[selectedIndex]
	selectedIndex = target
	refreshList()
	requestSave()
end

function HelperCavebot.clear()
	HelperCavebot.stop("Rota limpa")
	waypoints = {}
	selectedIndex = nil
	currentIndex = 1
	refreshList()
	requestSave()
end

function HelperCavebot.onEnableChange(checked)
	if ctx and ctx.isLoadingConfig and ctx.isLoadingConfig() then return end
	if checked then HelperCavebot.start() else HelperCavebot.stop() end
end

function HelperCavebot.toggle()
	if enabled then
		HelperCavebot.stop()
	else
		HelperCavebot.start()
	end
	local check = widget("cavebotEnableCheckBox")
	if check and check:isChecked() ~= enabled then
		check:setChecked(enabled)
	end
end

function HelperCavebot.onLoopChange(checked)
	loopRoute = checked == true
	requestSave()
end

function HelperCavebot.collectConfig(config)
	config.cavebot = {
		enabled = enabled,
		loopRoute = loopRoute,
		currentIndex = currentIndex,
		waypoints = waypoints,
		scripts = scripts,
		recording = recording,
		waypointMode = waypointMode,
		waypointDirection = waypointDirection,
		options = options
	}
end

function HelperCavebot.loadFromConfig(config)
	local data = type(config.cavebot) == "table" and config.cavebot or {}
	waypoints = type(data.waypoints) == "table" and data.waypoints or {}
	for _, pos in ipairs(waypoints) do pos.type = pos.type or "Walk" end
	scripts = type(data.scripts) == "table" and data.scripts or {}
	loopRoute = data.loopRoute ~= false
	currentIndex = tonumber(data.currentIndex) or 1
	selectedIndex = nil
	refreshList()
	refreshScripts()
	local loopCheck = widget("cavebotLoopCheckBox")
	if loopCheck then loopCheck:setChecked(loopRoute) end
	local enableCheck = widget("cavebotEnableCheckBox")
	if enableCheck then enableCheck:setChecked(false) end
	HelperCavebot.stop("Parado")
	local recordingCheck = widget("cavebotRecordingCheckBox")
	if recordingCheck then recordingCheck:setChecked(data.recording == true) end
	recording = data.recording == true
	waypointMode = data.waypointMode or "Add"
	waypointDirection = DIRECTION_OFFSETS[data.waypointDirection] and data.waypointDirection or "C"
	if type(data.options) == "table" then
		for name, value in pairs(data.options) do if options[name] ~= nil then options[name] = value end end
	end
	HelperCavebot.setWaypointMode(waypointMode)
	if recording then scheduleTick() end
	if data.enabled == true and g_game.isOnline() then HelperCavebot.start() end
end

function HelperCavebot.init(context)
	ctx = context
	refreshList()
	refreshScripts()
end

function HelperCavebot.onShow()
	refreshList()
	refreshScripts()
	refreshToggleState()
	local recordingButton = widget("cavebotRecordingCheckBox")
	if recordingButton then
		recordingButton:setText(recording and "Recording" or "Not Recording")
		recordingButton:setColor(recording and "#ffcc66" or "#c0c0c0")
	end
end

function HelperCavebot.onHide()
end

function HelperCavebot.terminate()
	HelperCavebot.closeScriptsWindow()
	HelperCavebot.closeSupplies()
	HelperCavebot.closeSettings()
	HelperCavebot.stop()
	ctx = nil
end
