-- chunkname: @/game_banners/game_banners.lua

bannersController = Controller:new()

local bannerQueue = {}
local isShowingBanner = false
local bannerWidget, currentBannerEntry
local animationEvents = {}
local BANNER_HOLD_MS = 3500
local BANNER_FULL_WIDTH = 355
local BANNER_HEIGHT = 105
local BANNER_BODY_WIDTH = 289
local BANNER_BODY_HEIGHT = 88
local ANIM_FRAME_MS = 50
local ICON_WIDTH = 72
local ICON_HEIGHT = 75
local ROLL_WIDTH = 21
local ROLL_HEIGHT = 105
local BACKDROP_MARGIN_LEFT = -74
local BACKDROP_MARGIN_TOP = 23
local TEXT_MARGIN_LEFT = 76
local TEXT_MARGIN_TOP = 13
local TEXT_MARGIN_RIGHT = 16
local IMAGE_BASE = "/images/game/banners/"
local SPELL_ICON_FILE = "/images/game/spells/spell-icons-32x32"
local SPELL_BORDER_ICON = "border-vocationinfo-spells"
local ANIM_FRAMES = {
	"backdrop-infobanner-anim0",
	"backdrop-infobanner-anim1",
	"backdrop-infobanner-anim2",
	"backdrop-infobanner-anim3",
	"backdrop-infobanner-anim4",
	"backdrop-infobanner-anim5",
	"backdrop-infobanner-anim6",
	"backdrop-infobanner-anim7"
}
local REVEAL_WIDTHS = {
	0,
	35,
	75,
	115,
	155,
	195,
	240,
	289
}
local CLIENT_EVENT_TYPE_SIMPLE = 1
local CLIENT_EVENT_TYPE_ACHIEVEMENT = 2
local CLIENT_EVENT_TYPE_TITLE = 3
local CLIENT_EVENT_TYPE_LEVEL = 4
local CLIENT_EVENT_TYPE_SKILL = 5
local CLIENT_EVENT_TYPE_BESTIARY = 6
local CLIENT_EVENT_TYPE_BOSSTIARY = 7
local CLIENT_EVENT_TYPE_QUEST = 8
local CLIENT_EVENT_TYPE_COSMETIC = 9
local CLIENT_EVENT_TYPE_PROFICIENCY = 10
local CLIENT_EVENT_TYPE_BOUNTY_TASK = 11
local CLIENT_EVENT_TYPE_WEEKLY_TASK = 12
local CLIENT_EVENT_TYPE_SPELL = 13
local CLIENT_EVENT_TYPE_ECHO_RAID_WARDEN = 14
local CLIENT_EVENT_TYPE_SUBAREA = 15
local CLIENT_EVENT_BOSSDEFEATED = 1
local CLIENT_EVENT_PLAYERKILLASSIST = 4
local CLIENT_EVENT_PLAYERKILL = 5
local CLIENT_EVENT_PLAYERATTACKING = 6
local CLIENT_EVENT_TREASUREFOUND = 7
local CLIENT_EVENT_GIFTOFLIFE = 8
local CLIENT_EVENT_ATTACKSTOPPED = 9
local CLIENT_EVENT_CAPACITYLIMIT = 10
local CLIENT_EVENT_OUTOFAMMO = 11
local CLIENT_EVENT_TARGETTOOCLOSE = 12
local CLIENT_EVENT_OUTOFSOULPOINTS = 13
local CLIENT_EVENT_TUTORIALCOMPLETE = 14
local COSMETIC_TYPE_ADDON = 0
local COSMETIC_TYPE_MOUNT = 1
local COSMETIC_TYPE_OUTFIT = 2
local BannerSkillTexts = {
	{
		name = "Magic Level",
		icon = "icon-infobanner-skill-magic",
		description = "Your magic level has increased."
	},
	{
		name = "Sword Fighting",
		icon = "icon-infobanner-skill-sword",
		description = "Your sword fighting skill has increased."
	},
	{
		name = "Club Fighting",
		icon = "icon-infobanner-skill-club",
		description = "Your club fighting skill has increased."
	},
	{
		name = "Axe Fighting",
		icon = "icon-infobanner-skill-axe",
		description = "Your axe fighting skill has increased."
	},
	{
		name = "Fist Fighting",
		icon = "icon-infobanner-skill-fist",
		description = "Your fist fighting skill has increased."
	},
	{
		name = "Distance Fighting",
		icon = "icon-infobanner-skill-distance",
		description = "Your distance fighting skill has increased."
	},
	{
		name = "Shielding",
		icon = "icon-infobanner-skill-shielding",
		description = "Your shielding skill has increased."
	},
	{
		name = "Fishing",
		icon = "icon-infobanner-skill-fishing",
		description = "Your fishing skill has increased."
	}
}
local SimpleEventTexts = {
	[CLIENT_EVENT_BOSSDEFEATED] = {
		title = "Boss Defeated",
		icon = "icon-infobanner-hint",
		description = "You defeated a boss creature."
	},
	[CLIENT_EVENT_PLAYERKILLASSIST] = {
		title = "Player Kill Assist",
		icon = "icon-infobanner-hint",
		description = "You assisted in defeating another player."
	},
	[CLIENT_EVENT_PLAYERKILL] = {
		title = "Player Kill",
		icon = "icon-infobanner-hint",
		description = "You defeated another player."
	},
	[CLIENT_EVENT_PLAYERATTACKING] = {
		title = "Player Attacking",
		icon = "icon-infobanner-hint",
		description = "You are attacking another player."
	},
	[CLIENT_EVENT_TREASUREFOUND] = {
		title = "Treasure Found",
		icon = "icon-infobanner-unlock",
		description = "You discovered a hidden treasure."
	},
	[CLIENT_EVENT_GIFTOFLIFE] = {
		title = "Gift of Life",
		icon = "icon-infobanner-hint",
		description = "Your Gift of Life was triggered."
	},
	[CLIENT_EVENT_ATTACKSTOPPED] = {
		title = "Stop Attack",
		icon = "icon-infobanner-hint",
		description = "Your attack has been stopped."
	},
	[CLIENT_EVENT_CAPACITYLIMIT] = {
		title = "Capacity Limit",
		icon = "icon-infobanner-hint",
		description = "You cannot carry more items."
	},
	[CLIENT_EVENT_OUTOFAMMO] = {
		title = "Out of Ammunition",
		icon = "icon-infobanner-hint",
		description = "You are out of ammunition."
	},
	[CLIENT_EVENT_TARGETTOOCLOSE] = {
		title = "Target Too Close",
		icon = "icon-infobanner-hint",
		description = "Your target is too close for a distance attack."
	},
	[CLIENT_EVENT_OUTOFSOULPOINTS] = {
		title = "Out of Soul Points",
		icon = "icon-infobanner-hint",
		description = "You do not have enough soul points."
	},
	[CLIENT_EVENT_TUTORIALCOMPLETE] = {
		title = "New Shores",
		icon = "icon-infobanner-offtonewshores",
		description = "You have reached new shores."
	}
}
local BannerTexts = {
	[CLIENT_EVENT_TYPE_ACHIEVEMENT] = {
		title = "Achievement Unlocked",
		icon = "icon-infobanner-achievements",
		description = "You have earned %s."
	},
	[CLIENT_EVENT_TYPE_TITLE] = {
		title = "New Title",
		icon = "icon-infobanner-title",
		description = "%s"
	},
	[CLIENT_EVENT_TYPE_LEVEL] = {
		title = "Level %d",
		icon = "icon-infobanner-levelup",
		description = "You gained hit points, mana, and capacity."
	},
	[CLIENT_EVENT_TYPE_BESTIARY] = {
		titleProgress = "Bestiary Progress",
		icon = "icon-infobanner-unlock",
		titleNew = "New Bestiary Entry",
		descriptionProgress = "You have progressed %s.",
		descriptionNew = "You have discovered %s."
	},
	[CLIENT_EVENT_TYPE_BOSSTIARY] = {
		titleProgress = "Bosstiary Progress",
		icon = "icon-infobanner-unlock",
		titleNew = "New Bosstiary Entry",
		descriptionProgress = "You have progressed %s.",
		descriptionNew = "You have discovered %s."
	},
	[CLIENT_EVENT_TYPE_QUEST] = {
		titleProgress = "Quest Update",
		icon = "icon-infobanner-quests",
		description = "%s",
		titleComplete = "Quest Complete"
	},
	[CLIENT_EVENT_TYPE_COSMETIC] = {
		titleMount = "New Mount",
		titleOutfit = "New Outfit",
		description = "You have unlocked %s",
		iconMount = "icon-infobanner-promotion",
		titleAddon = "New Addon",
		iconAddon = "icon-infobanner-unlock"
	},
	[CLIENT_EVENT_TYPE_PROFICIENCY] = {
		title = "Weapon Proficiency",
		icon = "icon-infobanner-hint",
		description = "You have improved %s"
	},
	[CLIENT_EVENT_TYPE_BOUNTY_TASK] = {
		title = "Task Completed",
		icon = "icon-infobanner-weeklytask",
		description = "%s"
	},
	[CLIENT_EVENT_TYPE_WEEKLY_TASK] = {
		title = "Weekly Task Completed",
		icon = "icon-infobanner-weeklytask",
		description = "%s"
	},
	[CLIENT_EVENT_TYPE_SPELL] = {
		title = "New Spell Unlocked",
		icon = "icon-infobanner-unlock",
		description = "You have unlocked a new spell: %s."
	},
	[CLIENT_EVENT_TYPE_ECHO_RAID_WARDEN] = {
		title = "Echo Warden Defeated",
		icon = "icon-infobanner-unlock",
		description = "You have received %d Charm Points."
	},
	[CLIENT_EVENT_TYPE_SUBAREA] = {
		title = "Point of Interest",
		icon = "icon-infobanner-pointofinterest",
		description = "%s"
	}
}

