-- chunkname: @/gamelib/ui/uicreaturebutton.lua

UICreatureButton = extends(UIWidget, "UICreatureButton")

local CreatureButtonColors = {
	onIdle = {
		notHovered = "#C0C0C0",
		hovered = "#FFFFFF"
	},
	onTargeted = {
		notHovered = "#FF0000",
		hovered = "#FF8888"
	},
	onFollowed = {
		notHovered = "#00FF00",
		hovered = "#88FF88"
	}
}
local NameBorderColors = {
	orange = "#EE8413",
	red = "#FF2020",
	pink = "#C850C0"
}

local function resolveNameBorderColor(creature)
	if not creature then
		return nil
	end

	local echoRaidColor = creature.getEchoRaidColor and creature:getEchoRaidColor() or -1

	if echoRaidColor == 0 then
		return NameBorderColors.red
	elseif echoRaidColor == 1 then
		return NameBorderColors.pink
	end

	local icons = creature.getIcons and creature:getIcons() or nil

	if icons then
		for _, iconData in pairs(icons) do
			if iconData[1] == 5 then
				return NameBorderColors.orange
			end
		end
	end

	return nil
end

function UICreatureButton:update()
	local labelColor = CreatureButtonColors.onIdle.notHovered
	local borderColor
	local showBorder = false

	if self.hoveredMark then
		labelColor = "#FFFFFF"
		borderColor = "#FFFFFF"
		showBorder = true
	end

	if self.isFollowed then
		labelColor = "#FFFFFF"
		borderColor = CreatureButtonColors.onFollowed.notHovered
		showBorder = true
	end

	if self.isTarget then
		borderColor = CreatureButtonColors.onTargeted.notHovered
		showBorder = true
	end

	local creatureWidget = self:getChildById("creature")
	local labelWidget = self:getChildById("label")

	if showBorder then
		creatureWidget:setBorderWidth(1)
		creatureWidget:setBorderColor(borderColor)
	else
		creatureWidget:setBorderWidth(0)
	end

	if self.isPartyButton and self.creature and not CreatureList.canBeSeen(self.creature) then
		labelColor = "#808080"
	end

	labelWidget:setColor(labelColor)
	self:updateNameBorder()
end

function UICreatureButton:updateNameBorder()
	local labelWidget = self:getChildById("label")

	if not labelWidget or not labelWidget.setTextOutlineColor then
		return
	end

	if not self.isBattleButton or not self.creature then
		labelWidget:setTextOutlineColor("alpha")

		return
	end

	local borderColor = resolveNameBorderColor(self.creature)

	labelWidget:setTextOutlineColor(borderColor or "alpha")
end

function UICreatureButton.create()
	local button = UICreatureButton.internalCreate()

	button:setFocusable(false)

	button.creature = nil
	button.hoveredMark = false
	button.isTarget = false
	button.isFollowed = false

	return button
end

function UICreatureButton.getCreatureButtonColors()
	return CreatureButtonColors
end

function UICreatureButton:setCreature(creature)
	self.creature = creature
end

function UICreatureButton:getCreature()
	return self.creature
end

function UICreatureButton:getCreatureId()
	return self.creature:getId()
end

local function getCreatureThingExactSize(lookType)
	if not lookType or lookType <= 0 or not g_things or not g_things.getThingType then
		return 0
	end

	local ok, exactSize = pcall(function()
		local thingType = g_things.getThingType(lookType, ThingCategoryCreature)

		return thingType and thingType:getExactSize() or 0
	end)

	return ok and (tonumber(exactSize) or 0) or 0
end

function UICreatureButton:updateOutfitPreview(outfit)
	local creatureWidget = self:getChildById("creature")

	if not creatureWidget then
		return
	end

	creatureWidget:setOutfit(outfit)

	if not self.isBattleButton then
		return
	end

	-- Keep the widget dimensions intact. The old setCreatureSize(0) call
	-- collapsed this UICreature to 0x0, leaving only the name and health bar.
	-- New executables expose auto-fit directly. Keep the module compatible
	-- with older packaged executables instead of breaking the battle list.
	if creatureWidget.setAutoFit then
		creatureWidget:setAutoFit(true)
	end

	local mountId = tonumber(outfit and outfit.mount) or 0
	local mounted = mountId > 0

	creatureWidget:setCenter(mounted)
	creatureWidget:setCenterByBoundingBox(mounted)

end

function UICreatureButton:setup(creature, onlyOutfit)
	self.creature = creature
	self.hoveredMark = g_game.getHoveredCreature() == creature

	local creatureWidget = self:getChildById("creature")
	local labelWidget = self:getChildById("label")

	labelWidget:setText(creature:getName())

	if onlyOutfit == true then
		self:updateOutfitPreview(creature:getOutfit())
	else
		creatureWidget:setCreature(creature)
	end

	self:setId("CreatureButton_" .. creature:getName():gsub("%s", "_"))
	self:setLifeBarPercent(creature:getHealthPercent())
	self:updateSkull(creature:getSkull())
	self:updateEmblem(creature:getEmblem())
	self:updateIcons(creature:getIcons())

	if self:getChildById("manaBar") then
		self:setManaBarPercent(creature:getManaPercent())
	end

	if self.updatePartyShield then
		self:updatePartyShield(creature:getShield())
	end

	if self.isBattleButton then
		local lifeBarWidget = self:getChildById("lifeBar")

		if lifeBarWidget then
			lifeBarWidget:setVisible(true)
		end
	elseif self.updateShowStatus and self.creature.getShowStatus then
		self:updateShowStatus(self.creature:getShowStatus())
	end

	self:update()
