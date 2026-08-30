-- chunkname: @/client_entergame/characterlist.lua

CharacterList = {}

local charactersWindow, loadBox, characterList, errorBox, waitingWindow, updateWaitEvent, resendWaitEvent, loginEvent, outfitCreatureBox
local restoreCharacterListEvent
local WORLD_TYPE_NAMES = {
	[0] = "Open PvP",
	"Optional PvP",
	"Hardcore PvP",
	"Retro Open PvP",
	"Retro Hardcore PvP"
}

local function getWorldTypeName(worldTypeId)
	local name = WORLD_TYPE_NAMES[worldTypeId]

	if not name then
		return nil
	end

	return tr(name)
end

local autoReconnectEvent
local lastLogout = 0
local manualLogoutPending = false
local autoReconnectAttempt = false
local reconnectAttemptCount = 0
local suppressLogoutTimestamp = false
local lastScheduleReconnectAt = 0
local RECONNECT_SCHEDULE_DEBOUNCE_MS = 500
local sortAlphabetical = false
local AUTO_RECONNECT_MAX_TRIES = 120
local AUTO_RECONNECT_FORCE_LOGOUT_AFTER = 20
local PINNED_CHARACTERS_SETTING = "pinned-characters"
local PIN_CLIP_OUTLINE = "0 0 12 12"
local PIN_CLIP_ACTIVE = "0 12 12 12"
local pendingFocusCharacterKey, pinnedCharactersData

local function makeCharacterKey(characterInfo)
	return string.format("%s|%s|%s", G.account or "", characterInfo.name or "", characterInfo.worldName or "")
end

local function loadPinnedCharacters()
	local data = {
		map = {},
		order = {},
		orderIndex = {}
	}
	local keys = g_settings.getList(PINNED_CHARACTERS_SETTING)

	if type(keys) == "table" and #keys > 0 then
		for index, key in ipairs(keys) do
			if type(key) == "string" and key ~= "" then
				data.map[key] = true

				table.insert(data.order, key)

				data.orderIndex[key] = index
			end
		end

		return data
	end

	local raw = g_settings.get(PINNED_CHARACTERS_SETTING)

	if not raw or raw == "" then
		return data
	end

	local ok, decoded = pcall(function()
		return json.decode(raw)
	end)

	if not ok or type(decoded) ~= "table" then
		return data
	end

	local migratedOrder = {}

	for index, key in ipairs(decoded) do
		if type(key) == "string" and key ~= "" then
			data.map[key] = true

			table.insert(data.order, key)

			data.orderIndex[key] = index

			table.insert(migratedOrder, key)
		end
	end

	if #migratedOrder > 0 then
		savePinnedCharacters(migratedOrder)
	end

	return data
end

local function savePinnedCharacters(orderArray)
	g_settings.setList(PINNED_CHARACTERS_SETTING, orderArray or {})
	g_settings.save()
end

local function isCharacterPinned(key, pinnedData)
	pinnedData = pinnedData or pinnedCharactersData

	return pinnedData and pinnedData.map[key] == true
end

local function getPinSortIndex(key, pinnedData)
	pinnedData = pinnedData or pinnedCharactersData

	local index = pinnedData and pinnedData.orderIndex[key]

	if index then
		return index
	end

	return math.huge
end

local function updateCharacterPinWidget(widget, isFocused, pinnedData)
	if not widget then
		return
	end

	local pin = widget:getChildById("characterPin")

	if not pin then
		return
	end

	if not g_game.getFeature(GameEnterGameShowAppearance) then
		pin:setVisible(false)

		return
	end

	local key = widget.characterKey

	if isCharacterPinned(key, pinnedData) then
		pin:setVisible(true)
		pin:setImageClip(PIN_CLIP_ACTIVE)
	elseif isFocused then
		pin:setVisible(true)
		pin:setImageClip(PIN_CLIP_OUTLINE)
	else
		pin:setVisible(false)
	end
end

local function refreshCharacterPinStates()
	if not characterList then
		return
	end

	local focused = characterList:getFocusedChild()

	for _, widget in ipairs(characterList:getChildren()) do
		updateCharacterPinWidget(widget, widget == focused, pinnedCharactersData)
	end
end

