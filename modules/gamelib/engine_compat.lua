-- Compatibility shim for modules ported from the ported client.
-- These modules call C++ bindings that our engine does not have (or has under a different name).
-- Each definition installs itself ONLY when the binding does not exist - once the real
-- implementation is added in C++, the shim automatically stops being used.

local function install(tbl, name, fn)
	if tbl and not tbl[name] then
		tbl[name] = fn
	end
end

local function stubSend(name)
	install(g_game, name, function(...)
		g_logger.warning(string.format("[compat] g_game.%s: no implementation in this client build (call ignored)", name))
	end)
end

-- ===== g_game: simple replacements =====

install(g_game, "isZoomEnabled", function()
	return true
end)

do
	local hoveredCreature = nil

	install(g_game, "setHoveredCreature", function(creature)
		hoveredCreature = creature
	end)
	install(g_game, "clearHoveredCreature", function()
		hoveredCreature = nil
	end)
	install(g_game, "getHoveredCreature", function()
		return hoveredCreature
	end)
end

-- ===== g_game: mappings to our existing bindings =====

if not g_game.sendOfflineTraining and g_game.sendStartOfflineTraining then
	g_game.sendOfflineTraining = function(skillId)
		g_game.sendStartOfflineTraining(skillId)
	end
end

if not g_game.sendBossDifficultySelect and g_game.sendBossDifficultyAction then
	-- our protocol: action 0=fight, 1=cancel, 2=difficulty update (leaderId is not transmitted)
	g_game.sendBossDifficultySelect = function(leaderId, difficulty)
		g_game.sendBossDifficultyAction(2, difficulty)
	end
	g_game.sendBossDifficultyStartFight = function(leaderId, difficulty)
		g_game.sendBossDifficultyAction(0, difficulty)
	end
	g_game.sendBossDifficultyCancel = function(leaderId)
		g_game.sendBossDifficultyAction(1, 0)
	end
end

if not g_game.sendSoulSealSelectCreature and g_game.sendSoulSealsAction then
	g_game.sendSoulSealSelectCreature = function(raceId)
		g_game.sendSoulSealsAction(raceId)
	end
end

if not g_game.sendSelectVocation and g_game.sendTutorialChangeVocation then
	g_game.sendSelectVocation = function(vocationId)
		g_game.sendTutorialChangeVocation(vocationId)
	end
end

install(g_game, "getTransferableTibiaCoins", function()
	return 0
end)
install(g_game, "getTibiaCoins", function()
	return 0
end)
install(g_game, "setTibiaCoins", function() end)

-- no binding in our exe; the resource balance arrives from the server on its own anyway
-- (0xEE / onResourcesBalanceChange), so requesting a refresh is unnecessary.
-- WITHOUT this shim mods/game_imbuing crashed right after opening the window (empty window).
install(g_game, "requestResource", function() end)

-- ===== g_game: sends with no counterpart in our protocol (no-op + warning) =====

local missingSends = {
	"processRuleViolation",
	"changeOutfitPodium",
	"changeHirelingOutfit",
	"confirmEditPodium",
	"getBaseInformationForAuctionCharacter",
	"sendCharacterAuction",
	"sendChangeHirelingName",
	"requestStoreOfferDescription",
	"closeContainerByItemId",
	"organizeContainer",
	"useHireling",
	"sendRewardCollectAll",
	"reportRuleViolationReport",
	"requestSearchLocker",
	"closeSearchLocker",
	"requestLockerItem",
	"retrieveDisplayed"
}

-- This engine has no client request for resource balances. Crystal sends the
-- complete balance list through GameServerResourceBalance (0xEE), including
-- updates after spending/receiving resources. The Task Board calls this only
-- as an optional refresh, so keep it as a silent no-op instead of flooding the
-- console every time that window is opened or refreshed.
install(g_game, "sendResourceBalance", function() end)

-- The ported Market/Stash modules use sendMarketAction, while this engine
-- exposes the same protocol operation as browseMarket.
if not g_game.sendMarketAction and g_game.browseMarket then
	install(g_game, "sendMarketAction", function(action, itemId, tier)
		g_game.browseMarket(action or 1, itemId or 0, tier or 0)
	end)
