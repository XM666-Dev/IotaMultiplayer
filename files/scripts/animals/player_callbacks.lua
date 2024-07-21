dofile_once("mods/iota_multiplayer/lib.lua")

blocks = {}

function add_block(blocked)
    blocks[blocked] = {}
end

function add_blocker(blocked, blocker)
    local blockers = blocks[blocked]
    if blockers and not table.find(blockers, function(v) return v == blocker end) then
        table.insert(blockers, blocker)
        return true
    end
end

function damage_about_to_be_received(damage, x, y, entity_thats_responsible, critical_hit_chance)
    local this = GetUpdatedEntityID()
    if validate_entity(entity_thats_responsible) and entity_thats_responsible ~= this and EntityHasTag(entity_thats_responsible, "iota_multiplayer.player") then
        damage = not ModSettingGet("iota_multiplayer.friendly_fire_kick") and add_blocker(entity_thats_responsible, this) and 0 or damage * ModSettingGet("iota_multiplayer.friendly_fire_percentage")
    end
    return damage, critical_hit_chance
end

function kick(entity_who_kicked)
    local this = GetUpdatedEntityID()
    if this == entity_who_kicked then
        add_block(this)
    end
end

function damage_received(damage, message, entity_thats_responsible, is_fatal, projectile_thats_responsible)
    if is_fatal then
        local this = GetUpdatedEntityID()
        local this_data = Player(this)
        this_data.damage_frame = GameGetFrameNum()
        this_data.damage_message = message
        this_data.damage_entity_thats_responsible = entity_thats_responsible
    end
end
