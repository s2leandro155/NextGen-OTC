-- chunkname: @/game_wheel/wheel.lua

wheelWindow = nil
wheelOfDestinyWindow = nil
gemAtelierWindow = nil
fragmentWindow = nil
newPresetWindow = nil
renamePresetWindow = nil
exportCodeWindow = nil
deletePresetWindow = nil
checkSavePresetWindow = nil
selectedNewPresetRadio = nil

local summaryVisible = false
local presetTabSelection = "informationButton"

wheelPanel = nil
centerReferencePoint = nil

if not SkillwheelStringsLibrary then
	SkillwheelStringsLibrary = {}
end

local function onGameStart()
	if g_game.getClientVersion() >= 1310 then
		local ret = WheelOfDestiny.loadWheelPresets()

		if not ret then
			print("[wheel] Error loading wheel presets")
		end
	else
		scheduleEvent(function()
			g_modules.getModule("game_wheel"):unload()
		end, 100)
	end
end

-- Building the whole wheel UI moved from init() to here and deferred until the FIRST opening.
-- Reason (measured): the wheelMenu/gemMenu/fragmentMenu styles load ~500 PNGs (~98 MB of pixels
-- in RAM + ~500 decodes) into a window that init hides anyway - EVERY client startup paid
-- for this, including the login screen itself.
function ensureWheelWindows()
	if wheelWindow then
		return
	end

	wheelWindow = g_ui.displayUI("wheel")
	mainPanel = wheelWindow:getChildById("mainPanel")

	-- The module is sandboxed, so callbacks declared inside wheel.otui cannot
	-- resolve this module's loadMenu function through the global environment.
	-- Bind the tab callbacks here, inside the module environment.
	local optionsTabBar = wheelWindow:getChildById("optionsTabBar")
	optionsTabBar:getChildById("wheelMenu").onClick = function()
		loadMenu("wheelMenu")
	end
	optionsTabBar:getChildById("gemMenu").onClick = function()
		loadMenu("gemMenu")
	end
	optionsTabBar:getChildById("fragmentMenu").onClick = function()
		loadMenu("fragmentMenu")
	end

	wheelOfDestinyWindow = g_ui.loadUI("styles/wheelMenu", mainPanel)

	wheelOfDestinyWindow:hide()

	gemAtelierWindow = g_ui.loadUI("styles/gemMenu", mainPanel)

	gemAtelierWindow:hide()

	local affinitiesBox = gemAtelierWindow:recursiveGetChildById("affinitiesBox")
	local qualitiesBox = gemAtelierWindow:recursiveGetChildById("qualitiesBox")

	if affinitiesBox then
		function affinitiesBox.onOptionChange(widget, text, data)
			if GemAtelier and GemAtelier.onSortAffinity then
				GemAtelier.onSortAffinity(widget, widget.currentIndex)
			end
		end
	end

	if qualitiesBox then
		function qualitiesBox.onOptionChange(widget, text, data)
			if GemAtelier and GemAtelier.onSortQuality then
				GemAtelier.onSortQuality(widget, widget.currentIndex)
			end
		end
	end

	fragmentWindow = g_ui.loadUI("styles/fragmentMenu", mainPanel)

	fragmentWindow:hide()

	newPresetWindow = g_ui.displayUI("styles/newPreset")

	newPresetWindow:hide()

	renamePresetWindow = g_ui.displayUI("styles/renamePreset")

	renamePresetWindow:hide()
	loadConfigJson()

	selectedNewPresetRadio = UIRadioGroup.create()

	selectedNewPresetRadio:addWidget(newPresetWindow.contentPanel.useEmpty)
	selectedNewPresetRadio:addWidget(newPresetWindow.contentPanel.copyPreset)
	selectedNewPresetRadio:addWidget(newPresetWindow.contentPanel.import)
	selectedNewPresetRadio:selectWidget(newPresetWindow.contentPanel.import)

	selectedNewPresetRadio.onSelectionChange = WheelOfDestiny.onNewPresetSelectionChange

	local addOneButton = wheelOfDestinyWindow:recursiveGetChildById("addOne")
	local rmvOneButton = wheelOfDestinyWindow:recursiveGetChildById("rmvOne")

	g_mouse.bindAutoPress(addOneButton, function()
		onAddOne()
	end, 500, nil)
	g_mouse.bindAutoPress(rmvOneButton, function()
		onRmvOne()
	end, 500, nil)
	loadMenu("wheelMenu")
	toggleTabBarButtons("informationButton")
	hide()
