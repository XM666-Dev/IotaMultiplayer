dofile_once("mods/iota_multiplayer/lib.lua")

function item_pickup(entity_item, entity_pickupper, item_name)
    EntityKill(entity_item)
    local x, y = EntityGetTransform(entity_item)
    perk_spawn_with_data(x, y, {
        ui_name = "$log_coop_started",
        ui_description = "$log_coop_started",
        perk_icon = "mods/iota_multiplayer/files/items_gfx/perks/new_player.png"
    }, "mods/iota_multiplayer/files/scripts/perks/new_player_pickup.lua")
    if mod.max_index < 8 then
        load_player(x, y)
    end
end
