-- chunkname: @/game_analysers/menus/Controller.lua

if not ControllerAnalyser then
	ControllerAnalyser = {
		name = "ControllerAnalyser",
		class = "ControllerAnalyser",
		data = {}
	}
	ControllerAnalyser.__index = ControllerAnalyser
end

function ControllerAnalyser:startEvent()
	if ControllerAnalyser.eventGraph then
		ControllerAnalyser.eventGraph:cancel()
	end

	if ControllerAnalyser.event250 then
		ControllerAnalyser.event250:cancel()
	end

	if ControllerAnalyser.event1000 then
		ControllerAnalyser.event1000:cancel()
	end

	if ControllerAnalyser.event2000 then
		ControllerAnalyser.event2000:cancel()
	end

	ControllerAnalyser.event250 = cycleEvent(function()
		if g_game.isOnline() then
			BossCooldown:checkTicks()
			MiscAnalyser:checkTicks()
		end
	end, 250)
	ControllerAnalyser.event1000 = cycleEvent(function()
		if g_game.isOnline() then
			HuntingAnalyser:updateWindow(true)
			LootAnalyser:checkBalance()
			ImpactAnalyser:updateWindow(true)
			ImpactAnalyser:updateGraphics()
			InputAnalyser:checkDPS()
			XPAnalyser:checkExpHour()
			DropTrackerAnalyser:checkTracker()
			SupplyAnalyser:updateWindow(false, true)
		end
	end, ANALYSER_GRAPH_PUSH_INTERVAL_4_MIN_MS)
	ControllerAnalyser.event2000 = cycleEvent(function()
		if g_game.isOnline() then
			InputAnalyser:updateWindow(true)
		end
	end, 2000)
	ControllerAnalyser.eventGraph = cycleEvent(function()
		if g_game.isOnline() then
			LootAnalyser:updateGraphics()
			LootAnalyser:updateWindow(false, true)
			SupplyAnalyser:updateGraphics()
			SupplyAnalyser:updateWindow(false, true)
			XPAnalyser:pushGraphSample()
			XPAnalyser:updateWindow(true)
			ImpactAnalyser:updateWindow(true)
		end
	end, ANALYSER_GRAPH_PUSH_INTERVAL_60_MIN_MS)

	analyserConfigureGraphWidgets()
	ImpactAnalyser:checkAnchos()
	InputAnalyser:checkAnchos()
end