end

-- Server data may arrive before the window exists (e.g. openWheel from show()) - the proxy
-- builds the UI on demand. The same ref must go to connect and disconnect.
local function onDestinyWheelProxy(...)
	ensureWheelWindows()
	return WheelOfDestiny.onDestinyWheel(...)
end

function init()
	-- cheap json with strings - we load it right away so that potential external consumers
	-- of SkillwheelStringsLibrary do not depend on whether the wheel was already opened
	loadConfigJson()

	connect(g_game, {
		onGameEnd = onGameEnd,
		onGameStart = onGameStart,
		onDestinyWheel = onDestinyWheelProxy,
		onResourcesBalanceChange = onResourceBalance
	})

	if modules.game_mainpanel then
		wheelButton = modules.game_mainpanel.addToggleButton("wheelButton", tr("Wheel of Destiny"), "/images/options/button_skillwheeldialog", toggle, false, 10)

		wheelButton:setOn(false)
	end
end

function terminate()
	disconnect(g_game, {
		onGameEnd = onGameEnd,
		onGameStart = onGameStart,
		onDestinyWheel = onDestinyWheelProxy,
		onResourcesBalanceChange = onResourceBalance
	})

	if wheelWindow then
		if g_modalManager then
			g_modalManager.hide(wheelWindow)
		end

		wheelWindow:destroy()

		wheelWindow = nil
	end

	if wheelButton then
		wheelButton:destroy()

		wheelButton = nil
	end
end

function showWheelWindow()
	ensureWheelWindows()
	wheelWindow:show(true)

	if g_modalManager then
		g_modalManager.show(wheelWindow)
	end

	wheelWindow:raise()
	wheelWindow:focus()
end

function hideWheelWindow()
	if not wheelWindow then
		return
	end

	if g_modalManager then
		g_modalManager.hide(wheelWindow)
	end

	wheelWindow:ungrabMouse()
	wheelWindow:ungrabKeyboard()
	wheelWindow:hide()
end

function toggle()
	ensureWheelWindows()

	if wheelWindow:isVisible() then
		hide()
	else
		wheelWindow:focus()
		loadMenu("wheelMenu")

		if gemAtelierWindow:isVisible() then
			gemAtelierWindow:hide()
		end

		if fragmentWindow:isVisible() then
			fragmentWindow:hide()
		end

		g_game.openWheel(g_game.getLocalPlayer():getId())
		wheelWindow:recursiveGetChildById("tabContent"):setVisible(false)
		WheelOfDestiny.onRemoveClick()
	end
end

function setWheelButtonOn(on)
	if wheelButton then
		wheelButton:setOn(on)
	end
end

function hide()
	if not wheelWindow then
		if wheelButton then
			wheelButton:setOn(false)
		end

		return
	end

	WheelOfDestiny.setPreviewMode(false)
	hideWheelWindow()

	if wheelButton then
		wheelButton:setOn(false)
	end
end

function onGameEnd()
	hide()
	WheelOfDestiny.saveWheelPresets()

	-- the UI may have never been created (lazy-init) - then there is nothing to hide
	if not wheelWindow then
		WheelOfDestiny.currentPreset = {}

		return
	end

	newPresetWindow:hide()
	renamePresetWindow:hide()

	if exportCodeWindow then
		exportCodeWindow:destroy()

		exportCodeWindow = nil
	end

	if exportCodeWindow then
		exportCodeWindow:destroy()

		exportCodeWindow = nil
	end

	if checkSavePresetWindow then
		checkSavePresetWindow:destroy()

		checkSavePresetWindow = nil
	end

	WheelOfDestiny.currentPreset = {}
end

function show()
	g_game.openWheel(g_game.getLocalPlayer():getId())
end

