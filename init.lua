--NoitaMultiplayer - Version Alpha 0.2
--Created by ImmortalDamned
--Github https://github.com/XM666-Dev

dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/scripts/debug/keycodes.lua")
dofile_once("mods/isoul_library/scripts/lib/utilities.lua")
dofile_once("mods/mnee/lib.lua")
dofile_once("data/scripts/perks/perk.lua")

ModLuaFileAppend("mods/mnee/bindings.lua", "mods/noita_multiplayer/mnee.lua")

MPM = namespace("noita_multiplayer_mod")

setmetatable(_G, entrytable({
    original_player = tag_entity_entry(MPM.original_player),
    primary_character = {
        get = function()
            return get_tag_entity(MPM.primary_character)
        end,
        set = function(v)
            set_character_enabled(primary_character, false)
            set_character_enabled(v, true)
            set_tag_entity(MPM.primary_character, v)
        end
    }
}))

function character_vt(character)
    local t = {}
    setmetatable(t, entrytable({
        user = var_entry(character, MPM.user, Int)
    }))
    return t
end

function add_character(character)
    EntityAddTag(character, MPM.character)
    set_character_enabled(character, false)
end

function get_characters()
    return EntityGetWithTag(MPM.character)
end

function set_character_enabled(character, enabled)
    local gui_comp = EntityGetFirstComponentIncludingDisabled(character, "InventoryGuiComponent")
    if gui_comp ~= nil then
        EntitySetComponentIsEnabled(character, gui_comp, enabled)
    end
end

function load_character_player()
    local x, y = EntityGetTransform(primary_character)
    local character = EntityLoad("data/entities/player.xml", x, y)
    add_character(character)
    return character
end

function OnPlayerSpawned(p1)
    if has_run_once(MPM.player_initialized) then
        return
    end
    local x, y = EntityGetTransform(p1)
    perk_spawn(x, y, "PROJECTILE_HOMING", true)
    add_character(p1)
    original_player = p1
    primary_character = p1
    local second_player = load_character_player()
    local first_vt = character_vt(p1)
    local second_vt = character_vt(second_player)
    first_vt.user = 1
    second_vt.user = 2
end

function update_primary_character()
    if primary_character == nil then
        primary_character = get_characters()[1]
    end
    if InputIsKeyJustDown(Key_g) then
        local characters = get_characters()
        primary_character = table_iterate(characters, function(a, b)
            return (b == nil or character_vt(a).user < character_vt(b).user) and
                character_vt(a).user > character_vt(primary_character).user
        end)
        if primary_character == nil then
            primary_character = table_iterate(characters, function(a, b)
                return b == nil or character_vt(a).user < character_vt(b).user
            end)
        end
    end
end

