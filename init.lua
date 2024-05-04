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
    if get_binding_pressed(get_id(MULTIPLAYER), "switch_player") or player_spawned and not camera_centered_player then
        local entities = camera_centered_player and table.filter(players, function(player)
            return PlayerData(player).user > PlayerData(camera_centered_player).user
        end) or {}
        entities = #entities > 0 and entities or players
        camera_centered_player = table.iterate(entities, function(a, b)
            return not b or PlayerData(a).user < PlayerData(b).user
        end)
    end
    if get_binding_pressed(get_id(MULTIPLAYER), "toggle_teleport") then
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
        local frame = GameGetFrameNum() + 1

        player_data.controls.enabled = false

        player_data.controls.mButtonDownFire = player_data:is_binding_down("usewand", false, false, false, false, false, "guied")
        if player_data:is_binding_down("usewand", false, true, false, false, false, "guied") then
            player_data.controls.mButtonFrameFire = frame
        end
        if player_data.controls.mButtonDownFire then
            player_data.controls.mButtonLastFrameFire = frame
        end

        player_data.controls.mButtonDownFire2 = player_data:is_binding_down("sprayflask")
        if player_data:get_binding_pressed("sprayflask") then
            player_data.controls.mButtonFrameFire2 = frame
        end

        player_data.controls.mButtonDownThrow = player_data:is_binding_down("throw")
        if player_data:get_binding_pressed("throw") then
            player_data.controls.mButtonFrameThrow = frame
        end

        player_data.controls.mButtonDownInteract = player_data:is_binding_down("interact")
        if player_data:get_binding_pressed("interact") then
            player_data.controls.mButtonFrameInteract = frame
        end

        player_data.controls.mButtonDownLeft = player_data:is_binding_down("left")
        if player_data:get_binding_pressed("left") then
            player_data.controls.mButtonFrameLeft = frame
        end

        player_data.controls.mButtonDownRight = player_data:is_binding_down("right")
        if player_data:get_binding_pressed("right") then
            player_data.controls.mButtonFrameRight = frame
        end

        player_data.controls.mButtonDownUp = player_data:is_binding_down("up")
        if player_data:get_binding_pressed("up") then
            player_data.controls.mButtonFrameUp = frame
        end

        player_data.controls.mButtonDownDown = player_data:is_binding_down("down")
        if player_data:get_binding_pressed("down") then
            player_data.controls.mButtonFrameDown = frame
        end

        player_data.controls.mButtonDownFly = player_data:is_binding_down("up")
        if player_data:get_binding_pressed("up") then
            player_data.controls.mButtonFrameFly = frame
        end

        player_data.controls.mButtonDownChangeItemR = player_data:is_binding_down("itemnext")
        if player_data:get_binding_pressed("itemnext") then
            player_data.controls.mButtonFrameChangeItemR = frame
            player_data.controls.mButtonCountChangeItemR = 1
        else
            player_data.controls.mButtonCountChangeItemR = 0
        end

        player_data.controls.mButtonDownChangeItemL = player_data:is_binding_down("itemprev")
        if player_data:get_binding_pressed("itemprev") then
            player_data.controls.mButtonFrameChangeItemL = frame
            player_data.controls.mButtonCountChangeItemL = 1
        else
            player_data.controls.mButtonCountChangeItemL = 0
        end

        player_data.controls.mButtonDownInventory = player_data:is_binding_down("inventory")
        if player_data:get_binding_pressed("inventory") then
            player_data.controls.mButtonFrameInventory = frame
            if gui_enabled_player ~= player then
                gui_enabled_player = player
            end
        end

        player_data.controls.mButtonDownKick = player_data:is_binding_down("kick")
        if player_data:get_binding_pressed("kick") then
            player_data.controls.mButtonFrameKick = frame
        end

        player_data.controls.mFlyingTargetY = player_y - 10

        local vector_x, is_unbound_x, is_buttoned_x = player_data:get_axis_state("aimh")
        local vector_y, is_unbound_y, is_buttoned_y = player_data:get_axis_state("aimv")
        if is_unbound_x and is_unbound_y then
            local mouse_x, mouse_y = DEBUG_GetMouseWorld()
            local aiming_vector_x, aiming_vector_y = mouse_x - player_x, mouse_y - player_y
            player_data.controls("mAimingVector").set(aiming_vector_x, aiming_vector_y)                          --controls usewand
            player_data.controls("mAimingVectorNormalized").set(vec_normalize(aiming_vector_x, aiming_vector_y)) --controls throw
            local mouse_position_raw_x, mouse_position_raw_y = InputGetMousePosOnScreen()
            local mouse_position_raw_prev_x, mouse_position_raw_prev_y = player_data.controls("mMousePositionRaw").get()
            player_data.controls("mMousePosition").set(mouse_x, mouse_y)                              --controls look
            player_data.controls("mMousePositionRaw").set(mouse_position_raw_x, mouse_position_raw_y) --controls camera
            player_data.controls("mMousePositionRawPrev").set(mouse_position_raw_prev_x, mouse_position_raw_prev_y)
            player_data.controls("mMouseDelta").set(mouse_position_raw_x - mouse_position_raw_prev_x, mouse_position_raw_y - mouse_position_raw_prev_y)
            goto continue
        end
        local function pressed(a, b, is_buttoned)
            return (not is_buttoned or a ~= b) and b ~= 0
        end
        local aiming_vector_x, aiming_vector_y = vector_x, vector_y
        local aiming_vector_non_zero_latest_x, aiming_vector_non_zero_latest_y = player_data.controls("mAimingVectorNonZeroLatest").get()
        local gamepad_aiming_vector_raw_x, gamepad_aiming_vector_raw_y = player_data.controls("mGamepadAimingVectorRaw").get()
        if vector_x == 0 and vector_y == 0 then
            aiming_vector_x, aiming_vector_y = aiming_vector_non_zero_latest_x, aiming_vector_non_zero_latest_y
        end
        if pressed(gamepad_aiming_vector_raw_x, vector_x, is_buttoned_x) or pressed(gamepad_aiming_vector_raw_y, vector_y, is_buttoned_y) then
            aiming_vector_non_zero_latest_x, aiming_vector_non_zero_latest_y = vector_x, vector_y
        end
        player_data.controls("mAimingVector").set(aiming_vector_x * 100, aiming_vector_y * 100)
        player_data.controls("mAimingVectorNormalized").set(vector_x, vector_y)
        player_data.controls("mAimingVectorNonZeroLatest").set(aiming_vector_non_zero_latest_x, aiming_vector_non_zero_latest_y)
        player_data.controls("mGamepadAimingVectorRaw").set(vector_x, vector_y)
        local cursor_x, cursor_y = player_data.controls("mGamePadCursorInWorld").get()
        local camera_x, camera_y = get_camera_top_left()
        local zoom_x, zoom_y = get_camera_zoom(gui)
        local mouse_position_raw_x, mouse_position_raw_y = (cursor_x - camera_x) * zoom_x * 2, (cursor_y - camera_y) * zoom_y * 2
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
        EntitySetComponentIsEnabled(player, get_id(player_data.listener), player == camera_centered_player)
    end
end

function update_gui()
    local gui_enabled_player_data = PlayerData(gui_enabled_player)
    if not gui_enabled_player or gui_enabled_player_data.gui.mActive == (gui_enabled_player_data.controls.mButtonFrameInventory == GameGetFrameNum() + 1) then
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
    local camera_x, camera_y = get_camera_top_left()
    local zoom_x, zoom_y = get_camera_zoom(gui)
    local players = get_players()
    for _, player in ipairs(players) do
        local player_data = PlayerData(player)
        local player_x, player_y = EntityGetTransform(player)
        local x, y = (player_x - camera_x) * zoom_x, (player_y - camera_y) * zoom_y
        GuiText(gui, x, y + 5, "P" .. player_data.user)
    end
end

function OnWorldPreUpdate()
    update_common()
    update_camera()
    update_controls()
    update_gui()
    update_wallet()
    draw_gui()
end