function openForPlayer(playerId)
	ensureWheelWindows()

	local id = playerId

	if not id or id == 0 then
		local player = g_game.getLocalPlayer()

		if not player then
			return
		end

		id = player:getId()
	end

	wheelWindow:focus()
	loadMenu("wheelMenu")

	if gemAtelierWindow:isVisible() then
		gemAtelierWindow:hide()
	end

	if fragmentWindow:isVisible() then
		fragmentWindow:hide()
	end

	g_game.openWheel(id)
	wheelWindow:recursiveGetChildById("tabContent"):setVisible(false)
	WheelOfDestiny.onRemoveClick()
end

function onWheelClick(position)
	WheelOfDestiny.onWheelClick(position)
end

function loadMenu(menuId)
	if wheelOfDestinyWindow:isVisible() then
		wheelOfDestinyWindow:hide()
	end

	if gemAtelierWindow:isVisible() then
		gemAtelierWindow:hide()
	end

	if newPresetWindow:isVisible() then
		newPresetWindow:hide()
	end

	if fragmentWindow:isVisible() then
		fragmentWindow:hide()
	end

	wheelMenuButton = wheelWindow.optionsTabBar:getChildById("wheelMenu")
	gemMenuButton = wheelWindow.optionsTabBar:getChildById("gemMenu")
	fragmentMenuButton = wheelWindow.optionsTabBar:getChildById("fragmentMenu")

	if menuId == "wheelMenu" then
		gemAtelierWindow:hide()
		fragmentWindow:hide()

		wheelPanel = wheelOfDestinyWindow:getChildById("wheelPanel")
		wheelPanel.onMouseMove = WheelOfDestiny.onMouseMove
		centerReferencePoint = wheelOfDestinyWindow:recursiveGetChildById("centerReferencePoint")

		wheelMenuButton:setChecked(true)
		gemMenuButton:setChecked(false)
		fragmentMenuButton:setChecked(false)

		local informationButton = wheelWindow.mainPanel.wheelMenu.info.presetTabBar:getChildById("informationButton")
		local managePresetsButton = wheelWindow.mainPanel.wheelMenu.info.presetTabBar:getChildById("managePresetsButton")
		local summaryButton = wheelWindow.mainPanel.wheelMenu.dedicationPerks:getChildById("summaryButton")
		local summaryOpenedButton = wheelWindow.mainPanel.wheelMenu.summary:getChildById("summaryButton")

		function informationButton.onClick()
			toggleTabBarButtons("informationButton")
		end

		function managePresetsButton.onClick()
			toggleTabBarButtons("managePresetsButton")
			scheduleEvent(function()
				WheelOfDestiny.configurePresets()
			end, 50)
		end

		function summaryButton.onClick()
			toggleSummary()
		end

		function summaryOpenedButton.onClick()
			toggleSummary()
		end

		toggleTabBarButtons("informationButton")

		if WheelOfDestiny.lastSelectedGemVessel and WheelOfDestiny.lastSelectedGemVessel:isVisible() then
			local currentDomain = WheelOfDestiny.lastSelectedGemVessel:getId():gsub("selectVessel", "")

			WheelOfDestiny.onGemVesselClick(tonumber(currentDomain))
		end

		Workshop.createFragments()
		wheelOfDestinyWindow:show(true)
	elseif menuId == "gemMenu" then
		Workshop.createFragments()
		GemAtelier.resetFields()
		GemAtelier.showGems(true)
		gemAtelierWindow:show(true)
		wheelMenuButton:setChecked(false)
		fragmentMenuButton:setChecked(false)
		gemMenuButton:setChecked(true)
	elseif menuId == "fragmentMenu" then
		Workshop.createFragments()
		Workshop.showFragmentList(true)
		fragmentWindow:show(true)
		wheelMenuButton:setChecked(false)
		gemMenuButton:setChecked(false)
		fragmentMenuButton:setChecked(true)
	end
end

function toggleSummary()
	summaryVisible = not summaryVisible

	local summaryPanel = wheelWindow.mainPanel.wheelMenu:getChildById("summary")
	local dedicationPerksPanel = wheelWindow.mainPanel.wheelMenu:getChildById("dedicationPerks")
	local convictionPerksPanel = wheelWindow.mainPanel.wheelMenu:getChildById("convictionPerks")
	local vesselsPanel = wheelWindow.mainPanel.wheelMenu:getChildById("vessels")
	local revelationPerksPanel = wheelWindow.mainPanel.wheelMenu:getChildById("revelationPerks")

	summaryPanel:setVisible(summaryVisible)
	dedicationPerksPanel:setVisible(not summaryVisible)
	convictionPerksPanel:setVisible(not summaryVisible)
	vesselsPanel:setVisible(not summaryVisible)
	revelationPerksPanel:setVisible(not summaryVisible)
	WheelOfDestiny.configureSummary()