local function sortCharacters(characters, pinnedData)
	local sorted = {}

	for i, characterInfo in ipairs(characters) do
		characterInfo.__originalIndex = characterInfo.__originalIndex or i

		table.insert(sorted, characterInfo)
	end

	table.sort(sorted, function(a, b)
		local aKey = makeCharacterKey(a)
		local bKey = makeCharacterKey(b)
		local aPinIndex = getPinSortIndex(aKey, pinnedData)
		local bPinIndex = getPinSortIndex(bKey, pinnedData)

		if aPinIndex ~= bPinIndex then
			return aPinIndex < bPinIndex
		end

		if sortAlphabetical then
			local aName = (a.name or ""):lower()
			local bName = (b.name or ""):lower()

			if aName == bName then
				return (a.__originalIndex or 0) < (b.__originalIndex or 0)
			end

			return aName < bName
		end

		return (a.__originalIndex or 0) < (b.__originalIndex or 0)
	end)

	return sorted
end

local function updateSortButton()
	if not charactersWindow then
		return
	end

	local sortButton = charactersWindow:recursiveGetChildById("sortOrderButton")

	if not sortButton then
		return
	end

	if sortAlphabetical then
		sortButton:setText("A-Z")
		sortButton:setTooltip(tr("Sorted alphabetically"))
	else
		sortButton:setText("Srv")
		sortButton:setTooltip(tr("Sorted by server order"))
	end
end

local function removeAutoReconnectEvent()
	if autoReconnectEvent then
		removeEvent(autoReconnectEvent)

		autoReconnectEvent = nil
	end
end

local function cancelRestoreCharacterListEvent()
	if restoreCharacterListEvent then
		removeEvent(restoreCharacterListEvent)

		restoreCharacterListEvent = nil
	end
end

local function destroyTrackedErrorBox()
	local box = errorBox

	errorBox = nil

	if not isWidgetAlive(box) then
		return
	end

	if g_modalManager and g_modalManager.hide then
		g_modalManager.hide(box)
	end

	box:destroy()
end

local function clearStaleErrorBox()
	if not errorBox then
		return
	end

	if isWidgetAlive(errorBox) and errorBox:isVisible() then
		return
	end

	destroyTrackedErrorBox()
end

local function trackErrorBox(box)
	destroyTrackedErrorBox()

	errorBox = box

	connect(box, {
		onDestroy = function(destroyedBox)
			if errorBox == destroyedBox then
				errorBox = nil
			end
		end
	})

	return box
end

local function resetReconnectBackoff()
	reconnectAttemptCount = 0
	autoReconnectAttempt = false
end

local function getReconnectDelay()
	if reconnectAttemptCount <= 3 then
		return 2500
	elseif reconnectAttemptCount <= 6 then
		return 5000
	elseif reconnectAttemptCount <= 10 then
		return 10000
	end

	return 15000
end

local function tryLogin(charInfo, tries)
	tries = tries or 1

	local maxTries = autoReconnectAttempt and AUTO_RECONNECT_MAX_TRIES or 50

	if maxTries < tries then
		if autoReconnectAttempt and g_game.isOnline() then
			g_logger.warning("[reconnect] still online after force logout, retrying later")

			autoReconnectAttempt = false

			scheduleAutoReconnect()
		end

		return
	end

	if g_game.isOnline() then
		if autoReconnectAttempt and tries > AUTO_RECONNECT_FORCE_LOGOUT_AFTER then
			g_game.forceLogout()
		elseif tries == 1 then
			g_game.safeLogout()
		end

		if loginEvent then
			removeEvent(loginEvent)

			loginEvent = nil
		end

		loginEvent = scheduleEvent(function()
			tryLogin(charInfo, tries + 1)
		end, 100)

		return
	end

	CharacterList.hide()
	g_logger.info("Login to " .. charInfo.worldHost .. ":" .. charInfo.worldPort)

	g_game.loginWorld(G.account, G.password, charInfo.worldName, charInfo.worldHost, charInfo.worldPort, charInfo.characterName, G.authenticatorToken, G.sessionKey)

	loadBox = displayCancelBox(tr("Connecting"), tr("Connecting to the game world. Please wait."))

	connect(loadBox, {
		onCancel = function()
			loadBox = nil

			g_game.cancelLogin()
			resetReconnectBackoff()
			CharacterList.show()
		end
	})
	g_settings.set("last-used-character", charInfo.characterName)
	g_settings.set("last-used-world", charInfo.worldName)
	removeAutoReconnectEvent()
end

