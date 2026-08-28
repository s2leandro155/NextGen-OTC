-- chunkname: @/corelib/sidebar_persistence.lua

SidebarPersistence = {
	FILE_NAME = "sidebars.json",
	lastSessionActive = false,
	savedOnLogout = false,
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

	if not SidebarPersistence.ensureCharacterDir() then
		return false
	end

	g_resources.writeFileContents(path, encoded)

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

function SidebarPersistence.saveNow()
	if not SidebarPersistence.active or not SidebarPersistence.playerId then
		return false
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
	SidebarPersistence.savedOnLogout = true

	return writeDocumentToDisk(document)
end

function SidebarPersistence.onGameStart()
	SidebarPersistence.savedOnLogout = false

	SidebarPersistence.load()

	SidebarPersistence.lastSessionActive = SidebarPersistence.active
end

function SidebarPersistence.onGameEnd()
	SidebarPersistence.lastSessionActive = SidebarPersistence.active

	if SidebarPersistence.active and not SidebarPersistence.savedOnLogout then
		SidebarPersistence.saveNow()
	end

	SidebarPersistence.active = false
	SidebarPersistence.playerId = nil
	SidebarPersistence.document = {}
	SidebarPersistence.savedOnLogout = false
end

function SidebarPersistence.onLogout()
	if SidebarPersistence.active and not SidebarPersistence.savedOnLogout then
		SidebarPersistence.saveNow()
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
end

function SidebarPersistence.terminate()
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
