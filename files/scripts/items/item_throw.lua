dofile_once("mods/iota_multiplayer/files/scripts/lib/utilities.lua")

local this = GetUpdatedEntityID()
local root = EntityGetRootEntity(this)
if root ~= this then
    SetValueInteger("last_root", root)
end

function throw_item(from_x, from_y, to_x, to_y)
    local last_root = GetValueInteger("last_root", 0)
    if EntityHasTag(last_root, "iota_multiplayer.player") and not flag then
        local player_data = Player(last_root)
        if player_data.controls.mButtonFrameDropItem == GameGetFrameNum() and player_data:is_inventory_open() then
            this = GetUpdatedEntityID()
            local physics_body = EntityGetFirstComponentIncludingDisabled(this, "PhysicsBodyComponent")
            local item = EntityGetFirstComponentIncludingDisabled(this, "ItemComponent")
            local velocity = EntityGetFirstComponentIncludingDisabled(this, "VelocityComponent")
            if physics_body ~= nil and item ~= nil then
                flag = true
                GameShootProjectile(last_root, from_x, from_y, from_x, from_y, this)
                flag = false
            elseif velocity ~= nil then
                ComponentSetValue2(velocity, "mVelocity", 0, -160)
            end
        end
    end
end