local function updateWait(timeStart, timeEnd)
	if waitingWindow then
		local time = g_clock.seconds()

		if time <= timeEnd then
			local percent = (time - timeStart) / (timeEnd - timeStart) * 100
			local timeStr = string.format("%.0f", timeEnd - time)
			local progressBar = waitingWindow:getChildById("progressBar")

			progressBar:setPercent(percent)

			local label = waitingWindow:getChildById("timeLabel")

			label:setText(tr("Trying to reconnect in %s seconds.", timeStr))

			updateWaitEvent = scheduleEvent(function()
				updateWait(timeStart, timeEnd)
			end, 1000)

			return true
		end
	end

	if updateWaitEvent then
		updateWaitEvent:cancel()

		updateWaitEvent = nil
	end
end

local function resendWait()
	if waitingWindow then
		waitingWindow:destroy()

		waitingWindow = nil

		if updateWaitEvent then
			updateWaitEvent:cancel()

			updateWaitEvent = nil
		end

		if charactersWindow then
			local selected = characterList:getFocusedChild()

			if selected then
				local charInfo = {
					worldHost = selected.worldHost,
					worldPort = selected.worldPort,
					worldName = selected.worldName,
					characterName = selected.characterName,
					characterLevel = selected.characterLevel,
					main = selected.main,
					dailyreward = selected.dailyreward,
					hidden = selected.hidden,
					outfitid = selected.outfitid,
					headcolor = selected.headcolor,
					torsocolor = selected.torsocolor,
					legscolor = selected.legscolor,
					detailcolor = selected.detailcolor,
					addonsflags = selected.addonsflags,
					characterVocation = selected.characterVocation
				}

				tryLogin(charInfo)
			end
		end
	end
end

local function onLoginWait(message, time)
	CharacterList.destroyLoadBox()

	waitingWindow = g_ui.displayUI("waitinglist")

	local label = waitingWindow:getChildById("infoLabel")

	label:setText(message)

	updateWaitEvent = scheduleEvent(function()
		updateWait(g_clock.seconds(), g_clock.seconds() + time)
	end, 0)
	resendWaitEvent = scheduleEvent(resendWait, time * 1000)
end

function onGameLoginError(message, msgType)
	CharacterList.destroyLoadBox()

	msgType = tonumber(msgType) or 0

	local function onLoginErrorOk()
		errorBox = nil

		if msgType == 1 then
			CharacterList.hide(true)
		elseif msgType == 2 then
			if g_app and g_app.restart then
				g_app.restart()
			else
				CharacterList.hide(true)
			end
		else
			CharacterList.showAgain()
		end
	end

	local box = trackErrorBox(displayErrorBox(tr("Sorry"), message))

	box.onOk = onLoginErrorOk
end

function onGameSessionEnd(reason)
	CharacterList.destroyLoadBox()

	if g_game.isOnline() then
		suppressLogoutTimestamp = true

		g_game.forceLogout()

		suppressLogoutTimestamp = false

		return
	end

	CharacterList.showAgain()
end

function onGameConnectionError(message, code)
	CharacterList.destroyLoadBox()

	code = tonumber(code) or 0

	if g_settings.getBoolean("autoReconnect") and isRecoverableConnectionError(code) then
		if not g_game.isOnline() then
			CharacterList.showAgain()
		end
	else
		local text = translateNetworkError(code, g_game.getProtocolGame() and g_game.getProtocolGame():isConnecting(), message)
		local box = trackErrorBox(displayErrorBox(tr("Connection Error"), text))

		function box.onOk()
			errorBox = nil

			CharacterList.showAgain()
		end
	end
end

function onGameUpdateNeeded(signature)
	CharacterList.destroyLoadBox()

	local box = trackErrorBox(displayErrorBox(tr("Update needed"), tr("Enter with your account again to update your client.")))

	function box.onOk()
		errorBox = nil

		CharacterList.showAgain()
	end
end

local function onGameStart()
	cancelRestoreCharacterListEvent()

	manualLogoutPending = false

	resetReconnectBackoff()
end

local function onGameEnd()
	CharacterList.destroyLoadBox()
	cancelRestoreCharacterListEvent()

	restoreCharacterListEvent = addEvent(function()
		restoreCharacterListEvent = nil

		if CharacterList and not g_game.isOnline() and not g_game.isLogging() then
			CharacterList.showAgain()
		end
	end)
