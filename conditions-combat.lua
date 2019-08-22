local kAddonName, addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(kAddonName)

local kCategory = 'combat'

local kTypes = {
	[_G.COMBATLOG_OBJECT_TYPE_PLAYER] = L['Player'],
	[_G.COMBATLOG_OBJECT_TYPE_NPC] = L['NPC'],
	[_G.COMBATLOG_OBJECT_TYPE_PET] = L['Pet'],
	[_G.COMBATLOG_OBJECT_TYPE_GUARDIAN] = L['Guardian'],
	[_G.COMBATLOG_OBJECT_TYPE_OBJECT] = L['Object'],
}

local kReactions = {
	[_G.COMBATLOG_OBJECT_REACTION_FRIENDLY] = L['Friendly'],
	[_G.COMBATLOG_OBJECT_REACTION_NEUTRAL] = L['Neutral'],
	[_G.COMBATLOG_OBJECT_REACTION_HOSTILE] = L['Hostile'],
}

local kAffiliations = {
	[_G.COMBATLOG_OBJECT_AFFILIATION_MINE] = L['Mine'],
	[_G.COMBATLOG_OBJECT_AFFILIATION_PARTY] = L['Party'],
	[_G.COMBATLOG_OBJECT_AFFILIATION_RAID] = L['Raid'],
	[_G.COMBATLOG_OBJECT_AFFILIATION_OUTSIDER] = L['Outsider'],
}

local kCommonLogFields = {
	srcName = {
		name = L['Source name'],
		valueType = 'text',
	},
	srcType = {
		name = L['Source type'],
		valueType = 'identifier',
		values = kTypes,
	},
	srcReaction = {
		name = L['Source reaction'],
		valueType = 'identifier',
		values = kReactions,
	},
	srcAffiliation = {
		name = L['Source affiliation'],
		valueType = 'identifier',
		values = kAffiliations,
	},
	destName = {
		name = L['Destination name'],
		valueType = 'text',
	},
	destType = {
		name = L['Destination type'],
		valueType = 'identifier',
		values = kTypes,
	},
	destReaction = {
		name = L['Destination reaction'],
		valueType = 'identifier',
		values = kReactions,
	},
	destAffiliation = {
		name = L['Destination affiliation'],
		valueType = 'identifier',
		values = kAffiliations,
	},
}

local kAbilityLogFields = {
	abilityName = {
		name = L['Ability name'],
		valueType = 'text',
	},
}

local kAmountLogFields = {
	amount = {
		name = L['Amount'],
		valueType = 'number',
	},
}

local kCritLogFields = {
	isCritical = {
		name = L['Is critical'],
		valueType = 'boolean',
	},
}

local function mergeFields(...)
	return addon.utils.mergeTables(kCommonLogFields, ...)
end

local kEvents = {
	enter = {
		name = L['I enter combat'],
		event = 'PLAYER_REGEN_DISABLED',
		fields = {},
	},
	leave = {
		name = L['I leave combat'],
		event = 'PLAYER_REGEN_ENABLED',
		fields = {},
	},
	aa_hit = {
		name = L['Auto-attack hits'],
		combatEvent = 'SWING_DAMAGE',
		fields = mergeFields(kAmountLogFields, kCritLogFields),
	},
	aa_miss = {
		name = L['Auto-attack misses'],
		combatEvent = 'SWING_MISSED',
		fields = mergeFields(),
	},
	ability_hit = {
		name = L['Ability hits'],
		combatEvent = 'SPELL_DAMAGE',
		fields = mergeFields(kAbilityLogFields, kAmountLogFields, kCritLogFields),
	},
	ability_miss = {
		name = L['Ability misses'],
		combatEvent = 'SPELL_MISSED',
		fields = mergeFields(kAbilityLogFields),
	},
	ability_heal = {
		name = L['Ability heals'],
		combatEvent = 'SPELL_HEAL',
		fields = mergeFields(kAbilityLogFields, kAmountLogFields, kCritLogFields),
	},
	ability_start = {
		name = L['Ability cast starts'],
		combatEvent = 'SPELL_CAST_START',
		fields = mergeFields(kAbilityLogFields),
	},
	ability_succeed = {
		name = L['Ability cast succeeds'],
		combatEvent = 'SPELL_CAST_SUCCESS',
		fields = mergeFields(kAbilityLogFields),
	},
	ability_interrupt = {
		name = L['Ability cast interrupted'],
		combatEvent = 'SPELL_INTERRUPT',
		fields = mergeFields(kAbilityLogFields),
	},
	environment_damage = {
		name = L['Environment deals damage'],
		combatEvent = 'ENVIRONMENTAL_DAMAGE',
		fields = mergeFields(kAmountLogFields, kCritLogFields),
	},
	death = {
		name = L['Something dies'],
		combatEvent = 'PARTY_KILL',
		fields = mergeFields(),
	},
}

