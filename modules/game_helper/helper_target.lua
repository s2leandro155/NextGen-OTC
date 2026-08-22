-- chunkname: @/game_helper/helper_target.lua

HelperTarget = HelperTarget or {}

local ctx, targetAssignWindow, targetMonstersPanel, editingPriorityListIndex
local priorityList = {}
local monsterCache
local allCreaturesEnabled = false
local openTargetRowContextMenu, openTargetAssignWindowInternal, targetActionButtonsState
local ALL_CREATURES_ICON = "/images/icons_big/icon-arbitrarymonster64x64"
local spectators = {}
local spectatorMeta = {}
local spectatorAgeCounter = 0
local combatTimer = 0
local COMBAT_TICK_MS = 150
local TARGET_INTERVAL_MS = 250
local autoTargetOnHold = false
local currentLockedTargetId = 0
local lastTargetAttackId = 0
local lastTargetAttackAt = 0
local suppressTargetCheckChange = false
local suppressTargetSettingsChange = false
local TARGET_SWITCH_DELAY_MS = 700
local TARGET_MODE_STAND = "stand"
local TARGET_MODE_CHASE = "chase"
local targetAttackMode = TARGET_MODE_STAND
local TARGET_OPERATING_MODE_DEFAULT = "F"
local TARGET_OPERATING_MODES = {
	"A",
	"B",
	"C",
	"D",
	"E",
	"F",
	"G",
	"H",
	"I"
}
local targetOperatingMode = TARGET_OPERATING_MODE_DEFAULT
local TARGET_PZ_AUTO_ENABLED = "enabled"
local TARGET_PZ_AUTO_DISABLED = "disabled"
local targetPzAuto = TARGET_PZ_AUTO_ENABLED
local targetEnabledBeforePz = false
local wasInProtectionZone = false
local boundAutoTargetHotkey
local targetUiLanguage = "en"
local TARGET_TEXT = {
	en = {
		mode = "Mode:",
		targetListHelp = "The order of entries in the list is the primary targeting priority. Entries at the top are preferred first.<br><br><li>Right-click an entry to change its order.</li><li>Uncheck an entry to temporarily disable it without removing it.</li>",
		targetSettings = "Target Settings",
		pzBlocked = "Target cannot be enabled inside a protection zone.",
		targetList = "Target List",
		disabled = "Disabled",
		allCreatures = "All Creatures",
		moveDown = "Move Down",
		chase = "Chase",
		moveUp = "Move Up",
		stand = "Stand",
		remove = "Remove",
		name = "Name",
		creature = "Creature",
		edit = "Edit",
		add = "Add",
		enableTarget = "Enable Target",
		pzAuto = "PZ Auto:",
		enabled = "Enabled",
		priority = "Priority:",
		distance = "Distance:",
		targetSettingsHelp = "Settings applied when auto-targeting is enabled:<br><li>Mode: Stand attacks in place; Chase follows the target.</li><li>Distance: maximum distance in tiles for a creature to be targeted.</li><li>Priority: selects the operating mode used among creatures with the same list priority.</li><li>PZ Auto enabled: pauses auto-target inside a protection zone and restores it after leaving.</li><li>PZ Auto disabled: turns auto-target off in a protection zone. It stays off after leaving and cannot be enabled while you are inside.</li>",
		operatingModes = {
			G = "Closest, then Highest Health",
			E = "Best Grouped Target (AOE/Runes)",
			D = "Highest Health",
			C = "Lowest Health",
			B = "Farthest Monster",
			A = "Closest Monster",
			F = "Closest, then Lowest Health",
			I = "Farthest, then Highest Health",
			H = "Farthest, then Lowest Health"
		},
		operatingModeOptions = {
			G = "Closest + Highest Life",
			E = "Best Grouped (AOE)",
			D = "Highest Life",
			C = "Lowest Life",
			B = "Farthest",
			A = "Closest",
			F = "Closest + Lowest Life",
			I = "Farthest + Highest Life",
			H = "Farthest + Lowest Life"
		}
	},
	pt = {
		mode = "Modo:",
		targetListHelp = "A ordem da lista e a prioridade principal do Target. As entradas do topo sao escolhidas primeiro.<br><br><li>Clique com o botao direito para mudar a ordem.</li><li>Desmarque uma entrada para desativa-la sem remove-la.</li>",
		targetSettings = "Configuracoes do Target",
		pzBlocked = "O Target nao pode ser ativado dentro de uma protection zone.",
		targetList = "Lista de Alvos",
		disabled = "Desativado",
		allCreatures = "Todas as Criaturas",
		moveDown = "Mover para Baixo",
		chase = "Perseguir",
		moveUp = "Mover para Cima",
		stand = "Parado",
		remove = "Remover",
		name = "Nome",
		creature = "Criatura",
		edit = "Editar",
		add = "Adicionar",
		enableTarget = "Ativar Target",
		pzAuto = "PZ Auto:",
		enabled = "Ativado",
		priority = "Prioridade:",
		distance = "Distancia:",
		targetSettingsHelp = "Configuracoes usadas pelo auto-target:<br><li>Modo: Parado ataca no lugar; Perseguir segue o alvo.</li><li>Distancia: distancia maxima em tiles para selecionar uma criatura.</li><li>Prioridade: escolhe o modo operante entre criaturas com a mesma prioridade na lista.</li><li>PZ Auto ativado: pausa o auto-target dentro de uma protection zone e restaura ao sair.</li><li>PZ Auto desativado: desliga o auto-target dentro de uma protection zone. Ele permanece desligado ao sair e nao pode ser ativado enquanto voce estiver nela.</li>",
		operatingModes = {
			G = "Mais Proximo, depois Maior Vida",
			E = "Melhor Alvo Agrupado (AOE/Runas)",
			D = "Maior Vida",
			C = "Menor Vida",
			B = "Monstro Mais Distante",
			A = "Monstro Mais Proximo",
			F = "Mais Proximo, depois Menor Vida",
			I = "Mais Distante, depois Maior Vida",
			H = "Mais Distante, depois Menor Vida"
		},
		operatingModeOptions = {
			G = "Proximo + Maior Vida",
			E = "Melhor Grupo (AOE)",
			D = "Maior Vida",
			C = "Menor Vida",
			B = "Mais Distante",
			A = "Mais Proximo",
			F = "Proximo + Menor Vida",
			I = "Distante + Maior Vida",
			H = "Distante + Menor Vida"
		}
	}
}
local familiarNames = {
	["knight familiar"] = true,
	["druid familiar"] = true,
	["sorcerer familiar"] = true,
	["paladin familiar"] = true,
	["monk familiar"] = true
}
local ZEBRA_COLOR_A = "#484848"
local ZEBRA_COLOR_B = "#414141"

local function widget(id)
	return ctx and ctx.getWidget(id)
end

local function normalizeTargetLanguage(language)
	return language == "pt" and "pt" or "en"
end

local function targetText(key)
	local selected = TARGET_TEXT[targetUiLanguage] or TARGET_TEXT.en

	return selected[key] or TARGET_TEXT.en[key] or key
end

local function operatingModeText(mode)
	local selected = TARGET_TEXT[targetUiLanguage] or TARGET_TEXT.en

	return selected.operatingModes and selected.operatingModes[mode] or TARGET_TEXT.en.operatingModes[mode] or mode
end

local function operatingModeOptionText(mode)
	local selected = TARGET_TEXT[targetUiLanguage] or TARGET_TEXT.en

	return selected.operatingModeOptions and selected.operatingModeOptions[mode] or TARGET_TEXT.en.operatingModeOptions[mode] or operatingModeText(mode)
end

local function nowMs()
	if g_clock and g_clock.millis then
		return g_clock.millis()
	end

	return math.floor((os.clock() or 0) * 1000)
end

local function saveConfigIfReady()
	if ctx and ctx.isLoadingConfig and ctx.isLoadingConfig() then
		return
	end

	if ctx and ctx.saveConfig then
		ctx.saveConfig()
	end
end

local function normalizeRaceId(raceId)
	if raceId == nil then
		return nil
	end

	return tonumber(raceId)
end

local function getDistanceBetween(p1, p2)
	if not p1 or not p2 or p1.x == nil or p2.x == nil then
		return 99
	end

	return math.max(math.abs(p1.x - p2.x), math.abs(p1.y - p2.y))
