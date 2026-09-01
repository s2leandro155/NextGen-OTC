-- chunkname: @/client_options/data_options.lua

local WALK_DELAY_DEFAULT_MS = 100

local function syncAllowInspectSetting(enabled)
	if not g_game.isOnline() or not g_game.inspectPlayer then
		return
	end

	local flag = enabled and InspectionParseFlags.AllowAll or InspectionParseFlags.DismissAll

	g_game.inspectPlayer(flag)
end

local function getPendingOptionValue(options, key)
	local option = options[key]

	if not option then
		return nil
	end

	if option.pendingValue ~= nil then
		return option.pendingValue
	end

	return option.value
end

local function syncHealthCircleModuleFromHud(options, panels, arcsEnabled)
	local hc = modules.game_healthcircle

	if not hc or type(hc.syncShowArcsFromClientOptions) ~= "function" then
		return
	end

	local show = arcsEnabled

	if show == nil then
		show = getPendingOptionValue(options, "showArcs")
	end

	hc.syncShowArcsFromClientOptions(show, options)
end

local function styleWalkDelayScroll(scroll, help, value, useDefault, labelText)
	if not scroll then
		return
	end

	local valueBar = scroll:recursiveGetChildById("valueBar")

	if useDefault then
		if valueBar then
			valueBar:setEnabled(false)
			valueBar:setValue(value)
		end

		scroll:setColor("#707070ff")

		if help then
			help:setVisible(false)
		end
	else
		if valueBar then
			valueBar:setEnabled(true)
		end

		if value >= 0 and value <= 29 then
			scroll:setColor("#d33c3cff")

			if help then
				help:setImageSource("/images/icons/show_gui_help_red")
				help:setTooltip(tr("The selected walk delay is very low. It is very likely that you\nwill experience problems with movement in this situation."))
				help:setVisible(true)
			end
		elseif value >= 30 and value <= 99 then
			scroll:setColor("#ff9854ff")

			if help then
				help:setImageSource("/images/icons/show_gui_help_orange")
				help:setTooltip(tr("The selected walk delay is quite low. It is possible that you\nwill experience problems with movement in this situation."))
				help:setVisible(true)
			end
		else
			scroll:setColor("#c0c0c0ff")

			if help then
				help:setVisible(false)
			end
		end
	end

	scroll:setText(labelText)
end

local function getMiniMapWindow()
	local miniMapUi = modules.game_minimap and modules.game_minimap.getMiniMapUi and modules.game_minimap.getMiniMapUi()

	if not miniMapUi or miniMapUi:isDestroyed() then
		return nil
	end

	local border = miniMapUi:getParent()

	if not border or border:isDestroyed() then
		return nil
	end

	local window = border:getParent()

	if not window or window:isDestroyed() then
		return nil
	end

	return window
end

local function isMiniMapContainer(child)
	if not child or child:isDestroyed() then
		return false
	end

	local miniMapWindow = getMiniMapWindow()

	if miniMapWindow and child == miniMapWindow then
		return true
	end

	return child:getId() == "mainmappanel" or child.moveOnlyToMain and child.allowHorizontalDrop
end

local function moveChildToTop(child, targetPanel)
	if not child or child:isDestroyed() or not targetPanel or targetPanel:isDestroyed() then
		return
	end

	local oldParent = child:getParent()

	if oldParent and not oldParent:isDestroyed() then
		oldParent:removeChild(child)
	end

	targetPanel:insertChild(1, child)
	signalcall(child.onContainerChanged, child, targetPanel)
end