local function isInfoBannerEnabled()
	if not modules.client_options or not modules.client_options.getOption then
		return true
	end

	return modules.client_options.getOption("showInfoBanner") ~= false
end

local function getCreatureName(raceId)
	raceId = tonumber(raceId) or 0

	if raceId <= 0 then
		return nil
	end

	local raceData = g_things.getRaceData(raceId)

	if raceData and raceData.raceId ~= 0 and raceData.name and raceData.name ~= "" then
		return raceData.name
	end

	return nil
end

local function formatBannerTitleCase(name)
	if not name or name == "" then
		return tr("Unknown Creature")
	end

	return name:gsub("(%a)([%w']*)", function(first, rest)
		return first:upper() .. rest:lower()
	end)
end

local function formatBannerQuotedName(name)
	return "\"" .. formatBannerTitleCase(name) .. "\""
end

local function getRaceOutfit(raceId)
	raceId = tonumber(raceId) or 0

	if raceId <= 0 then
		return nil
	end

	local raceData = g_things.getRaceData(raceId)

	if raceData and raceData.raceId ~= 0 and raceData.outfit and raceData.outfit.type then
		return raceData.outfit
	end

	return nil
end

local function buildCosmeticOutfit(lookType, skinType)
	lookType = tonumber(lookType) or 0

	if lookType <= 0 then
		return nil
	end

	if skinType == COSMETIC_TYPE_MOUNT then
		return {
			type = lookType
		}
	end

	local outfit = {
		addons = 3,
		type = lookType
	}
	local player = g_game.getLocalPlayer()

	if player then
		local playerOutfit = player:getOutfit()

		outfit.head = playerOutfit.head or 0
		outfit.body = playerOutfit.body or 0
		outfit.legs = playerOutfit.legs or 0
		outfit.feet = playerOutfit.feet or 0
	end

	return outfit
