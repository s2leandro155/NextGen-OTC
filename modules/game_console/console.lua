-- chunkname: @/game_console/console.lua

SpeakTypesSettings = {
	none = {},
	say = {
		color = "#F0F000",
		speakType = MessageModes.Say
	},
	whisper = {
		color = "#F0F000",
		speakType = MessageModes.Whisper
	},
	yell = {
		color = "#F0F000",
		speakType = MessageModes.Yell
	},
	broadcast = {
		color = "#F86060",
		speakType = MessageModes.GamemasterBroadcast
	},
	private = {
		color = "#60F8F8",
		private = true,
		speakType = MessageModes.PrivateTo
	},
	privateRed = {
		color = "#F86060",
		private = true,
		speakType = MessageModes.GamemasterTo
	},
	privatePlayerToPlayer = {
		color = "#A0A0FF",
		private = true,
		speakType = MessageModes.PrivateTo
	},
	privatePlayerToNpc = {
		color = "#A0A0FF",
		private = true,
		npcChat = true,
		speakType = MessageModes.NpcTo
	},
	privateNpcToPlayer = {
		color = "#60F8F8",
		private = true,
		npcChat = true,
		speakType = MessageModes.NpcFrom
	},
	channelYellow = {
		color = "#F0F000",
		speakType = MessageModes.Channel
	},
	channelWhite = {
		color = "#FFFFFF",
		speakType = MessageModes.ChannelManagement
	},
	channelRed = {
		color = "#F86060",
		speakType = MessageModes.GamemasterChannel
	},
	channelOrange = {
		color = "#F0B400",
		speakType = MessageModes.ChannelHighlight
	},
	spell = {
		color = "#F0F000",
		speakType = MessageModes.Spell
	},
	monsterSay = {
		color = "#FF6600",
		hideInConsole = true,
		speakType = MessageModes.MonsterSay
	},
	monsterYell = {
		color = "#FF6600",
		hideInConsole = true,
		speakType = MessageModes.MonsterYell
	},
	rvrAnswerFrom = {
		color = "#FF6600",
		speakType = MessageModes.RVRAnswer
	},
	rvrAnswerTo = {
		color = "#FF6600",
		speakType = MessageModes.RVRAnswer
	},
	rvrContinue = {
		color = "#F0F000",
		speakType = MessageModes.RVRContinue
	}
}
SpeakTypes = {
	[MessageModes.Say] = SpeakTypesSettings.say,
	[MessageModes.Whisper] = SpeakTypesSettings.whisper,
	[MessageModes.Yell] = SpeakTypesSettings.yell,
	[MessageModes.GamemasterBroadcast] = SpeakTypesSettings.broadcast,
	[MessageModes.PrivateTo] = SpeakTypesSettings.private,
	[MessageModes.PrivateFrom] = SpeakTypesSettings.private,
	[MessageModes.GamemasterPrivateFrom] = SpeakTypesSettings.privateRed,
	[MessageModes.NpcTo] = SpeakTypesSettings.privatePlayerToNpc,
	[MessageModes.NpcFrom] = SpeakTypesSettings.privateNpcToPlayer,
	[MessageModes.Channel] = SpeakTypesSettings.channelYellow,
	[MessageModes.ChannelManagement] = SpeakTypesSettings.channelWhite,
	[MessageModes.GamemasterChannel] = SpeakTypesSettings.channelRed,
	[MessageModes.ChannelHighlight] = SpeakTypesSettings.channelOrange,
	[MessageModes.MonsterSay] = SpeakTypesSettings.monsterSay,
	[MessageModes.MonsterYell] = SpeakTypesSettings.monsterYell,
	[MessageModes.RVRChannel] = SpeakTypesSettings.channelWhite,
	[MessageModes.RVRContinue] = SpeakTypesSettings.rvrContinue,
	[MessageModes.RVRAnswer] = SpeakTypesSettings.rvrAnswerFrom,
	[MessageModes.NpcFromStartBlock] = SpeakTypesSettings.privateNpcToPlayer,
	[MessageModes.Spell] = SpeakTypesSettings.spell,
	[MessageModes.BarkLow] = SpeakTypesSettings.none,
	[MessageModes.BarkLoud] = SpeakTypesSettings.none,
	[MessageModes.Potion] = SpeakTypesSettings.none
}
SayModes = {
	{
		clipPressed = "16 32 16 16",
		clip = "0 32 16 16",
		speakTypeDesc = "whisper"
	},
	{
		clipPressed = "16 0 16 16",
		clip = "0 0 16 16",
		speakTypeDesc = "say"
	},
	{
		clipPressed = "16 16 16 16",
		clip = "0 16 16 16",
		speakTypeDesc = "yell"
	}
}

local function updateSayModeButtonClip(button, pressed)
	if not button then
		return
	end

	local idx = tonumber(button.sayMode)

	if not idx or idx < 1 then
		idx = 2
	end

	local mode = SayModes[idx]

	if not mode then
		return
	end

	button:setImageClip(pressed and mode.clipPressed or mode.clip)
end

local function updateSayModeButtonVisibility(tab)
	if not consolePanel then
		return
	end

	local btn = consolePanel:getChildById("sayModeButton")

	if not btn then
		return
	end

	if tab and (tab == defaultTab or tab == serverTab) then
		btn:show()
	else
		btn:hide()
	end
end

ChannelEventFormats = {
	[ChannelEvent.Join] = "%s joined the channel.",
	[ChannelEvent.Leave] = "%s left the channel.",
	[ChannelEvent.Invite] = "%s has been invited to the channel.",
	[ChannelEvent.Exclude] = "%s has been removed from the channel."
}
MAX_HISTORY = 500
MAX_LINES = 100
HELP_CHANNEL = 7
LOOT_CHANNEL = 9
CHANNEL_GUILD = 0
CHANNEL_PARTY = 1
CHANNEL_GUILD_LEADER = 10000
TEXT_MESSAGE_NO_CHANNEL = 65535

local channelTextMessageModes = {
	MessageModes.Guild,
	MessageModes.Party,
	MessageModes.PartyManagement,
	MessageModes.ChannelManagement
}

ClientOpenChannelNpcId = 65534
consolePanel = nil
consoleContentPanel = nil

local extendedViewButtonToggleChat, extendedViewButtonShowAlphaChat, gameBottomPanel

consoleTabBar = nil
consoleTextEdit = nil

local npcModalTextEditDocked = false
local npcModalRestoreWasdAfterClose = false

consoleToggleChat = nil
channels = nil
channelsWindow = nil
communicationWindow = nil
ownPrivateName = nil
messageHistory = {}
currentMessageIndex = 0
ignoreNpcMessages = false
defaultTab = nil
serverTab = nil
violationsChannelId = nil
violationWindow = nil
violationReportTab = nil
ignoredChannels = {}
mutedChannels = {}
filters = {}

local readOnlyButton, readOnlyPanel
local activeactiveReadOnlyTabName = ""
local readOnlyModeEnabled = false
local temporaryChatViaEnter = false
local npcModalProxyKeyDownSlot, isNpcModalVisible

local function syncToggleChatToTypingButton()
	consoleToggleChat.isChecked = false

	consoleToggleChat:setText(tr("Chat On"))
end

local function syncToggleChatToWASDButton()
	consoleToggleChat.isChecked = true

	consoleToggleChat:setText(tr("Chat Off"))
end

local function syncNpcToggleChatButton(wasdMode)
	local npcModal = modules.game_npcmodal and modules.game_npcmodal.mainNpcModal

	if not npcModal then
		return
	end

	local npcToggleBtn = npcModal:recursiveGetChildById("toggleChat")

	if not npcToggleBtn then
		return
	end

	npcToggleBtn.isChecked = wasdMode

	npcToggleBtn:setText(wasdMode and tr("Chat Off") or tr("Chat On"))
end

function setChatModeOn()
	if not g_game.isOnline() or HotkeyUtils.areHotkeysDisabled() then
		return
	end

	if not consoleToggleChat or not consoleTextEdit then
		return
	end

	temporaryChatViaEnter = false

	syncToggleChatToTypingButton()
	syncNpcToggleChatButton(false)
	switchChat(true)
end

function setChatModeOff()
	if not g_game.isOnline() or HotkeyUtils.areHotkeysDisabled() then
		return
	end

	if not consoleToggleChat or not consoleTextEdit then
		return
	end

	temporaryChatViaEnter = false

	syncToggleChatToWASDButton()
	syncNpcToggleChatButton(true)
	switchChat(false)
end

local communicationSettings = {
	allowVIPs = false,
	yelling = false,
	privateMessages = false,
	useWhiteList = true,
	useIgnoreList = true,
	ignoredPlayers = {},
	whitelistedPlayers = {}
}

local function getTabChannelName(tab)
	if not tab then
		return nil
	end

	return tab.fullName or tab:getText()
end

local function findTabByName(name)
	if not name or not consoleTabBar then
		return nil
	end

	local tab = consoleTabBar:getTab(name)

	if tab then
		return tab
	end

	local function checkTabs(tabs)
		if not tabs then
			return nil
		end

		for _, currentTab in pairs(tabs) do
			if currentTab.fullName and currentTab.fullName:lower() == name:lower() then
				return currentTab
			end
		end
	end

	return checkTabs(consoleTabBar.tabs) or checkTabs(consoleTabBar.preTabs) or checkTabs(consoleTabBar.postTabs)
end

function init()
	connect(g_game, {
		onTalk = onTalk,
		onChannelList = onChannelList,
		onOpenChannel = onOpenChannel,
		onOpenPrivateChannel = onOpenPrivateChannel,
		onOpenOwnPrivateChannel = onOpenOwnPrivateChannel,
		onCloseChannel = onCloseChannel,
		onRuleViolationChannel = onRuleViolationChannel,
		onRuleViolationRemove = onRuleViolationRemove,
		onRuleViolationCancel = onRuleViolationCancel,
		onRuleViolationLock = onRuleViolationLock,
		onGameStart = online,
		onGameEnd = offline,
		onChannelEvent = onChannelEvent
	})

	gameBottomPanel = modules.game_interface.getBottomPanel()
	consolePanel = g_ui.loadUI("console", gameBottomPanel)
	consoleTextEdit = consolePanel:getChildById("consoleTextEdit")

	connect(consoleTextEdit, {
		onKeyDown = function(widget, keyCode, keyboardModifiers)
			if g_keyboard.isEnterKey(keyCode) and keyboardModifiers == KeyboardNoModifier then
				switchChatOnCall()

				return true
			end

			return false
		end
	})

	consoleContentPanel = consolePanel:getChildById("consoleContentPanel")
	consoleTabBar = consolePanel:getChildById("consoleTabBar")

	consoleTabBar:setContentWidget(consoleContentPanel)

	channels = {}
	readOnlyPanel = consolePanel:getChildById("readOnlyPanel")

	readOnlyPanel:hide()
	consoleContentPanel:removeAnchor(AnchorRight)
	consoleContentPanel:addAnchor(AnchorRight, "parent", AnchorRight)

	consolePanel.onDragEnter = onDragEnter
	consolePanel.onDragLeave = onDragLeave
	consolePanel.onDragMove = onDragMove
	consoleTabBar.onDragEnter = onDragEnter
	consoleTabBar.onDragLeave = onDragLeave
	consoleTabBar.onDragMove = onDragMove

	function consolePanel:onKeyPress(keyCode, keyboardModifiers)
		if keyboardModifiers ~= KeyboardCtrlModifier or keyCode ~= KeyC then
			return false
		end

		local tab = consoleTabBar:getCurrentTab()

		if not tab then
			return false
		end

		local selection = tab.tabPanel:getChildById("consoleBuffer").selectionText

		if not selection then
			return false
		end

		g_window.setClipboardText(selection)

		return true
	end

	g_keyboard.bindKeyPress("Shift+Up", function()
		navigateMessageHistory(1)
	end, consolePanel)
	g_keyboard.bindKeyPress("Shift+Down", function()
		navigateMessageHistory(-1)
	end, consolePanel)
	g_keyboard.bindKeyDown("Escape", disableChatOnCall, consolePanel)
	g_keyboard.bindKeyPress("Ctrl+A", function()
		consoleTextEdit:clearText()
	end, consolePanel)
	consoleTabBar:setNavigation(consolePanel:getChildById("prevChannelButton"), consolePanel:getChildById("nextChannelButton"))

	consoleTabBar.onTabChange = onTabChange

	local sayModeBtn = consolePanel:getChildById("sayModeButton")

	if sayModeBtn then
		function sayModeBtn:onMousePress(mousePos, mouseButton)
			if mouseButton ~= MouseLeftButton then
				return false
			end

			updateSayModeButtonClip(self, true)

			return false
		end

		function sayModeBtn:onMouseRelease(mousePos, mouseButton)
			if mouseButton ~= MouseLeftButton then
				return false
			end

			updateSayModeButtonClip(self, false)

			return UIButton.onMouseRelease(self, mousePos, mouseButton)
		end

		updateSayModeButtonVisibility(nil)
	end

	local gameRootPanel = modules.game_interface.getRootPanel()

	Keybind.new("Chat Channel", "Next Channel", "Tab", "")
	Keybind.bind("Chat Channel", "Next Channel", {
		{
			type = KEY_PRESS,
			callback = function()
				consoleTabBar:selectNextTab()
			end
		}
	}, consolePanel)
	Keybind.new("Chat Channel", "Previous Channel", "Shift+Tab", "")
	Keybind.bind("Chat Channel", "Previous Channel", {
		{
			type = KEY_PRESS,
			callback = function()
				consoleTabBar:selectPrevTab()
			end
		}
	}, consolePanel)
	Keybind.new("Chat", "Send current chat line", {
		[CHAT_MODE.ON] = "Enter",
		[CHAT_MODE.OFF] = "Enter"
	}, "")
	Keybind.bind("Chat", "Send current chat line", {
		{
			type = KEY_DOWN,
			callback = switchChatOnCall
		}
	}, consolePanel)
	Keybind.new("Chat Channel", "Open Channel List", "Ctrl+O", "")
	Keybind.bind("Chat Channel", "Open Channel List", {
		{
			type = KEY_DOWN,
			callback = g_game.requestChannels
		}
	}, gameRootPanel)
	Keybind.new("Chat Channel", "Close Current Channel", "Ctrl+E", "")
	Keybind.bind("Chat Channel", "Close Current Channel", {
		{
			type = KEY_DOWN,
			callback = removeCurrentTab
		}
	}, gameRootPanel)
	Keybind.new("Chat Channel", "Open Help Channel", "Ctrl+H", "")
	Keybind.bind("Chat Channel", "Open Help Channel", {
		{
			type = KEY_DOWN,
			callback = openHelp
		}
	}, consolePanel)
	Keybind.new("Chat Mode", "Set to Chat On", "", "")
	Keybind.bind("Chat Mode", "Set to Chat On", {
		{
			type = KEY_DOWN,
			callback = setChatModeOn
		}
	}, gameRootPanel)
	Keybind.new("Chat Mode", "Set to Chat Off", "", "")
	Keybind.bind("Chat Mode", "Set to Chat Off", {
		{
			type = KEY_DOWN,
			callback = setChatModeOff
		}
	}, gameRootPanel)

	consoleToggleChat = consolePanel:getChildById("toggleChat")
	readOnlyButton = consolePanel:getChildById("readOnlyButton")
	readOnlyPanel = consolePanel:getChildById("readOnlyPanel")

	function readOnlyButton.onMousePress(tab, mousePos, mouseButton)
		if mouseButton == MouseRightButton then
			onReadOnlyMouseClick()

			return true
		end
	end

	consoleTabBar:setDropTarget(readOnlyButton, function(target, draggedWidget)
		activateReadOnlyMode(getTabChannelName(draggedWidget))
	end)
	load()

	if g_game.isOnline() then
		online()
	end

	for _, mode in ipairs(channelTextMessageModes) do
		registerMessageMode(mode, onChannelTextMessage)
	end
