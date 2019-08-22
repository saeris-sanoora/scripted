local kAddonName, addon = ...
addon.conditions = {}
local L = LibStub('AceLocale-3.0'):GetLocale(kAddonName)

local kFieldTypes = {
	identifier = {
		comparisons = {'eq', 'ne'},
	},
	text = {
		comparisons = {'eq', 'ne', 'matches', 'notmatches'},
	},
	number = {
		comparisons = {'eq', 'ne', 'lt', 'gt'},
		numeric = true,
	},
	boolean = {
		comparisons = {'eq'},
		values = {
			[true] = L['True'],
			[false] = L['False'],
		}
	},
}

local kComparisons = {
	eq = {
		name = L['Is'],
		func = function(actual, wanted)
			return actual == wanted
		end,
	},
	ne = {
		name = L['Is Not'],
		func = function(actual, wanted)
			return actual ~= wanted
		end,
	},
	matches = {
		name = L['Matches'],
		func = function(actual, wanted)
			return addon.utils.matches(actual, wanted)
		end,
	},
	notmatches = {
		name = L['Does Not Match'],
		func = function(actual, wanted)
			return not addon.utils.matches(actual, wanted)
		end,
	},
	lt = {
		name = L['Less Than'],
		func = function(actual, wanted)
			return actual < wanted
		end,
	},
	gt = {
		name = L['Greater Than'],
		func = function(actual, wanted)
			return actual > wanted
		end,
	},
}

local categoriesRegistry = {}
local eventsRegistry = {}


local function getCategoryEvent(category, event)
	return category .. '_' .. event
end


local function checkSingle(condition, fields)
	local compare = kComparisons[condition.comparison].func
	return compare(fields[condition.field], condition.value)
end


local function checkGroup(group, categoryEvent, fields)
	if group.event ~= categoryEvent then
		return false
	end
	return addon.utils.all(group.conditions, checkSingle, fields)
end


local function checkEntry(entry, categoryEvent, fields)
	if addon.utils.now() < entry.allowedTime then
		return false
	end
	return addon.utils.any(entry.conditionGroups, checkGroup, categoryEvent, fields)
end


local function getEventName(event)
	local eventInfo = eventsRegistry[event]
	assert(eventInfo, event)
	return eventInfo.name
end


local function getFieldInfo(event, field)
	local info = eventsRegistry[event].fields[field]
	assert(info, (event or '') .. (field or ''))
	local typeInfo = kFieldTypes[info.valueType]
	local comparisons = {}
	for _, comparison in ipairs(typeInfo.comparisons) do
		local name = kComparisons[comparison].name
		table.insert(comparisons, {key = comparison, name = name})
	end
	local values = info.values or typeInfo.values
	-- Don't use a ternary for this in case the value is false.
	local defaultValue = ''
	if values then
		defaultValue = next(values)
	end
	local publicInfo = {
		name = info.name,
		comparisons = comparisons,
		defaultComparison = comparisons[1].key,
		numeric = typeInfo.numeric,
		values = values,
		defaultValue = defaultValue,
	}
	return publicInfo
end


local function getValueName(event, field, value)
	local values = getFieldInfo(event, field).values
	if values then
		return values[value]
	end
	return value
end


local function getConditionNames(event, condition)
	local fieldInfo = getFieldInfo(event, condition.field)
	return {
		field = fieldInfo.name,
		comparison = kComparisons[condition.comparison].name,
		value = getValueName(event, condition.field, condition.value),
	}
end


local function convertFieldsToFriendly(event, fields)
	local friendly = {}
	for field, value in pairs(fields) do
		local fieldName = getFieldInfo(event, field).name
		local valueName = getValueName(event, field, value)
		friendly[fieldName] = tostring(valueName)
	end
	return friendly
end


local function logEvent(event, fields)
	local eventInfo = eventsRegistry[event]
	local fieldsList = {}
	local friendlyFields = convertFieldsToFriendly(event, fields)
	for fieldName, valueName in pairs(friendlyFields) do
		table.insert(fieldsList, ('%s = %q'):format(fieldName, valueName))
	end
	local fieldsText = _G.NONE
	if #fieldsList > 0 then
		fieldsText = table.concat(fieldsList, ', ')
	end
	addon.utils.print(L.watch_message, eventInfo.name, fieldsText)
end


function addon.conditions.registerCategory(category, name, events, watch, unwatch)
	assert(not categoriesRegistry[category])
	assert(type(category) == 'string')
	assert(type(name) == 'string')
	assert(type(events) == 'table')
	assert(type(watch) == 'function')
	assert(type(unwatch) == 'function')
	local categoryInfo = {
		name = name,
		watch = watch,
		unwatch = unwatch,
		events = {},
	}
	categoriesRegistry[category] = categoryInfo
	for event, eventInfo in pairs(events) do
		assert(eventInfo.name, category)
		local categoryEvent = getCategoryEvent(category, event)
		assert(not eventsRegistry[categoryEvent])
		local fullEventInfo = {
			category = category,
			categoryInfo = categoryInfo,
			active = false,
			event = event,
			name = eventInfo.name,
			fields = eventInfo.fields or {},
			entries = {},
		}
		eventsRegistry[categoryEvent] = fullEventInfo
		categoryInfo.events[categoryEvent] = fullEventInfo
	end
