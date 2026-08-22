local var_0_0
local var_0_1
local var_0_2 = 0
local var_0_3 = {}
local var_0_4 = {}
local var_0_5 = {}
local var_0_6 = {}
local var_0_7
local var_0_8 = false
local var_0_9 = {
	showCount = "all",
	sortBy = "type",
	showCompleted = true
}
local var_0_10 = {
	[300] = "#d4b000",
	[100] = "#c87828",
	daily = "#c0c0c0",
	done = "#606060",
	[500] = "#88c8f0",
	[200] = "#8ab4c8"
}
local var_0_11 = {
	[300] = "/images/game/battlepass/gold-icon",
	[100] = "/images/game/battlepass/bronze-icon",
	daily = "/images/game/battlepass/daily-free-icon",
	[500] = "/images/game/battlepass/crystal-icon",
	[200] = "/images/game/battlepass/silver-icon"
}
local var_0_12
local var_0_13
local var_0_14

function initialize()
	g_ui.importStyle("battlepasstracker")

	var_0_0 = g_ui.createWidget("BattlePassTracker", modules.game_interface.getRightPanel())

	var_0_0:setContentMinimumHeight(80)

	local var_1_0 = var_0_0:recursiveGetChildById("toggleFilterButton")

	if var_1_0 then
		var_1_0:setVisible(false)
		var_1_0:setOn(false)
	end

	local var_1_1 = var_0_0:recursiveGetChildById("newWindowButton")

	if var_1_1 then
		var_1_1:setVisible(false)
	end

	local var_1_2 = var_0_0:recursiveGetChildById("contextMenuButton")
	local var_1_3 = var_0_0:recursiveGetChildById("lockButton")
	local var_1_4 = var_0_0:recursiveGetChildById("minimizeButton")

	if var_1_2 then
		var_1_2:setVisible(true)

		if var_1_4 then
			var_1_2:breakAnchors()
			var_1_2:addAnchor(AnchorTop, var_1_4:getId(), AnchorTop)
			var_1_2:addAnchor(AnchorRight, var_1_4:getId(), AnchorLeft)
			var_1_2:setMarginRight(7)
			var_1_2:setMarginTop(0)
		end

		if var_1_3 then
			var_1_3:breakAnchors()
			var_1_3:addAnchor(AnchorTop, var_1_2:getId(), AnchorTop)
			var_1_3:addAnchor(AnchorRight, var_1_2:getId(), AnchorLeft)
			var_1_3:setMarginRight(2)
			var_1_3:setMarginTop(0)
		end

		function var_1_2.onClick(arg_2_0, arg_2_1)
			var_0_13(arg_2_1)

			return true
		end
	end

	var_0_0:setup()
	var_0_0:hide()
	connect(g_game, {
		onGameStart = onGameStart,
		onGameEnd = onGameEnd
	})
end

function terminate()
	disconnect(g_game, {
		onGameStart = onGameStart,
		onGameEnd = onGameEnd
	})

	if var_0_8 then
		disconnect(g_game, {
			onBattlePassMissions = var_0_14
		})

		var_0_8 = false
	end

	if var_0_1 then
		var_0_1:destroy()

		var_0_1 = nil
	end

	if var_0_0 then
		var_0_0:destroy()

		var_0_0 = nil
	end

	var_0_5 = {}
	var_0_6 = {}
	var_0_7 = nil
	var_0_2 = 0
	var_0_3 = {}
	var_0_4 = {}
end

function onMiniWindowOpen()
	if var_0_1 then
		var_0_1:setOn(true)
	end

	var_0_12()
end

function onMiniWindowClose()
	if var_0_1 then
		var_0_1:setOn(false)
	end
end

function onGameStart()
	var_0_1 = modules.game_mainpanel.addToggleButton("battlePassTrackerButton", tr("Battle Pass Tracker"), "/images/game/battlepass/mainIcon1", toggle)

	var_0_1:setVisible(false)
	var_0_0:setupOnStart()

	if var_0_0:isExplicitlyVisible() then
		var_0_0:close(true)
	end

	if not modules.game_battlepass then
		connect(g_game, {
			onBattlePassMissions = var_0_14
		})

		var_0_8 = true
	end
end

function onGameEnd()
	if var_0_8 then
		disconnect(g_game, {
			onBattlePassMissions = var_0_14
		})

		var_0_8 = false
	end

	if var_0_0 and var_0_0.contentsPanel then
		var_0_0.contentsPanel:destroyChildren()
	end

	var_0_5 = {}
	var_0_6 = {}
	var_0_7 = nil
	var_0_2 = 0
	var_0_3 = {}
	var_0_4 = {}

	if var_0_1 then
		var_0_1:destroy()

		var_0_1 = nil
	end
