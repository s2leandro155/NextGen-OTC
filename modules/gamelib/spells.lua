-- chunkname: @/gamelib/spells.lua

SpelllistSettings = {
	Default = {
		iconFile = "/images/game/spells/spell-icons-32x32",
		iconSize = {
			width = 32,
			height = 32
		}
	}
}
PassiveAbilities = {
	{
		type = "Passive",
		name = "Gift of Life",
		icon = "/images/game/spells/passiveability-icons-32x32",
		exhaustion = 108000000
	}
}

function PassiveAbilityUnlockedInWheel(passiveId)
	if passiveId ~= 1 then
		return true
	end

	local WD = rawget(_G, "WheelOfDestiny")

	if type(WD) ~= "table" or not WD.passivePoints then
		return true
	end

	local topLeftPoints = WD.passivePoints[1] or 0

	return topLeftPoints >= 250
end

SpellAreas = {
	AREA_BEAM5 = {
		{
			1
		},
		{
			1
		},
		{
			1
		},
		{
			1
		},
		{
			1
		},
		{
			3
		}
	},
	AREA_BEAM6 = {
		{
			1
		},
		{
			1
		},
		{
			1
		},
		{
			1
		},
		{
			1
		},
		{
			1
		},
		{
			3
		}
	},
	AREA_BEAM7 = {
		{
			1
		},
		{
			1
		},
		{
			1
		},
		{
			1
		},
		{
			1
		},
		{
			1
		},
		{
			1
		},
		{
			3
		}
	},
	AREA_BEAM8 = {
		{
			1
		},
		{
			1
		},
		{
			1
		},
		{
			1
		},
		{
			1
		},
		{
			1
		},
		{
			1
		},
		{
			1
		},
		{
			3
		}
	},
	AREA_SQUAREWAVE1 = {
		{
			1,
			1,
			1
		},
		{
			0,
			3,
			0
		}
	},
	AREA_SQUAREWAVE3 = {
		{
			1,
			1,
			1
		},
		{
			1,
			1,
			1
		},
		{
			0,
			1,
			0
		},
		{
			0,
			3,
			0
		}
	},
	AREA_SQUAREWAVE4 = {
		{
			1,
			1,
			1
		},
		{
			1,
			1,
			1
		},
		{
			1,
			1,
			1
		},
		{
			0,
			1,
			0
		},
		{
			0,
			1,
			0
		},
		{
			0,
			3,
			0
		}
	},
	AREA_SQUAREWAVE5 = {
		{
			1,
			1,
			1,
			1,
			1
		},
		{
			0,
			1,
			1,
			1,
			0
		},
		{
			0,
			1,
			1,
			1,
			0
		},
		{
			0,
			0,
			1,
			0,
			0
		},
		{
			0,
			0,
			3,
			0,
			0
		}
	},
	AREA_SQUAREWAVE6 = {
		{
			1,
			1,
			1,
			1,
			1
		},
		{
			1,
			1,
			1,
			1,
			1
		},
		{
			0,
			1,
			1,
			1,
			0
		},
		{
			0,
			1,
			1,
			1,
			0
		},
		{
			0,
			0,
			1,
			0,
			0
		},
		{
			0,
			0,
			3,
			0,
			0
		}
	},
	AREA_SQUARE2X2 = {
		{
			1,
			1,
			1,
			1,
			1
		},
		{
			1,
			1,
			1,
			1,
			1
		},
		{
			1,
			1,
			3,
			1,
			1
		},
		{
			1,
			1,
			1,
			1,
			1
		},
		{
			1,
			1,
			1,
			1,
			1
		}
	},
	AREA_CIRCLE1X1 = {
		{
			1,
			1,
			1
		},
		{
			1,
			3,
			1
		},
		{
			1,
			1,
			1
		}
	},
	AREA_CIRCLE2X2 = {
		{
			0,
			1,
			1,
			1,
			0
		},
		{
			1,
			1,
			1,
			1,
			1
		},
		{
			1,
			1,
			3,
			1,
			1
		},
		{
			1,
			1,
			1,
			1,
			1
		},
		{
			0,
			1,
			1,
			1,
			0
		}
	},
	AREA_CIRCLE3X3 = {
		{
			0,
			0,
			1,
			1,
			1,
			0,
			0
		},
		{
			0,
			1,
			1,
			1,
			1,
			1,
			0
		},
		{
			1,
			1,
			1,
			1,
			1,
			1,
			1
		},
		{
			1,
			1,
			1,
			3,
			1,
			1,
			1
		},
		{
			1,
			1,
			1,
			1,
			1,
			1,
			1
		},
		{
			0,
			1,
			1,
			1,
			1,
			1,
			0
		},
		{
			0,
			0,
			1,
			1,
			1,
			0,
			0
		}
	},
	AREA_CIRCLE5X5 = {
		{
			0,
			0,
			0,
			0,
			0,
			1,
			0,
			0,
			0,
			0,
			0
		},
		{
			0,
			0,
			0,
			1,
			1,
			1,
			1,
			1,
			0,
			0,
			0
		},
		{
			0,
			0,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			0,
			0
		},
		{
			0,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			0
		},
		{
			0,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			0
		},
		{
			1,
			1,
			1,
			1,
			1,
			3,
			1,
			1,
			1,
			1,
			1
		},
		{
			0,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			0
		},
		{
			0,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			0
		},
		{
			0,
			0,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			0,
			0
		},
		{
			0,
			0,
			0,
			1,
			1,
			1,
			1,
			1,
			0,
			0,
			0
		},
		{
			0,
			0,
			0,
			0,
			0,
			1,
			0,
			0,
			0,
			0,
			0
		}
	},
	AREA_CIRCLE6X6 = {
		{
			0,
			0,
			0,
			0,
			0,
			0,
			1,
			0,
			0,
			0,
			0,
			0,
			0
		},
		{
			0,
			0,
			0,
			0,
			1,
			1,
			1,
			1,
			1,
			0,
			0,
			0,
			0
		},
		{
			0,
			0,
			0,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			0,
			0,
			0
		},
		{
			0,
			0,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			0,
			0
		},
		{
			0,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			0
		},
		{
			0,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			0
		},
		{
			1,
			1,
			1,
			1,
			1,
			1,
			3,
			1,
			1,
			1,
			1,
			1,
			1
		},
		{
			0,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			0
		},
		{
			0,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			0
		},
		{
			0,
			0,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			0,
			0
		},
		{
			0,
			0,
			0,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			0,
			0,
			0
		},
		{
			0,
			0,
			0,
			0,
			1,
			1,
			1,
			1,
			1,
			0,
			0,
			0,
			0
		},
		{
			0,
			0,
			0,
			0,
			0,
			0,
			1,
			0,
			0,
			0,
			0,
			0,
			0
		}
	},
	AREA_RING_BURST3 = {
		{
			0,
			0,
			0,
			1,
			1,
			1,
			0,
			0,
			0
		},
		{
			0,
			0,
			1,
			1,
			1,
			1,
			1,
			0,
			0
		},
		{
			0,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			0
		},
		{
			1,
			1,
			1,
			0,
			0,
			0,
			1,
			1,
			1
		},
		{
			1,
			1,
			1,
			0,
			3,
			0,
			1,
			1,
			1
		},
		{
			1,
			1,
			1,
			0,
			0,
			0,
			1,
			1,
			1
		},
		{
			0,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			0
		},
		{
			0,
			0,
			1,
			1,
			1,
			1,
			1,
			0,
			0
		},
		{
			0,
			0,
			0,
			1,
			1,
			1,
			0,
			0,
			0
		}
	},
	AREA_BURSTWAVE1 = {
		{
			0,
			1,
			1,
			1,
			0
		},
		{
			1,
			1,
			1,
			1,
			1
		},
		{
			1,
			1,
			3,
			1,
			1
		},
		{
			0,
			1,
			0,
			1,
			0
		}
	},
	AREA_FLURRYWAVE = {
		{
			0,
			0,
			1,
			0,
			0
		},
		{
			0,
			1,
			1,
			1,
			0
		},
		{
			0,
			1,
			1,
			1,
			0
		},
		{
			0,
			1,
			3,
			1,
			0
		}
	},
	AREA_GREATER_FLURRYWAVE = {
		{
			0,
			0,
			1,
			0,
			0
		},
		{
			0,
			1,
			1,
			1,
			0
		},
		{
			0,
			1,
			1,
			1,
			0
		},
		{
			1,
			1,
			1,
			1,
			1
		},
		{
			0,
			1,
			3,
			1,
			0
		}
	},
	AREA_SHORTWAVE4 = {
		{
			0,
			1,
			1,
			1,
			0
		},
		{
			1,
			1,
			1,
			1,
			1
		},
		{
			1,
			1,
			1,
			1,
			1
		},
		{
			1,
			1,
			1,
			1,
			1
		},
		{
			1,
			1,
			3,
			1,
			1
		}
	},
	AREA_FORKS = {
		{
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1
		},
		{
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1
		},
		{
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1
		},
		{
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1
		},
		{
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1
		},
		{
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			3,
			1,
			1,
			1,
			1,
			1,
			1,
			1
		},
		{
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1
		},
		{
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1
		},
		{
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1
		},
		{
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1
		},
		{
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1,
			1
		}
	}
}
SpellInfo = {
	Default = {
		["Light Healing"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 20,
			level = 8,
			needTarget = false,
			words = "exura",
			id = 1,
			exhaustion = 1000,
			name = "Light Healing",
			premium = false,
			range = 0,
			group = {
				[2] = 1000
			},
			vocations = {
				1,
				2,
				3,
				5,
				6,
				7,
				9,
				10
			}
		},
		["Intense Healing"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 70,
			level = 20,
			needTarget = false,
			words = "exura gran",
			id = 2,
			exhaustion = 1000,
			name = "Intense Healing",
			premium = false,
			range = 0,
			group = {
				[2] = 1000
			},
			vocations = {
				1,
				2,
				3,
				5,
				6,
				7,
				9,
				10
			}
		},
		["Ultimate Healing"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 160,
			level = 30,
			needTarget = false,
			words = "exura vita",
			id = 3,
			exhaustion = 1000,
			name = "Ultimate Healing",
			premium = false,
			range = 0,
			group = {
				[2] = 1000
			},
			vocations = {
				1,
				2,
				5,
				6
			}
		},
		["Intense Healing Rune"] = {
			maglevel = 1,
			type = "Conjure",
			soul = 2,
			mana = 120,
			level = 15,
			needTarget = false,
			parameter = false,
			words = "adura gran",
			id = 4,
			range = 0,
			exhaustion = 2000,
			name = "Intense Healing Rune",
			premium = false,
			source = 3147,
			group = {
				[3] = 2000
			},
			vocations = {
				2,
				6
			}
		},
		["Ultimate Healing Rune"] = {
			maglevel = 4,
			type = "Conjure",
			soul = 3,
			mana = 400,
			level = 24,
			needTarget = false,
			parameter = false,
			words = "adura vita",
			id = 5,
			range = 0,
			exhaustion = 2000,
			name = "Ultimate Healing Rune",
			premium = false,
			source = 3147,
			group = {
				[3] = 2000
			},
			vocations = {
				2,
				6
			}
		},
		Haste = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 60,
			level = 14,
			needTarget = false,
			words = "utani hur",
			id = 6,
			duration = 33000,
			exhaustion = 2000,
			name = "Haste",
			premium = true,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				2,
				3,
				4,
				5,
				6,
				7,
				8,
				9,
				10
			}
		},
		["Light Magic Missile"] = {
			maglevel = 0,
			type = "Conjure",
			soul = 1,
			mana = 120,
			level = 15,
			needTarget = false,
			parameter = false,
			words = "adori min vis",
			id = 7,
			range = 0,
			exhaustion = 2000,
			name = "Light Magic Missile",
			premium = false,
			source = 3147,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				2,
				5,
				6
			}
		},
		["Heavy Magic Missile"] = {
			maglevel = 3,
			type = "Conjure",
			soul = 2,
			mana = 350,
			level = 25,
			needTarget = false,
			parameter = false,
			words = "adori vis",
			id = 8,
			range = 0,
			exhaustion = 2000,
			name = "Heavy Magic Missile",
			premium = false,
			source = 3147,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				5,
				2,
				6
			}
		},
		["Summon Creature"] = {
			parameter = true,
			type = "Instant",
			soul = 0,
			mana = 0,
			level = 25,
			needTarget = false,
			parameterPlaceholder = "creature",
			words = "utevo res",
			id = 9,
			exhaustion = 2000,
			name = "Summon Creature",
			premium = false,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				2,
				5,
				6
			}
		},
		Light = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 20,
			level = 8,
			needTarget = false,
			words = "utevo lux",
			id = 10,
			exhaustion = 2000,
			name = "Light",
			premium = false,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				2,
				3,
				4,
				5,
				6,
				7,
				8,
				9,
				10
			}
		},
		["Great Light"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 60,
			level = 13,
			needTarget = false,
			words = "utevo gran lux",
			id = 11,
			exhaustion = 2000,
			name = "Great Light",
			premium = false,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				2,
				3,
				4,
				5,
				6,
				7,
				8,
				9,
				10
			}
		},
		["Convince Creature"] = {
			maglevel = 5,
			type = "Conjure",
			soul = 3,
			mana = 200,
			level = 16,
			needTarget = false,
			parameter = false,
			words = "adeta sio",
			id = 12,
			range = 0,
			exhaustion = 2000,
			name = "Convince Creature",
			premium = false,
			source = 3147,
			group = {
				[3] = 2000
			},
			vocations = {
				2,
				6
			}
		},
		["Energy Wave"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 170,
			level = 38,
			needTarget = false,
			directional = true,
			words = "exevo vis hur",
			id = 13,
			exhaustion = 8000,
			name = "Energy Wave",
			premium = false,
			range = 0,
			group = {
				[1] = 2000
			},
			vocations = {
				1,
				5
			},
			area = SpellAreas.AREA_SQUAREWAVE4
		},
		Chameleon = {
			maglevel = 4,
			type = "Conjure",
			soul = 2,
			mana = 600,
			level = 27,
			needTarget = false,
			parameter = false,
			words = "adevo ina",
			id = 14,
			range = 0,
			exhaustion = 2000,
			name = "Chameleon",
			premium = false,
			source = 3147,
			group = {
				[3] = 2000
			},
			vocations = {
				2,
				6
			}
		},
		Fireball = {
			maglevel = 4,
			type = "Conjure",
			soul = 3,
			mana = 460,
			level = 27,
			needTarget = false,
			parameter = false,
			words = "adori flam",
			id = 15,
			range = 0,
			exhaustion = 2000,
			name = "Fireball",
			premium = true,
			source = 3147,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				5
			}
		},
		["Great Fireball"] = {
			maglevel = 4,
			type = "Conjure",
			soul = 3,
			mana = 530,
			level = 30,
			needTarget = false,
			parameter = false,
			words = "adori mas flam",
			id = 16,
			range = 0,
			exhaustion = 2000,
			name = "Great Fireball",
			premium = false,
			source = 3147,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				5
			}
		},
		Firebomb = {
			maglevel = 5,
			type = "Conjure",
			soul = 4,
			mana = 600,
			level = 27,
			needTarget = false,
			parameter = false,
			words = "adevo mas flam",
			id = 17,
			range = 0,
			exhaustion = 2000,
			name = "Fire Bomb Rune",
			premium = false,
			source = 3147,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				2,
				5,
				6
			}
		},
		Explosion = {
			maglevel = 6,
			type = "Conjure",
			soul = 4,
			mana = 570,
			level = 31,
			needTarget = false,
			parameter = false,
			words = "adevo mas hur",
			id = 18,
			range = 0,
			exhaustion = 2000,
			name = "Explosion",
			premium = false,
			source = 3147,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				2,
				5,
				6
			}
		},
		["Fire Wave"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 25,
			level = 18,
			needTarget = false,
			directional = true,
			words = "exevo flam hur",
			id = 19,
			exhaustion = 3000,
			name = "Fire Wave",
			premium = false,
			range = 0,
			group = {
				[1] = 2000
			},
			vocations = {
				1,
				5
			},
			area = SpellAreas.AREA_SQUAREWAVE5
		},
		["Find Person"] = {
			parameter = true,
			type = "Instant",
			soul = 0,
			mana = 20,
			level = 8,
			needTarget = false,
			parameterPlaceholder = "name",
			words = "exiva",
			id = 20,
			exhaustion = 2000,
			name = "Find Person",
			premium = false,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				2,
				3,
				4,
				5,
				6,
				7,
				8,
				9,
				10
			}
		},
		["Sudden Death"] = {
			maglevel = 15,
			type = "Conjure",
			soul = 5,
			mana = 985,
			level = 45,
			needTarget = false,
			parameter = false,
			words = "adori gran mort",
			id = 21,
			range = 0,
			exhaustion = 2000,
			name = "Sudden Death",
			premium = false,
			source = 3147,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				5
			}
		},
		["Energy Beam"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 40,
			level = 23,
			needTarget = false,
			directional = true,
			words = "exevo vis lux",
			id = 22,
			exhaustion = 4000,
			name = "Energy Beam",
			premium = false,
			range = 0,
			group = {
				[1] = 2000
			},
			vocations = {
				1,
				5
			},
			area = SpellAreas.AREA_BEAM5
		},
		["Great Energy Beam"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 110,
			level = 29,
			needTarget = false,
			directional = true,
			words = "exevo gran vis lux",
			id = 23,
			exhaustion = 6000,
			name = "Great Energy Beam",
			premium = false,
			range = 0,
			group = {
				[1] = 2000,
				[9] = 6000
			},
			vocations = {
				1,
				5
			},
			area = SpellAreas.AREA_BEAM8
		},
		["Hell's Core"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 1100,
			level = 60,
			needTarget = false,
			words = "exevo gran mas flam",
			id = 24,
			exhaustion = 40000,
			name = "Hell's Core",
			premium = true,
			range = 0,
			group = {
				[1] = 4000,
				[7] = 40000
			},
			vocations = {
				1,
				5
			},
			area = SpellAreas.AREA_CIRCLE5X5
		},
		["Fire Field"] = {
			maglevel = 1,
			type = "Conjure",
			soul = 1,
			mana = 240,
			level = 15,
			needTarget = false,
			parameter = false,
			words = "adevo grav flam",
			id = 25,
			range = 0,
			exhaustion = 2000,
			name = "Fire Field Rune",
			premium = false,
			source = 3147,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				2,
				5,
				6
			}
		},
		["Poison Field"] = {
			maglevel = 0,
			type = "Conjure",
			soul = 1,
			mana = 200,
			level = 14,
			needTarget = false,
			parameter = false,
			words = "adevo grav pox",
			id = 26,
			range = 0,
			exhaustion = 2000,
			name = "Poison Field Rune",
			premium = false,
			source = 3147,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				2,
				5,
				6
			}
		},
		["Energy Field"] = {
			maglevel = 3,
			type = "Conjure",
			soul = 2,
			mana = 320,
			level = 18,
			needTarget = false,
			parameter = false,
			words = "adevo grav vis",
			id = 27,
			range = 0,
			exhaustion = 2000,
			name = "Energy Field Rune",
			premium = false,
			source = 3147,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				2,
				5,
				6
			}
		},
		["Fire Wall"] = {
			maglevel = 6,
			type = "Conjure",
			soul = 4,
			mana = 780,
			level = 33,
			needTarget = false,
			parameter = false,
			words = "adevo mas grav flam",
			id = 28,
			range = 0,
			exhaustion = 2000,
			name = "Fire Wall Rune",
			premium = false,
			source = 3147,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				2,
				5,
				6
			}
		},
		["Cure Poison"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 30,
			level = 10,
			needTarget = false,
			words = "exana pox",
			id = 29,
			exhaustion = 6000,
			name = "Cure Poison",
			premium = false,
			range = 0,
			group = {
				[2] = 1000
			},
			vocations = {
				1,
				2,
				3,
				4,
				5,
				6,
				7,
				8,
				9,
				10
			}
		},
		["Destroy Field"] = {
			maglevel = 3,
			type = "Conjure",
			soul = 2,
			mana = 120,
			level = 17,
			needTarget = false,
			parameter = false,
			words = "adito grav",
			id = 30,
			range = 0,
			exhaustion = 2000,
			name = "Destroy Field Rune",
			premium = false,
			source = 3147,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				2,
				3,
				5,
				6,
				7,
				9,
				10
			}
		},
		["Cure Poison Rune"] = {
			maglevel = 0,
			type = "Conjure",
			soul = 1,
			mana = 200,
			level = 15,
			needTarget = false,
			parameter = false,
			words = "adana pox",
			id = 31,
			range = 0,
			exhaustion = 2000,
			name = "Cure Poison Rune",
			premium = false,
			source = 3147,
			group = {
				[3] = 2000
			},
			vocations = {
				2,
				6
			}
		},
		["Poison Wall"] = {
			maglevel = 5,
			type = "Conjure",
			soul = 3,
			mana = 640,
			level = 29,
			needTarget = false,
			parameter = false,
			words = "adevo mas grav pox",
			id = 32,
			range = 0,
			exhaustion = 2000,
			name = "Poison Wall Rune",
			premium = false,
			source = 3147,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				2,
				5,
				6
			}
		},
		["Energy Wall"] = {
			maglevel = 9,
			type = "Conjure",
			soul = 5,
			mana = 1000,
			level = 41,
			needTarget = false,
			parameter = false,
			words = "adevo mas grav vis",
			id = 33,
			range = 0,
			exhaustion = 2000,
			name = "Energy Wall Rune",
			premium = false,
			source = 3147,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				2,
				5,
				6
			}
		},
		Salvation = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 210,
			level = 60,
			needTarget = false,
			words = "exura gran san",
			id = 36,
			exhaustion = 1000,
			name = "Salvation",
			premium = true,
			range = 0,
			group = {
				[2] = 1000
			},
			vocations = {
				3,
				7
			}
		},
		["Creature Illusion"] = {
			parameter = true,
			type = "Instant",
			soul = 0,
			mana = 100,
			level = 23,
			needTarget = false,
			parameterPlaceholder = "creature",
			words = "utevo res ina",
			id = 38,
			exhaustion = 2000,
			name = "Creature Illusion",
			premium = false,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				2,
				5,
				6
			}
		},
		["Strong Haste"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 100,
			level = 20,
			needTarget = false,
			words = "utani gran hur",
			id = 39,
			duration = 22000,
			exhaustion = 2000,
			name = "Strong Haste",
			premium = true,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				2,
				5,
				6,
				9,
				10
			}
		},
		Food = {
			parameter = false,
			type = "Instant",
			soul = 1,
			mana = 120,
			level = 0,
			needTarget = false,
			words = "exevo pan",
			id = 42,
			exhaustion = 2000,
			name = "Food",
			premium = false,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				2,
				6
			}
		},
		["Strong Ice Wave"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 170,
			level = 40,
			needTarget = false,
			directional = true,
			words = "exevo gran frigo hur",
			id = 43,
			exhaustion = 8000,
			name = "Strong Ice Wave",
			premium = false,
			range = 0,
			group = {
				[1] = 2000
			},
			vocations = {
				2,
				6
			},
			area = SpellAreas.AREA_SQUAREWAVE3
		},
		["Magic Shield"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 50,
			level = 14,
			needTarget = false,
			words = "utamo vita",
			id = 44,
			exhaustion = 14000,
			name = "Magic Shield",
			premium = false,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				2,
				5,
				6
			}
		},
		Invisibility = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 440,
			level = 35,
			needTarget = false,
			words = "utana vid",
			id = 45,
			exhaustion = 2000,
			name = "Invisibility",
			premium = false,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				2,
				5,
				6
			}
		},
		["Conjure Explosive Arrow"] = {
			parameter = false,
			type = "Conjure",
			soul = 3,
			mana = 290,
			level = 25,
			needTarget = false,
			words = "exevo con flam",
			id = 49,
			exhaustion = 2000,
			name = "Conjure Explosive Arrow",
			premium = false,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				3,
				7
			}
		},
		Soulfire = {
			maglevel = 7,
			type = "Conjure",
			soul = 3,
			mana = 420,
			level = 27,
			needTarget = false,
			parameter = false,
			words = "adevo res flam",
			id = 50,
			range = 0,
			exhaustion = 2000,
			name = "Soulfire",
			premium = true,
			source = 3147,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				2,
				5,
				6
			}
		},
		["Conjure Arrow"] = {
			parameter = false,
			type = "Conjure",
			soul = 1,
			mana = 100,
			level = 13,
			needTarget = false,
			words = "exevo con",
			id = 51,
			exhaustion = 2000,
			name = "Conjure Arrow",
			premium = false,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				3,
				7
			}
		},
		Paralyze = {
			maglevel = 18,
			type = "Conjure",
			soul = 3,
			mana = 1400,
			level = 54,
			needTarget = false,
			parameter = false,
			words = "adana ani",
			id = 54,
			range = 0,
			exhaustion = 2000,
			name = "Paralyze",
			premium = true,
			source = 3147,
			group = {
				[3] = 2000
			},
			vocations = {
				2,
				6
			}
		},
		Energybomb = {
			maglevel = 10,
			type = "Conjure",
			soul = 5,
			mana = 880,
			level = 37,
			needTarget = false,
			parameter = false,
			words = "adevo mas vis",
			id = 55,
			range = 0,
			exhaustion = 2000,
			name = "Energy Bomb Rune",
			premium = true,
			source = 3147,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				5
			}
		},
		["Wrath of Nature"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 700,
			level = 55,
			needTarget = false,
			words = "exevo gran mas tera",
			id = 56,
			exhaustion = 40000,
			name = "Wrath of Nature",
			premium = true,
			range = 0,
			group = {
				[1] = 4000,
				[7] = 40000
			},
			vocations = {
				2,
				6
			},
			area = SpellAreas.AREA_CIRCLE6X6
		},
		["Strong Ethereal Spear"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 55,
			level = 90,
			needTarget = true,
			words = "exori gran con",
			id = 57,
			exhaustion = 8000,
			name = "Strong Ethereal Spear",
			premium = true,
			range = 7,
			group = {
				[1] = 2000
			},
			vocations = {
				3,
				7
			}
		},
		["Front Sweep"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 200,
			level = 70,
			needTarget = false,
			directional = true,
			words = "exori min",
			id = 59,
			exhaustion = 6000,
			name = "Front Sweep",
			premium = true,
			range = 0,
			group = {
				[1] = 2000
			},
			vocations = {
				4,
				8
			},
			area = SpellAreas.AREA_SQUAREWAVE1
		},
		["Brutal Strike"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 30,
			level = 16,
			needTarget = true,
			words = "exori ico",
			id = 61,
			exhaustion = 6000,
			name = "Brutal Strike",
			premium = true,
			range = 1,
			group = {
				[1] = 2000
			},
			vocations = {
				4,
				8
			}
		},
		Annihilation = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 300,
			level = 110,
			needTarget = true,
			words = "exori gran ico",
			id = 62,
			exhaustion = 30000,
			name = "Annihilation",
			premium = true,
			range = 1,
			group = {
				[1] = 2000
			},
			vocations = {
				4,
				8
			}
		},
		["Ultimate Light"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 140,
			level = 26,
			needTarget = false,
			words = "utevo vis lux",
			id = 75,
			exhaustion = 2000,
			name = "Ultimate Light",
			premium = true,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				2,
				5,
				6
			}
		},
		["Magic Rope"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 20,
			level = 9,
			needTarget = false,
			words = "exani tera",
			id = 76,
			exhaustion = 2000,
			name = "Magic Rope",
			premium = true,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				2,
				3,
				4,
				5,
				6,
				7,
				8,
				9,
				10
			}
		},
		Stalagmite = {
			maglevel = 3,
			type = "Conjure",
			soul = 2,
			mana = 350,
			level = 24,
			needTarget = false,
			parameter = false,
			words = "adori tera",
			id = 77,
			range = 0,
			exhaustion = 2000,
			name = "Stalagmite Rune",
			premium = false,
			source = 3147,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				5,
				2,
				6
			}
		},
		Disintegrate = {
			maglevel = 4,
			type = "Conjure",
			soul = 3,
			mana = 200,
			level = 21,
			needTarget = false,
			parameter = false,
			words = "adito tera",
			id = 78,
			range = 0,
			exhaustion = 2000,
			name = "Disintegrate Rune",
			premium = true,
			source = 3147,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				2,
				3,
				5,
				6,
				7,
				9,
				10
			}
		},
		Berserk = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 115,
			level = 35,
			needTarget = false,
			words = "exori",
			id = 80,
			exhaustion = 4000,
			name = "Berserk",
			premium = true,
			range = 0,
			group = {
				[1] = 2000
			},
			vocations = {
				4,
				8
			},
			area = SpellAreas.AREA_CIRCLE1X1
		},
		Levitate = {
			parameter = true,
			type = "Instant",
			soul = 0,
			mana = 50,
			level = 12,
			needTarget = false,
			parameterPlaceholder = "up|down",
			words = "exani hur",
			id = 81,
			exhaustion = 2000,
			name = "Levitate",
			premium = true,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				2,
				3,
				4,
				5,
				6,
				7,
				8,
				9,
				10
			}
		},
		["Mass Healing"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 150,
			level = 36,
			needTarget = false,
			words = "exura gran mas res",
			id = 82,
			exhaustion = 2000,
			name = "Mass Healing",
			premium = true,
			range = 0,
			group = {
				[2] = 1000
			},
			vocations = {
				2,
				6
			}
		},
		["Animate Dead"] = {
			maglevel = 4,
			type = "Conjure",
			soul = 5,
			mana = 600,
			level = 27,
			needTarget = false,
			parameter = false,
			words = "adana mort",
			id = 83,
			range = 0,
			exhaustion = 2000,
			name = "Animate Dead",
			premium = true,
			source = 3147,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				2,
				5,
				6
			}
		},
		["Heal Friend"] = {
			parameter = true,
			type = "Instant",
			soul = 0,
			mana = 120,
			level = 18,
			needTarget = true,
			parameterPlaceholder = "name",
			words = "exura sio",
			id = 84,
			exhaustion = 1000,
			name = "Heal Friend",
			premium = true,
			range = 7,
			group = {
				[2] = 1000
			},
			vocations = {
				2,
				6
			}
		},
		["Magic Wall"] = {
			maglevel = 9,
			type = "Conjure",
			soul = 5,
			mana = 750,
			level = 32,
			needTarget = false,
			parameter = false,
			words = "adevo grav tera",
			id = 86,
			range = 0,
			exhaustion = 2000,
			name = "Magic Wall Rune",
			premium = true,
			source = 3147,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				5
			}
		},
		["Death Strike"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 20,
			level = 16,
			needTarget = false,
			words = "exori mort",
			id = 87,
			exhaustion = 2000,
			name = "Death Strike",
			premium = true,
			range = 3,
			group = {
				[1] = 2000
			},
			vocations = {
				1,
				5
			}
		},
		["Energy Strike"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 20,
			level = 12,
			needTarget = false,
			words = "exori vis",
			id = 88,
			exhaustion = 2000,
			name = "Energy Strike",
			premium = true,
			range = 3,
			group = {
				[1] = 2000
			},
			vocations = {
				1,
				2,
				5,
				6
			}
		},
		["Flame Strike"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 20,
			level = 14,
			needTarget = false,
			words = "exori flam",
			id = 89,
			exhaustion = 2000,
			name = "Flame Strike",
			premium = true,
			range = 3,
			group = {
				[1] = 2000
			},
			vocations = {
				1,
				2,
				5,
				6
			}
		},
		["Cancel Invisibility"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 200,
			level = 26,
			needTarget = false,
			words = "exana ina",
			id = 90,
			exhaustion = 2000,
			name = "Cancel Invisibility",
			premium = true,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				3,
				7
			}
		},
		Poisonbomb = {
			maglevel = 4,
			type = "Conjure",
			soul = 2,
			mana = 520,
			level = 25,
			needTarget = false,
			parameter = false,
			words = "adevo mas pox",
			id = 91,
			range = 0,
			exhaustion = 2000,
			name = "Poison Bomb Rune",
			premium = true,
			source = 3147,
			group = {
				[3] = 2000
			},
			vocations = {
				2,
				6
			}
		},
		["Conjure Wand of Darkness"] = {
			parameter = false,
			type = "Conjure",
			soul = 0,
			mana = 250,
			level = 41,
			needTarget = false,
			words = "exevo gran mort",
			id = 92,
			exhaustion = 1200000,
			name = "Conjure Wand of Darkness",
			premium = true,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				5
			}
		},
		Challenge = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 30,
			level = 20,
			needTarget = false,
			words = "exeta res",
			id = 93,
			exhaustion = 2000,
			name = "Challenge",
			premium = true,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				8
			}
		},
		["Wild Growth"] = {
			maglevel = 8,
			type = "Conjure",
			soul = 5,
			mana = 600,
			level = 27,
			needTarget = false,
			parameter = false,
			words = "adevo grav vita",
			id = 94,
			range = 0,
			exhaustion = 0,
			name = "Wild Growth",
			premium = true,
			source = 3147,
			group = {
				[3] = 2000
			},
			vocations = {
				2,
				6
			}
		},
		["Fierce Berserk"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 340,
			level = 90,
			needTarget = false,
			words = "exori gran",
			id = 105,
			exhaustion = 6000,
			name = "Fierce Berserk",
			premium = true,
			range = 0,
			group = {
				[1] = 2000
			},
			vocations = {
				4,
				8
			},
			area = SpellAreas.AREA_CIRCLE1X1
		},
		Groundshaker = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 160,
			level = 33,
			needTarget = false,
			words = "exori mas",
			id = 106,
			exhaustion = 8000,
			name = "Groundshaker",
			premium = true,
			range = 0,
			group = {
				[1] = 2000
			},
			vocations = {
				4,
				8
			},
			area = SpellAreas.AREA_CIRCLE3X3
		},
		["Whirlwind Throw"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 40,
			level = 28,
			needTarget = true,
			words = "exori hur",
			id = 107,
			exhaustion = 6000,
			name = "Whirlwind Throw",
			premium = true,
			range = 5,
			group = {
				[1] = 2000
			},
			vocations = {
				4,
				8
			}
		},
		["Enchant Spear"] = {
			parameter = false,
			type = "Conjure",
			soul = 3,
			mana = 350,
			level = 45,
			needTarget = false,
			range = 0,
			words = "exeta con",
			id = 110,
			exhaustion = 2000,
			name = "Enchant Spear",
			premium = true,
			source = 3277,
			group = {
				[3] = 2000
			},
			vocations = {
				3,
				7
			}
		},
		["Ethereal Spear"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 25,
			level = 23,
			needTarget = true,
			words = "exori con",
			id = 111,
			exhaustion = 2000,
			name = "Ethereal Spear",
			premium = true,
			range = 7,
			group = {
				[1] = 2000
			},
			vocations = {
				3,
				7
			}
		},
		["Ice Strike"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 20,
			level = 15,
			needTarget = false,
			words = "exori frigo",
			id = 112,
			exhaustion = 2000,
			name = "Ice Strike",
			premium = true,
			range = 3,
			group = {
				[1] = 2000
			},
			vocations = {
				1,
				5,
				2,
				6
			}
		},
		["Terra Strike"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 20,
			level = 13,
			needTarget = false,
			words = "exori tera",
			id = 113,
			exhaustion = 2000,
			name = "Terra Strike",
			premium = true,
			range = 3,
			group = {
				[1] = 2000
			},
			vocations = {
				1,
				5,
				2,
				6
			}
		},
		Icicle = {
			maglevel = 4,
			type = "Conjure",
			soul = 3,
			mana = 460,
			level = 28,
			needTarget = false,
			parameter = false,
			words = "adori frigo",
			id = 114,
			range = 0,
			exhaustion = 2000,
			name = "Icicle",
			premium = true,
			source = 3147,
			group = {
				[3] = 2000
			},
			vocations = {
				2,
				6
			}
		},
		Avalanche = {
			maglevel = 4,
			type = "Conjure",
			soul = 3,
			mana = 530,
			level = 30,
			needTarget = false,
			parameter = false,
			words = "adori mas frigo",
			id = 115,
			range = 0,
			exhaustion = 2000,
			name = "Avalanche",
			premium = false,
			source = 3147,
			group = {
				[3] = 2000
			},
			vocations = {
				2,
				6
			}
		},
		["Stone Shower"] = {
			maglevel = 4,
			type = "Conjure",
			soul = 3,
			mana = 430,
			level = 28,
			needTarget = false,
			parameter = false,
			words = "adori mas tera",
			id = 116,
			range = 0,
			exhaustion = 2000,
			name = "Stone Shower",
			premium = true,
			source = 3147,
			group = {
				[3] = 2000
			},
			vocations = {
				2,
				6
			}
		},
		Thunderstorm = {
			maglevel = 4,
			type = "Conjure",
			soul = 3,
			mana = 430,
			level = 28,
			needTarget = false,
			parameter = false,
			words = "adori mas vis",
			id = 117,
			range = 0,
			exhaustion = 2000,
			name = "Thunderstorm",
			premium = true,
			source = 3147,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				5
			}
		},
		["Eternal Winter"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 1050,
			level = 60,
			needTarget = false,
			words = "exevo gran mas frigo",
			id = 118,
			exhaustion = 40000,
			name = "Eternal Winter",
			premium = true,
			range = 0,
			group = {
				[1] = 4000,
				[7] = 40000
			},
			vocations = {
				2,
				6
			},
			area = SpellAreas.AREA_CIRCLE5X5
		},
		["Rage of the Skies"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 600,
			level = 55,
			needTarget = false,
			words = "exevo gran mas vis",
			id = 119,
			exhaustion = 40000,
			name = "Rage of the Skies",
			premium = true,
			range = 0,
			group = {
				[1] = 4000,
				[7] = 40000
			},
			vocations = {
				1,
				5
			},
			area = SpellAreas.AREA_CIRCLE5X5
		},
		["Terra Wave"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 170,
			level = 38,
			needTarget = false,
			directional = true,
			words = "exevo tera hur",
			id = 120,
			exhaustion = 4000,
			name = "Terra Wave",
			premium = false,
			range = 0,
			group = {
				[1] = 2000
			},
			vocations = {
				2,
				6
			},
			area = SpellAreas.AREA_SQUAREWAVE4
		},
		["Ice Wave"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 25,
			level = 18,
			needTarget = false,
			directional = true,
			words = "exevo frigo hur",
			id = 121,
			exhaustion = 3000,
			name = "Ice Wave",
			premium = false,
			range = 0,
			group = {
				[1] = 2000
			},
			vocations = {
				2,
				6
			},
			area = SpellAreas.AREA_SQUAREWAVE5
		},
		["Divine Missile"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 20,
			level = 40,
			needTarget = false,
			words = "exori san",
			id = 122,
			exhaustion = 2000,
			name = "Divine Missile",
			premium = true,
			range = 4,
			group = {
				[1] = 2000
			},
			vocations = {
				3,
				7
			}
		},
		["Wound Cleansing"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 40,
			level = 8,
			needTarget = false,
			words = "exura ico",
			id = 123,
			exhaustion = 2000,
			name = "Wound Cleansing",
			premium = false,
			range = 0,
			group = {
				[2] = 2000
			},
			vocations = {
				4,
				8
			}
		},
		["Divine Caldera"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 160,
			level = 50,
			needTarget = false,
			words = "exevo mas san",
			id = 124,
			exhaustion = 4000,
			name = "Divine Caldera",
			premium = true,
			range = 0,
			group = {
				[1] = 2000
			},
			vocations = {
				3,
				7
			},
			area = SpellAreas.AREA_CIRCLE3X3
		},
		["Divine Healing"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 160,
			level = 35,
			needTarget = false,
			words = "exura san",
			id = 125,
			exhaustion = 1000,
			name = "Divine Healing",
			premium = false,
			range = 0,
			group = {
				[2] = 1000
			},
			vocations = {
				3,
				7
			}
		},
		["Train Party"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 60,
			level = 32,
			needTarget = false,
			words = "utito mas sio",
			id = 126,
			exhaustion = 2000,
			name = "Train Party",
			premium = true,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				4,
				8
			}
		},
		["Protect Party"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 90,
			level = 32,
			needTarget = false,
			words = "utamo mas sio",
			id = 127,
			exhaustion = 2000,
			name = "Protect Party",
			premium = true,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				3,
				7
			}
		},
		["Heal Party"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 120,
			level = 32,
			needTarget = false,
			words = "utura mas sio",
			id = 128,
			exhaustion = 2000,
			name = "Heal Party",
			premium = true,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				2,
				6
			}
		},
		["Enchant Party"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 120,
			level = 32,
			needTarget = false,
			words = "utori mas sio",
			id = 129,
			exhaustion = 2000,
			name = "Enchant Party",
			premium = true,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				5
			}
		},
		["Holy Missile"] = {
			maglevel = 4,
			type = "Conjure",
			soul = 3,
			mana = 300,
			level = 27,
			needTarget = false,
			parameter = false,
			words = "adori san",
			id = 130,
			range = 0,
			exhaustion = 2000,
			name = "Holy Missile",
			premium = true,
			source = 3147,
			group = {
				[3] = 2000
			},
			vocations = {
				3,
				7
			}
		},
		Charge = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 100,
			level = 25,
			needTarget = false,
			words = "utani tempo hur",
			id = 131,
			duration = 5000,
			exhaustion = 2000,
			name = "Charge",
			premium = true,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				4,
				8
			}
		},
		Protector = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 200,
			level = 55,
			needTarget = false,
			words = "utamo tempo",
			id = 132,
			exhaustion = 2000,
			name = "Protector",
			premium = true,
			range = 0,
			group = {
				[3] = 2000,
				[7] = 2000
			},
			vocations = {
				4,
				8
			}
		},
		["Blood Rage"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 290,
			level = 60,
			needTarget = false,
			words = "utito tempo",
			id = 133,
			exhaustion = 2000,
			name = "Blood Rage",
			premium = true,
			range = 0,
			group = {
				[3] = 2000,
				[7] = 2000
			},
			vocations = {
				4,
				8
			}
		},
		["Swift Foot"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 400,
			level = 55,
			needTarget = false,
			words = "utamo tempo san",
			id = 134,
			duration = 10000,
			exhaustion = 10000,
			name = "Swift Foot",
			premium = false,
			range = 0,
			group = {
				[3] = 2000,
				[7] = 10000
			},
			vocations = {
				3,
				7
			}
		},
		Sharpshooter = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 250,
			level = 20,
			needTarget = false,
			words = "utori con",
			id = 313,
			exhaustion = 10000,
			name = "Sharpshooter",
			premium = false,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				3,
				7
			}
		},
		Ignite = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 30,
			level = 26,
			needTarget = true,
			words = "utori flam",
			id = 138,
			exhaustion = 30000,
			name = "Ignite",
			premium = false,
			range = 3,
			group = {
				[1] = 2000
			},
			vocations = {
				1,
				5
			}
		},
		Curse = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 30,
			level = 75,
			needTarget = true,
			words = "utori mort",
			id = 139,
			exhaustion = 40000,
			name = "Curse",
			premium = false,
			range = 3,
			group = {
				[1] = 2000
			},
			vocations = {
				1,
				5
			}
		},
		Electrify = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 30,
			level = 34,
			needTarget = true,
			words = "utori vis",
			id = 140,
			exhaustion = 30000,
			name = "Electrify",
			premium = false,
			range = 3,
			group = {
				[1] = 2000
			},
			vocations = {
				1,
				5
			}
		},
		["Inflict Wound"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 30,
			level = 40,
			needTarget = true,
			words = "utori kor",
			id = 141,
			exhaustion = 30000,
			name = "Inflict Wound",
			premium = false,
			range = 1,
			group = {
				[1] = 2000
			},
			vocations = {
				4,
				8,
				9
			}
		},
		Envenom = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 30,
			level = 50,
			needTarget = true,
			words = "utori pox",
			id = 142,
			exhaustion = 40000,
			name = "Envenom",
			premium = false,
			range = 3,
			group = {
				[1] = 2000
			},
			vocations = {
				2,
				6
			}
		},
		["Holy Flash"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 30,
			level = 70,
			needTarget = true,
			words = "utori san",
			id = 143,
			exhaustion = 10000,
			name = "Holy Flash",
			premium = false,
			range = 3,
			group = {
				[1] = 2000
			},
			vocations = {
				3,
				7
			}
		},
		["Cure Bleeding"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 30,
			level = 45,
			needTarget = false,
			words = "exana kor",
			id = 144,
			exhaustion = 6000,
			name = "Cure Bleeding",
			premium = false,
			range = 0,
			group = {
				[2] = 1000
			},
			vocations = {
				2,
				4,
				6,
				8
			}
		},
		["Cure Burning"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 30,
			level = 30,
			needTarget = false,
			words = "exana flam",
			id = 145,
			exhaustion = 6000,
			name = "Cure Burning",
			premium = false,
			range = 0,
			group = {
				[2] = 1000
			},
			vocations = {
				2,
				6
			}
		},
		["Cure Electrification"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 30,
			level = 22,
			needTarget = false,
			words = "exana vis",
			id = 146,
			exhaustion = 6000,
			name = "Cure Electrification",
			premium = false,
			range = 0,
			group = {
				[2] = 1000
			},
			vocations = {
				2,
				6
			}
		},
		["Cure Curse"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 40,
			level = 80,
			needTarget = false,
			words = "exana mort",
			id = 147,
			exhaustion = 6000,
			name = "Cure Curse",
			premium = false,
			range = 0,
			group = {
				[2] = 1000
			},
			vocations = {
				3,
				7
			}
		},
		["Physical Strike"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 20,
			level = 16,
			needTarget = false,
			words = "exori moe ico",
			id = 148,
			exhaustion = 2000,
			name = "Physical Strike",
			premium = true,
			range = 3,
			group = {
				[1] = 2000
			},
			vocations = {
				2,
				6
			}
		},
		Lightning = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 60,
			level = 55,
			needTarget = false,
			words = "exori amp vis",
			id = 149,
			exhaustion = 6000,
			name = "Lightning",
			premium = true,
			range = 4,
			group = {
				[1] = 2000,
				[4] = 8000
			},
			vocations = {
				1,
				5
			}
		},
		["Strong Flame Strike"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 60,
			level = 70,
			needTarget = false,
			words = "exori gran flam",
			id = 150,
			exhaustion = 8000,
			name = "Strong Flame Strike",
			premium = true,
			range = 3,
			group = {
				[1] = 2000,
				[4] = 8000
			},
			vocations = {
				1,
				5
			}
		},
		["Strong Energy Strike"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 60,
			level = 80,
			needTarget = false,
			words = "exori gran vis",
			id = 151,
			exhaustion = 8000,
			name = "Strong Energy Strike",
			premium = true,
			range = 3,
			group = {
				[1] = 2000,
				[4] = 8000
			},
			vocations = {
				1,
				5
			}
		},
		["Strong Ice Strike"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 60,
			level = 80,
			needTarget = false,
			words = "exori gran frigo",
			id = 152,
			exhaustion = 8000,
			name = "Strong Ice Strike",
			premium = true,
			range = 3,
			group = {
				[1] = 2000,
				[4] = 8000
			},
			vocations = {
				2,
				6
			}
		},
		["Strong Terra Strike"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 60,
			level = 70,
			needTarget = false,
			words = "exori gran tera",
			id = 153,
			exhaustion = 8000,
			name = "Strong Terra Strike",
			premium = true,
			range = 3,
			group = {
				[1] = 2000,
				[4] = 8000
			},
			vocations = {
				2,
				6
			}
		},
		["Ultimate Flame Strike"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 100,
			level = 90,
			needTarget = false,
			words = "exori max flam",
			id = 154,
			exhaustion = 30000,
			name = "Ultimate Flame Strike",
			premium = true,
			range = 3,
			group = {
				[1] = 2000,
				[8] = 30000
			},
			vocations = {
				1,
				5
			}
		},
		["Ultimate Energy Strike"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 100,
			level = 100,
			needTarget = false,
			words = "exori max vis",
			id = 155,
			exhaustion = 30000,
			name = "Ultimate Energy Strike",
			premium = true,
			range = 3,
			group = {
				[1] = 2000,
				[8] = 30000
			},
			vocations = {
				1,
				5
			}
		},
		["Ultimate Ice Strike"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 100,
			level = 100,
			needTarget = false,
			words = "exori max frigo",
			id = 156,
			exhaustion = 30000,
			name = "Ultimate Ice Strike",
			premium = true,
			range = 3,
			group = {
				[1] = 2000,
				[8] = 30000
			},
			vocations = {
				2,
				6
			}
		},
		["Ultimate Terra Strike"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 100,
			level = 90,
			needTarget = false,
			words = "exori max tera",
			id = 157,
			exhaustion = 30000,
			name = "Ultimate Terra Strike",
			premium = true,
			range = 3,
			group = {
				[1] = 2000,
				[8] = 30000
			},
			vocations = {
				2,
				6
			}
		},
		["Intense Wound Cleansing"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 200,
			level = 80,
			needTarget = false,
			words = "exura gran ico",
			id = 158,
			exhaustion = 120000,
			name = "Intense Wound Cleansing",
			premium = true,
			range = 0,
			group = {
				[2] = 2000
			},
			vocations = {
				4,
				8
			}
		},
		Recovery = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 75,
			level = 50,
			needTarget = false,
			words = "utura",
			id = 159,
			exhaustion = 60000,
			name = "Recovery",
			premium = false,
			range = 0,
			group = {
				[2] = 1000
			},
			vocations = {
				3,
				4,
				7,
				8
			}
		},
		["Intense Recovery"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 165,
			level = 100,
			needTarget = false,
			words = "utura gran",
			id = 160,
			exhaustion = 60000,
			name = "Intense Recovery",
			premium = false,
			range = 0,
			group = {
				[2] = 1000
			},
			vocations = {
				3,
				4,
				7,
				8
			}
		},
		["Practise Healing"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 5,
			level = 1,
			needTarget = false,
			words = "exura dis",
			id = 166,
			exhaustion = 1000,
			name = "Practise Healing",
			premium = false,
			range = 0,
			group = {
				[2] = 1000
			},
			vocations = {
				0
			}
		},
		["Practise Fire Wave"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 5,
			level = 1,
			needTarget = false,
			directional = true,
			words = "exevo dis flam hur",
			id = 167,
			exhaustion = 3000,
			name = "Practise Fire Wave",
			premium = false,
			range = 0,
			group = {
				[1] = 2000
			},
			vocations = {
				0
			},
			area = SpellAreas.AREA_SQUAREWAVE5
		},
		["Apprentice's Strike"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 6,
			level = 8,
			needTarget = false,
			words = "exori min flam",
			id = 169,
			exhaustion = 2000,
			name = "Apprentice's Strike",
			premium = false,
			range = 3,
			group = {
				[1] = 2000
			},
			vocations = {
				1,
				2,
				5,
				6
			}
		},
		["Bruise Bane"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 10,
			level = 1,
			needTarget = false,
			words = "exura infir ico",
			id = 175,
			exhaustion = 2000,
			name = "Bruise Bane",
			premium = false,
			range = 0,
			group = {
				[2] = 2000
			},
			vocations = {
				4,
				8
			}
		},
		["Mud Attack"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 6,
			level = 1,
			needTarget = false,
			words = "exori infir tera",
			id = 172,
			exhaustion = 2000,
			name = "Mud Attack",
			premium = false,
			range = 3,
			group = {
				[1] = 2000
			},
			vocations = {
				2,
				6
			}
		},
		["Chill Out"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 8,
			level = 1,
			needTarget = false,
			directional = true,
			words = "exevo infir frigo hur",
			id = 173,
			exhaustion = 4000,
			name = "Chill Out",
			premium = false,
			range = 0,
			group = {
				[1] = 2000
			},
			vocations = {
				2,
				6
			},
			area = SpellAreas.AREA_SQUAREWAVE5
		},
		["Magic Patch"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 6,
			level = 1,
			needTarget = false,
			words = "exura infir",
			id = 174,
			exhaustion = 1000,
			name = "Magic Patch",
			premium = false,
			range = 0,
			group = {
				[2] = 1000
			},
			vocations = {
				1,
				2,
				3,
				5,
				6,
				7,
				9,
				10
			}
		},
		["Arrow Call"] = {
			parameter = false,
			type = "Conjure",
			soul = 1,
			mana = 10,
			level = 1,
			needTarget = false,
			words = "exevo infir con",
			id = 176,
			exhaustion = 2000,
			name = "Arrow Call",
			premium = false,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				3,
				7
			}
		},
		Buzz = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 6,
			level = 1,
			needTarget = false,
			words = "exori infir vis",
			id = 177,
			exhaustion = 2000,
			name = "Buzz",
			premium = false,
			range = 3,
			group = {
				[1] = 2000
			},
			vocations = {
				1,
				5
			}
		},
		Scorch = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 8,
			level = 1,
			needTarget = false,
			directional = true,
			words = "exevo infir flam hur",
			id = 178,
			exhaustion = 3000,
			name = "Scorch",
			premium = false,
			range = 0,
			group = {
				[1] = 2000
			},
			vocations = {
				1,
				5
			},
			area = SpellAreas.AREA_SQUAREWAVE5
		},
		["Summon Knight Familiar"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 2000,
			level = 200,
			needTarget = false,
			words = "utevo gran res eq",
			id = 194,
			exhaustion = 1800000,
			name = "Summon Knight Familiar",
			premium = false,
			range = 0,
			group = {
				[3] = 4000
			},
			vocations = {
				8
			}
		},
		["Summon Paladin Familiar"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 2000,
			level = 200,
			needTarget = false,
			words = "utevo gran res sac",
			id = 195,
			exhaustion = 1800000,
			name = "Summon Paladin Familiar",
			premium = false,
			range = 0,
			group = {
				[3] = 4000
			},
			vocations = {
				7
			}
		},
		["Summon Sorcerer Familiar"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 3000,
			level = 200,
			needTarget = false,
			words = "utevo gran res ven",
			id = 196,
			exhaustion = 1800000,
			name = "Summon Sorcerer Familiar",
			premium = false,
			range = 0,
			group = {
				[3] = 4000
			},
			vocations = {
				5
			}
		},
		["Summon Druid Familiar"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 3000,
			level = 200,
			needTarget = false,
			words = "utevo gran res dru",
			id = 197,
			exhaustion = 1800000,
			name = "Summon Druid Familiar",
			premium = false,
			range = 0,
			group = {
				[3] = 4000
			},
			vocations = {
				6
			}
		},
		["Chivalrous Challenge"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 80,
			level = 150,
			needTarget = false,
			words = "exeta amp res",
			id = 237,
			exhaustion = 2000,
			name = "Chivalrous Challenge",
			premium = true,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				4,
				8
			}
		},
		["Divine Dazzle"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 80,
			level = 250,
			needTarget = false,
			words = "exana amp res",
			id = 238,
			exhaustion = 16000,
			name = "Divine Dazzle",
			premium = true,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				3,
				7
			}
		},
		["Fair Wound Cleansing"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 90,
			level = 300,
			needTarget = false,
			words = "exura med ico",
			id = 239,
			exhaustion = 2000,
			name = "Fair Wound Cleansing",
			premium = true,
			range = 0,
			group = {
				[2] = 2000
			},
			vocations = {
				4,
				8
			}
		},
		["Great Fire Wave"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 120,
			level = 38,
			needTarget = false,
			directional = true,
			words = "exevo gran flam hur",
			id = 240,
			exhaustion = 4000,
			name = "Great Fire Wave",
			premium = false,
			range = 0,
			group = {
				[1] = 2000
			},
			vocations = {
				1,
				5
			},
			area = SpellAreas.AREA_SQUAREWAVE6
		},
		Restoration = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 260,
			level = 300,
			needTarget = false,
			words = "exura max vita",
			id = 241,
			exhaustion = 6000,
			name = "Restoration",
			premium = false,
			range = 0,
			group = {
				[2] = 1000
			},
			vocations = {
				1,
				2,
				5,
				6
			}
		},
		["Nature's Embrace"] = {
			parameter = true,
			type = "Instant",
			soul = 0,
			mana = 400,
			level = 275,
			needTarget = true,
			parameterPlaceholder = "name",
			words = "exura gran sio",
			id = 242,
			exhaustion = 60000,
			name = "Nature's Embrace",
			premium = true,
			range = 0,
			group = {
				[2] = 1000
			},
			vocations = {
				2,
				6
			}
		},
		["Aura of Exposed Weakness"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 1500,
			level = 175,
			needTarget = false,
			words = "exori moe tempo",
			id = 311,
			exhaustion = 30000,
			name = "Aura of Exposed Weakness",
			premium = false,
			range = 0,
			group = {
				[3] = 2000,
				[6] = 2000
			},
			vocations = {
				1,
				5
			}
		},
		["Aura of Sapped Strength"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 1500,
			level = 175,
			needTarget = false,
			words = "exori kor tempo",
			id = 312,
			exhaustion = 30000,
			name = "Aura of Sapped Strength",
			premium = false,
			range = 0,
			group = {
				[3] = 2000,
				[6] = 2000
			},
			vocations = {
				1,
				5
			}
		},
		["Cancel Magic Shield"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 50,
			level = 14,
			needTarget = false,
			words = "exana vita",
			id = 245,
			exhaustion = 2000,
			name = "Cancel Magic Shield",
			premium = false,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				5,
				2,
				6
			}
		},
		["Find Fiend"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 20,
			level = 25,
			needTarget = false,
			words = "exiva moe res",
			id = 248,
			exhaustion = 2000,
			name = "Find Fiend",
			premium = false,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				1,
				2,
				3,
				4,
				5,
				6,
				7,
				8,
				9,
				10
			}
		},
		["Divine Grenade"] = {
			parameter = false,
			needTarget = false,
			special = true,
			soul = 0,
			mana = 160,
			level = 0,
			words = "exevo tempo mas san",
			id = 258,
			crossHairTarget = true,
			exhaustion = 26000,
			name = "Divine Grenade",
			type = "Instant",
			premium = false,
			range = 5,
			group = {
				[1] = 2000
			},
			vocations = {
				7
			},
			area = SpellAreas.AREA_CIRCLE2X2
		},
		["Great Death Beam"] = {
			parameter = false,
			needTarget = false,
			special = true,
			soul = 0,
			mana = 140,
			level = 0,
			directional = true,
			words = "exevo max mort",
			id = 260,
			exhaustion = 10000,
			name = "Great Death Beam",
			type = "Instant",
			premium = false,
			range = 0,
			group = {
				[1] = 2000,
				[9] = 6000
			},
			vocations = {
				5
			},
			area = SpellAreas.AREA_BEAM8
		},
		["Executioner's Throw"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 225,
			level = 300,
			needTarget = true,
			words = "exori amp kor",
			id = 261,
			special = true,
			exhaustion = 2000,
			name = "Executioner's Throw",
			premium = false,
			range = 5,
			group = {
				[1] = 2000
			},
			vocations = {
				4,
				8
			}
		},
		["Ice Burst"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 230,
			level = 300,
			needTarget = false,
			words = "exevo ulus frigo",
			id = 262,
			special = true,
			exhaustion = 2000,
			name = "Ice Burst",
			premium = false,
			range = 0,
			group = {
				[1] = 2000,
				[10] = 2000
			},
			vocations = {
				2,
				6
			},
			area = SpellAreas.AREA_RING_BURST3
		},
		["Terra Burst"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 230,
			level = 300,
			needTarget = false,
			words = "exevo ulus tera",
			id = 263,
			special = true,
			exhaustion = 2000,
			name = "Terra Burst",
			premium = false,
			range = 0,
			group = {
				[1] = 2000,
				[10] = 2000
			},
			vocations = {
				2,
				6
			},
			area = SpellAreas.AREA_RING_BURST3
		},
		["Avatar of Steel"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 800,
			level = 0,
			needTarget = false,
			words = "uteta res eq",
			id = 264,
			special = true,
			exhaustion = 7200000,
			name = "Avatar of Steel",
			premium = false,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				8
			}
		},
		["Avatar of Light"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 800,
			level = 0,
			needTarget = false,
			words = "uteta res sac",
			id = 265,
			special = true,
			exhaustion = 7200000,
			name = "Avatar of Light",
			premium = false,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				7
			}
		},
		["Avatar of Storm"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 800,
			level = 0,
			needTarget = false,
			words = "uteta res ven",
			id = 266,
			special = true,
			exhaustion = 7200000,
			name = "Avatar of Storm",
			premium = false,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				5
			}
		},
		["Avatar of Nature"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 800,
			level = 0,
			needTarget = false,
			words = "uteta res dru",
			id = 267,
			special = true,
			exhaustion = 7200000,
			name = "Avatar of Nature",
			premium = false,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				6
			}
		},
		["Divine Empowerment"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 500,
			level = 0,
			needTarget = false,
			words = "utevo grav san",
			id = 268,
			special = true,
			exhaustion = 32000,
			name = "Divine Empowerment",
			premium = false,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				7
			},
			area = SpellAreas.AREA_CIRCLE2X2
		},
		["Lesser Ethereal Spear"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 6,
			level = 1,
			needTarget = true,
			words = "exori infir con",
			id = 270,
			exhaustion = 8000,
			name = "Lesser Ethereal Spear",
			premium = false,
			range = 7,
			group = {
				[1] = 2000
			},
			vocations = {
				3,
				7
			}
		},
		["Lesser Front Sweep"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 6,
			level = 1,
			needTarget = false,
			words = "exori infir min",
			id = 271,
			exhaustion = 6000,
			name = "Lesser Front Sweep",
			premium = false,
			range = 1,
			group = {
				[1] = 2000
			},
			vocations = {
				4,
				8
			},
			area = SpellAreas.AREA_SQUAREWAVE1
		},
		["Spirit Mend"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 210,
			level = 80,
			needTarget = false,
			words = "exura gran tio",
			id = 273,
			exhaustion = 1000,
			name = "Spirit Mend",
			premium = false,
			range = 0,
			group = {
				[2] = 1000
			},
			vocations = {
				9,
				10
			}
		},
		["Virtue of Harmony"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 210,
			level = 20,
			needTarget = false,
			words = "utori virtu",
			id = 274,
			exhaustion = 10000,
			name = "Virtue of Harmony",
			premium = false,
			range = 0,
			group = {
				[3] = 2000,
				[11] = 10000
			},
			vocations = {
				9,
				10
			}
		},
		["Virtue of Justice"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 210,
			level = 20,
			needTarget = false,
			words = "utito virtu",
			id = 275,
			exhaustion = 10000,
			name = "Virtue of Justice",
			premium = false,
			range = 0,
			group = {
				[3] = 2000,
				[11] = 10000
			},
			vocations = {
				9,
				10
			}
		},
		["Virtue of Sustain"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 210,
			level = 20,
			needTarget = false,
			words = "utura tio",
			id = 276,
			exhaustion = 10000,
			name = "Virtue of Sustain",
			premium = false,
			range = 0,
			group = {
				[3] = 2000,
				[11] = 10000
			},
			vocations = {
				9,
				10
			}
		},
		["Enlighten Party"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 75,
			level = 32,
			needTarget = false,
			words = "utevo mas sio",
			id = 278,
			exhaustion = 300000,
			name = "Enlighten Party",
			premium = false,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				9,
				10
			}
		},
		["Focus Harmony"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 500,
			level = 275,
			needTarget = false,
			needLearn = true,
			words = "utevo nia",
			id = 279,
			exhaustion = 120000,
			name = "Focus Harmony",
			premium = false,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				9,
				10
			}
		},
		["Balanced Brawl"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 80,
			level = 175,
			needTarget = false,
			directional = true,
			words = "exori mas res",
			id = 280,
			exhaustion = 10000,
			name = "Balanced Brawl",
			premium = false,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				9,
				10
			}
		},
		["Focus Serenity"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 500,
			level = 150,
			needTarget = false,
			words = "utamo tio",
			id = 281,
			exhaustion = 600000,
			name = "Focus Serenity",
			premium = false,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				9,
				10
			}
		},
		["Summon Monk Familiar"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 1500,
			level = 200,
			needTarget = false,
			words = "utevo gran res tio",
			id = 282,
			exhaustion = 1800000,
			name = "Summon Monk Familiar",
			premium = false,
			range = 0,
			group = {
				[3] = 4000
			},
			vocations = {
				9,
				10
			}
		},
		["Avatar of Balance"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 1200,
			level = 0,
			needTarget = false,
			words = "uteta res tio",
			id = 283,
			special = true,
			exhaustion = 7200000,
			name = "Avatar of Balance",
			premium = false,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				9,
				10
			}
		},
		["Swift Jab"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 3,
			level = 0,
			needTarget = true,
			words = "exori infir pug",
			id = 284,
			exhaustion = 2000,
			name = "Swift Jab",
			premium = true,
			range = 1,
			group = {
				[1] = 2000
			},
			vocations = {
				9,
				10
			}
		},
		["Double Jab"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 35,
			level = 14,
			needTarget = true,
			words = "exori pug",
			id = 285,
			exhaustion = 4000,
			name = "Double Jab",
			premium = true,
			range = 1,
			group = {
				[1] = 2000
			},
			vocations = {
				9,
				10
			}
		},
		["Forceful Uppercut"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 325,
			level = 110,
			needTarget = true,
			needLearn = true,
			words = "exori gran pug",
			id = 286,
			exhaustion = 60000,
			name = "Forceful Uppercut",
			premium = true,
			range = 1,
			group = {
				[1] = 2000
			},
			vocations = {
				9,
				10
			}
		},
		["Flurry of Blows"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 125,
			level = 35,
			needTarget = false,
			directional = true,
			words = "exori mas pug",
			id = 287,
			exhaustion = 4000,
			name = "Flurry of Blows",
			premium = true,
			range = 0,
			group = {
				[1] = 2000
			},
			vocations = {
				9,
				10
			},
			area = SpellAreas.AREA_FLURRYWAVE
		},
		["Chained Penance"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 180,
			level = 70,
			needTarget = true,
			words = "exori med pug",
			id = 288,
			exhaustion = 4000,
			name = "Chained Penance",
			premium = true,
			range = 2,
			group = {
				[1] = 2000
			},
			vocations = {
				9,
				10
			}
		},
		["Greater Flurry of Blows"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 315,
			level = 90,
			needTarget = false,
			directional = true,
			words = "exori gran mas pug",
			id = 289,
			exhaustion = 16000,
			name = "Greater Flurry of Blows",
			premium = true,
			range = 0,
			group = {
				[1] = 2000
			},
			vocations = {
				9,
				10
			},
			area = SpellAreas.AREA_GREATER_FLURRYWAVE
		},
		["Mystic Repulse"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 175,
			level = 30,
			needTarget = true,
			needLearn = true,
			words = "exori amp pug",
			id = 290,
			exhaustion = 20000,
			name = "Mystic Repulse",
			premium = true,
			range = 7,
			group = {
				[1] = 2000
			},
			vocations = {
				9,
				10
			}
		},
		["Tiger Clash"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 18,
			level = 0,
			needTarget = true,
			exhaustion = 8000,
			words = "exori infir nia",
			id = 291,
			useHarmony = true,
			spender = true,
			name = "Tiger Clash",
			premium = true,
			range = 1,
			group = {
				[1] = 2000
			},
			vocations = {
				9,
				10
			}
		},
		["Greater Tiger Clash"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 50,
			level = 18,
			needTarget = true,
			exhaustion = 8000,
			words = "exori nia",
			id = 292,
			useHarmony = true,
			spender = true,
			name = "Greater Tiger Clash",
			premium = true,
			range = 1,
			group = {
				[1] = 2000
			},
			vocations = {
				9,
				10
			}
		},
		["Devastating Knockout"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 210,
			level = 125,
			needTarget = true,
			exhaustion = 24000,
			words = "exori gran nia",
			id = 293,
			useHarmony = true,
			spender = true,
			name = "Devastating Knockout",
			premium = true,
			range = 1,
			group = {
				[1] = 2000
			},
			vocations = {
				9,
				10
			}
		},
		["Sweeping Takedown"] = {
			parameter = false,
			needTarget = false,
			soul = 0,
			mana = 195,
			level = 60,
			directional = true,
			words = "exori mas nia",
			id = 294,
			exhaustion = 8000,
			name = "Sweeping Takedown",
			type = "Instant",
			useHarmony = true,
			spender = true,
			premium = true,
			range = 0,
			group = {
				[1] = 2000
			},
			vocations = {
				9,
				10
			},
			area = SpellAreas.AREA_SHORTWAVE4
		},
		["Spiritual Outburst"] = {
			parameter = false,
			needTarget = true,
			soul = 0,
			mana = 425,
			level = 0,
			special = true,
			words = "exori gran mas nia",
			id = 295,
			exhaustion = 24000,
			name = "Spiritual Outburst",
			type = "Instant",
			useHarmony = true,
			spender = true,
			premium = true,
			range = 2,
			group = {
				[1] = 2000
			},
			vocations = {
				9,
				10
			}
		},
		["Mass Spirit Mend"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 250,
			level = 150,
			needTarget = false,
			words = "exura mas nia",
			id = 296,
			exhaustion = 12000,
			name = "Mass Spirit Mend",
			premium = false,
			range = 0,
			group = {
				[2] = 1000
			},
			vocations = {
				9,
				10
			}
		},
		["Restore Balance"] = {
			parameter = true,
			type = "Instant",
			soul = 0,
			mana = 120,
			level = 18,
			needTarget = true,
			parameterPlaceholder = "name",
			words = "exura tio sio",
			id = 297,
			exhaustion = 2000,
			name = "Restore Balance",
			premium = true,
			range = 7,
			group = {
				[2] = 1000
			},
			vocations = {
				9,
				10
			}
		},
		["Lesser Mystic Repulse"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 30,
			level = 6,
			needTarget = true,
			needLearn = true,
			words = "exori infir amp pug",
			id = 298,
			exhaustion = 20000,
			name = "Lesser Mystic Repulse",
			premium = false,
			range = 7,
			group = {
				[1] = 2000
			},
			vocations = {
				9,
				10
			}
		},
		["Thousand Fist Blows"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 145,
			level = 120,
			needTarget = true,
			words = "exori mas amp pug",
			id = 301,
			exhaustion = 12000,
			crossHairTarget = true,
			name = "Thousand Fist Blows",
			premium = false,
			range = 7,
			group = {
				[1] = 2000
			},
			vocations = {
				9,
				10
			},
			area = SpellAreas.AREA_CIRCLE2X2
		},
		["Divine Barrage"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 175,
			level = 70,
			needTarget = false,
			words = "exori dir san",
			id = 302,
			exhaustion = 4000,
			crossHairTarget = true,
			name = "Divine Barrage",
			premium = false,
			range = 7,
			group = {
				[1] = 2000
			},
			vocations = {
				3,
				7
			},
			area = SpellAreas.AREA_CIRCLE2X2
		},
		["Ethereal Barrage"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 135,
			level = 60,
			needTarget = false,
			words = "exori dir moe",
			id = 303,
			exhaustion = 4000,
			crossHairTarget = true,
			name = "Ethereal Barrage",
			premium = false,
			range = 7,
			group = {
				[1] = 2000
			},
			vocations = {
				3,
				7
			},
			area = SpellAreas.AREA_CIRCLE2X2
		},
		["Master of Flames"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 400,
			level = 20,
			needTarget = false,
			words = "uteta flam",
			id = 304,
			exhaustion = 30000,
			name = "Master of Flames",
			premium = false,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				5
			}
		},
		["Master of Thunder"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 400,
			level = 20,
			needTarget = false,
			words = "uteta vis",
			id = 305,
			exhaustion = 30000,
			name = "Master of Thunder",
			premium = false,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				5
			}
		},
		["Master of Decay"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 400,
			level = 20,
			needTarget = false,
			words = "uteta mort",
			id = 306,
			exhaustion = 30000,
			name = "Master of Decay",
			premium = false,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				5
			}
		},
		["Elemental Synthesis"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 400,
			level = 20,
			needTarget = false,
			words = "utito dru",
			id = 319,
			exhaustion = 10000,
			name = "Elemental Synthesis",
			premium = false,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				6
			}
		},
		["Shared Conservation"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 400,
			level = 20,
			needTarget = false,
			words = "utura sio",
			id = 309,
			exhaustion = 10000,
			name = "Shared Conservation",
			premium = false,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				6
			}
		},
		["Death Echo"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 155,
			level = 120,
			needTarget = false,
			words = "exevo mort ora",
			id = 310,
			exhaustion = 6000,
			crossHairTarget = true,
			name = "Death Echo",
			premium = false,
			range = 7,
			group = {
				[1] = 2000
			},
			vocations = {
				1,
				5
			},
			area = SpellAreas.AREA_SQUARE2X2
		},
		["Divine Defiance"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 250,
			level = 20,
			needTarget = false,
			words = "utori hur",
			id = 314,
			exhaustion = 10000,
			name = "Divine Defiance",
			premium = false,
			range = 0,
			group = {
				[3] = 2000
			},
			vocations = {
				3,
				7
			}
		},
		["Shield Bash"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 30,
			level = 18,
			needTarget = true,
			words = "exori ico scu",
			id = 315,
			exhaustion = 4000,
			name = "Shield Bash",
			premium = false,
			range = 1,
			group = {
				[1] = 2000
			},
			vocations = {
				4,
				8
			}
		},
		["Shield Slam"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 110,
			level = 30,
			needTarget = false,
			words = "exori scu",
			id = 316,
			exhaustion = 6000,
			name = "Shield Slam",
			premium = false,
			range = 0,
			group = {
				[1] = 2000
			},
			vocations = {
				4,
				8
			},
			area = SpellAreas.AREA_CIRCLE1X1
		},
		["Forked Glacier"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 180,
			level = 90,
			needTarget = false,
			words = "exevo fur frigo",
			id = 317,
			exhaustion = 6000,
			name = "Forked Glacier",
			premium = false,
			range = 7,
			group = {
				[1] = 2000,
				[4] = 6000
			},
			vocations = {
				2,
				6
			},
			area = SpellAreas.AREA_FORKS
		},
		["Forked Thorns"] = {
			parameter = false,
			type = "Instant",
			soul = 0,
			mana = 180,
			level = 80,
			needTarget = false,
			words = "exevo fur tera",
			id = 318,
			exhaustion = 6000,
			name = "Forked Thorns",
			premium = false,
			range = 7,
			group = {
				[1] = 2000,
				[4] = 6000
			},
			vocations = {
				2,
				6
			},
			area = SpellAreas.AREA_FORKS
		}
	}
}
SpellIconsFirstIsZero = {
	5,
	6,
	0,
	73,
	61,
	100,
	72,
	76,
	115,
	114,
	113,
	89,
	42,
	90,
	78,
	77,
	81,
	82,
	43,
	111,
	63,
	40,
	41,
	48,
	80,
	68,
	84,
	79,
	9,
	86,
	88,
	67,
	83,
	nil,
	nil,
	59,
	nil,
	99,
	101,
	nil,
	nil,
	98,
	45,
	120,
	93,
	nil,
	nil,
	nil,
	108,
	66,
	105,
	nil,
	nil,
	70,
	85,
	47,
	58,
	nil,
	19,
	nil,
	22,
	23,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	112,
	104,
	65,
	87,
	nil,
	20,
	121,
	8,
	92,
	7,
	nil,
	71,
	37,
	28,
	25,
	94,
	69,
	138,
	96,
	60,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	21,
	24,
	18,
	nil,
	nil,
	103,
	17,
	31,
	34,
	74,
	91,
	64,
	62,
	49,
	51,
	46,
	44,
	38,
	2,
	39,
	1,
	117,
	119,
	122,
	110,
	75,
	97,
	118,
	95,
	116,
	nil,
	nil,
	nil,
	54,
	53,
	55,
	56,
	57,
	52,
	11,
	12,
	13,
	10,
	16,
	50,
	26,
	29,
	32,
	35,
	27,
	30,
	33,
	36,
	3,
	14,
	15,
	nil,
	nil,
	nil,
	nil,
	nil,
	124,
	125,
	126,
	123,
	nil,
	nil,
	133,
	132,
	130,
	131,
	134,
	129,
	128,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	139,
	141,
	142,
	140,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	109,
	135,
	4,
	102,
	107,
	106,
	nil,
	nil,
	143,
	nil,
	nil,
	144,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	nil,
	152,
	nil,
	154,
	149,
	150,
	151,
	145,
	147,
	148,
	146,
	155,
	nil,
	156,
	157,
	nil,
	158,
	159,
	160,
	161,
	nil,
	163,
	164,
	165,
	166,
	167,
	168,
	169,
	170,
	171,
	172,
	173,
	174,
	175,
	176,
	177,
	178,
	179,
	180,
	181,
	182,
	183,
	nil,
	183,
	184,
	185,
	186,
	187,
	188,
	189,
	nil,
	190,
	191,
	192,
	199,
	200,
	193,
	194,
	195,
	196,
	197,
	198,
	190
}
SpellIcons = {}