end

function clearSelection(consoleBuffer)
	for _, label in pairs(consoleBuffer:getChildren()) do
		label:clearSelection()
	end

	consoleBuffer.selectionText = nil
	consoleBuffer.selection = nil
end

function selectAll(consoleBuffer)
	clearSelection(consoleBuffer)

	if consoleBuffer:getChildCount() > 0 then
		local text = {}

		for _, label in pairs(consoleBuffer:getChildren()) do
			label:selectAll()
			table.insert(text, label:getSelection())
		end

		consoleBuffer.selectionText = table.concat(text, "\n")
		consoleBuffer.selection = {
			first = consoleBuffer:getChildIndex(consoleBuffer:getFirstChild()),
			last = consoleBuffer:getChildIndex(consoleBuffer:getLastChild())
		}
	end
end

function toggleChat()
	temporaryChatViaEnter = false
	consoleToggleChat.isChecked = not consoleToggleChat.isChecked

	if consoleToggleChat.isChecked then
		consoleToggleChat:setText(tr("Chat Off"))
	else
		consoleToggleChat:setText(tr("Chat On"))
	end

	syncNpcToggleChatButton(consoleToggleChat.isChecked)
	updateChatMode()
end

function updateChatMode()
	temporaryChatViaEnter = false

	switchChat(not consoleToggleChat.isChecked)
end

local function unbindMovingKeys()
	local gameWalk = modules.game_walk

	gameWalk.unbindWalkKey("W")
	gameWalk.unbindWalkKey("D")
	gameWalk.unbindWalkKey("S")
	gameWalk.unbindWalkKey("A")
	gameWalk.unbindWalkKey("E")
	gameWalk.unbindWalkKey("Q")
	gameWalk.unbindWalkKey("C")
	gameWalk.unbindWalkKey("Z")

	if gameWalk.syncWasdTurnKeyLayout then
		gameWalk.syncWasdTurnKeyLayout(false)
	end
end

local function bindMovingKeys()
	local gameWalk = modules.game_walk
	local keyDirs = gameWalk.getWasdMovementKeyDirs and gameWalk.getWasdMovementKeyDirs() or {
		{
			"W",
			North
		},
		{
			"D",
			East
		},
		{
			"S",
			South
		},
		{
			"A",
			West
		},
		{
			"E",
			NorthEast
		},
		{
			"Q",
			NorthWest
		},
		{
			"C",
			SouthEast
		},
		{
			"Z",
			SouthWest
		}
	}

	for _, keyDir in ipairs(keyDirs) do
		if not gameWalk.isMovementKeyBlockedByHotkey or not gameWalk.isMovementKeyBlockedByHotkey(keyDir[1]) then
			gameWalk.bindWalkKey(keyDir[1], keyDir[2])
		end
	end

	if gameWalk.syncWasdTurnKeyLayout then
		gameWalk.syncWasdTurnKeyLayout(true)
	end
end

function syncMovingKeys()
	if isChatEnabled() then
		return
	end

	unbindMovingKeys()
	bindMovingKeys()
end

local function getNpcModalChatProxy()
	if not modules.game_npcmodal or not modules.game_npcmodal.mainNpcModal then
		return nil
	end

	local w = modules.game_npcmodal.mainNpcModal

	if w:isDestroyed() then
		return nil
	end

	return w:recursiveGetChildById("npcModalChatProxy")
end

local function isNpcModalChatActive()
	if not npcModalTextEditDocked then
		return false
	end

	local npcModal = modules.game_npcmodal and modules.game_npcmodal.mainNpcModal

	return npcModal and not npcModal:isDestroyed() and npcModal:isVisible()
end

local function getActiveChatInputForEdit()
	if isNpcModalChatActive() then
		local proxy = getNpcModalChatProxy()

		if proxy and not proxy:isDestroyed() then
			return proxy
		end
	end

	return consoleTextEdit
end

local function syncChatInputPlaceholder(input)
	if not input or input:isDestroyed() then
		return
	end

	if input == consoleTextEdit then
		local ph = consolePanel and consolePanel:getChildById("placeholderLabel")

		if ph then
			ph:setVisible(input:getText():len() == 0)
		end

		return
	end

	local npcModal = modules.game_npcmodal and modules.game_npcmodal.mainNpcModal

	if npcModal and not npcModal:isDestroyed() then
		local ph = npcModal:getChildById("placeholderLabel")

		if ph then
			ph:setVisible(input:getText():len() == 0)
		end
	end
end

local function setTextEditTextOnInput(input, text)
	if not input or input:isDestroyed() then
		return
	end

	if text and #text > 0 then
		input:setText(text)
	else
		input:clearText()
	end

	input:setCursorPos(-1)
	syncChatInputPlaceholder(input)
end

local function focusActiveChatInput()
	local input = getActiveChatInputForEdit()

	if not input or input:isDestroyed() then
		return
	end

	if input:isFocusable() and input:isEditable() then
		input:focus()
	end
end

local function applyNpcModalProxyEditability()
	if not npcModalTextEditDocked then
		return
	end

	local proxy = getNpcModalChatProxy()

	if not proxy or not consoleTextEdit then
		return
	end

	proxy:setVisible(true)
	proxy:setEditable(consoleTextEdit:isEditable())
	proxy:setFocusable(consoleTextEdit:isFocusable())
	proxy:setCursorVisible(consoleTextEdit:isCursorVisible())
	proxy:setColor(consoleTextEdit:getColor())
end

function switchChat(enabled)
	if not enabled then
		temporaryChatViaEnter = false
	end

	if enabled and modules.game_walk and modules.game_walk.cancelWalkInput then
		modules.game_walk.cancelWalkInput()
	end

	consoleTextEdit:setVisible(true)

	if consoleTextEdit:isEditable() ~= enabled then
		consoleTextEdit:setEditable(enabled)
		consoleTextEdit:setFocusable(enabled)

		if not enabled then
			consoleTextEdit:setText("")
			consoleTextEdit:setCursorPos(-1)

			if consoleTextEdit:isFocused() then
				modules.game_interface.getRootPanel():focus()
			end
		end
	elseif not enabled and consoleTextEdit:getText() ~= "" then
		consoleTextEdit:setText("")
		consoleTextEdit:setCursorPos(-1)
	end

	consoleTextEdit:setCursorVisible(enabled)

	if enabled then
		unbindMovingKeys()
		consoleToggleChat:setTooltip(tr("Disable chat mode, allow to walk using WASD"))
		Keybind.setChatMode(CHAT_MODE.ON)
	else
		bindMovingKeys()
		consoleToggleChat:setTooltip(tr("Enable chat mode"))
		Keybind.setChatMode(CHAT_MODE.OFF)
	end

	if npcModalTextEditDocked then
		local proxy = getNpcModalChatProxy()

		if proxy and not enabled and proxy:isFocused() then
			modules.game_interface.getRootPanel():focus()
		end

		applyNpcModalProxyEditability()
	end

	if modules.game_actionbar and modules.game_actionbar.setupHotkeys then
		modules.game_actionbar.setupHotkeys()
	end
end

function isChatEnabled()
	return consoleTextEdit and consoleTextEdit:isEditable()
end

local function getChatInputForSend()
	if isNpcModalChatActive() then
		local proxy = getNpcModalChatProxy()

		if proxy and not proxy:isDestroyed() then
			return proxy
		end
	end

	return consoleTextEdit
end

local function healConsoleTextEditIfLeftOnNpcModal()
	if not consoleTextEdit or not consolePanel or consoleTextEdit:isDestroyed() or consolePanel:isDestroyed() then
		return
	end

	if consoleTextEdit:getParent() == consolePanel then
		return
	end

	npcModalTextEditDocked = false

	consoleTextEdit:removeAnchor(AnchorLeft)
	consoleTextEdit:removeAnchor(AnchorRight)
	consoleTextEdit:removeAnchor(AnchorTop)
	consoleTextEdit:removeAnchor(AnchorBottom)
	consoleTextEdit:setParent(consolePanel)
	consoleTextEdit:addAnchor(AnchorLeft, "sayModeButton", AnchorRight)
	consoleTextEdit:addAnchor(AnchorRight, "toggleChat", AnchorLeft)
	consoleTextEdit:addAnchor(AnchorBottom, "parent", AnchorBottom)
	consoleTextEdit:setMarginRight(2)
	consoleTextEdit:setMarginLeft(3)
	consoleTextEdit:setMarginBottom(4)
end

local function disconnectNpcModalProxy(proxy)
	if not proxy then
		return
	end

	if npcModalProxyKeyDownSlot then
		disconnect(proxy, {
			onKeyDown = npcModalProxyKeyDownSlot
		})
	end

	npcModalProxyKeyDownSlot = nil
end

local function wireNpcModalProxy(proxy)
	disconnectNpcModalProxy(proxy)

	function npcModalProxyKeyDownSlot(widget, keyCode, keyboardModifiers)
		if not npcModalTextEditDocked then
			return false
		end

		if keyboardModifiers == KeyboardShiftModifier and keyCode == KeyUp then
			navigateMessageHistory(1)

			return true
		end

		if keyboardModifiers == KeyboardShiftModifier and keyCode == KeyDown then
			navigateMessageHistory(-1)

			return true
		end

		if keyboardModifiers == KeyboardNoModifier and keyCode == KeyEscape and modules.game_npcmodal and modules.game_npcmodal.closeNpcModal then
			modules.game_npcmodal.closeNpcModal()

			return true
		end

		if g_keyboard.isEnterKey(keyCode) and keyboardModifiers == KeyboardNoModifier then
			switchChatOnCall()

			return true
		end

		return false
	end

	connect(proxy, {
		onKeyDown = npcModalProxyKeyDownSlot
	})
end

local function wireNpcModalKeyboard(npcModalWindow)
	if not npcModalWindow or npcModalWindow.npcModalKeyPressWired then
		return
	end

	npcModalWindow.npcModalKeyPressWired = true

	function npcModalWindow:onKeyPress(keyCode, keyboardModifiers)
		if keyboardModifiers == KeyboardCtrlModifier and keyCode == KeyC then
			local itemsPanel = self:recursiveGetChildById("itemsPanel")

			if itemsPanel and itemsPanel.selectionText and #itemsPanel.selectionText > 0 then
				g_window.setClipboardText(itemsPanel.selectionText)

				return true
			end
		end

		return false
	end
end

function switchChatOnCall()
	if not g_game.isOnline() or HotkeyUtils.areHotkeysDisabled() then
		return
	end

	if not consoleTextEdit:isEditable() then
		if not consoleToggleChat.isChecked then
			updateChatMode()

			return
		end

		switchChat(true)

		temporaryChatViaEnter = true

		syncToggleChatToTypingButton()

		return
	end

	local wasTemporary = temporaryChatViaEnter
	local message = getChatInputForSend():getText()

	if #message > 0 then
		sendCurrentMessage()

		if wasTemporary then
			switchChat(false)
			syncToggleChatToWASDButton()
		end

		return
	end

	if wasTemporary then
		switchChat(false)
		syncToggleChatToWASDButton()
	end
end

function disableChatOnCall()
	if not g_game.isOnline() or HotkeyUtils.areHotkeysDisabled() then
		return
	end

	if isNpcModalVisible() then
		if modules.game_npcmodal and modules.game_npcmodal.closeNpcModal then
			modules.game_npcmodal.closeNpcModal()
		end

		return
	end

	if temporaryChatViaEnter then
		switchChat(false)
		syncToggleChatToWASDButton()

		return
	end

	if not consoleToggleChat.isChecked then
		toggleChat()
	else
		updateChatMode()
	end
