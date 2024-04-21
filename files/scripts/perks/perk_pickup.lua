function item_pickup(entity_item, entity_pickupper, item_name)
    EntityAddComponent(entity_pickupper, "LuaComponent", {
        script_shot = "mods/noita_multiplayer/files/scripts/perks/autoaim.lua",
        execute_every_n_frame = "-1",
    })
end
