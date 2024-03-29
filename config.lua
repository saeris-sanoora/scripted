local kAddonName, addon = ...
addon.config = {}
addon.config.kVersion = 1

local kDefaults = {
	version = addon.config.kVersion,
	globalCooldown = '3',
	globalAllowedTime = 0,
	entries = {},
}

local savedData
local optionsPanel


local function onStoreChange()
	local state = addon.store.getState()
	savedData.globalCooldown = state.globalCooldown
	savedData.globalAllowedTime = state.globalAllowedTime
	savedData.entries = state.entries
	addon.config.updateGUI(optionsPanel)
	addon.conditions.onStoreChange()
end


local function createGUI()
	local panel = _G.CreateFrame('Frame', kAddonName .. '_Config', _G.UIParent)
	panel:Hide()
	panel.name = kAddonName
	local function onShow()
		-- Defer creation of the full GUI until it's actually needed.
		if not panel.entries then
			addon.config.createGUISections(panel)
		end
		addon.store.dispatch({ name = 'startEditing' })
	end
	local function onHide()
		addon.store.dispatch({ name = 'stopEditing' })
	end
	panel:SetScript('OnShow', onShow)
	panel:SetScript('OnHide', onHide)
	return panel
end


local function loadSaved()
	local savedDataName = kAddonName .. '_SavedData'
	savedData = _G[savedDataName]
	if not savedData or savedData.version ~= kDefaults.version then
		savedData = kDefaults
		_G[savedDataName] = savedData
	end
	addon.store.dispatch({ name = 'loadConfig', config = savedData })
end


local function handleSlashCommand(message)
	if message == 'test' then
		addon.tests.run()
	elseif message == 'debug' then
		local state = addon.store.getState()
		if state.debug then
			addon.utils.print('Disabling debug mode.')
		else
			addon.utils.print('Enabling debug mode.')
		end
		addon.store.dispatch({ name = 'toggleDebug' })
	else
		-- Due to a Blizzard bug, this has to be run twice to actually open.
		_G.InterfaceOptionsFrame_OpenToCategory(optionsPanel)
		_G.InterfaceOptionsFrame_OpenToCategory(optionsPanel)
	end
end


function addon.config.init()
	optionsPanel = createGUI()
	_G.InterfaceOptions_AddCategory(optionsPanel)
	_G['SLASH_' .. kAddonName .. '1'] = '/' .. kAddonName:lower()
	_G.SlashCmdList[kAddonName] = handleSlashCommand
	addon.store.subscribe(onStoreChange)
	loadSaved()
end
