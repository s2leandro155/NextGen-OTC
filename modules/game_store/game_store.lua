-- chunkname: @/game_store/game_store.lua

local acceptWindow, changeNameWindow, worldTransferWindow, hirelingNameWindow, transferPointsWindow, processingWindow, messageBox
local oldProtocol = false
local a0xF2 = true
local offerDescriptions = {}
local reasonCategory = {}
local bannersHome = {}
local currentIndex = 1
local HISTORY_ENTRIES_PER_PAGE = 26
local HISTORY_ROW_COLOR_A = "#484848"
local HISTORY_ROW_COLOR_B = "#414141"
local HISTORY_ROW_COLOR_SELECTED = "#585858"
local waitingInitialHome = false
local pendingStoreRedirect
local storeRedirectAwaitingOffers = false
local pendingStoreFocusOfferId

local function normalizeStoreOfferId(offerId)
	offerId = tonumber(offerId) or 0

	if offerId <= 0 then
		return 0
	end

	if offerId > 1000000 then
		return offerId % 1000000
	end

	return offerId
end

local function getPrimaryPurchasableOfferId(product)
	if not product then
		return 0
	end

	for _, subOffer in ipairs(product.subOffers or {}) do
		if subOffer.id and subOffer.id > 0 and subOffer.price ~= nil then
			return subOffer.id
		end
	end

	return product.id or 0
end

local function getCachedOfferDescription(offerId)
	if not offerId or offerId <= 0 then
		return ""
	end

	local cached = offerDescriptions[offerId] or offerDescriptions[normalizeStoreOfferId(offerId)]

	return cached and cached.description or ""
end

local function cacheOfferDescription(offerId, description)
	if not offerId or offerId <= 0 then
		return
	end

	offerDescriptions[offerId] = {
		id = offerId,
		description = description
	}

	local normalizedId = normalizeStoreOfferId(offerId)

	if normalizedId ~= offerId then
		offerDescriptions[normalizedId] = offerDescriptions[offerId]
	end
end

local function offerIdBelongsToProduct(product, offerId)
	if not product or not offerId or offerId <= 0 then
		return false
	end

	local normalizedIncoming = normalizeStoreOfferId(offerId)

	for _, subOffer in ipairs(product.subOffers or {}) do
		if subOffer.id and subOffer.id > 0 and (subOffer.id == offerId or normalizeStoreOfferId(subOffer.id) == normalizedIncoming) then
			return true
		end
	end

	if product.id and product.id > 0 and (product.id == offerId or normalizeStoreOfferId(product.id) == normalizedIncoming) then
		return true
	end

	return false
end

local function focusStoreOffer(listProduct, targetOfferId)
	if not listProduct or not targetOfferId or targetOfferId <= 0 then
		return false
	end

	local normalizedTarget = normalizeStoreOfferId(targetOfferId)

	for _, child in ipairs(listProduct:getChildren()) do
		local subOffers = child.product and (child.product.subOffers or {
			child.product
		}) or {}

		for _, subOffer in ipairs(subOffers) do
			if normalizeStoreOfferId(subOffer.id) == normalizedTarget then
				listProduct:focusChild(child)
				listProduct:ensureChildVisible(child)

				return true
			end
		end
	end

	return false
end

local storeHiddenForOverlay = false
local STORE_WATCHDOG_EVENT = "serverNoSendPackets0xF20xFA"

local function resetStoreLuaFlags()
	waitingInitialHome = false
	pendingStoreRedirect = nil
	storeRedirectAwaitingOffers = false
	pendingStoreFocusOfferId = nil
	storeHiddenForOverlay = false
end

local function resetStoreSessionFlags()
	resetStoreLuaFlags()

	a0xF2 = true
end

local function cancelStoreWatchdogEvent()
	controllerShop:scheduleEvent(function()
		return
	end, 1, STORE_WATCHDOG_EVENT)
end

local function recoverStoreOpenEnvironment()
	if g_modalManager and g_modalManager.pruneOrphanBlockers then
		g_modalManager.pruneOrphanBlockers()
	end

	if g_client and g_client.setInputLockWidget then
		pcall(function()
			g_client.setInputLockWidget(nil)
		end)
	end
end

local function showStoreWindow()
	if not controllerShop.ui then
		return
	end

	storeHiddenForOverlay = false

	controllerShop.ui:show()
	g_modalManager.show(controllerShop.ui)

	if controllerShop.ui.SearchEdit then
		controllerShop.ui.SearchEdit:focus()
	end
end

local function hideStoreForOverlay()
	if not controllerShop.ui then
		return
	end

	storeHiddenForOverlay = true

	g_modalManager.hide(controllerShop.ui)
	controllerShop.ui:hide()
end

local function restoreStoreAfterOverlay()
	if not storeHiddenForOverlay or not controllerShop.ui then
		return
	end

	showStoreWindow()
end

function hideStoreForCharacterBazaar()
	hideStoreForOverlay()
end

local STORE_ROW_AVAILABLE = "StoreOfferRowAvailable"
local STORE_ROW_UNAVAILABLE = "StoreOfferRowUnavailable"

GameStore = {}
GameStore.website = {
	IMAGES_URL = "",
	WEBSITE_GETCOINS = "https://google.com"
}
GameStore.CoinType = {
	Transferable = 1,
	Coin = 0
}
GameStore.ClientOfferTypes = {
	CLIENT_STORE_OFFER_OTHER = 0,
	CLIENT_STORE_OFFER_CONFIRM = 6,
	CLIENT_STORE_OFFER_TOURNAMENT = 5,
	CLIENT_STORE_OFFER_CHARACTER = 4,
	CLIENT_STORE_OFFER_HIRELING = 3,
	CLIENT_STORE_OFFER_WORLD_TRANSFER = 2,
	CLIENT_STORE_OFFER_NAMECHANGE = 1
}
GameStore.States = {
	STATE_NONE = 0,
	STATE_TIMED = 3,
	STATE_SALE = 2,
	STATE_NEW = 1
}
GameStore.SendingPackets = {
	S_CoinBalanceUpdating = 242,
	S_RequestPurchaseData = 225,
	S_StoreError = 224,
	S_CoinBalance = 223,
	S_CompletePurchase = 254,
	S_OpenTransactionHistory = 253,
	S_StoreOffers = 252,
	S_OpenStore = 251
}
GameStore.RecivedPackets = {
	C_ParseHirelingName = 236,
	C_TransferCoins = 239,
	C_RequestOfferDescription = 232,
	C_RequestTransactionHistory = 254,
	C_OpenTransactionHistory = 253,
	C_BuyStoreOffer = 252,
	C_RequestStoreOffers = 251,
	C_OpenStore = 250
}

local function showPanel(panel)
	if panel == "HomePanel" then
		controllerShop.ui.HomePanel:setVisible(true)
		controllerShop.ui.panelItem:setVisible(false)
		controllerShop.ui.transferHistory:setVisible(false)
	elseif panel == "transferHistory" then
		controllerShop.ui.HomePanel:setVisible(false)
		controllerShop.ui.panelItem:setVisible(false)
		controllerShop.ui.transferHistory:setVisible(true)
	elseif panel == "panelItem" then
		controllerShop.ui.HomePanel:setVisible(false)
		controllerShop.ui.panelItem:setVisible(true)
		controllerShop.ui.transferHistory:setVisible(false)
	end
end

local function prepareStoreRedirectUi(focusOfferId)
	showStoreWindow()

	waitingInitialHome = false
	storeRedirectAwaitingOffers = true
	pendingStoreFocusOfferId = focusOfferId

	showPanel("panelItem")

	local listProduct = controllerShop.ui.panelItem and controllerShop.ui.panelItem.listProduct

	if listProduct then
		listProduct:destroyChildren()
	end
end

local function clearPurchaseCompleteModalEvents(box)
	if not box then
		return
	end

	if box._closeEvent then
		removeEvent(box._closeEvent)

		box._closeEvent = nil
	end
end

local function releasePurchaseCompleteModalRefs(box)
	clearPurchaseCompleteModalEvents(box)

	if not box then
		return
	end

	local buttonAnimation = box:recursiveGetChildById("buttonAnimation")

	if buttonAnimation and not buttonAnimation:isDestroyed() then
		buttonAnimation.onClick = nil
	end

	if box.onEscape then
		box.onEscape = nil
	end
end

local function releaseTransferPointsWindowRefs(window)
	if not window then
		return
	end

	if window.transferPointsText and not window.transferPointsText:isDestroyed() then
		window.transferPointsText.onTextChange = nil
	end

	if window.amountBar and not window.amountBar:isDestroyed() then
		window.amountBar.onValueChange = nil
	end

	if window.closeButton and not window.closeButton:isDestroyed() then
		window.closeButton.onClick = nil
	end

	if window.buttonOk and not window.buttonOk:isDestroyed() then
		window.buttonOk.onClick = nil
	end

	if window._giftButtonUpdateEvent then
		removeEvent(window._giftButtonUpdateEvent)

		window._giftButtonUpdateEvent = nil
	end

	window.onEscape = nil
	window.giftable = nil
	window.amount = nil
	window.amountBar = nil
	window.transferPointsText = nil
	window.closeButton = nil
	window.buttonOk = nil
end

local function releaseChangeNameWindowRefs(window)
	if not window then
		return
	end

	local nameField = window.transferPointsText

	if nameField and not nameField:isDestroyed() then
		nameField.onTextChange = nil
	end

	if window.closeButton and not window.closeButton:isDestroyed() then
		window.closeButton.onClick = nil
	end

	if window.buttonOk and not window.buttonOk:isDestroyed() then
		window.buttonOk.onClick = nil
	end

	if window._nameOkButtonUpdateEvent then
		removeEvent(window._nameOkButtonUpdateEvent)

		window._nameOkButtonUpdateEvent = nil
	end

	window.onEscape = nil
	window.transferPointsText = nil
	window.closeButton = nil
	window.buttonOk = nil
end

local function clearStoreOverlayWindowRef(window)
	if window == acceptWindow then
		acceptWindow = nil
	elseif window == processingWindow then
		processingWindow = nil
	elseif window == messageBox then
		messageBox = nil
	elseif window == transferPointsWindow then
		transferPointsWindow = nil
	elseif window == changeNameWindow then
		changeNameWindow = nil
	end
end

local function destroyWindow(windows)
	local list = type(windows) == "table" and windows or {
		windows
	}

	for _, window in ipairs(list) do
		if window == messageBox then
			clearPurchaseCompleteModalEvents(window)
		end

		if window and not window:isDestroyed() then
			releasePurchaseCompleteModalRefs(window)

			if releaseShopMessageBoxRefs then
				releaseShopMessageBoxRefs(window)
			end

			if window == transferPointsWindow then
				releaseTransferPointsWindowRefs(window)
			elseif window == changeNameWindow then
				releaseChangeNameWindowRefs(window)
			end

			g_modalManager.hide(window)
			window:destroy()
		end

		clearStoreOverlayWindowRef(window)
	end
end

local function isConfigurableOffer(product, offer)
	return offer and offer.configurable == true or product and product.configurable == true or false
end

local function showStoreProcessingModal()
	destroyWindow(processingWindow)
	hideStoreForOverlay()

	processingWindow = displayGeneralBox(tr("Processing purchase."), tr("Your purchase is being processed."), {}, nil, nil)

	if processingWindow then
		g_modalManager.show(processingWindow)
	end
end

local function getPageLabelHistory()
	local text = controllerShop.ui.transferHistory.lblPage:getText()
	local currentPage, pageCount = text:match("Page (%d+)/(%d+)")

	return tonumber(currentPage), tonumber(pageCount)
end

local pendingHttpWidgets = {}
local pendingHttpId = 0
local STORE_DESC_FONT = "Verdana-11px-lowspace"
local STORE_DESC_ITALIC_FONT = "Verdana-11px-lowspace-italic"
local STORE_DESC_UNDERLINE_FONT = "Verdana-11px-lowspace-underline"
local STORE_DESC_COLOR = "#f4f4f4"
local STORE_INLINE_ICON_SHEET = "/images/icons/store-icons-inline"
local STORE_DESC_ITALIC_ON = string.char(1)
local STORE_DESC_ITALIC_OFF = string.char(2)
local STORE_DESC_UNDERLINE_ON = string.char(3)
local STORE_DESC_UNDERLINE_OFF = string.char(4)
local STORE_INLINE_ICONS = {
	["{vocationlevelcheckicon}"] = "104 0 13 13",
	["{info}"] = "0 0 13 13",
	["{speedboosticon}"] = "117 0 13 13",
	["{backtoinboxicon}"] = "91 0 13 13",
	["{activatedicon}"] = "130 0 13 13",
	["{limiticon}"] = "78 0 13 13",
	["{battlesignicon}"] = "143 0 13 13",
	["{houseicon}"] = "65 0 13 13",
	["{capacityicon}"] = "156 0 13 13",
	["{storeinboxicon}"] = "52 0 13 13",
	["{useicon}"] = "169 0 13 13",
	["{boxicon}"] = "39 0 13 13",
	["{transferablepriceicon}"] = "182 0 13 13",
	["{usablebyallicon}"] = "26 0 13 13",
	["{accounticon}"] = "195 0 13 13",
	["{charactericon}"] = "13 0 13 13"
}
local STORE_DESCRIPTION_HINTS = {
	{
		keyword = "character",
		text = "only usable by purchasing character",
		icon = "{charactericon}"
	},
	{
		keyword = "usablebyall",
		text = "can be used by all characters that have access to the house",
		icon = "{usablebyallicon}"
	},
	{
		keyword = "box",
		text = "comes in a box which can only be unwrapped by purchasing character",
		icon = "{boxicon}"
	},
	{
		keyword = "storeinbox",
		text = "will be sent to your Store inbox and can only be stored there and in depot box",
		icon = "{storeinboxicon}"
	},
	{
		keyword = "house",
		text = "can only be unwrapped in a house owned by the purchasing character",
		icon = "{houseicon}"
	},
	{
		keyword = "limit",
		text = "maximum amount that can be owned by character: %s",
		icon = "{limiticon}",
		dynamic = true
	},
	{
		keyword = "backtoinbox",
		text = "will be wrapped back and sent to inbox if the purchasing character is no longer the house owner",
		icon = "{backtoinboxicon}"
	},
	{
		keyword = "vocationlevelcheck",
		text = "only buyable if fitting vocation and level of purchasing character",
		icon = "{vocationlevelcheckicon}"
	},
	{
		keyword = "speedboost",
		text = "provides character with a speed boost",
		icon = "{speedboosticon}"
	},
	{
		keyword = "activated",
		text = "activated at purchase",
		icon = "{activatedicon}"
	},
	{
		keyword = "battlesign",
		text = "cannot be purchased by characters with protection zone block or battle sign",
		icon = "{battlesignicon}"
	},
	{
		keyword = "capacity",
		text = "cannot be purchased if capacity is exceeded",
		icon = "{capacityicon}"
	},
	{
		keyword = "transferableprice",
		text = "can only be purchased with transferable Tibia Coins",
		icon = "{transferablepriceicon}"
	},
	{
		keyword = "account",
		text = "usable by all characters of the account",
		icon = "{accounticon}"
	}
}
local STORE_DESCRIPTION_HINTS_BY_KEYWORD = {}
local STORE_DESCRIPTION_HINTS_BY_TEXT = {}

for _, hint in ipairs(STORE_DESCRIPTION_HINTS) do
	STORE_DESCRIPTION_HINTS_BY_KEYWORD[hint.keyword] = hint

	if not hint.dynamic then
		STORE_DESCRIPTION_HINTS_BY_TEXT[hint.text:lower()] = hint
	end
end

local function decodeStoreDescriptionEntities(text)
	text = text:gsub("&nbsp;", " ")
	text = text:gsub("&lt;", "<")
	text = text:gsub("&gt;", ">")
	text = text:gsub("&quot;", "\"")
	text = text:gsub("&amp;", "&")

	return text
end

local function matchStoreDescriptionIconTag(text, pos)
	if text:byte(pos) ~= 123 then
		return nil
	end

	local tail = text:sub(pos)
	local limitTag = tail:match("^(%{limit|%d+%})")

	if limitTag then
		return "{limiticon}", STORE_INLINE_ICONS["{limiticon}"], pos + #limitTag
	end

	local close = text:find("}", pos + 1, true)

	if not close then
		return nil
	end

	local tag = text:sub(pos, close)
	local clip = STORE_INLINE_ICONS[tag]

	if clip then
		return tag, clip, close + 1
	end

	return nil
