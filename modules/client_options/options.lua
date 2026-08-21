-- chunkname: @/client_options/options.lua

local options = dofile("data_options")
local CATEGORY_BASE_HEIGHT = 22
local SUBCATEGORY_HEIGHT = 20
local ROTATE_HOLD_KEYS = {
	rotateHoldAlt = true,
	rotateHoldShift = true,
	rotateHoldCtrl = true
}

local function normalizeRotateHoldOption(value)
	if value == true then
		return true
	end

	if value == false or value == nil then
		return false
	end

	if type(value) == "string" then
		local l = value:lower()

		return l == "true" or l == "1" or l == "yes"
	end

	if type(value) == "number" then
		return value ~= 0
	end

	return not not value
end

local hasAtLeastOneRotateHoldModifier, showRotateHoldWarning
local UNUSED_EXPIRY_HELP_DEFAULT = tr("Check this box to see how much time or how many charges are left\non items that have not been used yet.")
local UNUSED_EXPIRY_HELP_DISABLED = tr("This option is only available when \"Show Expiry In Containers\" is enabled.\n\nCheck this box to see how much time or how many charges are left\non items that have not been used yet.")

function updateShowExpiryOnUnusedAvailability(panelsArg, showExpiryInContainersEnabled)
	local p = panelsArg or panels

	if not p or not p.interface then
		return
	end

	local unusedCb = p.interface:recursiveGetChildById("showExpiryOnUnusedItems")
	local help = p.interface:recursiveGetChildById("showExpiryOnUnusedItemsHelp")

	if unusedCb then
		unusedCb:setEnabled(showExpiryInContainersEnabled)
	end

	if help then
		if showExpiryInContainersEnabled then
			help:setImageSource("/images/icons/show_gui_help_grey")
			help:setTooltip(UNUSED_EXPIRY_HELP_DEFAULT)
		else
			help:setImageSource("/images/icons/show_gui_help_orange")
			help:setTooltip(UNUSED_EXPIRY_HELP_DISABLED)
		end
	end
end

local BIG_CURSOR_TOOLTIP_DEFAULT = tr("Enable this option if you prefer to see a bigger mouse cursor. This\nmight be especially useful for high resolution screens.")
local BIG_CURSOR_TOOLTIP_DISABLED = tr("This option is only available when \"Use Native Mouse Cursor\" is disabled.\n\nEnable this option if you prefer to see a bigger mouse cursor. This\nmight be especially useful for high resolution screens.")
local HUD_ENABLED_COLOR = "#c0c0c0ff"
local HUD_DISABLED_COLOR = "#707070ff"
local HUD_IMAGE_COLOR = "#ffffffff"
local HUD_IMAGE_DEFAULT_COLOR = "#dfdfdfff"
local OWN_HUD_DEPENDENT_OPTIONS = {
	"showOwnBars",
	"showOwnName",
	"showOwnHealth",
	"showOwnMana",
	"showOwnHarmony",
	"showManaShield",
	"showOwnMarks"
}
local OWN_BAR_DEPENDENT_OPTIONS = {}
local OWN_MANA_SHIELD_OPTIONS = {
	"manaShieldNextToHealth",
	"manaShieldNextToMana"
}
local OWN_HARMONY_OPTIONS = {
	"harmonyNextToHealth",
	"harmonyNextToMana"
}
local updatingManaShieldPlacement = false
local suppressManaShieldPlacementOptionWrite = false
local updatingHarmonyPlacement = false
local suppressHarmonyPlacementOptionWrite = false
local OTHER_HUD_DEPENDENT_OPTIONS = {
	"showOtherName",
	"showOtherHealth",
	"showOtherMarks",
	"showOtherNpcIcons"
}

local function setHudDependentOptionState(panel, id, enabled)
	if not panel then
		return
	end

	local widget = panel:recursiveGetChildById(id)

	if not widget then
		return
	end

	widget:setEnabled(enabled)
	widget:setColor(enabled and HUD_ENABLED_COLOR or HUD_DISABLED_COLOR)
	widget:setImageColor(enabled and HUD_IMAGE_DEFAULT_COLOR or HUD_IMAGE_COLOR)
	widget:setOpacity(1)
end

function updateHudDependencyAvailability(panelsArg, ownHudEnabled, otherHudEnabled, ownBarsEnabled, manaShieldSubEnabled, harmonySubEnabled)
	local p = panelsArg or panels

	if not p or not p.interfaceHUD then
		return
	end

	if ownBarsEnabled == nil then
		local showOwnBars = options.showOwnBars

		ownBarsEnabled = not showOwnBars or showOwnBars.pendingValue ~= nil and showOwnBars.pendingValue or showOwnBars.value
	end

	if manaShieldSubEnabled == nil then
		local msWidget = p.interfaceHUD:recursiveGetChildById("showManaShield")

		if msWidget then
			manaShieldSubEnabled = msWidget:isChecked()
		else
			local msOpt = options.showManaShield

			manaShieldSubEnabled = msOpt and (msOpt.pendingValue ~= nil and msOpt.pendingValue or msOpt.value) or false
		end
	end

	if harmonySubEnabled == nil then
		local hWidget = p.interfaceHUD:recursiveGetChildById("showOwnHarmony")

		if hWidget then
			harmonySubEnabled = hWidget:isChecked()
		else
			local hOpt = options.showOwnHarmony

			harmonySubEnabled = hOpt and (hOpt.pendingValue ~= nil and hOpt.pendingValue or hOpt.value) or false
		end
	end

	for _, id in ipairs(OWN_HUD_DEPENDENT_OPTIONS) do
		setHudDependentOptionState(p.interfaceHUD, id, ownHudEnabled)
	end

	for _, id in ipairs(OWN_BAR_DEPENDENT_OPTIONS) do
		setHudDependentOptionState(p.interfaceHUD, id, ownHudEnabled and ownBarsEnabled)
	end

	for _, id in ipairs(OWN_MANA_SHIELD_OPTIONS) do
		setHudDependentOptionState(p.interfaceHUD, id, ownHudEnabled and manaShieldSubEnabled)
	end

	for _, id in ipairs(OWN_HARMONY_OPTIONS) do
		setHudDependentOptionState(p.interfaceHUD, id, ownHudEnabled and harmonySubEnabled)
	end

	for _, id in ipairs(OTHER_HUD_DEPENDENT_OPTIONS) do
		setHudDependentOptionState(p.interfaceHUD, id, otherHudEnabled)
	end
end

function refreshHudDependencyAvailability(panelsArg)
	local p = panelsArg or panels

	if not p or not p.interfaceHUD then
		return
	end

	local ownHud = p.interfaceHUD:recursiveGetChildById("showHudForOwnCharacter")
	local otherHud = p.interfaceHUD:recursiveGetChildById("showHudForOtherCreatures")
	local ownBars = p.interfaceHUD:recursiveGetChildById("showOwnBars")
	local ownHudEnabled = options.showHudForOwnCharacter.value
	local otherHudEnabled = options.showHudForOtherCreatures.value
	local ownBarsEnabled = options.showOwnBars and options.showOwnBars.value

	if ownHud then
		ownHudEnabled = ownHud:isChecked()
	end

	if otherHud then
		otherHudEnabled = otherHud:isChecked()
	end

	if ownBars then
		ownBarsEnabled = ownBars:isChecked()
	end

	local manaShieldSubEnabled
	local msWidget = p.interfaceHUD:recursiveGetChildById("showManaShield")

	if msWidget then
		manaShieldSubEnabled = ownHudEnabled and msWidget:isChecked()
	end

	local harmonySubEnabled
	local hOwnWidget = p.interfaceHUD:recursiveGetChildById("showOwnHarmony")

	if hOwnWidget then
		harmonySubEnabled = ownHudEnabled and hOwnWidget:isChecked()
	end

	updateHudDependencyAvailability(p, ownHudEnabled, otherHudEnabled, ownBarsEnabled, manaShieldSubEnabled, harmonySubEnabled)
end

function updateBigMouseCursorAvailability(panelsArg, useNativeMouseCursor)
	local p = panelsArg or panels

	if not p or not p.interface then
		return
	end

	local showBigMouseCursor = p.interface:recursiveGetChildById("showBigMouseCursor")
	local showBigMouseCursorHelp = p.interface:recursiveGetChildById("showBigMouseCursorHelp")

	if showBigMouseCursor then
		showBigMouseCursor:setEnabled(not useNativeMouseCursor)
	end

	if showBigMouseCursorHelp then
		showBigMouseCursorHelp:setImageSource(useNativeMouseCursor and "/images/icons/show_gui_help_orange" or "/images/icons/show_gui_help_grey")
		showBigMouseCursorHelp:setTooltip(useNativeMouseCursor and BIG_CURSOR_TOOLTIP_DISABLED or BIG_CURSOR_TOOLTIP_DEFAULT)
	end
end

local GRAPHICS_ENGINE_DISPLAY_NAMES = {
	[0] = "DirectX 12",
	"DirectX 12",
	"OpenGL"
}
local GRAPHICS_ENGINE_HELP_BODY = tr("In general, the client will automatically select the best graphics engine for you. Select the graphics engine of your choice from the drop-down menu if you should experience problems with the pre-selected one. Note that a restart of the client is necessary for this change to take effect.")

function updateGraphicsEngineHelpTooltip(panelsArg, engineValue)
	local p = panelsArg or panels

	if not p or not p.graphicsPanel then
		return
	end

	local help = p.graphicsPanel:recursiveGetChildById("graphicsEngineHelp")

	if not help then
		return
	end

	local engineName = GRAPHICS_ENGINE_DISPLAY_NAMES[engineValue] or GRAPHICS_ENGINE_DISPLAY_NAMES[0]

	help:setTooltip(tr("Your current graphics engine is %s.\n\n%s", engineName, GRAPHICS_ENGINE_HELP_BODY))
end

local function getEffectiveOptionValue(key)
	local opt = options[key]

	if not opt then
		return nil
	end

	if opt.pendingValue ~= nil then
		return opt.pendingValue
	end

	return opt.value
end

function updateBackgroundFrameRatePreview(panelsArg)
	local p = panelsArg or panels

	if not p or not p.graphicsPanel then
		return
	end

	local noLimit = getEffectiveOptionValue("noFrameRateLimit") == true
	local frameRate = getEffectiveOptionValue("backgroundFrameRate") or 240

	if frameRate <= 0 or frameRate > 240 then
		frameRate = 240
	end

	local frameRateScroll = p.graphicsPanel:recursiveGetChildById("backgroundFrameRate")
	local frameRateHelp = p.graphicsPanel:recursiveGetChildById("backgroundFrameRateHelp")

	if not frameRateScroll then
		return
	end

	local valueBar = frameRateScroll:recursiveGetChildById("valueBar")

	if noLimit then
		if valueBar then
			valueBar:setEnabled(false)
			valueBar:setValue(frameRate)
		end

		frameRateScroll:setColor("#707070ff")
	else
		if valueBar then
			valueBar:setEnabled(true)
			valueBar:setValue(frameRate)
		end

		frameRateScroll:setColor("#c0c0c0ff")
	end

	if frameRateHelp then
		frameRateHelp:setVisible(true)
	end

	if noLimit then
		frameRateScroll:setText(tr("Frame Rate Limit: %s", tr("unlimited")))
	else
		frameRateScroll:setText(tr("Frame Rate Limit: %s", frameRate))
	end
end

local currentFrameRatePollEvent