end

function CharacterList.init()
	connect(g_game, {
		onLoginError = onGameLoginError
	})
	connect(g_game, {
		onSessionEnd = onGameSessionEnd
	})
	connect(g_game, {
		onUpdateNeeded = onGameUpdateNeeded
	})
	connect(g_game, {
		onConnectionError = onGameConnectionError
	})
	connect(g_game, {
		onGameStart = onGameStart
	})
	connect(g_game, {
		onLoginWait = onLoginWait
	})
	connect(g_game, {
		onGameEnd = onGameEnd
	})
	connect(g_game, {
		onLogout = onLogout
	})

	if G.characters then
		CharacterList.create(G.characters, G.characterAccount)
	end
end

function CharacterList.terminate()
	cancelRestoreCharacterListEvent()
	disconnect(g_game, {
		onLoginError = onGameLoginError
	})
	disconnect(g_game, {
		onSessionEnd = onGameSessionEnd
	})
	disconnect(g_game, {
		onUpdateNeeded = onGameUpdateNeeded
	})
	disconnect(g_game, {
		onConnectionError = onGameConnectionError
	})
	disconnect(g_game, {
		onGameStart = onGameStart
	})
	disconnect(g_game, {
		onLoginWait = onLoginWait
	})
	disconnect(g_game, {
		onGameEnd = onGameEnd
	})
	disconnect(g_game, {
		onLogout = onLogout
	})

	if charactersWindow then
		characterList = nil

		charactersWindow:destroy()

		charactersWindow = nil
	end

	if loadBox then
		g_game.cancelLogin()
		loadBox:destroy()

		loadBox = nil
	end

	if waitingWindow then
		waitingWindow:destroy()

		waitingWindow = nil
	end

	if updateWaitEvent then
		removeEvent(updateWaitEvent)

		updateWaitEvent = nil
	end

	if resendWaitEvent then
		removeEvent(resendWaitEvent)

		resendWaitEvent = nil
	end

	if loginEvent then
		removeEvent(loginEvent)

		loginEvent = nil
	end

	destroyTrackedErrorBox()
	removeAutoReconnectEvent()
	resetReconnectBackoff()

	manualLogoutPending = false

	destroyCreateAccount()

	CharacterList = nil
end

