local kAddonName, addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(kAddonName)


local function updateLineGroup(line, item)
	line.prefix:SetText(item.groupIndex .. '.')
	line.cooldown:Show()
	line.cooldown:SetText(item.group.cooldown)
	line.ignoreGlobalCooldown:Show()
	line.ignoreGlobalCooldown:SetChecked(item.group.ignoreGlobalCooldown)
end


local function updateLineAction(line, item)
	line.delete:Show()
	if item.actionIndex == 1 then
		line.prefix:SetText(L['RUN'])
	else
		line.prefix:SetText(L['AND'])
	end
	line.command:Show()
	line.delay:Show()
	line.command:SetText(item.action.command)
	line.delay:SetText(item.action.delay)
end


local function updateActionLine(line, item)
	line.prefix:SetText('')
	line.addAnd:Hide()
	line.addOr:Hide()
	line.delete:Hide()
	line.cooldown:Hide()
	line.ignoreGlobalCooldown:Hide()
	line.command:Hide()
	line.delay:Hide()
	if item.kind == 'group' then
		updateLineGroup(line, item)
	elseif item.kind == 'action' then
		updateLineAction(line, item)
	elseif item.kind == 'newAnd' then
		line.addAnd:Show()
	elseif item.kind == 'newOr' then
		line.addOr:Show()
	end
end


local function flattenActions(actions)
	local flat = {}
	for i, group in ipairs(actions) do
		table.insert(flat, {
			kind = 'group',
			groupIndex = i,
			group = group,
		})
		for ii, action in ipairs(group.actions) do
			table.insert(flat, {
				kind = 'action',
				groupIndex = i,
				actionIndex = ii,
				action = action,
			})
		end
		table.insert(flat, {kind = 'newAnd', groupIndex = i})
	end
	table.insert(flat, {kind = 'newOr'})
	return flat
end


function addon.actions.updateGUI(frame, entry)
	frame:SetShown(not not entry)
	if entry then
		frame.test.extraTooltipText = nil
		local items = flattenActions(entry.actions)
		addon.guiutils.updateScroller(frame.content.scroller, items, updateActionLine)
	end
end


local function clickDelete(self)
	local function delete()
		local line = self:GetParent()
		addon.store.dispatch({
			name = 'deleteAction',
			entryIndex = addon.guiutils.getSelectedEntryIndex(),
			groupIndex = line.item.groupIndex,
			actionIndex = line.item.actionIndex,
		})
	end
	addon.guiutils.confirmDelete(delete)
end


local function clickAddAnd(self)
	local line = self:GetParent()
	addon.store.dispatch({
		name = 'addAction',
		entryIndex = addon.guiutils.getSelectedEntryIndex(),
		groupIndex = line.item.groupIndex,
		delay = 0,
		command = L.default_command,
	})
end


local function clickAddOr()
	local action = {
		delay = 0,
		command = L.default_command,
	}
	addon.store.dispatch({
		name = 'addActionGroup',
		entryIndex = addon.guiutils.getSelectedEntryIndex(),
		actions = {action},
	})
end


local function changeCooldown(self)
	_G.EditBox_ClearHighlight(self)
	local cooldown = self:GetText()
	if #cooldown == 0 or not addon.guiutils.isValidCooldown(cooldown) then
		cooldown = '0'
	end
	local line = self:GetParent()
	addon.store.dispatch({
		name = 'setActionGroupCooldown',
		entryIndex = addon.guiutils.getSelectedEntryIndex(),
		groupIndex = line.item.groupIndex,
		cooldown = cooldown,
	})
end


local function changeIgnoreGlobalCooldown(self)
	local ignore = not not self:GetChecked()
	local line = self:GetParent()
	addon.store.dispatch({
		name = 'setActionGroupIgnoreGlobalCooldown',
		entryIndex = addon.guiutils.getSelectedEntryIndex(),
		groupIndex = line.item.groupIndex,
		ignore = ignore,
	})
end


local function changeCommandOrDelay(self)
	_G.EditBox_ClearHighlight(self)
	local line = self:GetParent()
	addon.store.dispatch({
		name = 'editAction',
		entryIndex = addon.guiutils.getSelectedEntryIndex(),
		groupIndex = line.item.groupIndex,
		actionIndex = line.item.actionIndex,
		delay = line.delayEditbox:GetNumber(),
		command = line.commandEditbox:GetText(),
	})
end


