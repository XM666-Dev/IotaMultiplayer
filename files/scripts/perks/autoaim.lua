dofile_once("mods/iota_multiplayer/files/scripts/lib/sult.lua"):import()

local projectile = GetUpdatedEntityID()
local projectile_x, projectile_y = EntityGetFirstHitboxCenter(projectile)

local projectile_component = EntityGetFirstComponent(projectile, "ProjectileComponent")
if not projectile_component then return end
local shooter = ComponentGetValue2(projectile_component, "mWhoShot")

local velocity_x, velocity_y = GameGetVelocityCompVelocity(projectile)
local velocity_direction = get_direction(0, 0, velocity_x, velocity_y)
local speed = get_magnitude(velocity_x, velocity_y)

local function get_direction_difference_abs(a, b)
    return math.abs(get_direction_difference(a, b))
end

local enemies = table.filter(EntityGetWithTag("mortal"), function(enemy)
    local enemy_x, enemy_y = EntityGetFirstHitboxCenter(enemy)
    local enemy_direction = get_direction(projectile_x, projectile_y, enemy_x, enemy_y)
    return enemy ~= shooter and
        EntityGetComponent(enemy, "GenomeDataComponent") and
        EntityGetHerdRelation(shooter, enemy) < 100 and
        get_direction_difference_abs(enemy_direction, velocity_direction) < math.pi / 4 and
        not RaytraceSurfaces(projectile_x, projectile_y, enemy_x, enemy_y)
end)

local enemy = table.iterate(enemies, function(a, b)
    if not b then
        return true
    end
    local a_x, a_y = EntityGetFirstHitboxCenter(a)
    local a_direction = get_direction(projectile_x, projectile_y, a_x, a_y)
    local b_x, b_y = EntityGetFirstHitboxCenter(b)
    local b_direction = get_direction(projectile_x, projectile_y, b_x, b_y)
    return get_direction_difference_abs(a_direction, velocity_direction) < get_direction_difference_abs(b_direction, velocity_direction)
end)

if not enemy then return end

local enemy_x, enemy_y   = EntityGetFirstHitboxCenter(enemy)

local vector_x, vector_y = vec_sub(enemy_x, enemy_y, projectile_x, projectile_y)
vector_x, vector_y       = vec_normalize(vector_x, vector_y)
vector_x, vector_y       = vec_mult(vector_x, vector_y, speed)

local velocity_comp      = EntityGetFirstComponent(projectile, "VelocityComponent")
ComponentSetValueVector2(velocity_comp, "mVelocity", vector_x, vector_y)
