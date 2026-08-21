-- chunkname: @/game_cyclopedia/tab/charms/charms.lua

local UI, TypeCharmRadioGroup

Cyclopedia.Charms = {}

local charmCategory_t = {
	CHARM_MAJOR = 1,
	CHARM_ALL = 0,
	CHARM_MINOR = 2
}
local CHARM_ACTION = {
	SELECT = 1,
	UPGRADE = 0,
	RESET_ALL = 3,
	CLEAR = 2
}

Cyclopedia.CHARM_CATEGORY_MAJOR = charmCategory_t.CHARM_MAJOR
Cyclopedia.CHARM_CATEGORY_MINOR = charmCategory_t.CHARM_MINOR
Cyclopedia.CHARM_ACTION = CHARM_ACTION

local function isCharmUnlocked(data)
	if not data then
		return false
	end

	return data.tier > 0 or data.unlocked or data.asignedStatus
end

local function getPlayerTotalGold(player)
	if not player then
		return 0
	end

	if player.getTotalMoney then
		return player:getTotalMoney() or 0
	end

	return (player:getResourceBalance(ResourceBank) or 0) + (player:getResourceBalance(ResourceInventary) or 0)
end

local function canAffordGoldCost(player, cost)
	return (cost or 0) <= getPlayerTotalGold(player)
end

local function setActionButtonTextColor(button)
	if not button or button:isDestroyed() then
		return
	end

	button:setColor(button:isEnabled() and "#ffffff" or "#C0C0C0")
end

local function updateResetAllCharmsCostDisplay()
	if not UI then
		return
	end

	local valueLabel = UI:recursiveGetChildById("resetAllCharmsCostValue")

	if not valueLabel then
		return
	end

	local cost = tonumber(Cyclopedia.Charms.resetAllCharmsCost) or 0

	valueLabel:setText(comma_value(cost))

	local resetButton = UI:recursiveGetChildById("ResetAllCharmsButton")
	local player = g_game.getLocalPlayer()

	if cost <= 0 then
		valueLabel:setColor("#C0C0C0")

		if resetButton then
			resetButton:setEnabled(false)
			setActionButtonTextColor(resetButton)
		end

		return
	end

	if resetButton then
		resetButton:setEnabled(true)
		setActionButtonTextColor(resetButton)
	end

	if player then
		local canAfford = canAffordGoldCost(player, cost)

		valueLabel:setColor(canAfford and "#C0C0C0" or "#D33C3C")
	else
		valueLabel:setColor("#C0C0C0")
	end
end

local function isCreatureSelectableForCharm(creature, charmCategory)
	if charmCategory == charmCategory_t.CHARM_MAJOR then
		return creature.showInMajorListState
	end

	if charmCategory == charmCategory_t.CHARM_MINOR then
		return creature.showInMinorListState or (creature.monsterMinorState or 0) > 0
	end

	return true
end

local function buildSelectableMonsterList(charmCategory)
	local raceIdNamePairs = {}

	for _, creature in ipairs(Cyclopedia.Charms.SelectableCreatures or {}) do
		if isCreatureSelectableForCharm(creature, charmCategory) then
			local raceData = g_things.getRaceData(creature.raceId)
			local raceName = raceData.name ~= "" and raceData.name or string.format("unnamed_%d", creature.raceId)

			table.insert(raceIdNamePairs, {
				raceId = creature.raceId,
				name = raceName
			})
		end
	end

	table.sort(raceIdNamePairs, function(a, b)
		return a.name:lower() < b.name:lower()
	end)

	local monsters = {}

	for _, pair in ipairs(raceIdNamePairs) do
		table.insert(monsters, pair.raceId)
	end

	return monsters
end

