-- chunkname: @/corelib/sidebar_persistence.lua

SidebarPersistence = {
	FILE_NAME = "sidebars.json",
	lastSessionActive = false,
	savedOnLogout = false,
	liveSaveEnabled = false,
	liveSaveEvent = nil,
	liveSaveEnableEvent = nil,
	lastEncodedDocument = nil,
	active = false,
	providers = {},
	document = {}
}

local function getPlayerId()
	local player = g_game.getLocalPlayer()

	if not player then
		return nil
	end

	return tostring(player:getId())
end

function SidebarPersistence.getFilePath()
	if not SidebarPersistence.playerId then
		return nil
	end

	return "/characterdata/" .. SidebarPersistence.playerId .. "/" .. SidebarPersistence.FILE_NAME
end

function SidebarPersistence.ensureCharacterDir()
	if not SidebarPersistence.playerId then
		return false
	end

	if not g_resources.directoryExists("/characterdata") then
		g_resources.makeDir("/characterdata")
	end

	local dir = "/characterdata/" .. SidebarPersistence.playerId

	if not g_resources.directoryExists(dir) then
		g_resources.makeDir(dir)
	end

	return true
end

function SidebarPersistence.registerProvider(sectionKey, provider)
	if type(sectionKey) ~= "string" or sectionKey == "" or type(provider) ~= "table" then
		return false
	end

	SidebarPersistence.providers[sectionKey] = provider

	return true
end

function SidebarPersistence.getSection(sectionKey)
	if not SidebarPersistence.active or type(SidebarPersistence.document) ~= "table" then
		return nil
	end

	return SidebarPersistence.document[sectionKey]
end

local function readDocumentFromDisk()
	local path = SidebarPersistence.getFilePath()

	if not path or not g_resources.fileExists(path) then
		return {}
	end

	local status, result = pcall(function()
		return json.decode(g_resources.readFileContents(path))
	end)

	if status and type(result) == "table" then
		return result
	end

	if not status then
		g_logger.error("[SidebarPersistence] failed to read " .. path .. ": " .. tostring(result))
	end

	return {}
end

local function writeDocumentToDisk(document)
	local path = SidebarPersistence.getFilePath()

	if not path then
		return false
	end

	local status, encoded = pcall(function()
		return json.encode(document, 2)
	end)

	if not status then
		g_logger.error("[SidebarPersistence] failed to encode: " .. tostring(encoded))

		return false
	end

	-- Layout snapshots run periodically while the player is online. Avoid
	-- rewriting the same file when no window, panel or backpack has changed.
	if encoded == SidebarPersistence.lastEncodedDocument then
		return true
	end

	if not SidebarPersistence.ensureCharacterDir() then
		return false
	end

	g_resources.writeFileContents(path, encoded)
	SidebarPersistence.lastEncodedDocument = encoded

	return true
end

function SidebarPersistence.load()
	local playerId = getPlayerId()

	if not playerId then
		SidebarPersistence.active = false
		SidebarPersistence.playerId = nil
		SidebarPersistence.document = {}

		return false
	end

	SidebarPersistence.playerId = playerId
	SidebarPersistence.document = readDocumentFromDisk()
	SidebarPersistence.lastEncodedDocument = nil
	SidebarPersistence.active = true

	return true
end

local function copySection(source)
	local copy = {}

	if type(source) ~= "table" then
		return copy
	end

	for key, value in pairs(source) do
		if key ~= "_jsonKeyOrder" and type(value) == "table" then
			local nested = {}

			for nestedKey, nestedValue in pairs(value) do
				if nestedKey ~= "_jsonKeyOrder" then
					nested[nestedKey] = nestedValue
				end
			end

			copy[key] = nested
		elseif key ~= "_jsonKeyOrder" then
			copy[key] = value
		end
	end

	return copy
end

