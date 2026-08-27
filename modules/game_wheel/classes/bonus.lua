-- chunkname: @/game_wheel/classes/bonus.lua

WheelPointTooltip = "From level 51 onwards, you receive one promotion point with each level, of which you currently have %s.\n\nFor each fully enhanced mod, you will receive another promotion point. This currently gives you %s out of a maximum of 69 points.\n\nCertain rare items and special game accomplishments can earn you bonus promotion points, of wich you currently have %s:"
ConvictionTooltip = "The Conviction Perk is unlocked when the maximum number of\npromotion points for this slice has been assigned.\n\nMost Conviction Perks can be found more than once within the\nWheel of Destiny. When they are unlocked, thier effect adds up."
WheelDedicationHeight = {
	{
		45,
		60,
		60,
		74
	},
	{
		45,
		45,
		60,
		74
	},
	{
		45,
		60,
		60,
		74
	},
	{
		45,
		60,
		74,
		74
	},
	{
		45,
		60,
		60,
		74
	}
}
WheelConsts = {
	lifeleech = 0.75,
	skill = 1,
	manaleech = 0.25,
	mitigation = 0.03,
	lifemana = {
		life = {
			3,
			2,
			1,
			1,
			2
		},
		mana = {
			1,
			3,
			6,
			6,
			2
		}
	},
	special_1 = {
		{
			"Battle Instinct",
			"Gain +6 shielding and +1 sword/axe/club fighting when 5\ncreatures are on adjacent squares.\nFor each additional creature, up to a maximum of 8, you get +6\nshielding and +1 sword/axe/club fighting more."
		},
		{
			"Positional Tatic",
			"Gain +3 distance fighting while no monster is within 1 squares.\nOtherwise gain +3 holy magic level and +3 healing magic level."
		},
		{
			"Runic Mastery",
			"If you use a rune, you have a 25% chance of increasing your magic\nlevel by 10%, or by 20% if you use a rune that can be created by\nyour vocation."
		},
		{
			"Healing Link",
			"If you heal someone with Nature's Embrace or Heal Friend, you\nalso heal yourself for 10% of the applied healing."
		},
		{
			"Guiding Presence",
			"Gain an aura that shares 50% of your mantra with members of your group."
		}
	},
	special_2 = {
		{
			"Battle Healing",
			"For each creature challenged, you will heal yourself for a small\namount. This amount scales with your shielding skill. Heals for\ndouble the amount if you have less than 60% of your hit points and\ntriple the amount if you have less than 30% of your hit points."
		},
		{
			"Ballistic Mastery",
			"The critical extra damage for attacks with a crossbow is increased\nby 10%. While wielding a bow your attacks and spells treat the\ntargets physical and holy sensitivity as being 2% higher."
		},
		{
			"Focus Mastery",
			"Increases the damage of your next damage spell by 35% within 12\nseconds after casting a focus spell."
		},
		{
			"Runic Mastery",
			"If you use a rune, you have a 25% chance of increasing your magic\nlevel by 10%, or by 20% if you use a rune that can be created by\nyour vocation."
		},
		{
			"Sanctuary",
			"Consuming Harmony creates a field lasting 5 seconds, increasing your damage and healing done by 2% for each Harmony consumed."
		}
	},
	health = {
		3,
		2,
		1,
		1,
		2
	},
	mana = {
		1,
		3,
		6,
		6,
		2
	},
	spell_1 = {
		6,
		21
	},
	spell_2 = {
		8,
		24
	},
	capacity = {
		5,
		4,
		2,
		2,
		5
	},
	spell_3 = {
		11,
		26
	},
	spell_4 = {
		13,
		29
	},
	spell_5 = {
		16,
		31
	}
}
WheelBonus = {
	[0] = {
		domain = 1,
		maxPoints = 200,
		conviction = "special_1",
		dedication = "lifemana"
	},
	{
		domain = 1,
		maxPoints = 150,
		conviction = "manaleech",
		dedication = "mitigation"
	},
	{
		domain = 1,
		maxPoints = 100,
		modType = 1,
		conviction = "vessel",
		dedication = "health"
	},
	{
		domain = 2,
		maxPoints = 100,
		conviction = "skill",
		dedication = "mana"
	},
	{
		domain = 2,
		maxPoints = 150,
		modType = 2,
		conviction = "vessel",
		dedication = "health"
	},
	{
		domain = 2,
		maxPoints = 200,
		conviction = "spell_1",
		dedication = "lifemana"
	},
	{
		domain = 1,
		maxPoints = 150,
		modType = 2,
		conviction = "vessel",
		dedication = "mitigation"
	},
	{
		domain = 1,
		maxPoints = 100,
		conviction = "spell_2",
		dedication = "health"
	},
	{
		domain = 1,
		maxPoints = 75,
		conviction = "lifeleech",
		dedication = "mana"
	},
	{
		domain = 2,
		maxPoints = 75,
		modType = 0,
		conviction = "vessel",
		dedication = "capacity"
	},
	{
		domain = 2,
		maxPoints = 100,
		conviction = "spell_3",
		dedication = "mana"
	},
	{
		domain = 2,
		maxPoints = 150,
		conviction = "manaleech",
		dedication = "health"
	},
	{
		domain = 1,
		maxPoints = 100,
		conviction = "spell_4",
		dedication = "health"
	},
	{
		domain = 1,
		maxPoints = 75,
		conviction = "skill",
		dedication = "mana"
	},
	{
		domain = 1,
		maxPoints = 50,
		modType = 0,
		conviction = "vessel",
		dedication = "capacity"
	},
	{
		domain = 2,
		maxPoints = 50,
		conviction = "spell_5",
		dedication = "mitigation"
	},
	{
		domain = 2,
		maxPoints = 75,
		conviction = "lifeleech",
		dedication = "capacity"
	},
	{
		domain = 2,
		maxPoints = 100,
		modType = 1,
		conviction = "vessel",
		dedication = "mana"
	},
	{
		domain = 3,
		maxPoints = 100,
		modType = 1,
		conviction = "vessel",
		dedication = "mitigation"
	},
	{
		domain = 3,
		maxPoints = 75,
		conviction = "manaleech",
		dedication = "health"
	},
	{
		domain = 3,
		maxPoints = 50,
		conviction = "spell_1",
		dedication = "mana"
	},
	{
		domain = 4,
		maxPoints = 50,
		modType = 0,
		conviction = "vessel",
		dedication = "health"
	},
	{
		domain = 4,
		maxPoints = 75,
		conviction = "skill",
		dedication = "mitigation"
	},
	{
		domain = 4,
		maxPoints = 100,
		conviction = "spell_2",
		dedication = "capacity"
	},
	{
		domain = 3,
		maxPoints = 150,
		conviction = "lifeleech",
		dedication = "capacity"
	},
	{
		domain = 3,
		maxPoints = 100,
		conviction = "spell_3",
		dedication = "mitigation"
	},
	{
		domain = 3,
		maxPoints = 75,
		modType = 0,
		conviction = "vessel",
		dedication = "health"
	},
	{
		domain = 4,
		maxPoints = 75,
		conviction = "manaleech",
		dedication = "mitigation"
	},
	{
		domain = 4,
		maxPoints = 100,
		conviction = "spell_4",
		dedication = "capacity"
	},
	{
		domain = 4,
		maxPoints = 150,
		modType = 2,
		conviction = "vessel",
		dedication = "mana"
	},
	{
		domain = 3,
		maxPoints = 200,
		conviction = "spell_5",
		dedication = "lifemana"
	},
	{
		domain = 3,
		maxPoints = 150,
		modType = 2,
		conviction = "vessel",
		dedication = "capacity"
	},
	{
		domain = 3,
		maxPoints = 100,
		conviction = "skill",
		dedication = "mitigation"
	},
	{
		domain = 4,
		maxPoints = 100,
		modType = 1,
		conviction = "vessel",
		dedication = "capacity"
	},
	{
		domain = 4,
		maxPoints = 150,
		conviction = "lifeleech",
		dedication = "mana"
	},
	{
		domain = 4,
		maxPoints = 200,
		conviction = "special_2",
		dedication = "lifemana"
	}
}
WheelDomainOrder = {
	[0] = {
		15,
		14,
		9,
		13,
		8,
		3,
		7,
		2,
		1
	},
	{
		16,
		10,
		17,
		4,
		11,
		18,
		5,
		12,
		6
	},
	{
		21,
		20,
		27,
		19,
		26,
		33,
		25,
		32,
		31
	},
	{
		22,
		23,
		28,
		24,
		29,
		34,
		30,
		35,
		36
	}
}

local function firstSpellIsUnlocked(attribute)
	return WheelOfDestiny.isLitFull(attribute[1]) or WheelOfDestiny.isLitFull(attribute[2])
end

local function secondSpellIsUnlocked(attribute)
	return WheelOfDestiny.isLitFull(attribute[1]) and WheelOfDestiny.isLitFull(attribute[2])
end

