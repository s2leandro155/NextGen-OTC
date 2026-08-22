HelperVoc = HelperVoc or {}
HelperVoc[7] = HelperVoc[7] or {}

local var_0_0 = HelperVoc[7]

function var_0_0.healingLayout(arg_1_0)
	applyHealingLayout({
		potions = 5,
		spells = 3,
		priorityTooltip = true
	})
end

function var_0_0.shooterLayout(arg_2_0)
	arg_2_0:setSize(tosize("555 601"))
	runePanel:setVisible(true)
	runePanel:setHeight(178)
	spellPanel:setHeight(178)
	attackSpellPanel3:setVisible(true)
	attackSpellPanel4:setVisible(true)
	enableButtons:addAnchor(AnchorTop, "runePanel", AnchorBottom)
	enableButtons:setMarginTop(5)
end