end

local function getSpellBannerIconClip(spellId)
	if not SpellIcons or not Spells or not Spells.getImageClipNormal then
		return nil
	end

	local iconId = SpellIcons[spellId]

	if not iconId then
		return nil
	end

	return Spells.getImageClipNormal(iconId, "Default")
end

local function applyBannerIcon(entry)
	if not bannerWidget or bannerWidget:isDestroyed() then
		return
	end

	local bannerIcon = bannerWidget:recursiveGetChildById("bannerIcon")
	local bannerIconCreature = bannerWidget:recursiveGetChildById("bannerIconCreature")
	local bannerIconSpell = bannerWidget:recursiveGetChildById("bannerIconSpell")
	local bannerIconSpellBorder = bannerWidget:recursiveGetChildById("bannerIconSpellBorder")

	if bannerIcon and entry and entry.icon then
		bannerIcon:setImageSource(IMAGE_BASE .. entry.icon)
	end

	if bannerIconSpell then
		if entry and entry.iconSpellClip then
			bannerIconSpell:setImageSource(SPELL_ICON_FILE)
			bannerIconSpell:setImageClip(entry.iconSpellClip)
			bannerIconSpell:setVisible(true)

			if bannerIconSpellBorder then
				bannerIconSpellBorder:setImageSource(IMAGE_BASE .. SPELL_BORDER_ICON)
				bannerIconSpellBorder:setVisible(true)
			end

			if bannerIconSpellBorder then
				bannerIconSpellBorder:raise()
			end

			bannerIconSpell:raise()
		else
			bannerIconSpell:setVisible(false)

			if bannerIconSpellBorder then
				bannerIconSpellBorder:setVisible(false)
			end
		end
	end

	if not bannerIconCreature then
		return
	end

	if entry and entry.iconOutfit then
		bannerIconCreature:setVisible(true)
		bannerIconCreature:setCenter(true)
		bannerIconCreature:setFixedCreatureSize(true)
		bannerIconCreature:setBaseScale(true)
		bannerIconCreature:setIgnoreDisplacementShift(true)
		bannerIconCreature:setClipping(false)
		bannerIconCreature:setOutfit(entry.iconOutfit)

		local creature = bannerIconCreature:getCreature()

		if creature then
			creature:setStaticWalking(1000)
		end

		bannerIconCreature:raise()
	else
		bannerIconCreature:setVisible(false)
	end