end

-- Party Hunt Analyser: our engine has these actions under the analyser names and without arguments
-- (the server toggles the price type itself), so this is a plain rename, not a missing function.
if g_game.sendPartyAnalyzerReset then
	install(g_game, "sendPartyResetSession", function()
		g_game.sendPartyAnalyzerReset()
	end)
	install(g_game, "sendPartyLootType", function()
		g_game.sendPartyAnalyzerPriceType()
	end)
	install(g_game, "sendPartyLootPrice", function()
		g_game.sendPartyAnalyzerPriceValue()
	end)
end

if g_game.requestImbuementScroll then
	install(g_game, "selectImbuementScroll", function()
		g_game.requestImbuementScroll()
	end)
end

-- TASK BOARD: our engine has the full set of actions, but under different names and grouped into three
-- functions (bountyTaskAction / weeklyTaskAction / bountyPreferredAction) plus two separate ones for the shop.
-- The the ported client module calls 15 separate names which until now were empty stubs, so NO
-- taskboard action was going out to the server. Action codes from Otc::* in src/client/const.h.
if g_game.bountyTaskAction and g_game.weeklyTaskAction and g_game.bountyPreferredAction then
	local BOUNTY_REROLL, BOUNTY_SELECT, BOUNTY_CLAIM_REWARD = 0, 1, 2
	local BOUNTY_CHANGE_DIFFICULTY, BOUNTY_REQUEST, BOUNTY_CLAIM_DAILY = 3, 4, 5
	local WEEKLY_SELECT_DIFFICULTY, WEEKLY_DELIVER, WEEKLY_REFRESH = 0, 1, 2
	local PREF_BUY_SLOT, PREF_SET_PREFERRED, PREF_SET_UNWANTED = 1, 2, 3
	local PREF_CLEAR_PREFERRED, PREF_CLEAR_UNWANTED = 4, 5

	-- tab: 0 = bounty, 1 = weekly, 2 = task shop
	install(g_game, "sendOpenMenuTaskBoardAction", function(tab)
		if tab == 1 then
			g_game.weeklyTaskAction(WEEKLY_REFRESH, 0)
		elseif tab == 2 then
			if g_game.taskHuntingShopRequest then
				g_game.taskHuntingShopRequest()
			end
		else
			g_game.bountyTaskAction(BOUNTY_REQUEST, 0)
		end
	end)

	install(g_game, "sendRerollTasks", function()
		g_game.bountyTaskAction(BOUNTY_REROLL, 0)
	end)
	install(g_game, "sendSelectTask", function(taskId)
		g_game.bountyTaskAction(BOUNTY_SELECT, taskId or 0)
	end)
	install(g_game, "sendClaimReward", function()
		g_game.bountyTaskAction(BOUNTY_CLAIM_REWARD, 0)
	end)
	-- the module counts difficulty 0-3, and Game::toServerDifficulty subtracts 1 before sending,
	-- so we must pass a value increased by 1 (otherwise Beginner would be rejected as 0)
	install(g_game, "sendSelectTaskDifficulty", function(difficulty)
		g_game.bountyTaskAction(BOUNTY_CHANGE_DIFFICULTY, (difficulty or 0) + 1)
	end)
	install(g_game, "sendClaimDaily", function()
		g_game.bountyTaskAction(BOUNTY_CLAIM_DAILY, 0)
	end)

	install(g_game, "sendSelectDifficultyWeeklyTasks", function(difficulty)
		g_game.weeklyTaskAction(WEEKLY_SELECT_DIFFICULTY, (difficulty or 0) + 1)
	end)
	install(g_game, "sendDeliveryTask", function(taskId)
		g_game.weeklyTaskAction(WEEKLY_DELIVER, taskId or 0)
	end)

	install(g_game, "sendPreferredListPreferred", function(slot, raceId)
		g_game.bountyPreferredAction(PREF_SET_PREFERRED, slot or 0, raceId or 0)
	end)
	install(g_game, "sendPreferredListUnwanted", function(slot, raceId)
		g_game.bountyPreferredAction(PREF_SET_UNWANTED, slot or 0, raceId or 0)
	end)
	install(g_game, "sendPreferredListClearPreferred", function(slot)
		g_game.bountyPreferredAction(PREF_CLEAR_PREFERRED, slot or 0, 0)
	end)
	install(g_game, "sendPreferredListClearUnwanted", function(slot)
		g_game.bountyPreferredAction(PREF_CLEAR_UNWANTED, slot or 0, 0)
	end)
	install(g_game, "sendPreferredListUnlockSlots", function(slot)
		g_game.bountyPreferredAction(PREF_BUY_SLOT, slot or 0, 0)
	end)

	if g_game.bountyTalismanUpgrade then
		install(g_game, "sendUpgradeTalisman", function(talismanId)
			g_game.bountyTalismanUpgrade(talismanId or 0)
		end)
	end

	if g_game.taskHuntingShopPurchase then
		install(g_game, "sendOnBuyHuntingTaskShop", function(offerId)
			g_game.taskHuntingShopPurchase(offerId or 0)
		end)
	end
