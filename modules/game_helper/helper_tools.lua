-- chunkname: @/game_helper/helper_tools.lua

HelperTools = HelperTools or {}

local ctx
local toolsUiLanguage = "en"
local TOOLS_HELP_TEXT = {
	en = {
		changeGold = "Change Gold:<br><li>Every second, converts a stack of 100 gold coins into platinum coins.</li><li>If no gold stack is available, converts a stack of 100 platinum coins into crystal coins.</li><li>The coins must be available in your inventory or accessible containers.</li>",
		manaTraining = "Mana Training:<br><li>Left-click the action slot to select a learned spell; right-click to clear it.</li><li>Casts when current mana is strictly above the selected percentage and the spell cooldown is ready.</li>",
		eatFood = "Eat Food:<br><li>Every 30 seconds, uses an available food item from the configured internal priority list.</li><li>The food must be available in your inventory or accessible containers.</li>",
		antiIdle = "Anti Idle:<br><li>After 5 minutes without walking or turning, rotates your character once every 15 seconds.</li><li>Manual walking or turning restarts the inactivity timer.</li>",
		reconnect = "Reconnect:<br><li>Enables the client native auto-reconnect setting.</li><li>Attempts to log the same character back in after recoverable connection errors.</li><li>A recent manual logout is respected and does not trigger an immediate reconnect.</li>",
		autoTraining = "Auto Training:<br><li>Left-click the slot to select an exercise weapon; right-click to clear it.</li><li>Uses the selected weapon every 10 seconds on the nearest visible exercise dummy within 5 tiles.</li><li>The weapon must be available in your inventory or accessible containers.</li>",
		autoAmmo = "Auto Ammo:<br><li>Left-click the slot to select arrows, bolts or stackable distance ammunition; right-click to clear it.</li><li>Every 20 seconds, when the amount is below Target, performs up to three moves one second apart into an equipped open quiver.</li><li>Stops the cycle early when Target is reached. Stackable hand ammunition is equipped directly from inventory or accessible containers.</li>",
		autoSSA = "Auto SSA:<br><li>Swaps the currently equipped amulet for a Stone Skin Amulet.</li><li>The amulet must be available in your inventory or an accessible container.</li>",
		autoMightRing = "Auto Might Ring:<br><li>Swaps the currently equipped ring for a Might Ring.</li><li>The ring must be available in your inventory or an accessible container.</li>",
		haste = "Haste:<br><li>Left-click the action slot to select a learned haste spell; right-click to clear it.</li><li>Recasts the spell when its duration and cooldown allow it.</li><li>PZ Cast allows the spell to be cast inside protection zones.</li>"
	},
	pt = {
		changeGold = "Trocar Ouro:<br><li>A cada segundo, converte uma pilha de 100 moedas de ouro em moedas de platina.</li><li>Se nao houver uma pilha de ouro, converte 100 moedas de platina em uma moeda de cristal.</li><li>As moedas devem estar no inventario ou em containers acessiveis.</li>",
		manaTraining = "Treino de Mana:<br><li>Clique esquerdo no slot para selecionar uma magia aprendida; clique direito para limpar.</li><li>Conjura quando a mana atual esta estritamente acima da porcentagem selecionada e o cooldown esta pronto.</li>",
		eatFood = "Comer:<br><li>A cada 30 segundos, usa um alimento disponivel conforme a lista interna de prioridade.</li><li>O alimento deve estar no inventario ou em containers acessiveis.</li>",
		antiIdle = "Anti Inatividade:<br><li>Apos 5 minutos sem caminhar ou virar, gira o personagem uma vez a cada 15 segundos.</li><li>Caminhar ou virar manualmente reinicia o contador de inatividade.</li>",
		reconnect = "Reconectar:<br><li>Ativa a reconexao automatica nativa do cliente.</li><li>Tenta conectar novamente o mesmo personagem apos erros de conexao recuperaveis.</li><li>Um logout manual recente e respeitado e nao dispara uma reconexao imediata.</li>",
		autoTraining = "Treino Automatico:<br><li>Clique esquerdo no slot para selecionar uma arma de exercicio; clique direito para limpar.</li><li>Usa a arma a cada 10 segundos no boneco de treino visivel mais proximo em ate 5 sqm.</li><li>A arma deve estar no inventario ou em containers acessiveis.</li>",
		autoAmmo = "Municao Automatica:<br><li>Clique esquerdo no slot para selecionar flechas, bolts ou municao de distancia empilhavel; clique direito para limpar.</li><li>A cada 20 segundos, quando a quantidade fica abaixo do Alvo, faz ate tres movimentos com intervalo de um segundo para o quiver equipado e aberto.</li><li>Interrompe o ciclo ao atingir o Alvo. Municao de mao empilhavel e equipada diretamente do inventario ou de containers acessiveis.</li>",
		autoSSA = "Auto SSA:<br><li>Troca o amuleto equipado por um Stone Skin Amulet.</li><li>O amuleto deve estar no inventario ou em um container acessivel.</li>",
		autoMightRing = "Auto Might Ring:<br><li>Troca o anel equipado por um Might Ring.</li><li>O anel deve estar no inventario ou em um container acessivel.</li>",
		haste = "Acelerar:<br><li>Clique esquerdo no slot para selecionar uma magia de velocidade aprendida; clique direito para limpar.</li><li>Conjura novamente quando a duracao e o cooldown permitirem.</li><li>Conjurar em PZ permite usar a magia dentro de zonas de protecao.</li>"
	}
}
local TOOLS_HELP_WIDGETS = {
	toolsEatFoodHelp = "eatFood",
	toolsChangeGoldHelp = "changeGold",
	toolsManaTrainingHelp = "manaTraining",
	toolsAntiIdleHelp = "antiIdle",
	toolsAutoTrainingHelp = "autoTraining",
	toolsHasteHelp = "haste",
	toolsAutoAmmoHelp = "autoAmmo",
	toolsAutoSSAHelp = "autoSSA",
	toolsAutoMightRingHelp = "autoMightRing",
	toolsReconnectHelp = "reconnect"
}
local TOOLS_UI_TEXT = {
	en = {
		clearAction = "Clear Action",
		selectAmmoFirst = "Select ammunition first.",
		assignExerciseWeapon = "Assign Exercise Weapon",
		selectExerciseWeaponFirst = "Select an exercise weapon first.",
		assignAmmo = "Assign Ammunition",
		typeToSearch = "Type to search",
		noExerciseDummyFound = "No exercise dummy found."
	},
	pt = {
		clearAction = "Limpar Acao",
		selectAmmoFirst = "Selecione uma municao primeiro.",
		assignExerciseWeapon = "Selecionar Arma de Exercicio",
		selectExerciseWeaponFirst = "Selecione uma arma de exercicio primeiro.",
		assignAmmo = "Selecionar Municao",
		typeToSearch = "Digite para pesquisar",
		noExerciseDummyFound = "Nenhum boneco de treino encontrado."
	}
}

local function toolsText(key)
	local texts = TOOLS_UI_TEXT[toolsUiLanguage] or TOOLS_UI_TEXT.en

	return texts[key] or TOOLS_UI_TEXT.en[key] or key
end

