-- chunkname: @/game_taskboard/menus/weekly_task.lua

TaskBoard.WeeklyTask = {}

local WeeklyTask = TaskBoard.WeeklyTask

WeeklyTask.mainWindow = nil
WeeklyTask.isWeeklyTaskActive = false

function WeeklyTask:updateOverlayVisibility()
	local canShowOverlay = self.isWeeklyTaskActive and TaskBoard.mainWindow and TaskBoard.mainWindow:isVisible() and TaskBoard.weeklyPanel and TaskBoard.weeklyPanel:isVisible() and TaskBoard.chainTransparentWeekly and TaskBoard.weeklyProgressPanel

	if canShowOverlay then
		TaskBoard.chainTransparentWeekly:show()
		TaskBoard.weeklyProgressPanel:show()
		TaskBoard.weeklyProgressPanel:raise()
		TaskBoard.weeklyProgressPanel:focus()

		return
	end

	if TaskBoard.weeklyProgressPanel then
		TaskBoard.weeklyProgressPanel:hide()
	end

	if TaskBoard.chainTransparentWeekly then
		TaskBoard.chainTransparentWeekly:hide()
	end
end

local function capitalizeWords(str)
	return (str or ""):gsub("(%a)([%w_']*)", function(first, rest)
		return first:upper() .. rest:lower()
	end)
end

local function getKillSlotsList()
	local weeklyPanel = TaskBoard.weeklyPanel

	if not weeklyPanel then
		return nil
	end

	local killTasks = weeklyPanel:recursiveGetChildById("killTasks")

	if not killTasks then
		return nil
	end

	return killTasks:recursiveGetChildById("killSlotsList")
end

local function getDeliverySlotsList()
	local weeklyPanel = TaskBoard.weeklyPanel

	if not weeklyPanel then
		return nil
	end

	local deliveryTasks = weeklyPanel:recursiveGetChildById("deliveryTasks")

	if not deliveryTasks then
		return nil
	end

	return deliveryTasks:recursiveGetChildById("deliverySlotsList")
end

local function setKillSlotCreature(panel, raceData)
	local outfitIcon = panel:getChildById("outfitIcon")

	if not outfitIcon then
		return
	end

	local anyCreatureIcon = panel:getChildById("anyCreatureIcon")

	if raceData and raceData.outfit and raceData.raceId ~= 0 then
		if anyCreatureIcon then
			anyCreatureIcon:setVisible(false)
		end
		outfitIcon:setOutfit(raceData.outfit)
		outfitIcon:setFixedCreatureSize(true)
		outfitIcon:setVisible(true)

		local c = outfitIcon:getCreature()

		if c then
			c:setStaticWalking(1000)
		end
	else
		outfitIcon:setVisible(false)
		if anyCreatureIcon then
			anyCreatureIcon:setVisible(true)
		end
	end
end

local function fillKillSlot(panel, name, current, target, raceData)
	if not panel then
		return
	end

	local displayName = capitalizeWords(name or "")

	if #displayName > 17 then
		displayName = displayName:sub(1, 17) .. "..."
	end

	panel:setText(displayName)
	setKillSlotCreature(panel, raceData)

	local currentLabel = panel:getChildById("killAnyMonstersLabel")

	if currentLabel then
		currentLabel:setText(TaskBoard:formatNumberWithCommas(current or 0))

		if target <= current then
			currentLabel:setColor("#44cc44")
		else
			currentLabel:setColor("#d33c3c")
		end
	end

	local totalLabel = panel:getChildById("totalKillAnyMonstersLabel")

	if totalLabel then
		totalLabel:setText(TaskBoard:formatNumberWithCommas(target or 0))
	end
end

local function fillDeliverySlot(panel, entry)
	if not panel or not entry then
		return
	end

	local thingType = g_things.getThingType(entry.taskItemId, 0)

	if thingType then
		local itemName = capitalizeWords(thingType:getName() or "")

		if #itemName > 17 then
			itemName = itemName:sub(1, 17) .. "..."
		end

		panel:setText(itemName)
	end

	local itemIcon = panel:getChildById("itemIcon")

	if itemIcon then
		itemIcon:setItemId(entry.taskItemId or 0)
	end

	local currentLabel = panel:getChildById("currentDeliveryLabel")

	if currentLabel then
		currentLabel:setText(TaskBoard:formatNumberWithCommas(entry.count or 0))

		if entry.count >= entry.totalItems then
			currentLabel:setColor("#44ad25")
		else
			currentLabel:setColor("#d33c3c")
		end
	end

	local totalLabel = panel:getChildById("totalDeliveryLabel")

	if totalLabel then
		totalLabel:setText(TaskBoard:formatNumberWithCommas(entry.totalItems or 0))
	end

	local deliverButton = panel:getChildById("deliverButton")

	if deliverButton then
		local taskId = entry.taskId or 0
		local isCompleted = (entry.completed or 0) ~= 0
		local hasItems = (entry.count or 0) > 0

		deliverButton:setEnabled(hasItems and not isCompleted)

		function deliverButton.onClick()
			g_game.sendDeliveryTask(taskId)
		end
	end
