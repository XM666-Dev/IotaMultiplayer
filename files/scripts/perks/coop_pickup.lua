dofile_once("mods/iota_multiplayer/files/scripts/lib/utilities.lua")

function item_pickup(entity_item, entity_pickupper, item_name)
    EntityKill(entity_item)
    local x, y = EntityGetTransform(entity_item)
    perk_spawn_with_data(x, y, {
        ui_name = "$log_coop_started",
        ui_description = "$log_coop_started",
        perk_icon = "mods/iota_multiplayer/files/items_gfx/perks/coop.png",
    }, "mods/iota_multiplayer/files/scripts/perks/coop_pickup.lua")
    if #get_players_including_disabled() < MAX_PLAYER_NUM then
        load_player(x, y)
    end
end