local lastAntiIdleTurnMs = 0
local lastActivityMs = 0
local antiIdleSelfTurn = false
local originalGameWalk, originalGameTurn
local lastChangeGoldMs = 0
local lastEatFoodMs = 0
local lastExerciseMs = 0
local lastExerciseDummyMsgMs = 0
local lastAutoAmmoMs = 0
local lastAutoEquipMs = 0
local autoAmmoBurstEvent, toolsTickEvent, antiIdleOutfitEvent
local antiIdleOutfitDirectionIndex = 1
local changeGoldIconEvent
local changeGoldIconIndex = 1
local eatFoodIconEvent
local eatFoodCount = 1
local positionConnected = false
local trainingSlot, configuredTrainingItemId
local autoTrainingEnabled = false
local ammoSlot, configuredAmmoItemId
local autoAmmoEnabled = false
local autoSSAEnabled = false
local autoMightRingEnabled = false
local autoAmmoTargetCount = 100
local cachedMainCheck, cachedExerciseDummy, cachedExerciseDummyKey
local cachedExerciseDummyAt = 0
local EXERCISE_DUMMY_CACHE_MS = 2500
local toolsItemAssignWindow, toolsItemAssignPanel, toolsItemAssignTargetSlot, toolsItemAssignKind, cachedAmmoAssignList
local ANTI_IDLE_THRESHOLD_MS = 300000
local ANTI_IDLE_INTERVAL_MS = 15000
local CHANGE_GOLD_INTERVAL_MS = 1000
local EAT_FOOD_INTERVAL_MS = 30000
local EXERCISE_INTERVAL_MS = 10000
local EXERCISE_SEARCH_RADIUS = 5
local AUTO_AMMO_INTERVAL_MS = 20000
local AUTO_AMMO_ACTION_DELAY_MS = 1000
local AUTO_AMMO_ACTIONS_PER_CYCLE = 3
local AUTO_AMMO_DEFAULT_TARGET_COUNT = 100
local AUTO_AMMO_COUNT_STEP = 10
local AUTO_AMMO_MAX_COUNT = 1000
local AMMO_STACK_MAX_COUNT = 100
local AUTO_EQUIP_INTERVAL_MS = 1000
local STONE_SKIN_AMULET_ID = 3081
local MIGHT_RING_ID = 3048
local ACTIVE_MIGHT_RING_ID = 3049
local GOLD_COIN_ID = 3031
local PLATINUM_COIN_ID = 3035
local CRYSTAL_COIN_ID = 3043
local CONVERT_STACK_SIZE = 100
local EAT_FOOD_ITEM_ID = 3582
local EAT_FOOD_MAX_COUNT = 5
local EAT_FOOD_PRIORITY_ITEM_IDS = {
	63055,
	63056
}
local EAT_FOOD_FALLBACK_ITEM_IDS = {
	3577,
	3578,
	3579,
	3580,
	3582,
	3583,
	3584,
	3585,
	3586,
	3587,
	3589,
	3592,
	3593,
	3597,
	3602,
	3607,
	3723,
	3725,
	3726,
	3727,
	3731,
	3732,
	5096,
	8010,
	8011,
	8012,
	8013,
	8014,
	8017,
	8194,
	16103,
	21143,
	21144,
	21146
}
local EXERCISE_WEAPON_IDS = {
	50292,
	50293,
	50294,
	50295,
	28540,
	28541,
	28542,
	28543,
	28544,
	28545,
	28552,
	28553,
	28554,
	28555,
	28556,
	28557,
	35279,
	35280,
	35281,
	35282,
	35283,
	35284,
	35285,
	35286,
	35287,
	35288,
	35289,
	35290,
	44064,
	44065,
	44066,
	44067
}
local EXERCISE_DUMMY_IDS = {
	28558,
	28559,
	28560,
	28561,
	28562,
	28563,
	28564,
	28565,
	63007,
	63008,
	63062,
	63063,
	63064,
	63065,
	63066,
	63067,
	63068,
	63069,
	63070,
	63071,
	63113,
	63114,
	63210,
	63211,
	63242,
	63243,
	63244,
	63245,
	63296,
	63297
}
local SLOT_IMG_EMPTY = "/images/game/actionbar/slot-actionbar-empty"
local TURN_DIRS = {
	North,
	East,
	South,
	West
}
local ANTI_IDLE_OUTFIT_DIRECTIONS = {
	South,
	West,
	North,
	East
}
local CHANGE_GOLD_ICON_IDS = {
	GOLD_COIN_ID,
	PLATINUM_COIN_ID,
	CRYSTAL_COIN_ID
}
local turnIdx = 1

local function stopAutoAmmoBurst()
	if autoAmmoBurstEvent then
		removeEvent(autoAmmoBurstEvent)

		autoAmmoBurstEvent = nil
	end
end

local function localizeToolsItemAssignWindow()
	if not toolsItemAssignWindow or toolsItemAssignWindow:isDestroyed() then
		return
	end

	local titleKey = toolsItemAssignKind == "ammo" and "assignAmmo" or "assignExerciseWeapon"

	toolsItemAssignWindow:setText(toolsText(titleKey))

	if ctx and ctx.applyWidgetLanguage then
		ctx.applyWidgetLanguage(toolsItemAssignWindow)
		toolsItemAssignWindow:setText(toolsText(titleKey))
	end

	local filterEdit = toolsItemAssignWindow:recursiveGetChildById("filterTextEdit")

	if filterEdit and filterEdit.setPlaceholder then
		filterEdit:setPlaceholder(toolsText("typeToSearch"))
	end
end

function HelperTools.refreshLanguage(language)
	toolsUiLanguage = language == "pt" and "pt" or "en"

	if not ctx or not ctx.getWidget then
		return
	end

	local texts = TOOLS_HELP_TEXT[toolsUiLanguage] or TOOLS_HELP_TEXT.en

	for widgetId, textKey in pairs(TOOLS_HELP_WIDGETS) do
		local help = ctx.getWidget(widgetId)

		if help and help.setTooltip then
			help:setTooltip(texts[textKey] or TOOLS_HELP_TEXT.en[textKey])
		end
	end

	localizeToolsItemAssignWindow()
end

local function applyAntiIdleOutfitDirection()
	if not ctx then
		return
	end

	local widget = ctx.getWidget("toolsAntiIdleCreature")

	if not widget or widget:isDestroyed() then
		return
	end

	widget:setOutfit({
		type = 127
	})

	local creature = widget.getCreature and widget:getCreature() or nil

	if creature and creature.setDirection then
		creature:setDirection(ANTI_IDLE_OUTFIT_DIRECTIONS[antiIdleOutfitDirectionIndex])
	elseif widget.setDirection then
		widget:setDirection(ANTI_IDLE_OUTFIT_DIRECTIONS[antiIdleOutfitDirectionIndex])
	end
end

local function startAntiIdleOutfitRotation()
	applyAntiIdleOutfitDirection()

	if antiIdleOutfitEvent then
		return
	end

	antiIdleOutfitEvent = cycleEvent(function()
		antiIdleOutfitDirectionIndex = antiIdleOutfitDirectionIndex % #ANTI_IDLE_OUTFIT_DIRECTIONS + 1

		applyAntiIdleOutfitDirection()
	end, 500)
end

local function stopAntiIdleOutfitRotation()
	if antiIdleOutfitEvent then
		removeEvent(antiIdleOutfitEvent)

		antiIdleOutfitEvent = nil
	end
