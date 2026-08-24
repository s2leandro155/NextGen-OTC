-- chunkname: @/game_helper/game_helper.lua

helperWindow = nil
helperButton = nil
currentTab = nil

local helperConfig = {}
local modulesByTab = {}
local helperLanguage = "en"
local helperUiLanguageCaptured = false
local HELPER_PT_TRANSLATIONS = {
	Condition = "Condicao",
	Name = "Nome",
	["Combo priority"] = "Prioridade de combo",
	["Clear Action"] = "Limpar Acao",
	Close = "Fechar",
	["Change Gold"] = "Trocar Ouro",
	["Auto Training"] = "Treino Automatico",
	["Auto Invite"] = "Convite Automatico",
	["Auto Ammo"] = "Municao Automatica",
	["Auto Accept"] = "Aceite Automatico",
	["Assign Spell"] = "Selecionar Magia",
	["Assign Exercise Weapon"] = "Selecionar Arma de Exercicio",
	["Assign Ammunition"] = "Selecionar Municao",
	["Anti Idle"] = "Anti Inatividade",
	["Add Selected"] = "Adicionar Selecionado",
	["Add Spell"] = "Adicionar Magia",
	["Add Player"] = "Adicionar Jogador",
	["Add Potion"] = "Adicionar Pocao",
	Add = "Adicionar",
	Action = "Acao",
	Cancel = "Cancelar",
	["Type to search"] = "Digite para pesquisar",
	["Only show learnt spells"] = "Mostrar somente magias aprendidas",
	["Target + Shooter Hotkey"] = "Hotkey do Target + Shooter",
	["Visible Players"] = "Jogadores Visiveis",
	["When HP"] = "Se HP",
	Value = "Valor",
	["Source:"] = "Origem:",
	["Spell Healing"] = "Cura por Magia",
	["Shooter Settings"] = "Configuracoes do Shooter",
	["Shooter List"] = "Lista do Shooter",
	["Send invite to (max 4 players):"] = "Enviar convite para (max. 4 jogadores):",
	["Select an exercise weapon first."] = "Selecione uma arma de exercicio primeiro.",
	Save = "Salvar",
	Rename = "Renomear",
	Remove = "Remover",
	["Refresh Map"] = "Atualizar Mapa",
	Reconnect = "Reconectar",
	["Mana Training"] = "Treino de Mana",
	["PZ Cast"] = "Conjurar em PZ",
	["Limit:"] = "Limite:",
	["Priority: "] = "Prior.: ",
	Load = "Carregar",
	["Priority:"] = "Prior.:",
	["Leader (Accept Party):"] = "Lider (aceitar):",
	["Preset:"] = "Perfil:",
	Haste = "Acelerar",
	["Presets:"] = "Perfis:",
	["Heal Friend"] = "Cura de Aliado",
	["Potion Healing"] = "Cura por Pocao",
	["General Settings"] = "Configuracoes Gerais",
	["Posture:"] = "Postura:",
	Enabled = "Ativado",
	["Add players using the button below."] = "Adicione jogadores usando o botao abaixo.",
	["Enable Shooter"] = "Ativar Shooter",
	["Higher priority"] = "Maior prioridade",
	["Enable Helper"] = "Ativar Helper",
	["No exercise dummy found."] = "Nenhum boneco de treino encontrado.",
	["Enable Healing"] = "Ativar Cura",
	["No party players."] = "Nenhum jogador no grupo.",
	["Enable Heal Friend"] = "Cura em Aliado",
	Players = "Jogadores",
	["Enable Auto Invite"] = "Ativar Convite Automatico",
	["Player name"] = "Nome do jogador",
	["Enable Auto Accept"] = "Ativar Aceite Automatico",
	["Player List"] = "Lista de Jogadores",
	["Edit Spell"] = "Editar Magia",
	Player = "Jogador",
	Edit = "Editar",
	["Specific Players"] = "Jogadores Especificos",
	["Eat Food"] = "Comer",
	["Configured Players"] = "Jogadores Configurados",
	["Distance:"] = "Dist.:",
	["Party players: 0"] = "Jogadores no grupo: 0",
	Disabled = "Desativado",
	["Party Players"] = "Jogadores do Grupo",
	Delete = "Excluir",
	["Open Helper"] = "Abrir Helper",
	Creature = "Criatura",
	New = "Novo"
}
local HELPER_PT_TOOLTIP_TRANSLATIONS = {
	["PZ Auto:<br><li>Enabled: pauses Target inside a protection zone and restores it after leaving.</li><li>Disabled: turns Target off in a protection zone. It stays off after leaving and cannot be enabled while you are inside.</li>"] = "PZ Auto:<br><li>Ativado: pausa o Target dentro de uma protection zone e restaura ao sair.</li><li>Desativado: desliga o Target dentro de uma protection zone. Ele permanece desligado ao sair e nao pode ser ativado enquanto voce estiver nela.</li>",
	["Auto-Switch Hotkey Preset:<br><li>On login, selects the client hotkey preset and Helper preset whose name exactly matches the character name.</li><li>All Helper tabs, profiles and hotkeys are always stored separately for each character.</li><li>If there is no matching preset, each system keeps its current preset.</li>"] = "Troca Automatica de Preset de Hotkeys:<br><li>Ao entrar, seleciona o preset de hotkeys do cliente e o perfil do Helper cujo nome corresponde exatamente ao nome do personagem.</li><li>Todas as abas, perfis e hotkeys do Helper sao sempre salvos separadamente para cada personagem.</li><li>Se nao houver um preset correspondente, cada sistema mantem seu preset atual.</li>",
	["Combo priority: when enabled, casts your enabled spells as a rotating combo (round-robin), reading the list from top to bottom, instead of always repeating the highest-priority ready spell."] = "Prioridade de combo: quando ativada, conjura as magias habilitadas em rotacao, lendo a lista de cima para baixo, em vez de repetir sempre a magia pronta de maior prioridade.",
	["Metrics used in the When row:<br><li>HP%: Health Points percentage.</li><li>MP%: Mana Points percentage.</li><br>Condition logic:<br><li>and: both conditions must be true.</li><li>or: at least one condition must be true.</li><br>Condition operators used in the Is row:<br><li>&lt; : value is below the threshold.</li><li>&lt;= : value is at or below the threshold.</li><li>&gt; : value is above the threshold.</li><li>&gt;= : value is at or above the threshold.</li>"] = "Metricas usadas na linha Quando:<br><li>HP%: percentual de pontos de vida.</li><li>MP%: percentual de pontos de mana.</li><br>Logica das condicoes:<br><li>e: ambas as condicoes devem ser verdadeiras.</li><li>ou: pelo menos uma condicao deve ser verdadeira.</li><br>Operadores usados na linha E:<br><li>&lt; : valor abaixo do limite.</li><li>&lt;= : valor igual ou abaixo do limite.</li><li>&gt; : valor acima do limite.</li><li>&gt;= : valor igual ou acima do limite.</li>",
	["The order of entries in the list determines the shooter priority. Entries at the top are checked first.<br><br><li>Drag an entry up or down to reorder it.</li><li>Right-click an entry to open a menu and change its order in the list.</li><li>Uncheck an entry to temporarily disable that spell or rune without removing it.</li>"] = "A ordem das entradas define a prioridade do Shooter. As entradas no topo sao verificadas primeiro.<br><br><li>Arraste uma entrada para cima ou para baixo para reordena-la.</li><li>Clique com o botao direito para abrir o menu e alterar sua ordem.</li><li>Desmarque uma entrada para desativar temporariamente a magia ou runa sem remove-la.</li>",
	["Shooter entry conditions:<br><li>HP%: target health percentage required to use this entry.</li><li>Creatures: minimum number of creatures needed for area spells or runes, unless force cast is enabled.</li><li>Use to: uses the selected spell or rune on the target, yourself, or the best position for area hits.</li><li>Harmony: minimum harmony required for spells that use harmony.</li>"] = "Condicoes da entrada do Shooter:<br><li>HP%: percentual de vida do alvo necessario para usar esta entrada.</li><li>Criaturas: quantidade minima de criaturas para magias ou runas de area, exceto quando o uso forcado estiver ativo.</li><li>Usar em: usa a magia ou runa no alvo, em voce ou na melhor posicao para ataques em area.</li><li>Harmonia: harmonia minima exigida pelas magias que usam esse recurso.</li>",
	["Heal Friend:<br><li>Only confirmed party members are added automatically.</li><li>Players at the top have higher healing priority than players below. Drag a player up or down to reorder.</li><li>Only party members visible on the map can be healed.</li>"] = "Cura de Aliado:<br><li>Somente membros confirmados do grupo sao adicionados automaticamente.</li><li>Jogadores no topo possuem mais prioridade de cura que os de baixo. Arraste um jogador para cima ou para baixo para reordenar.</li><li>Somente membros do grupo visiveis no mapa podem ser curados.</li>",
	["Auto-turn: before casting this directional spell, turn toward the direction that hits the most creatures. If unchecked, the spell is simply forced out in your current facing."] = "Giro automatico: antes de conjurar esta magia direcional, vira para a direcao que atinge mais criaturas. Se desmarcado, a magia e lancada na direcao atual.",
	["Action: Restore Balance\nFormula: exura tio sio\nCooldown: 2s\nMana: 120"] = "Acao: Restaurar Equilibrio\nFormula: exura tio sio\nRecarga: 2s\nMana: 120",
	["Action: Cast Nature's Embrace\nFormula: exura gran sio\nCooldown: 1min\nMana: 400"] = "Acao: Conjurar Abraco da Natureza\nFormula: exura gran sio\nRecarga: 1min\nMana: 400",
	["Action: Cast Heal Friend\nFormula: exura sio\nCooldown: 1s\nMana: 120"] = "Acao: Curar Aliado\nFormula: exura sio\nRecarga: 1s\nMana: 120",
	["Maximum number of eligible players (1-50)."] = "Numero maximo de jogadores elegiveis (1-50).",
	["Healing actions are checked by their configured HP/MP percent, not by their visual position."] = "As acoes de cura sao verificadas pelo percentual de HP/MP configurado, nao pela posicao visual.",
	["Auto Save:<br><li>Saves every change automatically in the active profile.</li><li>When disabled, changes remain temporary until you use Save.</li>"] = "Salvar Auto:<br><li>Salva automaticamente cada alteracao no perfil ativo.</li><li>Quando desativado, as alteracoes ficam temporarias ate voce usar Salvar.</li>",
	["Target + Shooter hotkey:<br><li>Assigns an independent key that toggles Target and Shooter together.</li><li>Does not change the individual hotkeys in either tab.</li><li>The key must be available; occupied keys cannot be overwritten.</li>"] = "Hotkey do Target + Shooter:<br><li>Define uma tecla independente que alterna Target e Shooter juntos.</li><li>Nao altera as hotkeys individuais de nenhuma das abas.</li><li>A tecla precisa estar livre; hotkeys ocupadas nao podem ser substituidas.</li>",
	["Check this box to activate the Helper."] = "Marque esta caixa para ativar o Helper.",
	["Auto Accept:<br><li>Uses only the leader field above.</li><li>When enabled, the helper accepts party invites from the configured leader.</li><li>The leader must be nearby or visible when the invite is detected.</li>"] = "Aceite Automatico:<br><li>Usa apenas o campo de lider acima.</li><li>Quando ativado, aceita convites de grupo enviados pelo lider configurado.</li><li>O lider deve estar proximo ou visivel quando o convite for detectado.</li>",
	["Auto Invite:<br><li>Uses only the invite list above.</li><li>When enabled, the helper invites configured players when they are nearby and not already in party.</li><li>Fill up to four player names.</li>"] = "Convite Automatico:<br><li>Usa apenas a lista de convites acima.</li><li>Quando ativado, convida os jogadores configurados que estiverem proximos e ainda nao estiverem no grupo.</li><li>Preencha ate quatro nomes de jogadores.</li>",
	["Shooter settings:<br><li>Presets save independent shooter lists.</li><li>Use the pencil beside a preset to assign a hotkey that selects it.</li><li>PZ Auto enabled: pauses Shooter inside a protection zone and restores it after leaving.</li><li>PZ Auto disabled: turns Shooter off in a protection zone. It stays off after leaving and cannot be enabled while you are inside.</li>"] = "Configuracoes do Shooter:<br><li>Os perfis salvam listas independentes do Shooter.</li><li>Use o lapis ao lado de um perfil para definir uma hotkey que o seleciona.</li><li>PZ Auto ativado: pausa o Shooter dentro de uma protection zone e restaura ao sair.</li><li>PZ Auto desativado: desliga o Shooter dentro de uma protection zone. Ele permanece desligado ao sair e nao pode ser ativado enquanto voce estiver nela.</li>",
	["PZ Auto:<br><li>Enabled: pauses Shooter inside a protection zone and restores it after leaving.</li><li>Disabled: turns Shooter off in a protection zone. It stays off after leaving and cannot be enabled while you are inside.</li>"] = "PZ Auto:<br><li>Ativado: pausa o Shooter dentro de uma protection zone e restaura ao sair.</li><li>Desativado: desliga o Shooter dentro de uma protection zone. Ele permanece desligado ao sair e nao pode ser ativado enquanto voce estiver nela.</li>"
}
local HELPER_LANGUAGE_SKIPPED_PANELS = {
	targetPanel = true,
	MainMenuLeft = true
}
local helperStatsWindow, helperTickEvent
local helperTickIntervalMs = 50
local combatTickEvent
local combatTickIntervalMs = 50
local boundTargetHotkeyWindow
local targetHotkeyPendingCombo = ""
local combatCreatureAppearHandler, combatCreatureDisappearHandler, combatSpellCooldownHandler, combatSpellGroupCooldownHandler, combatMultiUseCooldownHandler, combatAttackingCreatureChangeHandler, combatFollowingCreatureChangeHandler, combatPlayerStatesChangeHandler, boundSharedCombatHotkey, bindCombatHotkeys, unbindCombatHotkeys, showHelperMessage
local LEGACY_HELPER_JSON_FILE = "/settings/game_helper_data.json"
local HELPER_CHARACTER_DATA_ROOT = "/characterdata"
local HELPER_JSON_FILE_NAME = "game_helper_data.json"
local HELPER_JSON_VERSION = 1
local DEFAULT_HELPER_PROFILE_NAME = "Default"
local AUTO_SWITCH_HOTKEY_PRESET_SETTING = "autoSwitchPreset"
local activeHelperJSONFile, activeHelperCharacterId, activeHelperCharacterName
local helperSavedOnLogout = false
local autoSaveEvent
local loadingConfig = false
local combatHotkeyBatchActive = false
local combatHotkeySavePending = false
local combatHotkeyStatsPending = false
local helperHotkeyWindow
local helperHotkeyPendingCombo = ""
local boundHelperHotkey, shooterHotkeyWindow
local shooterHotkeyPendingCombo = ""
local shooterPresetHotkeyProfileName, boundShooterHotkey

local function helperLog(level, message)
	if not g_logger then
		return
	end

	local fn = g_logger[level] or g_logger.info

	fn("[game_helper] " .. message)
end

local function cancelAutoSave()
	if autoSaveEvent then
		removeEvent(autoSaveEvent)

		autoSaveEvent = nil
	end
end

local function ensureHelperSettingsDir()
	pcall(function()
		if not g_resources.directoryExists("/settings") then
			g_resources.makeDir("/settings")
		end
	end)