end

local function lineStartsWithStoreIconTag(line)
	local content = line:match("^%s*(.*)$") or line

	if content == "" then
		return false
	end

	return matchStoreDescriptionIconTag(content, 1) ~= nil
end

local function enrichStoreDescriptionLine(line)
	if not line or not line:match("%S") then
		return line
	end

	if lineStartsWithStoreIconTag(line) then
		return line
	end

	local content = line:match("^%s*(.-)%s*$") or line
	local plain = content:gsub("^%-%s*", "")
	local tagBody = plain:match("^%{([^}]+)}%s*$") or plain:match("^%{([^}]+)}%s+")

	if tagBody then
		local keyword, amount = tagBody:match("^([^|]+)|(%d+)$")

		keyword = keyword or tagBody
		keyword = keyword:lower()

		local hint = STORE_DESCRIPTION_HINTS_BY_KEYWORD[keyword]

		if hint then
			if hint.dynamic and amount then
				local text = string.format(hint.text, amount)

				return "{limit|" .. amount .. "} " .. text
			elseif not hint.dynamic then
				return hint.icon .. " " .. hint.text
			end
		end
	end

	local normalized = plain:lower()
	local limitAmount = normalized:match("^maximum amount that can be owned by character: (%d+)$")

	if limitAmount then
		return "{limit|" .. limitAmount .. "} maximum amount that can be owned by character: " .. limitAmount
	end

	local hint = STORE_DESCRIPTION_HINTS_BY_TEXT[normalized]

	if hint then
		return hint.icon .. " " .. hint.text
	end

	return line
end

local function htmlToStoreDescriptionLines(html)
	if not html or html == "" then
		return {}
	end

	html = decodeStoreDescriptionEntities(html:gsub("\r", ""))
	html = html:gsub("<[bB][rR]%s*/?>", "\n")
	html = html:gsub("<[lL][iI]>%s*", "- ")
	html = html:gsub("</[lL][iI]>%s*", "\n")
	html = html:gsub("<[uUoO][lL]>%s*", "")
	html = html:gsub("</[uUoO][lL]>%s*", "\n")
	html = html:gsub("<[pP]>%s*", "")
	html = html:gsub("</[pP]>%s*", "\n")
	html = html:gsub("</?[bB]>", "")

	local lines = {}
	local from = 1

	for i = 1, #html do
		if html:byte(i) == 10 then
			table.insert(lines, html:sub(from, i - 1))

			from = i + 1
		end
	end

	if from <= #html then
		table.insert(lines, html:sub(from))
	end

	for i = 1, #lines do
		lines[i] = enrichStoreDescriptionLine(lines[i])
	end

	return lines
end

local function stripStoreDescriptionTags(text)
	local trimmed = text:match("^%s*(.-)%s*$") or text

	return trimmed:gsub("<i>", ""):gsub("</i>", ""):gsub("<I>", ""):gsub("</I>", ""):gsub("<u>", ""):gsub("</u>", ""):gsub("<U>", ""):gsub("</U>", ""):gsub("<[^>]+>", "")
end

local STORE_DESC_ICON_GAP = 17
local storeDescMeasureLabel

local function getStoreDescriptionFont(lineText)
	local trimmed = lineText:match("^%s*(.-)%s*$") or lineText

	if trimmed:find("<i>") or trimmed:find("<I>") then
		return STORE_DESC_ITALIC_FONT
	end

	if trimmed:find("<u>") or trimmed:find("<U>") then
		return STORE_DESC_UNDERLINE_FONT
	end

	return STORE_DESC_FONT
end

local function measureStoreDescriptionText(text, fontName)
	if not text or text == "" then
		return 0
	end

	if not storeDescMeasureLabel then
		storeDescMeasureLabel = g_ui.createWidget("Label", g_ui.getRootWidget())

		storeDescMeasureLabel:setVisible(false)
		storeDescMeasureLabel:setPhantom(true)
	end

	storeDescMeasureLabel:setFont(fontName)
	storeDescMeasureLabel:setTextWrap(false)
	storeDescMeasureLabel:setText(text, true)

	return storeDescMeasureLabel:getTextSize().width
end

local function getStoreDescriptionScrollWidth(scroll)
	if not scroll then
		return 200
	end

	local width = scroll:getWidth() - scroll:getPaddingLeft() - scroll:getPaddingRight()

	return math.max(1, width)
end

local function wrapStoreDescriptionPlainText(plainText, fontName, totalWidth, firstLineWidth)
	if not plainText or plainText == "" then
		return {
			""
		}
	end

	local lines = {}
	local currentLine = ""
	local maxWidth = firstLineWidth

	for word in plainText:gmatch("%S+") do
		local candidate = currentLine == "" and word or currentLine .. " " .. word

		if maxWidth >= measureStoreDescriptionText(candidate, fontName) then
			currentLine = candidate
		elseif currentLine == "" then
			table.insert(lines, word)

			currentLine = ""
			maxWidth = totalWidth
		else
			table.insert(lines, currentLine)

			currentLine = word
			maxWidth = totalWidth
		end
	end

	if currentLine ~= "" then
		table.insert(lines, currentLine)
	end

	if #lines == 0 then
		table.insert(lines, plainText)
	end

	return lines
end

local function formatStoreDescription(html)
	local parts = {}

	for _, line in ipairs(htmlToStoreDescriptionLines(html)) do
		local plain = line:gsub("<i>", STORE_DESC_ITALIC_ON):gsub("</i>", STORE_DESC_ITALIC_OFF)

		plain = plain:gsub("<u>", STORE_DESC_UNDERLINE_ON):gsub("</u>", STORE_DESC_UNDERLINE_OFF)
		plain = plain:gsub("<[^>]+>", "")

		table.insert(parts, plain)
	end

	return table.concat(parts, "\n")
end

local function applyStoreDescriptionLineText(textWidget, lineText, color)
	local trimmed = lineText:match("^%s*(.-)%s*$") or lineText
	local hasItalic = trimmed:find("<i>") or trimmed:find("<I>")
	local hasUnderline = trimmed:find("<u>") or trimmed:find("<U>")
	local plainText = stripStoreDescriptionTags(trimmed)

	if plainText == "" then
		textWidget:setText("")

		return
	end

	if hasItalic then
		textWidget:setFont(STORE_DESC_ITALIC_FONT)
	elseif hasUnderline then
		textWidget:setFont(STORE_DESC_UNDERLINE_FONT)
	else
		textWidget:setFont(STORE_DESC_FONT)
	end

	textWidget:setText(plainText)
	textWidget:setColor(color or STORE_DESC_COLOR)
end

local function renderStoreDescriptionLineWidget(container, lineText, color, iconClip)
	local widget = g_ui.createWidget("StoreDescriptionLine", container)

	if not widget then
		return false
	end

	local iconWidget = widget.icon or widget:getChildById("icon")
	local textWidget = widget.text or widget:getChildById("text")

	if not textWidget then
		widget:destroy()

		return false
	end

	if iconClip and iconWidget then
		iconWidget:setVisible(true)
		iconWidget:setImageSource(STORE_INLINE_ICON_SHEET)
		iconWidget:setImageClip(iconClip)
		textWidget:setMarginLeft(STORE_DESC_ICON_GAP)
		textWidget:setTextWrap(false)
	else
		if iconWidget then
			iconWidget:setVisible(false)
		end

		textWidget:setMarginLeft(0)
		textWidget:setTextWrap(true)
	end

	applyStoreDescriptionLineText(textWidget, lineText, color)
	widget:setHeight(math.max(14, textWidget:getTextSize().height + 2))

	return textWidget:getText() ~= "" or iconClip ~= nil
end

local function addStoreDescriptionLine(container, lineText, color)
	if lineText == nil then
		return false
	end

	if not lineText:match("%S") then
		local widget = g_ui.createWidget("StoreDescriptionLine", container)

		if not widget then
			return false
		end

		local iconWidget = widget.icon or widget:getChildById("icon")
		local textWidget = widget.text or widget:getChildById("text")

		if iconWidget then
			iconWidget:setVisible(false)
		end

		if textWidget then
			textWidget:setMarginLeft(0)
			textWidget:setText("")
		end

		widget:setHeight(8)

		return true
	end

	local _, clip, nextPos = matchStoreDescriptionIconTag(lineText, 1)

	if clip then
		local textAfterIcon = lineText:sub(nextPos)
		local fontName = getStoreDescriptionFont(textAfterIcon)
		local plainText = stripStoreDescriptionTags(textAfterIcon:match("^%s*(.-)%s*$") or textAfterIcon)
		local totalWidth = getStoreDescriptionScrollWidth(container)
		local firstLineWidth = math.max(1, totalWidth - STORE_DESC_ICON_GAP)
		local segments = wrapStoreDescriptionPlainText(plainText, fontName, totalWidth, firstLineWidth)
		local hasItalic = textAfterIcon:find("<i>") or textAfterIcon:find("<I>")
		local hasUnderline = textAfterIcon:find("<u>") or textAfterIcon:find("<U>")
		local added = false

		for index, segment in ipairs(segments) do
			local segmentText = segment

			if hasItalic then
				segmentText = "<i>" .. segment .. "</i>"
			elseif hasUnderline then
				segmentText = "<u>" .. segment .. "</u>"
			end

			if renderStoreDescriptionLineWidget(container, segmentText, color, index == 1 and clip or nil) then
				added = true
			end
		end

		return added
	end

	return renderStoreDescriptionLineWidget(container, lineText, color, nil)
end

local function getPanelItemDetailsContent(panel)
	if not panel then
		return nil
	end

	return panel.detailsContentPanel or panel:getChildById("detailsContentPanel")
end

local function getPanelItemDescriptionScroll(panel)
	local detail = getPanelItemDetailsContent(panel)

	if not detail then
		return nil
	end

	return detail.descriptionScroll or detail:getChildById("descriptionScroll")
end

local function getPanelItemDescriptionLabel(panel)
	local scroll = getPanelItemDescriptionScroll(panel)

	if not scroll then
		return nil
	end

	return scroll.lblDescription or scroll:getChildById("lblDescription")
end

local function clearStoreDescriptionLines(scroll)
	if not scroll then
		return
	end

	for i = scroll:getChildCount(), 1, -1 do
		local child = scroll:getChildByIndex(i)

		if child and child:getId() ~= "lblDescription" then
			child:destroy()
		end
	end
end

local function showStoreDescriptionFallback(scroll, html, errorText)
	local label = scroll.lblDescription or scroll:getChildById("lblDescription")

	if not label then
		return
	end

	clearStoreDescriptionLines(scroll)
	label:setVisible(true)

	local textParts = {}

	for _, line in ipairs(htmlToStoreDescriptionLines(html or "")) do
		local plain = stripStoreDescriptionTags(line):gsub("%{%w+%}", "")

		table.insert(textParts, plain)
	end

	local text = table.concat(textParts, "\n")

	if errorText and errorText ~= "" then
		text = errorText .. (text ~= "" and "\n\n" .. text or "")
	end

	label:setFont(STORE_DESC_FONT)
	label:setColor(STORE_DESC_COLOR)
	label:setText(text)
end

local createProductImage

local function getPackageContents(product)
	local capacity = tonumber(product and product.productsCapacity) or 0

	if capacity <= 0 then
		return {}
	end

	local subOffers = product.subOffers or {}
	local startIndex = #subOffers - capacity + 1

	if startIndex < 1 then
		return {}
	end

	local contents = {}

	for i = startIndex, #subOffers do
		table.insert(contents, subOffers[i])
	end

	return contents
end

local function getPurchasableSubOffers(product)
	local subOffers = product and product.subOffers or {}
	local capacity = tonumber(product and product.productsCapacity) or 0

	if capacity <= 0 or capacity >= #subOffers then
		return subOffers
	end

	local purchasable = {}

	for i = 1, #subOffers - capacity do
		table.insert(purchasable, subOffers[i])
	end

	return purchasable
end

local function getProductOutfitColors(source)
	if not source then
		return 0, 0, 0, 0
	end

	local function readColors(from)
		if from.outfit then
			return from.outfit.lookHead or from.outfit.head or 0, from.outfit.lookBody or from.outfit.body or 0, from.outfit.lookLegs or from.outfit.legs or 0, from.outfit.lookFeet or from.outfit.feet or 0
		end

		return from.outfitHead or 0, from.outfitBody or 0, from.outfitLegs or 0, from.outfitFeet or 0
	end

	local head, body, legs, feet = readColors(source)

	if source.outfitHead ~= nil or source.outfitBody ~= nil or source.outfitLegs ~= nil or source.outfitFeet ~= nil then
		return head, body, legs, feet
	end

	for _, subOffer in ipairs(source.subOffers or {}) do
		if subOffer.outfitHead ~= nil or subOffer.outfitBody ~= nil or subOffer.outfitLegs ~= nil or subOffer.outfitFeet ~= nil then
			return readColors(subOffer)
		end
	end

	return head, body, legs, feet
end

local function buildHirelingProductData(source, outfitId)
	if not outfitId or outfitId <= 0 then
		return nil
	end

	local head, body, legs, feet = getProductOutfitColors(source)

	return {
		VALOR = "outfitId",
		isHireling = true,
		ID = outfitId,
		outfit = {
			addons = 3,
			type = outfitId,
			head = head,
			body = body,
			legs = legs,
			feet = feet
		}
	}
end

local function toPositiveNumber(value)
	local n = tonumber(value)

	if n and n > 0 then
		return n
	end

	return nil
end

local function findHirelingOutfitIds(product)
	local male = toPositiveNumber(product.maleOutfitId)
	local female = toPositiveNumber(product.femaleOutfitId)

	if male or female then
		return male, female
	end

	for _, subOffer in ipairs(product.subOffers or {}) do
		male = male or toPositiveNumber(subOffer.maleOutfitId)
		female = female or toPositiveNumber(subOffer.femaleOutfitId)
	end

	return male, female
end

local function resolveHirelingOutfitId(sex, maleOutfitId, femaleOutfitId)
	if sex == nil then
		sex = 1
	end

	local outfitId = sex == 0 and femaleOutfitId or maleOutfitId

	return outfitId or maleOutfitId or femaleOutfitId
end

local function findHirelingSex(product)
	if product.sex ~= nil then
		return product.sex
	end

	for _, subOffer in ipairs(product.subOffers or {}) do
		if subOffer.sex ~= nil then
			return subOffer.sex
		end
	end

	return 1
end

local function getSubOfferProductData(subOffer)
	if not subOffer then
		return nil
	end

	if subOffer.itemId and subOffer.itemId > 0 then
		return {
			VALOR = "item",
			ID = subOffer.itemId
		}
	end

	if subOffer.mountId and subOffer.mountId > 0 then
		return {
			VALOR = "mountId",
			ID = subOffer.mountId
		}
	end

	if subOffer.icon and subOffer.icon ~= "" then
		return {
			VALOR = "icon",
			ID = subOffer.icon
		}
	end

	local maleOutfitId = subOffer.maleOutfitId
	local femaleOutfitId = subOffer.femaleOutfitId

	if maleOutfitId and maleOutfitId > 0 or femaleOutfitId and femaleOutfitId > 0 then
		local outfitId = resolveHirelingOutfitId(subOffer.sex, maleOutfitId, femaleOutfitId)

		return buildHirelingProductData(subOffer, outfitId)
	end

	return nil
end

local function renderStorePackageContents(scroll, product, opts)
	opts = opts or {}

	if not scroll or not product then
		return false
	end

	local contents = getPackageContents(product)

	if #contents == 0 then
		return false
	end

	if opts.addSpacer then
		addStoreDescriptionLine(scroll, "")
	end

	local header = g_ui.createWidget("StorePackageContentsHeader", scroll)

	if header then
		header:setText("This package contains:")
	end

	for _, content in ipairs(contents) do
		local row = g_ui.createWidget("StorePackageContentsRow", scroll)

		if not row then
			-- block empty
		else
			local nameLabel = row.name or row:getChildById("name")

			if nameLabel then
				nameLabel:setText(content.name or "")
			end

			local preview = row.preview or row:getChildById("preview")
			local data = getSubOfferProductData(content)

			if preview and data and createProductImage then
				preview:destroyChildren()
				createProductImage(preview, data, {
					packagePreview = true
				})
			end
		end
	end

	return true
end