end

function prepareConsoleTextEditForNpcModal()
	if not consoleTextEdit or not consoleToggleChat or not g_game.isOnline() then
		return
	end

	if consoleTextEdit:isEditable() then
		return
	end

	npcModalRestoreWasdAfterClose = true
	temporaryChatViaEnter = false

	syncToggleChatToTypingButton()

	local npcModal = modules.game_npcmodal.mainNpcModal

	if npcModal and not npcModal:isDestroyed() then
		local npcToggleBtn = npcModal:recursiveGetChildById("toggleChat")

		if npcToggleBtn then
			npcToggleBtn.isChecked = false

			npcToggleBtn:setText(tr("Chat On"))
		end
	end

	switchChat(true)
end

function focusConsoleTextEditAfterNpcModalShow()
	scheduleEvent(function()
		if not npcModalTextEditDocked then
			return
		end

		local proxy = getNpcModalChatProxy()

		if proxy and not proxy:isDestroyed() then
			proxy:focus()
		end
	end, 1)
end

function clearNpcModalItemsPanel()
	local npcModal = modules.game_npcmodal and modules.game_npcmodal.mainNpcModal

	if not npcModal or npcModal:isDestroyed() then
		return
	end

	local itemsPanel = npcModal:recursiveGetChildById("itemsPanel")

	if not itemsPanel then
		return
	end

	itemsPanel:destroyChildren()

	itemsPanel.selection = nil
	itemsPanel.selectionText = nil
end

local function ensureNpcChatTab()
	if not consoleTabBar then
		return nil
	end

	local npcTab = getTab("NPCs")

	npcTab = npcTab or addTab("NPCs", false)

	if npcTab then
		npcTab.npcChat = true
	end

	return npcTab
end

function onNpcModalOpened()
	ensureNpcChatTab()
	prepareConsoleTextEditForNpcModal()
	clearNpcModalItemsPanel()
	focusConsoleTextEditAfterNpcModalShow()
end

function attachConsoleTextEditToNpcModal(npcModalWindow)
	if not consoleTextEdit or not consolePanel or not npcModalWindow then
		return
	end

	healConsoleTextEditIfLeftOnNpcModal()

	if npcModalTextEditDocked then
		return
	end

	local proxy = npcModalWindow:recursiveGetChildById("npcModalChatProxy")

	if not proxy then
		return
	end

	npcModalTextEditDocked = true

	proxy:show()
	applyNpcModalProxyEditability()

	local ph = npcModalWindow:getChildById("placeholderLabel")

	if ph then
		ph:setVisible(proxy:getText():len() == 0)
		npcModalWindow:moveChildToIndex(proxy, npcModalWindow:getChildIndex(ph))
	end

	wireNpcModalProxy(proxy)
	wireNpcModalKeyboard(npcModalWindow)
end

function detachConsoleTextEditFromNpcModal()
	if not npcModalTextEditDocked then
		return
	end

	npcModalTextEditDocked = false

	local proxy = getNpcModalChatProxy()

	if proxy then
		disconnectNpcModalProxy(proxy)
		proxy:hide()
		proxy:clearText()
	end

	if npcModalRestoreWasdAfterClose and consoleToggleChat then
		npcModalRestoreWasdAfterClose = false

		syncToggleChatToWASDButton()

		local npcModal = modules.game_npcmodal.mainNpcModal

		if npcModal and not npcModal:isDestroyed() then
			local npcToggleBtn = npcModal:recursiveGetChildById("toggleChat")

			if npcToggleBtn then
				npcToggleBtn.isChecked = true

				npcToggleBtn:setText(tr("Chat Off"))
			end
		end

		updateChatMode()
	end

	healConsoleTextEditIfLeftOnNpcModal()

	if consoleTextEdit and not consoleTextEdit:isDestroyed() and consolePanel and not consolePanel:isDestroyed() then
		local ph = consolePanel:getChildById("placeholderLabel")

		if ph then
			ph:setVisible(consoleTextEdit:getText():len() == 0)
		end
	end
end

function terminate()
	save()

	for _, mode in ipairs(channelTextMessageModes) do
		unregisterMessageMode(mode, onChannelTextMessage)
	end

	disconnect(g_game, {
		onTalk = onTalk,
		onChannelList = onChannelList,
		onOpenChannel = onOpenChannel,
		onOpenPrivateChannel = onOpenPrivateChannel,
		onOpenOwnPrivateChannel = onOpenOwnPrivateChannel,
		onCloseChannel = onCloseChannel,
		onRuleViolationChannel = onRuleViolationChannel,
		onRuleViolationRemove = onRuleViolationRemove,
		onRuleViolationCancel = onRuleViolationCancel,
		onRuleViolationLock = onRuleViolationLock,
		onGameStart = online,
		onGameEnd = offline,
		onChannelEvent = onChannelEvent
	})

	if g_game.isOnline() then
		clear()
	end

	Keybind.delete("Chat Channel", "Close Current Channel")
	Keybind.delete("Chat Channel", "Next Channel")
	Keybind.delete("Chat Channel", "Previous Channel")
	Keybind.delete("Chat Channel", "Open Channel List")
	Keybind.delete("Chat Channel", "Open Help Channel")
	Keybind.delete("Chat", "Send current chat line")
	Keybind.delete("Chat Mode", "Set to Chat On")
	Keybind.delete("Chat Mode", "Set to Chat Off")
	detachConsoleTextEditFromNpcModal()
	saveCommunicationSettings()
	clearReadOnlyTab()

	if readOnlyModeEnabled then
		toggleReadOnlyMode()
	end

	if readOnlyButton then
		readOnlyButton:destroy()

		readOnlyButton = nil
	end

	if readOnlyPanel then
		readOnlyPanel:destroy()

		readOnlyPanel = nil
	end

	if channelsWindow then
		channelsWindow:destroy()
	end

	if communicationWindow then
		communicationWindow:destroy()
	end

	if violationWindow then
		violationWindow:destroy()
	end

	if modules.game_ruleviolation then
		modules.game_ruleviolation.hidePlayerReportWindow()
	end

	consoleTabBar = nil
	consoleContentPanel = nil
	consoleToggleChat = nil
	consoleTextEdit = nil

	consolePanel:destroy()

	consolePanel = nil
	ownPrivateName = nil
	gameBottomPanel = nil
	Console = nil
end

function save()
	local settings = {}

	settings.messageHistory = messageHistory
	settings.wasdMode = consoleToggleChat.isChecked or temporaryChatViaEnter

	g_settings.setNode("game_console", settings)
end

function load()
	local settings = g_settings.getNode("game_console")

	if settings then
		messageHistory = settings.messageHistory or {}
		consoleToggleChat.isChecked = settings.wasdMode ~= false
	else
		consoleToggleChat.isChecked = true
	end

	if consoleToggleChat.isChecked then
		consoleToggleChat:setText(tr("Chat Off"))
	else
		consoleToggleChat:setText(tr("Chat On"))
	end

	updateChatMode()
	loadCommunicationSettings()
end

function isEnabledWASD()
	return consoleToggleChat.isChecked
end

local function updateConsoleTextEditColorForChannel(tab)
	if not consoleTextEdit or not tab then
		return
	end

	if tab == defaultTab or tab == serverTab then
		consoleTextEdit:setColor("#f4f4f4")
	else
		consoleTextEdit:setColor("#9f9ffe")
	end

	applyNpcModalProxyEditability()
end

function onTabChange(tabBar, tab)
	local player = g_game.getLocalPlayer()
	local message = consoleTextEdit:getText()
	local closeButton = consolePanel:getChildById("closeChannelButton")
	local serverMessageButton = consolePanel:getChildById("serverMessageButton")

	if tab == defaultTab or tab == serverTab then
		closeButton:disable()
		closeButton:hide()
		serverMessageButton:disable()
		serverMessageButton:hide()

		if player then
			player:setTyping(message ~= "")
		end
	else
		closeButton:show()
		closeButton:enable()
		serverMessageButton:show()
		serverMessageButton:enable()

		if player then
			player:setTyping(false)
		end
	end

	if tab.isOnRedMessage then
		tab:setColor("#dfdfdfff")

		tab.isOnRedMessage = false
	end

	if tab.newMessageEvent ~= nil then
		tab:setColor("#dfdfdfff")
		removeEvent(tab.newMessageEvent)

		tab.newMessageEvent = nil
	end

	updateConsoleTextEditColorForChannel(tab)
	updateSayModeButtonVisibility(tab)
end

local function cancelConsoleTabTimers(tab)
	if not tab or tab:isDestroyed() then
		return
	end

	if tab.newMessageEvent then
		removeEvent(tab.newMessageEvent)

		tab.newMessageEvent = nil
	end

	if tab.blinkEvent then
		removeEvent(tab.blinkEvent)

		tab.blinkEvent = nil
	end
end

local function clearConsoleBuffer(tab)
	if not tab or tab:isDestroyed() then
		return
	end

	local panel = tab.tabPanel

	if not panel or panel:isDestroyed() then
		return
	end

	local consoleBuffer = panel:getChildById("consoleBuffer")

	if not consoleBuffer then
		return
	end

	local layout = consoleBuffer:getLayout()

	if layout then
		layout:disableUpdates()
	end

	consoleBuffer:destroyChildren()

	if layout then
		layout:enableUpdates()
	end
end

local function clearNpcModalMirrorLines()
	if not isNpcModalVisible() then
		return
	end

	local npcModal = modules.game_npcmodal.mainNpcModal
	local itemsPanel = npcModal:recursiveGetChildById("itemsPanel")

	if not itemsPanel then
		return
	end

	itemsPanel:destroyChildren()
end