end

local function ensureHelperCharacterDir(characterId)
	if not characterId or characterId == "" then
		return false
	end

	local ok, result = pcall(function()
		if not g_resources.directoryExists(HELPER_CHARACTER_DATA_ROOT) then
			g_resources.makeDir(HELPER_CHARACTER_DATA_ROOT)
		end

		local directory = HELPER_CHARACTER_DATA_ROOT .. "/" .. characterId

		if not g_resources.directoryExists(directory) then
			g_resources.makeDir(directory)
		end

		return g_resources.directoryExists(directory)
	end)

	if not ok or not result then
		helperLog("error", "Failed to create character Helper directory for id " .. tostring(characterId) .. ". Details: " .. tostring(result))

		return false
	end

	return true
end

local function copyConfig(config)
	if type(config) ~= "table" then
		return {}
	end

	local ok, copied = pcall(function()
		return json.decode(json.encode(config))
	end)

	if ok and type(copied) == "table" then
		return copied
	end

	return config
end

local function normalizeHelperLanguage(language)
	return language == "pt" and "pt" or "en"
end

local function getDefaultProfileName()
	if HelperConfigTab and HelperConfigTab.DEFAULT_PROFILE_NAME then
		return HelperConfigTab.DEFAULT_PROFILE_NAME
	end

	return DEFAULT_HELPER_PROFILE_NAME
end

local function configTableHasContent(config)
	return type(config) == "table" and next(config) ~= nil
end

local function ensureDefaultProfile(data)
	local defaultName = getDefaultProfileName()

	data.profiles = data.profiles or {}

	if type(data.profiles[defaultName]) == "table" then
		return
	end

	if configTableHasContent(data.current) then
		data.profiles[defaultName] = copyConfig(data.current)
	else
		data.profiles[defaultName] = {}
	end
end

local function normalizeHelperData(raw)
	local data = type(raw) == "table" and raw or {}

	if type(data.profiles) ~= "table" then
		data.profiles = {}
	end

	if type(data.current) ~= "table" then
		data.current = {}
	end

	if data.activeProfile ~= nil and type(data.activeProfile) ~= "string" then
		data.activeProfile = nil
	end

	ensureDefaultProfile(data)

	if data.autoSaveEnabled == nil then
		data.autoSaveEnabled = true
	end

	data.language = normalizeHelperLanguage(data.language)
	data.version = HELPER_JSON_VERSION

	return data
end

local function readHelperJSONFile(filePath)
	if not filePath or not g_resources.fileExists(filePath) then
		return nil
	end

	local ok, content = pcall(g_resources.readFileContents, filePath)

	if not ok or not content or content == "" then
		helperLog("error", "Failed to read Helper JSON: " .. tostring(filePath))

		return nil
	end

	local okDecode, data = pcall(json.decode, content)

	if not okDecode or type(data) ~= "table" then
		helperLog("error", "Invalid Helper JSON at " .. tostring(filePath) .. ". Details: " .. tostring(data))

		return nil
	end

	return normalizeHelperData(data)
end

local function writeHelperJSONFile(filePath, data)
	if not filePath then
		helperLog("error", "No active character Helper JSON file is available.")

		return false
	end

	data = normalizeHelperData(data)

	local ok, content = pcall(json.encode, data, 2)

	if not ok or not content then
		helperLog("error", "Failed to encode helper JSON: " .. tostring(content))

		return false
	end

	local okWrite, writeErr = pcall(g_resources.writeFileContents, filePath, content)

	if not okWrite or writeErr == false then
		helperLog("error", "Failed to write Helper JSON at " .. tostring(filePath) .. ": " .. tostring(writeErr))

		return false
	end

	return true
end

local function getActiveHelperJSONFile()
	if activeHelperJSONFile then
		return activeHelperJSONFile
	end

	if g_game and g_game.isOnline and g_game.isOnline() then
		return nil
	end

	return LEGACY_HELPER_JSON_FILE
end

local function readHelperJSON()
	local filePath = getActiveHelperJSONFile()

	if filePath == LEGACY_HELPER_JSON_FILE then
		ensureHelperSettingsDir()
	end

	return readHelperJSONFile(filePath) or normalizeHelperData({})
end

local function writeHelperJSON(data)
	local filePath = getActiveHelperJSONFile()

	if filePath == LEGACY_HELPER_JSON_FILE then
		ensureHelperSettingsDir()
	elseif activeHelperCharacterId and not ensureHelperCharacterDir(activeHelperCharacterId) then
		return false
	end

	return writeHelperJSONFile(filePath, data)
end

local function activateHelperCharacterStorage()
	local player = g_game.getLocalPlayer()

	if not player then
		activeHelperJSONFile = nil
		activeHelperCharacterId = nil
		activeHelperCharacterName = nil

		return false
	end

	local characterId = tostring(player:getId() or "")

	if characterId == "" or characterId == "0" then
		helperLog("error", "Cannot activate character Helper storage without a valid player id.")

		activeHelperJSONFile = nil
		activeHelperCharacterId = nil
		activeHelperCharacterName = nil

		return false
	end

	local characterName = g_game.getCharacterName() or player:getName() or ""
	local filePath = HELPER_CHARACTER_DATA_ROOT .. "/" .. characterId .. "/" .. HELPER_JSON_FILE_NAME

	activeHelperJSONFile = nil
	activeHelperCharacterId = nil
	activeHelperCharacterName = nil

	if not ensureHelperCharacterDir(characterId) then
		return false
	end

	if not g_resources.fileExists(filePath) then
		ensureHelperSettingsDir()

		local legacyData = readHelperJSONFile(LEGACY_HELPER_JSON_FILE) or normalizeHelperData({})

		if not writeHelperJSONFile(filePath, copyConfig(legacyData)) then
			helperLog("error", "Failed to migrate legacy Helper data for character id " .. characterId .. ".")

			return false
		end

		helperLog("info", "Migrated legacy Helper data to " .. filePath .. ".")
	end

	activeHelperJSONFile = filePath
	activeHelperCharacterId = characterId
	activeHelperCharacterName = tostring(characterName)
	helperSavedOnLogout = false

	helperLog("info", "Active character Helper storage: " .. filePath .. " (" .. activeHelperCharacterName .. ").")

	return true
end

local TABS = {
	healing = {
		panelId = "healingPanel",
		buttonId = "healing",
		module = "healer"
	},
	healFriend = {
		panelId = "healFriendPanel",
		buttonId = "healFriend",
		module = "healFriend"
	},
	target = {
		panelId = "targetPanel",
		buttonId = "targetButton",
		module = "target"
	},
	shooter = {
		panelId = "shooterPanel",
		buttonId = "shooterButton",
		module = "shooter"
	},
	party = {
		panelId = "partyPanel",
		buttonId = "partyButton",
		module = "autoparty"
	},
	tools = {
		panelId = "toolsPanel",
		buttonId = "toolsButton",
		module = "tools"
	},
	configs = {
		panelId = "configsPanel",
		buttonId = "configsButton",
		module = "config"
	},
	cavebot = {
		panelId = "cavebotPanel",
		buttonId = "cavebotButton",
		module = "cavebot"
	}
}
local HELPER_STATS_ITEMS = {
	{
		label = "Healing",
		id = "healing",
		rowId = "helperStatsHealingRow",
		widgetId = "enableHealingCheckBox"
	},
	{
		label = "Heal Friend",
		id = "healFriend",
		rowId = "helperStatsHealFriendRow",
		widgetId = "enableHealFriendCheckBox"
	},
	{
		label = "Target Helper",
		id = "target",
		rowId = "helperStatsTargetRow",
		widgetId = "enableTargetCheckBox"
	},
	{
		label = "Shooter Helper",
		id = "shooter",
		rowId = "helperStatsShooterRow",
		widgetId = "enableShooterCheckBox"
	},
	{
		label = "Auto Invite",
		id = "autoInvite",
		rowId = "helperStatsAutoInviteRow",
		widgetId = "toolsAutoPartyCheckBox"
	},
	{
		label = "Auto Accept",
		id = "autoAccept",
		rowId = "helperStatsAutoAcceptRow",
		widgetId = "toolsAutoPartyAcceptCheckBox"
	},
	{
		label = "Auto Haste",
		id = "autoHaste",
		rowId = "helperStatsAutoHasteRow",
		widgetId = "toolsAutoHasteCheckBox"
	},
	{
		label = "Auto Training",
		id = "autoTraining",
		rowId = "helperStatsAutoTrainingRow",
		widgetId = "toolsAutoTrainingCheckBox"
	},
	{
		label = "Anti Idle",
		id = "antiIdle",
		rowId = "helperStatsAntiIdleRow",
		widgetId = "toolsAntiIdleCheckBox"
	},
	{
		label = "Mana Training",
		id = "manaTraining",
		rowId = "helperStatsManaTrainingRow",
		widgetId = "toolsManaTrainingCheckBox"
	},
	{
		label = "Change Gold",
		id = "changeGold",
		rowId = "helperStatsChangeGoldRow",
		widgetId = "toolsChangeGoldCheckBox"
	},
	{
		label = "Eat Food",
		id = "eatFood",
		rowId = "helperStatsEatFoodRow",
		widgetId = "toolsEatFoodCheckBox"
	},
	{
		label = "Reconnect",
		id = "reconnect",
		rowId = "helperStatsReconnectRow",
		widgetId = "toolsReconnectCheckBox"
	}
}

local function syncButton()
	if helperButton and not helperButton:isDestroyed() then
		local statsOpen = helperStatsWindow and not helperStatsWindow:isDestroyed() and not helperStatsWindow:isHidden()

		helperButton:setOn(statsOpen == true)
	end
end

local function getWidget(id)
	return helperWindow and helperWindow:recursiveGetChildById(id)
end

local function setCharacterCardText(id, text, tooltip)
	local widget = getWidget(id)

	if not widget then
		return
	end

	if widget.setText then
		widget:setText(text or "")
	end

	if widget.setTooltip and tooltip then
		widget:setTooltip(tooltip)
	end
end

local function setCharacterCardName(fullName)
	local label = getWidget("helperCharacterName")

	if not label then
		return
	end

	fullName = tostring(fullName or "")

	label:setTooltip(fullName)
	label:setText(fullName)

	local budget = label:getWidth()

	if not budget or budget < 40 then
		budget = 98
	end

	budget = math.max(1, budget - 2)

	if budget >= label:getTextSize().width then
		return
	end

	local dots = "..."
	local low, high, best = 0, #fullName, dots

	while low <= high do
		local middle = math.floor((low + high) / 2)
		local candidate = fullName:sub(1, middle) .. dots

		label:setText(candidate)

		if budget >= label:getTextSize().width then
			best = candidate
			low = middle + 1
		else
			high = middle - 1
		end
	end

	label:setText(best)
end

local function isCurrentAccountPremium(player)
	local account = G and G.characterAccount or nil

	if account and account.subStatus ~= nil and SubscriptionStatus then
		if account.subStatus == SubscriptionStatus.Premium then
			return true
		end

		if account.subStatus == SubscriptionStatus.Free then
			return false
		end
	end

	return player and player:isPremium() == true or false
end

local function refreshHelperCharacterCard()
	if not helperWindow or helperWindow:isDestroyed() then
		return
	end

	local player = g_game.isOnline() and g_game.getLocalPlayer() or nil
	local isPortuguese = helperLanguage == "pt"
	local outfitWidget = getWidget("helperCharacterOutfit")

	if outfitWidget then
		outfitWidget:setVisible(player ~= nil)

		if player then
			outfitWidget:setOutfit(player:getOutfit())

			local creature = outfitWidget:getCreature()

			if creature and creature.setDirection then
				creature:setDirection(South)
			end
		end
	end

	local playerName = player and player:getName() or isPortuguese and "Desconectado" or "Offline"

	setCharacterCardName(playerName)

	local levelText = isPortuguese and "Nivel: -" or "Level: -"

	if player then
		levelText = string.format(isPortuguese and "Nivel: %d" or "Level: %d", player:getLevel())
	end

	setCharacterCardText("helperCharacterLevel", levelText)
	setCharacterCardText("helperAccountCaption", isPortuguese and "Status da Conta:" or "Account Status:")

	local statusText = isPortuguese and "Desconectado" or "Offline"
	local statusIcon = "/images/game/entergame/nopremium"

	if player then
		local isPremiumAccount = isCurrentAccountPremium(player)

		if isPremiumAccount then
			statusText = isPortuguese and "Conta Premium" or "Premium Account"
			statusIcon = "/images/game/entergame/premium"
		else
			statusText = isPortuguese and "Conta Gratuita" or "Free Account"
		end
	end

	setCharacterCardText("helperAccountStatus", statusText, statusText)

	local accountIcon = getWidget("helperAccountStatusIcon")

	if accountIcon then
		accountIcon:setImageSource(statusIcon)
		accountIcon:setTooltip(statusText)
	end

	local languageButton = getWidget("helperLanguageButton")

	if languageButton then
		languageButton:setText(isPortuguese and "Portugues" or "English")
		languageButton:setTooltip(isPortuguese and "Mudar idioma para ingles." or "Switch language to Portuguese.")
	end

	local portugueseFlag = getWidget("helperLanguageFlagPt")

	if portugueseFlag then
		portugueseFlag:setVisible(isPortuguese)
	end

	local englishFlag = getWidget("helperLanguageFlagEn")

	if englishFlag then
		englishFlag:setVisible(not isPortuguese)
	end
end

local function onHelperCharacterChanged()
	refreshHelperCharacterCard()
end

local function translateHelperWidgetTree(target, capture)
	if not target then
		return
	end

	local id = target.getId and target:getId() or nil

	if HELPER_LANGUAGE_SKIPPED_PANELS[id] then
		return
	end

	local className = target.getClassName and target:getClassName() or ""
	local canTranslateText = className ~= "UITextEdit" and className ~= "UIComboBox" and target.getText and target.setText

	if canTranslateText then
		local current = target:getText()

		if capture and current and HELPER_PT_TRANSLATIONS[current] then
			target.helperLanguageSourceText = current
		end

		local source = target.helperLanguageSourceText

		if source then
			local lastApplied = target.helperLanguageAppliedText

			if lastApplied and current ~= lastApplied and current ~= source then
				if HELPER_PT_TRANSLATIONS[current] then
					source = current
					target.helperLanguageSourceText = current
				else
					source = nil
					target.helperLanguageSourceText = nil
					target.helperLanguageAppliedText = nil
				end
			end

			if source then
				local translated = helperLanguage == "pt" and HELPER_PT_TRANSLATIONS[source] or source

				target:setText(translated)

				target.helperLanguageAppliedText = translated
			end
		end
	end

	if target.getTooltip and target.setTooltip then
		local currentTooltip = target:getTooltip()

		if capture and currentTooltip and HELPER_PT_TOOLTIP_TRANSLATIONS[currentTooltip] then
			target.helperLanguageSourceTooltip = currentTooltip
		end

		local sourceTooltip = target.helperLanguageSourceTooltip

		if sourceTooltip then
			local translatedTooltip = helperLanguage == "pt" and HELPER_PT_TOOLTIP_TRANSLATIONS[sourceTooltip] or sourceTooltip

			target:setTooltip(translatedTooltip)
		end
	end

	if target.getChildren then
		for _, child in ipairs(target:getChildren()) do
			translateHelperWidgetTree(child, capture)
		end
	end
