dofile_once("mods/iota_multiplayer/files/scripts/lib/utilities.lua")

local this = GetUpdatedEntityID()
local parent = this
while EntityGetComponentIncludingDisabled(parent, "ItemComponent") ~= nil do
    parent = EntityGetParent(parent)
end
SetValueInteger("player", EntityGetParent(parent))

local message = true
function throw_item(from_x, from_y, to_x, to_y)
    local player = GetValueInteger("player", 0)
    if EntityHasTag(player, "iota_multiplayer.player") and message then
        local player_object = Player(player)
        if player_object.controls.mButtonFrameDropItem == GameGetFrameNum() and player_object:is_inventory_open() then
            local this = GetUpdatedEntityID()
            local physics_body = EntityGetFirstComponentIncludingDisabled(this, "PhysicsBodyComponent")
            local item = EntityGetFirstComponentIncludingDisabled(this, "ItemComponent")
            local velocity = EntityGetFirstComponentIncludingDisabled(this, "VelocityComponent")
            if physics_body ~= nil and item ~= nil then
                message = false
                GameShootProjectile(player, from_x, from_y, from_x, from_y, this)
                message = true
            elseif velocity ~= nil then
                ComponentSetValue2(velocity, "mVelocity", 0, -160)
            end
        end
    end
end
