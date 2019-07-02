local kAddonName, addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(kAddonName)

local kCategory = 'chat'

local kLists = {
	{prefix = '', list = _G.CHAT_CONFIG_CHAT_LEFT},
	{prefix = _G.CREATURE, list = _G.CHAT_CONFIG_CHAT_CREATURE_LEFT},
	{prefix = '', list = _G.CHAT_CONFIG_OTHER_COMBAT},
	{prefix = '', list = _G.CHAT_CONFIG_OTHER_PVP},
	{prefix = '', list = _G.CHAT_CONFIG_OTHER_SYSTEM},
}
local kChannels = {}
local kChannelLookup = {}
for _, entry in ipairs(kLists) do
	for _, item in ipairs(entry.list) do
		local groupName = item.type
		local name = item.text or _G[groupName]
		if #entry.prefix > 0 then
			name = entry.prefix .. ' ' .. name
		end
		local group = _G.ChatTypeGroup[groupName]
		if not group then
			-- The "BG_SYSTEM_[side]" groups don't have a definition in ChatTypeGroup.
			-- The "SYSTEM" part has to be removed.
			local match = groupName:match('^BG_SYSTEM_(.+)$')
			if match then
				groupName = 'BG_' .. match
				group = _G.ChatTypeGroup[groupName]
			end
		end
		assert(group, groupName)
		kChannels[groupName] = name
		for _, chatEvent in ipairs(group) do
			kChannelLookup[chatEvent] = groupName
		end
	end
end
-- Rename this one for clarity.
kChannels.CHANNEL = L['Numbered channel']

local kFields = {
	channel = {
		name = _G.CHANNEL,
		valueType = 'identifier',
		values = kChannels,
	},
	channelName = {
		name = L['Numbered channel name'],
		valueType = 'text',
	},
	message = {
		name = L['Message'],
		valueType = 'text',
	},
	author = {
		name = L['Author'],
		valueType = 'text',
	},
	language = {
		name = _G.LANGUAGE,
		valueType = 'text',
	},
}

local kEvents = {
	incoming_message = {
		name = L['Chat message received'],
		fields = kFields,
	}
}


local function onChatEvent(event, message, author, language, ...)
	if author == _G.UnitName('player') then
		return
	end
	local channelName = nil
	if event == 'CHAT_MSG_CHANNEL' then
		-- Custom channel name is event arg9.
		channelName = select(5, ...)
	end
	local fields = {
		channel = kChannelLookup[event],
		channelName = channelName,
		message = message,
		author = author,
		language = language,
	}
	addon.conditions.dispatchEvent(kCategory, 'incoming_message', fields)
end


local function watch(event)
	assert(event == 'incoming_message')
	for chatEvent in pairs(kChannelLookup) do
		addon.events.on(chatEvent, onChatEvent)
	end
end


local function unwatch(event)
	assert(event == 'incoming_message')
	for chatEvent in pairs(kChannelLookup) do
		addon.events.off(chatEvent)
	end
end


addon.conditions.registerCategory(kCategory, _G.CHAT, kEvents, watch, unwatch)