local charm_t = {
	CHARM_PASSIVE = 3,
	CHARM_DEFENSIVE = 2,
	CHARM_OFFENSIVE = 1,
	CHARM_UNDEFINED = 0
}
local charmRune_t = {
	CHARM_CARNAGE = 22,
	CHARM_VOIDINVERSION = 21,
	CHARM_FATAL = 20,
	CHARM_SAVAGE = 19,
	CHARM_VOID = 18,
	CHARM_VAMP = 17,
	CHARM_DIVINE = 16,
	CHARM_LOW = 15,
	CHARM_GUT = 14,
	CHARM_SCAVENGE = 13,
	CHARM_BLESS = 12,
	CHARM_CLEANSE = 11,
	CHARM_NUMB = 10,
	CHARM_ADRENALINE = 9,
	CHARM_DODGE = 8,
	CHARM_PARRY = 7,
	CHARM_CRIPPLE = 6,
	CHARM_CURSE = 5,
	CHARM_ZAP = 4,
	CHARM_FREEZE = 3,
	CHARM_POISON = 2,
	CHARM_ENFLAME = 1,
	CHARM_WOUND = 0,
	CHARM_OVERFLUX = 24,
	CHARM_OVERPOWER = 23
}
local charms = {
	[charmRune_t.CHARM_WOUND] = {
		percent = 5,
		name = "Wound",
		description = "Your attacks have a %s%% chance to deal physical damage equal to 5% of the target's initial hit points.",
		category = charmCategory_t.CHARM_MAJOR,
		type = charm_t.CHARM_OFFENSIVE,
		chance = {
			5,
			10,
			11
		},
		points = {
			240,
			360,
			1200
		}
	},
	[charmRune_t.CHARM_ENFLAME] = {
		percent = 5,
		name = "Enflame",
		description = "Your attacks have a %s%% chance to deal fire damage equal to 5% of the target's initial hit points.",
		category = charmCategory_t.CHARM_MAJOR,
		type = charm_t.CHARM_OFFENSIVE,
		chance = {
			5,
			10,
			11
		},
		points = {
			400,
			600,
			2000
		}
	},
	[charmRune_t.CHARM_POISON] = {
		percent = 5,
		name = "Poison",
		description = "Your attacks have a %s%% chance to deal earth damage equal to 5% of the target's initial hit points.",
		category = charmCategory_t.CHARM_MAJOR,
		type = charm_t.CHARM_OFFENSIVE,
		chance = {
			5,
			10,
			11
		},
		points = {
			240,
			360,
			1200
		}
	},
	[charmRune_t.CHARM_FREEZE] = {
		percent = 5,
		name = "Freeze",
		description = "Your attacks have a %s%% chance to deal ice damage equal to 5% of the target's initial hit points.",
		category = charmCategory_t.CHARM_MAJOR,
		type = charm_t.CHARM_OFFENSIVE,
		chance = {
			5,
			10,
			11
		},
		points = {
			320,
			480,
			1600
		}
	},
	[charmRune_t.CHARM_ZAP] = {
		percent = 5,
		name = "Zap",
		description = "Your attacks have a %s%% chance to deal energy damage equal to 5% of the target's initial hit points.",
		category = charmCategory_t.CHARM_MAJOR,
		type = charm_t.CHARM_OFFENSIVE,
		chance = {
			5,
			10,
			11
		},
		points = {
			320,
			480,
			1600
		}
	},
	[charmRune_t.CHARM_CURSE] = {
		percent = 5,
		name = "Curse",
		description = "Your attacks have a %s%% chance to deal death damage equal to 5% of the target's initial hit points.",
		category = charmCategory_t.CHARM_MAJOR,
		type = charm_t.CHARM_OFFENSIVE,
		chance = {
			5,
			10,
			11
		},
		points = {
			360,
			540,
			1800
		}
	},
	[charmRune_t.CHARM_CRIPPLE] = {
		name = "Cripple",
		description = "Your attacks have a %s%% chance to paralyse the target for 10 seconds.",
		messageCancel = "You crippled a monster. (cripple charm)",
		category = charmCategory_t.CHARM_MINOR,
		type = charm_t.CHARM_OFFENSIVE,
		chance = {
			6,
			9,
			12
		},
		points = {
			100,
			150,
			225
		}
	},
	[charmRune_t.CHARM_PARRY] = {
		name = "Parry",
		description = "Each time you take damage, you have a %s%% chance to reflect it back to the aggressor.",
		messageCancel = "You parried an attack. (parry charm)",
		category = charmCategory_t.CHARM_MAJOR,
		type = charm_t.CHARM_DEFENSIVE,
		chance = {
			5,
			10,
			11
		},
		points = {
			400,
			600,
			2000
		}
	},
	[charmRune_t.CHARM_DODGE] = {
		name = "Dodge",
		description = "Grants a %s%% chance to dodge an attack.",
		messageCancel = "You dodged an attack. (dodge charm)",
		category = charmCategory_t.CHARM_MAJOR,
		type = charm_t.CHARM_DEFENSIVE,
		chance = {
			5,
			10,
			11
		},
		points = {
			240,
			360,
			1200
		}
	},
	[charmRune_t.CHARM_ADRENALINE] = {
		name = "Adrenaline Burst",
		description = "Each time you're hit, you have a %s%% chance to trigger a burst of adrenaline, boosting your speed by 150% for 10 seconds.",
		messageCancel = "Your movements where bursted. (adrenaline burst charm)",
		category = charmCategory_t.CHARM_MINOR,
		type = charm_t.CHARM_DEFENSIVE,
		chance = {
			6,
			9,
			12
		},
		points = {
			100,
			150,
			225
		}
	},
	[charmRune_t.CHARM_NUMB] = {
		name = "Numb",
		description = "After being attacked, you have a %s%% chance to paralyse the aggressor for 10 seconds.",
		messageCancel = "You numbed a monster. (numb charm)",
		category = charmCategory_t.CHARM_MINOR,
		type = charm_t.CHARM_DEFENSIVE,
		chance = {
			6,
			9,
			12
		},
		points = {
			100,
			150,
			225
		}
	},
	[charmRune_t.CHARM_CLEANSE] = {
		name = "Cleanse",
		description = "Each time you're hit, you have a %s%% chance to cleanse one random negative status effect and gain temporary immunity to it for 11 seconds.",
		messageCancel = "You purified an attack. (cleanse charm)",
		category = charmCategory_t.CHARM_MINOR,
		type = charm_t.CHARM_DEFENSIVE,
		chance = {
			6,
			9,
			12
		},
		points = {
			100,
			150,
			225
		}
	},
	[charmRune_t.CHARM_BLESS] = {
		percent = 10,
		name = "Bless",
		description = "Blesses you, reducing skill and experience loss by %s%% when killed by the chosen creature.",
		category = charmCategory_t.CHARM_MINOR,
		type = charm_t.CHARM_PASSIVE,
		chance = {
			6,
			9,
			12
		},
		points = {
			100,
			150,
			225
		}
	},
	[charmRune_t.CHARM_SCAVENGE] = {
		name = "Scavenge",
		description = "Increases your chance of successfully skinning/dusting a skinnable/dustable creature by %s%%.",
		category = charmCategory_t.CHARM_MINOR,
		type = charm_t.CHARM_PASSIVE,
		chance = {
			60,
			90,
			120
		},
		points = {
			100,
			150,
			225
		}
	},
	[charmRune_t.CHARM_GUT] = {
		name = "Gut",
		description = "Gutting the creature yields %s%% more creature products.",
		category = charmCategory_t.CHARM_MINOR,
		type = charm_t.CHARM_PASSIVE,
		chance = {
			6,
			9,
			12
		},
		points = {
			100,
			150,
			225
		}
	},
	[charmRune_t.CHARM_LOW] = {
		name = "Low Blow",
		description = "Adds +%s%% critical hit chance.",
		category = charmCategory_t.CHARM_MAJOR,
		type = charm_t.CHARM_PASSIVE,
		chance = {
			4,
			8,
			9
		},
		points = {
			800,
			1200,
			4000
		}
	},
	[charmRune_t.CHARM_DIVINE] = {
		percent = 5,
		name = "Divine Wrath",
		description = "Your attacks have a %s%% chance to deal holy damage equal to 5% of the target's initial hit points.",
		category = charmCategory_t.CHARM_MAJOR,
		type = charm_t.CHARM_OFFENSIVE,
		chance = {
			5,
			10,
			11
		},
		points = {
			600,
			900,
			3000
		}
	},
	[charmRune_t.CHARM_VAMP] = {
		name = "Vampiric Embrace",
		description = "Increases your current life leech by %s%%.",
		category = charmCategory_t.CHARM_MINOR,
		type = charm_t.CHARM_PASSIVE,
		chance = {
			1.6,
			2.4,
			3.2
		},
		points = {
			100,
			150,
			225
		}
	},
	[charmRune_t.CHARM_VOID] = {
		name = "Void's Call",
		description = "Increases your current mana leech by %s%%.",
		category = charmCategory_t.CHARM_MINOR,
		type = charm_t.CHARM_PASSIVE,
		chance = {
			0.8,
			1.2,
			1.6
		},
		points = {
			100,
			150,
			225
		}
	},
	[charmRune_t.CHARM_SAVAGE] = {
		name = "Savage Blow",
		description = "Adds +%s%% critical extra damage.",
		category = charmCategory_t.CHARM_MAJOR,
		type = charm_t.CHARM_PASSIVE,
		chance = {
			20,
			40,
			44
		},
		points = {
			800,
			1200,
			4000
		}
	},
	[charmRune_t.CHARM_FATAL] = {
		name = "Fatal Hold",
		description = "Your attacks have a %s%% chance to prevent creatures from fleeing due to low health for 30 seconds.",
		messageCancel = "Your enemy is not able to flee now for 30 seconds. (fatal hold charm)",
		category = charmCategory_t.CHARM_MINOR,
		type = charm_t.CHARM_PASSIVE,
		chance = {
			30,
			45,
			60
		},
		points = {
			100,
			150,
			225
		}
	},
	[charmRune_t.CHARM_VOIDINVERSION] = {
		name = "Void Inversion",
		description = "%s%% chance to gain mana instead of losing it when taking mana drain damage.",
		category = charmCategory_t.CHARM_MINOR,
		type = charm_t.CHARM_PASSIVE,
		chance = {
			20,
			30,
			40
		},
		points = {
			100,
			150,
			225
		}
	},
	[charmRune_t.CHARM_CARNAGE] = {
		percent = 15,
		name = "Carnage",
		description = "Killing a monster has %s%% chance to deal physical damage equal to 15% of its maximum health to all monsters in a small radius.",
		category = charmCategory_t.CHARM_MAJOR,
		type = charm_t.CHARM_OFFENSIVE,
		chance = {
			10,
			20,
			22
		},
		points = {
			600,
			900,
			3000
		}
	},
	[charmRune_t.CHARM_OVERPOWER] = {
		percent = 5,
		name = "Overpower",
		description = "Your attacks have a %s%% chance to deal damage equal to 5% of your maximum health.",
		category = charmCategory_t.CHARM_MAJOR,
		type = charm_t.CHARM_OFFENSIVE,
		chance = {
			5,
			10,
			11
		},
		points = {
			600,
			900,
			3000
		}
	},
	[charmRune_t.CHARM_OVERFLUX] = {
		percent = 2.5,
		name = "Overflux",
		description = "Your attacks have a %s%% chance to deal damage equal to 2.5% of your maximum mana.",
		category = charmCategory_t.CHARM_MAJOR,
		type = charm_t.CHARM_OFFENSIVE,
		chance = {
			5,
			10,
			11
		},
		points = {
			600,
			900,
			3000
		}
	}
}

