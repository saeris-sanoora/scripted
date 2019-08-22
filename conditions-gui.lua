local kAddonName, addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(kAddonName)


local function updateLineGroup(line, item)
	line.delete:Show()
	line.delete:SetEnabled(item.conditionCount == 0 and item.groupCount ~= 1)
	line.event:Show()
	line.event.Button:SetEnabled(item.conditionCount == 0)
	_G.UIDropDownMenu_SetText(line.event, item.eventName)
end


local function updateLineCondition(line, item)
	line.delete:Show()
	line.delete:Enable()
	line.prefix:SetText(L['AND'])
	line.field:Show()
	_G.UIDropDownMenu_SetText(line.field, item.names.field)
	line.comparison:Show()
	_G.UIDropDownMenu_SetText(line.comparison, item.names.comparison)
	local comparison = item.condition.comparison
	local isMatches = comparison == 'matches' or comparison == 'notmatches'
	local helpText = isMatches and L.help_condition_value_wildcard or nil
	if item.fieldInfo.values then
		line.valueSelect:Show()
		_G.UIDropDownMenu_SetText(line.valueSelect, item.names.value)
		line.valueSelect.extraTooltipText = helpText
	else
		line.valueEdit:Show()
		line.valueEdit:SetNumeric(item.fieldInfo.numeric)
		line.valueEdit:SetText(item.names.value)
		line.valueEdit.extraTooltipText = helpText
	end
end


local function updateConditionLine(line, item)
	line.prefix:SetText('')
	line.addAnd:Hide()
	line.addOr:Hide()
	line.delete:Hide()
	line.event:Hide()
	line.field:Hide()
	line.comparison:Hide()
	line.valueSelect:Hide()
	line.valueEdit:Hide()
	if item.kind == 'group' then
		updateLineGroup(line, item)
	elseif item.kind == 'condition' then
		updateLineCondition(line, item)
	elseif item.kind == 'newAnd' then
		line.addAnd:Show()
		line.addAnd:SetEnabled(item.canAdd)
	elseif item.kind == 'existingOr' then
		line.prefix:SetText(L['OR'] .. '...')
	elseif item.kind == 'newOr' then
		line.addOr:Show()
	end
end


local function flattenConditions(conditionGroups)
	local flat = {}
	for i, group in ipairs(conditionGroups) do
		if i > 1 then
			table.insert(flat, {kind = 'existingOr'})
		end
		table.insert(flat, {
			kind = 'group',
			groupIndex = i,
			groupCount = #conditionGroups,
			event = group.event,
			eventName = addon.conditions.getEventName(group.event),
			conditionCount = #group.conditions,
		})
		for ii, condition in ipairs(group.conditions) do
			table.insert(flat, {
				kind = 'condition',
				groupIndex = i,
				conditionIndex = ii,
				event = group.event,
				condition = condition,
				names = addon.conditions.getConditionNames(group.event, condition),
				fieldInfo = addon.conditions.getFieldInfo(group.event, condition.field),
			})
		end
		table.insert(flat, {
			kind = 'newAnd',
			groupIndex = i,
			event = group.event,
			canAdd = not not addon.conditions.getDefaultField(group.event),
		})
	end
	table.insert(flat, {kind = 'newOr'})
	return flat
end


function addon.conditions.updateGUI(frame, entry)
	frame:SetShown(not not entry)
	if entry then
		frame.cooldown:SetText(entry.cooldown)
		frame.watch:SetChecked(entry.watch)
		local items = flattenConditions(entry.conditionGroups)
		addon.guiutils.updateScroller(frame.content.scroller, items, updateConditionLine)
	end
end


local function clickDelete(self)
	local function delete()
		local line = self:GetParent()
		if line.item.conditionIndex then
			addon.store.dispatch({
				name = 'deleteCondition',
				entryIndex = addon.guiutils.getSelectedEntryIndex(),
				groupIndex = line.item.groupIndex,
				conditionIndex = line.item.conditionIndex,
			})
		else
			addon.store.dispatch({
				name = 'deleteConditionGroup',
				entryIndex = addon.guiutils.getSelectedEntryIndex(),
				groupIndex = line.item.groupIndex,
			})
		end
	end
	addon.guiutils.confirmDelete(delete)
end


local function clickAddAnd(self)
	local line = self:GetParent()
	local field, fieldInfo = addon.conditions.getDefaultField(line.item.event)
	addon.store.dispatch({
		name = 'addCondition',
		entryIndex = addon.guiutils.getSelectedEntryIndex(),
		groupIndex = line.item.groupIndex,
		field = field,
		comparison = fieldInfo.defaultComparison,
		value = fieldInfo.defaultValue,
	})
end


local function clickAddOr()
	local event = addon.conditions.getDefaultEvent()
	addon.store.dispatch({
		name = 'addConditionGroup',
		entryIndex = addon.guiutils.getSelectedEntryIndex(),
		event = event,
		conditions = addon.conditions.getDefaultConditions(event),
	})
end