end

local function isMapCreature(creature)
	if not creature then
		return false
	end

	local creatureType = type(creature)

	if creatureType ~= "userdata" and creatureType ~= "table" then
		return false
	end

	return type(creature.isDead) == "function" and type(creature.getPosition) == "function"
end

local function isFamiliar(creature)
	if not creature then
		return false
	end

	local name = creature:getName()

	if not name then
		return false
	end

	return familiarNames[name:lower()] == true
end

local function isCavebotIgnored(creature)
	return HelperCavebot and HelperCavebot.isCreatureIgnored and HelperCavebot.isCreatureIgnored(creature) or false
end

local function refreshVisibleSpectators(position)
	if not position then
		return
	end

	for _, creature in ipairs(g_map.getSpectators(position, false) or {}) do
		if creature and creature.isMonster and creature:isMonster() and not creature:isDead() and not isFamiliar(creature) and not isCavebotIgnored(creature) then
			local creatureId = creature:getId()

			if not spectators[creatureId] then
				spectatorAgeCounter = spectatorAgeCounter + 1
				spectatorMeta[creatureId] = { age = spectatorAgeCounter }
			end

			spectators[creatureId] = creature
		end
	end
end

local function isWithinReach(playerPos, targetPos)
	if not playerPos or not targetPos or playerPos.x == nil or targetPos.x == nil then
		return false
	end

	local deltaX = math.abs(playerPos.x - targetPos.x)
	local deltaY = math.abs(playerPos.y - targetPos.y)

	return deltaX <= 7 and deltaY <= 5 and playerPos.z == targetPos.z
end

local function readDistanceRange()
	if ctx and ctx.readDistanceValue then
		return 0, ctx.readDistanceValue("targetDistanceCombo")
	end

	return 0, 7
end

local function normalizeTargetMode(mode)
	if type(mode) == "string" then
		local value = mode:lower()

		if value == TARGET_MODE_CHASE or value == "perseguir" then
			return TARGET_MODE_CHASE
		end
	end

	return TARGET_MODE_STAND
end

local function readComboOptionValue(combo, fallback)
	if not combo or not combo.getCurrentOption then
		return fallback
	end

	local current = combo:getCurrentOption()

	if type(current) == "table" then
		return current.data or current.text or fallback
	end

	return current or fallback
end

local function readTargetModeWidget()
	local combo = widget("targetModeCombo")

	if not combo or not combo.getCurrentOption then
		return targetAttackMode
	end

	return normalizeTargetMode(readComboOptionValue(combo, targetAttackMode))
end

local function applyTargetModeWidget(mode)
	local combo = widget("targetModeCombo")

	if not combo or not combo.setCurrentOption then
		return
	end

	mode = normalizeTargetMode(mode)

	if combo.setCurrentOptionByData then
		combo:setCurrentOptionByData(mode, true)
	else
		combo:setCurrentOption(mode == TARGET_MODE_CHASE and targetText("chase") or targetText("stand"), true)
	end
end

local function normalizeTargetOperatingMode(mode)
	local value = tostring(mode or TARGET_OPERATING_MODE_DEFAULT):upper()

	if not value:match("^[A-I]$") then
		return TARGET_OPERATING_MODE_DEFAULT
	end

	return value
end

local function compactLegacyValue(value)
	return tostring(value or ""):lower():gsub("%s+", "")
end

local function operatingModeFromLegacyConfig(data)
	if type(data) ~= "table" then
		return TARGET_OPERATING_MODE_DEFAULT
	end

	if data.priorityOrder == nil and data.prioritySort == nil and data.prioritySecondary == nil then
		return TARGET_OPERATING_MODE_DEFAULT
	end

	local order = compactLegacyValue(data.priorityOrder)
	local sortBy = compactLegacyValue(data.prioritySort)
	local secondary = compactLegacyValue(data.prioritySecondary)

	if order == "besttarget" or sortBy == "besttarget" or sortBy == "displaytime" then
		return "E"
	end

	local ascending = order == "ascending"

	if sortBy == "distance" then
		if secondary == "lowhealth" then
			return ascending and "F" or "H"
		end

		if secondary == "highhealth" then
			return ascending and "G" or "I"
		end

		return ascending and "A" or "B"
	end

	return ascending and "C" or "D"
end

local function readTargetOperatingModeWidget()
	return normalizeTargetOperatingMode(readComboOptionValue(widget("targetOperatingModeCombo"), targetOperatingMode))
end

local function applyTargetOperatingModeWidget(mode)
	local combo = widget("targetOperatingModeCombo")

	if not combo or not combo.setCurrentOption then
		return
	end

	mode = normalizeTargetOperatingMode(mode)

	if combo.setCurrentOptionByData then
		combo:setCurrentOptionByData(mode, true)
	else
		combo:setCurrentOption(operatingModeOptionText(mode), true)
	end

	if combo.setTooltip then
		combo:setTooltip(operatingModeText(mode))
	end
end

local function normalizeTargetPzAuto(value)
	if type(value) == "string" then
		local normalized = value:lower()

		if normalized == TARGET_PZ_AUTO_DISABLED or normalized == "desativado" then
			return TARGET_PZ_AUTO_DISABLED
		end
	end

	return TARGET_PZ_AUTO_ENABLED
end

local function isTargetPzAutoEnabled()
	return normalizeTargetPzAuto(targetPzAuto) == TARGET_PZ_AUTO_ENABLED
end

local function readTargetPzAutoWidget()
	return normalizeTargetPzAuto(readComboOptionValue(widget("targetPzAutoCombo"), targetPzAuto))
end

local function applyTargetPzAutoWidget(value)
	local combo = widget("targetPzAutoCombo")

	if not combo or not combo.setCurrentOption then
		return
	end

	value = normalizeTargetPzAuto(value)

	if combo.setCurrentOptionByData then
		combo:setCurrentOptionByData(value, true)
	else
		combo:setCurrentOption(value == TARGET_PZ_AUTO_ENABLED and targetText("enabled") or targetText("disabled"), true)
	end
end

local function rebuildTargetSettingOptions()
	suppressTargetSettingsChange = true

	local modeCombo = widget("targetModeCombo")

	if modeCombo and modeCombo.clearOptions and modeCombo.addOption then
		modeCombo:clearOptions()
		modeCombo:addOption(targetText("stand"), TARGET_MODE_STAND)
		modeCombo:addOption(targetText("chase"), TARGET_MODE_CHASE)
		applyTargetModeWidget(targetAttackMode)
	end

	local operatingCombo = widget("targetOperatingModeCombo")

	if operatingCombo and operatingCombo.clearOptions and operatingCombo.addOption then
		operatingCombo:clearOptions()

		for _, mode in ipairs(TARGET_OPERATING_MODES) do
			operatingCombo:addOption(operatingModeOptionText(mode), mode)
		end

		applyTargetOperatingModeWidget(targetOperatingMode)
	end

	local pzCombo = widget("targetPzAutoCombo")

	if pzCombo and pzCombo.clearOptions and pzCombo.addOption then
		pzCombo:clearOptions()
		pzCombo:addOption(targetText("enabled"), TARGET_PZ_AUTO_ENABLED)
		pzCombo:addOption(targetText("disabled"), TARGET_PZ_AUTO_DISABLED)
		applyTargetPzAutoWidget(targetPzAuto)
	end

	suppressTargetSettingsChange = false
end

local countAttackableCreatures

local function getGroupedTargetCount(creature, areaCreatureList)
	if not creature then
		return 0
	end

	local area = SpellAreas and SpellAreas.AREA_CIRCLE2X2
	local creaturePos = creature:getPosition()

	if not area or not creaturePos then
		return 0
	end

	return countAttackableCreatures(creaturePos, Directions.North, area, areaCreatureList or {}, true)
end

local function isStableOperatingCandidateBetter(candidate, best)
	if not best or not best.id then
		return true
	end

	if candidate.distance ~= best.distance then
		return candidate.distance < best.distance
	end

	if candidate.health ~= best.health then
		return candidate.health < best.health
	end

	return candidate.creatureId < best.creatureId
end

