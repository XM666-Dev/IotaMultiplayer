--IotaMultiplayer - Created by ImmortalDamned
--Github https://github.com/XM666-Dev/IotaMultiplayer

dofile_once("mods/iota_multiplayer/lib.lua")

ModLuaFileAppend("mods/mnee/bindings.lua", "mods/iota_multiplayer/mnee.lua")
ModLuaFileAppend("data/scripts/biomes/temple_altar.lua", "mods/iota_multiplayer/files/scripts/biomes/temple_altar_appends.lua")
ModLuaFileAppend("data/scripts/perks/perk.lua", "mods/iota_multiplayer/files/scripts/perks/perk_appends.lua")

append_translations("mods/iota_multiplayer/files/translations.csv")

function OnWorldInitialized()
    world_initialized = true
    ModAccessorTable(_G)
end

function OnPlayerSpawned(player)
    player_spawned = true
    primary_player = player
    if has_flag_run_or_add(MOD.player_spawned_once) then
        return
    end
    add_player(player)
    local x, y = EntityGetTransform(player)
    for i = 1, math.round(ModSettingGet(MOD.player_num)) - 1 do
        load_player(x, y)
    end
    perk_spawn_with_data(x, y, {
        ui_name = "$action_autoaim",
        ui_description = "$actiondesc_autoaim",
        perk_icon = "data/ui_gfx/gun_actions/autoaim.png"
    }, "mods/iota_multiplayer/files/scripts/perks/autoaim_pickup.lua")
end