-- crystal/canary has charmRune_t identical 1:1 to the 'charms' table above (CHARM_WOUND = 0 ... 24),
-- so there is no offset at all. The original "serverId - 1" lost charm 0 (Wound) and showed
-- every subsequent one under the previous one's name, and via resolveWireCharmId sent the wrong id
-- to the server (buying/upgrading hit the neighboring charm).
local function toClientCharmId(serverId)
	if type(serverId) ~= "number" or not charms[serverId] then
		return nil
	end

	return serverId
end

local function formatCharmChanceValue(value)
	if type(value) ~= "number" then
		return tostring(value or 0)
	end

	if value == math.floor(value) then
		return tostring(math.floor(value))
	end

	local text = string.format("%.2f", value)

	text = text:gsub("0+$", "")
	text = text:gsub("%.$", "")

	return text
end

local function resolveCharmDescriptionForTier(charmData, charmDefinition)
	local template = charmDefinition and charmDefinition.description

	if type(template) ~= "string" or not template:find("%%s") then
		return nil
	end

	local chanceByTier = charmDefinition.chance

	if type(chanceByTier) ~= "table" then
		return template
	end

	local tier = charmData and charmData.tier or 0
	local chanceIndex = math.max(1, math.min(3, tier))
	local chanceValue = chanceByTier[chanceIndex] or chanceByTier[1]
	local formattedChance = formatCharmChanceValue(chanceValue)
	local description = template:gsub("%%s", formattedChance)

	return description:gsub("%%%%", "%%")
end

local function resolveWireCharmId(charmIdOrData)
	if type(charmIdOrData) == "table" then
		return charmIdOrData.internalId or charmIdOrData.id or 0
	end

	return type(charmIdOrData) == "number" and charmIdOrData or 0
end

local function sendCharmAction(action, charmIdOrData, raceId)
	g_game.BuyCharmRune(action, resolveWireCharmId(charmIdOrData), action == CHARM_ACTION.SELECT and (raceId or 0) or 0)
end

function Cyclopedia.sendCharmAction(action, charmIdOrData, raceId)
	sendCharmAction(action, charmIdOrData, raceId)
end

function Cyclopedia.isCharmUnlocked(data)
	return isCharmUnlocked(data)
end

function Cyclopedia.getCharmDefinition(clientId)
	return charms[clientId]
end

function Cyclopedia.isCreatureCharmAssignable(raceId, charmCategory)
	for _, creature in ipairs(Cyclopedia.Charms.SelectableCreatures or {}) do
		if creature.raceId == raceId then
			return isCreatureSelectableForCharm(creature, charmCategory)
		end
	end

	return false
end

local function formatCharmsData(charmsData)
	local formattedData = {}

	for _, charmData in ipairs(charmsData.charms or {}) do
		charmData.serverId = charmData.id

		local internalId = toClientCharmId(charmData.id)

		if internalId ~= nil then
			local charm = charms[internalId]

			charmData.id = internalId
			charmData.name = charmData.name ~= "" and charmData.name or charm.name

			local tierDescription = resolveCharmDescriptionForTier(charmData, charm)

			charmData.description = tierDescription or charmData.description ~= "" and charmData.description or charm.description
			charmData.internalId = internalId
			charmData.typePriority = charm.type
			charmData.category = charm.category

			table.insert(formattedData, charmData)
		else
			g_logger.warning(string.format("Cyclopedia.loadCharms - unknown server charm id: %s", tostring(charmData.serverId)))
		end
	end

	table.sort(formattedData, function(a, b)
		local tierA, tierB = a.tier or 0, b.tier or 0

		if tierA ~= tierB then
			return tierB < tierA
		end

		return a.name:lower() < b.name:lower()
	end)

	return formattedData
end

function Cyclopedia.applyCharmsData(charmsData)
	local selectableCreatures = charmsData.selectableCreatures or {}

	-- This engine exposes the server's finished-monster race ids directly.
	-- The ported UI expects richer selectable-creature records instead.
	if #selectableCreatures == 0 then
		for _, raceId in ipairs(charmsData.finishedMonsters or {}) do
			table.insert(selectableCreatures, {
				raceId = raceId,
				showInMajorListState = true,
				showInMinorListState = true,
				monsterMinorState = 1
			})
		end
	end

	Cyclopedia.Charms.SelectableCreatures = selectableCreatures
	Cyclopedia.Charms.resetAllCharmsCost = tonumber(charmsData.resetAllCharmsCost) or 0
	Cyclopedia.Charms.List = formatCharmsData(charmsData)
	Cyclopedia.Charms.points = charmsData.points

	if Cyclopedia.refreshBestiaryCharmUI then
		Cyclopedia.refreshBestiaryCharmUI()
	end
end

local function getCharmSearchPanel()
	if not UI then
		return nil
	end

	return UI.InformationBase.PanelCreatureList
end

local charmCreatureListKeyHandlers

local function unbindCharmCreatureListKeys()
	if not charmCreatureListKeyHandlers then
		return
	end

	local panel = charmCreatureListKeyHandlers.panel

	if panel and not panel:isDestroyed() then
		g_keyboard.unbindKeyPress("Up", charmCreatureListKeyHandlers.up, panel)
		g_keyboard.unbindKeyPress("Down", charmCreatureListKeyHandlers.down, panel)
	end

	charmCreatureListKeyHandlers = nil
end

local function focusCharmCreatureEntry(creatureList, widget)
	if not widget or widget:isDestroyed() or not widget:isEnabled() then
		return
	end

	creatureList:focusChild(widget, KeyboardFocusReason)
	creatureList:ensureChildVisible(widget)
	Cyclopedia.selectCreatureCharm(widget, true)