local function renderStoreDescription(panel, html, errorText, product)
	local scroll = getPanelItemDescriptionScroll(panel)

	if not scroll then
		return
	end

	local fallbackLabel = scroll.lblDescription or scroll:getChildById("lblDescription")

	if fallbackLabel then
		fallbackLabel:setVisible(false)
	end

	clearStoreDescriptionLines(scroll)

	local lineCount = 0

	if errorText and errorText ~= "" then
		if addStoreDescriptionLine(scroll, errorText, "#d33c3c") then
			lineCount = lineCount + 1
		end

		if addStoreDescriptionLine(scroll, "") then
			lineCount = lineCount + 1
		end
	end

	if html and html ~= "" then
		for _, line in ipairs(htmlToStoreDescriptionLines(html)) do
			if addStoreDescriptionLine(scroll, line) then
				lineCount = lineCount + 1
			end
		end
	end

	local hasPackage = renderStorePackageContents(scroll, product, {
		addSpacer = lineCount > 0
	})

	if lineCount == 0 and not hasPackage then
		showStoreDescriptionFallback(scroll, html, errorText)

		return
	end

	scroll:updateLayout()
end

local function clearPendingHttpForChildren(parent)
	if not parent then
		return
	end

	for i = 1, parent:getChildCount() do
		local child = parent:getChildByIndex(i)

		if child and child._httpId then
			pendingHttpWidgets[child._httpId] = nil
			child._httpId = nil
		end
	end
end

local function clearHomeProducts()
	if not controllerShop.ui or not controllerShop.ui.HomePanel then
		return
	end

	local homeProductos = controllerShop.ui.HomePanel.HomeRecentlyAdded.HomeProductos

	for i = 1, homeProductos:getChildCount() do
		local row = homeProductos:getChildByIndex(i)

		if row then
			clearPendingHttpForChildren(row:getChildById("image"))
		end
	end

	homeProductos:destroyChildren()
end

local function refreshRowHoverBorder(row)
	local hoverBorder = row:getChildById("hoverBorder")

	if not hoverBorder then
		return
	end

	hoverBorder:setVisible(row._isHovered == true or row._isFocused == true)
end

local function bindRowHoverBorder(row, enableHover, keepFocusBorder)
	row._isHovered = false
	row._isFocused = false

	if keepFocusBorder ~= false then
		function row.onFocusChange(widget, focused)
			widget._isFocused = focused

			refreshRowHoverBorder(widget)
		end
	end

	if enableHover then
		function row.onHoverChange(widget, hovered)
			widget._isHovered = hovered

			refreshRowHoverBorder(widget)
		end
	end
end

local function updateHomeHoveredRow(homeProductos, mousePos)
	local hoveredRow

	for _, row in ipairs(homeProductos:getChildren()) do
		local isHovered = row:containsPoint(mousePos)

		row._isHovered = isHovered

		if isHovered then
			hoveredRow = row
		end

		refreshRowHoverBorder(row)
	end

	return hoveredRow
end

local function getHomeBannerWidget()
	if not controllerShop.ui or not controllerShop.ui.HomePanel then
		return nil
	end

	local frame = controllerShop.ui.HomePanel:getChildById("HomeImagenFrame")

	if not frame then
		return nil
	end

	return frame:getChildById("HomeImagen")
end

local function setImagenHttp(widget, url, isIcon)
	local base = GameStore.website.IMAGES_URL

	if base and base ~= "" then
		pendingHttpId = pendingHttpId + 1

		local myId = pendingHttpId

		pendingHttpWidgets[myId] = widget
		widget._httpId = myId

		HTTP.downloadImage(base .. url, function(path, err)
			local w = pendingHttpWidgets[myId]

			pendingHttpWidgets[myId] = nil

			if not w or w:isDestroyed() then
				return
			end

			if err then
				g_logger.warning("HTTP error: " .. err .. " - " .. base .. url)

				if isIcon then
					w:setIcon("/game_store/images/dynamic-image-error")
				else
					w:setImageSource("/game_store/images/dynamic-image-error")
					w:setImageFixedRatio(false)
				end

				return
			end

			if isIcon then
				w:setIcon(path)
			else
				w:setImageSource(path)
			end
		end)
	else
		local rel = url:gsub("^/+", "")
		local localPath = "/game_store/images/" .. rel

		if not g_resources.fileExists(localPath) then
			widget:setImageSource("/game_store/images/dynamic-image-error")
			widget:setImageFixedRatio(false)
		else
			widget:setImageSource(localPath)
		end
	end
end

local function formatNumberWithCommas(value)
	local sign = value < 0 and "-" or ""

	value = math.abs(value)

	local formattedValue = string.format("%d", value)

	formattedValue = formattedValue:reverse():gsub("(%d%d%d)", "%1,")
	formattedValue = formattedValue:reverse():gsub("^,", "")

	return sign .. formattedValue
end

local function getCoinsBalance()
	local function extractNumber(text)
		if type(text) ~= "string" then
			return 0
		end

		local numberStr = text:match("%d[%d,]*")

		if not numberStr then
			return 0
		end

		local cleanNumber = numberStr:gsub("[^%d]", "")

		return tonumber(cleanNumber) or 0
	end

	local lblCoins = controllerShop.ui.lblCoins.lblTibiaCoins
	local lblTransfer = controllerShop.ui.lblCoins.lblTibiaTransfer
	local coins1 = lblCoins and extractNumber(lblCoins:getText()) or 0
	local coins2 = lblTransfer and extractNumber(lblTransfer:getText()) or 0

	return coins1, coins2
end

local function fixServerNoSend0xF2()
	if not a0xF2 then
		return
	end

	local player = g_game.getLocalPlayer()

	if not player or not controllerShop.ui then
		local packet2 = GameStore.SendingPackets.S_CoinBalanceUpdating

		g_logger.warning(string.format("[game_store BUG] Check 0x%X (%d) on server onParseStoreGetCoin", packet2, packet2))

		return
	end

	local coin, transfer = getCoinsBalance()
	local coinBalance = player:getResourceBalance(ResourceTypes.COIN_NORMAL)
	local transferBalance = player:getResourceBalance(ResourceTypes.COIN_TRANSFERRABLE)

	if coin ~= coinBalance or transfer ~= transferBalance then
		controllerShop.ui.lblCoins.lblTibiaCoins:setText(formatNumberWithCommas(coinBalance))
		controllerShop.ui.lblCoins.lblTibiaTransfer:setText(string.format("(Including: %s", formatNumberWithCommas(transferBalance)))
	end

	a0xF2 = false
end

local function closePurchaseSuccessModal(box)
	box = box or messageBox

	if not box or box:isDestroyed() then
		return
	end

	destroyWindow(box)
	restoreStoreAfterOverlay()
	fixServerNoSend0xF2()
end

function updateAuctionCharacterTransferableBalance()
	local window = configAuctionCharacterWindow

	if not window or window:isDestroyed() or not window:isVisible() then
		window = checksAuctionCharacterWindow
	end

	if not window or window:isDestroyed() then
		return
	end

	local label = window.balanceCoins and window.balanceCoins.balanceCoinsLabel

	if not label then
		return
	end

	fixServerNoSend0xF2()

	local _, transferableBalance = getCoinsBalance()
	local player = g_game.getLocalPlayer()

	if not player then
		return
	end

	local balance = player:getResourceBalance(ResourceTypes.COIN_TRANSFERRABLE)

	if balance == 0 then
		balance = transferableBalance
	end

	label:setText(formatNumberWithCommas(balance))
end

local function convert_timestamp(timestamp)
	local fecha_hora = os.date("%Y-%m-%d, %H:%M:%S", timestamp)

	return fecha_hora
end

local function getProductData(product)
	local SHOW_NONE = 0
	local SHOW_MOUNT = 1
	local SHOW_OUTFIT = 2
	local SHOW_ITEM = 3
	local SHOW_HIRELING = 4

	local function toPositiveNumber(value)
		local n = tonumber(value)

		if n and n > 0 then
			return n
		end

		return nil
	end

	local productType = tonumber(product.type) or 0
	local subOffers = getPurchasableSubOffers(product)

	local function findNumber(fieldName)
		local direct = toPositiveNumber(product[fieldName])

		if direct then
			return direct
		end

		for _, subOffer in ipairs(subOffers) do
			local value = toPositiveNumber(subOffer[fieldName])

			if value then
				return value
			end
		end

		return nil
	end

	local function findIcon()
		if product.icon and product.icon ~= "" then
			return product.icon
		end

		for _, subOffer in ipairs(subOffers) do
			if subOffer.icon and subOffer.icon ~= "" then
				return subOffer.icon
			end
		end

		return nil
	end

	local itemId = findNumber("itemId")
	local itemType = findNumber("itemType")
	local icon = findIcon()
	local mountClientId = findNumber("mountClientId")
	local mountId = findNumber("mountId")
	local outfitId = findNumber("outfitId")
	local maleOutfitId = findNumber("maleOutfitId")
	local femaleOutfitId = findNumber("femaleOutfitId")
	local sexId = findNumber("sexId")

	if productType == SHOW_MOUNT and (mountClientId or mountId) then
		return {
			VALOR = "mountId",
			ID = mountClientId or mountId
		}
	elseif productType == SHOW_ITEM and (itemType or itemId) then
		return {
			VALOR = "item",
			ID = itemType or itemId
		}
	elseif productType == SHOW_OUTFIT then
		if sexId then
			return {
				VALOR = "outfitId",
				ID = sexId
			}
		elseif outfitId then
			return {
				VALOR = "outfitId",
				ID = outfitId
			}
		end
	elseif productType == SHOW_HIRELING then
		local male, female = findHirelingOutfitIds(product)
		local id = resolveHirelingOutfitId(findHirelingSex(product), male, female)

		return buildHirelingProductData(product, id)
	elseif productType == SHOW_NONE and icon then
		return {
			VALOR = "icon",
			ID = icon
		}
	end

	if itemId or itemType then
		return {
			VALOR = "item",
			ID = itemId or itemType
		}
	elseif mountId then
		return {
			VALOR = "mountId",
			ID = mountId
		}
	elseif outfitId then
		return {
			VALOR = "outfitId",
			ID = outfitId
		}
	elseif maleOutfitId or femaleOutfitId or productType == SHOW_HIRELING then
		local male, female = findHirelingOutfitIds(product)
		local id = resolveHirelingOutfitId(findHirelingSex(product), male or maleOutfitId, female or femaleOutfitId)

		return buildHirelingProductData(product, id)
	elseif sexId then
		return {
			VALOR = "outfitId",
			ID = sexId
		}
	elseif icon then
		return {
			VALOR = "icon",
			ID = icon
		}
	end
end

local function getOfferTitleColorByState(state)
	if state == GameStore.States.STATE_NEW then
		return "#44ad25"
	elseif state == GameStore.States.STATE_SALE then
		return "#f7af48"
	elseif state == GameStore.States.STATE_TIMED then
		return "#1872c3"
	end

	return "#c0c0c0"
end

local function resolveOfferState(product)
	if not product then
		return 0
	end

	if product.state and product.state > 0 then
		return product.state
	end

	if product.subOffers and #product.subOffers > 0 then
		local firstSubOffer = product.subOffers[1]

		if firstSubOffer and firstSubOffer.state and firstSubOffer.state > 0 then
			return firstSubOffer.state
		end
	end

	return 0
end

local function getOfferStateFlagImage(state)
	if state == GameStore.States.STATE_NEW then
		return "/game_store/images/store-flag-new"
	elseif state == GameStore.States.STATE_SALE then
		return "/game_store/images/store-flag-sale"
	elseif state == GameStore.States.STATE_TIMED then
		return "/game_store/images/store-flag-expires"
	end

	return nil
end

local function applyOfferStateVisuals(row, product)
	local state = resolveOfferState(product)
	local nameLabel = row:getChildById("lblName")

	if nameLabel then
		nameLabel:setColor(getOfferTitleColorByState(state))
	end

	local stateFlag = row:getChildById("stateFlag")

	if not stateFlag then
		return
	end

	local stateFlagImage = getOfferStateFlagImage(state)

	if stateFlagImage then
		stateFlag:setImageSource(stateFlagImage)
		stateFlag:show()
	else
		stateFlag:setImageSource("")
		stateFlag:hide()
	end
end

function createProductImage(imageParent, data, opts)
	opts = opts or {}

	local detailLargePreview = opts.detailLargePreview == true
	local packagePreview = opts.packagePreview == true
	local previewSize = 64

	if detailLargePreview then
		previewSize = 128
	elseif packagePreview then
		previewSize = 64
	end

	if data.VALOR == "item" then
		local itemWidget = g_ui.createWidget("Item", imageParent)

		itemWidget:setId("storeItem_" .. data.ID)
		itemWidget:setItemId(data.ID)
		itemWidget:setVirtual(true)
		itemWidget:setImageSource("")

		if detailLargePreview then
			itemWidget:setFixedItemSize(false)
			itemWidget:setPadding(0)

			local exactSize = g_gameConfig.getSpriteSize()
			local itemThing = itemWidget:getItem()

			if itemThing then
				exactSize = math.max(exactSize, itemThing:getExactSize())
			end

			itemWidget:setSize({
				width = exactSize * 2,
				height = exactSize * 2
			})
		elseif packagePreview then
			itemWidget:setFixedItemSize(false)
			itemWidget:setPadding(0)

			local exactSize = g_gameConfig.getSpriteSize()
			local itemThing = itemWidget:getItem()

			if itemThing then
				exactSize = math.max(exactSize, itemThing:getExactSize())
			end

			itemWidget:setSize({
				width = exactSize,
				height = exactSize
			})
		else
			itemWidget:setFixedItemSize(true)
			itemWidget:setSize({
				width = previewSize,
				height = previewSize
			})
		end

		itemWidget:addAnchor(AnchorHorizontalCenter, "parent", AnchorHorizontalCenter)
		itemWidget:addAnchor(AnchorVerticalCenter, "parent", AnchorVerticalCenter)
	elseif data.VALOR == "icon" then
		local widget = g_ui.createWidget("UIWidget", imageParent)

		widget:setId("storeIcon_" .. data.ID)
		setImagenHttp(widget, "/64/" .. data.ID, false)
		widget:setSize({
			width = previewSize,
			height = previewSize
		})

		if detailLargePreview then
			widget:setImageFixedRatio(false)
		end

		widget:addAnchor(AnchorHorizontalCenter, "parent", AnchorHorizontalCenter)
		widget:addAnchor(AnchorVerticalCenter, "parent", AnchorVerticalCenter)
	elseif data.VALOR == "mountId" or data.VALOR:find("outfitId") then
		local creature = g_ui.createWidget("StorePreviewCreature", imageParent)

		creature:setId("storeCreature_" .. data.ID)

		local outfit = {
			addons = 3,
			type = data.ID
		}

		if data.outfit then
			outfit.head = data.outfit.head or 0
			outfit.body = data.outfit.body or 0
			outfit.legs = data.outfit.legs or 0
			outfit.feet = data.outfit.feet or 0
		end

		creature:setOutfit(outfit)
		creature:getCreature():setStaticWalking(0)

		local widgetSize = previewSize

		if detailLargePreview then
			widgetSize = 128
		end

		creature:setSize({
			width = widgetSize,
			height = widgetSize
		})

		if data.isHireling then
			if detailLargePreview then
				creature:setCenter(false)
				creature:setFixedCreatureSize(false)
				creature:setCreatureSize(100)
				creature:setBaseScale(true)
			else
				creature:setFixedCreatureSize(true)
			end
		else
			creature:setCenter(true)
			creature:setFixedCreatureSize(true)
			creature:setBaseScale(true)
			creature:setIgnoreDisplacementShift(true)
		end

		creature:addAnchor(AnchorHorizontalCenter, "parent", AnchorHorizontalCenter)
		creature:addAnchor(AnchorVerticalCenter, "parent", AnchorVerticalCenter)
	end
end

