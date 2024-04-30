--IotaMultiplayer - Version Alpha 0.4
--Created by ImmortalDamned
--Github https://github.com/XM666-Dev/IotaMultiplayer

dofile_once("mods/iota_multiplayer/lib.lua")

ModLuaFileAppend("mods/mnee/bindings.lua", "mods/iota_multiplayer/mnee.lua")

function OnWorldInitialized()
    set_dictionary_metatable()
    max_user = 1
end

function OnPlayerSpawned(player)
    if has_flag_run_once(MP.player_spawned) then
        return
    end
    add_player(player)
    PlayerData(player).user = 1
    spawned_player = player
    focused_player = player
    local x, y = EntityGetTransform(player)
    for _ = 2, tonumber(ModSettingGet(MP.player_num)) do
        load_player()
        perk_spawn_with_data(x, y, {
            ui_name = "$action_autoaim",
            ui_description = "$actiondesc_autoaim",
            perk_icon = "data/ui_gfx/gun_actions/autoaim.png",
        })
    end
end

function update_focused_player()
    local players = get_players()
    if not focused_player and spawned_player then
        focused_player = spawned_player
    end
    if get_binding_pressed(MP(), "switch_focus") then
        focused_player = table_iterate(players, function(a, b)
            return (b == nil or PlayerData(a).user < PlayerData(b).user) and
                PlayerData(a).user > PlayerData(focused_player).user
        end)
        if focused_player == nil then
            focused_player = table_iterate(players, function(a, b)
                return b == nil or PlayerData(a).user < PlayerData(b).user
            end)
        end
    end
    if get_binding_pressed(MP(), "teleport") then
        for _, player in ipairs(players) do
            if player ~= focused_player then
                local from_x, from_y = EntityGetTransform(player)
                local to_x, to_y = EntityGetTransform(focused_player)
                teleport(player, from_x, from_y, to_x, to_y)
            end
        end
    end
    for _, player in ipairs(players) do
        if player ~= focused_player then
            set_player_focused(player, false)
        end
    end
end

