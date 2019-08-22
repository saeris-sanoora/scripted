local _--[[kAddonName]], addon = ...


addon.tests.register('chat event "incoming_message" normal channel', function(mock)
	local conditionGroups = {
		event = 'chat_incoming_message',
		conditions = {
			{ field = 'channel', comparison = 'eq', value = 'GUILD' },
			{ field = 'message', comparison = 'matches', value = '*keyword*' },
			{ field = 'author', comparison = 'matches', value = '*idely' },
			{ field = 'language', comparison = 'matches', value = 'Titan' },
		},
	}
	-- event, message, author, language, arg4, arg5, arg6, arg7, arg8, channelName
	local eventArgs = {
		'CHAT_MSG_GUILD', 'a keyword or something', 'Sidely', 'Titan',
		nil, nil, nil, nil, nil, nil
	}
	addon.tests.testEvent(mock, conditionGroups, eventArgs)
end)


addon.tests.register('chat event "incoming_message" numbered channel', function(mock)
	local conditionGroups = {
		event = 'chat_incoming_message',
		conditions = {
			{ field = 'channel', comparison = 'eq', value = 'CHANNEL' },
			{ field = 'channelName', comparison = 'matches', value = '*beast' },
		},
	}
	-- event, message, author, language, arg4, arg5, arg6, arg7, arg8, channelName
	local eventArgs = {
		'CHAT_MSG_CHANNEL', 'a keyword or something', 'Sidely', 'Titan',
		nil, nil, nil, nil, nil, 'sexybeast'
	}
	addon.tests.testEvent(mock, conditionGroups, eventArgs)
end)
