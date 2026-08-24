local var_0_0
local var_0_1
local var_0_2
local var_0_3 = false
local var_0_4
local var_0_5
local var_0_6
local var_0_7
local var_0_8
local var_0_9
local var_0_10 = false
local var_0_11 = false
local var_0_12 = 0
local var_0_13 = 0
local var_0_14 = 0
local var_0_15 = 180
local var_0_16 = {
	B = 2,
	H = 8,
	G = 7,
	E = 5,
	D = 4,
	C = 3,
	A = 1,
	F = 6
}
local var_0_17 = {
	"Enable/Disable Helper",
	"Enable/Disable Auto Target",
	"Enable/Disable Magic Shooter",
	"Change Shooter Preset",
	"Enable/Disable Target and Magic Shooter"
}

local function var_0_18(arg_1_0)
	if type(arg_1_0) ~= "table" then
		return arg_1_0
	end

	local var_1_0 = {}

	for iter_1_0, iter_1_1 in pairs(arg_1_0) do
		var_1_0[iter_1_0] = var_0_18(iter_1_1)
	end

	return var_1_0
end

local var_0_19 = {
	spells = {
		{
			harmony = 1,
			selfCast = false,
			forceCast = false,
			priority = 1,
			creatures = 2,
			percent = 0,
			id = 0,
			serene = false
		},
		{
			harmony = 1,
			selfCast = false,
			forceCast = false,
			priority = 2,
			creatures = 2,
			percent = 0,
			id = 0,
			serene = false
		},
		{
			harmony = 1,
			selfCast = false,
			forceCast = false,
			priority = 3,
			creatures = 2,
			percent = 0,
			id = 0,
			serene = false
		},
		{
			harmony = 1,
			selfCast = false,
			forceCast = false,
			priority = 4,
			creatures = 1,
			percent = 0,
			id = 0,
			serene = false
		},
		{
			harmony = 1,
			selfCast = false,
			forceCast = false,
			priority = 5,
			creatures = 1,
			percent = 0,
			id = 0,
			serene = false
		},
		{
			harmony = 1,
			selfCast = false,
			forceCast = false,
			priority = 6,
			creatures = 2,
			percent = 0,
			id = 0,
			serene = false
		},
		{
			harmony = 1,
			selfCast = false,
			forceCast = false,
			priority = 7,
			creatures = 1,
			percent = 0,
			id = 0,
			serene = false
		},
		{
			harmony = 1,
			selfCast = false,
			forceCast = false,
			priority = 8,
			creatures = 2,
			percent = 0,
			id = 0,
			serene = false
		}
	},
	runes = {
		{
			useDuringCycle = false,
			forceCast = false,
			priority = 8,
			creatures = 2,
			interval = 4000,
			id = 0
		},
		{
			creatures = 2,
			forceCast = false,
			id = 0,
			priority = 9
		},
		{
			creatures = 1,
			forceCast = false,
			id = 0,
			priority = 10
		}
	},
	combatStance = {
		id = 0,
		percent = 0,
		cooldown = 30000
	},
	autoTargetMode = var_0_16.F
}
local var_0_20 = 5
local var_0_21 = {
	spells = {
		{
			id = 0,
			percent = 80
		},
		{
			id = 0,
			percent = 80
		},
		{
			id = 0,
			percent = 80
		},
		{
			id = 0,
			percent = 80
		},
		{
			id = 0,
			percent = 80
		}
	},
	potions = {
		{
			percent = 50,
			id = 0,
			priority = 0
		},
		{
			percent = 50,
			id = 0,
			priority = 0
		},
		{
			percent = 50,
			id = 0,
			priority = 0
		},
		{
			percent = 50,
			id = 0,
			priority = 0
		},
		{
			percent = 50,
			id = 0,
			priority = 0
		}
	},
	friendhealing = {
		{
			enabled = false,
			name = "",
			percent = 0
		},
		{
			enabled = false,
			name = "",
			percent = 0
		}
	},
	gransiohealing = {
		{
			enabled = false,
			name = "",
			percent = 0
		},
		{
			enabled = false,
			name = "",
			percent = 0
		}
	}
}
local var_0_22 = {
	training = {
		{
			enabled = false,
			percent = 0,
			id = 0
		}
	},
	exerciseTraining = {
		id = 0,
		enabled = false
	},
	haste = {
		{
			enabled = false,
			safecast = false,
			id = 0
		}
	}
}
local var_0_23 = {
	healing = {
		selectedKey = "selectedHealingProfile",
		profilesKey = "healingProfiles",
		fields = {
			"spells",
			"potions",
			"friendhealing",
			"gransiohealing"
		},
		default = var_0_21
	},
	tools = {
		selectedKey = "selectedToolsProfile",
		profilesKey = "toolsProfiles",
		fields = {
			"training",
			"exerciseTraining",
			"haste"
		},
		default = var_0_22
	},
	shooter = {
		fields = nil,
		selectedKey = "selectedShooterProfile",
		profilesKey = "shooterProfiles",
		default = var_0_19
	}
}
local var_0_24 = {
	id = "food",
	exhaustion = 1000
}
local var_0_25 = {
	id = "potion",
	exhaustion = 1000
}
local var_0_26 = {
	helperCycleTimer = 50,
	helperCycleEvent = nil
}
local var_0_27 = {
	checkAutoTarget = 0,
	checkMagicShooter = 0,
	checkAutoHaste = 0,
	checkFriendHealing = 0,
	routineChecks = 0,
	checkMana = 0,
	checkHealthHealing = 0,
	checkRustyRemover = 0,
	checkIdleActivity = 0,
	checkChangeGold = 0,
	checkExerciseEvent = 0
}
local var_0_28 = {
	checkHealthHealing = {
		action = nil,
		interval = 100
	},
	checkMana = {
		action = nil,
		interval = 100
	},
	routineChecks = {
		action = nil,
		interval = 1000
	},
	checkFriendHealing = {
		action = nil,
		interval = 150
	},
	checkAutoHaste = {
		action = nil,
		interval = 500
	},
	checkMagicShooter = {
		action = nil,
		interval = 100
	},
	checkAutoTarget = {
		action = nil,
		interval = 250
	},
	checkExerciseEvent = {
		action = nil,
		interval = 15000
	},
	checkChangeGold = {
		action = nil,
		interval = 15000
	},
	checkIdleActivity = {
		action = nil,
		interval = 1000
	},
	checkRustyRemover = {
		action = nil,
		interval = 3000
	}
}
local var_0_29 = {
	active = false,
	searchStartedAt = 0,
	lastAttemptTargetPos = nil,
	lastAttemptTargetKey = nil,
	nextAttemptAt = 0,
	pendingUntil = 0,
	targetCooldowns = {}
}
local var_0_30 = 3000
local var_0_31 = 10000
local var_0_32 = 30000
local var_0_33 = 30000
local var_0_34 = 5
local var_0_35
local var_0_36
local var_0_37
local var_0_38
local var_0_39 = "/settings/helper/"
local var_0_40 = {}

local function var_0_41(arg_2_0)
	return var_0_40[arg_2_0] or 0
end

local function var_0_42()
	local var_3_0 = g_clock.millis()

	return var_3_0 < var_0_41(var_0_25.id) or var_3_0 < var_0_12
end

-- Minimum local lock for each Shooter spell. The server cooldown packet can
-- arrive late (or briefly report a shorter value) on a high-latency link, so
-- 400 ms allowed the same words to be sent repeatedly before state settled.
local var_0_43 = 1500
local var_0_44 = 2000
local var_0_45
local var_0_46 = 0
local var_0_47 = 10000
local var_0_48 = false
local var_0_49 = 300000
local var_0_50 = 0
local var_0_51 = -1
local var_0_52 = -1
local var_0_53 = false

function markHelperActivity()
	var_0_50 = g_clock.millis()
	var_0_53 = false
end

local function var_0_54()
	markHelperActivity()
end

local var_0_55 = {
	onKeyDown = var_0_54,
	onKeyPress = var_0_54,
	onMousePress = var_0_54,
	onMouseWheel = var_0_54
}

function checkIdleActivity()
	if not g_game.isOnline() or not var_0_0 then
		return
	end

	local var_6_0 = g_window.getMousePosition()

	if var_6_0 and (var_6_0.x ~= var_0_51 or var_6_0.y ~= var_0_52) then
		var_0_51, var_0_52 = var_6_0.x, var_6_0.y

		markHelperActivity()
	end

	if var_0_53 then
		return
	end

	if g_clock.millis() - var_0_50 < var_0_49 then
		return
	end

	var_0_53 = true

	local var_6_1 = shooterPanel and shooterPanel:recursiveGetChildById("enableAutoTarget")
	local var_6_2 = shooterPanel and shooterPanel:recursiveGetChildById("enableMagicShooter")
	local var_6_3 = false

	if var_6_1 and var_6_1:isChecked() then
		var_6_1:setChecked(false)

		var_6_3 = true
	end

	if var_6_2 and var_6_2:isChecked() then
		var_6_2:setChecked(false)

		var_6_3 = true
	end

	if var_6_3 then
		modules.game_textmessage.displayGameMessage("Target and Magic Shooter disabled after 5 minutes without keyboard/mouse activity.")
	end
end

var_0_28.checkIdleActivity.action = checkIdleActivity

local function var_0_56(arg_7_0)
	arg_7_0 = tostring(arg_7_0 or "")

	return (arg_7_0:gsub("[^%w%._%-]", function(arg_8_0)
		return string.format("_%02X", arg_8_0:byte())
	end))
end

local function var_0_57(arg_9_0)
	local var_9_0 = G and G.host and string.gsub(G.host, "^https?://", "") or nil

	if var_9_0 and var_9_0 ~= "" then
		var_0_36 = var_9_0

		return var_9_0
	end

	if arg_9_0 then
		return var_0_36
	end

	return nil
end

local function var_0_58(arg_10_0)
	if g_game.getCharacterName then
		local var_10_0 = g_game.getCharacterName()

		if var_10_0 and var_10_0 ~= "" then
			var_0_37 = var_10_0

			return var_10_0
		end
	end

	local var_10_1 = g_game.getLocalPlayer()

	if var_10_1 then
		local var_10_2 = var_10_1:getName()

		if var_10_2 and var_10_2 ~= "" then
			var_0_37 = var_10_2

			return var_10_2
		end
	end

	if LoadedPlayer and LoadedPlayer.getName then
		local var_10_3 = LoadedPlayer:getName()

		if var_10_3 and var_10_3 ~= "" then
			var_0_37 = var_10_3

			return var_10_3
		end
	end

	if arg_10_0 then
		return var_0_37
	end

	return nil
end

local function var_0_59(arg_11_0)
	local var_11_0 = g_game.getLocalPlayer()

	if var_11_0 then
		local var_11_1 = var_11_0:getId()

		if var_11_1 and var_11_1 > 0 then
			var_0_38 = var_11_1

			return var_11_1
		end
	end

	if LoadedPlayer and LoadedPlayer.isLoaded and LoadedPlayer:isLoaded() then
		local var_11_2 = LoadedPlayer:getId()

		if var_11_2 and var_11_2 > 0 then
			var_0_38 = var_11_2

			return var_11_2
		end
	end

	if arg_11_0 then
		return var_0_38
	end

	return nil
end

local function var_0_60(arg_12_0)
	local var_12_0 = var_0_58(arg_12_0)

	if not var_12_0 then
		return nil
	end

	local var_12_1 = var_0_57(arg_12_0) or "default"

	return var_0_39 .. var_0_56(var_12_1) .. "__" .. var_0_56(var_12_0) .. ".json"
end

local function var_0_61(arg_13_0)
	local var_13_0 = var_0_59(arg_13_0)

	if not var_13_0 then
		return nil
	end

	return "/characterdata/" .. var_13_0 .. "/helper.json"
end

local function var_0_62()
	if not g_resources.directoryExists("/settings/") then
		g_resources.makeDir("/settings/")
	end

	if not g_resources.directoryExists(var_0_39) then
		g_resources.makeDir(var_0_39)
	end
end

local function var_0_63(arg_15_0)
	if not arg_15_0 then
		return "nil"
	end

	return string.format("%d,%d,%d", arg_15_0.x or 0, arg_15_0.y or 0, arg_15_0.z or 0)
end

local function var_0_64()
	var_0_29.active = false
	var_0_29.pendingUntil = 0
	var_0_29.nextAttemptAt = 0
	var_0_29.lastAttemptTargetKey = nil
	var_0_29.lastAttemptTargetPos = nil
	var_0_29.targetCooldowns = {}
	var_0_29.searchStartedAt = 0
end

local function var_0_65()
	var_0_29.pendingUntil = 0
	var_0_29.lastAttemptTargetKey = nil
	var_0_29.lastAttemptTargetPos = nil
end

local function var_0_66(arg_18_0)
	if var_0_29.lastAttemptTargetKey then
		var_0_29.targetCooldowns[var_0_29.lastAttemptTargetKey] = arg_18_0 + var_0_32
	end

	var_0_65()
end

local function var_0_67()
	if not var_0_35 then
		var_0_35 = {
			MessageModes.Game,
			MessageModes.Failure,
			MessageModes.Status,
			MessageModes.GameHighlight,
			MessageModes.Look
		}
	end

	return var_0_35
end

local function var_0_68()
	var_0_29.active = true

	var_0_65()

	var_0_29.targetCooldowns = {}
	var_0_29.searchStartedAt = 0
end

local function var_0_69()
	var_0_29.active = false

	var_0_65()
end

local var_0_70
local var_0_71
local var_0_72 = false

function invalidateHelperCache()
	var_0_70 = nil
	var_0_71 = nil
end

local var_0_73 = {}

local function var_0_74(arg_23_0, arg_23_1)
	return math.max(math.abs(arg_23_0.x - arg_23_1.x), math.abs(arg_23_0.y - arg_23_1.y))
end

local function var_0_75(arg_24_0, arg_24_1)
	return arg_24_0.x == arg_24_1.x and arg_24_0.y == arg_24_1.y and arg_24_0.z == arg_24_1.z
end

local function var_0_76(arg_25_0)
	local var_25_0 = arg_25_0 % 10
	local var_25_1 = arg_25_0 % 100

	if var_25_1 >= 11 and var_25_1 <= 13 then
		return tostring(arg_25_0) .. "th"
	end

	if var_25_0 == 1 then
		return tostring(arg_25_0) .. "st"
	elseif var_25_0 == 2 then
		return tostring(arg_25_0) .. "nd"
	elseif var_25_0 == 3 then
		return tostring(arg_25_0) .. "rd"
	else
		return tostring(arg_25_0) .. "th"
	end
end

local function var_0_77(arg_26_0, arg_26_1)
	if type(arg_26_1) ~= "table" then
		return false
	end

	local var_26_0 = math.abs(arg_26_0.x - arg_26_1.x)
	local var_26_1 = math.abs(arg_26_0.y - arg_26_1.y)
	local var_26_2 = var_26_0 <= 7
	local var_26_3 = var_26_1 <= 5

	return var_26_2 and var_26_3 and arg_26_0.z == arg_26_1.z
end

local var_0_78 = {}

helperConfig = {
	selectedShooterProfile = "Default",
	magicShooterOnHold = false,
	selectedToolsProfile = "Default",
	autoChangeGold = false,
	autoReconnect = false,
	autoEatFood = false,
	terms = false,
	autoRustyRemover = false,
	magicShooterEnabled = false,
	selectedHealingProfile = "Default",
	autoTargetEnabled = false,
	currentLockedTargetId = 0,
	spells = {
		{
			id = 0,
			percent = 80
		},
		{
			id = 0,
			percent = 80
		},
		{
			id = 0,
			percent = 80
		},
		{
			id = 0,
			percent = 80
		},
		{
			id = 0,
			percent = 80
		}
	},
	potions = {
		{
			percent = 50,
			id = 0,
			priority = 0
		},
		{
			percent = 50,
			id = 0,
			priority = 0
		},
		{
			percent = 50,
			id = 0,
			priority = 0
		},
		{
			percent = 50,
			id = 0,
			priority = 0
		},
		{
			percent = 50,
			id = 0,
			priority = 0
		}
	},
	training = {
		{
			enabled = false,
			percent = 0,
			id = 0
		}
	},
	exerciseTraining = {
		id = 0,
		enabled = false
	},
	haste = {
		{
			enabled = false,
			safecast = false,
			id = 0
		}
	},
	friendhealing = {
		{
			enabled = false,
			name = "",
			percent = 0
		},
		{
			enabled = false,
			name = "",
			percent = 0
		}
	},
	gransiohealing = {
		{
			enabled = false,
			name = "",
			percent = 0
		},
		{
			enabled = false,
			name = "",
			percent = 0
		}
	},
	shooterProfiles = {
		Default = var_0_19
	},
	healingProfiles = {
		Default = var_0_18(var_0_21)
	},
	toolsProfiles = {
		Default = var_0_18(var_0_22)
	},
	autoFood = {
		id = 0,
		minTime = 300
	},
	autoTargetMode = var_0_16.F
}

local var_0_79 = {
	3577,
	3578,
	3579,
	3581,
	3582,
	3583,
	3585,
	3586,
	3587,
	3588,
	3589,
	3592,
	3595,
	3597,
	3600,
	3601,
	3602,
	3606,
	3607,
	3723,
	3724,
	3725,
	3728,
	3731,
	3732,
	8011,
	8014,
	8016,
	8017,
	12310,
	14085,
	17457,
	17820,
	17821,
	21143,
	21144,
	21146,
	23535,
	23545
}
local var_0_80 = {
	61615,
	61672,
	61734,
	61930,
	62184,
	62267,
	62268,
	63235,
	63314,
	63723
}
local var_0_81 = {}

for iter_0_0, iter_0_1 in pairs(var_0_79) do
	var_0_81[iter_0_1] = true
end

for iter_0_2, iter_0_3 in pairs(var_0_80) do
	var_0_81[iter_0_3] = true
end

local var_0_82 = 9016
local var_0_83 = {
	[8899] = true,
	[8907] = true,
	[8895] = true,
	[8898] = true,
	[8897] = true,
	[8896] = true,
	[8908] = true,
	[8902] = true,
	[8894] = true
}
local var_0_84 = {
	28558,
	28559,
	28560,
	28561,
	28562,
	28563,
	28564,
	28565,
	51967,
	51968,
	61723,
	61725
}
local var_0_85 = {
	28552,
	28553,
	28554,
	28555,
	28556,
	28557,
	35279,
	35280,
	35281,
	35282,
	35283,
	35284,
	35285,
	35286,
	35287,
	35288,
	35289,
	35290,
	44064,
	44065,
	44066,
	44067,
	50292,
	50293,
	50294,
	50295,
	62101,
	62102,
	62103,
	62104,
	62105,
	62106,
	62107,
	63492,
	61726,
	61732,
	61728,
	61729,
	61730,
	61731,
	61733
}
local var_0_86 = {}

for iter_0_4, iter_0_5 in pairs(var_0_84) do
	var_0_86[iter_0_5] = true
end

local var_0_87 = {
	[35282] = true,
	[28545] = true,
	[35289] = true,
	[35284] = true,
	[28557] = true,
	[35288] = true,
	[28544] = true,
	[35290] = true,
	[28556] = true,
	[61731] = true,
	[61730] = true,
	[28543] = true,
	[28555] = true,
	[61729] = true,
	[35283] = true
}

local function var_0_88(arg_27_0)
	if var_0_87[arg_27_0] then
		return 7, 7
	end

	return 1, 1
end

local function var_0_89(arg_28_0)
	if g_game.findPlayerItem then
		return g_game.findPlayerItem(arg_28_0, -1, 0)
	end

	if var_0_0 and var_0_0.getItem then
		return var_0_0:getItem(arg_28_0, -1)
	end

	return nil
end

local function var_0_90(arg_29_0)
	for iter_29_0, iter_29_1 in ipairs(var_0_85) do
		if iter_29_1 ~= arg_29_0 and var_0_0:getInventoryCount(iter_29_1) > 0 then
			return iter_29_1
		end
	end

	return nil
end

local function var_0_91()
	if type(helperConfig.exerciseTraining) ~= "table" then
		helperConfig.exerciseTraining = {
			id = 0,
			enabled = false
		}
	end

	helperConfig.exerciseTraining.id = tonumber(helperConfig.exerciseTraining.id) or 0
	helperConfig.exerciseTraining.enabled = helperConfig.exerciseTraining.enabled == true

	return helperConfig.exerciseTraining
end

local function var_0_92(arg_31_0)
	local var_31_0 = var_0_2 and var_0_2:recursiveGetChildById("autoTrainingItem")

	if not var_31_0 then
		return
	end

	arg_31_0 = tonumber(arg_31_0) or 0

	if arg_31_0 <= 0 then
		var_31_0:setImageSource("/images/game/actionbar/actionbarslot")

		if var_31_0.potionItem then
			var_31_0.potionItem:destroy()
		end

		return
	end

	var_31_0:setImageSource("/images/ui/item")

	if not var_31_0:getChildById("potionItem") then
		local var_31_1 = g_ui.createWidget("PotionItem", var_31_0)

		if var_31_1 then
			var_31_1:setId("potionItem")
		end
	end

	local var_31_2 = var_31_0:getChildById("potionItem")

	if var_31_2 then
		var_31_2:setItemId(arg_31_0)
	end
end

local function var_0_93()
	if type(helperConfig.autoFood) ~= "table" then
		helperConfig.autoFood = {
			id = 0,
			minTime = 300
		}
	end

	helperConfig.autoFood.id = tonumber(helperConfig.autoFood.id) or 0
	helperConfig.autoFood.minTime = tonumber(helperConfig.autoFood.minTime) or 300

	return helperConfig.autoFood
end

local function var_0_94(arg_33_0)
	local var_33_0 = var_0_2 and var_0_2:recursiveGetChildById("autoFoodItem")

	if not var_33_0 then
		return
	end

	arg_33_0 = tonumber(arg_33_0) or 0

	if arg_33_0 <= 0 then
		var_33_0:setImageSource("/images/game/actionbar/actionbarslot")

		local var_33_1 = var_33_0:getChildById("potionItem")

		if var_33_1 then
			var_33_1:destroy()
		end

		return
	end

	var_33_0:setImageSource("/images/ui/item")

	if not var_33_0:getChildById("potionItem") then
		local var_33_2 = g_ui.createWidget("PotionItem", var_33_0)

		if var_33_2 then
			var_33_2:setId("potionItem")
		end
	end

	local var_33_3 = var_33_0:getChildById("potionItem")

	if var_33_3 then
		var_33_3:setItemId(arg_33_0)
	end
end

local function var_0_95(arg_34_0)
	if not arg_34_0 then
		return nil, nil
	end

	for iter_34_0, iter_34_1 in pairs(arg_34_0:getItems()) do
		if iter_34_1 and var_0_86[iter_34_1:getId()] then
			return iter_34_1, "items"
		end
	end

	local var_34_0 = arg_34_0:getTopMultiUseThing()

	if var_34_0 and var_0_86[var_34_0:getId()] then
		return var_34_0, "topMultiUse"
	end

	local var_34_1 = arg_34_0:getTopUseThing()

	if var_34_1 and var_0_86[var_34_1:getId()] then
		return var_34_1, "topUse"
	end

	return nil, nil
end

local var_0_96 = {
	3031,
	3035
}
local var_0_97 = {
	258, -- Divine Grenade (RP)
	302, -- Divine Barrage (RP)
	303, -- Ethereal Barrage (MS)
	310, -- Death Echo (MS)
	301  -- Thousand Fist Blows (Monk)
}
local var_0_98 = {
	[275] = true,
	[274] = true,
	[143] = true,
	[159] = true,
	[297] = true,
	[84] = true,
	[128] = true,
	[242] = true,
	[144] = true,
	[160] = true,
	[145] = true,
	[142] = true,
	[146] = true,
	[141] = true,
	[147] = true,
	[140] = true,
	[296] = true,
	[139] = true,
	[138] = true,
	[29] = true,
	[276] = true
}

local function var_0_99(arg_35_0, arg_35_1)
	if not arg_35_0 then
		return false
	end

	local ok, var_35_0 = pcall(function()
		return arg_35_0:getSpells()
	end)

	if not ok or type(var_35_0) ~= "table" then
		return false
	end

	return table.contains(var_35_0, arg_35_1)
end

-- SpellInfo ids identify spells, while the sprite sheet uses SpellIcons ids.
-- Some Tyron builds expose spell.clientId as the spell id, which produces an
-- out-of-range image clip (the coloured vertical noise seen in the selector).
local function getCrystalSpellIconId(spell, spellName)
	if not spell then
		return nil
	end

	return Spells.getClientId(spellName or spell.name) or spell.clientId
end

gmVocationOverride = nil

local function var_0_100()
	local var_36_0 = g_game.getLocalPlayer()

	if not var_36_0 then
		return false
	end

	local var_36_1 = var_36_0:getName()

	if not var_36_1 then
		return false
	end

	return var_36_1:gsub("^%s+", ""):gsub("%s+$", ""):lower() == "gamemaster"
end

function getPlayerVocation()
	local var_37_0 = g_game.getLocalPlayer()

	if not var_37_0 then
		return 0
	end

	if gmVocationOverride and var_0_100() then
		return gmVocationOverride
	end

	local rawVocation = tonumber(var_37_0:getVocation()) or 0
	-- Crystal sends its Helper vocation ids directly: 5 Sorcerer, 6 Druid,
	-- 7 Paladin, 8 Knight and 9/10 Monk. Do not pass id 5 through the
	-- official-client translator, where 5 means Monk.
	if rawVocation >= 5 and rawVocation <= 10 then
		return rawVocation
	end
	local translated = translateVocation(rawVocation)

	-- Crystal's server already sends the promoted vocation in the Helper
	-- range (5 Sorcerer, 6 Druid, 7 Paladin, 8 Knight, 9/10 Monk).
	if translated == 0 and rawVocation >= 5 and rawVocation <= 10 then
		return rawVocation
	end

	return translated
end

local crystalVocationPresentation = {
	[5] = { name = "Sorcerer", icon = "/images/game/battle/icon-battlelist-sorcerer" },
	[6] = { name = "Druid", icon = "/images/game/battle/icon-battlelist-druid" },
	[7] = { name = "Paladin", icon = "/images/game/battle/icon-battlelist-paladin" },
	[8] = { name = "Knight", icon = "/images/game/battle/icon-battlelist-knight" },
	[9] = { name = "Monk", icon = "/images/game/battle/icon-battlelist-monk" },
	[10] = { name = "Monk", icon = "/images/game/battle/icon-battlelist-monk" }
}

function updateCrystalVocationPresentation()
	if not var_0_5 then
		return
	end

	local presentation = crystalVocationPresentation[getPlayerVocation()] or {
		name = "No Vocation",
		icon = "/images/game/battle/icon-battlelist-paladin"
	}
	local banner = var_0_5:getChildById("vocationBanner")
	if banner then
		local name = banner:getChildById("vocationName")
		local icon = banner:getChildById("vocationIcon")
		if name then name:setText(presentation.name) end
		if icon then icon:setImageSource(presentation.icon) end
	end

	local content = var_0_5.contentPanel
	local tabs = content and content.optionsTabBar
	local shooterMenu = tabs and tabs:getChildById("shooterMenu")
	if shooterMenu then
		shooterMenu:setText(presentation.name .. " Caster")
	end
end

function isMonkVocId(arg_38_0)
	return arg_38_0 == 9 or arg_38_0 == 10
end

function isMonkVoc()
	return isMonkVocId(getPlayerVocation())
end

function usesCycleRune()
	return isMonkVoc() or isKnightVoc()
end

local var_0_101 = {
	nil,
	nil,
	nil,
	nil,
	"gmSorcerer",
	"gmDruid",
	"gmPaladin",
	"gmKnight",
	"gmMonk"
}

function updateGMVocSwitch()
	if not gmVocSwitch then
		return
	end

	if not var_0_100() or not var_0_5:isVisible() then
		gmVocSwitch:hide()

		return
	end

	local var_41_0 = var_0_5:getPosition()
	local var_41_1 = var_0_5:getSize()

	gmVocSwitch:setPosition({
		x = var_41_0.x + var_41_1.width + 12,
		y = var_41_0.y
	})
	gmVocSwitch:show()
	gmVocSwitch:raise()

	local var_41_2 = getPlayerVocation()

	for iter_41_0, iter_41_1 in pairs(var_0_101) do
		local var_41_3 = gmVocSwitch:getChildById(iter_41_1)

		if var_41_3 then
			var_41_3:setChecked(iter_41_0 == var_41_2)
		end
	end
end

function switchGMVocation(arg_42_0)
	if not var_0_100() then
		return
	end

	gmVocationOverride = arg_42_0
	updateCrystalVocationPresentation()

	if helperConfig then
		helperConfig.vocation = arg_42_0
	end

	local var_42_0 = "healingMenu"
	local var_42_1 = var_0_5.contentPanel.optionsTabBar

	for iter_42_0, iter_42_1 in ipairs({
		"healingMenu",
		"toolsMenu",
		"shooterMenu"
	}) do
		local var_42_2 = var_42_1:getChildById(iter_42_1)

		if var_42_2 and var_42_2:isChecked() then
			var_42_0 = iter_42_1

			break
		end
	end

	loadMenu(var_42_0)

	if var_42_0 == "shooterMenu" and helperConfig and helperConfig.selectedShooterProfile then
		loadShooterProfileByName(helperConfig.selectedShooterProfile)
	end

	updateGMVocSwitch()
end

local var_0_102 = {
	[143] = true,
	[159] = true,
	[172] = true,
	[241] = true,
	[158] = true,
	[125] = true,
	[128] = true,
	[84] = true,
	[144] = true,
	[160] = true,
	[145] = true,
	[142] = true,
	[146] = true,
	[141] = true,
	[147] = true,
	[140] = true,
	[36] = true,
	[139] = true,
	[1] = true,
	[138] = true,
	[242] = true,
	[239] = true,
	[82] = true,
	[2] = true,
	[277] = true,
	[123] = true,
	[29] = true,
	[170] = true
}
local var_0_103 = {
	{
		type = "mana",
		name = "Mana Potion",
		id = 268
	},
	{
		type = "mana",
		name = "Strong Mana Potion",
		id = 237
	},
	{
		type = "mana",
		name = "Great Mana Potion",
		id = 238
	},
	{
		type = "mana",
		name = "Ultimate Mana Potion",
		id = 23373
	},
	{
		type = "health",
		name = "Health Potion",
		id = 266
	},
	{
		type = "health",
		name = "Strong Health Potion",
		id = 236
	},
	{
		type = "health",
		name = "Great Health Potion",
		id = 239
	},
	{
		type = "health",
		name = "Ultimate Health Potion",
		id = 7643
	},
	{
		type = "health",
		name = "Supreme Health Potion",
		id = 23375
	},
	{
		type = "health",
		name = "Great Spirit Potion",
		id = 7642
	},
	{
		type = "health",
		name = "Ultimate Spirit Potion",
		id = 23374
	},
	{
		type = "health",
		name = "Small Health Potion",
		id = 7876
	}
}
local var_0_104 = {
	[9] = {
		6,
		39
	},
	[8] = {
		6,
		131
	},
	[7] = {
		6,
		134
	},
	[6] = {
		6,
		39
	},
	[5] = {
		6,
		39
	},
	[0] = {}
}

function init()
	g_ui.importStyle("styles/spell.otui")
	g_ui.importStyle("styles/actionbar_dialogs.otui")
	g_ui.importStyle("game_helper.otui")

	connect(g_game, {
		onGameStart = online,
		onGameEnd = offline,
		onSpellCooldown = onSpellCooldown,
		onSpellGroupCooldown = onSpellGroupCooldown,
		onUpdateSpellArea = onUpdateSpellArea,
		onMultiUseCooldown = onMultiUseCooldown
	})

	for iter_43_0, iter_43_1 in ipairs(var_0_67()) do
		registerMessageMode(iter_43_1, onExerciseTrainingMessage)
	end

	connect(Creature, {
		onAppear = onCreatureAppear,
		onDisappear = onCreatureDisappear,
		onShieldChange = onCreatureShieldChange
	})
	connect(Container, {
		onOpen = onHelperContainerOpen
	})
	connect(LocalPlayer, {
		onPositionChange = onHelperPositionChange
	})

	helperButton = modules.game_mainpanel.addToggleButton("helperButton", tr("helper"), "/images/options/button_helper", toggle, false, 99999)

	helperButton:setOn(false)
	helperButton:show()

	var_0_5 = g_ui.displayUI("styles/helper")
	updateCrystalVocationPresentation()
	gmVocSwitch = g_ui.createWidget("HelperGMVocSwitch", rootWidget)

	gmVocSwitch:hide()
	connect(var_0_5, {
		onGeometryChange = function()
			updateGMVocSwitch()
		end
	})

	var_0_6 = g_ui.createWidget("HelperTracker")
	var_0_7 = g_ui.createWidget("HelperRules", rootWidget)

	var_0_7:hide()
	var_0_6:setup()

	local var_43_0 = var_0_6:getChildById("toggleFilterButton")

	if var_43_0 then
		var_43_0:hide()
		var_43_0:setSize({
			width = 0,
			height = 0
		})
	end

	local var_43_1 = var_0_6:getChildById("contextMenuButton")

	if var_43_1 then
		var_43_1:hide()
		var_43_1:setSize({
			width = 0,
			height = 0
		})
	end

	local var_43_2 = var_0_6:getChildById("newWindowButton")

	if var_43_2 then
		var_43_2:hide()
		var_43_2:setSize({
			width = 0,
			height = 0
		})
	end

	local var_43_3 = var_0_6:getChildById("lockButton")
	local var_43_4 = var_0_6:getChildById("minimizeButton")

	if var_43_3 and var_43_4 then
		var_43_3:removeAnchor(AnchorRight)
		var_43_3:addAnchor(AnchorRight, "minimizeButton", AnchorLeft)
		var_43_3:setMarginRight(2)
	end

	var_0_6:close()

	var_0_0 = g_game.getLocalPlayer()

	hide()

	var_0_1 = var_0_5.contentPanel:getChildById("healingPanel")
	var_0_2 = var_0_5.contentPanel:getChildById("toolsPanel")
	supportPanel = var_0_5.contentPanel:recursiveGetChildById("supportPanel")
	utilitiesPanel = var_0_5.contentPanel:recursiveGetChildById("utilitiesPanel")
	var_0_1 = var_0_5.contentPanel:getChildById("healingPanel")
	potionButton2 = var_0_1:recursiveGetChildById("potionButton2")
	rmvPotionPercentButton2 = var_0_1:recursiveGetChildById("rmvPotionPercentButton2")
	potionPercentBg2 = var_0_1:recursiveGetChildById("potionPercentBg2")
	addPotionPercentButton2 = var_0_1:recursiveGetChildById("addPotionPercentButton2")
	priority2 = var_0_1:recursiveGetChildById("priority2")
	friendHealingPanel = var_0_1:recursiveGetChildById("friendHealingPanel")
	granSioPanel = var_0_1:recursiveGetChildById("granSioPanel")
	spellButton2 = var_0_1:recursiveGetChildById("spellButton2")
	rmvPercentButton2 = var_0_1:recursiveGetChildById("rmvPercentButton2")
	spellPercentBg2 = var_0_1:recursiveGetChildById("spellPercentBg2")
	addPercentButton2 = var_0_1:recursiveGetChildById("addPercentButton2")
	priorityButton1 = var_0_1:recursiveGetChildById("priority0")
	priorityButton2 = var_0_1:recursiveGetChildById("priority1")
	priorityButton3 = var_0_1:recursiveGetChildById("priority2")
	equipPanel = var_0_2:recursiveGetChildById("equipPanel")
	shooterPanel = var_0_5.contentPanel:getChildById("shooterPanel")
	settingsPanel = var_0_5.contentPanel:getChildById("settingsPanel")
	cavebotPanel = var_0_5.contentPanel:getChildById("cavebotPanel")
	runePanel = shooterPanel:recursiveGetChildById("runePanel")
	attackSpellPanel3 = shooterPanel:recursiveGetChildById("attackSpellPanel3")
	attackSpellPanel4 = shooterPanel:recursiveGetChildById("attackSpellPanel4")
	attackSpellPanel6 = shooterPanel:recursiveGetChildById("attackSpellPanel6")
	spellPanel = shooterPanel:recursiveGetChildById("spellPanel")
	enableButtons = shooterPanel:recursiveGetChildById("enableButtons")
	presetsPanel = shooterPanel:recursiveGetChildById("presetsPanel")
	var_0_8 = var_0_1:recursiveGetChildById("friendList")
	var_0_9 = var_0_1:recursiveGetChildById("friendList2")
	helperTabs = var_0_5.contentPanel.optionsTabBar

	if HelperPosture and HelperPosture.init then
		HelperPosture.init({
			getWidget = function(id)
				return var_0_5 and var_0_5:recursiveGetChildById(id) or nil
			end,
			getPlayerVoc = getPlayerVocation,
			isLoadingConfig = function() return false end,
			saveConfig = function()
				if helperConfig then saveSettings() end
			end
		})
	end

	if HelperCavebot and HelperCavebot.init then
		HelperCavebot.init({
			getWidget = function(id)
				return var_0_5 and var_0_5:recursiveGetChildById(id) or nil
			end,
			isLoadingConfig = function() return false end,
			requestAutoSave = function()
				if helperConfig then saveSettings() end
			end
		})
	end

	botStatus()

	local var_43_5 = modules.game_interface.getRootPanel()

	connect(var_43_5, var_0_55)
	Keybind.new("Helper", "Enable/Disable Helper", "Pause", "")
	Keybind.bind("Helper", "Enable/Disable Helper", {
		{
			type = KEY_DOWN,
			callback = function()
				botStatus()
			end
		}
	}, var_43_5)
	Keybind.new("Helper", "Enable/Disable Auto Target", "", "")
	Keybind.bind("Helper", "Enable/Disable Auto Target", {
		{
			type = KEY_DOWN,
			callback = function()
				toggleAutoTarget()
			end
		}
	}, var_43_5)
	Keybind.new("Helper", "Enable/Disable Magic Shooter", "", "")
	Keybind.bind("Helper", "Enable/Disable Magic Shooter", {
		{
			type = KEY_DOWN,
			callback = function()
				toggleMagicShooter()
			end
		}
	}, var_43_5)
	Keybind.new("Helper", "Change Shooter Preset", "", "")
	Keybind.bind("Helper", "Change Shooter Preset", {
		{
			type = KEY_DOWN,
			callback = function()
				toggleShooterPreset()
			end
		}
	}, var_43_5)
	Keybind.new("Helper", "Enable/Disable Target and Magic Shooter", "", "")
	Keybind.bind("Helper", "Enable/Disable Target and Magic Shooter", {
		{
			type = KEY_DOWN,
			callback = function()
				toggleAutoTarget()
				toggleMagicShooter()
			end
		}
	}, var_43_5)

	var_0_4 = g_ui.createWidget("UIWidget")

	var_0_4:setVisible(false)
	var_0_4:setFocusable(false)

	if g_game.isOnline() then
		online()
	end
