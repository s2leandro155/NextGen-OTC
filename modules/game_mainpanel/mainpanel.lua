-- chunkname: @/game_mainpanel/mainpanel.lua

local standModeBox, chaseModeBox
local optionsAmount = 0
local specialsAmount = 0
local storeAmount = 0
local chaseModeRadioGroup
local buttonConfigs = {}
local buttonOrder = {}

local function stripHotkey(text)
	if type(text) ~= "string" then
		return text
	end

	return text:gsub("%s*%b()$", "")
end

local function onShortcutsSidebarMousePress(_, mousePos, mouseButton)
	if mouseButton == MouseRightButton then
		if modules.client_options and modules.client_options.openManageShortcutsMenu then
			modules.client_options.openManageShortcutsMenu(mousePos)
		end

		return true
	end
end

local function bindShortcutsSidebarContextMenuRecursive(widget)
	if not widget or widget:isDestroyed() then
		return
	end

	widget.onMousePress = onShortcutsSidebarMousePress

	for _, child in pairs(widget:getChildren()) do
		bindShortcutsSidebarContextMenuRecursive(child)
	end
end

function refreshShortcutsSidebarContextMenu()
	if not optionsController or not optionsController.ui or not optionsController.ui.onPanel then
		return
	end

	local optionsPanel = optionsController.ui.onPanel.options

	if not optionsPanel or optionsPanel:isDestroyed() then
		return
	end

	optionsPanel:setPhantom(false)
	bindShortcutsSidebarContextMenuRecursive(optionsPanel)
end

ControlButtonNames = {
	bossSlot = "Boss Slots",
	preyButton = "Prey Dialog",
	trackerButton = "Bestiary Tracker",
	questLogButton = "Quest Log",
	battleButton = "Battle List",
	questTrackerButton = "Quest Tracker",
	analyticsSelectorWidget = "Analytics Selector",
	rewardWall = "Reward Wall",
	playerGuide = "Player Guide",
	eventScheduleButton = "Event Schedule",
	partyWidget = "Party List",
	skillsButton = "Skills",
	manageShortcuts = "Manage Shortcuts",
	friendsDialog = "Social",
	preyTrackerButton = "Kill Tracker",
	spellListWidget = "Spell List",
	imbuementTrackerButton = "Imbuement Tracker",
	taskBoard = "Task Board",
	linkedTasks = "Linked Tasks",
	highscoresButton = "Highscores",
	unjustifiedPointsButton = "Unjustified Points",
	helperDialog = "Helper",
	vipListButton = "VIP List",
	forgeButton = "Exaltation Forge",
	ProciencyButton = "Weapon Proficiency",
	CyclopediaButton = "Cyclopedia",
	wheelButton = "Wheel of Destiny",
	compendiumDialog = "Compendium",
	helperButton = "Helper Stats",
	bosstiarytrackerButton = "Bosstiary Tracker",
	bosstiary = "Bosstiary"
}

local PANEL_CONSTANTS = {
	ICON_HEIGHT = 18,
	ICON_WIDTH = 18,
	MAIN_RIGHT_PANEL_EXTRA_HEIGHT = 3,
	MULTI_STORE_HEIGHT = 20,
	HEIGHT_EXTRA_ONPANEL = -16,
	HEIGHT_EXTRA_SHRINK = -14,
	MAX_ICONS_PER_ROW = {
		STORE = 1,
		SPECIALS = 2,
		OPTIONS = 5
	}
}
local DEFAULT_SHORTCUT_ORDER = {
	"skillsButton",
	"battleButton",
	"spellListWidget",
	"vipListButton",
	"unjustifiedPointsButton",
	"questLogButton",
	"preyButton",
	"taskBoard",
	"linkedTasks",
	"CyclopediaButton",
	"highscoresButton",
	"ProciencyButton",
	"helperButton",
	"manageShortcuts"
}
local optionsShrink = false

local function calculatePanelHeight(panel, max_icons_per_row)
	local icon_count = 0

	for _, icon in ipairs(panel:getChildren()) do
		if icon:isVisible() then
			icon_count = icon_count + 1
		end
	end

	local rows = math.ceil(icon_count / max_icons_per_row)
	local height = rows * PANEL_CONSTANTS.ICON_HEIGHT + rows * 3

	if rows > 2 then
		height = height + rows - 2
	end

	return height, icon_count
end