end

local function navigateCharmCreatureList(creatureList, direction)
	if not creatureList or creatureList:isDestroyed() or creatureList:getChildCount() == 0 then
		return
	end

	local focused = creatureList:getFocusedChild()

	if not focused then
		local index = direction < 0 and creatureList:getChildCount() or 1

		focusCharmCreatureEntry(creatureList, creatureList:getChildByIndex(index))

		return
	end

	if direction < 0 then
		creatureList:focusPreviousChild(KeyboardFocusReason)
	else
		creatureList:focusNextChild(KeyboardFocusReason)
	end

	focused = creatureList:getFocusedChild()

	if focused and focused:isEnabled() then
		focusCharmCreatureEntry(creatureList, focused)
	end
end

local function bindCharmCreatureListKeys(panel, creatureList)
	unbindCharmCreatureListKeys()

	if not panel or panel:isDestroyed() or not creatureList or creatureList:isDestroyed() then
		return
	end

	if creatureList:getChildCount() == 0 then
		return
	end

	local function onUp()
		navigateCharmCreatureList(creatureList, -1)
	end

	local function onDown()
		navigateCharmCreatureList(creatureList, 1)
	end

	g_keyboard.bindKeyPress("Up", onUp, panel)
	g_keyboard.bindKeyPress("Down", onDown, panel)

	charmCreatureListKeyHandlers = {
		panel = panel,
		up = onUp,
		down = onDown
	}

	if panel.SearchEdit and not panel.SearchEdit:isDestroyed() then
		function panel.SearchEdit.onKeyDown(widget, keyCode)
			if keyCode == KeyDown and creatureList:getChildCount() > 0 then
				focusCharmCreatureEntry(creatureList, creatureList:getChildByIndex(1))

				return true
			end

			return false
		end
	end
end

local function isCharmSearchAllowed()
	return Cyclopedia.Charms.searchAllowed ~= false
end

local function updateCharmSearchClearButton()
	local panel = getCharmSearchPanel()

	if not panel then
		return
	end

	local edit = panel.SearchEdit
	local btn = panel.SearchClearButton

	if not edit or not btn then
		return
	end

	btn:setEnabled(isCharmSearchAllowed())
end

local function resetCharmSearchText()
	Cyclopedia.Charms.searchFrozenText = ""

	local panel = getCharmSearchPanel()

	if not panel or not panel.SearchEdit then
		return
	end

	local edit = panel.SearchEdit

	if (edit:getText() or "") ~= "" then
		edit:setText("")
	end

	updateCharmSearchClearButton()
end

local function setCharmSearchAllowed(allowed)
	Cyclopedia.Charms.searchAllowed = allowed

	local panel = getCharmSearchPanel()

	if not panel or not panel.SearchEdit then
		return
	end

	local edit = panel.SearchEdit

	if not allowed then
		Cyclopedia.Charms.searchFrozenText = edit:getText() or ""
	end

	edit:setEnabled(allowed)
	edit:setFocusable(allowed)
	edit:setOpacity(1)

	if not allowed and edit:isFocused() then
		local parent = edit:getParent()

		if parent and parent.focus then
			parent:focus()
		end
	end

	updateCharmSearchClearButton()
end

function showCharms()
	onTerminateCharm()

	UI = g_ui.loadUI("charms", contentContainer)

	UI:show()

	Cyclopedia.Charms.searchAllowed = true
	Cyclopedia.Charms.searchFrozenText = ""
	Cyclopedia.Charms.suppressCharmSelection = false

	g_game.requestBestiary()
	controllerCyclopedia.ui.MajorCharmsBase:setVisible(true)
	controllerCyclopedia.ui.MinorCharmsBase:setVisible(true)
	controllerCyclopedia.ui.GoldBase:setVisible(true)
	controllerCyclopedia.ui.BestiaryTrackerButton:setVisible(false)

	TypeCharmRadioGroup = UIRadioGroup.create()

	TypeCharmRadioGroup:addWidget(UI.mainPanelCharmsType.typeCharmPanel.MajorCharms)
	TypeCharmRadioGroup:addWidget(UI.mainPanelCharmsType.typeCharmPanel.MinorCharms)
	TypeCharmRadioGroup:selectWidget(TypeCharmRadioGroup:getFirstWidget())
	connect(TypeCharmRadioGroup, {
		onSelectionChange = onTypeCharmRadioGroup
	})
	updateCharmSearchClearButton()
	updateResetAllCharmsCostDisplay()
end

-- the charm panels (MajorCharmsBase/MinorCharmsBase/GoldBase) hang off the MAIN cyclopedia window,
-- not the contentContainer cleared on tab change - they have to be hidden manually,
-- otherwise they "leak" onto the next tab
function Cyclopedia.clearCharmsUI()
	if not controllerCyclopedia or not controllerCyclopedia.ui then
		return
	end

	local ui = controllerCyclopedia.ui

	-- BestiaryTrackerButton leaks the same way (bestiary enables it, nobody disables it)
	for _, id in ipairs({ "MajorCharmsBase", "MinorCharmsBase", "GoldBase", "BestiaryTrackerButton" }) do
		local panel = ui[id]

		if panel and not panel:isDestroyed() then
			panel:setVisible(false)
		end
	end

	if TypeCharmRadioGroup then
		disconnect(TypeCharmRadioGroup, {
			onSelectionChange = onTypeCharmRadioGroup
		})
		TypeCharmRadioGroup:destroy()

		TypeCharmRadioGroup = nil
	end
end

function onTerminateCharm()
	unbindCharmCreatureListKeys()

	if TypeCharmRadioGroup then
		disconnect(TypeCharmRadioGroup, {
			onSelectionChange = onTypeCharmRadioGroup
		})

		for i = #TypeCharmRadioGroup.widgets, 1, -1 do
			local widget = TypeCharmRadioGroup.widgets[i]

			if widget and not widget:isDestroyed() then
				widget.onClick = nil
			end
		end

		TypeCharmRadioGroup.widgets = {}
		TypeCharmRadioGroup.selectedWidget = nil

		TypeCharmRadioGroup:destroy()

		TypeCharmRadioGroup = nil
	end

	if UI then
		if UI.InformationBase then
			UI.InformationBase.data = nil
		end

		if not UI:isDestroyed() then
			UI:destroy()
		end

		UI = nil
	end
end