end

local function applyChangeGoldIcon()
	if not ctx then
		return
	end

	local icon = ctx.getWidget("toolsChangeGoldIcon")

	if not icon or icon:isDestroyed() then
		return
	end

	local itemId = CHANGE_GOLD_ICON_IDS[changeGoldIconIndex]

	if Item and Item.create and icon.setItem then
		icon:setItem(Item.create(itemId, CONVERT_STACK_SIZE))
	else
		icon:setItemId(itemId)
	end
end

local function startChangeGoldIconRotation()
	applyChangeGoldIcon()

	if changeGoldIconEvent then
		return
	end

	changeGoldIconEvent = cycleEvent(function()
		changeGoldIconIndex = changeGoldIconIndex % #CHANGE_GOLD_ICON_IDS + 1

		applyChangeGoldIcon()
	end, 500)
end

local function stopChangeGoldIconRotation()
	if changeGoldIconEvent then
		removeEvent(changeGoldIconEvent)

		changeGoldIconEvent = nil
	end
end

local function applyEatFoodIcon()
	if not ctx then
		return
	end

	local icon = ctx.getWidget("toolsEatFoodIcon")

	if not icon or icon:isDestroyed() then
		return
	end

	if Item and Item.create and icon.setItem then
		icon:setItem(Item.create(EAT_FOOD_ITEM_ID, eatFoodCount))
	else
		icon:setItemId(EAT_FOOD_ITEM_ID)
	end
end

local function startEatFoodIconRotation()
	applyEatFoodIcon()

	if eatFoodIconEvent then
		return
	end

	eatFoodIconEvent = cycleEvent(function()
		eatFoodCount = eatFoodCount % EAT_FOOD_MAX_COUNT + 1

		applyEatFoodIcon()
	end, 500)
end

local function stopEatFoodIconRotation()
	if eatFoodIconEvent then
		removeEvent(eatFoodIconEvent)

		eatFoodIconEvent = nil
	end
end

local function refreshWidgetCache()
	if not ctx then
		return
	end

	cachedMainCheck = ctx.getWidget("checkbox")
end

local function clearWidgetCache()
	cachedMainCheck = nil
end

local function invalidateExerciseDummyCache()
	cachedExerciseDummy = nil
	cachedExerciseDummyKey = nil
	cachedExerciseDummyAt = 0
end

local function playerPosCacheKey(pos)
	return (pos.z * 65536 + pos.x) * 65536 + pos.y
end

local function markUserActivity()
	lastActivityMs = g_clock.millis()
end

local function onLocalPosChange(creature, newPos, oldPos)
	local lp = g_game.getLocalPlayer()

	if creature and creature == lp then
		markUserActivity()
		invalidateExerciseDummyCache()
	end
end

local function installActivityHooks()
	if originalGameWalk or originalGameTurn then
		return
	end

	if g_game.walk then
		originalGameWalk = g_game.walk

		function g_game.walk(dir)
			if not antiIdleSelfTurn then
				markUserActivity()
			end

			return originalGameWalk(dir)
		end
	end

	if g_game.turn then
		originalGameTurn = g_game.turn

		function g_game.turn(dir)
			if not antiIdleSelfTurn then
				markUserActivity()
			end

			return originalGameTurn(dir)
		end
	end
end

local function removeActivityHooks()
	if originalGameWalk then
		g_game.walk = originalGameWalk
		originalGameWalk = nil
	end

	if originalGameTurn then
		g_game.turn = originalGameTurn
		originalGameTurn = nil
	end
end

local function isEnabled(featureCheckBoxId)
	if not cachedMainCheck or cachedMainCheck:isDestroyed() then
		refreshWidgetCache()
	end

	if not cachedMainCheck or not cachedMainCheck:isChecked() then
		return false
	end

	local feat = ctx and ctx.getWidget(featureCheckBoxId) or nil

	return feat and feat:isChecked() or false
end

local function isTrainingEnabled()
	if not cachedMainCheck or cachedMainCheck:isDestroyed() then
		refreshWidgetCache()
	end

	if not cachedMainCheck or not cachedMainCheck:isChecked() then
		return false
	end

	return autoTrainingEnabled
end

local function autoSave()
	if modules.game_helper and modules.game_helper.autoSave then
		modules.game_helper.autoSave()
	elseif ctx and ctx.saveConfig then
		ctx.saveConfig()
	end
end

local function setConfiguredTrainingItemId(itemId)
	if itemId and itemId > 0 then
		configuredTrainingItemId = itemId
	else
		configuredTrainingItemId = nil
	end
end

local function updateTrainingSlotVisual(itemId)
	if not trainingSlot or trainingSlot:isDestroyed() then
		return
	end

	local icon = trainingSlot:getChildById("trainingItemIcon")
	local frame = trainingSlot:getChildById("trainingSlotFrame")
	local bg = trainingSlot:getChildById("trainingItemBackground")

	if not icon then
		return
	end

	if itemId and itemId > 0 then
		trainingSlot:setImageSource("")

		if frame then
			frame:show()
		end

		if bg then
			bg:setImageSource("/modules/game_helper/images/background-exercises")
			bg:show()
		end

		icon:setItemId(itemId)
		icon:show()

		if frame then
			trainingSlot:raiseChild(frame)
		end

		if bg then
			trainingSlot:raiseChild(bg)
		end

		trainingSlot:raiseChild(icon)
	else
		trainingSlot:setImageSource(SLOT_IMG_EMPTY)

		if frame then
			frame:hide()
		end

		if bg then
			bg:hide()
		end

		icon:setItemId(0)
		icon:hide()
	end
end

local function clearTrainingSlot()
	setConfiguredTrainingItemId(nil)
	updateTrainingSlotVisual(nil)
	autoSave()
end

local function assignItemToTrainingSlot(slot, itemId)
	setConfiguredTrainingItemId(itemId)
	updateTrainingSlotVisual(itemId)
	autoSave()
end

local function getTrainingItemId()
	if configuredTrainingItemId and configuredTrainingItemId > 0 then
		return configuredTrainingItemId
	end

	return nil
end

local function ammoKindForThingType(thingType)
	if not thingType or not MarketCategory then
		return nil
	end

	local marketData = thingType:getMarketData()
	local category = marketData and marketData.category or nil

	if category == MarketCategory.Ammunition and thingType:isStackable() then
		return "quiver"
	end

	if category == MarketCategory.DistanceWeapons and thingType:isStackable() then
		return "hand"
	end

	return nil
end

local function ammoKindForItemId(itemId)
	if not itemId or itemId <= 0 then
		return nil
	end

	local thingType = g_things.getThingType(itemId, ThingCategoryItem)

	return ammoKindForThingType(thingType)
end

local function normalizeAutoAmmoCount(value, fallback)
	local count = math.floor(tonumber(value) or fallback)

	count = math.floor((count + AUTO_AMMO_COUNT_STEP / 2) / AUTO_AMMO_COUNT_STEP) * AUTO_AMMO_COUNT_STEP

	return math.max(AUTO_AMMO_COUNT_STEP, math.min(AUTO_AMMO_MAX_COUNT, count))
end

local function setConfiguredAmmoItemId(itemId)
	stopAutoAmmoBurst()

	if itemId and itemId > 0 and ammoKindForItemId(itemId) then
		configuredAmmoItemId = itemId
	else
		configuredAmmoItemId = nil
	end
