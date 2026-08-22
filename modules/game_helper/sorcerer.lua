HelperVoc = HelperVoc or {}
HelperVoc[5] = HelperVoc[5] or {}

local var_0_0 = HelperVoc[5]

function var_0_0.healingLayout(arg_1_0)
	applyHealingLayout({
		friend = true,
		potions = 3,
		spells = 2,
		sioText = "Enable UH"
	})
end

function var_0_0.shooterLayout(arg_2_0)
	arg_2_0:setSize(tosize("770 648"))
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
		sepCols = 362,
		rSpellLabel = 374,
		rPrioLabel = 527,
		rManaLabel = 422,
		attackSpellPanel3 = 372
	})
	runePanel:setVisible(true)
	runePanel:setHeight(178)
	enableButtons:addAnchor(AnchorTop, "runePanel", AnchorBottom)
	enableButtons:setMarginTop(5)
end