function update_controls()
    local players = get_players()
    for i, player in ipairs(players) do
        local player_data = PlayerData(player)
        local player_x, player_y = EntityGetTransform(player)

        if player_data.controls == nil or player_data.lukki_disable_sprite ~= nil and player_data.lukki_disable_sprite.rect_animation == "intro_stand_up" then
            goto continue
        end
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
        player_data.controls.mButtonDownThrow = throw and not (throw_jpad and player_data:is_inventory_open())
        if player_data:mnin_bind("throw", false, true, false, false, "guied") and player_data.controls.mButtonDownThrow then
            player_data.controls.mButtonFrameThrow = get_frame_num_next()
        end

        local interact, interact_gone, interact_jpad = player_data:mnin_bind("interact")
        player_data.controls.mButtonDownInteract = interact and not (interact_jpad and player_data:is_inventory_open())
        if player_data:mnin_bind("interact", false, true) and player_data.controls.mButtonDownInteract then
            player_data.controls.mButtonFrameInteract = get_frame_num_next()
        end

        local left, left_gone, left_jpad = player_data:mnin_bind("left")
        player_data.controls.mButtonDownLeft = left and not (left_jpad and player_data:is_inventory_open())
        if player_data:mnin_bind("left", false, true) and player_data.controls.mButtonDownLeft then
            player_data.controls.mButtonFrameLeft = get_frame_num_next()
        end

        local right, right_gone, right_jpad = player_data:mnin_bind("right")
        player_data.controls.mButtonDownRight = right and not (right_jpad and player_data:is_inventory_open())
        if player_data:mnin_bind("right", false, true) and player_data.controls.mButtonDownRight then
            player_data.controls.mButtonFrameRight = get_frame_num_next()
        end

        local up, up_gone, up_jpad = player_data:mnin_bind("up")
        player_data.controls.mButtonDownUp = up and not (up_jpad and player_data:is_inventory_open())
        if player_data:mnin_bind("up", false, true) and player_data.controls.mButtonDownUp then
            player_data.controls.mButtonFrameUp = get_frame_num_next()
        end

        local down, down_gone, down_jpad = player_data:mnin_bind("down")
        player_data.controls.mButtonDownDown = down and not (down_jpad and player_data:is_inventory_open())
        if player_data:mnin_bind("down", false, true) and player_data.controls.mButtonDownDown then
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
            gui_enabled_player = player
        end

        player_data.controls.mButtonDownDropItem = player_data:mnin_bind("dropitem") and player_data:is_inventory_open()
        if player_data:mnin_bind("dropitem", false, true) and player_data.controls.mButtonDownDropItem then
            player_data.controls.mButtonFrameDropItem = get_frame_num_next()
        end

        local kick, kick_gone, kick_jpad = player_data:mnin_bind("kick")
        player_data.controls.mButtonDownKick = kick and not (kick_jpad and player_data:is_inventory_open())
        if player_data:mnin_bind("kick", false, true) and player_data.controls.mButtonDownKick then
            player_data.controls.mButtonFrameKick = get_frame_num_next()
        end

        player_data.controls.mButtonDownLeftClick = mnee.mnin_key("mouse_left", false, false, false, "guied") and player == primary_player
        if mnee.mnin_key("mouse_left", false, true, false, "guied") and player_data.controls.mButtonDownLeftClick then
            player_data.controls.mButtonFrameLeftClick = get_frame_num_next()
        end

        player_data.controls.mButtonDownRightClick = mnee.mnin_key("mouse_right", false, false, false, "guied") and player == primary_player
        if mnee.mnin_key("mouse_right", false, true, false, "guied") and player_data.controls.mButtonDownRightClick then
            player_data.controls.mButtonFrameRightClick = get_frame_num_next()
        end

        player_data.controls.mFlyingTargetY = player_y - 10

        local aim, aim_gone, aim_buttoned = player_data:mnin_stick("aim")
        if aim_gone then
            local mouse_position_x, mouse_position_y = DEBUG_GetMouseWorld()
            local aiming_vector_x, aiming_vector_y = mouse_position_x - player_x, mouse_position_y - player_y
            local magnitude = math.max(get_magnitude(aiming_vector_x, aiming_vector_y), 100)
            local aiming_vector_normalized_x, aiming_vector_normalized_y = aiming_vector_x / magnitude, aiming_vector_y / magnitude
            player_data.controls().mAimingVector = { aiming_vector_x, aiming_vector_y }
            player_data.controls().mAimingVectorNormalized = { aiming_vector_normalized_x, aiming_vector_normalized_y }
            local mouse_position_raw_x, mouse_position_raw_y = InputGetMousePosOnScreen()
            local mouse_position_raw_prev = player_data.controls().mMousePositionRaw
            player_data.controls().mMousePosition = { mouse_position_x, mouse_position_y }
            player_data.controls().mMousePositionRaw = { mouse_position_raw_x, mouse_position_raw_y }
            player_data.controls().mMousePositionRawPrev = mouse_position_raw_prev
            player_data.controls().mMouseDelta = { mouse_position_raw_x - mouse_position_raw_prev[1], mouse_position_raw_y - mouse_position_raw_prev[2] }
            goto continue
        end
        if player_data:is_inventory_open() then
            aim = { 0, 0 }
        end
        local function is_pressed(a, b, buttoned)
            return (a ~= b or not buttoned) and b ~= 0
        end
        local aiming_vector = aim
        local aiming_vector_non_zero_latest = player_data.controls().mAimingVectorNonZeroLatest
        local gamepad_aiming_vector_raw = player_data.controls().mGamepadAimingVectorRaw
        if aim[1] == 0 and aim[2] == 0 then
            aiming_vector = aiming_vector_non_zero_latest
        end
        if is_pressed(gamepad_aiming_vector_raw[1], aim[1], aim_buttoned[1]) or is_pressed(gamepad_aiming_vector_raw[2], aim[2], aim_buttoned[2]) then
            aiming_vector_non_zero_latest = aim
        end
        player_data.controls().mAimingVector = { aiming_vector[1] * 100, aiming_vector[2] * 100 }
        player_data.controls().mAimingVectorNormalized = aim
        player_data.controls().mAimingVectorNonZeroLatest = aiming_vector_non_zero_latest
        player_data.controls().mGamepadAimingVectorRaw = aim
        local mouse_position = player_data.controls().mGamePadCursorInWorld
        local mouse_position_raw_x, mouse_position_raw_y = get_pos_on_screen(gui, unpack(mouse_position))
        mouse_position_raw_x, mouse_position_raw_y = mouse_position_raw_x * 2, mouse_position_raw_y * 2
        local mouse_position_raw_prev = player_data.controls().mMousePositionRaw
        player_data.controls().mMousePosition = mouse_position
        player_data.controls().mMousePositionRaw = { mouse_position_raw_x, mouse_position_raw_y }
        player_data.controls().mMousePositionRawPrev = mouse_position_raw_prev
        player_data.controls().mMouseDelta = { mouse_position_raw_x - mouse_position_raw_prev[1], mouse_position_raw_y - mouse_position_raw_prev[2] }
        ::continue::
    end