local function configureTopCategoryFilter(comboBox, menuFilter)
	comboBox._suppressStoreFilterRequest = true

	local previousOption = comboBox.getCurrentOption and comboBox:getCurrentOption() or nil
	local previousText = previousOption and previousOption.text or "Show All"

	if not comboBox._storeFilterMousePressPatched then
		comboBox._storeFilterMousePressPatched = true
		comboBox._storeFilterBaseOnMousePress = comboBox.onMousePress

		function comboBox:onMousePress(mousePos, mouseButton)
			if self._showAllOnly then
				return true
			end

			if self._storeFilterBaseOnMousePress then
				return self._storeFilterBaseOnMousePress(self, mousePos, mouseButton)
			end

			return false
		end
	end

	comboBox:clearOptions()
	comboBox:addOption("Show All", -1)
	comboBox:setCurrentOption("Show All", true)

	local hasExtraCategories = type(menuFilter) == "table" and #menuFilter > 0

	if hasExtraCategories then
		local hasPreviousOption = previousText == "Show All"

		for index, categoryName in ipairs(menuFilter) do
			comboBox:addOption(categoryName, index - 1)

			if categoryName == previousText then
				hasPreviousOption = true
			end
		end

		if hasPreviousOption then
			comboBox:setCurrentOption(previousText, true)
		end

		comboBox._showAllOnly = false

		comboBox:setPhantom(false)
		comboBox:setEnabled(true)
		comboBox:setColor("#c0c0c0")
	else
		comboBox._showAllOnly = true

		comboBox:setPhantom(true)
		comboBox:setEnabled(true)
		comboBox:setOn(false)
		comboBox:setColor("#707070")
	end

	comboBox._suppressStoreFilterRequest = false
end

local function getStoreSortOrderFromUi()
	local sortCombo = controllerShop.ui and controllerShop.ui.panelItem.storeFilterBar.comboBoxContainer.MostPopularFirst

	if not sortCombo or not sortCombo.getCurrentOption then
		return 0
	end

	local current = sortCombo:getCurrentOption()
	local data = current and current.data or nil

	if data == "Alphabetically" then
		return 1
	elseif data == "NewestFirst" or data == "NewestFist" then
		return 2
	end

	return 0
end

local function requestStoreOffersFromFilters()
	if not controllerShop.ui then
		return
	end

	local selectedCategory = ""

	if controllerShop.ui.openedSubCategory and controllerShop.ui.openedSubCategory.open then
		selectedCategory = controllerShop.ui.openedSubCategory.open
	elseif controllerShop.ui.openedCategory and controllerShop.ui.openedCategory.open then
		selectedCategory = controllerShop.ui.openedCategory.open
	end

	if selectedCategory == "" or selectedCategory == "Home" then
		return
	end

	local showAllCombo = controllerShop.ui.panelItem.storeFilterBar.comboBoxContainer.showAll
	local showAllCurrent = showAllCombo and showAllCombo:getCurrentOption() or nil
	local selectedFilterText = showAllCurrent and showAllCurrent.text or "Show All"
	local selectedSubCategory = selectedFilterText ~= "Show All" and selectedFilterText or ""
	local sortOrder = getStoreSortOrderFromUi()

	g_game.requestStoreOffers(selectedCategory, selectedSubCategory, sortOrder, 1)
end

local function resetStoreFilterDefaults()
	if not controllerShop.ui then
		return
	end

	local comboContainer = controllerShop.ui.panelItem.storeFilterBar.comboBoxContainer
	local showAllCombo = comboContainer.showAll
	local sortCombo = comboContainer.MostPopularFirst

	if showAllCombo then
		showAllCombo._suppressStoreFilterRequest = true

		showAllCombo:setCurrentOption("Show All", true)

		showAllCombo._suppressStoreFilterRequest = false
	end

	if sortCombo then
		sortCombo._suppressStoreSortRequest = true

		sortCombo:setCurrentOption("Most Popular First", true)

		sortCombo._suppressStoreSortRequest = false
	end
end

local function normalizeStoreFilterToken(token)
	token = (token or ""):lower()

	if token:sub(-3) == "ies" then
		return token:sub(1, -4) .. "y"
	end

	if token:sub(-3) == "ves" then
		return token:sub(1, -4) .. "f"
	end

	if token:sub(-2) == "es" then
		return token:sub(1, -3)
	end

	if token:sub(-1) == "s" then
		return token:sub(1, -2)
	end

	return token
end

local function productMatchesSubCategoryFilter(product, selectedSubCategory)
	if not selectedSubCategory or selectedSubCategory == "" then
		return true
	end

	local needle = normalizeStoreFilterToken(selectedSubCategory)
	local collection = normalizeStoreFilterToken(product.collection)

	if collection ~= "" and (collection == needle or collection:find(needle, 1, true) or needle:find(collection, 1, true)) then
		return true
	end

	local haystack = string.format("%s %s", tostring(product.name or ""):lower(), tostring(product.description or ""):lower())

	if haystack:find(selectedSubCategory:lower(), 1, true) then
		return true
	end

	local hasAnyToken = false

	for token in tostring(selectedSubCategory):lower():gmatch("[%w]+") do
		if #token > 2 then
			hasAnyToken = true

			local normalized = normalizeStoreFilterToken(token)

			if not haystack:find(token, 1, true) and not haystack:find(normalized, 1, true) then
				return false
			end
		end
	end

	return hasAnyToken
end

local function getNewestRankForProduct(product)
	return tonumber(product.stateNewUntil) or 0
end

local function applyClientSideOfferFilters(offers, selectedSubCategory, sortOrder)
	offers = offers or {}

	local hasFilter = selectedSubCategory and selectedSubCategory ~= ""

	if not hasFilter and sortOrder == 0 then
		return offers
	end

	local filtered = {}

	if hasFilter then
		for _, product in ipairs(offers) do
			if productMatchesSubCategoryFilter(product, selectedSubCategory) then
				table.insert(filtered, product)
			end
		end
	else
		for _, product in ipairs(offers) do
			table.insert(filtered, product)
		end
	end

	if sortOrder == 1 then
		table.sort(filtered, function(a, b)
			return tostring(a.name or ""):lower() < tostring(b.name or ""):lower()
		end)
	elseif sortOrder == 2 then
		table.sort(filtered, function(a, b)
			local newestA, newestB = getNewestRankForProduct(a), getNewestRankForProduct(b)

			if newestA ~= newestB then
				return newestB < newestA
			end

			return tostring(a.name or ""):lower() < tostring(b.name or ""):lower()
		end)
	else
		table.sort(filtered, function(a, b)
			local popA, popB = tonumber(a.popularityScore) or 0, tonumber(b.popularityScore) or 0

			if popA ~= popB then
				return popB < popA
			end

			return tostring(a.name or ""):lower() < tostring(b.name or ""):lower()
		end)
	end

	return filtered
end

local function disableAllButtons()
	local panel = controllerShop.ui.panelItem
	local detail = getPanelItemDetailsContent(panel)

	if detail then
		local image = detail:getChildById("image")

		clearPendingHttpForChildren(image)

		local stack = detail:getChildById("StackOffers")

		if stack then
			stack:destroyChildren()
		end

		if image then
			image:destroyChildren()
		end
	end

	for i = 1, controllerShop.ui.listCategory:getChildCount() do
		local widget = controllerShop.ui.listCategory:getChildByIndex(i)

		if widget and widget.Button then
			widget.Button:setEnabled(false)

			if widget.subCategories then
				for subId, _ in ipairs(widget.subCategories) do
					local subWidget = widget:getChildById(subId)

					if subWidget and subWidget.Button then
						subWidget.Button:setEnabled(false)
					end
				end
			end
		end
	end

	offerDescriptions = {}
end

local updateSelectedCategoryTextColor

local function setCategoryButtonVisualState(widget, isSelected)
	if not widget or not widget.Button then
		return
	end

	local title = widget.Button.Title
	local icon = widget.Button.Icon

	if not title or not icon then
		return
	end

	if isSelected then
		icon:setMarginLeft(7)
		icon:setMarginTop(1)
		title:setTextOffset(topoint("1 1"))
	else
		icon:setMarginLeft(6)
		icon:setMarginTop(0)
		title:setTextOffset(topoint("0 1"))
	end
end

local function enableAllButtons()
	for i = 1, controllerShop.ui.listCategory:getChildCount() do
		local widget = controllerShop.ui.listCategory:getChildByIndex(i)

		if widget and widget.Button then
			widget.Button:setEnabled(true)

			if widget.subCategories then
				for subId, _ in ipairs(widget.subCategories) do
					local subWidget = widget:getChildById(subId)

					if subWidget and subWidget.Button then
						subWidget.Button:setEnabled(true)
					end
				end
			end
		end
	end

	local selectedSubCategory = controllerShop.ui.openedSubCategory

	if selectedSubCategory and selectedSubCategory:isVisible() then
		updateSelectedCategoryTextColor(nil, selectedSubCategory)
	else
		updateSelectedCategoryTextColor(controllerShop.ui.openedCategory, nil)
	end
end

function updateSelectedCategoryTextColor(selectedCategory, selectedSubCategory)
	for i = 1, controllerShop.ui.listCategory:getChildCount() do
		local widget = controllerShop.ui.listCategory:getChildByIndex(i)

		if widget and widget.Button and widget.Button.Title then
			widget.Button.Title:setColor("#c0c0c0")
			setCategoryButtonVisualState(widget, false)
		end

		if widget and widget.subCategories then
			for subId, _ in ipairs(widget.subCategories) do
				local subWidget = widget:getChildById(subId)

				if subWidget and subWidget.Button and subWidget.Button.Title then
					subWidget.Button.Title:setColor("#c0c0c0")
					setCategoryButtonVisualState(subWidget, false)
				end
			end
		end
	end

	if selectedCategory and selectedCategory.Button and selectedCategory.Button.Title then
		selectedCategory.Button.Title:setColor("#f4f4f4")
		setCategoryButtonVisualState(selectedCategory, true)
	end

	if selectedSubCategory and selectedSubCategory.Button and selectedSubCategory.Button.Title then
		selectedSubCategory.Button.Title:setColor("#f4f4f4")
		setCategoryButtonVisualState(selectedSubCategory, true)
	end
end

local function toggleSubCategories(parent, isOpen)
	if parent.SubCategoryRail then
		parent.SubCategoryRail:setVisible(isOpen)
	end

	for subId, _ in ipairs(parent.subCategories) do
		local subWidget = parent:getChildById(subId)

		if subWidget then
			subWidget:setVisible(isOpen)

			if subWidget.Button then
				subWidget.Button:setChecked(false)
			end

			if subWidget.ExternalArrow then
				subWidget.ExternalArrow:setVisible(false)
			end
		end
	end

	if isOpen then
		local sub1 = parent:getChildById(1)

		if sub1 and sub1.Button then
			sub1.Button:setChecked(true)

			if sub1.ExternalArrow then
				sub1.ExternalArrow:setVisible(true)
			end

			controllerShop.ui.openedSubCategory = sub1

			updateSelectedCategoryTextColor(nil, sub1)
		end
	else
		controllerShop.ui.openedSubCategory = nil
	end

	parent:setHeight(isOpen and parent.openedSize or parent.closedSize)

	parent.opened = isOpen

	parent.Button.Arrow:setVisible(not isOpen)
end

local function close(parent)
	if parent.subCategories then
		toggleSubCategories(parent, false)
	end
end

local function open(parent)
	local oldOpen = controllerShop.ui.openedCategory

	if oldOpen and oldOpen ~= parent then
		close(oldOpen)
	end

	toggleSubCategories(parent, true)

	controllerShop.ui.openedCategory = parent
end

local function closeCategoryButtons()
	if not controllerShop.ui or not controllerShop.ui.listCategory then
		return
	end

	for i = 1, controllerShop.ui.listCategory:getChildCount() do
		local widget = controllerShop.ui.listCategory:getChildByIndex(i)

		if widget and widget.subCategories then
			for subId, _ in ipairs(widget.subCategories) do
				local subWidget = widget:getChildById(subId)

				if subWidget then
					subWidget.Button:setChecked(false)

					if subWidget.ExternalArrow then
						subWidget.ExternalArrow:setVisible(false)
					end
				end
			end
		end
	end
end

local function clearSelectedStoreCategory()
	if not controllerShop.ui or not controllerShop.ui.listCategory then
		return
	end

	closeCategoryButtons()

	for i = 1, controllerShop.ui.listCategory:getChildCount() do
		local widget = controllerShop.ui.listCategory:getChildByIndex(i)

		if widget then
			if widget.subCategories and widget.opened then
				toggleSubCategories(widget, false)
			end

			if widget.Button then
				widget.Button:setChecked(false)
				widget.Button.Arrow:setVisible(widget.subCategoriesSize and widget.subCategoriesSize > 0 or false)
			end
		end
	end

	controllerShop.ui.openedCategory = nil
	controllerShop.ui.openedSubCategory = nil

	updateSelectedCategoryTextColor(nil, nil)
end

local function resetStoreUiOnClose()
	if not controllerShop.ui then
		return
	end

	controllerShop.ui.openedCategory = nil
	controllerShop.ui.openedSubCategory = nil

	updateSelectedCategoryTextColor(nil, nil)
	resetStoreFilterDefaults()

	local listProduct = controllerShop.ui.panelItem and controllerShop.ui.panelItem.listProduct

	if listProduct then
		for i = 1, listProduct:getChildCount() do
			local row = listProduct:getChildByIndex(i)

			if row then
				clearPendingHttpForChildren(row:getChildById("image"))
			end
		end

		listProduct:destroyChildren()
	end

	clearHomeProducts()

	local detail = getPanelItemDetailsContent(controllerShop.ui.panelItem)

	if detail then
		local image = detail:getChildById("image")
		local stack = detail:getChildById("StackOffers")

		if image then
			clearPendingHttpForChildren(image)
			image:destroyChildren()
			image:setImageSource("/images/ui/1pixel-down-frame")
		end

		if stack then
			stack:destroyChildren()
		end
	end

	if controllerShop.ui.listCategory then
		controllerShop.ui.listCategory:destroyChildren()
	end
end

local function syncSelectedCategoryByName(categoryName)
	if not controllerShop.ui or not categoryName or categoryName == "" then
		return
	end

	if categoryName == "Search" then
		return
	end

	local targetCategory, targetSubCategory

	for i = 1, controllerShop.ui.listCategory:getChildCount() do
		local categoryWidget = controllerShop.ui.listCategory:getChildByIndex(i)

		if categoryWidget then
			if categoryWidget.open == categoryName or categoryWidget:getId() == categoryName then
				targetCategory = categoryWidget

				break
			end

			if categoryWidget.subCategories then
				for subId, _ in ipairs(categoryWidget.subCategories) do
					local subWidget = categoryWidget:getChildById(subId)

					if subWidget and (subWidget.open == categoryName or subWidget.Button and subWidget.Button.Title and subWidget.Button.Title:getText() == categoryName) then
						targetCategory = categoryWidget
						targetSubCategory = subWidget

						break
					end
				end

				if targetCategory then
					break
				end
			end
		end
	end

	if not targetCategory then
		return
	end

	closeCategoryButtons()

	if controllerShop.ui.openedCategory and controllerShop.ui.openedCategory ~= targetCategory then
		close(controllerShop.ui.openedCategory)

		if controllerShop.ui.openedCategory.Button then
			controllerShop.ui.openedCategory.Button:setChecked(false)
		end
	end

	controllerShop.ui.openedCategory = targetCategory

	if targetCategory.subCategoriesSize then
		targetCategory.closedSize = 22
		targetCategory.openedSize = targetCategory.closedSize + targetCategory.subCategoriesSize * 20

		open(targetCategory)
	else
		targetCategory.Button:setChecked(true)
		targetCategory.Button.Arrow:setVisible(false)
	end

	if targetSubCategory then
		for subId, _ in ipairs(targetCategory.subCategories) do
			local sw = targetCategory:getChildById(subId)

			if sw and sw.Button then
				local sel = sw == targetSubCategory

				sw.Button:setChecked(sel)

				if sw.ExternalArrow then
					sw.ExternalArrow:setVisible(sel)
				end
			end
		end

		controllerShop.ui.openedSubCategory = targetSubCategory

		updateSelectedCategoryTextColor(nil, targetSubCategory)
	elseif targetCategory.subCategoriesSize then
		local firstSub = targetCategory:getChildById(1)

		controllerShop.ui.openedSubCategory = firstSub

		if firstSub then
			updateSelectedCategoryTextColor(nil, firstSub)
		end
	else
		controllerShop.ui.openedSubCategory = nil

		updateSelectedCategoryTextColor(targetCategory, nil)
	end
end

function showStoreAfterAuction()
	if not controllerShop.ui then
		return
	end

	restoreStoreAfterOverlay()

	local openedCategory = controllerShop.ui.openedCategory
	local isHomeCategory = openedCategory and (openedCategory:getId() == "Home" or openedCategory.open == "Home")

	if isHomeCategory then
		syncSelectedCategoryByName("Home")
		showPanel("HomePanel")

		local homeProductos = controllerShop.ui.HomePanel.HomeRecentlyAdded.HomeProductos

		if homeProductos and homeProductos:getChildCount() == 0 then
			g_game.sendRequestStoreHome()
		end
	elseif controllerShop.ui.panelItem:isVisible() or controllerShop.ui.openedCategory then
		showPanel("panelItem")
	else
		syncSelectedCategoryByName("Home")
		showPanel("HomePanel")
		g_game.sendRequestStoreHome()
	end
