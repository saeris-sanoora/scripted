local kAddonName, addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(kAddonName)


local function updateEntryLine(line, item)
	line.add:Hide()
	line.import:Hide()
	line.delete:Hide()
	line.export:Hide()
	line.select:Hide()

	if item.kind == 'entry' then
		line.delete:Show()
		line.export:Show()
		line.select:Show()
		line.select:SetText(item.description)
		if item.isSelected then
			line.select:LockHighlight()
		else
			line.select:UnlockHighlight()
		end

	elseif item.kind == 'create' then
		line.add:Show()
		line.import:Show()
	end
end


local function describeEntry(entry)
	local success, conditionsText = pcall(addon.conditions.describe, entry.conditions)
	if success and entry.watch then
		conditionsText = ('[+%s] %s'):format(L['Watch'], conditionsText)
	end
	if #conditionsText > 90 then
		conditionsText = conditionsText:sub(1, 90) .. '...'
	end
	local _, actionsText = pcall(addon.actions.describe, entry.actions)
	if #actionsText > 90 then
		actionsText = actionsText:sub(1, 90) .. '...'
	end
	return ('%s %s\n    %s %s'):format(L['When...'], conditionsText, L['Then...'], actionsText)
end


local function flattenEntries(entries, selectedIndex)
	local flat = {}
	for i, entry in ipairs(entries) do
		table.insert(flat, {
			kind = 'entry',
			entryIndex = i,
			entry = entry,
			isSelected = i == selectedIndex,
			description = describeEntry(entry),
		})
	end
	table.insert(flat, {kind = 'create'})
	return flat
end


local function updateEntriesGUI(frame, state)
	frame.cooldown:SetText(state.globalCooldown)
	local items = flattenEntries(state.entries, state.selectedEntryIndex)
	addon.guiutils.updateScroller(frame.content.scroller, items, updateEntryLine)
end


function addon.config.updateGUI(parent)
	local state = addon.store.getState()
	if state.isEditing then
		updateEntriesGUI(parent.entries, state)
		local hasSelected = state.selectedEntryIndex > 0
		local entry = hasSelected and state.entries[state.selectedEntryIndex] or nil
		addon.conditions.updateGUI(parent.conditions, entry)
		addon.actions.updateGUI(parent.actions, entry)
	else
		addon.guiutils.closePrompts()
	end
end


local function clickCreate()
	local event = addon.conditions.getDefaultEvent()
	local conditions = addon.conditions.getDefaultConditions(event)
	local action = {
		delay = 0,
		command = L.default_command,
	}
	addon.store.dispatch({
		name = 'createEntry',
		conditions = {{event = event, conditions = conditions}},
		actions = {{actions = {action}}},
	})
end


local function importEntryText(entryText)
	local func, err = loadstring('return ' .. entryText)
	if not func then
		addon.utils.print('%s: %s (%s)', L['Import failed'], L['Could not parse import text'], err)
		return
	end
	local importTable = func()
	if type(importTable) ~= 'table' or importTable.version ~= addon.config.kVersion then
		addon.utils.print('%s: %s', L['Import failed'], L['Invalid format or incompatible version'])
		return
	end
	local entry = importTable.entry
	addon.store.dispatch({
		name = 'createEntry',
		cooldown = entry.cooldown,
		watch = entry.watch,
		conditions = entry.conditions,
		actions = entry.actions,
	})
end


local function clickImport()
	addon.guiutils.promptImport(importEntryText)
end


local function clickExport(self)
	local line = self:GetParent()
	local exportTable = {
		version = addon.config.kVersion,
		entry = line.item.entry,
	}
	local exportText = addon.utils.tabletostring(exportTable)
	addon.guiutils.promptExport(exportText)
end


local function clickDelete(self)
	local function delete()
		local line = self:GetParent()
		addon.store.dispatch({ name = 'deleteEntry', index = line.item.entryIndex })
	end
	addon.guiutils.confirmDelete(delete)
end


local function clickSelect(self)
	local line = self:GetParent()
	addon.store.dispatch({ name = 'selectEntry', index = line.item.entryIndex })
end


