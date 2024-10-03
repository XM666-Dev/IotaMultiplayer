dofile_once("mods/iota_multiplayer/files/scripts/lib/utilities.lua")

function item_pickup(entity_item, entity_pickupper, item_name)
    local item = EntityGetFirstComponent(entity_item, "ItemComponent")
    if item == nil then return end
    local x, y = ComponentGetValue2(item, "spawn_pos")
    local respawn = EntityGetInRadiusWithTag(x, y, 16, "coop_respawn")[1]
    local to_x, to_y = EntityGetTransform(respawn)
    for i, player in ipairs(get_players_including_disabled()) do
        local player_data = Player(player)
        if player_data.dead then
            set_dead(player, false)
            local from_x, from_y = EntityGetTransform(player)
            teleport(player, from_x, from_y, to_x, to_y)
        end
    end
end