local kCombatEventToEvent = {}
for event, eventInfo in pairs(kEvents) do
	if eventInfo.combatEvent then
		kCombatEventToEvent[eventInfo.combatEvent] = event
	end
end

local watchedCombatEventsCount = 0
local watchedCombatEvents = {}


local function addPrefixFields(fields, prefix, ...)
	if prefix == 'SPELL' then
		fields.abilityName = select(10, ...)
	end
end

local function addSuffixFields(fields, prefix, suffix, ...)
	local suffixArgsPos = 9
	if prefix == 'SPELL' then
		suffixArgsPos = suffixArgsPos + 3
	elseif prefix == 'ENVIRONMENTAL' then
		suffixArgsPos = suffixArgsPos + 1
	end
	if suffix == 'DAMAGE' or suffix == 'HEAL' then
		fields.amount = select(suffixArgsPos, ...)
	end
	if suffix == 'DAMAGE' then
		fields.isCritical = not not select(suffixArgsPos + 6, ...)
	elseif suffix == 'HEAL' then
		fields.isCritical = not not select(suffixArgsPos + 3, ...)
	end
end

local function onCombatEvent(_--[[event]], _--[[timestamp]], combatEvent, _--[[hideCaster]], ...)
	--[[ Args:
	timestamp, event, hideCaster,
	1. sourceGUID, 2. sourceName, 3. sourceFlags, 4. sourceRaidFlags,
	5. destGUID, 6. destName, 7. destFlags, 8. destRaidFlags
	--]]
	if not watchedCombatEvents[combatEvent] then
		return
	end
	local event = kCombatEventToEvent[combatEvent]
	local srcName, srcFlags = select(2, ...)
	local destName, destFlags = select(6, ...)
	local fields = {
		srcName = srcName,
		srcType = bit.band(srcFlags, _G.COMBATLOG_OBJECT_TYPE_MASK),
		srcReaction = bit.band(srcFlags, _G.COMBATLOG_OBJECT_REACTION_MASK),
		srcAffiliation = bit.band(srcFlags, _G.COMBATLOG_OBJECT_AFFILIATION_MASK),
		destName = destName,
		destType = bit.band(destFlags, _G.COMBATLOG_OBJECT_TYPE_MASK),
		destReaction = bit.band(destFlags, _G.COMBATLOG_OBJECT_REACTION_MASK),
		destAffiliation = bit.band(destFlags, _G.COMBATLOG_OBJECT_AFFILIATION_MASK),
	}
	local prefix = combatEvent:match('^(.-)_')
	local suffix = combatEvent:match('.+_(.-)$')
	addPrefixFields(fields, prefix, ...)
	addSuffixFields(fields, prefix, suffix, ...)
	addon.conditions.dispatchEvent(kCategory, event, fields)
end


local function watch(event)
	local eventInfo = kEvents[event]
	assert(eventInfo, event)
	if eventInfo.event then
		local function onEvent()
			addon.conditions.dispatchEvent(kCategory, event, {})
		end
		addon.events.on(eventInfo.event, onEvent)
	elseif eventInfo.combatEvent then
		watchedCombatEventsCount = watchedCombatEventsCount + 1
		watchedCombatEvents[eventInfo.combatEvent] = true
		if watchedCombatEventsCount == 1 then
			addon.events.on('COMBAT_LOG_EVENT_UNFILTERED', onCombatEvent)
		end
	end
end


local function unwatch(event)
	local eventInfo = kEvents[event]
	assert(eventInfo, event)
	if eventInfo.event then
		addon.events.off(eventInfo.event)
	elseif eventInfo.combatEvent then
		watchedCombatEventsCount = watchedCombatEventsCount - 1
		watchedCombatEvents[eventInfo.combatEvent] = nil
		if watchedCombatEventsCount == 0 then
			addon.events.off('COMBAT_LOG_EVENT_UNFILTERED')
		end
	end
end


addon.conditions.registerCategory(kCategory, _G.COMBAT, kEvents, watch, unwatch)
