-- chunkname: @/game_helper/helper_posture.lua

HelperPosture = HelperPosture or {}

local ctx
local STANCE_SELECTION_ORDER = {
	"stance",
	"elemental",
	"crippling",
	"virtue"
}
local STANCE_SELECTION_KEYS = {
	elemental = true,
	stance = true,
	virtue = true,
	crippling = true
}
local STANCE_VOCATION_KEYS = {
	"sorcerer",
	"druid",
	"paladin",
	"knight",
	"sorcerer",
	"druid",
	"paladin",
	"knight",
	"monk",
	"monk"
}
local STANCE_DEFINITIONS = {
	knight = {
		{
			key = "stance",
			label = "Stance",
			names = {
				"Blood Rage",
				"Protector"
			}
		}
	},
	paladin = {
		{
			key = "stance",
			label = "Stance",
			names = {
				"Sharpshooter",
				"Divine Defiance"
			}
		}
	},
	sorcerer = {
		{
			key = "elemental",
			label = "Elemental",
			names = {
				"Master of Flames",
				"Master of Thunder",
				"Master of Decay"
			}
		},
		{
			key = "crippling",
			label = "Crippling",
			names = {
				"Aura of Sapped Strength",
				"Aura of Exposed Weakness"
			}
		}
	},
	druid = {
		{
			key = "stance",
			label = "Stance",
			names = {
				"Elemental Synthesis",
				"Shared Conservation"
			}
		}
	},
	monk = {
		{
			key = "virtue",
			label = "Virtue",
			names = {
				"Virtue of Harmony",
				"Virtue of Justice",
				"Virtue of Sustain"
			}
		}
	}
}
local DEFAULT_STANCE_EXHAUSTION_MS = 1000
local GLOBAL_POSTURE_CAST_LOCK_MS = 500
local selection = {
	elemental = "",
	stance = "",
	virtue = "",
	crippling = ""
}
local castRequests = {}
local stanceCooldowns = {}
local nextCastAt = 0
local virtueBorderConnected = false

local function nowMs()
	if g_clock and type(g_clock.millis) == "function" then
		return g_clock.millis()
	end

	return 0
end