function reloadMainPanelSizes()
	local main_panel = modules.game_interface.getMainRightPanel()
	local right_panel = modules.game_interface.getRightPanel()

	if not main_panel or not right_panel then
		return
	end

	local total_height = 1

	for _, panel in ipairs(main_panel:getChildren()) do
		if panel.panelHeight ~= nil then
			if panel:isVisible() then
				panel:setHeight(panel.panelHeight)

				total_height = total_height + panel.panelHeight

				if panel:getId() == "mainoptionspanel" then
					local store_panel = panel.onPanel.store
					local _, store_count = calculatePanelHeight(store_panel, PANEL_CONSTANTS.MAX_ICONS_PER_ROW.STORE)
					local store_height = 0

					if store_count > 0 then
						store_height = store_count * PANEL_CONSTANTS.MULTI_STORE_HEIGHT
					end

					store_panel:setHeight(store_height)

					if panel:isOn() then
						local options_panel = optionsController.ui.onPanel.options
						local options_height, _ = calculatePanelHeight(options_panel, PANEL_CONSTANTS.MAX_ICONS_PER_ROW.OPTIONS)
						local specials_panel = optionsController.ui.onPanel.specials
						local specials_height, _ = calculatePanelHeight(specials_panel, PANEL_CONSTANTS.MAX_ICONS_PER_ROW.SPECIALS)
						local separator = optionsController.ui.onPanel.optionsSeparator
						local controls_height = math.max(options_height, specials_height)

						options_panel:setHeight(controls_height)
						specials_panel:setHeight(controls_height)

						if separator then
							separator:setHeight(controls_height)
						end

						local controls_start_offset = store_height + options_panel:getMarginTop()
						local right_column_height = controls_start_offset + controls_height
						local combined_height = math.max(store_height, right_column_height) + PANEL_CONSTANTS.HEIGHT_EXTRA_ONPANEL

						panel:setHeight(combined_height + panel.panelHeight)

						total_height = total_height + combined_height
					else
						local combined_height = store_height + PANEL_CONSTANTS.HEIGHT_EXTRA_SHRINK

						panel:setHeight(combined_height + panel.panelHeight)

						total_height = total_height + combined_height
					end
				end
			else
				panel:setHeight(0)
			end
		end
	end

	main_panel:setHeight(total_height + PANEL_CONSTANTS.MAIN_RIGHT_PANEL_EXTRA_HEIGHT)
	right_panel:fitAll()
end

local function refreshOptionsSizes()
	local ui = optionsController.ui
	local offBtn = ui.offPanel:recursiveGetChildById("offOptionsSizeButton")
	local resizer = ui.onPanel:recursiveGetChildById("resizer")
	local optionsPanel = ui.onPanel:recursiveGetChildById("options")
	local specialsPanel = ui.onPanel:recursiveGetChildById("specials")
	local separator = ui.onPanel:recursiveGetChildById("optionsSeparator")

	ui.onPanel:show()

	if optionsShrink then
		ui:setOn(false)
		ui.offPanel:show()

		if optionsPanel then
			optionsPanel:hide()
		end

		if specialsPanel then
			specialsPanel:hide()
		end

		if separator then
			separator:hide()
		end

		if resizer then
			resizer:hide()
			resizer:setImageClip("0 20 42 20")
		end

		if offBtn then
			offBtn:setImageClip("0 0 42 20")
		end
	else
		ui:setOn(true)
		ui.offPanel:hide()

		if optionsPanel then
			optionsPanel:show()
		end

		if specialsPanel then
			specialsPanel:show()
		end

		if separator then
			separator:show()
		end

		if resizer then
			resizer:show()
			resizer:setImageClip("0 20 42 20")
		end

		if offBtn then
			offBtn:setImageClip("0 0 42 20")
		end
	end

	reloadMainPanelSizes()
end

local function createButton_large(id, description, image, callback, panelId, front)
	local panel = optionsController.ui.onPanel[panelId or "store"]

	storeAmount = storeAmount + 1

	local button = panel:getChildById(id)

	if not button then
		button = g_ui.createWidget("largeToggleButton")

		if front then
			panel:insertChild(1, button)
		else
			panel:addChild(button)
		end
	end

	button:setId(id)
	button:setTooltip(description)
	button:setImageSource(image)
	button:setImageClip("0 0 108 20")

	function button.onMouseRelease(widget, mousePos, mouseButton)
		if widget:containsPoint(mousePos) and mouseButton == MouseLeftButton then
			callback()

			return true
		end
	end

	return button
end