end

function update_camera()
    local players = get_players()
    if mnee.mnin_bind(get_id(MOD), "switch_player", false, true) or camera_centered_player == nil and player_spawned then
        local entities = camera_centered_player ~= nil and table.filter(players, function(player)
            return PlayerData(player).user > PlayerData(camera_centered_player).user
        end) or {}
        entities = #entities > 0 and entities or players
        camera_centered_player = table.iterate(entities, function(a, b)
            return b == nil or PlayerData(a).user < PlayerData(b).user
        end)
    end
    local primary_player_data = PlayerData(primary_player)
    local camera_centered_player_data = PlayerData(camera_centered_player)
    local previous_camera_centered_player_data = PlayerData(previous_camera_centered_player)
    if camera_centered_player ~= previous_camera_centered_player then
        if camera_centered_player_data.shooter ~= nil and previous_camera_centered_player_data.shooter ~= nil then
            camera_centered_player_data.shooter().mSmoothedCameraPosition = previous_camera_centered_player_data.shooter().mSmoothedCameraPosition
            camera_centered_player_data.shooter().mSmoothedAimingVector = previous_camera_centered_player_data.shooter().mSmoothedAimingVector
            camera_centered_player_data.shooter().mDesiredCameraPos = previous_camera_centered_player_data.shooter().mDesiredCameraPos
        end
        local players_including_disabled = get_players_including_disabled()
        for i, player in ipairs(players_including_disabled) do
            local player_data = PlayerData(player)
            if player_data.listener ~= nil then
                EntitySetComponentIsEnabled(player, get_id(player_data.listener), player == camera_centered_player)
            end
        end
        previous_camera_centered_player = camera_centered_player
    end
    if primary_player_data.shooter ~= nil and camera_centered_player_data.shooter ~= nil then
        primary_player_data.shooter().mDesiredCameraPos = camera_centered_player_data.shooter().mDesiredCameraPos
    end
end

function update_gui()
    local gui_enabled_player_data = PlayerData(gui_enabled_player)
    if gui_enabled_player == nil or gui_enabled_player_data.controls.mButtonFrameInventory == get_frame_num_next() == gui_enabled_player_data:is_inventory_open() then
        gui_enabled_player = camera_centered_player
    end
    if gui_enabled_player ~= previous_gui_enabled_player then
        gui_enabled_player_data = PlayerData(gui_enabled_player)
        local previous_gui_enabled_player_data = PlayerData(previous_gui_enabled_player)
        if gui_enabled_player_data.gui ~= nil and previous_gui_enabled_player_data.gui ~= nil then
            gui_enabled_player_data.gui.wallet_money_target = previous_gui_enabled_player_data.gui.wallet_money_target
        end
        if previous_gui_enabled_player_data.gui ~= nil then
            EntityRemoveComponent(previous_gui_enabled_player, get_id(previous_gui_enabled_player_data.gui))
            EntityAddComponent2(previous_gui_enabled_player, "InventoryGuiComponent")
        end
        previous_gui_enabled_player = gui_enabled_player
    end
    local players = get_players_including_disabled()
    for i, player in ipairs(players) do
        local player_data = PlayerData(player)
        if player_data.gui ~= nil then
            EntitySetComponentIsEnabled(player, get_id(player_data.gui), player == gui_enabled_player)
        end
    end
end

function update_gui_post()
    local players = get_players_including_disabled()
    for i, player in ipairs(players) do
        local player_data = PlayerData(player)
        if player_data.gui ~= nil then
            EntitySetComponentIsEnabled(player, get_id(player_data.gui), true)
        end
    end
