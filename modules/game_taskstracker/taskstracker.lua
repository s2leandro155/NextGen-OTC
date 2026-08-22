TaskSystemTrackerWindow = nil
TaskSystemTrackerButton = nil

init = function()
	TaskSystemTrackerWindow = g_ui.loadUI("taskstracker", modules.game_interface.getRightPanel())

	TaskSystemTrackerWindow:constructEnviorementVariables()
	TaskSystemTrackerWindow.lockButton:hide()

	TaskSystemTrackerButton = modules.game_mainpanel.addToggleButton(26, "TaskSystemTrackerButton", "Task tracker window", "/images/options/button_task_tracker", toggle, false, function ()
		return modules.client_options.getGeneralsaveIdHotkey("windowsShowHideTaskTracker")
	end)

	TaskSystemTrackerButton:setOn(true)
	TaskSystemTrackerWindow:setup()

	TaskSystemTrackerWindow.menuButton.onMousePress = openMenu

	if g_game.isOnline() then
		onGameStart()
	end

	connect(g_game, {
		onModuleFeature = nil,
		onTaskTracker = nil,
		onGameStart = nil,
		onGameStart = onGameStart,
		onTaskTracker = onTaskTracker,
		onModuleFeature = onModuleFeature
	})
end

terminate = function()
	disconnect(g_game, {
		onModuleFeature = nil,
		onTaskTracker = nil,
		onGameStart = nil,
		onGameStart = onGameStart,
		onTaskTracker = onTaskTracker,
		onModuleFeature = onModuleFeature
	})
	TaskSystemTrackerWindow:destroy()
	TaskSystemTrackerButton:destroy()

	TaskSystemTrackerWindow = nil
	TaskSystemTrackerButton = nil
end

onModuleFeature = function(slot0, slot1)
	if slot0 ~= GameFeatureModules.GameModuleTasksTracker then
		return
	end

	TaskSystemTrackerButton:setVisible(slot1)
end

onGameStart = function()
	slot0 = g_stats.startEvent("[LUA] tasktracker.lua:42")

	if g_settings.getNode("TaskTracker") == nil then
		slot1 = {}
	end

	if slot1[g_game.getCharacterName()] == nil then
		slot2 = {}
	end

	slot3 = TaskSystemTrackerWindow
	slot4 = slot2.sortingType

	if not slot0 then
		slot4 = "name"
	end

	slot3.sortingType = slot4
	slot3 = TaskSystemTrackerWindow
	slot4 = slot2.sortingOrder

	if not slot0 then
		slot4 = "asc"
	end

	slot3.sortingOrder = slot4

	TaskSystemTrackerWindow.contentsPanel:destroyChildren()
	g_stats.endEvent(slot0)
end

