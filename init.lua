--IotaMultiplayer - Created by ImmortalDamned
--Github https://github.com/XM666-Dev/IotaMultiplayer

dofile_once("mods/iota_multiplayer/lib.lua")

ModLuaFileAppend("mods/mnee/bindings.lua", "mods/iota_multiplayer/mnee.lua")
ModLuaFileAppend("data/scripts/items/spell_refresh.lua", "mods/iota_multiplayer/files/scripts/items/spell_refresh_append.lua")
ModLuaFileAppend("data/scripts/items/heart_fullhp_temple.lua", "mods/iota_multiplayer/files/scripts/items/heart_fullhp_temple_append.lua")

set_translations("mods/iota_multiplayer/translations.csv")

function OnWorldInitialized()
    set_dictionary_metatable()
end

function OnPlayerSpawned(player)
    player_spawned = true
    if has_globals_value_or_set(MULTIPLAYER.player_spawned_once, "yes") then
        return
    end
    add_player(player)
    spawned_player = player
    local x, y = EntityGetTransform(player)
    for i = 1, tonumber(ModSettingGet(MULTIPLAYER.player_num)) do
        if i > 1 then
            load_player(x, y)
        end
        perk_spawn_with_data(x, y, {
            ui_name = "$action_autoaim",
            ui_description = "$actiondesc_autoaim",
            perk_icon = "data/ui_gfx/gun_actions/autoaim.png"
        }, "mods/iota_multiplayer/files/scripts/perks/autoaim_pickup.lua")
    end
end

function update_common()
    local players = get_players()
    if mnee.mnin_bind(get_id(MULTIPLAYER), "switch_player", false, true) or player_spawned and not camera_centered_player then
        local entities = camera_centered_player and table.filter(players, function(player)
            return PlayerData(player).user > PlayerData(camera_centered_player).user
        end) or {}
        entities = #entities > 0 and entities or players
        camera_centered_player = table.iterate(entities, function(a, b)
            return not b or PlayerData(a).user < PlayerData(b).user
        end)
    end
    if mnee.mnin_bind(get_id(MULTIPLAYER), "toggle_teleport", false, true) then
        for _, player in ipairs(players) do
            if player ~= camera_centered_player then
                local from_x, from_y = EntityGetTransform(player)
                local to_x, to_y = EntityGetTransform(camera_centered_player)
                teleport(player, from_x, from_y, to_x, to_y)
            end
        end
    end
end