end

local function createSubWidget(parent, subId, subButton)
	local subWidget = g_ui.createWidget("storeCategory", parent)

	subWidget:setId(subId)
	subWidget:setImageSource("")
	subWidget:setSize("152 22")
	setImagenHttp(subWidget.Button.Icon, subButton.icon, true)
	subWidget.Button.Title:setText(subButton.text)
	subWidget:setVisible(false)

	subWidget.open = subButton.open

	subWidget.Button:setSize("152 20")
	subWidget.Button:addAnchor(AnchorTop, "parent", AnchorTop)
	subWidget.Button:addAnchor(AnchorRight, "parent", AnchorRight)
	subWidget.Button:setMarginTop(1)
	subWidget.Button:setMarginRight(0)
	subWidget.Button:setMarginLeft(0)
	subWidget.Button.Arrow:setVisible(false)

	local arrow = g_ui.createWidget("UIWidget", parent)

	arrow:setId("arrow_" .. subId)
	arrow:setSize("7 7")
	arrow:setPhantom(true)
	arrow:setImageSource("/images/ui/icon-arrow7x7-right")
	arrow:setVisible(false)
	arrow:addAnchor(AnchorVerticalCenter, tostring(subId), AnchorVerticalCenter)
	arrow:addAnchor(AnchorLeft, "parent", AnchorLeft)
	arrow:setMarginLeft(3)

	subWidget.ExternalArrow = arrow

	function subWidget.Button.onClick()
		waitingInitialHome = false

		disableAllButtons()
		resetStoreFilterDefaults()

		local selectedOption = controllerShop.ui.selectedOption

		closeCategoryButtons()
		parent.Button:setChecked(false)
		parent.Button.Arrow:setVisible(false)
		subWidget.Button:setChecked(true)
		subWidget.ExternalArrow:setVisible(true)
		updateSelectedCategoryTextColor(nil, subWidget)

		controllerShop.ui.openedSubCategory = subWidget

		if selectedOption then
			selectedOption:hide()
		end

		if subWidget.open == "Home" then
			g_game.sendRequestStoreHome()
		else
			g_game.requestStoreOffers(subButton.text, "", 0, 1)
		end
	end

	if subId == 1 then
		subWidget:addAnchor(AnchorRight, "parent", AnchorRight)
		subWidget:addAnchor(AnchorTop, "parent", AnchorTop)
		subWidget:setMarginTop(20)
		subWidget:setMarginRight(1)
	else
		subWidget:addAnchor(AnchorRight, "parent", AnchorRight)
		subWidget:addAnchor(AnchorTop, tostring(subId - 1), AnchorBottom)
		subWidget:setMarginTop(-1)
		subWidget:setMarginRight(1)
	end

	return subWidget
end

local function createSubCategoryRail(parent)
	if parent.SubCategoryRail or not parent.subCategoriesSize or parent.subCategoriesSize <= 0 then
		return
	end

	local rail = g_ui.createWidget("UIWidget", parent)

	rail:setId("SubCategoryRail")
	rail:setSize(string.format("12 %d", parent.subCategoriesSize * 20))
	rail:setPhantom(true)
	rail:setImageSource("/game_store/images/container-arrow")
	rail:setImageBorder(5)
	rail:addAnchor(AnchorLeft, "parent", AnchorLeft)
	rail:addAnchor(AnchorTop, "parent", AnchorTop)
	rail:setMarginLeft(1)
	rail:setMarginTop(21)
	rail:setVisible(false)

	parent.SubCategoryRail = rail
end

local function updateSearchClearButtonVisual()
	if not controllerShop.ui then
		return
	end

	local edit = controllerShop.ui.SearchEdit
	local btn = controllerShop.ui.SearchClearButton

	if not edit or not btn then
		return
	end

	if (edit:getText() or ""):trim() == "" then
		btn:setImageClip("0 40 20 20")
		btn:setEnabled(false)
	else
		btn:setImageClip("0 0 20 20")
		btn:setEnabled(true)
	end
end

controllerShop = Controller:new()

g_ui.importStyle("style/ui.otui")
g_ui.importStyle("style/auctioncharacter.otui")
controllerShop:setUI("game_store")

function controllerShop:onInit()
	controllerShop.ui:hide()

	for k, v in pairs({
		{
			"Most Popular First",
			"MostPopularFirst"
		},
		{
			"Alphabetically",
			"Alphabetically"
		},
		{
			"Newest First",
			"NewestFirst"
		}
	}) do
		controllerShop.ui.panelItem.storeFilterBar.comboBoxContainer.MostPopularFirst:addOption(v[1], v[2])
	end

	function controllerShop.ui.panelItem.storeFilterBar.comboBoxContainer.showAll.onOptionChange(widget, text, data)
		if widget._suppressStoreFilterRequest then
			return
		end

		requestStoreOffersFromFilters()
	end

	function controllerShop.ui.panelItem.storeFilterBar.comboBoxContainer.MostPopularFirst.onOptionChange(widget, text, data)
		if widget._suppressStoreSortRequest then
			return
		end

		requestStoreOffersFromFilters()
	end

	controllerShop.ui.transferPoints.onClick = transferPoints
	controllerShop.ui.panelItem.listProduct.onChildFocusChange = chooseOffert
	controllerShop.ui.HomePanel.HomeRecentlyAdded.HomeProductos.onChildFocusChange = chooseHome

	local homeBanner = getHomeBannerWidget()

	if homeBanner then
		homeBanner.onClick = onClickHomeBanner
	end

	function controllerShop.ui.SearchEdit.onKeyDown(widget, keyCode, keyboardModifiers)
		if g_keyboard.isEnterKey(keyCode) then
			search()

			return true
		end

		return false
	end

	function controllerShop.ui.SearchEdit.onTextChange()
		updateSearchClearButtonVisual()
	end

	do
		local btn = controllerShop.ui.SearchClearButton

		function btn.onMousePress(widget, mousePos, mouseButton)
			if not widget:isEnabled() then
				return
			end

			if mouseButton == MouseLeftButton then
				widget:setImageClip("0 20 20 20")
			end
		end

		function btn.onMouseRelease(widget, mousePos, mouseButton)
			updateSearchClearButtonVisual()
		end

		function btn.onClick()
			if not btn:isEnabled() then
				return
			end

			controllerShop.ui.SearchEdit:setText("")
			search()
			updateSearchClearButtonVisual()
		end
	end

	updateSearchClearButtonVisual()
	controllerShop:registerEvents(g_game, {
		onParseStoreGetCoin = onParseStoreGetCoin,
		onParseStoreGetCategories = onParseStoreGetCategories,
		onParseStoreCreateHome = onParseStoreCreateHome,
		onParseStoreCreateProducts = onParseStoreCreateProducts,
		onParseStoreGetHistory = onParseStoreGetHistory,
		onParseStoreGetPurchaseStatus = onParseStoreGetPurchaseStatus,
		onParseStoreOfferDescriptions = onParseStoreOfferDescriptions,
		onParseStoreError = onParseStoreError,
		onParseStoreRequestPurchaseData = onParseStoreRequestPurchaseData,
		onHirelingNameChange = onHirelingNameChange,
		onStoreInit = onStoreInit,
		onAuctionCharacterCheckRequirements = onAuctionCharacterCheckRequirements,
		onAuctionCharacterItemsInventory = onAuctionCharacterItemsInventory,
		onAuctionCharacterItemsStore = onAuctionCharacterItemsStore,
		onAuctionCharacterArguments = onAuctionCharacterArguments
	})
end

function controllerShop:onGameStart()
	oldProtocol = g_game.getClientVersion() < 1310
end

function controllerShop:onGameEnd()
	if controllerShop.ui then
		hide()
	end

	resetStoreSessionFlags()
	clearPurchaseCompleteModalEvents(messageBox)
	releasePurchaseCompleteModalRefs(messageBox)
	destroyWindow({
		transferPointsWindow,
		changeNameWindow,
		worldTransferWindow,
		hirelingNameWindow,
		acceptWindow,
		processingWindow,
		messageBox,
		checksAuctionCharacterWindow,
		configAuctionCharacterWindow
	})

	transferPointsWindow = nil
	changeNameWindow = nil
	worldTransferWindow = nil
	hirelingNameWindow = nil
	acceptWindow = nil
	processingWindow = nil
	messageBox = nil
	checksAuctionCharacterWindow = nil
	configAuctionCharacterWindow = nil
	auctionCharacterWindowStep = 0
end

function controllerShop:onTerminate()
	destroyWindow({
		transferPointsWindow,
		changeNameWindow,
		worldTransferWindow,
		hirelingNameWindow,
		acceptWindow,
		processingWindow,
		messageBox,
		checksAuctionCharacterWindow,
		configAuctionCharacterWindow
	})

	checksAuctionCharacterWindow = nil
	configAuctionCharacterWindow = nil
	auctionCharacterWindowStep = 0
end

function onStoreInit(url, coinsPacketSize)
	-- A server configured with 127.0.0.1 would otherwise make every remote
	-- player download Store images from their own computer. Keep valid public
	-- URLs untouched and replace only a loopback hostname with the login host.
	local storeHostname = type(url) == "string" and url:match("^https?://([^/:]+)") or nil
	if storeHostname == "127.0.0.1" or storeHostname == "localhost" then
		local configuredHost = G and (G.host or G.loginHost) or nil
		local loginHostname = configuredHost and (configuredHost:match("^https?://([^/:]+)") or configuredHost:match("^([^/:]+)")) or nil

		if loginHostname and loginHostname ~= "" and loginHostname ~= "127.0.0.1" and loginHostname ~= "localhost" then
			url = url:gsub("^(https?://)[^/:]+", "%1" .. loginHostname, 1)
			g_logger.info("Store image URL adjusted to the connected server: " .. url)
		end
	end

	GameStore.website.IMAGES_URL = url
end

function onParseStoreGetCoin(getTibiaCoins, getTransferableCoins)
	a0xF2 = false

	controllerShop.ui.lblCoins.lblTibiaCoins:setText(formatNumberWithCommas(getTibiaCoins))
	controllerShop.ui.lblCoins.lblTibiaTransfer:setText(string.format("(Including: %s", formatNumberWithCommas(getTransferableCoins)))
	updateAuctionCharacterTransferableBalance()
end

function onParseStoreOfferDescriptions(offerId, description)
	cacheOfferDescription(offerId, description)
	addEvent(function()
		if not controllerShop.ui or not controllerShop.ui.panelItem then
			return
		end

		local listProduct = controllerShop.ui.panelItem.listProduct

		if not listProduct then
			return
		end

		local focusedChild = listProduct:getFocusedChild()

		if focusedChild and focusedChild.product and offerIdBelongsToProduct(focusedChild.product, offerId) then
			chooseOffert(listProduct, focusedChild)
		end
	end)
end

function onParseStoreGetPurchaseStatus(purchaseStatus)
	clearPurchaseCompleteModalEvents(messageBox)
	destroyWindow({
		processingWindow,
		messageBox
	})
	hideStoreForOverlay()

	messageBox = g_ui.createWidget("confirmarSHOP", g_ui.getRootWidget())

	if not messageBox then
		restoreStoreAfterOverlay()

		return
	end

	local statusText = purchaseStatus

	if not statusText or statusText == "" then
		statusText = tr("Purchase completed successfully.")
	end

	local boxLabel = messageBox:recursiveGetChildById("Box")

	if boxLabel then
		boxLabel:setTextAutoResize(true)
		boxLabel:setTextWrap(true)
		boxLabel:setWidth(192)
		boxLabel:setText(statusText)

		if boxLabel.resizeToText then
			boxLabel:resizeToText()
		end

		if boxLabel.setTextAlign then
			boxLabel:setTextAlign(AlignTopLeft)
		end
	end

	local dragonHeader = messageBox:recursiveGetChildById("dragonHeader")

	if dragonHeader then
		dragonHeader:raise()
	end

	g_modalManager.show(messageBox)

	function messageBox.onEscape()
		closePurchaseSuccessModal(messageBox)
	end

	local buttonAnimation = messageBox:recursiveGetChildById("buttonAnimation")

	if buttonAnimation then
		function buttonAnimation.onClick()
			if not messageBox or messageBox:isDestroyed() then
				return
			end

			buttonAnimation:disable()

			local anim = buttonAnimation:getChildById("animation")

			if anim and not anim:isDestroyed() then
				anim:setImageSource("/images/animations/animation-purchasecomplete-pressed")
			end

			if messageBox._closeEvent then
				removeEvent(messageBox._closeEvent)
			end

			messageBox._closeEvent = controllerShop:scheduleEvent(function()
				messageBox._closeEvent = nil

				closePurchaseSuccessModal(messageBox)
			end, 2000)
		end
	end
end

function onParseStoreCreateProducts(storeProducts)
	local windowType = tonumber(storeProducts.windowType) or storeProducts.categoryName == "Search" and 2 or 0

	if windowType == 3 then
		return onParseStoreCreateHome(storeProducts)
	end

	if waitingInitialHome and windowType == 0 and not storeRedirectAwaitingOffers then
		return
	end

	if storeRedirectAwaitingOffers and (windowType == 0 or windowType == 2) then
		waitingInitialHome = false

		local redirectId = tonumber(storeProducts.redirectId) or 0

		if redirectId <= 0 and storeProducts.categoryName == "Exclusive Offers" then
			return
		end

		storeRedirectAwaitingOffers = false

		showPanel("panelItem")
	end

	local comboBox = controllerShop.ui.panelItem.storeFilterBar.comboBoxContainer.showAll

	configureTopCategoryFilter(comboBox, storeProducts.menuFilter)

	reasonCategory = storeProducts.disableReasons

	syncSelectedCategoryByName(storeProducts.categoryName)

	local listProduct = controllerShop.ui.panelItem.listProduct

	for i = 1, listProduct:getChildCount() do
		local row = listProduct:getChildByIndex(i)

		if row then
			clearPendingHttpForChildren(row:getChildById("image"))
		end
	end

	listProduct:destroyChildren()

	if not storeProducts then
		return
	end

	local showAllCombo = controllerShop.ui.panelItem.storeFilterBar.comboBoxContainer.showAll
	local selectedOption = showAllCombo and showAllCombo:getCurrentOption() or nil
	local selectedFilterText = selectedOption and selectedOption.text or "Show All"
	local selectedSubCategory = selectedFilterText ~= "Show All" and selectedFilterText or ""
	local sortOrder = getStoreSortOrderFromUi()
	local productsToRender = applyClientSideOfferFilters(storeProducts.offers, selectedSubCategory, sortOrder)

	for _, product in ipairs(productsToRender) do
		local subOffersProbe = product.subOffers or {
			product
		}
		local rowDisabled = false

		for _, so in ipairs(subOffersProbe) do
			if so.disabled then
				rowDisabled = true

				break
			end
		end

		local row = g_ui.createWidget(rowDisabled and STORE_ROW_UNAVAILABLE or STORE_ROW_AVAILABLE, listProduct)

		bindRowHoverBorder(row, false)

		row.product, row.type = product, product.type

		local nameLabel = row:getChildById("lblName")

		nameLabel:setText(product.name)
		nameLabel:setTextAlign(AlignTopLeft)
		nameLabel:setMarginRight(4)
		nameLabel:setHeight(34)
		applyOfferStateVisuals(row, product)

		local subOffers = product.subOffers or {
			product
		}
		local validSubOffers = {}

		for _, so in ipairs(subOffers) do
			if not so.id or so.id ~= 0 then
				table.insert(validSubOffers, so)
			end
		end

		for i, subOffer in ipairs(subOffers) do
			if subOffer.id and subOffer.id == 0 then
				-- block empty
			else
				local offerI = g_ui.createWidget("stackOfferPanel", row:getChildById("StackOffers"))

				offerI.offerId = subOffer.id

				if subOffer.disabled then
					offerI:disable()
				end

				local priceLabel = offerI:getChildById("lblPrice")

				priceLabel:setText(formatNumberWithCommas(tonumber(subOffer.price) or 0))

				local shouldShowCount = #validSubOffers > 1 or (subOffer.count or 1) > 1

				if shouldShowCount and subOffer.count and subOffer.count > 0 then
					offerI:getChildById("count"):setText(subOffer.count .. "x")
				else
					offerI:getChildById("count"):setText("")
				end

				fixServerNoSend0xF2()

				local coinsBalance2, coinsBalance1 = getCoinsBalance()
				local isTransferable = subOffer.coinType == GameStore.CoinType.Transferable
				local price = subOffer.price
				local balance = isTransferable and coinsBalance1 or coinsBalance2

				priceLabel:setColor("#c0c0c0")

				if isTransferable then
					priceLabel:setIcon("/images/icons/icon-tibiacointransferable")
				end
			end
		end

		local data = getProductData(product)

		if data then
			createProductImage(row:getChildById("image"), data)
		end
	end

	controllerShop:scheduleEvent(function()
		local focusId = pendingStoreFocusOfferId or storeProducts.redirectId

		if focusStoreOffer(listProduct, focusId) then
			pendingStoreFocusOfferId = nil
		elseif storeProducts.redirectId and storeProducts.redirectId ~= 0 then
			focusStoreOffer(listProduct, storeProducts.redirectId)

			pendingStoreFocusOfferId = nil
		else
			local firstChild = listProduct:getFirstChild()

			if firstChild and firstChild:isEnabled() then
				listProduct:focusChild(firstChild)
				listProduct:ensureChildVisible(firstChild)
			end
		end

		local focusedChild = listProduct:getFocusedChild()

		if focusedChild then
			chooseOffert(listProduct, focusedChild)
		end
	end, 300, "onParseStoreOfferDescriptionsSafeDelay")
	enableAllButtons()
	showPanel("panelItem")
	fixServerNoSend0xF2()
