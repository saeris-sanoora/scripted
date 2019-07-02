--[[ Immutable
by Saeris (saeris@pm.me)
A library for handling immutable Lua values within a World of Warcraft AddOn environment.
Hosted on GitHub: https://github.com/saeris-sanoora/immutable
See the README.md file for documentation.
--]]

local MAJOR, MINOR = 'Immutable-1.0', 0
assert(LibStub, MAJOR .. ' requires LibStub')
local Immutable = LibStub:NewLibrary(MAJOR, MINOR)
if not Immutable then return end


local function assertf(expression, format, ...)
	if not expression then
		error(MAJOR .. ': ' .. format:format(_G.tostringall(...)), 2)
	end
end


local function shallowCopy(tbl)
	local copy = {}
	for key, value in pairs(tbl) do
		copy[key] = value
	end
	return copy
end


local function normalizeArrayIndex(length, index)
	local normalized = index
	if not index then
		normalized = length + 1
	elseif index < 0 then
		normalized = length + index + 1
	end
	assertf(normalized > 0 and normalized <= (length + 1), 'index is out of bounds: %q', index)
	return normalized
end


local function transform(original, change, key)
	local changeType = type(change)
	if changeType == 'table' then
		assertf(type(original) == 'table', 'key %q is not a table: %q', key or 'root', original)
		local copy = shallowCopy(original)
		for nestedKey, nestedChange in pairs(change) do
			copy[nestedKey] = transform(copy[nestedKey], nestedChange, nestedKey)
		end
		return copy
	end
	if changeType == 'function' then
		return change(original, key)
	end
	if key then
		assertf(original ~= nil, 'table is missing key: %q', key)
	end
	return change
end


-- Given a value and a change, returns a copy of the value with the change applied.
function Immutable.transform(original, change)
	return transform(original, change)
end


-- Returns a change function which will set a value directly, without giving it special treatment.
function Immutable.assign(value)
	local function change()
		return value
	end
	return change
end


-- Returns a change function which will add a key to a table, with the given value.
function Immutable.addKey(value)
	local function change(original, key)
		assertf(original == nil, 'table already has key: %q', key)
		return value
	end
	return change
end


-- Returns a change function which will remove a key from a table.
function Immutable.removeKey()
	local function change(original, key)
		assertf(original ~= nil, 'table does not have key: %q', key)
		return nil
	end
	return change
end


-- Returns a change function which will insert a value at an index in an array table.
function Immutable.insert(value, index)
	local function change(original)
		assertf(type(original) == 'table', 'cannot insert into non-table: %q', original)
		local normalizedIndex = normalizeArrayIndex(#original, index)
		local copy = shallowCopy(original)
		table.insert(copy, normalizedIndex, value)
		return copy
	end
	return change
end


-- Returns a change function which will remove an index from an array table.
function Immutable.remove(index)
	local function change(original)
		assertf(type(original) == 'table', 'cannot remove from non-table: %q', original)
		local normalizedIndex = normalizeArrayIndex(#original, index)
		local copy = shallowCopy(original)
		table.remove(copy, normalizedIndex)
		return copy
	end
	return change
end
