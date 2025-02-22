dofile_once("mods/iota_multiplayer/files/scripts/lib/utilities.lua")

function item_pickup(player)
    local player_data = Player(player)
    player_data.controls_.mButtonFrameInventory = get_frame_num_next()
end