end

function var_0_14(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7, arg_8_8, arg_8_9, arg_8_10, arg_8_11)
	updateData(arg_8_6, arg_8_10, arg_8_11)
end

function updateData(arg_9_0, arg_9_1, arg_9_2)
	var_0_2 = arg_9_0 or 0
	var_0_3 = arg_9_1 or {}
	var_0_4 = arg_9_2 or {}

	var_0_12()
end

function toggle()
	if not var_0_0 then
		return
	end

	if var_0_0:isVisible() then
		var_0_0:hide()

		if var_0_1 then
			var_0_1:setOn(false)
		end
	else
		var_0_0:show(true)
		var_0_0:raise()
		var_0_0:focus()

		if var_0_1 then
			var_0_1:setOn(true)
		end

		var_0_12()
	end
end

local function var_0_15(arg_11_0)
	local var_11_0 = {}

	for iter_11_0, iter_11_1 in ipairs(arg_11_0) do
		table.insert(var_11_0, iter_11_1)
	end

	if var_0_9.sortBy == "type" then
		table.sort(var_11_0, function(arg_12_0, arg_12_1)
			return (arg_12_0.rewardPoints or 0) > (arg_12_1.rewardPoints or 0)
		end)
	elseif var_0_9.sortBy == "progress" then
		table.sort(var_11_0, function(arg_13_0, arg_13_1)
			return ((arg_13_0.maxProgress or 0) > 0 and arg_13_0.currentProgress / arg_13_0.maxProgress or 0) > ((arg_13_1.maxProgress or 0) > 0 and arg_13_1.currentProgress / arg_13_1.maxProgress or 0)
		end)
	elseif var_0_9.sortBy == "name" then
		table.sort(var_11_0, function(arg_14_0, arg_14_1)
			return (arg_14_0.missionName or "") < (arg_14_1.missionName or "")
		end)
	end

	return var_11_0
end

local function var_0_16(arg_15_0, arg_15_1)
	local var_15_0 = arg_15_0.missionId or arg_15_0.id or arg_15_0.missionName

	return (arg_15_1 and "d:" or "g:") .. tostring(var_15_0)
end

local function var_0_17(arg_16_0, arg_16_1, arg_16_2)
	local var_16_0 = arg_16_1.currentProgress or 0
	local var_16_1 = arg_16_1.maxProgress or 1
	local var_16_2 = var_16_1 <= var_16_0
	local var_16_3 = arg_16_2 and "daily" or arg_16_1.rewardPoints or 100
	local var_16_4 = var_0_11[var_16_3] or var_0_11[100]
	local var_16_5 = var_16_2 and var_0_10.done or var_0_10[var_16_3] or var_0_10[100]
	local var_16_6 = arg_16_0:recursiveGetChildById("missionIcon")
	local var_16_7 = arg_16_0:recursiveGetChildById("missionName")
	local var_16_8 = arg_16_0:recursiveGetChildById("missionProgress")

	var_16_6:setImageSource(var_16_4)
	var_16_7:setText(arg_16_1.missionName or "")
	var_16_7:setColor(var_16_5)

	local var_16_9 = var_16_1 > 0 and var_16_0 / var_16_1 * 100 or 0

	var_16_8:setPercent(var_16_9)
	var_16_8:setBackgroundColor(var_16_2 and "#2CB204" or var_16_5)

	local var_16_10 = string.format("%d/%d", var_16_0, var_16_1)
	local var_16_11 = string.format("[%s]\n%s\n%s", arg_16_1.missionName or "", arg_16_1.missionDescription or "", var_16_10)

	arg_16_0:setTooltip(var_16_11)
end

local function var_0_18(arg_17_0, arg_17_1)
	local var_17_0 = var_0_5[arg_17_1]

	if var_17_0 and not var_17_0:isDestroyed() then
		return var_17_0, false
	end

	local var_17_1 = g_ui.createWidget("BattlePassMissionRow", arg_17_0)

	var_0_5[arg_17_1] = var_17_1

	return var_17_1, true
end

local function var_0_19(arg_18_0, arg_18_1, arg_18_2)
	local var_18_0 = var_0_6[arg_18_1]

	if var_18_0 and not var_18_0:isDestroyed() then
		var_18_0:setText(arg_18_2)

		return var_18_0
	end

	local var_18_1 = g_ui.createWidget("BattlePassTrackerSectionHeader", arg_18_0)

	var_18_1:setText(arg_18_2)

	var_0_6[arg_18_1] = var_18_1

	return var_18_1
end

