dofile_once("mods/iota_multiplayer/files/scripts/lib/environment.lua")
dofile_once("mods/iota_multiplayer/files/scripts/lib/utilities.lua")

local raw_biome_map_load_keep_player = BiomeMapLoad_KeepPlayer
function BiomeMapLoad_KeepPlayer(...)
    local players = table.filter(get_players_including_disabled(), function(player)
        local player_data = Player(player)
        return player_data.index > 1
    end)
    for i, player in ipairs(players) do
        EntityAddChild(GameGetWorldStateEntity(), player)
    end
    raw_biome_map_load_keep_player(...)
    for i, player in ipairs(players) do
        EntityRemoveFromParent(player)
    end
end