end

function onParseStoreCreateHome(offer)
	waitingInitialHome = false

	if storeRedirectAwaitingOffers then
		storeRedirectAwaitingOffers = false
		pendingStoreFocusOfferId = nil

		showPanel("panelItem")

		return
	end

	syncSelectedCategoryByName("Home")

	local homeProductos = controllerShop.ui.HomePanel.HomeRecentlyAdded.HomeProductos

	clearHomeProducts()

	for i, product in ipairs(offer.offers) do
		local subOffersProbe = product.subOffers or {
			product
		}
		local rowDisabled = false

		for _, so in ipairs(subOffersProbe) do
			if so.disabled then
				rowDisabled = true

				break
			end
		end

		local row = g_ui.createWidget(rowDisabled and STORE_ROW_UNAVAILABLE or STORE_ROW_AVAILABLE, homeProductos)

		bindRowHoverBorder(row, false, false)
		row:setSize("250 78")

		if i % 2 == 1 then
			row:setMarginLeft(2)
			row:setMarginTop(2)
			row:setMarginRight(5)
			row:setMarginBottom(2)
		else
			row:setMarginLeft(5)
			row:setMarginTop(2)
			row:setMarginBottom(2)
		end

		row.product, row.type = product, product.type

		local nameLabel = row:getChildById("lblName")

		nameLabel:setText(product.name)
		nameLabel:setTextAlign(AlignTopLeft)
		nameLabel:setMarginRight(10)
		applyOfferStateVisuals(row, product)

		local stackOffers = row:getChildById("StackOffers")

		stackOffers:destroyChildren()

		local subOffers = product.subOffers or {
			product
		}
		local validSubOffers = {}

		for _, subOffer in ipairs(subOffers) do
			if not subOffer.id or subOffer.id ~= 0 then
				table.insert(validSubOffers, subOffer)
			end
		end

		local visibleSubOffers = 0

		for _, subOffer in ipairs(validSubOffers) do
			local subOfferWidget = g_ui.createWidget("stackOfferPanel", stackOffers)

			subOfferWidget.lblPrice:setText(formatNumberWithCommas(tonumber(subOffer.price) or 0))

			local shouldShowCount = #validSubOffers > 1 or (subOffer.count or 1) > 1

			if shouldShowCount and subOffer.count and subOffer.count > 0 then
				subOfferWidget.count:setText(subOffer.count .. "x")
			else
				subOfferWidget.count:setText("")
			end

			if subOffer.coinType == GameStore.CoinType.Transferable then
				subOfferWidget.lblPrice:setIcon("/images/icons/icon-tibiacointransferable")
			else
				subOfferWidget.lblPrice:setIcon("/images/icons/icon-tibiacoin")
			end

			visibleSubOffers = visibleSubOffers + 1
		end

		stackOffers:setHeight(math.max(20, visibleSubOffers * 24))

		local data = getProductData(product)

		if data then
			createProductImage(row:getChildById("image"), data)
		end
	end

	function homeProductos.onMouseMove(widget, mousePos)
		updateHomeHoveredRow(widget, mousePos)

		return false
	end

	function homeProductos.onHoverChange(widget, hovered)
		if hovered then
			updateHomeHoveredRow(widget, g_window.getMousePosition())

			return
		end

		for _, row in ipairs(widget:getChildren()) do
			row._isHovered = false

			refreshRowHoverBorder(row)
		end
	end

	bannersHome = table.copy(offer.banners or {})

	if #bannersHome > 0 then
		currentIndex = math.random(1, #bannersHome)

		local homeBanner = getHomeBannerWidget()

		if homeBanner then
			setImagenHttp(homeBanner, bannersHome[currentIndex].image, false)
		end
	end

	enableAllButtons()
	showPanel("HomePanel")
	fixServerNoSend0xF2()
end

function onParseStoreGetHistory(currentPage, pageCount, historyData)
	local transferHistory = controllerShop.ui.transferHistory.historyPanel

	transferHistory:destroyChildren()
	controllerShop.ui.transferHistory.lblPage:setText(string.format("Page %d/%d", currentPage + 1, pageCount))
	controllerShop.ui.transferHistory.btnPrevPage:setVisible(currentPage > 0)
	controllerShop.ui.transferHistory.btnNextPage:setVisible(pageCount > currentPage + 1)

	for i, data in ipairs(historyData) do
		local row = g_ui.createWidget("StoreHistoryData", transferHistory)

		row._normalBackground = i % 2 == 1 and HISTORY_ROW_COLOR_A or HISTORY_ROW_COLOR_B

		row:setBackgroundColor(row._normalBackground)

		function row.onFocusChange(widget, focused)
			widget:setBackgroundColor(focused and HISTORY_ROW_COLOR_SELECTED or widget._normalBackground)
			widget.date:setColor(focused and "#f4f4f4" or "#c0c0c0")
			widget.Description:setColor(focused and "#f4f4f4" or "#c0c0c0")
		end

		row.date:setText(convert_timestamp(data[1]))
		row.date:setColor("#c0c0c0")

		local balance = data[3]
		local balanceText = formatNumberWithCommas(balance)

		if balance > 0 then
			balanceText = "+" .. balanceText
		end

		row.Balance:setText(balanceText)
		row.Balance:setColor(balance < 0 and "#D33C3C" or "#44ad25")
		row.Description:setText(data[5])
		row.Description:setColor("#c0c0c0")
		row.Balance:setIcon(data[4] == GameStore.CoinType.Transferable and "/images/icons/icon-tibiacointransferable" or "/images/icons/icon-tibiacoin")
	end

	clearSelectedStoreCategory()
	showPanel("transferHistory")
end

function onParseStoreGetCategories(buttons)
	if controllerShop.ui.listCategory:getChildCount() > 0 then
		if pendingStoreRedirect then
			addEvent(function()
				executePendingStoreRedirect()
			end)
		end

		return
	end

	controllerShop.ui.listCategory:destroyChildren()

	local categories = {}
	local categoryOrder = {}

	if not oldProtocol then
		local homeCategory = {
			state = 0,
			name = "Home",
			subCategories = {},
			icons = {
				[1] = "icon-store-home.png"
			}
		}

		categories.Home = homeCategory

		table.insert(categoryOrder, "Home")
	end

	local subcategories = {}

	for _, button in ipairs(buttons) do
		if not button.parent then
			categories[button.name] = button
			categories[button.name].subCategories = {}

			table.insert(categoryOrder, button.name)
		else
			table.insert(subcategories, button)
		end
	end

	for _, subcat in ipairs(subcategories) do
		if categories[subcat.parent] then
			table.insert(categories[subcat.parent].subCategories, subcat)
		end
	end

	for _, categoryName in ipairs(categoryOrder) do
		local category = categories[categoryName]
		local widget = g_ui.createWidget("storeCategory", controllerShop.ui.listCategory)

		widget:setId(category.name)

		if category.icons[1] == "icon-store-home.png" then
			widget.Button.Icon:setIcon("/game_store/images/icon-store-home")
		else
			setImagenHttp(widget.Button.Icon, "/13/" .. category.icons[1], true)
		end

		widget.Button.Title:setText(category.name)

		widget.open = category.name

		if #category.subCategories > 0 then
			widget.subCategories = category.subCategories
			widget.subCategoriesSize = #category.subCategories

			widget.Button.Arrow:setVisible(true)
			createSubCategoryRail(widget)

			for subId, subButton in ipairs(category.subCategories) do
				local subWidget = createSubWidget(widget, subId, {
					text = subButton.name,
					icon = "/13/" .. subButton.icons[1],
					open = subButton.name
				})
			end
		end

		widget:setMarginTop(10)

		function widget.Button.onClick()
			waitingInitialHome = false

			disableAllButtons()
			resetStoreFilterDefaults()

			local parent = widget
			local oldOpen = controllerShop.ui.openedCategory
			local panel = controllerShop.ui.panelItem
			local detail = getPanelItemDetailsContent(panel)

			if detail then
				local image = detail:getChildById("image")
				local stack = detail:getChildById("StackOffers")

				if image then
					clearPendingHttpForChildren(image)
					image:destroyChildren()
					image:setImageSource("/images/ui/1pixel-down-frame")
				end

				if stack then
					stack:destroyChildren()
				end
			end

			if oldOpen and oldOpen ~= parent then
				if oldOpen.Button then
					oldOpen.Button:setChecked(false)
					oldOpen.Button.Arrow:setImageSource("/images/ui/icon-arrow7x7-down")
				end

				close(oldOpen)
			end

			if parent.subCategoriesSize then
				parent.closedSize = 22
				parent.openedSize = parent.closedSize + parent.subCategoriesSize * 20

				open(parent)
			else
				widget.Button:setChecked(true)
				widget.Button.Arrow:setImageSource("/images/ui/icon-arrow7x7-right")
				widget.Button.Arrow:setVisible(false)

				controllerShop.ui.openedSubCategory = nil

				updateSelectedCategoryTextColor(widget, nil)
			end

			if controllerShop.ui.selectedOption then
				controllerShop.ui.selectedOption:hide()
			end

			if category.name == "Home" then
				clearHomeProducts()
				g_game.sendRequestStoreHome()
			else
				g_game.requestStoreOffers(category.name, "", 0, 1)
			end

			controllerShop.ui.openedCategory = parent
		end
	end

	local firstCategory = controllerShop.ui.listCategory:getChildByIndex(1)

	if pendingStoreRedirect then
		addEvent(function()
			executePendingStoreRedirect()
		end)
	elseif controllerShop.ui.openedCategory == nil and firstCategory then
		controllerShop.ui.openedCategory = firstCategory

		firstCategory.Button:onClick()
	end
end

function onParseStoreError(errorMessage, errorType)
	pendingStoreRedirect = nil
	storeRedirectAwaitingOffers = false
	pendingStoreFocusOfferId = nil
	waitingInitialHome = false

	enableAllButtons()
	destroyWindow({
		processingWindow,
		acceptWindow,
		messageBox
	})
	hideStoreForOverlay()

	local errorBox

	local function okCallback()
		destroyWindow({
			errorBox
		})
		enableAllButtons()
		recoverStoreOpenEnvironment()
		restoreStoreAfterOverlay()
		fixServerNoSend0xF2()
	end

	errorBox = displayGeneralBox(controllerShop.ui:getText(), errorMessage, {
		{
			text = tr("Ok"),
			callback = okCallback
		}
	}, okCallback, okCallback)

	g_modalManager.show(errorBox)
end

function onParseStoreRequestPurchaseData(offerId, offerType, data)
	destroyWindow(processingWindow)

	processingWindow = nil

	restoreStoreAfterOverlay()

	if offerType == GameStore.ClientOfferTypes.CLIENT_STORE_OFFER_NAMECHANGE then
		displayChangeName(offerId)
	elseif offerType == GameStore.ClientOfferTypes.CLIENT_STORE_OFFER_WORLD_TRANSFER then
		displayWorldTransfer(offerId, data)
	elseif offerType == GameStore.ClientOfferTypes.CLIENT_STORE_OFFER_HIRELING then
		displayHirelingName(offerId)
	end
end

function hide()
	if not controllerShop.ui then
		return
	end

	cancelStoreWatchdogEvent()
	resetStoreLuaFlags()
	resetStoreUiOnClose()
	g_modalManager.hide(controllerShop.ui)
	controllerShop.ui:hide()
end

function toggle()
	if not controllerShop.ui then
		return
	end

	recoverStoreOpenEnvironment()

	if controllerShop.ui:isVisible() then
		local isModal = g_modalManager.isModal(controllerShop.ui)

		if isModal and not storeHiddenForOverlay then
			return hide()
		end

		g_modalManager.hide(controllerShop.ui)
		controllerShop.ui:hide()

		storeHiddenForOverlay = false
	end

	show()
end

function show()
	if not controllerShop.ui then
		return
	end

	gameOpenStore()
end

function gameOpenStore(skipHomeRequest)
	if not controllerShop.ui then
		return
	end

	recoverStoreOpenEnvironment()

	if skipHomeRequest or pendingStoreRedirect then
		waitingInitialHome = false
	end

	showStoreWindow()
	g_game.openStore()

	if not skipHomeRequest and controllerShop.ui.listCategory:getChildCount() > 0 then
		waitingInitialHome = true

		syncSelectedCategoryByName("Home")
		g_game.sendRequestStoreHome()
	end

	if not skipHomeRequest and not pendingStoreRedirect then
		controllerShop:scheduleEvent(function()
			if pendingStoreRedirect then
				return
			end

			if not controllerShop.ui or not controllerShop.ui:isVisible() then
				return
			end

			if controllerShop.ui.listCategory:getChildCount() == 0 then
				g_game.sendRequestStoreHome()

				local packet1 = GameStore.RecivedPackets.C_OpenStore

				g_logger.warning(string.format("[game_store BUG] Check 0x%X (%d) L827", packet1, packet1))
			end
		end, 1000, STORE_WATCHDOG_EVENT)
	end
end

function executePendingStoreRedirect()
	if not pendingStoreRedirect then
		return
	end

	if not controllerShop.ui or controllerShop.ui.listCategory:getChildCount() == 0 then
		return
	end

	local pending = pendingStoreRedirect

	pendingStoreRedirect = nil
	waitingInitialHome = false

	pending.requestFn()
end

local function openStoreRedirect(label, requestFn, delay, focusOfferId)
	if not controllerShop.ui or not requestFn then
		return
	end

	pendingStoreRedirect = {
		label = label,
		requestFn = requestFn
	}

	local categoriesReady = controllerShop.ui.listCategory:getChildCount() > 0

	prepareStoreRedirectUi(focusOfferId)

	if not categoriesReady then
		g_game.openStore()

		delay = delay or 300
	else
		delay = delay or 50
	end

	controllerShop:scheduleEvent(function()
		executePendingStoreRedirect()
	end, delay, "openStoreRedirect_" .. tostring(label))
end

function openOfferById(offerId)
	if not offerId or offerId <= 0 then
		return
	end

	openStoreRedirect("offerById:" .. offerId, function()
		g_game.sendRequestStoreOfferById(offerId)
	end, nil, offerId)
end

function openPremiumBoost()
	openStoreRedirect("premiumBoost", function()
		g_game.sendRequestStorePremiumBoost()
	end, nil, 5)
end

local USEFUL_THINGS_FOCUS_OFFERS = {
	[0] = 582,
	583,
	579,
	570,
	652,
	654,
	655,
	653,
	656,
	657,
	658,
	492,
	651,
	581
}

function openUsefulThings(offerId)
	offerId = offerId or 0

	openStoreRedirect("usefulThings:" .. tostring(offerId), function()
		g_game.sendRequestUsefulThings(offerId)
	end, nil, USEFUL_THINGS_FOCUS_OFFERS[offerId])
end

function openWeeklyTaskExpansion()
	openUsefulThings(StoreConst.WeeklyTaskExpansion)
end

function openCharmExpansion()
	openUsefulThings(StoreConst.CharmExpansion)
end

function openCharmPoints()
	openOfferById(StoreConst.MajorCharmPoints)
end

function openHirelingSexChange()
	openOfferById(269)
end

function openStoreCategory(categoryName, subCategory, sortOrder, serviceType)
	if not categoryName or categoryName == "" then
		return
	end

	openStoreRedirect("category:" .. categoryName, function()
		g_game.requestStoreOffers(categoryName, subCategory or "", sortOrder or 0, serviceType or 0)
	end)
end

function getCoinsWebsite()
	if GameStore.website.WEBSITE_GETCOINS ~= "" then
		g_platform.openUrl(GameStore.website.WEBSITE_GETCOINS)
	else
		sendMessageBox("Error", "No data for store URL.")
	end
end

function toggleTransferHistory()
	if controllerShop.ui.transferHistory:isVisible() then
		if controllerShop.ui.openedCategory and controllerShop.ui.openedCategory:getId() == "Home" then
			showPanel("HomePanel")
		else
			showPanel("panelItem")
		end
	else
		clearSelectedStoreCategory()
		g_game.openTransactionHistory(HISTORY_ENTRIES_PER_PAGE)
	end
end

function requestTransactionHistory(widget)
	local currentPage, pageCount = getPageLabelHistory()
	local newPage = currentPage + (widget:getId() == "btnNextPage" and 1 or -1)

	if newPage > 0 and newPage <= pageCount then
		g_game.requestTransactionHistory(newPage - 1, HISTORY_ENTRIES_PER_PAGE)
	end
end

local function setOfferPanelPriceRow(offerPanel, offer, coinsBalance2, coinsBalance1)
	local pricePanel = offerPanel:getChildById("lblPrice")

	if not pricePanel then
		return
	end

	local row = pricePanel:getChildById("lblPriceRow")

	if not row then
		return
	end

	local priceText = row:getChildById("lblPriceText")
	local priceCoin = row:getChildById("lblPriceCoin")
	local isTransferable = offer.coinType == GameStore.CoinType.Transferable
	local currentBalance = isTransferable and coinsBalance1 or coinsBalance2
	local priceVal = tonumber(offer.price) or 0

	if priceText then
		priceText:setText(formatNumberWithCommas(priceVal))
		priceText:setColor("#c0c0c0")
	end

	if priceCoin then
		if isTransferable then
			priceCoin:setImageSource("/images/icons/icon-tibiacointransferable")
		else
			priceCoin:setImageSource("/images/icons/icon-tibiacoin")
		end

		priceCoin:setImageFixedRatio(true)
		priceCoin:setVisible(true)
	end

	local btnBuy = offerPanel:getChildById("btnBuy")

	if btnBuy then
		if currentBalance < priceVal then
			btnBuy:disable()
		else
			btnBuy:enable()
		end
	end
end

function chooseOffert(self, focusedChild)
	if not focusedChild then
		return
	end

	local product = focusedChild.product
	local panel = controllerShop.ui.panelItem
	local detail = getPanelItemDetailsContent(panel)

	if not detail then
		return
	end

	local lblName = detail:getChildById("lblName")

	if lblName then
		lblName:setText(product.name)
	end

	local primaryOfferId = getPrimaryPurchasableOfferId(product)
	local description = product.description or getCachedOfferDescription(primaryOfferId)

	if description == "" then
		for _, subOffer in ipairs(product.subOffers or {}) do
			if subOffer.description and subOffer.description ~= "" then
				description = subOffer.description

				break
			end
		end
	end

	if not oldProtocol and primaryOfferId > 0 and description == "" then
		g_game.requestStoreOfferDescription(primaryOfferId)
	end

	renderStoreDescription(panel, description, nil, product)

	local subOffers = product.subOffers or {}
	local data = getProductData(product)
	local imagePanel = detail:getChildById("image")

	clearPendingHttpForChildren(imagePanel)

	if imagePanel then
		imagePanel:destroyChildren()
		imagePanel:setImageSource("/images/ui/1pixel-down-frame")

		if data then
			createProductImage(imagePanel, data, {
				detailLargePreview = true
			})
		end
	end

	fixServerNoSend0xF2()

	local coinsBalance2, coinsBalance1 = getCoinsBalance()
	local offerStackPanel = detail:getChildById("StackOffers")

	if not offerStackPanel then
		return
	end

	offerStackPanel:destroyChildren()

	local offers = not table.empty(subOffers) and subOffers or {
		product
	}
	local validOffers = {}
	local showDisabledDescription = false

	for _, o in ipairs(offers) do
		if not o.id or o.id ~= 0 then
			table.insert(validOffers, o)
		end
	end

	for _, offer in ipairs(offers) do
		if offer.id and offer.id == 0 then
			-- block empty
		else
			local offerPanel = g_ui.createWidget("OfferPanel2", offerStackPanel)
			local btnBuyWidget = offerPanel:getChildById("btnBuy")

			if isConfigurableOffer(product, offer) then
				btnBuyWidget:setText(tr("Configure"))
			else
				local showBuyWithPrice = #validOffers > 1 or (offer.count or 1) > 1

				if showBuyWithPrice then
					btnBuyWidget:setText("Buy  " .. tostring(offer.count or 1))
				else
					btnBuyWidget:setText(tr("Buy"))
				end
			end

			setOfferPanelPriceRow(offerPanel, offer, coinsBalance2, coinsBalance1)

			if offer.disabled then
				showDisabledDescription = true

				local btnBuy = offerPanel:getChildById("btnBuy")

				btnBuy:disable()
				btnBuy:setOpacity(0.8)

				if offer.reasonIdDisable or offer.reasonIdsDisable and #offer.reasonIdsDisable > 0 then
					local tooltipOverlay = g_ui.createWidget("UIWidget", offerPanel)

					tooltipOverlay:setId("tooltipOverlay")
					tooltipOverlay:setFocusable(false)
					tooltipOverlay:setSize(btnBuy:getSize())
					tooltipOverlay:setPosition(btnBuy:getPosition())

					local reasonLines = {}

					if oldProtocol then
						table.insert(reasonLines, tostring(offer.reasonIdDisable or "Unavailable"))
					else
						local reasonIds = offer.reasonIdsDisable

						if not reasonIds or #reasonIds == 0 then
							reasonIds = {
								offer.reasonIdDisable
							}
						end

						for _, reasonId in ipairs(reasonIds) do
							local reasonText = reasonCategory[(reasonId or 0) + 1]

							if reasonText and reasonText ~= "" then
								table.insert(reasonLines, reasonText)
							end
						end
					end

					if #reasonLines == 0 then
						table.insert(reasonLines, "Unavailable")
					end

					tooltipOverlay:parseColoreDisplayToolTip(string.format("[color=#ff0000]The product is not available for this character:\n\n- %s[/color]", table.concat(reasonLines, "\n- ")))
					tooltipOverlay:setOpacity(0)
					tooltipOverlay:addAnchor(AnchorLeft, btnBuy:getId(), AnchorLeft)
					tooltipOverlay:addAnchor(AnchorTop, btnBuy:getId(), AnchorTop)
				end
			end

			offerPanel:getChildById("btnBuy").onClick = function(widget)
				if acceptWindow then
					destroyWindow(acceptWindow)
				end

				local isTransferable = offer.coinType == GameStore.CoinType.Transferable

				if isConfigurableOffer(product, offer) then
					fixServerNoSend0xF2()
					g_game.buyStoreOffer(offer.id, GameStore.ClientOfferTypes.CLIENT_STORE_OFFER_OTHER)
					showStoreProcessingModal()

					return
				end

				local function shouldAskBeforeBuying()
					if modules.client_options and modules.client_options.getOption then
						local value = modules.client_options.getOption("askBeforeBuying")

						if value ~= nil then
							return value
						end
					end

					return true
				end

				local purchaseInProgress = false

				local function acceptFunc()
					if purchaseInProgress then
						return
					end

					purchaseInProgress = true

					if acceptWindow and applyShopDoNotShowAgainPreference then
						applyShopDoNotShowAgainPreference(acceptWindow)
					end

					destroyWindow(acceptWindow)
					addEvent(function()
						fixServerNoSend0xF2()

						local latestBalance2, latestBalance1 = getCoinsBalance()
						local latestCurrentBalance = isTransferable and latestBalance1 or latestBalance2

						if latestCurrentBalance >= offer.price then
							g_game.buyStoreOffer(offer.id, GameStore.ClientOfferTypes.CLIENT_STORE_OFFER_OTHER)
							showStoreProcessingModal()
						else
							displayErrorBox(controllerShop.ui:getText(), tr("You don't have enough coins"))
							restoreStoreAfterOverlay()
						end
					end)
				end

				local function cancelFunc()
					destroyWindow(acceptWindow)
					restoreStoreAfterOverlay()
				end

				local formattedPrice = formatNumberWithCommas(tonumber(offer.price) or 0)
				local offerCount = offer.count or 1
				local productLineText = string.format("%dx %s", offerCount, product.name)
				local confirmationMessage = string.format("Do you want to buy the product \"%s\"?", productLineText)
				local priceIcon = isTransferable and "/images/icons/icon-tibiacointransferable" or "/images/icons/icon-tibiacoin"
				local data = getProductData(product)

				if not shouldAskBeforeBuying() then
					acceptFunc()

					return
				end

				hideStoreForOverlay()

				acceptWindow = displayGeneralSHOPBox(tr("Confirmation of Purchase"), confirmationMessage, productLineText, formattedPrice, priceIcon, {
					{
						text = tr("Buy"),
						callback = acceptFunc
					},
					{
						text = tr("Cancel"),
						callback = cancelFunc
					},
					anchor = AnchorHorizontalCenter
				}, acceptFunc, cancelFunc)

				if data then
					createProductImage(acceptWindow.Box, data)
				end
			end
		end
	end

	if showDisabledDescription then
		renderStoreDescription(panel, description, "The product is currently not available for this character. See the buy button tooltip for details.", product)
	end
end

function onClickHomeBanner()
	if not bannersHome or #bannersHome == 0 then
		return
	end

	local currentBanner = bannersHome[currentIndex]

	if not currentBanner then
		return
	end

	local targetOfferId = currentBanner.offerId

	if targetOfferId and targetOfferId ~= 0 then
		g_game.sendRequestStoreOfferById(targetOfferId)
	else
		g_logger.warning("[game_store] Could not redirect from banner: missing offer id")
	end
end

function chooseHome(self, focusedChild)
	if not focusedChild then
		return
	end

	local product = focusedChild.product
	local targetOfferId = product.id

	if (not targetOfferId or targetOfferId == 0) and product.subOffers and #product.subOffers > 0 then
		targetOfferId = product.subOffers[1].id
	end

	if targetOfferId and targetOfferId ~= 0 then
		g_game.sendRequestStoreOfferById(targetOfferId)
	else
		g_logger.warning("[game_store] Could not redirect from Home: missing offer id")
	end
end

function changeImagenHome(direction)
	if direction == "nextImagen" then
		currentIndex = currentIndex + 1

		if currentIndex > #bannersHome then
			currentIndex = 1
		end
	elseif direction == "prevImagen" then
		currentIndex = currentIndex - 1

		if currentIndex < 1 then
			currentIndex = #bannersHome
		end
	end

	local currentBanner = bannersHome[currentIndex]
	local imagePath = "/" .. currentBanner.image
	local homeBanner = getHomeBannerWidget()

	if homeBanner then
		setImagenHttp(homeBanner, imagePath, false)
	end
end

local function closeChangeNameWindow(restoreStore)
	destroyWindow(changeNameWindow)

	if restoreStore then
		restoreStoreAfterOverlay()
	end
end

function displayChangeName(offerId)
	offerId = tonumber(offerId)

	if not offerId or offerId == 0 then
		displayErrorBox(controllerShop.ui and controllerShop.ui:getText() or tr("Store"), tr("Invalid offer."))

		return
	end

	hideStoreForOverlay()
	destroyWindow(changeNameWindow)

	changeNameWindow = g_ui.displayUI("style/changename")

	if not changeNameWindow then
		restoreStoreAfterOverlay()

		return
	end

	changeNameWindow:setText(tr("Enter New Character Name"))
	changeNameWindow:show()
	changeNameWindow:raise()
	changeNameWindow:focus()
	g_modalManager.show(changeNameWindow)

	local nameField = changeNameWindow:recursiveGetChildById("transferPointsText")

	changeNameWindow.transferPointsText = nameField

	if nameField then
		nameField:setText("")
		nameField:focus()
	end

	local function updateNameChangeOkButtonState(nameText)
		if not changeNameWindow or changeNameWindow:isDestroyed() then
			return
		end

		local okBtn = changeNameWindow.buttonOk

		if not okBtn or okBtn:isDestroyed() then
			okBtn = changeNameWindow:recursiveGetChildById("buttonOk")
			changeNameWindow.buttonOk = okBtn
		end

		if not okBtn then
			return
		end

		local text = nameText

		if text == nil and nameField and not nameField:isDestroyed() then
			text = nameField:getText()
		end

		local hasName = (text or ""):trim():len() >= 1

		okBtn:setEnabled(hasName)
	end

	local function scheduleNameChangeOkButtonState(nameText)
		if not changeNameWindow or changeNameWindow:isDestroyed() then
			return
		end

		if changeNameWindow._nameOkButtonUpdateEvent then
			removeEvent(changeNameWindow._nameOkButtonUpdateEvent)
		end

		changeNameWindow._nameOkButtonUpdateEvent = addEvent(function()
			changeNameWindow._nameOkButtonUpdateEvent = nil

			updateNameChangeOkButtonState(nameText)
		end)
	end

	function changeNameWindow.onEscape()
		closeChangeNameWindow(true)
	end

	local closeButton = changeNameWindow:recursiveGetChildById("closeButton")

	changeNameWindow.closeButton = closeButton

	local okButton = changeNameWindow:recursiveGetChildById("buttonOk")

	changeNameWindow.buttonOk = okButton

	updateNameChangeOkButtonState("")

	if nameField then
		function nameField.onTextChange(widget, text)
			scheduleNameChangeOkButtonState(text)
		end
	end

	if closeButton then
		function closeButton.onClick()
			closeChangeNameWindow(true)
		end
	end

	if okButton then
		function okButton.onClick()
			if not changeNameWindow or changeNameWindow:isDestroyed() then
				return
			end

			local newName = nameField and nameField:getText():trim() or ""

			if newName:len() < 1 or not okButton:isEnabled() then
				return
			end

			if newName:len() < 2 then
				displayErrorBox(changeNameWindow:getText(), tr("Please enter a valid character name."))

				return
			end

			destroyWindow(changeNameWindow)
			g_game.buyStoreOffer(offerId, GameStore.ClientOfferTypes.CLIENT_STORE_OFFER_NAMECHANGE, newName)
			showStoreProcessingModal()
		end
	end
end

local function closeHirelingNameWindow(restoreStore)
	destroyWindow(hirelingNameWindow)

	if restoreStore then
		restoreStoreAfterOverlay()
	end
end

function displayHirelingName(offerId)
	offerId = tonumber(offerId)

	if not offerId or offerId == 0 then
		displayErrorBox(controllerShop.ui and controllerShop.ui:getText() or tr("Store"), tr("Invalid offer."))

		return
	end

	hideStoreForOverlay()
	destroyWindow(hirelingNameWindow)

	hirelingNameWindow = g_ui.displayUI("style/changename")

	if not hirelingNameWindow then
		restoreStoreAfterOverlay()

		return
	end

	hirelingNameWindow:setText(tr("Enter Hireling Name"))
	hirelingNameWindow:show()
	hirelingNameWindow:raise()
	hirelingNameWindow:focus()
	g_modalManager.show(hirelingNameWindow)

	local nameField = hirelingNameWindow:recursiveGetChildById("transferPointsText")

	hirelingNameWindow.transferPointsText = nameField

	if nameField then
		nameField:setText("")
		nameField:focus()
	end

	local function updateOkButtonState(nameText)
		if not hirelingNameWindow or hirelingNameWindow:isDestroyed() then
			return
		end

		local okBtn = hirelingNameWindow.buttonOk

		if not okBtn or okBtn:isDestroyed() then
			okBtn = hirelingNameWindow:recursiveGetChildById("buttonOk")
			hirelingNameWindow.buttonOk = okBtn
		end

		if not okBtn then
			return
		end

		local text = nameText

		if text == nil and nameField and not nameField:isDestroyed() then
			text = nameField:getText()
		end

		okBtn:setEnabled((text or ""):trim():len() >= 1)
	end

	local function scheduleOkButtonState(nameText)
		if not hirelingNameWindow or hirelingNameWindow:isDestroyed() then
			return
		end

		if hirelingNameWindow._okUpdateEvent then
			removeEvent(hirelingNameWindow._okUpdateEvent)
		end

		hirelingNameWindow._okUpdateEvent = addEvent(function()
			hirelingNameWindow._okUpdateEvent = nil

			updateOkButtonState(nameText)
		end)
	end

	function hirelingNameWindow.onEscape()
		closeHirelingNameWindow(true)
	end

	local closeButton = hirelingNameWindow:recursiveGetChildById("closeButton")
	local okButton = hirelingNameWindow:recursiveGetChildById("buttonOk")

	hirelingNameWindow.buttonOk = okButton

	updateOkButtonState("")

	if nameField then
		function nameField.onTextChange(widget, text)
			scheduleOkButtonState(text)
		end
	end

	if closeButton then
		function closeButton.onClick()
			closeHirelingNameWindow(true)
		end
	end

	if okButton then
		function okButton.onClick()
			if not hirelingNameWindow or hirelingNameWindow:isDestroyed() then
				return
			end

			local newName = nameField and nameField:getText():trim() or ""

			if newName:len() < 1 or not okButton:isEnabled() then
				return
			end

			if newName:len() < 2 then
				displayErrorBox(hirelingNameWindow:getText(), tr("Please enter a valid hireling name."))

				return
			end

			destroyWindow(hirelingNameWindow)
			g_game.buyStoreOffer(offerId, GameStore.ClientOfferTypes.CLIENT_STORE_OFFER_HIRELING, newName, 0)
			showStoreProcessingModal()
		end
	end
end

function displayHirelingRename(creatureId)
	creatureId = tonumber(creatureId)

	if not creatureId or creatureId == 0 then
		return
	end

	destroyWindow(hirelingNameWindow)

	hirelingNameWindow = g_ui.displayUI("style/changename")

	if not hirelingNameWindow then
		return
	end

	hirelingNameWindow:setText(tr("Enter Hireling Name"))
	hirelingNameWindow:show()
	hirelingNameWindow:raise()
	hirelingNameWindow:focus()
	g_modalManager.show(hirelingNameWindow)

	local nameField = hirelingNameWindow:recursiveGetChildById("transferPointsText")

	hirelingNameWindow.transferPointsText = nameField

	if nameField then
		nameField:setText("")
		nameField:focus()
	end

	local function updateOkButtonState(nameText)
		if not hirelingNameWindow or hirelingNameWindow:isDestroyed() then
			return
		end

		local okBtn = hirelingNameWindow.buttonOk

		if not okBtn or okBtn:isDestroyed() then
			okBtn = hirelingNameWindow:recursiveGetChildById("buttonOk")
			hirelingNameWindow.buttonOk = okBtn
		end

		if not okBtn then
			return
		end

		local text = nameText

		if text == nil and nameField and not nameField:isDestroyed() then
			text = nameField:getText()
		end

		okBtn:setEnabled((text or ""):trim():len() >= 1)
	end

	local function scheduleOkButtonState(nameText)
		if not hirelingNameWindow or hirelingNameWindow:isDestroyed() then
			return
		end

		if hirelingNameWindow._okUpdateEvent then
			removeEvent(hirelingNameWindow._okUpdateEvent)
		end

		hirelingNameWindow._okUpdateEvent = addEvent(function()
			hirelingNameWindow._okUpdateEvent = nil

			updateOkButtonState(nameText)
		end)
	end

	function hirelingNameWindow.onEscape()
		closeHirelingNameWindow(false)
	end

	local closeButton = hirelingNameWindow:recursiveGetChildById("closeButton")
	local okButton = hirelingNameWindow:recursiveGetChildById("buttonOk")

	hirelingNameWindow.buttonOk = okButton

	updateOkButtonState("")

	if nameField then
		function nameField.onTextChange(widget, text)
			scheduleOkButtonState(text)
		end
	end

	if closeButton then
		function closeButton.onClick()
			closeHirelingNameWindow(false)
		end
	end

	if okButton then
		function okButton.onClick()
			if not hirelingNameWindow or hirelingNameWindow:isDestroyed() then
				return
			end

			local newName = nameField and nameField:getText():trim() or ""

			if newName:len() < 1 or not okButton:isEnabled() then
				return
			end

			if newName:len() < 2 then
				displayErrorBox(hirelingNameWindow:getText(), tr("Please enter a valid hireling name."))

				return
			end

			destroyWindow(hirelingNameWindow)
			g_game.sendChangeHirelingName(creatureId, newName)
		end
	end
end

function onHirelingNameChange(playerId, creatureId)
	displayHirelingRename(creatureId)
end

local WORLD_TYPE_NAMES = {
	[0] = "Open PvP",
	"Optional PvP",
	"Hardcore PvP",
	"Retro Open PvP",
	"Retro Hardcore PvP"
}

local function closeWorldTransferWindow(restoreStore)
	destroyWindow(worldTransferWindow)

	worldTransferWindow = nil

	if restoreStore then
		restoreStoreAfterOverlay()
	end
end

function displayWorldTransfer(offerId, data)
	offerId = tonumber(offerId)

	if not offerId or offerId == 0 then
		displayErrorBox(controllerShop.ui and controllerShop.ui:getText() or tr("Store"), tr("Invalid offer."))

		return
	end

	if not data then
		displayErrorBox(controllerShop.ui and controllerShop.ui:getText() or tr("Store"), tr("Missing world transfer data."))

		return
	end

	hideStoreForOverlay()
	destroyWindow(worldTransferWindow)

	worldTransferWindow = g_ui.displayUI("style/worldtransfer")

	if not worldTransferWindow then
		restoreStoreAfterOverlay()

		return
	end

	local transferTitle = data.isExpress and tr("Set Up an Express Character World Transfer") or tr("Set Up a Character World Transfer")

	worldTransferWindow:setText(transferTitle .. tr(" - Step 1 of 2"))
	worldTransferWindow:show()
	worldTransferWindow:raise()
	worldTransferWindow:focus()
	g_modalManager.show(worldTransferWindow)

	local playerName = g_game.getLocalPlayer() and g_game.getLocalPlayer():getName() or ""
	local step1 = worldTransferWindow:getChildById("step1Panel")
	local step2 = worldTransferWindow:getChildById("step2Panel")
	local charLabel1 = step1:getChildById("characterLabel1")

	if charLabel1 then
		charLabel1:setText(tr("Character: %s", playerName))
	end

	local charLabel2 = step2:getChildById("characterLabel2")

	if charLabel2 then
		charLabel2:setText(tr("Character: %s", playerName))
	end

	local worldCombo = step1:getChildById("worldCombo")

	if worldCombo then
		worldCombo:clear()

		for _, world in ipairs(data.worlds or {}) do
			if not world.worldLocked then
				local label = world.name
				local typeName = WORLD_TYPE_NAMES[world.worldType]

				if typeName then
					label = label .. " (" .. typeName .. ")"
				end

				if world.onlyPremium then
					label = label .. " [Premium]"
				end

				worldCombo:addOption(label, world.name)
			end
		end

		worldCombo:setCurrentIndex(1)
	end

	local reqList = step1:getChildById("requirementsList")

	if reqList then
		local requirements = {
			{
				met = not data.hasRedSkull,
				text = tr("Your character has no red skull."),
				fail = tr("Your character has a red skull.")
			},
			{
				met = not data.hasBlackSkull,
				text = tr("Your character has no black skull."),
				fail = tr("Your character has a black skull.")
			},
			{
				met = not data.isGuildLeader,
				text = tr("Your character is no guild leader."),
				fail = tr("Your character is a guild leader.")
			},
			{
				met = not data.hasHouseOrBidActive,
				text = tr("Your character does not own a house."),
				fail = tr("Your character owns a house.")
			},
			{
				met = not data.hasCoinMarketAuction,
				text = tr("You do not have any Tibia Coin auctions in the Market."),
				fail = tr("You have active Tibia Coin auctions in the Market.")
			}
		}
		local allMet = true

		for _, req in ipairs(requirements) do
			local row = g_ui.createWidget("WorldTransferReqRow", reqList)

			if row then
				local icon = row:getChildById("reqIcon")
				local label = row:getChildById("reqText")

				if req.met then
					if icon then
						icon:setImageSource("/images/ui/icon-yes")
						icon:setSize("12 9")
					end

					if label then
						label:setText(req.text)
					end
				else
					allMet = false

					if icon then
						icon:setImageSource("/images/ui/icon-no")
						icon:setSize("12 9")
					end

					if label then
						label:setText(req.fail)
						label:setColor("#ff6060")
					end
				end
			end
		end

		local rowHeight = 18

		reqList:setHeight(#requirements * rowHeight + 4)

		local fulfillText = step1:getChildById("fulfillText")

		if fulfillText then
			if allMet then
				fulfillText:setText(tr("You fulfil all conditions for a Character World Transfer. Please select the game world to which you like to transfer."))
			else
				fulfillText:setText(tr("Not all requirements are fulfilled. You cannot proceed with the transfer."))
				fulfillText:setColor("#ff6060")
			end
		end

		local btnNext = step1:getChildById("btnNext")

		if btnNext then
			btnNext:setEnabled(allMet and worldCombo and worldCombo:getOptionsCount() > 0)

			function worldCombo.onOptionChange()
				btnNext:setEnabled(allMet and worldCombo:getCurrentIndex() > 0)
			end
		end
	end

	local function goToStep2()
		local opt = worldCombo and worldCombo:getCurrentOption()
		local selectedWorld = opt and opt.data or ""
		local targetConfirm = step2:getChildById("targetWorldConfirm")

		if targetConfirm then
			targetConfirm:setText(tr("Target world: %s", selectedWorld))
		end

		worldTransferWindow:setText(transferTitle .. tr(" - Step 2 of 2"))
		worldTransferWindow:setSize("450 430")
		step1:setVisible(false)
		step2:setVisible(true)

		local btnBuyNow = step2:getChildById("btnBuyNow")
		local acceptCheckbox = step2:getChildById("acceptCheckbox")

		if btnBuyNow and acceptCheckbox then
			btnBuyNow:setEnabled(acceptCheckbox:isChecked())

			function acceptCheckbox.onCheckChange(widget, checked)
				btnBuyNow:setEnabled(checked)
			end
		end
	end

	local btnNext = step1:getChildById("btnNext")

	if btnNext then
		function btnNext.onClick()
			goToStep2()
		end
	end

	local btnCancel1 = step1:getChildById("btnCancel1")

	if btnCancel1 then
		function btnCancel1.onClick()
			closeWorldTransferWindow(true)
		end
	end

	local btnBuyNow = step2:getChildById("btnBuyNow")

	if btnBuyNow then
		function btnBuyNow.onClick()
			local opt = worldCombo and worldCombo:getCurrentOption()
			local selectedWorld = opt and opt.data or ""

			if selectedWorld == "" then
				return
			end

			closeWorldTransferWindow(false)
			g_game.buyStoreOffer(offerId, GameStore.ClientOfferTypes.CLIENT_STORE_OFFER_WORLD_TRANSFER, selectedWorld)
			showStoreProcessingModal()
		end
	end

	local btnCancel2 = step2:getChildById("btnCancel2")

	if btnCancel2 then
		function btnCancel2.onClick()
			closeWorldTransferWindow(true)
		end
	end

	local btnBack = step2:getChildById("btnBack")

	if btnBack then
		function btnBack.onClick()
			worldTransferWindow:setText(transferTitle .. tr(" - Step 1 of 2"))
			worldTransferWindow:setSize("450 356")
			step2:setVisible(false)
			step1:setVisible(true)
		end
	end

	function worldTransferWindow.onEscape()
		closeWorldTransferWindow(true)
	end

	local closeButton = worldTransferWindow:recursiveGetChildById("closeButton")

	if closeButton then
		function closeButton.onClick()
			closeWorldTransferWindow(true)
		end
	end
end

local function closeTransferPointsWindow()
	destroyWindow(transferPointsWindow)
	restoreStoreAfterOverlay()
end

function transferCancel()
	closeTransferPointsWindow()
end

function transferPoints()
	destroyWindow(transferPointsWindow)
	hideStoreForOverlay()

	transferPointsWindow = g_ui.displayUI("style/transferpoints")

	transferPointsWindow:show()
	transferPointsWindow:raise()
	transferPointsWindow:focus()
	g_modalManager.show(transferPointsWindow)

	local playerBalance = g_game.getLocalPlayer():getResourceBalance(ResourceTypes.COIN_TRANSFERRABLE)

	fixServerNoSend0xF2()

	local coinsBalance2, coinsBalance1 = getCoinsBalance()

	if playerBalance == 0 then
		playerBalance = coinsBalance1
	end

	transferPointsWindow.giftable:setText(formatNumberWithCommas(playerBalance))

	local giftCoinStep = 25
	local canGiftCoins = giftCoinStep <= playerBalance
	local giftAmountMin = canGiftCoins and giftCoinStep or 0
	local giftAmountMax = canGiftCoins and math.floor(playerBalance / giftCoinStep) * giftCoinStep or 0

	transferPointsWindow.amountBar:setMinimum(giftAmountMin)
	transferPointsWindow.amountBar:setMaximum(giftAmountMax)
	transferPointsWindow.amountBar:setStep(giftCoinStep)
	transferPointsWindow.amountBar:setIncrementStep(giftCoinStep)

	local initialAmount = canGiftCoins and giftCoinStep or 0

	transferPointsWindow.amountBar:setEnabled(canGiftCoins)
	transferPointsWindow.amountBar:setValue(initialAmount)
	transferPointsWindow.amount:setText(formatNumberWithCommas(initialAmount))

	local function updateGiftTransferButtonState(recipientText)
		if not transferPointsWindow or transferPointsWindow:isDestroyed() then
			return
		end

		local textEdit = transferPointsWindow.transferPointsText
		local recipient = recipientText

		if recipient == nil and textEdit and not textEdit:isDestroyed() then
			recipient = textEdit:getText()
		end

		recipient = (recipient or ""):trim()

		local hasRecipient = recipient:len() >= 1
		local giftButton = transferPointsWindow.buttonOk

		giftButton:setEnabled(hasRecipient)
	end

	local function scheduleGiftTransferButtonState(recipientText)
		if transferPointsWindow._giftButtonUpdateEvent then
			removeEvent(transferPointsWindow._giftButtonUpdateEvent)
		end

		transferPointsWindow._giftButtonUpdateEvent = addEvent(function()
			transferPointsWindow._giftButtonUpdateEvent = nil

			updateGiftTransferButtonState(recipientText)
		end)
	end

	updateGiftTransferButtonState("")

	function transferPointsWindow.transferPointsText.onTextChange(widget, text)
		scheduleGiftTransferButtonState(text)
	end

	transferPointsWindow.onEscape = closeTransferPointsWindow

	local function snapGiftCoinAmount(raw)
		if not canGiftCoins then
			return 0
		end

		local value = math.max(0, math.floor(tonumber(raw) or 0))

		if value <= 0 then
			return giftAmountMin
		end

		local snapped = math.floor((value + giftCoinStep / 2) / giftCoinStep) * giftCoinStep

		if snapped < giftAmountMin then
			snapped = giftAmountMin
		end

		return math.min(snapped, giftAmountMax)
	end

	function transferPointsWindow.amountBar.onValueChange(scrollbar, value)
		local snapped = snapGiftCoinAmount(value)

		if scrollbar:getValue() ~= snapped then
			scrollbar:setValue(snapped)

			return
		end

		transferPointsWindow.amount:setText(formatNumberWithCommas(snapped))
	end

	transferPointsWindow.closeButton.onClick = closeTransferPointsWindow

	function transferPointsWindow.buttonOk.onClick()
		local receipient = transferPointsWindow.transferPointsText:getText():trim()

		if receipient:len() < 1 then
			return
		end

		local amount = transferPointsWindow.amountBar:getValue()

		if not canGiftCoins or amount < giftAmountMin or amount > giftAmountMax then
			return
		end

		g_game.transferCoins(receipient, amount)
		closeTransferPointsWindow()
	end
end

function search()
	if not controllerShop.ui then
		return
	end

	waitingInitialHome = false

	if controllerShop.ui.openedCategory ~= nil then
		close(controllerShop.ui.openedCategory)
	end

	local text = controllerShop.ui.SearchEdit:getText() or ""

	g_game.sendRequestStoreSearch(text:trim(), 0, 1)
end
