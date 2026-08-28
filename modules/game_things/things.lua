-- chunkname: @/game_things/things.lua

ThingsLoaderController = Controller:new()

local filename
local loaded = false

local function getThingsAssetsPath(version)
	local versionPath = "/things/" .. version .. "/"
	local sharedAssetsPath = "/things/assets/"

	-- Prefer the editable Assets Editor catalog when installed. Keep the
	-- version-specific catalog as a safe fallback for older installations.
	if g_resources.directoryExists(sharedAssetsPath) then
		return sharedAssetsPath
	end

	return versionPath
end

function setFileName(name)
	filename = name
end

function isLoaded()
	return loaded
end

local function tryLoadDatWithFallbacks(datPath)
	if g_things.loadDat(datPath) then
		return true
	end

	local featureFlags = {
		GameSpritesU32,
		GameEnhancedAnimations,
		GameIdleAnimations
	}
	local combinations = {
		{
			1
		},
		{
			2
		},
		{
			3
		},
		{
			1,
			2
		},
		{
			1,
			3
		},
		{
			2,
			3
		},
		{
			1,
			2,
			3
		}
	}

	for _, combo in ipairs(combinations) do
		for _, idx in ipairs(combo) do
			g_game.enableFeature(featureFlags[idx])
		end

		if g_things.loadDat(datPath) then
			return true
		end
	end

	return false
end

local function load(version)
	local errorList = {}
	local THINGS_ASSETS_PATH = getThingsAssetsPath(version)

	if version >= 1281 and not g_game.getFeature(GameLoadSprInsteadProtobuf) then
		local filePath = resolvepath(THINGS_ASSETS_PATH)

		if not g_things.loadAppearances(filePath) then
			errorList[#errorList + 1] = "Couldn't load assets"
		end

		if not g_things.loadStaticData(filePath) then
			errorList[#errorList + 1] = "Couldn't load staticdata"
		end

		if g_things.loadStaticMapData then
			if not g_things.loadStaticMapData(filePath) then
				g_logger.warning(string.format("[game_things.load()] Could not load staticmapdata from '%s' (file missing or corrupt).", filePath))
			elseif g_things.prefetchAllHouseSprites then
				g_things.prefetchAllHouseSprites()
			end
		end

		if g_minimap.loadOfficial and not g_minimap.loadOfficial(filePath) then
			g_logger.warning(string.format("[game_things.load()] Could not load official minimap from '%s' (map-*.dat missing or corrupt).", filePath))
		end
	else
		local datPath, sprPath

		if filename then
			datPath = resolvepath(THINGS_ASSETS_PATH .. filename)
			sprPath = resolvepath(THINGS_ASSETS_PATH .. filename)
		else
			datPath = resolvepath(THINGS_ASSETS_PATH .. "Tibia")
			sprPath = resolvepath(THINGS_ASSETS_PATH .. "Tibia")
		end

		g_logger.setLevel(5)

		if not tryLoadDatWithFallbacks(datPath) then
			errorList[#errorList + 1] = tr("Unable to load dat file, please place a valid dat in '%s.dat'", datPath)
		end

		g_logger.setLevel(1)

		if not g_sprites.loadSpr(sprPath) then
			errorList[#errorList + 1] = tr("Unable to load spr file, please place a valid spr in '%s.spr'", sprPath)
		end

		if g_game.getFeature(GameLoadSprInsteadProtobuf) and version >= 1281 then
			local staticPath = resolvepath(THINGS_ASSETS_PATH .. "appearances")

			if not g_things.loadAppearances(staticPath) then
				g_logger.warning(string.format("[game_things.load()] Couldn't load %sappearances.dat, possible packets error.", THINGS_ASSETS_PATH))
			end
		end
	end

	loaded = #errorList == 0

	if loaded then
		g_sounds.loadClientFiles(resolvepath("/sounds/"))

		return
	end

	local messageBox = displayErrorBox(tr("Error"), table.concat(errorList, "\n"))

	addEvent(function()
		messageBox:raise()
		messageBox:focus()
	end)
	g_game.setClientVersion(0)
	g_game.setProtocolVersion(0)
end

function ThingsLoaderController:onInit()
	self:registerEvents(g_game, {
		onClientVersionChange = load
	})
end
