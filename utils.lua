local kAddonName, addon = ...
addon.utils = {}

local kCooldownUnitMultipliers = {
	s = 1,
	m = 60,
	h = 60 * 60,
	d = 60 * 60 * 24
}

local matchPatternCache = {}


function addon.utils.now()
	return _G.GetServerTime()
end


local function parseCooldownToSeconds(cooldown)
	local asNumber = tonumber(cooldown)
	if asNumber then
		return asNumber
	end
	local seconds = 0
	local function aggregate(number, unit)
		local multiplier = kCooldownUnitMultipliers[unit]
		number = tonumber(number)
		seconds = seconds + (number * multiplier)
		return ''
	end
	local remainder = cooldown:gsub('([%d%.]+)([dhms])', aggregate)
	if #remainder > 0 then
		addon.utils.error('Invalid cooldown: %q', cooldown)
	end
	return seconds
end


function addon.utils.parseCooldown(text)
	local despaced = text:gsub('%s', '')
	local min, max = despaced:match('^(.-)%-(.-)$')
	if not min or not max then
		min = despaced
		max = min
	end
	local minSecs = parseCooldownToSeconds(min)
	local maxSecs = parseCooldownToSeconds(max)
	if minSecs > maxSecs then
		addon.utils.error('Invalid cooldown range: %q to %q', minSecs, maxSecs)
	end
	return minSecs, maxSecs
end


function addon.utils.getCooldownAllowedTime(cooldown)
	local minSecs, maxSecs = addon.utils.parseCooldown(cooldown)
	local seconds = math.random(minSecs, maxSecs)
	return addon.utils.now() + seconds
end


function addon.utils.escapePattern(text)
	return text:gsub('([%.%^%$%(%)%[%]%+%*%-%%])', '%%%1')
end


function addon.utils.matches(actual, wanted)
	local pattern = matchPatternCache[wanted]
	if not pattern then
		local escaped = addon.utils.escapePattern(wanted):gsub('%%%*', '.+')
		pattern = '^' .. escaped .. '$'
		matchPatternCache[wanted] = pattern
	end
	return not not actual:find(pattern)
end


local function formatMessage(message, ...)
	local formattedMessage = message:format(...)
	return ('%s: %s'):format(kAddonName, formattedMessage)
end


function addon.utils.print(message, ...)
	print(formatMessage(message, ...))
end


function addon.utils.error(message, ...)
	error(formatMessage(message, ...))
end


function addon.utils.softerror(message, ...)
	_G.geterrorhandler()(formatMessage(message, ...))
end


function addon.utils.all(tbl, func, ...)
	for _, value in ipairs(tbl) do
		if not func(value, ...) then
			return false
		end
	end
	return true
end


function addon.utils.any(tbl, func, ...)
	for _, value in ipairs(tbl) do
		if func(value, ...) then
			return true
		end
	end
	return false
end


function addon.utils.mergeTables(...)
	local merged = {}
	for i = 1, select('#', ...) do
		local tbl = select(i, ...)
		for key, value in pairs(tbl) do
			merged[key] = value
		end
	end
	return merged
end


function addon.utils.tabletostring(tbl)
	local pieces = {}
	for key, value in pairs(tbl) do
		local keyText = key
		if type(key) == 'string' then
			keyText = ('%q'):format(key)
		end
		local valueText = value
		if type(value) == 'table' then
			valueText = addon.utils.tabletostring(value)
		elseif type(value) == 'string' then
			valueText = ('%q'):format(value)
		end
		table.insert(pieces, ('[%s]=%s'):format(tostring(keyText), tostring(valueText)))
	end
	return '{' .. table.concat(pieces, ',') .. '}'
end


-- Yes, this is almost verbatim Redux. http://redux.js.org/
function addon.utils.createStore(reducer)
	local state = reducer()
	local listeners = {}

	local function getState()
		return state
	end

	local function subscribe(newListener)
		table.insert(listeners, newListener)
		local subscribed = true
		local function unsubscribe()
			if not subscribed then
				return
			end
			subscribed = false
			for i, listener in ipairs(listeners) do
				if listener == newListener then
					table.remove(listeners, i)
					return
				end
			end
		end
		return unsubscribe
	end

	local function dispatch(action)
		local isDebug = state.debug
		if isDebug then
			_G.debugprofilestart()
		end
		state = reducer(state, action)
		for _, listener in ipairs(listeners) do
			listener()
		end
		if isDebug then
			local durationMs = _G.debugprofilestop()
			addon.utils.print('Duration for action %q: %s ms', action.name, durationMs)
		end
	end

	return { getState = getState, subscribe = subscribe, dispatch = dispatch }
end
