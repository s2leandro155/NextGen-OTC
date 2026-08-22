tasksWindow = nil

local var_0_0
local var_0_1 = {}
local var_0_2 = false
local var_0_3
local var_0_4
local var_0_5 = 1
local var_0_6
local var_0_7
local var_0_8
local var_0_9 = 143
local taskStoreWindow
local taskCoinBalance = 0
local defaultTaskStoreProducts = {
	{ id = 1, item = 61718, count = 1, price = 25, name = "Mystic Bag" },
	{ id = 2, item = 61608, count = 1, price = 15, name = "Tigrinho Roulette Coin" },
	{ id = 3, item = 61722, count = 1, price = 50, name = "Paladin's Chest" },
	{ id = 4, item = 61720, count = 1, price = 50, name = "Druid's Chest" },
	{ id = 5, item = 61721, count = 1, price = 50, name = "Knight's Chest" },
	{ id = 6, item = 61719, count = 1, price = 50, name = "Sorcerer's Chest" }
}
local var_0_10 = {
	{
		name = "Exercise Sword",
		id = 35279
	},
	{
		name = "Exercise Axe",
		id = 35280
	},
	{
		name = "Exercise Club",
		id = 35281
	},
	{
		name = "Exercise Bow",
		id = 35282
	},
	{
		name = "Exercise Rod",
		id = 35283
	},
	{
		name = "Exercise Wand",
		id = 35284
	},
	{
		name = "Exercise Cestus",
		id = 50294
	}
}

local function var_0_11(arg_1_0)
	for iter_1_0, iter_1_1 in ipairs(arg_1_0:getChildren()) do
		local var_1_0 = iter_1_1:getId()

		if var_1_0 and var_1_0 ~= "" then
			arg_1_0[var_1_0] = iter_1_1

			var_0_11(iter_1_1)
		end
	end
end

local function var_0_12(arg_2_0)
	if not arg_2_0 then
		return ""
	end

	return arg_2_0:gsub("(%a)([%w_']*)", function(arg_3_0, arg_3_1)
		return arg_3_0:upper() .. arg_3_1:lower()
	end)
end

local function var_0_13(arg_4_0, arg_4_1)
	local var_4_0 = g_game.getProtocolGame()

	if var_4_0 then
		var_4_0:sendExtendedOpcode(var_0_9, json.encode({
			action = arg_4_0,
			id = arg_4_1
		}))
	end
end

local var_0_14 = {
	states = {
		SecondFinished = 6,
		SecondActive = 5,
		SecondAvailable = 4,
		Finished = 3,
		Active = 2,
		Available = 1,
		Locked = 0,
		SecondLocked = 7
	},
	actions = {
		start = 1,
		request = 0,
		cancel = 2,
		claim = 3
	},
	rewards = {
		available = 1,
		locked = 0,
		claimed = 2
	},
	categories = {
		{
			color = "#fffbdcff",
			name = "Greenhorn",
			gif = false,
			image = "images/novato",
			hall = "Greenhorn Hall",
			description = "Novice tasks feature initial confrontations in villages and forests, shallow caves and ancient ruins, where goblins, trolls, rotworms, minotaurs, dwarves, elves, undead from dark cathedrals, pirates, barbarians, djinns and mutant creatures test the player.\n\nAs a reward, winners receive consistent experience, small amounts of coins, utility and progression items (scrolls, wildcards, mystic food, exercise chests, wheel points) and occasionally mystic resources for upgrades.\n\nHere is a summary of your current progress:",
			icon = "images/icon_1"
		},
		{
			color = "#ffdcdcff",
			name = "Adventurer",
			gif = false,
			image = "images/destemido",
			hall = "Adventurer Hall",
			description = "Fearless tasks put the player against deep seas and ancient ruins, scorching deserts and frozen wastelands, toxic hives and esoteric caverns, profane temples and tribal fortresses.\n\nAs a reward, winners receive good experience, upgrade resources (mystic core, stone bag), coins and valuable tokens, wildcards and utility items, plus mysterious outfit and mount chests.\n\nHere is a summary of your current progress:",
			icon = "images/icon_2"
		},
		{
			color = "#ffbabaff",
			name = "Hunter",
			gif = true,
			image = "images/veterano",
			hall = "Hunter Hall",
			description = "Veteran tasks take the player to face hostile zones like ancestral ruins, scorching deserts, living forests, haunted catacombs and asura temples, fighting specters, reapers, lycanthropes, seasonal beasts and void horrors.\n\nAs a reward, winners receive lots of experience, themed bags and chests, upgrade resources (mystic core, stone bag), coins and valuable tokens, utility items and temporary boosts.\n\nHere is a summary of your current progress:",
			icon = "images/icon_3"
		},
		{
			color = "#bae0ffff",
			name = "Scrapper",
			gif = true,
			image = "images/gladiador",
			hall = "Scrapper Hall",
			description = "Gladiator tasks lead the player to face intense assaults in war zones, fortified bastions, deep deserts, dark prisons, salt caverns and ancient ruins. Each route requires thousands of kills.\n\nAs a reward, winners receive lots of experience, themed bags and chests, mystic resources and upgrade materials, coins and valuable tokens, temporary improvements and rare prizes.\n\nHere is a summary of your current progress:",
			icon = "images/icon_4"
		},
		{
			color = "#efffbaff",
			name = "Warlord",
			gif = true,
			image = "images/soberano",
			hall = "Warlord Hall",
			description = "Sovereign tasks take the player to face hordes of elemental and abyssal creatures in extreme environments like mystic libraries, raging craters, mirrored nightmares, rotting swamps and claustrophobic infernos.\n\nAs a reward, winners receive vast amounts of experience, mysterious items, random mounts and outfits, rare bags, essential resources and power objects.\n\nHere is a summary of your current progress:",
			icon = "images/icon_5"
		}
	}
}
local var_0_15

local function var_0_16(arg_5_0)
	if not tasksWindow then
		return
	end

	tasksWindow.difficultyLabel:setVisible(arg_5_0)

	for iter_5_0 = 1, 5 do
		tasksWindow["filterStar" .. iter_5_0]:setVisible(arg_5_0)
	end

	tasksWindow.filterShowCompleted:setVisible(arg_5_0)
	tasksWindow.filterShowLocked:setVisible(arg_5_0)
	tasksWindow.filterShowActive:setVisible(arg_5_0)
	tasksWindow.filterShowAvailable:setVisible(arg_5_0)
end