local function createEntriesLine(parent, index)
	local line = addon.guiutils.create('Frame', 'Line' .. index, parent)
	line:SetSize(545, 25)

	local add = addon.guiutils.createTextButton('Add', line, _G.ADD, clickCreate)
	add:SetPoint('LEFT')
	addon.guiutils.setupTooltip(add, L['Add Entry'], L.help_entry_add)

	local import = addon.guiutils.createTextButton('Import', line, L['Import'], clickImport)
	import:SetPoint('LEFT', add, 'RIGHT', 10, 0)
	addon.guiutils.setupTooltip(import, L['Import Entry'], L.help_entry_import)

	local selectButton = addon.guiutils.createButton('Select', line, nil, clickSelect)
	selectButton:SetPoint('LEFT')
	selectButton:SetSize(490, 22)
	selectButton:SetNormalFontObject(_G.GameFontHighlightSmallLeft)
	selectButton:SetHighlightFontObject(_G.GameFontNormalSmallLeft)

	local delete = addon.guiutils.createButton('Delete', line, 'UIPanelCloseButton', clickDelete)
	delete:SetPoint('TOPRIGHT')
	delete:SetSize(24, 24)
	addon.guiutils.setupTooltip(delete, _G.DELETE, '')

	local export = addon.guiutils.createButton('Export', line, nil, clickExport)
	export:SetNormalTexture('Interface/Buttons/UI-Panel-BiggerButton-Up')
	export:SetPushedTexture('Interface/Buttons/UI-Panel-BiggerButton-Down')
	export:SetHighlightTexture('Interface/Buttons/UI-Panel-MinimizeButton-Highlight', 'ADD')
	export:SetPoint('TOPRIGHT', delete, 'TOPLEFT', -5, 0)
	export:SetSize(24, 24)
	addon.guiutils.setupTooltip(export, L['Export Entry'], L.help_entry_export)

	return line
end


local function getAboutText()
	local version = _G.GetAddOnMetadata(kAddonName, 'Version')
	local author =_G.GetAddOnMetadata(kAddonName, 'Author')
	local color = _G.ITEM_QUALITY_COLORS[6].hex
	return ('%sVersion %s\nby %s|r'):format(color, version, author)
end


local function clickCreateHelperEntry(_--[[self]], entry)
	addon.store.dispatch({
		name = 'createEntry',
		cooldown = entry.cooldown,
		conditions = entry.conditions,
		actions = entry.actions,
	})
end


local function initEntriesHelpDropdown(_--[[frame]], level)
	for _, example in addon.conditions.iterateEntryExamples() do
		local info = {
			text = example.name,
			notCheckable = true,
			func = clickCreateHelperEntry,
			arg1 = example.entry,
		}
		_G.UIDropDownMenu_AddButton(info, level)
	end
end


local function changeGlobalCooldown(self)
	local cooldown = self:GetText()
	if #cooldown == 0 or not addon.guiutils.isValidCooldown(cooldown) then
		cooldown = '0'
	end
	addon.store.dispatch({
		name = 'setGlobalCooldown',
		cooldown = cooldown,
	})
end


local function createEntriesGUI(parent)
	local frame = addon.guiutils.createSection({
		parent = parent,
		name = 'Entries',
		height = 200,
		title = kAddonName,
		subtitle = L.entries_subtitle,
		help = getAboutText() .. '\n\n' .. L.help_entries,
		initHelpDropdown = initEntriesHelpDropdown,
		lineCount = 8,
		createLine = createEntriesLine,
	})

	local cooldown = addon.guiutils.create('EditBox', 'Cooldown', frame, 'InputBoxTemplate')
	cooldown:SetPoint('TOPRIGHT', 0, 3)
	cooldown:SetWidth(50)
	cooldown:SetHeight(25)
	cooldown:SetAutoFocus(false)
	cooldown:SetScript('OnTextChanged', addon.guiutils.onCooldownTextChanged)
	cooldown:SetScript('OnEditFocusLost', changeGlobalCooldown)
	local cooldownHelp = L.help_entry_cooldown .. '\n\n' .. L.help_cooldown
	addon.guiutils.setupTooltip(cooldown, L['Cooldown'], cooldownHelp)

	local cooldownLabel = cooldown:CreateFontString(
		'$parentLabel', 'ARTWORK', 'GameFontHighlightSmall')
	cooldownLabel:SetPoint('RIGHT', cooldown, 'LEFT', -7, 0)
	cooldownLabel:SetText(L['Cooldown'] .. ':')

	return frame
end


function addon.config.createGUISections(parent)
	local entries = createEntriesGUI(parent)
	entries:SetPoint('TOPLEFT', 20, -15)
	entries:SetPoint('TOPRIGHT', -20, -15)
	local conditions = addon.conditions.createGUI(parent)
	conditions:SetPoint('TOPLEFT', entries, 'BOTTOMLEFT', 0, -15)
	conditions:SetPoint('TOPRIGHT', entries, 'BOTTOMRIGHT', 0, -15)
	local actions = addon.actions.createGUI(parent)
	actions:SetPoint('TOPLEFT', conditions, 'BOTTOMLEFT', 0, -15)
	actions:SetPoint('TOPRIGHT', conditions, 'BOTTOMRIGHT', 0, -15)
end
