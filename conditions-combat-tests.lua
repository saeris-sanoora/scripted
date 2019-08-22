local _--[[kAddonName]], addon = ...


addon.tests.register('combat event "enter"', function(mock)
	local conditions = { event = 'combat_enter', conditions = {} }
	local eventArgs = {'PLAYER_REGEN_DISABLED'}
	addon.tests.testEvent(mock, conditions, eventArgs)
end)


addon.tests.register('combat event "leave"', function(mock)
	local conditions = { event = 'combat_leave', conditions = {} }
	local eventArgs = {'PLAYER_REGEN_ENABLED'}
	addon.tests.testEvent(mock, conditions, eventArgs)
end)


local function getCombatEventArgs(event, extraArgs)
	local sourceFlags = bit.bor(
		_G.COMBATLOG_OBJECT_AFFILIATION_OUTSIDER,
		_G.COMBATLOG_OBJECT_REACTION_HOSTILE,
		_G.COMBATLOG_OBJECT_CONTROL_PLAYER,
		_G.COMBATLOG_OBJECT_TYPE_PLAYER
	)
	local destFlags = bit.bor(
		_G.COMBATLOG_OBJECT_AFFILIATION_MINE,
		_G.COMBATLOG_OBJECT_REACTION_FRIENDLY,
		_G.COMBATLOG_OBJECT_CONTROL_PLAYER,
		_G.COMBATLOG_OBJECT_TYPE_PET
	)
	local eventArgs = {
		'COMBAT_LOG_EVENT_UNFILTERED',
		123,
		event,
		false,
		'sourceguid',
		'Source',
		sourceFlags,
		0,
		'destguid',
		'Destination',
		destFlags,
		0,
	}
	for _, arg in ipairs(extraArgs) do
		table.insert(eventArgs, arg)
	end
	return eventArgs
end


addon.tests.register('combat event common fields', function(mock)
	local groups = {
		event = 'combat_death',
		conditions = {
			{ field = 'srcName', comparison = 'eq',
				value = 'Source' },
			{ field = 'srcType', comparison = 'eq',
				value = _G.COMBATLOG_OBJECT_TYPE_PLAYER },
			{ field = 'srcReaction', comparison = 'eq',
				value = _G.COMBATLOG_OBJECT_REACTION_HOSTILE },
			{ field = 'srcAffiliation', comparison = 'eq',
				value = _G.COMBATLOG_OBJECT_AFFILIATION_OUTSIDER },
			{ field = 'destName', comparison = 'eq',
				value = 'Destination' },
			{ field = 'destType', comparison = 'eq',
				value = _G.COMBATLOG_OBJECT_TYPE_PET },
			{ field = 'destReaction', comparison = 'eq',
				value = _G.COMBATLOG_OBJECT_REACTION_FRIENDLY },
			{ field = 'destAffiliation', comparison = 'eq',
				value = _G.COMBATLOG_OBJECT_AFFILIATION_MINE },
		},
	}
	local extraArgs = {}
	addon.tests.testEvent(mock, groups, getCombatEventArgs('PARTY_KILL', extraArgs))
end)


addon.tests.register('combat event "aa_hit"', function(mock)
	local groups = {
		event = 'combat_aa_hit',
		conditions = {
			{ field = 'amount', comparison = 'gt', value = 1336 },
			{ field = 'isCritical', comparison = 'eq', value = true },
		},
	}
	-- amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand
	local extraArgs = {1337, 0, 0, 0, 0, 0, 1, nil, nil, nil}
	addon.tests.testEvent(mock, groups, getCombatEventArgs('SWING_DAMAGE', extraArgs))
end)


addon.tests.register('combat event "aa_miss"', function(mock)
	local groups = {
		event = 'combat_aa_miss',
		conditions = {},
	}
	local extraArgs = {}
	addon.tests.testEvent(mock, groups, getCombatEventArgs('SWING_MISSED', extraArgs))
end)


