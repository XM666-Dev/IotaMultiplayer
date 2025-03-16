function electricity_receiver_electrified()
    if ModSettingGet("iota_multiplayer.camera_zoom_max") ~= ModSettingGet("iota_multiplayer.camera_zoom_min") then
        local entities = EntityGetInRadius(0, 0, math.huge)
        for i, entity in ipairs(entities) do
            for i, type in ipairs{"ExplodeOnDamageComponent", "ExplosionComponent", "LightningComponent", "ProjectileComponent"} do
                local components = EntityGetComponent(entity, type) or {}
                for i, component in ipairs(components) do
                    ComponentObjectSetValue2(component, "config_explosion", "explosion_sprite_emissive", false)
                end
            end
            local emitters = EntityGetComponent(entity, "SpriteParticleEmitterComponent") or {}
            for i, emitter in ipairs(emitters) do
                ComponentSetValue2(emitter, "emissive", false)
                ComponentSetValue2(emitter, "z_index", -math.huge)
            end
        end
    end
end
