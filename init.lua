--IotaMultiplayer - Created by ImmortalDamned
--Github https://github.com/XM666-Dev/IotaMultiplayer

dofile_once("mods/iota_multiplayer/files/scripts/lib/utilities.lua")

ModLuaFileAppend("mods/mnee/bindings.lua", "mods/iota_multiplayer/files/scripts/mnee.lua")
ModLuaFileAppend("data/scripts/biomes/mountain/mountain_left_entrance.lua", "mods/iota_multiplayer/files/scripts/biomes/mountain/mountain_left_entrance_appends.lua")
ModLuaFileAppend("data/scripts/biomes/temple_altar.lua", "mods/iota_multiplayer/files/scripts/biomes/temple_altar_appends.lua")
ModLuaFileAppend("data/scripts/perks/perk.lua", "mods/iota_multiplayer/files/scripts/perks/perk_appends.lua")

append_translations("mods/iota_multiplayer/files/translations.csv")

local gui = GuiCreate()

local function get_magic_numbers()
    local t = {}
    for k, v in string.gmatch(ModTextFileGetContent("data/magic_numbers.xml"), '(%g+)%s*=%s*"(.-)"') do
        t[k] = v
    end
    return t
end
local function MagicNumbers(t)
    local list = { "<MagicNumbers " }
    for k, v in pairs(t) do
        local value_type = type(v)
        if value_type == "number" then
            v = ("%f"):format(v)
        end
        if value_type == "boolean" then
            v = v and "1" or "0"
        end
        table.insert(list, ('%s="%s"'):format(k, v))
    end
    table.insert(list, "/>")
    return table.concat(list)
end
local function add_magic_numbers(t)
    ModTextFileSetContent("mods/iota_multiplayer/files/magic_numbers.xml", MagicNumbers(t))
    ModMagicNumbersFileAdd("mods/iota_multiplayer/files/magic_numbers.xml")
end
local magic_numbers = get_magic_numbers()

if GameGetWorldStateEntity() == 0 then
    ModSettingSet("iota_multiplayer.camera_zoom", ModSettingGetNextValue("iota_multiplayer.camera_zoom") or 1)
end
local zoom = ModSettingGet("iota_multiplayer.camera_zoom")
if zoom ~= 1 then
    add_magic_numbers({
        VIRTUAL_RESOLUTION_X = tonumber(magic_numbers.VIRTUAL_RESOLUTION_X) * zoom,
        VIRTUAL_RESOLUTION_Y = tonumber(magic_numbers.VIRTUAL_RESOLUTION_Y) * zoom,
    })
    local flag = true
    ModTextFileSetContent("data/shaders/post_final.vert", ModTextFileGetContent("data/shaders/post_final.vert")
        :gsub("camera_inv_zoom_ratio", function()
            if flag then
                flag = false
                return
            end
            return string.format("%f", zoom)
        end, 2)
        :gsub("\n", "\nuniform vec4 internal_zoom;", 1)
        :gsub("gl_MultiTexCoord0", "(gl_MultiTexCoord0 * internal_zoom - internal_zoom * 0.5 + 0.5)")
        :gsub("gl_MultiTexCoord1", "(gl_MultiTexCoord1 * internal_zoom - internal_zoom * 0.5 + 0.5)"))
end
local f = GameGetCameraBounds
function GameGetCameraBounds()
    local x, y, w, h = f()
    return x, y, w * internal_zoom, h * internal_zoom
end

function OnWorldInitialized()
    for i, pos in ipairs(mod.player_positions) do
        EntityKill(EntityLoad("mods/iota_multiplayer/files/entities/buildings/keep_alive.xml", unpack(pos)))
    end
end

