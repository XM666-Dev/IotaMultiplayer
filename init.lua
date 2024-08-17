--IotaMultiplayer - Created by ImmortalDamned
--Github https://github.com/XM666-Dev/IotaMultiplayer

dofile_once("mods/iota_multiplayer/lib.lua")
--dofile_once("mods/iota_multiplayer/NoitaPatcher/load.lua")

ModLuaFileAppend("mods/mnee/bindings.lua", "mods/iota_multiplayer/mnee.lua")
ModLuaFileAppend("data/scripts/biomes/mountain/mountain_left_entrance.lua", "mods/iota_multiplayer/files/scripts/biomes/mountain/mountain_left_entrance_appends.lua")
ModLuaFileAppend("data/scripts/biomes/temple_altar.lua", "mods/iota_multiplayer/files/scripts/biomes/temple_altar_appends.lua")
ModLuaFileAppend("data/scripts/perks/perk.lua", "mods/iota_multiplayer/files/scripts/perks/perk_appends.lua")

append_translations("mods/iota_multiplayer/files/translations.csv")

local gui = GuiCreate()

if GameGetWorldStateEntity() == 0 then
    ModSettingSet("iota_multiplayer.camera_zoom", ModSettingGetNextValue("iota_multiplayer.camera_zoom") or 1)
end
local zoom = ModSettingGet("iota_multiplayer.camera_zoom")
if zoom ~= 1 then
    local content = ModTextFileGetContent("mods/iota_multiplayer/files/magic_numbers.xml")
    ModTextFileSetContent("mods/iota_multiplayer/files/magic_numbers.xml", content:asub(function(k, v)
        if k == "VIRTUAL_RESOLUTION_X" then
            return ('%s="%f"'):format(k, tonumber(v) * zoom)
        elseif k == "VIRTUAL_RESOLUTION_Y" then
            return ('%s="%f"'):format(k, tonumber(v) * zoom)
        end
    end))
    ModMagicNumbersFileAdd("mods/iota_multiplayer/files/magic_numbers.xml")
    local offset = (zoom - 1) * 2.75 / 64.0 --map(zoom, 1, 2, 0, 2.75 / 64.0)
    local flag = true
    content = ModTextFileGetContent("data/shaders/post_final.frag"):gsub("tex_coord_fogofwar", function()
        local result
        if flag then
            result = "tex_coord_fogofwar"
            flag = false
        else
            result = ("vec2(tex_coord_fogofwar.x, tex_coord_fogofwar.y + %f)"):format(offset)
        end
        return result
    end)
    ModTextFileSetContent("data/shaders/post_final.frag", content)
end

function OnWorldInitialized()
    world_initialized = true
    for i, pos in ipairs(mod.player_positions) do
        EntityKill(EntityLoad("mods/iota_multiplayer/files/entities/buildings/keep_alive.xml", unpack(pos)))
    end
end

function OnPlayerSpawned(player)
    player_spawned = true
    mod.primary_player = player
    if has_flag_run_or_add("iota_multiplayer.player_spawned_once") then
        return
    end
    add_player(player)
    EntityAddComponent2(mod.id, "LuaComponent", {
        script_source_file = "mods/iota_multiplayer/files/scripts/magic/player_polymorph.lua",
    })
end

local function is_pressed(a, b, emulated)
    return (a ~= b or not emulated) and b ~= 0