function getDedicationBonus(index)
	local bonus = WheelBonus[index - 1]
	local vocation = WheelOfDestiny.vocationId
	local points = WheelOfDestiny.pointInvested[index]

	if not vocation or vocation == 0 then
		return
	end

	local attribute = WheelConsts[bonus.dedication]
	local vocationAttribute = 0

	if type(attribute) == "table" then
		vocationAttribute = attribute[vocation] or 0
	end

	if bonus.dedication == "capacity" then
		return string.format("+%d Capacity", points * vocationAttribute)
	elseif bonus.dedication == "mana" then
		return string.format("+%d Mana", points * vocationAttribute)
	elseif bonus.dedication == "health" then
		return string.format("+%d Hit Points", points * vocationAttribute)
	elseif bonus.dedication == "mitigation" then
		return string.format("%.2f%% Mitigation Multiplier", points * attribute)
	elseif bonus.dedication == "lifemana" then
		return string.format("+%d Hit Points\n+%d Mana", points * attribute.life[vocation], points * attribute.mana[vocation])
	end

	return ""
end

function getDedicationTooltip(index)
	local bonus = WheelBonus[index - 1]
	local vocation = WheelOfDestiny.vocationId
	local points = WheelOfDestiny.pointInvested[index]

	if not vocation or vocation == 0 then
		return ""
	end

	local attribute = WheelConsts[bonus.dedication]
	local vocationAttribute = 0

	if type(attribute) == "table" then
		vocationAttribute = attribute[vocation] or 0
	end

	if bonus.dedication == "capacity" then
		return string.format("Per promotion point:\n+%d Capacity", vocationAttribute)
	elseif bonus.dedication == "mana" then
		return string.format("Per promotion point:\n+%d Mana", vocationAttribute)
	elseif bonus.dedication == "health" then
		return string.format("Per promotion point:\n+%d Hit Points", vocationAttribute)
	elseif bonus.dedication == "mitigation" then
		return string.format("Increases your mitigation multiplicatively.\n\n%.2f%% Mitigation Multiplier", attribute)
	elseif bonus.dedication == "lifemana" then
		return string.format("Per promotion point:\n+%d Hit Points\n+%d Mana", attribute.life[vocation], attribute.mana[vocation])
	end

	return ""
end

function getConvictionBonusTooltip(index)
	local bonus = WheelBonus[index - 1]
	local vocation = WheelOfDestiny.vocationId
	local points = WheelOfDestiny.pointInvested[index]
	local attribute = WheelConsts[bonus.conviction]

	if bonus.conviction == "vessel" then
		local domain = bonus.domain

		if domain == 1 then
			return "Each level of Vessel Resonance unlocks equivalent Gem Mods in its\ndomain. If the Vessel Resonance matches the gem quality, a\ndamage and healing bonus is granted."
		elseif domain == 2 then
			return "Each level of Vessel Resonance unlocks equivalent Gem Mods in its\ndomain. If the Vessel Resonance matches the gem quality, a\ndamage and healing bonus is granted."
		elseif domain == 3 then
			return "Each level of Vessel Resonance unlocks equivalent Gem Mods in its\ndomain. If the Vessel Resonance matches the gem quality, a\ndamage and healing bonus is granted."
		elseif domain == 4 then
			return "Each level of Vessel Resonance unlocks equivalent Gem Mods in its\ndomain. If the Vessel Resonance matches the gem quality, a\ndamage and healing bonus is granted."
		end
	elseif bonus.conviction == "special_1" then
		if vocation == KNIGHT then
			return "Gain +6 shielding and +1 sword/axe/club fighting when 5\ncreatures are on adjacent squares.\nFor each additional creature, up to a maximum of 8, you get +6\nshielding and +1 sword/axe/club fighting more."
		elseif vocation == PALADIN then
			return "Gain +3 distance fighting while no monster is within 1 squares.\nOtherwise gain +3 holy magic level and +3 healing magic level."
		elseif vocation == SORCERER then
			return "If you use a rune, you have a 25% chance of increasing your magic\nlevel by 10%, or by 20% if you use a rune that can be created by\nyour vocation."
		elseif vocation == DRUID then
			return "If you heal someone with Nature's Embrace or Heal Friend, you\nalso heal yourself for 10% of the applied healing."
		elseif vocation == MONK then
			return "Gain an aura that shares 50% of your\nmantra with members of your group."
		end
	elseif bonus.conviction == "special_2" then
		if vocation == KNIGHT then
			return "For each creature challenged, you will heal yourself for a small\namount. This amount scales with your shielding skill. Heals for\ndouble the amount if you have less than 60% of your hit points and\ntriple the amount if you have less than 30% of your hit points."
		elseif vocation == PALADIN then
			return "The critical extra damage for attacks with a crossbow is increased\nby 10%. While wielding a bow your attacks and spells treat the\ntargets physical and holy sensitivity as being 2% higher."
		elseif vocation == SORCERER then
			return "Increases the damage of your next damage spell by 35% within 12\nseconds after casting a focus spell."
		elseif vocation == DRUID then
			return "If you use a rune, you have a 25% chance of increasing your magic\nlevel by 10%, or by 20% if you use a rune that can be created by\nyour vocation."
		elseif vocation == MONK then
			return "Consuming Harmony creates a field lasting 5 seconds, increasing\nyour damage and healing done by 2% for each Harmony\nconsumed."
		end
	elseif bonus.conviction == "spell_1" then
		if vocation == KNIGHT then
			return ""
		elseif vocation == PALADIN then
			local t = {}

			if not firstSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, " Enables the casting of support spells while active and Focus secondary group cooldown -8s\n", "#707070")

			if not secondSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, " -6s Cooldown; distance skill bonus increased by +5%", "#707070")

			return t
		end
	end

	return ""
end

