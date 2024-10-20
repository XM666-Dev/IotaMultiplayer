dofile_once("mods/iota_multiplayer/files/scripts/lib/utilities.lua")

local blocks = {}
local function add_block(blocked)
    blocks[blocked] = {}
end
local function add_blocker(blocked, blocker)
    local blockers = blocks[blocked]
    if blockers ~= nil and not table.find(blockers, function(v) return v == blocker end) then
        table.insert(blockers, blocker)
        return true
    end
end

function kick(entity_who_kicked)
    local this = GetUpdatedEntityID()
    if this == entity_who_kicked then
        add_block(this)
    end
end

function damage_about_to_be_received(damage, x, y, entity_thats_responsible, critical_hit_chance)
    local this = GetUpdatedEntityID()
    if validate(entity_thats_responsible) and entity_thats_responsible ~= this and EntityHasTag(entity_thats_responsible, "iota_multiplayer.player") then
        if not ModSettingGet("iota_multiplayer.friendly_fire_kick") and add_blocker(entity_thats_responsible, this) then
            damage = 0
        elseif damage > 0 then
            damage = damage * ModSettingGet("iota_multiplayer.friendly_fire_percent")
        end
    end
    return damage, critical_hit_chance
end

function shot(projectile_entity_id)
    local projectile = EntityGetFirstComponent(projectile_entity_id, "ProjectileComponent")
    if ModSettingGet("iota_multiplayer.friendly_fire_force") and projectile ~= nil then
        ComponentSetValue2(projectile, "mShooterHerdId", -1)
    end
end
