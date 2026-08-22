local var_0_0 = false
local var_0_1 = 22

if not BattlePass then
	BattlePass = {}
	BattlePass.__index = BattlePass
	BattlePass.window = nil
	BattlePass.missionPanel = nil
	BattlePass.progressPanel = nil
	BattlePass.outfitWidget = nil
	BattlePass.scrollBarWidget = nil
	BattlePass.dailyRerollWindow = nil
	BattlePass.beginTime = 0
	BattlePass.endTime = 0
	BattlePass.seasonActive = false
	BattlePass.progressPoints = 0
	BattlePass.dailyRerollPrice = 0
	BattlePass.premiumBattlepass = false
	BattlePass.currentRewardStep = 0
	BattlePass.nextStepPoints = 0
	BattlePass.currentReward = 0
	BattlePass.dailyMissionsBegin = 0
	BattlePass.dailyMissionsExpire = 0
	BattlePass.dailyMissions = {}
	BattlePass.seassonMissions = {}
	BattlePass.isAnimatingWalk = false
	BattlePass.lastRewardStep = 0
	BattlePass.lastCameraPosition = 0
	BattlePass.rewardMinMargin = 195
	BattlePass.rewardMaxMargin = 18045
	BattlePass.currentMenu = nil
	BattlePass.rewardContainersBuilt = false
	BattlePass.rewardWidgetCache = {}
	BattlePass.missionWidgetCache = {}
	BattlePass.missionContainersBuilt = false
	BattlePass.dailyContainersBuilt = false
	BattlePass.shopWidgetCache = nil
	BattlePass.shopBuiltSignature = nil
end

BattlePass.eventHandles = BattlePass.eventHandles or {}
BattlePass.SEASON_CALENDAR = BattlePass.SEASON_CALENDAR or nil

local function var_0_2(arg_1_0)
	local var_1_0, var_1_1, var_1_2 = arg_1_0:match("^(%d+)-(%d+)-(%d+)$")

	if not var_1_0 then
		return nil
	end

	return os.time({
		min = 0,
		sec = 0,
		hour = 0,
		year = tonumber(var_1_0),
		month = tonumber(var_1_1),
		day = tonumber(var_1_2)
	})
end

function BattlePass.loadSeasonCalendar()
	local var_2_0 = "/data/json/battlepass_seasons.json"

	if not g_resources.fileExists(var_2_0) then
		g_logger.warning("[BattlePass] season calendar JSON missing at " .. var_2_0)

		return
	end

	local var_2_1, var_2_2 = pcall(function()
		return json.decode(g_resources.readFileContents(var_2_0))
	end)

	if not var_2_1 or type(var_2_2) ~= "table" then
		g_logger.error("[BattlePass] failed to parse season calendar JSON: " .. tostring(var_2_2))

		return
	end

	local var_2_3 = {
		seasons = {},
		missionUnlock = var_2_2.mission_unlock or {}
	}

	for iter_2_0, iter_2_1 in ipairs(var_2_2.seasons or {}) do
		local var_2_4 = var_0_2(iter_2_1.start)
		local var_2_5 = iter_2_1["end"] and var_0_2(iter_2_1["end"]) or nil

		if var_2_4 and var_2_5 then
			table.insert(var_2_3.seasons, {
				id = iter_2_1.id,
				startTs = var_2_4,
				endTs = var_2_5
			})
		end
	end

	BattlePass.SEASON_CALENDAR = var_2_3
end

function BattlePass.getCurrentSeason()
	if not BattlePass.SEASON_CALENDAR then
		BattlePass.loadSeasonCalendar()
	end

	if not BattlePass.SEASON_CALENDAR then
		return nil, 0, 0, false
	end

	local var_4_0 = os.time()
	local var_4_1

	for iter_4_0, iter_4_1 in ipairs(BattlePass.SEASON_CALENDAR.seasons) do
		if var_4_0 >= iter_4_1.startTs and var_4_0 <= iter_4_1.endTs then
			return iter_4_1, iter_4_1.startTs, iter_4_1.endTs, true
		elseif var_4_0 < iter_4_1.startTs then
			var_4_1 = var_4_1 or iter_4_1
		end
	end

	if var_4_1 then
		return var_4_1, var_4_1.startTs, var_4_1.endTs, false
	end

	return nil, 0, 0, false
end

function BattlePass.refreshLocalSeasonState()
	local var_5_0, var_5_1, var_5_2, var_5_3 = BattlePass.getCurrentSeason()

	if var_5_0 then
		BattlePass.beginTime = var_5_1
		BattlePass.endTime = var_5_2
		BattlePass.currentSeasonId = var_5_0.id
	end

	BattlePass.seasonActive = var_5_0 ~= nil and var_5_3 or false

	BattlePass.updateMainpanelButton()

	if not BattlePass.seasonActive and BattlePass.window and BattlePass.window:isVisible() and hide then
		hide()
	end
end