end

function UICreatureButton:updateSkull(skullId)
	if not self.creature then
		return
	end

	local skullId = skullId or self.creature:getSkull()
	local skullWidget = self:getChildById("skull")
	local labelWidget = self:getChildById("label")
	local partyShield = self:getChildById("partyShield")

	if skullId ~= SkullNone then
		skullWidget:setWidth(skullWidget:getHeight())

		local imagePath, clip = getSkullImagePath(skullId)

		skullWidget:setImageSource(imagePath)

		if clip then
			skullWidget:setImageClip(torect(clip))
		end

		if not partyShield or partyShield:getWidth() == 0 then
			labelWidget:setMarginLeft(5)
		else
			labelWidget:setMarginLeft(2)
		end
	else
		skullWidget:setWidth(0)
		skullWidget:setImageSource("")
		labelWidget:setMarginLeft(partyShield and partyShield:getWidth() > 0 and 2 or 2)
	end
end

function UICreatureButton:updateEmblem(emblemId)
	if not self.creature then
		return
	end

	local emblemId = emblemId or self.creature:getEmblem()
	local emblemWidget = self:getChildById("emblem")

	if emblemId ~= EmblemNone then
		emblemWidget:setWidth(emblemWidget:getHeight())

		local imagePath, clip = getEmblemImagePath(emblemId)

		emblemWidget:setImageSource(imagePath)

		if clip then
			emblemWidget:setImageClip(torect(clip))
		end
	else
		emblemWidget:setWidth(0)
	end

	emblemWidget:setMarginLeft(0)
end

function UICreatureButton:setLifeBarPercent(percent)
	local lifeBarWidget = self:getChildById("lifeBar")

	lifeBarWidget:setPercent(percent)
	lifeBarWidget:setBackgroundColor(getHealthColorByPercent(percent))
end

function UICreatureButton:setManaBarPercent(percent)
	local manaBarWidget = self:getChildById("manaBar")

	if not manaBarWidget then
		return
	end

	manaBarWidget:setPercent(percent)
	manaBarWidget:setBackgroundColor("#0000FF")
end

function UICreatureButton:updatePartyShield(shieldId)
	if not self.creature then
		return
	end

	local shieldWidget = self:getChildById("partyShield")

	if not shieldWidget then
		return
	end

	shieldId = shieldId or self.creature:getShield()

	if shieldId ~= ShieldNone then
		shieldWidget:setWidth(shieldWidget:getHeight())

		local imagePath, clip = getShieldImagePath(shieldId)

		shieldWidget:setImageSource(imagePath)

		if clip then
			shieldWidget:setImageClip(torect(clip))
		end
	else
		shieldWidget:setWidth(0)
		shieldWidget:setImageSource("")
	end
end

function UICreatureButton:updateShowStatus(showStatus)
	if showStatus == nil and self.creature and self.creature.getShowStatus then
		showStatus = self.creature:getShowStatus()
	end

	if showStatus == nil then
		showStatus = true
	end

	local lifeBarWidget = self:getChildById("lifeBar")
	local manaBarWidget = self:getChildById("manaBar")

	if lifeBarWidget then
		local visible = self.isBattleButton or showStatus

		lifeBarWidget:setVisible(visible)

		if visible and self.creature and self.creature.getHealthPercent then
			self:setLifeBarPercent(self.creature:getHealthPercent())
		end
	end

	if manaBarWidget then
		manaBarWidget:setVisible(showStatus)
	end
end

function UICreatureButton:updateIcons(icons)
	for i = 1, 3 do
		local w = self:getChildById("iconsMonsterSlot" .. i)

		if w then
			w:setImageSource("")
			w:setWidth(0)
		end
	end

	if not self.creature or not icons or #icons == 0 then
		self:updateNameBorder()

		return
	end

	if not self.creature:isMonster() then
		self:updateNameBorder()

		return
	end

	for index, iconData in pairs(icons) do
		if index > 3 then
			break
		end

		local iconId = iconData[1]
		local widget = self:getChildById("iconsMonsterSlot" .. index)

		if widget then
			widget:setWidth(11)
			widget:setImageSource("/images/game/creatures/hud/flags/modifications")
			widget:setImageClip(torect((iconId - 1) * 11 .. " 0 11 11"))
		end
	end

	self:updateNameBorder()
end

function UICreatureButton:resetState()
	self.hoveredMark = false
	self.isTarget = false
	self.isFollowed = false

	self:getChildById("creature"):setBorderWidth(0)
	self:getChildById("label"):setColor(CreatureButtonColors.onIdle.notHovered)
	self:getChildById("skull"):setImageSource("")
	self:getChildById("emblem"):setImageSource("")

	local partyShield = self:getChildById("partyShield")

	if partyShield then
		partyShield:setImageSource("")
		partyShield:setWidth(0)
	end

	for i = 1, 3 do
		local w = self:getChildById("iconsMonsterSlot" .. i)

		w:setImageSource("")
		w:setWidth(0)
	end

	local labelWidget = self:getChildById("label")

	if labelWidget and labelWidget.setTextOutlineColor then
		labelWidget:setTextOutlineColor("alpha")
	end
end