local function normalizeKey(value)
	return tostring(value or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
end

local function safeCall(obj, method, ...)
	if not obj or type(obj[method]) ~= "function" then
		return nil
	end

	local ok, result = pcall(obj[method], obj, ...)

	if ok then
		return result
	end

	return nil
end

local function getPlayer()
	return g_game and g_game.getLocalPlayer and g_game.getLocalPlayer() or nil
end

local function resolvePlayerVocation(player)
	player = player or getPlayer()

	local rawVocation = tonumber(safeCall(player, "getVocation")) or 0

	-- This server already sends the Helper vocation ids directly. In
	-- particular, raw id 5 is Sorcerer here (the official translator would
	-- incorrectly turn it into Monk).
	if rawVocation >= 5 and rawVocation <= 10 then
		return rawVocation, rawVocation
	end

	if type(translateVocation) == "function" then
		local ok, vocation = pcall(translateVocation, rawVocation)

		vocation = tonumber(vocation) or 0

		if ok and vocation > 0 then
			return vocation, rawVocation
		end
	end

	if ctx and type(ctx.getPlayerVoc) == "function" then
		local vocation = tonumber(ctx.getPlayerVoc()) or 0

		if vocation > 0 then
			return vocation, rawVocation
		end
	end

	return rawVocation, rawVocation
end

local function playerVocationKey(player)
	local vocation = resolvePlayerVocation(player)

	return STANCE_VOCATION_KEYS[vocation]
end

local function resolveStanceSpell(name)
	if not Spells or type(Spells.getSpellByName) ~= "function" then
		return nil
	end

	local ok, spell = pcall(Spells.getSpellByName, name)

	if not ok or type(spell) ~= "table" or tostring(spell.words or "") == "" then
		return nil
	end

	return spell
end

local function normalizeSelection(value)
	local source = type(value) == "table" and value or {}
	local result = {}

	for key in pairs(STANCE_SELECTION_KEYS) do
		result[key] = tostring(source[key] or "")
	end

	return result
end

function HelperPosture.getGroups(player)
	local definitions = STANCE_DEFINITIONS[playerVocationKey(player)]
	local result = {}

	if type(definitions) ~= "table" then
		return result
	end

	for _, groupDef in ipairs(definitions) do
		local group = {
			key = tostring(groupDef.key or "stance"),
			label = tostring(groupDef.label or "Stance"),
			spells = {}
		}

		for _, name in ipairs(groupDef.names or {}) do
			local spell = resolveStanceSpell(name)

			if spell then
				group.spells[#group.spells + 1] = spell
			end
		end

		if #group.spells > 0 then
			result[#result + 1] = group
		end
	end

	return result
end

function HelperPosture.hasGroups(player)
	return #HelperPosture.getGroups(player) > 0
end

function HelperPosture.getSelection(groupKey)
	groupKey = tostring(groupKey or "")

	if not STANCE_SELECTION_KEYS[groupKey] then
		return ""
	end

	selection = normalizeSelection(selection)

	return tostring(selection[groupKey] or "")
end

local function findStance(groupKey, words, player)
	local needle = normalizeKey(words)

	if needle == "" then
		return nil
	end

	for _, group in ipairs(HelperPosture.getGroups(player)) do
		if group.key == groupKey then
			for _, spell in ipairs(group.spells or {}) do
				if normalizeKey(spell.words) == needle or normalizeKey(spell.name) == needle then
					return spell
				end
			end
		end
	end

	return nil
end

local function saveConfigIfReady()
	if ctx and ctx.isLoadingConfig and ctx.isLoadingConfig() then
		return
	end

	if ctx and ctx.saveConfig then
		ctx.saveConfig()
	end
end

local function syncActionBarBorders()
	local actionBar = modules and modules.game_actionbar

	if not actionBar or type(actionBar.setManagedVirtueYellowBorderSpellIds) ~= "function" then
		return
	end

	selection = normalizeSelection(selection)

	local selectedIds = {}
	local managedIds = {}

	for _, group in ipairs(HelperPosture.getGroups()) do
		local selectedWords = normalizeKey(selection[group.key] or "")

		for _, spell in ipairs(group.spells or {}) do
			local spellId = tonumber(spell.id)

			if spellId then
				managedIds[#managedIds + 1] = spellId

				if selectedWords ~= "" and normalizeKey(spell.words) == selectedWords then
					selectedIds[#selectedIds + 1] = spellId
				end
			end
		end
	end

	actionBar.setManagedVirtueYellowBorderSpellIds(selectedIds, managedIds)
end

local function resolveOfficialBorderSpellId(incomingId)
	local spellId = tonumber(incomingId)

	if not spellId then
		return nil
	end

	if Spells and type(Spells.getSpellDataById) == "function" then
		local ok, spell = pcall(Spells.getSpellDataById, spellId)

		if ok and type(spell) == "table" then
			return tonumber(spell.id) or spellId
		end
	end

	return spellId
end

local function onOfficialVirtuesYellowBorder(spellIds)
	local groups = HelperPosture.getGroups()

	if #groups == 0 then
		return
	end

	local activeIds = {}

	local function includeSpellId(incomingId)
		local spellId = resolveOfficialBorderSpellId(incomingId)

		if spellId then
			activeIds[spellId] = true
		end
	end

	if type(spellIds) == "table" then
		for _, incomingId in ipairs(spellIds) do
			includeSpellId(incomingId)
		end
	elseif type(spellIds) == "number" then
		includeSpellId(spellIds)
	end

	selection = normalizeSelection(selection)

	local changed = false

	for _, group in ipairs(groups) do
		local officialWords = ""

		for _, spell in ipairs(group.spells or {}) do
			if activeIds[tonumber(spell.id)] then
				officialWords = tostring(spell.words or "")

				break
			end
		end

		if normalizeKey(selection[group.key]) ~= normalizeKey(officialWords) then
			selection[group.key] = officialWords
			castRequests[group.key] = nil
			changed = true
		end
	end

	syncActionBarBorders()

	if changed then
		saveConfigIfReady()
		addEvent(function()
			if HelperPosture.refreshUI then
				HelperPosture.refreshUI()
			end
		end)
	end
end

function HelperPosture.setSelection(groupKey, words, persist)
	groupKey = tostring(groupKey or "")

	if not STANCE_SELECTION_KEYS[groupKey] then
		return false
	end

	selection = normalizeSelection(selection)
	words = tostring(words or "")

	if normalizeKey(words) == "" then
		selection[groupKey] = ""
		castRequests[groupKey] = nil

		syncActionBarBorders()

		if persist ~= false then
			saveConfigIfReady()
		end

		return true
	end

	local spell = findStance(groupKey, words, getPlayer())

	if not spell then
		return false
	end

	selection[groupKey] = tostring(spell.words or "")
	castRequests[groupKey] = tostring(spell.words or "")

	syncActionBarBorders()

	if persist ~= false then
		saveConfigIfReady()
	end

	return true
end

local function getStanceGroupIds(spell)
	local groups = {}

	if Spells and type(Spells.getGroupIds) == "function" then
		local ok, result = pcall(Spells.getGroupIds, spell)

		if ok and type(result) == "table" then
			return result
		end
	end

	if type(spell.group) == "table" then
		for groupId in pairs(spell.group) do
			groups[#groups + 1] = tonumber(groupId) or groupId
		end
	elseif spell.group ~= nil then
		groups[1] = tonumber(spell.group) or spell.group
	end

	return groups
end

local function resolveStanceExhaustion(spell)
	local exhaustion = tonumber(spell and spell.exhaustion)

	if exhaustion and exhaustion > 0 then
		return exhaustion
	end

	return DEFAULT_STANCE_EXHAUSTION_MS
end

local function isStanceOnCooldown(spell, now)
	local key = normalizeKey(spell and spell.words)

	if key ~= "" and now < (tonumber(stanceCooldowns[key]) or 0) then
		return true
	end

	return false
end

local function reserveStanceCooldown(spell, now)
	local key = normalizeKey(spell and spell.words)

	if key == "" then
		return
	end

	local duration = math.max(GLOBAL_POSTURE_CAST_LOCK_MS, resolveStanceExhaustion(spell))

	stanceCooldowns[key] = math.max(tonumber(stanceCooldowns[key]) or 0, now + duration)
end

local function canCastStance(player, spell)
	if not player or not spell or tostring(spell.words or "") == "" then
		return false
	end

	local now = nowMs()

	if isStanceOnCooldown(spell, now) then
		return false
	end

	if (tonumber(safeCall(player, "getLevel")) or 0) < (tonumber(spell.level) or 0) then
		return false
	end

	if (tonumber(safeCall(player, "getMana")) or 0) < (tonumber(spell.mana) or 0) then
		return false
	end

	if (tonumber(safeCall(player, "getSoul")) or 0) < (tonumber(spell.soul) or 0) then
		return false
	end

	return true
end

function HelperPosture.castPending(player, cooldownReady)
	player = player or getPlayer()

	if not player then
		return false
	end

	local now = nowMs()

	if now < nextCastAt then
		return false
	end

	for _, groupKey in ipairs(STANCE_SELECTION_ORDER) do
		-- A selected posture is persistent: cast it again whenever its own
		-- exhaustion expires. castRequests only makes a newly clicked selection
		-- eligible immediately; clearing it must not disable future renewals.
		local words = castRequests[groupKey] or selection[groupKey]

		if words and tostring(words) ~= "" then
			local spell = findStance(groupKey, words, player)

			if not spell then
				castRequests[groupKey] = nil
			elseif canCastStance(player, spell) and (not cooldownReady or cooldownReady(spell, now)) then
				if g_game and g_game.talk then
					g_game.talk(spell.words)
				end

				nextCastAt = now + GLOBAL_POSTURE_CAST_LOCK_MS
				castRequests[groupKey] = nil

				reserveStanceCooldown(spell, now)

				return true
			end
		end
	end

	return false
end

function HelperPosture.onGameStart()
	castRequests = {}
	stanceCooldowns = {}
	nextCastAt = 0

	syncActionBarBorders()

	if HelperPosture.refreshUI then
		pcall(HelperPosture.refreshUI)
	end
end

function HelperPosture.collectConfig(config)
	config.shooter = config.shooter or {}
	selection = normalizeSelection(selection)
	config.shooter.posture = {
		stance = selection.stance or "",
		elemental = selection.elemental or "",
		crippling = selection.crippling or "",
		virtue = selection.virtue or ""
	}
end

function HelperPosture.loadFromConfig(config)
	local data = config and config.shooter and config.shooter.posture or {}

	selection = normalizeSelection(data)
	castRequests = {}

	syncActionBarBorders()
end

local ICON_SIZE = 28
local postureWidgets = {}

local function clearPostureWidgets()
	for _, w in ipairs(postureWidgets) do
		if w and not w:isDestroyed() then
			w:destroy()
		end
	end

	postureWidgets = {}
end

local function stanceIconProfile()
	if type(SpelllistSettings) == "table" then
		if SpelllistSettings.Default then
			return "Default"
		end

		for profile in pairs(SpelllistSettings) do
			return profile
		end
	end

	return "Default"
end

local function applyStanceIcon(widget, spell)
	if not widget or not spell then
		return false
	end

	local profile = stanceIconProfile()
	local settings = type(SpelllistSettings) == "table" and SpelllistSettings[profile]

	if not settings then
		return false
	end

	local iconId = type(SpellIcons) == "table" and SpellIcons[spell.id] or spell.id
	local clip = Spells and Spells.getImageClip and Spells.getImageClip(iconId, profile)

	if not clip then
		return false
	end

	widget:setImageSource(settings.iconFile)
	widget:setImageClip(clip)
	widget:setImageSize(tosize(ICON_SIZE .. " " .. ICON_SIZE))

	return true
end

function HelperPosture.refreshUI()
	if not ctx or not ctx.getWidget then
		return
	end

	local panel = ctx.getWidget("posturePanel")
	local label = ctx.getWidget("postureLabel")

	if not panel then
		return
	end

	clearPostureWidgets()

	local groups = HelperPosture.getGroups()
	local vocation, rawVocation = resolvePlayerVocation(getPlayer())

	if label then
		label:setVisible(true)
	end

	panel:setVisible(true)

	if #groups == 0 then
		return
	end

	selection = normalizeSelection(selection)

	for groupIndex, group in ipairs(groups) do
		-- Keep each posture family on its own line. Sorcerer therefore shows
		-- the three elemental stances on top and the two combat auras below.
		local groupRow = g_ui.createWidget("Panel", panel)
		groupRow:mergeStyle({
			width = 110,
			height = ICON_SIZE,
			layout = {
				type = "horizontalBox",
				spacing = 8
			}
		})
		postureWidgets[#postureWidgets + 1] = groupRow

		local selectedWords = normalizeKey(selection[group.key] or "")
		local groupKey = group.key

		for _, spell in ipairs(group.spells) do
			local active = selectedWords ~= "" and normalizeKey(spell.words) == selectedWords
			local words = tostring(spell.words or "")
			local ok, err = pcall(function()
				local btn = g_ui.createWidget("HelperPostureButton", groupRow)

				btn:setPhantom(false)
				btn:setFocusable(false)
				btn:setWidth(ICON_SIZE)
				btn:setHeight(ICON_SIZE)
				applyStanceIcon(btn, spell)

				local activeSpell = btn:recursiveGetChildById("activeSpell")

				if activeSpell then
					activeSpell:setVisible(active)

					if active and activeSpell.raise then
						activeSpell:raise()
					end
				end

				btn:setTooltip(group.label .. ": " .. (spell.name or spell.words or ""))

				function btn.onMouseRelease(_, _, mouseButton)
					if mouseButton ~= MouseLeftButton then
						return false
					end

					local wasActive = active
					local changed = HelperPosture.setSelection(groupKey, wasActive and "" or words, true)

					-- A posture icon is also a direct cast button. Previously the click
					-- only queued the spell for checkMagicShooter(), so nothing happened
					-- while "Enable Shooter Helper" was unchecked. Consume the queued
					-- request and reserve its cooldown here; otherwise the Shooter tick
					-- speaks the same words a second time and toggles the aura back off.
					if changed and g_game and g_game.isOnline and g_game.isOnline() and words ~= "" then
						local castAt = nowMs()

						g_game.talk(words)
						castRequests[groupKey] = nil
						nextCastAt = math.max(nextCastAt, castAt + GLOBAL_POSTURE_CAST_LOCK_MS)
						reserveStanceCooldown(spell, castAt)
					end
					addEvent(function()
						HelperPosture.refreshUI()
					end)

					return true
				end

				-- The row owns and destroys its buttons. Keeping the child here too
				-- made refreshUI destroy the same widget twice after a click, which
				-- broke the aura selection/highlight.
			end)

			if not ok and g_logger and g_logger.info then
				g_logger.info("[Posture] icon build failed for " .. tostring(spell.name) .. ": " .. tostring(err))
			end
		end
	end
end

function HelperPosture.init(pctx)
	ctx = pctx
	selection = normalizeSelection(selection)
	castRequests = {}
	stanceCooldowns = {}
	nextCastAt = 0

	if not virtueBorderConnected and g_game then
		connect(g_game, {
			onVirtuesYellowBorder = onOfficialVirtuesYellowBorder
		})

		virtueBorderConnected = true
	end

	syncActionBarBorders()
end

function HelperPosture.terminate()
	if virtueBorderConnected and g_game then
		disconnect(g_game, {
			onVirtuesYellowBorder = onOfficialVirtuesYellowBorder
		})

		virtueBorderConnected = false
	end

	local actionBar = modules and modules.game_actionbar

	if actionBar and type(actionBar.setManagedVirtueYellowBorderSpellIds) == "function" then
		actionBar.setManagedVirtueYellowBorderSpellIds({}, {})
	end

	clearPostureWidgets()

	castRequests = {}
	stanceCooldowns = {}
	nextCastAt = 0
end
