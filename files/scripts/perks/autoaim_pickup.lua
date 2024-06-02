dofile_once("mods/iota_multiplayer/lib.lua")

function item_pickup(entity_item, entity_pickupper)
    EntityKill(entity_item)
    local x, y = EntityGetTransform(entity_item)
    perk_spawn_with_data(x, y, {
        ui_name = "$action_autoaim",
        ui_description = "$actiondesc_autoaim",
        perk_icon = "data/ui_gfx/gun_actions/autoaim.png"
    }, "mods/iota_multiplayer/files/scripts/perks/autoaim_pickup.lua")
    local lua = table.filter(EntityGetComponentIncludingDisabled(entity_pickupper, "LuaComponent"), function(lua)
        return ComponentGetValue2(lua, "script_shot") == "mods/iota_multiplayer/files/scripts/perks/autoaim_shot.lua"
    end)[1]
    if lua then
        EntityRemoveComponent(entity_pickupper, lua)
        GamePrint(GameTextGet("$action_autoaim") .. " " .. GameTextGet("$option_off"))
    else
        EntityAddComponent2(entity_pickupper, "LuaComponent", {
            script_shot = "mods/iota_multiplayer/files/scripts/perks/autoaim_shot.lua",
            execute_every_n_frame = -1,
        })
        GamePrint(GameTextGet("$action_autoaim") .. " " .. GameTextGet("$option_on"))
    end
end
