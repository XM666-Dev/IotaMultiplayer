dofile_once("mods/iota_multiplayer/lib.lua")

function item_pickup(entity_item, entity_pickupper, item_name)
    EntityKill(entity_item)
    local x, y = EntityGetTransform(entity_item)
    perk_spawn_with_data(x, y, {
        ui_name = "$action_autoaim",
        ui_description = "$actiondesc_autoaim",
        perk_icon = "mods/iota_multiplayer/files/items_gfx/perks/autoaim.png",
    }, "mods/iota_multiplayer/files/scripts/perks/autoaim_pickup.lua")

    local entity_pickupper_data = Player(entity_pickupper)
    if entity_pickupper_data.autoaim ~= nil then
        local enabled = ComponentGetIsEnabled(entity_pickupper_data.autoaim._id)
        set_component_enabled(entity_pickupper_data.autoaim._id, not enabled)
        if enabled then
            GamePrint(table.concat { GameTextGet("$action_autoaim"), " ", GameTextGet("$option_off") })
        else
            GamePrint(table.concat { GameTextGet("$action_autoaim"), " ", GameTextGet("$option_on") })
        end
    end
end