end

local function refreshHelperUiLanguage(capture)
	if not helperWindow then
		return
	end

	local shouldCapture = capture == true or not helperUiLanguageCaptured

	translateHelperWidgetTree(helperWindow, shouldCapture)

	helperUiLanguageCaptured = true
end

local function applyHelperLanguage(language)
	helperLanguage = normalizeHelperLanguage(language)

	for name, mod in pairs(modulesByTab) do
		if mod and mod.refreshLanguage then
			local ok, err = pcall(mod.refreshLanguage, helperLanguage)

			if not ok then
				helperLog("warning", "refreshLanguage failed for " .. tostring(name) .. ": " .. tostring(err))
			end
		end
	end

	refreshHelperUiLanguage(false)
	refreshHelperCharacterCard()

	return helperLanguage
end

local function getHelperStatsRow(item)
	if not helperStatsWindow or helperStatsWindow:isDestroyed() then
		return nil
	end

	return helperStatsWindow:recursiveGetChildById(item.rowId)
end

local function refreshHelperStatsWindow()
	if combatHotkeyBatchActive then
		combatHotkeyStatsPending = true

		return
	end

	if not helperStatsWindow or helperStatsWindow:isDestroyed() then
		return
	end

	for _, item in ipairs(HELPER_STATS_ITEMS) do
		local row = getHelperStatsRow(item)
		local icon = row and row:getChildById("statusIcon")
		local status = row and row:getChildById("statusLabel")
		local check = getWidget(item.widgetId)
		local enabled = check and check:isChecked()
		local paused = false

		if item.id == "shooter" and HelperShooter and HelperShooter.isDisabledByFollow and HelperShooter.isDisabledByFollow() then
			paused = true
		end

		if item.id == "target" and HelperTarget and HelperTarget.isDisabledByProtectionZone and HelperTarget.isDisabledByProtectionZone() then
			paused = true
		end

		if item.id == "shooter" and HelperShooter and HelperShooter.isDisabledByProtectionZone and HelperShooter.isDisabledByProtectionZone() then
			paused = true
		end

		if item.id == "autoHaste" and enabled then
			local pzCastCheck = getWidget("toolsAutoHastePzCastCheckBox")
			local player = g_game.getLocalPlayer()
			local inProtectionZone = player and player.isInProtectionZone and player:isInProtectionZone()

			if inProtectionZone and pzCastCheck and not pzCastCheck:isChecked() then
				paused = true
			end
		end

		local displayEnabled = enabled or paused

		if icon then
			if paused then
				icon:setImageSource("/images/icons/icon-paused")
			else
				icon:setImageSource(displayEnabled and "/images/icons/icon-yes" or "/images/icons/icon-no")
			end
		end

		if status then
			status:setText(displayEnabled and tr("Enabled") or tr("Disabled"))

			local enabledColor = "#5ff75f"
			local disabledColor = "#f75f5f"

			if paused then
				enabledColor = "#ff9854"
			end

			status:setColor(displayEnabled and enabledColor or disabledColor)
		end
	end
end

function refreshHelperStats()
	refreshHelperStatsWindow()
end

local function setupHelperStatsWindow()
	local parent = modules.game_interface and modules.game_interface.getRightPanel and modules.game_interface.getRightPanel()

	helperStatsWindow = g_ui.createWidget("HelperStatsWindow", parent or rootWidget)

	if helperStatsWindow.setup then
		helperStatsWindow:setup()
	end

	if helperStatsWindow.setContentMinimumHeight then
		helperStatsWindow:setContentMinimumHeight(80)
	end

	for _, id in ipairs({
		"newWindowButton",
		"toggleFilterButton",
		"contextMenuButton",
		"lockButton"
	}) do
		local widget = helperStatsWindow:recursiveGetChildById(id)

		if widget then
			widget:setVisible(false)
			widget:setOn(false)
		end
	end

	local closeButton = helperStatsWindow:recursiveGetChildById("closeButton")

	if closeButton then
		closeButton:setVisible(true)

		function closeButton.onClick()
			if helperStatsWindow and not helperStatsWindow:isDestroyed() then
				helperStatsWindow:closeAndForgetLayout()
			end

			syncButton()
		end
	end

	for _, item in ipairs(HELPER_STATS_ITEMS) do
		local row = getHelperStatsRow(item)

		if row then
			local title = row:getChildById("titleLabel")

			if title then
				title:setText(tr(item.label))
			end

			row.helperStatsItemId = item.id

			function row.onMousePress(widget, _, mouseButton)
				if mouseButton ~= MouseLeftButton then
					return false
				end

				modules.game_helper.toggleHelperStatsEntry(widget.helperStatsItemId)

				return true
			end
		end
	end

	local openButton = helperStatsWindow:recursiveGetChildById("helperStatsOpenHelperButton")

	if openButton then
		function openButton.onClick()
			modules.game_helper.openHelperFromStats()
		end
	end

	function helperStatsWindow.onVisibilityChange()
		syncButton()
		if modules.game_analysers and modules.game_analysers.onHelperStatsVisibilityChange then
			modules.game_analysers.onHelperStatsVisibilityChange()
		end
	end

	helperStatsWindow:hide()
	refreshHelperStatsWindow()
	syncButton()
end

local function getPlayerVoc()
	local player = g_game.getLocalPlayer()

	if not player then
		return 0
	end

	return translateVocation(player:getVocation())
end

local function getProfileNameForAutoSave()
	if HelperConfigTab and HelperConfigTab.getProfileNameForAutoSave then
		return HelperConfigTab.getProfileNameForAutoSave()
	end

	return nil
end

function isAutoSaveEnabled()
	local check = getWidget("configsAutoSaveCheckBox")

	if check then
		return check:isChecked()
	end

	local data = readHelperJSON()

	return data.autoSaveEnabled ~= false
end

local function applyAutoSavePreferenceToCheckbox(enabled)
	local check = getWidget("configsAutoSaveCheckBox")

	if not check then
		return
	end

	local value = enabled ~= false

	if check:isChecked() ~= value then
		loadingConfig = true

		check:setChecked(value)

		loadingConfig = false
	end
end

local function isAutoSwitchHotkeyPresetEnabled()
	if modules.client_options and modules.client_options.getOption then
		local ok, enabled = pcall(modules.client_options.getOption, AUTO_SWITCH_HOTKEY_PRESET_SETTING)

		if ok and type(enabled) == "boolean" then
			return enabled
		end
	end

	return g_settings and g_settings.getBoolean and g_settings.getBoolean(AUTO_SWITCH_HOTKEY_PRESET_SETTING) or false
end

local function applyAutoSwitchHotkeyPresetToCheckbox(enabled)
	local check = getWidget("configsAutoSwitchHotkeyPresetCheckBox")

	if not check then
		return
	end

	local value = enabled == true

	if check:isChecked() ~= value then
		loadingConfig = true

		check:setChecked(value)

		loadingConfig = false
	end
end

local function setAutoSwitchHotkeyPresetEnabled(enabled)
	local value = enabled == true

	local function saveNativeSettings()
		if not g_settings or not g_settings.save then
			return true
		end

		local ok, err = pcall(g_settings.save)

		if not ok then
			helperLog("error", "Failed to save native auto-switch option: " .. tostring(err))

			return false
		end

		return true
	end

	if modules.client_options and modules.client_options.setOption then
		local ok, err = pcall(modules.client_options.setOption, AUTO_SWITCH_HOTKEY_PRESET_SETTING, value, true)

		if ok and isAutoSwitchHotkeyPresetEnabled() == value then
			return saveNativeSettings()
		end

		if not ok then
			helperLog("warning", "Failed to update native auto-switch option: " .. tostring(err))
		end
	end

	if g_settings and g_settings.set then
		local ok, err = pcall(g_settings.set, AUTO_SWITCH_HOTKEY_PRESET_SETTING, value)

		if ok then
			return saveNativeSettings()
		end

		helperLog("error", "Failed to persist native auto-switch option: " .. tostring(err))
	end

	return false
end

local function collectHelperConfigSnapshot()
	helperConfig.enableHelper = getWidget("checkbox") and getWidget("checkbox"):isChecked() or false
	helperConfig.enableHealing = getWidget("enableHealingCheckBox") and getWidget("enableHealingCheckBox"):isChecked() or false
	helperConfig.enableHealFriend = getWidget("enableHealFriendCheckBox") and getWidget("enableHealFriendCheckBox"):isChecked() or false
	helperConfig.hotkey = helperConfig.hotkey or ""
	helperConfig.shooterHotkey = helperConfig.shooterHotkey or ""
	helperConfig.autoTargetHotkey = helperConfig.autoTargetHotkey or "F11"
	helperConfig.shooterEnableHotkey = helperConfig.shooterEnableHotkey or helperConfig.shooterHotkey or "F10"
	helperConfig.shooterPresetHotkey = nil
	helperConfig.sharedCombatHotkey = helperConfig.sharedCombatHotkey or ""

	if HelperTarget and HelperTarget.collectHotkeys then
		HelperTarget.collectHotkeys(helperConfig)
	end

	if HelperShooter and HelperShooter.collectHotkeys then
		HelperShooter.collectHotkeys(helperConfig)
	end

	for _, tab in pairs(TABS) do
		local mod = modulesByTab[tab.module]

		if mod and mod.collectConfig then
			mod.collectConfig(helperConfig)
		end
	end

	if HelperConditions and HelperConditions.collectConfig then
		HelperConditions.collectConfig(helperConfig)
	end

	return copyConfig(helperConfig)
end

local function saveConfig()
	if loadingConfig then
		return false
	end

	if combatHotkeyBatchActive then
		combatHotkeySavePending = true

		return true
	end

	if not helperWindow then
		return false
	end

	local snapshot = collectHelperConfigSnapshot()

	helperConfig = snapshot

	local data = readHelperJSON()

	data.autoSaveEnabled = isAutoSaveEnabled()
	data.current = copyConfig(snapshot)

	if data.autoSaveEnabled then
		local profileName = getProfileNameForAutoSave()

		if not profileName or profileName == "" then
			profileName = data.activeProfile
		end

		if not profileName or profileName == "" then
			profileName = getDefaultProfileName()
		end

		if profileName and profileName ~= "" then
			data.profiles = data.profiles or {}
			data.profiles[profileName] = copyConfig(snapshot)
			data.activeProfile = profileName

			if HelperConfigTab and HelperConfigTab.setSelectedProfileName then
				HelperConfigTab.setSelectedProfileName(profileName)
			end
		end
	end

	local saved = writeHelperJSON(data)

	if not saved then
		helperLog("error", "Auto-save failed.")
	end

	refreshHelperStatsWindow()

	return saved
end

local function flushAutoSave()
	if not autoSaveEvent then
		return
	end

	cancelAutoSave()
	saveConfig()
end

local function saveActiveHelperCharacter()
	if not activeHelperCharacterId or helperSavedOnLogout then
		return false
	end

	cancelAutoSave()

	if saveConfig() then
		helperSavedOnLogout = true

		return true
	end

	return false
end

local function updateSetHotkeyButtonLabel()
	local btn = getWidget("setHotkeyButton")

	if not btn then
		return
	end

	local hotkey = helperConfig.hotkey or ""

	if hotkey == "" then
		btn:setText(tr("Key [NONE]"))
	else
		btn:setText(tr("Key [%s]", hotkey))
	end
end

local function toggleHelperEnabled()
	if loadingConfig then
		return
	end

	local check = getWidget("checkbox")

	if not check then
		return
	end

	check:setChecked(not check:isChecked())
end

local function unbindHelperHotkey()
	if boundHelperHotkey and boundHelperHotkey ~= "" then
		g_keyboard.unbindKeyPress(boundHelperHotkey)
	end

	boundHelperHotkey = nil
end

local helperHotkeyConflict

local function bindHelperHotkey()
	unbindHelperHotkey()

	local hotkey = helperConfig.hotkey

	if type(hotkey) ~= "string" or hotkey == "" then
		updateSetHotkeyButtonLabel()

		return
	end

	if helperHotkeyConflict and helperHotkeyConflict(hotkey) then
		helperLog("warning", "Helper hotkey not bound because it is already in use: " .. hotkey)
		updateSetHotkeyButtonLabel()

		return
	end

	boundHelperHotkey = hotkey

	g_keyboard.bindKeyPress(hotkey, function()
		if not HotkeyUtils.canPerformKeyCombo(hotkey) then
			return
		end

		toggleHelperEnabled()
	end)
	updateSetHotkeyButtonLabel()
end

function helperHotkeyConflict(combo)
	if not combo or combo == "" then
		return false
	end

	if g_keyboard.isReservedMovementHotkey and g_keyboard.isReservedMovementHotkey(combo) then
		return true
	end

	if combo == helperConfig.autoTargetHotkey or combo == helperConfig.shooterEnableHotkey or combo == helperConfig.shooterHotkey or combo == helperConfig.sharedCombatHotkey or HelperShooter and HelperShooter.hasPresetHotkey and HelperShooter.hasPresetHotkey(combo) then
		return true
	end

	if Keybind and Keybind.isKeyComboUsedOnActionBar then
		if Keybind.isKeyComboUsedOnActionBar(combo, CHAT_MODE.ON) or Keybind.isKeyComboUsedOnActionBar(combo, CHAT_MODE.OFF) then
			return true
		end
	else
		local ab = modules.game_actionbar

		if ab and ab.checkHotkey and ab.checkHotkey(combo, nil) then
			return true
		end
	end

	if Keybind and Keybind.isKeyComboUsedOnCustomHotkeys then
		return Keybind.isKeyComboUsedOnCustomHotkeys(combo, CHAT_MODE.ON) == true or Keybind.isKeyComboUsedOnCustomHotkeys(combo, CHAT_MODE.OFF) == true
	end

	if CustomHotkeyManager and CustomHotkeyManager.isKeyComboUsed then
		return CustomHotkeyManager.isKeyComboUsed(combo, nil, CHAT_MODE.ON) == true or CustomHotkeyManager.isKeyComboUsed(combo, nil, CHAT_MODE.OFF) == true
	end

	return false
end

local function updateHelperHotkeyPreview()
	if not helperHotkeyWindow or helperHotkeyWindow:isDestroyed() then
		return
	end

	local comboPreview = helperHotkeyWindow:recursiveGetChildById("comboPreview")

	if comboPreview then
		comboPreview:setText(tr("%s", helperHotkeyPendingCombo or ""))
		comboPreview:resizeToText()
	end

	local errorLabel = helperHotkeyWindow:recursiveGetChildById("errorLabel")
	local conflict = helperHotkeyConflict(helperHotkeyPendingCombo)

	if errorLabel then
		errorLabel:setText(helperLanguage == "pt" and "Esta hotkey ja esta em uso." or "This hotkey is already in use.")
		errorLabel:setVisible(conflict)
	end

	local applyButton = helperHotkeyWindow:recursiveGetChildById("applyButton")

	if applyButton then
		applyButton:setEnabled(not conflict and helperHotkeyPendingCombo ~= "")
	end
end

function closeHelperHotkeyWindow()
	if helperHotkeyWindow and not helperHotkeyWindow:isDestroyed() then
		helperHotkeyWindow:destroy()
	end

	helperHotkeyWindow = nil
	helperHotkeyPendingCombo = ""
end