end

local function getAmmoItemId()
	if configuredAmmoItemId and configuredAmmoItemId > 0 then
		return configuredAmmoItemId
	end

	return nil
end

local function updateAmmoSlotVisual(itemId)
	if not ammoSlot or ammoSlot:isDestroyed() then
		return
	end

	local icon = ammoSlot:getChildById("ammoItemIcon")
	local frame = ammoSlot:getChildById("ammoSlotFrame")
	local bg = ammoSlot:getChildById("ammoItemBackground")

	if not icon then
		return
	end

	if itemId and itemId > 0 then
		ammoSlot:setImageSource("")

		if frame then
			frame:show()
		end

		if bg then
			bg:setImageSource("/modules/game_helper/images/background-ammunition")
			bg:show()
		end

		icon:setItemId(itemId)
		icon:show()

		if frame then
			ammoSlot:raiseChild(frame)
		end

		if bg then
			ammoSlot:raiseChild(bg)
		end

		ammoSlot:raiseChild(icon)
	else
		ammoSlot:setImageSource(SLOT_IMG_EMPTY)

		if frame then
			frame:hide()
		end

		if bg then
			bg:hide()
		end

		icon:setItemId(0)
		icon:hide()
	end
end

local function clearAmmoSlot()
	setConfiguredAmmoItemId(nil)
	updateAmmoSlotVisual(nil)

	autoAmmoEnabled = false

	local check = ctx and ctx.getWidget("toolsAutoAmmoCheckBox")

	if check then
		check:setChecked(false)
	end

	autoSave()
end

local function assignItemToAmmoSlot(_, itemId)
	setConfiguredAmmoItemId(itemId)
	updateAmmoSlotVisual(configuredAmmoItemId)
	autoSave()
end

local function playerHasExerciseItem(player, itemId)
	if not player or not itemId or itemId <= 0 then
		return false
	end

	if player.getItemsCount and player:getItemsCount(itemId) > 0 then
		return true
	end

	if player.getInventoryCount and player:getInventoryCount(itemId, 0) > 0 then
		return true
	end

	if g_game.findPlayerItem then
		return g_game.findPlayerItem(itemId, -1, 0) ~= nil
	end

	return false
end

local function findAvailableEatFoodId(player)
	local searchLists = {
		EAT_FOOD_PRIORITY_ITEM_IDS,
		EAT_FOOD_FALLBACK_ITEM_IDS
	}

	for listIndex = 1, #searchLists do
		local itemIds = searchLists[listIndex]

		for i = 1, #itemIds do
			local itemId = itemIds[i]

			if playerHasExerciseItem(player, itemId) then
				return itemId
			end
		end
	end

	return nil
end

local function thingDisplayName(thing, fallbackId)
	if not thing then
		return tostring(fallbackId or "")
	end

	local name = thing:getName()

	if name and name ~= "" then
		return name
	end

	return tostring(fallbackId or "")
end

local function buildExerciseAssignList()
	local items = {}

	for _, itemId in ipairs(EXERCISE_WEAPON_IDS) do
		local thing = g_things.getThingType(itemId, ThingCategoryItem)

		if thing then
			table.insert(items, {
				id = itemId,
				name = thingDisplayName(thing, itemId)
			})
		end
	end

	table.sort(items, function(a, b)
		return a.name:lower() < b.name:lower()
	end)

	return items
end

local function buildAmmoAssignList()
	if cachedAmmoAssignList then
		return cachedAmmoAssignList
	end

	local items = {}

	for _, thingType in ipairs(g_things.getThingTypes(ThingCategoryItem)) do
		if ammoKindForThingType(thingType) then
			local itemId = thingType:getId()

			table.insert(items, {
				id = itemId,
				name = thingDisplayName(thingType, itemId)
			})
		end
	end

	table.sort(items, function(a, b)
		local aName = a.name:lower()
		local bName = b.name:lower()

		return aName == bName and a.id < b.id or aName < bName
	end)

	cachedAmmoAssignList = items

	return cachedAmmoAssignList
end

local function closeToolsItemAssignInternal()
	toolsItemAssignTargetSlot = nil
	toolsItemAssignPanel = nil
	toolsItemAssignKind = nil

	if toolsItemAssignWindow and not toolsItemAssignWindow:isDestroyed() then
		toolsItemAssignWindow:destroy()
	end

	toolsItemAssignWindow = nil
end

local function syncToolsItemAssignOkButton()
	if not toolsItemAssignWindow or toolsItemAssignWindow:isDestroyed() then
		return
	end

	local okBtn = toolsItemAssignWindow:recursiveGetChildById("okButton")

	if not okBtn then
		return
	end

	local focused = toolsItemAssignPanel and toolsItemAssignPanel:getFocusedChild()

	okBtn:setEnabled(focused and focused.assignItemId ~= nil)
end

local function updateToolsItemAssignPreview(row)
	if not toolsItemAssignWindow or toolsItemAssignWindow:isDestroyed() or not row then
		return
	end

	local preview = toolsItemAssignWindow:recursiveGetChildById("spellPreview")

	if not preview then
		return
	end

	local spellIcon = preview:getChildById("previewSpellIcon")
	local itemIcon = preview:getChildById("previewItemIcon")
	local spellGray = preview:getChildById("previewSpellGray")
	local itemGray = preview:getChildById("previewItemGray")
	local nameLabel = preview:getChildById("previewSpellName")
	local wordsLabel = preview:getChildById("previewSpellWords")
	local itemBg = preview:getChildById("previewItemBackground")

	if spellIcon then
		spellIcon:hide()
	end

	if spellGray then
		spellGray:hide()
	end

	if itemIcon then
		itemIcon:show()
		itemIcon:setItemId(row.assignItemId or 0)
	end

	if itemBg then
		local backgroundSource = toolsItemAssignKind == "ammo" and "/modules/game_helper/images/background-ammunition" or "/modules/game_helper/images/background-exercises"

		itemBg:setImageSource(backgroundSource)
		itemBg:show()
	end

	if nameLabel then
		nameLabel:setText(row.assignItemName or "")
	end

	if wordsLabel then
		wordsLabel:setText("")
		wordsLabel:hide()
	end

	if itemGray then
		itemGray:hide()
	end
end

local function clearToolsItemAssignPreview()
	if not toolsItemAssignWindow or toolsItemAssignWindow:isDestroyed() then
		return
	end

	local preview = toolsItemAssignWindow:recursiveGetChildById("spellPreview")

	if not preview then
		return
	end

	local itemIcon = preview:getChildById("previewItemIcon")
	local itemBg = preview:getChildById("previewItemBackground")
	local nameLabel = preview:getChildById("previewSpellName")

	if itemIcon then
		itemIcon:hide()
	end

	if itemBg then
		itemBg:hide()
	end

	if nameLabel then
		nameLabel:setText("")
	end
end

local function focusFirstVisibleToolsItemAssignRow()
	if not toolsItemAssignPanel then
		return
	end

	local first

	for _, row in ipairs(toolsItemAssignPanel:getChildren()) do
		if row:isVisible() then
			first = row

			break
		end
	end

	if first then
		toolsItemAssignPanel:focusChild(first, KeyboardFocusReason)
		updateToolsItemAssignPreview(first)
	else
		toolsItemAssignPanel:focusChild(nil)
		clearToolsItemAssignPreview()
	end

	syncToolsItemAssignOkButton()