function getConvictionBonus(index, fullMessage)
	local bonus = WheelBonus[index - 1]
	local vocation = WheelOfDestiny.vocationId
	local points = WheelOfDestiny.pointInvested[index]
	local attribute = WheelConsts[bonus.conviction]

	if bonus.conviction == "vessel" then
		local domain = bonus.domain

		if domain == 1 then
			if not fullMessage then
				return "Vessel Resonance Top Left\nEach level of Vessel\nResonance unlocks equivalent\nGem Mods in its domain. If the\nVessel Resonance matches t..."
			else
				return "Vessel Resonance Top Left\nEach level of Vessel\nResonance unlocks equivalent\nGem Mods in its domain. If the\nVessel Resonance matches\nthe gem quality, a damage\nand healing bonus is granted."
			end
		elseif domain == 2 then
			if not fullMessage then
				return "Vessel Resonance Top Right\nEach level of Vessel\nResonance unlocks equivalent\nGem Mods in its domain. If the\nVessel Resonance matches t..."
			else
				return "Vessel Resonance Top Right\nEach level of Vessel\nResonance unlocks equivalent\nGem Mods in its domain. If the\nVessel Resonance matches\nthe gem quality, a damage\nand healing bonus is granted."
			end
		elseif domain == 3 then
			if not fullMessage then
				return "Vessel Resonance Bottom Left\nEach level of Vessel\nResonance unlocks equivalent\nGem Mods in its domain. If the\nVessel Resonance matches t..."
			else
				return "Vessel Resonance Bottom Left\nEach level of Vessel\nResonance unlocks equivalent\nGem Mods in its domain. If the\nVessel Resonance matches\nthe gem quality, a damage\nand healing bonus is granted."
			end
		elseif domain == 4 then
			if not fullMessage then
				return "VR Bottom Right\nEach level of Vessel\nResonance unlocks equivalent\nGem Mods in its domain. If the\nVessel Resonance matches t..."
			else
				return "VR Bottom Right\nEach level of Vessel\nResonance unlocks equivalent\nGem Mods in its domain. If the\nVessel Resonance matches\nthe gem quality, a damage\nand healing bonus is granted."
			end
		end
	elseif bonus.conviction == "skill" then
		if vocation == KNIGHT then
			return string.format("+%d Weapon Skill Boost\nApplies to sword, axe and club\nfighting", attribute)
		elseif vocation == PALADIN then
			return string.format("+%d Distance Skill Boost", attribute)
		elseif vocation == SORCERER or vocation == DRUID then
			return string.format("+%d Magic Skill Boost", attribute)
		elseif vocation == MONK then
			return string.format("+%d Fist Fighting Skill Boost", attribute)
		end
	elseif bonus.conviction == "lifeleech" then
		return string.format("+%.2f%% Life Leech", attribute)
	elseif bonus.conviction == "manaleech" then
		return string.format("+%.2f%% Mana Leech", attribute)
	elseif bonus.conviction == "spell_1" then
		if vocation == KNIGHT then
			local t = {}

			setStringColor(t, "Augmented Front Sweep\n", points >= bonus.maxPoints and "#C0C0C0" or "#707070")

			if not firstSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": Adds 5% life leech to this\nspell\n", firstSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			if not secondSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": +14% Base Damage", secondSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			return t
		elseif vocation == PALADIN then
			local t = {}

			setStringColor(t, "Augmented Sharpshooter\n", points >= bonus.maxPoints and "#C0C0C0" or "#707070")

			if not firstSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": Enables the casting of\nsupport spells while activ...\n", firstSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			if not secondSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": -6s Cooldown; distance\nskill bonus increased by ...", secondSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			return t
		elseif vocation == SORCERER then
			local t = {}

			setStringColor(t, "Augmented Focus Spells\n", points >= bonus.maxPoints and "#C0C0C0" or "#707070")

			if not firstSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": +8% Base Damage for Hell's\nCore and Rage of the Skies\n", firstSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			if not secondSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": -4s Cooldown; Focus\nsecondary group cooldow...", secondSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			return t
		elseif vocation == DRUID then
			local t = {}

			setStringColor(t, "Augmented Forked Spells\n", points >= bonus.maxPoints and "#C0C0C0" or "#707070")

			if not firstSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": -2s Cooldown\n", firstSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			if not secondSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": Adds +1 target", secondSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			return t
		elseif vocation == MONK then
			local t = {}

			setStringColor(t, "Aug. Thousand Fist Blows\n", points >= bonus.maxPoints and "#C0C0C0" or "#707070")

			if not firstSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": Adds 3% mana leech to\nthis spell\n", firstSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			if not secondSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": Adds 25% critical extra\ndamage for this spell", secondSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			return t
		end
	elseif bonus.conviction == "spell_2" then
		if vocation == KNIGHT then
			local t = {}

			setStringColor(t, "Augmented Groundshaker\n", points >= bonus.maxPoints and "#C0C0C0" or "#707070")

			if not firstSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": +12.5% Base Damage\n", firstSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			if not secondSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": -2s Cooldown", secondSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			return t
		elseif vocation == PALADIN then
			local t = {}

			setStringColor(t, "Aug. Strong Ethereal Spear\n", points >= bonus.maxPoints and "#C0C0C0" or "#707070")

			if not firstSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": -2s Cooldown\n", firstSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			if not secondSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": +380% Base Damage", secondSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			return t
		elseif vocation == SORCERER then
			local t = {}

			setStringColor(t, "Augmented Death Echo\n", points >= bonus.maxPoints and "#C0C0C0" or "#707070")

			if not firstSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": Enhanced effect\n", firstSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			if not secondSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": -6s Cooldown", secondSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			return t
		elseif vocation == DRUID then
			local t = {}

			setStringColor(t, "Augmented Mass Healing\n", points >= bonus.maxPoints and "#C0C0C0" or "#707070")

			if not firstSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": +5% Base Healing\n", firstSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			if not secondSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": Affected area enlarged", secondSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			return t
		elseif vocation == MONK then
			local t = {}

			setStringColor(t, "Augmented Mass Spirit Mend\n", points >= bonus.maxPoints and "#C0C0C0" or "#707070")

			if not firstSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": +8% Base Healing\n", firstSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			if not secondSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": Affected area enlarged", secondSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			return t
		end
	elseif bonus.conviction == "spell_3" then
		if vocation == KNIGHT then
			local t = {}

			setStringColor(t, "Augmented Shield Slam\n", points >= bonus.maxPoints and "#C0C0C0" or "#707070")

			if not firstSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": +15% Life Leech\n", firstSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			if not secondSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": +25% Damage Reduction\n(75% total)", secondSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			return t
		elseif vocation == PALADIN then
			local t = {}

			setStringColor(t, "Augmented Divine Dazzle\n", points >= bonus.maxPoints and "#C0C0C0" or "#707070")

			if not firstSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": Jumps to +1 additional\ntarget\n", firstSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			if not secondSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": Duration increased; -4s\nCooldown", secondSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			return t
		elseif vocation == SORCERER then
			local t = {}

			setStringColor(t, "Augmented Special Spells\n", points >= bonus.maxPoints and "#C0C0C0" or "#707070")

			if not firstSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": Affected area enlarged\n", firstSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			if not secondSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": Damage reduction\nincreased", secondSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			return t
		elseif vocation == DRUID then
			local t = {}

			setStringColor(t, "Augmented Heal Friend\n", points >= bonus.maxPoints and "#C0C0C0" or "#707070")

			if not firstSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": -10 Mana Cost\n", firstSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			if not secondSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": +5% Base Healing", secondSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			return t
		elseif vocation == MONK then
			local t = {}

			setStringColor(t, "Augmented Mystic Repulse\n", points >= bonus.maxPoints and "#C0C0C0" or "#707070")

			if not firstSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": -4s Cooldown\n", firstSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			if not secondSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": +40% Base Damage", secondSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			return t
		end
	elseif bonus.conviction == "spell_4" then
		if vocation == KNIGHT then
			local t = {}

			setStringColor(t, "Aug. Intense Wound Cleansing\n", points >= bonus.maxPoints and "#C0C0C0" or "#707070")

			if not firstSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": +125% Base Healing\n", firstSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			if not secondSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": -300s Cooldown", secondSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			return t
		elseif vocation == PALADIN then
			local t = {}

			setStringColor(t, "Augmented Swift Foot\n", points >= bonus.maxPoints and "#C0C0C0" or "#707070")

			if not firstSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": Focus secondary group\ncooldown -8s. Attacks an...\n", firstSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			if not secondSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": -6s Cooldown and the\ndamage dealt is no longe...", secondSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			return t
		elseif vocation == SORCERER then
			local t = {}

			setStringColor(t, "Augmented Energy Wave\n", points >= bonus.maxPoints and "#C0C0C0" or "#707070")

			if not firstSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": +5% Base Damage\n", firstSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			if not secondSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": Affected area enlarged", secondSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			return t
		elseif vocation == DRUID then
			local t = {}

			setStringColor(t, "Augmented Terra Wave\n", points >= bonus.maxPoints and "#C0C0C0" or "#707070")

			if not firstSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": +5% Base Damage\n", firstSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			if not secondSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": Adds 5% life leech to this\nspell", secondSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			return t
		elseif vocation == MONK then
			local t = {}

			setStringColor(t, "Aug. Chained Penance\n", points >= bonus.maxPoints and "#C0C0C0" or "#707070")

			if not firstSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": Jumps to +1 additional\ntarget\n", firstSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			if not secondSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": Jumps to +1 additional\ntarget", secondSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			return t
		end
	elseif bonus.conviction == "spell_5" then
		if vocation == KNIGHT then
			local t = {}

			setStringColor(t, "Augmented Fierce Berserk\n", points >= bonus.maxPoints and "#C0C0C0" or "#707070")

			if not firstSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": -30 Mana Cost\n", firstSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			if not secondSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": +10% Base Damage", secondSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			return t
		elseif vocation == PALADIN then
			local t = {}

			setStringColor(t, "Augmented Divine Caldera\n", points >= bonus.maxPoints and "#C0C0C0" or "#707070")

			if not firstSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": -20 Mana Cost\n", firstSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			if not secondSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": +8.5% Base Damage", secondSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			return t
		elseif vocation == SORCERER then
			local t = {}

			setStringColor(t, "Augmented Great Fire Wave\n", points >= bonus.maxPoints and "#C0C0C0" or "#707070")

			if not firstSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": Adds 15% critical extra\ndamage for this spell and...\n", firstSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			if not secondSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": +5% Base Damage", secondSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			return t
		elseif vocation == DRUID then
			local t = {}

			setStringColor(t, "Augmented Strong Ice Wave\n", points >= bonus.maxPoints and "#C0C0C0" or "#707070")

			if not firstSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": +6% Base Damage\n", firstSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			if not secondSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": Affected area enlarged", secondSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			return t
		elseif vocation == MONK then
			local t = {}

			setStringColor(t, "Aug. Flurry of Blows\n", points >= bonus.maxPoints and "#C0C0C0" or "#707070")

			if not firstSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": Adds 5% life leech to this\nspell\n", firstSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			if not secondSpellIsUnlocked(attribute) then
				setStringColor(t, "�", "white")
			else
				setStringColor(t, "�", "white")
			end

			setStringColor(t, ": +12% Base Damage", secondSpellIsUnlocked(attribute) and "#C0C0C0" or "#707070")

			return t
		end
	elseif bonus.conviction == "special_1" then
		if vocation == KNIGHT then
			if not fullMessage then
				return "Battle Instinct\nGain +6 shielding and +1\nsword/axe/club fighting when\n5 creatures are on adjacent\nsquares..."
			else
				return "Battle Instinct\nGain +6 shielding and +1\nsword/axe/club fighting when\n5 creatures are on adjacent\nsquares.\nFor each additional creature,\nup to a maximum of 8, you get\n+6 shielding and +1 sword/\naxe/club fighting more."
			end
		elseif vocation == PALADIN then
			if not fullMessage then
				return "Ballistic Mastery\nGain +3 distance fighting\nwhile no monster is within 1\nsquares. Otherwise gain +3\nholy magic level and +3 hea..."
			else
				return "Ballistic Mastery\nGain +3 distance fighting\nwhile no monster is within 1\nsquares. Otherwise gain +3\nholy magic level and +3\nhealing magic level."
			end
		elseif vocation == SORCERER then
			if not fullMessage then
				return "Runic Mastery\nIf you use a rune, you have a\n25% chance of increasing\nyour magic level by 10%, or\nby 20% if you use a rune th..."
			else
				return "Runic Mastery\nIf you use a rune, you have a\n25% chance of increasing\nyour magic level by 10%, or\nby 20% if you use a rune that\ncan be created by your\nvocation."
			end
		elseif vocation == DRUID then
			if not fullMessage then
				return "Healing Link\nIf you heal someone with\nNature's Embrace or Heal\nFriend, you also heal yourself\nfor 10% of the applied heali..."
			else
				return "Healing Link\nIf you heal someone with\nNature's Embrace or Heal\nFriend, you also heal yourself\nfor 10% of the applied\nhealing."
			end
		elseif vocation == MONK then
			if not fullMessage then
				return "Guiding Presence\nGain an aura that shares 50% of your\nmantra with members of your\ngroup."
			else
				return "Guiding Presence\nGain an aura that shares 50% of your\nmantra with members of your\ngroup."
			end
		end
	elseif bonus.conviction == "special_2" then
		if vocation == KNIGHT then
			if not fullMessage then
				return "Battle Healing\nFor each creature challenged,\nyou will heal yourself for a\nsmall amount. This amount\nscales with your shielding s..."
			else
				return "Battle Healing\nFor each creature challenged,\nyou will heal yourself for a\nsmall amount. This amount\nscales with your shielding\nskill. Heals for double the\namount if you have less than\n60% of your hit points and\ntriple the amount if you hav..."
			end
		elseif vocation == PALADIN then
			if not fullMessage then
				return "Ballistic Mastery\nThe critical extra damage for\nattacks with a crossbow is\nincreased by 10%.\nWhile wielding a bow your a..."
			else
				return "Ballistic Mastery\nThe critical extra damage for\nattacks with a crossbow is\nincreased by 10%.\nWhile wielding a bow your\nattacks and spells treat the\ntargets physical and holy\nsensitivity as being 2%\nhigher."
			end
		elseif vocation == SORCERER then
			return "Focus Mastery\nIncreases the damage of your\nnext damage spell by 35%\nwithin 12 seconds after\ncasting a focus spell."
		elseif vocation == DRUID then
			if not fullMessage then
				return "Runic Mastery\nIf you use a rune, you have a\n25% chance of increasing\nyour magic level by 10%, or\nby 20% if you use a rune th..."
			else
				return "Runic Mastery\nIf you use a rune, you have a\n25% chance of increasing\nyour magic level by 10%, or\nby 20% if you use a rune that\ncan be created by your\nvocation."
			end
		elseif vocation == MONK then
			if not fullMessage then
				return "Sanctuary\nConsuming Harmony creates\na field lasting 5 seconds,\nincreasing damage and..."
			else
				return "Sanctuary\nConsuming Harmony creates\na field lasting 5 seconds,\nincreasing your damage and\nhealing done by 2% for each\nHarmony consumed."
			end
		end
	end

	return ""