local function doFullSync()
	if not g_game.isOnline() then
		return
	end

	local optionsPanel = optionsController.ui.onPanel.options

	if not optionsPanel then
		return
	end

	for _, button in ipairs(optionsPanel:getChildren()) do
		local id = button:getId()

		if id then
			if not buttonConfigs[id] then
				local visible = table.find(buttonOrder, id) ~= nil

				buttonConfigs[id] = {
					visible = visible,
					tooltip = ControlButtonNames[id] or stripHotkey(button:getTooltip()) or id
				}
			end

			button:setVisible(buttonConfigs[id].visible)

			if buttonConfigs[id].visible and not table.find(buttonOrder, id) then
				table.insert(buttonOrder, id)
			end
		end
	end

	reorderButtons()
	reorderMainPanelSpecialButtons()

	if modules.client_topmenu and modules.client_topmenu.reorderTopRightToggleButtons then
		modules.client_topmenu.reorderTopRightToggleButtons()
	end

	reloadMainPanelSizes()

	if modules.client_options and modules.client_options.refreshShortcuts then
		modules.client_options.refreshShortcuts()
	end

	refreshShortcutsSidebarContextMenu()
end

local pendingFullSync = false

local function scheduleFullSync()
	if pendingFullSync or not g_game.isOnline() then
		return
	end

	pendingFullSync = true

	scheduleEvent(function()
		pendingFullSync = false

		doFullSync()
	end, 0)
end

local pendingRefreshOptionsSizes = false

local function scheduleRefreshOptionsSizes()
	if pendingRefreshOptionsSizes then
		return
	end

	pendingRefreshOptionsSizes = true

	addEvent(function()
		pendingRefreshOptionsSizes = false

		refreshOptionsSizes()
	end)
end

local function createButton(id, description, image, callback, special, front, index, styleName)
	local panel

	if special then
		panel = optionsController.ui.onPanel.specials
		specialsAmount = specialsAmount + 1
	else
		panel = optionsController.ui.onPanel.options
		optionsAmount = optionsAmount + 1
	end

	local button = panel:getChildById(id)

	if not button then
		button = g_ui.createWidget(styleName or "MainToggleButton")

		if front then
			panel:insertChild(1, button)
		else
			panel:addChild(button)
		end
	end

	button:setId(id)
	button:setTooltip(description)
	button:setSize("20 20")
	button:setImageSource(image)
	button:setImageClip("0 0 20 20")

	function button.onMouseRelease(widget, mousePos, mouseButton)
		if widget:containsPoint(mousePos) and mouseButton == MouseLeftButton then
			callback()

			return true
		end
	end

	if not button.index and type(index) == "number" then
		button.index = index or 1000
	end

	if not special then
		button:setVisible(false)

		if buttonConfigs[id] then
			button:setVisible(buttonConfigs[id].visible)
		end

		refreshShortcutsSidebarContextMenu()
	end

	if g_game.isOnline() then
		scheduleFullSync()
	else
		scheduleRefreshOptionsSizes()
	end

	return button
end

optionsController = Controller:new()

optionsController:setUI("mainoptionspanel", modules.game_interface.getMainRightPanel())

function optionsController:onInit()
	createButton_large("Store shop", tr("Open the Store"), "/images/options/store_large", toggleStore, "store", false)
	createButton_large("battlePassButton", tr("Battle Pass"), "/images/options/battlepass_large", function()
		local module = g_modules.getModule("game_battlepass")

		if module and not module:isLoaded() then
			g_modules.ensureModuleLoaded("game_battlepass")
		end

		if modules.game_battlepass and modules.game_battlepass.openOrPreview then
			modules.game_battlepass.openOrPreview()
		end
	end, "store", false)
	refreshShortcutsSidebarContextMenu()
end

function toggleStore()
	if modules.game_store and modules.game_store.toggle then
		modules.game_store.toggle()
	end
end

function optionsController:onTerminate()
	return
end

function optionsController:onGameStart()
	local config = loadButtonConfig()

	buttonConfigs = {}

	applyShortcutOrder(config.shortcutOrder)

	if SidebarPersistence and SidebarPersistence.getSection then
		local panelOptions = SidebarPersistence.getSection("sidebarPanelsOptions")

		if type(panelOptions) == "table" and panelOptions.controlButtonsVisible ~= nil then
			optionsShrink = panelOptions.controlButtonsVisible ~= true
		end
	end

	refreshOptionsSizes()
	modules.game_interface.setupOptionsMainButton()
	modules.client_options.setupOptionsMainButton()

	local getOptionsPanel = optionsController.ui.onPanel.options
	local children = getOptionsPanel:getChildren()

	table.sort(children, function(a, b)
		return (a.index or 1000) < (b.index or 1000)
	end)
	getOptionsPanel:reorderChildren(children)
	reorderButtons()
	reorderMainPanelSpecialButtons()
	reloadMainPanelSizes()
	scheduleFullSync()
	optionsController:scheduleEvent(function()
		doFullSync()
	end, 50, "onGameStart")