onTaskTracker = function(slot0)
	for slot4, slot5 in ipairs(TaskSystemTrackerWindow.contentsPanel:getChildren()) do
		slot5.entryFound = false
	end

	slot1 = {}

	for slot5, slot6 in ipairs(slot0) do
		if not TaskSystemTrackerWindow.contentsPanel:getChildById("TaskUID_" .. slot6.raceId) then
			slot7.progress:setWidth(math.floor(math.min(slot6.total, slot6.kills) * 105 / slot6.total))
			slot7.progressBar:setText(math.floor(math.min(slot6.total, slot6.kills) * 100 / slot6.total) .. "%")
			slot7.progress:setBackgroundColor(slot6.total <= slot6.kills and "#00ff2a" or "#2effe7")
			slot7.progressBar:setTooltip("You have slain " .. comma_value(slot6.kills) .. " of " .. comma_value(slot6.total) .. " creatures.")
			slot7:setHeight(42 + (#slot6.creatures > 0 and 5 or 0) + #slot6.creatures * 15)

			if #slot6.creatures > 0 then
				slot7.creatures:show()

				for slot11, slot12 in ipairs(slot6.creatures) do
					if slot7.creatures:getChildById("Monster_" .. slot12.raceId) == nil then
						slot13 = g_ui.createWidget("TaskTrackerKillEntry", slot7.creatures)

						slot13:setId("Monster_" .. slot12.raceId)
						slot13:constructEnviorementVariables()

						if g_things.getThingType(slot12.raceId, ThingCategoryMonster) ~= nil then
							slot13.title:setText(capitalizeWords(slot14:getName()) .. ":")
						end
					end

					slot13.amount:setText(comma_value(slot12.kills))

					slot13.amountInt = slot12.kills
				end

				slot8 = slot7.creatures:getChildren()

				table.sort(slot8, function (slot0, slot1)
					return slot1.amountInt < slot0.amountInt
				end)
				slot7.creatures:reorderChildren(slot8)
			else
				slot7.creatures:hide()
				slot7.creatures:destroyChildren()
			end

			slot7.entryFound = true
		else
			table.insert(slot1, slot6)
		end
	end

	for slot5, slot6 in ipairs(slot1) do
		if not g_things.getThingType(slot6.raceId, ThingCategoryMonster) then
			slot8 = g_ui.createWidget("TaskTrackerEntry", TaskSystemTrackerWindow.contentsPanel)

			slot8:setId("TaskUID_" .. slot6.raceId)
			slot8:constructEnviorementVariables()

			if ({
				wings = 0,
				manaBar = 0,
				healthBar = 0,
				feet = nil,
				shader = "",
				mount = 0,
				head = nil,
				body = nil,
				legs = nil,
				aura = 0,
				addons = nil,
				auxType = nil,
				type = nil,
				type = slot7:getTypeId(),
				auxType = slot7:getAuxTypeId(),
				addons = slot7:getAddon(),
				head = slot7:getHeadColor(),
				body = slot7:getBodyColor(),
				legs = slot7:getLegsColor(),
				feet = slot7:getFeetColor()
			}).auxType ~= 0 then
				slot9.category = ThingCategoryItem
			else
				slot9.category = ThingCategoryCreature
			end

			slot8.creature:setOutfit(slot9)
			slot8.creature:setCenter(true)
			slot8.title:setText(slot6.name)
			slot8.progress:setWidth(math.floor(math.min(slot6.total, slot6.kills) * 105 / slot6.total))
			slot8.progressBar:setText(math.floor(math.min(slot6.total, slot6.kills) * 100 / slot6.total) .. "%")
			slot8.progress:setBackgroundColor(slot6.total <= slot6.kills and "#00ff2a" or "#2effe7")
			slot8.progressBar:setTooltip("You have slain " .. comma_value(slot6.kills) .. " of " .. comma_value(slot6.total) .. " creatures.")
			slot8:setHeight(42 + (#slot6.creatures > 0 and 5 or 0) + #slot6.creatures * 15)

			if #slot6.creatures > 0 then
				slot8.creatures:show()
				slot8.creatures:setHeight(#slot6.creatures * 15)

				for slot13, slot14 in ipairs(slot6.creatures) do
					if slot8.creatures:getChildById("Monster_" .. slot14.raceId) == nil then
						slot15 = g_ui.createWidget("TaskTrackerKillEntry", slot8.creatures)

						slot15:setId("Monster_" .. slot14.raceId)
						slot15:constructEnviorementVariables()

						if g_things.getThingType(slot14.raceId, ThingCategoryMonster) ~= nil then
							slot15.title:setText(capitalizeWords(slot16:getName()) .. ":")
						end
					end

					slot15.amount:setText(comma_value(slot14.kills))

					slot15.amountInt = slot14.kills
				end

				slot10 = slot8.creatures:getChildren()

				table.sort(slot10, function (slot0, slot1)
					return slot1.amountInt < slot0.amountInt
				end)
				slot8.creatures:reorderChildren(slot10)
			else
				slot8.creatures:hide()
				slot8.creatures:setHeight(0)
				slot8.creatures:destroyChildren()
			end

			slot8.entryFound = true
		end
	end

	slot2 = {}

	for slot6, slot7 in ipairs(TaskSystemTrackerWindow.contentsPanel:getChildren()) do
		slot8 = slot7.entryFound

		if not slot0 then
			table.insert(slot2, slot7)
		end
	end

	for slot6, slot7 in ipairs(slot2) do
		TaskSystemTrackerWindow.contentsPanel:removeChild(slot7)
		slot7:destroy()
	end

	reloadSorting()
end

saveSettings = function()
	if g_settings.getNode("TaskTracker") == nil then
		slot0 = {}
	end

	if slot0[g_game.getCharacterName()] == nil then
		slot0[g_game.getCharacterName()] = {}
	end

	slot0[g_game.getCharacterName()] = {
		sortingType = nil,
		sortingOrder = nil,
		sortingType = TaskSystemTrackerWindow.sortingType,
		sortingOrder = TaskSystemTrackerWindow.sortingOrder
	}

	g_settings.setNode("TaskTracker", slot0)
end

reloadSorting = function()
	slot0 = TaskSystemTrackerWindow.contentsPanel:getChildren()

	table.sort(slot0, function (slot0, slot1)
		if TaskSystemTrackerWindow.sortingType == "name" then
			if TaskSystemTrackerWindow.sortingOrder == "asc" then
				return slot0.title:getText():lower() < slot1.title:getText():lower()
			else
				return slot1.title:getText():lower() < slot0.title:getText():lower()
			end
		elseif TaskSystemTrackerWindow.sortingType == "stage" then
			if TaskSystemTrackerWindow.sortingOrder == "asc" then
				return slot0.progress.bar:getPercent() < slot1.progress.bar:getPercent()
			else
				return slot1.progress.bar:getPercent() < slot0.progress.bar:getPercent()
			end
		elseif TaskSystemTrackerWindow.sortingType == "kills" then
			if TaskSystemTrackerWindow.sortingOrder == "asc" then
				return tonumber(tostring(slot0.progress.text:getText():gsub(",", ""))) < tonumber(tostring(slot1.progress.text:getText():gsub(",", "")))
			else
				return tonumber(tostring(slot1.progress.text:getText():gsub(",", ""))) < tonumber(tostring(slot0.progress.text:getText():gsub(",", "")))
			end
		else
			return slot0.title:getText():lower() < slot1.title:getText():lower()
		end
	end)
	TaskSystemTrackerWindow.contentsPanel:reorderChildren(slot0)
end

toggle = function()
	if TaskSystemTrackerButton:isOn() then
		TaskSystemTrackerWindow:close()
		TaskSystemTrackerButton:setOn(false)
	else
		TaskSystemTrackerWindow:open()
		TaskSystemTrackerButton:setOn(true)
	end
end

hide = function()
	TaskSystemTrackerWindow:close()
	TaskSystemTrackerButton:setOn(false)
end

openMenu = function(slot0, slot1, slot2)
	if slot0 ~= nil and slot0.getId(slot0) == "menuButton" then
		if slot2 ~= MouseLeftButton then
			return
		end
	elseif slot2 ~= MouseRightButton then
		return
	end

	slot3 = g_ui.createWidget("PopupMenu")

	slot3:setGameMenu(true)
	slot3:addCheckBoxOption("Sort by name", function ()
		TaskSystemTrackerWindow.sortingType = "name"

		reloadSorting()
		saveSettings()
	end, TaskSystemTrackerWindow.sortingType == "name")
	slot3:addCheckBoxOption("Sort by completion percentage", function ()
		TaskSystemTrackerWindow.sortingType = "stage"

		reloadSorting()
		saveSettings()
	end, TaskSystemTrackerWindow.sortingType == "stage")
	slot3:addCheckBoxOption("Sort by kills", function ()
		TaskSystemTrackerWindow.sortingType = "kills"

		reloadSorting()
		saveSettings()
	end, TaskSystemTrackerWindow.sortingType == "kills")
	slot3:addSeparator()
	slot3:addCheckBoxOption("Sort ascending", function ()
		TaskSystemTrackerWindow.sortingOrder = "asc"

		reloadSorting()
		saveSettings()
	end, TaskSystemTrackerWindow.sortingOrder == "asc")
	slot3:addCheckBoxOption("Sort descending", function ()
		TaskSystemTrackerWindow.sortingOrder = "desc"

		reloadSorting()
		saveSettings()
	end, TaskSystemTrackerWindow.sortingOrder == "desc")
	slot3:display(slot1)
end