end

function getConvictionPerks()
	local convictions = {}
	local vocation = WheelOfDestiny.vocationId
	local order = {
		special_4 = 4,
		special_3 = 3,
		special_2 = 2,
		spell_5 = 12,
		spell_4 = 11,
		spell_3 = 10,
		special_1 = 1,
		spell_2 = 9,
		spell_1 = 8,
		skill = 5,
		["vessel.4"] = 16,
		lifeleech = 6,
		manaleech = 7,
		["vessel.3"] = 15,
		["vessel.2"] = 14,
		["vessel.1"] = 13
	}

	for id, bonus in pairs(WheelBonus) do
		local index = id + 1

		if not WheelOfDestiny.isLit(index) then
			-- block empty
		else
			local t = order[bonus.conviction] or table.size(order) + 1
			local attribute = WheelConsts[bonus.conviction]
			local pointsInvested = WheelOfDestiny.pointInvested[index] or 0

			if pointsInvested ~= bonus.maxPoints then
				-- block empty
			elseif bonus.conviction == "special_1" then
				convictions[t] = {
					perk = attribute[vocation][1],
					tooltip = attribute[vocation][2]
				}
			elseif bonus.conviction == "special_2" then
				convictions[t] = {
					perk = attribute[vocation][1],
					tooltip = attribute[vocation][2]
				}
			elseif bonus.conviction == "special_3" then
				if vocation == MONK then
					convictions[t] = {
						perk = attribute[vocation][1],
						tooltip = attribute[vocation][2]
					}
				end
			elseif bonus.conviction == "special_4" then
				if vocation == MONK then
					convictions[t] = {
						perk = attribute[vocation][1],
						tooltip = attribute[vocation][2]
					}
				end
			elseif bonus.conviction == "manaleech" then
				if not convictions[t] then
					convictions[t] = {
						points = 0,
						perk = "Mana Leech",
						stringPoint = ""
					}
				end

				convictions[t].points = convictions[t].points + attribute
				convictions[t].stringPoint = string.format("+%.2f%%", convictions[t].points)
			elseif bonus.conviction == "lifeleech" then
				if not convictions[t] then
					convictions[t] = {
						points = 0,
						perk = "Life Leech",
						stringPoint = ""
					}
				end

				convictions[t].points = convictions[t].points + attribute
				convictions[t].stringPoint = string.format("+%.2f%%", convictions[t].points)
			elseif bonus.conviction == "vessel" then
				t = "vessel." .. bonus.domain
				t = order[t]

				if bonus.domain == 1 then
					if not convictions[t] then
						convictions[t] = {
							points = 0,
							perk = "VR Top Left",
							stringPoint = "I"
						}
					end

					convictions[t].points = convictions[t].points + 1

					if convictions[t].points == 1 then
						convictions[t].stringPoint = "I"
					elseif convictions[t].points == 2 then
						convictions[t].stringPoint = "II"
					else
						convictions[t].stringPoint = "III"
					end
				elseif bonus.domain == 2 then
					if not convictions[t] then
						convictions[t] = {
							points = 0,
							perk = "VR Top Right",
							stringPoint = "I"
						}
					end

					convictions[t].points = convictions[t].points + 1

					if convictions[t].points == 1 then
						convictions[t].stringPoint = "I"
					elseif convictions[t].points == 2 then
						convictions[t].stringPoint = "II"
					else
						convictions[t].stringPoint = "III"
					end
				elseif bonus.domain == 3 then
					if not convictions[t] then
						convictions[t] = {
							points = 0,
							perk = "VR Bottom Left",
							stringPoint = "I"
						}
					end

					convictions[t].points = convictions[t].points + 1

					if convictions[t].points == 1 then
						convictions[t].stringPoint = "I"
					elseif convictions[t].points == 2 then
						convictions[t].stringPoint = "II"
					else
						convictions[t].stringPoint = "III"
					end
				else
					if not convictions[t] then
						convictions[t] = {
							points = 0,
							perk = "VR Bottom Right",
							stringPoint = "I"
						}
					end

					convictions[t].points = convictions[t].points + 1

					if convictions[t].points == 1 then
						convictions[t].stringPoint = "I"
					elseif convictions[t].points == 2 then
						convictions[t].stringPoint = "II"
					else
						convictions[t].stringPoint = "III"
					end
				end

				convictions[t].tooltip = "Each level of Vessel Resonance unlocks equivalent Gem Mods in its\ndomain. If the Vessel Resonance matches the gem quality, a\ndamage and healing bonus is granted."
			elseif bonus.conviction == "skill" then
				if not convictions[t] then
					convictions[t] = {
						points = 0,
						perk = "",
						stringPoint = ""
					}
				end

				if vocation == KNIGHT then
					convictions[t].perk = "Weapon Skill Boost"
					convictions[t].points = convictions[t].points + attribute
					convictions[t].stringPoint = string.format("+%d", convictions[t].points)
					convictions[t].tooltip = "Applies to sword, axe and club fighting"
				elseif vocation == PALADIN then
					convictions[t].perk = "Distance Skill Boost"
					convictions[t].points = convictions[t].points + attribute
					convictions[t].stringPoint = string.format("+%d", convictions[t].points)
				elseif vocation == SORCERER or vocation == DRUID then
					convictions[t].perk = "Magic Skill Boost"
					convictions[t].points = convictions[t].points + attribute
					convictions[t].stringPoint = string.format("+%.2f%%", convictions[t].points)
				elseif vocation == MONK then
					convictions[t].perk = "Fist Fighting Skill Boost"
					convictions[t].points = convictions[t].points + attribute
					convictions[t].stringPoint = string.format("+%d", convictions[t].points)
				end
			elseif bonus.conviction == "spell_1" then
				if vocation == KNIGHT then
					if not convictions[t] then
						convictions[t] = {
							points = 0,
							perk = "Aug. Front Sweep",
							stringPoint = ""
						}
					end

					convictions[t].points = convictions[t].points + 1

					if convictions[t].points == 1 then
						convictions[t].stringPoint = "I"
					else
						convictions[t].stringPoint = "II"
					end

					local message = {}

					if not firstSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "Adds 5% life leech to this spell\n", "#3F3F3F")

					if not secondSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "+8% Base Damage", "#3f3f3f")

					convictions[t].tooltip = message
				elseif vocation == PALADIN then
					if not convictions[t] then
						convictions[t] = {
							points = 0,
							perk = "Aug. Sharpshooter",
							stringPoint = ""
						}
					end

					convictions[t].points = convictions[t].points + 1

					if convictions[t].points == 1 then
						convictions[t].stringPoint = "I"
					else
						convictions[t].stringPoint = "II"
					end

					local message = {}

					if not firstSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "Enables the casting of support spells while active and Focus\nsecondary group cooldown -8s\n", "#3F3F3F")

					if not secondSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "-6s Cooldown; distance skill bonus increased by +5%", "#3F3F3F")

					convictions[t].tooltip = message
				elseif vocation == SORCERER then
					if not convictions[t] then
						convictions[t] = {
							points = 0,
							perk = "Aug. Focus Spells",
							stringPoint = ""
						}
					end

					convictions[t].points = convictions[t].points + 1

					if convictions[t].points == 1 then
						convictions[t].stringPoint = "I"
					else
						convictions[t].stringPoint = "II"
					end

					local message = {}

					if not firstSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "+8% Base Damage for Hell's Core and Rage of the Skies\n", "#3F3F3F")

					if not secondSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "-4s Cooldown; Focus secondary group cooldown -4s for Hell's\nCore and Rage of the Skies", "#3F3F3F")

					convictions[t].tooltip = message
				elseif vocation == DRUID then
					if not convictions[t] then
						convictions[t] = {
							points = 0,
							perk = "Aug. Forked Spells",
							stringPoint = ""
						}
					end

					convictions[t].points = convictions[t].points + 1

					if convictions[t].points == 1 then
						convictions[t].stringPoint = "I"
					else
						convictions[t].stringPoint = "II"
					end

					local message = {}

					if not firstSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "-2s Cooldown\n", "#3F3F3F")

					if not secondSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "Adds +1 target", "#3F3F3F")

					convictions[t].tooltip = message
				elseif vocation == MONK then
					if not convictions[t] then
						convictions[t] = {
							points = 0,
							perk = "Aug. Thousand Fist Blows",
							stringPoint = ""
						}
					end

					convictions[t].points = convictions[t].points + 1

					if convictions[t].points == 1 then
						convictions[t].stringPoint = "I"
					else
						convictions[t].stringPoint = "II"
					end

					local message = {}

					if not firstSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "Adds 3% mana leech to this spell\n", "#3F3F3F")

					if not secondSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "Adds 25% critical extra damage", "#3F3F3F")

					convictions[t].tooltip = message
				end
			elseif bonus.conviction == "spell_2" then
				if vocation == KNIGHT then
					if not convictions[t] then
						convictions[t] = {
							points = 0,
							perk = "Aug. Groundshaker",
							stringPoint = ""
						}
					end

					convictions[t].points = convictions[t].points + 1

					if convictions[t].points == 1 then
						convictions[t].stringPoint = "I"
					else
						convictions[t].stringPoint = "II"
					end

					local message = {}

					if not firstSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "+12.5% Base Damage\n", "#3F3F3F")

					if not secondSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "-2s Cooldown", "#3F3F3F")

					convictions[t].tooltip = message
				elseif vocation == PALADIN then
					if not convictions[t] then
						convictions[t] = {
							points = 0,
							perk = "Aug. Strong Ethereal Spear",
							stringPoint = ""
						}
					end

					convictions[t].points = convictions[t].points + 1

					if convictions[t].points == 1 then
						convictions[t].stringPoint = "I"
					else
						convictions[t].stringPoint = "II"
					end

					local message = {}

					if not firstSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "-2s Cooldown\n", "#3F3F3F")

					if not secondSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "+8% Base Damage", "#3F3F3F")

					convictions[t].tooltip = message
				elseif vocation == SORCERER then
					if not convictions[t] then
						convictions[t] = {
							points = 0,
							perk = "Aug. Death Echo",
							stringPoint = ""
						}
					end

					convictions[t].points = convictions[t].points + 1

					if convictions[t].points == 1 then
						convictions[t].stringPoint = "I"
					else
						convictions[t].stringPoint = "II"
					end

					local message = {}

					if not firstSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "Enhanced effect\n", "#3F3F3F")

					if not secondSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "-6s Cooldown", "#3F3F3F")

					convictions[t].tooltip = message
				elseif vocation == DRUID then
					if not convictions[t] then
						convictions[t] = {
							points = 0,
							perk = "Aug. Mass Healing",
							stringPoint = ""
						}
					end

					convictions[t].points = convictions[t].points + 1

					if convictions[t].points == 1 then
						convictions[t].stringPoint = "I"
					else
						convictions[t].stringPoint = "II"
					end

					local message = {}

					if not firstSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "+5% Base Healing\n", "#3F3F3F")

					if not secondSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "Affected area enlarged", "#3F3F3F")

					convictions[t].tooltip = message
				elseif vocation == MONK then
					if not convictions[t] then
						convictions[t] = {
							points = 0,
							perk = "Aug. Mass Spirit Mend",
							stringPoint = ""
						}
					end

					convictions[t].points = convictions[t].points + 1

					if convictions[t].points == 1 then
						convictions[t].stringPoint = "I"
					else
						convictions[t].stringPoint = "II"
					end

					local message = {}

					if not firstSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "+8% Base Healing\n", "#3F3F3F")

					if not secondSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "Affected area enlarged", "#3F3F3F")

					convictions[t].tooltip = message
				end
			elseif bonus.conviction == "spell_3" then
				if vocation == KNIGHT then
					if not convictions[t] then
						convictions[t] = {
							points = 0,
							perk = "Aug. Shield Slam",
							stringPoint = ""
						}
					end

					convictions[t].points = convictions[t].points + 1

					if convictions[t].points == 1 then
						convictions[t].stringPoint = "I"
					else
						convictions[t].stringPoint = "II"
					end

					local message = {}

					if not firstSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "+15% Life Leech\n", "#3F3F3F")

					if not secondSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "+25% Damage Reduction (75% total)", "#3F3F3F")

					convictions[t].tooltip = message
				elseif vocation == PALADIN then
					if not convictions[t] then
						convictions[t] = {
							points = 0,
							perk = "Aug. Divine Dazzle",
							stringPoint = ""
						}
					end

					convictions[t].points = convictions[t].points + 1

					if convictions[t].points == 1 then
						convictions[t].stringPoint = "I"
					else
						convictions[t].stringPoint = "II"
					end

					local message = {}

					if not firstSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "Jumps to +1 additional target\n", "#3F3F3F")

					if not secondSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "Duration increased; -4s Cooldown", "#3F3F3F")

					convictions[t].tooltip = message
				elseif vocation == SORCERER then
					if not convictions[t] then
						convictions[t] = {
							points = 0,
							perk = "Aug. Special Spells",
							stringPoint = ""
						}
					end

					convictions[t].points = convictions[t].points + 1

					if convictions[t].points == 1 then
						convictions[t].stringPoint = "I"
					else
						convictions[t].stringPoint = "II"
					end

					local message = {}

					if not firstSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "Affected area enlarged\n", "#3F3F3F")

					if not secondSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "Damage reduction increased by +1%", "#3F3F3F")

					convictions[t].tooltip = message
				elseif vocation == DRUID then
					if not convictions[t] then
						convictions[t] = {
							points = 0,
							perk = "Aug. Heal Friend",
							stringPoint = ""
						}
					end

					convictions[t].points = convictions[t].points + 1

					if convictions[t].points == 1 then
						convictions[t].stringPoint = "I"
					else
						convictions[t].stringPoint = "II"
					end

					local message = {}

					if not firstSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "-10 Mana Cost\n", "#3F3F3F")

					if not secondSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "+5% Base Healing", "#3F3F3F")

					convictions[t].tooltip = message
				elseif vocation == MONK then
					if not convictions[t] then
						convictions[t] = {
							points = 0,
							perk = "Aug. Mystic Repulse",
							stringPoint = ""
						}
					end

					convictions[t].points = convictions[t].points + 1

					if convictions[t].points == 1 then
						convictions[t].stringPoint = "I"
					else
						convictions[t].stringPoint = "II"
					end

					local message = {}

					if not firstSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "-4s Cooldown\n", "#3F3F3F")

					if not secondSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "+40% Base Damage", "#3F3F3F")

					convictions[t].tooltip = message
				end
			elseif bonus.conviction == "spell_4" then
				if vocation == KNIGHT then
					if not convictions[t] then
						convictions[t] = {
							points = 0,
							perk = "Aug. Intense Wound C...",
							stringPoint = ""
						}
					end

					convictions[t].points = convictions[t].points + 1

					if convictions[t].points == 1 then
						convictions[t].stringPoint = "I"
					else
						convictions[t].stringPoint = "II"
					end

					local message = {}

					if not firstSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "+10% Base Healing\n", "#3F3F3F")

					if not secondSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "-300s Cooldown", "#3F3F3F")

					convictions[t].tooltip = message
				elseif vocation == PALADIN then
					if not convictions[t] then
						convictions[t] = {
							points = 0,
							perk = "Aug. Swift Foot",
							stringPoint = ""
						}
					end

					convictions[t].points = convictions[t].points + 1

					if convictions[t].points == 1 then
						convictions[t].stringPoint = "I"
					else
						convictions[t].stringPoint = "II"
					end

					local message = {}

					if not firstSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "Focus secondary group cooldown -8s. Attacks and spells are\nenabled but dealt damage is reduced by 50%.\n", "#3F3F3F")

					if not secondSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "-6s Cooldown and the damage dealt is no longer reduced.", "#3F3F3F")

					convictions[t].tooltip = message
				elseif vocation == SORCERER then
					if not convictions[t] then
						convictions[t] = {
							points = 0,
							perk = "Aug. Energy Wave",
							stringPoint = ""
						}
					end

					convictions[t].points = convictions[t].points + 1

					if convictions[t].points == 1 then
						convictions[t].stringPoint = "I"
					else
						convictions[t].stringPoint = "II"
					end

					local message = {}

					if not firstSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "+5% Base Damage\n", "#3F3F3F")

					if not secondSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "Affected area enlarged", "#3F3F3F")

					convictions[t].tooltip = message
				elseif vocation == DRUID then
					if not convictions[t] then
						convictions[t] = {
							points = 0,
							perk = "Aug. Terra Wave",
							stringPoint = ""
						}
					end

					convictions[t].points = convictions[t].points + 1

					if convictions[t].points == 1 then
						convictions[t].stringPoint = "I"
					else
						convictions[t].stringPoint = "II"
					end

					local message = {}

					if not firstSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "+5% Base Damage\n", "#3F3F3F")

					if not secondSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "Adds 5% life leech to this spell", "#3F3F3F")

					convictions[t].tooltip = message
				elseif vocation == MONK then
					if not convictions[t] then
						convictions[t] = {
							points = 0,
							perk = "Aug. Chained Penance",
							stringPoint = ""
						}
					end

					convictions[t].points = convictions[t].points + 1

					if convictions[t].points == 1 then
						convictions[t].stringPoint = "I"
					else
						convictions[t].stringPoint = "II"
					end

					local message = {}

					if not firstSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "Jumps to +1 additional target\n", "#3F3F3F")

					if not secondSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "Jumps to +1 additional target", "#3F3F3F")

					convictions[t].tooltip = message
				end
			elseif bonus.conviction == "spell_5" then
				if vocation == KNIGHT then
					if not convictions[t] then
						convictions[t] = {
							points = 0,
							perk = "Aug. Fierce Berserk",
							stringPoint = ""
						}
					end

					convictions[t].points = convictions[t].points + 1

					if convictions[t].points == 1 then
						convictions[t].stringPoint = "I"
					else
						convictions[t].stringPoint = "II"
					end

					local message = {}

					if not firstSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "-30 Mana Cost\n", "#3F3F3F")

					if not secondSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "+10% Base Damage", "#3F3F3F")

					convictions[t].tooltip = message
				elseif vocation == PALADIN then
					if not convictions[t] then
						convictions[t] = {
							points = 0,
							perk = "Aug. Divine Caldera",
							stringPoint = ""
						}
					end

					convictions[t].points = convictions[t].points + 1

					if convictions[t].points == 1 then
						convictions[t].stringPoint = "I"
					else
						convictions[t].stringPoint = "II"
					end

					local message = {}

					if not firstSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "-20 Mana Cost\n", "#3F3F3F")

					if not secondSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "+8.5% Base Damage", "#3F3F3F")

					convictions[t].tooltip = message
				elseif vocation == SORCERER then
					if not convictions[t] then
						convictions[t] = {
							points = 0,
							perk = "Aug. Great Fire Wave",
							stringPoint = ""
						}
					end

					convictions[t].points = convictions[t].points + 1

					if convictions[t].points == 1 then
						convictions[t].stringPoint = "I"
					else
						convictions[t].stringPoint = "II"
					end

					local message = {}

					if not firstSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "Adds 15% critical extra damage for this spell and grants a 10%\nchance (non-cumulative) for a critical hit.\n", "#3F3F3F")

					if not secondSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "+5% Base Damage", "#3F3F3F")

					convictions[t].tooltip = message
				elseif vocation == DRUID then
					if not convictions[t] then
						convictions[t] = {
							points = 0,
							perk = "Aug. Strong Ice Wave",
							stringPoint = ""
						}
					end

					convictions[t].points = convictions[t].points + 1

					if convictions[t].points == 1 then
						convictions[t].stringPoint = "I"
					else
						convictions[t].stringPoint = "II"
					end

					local message = {}

					if not firstSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "+6% Base Damage\n", "#3F3F3F")

					if not secondSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "Affected area enlarged", "#3F3F3F")

					convictions[t].tooltip = message
				elseif vocation == MONK then
					if not convictions[t] then
						convictions[t] = {
							points = 0,
							perk = "Aug. Flurry of Blows",
							stringPoint = ""
						}
					end

					convictions[t].points = convictions[t].points + 1

					if convictions[t].points == 1 then
						convictions[t].stringPoint = "I"
					else
						convictions[t].stringPoint = "II"
					end

					local message = {}

					if not firstSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "Adds 5% life leech to this spell\n", "#3F3F3F")

					if not secondSpellIsUnlocked(attribute) then
						setStringColor(message, "�", "white")
					else
						setStringColor(message, "�", "white")
					end

					setStringColor(message, "+12% Base Damage", "#3F3F3F")

					convictions[t].tooltip = message
				end
			end
		end
	end

	return convictions