local function onHelperHotkeyKeyDown(_, keyCode, keyboardModifiers, keyText)
	if not helperHotkeyWindow or helperHotkeyWindow:isDestroyed() then
		return false
	end

	helperHotkeyWindow:raise()
	helperHotkeyWindow:focus()

	helperHotkeyPendingCombo = determineKeyComboDesc(keyCode, keyboardModifiers, keyText) or ""

	updateHelperHotkeyPreview()

	return true
end

function onHelperHotkeyCaptureOk()
	local combo = helperHotkeyPendingCombo or ""

	if combo == "" then
		return
	end

	if type(combo) ~= "string" then
		combo = tostring(combo)
	end

	if helperHotkeyConflict(combo) then
		updateHelperHotkeyPreview()

		return
	end

	helperConfig.hotkey = combo

	bindHelperHotkey()
	saveConfig()
	helperLog("info", "Helper hotkey assigned: " .. combo)
	closeHelperHotkeyWindow()
end

function onHelperHotkeyClear()
	helperConfig.hotkey = ""

	bindHelperHotkey()
	saveConfig()
	helperLog("info", "Helper hotkey cleared.")
	closeHelperHotkeyWindow()
end

function openHelperHotkeyWindow()
	if helperHotkeyWindow and not helperHotkeyWindow:isDestroyed() then
		closeHelperHotkeyWindow()
	end

	helperHotkeyWindow = g_ui.loadUI("/game_actionbar/assign_hotkey", g_ui.getRootWidget())

	if not helperHotkeyWindow then
		helperLog("error", "Failed to load assign_hotkey UI.")

		return
	end

	helperHotkeyPendingCombo = helperConfig.hotkey or ""

	helperHotkeyWindow:setText(tr("Edit Hotkey for Helper"))

	local chatModeLabel = helperHotkeyWindow:recursiveGetChildById("chatMode")

	if chatModeLabel then
		chatModeLabel:setVisible(false)
	end

	local instrLabel = helperHotkeyWindow:recursiveGetChildById("hotkeyInstructionLabel")

	if instrLabel then
		instrLabel:setText(tr("Click \"Ok\" to assign the hotkey. Click \"Clear\" to remove the helper hotkey."))
	end

	updateHelperHotkeyPreview()

	helperHotkeyWindow.onKeyDown = onHelperHotkeyKeyDown
	helperHotkeyWindow.onEscape = closeHelperHotkeyWindow

	local applyBtn = helperHotkeyWindow:recursiveGetChildById("applyButton")

	if applyBtn then
		function applyBtn.onClick()
			onHelperHotkeyCaptureOk()
		end
	end

	local clearBtn = helperHotkeyWindow:recursiveGetChildById("clearButton")

	if clearBtn then
		function clearBtn.onClick()
			onHelperHotkeyClear()
		end
	end

	local cancelBtn = helperHotkeyWindow:recursiveGetChildById("cancelButton")

	if cancelBtn then
		function cancelBtn.onClick()
			closeHelperHotkeyWindow()
		end
	end

	helperHotkeyWindow:grabKeyboard()
	helperHotkeyWindow:raise()
	helperHotkeyWindow:focus()

	helperHotkeyWindow.hotkeyBlock = HotkeyUtils.createHotkeyBlock("helper_hotkey_window")
end

local function updateSetShooterHotkeyButtonLabel()
	if HelperShooter and HelperShooter.updateShooterHotkeyLabels then
		HelperShooter.updateShooterHotkeyLabels(helperConfig)
	end
end

local function updateSharedCombatHotkeyButtonLabel()
	local btn = getWidget("configsSharedHotkeyButton")

	if not btn then
		return
	end

	local sharedHotkey = helperConfig.sharedCombatHotkey or ""

	btn:setText(sharedHotkey == "" and tr("Key [NONE]") or tr("Key [%s]", sharedHotkey))
end

local function toggleShooterEnabled()
	if loadingConfig then
		return
	end

	if HelperShooter and HelperShooter.toggleShooterEnableHotkey then
		HelperShooter.toggleShooterEnableHotkey()
	end
end

local function unbindShooterHotkey()
	return
end

function closeShooterHotkeyWindow()
	if shooterHotkeyWindow and not shooterHotkeyWindow:isDestroyed() then
		shooterHotkeyWindow:destroy()
	end

	shooterHotkeyWindow = nil
	shooterHotkeyPendingCombo = ""
	shooterPresetHotkeyProfileName = nil
end

local function bindShooterHotkey()
	bindCombatHotkeys()
	updateSetShooterHotkeyButtonLabel()
end

local combatHotkeyConflict
local COMBAT_HOTKEY_CHAT_MODES = {
	CHAT_MODE.ON,
	CHAT_MODE.OFF
}

local function isNativeKeybindUsed(combo)
	if not Keybind or not combo or combo == "" then
		return false
	end

	if Keybind.isKeyComboUsed then
		for _, chatMode in ipairs(COMBAT_HOTKEY_CHAT_MODES) do
			if Keybind.isKeyComboUsed(combo, nil, nil, chatMode) then
				return true
			end
		end

		return false
	end

	if Keybind.reservedKeys and Keybind.reservedKeys[combo] then
		return true
	end

	if not Keybind.defaultKeybinds or not Keybind.getKeybindKeys then
		return false
	end

	for _, chatMode in ipairs(COMBAT_HOTKEY_CHAT_MODES) do
		for _, keybind in pairs(Keybind.defaultKeybinds) do
			local keys = Keybind.getKeybindKeys(keybind.category, keybind.action, chatMode, Keybind.currentPreset)

			if keys and (keys.primary == combo or keys.secondary == combo) then
				return true
			end
		end
	end

	return false
end

local function isActionBarHotkeyUsed(combo)
	for _, chatMode in ipairs(COMBAT_HOTKEY_CHAT_MODES) do
		if Keybind and Keybind.isKeyComboUsedOnActionBar and Keybind.isKeyComboUsedOnActionBar(combo, chatMode) then
			return true
		end

		local actionbar = modules.game_actionbar

		if (not Keybind or not Keybind.isKeyComboUsedOnActionBar) and actionbar and actionbar.isKeyComboUsedOnActionBar and actionbar.isKeyComboUsedOnActionBar(combo, chatMode == CHAT_MODE.ON) then
			return true
		end
	end

	return false
end

local function isCustomHotkeyUsed(combo)
	for _, chatMode in ipairs(COMBAT_HOTKEY_CHAT_MODES) do
		if Keybind and Keybind.isKeyComboUsedOnCustomHotkeys and Keybind.isKeyComboUsedOnCustomHotkeys(combo, chatMode) then
			return true
		end

		if (not Keybind or not Keybind.isKeyComboUsedOnCustomHotkeys) and CustomHotkeyManager and CustomHotkeyManager.isKeyComboUsed and CustomHotkeyManager.isKeyComboUsed(combo, nil, chatMode) then
			return true
		end
	end

	return false
end

function combatHotkeyConflict(kind, combo, presetProfileName)
	if type(combo) ~= "string" or combo == "" then
		return false, nil
	end

	if g_keyboard.isReservedMovementHotkey and g_keyboard.isReservedMovementHotkey(combo) then
		return true, helperLanguage == "pt" and "Esta hotkey e reservada para movimento." or "This hotkey is reserved for movement."
	end

	if isNativeKeybindUsed(combo) then
		return true, helperLanguage == "pt" and "Hotkey usada nos controles. Escolha outra." or "Hotkey used in Controls. Choose another."
	end

	local targetHotkey = helperConfig.autoTargetHotkey or ""
	local shooterHotkey = helperConfig.shooterEnableHotkey or helperConfig.shooterHotkey or ""
	local sharedHotkey = helperConfig.sharedCombatHotkey or ""
	local presetHotkeyConflict = HelperShooter and HelperShooter.hasPresetHotkey and HelperShooter.hasPresetHotkey(combo, kind == "preset" and presetProfileName or nil)

	if combo == helperConfig.hotkey or kind ~= "target" and combo == targetHotkey or kind ~= "enable" and (combo == shooterHotkey or combo == helperConfig.shooterHotkey) or kind ~= "shared" and combo == sharedHotkey or presetHotkeyConflict or isActionBarHotkeyUsed(combo) or isCustomHotkeyUsed(combo) then
		return true, helperLanguage == "pt" and "Esta hotkey ja esta em uso." or "This hotkey is already in use."
	end

	return false, nil
end

local function sharedCombatHotkeyConflict(combo)
	return combatHotkeyConflict("shared", combo)
end

local function applySharedCombatHotkey(combo)
	helperConfig.sharedCombatHotkey = combo

	bindCombatHotkeys()
	saveConfig()
	showHelperMessage(false, helperLanguage == "pt" and string.format("Hotkey %s definida para ativar Target e Shooter juntos.", combo) or string.format("Hotkey %s assigned to toggle Target and Shooter together.", combo))
end

local function clearSharedCombatHotkey()
	helperConfig.sharedCombatHotkey = ""

	bindCombatHotkeys()
	saveConfig()
	showHelperMessage(false, helperLanguage == "pt" and "Hotkey conjunta removida. As hotkeys individuais foram preservadas." or "Shared hotkey cleared. Individual hotkeys were preserved.")
end

local function openCombatHotkeyWindow(kind, title, configKey, clearMessage, presetProfileName)
	if shooterHotkeyWindow and not shooterHotkeyWindow:isDestroyed() then
		shooterHotkeyWindow:destroy()
	end

	shooterHotkeyWindow = g_ui.loadUI("/game_actionbar/assign_hotkey", g_ui.getRootWidget())

	if not shooterHotkeyWindow then
		return
	end

	shooterPresetHotkeyProfileName = kind == "preset" and presetProfileName or nil

	if kind == "shared" then
		shooterHotkeyPendingCombo = helperConfig.sharedCombatHotkey or ""
	elseif kind == "target" then
		shooterHotkeyPendingCombo = helperConfig.autoTargetHotkey or ""
	elseif kind == "preset" then
		shooterHotkeyPendingCombo = HelperShooter and HelperShooter.getPresetHotkey and HelperShooter.getPresetHotkey(shooterPresetHotkeyProfileName) or ""
	else
		shooterHotkeyPendingCombo = helperConfig.shooterEnableHotkey or ""
	end

	shooterHotkeyWindow:setText(tr(title))

	local chatModeLabel = shooterHotkeyWindow:recursiveGetChildById("chatMode")

	if chatModeLabel then
		chatModeLabel:setVisible(false)
	end

	local instrLabel = shooterHotkeyWindow:recursiveGetChildById("hotkeyInstructionLabel")

	if instrLabel then
		instrLabel:setText(tr(clearMessage))
	end

	local comboPreview = shooterHotkeyWindow:recursiveGetChildById("comboPreview")
	local errorLabel = shooterHotkeyWindow:recursiveGetChildById("errorLabel")
	local applyBtn = shooterHotkeyWindow:recursiveGetChildById("applyButton")

	local function refreshCombatHotkeyPreview()
		if comboPreview then
			comboPreview:setText(tr("%s", shooterHotkeyPendingCombo or ""))
			comboPreview:resizeToText()
		end

		local combo = shooterHotkeyPendingCombo or ""
		local conflict, conflictMessage = combatHotkeyConflict(kind, combo, shooterPresetHotkeyProfileName)

		if errorLabel then
			errorLabel:setText(conflictMessage or helperLanguage == "pt" and "Esta hotkey ja esta em uso." or "This hotkey is already in use.")
			errorLabel:setVisible(conflict)
		end

		if applyBtn then
			applyBtn:setEnabled(combo ~= "" and not conflict)
		end
	end

	refreshCombatHotkeyPreview()

	function shooterHotkeyWindow.onKeyDown(_, keyCode, keyboardModifiers, keyText)
		if not shooterHotkeyWindow or shooterHotkeyWindow:isDestroyed() then
			return false
		end

		shooterHotkeyWindow:raise()
		shooterHotkeyWindow:focus()

		shooterHotkeyPendingCombo = determineKeyComboDesc(keyCode, keyboardModifiers, keyText) or ""

		refreshCombatHotkeyPreview()

		return true
	end

	shooterHotkeyWindow.onEscape = closeShooterHotkeyWindow

	if applyBtn then
		function applyBtn.onClick()
			local combo = shooterHotkeyPendingCombo or ""
			local conflict = combatHotkeyConflict(kind, combo, shooterPresetHotkeyProfileName)

			if combo == "" or conflict then
				refreshCombatHotkeyPreview()

				return
			end

			if kind == "shared" then
				applySharedCombatHotkey(combo)
				closeShooterHotkeyWindow()

				return
			elseif kind == "target" then
				helperConfig.autoTargetHotkey = combo
			elseif kind == "preset" then
				if not HelperShooter or not HelperShooter.setPresetHotkey or not HelperShooter.setPresetHotkey(shooterPresetHotkeyProfileName, combo) then
					closeShooterHotkeyWindow()

					return
				end
			else
				helperConfig.shooterEnableHotkey = combo
				helperConfig.shooterHotkey = combo
			end

			bindCombatHotkeys()
			saveConfig()
			closeShooterHotkeyWindow()
		end
	end

	local clearBtn = shooterHotkeyWindow:recursiveGetChildById("clearButton")

	if clearBtn then
		function clearBtn.onClick()
			if kind == "shared" then
				clearSharedCombatHotkey()
			elseif kind == "target" then
				helperConfig.autoTargetHotkey = ""
			elseif kind == "preset" then
				if HelperShooter and HelperShooter.setPresetHotkey then
					HelperShooter.setPresetHotkey(shooterPresetHotkeyProfileName, "")
				end
			else
				helperConfig.shooterEnableHotkey = ""
				helperConfig.shooterHotkey = ""
			end

			if kind ~= "shared" then
				bindCombatHotkeys()
				saveConfig()
			end

			closeShooterHotkeyWindow()
		end
	end

	local cancelBtn = shooterHotkeyWindow:recursiveGetChildById("cancelButton")

	if cancelBtn then
		cancelBtn.onClick = closeShooterHotkeyWindow
	end

	shooterHotkeyWindow:grabKeyboard()
	shooterHotkeyWindow:raise()
	shooterHotkeyWindow:focus()
end

function openTargetHotkeyWindow()
	openCombatHotkeyWindow("target", "Edit Hotkey for Auto Target", "autoTargetHotkey", "Click Ok to assign. Clear removes the hotkey.")
end

function openSharedCombatHotkeyWindow()
	local title = helperLanguage == "pt" and "Editar Hotkey do Target + Shooter" or "Edit Hotkey for Target + Shooter"
	local instruction = helperLanguage == "pt" and "Clique Ok para criar um atalho independente que alterna os dois juntos. Limpar remove apenas este atalho." or "Click Ok to create an independent shortcut that toggles both together. Clear removes only this shortcut."

	openCombatHotkeyWindow("shared", title, "sharedCombatHotkey", instruction)
end

function openPresetHotkeyWindow(profileName)
	if not HelperShooter or not HelperShooter.getPresetHotkey or HelperShooter.getPresetHotkey(profileName) == nil then
		return
	end

	local title = helperLanguage == "pt" and string.format("Editar Hotkey do Perfil %s", profileName) or string.format("Edit Hotkey for Profile %s", profileName)
	local instruction = helperLanguage == "pt" and "Clique Ok para definir. Limpar remove a hotkey deste perfil." or "Click Ok to assign. Clear removes this profile hotkey."

	openCombatHotkeyWindow("preset", title, nil, instruction, profileName)
