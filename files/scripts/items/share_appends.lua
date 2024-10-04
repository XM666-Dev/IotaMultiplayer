local f = item_pickup
function _G.item_pickup(entity_item, entity_who_picked, name)
    EntityKill = function() end
    f(entity_item, entity_who_picked, name)
end
