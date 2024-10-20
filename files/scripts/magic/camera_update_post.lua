if ModSettingGet("iota_multiplayer.camera_zoom_max") ~= ModSettingGet("iota_multiplayer.camera_zoom_min") then
    local entities = EntityGetInRadius(0, 0, math.huge)
    for i, entity in ipairs(entities) do
        local sprites = EntityGetComponent(entity, "SpriteComponent") or {}
        for i, sprite in ipairs(sprites) do
            if ComponentGetValue2(sprite, "emissive") then
                ComponentSetValue2(sprite, "emissive", false)
                ComponentSetValue2(sprite, "z_index", -math.huge)
                EntityRefreshSprite(entity, sprite)
            end
        end
    end
end
