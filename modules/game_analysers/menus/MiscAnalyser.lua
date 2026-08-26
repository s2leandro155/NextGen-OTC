-- chunkname: @/game_analysers/menus/MiscAnalyser.lua

if not MiscAnalyser then
	MiscAnalyser = {
		startedAt = os.time(),
		lastUiSecond = -1,
		data = {}
	}
	MiscAnalyser.__index = MiscAnalyser
end

local categoryAliases = {
	charm = "charm",
	charms = "charm",
	imbuement = "imbuement",
	imbuements = "imbuement",
	itemupgrade = "itemUpgrade",
	item_upgrade = "itemUpgrade",
	upgrade = "itemUpgrade",
	awakenedproc = "awakenedProcs",
	awakenedprocs = "awakenedProcs",
	awakened_procs = "awakenedProcs"
}

local categoryOrder = { "charm", "imbuement", "itemUpgrade", "awakenedProcs" }

local imbuementNames = {
	[1] = "Critical Hit",
	[2] = "Mana Leech",
	[3] = "Life Leech"
}

local specialSkillNames = {
	[0] = "Onslaught",
	[1] = "Ruse",
	[2] = "Momentum",
	[3] = "Transcendence"
}

local imbuementIcons = {
	[1] = "/images/game/analyzer/misc/critical",
	[2] = "/images/game/analyzer/misc/mana-leech",
	[3] = "/images/game/analyzer/misc/life-leech"
}

local specialSkillIcons = {
	[0] = "/images/game/analyzer/misc/onslaught",
	[1] = "/images/game/analyzer/misc/ruse",
	[2] = "/images/game/analyzer/misc/momentum",
	[3] = "/images/game/analyzer/misc/transcendence"
}

-- Wire IDs used by CrystalServer's bestiary/charm protocol. Keep this local:
-- game_cyclopedia is sandboxed and may not have exported its definition table
-- yet when the first combat proc reaches the analyser.
local charmNames = {
	[0] = "Wound",
	[1] = "Enflame",
	[2] = "Poison",
	[3] = "Freeze",
	[4] = "Zap",
	[5] = "Curse",
	[6] = "Cripple",
	[7] = "Parry",
	[8] = "Dodge",
	[9] = "Adrenaline Burst",
	[10] = "Numb",
	[11] = "Cleanse",
	[12] = "Bless",
	[13] = "Scavenge",
	[14] = "Gut",
	[15] = "Low Blow",
	[16] = "Divine Wrath",
	[17] = "Vampiric Embrace",
	[18] = "Void's Call",
	[19] = "Savage Blow",
	[20] = "Fatal Hold",
	[21] = "Void Inversion",
	[22] = "Carnage",
	[23] = "Overpower",
	[24] = "Overflux"
}

local function charmName(charmId)
	if charmNames[charmId] then
		return charmNames[charmId]
	end

	local cyclopedia = modules.game_cyclopedia and modules.game_cyclopedia.Cyclopedia
	if cyclopedia and cyclopedia.getCharmDefinition then
		local ok, charm = pcall(function()
			return cyclopedia.getCharmDefinition(charmId)
		end)
		if ok and charm and charm.name then
			return charm.name
		end
	end
	return string.format("Charm #%d", charmId)
end

local function normalizeCategory(category)
	local key = tostring(category or ""):gsub("[%s%-]", ""):lower()
	return categoryAliases[key]
end

local function formatSession(seconds)
	seconds = math.max(0, math.floor(tonumber(seconds) or 0))
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor(seconds % 3600 / 60)
	return string.format("%02d:%02dh", hours, minutes)
end

local function clearPanel(panel)
	if panel then
		panel:destroyChildren()
	end
end

local function createRow(panel, text, color)
	local label = g_ui.createWidget("Label", panel)
	label:setText(text)
	label:setColor(color or "#c0c0c0")
	label:setFont("verdana-11px-monochrome")
	label:setTextAutoResize(true)
	label:setMarginLeft(7)
	label:setMarginTop(1)
	return label
end

local function createEntryRow(panel, entry)
	local row = g_ui.createWidget("MiscEntryRow", panel)
	local icon = row:getChildById("entryIcon")
	local item = row:getChildById("entryItem")
	local name = row:getChildById("entryName")
	local value = row:getChildById("entryValue")

	if entry.itemId and entry.itemId > 0 then
		icon:setVisible(false)
		item:setVisible(true)
		item:setItemId(entry.itemId)
		name:addAnchor(AnchorLeft, "entryItem", AnchorRight)
	else
		item:setVisible(false)
		icon:setVisible(true)
		icon:setImageSource(entry.icon or "/images/ui/character/helmet")
	end

	name:setText(entry.name)
	value:setText(formatMoney(entry.count))
	return row