end
local function update_controls()
    local players = get_players_including_disabled()
    for i, player in ipairs(players) do
        local player_data = Player(player)
        local player_x, player_y = EntityGetTransform(player)

        if player_data.controls == nil then
            goto continue
        end

        player_data.controls.enabled = false

        if player_data.dead or player_data.sprite ~= nil and player_data.sprite.rect_animation == "intro_stand_up" then
            goto continue
        end

        player_data.controls.mButtonDownFire = player_data:mnin_bind("usewand", true, false, false, false, "guied")
        if player_data:mnin_bind("usewand", true, true, false, false, "guied") then
            player_data.controls.mButtonFrameFire = get_frame_num_next()
        end
        if player_data.controls.mButtonDownFire then
            player_data.controls.mButtonLastFrameFire = get_frame_num_next()
        end
        if player_data.controls.polymorph_hax and player_data.controls.polymorph_next_attack_frame <= get_frame_num_next() and player_data.controls.mButtonFrameFire == get_frame_num_next() then
            entity_shoot(player)
            local ai = EntityGetFirstComponentIncludingDisabled(player, "AnimalAIComponent")
            local attacks = EntityGetComponent(player, "AIAttackComponent") or {}
            local attack_table = get_attack_table(ai, attacks[#attacks])
            player_data.controls.polymorph_next_attack_frame = get_frame_num_next() + attack_table.frames_between
        end

        player_data.controls.mButtonDownFire2 = player_data:mnin_bind("sprayflask", true, false, false, false, "guied")
        if player_data:mnin_bind("sprayflask", true, true, false, false, "guied") then
            player_data.controls.mButtonFrameFire2 = get_frame_num_next()
        end

        local throw, throw_unbound, throw_jpad = player_data:mnin_bind("throw", true, false, false, false, "guied")
        player_data.controls.mButtonDownThrow = throw and not (throw_jpad and player_data:is_inventory_open())
        if player_data:mnin_bind("throw", true, true, false, false, "guied") and player_data.controls.mButtonDownThrow then
            player_data.controls.mButtonFrameThrow = get_frame_num_next()
        end

        local interact, interact_unbound, interact_jpad = player_data:mnin_bind("interact", true)
        player_data.controls.mButtonDownInteract = interact and not (interact_jpad and player_data:is_inventory_open())
        if player_data:mnin_bind("interact", true, true) and player_data.controls.mButtonDownInteract then
            player_data.controls.mButtonFrameInteract = get_frame_num_next()
        end

        local left, left_unbound, left_jpad = player_data:mnin_bind("left", true)
        player_data.controls.mButtonDownLeft = left and not (left_jpad and player_data:is_inventory_open())
        if player_data:mnin_bind("left", true, true) and player_data.controls.mButtonDownLeft then
            player_data.controls.mButtonFrameLeft = get_frame_num_next()
        end

        local right, right_unbound, right_jpad = player_data:mnin_bind("right", true)
        player_data.controls.mButtonDownRight = right and not (right_jpad and player_data:is_inventory_open())
        if player_data:mnin_bind("right", true, true) and player_data.controls.mButtonDownRight then
            player_data.controls.mButtonFrameRight = get_frame_num_next()
        end

        local up, up_unbound, up_jpad = player_data:mnin_bind("up", true)
        player_data.controls.mButtonDownUp = up and not (up_jpad and player_data:is_inventory_open())
        if player_data:mnin_bind("up", true, true) and player_data.controls.mButtonDownUp then
            player_data.controls.mButtonFrameUp = get_frame_num_next()
        end

        local down, down_unbound, down_jpad = player_data:mnin_bind("down", true)
        player_data.controls.mButtonDownDown = down and not (down_jpad and player_data:is_inventory_open())
        if player_data:mnin_bind("down", true, true) and player_data.controls.mButtonDownDown then
            player_data.controls.mButtonFrameDown = get_frame_num_next()
        end

        player_data.controls.mButtonDownFly = player_data:mnin_bind("up", true)
        if player_data:mnin_bind("up", true, true) then
            player_data.controls.mButtonFrameFly = get_frame_num_next()
        end

        player_data.controls.mButtonDownChangeItemR = player_data:mnin_bind("itemnext", true)
        if player_data:mnin_bind("itemnext", true, true) then
            player_data.controls.mButtonFrameChangeItemR = get_frame_num_next()
            player_data.controls.mButtonCountChangeItemR = 1
        else
            player_data.controls.mButtonCountChangeItemR = 0
        end

        player_data.controls.mButtonDownChangeItemL = player_data:mnin_bind("itemprev", true)
        if player_data:mnin_bind("itemprev", true, true) then
            player_data.controls.mButtonFrameChangeItemL = get_frame_num_next()
            player_data.controls.mButtonCountChangeItemL = 1
        else
            player_data.controls.mButtonCountChangeItemL = 0
        end

        player_data.controls.mButtonDownInventory = player_data:mnin_bind("inventory", true)
        if player_data:mnin_bind("inventory", true, true) then
            player_data.controls.mButtonFrameInventory = get_frame_num_next()
            mod.gui_enabled_player = player
        end

        player_data.controls.mButtonDownDropItem = player_data:mnin_bind("dropitem", true) and player_data:is_inventory_open()
        if player_data:mnin_bind("dropitem", true, true) and player_data.controls.mButtonDownDropItem then
            player_data.controls.mButtonFrameDropItem = get_frame_num_next()
        end

        local kick, kick_unbound, kick_jpad = player_data:mnin_bind("kick", true)
        player_data.controls.mButtonDownKick = kick and not (kick_jpad and player_data:is_inventory_open())
        if player_data:mnin_bind("kick", true, true) and player_data.controls.mButtonDownKick then
            player_data.controls.mButtonFrameKick = get_frame_num_next()
        end

        player_data.controls.mButtonDownLeftClick = mnee.mnin_key("mouse_left", false, false, "guied") and player == mod.primary_player
        if mnee.mnin_key("mouse_left", true, false, "guied") and player_data.controls.mButtonDownLeftClick then
            player_data.controls.mButtonFrameLeftClick = get_frame_num_next()
        end

        player_data.controls.mButtonDownRightClick = mnee.mnin_key("mouse_right", false, false, "guied") and player == mod.primary_player
        if mnee.mnin_key("mouse_right", true, false, "guied") and player_data.controls.mButtonDownRightClick then
            player_data.controls.mButtonFrameRightClick = get_frame_num_next()
        end

        player_data.controls.mFlyingTargetY = player_y - 10

        local aim, aim_unbound, aim_emulated = player_data:mnin_stick("aim")
        local CONTROLS_AIMING_VECTOR_FULL_LENGTH_PIXELS = tonumber(MagicNumbersGetValue("CONTROLS_AIMING_VECTOR_FULL_LENGTH_PIXELS"))
        if aim_unbound then
            local mouse_position_x, mouse_position_y = DEBUG_GetMouseWorld()
            local center_x, center_y = EntityGetFirstHitboxCenter(player)
            local aiming_vector_x, aiming_vector_y = mouse_position_x - center_x, mouse_position_y - center_y
            local magnitude = math.max(math.sqrt(aiming_vector_x * aiming_vector_x + aiming_vector_y * aiming_vector_y), CONTROLS_AIMING_VECTOR_FULL_LENGTH_PIXELS)
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
        local aiming_vector_non_zero_latest = player_data.controls().mAimingVectorNonZeroLatest
        local function mnin_stick_raw(mod_id, bind_id, pressed_mode, is_vip, inmode)
            local abort_tbl = { { 0, 0 }, false, { false, false }, 0 }
            if (GameHasFlagRun(mnee.SERV_MODE) and not (mnee.ignore_service_mode)) then return unpack(abort_tbl) end
            if (GameHasFlagRun(mnee.TOGGLER) and not (is_vip)) then return unpack(abort_tbl) end
            if (not (mnee.is_priority_mod(mod_id))) then return unpack(abort_tbl) end

            local binding = mnee.get_bindings()
            if (binding ~= nil) then binding = binding[mod_id] end
            if (binding ~= nil) then binding = binding[bind_id] end
            if (not (pen.vld(binding))) then return unpack(abort_tbl) end

            local acc = 100
            local val_x, gone_x, buttoned_x = mnee.mnin_axis(mod_id, binding.axes[1], true, pressed_mode, is_vip, inmode)
            local val_y, gone_y, buttoned_y = mnee.mnin_axis(mod_id, binding.axes[2], true, pressed_mode, is_vip, inmode)
            local direction = math.rad(math.floor(math.deg(math.atan2(val_y, val_x)) + 0.5))
            val_x, val_y = pen.rounder(mnee.apply_deadzone(math.min(val_x, 1), binding.jpad_type, binding.deadzone), acc), pen.rounder(mnee.apply_deadzone(math.min(val_y, 1), binding.jpad_type, binding.deadzone), acc)
            return { math.min(val_x, 1), math.min(val_y, 1) }, gone_x or gone_y, { buttoned_x, buttoned_y }, direction
        end
        local aim_raw = mnin_stick_raw("iota_multiplayer" .. player_data.index, "aim")
        if is_pressed(tonumber(player_data.previous_aim_x), aim_raw[1], aim_emulated[1]) or is_pressed(tonumber(player_data.previous_aim_y), aim_raw[2], aim_emulated[2]) then
            aiming_vector_non_zero_latest = aim
        end
        player_data.previous_aim_x = ("%.16a"):format(aim_raw[1])
        player_data.previous_aim_y = ("%.16a"):format(aim_raw[2])
        player_data.controls().mAimingVector = { aiming_vector_non_zero_latest[1] * CONTROLS_AIMING_VECTOR_FULL_LENGTH_PIXELS, aiming_vector_non_zero_latest[2] * CONTROLS_AIMING_VECTOR_FULL_LENGTH_PIXELS }
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

local function update_gui()
    local gui_enabled_player_data = Player(mod.gui_enabled_player)
    if mod.gui_enabled_player == nil or gui_enabled_player_data.controls ~= nil and gui_enabled_player_data.controls.mButtonFrameInventory == get_frame_num_next() == gui_enabled_player_data:is_inventory_open() then
        mod.gui_enabled_player = mod.camera_centered_player
    end
    if mod.gui_enabled_player ~= mod.previous_gui_enabled_player then
        gui_enabled_player_data = Player(mod.gui_enabled_player)
        local previous_gui_enabled_player_data = Player(mod.previous_gui_enabled_player)
        if gui_enabled_player_data.gui ~= nil and previous_gui_enabled_player_data.gui ~= nil then
            gui_enabled_player_data.gui.wallet_money_target = previous_gui_enabled_player_data.gui.wallet_money_target
        end
        if previous_gui_enabled_player_data.gui ~= nil then
            EntityRemoveComponent(mod.previous_gui_enabled_player, previous_gui_enabled_player_data.gui._id)
            EntityAddComponent2(mod.previous_gui_enabled_player, "InventoryGuiComponent")
        end
        mod.previous_gui_enabled_player = mod.gui_enabled_player
    end
    local players = get_players_including_disabled()
    for i, player in ipairs(players) do
        local player_data = Player(player)
        if player_data.gui ~= nil then
            set_component_enabled(player_data.gui._id, player == mod.gui_enabled_player)
        end
    end
end

local function update_gui_post()
    local players = get_players_including_disabled()
    for i, player in ipairs(players) do
        local player_data = Player(player)
        if player_data.gui ~= nil then
            set_component_enabled(player_data.gui._id, true)
        end
    end
end

local function add_script_item_throw(item)
    if EntityGetFirstComponentIncludingDisabled(item, "LuaComponent", "iota_multiplayer.item_throw") == nil then
        EntityAddComponent2(item, "LuaComponent", {
            _tags = "enabled_in_world,enabled_in_hand,enabled_in_inventory,iota_multiplayer.item_throw",
            script_source_file = "mods/iota_multiplayer/files/scripts/items/item_throw.lua",
            script_throw_item = "mods/iota_multiplayer/files/scripts/items/item_throw.lua",
        })
    end
    local children = get_children(item)
    for i, child in ipairs(children) do
        add_script_item_throw(child)
    end
end
local function update_common()
    local players = get_players()
    local players_including_disabled = get_players_including_disabled()
    if mnee.mnin_bind("iota_multiplayer", "toggle_teleport", true, true) then
        for i, player in ipairs(players) do
            if player ~= mod.camera_centered_player then
                local from_x, from_y = EntityGetTransform(player)
                local to_x, to_y = EntityGetTransform(mod.camera_centered_player)
                teleport(player, from_x, from_y, to_x, to_y)
            end
        end
    end
    if ModSettingGet("iota_multiplayer.share_money") then
        local gui_enabled_player_data = Player(mod.gui_enabled_player)
        for i, player in ipairs(players) do
            local player_data = Player(player)
            if player_data.wallet ~= nil and gui_enabled_player_data.wallet ~= nil and player ~= mod.gui_enabled_player then
                gui_enabled_player_data.wallet.money = gui_enabled_player_data.wallet.money + player_data.wallet.money - player_data.previous_money
            end
        end
        for i, player in ipairs(players) do
            local player_data = Player(player)
            if player_data.wallet ~= nil and gui_enabled_player_data.wallet ~= nil then
                player_data.wallet.money = gui_enabled_player_data.wallet.money
                player_data.previous_money = player_data.wallet.money
            end
        end
    end
    for i, player in ipairs(players) do
        local player_data = Player(player)
        if player_data.pick_upper ~= nil then
            player_data.pick_upper.is_immune_to_kicks = not ModSettingGet("iota_multiplayer.friendly_fire_kick_drop")
        end
        local items = GameGetAllInventoryItems(player) or {}
        for i, item in ipairs(items) do
            add_script_item_throw(item)
        end
        if player_data.damage_model ~= nil then
            player_data.damage_model.wait_for_kill_flag_on_death = mod.max_index > 1
            if player_data.damage_model.hp < 0 then
                set_dead(player, true)
            end
        end
    end
    for i, player in ipairs(players_including_disabled) do
        local player_data = Player(player)
        if player_data.dead then
            GamePlayAnimation(player, "intro_sleep", 2)
        end
        local arm_r = player_data:get_arm_r()
        if arm_r ~= nil and player_data.sprite ~= nil then
            local stand = player_data.sprite.rect_animation ~= "intro_sleep" and player_data.sprite.rect_animation ~= "intro_stand_up"
            EntitySetName(arm_r, stand and "arm_r" or "")
            EntitySetComponentsWithTagEnabled(arm_r, "with_item", stand)
        end
        if player_data.aiming_reticle ~= nil then
            local aim, aim_unbound, aim_emulated = player_data:mnin_stick("aim")
            player_data.aiming_reticle.visible = not aim_unbound
        end
    end
    if give_up then
        local damaged_players = table.copy(players_including_disabled)
        table.sort(damaged_players, function(a, b)
            return Player(a).damage_frame < Player(b).damage_frame
        end)
        for i, player in ipairs(damaged_players) do
            local player_data = Player(player)
            set_component_enabled(player_data.damage_model._id, true)
            player_data.damage_model.wait_for_kill_flag_on_death = false
            player_data.damage_model.hp = 0
            EntityInflictDamage(player, 0.04, "DAMAGE_CURSE", player_data.damage_message, "NONE", 0, 0, player_data.damage_entity_thats_responsible)
            EntityKill(player)
        end
    end
    if world_initialized then
        local player_positions = {}
        for i, player in ipairs(players_including_disabled) do
            local x, y = EntityGetTransform(player)
            player_positions[i] = { x, y }
        end
        mod.player_positions = player_positions
    end
end

local function update_camera()
    local players = get_players()
    local camera_centered_player_data = Player(mod.camera_centered_player)
    if mnee.mnin_bind("iota_multiplayer", "switch_player", true, true) or mod.camera_centered_player == nil and player_spawned then
        local entities = mod.camera_centered_player ~= nil and table.filter(players, function(player)
            return Player(player).index > camera_centered_player_data.index
        end) or {}
        entities = #entities > 0 and entities or players
        mod.camera_centered_player = table.iterate(entities, function(a, b)
            return b == nil or Player(a).index < Player(b).index
        end)
    end
    if mod.camera_centered_player ~= mod.previous_camera_centered_player then
        camera_centered_player_data = Player(mod.camera_centered_player)
        local previous_camera_centered_player_data = Player(mod.previous_camera_centered_player)
        if camera_centered_player_data.shooter ~= nil and previous_camera_centered_player_data.shooter ~= nil then
            camera_centered_player_data.shooter().mSmoothedCameraPosition = previous_camera_centered_player_data.shooter().mSmoothedCameraPosition
            camera_centered_player_data.shooter().mSmoothedAimingVector = previous_camera_centered_player_data.shooter().mSmoothedAimingVector
            camera_centered_player_data.shooter().mDesiredCameraPos = previous_camera_centered_player_data.shooter().mDesiredCameraPos
        end
        mod.previous_camera_centered_player = mod.camera_centered_player
    end
    local primary_player_data = Player(mod.primary_player)
    if primary_player_data.shooter ~= nil then
        GameSetCameraFree(false)
        primary_player_data.shooter().mDesiredCameraPos = camera_centered_player_data.shooter ~= nil and camera_centered_player_data.shooter().mDesiredCameraPos or { EntityGetTransform(mod.camera_centered_player) }
    elseif mod.camera_centered_player ~= nil then
        GameSetCameraFree(true)
        local pos = camera_centered_player_data.shooter ~= nil and camera_centered_player_data.shooter().mDesiredCameraPos or { EntityGetTransform(mod.camera_centered_player) }
        GameSetCameraPos(unpack(pos))
    end
    local players_including_disabled = get_players_including_disabled()
    for i, player in ipairs(players_including_disabled) do
        local player_data = Player(player)
        if player_data.listener ~= nil then
            set_component_enabled(player_data.listener._id, player == mod.camera_centered_player)
        end
    end
end

local function gui_image_nine_piece(gui, id, x, y, to_x, to_y, ...)
    GuiImageNinePiece(gui, id, x, y, to_x - x, to_y - y, ...)
end
local function update_gui_mod()
    if not world_initialized or mod.max_index < 2 then
        return
    end
    GuiStartFrame(gui)
    local gui_enabled_player_data = Player(mod.gui_enabled_player)
    if mod.gui_enabled_player ~= nil then
        GuiOptionsAddForNextWidget(gui, GUI_OPTION.Align_HorizontalCenter)
        GuiText(gui, 10, 25, "P" .. gui_enabled_player_data.index)
    end
    local players = get_players()
    for i, player in ipairs(players) do
        local player_data = Player(player)

        local player_x, player_y = EntityGetTransform(player)
        local x, y = get_pos_on_screen(gui, player_x, player_y)
        GuiOptionsAddForNextWidget(gui, GUI_OPTION.Align_HorizontalCenter)
        GuiColorSetForNextWidget(gui, 1, 1, 1, gui_enabled_player_data.gui ~= nil and 1 - gui_enabled_player_data.gui.mBackgroundOverlayAlpha * 2 or 1)
        GuiText(gui, x, y + 5, "P" .. player_data.index)

        local from_x, from_y = x + 7.5, y + 7.5
        local to_x, to_y = from_x + 5, from_y + 5
        local z = 127
        GuiZSetForNextWidget(gui, z)
        z = z - 1
        gui_image_nine_piece(gui, new_id("bar_bg" .. i), from_x, from_y, to_x, to_y, 1, "data/ui_gfx/hud/colors_bar_bg.png")

        if player_data.damage_model ~= nil then
            local from_x, from_y = from_x + 1, from_y + 1
            local to_x, to_y = to_x - 1, to_y - 1
            to_x = lerp_clamped(from_x, to_x, player_data.damage_model.hp / player_data.damage_model.max_hp)
            GuiZSetForNextWidget(gui, z)
            z = z - 1
            gui_image_nine_piece(gui, new_id("health_bar" .. i), from_x, from_y, to_x, to_y, 1, "data/ui_gfx/hud/colors_health_bar.png")
        end

        if player_data.character_data ~= nil and player_data.character_data.mFlyingTimeLeft < player_data.character_data.fly_time_max then
            local from_x, from_y = from_x + 1, from_y + 1
            local to_x, to_y = to_x - 1, to_y - 1
            to_y = lerp_clamped(to_y, from_y, player_data.character_data.mFlyingTimeLeft / player_data.character_data.fly_time_max)
            GuiZSetForNextWidget(gui, z)
            z = z - 1
            gui_image_nine_piece(gui, new_id("flying_bar" .. i), from_x, from_y, to_x, to_y, 1, "data/ui_gfx/hud/colors_flying_bar.png")
        end
    end
    local players_including_disabled = get_players_including_disabled()
    if #players < 1 and #players_including_disabled > 0 then
        local screen_w, screen_h = GuiGetScreenDimensions(gui)
        GuiOptionsAddForNextWidget(gui, GUI_OPTION.Align_HorizontalCenter)
        GuiOptionsAddForNextWidget(gui, GUI_OPTION.GamepadDefaultWidget)
        local clicked = GuiButton(gui, new_id("button_give_up"), screen_w / 2, screen_h / 2, "$iota_multiplayer.menugiveup")
        if clicked then
            give_up = true
        end
    end
end

function OnWorldPreUpdate()
    update_controls()
    update_gui()
    update_common()
end

function OnWorldPostUpdate()
    update_gui_post()
    update_camera()
    update_gui_mod()
end
