dofile_once("mods/iota_multiplayer/files/scripts/lib/isutilities.lua")

local projectile = GetUpdatedEntityID()
local projectile_x, projectile_y = EntityGetFirstHitboxCenter(projectile)

local proj_comp = EntityGetFirstComponent(projectile, "ProjectileComponent")
if not proj_comp then return end
local shooter = ComponentGetValue2(proj_comp, "mWhoShot")

local vel_x, vel_y = GameGetVelocityCompVelocity(projectile)
local vel_dir = get_direction(0, 0, vel_x, vel_y)
local speed = get_magnitude(vel_x, vel_y)

local function abs_direction_difference(a, b)
    return math.abs(get_direction_difference(a, b))
end

local enemies = table_filter(EntityGetWithTag("mortal"), function(enemy)
    local enemy_x, enemy_y = EntityGetFirstHitboxCenter(enemy)
    local to_enemy_dir = get_direction(projectile_x, projectile_y, enemy_x, enemy_y)
    return enemy ~= shooter and
        EntityGetComponent(enemy, "GenomeDataComponent") and
        EntityGetHerdRelation(shooter, enemy) < 100 and
        abs_direction_difference(to_enemy_dir, vel_dir) < math.pi / 2 and
        not RaytraceSurfaces(projectile_x, projectile_y, enemy_x, enemy_y)
end)

local enemy = table_iterate(enemies, function(a, b)
    if not b then
        return true
    end
    local x, y = EntityGetFirstHitboxCenter(a)
    local dir = get_direction(projectile_x, projectile_y, x, y)
    local old_x, old_y = EntityGetFirstHitboxCenter(b)
    local old_dir = get_direction(projectile_x, projectile_y, old_x, old_y)
    return abs_direction_difference(dir, vel_dir) < abs_direction_difference(old_dir, vel_dir)
end)

if not enemy then return end

local enemy_x, enemy_y = EntityGetFirstHitboxCenter(enemy)

local dir_x, dir_y     = vec_sub(enemy_x, enemy_y, projectile_x, projectile_y)
dir_x, dir_y           = vec_normalize(dir_x, dir_y)
dir_x, dir_y           = vec_mult(dir_x, dir_y, speed)

local vel_comp         = EntityGetFirstComponent(projectile, "VelocityComponent")
ComponentSetValueVector2(vel_comp, "mVelocity", dir_x, dir_y)