function init()
	tasksWindow = g_ui.displayUI("tasks")
	taskStoreWindow = g_ui.displayUI("task_store")
	taskStoreWindow:hide()

	tasksWindow:hide()
	connect(tasksWindow.main.gridPanel, {
		onVisibilityChange = function(arg_7_0, arg_7_1)
			var_0_16(arg_7_1)
		end
	})
	var_0_16(false)

	tasksWindow.var = {
		currentPage = 1,
		grid = {}
	}

	tasksWindow.main.selectedPanel.overall.mapBorder.minimap:setZoom(2)
	tasksWindow.main.selectedPanel.overall.mapBorder.minimap:disableAutoWalk()

	tasksWindow.main.selectedPanel.overall.mapBorder.minimap.allowCallback = false

	ProtocolGame.registerExtendedJSONOpcode(var_0_9, onExtendedOpcode)
	Keybind.new("Windows", "Toggle Linked Tasks", "Ctrl+Shift+T", "")
	Keybind.bind("Windows", "Toggle Linked Tasks", {
		{
			type = KEY_DOWN,
			callback = tryOpen
		}
	})

	if modules.game_interface then
		local var_6_0 = modules.game_interface.getMapPanel()

		if var_6_0 then
			var_0_0 = g_ui.createWidget("TaskTrackerWidget", var_6_0)

			var_0_0:hide()
			var_0_0:raise()

			local function var_6_1()
				if not var_0_0 or not var_6_0 then
					return
				end

				local var_8_0 = var_6_0:getSize()
				local var_8_1 = var_8_0.width / var_8_0.height
				local var_8_2 = 1.3636363636363635
				local var_8_3 = 10
				local var_8_4 = 10

				if var_8_2 < var_8_1 then
					local var_8_5 = var_8_0.height * var_8_2

					var_8_3 = var_8_3 + (var_8_0.width - var_8_5) / 2
				elseif var_8_1 < var_8_2 then
					local var_8_6 = var_8_0.width / var_8_2

					var_8_4 = var_8_4 + (var_8_0.height - var_8_6) / 2
				end

				var_0_0:setMarginRight(var_8_3)
				var_0_0:setMarginBottom(var_8_4)
			end

			connect(var_6_0, {
				onGeometryChange = var_6_1
			})
			addEvent(var_6_1)
		end
	end

	var_0_6 = g_ui.createWidget("TaskExerciseWindow", rootWidget)

	if var_0_6 then
		var_0_6:hide()
	end

	var_0_2 = g_settings.getBoolean("taskTrackerVisible", false)

	if tasksWindow then
		local var_6_2 = tasksWindow:getChildById("trackerCheckbox")

		if var_6_2 then
			var_6_2:setChecked(var_0_2)
		end
	end

	connect(g_game, {
		onGameEnd = onGameEnd
	})
end

function terminate()
	if taskStoreWindow then
		taskStoreWindow:destroy()
		taskStoreWindow = nil
	end
	if var_0_3 then
		removeEvent(var_0_3)

		var_0_3 = nil
	end

	if var_0_4 then
		removeEvent(var_0_4)

		var_0_4 = nil
	end

	if var_0_0 then
		var_0_0:destroy()

		var_0_0 = nil
	end

	if var_0_6 then
		var_0_6:destroy()

		var_0_6 = nil
	end

	if tasksWindow then
		tasksWindow:destroy()

		tasksWindow = nil
	end

	ProtocolGame.unregisterExtendedJSONOpcode(var_0_9)
	Keybind.delete("Windows", "Toggle Linked Tasks")
	disconnect(g_game, {
		onGameEnd = onGameEnd
	})
end

function onGameEnd()
	hide()
	hideTaskStore()

	if var_0_0 then
		var_0_0:hide()
	end

	var_0_1 = {}
end

function hide()
	if tasksWindow then
		tasksWindow:hide()
	end
end

function backToGrid()
	tasksWindow:setWidth(911)
	tasksWindow:setHeight(789)
	tasksWindow.main.selectedPanel:hide()
	tasksWindow.main.gridPanel:show()
	tasksWindow.main.loading:hide()
	tasksWindow.main.rewardPanel:hide()
	tasksWindow.back:hide()
	requestCategory(getCurrentTaskSelectedStage())
end

function tryOpen()
	if not g_game.isOnline() then
		return
	end

	if tasksWindow and not tasksWindow:isVisible() then
		show()
	elseif tasksWindow and tasksWindow:isVisible() then
		hide()
	end
end

function show()
	if tasksWindow and not tasksWindow:isVisible() then
		tasksWindow:setWidth(911)
		tasksWindow:setHeight(789)
		tasksWindow.main.selectedPanel:hide()
		tasksWindow.main.gridPanel:show()
		tasksWindow.main.loading:hide()
		tasksWindow.main.rewardPanel:hide()
		tasksWindow.back:hide()
		tasksWindow.main.gridPanel.tabs:getChildByIndex(1):setChecked(true)
		tasksWindow:show()
		tasksWindow:raise()
		tasksWindow:focus()
		requestCategory(1)
	end
end

function requestCategory(arg_15_0)
	var_0_13("category", arg_15_0)
end

function onExtendedOpcode(arg_16_0, arg_16_1, arg_16_2)
	if arg_16_2.taskPoints ~= nil then
		updateTaskPointsBalance(arg_16_2.taskPoints)
	end

	if arg_16_2.type == "category" then
		onCategoryReceived(arg_16_2.category, arg_16_2.tasks)
	elseif arg_16_2.type == "selected" then
		onTaskSelectedCreature(arg_16_2.id, arg_16_2.name, arg_16_2.raceId, arg_16_2.kills, arg_16_2.total, arg_16_2.rewards, arg_16_2.secondRewards, arg_16_2.state, arg_16_2.hunts, arg_16_2.creatures, arg_16_2.outfit)
	elseif arg_16_2.type == "reward" then
		onTaskRewardDay(arg_16_2.level, arg_16_2.state, arg_16_2.rewards, arg_16_2.tasks)
	elseif arg_16_2.type == "tracker" then
		onTaskTrackerReceived(arg_16_2.list)
	elseif arg_16_2.type == "exercise_select" then
		var_0_8 = arg_16_2.taskId

		showExerciseWindow()
	elseif arg_16_2.type == "task_store" then
		showTaskStoreProducts(arg_16_2.products or {}, arg_16_2.taskPoints or 0)
	end
end

function showTaskStore()
	if not g_game.isOnline() then return end
	if taskStoreWindow then
		showTaskStoreProducts(defaultTaskStoreProducts, taskCoinBalance)
		taskStoreWindow:show()
		taskStoreWindow:raise()
		taskStoreWindow:focus()
	end
	var_0_13("task_store", 0)
end

function hideTaskStore()
	if taskStoreWindow then taskStoreWindow:hide() end
end

function buyTaskStoreProduct(productId)
	local protocol = g_game.getProtocolGame()
	if protocol then
		protocol:sendExtendedOpcode(var_0_9, json.encode({ action = "task_store_buy", id = productId }))
	end
end

function showTaskStoreProducts(products, balance)
	if not taskStoreWindow then return end
	var_0_11(taskStoreWindow)
	taskCoinBalance = balance or 0
	taskStoreWindow.balance.text:setText("Task Coins: " .. comma_value(taskCoinBalance))
	taskStoreWindow.products:destroyChildren()
	for _, product in ipairs(products) do
		local row = g_ui.createWidget("TaskStoreProduct", taskStoreWindow.products)
		var_0_11(row)
		row.item:setItemId(product.item)
		row.item:setItemCount(product.count or 1)
		row.item:setShowCount((product.count or 1) > 1)
		row.name:setText(product.name)
		row.price:setText(comma_value(product.price) .. " Task Coins")
		row.buy:setEnabled(taskCoinBalance >= product.price)
		row.buy.onClick = function() buyTaskStoreProduct(product.id) end
	end
	taskStoreWindow:show()
	taskStoreWindow:raise()
	taskStoreWindow:focus()
