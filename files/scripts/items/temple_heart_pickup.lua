dofile_once("mods/iota_multiplayer/lib.lua")

function item_pickup(entity_item, entity_pickupper, item_name)
    local x, y = EntityGetTransform(entity_pickupper)
    local respawn = EntityGetInRadiusWithTag(x, y, 200, "coop_respawn")[1]
    local to_x, to_y = EntityGetTransform(respawn)
    for i, player in ipairs(get_players_including_disabled()) do
        local player_data = PlayerData(player)
        if player_data.dead then
            set_dead(player, false)
            local from_x, from_y = EntityGetTransform(player)
            teleport(player, from_x, from_y, to_x, to_y)
        end
    end
end