end

function getPassiveInfo(domain)
	local extraPoints = WheelOfDestiny.extraPassivePoints[domain] or 0
	local passive = WheelOfDestiny.passivePoints[domain] + extraPoints
	local message = {}

	local function currentUnlocked(i)
		if passive >= 1000 and i == 3 then
			return true
		elseif passive >= 500 and passive < 1000 and i == 2 then
			return true
		elseif passive >= 250 and passive < 500 and i == 1 then
			return true
		else
			return false
		end
	end

	local m1 = ""
	local m2 = ""
	local vocation = WheelOfDestiny.vocationId

	if domain == 1 then
		setStringColor(message, "If an attack (except with agony damage) were to kill you but the\noverkill damage amounts to less than ", "#3F3F3F")
		setStringColor(message, "20%", currentUnlocked(1) and "#ffffff" or "#3F3F3F")
		setStringColor(message, "/", "#3F3F3F")
		setStringColor(message, "25%", currentUnlocked(2) and "#ffffff" or "#3F3F3F")
		setStringColor(message, "/", "#3F3F3F")
		setStringColor(message, "30% ", currentUnlocked(3) and "#ffffff" or "#3F3F3F")
		setStringColor(message, "of your\nmaximum hit points, you will heal yourself for ", "#3F3F3F")
		setStringColor(message, "20%", currentUnlocked(1) and "#ffffff" or "#3F3F3F")
		setStringColor(message, "/", "#3F3F3F")
		setStringColor(message, "25%", currentUnlocked(2) and "#ffffff" or "#3F3F3F")
		setStringColor(message, "/", "#3F3F3F")
		setStringColor(message, "30% ", currentUnlocked(3) and "#ffffff" or "#3F3F3F")
		setStringColor(message, " of\nyour maximum hit points. Only after that is the damage applied.\nIn addition, all your spell cooldowns are reduced by 60 seconds.\n\nCooldown: ", "#3F3F3F")
		setStringColor(message, "30h", currentUnlocked(1) and "#ffffff" or "#3F3F3F")
		setStringColor(message, "/", "#3F3F3F")
		setStringColor(message, "20h", currentUnlocked(2) and "#ffffff" or "#3F3F3F")
		setStringColor(message, "/", "#3F3F3F")
		setStringColor(message, "10h ", currentUnlocked(3) and "#ffffff" or "#3F3F3F")

		m1 = "Gift of Life\nAllows you to survive an\notherwise fatal blow."
		m2 = message
	elseif domain == 2 then
		if vocation == KNIGHT then
			m1 = "Executioner's Throw\nThrowing attack that deals\nmassive damage to enemies\nwith low hit points."

			setStringColor(message, "This spell throws your weapon on your target and jumps on ", "#3F3F3F")
			setStringColor(message, "2", currentUnlocked(1) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "3", currentUnlocked(2) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "4\n ", currentUnlocked(3) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "nearby enemies. Deals ", "#3F3F3F")
			setStringColor(message, "100%", currentUnlocked(1) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "125%", currentUnlocked(2) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "150%  ", currentUnlocked(3) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "additional damage to\ntargets with less than 30% of their hit points.\nCooldown: ", "#3F3F3F")
			setStringColor(message, "18", currentUnlocked(1) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "14", currentUnlocked(2) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "10", currentUnlocked(3) and "#ffffff" or "#3F3F3F")
			setStringColor(message, " seconds", "#3F3F3F")

			m2 = message
		elseif vocation == PALADIN then
			setStringColor(message, "This spell plants a marker at the feet of your target that explodes\nafter 3 seconds, dealing holy damage. +16% Base Damage with\nhigher spell stages.\n\nCooldown: ", "#3F3F3F")
			setStringColor(message, "26", currentUnlocked(1) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "20", currentUnlocked(2) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "14", currentUnlocked(3) and "#ffffff" or "#3F3F3F")
			setStringColor(message, " seconds", "#3F3F3F")

			m1 = "Divine Grenade\nDeploy a powerful delayed\neffect that deals holy damage."
			m2 = message
		elseif vocation == SORCERER then
			setStringColor(message, "This beam spell deals death damage. Damage and length increase\nwith higher spell stages.\nCooldown: ", "#3F3F3F")
			setStringColor(message, "10", currentUnlocked(1) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "8", currentUnlocked(2) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "6", currentUnlocked(3) and "#ffffff" or "#3F3F3F")
			setStringColor(message, " seconds\n\nIn addition, for each target hit by a beam spell, the cooldown of all\nother spells is reduced by 1 sec (up to a maximum of 3 sec) and\nthe damage of beam spells is increased by ", "#3F3F3F")
			setStringColor(message, "10%", currentUnlocked(1) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "12%", currentUnlocked(2) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "14%", currentUnlocked(3) and "#ffffff" or "#3F3F3F")
			setStringColor(message, " (up to\na maximum of ", "#3F3F3F")
			setStringColor(message, "30%", currentUnlocked(1) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "36%", currentUnlocked(2) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "42%", currentUnlocked(3) and "#ffffff" or "#3F3F3F")
			setStringColor(message, ").", "#3F3F3F")

			m1 = "Beam Mastery\nBoosts all of your beam spells\nand unlocks a beam spell that\ndeals death damage."
			m2 = message
		elseif vocation == DRUID then
			setStringColor(message, "You healing is increased by\n", "#3F3F3F")
			setStringColor(message, "6%", currentUnlocked(1) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "9%", currentUnlocked(2) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "12%", currentUnlocked(3) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "if the target has less\nthan 60% but more than 30% of\ntheir hit points.\n", "#3F3F3F")
			setStringColor(message, "You healing is increased by\n", "#3F3F3F")
			setStringColor(message, "12%", currentUnlocked(1) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "18%", currentUnlocked(2) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "24%", currentUnlocked(3) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "if the target has less\nthan 30% of their hit points.", "#3F3F3F")

			m1 = "Blessing of the Grove\nIncreases your healing if the target's\nmissing hit points is below certain \nthresholds."
			m2 = message
		elseif vocation == MONK then
			setStringColor(message, "This spell consumes your Harmony. Releases a massive attack\nchaining to ", "#3F3F3F")
			setStringColor(message, "7", currentUnlocked(3) and "#ffffff" or "#3F3F3F")
			setStringColor(message, " additional enemies. When used with full Harmony,\n", "#3F3F3F")
			setStringColor(message, "repeats after 1 second for ", "#3F3F3F")
			setStringColor(message, "37.5%", currentUnlocked(1) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "50%", currentUnlocked(2) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "62.5%", currentUnlocked(3) and "#ffffff" or "#3F3F3F")
			setStringColor(message, " of its original\ndamage. Cooldown: ", "#3F3F3F")
			setStringColor(message, "24", currentUnlocked(1) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "20", currentUnlocked(2) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "16", currentUnlocked(3) and "#ffffff" or "#3F3F3F")
			setStringColor(message, " seconds.", "#3F3F3F")

			m1 = "Spiritual Outburst\nA powerful spell that consumes\nHarmony to release a massive\nchain attack."
			m2 = message
		end
	elseif domain == 3 then
		if vocation == KNIGHT then
			setStringColor(message, "Increases the defence value of shields by ", "#3F3F3F")
			setStringColor(message, "10", currentUnlocked(1) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "20", currentUnlocked(2) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "30.\n", currentUnlocked(3) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "Increases your critical extra damage by ", "#3F3F3F")
			setStringColor(message, "4%", currentUnlocked(1) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "8%", currentUnlocked(2) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "12%", currentUnlocked(3) and "#ffffff" or "#3F3F3F")
			setStringColor(message, " while\nwielding a two-handed weapon.", "#3F3F3F")

			m1 = "Combat Mastery\nImprove your combat\nprowess based on the\nequipment you use."
			m2 = message
		elseif vocation == PALADIN then
			setStringColor(message, "This support spell creates a field of holy energy around your feet\nfor 5 seconds. As long as you stand in this field, your dealt damage\nincreases by ", "#3F3F3F")
			setStringColor(message, "8%", currentUnlocked(1) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "10%", currentUnlocked(2) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "12%.\n\n", currentUnlocked(3) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "Cooldown: ", "#3F3F3F")
			setStringColor(message, "32", currentUnlocked(1) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "28", currentUnlocked(2) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "24", currentUnlocked(3) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "seconds", "#3F3F3F")

			m1 = "Divine Empowerment\nThis support spell creates a\nfield that increases your dealt\ndamage."
			m2 = message
		elseif vocation == SORCERER then
			setStringColor(message, "Expose Weakness grants ", "#3F3F3F")
			setStringColor(message, "1.00%", currentUnlocked(1) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "2.00%", currentUnlocked(2) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "3.00%", currentUnlocked(3) and "#ffffff" or "#3F3F3F")
			setStringColor(message, " mana leech and\nSap Strength grants ", "#3F3F3F")
			setStringColor(message, "3.00%", currentUnlocked(1) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "4.00%", currentUnlocked(2) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "5.00%", currentUnlocked(3) and "#ffffff" or "#3F3F3F")
			setStringColor(message, " life leech against\ndebuffed creatures.", "#3F3F3F")

			m1 = "Drain Body\nImprove your crippling spells\nby adding mana or life leech\nto them."
			m2 = message
		elseif vocation == DRUID then
			setStringColor(message, "Decide wisely whether you want to cast ice or earth damage in a\nsmall area around you, as these two ring spells share the same\ncooldown. Both spells deal ", "#3F3F3F")
			setStringColor(message, "20%", currentUnlocked(1) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "40%", currentUnlocked(2) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "60%", currentUnlocked(3) and "#ffffff" or "#3F3F3F")
			setStringColor(message, " additional damage to\ntargets with more than 60% of their hit points.\nCooldown: ", "#3F3F3F")
			setStringColor(message, "22", currentUnlocked(1) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "18", currentUnlocked(2) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "14", currentUnlocked(3) and "#ffffff" or "#3F3F3F")
			setStringColor(message, " seconds", "#3F3F3F")

			m1 = "Twin Bursts\nPowerful ring spell that deals\nice or earth damage that is\nenhanced against targets with\nhigh hit points."
			m2 = message
		elseif vocation == MONK then
			setStringColor(message, "Increases the Harmony base bonus by ", "#3F3F3F")
			setStringColor(message, "1%", currentUnlocked(1) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "2%", currentUnlocked(2) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "3%", currentUnlocked(3) and "#ffffff" or "#3F3F3F")
			setStringColor(message, " and your\nautoattacks deal additional damage equal to ", "#3F3F3F")
			setStringColor(message, "100%", currentUnlocked(1) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "200%", currentUnlocked(2) and "#ffffff" or "#3F3F3F")
			setStringColor(message, "/", "#3F3F3F")
			setStringColor(message, "300%", currentUnlocked(3) and "#ffffff" or "#3F3F3F")
			setStringColor(message, " of\nyour mantra.", "#3F3F3F")

			m1 = "Ascetic\nImprove all spenders and allows\nmantra to improve the damage\nof your attacks."
			m2 = message
		end
	elseif domain == 4 then
		setStringColor(message, "This spell transforms yourself into a powerful avatar for 15 \nseconds.\nWhile in this form, you benefit from ", "#3F3F3F")
		setStringColor(message, "5%", currentUnlocked(1) and "#ffffff" or "#3F3F3F")
		setStringColor(message, "/", "#3F3F3F")
		setStringColor(message, "10%", currentUnlocked(2) and "#ffffff" or "#3F3F3F")
		setStringColor(message, "/", "#3F3F3F")
		setStringColor(message, "15%", currentUnlocked(3) and "#ffffff" or "#3F3F3F")
		setStringColor(message, " damage \nreduction and all your attacks are critical hits with ", "#3F3F3F")
		setStringColor(message, "5%", currentUnlocked(1) and "#ffffff" or "#3F3F3F")
		setStringColor(message, "/", "#3F3F3F")
		setStringColor(message, "10%", currentUnlocked(2) and "#ffffff" or "#3F3F3F")
		setStringColor(message, "/", "#3F3F3F")
		setStringColor(message, "15%\n", currentUnlocked(3) and "#ffffff" or "#3F3F3F")
		setStringColor(message, "critical extra damage.\nCooldown: ", "#3F3F3F")
		setStringColor(message, "120", currentUnlocked(1) and "#ffffff" or "#3F3F3F")
		setStringColor(message, "/", "#3F3F3F")
		setStringColor(message, "90", currentUnlocked(2) and "#ffffff" or "#3F3F3F")
		setStringColor(message, "/", "#3F3F3F")
		setStringColor(message, "60", currentUnlocked(3) and "#ffffff" or "#3F3F3F")
		setStringColor(message, " minutes", "#3F3F3F")

		if vocation == KNIGHT then
			m1 = "Avatar of Steel\nTransforms you into a\npowerful form that reduces\ndamage taken and increases\ndamage dealt."
			m2 = message
		elseif vocation == PALADIN then
			m1 = "Avatar of Light\nTransforms you into a\npowerful form that reduces\ndamage taken and increases\ndamage dealt."
			m2 = message
		elseif vocation == SORCERER then
			m1 = "Avatar of Storm\nTransforms you into a\npowerful form that reduces\ndamage taken and increases\ndamage dealt."
			m2 = message
		elseif vocation == DRUID then
			m1 = "Avatar of Nature\nTransforms you into a\npowerful form that reduces\ndamage taken and increases\ndamage dealt."
			m2 = message
		elseif vocation == MONK then
			m1 = "Avatar of Balance\nTransforms you into a\npowerful form that reduces\ndamage taken and increases\ndamage dealt."
			m2 = message
		end
	end

	return m1, m2