end

function onClickHuntOption(arg_17_0, arg_17_1)
	for iter_17_0, iter_17_1 in ipairs(tasksWindow.main.selectedPanel.preview.list:getChildren()) do
		if iter_17_1 ~= arg_17_0 then
			iter_17_1:setBackgroundColor(iter_17_1.originBackground)
		end
	end

	arg_17_0:setBackgroundColor("#6d6d6d")
	tasksWindow.main.selectedPanel.overall.title:setText(arg_17_1.name)

	local var_17_0 = {
		x = arg_17_1.position.x,
		y = arg_17_1.position.y,
		z = arg_17_1.position.z
	}

	tasksWindow.main.selectedPanel.overall.mapBorder.minimap:setCameraPosition(var_17_0)
	tasksWindow.main.selectedPanel.overall.mapBorder.minimap:setCrossPosition(var_17_0)
	tasksWindow.main.selectedPanel.overall.mapBorder.layersPanel.layersMark:setMarginTop((var_17_0.z + 1) * 4 - 3)
	tasksWindow.main.selectedPanel.overall.mapBorder.layersPanel.automapLayers:setImageClip(var_17_0.z * 14 .. " 0 14 67")
	tasksWindow.main.selectedPanel.overall.soloLevel.value:setText(comma_value(arg_17_1.solo))
	tasksWindow.main.selectedPanel.overall.partyLevel.value:setText(comma_value(arg_17_1.party))

	for iter_17_2 = 1, 5 do
		local var_17_1 = tasksWindow.main.selectedPanel.overall.exp["star" .. iter_17_2]

		if var_17_1 ~= nil then
			var_17_1:setEnabled(iter_17_2 <= arg_17_1.experience)
		end

		local var_17_2 = tasksWindow.main.selectedPanel.overall.loot["star" .. iter_17_2]

		if var_17_2 ~= nil then
			var_17_2:setEnabled(iter_17_2 <= arg_17_1.experience)
		end
	end

	for iter_17_3, iter_17_4 in ipairs(tasksWindow.main.selectedPanel.creatures.list:getChildren()) do
		if table.find(arg_17_1.creatures, iter_17_4.raceId) then
			iter_17_4.mask:hide()
			iter_17_4.icon:hide()
		else
			iter_17_4.mask:show()
			iter_17_4.icon:show()
		end
	end
end

function onTaskRewardDay(arg_18_0, arg_18_1, arg_18_2, arg_18_3)
	local var_18_0 = var_0_14.categories[arg_18_0]

	if var_18_0 == nil then
		return
	end

	tasksWindow.main.rewardPanel.main.image:setImageSource(var_18_0.image)
	tasksWindow.main.rewardPanel.main.text:setText(var_18_0.name)
	tasksWindow.main.rewardPanel.main.text:setColor(var_18_0.color)

	for iter_18_0, iter_18_1 in ipairs({
		"_left_",
		"_right_"
	}) do
		for iter_18_2 = 1, 5 do
			tasksWindow.main.rewardPanel.main["star" .. iter_18_1 .. iter_18_2]:setEnabled(iter_18_2 <= arg_18_0)
		end
	end

	local function var_18_1(arg_19_0)
		if arg_19_0 < 1000 then
			return tostring(arg_19_0)
		end

		if arg_19_0 < 1000000 then
			return tostring(arg_19_0 / 1000) .. "k"
		end

		return tostring(math.floor(arg_19_0 / 1000000)) .. "kk"
	end

	tasksWindow.main.rewardPanel.rewards.list:destroyChildren()

	for iter_18_3, iter_18_4 in ipairs(arg_18_2) do
		local var_18_2 = g_ui.createWidget("TaskPremiumItem", tasksWindow.main.rewardPanel.rewards.list)

		var_0_11(var_18_2)
		var_18_2.item:setItemId(iter_18_4.item)

		local var_18_3 = var_18_2.item:getItem()
		local var_18_4 = ""

		if var_18_3 ~= nil then
			var_18_4 = iter_18_4.name or var_18_3:getName()

			if iter_18_4.count > 1 or var_18_3:isStackable() then
				var_18_2.count:show()
				var_18_2.count:setText(var_18_1(iter_18_4.count))
			else
				var_18_2.count:hide()
			end
		elseif iter_18_4.name then
			var_18_4 = iter_18_4.name

			var_18_2.count:show()
			var_18_2.count:setText(var_18_1(iter_18_4.count))
		end

		if iter_18_4.chance and iter_18_4.chance < 100 then
			var_18_2:setTooltip(iter_18_4.count .. "x " .. var_18_4 .. " (" .. iter_18_4.chance .. "%)")

			if var_18_2.chance then
				var_18_2.chance:show()
				var_18_2.chance:setText(iter_18_4.chance .. "%")
			end
		else
			var_18_2:setTooltip(iter_18_4.count .. "x " .. var_18_4)
		end
	end

	if arg_18_1 == var_0_14.rewards.locked then
		tasksWindow.main.rewardPanel.rewards.claim:setImageSource("images/button_red")
		tasksWindow.main.rewardPanel.rewards.claim:setEnabled(false)
		tasksWindow.main.rewardPanel.rewards.claim:setText("Locked")

		tasksWindow.main.rewardPanel.rewards.claim.onClick = nil
	elseif arg_18_1 == var_0_14.rewards.available then
		tasksWindow.main.rewardPanel.rewards.claim:setImageSource("images/button_blue")
		tasksWindow.main.rewardPanel.rewards.claim:setEnabled(true)
		tasksWindow.main.rewardPanel.rewards.claim:setText("Claim")

		function tasksWindow.main.rewardPanel.rewards.claim.onClick()
			var_0_13("claim", arg_18_0 * 1000)
		end
	elseif arg_18_1 == var_0_14.rewards.claimed then
		tasksWindow.main.rewardPanel.rewards.claim:setImageSource("images/button_blue")
		tasksWindow.main.rewardPanel.rewards.claim:setEnabled(false)
		tasksWindow.main.rewardPanel.rewards.claim:setText("Claimed")

		tasksWindow.main.rewardPanel.rewards.claim.onClick = nil
	end

	tasksWindow.main.rewardPanel.overview.description:setText(var_18_0.description)
	tasksWindow.main.rewardPanel.overview.list:destroyChildren()

	for iter_18_5, iter_18_6 in ipairs(arg_18_3) do
		local var_18_5 = g_ui.createWidget("TaskResumeEntry", tasksWindow.main.rewardPanel.overview.list)

		var_0_11(var_18_5)

		if iter_18_6.progress == 0 and not iter_18_6.second then
			var_18_5.name:setText("????:")
			var_18_5.value:setText("???")
		else
			var_18_5.name:setText(iter_18_6.name .. ":")
			var_18_5.value:setText(iter_18_6.progress .. "%")
		end

		if iter_18_6.second or iter_18_6.progress >= 100 then
			var_18_5.iconYes:show()

			if iter_18_6.second and iter_18_6.progress < 100 then
				var_18_5.second:show()
			end
		elseif iter_18_6.progress > 0 then
			var_18_5.iconTimer:show()
		else
			var_18_5.iconNo:show()
		end
	end

	tasksWindow:setWidth(865)
	tasksWindow:setHeight(600)
	tasksWindow.main.rewardPanel:show()
	tasksWindow.main.selectedPanel:hide()
	tasksWindow.main.gridPanel:hide()
	tasksWindow.main.loading:hide()
	tasksWindow.back:show()
	show()
