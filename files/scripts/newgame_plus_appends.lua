dofile_once("mods/iota_multiplayer/files/scripts/lib/environment.lua")
dofile_once("mods/iota_multiplayer/files/scripts/lib/utilities.lua")

local raw_biome_map_load_keep_player = BiomeMapLoad_KeepPlayer
function BiomeMapLoad_KeepPlayer(...)
    local first_player = get_player_at_index_including_disabled(1)
    local players = table.filter(get_players_including_disabled(), function(player)
        local player_object = Player(player)
        return player_object.index ~= 1 and first_player ~= nil and not validate(EntityGetParent(player))
    end)
    for i, player in ipairs(players) do
        EntityAddChild(first_player, player)
    end
    raw_biome_map_load_keep_player(...)
    for i, player in ipairs(players) do
        EntityRemoveFromParent(player)
    end
end
