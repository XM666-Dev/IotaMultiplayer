dofile_once("mods/iota_multiplayer/files/scripts/lib/utilities.lua")

local blocks
local block_frame
local function consume_block(consumer, blocked)
    local block = table.find(blocks, function(v) return v.enabled and v.blocked == blocked and not table.find(v.consumers, consumer) end)
    if block ~= nil then
        block.enabled = false
        table.insert(block.consumers, consumer)
    end
    return block
end

function kick(kicked)
    local this = GetUpdatedEntityID()
    if kicked == this then
        local frame = GameGetFrameNum()
        if block_frame ~= frame then
            block_frame = frame
            blocks = {}
        end
        table.insert(blocks, {enabled = true, blocked = kicked, consumers = {}})
    elseif EntityHasTag(kicked, "iota_multiplayer.player") then
        local block = table.find(blocks, function(v) return v.blocked == kicked end)
        block.enabled = true
    end
end

function damage_about_to_be_received(damage, x, y, responsible, critical_hit_chance)
    local this = GetUpdatedEntityID()
    if EntityHasTag(responsible, "iota_multiplayer.player") and responsible ~= this and damage > 0 then
        if not ModSettingGet("iota_multiplayer.friendly_fire_kick") and block_frame == GameGetFrameNum() and consume_block(this, responsible) then
            damage = 0
        else
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