end

function onTaskSelectedCreature(arg_21_0, arg_21_1, arg_21_2, arg_21_3, arg_21_4, arg_21_5, arg_21_6, arg_21_7, arg_21_8, arg_21_9, arg_21_10)
	tasksWindow.main.selectedPanel.preview.title:setText(arg_21_1)
	tasksWindow.main.selectedPanel.preview.progress.bar:setWidth(math.max(0, math.min(161, arg_21_3 * 161 / arg_21_4)))
	tasksWindow.main.selectedPanel.preview.progress.text:setText(comma_value(arg_21_3) .. " / " .. comma_value(arg_21_4))

	if arg_21_4 <= arg_21_3 then
		tasksWindow.main.selectedPanel.preview.progress.bar:setBackgroundColor("#00ff2a")
	else
		tasksWindow.main.selectedPanel.preview.progress.bar:setBackgroundColor("#2effe7")
	end

	if arg_21_10 and arg_21_10.lookType and arg_21_10.lookType > 0 then
		tasksWindow.main.selectedPanel.preview.creature:show()

		local var_21_0 = {
			wings = 0,
			mount = 0,
			aura = 0,
			addons = 0,
			auxType = 0,
			manaBar = 0,
			healthBar = 0,
			shader = "",
			type = arg_21_10.lookType,
			head = arg_21_10.lookHead or 0,
			body = arg_21_10.lookBody or 0,
			legs = arg_21_10.lookLegs or 0,
			feet = arg_21_10.lookFeet or 0,
			category = ThingCategoryCreature
		}

		tasksWindow.main.selectedPanel.preview.creature:setOutfit(var_21_0)
		tasksWindow.main.selectedPanel.preview.creature:getCreature():setOutfit(var_21_0)
	else
		tasksWindow.main.selectedPanel.preview.creature:hide()
	end

	tasksWindow.main.selectedPanel.creatures.list:destroyChildren()

	for iter_21_0, iter_21_1 in ipairs(arg_21_9) do
		local var_21_1 = g_ui.createWidget("TaskMonsterBlock", tasksWindow.main.selectedPanel.creatures.list)

		var_0_11(var_21_1)

		var_21_1.raceId = iter_21_1.raceId

		var_21_1:setTooltip(var_0_12(iter_21_1.name or "Unknown"))
		var_21_1.title:setText(var_0_12(iter_21_1.name or "Unknown"))

		if iter_21_1.lookType and iter_21_1.lookType > 0 then
			local var_21_2 = {
				wings = 0,
				mount = 0,
				aura = 0,
				addons = 0,
				auxType = 0,
				manaBar = 0,
				healthBar = 0,
				shader = "",
				type = iter_21_1.lookType,
				head = iter_21_1.lookHead or 0,
				body = iter_21_1.lookBody or 0,
				legs = iter_21_1.lookLegs or 0,
				feet = iter_21_1.lookFeet or 0,
				category = ThingCategoryCreature
			}

			var_21_1.creature:setOutfit(var_21_2)
			var_21_1.creature:getCreature():setOutfit(var_21_2)
		end

		for iter_21_2 = 1, 5 do
			local var_21_3 = var_21_1.starBackground["star" .. iter_21_2]

			if var_21_3 ~= nil then
				var_21_3:setEnabled(iter_21_2 <= iter_21_1.stars)
			end
		end
	end

	table.sort(arg_21_8, function(arg_22_0, arg_22_1)
		if arg_22_0.stars == arg_22_1.stars then
			if arg_22_0.experience == arg_22_1.experience then
				if arg_22_0.loot == arg_22_1.loot then
					if #arg_22_0.creatures == #arg_22_1.creatures then
						return arg_22_0.name:lower() < arg_22_1.name:lower()
					else
						return #arg_22_0.creatures > #arg_22_1.creatures
					end
				else
					return arg_22_0.loot > arg_22_1.loot
				end
			else
				return arg_22_0.experience > arg_22_1.experience
			end
		else
			return arg_22_0.stars > arg_22_1.stars
		end
	end)
	tasksWindow.main.selectedPanel.preview.list:destroyChildren()

	for iter_21_3, iter_21_4 in ipairs(arg_21_8) do
		local var_21_4 = g_ui.createWidget("TaskHuntOption", tasksWindow.main.selectedPanel.preview.list)

		var_0_11(var_21_4)

		if iter_21_3 % 2 ~= 0 then
			var_21_4.originBackground = "#484848"

			var_21_4:setBackgroundColor("#484848")
		else
			var_21_4.originBackground = "alpha"

			var_21_4:setBackgroundColor("alpha")
		end

		var_21_4:setTooltip(iter_21_4.name)
		var_21_4.text:setText(iter_21_4.name)

		local var_21_5

		for iter_21_5 = 1, 5 do
			local var_21_6 = var_21_4["star" .. iter_21_5]

			if var_21_6 ~= nil then
				var_21_6:setVisible(iter_21_5 <= iter_21_4.stars)

				if iter_21_5 <= iter_21_4.stars then
					var_21_5 = iter_21_5
				end
			end
		end

		if var_21_5 ~= nil then
			var_21_4.text:addAnchor(AnchorRight, "star" .. var_21_5, AnchorLeft)
		else
			var_21_4.text:addAnchor(AnchorRight, "parent", AnchorRight)
		end

		function var_21_4.onClick()
			onClickHuntOption(var_21_4, iter_21_4)
		end

		if iter_21_3 == 1 then
			var_21_4:onClick()
		end
	end

	local function var_21_7(arg_24_0)
		if arg_24_0 < 1000 then
			return tostring(arg_24_0)
		end

		if arg_24_0 < 1000000 then
			return tostring(arg_24_0 / 1000) .. "k"
		end

		return tostring(math.floor(arg_24_0 / 1000000)) .. "kk"
	end

	local function var_21_8(arg_25_0, arg_25_1)
		arg_25_0.experience.text:setText("0")
		arg_25_0.list:destroyChildren()

		for iter_25_0, iter_25_1 in ipairs(arg_25_1) do
			if iter_25_1.taskPoints or iter_25_1.preyCards or iter_25_1.exerciseWeapon then
				local var_25_0 = g_ui.createWidget("TaskItem", arg_25_0.list)

				var_0_11(var_25_0)
				var_25_0.item:hide()

				local var_25_1
				local var_25_2

				if iter_25_1.taskPoints then
					var_25_1, var_25_2 = "images/preyhuntingtask-tokens", "Task Coins"
				elseif iter_25_1.preyCards then
					var_25_1, var_25_2 = "images/prey_wildcard", "Prey Wildcard"
				else
					var_25_1, var_25_2 = "images/training", "Exercise Weapon"
				end

				var_25_0.icon:setImageSource(var_25_1)
				var_25_0.icon:show()

				if iter_25_1.count and iter_25_1.count > 1 then
					var_25_0.count:show()
					var_25_0.count:setText(var_21_7(iter_25_1.count))
				else
					var_25_0.count:hide()
				end

				var_25_0:setTooltip((iter_25_1.count or 1) .. "x " .. var_25_2)
			elseif iter_25_1.item == 0 then
				arg_25_0.experience.text:setText(comma_value(iter_25_1.count))
			else
				local var_25_3 = g_ui.createWidget(iter_25_1.special and "TaskPremiumItem" or "TaskItem", arg_25_0.list)

				var_0_11(var_25_3)
				var_25_3.item:setItemId(iter_25_1.item)
				var_25_3.item:setItemCount(iter_25_1.count)
				var_25_3.item:setShowCount(false)

				local var_25_4 = var_25_3.item:getItem()
				local var_25_5 = ""

				if var_25_4 ~= nil then
					var_25_5 = iter_25_1.name or var_25_4:getName()

					if iter_25_1.count > 1 or var_25_4:isStackable() then
						var_25_3.count:show()
						var_25_3.count:setText(var_21_7(iter_25_1.count))
					else
						var_25_3.count:hide()
					end
				else
					var_25_5 = iter_25_1.name or "Item #" .. iter_25_1.item

					var_25_3.item:hide()
					var_25_3.icon:setImageSource("images/task_loot_icon")
					var_25_3.icon:show()
					var_25_3.count:show()
					var_25_3.count:setText(var_21_7(iter_25_1.count))
				end

				if iter_25_1.chance and iter_25_1.chance < 100 then
					var_25_3:setTooltip(iter_25_1.count .. "x " .. var_25_5 .. " (" .. iter_25_1.chance .. "%)")

					if var_25_3.chance then
						var_25_3.chance:show()
						var_25_3.chance:setText(iter_25_1.chance .. "%")
					end
				else
					var_25_3:setTooltip(iter_25_1.count .. "x " .. var_25_5)
				end
			end
		end
	end

	var_21_8(tasksWindow.main.selectedPanel.actions.firstColumn, arg_21_5 or {})
	var_21_8(tasksWindow.main.selectedPanel.actions.secondColumn, arg_21_6 or {})

	local var_21_9 = arg_21_7 == var_0_14.states.SecondAvailable or arg_21_7 == var_0_14.states.SecondActive or arg_21_7 == var_0_14.states.SecondFinished or arg_21_7 == var_0_14.states.SecondLocked

	tasksWindow.main.selectedPanel.actions.firstColumn:setOpacity(var_21_9 and 0.35 or 1)
	tasksWindow.main.selectedPanel.actions.firstCompletedOverlay:setVisible(var_21_9)
	tasksWindow.main.selectedPanel.preview.progress:show()
	tasksWindow.main.selectedPanel.preview.list:setMarginTop(25)
	tasksWindow.main.selectedPanel.preview.background:setMarginTop(10)
	tasksWindow.main.selectedPanel.actions.claim:setColor("#C0C0C0")

	tasksWindow.main.selectedPanel.actions.claim.onClick = nil

	if arg_21_7 == var_0_14.states.Locked or arg_21_7 == var_0_14.states.SecondLocked then
		tasksWindow.main.selectedPanel.preview.progress:hide()
		tasksWindow.main.selectedPanel.preview.list:setMarginTop(10)
		tasksWindow.main.selectedPanel.preview.background:setMarginTop(20)
		tasksWindow.main.selectedPanel.actions.claim:setImageSource("images/button_red")
		tasksWindow.main.selectedPanel.actions.claim:setEnabled(false)
		tasksWindow.main.selectedPanel.actions.claim:setText("Locked")
	elseif arg_21_7 == var_0_14.states.Active or arg_21_7 == var_0_14.states.SecondActive then
		tasksWindow.main.selectedPanel.actions.claim:setImageSource("images/button_red")
		tasksWindow.main.selectedPanel.actions.claim:setEnabled(true)
		tasksWindow.main.selectedPanel.actions.claim:setText("Cancel")

		function tasksWindow.main.selectedPanel.actions.claim.onClick()
			var_0_13("cancel", arg_21_0)
		end
	elseif arg_21_7 == var_0_14.states.Finished or arg_21_7 == var_0_14.states.SecondFinished then
		tasksWindow.main.selectedPanel.actions.claim:setImageSource("images/button_blue")
		tasksWindow.main.selectedPanel.actions.claim:setEnabled(true)
		tasksWindow.main.selectedPanel.actions.claim:setText("Claim")

		function tasksWindow.main.selectedPanel.actions.claim.onClick()
			var_0_13("claim", arg_21_0)
		end
	elseif arg_21_7 == var_0_14.states.Available then
		tasksWindow.main.selectedPanel.preview.progress:hide()
		tasksWindow.main.selectedPanel.preview.list:setMarginTop(10)
		tasksWindow.main.selectedPanel.preview.background:setMarginTop(20)
		tasksWindow.main.selectedPanel.actions.claim:setImageSource("images/button_green")
		tasksWindow.main.selectedPanel.actions.claim:setText("Start")
		tasksWindow.main.selectedPanel.actions.claim:setEnabled(true)

		function tasksWindow.main.selectedPanel.actions.claim.onClick()
			var_0_13("start", arg_21_0)
		end
	elseif arg_21_7 == var_0_14.states.SecondAvailable then
		tasksWindow.main.selectedPanel.preview.progress:hide()
		tasksWindow.main.selectedPanel.preview.list:setMarginTop(10)
		tasksWindow.main.selectedPanel.preview.background:setMarginTop(20)
		tasksWindow.main.selectedPanel.actions.claim:setImageSource("images/button_green")
		tasksWindow.main.selectedPanel.actions.claim:setText("Repeat")
		tasksWindow.main.selectedPanel.actions.claim:setEnabled(true)

		function tasksWindow.main.selectedPanel.actions.claim.onClick()
			var_0_13("start", arg_21_0)
		end
	end

	tasksWindow:setWidth(985)
	tasksWindow:setHeight(600)
	tasksWindow.main.selectedPanel:show()
	tasksWindow.main.gridPanel:hide()
	tasksWindow.main.rewardPanel:hide()
	tasksWindow.main.loading:hide()
	tasksWindow.back:show()
	show()