end

local WEEKLY_KILL_TRACKER_MAX_SLOTS = 9
local WEEKLY_ANY_CREATURE_ICON = "/modules/game_taskboard/images/icon-arbitrarymonster"
local WEEKLY_CREATURETRACK_NO_CREATURE_IMG = "/images/game/prey/prey-noprey-small"
local WEEKLY_TRACKER_TOOLTIP_FOOTER = "Click in this window to open the Task Board dialog."

local function buildWeeklyTrackerActiveTooltip(creatureName, killed, total)
	local header = string.format("Creature: %s\nAmount: %s / %s", creatureName, TaskBoard:formatNumberWithCommas(killed), TaskBoard:formatNumberWithCommas(total))

	return header .. "\n\n" .. tr(WEEKLY_TRACKER_TOOLTIP_FOOTER)
end

local function refreshBountyKillTrackerIfAvailable()
	local bounty = modules.game_taskboard and modules.game_taskboard.TaskBoard and modules.game_taskboard.TaskBoard.BountyTask

	if bounty and bounty.refreshKillTracker then
		bounty.refreshKillTracker()
	end
end

local function getWeeklyTrackerSlot(slotIndex)
	local prey = modules.game_prey

	if not prey or not prey.preyTracker or prey.preyTracker:isDestroyed() then
		return nil
	end

	local contents = prey.preyTracker.contentsPanel

	if not contents then
		return nil
	end

	return contents:getChildById("wslot" .. slotIndex)
end

local function setWeeklyKillTrackerUnused(slotIndex)
	local slot = getWeeklyTrackerSlot(slotIndex)

	if not slot then
		return
	end

	slot:setVisible(false)

	local creature = slot:getChildById("creature")
	local noCreature = slot:getChildById("noCreature")
	local nameLabel = slot:getChildById("creatureName")
	local timeBar = slot:getChildById("time")

	if creature then
		creature:setVisible(false)
	end

	if noCreature then
		noCreature:setImageSource(WEEKLY_CREATURETRACK_NO_CREATURE_IMG)
		noCreature:setVisible(true)
	end

	if nameLabel then
		nameLabel:setText(tr("Inactive"))
	end

	if timeBar then
		timeBar:setPercent(0)
	end

	slot:setTooltip("")
end

local function setWeeklyTrackerSelected(slotIndex, raceId, monstersKilled, totalKills, isAnyCreature)
	local slot = getWeeklyTrackerSlot(slotIndex)

	if not slot then
		return
	end

	slot:setVisible(true)

	local creature = slot:getChildById("creature")
	local noCreature = slot:getChildById("noCreature")
	local nameLabel = slot:getChildById("creatureName")
	local timeBar = slot:getChildById("time")
	local creatureName = "?"

	if isAnyCreature then
		creatureName = tr("Any Creature")

		if creature then
			creature:setVisible(false)
		end

		if noCreature then
			noCreature:setImageSource(WEEKLY_ANY_CREATURE_ICON)
			noCreature:setImageSize({
				width = 18,
				height = 14
			})
			noCreature:setCenter(true)
			noCreature:setVisible(true)
		end
	else
		local rid = tonumber(raceId) or 0
		local raceData = g_things.getRaceData(rid)

		creatureName = raceData and raceData.raceId ~= 0 and raceData.name or "?"

		if creature then
			if raceData and raceData.outfit then
				creature:setOutfit(raceData.outfit)
				creature:getCreature():setStaticWalking(1000)
				creature:setVisible(true)
			else
				creature:setVisible(false)
			end
		end

		if noCreature then
			noCreature:setImageSource(WEEKLY_CREATURETRACK_NO_CREATURE_IMG)
			noCreature:setVisible(false)
		end
	end

	if nameLabel then
		if isAnyCreature then
			nameLabel:setText(capitalizeWords(creatureName))
		else
			nameLabel:setText(modules.game_prey.formatKillTrackerCreatureName(creatureName))
		end
	end

	local killed = tonumber(monstersKilled) or 0
	local total = tonumber(totalKills) or 0

	if timeBar then
		local percent = 0

		if total > 0 then
			percent = math.min(100, math.floor(killed / total * 100))
		end

		timeBar:setPercent(percent)
	end

	slot:setTooltip(buildWeeklyTrackerActiveTooltip(capitalizeWords(creatureName), killed, total))