local function createActionsLine(parent, index)
	local line = addon.guiutils.create('Frame', 'Line' .. index, parent)
	line:SetSize(545, 25)

	local prefix = line:CreateFontString(
		'BACKGROUND', '$parentPrefix', 'GameFontHighlightSmallLeft')
	line.prefix = prefix
	prefix:SetPoint('LEFT')
	prefix:SetWidth(30)

	local addAnd = addon.guiutils.createTextButton('AddAnd', line, L['AND'], clickAddAnd)
	addAnd:SetPoint('LEFT', 30, 0)
	addon.guiutils.setupTooltip(addAnd, L['Add Action to This Group'], L.help_action_and)

	local addOr = addon.guiutils.createTextButton('AddOr', line, _G.ADD:upper(), clickAddOr)
	addOr:SetPoint('LEFT')
	addon.guiutils.setupTooltip(addOr, L['Add Action Group'], L.help_action_or)

	local delete = addon.guiutils.createButton('Delete', line, 'UIPanelCloseButton', clickDelete)
	delete:SetPoint('TOPRIGHT')
	delete:SetSize(24, 24)
	addon.guiutils.setupTooltip(delete, _G.DELETE, '')

	local cooldown = addon.guiutils.create('EditBox', 'Cooldown', line, 'InputBoxTemplate')
	cooldown:SetPoint('TOPLEFT', 100, 0)
	cooldown:SetWidth(50)
	cooldown:SetHeight(25)
	cooldown:SetAutoFocus(false)
	cooldown:SetScript('OnTextChanged', addon.guiutils.onCooldownTextChanged)
	cooldown:SetScript('OnEditFocusLost', changeCooldown)
	local cooldownHelp = L.help_action_cooldown .. '\n\n' .. L.help_cooldown
	addon.guiutils.setupTooltip(cooldown, L['Cooldown'], cooldownHelp)

	local cooldownLabel = cooldown:CreateFontString(
		'$parentLabel', 'ARTWORK', 'GameFontHighlightSmall')
	cooldownLabel:SetPoint('RIGHT', cooldown, 'LEFT', -7, 0)
	cooldownLabel:SetText(L['Cooldown'] .. ':')

	local ignoreGCD = addon.guiutils.create(
		'CheckButton', 'IgnoreGlobalCooldown', line, 'OptionsSmallCheckButtonTemplate')
	ignoreGCD:SetPoint('LEFT', cooldown, 'RIGHT', 30, 0)
	ignoreGCD:SetScript('OnClick', changeIgnoreGlobalCooldown)
	_G[ignoreGCD:GetName() .. 'Text']:SetText(L['Ignore global cooldown'])
	_G[ignoreGCD:GetName() .. 'Text']:SetTextColor(1.0, 1.0, 1.0)
	addon.guiutils.setupTooltip(
		ignoreGCD, L['Ignore global cooldown'], L.help_action_cooldown_ignore_global)

	local delay = addon.guiutils.create('EditBox', 'Delay', line, 'InputBoxTemplate')
	delay:SetPoint('TOPRIGHT', line, 'TOPRIGHT', -30, 0)
	delay:SetNumeric(true)
	delay:SetMaxLetters(2)
	delay:SetWidth(25)
	delay:SetHeight(25)
	delay:SetAutoFocus(false)
	delay:SetScript('OnEditFocusLost', changeCommandOrDelay)
	addon.guiutils.setupTooltip(delay, L['Delay (secs)'], L.help_action_delay)

	local delayLabel = delay:CreateFontString('$parentLabel', 'ARTWORK', 'GameFontHighlightSmall')
	delayLabel:SetPoint('RIGHT', delay, 'LEFT', -7, 0)
	delayLabel:SetText(L['Delay (secs)'] .. ':')

	local command = addon.guiutils.create('EditBox', 'Command', line, 'InputBoxTemplate')
	command:SetPoint('TOPLEFT', line, 'TOPLEFT', 40, 0)
	command:SetMaxLetters(255)
	command:SetWidth(360)
	command:SetHeight(25)
	command:SetAutoFocus(false)
	command:SetScript('OnEditFocusLost', changeCommandOrDelay)
	addon.guiutils.setupTooltip(command, L['Command'], L.help_action_command)

	return line
end


local function clickCreateHelperActionGroup(_--[[self]], group)
	addon.store.dispatch({
		name = 'addActionGroup',
		entryIndex = addon.guiutils.getSelectedEntryIndex(),
		cooldown = group.cooldown,
		ignoreGlobalCooldown = group.ignoreGlobalCooldown,
		actions = group.actions,
	})
end


local function initActionsHelpDropdown(_--[[frame]], level)
	for _, example in addon.actions.iterateExamples() do
		local info = {
			text = example.name,
			notCheckable = true,
			func = clickCreateHelperActionGroup,
			arg1 = example.group,
		}
		_G.UIDropDownMenu_AddButton(info, level)
	end
end


local function clickTestActions(self)
	local entryIndex = addon.guiutils.getSelectedEntryIndex()
	local alwaysIndexes, cooldownIndex = addon.actions.runEntry(entryIndex, {})
	local groups = alwaysIndexes
	if cooldownIndex then
		table.insert(groups, cooldownIndex)
	end
	local ranText = _G.NONE
	if #groups > 0 then
		ranText = table.concat(groups, ', ')
	end
	self.extraTooltipText = L.help_action_test_ran .. ':\n' .. ranText
	self:GetScript('OnEnter')(self)
end


function addon.actions.createGUI(parent)
	local frame = addon.guiutils.createSection({
		parent = parent,
		name = 'Actions',
		height = 155,
		title = L['Then...'],
		subtitle = L.actions_subtitle,
		help = L.help_actions,
		initHelpDropdown = initActionsHelpDropdown,
		lineCount = 5,
		createLine = createActionsLine,
	})

	local testButton = addon.guiutils.createTextButton(
		'Test', frame, L['Test'], clickTestActions)
	testButton:SetPoint('TOPRIGHT', 0, 3)
	addon.guiutils.setupTooltip(testButton, L['Test'], L.help_action_test)

	return frame
end