local function changeEvent(_--[[self]], line, event)
	_G.CloseDropDownMenus()
	addon.store.dispatch({
		name = 'setConditionGroupEvent',
		entryIndex = addon.guiutils.getSelectedEntryIndex(),
		groupIndex = line.item.groupIndex,
		event = event,
		conditions = addon.conditions.getDefaultConditions(event),
	})
end


local function initEventDropdown(frame, level)
	local line = frame:GetParent()

	if level == 1 then
		local categories = {}
		for category, categoryInfo in addon.conditions.iterateCategories() do
			table.insert(categories, {value = category, name = categoryInfo.name})
		end
		table.sort(categories, addon.guiutils.compareByName)
		for _, item in ipairs(categories) do
			local info = {
				text = item.name,
				value = item.value,
				hasArrow = true,
				notCheckable = true,
			}
			_G.UIDropDownMenu_AddButton(info, level)
		end

	elseif level == 2 then
		local category = _G.UIDROPDOWNMENU_MENU_VALUE
		local events = {}
		for event, eventInfo in addon.conditions.iterateEvents(category) do
			table.insert(events, {value = event, name = eventInfo.name})
		end
		table.sort(events, addon.guiutils.compareByName)
		for _, item in ipairs(events) do
			local info = {
				text = item.name,
				value = item.value,
				checked = item.value == line.item.event,
				func = changeEvent,
				arg1 = line,
				arg2 = item.value,
			}
			_G.UIDropDownMenu_AddButton(info, level)
		end
	end
end


local function changeCondition(_--[[self]], line, condition)
	addon.store.dispatch({
		name = 'editCondition',
		entryIndex = addon.guiutils.getSelectedEntryIndex(),
		groupIndex = line.item.groupIndex,
		conditionIndex = line.item.conditionIndex,
		field = condition.field,
		comparison = condition.comparison,
		value = condition.value,
	})
end


local function initFieldDropdown(frame, level)
	local line = frame:GetParent()
	local old = line.item.condition
	local fields = {}
	for field, fieldInfo in addon.conditions.iterateFields(line.item.event) do
		table.insert(fields, {value = field, name = fieldInfo.name, info = fieldInfo})
	end
	table.sort(fields, addon.guiutils.compareByName)
	for _, item in ipairs(fields) do
		local condition = {
			field = item.value,
			comparison = item.info.defaultComparison,
			value = item.info.defaultValue,
		}
		local info = {
			text = item.name,
			value = item.value,
			checked = item.value == old.field,
			func = changeCondition,
			arg1 = line,
			arg2 = condition,
		}
		_G.UIDropDownMenu_AddButton(info, level)
	end
end


local function initComparisonDropdown(frame, level)
	local line = frame:GetParent()
	local old = line.item.condition
	for _, comparison in ipairs(line.item.fieldInfo.comparisons) do
		local condition = {
			field = old.field,
			comparison = comparison.key,
			value = old.value,
		}
		local info = {
			text = comparison.name,
			value = comparison.key,
			checked = comparison.key == old.comparison,
			func = changeCondition,
			arg1 = line,
			arg2 = condition,
		}
		_G.UIDropDownMenu_AddButton(info, level)
	end
end


local function initValueDropdown(frame, level)
	local line = frame:GetParent()
	local old = line.item.condition
	local values = {}
	for value, name in pairs(line.item.fieldInfo.values) do
		table.insert(values, {value = value, name = name})
	end
	table.sort(values, addon.guiutils.compareByName)
	for _, item in ipairs(values) do
		local condition = {
			field = old.field,
			comparison = old.comparison,
			value = item.value,
		}
		local info = {
			text = item.name,
			value = item.value,
			checked = item.value == old.value,
			func = changeCondition,
			arg1 = line,
			arg2 = condition,
		}
		_G.UIDropDownMenu_AddButton(info, level)
	end
end


local function changeConditionValue(self)
	_G.EditBox_ClearHighlight(self)
	local line = self:GetParent()
	local old = line.item.condition
	local value
	if self:IsNumeric() then
		value = self:GetNumber()
	else
		value = self:GetText()
	end
	local condition = {
		field = old.field,
		comparison = old.comparison,
		value = value,
	}
	changeCondition(self, line, condition)
end