function OnPlayerSpawned(player)
    player_spawned = true
    if has_flag_run_or_add("iota_multiplayer.player_spawned_once") then
        return
    end
    add_player(player)
    EntityAddComponent2(mod.id, "ElectricityReceiverComponent", { electrified_msg_interval_frames = 1 })
    EntityAddComponent2(mod.id, "LuaComponent", {
        script_electricity_receiver_electrified = "mods/iota_multiplayer/files/scripts/magic/camera_update.lua",
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

        player_data.controls.mButtonDownLeftClick = player_data.index == 1 and mnee.mnin_key("mouse_left", false, false, "guied")
        if mnee.mnin_key("mouse_left", true, false, "guied") and player_data.controls.mButtonDownLeftClick then
            player_data.controls.mButtonFrameLeftClick = get_frame_num_next()
        end

        player_data.controls.mButtonDownRightClick = player_data.index == 1 and mnee.mnin_key("mouse_right", false, false, "guied")
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
            player_data.controls.mAimingVector = { aiming_vector_x, aiming_vector_y }
            player_data.controls.mAimingVectorNormalized = { aiming_vector_normalized_x, aiming_vector_normalized_y }
            local mouse_position_raw_x, mouse_position_raw_y = InputGetMousePosOnScreen()
            local mouse_position_raw_prev = player_data.controls.mMousePositionRaw
            player_data.controls.mMousePosition = { mouse_position_x, mouse_position_y }
            player_data.controls.mMousePositionRaw = { mouse_position_raw_x, mouse_position_raw_y }
            player_data.controls.mMousePositionRawPrev = mouse_position_raw_prev
            player_data.controls.mMouseDelta = { mouse_position_raw_x - mouse_position_raw_prev[1], mouse_position_raw_y - mouse_position_raw_prev[2] }
            goto continue
        end
        if player_data:is_inventory_open() then
            aim = { 0, 0 }
        end
        local aiming_vector_non_zero_latest = player_data.controls.mAimingVectorNonZeroLatest
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
        player_data.controls.mAimingVector = { aiming_vector_non_zero_latest[1] * CONTROLS_AIMING_VECTOR_FULL_LENGTH_PIXELS, aiming_vector_non_zero_latest[2] * CONTROLS_AIMING_VECTOR_FULL_LENGTH_PIXELS }
        player_data.controls.mAimingVectorNormalized = aim
        player_data.controls.mAimingVectorNonZeroLatest = aiming_vector_non_zero_latest
        player_data.controls.mGamepadAimingVectorRaw = aim
        local mouse_position = player_data.controls.mGamePadCursorInWorld
        local mouse_position_raw_x, mouse_position_raw_y = get_pos_on_screen(gui, unpack(mouse_position))
        mouse_position_raw_x, mouse_position_raw_y = mouse_position_raw_x * 2, mouse_position_raw_y * 2
        local mouse_position_raw_prev = player_data.controls.mMousePositionRaw
        player_data.controls.mMousePosition = mouse_position
        player_data.controls.mMousePositionRaw = { mouse_position_raw_x, mouse_position_raw_y }
        player_data.controls.mMousePositionRawPrev = mouse_position_raw_prev
        player_data.controls.mMouseDelta = { mouse_position_raw_x - mouse_position_raw_prev[1], mouse_position_raw_y - mouse_position_raw_prev[2] }
        ::continue::
    end
end

local function get_item_index(item)
    local item_component = EntityGetFirstComponentIncludingDisabled(item, "ItemComponent")
    local ability_component = EntityGetFirstComponentIncludingDisabled(item, "AbilityComponent")
    if item_component ~= nil and ability_component ~= nil then
        return ComponentGetValue2(item_component, "inventory_slot") + (ComponentGetValue2(ability_component, "use_gun_script") and 0 or 4)
    end
end
local function get_item(player, index)
    local children = get_children(player)
    local i, quick_inventory = table.find(children, function(v) return EntityGetName(v) == "inventory_quick" end)
    local items = get_children(quick_inventory)
    for i, item in ipairs(items) do
        if get_item_index(item) == index then
            table.sort(items, function(a, b)
                local index_a = get_item_index(a)
                local index_b = get_item_index(b)
                return index_a ~= nil and index_b ~= nil and index_a < index_b
            end)
            return item, table.find(items, function(v) return v == item end)
        end
    end
end
local function update_gui()
    local gui_enabled_player = get_player(mod.gui_enabled_index)
    local gui_enabled_player_data = Player(gui_enabled_player)
    local next_gui_enabled_player
    local next_gui_enabled_player_data
    if gui_enabled_player == nil or gui_enabled_player_data.controls ~= nil and gui_enabled_player_data.controls.mButtonFrameInventory == get_frame_num_next() == gui_enabled_player_data:is_inventory_open() then
        next_gui_enabled_player = get_player(mod.camera_center_index)
    end
    local players = get_players()
    for i, player in ipairs(players) do
        local player_data = Player(player)
        if player_data.controls.mButtonFrameInventory == get_frame_num_next() then
            next_gui_enabled_player = player
        end
    end
    if next_gui_enabled_player ~= nil and next_gui_enabled_player ~= gui_enabled_player then
        next_gui_enabled_player_data = Player(next_gui_enabled_player)
        if next_gui_enabled_player_data.gui ~= nil and gui_enabled_player_data.gui ~= nil then
            next_gui_enabled_player_data.gui.wallet_money_target = gui_enabled_player_data.gui.wallet_money_target
        end
        if gui_enabled_player_data.gui ~= nil then
            remove_component(gui_enabled_player_data.gui._id)
            EntityAddComponent2(gui_enabled_player, "InventoryGuiComponent")
        end
        mod.gui_enabled_index = next_gui_enabled_player_data.index
    end
    local players_including_disabled = get_players_including_disabled()
    for i, player in ipairs(players_including_disabled) do
        local player_data = Player(player)
        if player_data.gui ~= nil then
            set_component_enabled(player_data.gui._id, player_data.index == mod.gui_enabled_index)
        end
    end
    --local players = get_players()
    --for i, player in ipairs(players) do
    --    local player_data = Player(player)
    --    if player_data.index == 1 then
    --        for i = 0, 7 do
    --            if InputIsKeyDown(30 + i) then
    --                local item, index = get_item(player, i)
    --                if item ~= nil then
    --                    --player_data.inventory.mActiveItem = item
    --                    --player_data.inventory.mActualActiveItem = item
    --                    player_data.inventory.mSavedActiveItemIndex = index - 1
    --                    player_data.inventory.mInitialized = false
    --                    --player_data.inventory.mForceRefresh = true
    --                end
    --            end
    --        end
    --    end
    --end
end

local function update_gui_post()
    local players = get_players_including_disabled()
    for i, player in ipairs(players) do
        local player_data = Player(player)
        if player_data.gui ~= nil then
            set_component_enabled(player_data.gui._id, true)
        end
    end
    --local players = get_players()
    --for i, player in ipairs(players) do
    --    local player_data = Player(player)
    --    if player_data.index == 1 then
    --        if InputIsKeyJustDown(30) then
    --            local item, index = get_item(player, 0)
    --            if item ~= nil then
    --                player_data.inventory.mActiveItem = item
    --                player_data.inventory.mActualActiveItem = item
    --                player_data.inventory.mSavedActiveItemIndex = index - 1
    --                player_data.inventory.mInitialized = false
    --                --debug_print("update_gui_post", player_data.inventory.mSavedActiveItemIndex)
    --            end
    --        end
    --        if InputIsKeyJustDown(31) then
    --            local item, index = get_item(player, 1)
    --            if item ~= nil then
    --                player_data.inventory.mActiveItem = item
    --                player_data.inventory.mActualActiveItem = item
    --                player_data.inventory.mSavedActiveItemIndex = index - 1
    --                player_data.inventory.mInitialized = false
    --                --debug_print("update_gui_post", player_data.inventory.mSavedActiveItemIndex)
    --            end
    --        end
    --    end
    --end
end

local function add_script_throw(item)
    if EntityGetFirstComponentIncludingDisabled(item, "LuaComponent", "iota_multiplayer.item_throw") == nil then
        EntityAddComponent2(item, "LuaComponent", {
            _tags = "enabled_in_world,enabled_in_hand,enabled_in_inventory,iota_multiplayer.item_throw",
            script_source_file = "mods/iota_multiplayer/files/scripts/items/item_throw.lua",
            script_throw_item = "mods/iota_multiplayer/files/scripts/items/item_throw.lua",
        })
    end
    local children = get_children(item)
    for i, child in ipairs(children) do
        add_script_throw(child)
    end
end
local function update_common()
    local players = get_players()
    local players_including_disabled = get_players_including_disabled()
    if mnee.mnin_bind("iota_multiplayer", "toggle_teleport", true, true) then
        local camera_center_player = get_player(mod.camera_center_index)
        local to_x, to_y = EntityGetTransform(camera_center_player)
        for i, player in ipairs(players) do
            local player_data = Player(player)
            if player_data.index ~= mod.camera_center_index then
                local from_x, from_y = EntityGetTransform(player)
                teleport(player, from_x, from_y, to_x, to_y)
            end
        end
    end
    if ModSettingGet("iota_multiplayer.share_money") then
        for i, player in ipairs(players) do
            local player_data = Player(player)
            if player_data.wallet ~= nil then
                mod.money = mod.money + player_data.wallet.money - player_data.previous_money
            end
        end
        for i, player in ipairs(players) do
            local player_data = Player(player)
            if player_data.wallet ~= nil then
                player_data.wallet.money = mod.money
                player_data.previous_money = mod.money
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
            add_script_throw(item)
        end
        if player_data.damage_model ~= nil then
            player_data.damage_model.wait_for_kill_flag_on_death = #players > 1
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
            player_data.aiming_reticle.visible = not aim_unbound and not player_data.dead
        end
    end
    if #players < 1 then
        local damaged_players = table.copy(players_including_disabled)
        table.sort(damaged_players, function(a, b)
            return Player(a).damage_frame > Player(b).damage_frame
        end)
        for i, player in ipairs(damaged_players) do
            local player_data = Player(player)
            set_component_enabled(player_data.damage_model._id, true)
            player_data.damage_model.wait_for_kill_flag_on_death = false
            player_data.damage_model.hp = 0
            player_data.damage_model.ui_report_damage = false
            EntityInflictDamage(player, 0.04, "", player_data.damage_message, "NO_RAGDOLL_FILE", 0, 0, player_data.damage_entity_thats_responsible)
            player_data.damage_model.kill_now = true
            player_data.damage_model.wait_for_kill_flag_on_death = true
            player_data.damage_model.ragdoll_fx_forced = "NO_RAGDOLL_FILE"
            player_data.log.report_death = false
        end
        GameSetCameraFree(false)
    end
    local player_positions = {}
    for i, player in ipairs(players_including_disabled) do
        local x, y = EntityGetTransform(player)
        player_positions[i] = { x, y }
    end
    mod.player_positions = player_positions
end

local function update_camera()
    local players = get_players()
    local camera_center_player = get_player(mod.camera_center_index)
    local camera_center_player_data = Player(camera_center_player)
    if mnee.mnin_bind("iota_multiplayer", "switch_player", true, true) or camera_center_player == nil then
        local entities = camera_center_player ~= nil and table.filter(players, function(player)
            return Player(player).index > camera_center_player_data.index
        end) or {}
        entities = #entities > 0 and entities or players
        local next_camera_center_player = table.iterate(entities, function(a, b)
            return Player(a).index < Player(b).index
        end)
        if next_camera_center_player ~= nil then
            local next_camera_center_player_data = Player(next_camera_center_player)
            mod.camera_center_index = next_camera_center_player_data.index
        end
    end
    local players_including_disabled = get_players_including_disabled()
    for i, player in ipairs(players_including_disabled) do
        local player_data = Player(player)
        if player_data.listener ~= nil then
            set_component_enabled(player_data.listener._id, player_data.index == mod.camera_center_index)
        end
    end
    if internal_zoom < 1 then
        local electricity_receiver = EntityGetFirstComponent(mod.id, "ElectricityReceiverComponent")
        if electricity_receiver ~= nil then
            ComponentSetValue2(electricity_receiver, "mLastFrameElectrified", get_frame_num_next())
        end
    end
end

local function update_camera_post()
    local players = table.filter(get_players(), function(v)
        local player_data = Player(v)
        return player_data.load_frame ~= GameGetFrameNum()
    end)
    if #players > 0 then
        local positions = {}
        local camera_center_player = get_player(mod.camera_center_index)
        if camera_center_player ~= nil then
            local center_x, center_y = EntityGetTransform(camera_center_player)
            local min_resolution_x, min_resolution_y = tonumber(magic_numbers.VIRTUAL_RESOLUTION_X), tonumber(magic_numbers.VIRTUAL_RESOLUTION_Y)
            local max_resolution_x, max_resolution_y = tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_X")), tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_Y"))
            local safe_w = max_resolution_x - min_resolution_x * 0.5
            local safe_h = max_resolution_y - min_resolution_y * 0.5
            for i, player in ipairs(players) do
                local x, y
                local player_data = Player(player)
                if player_data.shooter ~= nil then
                    x, y = unpack(player_data.shooter.mDesiredCameraPos)
                else
                    x, y = EntityGetTransform(player)
                end
                if math.abs(x - center_x) < safe_w and math.abs(y - center_y) < safe_h then
                    table.insert(positions, { x, y })
                end
            end
            local min_x, min_y = table.iterate(positions, function(a, b)
                return a[1] < b[1]
            end)[1], table.iterate(positions, function(a, b)
                return a[2] < b[2]
            end)[2]
            local max_x, max_y = table.iterate(positions, function(a, b)
                return a[1] > b[1]
            end)[1], table.iterate(positions, function(a, b)
                return a[2] > b[2]
            end)[2]
            local resolution_x, resolution_y = math.min(max_x - min_x + min_resolution_x, max_resolution_x), math.min(max_y - min_y + min_resolution_y, max_resolution_y)
            internal_zoom = math.max(resolution_x / max_resolution_x, resolution_y / max_resolution_y)
            GameSetPostFxParameter("internal_zoom", internal_zoom, internal_zoom, internal_zoom, internal_zoom)
            local camera_x, camera_y = (min_x + max_x) / 2, (min_y + max_y) / 2
            GameSetCameraPos(camera_x, camera_y)
            GameSetCameraFree(true)
        end
    end
    if internal_zoom < 1 then
        local entities = EntityGetInRadius(0, 0, math.huge)
        for i, entity in ipairs(entities) do
            local sprites = EntityGetComponent(entity, "SpriteComponent") or {}
            for i, sprite in ipairs(sprites) do
                if ComponentGetValue2(sprite, "emissive") then
                    ComponentSetValue2(sprite, "emissive", false)
                    ComponentSetValue2(sprite, "z_index", -math.huge)
                    EntityRefreshSprite(entity, sprite)
                end
            end
        end
    end