local function collectTabsForLogoutClear()
	local tabs = {}

	for _, channelName in pairs(channels) do
		local tab = findTabByName(channelName)

		if tab then
			tabs[#tabs + 1] = tab
		end
	end

	if defaultTab then
		tabs[#tabs + 1] = defaultTab
	end

	if serverTab then
		tabs[#tabs + 1] = serverTab
	end

	local npcTab = consoleTabBar:getTab("NPCs")

	if npcTab then
		tabs[#tabs + 1] = npcTab
	end

	if violationReportTab then
		tabs[#tabs + 1] = violationReportTab
	end

	return tabs
end

function clear()
	local lastChannelsOpen = g_settings.getNode("lastChannelsOpen") or {}
	local char = g_game.getCharacterName()
	local savedChannels = {}
	local set = false

	for channelId, channelName in pairs(channels) do
		if type(channelId) == "number" then
			savedChannels[channelName] = channelId
			set = true
		end
	end

	if set then
		lastChannelsOpen[char] = savedChannels
	else
		lastChannelsOpen[char] = nil
	end

	g_settings.setNode("lastChannelsOpen", lastChannelsOpen)

	if extendedViewButtonToggleChat and not gameBottomPanel:isVisible() then
		returnChat()
	end

	clearNpcModalMirrorLines()

	if readOnlyModeEnabled then
		clearReadOnlyTab()
		toggleReadOnlyMode()
	end

	local tabsToRemove = collectTabsForLogoutClear()

	channels = {}

	for i = 1, #tabsToRemove do
		local tab = tabsToRemove[i]

		clearConsoleBuffer(tab)
		cancelConsoleTabTimers(tab)
	end

	consoleTabBar:beginBatchRemove()

	for i = 1, #tabsToRemove do
		consoleTabBar:removeTab(tabsToRemove[i])
	end

	consoleTabBar:endBatchRemove()

	defaultTab = nil
	serverTab = nil
	violationReportTab = nil

	consoleTextEdit:clearText()

	if violationWindow then
		violationWindow:destroy()

		violationWindow = nil
	end

	if modules.game_ruleviolation then
		modules.game_ruleviolation.hidePlayerReportWindow()
	end

	if channelsWindow then
		channelsWindow:destroy()

		channelsWindow = nil
	end

	if g_game.getClientVersion() < 862 then
		Keybind.delete("Dialogs", "Open Rule Violation")
	end

	updateSayModeButtonVisibility(nil)
end

function clearChannel(consoleTabBar)
	local currentTab = consoleTabBar:getCurrentTab()
	local currentTabName = getTabChannelName(currentTab)

	currentTab.tabPanel:getChildById("consoleBuffer"):destroyChildren()

	if readOnlyModeEnabled and currentTabName == activeactiveReadOnlyTabName then
		readOnlyPanel:getChildById("panel"):destroyChildren()
	end
end

function setTextEditText(text)
	setTextEditTextOnInput(getActiveChatInputForEdit(), text)
end

function openHelp()
	g_game.joinChannel(HELP_CHANNEL)
end

function openPlayerReportRuleViolationWindow(prefillText)
	if violationWindow or violationReportTab then
		return
	end

	violationWindow = g_ui.loadUI("violationwindow", rootWidget)

	if prefillText and #prefillText > 0 then
		violationWindow:getChildById("text"):setText(prefillText)
	end

	function violationWindow.onEscape()
		violationWindow:destroy()

		violationWindow = nil
	end

	function violationWindow.onEnter()
		local text = violationWindow:getChildById("text"):getText()

		g_game.talkChannel(MessageModes.RVRChannel, 0, text)

		violationReportTab = addTab(tr("Report Rule") .. "...", true)

		addTabText(tr("Please wait patiently for a gamemaster to reply") .. ".", SpeakTypesSettings.privateRed, violationReportTab)
		addTabText(applyMessagePrefixies(g_game.getCharacterName(), 0, text), SpeakTypesSettings.say, violationReportTab, g_game.getCharacterName())

		violationReportTab.locked = true

		violationWindow:destroy()

		violationWindow = nil
	end
end

local CHAT_NAME_ELLIPSIS = "..."

local function setElidedChatWidgetText(widget, name)
	widget:setText(name)

	local availableWidth = widget:getWidth() - widget:getPaddingLeft() - widget:getPaddingRight()

	if availableWidth >= widget:getTextSize().width then
		return false
	end

	local low, high = 0, #name
	local displayName = CHAT_NAME_ELLIPSIS

	while low <= high do
		local middle = math.floor((low + high) / 2)
		local candidate = name:sub(1, middle) .. CHAT_NAME_ELLIPSIS

		widget:setText(candidate)

		if availableWidth >= widget:getTextSize().width then
			displayName = candidate
			low = middle + 1
		else
			high = middle - 1
		end
	end

	widget:setText(displayName)

	return true
end

local function invokeWidgetHoverChange(widget, hovered)
	local handler = UIWidget.onHoverChange

	if not handler then
		return
	end

	if type(handler) == "table" then
		for i = 1, #handler do
			handler[i](widget, hovered)
		end
	else
		handler(widget, hovered)
	end
end

function addTab(name, focus)
	local tab = getTab(name)

	if tab then
		if not focus then
			focus = true
		end
	else
		tab = consoleTabBar:addTab(name, nil, processChannelTabMenu)

		if setElidedChatWidgetText(tab, name) then
			tab.fullName = name

			tab:setTooltip(name)
		end
	end

	if focus then
		consoleTabBar:selectTab(tab)
	end

	function tab:onHoverChange(hovered)
		if consoleTabBar:getId() ~= tab then
			if tab.isOnRedMessage then
				tab:setColor("#f75f5fff")
			end

			if tab.newMessageEvent ~= nil then
				tab:setColor("#dfdfdfff")
			end
		end

		invokeWidgetHoverChange(self, hovered)
	end

	return tab
end

function removeTab(tab)
	if type(tab) == "string" then
		tab = findTabByName(tab)
	end

	if tab == defaultTab or tab == serverTab then
		return
	end

	if tab == violationReportTab then
		g_game.cancelRuleViolation()

		violationReportTab = nil
	elseif tab.violationChatName then
		g_game.closeRuleViolation(tab.violationChatName)
	elseif tab.channelId then
		for k, v in pairs(channels) do
			if k == tab.channelId then
				channels[k] = nil
			end
		end

		if not tab.skipLeaveChannel then
			g_game.leaveChannel(tab.channelId)
		end
	elseif tab:getText() == "NPCs" then
		g_game.closeNpcChannel()
	end

	consoleTabBar:removeTab(tab)
end

function removeCurrentTab()
	removeTab(consoleTabBar:getCurrentTab())
end

function getTab(name)
	return findTabByName(name)
end

function getChannelTab(channelId)
	local channel = channels[channelId]

	if channel then
		return getTab(channel)
	end

	return nil
end

function getRuleViolationsTab()
	if violationsChannelId then
		return getChannelTab(violationsChannelId)
	end

	return nil
end

function getCurrentTab()
	return consoleTabBar:getCurrentTab()
end

function getCurrentConsoleBuffer()
	if not consoleTabBar then
		return nil
	end

	local tab = consoleTabBar:getCurrentTab()

	if not tab or not tab.tabPanel then
		return nil
	end

	return tab.tabPanel:getChildById("consoleBuffer")
end

function addChannel(name, id)
	channels[id] = name

	local focus = not table.find(ignoredChannels, id)
	local tab = addTab(name, focus)

	tab.channelId = id

	return tab
end

local function openLootConsoleTab()
	if not channels[LOOT_CHANNEL] then
		local tab = addChannel(tr("Loot"), LOOT_CHANNEL)

		tab.skipLeaveChannel = true
	else
		local t = getTab(channels[LOOT_CHANNEL])

		if t then
			consoleTabBar:selectTab(t)
		end
	end
end

function addPrivateChannel(receiver)
	channels[receiver] = receiver

	return addTab(receiver, true)
end

function addPrivateText(text, speaktype, name, isPrivateCommand, creatureName, statementId)
	local focus = false

	if speaktype.npcChat then
		name = "NPCs"
	end

	local privateTab = getTab(name)

	if speaktype.npcChat and not privateTab and isNpcModalVisible() then
		privateTab = ensureNpcChatTab()
	end

	if privateTab == nil then
		if speaktype.npcChat then
			return
		elseif isPrivateCommand then
			privateTab = defaultTab
		elseif modules.client_options.getOption("openNewTabsWhenReceivingPrivateMessages") and not focus then
			privateTab = addTab(name, focus)
			channels[name] = name
		else
			privateTab = defaultTab
		end

		privateTab.npcChat = speaktype.npcChat
	elseif focus then
		consoleTabBar:selectTab(privateTab)
	end

	if speaktype.npcChat and privateTab then
		privateTab.npcChat = true
	end

	addTabText(text, speaktype, privateTab, creatureName, statementId)
end

function addText(text, speaktype, tabName, creatureName, statementId)
	local player = g_game.getLocalPlayer()

	if player and player:getName() ~= creatureName and mutedChannels[tabName] then
		return
	end

	local tab = getTab(tabName)

	if tab ~= nil then
		addTabText(text, speaktype, tab, creatureName, statementId)
	end
end

local function buildNpcChatColoredText(text, baseColor, highlightColor)
	baseColor = baseColor or "#60F8F8"
	highlightColor = highlightColor or "#1f9ffe"

	if not text:find("{", 1, true) then
		return nil, nil
	end

	local highlightInfo = {}
	local parts = {}
	local plainLength = 0
	local plainBuffer = ""
	local lastPos = 1
	local found = false

	local function flushPlain()
		if plainBuffer == "" then
			return
		end

		parts[#parts + 1] = string.format("{%s, %s}", plainBuffer, baseColor)
		plainLength = plainLength + #plainBuffer
		plainBuffer = ""
	end

	local function appendKeyword(content)
		flushPlain()

		parts[#parts + 1] = string.format("{%s, %s}", content, highlightColor)

		local startIdx = plainLength

		plainLength = plainLength + #content

		for i = startIdx, plainLength - 1 do
			highlightInfo[i] = content
		end
	end

	for startBrace, content, endBrace in text:gmatch("()%{([^}]*)%}()") do
		found = true

		if lastPos < startBrace then
			plainBuffer = plainBuffer .. text:sub(lastPos, startBrace - 1)
		end

		appendKeyword(content)

		lastPos = endBrace
	end

	if lastPos <= #text then
		plainBuffer = plainBuffer .. text:sub(lastPos)
	end

	flushPlain()

	if not found then
		return nil, nil
	end

	return table.concat(parts), highlightInfo
end

local function stripNpcHighlightMarkers(text)
	return (text:gsub("{([^}]+)}", "%1"))
end

local function applyNpcChatLabel(label, text, speaktype)
	local coloredText, highlightInfo = buildNpcChatColoredText(text, speaktype.color, "#1f9ffe")

	if coloredText then
		label:setColoredText(coloredText)

		label.coloredText = coloredText
		label.highlightInfo = highlightInfo
	else
		label:setText(text)

		label.coloredText = nil
		label.highlightInfo = {}

		label:setColor(speaktype.color)
	end
end

local function copyHighlightInfo(highlightInfo)
	if not highlightInfo then
		return {}
	end

	local copy = {}

	for index, word in pairs(highlightInfo) do
		copy[index] = word
	end

	return copy
end

local function isWordChar(char)
	if not char or char == "" then
		return false
	end

	local byte = string.byte(char)

	return byte >= 48 and byte <= 57 or byte >= 65 and byte <= 90 or byte >= 97 and byte <= 122
end

local function getWordRangeAt(text, position)
	if not text or text == "" or position == nil or position < 0 then
		return nil
	end

	local textLength = #text

	if textLength <= position then
		position = textLength - 1
	end

	if position < 0 then
		return nil
	end

	local function charAt(index)
		return text:sub(index + 1, index + 1)
	end

	if not isWordChar(charAt(position)) then
		if position > 0 and isWordChar(charAt(position - 1)) then
			position = position - 1
		elseif textLength > position + 1 and isWordChar(charAt(position + 1)) then
			position = position + 1
		else
			return nil
		end
	end

	local startPos = position

	while startPos > 0 and isWordChar(charAt(startPos - 1)) do
		startPos = startPos - 1
	end

	local endPos = position + 1

	while endPos < textLength and isWordChar(charAt(endPos)) do
		endPos = endPos + 1
	end

	if endPos <= startPos then
		return nil
	end

	return startPos, endPos
end

local function updateBufferSelectionText(textBuffer)
	if not textBuffer or not textBuffer.selection then
		if textBuffer then
			textBuffer.selectionText = nil
		end

		return
	end

	local parts = {}

	for i = textBuffer.selection.first, textBuffer.selection.last do
		local child = textBuffer:getChildByIndex(i)

		if child then
			table.insert(parts, child:getSelection())
		end
	end

	textBuffer.selectionText = table.concat(parts, "\n")
end

local function applyConsoleLabelSelection(label, textBuffer, startPos, endPos, expandState)
	clearSelection(textBuffer)
	label:setSelection(startPos, endPos)

	label.doubleClickExpandState = expandState

	local selfIndex = label:getParent():getChildIndex(label)

	textBuffer.selection = {
		first = selfIndex,
		last = selfIndex
	}

	updateBufferSelectionText(textBuffer)
end

local function isPositionInsideRange(position, startPos, endPos)
	return position ~= nil and position >= 0 and startPos ~= nil and endPos ~= nil and startPos <= position and position < endPos
end

function isNpcModalVisible()
	local npcModal = modules.game_npcmodal and modules.game_npcmodal.mainNpcModal

	return npcModal and not npcModal:isDestroyed() and npcModal:isVisible()
end

local function setupConsoleLabelDragMove(label, textBuffer)
	function label:onDragMove(mousePos, mouseMoved)
		local parent = self:getParent()
		local parentRect = parent:getPaddingRect()
		local selfIndex = parent:getChildIndex(self)
		local child = parent:getChildByPos(mousePos)

		if not child then
			if mousePos.y < self:getY() then
				for index = selfIndex - 1, 1, -1 do
					local childLabel = parent:getChildByIndex(index)

					if childLabel:getY() + childLabel:getHeight() > parentRect.y then
						if mousePos.y >= childLabel:getY() and mousePos.y <= childLabel:getY() + childLabel:getHeight() or index == 1 then
							child = childLabel

							break
						end
					else
						child = parent:getChildByIndex(index + 1)

						break
					end
				end
			elseif mousePos.y > self:getY() + self:getHeight() then
				for index = selfIndex + 1, parent:getChildCount() do
					local childLabel = parent:getChildByIndex(index)

					if childLabel:getY() < parentRect.y + parentRect.height then
						if mousePos.y >= childLabel:getY() and mousePos.y <= childLabel:getY() + childLabel:getHeight() or index == parent:getChildCount() then
							child = childLabel

							break
						end
					else
						child = parent:getChildByIndex(index - 1)

						break
					end
				end
			else
				child = self
			end
		end

		if not child then
			return false
		end

		local childIndex = parent:getChildIndex(child)

		self.doubleClickExpandState = nil

		clearSelection(textBuffer)

		local textBegin = self:getTextPos(self:getLastClickPosition())
		local textPos = self:getTextPos(mousePos)

		self:setSelection(textBegin, textPos)

		textBuffer.selection = {
			first = math.min(selfIndex, childIndex),
			last = math.max(selfIndex, childIndex)
		}

		if child ~= self then
			for selectionChild = textBuffer.selection.first + 1, textBuffer.selection.last - 1 do
				parent:getChildByIndex(selectionChild):selectAll()
			end

			local childTextPos = child:getTextPos(mousePos)

			if selfIndex < childIndex then
				child:setSelection(0, childTextPos)
			else
				child:setSelection(string.len(child:getText()), childTextPos)
			end
		end

		updateBufferSelectionText(textBuffer)

		return true
	end
end

local function setupConsoleLabelMouseHandlers(label, tab, creatureName, text, textBuffer)
	function label:onMouseRelease(mousePos, mouseButton)
		if mouseButton == MouseLeftButton then
			if self.skipKeywordClick then
				self.skipKeywordClick = false

				return true
			end

			local position = self:getTextPos(mousePos)

			if position ~= nil and position >= 0 and self.highlightInfo then
				local keyword = self.highlightInfo[position]

				if keyword then
					self.doubleClickExpandState = nil

					if self.pendingKeywordEvent then
						removeEvent(self.pendingKeywordEvent)
					end

					self.pendingKeyword = keyword
					self.pendingKeywordEvent = scheduleEvent(function()
						if self.pendingKeyword and not self.skipKeywordClick then
							sendMessage(self.pendingKeyword, tab)

							if isNpcModalChatActive() then
								focusActiveChatInput()
							end
						end

						self.pendingKeyword = nil
						self.pendingKeywordEvent = nil
					end, 250)

					return true
				end
			end
		elseif mouseButton == MouseRightButton then
			processMessageMenu(mousePos, mouseButton, creatureName, text, self, tab)

			return true
		end
	end

	function label:onDoubleClick(mousePos)
		self.skipKeywordClick = true
		self.pendingKeyword = nil

		if self.pendingKeywordEvent then
			removeEvent(self.pendingKeywordEvent)

			self.pendingKeywordEvent = nil
		end

		local text = self:getText()
		local textLength = #text
		local position = self:getTextPos(mousePos)
		local wordStart, wordEnd = getWordRangeAt(text, position)

		if not wordStart then
			return true
		end

		local state = self.doubleClickExpandState

		if state and isPositionInsideRange(position, wordStart, wordEnd) then
			if state.mode == "word" and state.startPos == wordStart and state.endPos == wordEnd then
				applyConsoleLabelSelection(self, textBuffer, 0, textLength, {
					mode = "line"
				})

				return true
			end

			if state.mode == "line" then
				applyConsoleLabelSelection(self, textBuffer, wordStart, wordEnd, {
					mode = "word",
					startPos = wordStart,
					endPos = wordEnd
				})

				return true
			end
		end

		applyConsoleLabelSelection(self, textBuffer, wordStart, wordEnd, {
			mode = "word",
			startPos = wordStart,
			endPos = wordEnd
		})

		return true
	end

	function label:onMousePress(mousePos, button)
		if button == MouseLeftButton then
			local position = self:getTextPos(mousePos)
			local state = self.doubleClickExpandState

			if state and position then
				if state.mode == "word" then
					if not isPositionInsideRange(position, state.startPos, state.endPos) then
						self.doubleClickExpandState = nil
					end
				elseif state.mode == "line" and not isPositionInsideRange(position, 0, #self:getText()) then
					self.doubleClickExpandState = nil
				end
			else
				self.doubleClickExpandState = nil
			end

			clearSelection(textBuffer)
		end
	end

	function label:onDragEnter(mousePos)
		self.doubleClickExpandState = nil

		clearSelection(textBuffer)

		return true
	end

	function label:onDragLeave(droppedWidget, mousePos)
		updateBufferSelectionText(textBuffer)

		return true
	end

	setupConsoleLabelDragMove(label, textBuffer)
end

local function addNpcModalMirrorLine(sourceLabel, tab)
	if not isNpcModalVisible() or not sourceLabel then
		return
	end

	local npcModal = modules.game_npcmodal.mainNpcModal
	local itemsPanel = npcModal:recursiveGetChildById("itemsPanel")

	if not itemsPanel then
		return
	end

	local mirror = g_ui.createWidget("ConsoleLabel", itemsPanel)

	mirror:setId("npcModalMirrorLine" .. itemsPanel:getChildCount())
	mirror:setFocusable(false)

	if sourceLabel.coloredText then
		mirror:setColoredText(sourceLabel.coloredText)

		mirror.coloredText = sourceLabel.coloredText
	else
		mirror:setText(sourceLabel:getText())

		mirror.coloredText = nil

		mirror:setColor(sourceLabel:getColor())
	end

	mirror.highlightInfo = copyHighlightInfo(sourceLabel.highlightInfo)
	mirror.name = sourceLabel.name

	setupConsoleLabelMouseHandlers(mirror, tab, sourceLabel.name, sourceLabel:getText(), itemsPanel)

	if itemsPanel:getChildCount() > MAX_LINES then
		local first = itemsPanel:getFirstChild()

		if first then
			first:destroy()
		end
	end
end

local function changeNewNessageColor(tab)
	if tab.newMessageEvent ~= nil or tab.isOnRedMessage then
		return
	end

	tab:setColor("#dfdfdfff")

	tab.newMessageEvent = scheduleEvent(function()
		tab:setColor("#f75f5fff")

		tab.isOnRedMessage = true
		tab.newMessageEvent = nil
	end, 1000)
end

local function recycleConsoleLabel(label)
	if label.pendingKeywordEvent then
		removeEvent(label.pendingKeywordEvent)

		label.pendingKeywordEvent = nil
	end

	label.pendingKeyword = nil
	label.skipKeywordClick = nil
	label.doubleClickExpandState = nil
	label.coloredText = nil
	label.highlightInfo = nil
end

function addTabText(text, speaktype, tab, creatureName, statementId)
	if not tab or tab.locked or not text or #text == 0 then
		return
	end

	if modules.client_options.getOption("showTimestampsInConsole") then
		text = os.date("%H:%M") .. " " .. text
	end

	local panel = consoleTabBar:getTabPanel(tab)
	local consoleBuffer = panel:getChildById("consoleBuffer")
	local label

	if consoleBuffer:getChildCount() >= MAX_LINES then
		clearSelection(consoleBuffer)

		label = consoleBuffer:getFirstChild()

		recycleConsoleLabel(label)
		consoleBuffer:moveChildToIndex(label, consoleBuffer:getChildCount())
	else
		label = g_ui.createWidget("ConsoleLabel", consoleBuffer)
	end

	label:setId("consoleLabel" .. consoleBuffer:getChildCount())

	local isNpcHighlight = speaktype.npcChat and (g_game.getCharacterName() ~= creatureName or g_game.getCharacterName() == "Account Manager")

	if isNpcHighlight then
		applyNpcChatLabel(label, text, speaktype)
	elseif speaktype.colored then
		label:setColoredText(text)

		label.coloredText = text
		label.highlightInfo = {}
	else
		label:setText(text)

		label.coloredText = nil
		label.highlightInfo = {}

		label:setColor(speaktype.color)
	end

	if readOnlyModeEnabled and activeactiveReadOnlyTabName == getTabChannelName(tab) then
		local readOnlyBuffer = readOnlyPanel:getChildById("panel")
		local readOnlyLabel = g_ui.createWidget("ConsoleLabel", readOnlyBuffer)

		readOnlyLabel:setId("consoleLabel" .. readOnlyBuffer:getChildCount())

		if isNpcHighlight then
			applyNpcChatLabel(readOnlyLabel, text, speaktype)
		elseif speaktype.colored then
			readOnlyLabel:setColoredText(text)

			readOnlyLabel.coloredText = text
		else
			readOnlyLabel:setText(text)
			readOnlyLabel:setColor(speaktype.color)
		end
	end

	if consoleTabBar:getCurrentTab() ~= tab and (not readOnlyModeEnabled or activeactiveReadOnlyTabName ~= getTabChannelName(tab)) then
		changeNewNessageColor(tab)
	end

	label.name = creatureName
	label.statementId = statementId or 0

	function consoleBuffer:onMouseRelease(mousePos, mouseButton)
		if mouseButton ~= MouseRightButton then
			return
		end

		local clickedLabel = self:getChildByPos(mousePos)

		if clickedLabel then
			processMessageMenu(mousePos, mouseButton, clickedLabel.name, clickedLabel:getText(), clickedLabel, tab)
		else
			processMessageMenu(mousePos, mouseButton, nil, nil, nil, tab)
		end

		return true
	end

	setupConsoleLabelMouseHandlers(label, tab, creatureName, text, consoleBuffer)

	if (tab.npcChat or speaktype.npcChat) and isNpcModalVisible() then
		addNpcModalMirrorLine(label, tab)
	end
end

function removeTabLabelByName(tab, name)
	local panel = consoleTabBar:getTabPanel(tab)
	local consoleBuffer = panel:getChildById("consoleBuffer")

	for _, label in pairs(consoleBuffer:getChildren()) do
		if label.name == name then
			label:destroy()
		end
	end
end

function processChannelTabMenu(tab, mousePos, mouseButton)
	local menu = g_ui.createWidget("PopupMenu")

	menu:setGameMenu(true)

	local worldName = g_game.getWorldName()
	local characterName = g_game.getCharacterName()

	channelName = getTabChannelName(tab)

	if tab ~= defaultTab and tab ~= serverTab then
		menu:addOption(tr("Close"), function()
			removeTab(channelName)
		end)
		menu:addSeparator()
	end

	if readOnlyModeEnabled and activeactiveReadOnlyTabName == channelName then
		menu:addOption(tr("Close Read-Only Tab"), function()
			clearReadOnlyTab()
			toggleReadOnlyMode()
		end)
		menu:addSeparator()
	else
		menu:addOption(tr("Show in Read-Only Tab"), function()
			activateReadOnlyMode(channelName)
		end)
		menu:addSeparator()
	end

	local muted = mutedChannels[channelName]

	menu:addOption(tr("%s", muted and "Unmute" or "Mute"), function()
		setChannelMuted(channelName, not muted)
	end)
	menu:addSeparator()

	if consoleTabBar:getCurrentTab() == tab then
		menu:addOption(tr("Save Window"), function()
			saveChannelMessages(tab, worldName, characterName, channelName)
		end)
		menu:addOption(tr("Clear Window"), function()
			clearChannel(consoleTabBar)
		end)
	end

	menu:display(mousePos)
end

local function getMessageStatement(text)
	if not text or #text == 0 then
		return ""
	end

	return text:match(".+%:%s(.+)") or text
end

local function reportStatement(creatureName, text, label)
	local statementId = label and label.statementId or 0

	modules.game_ruleviolation.openStatementReport(creatureName, getMessageStatement(text), statementId)
end

local function reportName(creatureName)
	modules.game_ruleviolation.openNameReport(creatureName)
end

function processMessageMenu(mousePos, mouseButton, creatureName, text, label, tab)
	if mouseButton == MouseRightButton then
		local menu = g_ui.createWidget("PopupMenu")

		menu:setGameMenu(true)

		local isOtherPlayer = creatureName and #creatureName > 0 and creatureName ~= g_game.getCharacterName()

		if isOtherPlayer then
			menu:addOption(tr("Message to %s", creatureName), function()
				g_game.openPrivateChannel(creatureName)
			end)

			if not g_game.getLocalPlayer():hasVip(creatureName) then
				menu:addOption(tr("Add %s to VIP list", creatureName), function()
					g_game.addVip(creatureName)
				end)
			end

			if isIgnored(creatureName) then
				menu:addOption(tr("Unignore %s", creatureName), function()
					removeIgnoredPlayer(creatureName)
				end)
			else
				menu:addOption(tr("Ignore %s", creatureName), function()
					addIgnoredPlayer(creatureName)
				end)
			end

			menu:addSeparator()
		end

		menu:addOption(tr("Select all"), function()
			selectAll(tab.tabPanel:getChildById("consoleBuffer"))
		end)

		if text then
			menu:addOption(tr("Copy message"), function()
				g_window.setClipboardText(text)
			end)
		end

		if isOtherPlayer then
			menu:addSeparator()
			menu:addOption(tr("Report Statement"), function()
				reportStatement(creatureName, text, label)
			end)
			menu:addOption(tr("Report Name"), function()
				reportName(creatureName)
			end)
			menu:addSeparator()
			menu:addOption(tr("Copy Name"), function()
				g_window.setClipboardText(creatureName)
			end)
		elseif creatureName and #creatureName > 0 then
			menu:addSeparator()
			menu:addOption(tr("Copy Name"), function()
				g_window.setClipboardText(creatureName)
			end)
		end

		if tab.violations and creatureName then
			menu:addSeparator()
			menu:addOption(tr("Process") .. " " .. creatureName, function()
				processViolation(creatureName, text)
			end)
			menu:addOption(tr("Remove") .. " " .. creatureName, function()
				g_game.closeRuleViolation(creatureName)
			end)
		end

		menu:display(mousePos)
	end
end

function sendCurrentMessage()
	local input = getChatInputForSend()
	local message = input:getText()

	if #message == 0 then
		return
	end

	if not isChatEnabled() then
		return
	end

	input:clearText()

	if input == consoleTextEdit then
		local ph = consolePanel:getChildById("placeholderLabel")

		if ph then
			ph:setVisible(true)
		end
	else
		local npcModal = modules.game_npcmodal.mainNpcModal
		local ph = npcModal and npcModal:getChildById("placeholderLabel")

		if ph then
			ph:setVisible(true)
		end
	end

	local proxy = getNpcModalChatProxy()

	if proxy and input == proxy then
		local npcTab = ensureNpcChatTab()

		if npcTab then
			sendMessage(message, npcTab)
		end
	else
		sendMessage(message)
	end
end

function addFilter(filter)
	table.insert(filters, filter)
end

function removeFilter(filter)
	table.removevalue(filters, filter)
end

function sendMessage(message, tab)
	local tab = tab or getCurrentTab()

	if not tab then
		return
	end

	for k, func in pairs(filters) do
		if func(message) then
			return true
		end
	end

	local name = getTabChannelName(tab)

	if tab == serverTab or tab == getRuleViolationsTab() then
		tab = defaultTab
		name = getTabChannelName(defaultTab)
	end

	if tab.channelId == LOOT_CHANNEL then
		tab = defaultTab
		name = getTabChannelName(defaultTab)
	end

	local channel = tab.channelId
	local originalMessage = message
	local chatCommandSayMode, chatCommandPrivate, chatCommandPrivateReady, chatCommandMessage

	chatCommandMessage = message:match("^%#[y|Y] (.*)")

	if chatCommandMessage ~= nil then
		chatCommandSayMode = "yell"
		channel = 0
		message = chatCommandMessage
	end

	chatCommandMessage = message:match("^%#[w|W] (.*)")

	if chatCommandMessage ~= nil then
		chatCommandSayMode = "whisper"
		message = chatCommandMessage
		channel = 0
	end

	chatCommandMessage = message:match("^%#[s|S] (.*)")

	if chatCommandMessage ~= nil then
		chatCommandSayMode = "say"
		message = chatCommandMessage
		channel = 0
	end

	chatCommandMessage = message:match("^%#[c|C] (.*)")

	if chatCommandMessage ~= nil then
		chatCommandSayMode = "channelRed"
		message = chatCommandMessage
	end

	chatCommandMessage = message:match("^%#[b|B] (.*)")

	if chatCommandMessage ~= nil then
		chatCommandSayMode = "broadcast"
		message = chatCommandMessage
		channel = 0
	end

	local findIni, findEnd, chatCommandInitial, chatCommandPrivate, chatCommandEnd, chatCommandMessage = message:find("([%*%@])(.+)([%*%@])(.*)")

	if findIni ~= nil and findIni == 1 and chatCommandInitial == chatCommandEnd then
		chatCommandPrivateRepeat = false

		if chatCommandInitial == "*" then
			setTextEditText("*" .. chatCommandPrivate .. "* ")
		end

		message = chatCommandMessage:trim()
		chatCommandPrivateReady = true
	end

	message = message:gsub("^(%s*)(.*)", "%2")

	if #message == 0 then
		return
	end

	currentMessageIndex = 0

	if #messageHistory == 0 or messageHistory[#messageHistory] ~= originalMessage then
		table.insert(messageHistory, originalMessage)

		if #messageHistory > MAX_HISTORY then
			table.remove(messageHistory, 1)
		end
	end

	local speaktypedesc

	if (channel or tab == defaultTab) and not chatCommandPrivateReady then
		if tab == defaultTab then
			speaktypedesc = chatCommandSayMode or SayModes[consolePanel:getChildById("sayModeButton").sayMode].speakTypeDesc

			if speaktypedesc ~= "say" then
				sayModeChange(2)
			end
		else
			speaktypedesc = chatCommandSayMode or "channelYellow"
		end

		g_game.talkChannel(SpeakTypesSettings[speaktypedesc].speakType, channel, message)

		return
	else
		local isPrivateCommand = false
		local priv = true
		local tabname = name
		local dontAdd = false

		if chatCommandPrivateReady then
			speaktypedesc = "privatePlayerToPlayer"
			name = chatCommandPrivate
			isPrivateCommand = true
		elseif tab.npcChat then
			speaktypedesc = "privatePlayerToNpc"
		elseif tab == violationReportTab then
			if violationReportTab.locked then
				modules.game_textmessage.displayFailureMessage("Wait for a gamemaster reply.")

				dontAdd = true
			else
				speaktypedesc = "rvrContinue"
				tabname = tr("Report Rule") .. "..."
			end
		elseif tab.violationChatName then
			speaktypedesc = "rvrAnswerTo"
			name = tab.violationChatName
			tabname = tab.violationChatName .. "'..."
		else
			speaktypedesc = "privatePlayerToPlayer"
		end

		local speaktype = SpeakTypesSettings[speaktypedesc]
		local player = g_game.getLocalPlayer()

		g_game.talkPrivate(speaktype.speakType, name, message)

		if not dontAdd then
			message = applyMessagePrefixies(g_game.getCharacterName(), player:getLevel(), message)

			addPrivateText(message, speaktype, tabname, isPrivateCommand, g_game.getCharacterName())
		end
	end
end

function sendNpcModalReply(message)
	if not message or #message == 0 or not consoleTabBar then
		return
	end

	local npcTab = ensureNpcChatTab()

	if not npcTab then
		g_game.talkPrivate(MessageModes.NpcTo, "NPCs", message)

		if isNpcModalChatActive() then
			focusActiveChatInput()
		end

		return
	end

	sendMessage(message, npcTab)

	if isNpcModalChatActive() then
		focusActiveChatInput()
	end
end

function sayModeChange(sayMode)
	if not consolePanel then
		return
	end

	local button = consolePanel:getChildById("sayModeButton")

	if not button then
		return
	end

	if sayMode == nil then
		local cur = tonumber(button.sayMode)

		if not cur or cur < 1 then
			cur = 2
		end

		sayMode = cur + 1
	end

	if sayMode > #SayModes then
		sayMode = 1
	end

	local mode = SayModes[sayMode]

	if not mode then
		return
	end

	button:setImageSource("/images/ui/adjust_chat")
	button:setImageClip(mode.clip)

	button.sayMode = sayMode
end

function getOwnPrivateTab()
	if not ownPrivateName then
		return
	end

	return getTab(ownPrivateName)
end

function setIgnoreNpcMessages(ignore)
	ignoreNpcMessages = ignore
end

function navigateMessageHistory(step)
	if not isChatEnabled() then
		return
	end

	local input = getActiveChatInputForEdit()
	local numCommands = #messageHistory

	if numCommands > 0 then
		currentMessageIndex = math.min(math.max(currentMessageIndex + step, 0), numCommands)

		if currentMessageIndex > 0 then
			local command = messageHistory[numCommands - currentMessageIndex + 1]

			setTextEditTextOnInput(input, command)
		else
			setTextEditTextOnInput(input, "")
		end
	end

	focusActiveChatInput()

	local player = g_game.getLocalPlayer()

	if player then
		player:lockWalk(200)
	end
end

function applyMessagePrefixies(name, level, message)
	if name and #name > 0 then
		if modules.client_options.getOption("showLevelsInConsole") and level > 0 then
			message = name .. " [" .. level .. "]: " .. message
		else
			message = name .. ": " .. message
		end
	end

	return message
end

function onTalk(name, level, mode, message, channelId, creaturePos, statementId)
	statementId = statementId or 0

	if mode == MessageModes.GamemasterBroadcast then
		modules.game_textmessage.displayBroadcastMessage(name .. ": " .. message)

		return
	end

	local isNpcMode = mode == MessageModes.NpcFromStartBlock or mode == MessageModes.NpcFrom

	if ignoreNpcMessages and isNpcMode then
		return
	end

	speaktype = SpeakTypes[mode]

	if not speaktype then
		perror("unhandled onTalk message mode " .. mode .. ": " .. message)

		return
	end

	local localPlayer = g_game.getLocalPlayer()

	if name ~= g_game.getCharacterName() and isUsingIgnoreList() and not isUsingWhiteList() or isUsingWhiteList() and not isWhitelisted(name) and (not isAllowingVIPs() or not localPlayer:hasVip(name)) then
		if mode == MessageModes.Yell and isIgnoringYelling() then
			return
		elseif speaktype.private and isIgnoringPrivate() and not isNpcMode then
			return
		elseif isIgnored(name) then
			return
		end
	end

	if mode == MessageModes.RVRChannel then
		channelId = violationsChannelId
	end

	local showPotionText = mode == MessageModes.Potion and modules.client_options.getOption("showPotionSoundEffects")
	local showStaticText = mode == MessageModes.Say or mode == MessageModes.Whisper or mode == MessageModes.Yell or mode == MessageModes.Spell or mode == MessageModes.MonsterSay or mode == MessageModes.MonsterYell or mode == MessageModes.NpcFrom or mode == MessageModes.BarkLow or mode == MessageModes.BarkLoud or mode == MessageModes.NpcFromStartBlock or showPotionText

	if showStaticText and creaturePos then
		local staticText = StaticText.create()
		local staticMode = mode == MessageModes.Spell and MessageModes.Say or mode == MessageModes.Potion and MessageModes.MonsterSay or mode
		local staticMessage = message

		if isNpcMode then
			staticMessage = stripNpcHighlightMarkers(staticMessage)

			staticText:setColor(speaktype.color)
		end

		staticText:addMessage(name, staticMode, staticMessage)
		g_map.addStaticText(staticText, creaturePos)
		modules.game_textmessage.registerStaticTextMessage(staticText, creaturePos)
	end

	local defaultMessage = mode <= MessageModes.Yell or mode == MessageModes.Spell

	if speaktype == SpeakTypesSettings.none then
		return
	end

	if speaktype.hideInConsole then
		return
	end

	local composedMessage = applyMessagePrefixies(name, level, message)

	if mode == MessageModes.RVRAnswer then
		violationReportTab.locked = false

		addTabText(composedMessage, speaktype, violationReportTab, name, statementId)
	elseif mode == MessageModes.RVRContinue then
		addText(composedMessage, speaktype, name .. "'...", name, statementId)
	elseif speaktype.private then
		addPrivateText(composedMessage, speaktype, name, false, name, statementId)

		if modules.client_options.getOption("showPrivateMessages") and modules.client_options.getOption("showMessages") and speaktype ~= SpeakTypesSettings.privateNpcToPlayer then
			modules.game_textmessage.displayPrivateMessage(name .. ":\n" .. message)
		end
	else
		local channel = tr("Local Chat")

		if not defaultMessage then
			channel = channels[channelId]
		end

		if channel then
			addText(composedMessage, speaktype, channel, name, statementId)
		elseif channelId == LOOT_CHANNEL then
			openLootConsoleTab()

			channel = channels[channelId]

			if channel then
				addText(composedMessage, speaktype, channel, name, statementId)
			end
		else
			pwarning("message in channel id " .. channelId .. " which is unknown, this is a server bug, relogin if you want to see messages in this channel")
		end
	end
end

local function getChannelTabName(channelId)
	if channels[channelId] then
		return channels[channelId]
	end

	if channelId == CHANNEL_GUILD or channelId == CHANNEL_GUILD_LEADER then
		return channels[CHANNEL_GUILD] or channels[CHANNEL_GUILD_LEADER]
	end

	if channelId == CHANNEL_PARTY then
		return channels[CHANNEL_PARTY]
	end

	return nil
end

local function showChannelParticipants(tab, participants)
	if not tab or not participants or #participants == 0 then
		return
	end

	local names = table.concat(participants, ", ")

	addTabText(tr("Channel participants: %s.", names), SpeakTypesSettings.channelWhite, tab)
end

function onChannelTextMessage(mode, text, channelId)
	if channelId == nil or channelId == TEXT_MESSAGE_NO_CHANNEL then
		return
	end

	local tabName = getChannelTabName(channelId)

	if not tabName then
		return
	end

	local speaktype = SpeakTypesSettings.channelWhite

	if mode == MessageModes.Party then
		speaktype = SpeakTypesSettings.channelYellow
	end

	addText(text, speaktype, tabName)
end

function onOpenChannel(channelId, channelName, participants)
	local tab = addChannel(channelName, channelId)

	if tab and channelId == LOOT_CHANNEL then
		tab.skipLeaveChannel = false
	end

	if tab and participants and #participants > 0 then
		showChannelParticipants(tab, participants)
	end
end

function onOpenPrivateChannel(receiver)
	addPrivateChannel(receiver)
end

function onOpenOwnPrivateChannel(channelId, channelName, participants)
	local privateTab = getTab(channelName)
	local tab

	if privateTab == nil then
		tab = addChannel(channelName, channelId)
	else
		tab = privateTab
	end

	ownPrivateName = channelName

	if tab and participants and #participants > 0 then
		showChannelParticipants(tab, participants)
	end
end

function onCloseChannel(channelId)
	local channel = channels[channelId]

	if channel then
		local tab = getTab(channel)

		if tab then
			consoleTabBar:removeTab(tab)
		end

		for k, v in pairs(channels) do
			if k == tab.channelId then
				channels[k] = nil
			end
		end
	end
end

function processViolation(name, text)
	local tabname = name .. "'..."
	local tab = addTab(tabname, true)

	channels[tabname] = tabname
	tab.violationChatName = name

	g_game.openRuleViolation(name)
	addTabText(text, SpeakTypesSettings.say, tab, name)
end

function onRuleViolationChannel(channelId)
	violationsChannelId = channelId

	local tab = addChannel(tr("Rule Violations"), channelId)

	tab.violations = true
end

function onRuleViolationRemove(name)
	local tab = getRuleViolationsTab()

	if not tab then
		return
	end

	removeTabLabelByName(tab, name)
end

function onRuleViolationCancel(name)
	local tab = getTab(name .. "'...")

	if not tab then
		return
	end

	addTabText(tr("%s has finished the request", name) .. ".", SpeakTypesSettings.privateRed, tab)

	tab.locked = true
end

function onRuleViolationLock()
	if not violationReportTab then
		return
	end

	violationReportTab.locked = false

	addTabText(tr("Your request has been closed") .. ".", SpeakTypesSettings.privateRed, violationReportTab)

	violationReportTab.locked = true
end

function doChannelListSubmit()
	local channelListPanel = channelsWindow:getChildById("channelList")
	local openPrivateChannelWith = channelsWindow:getChildById("openPrivateChannelWith"):getText():trim()
	local wnd = channelsWindow

	local function closeWindow()
		if wnd and not wnd:isDestroyed() then
			wnd:destroy()
		end
	end

	if openPrivateChannelWith ~= "" then
		if openPrivateChannelWith:lower() ~= g_game.getCharacterName():lower() then
			g_game.openPrivateChannel(openPrivateChannelWith)
		else
			modules.game_textmessage.displayFailureMessage("You cannot create a private chat channel with yourself.")
		end

		closeWindow()

		return
	end

	local selectedChannelLabel = channelListPanel:getFocusedChild()

	if not selectedChannelLabel then
		modules.game_textmessage.displayFailureMessage(tr("Select a channel."))
		closeWindow()

		return
	end

	local wid = selectedChannelLabel:getId() or ""

	if wid == "channelListEntry_npc" then
		if g_game.getClientVersion() >= 820 then
			local npcTab = getTab("NPCs")

			if not npcTab then
				npcTab = addTab("NPCs", true)
				npcTab.npcChat = true
			else
				consoleTabBar:selectTab(npcTab)
			end
		end
	elseif wid == "channelListEntry_" .. tostring(65535) then
		g_game.openOwnChannel()
	else
		local cid = tonumber(wid:match("^channelListEntry_(%d+)$"))

		if cid == LOOT_CHANNEL then
			openLootConsoleTab()
		elseif cid then
			if channels[cid] then
				g_game.leaveChannel(cid)
			end

			scheduleEvent(function()
				if g_game.isOnline() then
					g_game.joinChannel(cid)
				end
			end, 50)
		end
	end

	closeWindow()
end

function onChannelList(channelList)
	if channelsWindow then
		channelsWindow:destroy()
	end

	channelsWindow = g_ui.displayUI("channelswindow")

	local channelListPanel = channelsWindow:getChildById("channelList")

	channelsWindow.onEnter = doChannelListSubmit

	function channelsWindow.onDestroy()
		channelsWindow = nil
	end

	g_keyboard.bindKeyPress("Down", function()
		channelListPanel:focusNextChild(KeyboardFocusReason)
	end, channelsWindow)
	g_keyboard.bindKeyPress("Up", function()
		channelListPanel:focusPreviousChild(KeyboardFocusReason)
	end, channelsWindow)

	local rowBackgrounds = {
		"#484848",
		"#414141"
	}
	local index = 0
	local displayList = {}

	for _, v in ipairs(channelList) do
		if v[1] ~= LOOT_CHANNEL and #v[2] > 0 then
			table.insert(displayList, v)
		end
	end

	if g_game.getClientVersion() >= 820 then
		table.insert(displayList, {
			ClientOpenChannelNpcId,
			tr("NPCs")
		})
	end

	table.insert(displayList, {
		LOOT_CHANNEL,
		tr("Loot")
	})

	for _, v in ipairs(displayList) do
		local channelId = v[1]
		local channelName = v[2]

		if #channelName > 0 then
			index = index + 1

			local label = g_ui.createWidget("ChannelListLabel", channelListPanel)

			label.channelId = channelId

			if channelId == ClientOpenChannelNpcId then
				label:setId("channelListEntry_npc")
			else
				label:setId("channelListEntry_" .. tostring(channelId))
			end

			label:setText(channelName)

			label.originalColor = rowBackgrounds[(index - 1) % 2 + 1]

			label:setBackgroundColor(label.originalColor)

			function label.onFocusChange(widget, focused)
				if focused then
					for _, other in pairs(channelListPanel:getChildren()) do
						if other ~= widget and other.originalColor then
							other:setBackgroundColor(other.originalColor)
						end
					end
				else
					widget:setBackgroundColor(widget.originalColor)
				end
			end

			label:setPhantom(false)

			label.onDoubleClick = doChannelListSubmit
		end
	end

	local firstChannel = channelListPanel:getChildByIndex(1)

	if firstChannel then
		channelListPanel:focusChild(firstChannel, KeyboardFocusReason)
		channelListPanel:ensureChildVisible(firstChannel)
	end
end

function loadCommunicationSettings()
	communicationSettings.whitelistedPlayers = {}
	communicationSettings.ignoredPlayers = {}

	local ignoreNode = g_settings.getNode("IgnorePlayers")

	if ignoreNode then
		for _, player in pairs(ignoreNode) do
			table.insert(communicationSettings.ignoredPlayers, player)
		end
	end

	local whitelistNode = g_settings.getNode("WhitelistedPlayers")

	if whitelistNode then
		for _, player in pairs(whitelistNode) do
			table.insert(communicationSettings.whitelistedPlayers, player)
		end
	end

	communicationSettings.useIgnoreList = g_settings.getBoolean("UseIgnoreList")
	communicationSettings.useWhiteList = g_settings.getBoolean("UseWhiteList")
	communicationSettings.privateMessages = g_settings.getBoolean("IgnorePrivateMessages")
	communicationSettings.yelling = g_settings.getBoolean("IgnoreYelling")
	communicationSettings.allowVIPs = g_settings.getBoolean("AllowVIPs")
end

function saveCommunicationSettings()
	local tmpIgnoreList = {}
	local ignoredPlayers = getIgnoredPlayers()

	for i = 1, #ignoredPlayers do
		table.insert(tmpIgnoreList, ignoredPlayers[i])
	end

	local tmpWhiteList = {}
	local whitelistedPlayers = getWhitelistedPlayers()

	for i = 1, #whitelistedPlayers do
		table.insert(tmpWhiteList, whitelistedPlayers[i])
	end

	g_settings.set("UseIgnoreList", communicationSettings.useIgnoreList)
	g_settings.set("UseWhiteList", communicationSettings.useWhiteList)
	g_settings.set("IgnorePrivateMessages", communicationSettings.privateMessages)
	g_settings.set("IgnoreYelling", communicationSettings.yelling)
	g_settings.setNode("IgnorePlayers", tmpIgnoreList)
	g_settings.setNode("WhitelistedPlayers", tmpWhiteList)
end

function getIgnoredPlayers()
	return communicationSettings.ignoredPlayers
end

function getWhitelistedPlayers()
	return communicationSettings.whitelistedPlayers
end

function isUsingIgnoreList()
	return communicationSettings.useIgnoreList
end

function isUsingWhiteList()
	return communicationSettings.useWhiteList
end

function isIgnored(name)
	return table.find(communicationSettings.ignoredPlayers, name, true)
end

function addIgnoredPlayer(name)
	if isIgnored(name) then
		return
	end

	table.insert(communicationSettings.ignoredPlayers, name)

	communicationSettings.useIgnoreList = true
end

function removeIgnoredPlayer(name)
	table.removevalue(communicationSettings.ignoredPlayers, name)
end

function isWhitelisted(name)
	return table.find(communicationSettings.whitelistedPlayers, name, true)
end

function addWhitelistedPlayer(name)
	if isWhitelisted(name) then
		return
	end

	table.insert(communicationSettings.whitelistedPlayers, name)
end

function removeWhitelistedPlayer(name)
	table.removevalue(communicationSettings.whitelistedPlayers, name)
end

function isIgnoringPrivate()
	return communicationSettings.privateMessages
end

function isIgnoringYelling()
	return communicationSettings.yelling
end

function isAllowingVIPs()
	return communicationSettings.allowVIPs
end

local function setAlternatingColor(widget, index)
	widget:setBackgroundColor(index % 2 == 1 and "#484848" or "#414141")
end

local function createListEntry(panel, template, text)
	local label = g_ui.createWidget(template, panel)

	label:setText(text)
	setAlternatingColor(label, panel:getChildCount())

	return label
end

local function setupRemoveButton(panel, button, editorId, removeFunction)
	button:disable()

	function panel.onChildFocusChange()
		local focused = panel:getFocusedChild()

		if focused and focused:getId() ~= editorId then
			button:enable()
		else
			button:disable()
		end
	end

	function button.onClick()
		local selection = panel:getFocusedChild()

		if selection and selection:getId() ~= editorId then
			removeFunction(selection:getText())
			selection:destroy()

			for i = 1, panel:getChildCount() do
				local child = panel:getChildByIndex(i)

				if child:getId() ~= editorId then
					setAlternatingColor(child, i)
				end
			end
		end

		button:disable()
	end
end

local function createInlineEditor(panel, editorId, template, getListFunction, addFunction)
	if panel:recursiveGetChildById(editorId) then
		return
	end

	local editor = g_ui.createWidget("TextEdit", panel)

	editor:setId(editorId)
	editor:setHeight(16)
	editor:setMarginLeft(-2)
	editor:setBorderWidth(0)
	editor:setPaddingLeft(3)
	editor:setText("new entry")
	editor:setCursorPos(0)
	editor:setSelection(0, #"new entry")

	local function confirm(self)
		if not self or self:isDestroyed() then
			return
		end

		local text = self:getText():trim()

		if text ~= "" and text:lower() ~= "new entry" and not table.find(getListFunction(), text) then
			createListEntry(panel, template, text)
			addFunction(text)
		end

		self:destroy()

		editor = nil
	end

	function editor:onKeyPress(keyCode)
		if not g_keyboard.isEnterKey(keyCode) then
			return false
		end

		confirm(self)

		return true
	end

	function editor:onFocusChange(focused)
		if not focused then
			confirm(self)
		end
	end

	function editor:onEscape()
		if not self:isDestroyed() then
			self:destroy()

			editor = nil
			communicationWindow.onClick = oldOnClick
		end
	end

	local oldOnClick = communicationWindow.onClick

	function communicationWindow.onClick(widget, mousePos, mouseButton)
		if oldOnClick then
			oldOnClick(widget, mousePos, mouseButton)
		end

		if editor and not editor:isDestroyed() then
			confirm(editor)
		end
	end

	editor:focus()
	editor:raise()
end

function onClickIgnoreButton()
	if communicationWindow then
		return
	end

	communicationWindow = g_ui.displayUI("communicationwindow")

	function communicationWindow.onDestroy()
		communicationWindow = nil
	end

	local ignoreListPanel = communicationWindow:recursiveGetChildById("ignoreList")
	local whiteListPanel = communicationWindow:recursiveGetChildById("whiteList")
	local useIgnoreListBox = communicationWindow:recursiveGetChildById("checkboxUseIgnoreList")
	local useWhiteListBox = communicationWindow:recursiveGetChildById("checkboxUseWhiteList")
	local ignorePrivateMessageBox = communicationWindow:recursiveGetChildById("checkboxIgnorePrivateMessages")
	local ignoreYellingBox = communicationWindow:recursiveGetChildById("checkboxIgnoreYelling")
	local allowVIPsBox = communicationWindow:recursiveGetChildById("checkboxAllowVIPs")

	useIgnoreListBox:setChecked(communicationSettings.useIgnoreList)
	useWhiteListBox:setChecked(communicationSettings.useWhiteList)
	ignorePrivateMessageBox:setChecked(communicationSettings.privateMessages)
	ignoreYellingBox:setChecked(communicationSettings.yelling)
	allowVIPsBox:setChecked(communicationSettings.allowVIPs)

	local removeIgnoreButton = communicationWindow:recursiveGetChildById("buttonIgnoreRemove")
	local removeWhitelistButton = communicationWindow:recursiveGetChildById("buttonWhitelistRemove")

	setupRemoveButton(ignoreListPanel, removeIgnoreButton, "ignoreEditor", removeIgnoredPlayer)
	setupRemoveButton(whiteListPanel, removeWhitelistButton, "whitelistEditor", removeWhitelistedPlayer)

	local addIgnoreButton = communicationWindow:recursiveGetChildById("buttonIgnoreAdd")

	function addIgnoreButton.onClick()
		createInlineEditor(ignoreListPanel, "ignoreEditor", "IgnoreListLabel", getIgnoredPlayers, addIgnoredPlayer)
	end

	local addWhitelistButton = communicationWindow:recursiveGetChildById("buttonWhitelistAdd")

	function addWhitelistButton.onClick()
		createInlineEditor(whiteListPanel, "whitelistEditor", "WhiteListLabel", getWhitelistedPlayers, addWhitelistedPlayer)
	end

	local saveButton = communicationWindow:recursiveGetChildById("buttonSave")

	function saveButton.onClick()
		communicationSettings.useIgnoreList = useIgnoreListBox:isChecked()
		communicationSettings.useWhiteList = useWhiteListBox:isChecked()
		communicationSettings.yelling = ignoreYellingBox:isChecked()
		communicationSettings.privateMessages = ignorePrivateMessageBox:isChecked()
		communicationSettings.allowVIPs = allowVIPsBox:isChecked()

		communicationWindow:destroy()
	end

	local cancelButton = communicationWindow:recursiveGetChildById("buttonCancel")

	function cancelButton.onClick()
		communicationWindow:destroy()
	end

	for _, name in ipairs(getIgnoredPlayers()) do
		createListEntry(ignoreListPanel, "IgnoreListLabel", name)
	end

	for _, name in ipairs(getWhitelistedPlayers()) do
		createListEntry(whiteListPanel, "WhiteListLabel", name)
	end
end

function online()
	defaultTab = addTab(tr("Local Chat"), true)
	serverTab = addTab(tr("Server Log"), false)

	if g_game.getClientVersion() >= 820 then
		local tab = addTab("NPCs", false)

		tab.npcChat = true
	end

	if g_game.getClientVersion() < 862 then
		Keybind.new("Dialogs", "Open Rule Violation", "Ctrl+R", "")

		local gameRootPanel = modules.game_interface.getRootPanel()

		Keybind.bind("Dialogs", "Open Rule Violation", {
			{
				type = KEY_DOWN,
				callback = openPlayerReportRuleViolationWindow
			}
		}, gameRootPanel)
	end

	local lastChannelsOpen = g_settings.getNode("lastChannelsOpen")

	if lastChannelsOpen then
		local savedChannels = lastChannelsOpen[g_game.getCharacterName()]

		if savedChannels then
			for channelName, channelId in pairs(savedChannels) do
				channelId = tonumber(channelId)

				if channelId ~= -1 and channelId < 100 and not channels[channelId] then
					g_game.joinChannel(channelId)
					table.insert(ignoredChannels, channelId)
				end
			end
		end
	end

	scheduleEvent(function()
		ignoredChannels = {}
	end, 3000)
end

function offline()
	temporaryChatViaEnter = false

	if consoleToggleChat and consoleTextEdit then
		switchChat(not consoleToggleChat.isChecked)
	end

	clear()
end

function onChannelEvent(channelId, name, type)
	local fmt = ChannelEventFormats[type]

	if not fmt then
		print(("Unknown channel event type (%d)."):format(type))

		return
	end

	local channel = channels[channelId]

	if channel then
		local tab = getTab(channel)

		if tab then
			addTabText(fmt:format(name), SpeakTypesSettings.channelOrange, tab)
		end
	end
end

function onTextChange(text)
	local player = g_game.getLocalPlayer()
	local tab = tab or getCurrentTab()

	if tab == defaultTab or tab == serverTab then
		if player then
			player:setTyping(text ~= "")
		end
	else
		player:setTyping(false)
	end
end

function setExtendedView(bool)
	if bool then
		consolePanel:setMarginRight(10)
		consolePanel:setMarginBottom(10)
		consolePanel:getChildById("extendedViewDraggable"):show()
		consolePanel:getChildById("extendedViewHide"):show()
		consolePanel:getChildById("extendedViewHide"):setChecked(not gameBottomPanel:isVisible())
	else
		consolePanel:setMarginRight(0)
		consolePanel:setMarginBottom(0)
		consolePanel:getChildById("extendedViewDraggable"):hide()
		consolePanel:getChildById("extendedViewHide"):hide()
		gameBottomPanel:show(true)
		destroyButtonChat()
	end

	gameBottomPanel:setDraggable(not bool)
end

function extendedViewDraggable(bool)
	gameBottomPanel:setDraggable(not bool)
end

function extendedViewCanSee(bool)
	local consoleTabBar = gameBottomPanel:getChildById("consolePanel"):getChildById("consoleTabBar")
	local consoleBuffer = consoleTabBar:getCurrentTab().tabPanel:getChildById("consoleBuffer")
	local children = gameBottomPanel:getChildren()

	if bool then
		for _, child in pairs(children) do
			child:setVisible(false)
		end

		consoleBuffer:setVisible(true)
		gameBottomPanel:setPhantom(true)
		gameBottomPanel:setVisible(true)
		gameBottomPanel:getChildById("consolePanel"):setVisible(true)

		for _, child in pairs(gameBottomPanel:getChildById("consolePanel"):getChildren()) do
			if child:getId() == "consoleContentPanel" then
				child:disable()
				child:setVisible(true)
				child.tabPanel.consoleScrollBar:setVisible(false)
			else
				child:setVisible(false)
			end
		end

		consoleTabBar:getCurrentTab().tabPanel:getChildById("consoleBuffer"):setImageSource("")
		gameBottomPanel:setImageSource("")
	else
		for _, child in pairs(gameBottomPanel:getChildById("consolePanel"):getChildren()) do
			if child:getId() == "consoleContentPanel" then
				child:enable()
				child:setVisible(false)
			end
		end
	end
end

function returnChat()
	local consoleTabBar = gameBottomPanel:getChildById("consolePanel"):getChildById("consoleTabBar")
	local consoleBuffer = consoleTabBar:getCurrentTab().tabPanel:getChildById("consoleBuffer")
	local children = gameBottomPanel:getChildren()

	for _, child in pairs(children) do
		if child:getId() == "cooldownWindow" then
			child:setVisible(modules.client_options.getOption("showSpellGroupCooldowns"))
		else
			child:setVisible(true)
		end
	end

	gameBottomPanel:getChildById("consolePanel"):setVisible(true)

	for _, child in pairs(gameBottomPanel:getChildById("consolePanel"):getChildren()) do
		if child:getId() ~= "consoleTextEdit" then
			child:setVisible(true)
		else
			child:setVisible(true)
			child:setEditable(not consoleToggleChat.isChecked)
			child:setFocusable(not consoleToggleChat.isChecked)
			child:setCursorVisible(not consoleToggleChat.isChecked)

			if consoleToggleChat.isChecked then
				child:setCursorPos(-1)
			end
		end
	end

	consoleTabBar:getCurrentTab().tabPanel:getChildById("consoleBuffer"):setImageSource("/images/ui/3pixel-frame-borderimage")
	gameBottomPanel:setImageSource("/images/ui/background_dark")
	gameBottomPanel:setPhantom(false)
end

function extendedViewHide(bool)
	if bool then
		gameBottomPanel:hide()
		createButtonChat()
		extendedViewCanSee(extendedViewButtonShowAlphaChat:isOn())
	else
		consolePanel:getChildById("extendedViewHide"):setChecked(false)
		gameBottomPanel:show(true)
		extendedViewCanSee(false)
		returnChat()

		if extendedViewButtonShowAlphaChat then
			extendedViewButtonShowAlphaChat:setOn(false)
		end

		destroyButtonChat()
	end
end

function createButtonChat()
	if extendedViewButtonToggleChat then
		return
	end

	local mapPanel = modules.game_interface.getMapPanel()
	local stringNameMobileOrPc = g_platform.isMobile() and "GameAction" or "MainToggleButton"

	extendedViewButtonToggleChat = g_ui.createWidget(stringNameMobileOrPc, mapPanel)

	extendedViewButtonToggleChat:setId("test")

	local hightMobileWidget = 0

	if g_platform.isMobile() then
		hightMobileWidget = modules.game_joystick.getPanel():getHeight()

		extendedViewButtonToggleChat.image:setImageSource("/images/game/mobile/chat")
		extendedViewButtonToggleChat:addAnchor(AnchorRight, "parent", AnchorRight)
		extendedViewButtonToggleChat:setMarginBottom(hightMobileWidget)
		extendedViewButtonToggleChat:setMarginRight(15)
		extendedViewButtonToggleChat:setMarginBottom(hightMobileWidget)
		extendedViewButtonToggleChat:setSize("60 60")
	else
		extendedViewButtonToggleChat:setIcon("/images/game/npcicons/icon_chat")
		extendedViewButtonToggleChat:setMarginBottom(10)
		extendedViewButtonToggleChat:setSize("30 23")
		extendedViewButtonToggleChat:addAnchor(AnchorLeft, "parent", AnchorLeft)
	end

	extendedViewButtonToggleChat:addAnchor(AnchorBottom, "parent", AnchorBottom)

	function extendedViewButtonToggleChat.onClick(a, b)
		extendedViewHide(modules.game_interface.currentViewMode ~= 2)
	end

	extendedViewButtonShowAlphaChat = g_ui.createWidget(stringNameMobileOrPc, mapPanel)

	extendedViewButtonShowAlphaChat:setIcon("/images/game/npcicons/icon_chat")
	extendedViewButtonShowAlphaChat:addAnchor(AnchorBottom, "parent", AnchorBottom)

	if g_platform.isMobile() then
		extendedViewButtonShowAlphaChat:setMarginBottom(hightMobileWidget)
		extendedViewButtonShowAlphaChat:setSize("60 60")
		extendedViewButtonShowAlphaChat:addAnchor(AnchorRight, "test", AnchorLeft)
	else
		extendedViewButtonShowAlphaChat:setSize("30 23")
		extendedViewButtonShowAlphaChat:addAnchor(AnchorLeft, "test", AnchorRight)
		extendedViewButtonShowAlphaChat:setMarginBottom(10)
	end

	extendedViewButtonShowAlphaChat:setMarginLeft(5)

	function extendedViewButtonShowAlphaChat.onClick(a, b)
		if extendedViewButtonShowAlphaChat:isOn() then
			extendedViewButtonShowAlphaChat:setOn(false)
		else
			extendedViewButtonShowAlphaChat:setOn(true)
		end

		extendedViewCanSee(extendedViewButtonShowAlphaChat:isOn())
	end
end

function destroyButtonChat()
	if extendedViewButtonToggleChat and not extendedViewButtonToggleChat:isDestroyed() then
		extendedViewButtonToggleChat:destroy()

		extendedViewButtonToggleChat = nil
	end

	if extendedViewButtonShowAlphaChat and not extendedViewButtonShowAlphaChat:isDestroyed() then
		extendedViewButtonShowAlphaChat:destroy()

		extendedViewButtonShowAlphaChat = nil
	end
end

function activateReadOnlyMode(channelName)
	activeactiveReadOnlyTabName = channelName

	setElidedChatWidgetText(readOnlyButton, channelName)
	readOnlyButton:setTooltip(channelName)
	copyMessagesToReadOnlyPanel(channelName)

	local tab = findTabByName(channelName)

	if tab then
		if tab.newMessageEvent then
			removeEvent(tab.newMessageEvent)

			tab.newMessageEvent = nil
		end

		if tab.isOnRedMessage then
			if consoleTabBar:getCurrentTab() == tab then
				tab:setColor("#dfdfdfff")
			else
				tab:setColor("#7f7f7fff")
			end

			tab.isOnRedMessage = false
		end
	end

	if not readOnlyModeEnabled then
		toggleReadOnlyMode()
	end
end

function onReadOnlyMouseClick()
	local contextMenu = g_ui.createWidget("PopupMenu")

	contextMenu:setGameMenu(true)

	if readOnlyModeEnabled and activeactiveReadOnlyTabName ~= "" then
		local sourceTab = findTabByName(activeactiveReadOnlyTabName)

		if sourceTab then
			addClonedMenuOptions(sourceTab, contextMenu, {
				readonly = true,
				close = true
			})
			contextMenu:addSeparator()
		end

		contextMenu:addOption(tr("Close Read-Only Tab"), function()
			clearReadOnlyTab()
			toggleReadOnlyMode()
		end)
	else
		for _, tab in pairs(consoleTabBar.tabs) do
			local tabName = getTabChannelName(tab)

			contextMenu:addOption(tr("Show " .. tabName), function()
				activateReadOnlyMode(tabName)
			end)
		end
	end

	contextMenu:display(mousePos)
end

function copyMessagesToReadOnlyPanel(channelName)
	local sourceTab = findTabByName(channelName)

	if not sourceTab then
		return
	end

	local readOnlyBuffer = readOnlyPanel:getChildById("panel")

	for _, child in pairs(readOnlyBuffer:getChildren()) do
		if child then
			child:destroy()

			child = nil
		end
	end

	local sourcePanel = consoleTabBar:getTabPanel(sourceTab)
	local sourceBuffer = sourcePanel:getChildById("consoleBuffer")

	for _, sourceLabel in pairs(sourceBuffer:getChildren()) do
		local clonedLabel = g_ui.createWidget("ConsoleLabel", readOnlyBuffer)

		clonedLabel:setId("consoleLabel" .. readOnlyBuffer:getChildCount())
		clonedLabel:setText(sourceLabel:getText())
		clonedLabel:setColor(sourceLabel:getColor())

		if sourceLabel.coloredText then
			clonedLabel:setColoredText(sourceLabel.coloredText)
		end
	end
end

function clearReadOnlyTab()
	if not readOnlyPanel then
		return
	end

	local panel = readOnlyPanel:getChildById("panel")

	if not panel then
		return
	end

	local layout = panel:getLayout()

	if layout then
		layout:disableUpdates()
	end

	panel:destroyChildren()

	if layout then
		layout:enableUpdates()
	end

	readOnlyButton:setIcon("")

	activeactiveReadOnlyTabName = ""
end

function setChannelMuted(channelName, muted)
	if muted then
		mutedChannels[channelName] = true
	else
		mutedChannels[channelName] = nil
	end
end

function toggleReadOnlyMode()
	if readOnlyModeEnabled then
		consoleContentPanel:removeAnchor(AnchorRight)
		consoleContentPanel:addAnchor(AnchorRight, "parent", AnchorRight)
		readOnlyPanel:hide()
		readOnlyButton:setText("")
		readOnlyButton:setIcon("/images/game/console/readOnly")
		readOnlyButton:setImageSource("")

		activeactiveReadOnlyTabName = ""
	else
		consoleContentPanel:removeAnchor(AnchorRight)
		consoleContentPanel:addAnchor(AnchorRight, "parent", AnchorHorizontalCenter)
		readOnlyPanel:show()
		readOnlyPanel:removeAnchor(AnchorLeft)
		readOnlyPanel:removeAnchor(AnchorRight)
		readOnlyPanel:addAnchor(AnchorLeft, "parent", AnchorHorizontalCenter)
		readOnlyPanel:addAnchor(AnchorRight, "parent", AnchorRight)
		readOnlyButton:removeAnchor(AnchorLeft)
		readOnlyButton:setIcon("")
		readOnlyButton:setImageSource("/images/ui/console_button")
	end

	readOnlyModeEnabled = not readOnlyModeEnabled
end

function addClonedMenuOptions(sourceTab, targetMenu, excludedOptions)
	excludedOptions = excludedOptions or {}

	local currentWorldName = g_game.getWorldName()
	local currentCharacterName = g_game.getCharacterName()
	local currentChannelName = getTabChannelName(sourceTab)

	if not excludedOptions.close then
		targetMenu:addOption(tr("Close"), function()
			removeTab(currentChannelName)
		end)
	end

	if not excludedOptions.readonly then
		if readOnlyModeEnabled and activeactiveReadOnlyTabName == currentChannelName then
			targetMenu:addOption(tr("Close read-only"), function()
				clearReadOnlyTab()
				toggleReadOnlyMode()
			end)
		else
			targetMenu:addOption(tr("Open read-only"), function()
				activateReadOnlyMode(currentChannelName)
			end)
		end
	end

	if not excludedOptions.separator1 then
		targetMenu:addSeparator()
	end

	if not excludedOptions.clear then
		targetMenu:addOption(tr("Clear Messages"), function()
			if readOnlyModeEnabled and activeactiveReadOnlyTabName == currentChannelName then
				clearTabByName(currentChannelName)
				copyMessagesToReadOnlyPanel(currentChannelName)
			else
				clearChannel(consoleTabBar)
			end
		end)
	end

	if not excludedOptions.save then
		targetMenu:addOption(tr("Save Messages"), function()
			saveChannelMessages(sourceTab, currentWorldName, currentCharacterName, currentChannelName)
		end)
	end
end

function saveChannelMessages(tab, worldName, characterName, channelName)
	local tabPanel = consoleTabBar:getTabPanel(tab)
	local consoleBuffer = tabPanel:getChildById("consoleBuffer")
	local messageLines = {}

	for _, label in pairs(consoleBuffer:getChildren()) do
		table.insert(messageLines, label:getText())
	end

	local fileName = worldName .. " - " .. characterName .. " - " .. channelName .. ".txt"
	local filePath = "/" .. fileName

	table.insert(messageLines, 1, os.date("\nChannel saved at %a %b %d %H:%M:%S %Y"))

	if g_resources.fileExists(filePath) then
		local existingContent = protectedcall(g_resources.readFileContents, filePath) or ""

		table.insert(messageLines, 1, existingContent)
	end

	g_resources.writeFileContents(filePath, table.concat(messageLines, "\n"))
	modules.game_textmessage.displayStatusMessage(tr("Channel appended to %s", fileName))
end

function clearTabByName(tabName)
	local tab = getTab(tabName)

	if tab then
		local panel = consoleTabBar:getTabPanel(tab)
		local consoleBuffer = panel:getChildById("consoleBuffer")

		consoleBuffer:destroyChildren()
	end
end

function getConsole()
	if consoleTextEdit and not consoleTextEdit:isDestroyed() then
		return consoleTextEdit
	end

	return consolePanel and consolePanel:recursiveGetChildById("consoleTextEdit")
end
