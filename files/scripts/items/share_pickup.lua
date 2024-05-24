dofile_once("mods/iota_multiplayer/lib.lua")

function item_pickup(entity_item, entity_pickupper, item_name)
    local filename = EntityGetFilename(entity_item)
    if filename == "data/entities/items/pickup/heart_fullhp_temple.xml" and ModSettingGet(MULTIPLAYER.temple_heart_share) or
        filename == "data/entities/items/pickup/spell_refresh.xml" and ModSettingGet(MULTIPLAYER.temple_refresh_share) then
        local players = get_players()
        for _, player in ipairs(players) do
            if player ~= entity_pickupper then
                local x, y = EntityGetTransform(player)
                EntityLoad(filename, x, y)
            end
        end
    end
end
