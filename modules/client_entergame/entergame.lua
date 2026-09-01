-- chunkname: @/client_entergame/entergame.lua

EnterGame = {}

local loadBox, enterGame, motdWindow, enterGameButton, clientBox
local motdEnabled = true
local twoFactorWindow, hostInfos

local function buildLoginBody(token)
	local body = {
		stayloggedin = true,
		type = "login",
		email = G.account,
		password = G.password
	}

	if token and token:len() > 0 then
		body.token = token
	end

	return body
end

local function buildLoginUrl(scheme, port)
	return string.format("%s://%s:%d%s", scheme, G.loginHost, port, G.loginPath)
end

local function sendHttpLoginRequest(httpLogin, token, scheme, port)
	local requestId = G.requestId
	local url = buildLoginUrl(scheme, port)

	G.httpOperationId = HTTP.postJSON(url, buildLoginBody(token), function(data, err)
		if G.requestId ~= requestId then
			return
		end

		if err and scheme == "https" and httpLogin then
			sendHttpLoginRequest(httpLogin, token, "http", G.httpFallbackPort or 80)

			return
		end

		EnterGame.handleHttpLoginResponse(data, err, requestId)
	end)
end

local function onError(protocol, message, errorCode)
	if loadBox then
		loadBox:destroy()

		loadBox = nil
	end

	if not errorCode then
		EnterGame.clearAccountFields()
	end

	local errorBox = displayErrorBox(tr("Sorry"), message)

	connect(errorBox, {
		onOk = EnterGame.show
	})
end

