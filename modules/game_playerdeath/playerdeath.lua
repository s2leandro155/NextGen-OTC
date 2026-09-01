-- chunkname: @/game_playerdeath/playerdeath.lua

deathController = Controller:new()

local autoRespawnEvent
local AUTO_RESPAWN_DELAY = 5000

local function cancelAutoRespawn()
	if autoRespawnEvent then
		removeEvent(autoRespawnEvent)
		autoRespawnEvent = nil
	end
end

function deathController:onInit()
	deathController:registerEvents(g_game, {
		onDeath = display
	})
end

function deathController:onTerminate()
	cancelAutoRespawn()
	deathController.ui = destroyWindows()
end

function deathController:onGameEnd()
	cancelAutoRespawn()
	deathController.ui = destroyWindows()
end

function destroyWindows()
	if deathController.ui and not deathController.ui:isDestroyed() then
		if g_modalManager then
			g_modalManager.hide(deathController.ui)
		end

		pcall(function()
			deathController.ui:ungrabKeyboard()
		end)
		deathController.ui:destroy()
	end

	if modules.game_interface and modules.game_interface.getRootPanel then
		local rootPanel = modules.game_interface.getRootPanel()

		if rootPanel then
			rootPanel:focus()
		end
	end

	if modules.game_console and modules.game_console.getConsole then
		local console = modules.game_console.getConsole()

		if console then
			console:focus()
		end
	end

	return nil
end

local function setStringColor(textTable, text, color)
	table.insert(textTable, text)
	table.insert(textTable, color)
end

local function tableToColoredText(t)
	local result = ""

	for i = 1, #t, 2 do
		local text = t[i] or ""
		local color = t[i + 1] or "#ffffff"

		result = result .. "{" .. text .. ", " .. color .. "}"
	end

	return result
end

function display(deathType, penalty)
	openWindow(deathType, penalty)
end

function openWindow(deathType, penalty)
	cancelAutoRespawn()
	deathController.ui = destroyWindows()
	deathController.ui = g_ui.displayUI("deathwindow", rootWidget)

	local window = deathController.ui
	local textLabel = window:recursiveGetChildById("labelText")
	local baseWidth = window.baseWidth or 369
	local baseHeight = window.baseHeight or 217
	local messageT = {}
	local extraHeight = 15

	if deathType == DeathType.Regular and penalty ~= nil and penalty ~= 100 then
		setStringColor(messageT, "Alas! Brave adventurer, you have met a sad fate.\nBut do not despair, for the gods will bring you back\ninto the world in exchange for a small sacrifice\n\n", "#c0c0c0")
		setStringColor(messageT, "This death penalty has been reduced by " .. tostring(penalty) .. "%\nbecause it was a unfair fight.\n\nSimply click on ", "#c0c0c0")
		setStringColor(messageT, "Ok ", "#ffffff")
		setStringColor(messageT, "to resume your journeys in game\nor on ", "#c0c0c0")
		setStringColor(messageT, "Cancel ", "#ffffff")
		setStringColor(messageT, "to get to your character list!\n\nClick on ", "#c0c0c0")
		setStringColor(messageT, "Store ", "#ffffff")
		setStringColor(messageT, "to resume your journeys and to shop\nblessings to ease the pain if you are unfortunate\nenough to lose another fight!", "#c0c0c0")

		extraHeight = 46
	else
		setStringColor(messageT, "Alas! Brave adventurer, you have met a sad fate.\nBut do not despair, for the gods will bring you back\ninto the world in exchange for a small sacrifice\n\nSimply click on ", "#c0c0c0")
		setStringColor(messageT, "Ok ", "#ffffff")
		setStringColor(messageT, "to resume your journeys in game\nor on ", "#c0c0c0")
		setStringColor(messageT, "Cancel ", "#ffffff")
		setStringColor(messageT, "to get to your character list!\n\nClick on ", "#c0c0c0")
		setStringColor(messageT, "Store ", "#ffffff")
		setStringColor(messageT, "to resume your journeys and to shop\nblessings to ease the pain if you are unfortunate\nenough to lose another fight!", "#c0c0c0")

		extraHeight = 15
	end

	window:setWidth(baseWidth)
	window:setHeight(baseHeight + extraHeight)

	if textLabel then
		textLabel:setColoredText(tableToColoredText(messageT))
	end

	if g_modalManager then
		g_modalManager.show(window)
	end

	local storeButton = window:recursiveGetChildById("buttonStore")
	local okButton = window:recursiveGetChildById("buttonOk")
	local cancelButton = window:recursiveGetChildById("buttonCancel")

	local function storeFunc()
		cancelAutoRespawn()
		g_game.requestRespawn()

		if modules.game_store and modules.game_store.gameOpenStore then
			modules.game_store.gameOpenStore()
		end

		deathController.ui = destroyWindows()
	end

	local function okFunc()
		cancelAutoRespawn()
		g_game.requestRespawn()

		deathController.ui = destroyWindows()
	end

	local function cancelFunc()
		cancelAutoRespawn()
		g_game.safeLogout()

		deathController.ui = destroyWindows()
	end

	window.onEnter = okFunc
	window.onEscape = cancelFunc

	if storeButton then
		storeButton.onClick = storeFunc
	end

	if okButton then
		okButton.onClick = okFunc
	end

	if cancelButton then
		cancelButton.onClick = cancelFunc
	end

	-- Avoid the old immediate-relog race: give the death packet and UI time to
	-- settle, then request the same respawn action as the Ok button.
	autoRespawnEvent = scheduleEvent(function()
		autoRespawnEvent = nil

		if g_game.isOnline() and g_game.isDead() then
			g_game.requestRespawn()
			deathController.ui = destroyWindows()
		end
	end, AUTO_RESPAWN_DELAY)
end