end

function openShooterEnableHotkeyWindow()
	openCombatHotkeyWindow("enable", "Edit Hotkey for Shooter Enable", "shooterEnableHotkey", "Click Ok to assign. Clear removes the hotkey.")
end

local function applyConfigToWidgets(config)
	helperConfig = copyConfig(config or {})
	loadingConfig = true

	local helperCheck = getWidget("checkbox")
	local healingCheck = getWidget("enableHealingCheckBox")
	local healFriendCheck = getWidget("enableHealFriendCheckBox")

	if helperCheck then
		helperCheck:setChecked(helperConfig.enableHelper == true)
	end

	if healingCheck then
		healingCheck:setChecked(helperConfig.enableHealing == true)
	end

	if healFriendCheck then
		healFriendCheck:setChecked(helperConfig.enableHealFriend == true)
	end

	initDistanceControls()

	for _, tab in pairs(TABS) do
		local mod = modulesByTab[tab.module]

		if mod and mod.loadFromConfig then
			local ok, err = pcall(mod.loadFromConfig, helperConfig)

			if not ok then
				helperLog("warning", "loadFromConfig failed for " .. tostring(tab.module) .. ": " .. tostring(err))
			end
		end
	end

	if HelperConditions and HelperConditions.loadFromConfig then
		HelperConditions.loadFromConfig(helperConfig)
	end

	local healFriend = modulesByTab.healFriend

	if healFriend and healFriend.refreshAllPrioritySteppers then
		healFriend.refreshAllPrioritySteppers()
	end

	loadingConfig = false

	bindHelperHotkey()
	bindCombatHotkeys()

	if HelperShooter and HelperShooter.syncHotkeyStatus then
		HelperShooter.syncHotkeyStatus()
	end

	if syncCombatSchedulerState then
		syncCombatSchedulerState()
	end

	refreshHelperStatsWindow()
end

local function loadConfigIntoWidgets()
	local data = readHelperJSON()
	local defaultName = getDefaultProfileName()
	local needsPersist = false

	if HelperConfigTab and HelperConfigTab.setLanguage then
		HelperConfigTab.setLanguage(data.language, false)
	end

	local characterProfile = activeHelperCharacterName

	if isAutoSwitchHotkeyPresetEnabled() and characterProfile and characterProfile ~= "" and type(data.profiles[characterProfile]) == "table" and data.activeProfile ~= characterProfile then
		data.activeProfile = characterProfile
		data.current = copyConfig(data.profiles[characterProfile])
		needsPersist = true

		helperLog("info", "Auto-switched Helper profile to \"" .. characterProfile .. "\".")
	end

	if data.autoSaveEnabled == nil then
		data.autoSaveEnabled = true
		needsPersist = true
	end

	if not data.activeProfile or data.activeProfile == "" or type(data.profiles[data.activeProfile]) ~= "table" then
		data.activeProfile = defaultName
		needsPersist = true
	end

	local config = data.current or {}

	if data.activeProfile and type(data.profiles) == "table" and type(data.profiles[data.activeProfile]) == "table" then
		config = data.profiles[data.activeProfile]

		if HelperConfigTab and HelperConfigTab.setSelectedProfileName then
			HelperConfigTab.setSelectedProfileName(data.activeProfile)
			HelperConfigTab.syncProfileNameEdit(data.activeProfile)
		end
	elseif type(data.profiles) == "table" and type(data.profiles[defaultName]) == "table" then
		config = data.profiles[defaultName]

		if data.activeProfile == defaultName and HelperConfigTab then
			if HelperConfigTab.setSelectedProfileName then
				HelperConfigTab.setSelectedProfileName(defaultName)
			end

			if HelperConfigTab.syncProfileNameEdit then
				HelperConfigTab.syncProfileNameEdit(defaultName)
			end
		end
	end

	applyConfigToWidgets(config)

	if data.autoSaveEnabled == false then
		applyAutoSavePreferenceToCheckbox(false)
	else
		if data.autoSaveEnabled ~= true then
			needsPersist = true
		end

		data.autoSaveEnabled = true

		applyAutoSavePreferenceToCheckbox(true)
	end

	if needsPersist then
		writeHelperJSON(data)
	end

	if HelperConfigTab and HelperConfigTab.refreshProfileList then
		HelperConfigTab.refreshProfileList()
	end
end

function showHelperMessage(failure, message)
	if not modules.game_textmessage then
		return
	end

	if failure then
		modules.game_textmessage.displayFailureMessage(message)
	else
		modules.game_textmessage.displayGameMessage(message)
	end
end

local function buildRuntimeState()
	local player = g_game.getLocalPlayer()

	if not player then
		return nil
	end

	local healthPercent = player.getHealthPercent and player:getHealthPercent()

	if not healthPercent then
		local maxHealth = player:getMaxHealth() or 0

		healthPercent = maxHealth > 0 and player:getHealth() / maxHealth * 100 or 100
	end

	local maxMana = player:getMaxMana() or 0
	local manaPercent = maxMana > 0 and player:getMana() / maxMana * 100 or 100

	return {
		nowMs = g_clock.millis(),
		player = player,
		healthPercent = healthPercent,
		manaPercent = manaPercent
	}
end

local function helperShouldRunTick()
	if not g_game.isOnline() then
		return false
	end

	local enableHelper = getWidget("checkbox")

	return enableHelper and enableHelper:isChecked() or false
end

local function combatFeatureStates()
	if not helperShouldRunTick() then
		return false, false
	end

	local targetCheck = getWidget("enableTargetCheckBox")
	local shooterCheck = getWidget("enableShooterCheckBox")

	return targetCheck and targetCheck:isChecked() or false, shooterCheck and shooterCheck:isChecked() or false
end

local function runCombatTick()
	local tickStartedUs = g_clock.realMicros()
	local targetEnabled, shooterEnabled = combatFeatureStates()

	if not targetEnabled and not shooterEnabled then
		return false
	end

	local stateStartedUs = g_clock.realMicros()
	local state = buildRuntimeState()
	local stateUs = g_clock.realMicros() - stateStartedUs

	if not state then
		return true
	end

	local targetUs = 0
	local targetMod = modulesByTab.target

	if targetEnabled and targetMod and targetMod.runTick then
		local targetStartedUs = g_clock.realMicros()
		local ok, err = pcall(targetMod.runTick, state)

		targetUs = g_clock.realMicros() - targetStartedUs

		if not ok and g_logger and g_logger.error then
			g_logger.error("[game_helper] combatTick target failure: " .. tostring(err))
		end
	end

	local shooterUs = 0
	local shooterScanUs = 0
	local shooterCreatureCount = 0
	local shooterPriorityCount = 0
	local shooterHotPriority = "none"
	local shooterHotPriorityUs = 0
	local shooterMod = modulesByTab.shooter

	if shooterEnabled and shooterMod and shooterMod.runTick then
		local shooterStartedUs = g_clock.realMicros()
		local ok, err = pcall(shooterMod.runTick, state)

		shooterUs = g_clock.realMicros() - shooterStartedUs

		if shooterMod.getLastTickProfile then
			shooterScanUs, shooterCreatureCount, shooterPriorityCount, shooterHotPriority, shooterHotPriorityUs = shooterMod.getLastTickProfile()
		end

		if not ok and g_logger and g_logger.error then
			g_logger.error("[game_helper] combatTick shooter failure: " .. tostring(err))
		end
	end

	local totalUs = g_clock.realMicros() - tickStartedUs

	if totalUs >= 5000 and g_logger and g_logger.warning then
		g_logger.warning(string.format("[HelperHitch] total=%.2fms state=%.2fms target=%.2fms shooter=%.2fms scan=%.2fms creatures=%d priorities=%d hot=%s/%.2fms active=%s/%s", totalUs / 1000, stateUs / 1000, targetUs / 1000, shooterUs / 1000, (tonumber(shooterScanUs) or 0) / 1000, tonumber(shooterCreatureCount) or 0, tonumber(shooterPriorityCount) or 0, tostring(shooterHotPriority or "none"), (tonumber(shooterHotPriorityUs) or 0) / 1000, tostring(targetEnabled), tostring(shooterEnabled)))
	end

	return true
end

local function stopCombatScheduler()
	if combatTickEvent then
		removeEvent(combatTickEvent)

		combatTickEvent = nil
	end
end

local function startCombatScheduler()
	if combatTickEvent then
		return
	end

	local targetEnabled, shooterEnabled = combatFeatureStates()

	if not targetEnabled and not shooterEnabled then
		return
	end

	combatTickEvent = scheduleEvent(function()
		combatTickEvent = nil

		local ok, shouldContinue = pcall(runCombatTick)

		if not ok then
			if g_logger and g_logger.error then
				g_logger.error("[game_helper] combatTick failure: " .. tostring(shouldContinue))
			end
		elseif not shouldContinue then
			return
		end

		startCombatScheduler()
	end, combatTickIntervalMs)
end

function syncCombatSchedulerState()
	local targetEnabled, shooterEnabled = combatFeatureStates()

	if targetEnabled or shooterEnabled then
		startCombatScheduler()
	else
		stopCombatScheduler()
	end
end

local function bindCombatHotkeysImpl()
	if boundSharedCombatHotkey and boundSharedCombatHotkey ~= "" then
		g_keyboard.unbindKeyPress(boundSharedCombatHotkey)
	end

	boundSharedCombatHotkey = nil

	if HelperTarget and HelperTarget.unbindHotkeys then
		HelperTarget.unbindHotkeys()
	end

	if HelperShooter and HelperShooter.unbindHotkeys then
		HelperShooter.unbindHotkeys()
	end

	local sharedHotkey = helperConfig.sharedCombatHotkey or ""

	if HelperTarget and HelperTarget.bindHotkeys then
		HelperTarget.bindHotkeys(helperConfig, false)
	end

	local skippedPresetHotkeys = {}

	if HelperShooter and HelperShooter.bindHotkeys then
		skippedPresetHotkeys = HelperShooter.bindHotkeys(helperConfig, false, function(profileName, hotkey)
			return combatHotkeyConflict("preset", hotkey, profileName)
		end) or {}
	end

	for _, skipped in ipairs(skippedPresetHotkeys) do
		helperLog("warning", string.format("Shooter profile hotkey not bound because it is already in use: %s (%s)", tostring(skipped.profile), tostring(skipped.key)))
	end

	local sharedConflict = sharedHotkey ~= "" and sharedCombatHotkeyConflict(sharedHotkey) or false

	if sharedHotkey ~= "" and not sharedConflict then
		local sharedCombo = sharedHotkey

		boundSharedCombatHotkey = sharedCombo

		g_keyboard.bindKeyPress(sharedCombo, function()
			if not HotkeyUtils.canPerformKeyCombo(sharedCombo) then
				return
			end

			local helperCheck = getWidget("checkbox")

			if not helperCheck or not helperCheck:isChecked() then
				return
			end

			local targetCheck = getWidget("enableTargetCheckBox")
			local shooterCheck = getWidget("enableShooterCheckBox")
			local bothEnabled = targetCheck and targetCheck:isChecked() and shooterCheck and shooterCheck:isChecked()
			local newState = not bothEnabled

			combatHotkeyBatchActive = true
			combatHotkeySavePending = false
			combatHotkeyStatsPending = false

			local ok, err = pcall(function()
				if HelperTarget and HelperTarget.setAutoTargetEnabledFromHotkey then
					HelperTarget.setAutoTargetEnabledFromHotkey(newState, true)
				end

				if HelperShooter and HelperShooter.toggleMagicShooterFromHotkey then
					HelperShooter.toggleMagicShooterFromHotkey(newState, true)
				end
			end)
			local shouldSave = combatHotkeySavePending
			local shouldRefreshStats = combatHotkeyStatsPending

			combatHotkeyBatchActive = false
			combatHotkeySavePending = false
			combatHotkeyStatsPending = false

			if shouldSave then
				autoSave()
			elseif shouldRefreshStats then
				refreshHelperStatsWindow()
			end

			if not ok then
				error(err, 0)
			end

			local targetEnabled = targetCheck and targetCheck:isChecked() or false
			local shooterEnabled = shooterCheck and shooterCheck:isChecked() or false

			if targetEnabled == shooterEnabled then
				local message

				if helperLanguage == "pt" then
					message = string.format("Auto Target e Shooter %s.", targetEnabled and "ativados" or "desativados")
				else
					message = string.format("Auto Target and Shooter are %s.", targetEnabled and "enabled" or "disabled")
				end

				showHelperMessage(false, message)
			else
				local message

				if helperLanguage == "pt" then
					message = string.format("Auto Target %s. Shooter %s.", targetEnabled and "ativado" or "desativado", shooterEnabled and "ativado" or "desativado")
				else
					message = string.format("Auto Target is %s. Shooter is %s.", targetEnabled and "enabled" or "disabled", shooterEnabled and "enabled" or "disabled")
				end

				showHelperMessage(false, message)
			end
		end)
	elseif sharedConflict then
		helperLog("warning", "Shared combat hotkey not bound because it is already in use: " .. tostring(sharedHotkey))
	end

	updateSharedCombatHotkeyButtonLabel()
end

bindCombatHotkeys = bindCombatHotkeysImpl

local function unbindCombatHotkeysImpl()
	if boundSharedCombatHotkey and boundSharedCombatHotkey ~= "" then
		g_keyboard.unbindKeyPress(boundSharedCombatHotkey)
	end

	boundSharedCombatHotkey = nil

	if HelperTarget and HelperTarget.unbindHotkeys then
		HelperTarget.unbindHotkeys()
	end

	if HelperShooter and HelperShooter.unbindHotkeys then
		HelperShooter.unbindHotkeys()
	end
end

unbindCombatHotkeys = unbindCombatHotkeysImpl

local function connectCombatEvents()
	function combatCreatureAppearHandler(creature)
		local mod = modulesByTab.target

		if mod and mod.onCreatureAppear then
			mod.onCreatureAppear(creature)
		end
	end

	function combatCreatureDisappearHandler(creature)
		local mod = modulesByTab.target

		if mod and mod.onCreatureDisappear then
			mod.onCreatureDisappear(creature)
		end
	end

	function combatSpellCooldownHandler(spellId, duration)
		if HelperShooter and HelperShooter.onSpellCooldown then
			HelperShooter.onSpellCooldown(spellId, duration)
		end
	end

	function combatSpellGroupCooldownHandler(groupId, duration)
		if HelperShooter and HelperShooter.onSpellGroupCooldown then
			HelperShooter.onSpellGroupCooldown(groupId, duration)
		end
	end

	function combatMultiUseCooldownHandler(duration)
		if HelperShooter and HelperShooter.onMultiUseCooldown then
			HelperShooter.onMultiUseCooldown(duration)
		end
	end

	function combatAttackingCreatureChangeHandler(creature, oldCreature)
		local targetMod = modulesByTab.target

		if targetMod and targetMod.onAttackingCreatureChange then
			targetMod.onAttackingCreatureChange(creature, oldCreature)
		end

		local shooterMod = modulesByTab.shooter

		if shooterMod and shooterMod.onAttackingCreatureChange then
			local ok, err = pcall(shooterMod.onAttackingCreatureChange, creature, oldCreature)

			if not ok and g_logger and g_logger.error then
				g_logger.error("[game_helper] attackingCreatureChange shooter failure: " .. tostring(err))
			end
		end
	end

	function combatFollowingCreatureChangeHandler(creature, oldCreature)
		local mod = modulesByTab.shooter

		if mod and mod.onFollowingCreatureChange then
			mod.onFollowingCreatureChange(creature, oldCreature)
		end
	end

	function combatPlayerStatesChangeHandler(_, states, oldStates)
		local pzState = PlayerStates and PlayerStates.Pz

		if not pzState or bit.band(bit.bxor(states, oldStates), pzState) == 0 then
			return
		end

		local targetMod = modulesByTab.target

		if targetMod and targetMod.refreshProtectionZoneState then
			targetMod.refreshProtectionZoneState()
		end

		local shooterMod = modulesByTab.shooter

		if shooterMod and shooterMod.refreshProtectionZoneState then
			shooterMod.refreshProtectionZoneState()
		end
	end

	connect(Creature, {
		onAppear = combatCreatureAppearHandler,
		onDisappear = combatCreatureDisappearHandler
	})
	connect(LocalPlayer, {
		onStatesChange = combatPlayerStatesChangeHandler
	})
	connect(g_game, {
		onSpellCooldown = combatSpellCooldownHandler,
		onSpellGroupCooldown = combatSpellGroupCooldownHandler,
		onMultiUseCooldown = combatMultiUseCooldownHandler,
		onAttackingCreatureChange = combatAttackingCreatureChangeHandler,
		onFollowingCreatureChange = combatFollowingCreatureChangeHandler
	})