addon.tests.register('combat event "ability_hit"', function(mock)
	local groups = {
		event = 'combat_ability_hit',
		conditions = {
			{ field = 'abilityName', comparison = 'matches', value = 'Pyro*' },
			{ field = 'amount', comparison = 'gt', value = 1336 },
			{ field = 'isCritical', comparison = 'eq', value = true },
		},
	}
	-- spellID, spellName, spellSchool
	-- amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand
	local extraArgs = {
		0, 'Pyroblast', 0,
		1337, 0, 0, 0, 0, 0, 1, nil, nil, nil
	}
	addon.tests.testEvent(mock, groups, getCombatEventArgs('SPELL_DAMAGE', extraArgs))
end)


addon.tests.register('combat event "ability_miss"', function(mock)
	local groups = {
		event = 'combat_ability_miss',
		conditions = {
			{ field = 'abilityName', comparison = 'matches', value = 'Pyro*' },
		},
	}
	-- spellID, spellName, spellSchool
	local extraArgs = {0, 'Pyroblast', 0}
	addon.tests.testEvent(mock, groups, getCombatEventArgs('SPELL_MISSED', extraArgs))
end)


addon.tests.register('combat event "ability_heal"', function(mock)
	local groups = {
		event = 'combat_ability_heal',
		conditions = {
			{ field = 'abilityName', comparison = 'matches', value = 'Pyro*' },
			{ field = 'amount', comparison = 'gt', value = 1336 },
			{ field = 'isCritical', comparison = 'eq', value = true },
		},
	}
	-- spellID, spellName, spellSchool
	-- amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand
	local extraArgs = {
		0, 'Pyroheal', 0,
		1337, 0, 0, 0, 0, 0, 1, nil, nil, nil
	}
	addon.tests.testEvent(mock, groups, getCombatEventArgs('SPELL_HEAL', extraArgs))
end)


addon.tests.register('combat event "ability_start"', function(mock)
	local groups = {
		event = 'combat_ability_start',
		conditions = {
			{ field = 'abilityName', comparison = 'matches', value = 'Pyro*' },
		},
	}
	-- spellID, spellName, spellSchool
	local extraArgs = {0, 'Pyroblast', 0}
	addon.tests.testEvent(mock, groups, getCombatEventArgs('SPELL_CAST_START', extraArgs))
end)


addon.tests.register('combat event "ability_succeed"', function(mock)
	local groups = {
		event = 'combat_ability_succeed',
		conditions = {
			{ field = 'abilityName', comparison = 'matches', value = 'Pyro*' },
		},
	}
	-- spellID, spellName, spellSchool
	local extraArgs = {0, 'Pyroblast', 0}
	addon.tests.testEvent(mock, groups, getCombatEventArgs('SPELL_CAST_SUCCESS', extraArgs))
end)


addon.tests.register('combat event "ability_interrupt"', function(mock)
	local groups = {
		event = 'combat_ability_interrupt',
		conditions = {
			{ field = 'abilityName', comparison = 'matches', value = 'Pyro*' },
		},
	}
	-- spellID, spellName, spellSchool
	local extraArgs = {0, 'Pyroblast', 0}
	addon.tests.testEvent(mock, groups, getCombatEventArgs('SPELL_INTERRUPT', extraArgs))
end)


addon.tests.register('combat event "environment_damage"', function(mock)
	local groups = {
		event = 'combat_environment_damage',
		conditions = {},
	}
	local extraArgs = {}
	addon.tests.testEvent(mock, groups, getCombatEventArgs('ENVIRONMENTAL_DAMAGE', extraArgs))
end)


addon.tests.register('combat event "death"', function(mock)
	local groups = {
		event = 'combat_death',
		conditions = {},
	}
	local extraArgs = {}
	addon.tests.testEvent(mock, groups, getCombatEventArgs('PARTY_KILL', extraArgs))
end)