end

function update_common()
    local players = get_players()
    local players_including_disabled = get_players_including_disabled()
    if mnee.mnin_bind(get_id(MOD), "toggle_teleport", false, true) then
        for i, player in ipairs(players) do
            if player ~= camera_centered_player then
                local from_x, from_y = EntityGetTransform(player)
                local to_x, to_y = EntityGetTransform(camera_centered_player)
                teleport(player, from_x, from_y, to_x, to_y)
            end
        end
    end
    if ModSettingGet(MOD.share_money) then
        local gui_enabled_player_data = PlayerData(gui_enabled_player)
        for i, player in ipairs(players) do
            local player_data = PlayerData(player)
            if player_data.wallet ~= nil and player ~= gui_enabled_player then
                gui_enabled_player_data.wallet.money = gui_enabled_player_data.wallet.money + player_data.wallet.money - player_data.previous_money
            end
        end
        for i, player in ipairs(players) do
            local player_data = PlayerData(player)
            if player_data.wallet ~= nil then
                player_data.wallet.money = gui_enabled_player_data.wallet.money
                player_data.previous_money = player_data.wallet.money
            end
        end
    end
    for i, player in ipairs(players) do
        local player_data = PlayerData(player)
        player_data.pick_upper.is_immune_to_kicks = not ModSettingGet(MOD.friendly_fire_kick_drop)
        player_data.damage_model.wait_for_kill_flag_on_death = max_user > 1
        if player_data.damage_model.hp < 0 then
            set_dead(player, true)
        end
    end
    for i, player in ipairs(players_including_disabled) do
        local player_data = PlayerData(player)
        if player_data.dead then
            GamePlayAnimation(player, "intro_sleep", 2)
        end
        local arm_r = player_data:get_arm_r()
        if arm_r ~= nil and player_data.lukki_disable_sprite ~= nil then
            local stand = player_data.lukki_disable_sprite.rect_animation ~= "intro_sleep" and player_data.lukki_disable_sprite.rect_animation ~= "intro_stand_up"
            EntitySetName(arm_r, stand and "arm_r" or "")
            EntitySetComponentsWithTagEnabled(arm_r, "with_item", stand)
        end
    end
    if give_up then
        for i, player in ipairs(players_including_disabled) do
            local player_data = PlayerData(player)
            EntitySetComponentIsEnabled(player, get_id(player_data.damage_model), true)
            player_data.damage_model.wait_for_kill_flag_on_death = false
            player_data.damage_model.hp = 0
            EntityInflictDamage(player, 0.04, "DAMAGE_CURSE", player_data.last_damage_message, "NONE", 0, 0, player_data.last_damage_entity_thats_responsible)
            EntityKill(player)
        end
    end
end

gui = GuiCreate()

function draw_gui()
    if not world_initialized or max_user < 2 then
        return
    end
    GuiStartFrame(gui)
    GuiOptionsAdd(gui, GUI_OPTION.Align_HorizontalCenter)
    local players = get_players()
    local players_including_disabled = get_players_including_disabled()
    if gui_enabled_player ~= nil then
        GuiText(gui, 10, 25, "P" .. PlayerData(gui_enabled_player).user)
    end
    for i, player in ipairs(players) do
        local player_x, player_y = EntityGetTransform(player)
        local x, y = get_pos_on_screen(gui, player_x, player_y)
        GuiText(gui, x, y + 5, "P" .. PlayerData(player).user)
    end
    if #players < 1 and #players_including_disabled > 0 then
        local screen_w, screen_h = GuiGetScreenDimensions(gui)
        local clicked = GuiButton(gui, new_id("give_up"), screen_w / 2, screen_h / 2, "$iota_multiplayer.menugiveup")
        if clicked then
            give_up = true
        end
    end
end

function OnWorldPreUpdate()
    update_controls()
    update_camera()
    update_gui()
    update_common()
end

function OnWorldPostUpdate()
    update_gui_post()
    draw_gui()
end