for id, icon in pairs(SpellIconsFirstIsZero) do
	SpellIcons[id] = icon + 1
end

VocationNames = {
	[0] = "None",
	"Sorcerer",
	"Druid",
	"Paladin",
	"Knight",
	"Master Sorcerer",
	"Elder Druid",
	"Royal Paladin",
	"Elite Knight",
	"Monk",
	"Exalted Monk"
}
SpellGroups = {
	"Attack",
	"Healing",
	"Support",
	"Special",
	"Conjure",
	"Crippling",
	"Focus",
	"Ultimate Strikes",
	"Great Beams",
	"Bursts of Nature",
	"Virtue"
}
SpellGroupIconFile = "/images/game/spells/spellgroup-icons-20x20"
SpellGroupIconSize = {
	width = 20,
	height = 20
}
SpellRunesData = {
	[3148] = {
		groupExhaustion = 1500,
		id = 30,
		group = 3,
		exhaustion = 2000,
		name = "destroy field rune"
	},
	[3149] = {
		groupExhaustion = 1500,
		id = 55,
		group = 1,
		exhaustion = 2000,
		name = "energybomb rune"
	},
	[3152] = {
		groupExhaustion = 2000,
		id = 4,
		group = 2,
		exhaustion = 2000,
		name = "intense healing rune"
	},
	[3153] = {
		groupExhaustion = 2000,
		id = 31,
		group = 2,
		exhaustion = 2000,
		name = "antidote rune"
	},
	[3155] = {
		groupExhaustion = 2000,
		id = 21,
		group = 1,
		exhaustion = 2000,
		name = "sudden death rune"
	},
	[3156] = {
		groupExhaustion = 1500,
		id = 94,
		group = 1,
		exhaustion = 2000,
		name = "Wild Growth Rune"
	},
	[3158] = {
		groupExhaustion = 1500,
		id = 114,
		group = 1,
		exhaustion = 2000,
		name = "icicle rune"
	},
	[3160] = {
		groupExhaustion = 1500,
		id = 5,
		group = 2,
		exhaustion = 2000,
		name = "ultimate healing rune"
	},
	[3161] = {
		groupExhaustion = 1500,
		id = 115,
		group = 1,
		exhaustion = 2000,
		name = "avalanche rune"
	},
	[3164] = {
		groupExhaustion = 1500,
		id = 27,
		group = 1,
		exhaustion = 2000,
		name = "energy field rune"
	},
	[3165] = {
		groupExhaustion = 2000,
		id = 54,
		group = 3,
		exhaustion = 4000,
		name = "paralyze rune"
	},
	[3166] = {
		groupExhaustion = 1500,
		id = 33,
		group = 1,
		exhaustion = 2000,
		name = "energy wall rune"
	},
	[3172] = {
		groupExhaustion = 2000,
		id = 26,
		group = 1,
		exhaustion = 2000,
		name = "poison field rune"
	},
	[3173] = {
		groupExhaustion = 1500,
		id = 91,
		group = 1,
		exhaustion = 2000,
		name = "poison bomb rune"
	},
	[3174] = {
		groupExhaustion = 1500,
		id = 7,
		group = 1,
		exhaustion = 2000,
		name = "light magic missile rune"
	},
	[3175] = {
		groupExhaustion = 1500,
		id = 116,
		group = 1,
		exhaustion = 2000,
		name = "stone shower rune"
	},
	[3176] = {
		groupExhaustion = 1500,
		id = 32,
		group = 1,
		exhaustion = 2000,
		name = "poison wall rune"
	},
	[3177] = {
		groupExhaustion = 1500,
		id = 12,
		group = 3,
		exhaustion = 2000,
		name = "convince creature rune"
	},
	[3178] = {
		groupExhaustion = 1500,
		id = 14,
		group = 3,
		exhaustion = 2000,
		name = "chameleon rune"
	},
	[3179] = {
		groupExhaustion = 1500,
		id = 77,
		group = 1,
		exhaustion = 2000,
		name = "stalagmite rune"
	},
	[3180] = {
		groupExhaustion = 2000,
		id = 86,
		group = 1,
		exhaustion = 2000,
		name = "Magic Wall Rune"
	},
	[3182] = {
		groupExhaustion = 2000,
		id = 130,
		group = 1,
		exhaustion = 2000,
		name = "holy missile rune"
	},
	[3188] = {
		groupExhaustion = 1500,
		id = 25,
		group = 1,
		exhaustion = 2000,
		name = "fire field rune"
	},
	[3189] = {
		groupExhaustion = 1500,
		id = 15,
		group = 1,
		exhaustion = 2000,
		name = "fireball rune"
	},
	[3190] = {
		groupExhaustion = 1500,
		id = 28,
		group = 1,
		exhaustion = 2000,
		name = "fire wall rune"
	},
	[3191] = {
		groupExhaustion = 1500,
		id = 16,
		group = 1,
		exhaustion = 2000,
		name = "great fireball rune"
	},
	[3192] = {
		groupExhaustion = 1500,
		id = 17,
		group = 1,
		exhaustion = 2000,
		name = "firebomb rune"
	},
	[3195] = {
		groupExhaustion = 1500,
		id = 50,
		group = 1,
		exhaustion = 2000,
		name = "soulfire rune"
	},
	[3197] = {
		groupExhaustion = 2000,
		id = 78,
		group = 3,
		exhaustion = 2000,
		name = "desintegrate rune"
	},
	[3198] = {
		groupExhaustion = 1500,
		id = 8,
		group = 1,
		exhaustion = 2000,
		name = "heavy magic missile rune"
	},
	[3200] = {
		groupExhaustion = 1500,
		id = 18,
		group = 1,
		exhaustion = 2000,
		name = "explosion rune"
	},
	[3202] = {
		groupExhaustion = 1500,
		id = 117,
		group = 1,
		exhaustion = 2000,
		name = "thunderstorm rune"
	},
	[3203] = {
		groupExhaustion = 2000,
		id = 83,
		group = 3,
		exhaustion = 2000,
		name = "animate dead rune"
	},
	[17512] = {
		groupExhaustion = 1500,
		id = 7,
		group = 1,
		exhaustion = 2000,
		name = "lightest magic missile rune"
	},
	[21351] = {
		groupExhaustion = 1500,
		id = 116,
		group = 1,
		exhaustion = 2000,
		name = "light stone shower rune"
	},
	[21352] = {
		groupExhaustion = 1500,
		id = 7,
		group = 1,
		exhaustion = 2000,
		name = "lightest missile rune"
	}
}
Spells = {}

