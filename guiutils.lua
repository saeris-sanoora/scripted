local kAddonName, addon = ...
addon.guiutils = {}
local L = LibStub('AceLocale-3.0'):GetLocale(kAddonName)

_G.StaticPopupDialogs[kAddonName .. '_CONFIRM_DELETE'] = {
	text = L['Really delete this?'],
	button1 = _G.ACCEPT,
	button2 = _G.CANCEL,
	timeout = 0,
	showAlert = true,
	exclusive = true,
	hideOnEscape = true,
}

_G.StaticPopupDialogs[kAddonName .. '_EXPORT_ENTRY'] = {
	text = L['Copy the text below. This text can be imported.'],
	button1 = _G.DONE,
	OnShow = function(self)
		self.editBox:SetText(self.data)
		self.editBox:SetFocus()
		self.editBox:HighlightText()
	end,
	timeout = 0,
	wide = true,
	hasEditBox = true,
	editBoxWidth = 250,
	exclusive = true,
	hideOnEscape = true,
}

_G.StaticPopupDialogs[kAddonName .. '_IMPORT_ENTRY'] = {
	text = L['Paste the entry text to import below.'],
	button1 = _G.ACCEPT,
	button2 = _G.CANCEL,
	timeout = 0,
	wide = true,
	hasEditBox = true,
	editBoxWidth = 250,
	exclusive = true,
	hideOnEscape = true,
}


function addon.guiutils.confirmDelete(callback)
	local function onAccept()
		callback()
	end
	_G.StaticPopupDialogs[kAddonName .. '_CONFIRM_DELETE'].OnAccept = onAccept
	_G.StaticPopup_Show(kAddonName .. '_CONFIRM_DELETE')
end


function addon.guiutils.promptExport(entryText)
	_G.StaticPopup_Show(kAddonName .. '_EXPORT_ENTRY', nil, nil, entryText)
end


function addon.guiutils.promptImport(callback)
	local function onAccept(self)
		callback(self.editBox:GetText())
	end
	_G.StaticPopupDialogs[kAddonName .. '_IMPORT_ENTRY'].OnAccept = onAccept
	_G.StaticPopup_Show(kAddonName .. '_IMPORT_ENTRY')
end


function addon.guiutils.closePrompts()
	_G.StaticPopup_Hide(kAddonName .. '_CONFIRM_DELETE')
	_G.StaticPopup_Hide(kAddonName .. '_EXPORT_ENTRY')
	_G.StaticPopup_Hide(kAddonName .. '_IMPORT_ENTRY')
end


function addon.guiutils.compareByName(left, right)
	return left.name < right.name
end


function addon.guiutils.isValidCooldown(text)
	return (pcall(addon.utils.parseCooldown, text))
end


function addon.guiutils.onCooldownTextChanged(self)
	if addon.guiutils.isValidCooldown(self:GetText()) then
		self:SetTextColor(1.0, 1.0, 1.0)
	else
		self:SetTextColor(0.8, 0.1, 0.1)
	end
end


function addon.guiutils.getSelectedEntryIndex()
	local state = addon.store.getState()
	return state.selectedEntryIndex
end