function updateCurrentFrameRateLabel(fps)
	if not panels or not panels.graphicsPanel then
		return
	end

	local label = panels.graphicsPanel:recursiveGetChildById("currentFrameRate")

	if not label then
		return
	end

	label:setText(tr("Current Frame Rate: %.2f fps", fps or g_app.getFps()))
end

local function stopCurrentFrameRatePoll()
	if currentFrameRatePollEvent then
		removeEvent(currentFrameRatePollEvent)

		currentFrameRatePollEvent = nil
	end
end

local function startCurrentFrameRatePoll()
	stopCurrentFrameRatePoll()
	updateCurrentFrameRateLabel()

	local function tick()
		if not controller.ui:isVisible() then
			stopCurrentFrameRatePoll()

			return
		end

		updateCurrentFrameRateLabel()

		currentFrameRatePollEvent = scheduleEvent(tick, 250)
	end

	currentFrameRatePollEvent = scheduleEvent(tick, 250)
end

function updateLootSideVisibility(panelsArg, classicControlValue)
	local p = panelsArg or panels

	if not p then
		return
	end

	local isClassic = classicControlValue == "classic" or classicControlValue == true

	for _, panel in pairs({
		p.generalPanel,
		p.optionsPanel
	}) do
		if panel then
			local lootSide = panel:recursiveGetChildById("lootSide")

			if lootSide then
				lootSide:setVisible(isClassic)
			end
		end
	end
end

local function scheduleRebindTurnKeys()
	local fn = modules.game_walk and modules.game_walk.rebindTurnKeys

	if type(fn) ~= "function" then
		return
	end

	fn()
	scheduleEvent(function()
		local f2 = modules.game_walk and modules.game_walk.rebindTurnKeys

		if type(f2) == "function" then
			f2()
		end
	end, 0)
end

panels = {}

local simpleButtons = {
	{
		icon = "/images/icons/icon_interface",
		text = "Options",
		open = "optionsPanel"
	},
	{
		icon = "/images/icons/icon_controls",
		text = "Hotkeys",
		open = "keybindsPanel"
	},
	{
		icon = "/images/icons/icon_interface",
		text = "Shortcuts",
		open = "shortcuts"
	},
	{
		icon = "/images/icons/icon_misc",
		text = "Help",
		open = "miscHelp"
	}
}
local advancedButtons = {
	{
		icon = "/images/icons/icon_controls",
		text = "Controls",
		open = "generalPanel",
		subCategories = {
			{
				text = "General Hotkeys",
				open = "keybindsPanel"
			},
			{
				text = "Custom Hotkeys",
				open = "customHotkeysPanel"
			}
		}
	},
	{
		icon = "/images/icons/icon_interface",
		text = "Interfaces",
		open = "interface",
		subCategories = {
			{
				text = "H U D",
				open = "interfaceHUD"
			},
			{
				text = "Console",
				open = "interfaceConsole"
			},
			{
				text = "Game Window",
				open = "interfaceGameWindow"
			},
			{
				text = "Action Bars",
				open = "actionBarsPanel"
			},
			{
				text = "Shortcuts",
				open = "shortcuts"
			}
		}
	},
	{
		icon = "/images/icons/icon_graphics",
		text = "Graphics",
		open = "graphicsPanel",
		subCategories = {
			{
				text = "Effects",
				open = "graphicsEffectsPanel"
			}
		}
	},
	{
		icon = "/images/icons/icon_sound",
		text = "Sound",
		open = "soundPanel",
		subCategories = {
			{
				text = "Battle Sounds",
				open = "battleSoundsPanel"
			},
			{
				text = "UI Sounds",
				open = "uiSoundsPanel"
			}
		}
	},
	{
		icon = "/images/icons/icon_misc",
		text = "Misc.",
		open = "misc",
		subCategories = {
			{
				text = "Game Play",
				open = "miscGameplay"
			},
			{
				text = "Screenshots",
				open = "miscScreenshots"
			},
			{
				text = "Help",
				open = "miscHelp"
			}
		}
	}
}
local buttons = simpleButtons
local isAdvancedMode = false
local extraWidgets = {}

local function toggleDisplays()
	local namesEnabled = options.showOwnName.value and options.showOtherName.value
	local healthEnabled = options.showOwnHealth.value and options.showOtherHealth.value

	if namesEnabled and healthEnabled and options.showOwnMana.value then
		setOption("showOwnName", false, true)
		setOption("showOtherName", false, true)
	elseif healthEnabled then
		setOption("showOwnHealth", false, true)
		setOption("showOtherHealth", false, true)
		setOption("showOwnMana", false, true)
	elseif not namesEnabled and not healthEnabled then
		setOption("showOwnName", true, true)
		setOption("showOtherName", true, true)
	else
		setOption("showOwnHealth", true, true)
		setOption("showOtherHealth", true, true)
		setOption("showOwnMana", true, true)
	end
end

local function toggleOption(key)
	setOption(key, not getOption(key))
end

function toggleAdvancedMode(enabled)
	if enabled == isAdvancedMode and controller.ui.optionsTabBar:getChildCount() > 0 then
		return
	end

	isAdvancedMode = enabled

	g_settings.set("advancedOptionsMode", enabled)

	buttons = enabled and advancedButtons or simpleButtons

	if controller.ui.selectedOption then
		controller.ui.selectedOption:hide()
	end

	controller.ui.openedCategory = nil
	controller.ui.selectedOption = nil

	configureCharacterCategories()

	local firstCategory = controller.ui.optionsTabBar:getChildByIndex(1)

	if firstCategory then
		controller.ui.openedCategory = firstCategory

		firstCategory.Button:onClick()
	end
end

local function setupComboBox()
	local graphicsEngineCombobox = panels.graphicsPanel:recursiveGetChildById("graphicsEngine")
	local antialiasingModeCombobox = panels.graphicsPanel:recursiveGetChildById("antialiasingMode")
	local framesRarityCombobox = panels.interface:recursiveGetChildById("frames")
	local vocationPresetsCombobox = panels.keybindsPanel:recursiveGetChildById("list")
	local listKeybindsPanel = panels.keybindsPanel:recursiveGetChildById("list")
	local markTargetVisuallyCombobox = panels.interfaceGameWindow and panels.interfaceGameWindow:recursiveGetChildById("markTargetVisually")

	local function setupMousePresetComboBoxes(panel)
		if not panel then
			return
		end

		local classicControls = panel:recursiveGetChildById("classicControls")
		local lootSide = panel:recursiveGetChildById("lootSide")

		if classicControls then
			for _, v in pairs({
				{
					"Classic Controls",
					"classic"
				},
				{
					"Regular Controls",
					"regular"
				},
				{
					"Left Smart-Click",
					"leftSmart"
				}
			}) do
				classicControls:addOption(v[1], v[2])
			end

			function classicControls.onOptionChange(comboBox, option)
				setOption("classicControl", comboBox:getCurrentOption().data)
			end
		end

		if lootSide then
			for _, v in pairs({
				{
					"Loot: Right",
					"right"
				},
				{
					"Loot: SHIFT + Right",
					"shiftRight"
				},
				{
					"Loot: Left",
					"left"
				}
			}) do
				lootSide:addOption(v[1], v[2])
			end

			function lootSide.onOptionChange(comboBox, option)
				setOption("lootSide", comboBox:getCurrentOption().data)
			end
		end
	end

	local function setupArcsHudCombo(panel)
		if not panel then
			return
		end

		local showArcsSizeCombo = panel:recursiveGetChildById("showArcsSize")

		if showArcsSizeCombo then
			for _, v in ipairs({
				{
					tr("Small Size"),
					"small"
				},
				{
					tr("Default Size"),
					"default"
				},
				{
					tr("Large Size"),
					"large"
				}
			}) do
				showArcsSizeCombo:addOption(v[1], v[2])
			end

			function showArcsSizeCombo.onOptionChange(comboBox, option)
				setOption("showArcsSize", comboBox:getCurrentOption().data)
			end
		end
	end

	setupArcsHudCombo(panels.interfaceHUD)

	if panels.optionsPanel then
		setupMousePresetComboBoxes(panels.optionsPanel)

		local colouriseLootValue = panels.optionsPanel:recursiveGetChildById("colouriseLootValue")
		local antialiasingModeOptions = panels.optionsPanel:recursiveGetChildById("antialiasingModeOptions")

		if colouriseLootValue then
			for k, v in pairs({
				{
					"None",
					"none"
				},
				{
					"Frames",
					"frames"
				},
				{
					"Corners",
					"corners"
				}
			}) do
				colouriseLootValue:addOption(v[1], v[2])
			end

			function colouriseLootValue.onOptionChange(comboBox, option)
				setOption("colouriseLootValue", comboBox:getCurrentOption().data)
			end
		end

		if antialiasingModeOptions then
			for k, t in ipairs({
				"None",
				"Antialiasing",
				"Smooth Retro"
			}) do
				antialiasingModeOptions:addOption(t, k - 1)
			end

			function antialiasingModeOptions.onOptionChange(comboBox, option)
				setOption("antialiasingMode", comboBox:getCurrentOption().data)
			end
		end
	end

	setupMousePresetComboBoxes(panels.generalPanel)

	if graphicsEngineCombobox then
		-- Vulkan is our own renderer (under construction). The choice is saved to config.ini as
		-- renderBackend, because the engine reads it at STARTUP - the change requires a client restart.
		for k, t in ipairs({
			"(auto-select)",
			"DirectX 12",
			"OpenGL",
			"Vulkan (experimental)"
		}) do
			graphicsEngineCombobox:addOption(t, k - 1)
		end

		function graphicsEngineCombobox.onOptionChange(comboBox, option)
			local data = comboBox:getCurrentOption().data

			-- Changing the list selection alone saves NOTHING and restarts nothing - that happens
			-- only on confirmation (Apply / OK), just like with the remaining settings.
			-- Here we only remember that the selection changed.
			if pendingRenderBackendFrom == nil then
				pendingRenderBackendFrom = getOption("graphicsEngine")
			end

			setOption("graphicsEngine", data)
		end

		updateGraphicsEngineHelpTooltip(panels, getOption("graphicsEngine"))
	end

	if antialiasingModeCombobox then
		for k, t in ipairs({
			"None",
			"Antialiasing",
			"Smooth Retro"
		}) do
			antialiasingModeCombobox:addOption(t, k - 1)
		end

		function antialiasingModeCombobox.onOptionChange(comboBox, option)
			setOption("antialiasingMode", comboBox:getCurrentOption().data)
		end
	end

	for k, v in pairs({
		{
			"None",
			"none"
		},
		{
			"Frames",
			"frames"
		},
		{
			"Corners",
			"corners"
		}
	}) do
		framesRarityCombobox:addOption(v[1], v[2])
	end

	function framesRarityCombobox.onOptionChange(comboBox, option)
		setOption("framesRarity", comboBox:getCurrentOption().data)
	end

	if markTargetVisuallyCombobox then
		for _, v in ipairs({
			{
				"Frame & Highlight",
				"frameAndHighlight"
			},
			{
				"Frame Only",
				"frameOnly"
			},
			{
				"Highlight Only",
				"highlightOnly"
			},
			{
				"None",
				"none"
			}
		}) do
			markTargetVisuallyCombobox:addOption(v[1], v[2])
		end

		function markTargetVisuallyCombobox.onOptionChange(comboBox, option)
			setOption("markTargetVisually", comboBox:getCurrentOption().data)
		end
	end

	for _, preset in ipairs(Keybind.presets) do
		listKeybindsPanel:addOption(preset)
	end

	function listKeybindsPanel.onOptionChange(comboBox, option)
		setOption("listKeybindsPanel", option)
	end

	panels.keybindsPanel.presets.list:setCurrentOption(Keybind.currentPreset)
