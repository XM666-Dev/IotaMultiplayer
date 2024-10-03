function electricity_receiver_electrified()
    local entities = EntityGetInRadius(0, 0, math.huge)
    for i, entity in ipairs(entities) do
        for i, type in ipairs({ "ExplodeOnDamageComponent", "ExplosionComponent", "LightningComponent", "ProjectileComponent" }) do
            local components = EntityGetComponent(entity, type) or {}
            for i, component in ipairs(components) do
                ComponentObjectSetValue2(component, "config_explosion", "explosion_sprite_emissive", false)
            end
        end
        local emitters = EntityGetComponent(entity, "SpriteParticleEmitterComponent") or {}
        for i, emitter in ipairs(emitters) do
            ComponentSetValue2(emitter, "emissive", false)
        end
    end
end