local function isOperatingCandidateBetter(candidate, best, mode)
	if not best or not best.id then
		return true
	end

	mode = normalizeTargetOperatingMode(mode)

	if mode == "A" then
		if candidate.distance ~= best.distance then
			return candidate.distance < best.distance
		end
	elseif mode == "B" then
		if candidate.distance ~= best.distance then
			return candidate.distance > best.distance
		end
	elseif mode == "C" then
		if candidate.health ~= best.health then
			return candidate.health < best.health
		end
	elseif mode == "D" then
		if candidate.health ~= best.health then
			return candidate.health > best.health
		end
	elseif mode == "E" then
		if candidate.areaCount ~= best.areaCount then
			return candidate.areaCount > best.areaCount
		end
	elseif mode == "F" then
		if candidate.distance ~= best.distance then
			return candidate.distance < best.distance
		end

		if candidate.health ~= best.health then
			return candidate.health < best.health
		end
	elseif mode == "G" then
		if candidate.distance ~= best.distance then
			return candidate.distance < best.distance
		end

		if candidate.health ~= best.health then
			return candidate.health > best.health
		end
	elseif mode == "H" then
		if candidate.distance ~= best.distance then
			return candidate.distance > best.distance
		end

		if candidate.health ~= best.health then
			return candidate.health < best.health
		end
	elseif mode == "I" then
		if candidate.distance ~= best.distance then
			return candidate.distance > best.distance
		end

		if candidate.health ~= best.health then
			return candidate.health > best.health
		end
	end

	return isStableOperatingCandidateBetter(candidate, best)
end

local applyTargetAttackMode

local function isWithinDistance(playerPos, targetPos, minDist, maxDist)
	if not isWithinReach(playerPos, targetPos) then
		return false
	end

	local dist = getDistanceBetween(playerPos, targetPos)

	minDist = tonumber(minDist) or 1
	maxDist = tonumber(maxDist) or 7

	return minDist <= dist and dist <= maxDist
end

local function rotateArea(area, direction)
	if type(area) ~= "table" or not area[1] then
		return {}
	end

	local rotatedArea = {}
	local rows = #area
	local cols = #area[1]

	if direction == Directions.North then
		return area
	elseif direction == Directions.South then
		for y = 1, rows do
			rotatedArea[y] = {}

			for x = 1, cols do
				rotatedArea[y][x] = area[rows - y + 1][cols - x + 1]
			end
		end
	elseif direction == Directions.East then
		for x = 1, cols do
			rotatedArea[x] = {}

			for y = 1, rows do
				rotatedArea[x][y] = area[rows - y + 1][x]
			end
		end
	elseif direction == Directions.West then
		for x = 1, cols do
			rotatedArea[x] = {}

			for y = 1, rows do
				rotatedArea[x][y] = area[y][cols - x + 1]
			end
		end
	else
		return area
	end

	return rotatedArea
end

local function findPlayerPosition(area)
	for y, row in ipairs(area) do
		for x, value in ipairs(row) do
			if value == 3 or value == 2 then
				return x, y
			end
		end
	end

	return nil, nil
end

local function getAttackAreaOffsets(area, direction, ranged, creatureList)
	local cache = type(creatureList) == "table" and creatureList.areaOffsetCache or nil

	if not cache and type(creatureList) == "table" then
		cache = {}
		creatureList.areaOffsetCache = cache
	end

	local areaCache = cache and cache[area] or nil

	if not areaCache and cache then
		areaCache = {}
		cache[area] = areaCache
	end

	local cacheKey = tostring(direction) .. (ranged and ":1" or ":0")

	if areaCache and areaCache[cacheKey] then
		return areaCache[cacheKey]
	end

	local rotated = rotateArea(area, direction)
	local playerX, playerY = findPlayerPosition(rotated)

	if not playerX or not playerY then
		return nil
	end

	local offsets = {}

	for yOffset, row in ipairs(rotated) do
		for xOffset, value in ipairs(row) do
			if value == 1 or ranged and (value == 3 or value == 2) then
				table.insert(offsets, {
					x = xOffset - playerX,
					y = yOffset - playerY
				})
			end
		end
	end

	if areaCache then
		areaCache[cacheKey] = offsets
	end

	return offsets
end

function countAttackableCreatures(casterPos, direction, area, creatureList, ranged)
	if type(area) ~= "table" then
		return 0
	end

	if direction == Directions.SouthEast or direction == Directions.NorthEast then
		direction = Directions.East
	elseif direction == Directions.SouthWest or direction == Directions.NorthWest then
		direction = Directions.West
	end

	local offsets = getAttackAreaOffsets(area, direction, ranged, creatureList)

	if not offsets then
		return 0
	end

	local creatures = 0
	local positionIndex = type(creatureList) == "table" and creatureList.positionIndex or nil

	for _, offset in ipairs(offsets) do
		local x = casterPos.x + offset.x
		local y = casterPos.y + offset.y

		if positionIndex then
			local column = positionIndex[x]
			local occupants = column and column[y] or nil

			if occupants then
				for _, creature in ipairs(occupants) do
					local creaturePos = creature.position

					if creaturePos and creaturePos.x == x and creaturePos.y == y and creaturePos.z == casterPos.z and g_map.isSightClear(casterPos, creaturePos) then
						creatures = creatures + 1

						break
					end
				end
			end
		else
			for _, creature in ipairs(creatureList) do
				local creaturePos = type(creature) == "table" and creature.position or nil

				if creaturePos and creaturePos.x == x and creaturePos.y == y and creaturePos.z == casterPos.z and g_map.isSightClear(casterPos, creaturePos) then
					creatures = creatures + 1

					break
				end
			end
		end
	end

	return creatures
end

local function addAreaCreature(creatureList, positionIndex, creature, creaturePos)
	local entry = {
		position = creaturePos,
		creature = creature
	}

	table.insert(creatureList, entry)

	local column = positionIndex[creaturePos.x]

	if not column then
		column = {}
		positionIndex[creaturePos.x] = column
	end

	local occupants = column[creaturePos.y]

	if not occupants then
		occupants = {}
		column[creaturePos.y] = occupants
	end

	table.insert(occupants, entry)
end

local function buildBestTargetAreaCreatureList(position)
	local creatureList = {}
	local positionIndex = {}

	for _, creature in pairs(spectators) do
		if isMapCreature(creature) and not creature:isDead() and creature.isMonster and creature:isMonster() and not isFamiliar(creature) and not isCavebotIgnored(creature) then
			local creaturePos = creature:getPosition()

			if creaturePos and creaturePos.z == position.z then
				addAreaCreature(creatureList, positionIndex, creature, creaturePos)
			end
		end
	end

	creatureList.positionIndex = positionIndex

	return creatureList
end

local function createAllCreaturesEntry(enabled)
	return {
		allCreatures = true,
		enabled = enabled ~= false
	}
end

local function ensureAllCreaturesEntry()
	local existingIndex

	for i = #priorityList, 1, -1 do
		if priorityList[i].allCreatures then
			if existingIndex then
				table.remove(priorityList, i)
			else
				existingIndex = i
			end
		end
	end

	if not existingIndex then
		table.insert(priorityList, 1, createAllCreaturesEntry(allCreaturesEnabled))

		existingIndex = 1
	end

	allCreaturesEnabled = priorityList[existingIndex].enabled ~= false

	return existingIndex
end

local function movePriorityEntryAt(index, delta)
	local newIndex = index + delta

	if newIndex < 1 or newIndex > #priorityList then
		return nil
	end

	local entry = table.remove(priorityList, index)

	table.insert(priorityList, newIndex, entry)

	return newIndex
end

local function removePriorityEntryAt(index)
	local entry = priorityList[index]

	if not entry or entry.allCreatures then
		return false
	end

	table.remove(priorityList, index)

	return true
end

local function focusTargetRowByIndex(index)
	local list = widget("targetPriorityList")

	if not list or list:isDestroyed() then
		return
	end

	for _, row in ipairs(list:getChildren()) do
		if row.priorityListIndex == index then
			list:focusChild(row, KeyboardFocusReason)

			break
		end
	end
end

local function getPriorityRaceOrder()
	local order = {}

	for idx, entry in ipairs(priorityList) do
		local raceId = normalizeRaceId(entry.raceId)

		if raceId and entry.enabled ~= false then
			order[raceId] = idx
		end
	end

	return order
end

local monsterNameToRaceId