end

local function cancelAnimationEvents()
	for _, eventId in ipairs(animationEvents) do
		removeEvent(eventId)
	end

	animationEvents = {}
end

local function scheduleBannerEvent(callback, delay)
	local eventId
	eventId = scheduleEvent(function()
		for index, storedId in ipairs(animationEvents) do
			if storedId == eventId then
				table.remove(animationEvents, index)

				break
			end
		end

		callback()
	end, delay)

	table.insert(animationEvents, eventId)

	return eventId
end

local function resolveBannerContent(eventType, ...)
	if eventType == CLIENT_EVENT_TYPE_SIMPLE then
		local simpleType = select(1, ...)
		local data = SimpleEventTexts[simpleType]

		if not data then
			return nil
		end

		return {
			title = data.title,
			description = data.description,
			icon = data.icon
		}
	end

	if eventType == CLIENT_EVENT_TYPE_ACHIEVEMENT then
		local name = select(1, ...) or ""
		local data = BannerTexts[eventType]

		return {
			title = data.title,
			description = string.format(data.description, formatBannerQuotedName(name)),
			icon = data.icon
		}
	end

	if eventType == CLIENT_EVENT_TYPE_TITLE then
		local name = select(1, ...) or ""
		local data = BannerTexts[eventType]

		return {
			title = data.title,
			description = string.format(data.description, name),
			icon = data.icon
		}
	end

	if eventType == CLIENT_EVENT_TYPE_LEVEL then
		local level = select(1, ...) or 0
		local data = BannerTexts[eventType]

		return {
			showOrnaments = true,
			title = string.format(data.title, level),
			description = data.description,
			icon = data.icon
		}
	end

	if eventType == CLIENT_EVENT_TYPE_SKILL then
		local skillId = select(1, ...)
		local level = select(2, ...) or 0
		local skillData = BannerSkillTexts[skillId]

		if not skillData then
			return nil
		end

		return {
			title = string.format("%s %d", skillData.name, level),
			description = skillData.description,
			icon = skillData.icon
		}
	end

	if eventType == CLIENT_EVENT_TYPE_BESTIARY or eventType == CLIENT_EVENT_TYPE_BOSSTIARY then
		local raceId = select(1, ...)
		local discovered = tonumber(select(2, ...)) or 0
		local data = BannerTexts[eventType]
		local creatureName = getCreatureName(raceId) or tr("Unknown Creature")
		local isNewEntry = discovered ~= 0
		local title = isNewEntry and data.titleNew or data.titleProgress
		local descriptionTemplate = isNewEntry and data.descriptionNew or data.descriptionProgress

		return {
			title = title,
			description = string.format(descriptionTemplate, formatBannerQuotedName(creatureName)),
			icon = data.icon,
			iconOutfit = getRaceOutfit(raceId)
		}
	end

	if eventType == CLIENT_EVENT_TYPE_QUEST then
		local questName = select(1, ...) or ""
		local completed = select(2, ...) or 0
		local data = BannerTexts[eventType]
		local title = completed ~= 0 and data.titleComplete or data.titleProgress

		return {
			title = title,
			description = string.format(data.description, questName),
			icon = data.icon
		}
	end

	if eventType == CLIENT_EVENT_TYPE_COSMETIC then
		local lookType = select(1, ...)
		local skinName = select(2, ...) or ""
		local skinType = select(3, ...) or COSMETIC_TYPE_ADDON
		local data = BannerTexts[eventType]
		local title = data.titleAddon
		local icon = data.iconAddon

		if skinType == COSMETIC_TYPE_MOUNT then
			title = data.titleMount
			icon = data.iconMount
		elseif skinType == COSMETIC_TYPE_OUTFIT then
			title = data.titleOutfit
		end

		return {
			title = title,
			description = string.format(data.description, formatBannerQuotedName(skinName)),
			icon = icon,
			iconOutfit = buildCosmeticOutfit(lookType, skinType)
		}
	end

	if eventType == CLIENT_EVENT_TYPE_PROFICIENCY then
		local itemName = select(2, ...) or ""
		local data = BannerTexts[eventType]

		return {
			title = data.title,
			description = string.format(data.description, formatBannerQuotedName(itemName)),
			icon = data.icon
		}
	end

	if eventType == CLIENT_EVENT_TYPE_BOUNTY_TASK or eventType == CLIENT_EVENT_TYPE_WEEKLY_TASK then
		local raceId = select(1, ...)
		local data = BannerTexts[eventType]
		local creatureName = getCreatureName(raceId) or tr("Unknown Creature")

		return {
			title = data.title,
			description = string.format(data.description, creatureName),
			icon = data.icon
		}
	end

	if eventType == CLIENT_EVENT_TYPE_SPELL then
		local spellId = select(1, ...) or 0
		local data = BannerTexts[eventType]
		local spellName = tr("Unknown Spell")

		if Spells and Spells.getSpellDataById then
			local spellData = Spells.getSpellDataById(spellId)

			if spellData and spellData.name then
				spellName = spellData.name
			end
		end

		return {
			title = data.title,
			description = string.format(data.description, formatBannerQuotedName(spellName)),
			icon = data.icon,
			iconSpellClip = getSpellBannerIconClip(spellId)
		}
	end

	if eventType == CLIENT_EVENT_TYPE_SUBAREA then
		local areaId = select(1, ...) or 0
		local data = BannerTexts[eventType]
		local areaName = tr("Unknown Area")

		if g_minimap and g_minimap.getCyclopediaAreaName then
			local name = g_minimap:getCyclopediaAreaName(areaId)

			if name and name ~= "" then
				areaName = name
			end
		end

		return {
			title = data.title,
			description = string.format(data.description, formatBannerQuotedName(areaName)),
			icon = data.icon
		}
	end

	if eventType == CLIENT_EVENT_TYPE_ECHO_RAID_WARDEN then
		local raceId = select(1, ...)
		local charmPoints = select(2, ...) or 0
		local data = BannerTexts[eventType]

		return {
			title = data.title,
			description = string.format(data.description, charmPoints),
			icon = data.icon,
			iconOutfit = getRaceOutfit(raceId)
		}
	end

	return nil