function Spells.getParameterPlaceholder(spell)
	if not spell then
		return nil
	end

	return spell.parameterPlaceholder
end

local function resolveSpellByName(spellName)
	if not spellName or spellName == "" then
		return nil, nil
	end

	local trimmed = spellName:trim()

	for profile, data in pairs(SpellInfo) do
		local spell = data[trimmed]

		if spell then
			return spell, profile
		end

		for _, entry in pairs(data) do
			if entry.name and entry.name:trim():lower() == trimmed:lower() then
				return entry, profile
			end
		end
	end

	return nil, nil
end

local function resolveSpellIconId(spell)
	if not spell then
		return nil
	end

	if SpellIcons[spell.id] then
		return SpellIcons[spell.id]
	end

	return nil
end

function Spells.getClientId(spellName)
	return resolveSpellIconId(resolveSpellByName(spellName))
end

function Spells.getSpellByClientId(id)
	for profile, data in pairs(SpellInfo) do
		for k, spell in pairs(data) do
			if spell.id == id then
				return spell, profile, k
			end
		end
	end

	return nil
end

function Spells.getSpellNameByWords(words)
	for profile, data in pairs(SpellInfo) do
		for k, spell in pairs(data) do
			if spell.words == words then
				return k
			end
		end
	end

	return nil