end


local function addEntryEvents(entryIndex, entry)
	for _, group in ipairs(entry.conditionGroups) do
		local event = group.event
		local eventInfo = eventsRegistry[event]
		if eventInfo then
			if not eventInfo.active then
				eventInfo.active = true
				eventInfo.categoryInfo.watch(eventInfo.event)
			end
			eventInfo.entries[entryIndex] = entry
		else
			addon.utils.softerror('Unknown event in config: %q', event)
		end
	end
end


function addon.conditions.onStoreChange()
	local state = addon.store.getState()
	local entries = state.isEditing and {} or state.entries

	for _--[[event]], eventInfo in pairs(eventsRegistry) do
		if next(eventInfo.entries) then
			eventInfo.entries = {}
		end
	end

	for i, entry in ipairs(entries) do
		addEntryEvents(i, entry)
	end

	for _--[[event]], eventInfo in pairs(eventsRegistry) do
		if eventInfo.active and not next(eventInfo.entries) then
			eventInfo.active = false
			eventInfo.categoryInfo.unwatch(eventInfo.event)
		end
	end
end


function addon.conditions.dispatchEvent(category, event, fields)
	local categoryEvent = getCategoryEvent(category, event)
	local eventInfo = eventsRegistry[categoryEvent]
	assert(eventInfo, categoryEvent)
	for entryIndex, entry in pairs(eventInfo.entries) do
		if entry.watch then
			logEvent(categoryEvent, fields)
		end
		if checkEntry(entry, categoryEvent, fields) then
			local friendlyFields = convertFieldsToFriendly(categoryEvent, fields)
			addon.actions.runEntry(entryIndex, friendlyFields)
		end
	end
end


function addon.conditions.describe(groups)
	local fullDescription = {}
	for _, group in ipairs(groups) do
		local groupDescription = {
			getEventName(group.event),
		}
		for _, condition in ipairs(group.conditions) do
			local names = getConditionNames(group.event, condition)
			local description = ('%s %s %q'):format(names.field, names.comparison, names.value)
			table.insert(groupDescription, description)
		end
		table.insert(fullDescription, table.concat(groupDescription, ' ' .. L['AND'] .. ' '))
	end
	return table.concat(fullDescription, ' ' .. L['OR'] .. ' ')
end


function addon.conditions.iterateEntryExamples()
	return ipairs({
		{
			name = 'Say something when using a Hearthstone',
			entry = {
				conditions = {
					{
						event = 'combat_ability_start',
						conditions = {
							{field = 'abilityName', comparison = 'eq', value = 'Hearthstone'},
							{field = 'srcAffiliation', comparison = 'eq', value = _G.COMBATLOG_OBJECT_AFFILIATION_MINE},
						},
					},
				},
				actions = {
					actions = {
						{command = '/say Well, time for me to hit the old dusty trail...'},
					},
				},
			},
		},
	})
end


function addon.conditions.iterateConditionExamples()
	return ipairs({
		{
			name = 'You deal a killing blow to a player',
			group = {
				event = 'combat_death',
				conditions = {
					{field = 'srcAffiliation', comparison = 'eq', value = _G.COMBATLOG_OBJECT_AFFILIATION_MINE},
					{field = 'destType', comparison = 'eq', value = _G.COMBATLOG_OBJECT_TYPE_PLAYER},
				},
			},
		},
	})
end


function addon.conditions.iterateCategories()
	return pairs(categoriesRegistry)
end


function addon.conditions.getDefaultEvent()
	return (next(eventsRegistry))
end


function addon.conditions.iterateEvents(category)
	local categoryInfo = categoriesRegistry[category]
	assert(categoryInfo, category)
	return pairs(categoryInfo.events)
end


function addon.conditions.getDefaultField(event)
	local eventInfo = eventsRegistry[event]
	assert(eventInfo, event)
	local field = next(eventInfo.fields)
	if not field then
		return nil, nil
	end
	local fieldInfo = getFieldInfo(event, field)
	return field, fieldInfo
end


function addon.conditions.getDefaultConditions(event)
	local eventInfo = eventsRegistry[event]
	assert(eventInfo, event)
	return eventInfo.defaultConditions or {}
end


function addon.conditions.iterateFields(event)
	local eventInfo = eventsRegistry[event]
	assert(eventInfo, event)
	local fields = {}
	for field in pairs(eventInfo.fields) do
		fields[field] = getFieldInfo(event, field)
	end
	return pairs(fields)
end


function addon.conditions.getEventName(event)
	return getEventName(event)
end


function addon.conditions.getConditionNames(event, condition)
	return getConditionNames(event, condition)
end


function addon.conditions.getFieldInfo(event, field)
	return getFieldInfo(event, field)
end