end

function terminate()
	if HelperCavebot and HelperCavebot.terminate then
		HelperCavebot.terminate()
	end

	if HelperPosture and HelperPosture.terminate then
		HelperPosture.terminate()
	end

	disconnect(g_game, {
		onGameStart = online,
		onGameEnd = offline,
		onSpellCooldown = onSpellCooldown,
		onSpellGroupCooldown = onSpellGroupCooldown,
		onUpdateSpellArea = onUpdateSpellArea,
		onMultiUseCooldown = onMultiUseCooldown
	})

	for iter_50_0, iter_50_1 in ipairs(var_0_67()) do
		unregisterMessageMode(iter_50_1, onExerciseTrainingMessage)
	end

	disconnect(Creature, {
		onAppear = onCreatureAppear,
		onDisappear = onCreatureDisappear,
		onShieldChange = onCreatureShieldChange
	})
	disconnect(Container, {
		onOpen = onHelperContainerOpen
	})
	disconnect(LocalPlayer, {
		onPositionChange = onHelperPositionChange
	})

	local var_50_0 = modules.game_interface.getRootPanel()

	if var_50_0 then
		disconnect(var_50_0, var_0_55)
	end

	for iter_50_2, iter_50_3 in ipairs(var_0_17) do
		Keybind.delete("Helper", iter_50_3)
	end

	if var_0_6 then
		var_0_6:destroy()

		var_0_6 = nil
	end

	if var_0_5 then
		g_keyboard.unbindKeyPress("Tab", toggleNextWindow, var_0_5)
		var_0_5:destroy()

		var_0_5 = nil
	end

	if gmVocSwitch then
		gmVocSwitch:destroy()

		gmVocSwitch = nil
	end
end

function toggle()
	if var_0_5:isVisible() then
		var_0_5:hide()
		updateGMVocSwitch()
	else
		var_0_5:show(true)
		var_0_5:raise()
		var_0_5:focus()
		g_keyboard.bindKeyPress("Tab", toggleNextWindow, var_0_5)
		updateCrystalVocationPresentation()
		loadMenu("healingMenu")
		updateGMVocSwitch()
	end
end

function hide()
	if var_0_5 then
		g_keyboard.unbindKeyPress("Tab", toggleNextWindow, var_0_5)
		var_0_5:hide()
		updateGMVocSwitch()
		saveSettings()
	end
end

function show()
	if var_0_5 then
		updateCrystalVocationPresentation()
		var_0_5:show(true)
		var_0_5:raise()
		var_0_5:focus()
		g_keyboard.bindKeyPress("Tab", toggleNextWindow, var_0_5)
		loadMenu("healingMenu")
		updateGMVocSwitch()
	end
end

function helperCycleEvent()
	if not g_game.isOnline() then
		return
	end

	local var_54_0 = g_game.getLocalPlayer()

	if var_54_0 and var_54_0 ~= var_0_0 then
		if var_0_72 then
			print("[HelperDbg] cycle: refreshed stale player reference")
		end

		var_0_0 = var_54_0
	end

	for iter_54_0, iter_54_1 in pairs(var_0_28) do
		var_0_27[iter_54_0] = var_0_27[iter_54_0] + var_0_26.helperCycleTimer

		if var_0_27[iter_54_0] >= iter_54_1.interval then
			var_0_27[iter_54_0] = 0

			local var_54_1 = iter_54_1.action

			if var_54_1 and type(var_54_1) == "function" then
				local var_54_2, var_54_3 = pcall(var_54_1)

				if not var_54_2 and var_0_72 then
					print("[HelperDbg] cycle event '" .. tostring(iter_54_0) .. "' failed: " .. tostring(var_54_3))
				end
			end
		end
	end
end

function online()
	local var_55_0 = g_clock.millis()

	var_0_3 = false
	var_0_0 = g_game.getLocalPlayer()
	updateCrystalVocationPresentation()
	var_0_48 = var_0_0 and var_0_0:isInProtectionZone() or false

	markHelperActivity()

	local var_55_1 = g_window.getMousePosition()

	if var_55_1 then
		var_0_51, var_0_52 = var_55_1.x, var_55_1.y
	end

	var_0_60(false)
	var_0_61(false)

	local var_55_2 = g_settings.getNode("helper_pending_import")

	if var_55_2 and type(var_55_2) == "table" and type(var_55_2.content) == "string" then
		local var_55_3 = var_0_60(false)

		if var_55_3 and pcall(var_0_62) and pcall(function()
			return g_resources.writeFileContents(var_55_3, var_55_2.content)
		end) then
			g_settings.setNode("helper_pending_import", nil)
			g_settings.save()
		end
	end

	reset()
	var_0_64()
	loadSettings()
	if HelperPosture and HelperPosture.loadFromConfig then
		HelperPosture.loadFromConfig(helperConfig)
	end
	if HelperPosture and HelperPosture.onGameStart then
		HelperPosture.onGameStart()
	end

	for iter_55_0 in pairs(var_0_23) do
		local var_55_4 = var_0_23[iter_55_0]
		local var_55_5 = var_55_4 and helperConfig[var_55_4.selectedKey]

		if var_55_5 and getPresetBucket(iter_55_0) and getPresetBucket(iter_55_0)[var_55_5] then
			applyPresetData(iter_55_0, var_55_5)
		end
	end

	loadProfileOptions()
	onLoadHelperData()

	if helperConfig.helperEnabled and not var_0_10 then
		botStatus()
	elseif not helperConfig.helperEnabled and var_0_10 then
		botStatus()
	end

	if helperConfig.autoReconnect then
		g_settings.set("autoReconnect", true)
	end

	helperConfig.currentLockedTargetId = 0
	var_0_26.helperCycleEvent = cycleEvent(helperCycleEvent, var_0_26.helperCycleTimer)

	if var_0_72 then
		print(string.format("[HelperDbg] online(): helperEnabled=%s hotkeyHelperStatus=%s player=%s", tostring(helperConfig.helperEnabled), tostring(var_0_10), tostring(var_0_0 ~= nil)))
	end

	resetPartyPanel()
	updatePartyFriendList()
	updateGMVocSwitch()

	if var_0_6 and not var_0_6:getParent() then
		local var_55_6 = modules.game_interface.findContentPanelAvailable(var_0_6, var_0_6:getMinimumHeight())

		if var_55_6 then
			var_55_6:addChild(var_0_6)
			var_0_6:open()
		end
	end

	updateTrackerDisplay()
	print("Helper loaded in " .. (g_clock.millis() - var_55_0) / 1000 .. " seconds.")
end

function offline()
	if var_0_72 then
		print(string.format("[HelperDbg] offline(): hotkeyHelperStatus=%s helperEnabled=%s", tostring(var_0_10), tostring(helperConfig.helperEnabled)))
	end

	-- The legacy Helper window lives outside the game interface, so it is not
	-- hidden automatically when returning to the character list.
	if var_0_5 then
		g_keyboard.unbindKeyPress("Tab", toggleNextWindow, var_0_5)
		var_0_5:hide()
	end

	if gmVocSwitch then
		gmVocSwitch:hide()
	end

	var_0_64()

	local var_57_0 = presetsPanel:recursiveGetChildById("presets")

	if var_57_0 then
		var_57_0:clear()
	end

	removeEvent(var_0_26.helperCycleEvent)
	saveSettings()
end

function onSpellCooldown(arg_58_0, arg_58_1)
	-- Never let a delayed/shorter cooldown packet undo a local anti-spam lock.
	var_0_40[arg_58_0] = math.max(var_0_40[arg_58_0] or 0, g_clock.millis() + arg_58_1)

	if var_0_45 and var_0_45.id == arg_58_0 then
		var_0_45 = nil
	end
end

function onSpellGroupCooldown(arg_59_0, arg_59_1)
	var_0_73[arg_59_0] = g_clock.millis() + arg_59_1
end

function onMultiUseCooldown(arg_60_0)
	var_0_12 = g_clock.millis() + arg_60_0
end

function onUpdateSpellArea(arg_61_0)
	if arg_61_0 then
		SpellInfo.Default["Energy Wave"].area = SpellAreas.AREA_SQUAREWAVE6
	else
		SpellInfo.Default["Energy Wave"].area = SpellAreas.AREA_SQUAREWAVE4
	end
end

function ensureAimCheckbox(arg_62_0, arg_62_1)
	if not shooterPanel then
		return
	end

	local var_62_1 = shooterPanel:recursiveGetChildById("countMinCreature" .. arg_62_0)
	local var_62_2 = shooterPanel:recursiveGetChildById("aimTarget" .. arg_62_0)
	local var_62_3 = arg_62_1 and arg_62_1.directional == true

	if var_62_3 and var_62_1 then
		if not var_62_2 then
			var_62_2 = g_ui.createWidget("CheckBox", var_62_1:getParent())

			var_62_2:mergeStyle({
				["margin-top"] = 6,
				["margin-left"] = 5,
				width = 12,
				height = 12,
				["anchors.top"] = "countMinCreature" .. arg_62_0 .. ".top",
				["anchors.left"] = "countMinCreature" .. arg_62_0 .. ".right"
			})
			var_62_2:setId("aimTarget" .. arg_62_0)
			var_62_2:setTooltip("Auto Turn\nTurns to the direction that hits the most creatures.\nNo target is required.")

			function var_62_2.onCheckChange(arg_63_0, arg_63_1)
				if arg_63_0.updating then
					return
				end

				local profile = getShooterProfile()
				local entry = profile and profile.spells and profile.spells[arg_62_0 + 1]

				if entry then
					entry.autoTurn = arg_63_1 == true
					saveSettings()
				end
			end
		end

		var_62_2.spellId = arg_62_1.id
		var_62_2.updating = true

		local profile = getShooterProfile()
		local entry = profile and profile.spells and profile.spells[arg_62_0 + 1]

		var_62_2:setChecked(entry and entry.autoTurn == true or false)

		var_62_2.updating = false

		var_62_2:setVisible(true)
	elseif var_62_2 then
		var_62_2:destroy()
	end
end

local var_0_105 = "/images/game/vocations/monk/icon-combopoint-empty"
local var_0_106 = "/images/game/vocations/monk/icon-combopoint-filled"
local var_0_107 = "/images/game/vocations/monk/icon-serene-off"
local var_0_108 = "/images/game/vocations/monk/icon-serene-on"

function refreshHarmonyIcons(arg_64_0)
	if not shooterPanel then
		return
	end

	local var_64_0 = shooterPanel:recursiveGetChildById("harmonyGroup" .. arg_64_0)

	if not var_64_0 then
		return
	end

	local var_64_1 = getShooterProfile().spells[tonumber(arg_64_0) + 1]

	if not var_64_1 then
		return
	end

	local var_64_2 = var_64_1.harmony or 1

	for iter_64_0 = 1, 5 do
		local var_64_3 = var_64_0:getChildById("harmonyPoint" .. arg_64_0 .. "_" .. iter_64_0)

		if var_64_3 then
			var_64_3:setImageSource(iter_64_0 <= var_64_2 and var_0_106 or var_0_105)
		end
	end

	local var_64_4 = var_64_0:getChildById("harmonySerene" .. arg_64_0)

	if var_64_4 then
		var_64_4:setImageSource(var_64_1.serene and var_0_108 or var_0_107)
	end
end

function ensureHarmonyIcons(arg_65_0, arg_65_1)
	if not shooterPanel then
		return
	end

	local var_65_0 = shooterPanel:recursiveGetChildById("priority" .. arg_65_0)
	local var_65_1 = shooterPanel:recursiveGetChildById("harmonyGroup" .. arg_65_0)

	if not arg_65_1 or not arg_65_1.spender or not var_65_0 then
		if var_65_1 then
			var_65_1:destroy()
		end

		return
	end

	local var_65_2 = getShooterProfile().spells[tonumber(arg_65_0) + 1]

	if var_65_2 then
		if var_65_2.harmony == nil then
			var_65_2.harmony = 1
		end

		if var_65_2.serene == nil then
			var_65_2.serene = false
		end
	end

	local var_65_3 = var_65_1

	if not var_65_3 then
		var_65_3 = g_ui.createWidget("UIWidget", var_65_0:getParent())

		var_65_3:setId("harmonyGroup" .. arg_65_0)
		var_65_3:mergeStyle({
			phantom = false,
			["margin-left"] = 8,
			width = 82,
			height = 12,
			["anchors.verticalCenter"] = "priority" .. arg_65_0 .. ".verticalCenter",
			["anchors.left"] = "priority" .. arg_65_0 .. ".right"
		})

		local var_65_4

		for iter_65_0 = 1, 5 do
			local var_65_5 = g_ui.createWidget("UIWidget", var_65_3)

			var_65_5:setId("harmonyPoint" .. arg_65_0 .. "_" .. iter_65_0)

			local var_65_6 = {
				["anchors.verticalCenter"] = "parent.verticalCenter",
				width = 12,
				height = 12
			}

			if var_65_4 then
				var_65_6["anchors.left"] = var_65_4 .. ".right"
				var_65_6["margin-left"] = 1
			else
				var_65_6["anchors.left"] = "parent.left"
			end

			var_65_5:mergeStyle(var_65_6)
			var_65_5:setVisible(true)
			var_65_5:setTooltip("Minimum harmony required to cast this spell")

			function var_65_5.onMouseRelease(arg_66_0, arg_66_1, arg_66_2)
				if arg_66_2 == MouseLeftButton then
					setMagicShooterHarmony(arg_65_0, iter_65_0)
				end

				return true
			end

			var_65_4 = var_65_5:getId()
		end

		local var_65_7 = g_ui.createWidget("UIWidget", var_65_3)

		var_65_7:setId("harmonySerene" .. arg_65_0)
		var_65_7:mergeStyle({
			["anchors.verticalCenter"] = "parent.verticalCenter",
			["margin-left"] = 6,
			width = 12,
			height = 12,
			["anchors.left"] = var_65_4 .. ".right"
		})
		var_65_7:setVisible(true)
		var_65_7:setTooltip("Serene: only cast while you are serene")

		function var_65_7.onMouseRelease(arg_67_0, arg_67_1, arg_67_2)
			if arg_67_2 == MouseLeftButton then
				toggleMagicShooterSerene(arg_65_0)
			end

			return true
		end
	end

	local var_65_8 = var_65_0:getParent()
	local var_65_9 = var_65_0:getX() + var_65_0:getWidth() + 8 + 82 + 4 - var_65_8:getX()

	if var_65_9 > var_65_8:getWidth() then
		var_65_8:setWidth(var_65_9)
	end

	var_65_3:setVisible(true)
	refreshHarmonyIcons(arg_65_0)
end

function syncHarmonyIcons()
	if not shooterPanel then
		return
	end

	local var_68_0 = getShooterProfile()

	for iter_68_0, iter_68_1 in ipairs(getAllSpellSlots()) do
		local var_68_1 = var_68_0 and var_68_0.spells[iter_68_1 + 1]
		local var_68_2

		if var_68_1 and var_68_1.id and var_68_1.id > 0 then
			var_68_2 = Spells.getSpellDataById(var_68_1.id)
		end

		ensureHarmonyIcons(iter_68_1, var_68_2)
	end
end

function getShooterProfileCount()
	local var_69_0 = 0

	for iter_69_0, iter_69_1 in pairs(helperConfig.shooterProfiles) do
		var_69_0 = var_69_0 + 1
	end

	return var_69_0
end

function getShooterProfile()
	local var_70_0 = helperConfig.shooterProfiles[helperConfig.selectedShooterProfile]

	if not var_70_0 then
		return var_0_19
	end

	return var_70_0
end

HelperVoc = HelperVoc or {}

local var_0_109 = 86
local var_0_110 = 86
local var_0_111 = 7
local var_0_112 = 120
local var_0_113 = 26
local var_0_114 = 120
local var_0_115 = 274
local var_0_116 = "Uses a healing or mana potion when your health or\nmana reaches the defined percentage."
local var_0_117 = var_0_116 .. "\nClick on this button to change the potion priority:\n  - Icon: Blue (Mana Priority)\n  - Icon: Red  (Health Priority)"

local function var_0_118(arg_71_0, arg_71_1)
	local var_71_0 = var_0_1:recursiveGetChildById(arg_71_0 .. "SlotsRow")

	if not var_71_0 then
		return
	end

	for iter_71_0 = 0, var_0_20 - 1 do
		local var_71_1 = var_0_1:recursiveGetChildById(arg_71_0 .. "Slot" .. iter_71_0)

		if var_71_1 then
			var_71_1:setVisible(iter_71_0 < arg_71_1)
		end
	end

	var_71_0:setWidth(arg_71_1 * var_0_109)
end

function applyHealingLayout(arg_72_0)
	local var_72_0 = arg_72_0.spells or 3
	local var_72_1 = arg_72_0.potions or 3

	var_0_118("spell", var_72_0)
	var_0_118("potion", var_72_1)
	friendHealingPanel:setVisible(arg_72_0.friend or false)
	granSioPanel:setVisible(arg_72_0.gransio or false)

	if arg_72_0.friend and arg_72_0.sioText then
		friendHealingPanel.secondPanel.enableSio0:setText(arg_72_0.sioText)
		friendHealingPanel.secondPanel.enableSio1:setText(arg_72_0.sioText)
	end

	local var_72_2 = arg_72_0.priorityTooltip and var_0_117 or var_0_116

	for iter_72_0 = 0, var_72_1 - 1 do
		local var_72_3 = var_0_1:recursiveGetChildById("priority" .. iter_72_0)

		if var_72_3 then
			var_72_3:setTooltip(var_72_2)
		end
	end

	local var_72_4 = math.max(var_72_0, var_72_1)
	local var_72_5 = math.max(var_0_115, var_72_4 * var_0_109)
	local var_72_6 = var_0_110 + var_0_111 + var_0_110

	if arg_72_0.friend then
		var_72_6 = var_72_6 + var_0_111 + var_0_112
	end

	if arg_72_0.gransio then
		var_72_6 = var_72_6 + var_0_111 + var_0_112
	end

	var_0_5:setSize(tosize(var_72_5 + var_0_113 .. " " .. var_72_6 + var_0_114))
end

function HelperVoc.defaultHealingLayout(arg_73_0)
	applyHealingLayout({
		potions = 2,
		spells = 2
	})
end

function HelperVoc.defaultShooterLayout(arg_74_0)
	arg_74_0:setSize(tosize("555 601"))
	runePanel:setVisible(true)
	runePanel:setHeight(178)
	spellPanel:setHeight(178)
	attackSpellPanel3:setVisible(true)
	attackSpellPanel4:setVisible(true)
	enableButtons:addAnchor(AnchorTop, "runePanel", AnchorBottom)
	enableButtons:setMarginTop(5)
end

function resetShooterExtras()
	if not shooterPanel then
		return
	end

	local var_75_0 = {
		"attackSpellPanel6",
		"attackSpellButton5",
		"rmvPercentButton5",
		"spellPercentBg5",
		"addPercentButton5",
		"countMinCreature5",
		"conditionSetting5",
		"priority5",
		"attackSpellButton7",
		"rmvPercentButton7",
		"spellPercentBg7",
		"addPercentButton7",
		"countMinCreature7",
		"conditionSetting7",
		"priority7"
	}

	for iter_75_0, iter_75_1 in ipairs(var_75_0) do
		local var_75_1 = shooterPanel:recursiveGetChildById(iter_75_1)

		if var_75_1 then
			var_75_1:setVisible(false)
		end
	end

	if not runePanel then
		return
	end

	local var_75_2 = {
		"combatStancePanel",
		"cycleRuneIntervalLabel",
		"cycleRuneInterval",
		"cycleRuneCheck"
	}

	for iter_75_2, iter_75_3 in ipairs(var_75_2) do
		local var_75_3 = runePanel:recursiveGetChildById(iter_75_3)

		if var_75_3 then
			var_75_3:setVisible(false)
		end
	end

	local var_75_4 = {
		"sep0",
		"sep1",
		"priorityLabel",
		"creaturesLabel",
		"runeLabel",
		"runeShooterButton0",
		"countMinCreature0",
		"runePriority0",
		"runeHelp0",
		"runeShooterButton1",
		"countMinCreature1",
		"runePriority1",
		"runeHelp1",
		"targetRuneLabel",
		"runeShooterButton2",
		"countMinCreature2",
		"runePriority2",
		"runeHelp2"
	}

	for iter_75_4, iter_75_5 in ipairs(var_75_4) do
		local var_75_5 = runePanel:recursiveGetChildById(iter_75_5)

		if var_75_5 then
			var_75_5:setVisible(true)
		end
	end
end

function loadMenu(arg_76_0)
	local var_76_0 = {
		shooterMenuButton = "shooterMenu",
		toolsMenuButton = "toolsMenu",
		healMenuButton = "healingMenu",
		presetsMenuButton = "presetsMenu",
		cavebotMenuButton = "cavebotMenu"
	}
	local var_76_1 = {
		toolsMenu = "Tools & Support",
		healingMenu = "Healing",
		presetsMenu = "Settings",
		shooterMenu = (crystalVocationPresentation[getPlayerVocation()] or { name = "Vocation" }).name .. " Caster",
		cavebotMenu = "Bot"
	}

	for iter_76_0, iter_76_1 in pairs(var_76_0) do
		local var_76_2 = var_0_5.contentPanel.optionsTabBar:getChildById(iter_76_1)

		if var_76_2 then
			var_76_2:setChecked(false)
			var_76_2:setText("")
		end
	end

	local var_76_3 = var_0_5.contentPanel.optionsTabBar:getChildById(arg_76_0)

	if var_76_3 then
		var_76_3:setChecked(true)
		var_76_3:setText(var_76_1[arg_76_0] or "")
	end

	if not g_game.getLocalPlayer() then
		var_0_1:show(true)
		var_0_2:hide()
		shooterPanel:hide()
		settingsPanel:hide()
		if cavebotPanel then cavebotPanel:hide() end
		var_0_5:setSize(tosize("295 240"))

		return
	end

	local var_76_4 = getPlayerVocation()

	if arg_76_0 == "healingMenu" then
		var_0_1:show(true)
		var_0_2:hide()
		shooterPanel:hide()
		settingsPanel:hide()
		if cavebotPanel then cavebotPanel:hide() end

		local var_76_5 = HelperVoc[var_76_4]

		if var_76_5 and var_76_5.healingLayout then
			var_76_5.healingLayout(var_0_5)
		else
			HelperVoc.defaultHealingLayout(var_0_5)
		end
	elseif arg_76_0 == "toolsMenu" then
		var_0_5:setSize(tosize("295 460"))
		var_0_1:hide()
		shooterPanel:hide()
		settingsPanel:hide()
		if cavebotPanel then cavebotPanel:hide() end
		var_0_2:show(true)
		updateSupportPanel()
		updateUtilitiesPanel()
	elseif arg_76_0 == "shooterMenu" then
		var_0_1:hide()
		var_0_2:hide()
		settingsPanel:hide()
		if cavebotPanel then cavebotPanel:hide() end
		shooterPanel:show(true)
		resetShooterColumnLayout()
		resetShooterExtras()

		local var_76_6 = HelperVoc[var_76_4]

		if var_76_6 and var_76_6.shooterLayout then
			var_76_6.shooterLayout(var_0_5)
		else
			HelperVoc.defaultShooterLayout(var_0_5)
		end

		syncHarmonyIcons()
		if HelperPosture and HelperPosture.refreshUI then
			HelperPosture.refreshUI()
		end
	elseif arg_76_0 == "presetsMenu" then
		var_0_1:hide()
		var_0_2:hide()
		shooterPanel:hide()
		settingsPanel:show(true)
		if cavebotPanel then cavebotPanel:hide() end
		var_0_5:setSize(tosize("295 400"))
		openSettingsTab()
	elseif arg_76_0 == "cavebotMenu" then
		var_0_1:hide()
		var_0_2:hide()
		shooterPanel:hide()
		settingsPanel:hide()
		if cavebotPanel then cavebotPanel:show(true) end
		var_0_5:setSize(tosize("620 511"))
		if HelperCavebot and HelperCavebot.onShow then HelperCavebot.onShow() end
	end
end

function cavebotAddCurrentPosition(waypointType)
	if HelperCavebot then HelperCavebot.addCurrentPosition(waypointType or "Walk") end
end

function cavebotSetDirection(direction)
	if HelperCavebot then HelperCavebot.setDirection(direction) end
end

function cavebotToggle()
	if HelperCavebot then HelperCavebot.toggle() end
end

function cavebotOpenSettings() if HelperCavebot then HelperCavebot.openSettings() end end
function cavebotCloseSettings() if HelperCavebot then HelperCavebot.closeSettings() end end
function cavebotSettingsTab(name) if HelperCavebot then HelperCavebot.settingsTab(name) end end
function cavebotApplySettings(closeAfter) if HelperCavebot then HelperCavebot.applySettings(closeAfter) end end
function cavebotOpenSupplies() if HelperCavebot then HelperCavebot.openSupplies() end end
function cavebotCloseSupplies() if HelperCavebot then HelperCavebot.closeSupplies() end end

function cavebotSetWaypointMode(mode)
	if HelperCavebot then HelperCavebot.setWaypointMode(mode) end
end

function cavebotSetOption(name, checked)
	if HelperCavebot then HelperCavebot.setOption(name, checked == true) end
end

function cavebotSetNumericOption(name, value)
	if HelperCavebot then HelperCavebot.setNumericOption(name, value) end
end

function cavebotShowInfo(message)
	if HelperCavebot then HelperCavebot.showInfo(message) end
end

function cavebotOpenScriptsWindow()
	if HelperCavebot then HelperCavebot.openScriptsWindow() end
end

function cavebotCloseScriptsWindow()
	if HelperCavebot then HelperCavebot.closeScriptsWindow() end
end

function cavebotRemoveSelected()
	if HelperCavebot then HelperCavebot.removeSelected() end
end

function cavebotMoveSelected(delta)
	if HelperCavebot then HelperCavebot.moveSelected(tonumber(delta) or 0) end
end

function cavebotClear()
	if HelperCavebot then HelperCavebot.clear() end
end

function onCavebotEnableChange(checked)
	if HelperCavebot then HelperCavebot.onEnableChange(checked == true) end
end

function onCavebotLoopChange(checked)
	if HelperCavebot then HelperCavebot.onLoopChange(checked == true) end
end

function cavebotSaveScript()
	if HelperCavebot then HelperCavebot.saveScript() end
end

function cavebotLoadScript()
	if HelperCavebot then HelperCavebot.loadScript() end
end

function cavebotDeleteScript()
	if HelperCavebot then HelperCavebot.deleteScript() end
end

function onCavebotRecordingChange(checked)
	if HelperCavebot then HelperCavebot.onRecordingChange(checked == true) end
end

local var_0_119 = {
	rPrioLabel = 427,
	attackSpellPanel3 = 272,
	rManaLabel = 322,
	rSpellLabel = 274,
	sepCols = 262
}

function setShooterColumnLayout(arg_77_0)
	if not shooterPanel then
		return
	end

	for iter_77_0, iter_77_1 in pairs(arg_77_0) do
		local var_77_0 = shooterPanel:recursiveGetChildById(iter_77_0)

		if var_77_0 then
			var_77_0:setMarginLeft(iter_77_1)
		end
	end
end

function resetShooterColumnLayout()
	setShooterColumnLayout(var_0_119)
end

function onCreatureAppear(arg_79_0)
	if arg_79_0:isPlayer() then
		if arg_79_0:isPartyMember() and not arg_79_0:isLocalPlayer() then
			updatePartyFriendList()
		end

		return
	end

	if arg_79_0:getHealthPercent() <= 0 then
		return
	end

	if not var_0_78[arg_79_0:getId()] and arg_79_0:isMonster() and arg_79_0:getType() < 3 then
		var_0_78[arg_79_0:getId()] = arg_79_0
	end
end

function onCreatureDisappear(arg_80_0)
	if var_0_78[arg_80_0:getId()] then
		var_0_78[arg_80_0:getId()] = nil
	end

	if arg_80_0:isPlayer() then
		updatePartyFriendList()
	end
end

function onCreatureShieldChange(arg_81_0, arg_81_1)
	if arg_81_0:isPlayer() then
		updatePartyFriendList()
	end
end

function assignTrainingSpell(arg_82_0, arg_82_1)
	local previousWindow = g_ui.getRootWidget():recursiveGetChildById("assignSpellsWindow")

	if previousWindow then
		previousWindow:destroy()
	end

	local var_82_0 = UIRadioGroup.create()
	local var_82_1 = g_ui.createWidget("ActionBarSpellsWindow", g_ui.getRootWidget())

	if not var_82_1 then
		return
	end

	var_82_1:show(true)
	var_82_1:raise()
	var_82_1:focus()
	var_82_1:grabKeyboard()
	var_0_5:hide()
	local var_82_title = arg_82_1 and "Assign Haste Spell" or "Assign Training Spell"
	if var_82_1.setTitle then
		var_82_1:setTitle(var_82_title)
	else
		var_82_1:setText(var_82_title)
	end

	local var_82_2 = var_82_1.spellList
	local var_82_3 = var_82_1.preview
	local var_82_4 = var_82_1.image
	local var_82_5 = var_82_1.paramLabel
	local var_82_6 = var_82_1.paramText

	if var_82_1.spellFooter.dev then
		var_82_1.spellFooter.dev:hide()
	end

	local var_82_7 = getPlayerVocation()
	local var_82_8 = var_0_0:getLevel()
	local var_82_9 = modules.gamelib.SpellInfo.Default
	local var_82_10 = SpelllistSettings.Default.iconFile

	for iter_82_0, iter_82_1 in pairs(var_82_9) do
		if arg_82_1 and not table.contains(var_0_104[var_82_7], iter_82_1.id) then
			-- block empty
		elseif not arg_82_1 and table.contains(var_0_104[var_82_7], iter_82_1.id) then
			-- block empty
		elseif table.contains(iter_82_1.vocations, var_82_7) and not var_0_102[iter_82_1.id] then
			local var_82_11 = g_ui.createWidget("SpellPreview", var_82_2)
			local var_82_12 = getCrystalSpellIconId(iter_82_1, iter_82_0)

			if not var_82_12 then
				-- block empty
			else
				local var_82_13 = Spells.getImageClip(var_82_12, "Default")

				var_82_0:addWidget(var_82_11)
				var_82_11:setId(iter_82_1.id)
				var_82_11:setText(iter_82_0 .. "\n" .. iter_82_1.words)
				var_82_11.spellName = iter_82_0
				var_82_11.words = iter_82_1.words

				var_82_11.voc = iter_82_1.vocations
				var_82_11.param = iter_82_1.parameter
				var_82_11.source = var_82_10
				var_82_11.clip = var_82_13

				var_82_11.image:setImageSource(var_82_11.source)
				var_82_11.image:setImageClip(var_82_11.clip)

				if iter_82_1.level then
					var_82_11.spellLevel = iter_82_1.level

					var_82_11.levelLabel:setVisible(true)
					var_82_11.levelLabel:setText(string.format("Level: %d", iter_82_1.level))
					var_82_11.image.gray:setVisible(var_82_8 < iter_82_1.level)
				else
					var_82_11.spellLevel = 0
				end

				local var_82_14 = Spells.getPrimaryGroupId(iter_82_1) or -1

				if var_82_14 ~= -1 then
					local var_82_15 = var_82_14 == 2 and 20 or var_82_14 == 3 and 40 or 0

					var_82_11.imageGroup:setImageClip(var_82_15 .. " 0 20 20")
					var_82_11.imageGroup:setVisible(true)
				end
			end
		end
	end

	local var_82_16 = var_82_2:getChildren()

	table.sort(var_82_16, function(arg_83_0, arg_83_1)
		return arg_83_0:getText() < arg_83_1:getText()
	end)

	for iter_82_2, iter_82_3 in ipairs(var_82_16) do
		var_82_2:moveChildToIndex(iter_82_3, iter_82_2)
	end

	function var_82_0.onSelectionChange(arg_84_0, arg_84_1)
		if arg_84_1 then
			var_82_3:setText(arg_84_1:getText())
			var_82_4:setImageSource(arg_84_1.source)
			var_82_4:setImageClip(arg_84_1.clip)
			var_82_5:setOn(arg_84_1.param)
			var_82_6:setEnabled(arg_84_1.param)
			var_82_6:clearText()
			var_82_2:ensureChildVisible(arg_84_1)
		end
	end

	if #var_82_16 > 0 then
		var_82_0:selectWidget(var_82_16[1])
	end

	local function var_82_17()
		local var_85_0 = var_82_1.searchText:getText():lower()
		local var_85_1 = var_82_1.filterPanel.filterLearntSpells:isChecked()

		for iter_85_0, iter_85_1 in pairs(var_82_2:getChildren()) do
			local var_85_2 = iter_85_1:getText():lower():find(var_85_0) or var_85_0 == "" or #var_85_0 < 3
			local var_85_3 = not var_85_1 or var_0_99(var_0_0, tonumber(iter_85_1:getId()))

			iter_85_1:setVisible(var_85_2 and var_85_3)
		end
	end

	function var_82_1.searchText.onTextChange(arg_86_0)
		var_82_17()
	end

	function var_82_1.filterPanel.filterLearntSpells.onCheckChange(arg_87_0, arg_87_1)
		var_82_17()
	end

	function var_82_1.buttonClearSearchText.onClick()
		var_82_1.searchText:clearText()
	end

	local function var_82_18(arg_89_0)
		local var_89_0 = var_82_0:getSelectedWidget()

		if not var_89_0 then
			return
		end

		local var_89_1 = var_89_0.spellName or var_89_0:getText():match("^(.-)\n") or "Unknown"
		local var_89_2 = var_89_0.words or var_89_0:getText():match("\n(.+)") or ""
		local var_89_3 = tonumber(var_89_0:getId())

		if arg_82_1 then
			helperConfig.haste[1].id = var_89_3
		else
			helperConfig.training[1].id = var_89_3

			if helperConfig.training[1].percent == 0 then
				helperConfig.training[1].percent = 100
			end
		end

		arg_82_0:setImageSource(var_89_0.source)
		arg_82_0:setImageClip(var_89_0.clip)
		arg_82_0:setBorderColorTop("#1b1b1b")
		arg_82_0:setBorderColorLeft("#1b1b1b")
		arg_82_0:setBorderColorRight("#757575")
		arg_82_0:setBorderColorBottom("#757575")
		arg_82_0:setBorderWidth(1)
		arg_82_0:setTooltip("Spell: " .. var_89_1 .. "\nWords: " .. var_89_2)

		if arg_89_0 then
			var_0_5:show(true)
			var_82_1:destroy()
		end
	end

	local function var_82_19()
		var_0_5:show(true)
		var_82_1:destroy()
	end

	function var_82_1.spellFooter.buttonOk.onClick()
		var_82_18(true)
	end

	function var_82_1.spellFooter.buttonApply.onClick()
		var_82_18(false)
	end

	var_82_1.spellFooter.buttonClose.onClick = var_82_19

	function var_82_1.onEnter()
		var_82_18(true)
	end

	var_82_1.onEscape = var_82_19
