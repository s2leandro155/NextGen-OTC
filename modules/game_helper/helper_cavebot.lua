-- chunkname: @/game_helper/helper_cavebot.lua

HelperCavebot = HelperCavebot or {}

local ctx
local waypoints = {}
local scripts = {}
local selectedIndex
local selectedScriptIndex
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
			row:setColor(active and "#ff9854" or "#c0c0c0")
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
		row:setText(string.format("%02d   %-7s   %d, %d, %d", index, pos.type or "Walk", pos.x, pos.y, pos.z))
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
	currentIndex = math.max(1, math.min(currentIndex, #waypoints))
	lastPosition = nil
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
	if recording and not samePosition(playerPosition, lastRecordedPosition) then
		waypoints[#waypoints + 1] = { x = playerPosition.x, y = playerPosition.y, z = playerPosition.z, type = "Walk" }
		lastRecordedPosition = copyPosition(playerPosition)
		refreshList()
		requestSave()
	end
	if not enabled then return end

	local target = g_game.getAttackingCreature()
	if target and target:getHealthPercent() > 0 then
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
		setStatus(string.format("Aguardando mudanca para andar %d", destination.z), "#ffcc66")
		return
	end

	local waypointType = destination.type or "Walk"
	local arrivalDistance = waypointType == "Node" and 1 or 0
	if distance(pos, destination) <= arrivalDistance then
		if waypointType == "Stand" and standUntil == 0 then
			standUntil = g_clock.millis() + 1000
			setStatus("Stand 1s", "#ffcc66")
			return
		elseif standUntil > g_clock.millis() then
			return
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

	if g_clock.millis() - lastWalkAt >= WALK_RETRY_MS then
		lastWalkAt = g_clock.millis()
		pcall(function() player:autoWalk(destination) end)
		setStatus(string.format("Indo para %d/%d", currentIndex, #waypoints), "#82e082")
	end
end

function HelperCavebot.addCurrentPosition(waypointType)
	local player = g_game.getLocalPlayer()
	if not player then return end
	local pos = copyPosition(player:getPosition())
	pos.type = waypointType or "Walk"
	waypoints[#waypoints + 1] = pos
	selectedIndex = #waypoints
	refreshList()
	requestSave()
end

local function refreshScripts()
	local list = widget("cavebotScriptList")
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

function HelperCavebot.saveScript()
	local name = "Script " .. tostring(#scripts + 1)
	scripts[#scripts + 1] = { name = name, waypoints = {} }
	for _, pos in ipairs(waypoints) do
		scripts[#scripts].waypoints[#scripts[#scripts].waypoints + 1] = { x = pos.x, y = pos.y, z = pos.z, type = pos.type or "Walk" }
	end
	selectedScriptIndex = #scripts
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
	local recordingValue = widget("cavebotRecordingValue")
	if recordingValue then
		recordingValue:setText(recording and "Recording" or "Not Recording")
		recordingValue:setColor(recording and "#ffcc66" or "#c0c0c0")
	end
	if recording then
		setStatus("Gravando rota", "#ffcc66")
		scheduleTick()
	elseif not enabled then
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
		recording = recording
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
	local recordingValue = widget("cavebotRecordingValue")
	if recordingValue then
		recordingValue:setText(recording and "Recording" or "Not Recording")
		recordingValue:setColor(recording and "#ffcc66" or "#c0c0c0")
	end
end

function HelperCavebot.onHide()
end

function HelperCavebot.terminate()
	HelperCavebot.stop()
	ctx = nil
end
