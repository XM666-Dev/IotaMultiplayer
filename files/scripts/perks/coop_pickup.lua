dofile_once("mods/iota_multiplayer/files/scripts/lib/utilities.lua")

function item_pickup(item)
    if #get_players_including_disabled() < MAX_PLAYER_NUM then
        load_player(EntityGetTransform(item))
    end
end