function Cyclopedia.CreateCharmItem(data)
	local CharmList = UI.mainPanelCharmsType.panelCharmList.CharmList.charmListGrid
	local widget = g_ui.createWidget("CharmItem", CharmList)
	local value = widget.PriceBase.Value

	widget:setId(tostring(data.id))
	widget.charmBase.image:setImageSource("/game_cyclopedia/images/charms/monster-bonus-effects")

	if data.id ~= nil then
		widget.charmBase.image:setImageClip(data.id * 32 .. " 0 32 32")
	else
		g_logger.error(string.format("Cyclopedia.CreateCharmItem - charm %s is nil", data.id))

		return
	end

	local charmData = charms[data.id]

	widget:setText(charmData.name)

	widget.data = data

	if data.asignedStatus then
		if data.raceId then
			local raceData = g_things.getRaceData(data.raceId)

			widget.InfoBase.Sprite:setOutfit(raceData.outfit)
			widget.InfoBase.Sprite:getCreature():setStaticWalking(1000)
		else
			g_logger.error("Cyclopedia.CreateCharmItem - no race id provided")
		end
	end

	local isUnlocked = isCharmUnlocked(data)

	widget.charmBase.lockedMask:setVisible(not isUnlocked)

	widget.icon = isUnlocked and 1 or 0

	if isUnlocked then
		widget.PriceBase.Value:setText(data.asignedStatus and comma_value(data.removeRuneCost) or 0)
	else
		widget.PriceBase.Value:setText(comma_value(data.unlockPrice))
	end

	local player = g_game.getLocalPlayer()

	if widget.icon == 1 and data.asignedStatus and player then
		local canAfford = canAffordGoldCost(player, data.removeRuneCost)

		value:setColor(canAfford and "#C0C0C0" or "#D33C3C")
	elseif widget.icon == 0 then
		local canAfford = data.unlockPrice <= UI.CharmsPoints

		value:setColor(canAfford and "#C0C0C0" or "#D33C3C")
	end

	widget.category = charmData.category

	if data.tier > 0 then
		widget.charmBase.border:setImageSource("/game_cyclopedia/images/charms/border/backdrop_charmgrade" .. data.tier)
	end
end

local function findVisibleCharmWidget(charmList, preferredClientId)
	if preferredClientId ~= nil then
		local widget = charmList:getChildById(tostring(preferredClientId))

		if widget and widget:isVisible() then
			return widget
		end
	end

	for _, child in ipairs(charmList:getChildren()) do
		if child:isVisible() then
			return child
		end
	end

	return nil
end

local function selectCharmWidget(widget)
	if not widget then
		return
	end

	local charmList = widget:getParent()

	Cyclopedia.Charms.suppressCharmSelection = true

	for _, child in ipairs(charmList:getChildren()) do
		child:setChecked(child == widget)
	end

	Cyclopedia.Charms.suppressCharmSelection = false

	Cyclopedia.selectCharm(widget, true)
end

function Cyclopedia.selectCharmItem(widget)
	if not widget or widget:isChecked() then
		return
	end

	selectCharmWidget(widget)
end

function Cyclopedia.updateCharmResourceDisplays()
	local player = g_game.getLocalPlayer()

	if not player or not controllerCyclopedia or not controllerCyclopedia.ui then
		return
	end

	local majorBase = controllerCyclopedia.ui.MajorCharmsBase
	local minorBase = controllerCyclopedia.ui.MinorCharmsBase

	if not majorBase or not minorBase then
		return
	end

	local function formatResourceBalance(resourceType, maxResourceType)
		return string.format("%s / %s", comma_value(player:getResourceBalance(resourceType)), comma_value(player:getResourceBalance(maxResourceType)))
	end

	majorBase.Value:setText(formatResourceBalance(ResourceTypes.CHARM, ResourceTypes.MAX_CHARM))
	minorBase.Value:setText(formatResourceBalance(ResourceTypes.MINOR_CHARM, ResourceTypes.MAX_MINOR_CHARM))
end

function Cyclopedia.loadCharms(charmsData)
	Cyclopedia.applyCharmsData(charmsData)

	if not UI then
		return
	end

	if not UI.mainPanelCharmsType then
		updateResetAllCharmsCostDisplay()

		return
	end

	local CharmList = UI.mainPanelCharmsType.panelCharmList.CharmList.charmListGrid

	Cyclopedia.updateCharmResourceDisplays()

	UI.CharmsPoints = charmsData.points

	updateResetAllCharmsCostDisplay()
	CharmList:destroyChildren()

	local formattedData = Cyclopedia.Charms.List or {}

	for _, value in ipairs(formattedData) do
		if value and value.name and value.description and value.internalId ~= nil and value.typePriority then
			local success, error = pcall(Cyclopedia.CreateCharmItem, value)

			if not success then
				g_logger.error(string.format("Error creating charm item: %s for charm ID: %s (%s)", error, tostring(value.internalId), tostring(value.name)))
			end
		else
			g_logger.error(string.format("Incomplete charm data: ID: %s", value and tostring(value.internalId or "unknown") or "nil"))
		end
	end

	local selectedWidget = TypeCharmRadioGroup:getSelectedWidget()

	if selectedWidget then
		local charmCategory = selectedWidget:getId() == "MajorCharms" and charmCategory_t.CHARM_MAJOR or charmCategory_t.CHARM_MINOR

		for _, widget in ipairs(CharmList:getChildren()) do
			widget:setVisible(widget.category == charmCategory)
		end

		CharmList:getLayout():update()
	end

	local preferredId = Cyclopedia.Charms.redirect

	Cyclopedia.Charms.redirect = nil

	selectCharmWidget(findVisibleCharmWidget(CharmList, preferredId))
end

local function getUIBase()
	return {
		CreatureList = UI.InformationBase.PanelCreatureList.CreaturesBase.CreatureList,
		InfoBase = UI.InformationBase.panelSelectCreature.InfoBase,
		TextBase = UI.InformationBase:recursiveGetChildById("TextBase"),
		ItemBase = UI.InformationBase.ItemBase,
		PriceBase = UI.InformationBase.verticalPanelUnLockClearChram.PriceBaseGold.priceRow,
		UnlockButton = UI.InformationBase.verticalPanelUnLockClearChram.UnlockButton,
		SearchEdit = UI.InformationBase.PanelCreatureList.SearchEdit,
		SearchLabel = UI.InformationBase.SearchLabel,
		CreaturesBase = UI.InformationBase.PanelCreatureList.CreaturesBase,
		CreaturesLabel = UI.InformationBase.panelSelectCreature.CreaturesLabel
	}
end

local function formatCreatureName(text)
	local capitalizedText = text:gsub("(%l)(%w*)", function(first, rest)
		return first:upper() .. rest
	end)

	return #capitalizedText > 19 and capitalizedText:sub(1, 16) .. "..." or capitalizedText
end