end

function optionsController:onGameEnd()
	return
end

function getControlButtonsVisible()
	return not optionsShrink
end

function setControlButtonsVisible(visible)
	local expanded = visible == true

	if not optionsShrink == expanded then
		return
	end

	optionsShrink = not expanded

	refreshOptionsSizes()
end

function changeOptionsSize()
	optionsShrink = not optionsShrink

	refreshOptionsSizes()
end

function addToggleButton(id, description, image, callback, front, index, styleName)
	return createButton(id, description, image, callback, false, front, index, styleName)
end

function addSpecialToggleButton(id, description, image, callback, front, index, styleName)
	return createButton(id, description, image, callback, true, front, index, styleName)
end

function addStoreButton(id, description, image, callback, front)
	return createButton_large(id, description, image, callback, "store", front)
end

function getButton(id)
	return optionsController.ui.onPanel.options:recursiveGetChildById(id)
end

function toggleExtendedViewButtons(extended)
	local optionsPanel = optionsController.ui.onPanel.options
	local specialsPanel = optionsController.ui.onPanel.store
	local rightGamePanel = modules.client_topmenu.getRightGameButtonsPanel()

	if extended then
		local optionChildren = optionsPanel:getChildren()

		for _, button in ipairs(optionChildren) do
			if not button:isDestroyed() then
				button.originalPanel = "options"

				rightGamePanel:addChild(button)
			end
		end

		local specialChildren = specialsPanel:getChildren()

		for _, button in ipairs(specialChildren) do
			if not button:isDestroyed() then
				button.originalPanel = "specials"

				rightGamePanel:addChild(button)
			end
		end

		optionsController.ui:hide()
		optionsController.ui:setHeight(0)
	else
		local children = rightGamePanel:getChildren()

		for _, button in ipairs(children) do
			if not button:isDestroyed() then
				if button.originalPanel == "options" then
					optionsPanel:addChild(button)
				elseif button.originalPanel == "specials" then
					specialsPanel:addChild(button)
				end
			end
		end

		optionsController.ui:show()
		optionsController.ui:setHeight(28)

		local mainRightPanel = modules.game_interface.getMainRightPanel()

		if mainRightPanel:hasChild(optionsController.ui) then
			mainRightPanel:moveChildToIndex(optionsController.ui, 4)
		end
	end

	refreshOptionsSizes()
end

function saveButtonConfig()
	return
end

local function isShortcutButtonConfiguredVisible(id, button)
	local cfg = buttonConfigs[id]

	if cfg and cfg.visible ~= nil then
		return cfg.visible
	end

	return button and button:isVisible() or false
end

function getShortcutOrder()
	local order = {}
	local seen = {}
	local optionsPanel = optionsController and optionsController.ui and optionsController.ui.onPanel and optionsController.ui.onPanel.options

	if not optionsPanel then
		return order
	end

	local function isShortcutVisible(id)
		return isShortcutButtonConfiguredVisible(id, optionsPanel:getChildById(id))
	end

	for _, id in ipairs(buttonOrder) do
		if type(id) == "string" and id ~= "" and not seen[id] and isShortcutVisible(id) then
			table.insert(order, id)

			seen[id] = true
		end
	end

	for _, button in ipairs(optionsPanel:getChildren()) do
		local id = button:getId()

		if id and id ~= "" and not seen[id] and isShortcutVisible(id) then
			table.insert(order, id)

			seen[id] = true
		end
	end

	return order
end

function applyShortcutOrder(order)
	local optionsPanel = optionsController and optionsController.ui and optionsController.ui.onPanel and optionsController.ui.onPanel.options

	if not optionsPanel then
		return
	end

	buttonOrder = {}

	if type(order) == "table" then
		for _, id in ipairs(order) do
			if type(id) == "string" and id ~= "" then
				table.insert(buttonOrder, id)
			end
		end
	end

	local visibleSet = {}

	for _, id in ipairs(buttonOrder) do
		visibleSet[id] = true
	end

	for _, button in ipairs(optionsPanel:getChildren()) do
		local id = button:getId()

		if id and id ~= "" then
			local visible = visibleSet[id] == true

			button:setVisible(visible)

			local displayName = ControlButtonNames[id] or stripHotkey(button:getTooltip()) or id

			if not buttonConfigs[id] then
				buttonConfigs[id] = {
					visible = visible,
					tooltip = displayName
				}
			else
				buttonConfigs[id].visible = visible
			end
		end
	end

	reorderButtons()
	reloadMainPanelSizes()
	refreshShortcutsSidebarContextMenu()