local function onMotd(protocol, motd)
	G.motdNumber = tonumber(motd:sub(0, motd:find("\n")))
	G.motdMessage = motd:sub(motd:find("\n") + 1, #motd)
end

local function onSessionKey(protocol, sessionKey)
	G.sessionKey = sessionKey
end

local function onCharacterList(protocol, characters, account, otui)
	local hostInit, valuesInit = next(Servers_init)
	local httpLogin = valuesInit.httpLogin

	g_settings.set("httpLogin", httpLogin)

	if enterGame:getChildById("rememberEmailBox"):isChecked() then
		local account = g_crypt.encrypt(G.account)

		g_settings.set("account", account)
	else
		EnterGame.clearAccountNameFields()
	end

	if enterGame:getChildById("rememberPasswordBox"):isChecked() then
		local password = g_crypt.encrypt(G.password)

		g_settings.set("password", password)
	else
		EnterGame.clearPasswordNameFields()
	end

	if loadBox then
		loadBox:destroy()

		loadBox = nil
	end

	for _, characterInfo in pairs(characters) do
		if characterInfo.previewState and characterInfo.previewState ~= PreviewState.Default then
			characterInfo.worldName = characterInfo.worldName .. ", Preview"
		end
	end

	CharacterList.create(characters, account, otui)
	CharacterList.show()

	if motdEnabled then
		local lastMotdNumber = g_settings.getNumber("motd")

		if G.motdNumber and G.motdNumber ~= lastMotdNumber then
			g_settings.set("motd", G.motdNumber)

			motdWindow = displayInfoBox(tr("Message of the day"), G.motdMessage)

			connect(motdWindow, {
				onOk = function()
					CharacterList.show()

					motdWindow = nil
				end
			})
			CharacterList.hide()
		end
	end
end

local function onUpdateNeeded(protocol, signature)
	if loadBox then
		loadBox:destroy()

		loadBox = nil
	end

	if EnterGame.updateFunc then
		local continueFunc = EnterGame.show
		local cancelFunc = EnterGame.show

		EnterGame.updateFunc(signature, continueFunc, cancelFunc)
	else
		local errorBox = displayErrorBox(tr("Update needed"), tr("Your client needs updating, try redownloading it."))

		connect(errorBox, {
			onOk = EnterGame.show
		})
	end
end

local function updateLabelText()
	enterGame:setText("Journey Onwards")
	enterGame:getChildById("emailLabel"):setText("Email:")
	enterGame:getChildById("rememberEmailBox"):setText("Remember Email")
end

function EnterGame.init()
	enterGame = g_ui.displayUI("entergame")

	Keybind.new("Misc.", "Change Character", "Ctrl+G", "")
	Keybind.bind("Misc.", "Change Character", {
		{
			type = KEY_DOWN,
			callback = EnterGame.openWindow
		}
	})

	local account = g_settings.get("account")
	local password = g_settings.get("password")
	local clientVersion = g_settings.getInteger("client-version")

	EnterGame.setAccountName(account)
	EnterGame.setPassword(password)

	if Servers_init and table.size(Servers_init) == 1 then
		local hostInit, valuesInit = next(Servers_init)

		EnterGame.setUniqueServer(hostInit, valuesInit.port, valuesInit.protocol)
	end

	updateLabelText()

	local emailEdit = enterGame:getChildById("accountNameTextEdit")
	local passwordEdit = enterGame:getChildById("accountPasswordTextEdit")
	local editsToFix = {
		"accountNameTextEdit",
		"accountPasswordTextEdit"
	}

	for _, editId in ipairs(editsToFix) do
		local editWidget = enterGame:getChildById(editId)

		if editWidget and not editWidget.keyPressEventFixed then
			local originalOnKeyPress = editWidget.onKeyPress

			function editWidget:onKeyPress(keyCode, keyboardModifiers, autoRepeatTicks)
				if keyCode == KeyTab and (self == emailEdit or self == passwordEdit) then
					local target = self == emailEdit and passwordEdit or emailEdit

					if target and not target:isDestroyed() then
						target:focus()
					end

					return true
				end

				local cursorPos = self:getCursorPos()
				local textLen = self:getText():len()

				if keyCode == KeyRight and cursorPos == textLen then
					return true
				end

				if keyCode == KeyLeft and cursorPos == 0 then
					return true
				end

				if originalOnKeyPress then
					return originalOnKeyPress(self, keyCode, keyboardModifiers, autoRepeatTicks)
				end

				return false
			end

			editWidget.keyPressEventFixed = true
		end
	end

	enterGame:hide()
	connect(g_game, {
		onGameStart = EnterGame.hidePanels
	})
	connect(g_game, {
		onGameEnd = EnterGame.showPanels
	})
end

function EnterGame.hidePanels(force)
	if not force and modules.client_background and modules.client_background.isMapTransitionActive and modules.client_background.isMapTransitionActive() then
		return
	end

	if g_modules.getModule("client_bottommenu"):isLoaded() then
		modules.client_bottommenu.hide()
	end

	modules.client_topmenu.hide()
end

function EnterGame.showPanels()
	if g_modules.getModule("client_bottommenu"):isLoaded() then
		modules.client_bottommenu.show()
	end

	modules.client_topmenu.show()
end

function EnterGame.loadStartupData()
	if Services and Services.status and g_modules.getModule("client_bottommenu"):isLoaded() then
		EnterGame.postCacheInfo()
		EnterGame.postEventScheduler()
		EnterGame.postShowCreatureBoost()
	end
end

function EnterGame.firstShow()
	EnterGame.show()
	EnterGame.loadStartupData()
end

function EnterGame.terminate()
	Keybind.delete("Misc.", "Change Character")

	if clientBox then
		disconnect(clientBox, {
			onOptionChange = EnterGame.onClientVersionChange
		})

		clientBox = nil
	end

	disconnect(g_game, {
		onGameStart = EnterGame.hidePanels
	})
	disconnect(g_game, {
		onGameEnd = EnterGame.showPanels
	})

	if enterGame then
		enterGame:destroy()

		enterGame = nil
	end

	if motdWindow then
		motdWindow:destroy()

		motdWindow = nil
	end

	EnterGame.destroyTwoFactorWindow()

	if loadBox then
		loadBox:destroy()

		loadBox = nil
	end

	EnterGame = nil
end

local function reportRequestWarning(requestType, msg, errorCode)
	g_logger.warning(("[Webscraping - %s] %s"):format(requestType, msg), errorCode)
end

function dump(o)
	if type(o) == "table" then
		local s = "{ "

		for k, v in pairs(o) do
			if type(k) ~= "number" then
				k = "\"" .. k .. "\""
			end

			s = s .. "[" .. k .. "] = " .. dump(v) .. ","
		end

		return s .. "} "
	else
		return tostring(o)
	end
end

function EnterGame.postCacheInfo()
	local requestType = "cacheinfo"

	local function onRecvInfo(message, err)
		if err then
			reportRequestWarning(requestType, "Bad Request. Game_entergame postCacheInfo1")

			return
		end

		local jsonString = message:match("{.*}")

		if not jsonString then
			reportRequestWarning(requestType, "Invalid JSON response format")

			return
		end

		local success, response = pcall(function()
			return json.decode(jsonString)
		end)

		if not success or not response then
			reportRequestWarning(requestType, "Failed to parse JSON response")

			return
		end

		if response.errorMessage then
			reportRequestWarning(requestType, response.errorMessage, response.errorCode)

			return
		end

		modules.client_topmenu.setPlayersOnline(response.playersonline)
	end

	HTTP.post(Services.status, json.encode({
		type = requestType
	}), onRecvInfo, false)
end

function EnterGame.postEventScheduler()
	local requestType = "eventschedule"

	local function onRecvInfo(message, err)
		if err then
			reportRequestWarning(requestType, "Bad Request.Game_entergame postEventScheduler1")

			return
		end

		local jsonString = message:match("{.*}")

		if not jsonString then
			reportRequestWarning(requestType, "Invalid JSON response format")

			return
		end

		local success, response = pcall(function()
			return json.decode(jsonString)
		end)

		if not success or not response then
			reportRequestWarning(requestType, "Failed to parse JSON response")

			return
		end

		if response.errorMessage then
			reportRequestWarning(requestType, response.errorMessage, response.errorCode)

			return
		end

		modules.client_bottommenu.setEventsSchedulerTimestamp(response.lastupdatetimestamp)
		modules.client_bottommenu.setEventsSchedulerCalender(response.eventlist)
	end

	HTTP.post(Services.status, json.encode({
		type = requestType
	}), onRecvInfo, false)
end

function EnterGame.postShowOff()
	local requestType = "showoff"

	local function onRecvInfo(message, err)
		if err then
			reportRequestWarning(requestType, "Bad Request.Game_entergame postShowOff")

			return
		end

		local jsonString = message:match("{.*}")

		if not jsonString then
			reportRequestWarning(requestType, "Invalid JSON response format")

			return
		end

		local success, response = pcall(function()
			return json.decode(jsonString)
		end)

		if not success or not response then
			reportRequestWarning(requestType, "Failed to parse JSON response")

			return
		end

		if response.errorMessage then
			reportRequestWarning(requestType, response.errorMessage, response.errorCode)

			return
		end

		modules.client_bottommenu.setShowOffData(response)
	end

	HTTP.post(Services.status, json.encode({
		type = requestType
	}), onRecvInfo, false)
end

function EnterGame.postShowCreatureBoost()
	local requestType = "boostedcreature"

	local function onRecvInfo(message, err)
		if err then
			reportRequestWarning(requestType, "Bad Request.Game_entergame postShowCreatureBoost1")

			return
		end

		local jsonString = message:match("{.*}")

		if not jsonString then
			reportRequestWarning(requestType, "Invalid JSON response format")

			return
		end

		local success, response = pcall(function()
			return json.decode(jsonString)
		end)

		if not success or not response then
			reportRequestWarning(requestType, "Failed to parse JSON response")

			return
		end

		if response.errorMessage then
			reportRequestWarning(requestType, response.errorMessage, response.errorCode)

			return
		end

		modules.client_bottommenu.setBoostedCreatureAndBoss(response)
	end

	HTTP.post(Services.status, json.encode({
		type = requestType
	}), onRecvInfo, false)
end

function EnterGame.show()
	if g_game.isOnline() or CharacterList.isVisible() then
		return
	end

	if loadBox then
		return
	end

	local background = modules.client_background.getBackground()

	-- serverLogo (the ported client logo) removed from background.otui at the user's request - the guard
	-- stays in case our own logo returns in this spot
	if background and background.serverLogo then
		background.serverLogo:show()
	end

	-- Fade the window in (appear effect on launch and whenever we return to the login screen).
	-- Hiding stays synchronous so the login<->character-list transitions (e.g. ESC) are not blocked
	-- by a window that is still "visible" mid-fade.
	enterGame:show()
	enterGame:raise()
	enterGame:focus()
	g_effects.fadeIn(enterGame, 300)
end

function EnterGame.hide()
	g_effects.cancelFade(enterGame)
	enterGame:hide()
	enterGame:setOpacity(1)

	local background = modules.client_background.getBackground()

	if background and background.serverLogo then
		background.serverLogo:hide()
	end
end

function EnterGame.openWindow()
	if g_game.isOnline() then
		CharacterList.show()
	elseif not g_game.isLogging() and not CharacterList.isVisible() then
		EnterGame.show()
	end
end

function EnterGame.setAccountName(account)
	local account = g_crypt.decrypt(account)

	enterGame:getChildById("accountNameTextEdit"):setText(account)
	enterGame:getChildById("accountNameTextEdit"):setCursorPos(-1)
	enterGame:getChildById("rememberEmailBox"):setChecked(#account > 0)
end

function EnterGame.setPassword(password)
	local password = g_crypt.decrypt(password)

	enterGame:getChildById("accountPasswordTextEdit"):setText(password)
	enterGame:getChildById("rememberPasswordBox"):setChecked(#password > 0)
end

function EnterGame.clearAccountFields()
	enterGame:getChildById("accountNameTextEdit"):clearText()
	enterGame:getChildById("accountPasswordTextEdit"):clearText()
	enterGame:getChildById("accountNameTextEdit"):focus()
	g_settings.remove("account")
	g_settings.remove("password")
end

function EnterGame.clearPasswordNameFields()
	enterGame:getChildById("accountPasswordTextEdit"):clearText()
	enterGame:getChildById("accountNameTextEdit"):focus()
	g_settings.remove("password")
end

function EnterGame.clearAccountNameFields()
	enterGame:getChildById("accountNameTextEdit"):clearText()
	enterGame:getChildById("accountNameTextEdit"):focus()
	g_settings.remove("account")
end

function EnterGame.onClientVersionChange(comboBox, text, data)
	updateLabelText()
end

function EnterGame.tryHttpLogin(clientVersion, httpLogin, token)
	G.pendingClientVersion = clientVersion
	G.pendingHttpLogin = httpLogin

	g_game.setClientVersion(clientVersion)
	g_game.setProtocolVersion(g_game.getClientProtocolVersion(clientVersion))
	g_game.chooseRsa(G.host)

	if not modules.game_things.isLoaded() then
		if loadBox then
			loadBox:destroy()

			loadBox = nil
		end

		local errorBox = displayErrorBox(tr("Sorry"), "Things are not loaded, please put assets in things/assets/.")

		connect(errorBox, {
			onOk = EnterGame.show
		})

		return
	end

	local scheme, authority, path = G.host:match("^(https?)://([^/]+)(/.*)$")
	if not authority then
		authority, path = G.host:match("^([^/]+)(/.*)$")
	end

	scheme = scheme or ((G.port == 443) and "https" or "http")
	local host, urlPort = authority and authority:match("^([^:]+):(%d+)$")
	host = host or authority
	G.port = tonumber(urlPort) or G.port or (scheme == "https" and 443 or 80)
	path = path or ""
	G.loginHost = host
	G.loginPath = path
	G.loginScheme = scheme

	if not host then
		loadBox = displayCancelBox(tr("Please wait"), tr("ERROR , try adding \n- ip/login.php \n- Enable HTTP login"))
	else
		loadBox = displayCancelBox(tr("Connecting"), tr("Your character list is being loaded. Please wait."))
	end

	connect(loadBox, {
		onCancel = function(msgbox)
			if G.httpOperationId then
				HTTP.cancel(G.httpOperationId)

				G.httpOperationId = nil
			end

			loadBox = nil
			G.requestId = 0

			EnterGame.show()
		end
	})
	math.randomseed(os.time())

	G.requestId = math.random(1)

	sendHttpLoginRequest(httpLogin, token or "", G.loginScheme, G.port)
end

function EnterGame.destroyTwoFactorWindow()
	if twoFactorWindow then
		twoFactorWindow:destroy()

		twoFactorWindow = nil
	end
end

function EnterGame.showTwoFactorWindow()
	EnterGame.destroyTwoFactorWindow()

	twoFactorWindow = g_ui.displayUI("twofactor")

	local tokenTextEdit = twoFactorWindow:getChildById("tokenTextEdit")

	tokenTextEdit:clearText()
	tokenTextEdit:focus()
end

function EnterGame.submitTwoFactor()
	if not twoFactorWindow then
		return
	end

	local token = twoFactorWindow:getChildById("tokenTextEdit"):getText()

	if token:len() == 0 then
		return
	end

	G.authenticatorToken = token

	EnterGame.destroyTwoFactorWindow()
	EnterGame.tryHttpLogin(G.pendingClientVersion, G.pendingHttpLogin, token)
end

function EnterGame.cancelTwoFactor()
	EnterGame.destroyTwoFactorWindow()
	EnterGame.show()
end

function EnterGame.handleHttpLoginResponse(data, err, requestId)
	if G.requestId ~= requestId then
		return
	end

	if loadBox then
		loadBox:destroy()

		loadBox = nil
	end

	G.httpOperationId = nil

	if err then
		onError(nil, err, nil)

		return
	end

	if not data then
		onError(nil, tr("Unexpected JSON format."), nil)

		return
	end

	if data.errorCode == 6 then
		EnterGame.showTwoFactorWindow()

		return
	end

	if data.errorMessage then
		onError(nil, data.errorMessage, data.errorCode)

		return
	end

	if not data.session then
		onError(nil, tr("No session data"), nil)

		return
	end

	EnterGame.destroyTwoFactorWindow()

	local characters = {}
	local worlds = {}

	if data.playdata then
		characters = data.playdata.characters or {}
		worlds = data.playdata.worlds or {}
	end

	EnterGame.loginSuccess(requestId, json.encode(data.session), json.encode(worlds), json.encode(characters))
end

function printTable(t)
	for k, v in pairs(t) do
		if type(v) == "table" then
			print(string.format("%q: {", k))
			printTable(v)
			print("}")
		else
			print(string.format("%q:", k) .. tostring(v) .. ",")
		end
	end
end

function EnterGame.loginSuccess(requestId, jsonSession, jsonWorlds, jsonCharacters)
	if G.requestId ~= requestId then
		return
	end

	EnterGame.destroyTwoFactorWindow()

	local worlds = {}

	for _, world in ipairs(json.decode(jsonWorlds)) do
		if world.id then
			worlds[world.id] = {
				name = world.name,
				ip = world.externaladdressprotected,
				port = world.externalportprotected,
				previewState = world.previewstate == 1,
				pvptype = world.pvptype
			}
		end
	end

	local characters = {}

	for index, character in ipairs(json.decode(jsonCharacters)) do
		local world = worlds[character.worldid]

		characters[index] = {
			name = character.name,
			level = character.level,
			main = character.ismaincharacter,
			dailyreward = character.dailyrewardstate,
			hidden = character.ishidden,
			vocation = character.vocation,
			outfitid = character.outfitid,
			headcolor = character.headcolor,
			torsocolor = character.torsocolor,
			legscolor = character.legscolor,
			detailcolor = character.detailcolor,
			addonsflags = character.addonsflags,
			worldName = world.name,
			worldIp = world.ip,
			worldPort = world.port,
			previewState = world.previewstate,
			worldPvpType = world.pvptype
		}
	end

	local session = json.decode(jsonSession)
	local premiumUntil = tonumber(session.premiumuntil)
	local account = {
		status = "",
		premDays = math.floor((premiumUntil - os.time()) / 86400),
		subStatus = premiumUntil > os.time() and SubscriptionStatus.Premium or SubscriptionStatus.Free,
		recoverySetupComplete = session.recoverysetupcomplete
	}

	G.sessionKey = session.sessionkey

	onCharacterList(nil, characters, account)
end

function EnterGame.loginFailed(requestId, msg, result)
	if G.requestId ~= requestId then
		return
	end

	onError(nil, msg, result)
end

function EnterGame.doLogin()
	G.account = enterGame:getChildById("accountNameTextEdit"):getText()
	G.password = enterGame:getChildById("accountPasswordTextEdit"):getText()
	G.authenticatorToken = ""

	local hostInit, valuesInit = next(Servers_init)

	G.host = hostInit
	G.port = valuesInit.port

	local clientVersion = tonumber(valuesInit.protocol)
	local httpLogin = valuesInit.httpLogin

	EnterGame.hide()

	if g_game.isOnline() then
		local errorBox = displayErrorBox(tr("Sorry"), tr("Cannot login while already in game."))

		connect(errorBox, {
			onOk = EnterGame.show
		})

		return
	end

	g_settings.set("host", G.host)
	g_settings.set("port", G.port)
	g_settings.set("client-version", clientVersion)
	EnterGame.tryHttpLogin(clientVersion, httpLogin)
end

function EnterGame.displayMotd()
	if not motdWindow then
		motdWindow = displayInfoBox(tr("Message of the day"), G.motdMessage)

		function motdWindow.onOk()
			motdWindow = nil
		end
	end
end

function EnterGame.setDefaultServer(host, port, protocol)
	local hostTextEdit = enterGame:getChildById("serverHostTextEdit")
	local portTextEdit = enterGame:getChildById("serverPortTextEdit")
	local clientLabel = enterGame:getChildById("clientLabel")
	local accountTextEdit = enterGame:getChildById("accountNameTextEdit")
	local passwordTextEdit = enterGame:getChildById("accountPasswordTextEdit")

	if hostTextEdit:getText() ~= host then
		hostTextEdit:setText(host)
		portTextEdit:setText(port)
		clientBox:setCurrentOption(protocol)
		accountTextEdit:setText("")
		passwordTextEdit:setText("")
	end
end

function EnterGame.setUniqueServer(host, port, protocol, windowWidth, windowHeight)
	local clientVersion = tonumber(protocol)
	local rememberEmailBox = enterGame:getChildById("rememberEmailBox")

	windowWidth = windowWidth or 280

	enterGame:setWidth(windowWidth)

	windowHeight = windowHeight or 198

	enterGame:setHeight(windowHeight)
	g_game.setClientVersion(clientVersion)
	g_game.setProtocolVersion(g_game.getClientProtocolVersion(clientVersion))
end

function EnterGame.setServerInfo(message)
	local label = enterGame:getChildById("serverInfoLabel")

	label:setText(message)
end

function EnterGame.disableMotd()
	motdEnabled = false
end

function ensableBtnCreateNewAccount()
	enterGame.btnCreateNewAccount:enable()
end