function SidebarPersistence.saveNow(finalSave)
	if not SidebarPersistence.active or not SidebarPersistence.playerId then
		return false
	end

	-- Read the real, current panel order before pruning the tracked state. This
	-- also catches windows moved by drag-and-drop paths that did not emit a
	-- placement notification.
	if SidebarLayoutState and SidebarLayoutState.syncFromPanels then
		SidebarLayoutState.syncFromPanels()
	end

	if SidebarLayoutState and SidebarLayoutState.pruneUntrackedWidgets then
		SidebarLayoutState.pruneUntrackedWidgets()
	end

	if SidebarWidgetOptionsPersistence and SidebarWidgetOptionsPersistence.registerProviders then
		SidebarWidgetOptionsPersistence.registerProviders()
	end

	local document = copySection(SidebarPersistence.document)

	for sectionKey, provider in pairs(SidebarPersistence.providers) do
		if type(provider.collect) == "function" then
			local section = copySection(document[sectionKey])

			provider.collect(section)

			if type(section) == "table" and (not table.empty(section) or provider.alwaysInclude) then
				document[sectionKey] = section
			end
		end
	end

	SidebarPersistence.document = document
	local saved = writeDocumentToDisk(document)

	if saved and finalSave then
		SidebarPersistence.savedOnLogout = true
	end

	return saved
end

local function saveLiveSnapshot()
	if SidebarPersistence.liveSaveEnabled and SidebarPersistence.active and g_game and g_game.isOnline() then
		SidebarPersistence.saveNow(false)
	end
end

function SidebarPersistence.onGameStart()
	SidebarPersistence.savedOnLogout = false
	SidebarPersistence.liveSaveEnabled = false

	SidebarPersistence.load()

	SidebarPersistence.lastSessionActive = SidebarPersistence.active

	if SidebarPersistence.liveSaveEnableEvent then
		removeEvent(SidebarPersistence.liveSaveEnableEvent)
	end

	-- Late-loaded modules and reopened containers need time to consume the
	-- stored layout. Enabling snapshots afterwards prevents an incomplete
	-- startup layout from replacing the good saved file.
	SidebarPersistence.liveSaveEnableEvent = scheduleEvent(function()
		SidebarPersistence.liveSaveEnableEvent = nil
		SidebarPersistence.liveSaveEnabled = SidebarPersistence.active and g_game.isOnline()
	end, 7000)
end

function SidebarPersistence.onGameEnd()
	SidebarPersistence.lastSessionActive = SidebarPersistence.active

	if SidebarPersistence.active and not SidebarPersistence.savedOnLogout then
		SidebarPersistence.saveNow(true)
	end

	SidebarPersistence.liveSaveEnabled = false
	SidebarPersistence.active = false
	SidebarPersistence.playerId = nil
	SidebarPersistence.document = {}
	SidebarPersistence.savedOnLogout = false
end

function SidebarPersistence.onLogout()
	if SidebarPersistence.active and not SidebarPersistence.savedOnLogout then
		SidebarPersistence.saveNow(true)
	end
end

local function onAppCloseSaveSidebars()
	if g_game and g_game.isOnline() then
		SidebarPersistence.onLogout()
	end
end

function SidebarPersistence.init()
	connect(g_game, {
		onGameStart = SidebarPersistence.onGameStart,
		onGameEnd = SidebarPersistence.onGameEnd,
		onLogout = SidebarPersistence.onLogout
	})
	connect(g_app, {
		onClose = onAppCloseSaveSidebars,
		onExit = onAppCloseSaveSidebars
	})

	SidebarPersistence.liveSaveEvent = cycleEvent(saveLiveSnapshot, 3000)
end

function SidebarPersistence.terminate()
	if SidebarPersistence.liveSaveEvent then
		removeEvent(SidebarPersistence.liveSaveEvent)
		SidebarPersistence.liveSaveEvent = nil
	end

	if SidebarPersistence.liveSaveEnableEvent then
		removeEvent(SidebarPersistence.liveSaveEnableEvent)
		SidebarPersistence.liveSaveEnableEvent = nil
	end

	disconnect(g_game, {
		onGameStart = SidebarPersistence.onGameStart,
		onGameEnd = SidebarPersistence.onGameEnd,
		onLogout = SidebarPersistence.onLogout
	})
	disconnect(g_app, {
		onClose = onAppCloseSaveSidebars,
		onExit = onAppCloseSaveSidebars
	})
end

SidebarPersistence.init()