function CharacterList.create(characters, account, otui)
	otui = otui or "characterlist"

	if charactersWindow then
		if isWidgetAlive(charactersWindow) then
			charactersWindow:destroy()
		end

		charactersWindow = nil
		characterList = nil
	end

	charactersWindow = g_ui.displayUI(otui)
	characterList = charactersWindow:recursiveGetChildById("characters")

	if not characterList then
		return
	end

	local sortButton = charactersWindow:recursiveGetChildById("sortOrderButton")

	if sortButton then
		function sortButton.onClick()
			CharacterList.toggleSortOrder()

			return true
		end
	end

	updateSortButton()

	G.characters = characters
	G.characterAccount = account

	characterList:destroyChildren()

	local accountStatusLabel = charactersWindow:getChildById("accountStatusLabel")
	local accountStatusIcon = charactersWindow:getChildById("accountStatusIcon")
	local recoverySetupLabel = charactersWindow:getChildById("recoverySetupLabel")
	local hiddenCharacterBox = charactersWindow:getChildById("hiddenCharacterBox")
	local focusLabel
	local focusKey = pendingFocusCharacterKey

	pendingFocusCharacterKey = nil
	pinnedCharactersData = loadPinnedCharacters()

	local sortedCharacters = sortCharacters(characters, pinnedCharactersData)

	for i, characterInfo in ipairs(sortedCharacters) do
		local widget = g_ui.createWidget("CharacterWidget", characterList)

		for key, value in pairs(characterInfo) do
			local subWidget = widget:getChildById(key)

			if subWidget then
				if key == "outfit" then
					subWidget:setOutfit(value)
				elseif key == "worldPvpType" then
					local name = getWorldTypeName(value)

					if name then
						subWidget:setText(string.format("(%s)", name))
					end
				else
					local text = value

					if subWidget.baseText and subWidget.baseTranslate then
						text = tr(subWidget.baseText, text)
					elseif subWidget.baseText then
						text = string.format(subWidget.baseText, text)
					end

					subWidget:setText(text)
				end
			end
		end

		local creatureDisplay = widget:recursiveGetChildById("outfitCreatureBox", characterList)
		local creature = Creature.create()
		local outfit = {
			type = characterInfo.outfitid,
			head = characterInfo.headcolor,
			body = characterInfo.torsocolor,
			legs = characterInfo.legscolor,
			feet = characterInfo.detailcolor,
			addons = characterInfo.addonsflags
		}

		creature:setOutfit(outfit)
		creature:setDirection(2)
		creature:setAnimate(false)
		creatureDisplay:setCreature(creature)

		local mainCharacter = widget:getChildById("mainCharacter", characterList)

		if characterInfo.main then
			mainCharacter:setImageSource("/images/game/entergame/maincharacter")
		else
			mainCharacter:setImageSource("")
		end

		local statusDailyReward = widget:getChildById("statusDailyReward", characterList)

		if characterInfo.dailyreward == 1 then
			statusDailyReward:setImageSource("/images/game/entergame/dailyreward_collected")
		else
			statusDailyReward:setImageSource("/images/game/entergame/dailyreward_notcollected")
		end

		local statusHidden = widget:getChildById("statusHidden", characterList)

		if characterInfo.hidden then
			statusHidden:setImageSource("/images/game/entergame/hidden")

			if not hiddenCharacterBox:isChecked() then
				widget:hide()
			end
		else
			statusHidden:setImageSource("")
		end

		widget.characterName = characterInfo.name
		widget.worldName = characterInfo.worldName
		widget.worldHost = characterInfo.worldIp
		widget.worldPort = characterInfo.worldPort
		widget.hidden = characterInfo.hidden
		widget.characterKey = makeCharacterKey(characterInfo)

		local characterPin = widget:getChildById("characterPin")

		if characterPin then
			function characterPin.onClick()
				CharacterList.toggleCharacterPin(widget)

				return true
			end

			updateCharacterPinWidget(widget, false, pinnedCharactersData)
		end

		connect(widget, {
			onDoubleClick = function()
				CharacterList.doLogin()

				return true
			end
		})

		if focusKey and widget.characterKey == focusKey then
			focusLabel = widget
		elseif not focusKey and not characterInfo.hidden and (i == 1 or g_settings.get("last-used-character") == widget.characterName and g_settings.get("last-used-world") == widget.worldName) then
			focusLabel = widget
		end
	end

	if focusLabel then
		characterList:focusChild(focusLabel, KeyboardFocusReason)
		addEvent(function()
			characterList:ensureChildVisible(focusLabel)
		end)
	end

	refreshCharacterPinStates()

	function characterList.onChildFocusChange()
		removeAutoReconnectEvent()
		refreshCharacterPinStates()
	end

	local listScrollBar = charactersWindow:getChildById("characterListScrollBar")

	if listScrollBar and characterList.setVerticalScrollBar then
		characterList:setVerticalScrollBar(listScrollBar)
	end

	if characterList.updateScrollBars then
		characterList:updateScrollBars()
	end

	local recoveryIncomplete = account and (account.recoverySetupComplete == false or account.recoverySetupComplete == 0 or account.recoverySetupComplete == "false" or account.recoverySetupComplete == "0")

	if recoverySetupLabel then
		if recoveryIncomplete then
			recoverySetupLabel:setText(tr("You need to complete the recovery setup process!"))
			recoverySetupLabel:setVisible(true)
			recoverySetupLabel:setHeight(24)
			recoverySetupLabel:setMarginBottom(5)
		else
			recoverySetupLabel:setVisible(false)
			recoverySetupLabel:setText("")
			recoverySetupLabel:setHeight(0)
			recoverySetupLabel:setMarginBottom(0)
		end
	end

	local status = ""

	if account.status == AccountStatus.Frozen then
		status = tr(" (Frozen)")
	elseif account.status == AccountStatus.Suspended then
		status = tr(" (Suspended)")
	end

	local premiumButton = charactersWindow:getChildById("getPremiumButton")

	if account.subStatus == SubscriptionStatus.Free then
		accountStatusLabel:setText(("%s%s"):format(tr("Free Account"), status))

		if accountStatusIcon ~= nil then
			accountStatusIcon:setImageSource("/images/game/entergame/nopremium")
		end

		if premiumButton then
			premiumButton:setVisible(true)
		end
	elseif account.subStatus == SubscriptionStatus.Premium then
		if account.premDays == 0 or account.premDays == 65535 then
			accountStatusLabel:setText(("%s%s"):format(tr("Gratis Premium Account"), status))
		else
			local color = account.premDays >= 10 and "#c0c0c0" or "#f86060"

			accountStatusLabel:setColoredText(("%s%s"):format(tr("{Premium Account, #c0c0c0} {(%s days left), " .. color .. "}", account.premDays), status))
		end

		if accountStatusIcon ~= nil then
			accountStatusIcon:setImageSource("/images/game/entergame/premium")
		end

		if premiumButton then
			premiumButton:setVisible(account.premDays > 0 and account.premDays < 10)
		end
	elseif premiumButton then
		premiumButton:setVisible(false)
	end

	if account.premDays > 0 and account.premDays < 10 then
		accountStatusLabel:setOn(true)
	else
		accountStatusLabel:setOn(false)
	end