end

function switchPage(arg_30_0)
	tasksWindow.var.currentPage = tasksWindow.var.currentPage + arg_30_0

	reloadPageContent(tasksWindow.var.search, false)
end

function getCurrentTaskSelectedStage()
	for iter_31_0, iter_31_1 in ipairs(tasksWindow.main.gridPanel.tabs:getChildren()) do
		if iter_31_1:isChecked() then
			return iter_31_0
		end
	end

	return 0
end

function reloadPageContent(arg_32_0, arg_32_1)
	if tasksWindow == nil or #tasksWindow.var.grid == 0 or tasksWindow.var.grid[getCurrentTaskSelectedStage()] == nil then
		if tasksWindow ~= nil then
			tasksWindow.main.gridPanel.list:destroyChildren()
		end

		return
	end

	if arg_32_1 then
		tasksWindow.var.currentPage = 1
	end

	if not arg_32_0 or tasksWindow.main.gridPanel.search:getText() == "" then
		tasksWindow.main.gridPanel.search:clearText()

		arg_32_0 = false
	end

	local var_32_0 = false
	local var_32_1 = 0

	tasksWindow.var.search = arg_32_0

	local var_32_2 = {}

	for iter_32_0, iter_32_1 in ipairs(tasksWindow.var.grid[getCurrentTaskSelectedStage()]) do
		if arg_32_0 then
			if iter_32_1.name:contains(tasksWindow.main.gridPanel.search:getText()) then
				table.insert(var_32_2, iter_32_1)
			end
		else
			local var_32_3 = true

			if (iter_32_1.status == var_0_14.states.Finished or iter_32_1.status == var_0_14.states.SecondFinished) and not tasksWindow.filterShowCompleted:isChecked() then
				var_32_3 = false
			end

			if (iter_32_1.status == var_0_14.states.Locked or iter_32_1.status == var_0_14.states.SecondLocked) and not tasksWindow.filterShowLocked:isChecked() then
				var_32_3 = false
			end

			if (iter_32_1.status == var_0_14.states.Active or iter_32_1.status == var_0_14.states.SecondActive) and not tasksWindow.filterShowActive:isChecked() then
				var_32_3 = false
			end

			if (iter_32_1.status == var_0_14.states.Available or iter_32_1.status == var_0_14.states.SecondAvailable) and not tasksWindow.filterShowAvailable:isChecked() then
				var_32_3 = false
			end

			if iter_32_1.status == var_0_14.states.Finished or iter_32_1.status == var_0_14.states.SecondLocked or iter_32_1.status == var_0_14.states.SecondFinished or iter_32_1.status == var_0_14.states.Active or iter_32_1.status == var_0_14.states.SecondActive or iter_32_1.status == var_0_14.states.Available or iter_32_1.status == var_0_14.states.SecondAvailable then
				var_32_0 = true
			end

			if iter_32_1.status == var_0_14.states.Finished or iter_32_1.status == var_0_14.states.SecondLocked or iter_32_1.status == var_0_14.states.SecondFinished or iter_32_1.status == var_0_14.states.SecondActive or iter_32_1.status == var_0_14.states.SecondAvailable then
				var_32_1 = var_32_1 + 1
			end

			if var_32_3 then
				local var_32_4 = math.max(1, math.min(5, iter_32_1.stars))

				if tasksWindow["filterStar" .. var_32_4]:isChecked() then
					table.insert(var_32_2, iter_32_1)
				end
			end
		end
	end

	local var_32_5 = {}
	local var_32_6 = 12
	local var_32_7 = (tasksWindow.var.currentPage - 1) * var_32_6
	local var_32_8 = tasksWindow.var.currentPage * var_32_6

	for iter_32_2 = var_32_7 + 1, var_32_8 do
		if var_32_2[iter_32_2] ~= nil then
			table.insert(var_32_5, var_32_2[iter_32_2])
		end
	end

	tasksWindow.main.gridPanel.pages:setText("Page: " .. tasksWindow.var.currentPage .. "/" .. math.ceil((#var_32_2 + 1) / var_32_6))
	tasksWindow.main.gridPanel.prevPage:setEnabled(tasksWindow.var.currentPage > 1)
	tasksWindow.main.gridPanel.nextPage:setEnabled(tasksWindow.var.currentPage < math.ceil((#var_32_2 + 1) / var_32_6))
	tasksWindow.main.gridPanel.list:destroyChildren()

	for iter_32_3, iter_32_4 in ipairs(var_32_5) do
		local var_32_9 = g_ui.createWidget("TaskElementBlock", tasksWindow.main.gridPanel.list)

		var_0_11(var_32_9)
		var_32_9.background:setImageSource("images/hunt_background_" .. iter_32_4.background)
		var_32_9.title:setText(iter_32_4.name)
		var_32_9.kills.text:setText(comma_value(iter_32_4.kills))

		for iter_32_5 = 1, 5 do
			var_32_9.starBackground["star" .. iter_32_5]:setEnabled(iter_32_5 <= iter_32_4.stars)
			var_32_9.exp["star" .. iter_32_5]:setEnabled(iter_32_5 <= iter_32_4.exp)
			var_32_9.loot["star" .. iter_32_5]:setEnabled(iter_32_5 <= iter_32_4.loot)
		end

		local var_32_10 = {
			text = "",
			color = ""
		}

		if iter_32_4.status == var_0_14.states.Active or iter_32_4.status == var_0_14.states.SecondActive then
			var_32_10.text = iter_32_4.progress .. "%"
			var_32_10.color = "#bde8e4"

			var_32_9.background:setBorderWidth(1)
			var_32_9.background:setBorderColor("#bde8e457")
		elseif iter_32_4.status == var_0_14.states.Finished or iter_32_4.status == var_0_14.states.SecondFinished then
			var_32_10.text = "Completed"
			var_32_10.color = "#88de75"

			var_32_9.background:setBorderWidth(1)
			var_32_9.background:setBorderColor("#88de7587")
			var_32_9.yes:show()
		elseif iter_32_4.status == var_0_14.states.Locked or iter_32_4.status == var_0_14.states.SecondLocked then
			var_32_10.text = "Locked"
			var_32_10.color = "#de7575"

			var_32_9.background:setBorderWidth(1)
			var_32_9.background:setBorderColor("#de757587")

			if var_32_9.background.setImageShader then
				var_32_9.background:setImageShader("map_nearest_gray")
			end

			var_32_9.locker:show()
			var_32_9.backgroundGrid:show()
			var_32_9.title:setText("????")
			var_32_9.kills.text:setText("???")
			var_32_9:setOpacity(0.5)

			iter_32_4._locked = true
		elseif iter_32_4.status == var_0_14.states.Available then
			var_32_10.text = "Available"
			var_32_10.color = "#c0de75"

			var_32_9.background:setBorderWidth(1)
			var_32_9.background:setBorderColor("#c0de7587")
		elseif iter_32_4.status == var_0_14.states.SecondAvailable then
			var_32_10.text = "Repeat"
			var_32_10.color = "#c0de75"

			var_32_9.background:setBorderWidth(1)
			var_32_9.background:setBorderColor("#c0de7587")
		end

		var_32_9.status:setText(var_32_10.text)
		var_32_9.status:setColor(var_32_10.color)

		for iter_32_6 = 1, 3 do
			local var_32_11 = iter_32_4["monster" .. iter_32_6 .. "Outfit"]

			if var_32_11 and var_32_11.lookType and var_32_11.lookType > 0 then
				local var_32_12 = {
					wings = 0,
					mount = 0,
					aura = 0,
					addons = 0,
					auxType = 0,
					manaBar = 0,
					healthBar = 0,
					shader = "",
					type = var_32_11.lookType,
					head = var_32_11.lookHead or 0,
					body = var_32_11.lookBody or 0,
					legs = var_32_11.lookLegs or 0,
					feet = var_32_11.lookFeet or 0,
					category = ThingCategoryCreature
				}

				var_32_9["creature" .. iter_32_6]:setOutfit(var_32_12)
				var_32_9["creature" .. iter_32_6]:getCreature():setOutfit(var_32_12)
				var_32_9["creature" .. iter_32_6]:getCreature():setStaticWalking(1000)

				if iter_32_4._locked then
					var_32_9["creature" .. iter_32_6]:getCreature():setShader("Outfit - cyclopedia-black")
				end

				if iter_32_6 == 1 or iter_32_6 == 3 then
					local var_32_13, var_32_14 = pcall(g_things.getThingType, var_32_12.type, ThingCategoryCreature)

					if var_32_13 and var_32_14 ~= nil then
						local var_32_15, var_32_16 = pcall(function()
							return var_32_14:getExactTextureSizePoint(0, 0, 0, 0, 0).x
						end)

						if var_32_15 and var_32_16 then
							if iter_32_6 == 1 then
								var_32_9.creature1:setMarginLeft(math.max(0, 64 - var_32_16 * 0.75))
							else
								var_32_9.creature3:setMarginRight(math.max(0, 64 - var_32_16 * 0.75))
							end
						end
					end
				end
			end
		end

		function var_32_9.onClick()
			if iter_32_4._locked then
				modules.game_textmessage.displayStatusMessage("Complete the previous task to unlock the next stage.")

				return
			end

			tasksWindow.main.selectedPanel:hide()
			tasksWindow.main.gridPanel:hide()
			tasksWindow.main.rewardPanel:hide()
			tasksWindow.main.loading:show()
			tasksWindow.back:show()
			var_0_13("request", iter_32_4.id)
		end

		function var_32_9.kills.icon.onClick()
			var_32_9:onClick()
		end

		connect(var_32_9.kills.icon, {
			onHoverChange = function(arg_36_0, arg_36_1)
				var_32_9:setBorderWidth(arg_36_1 and 1 or 0)
			end
		})
	end

	if tasksWindow.main.gridPanel.search:getText() == "" and tasksWindow.var.currentPage == math.ceil((#var_32_2 + 1) / var_32_6) then
		local var_32_17 = var_0_14.categories[getCurrentTaskSelectedStage()]

		if var_32_17 == nil then
			return
		end

		local var_32_18 = g_ui.createWidget("TaskElementHallBlock", tasksWindow.main.gridPanel.list)

		var_0_11(var_32_18)
		var_32_18.title:setText(var_32_17.hall)
		var_32_18.icon:setImageSource(var_32_17.icon)

		if var_32_17.gif and var_32_18.icon.setGifDuration then
			var_32_18.icon:setGifDuration(100)
			var_32_18.icon:setGifSource(var_32_17.icon)
			var_32_18.icon:setGifFrames(15)
			var_32_18.icon:setGifRect(torect("0 0 65 64"))
			var_32_18.icon:setImageClip(torect("0 0 65 64"))
		end

		if var_32_0 then
			var_32_18.status:setText(math.floor(var_32_1 * 100 / #tasksWindow.var.grid[getCurrentTaskSelectedStage()]) .. "%")
			var_32_18.status:setColor("#bde8e4")
		else
			var_32_18.status:setText("Locked")
			var_32_18.status:setColor("#de7575")

			if var_32_18.background.setImageShader then
				var_32_18.background:setImageShader("map_nearest_gray")
			end

			var_32_18.backgroundGrid:show()
		end

		function var_32_18.onClick()
			tasksWindow.main.selectedPanel:hide()
			tasksWindow.main.gridPanel:hide()
			tasksWindow.main.rewardPanel:hide()
			tasksWindow.main.loading:show()
			tasksWindow.back:show()
			var_0_13("request", getCurrentTaskSelectedStage() * 1000)
		end
	end
end

function updateTaskPointsBalance(arg_38_0)
	if not tasksWindow then
		return
	end

	taskCoinBalance = arg_38_0 or 0
	tasksWindow.taskPointsBalance.text:setText(comma_value(taskCoinBalance))
	if taskStoreWindow and taskStoreWindow.balance and taskStoreWindow.balance.text then
		taskStoreWindow.balance.text:setText("Task Coins: " .. comma_value(taskCoinBalance))
	end
end

function onCategoryReceived(arg_39_0, arg_39_1)
	if not arg_39_0 or not arg_39_1 then
		return
	end

	-- The linked-task server sends the creature look type in monster1/2/3,
	-- while the original task UI expects monster1/2/3Outfit tables.
	-- Normalize both formats here so every task card can render its monsters.
	for _, task in ipairs(arg_39_1) do
		for index = 1, 3 do
			local outfitKey = "monster" .. index .. "Outfit"
			local monsterKey = "monster" .. index
			local lookType = tonumber(task[monsterKey]) or 0
			if not task[outfitKey] and lookType > 0 then
				task[outfitKey] = {
					lookType = lookType,
					lookHead = 0,
					lookBody = 0,
					lookLegs = 0,
					lookFeet = 0
				}
			end
		end
	end

	tasksWindow.var.grid[arg_39_0] = arg_39_1

	if tasksWindow:isVisible() and getCurrentTaskSelectedStage() == arg_39_0 then
		reloadPageContent(false, true)
		tasksWindow:setWidth(911)
		tasksWindow:setHeight(789)
		tasksWindow.main.selectedPanel:hide()
		tasksWindow.main.gridPanel:show()
		tasksWindow.main.loading:hide()
		tasksWindow.main.rewardPanel:hide()
		tasksWindow.back:hide()
	end
end

function onTaskTrackerReceived(arg_40_0)
	var_0_1 = arg_40_0 or {}
	var_0_5 = 1

	updateTrackerWidget()
end

function toggleTracker(arg_41_0)
	var_0_2 = arg_41_0

	g_settings.set("taskTrackerVisible", arg_41_0)
	updateTrackerWidget()
end

function updateTrackerWidget()
	if not var_0_0 then
		return
	end

	if not var_0_2 or #var_0_1 == 0 then
		var_0_0:hide()

		if var_0_3 then
			removeEvent(var_0_3)

			var_0_3 = nil
		end

		if var_0_4 then
			removeEvent(var_0_4)

			var_0_4 = nil
		end

		return
	end

	local var_42_0 = {}

	for iter_42_0, iter_42_1 in ipairs(var_0_1) do
		if iter_42_1.creatures then
			for iter_42_2, iter_42_3 in ipairs(iter_42_1.creatures) do
				table.insert(var_42_0, {
					taskName = iter_42_1.name,
					name = iter_42_3.name,
					kills = iter_42_3.kills or 0,
					total = iter_42_1.total or 0,
					totalKills = iter_42_1.kills or 0,
					lookType = iter_42_3.lookType or iter_42_1.lookType or 0,
					lookHead = iter_42_3.lookHead or iter_42_1.lookHead or 0,
					lookBody = iter_42_3.lookBody or iter_42_1.lookBody or 0,
					lookLegs = iter_42_3.lookLegs or iter_42_1.lookLegs or 0,
					lookFeet = iter_42_3.lookFeet or iter_42_1.lookFeet or 0
				})
			end
		end
	end

	if #var_42_0 == 0 then
		var_0_0:hide()

		return
	end

	showTrackerCreature(var_42_0, 1)

	if var_0_3 then
		removeEvent(var_0_3)

		var_0_3 = nil
	end

	if #var_42_0 > 1 then
		var_0_3 = cycleEvent(function()
			if not var_0_0 or not var_0_2 or #var_42_0 == 0 then
				return
			end

			var_0_5 = var_0_5 % #var_42_0 + 1

			showTrackerCreature(var_42_0, var_0_5)
		end, 3000)
	end

	var_0_0:show()
	var_0_0:raise()
	startTrackerHighlight()
end

function startTrackerHighlight()
	if var_0_4 then
		removeEvent(var_0_4)

		var_0_4 = nil
	end

	if not var_0_0 then
		return
	end

	local var_44_0 = var_0_0:getChildById("highlight")

	if not var_44_0 then
		return
	end

	local var_44_1 = g_clock.millis()

	local function var_44_2()
		if not var_0_0 or not var_0_0:isVisible() then
			return
		end

		if not var_44_0 then
			return
		end

		local var_45_0 = g_clock.millis()
		local var_45_1 = (math.sin((var_45_0 - var_44_1) / 1000 * math.pi * 2) + 1) * 0.25

		var_44_0:setOpacity(var_45_1)
		var_44_0:setVisible(true)

		var_0_4 = scheduleEvent(var_44_2, 100)
	end

	var_44_2()
end

function showTrackerCreature(arg_46_0, arg_46_1)
	if not var_0_0 or not arg_46_0[arg_46_1] then
		return
	end

	local var_46_0 = arg_46_0[arg_46_1]
	local var_46_1 = var_0_0:getChildById("creature")
	local var_46_2 = var_0_0:getChildById("counter")

	if var_46_1 and var_46_0.lookType and var_46_0.lookType > 0 then
		local var_46_3 = {
			wings = 0,
			mount = 0,
			aura = 0,
			addons = 0,
			auxType = 0,
			manaBar = 0,
			healthBar = 0,
			shader = "",
			type = var_46_0.lookType,
			head = var_46_0.lookHead or 0,
			body = var_46_0.lookBody or 0,
			legs = var_46_0.lookLegs or 0,
			feet = var_46_0.lookFeet or 0,
			category = ThingCategoryCreature
		}

		var_46_1:setOutfit(var_46_3)
	end

	if var_46_2 then
		var_46_2:setText(tostring(var_46_0.totalKills) .. "/" .. tostring(var_46_0.total))

		if var_46_0.totalKills >= var_46_0.total then
			var_46_2:setColor("#00FF00")
		elseif var_46_0.totalKills > 0 then
			var_46_2:setColor("#FFFF00")
		else
			var_46_2:setColor("#FFFFFF")
		end
	end

	var_0_0:setTooltip(var_46_0.taskName)
end

function getRecommendedExerciseWeapon()
	local var_47_0 = g_game.getLocalPlayer()

	if not var_47_0 then
		return 0
	end

	local var_47_1 = var_47_0:getVocation()

	if var_47_1 == 3 or var_47_1 == 13 then
		return 35284
	end

	if var_47_1 == 4 or var_47_1 == 14 then
		return 35283
	end

	if var_47_1 == 2 or var_47_1 == 12 then
		return 35282
	end

	if var_47_1 == 5 or var_47_1 == 15 then
		return 50294
	end

	if var_47_1 == 1 or var_47_1 == 11 then
		local var_47_2 = var_47_0:getSkillLevel(2)
		local var_47_3 = var_47_0:getSkillLevel(1)
		local var_47_4 = var_47_0:getSkillLevel(3)
		local var_47_5 = math.max(var_47_2, var_47_3, var_47_4)

		if var_47_5 == var_47_3 then
			return 35281
		end

		if var_47_5 == var_47_4 then
			return 35280
		end

		return 35279
	end

	return 0
end

function showExerciseWindow()
	if not var_0_6 then
		return
	end

	var_0_7 = nil

	local var_48_0 = var_0_6:getChildById("exerciseGrid")

	if not var_48_0 then
		return
	end

	var_48_0:destroyChildren()

	local var_48_1 = getRecommendedExerciseWeapon()

	for iter_48_0, iter_48_1 in ipairs(var_0_10) do
		local var_48_2 = g_ui.createWidget("TaskExerciseItemWidget", var_48_0)

		var_48_2:setId("exerciseSlot" .. iter_48_0)

		local var_48_3 = var_48_2:getChildById("item")

		if var_48_3 then
			var_48_3:setItemId(iter_48_1.id)
		end

		var_48_2:setTooltip(iter_48_1.name)

		local var_48_4 = var_48_2:getChildById("recommendedLabel")

		if var_48_4 then
			var_48_4:setVisible(iter_48_1.id == var_48_1)
		end

		function var_48_2.onClick()
			selectExerciseItem(iter_48_0)
		end
	end

	var_0_6:show()
	var_0_6:raise()
	var_0_6:focus()
end

function selectExerciseItem(arg_50_0)
	if not var_0_10[arg_50_0] then
		return
	end

	var_0_7 = var_0_10[arg_50_0].id

	local var_50_0 = var_0_6:getChildById("exerciseGrid")

	if not var_50_0 then
		return
	end

	local var_50_1 = var_50_0:getChildren()

	for iter_50_0, iter_50_1 in ipairs(var_50_1) do
		local var_50_2 = iter_50_1:getChildById("selected")
		local var_50_3 = iter_50_1:getChildById("checkmark")

		if var_50_2 then
			var_50_2:setVisible(iter_50_0 == arg_50_0)
		end

		if var_50_3 then
			var_50_3:setVisible(iter_50_0 == arg_50_0)
		end
	end
end

function confirmExerciseReward()
	if not var_0_7 or not var_0_8 then
		return
	end

	local var_51_0 = g_game.getProtocolGame()

	if var_51_0 then
		var_51_0:sendExtendedOpcode(var_0_9, json.encode({
			action = "claim_exercise",
			id = var_0_8,
			weaponId = var_0_7
		}))
	end

	hideExerciseWindow()
end

function hideExerciseWindow()
	if var_0_6 then
		var_0_6:hide()
	end

	var_0_8 = nil
	var_0_7 = nil
end
