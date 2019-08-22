local _--[[kAddonName]], addon = ...


local function mockForActions(mock)
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

	return texts, delays, languages
end


local function runEntry(entry, globalAllowedTime)
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
	return addon.actions.runEntry(1, {})
end


addon.tests.register('unconditional delayed actions', function(mock)
	local entry = {
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
	local texts, delays = mockForActions(mock)
	local alwaysIndexes, cooldownIndex = runEntry(entry)
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
	assert(state.entries[1].actionGroups[1].allowedTime == 0)
	assert(state.entries[1].actionGroups[2].allowedTime == 0)
end)


addon.tests.register('actions in other languages', function(mock)
	local entry = {
		actionGroups = {
			{
				actions = {
					{ command = '[Taurahe] other language' },
					{ command = '[Nothing] unknown language' },
				},
			},
		}
	}
	local texts, _--[[delays]], languages = mockForActions(mock)
	runEntry(entry)
	assert(texts[1] == 'other language')
	-- Taurahe seems to be language ID 3.
	assert(languages[1] == 3)
	assert(texts[2] == 'unknown language')
	assert(languages[2] == 'default')
end)


addon.tests.register('actions with cooldowns', function(mock)
	local entry = {
		actionGroups = {
			{
				cooldown = '1',
				actions = {{ command = 'cooldown 1' }},
			},
			{
				cooldown = '2',
				actions = {{ command = 'cooldown 2' }},
			},
			{
				cooldown = '0',
				actions = {{ command = 'no cooldown' }},
			},
		}
	}
	local texts = mockForActions(mock)

	local alwaysIndexes, cooldownIndex = runEntry(entry)
	local state = addon.store.getState()
	local now = addon.utils.now()
	assert(alwaysIndexes[1] == 3)
	assert(cooldownIndex == 1)
	assert(texts[1] == 'cooldown 1')
	assert(texts[2] == 'no cooldown')
	assert(state.entries[1].actionGroups[1].allowedTime > now)
	assert(state.entries[1].actionGroups[2].allowedTime == 0)
	assert(state.entries[1].actionGroups[3].allowedTime == 0)

	alwaysIndexes, cooldownIndex = runEntry(entry)
	state = addon.store.getState()
	now = addon.utils.now()
	assert(alwaysIndexes[1] == 3)
	assert(cooldownIndex == 2)
	assert(texts[3] == 'cooldown 2')
	assert(texts[4] == 'no cooldown')
	assert(state.entries[1].actionGroups[1].allowedTime > now)
	assert(state.entries[1].actionGroups[2].allowedTime > now)
	assert(state.entries[1].actionGroups[1].allowedTime < state.entries[1].actionGroups[2].allowedTime)
	assert(state.entries[1].actionGroups[3].allowedTime == 0)
end)


addon.tests.register('real (unmocked) action', function()
	local entry = {
		actionGroups = {
			{
				actions = {
					{ command = '[Taurahe] /say Moo and such.', delay = 0 },
					{ command = '/flop', delay = 1 },
				},
			},
		}
	}
	addon.utils.print('Two actual commands should run: a /say in Taurahe, and /flop.')
	local alwaysIndexes, cooldownIndex = runEntry(entry)
	assert(alwaysIndexes[1] == 1)
	assert(cooldownIndex == nil)
end)