end

local function getBannerParent()
	if modules.game_interface and modules.game_interface.getRootPanel then
		return modules.game_interface.getRootPanel()
	end

	return rootWidget
end

local function setTextContentOpacity(opacity)
	if not bannerWidget or bannerWidget:isDestroyed() then
		return
	end

	local textPanel = bannerWidget:recursiveGetChildById("textPanel")
	local bannerTitle = bannerWidget:recursiveGetChildById("bannerTitle")

	if textPanel then
		textPanel:setOpacity(opacity)
	end

	if bannerTitle then
		bannerTitle:setOpacity(opacity)
	end
end

local function cancelTextContentFade()
	if not bannerWidget or bannerWidget:isDestroyed() then
		return
	end

	local textPanel = bannerWidget:recursiveGetChildById("textPanel")
	local bannerTitle = bannerWidget:recursiveGetChildById("bannerTitle")

	if textPanel then
		g_effects.cancelFade(textPanel)
	end

	if bannerTitle then
		g_effects.cancelFade(bannerTitle)
	end
end

local function fadeInTextContent(duration)
	if not bannerWidget or bannerWidget:isDestroyed() then
		return
	end

	local textPanel = bannerWidget:recursiveGetChildById("textPanel")
	local bannerTitle = bannerWidget:recursiveGetChildById("bannerTitle")

	if textPanel then
		g_effects.fadeIn(textPanel, duration)
	end

	if bannerTitle then
		g_effects.fadeIn(bannerTitle, duration)
	end