end

local function disconnectCombatEvents()
	if combatCreatureAppearHandler then
		disconnect(Creature, {
			onAppear = combatCreatureAppearHandler,
			onDisappear = combatCreatureDisappearHandler
		})
	end

	if combatSpellCooldownHandler or combatAttackingCreatureChangeHandler then
		disconnect(g_game, {
			onSpellCooldown = combatSpellCooldownHandler,
			onSpellGroupCooldown = combatSpellGroupCooldownHandler,
			onMultiUseCooldown = combatMultiUseCooldownHandler,
			onAttackingCreatureChange = combatAttackingCreatureChangeHandler,
			onFollowingCreatureChange = combatFollowingCreatureChangeHandler
		})
	end

	if combatPlayerStatesChangeHandler then
		disconnect(LocalPlayer, {
			onStatesChange = combatPlayerStatesChangeHandler
		})
	end
end

local function runHelperTick()
	if not helperShouldRunTick() then
		return
	end

	local state = buildRuntimeState()

	if not state then
		return
	end

	local healer = modulesByTab.healer

	if healer and healer.runTick and healer.runTick(state) then
		return
	end

	local healFriend = modulesByTab.healFriend

	if healFriend and healFriend.runTick then
		healFriend.runTick(state)
	end
end

local function startScheduler()
	if helperTickEvent then
		return
	end

	helperTickEvent = cycleEvent(function()
		local ok, err = pcall(runHelperTick)

		if not ok and g_logger and g_logger.error then
			g_logger.error("[game_helper] helperTick failure: " .. tostring(err))
		end
	end, helperTickIntervalMs)
end

local function stopScheduler()
	if helperTickEvent then
		removeEvent(helperTickEvent)

		helperTickEvent = nil
	end
end

local function initModules()
	modulesByTab.healer = HelperHealer
	modulesByTab.healFriend = HelperHealFriend
	modulesByTab.target = HelperTarget
	modulesByTab.shooter = HelperShooter
	modulesByTab.conditions = HelperConditions
	modulesByTab.tools = HelperTools
	modulesByTab.autoparty = HelperAutoParty
	modulesByTab.cavebot = HelperCavebot
	modulesByTab.config = HelperConfigTab

	local ctx = {
		getWidget = getWidget,
		getPlayerVoc = getPlayerVoc,
		saveConfig = saveConfig,
		isLoadingConfig = function()
			return loadingConfig
		end,
		getLanguage = function()
			return helperLanguage
		end,
		applyWidgetLanguage = function(target)
			translateHelperWidgetTree(target, true)
		end,
		rebindCombatHotkeys = function()
			if bindCombatHotkeys then
				bindCombatHotkeys()
			end
		end,
		requestAutoSave = function()
			autoSave()
		end,
		isTabActive = function(tabName)
			return currentTab == tabName and helperWindow and not helperWindow:isHidden()
		end,
		readDistanceValue = readDistanceValue,
		applyDistanceValue = applyDistanceValue
	}

	for _, tab in pairs(TABS) do
		if tab.module ~= "config" then
			local mod = modulesByTab[tab.module]

			if mod and mod.init then
				mod.init(ctx)
			end
		end
	end

	if HelperConditions and HelperConditions.init then
		HelperConditions.init(ctx)
	end

	if HelperConfigTab and HelperConfigTab.init then
		HelperConfigTab.init({
			getWidget = getWidget,
			readHelperJSON = readHelperJSON,
			writeHelperJSON = writeHelperJSON,
			copyConfig = copyConfig,
			collectConfig = collectHelperConfigSnapshot,
			applyConfig = applyConfigToWidgets,
			applyConfigSnapshot = function(snapshot)
				helperConfig = copyConfig(snapshot)
			end,
			isAutoSaveEnabled = isAutoSaveEnabled,
			isLoadingConfig = function()
				return loadingConfig
			end,
			getLanguage = function()
				return helperLanguage
			end,
			applyLanguage = applyHelperLanguage,
			getProfileNameForAutoSave = getProfileNameForAutoSave,
			applyAutoSavePreferenceToCheckbox = applyAutoSavePreferenceToCheckbox,
			isAutoSwitchHotkeyPresetEnabled = isAutoSwitchHotkeyPresetEnabled,
			applyAutoSwitchHotkeyPresetToCheckbox = applyAutoSwitchHotkeyPresetToCheckbox,
			cancelAutoSave = cancelAutoSave,
			flushAutoSave = flushAutoSave,
			showMessage = showHelperMessage,
			log = helperLog,
			openHelperWindow = function()
				if helperWindow then
					helperWindow:show()
					helperWindow:raise()
					helperWindow:focus()
				end
			end
		})
	end
end

local function getModuleForTab(tab)
	local cfg = tab and TABS[tab]

	return cfg and modulesByTab[cfg.module] or nil
end

local function showCurrentTabModule()
	local mod = getModuleForTab(currentTab)

	if mod and mod.onShow then
		mod.onShow()
	end
end

local function hideCurrentTabModule()
	local mod = getModuleForTab(currentTab)

	if mod and mod.onHide then
		mod.onHide()
	end
end

function showTab(tab)
	if not helperWindow or currentTab == tab then
		return
	end

	local prevTab = currentTab

	currentTab = tab

	for name, cfg in pairs(TABS) do
		local active = name == tab
		local button = getWidget(cfg.buttonId)
		local panel = getWidget(cfg.panelId)

		if button then
			button:setOn(active)
		end

		if panel then
			panel:setVisible(active)
		end
	end

	if prevTab and TABS[prevTab] then
		local prevMod = getModuleForTab(prevTab)

		if prevMod and prevMod.onHide then
			prevMod.onHide()
		end
	end

	if TABS[tab] then
		local currentMod = getModuleForTab(tab)

		if currentMod and currentMod.onShow then
			currentMod.onShow()
		end
	end

	refreshHelperUiLanguage(false)
end

local DISTANCE_MIN = 1
local DISTANCE_MAX = 7
local DISTANCE_DEFAULT = 7

function clampDistanceValue(value, default)
	local n = tonumber(value)

	if not n then
		return default or DISTANCE_DEFAULT
	end

	n = math.floor(n)

	if n < DISTANCE_MIN then
		n = DISTANCE_MIN
	end

	if n > DISTANCE_MAX then
		n = DISTANCE_MAX
	end

	return n
end

local function getDistanceWidgetText(widget)
	if not widget then
		return nil
	end

	if widget.getCurrentOption then
		local current = widget:getCurrentOption()

		if type(current) == "table" then
			return current.text
		end

		return current
	end

	if widget.getText then
		return widget:getText()
	end

	return nil
end

local function setDistanceWidgetValue(widget, value, default)
	if not widget then
		return
	end

	local text = tostring(clampDistanceValue(value, default or DISTANCE_DEFAULT))

	if widget.setCurrentOption then
		widget:setCurrentOption(text, true)
	elseif widget.setText then
		widget:setText(text)
	end
end

local function ensureDistanceComboOptions(combo)
	if not combo or not combo.addOption then
		return
	end

	if combo.getOptionsCount and combo:getOptionsCount() > 0 then
		return
	end

	for i = DISTANCE_MIN, DISTANCE_MAX do
		combo:addOption(tostring(i), i)
	end
end

function readDistanceValue(id)
	local distanceWidget = getWidget(id)

	return clampDistanceValue(getDistanceWidgetText(distanceWidget), DISTANCE_DEFAULT)
end

function applyDistanceValue(id, value)
	local distanceWidget = getWidget(id)

	ensureDistanceComboOptions(distanceWidget)
	setDistanceWidgetValue(distanceWidget, value, DISTANCE_DEFAULT)
end

function initDistanceControls()
	applyDistanceValue("targetDistanceCombo", DISTANCE_DEFAULT)
end

function onTargetDistanceChange(_)
	if loadingConfig then
		return
	end

	autoSave()
end

function onTargetModeChange(_)
	if loadingConfig then
		return
	end

	local mod = modulesByTab.target

	if mod and mod.onTargetModeChange then
		mod.onTargetModeChange()
	else
		autoSave()
	end
end

function onTargetPriorityChange(_)
	if loadingConfig then
		return
	end

	local mod = modulesByTab.target

	if mod and mod.onTargetPriorityChange then
		mod.onTargetPriorityChange()
	else
		autoSave()
	end
end

function onTargetPzAutoChange(_)
	if loadingConfig then
		return
	end

	local mod = modulesByTab.target

	if mod and mod.onTargetPzAutoChange then
		mod.onTargetPzAutoChange()
	else
		autoSave()
	end
end

function autoSave()
	if loadingConfig then
		return
	end

	cancelAutoSave()

	autoSaveEvent = scheduleEvent(function()
		autoSaveEvent = nil

		saveConfig()
	end, 800)

	refreshHelperStatsWindow()
end

function openHelperFromStats()
	if not helperWindow then
		return
	end

	local opening = helperWindow:isHidden()

	helperWindow:show()
	helperWindow:raise()
	helperWindow:focus()

	if not currentTab then
		showTab("healing")
	elseif opening then
		showCurrentTabModule()
	end

	syncButton()
end

function closeHelperStatsWindow()
	if helperStatsWindow and not helperStatsWindow:isDestroyed() then
		helperStatsWindow:closeAndForgetLayout()
	end

	syncButton()
end

function isHelperStatsWindowOpen()
	return helperStatsWindow ~= nil and not helperStatsWindow:isDestroyed() and not helperStatsWindow:isHidden()
end

function toggleHelperStatsWindow()
	if not helperStatsWindow or helperStatsWindow:isDestroyed() then
		return
	end

	if helperButton and helperButton:isOn() then
		helperStatsWindow:closeAndForgetLayout()
	else
		if not helperStatsWindow:getParent() then
			local panel = modules.game_interface.findContentPanelAvailable(helperStatsWindow, helperStatsWindow:getMinimumHeight())

			if not panel then
				return
			end

			panel:addChild(helperStatsWindow)
		end

		helperStatsWindow:open()
		refreshHelperStatsWindow()
		helperStatsWindow:raise()
		helperStatsWindow:focus()
	end

	syncButton()
end

function toggleHelperStatsEntry(itemId)
	if loadingConfig then
		return
	end

	for _, item in ipairs(HELPER_STATS_ITEMS) do
		if item.id == itemId then
			if item.id == "target" and HelperTarget and HelperTarget.isDisabledByProtectionZone and HelperTarget.isDisabledByProtectionZone() and HelperTarget.disableProtectionZonePause then
				HelperTarget.disableProtectionZonePause()
				refreshHelperStatsWindow()

				return
			end

			if item.id == "shooter" and HelperShooter and (HelperShooter.isDisabledByFollow and HelperShooter.isDisabledByFollow() or HelperShooter.isDisabledByProtectionZone and HelperShooter.isDisabledByProtectionZone()) and HelperShooter.disablePausedState then
				HelperShooter.disablePausedState()
				refreshHelperStatsWindow()

				return
			end

			local check = getWidget(item.widgetId)

			if check then
				local enabling = not check:isChecked()

				if enabling and item.id == "target" and HelperTarget and HelperTarget.enableProtectionZonePause and HelperTarget.enableProtectionZonePause() then
					refreshHelperStatsWindow()

					return
				end

				if enabling and item.id == "shooter" and HelperShooter and HelperShooter.enableProtectionZonePause and HelperShooter.enableProtectionZonePause() then
					refreshHelperStatsWindow()

					return
				end

				check:setChecked(enabling)
				refreshHelperStatsWindow()
			end

			return
		end
	end
end

function openProfileWindow()
	if HelperConfigTab and HelperConfigTab.openProfileWindow then
		HelperConfigTab.openProfileWindow()
	end
end

function onSaveProfile()
	if HelperConfigTab and HelperConfigTab.saveProfile then
		HelperConfigTab.saveProfile()
	end
end

function onLoadProfile()
	if HelperConfigTab and HelperConfigTab.loadProfile then
		HelperConfigTab.loadProfile()
	end
end

function onDeleteProfile()
	if HelperConfigTab and HelperConfigTab.deleteProfile then
		HelperConfigTab.deleteProfile()
	end
end

function onQuickProfileNew()
	if HelperConfigTab and HelperConfigTab.newQuickProfile then
		HelperConfigTab.newQuickProfile()
	end
end

function onQuickProfileSave()
	if HelperConfigTab and HelperConfigTab.saveQuickProfile then
		HelperConfigTab.saveQuickProfile()
	end
end

function onQuickProfileDelete()
	if HelperConfigTab and HelperConfigTab.deleteQuickProfile then
		HelperConfigTab.deleteQuickProfile()
	end
end

local function countAttackRunes()
	if not SpellRunesData then
		return 0
	end

	local count = 0

	for itemId, runeData in pairs(SpellRunesData) do
		if runeData.group == 1 and Spells.getRuneSpellByItem(itemId) then
			count = count + 1
		end
	end

	return count
end