end

local function refreshPresetTabButtonClip(button)
	local buttonId = button:getId()
	local isSmall = buttonId == "informationButton" and presetTabSelection == "managePresetsButton" or buttonId == "managePresetsButton" and presetTabSelection == "informationButton"

	if buttonId == "managePresetsButton" and not button:isEnabled() then
		button:setImageClip(torect("0 68 34 34"))

		return
	end

	if isSmall then
		local clipY = button:isHovered() and 34 or 0

		button:setImageClip(torect(string.format("0 %d 34 34", clipY)))
	else
		button:setImageClip(torect("0 0 174 34"))
	end
end

function onPresetTabButtonHoverChange(button, hovered)
	refreshPresetTabButtonClip(button)

	if g_tooltip and g_tooltip.onWidgetHoverChange then
		g_tooltip.onWidgetHoverChange(button, hovered)
	end
end

function refreshPresetTabBarButtons()
	local presetTabBar = wheelWindow.mainPanel.wheelMenu.info.presetTabBar

	refreshPresetTabButtonClip(presetTabBar:getChildById("informationButton"))
	refreshPresetTabButtonClip(presetTabBar:getChildById("managePresetsButton"))
end

function toggleTabBarButtons(selectedButtonId)
	presetTabSelection = selectedButtonId

	local informationButton = wheelWindow.mainPanel.wheelMenu.info.presetTabBar:getChildById("informationButton")
	local managePresetsButton = wheelWindow.mainPanel.wheelMenu.info.presetTabBar:getChildById("managePresetsButton")
	local tabContent = wheelWindow.mainPanel.wheelMenu.info.tabContent

	if selectedButtonId == "informationButton" then
		informationButton:setSize(tosize("174 34"))
		informationButton:setImageSource("/images/game/wheel/informationSelection")
		managePresetsButton:setSize(tosize("34 34"))
		managePresetsButton:setImageSource("/images/game/wheel/small_manage_button")
		tabContent.manage:setVisible(false)
		tabContent.information:setVisible(true)
	elseif selectedButtonId == "managePresetsButton" then
		informationButton:setSize(tosize("34 34"))
		informationButton:setImageSource("/images/game/wheel/small_information_button")
		managePresetsButton:setSize(tosize("174 34"))
		managePresetsButton:setImageSource("/images/game/wheel/manageSelect")
		tabContent.information:setVisible(false)
		tabContent.manage:setVisible(true)
	end

	refreshPresetTabButtonClip(informationButton)
	refreshPresetTabButtonClip(managePresetsButton)
end

function onResourceBalance()
	if not wheelWindow or not wheelWindow:isVisible() then
		return true
	end

	local player = g_game.getLocalPlayer()
	local bankMoney = player:getResourceBalance(ResourceTypes.BANK_BALANCE)
	local characterMoney = player:getResourceBalance(ResourceTypes.GOLD_EQUIPPED)
	local lesserFragment = player:getResourceBalance(ResourceTypes.LESSER_FRAGMENTS)
	local greaterFragment = player:getResourceBalance(ResourceTypes.GREATER_FRAGMENTS)
	local value = bankMoney + characterMoney

	wheelWindow.moneyPanel.gold:setText(formatMoney(value, ","))
	wheelWindow.lesserFragmentPanel.gold:setText(lesserFragment)
	wheelWindow.greaterFragmentPanel.gold:setText(greaterFragment)
end

function loadConfigJson()
	local file = "/json/SkillwheelStringsJsonLibrary.json"

	if g_resources.fileExists(file) then
		local status, result = pcall(function()
			return json.decode(g_resources.readFileContents(file))
		end)

		if not status then
			return g_logger.debug("Error while reading characterdata file. Details: " .. result)
		end

		SkillwheelStringsLibrary = result
	end
end