end

function Spells.getSpellByName(name)
	local spell = resolveSpellByName(name)

	return spell
end

local spellByIdCache = {}
local spellByWordsCache = {}

function Spells.getSpellByWords(words)
	if not words or words == "" then
		return nil
	end

	local normalized = words:lower():trim()
	local cached = spellByWordsCache[normalized]

	if cached ~= nil then
		if cached == false then
			return nil
		end

		return cached[1], cached[2], cached[3]
	end

	for profile, data in pairs(SpellInfo) do
		for k, spell in pairs(data) do
			if spell.words == normalized then
				spellByWordsCache[normalized] = {
					spell,
					profile,
					k
				}

				return spell, profile, k
			end
		end
	end

	spellByWordsCache[normalized] = false

	return nil
end

function Spells.getSpellByIcon(iconId)
	for profile, data in pairs(SpellInfo) do
		for k, spell in pairs(data) do
			if spell.id == iconId then
				return spell, profile, k
			end
		end
	end

	for profile, data in pairs(SpellInfo) do
		for k, spell in pairs(data) do
			if SpellIcons[spell.id] and SpellIcons[spell.id] == iconId then
				return spell, profile, k
			end
		end
	end

	return nil
end

function Spells.resolveSpellId(iconId)
	local spell = Spells.getSpellByIcon(iconId)

	return spell and spell.id or iconId