end

local function createToolsItemAssignRow(itemId, itemName)
	local row = g_ui.createWidget("HelperAssignListLabel", toolsItemAssignPanel)

	row.assignItemId = itemId
	row.assignItemName = itemName
	row.nameLower = itemName:lower()

	local spellIcon = row:getChildById("spellIcon")

	if spellIcon then
		spellIcon:hide()
	end

	local groupIcon = row:getChildById("groupCooldownIcon")

	if groupIcon then
		groupIcon:hide()
	end

	local levelLabel = row:getChildById("spellLevel")
	local nameLabel = row:getChildById("spellName")
	local wordsLabel = row:getChildById("spellWords")
	local itemIcon = row:getChildById("listItemIcon")

	if itemIcon then
		itemIcon:show()
		itemIcon:setItemId(itemId)
	end

	local itemBg = row:getChildById("listItemBackground")

	if itemBg then
		local backgroundSource = toolsItemAssignKind == "ammo" and "/modules/game_helper/images/background-ammunition" or "/modules/game_helper/images/background-exercises"

		itemBg:setImageSource(backgroundSource)
		itemBg:show()
	end

	if nameLabel then
		nameLabel:setText(itemName)
	end

	if wordsLabel then
		wordsLabel:setText("")
		wordsLabel:hide()
	end

	if levelLabel then
		levelLabel:hide()
	end

	return row
end

local function openToolsItemAssignWindow(targetSlot, assignKind)
	if toolsItemAssignWindow and not toolsItemAssignWindow:isDestroyed() then
		closeToolsItemAssignInternal()
	end

	toolsItemAssignWindow = g_ui.loadUI("assign_helper", g_ui.getRootWidget())

	if not toolsItemAssignWindow then
		return
	end

	toolsItemAssignTargetSlot = targetSlot
	toolsItemAssignKind = assignKind
	toolsItemAssignPanel = toolsItemAssignWindow:recursiveGetChildById("spellsPanel")

	localizeToolsItemAssignWindow()

	local learntPanel = toolsItemAssignWindow:recursiveGetChildById("onlyShowLearntSpellsPanel")

	if learntPanel then
		learntPanel:setVisible(false)
	end

	local okBtn = toolsItemAssignWindow:recursiveGetChildById("okButton")

	if okBtn then
		okBtn:setEnabled(false)
	end

	local entries = assignKind == "ammo" and buildAmmoAssignList() or buildExerciseAssignList()

	for _, entry in ipairs(entries) do
		createToolsItemAssignRow(entry.id, entry.name)
	end

	connect(toolsItemAssignPanel, {
		onChildFocusChange = function(_, focusedChild)
			if not focusedChild then
				syncToolsItemAssignOkButton()

				return
			end

			updateToolsItemAssignPreview(focusedChild)
			syncToolsItemAssignOkButton()
		end
	})
	HelperTools.filterToolsItemAssignEntries("")
	focusFirstVisibleToolsItemAssignRow()
	toolsItemAssignWindow:raise()
	toolsItemAssignWindow:focus()

	local edit = toolsItemAssignWindow:recursiveGetChildById("filterTextEdit")

	if edit then
		edit:focus()
	end
end

local function openTrainingSlotContextMenu(slot)
	local menu = g_ui.createWidget("GamePopupMenu")

	menu:setWidth(220)

	local hasItem = getTrainingItemId() ~= nil

	menu:addOption(toolsText("assignExerciseWeapon"), function()
		openToolsItemAssignWindow(slot, "exercise")
	end)

	if hasItem then
		menu:addSeparator()
		menu:addOption(toolsText("clearAction"), function()
			clearTrainingSlot()
		end)
	end

	menu:display()
end

function bindAutoTrainingSlot()
	if not ctx then
		return
	end

	local slot = ctx.getWidget("toolsAutoTrainingSlot")

	if not slot then
		return
	end

	trainingSlot = slot

	slot:setVisible(true)
	updateTrainingSlotVisual(configuredTrainingItemId)

	function slot:onMouseRelease(mousePos, button)
		if button == MouseRightButton then
			openTrainingSlotContextMenu(self)

			return true
		end

		if button == MouseLeftButton then
			openToolsItemAssignWindow(self, "exercise")

			return true
		end
	end
end

local function openAmmoSlotContextMenu(slot)
	local menu = g_ui.createWidget("GamePopupMenu")

	menu:setWidth(220)
	menu:addOption(toolsText("assignAmmo"), function()
		openToolsItemAssignWindow(slot, "ammo")
	end)

	if getAmmoItemId() then
		menu:addSeparator()
		menu:addOption(toolsText("clearAction"), clearAmmoSlot)
	end

	menu:display()
end

local function bindAutoAmmoSlot()
	if not ctx then
		return
	end

	local slot = ctx.getWidget("toolsAutoAmmoSlot")

	if not slot then
		return
	end

	ammoSlot = slot

	slot:setVisible(true)
	updateAmmoSlotVisual(configuredAmmoItemId)

	local targetCombo = ctx.getWidget("toolsAutoAmmoTargetCombo")

	if targetCombo then
		targetCombo:setCurrentOption(tostring(autoAmmoTargetCount), true)
	end

	function slot:onMouseRelease(_, button)
		if button == MouseRightButton then
			openAmmoSlotContextMenu(self)

			return true
		end

		if button == MouseLeftButton then
			openToolsItemAssignWindow(self, "ammo")

			return true
		end
	end
end

local function getNearestExerciseDummy()
	local lp = g_game.getLocalPlayer()

	if not lp then
		return nil
	end

	local playerPos = lp:getPosition()
	local posKey = playerPosCacheKey(playerPos)
	local now = g_clock.millis()

	if cachedExerciseDummyKey == posKey and now < cachedExerciseDummyAt + EXERCISE_DUMMY_CACHE_MS then
		return cachedExerciseDummy
	end

	local itemList = {}

	for i = 1, #EXERCISE_DUMMY_IDS do
		local id = EXERCISE_DUMMY_IDS[i]
		local items = g_map.findItemsById(id, EXERCISE_SEARCH_RADIUS)

		if items then
			for pos, ptr in pairs(items) do
				if pos.z == playerPos.z then
					itemList[#itemList + 1] = {
						position = pos,
						item = ptr
					}
				end
			end
		end
	end

	local getDistance = HelperTarget and HelperTarget.getDistanceBetween

	if getDistance then
		table.sort(itemList, function(a, b)
			return getDistance(playerPos, a.position) < getDistance(playerPos, b.position)
		end)
	end

	local nearest

	for i = 1, #itemList do
		local data = itemList[i]

		if g_map.isSightClear(data.position, playerPos) then
			nearest = data.item

			break
		end
	end

	cachedExerciseDummy = nearest
	cachedExerciseDummyKey = posKey
	cachedExerciseDummyAt = now

	return nearest
end

local function itemMatchesId(item, itemId)
	return item and item:getId() == itemId
end

local function itemCount(item)
	return item and math.max(1, tonumber(item:getCount()) or 1) or 0
end

local function sameContainerSource(left, right)
	if not left or not right then
		return false
	end

	if left == right then
		return true
	end

	return left:getId() == right:getId()