end

local function bindCheckbox(panel, id)
	local widget = panel:recursiveGetChildById(id)

	if widget then
		function widget:onClick()
			self:setChecked(not self:isChecked())
			setOption(id, self:isChecked())
		end
	end
end

local function setupOptionsCheckboxes()
	if not panels.optionsPanel then
		return
	end

	local checkboxIds = {
		"allowInspect",
		"autoChaseOff",
		"quickLootCorpses",
		"showBars",
		"showArcs",
		"bottomBarsAll",
		"bottomBarsBar1",
		"bottomBarsBar2",
		"bottomBarsBar3",
		"leftBarsAll",
		"leftBarsBar1",
		"leftBarsBar2",
		"leftBarsBar3",
		"rightBarsAll",
		"rightBarsBar1",
		"rightBarsBar2",
		"rightBarsBar3"
	}

	for _, id in ipairs(checkboxIds) do
		bindCheckbox(panels.optionsPanel, id)

		if panels.interfaceHUD then
			bindCheckbox(panels.interfaceHUD, id)
		end
	end
end

local displayedButtons = {}
local availableButtons = {}

local function setShortcutButtonState(button, enabled)
	if not button then
		return
	end

	button:setEnabled(enabled)
end

local function updateButtonStates()
	if not panels.shortcuts then
		return
	end

	local displayedList = panels.shortcuts:recursiveGetChildById("displayedButtonsList")
	local availableList = panels.shortcuts:recursiveGetChildById("availableButtonsList")
	local moveToAvailableBtn = panels.shortcuts:recursiveGetChildById("moveToAvailableBtn")
	local moveUpBtn = panels.shortcuts:recursiveGetChildById("moveUpBtn")
	local moveDownBtn = panels.shortcuts:recursiveGetChildById("moveDownBtn")
	local moveToDisplayedBtn = panels.shortcuts:recursiveGetChildById("moveToDisplayedBtn")
	local focusedDisplayed = displayedList and displayedList:getFocusedChild() or nil
	local hasDisplayedSelection = focusedDisplayed ~= nil
	local hasAvailableSelection = availableList and availableList:getFocusedChild() ~= nil
	local canMoveUp = false
	local canMoveDown = false

	if focusedDisplayed and displayedList then
		local children = displayedList:getChildren()

		for i, child in ipairs(children) do
			if child == focusedDisplayed then
				canMoveUp = i > 1
				canMoveDown = i < #children

				break
			end
		end
	end

	setShortcutButtonState(moveToAvailableBtn, hasDisplayedSelection)
	setShortcutButtonState(moveUpBtn, canMoveUp)
	setShortcutButtonState(moveDownBtn, canMoveDown)
	setShortcutButtonState(moveToDisplayedBtn, hasAvailableSelection)
end

local function applyShortcutListRowLabelStyle(label)
	label:setTextAlign(AlignLeft)
	label:setMarginLeft(-1)
	label:setTextOffset("1 0")
	label:setHeight(16)
	label:setFont("Verdana Bold-11px-new")
	label:setColor("#c0c0c0ff")
	label:setFocusable(true)
end

local function updateDisplayedButtonsList(keepSelection)
	if not panels.shortcuts then
		return
	end

	local displayedList = panels.shortcuts:recursiveGetChildById("displayedButtonsList")

	if not displayedList then
		return
	end

	local selectedId

	if keepSelection then
		local focused = displayedList:getFocusedChild()

		if focused then
			selectedId = focused.buttonId
		end
	end

	displayedList:destroyChildren()

	for i, buttonData in ipairs(displayedButtons) do
		local label = g_ui.createWidget("Label", displayedList)

		label:setText(buttonData.tooltip)
		applyShortcutListRowLabelStyle(label)

		label.buttonId = buttonData.id

		local bgColor = i % 2 == 1 and "#484848" or "#414141"

		label:setBackgroundColor(bgColor)

		function label:onFocusChange(focused)
			if focused then
				self:setBackgroundColor("#585858")
				self:setColor("#f4f4f4")
			else
				self:setBackgroundColor(bgColor)
				self:setColor("#c0c0c0ff")
			end

			updateButtonStates()
		end

		function label:onDoubleClick(mousePos)
			self:focus()
			moveToAvailable()
		end

		if selectedId and buttonData.id == selectedId then
			label:focus()
		end
	end

	updateButtonStates()
end

local function updateAvailableButtonsList(keepSelection)
	if not panels.shortcuts then
		return
	end

	local availableList = panels.shortcuts:recursiveGetChildById("availableButtonsList")

	if not availableList then
		return
	end

	local selectedId

	if keepSelection then
		local focused = availableList:getFocusedChild()

		if focused then
			selectedId = focused.buttonId
		end
	end

	availableList:destroyChildren()

	for i, buttonData in ipairs(availableButtons) do
		local label = g_ui.createWidget("Label", availableList)

		label:setText(buttonData.tooltip)
		applyShortcutListRowLabelStyle(label)

		label.buttonId = buttonData.id

		local bgColor = i % 2 == 1 and "#484848" or "#414141"

		label:setBackgroundColor(bgColor)

		function label:onFocusChange(focused)
			if focused then
				self:setBackgroundColor("#585858")
				self:setColor("#f4f4f4")
			else
				self:setBackgroundColor(bgColor)
				self:setColor("#c0c0c0ff")
			end

			updateButtonStates()
		end

		function label:onDoubleClick(mousePos)
			self:focus()
			moveToDisplayed()
		end

		if selectedId and buttonData.id == selectedId then
			label:focus()
		end
	end

	updateButtonStates()
end

function refreshShortcuts()
	if not panels.shortcuts then
		return
	end

	if not modules.game_mainpanel or not modules.game_mainpanel.getMainPanelButtonsInfo then
		return
	end

	displayedButtons = {}
	availableButtons = {}

	local buttons, order = modules.game_mainpanel.getMainPanelButtonsInfo()

	if not buttons then
		return
	end

	local buttonMap = {}

	for _, btn in ipairs(buttons) do
		buttonMap[btn.id] = btn
	end

	local addedIds = {}

	for _, id in ipairs(order) do
		if buttonMap[id] and buttonMap[id].visible then
			table.insert(displayedButtons, buttonMap[id])

			addedIds[id] = true
		end
	end

	for _, btn in ipairs(buttons) do
		if btn.visible and not addedIds[btn.id] then
			table.insert(displayedButtons, btn)
		end
	end

	for _, btn in ipairs(buttons) do
		if not btn.visible then
			table.insert(availableButtons, btn)
		end
	end

	updateDisplayedButtonsList()
	updateAvailableButtonsList()
end