local function updateUIColors(widget, UI_BASE)
	local player = g_game.getLocalPlayer()

	if not player then
		return
	end

	local panel = UI.InformationBase.verticalPanelUnLockClearChram
	local goldValue = panel.PriceBaseGold.priceRow.Value
	local clearButton = panel.ClearCharmButton
	local charmEntry = charms[widget.data.id]

	if charmEntry and charmEntry.points and charmEntry.points[widget.data.tier + 1] then
		local selectedWidget = TypeCharmRadioGroup:getSelectedWidget()

		if selectedWidget then
			local charmCategory = selectedWidget:getId() == "MajorCharms" and ResourceTypes.CHARM or ResourceTypes.MINOR_CHARM
			local pointsValue = charmEntry.points[widget.data.tier + 1]
			local canAfford = pointsValue <= player:getResourceBalance(charmCategory)

			panel.PriceBaseCharm.priceRow.Value:setColor(canAfford and "#C0C0C0" or "#D33C3C")

			if not widget.data.asignedStatus then
				panel.UnlockButton:setEnabled(canAfford)
			end
		end
	else
		panel.PriceBaseCharm.priceRow.Value:setColor("#C0C0C0")

		if not widget.data.asignedStatus then
			panel.UnlockButton:setEnabled(false)
		end
	end

	if widget.data.asignedStatus then
		local cost = widget.data.removeRuneCost or 0

		goldValue:setText(comma_value(cost))

		local canAffordGold = canAffordGoldCost(player, cost)

		goldValue:setColor(canAffordGold and "#C0C0C0" or "#D33C3C")
		clearButton:setEnabled(true)
	else
		goldValue:setText("0")
		goldValue:setColor("#C0C0C0")
		clearButton:setEnabled(false)
	end

	setActionButtonTextColor(panel.UnlockButton)
	setActionButtonTextColor(clearButton)
	setActionButtonTextColor(UI.InformationBase and UI.InformationBase.panelSelectCreature and UI.InformationBase.panelSelectCreature.CreaturesLabel)
end

local function setupAssignedCreatureOnly(widget, UI_BASE)
	local raceId = widget.data.raceId

	if not raceId then
		return
	end

	local creatureWidget = g_ui.createWidget("CharmCreatureName", UI_BASE.CreatureList)

	creatureWidget:setText(formatCreatureName(g_things.getRaceData(raceId).name))
	creatureWidget:setEnabled(false)
	creatureWidget:setColor("#707070")

	creatureWidget.raceId = raceId

	setCharmSearchAllowed(false)
	UI_BASE.CreaturesLabel:setEnabled(false)
	setActionButtonTextColor(UI_BASE.CreaturesLabel)
end

local function setupCreatureList(widget, UI_BASE)
	if widget.data.asignedStatus then
		setupAssignedCreatureOnly(widget, UI_BASE)

		return
	end

	if not isCharmUnlocked(widget.data) then
		setCharmSearchAllowed(false)
		UI_BASE.CreaturesLabel:setEnabled(false)
		setActionButtonTextColor(UI_BASE.CreaturesLabel)

		return
	end

	UI_BASE.UnlockButton:setText("Select")

	local monsters = buildSelectableMonsterList(widget.category)
	local color = "#484848"

	for index, raceId in ipairs(monsters) do
		local creatureWidget = g_ui.createWidget("CharmCreatureName", UI_BASE.CreatureList)

		creatureWidget:setId(index)
		creatureWidget:setText(formatCreatureName(g_things.getRaceData(raceId).name))

		creatureWidget.raceId = raceId

		creatureWidget:setBackgroundColor(color)

		creatureWidget.color = color
		color = color == "#484848" and "#414141" or "#484848"
	end

	UI_BASE.UnlockButton:setEnabled(false)
	setActionButtonTextColor(UI_BASE.UnlockButton)
	setCharmSearchAllowed(true)
	UI_BASE.CreaturesLabel:setEnabled(true)
	setActionButtonTextColor(UI_BASE.CreaturesLabel)
	bindCharmCreatureListKeys(UI.InformationBase.PanelCreatureList, UI_BASE.CreatureList)
end

local function setupCharmUpgrade(widget, UI_BASE)
	local charmId = widget.data.id
	local tier = widget.data.tier or 0
	local charmEntry = charms[charmId]

	if charmEntry and charmEntry.points and charmEntry.points[tier + 1] then
		local pointsValue = charmEntry.points[tier + 1]
		local chanceValue = charmEntry.chance and charmEntry.chance[tier + 1] or 0

		UI.InformationBase.verticalPanelUnLockClearChram.PriceBaseCharm.priceRow.Value:setText(comma_value(pointsValue))

		local tierButtons = {
			[0] = "Unlock",
			[2] = string.format("Upgrade to %d%%", charmEntry.chance[3] or 0),
			string.format("Upgrade to %d%%", charmEntry.chance[2] or 0),
			[3] = "Fully Unlocked"
		}

		UI_BASE.UnlockButton:setText(tierButtons[tier])

		if tier >= 0 and tier < 3 then
			UI_BASE.UnlockButton:setEnabled(true)
			setActionButtonTextColor(UI_BASE.UnlockButton)
		end

		UI_BASE.UnlockButton:getParent().data = widget.data
	else
		UI_BASE.UnlockButton:setText("Fully Unlocked")
		UI_BASE.UnlockButton:setEnabled(false)
		setActionButtonTextColor(UI_BASE.UnlockButton)
		UI.InformationBase.verticalPanelUnLockClearChram.PriceBaseCharm.priceRow.Value:setText(comma_value(0))
	end
end

function Cyclopedia.selectCharm(widget, isChecked)
	if Cyclopedia.Charms.suppressCharmSelection then
		return
	end

	if not isChecked then
		return
	end

	local UI_BASE = getUIBase()

	UI_BASE.CreatureList:destroyChildren()

	local parent = widget:getParent()

	UI.InformationBase.data = widget.data
	Cyclopedia.Charms.suppressCharmSelection = true

	for i = 1, parent:getChildCount() do
		local internalWidget = parent:getChildByIndex(i)

		if internalWidget:isChecked() and widget:getId() ~= internalWidget:getId() then
			internalWidget:setChecked(false)
		end
	end

	widget:setChecked(true)

	Cyclopedia.Charms.suppressCharmSelection = false

	UI_BASE.TextBase:setText(widget.data.description)
	UI_BASE.ItemBase.image:setImageSource(widget.charmBase.image:getImageSource())
	UI_BASE.ItemBase.image:setImageClip(widget.charmBase.image:getImageClip())
	UI.InformationBase:setText(widget:getText())

	if isCharmUnlocked(widget.data) then
		if widget.data.tier > 0 then
			UI_BASE.ItemBase.border:setImageSource("/game_cyclopedia/images/charms/border/backdrop_charmgrade" .. widget.data.tier)
		else
			UI_BASE.ItemBase.border:setImageSource("")
		end

		UI_BASE.ItemBase.lockedMask:setVisible(false)
	else
		UI_BASE.ItemBase.lockedMask:setVisible(true)
		UI_BASE.ItemBase.border:setImageSource("")
	end

	if widget.data.asignedStatus then
		local sprite = UI_BASE.InfoBase.sprite

		sprite:setVisible(true)
		sprite:setOutfit(g_things.getRaceData(widget.data.raceId).outfit)
		sprite:getCreature():setStaticWalking(1000)
		sprite:setOpacity(1)
	else
		UI_BASE.InfoBase.sprite:setVisible(false)
	end

	updateUIColors(widget, UI_BASE)
	setupCreatureList(widget, UI_BASE)
	resetCharmSearchText()

	if not isCharmUnlocked(widget.data) then
		UI_BASE.UnlockButton:setText("Unlock")
		setCharmSearchAllowed(false)
		UI_BASE.CreaturesLabel:setEnabled(false)
		setActionButtonTextColor(UI_BASE.CreaturesLabel)
	end

	setupCharmUpgrade(widget, UI_BASE)
	updateUIColors(widget, UI_BASE)
