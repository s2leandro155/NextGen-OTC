if not BattlePassRewards then
	BattlePassRewards = {}
	BattlePassRewards.__index = BattlePassRewards
	BattlePassRewards.claimRewardWindow = nil
	BattlePassRewards.confirmRewardWindow = nil
	BattlePassRewards.rewardWidthIncrement = 80
	BattlePassRewards.rewardEmptyHeight = 140
	BattlePassRewards.selectedItemId = -1
	BattlePassRewards.textReward = ""
end

local var_0_0 = {
	[0] = "Fist Fighting",
	"Club Fighting",
	"Sword Fighting",
	"Axe Fighting",
	"Distance Fighting",
	"Shielding",
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	"Magic Level"
}
local var_0_1 = BattlePassRewards
local var_0_2 = {
	prey_wildcard = "/images/game/battlepass/rewards/prey_wildcard",
	instant_reward = "/images/game/battlepass/rewards/instant_reward",
	charm_points = "/images/game/battlepass/rewards/charm_points"
}

function BattlePassRewards.onConfirmClaimReward(arg_1_0, arg_1_1, arg_1_2)
	local var_1_0 = arg_1_0:getReward(arg_1_1, arg_1_2)

	if not var_1_0 then
		return
	end

	if arg_1_0.confirmRewardWindow then
		arg_1_0.confirmRewardWindow:destroy()

		arg_1_0.confirmRewardWindow = nil
	end

	arg_1_0.claimRewardWindow = g_ui.createWidget("SelectRewardWindow", rootWidget)

	local var_1_1 = arg_1_0.claimRewardWindow:recursiveGetChildById("rewardsInfoPanel")
	local var_1_2 = arg_1_0.claimRewardWindow:recursiveGetChildById("rewardLabel")
	local var_1_3 = var_1_2:getText()

	var_1_2:setText(string.format(var_1_3, arg_1_1))

	function arg_1_0.claimRewardWindow.onEscape()
		arg_1_0.claimRewardWindow:destroy()

		arg_1_0.claimRewardWindow = nil

		BattlePass:showBattlePass()
	end

	arg_1_0.claimRewardWindow:recursiveGetChildById("close").onClick = function()
		arg_1_0.claimRewardWindow:destroy()

		arg_1_0.claimRewardWindow = nil

		BattlePass:showBattlePass()
	end

	local function var_1_4()
		if arg_1_0.selectedItemId == -1 and (BattleRewardTypes[var_1_0.rewardType] == "Boosted Exercise" or BattleRewardTypes[var_1_0.rewardType] == "Exercise Item" or BattleRewardTypes[var_1_0.rewardType] == "Extra Skill" or BattleRewardTypes[var_1_0.rewardType] == "Elemental Outfit" or BattleRewardTypes[var_1_0.rewardType] == "Choosable Item") then
			modules.game_textmessage.displayFailureMessage("You must select an item before collecting the reward.")

			return
		end

		local var_4_0 = BattlePass.window:recursiveGetChildById("confirmRewardOverlay")

		if var_4_0 then
			var_4_0:setVisible(false)
		end

		arg_1_0:onRedeemReward(arg_1_1, var_1_0.rewardId, var_1_0.rewardType, arg_1_0.selectedItemId)
	end

	local function var_1_5()
		local var_5_0 = BattlePass.window:recursiveGetChildById("confirmRewardOverlay")

		if var_5_0 then
			var_5_0:setVisible(false)
		end

		arg_1_0.claimRewardWindow:show()
	end

	arg_1_0.claimRewardWindow:recursiveGetChildById("collectRewardButton").onClick = function()
		if not var_1_0.rewardType or not BattleRewardTypes[var_1_0.rewardType] then
			if var_1_0.options and #var_1_0.options > 0 and arg_1_0.selectedItemId == -1 then
				return
			end

			arg_1_0.claimRewardWindow:destroy()

			arg_1_0.claimRewardWindow = nil

			BattlePass:showBattlePass()
			BattlePass.sendBattlePassAction({
				action = "redeem",
				stepId = arg_1_1,
				rewardType = arg_1_2,
				choiceId = arg_1_0.selectedItemId
			})

			return
		end

		if arg_1_0.selectedItemId == -1 and (BattleRewardTypes[var_1_0.rewardType] == "Boosted Exercise" or BattleRewardTypes[var_1_0.rewardType] == "Exercise Item" or BattleRewardTypes[var_1_0.rewardType] == "Extra Skill" or BattleRewardTypes[var_1_0.rewardType] == "Elemental Outfit" or BattleRewardTypes[var_1_0.rewardType] == "Choosable Item") then
			return
		end

		arg_1_0.claimRewardWindow:hide()

		local var_6_0 = BattlePass.window:recursiveGetChildById("confirmRewardOverlay")

		if var_6_0 then
			arg_1_0.confirmRewardWindow = var_6_0
			var_6_0:recursiveGetChildById("cancel").onClick = var_1_5
			var_6_0:recursiveGetChildById("confirm").onClick = var_1_4

			var_6_0:recursiveGetChildById("textContent"):setText(arg_1_0.textReward)
			var_6_0:setVisible(true)
			var_6_0:raise()
		else
			arg_1_0.confirmRewardWindow = g_ui.createWidget("ConfirmReward", rootWidget)
			arg_1_0.confirmRewardWindow.onEscape = var_1_5
			arg_1_0.confirmRewardWindow:recursiveGetChildById("cancel").onClick = var_1_5
			arg_1_0.confirmRewardWindow:recursiveGetChildById("confirm").onClick = var_1_4

			arg_1_0.confirmRewardWindow:recursiveGetChildById("textContent"):setText(arg_1_0.textReward)
		end
	end

	BattlePass.window:hide()

	arg_1_0.textReward = ""

	local var_1_6 = arg_1_0.claimRewardWindow:recursiveGetChildById("infoLabel")
	local var_1_7 = arg_1_0.claimRewardWindow:recursiveGetChildById("rewardsInfoPanel")
	local var_1_8 = arg_1_0.claimRewardWindow:recursiveGetChildById("outfitsInfoPanel")

	var_1_7:setVisible(true)
	var_1_8:setVisible(false)
	var_1_7:setWidth(arg_1_0.rewardWidthIncrement)

	local var_1_9 = arg_1_0.claimRewardWindow:recursiveGetChildById("rewardsInfoScrollBar")

	var_1_9:setVisible(true)

	local var_1_10 = 0
	local var_1_11 = 250

	arg_1_0.selectedItemId = -1

	if BattleRewardTypes[var_1_0.rewardType] == "Outfit" then
		local function var_1_12(arg_7_0)
			arg_1_0.currentOutfitDirection = arg_1_0.currentOutfitDirection or Directions.North

			local var_7_0 = arg_1_0.currentOutfitDirection + arg_7_0

			if var_7_0 < Directions.North then
				var_7_0 = Directions.West
			elseif var_7_0 > Directions.West then
				var_7_0 = Directions.North
			end

			arg_1_0.currentOutfitDirection = var_7_0

			local var_7_1 = 1

			while true do
				local var_7_2 = var_1_7:recursiveGetChildById("rewardSlot" .. var_7_1 - 1)

				if not var_7_2 then
					break
				end

				if var_7_2:isVisible() then
					var_7_2.rewardOutfit:setDirection(var_7_0)
				end

				var_7_1 = var_7_1 + 1
			end
		end

		local function var_1_13(arg_8_0, arg_8_1, arg_8_2)
			arg_8_0.rewardOutfit:setVisible(true)
			arg_8_0.rewardOutfit:setOutfit({
				type = arg_8_1.thingId,
				head = arg_8_2.head,
				body = arg_8_2.body,
				legs = arg_8_2.legs,
				feet = arg_8_2.feet,
				addons = var_1_0.addons
			})
			arg_8_0:setImageSource("/images/game/battlepass/ground-bg")

			if arg_1_0.currentOutfitDirection then
				arg_8_0.rewardOutfit:setDirection(arg_1_0.currentOutfitDirection)
			end
		end

		local var_1_14 = arg_1_0.claimRewardWindow:recursiveGetChildById("rotatePrevButton")
		local var_1_15 = arg_1_0.claimRewardWindow:recursiveGetChildById("rotateNextButton")

		var_1_7:setVisible(true)
		var_1_15:setVisible(true)
		var_1_14:setVisible(true)

		function var_1_15.onClick()
			var_1_12(-1)
		end

		function var_1_14.onClick()
			var_1_12(1)
		end

		local var_1_16 = ""
		local var_1_17 = ""

		for iter_1_0, iter_1_1 in pairs(var_1_0.randomValues) do
			local var_1_18 = var_1_1:recursiveGetChildById("rewardSlot" .. iter_1_0 - 1)

			var_1_18:setVisible(true)
			var_1_18.rewardOutfit:setVisible(true)

			local var_1_19 = g_game.getLocalPlayer():getOutfit()
			local var_1_20 = {
				type = iter_1_1.thingId,
				head = var_1_19.head,
				body = var_1_19.body,
				legs = var_1_19.legs,
				feet = var_1_19.feet,
				addons = var_1_0.addons
			}

			var_1_13(var_1_18, iter_1_1, var_1_19)

			var_1_17 = var_1_0.addons == 1 and "first addon" or var_1_0.addons == 2 and "second addon" or "full addons"

			local var_1_21 = string.format("%s with %s", iter_1_1.thingName, var_1_17)

			var_1_18.rewardOutfit:setTooltip(var_1_21)

			var_1_10 = var_1_10 + arg_1_0.rewardWidthIncrement
			var_1_16 = var_1_21
		end

		var_1_6:setText(string.format("You will receive the following outfit with %s:", var_1_17))

		arg_1_0.textReward = string.format("You will receive the following outfit:\n%s.", var_1_16)
	elseif BattleRewardTypes[var_1_0.rewardType] == "Random Item" then
		for iter_1_2, iter_1_3 in pairs(var_1_0.randomValues) do
			local var_1_22 = var_1_1:recursiveGetChildById("rewardSlot" .. iter_1_2 - 1)

			var_1_22:setVisible(true)
			var_1_22.rewardItem:setVisible(true)
			var_1_22.rewardItem:setItemId(iter_1_3.thingId)
			var_1_22.rewardItem.rewardItemCount:setText(var_1_0.count > 1 and tostring(var_1_0.count) or "")

			local var_1_23 = var_1_22.rewardItem:getItem()

			if var_1_23 then
				var_1_22.rewardItem:setTooltip(string.capitalize(var_1_23:getName()))
				var_1_22.rewardItem:setFixedSize(not var_1_23:isWrapable())
			end

			var_1_10 = var_1_10 + arg_1_0.rewardWidthIncrement
		end

		local var_1_24 = "You will receive a random item from the list bellow:"

		if var_1_0.stuck then
			var_1_24 = var_1_24 .. "\n[color=white]The reward will be bound to your character.[/color]"
		end

		arg_1_0.textReward = string.format("You will receive a random item from the list.")

		var_1_6:setColorText(var_1_24)
	elseif BattleRewardTypes[var_1_0.rewardType] == "Random Mount" then
		for iter_1_4, iter_1_5 in pairs(var_1_0.randomValues) do
			local var_1_25 = var_1_1:recursiveGetChildById("rewardSlot" .. iter_1_4 - 1)

			if not var_1_25 then
				var_1_25 = g_ui.createWidget("RewardInfoSlot", var_1_7)

				var_1_25:setId("rewardSlot" .. iter_1_4 - 1)
			end

			var_1_25:setVisible(true)
			var_1_25:setPhantom(false)
			var_1_25.rewardOutfit:setVisible(true)
			var_1_25.rewardOutfit:setTooltip(iter_1_5.thingName)
			var_1_25:setImageSource("/images/game/battlepass/ground-bg")
			var_1_25.rewardOutfit:setOutfit({
				type = iter_1_5.thingId
			})

			var_1_10 = var_1_10 + arg_1_0.rewardWidthIncrement
		end

		var_1_6:setText("You will receive a random mount from the list bellow:")

		arg_1_0.textReward = string.format("You will receive a random mount from the list.")
	elseif BattleRewardTypes[var_1_0.rewardType] == "Item" then
		local var_1_26 = var_1_1:recursiveGetChildById("rewardSlot0")

		var_1_26:setVisible(true)
		var_1_26.rewardItem:setVisible(true)
		var_1_26.rewardItem:setItemId(var_1_0.itemId)
		var_1_26.rewardItem.rewardItemCount:setText(var_1_0.count > 1 and tostring(var_1_0.count) or "")

		local var_1_27 = getItemNameById(var_1_0.itemId)
		local var_1_28 = var_1_26.rewardItem:getItem()

		if var_1_28 then
			var_1_27 = var_1_28:getName()
		end

		if var_1_0.charges > 0 then
			var_1_26.rewardItem:setTooltip(string.format("%s\nCharges: %s", string.capitalize(var_1_27), var_1_0.charges))
		else
			var_1_26.rewardItem:setTooltip(string.format("%sx %s", var_1_0.count, string.capitalize(var_1_27)))
		end

		if var_1_28 then
			var_1_26.rewardItem:setFixedSize(not var_1_28:isWrapable())

			if var_1_0.itemId == 63246 then
				var_1_26.rewardItem:setFixedSize(true)
			end
		end

		var_1_10 = var_1_10 + arg_1_0.rewardWidthIncrement

		local var_1_29 = "You will receive the following item."

		if var_1_0.stuck then
			var_1_29 = var_1_29 .. "\n[color=white]The reward will be bound to your character.[/color]"
		end

		var_1_6:setColorText(var_1_29)

		arg_1_0.textReward = string.format("You will receive the following item: %d %s.", var_1_0.count, string.capitalize(var_1_27))
	elseif BattleRewardTypes[var_1_0.rewardType] == "Boosted Exercise" or BattleRewardTypes[var_1_0.rewardType] == "Exercise Item" then
		for iter_1_6, iter_1_7 in pairs(var_1_0.randomValues) do
			local var_1_30 = var_1_1:recursiveGetChildById("rewardSlot" .. iter_1_6 - 1)

			var_1_30:setVisible(true)
			var_1_30.rewardItem:setVisible(true)
			var_1_30.rewardItem:setItemId(iter_1_7.thingId)

			local var_1_31 = var_1_30.rewardItem:getItem()
			local var_1_32 = getItemNameById(iter_1_7.itemId)

			if var_1_31 then
				var_1_32 = var_1_31:getName()
			end

			var_1_30.rewardItem:setTooltip(string.capitalize(var_1_32))
			var_1_30:setFocusable(true)

			var_1_11 = 260

			function var_1_30.rewardItem.onClick(arg_11_0)
				if arg_11_0:isFocused() then
					arg_1_0.selectedItemId = iter_1_7.thingId
					arg_1_0.textReward = string.format("You must choose one %s,\nhave %d charges.", string.capitalize(var_1_32), var_1_0.charges)
				end
			end

			var_1_10 = var_1_10 + arg_1_0.rewardWidthIncrement
		end

		local var_1_33 = "You must choose [color=white]one[/color] of the following items, have [color=white]" .. var_1_0.charges .. " charges.[/color]"

		if var_1_0.stuck then
			var_1_33 = var_1_33 .. "\n[color=white]The reward will be bound to your character.[/color]"
		end

		var_1_6:setColorText(var_1_33)
	elseif BattleRewardTypes[var_1_0.rewardType] == "Charms" then
		var_1_6:setColorText("You will receive [color=white]+" .. var_1_0.count .. " charm points[/color] on your character.")
		var_1_7:setVisible(false)
		var_1_9:setVisible(false)

		var_1_11 = arg_1_0.rewardEmptyHeight
		arg_1_0.textReward = string.format("You will receive +%d charm points on your character.", var_1_0.count)
	elseif BattleRewardTypes[var_1_0.rewardType] == "Prey" then
		var_1_6:setColorText("You will receive [color=white]+" .. var_1_0.count .. " prey wildcards[/color] on your character.")
		var_1_7:setVisible(false)
		var_1_9:setVisible(false)

		var_1_11 = arg_1_0.rewardEmptyHeight
		arg_1_0.textReward = string.format("You will receive +%d prey wildcards on your character.", var_1_0.count)
	elseif BattleRewardTypes[var_1_0.rewardType] == "Regen" then
		var_1_6:setColorText("You will receive [color=white]" .. var_1_0.durationTime .. " hours (Scroll 30 days) of Double Regeneration[/color].")
		var_1_7:setVisible(false)
		var_1_9:setVisible(false)

		var_1_11 = arg_1_0.rewardEmptyHeight
		arg_1_0.textReward = string.format("You will receive %d hours (Scroll 30 days)\nof Double Regeneration.", var_1_0.durationTime)
	elseif BattleRewardTypes[var_1_0.rewardType] == "Instant Reward" then
		var_1_6:setColorText("You will receive [color=white]+" .. var_1_0.count .. " instant rewards[/color] on your character.")
		var_1_7:setVisible(false)
		var_1_9:setVisible(false)

		var_1_11 = arg_1_0.rewardEmptyHeight
		arg_1_0.textReward = string.format("You will receive +%d instant rewards on your character.", var_1_0.count)
	elseif BattleRewardTypes[var_1_0.rewardType] == "Double Skill" then
		var_1_6:setColorText("You will receive [color=white]" .. var_1_0.durationTime .. " hours (Scroll 30 days) of Double Skill[/color].")
		var_1_7:setVisible(false)
		var_1_9:setVisible(false)

		var_1_11 = arg_1_0.rewardEmptyHeight
		arg_1_0.textReward = string.format("You will receive %d hours (Scroll 30 days)\nof Double Skill.", var_1_0.durationTime)
	elseif BattleRewardTypes[var_1_0.rewardType] == "Level" then
		var_1_6:setColorText("You will receive [color=white]+" .. var_1_0.count .. " Level[/color] on your character.")
		var_1_7:setVisible(false)
		var_1_9:setVisible(false)

		var_1_11 = arg_1_0.rewardEmptyHeight
		arg_1_0.textReward = string.format("You will receive +%d Level on your character.", var_1_0.count)
	elseif BattleRewardTypes[var_1_0.rewardType] == "Overload Forge" then
		var_1_6:setColorText("You will receive [color=white]" .. var_1_0.durationTime .. " hours (Scroll 30 days) of Exaltation Overload[/color].")
		var_1_7:setVisible(false)
		var_1_9:setVisible(false)

		var_1_11 = arg_1_0.rewardEmptyHeight
		arg_1_0.textReward = string.format("You will receive %d hours (Scroll 30 days)\nof Exaltation Overload.", var_1_0.durationTime)
	elseif BattleRewardTypes[var_1_0.rewardType] == "Exp Boost" then
		var_1_6:setColorText("You will receive [color=white]" .. var_1_0.durationTime .. " hours of store XP Boost[/color].")
		var_1_7:setVisible(false)
		var_1_9:setVisible(false)

		var_1_11 = arg_1_0.rewardEmptyHeight
		arg_1_0.textReward = string.format("You will receive %d hours of store XP Boost,\nlinked to your skill tab.", var_1_0.durationTime)
	elseif BattleRewardTypes[var_1_0.rewardType] == "Extra Skill" then
		var_1_6:setColorText("You will receive [color=white]+" .. var_1_0.count .. " skill points[/color] in the skill of your choice for [color=white]" .. var_1_0.durationTime .. " hours[/color].")
		var_1_7:setVisible(true)
		var_1_9:setVisible(true)

		local var_1_34 = {
			0,
			1,
			2,
			3,
			4,
			5,
			13
		}

		for iter_1_8, iter_1_9 in pairs(var_1_34) do
			local var_1_35 = var_1_1:recursiveGetChildById("rewardSlot" .. iter_1_8 - 1)

			var_1_35:setVisible(true)
			var_1_35.rewardSpecial:setVisible(true)
			var_1_35.rewardSpecial:setTooltip(var_0_0[iter_1_9] .. " (" .. var_1_0.count .. " points for " .. var_1_0.durationTime .. " hours)")
			var_1_35.rewardSpecial:setImageSource("/images/game/battlepass/skills/" .. iter_1_9)
			var_1_35:setFocusable(true)

			function var_1_35.rewardSpecial.onClick(arg_12_0)
				if arg_12_0:isFocused() then
					arg_1_0.selectedItemId = iter_1_9
				end
			end

			var_1_10 = var_1_10 + arg_1_0.rewardWidthIncrement
		end
	elseif BattleRewardTypes[var_1_0.rewardType] == "Elemental Outfit" then
		local function var_1_36(arg_13_0)
			arg_1_0.currentOutfitDirection = arg_1_0.currentOutfitDirection or Directions.North

			local var_13_0 = arg_1_0.currentOutfitDirection + arg_13_0

			if var_13_0 < Directions.North then
				var_13_0 = Directions.West
			elseif var_13_0 > Directions.West then
				var_13_0 = Directions.North
			end

			arg_1_0.currentOutfitDirection = var_13_0

			local var_13_1 = 1

			while true do
				local var_13_2 = var_1_8:recursiveGetChildById("outfitPreview" .. var_13_1 - 1)

				if not var_13_2 then
					break
				end

				if var_13_2:isVisible() then
					var_13_2.rewardOutfit:setDirection(var_13_0)
				end

				var_13_1 = var_13_1 + 1
			end
		end

		local function var_1_37(arg_14_0, arg_14_1, arg_14_2)
			arg_14_0.rewardOutfit:setVisible(true)
			arg_14_0.rewardOutfit:setOutfit({
				type = arg_14_1.looktype,
				head = arg_14_2.head,
				body = arg_14_2.body,
				legs = arg_14_2.legs,
				feet = arg_14_2.feet,
				addons = var_1_0.addons
			})
			arg_14_0.rewardOutfit:setTooltip(arg_14_1.name)
			arg_14_0:setTooltip(arg_14_1.name)
			arg_14_0:setImageSource("/images/game/battlepass/ground-bg")

			if arg_1_0.currentOutfitDirection then
				arg_14_0.rewardOutfit:setDirection(arg_1_0.currentOutfitDirection)
			end
		end

		local var_1_38 = arg_1_0.claimRewardWindow:recursiveGetChildById("previousButton")
		local var_1_39 = arg_1_0.claimRewardWindow:recursiveGetChildById("nextButton")

		var_1_6:setColorText("You will receive the [color=white]Elemental Outfit[/color] of your choice.")
		var_1_7:setVisible(true)
		var_1_8:setVisible(true)
		var_1_39:setVisible(true)
		var_1_38:setVisible(true)

		function var_1_39.onClick()
			var_1_36(-1)
		end

		function var_1_38.onClick()
			var_1_36(1)
		end

		var_1_11 = 340

		local var_1_40 = {
			"Death",
			"Energy",
			"Holy",
			"Ice",
			"Earth",
			"Fire"
		}

		for iter_1_10 = 1, 6 do
			local var_1_41 = var_1_1:recursiveGetChildById("rewardSlot" .. iter_1_10 - 1)

			var_1_41:setVisible(true)
			var_1_41.rewardSpecial:setVisible(true)
			var_1_41.rewardSpecial:setImageSource("/images/game/battlepass/tiles/" .. iter_1_10)
			var_1_41.rewardSpecial:setTooltip("Elemental Outfit " .. var_1_40[iter_1_10])
			var_1_41:setFocusable(true)

			if iter_1_10 == 1 then
				var_1_41:recursiveFocus(2)

				arg_1_0.selectedItemId = iter_1_10

				local var_1_42 = g_game.getLocalPlayer():getOutfit()
				local var_1_43 = 1

				for iter_1_11, iter_1_12 in pairs(var_1_0.maleOutfit[iter_1_10]) do
					local var_1_44 = var_1_8:recursiveGetChildById("outfitPreview" .. var_1_43 - 1)

					var_1_37(var_1_44, iter_1_12, var_1_42)

					var_1_43 = var_1_43 + 1
				end

				for iter_1_13, iter_1_14 in pairs(var_1_0.femaleOutfit[iter_1_10]) do
					local var_1_45 = var_1_8:recursiveGetChildById("outfitPreview" .. var_1_43 - 1)

					var_1_37(var_1_45, iter_1_14, var_1_42)

					var_1_43 = var_1_43 + 1
				end
			end

			function var_1_41.rewardSpecial.onClick(arg_17_0)
				if arg_17_0:isFocused() then
					arg_1_0.selectedItemId = iter_1_10

					local var_17_0 = g_game.getLocalPlayer():getOutfit()
					local var_17_1 = 1

					for iter_17_0, iter_17_1 in pairs(var_1_0.maleOutfit[iter_1_10]) do
						local var_17_2 = var_1_8:recursiveGetChildById("outfitPreview" .. var_17_1 - 1)

						var_1_37(var_17_2, iter_17_1, var_17_0)

						var_17_1 = var_17_1 + 1
					end

					for iter_17_2, iter_17_3 in pairs(var_1_0.femaleOutfit[iter_1_10]) do
						local var_17_3 = var_1_8:recursiveGetChildById("outfitPreview" .. var_17_1 - 1)

						var_1_37(var_17_3, iter_17_3, var_17_0)

						var_17_1 = var_17_1 + 1
					end
				end
			end

			var_1_10 = var_1_10 + arg_1_0.rewardWidthIncrement
		end
	elseif BattleRewardTypes[var_1_0.rewardType] == "Choosable Item" then
		for iter_1_15, iter_1_16 in pairs(var_1_0.choosableValues) do
			local var_1_46 = var_1_1:recursiveGetChildById("rewardSlot" .. iter_1_15 - 1)

			var_1_46:setVisible(true)
			var_1_46.rewardItem:setVisible(true)
			var_1_46.rewardItem:setItemId(iter_1_16.thingId)
			var_1_46.rewardItem.rewardItemCount:setText(var_1_0.count > 1 and tostring(var_1_0.count) or "")

			local var_1_47 = var_1_46.rewardItem:getItem()
			local var_1_48 = getItemNameById(iter_1_16.thingId)

			if var_1_47 then
				var_1_48 = var_1_47:getName()

				var_1_46.rewardItem:setFixedSize(not var_1_47:isWrapable())
			end

			var_1_46.rewardItem:setTooltip(string.format("%dx %s", var_1_0.count, string.capitalize(var_1_48)))
			var_1_46:setFocusable(true)

			var_1_11 = 260

			function var_1_46.rewardItem.onClick(arg_18_0)
				if arg_18_0:isFocused() then
					arg_1_0.selectedItemId = iter_1_16.thingId
					arg_1_0.textReward = string.format("You have selected %dx %s.", var_1_0.count, string.capitalize(var_1_48))
				end
			end

			var_1_10 = var_1_10 + arg_1_0.rewardWidthIncrement
		end

		local var_1_49 = "You must choose [color=white]one[/color] of the following items:"

		if var_1_0.stuck then
			var_1_49 = var_1_49 .. "\n[color=white]The reward will be bound to your character.[/color]"
		end

		var_1_6:setColorText(var_1_49)
	elseif BattleRewardTypes[var_1_0.rewardType] == "Multi Items" then
		local var_1_50 = var_1_0.stuck or false
		local var_1_51 = ""

		for iter_1_17, iter_1_18 in pairs(var_1_0.items) do
			local var_1_52 = var_1_1:recursiveGetChildById("rewardSlot" .. iter_1_17 - 1)

			var_1_52:setVisible(true)
			var_1_52.rewardItem:setVisible(true)
			var_1_52.rewardItem:setItemId(iter_1_18.itemId)
			var_1_52.rewardItem.rewardItemCount:setText(iter_1_18.count > 1 and tostring(iter_1_18.count) or "")

			local var_1_53 = var_1_52.rewardItem:getItem()
			local var_1_54 = getItemNameById(iter_1_18.itemId)

			if var_1_53 then
				var_1_54 = var_1_53:getName()

				var_1_52.rewardItem:setFixedSize(not var_1_53:isWrapable())
				var_1_52.rewardItem:setTooltip(string.capitalize(var_1_53:getName()))
			end

			var_1_10 = var_1_10 + arg_1_0.rewardWidthIncrement

			if iter_1_18.stuck then
				var_1_50 = true
			end

			if var_1_54 ~= "" then
				var_1_54 = var_1_54 .. ", " .. iter_1_18.count .. " " .. string.capitalize(var_1_54)
			else
				local var_1_55 = iter_1_18.count .. " " .. string.capitalize(var_1_54)
			end
		end

		local var_1_56 = "You will receive these items from the list bellow:"

		if var_1_50 then
			var_1_56 = var_1_56 .. "\n[color=white]The reward will be bound to your character.[/color]"
		end

		var_1_6:setColorText(var_1_56)

		arg_1_0.textReward = string.format("You will receive these items from the list:\n%s", var_1_51)
	else
		local var_1_57 = var_1_0.rewardName or "Battle Pass Reward"
		local var_1_58 = var_1_0.freeReward and "Free" or "Deluxe"

		if var_1_0.options and #var_1_0.options > 0 then
			local var_1_59 = string.format("%s Reward - Level %d\n\nChoose your %s:", var_1_58, arg_1_1, var_1_57)

			var_1_6:setText(var_1_59)

			arg_1_0.textReward = ""
			arg_1_0.selectedItemId = -1

			for iter_1_19, iter_1_20 in ipairs(var_1_0.options) do
				if iter_1_19 > 12 then
					break
				end

				local var_1_60 = var_1_1:recursiveGetChildById("rewardSlot" .. iter_1_19 - 1)

				if var_1_60 then
					var_1_60:setVisible(true)

					local var_1_61 = var_1_60:recursiveGetChildById("rewardItem") or var_1_60:getFirstChild()

					if var_1_61 then
						var_1_61:setVisible(true)

						if iter_1_20.itemId and iter_1_20.itemId > 0 then
							if var_1_61.setItemId then
								var_1_61:setItemId(iter_1_20.itemId)
							end
						elseif iter_1_20.mountId and iter_1_20.mountId > 0 then
							if var_1_61.setOutfit then
								var_1_61:setOutfit({
									type = iter_1_20.mountId
								})
							end
						elseif iter_1_20.outfitId and iter_1_20.outfitId > 0 and var_1_61.setOutfit then
							local var_1_62 = g_game.getLocalPlayer()
							local var_1_63 = {
								addons = 3,
								type = iter_1_20.outfitId
							}

							if var_1_62 then
								local var_1_64 = var_1_62:getOutfit()

								var_1_63.head = var_1_64.head
								var_1_63.body = var_1_64.body
								var_1_63.legs = var_1_64.legs
								var_1_63.feet = var_1_64.feet
							end

							var_1_61:setOutfit(var_1_63)
						end

						var_1_61:setTooltip(iter_1_20.name or "Option " .. iter_1_19)
					end

					var_1_60:setFocusable(true)
					var_1_60:setPhantom(false)

					local function var_1_65()
						for iter_19_0 = 0, 11 do
							local var_19_0 = var_1_1:recursiveGetChildById("rewardSlot" .. iter_19_0)

							if var_19_0 and var_19_0:isVisible() then
								var_19_0:setBorderWidth(1)
								var_19_0:setBorderColor("#161616")
								var_19_0:setOpacity(0.6)
							end
						end

						var_1_60:setBorderWidth(2)
						var_1_60:setBorderColor("#00ff00")
						var_1_60:setOpacity(1)

						arg_1_0.selectedItemId = iter_1_20.itemId or iter_1_20.mountId or iter_1_20.outfitId or iter_1_19
						arg_1_0.textReward = string.format("You will receive: %s", iter_1_20.name or var_1_57)
					end

					var_1_60.onClick = var_1_65
					var_1_60.onDoubleClick = var_1_65

					function var_1_60.onMouseRelease(arg_20_0, arg_20_1, arg_20_2)
						if arg_20_2 == MouseLeftButton then
							var_1_65()
						end

						return true
					end

					if var_1_61 then
						var_1_61:setPhantom(true)
					end

					var_1_60:setOpacity(0.6)

					var_1_10 = var_1_10 + (arg_1_0.rewardWidthIncrement or 75)
				end
			end

			var_1_11 = 280
		else
			local var_1_66 = string.format("%s Reward - Level %d\n\n%s\n\nClick Collect to claim this reward.", var_1_58, arg_1_1, var_1_57)

			var_1_6:setText(var_1_66)

			arg_1_0.textReward = string.format("You will receive: %s", var_1_57)
			var_1_10 = 175
			var_1_11 = 220

			local var_1_67 = var_0_2[var_1_0.rewardType]
			local var_1_68 = var_1_1:recursiveGetChildById("rewardSlot0")

			if var_1_0.itemId and var_1_0.itemId > 0 and var_1_68 and var_1_68.rewardItem then
				var_1_68:setVisible(true)
				var_1_68.rewardItem:setVisible(true)
				var_1_68.rewardItem:setItemId(var_1_0.itemId)
				var_1_68.rewardItem.rewardItemCount:setText(var_1_0.count and var_1_0.count > 1 and tostring(var_1_0.count) or "")

				local var_1_69 = var_1_68.rewardItem:getItem()
				local var_1_70 = var_1_69 and var_1_69:getName() or var_1_57

				var_1_68.rewardItem:setTooltip(string.capitalize(var_1_70))
			elseif var_1_67 and var_1_68 and var_1_68.rewardSpecial then
				var_1_68:setVisible(true)
				var_1_68.rewardSpecial:setVisible(true)
				var_1_68.rewardSpecial:setImageSource(var_1_67)
				var_1_68.rewardSpecial:setTooltip(var_1_57)
			end
		end
	end

	local var_1_71 = 0
	local var_1_72 = 0

	while true do
		local var_1_73 = var_1_1:recursiveGetChildById("rewardSlot" .. var_1_72)

		if not var_1_73 then
			break
		end

		if var_1_73:isVisible() then
			var_1_71 = var_1_71 + 1
		end

		var_1_72 = var_1_72 + 1
	end

	if var_1_71 >= 6 then
		var_1_7:setWidth(465)
	else
		var_1_7:setWidth(math.min(430, var_1_10) + 10)
	end

	arg_1_0.claimRewardWindow:setSize(tosize(500 .. " " .. var_1_11))

	if var_1_10 <= 175 then
		var_1_9:setVisible(false)
		var_1_7:setImageSource("")
	end
