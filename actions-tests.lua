local _--[[kAddonName]], addon = ...


local function mockForActions(mock, entry, globalAllowedTime)
	local texts = {}
	local languages = {}
	local delays = {}

	local function fakeCommandExecutor(editbox)
		table.insert(texts, editbox:GetText())
		table.insert(languages, editbox.languageID or 'default')
	end

	local function fakeDelayedCommandExecutor(delay, exec)
		table.insert(delays, delay)
		exec()
	end

	mock(addon.actions, 'commandExecutor', fakeCommandExecutor)
	mock(addon.actions, 'delayedCommandExecutor', fakeDelayedCommandExecutor)

	addon.store.dispatch({ name = 'setGlobalCooldown', cooldown = '3' })
	if globalAllowedTime then
		addon.store.dispatch({ name = 'setState', state = { globalAllowedTime = globalAllowedTime }})
	end
	addon.store.dispatch({
		name = 'createEntry',
		cooldown = entry.cooldown,
		conditionGroups = entry.conditionGroups,
		actionGroups = entry.actionGroups,
	})

	return texts, languages, delays
end


addon.tests.register('unconditional actions', function(mock)
	local entry = {
		cooldown = '3',
		actionGroups = {
			{
				actions = {
					{ command = '1.1', delay = 0 },
					{ command = '1.2', delay = 1 },
				},
			},
			{
				actions = {
					{ command = '2.1', delay = 2 },
					{ command = '2.2', delay = 3 },
				},
			},
		}
	}
	local texts, _--[[languages]], delays = mockForActions(mock, entry)
	local alwaysIndexes, cooldownIndex = addon.actions.runEntry(1, {})
	local state = addon.store.getState()
	local now = addon.utils.now()
	assert(alwaysIndexes[1] == 1)
	assert(alwaysIndexes[2] == 2)
	assert(cooldownIndex == nil)
	assert(texts[1] == '1.1')
	assert(delays[1] == 0)
	assert(texts[2] == '1.2')
	assert(delays[2] == 1)
	assert(texts[3] == '2.1')
	assert(delays[3] == 2)
	assert(texts[4] == '2.2')
	assert(delays[4] == 3)
	assert(state.globalAllowedTime > now)
	assert(state.entries[1].allowedTime > now)
	assert(state.entries[1].actionGroups[1].allowedTime <= now)
	assert(state.entries[1].actionGroups[2].allowedTime <= now)
end)