local function validateHelperRuntime()
	local warnings = {}

	if not helperWindow or helperWindow:isDestroyed() then
		table.insert(warnings, "HelperWindow missing or destroyed after init")
	else
		for _, id in ipairs({
			"presetBar",
			"quickProfileCombo",
			"quickProfileNewButton",
			"quickProfileSaveButton",
			"quickProfileDeleteButton",
			"helperCharacterCard",
			"helperCharacterOutfit",
			"helperCharacterName",
			"helperCharacterLevel",
			"helperAccountStatus",
			"helperLanguageButton",
			"toolsAutoAmmoSection",
			"toolsAutoAmmoSlot",
			"toolsAutoAmmoCheckBox",
			"toolsAutoAmmoTargetCombo",
			"toolsAutoSSASection",
			"toolsAutoSSACheckBox",
			"toolsAutoMightRingSection",
			"toolsAutoMightRingCheckBox"
		}) do
			if not getWidget(id) then
				table.insert(warnings, "Helper UI widget missing: " .. id)
			end
		end

		for name, cfg in pairs(TABS) do
			if not getWidget(cfg.panelId) then
				table.insert(warnings, "Tab panel missing: " .. name .. " (" .. cfg.panelId .. ")")
			end

			if not getWidget(cfg.buttonId) then
				table.insert(warnings, "Tab button missing: " .. name .. " (" .. cfg.buttonId .. ")")
			end

			local mod = modulesByTab[cfg.module]

			if not mod then
				table.insert(warnings, "Module missing for tab: " .. name)
			end
		end
	end

	local modalPaths = {
		"assign_healing",
		"assign_target",
		"assign_shooter",
		"assign_shooter_spell",
		"assign_helper",
		"shooter_preset"
	}

	for _, path in ipairs(modalPaths) do
		local exists = g_resources.fileExists("/modules/game_helper/" .. path .. ".otui") or g_resources.fileExists("modules/game_helper/" .. path .. ".otui")

		if not exists then
			table.insert(warnings, "Modal OTUI missing: " .. path)
		end
	end

	local runeCount = countAttackRunes()

	if runeCount == 0 then
		table.insert(warnings, "No attack runes in SpellRunesData")
	else
		helperLog("info", "Attack runes available: " .. runeCount)
	end

	local data = readHelperJSON()

	if type(data) ~= "table" then
		table.insert(warnings, "Helper JSON read returned invalid data")
	else
		local probe = copyConfig({
			validateProbe = true,
			version = HELPER_JSON_VERSION
		})

		if type(probe) == "table" and probe.validateProbe then
			helperLog("info", "Profile JSON round-trip OK")
		end
	end

	if #warnings == 0 then
		helperLog("info", "Helper runtime validation passed (init, tabs, modals, runes, JSON).")
	else
		for _, msg in ipairs(warnings) do
			helperLog("warning", "Validate: " .. msg)
		end
	end
end

function init()
	g_ui.importStyle("game_helper")
	connect(g_game, {
		onGameEnd = onGameEnd,
		onGameStart = onGameStart,
		onLogout = onLogout
	})

	helperWindow = g_ui.createWidget("HelperWindow", rootWidget)

	helperWindow:hide()
	connect(LocalPlayer, {
		onLevelChange = onHelperCharacterChanged,
		onOutfitChange = onHelperCharacterChanged,
		onPremiumChange = onHelperCharacterChanged
	})

	if g_game.isOnline() and not activateHelperCharacterStorage() then
		helperLog("error", "Character Helper storage could not be activated during initialization.")
	end

	initModules()
	refreshHelperCharacterCard()
	connectCombatEvents()
	loadConfigIntoWidgets()
	setupHelperStatsWindow()

	if helperShouldRunTick() then
		startScheduler()
		syncCombatSchedulerState()
	end

	validateHelperRuntime()

	if modules.game_mainpanel then
		-- Special-buttons grid (top-right, next to the settings gear) instead of the bottom
		-- button row, at the user's request.
		helperButton = modules.game_mainpanel.addSpecialToggleButton("helperButton", tr("Open Helper Stats"), "/images/options/button_helper", toggleHelperStatsWindow, false, 1002, "HelperMainToggleButton")

		helperButton:setImageBorder(0)
	end
end

function onGameStart()
	local startedAt = g_clock.realMillis()

	if activeHelperCharacterId and not helperSavedOnLogout then
		saveActiveHelperCharacter()
	end

	cancelAutoSave()

	helperSavedOnLogout = false

	if not activateHelperCharacterStorage() then
		helperLog("error", "Character Helper storage could not be activated on game start.")
	end

	loadConfigIntoWidgets()
	helperLog("info", string.format("[login] Helper config ready in %d ms.", g_clock.realMillis() - startedAt))
	scheduleEvent(function()
		refreshHelperCharacterCard()

		if not modules.game_mainpanel then
			return
		end

		helperButton = modules.game_mainpanel.getButton("helperButton") or helperButton

		local saved = g_settings.getNode("control_buttons")

		if not saved or not saved.buttons or saved.buttons.helperButton == nil then
			modules.game_mainpanel.setMainPanelButtonVisible("helperButton", true)
		end

		syncButton()

		if helperShouldRunTick() then
			startScheduler()
			syncCombatSchedulerState()
		else
			stopScheduler()
			stopCombatScheduler()
		end

		if helperStatsWindow and helperStatsWindow.setupOnStart then
			helperStatsWindow:setupOnStart()
		end

		local targetMod = modulesByTab.target

		if targetMod and targetMod.onGameStart then
			targetMod.onGameStart()
		end

		local shooterMod = modulesByTab.shooter

		if shooterMod and shooterMod.onGameStart then
			shooterMod.onGameStart()
		end

		bindCombatHotkeys()

		local healer = modulesByTab.healer

		if healer and healer.onGameStart then
			healer.onGameStart()
		end

		local mod = modulesByTab.healFriend

		if mod and mod.applyVocationGate then
			mod.applyVocationGate()
		end
	end, 100)
end

function onLogout()
	stopScheduler()
	stopCombatScheduler()
	saveActiveHelperCharacter()
	onHelperClose()
end

function onGameEnd()
	stopScheduler()
	stopCombatScheduler()
	saveActiveHelperCharacter()
	onHelperClose()
end

function terminate()
	saveActiveHelperCharacter()
	cancelAutoSave()
	unbindHelperHotkey()
	unbindShooterHotkey()
	unbindCombatHotkeys()
	closeHelperHotkeyWindow()
	closeShooterHotkeyWindow()
	stopScheduler()
	stopCombatScheduler()
	disconnectCombatEvents()
	disconnect(g_game, {
		onGameEnd = onGameEnd,
		onGameStart = onGameStart,
		onLogout = onLogout
	})
	disconnect(LocalPlayer, {
		onLevelChange = onHelperCharacterChanged,
		onOutfitChange = onHelperCharacterChanged,
		onPremiumChange = onHelperCharacterChanged
	})

	for _, tab in pairs(TABS) do
		local mod = modulesByTab[tab.module]

		if tab.module ~= "config" and mod and mod.terminate then
			mod.terminate()
		end
	end

	if HelperConfigTab and HelperConfigTab.terminate then
		HelperConfigTab.terminate()
	end

	if HelperConditions and HelperConditions.terminate then
		HelperConditions.terminate()
	end

	if helperButton then
		helperButton:destroy()
	end

	if helperStatsWindow and not helperStatsWindow:isDestroyed() then
		helperStatsWindow:destroy()
	end

	if helperWindow and not helperWindow:isDestroyed() then
		helperWindow:destroy()
	end

	helperStatsWindow = nil
	helperWindow = nil
	helperUiLanguageCaptured = false
	activeHelperJSONFile = nil
	activeHelperCharacterId = nil
	activeHelperCharacterName = nil
	helperSavedOnLogout = false
end

function onHelperClose()
	if helperWindow then
		helperWindow:hide()
	end

	refreshHelperCharacterCard()

	local current = getModuleForTab(currentTab) or modulesByTab.healer

	if current and current.onHide then
		current.onHide()
	end

	local mod = modulesByTab.healer

	if mod and mod ~= current and mod.onHide then
		mod.onHide()
	end

	if not g_game.isOnline() then
		stopScheduler()
		stopCombatScheduler()
	end

	syncButton()
end

function toggle()
	local opening = helperWindow:isHidden()

	if not opening then
		hideCurrentTabModule()
	end

	helperWindow:setVisible(opening)

	if opening then
		if not currentTab then
			showTab("healing")
		else
			showCurrentTabModule()

			local mod = modulesByTab.healer

			if mod and mod.clearListSelection then
				mod.clearListSelection()
			end
		end

		refreshHelperCharacterCard()
		refreshHelperUiLanguage(false)
	end

	syncButton()
end

function onHelperLanguageToggle()
	if HelperConfigTab and HelperConfigTab.toggleLanguage then
		HelperConfigTab.toggleLanguage()
	end
end

function onEnableHelperChange(_, checked)
	if loadingConfig then
		return
	end

	if checked and g_game.isOnline() then
		startScheduler()
		syncCombatSchedulerState()
	else
		stopScheduler()
		stopCombatScheduler()
	end

	if not checked then
		local targetMod = modulesByTab.target

		if targetMod and targetMod.onHelperDisabled then
			targetMod.onHelperDisabled()
		end
	end

	showHelperMessage(false, string.format("Helper is %s.", checked and "enabled" or "disabled"))
	saveConfig()

	if HelperShooter and HelperShooter.syncHotkeyStatus then
		HelperShooter.syncHotkeyStatus()
	end

	refreshHelperStatsWindow()
end

function onConfigsAutoSaveChange(_, _)
	if loadingConfig then
		return
	end

	saveConfig()
end

function onConfigsAutoSwitchHotkeyPresetChange(_, checked)
	if loadingConfig then
		return
	end

	if not setAutoSwitchHotkeyPresetEnabled(checked) then
		applyAutoSwitchHotkeyPresetToCheckbox(isAutoSwitchHotkeyPresetEnabled())
		helperLog("error", "Auto-switch hotkey preset preference was not changed.")
	end
end

function cavebotAddCurrentPosition(waypointType)
	if HelperCavebot then HelperCavebot.addCurrentPosition(waypointType or "Walk") end
end

function cavebotSetDirection(direction)
	if HelperCavebot then HelperCavebot.setDirection(direction) end
end

function cavebotToggle()
	if HelperCavebot then HelperCavebot.toggle() end
end

function cavebotOpenSettings() if HelperCavebot then HelperCavebot.openSettings() end end
function cavebotCloseSettings() if HelperCavebot then HelperCavebot.closeSettings() end end
function cavebotSettingsTab(name) if HelperCavebot then HelperCavebot.settingsTab(name) end end
function cavebotApplySettings(closeAfter) if HelperCavebot then HelperCavebot.applySettings(closeAfter) end end
function cavebotOpenSupplies() if HelperCavebot then HelperCavebot.openSupplies() end end
function cavebotCloseSupplies() if HelperCavebot then HelperCavebot.closeSupplies() end end

function cavebotSetWaypointMode(mode)
	if HelperCavebot then HelperCavebot.setWaypointMode(mode) end
end

function cavebotSetOption(name, checked)
	if HelperCavebot then HelperCavebot.setOption(name, checked == true) end
end

function cavebotSetNumericOption(name, value)
	if HelperCavebot then HelperCavebot.setNumericOption(name, value) end
end

function cavebotShowInfo(message)
	if HelperCavebot then HelperCavebot.showInfo(message) end
end

function cavebotOpenScriptsWindow()
	if HelperCavebot then HelperCavebot.openScriptsWindow() end
end

function cavebotCloseScriptsWindow()
	if HelperCavebot then HelperCavebot.closeScriptsWindow() end
end

function cavebotRemoveSelected()
	if HelperCavebot then HelperCavebot.removeSelected() end
end

function cavebotMoveSelected(delta)
	if HelperCavebot then HelperCavebot.moveSelected(tonumber(delta) or 0) end
end

function cavebotClear()
	if HelperCavebot then HelperCavebot.clear() end
end

function onCavebotEnableChange(checked)
	if HelperCavebot then HelperCavebot.onEnableChange(checked == true) end
end

function onCavebotLoopChange(checked)
	if HelperCavebot then HelperCavebot.onLoopChange(checked == true) end
end

function cavebotSaveScript()
	if HelperCavebot then HelperCavebot.saveScript() end
end

function cavebotLoadScript()
	if HelperCavebot then HelperCavebot.loadScript() end
end

function cavebotDeleteScript()
	if HelperCavebot then HelperCavebot.deleteScript() end
end

function onCavebotRecordingChange(checked)
	if HelperCavebot then HelperCavebot.onRecordingChange(checked == true) end
end

function onEnableTargetChange(self, checked)
	if loadingConfig then
		return
	end

	local mod = modulesByTab.target

	if mod and mod.onEnableTargetCheckChange then
		mod.onEnableTargetCheckChange(self)
	elseif mod and mod.toggleAutoTarget then
		mod.toggleAutoTarget(self, true)
	else
		autoSave()
	end

	refreshHelperStatsWindow()
end

function onEnableShooterChange(self, checked)
	if loadingConfig then
		return
	end

	local mod = modulesByTab.shooter

	if mod and mod.toggleMagicShooter then
		mod.toggleMagicShooter(self, nil, true)
	else
		autoSave()
	end

	refreshHelperStatsWindow()
end

function openAddHealingWindow()
	local mod = modulesByTab.healer

	if mod and mod.openAddHealingWindow then
		mod.openAddHealingWindow()
	end
end

function openAddHealingSpellWindow()
	local mod = modulesByTab.healer

	if mod and mod.openAddHealingSpellWindow then
		mod.openAddHealingSpellWindow()
	end
end

function openAddHealingPotionWindow()
	local mod = modulesByTab.healer

	if mod and mod.openAddHealingPotionWindow then
		mod.openAddHealingPotionWindow()
	end
end

function openEditHealingWindow()
	local mod = modulesByTab.healer

	if mod and mod.openEditHealingWindow then
		mod.openEditHealingWindow()
	end
end

function closeAddHealingWindow()
	local mod = modulesByTab.healer

	if mod and mod.closeAddHealingWindow then
		mod.closeAddHealingWindow()
	end
end

function addHealingEntryOk()
	local mod = modulesByTab.healer

	if mod and mod.addHealingEntryOk then
		mod.addHealingEntryOk()
	end
end

function addHealingEntryApply()
	local mod = modulesByTab.healer

	if mod and mod.addHealingEntryApply then
		mod.addHealingEntryApply()
	end
end

function addHealingEntryConfirm()
	addHealingEntryOk()
end

function onHealingRemoveClick()
	local mod = modulesByTab.healer

	if mod and mod.removeSelectedEntry then
		mod.removeSelectedEntry()
	end
end

function onAddHealingThresholdChange(edit)
	local mod = modulesByTab.healer

	if mod and mod.onAddHealingThresholdChange then
		mod.onAddHealingThresholdChange(edit)
	end
end

function onAddHealingThresholdFocusChange(edit, focused)
	local mod = modulesByTab.healer

	if mod and mod.onAddHealingThresholdFocusChange then
		mod.onAddHealingThresholdFocusChange(edit, focused)
	end
end

function onEnableHealingChange(self, on)
	local mod = modulesByTab.healer

	if mod and mod.onEnableHealingChange then
		mod.onEnableHealingChange(self, on)
	else
		saveConfig()
	end

	refreshHelperStatsWindow()
end

function onEnableHealFriendChange(self, on)
	local mod = modulesByTab.healFriend

	if mod and mod.onEnableHealFriendChange then
		mod.onEnableHealFriendChange(self, on)
	else
		saveConfig()
	end

	refreshHelperStatsWindow()
end

function onHealFriendClassToggle(self, on)
	local mod = modulesByTab.healFriend

	if mod and mod.onHealFriendClassToggle then
		mod.onHealFriendClassToggle(self, on)
	else
		saveConfig()
	end
end

function onHealFriendThresholdChange(edit)
	local mod = modulesByTab.healFriend

	if mod and mod.onThresholdChange then
		mod.onThresholdChange(edit)
	else
		autoSave()
	end
end

function onHealFriendThresholdFocusChange(edit, focused)
	local mod = modulesByTab.healFriend

	if mod and mod.onThresholdFocusChange then
		mod.onThresholdFocusChange(edit, focused)
	end
end