end

local function findOpenContainerForItem(sourceItem)
	for _, container in pairs(g_game.getContainers()) do
		if sameContainerSource(container:getContainerItem(), sourceItem) then
			return container
		end
	end

	return nil
end

local function findOpenEquippedQuiver(player)
	if not player then
		return nil, nil
	end

	for _, slot in ipairs({
		InventorySlotRight,
		InventorySlotAmmo
	}) do
		local quiver = player:getInventoryItem(slot)

		if quiver and quiver:isQuiver() then
			local container = findOpenContainerForItem(quiver)

			if container then
				return quiver, container
			end
		end
	end

	return nil, nil
end

local function countContainerItem(container, itemId)
	local total = 0

	for _, item in pairs(container:getItems()) do
		if itemMatchesId(item, itemId) then
			total = total + itemCount(item)
		end
	end

	return total
end

local function findAmmoDestination(container, itemId)
	for _, item in pairs(container:getItems()) do
		if itemMatchesId(item, itemId) then
			local count = itemCount(item)

			if count < AMMO_STACK_MAX_COUNT then
				return item:getPosition(), AMMO_STACK_MAX_COUNT - count
			end
		end
	end

	for slot = 0, container:getCapacity() - 1 do
		if not container:getItem(slot) then
			return container:getSlotPosition(slot), AMMO_STACK_MAX_COUNT
		end
	end

	return nil, 0
end

local function findAmmoSource(player, itemId, excludedContainer, excludedItems)
	for slot = InventorySlotFirst, InventorySlotLast do
		local item = player:getInventoryItem(slot)

		if itemMatchesId(item, itemId) and (not excludedItems or not excludedItems[item]) then
			return item
		end
	end

	for _, container in pairs(g_game.getContainers()) do
		if container ~= excludedContainer then
			for _, item in pairs(container:getItems()) do
				if itemMatchesId(item, itemId) and (not excludedItems or not excludedItems[item]) then
					return item
				end
			end
		end
	end

	return nil
end

local function runAutoEquipment()
	if not g_game.isOnline() then
		return
	end

	local now = g_clock.millis()

	if now < lastAutoEquipMs + AUTO_EQUIP_INTERVAL_MS then
		return
	end

	local player = g_game.getLocalPlayer()

	if not player then
		return
	end

	local source
	local requestedItemId
	local destinationSlot

	local equippedAmulet = player:getInventoryItem(InventorySlotNeck)
	local equippedRing = player:getInventoryItem(InventorySlotFinger)
	local hasSSAEquipped = itemMatchesId(equippedAmulet, STONE_SKIN_AMULET_ID)
	local hasMightRingEquipped = itemMatchesId(equippedRing, MIGHT_RING_ID) or itemMatchesId(equippedRing, ACTIVE_MIGHT_RING_ID)

	if autoSSAEnabled and isEnabled("toolsAutoSSACheckBox") and not hasSSAEquipped then
		requestedItemId = STONE_SKIN_AMULET_ID
		source = findAmmoSource(player, STONE_SKIN_AMULET_ID)
		destinationSlot = InventorySlotNeck
	end

	if not requestedItemId and autoMightRingEnabled and isEnabled("toolsAutoMightRingCheckBox") and not hasMightRingEquipped then
		requestedItemId = MIGHT_RING_ID
		source = findAmmoSource(player, MIGHT_RING_ID)
		destinationSlot = InventorySlotFinger
	end

	if requestedItemId and destinationSlot then
		lastAutoEquipMs = now

		if source then
			g_game.move(source, {
				x = 65535,
				y = destinationSlot,
				z = 0
			}, 1)
		else
			g_game.equipItemId(requestedItemId, 0)
		end
	end
end

local function runQuiverAutoAmmo(player, itemId, targetCount)
	local _, quiverContainer = findOpenEquippedQuiver(player)

	if not quiverContainer then
		return false
	end

	local currentCount = countContainerItem(quiverContainer, itemId)

	if targetCount <= currentCount then
		return false
	end

	local destination, destinationCapacity = findAmmoDestination(quiverContainer, itemId)

	if not destination or destinationCapacity <= 0 then
		return false
	end

	local source = findAmmoSource(player, itemId, quiverContainer)

	if not source then
		return false
	end

	local moveCount = math.min(targetCount - currentCount, itemCount(source), destinationCapacity)

	if moveCount > 0 then
		g_game.move(source, destination, moveCount)

		return true
	end

	return false
end

local function runHandAutoAmmo(player, itemId, targetCount)
	local excludedItems = {}
	local equippedCount = 0

	for _, slot in ipairs({
		InventorySlotLeft,
		InventorySlotAmmo
	}) do
		local item = player:getInventoryItem(slot)

		if itemMatchesId(item, itemId) then
			excludedItems[item] = true
			equippedCount = math.max(equippedCount, itemCount(item))
		end
	end

	if targetCount <= equippedCount then
		return false
	end

	local source = findAmmoSource(player, itemId, nil, excludedItems)

	if source then
		g_game.equipItemId(itemId, 0)

		return true
	end

	return false
end

local function performAutoAmmoAction()
	if not isEnabled("toolsAutoAmmoCheckBox") or not autoAmmoEnabled then
		return
	end

	if not g_game.isOnline() then
		return
	end

	local itemId = getAmmoItemId()
	local ammoKind = ammoKindForItemId(itemId)

	if not ammoKind then
		return
	end

	local player = g_game.getLocalPlayer()

	if not player then
		return
	end

	local targetCount = normalizeAutoAmmoCount(autoAmmoTargetCount, AUTO_AMMO_DEFAULT_TARGET_COUNT)

	if ammoKind == "quiver" then
		return runQuiverAutoAmmo(player, itemId, targetCount)
	else
		return runHandAutoAmmo(player, itemId, math.min(targetCount, AMMO_STACK_MAX_COUNT))
	end
end

local function runAutoAmmoBurst(remainingActions)
	autoAmmoBurstEvent = nil

	if remainingActions <= 0 then
		return
	end

	local moved = performAutoAmmoAction()

	if not moved or remainingActions <= 1 then
		return
	end

	autoAmmoBurstEvent = scheduleEvent(function()
		runAutoAmmoBurst(remainingActions - 1)
	end, AUTO_AMMO_ACTION_DELAY_MS)
end

local function runAutoAmmo(force)
	if not isEnabled("toolsAutoAmmoCheckBox") or not autoAmmoEnabled then
		return
	end

	if not g_game.isOnline() then
		return
	end

	local now = g_clock.millis()

	if not force and now < lastAutoAmmoMs + AUTO_AMMO_INTERVAL_MS then
		return
	end

	if force then
		stopAutoAmmoBurst()
	end

	lastAutoAmmoMs = now

	runAutoAmmoBurst(AUTO_AMMO_ACTIONS_PER_CYCLE)
end

local function findConvertibleCoinStack(lp, itemId)
	if not lp or not lp.getItems then
		return nil
	end

	local items = lp:getItems(itemId)

	for i = 1, #items do
		local item = items[i]

		if item and item:getCount() >= CONVERT_STACK_SIZE then
			return item
		end
	end

	return nil
end

