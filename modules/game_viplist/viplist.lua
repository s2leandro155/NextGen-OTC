-- chunkname: @/game_viplist/viplist.lua

vipWindow = nil
vipButton = nil
addVipWindow = nil
editVipWindow = nil
vipInfo = {}
addGroupWindow = nil
vipGroups = {}
maxVipGroups = 5
editableGroupCount = 1

local globalSettings = {
	hideOfflineVips = false,
	showGrouped = false,
	vipSortOrder = {}
}

local function normalizeVipSortForSave(value)
	if value == "type" or value == "byType" then
		return "byType"
	elseif value == "status" or value == "byState" then
		return "byState"
	end

	return "byName"
end

function getVipWidgetConfig()
	return {
		hideOfflineVips = globalSettings.hideOfflineVips == true,
		showGrouped = globalSettings.showGrouped == true,
		vipSortOrder = normalizeVipSortForSave(globalSettings.vipSortOrder and globalSettings.vipSortOrder[1])
	}
end

local function loadVipWidgetConfigFromSidebar()
	globalSettings.showGrouped = false
	globalSettings.hideOfflineVips = false
	globalSettings.vipSortOrder = {}

	if not SidebarPersistence or not SidebarPersistence.getSection then
		return
	end

	local section = SidebarPersistence.getSection("vipWidgetOptions")

	if type(section) ~= "table" then
		return
	end

	globalSettings.showGrouped = section.showGrouped == true
	globalSettings.hideOfflineVips = section.hideOfflineVips == true

	if type(section.vipSortOrder) == "string" and section.vipSortOrder ~= "" then
		globalSettings.vipSortOrder = {
			section.vipSortOrder
		}
	end
end

local function saveVipWidgetConfigToSidebar()
	if not SidebarPersistence or not SidebarPersistence.active then
		return
	end

	if type(SidebarPersistence.document) ~= "table" then
		return
	end

	local section = SidebarPersistence.document.vipWidgetOptions

	if type(section) ~= "table" then
		section = {}
		SidebarPersistence.document.vipWidgetOptions = section
	end

	local cfg = getVipWidgetConfig()

	section.hideOfflineVips = cfg.hideOfflineVips
	section.showGrouped = cfg.showGrouped
	section.vipSortOrder = cfg.vipSortOrder
end

local syncVipMainPanelButton

local function vipStatusDisplayText(vipState)
	if vipState == VipState.Online then
		return tr("Online")
	elseif vipState == VipState.Pending then
		return tr("Pending")
	elseif vipState == VipState.Offline then
		return tr("Offline")
	elseif vipState == VipState.Training then
		return tr("Exercise Dummy Training")
	end

	return tr("Offline")
end

local function getStoredVipDescription(widget)
	local desc = widget.vipDescription

	if desc and desc ~= "" then
		return desc
	end

	local t = widget:getTooltip() or ""

	if t == "" or t:find("Status:", 1, true) then
		return ""
	end

	return t
end

local function applyVipListLabelTooltip(widget)
	if not widget or widget:isDestroyed() then
		return
	end

	local name = widget:getText()

	if not name or name == "" then
		return
	end

	local lines = {
		tr("Name: %s", name),
		tr("Status: %s", vipStatusDisplayText(widget.vipState))
	}
	local desc = widget.vipDescription

	if desc and desc ~= "" then
		table.insert(lines, desc)
	end

	widget:setTooltip(table.concat(lines, "\n"))
end

controllerVip = Controller:new()

function controllerVip:onInit()
	Keybind.new("Windows", "Show/hide VIP list", "Ctrl+P", "")
	Keybind.bind("Windows", "Show/hide VIP list", {
		{
			type = KEY_DOWN,
			callback = toggle
		}
	})

	vipButton = modules.game_mainpanel.addToggleButton("vipListButton", tr("Open VIP List"), "/images/options/button_vip_list", toggle, false, 3)
	vipWindow = g_ui.loadUI("viplist")

	controllerVip:registerEvents(g_game, {
		onAddVip = onAddVip,
		onVipStateChange = onVipStateChange,
		onVipGroupChange = onVipGroupChange
	})
	refresh()
	vipWindow:setup()

	local toggleFilterButton = vipWindow:recursiveGetChildById("toggleFilterButton")

	if toggleFilterButton then
		toggleFilterButton:setVisible(false)
		toggleFilterButton:setOn(false)
	end

	local contextMenuButton = vipWindow:recursiveGetChildById("contextMenuButton")
	local minimizeButton = vipWindow:recursiveGetChildById("minimizeButton")

	if contextMenuButton and minimizeButton then
		contextMenuButton:addAnchor(AnchorTop, minimizeButton:getId(), AnchorTop)
		contextMenuButton:addAnchor(AnchorRight, minimizeButton:getId(), AnchorLeft)
		contextMenuButton:setMarginRight(5)

		function contextMenuButton.onClick(widget, mousePos, mouseButton)
			return onVipListMousePress(widget, mousePos or widget:getPosition(), MouseRightButton)
		end
	end

	local lockButton = vipWindow:recursiveGetChildById("lockButton")

	if lockButton and contextMenuButton then
		lockButton:addAnchor(AnchorTop, contextMenuButton:getId(), AnchorTop)
		lockButton:addAnchor(AnchorRight, contextMenuButton:getId(), AnchorLeft)
		lockButton:setMarginRight(2)
	end

	local newWindowButton = vipWindow:recursiveGetChildById("newWindowButton")

	if newWindowButton then
		newWindowButton:setVisible(false)
	end

	if g_game.isOnline() then
		vipWindow:setupOnStart()
	end

	syncVipMainPanelButton()