function setupHealFriendPriorityStepper(stepper, valueId, defaultValue)
	local mod = modulesByTab.healFriend

	if mod and mod.setupPriorityStepper then
		mod.setupPriorityStepper(stepper, valueId, defaultValue)
	end
end

function refreshHealFriendPriorityStepper(stepper)
	local mod = modulesByTab.healFriend

	if mod and mod.refreshPriorityStepper then
		mod.refreshPriorityStepper(stepper)
	end
end

function onHealFriendPriorityClick(widget, action)
	local mod = modulesByTab.healFriend

	if mod and mod.onPriorityClick then
		mod.onPriorityClick(widget, action)
	end
end

function openHealFriendPlayersWindow()
	local mod = modulesByTab.healFriend

	if mod and mod.openPlayerListWindow then
		mod.openPlayerListWindow()
	end
end

function closeHealFriendPlayersWindow()
	local mod = modulesByTab.healFriend

	if mod and mod.closePlayerListWindow then
		mod.closePlayerListWindow()
	end
end

function addHealFriendTypedPlayer()
	local mod = modulesByTab.healFriend

	if mod and mod.addTypedPlayer then
		mod.addTypedPlayer()
	end
end

function addHealFriendVisiblePlayer()
	local mod = modulesByTab.healFriend

	if mod and mod.addVisiblePlayer then
		mod.addVisiblePlayer()
	end
end

function removeHealFriendConfiguredPlayer()
	local mod = modulesByTab.healFriend

	if mod and mod.removeConfiguredPlayer then
		mod.removeConfiguredPlayer()
	end
end

function refreshHealFriendVisiblePlayers()
	local mod = modulesByTab.healFriend

	if mod and mod.refreshVisiblePlayers then
		mod.refreshVisiblePlayers()
	end
end

local function actionbarSpellAssign()
	return modules.game_actionbar
end

local function helperAssignFilterText()
	local ab = actionbarSpellAssign()

	if ab and ab.getSpellAssignFilterText then
		return ab.getSpellAssignFilterText()
	end

	return ""
end

function closeHelperAssignWindow()
	if HelperTools and HelperTools.isToolsItemAssignActive and HelperTools.isToolsItemAssignActive() then
		HelperTools.closeToolsItemAssignWindow()

		return
	end

	local mod = modulesByTab.healer

	if mod and mod.isHelperItemAssignActive and mod.isHelperItemAssignActive() then
		mod.closeHelperItemAssignWindow()

		return
	end

	if mod and mod.cancelPendingHealingEntryAssign then
		mod.cancelPendingHealingEntryAssign()
	end

	closeHelperSpellAssignWindow()
end

function closeHelperSpellAssignWindow()
	local ab = actionbarSpellAssign()

	if ab and ab.closeSpellAssignWindow then
		ab.closeSpellAssignWindow()
	end
end

function helperAssignOk()
	if HelperTools and HelperTools.isToolsItemAssignActive and HelperTools.isToolsItemAssignActive() then
		HelperTools.toolsItemAssignOk()

		return
	end

	local mod = modulesByTab.healer

	if mod and mod.isHelperItemAssignActive and mod.isHelperItemAssignActive() then
		mod.helperItemAssignOk()

		return
	end

	helperSpellAssignOk()
end

function helperSpellAssignOk()
	local ab = actionbarSpellAssign()

	if ab and ab.spellAssignOk then
		ab.spellAssignOk()
	end
end

function helperAssignApply()
	local mod = modulesByTab.healer

	if mod and mod.isHelperItemAssignActive and mod.isHelperItemAssignActive() then
		return
	end

	helperSpellAssignApply()
end

function helperSpellAssignApply()
	local ab = actionbarSpellAssign()

	if ab and ab.spellAssignApply then
		ab.spellAssignApply()
	end
end

function filterHelperAssign(text)
	if HelperTools and HelperTools.isToolsItemAssignActive and HelperTools.isToolsItemAssignActive() then
		HelperTools.filterToolsItemAssignEntries(text)

		return
	end

	local mod = modulesByTab.healer

	if mod and mod.isHelperItemAssignActive and mod.isHelperItemAssignActive() then
		mod.filterHelperAssignEntries(text)

		return
	end

	filterHelperSpells(text)
end

function filterHelperSpells(text)
	local ab = actionbarSpellAssign()

	if ab and ab.filterSpells then
		ab.filterSpells(text)
	end
end

function clearHelperAssignFilter()
	if HelperTools and HelperTools.isToolsItemAssignActive and HelperTools.isToolsItemAssignActive() then
		HelperTools.clearToolsItemAssignFilter()

		return
	end

	local mod = modulesByTab.healer

	if mod and mod.isHelperItemAssignActive and mod.isHelperItemAssignActive() then
		mod.clearHelperItemAssignFilter()

		return
	end

	clearHelperSpellFilter()
end

function clearHelperSpellFilter()
	local ab = actionbarSpellAssign()

	if ab and ab.clearSpellFilter then
		ab.clearSpellFilter()
	end
end

function onHelperAssignLearntChange()
	local mod = modulesByTab.healer

	if mod and mod.isHelperItemAssignActive and mod.isHelperItemAssignActive() then
		mod.onHelperAssignLearntChange()

		return
	end

	filterHelperSpells(helperAssignFilterText())
end

function filterPotions(text)
	filterHelperAssign(text)
end

function clearPotionFilter()
	local mod = modulesByTab.healer

	if mod and mod.clearPotionFilter then
		mod.clearPotionFilter()
	end
end

function potionAssignOk()
	local mod = modulesByTab.healer

	if mod and mod.potionAssignOk then
		mod.potionAssignOk()
	end
end

function closePotionAssignWindow()
	local mod = modulesByTab.healer

	if mod and mod.closePotionAssignWindow then
		mod.closePotionAssignWindow()
	end
end

function openTargetAssignWindow()
	local mod = modulesByTab.target

	if mod and mod.openAssignWindow then
		mod.openAssignWindow()
	end
end

function openTargetEditWindow()
	local mod = modulesByTab.target

	if mod and mod.openEditAssignWindow then
		mod.openEditAssignWindow()
	end
end

function closeTargetAssignWindow()
	local mod = modulesByTab.target

	if mod and mod.closeAssignWindow then
		mod.closeAssignWindow()
	end
end

function targetAssignOk()
	local mod = modulesByTab.target

	if mod and mod.assignOk then
		mod.assignOk()
	end
end

function filterTargetMonsters(text)
	local mod = modulesByTab.target

	if mod and mod.filterMonsters then
		mod.filterMonsters(text)
	end
end

function clearTargetMonsterFilter()
	local mod = modulesByTab.target

	if mod and mod.clearMonsterFilter then
		mod.clearMonsterFilter()
	end
end

function onTargetAllCreaturesChange(self, checked)
	local mod = modulesByTab.target

	if mod and mod.onAllCreaturesChange then
		mod.onAllCreaturesChange(self, checked)
	end
end

function onTargetRemoveClick()
	local mod = modulesByTab.target

	if mod and mod.onRemoveClick then
		mod.onRemoveClick()
	end
end

function openShooterAssignWindow()
	local mod = modulesByTab.shooter

	if mod and mod.openAssignWindow then
		mod.openAssignWindow()
	end
end

function openShooterEditWindow()
	local mod = modulesByTab.shooter

	if mod and mod.openEditAssignWindow then
		mod.openEditAssignWindow()
	end
end

function closeShooterAssignWindow()
	local mod = modulesByTab.shooter

	if mod and mod.closeAssignWindow then
		mod.closeAssignWindow()
	end
end

function closeShooterEntryWindow()
	local mod = modulesByTab.shooter

	if mod and mod.closeEntryWindow then
		mod.closeEntryWindow()
	end
end

function shooterAssignOk()
	local mod = modulesByTab.shooter

	if mod and mod.assignOk then
		mod.assignOk()
	end
end

function filterShooterSpells(text)
	local mod = modulesByTab.shooter

	if mod and mod.filterSpells then
		mod.filterSpells(text)
	end
end

function clearShooterSpellFilter()
	local mod = modulesByTab.shooter

	if mod and mod.clearSpellFilter then
		mod.clearSpellFilter()
	end
end

function onShooterAssignLearntChange()
	local mod = modulesByTab.shooter

	if mod and mod.onAssignLearntChange then
		mod.onAssignLearntChange()
	end
end

function addShooterEntryOk()
	local mod = modulesByTab.shooter

	if mod and mod.addEntryOk then
		mod.addEntryOk()
	end
end

function onAddShooterHpChange(edit)
	local mod = modulesByTab.shooter

	if mod and mod.onHpTextChange then
		mod.onHpTextChange(edit)
	end
end

function onAddShooterHpFocusChange(edit, focused)
	local mod = modulesByTab.shooter

	if mod and mod.onHpFocusChange then
		mod.onHpFocusChange(edit, focused)
	end
end

function onShooterAssignModeSpells()
	local mod = modulesByTab.shooter

	if mod and mod.setAssignMode then
		mod.setAssignMode("spells")
	end
end

function onShooterAssignModeRunes()
	local mod = modulesByTab.shooter

	if mod and mod.setAssignMode then
		mod.setAssignMode("runes")
	end
end

function onShooterRemoveClick()
	local mod = modulesByTab.shooter

	if mod and mod.onRemoveClick then
		mod.onRemoveClick()
	end
end

function onShooterPriorityClick(widget, action)
	local mod = modulesByTab.shooter

	if mod and mod.onPriorityClick then
		mod.onPriorityClick(widget, action)
	end
end

function onShooterPriorityChange(edit)
	local mod = modulesByTab.shooter

	if mod and mod.onPriorityChange then
		mod.onPriorityChange(edit)
	end
end

function onToolsAutoPartyChange(self, on)
	if HelperAutoParty and HelperAutoParty.onEnableChange then
		HelperAutoParty.onEnableChange(self, on)
	end

	refreshHelperStatsWindow()
end

function onToolsAutoPartyAcceptChange(self, on)
	if HelperAutoParty and HelperAutoParty.onAcceptChange then
		HelperAutoParty.onAcceptChange(self, on)
	end

	refreshHelperStatsWindow()
end

function openAutoPartySettings()
	if HelperAutoParty and HelperAutoParty.openSettings then
		HelperAutoParty.openSettings()
	end
end

function onAutoPartySettingsTextChange()
	if HelperAutoParty and HelperAutoParty.onSettingsTextChange then
		HelperAutoParty.onSettingsTextChange()
	end
end

function focusAutoPartyTextEdit(edit)
	if HelperAutoParty and HelperAutoParty.focusTextEdit then
		HelperAutoParty.focusTextEdit(edit)
	elseif edit and edit.setCursorVisible then
		edit:setCursorVisible(true)
	end
end

function onShooterEntryCreaturesChange(combo)
	if not combo then
		return
	end

	local row = combo:getParent()

	if not row or not row.shooterEntryIndex then
		return
	end

	local text = combo:getCurrentOption()
	local creatures = type(text) == "table" and text.text or tostring(text or "1")

	creatures = creatures:match("%d+")

	if HelperShooter and HelperShooter.updateEntryCreatures then
		HelperShooter.updateEntryCreatures(row.shooterEntryIndex, creatures)
	end
end

function onShooterEntryEnabledChange(check)
	if not check then
		return
	end

	local column = check:getParent()
	local row = column and column:getParent()

	if not row or not row.shooterEntryIndex then
		return
	end

	if HelperShooter and HelperShooter.updateEntryEnabled then
		HelperShooter.updateEntryEnabled(row.shooterEntryIndex, check:isChecked())
	end
end

function onShooterMoveUpClick()
	if HelperShooter and HelperShooter.onMoveUpClick then
		HelperShooter.onMoveUpClick()
	end
end

function onShooterMoveDownClick()
	if HelperShooter and HelperShooter.onMoveDownClick then
		HelperShooter.onMoveDownClick()
	end
end

function onShooterPresetChange(combo)
	if loadingConfig then
		return
	end

	if HelperShooter and HelperShooter.toggleShooterPreset then
		HelperShooter.toggleShooterPreset(combo, false)
	end
end

function onShooterPresetMenu(combo)
	if HelperShooter and HelperShooter.openPresetMenu then
		return HelperShooter.openPresetMenu(combo)
	end

	return false
end

function onShooterPzAutoChange(_)
	if loadingConfig then
		return
	end

	if HelperShooter and HelperShooter.onShooterPzAutoChange then
		HelperShooter.onShooterPzAutoChange()
	else
		autoSave()
	end
end

function onShooterComboModeChange(_, checked)
	if loadingConfig then
		return
	end

	if HelperShooter and HelperShooter.setComboMode then
		HelperShooter.setComboMode(checked == true)
	end
end

function onShooterRenamePreset()
	if HelperShooter and HelperShooter.sendRenameOrAddWindow then
		HelperShooter.sendRenameOrAddWindow(true)
	end
end

function onShooterNewPreset()
	if HelperShooter and HelperShooter.sendRenameOrAddWindow then
		HelperShooter.sendRenameOrAddWindow(false)
	end
end

function onShooterRemovePreset()
	if HelperShooter and HelperShooter.removeProfile then
		HelperShooter.removeProfile()
	end
end

function openShooterHotkeyWindow()
	openShooterEnableHotkeyWindow()
end

function onShooterSettingChange()
	if loadingConfig then
		return
	end

	autoSave()
end

function onEnableConditionsChange(_, _)
	if loadingConfig then
		return
	end

	if HelperConditions and HelperConditions.onEnableConditionsChange then
		HelperConditions.onEnableConditionsChange()
	else
		saveConfig()
	end
end

function onToolsReconnectChange(self, on)
	if HelperTools and HelperTools.onReconnectChange then
		HelperTools.onReconnectChange(self, on)
	end

	refreshHelperStatsWindow()
end

function onToolsChangeGoldChange(self, on)
	if HelperTools and HelperTools.onChangeGoldChange then
		HelperTools.onChangeGoldChange(self, on)
	end

	refreshHelperStatsWindow()
end

function onToolsEatFoodChange(self, on)
	if HelperTools and HelperTools.onEatFoodChange then
		HelperTools.onEatFoodChange(self, on)
	end

	refreshHelperStatsWindow()
end

function onToolsAutoTrainingChange(self, on)
	if loadingConfig then
		return
	end

	if HelperTools and HelperTools.onAutoTrainingChange then
		HelperTools.onAutoTrainingChange(self, on)
	end

	refreshHelperStatsWindow()
end

function onToolsAutoAmmoChange(self, on)
	if loadingConfig then
		return
	end

	if HelperTools and HelperTools.onAutoAmmoChange then
		HelperTools.onAutoAmmoChange(self, on)
	end

	refreshHelperStatsWindow()
end

function onToolsAutoAmmoTargetChange()
	if loadingConfig then
		return
	end

	if HelperTools and HelperTools.onAutoAmmoTargetChange then
		HelperTools.onAutoAmmoTargetChange()
	end
end

function onToolsAutoSSAChange(self, on)
	if loadingConfig then
		return
	end

	if HelperTools and HelperTools.onAutoSSAChange then
		HelperTools.onAutoSSAChange(self, on)
	end
end

function onToolsAutoMightRingChange(self, on)
	if loadingConfig then
		return
	end

	if HelperTools and HelperTools.onAutoMightRingChange then
		HelperTools.onAutoMightRingChange(self, on)
	end
end
