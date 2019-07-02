local kAddonName = ...
local L = LibStub('AceLocale-3.0'):NewLocale(kAddonName, 'enUS', true)

-- General headers and labels...
L['When...'] = true
L['Then...'] = true
L.entries_subtitle = 'All entries (when/then pairs) for this character.'
L.conditions_subtitle = 'When these conditions are met...'
L.actions_subtitle = 'Then these actions (slash commands) will run...'
L['no actions configured'] = true
L['Cooldown'] = true
L['Add Entry'] = true
L['Export Entry'] = true
L['Copy the text below. This text can be imported.'] = true
L['Import'] = true
L['Import Entry'] = true
L['Paste the entry text to import below.'] = true
L['Import failed'] = true
L['Could not parse import text'] = true
L['Invalid format or incompatible version'] = true
L['AND'] = true
L['OR'] = true
L['RUN'] = true
L['Watch'] = true
L.watch_message = 'Watch: Event %q detected, with these fields: %s'
L['Add Condition Group'] = true
L['Add Condition to This Group'] = true
L['Event'] = true
L['Field'] = true
L['Comparison'] = true
L['Value'] = true
L['Add Action Group'] = true
L['Add Action to This Group'] = true
L['Ignore global cooldown'] = true
L['Command'] = true
L['Delay (secs)'] = true
L.default_command = '/say Whoa!'
L['Test'] = true
L['Really delete this?'] = true

-- Help text...
L.help_cooldown = 'Enter a plain number like 60 for a value in seconds, or a pattern like "1d2h3m4s" (for "1 day, 2 hours, 3 minutes, 4 seconds"). Ranges like "30-60" or "2h-3h" are supported. If a range is given, the actual cooldown will be chosen at random within the range. If the text turns |cffcc2525red|r, that means the cooldown syntax is invalid.'
L.help_entries = 'The addon works based on "when/then" pairs: |cffffff33when|r conditions are met, |cffffff33then|r actions will run.\n\nThis list shows all of the entries for the current character. Click an entry to edit it, or click the "ADD" button to create a new entry.\n\nClick here to create example entries that will help to demonstrate how the addon works.'
L.help_entry_add = 'Click to add another new entry.'
L.help_entry_import = 'Click to import an entry by pasting text from an entry that was previously exported.'
L.help_entry_export = 'Click to export this entry to copyable text. It can later be imported (by you or anyone else) by clicking Import and pasting the text.'
L.help_entry_cooldown = 'This global cooldown is the minimum time to wait between running *any* actions across the entire addon. This is an anti-spam tool, intended to prevent sending too many messages in too short of a span of time. Individual action groups can be configured to ignore this limit, however.'
L.help_conditions = 'This section uses |cffffff33conditions|r to define when actions should run. Each group of conditions consists of an event (like casting a spell) and optionally also some fields (like the spell name). In order for actions to run, at least one group of conditions must pass.\n\nClick to add example groups of conditions that will help to demonstrate how the addon works.'
L.help_condition_watch = 'If enabled, a message will be added to the chat window every time one of the selected events occurs. This can be helpful for configuring fields.\n\nReminder: The addon does not monitor events while this configuration panel is open, so no messages will appear until this panel is closed.'
L.help_condition_cooldown = 'This cooldown is the minimum time to wait between running actions below. For example, if any action below runs and the cooldown is 60 seconds, then none of the actions below will be allowed to run until 60 seconds have elapsed. Actions in other entries can still run during that time.'
L.help_condition_event = 'An event is something the addon can monitor, such as casting a spell. Most events can be configured with additional fields to narrow down the specifics, such as the spell name or who cast it.'
L.help_condition_event_change = 'The event can only be changed when zero fields are configured.'
L.help_condition_event_delete = 'The event can only be deleted when zero fields are configured and it is not the only event.'
L.help_condition_field = 'The field is a property or attribute of the selected event. For example, if the event is a spell cast, then the field could be the spell name or who cast it. The available fields depend on the selected event.'
L.help_condition_comparison = 'The comparison is a way to check the selected field against a desired value. The available comparisons depend on the selected field. For example, only text-like fields support the Matches comparison, and only number-like fields support the Less Than comparison.'
L.help_condition_value = 'The value is something against which to compare the field. For example, if the field is a spell name, then the value is the name to check against. Some fields allow typing text (case-sensitive), while others only allow selecting a value from a list.'
L.help_condition_value_wildcard = 'Since the Matches or Does Not Match comparison is selected, wildcards (*) can be used in the value. For example, "*stone" would match "Hearthstone" or "Healthstone".'
L.help_condition_and = 'Click to add another condition line in this group. All conditions in a group must pass in order for the group itself to pass.'
L.help_condition_no_fields = 'The selected event has no fields, so conditions cannot be added.'
L.help_condition_or = 'Click to add another group of conditions. At least one group of conditions must pass in order for actions to run.'
L.help_actions = 'This section uses |cffffff33actions|r to define what to do when the conditions above have been met. Each action consists of a single slash command (like "/say Whoa!") with an optional delay.\n\nTo produce a variety of effects, multiple groups of actions can be created with varying cooldowns. All groups without a cooldown will always run, but only one group with a cooldown will run. The chosen group is the one that ran least recently.\n\nFor example, if one group has a 1 hour cooldown and another has a 60 second cooldown, the 1 hour group will be chosen unless it is on cooldown.\n\nClick to add example groups of actions that will help to demonstrate how the addon works.'
L.help_action_test = 'Click to test these actions by explicitly running them right now. This respects cooldowns, so if an action group is currently cooling down, it will not run.'
L.help_action_test_ran = 'The following action groups ran'
L.help_action_cooldown = 'This cooldown is the minimum time to wait between runs of this particular action group. For example, if this action group runs and the cooldown is 60 seconds, then this action group will not be allowed to run again until 60 seconds have elapsed. Other action groups can still run during that time.'
L.help_action_cooldown_ignore_global = 'If enabled, this action group will be eligible to run even when it would otherwise be prevented by the global cooldown (configured above). This is primarily intended for use with actions that will not send chat messages, such as "/script AcceptGroup()". Use responsibly!'
L.help_action_command = 'The command is the slash command to run. For example, "/say Hello!" or "/wave".\n\nTo include fields in the command, use curly brace {placeholders} with the field name, like this:\n/say {ability name}!!\nIf the ability name is "Fireball", this will be equivalent to this:\n/say Fireball!!\n\nTo speak in a language other than the default, prefix the command with that language in [brackets], like this:\n[Dwarvish] /say Hoy there!'
L.help_action_delay = 'The delay is how long to wait, in seconds, before actually running the command. For example, consider three actions in a group:\n(0s) /say You...\n(1s) /say ...shall not...\n(2s) /say ...PASS!'
L.help_action_and = 'Click to add another action line in this group. All actions in a group will run when the group runs.'
L.help_action_or = 'Click to add another group of actions. All groups of actions will try to run (cooldown permitting) when the conditions above are met.'