end

-- Proficiency Modify/Refine/Maximise/Reshape/Clear: our engine has this as
-- sendWeaponProficiencySlotAction(actionType, itemId, level, position, offerIndex) and sends 0xB3
-- in the layout that crystal expects. Until now there was an empty stub here, so none of these actions
-- was going out to the server, and the module overwrote its own preview upfront anyway - hence the "random
-- perk at level 10" after merely opening the window (it was an optimistic swap that nobody reverted).
if g_game.sendWeaponProficiencySlotAction then
	install(g_game, "sendWeaponProficiencyModifierAction", function(actionType, itemId, level, position, offerIndex)
		-- action 8 (reshape offer selection) accepts index 0-2; the module uses 3 for the "Keep" button,
		-- i.e. "keep the current modifier" - the server knows no such offer, so we send nothing
		if actionType == 8 and (type(offerIndex) ~= "number" or offerIndex < 0 or offerIndex > 2) then
			return
		end

		g_game.sendWeaponProficiencySlotAction(actionType or 0, itemId or 0, level or 0, position or 0,
			type(offerIndex) == "number" and offerIndex or -1)
	end)
end

-- the imbuing module only knows itemId + position + stackpos, while requestImbuementWindow wants an Item object
if g_game.requestImbuementWindowById then
	install(g_game, "selectImbuementItem", function(itemId, position, stackPos)
		g_game.requestImbuementWindowById(itemId or 0, position, stackPos or 0)
	end)
end

for _, name in ipairs(missingSends) do
	stubSend(name)
end

-- forge: our bindings have different names (forgeRequest / sendForgeBrowseHistoryRequest)
if not g_game.sendForgeAction and g_game.forgeRequest then
	g_game.sendForgeAction = function(actionType, convergence, firstId, firstTier, secondId, improve, tierLoss)
		g_game.forgeRequest(actionType or 0, convergence and true or false, firstId or 0, firstTier or 0, secondId or 0, improve and true or false, tierLoss and true or false)
	end
end

if not g_game.sendForgeHistory and g_game.sendForgeBrowseHistoryRequest then
	g_game.sendForgeHistory = function(page)
		g_game.sendForgeBrowseHistoryRequest(page or 0)
	end
end

if g_shaders then
	install(g_shaders, "removeShader", function() end)
end

-- ===== remaining singletons =====

install(g_app, "quit", function()
	g_app.exit()
end)

