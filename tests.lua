local _--[[kAddonName]], addon = ...
addon.tests = {}

local tests = {}


function addon.tests.register(name, func)
	table.insert(tests, {name, func})
end


function addon.tests.run()
	addon.utils.print('Running %d tests...', #tests)

	local failures = 0
	local realState = addon.store.getState()
	local blankState = { globalCooldown = '0', globalAllowedTime = 0, entries = {} }
	local mocks

	local function mock(obj, name, value)
		table.insert(mocks, 1, {obj, name, obj[name]})
		obj[name] = value
	end

	for _, test in ipairs(tests) do
		addon.store.dispatch({ name = 'setState', state = blankState })
		mocks = {}
		local name = test[1]
		local func = test[2]
		local function onError(err)
			_G.geterrorhandler()(('%s (in test: %s)'):format(err, name))
		end
		local success = xpcall(func, onError, mock)
		if not success then
			failures = failures + 1
		end
		for _, record in ipairs(mocks) do
			record[1][record[2]] = record[3]
		end
	end

	addon.utils.print('Ran %d tests with %d failures.', #tests, failures)
	addon.store.dispatch({ name = 'setState', state = realState })
end


function addon.tests.testEvent(mock, conditionGroup, eventArgs)
	local callCount = 0

	local function fakeRunEntry(entryIndex)
		callCount = callCount + 1
		assert(entryIndex == 1)
	end

	mock(addon.actions, 'runEntry', fakeRunEntry)

	addon.store.dispatch({
		name = 'createEntry',
		conditionGroups = {conditionGroup},
	})

	addon.events.trigger(unpack(eventArgs))

	assert(callCount == 1)
end