end

function Spells.getSpellIconIds()
	local ids = {}

	for profile, data in pairs(SpellInfo) do
		for k, spell in pairs(data) do
			table.insert(ids, spell.id)
		end
	end

	return ids
end

function Spells.getSpellProfileById(id)
	for profile, data in pairs(SpellInfo) do
		for k, spell in pairs(data) do
			if spell.id == id then
				return profile
			end
		end
	end

	return nil
end

function Spells.getSpellProfileByWords(words)
	for profile, data in pairs(SpellInfo) do
		for k, spell in pairs(data) do
			if spell.words == words then
				return profile
			end
		end
	end

	return nil
end

function Spells.getSpellProfileByName(spellName)
	local _, profile = resolveSpellByName(spellName)

	return profile
end

function Spells.getSpellsByVocationId(vocId)
	local spells = {}

	for profile, data in pairs(SpellInfo) do
		for k, spell in pairs(data) do
			if table.contains(spell.vocations, vocId) then
				table.insert(spells, spell)
			end
		end
	end

	return spells
end

function Spells.getSpellNamesSortedForVocation(vocId, spellProfile)
	local names = {}
	local data = SpellInfo[spellProfile]

	if not data or not vocId or vocId <= 0 then
		return names
	end

	for spellName, spell in pairs(data) do
		if table.contains(spell.vocations, vocId) then
			table.insert(names, spellName)
		end
	end

	table.sort(names, function(a, b)
		return a:lower() < b:lower()
	end)

	return names