end

function controllerVip:onTerminate()
	Keybind.delete("Windows", "Show/hide VIP list")

	local ArrayWidgets = {
		addVipWindow,
		editVipWindow,
		vipWindow,
		vipButton,
		addGroupWindow
	}

	for _, widget in ipairs(ArrayWidgets) do
		if widget ~= nil or widget then
			widget:destroy()

			widget = nil
		end
	end

	vipInfo = {}
end

function controllerVip:onGameStart()
	loadVipWidgetConfigFromSidebar()

	if not g_game.getFeature(GameAdditionalVipInfo) then
		loadVipInfo()
	end

	if not g_game.getFeature(GameVipGroups) then
		vipWindow.miniborder:hide()

		globalSettings.showGrouped = false
	else
		vipInfo = {}
	end

	vipWindow:setupOnStart()
	refresh()
	syncVipMainPanelButton()
end

function controllerVip:onGameEnd()
	saveVipWidgetConfigToSidebar()

	if not g_game.getFeature(GameVipGroups) then
		saveVipInfo()
	end

	if not SidebarPersistence or not SidebarPersistence.lastSessionActive then
		vipWindow:setParent(nil, true)
	end

	clear()

	if editVipWindow then
		editVipWindow:destroy()

		editVipWindow = nil
	end

	if addGroupWindow then
		addGroupWindow:destroy()

		addGroupWindow = nil
	end
end

function loadVipInfo()
	local settings = g_settings.getNode("VipList")

	if not settings then
		vipInfo = {}

		return
	end

	vipInfo = settings.VipInfo or {}
end

function saveVipInfo()
	if not g_game.getFeature(GameAdditionalVipInfo) then
		if not g_settings.getNode("VipList") then
			g_settings.setNode("VipList", {})
		end

		local settings = {}

		settings.VipInfo = vipInfo

		g_settings.mergeNode("VipList", settings)
	end
end

function refresh()
	clear()

	for id, vip in pairs(g_game.getVips()) do
		onAddVip(id, unpack(vip))
	end

	vipWindow:setContentMinimumHeight(38)
end

function clear()
	local vipList = vipWindow:getChildById("contentsPanel")

	vipList:destroyChildren()

	if not g_game.isOnline() and g_game.getFeature(GameAdditionalVipInfo) then
		vipInfo = {}
		vipGroups = {}
	end

	if editVipWindow ~= nil or editVipWindow then
		editVipWindow:hide()
	end
end

function syncVipMainPanelButton()
	if SidebarWidgetOptions and SidebarWidgetOptions.syncToggleButton then
		SidebarWidgetOptions.syncToggleButton(vipWindow, vipButton, "Open VIP List", "Close VIP List")

		return
	end

	if not vipButton or vipButton:isDestroyed() then
		return
	end

	local on = false

	if vipWindow and not vipWindow:isDestroyed() then
		on = vipWindow:isVisible()
	end

	vipButton:setOn(on)

	if vipButton.setTooltip then
		vipButton:setTooltip(tr(on and "Close VIP List" or "Open VIP List"))
	end
end

function toggle()
	if vipButton:isOn() then
		vipWindow:closeAndForgetLayout()
	else
		if not vipWindow:getParent() then
			local panel = modules.game_interface.findContentPanelAvailable(vipWindow, vipWindow:getMinimumHeight())

			if not panel then
				return
			end

			panel:addChild(vipWindow)
		end

		vipWindow:open()
	end

	syncVipMainPanelButton()
end

function onMiniWindowOpen()
	syncVipMainPanelButton()
end

function onMiniWindowClose()
	syncVipMainPanelButton()
end