end

local function clearCurrentBannerEntry()
	currentBannerEntry = nil
end

local function destroyBannerWidget()
	cancelAnimationEvents()

	if bannerWidget and not bannerWidget:isDestroyed() then
		cancelTextContentFade()
		bannerWidget:destroy()
	end

	bannerWidget = nil

	clearCurrentBannerEntry()
end

local function raiseBannerStack(isAnimationPhase)
	if not bannerWidget or bannerWidget:isDestroyed() then
		return
	end

	local backdropBottom = bannerWidget:recursiveGetChildById("backdropBottom")
	local bannerClipPanel = bannerWidget:recursiveGetChildById("bannerClipPanel")
	local bannerIcon = bannerWidget:recursiveGetChildById("bannerIcon")
	local backdropMid = bannerWidget:recursiveGetChildById("backdropMid")
	local backdropTop = bannerWidget:recursiveGetChildById("backdropTop")
	local rollAnim = bannerWidget:recursiveGetChildById("rollAnim")
	local backdropOrnaments = bannerWidget:recursiveGetChildById("backdropOrnaments")
	local bannerTitle = bannerWidget:recursiveGetChildById("bannerTitle")
	local textPanel = bannerWidget:recursiveGetChildById("textPanel")

	if backdropBottom and backdropBottom:isVisible() then
		backdropBottom:raise()
	end

	if bannerClipPanel and bannerClipPanel:isVisible() then
		bannerClipPanel:raise()
	end

	if bannerIcon then
		bannerIcon:raise()
	end

	local bannerIconSpell = bannerWidget:recursiveGetChildById("bannerIconSpell")
	local bannerIconSpellBorder = bannerWidget:recursiveGetChildById("bannerIconSpellBorder")

	if bannerIconSpellBorder and bannerIconSpellBorder:isVisible() then
		bannerIconSpellBorder:raise()
	end

	if bannerIconSpell and bannerIconSpell:isVisible() then
		bannerIconSpell:raise()
	end

	local bannerIconCreature = bannerWidget:recursiveGetChildById("bannerIconCreature")

	if bannerIconCreature and bannerIconCreature:isVisible() then
		bannerIconCreature:raise()
	end

	if backdropMid and backdropMid:isVisible() then
		backdropMid:raise()
	end

	if backdropTop and backdropTop:isVisible() then
		backdropTop:raise()
	end

	if isAnimationPhase and rollAnim and rollAnim:isVisible() then
		rollAnim:raise()
	end

	if backdropOrnaments and backdropOrnaments:isVisible() then
		backdropOrnaments:raise()
	end

	if bannerTitle and bannerTitle:isVisible() then
		bannerTitle:raise()
	end

	if textPanel and textPanel:isVisible() then
		textPanel:raise()
	end
end

local function refreshBannerTextLayout()
	if not bannerWidget or bannerWidget:isDestroyed() then
		return
	end

	local textPanel = bannerWidget:recursiveGetChildById("textPanel")
	local bannerTitle = bannerWidget:recursiveGetChildById("bannerTitle")
	local bannerDescription = bannerWidget:recursiveGetChildById("bannerDescription")

	if not textPanel or not bannerTitle or not bannerDescription then
		return
	end

	local textWidth = BANNER_BODY_WIDTH - TEXT_MARGIN_LEFT - TEXT_MARGIN_RIGHT

	bannerDescription:setTextAutoResize(false)
	bannerDescription:setTextWrap(true)
	bannerDescription:setWidth(textWidth)

	local descriptionHeight = bannerDescription:getTextSize().height

	textPanel:setHeight(math.max(20, descriptionHeight + 2))
end