function BattlePass.getExposedMissionCount()
	if not BattlePass.seasonActive or not BattlePass.beginTime or BattlePass.beginTime == 0 then
		return 0
	end

	local var_6_0 = math.floor((os.time() - BattlePass.beginTime) / 604800) + 1

	if var_6_0 <= 0 then
		return 0
	end

	-- RubinOT Season 4 starts with daily missions only. General missions are
	-- released in seven weekly waves after the opening week.
	local var_6_1 = math.min(var_6_0, 8)
	local var_6_2 = 0
	local var_6_3 = 0
	local var_6_4 = 0
	local var_6_5 = 0

	if var_6_1 == 1 then
		var_6_2, var_6_3, var_6_4, var_6_5 = 0, 0, 0, 0
	elseif var_6_1 <= 3 then
		var_6_2, var_6_3 = (var_6_1 - 1) * 2, (var_6_1 - 1) * 2
	elseif var_6_1 <= 5 then
		var_6_2, var_6_3, var_6_4 = (var_6_1 - 1) * 2, (var_6_1 - 1) * 2, (var_6_1 - 3) * 2
	else
		var_6_2, var_6_3 = (var_6_1 - 1) * 2, (var_6_1 - 1) * 2
		var_6_4, var_6_5 = var_6_1 - 1, var_6_1 - 5
	end

	local var_6_6 = BattlePassAssets and BattlePassAssets.bronzeMissions or {}
	local var_6_7 = BattlePassAssets and BattlePassAssets.silverMissions or {}
	local var_6_8 = BattlePassAssets and BattlePassAssets.goldMissions or {}
	local var_6_9 = BattlePassAssets and BattlePassAssets.crystalMissions or {}

	local var_6_10 = math.min(var_6_2, #var_6_6)
	local var_6_11 = math.min(var_6_3, #var_6_7)
	local var_6_12 = math.min(var_6_4, #var_6_8)
	local var_6_13 = math.min(var_6_5, #var_6_9)

	return var_6_10 + var_6_11 + var_6_12 + var_6_13
end

function BattlePass.sendBattlePassAction(arg_7_0)
	local var_7_0 = g_game.getProtocolGame()

	if var_7_0 then
		var_7_0:sendExtendedJSONOpcode(var_0_1, arg_7_0)
	end
end

local var_0_3 = BattlePass.sendBattlePassAction

local function var_0_4(arg_8_0)
	if not arg_8_0 then
		return "0"
	end

	arg_8_0 = math.floor(arg_8_0)

	if arg_8_0 >= 1000000000 then
		return string.format("%.1fb", arg_8_0 / 1000000000)
	elseif arg_8_0 >= 1000000 then
		return string.format("%.1fm", arg_8_0 / 1000000)
	elseif arg_8_0 >= 1000 then
		return string.format("%.1fk", arg_8_0 / 1000)
	end

	return tostring(arg_8_0)
end

local function var_0_5(arg_9_0)
	return MissionsDisplacement[arg_9_0]
end

local function var_0_6(arg_10_0)
	local var_10_0 = {}
	local var_10_1 = {}
	local var_10_2 = {}
	local var_10_3 = {}
	local var_10_4 = {}

	for iter_10_0, iter_10_1 in ipairs(BattlePass.seassonMissions) do
		if iter_10_1.rewardPoints == 100 then
			table.insert(var_10_0, iter_10_1)
		elseif iter_10_1.rewardPoints == 200 then
			table.insert(var_10_1, iter_10_1)
		elseif iter_10_1.rewardPoints == 300 then
			table.insert(var_10_2, iter_10_1)
		elseif iter_10_1.rewardPoints == 500 then
			table.insert(var_10_3, iter_10_1)
		end
	end

	local var_10_5 = 1
	local var_10_6 = 1
	local var_10_7 = 1
	local var_10_8 = 1

	for iter_10_2, iter_10_3 in ipairs(MissionTypesOrder) do
		local var_10_9 = MissionsDisplacement[iter_10_2]
		local var_10_10

		if iter_10_3 == "bronze" and var_10_0[var_10_5] then
			var_10_10 = var_10_0[var_10_5]
			var_10_5 = var_10_5 + 1
		elseif iter_10_3 == "silver" and var_10_1[var_10_6] then
			var_10_10 = var_10_1[var_10_6]
			var_10_6 = var_10_6 + 1
		elseif iter_10_3 == "gold" and var_10_2[var_10_7] then
			var_10_10 = var_10_2[var_10_7]
			var_10_7 = var_10_7 + 1
		elseif iter_10_3 == "crystal" and var_10_3[var_10_8] then
			var_10_10 = var_10_3[var_10_8]
			var_10_8 = var_10_8 + 1
		end

		if var_10_10 then
			table.insert(var_10_4, {
				data = var_10_10,
				index = var_10_9
			})
		end
	end

	return var_10_4
end

local function var_0_7(arg_11_0)
	local var_11_0 = arg_11_0 - os.time()

	if var_11_0 <= 0 then
		return "Expired", "Expired"
	end

	local var_11_1 = math.floor(var_11_0 / 86400)
	local var_11_2 = math.floor(var_11_0 % 86400 / 3600)
	local var_11_3 = math.floor(var_11_0 % 3600 / 60)
	local var_11_4 = var_11_0 % 60

	local function var_11_5(arg_12_0, arg_12_1, arg_12_2)
		return arg_12_0 == 1 and string.format("%d %s", arg_12_0, arg_12_1) or string.format("%02d %s", arg_12_0, arg_12_2)
	end

	local var_11_6
	local var_11_7

	if var_11_1 > 0 then
		var_11_6 = var_11_5(var_11_1, "Day left", "Days left")
		var_11_7 = var_11_5(var_11_1, "Day", "Days") .. string.format(" and %02d hours left", var_11_2)
	elseif var_11_2 > 0 then
		var_11_6 = var_11_5(var_11_2, "Hour left", "Hours left")
		var_11_7 = var_11_5(var_11_2, "Hour", "Hours") .. string.format(" and %02d minutes left", var_11_3)
	elseif var_11_3 > 0 then
		var_11_6 = var_11_5(var_11_3, "Minute left", "Minutes left")
		var_11_7 = var_11_5(var_11_3, "Minute", "Minutes") .. string.format(" and %02d seconds left", var_11_4)
	else
		var_11_6 = string.format("%02d Seconds left", var_11_4)
		var_11_7 = var_11_6
	end

	return var_11_6, var_11_7
end

local function var_0_8(arg_13_0)
	local var_13_0 = arg_13_0 - os.time()

	if var_13_0 <= 0 then
		return "00:00:00:00"
	end

	local var_13_1 = math.floor(var_13_0 / 86400)
	local var_13_2 = math.floor(var_13_0 % 86400 / 3600)
	local var_13_3 = math.floor(var_13_0 % 3600 / 60)
	local var_13_4 = var_13_0 % 60

	return string.format("%02d:%02d:%02d:%02d", var_13_1, var_13_2, var_13_3, var_13_4)
end

local function var_0_9(arg_14_0)
	local var_14_0 = BattlePass.eventHandles[arg_14_0]

	if var_14_0 then
		removeEvent(var_14_0)

		BattlePass.eventHandles[arg_14_0] = nil
	end
end

local function var_0_10()
	for iter_15_0, iter_15_1 in pairs(BattlePass.eventHandles) do
		if iter_15_1 then
			removeEvent(iter_15_1)
		end

		BattlePass.eventHandles[iter_15_0] = nil
	end
end

local function var_0_11(arg_16_0, arg_16_1)
	var_0_9("timerEvent")

	if not arg_16_0 or not arg_16_0:isVisible() or arg_16_1 < os.time() then
		return
	end

	arg_16_0:setText(BattlePass:running() and string.format("New missions available in: %s", var_0_8(arg_16_1)) or "                              Expired")

	BattlePass.eventHandles.timerEvent = scheduleEvent(function()
		BattlePass.eventHandles.timerEvent = nil

		var_0_11(arg_16_0, arg_16_1)
	end, 1000)
end

function toggleTracker()
	if modules.game_battlepasstracker then
		modules.game_battlepasstracker.toggle()
	end
end

local function var_0_12(arg_19_0, arg_19_1)
	local var_19_0 = 0

	for iter_19_0 = arg_19_0 + 1, arg_19_1 do
		if iter_19_0 <= 10 then
			var_19_0 = var_19_0 + 25
		elseif iter_19_0 <= 20 then
			var_19_0 = var_19_0 + 50
		elseif iter_19_0 <= 40 then
			var_19_0 = var_19_0 + 75
		elseif iter_19_0 <= 60 then
			var_19_0 = var_19_0 + 100
		else
			var_19_0 = var_19_0 + 125
		end
	end

	return var_19_0
end

function BattlePass.confirmBuySteps(arg_20_0)
	local var_20_0 = BattlePass.currentRewardStep

	if arg_20_0 <= var_20_0 then
		return
	end

	local var_20_1 = arg_20_0 - var_20_0
	local var_20_2 = var_0_12(var_20_0, arg_20_0)
	local var_20_3 = BattlePass.window:recursiveGetChildById("buyStepsConfirmOverlay")

	if not var_20_3 then
		return
	end

	var_20_3:recursiveGetChildById("buyStepsMsg"):setText(string.format("Are you sure you want to purchase %d step%s up to level %d for $ %s?", var_20_1, var_20_1 > 1 and "s" or "", arg_20_0, comma_value(var_20_2)))

	local var_20_4 = var_20_3:recursiveGetChildById("buyStepsOk")
	local var_20_5 = var_20_3:recursiveGetChildById("buyStepsCancel")

	local function var_20_6()
		var_20_3:setVisible(false)

		var_20_4.onClick = nil
		var_20_5.onClick = nil
	end

	function var_20_4.onClick()
		var_20_6()

		if var_0_0 then
			BattlePass.currentRewardStep = arg_20_0

			BattlePass:configureMissionPanel()
			BattlePass:configureRewardPanel()
		else
			var_0_3({
				action = "buySteps",
				targetStep = arg_20_0,
				cost = var_20_2
			})
		end
	end

	function var_20_5.onClick()
		var_20_6()
	end

	var_20_3:setVisible(true)
	var_20_3:raise()
end

function redirectToStore()
	BattlePass.window:hide()
	modules.game_store.show()
	g_game.requestStoreOffers("Deluxe Battle Pass", "", 0, 1)
end

local var_0_13
local var_0_14
local var_0_15
local var_0_16
local var_0_17
local var_0_18

function init()
	BattlePass.window = g_ui.displayUI("battlepass")

	BattlePass.window:hide()


	BattlePass.missionPanel = BattlePass.window.mainPanel.contentPanel.missionPanel
	BattlePass.progressPanel = BattlePass.window.mainPanel.contentPanel.progressPanel
	BattlePass.outfitWidget = BattlePass.window:recursiveGetChildById("playerOutfit")
	BattlePass.scrollBarWidget = BattlePass.window:recursiveGetChildById("progressPanelScrollBar")

	local var_25_0 = BattlePass.window:recursiveGetChildById("skipButton")

	if var_25_0 then
		function var_25_0.onClick()
			local var_26_0 = BattlePass.currentRewardStep

			if var_26_0 > 0 and RewardPositions[var_26_0] then
				BattlePass.isAnimatingWalk = false

				BattlePass.scrollBarWidget:setValue(RewardPositions[var_26_0].scrollPosition)
				BattlePass.outfitWidget:setMarginLeft(BattlePass:getRewardMarginLeft(var_26_0))
				BattlePass.outfitWidget:setDirection(North)

				BattlePass.lastRewardStep = var_26_0
				BattlePass.lastCameraPosition = RewardPositions[var_26_0].scrollPosition
			end
		end
	end

	local var_25_1 = BattlePass.window:recursiveGetChildById("playButton")

	if var_25_1 then
		function var_25_1.onClick()
			if not BattlePass.isAnimatingWalk then
				BattlePass:updatePlayerPosition()
			end
		end
	end

	local var_25_2 = BattlePass.window:recursiveGetChildById("dropRewardButton")

	if var_25_2 then
		function var_25_2.onClick()
			local var_28_0 = BattlePass.window:recursiveGetChildById("rewardsListPanel")

			if var_28_0 then
				local var_28_1 = not var_28_0:isVisible()

				var_28_0:setVisible(var_28_1)

				if var_28_1 then
					var_28_0:raise()
					BattlePass:buildRewardsList()
				end
			end
		end
	end

	function BattlePass.scrollBarWidget.canChangeValue()
		return not BattlePass.isAnimatingWalk
	end

	g_keyboard.bindKeyPress("Tab", var_0_17, BattlePass.window)
	loadMenu("challengesMenu")
	var_0_16()
	connect(g_game, {
		onGameStart = var_0_13,
		onGameEnd = var_0_14,
		onResourceBalance = var_0_15
	})

	-- The Battle Pass module can be loaded by the main-panel button after the
	-- character is already online. In that case onGameStart has already fired,
	-- so initialise the protocol explicitly.
	if g_game.isOnline() then
		scheduleEvent(function()
			var_0_13()
		end, 50)
	end
end

local function var_0_19(arg_30_0, arg_30_1, arg_30_2)
	if not arg_30_2 or not arg_30_2.action then
		return
	end

	if arg_30_2.action == "missions" then
		BattlePass.onBattlePassMissions(arg_30_2.playerOutfit, arg_30_2.beginTime, arg_30_2.endTime, arg_30_2.points, arg_30_2.rerollPrice, arg_30_2.battlePassActive, arg_30_2.currentRewardStep, arg_30_2.nextStepPoints, arg_30_2.dailyBeginTime, arg_30_2.dailyEndTime, arg_30_2.dailyMissions, arg_30_2.generalMissions, arg_30_2.coinsBalance, arg_30_2.bankBalance, arg_30_2.goldBalance, arg_30_2.battlepasPoints)
		if BattlePass.pendingOpen then
			BattlePass.pendingOpen = false
			show()
		end
	elseif arg_30_2.action == "rewards" then
		BattlePass.onBattlePassRewards(arg_30_2.rewardSteps)
	elseif arg_30_2.action == "shop" then
		BattlePass.onBattlePassShop(arg_30_2.shopItems, arg_30_2.shopPoints)
	end

	var_0_18()
end

function terminate()
	var_0_10()

	_G.bpc = nil


	if BattlePass.window then
		g_keyboard.unbindKeyPress("Tab", var_0_17, BattlePass.window)
	end

	pcall(ProtocolGame.unregisterExtendedJSONOpcode, var_0_1)
	disconnect(g_game, {
		onGameStart = var_0_13,
		onGameEnd = var_0_14,
		onResourceBalance = var_0_15
	})

	if BattlePassRewards and BattlePassRewards.claimRewardWindow then
		BattlePassRewards.claimRewardWindow:destroy()

		BattlePassRewards.claimRewardWindow = nil
	end

	if BattlePassRewards and BattlePassRewards.confirmRewardWindow then
		BattlePassRewards.confirmRewardWindow:destroy()

		BattlePassRewards.confirmRewardWindow = nil
	end

	if BattlePass.dailyRerollWindow then
		BattlePass.dailyRerollWindow:destroy()

		BattlePass.dailyRerollWindow = nil
	end

	if BattlePass.window then
		BattlePass.window:destroy()

		BattlePass.window = nil
	end

	BattlePass.rewardContainersBuilt = false
	BattlePass.rewardWidgetCache = {}
	BattlePass.missionWidgetCache = {}
	BattlePass.missionContainersBuilt = false
	BattlePass.dailyContainersBuilt = false
	BattlePass.shopWidgetCache = nil
	BattlePass.shopBuiltSignature = nil
end

function var_0_13()
	pcall(ProtocolGame.unregisterExtendedJSONOpcode, var_0_1)
	ProtocolGame.registerExtendedJSONOpcode(var_0_1, var_0_19)
	BattlePass:loadConfigJson()
	BattlePass:loadPlayerPosition()
	BattlePass.refreshLocalSeasonState()

	local var_32_0 = BattlePass.window:recursiveGetChildById("dailyMissionsBg")

	if not BattlePass.dailyContainersBuilt then
		BattlePass.missionWidgetCache.daily = {}

		var_32_0:destroyChildren()

		for iter_32_0 = 1, 2 do
			local var_32_1 = g_ui.createWidget("DailyMissionWidget", var_32_0)
			local var_32_2 = var_32_1:recursiveGetChildById("dailyMissionIconImage")
			local var_32_3 = iter_32_0 == 1 and "daily-free-icon" or "daily-vip-icon"

			var_32_2:setImageSource("/images/game/battlepass/" .. var_32_3)

			var_32_1._dmc = {
				name = var_32_1:recursiveGetChildById("dailyMissionName"),
				points = var_32_1:recursiveGetChildById("dailyMissionPoints"),
				progress = var_32_1:recursiveGetChildById("dailyMissionProgress"),
				progressText = var_32_1:recursiveGetChildById("dailyMissionProgressText"),
				info = var_32_1:recursiveGetChildById("dailyMissionInformation"),
				blockedIcon = var_32_1:recursiveGetChildById("dailyBlockedMissionIcon"),
				freeIcon = var_32_1:recursiveGetChildById("dailyFreeIcon"),
				rerollBtn = var_32_1:recursiveGetChildById("dailyRerollButton"),
				iconImage = var_32_2,
				progressPanel = var_32_1:recursiveGetChildById("dailyProgressPanel"),
				completedIcon = var_32_1:recursiveGetChildById("dailyCompletedIcon")
			}
			BattlePass.missionWidgetCache.daily[iter_32_0] = var_32_1
		end

		BattlePass.dailyContainersBuilt = true
	else
		for iter_32_1 = 1, 2 do
			local var_32_4 = BattlePass.missionWidgetCache.daily[iter_32_1] or var_32_0:getChildByIndex(iter_32_1)

			if var_32_4 then
				var_32_4:setEnabled(true)
				var_32_4:setVisible(true)
			end
		end
	end

	local var_32_5 = BattlePass.window:recursiveGetChildById("missionsBackground")

	if not BattlePass.missionContainersBuilt then
		BattlePass.missionWidgetCache.season = {}

		var_32_5:destroyChildren()

		for iter_32_2 = 1, 40 do
			local var_32_6 = g_ui.createWidget("MissionWidget", var_32_5)

			var_32_6._smc = {
				name = var_32_6:recursiveGetChildById("missionName"),
				points = var_32_6:recursiveGetChildById("missionPoints"),
				progress = var_32_6:recursiveGetChildById("missionProgress"),
				progressText = var_32_6:recursiveGetChildById("missionProgressText"),
				desc = var_32_6:recursiveGetChildById("missionDesc"),
				blockedIcon = var_32_6:recursiveGetChildById("blockedMissionIcon"),
				rerollBtn = var_32_6:recursiveGetChildById("missionRerollButton"),
				iconImage = var_32_6:recursiveGetChildById("missionIconImage"),
				completedIcon = var_32_6:recursiveGetChildById("completedIcon"),
				progressPanel = var_32_6:recursiveGetChildById("progressPanel"),
				finishedCover = var_32_6:recursiveGetChildById("missionFinishedCover")
			}
			BattlePass.missionWidgetCache.season[iter_32_2] = var_32_6
		end

		BattlePass.missionContainersBuilt = true
	else
		for iter_32_3 = 1, 40 do
			local var_32_7 = BattlePass.missionWidgetCache.season[iter_32_3] or var_32_5:getChildByIndex(iter_32_3)

			if var_32_7 then
				var_32_7:setEnabled(true)
				var_32_7:setVisible(true)
			end
		end
	end

	if BattlePassRewards.claimRewardWindow then
		BattlePassRewards.claimRewardWindow:destroy()

		BattlePassRewards.claimRewardWindow = nil
	end

	var_0_9("online_request")

	if var_0_0 then
		BattlePass.eventHandles.online_request = scheduleEvent(function()
			BattlePass.eventHandles.online_request = nil

			BattlePassAssets.loadDevData()
		end, 200)
	else
		BattlePass.eventHandles.online_request = scheduleEvent(function()
			BattlePass.eventHandles.online_request = nil

			var_0_3({
				action = "requestData"
			})
		end, 500)
	end
end

function var_0_14()
	hide()
	var_0_10()

	BattlePass.seasonActive = false

	BattlePass.updateMainpanelButton()

	BattlePass.lastRewardStep = BattlePass.currentRewardStep

	local var_35_0 = RewardPositions[BattlePass.currentRewardStep]

	BattlePass.lastCameraPosition = var_35_0 and var_35_0.scrollPosition or 0

	BattlePass.outfitWidget:setMarginLeft(165)
	BattlePass:saveConfigJson()

	if BattlePassRewards.claimRewardWindow then
		BattlePassRewards.claimRewardWindow:destroy()

		BattlePassRewards.claimRewardWindow = nil
	end
end

function var_0_18()
	local var_36_0 = BattlePass.window and BattlePass.window:recursiveGetChildById("bpPoints")

	if not var_36_0 then
		return
	end

	local var_36_1 = g_game.getLocalPlayer()

	if not var_36_1 then
		return
	end

	local var_36_2 = var_36_1:getResourceBalance(ResourceTypes.COIN_TRANSFERRABLE) or 0

	var_36_0:setText(comma_value(var_36_2))
end

local function var_0_20()
	local var_37_0 = g_game.getLocalPlayer()

	if not var_37_0 or not var_37_0.getResourceValue then
		return
	end

	local var_37_1 = BattlePass.window:recursiveGetChildById("rCoins")

	if not var_37_1 then
		return
	end

	local var_37_2, var_37_3 = pcall(function()
		return var_37_0:getResourceValue(ResourceBank)
	end)

	if not var_37_2 then
		return
	end

	local var_37_4, var_37_5 = pcall(function()
		return var_37_0:getResourceValue(ResourceInventary)
	end)

	if not var_37_4 then
		return
	end

	local var_37_6 = {}

	setStringColor(var_37_6, "Cash: " .. comma_value(var_37_5), "#3f3f3f")
	setStringColor(var_37_6, " $", "#f7e6fe")
	setStringColor(var_37_6, "\nBank: " .. comma_value(var_37_3), "#3f3f3f")
	setStringColor(var_37_6, " $", "#f7e6fe")
	var_37_1:setText(comma_value(var_37_3 + var_37_5))
	var_37_1:setTooltip(var_37_6)
end

function BattlePass.showBattlePass(arg_40_0)
	if not BattlePass.seasonActive then
		return
	end

	BattlePass.window:show(true)
	BattlePass.window:raise()
	BattlePass.window:focus()
	var_0_20()
end

function show()
	if not BattlePass.seasonActive then
		return
	end

	BattlePass.window:show(true)
	BattlePass.window:raise()
	BattlePass.window:focus()
	g_keyboard.bindKeyPress("Tab", var_0_17, BattlePass.window)
end

function openOrPreview()
	if not g_game.isOnline() then
		return
	end

	BattlePass.pendingOpen = true
	var_0_3({
		action = "requestData"
	})

	if BattlePass.seasonActive then
		BattlePass.pendingOpen = false
		show()
	end
end

function hide()
	BattlePass.window:hide()
	var_0_10()
	g_keyboard.unbindKeyPress("Tab", var_0_17, BattlePass.window)
end

function BattlePass.debugOpenRewards()
	if not g_game.isOnline() then
		g_logger.warning("[BattlePass] bpc(): enter the game first.")

		return
	end

	if not BattlePass.window then
		return
	end

	BattlePassAssets.loadDevData()
	BattlePass.window:show(true)
	BattlePass.window:raise()
	BattlePass.window:focus()
	g_keyboard.bindKeyPress("Tab", var_0_17, BattlePass.window)
	loadMenu("rewardsMenu")
end

_G.bpc = BattlePass.debugOpenRewards

function var_0_16()
	if BattlePass.rewardContainersBuilt then
		return
	end

	local var_44_0 = BattlePass.window:recursiveGetChildById("progressPanelContent")

	if not var_44_0 then
		return
	end

	BattlePass.rewardWidgetCache = {}
	BattlePass.stepMarkerCache = {}

	local function var_44_1(arg_45_0, arg_45_1)
		local var_45_0 = 0

		for iter_45_0 = 0, 71 do
			if arg_45_1 < MapFragmentCumX[iter_45_0 + 1] then
				var_45_0 = iter_45_0

				break
			end

			var_45_0 = iter_45_0
		end

		arg_45_0:addAnchor(AnchorLeft, "mapFragment" .. var_45_0, AnchorLeft)
		arg_45_0:setMarginLeft(arg_45_1 - MapFragmentCumX[var_45_0])
	end

	for iter_44_0, iter_44_1 in ipairs(RewardPositions) do
		BattlePass.rewardWidgetCache[iter_44_0] = {}

		for iter_44_2, iter_44_3 in pairs(iter_44_1.positions) do
			local var_44_2 = iter_44_2 .. "RewardWidget" .. iter_44_0
			local var_44_3 = g_ui.createWidget("RewardWidget", var_44_0)

			var_44_3:setId(var_44_2)
			var_44_1(var_44_3, iter_44_3.marginLeft)
			var_44_3:setMarginTop(iter_44_3.marginTop)
			var_44_3:setVisible(false)

			local var_44_4 = iter_44_2 == "free" and "/images/game/battlepass/free-reward-chest" or "/images/game/battlepass/vip-reward-chest"
			local var_44_5 = var_44_3:recursiveGetChildById("rewardBoxImage")

			var_44_5:setImageSource(var_44_4)
			var_44_5:setImageClip("30 32 29 31")
			var_44_5:setTooltip(string.format("Battle Pass %s Reward\nUnlocked at level %d", string.capitalize(iter_44_2), iter_44_0))

			function var_44_5.onClick()
				local var_44_12 = BattlePass:getRewardMarginLeft(iter_44_0)
				BattlePass:doAnimatePlayerMove(var_44_12, iter_44_0, function()
					BattlePassRewards:onConfirmClaimReward(iter_44_0, iter_44_2)
				end)
			end

			local var_44_6 = iter_44_2 .. "BlockedRewardWidget" .. iter_44_0
			local var_44_7 = g_ui.createWidget("BlockedRewardWidget", var_44_0)

			var_44_7:setId(var_44_6)
			var_44_1(var_44_7, iter_44_3.marginLeft)
			var_44_7:setMarginTop(iter_44_3.marginTop)
			var_44_7:setVisible(true)

			local var_44_8 = var_44_7:recursiveGetChildById("lockedBoxImage")

			var_44_8:setImageSource(var_44_4)
			var_44_8:setTooltip(string.format("Battle Pass %s Reward\nUnlock at level %d", string.capitalize(iter_44_2), iter_44_0))

			BattlePass.rewardWidgetCache[iter_44_0][iter_44_2] = {
				rewardWidget = var_44_3,
				blockedReward = var_44_7,
				rewardBoxImage = var_44_5,
				lockedBoxImage = var_44_8
			}

			if iter_44_2 == "premium" then
				local var_44_9 = g_ui.createWidget("StepMarker", var_44_0)

				var_44_9:setId("stepMarker_" .. iter_44_0)

				local var_44_10 = iter_44_0 == #RewardPositions and iter_44_3.marginLeft - 60 or iter_44_3.marginLeft

				var_44_1(var_44_9, var_44_10)
				var_44_9:setMarginTop(226)

				local var_44_11 = iter_44_0

				function var_44_9.onClick()
					BattlePass.confirmBuySteps(var_44_11)
				end

				BattlePass.stepMarkerCache[iter_44_0] = var_44_9
			end
		end
	end

	local var_44_12 = var_44_0:getChildById("playerOutfit")

	if var_44_12 then
		var_44_12:raise()
	end

	BattlePass.rewardContainersBuilt = true
end

function loadMenu(arg_48_0)
	BattlePass.currentMenu = arg_48_0

	local var_48_0 = {
		"challengesMenu",
		"rewardsMenu",
		"shopMenu"
	}

	for iter_48_0, iter_48_1 in ipairs(var_48_0) do
		local var_48_1 = BattlePass.window.mainPanel.optionsTabBar:getChildById(iter_48_1)

		if var_48_1 then
			var_48_1:setChecked(false)
		end
	end

	local var_48_2 = BattlePass.window.mainPanel.optionsTabBar:getChildById(arg_48_0)

	if var_48_2 then
		var_48_2:setChecked(true)
	end

	local var_48_3 = BattlePass.window:recursiveGetChildById("shopPanel")
	local var_48_4 = BattlePass.window:recursiveGetChildById("shopScrollBar")

	if arg_48_0 == "challengesMenu" then
		BattlePass.missionPanel:show(true)
		BattlePass.progressPanel:hide()

		if var_48_3 then
			var_48_3:hide()
		end

		if var_48_4 then
			var_48_4:hide()
		end

		if g_game.isOnline() then
			local var_48_5 = BattlePass.getNextResetWeek(BattlePass.calculateWeekNumber())
			local var_48_6 = BattlePass.window:recursiveGetChildById("unlockInfo")

			var_0_11(var_48_6, var_48_5)
		end
	elseif arg_48_0 == "rewardsMenu" then
		BattlePass.scrollBarWidget:setValue(BattlePass.lastCameraPosition)
		BattlePass.outfitWidget:setDirection(BattlePass.currentRewardStep == 0 and East or North)
		var_0_9("rewardsMenuShow")

		BattlePass.eventHandles.rewardsMenuShow = scheduleEvent(function()
			BattlePass.eventHandles.rewardsMenuShow = nil

			BattlePass.missionPanel:hide()

			if var_48_3 then
				var_48_3:hide()
			end

			if var_48_4 then
				var_48_4:hide()
			end

			BattlePass.progressPanel:show(true)
			BattlePass.progressPanel:raise()
			BattlePass.window:raise()
			BattlePass.window:focus()
			BattlePass:updatePlayerPosition()
		end, 50)
	elseif arg_48_0 == "shopMenu" then
		BattlePass.missionPanel:hide()
		BattlePass.progressPanel:hide()

		if var_48_3 then
			var_48_3:show(true)

			if var_48_4 then
				var_48_4:show()
			end

			BattlePass:loadShopItems(var_48_3)
		end
	end
end

function BattlePass.onBattlePassShop(arg_50_0, arg_50_1)
	BattlePass.serverShopItems = arg_50_0 or {}
	BattlePass.serverShopPoints = arg_50_1 or 0

	local var_50_0 = BattlePass.window:recursiveGetChildById("shopPoints")

	if var_50_0 then
		var_50_0:setText(tostring(arg_50_1 or 0))
	end

	local var_50_1 = BattlePass.window:recursiveGetChildById("shopBackground")

	if var_50_1 and var_50_1:isVisible() then
		BattlePass:loadShopItems(var_50_1)
	end
end

local function var_0_21(arg_51_0)
	local var_51_0 = {
		tostring(#arg_51_0)
	}

	for iter_51_0, iter_51_1 in ipairs(arg_51_0) do
		var_51_0[#var_51_0 + 1] = tostring(iter_51_1.id or iter_51_0) .. ":" .. tostring(iter_51_1.type or "")
	end

	return table.concat(var_51_0, "|")
end

function BattlePass.buildShop(arg_52_0, arg_52_1, arg_52_2)
	arg_52_1:destroyChildren()

	BattlePass.shopWidgetCache = {}

	local var_52_0 = {
		item = "boost",
		outfit = "gear",
		mount = "mount",
		prey_wildcard = "boost",
		bless = "boost",
		charm = "boost",
		vip = "boost"
	}

	for iter_52_0, iter_52_1 in ipairs(arg_52_2) do
		local var_52_1, var_52_2 = pcall(function()
			local var_53_0 = g_ui.createWidget("ShopItemWidget", arg_52_1)
			local var_53_1 = var_53_0:recursiveGetChildById("shopItemType")
			local var_53_2 = var_52_0[iter_52_1.type] or var_52_0[iter_52_1.itemType]

			if var_53_2 then
				var_53_1:setImageSource("/images/game/battlepass/" .. var_53_2)
			end

			local var_53_3 = var_53_0:recursiveGetChildById("shopItemName")
			local var_53_4 = var_53_0:recursiveGetChildById("shopItemDesc")
			local var_53_5 = var_53_0:recursiveGetChildById("shopItemPrice")
			local var_53_6 = var_53_0:recursiveGetChildById("shopBuyButton")

			var_53_3:setText(iter_52_1.name or "")
			var_53_4:setText(iter_52_1.description or "")
			var_53_5:setText(tostring(iter_52_1.price or 0))

			local var_53_7 = var_53_0:recursiveGetChildById("shopItemImage")

			if var_53_7 then
				if iter_52_1.type == "mount" and iter_52_1.mountId and iter_52_1.mountId > 0 then
					local var_53_8 = g_ui.createWidget("UICreature", var_53_7)

					var_53_8:setOutfit({
						type = iter_52_1.looktype or iter_52_1.mountId
					})
					var_53_8:fill("parent")

					if var_53_8.setFixedCreatureSize then
						var_53_8:setFixedCreatureSize(true)
					end

					if var_53_8:getCreature() then
						var_53_8:getCreature():setStaticWalking(1000)
					end
				elseif iter_52_1.type == "outfit" then
					local var_53_9 = iter_52_1.outfitMale or iter_52_1.outfitFemale or 0

					if var_53_9 > 0 then
						local var_53_10 = g_game.getLocalPlayer()
						local var_53_11 = {
							addons = 3,
							type = var_53_9
						}

						if var_53_10 then
							local var_53_12 = var_53_10:getOutfit()

							var_53_11.head = var_53_12.head
							var_53_11.body = var_53_12.body
							var_53_11.legs = var_53_12.legs
							var_53_11.feet = var_53_12.feet
						end

						local var_53_13 = g_ui.createWidget("UICreature", var_53_7)

						var_53_13:setOutfit(var_53_11)
						var_53_13:fill("parent")

						if var_53_13.setFixedCreatureSize then
							var_53_13:setFixedCreatureSize(true)
						end

						if var_53_13:getCreature() then
							var_53_13:getCreature():setStaticWalking(1000)
						end
					end
				elseif iter_52_1.type == "item" and iter_52_1.itemId and iter_52_1.itemId > 0 then
					local var_53_14 = g_ui.createWidget("UIItem", var_53_7)

					var_53_14:setItemId(iter_52_1.itemId)
					var_53_14:setVirtual(true)
					var_53_14:fill("parent")
				elseif iter_52_1.type == "bless" then
					local var_53_15 = g_ui.createWidget("UIWidget", var_53_7)

					var_53_15:fill("parent")
					var_53_15:setImageSource("/game_battlepass/blessings")
					var_53_15:setImageAutoResize(true)
				elseif iter_52_1.type == "charm" then
					local var_53_16 = g_ui.createWidget("UIWidget", var_53_7)

					var_53_16:fill("parent")
					var_53_16:setImageSource("/game_battlepass/charm")
					var_53_16:setImageAutoResize(true)
				elseif iter_52_1.type == "vip" then
					local var_53_17 = g_ui.createWidget("UIWidget", var_53_7)

					var_53_17:fill("parent")
					var_53_17:setImageSource("/game_battlepass/premiumtime")
					var_53_17:setImageAutoResize(true)
				elseif iter_52_1.type == "prey_wildcard" then
					local var_53_18 = g_ui.createWidget("UIWidget", var_53_7)

					var_53_18:fill("parent")
					var_53_18:setImageSource("/images/game/prey/prey_wildcard")
					var_53_18:setImageAutoResize(true)
				end
			end

			BattlePass.shopWidgetCache[iter_52_0] = {
				widget = var_53_0,
				priceLabel = var_53_5,
				buyBtn = var_53_6,
				item = iter_52_1
			}
		end)
	end

	BattlePass:updateShopPrices(arg_52_2)
end

function BattlePass.updateShopPrices(arg_54_0, arg_54_1)
	local var_54_0 = BattlePass.battlepasPoints or 0

	for iter_54_0, iter_54_1 in ipairs(arg_54_1) do
		local var_54_1 = BattlePass.shopWidgetCache and BattlePass.shopWidgetCache[iter_54_0]

		if var_54_1 then
			local var_54_2 = iter_54_1.price or 0

			var_54_1.priceLabel:setText(tostring(var_54_2))

			if var_54_0 < var_54_2 then
				var_54_1.priceLabel:setColor("#d33c3c")
			else
				var_54_1.priceLabel:setColor("#c0c0c0")
			end

			local var_54_3 = var_54_1.buyBtn
			local var_54_4 = false

			if var_54_4 then
				var_54_3:setText("Owned")
				var_54_3:setEnabled(false)
				var_54_3:setOpacity(0.5)
			else
				var_54_3:setEnabled(true)
				var_54_3:setOpacity(1)

				function var_54_3.onClick()
					if (BattlePass.battlepasPoints or 0) < var_54_2 then
						modules.game_textmessage.displayFailureMessage("Insufficient Battle Pass Points. Need " .. var_54_2 .. ", have " .. (BattlePass.battlepasPoints or 0) .. ".")

						return
					end

					var_0_3({
						action = "buyShopItem",
						shopItemId = iter_54_1.id or iter_54_0
					})
				end
			end
		end
	end
end

function BattlePass.loadShopItems(arg_56_0, arg_56_1)
	local var_56_0 = BattlePass.serverShopItems or BattlePassAssets and BattlePassAssets.shopItems or {}
	local var_56_1 = var_0_21(var_56_0)

	if BattlePass.shopBuiltSignature == var_56_1 and BattlePass.shopWidgetCache then
		BattlePass:updateShopPrices(var_56_0)

		return
	end

	BattlePass.shopBuiltSignature = var_56_1

	BattlePass:buildShop(arg_56_1, var_56_0)
end

function var_0_17()
	local var_57_0 = {
		"challengesMenu",
		"rewardsMenu",
		"shopMenu"
	}
	local var_57_1 = BattlePass.currentMenu
	local var_57_2

	for iter_57_0, iter_57_1 in ipairs(var_57_0) do
		if iter_57_1 == var_57_1 then
			var_57_2 = iter_57_0

			break
		end
	end

	var_57_2 = var_57_2 or 1

	local var_57_3 = var_57_0[var_57_2 == #var_57_0 and 1 or var_57_2 + 1]

	loadMenu(var_57_3)
end

function BattlePass.isSeasonActive()
	local var_58_0 = os.time()

	return BattlePass.beginTime > 0 and BattlePass.endTime > 0 and var_58_0 >= BattlePass.beginTime and var_58_0 <= BattlePass.endTime
end

function BattlePass.updateMainpanelButton()
	local var_59_0 = g_modules.getModule("game_mainpanel")

	if not var_59_0 or not var_59_0:isLoaded() then
		return
	end

	local var_59_1 = var_59_0:getSandbox()
	local var_59_2 = var_59_1 and var_59_1.setBattlepassButtonVisible

	if var_59_2 then
		var_59_2(BattlePass.seasonActive)
	end
end

function BattlePass.onBattlePassMissions(arg_60_0, arg_60_1, arg_60_2, arg_60_3, arg_60_4, arg_60_5, arg_60_6, arg_60_7, arg_60_8, arg_60_9, arg_60_10, arg_60_11, arg_60_12, arg_60_13, arg_60_14, arg_60_15)
	local var_60_0 = g_game.getLocalPlayer()

	if var_60_0 then
		BattlePass.outfitWidget:setOutfit(var_60_0:getOutfit())
	end

	BattlePass.beginTime = arg_60_1
	BattlePass.endTime = arg_60_2
	BattlePass.seasonActive = BattlePass.isSeasonActive()

	BattlePass.updateMainpanelButton()

	if not BattlePass.seasonActive and BattlePass.window and BattlePass.window:isVisible() then
		hide()
	end

	BattlePass.progressPoints = arg_60_3
	BattlePass.dailyRerollPrice = arg_60_4
	BattlePass.premiumBattlepass = arg_60_5
	BattlePass.currentRewardStep = arg_60_6
	BattlePass.nextStepPoints = arg_60_7
	BattlePass.dailyMissionsBegin = arg_60_8
	BattlePass.dailyMissionsExpire = arg_60_9
	BattlePass.dailyMissions = arg_60_10
	BattlePass.seassonMissions = arg_60_11
	BattlePass.coinsBalance = arg_60_12 or 0
	BattlePass.bankBalance = arg_60_13 or 0
	BattlePass.goldBalance = arg_60_14 or 0
	BattlePass.battlepasPoints = arg_60_15 or 0

	local var_60_1 = BattlePass.window:recursiveGetChildById("rCoins")

	if var_60_1 then
		local var_60_2 = (BattlePass.bankBalance or 0) + (BattlePass.goldBalance or 0)

		var_60_1:setText(comma_value(var_60_2))
	end

	var_0_18()

	local var_60_3 = BattlePass.window:recursiveGetChildById("shopPoints")

	if var_60_3 then
		var_60_3:setText(tostring(BattlePass.battlepasPoints))
	end

	local var_60_4 = BattlePass.window:recursiveGetChildById("getVipPassTicket")
	local var_60_5 = BattlePass.window:recursiveGetChildById("getVipPassTicketBorder")

	if var_60_4 then
		var_60_4:setVisible(not BattlePass.premiumBattlepass)
		var_60_5:setVisible(not BattlePass.premiumBattlepass)
	end

	BattlePass:configureMissionPanel()

	if modules.game_battlepasstracker then
		modules.game_battlepasstracker.updateData(arg_60_6, arg_60_10, arg_60_11)
	end

	if BattlePass.currentRewardStep == 0 then
		BattlePass.lastCameraPosition = 0
		BattlePass.lastRewardStep = 0

		BattlePass.outfitWidget:setMarginLeft(165)
		BattlePass.scrollBarWidget:setValue(0)
	end
end

function BattlePass.onBattlePassRewards(arg_61_0)
	BattlePass.rewardSteps = {}
	-- Until the server supplies its own reward catalogue, use the validated
	-- Crystal catalogue instead of rendering an empty rewards track.
	if not arg_61_0 or #arg_61_0 == 0 then
		BattlePass.rewardSteps = BattlePassAssets and BattlePassAssets.rewardSteps or {}
	else
		BattlePass.rewardSteps = arg_61_0
	end

	BattlePass:configureRewardPanel()
end

function BattlePass.calculateWeekNumber()
	if not BattlePass.beginTime or BattlePass.beginTime == 0 then
		return 1
	end

	local var_62_0 = os.time()
	local var_62_1 = os.date("*t", BattlePass.beginTime)

	if not var_62_1 then
		return 1
	end

	local var_62_2 = os.time({
		min = 0,
		sec = 0,
		hour = 10,
		year = var_62_1.year,
		month = var_62_1.month,
		day = var_62_1.day
	})
	local var_62_3 = os.difftime(var_62_0, var_62_2)

	if var_62_3 < 0 then
		return 1
	end

	return math.floor(var_62_3 / 604800) + 1
end

function BattlePass.getNextResetWeek(arg_63_0)
	if not BattlePass.beginTime or BattlePass.beginTime == 0 then
		return os.time() + 86400
	end

	local var_63_0 = 7 * arg_63_0
	local var_63_1 = os.date("*t", BattlePass.beginTime)

	if not var_63_1 then
		return os.time() + 86400
	end

	local var_63_2 = os.time({
		min = 0,
		sec = 0,
		hour = 10,
		year = var_63_1.year,
		month = var_63_1.month,
		day = var_63_1.day
	}) + var_63_0 * 86400
	local var_63_3 = os.date("*t", var_63_2)

	return os.time({
		min = 0,
		sec = 0,
		hour = 10,
		year = var_63_3.year,
		month = var_63_3.month,
		day = var_63_3.day
	})
end

function BattlePass.configureMissionPanel(arg_64_0)
	BattlePass.window:recursiveGetChildById("playerLevel"):setText(BattlePass.currentRewardStep)
	BattlePass.window:recursiveGetChildById("currentlyLevelText"):setText(string.format("%s/%s", BattlePass.progressPoints, BattlePass.nextStepPoints))
	BattlePass.window:recursiveGetChildById("levelProgress"):setPercent(BattlePass.progressPoints / BattlePass.nextStepPoints * 100)

	local var_64_0 = BattlePass.endTime - BattlePass.beginTime
	local var_64_1 = (BattlePass.endTime - os.time()) / var_64_0 * 100
	local var_64_2, var_64_3 = var_0_7(BattlePass.endTime)

	BattlePass.window:recursiveGetChildById("seasonTimeText"):setText(var_64_2)
	BattlePass.window:recursiveGetChildById("seasonHourglassIcon"):setTooltip(var_64_3)
	BattlePass.window:recursiveGetChildById("seasonTimeProgress"):setPercent(var_64_1)

	local var_64_4 = BattlePass.getNextResetWeek(BattlePass.calculateWeekNumber())
	local var_64_5 = BattlePass.window:recursiveGetChildById("unlockInfo")

	var_64_5:setText(string.format("New missions available in: %s", var_0_8(var_64_4)))
	var_0_11(var_64_5, var_64_4)

	local var_64_6 = BattlePass.dailyMissionsExpire - BattlePass.dailyMissionsBegin
	local var_64_7 = (BattlePass.dailyMissionsExpire - os.time()) / var_64_6 * 100
	local var_64_8, var_64_9 = var_0_7(BattlePass.dailyMissionsExpire)

	BattlePass.window:recursiveGetChildById("dailyTimeText"):setText(var_64_8)
	BattlePass.window:recursiveGetChildById("hourglassIcon"):setTooltip(var_64_9)
	BattlePass.window:recursiveGetChildById("dailyTimeProgress"):setPercent(var_64_7)

	local var_64_10 = BattlePass.window:recursiveGetChildById("dailyMissionsBg")

	for iter_64_0, iter_64_1 in ipairs(BattlePass.dailyMissions) do
		if iter_64_0 > 2 then
			break
		end

		local var_64_11 = var_64_10:getChildByIndex(iter_64_0)
		local var_64_12 = var_64_11._dmc

		if not var_64_12 then
			var_64_12 = {
				name = var_64_11:recursiveGetChildById("dailyMissionName"),
				points = var_64_11:recursiveGetChildById("dailyMissionPoints"),
				progress = var_64_11:recursiveGetChildById("dailyMissionProgress"),
				progressText = var_64_11:recursiveGetChildById("dailyMissionProgressText"),
				info = var_64_11:recursiveGetChildById("dailyMissionInformation"),
				blockedIcon = var_64_11:recursiveGetChildById("dailyBlockedMissionIcon"),
				freeIcon = var_64_11:recursiveGetChildById("dailyFreeIcon"),
				rerollBtn = var_64_11:recursiveGetChildById("dailyRerollButton"),
				iconImage = var_64_11:recursiveGetChildById("dailyMissionIconImage"),
				progressPanel = var_64_11:recursiveGetChildById("dailyProgressPanel"),
				completedIcon = var_64_11:recursiveGetChildById("dailyCompletedIcon")
			}
			var_64_11._dmc = var_64_12
		end

		local var_64_13 = iter_64_1.currentProgress == iter_64_1.maxProgress

		var_64_12.name:setText(iter_64_1.missionName)
		var_64_12.points:setText(iter_64_1.rewardPoints)
		var_64_12.progress:setPercent(iter_64_1.currentProgress / iter_64_1.maxProgress * 100)
		var_64_12.progressText:setText(string.format("%s/%s", var_0_4(iter_64_1.currentProgress), var_0_4(iter_64_1.maxProgress)))

		local var_64_14 = iter_64_1.isPremium or iter_64_0 == 2
		local var_64_15 = var_64_14 and not BattlePass.premiumBattlepass

		var_64_12.info:setTooltip(iter_64_1.missionDescription)
		var_64_12.blockedIcon:setVisible(var_64_15)
		var_64_12.freeIcon:setVisible(false)
		var_64_12.rerollBtn:setVisible(not var_64_13 and not var_64_15)
		var_64_12.name:setVisible(not var_64_15)
		var_64_12.points:setVisible(not var_64_15)
		var_64_12.progress:setVisible(not var_64_15)
		var_64_12.progressText:setVisible(not var_64_15)
		var_64_12.info:setVisible(not var_64_15)

		function var_64_12.rerollBtn.onClick()
			if not BattlePass:running() then
				return true
			end

			BattlePass:rerollDailyMission(iter_64_1)
		end

		local var_64_16 = not var_64_14 and "daily-free-icon" or "daily-vip-icon"

		if var_64_13 then
			var_64_16 = "daily-icon-complete"
		end

		var_64_12.iconImage:setImageSource("/images/game/battlepass/" .. var_64_16)
		var_64_12.progressPanel:setVisible(not var_64_13)
		var_64_12.completedIcon:setVisible(var_64_13)

		if not BattlePass:running() then
			var_64_11:setEnabled(false)
			var_64_11:setVisible(false)
		end
	end

	local var_64_17 = BattlePass.window:recursiveGetChildById("missionsBackground")
	local var_64_18 = var_0_6(BattlePass.seassonMissions)
	local var_64_19 = {}

	for iter_64_2, iter_64_3 in ipairs(var_64_18) do
		var_64_19[iter_64_3.index] = true
	end

	local var_64_20 = 1

	while true do
		local var_64_21 = var_64_17:getChildByIndex(var_64_20)

		if not var_64_21 then
			break
		end

		if not var_64_19[var_64_20] then
			var_64_21:setVisible(true)
			var_64_21:setEnabled(false)
			var_64_21:setOpacity(0.35)

			local var_64_22 = var_64_21:recursiveGetChildById("missionName")

			if var_64_22 then
				var_64_22:setText("Locked")
			end

			local var_64_23 = var_64_21:recursiveGetChildById("missionDesc")

			if var_64_23 then
				var_64_23:setText("")
			end

			local var_64_24 = var_64_21:recursiveGetChildById("missionPoints")

			if var_64_24 then
				var_64_24:setText("?")
			end

			local var_64_25 = var_64_21:recursiveGetChildById("missionIconImage")

			if var_64_25 then
				var_64_25:setImageSource("/images/game/battlepass/mission-locked-icon")
			end

			local var_64_26 = var_64_21:recursiveGetChildById("missionRerollButton")

			if var_64_26 then
				var_64_26:setVisible(false)
			end

			local var_64_27 = var_64_21:recursiveGetChildById("completedIcon")

			if var_64_27 then
				var_64_27:setVisible(false)
			end

			local var_64_28 = var_64_21:recursiveGetChildById("missionFinishedCover")

			if var_64_28 then
				var_64_28:setVisible(false)
			end

			local var_64_29 = var_64_21:recursiveGetChildById("progressPanel")

			if var_64_29 then
				var_64_29:setVisible(false)
			end

			local var_64_30 = var_64_21:recursiveGetChildById("blockedMissionIcon")

			if var_64_30 then
				var_64_30:setVisible(false)
			end
		end

		var_64_20 = var_64_20 + 1
	end

	for iter_64_4, iter_64_5 in ipairs(var_64_18) do
		local var_64_31 = iter_64_5.data
		local var_64_32 = var_64_17:getChildByIndex(iter_64_5.index)

		if not var_64_32 then
			break
		end

		var_64_32:setVisible(true)
		var_64_32:setEnabled(true)
		var_64_32:setOpacity(1)

		local var_64_33 = var_64_32._smc

		if not var_64_33 then
			var_64_33 = {
				name = var_64_32:recursiveGetChildById("missionName"),
				points = var_64_32:recursiveGetChildById("missionPoints"),
				progress = var_64_32:recursiveGetChildById("missionProgress"),
				progressText = var_64_32:recursiveGetChildById("missionProgressText"),
				desc = var_64_32:recursiveGetChildById("missionDesc"),
				blockedIcon = var_64_32:recursiveGetChildById("blockedMissionIcon"),
				rerollBtn = var_64_32:recursiveGetChildById("missionRerollButton"),
				iconImage = var_64_32:recursiveGetChildById("missionIconImage"),
				completedIcon = var_64_32:recursiveGetChildById("completedIcon"),
				progressPanel = var_64_32:recursiveGetChildById("progressPanel"),
				finishedCover = var_64_32:recursiveGetChildById("missionFinishedCover")
			}
			var_64_32._smc = var_64_33
		end

		var_64_33.name:setText(var_64_31.missionName)
		var_64_33.points:setText(var_64_31.rewardPoints)
		var_64_33.progress:setPercent(var_64_31.currentProgress / var_64_31.maxProgress * 100)
		var_64_33.progressText:setText(string.format("%s/%s", var_0_4(var_64_31.currentProgress), var_0_4(var_64_31.maxProgress)))
		var_64_33.desc:setText(var_64_31.missionDescription)
		var_64_33.blockedIcon:setVisible(false)

		local var_64_34 = var_64_31.currentProgress == var_64_31.maxProgress

		if var_64_33.rerollBtn then
			var_64_33.rerollBtn:setVisible(not var_64_34)

			function var_64_33.rerollBtn.onClick()
				BattlePass:rerollGeneralMission(var_64_31)
			end
		end

		local var_64_35 = var_64_34 and MissionRankIcons[var_64_31.rewardPoints] .. "-complete" or MissionRankIcons[var_64_31.rewardPoints]

		var_64_33.iconImage:setImageSource("/images/game/battlepass/" .. var_64_35)
		var_64_33.completedIcon:setVisible(false)
		var_64_33.progressPanel:setVisible(true)

		local var_64_36 = var_64_33.progressPanel

		if var_64_34 and var_64_36 then
			var_64_36:breakAnchors()
			var_64_36:addAnchor(AnchorBottom, "parent", AnchorBottom)
			var_64_36:addAnchor(AnchorLeft, "parent", AnchorLeft)
			var_64_36:addAnchor(AnchorRight, "parent", AnchorRight)
			var_64_36:setMarginBottom(10)
			var_64_36:setMarginLeft(10)
			var_64_36:setMarginRight(12)

			if var_64_33.progress then
				var_64_33.progress:setImageColor("#2CB204")
			end
		end

		if var_64_33.finishedCover then
			var_64_33.finishedCover:setVisible(var_64_34)
		end

		if not BattlePass:running() then
			var_64_32:setEnabled(false)
			var_64_32:setVisible(false)
		end
	end
end

function BattlePass.configureRewardPanel(arg_67_0)
	if not BattlePass.window then
		return
	end

	for iter_67_0, iter_67_1 in ipairs(BattlePass.rewardSteps) do
		local var_67_0 = BattlePass.rewardWidgetCache[iter_67_1.stepId]

		if var_67_0 then
			for iter_67_2, iter_67_3 in ipairs(iter_67_1.rewards) do
				local var_67_1 = iter_67_3.freeReward and "free" or "premium"
				local var_67_2 = var_67_0[var_67_1]

				if var_67_2 then
					local var_67_3 = var_67_2.rewardWidget
					local var_67_4 = var_67_2.blockedReward
					local var_67_5 = var_67_2.rewardBoxImage
					local var_67_6 = var_67_2.lockedBoxImage
					local var_67_7 = iter_67_1.stepId <= BattlePass.currentRewardStep

					var_67_4:setVisible(not var_67_7)
					var_67_3:setVisible(var_67_7)

					if var_67_6 then
						local var_67_8 = iter_67_3.rewardName or "Reward"

						var_67_6:setTooltip(string.format("Level %d %s Reward\n%s\nUnlocks at level %d", iter_67_1.stepId, iter_67_3.freeReward and "Free" or "Deluxe", var_67_8, iter_67_1.stepId))
					end

					local var_67_9 = var_67_7 and not iter_67_3.hasClamedReward

					if not iter_67_3.freeReward and not BattlePass.premiumBattlepass then
						var_67_9 = false
					end

					if var_67_5 then
						var_67_5:setEnabled(var_67_9)

						local var_67_10 = iter_67_3.hasClamedReward and "Claimed" or var_67_9 and "Click to claim" or "Requires Deluxe"
						local var_67_11 = iter_67_3.rewardName or "Reward"

						var_67_5:setTooltip(string.format("Level %d %s Reward\n%s\n%s", iter_67_1.stepId, iter_67_3.freeReward and "Free" or "Deluxe", var_67_11, var_67_10))
					end

					if iter_67_3.hasClamedReward then
						if var_67_1 == "free" then
							var_67_5:setImageSource("/images/game/battlepass/free-reward-chest-open")
							var_67_5:setImageClip("26 22 38 42")
							var_67_5:setSize("38 42")
							var_67_5:setMarginTop(-10)
						else
							var_67_5:setImageSource("/images/game/battlepass/vip-reward-chest-open")
							var_67_5:setImageClip("24 20 40 44")
							var_67_5:setSize("40 44")
							var_67_5:setMarginTop(-12)
						end
					elseif var_67_1 == "free" then
						var_67_5:setImageSource("/images/game/battlepass/free-reward-chest")
						var_67_5:setImageClip("30 32 29 31")
					else
						var_67_5:setImageSource("/images/game/battlepass/vip-reward-chest")
						var_67_5:setImageClip("30 32 29 31")
					end

					local var_67_12 = iter_67_3.freeReward and "Free" or "Deluxe"

					var_67_5:setTooltip(string.format("Battle Pass %s Reward\n%s at level %d", string.capitalize(var_67_12), iter_67_3.hasClamedReward and "Claimed" or "Unlocked", iter_67_1.stepId))

					if var_67_1 == "free" then
						var_67_6:setImageSource("/images/game/battlepass/free-reward-chest")
					else
						var_67_6:setImageSource("/images/game/battlepass/vip-reward-chest")
					end

					var_67_6:setTooltip(string.format("Battle Pass %s Reward\nUnlock at level %d", string.capitalize(var_67_12), iter_67_1.stepId))
				end
			end
		end
	end

	local var_67_13 = BattlePass.window:recursiveGetChildById("rewardsListPanel")

	if var_67_13 and var_67_13:isVisible() then
		BattlePass:buildRewardsList()
	end

	local var_67_14 = BattlePass.currentRewardStep

	if BattlePass.stepMarkerCache then
		for iter_67_4 = 1, 80 do
			local var_67_15 = BattlePass.stepMarkerCache[iter_67_4]

			if var_67_15 then
				if iter_67_4 <= var_67_14 then
					var_67_15:setImageSource("/images/game/battlepass/silverStep")
					var_67_15:setTooltip(string.format("Step %d: Completed", iter_67_4))
				else
					var_67_15:setImageSource("/images/game/battlepass/goldStep")

					local var_67_16 = var_0_12(var_67_14, iter_67_4)

					var_67_15:setTooltip(string.format("Step %d: %s Tyron Coin", iter_67_4, comma_value(var_67_16)))
				end
			end
		end
	end
end

function BattlePass.getStepsToReward(arg_68_0, arg_68_1)
	local var_68_0 = 0

	for iter_68_0, iter_68_1 in ipairs(RewardPositions) do
		if iter_68_0 <= arg_68_1 then
			var_68_0 = var_68_0 + iter_68_1.stepsTo
		end
	end

	return var_68_0
end

function BattlePass.getRewardMarginLeft(arg_69_0, arg_69_1)
	if arg_69_1 and arg_69_1 > 0 and RewardPositions[arg_69_1] then
		local var_69_0 = RewardPositions[arg_69_1].positions

		if var_69_0 and var_69_0.premium then
			return var_69_0.premium.marginLeft
		end
	end

	return BattlePass.rewardMinMargin
end

function BattlePass.loadPlayerPosition(arg_70_0)
	if not BattlePass.lastRewardStep or BattlePass.lastRewardStep == 0 then
		return
	end

	local var_70_0 = BattlePass:getRewardMarginLeft(BattlePass.lastRewardStep)

	BattlePass.outfitWidget:setMarginLeft(var_70_0)
	BattlePass.scrollBarWidget:setValue(BattlePass.lastCameraPosition)
end

function BattlePass.updatePlayerPosition(arg_71_0)
	local var_71_0 = BattlePass:getRewardMarginLeft(BattlePass.currentRewardStep)
	local var_71_1 = math.abs((BattlePass.currentRewardStep or 0) - (BattlePass.lastRewardStep or 0))

	-- Large jumps (admin/test grants or bought levels) are positioned directly;
	-- animating dozens of map fragments can stall low-end GPUs.
	if var_71_1 > 10 then
		BattlePass.outfitWidget:setMarginLeft(var_71_0)
		local var_71_2 = RewardPositions[BattlePass.currentRewardStep]
		BattlePass.lastRewardStep = BattlePass.currentRewardStep
		BattlePass.lastCameraPosition = var_71_2 and var_71_2.scrollPosition or 0
		BattlePass.scrollBarWidget:setValue(BattlePass.lastCameraPosition)
		BattlePass.outfitWidget:setDirection(North)
		BattlePass:saveConfigJson()
		return
	end

	if var_71_0 > 195 then
		BattlePass.lastCameraPosition = RewardPositions[BattlePass.lastRewardStep].scrollPosition

		BattlePass:doAnimatePlayerMove(var_71_0, BattlePass.currentRewardStep)
	end

	BattlePass:saveConfigJson()
end

function BattlePass.running(arg_72_0)
	if BattlePass.endTime - os.time() <= 0 then
		return false
	end

	return true
end

function BattlePass.doAnimatePlayerMove(arg_73_0, arg_73_1, arg_73_2)
	if arg_73_0 == BattlePass.outfitWidget:getMarginLeft() then
		if arg_73_2 then arg_73_2() end
		return
	end

	var_0_9("animateStep")
	var_0_9("animateFinishDir")

	local var_73_0 = g_game.getLocalPlayer()

	BattlePass.outfitWidget:setDirection(BattlePass.outfitWidget:getMarginLeft() <= arg_73_0 and East or West)
	BattlePass.outfitWidget:getCreature():setStaticWalking(1000)

	BattlePass.isAnimatingWalk = true

	local var_73_1 = BattlePass.outfitWidget:getMarginLeft()
	local var_73_2 = BattlePass.scrollBarWidget

	local function var_73_3()
		BattlePass.outfitWidget:setMarginLeft(arg_73_0)
		BattlePass.outfitWidget:getCreature():setStaticWalking(0)

		BattlePass.isAnimatingWalk = false
		BattlePass.lastRewardStep = arg_73_1 or BattlePass.currentRewardStep

		local var_74_0 = RewardPositions[BattlePass.lastRewardStep]

		BattlePass.lastCameraPosition = var_74_0 and var_74_0.scrollPosition or 0

		BattlePass:saveConfigJson()

		BattlePass.eventHandles.animateFinishDir = scheduleEvent(function()
			BattlePass.eventHandles.animateFinishDir = nil

			BattlePass.outfitWidget:setDirection(North)
		end, 150)

		if arg_73_2 then arg_73_2() end
	end

	local function var_73_4()
		BattlePass.eventHandles.animateStep = nil

		if not BattlePass.outfitWidget:isVisible() then
			var_73_3()

			return true
		end

		if var_73_1 < arg_73_0 then
			var_73_1 = math.min(var_73_1 + 3, arg_73_0)

			BattlePass.outfitWidget:setMarginLeft(var_73_1)

			if var_73_1 < arg_73_0 then
				BattlePass.eventHandles.animateStep = scheduleEvent(var_73_4, 25)

				if var_73_1 >= 350 then
					var_73_2:setValue(var_73_2:getValue() + 3)
				end
			else
				var_73_3()
			end
		elseif var_73_1 > arg_73_0 then
			var_73_1 = math.max(var_73_1 - 3, arg_73_0)
			BattlePass.outfitWidget:setMarginLeft(var_73_1)
			if var_73_1 > arg_73_0 then
				BattlePass.eventHandles.animateStep = scheduleEvent(var_73_4, 25)
				var_73_2:setValue(math.max(0, var_73_2:getValue() - 3))
			else
				var_73_3()
			end
		else
			var_73_3()
		end
	end

	var_73_4()
end

function BattlePass.loadConfigJson(arg_77_0)
	if not LoadedPlayer:isLoaded() then
		return
	end

	local var_77_0 = "/characterdata/" .. LoadedPlayer:getId() .. "/battlepass.json"

	if g_resources.fileExists(var_77_0) then
		local var_77_1, var_77_2 = pcall(function()
			return json.decode(g_resources.readFileContents(var_77_0))
		end)

		if not var_77_1 then
			return g_logger.error("Error while reading characterdata file. Details: " .. var_77_2)
		end

		BattlePass.lastRewardStep = var_77_2.currentRewardStep or 0
		BattlePass.lastCameraPosition = var_77_2.lastCameraPosition or 0
	else
		BattlePass.lastRewardStep = 0
		BattlePass.lastCameraPosition = 0
	end
end

function BattlePass.saveConfigJson(arg_79_0)
	local var_79_0 = {
		currentRewardStep = BattlePass.lastRewardStep,
		lastCameraPosition = BattlePass.lastCameraPosition
	}

	if not LoadedPlayer:isLoaded() then
		return
	end

	local var_79_1 = "/characterdata/" .. LoadedPlayer:getId() .. "/battlepass.json"
	local var_79_2, var_79_3 = pcall(function()
		return json.encode(var_79_0, 2)
	end)

	if not var_79_2 then
		return g_logger.error("Error while saving profile Battlepass data. Data won't be saved. Details: " .. var_79_3)
	end

	if var_79_3:len() > 104857600 then
		return g_logger.error("Something went wrong, file is above 100MB, won't be saved")
	end

	g_resources.writeFileContents(var_79_1, var_79_3)
end

local var_0_22 = {
	[300] = 1000000,
	[100] = 300000,
	[200] = 500000,
	[500] = 2000000
}

local function var_0_23(arg_81_0, arg_81_1)
	local var_81_0 = g_game.getLocalPlayer()

	if not var_81_0 then
		return
	end

	local var_81_1 = arg_81_1 and var_81_0:getLevel() * 800 or var_0_22[arg_81_0.rewardPoints] or 300000
	local var_81_2 = BattlePass.window:recursiveGetChildById("rerollConfirmOverlay")

	if not var_81_2 then
		return
	end

	var_81_2:recursiveGetChildById("rerollConfirmMsg"):setText(string.format("Are you sure you want to reroll the mission \"%s\" for $ %s?", arg_81_0.missionName, comma_value(var_81_1)))

	local var_81_3 = var_81_2:recursiveGetChildById("rerollConfirmOk")
	local var_81_4 = var_81_2:recursiveGetChildById("rerollConfirmCancel")

	local function var_81_5()
		var_81_2:setVisible(false)

		var_81_3.onClick = nil
		var_81_4.onClick = nil
	end

	function var_81_3.onClick()
		var_81_5()

		if var_0_0 then
			if arg_81_1 then
				local var_83_0 = BattlePassAssets.getRandomDailyMissions and BattlePassAssets.getRandomDailyMissions() or {}

				for iter_83_0, iter_83_1 in ipairs(BattlePass.dailyMissions) do
					if iter_83_1 == arg_81_0 then
						BattlePass.dailyMissions[iter_83_0] = var_83_0[math.random(#var_83_0)]

						break
					end
				end
			else
				BattlePassAssets.rerollMissionInPlace(arg_81_0)
			end

			BattlePass:configureMissionPanel()
		else
			var_0_3({
				action = "reroll",
				missionId = arg_81_0.missionId
			})
		end
	end

	function var_81_4.onClick()
		var_81_5()
	end

	var_81_2:setVisible(true)
	var_81_2:raise()
end

function BattlePass.rerollDailyMission(arg_85_0, arg_85_1)
	if BattlePass.dailyRerollWindow then
		BattlePass.dailyRerollWindow:destroy()

		BattlePass.dailyRerollWindow = nil
	end

	var_0_23(arg_85_1, true)
end

function BattlePass.rerollGeneralMission(arg_86_0, arg_86_1)
	var_0_23(arg_86_1, false)
end

function BattlePass.buildRewardsList(arg_87_0)
	local var_87_0 = BattlePass.window:recursiveGetChildById("rewardsListScroll")
	local var_87_1 = BattlePass.window:recursiveGetChildById("rewardsListHeader")

	if not var_87_0 then
		return
	end

	var_87_0:destroyChildren()

	local var_87_2 = 0
	local var_87_3 = 0
	local var_87_4 = {}

	for iter_87_0, iter_87_1 in ipairs(BattlePass.rewardSteps or {}) do
		if iter_87_1.stepId <= BattlePass.currentRewardStep then
			for iter_87_2, iter_87_3 in ipairs(iter_87_1.rewards) do
				var_87_2 = var_87_2 + 1

				if iter_87_3.hasClamedReward then
					var_87_3 = var_87_3 + 1
				end

				table.insert(var_87_4, {
					stepId = iter_87_1.stepId,
					reward = iter_87_3
				})
			end
		end
	end

	if var_87_1 then
		var_87_1:setText(string.format("Unlocked Rewards: %d/%d Collected", var_87_3, var_87_2))
	end

	for iter_87_4, iter_87_5 in ipairs(var_87_4) do
		local var_87_5 = g_ui.createWidget("RewardListRow", var_87_0)

		if iter_87_4 % 2 == 0 then
			var_87_5:setBackgroundColor("#1e1e1e")
		end

		local var_87_6 = var_87_5:recursiveGetChildById("rowType")
		local var_87_7 = iter_87_5.reward.freeReward

		var_87_6:setText(var_87_7 and "Free" or "Deluxe")
		var_87_6:setColor(var_87_7 and "#7FC97E" or "#F7A700")

		local var_87_8 = var_87_5:recursiveGetChildById("rowClaim")
		local var_87_9 = iter_87_5.reward.hasClamedReward and "/images/game/battlepass/claimed" or "/images/game/battlepass/unclaimed"

		var_87_8:setImageSource(var_87_9)
		var_87_5:recursiveGetChildById("rowStep"):setText(tostring(iter_87_5.stepId))
		var_87_5:recursiveGetChildById("rowReward"):setText(iter_87_5.reward.rewardName or "Reward")

		local var_87_10 = var_87_5:recursiveGetChildById("rowClaimBtn")
		local var_87_11 = iter_87_5.stepId
		local var_87_12 = var_87_7 and "free" or "premium"
		local var_87_13 = not iter_87_5.reward.hasClamedReward

		if not var_87_7 and not BattlePass.premiumBattlepass then
			var_87_13 = false
		end

		if not var_87_13 then
			var_87_10:setEnabled(false)
			var_87_10:setImageColor("#555555")
		else
			var_87_10:setEnabled(true)

			function var_87_10.onClick()
				var_0_3({
					action = "redeem",
					stepId = var_87_11,
					rewardType = var_87_12
				})
			end
		end

		var_87_5:recursiveGetChildById("rowGotoBtn").onClick = function()
			if RewardPositions[var_87_11] then
				BattlePass.window:recursiveGetChildById("rewardsListPanel"):setVisible(false)
				BattlePass.scrollBarWidget:setValue(RewardPositions[var_87_11].scrollPosition)
			end
		end
	end
end

function var_0_15()
	if not BattlePass.window:isVisible() then
		return
	end

	var_0_20()
	var_0_18()
end