local function buildMonsterCache()
	local all = g_things.getMonsterList() or {}
	local filtered = {}

	for _, monster in ipairs(all) do
		if type(monster) == "table" and not monster.boss then
			table.insert(filtered, monster)
		end
	end

	table.sort(filtered, function(a, b)
		return (a.name or ""):lower() < (b.name or ""):lower()
	end)

	monsterCache = filtered
	monsterNameToRaceId = nil
end

local function getMonstersSorted()
	if not monsterCache then
		buildMonsterCache()
	end

	return monsterCache
end

local function rebuildMonsterNameIndex()
	local monsters = getMonstersSorted()
	local index = {}

	for _, race in ipairs(monsters) do
		if type(race) == "table" and race.name and race.raceId then
			index[race.name:lower()] = race.raceId
		end
	end

	monsterNameToRaceId = index
end

local function getCreatureRaceId(creature)
	if not creature then
		return nil
	end

	if creature.getRaceId then
		return creature:getRaceId()
	end

	local name = creature:getName()

	if not name or name == "" then
		return nil
	end

	if not monsterNameToRaceId then
		rebuildMonsterNameIndex()
	end

	return monsterNameToRaceId[name:lower()]
end

local function creatureMatchesPriority(creature, allCreatures)
	if allCreatures then
		return true
	end

	local order = getPriorityRaceOrder()

	if not next(order) then
		return false
	end

	local raceId = normalizeRaceId(getCreatureRaceId(creature))

	if not raceId then
		return false
	end

	return order[raceId] ~= nil
end

local function getPriorityRank(creature)
	local raceId = normalizeRaceId(getCreatureRaceId(creature))

	if not raceId then
		return 9999
	end

	return getPriorityRaceOrder()[raceId] or 9999
end

local function isLockedTargetValid(creature, position, minDist, maxDist, allCreatures)
	if not creature or creature:isDead() then
		return false
	end

	if not creature.isMonster or not creature:isMonster() then
		return false
	end

	if isFamiliar(creature) then
		return false
	end

	if isCavebotIgnored(creature) then
		return false
	end

	if not creatureMatchesPriority(creature, allCreatures) then
		return false
	end

	local creaturePos = creature:getPosition()

	if not creaturePos or creaturePos.z ~= position.z then
		return false
	end

	local keepMaxDist = (tonumber(maxDist) or 7) + 2

	if not isWithinDistance(position, creaturePos, 0, keepMaxDist) then
		return false
	end

	return true
end

local function isHelperEnabled()
	local main = widget("checkbox")

	return main and main:isChecked() or false
end

local function syncCombatSchedulerState()
	local helper = modules.game_helper

	if helper and helper.syncCombatSchedulerState then
		helper.syncCombatSchedulerState()
	end
end

local function isAutoTargetEnabled()
	if not isHelperEnabled() then
		return false
	end

	local check = widget("enableTargetCheckBox")

	return check and check:isChecked() or false
end

function applyTargetAttackMode()
	if not isAutoTargetEnabled() or autoTargetOnHold then
		return
	end

	if not g_game.getAttackingCreature() then
		return
	end

	local desiredChase = targetAttackMode == TARGET_MODE_CHASE and ChaseOpponent or DontChase

	if g_game.getChaseMode() == desiredChase then
		return
	end

	if modules.game_inventory and modules.game_inventory.selectPosture then
		modules.game_inventory.selectPosture(targetAttackMode == TARGET_MODE_CHASE and "follow" or "stand")
	else
		g_game.setChaseMode(desiredChase)
	end
end

local function showMessage(text)
	if modules.game_textmessage and modules.game_textmessage.displayGameMessage then
		modules.game_textmessage.displayGameMessage(text)
	end
end

local function showFailure(text)
	if modules.game_textmessage and modules.game_textmessage.displayFailureMessage then
		modules.game_textmessage.displayFailureMessage(text)
	end
end

local function isTargetBlockedByProtectionZone()
	local player = g_game.getLocalPlayer()

	return not isTargetPzAutoEnabled() and player and player.isInProtectionZone and player:isInProtectionZone() or false
end

local function setTargetCheckEnabled(enabled)
	local check = widget("enableTargetCheckBox")

	if check and check.setEnabled then
		check:setEnabled(enabled == true)
	end

	local label = widget("enableTargetLabel")

	if label and label.setColor then
		label:setColor(enabled == true and "#c0c0c0" or "#707070")
	end
end

local function blockTargetEnableInProtectionZone(silent)
	if not isTargetBlockedByProtectionZone() then
		return false
	end

	local check = widget("enableTargetCheckBox")

	if check and check:isChecked() then
		suppressTargetCheckChange = true

		check:setChecked(false)

		suppressTargetCheckChange = false
	end

	setTargetCheckEnabled(false)

	targetEnabledBeforePz = false

	if currentLockedTargetId > 0 then
		currentLockedTargetId = 0

		g_game.cancelAttack()
	end

	if not silent then
		showFailure(targetText("pzBlocked"))
	end

	return true
end

function HelperTarget.isFamiliar(creature)
	return isFamiliar(creature)
end

function HelperTarget.getSpectators()
	return spectators
end

function HelperTarget.isWithinDistance(playerPos, targetPos, minDist, maxDist)
	return isWithinDistance(playerPos, targetPos, minDist, maxDist)
end

function HelperTarget.isWithinReach(playerPos, targetPos)
	return isWithinReach(playerPos, targetPos)
end

function HelperTarget.getDistanceBetween(p1, p2)
	return getDistanceBetween(p1, p2)
end

function HelperTarget.countAttackableCreatures(casterPos, direction, area, creatureList, ranged)
	return countAttackableCreatures(casterPos, direction, area, creatureList, ranged)
end

function HelperTarget.isAutoTargetActive()
	return isAutoTargetEnabled()
end

function HelperTarget.setAutoTargetOnHold(value)
	autoTargetOnHold = value == true
end

function HelperTarget.onHelperDisabled()
	if currentLockedTargetId > 0 then
		currentLockedTargetId = 0

		g_game.cancelAttack()
	end
end

function HelperTarget.onCreatureAppear(creature)
	if not creature or creature:isPlayer() then
		return
	end

	if creature:getHealthPercent() <= 0 then
		return
	end

	if isFamiliar(creature) then
		return
	end

	if creature:isMonster() and not spectators[creature:getId()] then
		spectatorAgeCounter = spectatorAgeCounter + 1
		spectatorMeta[creature:getId()] = {
			age = spectatorAgeCounter
		}
		spectators[creature:getId()] = creature
	end
end

function HelperTarget.onCreatureDisappear(creature)
	if not creature then
		return
	end

	local creatureId = creature:getId()

	if spectators[creatureId] then
		spectators[creatureId] = nil
	end

	spectatorMeta[creatureId] = nil

	if creature:getId() == currentLockedTargetId then
		currentLockedTargetId = 0
	end
end

function HelperTarget.onAttackingCreatureChange(creature, _oldCreature)
	if not isAutoTargetEnabled() or autoTargetOnHold then
		return
	end

	if creature then
		currentLockedTargetId = creature:getId()
	else
		currentLockedTargetId = 0
	end
end

function HelperTarget.clearSpectators()
	spectators = {}
	spectatorMeta = {}
	spectatorAgeCounter = 0
end

local function updateProtectionZoneAutoTarget()
	local myCharacter = g_game.getLocalPlayer()

	if not myCharacter then
		return
	end

	local inPz = myCharacter:isInProtectionZone()
	local shouldTurnOffInPz = not isTargetPzAutoEnabled()

	if shouldTurnOffInPz then
		local wasPaused = targetEnabledBeforePz == true

		targetEnabledBeforePz = false

		if inPz then
			local autoTarget = widget("enableTargetCheckBox")
			local changed = wasPaused or autoTarget and autoTarget:isChecked()

			blockTargetEnableInProtectionZone(true)

			if changed then
				saveConfigIfReady()
			end
		else
			setTargetCheckEnabled(true)
		end
	else
		setTargetCheckEnabled(true)

		if not isHelperEnabled() then
			wasInProtectionZone = inPz

			if modules.game_helper and modules.game_helper.refreshHelperStats then
				modules.game_helper.refreshHelperStats()
			end

			return
		end

		if isTargetPzAutoEnabled() then
			if inPz and not wasInProtectionZone then
				local autoTarget = widget("enableTargetCheckBox")

				if autoTarget and autoTarget:isChecked() then
					targetEnabledBeforePz = true
					suppressTargetCheckChange = true

					autoTarget:setChecked(false)

					suppressTargetCheckChange = false

					if currentLockedTargetId > 0 then
						currentLockedTargetId = 0

						g_game.cancelAttack()
					end
				else
					targetEnabledBeforePz = false
				end
			elseif not inPz and wasInProtectionZone and targetEnabledBeforePz then
				targetEnabledBeforePz = false

				local autoTarget = widget("enableTargetCheckBox")

				if autoTarget and not autoTarget:isChecked() then
					suppressTargetCheckChange = true

					autoTarget:setChecked(true)

					suppressTargetCheckChange = false
				end
			end
		elseif not inPz then
			targetEnabledBeforePz = false
		end
	end

	wasInProtectionZone = inPz

	if modules.game_helper and modules.game_helper.refreshHelperStats then
		modules.game_helper.refreshHelperStats()
	end