end

local function var_0_120(arg_94_0)
	if helperConfig.shooterProfiles[arg_94_0] then
		return true, "There is already a preset with this name."
	elseif arg_94_0:len() == 0 then
		return true, "The name cannot be empty."
	elseif arg_94_0:len() > 7 then
		return true, "The name cannot be longer than 7 characters."
	elseif arg_94_0:match("[^%w]") then
		return true, "The name cannot contain special characters or spaces."
	end

	return false
end

function getPresetCategoryInfo(arg_95_0)
	return var_0_23[arg_95_0]
end

function padHealingData(arg_96_0)
	if type(arg_96_0) ~= "table" then
		return arg_96_0
	end

	if type(arg_96_0.spells) ~= "table" then
		arg_96_0.spells = {}
	end

	while #arg_96_0.spells < var_0_20 do
		table.insert(arg_96_0.spells, {
			id = 0,
			percent = 80
		})
	end

	if type(arg_96_0.potions) ~= "table" then
		arg_96_0.potions = {}
	end

	while #arg_96_0.potions < var_0_20 do
		table.insert(arg_96_0.potions, {
			percent = 50,
			id = 0,
			priority = 0
		})
	end

	return arg_96_0
end

function getPresetBucket(arg_97_0)
	local var_97_0 = var_0_23[arg_97_0]

	if not var_97_0 then
		return nil
	end

	return helperConfig[var_97_0.profilesKey]
end

function getSelectedPresetName(arg_98_0)
	local var_98_0 = var_0_23[arg_98_0]

	if not var_98_0 then
		return nil
	end

	return helperConfig[var_98_0.selectedKey]
end

function getPresetCount(arg_99_0)
	local var_99_0 = getPresetBucket(arg_99_0)
	local var_99_1 = 0

	if var_99_0 then
		for iter_99_0 in pairs(var_99_0) do
			var_99_1 = var_99_1 + 1
		end
	end

	return var_99_1
end

local function var_0_121(arg_100_0)
	return arg_100_0 == "shooter" and 7 or 16
end

function invalidPresetNameFor(arg_101_0, arg_101_1)
	local var_101_0 = var_0_23[arg_101_0]

	if not var_101_0 then
		return true, "Invalid category."
	end

	local var_101_1 = helperConfig[var_101_0.profilesKey]

	if var_101_1 and var_101_1[arg_101_1] then
		return true, "There is already a preset with this name."
	elseif arg_101_1:len() == 0 then
		return true, "The name cannot be empty."
	elseif arg_101_1:len() > var_0_121(arg_101_0) then
		return true, string.format("The name cannot be longer than %d characters.", var_0_121(arg_101_0))
	elseif arg_101_1:match("[^%w]") then
		return true, "The name cannot contain special characters or spaces."
	end

	return false
end

function capturePreset(arg_102_0)
	local var_102_0 = var_0_23[arg_102_0]

	if not var_102_0 then
		return nil
	end

	local var_102_1

	if not var_102_0.fields then
		var_102_1 = var_0_18(getShooterProfile())
	else
		var_102_1 = {}

		for iter_102_0, iter_102_1 in ipairs(var_102_0.fields) do
			var_102_1[iter_102_1] = var_0_18(helperConfig[iter_102_1])
		end
	end

	var_102_1.vocation = getPlayerVocation()

	return var_102_1
end

function syncActiveToSelectedProfiles()
	for iter_103_0, iter_103_1 in pairs(var_0_23) do
		if iter_103_1.fields then
			local var_103_0 = helperConfig[iter_103_1.profilesKey]
			local var_103_1 = helperConfig[iter_103_1.selectedKey]
			local var_103_2 = var_103_0 and var_103_1 and var_103_0[var_103_1]

			if var_103_2 then
				for iter_103_2, iter_103_3 in ipairs(iter_103_1.fields) do
					var_103_2[iter_103_3] = var_0_18(helperConfig[iter_103_3])
				end
			end
		end
	end
end

function applyPresetData(arg_104_0, arg_104_1)
	local var_104_0 = var_0_23[arg_104_0]

	if not var_104_0 then
		return false
	end

	local var_104_1 = helperConfig[var_104_0.profilesKey]
	local var_104_2 = var_104_1 and var_104_1[arg_104_1]

	if not var_104_2 then
		return false
	end

	helperConfig[var_104_0.selectedKey] = arg_104_1

	if var_104_0.fields then
		for iter_104_0, iter_104_1 in ipairs(var_104_0.fields) do
			if var_104_2[iter_104_1] ~= nil then
				helperConfig[iter_104_1] = var_0_18(var_104_2[iter_104_1])
			end
		end
	end

	if arg_104_0 == "healing" then
		padHealingData(helperConfig)
	end

	return true
end

function createPreset(arg_105_0, arg_105_1, arg_105_2)
	local var_105_0 = var_0_23[arg_105_0]

	if not var_105_0 then
		return false, "Invalid category."
	end

	local var_105_1, var_105_2 = invalidPresetNameFor(arg_105_0, arg_105_1)

	if var_105_1 then
		return false, var_105_2
	end

	local var_105_3 = arg_105_2 and var_0_18(arg_105_2) or capturePreset(arg_105_0)

	if not var_105_3 then
		return false, "Could not capture preset data."
	end

	if var_105_3.vocation == nil then
		var_105_3.vocation = getPlayerVocation()
	end

	if not helperConfig[var_105_0.profilesKey] then
		helperConfig[var_105_0.profilesKey] = {}
	end

	helperConfig[var_105_0.profilesKey][arg_105_1] = var_105_3

	return true
end

function duplicatePreset(arg_106_0, arg_106_1, arg_106_2)
	local var_106_0 = var_0_23[arg_106_0]

	if not var_106_0 then
		return false, "Invalid category."
	end

	local var_106_1 = helperConfig[var_106_0.profilesKey]
	local var_106_2 = var_106_1 and var_106_1[arg_106_1]

	if not var_106_2 then
		return false, "Source preset not found."
	end

	local var_106_3, var_106_4 = invalidPresetNameFor(arg_106_0, arg_106_2)

	if var_106_3 then
		return false, var_106_4
	end

	var_106_1[arg_106_2] = var_0_18(var_106_2)

	return true
end

function renamePreset(arg_107_0, arg_107_1, arg_107_2)
	local var_107_0 = var_0_23[arg_107_0]

	if not var_107_0 then
		return false, "Invalid category."
	end

	local var_107_1 = helperConfig[var_107_0.profilesKey]

	if not var_107_1 or not var_107_1[arg_107_1] then
		return false, "Preset not found."
	end

	if arg_107_1 == arg_107_2 then
		return true
	end

	local var_107_2, var_107_3 = invalidPresetNameFor(arg_107_0, arg_107_2)

	if var_107_2 then
		return false, var_107_3
	end

	var_107_1[arg_107_2] = var_107_1[arg_107_1]
	var_107_1[arg_107_1] = nil

	if helperConfig[var_107_0.selectedKey] == arg_107_1 then
		helperConfig[var_107_0.selectedKey] = arg_107_2
	end

	return true
end

function deletePreset(arg_108_0, arg_108_1)
	local var_108_0 = var_0_23[arg_108_0]

	if not var_108_0 then
		return false, "Invalid category."
	end

	local var_108_1 = helperConfig[var_108_0.profilesKey]

	if not var_108_1 or not var_108_1[arg_108_1] then
		return false, "Preset not found."
	end

	if getPresetCount(arg_108_0) <= 1 then
		return false, "You can't delete your only preset."
	end

	var_108_1[arg_108_1] = nil

	if helperConfig[var_108_0.selectedKey] == arg_108_1 then
		applyPresetData(arg_108_0, next(var_108_1))
	end

	return true
end

function listPresetsForVocation(arg_109_0, arg_109_1)
	local var_109_0 = getPresetBucket(arg_109_0)
	local var_109_1 = {}

	if var_109_0 then
		for iter_109_0, iter_109_1 in pairs(var_109_0) do
			local var_109_2 = iter_109_1.vocation or 0
			local var_109_3 = isMonkVocId(var_109_2) and isMonkVocId(arg_109_1)

			if not arg_109_1 or arg_109_1 == 0 or var_109_2 == 0 or var_109_2 == arg_109_1 or var_109_3 then
				table.insert(var_109_1, iter_109_0)
			end
		end
	end

	table.sort(var_109_1)

	return var_109_1
end

local var_0_122 = 1

function sanitizePresetData(arg_110_0, arg_110_1)
	local var_110_0 = var_0_23[arg_110_0]

	if not var_110_0 then
		return nil
	end

	local var_110_1 = var_0_18(var_110_0.default)

	if var_110_0.fields then
		for iter_110_0, iter_110_1 in ipairs(var_110_0.fields) do
			if arg_110_1[iter_110_1] ~= nil then
				var_110_1[iter_110_1] = var_0_18(arg_110_1[iter_110_1])
			end
		end
	else
		for iter_110_2 in pairs(var_110_0.default) do
			if arg_110_1[iter_110_2] ~= nil then
				var_110_1[iter_110_2] = var_0_18(arg_110_1[iter_110_2])
			end
		end
	end

	if arg_110_0 == "healing" then
		padHealingData(var_110_1)
	end

	return var_110_1
end

local function var_0_123(arg_111_0, arg_111_1)
	local var_111_0 = getPresetBucket(arg_111_0) or {}
	local var_111_1 = var_0_121(arg_111_0)

	arg_111_1 = tostring(arg_111_1):gsub("[^%w]", "")

	if arg_111_1:len() == 0 then
		arg_111_1 = "Import"
	end

	if var_111_1 < arg_111_1:len() then
		arg_111_1 = arg_111_1:sub(1, var_111_1)
	end

	if not var_111_0[arg_111_1] then
		return arg_111_1
	end

	for iter_111_0 = 1, 99 do
		local var_111_2 = tostring(iter_111_0)
		local var_111_3 = arg_111_1:sub(1, math.max(1, var_111_1 - var_111_2:len())) .. var_111_2

		if not var_111_0[var_111_3] then
			return var_111_3
		end
	end

	return arg_111_1
end

function exportPreset(arg_112_0, arg_112_1)
	local var_112_0 = var_0_23[arg_112_0]

	if not var_112_0 then
		return nil, "Invalid category."
	end

	local var_112_1 = helperConfig[var_112_0.profilesKey]
	local var_112_2 = var_112_1 and var_112_1[arg_112_1]

	if not var_112_2 then
		return nil, "Preset not found."
	end

	local var_112_3 = {
		tp = var_0_122,
		cat = arg_112_0,
		voc = var_112_2.vocation or 0,
		name = arg_112_1,
		data = var_0_18(var_112_2)
	}
	local var_112_4, var_112_5 = pcall(function()
		return json.encode(var_112_3)
	end)

	if not var_112_4 or type(var_112_5) ~= "string" then
		return nil, "Could not encode preset."
	end

	return base64.encode(var_112_5)
end

function importPreset(arg_114_0, arg_114_1)
	if type(arg_114_0) ~= "string" then
		return false, "Invalid import string."
	end

	arg_114_0 = arg_114_0:gsub("%s", "")

	if arg_114_0:len() == 0 then
		return false, "Empty import string."
	end

	local var_114_0, var_114_1 = pcall(function()
		return base64.decode(arg_114_0)
	end)

	if not var_114_0 or type(var_114_1) ~= "string" or var_114_1:len() == 0 then
		return false, "Invalid import string."
	end

	local var_114_2, var_114_3 = pcall(function()
		return json.decode(var_114_1)
	end)

	if not var_114_2 or type(var_114_3) ~= "table" then
		return false, "Corrupted preset data."
	end

	if var_114_3.tp ~= var_0_122 then
		return false, "Unsupported preset version."
	end

	if var_114_3.all == true then
		local var_114_4, var_114_5 = importAllPresets(var_114_3)

		return var_114_4, var_114_5, nil
	end

	local var_114_6 = var_114_3.cat

	if not var_0_23[var_114_6] then
		return false, "Unknown preset category."
	end

	if type(var_114_3.data) ~= "table" then
		return false, "Missing preset data."
	end

	local var_114_7 = sanitizePresetData(var_114_6, var_114_3.data)

	if not var_114_7 then
		return false, "Could not read preset data."
	end

	var_114_7.vocation = tonumber(var_114_3.voc) or 0

	local var_114_8 = var_0_123(var_114_6, arg_114_1 or var_114_3.name or "Import")
	local var_114_9, var_114_10 = invalidPresetNameFor(var_114_6, var_114_8)

	if var_114_9 then
		return false, var_114_10
	end

	helperConfig[var_0_23[var_114_6].profilesKey][var_114_8] = var_114_7

	return true, var_114_8, var_114_6
end

function exportAllPresets()
	local var_117_0 = {
		all = true,
		tp = var_0_122,
		presets = {},
		selected = {}
	}

	for iter_117_0, iter_117_1 in pairs(var_0_23) do
		local var_117_1 = helperConfig[iter_117_1.profilesKey]

		if type(var_117_1) == "table" then
			local var_117_2 = {}

			for iter_117_2, iter_117_3 in pairs(var_117_1) do
				if type(iter_117_3) == "table" then
					var_117_2[iter_117_2] = var_0_18(iter_117_3)
				end
			end

			var_117_0.presets[iter_117_0] = var_117_2
		end

		local var_117_3 = helperConfig[iter_117_1.selectedKey]

		if var_117_3 then
			var_117_0.selected[iter_117_0] = var_117_3
		end
	end

	local var_117_4, var_117_5 = pcall(function()
		return json.encode(var_117_0)
	end)

	if not var_117_4 or type(var_117_5) ~= "string" then
		return nil, "Could not encode presets."
	end

	return base64.encode(var_117_5)
end

function importAllPresets(arg_119_0)
	if type(arg_119_0.presets) ~= "table" then
		return false, "Missing preset data."
	end

	local var_119_0 = 0

	for iter_119_0, iter_119_1 in pairs(arg_119_0.presets) do
		local var_119_1 = var_0_23[iter_119_0]

		if var_119_1 and type(iter_119_1) == "table" then
			if type(helperConfig[var_119_1.profilesKey]) ~= "table" then
				helperConfig[var_119_1.profilesKey] = {}
			end

			for iter_119_2, iter_119_3 in pairs(iter_119_1) do
				if type(iter_119_3) == "table" then
					local var_119_2 = sanitizePresetData(iter_119_0, iter_119_3)

					if var_119_2 then
						var_119_2.vocation = tonumber(iter_119_3.vocation) or 0

						local var_119_3 = var_0_123(iter_119_0, iter_119_2)

						helperConfig[var_119_1.profilesKey][var_119_3] = var_119_2
						var_119_0 = var_119_0 + 1
					end
				end
			end
		end
	end

	if var_119_0 == 0 then
		return false, "No presets found to import."
	end

	return true, string.format("%d preset(s) imported.", var_119_0), var_119_0
end

local var_0_124 = {
	Healing = "healing",
	["Tyron Caster"] = "shooter",
	["Tools & Support"] = "tools"
}
local var_0_125 = {
	"Healing",
	"Tools & Support",
	"Tyron Caster"
}
local var_0_126 = {
	All = 0,
	Monk = 9,
	Druid = 6,
	Sorcerer = 5,
	Paladin = 7,
	Knight = 8
}
local var_0_127 = {
	"All",
	"Knight",
	"Paladin",
	"Sorcerer",
	"Druid",
	"Monk"
}
local var_0_128 = "healing"
local var_0_129 = 0

local function var_0_130(arg_120_0)
	if not settingsPanel then
		return nil
	end

	return settingsPanel:recursiveGetChildById(arg_120_0)
end

local function var_0_131(arg_121_0)
	for iter_121_0, iter_121_1 in pairs(var_0_124) do
		if iter_121_1 == arg_121_0 then
			return iter_121_0
		end
	end

	return "Healing"
end

local function var_0_132(arg_122_0)
	for iter_122_0, iter_122_1 in pairs(var_0_126) do
		if iter_122_1 == arg_122_0 then
			return iter_122_0
		end
	end

	return "All"
end

local function var_0_133()
	if not g_game.isOnline() then
		return
	end

	saveSettings()
	reset()
	loadSettings()

	for iter_123_0 in pairs(var_0_23) do
		local var_123_0 = var_0_23[iter_123_0]
		local var_123_1 = var_123_0 and helperConfig[var_123_0.selectedKey]

		if var_123_1 and getPresetBucket(iter_123_0) and getPresetBucket(iter_123_0)[var_123_1] then
			applyPresetData(iter_123_0, var_123_1)
		end
	end

	loadProfileOptions()
	onLoadHelperData()
	updatePartyFriendList()
end

local var_0_134 = false

function settingsRefreshPresetCombo()
	local var_124_0 = var_0_130("presetCombo")

	if not var_124_0 then
		return
	end

	var_0_134 = true

	var_124_0:clear()

	local var_124_1 = listProfileNames()

	for iter_124_0, iter_124_1 in ipairs(var_124_1) do
		var_124_0:addOption(iter_124_1)
	end

	local var_124_2 = getCurrentProfileName()
	local var_124_3 = false

	for iter_124_2, iter_124_3 in ipairs(var_124_1) do
		if iter_124_3 == var_124_2 then
			var_124_3 = true

			break
		end
	end

	if var_124_3 then
		var_124_0:setCurrentOption(var_124_2, true)
	elseif #var_124_1 > 0 then
		var_124_0:setCurrentOption(var_124_1[1], true)
	end

	var_0_134 = false

	refreshShooterPresetCombo()
	settingsResetExport()
end

local var_0_135 = {
	"healing",
	"tools",
	"shooter"
}

function getCurrentProfileName()
	return getSelectedPresetName("healing") or getSelectedPresetName("tools") or getSelectedPresetName("shooter")
end