end

function Spells.filterSpellsByGroups(spells, groups)
	local filtered = {}

	for v, spell in pairs(spells) do
		local spellGroups = Spells.getGroupIds(spell)

		if table.equals(spellGroups, groups) then
			table.insert(filtered, spell)
		end
	end

	return filtered
end

function Spells.getGroupIds(spell)
	local groups = {}

	for k, _ in pairs(spell.group) do
		table.insert(groups, k)
	end

	return groups
end

function Spells.getPrimaryGroupId(spell)
	if not spell or not spell.group then
		return nil
	end

	local minId

	for gid, _ in pairs(spell.group) do
		if not minId or gid < minId then
			minId = gid
		end
	end

	return minId
end

function Spells.getSpellGroupIconClip(groupId)
	if not groupId or groupId < 1 or not SpellGroups[groupId] then
		return nil
	end

	local w = SpellGroupIconSize.width
	local h = SpellGroupIconSize.height

	return (groupId - 1) * w .. " 0 " .. w .. " " .. h
end

function Spells.getImageClip(id, profile)
	if not id or not profile or not SpelllistSettings[profile] then
		return nil
	end

	local w = SpelllistSettings[profile].iconSize.width
	local h = SpelllistSettings[profile].iconSize.height

	return (id - 1) * w .. " 0 " .. w .. " " .. h