function var_0_12()
	if not var_0_0 then
		return
	end

	local var_19_0 = var_0_0.contentsPanel

	if not var_19_0 then
		return
	end

	local var_19_1 = {}
	local var_19_2 = {}

	if not var_0_7 or var_0_7:isDestroyed() then
		var_0_7 = g_ui.createWidget("BattlePassTrackerLevelSection", var_19_0)
	end

	var_0_7:recursiveGetChildById("levelNumber"):setText(tostring(var_0_2))
	table.insert(var_19_2, var_0_7)

	if #var_0_3 > 0 then
		local var_19_3 = var_0_19(var_19_0, "daily", tr("Daily Missions"))

		var_19_1.__header_daily = true

		table.insert(var_19_2, var_19_3)

		for iter_19_0, iter_19_1 in ipairs(var_0_3) do
			if not ((iter_19_1.currentProgress or 0) >= (iter_19_1.maxProgress or 1)) or var_0_9.showCompleted then
				local var_19_4 = var_0_16(iter_19_1, true)
				local var_19_5 = var_0_18(var_19_0, var_19_4)

				var_0_17(var_19_5, iter_19_1, true)

				var_19_1[var_19_4] = true

				table.insert(var_19_2, var_19_5)
			end
		end
	end

	local var_19_6 = var_0_15(var_0_4)

	if #var_19_6 > 0 then
		local var_19_7 = {}
		local var_19_8 = var_0_9.showCount == "10" and 10 or math.huge

		for iter_19_2, iter_19_3 in ipairs(var_19_6) do
			if var_19_8 <= #var_19_7 then
				break
			end

			if not ((iter_19_3.currentProgress or 0) >= (iter_19_3.maxProgress or 1)) or var_0_9.showCompleted then
				table.insert(var_19_7, iter_19_3)
			end
		end

		if #var_19_7 > 0 then
			local var_19_9 = var_0_19(var_19_0, "general", tr("General Missions"))

			var_19_1.__header_general = true

			table.insert(var_19_2, var_19_9)

			for iter_19_4, iter_19_5 in ipairs(var_19_7) do
				local var_19_10 = var_0_16(iter_19_5, false)
				local var_19_11 = var_0_18(var_19_0, var_19_10)

				var_0_17(var_19_11, iter_19_5, false)

				var_19_1[var_19_10] = true

				table.insert(var_19_2, var_19_11)
			end
		end
	end

	for iter_19_6, iter_19_7 in pairs(var_0_5) do
		if not var_19_1[iter_19_6] then
			if iter_19_7 and not iter_19_7:isDestroyed() then
				iter_19_7:destroy()
			end

			var_0_5[iter_19_6] = nil
		end
	end

	for iter_19_8, iter_19_9 in pairs(var_0_6) do
		if not var_19_1["__header_" .. iter_19_8] then
			if iter_19_9 and not iter_19_9:isDestroyed() then
				iter_19_9:destroy()
			end

			var_0_6[iter_19_8] = nil
		end
	end

	for iter_19_10, iter_19_11 in ipairs(var_19_2) do
		var_19_0:moveChildToIndex(iter_19_11, iter_19_10)
	end
end

function var_0_13(arg_20_0)
	local var_20_0 = g_ui.createWidget("BattlePassTrackerMenu")

	var_20_0:setGameMenu(true)

	local var_20_1 = {
		sortByName = "name",
		sortByProgress = "progress",
		sortByType = "type"
	}

	for iter_20_0, iter_20_1 in pairs(var_20_1) do
		local var_20_2 = var_20_0:recursiveGetChildById(iter_20_0)

		if var_20_2 then
			var_20_2:setChecked(var_0_9.sortBy == iter_20_1)

			function var_20_2.onCheckChange()
				var_0_9.sortBy = iter_20_1

				var_20_0:destroy()
				var_0_12()
			end
		end
	end

	local var_20_3 = {
		showAllMissions = "all",
		show10Missions = "10"
	}

	for iter_20_2, iter_20_3 in pairs(var_20_3) do
		local var_20_4 = var_20_0:recursiveGetChildById(iter_20_2)

		if var_20_4 then
			var_20_4:setChecked(var_0_9.showCount == iter_20_3)

			function var_20_4.onCheckChange()
				var_0_9.showCount = iter_20_3

				var_20_0:destroy()
				var_0_12()
			end
		end
	end

	local var_20_5 = var_20_0:recursiveGetChildById("showCompleted")

	if var_20_5 then
		var_20_5:setChecked(var_0_9.showCompleted)

		function var_20_5.onCheckChange()
			var_0_9.showCompleted = not var_0_9.showCompleted

			var_20_0:destroy()
			var_0_12()
		end
	end

	var_20_0:display(arg_20_0)
end