end

function CharacterList.toggleSortOrder()
	if not G.characters or not G.characterAccount then
		return
	end

	sortAlphabetical = not sortAlphabetical

	CharacterList.create(G.characters, G.characterAccount)
	CharacterList.show()
end

function CharacterList.toggleCharacterPin(widget)
	if not widget or not widget.characterKey then
		return
	end

	if not G.characters or not G.characterAccount then
		return
	end

	local key = widget.characterKey
	local pinnedData = loadPinnedCharacters()
	local newOrder = {}

	for _, existingKey in ipairs(pinnedData.order) do
		table.insert(newOrder, existingKey)
	end

	if pinnedData.map[key] then
		for i = #newOrder, 1, -1 do
			if newOrder[i] == key then
				table.remove(newOrder, i)

				break
			end
		end
	else
		table.insert(newOrder, key)
	end

	savePinnedCharacters(newOrder)

	pendingFocusCharacterKey = key

	CharacterList.create(G.characters, G.characterAccount)
	CharacterList.show()
end

function CharacterList.destroy()
	CharacterList.hide(true)

	if charactersWindow then
		characterList = nil

		charactersWindow:destroy()

		charactersWindow = nil
	end
end

function CharacterList.show()
	clearStaleErrorBox()

	if loadBox or errorBox or not isWidgetAlive(charactersWindow) then
		return false
	end

	-- Fade the window in (appear effect). Hiding stays synchronous so ESC->login works.
	charactersWindow:show()
	charactersWindow:raise()
	charactersWindow:focus()
	g_effects.fadeIn(charactersWindow, 300)

	return true
end

function CharacterList.hide(showLogin)
	removeAutoReconnectEvent()

	showLogin = showLogin or false

	if isWidgetAlive(charactersWindow) then
		g_effects.cancelFade(charactersWindow)
		charactersWindow:hide()
		charactersWindow:setOpacity(1)
	end

	if showLogin and EnterGame and not g_game.isOnline() then
		EnterGame.show()
	end
end

local function shouldDropSessionOnLogout()
	if not manualLogoutPending then
		return false
	end

	if not modules.client_options or not modules.client_options.getOption then
		return false
	end

	return modules.client_options.getOption("stayLoggedIn") == false
end

local function dropCachedSession()
	G.password = nil
	G.sessionKey = nil
	G.authenticatorToken = nil
	G.characters = nil
	G.characterAccount = nil

	g_settings.remove("password")

	if isWidgetAlive(characterList) then
		characterList:destroyChildren()
	end
end

function CharacterList.showAgain()
	clearStaleErrorBox()

	if errorBox then
		return false
	end

	if shouldDropSessionOnLogout() then
		manualLogoutPending = false
		dropCachedSession()
		CharacterList.hide()

		if EnterGame and not g_game.isOnline() and not g_game.isLogging() then
			EnterGame.show()
		end

		return false
	end

	if (not isWidgetAlive(characterList) or not characterList:hasChildren()) and type(G.characters) == "table" and type(G.characterAccount) == "table" then
		CharacterList.create(G.characters, G.characterAccount)
	end

	if isWidgetAlive(characterList) and characterList:hasChildren() and CharacterList.show() then
		scheduleAutoReconnect()

		return true
	end

	if EnterGame and not g_game.isOnline() and not g_game.isLogging() then
		g_logger.warning("[character-list] cached character list unavailable; showing account login")
		EnterGame.show()
	end

	return false
end

function CharacterList.isVisible()
	if isWidgetAlive(charactersWindow) and charactersWindow:isVisible() then
		return true
	end

	return false