local function focusFloatingNameInput(window, nameInput, selectAll)
	if not window or window:isDestroyed() or not nameInput or nameInput:isDestroyed() then
		return
	end

	window:raise()
	window:focus()
	window:grabKeyboard()
	window:focusChild(nameInput, KeyboardFocusReason)

	if selectAll then
		nameInput:selectAll()
	else
		nameInput:setCursorPos(-1)
	end
end

function createAddWindow()
	if addVipWindow then
		addVipWindow:destroy()

		addVipWindow = nil
	end

	addVipWindow = g_ui.displayUI("addvip")

	addVipWindow:show()

	local nameInput = addVipWindow:getChildById("name")

	nameInput:setText("")
	focusFloatingNameInput(addVipWindow, nameInput)
	scheduleEvent(function()
		focusFloatingNameInput(addVipWindow, nameInput)
	end, 50)

	local function closeWindow()
		pcall(function()
			addVipWindow:ungrabKeyboard()
		end)
		nameInput:setText("")
		addVipWindow:setVisible(false)
		addVipWindow:destroy()

		addVipWindow = nil
	end

	function addVipWindow.buttonOk.onClick()
		local playerName = nameInput:getText()

		if playerName and playerName ~= "" then
			g_game.addVip(playerName)
		end

		closeWindow()
	end

	addVipWindow.closeButton.onClick = closeWindow
	addVipWindow.onEscape = closeWindow

	function nameInput.onKeyDown(widget, keyCode, keyboardModifiers)
		if g_keyboard.isEnterKey(keyCode) then
			addVipWindow.buttonOk.onClick()

			return true
		elseif keyCode == KeyEscape then
			closeWindow()

			return true
		end

		return false
	end
end