end

function MiscAnalyser.create()
	MiscAnalyser.window = openedWindows.miscButton
	MiscAnalyser:reset()
end

function MiscAnalyser:reset()
	self.startedAt = os.time()
	self.lastUiSecond = -1
	self.data = {
		charm = {},
		imbuement = {},
		itemUpgrade = {},
		awakenedProcs = {}
	}
	self:updateWindow()
end

function MiscAnalyser:add(category, name, amount, icon, itemId)
	local normalized = normalizeCategory(category)
	if not normalized then
		return false
	end

	name = tostring(name or tr("Unknown"))
	if name == "" then
		name = tr("Unknown")
	end

	amount = tonumber(amount) or 1
	local entries = self.data[normalized]
	local entry = entries[name]
	if not entry then
		entry = { name = name, count = 0, icon = icon, itemId = tonumber(itemId) }
		entries[name] = entry
	end
	entry.icon = icon or entry.icon
	entry.itemId = tonumber(itemId) or entry.itemId

	entry.count = entry.count + amount
	self:updateWindow()
	return true
end

-- Astra/Crystal server format on extended opcode 204:
-- c<charmId>=<count>; i1=critical count; i2/i3=mana/life leeched;
-- s0..s3=item upgrade proc count.
-- Awakened helmet proc: awk:<itemId>|<spell words>|<display name>.
-- The older awk:<spell words>|<display name> form remains supported.
function MiscAnalyser:onProtocolBuffer(buffer)
	if not buffer or buffer == "" then
		return
	end

	local itemId, words, displayName = buffer:match("^awk:(%d+)|(.-)|(.+)$")
	if itemId then
		self:add("awakenedProcs", displayName or words, 1, nil, tonumber(itemId))
		return
	end

	words, displayName = buffer:match("^awk:(.-)|(.+)$")
	if words then
		self:add("awakenedProcs", displayName or words, 1, "/images/ui/character/helmet")
		return
	end

	local changed = false
	for kind, rawId, rawAmount in buffer:gmatch("(%a)(%d+)=(%d+)") do
		local id = tonumber(rawId)
		local amount = tonumber(rawAmount) or 0
		if amount > 0 then
			if kind == "c" then
				self:add("charm", charmName(id), amount, string.format("/images/game/analyzer/charm_runes/charm_%d", id))
				changed = true
			elseif kind == "i" and imbuementNames[id] then
				self:add("imbuement", imbuementNames[id], amount, imbuementIcons[id])
				changed = true
			elseif kind == "s" and specialSkillNames[id] then
				self:add("itemUpgrade", specialSkillNames[id], amount, specialSkillIcons[id])
				changed = true
			end
		end
	end

	if changed then
		self:updateWindow()
	end
end

function MiscAnalyser:updateWindow()
	if not self.window or self.window:isDestroyed() then
		return
	end

	local contents = self.window.contentsPanel
	local sessionValue = contents:recursiveGetChildById("sessionValue")
	if sessionValue then
		sessionValue:setText(formatSession(os.time() - self.startedAt))
	end

	for _, category in ipairs(categoryOrder) do
		local panel = contents:getChildById(category .. "Entries")
		clearPanel(panel)

		local rows = {}
		for _, entry in pairs(self.data[category] or {}) do
			rows[#rows + 1] = entry
		end
		table.sort(rows, function(a, b)
			if a.count ~= b.count then
				return a.count > b.count
			end
			return a.name:lower() < b.name:lower()
		end)

		if #rows == 0 then
			-- ASCII keeps the branch marker readable when box-drawing bytes
			-- are not decoded as UTF-8 by the client font renderer.
			createRow(panel, "L " .. tr("No data yet"), "#a0a0a0")
		else
			for _, entry in ipairs(rows) do
				createEntryRow(panel, entry)
			end
		end

		-- Keep each category tall enough for all generated rows.
		panel:setHeight(math.max(27, math.max(1, #rows) * 20 + 7))
	end
end

function MiscAnalyser:checkTicks()
	local now = os.time()
	if now == self.lastUiSecond then
		return
	end
	self.lastUiSecond = now
	if self.window and self.window:isVisible() then
		self:updateWindow()
	end
end
