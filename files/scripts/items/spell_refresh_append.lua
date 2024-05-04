dofile_once("mods/iota_multiplayer/lib.lua")

local old_item_pickup = item_pickup

function item_pickup(entity_item, entity_who_picked, name)
    old_item_pickup(entity_item, entity_who_picked, name)
    local players = get_players()
    for _, player in ipairs(players) do
        if player ~= entity_who_picked then
            GameRegenItemActionsInPlayer(player)
        end
    end
end