function update_character_controls()
    local characters = get_characters()
    local _, p1 = table_find(characters, function(v)
        return character_vt(v).user == 1
    end)
    local _, p2 = table_find(characters, function(v)
        return character_vt(v).user == 2
    end)
    if p2 ~= nil then
        local controls_comp = EntityGetFirstComponent(p2, "ControlsComponent")
        local controls_ft = fieldtable(controls_comp)
        controls_ft.enabled.set(false)

        local up = is_binding_down("noita_multiplayer", "up") --up
        local player_x, player_y = EntityGetTransform(p2)
        controls_ft.mFlyingTargetY.set(player_y - 10)
        controls_ft.mButtonDownUp.set(up)
        controls_ft.mButtonDownFly.set(up)

        controls_ft.mButtonDownDown.set(is_binding_down("noita_multiplayer", "down"))   --down

        controls_ft.mButtonDownLeft.set(is_binding_down("noita_multiplayer", "left"))   --left

        controls_ft.mButtonDownRight.set(is_binding_down("noita_multiplayer", "right")) --right

        local aim_x, aim_y = InputGetJoystickAnalogStick(0, 1)                          --aim
        local camera_x, camera_y = GameGetCameraBounds()
        if aim_x ~= 0 or aim_y ~= 0 then
            controls_ft.mAimingVector.set(aim_x * 100, aim_y * 100)
            controls_ft.mAimingVectorNonZeroLatest.set(aim_x, aim_y)
        end
        controls_ft.mAimingVectorNormalized.set(aim_x, aim_y)
        controls_ft.mGamepadAimingVectorRaw.set(aim_x, aim_y)
        controls_ft.mMousePosition.set(player_x + aim_x * 100, player_y + aim_y * 100)
        controls_ft.mMousePositionRaw.set(vec_mult(player_x - camera_x + aim_x * 300,
            player_y - camera_y + aim_y * 300, 3))
        local shooter_comp = EntityGetFirstComponent(p2, "PlatformShooterPlayerComponent")
        ComponentSetValue2(shooter_comp, "mHasGamepadControlsPrev", true)

        controls_ft.mButtonDownFire.set(is_binding_down("noita_multiplayer", "use_wand")) --use_wand
        if get_binding_pressed("noita_multiplayer", "use_wand") then
            controls_ft.mButtonFrameFire.set(GameGetFrameNum() + 1)
        end

        controls_ft.mButtonDownFire2.set(is_binding_down("noita_multiplayer", "spray_from_potion")) --spray_from_potion

        if get_binding_pressed("noita_multiplayer", "throw") then                                   --throw
            controls_ft.mButtonDownThrow.set(true)
            controls_ft.mButtonFrameThrow.set(GameGetFrameNum() + 1)
        end

        if get_binding_pressed("noita_multiplayer", "kick") then --kick
            controls_ft.mButtonDownKick.set(true)
            controls_ft.mButtonFrameKick.set(GameGetFrameNum() + 1)
        end

        if get_binding_pressed("noita_multiplayer", "open_or_close_inventory") then --open_or_close_inventory
            if primary_character == p1 then
                local p1_gui_comp = EntityGetFirstComponent(p1, "InventoryGuiComponent")
                if p1_gui_comp ~= nil and ComponentGetValue2(p1_gui_comp, "mActive") then
                    local p1_controls_comp = EntityGetFirstComponent(p1, "ControlsComponent")
                    ComponentSetValue2(p1_controls_comp, "mButtonDownInventory", true)
                    ComponentSetValue2(p1_controls_comp, "mButtonFrameInventory", GameGetFrameNum() + 1)
                    --ComponentSetValue2(EntityGetFirstComponentIncludingDisabled(p2, "InventoryGuiComponent"), "mActive",
                    --    false)
                    --controls_ft.mButtonDownInventory.set(true)
                    --controls_ft.mButtonFrameInventory.set(GameGetFrameNum() + 1)
                    --ComponentSetValue2(p1_gui_comp, "mBackgroundOverlayAlpha", 0)
                end
                primary_character = p2
                local gui_comp = EntityGetFirstComponent(p2, "InventoryGuiComponent")
                if not ComponentGetValue2(gui_comp, "mActive") then
                    controls_ft.mButtonDownInventory.set(true)
                    controls_ft.mButtonFrameInventory.set(GameGetFrameNum() + 1)
                end
            else
                controls_ft.mButtonDownInventory.set(true)
                controls_ft.mButtonFrameInventory.set(GameGetFrameNum() + 1)
            end
        end
        local p1_controls_comp = EntityGetFirstComponent(p1, "ControlsComponent")
        if p1_controls_comp ~= nil and ComponentGetValue2(p1_controls_comp, "mButtonDownInventory") and primary_character ~= p1 then
            local p2_gui_comp = EntityGetFirstComponent(p2, "InventoryGuiComponent")
            if p2_gui_comp ~= nil and ComponentGetValue2(p2_gui_comp, "mActive") then
                controls_ft.mButtonDownInventory.set(true)
                controls_ft.mButtonFrameInventory.set(GameGetFrameNum() + 1)
            end
            primary_character = p1
            local gui_comp = EntityGetFirstComponent(p1, "InventoryGuiComponent")
            if not ComponentGetValue2(gui_comp, "mActive") then
                ComponentSetValue2(p1_controls_comp, "mButtonDownInventory", true)
                ComponentSetValue2(p1_controls_comp, "mButtonFrameInventory", GameGetFrameNum() + 1)
            end
        end

        if get_binding_pressed("noita_multiplayer", "interact") then --interact
            ComponentSetValue2(controls_comp, "mButtonDownInteract", true)
            ComponentSetValue2(controls_comp, "mButtonFrameInteract", GameGetFrameNum() + 1)
        end

        ComponentSetValue2(controls_comp, "mButtonCountChangeItemR", 0) --next_item
        if get_binding_pressed("noita_multiplayer", "next_item") then
            ComponentSetValue2(controls_comp, "mButtonDownChangeItemR", true)
            ComponentSetValue2(controls_comp, "mButtonFrameChangeItemR", GameGetFrameNum() + 1)
            ComponentSetValue2(controls_comp, "mButtonCountChangeItemR", 1)
        end

        ComponentSetValue2(controls_comp, "mButtonCountChangeItemL", 0) --previous_item
        if get_binding_pressed("noita_multiplayer", "previous_item") then
            ComponentSetValue2(controls_comp, "mButtonDownChangeItemL", true)
            ComponentSetValue2(controls_comp, "mButtonFrameChangeItemL", GameGetFrameNum() + 1)
            ComponentSetValue2(controls_comp, "mButtonCountChangeItemL", 1)
        end

        --select_item_in_slot_1
        --select_item_in_slot_2
        --select_item_in_slot_3
        --select_item_in_slot_4
        --select_item_in_slot_5
        --select_item_in_slot_6
        --select_item_in_slot_7
        --select_item_in_slot_8
    end
end

function update_camera()
    if primary_character == nil or original_player == nil then
        return
    end
    local shooter_comp = EntityGetFirstComponent(primary_character, "PlatformShooterPlayerComponent")
    local desired_x, desired_y = ComponentGetValue2(shooter_comp, "mDesiredCameraPos")
    local ft = fieldtable(EntityGetFirstComponent(original_player, "PlatformShooterPlayerComponent"))
    ft.mDesiredCameraPos.set(desired_x, desired_y)
end

function OnWorldPreUpdate()
    update_primary_character()
    update_camera()
    update_character_controls()
end