end

function Cyclopedia.selectCreatureCharm(widget, isChecked)
	if Cyclopedia.Charms.suppressCharmSelection then
		return
	end

	if not isChecked then
		return
	end

	local UI_BASE = {
		InfoBase = UI.InformationBase.panelSelectCreature.InfoBase,
		UnlockButton = UI.InformationBase.verticalPanelUnLockClearChram.UnlockButton
	}
	local parent = widget:getParent()

	Cyclopedia.Charms.suppressCharmSelection = true

	for i = 1, parent:getChildCount() do
		local internalWidget = parent:getChildByIndex(i)

		if internalWidget:isChecked() and widget:getId() ~= internalWidget:getId() then
			internalWidget:setChecked(false)
			internalWidget:setBackgroundColor(internalWidget.color)
			internalWidget:setColor("#C0C0C0")
		end
	end

	widget:setChecked(true)
	widget:setColor("#f4f4f4")

	Cyclopedia.Charms.suppressCharmSelection = false

	UI_BASE.InfoBase.sprite:setVisible(true)
	UI_BASE.InfoBase.sprite:setOutfit(g_things.getRaceData(widget.raceId).outfit)
	UI_BASE.InfoBase.sprite:getCreature():setStaticWalking(1000)
	UI_BASE.UnlockButton:setEnabled(true)
	setActionButtonTextColor(UI_BASE.UnlockButton)

	Cyclopedia.Charms.SelectedCreature = widget.raceId
end

function Cyclopedia.onCharmSearchTextChange(text)
	if not isCharmSearchAllowed() then
		local panel = getCharmSearchPanel()

		if panel and panel.SearchEdit then
			local frozen = Cyclopedia.Charms.searchFrozenText or ""

			if panel.SearchEdit:getText() ~= frozen then
				panel.SearchEdit:setText(frozen)
			end
		end

		return
	end

	Cyclopedia.Charms.searchFrozenText = text

	Cyclopedia.searchCharmMonster(text)
	updateCharmSearchClearButton()
end

function Cyclopedia.clearCharmSearch()
	local panel = getCharmSearchPanel()

	if not panel then
		return
	end

	local edit = panel.SearchEdit

	if not edit or not isCharmSearchAllowed() then
		return
	end

	edit:setText("")
	Cyclopedia.searchCharmMonster("")
	updateCharmSearchClearButton()
end

function Cyclopedia.searchCharmMonster(text)
	local data = UI.InformationBase.data

	if not data or data.asignedStatus or not isCharmUnlocked(data) then
		return
	end

	local creaturesBase = UI.InformationBase.PanelCreatureList.CreaturesBase

	creaturesBase.CreatureList:destroyChildren()

	local function format(string)
		local capitalizedText = string:gsub("(%l)(%w*)", function(first, rest)
			return first:upper() .. rest
		end)

		if #capitalizedText > 19 then
			return capitalizedText:sub(1, 16) .. "..."
		else
			return capitalizedText
		end
	end

	local function getColor(currentColor)
		return currentColor == "#484848" and "#414141" or "#484848"
	end

	local charmCategory = UI.InformationBase.data and UI.InformationBase.data.category or charmCategory_t.CHARM_MAJOR
	local monsters = buildSelectableMonsterList(charmCategory)
	local searchedMonsters = {}

	if text ~= "" then
		for _, raceId in ipairs(monsters) do
			local name = g_things.getRaceData(raceId).name

			if string.find(name:lower(), text:lower()) then
				table.insert(searchedMonsters, raceId)
			end
		end
	else
		searchedMonsters = monsters
	end

	local color = "#484848"

	for _, raceId in ipairs(searchedMonsters) do
		local internalWidget = g_ui.createWidget("CharmCreatureName", creaturesBase.CreatureList)

		internalWidget:setId(raceId)
		internalWidget:setText(format(g_things.getRaceData(raceId).name))

		internalWidget.raceId = raceId

		internalWidget:setBackgroundColor(color)

		internalWidget.color = color
		color = getColor(color)
	end

	local panel = getCharmSearchPanel()

	if panel then
		bindCharmCreatureListKeys(panel, creaturesBase.CreatureList)
	end
end

function Cyclopedia.resetAllCharms()
	local cost = tonumber(Cyclopedia.Charms.resetAllCharmsCost) or 0
	local returnCharmId = UI and UI.InformationBase and UI.InformationBase.data and UI.InformationBase.data.id or nil
	local confirmWindow

	local function yesCallback()
		sendCharmAction(CHARM_ACTION.RESET_ALL)

		if confirmWindow then
			confirmWindow:destroy()

			confirmWindow = nil
		end

		if show then
			Cyclopedia.Charms.redirect = returnCharmId

			show("charms")
		end
	end

	local function noCallback()
		if confirmWindow then
			confirmWindow:destroy()

			confirmWindow = nil
		end

		if show then
			Cyclopedia.Charms.redirect = returnCharmId

			show("charms")
		end
	end

	if not confirmWindow then
		if hide then
			hide()
		end

		confirmWindow = displayGeneralBox(tr("Confirm Reset of Charms"), tr("Do you want to reset all Charms? This will cost you %s gold?", comma_value(cost)), {
			{
				text = tr("No"),
				callback = noCallback
			},
			{
				text = tr("Yes"),
				callback = yesCallback
			},
			anchor = AnchorHorizontalCenter
		}, yesCallback, noCallback)
	end
end

