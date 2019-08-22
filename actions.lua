local kAddonName, addon = ...
addon.actions = {}
local L = LibStub('AceLocale-3.0'):GetLocale(kAddonName)

addon.actions.commandExecutor = _G.ChatEdit_SendText
addon.actions.delayedCommandExecutor = _G.C_Timer.After

local actionEditbox = _G.CreateFrame('EditBox', kAddonName .. '_ActionEditBox')
actionEditbox:Hide()


local function getLanguageID(target)
	target = target:lower()
	for i = 1, _G.GetNumLanguages() do
		local language, languageID = _G.GetLanguageByIndex(i)
		if language:lower() == target then
			return languageID
		end
	end
	return nil
end


local function execCommand(command)
	local normalizedCommand = command
	local language, rest = command:match('^%[(.-)%]%s*(.+)')
	actionEditbox.languageID = nil
	if language and rest then
		actionEditbox.languageID = getLanguageID(language)
		normalizedCommand = rest
	end
	actionEditbox:SetText(normalizedCommand)
	local success, err = pcall(addon.actions.commandExecutor, actionEditbox)
	if not success then
		addon.utils.softerror('Failed to run command\nCommand: %s\nError: %s', command, err)
	end
end


local function execDelayedCommand(command, delay)
	local function exec()
		execCommand(command)
	end
	addon.actions.delayedCommandExecutor(delay, exec)
end


local function normalizeFieldName(name)
	return name:gsub('%s', ''):lower()
end


local function normalizeFields(fields)
	local normalized = {}
	for name, value in pairs(fields) do
		local normalizedName = normalizeFieldName(name)
		normalized[normalizedName] = value
	end
	return normalized
end


local function fillCommandFields(command, fields)
	local function replaceToken(match, fieldName)
		local normalizedName = normalizeFieldName(fieldName)
		return tostring(fields[normalizedName] or match)
	end
	return (command:gsub('({(.-)})', replaceToken))
end


local function runGroup(group, fields)
	for _, action in ipairs(group.actions) do
		local command = fillCommandFields(action.command, fields)
		if #command > 0 then
			execDelayedCommand(command, action.delay)
		end
	end
end


local function compareByAllowedTime(left, right)
	if left.group.allowedTime == right.group.allowedTime then
		return left.index < right.index
	end
	return left.group.allowedTime < right.group.allowedTime
end

local function sortGroupsByOldestAllowedTime(groups)
	local sortable = {}
	for i, group in ipairs(groups) do
		table.insert(sortable, {index = i, group = group})
	end
	table.sort(sortable, compareByAllowedTime)
	return sortable
end


local function runGroups(groups, fields, globalAllowedTime)
	local now = addon.utils.now()
	local sorted = sortGroupsByOldestAllowedTime(groups)
	local alwaysIndexes = {}
	local cooldownIndex = nil
	for _, item in ipairs(sorted) do
		if item.group.ignoreGlobalCooldown or now > globalAllowedTime then
			if item.group.cooldown == '0' then
				table.insert(alwaysIndexes, item.index)
				runGroup(item.group, fields)
			elseif not cooldownIndex then
				if now > item.group.allowedTime then
					cooldownIndex = item.index
					runGroup(item.group, fields)
				end
			end
		end
	end
	return alwaysIndexes, cooldownIndex
end


function addon.actions.runEntry(entryIndex, fields)
	local state = addon.store.getState()
	local entry = state.entries[entryIndex]
	local normalizedFields = normalizeFields(fields)
	local alwaysIndexes, cooldownIndex = runGroups(
		entry.actionGroups, normalizedFields, state.globalAllowedTime)
	local didSomething = #alwaysIndexes > 0 or not not cooldownIndex
	if didSomething then
		addon.store.dispatch({
			name = 'updateAllowedTime',
			entryIndex = entryIndex,
			actionGroupIndexes = {cooldownIndex},
		})
	end
	return alwaysIndexes, cooldownIndex
end


function addon.actions.describe(groups)
	if #groups == 0 then
		return ('[%s]'):format(L['no actions configured'])
	end
	local fullDescription = {}
	for _, group in ipairs(groups) do
		local description = {}
		for _, action in ipairs(group.actions) do
			table.insert(description, action.command)
		end
		table.insert(fullDescription, table.concat(description, ' ' .. L['AND'] .. ' '))
	end
	return table.concat(fullDescription, ' ;; ')
end


function addon.actions.iterateExamples()
	return ipairs({
		{
			name = 'Delayed speech',
			group = {
				actions = {
					{delay = 0, command = '/say You...'},
					{delay = 1, command = '/say ...shall not...'},
					{delay = 2, command = '/say PASS!'},
				},
			},
		},
	})
end