end

function Spells.getIconFileByProfile(profile)
	return SpelllistSettings[profile].iconFile
end

function Spells.getImageClipNormal(id, profile)
	if not id or not profile or not SpelllistSettings[profile] then
		return nil
	end

	local w = SpelllistSettings[profile].iconSize.width
	local h = SpelllistSettings[profile].iconSize.height

	return (id - 1) * w .. " 0 " .. w .. " " .. h
end

function Spells.getSpellDataById(spellId)
	spellId = tonumber(spellId)

	if not spellId then
		return nil
	end

	local cached = spellByIdCache[spellId]

	if cached ~= nil then
		return cached or nil
	end

	for _, data in pairs(SpellInfo) do
		for _, spell in pairs(data) do
			if spell.id == spellId then
				spellByIdCache[spellId] = spell

				return spell
			end
		end
	end

	spellByIdCache[spellId] = false

	return nil
end

function Spells.clearSpellCache()
	spellByIdCache = {}
	spellByWordsCache = {}
end

function Spells.getRuneUsageSpell(itemId)
	local runeData = SpellRunesData[itemId]

	if not runeData then
		return nil
	end

	local groupCd = runeData.groupExhaustion or runeData.exhaustion
	local conjureSpell = Spells.getSpellDataById(runeData.id)
	local attackRuneAreas = {
		[3161] = SpellAreas.AREA_CIRCLE3X3, -- avalanche
		[3175] = SpellAreas.AREA_CIRCLE3X3, -- stone shower
		[3191] = SpellAreas.AREA_CIRCLE3X3, -- great fireball
		[3202] = SpellAreas.AREA_CIRCLE3X3, -- thunderstorm
		[3192] = SpellAreas.AREA_CIRCLE1X1,
		[3149] = SpellAreas.AREA_CIRCLE1X1,
		[3173] = SpellAreas.AREA_CIRCLE1X1,
		[3200] = SpellAreas.AREA_CIRCLE1X1,
		[21351] = SpellAreas.AREA_CIRCLE1X1
	}

	return {
		type = "Rune",
		id = runeData.id,
		name = conjureSpell and conjureSpell.name or runeData.name,
		icon = conjureSpell and conjureSpell.icon or nil,
		clientId = conjureSpell and conjureSpell.clientId or nil,
		group = {
			[runeData.group] = groupCd
		},
		runeGroup = runeData.group,
		exhaustion = runeData.exhaustion,
		area = attackRuneAreas[itemId],
		range = 7,
		_conjureVocations = conjureSpell and conjureSpell.vocations or nil
	}
end

function Spells.getRuneSpellByItem(itemId)
	return Spells.getRuneUsageSpell(itemId)
end

function Spells.isRuneSpell(spellId)
	for _, data in pairs(SpellRunesData) do
		if data.id == spellId then
			return true
		end
	end

	return false
end

function Spells.hasCrossHairTarget(spell)
	if type(spell) ~= "table" then
		return false
	end

	return spell.crossHairTarget == true
end
