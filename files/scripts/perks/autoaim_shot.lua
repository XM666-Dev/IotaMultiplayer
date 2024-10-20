dofile_once("mods/iota_multiplayer/files/scripts/lib/utilities.lua")

local function get_direction_difference_abs(a, b)
    return math.abs(get_direction_difference(a, b))
end

function shot(projectile)
    local autoaim = GetUpdatedComponentID()
    local physics_body = EntityGetFirstComponentIncludingDisabled(projectile, "PhysicsBodyComponent")
    local item = EntityGetFirstComponentIncludingDisabled(projectile, "ItemComponent")
    local projectile_component = EntityGetFirstComponent(projectile, "ProjectileComponent")
    if not ComponentGetIsEnabled(autoaim) or physics_body ~= nil and item ~= nil or projectile_component == nil then
        return
    end

    local shooter = ComponentGetValue2(projectile_component, "mWhoShot")
    local projectile_x, projectile_y = EntityGetFirstHitboxCenter(projectile)
    local velocity_x, velocity_y = GameGetVelocityCompVelocity(projectile)
    local velocity_direction = get_direction(0, 0, velocity_x, velocity_y)

    local shooter_data = Player(shooter)
    local x, y = shooter_data.controls.mAimingVectorNormalized()
    local length = x * x + y * y
    local angle = math.pi / 4 * length

    local enemies = table.filter(EntityGetWithTag("enemy"), function(enemy)
        local enemy_x, enemy_y = EntityGetFirstHitboxCenter(enemy)
        local enemy_direction = get_direction(projectile_x, projectile_y, enemy_x, enemy_y)
        return enemy ~= shooter and
            EntityGetHerdRelationSafe(shooter, enemy) < 100 and
            get_direction_difference_abs(enemy_direction, velocity_direction) < angle and
            not RaytraceSurfaces(projectile_x, projectile_y, enemy_x, enemy_y)
    end)

    local enemy = table.iterate(enemies, function(a, b)
        local a_x, a_y = EntityGetFirstHitboxCenter(a)
        local a_distance = get_distance(projectile_x, projectile_y, a_x, a_y)
        local a_direction = get_direction(projectile_x, projectile_y, a_x, a_y)
        local a_weight = a_distance * get_direction_difference_abs(a_direction, velocity_direction)
        local b_x, b_y = EntityGetFirstHitboxCenter(b)
        local b_distance = get_distance(projectile_x, projectile_y, b_x, b_y)
        local b_direction = get_direction(projectile_x, projectile_y, b_x, b_y)
        local b_weight = b_distance * get_direction_difference_abs(b_direction, velocity_direction)
        return a_weight < b_weight
    end)
    if enemy == nil then return end

    local enemy_x, enemy_y = EntityGetFirstHitboxCenter(enemy)
    GameShootProjectile(0, projectile_x, projectile_y, enemy_x, enemy_y, projectile, false)
end