local function applyBannerOrnamentsLayout()
	if not bannerWidget or bannerWidget:isDestroyed() then
		return
	end

	local showOrnaments = currentBannerEntry and currentBannerEntry.showOrnaments
	local backdropOrnaments = bannerWidget:recursiveGetChildById("backdropOrnaments")
	local bannerTitle = bannerWidget:recursiveGetChildById("bannerTitle")

	if backdropOrnaments then
		backdropOrnaments:setVisible(showOrnaments == true)
	end

	if not bannerTitle then
		return
	end

	bannerTitle:breakAnchors()

	if showOrnaments then
		bannerTitle:addAnchor(AnchorHorizontalCenter, "backdropOrnaments", AnchorHorizontalCenter)
		bannerTitle:addAnchor(AnchorVerticalCenter, "backdropOrnaments", AnchorVerticalCenter)
		bannerTitle:setMarginTop(0)
	else
		bannerTitle:addAnchor(AnchorHorizontalCenter, "backdropBottom", AnchorHorizontalCenter)
		bannerTitle:addAnchor(AnchorTop, "backdropBottom", AnchorTop)
		bannerTitle:setMarginTop(10)
	end
end

local function applyAnimationFrame(frameIndex)
	if not bannerWidget or bannerWidget:isDestroyed() then
		return
	end

	local bannerClipPanel = bannerWidget:recursiveGetChildById("bannerClipPanel")
	local rollAnim = bannerWidget:recursiveGetChildById("rollAnim")

	if not bannerClipPanel or not rollAnim then
		return
	end

	local revealWidth = REVEAL_WIDTHS[frameIndex + 1] or 0
	local frameName = ANIM_FRAMES[frameIndex + 1]

	if frameName then
		rollAnim:setImageSource(IMAGE_BASE .. frameName)
	end

	rollAnim:setMarginLeft(BACKDROP_MARGIN_LEFT + revealWidth - ROLL_WIDTH)
	rollAnim:setMarginTop(BACKDROP_MARGIN_TOP)
	bannerClipPanel:setWidth(revealWidth)
	bannerClipPanel:setVisible(revealWidth > 0)
	rollAnim:setVisible(true)
	raiseBannerStack(true)
end

local function setAnimationLayersVisible(visible)
	if not bannerWidget or bannerWidget:isDestroyed() then
		return
	end

	local bannerClipPanel = bannerWidget:recursiveGetChildById("bannerClipPanel")
	local rollAnim = bannerWidget:recursiveGetChildById("rollAnim")

	if rollAnim then
		rollAnim:setVisible(visible)
	end

	if bannerClipPanel and not visible then
		bannerClipPanel:setVisible(false)
	end
end

local FINAL_BODY_LAYER_IDS = {
	"backdropBottom",
	"backdropOrnaments",
	"bannerTitle",
	"textPanel"
}
local FINAL_ICON_LAYER_IDS = {
	"backdropMid",
	"backdropTop"
}

local function setIconDecorationLayersVisible(visible)
	if not bannerWidget or bannerWidget:isDestroyed() then
		return
	end

	for _, layerId in ipairs(FINAL_ICON_LAYER_IDS) do
		local layer = bannerWidget:recursiveGetChildById(layerId)

		if layer then
			layer:setVisible(visible)
		end
	end
end

local function setFinalLayersVisible(visible)
	if not bannerWidget or bannerWidget:isDestroyed() then
		return
	end

	for _, layerId in ipairs(FINAL_BODY_LAYER_IDS) do
		local layer = bannerWidget:recursiveGetChildById(layerId)

		if layer then
			layer:setVisible(visible)
		end
	end

	if visible then
		setIconDecorationLayersVisible(true)
	end
end

local function showRollPhase(startFrame)
	if not bannerWidget or bannerWidget:isDestroyed() then
		return
	end

	setFinalLayersVisible(false)
	setIconDecorationLayersVisible(true)
	setTextContentOpacity(0)
	cancelTextContentFade()
	setAnimationLayersVisible(true)
	applyAnimationFrame(startFrame or 0)
	raiseBannerStack(true)
end

local function showFinalPhase()
	if not bannerWidget or bannerWidget:isDestroyed() then
		return
	end

	local bannerClipPanel = bannerWidget:recursiveGetChildById("bannerClipPanel")
	local rollAnim = bannerWidget:recursiveGetChildById("rollAnim")

	if bannerClipPanel then
		bannerClipPanel:setWidth(BANNER_BODY_WIDTH)
		bannerClipPanel:setVisible(true)
	end

	setFinalLayersVisible(true)
	applyBannerOrnamentsLayout()
	refreshBannerTextLayout()
	raiseBannerStack(false)

	if rollAnim then
		rollAnim:setVisible(false)
	end

	if bannerClipPanel then
		bannerClipPanel:setVisible(false)
	end
end

