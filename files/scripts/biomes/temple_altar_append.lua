dofile_once("mods/iota_multiplayer/files/scripts/lib/sule.lua")(function()
	dofile_once("mods/iota_multiplayer/lib.lua")

	local old_spawn_hp = spawn_hp
	function _G.spawn_hp(x, y)
		old_spawn_hp(x, y)
		for _, pickup in ipairs(EntityGetInRadius(x, y, 16)) do
			local filename = EntityGetFilename(pickup)
			if filename == "data/entities/items/pickup/heart_fullhp_temple.xml" or filename == "data/entities/items/pickup/spell_refresh.xml" then
				EntityAddComponent2(pickup, "LuaComponent", {
					script_item_picked_up = "mods/iota_multiplayer/files/scripts/items/share_pickup.lua",
					execute_every_n_frame = -1
				})
			end
		end
	end

	local old_spawn_all_perks = spawn_all_perks
	function _G.spawn_all_perks(x, y)
		old_spawn_all_perks(x, y)
		for _, perk in ipairs(EntityGetInRadiusWithTag(x + 30, y, 30, "perk")) do
			EntityAddTag(perk, MOD.temple_perk)
		end
		EntityLoad("mods/iota_multiplayer/files/entities/buildings/perk_stats.xml", x + 30, y)
	end
end)