end

function HelperTarget.refreshProtectionZoneState()
	updateProtectionZoneAutoTarget()
end

local function checkAutoTarget()
	updateProtectionZoneAutoTarget()

	local myCharacter = g_game.getLocalPlayer()

	if not myCharacter then
		return
	end

	if myCharacter:isInProtectionZone() then
		return
	end

	if not isAutoTargetEnabled() then
		return
	end

	if autoTargetOnHold then
		return
	end

	local position = myCharacter:getPosition()
	refreshVisibleSpectators(position)
	local minDist, maxDist = readDistanceRange()
	local allCreatures = allCreaturesEnabled

	targetOperatingMode = readTargetOperatingModeWidget()

	local areaCreatureList = targetOperatingMode == "E" and buildBestTargetAreaCreatureList(position) or nil

	if not allCreatures and not next(getPriorityRaceOrder()) then
		currentLockedTargetId = 0
		-- An empty auto-target list means there is nothing for the helper to manage.
		-- Preserve attacks selected manually instead of cancelling them every tick.
		return
	end

	local bestTarget = {
		priority = 9999,
		areaCount = 0,
		creatureId = 0,
		health = 0,
		distance = 99
	}

	for _, creature in pairs(spectators) do
		if isMapCreature(creature) and not creature:isDead() and not isCavebotIgnored(creature) and creatureMatchesPriority(creature, allCreatures) then
			local creaturePos = creature:getPosition()

			if isWithinDistance(position, creaturePos, minDist, maxDist) and g_map.isSightClear(position, creaturePos) then
				local priority = getPriorityRank(creature)
				local creatureDistance = getDistanceBetween(position, creaturePos)
				local creatureId = creature:getId()
				local candidate = {
					id = creatureId,
					priority = priority,
					distance = creatureDistance,
					health = creature:getHealthPercent() or 0,
					areaCount = targetOperatingMode == "E" and getGroupedTargetCount(creature, areaCreatureList) or 0,
					creatureId = creatureId
				}
				local isBetter = false

				if priority < bestTarget.priority then
					isBetter = true
				elseif priority == bestTarget.priority then
					isBetter = isOperatingCandidateBetter(candidate, bestTarget, targetOperatingMode)
				end

				if isBetter then
					bestTarget = candidate
				end
			end
		end
	end

	local tickNow = nowMs()
	local target = bestTarget.id and g_map.getCreatureById(bestTarget.id) or nil
	local currentTarget = g_game.getAttackingCreature()

	if target and currentTarget and currentTarget:getId() ~= target:getId() and lastTargetAttackId == currentTarget:getId() and lastTargetAttackAt > 0 and tickNow - lastTargetAttackAt < TARGET_SWITCH_DELAY_MS and isLockedTargetValid(currentTarget, position, minDist, maxDist, allCreatures) then
		target = currentTarget
	end

	if target then
		currentLockedTargetId = target:getId()

		if not currentTarget or currentTarget:getId() ~= target:getId() then
			g_game.attack(target)

			lastTargetAttackId = target:getId()
			lastTargetAttackAt = tickNow
		end

		applyTargetAttackMode()
	else
		currentLockedTargetId = 0

		if currentTarget then
			g_game.cancelAttack()
		end
	end
end

function HelperTarget.onTargetModeChange()
	if suppressTargetSettingsChange then
		return
	end

	targetAttackMode = readTargetModeWidget()

	applyTargetAttackMode()
	saveConfigIfReady()
end

function HelperTarget.onTargetPriorityChange()
	if suppressTargetSettingsChange then
		return
	end

	targetOperatingMode = readTargetOperatingModeWidget()

	local combo = widget("targetOperatingModeCombo")

	if combo and combo.setTooltip then
		combo:setTooltip(operatingModeText(targetOperatingMode))
	end

	currentLockedTargetId = 0
	lastTargetAttackId = 0
	lastTargetAttackAt = 0

	saveConfigIfReady()
end

function HelperTarget.onTargetPzAutoChange()
	if suppressTargetSettingsChange then
		return
	end

	targetPzAuto = readTargetPzAutoWidget()

	saveConfigIfReady()
	updateProtectionZoneAutoTarget()
end

function HelperTarget.isDisabledByProtectionZone()
	return targetEnabledBeforePz == true
end

function HelperTarget.enableProtectionZonePause()
	local player = g_game.getLocalPlayer()

	if not player or not player.isInProtectionZone or not player:isInProtectionZone() then
		return false
	end

	if not isTargetPzAutoEnabled() then
		return false
	end

	targetEnabledBeforePz = true
	wasInProtectionZone = true

	local autoTarget = widget("enableTargetCheckBox")

	if autoTarget and autoTarget:isChecked() then
		suppressTargetCheckChange = true

		autoTarget:setChecked(false)

		suppressTargetCheckChange = false
	end

	if currentLockedTargetId > 0 then
		currentLockedTargetId = 0

		g_game.cancelAttack()
	end

	saveConfigIfReady()

	if modules.game_helper and modules.game_helper.refreshHelperStats then
		modules.game_helper.refreshHelperStats()
	end

	return true
end

function HelperTarget.disableProtectionZonePause()
	targetEnabledBeforePz = false

	setTargetCheckEnabled(not isTargetBlockedByProtectionZone())

	local autoTarget = widget("enableTargetCheckBox")

	if autoTarget and autoTarget:isChecked() then
		suppressTargetCheckChange = true

		autoTarget:setChecked(false)

		suppressTargetCheckChange = false
	end

	saveConfigIfReady()

	if modules.game_helper and modules.game_helper.refreshHelperStats then
		modules.game_helper.refreshHelperStats()
	end
end

function HelperTarget.runTick(_state)
	combatTimer = combatTimer + COMBAT_TICK_MS

	if combatTimer >= TARGET_INTERVAL_MS then
		combatTimer = 0

		checkAutoTarget()
	end
end

function HelperTarget.toggleAutoTarget(checkWidget, silent)
	if not checkWidget then
		checkWidget = widget("enableTargetCheckBox")

		if checkWidget then
			suppressTargetCheckChange = true

			checkWidget:setChecked(not checkWidget:isChecked())

			suppressTargetCheckChange = false
		end
	end

	if not checkWidget then
		return
	end

	if checkWidget:isChecked() and blockTargetEnableInProtectionZone(silent) then
		saveConfigIfReady()
		syncCombatSchedulerState()

		if modules.game_helper and modules.game_helper.refreshHelperStats then
			modules.game_helper.refreshHelperStats()
		end

		return
	end

	if not checkWidget:isChecked() and currentLockedTargetId > 0 then
		currentLockedTargetId = 0

		g_game.cancelAttack()
	end

	if not silent then
		showMessage(string.format("Auto Target is %s.", checkWidget:isChecked() and "enabled" or "disabled"))
	end

	saveConfigIfReady()
	syncCombatSchedulerState()
end

function HelperTarget.onEnableTargetCheckChange(checkWidget)
	if not checkWidget then
		return
	end

	if suppressTargetCheckChange then
		syncCombatSchedulerState()

		return
	end

	if checkWidget:isChecked() and blockTargetEnableInProtectionZone(false) then
		saveConfigIfReady()
		syncCombatSchedulerState()

		if modules.game_helper and modules.game_helper.refreshHelperStats then
			modules.game_helper.refreshHelperStats()
		end

		return
	end

	if not checkWidget:isChecked() and currentLockedTargetId > 0 then
		currentLockedTargetId = 0

		g_game.cancelAttack()
	end

	saveConfigIfReady()
	syncCombatSchedulerState()
