dofile_once("mods/iota_multiplayer/lib.lua")

local old_item_pickup = item_pickup

function item_pickup(entity_item, entity_who_picked, name)
    old_item_pickup(entity_item, entity_who_picked, name)
    local players = get_players()
    for _, player in ipairs(players) do
        if player ~= entity_who_picked then
            local max_hp = 0
            local max_hp_addition = 0.4
            local healing = 0

            local x, y = EntityGetTransform(entity_item)

            local damagemodels = EntityGetComponent(player, "DamageModelComponent")
            if (damagemodels ~= nil) then
                for i, damagemodel in ipairs(damagemodels) do
                    max_hp = tonumber(ComponentGetValue(damagemodel, "max_hp"))
                    local max_hp_cap = tonumber(ComponentGetValue(damagemodel, "max_hp_cap"))
                    local hp = tonumber(ComponentGetValue(damagemodel, "hp"))

                    max_hp = max_hp + max_hp_addition

                    if (max_hp_cap > 0) then
                        max_hp_cap = math.max(max_hp, max_hp_cap)
                    end

                    healing = max_hp - hp

                    -- if( hp > max_hp ) then hp = max_hp end
                    ComponentSetValue(damagemodel, "max_hp_cap", max_hp_cap)
                    ComponentSetValue(damagemodel, "max_hp", max_hp)
                    ComponentSetValue(damagemodel, "hp", max_hp)
                end
            end
        end
    end
end
