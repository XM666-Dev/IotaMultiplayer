dofile_once("mods/iota_multiplayer/files/scripts/lib/utilities.lua")

if ModSettingGet("iota_multiplayer.camera_zoom_max") ~= ModSettingGet("iota_multiplayer.camera_zoom_min") then
    local entities = EntityGetInRadius(0, 0, math.huge)
    for i, entity in ipairs(entities) do
        local sprites = EntityGetComponent(entity, "SpriteComponent") or {}
        for i, sprite in ipairs(sprites) do
            if ComponentGetValue2(sprite, "emissive") then
                ComponentSetValue2(sprite, "emissive", false)
                ComponentSetValue2(sprite, "z_index", -math.huge)
                refresh_sprite(sprite)
            end
        end
    end
end

local players_including_disabled = get_players_including_disabled()
for i, player in ipairs(players_including_disabled) do
    local player_object = Player(player)
    if player_object.index == 1 then
        if player_object.alive == nil and not validate(EntityGetParent(player)) then
            EntityAddChild(EntityGetWithName("iota_multiplayer.updator"), player)
        end
    else
        local first_player = get_player_at_index_including_disabled(1)
        if first_player ~= nil and not validate(EntityGetParent(player)) then
            EntityAddChild(first_player, player)
        end
        remove_component(player_object.alive_._id)
    end
end
