local _--[[kAddonName]], addon = ...
local Immutable = LibStub('Immutable-1.0')

local kDefaultState = {
	isEditing = false,
	globalCooldown = '0',
	globalAllowedTime = 0,
	selectedEntryIndex = 0,
	entries = {},
}


local function normalizeConditions(conditions)
	for _, condition in ipairs(conditions) do
		assert(condition.field and condition.comparison and condition.value)
	end
end


local function normalizeConditionGroups(conditions)
	for _, group in ipairs(conditions) do
		assert(group.event)
		normalizeConditions(group.conditions)
	end
end


local function normalizeActions(actions)
	for _, action in ipairs(actions) do
		action.delay = action.delay or 0
		action.command = action.command or ''
	end
end


local function normalizeActionGroups(actions)
	for _, group in ipairs(actions) do
		group.cooldown = group.cooldown or '0'
		group.allowedTime = 0
		if group.ignoreGlobalCooldown == nil then
			group.ignoreGlobalCooldown = false
		end
		group.actions = group.actions or {}
		normalizeActions(group.actions)
	end
end


local function loadConfig(action)
	return {
		isEditing = false,
		globalCooldown = action.config.globalCooldown,
		globalAllowedTime = 0,
		selectedEntryIndex = 0,
		entries = Immutable.assign(action.config.entries),
	}
end


local function startEditing()
	return { isEditing = true }
end


local function stopEditing()
	return { isEditing = false }
end


local function setGlobalCooldown(action)
	local cooldown = '0'
	if action.cooldown and #action.cooldown > 0 then
		cooldown = tostring(action.cooldown)
	end
	return {
		globalCooldown = cooldown,
		globalAllowedTime = 0,
	}
end


local function selectEntry(action)
	return { selectedEntryIndex = action.index }
end


local function createEntry(action, state)
	local entry = {
		cooldown = action.cooldown or '0',
		allowedTime = 0,
		watch = false,
		conditions = action.conditions or {},
		actions = action.actions or {},
	}
	normalizeConditionGroups(entry.conditions)
	normalizeActionGroups(entry.actions)
	local index = #state.entries + 1
	return {
		selectedEntryIndex = index,
		entries = Immutable.insert(entry),
	}
end


local function editEntry(action, change)
	return {
		entries = {
			[action.entryIndex] = change
		},
	}
end


local function setEntryCooldown(action)
	local cooldown = '0'
	if action.cooldown and #action.cooldown > 0 then
		cooldown = tostring(action.cooldown)
	end
	return editEntry(action, {
		cooldown = cooldown,
		allowedTime = 0,
	})
end


local function setEntryWatch(action)
	return editEntry(action, {
		watch = action.watch,
	})
end


local function deleteEntry(action)
	return {
		selectedEntryIndex = 0,
		entries = Immutable.remove(action.index),
	}
end


local function addConditionGroup(action)
	assert(action.event)
	local conditions = action.conditions or {}
	normalizeConditions(conditions)
	return editEntry(action, {
		conditions = Immutable.insert({
			event = action.event,
			conditions = conditions,
		}),
	})
end


local function setConditionGroupEvent(action)
	return editEntry(action, {
		conditions = {
			[action.groupIndex] = Immutable.assign({
				event = action.event,
				conditions = action.conditions or {},
			}),
		},
	})
end


local function deleteConditionGroup(action)
	return editEntry(action, {
		conditions = Immutable.remove(action.groupIndex),
	})
end


local function addCondition(action)
	return editEntry(action, {
		conditions = {
			[action.groupIndex] = {
				conditions = Immutable.insert({
					field = action.field,
					comparison = action.comparison,
					value = action.value,
				}),
			},
		},
	})
end


local function editCondition(action)
	return editEntry(action, {
		conditions = {
			[action.groupIndex] = {
				conditions = {
					[action.conditionIndex] = {
						field = action.field,
						comparison = action.comparison,
						value = action.value,
					},
				},
			},
		},
	})
end


local function deleteCondition(action)
	return editEntry(action, {
		conditions = {
			[action.groupIndex] = {
				conditions = Immutable.remove(action.conditionIndex),
			},
		},
	})
end