end

function HelperTarget.toggleAutoTargetHotkey()
	HelperTarget.toggleAutoTarget(nil)
end

function HelperTarget.setAutoTargetEnabledFromHotkey(newState, silent)
	local check = widget("enableTargetCheckBox")

	if not check then
		return false
	end

	if newState == true and blockTargetEnableInProtectionZone(silent) then
		return false
	end

	if check:isChecked() ~= (newState == true) then
		suppressTargetCheckChange = true

		check:setChecked(newState == true)

		suppressTargetCheckChange = false

		HelperTarget.toggleAutoTarget(check, silent)
	end

	return check:isChecked()
end

function HelperTarget.bindHotkeys(config, skipAutoTargetHotkey)
	if boundAutoTargetHotkey and boundAutoTargetHotkey ~= "" then
		g_keyboard.unbindKeyPress(boundAutoTargetHotkey)
	end

	boundAutoTargetHotkey = nil

	local autoHotkey = config and config.autoTargetHotkey

	if not skipAutoTargetHotkey and type(autoHotkey) == "string" and autoHotkey ~= "" then
		boundAutoTargetHotkey = autoHotkey

		g_keyboard.bindKeyPress(autoHotkey, function()
			if not HotkeyUtils.canPerformKeyCombo(autoHotkey) then
				return
			end

			if not isHelperEnabled() then
				return
			end

			HelperTarget.toggleAutoTargetHotkey()
		end)
	end

	HelperTarget.updateTargetHotkeyButtonLabel(config)
end

function HelperTarget.unbindHotkeys()
	if boundAutoTargetHotkey and boundAutoTargetHotkey ~= "" then
		g_keyboard.unbindKeyPress(boundAutoTargetHotkey)
	end

	boundAutoTargetHotkey = nil
end

function HelperTarget.updateTargetHotkeyButtonLabel(config)
	local btn = widget("setTargetHotkeyButton")

	if not btn then
		return
	end

	local hotkey = config and config.autoTargetHotkey or ""

	if hotkey == "" then
		btn:setText(tr("Key [NONE]"))
	else
		btn:setText(tr("Key [%s]", hotkey))
	end
end

function HelperTarget.collectHotkeys(config)
	config.autoTargetHotkey = config.autoTargetHotkey or ""
end

local function capitalizeWords(text)
	if not text or text == "" then
		return ""
	end

	return (text:gsub("(%a)([%w_']*)", function(a, rest)
		return a:upper() .. rest:lower()
	end))
end

local function applyZebraToPanel(panel)
	if not panel then
		return
	end

	local idx = 0

	for _, child in ipairs(panel:getChildren()) do
		if child:isVisible() then
			idx = idx + 1

			local color = idx % 2 == 1 and ZEBRA_COLOR_A or ZEBRA_COLOR_B

			child.zebraColor = color

			child:setBackgroundColor(color)
		end
	end
end

local function connectZebraFocus(item)
	connect(item, {
		onFocusChange = function(self, focused)
			if focused then
				self:setBackgroundColor("#585858")
			else
				addEvent(function()
					if not self:isDestroyed() then
						self:setBackgroundColor(self.zebraColor or ZEBRA_COLOR_A)
					end
				end)
			end
		end
	})
end

local function findRaceById(raceId)
	local id = normalizeRaceId(raceId)

	if not id then
		return nil
	end

	for _, race in ipairs(getMonstersSorted()) do
		if normalizeRaceId(race.raceId) == id then
			return race
		end
	end

	return nil
end

local function getPriorityRaceIds(excludeIndex)
	local ids = {}

	for i, entry in ipairs(priorityList) do
		local raceId = normalizeRaceId(entry.raceId)

		if raceId and i ~= excludeIndex then
			ids[raceId] = true
		end
	end

	return ids
end

local function applyCreaturePreview(creatureWidget, outfit)
	if creatureWidget and outfit then
		creatureWidget:setOutfit(outfit)
	end
end

local function setCreatureRowData(row, race)
	if not row or not race then
		return
	end

	row.targetRaceId = race.raceId

	local creatureSprite = row:recursiveGetChildById("creatureSprite")
	local creatureIcon = row:recursiveGetChildById("creatureIcon")

	if creatureIcon then
		creatureIcon:hide()
	end

	if creatureSprite then
		creatureSprite:show()
		applyCreaturePreview(creatureSprite, race.outfit)
	end

	local nameLabel = row:recursiveGetChildById("creatureName")

	if nameLabel then
		nameLabel:setText(capitalizeWords(race.name))
	end
end

local function applyAllCreaturesRowVisual(row, entry)
	if not row then
		return
	end

	local enabledCheck = row:recursiveGetChildById("targetRowEnabled")

	if enabledCheck then
		local enabled = entry and entry.enabled ~= false or allCreaturesEnabled

		enabledCheck:setChecked(enabled)
	end

	local creatureSprite = row:recursiveGetChildById("creatureSprite")
	local creatureIcon = row:recursiveGetChildById("creatureIcon")

	if creatureSprite then
		creatureSprite:hide()
	end

	if creatureIcon then
		creatureIcon:setImageSource(ALL_CREATURES_ICON)
		creatureIcon:show()
	end

	local nameLabel = row:recursiveGetChildById("creatureName")

	if nameLabel then
		nameLabel:setText(targetText("allCreatures"))
	end
end

local function applyTargetPriorityRowVisual(row, entry)
	if not row or not entry then
		return
	end

	local enabledCheck = row:recursiveGetChildById("targetRowEnabled")

	if enabledCheck then
		enabledCheck:setChecked(entry.enabled ~= false)
	end

	local race = findRaceById(entry.raceId) or entry

	setCreatureRowData(row, race)
end

local function getSelectedRemovableTargetRow()
	local list = widget("targetPriorityList")

	if not list or list:isDestroyed() then
		return nil
	end

	local focused = list:getFocusedChild()

	if focused and not focused.isAllCreaturesRow and focused.priorityListIndex then
		return focused
	end

	return nil
end

local function resetTargetActionButtonsState()
	targetActionButtonsState = nil
end

local function syncTargetActionButtons()
	local addBtn = widget("targetAddBtn")
	local editBtn = widget("targetEditBtn")
	local removeBtn = widget("targetRemoveBtn")

	if not addBtn or not editBtn or not removeBtn then
		return
	end

	local showActions = getSelectedRemovableTargetRow() ~= nil
	local stateKey = showActions and "actions" or "default"

	if targetActionButtonsState == stateKey then
		return
	end

	targetActionButtonsState = stateKey

	addBtn:setEnabled(true)

	if showActions then
		removeBtn:show()
		editBtn:show()
		addBtn:breakAnchors()
		addBtn:addAnchor(AnchorTop, "parent", AnchorTop)
		addBtn:addAnchor(AnchorRight, "targetEditBtn", AnchorLeft)
		addBtn:setMarginRight(6)
		editBtn:setEnabled(true)
		removeBtn:setEnabled(true)
		removeBtn:setMarginRight(0)
	else
		removeBtn:hide()
		editBtn:hide()
		addBtn:breakAnchors()
		addBtn:addAnchor(AnchorTop, "parent", AnchorTop)
		addBtn:addAnchor(AnchorRight, "parent", AnchorRight)
		addBtn:setMarginRight(0)
	end
end

local function scheduleTargetActionButtonsSync()
	addEvent(function()
		syncTargetActionButtons()
	end)
end

local function clearTargetListSelection()
	local list = widget("targetPriorityList")

	if not list or list:isDestroyed() then
		return
	end

	list:focusChild(nil)
	resetTargetActionButtonsState()
	scheduleTargetActionButtonsSync()
end

local function updateTargetPreview(row)
	if not targetAssignWindow or targetAssignWindow:isDestroyed() or not row then
		return
	end

	local preview = targetAssignWindow:recursiveGetChildById("targetPreview")

	if not preview then
		return
	end

	local race = row.targetRace
	local sprite = preview:getChildById("previewCreatureSprite")

	if sprite and race then
		applyCreaturePreview(sprite, race.outfit)
	end

	local name = preview:getChildById("previewCreatureName")

	if name and race then
		name:setText(capitalizeWords(race.name))
	end