end

function getRevelationDisplayName(domain)
	local title = select(1, getPassiveInfo(domain))

	return title:match("^([^\n]+)") or title
end

function getBonusValueUpgrade(currentBonusID, gemID, supreme, firstBonus)
	local gem = GemAtelier.getGemDataById(gemID)

	if not gem then
		return 0
	end

	local slot = 0

	if gem.lesserBonus == currentBonusID then
		slot = 0
	elseif gem.regularBonus == currentBonusID then
		slot = 1
	elseif gem.supremeBonus == currentBonusID then
		slot = 2
	end

	local effectiveLevel = GemAtelier.getEffectiveLevel(gem, currentBonusID, supreme, slot)
	local modInfo = Workshop.getDataByBonus(currentBonusID, supreme)
	local bonus = Workshop.getBonusValue(modInfo, effectiveLevel, firstBonus)

	return bonus
end

function getValueByVocation(bonusType, steps)
	local step = bonusStep[WheelOfDestiny.vocationId]
	local bonus = 0

	if bonusType == "mana" then
		bonus = steps * step.mana
	elseif bonusType == "life" then
		bonus = steps * step.life
	elseif bonusType == "capacity" then
		bonus = steps * step.capacity
	end

	return bonus
end

function getVesselBonus()
	local bonuses = {}
	local defenses = {}

	local function findBonusByText(text)
		for i, b in ipairs(bonuses) do
			if b.text == text then
				return b, i
			end
		end

		return nil
	end

	local function findDefenseByText(text)
		for i, b in ipairs(defenses) do
			if b.text == text then
				return b, i
			end
		end

		return nil
	end

	for _, k in pairs(WheelOfDestiny.equipedGemBonuses) do
		if k.bonusID == -1 then
			-- block empty
		else
			local bonus = k.supreme and SupremeGemDescription[k.bonusID] or RegularGemDescription[k.bonusID]
			local firstString, secondString
			local skipIndex = bonus.text:find("\n")

			if skipIndex then
				firstString = bonus.text:sub(1, skipIndex - 1)
				secondString = bonus.text:sub(skipIndex + 1)
			else
				firstString = bonus.text
			end

			if not k.supreme then
				if firstString then
					if firstString:find("Mitigation") then
						local number = getBonusValueUpgrade(k.bonusID, k.gemID, k.supreme, true)
						local existingBonus = findBonusByText("Mitigation Mult.")

						if existingBonus then
							existingBonus.value = existingBonus.value + tonumber(number)
						else
							bonuses[#bonuses + 1] = {
								text = "Mitigation Mult.",
								bonusType = bonus.type1,
								value = number,
								tooltip = bonus.tooltip
							}
						end

						goto label_13_0
					end

					local number = getBonusValueUpgrade(k.bonusID, k.gemID, k.supreme, true)
					local message = firstString:match("@%s*(.+)")

					if bonus.type1 == "defense" then
						number = getBonusValueUpgrade(k.bonusID, k.gemID, k.supreme, true)
						message = firstString:gsub("^%+%s*%% ", "")
					end

					local existingBonus = findBonusByText(message)

					if bonus.type1 == "defense" then
						existingBonus = findDefenseByText(message)
					end

					if existingBonus then
						existingBonus.value = existingBonus.value + tonumber(number)
					elseif bonus.type1 == "defense" then
						defenses[#defenses + 1] = {
							bonusType = bonus.type1,
							text = message,
							value = number
						}
					else
						bonuses[#bonuses + 1] = {
							bonusType = bonus.type1,
							text = message,
							value = "+" .. number
						}
					end
				end

				if secondString then
					local number = getBonusValueUpgrade(k.bonusID, k.gemID, k.supreme, false)
					local message = secondString:match("@%s*(.+)")

					if bonus.type2 == "defense" then
						if bonus.bonus2 and bonus.bonus2 == -1 then
							number, message = secondString:match("([-]?%d+%.?%d*)%% (.+)")
						else
							number = getBonusValueUpgrade(k.bonusID, k.gemID, k.supreme, false)
							message = secondString:gsub("^%+%s*%% ", "")
						end
					end

					local existingBonus = findBonusByText(message)

					if bonus.type2 == "defense" then
						existingBonus = findDefenseByText(message)
					end

					if existingBonus then
						existingBonus.value = existingBonus.value + tonumber(number)
					elseif bonus.type2 == "defense" then
						defenses[#defenses + 1] = {
							bonusType = bonus.type2,
							text = message,
							value = number
						}
					else
						bonuses[#bonuses + 1] = {
							bonusType = bonus.type2,
							text = message,
							value = "+" .. number
						}
					end
				end
			elseif bonus.text:find("RM") then
				local number = getBonusValueUpgrade(k.bonusID, k.gemID, k.supreme, true)
				local existingBonus = findBonusByText(short_text(bonus.text, 17))

				if existingBonus then
					existingBonus.value = existingBonus.value + tonumber(number)
				else
					bonuses[#bonuses + 1] = {
						bonusType = "revelation",
						text = short_text(bonus.text, 17),
						value = number,
						tooltip = bonus.tooltip
					}
				end
			elseif not bonus.text:find("\n") then
				local number, message = firstString:match("([-]?%d+%.?%d*)%% (.+)")
				local existingBonus = findBonusByText(message)

				if existingBonus then
					existingBonus.value = existingBonus.value + tonumber(number)
				else
					bonuses[#bonuses + 1] = {
						bonusType = "special",
						text = message,
						value = number
					}
				end
			elseif bonus.text:find("Aug.") then
				local bonusName = firstString
				local number = getBonusValueUpgrade(k.bonusID, k.gemID, k.supreme, true)
				local tooltip = bonus.tooltip

				-- The original client used an icon glyph before supreme mod names.
				-- In this asset/font set that glyph was converted to a literal '?'.
				bonusName = bonusName:gsub("^%?%s*", ""):gsub("Aug%.%s*", "")

				if vocation == 5 and bonusName == "Greater Flurry of Blows" then
					tooltip = string.format("+%d%% Base Damage", number)
				end

				local existingBonus = findBonusByText(bonusName)

				if existingBonus then
					existingBonus.value = existingBonus.value + tonumber(number)

					if string.find(tooltip, "%%") then
						existingBonus.tooltip = tr(tooltip, existingBonus.value)
					end
				else
					if string.find(tooltip, "%%") then
						tooltip = tr(tooltip, number)
					end

					bonuses[#bonuses + 1] = {
						bonusType = "augment",
						text = bonusName,
						value = number,
						tooltip = tooltip
					}
				end
			end
		end

		::label_13_0::
	end

	if #defenses > 0 then
		bonuses[#bonuses + 1] = {
			text = "Resistances:",
			bonusType = "defense",
			value = -1
		}
	end

	for _, v in pairs(defenses) do
		if v.value == 0 then
			-- block empty
		else
			local valueString = tonumber(v.value) > 0 and "+" .. v.value or v.value

			bonuses[#bonuses + 1] = {
				bonusType = v.bonusType,
				text = "  " .. v.text:gsub(" Resistance", ""),
				value = valueString .. "%"
			}
		end
	end

	local DHcount = GemAtelier:getDamageAndHealing()

	if DHcount > 0 then
		table.insert(bonuses, 1, {
			text = "Damage and Healing",
			tooltip = "If the Vessel Resonance matches the gem quality in this domain, a\nbonus of +1 to all damage and healing is granted. This bonus is\nincreased by 1 for greater gems.\n\nRegardless of the match, gems will always grant mod bonuses\nbased on the Vessel Resonance.\n? Lesser gems match Dormant Vessels (VR I)\n? Regular gems match Awakened Vessels (VR II)\n? Greater gems match Radiant Vessels (VR III)",
			bonusType = "damagehealing",
			value = "+" .. DHcount
		})
	end

	return bonuses
end
