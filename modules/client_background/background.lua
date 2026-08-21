-- chunkname: @/client_background/background.lua

local background
-- The only pool of login screen backgrounds - randomized once at every client startup.
local BACKGROUNDS = {
	"/images/background_crystal1",
	"/images/background_crystal2",
	"/images/background_crystal3",
	"/images/background_crystal4",
	"/images/background_crystal5",
	"/images/background_crystal6"
}
local toggleState = true
local timeLoopBackgroundEffect = 5000
local mapReadyEvent
local mapTransitionStartedAt = 0
local mapTransitionActive = false
local MAP_READY_POLL_MS = 16
local MAP_READY_TIMEOUT_MS = 3000

local function cancelMapReadyEvent()
	if mapReadyEvent then
		removeEvent(mapReadyEvent)

		mapReadyEvent = nil
	end
end

local function finishMapTransition(timedOut)
	cancelMapReadyEvent()

	mapTransitionActive = false

	if timedOut then
		g_logger.warning(string.format("[login] map loading art timed out after %d ms", MAP_READY_TIMEOUT_MS))
	end

	background:hide()

	if CharacterList and CharacterList.destroyLoadBox then
		CharacterList.destroyLoadBox()
	end

	if modules.client_topmenu and modules.client_topmenu.online then
		modules.client_topmenu.online()
	end

	if EnterGame and EnterGame.hidePanels then
		EnterGame.hidePanels(true)
	end
end

local function pollMapReady()
	mapReadyEvent = nil

	if not g_game.isOnline() then
		return
	end

	local gameInterface = modules.game_interface
	local mapPanel = gameInterface and gameInterface.getMapPanel and gameInterface.getMapPanel()

	if mapPanel and not mapPanel:isDestroyed() and mapPanel.isReadyToDisplay and mapPanel:isReadyToDisplay() then
		finishMapTransition(false)

		return
	end

	if g_clock.realMillis() - mapTransitionStartedAt >= MAP_READY_TIMEOUT_MS then
		finishMapTransition(true)

		return
	end

	mapReadyEvent = scheduleEvent(pollMapReady, MAP_READY_POLL_MS)
end

local function beginMapTransition()
	cancelMapReadyEvent()

	mapTransitionStartedAt = g_clock.realMillis()
	mapTransitionActive = true

	background:show()

	if modules.client_topmenu then
		modules.client_topmenu.offline()
		modules.client_topmenu.show()
	end

	if g_modules.getModule("client_bottommenu") and g_modules.getModule("client_bottommenu"):isLoaded() then
		modules.client_bottommenu.show()
	end

	mapReadyEvent = scheduleEvent(pollMapReady, 0)
end

function init()
	background = g_ui.displayUI("background")

	math.randomseed(g_clock.realMillis())

	background:setImageSource(BACKGROUNDS[math.random(#BACKGROUNDS)])
	background:lower()

	connect(g_game, {
		onGameStart = beginMapTransition
	})
	connect(g_game, {
		onGameEnd = show
	})

	if g_game.isOnline() then
		beginMapTransition()
	end
end

function terminate()
	cancelMapReadyEvent()

	mapTransitionActive = false

	disconnect(g_game, {
		onGameStart = beginMapTransition
	})
	disconnect(g_game, {
		onGameEnd = show
	})
	background:destroy()

	background = nil
end

function hide()
	cancelMapReadyEvent()

	mapTransitionActive = false

	background:hide()
end

function show()
	cancelMapReadyEvent()

	mapTransitionActive = false

	background:show()
end

function getBackground()
	return background
end

function isMapTransitionActive()
	return mapTransitionActive
end