end

local function refreshAddButtonState()
	syncTargetActionButtons()
end

local function refreshPriorityListUI()
	ensureAllCreaturesEntry()
	resetTargetActionButtonsState()

	local list = widget("targetPriorityList")

	if not list then
		return
	end

	list:destroyChildren()

	for idx, entry in ipairs(priorityList) do
		local rowEntry = entry
		local row = g_ui.createWidget("TargetPriorityListRow", list)
		local zebraColor = idx % 2 == 1 and ZEBRA_COLOR_A or ZEBRA_COLOR_B

		row.zebraColor = zebraColor

		row:setBackgroundColor(zebraColor)

		row.priorityListIndex = idx
		row.isAllCreaturesRow = rowEntry.allCreatures == true

		if rowEntry.allCreatures then
			applyAllCreaturesRowVisual(row, rowEntry)
		else
			row.targetRaceId = rowEntry.raceId

			applyTargetPriorityRowVisual(row, rowEntry)
		end

		local rowCheck = row:recursiveGetChildById("targetRowEnabled")

		if rowCheck then
			function rowCheck.onCheckChange(_, checked)
				rowEntry.enabled = checked

				if rowEntry.allCreatures then
					allCreaturesEnabled = checked == true

					resetTargetActionButtonsState()
					scheduleTargetActionButtonsSync()
				end

				saveConfigIfReady()
			end
		end

		connectZebraFocus(row)

		function row:onMouseRelease(_, button)
			if button == MouseRightButton then
				openTargetRowContextMenu(self)
			end
		end
	end

	syncTargetActionButtons()
end

function openTargetRowContextMenu(row)
	if not row or not row.priorityListIndex then
		return
	end

	local index = row.priorityListIndex
	local entry = priorityList[index]

	if not entry then
		return
	end

	local list = widget("targetPriorityList")

	if list and not list:isDestroyed() then
		list:focusChild(row, KeyboardFocusReason)
		resetTargetActionButtonsState()
		scheduleTargetActionButtonsSync()
	end

	local menu = g_ui.createWidget("GamePopupMenu")

	menu:setWidth(120)

	if index > 1 then
		menu:addOption(targetText("moveUp"), function()
			local newIndex = movePriorityEntryAt(index, -1)

			if newIndex then
				refreshPriorityListUI()
				focusTargetRowByIndex(newIndex)
				syncTargetActionButtons()
				saveConfigIfReady()
			end
		end)
	end

	if index < #priorityList then
		menu:addOption(targetText("moveDown"), function()
			local newIndex = movePriorityEntryAt(index, 1)

			if newIndex then
				refreshPriorityListUI()
				focusTargetRowByIndex(newIndex)
				syncTargetActionButtons()
				saveConfigIfReady()
			end
		end)
	end

	if not entry.allCreatures then
		menu:addOption(targetText("edit"), function()
			openTargetAssignWindowInternal(index)
		end)
		menu:addOption(targetText("remove"), function()
			if removePriorityEntryAt(index) then
				refreshPriorityListUI()
				syncTargetActionButtons()
				saveConfigIfReady()
			end
		end)
	end

	menu:display()
end

local function closeTargetAssignWindowInternal()
	if targetAssignWindow and not targetAssignWindow:isDestroyed() then
		targetAssignWindow:destroy()
	end

	targetAssignWindow = nil
	targetMonstersPanel = nil
	editingPriorityListIndex = nil
end

local function populateTargetMonsterList()
	if not targetMonstersPanel then
		return
	end

	targetMonstersPanel:destroyChildren()

	local excludeIds = getPriorityRaceIds(editingPriorityListIndex)
	local visibleIdx = 0

	for _, race in ipairs(getMonstersSorted()) do
		if not excludeIds[race.raceId] then
			visibleIdx = visibleIdx + 1

			local rowType = visibleIdx % 2 == 1 and "HelperCreatureListRowOdd" or "HelperCreatureListRowEven"
			local row = g_ui.createWidget(rowType, targetMonstersPanel)

			row.targetRace = race
			row.nameLower = (race.name or ""):lower()

			setCreatureRowData(row, race)
			connectZebraFocus(row)
		end
	end

	local okBtn = targetAssignWindow and targetAssignWindow:recursiveGetChildById("okButton")

	if okBtn then
		okBtn:setEnabled(false)
	end
end

local function filterTargetMonsterRows(text)
	if not targetMonstersPanel then
		return
	end

	text = text or ""

	local active = #text > 0
	local lower = active and text:lower() or ""

	for _, row in pairs(targetMonstersPanel:getChildren()) do
		local visible = true

		if active then
			visible = row.nameLower and row.nameLower:find(lower, 1, true) ~= nil
		end

		row:setVisible(visible)
	end

	applyZebraToPanel(targetMonstersPanel)
end

local function focusTargetMonsterRowByRaceId(raceId)
	if not targetMonstersPanel or not raceId then
		return
	end

	local wantedId = normalizeRaceId(raceId)

	if not wantedId then
		return
	end

	for _, row in pairs(targetMonstersPanel:getChildren()) do
		if row:isVisible() and row.targetRace and normalizeRaceId(row.targetRace.raceId) == wantedId then
			targetMonstersPanel:focusChild(row, KeyboardFocusReason)
			updateTargetPreview(row)

			local okBtn = targetAssignWindow and targetAssignWindow:recursiveGetChildById("okButton")

			if okBtn then
				okBtn:setEnabled(true)
			end

			return
		end
	end
end

function openTargetAssignWindowInternal(editIndex)
	closeTargetAssignWindowInternal()

	editingPriorityListIndex = editIndex
	targetAssignWindow = g_ui.loadUI("assign_target", g_ui.getRootWidget())

	if not targetAssignWindow then
		editingPriorityListIndex = nil

		return
	end

	targetAssignWindow:setText(editIndex and targetText("edit") .. " Target" or targetText("add") .. " Target")

	local okBtn = targetAssignWindow:recursiveGetChildById("okButton")

	if okBtn then
		okBtn:setText(editIndex and targetText("edit") or targetText("add"))
	end

	targetMonstersPanel = targetAssignWindow:recursiveGetChildById("targetMonstersPanel")

	connect(targetMonstersPanel, {
		onChildFocusChange = function(_, focusedChild)
			if focusedChild then
				updateTargetPreview(focusedChild)
			end

			local okBtn = targetAssignWindow:recursiveGetChildById("okButton")

			if okBtn then
				okBtn:setEnabled(focusedChild ~= nil)
			end
		end
	})
	populateTargetMonsterList()
	filterTargetMonsterRows("")
	targetAssignWindow:show()
	targetAssignWindow:raise()
	targetAssignWindow:focus()

	if editIndex then
		local entry = priorityList[editIndex]

		if entry and entry.raceId then
			addEvent(function()
				if targetAssignWindow and not targetAssignWindow:isDestroyed() then
					focusTargetMonsterRowByRaceId(entry.raceId)
				end
			end)
		end
	end
end

local function setTargetWidgetText(id, text)
	local target = widget(id)

	if target and target.setText then
		target:setText(text)
	end
end

function HelperTarget.refreshLanguage(language)
	targetUiLanguage = normalizeTargetLanguage(language)

	setTargetWidgetText("targetListWindow", targetText("targetList"))
	setTargetWidgetText("targetSettingsWindow", targetText("targetSettings"))
	setTargetWidgetText("targetModeLabel", targetText("mode"))
	setTargetWidgetText("targetDistanceLabel", targetText("distance"))
	setTargetWidgetText("targetPriorityLabel", targetText("priority"))
	setTargetWidgetText("targetPzAutoLabel", targetText("pzAuto"))
	setTargetWidgetText("enableTargetLabel", targetText("enableTarget"))
	setTargetWidgetText("targetAddBtn", targetText("add"))
	setTargetWidgetText("targetEditBtn", targetText("edit"))
	setTargetWidgetText("targetRemoveBtn", targetText("remove"))
	setTargetWidgetText("targetHeaderCreature", targetText("creature"))
	setTargetWidgetText("targetHeaderName", targetText("name"))

	local listHelp = widget("targetListHelp")

	if listHelp and listHelp.setTooltip then
		listHelp:setTooltip(targetText("targetListHelp"))
	end

	local settingsHelp = widget("targetSettingsHelp")

	if settingsHelp and settingsHelp.setTooltip then
		settingsHelp:setTooltip(targetText("targetSettingsHelp"))
	end

	rebuildTargetSettingOptions()
	refreshPriorityListUI()
	refreshAddButtonState()

	if targetAssignWindow and not targetAssignWindow:isDestroyed() then
		targetAssignWindow:setText(editingPriorityListIndex and targetText("edit") .. " Target" or targetText("add") .. " Target")

		local okBtn = targetAssignWindow:recursiveGetChildById("okButton")

		if okBtn then
			okBtn:setText(editingPriorityListIndex and targetText("edit") or targetText("add"))
		end
	end