function createEditWindow(widget)
	if editVipWindow then
		return
	end

	editVipWindow = g_ui.displayUI("editvip")

	local name = widget:getText()
	local id = widget:getId():sub(4)

	if not g_game.getFeature(GameVipGroups) then
		editVipWindow:setText("Edit VIP")
		editVipWindow:setSize("272 170")
	else
		local editVipBaseWidth = 285
		local editVipBaseHeight = 301
		local editVipHeightPerGroup = 15

		editVipWindow:setSize(string.format("%d %d", editVipBaseWidth, editVipBaseHeight + editVipHeightPerGroup * #vipGroups))
	end

	editVipWindow.groups:destroyChildren()
	table.sort(vipGroups, function(a, b)
		return a[1] > b[1]
	end)

	for _, group in ipairs(vipGroups) do
		local groupBox = g_ui.createWidget("VipGroupBox", editVipWindow.groups)

		groupBox:setText(group[2])

		groupBox.id = group[1]

		groupBox:setChecked(checkPlayerGroup(name, group[1]))
	end

	local okButton = editVipWindow:getChildById("buttonOK")
	local cancelButton = editVipWindow:getChildById("buttonCancel")
	local nameLabel = editVipWindow:getChildById("nameLabel")

	nameLabel:setText(name)

	local descriptionTextId = g_game.getFeature(GameVipGroups) and "descriptionText" or "descriptionTextLegacy"
	local descriptionText = editVipWindow:getChildById(descriptionTextId)

	descriptionText:appendText(getStoredVipDescription(widget))

	local notifyCheckBox = editVipWindow:recursiveGetChildById("checkBoxNotify")

	notifyCheckBox:setChecked(widget.notifyLogin)

	local iconRadioGroup = UIRadioGroup.create()

	for i = VipIconFirst, VipIconLast do
		iconRadioGroup:addWidget(editVipWindow:recursiveGetChildById("icon" .. i))
	end

	if not widget.iconId then
		widget.iconId = 0
	end

	iconRadioGroup:selectWidget(editVipWindow:recursiveGetChildById("icon" .. widget.iconId))

	local function cancelFunction()
		editVipWindow:destroy()
		iconRadioGroup:destroy()

		editVipWindow = nil
	end

	local function saveFunction()
		local vipList = vipWindow:getChildById("contentsPanel")

		if not widget then
			cancelFunction()

			return
		end

		local name = widget:getText()
		local state = widget.vipState
		local description = descriptionText:getText()
		local iconId = tonumber(iconRadioGroup:getSelectedWidget():getId():sub(5))

		iconId = iconId or 0

		local notify = notifyCheckBox:isChecked()
		local groups = {}

		for _, child in pairs(editVipWindow.groups:getChildren()) do
			if child:isChecked() then
				table.insert(groups, child.id)
			end
		end

		if g_game.getFeature(GameAdditionalVipInfo) then
			g_game.editVip(id, description, iconId, notify, groups)
		elseif notify ~= false or #description > 0 or iconId > 0 then
			vipInfo[name] = {
				description = description,
				iconId = iconId,
				notifyLogin = notify
			}
		else
			vipInfo[name] = nil
		end

		widget:destroy()
		onAddVip(id, name, state, description, iconId, notify, groups, nil)

		if iconRadioGroup then
			iconRadioGroup:destroy()

			iconRadioGroup = nil
		end

		if editVipWindow then
			editVipWindow:destroy()

			editVipWindow = nil
		end
	end

	cancelButton.onClick = cancelFunction
	okButton.onClick = saveFunction
	editVipWindow.onEscape = cancelFunction
	editVipWindow.onEnter = saveFunction
end

function destroyAddWindow()
	if addVipWindow then
		addVipWindow:setVisible(false)
		addVipWindow:destroy()

		addVipWindow = nil
	end
end

function addVip()
	if addVipWindow then
		local nameInput = addVipWindow:getChildById("name")
		local playerName = nameInput:getText()

		if playerName and playerName ~= "" then
			g_game.addVip(playerName)
			destroyAddWindow()
		end
	end
end

local function removeVipFromInfo(playerId, name)
	if g_game.getFeature(GameAdditionalVipInfo) then
		for key, data in pairs(vipInfo) do
			if type(data) == "table" and tonumber(data.playerId) == playerId then
				vipInfo[key] = nil

				return
			end
		end
	end

	if name then
		vipInfo[name] = nil
	end
end

function removeVip(widgetOrName)
	if not widgetOrName then
		return
	end

	local widget
	local vipList = vipWindow:getChildById("contentsPanel")

	if type(widgetOrName) == "string" then
		local entries = vipList:getChildren()

		for i = 1, #entries do
			if entries[i]:getText():lower() == widgetOrName:lower() then
				widget = entries[i]

				break
			end
		end

		if not widget then
			return
		end
	else
		widget = widgetOrName
	end

	if widget then
		local id = tonumber(widget:getId():sub(4))

		if not id then
			return
		end

		local name = widget:getText()

		g_game.removeVip(id)
		removeVipFromInfo(id, name)
		saveVipInfo()
		refresh()
	end
end

function hideOffline(state)
	globalSettings.hideOfflineVips = state

	refresh()
end

function isHiddingOffline()
	local settings = g_settings.getNode("VipList")

	if not settings then
		return false
	end

	return settings.hideOffline
end

function getSortedBy()
	if g_game.getFeature(GameAdditionalVipInfo) then
		if not globalSettings.vipSortOrder then
			return ""
		end

		return globalSettings.vipSortOrder[1]
	else
		local settings = g_settings.getNode("VipList")

		if not settings or not settings.sortedBy then
			return "status"
		end

		return settings.sortedBy
	end
end

function sortBy(state)
	if not g_game.getFeature(GameAdditionalVipInfo) then
		local settings = {}

		settings.sortedBy = state

		g_settings.mergeNode("VipList", settings)
	end

	for i, v in ipairs(globalSettings.vipSortOrder) do
		if v == state then
			table.remove(globalSettings.vipSortOrder, i)

			break
		end
	end

	table.insert(globalSettings.vipSortOrder, 1, state)

	local contentPanel = vipWindow:getChildById("contentsPanel")

	if g_game.getFeature(GameVipGroups) and globalSettings.showGrouped then
		for _, groupWidget in ipairs(contentPanel:getChildren()) do
			if groupWidget:getId():find("group-") == 1 then
				local groupPanel = groupWidget:getChildById("panel")
				local children = groupPanel:getChildren()

				table.sort(children, compareVips)

				for i, child in ipairs(children) do
					groupPanel:moveChildToIndex(child, i)
				end
			end
		end
	else
		local children = contentPanel:getChildren()

		table.sort(children, compareVips)

		for i, child in ipairs(children) do
			contentPanel:moveChildToIndex(child, i)
		end
	end

	contentPanel:updateLayout()
end

function compareVips(a, b)
	for _, orderType in ipairs(globalSettings.vipSortOrder) do
		if orderType == "byState" or orderType == "status" then
			if a.vipState ~= nil and b.vipState ~= nil and a.vipState ~= b.vipState then
				return a.vipState > b.vipState
			end
		elseif orderType == "byName" or orderType == "name" then
			if a:getText() ~= nil and b:getText() ~= nil and a:getText():lower() ~= b:getText():lower() then
				return a:getText():lower() < b:getText():lower()
			end
		elseif (orderType == "byType" or orderType == "type") and a.iconId ~= nil and b.iconId ~= nil and a.iconId ~= b.iconId then
			return a.iconId > b.iconId
		end
	end

	return false
end

function onAddVip(id, name, state, description, iconId, notify, groupID, bool)
	if g_game.getFeature(GameAdditionalVipInfo) then
		vipInfo[name] = {
			playerId = id,
			playerName = name,
			vipState = state,
			vipDesc = description,
			icon = iconId,
			hasNotify = notify,
			vipGroups = groupID
		}

		if globalSettings.showGrouped then
			showGroups()

			return
		end
	end

	local vipList = vipWindow:getChildById("contentsPanel")
	local childrenContentPanel = vipList:getChildCount()

	if bool then
		for i = 1, childrenContentPanel do
			local vipName = vipList:getChildByIndex(i)

			if vipName:getText() == name then
				setVipState(vipName, state)

				if state == VipState.Online then
					vipName:setVisible(true)
				elseif state == VipState.Offline and globalSettings.hideOfflineVips then
					vipName:setVisible(false)
				end

				return
			end
		end
	end

	for j = 1, childrenContentPanel do
		if vipList:getChildByIndex(j):getText() == name then
			return
		end
	end

	local label = g_ui.createWidget("VipListLabel")

	label.onMousePress = onVipListLabelMousePress

	label:setId("vip" .. id)
	label:setText(name)

	if not g_game.getFeature(GameAdditionalVipInfo) then
		local tmpVipInfo = vipInfo[name]

		label.iconId = 0
		label.notifyLogin = false
		label.vipDescription = ""

		if tmpVipInfo then
			if tmpVipInfo.iconId then
				label:setImageClip(torect(tmpVipInfo.iconId * 12 .. " 0 12 12"))

				label.iconId = tmpVipInfo.iconId
			end

			if tmpVipInfo.description then
				label.vipDescription = tmpVipInfo.description
			end

			label.notifyLogin = tmpVipInfo.notifyLogin or false
		end
	else
		label.vipDescription = description or ""

		label:setImageClip(torect(iconId * 12 .. " 0 12 12"))

		label.iconId = iconId
		label.notifyLogin = notify
	end

	setVipState(label, state)
	label:setPhantom(false)
	connect(label, {
		onDoubleClick = function()
			g_game.openPrivateChannel(label:getText())

			return true
		end
	})

	if state == VipState.Offline and globalSettings.hideOfflineVips then
		label:setVisible(false)
	end

	local nameLower = name:lower()
	local childrenCount = vipList:getChildCount()

	for i = 1, childrenCount do
		local child = vipList:getChildByIndex(i)

		if state == VipState.Online and child.vipState ~= VipState.Online and getSortedBy() == "status" or label.iconId > child.iconId and getSortedBy() == "type" then
			vipList:insertChild(i, label)

			return
		end

		if (state ~= VipState.Online and child.vipState ~= VipState.Online or state == VipState.Online and child.vipState == VipState.Online) and getSortedBy() == "status" or label.iconId == child.iconId and getSortedBy() == "type" or getSortedBy() == "name" then
			local childText = child:getText():lower()
			local length = math.min(childText:len(), nameLower:len())

			for j = 1, length do
				if nameLower:byte(j) < childText:byte(j) then
					vipList:insertChild(i, label)

					return
				elseif nameLower:byte(j) > childText:byte(j) then
					break
				elseif j == nameLower:len() then
					vipList:insertChild(i, label)

					return
				end
			end
		end
	end

	vipList:insertChild(childrenCount + 1, label)
end

function onVipStateChange(id, state, groupID)
	if g_game.getFeature(GameVipGroups) and globalSettings.showGrouped then
		local name, description, iconId, notify = searchPlayerbyId(id)

		onAddVip(id, name, state, description, iconId, notify, groupID, true)
	else
		local vipList = vipWindow:getChildById("contentsPanel")
		local label = vipList:getChildById("vip" .. id)
		local name = label:getText()
		local description = getStoredVipDescription(label)
		local iconId = label.iconId
		local notify = label.notifyLogin

		label:destroy()
		onAddVip(id, name, state, description, iconId, notify)
	end

	if notify and state ~= VipState.Pending then
		modules.game_textmessage.displayFailureMessage(state == VipState.Online and tr("%s has logged in.", name) or tr("%s has logged out.", name))
	end
end

function onVipListMousePress(widget, mousePos, mouseButton)
	if mouseButton ~= MouseRightButton then
		return
	end

	local vipList = vipWindow:getChildById("contentsPanel")
	local menu = g_ui.createWidget("PopupMenu")

	menu:setGameMenu(true)
	menu:addOption(tr("Add new VIP"), function()
		createAddWindow()
	end)
	menu:addSeparator()

	if g_game.getFeature(GameVipGroups) then
		menu:addOption(tr("Add new group"), function()
			createAddGroupWindow()
		end)
	end

	menu:addSeparator()
	menu:addOption(tr("Sort by name"), function()
		sortBy("name")
	end)
	menu:addOption(tr("Sort by type"), function()
		sortBy("type")
	end)
	menu:addOption(tr("Sort by status"), function()
		sortBy("status")
	end)

	if not globalSettings.hideOfflineVips then
		menu:addOption(tr("Hide offline VIPs"), function()
			hideOffline(true)
		end)
	else
		menu:addOption(tr("Show offline VIPs"), function()
			hideOffline(false)
		end)
	end

	if g_game.getFeature(GameVipGroups) then
		if not globalSettings.showGrouped then
			menu:addOption(tr("Show groups"), function()
				globalSettings.showGrouped = true

				showGroups()
			end)
		else
			menu:addOption(tr("Hide groups"), function()
				globalSettings.showGrouped = false

				refresh()
			end)
		end
	end

	local menuPos = {
		x = mousePos.x,
		y = mousePos.y
	}
	local menuSize = menu:getSize()
	local screenSize = g_window.getSize()

	if menuPos.x + menuSize.width > screenSize.width then
		menuPos.x = screenSize.width - menuSize.width
	end

	if menuPos.y + menuSize.height > screenSize.height then
		menuPos.y = screenSize.height - menuSize.height
	end

	if menuPos.x < 0 then
		menuPos.x = 0
	end

	if menuPos.y < 0 then
		menuPos.y = 0
	end

	menu:display(menuPos)

	return true
end

function onVipListLabelMousePress(widget, mousePos, mouseButton)
	if mouseButton ~= MouseRightButton then
		return
	end

	local vipList = vipWindow:getChildById("contentsPanel")
	local isGroup = string.find(widget:getId(), "group")
	local isVip = string.find(widget:getId(), "vip")
	local menu = g_ui.createWidget("PopupMenu")

	menu:setGameMenu(true)

	if not isGroup then
		if isVip and widget.vipState == VipState.Online then
			menu:addOption(tr("Exiva %s", widget:getText()), function()
				g_game.talk(string.format("exiva \"%s\"", widget:getText()), true)
			end)
		end

		menu:addOption(tr("Edit %s", widget:getText()), function()
			if widget then
				createEditWindow(widget)
			end
		end)
		menu:addOption(tr("Remove %s", widget:getText()), function()
			if widget then
				removeVip(widget)
			end
		end)

		if isVip and widget.vipState == VipState.Online then
			menu:addOption(tr("Message to %s", widget:getText()), function()
				g_game.openPrivateChannel(widget:getText())
			end)
			menu:addOption(tr("Invite %s to Party", widget:getText()), function()
				local player = g_game.getLocalPlayer()
				local targetName = widget:getText()
				local targetCreature

				if player then
					for _, creature in ipairs(g_map.getSpectators(player:getPosition(), false) or {}) do
						if creature:isPlayer() and creature:getName():lower() == targetName:lower() then
							targetCreature = creature
							break
						end
					end
				end

				if targetCreature then
					g_game.partyInvite(targetCreature:getId())
				else
					displayInfoBox(tr("Invite to Party"), tr("%s must be visible on your screen to be invited.", targetName))
				end
			end)
		end
	end

	menu:addOption(tr("Add new VIP"), function()
		createAddWindow()
	end)

	if g_game.getFeature(GameVipGroups) then
		menu:addSeparator()

		if isGroup and widget.editable then
			local groupName = widget:getTooltip() and widget:getTooltip() or widget.group:getText()

			menu:addOption(tr("Edit group %s", groupName), function()
				createEditGroupWindow(groupName, widget.groupId)
			end)
			menu:addOption(tr("Remove group %s", groupName), function()
				g_game.editVipGroups(3, widget.groupId, "")
			end)
		end

		menu:addOption(tr("Add new group"), function()
			createAddGroupWindow()
		end)
	end

	menu:addSeparator()
	menu:addOption(tr("Sort by name"), function()
		sortBy("name")
	end)
	menu:addOption(tr("Sort by type"), function()
		sortBy("type")
	end)
	menu:addOption(tr("Sort by status"), function()
		sortBy("status")
	end)

	if not globalSettings.hideOfflineVips then
		menu:addOption(tr("Hide offline VIPs"), function()
			hideOffline(true)
		end)
	else
		menu:addOption(tr("Show offline VIPs"), function()
			hideOffline(false)
		end)
	end

	if g_game.getFeature(GameVipGroups) then
		if not globalSettings.showGrouped then
			menu:addOption(tr("Show groups"), function()
				globalSettings.showGrouped = true

				showGroups()
			end)
		else
			menu:addOption(tr("Hide groups"), function()
				globalSettings.showGrouped = false

				refresh()
			end)
		end
	end

	if not isGroup then
		menu:addSeparator()
		menu:addOption(tr("Copy Name"), function()
			g_window.setClipboardText(widget:getText())
		end)
	end

	local menuPos = {
		x = mousePos.x,
		y = mousePos.y
	}
	local menuSize = menu:getSize()
	local screenSize = g_window.getSize()

	if menuPos.x + menuSize.width > screenSize.width then
		menuPos.x = screenSize.width - menuSize.width
	end

	if menuPos.y + menuSize.height > screenSize.height then
		menuPos.y = screenSize.height - menuSize.height
	end

	if menuPos.x < 0 then
		menuPos.x = 0
	end

	if menuPos.y < 0 then
		menuPos.y = 0
	end

	menu:display(menuPos)

	return true
end

function onVipGroupChange(vipGroupsArray, groupsAmountLeft)
	vipGroups = vipGroupsArray
	maxVipGroups = groupsAmountLeft
	editableGroupCount = groupsAmountLeft

	refresh()
end

function createAddGroupWindow()
	if maxVipGroups < 1 then
		displayInfoBox(tr("Maximum of User-Created Groups Reached"), "You have already reached the maximum of groups you can create yourself.")

		return
	end

	if addGroupWindow then
		addGroupWindow:destroy()

		addGroupWindow = nil
	end

	addGroupWindow = g_ui.displayUI("addgroup")

	addGroupWindow:show()

	local nameInput = addGroupWindow:getChildById("name")

	nameInput:setText("")
	focusFloatingNameInput(addGroupWindow, nameInput)
	scheduleEvent(function()
		focusFloatingNameInput(addGroupWindow, nameInput)
	end, 50)

	local function closeWindow()
		destroyAddGroupWindow()
	end

	addGroupWindow.closeButton.onClick = closeWindow
	addGroupWindow.onEscape = closeWindow

	function nameInput.onKeyDown(widget, keyCode, keyboardModifiers)
		if g_keyboard.isEnterKey(keyCode) then
			addGroup()

			return true
		elseif keyCode == KeyEscape then
			closeWindow()

			return true
		end

		return false
	end
end

function createEditGroupWindow(groupName, groupId)
	if addGroupWindow then
		addGroupWindow:destroy()

		addGroupWindow = nil
	end

	addGroupWindow = g_ui.displayUI("addgroup")

	addGroupWindow:show()

	local headerLabel = addGroupWindow:getChildById("headerLabel")

	if headerLabel then
		headerLabel:setText(tr("Edit VIP Group"))
	end

	local nameInput = addGroupWindow:getChildById("name")

	nameInput:setText(groupName)
	focusFloatingNameInput(addGroupWindow, nameInput, true)
	scheduleEvent(function()
		focusFloatingNameInput(addGroupWindow, nameInput, true)
	end, 50)

	local function closeWindow()
		pcall(function()
			addGroupWindow:ungrabKeyboard()
		end)
		nameInput:setText("")
		addGroupWindow:setVisible(false)
		addGroupWindow:destroy()

		addGroupWindow = nil
	end

	function addGroupWindow.buttonOk.onClick()
		local newGroupName = nameInput:getText()

		if newGroupName and newGroupName ~= "" then
			g_game.editVipGroups(2, groupId, newGroupName)
		end

		closeWindow()
	end

	addGroupWindow.closeButton.onClick = closeWindow
	addGroupWindow.onEscape = closeWindow

	function nameInput.onKeyDown(widget, keyCode, keyboardModifiers)
		if g_keyboard.isEnterKey(keyCode) then
			addGroupWindow.buttonOk.onClick()

			return true
		elseif keyCode == KeyEscape then
			closeWindow()

			return true
		end

		return false
	end
end

function addGroup()
	if addGroupWindow then
		local nameInput = addGroupWindow:getChildById("name")
		local groupName = nameInput:getText()

		if groupName and groupName ~= "" then
			g_game.editVipGroups(1, 0, groupName)
			destroyAddGroupWindow()
		end
	end
end

function destroyAddGroupWindow()
	if addGroupWindow then
		pcall(function()
			addGroupWindow:ungrabKeyboard()
		end)
		addGroupWindow:destroy()

		addGroupWindow = nil
	end
end

function editGroup(groupId)
	g_game.editVipGroups(2, groupId, addGroupWindow:getChildById("name"):getText())
	destroyAddGroupWindow()
end

function getPlayersByGroup(groupId)
	local playerFromGroupID = {}

	for id, data in pairs(vipInfo) do
		if data.vipGroups and table.contains(data.vipGroups, groupId) then
			table.insert(playerFromGroupID, data)
		end
	end

	return playerFromGroupID
end

function getPlayersNoGroup()
	local playerFromNoGroup = {}

	for id, data in pairs(vipInfo) do
		if not data.vipGroups or #data.vipGroups == 0 then
			table.insert(playerFromNoGroup, data)
		end
	end

	return playerFromNoGroup
end

function showGroups(sortType)
	local contentsPanel = vipWindow:getChildById("contentsPanel")

	contentsPanel:destroyChildren()
	table.sort(vipGroups, function(a, b)
		return a[2] < b[2]
	end)

	local function createPlayerWidget(group, player)
		if not player.playerId then
			return
		end

		local playerWidget = g_ui.createWidget("VipListLabel", group.panel)

		playerWidget.onMousePress = onVipListLabelMousePress

		playerWidget:setId("vip" .. player.playerId)
		playerWidget:setText(player.playerName)
		playerWidget:setImageClip(torect(player.icon * 12 .. " 0 12 12"))

		playerWidget.iconId = player.icon
		playerWidget.notifyLogin = player.hasNotify
		playerWidget.vipDescription = player.vipDesc or ""

		setVipState(playerWidget, player.vipState)
		playerWidget:setPhantom(false)
		connect(playerWidget, {
			onDoubleClick = function()
				g_game.openPrivateChannel(playerWidget:getText())

				return true
			end
		})

		return playerWidget
	end

	for _, group in ipairs(vipGroups) do
		local groupId, groupName, isEditable = group[1], group[2], group[3]
		local playersInGroup = getPlayersByGroup(groupId)

		if #playersInGroup > 0 then
			local groupWidget = g_ui.createWidget("VipGroupList", contentsPanel)

			groupWidget.group:setText(groupName)

			if #groupName >= 18 then
				groupWidget:setTooltip(groupName)
			end

			groupWidget:setId("group-" .. groupId)

			groupWidget.onMousePress = onVipListLabelMousePress
			groupWidget.groupId = groupId
			groupWidget.editable = isEditable

			local visiblePlayers = 0

			for _, player in ipairs(playersInGroup) do
				if player.icon == nil then
					break
				end

				local playerWidget = createPlayerWidget(groupWidget, player)

				if player.vipState == VipState.Offline and globalSettings.hideOfflineVips then
					playerWidget:setVisible(false)
				else
					visiblePlayers = visiblePlayers + 1
				end
			end

			if visiblePlayers == 0 then
				groupWidget:hide()
			else
				groupWidget:setSize("156 " .. 16 * visiblePlayers + groupWidget:getHeight())
			end
		end
	end

	local playersNoGroup = getPlayersNoGroup()

	if #playersNoGroup > 0 then
		local noGroupWidget = g_ui.createWidget("VipGroupList", contentsPanel)

		noGroupWidget.onMousePress = onVipListLabelMousePress

		noGroupWidget:setId("group")

		local visiblePlayers = 0

		for _, player in ipairs(playersNoGroup) do
			local playerWidget = createPlayerWidget(noGroupWidget, player)

			if player.vipState == VipState.Offline and globalSettings.hideOfflineVips then
				playerWidget:setVisible(false)
			else
				visiblePlayers = visiblePlayers + 1
			end
		end

		if visiblePlayers == 0 then
			noGroupWidget:hide()
		else
			noGroupWidget:setSize("156 " .. 15 * visiblePlayers + noGroupWidget:getHeight())
		end
	end

	sortBy(getSortedBy())
end

function setVipState(widget, vipState)
	widget.vipState = vipState

	if vipState == VipState.Online then
		widget:setColor("#5ff75f")
	end

	if vipState == VipState.Pending then
		widget:setColor("#ffca38")
	elseif vipState == VipState.Offline then
		widget:setColor("#f75f5f")
	elseif vipState == VipState.Training then
		widget:setColor("#9966cc")
	end

	applyVipListLabelTooltip(widget)
end

function getPlayerGroups(playerName)
	local playerGroups = {}

	for id, vip in pairs(g_game.getVips()) do
		if vip[1] == playerName then
			playerGroups = vip[6]

			break
		end
	end

	return playerGroups
end

function checkPlayerGroup(playerName, groupId)
	local vips = g_game.getVips()

	for _, vip in pairs(vips) do
		if vip[1] == playerName then
			local playerGroups = vip[6]

			for _, playerGroup in ipairs(playerGroups) do
				if playerGroup == groupId then
					return true
				end
			end

			return false
		end
	end

	return false
end

function searchPlayerbyId(playerId)
	for key, idCache in pairs(vipInfo) do
		if tonumber(idCache.playerId) == playerId then
			local name = idCache.playerName
			local description = idCache.vipDesc
			local iconId = idCache.icon
			local notify = idCache.hasNotify

			return name, description, iconId, notify
		end
	end
end