function moveToAvailable()
	if not panels.shortcuts then
		return
	end

	local displayedList = panels.shortcuts:recursiveGetChildById("displayedButtonsList")
	local selectedItem = displayedList:getFocusedChild()

	if not selectedItem then
		return
	end

	local buttonId = selectedItem.buttonId

	modules.game_mainpanel.setMainPanelButtonVisible(buttonId, false)
	refreshShortcuts()

	local children = displayedList:getChildren()

	if #children > 0 then
		children[math.min(#children, 1)]:focus()
	end
end

function moveToDisplayed()
	if not panels.shortcuts then
		return
	end

	local availableList = panels.shortcuts:recursiveGetChildById("availableButtonsList")
	local selectedItem = availableList:getFocusedChild()

	if not selectedItem then
		return
	end

	local buttonId = selectedItem.buttonId

	modules.game_mainpanel.setMainPanelButtonVisible(buttonId, true)
	refreshShortcuts()

	local children = availableList:getChildren()

	if #children > 0 then
		children[math.min(#children, 1)]:focus()
	end
end

function moveButtonUp()
	if not panels.shortcuts then
		return
	end

	local displayedList = panels.shortcuts:recursiveGetChildById("displayedButtonsList")
	local selectedItem = displayedList:getFocusedChild()

	if not selectedItem then
		return
	end

	local buttonId = selectedItem.buttonId
	local index

	for i, btn in ipairs(displayedButtons) do
		if btn.id == buttonId then
			index = i

			break
		end
	end

	if index and index > 1 then
		displayedButtons[index], displayedButtons[index - 1] = displayedButtons[index - 1], displayedButtons[index]

		local newOrder = {}

		for _, btn in ipairs(displayedButtons) do
			table.insert(newOrder, btn.id)
		end

		modules.game_mainpanel.setMainPanelButtonOrder(newOrder)
		updateDisplayedButtonsList(true)

		local focusedChild = displayedList:getFocusedChild()

		if focusedChild then
			displayedList:ensureChildVisible(focusedChild)
		end
	end
end

function moveButtonDown()
	if not panels.shortcuts then
		return
	end

	local displayedList = panels.shortcuts:recursiveGetChildById("displayedButtonsList")
	local selectedItem = displayedList:getFocusedChild()

	if not selectedItem then
		return
	end

	local buttonId = selectedItem.buttonId
	local index

	for i, btn in ipairs(displayedButtons) do
		if btn.id == buttonId then
			index = i

			break
		end
	end

	if index and index < #displayedButtons then
		displayedButtons[index], displayedButtons[index + 1] = displayedButtons[index + 1], displayedButtons[index]

		local newOrder = {}

		for _, btn in ipairs(displayedButtons) do
			table.insert(newOrder, btn.id)
		end

		modules.game_mainpanel.setMainPanelButtonOrder(newOrder)
		updateDisplayedButtonsList(true)

		local focusedChild = displayedList:getFocusedChild()

		if focusedChild then
			displayedList:ensureChildVisible(focusedChild)
		end
	end
end

function resetShortcuts()
	if not modules.game_mainpanel or not modules.game_mainpanel.resetMainPanelButtons then
		return
	end

	modules.game_mainpanel.resetMainPanelButtons()
	refreshShortcuts()
end

local suppressConditionsUi = false
local lastFocusedConditionId
local specialConditionIds = {}

for _, cond in ipairs(SpecialConditions or {}) do
	if cond.id then
		specialConditionIds[cond.id] = true
	end
end

local function getDefaultConditionsDisplaySettings()
	local order = {}
	local entries = {}

	for _, cond in ipairs(SpecialConditions or {}) do
		if cond.id then
			order[#order + 1] = cond.id
			entries[cond.id] = {
				hud = cond.defaultHud ~= false,
				bar = cond.defaultBar ~= false
			}
		end
	end

	return {
		hudColumnEnabled = true,
		barColumnEnabled = true,
		order = order,
		entries = entries
	}
end

local function mergeConditionsDisplaySettings(stored)
	local defaults = getDefaultConditionsDisplaySettings()

	if type(stored) ~= "table" or type(stored.order) ~= "table" or type(stored.entries) ~= "table" then
		return defaults
	end

	local entries = {}

	for id, def in pairs(defaults.entries) do
		local saved = stored.entries and stored.entries[id]
		local hud = def.hud
		local bar = def.bar

		if saved then
			if saved.hud ~= nil then
				hud = saved.hud
			end

			if saved.bar ~= nil then
				bar = saved.bar
			end
		end

		entries[id] = {
			hud = hud,
			bar = bar
		}
	end

	local order = {}
	local seen = {}

	for _, id in ipairs(stored.order) do
		if entries[id] and not seen[id] then
			order[#order + 1] = id
			seen[id] = true
		end
	end

	for _, id in ipairs(defaults.order) do
		if not seen[id] then
			order[#order + 1] = id
		end
	end

	return {
		order = order,
		entries = entries,
		hudColumnEnabled = stored.hudColumnEnabled ~= false,
		barColumnEnabled = stored.barColumnEnabled ~= false
	}
end

function parseConditionsDisplaySettings(raw)
	if type(raw) == "table" then
		return mergeConditionsDisplaySettings(raw)
	end

	if type(raw) == "string" and raw ~= "" then
		local ok, data = pcall(json.decode, raw)

		if ok and type(data) == "table" then
			return mergeConditionsDisplaySettings(data)
		end
	end

	return getDefaultConditionsDisplaySettings()
end

local function encodeConditionsDisplaySettings(settings)
	return json.encode(settings)
end

function getConditionsDisplaySettings()
	local opt = options.conditionsDisplaySettings

	if not opt then
		return getDefaultConditionsDisplaySettings()
	end

	local raw = opt.pendingValue ~= nil and opt.pendingValue or opt.value

	return parseConditionsDisplaySettings(raw)
end

local function getCommittedConditionsDisplaySettings()
	local opt = options.conditionsDisplaySettings

	if not opt then
		return getDefaultConditionsDisplaySettings()
	end

	return parseConditionsDisplaySettings(opt.value)
end

local function getSpecialConditionById(id)
	for _, cond in ipairs(SpecialConditions or {}) do
		if cond.id == id then
			return cond
		end
	end

	return nil
end

function isSpecialConditionId(id)
	return id ~= nil and specialConditionIds[id] == true
end

function isConditionVisibleInHud(id)
	if not isSpecialConditionId(id) then
		return true
	end

	local settings = getCommittedConditionsDisplaySettings()

	if settings.hudColumnEnabled == false then
		return false
	end

	local entry = settings.entries[id]

	return not entry or entry.hud ~= false
end

function isConditionVisibleInBar(id)
	if not isSpecialConditionId(id) then
		return true
	end

	local settings = getCommittedConditionsDisplaySettings()

	if settings.barColumnEnabled == false then
		return false
	end

	local entry = settings.entries[id]

	return not entry or entry.bar ~= false
end

function getConditionDisplayOrderIndex(id)
	local settings = getCommittedConditionsDisplaySettings()

	for i, condId in ipairs(settings.order) do
		if condId == id then
			return i
		end
	end

	return 9999
end

function notifyConditionsDisplayChanged()
	if modules.game_healthcircle and modules.game_healthcircle.refreshArcConditionsBarDeferred then
		modules.game_healthcircle.refreshArcConditionsBarDeferred()
	end

	local gameInterface = modules.game_interface

	if gameInterface and gameInterface.refreshConditionIconsFromSettings then
		gameInterface.refreshConditionIconsFromSettings()
	elseif gameInterface and gameInterface.StatsBar and gameInterface.StatsBar.refreshConditionIconsFromSettings then
		gameInterface.StatsBar.refreshConditionIconsFromSettings()
	end
end

local function persistConditionsDisplaySettings(settings, force)
	setOption("conditionsDisplaySettings", encodeConditionsDisplaySettings(settings), force)
end

local function refreshConditionListCheckboxState(checkbox, enabled)
	if not checkbox then
		return
	end

	local checked = checkbox:isChecked()

	checkbox:setEnabled(enabled)
	checkbox:setChecked(checked)
end

local function applyConditionsColumnEnabledState(panelsArg, settings)
	settings = settings or getConditionsDisplaySettings()

	local hud = panelsArg and panelsArg.interfaceHUD or panels and panels.interfaceHUD

	if not hud then
		return
	end

	local hudColumnEnabled = settings.hudColumnEnabled ~= false
	local barColumnEnabled = settings.barColumnEnabled ~= false

	suppressConditionsUi = true

	local showInHudCb = hud:recursiveGetChildById("showInHud")
	local showInBarCb = hud:recursiveGetChildById("showInBar")

	if showInHudCb then
		showInHudCb:setChecked(hudColumnEnabled)
	end

	if showInBarCb then
		showInBarCb:setChecked(barColumnEnabled)
	end

	local list = hud:recursiveGetChildById("conditionsList")

	if list then
		for _, row in ipairs(list:getChildren()) do
			local hudCheck = row:getChildById("showInHudCheck")
			local barCheck = row:getChildById("showInBarCheck")

			if hudCheck then
				refreshConditionListCheckboxState(hudCheck, hudColumnEnabled)
			end

			if barCheck then
				refreshConditionListCheckboxState(barCheck, barColumnEnabled)
			end
		end
	end

	suppressConditionsUi = false
end

local function updateConditionMoveButtons(panelsArg)
	local hud = panelsArg and panelsArg.interfaceHUD or panels and panels.interfaceHUD

	if not hud then
		return
	end

	local list = hud:recursiveGetChildById("conditionsList")
	local moveUpBtn = hud:recursiveGetChildById("moveUpBtn")
	local moveDownBtn = hud:recursiveGetChildById("moveDownBtn")

	if not list or not moveUpBtn or not moveDownBtn then
		return
	end

	local focused = list:getFocusedChild()
	local canMoveUp, canMoveDown = false, false

	if focused then
		local children = list:getChildren()

		for i, child in ipairs(children) do
			if child == focused then
				canMoveUp = i > 1
				canMoveDown = i < #children

				break
			end
		end
	end

	moveUpBtn:setEnabled(canMoveUp)
	moveDownBtn:setEnabled(canMoveDown)
end

local function onConditionRowCheckChange(row, column, checked)
	if suppressConditionsUi or not row or not row.conditionId then
		return
	end

	local settings = getConditionsDisplaySettings()
	local entry = settings.entries[row.conditionId]

	if not entry then
		entry = {
			hud = true,
			bar = true
		}
		settings.entries[row.conditionId] = entry
	end

	if column == "hud" then
		entry.hud = checked
	else
		entry.bar = checked
	end

	persistConditionsDisplaySettings(settings)
end

local function onConditionRowFocusChange(row, focused, bgColor)
	if not row then
		return
	end

	if focused then
		row:setBackgroundColor("#585858")

		local label = row:getChildById("label")

		if label then
			label:setColor("#f4f4f4")
		end

		if row.conditionId then
			lastFocusedConditionId = row.conditionId
		end
	else
		row:setBackgroundColor(bgColor)

		local label = row:getChildById("label")

		if label then
			label:setColor("#c0c0c0")
		end
	end

	updateConditionMoveButtons()
end

function refreshConditionsListUi(panelsArg, rawValue)
	local hud = panelsArg and panelsArg.interfaceHUD or panels and panels.interfaceHUD

	if not hud then
		return
	end

	local list = hud:recursiveGetChildById("conditionsList")

	if not list then
		return
	end

	local settings = parseConditionsDisplaySettings(rawValue)
	local scrollBar = hud:recursiveGetChildById("conditionsScrollBar")
	local savedScrollValue = scrollBar and scrollBar.getValue and scrollBar:getValue() or nil
	local selectedId = lastFocusedConditionId
	local focused = list:getFocusedChild()

	if focused and focused.conditionId then
		selectedId = focused.conditionId
	end

	suppressConditionsUi = true

	list:destroyChildren()

	local focusRow

	for i, id in ipairs(settings.order) do
		local cond = getSpecialConditionById(id)
		local entry = settings.entries[id]

		if cond and entry and cond.info then
			local row = g_ui.createWidget("ConditionListRow", list)

			row.conditionId = id

			row:setId("conditionRow_" .. id)

			local icon = row:getChildById("icon")

			if icon then
				applyPlayerStateIcon(icon, cond.info)
				icon:setTooltip(cond.info.tooltip)
			end

			local label = row:getChildById("label")

			if label then
				label:setText(cond.label or cond.info.tooltip or id)
			end

			local hudCheck = row:getChildById("showInHudCheck")
			local barCheck = row:getChildById("showInBarCheck")

			if hudCheck then
				hudCheck:setChecked(entry.hud ~= false)

				function hudCheck:onCheckChange(checked)
					onConditionRowCheckChange(row, "hud", checked)
				end
			end

			if barCheck then
				barCheck:setChecked(entry.bar ~= false)

				function barCheck:onCheckChange(checked)
					onConditionRowCheckChange(row, "bar", checked)
				end
			end

			local bgColor = i % 2 == 1 and "#484848" or "#414141"

			row:setBackgroundColor(bgColor)

			function row:onFocusChange(focused)
				onConditionRowFocusChange(self, focused, bgColor)
			end

			if selectedId and id == selectedId then
				row:focus()

				focusRow = row
			end
		end
	end

	suppressConditionsUi = false

	applyConditionsColumnEnabledState(panelsArg, settings)
	updateConditionMoveButtons(panelsArg)

	if focusRow then
		list:ensureChildVisible(focusRow)
	elseif savedScrollValue ~= nil and scrollBar and scrollBar.setValue then
		scrollBar:setValue(savedScrollValue)
	end
end

function onMasterConditionCheckChange(column, checked)
	if suppressConditionsUi then
		return
	end

	local settings = getConditionsDisplaySettings()

	if column == "hud" then
		settings.hudColumnEnabled = checked
	else
		settings.barColumnEnabled = checked
	end

	applyConditionsColumnEnabledState(panels, settings)
	persistConditionsDisplaySettings(settings)
end

local function setupConditionsList()
	local opt = options.conditionsDisplaySettings

	if not opt then
		return
	end

	local stored = g_settings.getString("conditionsDisplaySettings")

	if stored == nil or stored == "" then
		local defaults = getDefaultConditionsDisplaySettings()

		stored = encodeConditionsDisplaySettings(defaults)

		g_settings.setDefault("conditionsDisplaySettings", stored)
	end

	setOption("conditionsDisplaySettings", stored, true)
	refreshConditionsListUi(panels, stored)
end

function refreshConditionsListOnHudOpen()
	local opt = options.conditionsDisplaySettings

	if not opt then
		return
	end

	local raw = opt.pendingValue ~= nil and opt.pendingValue or opt.value

	refreshConditionsListUi(panels, raw)
end

function moveConditionUp()
	if not panels.interfaceHUD then
		return
	end

	local list = panels.interfaceHUD:recursiveGetChildById("conditionsList")
	local selectedItem = list and list:getFocusedChild()

	if not list or not selectedItem or not selectedItem.conditionId then
		return
	end

	local settings = getConditionsDisplaySettings()
	local order = settings.order
	local index

	for i, id in ipairs(order) do
		if id == selectedItem.conditionId then
			index = i

			break
		end
	end

	if index and index > 1 then
		order[index], order[index - 1] = order[index - 1], order[index]

		persistConditionsDisplaySettings(settings)
		refreshConditionsListUi(panels, encodeConditionsDisplaySettings(settings))

		local focused = list:getFocusedChild()

		if focused then
			list:ensureChildVisible(focused)
		end
	end
end

function moveConditionDown()
	if not panels.interfaceHUD then
		return
	end

	local list = panels.interfaceHUD:recursiveGetChildById("conditionsList")
	local selectedItem = list and list:getFocusedChild()

	if not list or not selectedItem or not selectedItem.conditionId then
		return
	end

	local settings = getConditionsDisplaySettings()
	local order = settings.order
	local index

	for i, id in ipairs(order) do
		if id == selectedItem.conditionId then
			index = i

			break
		end
	end

	if index and index < #order then
		order[index], order[index + 1] = order[index + 1], order[index]

		persistConditionsDisplaySettings(settings)
		refreshConditionsListUi(panels, encodeConditionsDisplaySettings(settings))

		local focused = list:getFocusedChild()

		if focused then
			list:ensureChildVisible(focused)
		end
	end
end

local function setupShortcuts()
	refreshShortcuts()
end

local LEGACY_SCREENSHOT_KEY_MAP = {
	LowHealth = "lowHealth",
	HighestHealingDone = "highestHealing",
	GiftOfLifeTriggered = "giftOfLife",
	HighestDamageDealt = "highestDamage",
	PlayerAttacking = "playerAttacking",
	PlayerKillAssist = "playerKillAssist",
	PlayerKill = "playerKill",
	DeathPvP = "deathPvP",
	DeathPvE = "deathPvE",
	BossDefeated = "bossDefeated",
	ValuableLoot = "valuableLoot",
	TreasureFound = "treasureFound",
	BestiaryEntryCompleted = "bestiaryCompleted",
	BestiaryEntryUnlocked = "bestiaryUnlocked",
	Achievement = "achievement",
	SkillUp = "skillUp",
	LevelUp = "levelUp",
	enableScreenshots = "enableAutoScreenshots"
}

local function migrateLegacyScreenshotSettings()
	for oldKey, newKey in pairs(LEGACY_SCREENSHOT_KEY_MAP) do
		if g_settings:exists(oldKey) and not g_settings:exists(newKey) then
			g_settings.set(newKey, g_settings.getBoolean(oldKey))
		end
	end
end

local function migrateGameWindowScreenMessageKeys()
	local root = g_settings.getNode()

	if type(root) ~= "table" then
		return
	end

	if root.showLootMessagesOnScreen ~= nil and root.showLootMessages == nil then
		g_settings.set("showLootMessages", g_settings.getBoolean("showLootMessagesOnScreen"))
	end

	if root.showPrivateMessagesOnScreen ~= nil and root.showPrivateMessages == nil then
		g_settings.set("showPrivateMessages", g_settings.getBoolean("showPrivateMessagesOnScreen"))
	end
end

local GAME_WINDOW_OPTION_DEFAULTS = {
	showInfoBanner = true,
	showMeleeAttackAnimation = true,
	showPvPFrames = true,
	showCombatFrames = true,
	showStoreNotificationsInCombat = true,
	showOfflineTrainingProgress = true,
	showBoostedCreature = true,
	showLootHighlighting = true,
	showHotkeyUsageNotifications = true,
	showSpellsOfOthers = true,
	showSpells = true,
	showPotionSoundEffects = true,
	showMessages = true,
	showTextualEffects = true,
	showPrivateMessages = true,
	showLootMessages = true,
	markTargetVisually = "frameAndHighlight"
}

function resetGameWindowOptions()
	for key, defaultValue in pairs(GAME_WINDOW_OPTION_DEFAULTS) do
		setOption(key, defaultValue)
	end
end

local function setup()
	panels.gameMapPanel = modules.game_interface.getMapPanel()

	migrateGameWindowScreenMessageKeys()
	setupComboBox()
	setupOptionsCheckboxes()
	setupShortcuts()
	setupConditionsList()

	for k, obj in pairs(options) do
		local v = obj.value

		if type(v) == "boolean" then
			if k == "enableAudio" then
				g_settings.set("enableAudio", true)
				setOption(k, true, true)
			elseif k == "showCustomisableStatusBars" then
				local dim = g_settings.getString("statsbar_dimension")
				local visible = dim ~= "hide"

				syncShowCustomisableStatusBarsOption(visible)
			elseif k == "showStatusBars" then
				if not g_settings.getBoolean("showStatusBars_semantics_v2") then
					g_settings.set("showStatusBars_semantics_v2", true)

					local root = g_settings.getNode()
					local explicit = type(root) == "table" and root.showStatusBars ~= nil
					local raw

					if explicit then
						raw = not g_settings.getBoolean(k)

						g_settings.set(k, raw)
					else
						raw = true

						g_settings.set(k, raw)
					end

					setOption(k, raw, true)
				else
					setOption(k, g_settings.getBoolean(k), true)
				end
			else
				setOption(k, g_settings.getBoolean(k), true)
			end
		elseif type(v) == "number" then
			setOption(k, g_settings.getNumber(k), true)
		elseif type(v) == "string" then
			setOption(k, g_settings.getString(k), true)
		end
	end

	-- The source of truth for the engine list is config.ini (renderBackend). It must run AFTER the
	-- loop above that loads saved options - earlier getOption returns the default (0), the correction
	-- does nothing, and the old value loaded a moment later (e.g. 3) would show a dead engine.
	-- setOption also fixes the saved profile (g_settings), so the mismatch disappears permanently.
	if g_configs.getRenderBackend then
		local backend = g_configs.getRenderBackend()
		local engine = getOption("graphicsEngine")

		if backend == "vulkan" and engine ~= 3 then
			setOption("graphicsEngine", 3)
		elseif backend ~= "vulkan" and engine == 3 then
			setOption("graphicsEngine", 2)
		end
	end

	if modules.game_walk and type(modules.game_walk.rebindTurnKeys) == "function" then
		modules.game_walk.rebindTurnKeys()
	end

	updateShowExpiryOnUnusedAvailability(panels, getOption("showExpiryInContainers"))
	updateBigMouseCursorAvailability(panels, getOption("useNativeMouseCursor"))
	updateHudDependencyAvailability(panels, getOption("showHudForOwnCharacter"), getOption("showHudForOtherCreatures"))

	if modules.game_healthcircle and modules.game_healthcircle.syncManaShieldHudOptions then
		modules.game_healthcircle.syncManaShieldHudOptions(options)
	end

	updateCurrentFrameRateLabel()
end

function showPresetNotification(text)
	if modules.game_textmessage and modules.game_textmessage.displayFailureMessage then
		modules.game_textmessage.displayFailureMessage(text)

		return
	end

	local root = g_ui.getRootWidget()

	if not root then
		return
	end

	local label = g_ui.createWidget("UILabel", root)

	label:setText(text)
	label:setTextAlign(AlignCenter)
	label:setColor("#ffffff")
	label:setPhantom(true)
	label:resize(400, 20)
	label:move(math.floor((root:getWidth() - 400) / 2), root:getHeight() - 60)
	scheduleEvent(function()
		if label and not label:isDestroyed() then
			label:destroy()
		end
	end, 3000)
end

function cycleHotkeyPreset()
	local presets = Keybind and Keybind.presets

	if not presets or #presets == 0 then
		return
	end

	local currentIdx = 1

	for i, p in ipairs(presets) do
		if p == Keybind.currentPreset then
			currentIdx = i

			break
		end
	end

	local nextIdx = currentIdx % #presets + 1
	local nextPreset = presets[nextIdx]

	if not nextPreset or nextPreset == Keybind.currentPreset then
		return
	end

	Keybind.selectPreset(nextPreset)

	if panels and panels.keybindsPanel and panels.keybindsPanel.presets and panels.keybindsPanel.presets.list then
		panels.keybindsPanel.presets.list:setCurrentOption(nextPreset, true)

		if updateKeybinds then
			updateKeybinds()
		end
	end

	if CustomHotkeys and CustomHotkeys.syncPresetFromGeneral then
		CustomHotkeys.syncPresetFromGeneral(nextPreset)
	end

	showPresetNotification(string.format("Switched to hotkey preset '%s'", nextPreset))
end

controller = Controller:new()

controller:setUI("options")

function controller:onInit()
	migrateLegacyScreenshotSettings()

	for k, obj in pairs(options) do
		if type(obj) ~= "table" then
			obj = {
				value = obj
			}
			options[k] = obj
		end

		g_settings.setDefault(k, obj.value)
	end

	extraWidgets.audioButton = modules.client_topmenu.addTopRightToggleButton("audioButton", tr("Music"), "/images/topbuttons/button_mute_up", function()
		toggleOption("enableMusicSound")
	end)
	extraWidgets.optionsButton = modules.client_topmenu.addTopRightToggleButton("optionsButton", tr("Options"), "/images/topbuttons/button_options", toggle)
	extraWidgets.logoutButton = modules.client_topmenu.addTopRightToggleButton("logoutButton", tr("Exit"), "/images/topbuttons/logout", toggle)

	local success, err = pcall(function()
		panels.optionsPanel = g_ui.loadUI("styles/optionspanel", controller.ui.optionsTabContent)
	end)

	if not success then
		g_logger.error("Failed to load optionspanel: " .. tostring(err))

		panels.optionsPanel = g_ui.loadUI("styles/controls/general", controller.ui.optionsTabContent)
	end

	panels.generalPanel = g_ui.loadUI("styles/controls/general", controller.ui.optionsTabContent)
	panels.keybindsPanel = g_ui.loadUI("styles/controls/keybinds", controller.ui.optionsTabContent)
	panels.customHotkeysPanel = g_ui.loadUI("styles/controls/custom_hotkeys", controller.ui.optionsTabContent)
	panels.graphicsPanel = g_ui.loadUI("styles/graphics/graphics", controller.ui.optionsTabContent)
	panels.graphicsEffectsPanel = g_ui.loadUI("styles/graphics/effects", controller.ui.optionsTabContent)
	panels.interface = g_ui.loadUI("styles/interface/interface", controller.ui.optionsTabContent)
	panels.interfaceConsole = g_ui.loadUI("styles/interface/console", controller.ui.optionsTabContent)
	panels.interfaceHUD = g_ui.loadUI("styles/interface/HUD", controller.ui.optionsTabContent)
	panels.interfaceGameWindow = g_ui.loadUI("styles/interface/gamewindow", controller.ui.optionsTabContent)
	panels.actionBarsPanel = g_ui.loadUI("styles/interface/actionbars", controller.ui.optionsTabContent)
	panels.shortcuts = g_ui.loadUI("styles/interface/shortcuts", controller.ui.optionsTabContent)
	panels.soundPanel = g_ui.loadUI("styles/sound/audio", controller.ui.optionsTabContent)
	panels.battleSoundsPanel = g_ui.loadUI("styles/sound/battlesounds", controller.ui.optionsTabContent)
	panels.uiSoundsPanel = g_ui.loadUI("styles/sound/uisounds", controller.ui.optionsTabContent)
	panels.misc = g_ui.loadUI("styles/misc/misc", controller.ui.optionsTabContent)
	panels.miscGameplay = g_ui.loadUI("styles/misc/gameplay", controller.ui.optionsTabContent)
	panels.miscScreenshots = g_ui.loadUI("styles/misc/screenshots", controller.ui.optionsTabContent)
	panels.miscHelp = g_ui.loadUI("styles/misc/help", controller.ui.optionsTabContent)

	self.ui:hide()
	g_settings.setDefault("advancedOptionsMode", true)

	isAdvancedMode = g_settings.getBoolean("advancedOptionsMode")
	buttons = isAdvancedMode and advancedButtons or simpleButtons

	configureCharacterCategories()
	controller.ui.hiddenAdvancedBox:setChecked(isAdvancedMode)
	addEvent(setup)
	init_binds()
	init_custom_hotkeys()
	connect(g_app, {
		onFps = updateCurrentFrameRateLabel
	})
	Keybind.new("UI", "Toggle Fullscreen", "Ctrl+F", "Alt+Return")
	Keybind.bind("UI", "Toggle Fullscreen", {
		{
			type = KEY_DOWN,
			callback = function()
				local opt = options.fullscreen
				local current = opt.pendingValue ~= nil and opt.pendingValue or opt.value

				setOption("fullscreen", not current, true)
			end
		}
	})
	Keybind.new("UI", "Show/hide FPS / lag indicator", "Alt+F8", "")
	Keybind.bind("UI", "Show/hide FPS / lag indicator", {
		{
			type = KEY_DOWN,
			callback = function()
				local opt = options.showFps
				local current = opt.pendingValue ~= nil and opt.pendingValue or opt.value

				setOption("showFps", not current, true)
			end
		}
	})
	Keybind.new("UI", "Show/hide Creature Names and Bars", "Ctrl+N", "")
	Keybind.bind("UI", "Show/hide Creature Names and Bars", {
		{
			type = KEY_DOWN,
			callback = toggleDisplays
		}
	})
	Keybind.new("Sound", "Mute/unmute music", "", "")
	Keybind.bind("Sound", "Mute/unmute music", {
		{
			type = KEY_DOWN,
			callback = function()
				toggleOption("enableMusicSound")
			end
		}
	})
	Keybind.new("UI", "Open Custom Hotkeys", "Ctrl+K", "")
	Keybind.bind("UI", "Open Custom Hotkeys", {
		{
			type = KEY_DOWN,
			callback = function()
				openOptionsCategory("Controls", "Custom Hotkeys")
			end
		}
	})
	Keybind.new("UI", "Switch Hotkey Preset", "Ctrl+J", "")
	Keybind.bind("UI", "Switch Hotkey Preset", {
		{
			type = KEY_DOWN,
			callback = function()
				cycleHotkeyPreset()
			end
		}
	})
end

function controller:onTerminate()
	stopCurrentFrameRatePoll()
	disconnect(g_app, {
		onFps = updateCurrentFrameRateLabel
	})
	extraWidgets.optionsButton:destroy()
	extraWidgets.audioButton:destroy()

	panels = {}
	extraWidgets = {}
	buttons = {}

	Keybind.delete("UI", "Toggle Fullscreen")
	Keybind.delete("UI", "Show/hide Creature Names and Bars")
	Keybind.delete("UI", "Show/hide FPS / lag indicator")
	Keybind.delete("Sound", "Mute/unmute music")
	Keybind.delete("UI", "Open Custom Hotkeys")
	Keybind.delete("UI", "Switch Hotkey Preset")
	terminate_custom_hotkeys()
	terminate_binds()
end

function controller:onGameStart()
	if g_settings.getBoolean("autoSwitchPreset") then
		local name = g_game.getCharacterName()

		if name and name ~= "" and Keybind.presetToIndex[name] then
			if panels and panels.keybindsPanel and panels.keybindsPanel.presets and panels.keybindsPanel.presets.list then
				panels.keybindsPanel.presets.list:setCurrentOption(name, true)
			end

			updateKeybinds()
		end
	end

	local allowInspectOption = options.allowInspect

	if allowInspectOption then
		local value = allowInspectOption.pendingValue

		if value == nil then
			value = allowInspectOption.value ~= nil and allowInspectOption.value or allowInspectOption
		end

		if g_game.inspectionPlayer then
			local flag = value and InspectionParseFlags.AllowAll or InspectionParseFlags.DismissAll

			g_game.inspectionPlayer(flag)
		end
	end
end

local function commitDeferredOptions()
	if not modules.game_interface then
		return
	end

	suppressManaShieldPlacementOptionWrite = true
	suppressHarmonyPlacementOptionWrite = true

	for key, option in pairs(options) do
		if option.deferAction and option.pendingValue ~= nil and option.pendingValue ~= option.value then
			setOption(key, option.pendingValue, true)
		elseif option.deferAction then
			option.pendingValue = nil
		end
	end

	suppressManaShieldPlacementOptionWrite = false
	suppressHarmonyPlacementOptionWrite = false

	if modules.game_healthcircle and modules.game_healthcircle.syncManaShieldHudOptions then
		modules.game_healthcircle.syncManaShieldHudOptions(options)
	end
end

function revertDeferredOptions()
	if not panels then
		return
	end

	suppressManaShieldPlacementOptionWrite = true
	suppressHarmonyPlacementOptionWrite = true

	for key, option in pairs(options) do
		if option.deferAction and option.pendingValue ~= nil then
			for _, panel in pairs(panels) do
				local widget = panel:recursiveGetChildById(key)

				if widget then
					local cls = widget:getStyle() and widget:getStyle().__class or ""

					if cls == "UICheckBox" or cls == "QtCheckBox" or cls == "OptionCheckBox" or cls == "OptionCheckBoxMarked" or cls == "RoundedCheckBox" then
						widget:setChecked(option.value)

						break
					end

					if cls == "UIScrollBar" then
						widget:setValue(option.value)

						break
					end

					if widget:recursiveGetChildById("valueBar") then
						widget:recursiveGetChildById("valueBar"):setValue(option.value)
					end

					break
				end
			end

			option.pendingValue = nil
		end
	end

	suppressManaShieldPlacementOptionWrite = false
	suppressHarmonyPlacementOptionWrite = false

	updateShowExpiryOnUnusedAvailability(panels, options.showExpiryInContainers.value)
	updateBigMouseCursorAvailability(panels, options.useNativeMouseCursor.value)
	updateHudDependencyAvailability(panels, options.showHudForOwnCharacter.value, options.showHudForOtherCreatures.value)

	if options.conditionsDisplaySettings then
		refreshConditionsListUi(panels, options.conditionsDisplaySettings.value)
	end

	updateBackgroundFrameRatePreview(panels)
end

-- The render backend can be switched ONLY at startup (the whole graphics context together with
-- textures must be torn down and recreated), so writing to config.ini and restarting is done only
-- when the settings are confirmed. Nil = the selection has not been touched since the last confirmation.
pendingRenderBackendFrom = nil

local function commitRenderBackendChange()
	local from = pendingRenderBackendFrom

	pendingRenderBackendFrom = nil

	if from == nil then
		return
	end

	local to = getOption("graphicsEngine")

	if from == to or not g_configs.setRenderBackend then
		return
	end

	-- 3 = Vulkan, the rest = the existing path
	g_configs.setRenderBackend(to == 3 and "vulkan" or "gl")

	local function doRestart()
		if g_app and g_app.restart then
			g_app.restart()
		end
	end

	if g_game.isOnline() then
		-- while in game we do not kick the player without asking - a restart breaks the server connection
		displayGeneralBox(tr("Restart required"),
			tr("Changing the graphics engine requires a client restart.\nYou are currently logged in - restart now?"), {
				{ text = tr("Restart"), callback = doRestart },
				{ text = tr("Later"), callback = function() end }
			}, doRestart, function() end)
	else
		scheduleEvent(doRestart, 200)
	end
end

function applyOptions()
	commitDeferredOptions()
	commitRenderBackendChange()

	if applyChangedOptions then
		applyChangedOptions()
	end

	g_settings.save()
	show()
end

function okOptions()
	commitDeferredOptions()
	commitRenderBackendChange()

	if applyChangedOptions then
		applyChangedOptions()
	end

	tryCloseOptions()
end

function cancelOptions()
	if not hasAtLeastOneRotateHoldModifier() then
		showRotateHoldWarning()

		return
	end

	-- Cancelling: we do not save the backend and do not restart. The list value itself reverts
	-- together with the rest of the deferred settings.
	pendingRenderBackendFrom = nil

	revertDeferredOptions()

	if revertKeybindChanges then
		revertKeybindChanges()
	end

	g_settings.save()
	hide()
end

function onHarmonyPlacementChange(widget)
	if suppressHarmonyPlacementOptionWrite then
		return
	end

	if updatingHarmonyPlacement then
		return
	end

	local hud = panels and panels.interfaceHUD

	if not hud or not widget then
		return
	end

	local healthCb = hud:recursiveGetChildById("harmonyNextToHealth")
	local manaCb = hud:recursiveGetChildById("harmonyNextToMana")

	if not healthCb or not manaCb then
		return
	end

	local id = widget:getId()

	if id ~= "harmonyNextToHealth" and id ~= "harmonyNextToMana" then
		return
	end

	local nextToHealth = id == "harmonyNextToHealth"

	updatingHarmonyPlacement = true

	healthCb:setChecked(nextToHealth)
	manaCb:setChecked(not nextToHealth)

	updatingHarmonyPlacement = false

	setOption("harmonyNextToHealth", nextToHealth)
	setOption("harmonyNextToMana", not nextToHealth)

	if modules.game_healthcircle and modules.game_healthcircle.syncManaShieldHudOptions then
		modules.game_healthcircle.syncManaShieldHudOptions(options)
	end
end

function onManaShieldPlacementChange(widget)
	if suppressManaShieldPlacementOptionWrite then
		return
	end

	if updatingManaShieldPlacement then
		return
	end

	local hud = panels and panels.interfaceHUD

	if not hud or not widget then
		return
	end

	local healthCb = hud:recursiveGetChildById("manaShieldNextToHealth")
	local manaCb = hud:recursiveGetChildById("manaShieldNextToMana")

	if not healthCb or not manaCb then
		return
	end

	local id = widget:getId()

	if id ~= "manaShieldNextToHealth" and id ~= "manaShieldNextToMana" then
		return
	end

	local nextToHealth = id == "manaShieldNextToHealth"

	updatingManaShieldPlacement = true

	healthCb:setChecked(nextToHealth)
	manaCb:setChecked(not nextToHealth)

	updatingManaShieldPlacement = false

	setOption("manaShieldNextToHealth", nextToHealth)
	setOption("manaShieldNextToMana", not nextToHealth)
end

local function syncOptionWidgetAcrossPanels(key, value)
	if not panels then
		return
	end

	for _, panel in pairs(panels) do
		if panel then
			local widget = panel:recursiveGetChildById(key)

			if widget then
				local cls = widget:getStyle() and widget:getStyle().__class or ""

				if cls == "UICheckBox" or cls == "QtCheckBox" or cls == "OptionCheckBox" or cls == "OptionCheckBoxMarked" or cls == "RoundedCheckBox" then
					widget:setChecked(value)
				elseif cls == "UIScrollBar" then
					widget:setValue(value)
				elseif widget:recursiveGetChildById("valueBar") then
					widget:recursiveGetChildById("valueBar"):setValue(value)
				end
			end
		end
	end
end

function syncShowCustomisableStatusBarsOption(visible)
	local opt = options.showCustomisableStatusBars

	if not opt then
		return
	end

	opt.value = visible
	opt.pendingValue = nil

	g_settings.set("showCustomisableStatusBars", visible)
	syncOptionWidgetAcrossPanels("showCustomisableStatusBars", visible)
end

function updateReverseCheckboxLayout(widget)
	if not widget then
		return
	end

	local textWidth = widget:getTextSize().width

	widget:setImageOffset({
		y = 0,
		x = textWidth + 4
	})
end

function setOption(key, value, force)
	if not modules.game_interface then
		return
	end

	local option = options[key]

	if option == nil then
		return
	end

	if ROTATE_HOLD_KEYS[key] then
		value = normalizeRotateHoldOption(value)
	end

	if key == "backgroundFrameRate" and (value <= 0 or value > 240) then
		value = 240
	end

	if key == "backgroundFrameRate" and not force then
		local noLimitActive = getEffectiveOptionValue("noFrameRateLimit") == true

		if noLimitActive then
			return
		end
	end

	if option.deferAction and not force then
		if option.value == value then
			option.pendingValue = nil

			if key == "noFrameRateLimit" or key == "backgroundFrameRate" then
				updateBackgroundFrameRatePreview(panels)
			end

			return
		end

		option.pendingValue = value

		if key == "showExpiryInContainers" then
			updateShowExpiryOnUnusedAvailability(panels, value)
		end

		if key == "useNativeMouseCursor" then
			updateBigMouseCursorAvailability(panels, value)
		end

		if key == "showHudForOwnCharacter" or key == "showHudForOtherCreatures" or key == "showOwnBars" or key == "showManaShield" or key == "showOwnHarmony" then
			refreshHudDependencyAvailability(panels)
			addEvent(function()
				refreshHudDependencyAvailability(panels)
			end)
		end

		if key == "noFrameRateLimit" or key == "backgroundFrameRate" then
			updateBackgroundFrameRatePreview(panels)
		end

		if type(value) == "boolean" then
			syncOptionWidgetAcrossPanels(key, value)
		end

		return
	end

	if not force and option.value == value then
		return
	end

	option.value = value

	if option.action then
		option.action(value, options, controller, panels, extraWidgets)
	end

	syncOptionWidgetAcrossPanels(key, value)
	g_settings.set(key, value)

	if option.deferAction then
		option.pendingValue = nil
	end

	if ROTATE_HOLD_KEYS[key] then
		scheduleRebindTurnKeys()
	end

	if key == "showHudForOwnCharacter" or key == "showHudForOtherCreatures" or key == "showOwnBars" or key == "showManaShield" or key == "showOwnHarmony" then
		refreshHudDependencyAvailability(panels)
	end
end

function persistOption(key, value)
	local option = options[key]

	if option == nil then
		return false
	end

	if ROTATE_HOLD_KEYS[key] then
		value = normalizeRotateHoldOption(value)
	end

	if key == "backgroundFrameRate" and (value <= 0 or value > 240) then
		value = 240
	end

	option.value = value

	g_settings.set(key, value)

	return true
end

function persistImportedOptions(optionMap)
	if type(optionMap) ~= "table" then
		return 0
	end

	local count = 0

	for key, value in pairs(optionMap) do
		if persistOption(key, value) then
			count = count + 1
		end
	end

	return count
end

function openManageShortcutsPage()
	if not controller.ui:isVisible() then
		show()
	end

	local opened = openOptionsCategory("Interfaces", "Shortcuts")

	if not opened then
		openOptionsCategory("Shortcuts")
	end

	refreshShortcuts()
	updateKeybinds()
end

function openManageShortcutsMenu(mousePos)
	local menu = g_ui.createWidget("PopupMenu")

	menu:setGameMenu(true)
	menu:addOption(tr("Manage Shortcuts"), function()
		openManageShortcutsPage()
	end)
	menu:setWidth(168)
	menu:display(mousePos)
end

function setupOptionsMainButton()
	if not extraWidgets.optionsButtons then
		extraWidgets.optionsButtons = modules.game_mainpanel.addSpecialToggleButton("optionsMainButton", tr("Options"), "/images/options/button_options", toggle, true)
	end

	if not extraWidgets.manageShortcutsButton then
		extraWidgets.manageShortcutsButton = modules.game_mainpanel.addToggleButton("manageShortcuts", tr("Click to Manage Your Shortcuts"), "/images/options/button_manage_shortcuts", function()
			openManageShortcutsPage()
		end, false, 999)
	end

	if not extraWidgets.taskBoardButton then
		extraWidgets.taskBoardButton = modules.game_mainpanel.addToggleButton("taskBoard", tr("Open Task Board"), "/images/options/button_task_board", function()
			if modules.game_taskboard and type(modules.game_taskboard.TaskBoard.toggleWindow) == "function" then
				modules.game_taskboard.TaskBoard:toggleWindow("bounty")
			end
		end, false, 1000)
	end

	if not extraWidgets.spellListButton then
		extraWidgets.spellListButton = modules.game_mainpanel.addToggleButton("spellListWidget", tr("Open Spell List"), "/images/options/button_spell_list", function()
			local spellModule = g_modules.getModule("game_spelllist")

			if spellModule and not spellModule:isLoaded() then
				spellModule:load()
			end

			if modules.game_spelllist and type(modules.game_spelllist.toggle) == "function" then
				modules.game_spelllist.toggle()
			end
		end, false, 1001)
	end
end

function getOption(key)
	if key == "hotkeyDelay" and options.useDefaultHotkeyDelay and options.useDefaultHotkeyDelay.value then
		return 250
	end

	if (key == "walkTurnDelay" or key == "walkTeleportDelay" or key == "walkStairsDelay") and options.useDefaultWalkDelay and options.useDefaultWalkDelay.value then
		return 100
	end

	local entry = options[key]

	if not entry then
		return nil
	end

	local v = entry.value

	if ROTATE_HOLD_KEYS[key] then
		return normalizeRotateHoldOption(v)
	end

	return v
end

function hasAtLeastOneRotateHoldModifier()
	return getOption("rotateHoldCtrl") or getOption("rotateHoldShift") or getOption("rotateHoldAlt")
end

function showRotateHoldWarning()
	controller.ui:hide()

	local box = g_ui.createWidget("RotateHoldWarningMessageBox", rootWidget)

	box:getChildById("title"):setText(tr("Warning"))
	box:getChildById("content"):setText(tr("Select one of the keys to rotate you character! If you do not select a key, you will not be able to manually\nrotate your character."))

	local function dismiss()
		box:destroy()
		show()
	end

	local btn = box:addButton(tr("Ok"), dismiss)

	btn:setSize("43 20")
	btn:setTextOffset("0 0")
	btn:addAnchor(AnchorTop, "parent", AnchorTop)
	btn:addAnchor(AnchorRight, "parent", AnchorRight)
	connect(box, {
		onEnter = dismiss,
		onEscape = dismiss
	})
	box:raise()
	box:focus()
end

function show()
	controller.ui:show()
	g_modalManager.show(controller.ui)
	startCurrentFrameRatePoll()
end

function hide()
	stopCurrentFrameRatePoll()
	g_modalManager.hide(controller.ui)
	controller.ui:hide()
end

function tryCloseOptions()
	if not hasAtLeastOneRotateHoldModifier() then
		showRotateHoldWarning()

		return
	end

	g_settings.save()
	hide()
end

local function findCategoryByTitle(title)
	for i = 1, controller.ui.optionsTabBar:getChildCount() do
		local category = controller.ui.optionsTabBar:getChildByIndex(i)

		if category and category.Button and category.Button.Title and category.Button.Title:getText() == title then
			return category
		end
	end

	return nil
end

function toggle()
	if controller.ui:isVisible() then
		okOptions()

		return
	end

	local defaultCategory = findCategoryByTitle("Controls") or controller.ui.optionsTabBar:getChildByIndex(1)

	if defaultCategory and defaultCategory.Button then
		defaultCategory.Button:onClick()
	end

	show()
	updateKeybinds()
end

function addTab(name, panel, icon)
	print("to prevent the error use Ex = g_ui.loadUI('option_healthcircle',modules.client_options:getPanel()) ")
end

function removeTab(v)
	print("to prevent the error use Ex   modules.client_options.addButton('Interface', 'HP/MP Circle', optionPanel)")
end

local function toggleSubCategories(parent, isOpen)
	for subId, _ in ipairs(parent.subCategories) do
		local subWidget = parent:getChildById(subId)

		if subWidget then
			subWidget:setVisible(isOpen)
		end
	end

	parent:setHeight(isOpen and parent.openedSize or parent.closedSize)

	parent.opened = isOpen

	parent.Button.Arrow:setVisible(not isOpen)
end

local function close(parent)
	if parent.subCategories then
		toggleSubCategories(parent, false)
	end
end

local function open(parent)
	local oldOpen = controller.ui.openedCategory

	if oldOpen and oldOpen ~= parent then
		close(oldOpen)
	end

	toggleSubCategories(parent, true)

	controller.ui.openedCategory = parent
end

local function setCategoryVisualState(buttonWidget, isChecked)
	if not buttonWidget then
		return
	end

	buttonWidget:setChecked(isChecked)

	if buttonWidget.Icon then
		buttonWidget.Icon:setMarginLeft(isChecked and 7 or 6)
		buttonWidget.Icon:setMarginTop(isChecked and 1 or 0)
	end

	if buttonWidget.Title then
		buttonWidget.Title:setTextOffset({
			y = 0,
			x = isChecked and 1 or 0
		})
		buttonWidget.Title:setMarginTop(isChecked and 2 or 1)
	end
end

function selectCharacterPage()
	local selectedOption = controller.ui.selectedOption

	if selectedOption then
		selectedOption:hide()
	end

	if controller.ui.InfoBase then
		controller.ui.InfoBase:setVisible(true)
		controller.ui.InfoBase:show()
	end
end

local function createSubWidget(parent, subId, subButton)
	local subWidget = g_ui.createWidget("OptionsCategory", parent)

	subWidget:setId(subId)
	subWidget.Button.Icon:setIcon(subButton.icon)
	subWidget.Button.Title:setText(subButton.text)
	subWidget:setVisible(false)

	subWidget.open = subButton.open
	subWidget.callbackFunc = subButton.callbackFunc

	subWidget:setImageSource("")
	subWidget:setImageBorder(0)
	subWidget:setHeight(SUBCATEGORY_HEIGHT)
	setCategoryVisualState(subWidget.Button, false)

	function subWidget.Button.onClick()
		local selectedOption = controller.ui.selectedOption

		closeCharacterButtons()
		setCategoryVisualState(parent.Button, false)
		parent.Button.Arrow:setVisible(true)
		parent.Button.Arrow:setImageSource("")
		setCategoryVisualState(subWidget.Button, true)
		subWidget.Button.Arrow:setVisible(true)
		subWidget.Button.Arrow:setImageSource("/images/ui/icon-arrow7x7-right")

		if selectedOption then
			selectedOption:hide()
		end

		local panelToShow = panels[subWidget.open]

		if panelToShow then
			panelToShow:show()
			panelToShow:setVisible(true)

			controller.ui.selectedOption = panelToShow

			if subWidget.open == "interfaceHUD" then
				refreshConditionsListOnHudOpen()
			elseif subWidget.open == "customHotkeysPanel" then
				updateCustomHotkeys()
			elseif subWidget.open == "shortcuts" then
				refreshShortcuts()
			end
		else
			print("Error: panelToShow is nil or does not exist in panels")
		end

		if subWidget.callbackFunc then
			subWidget.callbackFunc()
		end
	end

	subWidget:addAnchor(AnchorHorizontalCenter, "parent", AnchorHorizontalCenter)

	if subId == 1 then
		subWidget:addAnchor(AnchorTop, "parent", AnchorTop)
		subWidget:setMarginTop(20)
	else
		subWidget:addAnchor(AnchorTop, "prev", AnchorBottom)
		subWidget:setMarginTop(1)
	end

	return subWidget
end

local function clearCharacterCategoryHandlers()
	controller.ui.openedCategory = nil

	for i = 1, controller.ui.optionsTabBar:getChildCount() do
		local widget = controller.ui.optionsTabBar:getChildByIndex(i)

		if not widget then
			-- block empty
		else
			if widget.Button then
				widget.Button.onClick = nil
			end

			if widget.subCategories then
				for subId in ipairs(widget.subCategories) do
					local subWidget = widget:getChildById(subId)

					if subWidget and subWidget.Button then
						subWidget.Button.onClick = nil
					end
				end
			end
		end
	end
end

function configureCharacterCategories()
	clearCharacterCategoryHandlers()
	controller.ui.optionsTabBar:destroyChildren()

	for id, button in ipairs(buttons) do
		local widget = g_ui.createWidget("OptionsCategory", controller.ui.optionsTabBar)

		widget:setId(id)
		widget.Button.Icon:setIcon(button.icon)
		widget.Button.Title:setText(button.text)

		widget.open = button.open

		if button.subCategories then
			widget.subCategories = button.subCategories
			widget.subCategoriesSize = #button.subCategories

			widget.Button.Arrow:setVisible(true)

			for subId, subButton in ipairs(button.subCategories) do
				local subWidget = createSubWidget(widget, subId, subButton)

				if button.text == "Controls" then
					subWidget.Button.Title:setMarginLeft(-5)
				end
			end
		end

		widget:addAnchor(AnchorHorizontalCenter, "parent", AnchorHorizontalCenter)

		if id == 1 then
			widget:addAnchor(AnchorTop, "parent", AnchorTop)
			widget:setMarginTop(7)
		else
			widget:addAnchor(AnchorTop, "prev", AnchorBottom)
			widget:setMarginTop(11)
		end

		function widget.Button.onClick()
			local parent = widget
			local oldOpen = controller.ui.openedCategory

			if oldOpen and oldOpen ~= parent then
				if oldOpen.Button then
					setCategoryVisualState(oldOpen.Button, false)
					oldOpen.Button.Arrow:setImageSource("/images/ui/icon-arrow7x7-down")
				end

				close(oldOpen)
			end

			if parent.subCategoriesSize then
				parent.closedSize = parent.closedSize or CATEGORY_BASE_HEIGHT
				parent.openedSize = parent.openedSize or CATEGORY_BASE_HEIGHT + parent.subCategoriesSize * SUBCATEGORY_HEIGHT

				if not parent.opened then
					open(parent)
				end
			end

			setCategoryVisualState(widget.Button, true)
			widget.Button.Arrow:setImageSource("/images/ui/icon-arrow7x7-right")
			widget.Button.Arrow:setVisible(true)

			if controller.ui.selectedOption then
				controller.ui.selectedOption:hide()
			end

			local panelToShow = panels[parent.open]

			if panelToShow then
				closeCharacterButtons()
				panelToShow:show()
				panelToShow:setVisible(true)

				controller.ui.selectedOption = panelToShow

				if parent.open == "shortcuts" then
					refreshShortcuts()
				end
			else
				print("Error: panelToShow is nil or does not exist in panels")
			end

			controller.ui.openedCategory = parent
		end
	end
end

function closeCharacterButtons()
	for i = 1, controller.ui.optionsTabBar:getChildCount() do
		local widget = controller.ui.optionsTabBar:getChildByIndex(i)

		if widget and widget.subCategories then
			for subId, _ in ipairs(widget.subCategories) do
				local subWidget = widget:getChildById(subId)

				if subWidget then
					setCategoryVisualState(subWidget.Button, false)
					subWidget.Button.Arrow:setVisible(false)
				end
			end
		end
	end
end

function createCategory(text, icon, openPanel, subCategories)
	local newCategory = {
		text = text,
		icon = icon,
		open = type(openPanel) == "string" and openPanel or getPanelName(openPanel),
		subCategories = subCategories
	}

	table.insert(buttons, newCategory)

	if type(openPanel) ~= "string" then
		panels[getPanelName(openPanel)] = openPanel
	end

	configureCharacterCategories()
end

function removeCategory(categoryText, subcategoryText)
	for i, category in ipairs(buttons) do
		if category.text == categoryText then
			if subcategoryText then
				if category.subCategories then
					for j, subcategory in ipairs(category.subCategories) do
						if subcategory.text == subcategoryText then
							panels[subcategory.open] = nil

							table.remove(category.subCategories, j)

							break
						end
					end
				end
			else
				panels[category.open] = nil

				if category.subCategories then
					for _, subcategory in ipairs(category.subCategories) do
						panels[subcategory.open] = nil
					end
				end

				table.remove(buttons, i)
			end

			configureCharacterCategories()

			return
		end
	end
end

function removeButton(categoryText, buttonText)
	for _, category in ipairs(buttons) do
		if category.text == categoryText and category.subCategories then
			for i, subcategory in ipairs(category.subCategories) do
				if subcategory.text == buttonText then
					panels[subcategory.open] = nil

					table.remove(category.subCategories, i)
					configureCharacterCategories()

					return
				end
			end
		end
	end
end

function addButton(categoryText, buttonText, openPanel, callback)
	for _, category in ipairs(buttons) do
		if category.text == categoryText then
			if not category.subCategories then
				category.subCategories = {}
			end

			local panelName = type(openPanel) == "string" and openPanel or getPanelName(openPanel)

			table.insert(category.subCategories, {
				text = buttonText,
				open = panelName,
				callbackFunc = callback
			})

			if type(openPanel) ~= "string" then
				panels[panelName] = openPanel
			end

			configureCharacterCategories()

			return
		end
	end
end

function getPanelName(panel)
	for name, p in pairs(panels) do
		if p == panel then
			return name
		end
	end

	return "panel_" .. tostring(panel):match("userdata: 0x(%x+)")
end

function addSubcategoryToCategory(categoryText, newSubcategory)
	addButtonToCategory(categoryText, newSubcategory)
end

function getPanel()
	return controller.ui.optionsTabContent
end

function openOptionsCategory(category, subcategory)
	if not controller.ui:isVisible() then
		show()
	end

	for i = 1, controller.ui.optionsTabBar:getChildCount() do
		local widget = controller.ui.optionsTabBar:getChildByIndex(i)

		if widget and widget.Button.Title:getText() == category then
			widget.Button:onClick()

			if subcategory and widget.subCategories then
				for subId, _ in ipairs(widget.subCategories) do
					local subWidget = widget:getChildById(subId)

					if subWidget and subWidget.Button.Title:getText() == subcategory then
						subWidget.Button:onClick()

						return true
					end
				end
			end

			return true
		end
	end

	return false
end

function setUISoundConsoleMessagesEnabled(state)
	local uiVolume = panels.uiSoundsPanel:recursiveGetChildById("uiVolume")
	local consoleMessages = panels.uiSoundsPanel:recursiveGetChildById("consoleMessages")
	local valueBar = uiVolume:getChildById("valueBar")

	if state == true and (valueBar:getValue() == 0 or not consoleMessages:isChecked()) then
		return
	end

	local subCheckboxes = {
		"party",
		"guild",
		"privateMessagesLocalChat",
		"privateMessages",
		"npcs",
		"global",
		"teamFinder",
		"raidAnnouncements",
		"systemAnnouncements"
	}

	for _, name in ipairs(subCheckboxes) do
		local widget = panels.uiSoundsPanel:recursiveGetChildById(name)

		if widget then
			widget:setEnabled(state)
		end
	end
end

function setUIItemVolumeEnabled(state)
	local itemVolume = panels.soundPanel:recursiveGetChildById("itemVolume")
	local valueBar = itemVolume:getChildById("valueBar")

	if state == true and valueBar:getValue() == 0 then
		return
	end

	panels.soundPanel:recursiveGetChildById("foodAndBeverages"):setEnabled(state)
	panels.soundPanel:recursiveGetChildById("moveItem"):setEnabled(state)
end

function setUISoundsEnabled(state)
	local uiVolume = panels.uiSoundsPanel:recursiveGetChildById("uiVolume")
	local valueBar = uiVolume:getChildById("valueBar")

	if state == true and valueBar:getValue() == 0 then
		return
	end

	panels.uiSoundsPanel:recursiveGetChildById("uiInteractions"):setEnabled(state)
	panels.uiSoundsPanel:recursiveGetChildById("toggleParty"):setEnabled(state)
	panels.uiSoundsPanel:recursiveGetChildById("toggleVip"):setEnabled(state)
	panels.uiSoundsPanel:recursiveGetChildById("consoleMessages"):setEnabled(state)
	setUISoundConsoleMessagesEnabled(state)
end

function setMusicVolumeEnabled(state)
	local musicVolume = panels.soundPanel:recursiveGetChildById("musicVolume")
	local valueBar = musicVolume:getChildById("valueBar")

	if state == true and valueBar:getValue() == 0 then
		return
	end

	panels.soundPanel:recursiveGetChildById("anthem"):setEnabled(state)
end

function setOwnBattleSoundEnabled(state)
	local ownBattleVolume = panels.battleSoundsPanel:recursiveGetChildById("ownBattleVolume")
	local valueBar = ownBattleVolume:getChildById("valueBar")

	if state == true and valueBar:getValue() == 0 then
		return
	end

	panels.battleSoundsPanel:recursiveGetChildById("ownSpells"):setEnabled(state)
	panels.battleSoundsPanel:recursiveGetChildById("ownAttack"):setEnabled(state)
	panels.battleSoundsPanel:recursiveGetChildById("ownHealing"):setEnabled(state)
	panels.battleSoundsPanel:recursiveGetChildById("ownSupport"):setEnabled(state)
	panels.battleSoundsPanel:recursiveGetChildById("ownWeapons"):setEnabled(state)
end

function setOtherPlayersBattleSoundEnabled(state)
	local otherPlayersVolume = panels.battleSoundsPanel:recursiveGetChildById("otherPlayersVolume")
	local valueBar = otherPlayersVolume:getChildById("valueBar")

	if state == true and valueBar:getValue() == 0 then
		return
	end

	panels.battleSoundsPanel:recursiveGetChildById("otherSpells"):setEnabled(state)
	panels.battleSoundsPanel:recursiveGetChildById("otherAttack"):setEnabled(state)
	panels.battleSoundsPanel:recursiveGetChildById("otherHealing"):setEnabled(state)
	panels.battleSoundsPanel:recursiveGetChildById("otherSupport"):setEnabled(state)
	panels.battleSoundsPanel:recursiveGetChildById("otherWeapons"):setEnabled(state)
end

function setCreatureBattleSoundEnabled(state)
	local creaturesVolume = panels.battleSoundsPanel:recursiveGetChildById("creaturesVolume")
	local valueBar = creaturesVolume:getChildById("valueBar")

	if state == true and valueBar:getValue() == 0 then
		return
	end

	panels.battleSoundsPanel:recursiveGetChildById("creatureNoises"):setEnabled(state)
	panels.battleSoundsPanel:recursiveGetChildById("creatureDeath"):setEnabled(state)
	panels.battleSoundsPanel:recursiveGetChildById("attackAndSpells"):setEnabled(state)
end

function setAllUISoundState(state)
	panels.soundPanel:recursiveGetChildById("musicVolume"):setEnabled(state)
	panels.soundPanel:recursiveGetChildById("ambienceVolume"):setEnabled(state)
	panels.soundPanel:recursiveGetChildById("itemVolume"):setEnabled(state)
	panels.soundPanel:recursiveGetChildById("eventVolume"):setEnabled(state)
	panels.uiSoundsPanel:recursiveGetChildById("uiVolume"):setEnabled(state)
	panels.battleSoundsPanel:recursiveGetChildById("ownBattleVolume"):setEnabled(state)
	panels.battleSoundsPanel:recursiveGetChildById("otherPlayersVolume"):setEnabled(state)
	panels.battleSoundsPanel:recursiveGetChildById("creaturesVolume"):setEnabled(state)
	setUISoundsEnabled(state)
	setUIItemVolumeEnabled(state)
	setMusicVolumeEnabled(state)
	setOwnBattleSoundEnabled(state)
	setOtherPlayersBattleSoundEnabled(state)
	setCreatureBattleSoundEnabled(state)
end