function listProfileNames()
	local var_126_0 = getPlayerVocation()
	local var_126_1 = {}
	local var_126_2 = {}

	for iter_126_0, iter_126_1 in ipairs(var_0_135) do
		for iter_126_2, iter_126_3 in ipairs(listPresetsForVocation(iter_126_1, var_126_0)) do
			if not var_126_1[iter_126_3] then
				var_126_1[iter_126_3] = true
				var_126_2[#var_126_2 + 1] = iter_126_3
			end
		end
	end

	table.sort(var_126_2)

	return var_126_2
end

function profileCount()
	return #listProfileNames()
end

function openSettingsTab()
	if not settingsPanel then
		return
	end

	local var_128_0 = var_0_130("exportEdit")

	if var_128_0 then
		var_128_0:setText("")
	end

	local var_128_1 = var_0_130("importEdit")

	if var_128_1 then
		var_128_1:setText("")
	end

	settingsRefreshPresetCombo()
end

function settingsSelectPreset(arg_129_0)
	if var_0_134 then
		return
	end

	if not arg_129_0 or arg_129_0 == "" then
		return
	end

	if arg_129_0 == getCurrentProfileName() then
		return
	end

	for iter_129_0, iter_129_1 in ipairs(var_0_135) do
		local var_129_0 = getPresetBucket(iter_129_1)

		if var_129_0 and var_129_0[arg_129_0] then
			applyPresetData(iter_129_1, arg_129_0)
		end
	end

	var_0_133()
	settingsRefreshPresetCombo()
end

function openPresetNameWindow(arg_130_0, arg_130_1, arg_130_2)
	local var_130_0 = g_ui.loadUI("styles/shooterPreset", g_ui.getRootWidget())

	if not var_130_0 then
		return
	end

	var_130_0:setText(arg_130_0)

	local var_130_1 = var_130_0.contentPanel.target
	local var_130_2 = var_130_0.contentPanel.warning

	var_130_1:setMaxLength(var_0_121(var_0_128))
	var_130_1:setText(arg_130_1 or "")
	var_130_0:show(true)
	var_130_0:raise()
	var_130_0:focus()
	var_130_1:focus()
	var_0_5:hide()

	local function var_130_3()
		var_0_5:show(true)
		var_130_0:destroy()
	end

	function var_130_1.onTextChange()
		local var_132_0, var_132_1 = invalidPresetNameFor(var_0_128, var_130_1:getText())

		var_130_2:setVisible(var_132_0 and true or false)
		var_130_2:setTooltip(var_132_0 and var_132_1 or "")
	end

	function var_130_0.contentPanel.okButton.onClick()
		local var_133_0 = var_130_1:getText()
		local var_133_1, var_133_2 = arg_130_2(var_133_0)

		if var_133_1 == false then
			var_130_2:setVisible(true)
			var_130_2:setTooltip(var_133_2 or "Invalid name.")

			return
		end

		var_130_3()
	end

	var_130_0.contentPanel.cancelButton.onClick = var_130_3
	var_130_0.onEscape = var_130_3
end

function settingsNewPreset()
	openPresetNameWindow(tr("New preset"), "", function(arg_135_0)
		for iter_135_0, iter_135_1 in ipairs(var_0_135) do
			local var_135_0, var_135_1 = invalidPresetNameFor(iter_135_1, arg_135_0)

			if var_135_0 then
				return false, var_135_1
			end
		end

		for iter_135_2, iter_135_3 in ipairs(var_0_135) do
			createPreset(iter_135_3, arg_135_0, capturePreset(iter_135_3))
			applyPresetData(iter_135_3, arg_135_0)
		end

		saveSettings()
		settingsRefreshPresetCombo()

		return true
	end)
end

function settingsDuplicatePreset()
	local var_136_0 = getCurrentProfileName()

	if not var_136_0 then
		return
	end

	openPresetNameWindow(tr("Duplicate preset"), "", function(arg_137_0)
		for iter_137_0, iter_137_1 in ipairs(var_0_135) do
			local var_137_0, var_137_1 = invalidPresetNameFor(iter_137_1, arg_137_0)

			if var_137_0 then
				return false, var_137_1
			end
		end

		for iter_137_2, iter_137_3 in ipairs(var_0_135) do
			local var_137_2 = getPresetBucket(iter_137_3)

			if var_137_2 and var_137_2[var_136_0] then
				duplicatePreset(iter_137_3, var_136_0, arg_137_0)
			else
				createPreset(iter_137_3, arg_137_0, capturePreset(iter_137_3))
			end

			applyPresetData(iter_137_3, arg_137_0)
		end

		saveSettings()
		settingsRefreshPresetCombo()

		return true
	end)
end

function settingsRenamePreset()
	local var_138_0 = getCurrentProfileName()

	if not var_138_0 then
		return
	end

	openPresetNameWindow(tr("Rename preset"), var_138_0, function(arg_139_0)
		if arg_139_0 == var_138_0 then
			return true
		end

		for iter_139_0, iter_139_1 in ipairs(var_0_135) do
			local var_139_0 = getPresetBucket(iter_139_1)

			if var_139_0 and var_139_0[var_138_0] then
				local var_139_1, var_139_2 = invalidPresetNameFor(iter_139_1, arg_139_0)

				if var_139_1 then
					return false, var_139_2
				end
			end
		end

		for iter_139_2, iter_139_3 in ipairs(var_0_135) do
			local var_139_3 = getPresetBucket(iter_139_3)

			if var_139_3 and var_139_3[var_138_0] then
				renamePreset(iter_139_3, var_138_0, arg_139_0)
			end
		end

		saveSettings()
		settingsRefreshPresetCombo()

		return true
	end)
end

function settingsDeletePreset()
	local var_140_0 = getCurrentProfileName()

	if not var_140_0 then
		return
	end

	if profileCount() <= 1 then
		modules.game_textmessage.displayGameMessage("You can't delete your only preset.")

		return
	end

	local var_140_1

	local function var_140_2()
		if var_140_1 then
			var_140_1:destroy()
		end
	end

	local function var_140_3()
		if var_140_1 then
			var_140_1:destroy()
		end

		for iter_142_0, iter_142_1 in ipairs(var_0_135) do
			local var_142_0 = getPresetBucket(iter_142_1)

			if var_142_0 and var_142_0[var_140_0] then
				deletePreset(iter_142_1, var_140_0)
			end
		end

		var_0_133()
		settingsRefreshPresetCombo()
		modules.game_textmessage.displayGameMessage(string.format("Preset %s deleted.", var_140_0))
	end

	var_140_1 = displayGeneralBox(tr("Delete Preset"), string.format("Are you sure you want to delete preset %s?", var_140_0), {
		{
			text = tr("Yes"),
			callback = var_140_3
		},
		{
			text = tr("No"),
			callback = var_140_2
		}
	})
end

function settingsExportPreset()
	local var_143_0 = getSelectedPresetName(var_0_128)

	if not var_143_0 then
		return
	end

	local var_143_1, var_143_2 = exportPreset(var_0_128, var_143_0)

	if not var_143_1 then
		modules.game_textmessage.displayGameMessage(var_143_2 or "Export failed.")

		return
	end

	local var_143_3 = var_0_130("exportEdit")

	if var_143_3 then
		var_143_3:setText(var_143_1)
	end

	g_window.setClipboardText(var_143_1)
	modules.game_textmessage.displayGameMessage("Preset copied to clipboard.")
end

function settingsExportAll()
	local var_144_0, var_144_1 = exportAllPresets()

	if not var_144_0 then
		modules.game_textmessage.displayGameMessage(var_144_1 or "Export failed.")

		return
	end

	local var_144_2 = var_0_130("exportEdit")

	if var_144_2 then
		var_144_2:setText(var_144_0)
	end

	g_window.setClipboardText(var_144_0)
	modules.game_textmessage.displayGameMessage("All presets copied to clipboard.")
end

function settingsImportPreset()
	local var_145_0 = var_0_130("importEdit")

	if not var_145_0 then
		return
	end

	local var_145_1, var_145_2, var_145_3 = importPreset(var_145_0:getText())

	if not var_145_1 then
		modules.game_textmessage.displayGameMessage(var_145_2 or "Import failed.")

		return
	end

	saveSettings()
	var_145_0:setText("")

	if var_145_3 == nil then
		settingsRefreshPresetCombo()
	elseif var_145_3 == var_0_128 then
		settingsRefreshPresetCombo()

		local var_145_4 = var_0_130("presetCombo")

		if var_145_4 then
			var_145_4:setCurrentOption(var_145_2, true)
		end
	end

	modules.game_textmessage.displayGameMessage(var_145_2 or "Import done.")
end

local var_0_136 = 2
local var_0_137 = {
	nil,
	nil,
	nil,
	nil,
	"SR",
	"DR",
	"PL",
	"KN",
	"MK",
	"MK"
}
local var_0_138 = {
	MK = "Monks",
	KN = "Knights",
	PL = "Paladins",
	DR = "Druids",
	SR = "Sorcerers"
}

local function var_0_139(arg_146_0)
	for iter_146_0, iter_146_1 in pairs(var_0_23) do
		local var_146_0 = helperConfig[iter_146_1.profilesKey]

		if type(var_146_0) == "table" and var_146_0[arg_146_0] ~= nil then
			return false
		end
	end

	return true
end

local function var_0_140(arg_147_0)
	arg_147_0 = tostring(arg_147_0 or ""):gsub("[^%w]", "")

	if arg_147_0:len() == 0 then
		arg_147_0 = "Import"
	end

	if arg_147_0:len() > 18 then
		arg_147_0 = arg_147_0:sub(1, 18)
	end

	if var_0_139(arg_147_0) then
		return arg_147_0
	end

	for iter_147_0 = 1, 99 do
		local var_147_0 = tostring(iter_147_0)
		local var_147_1 = arg_147_0:sub(1, math.max(1, 18 - var_147_0:len())) .. var_147_0

		if var_0_139(var_147_1) then
			return var_147_1
		end
	end

	return arg_147_0
end

function exportFullConfig()
	if type(g_crypt.compress) ~= "function" then
		return nil, "Outdated client: restart to update (missing compression)."
	end

	local var_148_0 = getPlayerVocation()
	local var_148_1 = var_0_137[var_148_0]

	if not var_148_1 then
		return nil, "Unknown vocation."
	end

	local var_148_2 = {
		tp = var_0_136,
		voc = var_148_0,
		presets = {}
	}

	for iter_148_0 in pairs(var_0_23) do
		local var_148_3 = capturePreset(iter_148_0)

		if type(var_148_3) == "table" then
			var_148_2.presets[iter_148_0] = var_148_3
		end
	end

	local var_148_4, var_148_5 = pcall(function()
		return json.encode(var_148_2)
	end)

	if not var_148_4 or type(var_148_5) ~= "string" then
		return nil, "Could not encode config."
	end

	local var_148_6 = g_crypt.compress(var_148_5)

	if type(var_148_6) ~= "string" or var_148_6:len() == 0 then
		return nil, "Could not compress config."
	end

	return var_148_1 .. "-" .. base64.encode(var_148_6)
end

function importFullConfig(arg_150_0, arg_150_1)
	if type(g_crypt.uncompress) ~= "function" then
		return false, "Outdated client: restart to update (missing compression)."
	end

	if type(arg_150_0) ~= "string" then
		return false, "Invalid code."
	end

	arg_150_0 = arg_150_0:gsub("%s", "")

	local var_150_0, var_150_1 = arg_150_0:match("^(%u%u)%-(.+)$")

	if not var_150_0 or not var_150_1 then
		return false, "Invalid code format."
	end

	local var_150_2 = getPlayerVocation()
	local var_150_3 = var_0_137[var_150_2]

	if not var_150_3 then
		return false, "Unknown vocation."
	end

	if var_150_0 ~= var_150_3 then
		return false, string.format("This config is for %s, not your vocation.", var_0_138[var_150_0] or var_150_0)
	end

	local var_150_4, var_150_5 = pcall(function()
		return base64.decode(var_150_1)
	end)

	if not var_150_4 or type(var_150_5) ~= "string" or var_150_5:len() == 0 then
		return false, "Invalid code."
	end

	local var_150_6 = g_crypt.uncompress(var_150_5)

	if type(var_150_6) ~= "string" or var_150_6:len() == 0 then
		return false, "Corrupted code."
	end

	local var_150_7, var_150_8 = pcall(function()
		return json.decode(var_150_6)
	end)

	if not var_150_7 or type(var_150_8) ~= "table" then
		return false, "Corrupted config data."
	end

	if var_150_8.tp ~= var_0_136 then
		return false, "Unsupported config version."
	end

	if type(var_150_8.presets) ~= "table" then
		return false, "Missing config data."
	end

	local var_150_9 = var_0_140(arg_150_1)
	local var_150_10 = 0

	for iter_150_0, iter_150_1 in pairs(var_150_8.presets) do
		local var_150_11 = var_0_23[iter_150_0]

		if var_150_11 and type(iter_150_1) == "table" then
			local var_150_12 = sanitizePresetData(iter_150_0, iter_150_1)

			if var_150_12 then
				var_150_12.vocation = var_150_2

				if type(helperConfig[var_150_11.profilesKey]) ~= "table" then
					helperConfig[var_150_11.profilesKey] = {}
				end

				helperConfig[var_150_11.profilesKey][var_150_9] = var_150_12

				applyPresetData(iter_150_0, var_150_9)

				var_150_10 = var_150_10 + 1
			end
		end
	end

	if var_150_10 == 0 then
		return false, "No presets found in code."
	end

	return true, var_150_9
end

function settingsResetExport()
	local var_153_0 = var_0_130("exportEdit")
	local var_153_1 = var_0_130("exportBtn")

	if var_153_0 then
		var_153_0:setText("")
	end

	if var_153_1 then
		var_153_1:setText("Generate")
	end
end

function settingsExportFull()
	local var_154_0 = var_0_130("exportEdit")
	local var_154_1 = var_0_130("exportBtn")

	if not var_154_0 or not var_154_1 then
		return
	end

	if var_154_1:getText() == "Copy" and var_154_0:getText() ~= "" then
		g_window.setClipboardText(var_154_0:getText())
		modules.game_textmessage.displayGameMessage("Helper config copied to clipboard.")

		return
	end

	local var_154_2, var_154_3 = exportFullConfig()

	if not var_154_2 then
		modules.game_textmessage.displayGameMessage(var_154_3 or "Export failed.")

		return
	end

	var_154_0:setText(var_154_2)
	var_154_1:setText("Copy")
end

function settingsImportFull()
	local var_155_0 = var_0_130("importEdit")

	if not var_155_0 then
		return
	end

	local var_155_1 = var_155_0:getText()

	if type(var_155_1) ~= "string" or var_155_1:gsub("%s", "") == "" then
		modules.game_textmessage.displayGameMessage("Paste a config code first.")

		return
	end

	displayInputBox(tr("Import Helper Config"), tr("Name for the imported preset:"), function(arg_156_0)
		local var_156_0, var_156_1 = importFullConfig(var_155_1, arg_156_0)

		if not var_156_0 then
			modules.game_textmessage.displayGameMessage(var_156_1 or "Import failed.")

			return
		end

		var_0_133()
		saveSettings()
		var_155_0:setText("")
		settingsRefreshPresetCombo()

		local var_156_2 = var_0_130("presetCombo")

		if var_156_2 then
			var_156_2:setCurrentOption(var_156_1, true)
		end

		modules.game_textmessage.displayGameMessage("Imported as \"" .. var_156_1 .. "\".")
	end, nil, "", 18)
end

function previewImportCode(arg_157_0)
	if type(arg_157_0) ~= "string" then
		return "empty"
	end

	arg_157_0 = arg_157_0:gsub("%s", "")

	if arg_157_0 == "" then
		return "empty"
	end

	local var_157_0 = arg_157_0:match("^(%u%u)%-")

	if not var_157_0 then
		return "invalid"
	end

	local var_157_1 = var_0_137[getPlayerVocation()]

	if not var_157_1 then
		return "invalid"
	end

	if var_157_0 ~= var_157_1 then
		return "wrong"
	end

	return "ok"
end

function settingsValidateImport(arg_158_0)
	local var_158_0 = var_0_130("importEdit")
	local var_158_1 = var_0_130("importBtn")
	local var_158_2 = previewImportCode(arg_158_0)

	if var_158_0 then
		if var_158_2 == "ok" then
			var_158_0:setColor("#44ad25")
			var_158_0:removeTooltip()
		elseif var_158_2 == "empty" then
			var_158_0:setColor("#c0c0c0")
			var_158_0:removeTooltip()
		elseif var_158_2 == "wrong" then
			var_158_0:setColor("#d33c3c")
			var_158_0:setTooltip(tr("You tried to insert a wrong vocation preset"))
		else
			var_158_0:setColor("#d33c3c")
			var_158_0:setTooltip(tr("Invalid preset code"))
		end
	end

	if var_158_1 then
		var_158_1:setEnabled(var_158_2 == "ok")
		var_158_1:setText(var_158_2 == "wrong" and tr("Wrong Vocation") or tr("Load"))
	end
end

function sendRenameOrAddWindow(arg_159_0)
	local var_159_0 = g_ui.loadUI("styles/shooterPreset", g_ui.getRootWidget())

	if not var_159_0 then
		return
	end

	if arg_159_0 then
		var_159_0:setText("Rename shooter preset")
		var_159_0.contentPanel.target:setText(helperConfig.selectedShooterProfile)
	else
		var_159_0:setText("New shooter preset")
		var_159_0.contentPanel.target:setText("")
	end

	local var_159_1 = presetsPanel:recursiveGetChildById("presets")

	var_159_0:show(true)
	var_159_0:raise()
	var_159_0:focus()
	var_159_0.contentPanel.target:focus()
	var_0_5:hide()

	local function var_159_2()
		var_0_5:show(true)
		var_159_0:destroy()
	end

	local function var_159_3()
		local var_161_0 = var_159_0.contentPanel.warning
		local var_161_1 = var_159_0.contentPanel.target:getText()
		local var_161_2, var_161_3 = var_0_120(var_161_1)

		if var_161_2 then
			var_161_0:setVisible(true)
			var_161_0:setTooltip(var_161_3)
		else
			var_161_0:setVisible(false)
			var_161_0:setTooltip("")
		end
	end

	local function var_159_4()
		local var_162_0 = var_159_0.contentPanel.target:getText()

		if var_162_0 == helperConfig.selectedShooterProfile then
			var_159_2()

			return
		end

		local var_162_1, var_162_2 = var_0_120(var_162_0)

		if var_162_1 then
			return
		end

		local var_162_3 = helperConfig.selectedShooterProfile
		local var_162_4 = helperConfig.shooterProfiles[var_162_3]

		if var_162_4 then
			helperConfig.shooterProfiles[var_162_0] = var_162_4
			helperConfig.selectedShooterProfile = var_162_0

			var_159_1:addOption(var_162_0)
			var_159_1:setCurrentOption(var_162_0, true)

			helperConfig.shooterProfiles[var_162_3] = nil

			var_159_1:removeOption(var_162_3)

			local var_162_5 = var_0_6:recursiveGetChildById("currentPresetName")

			if var_162_5 then
				var_162_5:setText(var_162_0)
			end
		end

		saveSettings()
		var_159_2()
	end

	local function var_159_5()
		local var_163_0 = var_159_0.contentPanel.target:getText()
		local var_163_1, var_163_2 = var_0_120(var_163_0)

		if var_163_1 then
			return
		end

		local var_163_3 = getShooterProfile()
		local var_163_4 = var_0_18(var_163_3)

		helperConfig.shooterProfiles[var_163_0] = var_163_4
		helperConfig.selectedShooterProfile = var_163_0

		var_159_1:addOption(var_163_0)
		var_159_1:setCurrentOption(var_163_0, true)

		local var_163_5 = var_0_6:recursiveGetChildById("currentPresetName")

		if var_163_5 then
			var_163_5:setText(var_163_0)
		end

		saveSettings()
		var_159_2()
	end

	var_159_0.contentPanel.cancelButton.onClick = var_159_2
	var_159_0.onEscape = var_159_2

	function var_159_0.contentPanel.target.onTextChange()
		var_159_3()
	end

	if arg_159_0 then
		function var_159_0.contentPanel.okButton.onClick()
			var_159_4()
		end

		function var_159_0.contentPanel.onEnter()
			var_159_4()
		end
	else
		function var_159_0.contentPanel.okButton.onClick()
			var_159_5()
		end

		function var_159_0.contentPanel.onEnter()
			var_159_5()
		end
	end
end

function isKnightVoc()
	return getPlayerVocation() == 8
end

function usesExtendedSpellSlots()
	local var_170_0 = getPlayerVocation()

	return var_170_0 == 8 or var_170_0 == 6 or var_170_0 == 5 or isMonkVocId(var_170_0)
end

function getAreaSpellSlots()
	if isMonkVocId(getPlayerVocation()) then
		return {
			0,
			1,
			2,
			5,
			7
		}
	end

	if usesExtendedSpellSlots() then
		return {
			0,
			1,
			2,
			5
		}
	end

	return {
		0,
		1,
		2
	}
end

function getSingleSpellSlots()
	if usesExtendedSpellSlots() then
		return {
			3,
			4,
			6
		}
	end

	return {
		3,
		4
	}
end

function getAllSpellSlots()
	return {
		0,
		1,
		2,
		3,
		4,
		5,
		6,
		7
	}
end

function isAoeSpellSlot(arg_174_0)
	arg_174_0 = tonumber(arg_174_0)

	return table.contains(getAreaSpellSlots(), arg_174_0)
end

function getSpellSlotRank(arg_175_0, arg_175_1)
	arg_175_0 = tonumber(arg_175_0)

	local var_175_0 = isAoeSpellSlot(arg_175_0) and getAreaSpellSlots() or getSingleSpellSlots()
	local var_175_1 = {}

	for iter_175_0, iter_175_1 in ipairs(var_175_0) do
		local var_175_2 = arg_175_1.spells[iter_175_1 + 1]

		if var_175_2 then
			var_175_1[#var_175_1 + 1] = {
				idx = iter_175_1,
				prio = var_175_2.priority or 999
			}
		end
	end

	table.sort(var_175_1, function(arg_176_0, arg_176_1)
		return arg_176_0.prio < arg_176_1.prio
	end)

	for iter_175_2, iter_175_3 in ipairs(var_175_1) do
		if iter_175_3.idx == arg_175_0 then
			return iter_175_2, var_175_1
		end
	end

	return 1, var_175_1
end

function isAoeRuneSlot(arg_177_0)
	return tonumber(arg_177_0) <= 1
end

function isAreaSpellData(arg_178_0)
	if arg_178_0.area then
		return true
	end

	return table.contains(var_0_97, arg_178_0.id)
end

function assignSpell(arg_179_0, arg_179_1, arg_179_2, arg_179_3, arg_179_4)
	local previousWindow = g_ui.getRootWidget():recursiveGetChildById("assignSpellsWindow")

	if previousWindow then
		previousWindow:destroy()
	end

	local var_179_0 = UIRadioGroup.create()
	local var_179_1 = g_ui.createWidget("ActionBarSpellsWindow", g_ui.getRootWidget())

	if not var_179_1 then
		return true
	end

	var_179_1:show(true)
	var_179_1:raise()
	var_179_1:focus()
	var_179_1:grabKeyboard()
	var_0_5:hide()
	local var_179_title = "Assign " .. arg_179_1 .. " Spell"
	if var_179_1.setTitle then
		var_179_1:setTitle(var_179_title)
	else
		var_179_1:setText(var_179_title)
	end

	local var_179_2 = var_179_1.spellList
	local var_179_3 = var_179_1.preview
	local var_179_4 = var_179_1.image
	local var_179_5 = var_179_1.paramLabel
	local var_179_6 = var_179_1.paramText

	if var_179_1.spellFooter.dev then
		var_179_1.spellFooter.dev:hide()
	end

	local var_179_7 = getShooterProfile()
	local var_179_8 = getPlayerVocation()
	local var_179_9 = var_0_0:getLevel()
	local var_179_10 = modules.gamelib.SpellInfo.Default
	local var_179_11 = SpelllistSettings.Default.iconFile
	local var_179_12 = arg_179_0:getId():find("attackSpellButton") ~= nil
	local var_179_13 = tonumber(arg_179_0:getId():match("%d+"))
	local var_179_14 = var_179_12 and isAoeSpellSlot(var_179_13)
	local var_179_15 = var_0_100()

	local function var_179_16(arg_180_0, arg_180_1)
		for iter_180_0, iter_180_1 in ipairs(arg_180_1) do
			if table.contains(arg_180_0, iter_180_1) then
				return true
			end
		end

		return false
	end

	for iter_179_0, iter_179_1 in pairs(var_179_10) do
		local var_179_17 = Spells.getGroupIds(iter_179_1)
		local var_179_18 = getCrystalSpellIconId(iter_179_1, iter_179_0)
		local var_179_19 = iter_179_1.id
		local var_179_20 = true

		if var_179_12 then
			local var_179_21 = isAreaSpellData(iter_179_1)

			var_179_20 = var_179_14 and var_179_21 or not var_179_14 and not var_179_21
		end

		-- Crystal does not always receive the learnt-spell id list. Requiring
		-- player:getSpells() here made every selector empty.
		if var_179_16(var_179_17, arg_179_2) and var_179_20 and (not arg_179_4 or arg_179_4[var_179_19]) and table.contains(iter_179_1.vocations, var_179_8) and not var_0_98[var_179_19] and iter_179_1.level and (var_179_15 or var_179_9 >= iter_179_1.level) then
			local var_179_22 = g_ui.createWidget("SpellPreview", var_179_2)
			local var_179_23 = Spells.getImageClip(var_179_18, "Default")

			var_179_0:addWidget(var_179_22)
			var_179_22:setId(var_179_19)
			var_179_22:setText(iter_179_0 .. "\n" .. iter_179_1.words)
			var_179_22.spellName = iter_179_0
			var_179_22.words = iter_179_1.words

			var_179_22.voc = iter_179_1.vocations
			var_179_22.param = iter_179_1.parameter
			var_179_22.source = var_179_11
			var_179_22.clip = var_179_23
			var_179_22.spellLevel = iter_179_1.level or 0

			var_179_22.image:setImageSource(var_179_22.source)
			var_179_22.image:setImageClip(var_179_22.clip)
			var_179_22.levelLabel:setVisible(true)
			var_179_22.levelLabel:setText(string.format("Level: %d", iter_179_1.level))
			var_179_22.image.gray:setVisible(not var_179_15 and var_179_9 < iter_179_1.level)

			local var_179_24 = Spells.getPrimaryGroupId(iter_179_1) or -1

			if var_179_24 ~= -1 then
				local var_179_25 = var_179_24 == 2 and 20 or var_179_24 == 3 and 40 or 0

				var_179_22.imageGroup:setImageClip(var_179_25 .. " 0 20 20")
				var_179_22.imageGroup:setVisible(true)
			end
		end
	end

	local var_179_26 = var_179_2:getChildren()

	table.sort(var_179_26, function(arg_181_0, arg_181_1)
		return arg_181_0:getText() < arg_181_1:getText()
	end)

	for iter_179_2, iter_179_3 in ipairs(var_179_26) do
		var_179_2:moveChildToIndex(iter_179_3, iter_179_2)
	end

	function var_179_0.onSelectionChange(arg_182_0, arg_182_1)
		if arg_182_1 then
			var_179_3:setText(arg_182_1:getText())
			var_179_4:setImageSource(arg_182_1.source)
			var_179_4:setImageClip(arg_182_1.clip)
			var_179_5:setOn(arg_182_1.param)
			var_179_6:setEnabled(arg_182_1.param)
			var_179_6:clearText()
			var_179_2:ensureChildVisible(arg_182_1)
		end
	end

	if #var_179_26 > 0 then
		var_179_0:selectWidget(var_179_26[1])
	end

	local function var_179_27()
		local var_183_0 = var_179_1.searchText:getText():lower()
		local var_183_1 = var_179_1.filterPanel.filterLearntSpells:isChecked()

		for iter_183_0, iter_183_1 in pairs(var_179_2:getChildren()) do
			local var_183_2 = iter_183_1:getText():lower():find(var_183_0) or var_183_0 == "" or #var_183_0 < 3
			local var_183_3 = not var_183_1 or var_0_99(var_0_0, tonumber(iter_183_1:getId()))

			iter_183_1:setVisible(var_183_2 and var_183_3)
		end
	end

	function var_179_1.searchText.onTextChange(arg_184_0)
		var_179_27()
	end

	function var_179_1.filterPanel.filterLearntSpells.onCheckChange(arg_185_0, arg_185_1)
		var_179_27()
	end

	function var_179_1.buttonClearSearchText.onClick()
		var_179_1.searchText:clearText()
	end

	local function var_179_28(arg_187_0)
		local var_187_0 = var_179_0:getSelectedWidget()

		if not var_187_0 then
			return
		end

		local var_187_1 = tonumber(var_187_0:getId())
		local var_187_2 = var_187_0.spellName or var_187_0:getText():match("^(.-)\n") or "Unknown"
		local var_187_3 = var_187_0.words or var_187_0:getText():match("\n(.+)") or ""
		local var_187_4 = tonumber(arg_179_0:getId():match("%d+"))

		if arg_179_0:getId():find("attackSpellButton") then
			var_179_7.spells[var_187_4 + 1].id = var_187_1
		else
			arg_179_3[var_187_4 + 1].id = var_187_1
		end

		arg_179_0:setImageSource(var_187_0.source)
		arg_179_0:setImageClip(var_187_0.clip)
		arg_179_0:setBorderColorTop("#1b1b1b")
		arg_179_0:setBorderColorLeft("#1b1b1b")
		arg_179_0:setBorderColorRight("#757575")
		arg_179_0:setBorderColorBottom("#757575")
		arg_179_0:setBorderWidth(1)
		arg_179_0:setTooltip("Spell: " .. var_187_2 .. "\nWords: " .. var_187_3)

		if arg_179_0:getId():find("attackSpellButton") then
			local var_187_5 = Spells.getSpellDataById(tonumber(var_187_1))

			if var_187_5 then
				local var_187_6 = shooterPanel:recursiveGetChildById("countMinCreature" .. var_187_4)
				local var_187_7 = shooterPanel:recursiveGetChildById("conditionSetting" .. var_187_4)
				local var_187_8 = shooterPanel:recursiveGetChildById("selfCast" .. var_187_4)

				if table.contains(var_0_97, var_187_5.id) and not var_187_8 then
					var_187_8 = g_ui.createWidget("Button", arg_179_0)

					var_187_8:mergeStyle({
						width = 12,
						height = 12,
						font = "Verdana Bold-9px-small",
						["anchors.right"] = "parent.right",
						["anchors.bottom"] = "parent.bottom"
					})
					var_187_8:setId("selfCast" .. var_187_4)
					var_187_8:setTooltip("Cast on yourself")
					var_187_8:setVisible(true)
					updateSelfCastModeWidget(var_187_8)

					function var_187_8.onClick()
						toggleSelfCast(var_187_4, not var_179_7.spells[var_187_4 + 1].selfCast)
					end
				end

				if var_187_8 and not table.contains(var_0_97, var_187_5.id) then
					var_179_7.spells[var_187_4 + 1].selfCast = false

					var_187_8:destroy()
				end

				if not var_187_5.area and not table.contains(var_0_97, var_187_5.id) then
					var_179_7.spells[var_187_4 + 1].creatures = 1

					var_187_6:setCurrentOption("1+")
					var_187_6:disable()

					if var_187_7 then
						var_187_7:setVisible(true)
					end
				else
					var_187_6:enable()

					if isAoeSpellSlot(var_187_4) and var_179_7.spells[var_187_4 + 1].creatures < 2 then
						var_179_7.spells[var_187_4 + 1].creatures = 2

						var_187_6:setCurrentOption("2+")
					end

					if var_187_7 then
						var_187_7:setVisible(false)

						var_179_7.spells[var_187_4 + 1].forceCast = false
					end
				end

				if var_187_5.spender then
					var_179_7.spells[var_187_4 + 1].harmony = 5
				end

				ensureAimCheckbox(var_187_4, var_187_5)
				ensureHarmonyIcons(var_187_4, var_187_5)
			end
		end

		if arg_187_0 then
			var_0_5:show(true)
			var_179_1:destroy()
		end
	end

	local function var_179_29()
		var_0_5:show(true)
		var_179_1:destroy()
	end

	function var_179_1.spellFooter.buttonOk.onClick()
		var_179_28(true)
	end

	function var_179_1.spellFooter.buttonApply.onClick()
		var_179_28(false)
	end

	var_179_1.spellFooter.buttonClose.onClick = var_179_29

	function var_179_1.onEnter()
		var_179_28(true)
	end

	var_179_1.onEscape = var_179_29
end

combatStanceSpellIds = {
	[133] = true,
	[132] = true
}

function assignCombatStance(arg_193_0)
	local var_193_0 = getShooterProfile()

	assignSpell(arg_193_0, "Combat Stance", {
		3
	}, {
		var_193_0.combatStance
	}, combatStanceSpellIds)
end

function assignRune(arg_194_0, arg_194_1, arg_194_2, arg_194_3)
	g_mouse.updateGrabber(var_0_4, "target")
	var_0_4:grabMouse()
	var_0_5:hide()
	g_mouse.pushCursor("target")

	function var_0_4.onMouseRelease(arg_195_0, arg_195_1, arg_195_2)
		onAssignRune(arg_195_0, arg_195_1, arg_195_2, arg_194_0)
	end
end

function onAssignRune(arg_196_0, arg_196_1, arg_196_2, arg_196_3)
	g_mouse.updateGrabber(var_0_4, "target")
	var_0_4:ungrabMouse()
	var_0_5:show()
	g_mouse.popCursor("target")

	var_0_4.onMouseRelease = nil

	local var_196_0 = g_ui.getRootWidget()

	if not var_196_0 then
		return true
	end

	local var_196_1 = var_196_0:recursiveGetChildByPos(arg_196_1, false)

	if not var_196_1 then
		return true
	end

	local var_196_2 = 0

	if var_196_1:getClassName() == "UIItem" and not var_196_1:isVirtual() then
		local var_196_3 = var_196_1:getItem()

		if var_196_3 then
			var_196_2 = var_196_3:getId()
		end
	elseif var_196_1:getClassName() == "UIGameMap" then
		local var_196_4 = var_196_1:getTile(arg_196_1)

		if var_196_4 then
			local var_196_5 = var_196_4:getTopUseThing()

			if var_196_5 then
				var_196_2 = var_196_5:getId()
			end
		end
	end

	local var_196_6 = Spells.getRuneSpellByItem(var_196_2)

	if var_196_6 and var_196_6.group == 1 then
		if var_196_6.vocations and not table.contains(var_196_6.vocations, getPlayerVocation()) then
			modules.game_textmessage.displayFailureMessage(tr("Your vocation can not use this rune."))

			return true
		end

		local var_196_7 = tonumber(arg_196_3:getId():match("%d+"))

		if isAoeRuneSlot(var_196_7) and not var_196_6.area then
			modules.game_textmessage.displayFailureMessage(tr("This slot only accepts area runes."))

			return true
		elseif not isAoeRuneSlot(var_196_7) and var_196_6.area then
			modules.game_textmessage.displayFailureMessage(tr("This slot only accepts single-target runes."))

			return true
		end

		updateRuneButton(arg_196_3, var_196_2, var_196_6)
	else
		modules.game_textmessage.displayFailureMessage(tr("Invalid rune!"))
	end
end

function updateRuneButton(arg_197_0, arg_197_1, arg_197_2)
	arg_197_0:setImageSource("/images/ui/item")

	if not arg_197_0:getChildById("runeItem") then
		g_ui.createWidget("RuneItem", arg_197_0):setId("runeItem")
	end

	arg_197_0:getChildById("runeItem"):setItemId(arg_197_1)
	arg_197_0:setTooltip(string.format(arg_197_2.name .. " %s", arg_197_2.area and "(Area Target)" or "(Single Target)"))

	local var_197_0 = getShooterProfile()
	local var_197_1 = arg_197_0:getId()
	local var_197_2 = tonumber(var_197_1:match("%d+"))
	local var_197_3 = runePanel:recursiveGetChildById("countMinCreature" .. var_197_2)
	local var_197_4 = runePanel:recursiveGetChildById("conditionSetting" .. var_197_2)

	var_197_0.runes[var_197_2 + 1].id = arg_197_1
	var_197_0.runes[var_197_2 + 1].creatures = var_197_0.runes[var_197_2 + 1].creatures

	local var_197_5 = Spells.getRuneSpellByItem(arg_197_1)

	if var_197_5 and not var_197_5.area then
		var_197_3:setCurrentOption("1+")
		var_197_3:disable()
		var_197_4:setChecked(var_197_0.runes[var_197_2 + 1].forceCast)
		var_197_4:setVisible(true)

		var_197_0.runes[var_197_2 + 1].creatures = 1

		return
	end

	var_197_0.runes[var_197_2 + 1].forceCast = false

	var_197_4:setChecked(false)
	var_197_4:setVisible(false)
	var_197_3:enable()

	if isAoeRuneSlot(var_197_2) and var_197_0.runes[var_197_2 + 1].creatures < 2 then
		var_197_0.runes[var_197_2 + 1].creatures = 2

		var_197_3:setCurrentOption("2+")
	end
end

function getPotionInfoById(arg_198_0)
	for iter_198_0, iter_198_1 in pairs(var_0_103) do
		if arg_198_0 == iter_198_1.id then
			return true, iter_198_1.name
		end
	end

	return false, "Unknown Potion"
end

function isHealthPotion(arg_199_0)
	for iter_199_0, iter_199_1 in ipairs(var_0_103) do
		if iter_199_1.id == arg_199_0 and iter_199_1.type == "health" then
			return true
		end
	end

	return false
end

function isManaPotion(arg_200_0)
	for iter_200_0, iter_200_1 in ipairs(var_0_103) do
		if iter_200_1.id == arg_200_0 and iter_200_1.type == "mana" then
			return true
		end
	end

	return false
end

function usePotion(arg_201_0)
	local var_201_0 = g_game.getLocalPlayer()

	if not var_201_0 then
		return false
	end

	if var_0_41(var_0_25.id) > g_clock.millis() then
		return false
	end

	if var_0_12 > g_clock.millis() then
		return false
	end

	helperConfig.magicShooterOnHold = true

	local var_201_1 = false

	if var_201_0:getInventoryCount(arg_201_0) > 0 then
		g_game.useInventoryItemWith(arg_201_0, var_201_0, 0, true)

		var_0_40[var_0_25.id] = g_clock.millis() + var_0_25.exhaustion
		var_201_1 = true
	end

	helperConfig.magicShooterOnHold = false

	return var_201_1
end

function assignPotionEvent(arg_202_0)
	g_mouse.updateGrabber(var_0_4, "target")
	var_0_4:grabMouse()
	var_0_5:hide()
	g_mouse.pushCursor("target")

	function var_0_4.onMouseRelease(arg_203_0, arg_203_1, arg_203_2)
		onAssignPotion(arg_203_0, arg_203_1, arg_203_2, arg_202_0)
	end
end

function onAssignPotion(arg_204_0, arg_204_1, arg_204_2, arg_204_3)
	g_mouse.updateGrabber(var_0_4, "target")
	var_0_4:ungrabMouse()
	var_0_5:show()
	g_mouse.popCursor("target")

	var_0_4.onMouseRelease = nil

	local var_204_0 = g_ui.getRootWidget()

	if not var_204_0 then
		return true
	end

	local var_204_1 = var_204_0:recursiveGetChildByPos(arg_204_1, false)

	if not var_204_1 then
		return true
	end

	local var_204_2 = 0

	if var_204_1:getClassName() == "UIItem" and not var_204_1:isVirtual() then
		local var_204_3 = var_204_1:getItem()

		if var_204_3 then
			var_204_2 = var_204_3:getId()
		end
	elseif var_204_1:getClassName() == "UIGameMap" then
		local var_204_4 = var_204_1:getTile(arg_204_1)

		if var_204_4 then
			local var_204_5 = var_204_4:getTopUseThing()

			if var_204_5 then
				var_204_2 = var_204_5:getId()
			end
		end
	end

	local var_204_6, var_204_7 = getPotionInfoById(var_204_2)

	if var_204_6 then
		updatePotionButton(arg_204_3, var_204_2, var_204_7)
	else
		modules.game_textmessage.displayFailureMessage(tr("Invalid potion!"))
	end
end

function updatePotionButton(arg_205_0, arg_205_1, arg_205_2)
	invalidateHelperCache()
	arg_205_0:setImageSource("/images/ui/item")

	if not arg_205_0:getChildById("potionItem") then
		g_ui.createWidget("PotionItem", arg_205_0):setId("potionItem")
	end

	local var_205_0 = arg_205_0:getChildById("potionItem")

	var_205_0:setItemId(arg_205_1)
	var_205_0:setTooltip(arg_205_2)

	local var_205_1 = arg_205_0:getId()
	local var_205_2 = tonumber(var_205_1:match("%d+"))

	helperConfig.potions[var_205_2 + 1].id = arg_205_1
	helperConfig.potions[var_205_2 + 1].percent = helperConfig.potions[var_205_2 + 1].percent

	if arg_205_1 == 7642 or arg_205_1 == 23374 then
		helperConfig.potions[var_205_2 + 1].priority = 1

		local var_205_3 = var_0_1:recursiveGetChildById("priority" .. var_205_2)

		var_205_3:setImageSource("/images/skin/show-gui-help-red")
		var_205_3:setTooltip("This potion is healing health...")

		var_205_3.actionId = 1
	end
end

function updateButton(arg_206_0)
	local var_206_0 = getShooterProfile()
	local var_206_1 = tonumber(arg_206_0:getId():match("%d+")) or 0

	function arg_206_0.onMousePress(arg_207_0, arg_207_1, arg_207_2)
		if arg_207_2 == MouseRightButton then
			local var_207_0 = g_ui.createWidget("PopupMenu")

			var_207_0:setGameMenu(true)

			local var_207_1 = arg_206_0:getId()

			if var_207_1:find("runeShooterButton") then
				if var_206_0.runes[var_206_1 + 1].id > 0 then
					var_207_0:addOption(tr("Edit Rune"), function()
						assignRune(arg_206_0)
					end)
					var_207_0:addOption(tr("Remove"), function()
						removeAction("rune", arg_206_0)
					end)
				else
					var_207_0:addOption(tr("Assign Rune"), function()
						assignRune(arg_206_0)
					end)
				end
			elseif var_207_1:find("attackSpellButton") then
				if var_206_0.spells[var_206_1 + 1].id > 0 then
					var_207_0:addOption(tr("Edit Spell"), function()
						assignSpell(arg_206_0, "Aggressive", {
							1,
							4,
							8
						}, var_206_0.spells)
					end)
					var_207_0:addOption(tr("Remove"), function()
						removeAction("shooter", arg_206_0)
					end)
				else
					var_207_0:addOption(tr("Assign Spell"), function()
						assignSpell(arg_206_0, "Aggressive", {
							1,
							4,
							8
						}, var_206_0.spells)
					end)
				end
			elseif var_207_1:find("combatStanceButton") then
				if var_206_0.combatStance.id > 0 then
					var_207_0:addOption(tr("Edit Spell"), function()
						assignCombatStance(arg_206_0)
					end)
					var_207_0:addOption(tr("Remove"), function()
						removeAction("combatstance", arg_206_0)
					end)
				else
					var_207_0:addOption(tr("Assign Spell"), function()
						assignCombatStance(arg_206_0)
					end)
				end
			elseif var_207_1:find("spellButton") then
				if helperConfig.spells[var_206_1 + 1].id > 0 then
					var_207_0:addOption(tr("Edit Spell"), function()
						assignSpell(arg_206_0, "Healing", {
							2
						}, helperConfig.spells)
					end)
					var_207_0:addOption(tr("Remove"), function()
						removeAction("spell", arg_206_0)
					end)
				else
					var_207_0:addOption(tr("Assign Spell"), function()
						assignSpell(arg_206_0, "Healing", {
							2
						}, helperConfig.spells)
					end)
				end
			elseif var_207_1:find("potionButton") then
				if helperConfig.potions[var_206_1 + 1].id > 0 then
					var_207_0:addOption(tr("Edit Potion"), function()
						assignPotionEvent(arg_206_0)
					end)
					var_207_0:addOption(tr("Remove"), function()
						removeAction("potion", arg_206_0)
					end)
				else
					var_207_0:addOption(tr("Assign Potion"), function()
						assignPotionEvent(arg_206_0)
					end)
				end
			elseif var_207_1:find("spellTrainingButton") then
				local trainingSlot = helperConfig.training[var_206_1 + 1] or { id = 0 }

				if (tonumber(trainingSlot.id) or 0) > 0 then
					var_207_0:addOption(tr("Edit Training Spell"), function()
						assignTrainingSpell(arg_206_0)
					end)
					var_207_0:addOption(tr("Remove"), function()
						removeAction("training", arg_206_0)
					end)
				else
					var_207_0:addOption(tr("Assign Training Spell"), function()
						assignTrainingSpell(arg_206_0)
					end)
				end
			elseif var_207_1:find("hasteButton") then
				local hasteSlot = helperConfig.haste[var_206_1 + 1] or { id = 0 }

				if (tonumber(hasteSlot.id) or 0) > 0 then
					var_207_0:addOption(tr("Edit Haste Spell"), function()
						assignTrainingSpell(arg_206_0, true)
					end)
					var_207_0:addOption(tr("Remove"), function()
						removeAction("haste", arg_206_0)
					end)
				else
					var_207_0:addOption(tr("Assign Haste Spell"), function()
						assignTrainingSpell(arg_206_0, true)
					end)
				end
			elseif var_207_1:find("autoTrainingItem") then
				if var_0_91().id <= 0 then
					var_207_0:addOption(tr("Select exercise weapon"), function()
						assignExerciseEvent(arg_206_0)
					end)
				else
					var_207_0:addOption(tr("Remove"), function()
						removeAction("exercise", arg_206_0)
						saveSettings()
					end)
				end
			elseif var_207_1:find("autoFoodItem") then
				if var_0_93().id <= 0 then
					var_207_0:addOption(tr("Select food"), function()
						assignFoodEvent(arg_206_0)
					end)
				else
					var_207_0:addOption(tr("Remove"), function()
						removeAction("food", arg_206_0)
						saveSettings()
					end)
				end
			end

			var_207_0:display(arg_207_1)

			return true
		end

		return false
	end
end

function updatePartyFriendList()
	if not var_0_8 or not var_0_9 then
		return
	end

	local var_233_0 = g_game.getLocalPlayer()

	if not var_233_0 or not var_233_0:isPartyMember() then
		resetPartyPanel()

		return
	end

	local var_233_1 = var_233_0:getPosition()
	local var_233_2 = g_map.getSpectators(var_233_1, false)
	local var_233_3 = {}

	for iter_233_0, iter_233_1 in ipairs(var_233_2) do
		if iter_233_1:isPlayer() and iter_233_1:isPartyMember() and not iter_233_1:isLocalPlayer() then
			table.insert(var_233_3, iter_233_1)
		end
	end

	local var_233_4 = {}

	for iter_233_2, iter_233_3 in ipairs(var_0_8:getChildren()) do
		var_233_4[iter_233_3:getText()] = true
	end

	local var_233_5 = false

	if var_0_8:getChildCount() ~= #var_233_3 then
		var_233_5 = true
	else
		for iter_233_4, iter_233_5 in ipairs(var_233_3) do
			if not var_233_4[iter_233_5:getName()] then
				var_233_5 = true

				break
			end
		end
	end

	if not var_233_5 then
		return
	end

	var_0_8:destroyChildren()
	var_0_9:destroyChildren()
	resetPartyPanel()

	for iter_233_6, iter_233_7 in ipairs(var_233_3) do
		local var_233_6 = g_ui.createWidget("PlayerName", var_0_8)
		local var_233_7 = g_ui.createWidget("PlayerName", var_0_9)

		var_233_6:setText(iter_233_7:getName())
		var_233_7:setText(iter_233_7:getName())

		var_233_6.creature = iter_233_7
		var_233_7.creature = iter_233_7
	end

	restoreSavedFriendHealing()
end

function restoreSavedFriendHealing()
	local var_234_0 = var_0_1:recursiveGetChildById("friendHealingPanel")
	local var_234_1 = var_0_1:recursiveGetChildById("granSioPanel")
	local var_234_2 = var_0_1:recursiveGetChildById("secondPanel")
	local var_234_3 = var_0_1:recursiveGetChildById("secondPanel2")

	for iter_234_0 = 0, 1 do
		local var_234_4 = helperConfig.friendhealing[iter_234_0 + 1]

		if var_234_4.name ~= "" then
			for iter_234_1, iter_234_2 in ipairs(var_0_8:getChildren()) do
				if iter_234_2:getText() == var_234_4.name and iter_234_2.creature then
					local var_234_5 = var_234_0:recursiveGetChildById("friendButton" .. iter_234_0)

					var_234_5:setCreature(iter_234_2.creature)
					var_234_5:setImageSource("/images/store/button-erase-small-up")
					manageSioSettings(true, iter_234_0)

					local var_234_6 = var_234_2:recursiveGetChildById("healPercent" .. iter_234_0)

					if var_234_6 and var_234_4.percent > 0 then
						var_234_6:setCurrentOption(tostring(var_234_4.percent) .. "%")
					end

					local var_234_7 = var_234_0:recursiveGetChildById("enableSio" .. iter_234_0)

					if var_234_7 then
						var_234_7:setChecked(var_234_4.enabled)
					end

					break
				end
			end
		end
	end

	for iter_234_3 = 0, 1 do
		local var_234_8 = helperConfig.gransiohealing[iter_234_3 + 1]

		if var_234_8.name ~= "" then
			for iter_234_4, iter_234_5 in ipairs(var_0_9:getChildren()) do
				if iter_234_5:getText() == var_234_8.name and iter_234_5.creature then
					local var_234_9 = var_234_1:recursiveGetChildById("friendButton" .. iter_234_3)

					var_234_9:setCreature(iter_234_5.creature)
					var_234_9:setImageSource("/images/store/button-erase-small-up")
					manageGranSioSettings(true, iter_234_3)

					local var_234_10 = var_234_3:recursiveGetChildById("healPercent" .. iter_234_3)

					if var_234_10 and var_234_8.percent > 0 then
						var_234_10:setCurrentOption(tostring(var_234_8.percent) .. "%")
					end

					local var_234_11 = var_234_1:recursiveGetChildById("enableSio" .. iter_234_3)

					if var_234_11 then
						var_234_11:setChecked(var_234_8.enabled)
					end

					break
				end
			end
		end
	end
end

function resetPartyPanel()
	local var_235_0 = var_0_1:recursiveGetChildById("friendHealingPanel")
	local var_235_1 = var_0_1:recursiveGetChildById("granSioPanel")
	local var_235_2 = g_game.getLocalPlayer()

	if not var_235_2 or not var_235_2:isPartyMember() then
		var_0_8:destroyChildren()
		var_0_9:destroyChildren()

		for iter_235_0 = 0, 1 do
			var_235_0:recursiveGetChildById("healPercent" .. iter_235_0):setEnabled(false)
			var_235_1:recursiveGetChildById("healPercent" .. iter_235_0):setEnabled(false)
			var_235_0:recursiveGetChildById("enableSio" .. iter_235_0):setEnabled(false)
			var_235_1:recursiveGetChildById("enableSio" .. iter_235_0):setChecked(false)
			var_235_0:recursiveGetChildById("friendButton" .. iter_235_0):setCreature(nil)
			var_235_1:recursiveGetChildById("friendButton" .. iter_235_0):setCreature(nil)
			var_235_0:recursiveGetChildById("friendButton" .. iter_235_0):setImageSource("/images/store/bazaar-add-item")
			var_235_1:recursiveGetChildById("friendButton" .. iter_235_0):setImageSource("/images/store/bazaar-add-item")
		end

		return
	end

	if not var_235_0:recursiveGetChildById("healPercent0"):isEnabled() then
		for iter_235_1 = 0, 1 do
			var_235_0:recursiveGetChildById("healPercent" .. iter_235_1):setEnabled(true)
			var_235_0:recursiveGetChildById("enableSio" .. iter_235_1):setEnabled(true)
			var_235_0:recursiveGetChildById("friendButton" .. iter_235_1):setEnabled(true)
		end
	end

	if not var_235_1:recursiveGetChildById("healPercent0"):isEnabled() then
		for iter_235_2 = 0, 1 do
			var_235_1:recursiveGetChildById("healPercent" .. iter_235_2):setEnabled(true)
			var_235_1:recursiveGetChildById("enableSio" .. iter_235_2):setEnabled(true)
			var_235_1:recursiveGetChildById("friendButton" .. iter_235_2):setEnabled(true)
		end
	end
end

function onAddPartyMember(arg_236_0)
	local var_236_0 = tonumber(arg_236_0:getId():match("%d+"))
	local var_236_1 = var_0_1:recursiveGetChildById("secondPanel")
	local var_236_2 = var_0_8:getFocusedChild()

	if not var_236_2 then
		return true
	end

	local var_236_3 = var_0_1:recursiveGetChildById("friendHealingPanel")
	local var_236_4 = var_236_3:recursiveGetChildById("enableSio" .. var_236_0) and var_236_3:recursiveGetChildById("enableSio" .. var_236_0):isChecked()
	local var_236_5 = var_236_1:recursiveGetChildById("healPercent" .. var_236_0):getCurrentOption().text

	if arg_236_0:getImageSource() == "/images/store/button-erase-small-up" then
		helperConfig.friendhealing[var_236_0 + 1].name = ""
		helperConfig.friendhealing[var_236_0 + 1].percent = 0
		helperConfig.friendhealing[var_236_0 + 1].enabled = false

		arg_236_0:setCreature(nil)
		arg_236_0:setImageSource("/images/store/bazaar-add-item")
		manageSioSettings(false, var_236_0)
	else
		if var_236_2:getText() == helperConfig.friendhealing[1].name or var_236_2:getText() == helperConfig.friendhealing[2].name then
			return true
		end

		helperConfig.friendhealing[var_236_0 + 1].name = var_236_2:getText()
		helperConfig.friendhealing[var_236_0 + 1].percent = tonumber(var_236_5:match("%d+"))
		helperConfig.friendhealing[var_236_0 + 1].enabled = var_236_4

		arg_236_0:setCreature(var_236_2.creature)
		arg_236_0:setImageSource("/images/store/button-erase-small-up")
		manageSioSettings(true, var_236_0)
	end
end

function onAddPartyGranSioMember(arg_237_0)
	local var_237_0 = tonumber(arg_237_0:getId():match("%d+"))
	local var_237_1 = var_0_1:recursiveGetChildById("secondPanel2")
	local var_237_2 = var_0_9:getFocusedChild()

	if not var_237_2 then
		return true
	end

	local var_237_3 = var_0_1:recursiveGetChildById("granSioPanel")
	local var_237_4 = var_237_3:recursiveGetChildById("enableSio" .. var_237_0) and var_237_3:recursiveGetChildById("enableSio" .. var_237_0):isChecked()
	local var_237_5 = var_237_1:recursiveGetChildById("healPercent" .. var_237_0):getCurrentOption().text

	if arg_237_0:getImageSource() == "/images/store/button-erase-small-up" then
		helperConfig.gransiohealing[var_237_0 + 1].name = ""
		helperConfig.gransiohealing[var_237_0 + 1].percent = 0
		helperConfig.gransiohealing[var_237_0 + 1].enabled = false

		arg_237_0:setCreature(nil)
		arg_237_0:setImageSource("/images/store/bazaar-add-item")
		manageGranSioSettings(false, var_237_0)
	else
		if var_237_2:getText() == helperConfig.gransiohealing[1].name or var_237_2:getText() == helperConfig.gransiohealing[2].name then
			return true
		end

		helperConfig.gransiohealing[var_237_0 + 1].name = var_237_2:getText()
		helperConfig.gransiohealing[var_237_0 + 1].percent = tonumber(var_237_5:match("%d+"))
		helperConfig.gransiohealing[var_237_0 + 1].enabled = var_237_4

		arg_237_0:setCreature(var_237_2.creature)
		arg_237_0:setImageSource("/images/store/button-erase-small-up")
		manageGranSioSettings(true, var_237_0)
	end
end

function manageSioSettings(arg_238_0, arg_238_1)
	local var_238_0 = var_0_1:recursiveGetChildById("friendHealingPanel")

	var_238_0:recursiveGetChildById("healPercent" .. arg_238_1):setEnabled(arg_238_0)
	var_238_0:recursiveGetChildById("enableSio" .. arg_238_1):setEnabled(arg_238_0)

	if not arg_238_0 then
		var_238_0:recursiveGetChildById("enableSio" .. arg_238_1):setChecked(false)
	end
end

function manageGranSioSettings(arg_239_0, arg_239_1)
	local var_239_0 = var_0_1:recursiveGetChildById("granSioPanel")

	var_239_0:recursiveGetChildById("healPercent" .. arg_239_1):setEnabled(arg_239_0)
	var_239_0:recursiveGetChildById("enableSio" .. arg_239_1):setEnabled(arg_239_0)

	if not arg_239_0 then
		var_239_0:recursiveGetChildById("enableSio" .. arg_239_1):setChecked(false)
	end
end

function onEnableSio(arg_240_0, arg_240_1)
	local var_240_0 = tonumber(arg_240_0:getId():match("%d+"))

	helperConfig.friendhealing[var_240_0 + 1].enabled = arg_240_1
end

function onEnableGranSio(arg_241_0, arg_241_1)
	local var_241_0 = tonumber(arg_241_0:getId():match("%d+"))

	helperConfig.gransiohealing[var_241_0 + 1].enabled = arg_241_1
end

function onEnableTraining(arg_242_0, arg_242_1)
	if helperConfig.haste[1].enabled then
		var_0_2:recursiveGetChildById("enableHaste0"):setChecked(false)
	end

	local var_242_0 = tonumber(arg_242_0:match("%d+"))

	helperConfig.training[var_242_0 + 1].enabled = arg_242_1
end

function updateHealingPercent(arg_243_0, arg_243_1)
	local var_243_0 = string.match(arg_243_0, "%d+")

	if not var_243_0 then
		return
	end

	local var_243_1 = tonumber(var_243_0)
	local var_243_2 = helperConfig.spells[var_243_1 + 1]

	if string.find(arg_243_0, "add") then
		if var_243_2.percent + 1 > 99 then
			var_0_1:recursiveGetChildById("addPercentButton" .. var_243_1):setEnabled(false)

			return
		end

		var_0_1:recursiveGetChildById("rmvPercentButton" .. var_243_1):setEnabled(true)

		var_243_2.percent = var_243_2.percent + 1

		var_0_1:recursiveGetChildById("spellPercentLabel" .. var_243_1):setText(var_243_2.percent .. "%")
	elseif string.find(arg_243_0, "rmv") then
		if var_243_2.percent - 1 < 1 then
			var_0_1:recursiveGetChildById("rmvPercentButton" .. var_243_1):setEnabled(false)

			return
		end

		var_0_1:recursiveGetChildById("addPercentButton" .. var_243_1):setEnabled(true)

		var_243_2.percent = var_243_2.percent - 1

		var_0_1:recursiveGetChildById("spellPercentLabel" .. var_243_1):setText(var_243_2.percent .. "%")
	end

	invalidateHelperCache()

	cachedSpells = table.copy(helperConfig.spells)

	table.sort(cachedSpells, function(arg_244_0, arg_244_1)
		return arg_244_0.percent < arg_244_1.percent
	end)
end

function updateMagicShooterPercent(arg_245_0, arg_245_1)
	local var_245_0 = string.match(arg_245_0, "%d+")

	if not var_245_0 then
		return
	end

	local var_245_1 = getShooterProfile()
	local var_245_2 = tonumber(var_245_0)
	local var_245_3 = var_245_1.spells[var_245_2 + 1]
	local var_245_4 = shooterPanel:recursiveGetChildById("spellPercentLabel" .. var_245_2)

	if string.find(arg_245_0, "add") then
		if var_245_3.percent >= 99 then
			shooterPanel:recursiveGetChildById("addPercentButton" .. var_245_2):setEnabled(false)

			return
		end

		var_245_3.percent = var_245_3.percent + 1

		var_245_4:setText(var_245_3.percent .. "%")

		if var_245_3.percent >= 99 then
			shooterPanel:recursiveGetChildById("addPercentButton" .. var_245_2):setEnabled(false)
		end

		shooterPanel:recursiveGetChildById("rmvPercentButton" .. var_245_2):setEnabled(true)
	elseif string.find(arg_245_0, "rmv") then
		if var_245_3.percent <= 1 then
			shooterPanel:recursiveGetChildById("rmvPercentButton" .. var_245_2):setEnabled(false)

			return
		end

		var_245_3.percent = var_245_3.percent - 1

		var_245_4:setText(var_245_3.percent .. "%")

		if var_245_3.percent <= 1 then
			shooterPanel:recursiveGetChildById("rmvPercentButton" .. var_245_2):setEnabled(false)
		end

		shooterPanel:recursiveGetChildById("addPercentButton" .. var_245_2):setEnabled(true)
	end
end

function updateRuneShooterCreatures(arg_246_0, arg_246_1, arg_246_2)
	local var_246_0 = getShooterProfile()
	local var_246_1 = tonumber(arg_246_2) or 1

	var_246_0.runes[arg_246_1 + 1].creatures = var_246_1
end

function updateRuneShooterPriority(arg_247_0, arg_247_1)
	getShooterProfile().runes[arg_247_0 + 1].priority = tonumber(arg_247_1)
end

function updateCycleRuneInterval(arg_248_0)
	local var_248_0 = getShooterProfile()
	local var_248_1 = tonumber(arg_248_0) or 4

	var_248_0.runes[1].interval = var_248_1 * 1000
end

function toggleCycleRuneDuringCycle(arg_249_0)
	getShooterProfile().runes[1].useDuringCycle = arg_249_0 and true or false
end

function updateCombatStanceCooldown(arg_250_0)
	local var_250_0 = getShooterProfile()
	local var_250_1 = tonumber(arg_250_0) or 30

	var_250_0.combatStance.cooldown = var_250_1 * 1000
end

function updateCombatStancePercent(arg_251_0)
	local var_251_0 = getShooterProfile().combatStance
	local var_251_1 = shooterPanel:recursiveGetChildById("combatStancePercentLabel")
	local var_251_2 = shooterPanel:recursiveGetChildById("combatStanceRmvPercent")
	local var_251_3 = shooterPanel:recursiveGetChildById("combatStanceAddPercent")

	if string.find(arg_251_0, "Add") then
		if var_251_0.percent >= 99 then
			var_251_3:setEnabled(false)

			return
		end

		var_251_0.percent = var_251_0.percent + 1

		if var_251_0.percent >= 99 then
			var_251_3:setEnabled(false)
		end

		var_251_2:setEnabled(true)
	elseif string.find(arg_251_0, "Rmv") then
		if var_251_0.percent <= 0 then
			var_251_2:setEnabled(false)

			return
		end

		var_251_0.percent = var_251_0.percent - 1

		if var_251_0.percent <= 0 then
			var_251_2:setEnabled(false)
		end

		var_251_3:setEnabled(true)
	end

	var_251_1:setText(var_251_0.percent .. "%")
end

function updatePotionPercent(arg_252_0, arg_252_1)
	invalidateHelperCache()

	local var_252_0 = string.match(arg_252_0, "%d+")

	if not var_252_0 then
		return
	end

	local var_252_1 = tonumber(var_252_0)
	local var_252_2 = helperConfig.potions[var_252_1 + 1]

	if string.find(arg_252_0, "add") then
		if var_252_2.percent + 1 > 99 then
			var_0_1:recursiveGetChildById("addPotionPercentButton" .. var_252_1):setEnabled(false)

			return
		end

		var_0_1:recursiveGetChildById("rmvPotionPercentButton" .. var_252_1):setEnabled(true)

		var_252_2.percent = var_252_2.percent + 1

		var_0_1:recursiveGetChildById("potionPercentLabel" .. var_252_1):setText(var_252_2.percent .. "%")
	elseif string.find(arg_252_0, "rmv") then
		if var_252_2.percent - 1 < 1 then
			var_0_1:recursiveGetChildById("rmvPotionPercentButton" .. var_252_1):setEnabled(false)

			return
		end

		var_0_1:recursiveGetChildById("addPotionPercentButton" .. var_252_1):setEnabled(true)

		var_252_2.percent = var_252_2.percent - 1

		var_0_1:recursiveGetChildById("potionPercentLabel" .. var_252_1):setText(var_252_2.percent .. "%")
	end
end

function updateFriendHealingPercent(arg_253_0, arg_253_1)
	helperConfig.friendhealing[arg_253_0 + 1].percent = tonumber(arg_253_1)
end

function updateGranSioPercent(arg_254_0, arg_254_1)
	helperConfig.gransiohealing[arg_254_0 + 1].percent = tonumber(arg_254_1)
end

function castHealingSpell(arg_255_0)
	local var_255_0 = Spells.getSpellDataById(tonumber(arg_255_0))

	if not var_255_0 or var_255_0.id == 0 then
		return false
	end

	if isSpellOnCooldown(var_255_0) then
		return false
	end

	if var_0_0:getMana() < var_255_0.mana then
		return false
	end

	if var_255_0.soul > 0 then
		if var_0_0:getSoul() < var_255_0.soul then
			return false
		end

		if var_255_0.source and var_255_0.source > 0 and not hasItemInBackpack(var_255_0.source) then
			return false
		end
	end

	g_game.talk(var_255_0.words)
	onSpellCooldown(var_255_0.id, 500)

	for iter_255_0, iter_255_1 in pairs(var_255_0.group) do
		onSpellGroupCooldown(iter_255_0, 500)
	end

	return true
end

function checkHealthHealing()
	if not var_0_10 then
		return false
	end

	local var_256_0 = var_0_0:getHealth()
	local var_256_1 = var_0_0:getMaxHealth()

	if var_256_1 <= 0 then
		return false
	end

	local var_256_2 = var_256_0 / var_256_1 * 100

	if not var_0_71 then
		var_0_71 = {}

		for iter_256_0, iter_256_1 in pairs(helperConfig.spells) do
			if iter_256_1.id and iter_256_1.id > 0 and not var_0_98[iter_256_1.id] then
				table.insert(var_0_71, {
					kind = "spell",
					id = iter_256_1.id,
					percent = iter_256_1.percent
				})
			end
		end

		for iter_256_2, iter_256_3 in pairs(helperConfig.potions) do
			if iter_256_3.id and iter_256_3.id > 0 and iter_256_3.priority ~= 2 then
				table.insert(var_0_71, {
					kind = "potion",
					id = iter_256_3.id,
					percent = iter_256_3.percent,
					priority = iter_256_3.priority or 1
				})
			end
		end

		table.sort(var_0_71, function(arg_257_0, arg_257_1)
			if arg_257_0.percent == arg_257_1.percent then
				if arg_257_0.kind ~= arg_257_1.kind then
					return arg_257_0.kind == "spell"
				end

				return (arg_257_0.priority or 0) < (arg_257_1.priority or 0)
			end

			return arg_257_0.percent < arg_257_1.percent
		end)
	end

	local var_256_3 = false
	local var_256_4 = false
	local var_256_5 = var_0_72 and {} or nil
	local var_256_6 = getPlayerVocation()
	local var_256_7 = var_256_6 == 5 or var_256_6 == 6 or isMonkVocId(var_256_6)

	for iter_256_4, iter_256_5 in ipairs(var_0_71) do
		if iter_256_5.kind == "spell" and not var_256_3 and var_256_2 <= iter_256_5.percent then
			if castHealingSpell(iter_256_5.id) then
				var_256_3 = true

				if var_256_5 then
					table.insert(var_256_5, "spell#" .. iter_256_5.id .. ":CAST@" .. iter_256_5.percent)
				end
			elseif var_256_5 then
				table.insert(var_256_5, "spell#" .. iter_256_5.id .. ":blocked")
			end
		end
	end

	if not var_256_7 or not var_256_3 then
		for iter_256_6, iter_256_7 in ipairs(var_0_71) do
			if iter_256_7.kind == "potion" and not var_256_4 and var_256_2 <= iter_256_7.percent then
				if not hasItemInBackpack(iter_256_7.id) then
					if var_256_5 then
						table.insert(var_256_5, "potion#" .. iter_256_7.id .. ":nostock")
					end
				elseif not isHealthPotion(iter_256_7.id) then
					if var_256_5 then
						table.insert(var_256_5, "potion#" .. iter_256_7.id .. ":nothealth")
					end
				elseif usePotion(iter_256_7.id) then
					var_256_4 = true

					if var_256_5 then
						table.insert(var_256_5, "potion#" .. iter_256_7.id .. ":USE@" .. iter_256_7.percent)
					end
				elseif var_256_5 then
					table.insert(var_256_5, "potion#" .. iter_256_7.id .. ":cooldown")
				end
			end
		end
	end

	if var_256_5 and #var_256_5 > 0 then
		print(string.format("[HealDbg] HP=%.0f%% | %s", var_256_2, table.concat(var_256_5, " ")))
	end

	return var_256_3 or var_256_4
end

function healingDebug(arg_258_0)
	if arg_258_0 == nil then
		var_0_72 = not var_0_72
	else
		var_0_72 = arg_258_0 and true or false
	end

	print("[HealDbg] healing debug " .. (var_0_72 and "ENABLED" or "DISABLED"))

	return var_0_72
end

function isHealingDebugEnabled()
	return var_0_72
end

var_0_28.checkHealthHealing.action = checkHealthHealing

function hasItemInBackpack(arg_260_0)
	return var_0_0 and type(var_0_0) == "userdata" and var_0_0:getInventoryCount(arg_260_0, 0) > 0
end

function checkManaHealing(arg_261_0, arg_261_1)
	local var_261_0 = arg_261_0 / arg_261_1 * 100

	for iter_261_0, iter_261_1 in ipairs(helperConfig.potions) do
		if isManaPotion(iter_261_1.id) then
			helperConfig.potions[iter_261_0].percent = tonumber(iter_261_1.percent) or 0
		end
	end

	local var_261_1 = false
	local var_261_2 = var_0_0:getHealth() / var_0_0:getMaxHealth() * 100

	for iter_261_2, iter_261_3 in ipairs(helperConfig.potions) do
		if iter_261_3.priority ~= 2 and hasItemInBackpack(iter_261_3.id) and isHealthPotion(iter_261_3.id) and var_261_2 <= iter_261_3.percent then
			var_261_1 = true

			break
		end
	end

	if var_261_1 then
		return
	end

	if not var_0_70 then
		var_0_70 = {}

		for iter_261_4, iter_261_5 in ipairs(helperConfig.potions) do
			if isManaPotion(iter_261_5.id) or iter_261_5.priority == 2 then
				table.insert(var_0_70, iter_261_5)
			end
		end

		table.sort(var_0_70, function(arg_262_0, arg_262_1)
			return arg_262_0.percent < arg_262_1.percent
		end)
	end

	for iter_261_6, iter_261_7 in ipairs(var_0_70) do
		if hasItemInBackpack(iter_261_7.id) and var_261_0 <= iter_261_7.percent then
			usePotion(iter_261_7.id)

			return
		end
	end
end

function useAutoSio(arg_263_0)
	local var_263_0 = 84
	local var_263_1 = Spells.getSpellDataById(tonumber(var_263_0))

	if not var_263_1 or var_263_1.id == 0 then
		return false
	end

	if not checkHealthPriority() then
		return
	end

	if isSpellOnCooldown(var_263_1) then
		return false
	end

	g_game.talk(string.format("%s \"%s\"", var_263_1.words, arg_263_0:getName()), true)
end

function useAutoGranSio(arg_264_0)
	local var_264_0 = 242
	local var_264_1 = Spells.getSpellDataById(var_264_0)

	if not var_264_1 or var_264_1.id == 0 then
		return false
	end

	if not checkHealthPriority() then
		return
	end

	if isSpellOnCooldown(var_264_1) then
		return false
	end

	g_game.talk(string.format("%s \"%s\"", var_264_1.words, arg_264_0:getName()), true)
end

function useAutoTioSio(arg_265_0)
	local var_265_0 = 297
	local var_265_1 = Spells.getSpellDataById(var_265_0)

	if not var_265_1 or var_265_1.id == 0 then
		return false
	end

	if not checkHealthPriority() then
		return
	end

	if isSpellOnCooldown(var_265_1) then
		return false
	end

	g_game.talk(string.format("%s \"%s\"", var_265_1.words, arg_265_0:getName()), true)
end

function useAutoUH(arg_266_0)
	local var_266_0 = 3160

	if not Spells.getRuneSpellByItem(var_266_0) then
		return false
	end

	if not checkHealthPriority() then
		return
	end

	helperConfig.magicShooterOnHold = true

	if hasItemInBackpack(var_266_0) then
		g_game.useInventoryItemWith(var_266_0, arg_266_0, 0, true)
	end

	helperConfig.magicShooterOnHold = false
end

function updateTrainingPercent(arg_267_0, arg_267_1)
	local var_267_0 = string.match(arg_267_0, "%d+")
	local var_267_1 = tonumber(var_267_0)
	local var_267_2 = helperConfig.training[var_267_1 + 1]

	if var_267_2 and var_267_2.percent then
		var_267_2.percent = tonumber(arg_267_1)
	end
end

function checkTrainingSpell(arg_268_0, arg_268_1)
	local var_268_0 = helperConfig.training[1]

	if not var_268_0 or not var_268_0.enabled then
		return false
	end

	if arg_268_1 == 0 then
		return false
	end

	if arg_268_0 / arg_268_1 * 100 < tonumber(var_268_0.percent) then
		return false
	end

	local var_268_1 = Spells.getSpellDataById(tonumber(var_268_0.id))

	if not var_268_1 or var_268_1.id == 0 then
		return false
	end

	if var_268_1.type == "Conjure" and var_268_1.source and var_268_1.source > 0 and not hasItemInBackpack(var_268_1.source) then
		return false
	end

	if isSpellOnCooldown(var_268_1) then
		return false
	end

	local var_268_2 = g_clock.millis()

	if var_268_2 - var_0_46 < var_0_47 then
		return false
	end

	var_0_46 = var_268_2

	castHealingSpell(var_268_0.id)
end

function toggleAutoEat(arg_269_0)
	helperConfig.autoEatFood = arg_269_0
end

function toggleAutoHaste(arg_270_0)
	if helperConfig.training[1].enabled then
		var_0_2:recursiveGetChildById("enableTraining0"):setChecked(false)
	end

	helperConfig.haste[1].enabled = arg_270_0
end

function toggleAutoHastePz(arg_271_0)
	helperConfig.haste[1].safecast = arg_271_0
end

function toogleChangeGold(arg_272_0)
	helperConfig.autoChangeGold = arg_272_0
end

local var_0_141 = 61701

local function var_0_142(arg_273_0)
	if not supportPanel then
		return nil
	end

	return supportPanel:recursiveGetChildById(arg_273_0)
end

local function var_0_143()
	if var_0_3 then
		return true
	end

	if not g_game.isOnline() then
		return false
	end

	for iter_274_0, iter_274_1 in pairs(g_game.getContainers()) do
		for iter_274_2, iter_274_3 in ipairs(iter_274_1:getItems()) do
			if iter_274_3:getId() == var_0_141 then
				var_0_3 = true

				return true
			end
		end
	end

	return false
end

function updateSupportPanel()
	if not supportPanel then
		return
	end

	local var_275_0 = var_0_143()
	local var_275_1 = var_0_142("autolootToggle")

	if var_275_1 then
		var_275_1:setEnabled(var_275_0)

		if var_275_0 then
			local var_275_2 = g_settings.getBoolean("autolootEnabled", true)

			var_275_1:setText(var_275_2 and "On" or "Off")
			var_275_1:setIcon(var_275_2 and "/images/store/icon-yes" or "/images/store/icon-no")
			var_275_1:setColor(var_275_2 and "#7ec77e" or "#c77e7e")
		else
			var_275_1:setText("Off")
			var_275_1:setIcon("/images/store/icon-no")
			var_275_1:setColor("#777777")
		end
	end

	local var_275_3 = var_0_142("autolootHelp")

	if var_275_3 then
		if var_275_0 then
			var_275_3:setImageSource("/images/skin/show-gui-help-grey")
			var_275_3:setTooltip(tr("Loots nearby corpses into your loot pouch. Requires a Loot Pouch in your Store Inbox."))
		else
			var_275_3:setImageSource("/images/skin/show-gui-help-red")
			var_275_3:setTooltip(tr("A Loot Pouch is required to enable this function."))
		end
	end

	local var_275_4 = var_0_142("flaskToggle")

	if var_275_4 then
		local var_275_5 = g_settings.getBoolean("flaskEnabled", true)

		var_275_4:setText(var_275_5 and "On" or "Off")
		var_275_4:setIcon(var_275_5 and "/images/store/icon-yes" or "/images/store/icon-no")
		var_275_4:setColor(var_275_5 and "#7ec77e" or "#c77e7e")
	end
end

function toggleSupportAutoloot()
	if not var_0_143() then
		return
	end

	local var_276_0 = g_game.getProtocolGame()

	if var_276_0 then
		var_276_0:sendExtendedOpcode(ExtendedIds.AutolootToggle, "")
	end

	scheduleEvent(updateSupportPanel, 250)
end

function toggleSupportFlask()
	local var_277_0 = g_game.getProtocolGame()

	if var_277_0 then
		var_277_0:sendExtendedOpcode(ExtendedIds.FlaskToggle, "")
	end

	scheduleEvent(updateSupportPanel, 250)
end

function onHelperContainerOpen(arg_278_0)
	if not var_0_3 and arg_278_0 then
		for iter_278_0, iter_278_1 in ipairs(arg_278_0:getItems()) do
			if iter_278_1:getId() == var_0_141 then
				var_0_3 = true

				break
			end
		end
	end

	updateSupportPanel()
	updateUtilitiesPanel()
end

function setAutoFoodMinTime(arg_279_0)
	local var_279_0 = tonumber(tostring(arg_279_0 or ""):match("%d+")) or 5

	var_0_93().minTime = var_279_0 * 60

	saveSettings()
end

function toggleRustyRemover(arg_280_0)
	helperConfig.autoRustyRemover = arg_280_0 == true
end

function updateUtilitiesPanel()
	if not utilitiesPanel then
		return
	end

	local var_281_0 = utilitiesPanel:recursiveGetChildById("rustyRemover")

	if not var_281_0 then
		return
	end

	local var_281_1 = hasRustyRemoverReady()

	var_281_0:setEnabled(var_281_1)

	if not var_281_1 and var_281_0:isChecked() then
		var_281_0:setChecked(false)

		helperConfig.autoRustyRemover = false
	end

	local var_281_2 = utilitiesPanel:recursiveGetChildById("rustyHelp")

	if var_281_2 then
		if var_281_1 then
			var_281_2:setImageSource("/images/skin/show-gui-help-grey")
			var_281_2:setTooltip(tr("Cleans rusty armor, legs, shields and helmets using a Rust Remover."))
		else
			var_281_2:setImageSource("/images/skin/show-gui-help-red")
			var_281_2:setTooltip(tr("A Rust Remover and at least one rusty item are required to enable this function."))
		end
	end
end

function autoEatFood()
	if not g_game.isOnline() or not var_0_0 or not helperConfig.autoEatFood then
		return
	end

	if var_0_42() then
		return true
	end

	if var_0_41(var_0_24.id) >= g_clock.millis() then
		return true
	end

	local var_282_0 = var_0_93()

	if var_282_0.id <= 0 then
		return
	end

	if var_0_0:getInventoryCount(var_282_0.id) > 0 then
		g_game.useInventoryItem(var_282_0.id)

		var_0_40[var_0_24.id] = g_clock.millis() + var_0_24.exhaustion
	end
end

function autoChangeGold()
	if not g_game.isOnline() or not var_0_0 or not helperConfig.autoChangeGold then
		return
	end

	if var_0_42() then
		return
	end

	doChangeGold(var_0_96)
end

function doChangeGold(arg_284_0)
	local var_284_0 = g_game.getContainers()

	for iter_284_0, iter_284_1 in pairs(var_284_0) do
		if iter_284_1 then
			for iter_284_2, iter_284_3 in ipairs(iter_284_1:getItems()) do
				if iter_284_3:getCount() == 100 then
					for iter_284_4, iter_284_5 in ipairs(arg_284_0) do
						if iter_284_3:getId() == iter_284_5 then
							return g_game.useWith(iter_284_3, iter_284_3)
						end
					end
				end
			end
		end
	end
end

function checkMana()
	if not g_game.isOnline() or not var_0_0 or not var_0_10 then
		return
	end

	if not var_0_0 then
		return
	end

	local var_285_0 = var_0_0:getMana()
	local var_285_1 = var_0_0:getMaxMana()

	checkManaHealing(var_285_0, var_285_1)
	checkTrainingSpell(var_285_0, var_285_1)
end

var_0_28.checkMana.action = checkMana

function routineChecks()
	if not var_0_10 then
		return
	end

	if var_0_0 then
		local var_286_0 = var_0_93()

		if var_0_0:getRegenerationTime() < var_286_0.minTime then
			autoEatFood()
		end
	end
end

local function var_0_144()
	for iter_287_0, iter_287_1 in pairs(g_game.getContainers()) do
		if iter_287_1 then
			for iter_287_2, iter_287_3 in ipairs(iter_287_1:getItems()) do
				if var_0_83[iter_287_3:getId()] then
					return iter_287_3
				end
			end
		end
	end

	return nil
end

local function var_0_145()
	for iter_288_0, iter_288_1 in pairs(g_game.getContainers()) do
		if iter_288_1 then
			for iter_288_2, iter_288_3 in ipairs(iter_288_1:getItems()) do
				if iter_288_3:getId() == var_0_82 then
					return iter_288_3
				end
			end
		end
	end

	return nil
end

function hasRustyRemoverReady()
	if not g_game.isOnline() or not var_0_0 then
		return false
	end

	return var_0_144() ~= nil and var_0_145() ~= nil
end

function autoRustyRemover()
	if not g_game.isOnline() or not var_0_0 or not helperConfig.autoRustyRemover then
		return
	end

	if var_0_42() then
		return
	end

	local var_290_0 = var_0_145()

	if not var_290_0 then
		return
	end

	local var_290_1 = var_0_144()

	if not var_290_1 then
		return
	end

	g_game.useWith(var_290_0, var_290_1)
end

var_0_28.routineChecks.action = routineChecks
var_0_28.checkChangeGold.action = autoChangeGold
var_0_28.checkRustyRemover.action = autoRustyRemover

local var_0_146 = false

local function var_0_147(arg_291_0, arg_291_1)
	local var_291_0 = shooterPanel and shooterPanel:recursiveGetChildById("priority" .. arg_291_0)

	if not var_291_0 then
		return
	end

	local var_291_1 = getSpellSlotRank(arg_291_0, arg_291_1)

	var_0_146 = true

	var_291_0:setCurrentOption(var_0_76(var_291_1))

	var_0_146 = false
end

function rebuildSpellPriorityOptions()
	if not shooterPanel then
		return
	end

	local function var_292_0(arg_293_0)
		local var_293_0 = #arg_293_0

		for iter_293_0, iter_293_1 in ipairs(arg_293_0) do
			local var_293_1 = shooterPanel:recursiveGetChildById("priority" .. iter_293_1)

			if var_293_1 then
				var_0_146 = true

				var_293_1:clearOptions()

				for iter_293_2 = 1, var_293_0 do
					var_293_1:addOption(var_0_76(iter_293_2))
				end

				var_0_146 = false
			end
		end
	end

	var_292_0(getAreaSpellSlots())
	var_292_0(getSingleSpellSlots())
end

function updateMagicShooterPriority(arg_294_0, arg_294_1)
	if var_0_146 then
		return
	end

	arg_294_0 = tonumber(arg_294_0)
	arg_294_1 = tonumber(arg_294_1)

	if not arg_294_0 or not arg_294_1 then
		return
	end

	local var_294_0 = getShooterProfile()
	local var_294_1 = var_294_0.spells[arg_294_0 + 1]

	if not var_294_1 then
		return
	end

	local var_294_2, var_294_3 = getSpellSlotRank(arg_294_0, var_294_0)

	arg_294_1 = math.max(1, math.min(#var_294_3, arg_294_1))

	local var_294_4 = var_294_3[arg_294_1].idx

	if var_294_4 == arg_294_0 then
		var_0_147(arg_294_0, var_294_0)

		return
	end

	local var_294_5 = var_294_0.spells[var_294_4 + 1]

	var_294_1.priority, var_294_5.priority = var_294_5.priority, var_294_1.priority

	var_0_147(arg_294_0, var_294_0)
	var_0_147(var_294_4, var_294_0)
end

function updateMagicShooterCreatures(arg_295_0, arg_295_1, arg_295_2)
	local var_295_0 = getShooterProfile()
	local var_295_1 = tonumber(arg_295_2) or 1

	var_295_0.spells[arg_295_1 + 1].creatures = var_295_1
end

function toggleSelfCast(arg_296_0, arg_296_1)
	local var_296_1 = getShooterProfile().spells[arg_296_0 + 1]
	var_296_1.selfCast = arg_296_1
	var_296_1.castMode = arg_296_1 and "Y" or "T"

	-- Use the native 15.30 spell-aim setting too. Enabled means that the
	-- server resolves the spell directly against the attacked creature.
	if var_296_1.id and g_game.sendSelectSpellAim then
		pcall(function()
			g_game.sendSelectSpellAim({ var_296_1.id }, not arg_296_1)
		end)
	end

	local var_296_0 = shooterPanel and shooterPanel:recursiveGetChildById("selfCast" .. arg_296_0)

	updateSelfCastModeWidget(var_296_0)
end

-- Crosshair spells can be aimed at the current target or at the player. Keep
-- that choice visible beside the checkbox: T = target, Y = yourself.
function updateSelfCastModeWidget(arg_296_0)
	if not arg_296_0 then
		return
	end

	local var_296_1 = tonumber(arg_296_0:getId():match("%d+"))
	local var_296_2 = var_296_1 and getShooterProfile().spells[var_296_1 + 1]
	local var_296_0 = var_296_2 and var_296_2.selfCast == true

	arg_296_0:setText(var_296_0 and "Y" or "T")
	arg_296_0:setColor(var_296_0 and "#66ff66" or "#ffd966")
	arg_296_0:setTooltip(var_296_0 and "Y = Yourself (cast on yourself)" or "T = Target (cast on current target)")
end

function toggleForceCast(arg_297_0, arg_297_1)
	getShooterProfile().spells[arg_297_0 + 1].forceCast = arg_297_1
end

function toggleForceRuneCast(arg_298_0, arg_298_1)
	getShooterProfile().runes[arg_298_0 + 1].forceCast = arg_298_1
end

function setMagicShooterHarmony(arg_299_0, arg_299_1)
	local var_299_0 = getShooterProfile()

	arg_299_1 = math.max(1, math.min(5, tonumber(arg_299_1) or 1))
	var_299_0.spells[arg_299_0 + 1].harmony = arg_299_1

	refreshHarmonyIcons(arg_299_0)
end

function toggleMagicShooterSerene(arg_300_0)
	local var_300_0 = getShooterProfile().spells[arg_300_0 + 1]

	var_300_0.serene = not var_300_0.serene

	refreshHarmonyIcons(arg_300_0)
end

function isMagicShooterActive()
	return helperConfig.magicShooterEnabled
end

function toggleMagicShooter(arg_302_0, arg_302_1)
	local var_302_0 = var_0_6:recursiveGetChildById("shooterStatus")

	if not arg_302_0 then
		arg_302_0 = shooterPanel:recursiveGetChildById("enableMagicShooter")

		arg_302_0:setChecked(not arg_302_0:isChecked())
	end

	helperConfig.magicShooterEnabled = arg_302_0:isChecked()

	modules.game_textmessage.displayGameMessage(arg_302_1 and arg_302_1 or string.format("TyronCaster is %s.", helperConfig.magicShooterEnabled and "enabled" or "disabled"))
	var_302_0:setText(helperConfig.magicShooterEnabled and "Active" or "Inactive")
	var_302_0:setColor(helperConfig.magicShooterEnabled and "#44ad25" or "#D33C3C")
end

function isAutoTargetActive()
	return helperConfig.autoTargetEnabled
end

function toggleAutoTarget(arg_304_0)
	local var_304_0 = var_0_6:recursiveGetChildById("targetStatus")

	if not arg_304_0 then
		arg_304_0 = shooterPanel:recursiveGetChildById("enableAutoTarget")

		arg_304_0:setChecked(not arg_304_0:isChecked())
	end

	helperConfig.autoTargetEnabled = arg_304_0:isChecked()

	if not helperConfig.autoTargetEnabled and helperConfig.currentLockedTargetId > 0 then
		helperConfig.currentLockedTargetId = 0

		g_game.cancelAttack()
	end

	modules.game_textmessage.displayGameMessage(string.format("Auto Target is %s.", helperConfig.autoTargetEnabled and "enabled" or "disabled"))
	var_304_0:setText(helperConfig.autoTargetEnabled and "Active" or "Inactive")
	var_304_0:setColor(helperConfig.autoTargetEnabled and "#44ad25" or "#D33C3C")
end

function toggleShooterPreset(arg_305_0, arg_305_1)
	local var_305_0 = ""

	if arg_305_0 then
		var_305_0 = arg_305_0:getCurrentOption().text

		if helperConfig.shooterProfiles[var_305_0] then
			loadShooterProfileByName(var_305_0)
		end
	elseif not arg_305_0 then
		arg_305_0 = presetsPanel:recursiveGetChildById("presets")

		local var_305_1 = {}

		for iter_305_0, iter_305_1 in pairs(helperConfig.shooterProfiles) do
			table.insert(var_305_1, iter_305_0)
		end

		local var_305_2 = #var_305_1

		if var_305_2 == 0 then
			return
		end

		local var_305_3 = 1

		for iter_305_2, iter_305_3 in ipairs(var_305_1) do
			if iter_305_3 == helperConfig.selectedShooterProfile then
				var_305_3 = iter_305_2

				break
			end
		end

		var_305_0 = var_305_1[var_305_3 % var_305_2 + 1]
		var_305_0 = var_305_0 or var_305_1[1]

		arg_305_0:setCurrentOption(var_305_0, true)
		loadShooterProfileByName(var_305_0)
	end

	if not arg_305_1 then
		modules.game_textmessage.displayGameMessage(string.format("TyronCaster profile switched to %s.", var_305_0))
	end
end

function removeProfile()
	local var_306_0
	local var_306_1 = presetsPanel:recursiveGetChildById("presets")

	local function var_306_2()
		if var_306_0 then
			var_306_0:destroy()
		end
	end

	local function var_306_3()
		if var_306_0 then
			var_306_0:destroy()
		end

		if getShooterProfileCount() <= 1 then
			modules.game_textmessage.displayGameMessage(string.format("You can't delete your only preset."))

			return
		end

		local var_308_0 = helperConfig.selectedShooterProfile

		toggleShooterPreset(nil, true)

		helperConfig.shooterProfiles[var_308_0] = nil

		var_306_1:removeOption(var_308_0)
		saveSettings()
		modules.game_textmessage.displayGameMessage(string.format("Preset %s deleted.", var_308_0))
	end

	var_306_0 = displayGeneralBox("Delete Preset", string.format("Are you sure you want to delete preset %s?", helperConfig.selectedShooterProfile), {
		{
			text = tr("Yes"),
			callback = var_306_3
		},
		{
			text = tr("No"),
			callback = var_306_2
		}
	}, yesFunction, noFunction)
end

function updateAutoTargetMode(arg_309_0)
	local var_309_0 = var_0_16[arg_309_0]

	if not var_309_0 then
		return
	end

	helperConfig.autoTargetMode = var_309_0

	local var_309_1 = getShooterProfile()

	if var_309_1 then
		var_309_1.autoTargetMode = var_309_0
	end
end

local function var_0_148(arg_310_0)
	for iter_310_0, iter_310_1 in ipairs(arg_310_0) do
		local var_310_0 = ""

		for iter_310_2, iter_310_3 in ipairs(iter_310_1) do
			var_310_0 = var_310_0 .. tostring(iter_310_3) .. " "
		end

		print(var_310_0)
	end

	print("\n")
end

local function var_0_149(arg_311_0, arg_311_1)
	local var_311_0 = {}
	local var_311_1 = #arg_311_0
	local var_311_2 = #arg_311_0[1]

	if arg_311_1 == Directions.North then
		var_311_0 = arg_311_0
	elseif arg_311_1 == Directions.South then
		for iter_311_0 = 1, var_311_1 do
			var_311_0[iter_311_0] = {}

			for iter_311_1 = 1, var_311_2 do
				var_311_0[iter_311_0][iter_311_1] = arg_311_0[var_311_1 - iter_311_0 + 1][var_311_2 - iter_311_1 + 1]
			end
		end
	elseif arg_311_1 == Directions.East then
		for iter_311_2 = 1, var_311_2 do
			var_311_0[iter_311_2] = {}

			for iter_311_3 = 1, var_311_1 do
				var_311_0[iter_311_2][iter_311_3] = arg_311_0[var_311_1 - iter_311_3 + 1][iter_311_2]
			end
		end
	elseif arg_311_1 == Directions.West then
		for iter_311_4 = 1, var_311_2 do
			var_311_0[iter_311_4] = {}

			for iter_311_5 = 1, var_311_1 do
				var_311_0[iter_311_4][iter_311_5] = arg_311_0[iter_311_5][var_311_2 - iter_311_4 + 1]
			end
		end
	end

	return var_311_0
end

local function var_0_150(arg_312_0)
	for iter_312_0, iter_312_1 in ipairs(arg_312_0) do
		for iter_312_2, iter_312_3 in ipairs(iter_312_1) do
			if iter_312_3 == 3 or iter_312_3 == 2 then
				return iter_312_2, iter_312_0
			end
		end
	end

	return nil, nil
end

function getRelativePosition(arg_313_0)
	local var_313_0 = g_game.getLocalPlayer()

	if not var_313_0 then
		return arg_313_0
	end

	local var_313_1 = var_313_0:getPosition()
	local var_313_2 = {
		x = arg_313_0.x,
		y = arg_313_0.y,
		z = arg_313_0.z
	}

	if var_313_1.x < arg_313_0.x and var_313_1.y < arg_313_0.y then
		var_313_2.x = var_313_2.x - 1
		var_313_2.y = var_313_2.y - 1
	elseif var_313_1.x < arg_313_0.x and var_313_1.y > arg_313_0.y or var_313_1.x < arg_313_0.x then
		var_313_2.x = var_313_2.x - 1
	elseif var_313_1.x > arg_313_0.x and var_313_1.y < arg_313_0.y or var_313_1.y < arg_313_0.y then
		var_313_2.y = var_313_2.y - 1
	end

	return var_313_2
end

local function var_0_151(arg_314_0, arg_314_1, arg_314_2, arg_314_3, arg_314_4)
	if arg_314_1 == Directions.SouthEast or arg_314_1 == Directions.NorthEast then
		arg_314_1 = Directions.East
	elseif arg_314_1 == Directions.SouthWest or arg_314_1 == Directions.NorthWest then
		arg_314_1 = Directions.West
	end

	local var_314_0 = var_0_149(arg_314_2, arg_314_1)
	local var_314_1 = 0
	local var_314_2, var_314_3 = var_0_150(var_314_0)

	if not var_314_2 or not var_314_3 then
		return 0
	end

	for iter_314_0, iter_314_1 in ipairs(var_314_0) do
		for iter_314_2, iter_314_3 in ipairs(iter_314_1) do
			if iter_314_3 == 1 or arg_314_4 and (iter_314_3 == 3 or iter_314_3 == 2) then
				local var_314_4 = {
					x = arg_314_0.x + (iter_314_2 - var_314_2),
					y = arg_314_0.y + (iter_314_0 - var_314_3),
					z = arg_314_0.z
				}

				for iter_314_4, iter_314_5 in ipairs(arg_314_3) do
					if var_0_75(iter_314_5.position, var_314_4) and g_map.isSightClear(arg_314_0, iter_314_5.position) then
						var_314_1 = var_314_1 + 1

						break
					end
				end
			end
		end
	end

	return var_314_1
end

local function var_0_152(arg_315_0, arg_315_1)
	local var_315_0 = arg_315_1.x - arg_315_0.x
	local var_315_1 = arg_315_1.y - arg_315_0.y

	if var_315_0 == 0 and var_315_1 == 0 then
		return nil
	end

	if math.abs(var_315_0) >= math.abs(var_315_1) then
		return var_315_0 >= 0 and Directions.East or Directions.West
	end

	return var_315_1 >= 0 and Directions.South or Directions.North
end

local function findBestWaveDirection(playerPosition, area, creatures, currentDirection)
	local directions = {
		Directions.North,
		Directions.East,
		Directions.South,
		Directions.West
	}
	local bestDirection = currentDirection
	local bestHits = var_0_151(playerPosition, currentDirection, area, creatures, false)

	for _, direction in ipairs(directions) do
		local hits = var_0_151(playerPosition, direction, area, creatures, false)

		if hits > bestHits then
			bestDirection = direction
			bestHits = hits
		end
	end

	return bestDirection, bestHits
end

local function var_0_153(arg_316_0)
	return arg_316_0.vocations and (table.contains(arg_316_0.vocations, 4) or table.contains(arg_316_0.vocations, 8))
end

local function var_0_154(arg_317_0, arg_317_1)
	for iter_317_0, iter_317_1 in ipairs(arg_317_1) do
		local var_317_0 = iter_317_1.position

		if var_317_0 and var_317_0.z == arg_317_0.z then
			local var_317_1 = math.abs(var_317_0.x - arg_317_0.x)
			local var_317_2 = math.abs(var_317_0.y - arg_317_0.y)

			if var_317_1 <= 1 and var_317_2 <= 1 and var_317_1 + var_317_2 > 0 and g_map.isSightClear(arg_317_0, var_317_0) then
				return true
			end
		end
	end

	return false
end

local function var_0_155(arg_318_0)
	if arg_318_0.needTarget or (arg_318_0.range or 0) >= 0 or not arg_318_0.area then
		return false
	end

	return arg_318_0.vocations and (table.contains(arg_318_0.vocations, 9) or table.contains(arg_318_0.vocations, 10))
end

local function var_0_156(arg_319_0)
	local var_319_0, var_319_1 = var_0_150(arg_319_0)

	if not var_319_0 or not var_319_1 then
		return 1
	end

	local var_319_2 = 1

	for iter_319_0, iter_319_1 in ipairs(arg_319_0) do
		for iter_319_2, iter_319_3 in ipairs(iter_319_1) do
			if iter_319_3 == 1 then
				var_319_2 = math.max(var_319_2, math.abs(iter_319_2 - var_319_0), math.abs(iter_319_0 - var_319_1))
			end
		end
	end

	return var_319_2
end

local function var_0_157(arg_320_0, arg_320_1, arg_320_2)
	local var_320_0 = var_0_156(arg_320_1)
	local var_320_1 = 0

	for iter_320_0, iter_320_1 in ipairs(arg_320_2) do
		local var_320_2 = iter_320_1.position

		if var_320_2 and var_320_2.z == arg_320_0.z then
			local var_320_3 = math.abs(var_320_2.x - arg_320_0.x)
			local var_320_4 = math.abs(var_320_2.y - arg_320_0.y)

			if var_320_3 <= var_320_0 and var_320_4 <= var_320_0 and var_320_3 + var_320_4 > 0 and g_map.isSightClear(arg_320_0, var_320_2) then
				var_320_1 = var_320_1 + 1
			end
		end
	end

	return var_320_1
end

local function var_0_158(arg_321_0)
	if arg_321_0.type == "rune" then
		return 2
	end

	if arg_321_0.slotIndex ~= nil and isAoeSpellSlot(arg_321_0.slotIndex) then
		return 0
	end

	return 1
end

local function var_0_159(arg_322_0)
	table.sort(arg_322_0, function(arg_323_0, arg_323_1)
		local var_323_0 = var_0_158(arg_323_0)
		local var_323_1 = var_0_158(arg_323_1)

		if var_323_0 ~= var_323_1 then
			return var_323_0 < var_323_1
		end

		return (arg_323_0.config.priority or 999) < (arg_323_1.config.priority or 999)
	end)

	local var_322_0 = g_game.getLocalPlayer()

	if not var_322_0 then
		return arg_322_0
	end

	local var_322_1 = var_322_0:getHarmony()

	if var_322_1 >= 1 then
		local var_322_2

		for iter_322_0, iter_322_1 in ipairs(arg_322_0) do
			if iter_322_1.spell and iter_322_1.spell.spender then
				local var_322_3 = iter_322_1.config.harmony or 1

				if (not iter_322_1.config.serene or var_322_0:isSerene()) and var_322_3 <= var_322_1 then
					var_322_2 = iter_322_0

					break
				end
			end
		end

		if var_322_2 then
			local var_322_4 = table.remove(arg_322_0, var_322_2)

			table.insert(arg_322_0, 1, var_322_4)
		end
	end

	return arg_322_0
end

local function var_0_160(arg_324_0, arg_324_1, arg_324_2, arg_324_3, arg_324_4)
	local var_324_0
	local var_324_1 = 0

	for iter_324_0, iter_324_1 in pairs(arg_324_3) do
		if var_0_77(arg_324_0, iter_324_1.position) and g_map.isSightClear(arg_324_0, iter_324_1.position) then
			local var_324_2 = var_0_151(iter_324_1.position, arg_324_1, arg_324_2, arg_324_3, true)

			if arg_324_4 <= var_324_2 and var_324_1 < var_324_2 then
				var_324_1 = var_324_2
				var_324_0 = iter_324_1.creature
			end
		end
	end

	return var_324_0, var_324_1
end

local var_0_161 = {}

local function var_0_162(arg_325_0, arg_325_1)
	if not var_0_72 then
		return
	end

	local var_325_0 = g_clock.millis()

	if var_325_0 >= (var_0_161[arg_325_0] or 0) + 1000 then
		var_0_161[arg_325_0] = var_325_0

		print(arg_325_1)
	end
end

function isSpellOnCooldown(arg_326_0)
	local var_326_0 = g_clock.millis()

	if var_326_0 <= var_0_41(arg_326_0.id) then
		var_0_162("idlock-" .. tostring(arg_326_0.id), string.format("[CDDbg] BLOCK %s (id=%s): id-cooldown %dms left", tostring(arg_326_0.words), tostring(arg_326_0.id), var_0_41(arg_326_0.id) - var_326_0))

		return true
	end

	if type(arg_326_0.group) == "table" then
		for iter_326_0, iter_326_1 in pairs(arg_326_0.group) do
			if var_326_0 <= (var_0_73[iter_326_0] or 0) then
				var_0_162("grp-" .. tostring(iter_326_0), string.format("[CDDbg] BLOCK %s (id=%s): group-cooldown group=%s %dms left", tostring(arg_326_0.words), tostring(arg_326_0.id), tostring(iter_326_0), var_0_73[iter_326_0] - var_326_0))

				return true
			end
		end
	elseif arg_326_0.group and var_326_0 <= (var_0_73[arg_326_0.group] or 0) then
		var_0_162("grp-" .. tostring(arg_326_0.group), string.format("[CDDbg] BLOCK %s (id=%s): group-cooldown group=%s %dms left", tostring(arg_326_0.words), tostring(arg_326_0.id), tostring(arg_326_0.group), var_0_73[arg_326_0.group] - var_326_0))

		return true
	end

	return false
end

function getMonstersInArea(arg_327_0, arg_327_1, arg_327_2, arg_327_3, arg_327_4, arg_327_5, arg_327_6)
	local var_327_0 = 0
	local var_327_1 = {}

	if arg_327_6 == true or not arg_327_6 then
		var_327_1 = {}
	else
		var_327_1 = arg_327_6
	end

	if arg_327_5 then
		for iter_327_0, iter_327_1 in pairs(g_map.getSpectators(arg_327_1, arg_327_5)) do
			if iter_327_1 ~= var_0_0 and iter_327_1:isPlayer() and not iter_327_1:isPartyMember() then
				return 0
			end
		end
	end

	if arg_327_0 == 1 or arg_327_0 == 3 or arg_327_0 == 4 then
		if arg_327_0 == 1 or arg_327_0 == 3 then
			local var_327_2 = getTarget() and getTarget():getName()

			if #var_327_1 ~= 0 and not table.find(var_327_1, var_327_2, true) then
				return 0
			end
		end

		for iter_327_2, iter_327_3 in pairs(g_map.getSpectators()) do
			local var_327_3 = iter_327_3:getHealthPercent()
			local var_327_4 = iter_327_3:getName():lower()

			var_327_0 = iter_327_3:isMonster() and arg_327_3 <= var_327_3 and var_327_3 <= arg_327_4 and (#var_327_1 == 0 or table.find(var_327_1, var_327_4, true)) and (g_game.getClientVersion() < 960 or iter_327_3:getType() < 3) and var_327_0 + 1 or var_327_0
		end

		return var_327_0
	end

	for iter_327_4, iter_327_5 in pairs(g_map.getSpectators(arg_327_1, arg_327_2)) do
		if iter_327_5 ~= var_0_0 then
			local var_327_5 = iter_327_5:getHealthPercent()
			local var_327_6 = iter_327_5:getName():lower()

			var_327_0 = iter_327_5:isMonster() and arg_327_3 <= var_327_5 and var_327_5 <= arg_327_4 and (#var_327_1 == 0 or table.find(var_327_1, var_327_6)) and (g_game.getClientVersion() < 960 or iter_327_5:getType() < 3) and var_327_0 + 1 or var_327_0
		end
	end

	return var_327_0
end

local function var_0_163(arg_328_0, arg_328_1)
	return getMonstersInArea(2, arg_328_0, arg_328_1, 0, 100, false, nil)
end

function checkMagicShooter()
	if not helperConfig.magicShooterEnabled then
		return
	end

	local var_329_0 = getShooterProfile()
	local var_329_1 = g_game.getLocalPlayer()

	if not var_329_1 then
		return
	end

	if var_329_1:isInProtectionZone() then
		if var_0_72 then
			print("[HealDbg] shooter: skip (protection zone)")
		end

		return
	end

	if HelperPosture and HelperPosture.castPending and HelperPosture.castPending(var_329_1, function(spell)
		return not isSpellOnCooldown(spell)
	end) then
		return
	end

	local var_329_2 = g_game.getFollowingCreature() ~= nil
	local var_329_3 = var_329_1:getPosition()
	local var_329_4 = var_329_1:getDirection()
	local var_329_5 = {}
	local var_329_6 = 0

	for iter_329_0, iter_329_1 in pairs(var_0_78) do
		if iter_329_1:getPosition().z == var_329_3.z and var_0_74(var_329_3, iter_329_1:getPosition()) <= 6 then
			var_329_6 = var_329_6 + 1
		end

		table.insert(var_329_5, {
			position = iter_329_1:getPosition(),
			creature = iter_329_1
		})
	end

	local var_329_7 = {}

	for iter_329_2, iter_329_3 in ipairs(var_329_0.spells) do
		local var_329_8 = iter_329_3.id ~= 0 and Spells.getSpellDataById(iter_329_3.id) or nil

		if var_329_8 then
			table.insert(var_329_7, {
				type = "spell",
				spell = var_329_8,
				config = iter_329_3,
				slotIndex = iter_329_2 - 1
			})
		end
	end

	for iter_329_4, iter_329_5 in ipairs(var_329_0.runes) do
		local var_329_9 = Spells.getRuneSpellByItem(iter_329_5.id)

		if var_329_9 then
			table.insert(var_329_7, {
				type = "rune",
				rune = var_329_9,
				config = iter_329_5
			})
		end
	end

	local var_329_10 = var_0_159(var_329_7)

	if var_0_72 then
		print(string.format("[ShootDbg] unifiedList size=%d voc=%d harmony=%s serene=%s", #var_329_10, getPlayerVocation(), tostring(var_0_0:getHarmony()), tostring(var_0_0:isSerene())))

		for iter_329_6, iter_329_7 in ipairs(var_329_10) do
			if iter_329_7.type == "spell" then
				print(string.format("[ShootDbg]   [%d] spell %s spender=%s vocs=%s", iter_329_6, tostring(iter_329_7.spell.words), tostring(iter_329_7.spell.spender), tostring(table.concat(iter_329_7.spell.vocations or {}, ","))))
			else
				print(string.format("[ShootDbg]   [%d] rune %s", iter_329_6, tostring(iter_329_7.config and iter_329_7.config.id)))
			end
		end
	end

	local var_329_11 = usesCycleRune()

	if var_329_11 then
		local var_329_12 = var_329_0.runes[1]

		if var_329_12 and var_329_12.id ~= 0 and var_329_12.useDuringCycle and (var_329_12.interval or 4000) <= g_clock.millis() - var_0_13 then
			for iter_329_8, iter_329_9 in ipairs(var_329_10) do
				if iter_329_9.type == "rune" then
					table.insert(var_329_10, 1, table.remove(var_329_10, iter_329_8))

					break
				end
			end
		end
	end

	local var_329_13 = var_0_0:getMana() / var_0_0:getMaxMana() * 100
	local var_329_14 = var_0_0:getHarmony()

	if var_0_45 and g_clock.millis() - var_0_45.time >= 600 then
		if var_0_72 then
			print(string.format("[ShootDbg] %s: cast not confirmed, backoff %dms", tostring(var_0_45.words), var_0_44))
		end

		local var_329_15 = var_0_45.id

		var_0_45 = nil

		onSpellCooldown(var_329_15, var_0_44)
	end

	if isKnightVoc() and var_329_0.combatStance and var_329_0.combatStance.id ~= 0 then
		local var_329_16 = var_329_0.combatStance
		local var_329_17 = Spells.getSpellDataById(var_329_16.id)

		if var_329_17 and var_329_13 >= (var_329_16.percent or 0) and var_0_0:getMana() >= var_329_17.mana and table.contains(var_329_17.vocations, getPlayerVocation()) and g_clock.millis() - var_0_14 >= (var_329_16.cooldown or 30000) and not isSpellOnCooldown(var_329_17) then
			g_game.talk(var_329_17.words)
			onSpellCooldown(var_329_17.id, var_0_43)

			var_0_14 = g_clock.millis()
		end
	end

	for iter_329_10, iter_329_11 in ipairs(var_329_10) do
		if var_0_11 then
			-- block empty
		else
			local var_329_18 = g_game.getAttackingCreature()
			local var_329_19 = var_329_18 and var_329_18:getPosition() or {
				z = 255,
				y = 65535,
				x = 65535
			}

			if iter_329_11.type == "spell" then
				local var_329_20 = false
				local var_329_34 = nil
				local var_329_21 = iter_329_11.spell
				local var_329_22 = iter_329_11.config
				var_329_22.castMode = var_329_22.castMode or (var_329_22.selfCast and "Y" or "T")
				local var_329_23 = 0
				local var_329_24 = var_329_21.range and var_329_21.range > 0 or table.contains(var_0_97, var_329_21.id)

				if var_0_45 and var_0_45.id == var_329_21.id then
					if var_0_72 then
						print(string.format("[ShootDbg] %s: skip awaiting-confirm", tostring(var_329_21.words)))
					end
				elseif var_0_0:getMana() < var_329_21.mana then
					if var_0_72 then
						print(string.format("[ShootDbg] %s: skip mana(%d<%d)", tostring(var_329_21.words), var_0_0:getMana(), var_329_21.mana))
					end
				elseif var_329_24 and not var_329_18 and var_329_22.castMode == "T" then
					if var_0_72 then
						print(string.format("[ShootDbg] %s: skip no-target(targetable)", tostring(var_329_21.words)))
					end
				elseif var_329_2 and var_329_24 and var_329_22.castMode == "T" then
					if var_0_72 then
						print(string.format("[ShootDbg] %s: skip targeted(following)", tostring(var_329_21.words)))
					end
				elseif not table.contains(var_329_21.vocations, getPlayerVocation()) then
					if var_0_72 then
						print(string.format("[ShootDbg] %s: skip vocation(%d not in list)", tostring(var_329_21.words), getPlayerVocation()))
					end
				else
					if var_329_21.spender then
						local var_329_25 = var_329_22.harmony or 1

						if var_329_14 < var_329_25 then
							if var_0_72 then
								print(string.format("[ShootDbg] %s: skip harmony(%d<%d)", tostring(var_329_21.words), var_329_14, var_329_25))
							end

							goto label_329_0
						end

						if var_329_22.serene and not var_0_0:isSerene() then
							if var_0_72 then
								print(string.format("[ShootDbg] %s: skip serene(need serene)", tostring(var_329_21.words)))
							end

							goto label_329_0
						end
					end

					if var_329_13 < var_329_22.percent then
						if var_0_72 then
							print(string.format("[ShootDbg] %s: skip mana%%(%.0f<%d)", tostring(var_329_21.words), var_329_13, var_329_22.percent))
						end
					else
						if table.contains(var_0_97, var_329_21.id) and var_329_22.castMode == "Y" then
							var_329_34 = var_329_3
							local var_329_26 = modules.game_interface.getMapPanel()
							local var_329_27 = var_329_26 and var_329_26:getSpectators() or {}

							for iter_329_12, iter_329_13 in ipairs(var_329_27) do
								if iter_329_13:isMonster() and iter_329_13:getHealthPercent() > 0 then
									local var_329_28 = iter_329_13:getPosition()

									if var_329_28.z == var_329_3.z and var_0_74(var_329_3, var_329_28) <= 4 then
										var_329_23 = var_329_23 + 1
									end
								end
							end

							if var_329_23 >= var_329_22.creatures then
								var_329_20 = true
							end
						elseif var_329_24 and var_329_22.castMode == "T" then
							var_329_34 = var_329_19
							if not var_329_19 or var_329_19.z ~= var_329_3.z or not var_329_18:canBeSeen() then
								goto label_329_0
							end

							if (var_329_21.range or 3) >= var_0_74(var_329_3, var_329_19) then
								if var_329_21.area then
									var_329_23 = var_0_151(var_329_19, 1, var_329_21.area, var_329_5, true)
								else
									var_329_23 = 1
								end
							end
						elseif var_329_21.area then
							local var_329_29 = var_329_4
							local isDirectional = var_329_21.directional == true
							local autoTurn = isDirectional and var_329_22.autoTurn == true

							if var_0_155(var_329_21) then
								var_329_23 = var_0_157(var_329_3, var_329_21.area, var_329_5)
							elseif autoTurn then
								var_329_29, var_329_23 = findBestWaveDirection(var_329_3, var_329_21.area, var_329_5, var_329_4)

								if var_329_29 ~= var_329_4 and var_329_23 >= var_329_22.creatures then
									g_game.turn(var_329_29)
								end
							else
								var_329_23 = var_0_151(var_329_3, var_329_29, var_329_21.area, var_329_5, false)
							end

							if var_329_23 > 0 and var_0_153(var_329_21) and not var_0_154(var_329_3, var_329_5) then
								var_329_23 = 0
							end

							if table.contains(var_0_97, var_329_21.id) and var_329_23 >= var_329_22.creatures then
								var_329_20 = true
							end
						end

						if var_0_72 then
							print(string.format("[ShootDbg] %s: area=%s reach=%d need=%s selfCast=%s", tostring(var_329_21.words), tostring(var_329_21.area ~= nil), var_329_23, tostring(var_329_22.creatures), tostring(var_329_22.selfCast)))
						end

						if var_329_23 >= var_329_22.creatures then
							-- A configured target spell must not be disabled merely because
							-- more than one monster is nearby. That old safety rule made the
							-- Shooter stop completely in normal hunts; the configured creature
							-- count, target, range and cooldown already guard the cast.
							if isSpellOnCooldown(var_329_21) then
								if var_0_72 then
									print(string.format("[ShootDbg] %s: skip cooldown", tostring(var_329_21.words)))
								end
							else
								if var_329_34 and g_game.talkSpell then
									-- Reliable helper aim channel. Some 15.30 protocol combinations
									-- discard the optional position tail of a say packet. Stage the
									-- same tile through an OTC extended opcode immediately before
									-- speaking; the server consumes it for this one spell only.
									local var_329_35 = g_game.getProtocolGame and g_game.getProtocolGame()
									if var_329_35 and var_329_35.sendExtendedOpcode then
										var_329_35:sendExtendedOpcode(249, string.format("%d,%d,%d", var_329_34.x, var_329_34.y, var_329_34.z))
									end
									g_game.talkSpell(var_329_21.words, var_329_22.castMode == "T" and 3 or 2, var_329_34)
								elseif var_329_20 and var_329_18 then
									g_game.cancelAttack()
									g_game.talk(var_329_21.words)
									scheduleEvent(function()
										if var_329_18 and not var_329_18:isRemoved() then
											g_game.attack(var_329_18)
										end
									end, 100)
								else
									g_game.talk(var_329_21.words)
								end

								if var_0_72 then
									print(string.format("[ShootDbg] CAST %s (reach=%d need=%s)", tostring(var_329_21.words), var_329_23, tostring(var_329_22.creatures)))
								end

								if var_0_45 and var_0_45.id ~= var_329_21.id then
									onSpellCooldown(var_0_45.id, var_0_44)
								end

								onSpellCooldown(var_329_21.id, var_0_43)

								var_0_45 = {
									id = var_329_21.id,
									words = var_329_21.words,
									time = g_clock.millis()
								}

								return
							end
						end
					end
				end
			elseif iter_329_11.type ~= "rune" or helperConfig.magicShooterOnHold then
				-- block empty
			else
				local var_329_31 = iter_329_11.rune
				local var_329_32 = iter_329_11.config

				if var_329_11 and (var_329_32.interval or 4000) > g_clock.millis() - var_0_13 then
					-- block empty
				elseif var_329_1:getInventoryCount(var_329_32.id) > 0 then
					local var_329_33

					if var_329_31.area then
						var_329_33 = var_0_160(var_329_3, var_329_4, var_329_31.area, var_329_5, var_329_32.creatures)
					else
						var_329_33 = var_329_18 and var_0_77(var_329_3, var_329_19) and g_map.isSightClear(var_329_3, var_329_19) and var_329_18 or nil
					end

					if not var_329_33 or not var_329_32.forceCast and not var_329_31.area and var_329_6 > 1 then
						-- block empty
					elseif isSpellOnCooldown(var_329_31) or var_0_12 > g_clock.millis() then
						-- block empty
					else
						g_game.useInventoryItemWith(var_329_32.id, var_329_33, 0, true)
						onSpellCooldown(var_329_31.id, var_0_43)

						if var_329_11 then
							var_0_13 = g_clock.millis()
						end

						return
					end
				end
			end
		end

		::label_329_0::
	end
end

var_0_28.checkMagicShooter.action = checkMagicShooter

function checkAutoTarget()
	if not helperConfig.autoTargetEnabled then
		return
	end

	if var_0_11 then
		return
	end

	local var_331_0 = g_game.getLocalPlayer()

	if not var_331_0 then
		if var_0_72 then
			print("[TgtDbg] skip: getLocalPlayer() == nil")
		end

		return
	end

	if var_0_72 then
		local var_331_1 = g_game.getFollowingCreature()
		local var_331_2 = g_game.getAttackingCreature()

		print(string.format("[TgtDbg] enter pz=%s follow=%s(rm=%s) attacking=%s(rm=%s)", tostring(var_331_0:isInProtectionZone()), tostring(var_331_1 and var_331_1:getId()), tostring(var_331_1 and var_331_1:isRemoved()), tostring(var_331_2 and var_331_2:getId()), tostring(var_331_2 and var_331_2:isRemoved())))
	end

	if var_331_0:isInProtectionZone() then
		if var_0_72 then
			print("[TgtDbg] autoTarget: skip (protection zone)")
		end

		return
	end

	local var_331_3 = var_331_0:getPosition()
	local var_331_4 = helperConfig.currentLockedTargetId ~= 0 and g_map.getCreatureById(helperConfig.currentLockedTargetId) or nil

	if var_331_4 and not var_331_4:isDead() and
		not (HelperCavebot and HelperCavebot.isCreatureIgnored and HelperCavebot.isCreatureIgnored(var_331_4)) and
		var_0_77(var_331_3, var_331_4:getPosition()) then
		return
	end

	local var_331_5 = {
		id = nil,
		distance = 99
	}
	local var_331_6 = {
		id = nil,
		distance = -1
	}
	local var_331_7 = {
		id = nil,
		health = 100
	}
	local var_331_8 = {
		id = nil,
		health = -1
	}
	local var_331_9 = {
		id = nil,
		creatures = 0
	}
	local var_331_10 = {
		health = 100,
		distance = 99,
		id = nil
	}
	local var_331_11 = {
		health = -1,
		distance = 99,
		id = nil
	}
	local var_331_12 = {
		health = 100,
		distance = -1,
		id = nil
	}
	local var_331_13 = {
		health = -1,
		distance = -1,
		id = nil
	}
	local var_331_14 = SpellAreas.AREA_CIRCLE3X3

	if getPlayerVocation() == 7 then
		var_331_14 = SpellAreas.AREA_CIRCLE2X2
	end

	local var_331_15 = {}
	local var_331_16 = g_map.getSpectators(var_331_3, false)

	for iter_331_0, iter_331_1 in pairs(var_331_16) do
		if iter_331_1:isMonster() and iter_331_1:getType() < 3 and
			not (HelperCavebot and HelperCavebot.isCreatureIgnored and HelperCavebot.isCreatureIgnored(iter_331_1)) then
			table.insert(var_331_15, {
				position = iter_331_1:getPosition(),
				creature = iter_331_1
			})
		end
	end

	local var_331_17 = {}
	local var_331_18 = 0

	for iter_331_2, iter_331_3 in pairs(var_331_15) do
		if not var_0_77(var_331_3, iter_331_3.position) or not g_map.isSightClear(var_331_3, iter_331_3.position) then
			-- block empty
		else
			local var_331_19 = iter_331_3.creature:getHealthPercent()

			if var_331_7.id == nil then
				var_331_7 = {
					id = iter_331_3.creature:getId(),
					health = var_331_19
				}
			end

			if var_331_19 < var_331_7.health then
				var_331_7 = {
					id = iter_331_3.creature:getId(),
					health = var_331_19
				}
			end

			if var_331_19 > var_331_8.health then
				var_331_8 = {
					id = iter_331_3.creature:getId(),
					health = var_331_19
				}
			end

			local var_331_20 = var_0_74(var_331_3, iter_331_3.position)

			if var_331_20 < var_331_5.distance then
				var_331_5 = {
					id = iter_331_3.creature:getId(),
					distance = var_331_20
				}
			end

			if var_331_20 > var_331_6.distance then
				var_331_6 = {
					id = iter_331_3.creature:getId(),
					distance = var_331_20
				}
			end

			if var_331_20 < var_331_10.distance or var_331_20 == var_331_10.distance and var_331_19 < var_331_10.health then
				var_331_10 = {
					id = iter_331_3.creature:getId(),
					distance = var_331_20,
					health = var_331_19
				}
			end

			if var_331_20 < var_331_11.distance or var_331_20 == var_331_11.distance and var_331_19 > var_331_11.health then
				var_331_11 = {
					id = iter_331_3.creature:getId(),
					distance = var_331_20,
					health = var_331_19
				}
			end

			if var_331_20 > var_331_12.distance or var_331_20 == var_331_12.distance and var_331_19 < var_331_12.health then
				var_331_12 = {
					id = iter_331_3.creature:getId(),
					distance = var_331_20,
					health = var_331_19
				}
			end

			if var_331_20 > var_331_13.distance or var_331_20 == var_331_13.distance and var_331_19 > var_331_13.health then
				var_331_13 = {
					id = iter_331_3.creature:getId(),
					distance = var_331_20,
					health = var_331_19
				}
			end

			local var_331_21 = var_0_151(iter_331_3.position, 1, var_331_14, var_331_15, true)

			if var_331_18 < var_331_21 then
				var_331_18 = var_331_21
				var_331_9.id = iter_331_3.creature:getId()
				var_331_9.creatures = var_331_21
			end

			table.insert(var_331_17, iter_331_3.creature)
		end
	end

	local var_331_22 = g_game.getAttackingCreature()
	local var_331_23

	if var_331_22 and HelperCavebot and HelperCavebot.isCreatureIgnored and HelperCavebot.isCreatureIgnored(var_331_22) then
		g_game.cancelAttack()
		helperConfig.currentLockedTargetId = 0
		var_331_22 = nil
	end

	if helperConfig.autoTargetMode == var_0_16.A then
		var_331_23 = g_map.getCreatureById(var_331_5.id)
	elseif helperConfig.autoTargetMode == var_0_16.B then
		var_331_23 = g_map.getCreatureById(var_331_6.id)
	elseif helperConfig.autoTargetMode == var_0_16.C then
		var_331_23 = g_map.getCreatureById(var_331_7.id)
	elseif helperConfig.autoTargetMode == var_0_16.D then
		var_331_23 = g_map.getCreatureById(var_331_8.id)
	elseif helperConfig.autoTargetMode == var_0_16.E and var_331_9.id ~= nil then
		var_331_23 = g_map.getCreatureById(var_331_9.id)
	elseif helperConfig.autoTargetMode == var_0_16.F then
		var_331_23 = g_map.getCreatureById(var_331_10.id)
	elseif helperConfig.autoTargetMode == var_0_16.G then
		var_331_23 = g_map.getCreatureById(var_331_11.id)
	elseif helperConfig.autoTargetMode == var_0_16.H then
		var_331_23 = g_map.getCreatureById(var_331_12.id)
	elseif helperConfig.autoTargetMode == var_0_16.I then
		var_331_23 = g_map.getCreatureById(var_331_13.id)
	end

	if var_0_72 then
		print(string.format("[TgtDbg] candidates=%d target=%s currentTarget=%s", #var_331_15, tostring(var_331_23 and var_331_23:getId()), tostring(var_331_22 and var_331_22:getId())))
	end

	if var_331_23 and (not var_331_22 or var_331_22:getId() ~= var_331_23:getId()) then
		if var_0_72 then
			print("[TgtDbg] -> attack " .. tostring(var_331_23:getId()))
		end

		g_game.attack(var_331_23)
	end
end

var_0_28.checkAutoTarget.action = checkAutoTarget

function checkFriendHealing()
	if not var_0_10 then
		return
	end

	local var_332_0 = g_game.getLocalPlayer()

	if var_332_0 and var_332_0:isPartyMember() then
		onFriendHealing(var_332_0)
	end
end

var_0_28.checkFriendHealing.action = checkFriendHealing

local var_0_164 = 0

function checkAutoHaste()
	if not var_0_10 then
		return
	end

	if not g_game.getLocalPlayer() or helperConfig.haste[1].id == 0 then
		return true
	end

	if not helperConfig.haste[1].enabled then
		return true
	end

	if not helperConfig.haste[1].safecast and var_0_0:isInProtectionZone() then
		return true
	end

	local var_333_0 = helperConfig.haste[1].id
	local var_333_1 = Spells.getSpellDataById(var_333_0)

	if not var_333_1 or var_333_1.id == 0 then
		return false
	end

	if not checkHealthPriority() then
		return
	end

	local var_333_2 = g_clock.millis()

	local var_333_3 = tonumber(var_333_1.duration) or tonumber(var_333_1.exhaustion) or 1000

	if var_333_2 < var_0_164 + var_333_3 then
		return
	end

	g_game.talk(var_333_1.words, true)

	var_0_164 = var_333_2
end

var_0_28.checkAutoHaste.action = checkAutoHaste

function checkHealthPriority()
	if not var_0_10 then
		return
	end

	for iter_334_0, iter_334_1 in ipairs(helperConfig.spells) do
		local var_334_0 = var_0_0:getHealth() / var_0_0:getMaxHealth() * 100

		if iter_334_1.id ~= 0 and var_334_0 <= tonumber(iter_334_1.percent) then
			return false
		end
	end

	return true
end

function toggleReconnect(arg_335_0)
	helperConfig.autoReconnect = arg_335_0

	g_settings.set("autoReconnect", arg_335_0)
end

function onFriendHealing(arg_336_0)
	if not var_0_10 then
		return
	end

	local var_336_0 = helperConfig.friendhealing[1]
	local var_336_1 = helperConfig.friendhealing[2]
	local var_336_2 = helperConfig.gransiohealing[1]
	local var_336_3 = helperConfig.gransiohealing[2]
	local var_336_4 = arg_336_0:getPosition()
	local var_336_5 = g_map.getSpectators(var_336_4, false)
	local var_336_6 = {}

	for iter_336_0, iter_336_1 in ipairs(var_336_5) do
		if iter_336_1:isPlayer() and iter_336_1:isPartyMember() and not iter_336_1:isLocalPlayer() then
			table.insert(var_336_6, iter_336_1)
		end
	end

	table.sort(var_336_6, function(arg_337_0, arg_337_1)
		if arg_337_0:getName() == var_336_0.name then
			return true
		elseif arg_337_1:getName() == var_336_0.name then
			return false
		else
			return arg_337_0:getName() < arg_337_1:getName()
		end
	end)

	for iter_336_2, iter_336_3 in ipairs(var_336_6) do
		if not iter_336_3:isPlayer() then
			-- block empty
		else
			local var_336_7 = iter_336_3:getHealthPercent()

			if not (g_map.isSightClear(var_336_4, iter_336_3:getPosition()) and var_0_77(var_336_4, iter_336_3:getPosition())) then
				-- block empty
			else
				if var_336_2.enabled and iter_336_3:getName() == var_336_2.name and var_336_7 <= var_336_2.percent then
					useAutoGranSio(iter_336_3)
				end

				if var_336_3.enabled and iter_336_3:getName() == var_336_3.name and var_336_7 <= var_336_3.percent then
					useAutoGranSio(iter_336_3)
				end

				if var_336_0.enabled and iter_336_3:getName() == var_336_0.name and var_336_7 <= var_336_0.percent and iter_336_3:isPartyMember() then
					if getPlayerVocation() == 5 then
						useAutoUH(iter_336_3)
					elseif isMonkVocId(getPlayerVocation()) then
						useAutoTioSio(iter_336_3)
					else
						useAutoSio(iter_336_3)
					end
				end

				if var_336_1.enabled and iter_336_3:getName() == var_336_1.name and var_336_7 <= var_336_1.percent and iter_336_3:isPartyMember() then
					if getPlayerVocation() == 5 then
						useAutoUH(iter_336_3)
					elseif isMonkVocId(getPlayerVocation()) then
						useAutoTioSio(iter_336_3)
					else
						useAutoSio(iter_336_3)
					end
				end
			end
		end
	end
end

function reset()
	for iter_338_0 = 0, var_0_20 - 1 do
		removeAction("spell", var_0_1:recursiveGetChildById("spellButton" .. iter_338_0))
		removeAction("potion", var_0_1:recursiveGetChildById("potionButton" .. iter_338_0))
	end

	for iter_338_1 = 0, 7 do
		local var_338_0 = shooterPanel:recursiveGetChildById("attackSpellButton" .. iter_338_1)

		if var_338_0 then
			removeAction("shooter", var_338_0)
		end
	end

	for iter_338_2 = 0, 2 do
		removeAction("rune", runePanel:recursiveGetChildById("runeShooterButton" .. iter_338_2))
	end

	removeAction("training", var_0_2:recursiveGetChildById("spellTrainingButton0"))
	removeAction("haste", var_0_2:recursiveGetChildById("hasteButton0"))
	removeAction("exercise", var_0_2:recursiveGetChildById("autoTrainingItem"))
end

function removeAction(arg_339_0, arg_339_1, arg_339_2)
	invalidateHelperCache()

	local var_339_0 = tonumber(arg_339_1:getId():match("%d+"))

	if arg_339_0 == "spell" then
		helperConfig.spells[var_339_0 + 1].id = 0
		helperConfig.spells[var_339_0 + 1].percent = 80

		local var_339_1 = var_0_1:recursiveGetChildById("spellButton" .. var_339_0)
		local var_339_2 = var_0_1:recursiveGetChildById("spellPercentLabel" .. var_339_0)

		var_339_1:setImageSource("/images/game/actionbar/actionbarslot")
		var_339_1:setImageClip("0 0 34 34")
		var_339_1:setBorderWidth(0)
		var_339_1:setTooltip("")
		var_339_2:setText("80%")
		var_0_1:recursiveGetChildById("rmvPercentButton" .. var_339_0):setEnabled(true)
		var_0_1:recursiveGetChildById("addPercentButton" .. var_339_0):setEnabled(true)
	elseif arg_339_0 == "shooter" then
		local var_339_3 = isAoeSpellSlot(var_339_0) and 2 or 1

		if not arg_339_2 then
			local var_339_4 = getShooterProfile()

			var_339_4.spells[var_339_0 + 1].id = 0
			var_339_4.spells[var_339_0 + 1].percent = 80
			var_339_4.spells[var_339_0 + 1].creatures = var_339_3
			var_339_4.spells[var_339_0 + 1].forceCast = false
			var_339_4.spells[var_339_0 + 1].selfCast = false
		end

		local var_339_5 = shooterPanel:recursiveGetChildById("attackSpellButton" .. var_339_0)

		var_339_5:setImageSource("/images/game/actionbar/actionbarslot")
		var_339_5:setImageClip("0 0 34 34")
		var_339_5:setBorderWidth(0)
		var_339_5:setTooltip("")

		local var_339_6 = shooterPanel:recursiveGetChildById("spellPercentLabel" .. var_339_0)

		shooterPanel:recursiveGetChildById("rmvPercentButton" .. var_339_0):setEnabled(true)
		shooterPanel:recursiveGetChildById("addPercentButton" .. var_339_0):setEnabled(true)
		var_339_6:setText("80%")

		local var_339_7 = shooterPanel:recursiveGetChildById("conditionSetting" .. var_339_0)

		var_339_7:setChecked(false)
		var_339_7:setVisible(false)

		local var_339_8 = shooterPanel:recursiveGetChildById("countMinCreature" .. var_339_0)

		var_339_8:setCurrentOption(var_339_3 .. "+")
		var_339_8:enable()

		local var_339_9 = shooterPanel:recursiveGetChildById("selfCast" .. var_339_0)

		if var_339_9 then
			var_339_9:destroy()
		end

		local var_339_10 = shooterPanel:recursiveGetChildById("aimTarget" .. var_339_0)

		if var_339_10 then
			var_339_10:destroy()
		end

		local var_339_11 = shooterPanel:recursiveGetChildById("harmonyGroup" .. var_339_0)

		if var_339_11 then
			var_339_11:destroy()
		end
	elseif arg_339_0 == "combatstance" then
		getShooterProfile().combatStance.id = 0

		local var_339_12 = shooterPanel:recursiveGetChildById("combatStanceButton0")

		if var_339_12 then
			var_339_12:setImageSource("/images/game/actionbar/actionbarslot")
			var_339_12:setImageClip("0 0 34 34")
			var_339_12:setBorderWidth(0)
			var_339_12:setTooltip("")
		end
	elseif arg_339_0 == "potion" then
		if not helperConfig.potions[var_339_0 + 1] then
			helperConfig.potions[var_339_0 + 1] = {}
		end

		if helperConfig.potions[var_339_0 + 1].id == 7642 or helperConfig.potions[var_339_0 + 1].id == 23374 then
			helperConfig.potions[var_339_0 + 1].priority = 0

			local var_339_13 = var_0_1:recursiveGetChildById("priority" .. var_339_0)

			var_339_13:setImageSource("/images/skin/show-gui-help-grey")
			var_339_13:setTooltip("Uses a healing or mana potion when your health or\nmana reaches the defined percentage.\nPaladins can click on this button to change the potion priority:\n  - Icon: Blue (Mana Priority)\n  - Icon: Red  (Health Priority)")
		end

		helperConfig.potions[var_339_0 + 1].id = 0
		helperConfig.potions[var_339_0 + 1].percent = 50

		local var_339_14 = var_0_1:recursiveGetChildById("potionButton" .. var_339_0)

		var_339_14:setImageSource("/images/game/actionbar/actionbarslot")

		local var_339_15 = var_0_1:recursiveGetChildById("potionPercentLabel" .. var_339_0)

		if var_339_14.potionItem then
			var_339_14.potionItem:destroy()
		end

		var_339_15:setText("50%")
		var_0_1:recursiveGetChildById("rmvPotionPercentButton" .. var_339_0):setEnabled(true)
		var_0_1:recursiveGetChildById("addPotionPercentButton" .. var_339_0):setEnabled(true)
	elseif arg_339_0 == "rune" then
		local var_339_16 = isAoeRuneSlot(var_339_0) and 2 or 1

		if not arg_339_2 then
			local var_339_17 = getShooterProfile()

			if not var_339_17.runes[var_339_0 + 1] then
				var_339_17.runes[var_339_0 + 1] = {}
			end

			var_339_17.runes[var_339_0 + 1].id = 0
			var_339_17.runes[var_339_0 + 1].creatures = var_339_16
			var_339_17.runes[var_339_0 + 1].forceCast = false
		end

		local var_339_18 = runePanel:recursiveGetChildById("runeShooterButton" .. var_339_0)

		var_339_18:setImageSource("/images/game/actionbar/actionbarslot")

		local var_339_19 = runePanel:recursiveGetChildById("countMinCreature" .. var_339_0)

		var_339_19:setCurrentOption(var_339_16 .. "+")
		var_339_19:enable()

		local var_339_20 = runePanel:recursiveGetChildById("conditionSetting" .. var_339_0)

		var_339_20:setVisible(false)
		var_339_20:setChecked(false)

		if var_339_18.runeItem then
			var_339_18.runeItem:destroy()
		end
	elseif arg_339_0 == "training" then
		helperConfig.training[var_339_0 + 1].id = 0
		helperConfig.training[var_339_0 + 1].percent = 0
		helperConfig.training[var_339_0 + 1].enabled = false

		local var_339_21 = var_0_2:recursiveGetChildById("spellTrainingButton" .. var_339_0)
		local var_339_22 = var_0_2:recursiveGetChildById("spellTrainingPercent" .. var_339_0)

		var_339_21:setImageSource("/images/game/actionbar/actionbarslot")
		var_339_21:setImageClip("0 0 34 34")
		var_339_21:setBorderWidth(0)
		var_339_21:setTooltip("")
		var_339_22:setCurrentOption("100%")
		var_0_2:recursiveGetChildById("enableTraining" .. var_339_0):setChecked(false)
	elseif arg_339_0 == "haste" then
		helperConfig.haste[var_339_0 + 1].id = 0
		helperConfig.haste[var_339_0 + 1].enabled = false
		helperConfig.haste[var_339_0 + 1].safecast = false

		local var_339_23 = var_0_2:recursiveGetChildById("hasteButton" .. var_339_0)

		var_339_23:setImageSource("/images/game/actionbar/actionbarslot")
		var_339_23:setImageClip("0 0 34 34")
		var_339_23:setBorderWidth(0)
		var_339_23:setTooltip("")
		var_0_2:recursiveGetChildById("enableHaste" .. var_339_0):setChecked(false)
		var_0_2:recursiveGetChildById("castOnPz"):setChecked(false)
	elseif arg_339_0 == "exercise" then
		local var_339_24 = var_0_91()

		var_339_24.id = 0
		var_339_24.enabled = false

		var_0_64()
		var_0_92(0)

		local var_339_25 = var_0_2:recursiveGetChildById("autoTrainingCheck")

		if var_339_25 then
			var_339_25:setChecked(false)
		end
	elseif arg_339_0 == "food" then
		var_0_93().id = 0
		helperConfig.autoEatFood = false

		var_0_94(0)

		local var_339_26 = var_0_2:recursiveGetChildById("autoFoodCheck")

		if var_339_26 then
			var_339_26:setChecked(false)
		end
	end
end

function refreshShooterPresetCombo()
	if not presetsPanel then
		return
	end

	local var_340_0 = presetsPanel:recursiveGetChildById("presets")

	if not var_340_0 then
		return
	end

	var_340_0:clear()

	local var_340_1 = {}

	for iter_340_0 in pairs(helperConfig.shooterProfiles or {}) do
		var_340_1[#var_340_1 + 1] = iter_340_0
	end

	table.sort(var_340_1)

	for iter_340_1, iter_340_2 in ipairs(var_340_1) do
		var_340_0:addOption(iter_340_2)
	end

	local var_340_2 = helperConfig.selectedShooterProfile

	if var_340_2 and helperConfig.shooterProfiles and helperConfig.shooterProfiles[var_340_2] then
		var_340_0:setCurrentOption(var_340_2, true)
	end
end

function loadProfileOptions()
	local var_341_0 = helperConfig.selectedShooterProfile
	local var_341_1 = presetsPanel:recursiveGetChildById("presets")

	if var_341_1 then
		if var_341_1:getOptionsCount() > 0 then
			return
		end

		local var_341_2 = {}

		for iter_341_0, iter_341_1 in pairs(helperConfig.shooterProfiles) do
			table.insert(var_341_2, iter_341_0)
		end

		table.sort(var_341_2)

		for iter_341_2, iter_341_3 in ipairs(var_341_2) do
			var_341_1:addOption(iter_341_3)
		end

		var_341_1:setCurrentOption(var_341_0)
		var_341_1:updateCurrentOption(var_341_0)
	end
end

function loadShooterProfileByName(arg_342_0)
	helperConfig.selectedShooterProfile = arg_342_0

	local var_342_0 = getShooterProfile()

	if not var_342_0 then
		return
	end

	local var_342_1 = var_0_6:recursiveGetChildById("currentPresetName")

	if var_342_1 then
		var_342_1:setText(arg_342_0)
	end

	if var_342_0.autoTargetMode then
		helperConfig.autoTargetMode = var_342_0.autoTargetMode

		local var_342_2 = enableButtons:recursiveGetChildById("autoTargetMode")

		if var_342_2 then
			for iter_342_0, iter_342_1 in pairs(var_0_16) do
				if iter_342_1 == var_342_0.autoTargetMode then
					var_342_2:setCurrentOption(iter_342_0)

					break
				end
			end
		end
	end

	rebuildSpellPriorityOptions()

	for iter_342_2, iter_342_3 in ipairs(getAreaSpellSlots()) do
		var_0_147(iter_342_3, var_342_0)
	end

	for iter_342_4, iter_342_5 in ipairs(getSingleSpellSlots()) do
		var_0_147(iter_342_5, var_342_0)
	end

	local var_342_3 = getPlayerVocation() ~= 0

	for iter_342_6, iter_342_7 in pairs(var_342_0.spells) do
		if not shooterPanel:recursiveGetChildById("attackSpellButton" .. iter_342_6 - 1) then
			-- block empty
		else
			iter_342_7.id = tonumber(iter_342_7.id) or 0
			iter_342_7.creatures = tonumber(iter_342_7.creatures) or 1
			iter_342_7.percent = tonumber(iter_342_7.percent) or 0

			if iter_342_7.id > 0 and var_342_3 then
				local var_342_4 = Spells.getSpellDataById(iter_342_7.id)

				if var_342_4 then
					local var_342_5 = isAreaSpellData(var_342_4)

					if isAoeSpellSlot(iter_342_6 - 1) and not var_342_5 or not isAoeSpellSlot(iter_342_6 - 1) and var_342_5 then
						iter_342_7.id = 0
					end
				end
			end

			if iter_342_7.id > 0 and var_342_3 then
				if isAoeSpellSlot(iter_342_6 - 1) then
					if iter_342_7.creatures < 2 then
						iter_342_7.creatures = 2
					end
				else
					iter_342_7.creatures = 1
				end
			end

			if iter_342_7.id <= 0 then
				removeAction("shooter", shooterPanel:recursiveGetChildById("attackSpellButton" .. iter_342_6 - 1))
				ensureHarmonyIcons(iter_342_6 - 1, nil)
			else
				local var_342_6 = shooterPanel:recursiveGetChildById("attackSpellButton" .. iter_342_6 - 1)
				local var_342_7 = shooterPanel:recursiveGetChildById("countMinCreature" .. iter_342_6 - 1)
				local var_342_8 = shooterPanel:recursiveGetChildById("priority" .. iter_342_6 - 1)
				local var_342_9 = shooterPanel:recursiveGetChildById("conditionSetting" .. iter_342_6 - 1)
				local var_342_10 = shooterPanel:recursiveGetChildById("selfCast" .. iter_342_6 - 1)

				var_342_9:setChecked(iter_342_7.forceCast)
				var_342_8:setCurrentOption(var_0_76(getSpellSlotRank(iter_342_6 - 1, var_342_0)))
				var_342_7:setCurrentOption(tostring(iter_342_7.creatures) .. "+")

				local var_342_11 = Spells.getSpellDataById(iter_342_7.id)

				if var_342_11 then
					local var_342_12 = SpelllistSettings.Default.iconFile
					local var_342_13 = Spells.getImageClip(getCrystalSpellIconId(var_342_11), "Default")

					var_342_6:setImageSource(var_342_12)
					var_342_6:setImageClip(var_342_13)
					var_342_6:setBorderColorTop("#1b1b1b")
					var_342_6:setBorderColorLeft("#1b1b1b")
					var_342_6:setBorderColorRight("#757575")
					var_342_6:setBorderColorBottom("#757575")
					var_342_6:setBorderWidth(1)
					var_342_6:setTooltip("Spell: " .. Spells.getSpellNameByWords(var_342_11.words) .. "\nWords: " .. var_342_11.words)

					if table.contains(var_0_97, var_342_11.id) and not var_342_10 then
						var_342_10 = g_ui.createWidget("Button", var_342_6)

						if var_342_10 then
							local var_342_14 = {
								width = 12,
								height = 12,
								font = "Verdana Bold-9px-small",
								["anchors.right"] = "parent.right",
								["anchors.bottom"] = "parent.bottom"
							}

							var_342_10:mergeStyle(var_342_14)
							var_342_10:setId("selfCast" .. iter_342_6 - 1)
							var_342_10:setTooltip("Cast on yourself")
							var_342_10:setVisible(true)
							updateSelfCastModeWidget(var_342_10)

							function var_342_10.onClick()
								local var_342_15 = tonumber(var_342_10:getId():match("%d+"))
								toggleSelfCast(var_342_15, not getShooterProfile().spells[var_342_15 + 1].selfCast)
							end
						end

						if var_342_10 then
							updateSelfCastModeWidget(var_342_10)
						end
					end

					-- Refresh controls that already existed before loading this preset.
					if table.contains(var_0_97, var_342_11.id) and var_342_10 then
						updateSelfCastModeWidget(var_342_10)
					elseif var_342_10 then
						var_342_10:destroy()
						var_342_10 = nil
					end

					if var_342_7 and not var_342_11.area and not table.contains(var_0_97, var_342_11.id) then
						var_342_7:setCurrentOption("1+")
						var_342_7:disable()

						iter_342_7.creatures = 1

						var_342_9:setVisible(true)
					else
						var_342_7:setEnabled(true)
						var_342_7:setCurrentOption(tostring(iter_342_7.creatures) .. "+")
						var_342_9:setVisible(false)
						var_342_9:setChecked(false)
					end

					ensureAimCheckbox(iter_342_6 - 1, var_342_11)
					ensureHarmonyIcons(iter_342_6 - 1, var_342_11)
				end

				shooterPanel:recursiveGetChildById("spellPercentLabel" .. iter_342_6 - 1):setText(tostring(iter_342_7.percent) .. "%")

				if iter_342_7.percent <= 1 then
					shooterPanel:recursiveGetChildById("rmvPercentButton" .. iter_342_6 - 1):setEnabled(false)
				elseif iter_342_7.percent >= 99 then
					shooterPanel:recursiveGetChildById("addPercentButton" .. iter_342_6 - 1):setEnabled(false)
				end
			end
		end
	end

	for iter_342_8, iter_342_9 in pairs(var_342_0.runes) do
		if iter_342_9.id > 0 then
			local var_342_15 = Spells.getRuneSpellByItem(iter_342_9.id)

			if var_342_15 then
				local var_342_16 = var_342_15.area and true or false

				if isAoeRuneSlot(iter_342_8 - 1) and not var_342_16 or not isAoeRuneSlot(iter_342_8 - 1) and var_342_16 then
					iter_342_9.id = 0
				end
			end
		end

		if iter_342_9.id > 0 then
			if isAoeRuneSlot(iter_342_8 - 1) then
				if iter_342_9.creatures < 2 then
					iter_342_9.creatures = 2
				end
			else
				iter_342_9.creatures = 1
			end
		end

		if iter_342_9.id <= 0 then
			removeAction("rune", runePanel:recursiveGetChildById("runeShooterButton" .. iter_342_8 - 1))
		else
			local var_342_17 = runePanel:recursiveGetChildById("runeShooterButton" .. iter_342_8 - 1)

			if var_342_17.runeItem then
				var_342_17.runeItem:destroy()
			end

			local var_342_18 = g_ui.createWidget("RuneItem", var_342_17)

			var_342_18:setItemId(iter_342_9.id)
			var_342_18:setId("runeItem")

			local var_342_19 = runePanel:recursiveGetChildById("countMinCreature" .. iter_342_8 - 1)

			var_342_19:setCurrentOption(tostring(iter_342_9.creatures) .. "+")

			local var_342_20 = runePanel:recursiveGetChildById("conditionSetting" .. iter_342_8 - 1)

			var_342_20:setVisible(false)
			var_342_20:setChecked(iter_342_9.forceCast)

			local var_342_21 = Spells.getRuneSpellByItem(iter_342_9.id)

			if var_342_21 then
				if not var_342_21.area then
					var_342_19:disable()
					var_342_20:setVisible(true)
				else
					var_342_19:setEnabled(true)
					var_342_19:setCurrentOption(tostring(iter_342_9.creatures) .. "+")
					var_342_20:setVisible(false)
					var_342_20:setChecked(false)
				end

				var_342_17:setTooltip(string.format(var_342_21.name .. " %s", var_342_21.area and "(Area Damage)" or "(Single Damage)"))
			end

			runePanel:recursiveGetChildById("runePriority" .. iter_342_8 - 1):setCurrentOption(var_0_76(iter_342_9.priority))
		end
	end

	local var_342_22 = var_342_0.runes[1]

	if var_342_22 then
		if var_342_22.interval == nil then
			var_342_22.interval = 4000
		end

		if var_342_22.useDuringCycle == nil then
			var_342_22.useDuringCycle = false
		end

		local var_342_23 = runePanel:recursiveGetChildById("cycleRuneInterval")

		if var_342_23 then
			var_342_23:setCurrentOption(math.floor(var_342_22.interval / 1000) .. "s")
		end

		local var_342_24 = runePanel:recursiveGetChildById("cycleRuneCheck")

		if var_342_24 then
			var_342_24:setChecked(var_342_22.useDuringCycle)
		end
	end

	local var_342_25 = var_342_0.combatStance

	if var_342_25 then
		if var_342_25.cooldown == nil then
			var_342_25.cooldown = 30000
		end

		if var_342_25.percent == nil then
			var_342_25.percent = 0
		end

		if var_342_25.id and var_342_25.id ~= 0 and not combatStanceSpellIds[var_342_25.id] then
			var_342_25.id = 0
		end

		local var_342_26 = runePanel:recursiveGetChildById("combatStanceButton0")

		if var_342_26 then
			if var_342_25.id and var_342_25.id ~= 0 then
				local var_342_27 = Spells.getSpellDataById(var_342_25.id)

				if var_342_27 then
					local var_342_28 = SpelllistSettings.Default.iconFile
					local var_342_29 = Spells.getImageClip(getCrystalSpellIconId(var_342_27), "Default")

					var_342_26:setImageSource(var_342_28)
					var_342_26:setImageClip(var_342_29)
					var_342_26:setBorderColorTop("#1b1b1b")
					var_342_26:setBorderColorLeft("#1b1b1b")
					var_342_26:setBorderColorRight("#757575")
					var_342_26:setBorderColorBottom("#757575")
					var_342_26:setBorderWidth(1)
					var_342_26:setTooltip("Spell: " .. Spells.getSpellNameByWords(var_342_27.words) .. "\nWords: " .. var_342_27.words)
				end
			else
				var_342_26:setImageSource("/images/game/actionbar/actionbarslot")
				var_342_26:setImageClip("0 0 34 34")
				var_342_26:setBorderWidth(0)
				var_342_26:setTooltip("")
			end
		end

		local var_342_30 = runePanel:recursiveGetChildById("combatStanceCooldown")

		if var_342_30 then
			var_342_30:setCurrentOption(math.floor(var_342_25.cooldown / 1000) .. "s")
		end

		local var_342_31 = runePanel:recursiveGetChildById("combatStancePercentLabel")

		if var_342_31 then
			var_342_31:setText(var_342_25.percent .. "%")
		end
	end

	syncHarmonyIcons()
end

function onLoadHelperData()
	for iter_344_0, iter_344_1 in pairs(helperConfig.spells) do
		iter_344_1.id = tonumber(iter_344_1.id) or 0

		if iter_344_1.id ~= 0 then
			local var_344_0 = var_0_1:recursiveGetChildById("spellButton" .. iter_344_0 - 1)
			local var_344_1 = Spells.getSpellDataById(iter_344_1.id)

			if var_344_1 then
				local var_344_2 = SpelllistSettings.Default.iconFile
				local var_344_3 = Spells.getImageClip(getCrystalSpellIconId(var_344_1), "Default")

				var_344_0:setImageSource(var_344_2)
				var_344_0:setImageClip(var_344_3)
				var_344_0:setBorderColorTop("#1b1b1b")
				var_344_0:setBorderColorLeft("#1b1b1b")
				var_344_0:setBorderColorRight("#757575")
				var_344_0:setBorderColorBottom("#757575")
				var_344_0:setBorderWidth(1)
				var_344_0:setTooltip("Spell: " .. Spells.getSpellNameByWords(var_344_1.words) .. "\nWords: " .. var_344_1.words)
			end
		end

		var_0_1:recursiveGetChildById("spellPercentLabel" .. iter_344_0 - 1):setText(tostring(iter_344_1.percent) .. "%")
	end

	for iter_344_2, iter_344_3 in pairs(helperConfig.potions) do
		if iter_344_3.id ~= 0 then
			local var_344_4 = var_0_1:recursiveGetChildById("potionButton" .. iter_344_2 - 1)
			local var_344_5 = g_ui.createWidget("PotionItem", var_344_4)

			var_344_5:setItemId(iter_344_3.id)
			var_344_5:setId("potionItem")

			if iter_344_3.id == 7642 or iter_344_3.id == 23374 then
				local var_344_6 = var_0_1:recursiveGetChildById("priority" .. iter_344_2 - 1)

				if iter_344_3.priority == 1 then
					var_344_6:setImageSource("/images/skin/show-gui-help-red")
					var_344_6:setTooltip("This potion is healing health...")

					var_344_6.actionId = 1
					helperConfig.potions[iter_344_2].priority = 1
				else
					var_344_6:setImageSource("/images/skin/show-gui-help-blue")
					var_344_6:setTooltip("This potion is healing mana...")

					var_344_6.actionId = 2
					helperConfig.potions[iter_344_2].priority = 2
				end
			end
		end

		var_0_1:recursiveGetChildById("potionPercentLabel" .. iter_344_2 - 1):setText(tostring(iter_344_3.percent) .. "%")
	end

	for iter_344_4, iter_344_5 in pairs(helperConfig.training) do
		iter_344_5.id = tonumber(iter_344_5.id) or 0

		if iter_344_5.id ~= 0 then
			local var_344_7 = var_0_2:recursiveGetChildById("spellTrainingButton" .. iter_344_4 - 1)
			local var_344_8 = Spells.getSpellDataById(iter_344_5.id)

			if var_344_8 then
				local var_344_9 = SpelllistSettings.Default.iconFile
				local var_344_10 = Spells.getImageClip(getCrystalSpellIconId(var_344_8), "Default")

				var_344_7:setImageSource(var_344_9)
				var_344_7:setImageClip(var_344_10)
				var_344_7:setBorderColorTop("#1b1b1b")
				var_344_7:setBorderColorLeft("#1b1b1b")
				var_344_7:setBorderColorRight("#757575")
				var_344_7:setBorderColorBottom("#757575")
				var_344_7:setBorderWidth(1)
				var_344_7:setTooltip("Spell: " .. Spells.getSpellNameByWords(var_344_8.words) .. "\nWords: " .. var_344_8.words)
			end

			var_0_2:recursiveGetChildById("spellTrainingPercent" .. iter_344_4 - 1):setCurrentOption(tostring(iter_344_5.percent) .. "%")
			var_0_2:recursiveGetChildById("enableTraining" .. iter_344_4 - 1):setChecked(iter_344_5.enabled)
		end
	end

	for iter_344_6, iter_344_7 in pairs(helperConfig.haste) do
		iter_344_7.id = tonumber(iter_344_7.id) or 0

		if iter_344_7.id ~= 0 then
			local var_344_11 = var_0_2:recursiveGetChildById("hasteButton" .. iter_344_6 - 1)
			local var_344_12 = Spells.getSpellDataById(iter_344_7.id)

			if var_344_12 then
				local var_344_13 = SpelllistSettings.Default.iconFile
				local var_344_14 = Spells.getImageClip(getCrystalSpellIconId(var_344_12), "Default")

				var_344_11:setImageSource(var_344_13)
				var_344_11:setImageClip(var_344_14)
				var_344_11:setBorderColorTop("#1b1b1b")
				var_344_11:setBorderColorLeft("#1b1b1b")
				var_344_11:setBorderColorRight("#757575")
				var_344_11:setBorderColorBottom("#757575")
				var_344_11:setBorderWidth(1)
				var_344_11:setTooltip("Spell: " .. Spells.getSpellNameByWords(var_344_12.words) .. "\nWords: " .. var_344_12.words)
			end

			var_0_2:recursiveGetChildById("enableHaste" .. iter_344_6 - 1):setChecked(iter_344_7.enabled)
			var_0_2:recursiveGetChildById("castOnPz"):setChecked(iter_344_7.safecast)
		end
	end

	local var_344_15 = var_0_91()

	if var_344_15.id > 0 then
		var_0_92(var_344_15.id)
	else
		var_0_92(0)
	end

	local var_344_16 = var_0_2:recursiveGetChildById("autoTrainingCheck")

	if var_344_16 then
		var_344_16:setChecked(var_344_15.enabled)
	end

	local var_344_17 = var_0_93()

	var_0_94(var_344_17.id)

	local var_344_18 = var_0_2:recursiveGetChildById("foodTimeBox")

	if var_344_18 then
		var_344_18:setCurrentOption(math.floor(var_344_17.minTime / 60) .. "min", true)
	end

	local var_344_19 = var_0_2:recursiveGetChildById("autoFoodCheck")

	if var_344_19 then
		var_344_19:setChecked(helperConfig.autoEatFood)
	end

	loadShooterProfileByName(helperConfig.selectedShooterProfile)
	var_0_2:recursiveGetChildById("reconnect"):setChecked(helperConfig.autoReconnect)
	var_0_2:recursiveGetChildById("changeGold"):setChecked(helperConfig.autoChangeGold)

	local var_344_20 = var_0_2:recursiveGetChildById("rustyRemover")

	if var_344_20 then
		var_344_20:setChecked(helperConfig.autoRustyRemover)
	end

	enableButtons:recursiveGetChildById("enableMagicShooter"):setChecked(helperConfig.magicShooterEnabled)
	enableButtons:recursiveGetChildById("enableAutoTarget"):setChecked(helperConfig.autoTargetEnabled)

	local var_344_21 = enableButtons:recursiveGetChildById("autoTargetMode")

	for iter_344_8, iter_344_9 in pairs(var_0_16) do
		if iter_344_9 == helperConfig.autoTargetMode then
			var_344_21:setCurrentOption(iter_344_8)

			break
		end
	end

	if HelperCavebot and HelperCavebot.loadFromConfig then
		HelperCavebot.loadFromConfig(helperConfig)
	end
end

function saveSettings()
	invalidateHelperCache()
	if HelperCavebot and HelperCavebot.collectConfig then
		HelperCavebot.collectConfig(helperConfig)
	end
	if HelperPosture and HelperPosture.collectConfig then
		HelperPosture.collectConfig(helperConfig)
	end

	local var_345_0 = var_0_60(true)

	if not var_345_0 then
		return
	end

	if g_game.getLocalPlayer() then
		helperConfig.vocation = getPlayerVocation()
	end

	helperConfig.helperEnabled = var_0_10

	syncActiveToSelectedProfiles()

	local var_345_1, var_345_2 = pcall(function()
		return json.encode(helperConfig, 2)
	end)

	if not var_345_1 then
		return onError("Error while saving helper profile settings. Data won't be saved. Details: " .. var_345_2)
	end

	if var_345_2:len() > 104857600 then
		return onError("Something went wrong, file is above 100MB, won't be saved")
	end

	local var_345_3, var_345_4 = pcall(var_0_62)

	if not var_345_3 then
		return onError("Error while creating helper settings directory. Data won't be saved. Details: " .. tostring(var_345_4))
	end

	local var_345_5, var_345_6 = pcall(function()
		return g_resources.writeFileContents(var_345_0, var_345_2)
	end)

	if not var_345_5 then
		return onError("Error while writing helper profile settings. Data won't be saved. Details: " .. tostring(var_345_6))
	end
end

function exportHelperSettingsRaw()
	if g_game.isOnline() then
		pcall(saveSettings)
	end

	local var_348_0 = var_0_60(false)

	if not var_348_0 or not g_resources.fileExists(var_348_0) then
		return nil
	end

	local var_348_1, var_348_2 = pcall(g_resources.readFileContents, var_348_0)

	if var_348_1 and type(var_348_2) == "string" and #var_348_2 > 0 then
		return var_348_2
	end

	return nil
end

function importHelperSettingsRaw(arg_349_0)
	if type(arg_349_0) ~= "string" or #arg_349_0 == 0 then
		return false
	end

	local var_349_0, var_349_1 = pcall(json.decode, arg_349_0)

	if not var_349_0 or type(var_349_1) ~= "table" then
		return false
	end

	local var_349_2 = var_0_60(false)

	if not var_349_2 or not g_game.isOnline() then
		g_settings.setNode("helper_pending_import", {
			content = arg_349_0
		})
		g_settings.save()

		return true
	end

	if not pcall(var_0_62) then
		return false
	end

	if not pcall(function()
		return g_resources.writeFileContents(var_349_2, arg_349_0)
	end) then
		return false
	end

	loadSettings()
	loadProfileOptions()
	onLoadHelperData()

	return true
end

function loadSettings()
	invalidateHelperCache()

	local var_351_0 = var_0_60(false)
	local var_351_1 = var_0_61(false)

	if not var_351_0 and not var_351_1 then
		return false
	end

	local var_351_2
	local var_351_3 = false

	helperConfig = {
		selectedShooterProfile = "Default",
		magicShooterOnHold = false,
		selectedToolsProfile = "Default",
		autoChangeGold = false,
		autoReconnect = false,
		autoEatFood = false,
		autoRustyRemover = false,
		magicShooterEnabled = false,
		selectedHealingProfile = "Default",
		autoTargetEnabled = false,
		currentLockedTargetId = 0,
		spells = {
			{
				id = 0,
				percent = 80
			},
			{
				id = 0,
				percent = 80
			},
			{
				id = 0,
				percent = 80
			}
		},
		potions = {
			{
				percent = 50,
				id = 0,
				priority = 0
			},
			{
				percent = 50,
				id = 0,
				priority = 0
			},
			{
				percent = 50,
				id = 0,
				priority = 0
			}
		},
		training = {
			{
				enabled = false,
				percent = 0,
				id = 0
			}
		},
		exerciseTraining = {
			id = 0,
			enabled = false
		},
		haste = {
			{
				enabled = false,
				safecast = false,
				id = 0
			}
		},
		friendhealing = {
			{
				enabled = false,
				name = "",
				percent = 0
			},
			{
				enabled = false,
				name = "",
				percent = 0
			}
		},
		gransiohealing = {
			{
				enabled = false,
				name = "",
				percent = 0
			},
			{
				enabled = false,
				name = "",
				percent = 0
			}
		},
		shooterProfiles = {
			Default = var_0_18(var_0_19)
		},
		healingProfiles = {
			Default = var_0_18(var_0_21)
		},
		toolsProfiles = {
			Default = var_0_18(var_0_22)
		},
		autoFood = {
			id = 0,
			minTime = 300
		},
		autoTargetMode = var_0_16.F
	}

	if var_351_0 and g_resources.fileExists(var_351_0) then
		var_351_2 = var_351_0
	elseif var_351_1 and g_resources.fileExists(var_351_1) then
		var_351_2 = var_351_1
		var_351_3 = true
	end

	if var_351_2 then
		local var_351_4, var_351_5 = pcall(function()
			return json.decode(g_resources.readFileContents(var_351_2))
		end)

		if not var_351_4 or type(var_351_5) ~= "table" then
			return false
		end

		helperConfig = var_351_5

		if not var_351_5.spells then
			helperConfig.spells = var_0_18(var_0_21.spells)
		end

		while #helperConfig.spells < var_0_20 do
			table.insert(helperConfig.spells, {
				id = 0,
				percent = 80
			})
		end

		for iter_351_0, iter_351_1 in pairs(helperConfig.spells) do
			if iter_351_1.percent == 0 then
				iter_351_1.percent = 80
			end
		end

		if not var_351_5.potions then
			helperConfig.potions = var_0_18(var_0_21.potions)
		end

		while #helperConfig.potions < var_0_20 do
			table.insert(helperConfig.potions, {
				percent = 50,
				id = 0,
				priority = 0
			})
		end

		for iter_351_2, iter_351_3 in pairs(helperConfig.potions) do
			if iter_351_3.percent == 0 then
				iter_351_3.percent = 50
			end

			if not iter_351_3.priority then
				iter_351_3.priority = 0
			end
		end

		if not var_351_5.training then
			helperConfig.training = {
				{
					enabled = false,
					percent = 0,
					id = 0
				}
			}
		end

		if not var_351_5.exerciseTraining then
			helperConfig.exerciseTraining = {
				id = 0,
				enabled = false
			}
		end

		local var_351_6 = var_0_91()

		if var_351_6.id > 0 and not table.find(var_0_85, var_351_6.id) then
			var_351_6.id = 0
			var_351_6.enabled = false
		end

		if not var_351_5.haste then
			helperConfig.haste = {
				{
					enabled = false,
					safecast = false,
					id = 0
				}
			}
		end

		if not var_351_5.friendhealing then
			helperConfig.friendhealing = {
				{
					enabled = false,
					name = "",
					percent = 0
				},
				{
					enabled = false,
					name = "",
					percent = 0
				}
			}
		end

		if not var_351_5.gransiohealing then
			helperConfig.gransiohealing = {
				{
					enabled = false,
					name = "",
					percent = 0
				},
				{
					enabled = false,
					name = "",
					percent = 0
				}
			}
		end

		if not var_351_5.shooterProfiles then
			var_351_5.selectedShooterProfile = "Default"
			var_351_5.shooterProfiles = {
				Default = var_0_19
			}
		end

		for iter_351_4, iter_351_5 in pairs(helperConfig.shooterProfiles) do
			if not iter_351_5.autoTargetMode then
				iter_351_5.autoTargetMode = var_0_16.F
			end

			if iter_351_5.runes and #iter_351_5.runes < 3 then
				iter_351_5.runes[3] = {
					creatures = 1,
					forceCast = false,
					id = 0,
					priority = 8
				}
			end

			if iter_351_5.spells then
				if not iter_351_5.spells[6] then
					iter_351_5.spells[6] = {
						harmony = 1,
						selfCast = false,
						forceCast = false,
						priority = 6,
						creatures = 2,
						percent = 0,
						id = 0,
						serene = false
					}
				end

				if not iter_351_5.spells[7] then
					iter_351_5.spells[7] = {
						harmony = 1,
						selfCast = false,
						forceCast = false,
						priority = 7,
						creatures = 1,
						percent = 0,
						id = 0,
						serene = false
					}
				end

				if not iter_351_5.spells[8] then
					iter_351_5.spells[8] = {
						harmony = 1,
						selfCast = false,
						forceCast = false,
						priority = 8,
						creatures = 2,
						percent = 0,
						id = 0,
						serene = false
					}
				end
			end

			if not iter_351_5.combatStance then
				iter_351_5.combatStance = {
					id = 0,
					percent = 0,
					cooldown = 30000
				}
			end
		end

		if not var_351_5.healingProfiles then
			helperConfig.selectedHealingProfile = "Default"
			helperConfig.healingProfiles = {
				Default = {
					spells = var_0_18(helperConfig.spells),
					potions = var_0_18(helperConfig.potions),
					friendhealing = var_0_18(helperConfig.friendhealing),
					gransiohealing = var_0_18(helperConfig.gransiohealing)
				}
			}
		end

		if not var_351_5.toolsProfiles then
			helperConfig.selectedToolsProfile = "Default"
			helperConfig.toolsProfiles = {
				Default = {
					training = var_0_18(helperConfig.training),
					exerciseTraining = var_0_18(helperConfig.exerciseTraining),
					haste = var_0_18(helperConfig.haste)
				}
			}
		end

		if type(helperConfig.healingProfiles) == "table" then
			for iter_351_6, iter_351_7 in pairs(helperConfig.healingProfiles) do
				padHealingData(iter_351_7)
			end
		end

		for iter_351_8, iter_351_9 in ipairs({
			helperConfig.shooterProfiles,
			helperConfig.healingProfiles,
			helperConfig.toolsProfiles
		}) do
			for iter_351_10, iter_351_11 in pairs(iter_351_9) do
				if iter_351_11.vocation == nil then
					iter_351_11.vocation = 0
				end
			end
		end

		if not var_351_5.autoEatFood then
			helperConfig.autoEatFood = false
		end

		if type(var_351_5.autoFood) ~= "table" then
			helperConfig.autoFood = {
				id = 0,
				minTime = 300
			}
		end

		if not var_351_5.autoReconnect then
			helperConfig.autoReconnect = false
		end

		if not var_351_5.autoChangeGold then
			helperConfig.autoChangeGold = false
		end

		if not var_351_5.autoRustyRemover then
			helperConfig.autoRustyRemover = false
		end

		if not var_351_5.magicShooterEnabled then
			helperConfig.magicShooterEnabled = false
		end

		if not var_351_5.magicShooterOnHold then
			helperConfig.magicShooterOnHold = false
		end

		if not var_351_5.autoTargetEnabled then
			helperConfig.autoTargetEnabled = false
		end

		if not var_351_5.autoTargetMode then
			helperConfig.autoTargetMode = var_0_16.F
		end

		if not var_351_5.currentLockedTargetId then
			helperConfig.currentLockedTargetId = 0
		end

		local var_351_7 = g_game.getLocalPlayer()
		local var_351_8 = getPlayerVocation()
		local var_351_9 = helperConfig.vocation == var_351_8 or isMonkVocId(helperConfig.vocation) and isMonkVocId(var_351_8)

		if var_351_7 and helperConfig.vocation and not var_351_9 then
			modules.game_textmessage.displayFailureMessage(tr("Helper: the loaded configuration belongs to a different vocation."))
		end

		if var_351_3 and var_351_0 then
			saveSettings()
		end

		return true
	end
end

function onExerciseTrainingMessage(arg_353_0, arg_353_1)
	if not arg_353_1 then
		return
	end

	local var_353_0 = arg_353_1:lower()

	if var_353_0:find("you have started training on an exercise dummy", 1, true) or var_353_0:find("you are already training", 1, true) or var_353_0:find("automatically continuing training with next exercise weapon", 1, true) then
		var_0_68()

		return
	end

	if var_353_0:find("you have stopped training", 1, true) or var_353_0:find("training has stopped", 1, true) or var_353_0:find("your training weapon has disappeared", 1, true) or var_353_0:find("you need the training weapon in the backpack", 1, true) or var_353_0:find("the selected item is not a training weapon", 1, true) then
		var_0_69()

		return
	end

	if var_353_0:find("you cannot use this object", 1, true) then
		var_0_66(g_clock.millis())

		return
	end

	if var_353_0:find("get closer to the dummy", 1, true) or var_353_0:find("you must be inside the house to use this dummy", 1, true) or var_353_0:find("that exercise dummy is busy", 1, true) then
		var_0_66(g_clock.millis())

		return
	end

	if var_353_0:find("you need to be in a protection zone", 1, true) or var_353_0:find("this exercise dummy can only be used after", 1, true) then
		var_0_65()
	end
end

function onHelperPositionChange(arg_354_0)
	if arg_354_0 and arg_354_0.isLocalPlayer and not arg_354_0:isLocalPlayer() then
		return
	end

	if not var_0_0 then
		return
	end

	local var_354_0 = var_0_0:isInProtectionZone()

	if not var_0_48 and var_354_0 then
		local var_354_1 = enableButtons and enableButtons:recursiveGetChildById("enableMagicShooter")

		if var_354_1 and var_354_1:isChecked() then
			var_354_1:setChecked(false)
		elseif helperConfig.magicShooterEnabled then
			helperConfig.magicShooterEnabled = false
		end

		local var_354_2 = enableButtons and enableButtons:recursiveGetChildById("enableAutoTarget")

		if var_354_2 and var_354_2:isChecked() then
			var_354_2:setChecked(false)
		elseif helperConfig.autoTargetEnabled then
			helperConfig.autoTargetEnabled = false
		end
	end

	if var_0_48 and not var_354_0 then
		local var_354_3 = var_0_2 and var_0_2:recursiveGetChildById("autoTrainingCheck")

		if var_354_3 and var_354_3:isChecked() then
			var_354_3:setChecked(false)
		elseif var_0_29.active then
			var_0_69()
		end
	end

	var_0_48 = var_354_0
end

function checkExerciseEvent()
	if not var_0_10 then
		return
	end

	local var_355_0 = g_clock.millis()

	if var_0_29.active then
		return
	end

	if var_355_0 < var_0_29.pendingUntil then
		return
	end

	if var_0_29.pendingUntil > 0 then
		var_0_66(var_355_0)
	end

	if not var_0_0:isInProtectionZone() then
		return
	end

	local var_355_1 = var_0_2:recursiveGetChildById("autoTrainingCheck")

	if not var_355_1:isChecked() then
		return
	end

	local var_355_2 = var_0_91()

	if not var_355_2.enabled then
		return
	end

	local var_355_3 = var_355_2.id
	local var_355_4 = var_0_2:recursiveGetChildById("autoTrainingItem")
	local var_355_5 = var_355_4 and var_355_4.potionItem

	if var_355_3 <= 0 and var_355_5 then
		var_355_3 = var_355_5:getItemId()
		var_355_2.id = var_355_3
	end

	if var_355_3 <= 0 then
		return var_355_1:setChecked(false)
	end

	if var_355_0 < var_0_29.nextAttemptAt then
		return
	end

	if var_0_0:getInventoryCount(var_355_3) == 0 then
		local var_355_6 = var_0_90(var_355_3)

		if not var_355_6 then
			var_0_64()

			return var_355_1:setChecked(false)
		end

		var_355_3 = var_355_6
		var_355_2.id = var_355_6

		var_0_92(var_355_6)
	end

	local var_355_7, var_355_8 = getExerciseDummy(var_355_3)

	if not var_355_7 then
		if var_0_29.searchStartedAt == 0 then
			var_0_29.searchStartedAt = var_355_0
		elseif var_355_0 - var_0_29.searchStartedAt >= var_0_33 then
			modules.game_textmessage.displayFailureMessage(tr("Auto-training stopped: no exercise dummy reachable."))
			var_0_64()
			var_355_1:setChecked(false)
		end

		return
	end

	var_0_29.searchStartedAt = 0

	local var_355_9 = var_0_89(var_355_3)

	if var_355_9 then
		g_game.useWith(var_355_9, var_355_7)
	else
		g_game.useInventoryItemWith(var_355_3, var_355_7)
	end

	if var_355_8 then
		var_0_29.lastAttemptTargetKey = var_355_8.key
		var_0_29.lastAttemptTargetPos = var_355_8.position
	else
		var_0_29.lastAttemptTargetKey = var_0_63(var_355_7:getPosition())
		var_0_29.lastAttemptTargetPos = var_355_7:getPosition()
	end

	var_0_29.pendingUntil = var_355_0 + var_0_30
	var_0_29.nextAttemptAt = var_355_0 + var_0_31
end

function getExerciseDummy(arg_356_0)
	local var_356_0 = var_0_0:getPosition()
	local var_356_1, var_356_2 = var_0_88(arg_356_0)
	local var_356_3 = math.min(var_356_1, var_0_34)
	local var_356_4 = math.min(var_356_2, var_0_34)
	local var_356_5 = g_clock.millis()
	local var_356_6 = {}
	local var_356_7 = g_map.getTiles(var_356_0.z)

	for iter_356_0, iter_356_1 in pairs(var_356_7) do
		local var_356_8 = iter_356_1:getPosition()

		if var_356_8.z == var_356_0.z and var_356_3 >= math.abs(var_356_0.x - var_356_8.x) and var_356_4 >= math.abs(var_356_0.y - var_356_8.y) and g_map.isSightClear(var_356_0, var_356_8) then
			local var_356_9 = var_0_95(iter_356_1)

			if var_356_9 and var_0_86[var_356_9:getId()] then
				local var_356_10 = var_0_63(var_356_8)

				var_356_6[#var_356_6 + 1] = {
					position = var_356_8,
					key = var_356_10,
					item = var_356_9,
					cooldownUntil = var_0_29.targetCooldowns[var_356_10] or 0
				}
			end
		end
	end

	table.sort(var_356_6, function(arg_357_0, arg_357_1)
		return var_0_74(var_356_0, arg_357_0.position) < var_0_74(var_356_0, arg_357_1.position)
	end)

	for iter_356_2, iter_356_3 in ipairs(var_356_6) do
		if var_356_5 >= iter_356_3.cooldownUntil then
			return iter_356_3.item, iter_356_3
		end
	end

	return nil
end

var_0_28.checkExerciseEvent.action = checkExerciseEvent

function toggleExerciseTraining(arg_358_0)
	local var_358_0 = var_0_91()

	var_358_0.enabled = arg_358_0 == true

	if not var_358_0.enabled then
		var_0_64()

		return
	end

	checkExerciseEvent()
end

function assignExerciseEvent(arg_359_0)
	g_mouse.updateGrabber(var_0_4, "target")
	var_0_4:grabMouse()
	var_0_5:hide()
	g_mouse.pushCursor("target")

	function var_0_4.onMouseRelease(arg_360_0, arg_360_1, arg_360_2)
		onAssignExercise(arg_360_0, arg_360_1, arg_360_2, arg_359_0)
	end
end

function onAssignExercise(arg_361_0, arg_361_1, arg_361_2, arg_361_3)
	g_mouse.updateGrabber(var_0_4, "target")
	var_0_4:ungrabMouse()
	g_mouse.popCursor("target")

	var_0_4.onMouseRelease = nil

	var_0_5:show()

	local var_361_0 = g_ui.getRootWidget()

	if not var_361_0 then
		return true
	end

	local var_361_1 = var_361_0:recursiveGetChildByPos(arg_361_1, false)

	if not var_361_1 then
		return true
	end

	local var_361_2 = 0

	if var_361_1:getClassName() == "UIItem" and not var_361_1:isVirtual() then
		local var_361_3 = var_361_1:getItem()

		if var_361_3 then
			var_361_2 = var_361_3:getId()
		end
	end

	if table.find(var_0_85, var_361_2) then
		var_0_91().id = var_361_2

		var_0_92(var_361_2)
		saveSettings()
	else
		modules.game_textmessage.displayFailureMessage(tr("Invalid exercise!"))
	end
end

function assignFoodEvent(arg_362_0)
	g_mouse.updateGrabber(var_0_4, "target")
	var_0_4:grabMouse()
	var_0_5:hide()
	g_mouse.pushCursor("target")

	function var_0_4.onMouseRelease(arg_363_0, arg_363_1, arg_363_2)
		onAssignFood(arg_363_0, arg_363_1, arg_363_2, arg_362_0)
	end
end

function onAssignFood(arg_364_0, arg_364_1, arg_364_2, arg_364_3)
	g_mouse.updateGrabber(var_0_4, "target")
	var_0_4:ungrabMouse()
	g_mouse.popCursor("target")

	var_0_4.onMouseRelease = nil

	var_0_5:show()

	local var_364_0 = g_ui.getRootWidget()

	if not var_364_0 then
		return true
	end

	local var_364_1 = var_364_0:recursiveGetChildByPos(arg_364_1, false)

	if not var_364_1 then
		return true
	end

	local var_364_2 = 0

	if var_364_1:getClassName() == "UIItem" and not var_364_1:isVirtual() then
		local var_364_3 = var_364_1:getItem()

		if var_364_3 then
			var_364_2 = var_364_3:getId()
		end
	end

	if var_0_81[var_364_2] then
		var_0_93().id = var_364_2

		var_0_94(var_364_2)
		saveSettings()
	else
		modules.game_textmessage.displayFailureMessage(tr("Invalid food!"))
	end
end

function onCheckPotionPriority(arg_365_0)
	local var_365_0 = tonumber(arg_365_0:getId():match("%d+"))

	if helperConfig.potions[var_365_0 + 1].priority == 0 then
		return true
	end

	if arg_365_0.actionId == 1 then
		arg_365_0.actionId = 2

		arg_365_0:setImageSource("/images/skin/show-gui-help-blue")
		arg_365_0:setTooltip("This potion is healing mana...")

		helperConfig.potions[var_365_0 + 1].priority = 2
	else
		arg_365_0.actionId = 1

		arg_365_0:setImageSource("/images/skin/show-gui-help-red")
		arg_365_0:setTooltip("This potion is healing health...")

		helperConfig.potions[var_365_0 + 1].priority = 1
	end

	invalidateHelperCache()
end

function updateTrackerDisplay()
	local var_366_0 = var_0_6:recursiveGetChildById("helperStatus")

	if var_366_0 then
		if var_0_10 then
			var_366_0:setText("Active")
			var_366_0:setColor("#44ad25")
		else
			var_366_0:setText("Inactive")
			var_366_0:setColor("#D33C3C")
		end
	end

	local var_366_1 = var_0_6:recursiveGetChildById("shooterStatus")

	if var_366_1 then
		var_366_1:setText(helperConfig.magicShooterEnabled and "Active" or "Inactive")
		var_366_1:setColor(helperConfig.magicShooterEnabled and "#44ad25" or "#D33C3C")
	end

	local var_366_2 = var_0_6:recursiveGetChildById("targetStatus")

	if var_366_2 then
		var_366_2:setText(helperConfig.autoTargetEnabled and "Active" or "Inactive")
		var_366_2:setColor(helperConfig.autoTargetEnabled and "#44ad25" or "#D33C3C")
	end

	local var_366_3 = var_0_6:recursiveGetChildById("currentPresetName")

	if var_366_3 then
		var_366_3:setText(helperConfig.selectedShooterProfile)
	end
end

function botStatus()
	local var_367_0 = var_0_5.contentPanel:recursiveGetChildById("helperStatus")
	local var_367_1 = var_0_5.contentPanel:recursiveGetChildById("helperStatusLabel")
	local var_367_2 = var_0_6:recursiveGetChildById("helperStatus")

	var_0_10 = not var_0_10

	if var_0_72 then
		print(string.format("[HelperDbg] botStatus(): hotkeyHelperStatus -> %s", tostring(var_0_10)))
	end

	if var_0_10 then
		var_367_0:setImageSource("/images/store/icon-yes")
		var_367_1:setText("Enabled")
		var_367_2:setText("Active")
		var_367_2:setColor("#44ad25")
		var_367_0:setTooltip(" - Helper Status: Enabled\n\nYou can Enable or Disable the helper using\nthe default hotkey (Pause Break).\n\nAlso you can change the hotkey on settings.")
		modules.game_textmessage.displayFailureMessage(tr("Helper Status: Enabled"))
	else
		var_367_0:setImageSource("/images/store/icon-no")
		var_367_2:setText("Inactive")
		var_367_1:setText("Disabled")
		var_367_2:setColor("#D33C3C")
		var_367_0:setTooltip(" - Helper Status: Disabled\n\nYou can Enable or Disable the helper using\nthe default hotkey (Pause Break).\n\nAlso you can change the hotkey on settings.")
		modules.game_textmessage.displayFailureMessage(tr("Helper Status: Disabled"))
	end

	if not var_0_6.clickHandlersSetup then
		if var_367_2 then
			function var_367_2.onClick()
				botStatus()
			end

			var_367_2:setTooltip("Click to toggle Helper status")
		end

		local var_367_3 = var_0_6:recursiveGetChildById("shooterStatus")

		if var_367_3 then
			function var_367_3.onClick()
				local var_369_0 = shooterPanel:recursiveGetChildById("enableMagicShooter")

				if var_369_0 then
					var_369_0:setChecked(not var_369_0:isChecked())
					toggleMagicShooter(var_369_0)
				end
			end

			var_367_3:setTooltip("Click to toggle TyronCaster")
		end

		local var_367_4 = var_0_6:recursiveGetChildById("targetStatus")

		if var_367_4 then
			function var_367_4.onClick()
				local var_370_0 = shooterPanel:recursiveGetChildById("enableAutoTarget")

				if var_370_0 then
					var_370_0:setChecked(not var_370_0:isChecked())
					toggleAutoTarget(var_370_0)
				end
			end

			var_367_4:setTooltip("Click to toggle Auto Target")
		end

		local var_367_5 = var_0_6:recursiveGetChildById("currentPresetName")

		if var_367_5 then
			function var_367_5.onClick()
				toggleShooterPreset()
			end

			var_367_5:setTooltip("Click to cycle through shooter presets")
		end

		var_0_6.clickHandlersSetup = true
	end

	local var_367_6 = var_0_6:recursiveGetChildById("shooterStatus")

	if var_367_6 then
		var_367_6:setText(helperConfig.magicShooterEnabled and "Active" or "Inactive")
		var_367_6:setColor(helperConfig.magicShooterEnabled and "#44ad25" or "#D33C3C")
	end

	local var_367_7 = var_0_6:recursiveGetChildById("targetStatus")

	if var_367_7 then
		var_367_7:setText(helperConfig.autoTargetEnabled and "Active" or "Inactive")
		var_367_7:setColor(helperConfig.autoTargetEnabled and "#44ad25" or "#D33C3C")
	end

	local var_367_8 = var_0_6:recursiveGetChildById("currentPresetName")

	if var_367_8 then
		var_367_8:setText(helperConfig.selectedShooterProfile)
		var_367_8:setTooltip("Click to cycle through shooter presets")
	end
end

function toggleNextWindow()
	local var_372_0 = {
		"healingMenu",
		"toolsMenu",
		"shooterMenu"
	}
	local var_372_1

	for iter_372_0, iter_372_1 in ipairs(var_372_0) do
		if iter_372_1 == menuId then
			var_372_1 = iter_372_0

			break
		end
	end

	var_372_1 = var_372_1 or 1
	menuId = var_372_0[var_372_1 == #var_372_0 and 1 or var_372_1 + 1]

	loadMenu(menuId)
end

function manageHotkeys(arg_373_0)
	var_0_5:hide()

	local var_373_0 = g_ui.createWidget("ActionAssignWindow", rootWidget)

	var_373_0:setText(arg_373_0)
	var_373_0:grabKeyboard()

	local var_373_1 = Keybind.getKeybindKeys("Helper", arg_373_0)
	local var_373_2 = var_373_1 and var_373_1.primary and tostring(var_373_1.primary) or ""
	local var_373_3 = Keybind.chatMode == CHAT_MODE.ON and "Chat On" or "Chat Off"

	var_373_0.chatMode:setText("Mode: \"" .. var_373_3 .. "\"")
	var_373_0.display:setText(var_373_2)
	var_373_0.desc:setText("Assign or edit a hotkey for: " .. arg_373_0)
	var_373_0:setHeight(190)

	function var_373_0.onKeyDown(arg_374_0, arg_374_1, arg_374_2)
		local var_374_0 = determineKeyComboDesc(arg_374_1, arg_374_2)
		local var_374_1 = {
			"Shift",
			"Ctrl",
			"Alt"
		}

		if table.contains(var_374_1, var_374_0) then
			arg_374_0.display:setText("")
			arg_374_0.warning:setVisible(false)
			arg_374_0.buttonOk:setEnabled(true)

			return true
		end

		arg_374_0.display:setText(var_374_0)
		arg_374_0.warning:setVisible(false)
		arg_374_0.buttonOk:setEnabled(true)

		if Keybind.isKeyComboUsed(var_374_0, "Helper", arg_373_0) then
			arg_374_0.warning:setVisible(true)
			arg_374_0.warning:setText("This hotkey is already in use and will be overwritten.")
		end

		return true
	end

	function var_373_0.buttonOk.onClick()
		local var_375_0 = tostring(var_373_0.display:getText())

		if #var_375_0 == 0 then
			Keybind.setPrimaryActionKey("Helper", arg_373_0, Keybind.currentPreset, "", Keybind.chatMode)
			var_373_0:destroy()

			return true
		end

		Keybind.setPrimaryActionKey("Helper", arg_373_0, Keybind.currentPreset, var_375_0, Keybind.chatMode)
		var_373_0:destroy()
	end

	function var_373_0.buttonClear.onClick()
		Keybind.setPrimaryActionKey("Helper", arg_373_0, Keybind.currentPreset, "", Keybind.chatMode)
		var_373_0:destroy()
	end

	function var_373_0.onDestroy(arg_377_0)
		var_0_5:show(true)
	end
end

function onDropSpell(arg_378_0, arg_378_1)
	local var_378_0 = Spells.getSpellByWords(arg_378_1)

	if not var_378_0 then
		return
	end

	local var_378_1 = string.match(arg_378_0:getId(), "^spellButton%d*")
	local var_378_2 = string.match(arg_378_0:getId(), "^spellTrainingButton")
	local var_378_3 = string.match(arg_378_0:getId(), "^hasteButton")
	local var_378_4 = string.match(arg_378_0:getId(), "^attackSpellButton%d*")
	local var_378_5 = getShooterProfile()

	if var_378_1 then
		onSetupDropSpell(arg_378_0, var_378_0, {
			2
		}, helperConfig.spells)
	elseif var_378_2 or var_378_3 then
		onSetupDropSupport(arg_378_0, var_378_0, var_378_3)
	elseif var_378_4 then
		onSetupDropSpell(arg_378_0, var_378_0, {
			1,
			4,
			8
		}, var_378_5.spells)
	end
end

function onSetupDropSpell(arg_379_0, arg_379_1, arg_379_2, arg_379_3)
	local var_379_0 = Spells.getGroupIds(arg_379_1)

	local function var_379_1(arg_380_0, arg_380_1)
		for iter_380_0, iter_380_1 in ipairs(arg_380_1) do
			if table.contains(arg_380_0, iter_380_1) then
				return true
			end
		end

		return false
	end

	local var_379_2 = getPlayerVocation()
	local var_379_3 = getShooterProfile()

	if var_379_1(var_379_0, arg_379_2) and table.contains(arg_379_1.vocations, var_379_2) and not var_0_98[arg_379_1.id] then
		local var_379_4 = SpelllistSettings.Default.iconFile
		local var_379_5 = Spells.getImageClip(arg_379_1.clientId, "Default")
		local var_379_6 = Spells.getSpellByClientId(arg_379_1.clientId)

		if arg_379_0:getId():find("attackSpellButton") then
			local var_379_7 = tonumber(arg_379_0:getId():match("%d+"))
			local var_379_8 = isAreaSpellData(arg_379_1)

			if isAoeSpellSlot(var_379_7) and not var_379_8 then
				modules.game_textmessage.displayFailureMessage(tr("This slot only accepts area/wave/beam spells."))

				return
			elseif not isAoeSpellSlot(var_379_7) and var_379_8 then
				modules.game_textmessage.displayFailureMessage(tr("This slot only accepts single-target spells."))

				return
			end
		end

		arg_379_0:setImageSource(var_379_4)
		arg_379_0:setImageClip(var_379_5)
		arg_379_0:setBorderColorTop("#1b1b1b")
		arg_379_0:setBorderColorLeft("#1b1b1b")
		arg_379_0:setBorderColorRight("#757575")
		arg_379_0:setBorderColorBottom("#757575")
		arg_379_0:setBorderWidth(1)
		arg_379_0:setTooltip("Spell: " .. arg_379_1.name .. "\nWords: " .. arg_379_1.words)

		local var_379_9 = tonumber(arg_379_0:getId():match("%d+"))

		if arg_379_0:getId():find("attackSpellButton") then
			var_379_3.spells[var_379_9 + 1].id = tonumber(arg_379_1.id)
		else
			arg_379_3[var_379_9 + 1].id = tonumber(arg_379_1.id)
		end

		if arg_379_0:getId():find("attackSpellButton") then
			local var_379_10 = shooterPanel:recursiveGetChildById("countMinCreature" .. var_379_9)
			local var_379_11 = shooterPanel:recursiveGetChildById("conditionSetting" .. var_379_9)
			local var_379_12 = shooterPanel:recursiveGetChildById("selfCast" .. var_379_9)

			if table.contains(var_0_97, var_379_6.id) and not var_379_12 then
				var_379_12 = g_ui.createWidget("Button", arg_379_0)

				local var_379_13 = {
					width = 12,
					height = 12,
					font = "Verdana Bold-9px-small",
					["anchors.right"] = "parent.right",
					["anchors.bottom"] = "parent.bottom"
				}

				var_379_12:mergeStyle(var_379_13)
				var_379_12:setId("selfCast" .. var_379_9)
				var_379_12:setTooltip("Cast on yourself")
				var_379_12:setVisible(true)
				updateSelfCastModeWidget(var_379_12)

				function var_379_12.onClick()
					local var_379_14 = tonumber(var_379_12:getId():match("%d+"))
					toggleSelfCast(var_379_14, not getShooterProfile().spells[var_379_14 + 1].selfCast)
				end
			end

			if var_379_12 and not table.contains(var_0_97, var_379_6.id) then
				var_379_3.spells[var_379_9 + 1].selfCast = false

				var_379_12:destroy()
			end

			if not var_379_6.area and not table.contains(var_0_97, var_379_6.id) then
				var_379_3.spells[var_379_9 + 1].creatures = 1

				var_379_10:setCurrentOption("1+")
				var_379_10:disable()

				if var_379_11 then
					var_379_11:setChecked(var_379_3.spells[var_379_9 + 1].forceCast)
					var_379_11:setVisible(true)
				end
			else
				var_379_10:enable()

				if isAoeSpellSlot(var_379_9) and var_379_3.spells[var_379_9 + 1].creatures < 2 then
					var_379_3.spells[var_379_9 + 1].creatures = 2

					var_379_10:setCurrentOption("2+")
				end

				if var_379_11 then
					var_379_11:setChecked(false)
					var_379_11:setVisible(false)

					var_379_3.spells[var_379_9 + 1].forceCast = false
				end
			end

			ensureAimCheckbox(var_379_9, var_379_6)
			ensureHarmonyIcons(var_379_9, var_379_6)
		end
	end
end

function onSetupDropSupport(arg_382_0, arg_382_1, arg_382_2)
	local var_382_0 = getPlayerVocation()

	if arg_382_2 and not table.contains(var_0_104[var_382_0], arg_382_1.id) then
		return
	end

	if not arg_382_2 and table.contains(var_0_104[var_382_0], arg_382_1.id) then
		return
	end

	if table.contains(arg_382_1.vocations, var_382_0) and not var_0_102[arg_382_1.id] then
		local var_382_1 = SpelllistSettings.Default.iconFile
		local var_382_2 = Spells.getImageClip(arg_382_1.clientId, "Default")

		arg_382_0:setImageSource(var_382_1)
		arg_382_0:setImageClip(var_382_2)
		arg_382_0:setBorderColorTop("#1b1b1b")
		arg_382_0:setBorderColorLeft("#1b1b1b")
		arg_382_0:setBorderColorRight("#757575")
		arg_382_0:setBorderColorBottom("#757575")
		arg_382_0:setBorderWidth(1)
		arg_382_0:setTooltip("Spell: " .. arg_382_1.name .. "\nWords: " .. arg_382_1.words)

		local var_382_3 = tonumber(arg_382_0:getId():match("%d+"))

		if arg_382_2 then
			helperConfig.haste[1].id = tonumber(arg_382_1.id)
		else
			helperConfig.training[1].id = tonumber(arg_382_1.id)

			if helperConfig.training[1].percent == 0 then
				helperConfig.training[1].percent = 100
			end
		end
	end
end

function onSearchTextChange(arg_383_0)
	local var_383_0 = g_ui.getRootWidget():recursiveGetChildById("assignSpellsWindow")

	if not var_383_0 then
		return
	end

	local var_383_1 = var_383_0:recursiveGetChildById("spellList")

	if not var_383_1 then
		return
	end

	for iter_383_0, iter_383_1 in pairs(var_383_1:getChildren()) do
		if iter_383_1:getText():lower():find(arg_383_0:lower()) or arg_383_0 == "" or #arg_383_0 < 3 then
			iter_383_1:setVisible(true)
		else
			iter_383_1:setVisible(false)
		end
	end
end

function onClearSearchText()
	local var_384_0 = g_ui.getRootWidget():recursiveGetChildById("assignSpellsWindow")

	if not var_384_0 then
		return
	end

	local var_384_1 = var_384_0:recursiveGetChildById("searchText")

	if var_384_1 then
		var_384_1:setText("")
	end
end

function toggleHelperTracker()
	if var_0_6:isVisible() then
		var_0_6:close()
	else
		if not var_0_6:getParent() then
			local var_385_0 = modules.game_interface.findContentPanelAvailable(var_0_6, var_0_6:getMinimumHeight())

			if not var_385_0 then
				return
			end

			var_385_0:addChild(var_0_6)
		end

		var_0_6:open()
	end
end

-- CrystalOTC analyser compatibility.
function toggleHelperStatsWindow()
	toggleHelperTracker()
end

function isHelperStatsWindowOpen()
	return var_0_6 ~= nil and var_0_6:isVisible()
end

function showTerms()
	if helperConfig.terms then
		show()
	else
		createHelperRules()
		var_0_7:show()
		var_0_7:focus()
	end
end

function closeTerms()
	var_0_7:hide()
end

function createHelperRules()
	local var_388_0 = var_0_7:recursiveGetChildById("rules")

	if var_388_0 then
		var_388_0:destroyChildren()

		local var_388_1 = "\n           Extended Terms of Conditions for Helper Services\n\n" .. " These Terms of Service establish the conditions under which D FATO GAMES LTDA provides 'Helper' and 'Additional Services' for the online RPG game 'RubinOT.' This document complements the 'RubinOT Service Agreement,' which all users must accept when creating an account.\n\n" .. "2 - Cheating\n\n" .. "2.H - Automations in Tyron.\n If the player is using the Tyron client and the TyronCaster function to attack monsters and/or cast spells is active, they will undergo a standard check by our team. If the player absence is confirmed, a ban will be applied to the player and their account."
		local var_388_2 = g_ui.createWidget("UILabel", var_388_0)

		var_388_2:setText(var_388_1)
		var_388_2:setColor("#c0c0c0")
		var_388_2:setFont("Verdana Bold-11px")
		var_388_2:setTextWrap(true)
		var_388_2:setTextAutoResize(true)
		var_388_2:setMarginRight(10)
		var_388_2:setMarginLeft(10)
		var_388_2:setBackgroundColor("#414141")
	end
end

function onHelperTermCondition(arg_389_0, arg_389_1)
	var_0_7:recursiveGetChildById("next"):setEnabled(arg_389_1)
end

function onHelperTermConditionNext()
	var_0_7:hide()
	show()

	helperConfig.terms = true
end

function hasAcceptedTerms()
	return helperConfig.terms
end

function move(arg_392_0, arg_392_1, arg_392_2, arg_392_3, arg_392_4)
	var_0_6:setParent(arg_392_0)
	var_0_6:open()
	var_0_6:setHeight(arg_392_1)

	if arg_392_3 then
		var_0_6:minimize()
	end

	if arg_392_4 then
		var_0_6:lock(true)
	end

	return var_0_6
end