function update_controls()
    local players = get_players()
    for _, player in ipairs(players) do
        local player_data = PlayerData(player)
        local player_x, player_y = EntityGetTransform(player)

        player_data.controls.enabled = false

        player_data.controls.mButtonDownFire = player_data:mnin_bind("usewand", false, false, false, false, "guied")
        if player_data:mnin_bind("usewand", false, true, false, false, "guied") then
            player_data.controls.mButtonFrameFire = get_frame_num_next()
        end
        if player_data.controls.mButtonDownFire then
            player_data.controls.mButtonLastFrameFire = get_frame_num_next()
        end

        player_data.controls.mButtonDownFire2 = player_data:mnin_bind("sprayflask", false, false, false, false, "guied")
        if player_data:mnin_bind("sprayflask", false, true, false, false, "guied") then
            player_data.controls.mButtonFrameFire2 = get_frame_num_next()
        end

        local throw, throw_gone, throw_jpad = player_data:mnin_bind("throw", false, false, false, false, "guied")
        player_data.controls.mButtonDownThrow = throw and not (throw_jpad and GameIsInventoryOpen())
        if player_data:mnin_bind("throw", false, true, false, false, "guied") and player_data.controls.mButtonDownThrow then
            player_data.controls.mButtonFrameThrow = get_frame_num_next()
        end

        local interact, interact_gone, interact_jpad = player_data:mnin_bind("interact")
        player_data.controls.mButtonDownInteract = interact and not (interact_jpad and GameIsInventoryOpen())
        if player_data:mnin_bind("interact", false, true) then
            player_data.controls.mButtonFrameInteract = get_frame_num_next()
        end

        local left, left_gone, left_jpad = player_data:mnin_bind("left")
        player_data.controls.mButtonDownLeft = left and not (left_jpad and GameIsInventoryOpen())
        if player_data:mnin_bind("left", false, true) and player_data.controls.mButtonDownLeft then
            player_data.controls.mButtonFrameLeft = get_frame_num_next()
        end

        local right, right_gone, right_jpad = player_data:mnin_bind("right")
        player_data.controls.mButtonDownRight = right and not (right_jpad and GameIsInventoryOpen())
        if player_data:mnin_bind("right", false, true) and player_data.controls.mButtonDownRight then
            player_data.controls.mButtonFrameRight = get_frame_num_next()
        end

        player_data.controls.mButtonDownUp = player_data:mnin_bind("up")
        if player_data:mnin_bind("up", false, true) then
            player_data.controls.mButtonFrameUp = get_frame_num_next()
        end

        local down, down_gone, down_jpad = player_data:mnin_bind("down")
        player_data.controls.mButtonDownDown = down and not (down_jpad and GameIsInventoryOpen())
        if player_data:mnin_bind("down", false, true) then
            player_data.controls.mButtonFrameDown = get_frame_num_next()
        end

        player_data.controls.mButtonDownFly = player_data:mnin_bind("up")
        if player_data:mnin_bind("up", false, true) then
            player_data.controls.mButtonFrameFly = get_frame_num_next()
        end

        player_data.controls.mButtonDownChangeItemR = player_data:mnin_bind("itemnext")
        if player_data:mnin_bind("itemnext", false, true) then
            player_data.controls.mButtonFrameChangeItemR = get_frame_num_next()
            player_data.controls.mButtonCountChangeItemR = 1
        else
            player_data.controls.mButtonCountChangeItemR = 0
        end

        player_data.controls.mButtonDownChangeItemL = player_data:mnin_bind("itemprev")
        if player_data:mnin_bind("itemprev", false, true) then
            player_data.controls.mButtonFrameChangeItemL = get_frame_num_next()
            player_data.controls.mButtonCountChangeItemL = 1
        else
            player_data.controls.mButtonCountChangeItemL = 0
        end

        player_data.controls.mButtonDownInventory = player_data:mnin_bind("inventory")
        if player_data:mnin_bind("inventory", false, true) then
            player_data.controls.mButtonFrameInventory = get_frame_num_next()
            if gui_enabled_player ~= player then
                gui_enabled_player = player
            end
        end

        local kick, kick_gone, kick_jpad = player_data:mnin_bind("kick")
        player_data.controls.mButtonDownKick = kick and not (kick_jpad and GameIsInventoryOpen())
        if player_data:mnin_bind("kick", false, true) then
            player_data.controls.mButtonFrameKick = get_frame_num_next()
        end

        player_data.controls.mButtonDownLeftClick = mnee.mnin_key("mouse_left", false, false, false, "guied") and player == spawned_player
        if mnee.mnin_key("mouse_left", false, true, false, "guied") and player_data.controls.mButtonDownLeftClick then
            player_data.controls.mButtonFrameLeftClick = get_frame_num_next()
        end

        player_data.controls.mButtonDownRightClick = mnee.mnin_key("mouse_right", false, false, false, "guied") and player == spawned_player
        if mnee.mnin_key("mouse_right", false, true, false, "guied") and player_data.controls.mButtonDownRightClick then
            player_data.controls.mButtonFrameRightClick = get_frame_num_next()
        end

        player_data.controls.mFlyingTargetY = player_y - 10

        local aim, aim_gone, aim_buttoned = player_data:mnin_stick("aim")
        if aim_gone then
            local mouse_x, mouse_y = DEBUG_GetMouseWorld()
            local aiming_vector_x, aiming_vector_y = mouse_x - player_x, mouse_y - player_y
            local aiming_vector_normalized_x, aiming_vector_normalized_y = aiming_vector_x, aiming_vector_y
            local magnitude = get_magnitude(aiming_vector_x, aiming_vector_y)
            if magnitude < 100 then
                aiming_vector_normalized_x, aiming_vector_normalized_y = aiming_vector_x / 100, aiming_vector_y / 100
            else
                aiming_vector_normalized_x, aiming_vector_normalized_y = aiming_vector_x / magnitude, aiming_vector_y / magnitude
            end
            player_data.controls("mAimingVector").set(aiming_vector_x, aiming_vector_y)
            player_data.controls("mAimingVectorNormalized").set(aiming_vector_normalized_x, aiming_vector_normalized_y)
            local mouse_position_raw_x, mouse_position_raw_y = InputGetMousePosOnScreen()
            local mouse_position_raw_prev_x, mouse_position_raw_prev_y = player_data.controls("mMousePositionRaw").get()
            player_data.controls("mMousePosition").set(mouse_x, mouse_y)
            player_data.controls("mMousePositionRaw").set(mouse_position_raw_x, mouse_position_raw_y)
            player_data.controls("mMousePositionRawPrev").set(mouse_position_raw_prev_x, mouse_position_raw_prev_y)
            player_data.controls("mMouseDelta").set(mouse_position_raw_x - mouse_position_raw_prev_x, mouse_position_raw_y - mouse_position_raw_prev_y)
            goto continue
        end
        if GameIsInventoryOpen() then
            aim = { 0, 0 }
        end
        local function pressed(a, b, buttoned)
            return (a ~= b or not buttoned) and b ~= 0
        end
        local aiming_vector_x, aiming_vector_y = unpack(aim)
        local aiming_vector_non_zero_latest_x, aiming_vector_non_zero_latest_y = player_data.controls("mAimingVectorNonZeroLatest").get()
        local gamepad_aiming_vector_raw_x, gamepad_aiming_vector_raw_y = player_data.controls("mGamepadAimingVectorRaw").get()
        if aim[1] == 0 and aim[2] == 0 then
            aiming_vector_x, aiming_vector_y = aiming_vector_non_zero_latest_x, aiming_vector_non_zero_latest_y
        end
        if pressed(gamepad_aiming_vector_raw_x, aim[1], aim_buttoned[1]) or pressed(gamepad_aiming_vector_raw_y, aim[2], aim_buttoned[2]) then
            aiming_vector_non_zero_latest_x, aiming_vector_non_zero_latest_y = unpack(aim)
        end
        player_data.controls("mAimingVector").set(aiming_vector_x * 100, aiming_vector_y * 100)
        player_data.controls("mAimingVectorNormalized").set(unpack(aim))
        player_data.controls("mAimingVectorNonZeroLatest").set(aiming_vector_non_zero_latest_x, aiming_vector_non_zero_latest_y)
        player_data.controls("mGamepadAimingVectorRaw").set(unpack(aim))
        local cursor_x, cursor_y = player_data.controls("mGamePadCursorInWorld").get()
        local mouse_position_raw_x, mouse_position_raw_y = get_gui_pos_from_world(gui, cursor_x, cursor_y)
        mouse_position_raw_x, mouse_position_raw_y = mouse_position_raw_x * 2, mouse_position_raw_y * 2
        local mouse_position_raw_prev_x, mouse_position_raw_prev_y = player_data.controls("mMousePositionRaw").get()
        player_data.controls("mMousePosition").set(cursor_x, cursor_y)
        player_data.controls("mMousePositionRaw").set(mouse_position_raw_x, mouse_position_raw_y)
        player_data.controls("mMousePositionRawPrev").set(mouse_position_raw_prev_x, mouse_position_raw_prev_y)
        player_data.controls("mMouseDelta").set(mouse_position_raw_x - mouse_position_raw_prev_x, mouse_position_raw_y - mouse_position_raw_prev_y)
        ::continue::
    end