-- Condition comparison names...
L['Is'] = true
L['Is Not'] = true
L['Matches'] = true
L['Does Not Match'] = true
L['Less Than'] = true
L['Greater Than'] = true

-- Condition booleans...
L['True'] = true
L['False'] = true

-- Chat condition fields...
L['Numbered channel'] = true
L['Numbered channel name'] = true
L['Message'] = true
L['Author'] = true

-- Chat event names...
L['Chat message received'] = true

-- Combat condition fields...
L['Source name'] = true
L['Source type'] = true
L['Source reaction'] = true
L['Source affiliation'] = true
L['Destination name'] = true
L['Destination type'] = true
L['Destination reaction'] = true
L['Destination affiliation'] = true
L['Ability name'] = true
L['Amount'] = true
L['Is critical'] = true

-- Combat event names...
L['I enter combat'] = true
L['I leave combat'] = true
L['Auto-attack hits'] = true
L['Auto-attack misses'] = true
L['Ability hits'] = true
L['Ability misses'] = true
L['Ability heals'] = true
L['Ability cast starts'] = true
L['Ability cast succeeds'] = true
L['Ability cast interrupted'] = true
L['Environment deals damage'] = true
L['Something dies'] = true

-- Combat condition values for types...
L['Object'] = true
L['Guardian'] = true
L['Pet'] = true
L['NPC'] = true
L['Player'] = true

-- Combat condition values for reactions...
L['Hostile'] = true
L['Neutral'] = true
L['Friendly'] = true

-- Combat condition values for affiliations...
L['Outsider'] = true
L['Raid'] = true
L['Party'] = true
L['Mine'] = true
