dofile_once("mods/iota_multiplayer/lib.lua")

blockings = {}

function add_blocking(blocked)
    table.insert(blockings, { blocked = blocked, blockers = {} })
end

function add_blocker(blocked, blocker)
    for _, blocking in ipairs(blockings) do
        if blocking.blocked == blocked and not table.find(blocking.blockers, function(v) return v == blocker end) then
            table.insert(blocking.blockers, blocker)
            return true
        end
    end
end

function damage_about_to_be_received(damage, x, y, entity_thats_responsible, critical_hit_chance)
    local this = GetUpdatedEntityID()
    if this ~= entity_thats_responsible then
        if EntityHasTag(entity_thats_responsible, MOD.player) then
            damage = damage * ModSettingGet(MOD.friendly_fire_percentage)
        end
        if not ModSettingGet(MOD.friendly_fire_kick) and add_blocker(entity_thats_responsible, this) then
            damage = 0
        end
    end
    return damage, critical_hit_chance
end

function kick(entity_who_kicked)
    local this = GetUpdatedEntityID()
    if this == entity_who_kicked then
        add_blocking(this)
    end
end

function damage_received(damage, message, entity_thats_responsible, is_fatal, projectile_thats_responsible)
    if is_fatal then
        local this = GetUpdatedEntityID()
        local this_data = PlayerData(this)
        --this_data.damage_model.wait_for_kill_flag_on_death = true
        --EntityAddTag(this, MOD.disabled_by_fatal_damage)
        --EntityRemoveTag(this, MOD.player)
        --disable(this)
        --ComponentSetValue2(get_id(this_data.shooter), "mCessationDo", true)
        --ComponentSetValue2(get_id(this_data.shooter), "mCessationLifetime", 10000)
    end
end

function disable(entity)
    for _, component in ipairs(EntityGetAllComponents(entity)) do
        if ComponentGetIsEnabled(component) then
            ComponentAddTag(component, MOD.disabled_by_fatal_damage)
            EntitySetComponentIsEnabled(entity, component, false)
        end
    end
    for _, child in ipairs(get_children(entity)) do
        disable(child)
    end
end