end

function loadButtonConfig()
	local shortcutOrder

	if SidebarPersistence and SidebarPersistence.getSection then
		local panelOptions = SidebarPersistence.getSection("sidebarPanelsOptions")

		if type(panelOptions) == "table" and type(panelOptions.shortcutOrder) == "table" then
			shortcutOrder = panelOptions.shortcutOrder
		end
	end

	shortcutOrder = shortcutOrder or DEFAULT_SHORTCUT_ORDER

	-- The Task Board backend and client module are available, but older sidebar
	-- settings were saved before its shortcut existed. Add it once to those
	-- layouts so players can actually discover and open the system.
	if not table.find(shortcutOrder, "taskBoard") then
		table.insert(shortcutOrder, "taskBoard")
	end
	if not table.find(shortcutOrder, "linkedTasks") then
		table.insert(shortcutOrder, "linkedTasks")
	end

	return {
		shortcutOrder = shortcutOrder
	}
end

function reorderMainPanelSpecialButtons()
	if not optionsController or not optionsController.ui or not optionsController.ui.onPanel then
		return
	end

	local panel = optionsController.ui.onPanel.specials

	if not panel or panel:isDestroyed() then
		return
	end

	local orderIds = {
		"optionsMainButton"
	}
	local byId = {}

	for _, ch in ipairs(panel:getChildren()) do
		local id = ch:getId()

		if id and id ~= "" then
			byId[id] = ch
		end
	end

	local out, used = {}, {}

	for _, id in ipairs(orderIds) do
		local w = byId[id]

		if w then
			out[#out + 1] = w
			used[w] = true
		end
	end

	local rest = {}

	for id, w in pairs(byId) do
		if not used[w] then
			rest[#rest + 1] = id
		end
	end

	table.sort(rest)

	for _, id in ipairs(rest) do
		out[#out + 1] = byId[id]
	end

	if #out > 0 then
		panel:reorderChildren(out)
	end
end

function reorderButtons()
	if not g_game.isOnline() then
		return
	end

	local optionsPanel = optionsController.ui.onPanel.options
	local children = {}

	for _, id in ipairs(buttonOrder) do
		local button = optionsPanel:getChildById(id)

		if button then
			table.insert(children, button)
		end
	end

	for _, button in ipairs(optionsPanel:getChildren()) do
		local id = button:getId()

		if not table.find(buttonOrder, id) then
			table.insert(children, button)
		end
	end

	optionsPanel:reorderChildren(children)
	refreshShortcutsSidebarContextMenu()
end

function getMainPanelButtonsInfo()
	local buttons = {}
	local optionsPanel = optionsController.ui.onPanel.options

	if optionsPanel then
		for _, button in ipairs(optionsPanel:getChildren()) do
			local id = button:getId()

			if id then
				table.insert(buttons, {
					id = id,
					tooltip = ControlButtonNames[id] or stripHotkey(button:getTooltip()) or id,
					visible = isShortcutButtonConfiguredVisible(id, button)
				})
			end
		end
	end

	return buttons, buttonOrder
end

function setMainPanelButtonVisible(id, visible)
	local optionsPanel = optionsController.ui.onPanel.options

	if not optionsPanel then
		return
	end

	local button = optionsPanel:getChildById(id)

	if button then
		button:setVisible(visible)

		local displayName = ControlButtonNames[id] or stripHotkey(button:getTooltip()) or id

		if not buttonConfigs[id] then
			buttonConfigs[id] = {
				visible = visible,
				tooltip = displayName
			}
		else
			buttonConfigs[id].visible = visible
		end

		if visible then
			if not table.find(buttonOrder, id) then
				table.insert(buttonOrder, id)
			end
		else
			table.removevalue(buttonOrder, id)
		end

		saveButtonConfig()
		reorderButtons()
		reloadMainPanelSizes()
	end
end

function setMainPanelButtonOrder(order)
	buttonOrder = order

	reorderButtons()
	saveButtonConfig()
end

function resetMainPanelButtons()
	buttonConfigs = {}
	buttonOrder = {}

	local optionsPanel = optionsController.ui.onPanel.options

	if optionsPanel then
		for _, button in ipairs(optionsPanel:getChildren()) do
			local id = button:getId()

			if id then
				button:setVisible(false)

				buttonConfigs[id] = {
					visible = false,
					tooltip = ControlButtonNames[id] or stripHotkey(button:getTooltip()) or id
				}
			end
		end
	end

	saveButtonConfig()
	reloadMainPanelSizes()
end