end

function CharacterList.doLogin(fromAutoReconnect)
	cancelRestoreCharacterListEvent()
	removeAutoReconnectEvent()

	if not fromAutoReconnect then
		autoReconnectAttempt = false
		manualLogoutPending = false
	end

	local selected = characterList:getFocusedChild()

	if selected then
		local charInfo = {
			worldHost = selected.worldHost,
			worldPort = selected.worldPort,
			worldName = selected.worldName,
			characterName = selected.characterName
		}

		charactersWindow:hide()

		if loginEvent then
			removeEvent(loginEvent)

			loginEvent = nil
		end

		tryLogin(charInfo)
	else
		displayErrorBox(tr("Error"), tr("You must select a character to login!"))
	end
end

function CharacterList.destroyLoadBox()
	if loadBox then
		loadBox:destroy()

		loadBox = nil
	end

	destroyCreateAccount()
end

function CharacterList.cancelWait()
	if waitingWindow then
		waitingWindow:destroy()

		waitingWindow = nil
	end

	if updateWaitEvent then
		removeEvent(updateWaitEvent)

		updateWaitEvent = nil
	end

	if resendWaitEvent then
		removeEvent(resendWaitEvent)

		resendWaitEvent = nil
	end

	CharacterList.destroyLoadBox()
	CharacterList.showAgain()
end

function CharacterList.updateCharactersAppearances(showOutfits)
	if showOutfitsCheckbox and showOutfits ~= showOutfitsCheckbox:isChecked() then
		showOutfitsCheckbox:setChecked(showOutfits)
	end

	if not characterList or #characterList:getChildren() == 0 then
		return
	end

	for _, widget in ipairs(characterList:getChildren()) do
		if not widget.characterInfo then
			break
		end

		if not widget.creature or not widget.creatureBorder then
			widget.creature = widget:recursiveGetChildById("creature")
			widget.creatureBorder = widget.creature:getParent()
		end

		CharacterList.updateCharactersAppearance(widget, widget.characterInfo, showOutfits)
	end
end

function onLogout()
	if modules.game_interface and modules.game_interface.saveSidebarsBeforeLogout then
		modules.game_interface.saveSidebarsBeforeLogout()
	end

	if autoReconnectAttempt or suppressLogoutTimestamp then
		return
	end

	manualLogoutPending = true
	lastLogout = g_clock.millis()
end

function scheduleAutoReconnect()
	if not g_settings.getBoolean("autoReconnect") or manualLogoutPending or lastLogout + 2000 > g_clock.millis() then
		return
	end

	local now = g_clock.millis()
	local isDuplicateSchedule = autoReconnectEvent ~= nil or now - lastScheduleReconnectAt < RECONNECT_SCHEDULE_DEBOUNCE_MS

	if not isDuplicateSchedule then
		reconnectAttemptCount = reconnectAttemptCount + 1
	end

	lastScheduleReconnectAt = now

	local delay = getReconnectDelay()

	g_logger.info(string.format("[reconnect] scheduling attempt %d in %d ms", reconnectAttemptCount, delay))
	removeAutoReconnectEvent()

	autoReconnectEvent = scheduleEvent(executeAutoReconnect, delay)
end

function executeAutoReconnect()
	if not g_settings.getBoolean("autoReconnect") then
		return
	end

	if loadBox then
		g_logger.info("[reconnect] login already in progress, skipping")

		return
	end

	if errorBox then
		errorBox:destroy()

		errorBox = nil
	end

	autoReconnectAttempt = true

	g_logger.info(string.format("[reconnect] executing attempt %d", reconnectAttemptCount))
	CharacterList.doLogin(true)
end

function toggleShowOutfit(checked)
	if not charactersWindow then
		return
	end

	local characterList = charactersWindow:recursiveGetChildById("characters")

	if not characterList then
		return
	end

	for _, child in ipairs(characterList:getChildren()) do
		local outfit = child:getChildById("outfit")

		outfit:setWidth(checked and outfit.baseWidth or 0)
	end
end

function toggleHiddenCharacters(checked)
	if not charactersWindow then
		return
	end

	local characterList = charactersWindow:recursiveGetChildById("characters")

	if not characterList then
		return
	end

	for _, child in ipairs(characterList:getChildren()) do
		if child.hidden then
			child:setVisible(checked)
		end
	end
end