function Cyclopedia.actionCharmButton(widget)
	local confirmWindow
	local type = widget:getText()
	local data = widget:getParent().data
	local charmEntry = charms[data.id]
	local tier = data.tier or 0
	local charmPointsCost = data.unlockPrice or 0

	if charmEntry and charmEntry.points and charmEntry.points[tier + 1] then
		charmPointsCost = charmEntry.points[tier + 1]
	end

	if type == "Unlock" then
		local function yesCallback()
			sendCharmAction(CHARM_ACTION.UPGRADE, data)

			if confirmWindow then
				confirmWindow:destroy()

				confirmWindow = nil
			end

			Cyclopedia.Charms.redirect = data.id

			if show then
				show("charms")
			end
		end

		local function noCallback()
			if confirmWindow then
				confirmWindow:destroy()

				confirmWindow = nil
			end

			if show then
				Cyclopedia.Charms.redirect = data.id

				show("charms")
			end
		end

		if not confirmWindow then
			if hide then
				hide()
			end

			confirmWindow = displayGeneralBox(tr("Confirm Unlocking of Charm"), tr("Do you want to unlock the Charm %s? This will cost you %d Charm Points?", data.name, charmPointsCost), {
				{
					text = tr("No"),
					callback = noCallback
				},
				{
					text = tr("Yes"),
					callback = yesCallback
				},
				anchor = AnchorHorizontalCenter
			}, yesCallback, noCallback)
		end
	end

	if type == "Select" or type == "Select Creature" then
		local function yesCallback()
			sendCharmAction(CHARM_ACTION.SELECT, data, Cyclopedia.Charms.SelectedCreature)

			if confirmWindow then
				confirmWindow:destroy()

				confirmWindow = nil
			end

			Cyclopedia.Charms.redirect = data.id

			if show then
				show("charms")
			end
		end

		local function noCallback()
			if confirmWindow then
				confirmWindow:destroy()

				confirmWindow = nil
			end

			if show then
				Cyclopedia.Charms.redirect = data.id

				show("charms")
			end
		end

		if not confirmWindow then
			if hide then
				hide()
			end

			confirmWindow = displayGeneralBox(tr("Confirm Selected Charm"), tr("Do you want to use the Charm %s for this creature?", data.name), {
				{
					text = tr("No"),
					callback = noCallback
				},
				{
					text = tr("Yes"),
					callback = yesCallback
				},
				anchor = AnchorHorizontalCenter
			}, yesCallback, noCallback)
		end
	end

	if type:match("^Upgrade") then
		local function yesCallback()
			sendCharmAction(CHARM_ACTION.UPGRADE, data)

			if confirmWindow then
				confirmWindow:destroy()

				confirmWindow = nil
			end

			Cyclopedia.Charms.redirect = data.id

			if show then
				show("charms")
			end
		end

		local function noCallback()
			if confirmWindow then
				confirmWindow:destroy()

				confirmWindow = nil
			end

			if show then
				Cyclopedia.Charms.redirect = data.id

				show("charms")
			end
		end

		if not confirmWindow then
			if hide then
				hide()
			end

			confirmWindow = displayGeneralBox(tr("Confirm Unlocking of Charm"), tr("Do you want to upgrade the Charm %s? This will cost you %d Charm Points?", data.name, charmPointsCost), {
				{
					text = tr("No"),
					callback = noCallback
				},
				{
					text = tr("Yes"),
					callback = yesCallback
				},
				anchor = AnchorHorizontalCenter
			}, yesCallback, noCallback)
		end
	end
end

function onTypeCharmRadioGroup(radioGroup, selectedWidget)
	local charmCategory = selectedWidget:getId() == "MajorCharms" and charmCategory_t.CHARM_MAJOR or charmCategory_t.CHARM_MINOR
	local CharmList = UI.mainPanelCharmsType.panelCharmList.CharmList.charmListGrid

	if charmCategory == charmCategory_t.CHARM_MAJOR then
		UI.InformationBase.verticalPanelUnLockClearChram.PriceBaseCharm.priceRow.Charm:setImageSource("/game_cyclopedia/images/monster-icon-bonuspoints")
	else
		UI.InformationBase.verticalPanelUnLockClearChram.PriceBaseCharm.priceRow.Charm:setImageSource("/game_cyclopedia/images/minor-charm-echoes")
	end

	for _, widget in ipairs(CharmList:getChildren()) do
		if widget.category == charmCategory then
			widget:setVisible(true)
		else
			widget:setVisible(false)
		end
	end

	CharmList:getLayout():update()

	local currentId = UI.InformationBase.data and UI.InformationBase.data.id
	local current = currentId and CharmList:getChildById(tostring(currentId))

	if not current or not current:isVisible() then
		selectCharmWidget(findVisibleCharmWidget(CharmList))
	end
end

function Cyclopedia.refreshCharmAffordability()
	updateResetAllCharmsCostDisplay()

	if not UI or not UI.InformationBase or not UI.InformationBase.data then
		return
	end

	local charmList = UI.mainPanelCharmsType.panelCharmList.CharmList.charmListGrid
	local widget = charmList:getChildById(tostring(UI.InformationBase.data.id))

	if widget then
		updateUIColors(widget, getUIBase())
	end
end

function Cyclopedia.actionClearCharmButton(widget)
	local data = UI.InformationBase.data

	if not data or not data.asignedStatus then
		return
	end

	local confirmWindow

	local function yesCallback()
		if confirmWindow then
			confirmWindow:destroy()

			confirmWindow = nil
		end

		scheduleEvent(function()
			Cyclopedia.Charms.redirect = data.id

			sendCharmAction(CHARM_ACTION.CLEAR, data)

			if show then
				show("charms")
			end
		end, 50)
	end

	local function noCallback()
		if confirmWindow then
			confirmWindow:destroy()

			confirmWindow = nil
		end

		if show then
			Cyclopedia.Charms.redirect = data.id

			show("charms")
		end
	end

	if hide then
		hide()
	end

	confirmWindow = displayGeneralBox(tr("Confirm Charm Removal"), tr("Do you want to remove the Charm %s from this creature? This will cost you %s gold pieces.", data.name, comma_value(data.removeRuneCost or 0)), {
		{
			text = tr("No"),
			callback = noCallback
		},
		{
			text = tr("Yes"),
			callback = yesCallback
		},
		anchor = AnchorHorizontalCenter
	}, yesCallback, noCallback)
end

function Cyclopedia.actionSelectCharmButton(widget)
	local confirmWindow
	local type = widget:getText()
	local data = UI.InformationBase.data

	if type == "Select" or type == "Select Creature" then
		local function yesCallback()
			sendCharmAction(CHARM_ACTION.SELECT, data, Cyclopedia.Charms.SelectedCreature)

			if confirmWindow then
				confirmWindow:destroy()

				confirmWindow = nil
			end

			Cyclopedia.Charms.redirect = data.id

			if show then
				show("charms")
			end
		end

		local function noCallback()
			if confirmWindow then
				confirmWindow:destroy()

				confirmWindow = nil
			end

			if show then
				Cyclopedia.Charms.redirect = data.id

				show("charms")
			end
		end

		if not confirmWindow then
			if hide then
				hide()
			end

			confirmWindow = displayGeneralBox(tr("Confirm Selected Charm"), tr("Do you want to use the Charm %s for this creature?", data.name), {
				{
					text = tr("No"),
					callback = noCallback
				},
				{
					text = tr("Yes"),
					callback = yesCallback
				},
				anchor = AnchorHorizontalCenter
			}, yesCallback, noCallback)
		end
	end
end

function Cyclopedia.buyCharmExpansion()
	hide()

	if modules.game_store and modules.game_store.openUsefulThings then
		modules.game_store.openUsefulThings(StoreConst.CharmExpansion)
	else
		g_game.openStore()
		scheduleEvent(function()
			g_game.sendRequestUsefulThings(StoreConst.CharmExpansion)
		end, 250)
	end
end

function Cyclopedia.buyCharmPoints()
	hide()

	if modules.game_store and modules.game_store.openCharmPoints then
		modules.game_store.openCharmPoints()
	elseif modules.game_store and modules.game_store.openOfferById then
		modules.game_store.openOfferById(StoreConst.MajorCharmPoints)
	else
		g_game.openStore()
		scheduleEvent(function()
			g_game.sendRequestStoreOfferById(StoreConst.MajorCharmPoints)
		end, 250)
	end
end