local function runChangeGold()
	if not isEnabled("toolsChangeGoldCheckBox") then
		return
	end

	if not g_game.isOnline() then
		return
	end

	local lp = g_game.getLocalPlayer()

	if not lp or not lp.getItems then
		return
	end

	local now = g_clock.millis()

	if now < lastChangeGoldMs + CHANGE_GOLD_INTERVAL_MS then
		return
	end

	lastChangeGoldMs = now

	local goldStack = findConvertibleCoinStack(lp, GOLD_COIN_ID)

	if goldStack then
		g_game.use(goldStack)

		return
	end

	local platinumStack = findConvertibleCoinStack(lp, PLATINUM_COIN_ID)

	if platinumStack then
		g_game.use(platinumStack)
	end
end

local function runEatFood()
	if not isEnabled("toolsEatFoodCheckBox") then
		return
	end

	if not g_game.isOnline() then
		return
	end

	local now = g_clock.millis()

	if now < lastEatFoodMs + EAT_FOOD_INTERVAL_MS then
		return
	end

	local lp = g_game.getLocalPlayer()

	if not lp then
		return
	end

	local foodItemId = findAvailableEatFoodId(lp)

	if not foodItemId then
		return
	end

	lastEatFoodMs = now

	if g_game.useInventoryItem then
		g_game.useInventoryItem(foodItemId)

		return
	end

	if lp and lp.getItems then
		local items = lp:getItems(foodItemId)

		if items and items[1] then
			g_game.use(items[1])
		end
	end
end

local function runAutoTraining(force)
	if not isTrainingEnabled() then
		return
	end

	if not g_game.isOnline() then
		return
	end

	local now = g_clock.millis()

	if not force and now < lastExerciseMs + EXERCISE_INTERVAL_MS then
		return
	end

	local itemId = getTrainingItemId()

	if not itemId then
		return
	end

	local lp = g_game.getLocalPlayer()

	if not lp then
		return
	end

	if not playerHasExerciseItem(lp, itemId) then
		return
	end

	local dummy = getNearestExerciseDummy()

	if not dummy then
		if now >= lastExerciseDummyMsgMs + EXERCISE_INTERVAL_MS then
			lastExerciseDummyMsgMs = now

			modules.game_textmessage.displayGameMessage(toolsText("noExerciseDummyFound"))
		end

		return
	end

	lastExerciseMs = now

	g_game.useInventoryItemWith(itemId, dummy)
end

local function runAntiIdle()
	if not isEnabled("toolsAntiIdleCheckBox") then
		return
	end

	if not g_game.isOnline() then
		return
	end

	local lp = g_game.getLocalPlayer()

	if not lp then
		return
	end

	local now = g_clock.millis()

	if now - lastActivityMs < ANTI_IDLE_THRESHOLD_MS then
		return
	end

	if now - lastAntiIdleTurnMs < ANTI_IDLE_INTERVAL_MS then
		return
	end

	if g_game.turn then
		antiIdleSelfTurn = true

		g_game.turn(TURN_DIRS[turnIdx])

		antiIdleSelfTurn = false
		turnIdx = turnIdx % #TURN_DIRS + 1
		lastAntiIdleTurnMs = now
	end
end

local function applyReconnectFlag()
	local check = ctx.getWidget("toolsReconnectCheckBox")

	if check then
		g_settings.set("autoReconnect", check:isChecked())
	end
end

local function syncReconnectFromSettings()
	local check = ctx.getWidget("toolsReconnectCheckBox")

	if check and g_settings.getBoolean("autoReconnect") then
		check:setChecked(true)
	end
end

function HelperTools.init(pctx)
	ctx = pctx

	HelperTools.refreshLanguage(ctx and ctx.getLanguage and ctx.getLanguage() or "en")
	refreshWidgetCache()

	if not positionConnected then
		connect(Creature, {
			onPositionChange = onLocalPosChange
		})

		positionConnected = true
	end

	markUserActivity()
	installActivityHooks()
	bindAutoTrainingSlot()
	bindAutoAmmoSlot()

	if not toolsTickEvent then
		toolsTickEvent = cycleEvent(function()
			if not g_game.isOnline() then
				return
			end

			if not cachedMainCheck or cachedMainCheck:isDestroyed() then
				refreshWidgetCache()
			end

			local ok, err = pcall(function()
				runAntiIdle()
				runChangeGold()
				runEatFood()
				runAutoTraining()
				runAutoAmmo()
				runAutoEquipment()
			end)

			if not ok and g_logger then
				g_logger.error("[helper_tools] " .. tostring(err))
			end
		end, 500)
	end
end

function HelperTools.onShow()
	HelperTools.refreshLanguage(ctx and ctx.getLanguage and ctx.getLanguage() or toolsUiLanguage)
	refreshWidgetCache()
	startAntiIdleOutfitRotation()
	startChangeGoldIconRotation()
	startEatFoodIconRotation()
	bindAutoTrainingSlot()
	bindAutoAmmoSlot()

	if HelperConditions and HelperConditions.onShow then
		HelperConditions.onShow()
	end
end

function HelperTools.onHide()
	stopAntiIdleOutfitRotation()
	stopChangeGoldIconRotation()
	stopEatFoodIconRotation()
	clearWidgetCache()

	if HelperConditions and HelperConditions.onHide then
		HelperConditions.onHide()
	end
end

function HelperTools.terminate()
	stopAutoAmmoBurst()
	stopAntiIdleOutfitRotation()
	stopChangeGoldIconRotation()
	stopEatFoodIconRotation()
	closeToolsItemAssignInternal()

	if toolsTickEvent then
		removeEvent(toolsTickEvent)

		toolsTickEvent = nil
	end

	if positionConnected then
		disconnect(Creature, {
			onPositionChange = onLocalPosChange
		})

		positionConnected = false
	end

	removeActivityHooks()
	clearWidgetCache()
	invalidateExerciseDummyCache()

	cachedAmmoAssignList = nil
	toolsUiLanguage = "en"
end

function HelperTools.onChangeGoldChange(_, _)
	if ctx and ctx.saveConfig then
		ctx.saveConfig()
	end
end

function HelperTools.onEatFoodChange(_, _)
	if ctx and ctx.saveConfig then
		ctx.saveConfig()
	end
end

function HelperTools.onAutoTrainingChange(_, on)
	if on and not getTrainingItemId() then
		modules.game_textmessage.displayFailureMessage(toolsText("selectExerciseWeaponFirst"))

		local check = ctx and ctx.getWidget("toolsAutoTrainingCheckBox")

		if check then
			check:setChecked(false)
		end

		autoTrainingEnabled = false

		return
	end

	autoTrainingEnabled = on

	if on then
		addEvent(function()
			runAutoTraining(true)
		end)
	end

	autoSave()
end

function HelperTools.onAutoAmmoChange(_, on)
	if on and not getAmmoItemId() then
		modules.game_textmessage.displayFailureMessage(toolsText("selectAmmoFirst"))

		local check = ctx and ctx.getWidget("toolsAutoAmmoCheckBox")

		if check then
			check:setChecked(false)
		end

		autoAmmoEnabled = false

		return
	end

	autoAmmoEnabled = on

	if not on then
		stopAutoAmmoBurst()
	end

	if on then
		addEvent(function()
			runAutoAmmo(true)
		end)
	end

	autoSave()
end