-- widget methods from the ported client engine that our exe lacks (no-op until a C++ implementation)
if UIWidget then
	-- ActionId is a generic numeric tag on a widget - market/prey/search locker tag list
	-- rows with it and READ it later (getActionId), so an empty stub broke entire modules.
	-- The fallback keeps values in a weak-keyed table; with a new exe (C++ bindings
	-- UIWidget::set/getActionId) install() simply does not install itself.
	do
		local widgetActionIds = setmetatable({}, { __mode = "k" })

		install(UIWidget, "setActionId", function(widget, actionId)
			widgetActionIds[widget] = actionId
		end)
		install(UIWidget, "getActionId", function(widget)
			return widgetActionIds[widget] or 0
		end)
	end
	install(UIWidget, "setImageRepeatedFromBottom", function() end)
	install(UIWidget, "setOnHtml", function() end)

	-- how many lines the wrapped text takes; our engine does not compute this, so we estimate
	-- from the rendered text height (used only for the "shorten and add a tooltip" decision)
	install(UIWidget, "getWrappedLinesCount", function(self)
		local text = self:getText()

		if not text or text == "" then
			return 0
		end

		local size = self:getTextSize()
		local lineHeight = 12

		if size and size.height and size.height > 0 then
			return math.max(1, math.floor(size.height / lineHeight + 0.5))
		end

		local lines = 1

		for _ in text:gmatch("\n") do
			lines = lines + 1
		end

		return lines
	end)
end

if UIWidget then
	-- market/search locker: whether a row is beyond the limit (we have no such state)
	install(UIWidget, "isOfflimit", function()
		return false
	end)
end

if UIMap then
	-- we have per-creature HUD setters, the getters are missing (creatureinformation.lua)
	local hudGetters = {
		isDrawingOwnName = true,
		isDrawingOtherNames = true,
		isDrawingOwnHealthBars = true,
		isDrawingOtherHealthBars = true,
		isDrawingOwnManaBar = true,
		isDrawingOtherNpcIcons = true,
		isDrawingOtherMarks = true
	}

	for name, default in pairs(hudGetters) do
		install(UIMap, name, function()
			return default
		end)
	end
end

-- our OutputMessage has addU8/addU16/addU32; the ported client uses the names addByte/addShort/addInt
if OutputMessage then
	install(OutputMessage, "addByte", function(self, v)
		return self:addU8(v)
	end)
	install(OutputMessage, "addShort", function(self, v)
		return self:addU16(v)
	end)
	install(OutputMessage, "addInt", function(self, v)
		return self:addU32(v)
	end)
end

if UICreature then
	install(UICreature, "setFixedCreatureSize", function() end)
	install(UICreature, "setBaseScale", function() end)
	install(UICreature, "setIgnoreDisplacementShift", function() end)
	install(UICreature, "setCenterByBoundingBox", function() end)
	install(UICreature, "setPodiumPreview", function() end)
	install(UICreature, "setCreatureSmooth", function() end)
end

-- NOTE: setDrawOutfitLayers is called on Creature (previewCreature:getCreature()),
-- not on UICreature - the shim must sit on the correct class
if Creature then
	install(Creature, "setDrawOutfitLayers", function() end)
	install(Creature, "isHealthHidden", function()
		return false
	end)
	install(Creature, "isSummon", function(self)
		return self.getMasterId and (self:getMasterId() or 0) > 0 or false
	end)
end

if ThingType then
	-- prefetch/preload of preview textures: our engine loads sprites lazily, so no-op
	install(ThingType, "prefetchSpriteSheetsForPreview", function() end)
	install(ThingType, "prefetchTexturePhase", function() end)
	install(ThingType, "preparePreviewMovementTexture", function() end)
	install(ThingType, "getResultingValue", function()
		return 0
	end)
end

if InputMessage then
	install(InputMessage, "getByte", function(self)
		return self:getU8()
	end)
end

if ThingType then
	install(ThingType, "isDualWielding", function()
		return false
	end)
end

