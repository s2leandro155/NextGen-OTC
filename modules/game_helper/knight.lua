HelperVoc = HelperVoc or {}
HelperVoc[8] = HelperVoc[8] or {}

local var_0_0 = HelperVoc[8]

function var_0_0.healingLayout(arg_1_0)
	applyHealingLayout({
		spells = 3,
		potions = 4
	})
end

function var_0_0.shooterLayout(arg_2_0)
	arg_2_0:setSize(tosize("770 627"))
	spellPanel:setHeight(225)
	attackSpellPanel3:setVisible(true)
	attackSpellPanel4:setVisible(true)
	attackSpellPanel6:setVisible(true)

	local var_2_0 = {
		"attackSpellButton5",
		"rmvPercentButton5",
		"spellPercentBg5",
		"addPercentButton5",
		"countMinCreature5",
		"priority5"
	}

	for iter_2_0, iter_2_1 in ipairs(var_2_0) do
		local var_2_1 = spellPanel:recursiveGetChildById(iter_2_1)

		if var_2_1 then
			var_2_1:setVisible(true)
		end
	end

	setShooterColumnLayout({
		attackSpellPanel3 = 372,
		rPrioLabel = 527,
		rManaLabel = 422,
		rSpellLabel = 374,
		sepCols = 362
	})
	runePanel:setVisible(true)
	runePanel:setHeight(150)

	local var_2_2 = {
		"sep1",
		"priorityLabel",
		"conditionSetting0",
		"runePriority0",
		"runeHelp0",
		"runeShooterButton1",
		"countMinCreature1",
		"conditionSetting1",
		"runePriority1",
		"runeHelp1",
		"targetRuneLabel",
		"runeShooterButton2",
		"countMinCreature2",
		"conditionSetting2",
		"runePriority2",
		"runeHelp2"
	}

	for iter_2_2, iter_2_3 in ipairs(var_2_2) do
		local var_2_3 = runePanel:recursiveGetChildById(iter_2_3)

		if var_2_3 then
			var_2_3:setVisible(false)
		end
	end

	local var_2_4 = {
		"runeShooterButton0",
		"runeLabel",
		"sep0",
		"creaturesLabel",
		"countMinCreature0",
		"cycleRuneIntervalLabel",
		"cycleRuneInterval",
		"cycleRuneCheck",
		"combatStancePanel"
	}

	for iter_2_4, iter_2_5 in ipairs(var_2_4) do
		local var_2_5 = runePanel:recursiveGetChildById(iter_2_5)

		if var_2_5 then
			var_2_5:setVisible(true)
		end
	end

	enableButtons:addAnchor(AnchorTop, "runePanel", AnchorBottom)
	enableButtons:setMarginTop(5)
end
