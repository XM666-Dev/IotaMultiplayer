function shot(projectile_entity_id)
    EntityAddComponent2(projectile_entity_id, "LuaComponent", {
        script_source_file = "mods/iota_multiplayer/files/scripts/perks/autoaim.lua",
        remove_after_executed = true
    })
end
