local kAddonName, addon = ...


local function onEventAddonLoaded(_--[[event]], name)
	if name == kAddonName then
		addon.events.off('ADDON_LOADED')
		addon.config.init()
	end
end


addon.events.on('ADDON_LOADED', onEventAddonLoaded)