function HelperTools.onAutoAmmoTargetChange()
	if not ctx then
		return
	end

	local targetCombo = ctx.getWidget("toolsAutoAmmoTargetCombo")
	local current = targetCombo and targetCombo:getCurrentOption() or nil
	local value = type(current) == "table" and current.text or current

	autoAmmoTargetCount = normalizeAutoAmmoCount(value, AUTO_AMMO_DEFAULT_TARGET_COUNT)

	if targetCombo then
		targetCombo:setCurrentOption(tostring(autoAmmoTargetCount), true)
	end

	autoSave()
end

function HelperTools.onAutoSSAChange(_, on)
	autoSSAEnabled = on == true
	lastAutoEquipMs = 0
	autoSave()
end

function HelperTools.onAutoMightRingChange(_, on)
	autoMightRingEnabled = on == true
	lastAutoEquipMs = 0
	autoSave()
end

function HelperTools.isToolsItemAssignActive()
	return toolsItemAssignWindow and not toolsItemAssignWindow:isDestroyed()
end

function HelperTools.closeToolsItemAssignWindow()
	closeToolsItemAssignInternal()
end

function HelperTools.toolsItemAssignOk()
	if not HelperTools.isToolsItemAssignActive() or not toolsItemAssignPanel or not toolsItemAssignTargetSlot then
		return
	end

	local focused = toolsItemAssignPanel:getFocusedChild()

	if not focused or not focused.assignItemId then
		return
	end

	if toolsItemAssignKind == "ammo" then
		assignItemToAmmoSlot(toolsItemAssignTargetSlot, focused.assignItemId)
	else
		assignItemToTrainingSlot(toolsItemAssignTargetSlot, focused.assignItemId)
	end

	closeToolsItemAssignInternal()
end

function HelperTools.filterToolsItemAssignEntries(text)
	if not toolsItemAssignPanel or not HelperTools.isToolsItemAssignActive() then
		return
	end

	text = text or ""

	local textActive = #text > 0
	local textLower = textActive and text:lower() or ""

	for _, row in ipairs(toolsItemAssignPanel:getChildren()) do
		local visible = true

		if textActive then
			visible = row.nameLower and row.nameLower:find(textLower, 1, true) ~= nil or false
		end

		row:setVisible(visible)
	end

	focusFirstVisibleToolsItemAssignRow()
end

function HelperTools.clearToolsItemAssignFilter()
	if not HelperTools.isToolsItemAssignActive() then
		return
	end

	local edit = toolsItemAssignWindow:recursiveGetChildById("filterTextEdit")

	if edit then
		edit:setText("")
		HelperTools.filterToolsItemAssignEntries("")
		edit:focus()
	end
end

function HelperTools.collectConfig(config)
	config.tools = config.tools or {}

	local idleCheck = ctx.getWidget("toolsAntiIdleCheckBox")
	local reconnectCheck = ctx.getWidget("toolsReconnectCheckBox")
	local changeGoldCheck = ctx.getWidget("toolsChangeGoldCheckBox")
	local eatFoodCheck = ctx.getWidget("toolsEatFoodCheckBox")

	config.tools.antiIdle = idleCheck and idleCheck:isChecked() or false
	config.tools.reconnect = reconnectCheck and reconnectCheck:isChecked() or false
	config.tools.changeGold = changeGoldCheck and changeGoldCheck:isChecked() or false
	config.tools.eatFood = eatFoodCheck and eatFoodCheck:isChecked() or false
	config.tools.autoTraining = autoTrainingEnabled
	config.tools.autoAmmo = autoAmmoEnabled
	config.tools.autoAmmoMinCount = nil
	config.tools.autoAmmoTargetCount = autoAmmoTargetCount
	config.tools.autoSSA = autoSSAEnabled
	config.tools.autoMightRing = autoMightRingEnabled

	local itemId = getTrainingItemId()

	if itemId and itemId > 0 then
		config.tools.autoTrainingSlot = {
			itemId = itemId
		}
	else
		config.tools.autoTrainingSlot = nil
	end

	local ammoItemId = getAmmoItemId()

	if ammoItemId then
		config.tools.autoAmmoSlot = {
			itemId = ammoItemId
		}
	else
		config.tools.autoAmmoSlot = nil
	end
end

function HelperTools.loadFromConfig(config)
	local data = config.tools or {}
	local idleCheck = ctx.getWidget("toolsAntiIdleCheckBox")
	local reconnectCheck = ctx.getWidget("toolsReconnectCheckBox")
	local changeGoldCheck = ctx.getWidget("toolsChangeGoldCheckBox")
	local eatFoodCheck = ctx.getWidget("toolsEatFoodCheckBox")
	local autoTrainingCheck = ctx.getWidget("toolsAutoTrainingCheckBox")
	local autoAmmoCheck = ctx.getWidget("toolsAutoAmmoCheckBox")
	local autoSSACheck = ctx.getWidget("toolsAutoSSACheckBox")
	local autoMightRingCheck = ctx.getWidget("toolsAutoMightRingCheckBox")

	if idleCheck then
		idleCheck:setChecked(data.antiIdle == true)
	end

	if reconnectCheck then
		if data.reconnect ~= nil then
			reconnectCheck:setChecked(data.reconnect == true)
			applyReconnectFlag()
		else
			syncReconnectFromSettings()
		end
	end

	if changeGoldCheck then
		changeGoldCheck:setChecked(data.changeGold == true)
	end

	if eatFoodCheck then
		eatFoodCheck:setChecked(data.eatFood == true)
	end

	if data.autoTrainingSlot and data.autoTrainingSlot.itemId and data.autoTrainingSlot.itemId > 0 then
		setConfiguredTrainingItemId(data.autoTrainingSlot.itemId)
	else
		setConfiguredTrainingItemId(nil)
	end

	bindAutoTrainingSlot()
	updateTrainingSlotVisual(configuredTrainingItemId)

	autoTrainingEnabled = data.autoTraining == true

	if autoTrainingCheck then
		autoTrainingCheck:setChecked(autoTrainingEnabled)
	end

	local ammoItemId = data.autoAmmoSlot and tonumber(data.autoAmmoSlot.itemId) or nil

	setConfiguredAmmoItemId(ammoItemId)

	autoAmmoTargetCount = normalizeAutoAmmoCount(data.autoAmmoTargetCount, AUTO_AMMO_DEFAULT_TARGET_COUNT)

	bindAutoAmmoSlot()
	updateAmmoSlotVisual(configuredAmmoItemId)

	autoAmmoEnabled = data.autoAmmo == true and getAmmoItemId() ~= nil

	if autoAmmoCheck then
		autoAmmoCheck:setChecked(autoAmmoEnabled)
	end

	lastAutoAmmoMs = 0
	autoSSAEnabled = data.autoSSA == true
	autoMightRingEnabled = data.autoMightRing == true

	if autoSSACheck then
		autoSSACheck:setChecked(autoSSAEnabled)
	end

	if autoMightRingCheck then
		autoMightRingCheck:setChecked(autoMightRingEnabled)
	end

	lastAutoEquipMs = 0
end

function HelperTools:onReconnectChange(on)
	g_settings.set("autoReconnect", on)

	if ctx and ctx.saveConfig and (not ctx.isLoadingConfig or not ctx.isLoadingConfig()) then
		ctx.saveConfig()
	end
end