local function playRollSequence(fromIndex, toIndex, onComplete)
	local step = fromIndex <= toIndex and 1 or -1
	local frameIndex = fromIndex

	local function advance()
		if not bannerWidget or bannerWidget:isDestroyed() then
			return
		end

		applyAnimationFrame(frameIndex)

		if frameIndex == toIndex then
			scheduleBannerEvent(function()
				if onComplete then
					onComplete()
				end
			end, ANIM_FRAME_MS)

			return
		end

		frameIndex = frameIndex + step

		scheduleBannerEvent(advance, ANIM_FRAME_MS)
	end

	advance()
end

local function playOpenAnimation(onComplete)
	if not bannerWidget or bannerWidget:isDestroyed() then
		if onComplete then
			onComplete()
		end

		return
	end

	cancelAnimationEvents()
	showRollPhase(0)
	playRollSequence(0, 7, function()
		if not bannerWidget or bannerWidget:isDestroyed() then
			return
		end

		showFinalPhase()
		setTextContentOpacity(0)
		fadeInTextContent(150)

		if onComplete then
			onComplete()
		end
	end)
end

local function playCloseAnimation(onComplete)
	if not bannerWidget or bannerWidget:isDestroyed() then
		if onComplete then
			onComplete()
		end

		return
	end

	cancelAnimationEvents()
	setTextContentOpacity(0)
	cancelTextContentFade()
	showRollPhase(7)
	playRollSequence(7, 0, function()
		if onComplete then
			onComplete()
		end
	end)
end

local processNextBanner

local function finishCurrentBanner()
	isShowingBanner = false

	destroyBannerWidget()
	processNextBanner()
end

function processNextBanner()
	if isShowingBanner or #bannerQueue == 0 then
		return
	end

	if not g_game.isOnline() then
		bannerQueue = {}

		return
	end

	local entry = table.remove(bannerQueue, 1)

	currentBannerEntry = entry
	isShowingBanner = true

	local parent = getBannerParent()

	if not parent or parent:isDestroyed() then
		isShowingBanner = false

		return
	end

	destroyBannerWidget()

	bannerWidget = g_ui.createWidget("GameBannerPanel", parent)

	if not bannerWidget then
		isShowingBanner = false

		return
	end

	bannerWidget:setSize({
		width = BANNER_FULL_WIDTH,
		height = BANNER_HEIGHT
	})
	bannerWidget:addAnchor(AnchorTop, "parent", AnchorTop)
	bannerWidget:addAnchor(AnchorHorizontalCenter, "parent", AnchorHorizontalCenter)
	bannerWidget:setMarginTop(8)
	bannerWidget:raise()
	bannerWidget:show()

	local bannerTitle = bannerWidget:recursiveGetChildById("bannerTitle")
	local bannerDescription = bannerWidget:recursiveGetChildById("bannerDescription")

	applyBannerIcon(entry)

	if bannerTitle then
		bannerTitle:setText(entry.title)
	end

	if bannerDescription then
		bannerDescription:setText(entry.description)
	end

	refreshBannerTextLayout()
	playOpenAnimation(function()
		scheduleBannerEvent(function()
			if not bannerWidget or bannerWidget:isDestroyed() then
				finishCurrentBanner()

				return
			end

			playCloseAnimation(finishCurrentBanner)
		end, BANNER_HOLD_MS)
	end)
end

local function enqueueBanner(entry)
	table.insert(bannerQueue, entry)
	processNextBanner()
end

local function onClientEvent(eventType, ...)
	if not isInfoBannerEnabled() then
		return
	end

	local content = resolveBannerContent(eventType, ...)

	if not content then
		return
	end

	enqueueBanner(content)
end

function hideActiveBanner(clearQueue)
	if clearQueue then
		bannerQueue = {}
	end

	isShowingBanner = false

	destroyBannerWidget()

	if not clearQueue then
		processNextBanner()
	end
end

function clearBannerQueue()
	bannerQueue = {}
end

function bannersController:onInit()
	g_ui.importStyle("game_banners")
end

function bannersController:onTerminate()
	hideActiveBanner(true)
end

function bannersController:onGameStart()
	if g_game.getClientVersion() < 1180 then
		return
	end

	bannersController:registerEvents(g_game, {
		onClientEvent = onClientEvent
	})
end

function bannersController:onGameEnd()
	hideActiveBanner(true)
end

function init()
	bannersController:init()
end

function terminate()
	bannersController:terminate()
end