if g_client then
	install(g_client, "setInputLockWidget", function() end)
	-- options are 0-100 (%), our alpha setters take 0-1
	if not g_client.setOwnSpellEffectOpacity and g_client.setOwnSpellEffectAlpha then
		g_client.setOwnSpellEffectOpacity = function(v)
			g_client.setOwnSpellEffectAlpha(v / 100)
		end
	end
	if not g_client.setOthersPlayersEffectOpacity and g_client.setOtherPlayerSpellEffectAlpha then
		g_client.setOthersPlayersEffectOpacity = function(v)
			g_client.setOtherPlayerSpellEffectAlpha(v / 100)
		end
	end
	if not g_client.setCreatureSpellEffectsOpacity and g_client.setCreatureSpellEffectAlpha then
		g_client.setCreatureSpellEffectsOpacity = function(v)
			g_client.setCreatureSpellEffectAlpha(v / 100)
		end
	end
	if not g_client.setBossAreaCreatureSpellEffectOpacity and g_client.setBossAreaCreatureEffectAlpha then
		g_client.setBossAreaCreatureSpellEffectOpacity = function(v)
			g_client.setBossAreaCreatureEffectAlpha(v / 100)
		end
	end

	install(g_client, "setShowMeleeAttackAnimation", function() end)
	install(g_client, "setMarkTargetVisually", function() end)
	install(g_client, "setShowCombatFrames", function() end)
	install(g_client, "setShowPvPFrames", function() end)
	install(g_client, "setShowLootHighlight", function() end)
end

install(g_mouse, "setUseNativeSystemCursor", function() end)
install(g_mouse, "setCursorDisplayScale", function() end)

install(g_things, "getMonsterList", function()
	return g_things.getRacesByName("")
end)
install(g_things, "getHouseTilesData", function()
	return nil
end)

install(g_minimap, "getCyclopediaSubareaAt", function()
	return nil
end)

install(g_platform, "readLocalFile", function()
	g_logger.warning("[compat] g_platform.readLocalFile unavailable in this build")

	return nil
end)
install(g_platform, "extractZip", function()
	g_logger.warning("[compat] g_platform.extractZip unavailable in this build")

	return false
end)
install(g_platform, "isDirectory", function()
	return false
end)
install(g_platform, "listLocalDirectory", function()
	return {}
end)

-- ===== C++ class methods (extensions via class tables) =====

if Item then
	-- podium (Customise Podium / outfit window): our parser discards podium attributes,
	-- so we return neutral values instead of crashing the module
	install(Item, "getPodiumOutfit", function()
		return { type = 0, head = 0, body = 0, legs = 0, feet = 0, addons = 0, mount = 0 }
	end)
	install(Item, "getPodiumDirection", function()
		return 2
	end)
	install(Item, "isPodiumShowPlatform", function()
		return true
	end)
	install(Item, "setPodium", function() end)
	install(Item, "getPriceValue", function()
		return 0
	end)
	install(Item, "getQuickLootFlags", function()
		return 0
	end)
	install(Item, "getObtainLootFlags", function()
		return 0
	end)
	install(Item, "getQuiverAmmoCount", function()
		return 0
	end)
	install(Item, "isDecoKit", function()
		return false
	end)
end

if Thing then
	install(Thing, "isCyclopediaItem", function(self)
		return self.getCyclopediaType and self:getCyclopediaType() > 0 or false
	end)
	install(Thing, "isPlayerCorpse", function()
		return false
	end)
end

if LocalPlayer then
	install(LocalPlayer, "getBlessingsIconColor", function(self)
		-- Protocol 0x9C stores the blessing/glow indicator in getBlessings().
		-- The inventory expects a numeric visual state: 1 grey, 2 gold, 3 green.
		local blessings = self and self.getBlessings and self:getBlessings() or 0
		return blessings ~= 0 and 3 or 1
	end)
end

if Container then
	install(Container, "isInDepot", function()
		return false
	end)
	install(Container, "getSelectedFilter", function()
		return 0
	end)
	install(Container, "getFiltersCount", function()
		return 0
	end)
	install(Container, "getFilterId", function()
		return 0
	end)
	install(Container, "getFilterName", function()
		return ""
	end)
end

if UIItem then
	install(UIItem, "setUseDecoKitContainerSprite", function() end)
	install(UIItem, "setPodiumPreview", function() end)
end

if UIGridLayout then
	install(UIGridLayout, "getCellSpacingWidth", function(self)
		return self:getCellSpacing()
	end)
	install(UIGridLayout, "getCellSpacingHeight", function(self)
		return self:getCellSpacing()
	end)
end