local function createConditionsLine(parent, index)
	local line = addon.guiutils.create('Frame', 'Line' .. index, parent)
	line:SetSize(545, 25)

	local prefix = line:CreateFontString(
		'BACKGROUND', '$parentPrefix', 'GameFontHighlightSmallLeft')
	line.prefix = prefix
	prefix:SetPoint('LEFT')
	prefix:SetWidth(30)

	local addAnd = addon.guiutils.createTextButton('AddAnd', line, L['AND'], clickAddAnd)
	addAnd:SetPoint('LEFT', 30, 0)
	addon.guiutils.setupTooltip(
		addAnd, L['Add Condition to This Group'], L.help_condition_and, L.help_condition_no_fields)

	local addOr = addon.guiutils.createTextButton('AddOr', line, L['OR'], clickAddOr)
	addOr:SetPoint('LEFT')
	addon.guiutils.setupTooltip(addOr, L['Add Condition Group'], L.help_condition_or)

	local delete = addon.guiutils.createButton('Delete', line, 'UIPanelCloseButton', clickDelete)
	delete:SetPoint('TOPRIGHT')
	delete:SetSize(24, 24)
	addon.guiutils.setupTooltip(delete, _G.DELETE, '', L.help_condition_event_delete)

	local event = addon.guiutils.createSelect('Event', line, 200, initEventDropdown)
	event:SetPoint('TOPLEFT', -15, 0)
	addon.guiutils.setupTooltip(event, L['Event'], L.help_condition_event)
	addon.guiutils.setupTooltip(
		event.Button, L['Event'], L.help_condition_event, L.help_condition_event_change)

	local field = addon.guiutils.createSelect('Field', line, 150, initFieldDropdown)
	field:SetPoint('TOPLEFT', 15, 0)
	addon.guiutils.setupTooltip(field, L['Field'], L.help_condition_field)

	local comparison = addon.guiutils.createSelect('Comparison', line, 110, initComparisonDropdown)
	comparison:SetPoint('TOPLEFT', field, 'TOPRIGHT')
	addon.guiutils.setupTooltip(comparison, L['Comparison'], L.help_condition_comparison)

	local valueSelect = addon.guiutils.createSelect('ValueSelect', line, 165, initValueDropdown)
	valueSelect:SetPoint('TOPLEFT', comparison, 'TOPRIGHT')
	addon.guiutils.setupTooltip(valueSelect, L['Value'], L.help_condition_value)

	local valueEdit = addon.guiutils.create('EditBox', 'ValueEdit', line, 'InputBoxTemplate')
	valueEdit:SetPoint('TOPRIGHT', valueSelect)
	valueEdit:SetWidth(165)
	valueEdit:SetHeight(25)
	valueEdit:SetAutoFocus(false)
	valueEdit:SetScript('OnEditFocusLost', changeConditionValue)
	addon.guiutils.setupTooltip(valueEdit, L['Value'], L.help_condition_value)

	return line
end


local function clickCreateHelperConditionGroup(_--[[self]], group)
	addon.store.dispatch({
		name = 'addConditionGroup',
		entryIndex = addon.guiutils.getSelectedEntryIndex(),
		event = group.event,
		conditions = group.conditions,
	})
end


local function initConditionsHelpDropdown(_--[[frame]], level)
	for _, example in addon.conditions.iterateConditionExamples() do
		local info = {
			text = example.name,
			notCheckable = true,
			func = clickCreateHelperConditionGroup,
			arg1 = example.group,
		}
		_G.UIDropDownMenu_AddButton(info, level)
	end
end


local function changeEntryCooldown(self)
	local cooldown = self:GetText()
	if #cooldown == 0 or not addon.guiutils.isValidCooldown(cooldown) then
		cooldown = '0'
	end
	addon.store.dispatch({
		name = 'setEntryCooldown',
		entryIndex = addon.guiutils.getSelectedEntryIndex(),
		cooldown = cooldown,
	})
end


local function changeEntryWatch(self)
	local watch = not not self:GetChecked()
	addon.store.dispatch({
		name = 'setEntryWatch',
		entryIndex = addon.guiutils.getSelectedEntryIndex(),
		watch = watch,
	})
end


function addon.conditions.createGUI(parent)
	local frame = addon.guiutils.createSection({
		parent = parent,
		name = 'Conditions',
		height = 155,
		title = L['When...'],
		subtitle = L.conditions_subtitle,
		help = L.help_conditions,
		initHelpDropdown = initConditionsHelpDropdown,
		lineCount = 5,
		createLine = createConditionsLine,
	})

	local cooldown = addon.guiutils.create('EditBox', 'Cooldown', frame, 'InputBoxTemplate')
	cooldown:SetPoint('TOPRIGHT', 0, 3)
	cooldown:SetWidth(50)
	cooldown:SetHeight(25)
	cooldown:SetAutoFocus(false)
	cooldown:SetScript('OnTextChanged', addon.guiutils.onCooldownTextChanged)
	cooldown:SetScript('OnEditFocusLost', changeEntryCooldown)
	local cooldownHelp = L.help_condition_cooldown .. '\n\n' .. L.help_cooldown
	addon.guiutils.setupTooltip(cooldown, L['Cooldown'], cooldownHelp)

	local cooldownLabel = cooldown:CreateFontString(
		'$parentLabel', 'ARTWORK', 'GameFontHighlightSmall')
	cooldownLabel:SetPoint('RIGHT', cooldown, 'LEFT', -7, 0)
	cooldownLabel:SetText(L['Cooldown'] .. ':')

	local watch = addon.guiutils.create(
		'CheckButton', 'Watch', frame, 'OptionsSmallCheckButtonTemplate')
	watch:SetPoint('RIGHT', cooldown, 'LEFT', -150, 0)
	watch:SetScript('OnClick', changeEntryWatch)
	_G[watch:GetName() .. 'Text']:SetText(L['Watch'])
	_G[watch:GetName() .. 'Text']:SetTextColor(1.0, 1.0, 1.0)
	addon.guiutils.setupTooltip(watch, L['Watch'], L.help_condition_watch)

	return frame
end