end

function BattlePassRewards.onRedeemReward(arg_21_0, arg_21_1, arg_21_2, arg_21_3, arg_21_4)
	if not g_game.isOnline() then
		return
	end

	local var_21_0 = arg_21_2 % 10 == 1 and "free" or "premium"
	local var_21_1 = {
		action = "redeem",
		stepId = arg_21_1,
		rewardType = var_21_0
	}

	if arg_21_4 and arg_21_4 ~= -1 then
		var_21_1.choiceId = arg_21_4
	end

	BattlePass.sendBattlePassAction(var_21_1)
end

function BattlePassRewards.getRewardDescription(arg_22_0, arg_22_1)
	if arg_22_1.rewardType == 1 then
		local var_22_0 = getItemNameById(arg_22_1.itemId)

		return string.format("%dx %s", arg_22_1.count, string.capitalize(var_22_0))
	end

	return "Reward Type: " .. BattleRewardTypes[arg_22_1.rewardType]
end

function BattlePassRewards.getReward(arg_23_0, arg_23_1, arg_23_2)
	local var_23_0 = arg_23_2 == "free"

	for iter_23_0, iter_23_1 in ipairs(BattlePass.rewardSteps) do
		if iter_23_1.stepId == arg_23_1 then
			for iter_23_2, iter_23_3 in ipairs(iter_23_1.rewards) do
				if var_23_0 and iter_23_3.freeReward then
					return iter_23_3
				elseif not var_23_0 and not iter_23_3.freeReward then
					return iter_23_3
				end
			end
		end
	end

	return nil
end