return {
	openMaximized = false,
	showInfoMessagesInConsole = true,
	showEventMessagesInConsole = true,
	showStatusMessagesInConsole = true,
	moveStack = false,
	smartWalk = true,
	freeWindowPlacement = true,
	openNewTabsWhenReceivingPrivateMessages = false,
	showOthersStatusMessagesInConsole = false,
	showPrivateMessagesInConsole = true,
	showLevelsInConsole = true,
	showTimestampsInConsole = true,
	actionBarBottomLocked = false,
	actionBarRightLocked = false,
	bottomBarsBar1 = true,
	leftBarsAll = false,
	leftBarsBar2 = false,
	rightBarsAll = false,
	rightBarsBar2 = false,
	onlyCaptureGameWindow = false,
	giftOfLife = true,
	highestHealing = false,
	playerAttacking = false,
	playerKill = false,
	deathPvP = false,
	deathPvE = true,
	bossDefeated = false,
	valuableLoot = false,
	treasureFound = false,
	bestiaryCompleted = false,
	achievement = true,
	levelUp = true,
	keepBacklog = false,
	rightBarsBar3 = false,
	rightBarsBar1 = false,
	leftBarsBar3 = false,
	leftBarsBar1 = false,
	bottomBarsBar3 = false,
	bottomBarsBar2 = false,
	bottomBarsAll = true,
	showBars = true,
	quickLootCorpses = false,
	autoChaseOff = true,
	actionBarLeftLocked = false,
	playerKillAssist = false,
	bestiaryUnlocked = false,
	highestDamage = false,
	skillUp = true,
	lowHealth = false,
	enableAutoScreenshots = true,
	autoSwitchPreset = false,
	vsync = {
		deferAction = true,
		value = false,
		action = function(value, options, controller, panels, extraWidgets)
			g_window.setVerticalSync(value)
		end
	},
	showFps = {
		deferAction = true,
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			modules.client_topmenu.setStatsHudVisible(value)
		end
	},
	fullscreen = {
		deferAction = true,
		value = false,
		action = function(value, options, controller, panels, extraWidgets)
			g_window.setFullscreen(value)
		end
	},
	anthem = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			return
		end
	},
	foodAndBeverages = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			if g_sounds then
				g_sounds.setClientSoundFilter("foodAndBeverages", value)
			end
		end
	},
	moveItem = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			if g_sounds then
				g_sounds.setClientSoundFilter("moveItem", value)
			end
		end
	},
	uiInteractions = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			if g_sounds then
				g_sounds.setClientSoundFilter("uiInteractions", value)
			end
		end
	},
	toggleParty = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			if g_sounds then
				g_sounds.setClientSoundFilter("toggleParty", value)
			end
		end
	},
	toggleVip = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			if g_sounds then
				g_sounds.setClientSoundFilter("toggleVip", value)
			end
		end
	},
	consoleMessages = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			setUISoundConsoleMessagesEnabled(value)
		end
	},
	party = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			return
		end
	},
	guild = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			return
		end
	},
	privateMessagesLocalChat = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			return
		end
	},
	privateMessages = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			return
		end
	},
	npcs = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			return
		end
	},
	global = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			return
		end
	},
	teamFinder = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			return
		end
	},
	raidAnnouncements = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			return
		end
	},
	systemAnnouncements = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			return
		end
	},
	ownSpells = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			if g_sounds then
				g_sounds.setClientSoundFilter("ownSpells", value)
			end
		end
	},
	ownAttack = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			if g_sounds then
				g_sounds.setClientSoundFilter("ownAttack", value)
			end
		end
	},
	ownHealing = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			if g_sounds then
				g_sounds.setClientSoundFilter("ownHealing", value)
			end
		end
	},
	ownSupport = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			if g_sounds then
				g_sounds.setClientSoundFilter("ownSupport", value)
			end
		end
	},
	ownWeapons = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			if g_sounds then
				g_sounds.setClientSoundFilter("ownWeapons", value)
			end
		end
	},
	otherSpells = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			if g_sounds then
				g_sounds.setClientSoundFilter("otherSpells", value)
			end
		end
	},
	otherAttack = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			if g_sounds then
				g_sounds.setClientSoundFilter("otherAttack", value)
			end
		end
	},
	otherHealing = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			if g_sounds then
				g_sounds.setClientSoundFilter("otherHealing", value)
			end
		end
	},
	otherSupport = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			if g_sounds then
				g_sounds.setClientSoundFilter("otherSupport", value)
			end
		end
	},
	otherWeapons = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			if g_sounds then
				g_sounds.setClientSoundFilter("otherWeapons", value)
			end
		end
	},
	creatureNoises = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			if g_sounds then
				g_sounds.setClientSoundFilter("creatureNoises", value)
			end
		end
	},
	creatureDeath = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			if g_sounds then
				g_sounds.setClientSoundFilter("creatureDeath", value)
			end
		end
	},
	attackAndSpells = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			if g_sounds then
				g_sounds.setClientSoundFilter("attackAndSpells", value)
			end
		end
	},
	showTextualEffects = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			g_app.setDrawAnimatedTexts(value)
		end
	},
	showMessages = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			if not value and modules.game_textmessage and modules.game_textmessage.clearMessages then
				modules.game_textmessage.clearMessages()
			end
		end
	},
	showPrivateMessages = {
		value = true
	},
	showPotionSoundEffects = {
		value = true
	},
	showSpells = {
		value = true
	},
	showSpellsOfOthers = {
		value = true
	},
	showHotkeyUsageNotifications = {
		value = true
	},
	showLootMessages = {
		value = true
	},
	showLootHighlighting = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			g_client.setShowLootHighlight(value)
		end
	},
	showBoostedCreature = {
		value = true
	},
	showOfflineTrainingProgress = {
		value = true
	},
	showStoreNotificationsInCombat = {
		value = true
	},
	showCombatFrames = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			g_client.setShowCombatFrames(value)
		end
	},
	showPvPFrames = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			g_client.setShowPvPFrames(value)
		end
	},
	markTargetVisually = {
		value = "frameAndHighlight",
		action = function(value, options, controller, panels, extraWidgets)
			local modeMap = {
				none = 3,
				frameAndHighlight = 0,
				highlightOnly = 2,
				frameOnly = 1
			}
			local mode = modeMap[value] or 0

			g_client.setMarkTargetVisually(mode)

			local panel = panels.interfaceGameWindow

			if panel then
				local combo = panel:recursiveGetChildById("markTargetVisually")

				if combo then
					combo:setCurrentOptionByData(value, true)
				end
			end

			if g_game.refreshAttackTargetMarks then
				g_game.refreshAttackTargetMarks()
			end
		end
	},
	showMeleeAttackAnimation = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			g_client.setShowMeleeAttackAnimation(value)
		end
	},
	showInfoBanner = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			if not value and modules.game_banners and modules.game_banners.hideActiveBanner then
				modules.game_banners.hideActiveBanner(true)
			end
		end
	},
	classicControl = {
		value = "classic",
		action = function(value, options, controller, panels, extraWidgets)
			for _, panel in pairs({
				panels.optionsPanel,
				panels.generalPanel
			}) do
				if panel then
					local classicControls = panel:recursiveGetChildById("classicControls")

					if classicControls then
						classicControls:setCurrentOptionByData(value, true)
					end
				end
			end

			if modules.client_options and modules.client_options.updateLootSideVisibility then
				modules.client_options.updateLootSideVisibility(panels, value)
			end

			if panels.gameMapPanel and panels.gameMapPanel.setHighlightObjectsWithoutShift then
				panels.gameMapPanel:setHighlightObjectsWithoutShift(value == "leftSmart")
			end
		end
	},
	lootSide = {
		value = "right",
		action = function(value, options, controller, panels, extraWidgets)
			for _, panel in pairs({
				panels.optionsPanel,
				panels.generalPanel
			}) do
				if panel then
					local lootSide = panel:recursiveGetChildById("lootSide")

					if lootSide then
						lootSide:setCurrentOptionByData(value, true)
					end
				end
			end
		end
	},
	showOutfitsOnList = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			CharacterList.updateCharactersAppearances(value)
		end
	},
	noFrameRateLimit = {
		deferAction = true,
		value = false,
		action = function(value, options, controller, panels, extraWidgets)
			if modules.client_options and modules.client_options.updateBackgroundFrameRatePreview then
				modules.client_options.updateBackgroundFrameRatePreview(panels)
			end

			local storedValue = getPendingOptionValue(options, "backgroundFrameRate") or 240

			if storedValue <= 0 or storedValue > 240 then
				storedValue = 240
			end

			if value then
				g_app.setMaxFps(0)
			else
				g_app.setMaxFps(storedValue)
			end
		end
	},
	backgroundFrameRate = {
		deferAction = true,
		value = 240,
		action = function(value, options, controller, panels, extraWidgets)
			local noLimit = getPendingOptionValue(options, "noFrameRateLimit")

			if noLimit then
				if value <= 0 or value > 240 then
					value = 240
				end

				if modules.client_options and modules.client_options.updateBackgroundFrameRatePreview then
					modules.client_options.updateBackgroundFrameRatePreview(panels)
				end

				g_app.setMaxFps(0)

				return
			end

			if value <= 0 or value > 240 then
				value = 240
			end

			if modules.client_options and modules.client_options.updateBackgroundFrameRatePreview then
				modules.client_options.updateBackgroundFrameRatePreview(panels)
			end

			g_app.setMaxFps(value)
		end
	},
	enableAudio = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			if g_sounds then
				g_sounds.setAudioEnabled(value)
			end
		end
	},
	enableMusicSound = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			if g_sounds then
				g_sounds.getChannel(SoundChannels.Music):setEnabled(value)
			end

			if extraWidgets.audioButton then
				if value then
					extraWidgets.audioButton:setIcon("/images/topbuttons/button_mute_up")
				else
					extraWidgets.audioButton:setIcon("/images/topbuttons/button_mute_pressed")
				end
			end
		end
	},
	masterVolume = {
		value = 100,
		action = function(value, options, controller, panels, extraWidgets)
			if g_sounds then
				g_sounds.setMasterVolume(value / 100)
			end

			setAllUISoundState(value > 0 and true or false)

			local state = ""

			if value == 0 then
				state = string.format(" (%s)", tr("off"))
			end

			panels.soundPanel:recursiveGetChildById("masterVolume"):setText(tr("Master Volume: %d %%", value) .. state)

			local bar = panels.soundPanel:recursiveGetChildById("masterVolume"):getChildById("valueBar")

			bar:setValue(value)
		end
	},
	musicVolume = {
		value = 100,
		action = function(value, options, controller, panels, extraWidgets)
			if g_sounds then
				g_sounds.getChannel(SoundChannels.Music):setGain(value / 100)
			end

			setMusicVolumeEnabled(value > 0 and true or false)

			local state = ""

			if value == 0 then
				state = string.format(" (%s)", tr("off"))
			end

			panels.soundPanel:recursiveGetChildById("musicVolume"):setText(tr("Music Volume: %d %%", value) .. state)
		end
	},
	ambienceVolume = {
		value = 100,
		action = function(value, options, controller, panels, extraWidgets)
			if g_sounds then
				g_sounds.getChannel(SoundChannels.Ambient):setGain(value / 100)
			end

			local state = ""

			if value == 0 then
				state = string.format(" (%s)", tr("off"))
			end

			panels.soundPanel:recursiveGetChildById("ambienceVolume"):setText(tr("Ambience Volume: %d %%", value) .. state)
		end
	},
	itemVolume = {
		value = 100,
		action = function(value, options, controller, panels, extraWidgets)
			if g_sounds then
				g_sounds.setClientSoundVolume(4, value / 100)
			end

			setUIItemVolumeEnabled(value > 0 and true or false)

			local state = ""

			if value == 0 then
				state = string.format(" (%s)", tr("off"))
			end

			panels.soundPanel:recursiveGetChildById("itemVolume"):setText(tr("Item Volume: %d %%", value) .. state)
		end
	},
	eventVolume = {
		value = 100,
		action = function(value, options, controller, panels, extraWidgets)
			if g_sounds then
				g_sounds.setClientSoundVolume(0, value / 100)
			end

			local state = ""

			if value == 0 then
				state = string.format(" (%s)", tr("off"))
			end

			panels.soundPanel:recursiveGetChildById("eventVolume"):setText(tr("Event Volume: %d %%", value) .. state)
		end
	},
	ownBattleVolume = {
		value = 100,
		action = function(value, options, controller, panels, extraWidgets)
			if g_sounds then
				g_sounds.setClientSoundVolume(1, value / 100)
			end

			setOwnBattleSoundEnabled(value > 0 and true or false)

			local state = ""

			if value == 0 then
				state = string.format(" (%s)", tr("off"))
			end

			panels.battleSoundsPanel:recursiveGetChildById("ownBattleVolume"):setText(tr("Own Players Sounds: %d %%", value) .. state)
		end
	},
	otherPlayersVolume = {
		value = 100,
		action = function(value, options, controller, panels, extraWidgets)
			if g_sounds then
				g_sounds.setClientSoundVolume(2, value / 100)
			end

			setOtherPlayersBattleSoundEnabled(value > 0 and true or false)

			local state = ""

			if value == 0 then
				state = string.format(" (%s)", tr("off"))
			end

			panels.battleSoundsPanel:recursiveGetChildById("otherPlayersVolume"):setText(tr("Other Players: %d %%", value) .. state)
		end
	},
	creaturesVolume = {
		value = 100,
		action = function(value, options, controller, panels, extraWidgets)
			if g_sounds then
				g_sounds.setClientSoundVolume(3, value / 100)
			end

			setCreatureBattleSoundEnabled(value > 0 and true or false)

			local state = ""

			if value == 0 then
				state = string.format(" (%s)", tr("off"))
			end

			panels.battleSoundsPanel:recursiveGetChildById("creaturesVolume"):setText(tr("Creatures: %d %%", value) .. state)
		end
	},
	uiVolume = {
		value = 100,
		action = function(value, options, controller, panels, extraWidgets)
			if g_sounds then
				g_sounds.setClientSoundVolume(5, value / 100)
			end

			setUISoundsEnabled(value > 0 and true or false)

			local state = ""

			if value == 0 then
				state = string.format(" (%s)", tr("off"))
			end

			panels.uiSoundsPanel:recursiveGetChildById("uiVolume"):setText(tr("UI Volume: %d %%", value) .. state)
		end
	},
	enableLights = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			panels.gameMapPanel:setDrawLights(value and options.ambientLight.value < 100)
			panels.graphicsEffectsPanel:recursiveGetChildById("ambientLight"):setEnabled(value)
		end
	},
	limitVisibleDimension = {
		value = false,
		action = function(value, options, controller, panels, extraWidgets)
			panels.gameMapPanel:setLimitVisibleDimension(value)
		end
	},
	floatingEffect = {
		value = false,
		action = function(value, options, controller, panels, extraWidgets)
			g_map.setFloatingEffect(value)
		end
	},
	ambientLight = {
		value = 25,
		action = function(value, options, controller, panels, extraWidgets)
			panels.graphicsEffectsPanel:recursiveGetChildById("ambientLight"):setText(string.format("Ambient Light: %s%%", value))
			panels.gameMapPanel:setMinimumAmbientLight(value / 100)
			panels.gameMapPanel:setDrawLights(options.enableLights.value)
		end
	},
	levelSeparator = {
		value = 80,
		action = function(value, options, controller, panels, extraWidgets)
			panels.graphicsEffectsPanel:recursiveGetChildById("levelSeparator"):setText(string.format("Level Separator: %s%%", value))
			panels.gameMapPanel:setShadowFloorIntensity(1 - value / 100)
		end
	},
	cloudsLabel = {
		value = 100,
		action = function(value, options, controller, panels, extraWidgets)
			panels.graphicsEffectsPanel:recursiveGetChildById("cloudsLabel"):setText(string.format("Clouds & Indoor Effect: %s%%", value))
		end
	},
	showHudForOwnCharacter = {
		deferAction = true,
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			if modules.client_options and modules.client_options.updateHudDependencyAvailability then
				modules.client_options.updateHudDependencyAvailability(panels, value, options.showHudForOtherCreatures.value)
			end

			panels.gameMapPanel:setDrawOwnName(value and getPendingOptionValue(options, "showOwnName"))
			panels.gameMapPanel:setDrawOwnHealthBars(value and getPendingOptionValue(options, "showOwnHealth"))
			panels.gameMapPanel:setDrawOwnManaBar(value and getPendingOptionValue(options, "showOwnMana"))
			panels.gameMapPanel:setDrawOwnHarmonyBar(value and getPendingOptionValue(options, "showOwnHarmony"))
			panels.gameMapPanel:setDrawOwnMarks(value and getPendingOptionValue(options, "showOwnMarks"))

			if g_gameConfig.isDrawingInformationByWidget() then
				modules.game_creatureinformation.toggleInformation()
			end
		end
	},
	showHudForOtherCreatures = {
		deferAction = true,
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			if modules.client_options and modules.client_options.updateHudDependencyAvailability then
				modules.client_options.updateHudDependencyAvailability(panels, options.showHudForOwnCharacter.value, value)
			end

			panels.gameMapPanel:setDrawOtherNames(value and getPendingOptionValue(options, "showOtherName"))
			panels.gameMapPanel:setDrawOtherHealthBars(value and getPendingOptionValue(options, "showOtherHealth"))
			panels.gameMapPanel:setDrawOtherNpcIcons(value and getPendingOptionValue(options, "showOtherNpcIcons"))
			panels.gameMapPanel:setDrawOtherMarks(value and getPendingOptionValue(options, "showOtherMarks"))

			if g_gameConfig.isDrawingInformationByWidget() then
				modules.game_creatureinformation.toggleInformation()
			end
		end
	},
	showOwnBars = {
		deferAction = true,
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			local showHudForOwnCharacter = getPendingOptionValue(options, "showHudForOwnCharacter")

			panels.gameMapPanel:setDrawOwnHealthBars(showHudForOwnCharacter and getPendingOptionValue(options, "showOwnHealth"))
			panels.gameMapPanel:setDrawOwnManaBar(showHudForOwnCharacter and getPendingOptionValue(options, "showOwnMana"))

			if g_gameConfig.isDrawingInformationByWidget() then
				modules.game_creatureinformation.toggleInformation()
			end
		end
	},
	showOwnName = {
		deferAction = true,
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			panels.gameMapPanel:setDrawOwnName(value and options.showHudForOwnCharacter.value)

			if g_gameConfig.isDrawingInformationByWidget() then
				modules.game_creatureinformation.toggleInformation()
			end
		end
	},
	showOtherName = {
		deferAction = true,
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			panels.gameMapPanel:setDrawOtherNames(value and options.showHudForOtherCreatures.value)

			if g_gameConfig.isDrawingInformationByWidget() then
				modules.game_creatureinformation.toggleInformation()
			end
		end
	},
	showOwnHealth = {
		deferAction = true,
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			panels.gameMapPanel:setDrawOwnHealthBars(value and getPendingOptionValue(options, "showHudForOwnCharacter"))

			if g_gameConfig.isDrawingInformationByWidget() then
				modules.game_creatureinformation.toggleInformation()
			end
		end
	},
	showOtherHealth = {
		deferAction = true,
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			panels.gameMapPanel:setDrawOtherHealthBars(value and options.showHudForOtherCreatures.value)

			if g_gameConfig.isDrawingInformationByWidget() then
				modules.game_creatureinformation.toggleInformation()
			end
		end
	},
	showOtherNpcIcons = {
		deferAction = true,
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			panels.gameMapPanel:setDrawOtherNpcIcons(value and options.showHudForOtherCreatures.value)
		end
	},
	showOwnMana = {
		deferAction = true,
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			panels.gameMapPanel:setDrawOwnManaBar(value and getPendingOptionValue(options, "showHudForOwnCharacter"))

			if g_gameConfig.isDrawingInformationByWidget() then
				modules.game_creatureinformation.toggleInformation()
			end
		end
	},
	showOwnMarks = {
		deferAction = true,
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			panels.gameMapPanel:setDrawOwnMarks(value and getPendingOptionValue(options, "showHudForOwnCharacter"))

			if g_gameConfig.isDrawingInformationByWidget() then
				modules.game_creatureinformation.toggleInformation()
			end
		end
	},
	showManaShield = {
		value = true,
		deferAction = true
	},
	manaShieldNextToHealth = {
		value = false,
		deferAction = true
	},
	manaShieldNextToMana = {
		value = true,
		deferAction = true
	},
	showOwnHarmony = {
		deferAction = true,
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			panels.gameMapPanel:setDrawOwnHarmonyBar(value and getPendingOptionValue(options, "showHudForOwnCharacter"))

			if g_gameConfig.isDrawingInformationByWidget() then
				modules.game_creatureinformation.toggleInformation()
			end
		end
	},
	harmonyNextToHealth = {
		value = true,
		deferAction = true
	},
	harmonyNextToMana = {
		value = false,
		deferAction = true
	},
	showOtherMarks = {
		deferAction = true,
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			panels.gameMapPanel:setDrawOtherMarks(value and getPendingOptionValue(options, "showHudForOtherCreatures"))

			if g_gameConfig.isDrawingInformationByWidget() then
				modules.game_creatureinformation.toggleInformation()
			end
		end
	},
	showArcs = {
		deferAction = true,
		value = false,
		action = function(value, options, controller, panels, extraWidgets)
			syncHealthCircleModuleFromHud(options, panels, value)
		end
	},
	showArcsSize = {
		deferAction = true,
		value = "default",
		action = function(value, options, controller, panels, extraWidgets)
			local hud = panels.interfaceHUD

			if not hud then
				return
			end

			local combo = hud:recursiveGetChildById("showArcsSize")

			if combo then
				combo:setCurrentOptionByData(value, true)
			end

			syncHealthCircleModuleFromHud(options, panels)
		end
	},
	showArcsDistanceScroll = {
		deferAction = true,
		value = 25,
		action = function(value, options, controller, panels, extraWidgets)
			local hud = panels.interfaceHUD

			if not hud then
				return
			end

			local bar = hud:recursiveGetChildById("showArcsDistanceScroll")

			if bar then
				bar:setValue(value)
			end

			local label = hud:recursiveGetChildById("showArcsDistanceLabel")

			if label then
				label:setText(tr("Distance: %d %%", value))
			end

			syncHealthCircleModuleFromHud(options, panels)
		end
	},
	showArcsOpacityScroll = {
		deferAction = true,
		value = 100,
		action = function(value, options, controller, panels, extraWidgets)
			local hud = panels.interfaceHUD

			if not hud then
				return
			end

			local v = math.max(20, math.min(100, tonumber(value) or 100))
			local bar = hud:recursiveGetChildById("showArcsOpacityScroll")

			if bar then
				bar:setValue(v)
			end

			local label = hud:recursiveGetChildById("showArcsOpacityLabel")

			if label then
				label:setText(tr("Opacity: %d %%", v))
			end

			syncHealthCircleModuleFromHud(options, panels)
		end
	},
	conditionsDisplaySettings = {
		deferAction = true,
		value = "",
		action = function(value, options, controller, panels, extraWidgets)
			notifyConditionsDisplayChanged()
		end
	},
	showStatusBars = {
		deferAction = true,
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			if modules.game_healthinfo and modules.game_healthinfo.setSidebarVisible then
				modules.game_healthinfo.setSidebarVisible(value)
			end
		end
	},
	showCustomisableStatusBars = {
		deferAction = true,
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			local gi = modules.game_interface

			if not gi or not gi.updateStatsBar then
				return
			end

			local placement = g_settings.getString("statsbar_placement")

			if placement == "" then
				placement = "top"
			end

			if value then
				local dim = g_settings.getString("statsbar_dimension")
				local plac = g_settings.getString("statsbar_placement")

				if dim == "" or dim == "hide" then
					dim = g_settings.getString("statsbar_dimension_before_hide")
				end

				if plac == "" then
					plac = g_settings.getString("statsbar_placement_before_hide")
				end

				if dim == "" or dim == "hide" then
					dim = "compact"
				end

				if plac == "" then
					plac = placement
				end

				gi.updateStatsBar(dim, plac)
			else
				local curDim = g_settings.getString("statsbar_dimension")
				local curPlac = g_settings.getString("statsbar_placement")

				if curPlac == "" then
					curPlac = placement
				end

				if curDim ~= "" and curDim ~= "hide" then
					g_settings.set("statsbar_dimension_before_hide", curDim)
					g_settings.set("statsbar_placement_before_hide", curPlac)
					g_settings.save()
				end

				gi.updateStatsBar("hide", curPlac)
			end

			if modules.game_healthcircle and modules.game_healthcircle.setStatsBarOption then
				local dim = g_settings.getString("statsbar_dimension")
				local plac = g_settings.getString("statsbar_placement")

				if plac == "" then
					plac = "top"
				end

				modules.game_healthcircle.setStatsBarOption(dim, plac)
			end

			if modules.game_healthcircle and modules.game_healthcircle.refreshArcConditionsBarDeferred then
				modules.game_healthcircle.refreshArcConditionsBarDeferred()
			end
		end
	},
	displayText = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			g_app.setDrawTexts(value)
		end
	},
	useDefaultWalkDelay = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			if not panels.generalPanel then
				return
			end

			local useDef = value
			local turn = g_settings.getNumber("walkTurnDelay")
			local tele = g_settings.getNumber("walkTeleportDelay")
			local stairs = g_settings.getNumber("walkStairsDelay")

			styleWalkDelayScroll(panels.generalPanel:recursiveGetChildById("walkTurnDelay"), panels.generalPanel:recursiveGetChildById("walkTurnDelayHelp"), turn, useDef, tr("Walk Delay After Turn: %d ms", turn))
			styleWalkDelayScroll(panels.generalPanel:recursiveGetChildById("walkTeleportDelay"), panels.generalPanel:recursiveGetChildById("walkTeleportDelayHelp"), tele, useDef, tr("Walk Delay After Teleport: %d ms", tele))
			styleWalkDelayScroll(panels.generalPanel:recursiveGetChildById("walkStairsDelay"), panels.generalPanel:recursiveGetChildById("walkStairsDelayHelp"), stairs, useDef, tr("Walk Delay After Floor Change: %d ms", stairs))
		end
	},
	walkTurnDelay = {
		value = 100,
		action = function(value, options, controller, panels, extraWidgets)
			if not panels.generalPanel then
				return
			end

			local useDef = options.useDefaultWalkDelay and options.useDefaultWalkDelay.value
			local scroll = panels.generalPanel:recursiveGetChildById("walkTurnDelay")
			local help = panels.generalPanel:recursiveGetChildById("walkTurnDelayHelp")

			styleWalkDelayScroll(scroll, help, value, useDef, tr("Walk Delay After Turn: %d ms", value))
		end
	},
	walkTeleportDelay = {
		value = 100,
		action = function(value, options, controller, panels, extraWidgets)
			if not panels.generalPanel then
				return
			end

			local useDef = options.useDefaultWalkDelay and options.useDefaultWalkDelay.value
			local scroll = panels.generalPanel:recursiveGetChildById("walkTeleportDelay")
			local help = panels.generalPanel:recursiveGetChildById("walkTeleportDelayHelp")

			styleWalkDelayScroll(scroll, help, value, useDef, tr("Walk Delay After Teleport: %d ms", value))
		end
	},
	walkStairsDelay = {
		value = 100,
		action = function(value, options, controller, panels, extraWidgets)
			if not panels.generalPanel then
				return
			end

			local useDef = options.useDefaultWalkDelay and options.useDefaultWalkDelay.value
			local scroll = panels.generalPanel:recursiveGetChildById("walkStairsDelay")
			local help = panels.generalPanel:recursiveGetChildById("walkStairsDelayHelp")

			styleWalkDelayScroll(scroll, help, value, useDef, tr("Walk Delay After Floor Change: %d ms", value))
		end
	},
	useDefaultHotkeyDelay = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			if not panels.generalPanel then
				return
			end

			local hotkeyDelay = panels.generalPanel:recursiveGetChildById("hotkeyDelay")
			local hotkeyDelayHelp = panels.generalPanel:recursiveGetChildById("hotkeyDelayHelp")

			if hotkeyDelay then
				local valueBar = hotkeyDelay:recursiveGetChildById("valueBar")

				if valueBar then
					valueBar:setEnabled(not value)
				end

				if value then
					hotkeyDelay:setColor("#707070ff")

					if hotkeyDelayHelp then
						hotkeyDelayHelp:setVisible(false)
					end
				else
					local currentValue = options.hotkeyDelay and options.hotkeyDelay.value or 250

					hotkeyDelay:setText(string.format("Keyboard Delay: %s ms", currentValue))

					if currentValue >= 0 and currentValue <= 49 then
						hotkeyDelay:setColor("#d33c3cff")

						if hotkeyDelayHelp then
							hotkeyDelayHelp:setImageSource("/images/icons/show_gui_help_red")
							hotkeyDelayHelp:setTooltip("The selected keyboard delay is very low. It is very likely that you\nwill experience problems moving your character.")
							hotkeyDelayHelp:setVisible(true)
						end
					elseif currentValue >= 50 and currentValue <= 249 then
						hotkeyDelay:setColor("#ff9854ff")

						if hotkeyDelayHelp then
							hotkeyDelayHelp:setImageSource("/images/icons/show_gui_help_orange")
							hotkeyDelayHelp:setTooltip("The selected keyboard delay is quite low. It is possible that you\nexperience problems moving your character.")
							hotkeyDelayHelp:setVisible(true)
						end
					else
						hotkeyDelay:setColor("#c0c0c0ff")

						if hotkeyDelayHelp then
							hotkeyDelayHelp:setVisible(false)
						end
					end
				end
			end
		end
	},
	hotkeyDelay = {
		value = 70,
		action = function(value, options, controller, panels, extraWidgets)
			local hotkeyDelay = panels.generalPanel:recursiveGetChildById("hotkeyDelay")
			local hotkeyDelayHelp = panels.generalPanel:recursiveGetChildById("hotkeyDelayHelp")

			if hotkeyDelay then
				if options.useDefaultHotkeyDelay and options.useDefaultHotkeyDelay.value then
					hotkeyDelay:setColor("#707070ff")

					if hotkeyDelayHelp then
						hotkeyDelayHelp:setVisible(false)
					end
				elseif value >= 0 and value <= 49 then
					hotkeyDelay:setColor("#d33c3cff")

					if hotkeyDelayHelp then
						hotkeyDelayHelp:setImageSource("/images/icons/show_gui_help_red")
						hotkeyDelayHelp:setTooltip("The selected keyboard delay is very low. It is very likely that you\nwill experience problems moving your character.")
						hotkeyDelayHelp:setVisible(true)
					end
				elseif value >= 50 and value <= 249 then
					hotkeyDelay:setColor("#ff9854ff")

					if hotkeyDelayHelp then
						hotkeyDelayHelp:setImageSource("/images/icons/show_gui_help_orange")
						hotkeyDelayHelp:setTooltip("The selected keyboard delay is quite low. It is possible that you\nexperience problems moving your character.")
						hotkeyDelayHelp:setVisible(true)
					end
				else
					hotkeyDelay:setColor("#c0c0c0ff")

					if hotkeyDelayHelp then
						hotkeyDelayHelp:setVisible(false)
					end
				end

				hotkeyDelay:setText(string.format("Keyboard Delay: %s ms", value))
			end
		end
	},
	rotateHoldCtrl = {
		value = true
	},
	rotateHoldShift = {
		value = false
	},
	rotateHoldAlt = {
		value = false
	},
	alwaysTurnTowardsMovement = {
		value = false
	},
	stabilizeCameraOnWalk = {
		value = false,
		action = function(value)
			g_gameConfig.setStabilizeCameraOnWalk(value)
		end
	},
	enableHighlightMouseTarget = {
		deferAction = true,
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			panels.gameMapPanel:setDrawHighlightTarget(value)
			panels.gameMapPanel:setCrosshairTexture(value and "/cursors/highlight-baseplate" or nil)
		end
	},
	showLinkCopyWarning = {
		value = true,
		deferAction = true
	},
	useNativeMouseCursor = {
		deferAction = true,
		value = false,
		action = function(value, options, controller, panels, extraWidgets)
			g_mouse.setUseNativeSystemCursor(value)

			if modules.client_options and modules.client_options.updateBigMouseCursorAvailability then
				modules.client_options.updateBigMouseCursorAvailability(panels, value)
			end
		end
	},
	showBigMouseCursor = {
		deferAction = true,
		value = false,
		action = function(value, options, controller, panels, extraWidgets)
			g_mouse.setCursorDisplayScale(value and 2 or 1)
		end
	},
	graphicsEngine = {
		value = 0,
		action = function(value, options, controller, panels, extraWidgets)
			if not panels or not panels.graphicsPanel then
				return
			end

			local combo = panels.graphicsPanel:recursiveGetChildById("graphicsEngine")

			if combo then
				combo:setCurrentOptionByData(value, true)
			end

			if modules.client_options and modules.client_options.updateGraphicsEngineHelpTooltip then
				modules.client_options.updateGraphicsEngineHelpTooltip(panels, value)
			end
		end
	},
	antialiasingMode = {
		value = 0,
		action = function(value, options, controller, panels, extraWidgets)
			if panels and panels.gameMapPanel then
				panels.gameMapPanel:setAntiAliasingMode(value)
			end

			if panels and panels.graphicsPanel then
				local combo = panels.graphicsPanel:recursiveGetChildById("antialiasingMode")

				if combo then
					combo:setCurrentOptionByData(value, true)
				end
			end
		end
	},
	hdGraphics = {
		value = false,
		action = function(value, options, controller, panels, extraWidgets)
			if g_sprites and g_sprites.setScaleFactor then
				g_sprites.setScaleFactor(value and 2 or 1)
			end
			if panels and panels.gameMapPanel then
				panels.gameMapPanel:setAntiAliasingMode(options.antialiasingMode.value)
			end
		end
	},
	optimizeFps = {
		deferAction = true,
		value = false,
		action = function(value, options, controller, panels, extraWidgets)
			g_app.optimize(value)
		end
	},
	forceEffectOptimization = {
		deferAction = true,
		value = false,
		action = function(value, options, controller, panels, extraWidgets)
			g_app.forceEffectOptimization(value)
		end
	},
	drawEffectOnTop = {
		value = false,
		action = function(value, options, controller, panels, extraWidgets)
			g_app.setDrawEffectOnTop(value)
		end
	},
	floorFading = {
		value = 500,
		action = function(value, options, controller, panels, extraWidgets)
			panels.graphicsEffectsPanel:recursiveGetChildById("floorFading"):setText(string.format("Floor Fading: %s ms", value))
			panels.gameMapPanel:setFloorFading(tonumber(value))
		end
	},
	asyncTxtLoading = {
		deferAction = true,
		value = false,
		action = function(value, options, controller, panels, extraWidgets)
			if g_game.isUsingProtobuf() then
				value = true
			elseif g_app.isEncrypted() then
				if panels and panels.graphicsPanel then
					local asyncWidget = panels.graphicsPanel:recursiveGetChildById("asyncTxtLoading")

					if asyncWidget then
						asyncWidget:setEnabled(false)
						asyncWidget:setChecked(false)
					end
				end

				return
			end

			g_app.setLoadingAsyncTexture(value)
		end
	},
	showLeftExtraPanel = {
		value = false,
		action = function(value, options, controller, panels, extraWidgets)
			modules.game_interface.getLeftExtraPanel():setOn(value)
		end
	},
	showLeftPanel = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			modules.game_interface.getLeftPanel():setOn(value)
		end
	},
	showRightExtraPanel = {
		value = false,
		action = function(value, options, controller, panels, extraWidgets)
			modules.game_interface.getRightExtraPanel():setOn(value)
		end
	},
	showRightHorizontalPanel = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			local panel = modules.game_interface.getRightTopPanel()

			if panel then
				if not value then
					local rightPanel = modules.game_interface.getRightPanel()
					local mainRightPanel = modules.game_interface.getMainRightPanel()
					local children = panel:getChildren()

					for i = #children, 1, -1 do
						local child = children[i]

						if child then
							if isMiniMapContainer(child) and mainRightPanel then
								moveChildToTop(child, mainRightPanel)
							elseif rightPanel then
								child:setParent(rightPanel)
							end
						end
					end
				end

				panel:setOn(value)

				if type(modules.game_interface.updateHorizontalPanelWidths) == "function" then
					addEvent(modules.game_interface.updateHorizontalPanelWidths)
				end
			end
		end
	},
	showLeftHorizontalPanel = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			local panel = modules.game_interface.getLeftTopPanel()

			if panel then
				if not value then
					local leftPanel = modules.game_interface.getLeftPanel()
					local mainRightPanel = modules.game_interface.getMainRightPanel()
					local children = panel:getChildren()

					for i = #children, 1, -1 do
						local child = children[i]

						if child then
							if isMiniMapContainer(child) and mainRightPanel then
								moveChildToTop(child, mainRightPanel)
							elseif leftPanel then
								child:setParent(leftPanel)
							end
						end
					end
				end

				panel:setOn(value)

				if type(modules.game_interface.updateHorizontalPanelWidths) == "function" then
					addEvent(modules.game_interface.updateHorizontalPanelWidths)
				end
			end
		end
	},
	showActionbar = {
		value = false,
		action = function(value, options, controller, panels, extraWidgets)
			modules.game_actionbar.setActionBarVisible(value)
		end
	},
	showSpellGroupCooldowns = {
		deferAction = true,
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			modules.game_cooldown.setSpellGroupCooldownsVisible(value)
		end
	},
	dontStretchShrink = {
		deferAction = true,
		value = false,
		action = function(value, options, controller, panels, extraWidgets)
			addEvent(function()
				modules.game_interface.updateStretchShrink()
			end)
		end
	},
	ownSpellEffectOpacity = {
		value = 100,
		action = function(value, options, controller, panels, extraWidgets)
			g_client.setOwnSpellEffectOpacity(value)
			panels.graphicsEffectsPanel:recursiveGetChildById("ownSpellEffectOpacity"):setText(tr("Own Spell Effects: %s%%", value))
		end
	},
	othersPlayersEffectOpacity = {
		value = 100,
		action = function(value, options, controller, panels, extraWidgets)
			g_client.setOthersPlayersEffectOpacity(value)
			panels.graphicsEffectsPanel:recursiveGetChildById("othersPlayersEffectOpacity"):setText(tr("Other Players' Effects: %s%%", value))
		end
	},
	creatureSpellEffectsOpacity = {
		value = 100,
		action = function(value, options, controller, panels, extraWidgets)
			g_client.setCreatureSpellEffectsOpacity(value)
			panels.graphicsEffectsPanel:recursiveGetChildById("creatureSpellEffectsOpacity"):setText(tr("Creature Spell Effects: %s%%", value))
		end
	},
	bossAreaCreatureSpellEffectOpacity = {
		value = 100,
		action = function(value, options, controller, panels, extraWidgets)
			g_client.setBossAreaCreatureSpellEffectOpacity(value)
			panels.graphicsEffectsPanel:recursiveGetChildById("bossAreaCreatureSpellEffectOpacity"):setText(tr("Boss Area Creature Spell Effects: %s%%", value))
		end
	},
	distFromCenScrollbar = {
		value = 0,
		action = function(value, options, controller, panels, extraWidgets)
			local optionPanel = modules.game_healthcircle and modules.game_healthcircle.optionPanel

			if not optionPanel then
				return
			end

			local bar = optionPanel:recursiveGetChildById("distFromCenScrollbar")

			if not bar then
				return
			end

			bar:setText(tr("Distance: %s", bar:recursiveGetChildById("valueBar"):getValue()))

			local v = bar:recursiveGetChildById("valueBar"):getValue()

			modules.game_healthcircle.setDistanceFromCenter(modules.game_healthcircle.arcScrollPercentToDistancePixels(v))
		end
	},
	opacityScrollbar = {
		value = 0,
		action = function(value, options, controller, panels, extraWidgets)
			local optionPanel = modules.game_healthcircle and modules.game_healthcircle.optionPanel

			if not optionPanel then
				return
			end

			local bar = optionPanel:recursiveGetChildById("opacityScrollbar")

			if not bar then
				return
			end

			bar:setText(tr("Opacity: %s", bar:recursiveGetChildById("valueBar"):getValue() / 100))
			modules.game_healthcircle.setCircleOpacity(bar:recursiveGetChildById("valueBar"):getValue() / 100)
		end
	},
	showExpiryInInvetory = {
		deferAction = true,
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			if options.showExpiryInContainers.event ~= nil then
				removeEvent(options.showExpiryInInvetory.event)
			end

			options.showExpiryInInvetory.event = scheduleEvent(function()
				modules.game_inventory.reloadInventory()

				options.showExpiryInInvetory.event = nil
			end, 100)
		end
	},
	showExpiryInContainers = {
		deferAction = true,
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			if options.showExpiryInContainers.event ~= nil then
				removeEvent(options.showExpiryInContainers.event)
			end

			options.showExpiryInContainers.event = scheduleEvent(function()
				modules.game_containers.reloadContainers()

				options.showExpiryInContainers.event = nil
			end, 100)

			if modules.client_options and modules.client_options.updateShowExpiryOnUnusedAvailability then
				modules.client_options.updateShowExpiryOnUnusedAvailability(panels, value)
			end
		end
	},
	showExpiryOnUnusedItems = {
		deferAction = true,
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			if options.showExpiryOnUnusedItems.event ~= nil then
				removeEvent(options.showExpiryOnUnusedItems.event)
			end

			options.showExpiryOnUnusedItems.event = scheduleEvent(function()
				if modules.game_inventory and modules.game_inventory.reloadInventory then
					modules.game_inventory.reloadInventory()
				end

				if modules.game_containers and modules.game_containers.reloadContainers then
					modules.game_containers.reloadContainers()
				end

				options.showExpiryOnUnusedItems.event = nil
			end, 100)
		end
	},
	framesRarity = {
		deferAction = true,
		value = "frames",
		action = function(value, options, controller, panels, extraWidgets)
			local newValue = value

			if newValue == "None" then
				newValue = nil
			end

			panels.interface:recursiveGetChildById("frames"):setCurrentOptionByData(newValue, true)

			if options.framesRarity.event ~= nil then
				removeEvent(options.framesRarity.event)
			end

			options.framesRarity.event = scheduleEvent(function()
				modules.game_containers.reloadContainers()

				if modules.game_stash and modules.game_stash.renderItems then
					modules.game_stash.renderItems(0)
				end

				if modules.game_quickloot and modules.game_quickloot.QuickLoot then
					local ql = modules.game_quickloot.QuickLoot

					if ql.loadFilterItems then
						ql.loadFilterItems()
					end

					if ql.start and ql.lootContainers then
						ql.start(ql.lastQuickLootFallback, ql.lootContainers)
					end
				end

				if modules.game_search_locker and modules.game_search_locker.refreshItemVisuals then
					modules.game_search_locker.refreshItemVisuals()
				end

				options.framesRarity.event = nil
			end, 100)
		end
	},
	listKeybindsPanel = {
		action = function(value, options, controller, panels, extraWidgets)
			listKeybindsComboBox(value)
		end
	},
	graphicalCooldown = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			if not modules.game_actionbar then
				return
			end

			if not value and modules.game_actionbar.clearCooldownVisuals then
				modules.game_actionbar.clearCooldownVisuals()
			end

			if modules.game_actionbar.toggleCooldownOption then
				modules.game_actionbar.toggleCooldownOption()
			end
		end
	},
	cooldownSecond = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			return
		end
	},
	actionBarShowBottom1 = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			if not modules.game_actionbar or not modules.game_actionbar.setBottomBarGroupVisible then
				return
			end

			local allOn = modules.client_options.getOption("allActionBar13")

			if allOn == nil then
				allOn = true
			end

			local b1, b2, b3 = value, modules.client_options.getOption("actionBarShowBottom2"), modules.client_options.getOption("actionBarShowBottom3")

			modules.game_actionbar.setBottomBarGroupVisible(allOn, b1, b2, b3)
		end
	},
	actionBarShowBottom2 = {
		value = false,
		action = function(value, options, controller, panels, extraWidgets)
			if not modules.game_actionbar or not modules.game_actionbar.setBottomBarGroupVisible then
				return
			end

			local allOn = modules.client_options.getOption("allActionBar13")

			if allOn == nil then
				allOn = true
			end

			local b1, b2, b3 = modules.client_options.getOption("actionBarShowBottom1"), value, modules.client_options.getOption("actionBarShowBottom3")

			modules.game_actionbar.setBottomBarGroupVisible(allOn, b1, b2, b3)
		end
	},
	actionBarShowBottom3 = {
		value = false,
		action = function(value, options, controller, panels, extraWidgets)
			if not modules.game_actionbar or not modules.game_actionbar.setBottomBarGroupVisible then
				return
			end

			local allOn = modules.client_options.getOption("allActionBar13")

			if allOn == nil then
				allOn = true
			end

			local b1, b2, b3 = modules.client_options.getOption("actionBarShowBottom1"), modules.client_options.getOption("actionBarShowBottom2"), value

			modules.game_actionbar.setBottomBarGroupVisible(allOn, b1, b2, b3)
		end
	},
	actionBarShowLeft1 = {
		value = false,
		action = function(value, options, controller, panels, extraWidgets)
			if not modules.game_actionbar or not modules.game_actionbar.setLeftBarGroupVisible then
				return
			end

			local allOn = modules.client_options.getOption("allActionBar46")
			local c1, c2, c3 = value, modules.client_options.getOption("actionBarShowLeft2"), modules.client_options.getOption("actionBarShowLeft3")

			modules.game_actionbar.setLeftBarGroupVisible(allOn, c1, c2, c3)
		end
	},
	actionBarShowLeft2 = {
		value = false,
		action = function(value, options, controller, panels, extraWidgets)
			if not modules.game_actionbar or not modules.game_actionbar.setLeftBarGroupVisible then
				return
			end

			local allOn = modules.client_options.getOption("allActionBar46")
			local c1, c2, c3 = modules.client_options.getOption("actionBarShowLeft1"), value, modules.client_options.getOption("actionBarShowLeft3")

			modules.game_actionbar.setLeftBarGroupVisible(allOn, c1, c2, c3)
		end
	},
	actionBarShowLeft3 = {
		value = false,
		action = function(value, options, controller, panels, extraWidgets)
			if not modules.game_actionbar or not modules.game_actionbar.setLeftBarGroupVisible then
				return
			end

			local allOn = modules.client_options.getOption("allActionBar46")
			local c1, c2, c3 = modules.client_options.getOption("actionBarShowLeft1"), modules.client_options.getOption("actionBarShowLeft2"), value

			modules.game_actionbar.setLeftBarGroupVisible(allOn, c1, c2, c3)
		end
	},
	actionBarShowRight1 = {
		value = false,
		action = function(value, options, controller, panels, extraWidgets)
			if not modules.game_actionbar or not modules.game_actionbar.setRightBarGroupVisible then
				return
			end

			local allOn = modules.client_options.getOption("allActionBar79")
			local c1, c2, c3 = value, modules.client_options.getOption("actionBarShowRight2"), modules.client_options.getOption("actionBarShowRight3")

			modules.game_actionbar.setRightBarGroupVisible(allOn, c1, c2, c3)
		end
	},
	actionBarShowRight2 = {
		value = false,
		action = function(value, options, controller, panels, extraWidgets)
			if not modules.game_actionbar or not modules.game_actionbar.setRightBarGroupVisible then
				return
			end

			local allOn = modules.client_options.getOption("allActionBar79")
			local c1, c2, c3 = modules.client_options.getOption("actionBarShowRight1"), value, modules.client_options.getOption("actionBarShowRight3")

			modules.game_actionbar.setRightBarGroupVisible(allOn, c1, c2, c3)
		end
	},
	actionBarShowRight3 = {
		value = false,
		action = function(value, options, controller, panels, extraWidgets)
			if not modules.game_actionbar or not modules.game_actionbar.setRightBarGroupVisible then
				return
			end

			local allOn = modules.client_options.getOption("allActionBar79")
			local c1, c2, c3 = modules.client_options.getOption("actionBarShowRight1"), modules.client_options.getOption("actionBarShowRight2"), value

			modules.game_actionbar.setRightBarGroupVisible(allOn, c1, c2, c3)
		end
	},
	allActionBar46 = {
		value = false,
		action = function(value, options, controller, panels, extraWidgets)
			local p = panels and panels.actionBarsPanel

			if p then
				for _, id in pairs({
					"actionBarShowLeft1",
					"actionBarShowLeft2",
					"actionBarShowLeft3"
				}) do
					local w = p:recursiveGetChildById(id)

					if w and w.setEnabled then
						w:setEnabled(value)
					end
				end
			end

			if not modules.game_actionbar or not modules.game_actionbar.setLeftBarGroupVisible then
				return
			end

			if not value then
				modules.game_actionbar.setLeftBarGroupVisible(false, false, false, false)
			else
				local c1 = modules.client_options.getOption("actionBarShowLeft1")
				local c2 = modules.client_options.getOption("actionBarShowLeft2")
				local c3 = modules.client_options.getOption("actionBarShowLeft3")

				modules.game_actionbar.setLeftBarGroupVisible(true, c1, c2, c3)
			end
		end
	},
	allActionBar13 = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			local p = panels and panels.actionBarsPanel

			if p then
				for _, id in pairs({
					"actionBarShowBottom1",
					"actionBarShowBottom2",
					"actionBarShowBottom3"
				}) do
					local w = p:recursiveGetChildById(id)

					if w and w.setEnabled then
						w:setEnabled(value)
					end
				end
			end

			if not modules.game_actionbar or not modules.game_actionbar.setBottomBarGroupVisible then
				return
			end

			if not value then
				modules.game_actionbar.setBottomBarGroupVisible(false, false, false, false)
			else
				local b1 = modules.client_options.getOption("actionBarShowBottom1")
				local b2 = modules.client_options.getOption("actionBarShowBottom2")
				local b3 = modules.client_options.getOption("actionBarShowBottom3")

				modules.game_actionbar.setBottomBarGroupVisible(true, b1, b2, b3)
			end
		end
	},
	allActionBar79 = {
		value = false,
		action = function(value, options, controller, panels, extraWidgets)
			local p = panels and panels.actionBarsPanel

			if p then
				for _, id in pairs({
					"actionBarShowRight1",
					"actionBarShowRight2",
					"actionBarShowRight3"
				}) do
					local w = p:recursiveGetChildById(id)

					if w and w.setEnabled then
						w:setEnabled(value)
					end
				end
			end

			if not modules.game_actionbar or not modules.game_actionbar.setRightBarGroupVisible then
				return
			end

			if not value then
				modules.game_actionbar.setRightBarGroupVisible(false, false, false, false)
			else
				local c1 = modules.client_options.getOption("actionBarShowRight1")
				local c2 = modules.client_options.getOption("actionBarShowRight2")
				local c3 = modules.client_options.getOption("actionBarShowRight3")

				modules.game_actionbar.setRightBarGroupVisible(true, c1, c2, c3)
			end
		end
	},
	actionTooltip = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			if modules.game_actionbar and modules.game_actionbar.updateVisibleOptions then
				modules.game_actionbar.updateVisibleOptions("tooltip", value)
			end
		end
	},
	showSpellParameters = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			if modules.game_actionbar and modules.game_actionbar.updateVisibleOptions then
				modules.game_actionbar.updateVisibleOptions("parameter", value)
			end
		end
	},
	showHKObjectsBars = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			if modules.game_actionbar and modules.game_actionbar.updateVisibleOptions then
				modules.game_actionbar.updateVisibleOptions("amount", value)
			end
		end
	},
	showAssignedHKButton = {
		value = true,
		action = function(value, options, controller, panels, extraWidgets)
			if modules.game_actionbar and modules.game_actionbar.updateVisibleOptions then
				modules.game_actionbar.updateVisibleOptions("hotkey", value)
			end
		end
	},
	askBeforeBuying = {
		value = true
	},
	askBeforeStowing = {
		value = true
	},
	askBeforeSorting = {
		value = true
	},
	askBeforeMoving = {
		value = true
	},
	stayLoggedIn = {
		value = true
	},
	allowInspect = {
		value = false,
		action = function(value)
			syncAllowInspectSetting(value)
		end
	}
}
