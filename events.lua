local kAddonName, addon = ...
addon.events = {}

local eventsFrame = _G.CreateFrame('Frame', kAddonName .. '_EventsFrame')
eventsFrame:Hide()
local handlers = {}

local function onEvent(_--[[self]], ...)
	addon.events.trigger(...)
end

eventsFrame:SetScript('OnEvent', onEvent)


function addon.events.trigger(event, ...)
	local handler = handlers[event]
	assert(handler, event)
	handler(event, ...)
end


function addon.events.on(event, callback)
	assert(not handlers[event], event)
	eventsFrame:RegisterEvent(event)
	handlers[event] = callback
end


function addon.events.off(event)
	if handlers[event] then
		eventsFrame:UnregisterEvent(event)
		handlers[event] = nil
	end
end