local function addActionGroup(action)
	local ignoreGlobalCooldown = action.ignoreGlobalCooldown
	if ignoreGlobalCooldown == nil then
		ignoreGlobalCooldown = false
	end
	local actions = action.actions or {}
	normalizeActions(actions)
	return editEntry(action, {
		actions = Immutable.insert({
			cooldown = action.cooldown or '0',
			allowedTime = 0,
			ignoreGlobalCooldown = ignoreGlobalCooldown,
			actions = actions,
		}),
	})
end


local function setActionGroupCooldown(action)
	local cooldown = '0'
	if action.cooldown and #action.cooldown > 0 then
		cooldown = tostring(action.cooldown)
	end
	return editEntry(action, {
		actions = {
			[action.groupIndex] = {
				cooldown = cooldown,
				allowedTime = 0,
			},
		},
	})
end


local function setActionGroupIgnoreGlobalCooldown(action)
	return editEntry(action, {
		actions = {
			[action.groupIndex] = {
				ignoreGlobalCooldown = action.ignore,
			},
		},
	})
end


local function deleteActionGroup(action)
	return editEntry(action, {
		actions = Immutable.remove(action.groupIndex),
	})
end


local function addAction(action)
	return editEntry(action, {
		actions = {
			[action.groupIndex] = {
				actions = Immutable.insert({
					delay = action.delay or 0,
					command = action.command or '',
				}),
			},
		},
	})
end


local function editAction(action)
	return editEntry(action, {
		actions = {
			[action.groupIndex] = {
				actions = {
					[action.actionIndex] = {
						delay = action.delay or 0,
						command = action.command or '',
					},
				},
			},
		},
	})
end


local function deleteAction(action, state)
	local group = state.entries[action.entryIndex].actions[action.groupIndex]
	if #group.actions == 1 and action.actionIndex == 1 then
		return deleteActionGroup(action, state)
	end
	return editEntry(action, {
		actions = {
			[action.groupIndex] = {
				actions = Immutable.remove(action.actionIndex),
			},
		},
	})
end


local function updateAllowedTime(action, state)
	local globalAllowedTime = addon.utils.getCooldownAllowedTime(state.globalCooldown)

	local entry = state.entries[action.entryIndex]
	local entryAllowedTime = addon.utils.getCooldownAllowedTime(entry.cooldown)

	local actionGroupChanges = {}
	for _, groupIndex in ipairs(action.actionGroupIndexes) do
		local group = entry.actions[groupIndex]
		local allowedTime = addon.utils.getCooldownAllowedTime(group.cooldown)
		actionGroupChanges[groupIndex] = {
			allowedTime = allowedTime,
		}
	end

	return {
		globalAllowedTime = globalAllowedTime,
		entries = {
			[action.entryIndex] = {
				allowedTime = entryAllowedTime,
				actions = actionGroupChanges,
			},
		},
	}
end


local kActionHandlers = {
	loadConfig = loadConfig,
	startEditing = startEditing,
	stopEditing = stopEditing,
	setGlobalCooldown = setGlobalCooldown,
	selectEntry = selectEntry,
	createEntry = createEntry,
	setEntryCooldown = setEntryCooldown,
	setEntryWatch = setEntryWatch,
	deleteEntry = deleteEntry,
	addConditionGroup = addConditionGroup,
	setConditionGroupEvent = setConditionGroupEvent,
	deleteConditionGroup = deleteConditionGroup,
	addCondition = addCondition,
	editCondition = editCondition,
	deleteCondition = deleteCondition,
	addActionGroup = addActionGroup,
	setActionGroupCooldown = setActionGroupCooldown,
	setActionGroupIgnoreGlobalCooldown = setActionGroupIgnoreGlobalCooldown,
	deleteActionGroup = deleteActionGroup,
	addAction = addAction,
	editAction = editAction,
	deleteAction = deleteAction,
	updateAllowedTime = updateAllowedTime,
}

local function reduceState(state, action)
	if not state then
		return kDefaultState
	end
	local handler = kActionHandlers[action.name]
	assert(handler, action.name)
	local changes = handler(action, state)
	return Immutable.transform(state, changes)
end

addon.store = addon.utils.createStore(reduceState)