end

function HelperTarget.init(pctx)
	ctx = pctx
	combatTimer = 0

	HelperTarget.refreshLanguage(ctx and ctx.getLanguage and ctx.getLanguage() or "en")

	local list = widget("targetPriorityList")

	if list then
		connect(list, {
			onChildFocusChange = function()
				scheduleTargetActionButtonsSync()
			end
		})
	end

	refreshAddButtonState()
end

function HelperTarget.onShow()
	refreshAddButtonState()
	clearTargetListSelection()
end

function HelperTarget.onHide()
	closeTargetAssignWindowInternal()
	clearTargetListSelection()
end

function HelperTarget.onGameStart()
	HelperTarget.clearSpectators()

	currentLockedTargetId = 0
	combatTimer = 0
end

function HelperTarget.terminate()
	HelperTarget.unbindHotkeys()
	closeTargetAssignWindowInternal()

	priorityList = {}
	allCreaturesEnabled = false
	monsterCache = nil
	monsterNameToRaceId = nil
	spectators = {}
	spectatorMeta = {}
	spectatorAgeCounter = 0
	currentLockedTargetId = 0
	targetEnabledBeforePz = false
	wasInProtectionZone = false
end

function HelperTarget.openAssignWindow()
	openTargetAssignWindowInternal(nil)
end

function HelperTarget.openEditAssignWindow()
	local row = getSelectedRemovableTargetRow()

	if not row or not row.priorityListIndex then
		return
	end

	openTargetAssignWindowInternal(row.priorityListIndex)
end

function HelperTarget.closeAssignWindow()
	closeTargetAssignWindowInternal()
end

function HelperTarget.filterMonsters(text)
	filterTargetMonsterRows(text or "")
end

function HelperTarget.clearMonsterFilter()
	if not targetAssignWindow or targetAssignWindow:isDestroyed() then
		return
	end

	local edit = targetAssignWindow:recursiveGetChildById("filterTextEdit")

	if edit then
		edit:setText("")
		edit:focus()
	end

	filterTargetMonsterRows("")
end

function HelperTarget.assignOk()
	if not targetMonstersPanel then
		return
	end

	local focused = targetMonstersPanel:getFocusedChild()

	if not focused or not focused.targetRace then
		return
	end

	local race = focused.targetRace
	local raceId = normalizeRaceId(race.raceId)

	if not raceId then
		return
	end

	local editIndex = editingPriorityListIndex

	for i, entry in ipairs(priorityList) do
		if normalizeRaceId(entry.raceId) == raceId and i ~= editIndex then
			closeTargetAssignWindowInternal()

			return
		end
	end

	local focusIndex = editIndex

	if editIndex then
		local entry = priorityList[editIndex]

		if not entry or entry.allCreatures then
			closeTargetAssignWindowInternal()

			return
		end

		entry.raceId = raceId
		entry.name = race.name
		entry.outfit = race.outfit
	else
		table.insert(priorityList, {
			enabled = true,
			raceId = raceId,
			name = race.name,
			outfit = race.outfit
		})

		focusIndex = #priorityList
	end

	refreshPriorityListUI()
	saveConfigIfReady()
	closeTargetAssignWindowInternal()

	if focusIndex then
		addEvent(function()
			focusTargetRowByIndex(focusIndex)
		end)
	end
end

function HelperTarget.onAllCreaturesChange(_, checked)
	allCreaturesEnabled = checked == true

	ensureAllCreaturesEntry()

	for _, entry in ipairs(priorityList) do
		if entry.allCreatures then
			entry.enabled = allCreaturesEnabled

			break
		end
	end

	refreshAddButtonState()
	saveConfigIfReady()
end

function HelperTarget.onRemoveClick()
	local list = widget("targetPriorityList")

	if not list then
		return
	end

	local focused = list:getFocusedChild()

	if not focused or focused.isAllCreaturesRow or not focused.priorityListIndex then
		return
	end

	if removePriorityEntryAt(focused.priorityListIndex) then
		refreshPriorityListUI()
		saveConfigIfReady()
	end
end

function HelperTarget.collectConfig(config)
	ensureAllCreaturesEntry()

	config.target = config.target or {}

	local enableCheck = widget("enableTargetCheckBox")
	local enabled = enableCheck and enableCheck:isChecked() or false

	config.target.enableTarget = enabled or isTargetPzAutoEnabled() and targetEnabledBeforePz == true

	if ctx.readDistanceValue then
		config.target.distance = ctx.readDistanceValue("targetDistanceCombo")
	end

	config.target.mode = readTargetModeWidget()
	config.target.autoTargetMode = readTargetOperatingModeWidget()
	config.target.pzAuto = readTargetPzAutoWidget()
	config.target.minDist = nil
	config.target.maxDist = nil
	config.target.priorityOrder = nil
	config.target.prioritySort = nil
	config.target.prioritySecondary = nil

	local allCreaturesIndex = 1

	config.target.allCreatures = allCreaturesEnabled
	config.target.priorityList = {}

	for i, entry in ipairs(priorityList) do
		if entry.allCreatures then
			allCreaturesIndex = i
			config.target.allCreatures = entry.enabled ~= false
		elseif entry.raceId then
			local raceId = normalizeRaceId(entry.raceId)

			if raceId then
				table.insert(config.target.priorityList, {
					raceId = raceId,
					name = entry.name,
					enabled = entry.enabled ~= false
				})
			end
		end
	end

	config.target.allCreaturesIndex = allCreaturesIndex
end

function HelperTarget.loadFromConfig(config)
	local data = config.target or {}
	local enableCheck = widget("enableTargetCheckBox")

	if enableCheck then
		enableCheck:setChecked(data.enableTarget == true)
	end

	if ctx.applyDistanceValue then
		ctx.applyDistanceValue("targetDistanceCombo", data.distance or data.maxDist or 7)
	end

	targetAttackMode = normalizeTargetMode(data.mode)

	applyTargetModeWidget(targetAttackMode)

	if data.autoTargetMode ~= nil or data.operatingMode ~= nil then
		targetOperatingMode = normalizeTargetOperatingMode(data.autoTargetMode or data.operatingMode)
	else
		targetOperatingMode = operatingModeFromLegacyConfig(data)
	end

	applyTargetOperatingModeWidget(targetOperatingMode)

	targetPzAuto = normalizeTargetPzAuto(data.pzAuto)

	applyTargetPzAutoWidget(targetPzAuto)

	targetEnabledBeforePz = false
	wasInProtectionZone = false

	setTargetCheckEnabled(true)

	allCreaturesEnabled = data.allCreatures == true
	currentLockedTargetId = 0
	lastTargetAttackId = 0
	lastTargetAttackAt = 0
	priorityList = {}

	for _, entry in ipairs(data.priorityList or {}) do
		if entry.raceId and not entry.allCreatures then
			local raceId = normalizeRaceId(entry.raceId)

			if raceId then
				local race = findRaceById(raceId)

				table.insert(priorityList, {
					raceId = raceId,
					name = entry.name or race and race.name or "",
					outfit = race and race.outfit or nil,
					enabled = entry.enabled ~= false
				})
			end
		end
	end

	local allCreaturesIndex = tonumber(data.allCreaturesIndex) or 1

	if allCreaturesIndex < 1 then
		allCreaturesIndex = 1
	end

	if allCreaturesIndex > #priorityList + 1 then
		allCreaturesIndex = #priorityList + 1
	end

	table.insert(priorityList, allCreaturesIndex, createAllCreaturesEntry(allCreaturesEnabled))
	ensureAllCreaturesEntry()
	refreshPriorityListUI()
	refreshAddButtonState()
end