end

function update_camera()
    if not spawned_player or not camera_centered_player then
        return
    end
    local spawned_player_data = PlayerData(spawned_player)
    local camera_centered_player_data = PlayerData(camera_centered_player)
    spawned_player_data.shooter("mDesiredCameraPos").set(camera_centered_player_data.shooter("mDesiredCameraPos").get())
    local players = get_players()
    for _, player in ipairs(players) do
        local player_data = PlayerData(player)
        local listener_component = get_id(player_data.listener)
        if player ~= camera_centered_player and ComponentGetIsEnabled(listener_component) then
            camera_centered_player_data.shooter("mSmoothedCameraPosition").set(player_data.shooter("mSmoothedCameraPosition").get())
            spawned_player_data.shooter("mDesiredCameraPos").set(player_data.shooter("mSmoothedCameraPosition").get())
        end
        EntitySetComponentIsEnabled(player, listener_component, player == camera_centered_player)
    end
end

function update_gui()
    local gui_enabled_player_data = PlayerData(gui_enabled_player)
    if not gui_enabled_player or gui_enabled_player_data.gui.mActive == (gui_enabled_player_data.controls.mButtonFrameInventory == get_frame_num_next()) then
        gui_enabled_player = camera_centered_player
    end
    local players = get_players()
    for _, player in ipairs(players) do
        set_gui_enabled(player, player == gui_enabled_player)
    end
end

function update_wallet()
    if gui_enabled_player then
        local gui_enabled_player_data = PlayerData(gui_enabled_player)
        local players = get_players()
        for _, player in ipairs(players) do
            if player == gui_enabled_player then
                goto continue
            end
            local player_data = PlayerData(player)
            gui_enabled_player_data.wallet.money = gui_enabled_player_data.wallet.money + player_data.wallet.money - player_data.previous_money
            ::continue::
        end
        for _, player in ipairs(players) do
            local player_data = PlayerData(player)
            player_data.wallet.money = gui_enabled_player_data.wallet.money
            player_data.previous_money = player_data.wallet.money
        end
    end
end

gui = GuiCreate()

function draw_gui()
    GuiStartFrame(gui)
    GuiOptionsAdd(gui, GUI_OPTION.Align_HorizontalCenter)
    if gui_enabled_player then
        local gui_enabled_player_data = PlayerData(gui_enabled_player)
        GuiText(gui, 10, 25, "P" .. gui_enabled_player_data.user)
    end
    local players = get_players()
    for _, player in ipairs(players) do
        local player_data = PlayerData(player)
        local player_x, player_y = EntityGetTransform(player)
        local x, y = get_gui_pos_from_world(gui, player_x, player_y)
        GuiText(gui, x, y + 5, "P" .. player_data.user)
    end
end

function OnWorldPreUpdate()
    update_common()
    update_camera()
    update_controls()
    update_gui()
    update_wallet()
end

function OnWorldPostUpdate()
    draw_gui()
end