local function updateScrollerList(scroller, items, updateLine)
	local totalCount = #items
	local shownCount = math.min(#scroller.buttons, totalCount)
	local offset = _G.HybridScrollFrame_GetOffset(scroller)
	for i, line in ipairs(scroller.buttons) do
		local index = i + offset
		line:SetID(index)
		line.item = nil
		if index > totalCount then
			line:Hide()
		else
			line:Show()
			line.item = items[index]
			updateLine(line, line.item)
		end
	end
	local totalHeight = totalCount * scroller.buttonHeight
	local shownHeight = shownCount * scroller.buttonHeight
	_G.HybridScrollFrame_Update(scroller, totalHeight, shownHeight)
end


function addon.guiutils.updateScroller(scroller, items, updateLine)
	local function updateAfterScroll()
		updateScrollerList(scroller, items, updateLine)
	end
	scroller.update = updateAfterScroll
	updateAfterScroll()
end


function addon.guiutils.setupTooltip(frame, title, text, disabledText)
	local function onEnter(self)
		_G.GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
		_G.GameTooltip:SetText(title)
		local textToShow = text
		if self.extraTooltipText then
			textToShow = textToShow .. '\n\n' .. self.extraTooltipText
		end
		if disabledText and not self:IsEnabled() then
			textToShow = textToShow .. '\n\n|cffcc2525' .. disabledText .. '|r'
		end
		_G.GameTooltip:AddLine(textToShow, 1.0, 1.0, 1.0, true)
		_G.GameTooltip:Show()
	end
	frame:SetScript('OnEnter', onEnter)
	frame:SetScript('OnLeave', _G.GameTooltip_Hide)
	if disabledText then
		frame:SetMotionScriptsWhileDisabled(true)
	end
end


function addon.guiutils.create(frameType, name, parent, inherits)
	assert(name and parent)
	local frame = _G.CreateFrame(frameType, '$parent' .. name, parent, inherits)
	parent[name:sub(1, 1):lower() .. name:sub(2)] = frame
	return frame
end


function addon.guiutils.createButton(name, parent, inherits, onClick)
	assert(onClick)
	local button = addon.guiutils.create('Button', name, parent, inherits)
	button:SetScript('OnClick', onClick)
	return button
end


function addon.guiutils.createTextButton(name, parent, text, onClick)
	local button = addon.guiutils.createButton(name, parent, 'GameMenuButtonTemplate', onClick)
	button:SetText(text)
	button:SetWidth(100)
	return button
end


function addon.guiutils.createSelect(name, parent, width, init)
	local frame = addon.guiutils.create('Frame', name, parent, 'UIDropDownMenuTemplate')
	_G.UIDropDownMenu_SetInitializeFunction(frame, init)
	if width == 'MENU' then
		frame:Hide()
		_G.UIDropDownMenu_SetDisplayMode(frame, 'MENU')
	else
		_G.UIDropDownMenu_SetWidth(frame, width, 20)
	end
	return frame
end


local function createHelp(parent, tooltipTitle, tooltipText, initDropdown)
	local dropdown
	local function toggleDropdown()
		_G.ToggleDropDownMenu(1, nil, dropdown)
	end

	local button = addon.guiutils.createButton('Help', parent, nil, toggleDropdown)
	button:SetNormalTexture('Interface/Common/help-i')
	button:SetHighlightTexture('Interface/Buttons/ButtonHilight-Square', 'ADD')
	button:SetSize(24, 24)

	-- The (i) icon is too small when set with :SetNormalTexture(). Make it bigger.
	local icon = button:GetNormalTexture()
	icon:ClearAllPoints()
	icon:SetPoint('CENTER')
	icon:SetSize(40, 40)

	addon.guiutils.setupTooltip(button, tooltipTitle, tooltipText)

	dropdown = addon.guiutils.createSelect('HelpSelect', parent, 'MENU', initDropdown)
	dropdown:Hide()
	dropdown:SetPoint('TOPLEFT', button, 'TOPLEFT')

	return button
end


local function createTitle(parent, titleText, subtitleText, helpText, initHelpDropdown)
	local helpButton = createHelp(parent, titleText, helpText, initHelpDropdown)
	helpButton:SetPoint('TOPLEFT', 0, 3)

	local title = parent:CreateFontString('$parentTitle', 'ARTWORK', 'GameFontNormalLarge')
	title:SetText(titleText)
	title:SetPoint('TOPLEFT', 30, 0)

	local subtitle = parent:CreateFontString('$parentSubtitle', 'ARTWORK', 'GameFontNormalSmall')
	subtitle:SetText(subtitleText)
	subtitle:SetPoint('BOTTOMLEFT', title, 'BOTTOMRIGHT', 15, 2)

	return helpButton, title, subtitle
end


local function createContent(parent, lineCount, createLine)
	local frame = addon.guiutils.create('Frame', 'Content', parent)
	frame:SetBackdrop({
		bgFile = 'Interface/Tooltips/UI-Tooltip-Background',
		edgeFile = 'Interface/Tooltips/UI-Tooltip-Border',
		tile = true, tileSize = 16, edgeSize = 16,
		insets = { left = 3, right = 3, top = 3, bottom = 3 },
	})
	frame:SetBackdropColor(0.0, 0.0, 0.0)
	frame:SetPoint('TOPLEFT', 0, -20)
	frame:SetPoint('BOTTOMRIGHT', 0, 0)

	local scroller = addon.guiutils.create(
		'ScrollFrame', 'Scroller', frame, 'MinimalHybridScrollFrameTemplate')
	scroller:SetPoint('TOPLEFT', 10, -5)
	scroller:SetPoint('BOTTOMRIGHT', -28, 5)
	scroller:SetWidth(525)
	scroller.buttons = {}
	for i = 1, lineCount do
		local line = createLine(scroller.scrollChild, i)
		if i == 1 then
			line:SetPoint('TOPLEFT')
		else
			line:SetPoint('TOPLEFT', scroller.buttons[i - 1], 'BOTTOMLEFT')
		end
		scroller.buttons[i] = line
	end
	_G.HybridScrollFrame_CreateButtons(scroller)

	return frame
end


function addon.guiutils.createSection(spec)
	local frame = addon.guiutils.create('Frame', spec.name, spec.parent)
	frame:SetHeight(spec.height)
	createTitle(frame, spec.title, spec.subtitle, spec.help, spec.initHelpDropdown)
	createContent(frame, spec.lineCount, spec.createLine)
	return frame
end
