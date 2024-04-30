function item_pickup(entity_item, entity_pickupper)
    EntityKill(entity_item)
    EntityAddComponent2(entity_pickupper, "LuaComponent", {
        script_shot = "mods/iota_multiplayer/files/scripts/perks/autoaim_shot.lua",
        execute_every_n_frame = -1,
    })
end