function update_controls()
    local players = get_players()
    for _, player in ipairs(players) do
        local player_data = PlayerData(player)
        local player_x, player_y = EntityGetTransform(player)
        local frame = GameGetFrameNum() + 1
        local function is_player_binding_down(name)
            return is_binding_down(MP.p .. player_data.user, name)
        end
        local function is_player_binding_just_down(name)
            return get_binding_pressed(MP.p .. player_data.user, name)
        end
        local function update_inventory(down, pressed)
            if focused_player ~= player then
                player_data.controls.mButtonDownInventory = down
                if pressed then
                    if PlayerData(focused_player).gui.mActive then
                        close_inventory(PlayerData(focused_player))
                    else
                        previous_focused_player = previous_focused_player or focused_player
                        focused_player = player
                        open_inventory(player_data)
                    end
                end
            else
                player_data.controls.mButtonDownInventory = down
                if pressed then
                    player_data.controls.mButtonFrameInventory = frame
                    if player_data.gui.mActive then
                        focused_player = previous_focused_player or focused_player
                        previous_focused_player = nil
                    end
                end
            end
        end

        if player_data.user == 1 then
            --if focused_player ~= player then
            --    if player_data.controls.mButtonFrameInventory == frame then
            --        if PlayerData(focused_player).gui.mActive then
            --            close_inventory(PlayerData(focused_player))
            --        else
            --            previous_focused_player = previous_focused_player or focused_player
            --            focused_player = player
            --            open_inventory(player_data)
            --        end
            --    end
            --else
            --    if player_data.controls.mButtonFrameInventory == frame then
            --        if player_data.gui.mActive then
            --            focused_player = previous_focused_player or focused_player
            --            previous_focused_player = nil
            --        end
            --    end
            --end
            goto continue
        end

        player_data.controls.enabled = false

        player_data.controls.mButtonDownFire = is_player_binding_down("usewand")
        if is_player_binding_just_down("usewand") then
            player_data.controls.mButtonFrameFire = frame
        end
        if is_player_binding_down("usewand") then
            player_data.controls.mButtonLastFrameFire = frame
        end

        player_data.controls.mButtonDownFire2 = is_player_binding_down("sprayflask")
        if is_player_binding_just_down("sprayflask") then
            player_data.controls.mButtonFrameFire2 = frame
        end

        player_data.controls.mButtonDownThrow = is_player_binding_down("throw")
        if is_player_binding_just_down("throw") then
            player_data.controls.mButtonFrameThrow = frame
        end

        player_data.controls.mButtonDownInteract = is_player_binding_down("interact")
        if is_player_binding_just_down("interact") then
            player_data.controls.mButtonFrameInteract = frame
        end

        player_data.controls.mButtonDownLeft = is_player_binding_down("left")
        if is_player_binding_just_down("left") then
            player_data.controls.mButtonFrameLeft = frame
        end

        player_data.controls.mButtonDownRight = is_player_binding_down("right")
        if is_player_binding_just_down("right") then
            player_data.controls.mButtonFrameRight = frame
        end

        player_data.controls.mButtonDownUp = is_player_binding_down("up")
        if is_player_binding_just_down("up") then
            player_data.controls.mButtonFrameUp = frame
        end

        player_data.controls.mButtonDownDown = is_player_binding_down("down")
        if is_player_binding_just_down("down") then
            player_data.controls.mButtonFrameDown = frame
        end

        player_data.controls.mButtonDownFly = is_player_binding_down("up")
        if is_player_binding_just_down("up") then
            player_data.controls.mButtonFrameFly = frame
        end

        player_data.controls.mButtonDownChangeItemR = is_player_binding_down("itemnext")
        if is_player_binding_just_down("itemnext") then
            player_data.controls.mButtonFrameChangeItemR = frame
            player_data.controls.mButtonCountChangeItemR = 1
        else
            player_data.controls.mButtonCountChangeItemR = 0
        end

        player_data.controls.mButtonDownChangeItemL = is_player_binding_down("itemprev")
        if is_player_binding_just_down("itemprev") then
            player_data.controls.mButtonFrameChangeItemL = frame
            player_data.controls.mButtonCountChangeItemL = 1
        else
            player_data.controls.mButtonCountChangeItemL = 0
        end

        update_inventory(is_player_binding_down("inventory"), is_player_binding_just_down("inventory"))

        player_data.controls.mButtonDownKick = is_player_binding_down("kick")
        if is_player_binding_just_down("kick") then
            player_data.controls.mButtonFrameKick = frame
        end

        player_data.controls.mFlyingTargetY = player_y - 10

        local vec_x, vec_y = get_axis_state(MP.p .. player_data.user, "aimh"),
            get_axis_state(MP.p .. player_data.user, "aimv")
        local camera_x, camera_y = GameGetCameraBounds()
        if vec_x ~= 0 or vec_y ~= 0 then
            player_data.controls("mAimingVector").set(vec_x * 100, vec_y * 100)
        end
        player_data.controls("mAimingVectorNormalized").set(vec_x, vec_y)
        if vec_x ~= 0 or vec_y ~= 0 then
            player_data.controls("mAimingVectorNonZeroLatest").set(vec_x, vec_y)
        end
        player_data.controls("mGamepadAimingVectorRaw").set(vec_x, vec_y)

        local mouse_x, mouse_y = player_x + vec_x * 100, player_y + vec_y * 100
        player_data.controls("mMousePosition").set(mouse_x, mouse_y)
        player_data.controls("mMousePositionRaw").set(vec_mult(mouse_x - camera_x, mouse_y - camera_y, 3))

        ::continue::
    end
end

function update_camera()
    if focused_player == nil or spawned_player == nil then
        return
    end
    local shooter_comp = EntityGetFirstComponent(focused_player, "PlatformShooterPlayerComponent")
    local desired_x, desired_y = ComponentGetValue2(shooter_comp, "mDesiredCameraPos")
    local spawned_shooter_comp = EntityGetFirstComponent(spawned_player, "PlatformShooterPlayerComponent")
    if spawned_shooter_comp then
        ComponentSetValue2(spawned_shooter_comp, "mDesiredCameraPos", desired_x, desired_y)
    end
end

gui = GuiCreate()

function update_gui()
    if focused_player == nil then
        return
    end
    GuiStartFrame(gui)
    local focused_player_data = PlayerData(focused_player)
    GuiOptionsAdd(gui, GUI_OPTION.Align_HorizontalCenter)
    GuiText(gui, 10, 25, "P" .. focused_player_data.user)
    local camera_x, camera_y = GameGetCameraPos()
    local _, _, w, h = GameGetCameraBounds()
    camera_x = camera_x - w / 2
    camera_y = camera_y - h / 2
    local players = get_players()
    for _, player in ipairs(players) do
        local player_data = PlayerData(player)
        local player_x, player_y = EntityGetTransform(player)
        local x, y = (player_x - camera_x) * 1.5, (player_y - camera_y) * 1.5
        GuiOptionsAdd(gui, GUI_OPTION.Align_HorizontalCenter)
        GuiText(gui, x, y + 5, "P" .. player_data.user)
    end
end

function OnWorldPreUpdate()
    update_focused_player()
    update_camera()
    update_controls()
end

function OnWorldPostUpdate()
    update_gui()
end