end

local function layoutWeeklyKillTrackerSlots(usedCount)
	for i = 1, WEEKLY_KILL_TRACKER_MAX_SLOTS do
		if usedCount < i then
			setWeeklyKillTrackerUnused(i)
		end
	end
end

local function buildKillSlots(weeklyTasks)
	local killSlotsList = getKillSlotsList()

	if not killSlotsList then
		return
	end

	local killEntries = weeklyTasks.killEntries or {}

	if #killEntries == 0 then
		killSlotsList:updateLayout()
		layoutWeeklyKillTrackerSlots(0)

		if modules.game_prey and modules.game_prey.updateTrackerHeight then
			modules.game_prey.updateTrackerHeight()
		end

		refreshBountyKillTrackerIfAvailable()

		return
	end

	killSlotsList:destroyChildren()

	local ok, anyPanel = pcall(g_ui.createWidget, "KillSlots", killSlotsList)

	if not ok then
		print("[WeeklyTask] error creating KillSlots (Any Creature):", tostring(anyPanel))

		return
	end

	fillKillSlot(anyPanel, "Any Creature", weeklyTasks.killedsAnyMonsters, weeklyTasks.killsAnyMonsters, nil)
	setWeeklyTrackerSelected(1, nil, weeklyTasks.killedsAnyMonsters, weeklyTasks.killsAnyMonsters, true)

	local unlockKillButton = killSlotsList:getParent():getChildById("unlockKillButton")

	if unlockKillButton then
		if #killEntries > 5 then
			unlockKillButton:setVisible(false)
		else
			unlockKillButton:setVisible(true)
		end
	end

	local maxSpeciesSlots = WEEKLY_KILL_TRACKER_MAX_SLOTS - 1

	for slotIndex, entry in ipairs(killEntries) do
		local ok2, panel = pcall(g_ui.createWidget, "KillSlots", killSlotsList)

		if not ok2 then
			print("[WeeklyTask] error creating KillSlots:", tostring(panel))

			break
		end

		local rid = tonumber(entry.raceId) or 0
		local raceData = g_things.getRaceData(rid)
		local raceName = raceData and raceData.raceId ~= 0 and raceData.name or "?"

		fillKillSlot(panel, raceName, entry.totalMonsterKilleds, entry.totalKills, raceData)

		if slotIndex <= maxSpeciesSlots then
			setWeeklyTrackerSelected(slotIndex + 1, rid, entry.totalMonsterKilleds, entry.totalKills, false)
		end
	end

	local usedTrackerSlots = math.min(1 + #killEntries, WEEKLY_KILL_TRACKER_MAX_SLOTS)

	layoutWeeklyKillTrackerSlots(usedTrackerSlots)
	killSlotsList:updateLayout()

	if modules.game_prey and modules.game_prey.updateTrackerHeight then
		modules.game_prey.updateTrackerHeight()
	end

	refreshBountyKillTrackerIfAvailable()
end

local function buildDeliverySlots(weeklyTasks)
	local deliverySlotsList = getDeliverySlotsList()

	if not deliverySlotsList then
		return
	end

	deliverySlotsList:destroyChildren()

	local unlockDeliveryButton = deliverySlotsList:getParent():getChildById("unlockDeliveryButton")

	if unlockDeliveryButton then
		if #weeklyTasks.deliveryEntries > 6 then
			unlockDeliveryButton:setVisible(false)
		else
			unlockDeliveryButton:setVisible(true)
		end
	end

	if weeklyTasks.deliveryEntries then
		for _, entry in ipairs(weeklyTasks.deliveryEntries) do
			local ok, panel = pcall(g_ui.createWidget, "DeliverySlots", deliverySlotsList)

			if not ok then
				print("[WeeklyTask] error creating DeliverySlots:", tostring(panel))

				break
			end

			fillDeliverySlot(panel, entry)
		end
	end

	deliverySlotsList:updateLayout()
end

local PROGRESS_BAR_INNER_WIDTH = 577
local PROGRESS_BAR_TOTAL_TASKS = 18
local PROGRESS_BAR_FILL_IMAGE = "/images/bars/progressbar-green-large"
local STORE_WEEKLY_OFFER_NAME = "Permanent Weekly Task Expansion"

local function openWeeklyTaskStoreOffer()
	local store = modules and modules.game_store

	if not store or not store.openWeeklyTaskExpansion then
		return
	end

	if TaskBoard and TaskBoard.mainWindow and TaskBoard.mainWindow:isVisible() then
		TaskBoard:toggleWindow()
	end

	store.openWeeklyTaskExpansion()
end

local function wireUnlockButton(button)
	if not button then
		return
	end

	button:setTooltip(tr("Open Store: %s", STORE_WEEKLY_OFFER_NAME))

	function button.onClick()
		openWeeklyTaskStoreOffer()
	end
end

local DIFFICULTY_BUTTON_TOOLTIPS = {
	[0] = tr("Beginner tasks include easy creatures."),
	tr("Adept tasks include easy and medium creatures. (Requires level 30)"),
	tr("Expert tasks include up to hard creatures. (Requires level 150)"),
	(tr("Master tasks include the hardest creatures. (Requires level 400)"))
}

local function wireDifficultyButton(button, difficulty)
	if not button then
		return
	end

	button:setTooltip(DIFFICULTY_BUTTON_TOOLTIPS[difficulty])

	function button.onClick()
		g_game.sendSelectDifficultyWeeklyTasks(difficulty)
	end
end

local function buildBarProgress(weeklyTasks)
	if not TaskBoard.weeklyPanel then
		return
	end

	local progressBar = TaskBoard.weeklyPanel:recursiveGetChildById("progressBar")

	if not progressBar then
		return
	end

	local totalKills = weeklyTasks.kill or 0
	local totalDeliveries = weeklyTasks.delivery or 0
	local total = math.max(0, math.min(totalKills + totalDeliveries, PROGRESS_BAR_TOTAL_TASKS))
	local fillWidth = math.floor(total / PROGRESS_BAR_TOTAL_TASKS * PROGRESS_BAR_INNER_WIDTH + 0.5)
	local fill = progressBar:getChildById("progressFill")

	if not fill then
		fill = g_ui.createWidget("UIWidget", progressBar)

		fill:setId("progressFill")
		fill:setPhantom(true)
		fill:setImageSource(PROGRESS_BAR_FILL_IMAGE)
		fill:setImageRepeated(true)
		fill:addAnchor(AnchorTop, "parent", AnchorTop)
		fill:addAnchor(AnchorLeft, "parent", AnchorLeft)
		fill:addAnchor(AnchorBottom, "parent", AnchorBottom)
		fill:setMarginTop(1)
		fill:setMarginBottom(1)
		fill:setMarginLeft(1)
	end

	fill:setVisible(fillWidth > 0)
	fill:setWidth(fillWidth)
	progressBar:setTooltip(tr("Weekly Progress: %d / %d tasks", total, PROGRESS_BAR_TOTAL_TASKS))
end

local function buildRewards(weeklyTasks)
	local huntingPoints = weeklyTasks.totalPoints or 0
	local soulSealsPoints = weeklyTasks.totalTasksCompleted or 0

	if TaskBoard.weeklyPanel then
		local huntingPointsLabel = TaskBoard.weeklyPanel:recursiveGetChildById("huntingPointsLabel")

		if huntingPointsLabel then
			huntingPointsLabel:setText(huntingPoints)
		end

		local soulSealsPointsLabel = TaskBoard.weeklyPanel:recursiveGetChildById("soulSealsPointsLabel")

		if soulSealsPointsLabel then
			soulSealsPointsLabel:setText(soulSealsPoints)
		end
	end

	local timeStamp = weeklyTasks.mondayTime or 0
	local daysRemainingLabel = TaskBoard.weeklyPanel and TaskBoard.weeklyPanel:recursiveGetChildById("daysRemaining")

	if daysRemainingLabel and timeStamp > 0 then
		local currentTime = os.time()
		local diffSeconds = timeStamp - currentTime
		local daysRemaining = math.floor(diffSeconds / 86400)

		if daysRemaining < 0 then
			daysRemaining = 0
		end

		daysRemainingLabel:setText(daysRemaining)
	end
end

function WeeklyTask:allowDifficultyWeeklyTasks(unlockedDifficulties)
	local panel = TaskBoard.weeklyProgressPanel

	if not panel then
		return
	end

	local unlocked = tonumber(unlockedDifficulties) or 0

	if unlocked < 0 then
		unlocked = 0
	elseif unlocked > 3 then
		unlocked = 3
	end

	local buttons = {
		{
			tier = 0,
			id = "beginnerButton"
		},
		{
			tier = 1,
			id = "adeptButton"
		},
		{
			tier = 2,
			id = "expertButton"
		},
		{
			tier = 3,
			id = "masterButton"
		}
	}

	for _, entry in ipairs(buttons) do
		local btn = panel:recursiveGetChildById(entry.id)

		if btn and btn.setEnabled then
			btn:setEnabled(unlocked >= entry.tier)
		end
	end

	if type(g_ui.updateHoveredWidget) == "function" then
		g_ui.updateHoveredWidget(true)
	end
end

function onWeeklyTasks(weeklyTasks)
	if type(weeklyTasks) ~= "table" then
		return
	end

	buildKillSlots(weeklyTasks)
	buildDeliverySlots(weeklyTasks)
	buildBarProgress(weeklyTasks)
	buildRewards(weeklyTasks)

	WeeklyTask.isWeeklyTaskActive = weeklyTasks.weeklyTaskActive == 1

	WeeklyTask:updateOverlayVisibility()
	WeeklyTask:allowDifficultyWeeklyTasks(weeklyTasks.unlockedDifficulties)
end

-- ADAPTER for our engine: onWeeklyTaskData passes THREE separate structures
-- (header, monsters, items) and uses different field names than the module. We assemble them into
-- the single table that onWeeklyTasks expects.
function onEngineWeeklyTaskData(header, monsters, items)
	header = header or {}

	local killEntries = {}
	local killsAnyMonsters = 0
	local killedsAnyMonsters = 0

	for _, m in ipairs(monsters or {}) do
		if m.raceId == 0 then
			-- the engine prepends a synthetic "any monsters" entry with raceId = 0
			killsAnyMonsters = m.total
			killedsAnyMonsters = m.current
		else
			killEntries[#killEntries + 1] = {
				raceId = m.raceId,
				totalMonsterKilleds = m.current,
				totalKills = m.total,
				state = m.state
			}
		end
	end

	local deliveryEntries = {}

	for _, it in ipairs(items or {}) do
		deliveryEntries[#deliveryEntries + 1] = {
			taskId = it.slotIndex,
			taskItemId = it.itemId,
			count = it.current,
			totalItems = it.total,
			completed = it.claimed,
			state = it.state
		}
	end

	onWeeklyTasks({
		killEntries = killEntries,
		deliveryEntries = deliveryEntries,
		killsAnyMonsters = killsAnyMonsters,
		killedsAnyMonsters = killedsAnyMonsters,
		kill = header.completedKillTasks,
		delivery = header.completedDeliveryTasks,
		totalPoints = header.pointsEarned,
		totalTasksCompleted = header.soulsealsEarned,
		mondayTime = header.resetTimestamp,
		weeklyTaskActive = header.weeklyProgressFinished,
		-- the engine reports 1-4, the module counts 0-3
		unlockedDifficulties = math.max(0, (header.unlockedDifficulty or 1) - 1)
	})
end

function WeeklyTask:init()
	connect(g_game, {
		onWeeklyTasks = onWeeklyTasks,
		onWeeklyTaskData = onEngineWeeklyTaskData
	})

	if TaskBoard.weeklyPanel then
		wireUnlockButton(TaskBoard.weeklyPanel:recursiveGetChildById("unlockKillButton"))
		wireUnlockButton(TaskBoard.weeklyPanel:recursiveGetChildById("unlockDeliveryButton"))
	end

	if TaskBoard.weeklyProgressPanel then
		wireDifficultyButton(TaskBoard.weeklyProgressPanel:recursiveGetChildById("beginnerButton"), 0)
		wireDifficultyButton(TaskBoard.weeklyProgressPanel:recursiveGetChildById("adeptButton"), 1)
		wireDifficultyButton(TaskBoard.weeklyProgressPanel:recursiveGetChildById("expertButton"), 2)
		wireDifficultyButton(TaskBoard.weeklyProgressPanel:recursiveGetChildById("masterButton"), 3)
	end
end

function WeeklyTask:terminate()
	disconnect(g_game, {
		onWeeklyTasks = onWeeklyTasks,
		onWeeklyTaskData = onEngineWeeklyTaskData
	})
end
