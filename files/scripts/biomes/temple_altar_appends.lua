dofile_once("mods/iota_multiplayer/files/scripts/lib/sule.lua")(function()
	dofile_once("mods/iota_multiplayer/files/scripts/lib/utilities.lua")

	local raw_spawn_all_perks = spawn_all_perks
	function _G.spawn_all_perks(x, y)
		raw_spawn_all_perks(x, y)
		EntityLoad("mods/iota_multiplayer/files/entities/buildings/perk_stats.xml", x + 30, y)
	end
end)