end

local function update_gui_mod()
    if #get_players_including_disabled() < 2 then return end
    GuiStartFrame(gui)

    GuiOptionsAddForNextWidget(gui, GUI_OPTION.Align_HorizontalCenter)
    GuiText(gui, 10, 25, "P" .. mod.gui_enabled_index)

    local widgets = {}
    local players = get_players()
    for i, player in ipairs(players) do
        local player_data = Player(player)
        local player_x, player_y = EntityGetTransform(player)
        local x, y = get_pos_on_screen(gui, player_x, player_y)
        local offset_x = 5
        local offset_y = 5

        local y = y + offset_y
        table.insert(widgets, function()
            GuiOptionsAddForNextWidget(gui, GUI_OPTION.Align_HorizontalCenter)
            GuiText(gui, x, y, "P" .. player_data.index)
        end)

        local x = x + offset_x
        local y = y + 2
        local to_x = x + 6
        local to_y = y + 6
        table.insert(widgets, function()
            GuiImage(gui, new_id("bar_bg" .. i), x, y, "data/ui_gfx/hud/colors_bar_bg.png", 1, (to_x - x) / 2, (to_y - y) / 2)
        end)

        local x, y = x + 1, y + 1
        local to_x, to_y = to_x - 1, to_y - 1
        if player_data.damage_model ~= nil then
            local to_x = lerp_clamped(x, to_x, player_data.damage_model.hp / player_data.damage_model.max_hp)
            table.insert(widgets, function()
                GuiImage(gui, new_id("health_bar" .. i), x, y, "data/ui_gfx/hud/colors_health_bar.png", 1, (to_x - x) / 2, (to_y - y) / 2)
            end)
        end
        if player_data.character_data ~= nil and player_data.character_data.mFlyingTimeLeft < player_data.character_data.fly_time_max then
            local y = lerp_clamped(y, to_y, player_data.character_data.mFlyingTimeLeft / player_data.character_data.fly_time_max)
            table.insert(widgets, function()
                GuiImage(gui, new_id("flying_bar" .. i), x, y, "data/ui_gfx/hud/colors_flying_bar.png", 1, (to_x - x) / 2, (to_y - y) / 2)
            end)
        end
    end
    for i, f in ipairs(widgets) do
        GuiZSetForNextWidget(gui, #widgets - i + 1001)
        f()
    end
end

function OnWorldPreUpdate()
    if player_spawned then
        update_camera()
        update_common()
        update_controls()
        update_gui()
    end
end

function OnWorldPostUpdate()
    if player_spawned then
        update_camera_post()
        update_gui_post()
        update_gui_mod()
    end
end
