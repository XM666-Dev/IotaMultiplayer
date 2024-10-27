--IotaMultiplayer - Created by ImmortalDamned
--Github https://github.com/XM666-Dev/IotaMultiplayer

dofile_once("mods/iota_multiplayer/files/scripts/lib/utilities.lua")

ModLuaFileAppend("mods/mnee/bindings.lua", "mods/iota_multiplayer/files/scripts/mnee.lua")
ModLuaFileAppend("data/scripts/biomes/mountain/mountain_left_entrance.lua", "mods/iota_multiplayer/files/scripts/biomes/mountain/mountain_left_entrance_appends.lua")
ModLuaFileAppend("data/scripts/biomes/temple_altar.lua", "mods/iota_multiplayer/files/scripts/biomes/temple_altar_appends.lua")
ModLuaFileAppend("data/scripts/items/heart_fullhp_temple.lua", "mods/iota_multiplayer/files/scripts/items/share_appends.lua")
ModLuaFileAppend("data/scripts/items/spell_refresh.lua", "mods/iota_multiplayer/files/scripts/items/share_appends.lua")
local filenames = ModLuaFileGetAppends("data/scripts/perks/perk.lua")
table.insert(filenames, 1, "mods/iota_multiplayer/files/scripts/perks/perk_appends.lua")
ModLuaFileSetAppends("data/scripts/perks/perk.lua", filenames)
ModTextFileSetContent("mods/iota_multiplayer/files/scripts/get_player_appends.lua", [[
dofile_once("mods/iota_multiplayer/files/scripts/lib/utilities.lua")
function get_player() return get_player_at_index(mod.camera_center_index) end
]])
ModLuaFileAppend("mods/spell_lab_shugged/files/gui/get_player.lua", "mods/iota_multiplayer/files/scripts/get_player_appends.lua")

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
local mod_magic_numbers = { UI_COOP_QUICK_INVENTORY_HEIGHT = 0, UI_COOP_STAT_BARS_HEIGHT = 0 }

if GameGetWorldStateEntity() == 0 then
    ModSettingSet("iota_multiplayer.camera_zoom_max", ModSettingGetNextValue("iota_multiplayer.camera_zoom_max"))
end
if ModSettingGet("iota_multiplayer.camera_zoom_max") ~= 1 then
    mod_magic_numbers.VIRTUAL_RESOLUTION_X = tonumber(magic_numbers.VIRTUAL_RESOLUTION_X) * ModSettingGet("iota_multiplayer.camera_zoom_max")
    mod_magic_numbers.VIRTUAL_RESOLUTION_Y = tonumber(magic_numbers.VIRTUAL_RESOLUTION_Y) * ModSettingGet("iota_multiplayer.camera_zoom_max")
    ModTextFileSetContent("data/shaders/post_final.vert", ModTextFileGetContent("data/shaders/post_final.vert")
        :gsub(("90.0 * camera_inv_zoom_ratio"):raw(), ("90.0 * camera_inv_zoom_ratio * %f"):format(ModSettingGet("iota_multiplayer.camera_zoom_max")))
        :gsub("\n", "\nuniform vec4 internal_zoom;", 1)
        :gsub("gl_MultiTexCoord0", "gl_MultiTexCoord0 * internal_zoom - internal_zoom * 0.5 + 0.5")
        :gsub("gl_MultiTexCoord1", "gl_MultiTexCoord1 * internal_zoom - internal_zoom * 0.5 + 0.5")
    )
end
local function get_camera_info()
    local players = table.filter(get_players(), function(v) return Player(v).load_frame ~= GameGetFrameNum() end)
    local positions = {}
    local camera_center_player = get_player_at_index(mod.camera_center_index)
    local center_x, center_y = EntityGetTransform(camera_center_player)
    local min_resolution_x, min_resolution_y = tonumber(magic_numbers.VIRTUAL_RESOLUTION_X) * ModSettingGet("iota_multiplayer.camera_zoom_min"), tonumber(magic_numbers.VIRTUAL_RESOLUTION_Y) * ModSettingGet("iota_multiplayer.camera_zoom_min")
    local max_resolution_x, max_resolution_y = tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_X")), tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_Y"))
    local safe_w = max_resolution_x - min_resolution_x * 0.5
    local safe_h = max_resolution_y - min_resolution_y * 0.5
    for i, player in ipairs(players) do
        local x, y
        local player_data = Player(player)
        if player_data.shooter ~= nil then
            x, y = player_data.shooter.mDesiredCameraPos()
        else
            x, y = EntityGetTransform(player)
        end
        --if math.abs(x - center_x) < safe_w and math.abs(y - center_y) < safe_h then
        if not ModSettingGet("iota_multiplayer.camera_unique") or player_data.index == mod.camera_center_index then
            table.insert(positions, { x, y })
        end
        --end
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
    local camera_x, camera_y = (min_x + max_x) / 2, (min_y + max_y) / 2
    local resolution_x, resolution_y = math.min(max_x - min_x + min_resolution_x, max_resolution_x), math.min(max_y - min_y + min_resolution_y, max_resolution_y)
    local internal_zoom = math.max(resolution_x / max_resolution_x, resolution_y / max_resolution_y)
    return camera_x, camera_y, internal_zoom
end

local raw_game_get_camera_bounds = GameGetCameraBounds
function GameGetCameraBounds()
    local x, y, w, h = raw_game_get_camera_bounds()
    local camera_x, camera_y, internal_zoom = get_camera_info()
    local ratio = 0.5 - internal_zoom / 2
    return x + w * ratio, y + h * ratio, w * internal_zoom, h * internal_zoom
end

local raw_get_resolution = get_resolution
function get_resolution(gui)
    local width, height = raw_get_resolution(gui)
    local camera_x, camera_y, internal_zoom = get_camera_info()
    return width * internal_zoom, height * internal_zoom
end

add_magic_numbers(mod_magic_numbers)

function OnWorldInitialized()
    for i, pos in ipairs(mod.player_positions) do
        EntityKill(EntityLoad("mods/iota_multiplayer/files/entities/buildings/keep_alive.xml", unpack(pos)))
    end
end

function OnPlayerSpawned(player)
    player_spawned = true
    debug_print("player_spawned_once", GameHasFlagRun("iota_multiplayer.player_spawned_once"))
    if has_flag_run_or_add("iota_multiplayer.player_spawned_once") then
        return
    end
    local player_data = Player(player)
    player_data:add()
    EntityAddComponent2(mod.id, "LuaComponent", { script_source_file = "mods/iota_multiplayer/files/scripts/magic/player_polymorph.lua" })
    EntityAddComponent2(mod.id, "ElectricityReceiverComponent", { electrified_msg_interval_frames = 1 })
    EntityAddComponent2(mod.id, "LuaComponent", { script_electricity_receiver_electrified = "mods/iota_multiplayer/files/scripts/magic/camera_update_pre.lua" })
    EntityAddComponent2(mod.id, "LuaComponent", { script_source_file = "mods/iota_multiplayer/files/scripts/magic/camera_update_post.lua" })
end

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
            local attack_table = get_attack_table(player, ai, attacks)
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

        player_data.controls.mButtonDownChangeItemR = player_data:mnin_bind("itemnext", true) and ModTextFileGetContent("mods/spell_lab_shugged/scroll_box_hovered.txt") ~= "true"
        if player_data:mnin_bind("itemnext", true, true) and player_data.controls.mButtonDownChangeItemR then
            player_data.controls.mButtonFrameChangeItemR = get_frame_num_next()
            player_data.controls.mButtonCountChangeItemR = 1
        else
            player_data.controls.mButtonCountChangeItemR = 0
        end

        player_data.controls.mButtonDownChangeItemL = player_data:mnin_bind("itemprev", true) and ModTextFileGetContent("mods/spell_lab_shugged/scroll_box_hovered.txt") ~= "true"
        if player_data:mnin_bind("itemprev", true, true) and player_data.controls.mButtonDownChangeItemL then
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
            local mouse_position_raw_x, mouse_position_raw_y = InputGetMousePosOnScreen()
            local mouse_position_x, mouse_position_y = get_pos_in_world(mouse_position_raw_x, mouse_position_raw_y)
            local center_x, center_y = EntityGetFirstHitboxCenter(player)
            local aiming_vector_x, aiming_vector_y = mouse_position_x - center_x, mouse_position_y - center_y
            local magnitude = math.max(math.sqrt(aiming_vector_x * aiming_vector_x + aiming_vector_y * aiming_vector_y), CONTROLS_AIMING_VECTOR_FULL_LENGTH_PIXELS)
            local aiming_vector_normalized_x, aiming_vector_normalized_y = aiming_vector_x / magnitude, aiming_vector_y / magnitude
            player_data.controls.mAimingVector = { aiming_vector_x, aiming_vector_y }
            player_data.controls.mAimingVectorNormalized = { aiming_vector_normalized_x, aiming_vector_normalized_y }
            local mouse_position_raw_prev = player_data.controls.mMousePositionRaw
            player_data.controls.mMousePosition = { mouse_position_x, mouse_position_y }
            player_data.controls.mMousePositionRaw = { mouse_position_raw_x, mouse_position_raw_y }
            player_data.controls.mMousePositionRawPrev = mouse_position_raw_prev
            player_data.controls.mMouseDelta = { mouse_position_raw_x - mouse_position_raw_prev[1], mouse_position_raw_y - mouse_position_raw_prev[2] }
            goto continue
        end
        local aim_raw = mnin_stick_raw("iota_multiplayer" .. player_data.index, "aim")
        if player_data:is_inventory_open() then
            aim = { 0, 0 }
            aim_raw = { 0, 0 }
        end
        local aiming_vector_non_zero_latest = player_data.controls.mAimingVectorNonZeroLatest
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
        local mouse_position_raw_x, mouse_position_raw_y = get_pos_on_screen(mouse_position())
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
    local gui_enabled_player = get_player_at_index_including_disabled(mod.gui_enabled_index)
    local gui_enabled_player_data = Player(gui_enabled_player)
    local next_gui_enabled_player
    local next_gui_enabled_player_data
    if gui_enabled_player == nil or gui_enabled_player_data.controls ~= nil and gui_enabled_player_data.controls.mButtonFrameInventory == get_frame_num_next() == gui_enabled_player_data:is_inventory_open() then
        next_gui_enabled_player = get_player_at_index(mod.camera_center_index)
    end
    local players_including_disabled = get_players_including_disabled()
    for i, player in ipairs(players_including_disabled) do
        local player_data = Player(player)
        if player_data.controls ~= nil and player_data.controls.mButtonFrameInventory == get_frame_num_next() then
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

    if not gui_initialized then
        gui_initialized = true
        for i, player in ipairs(players_including_disabled) do
            local player_data = Player(player)
            if player_data.gui ~= nil then
                remove_component(player_data.gui._id)
                EntityAddComponent2(player, "InventoryGuiComponent")
            end
        end
    end

    local gui_enabled_player = get_player_at_index_including_disabled(mod.gui_enabled_index)
    local i, player = table.find(players_including_disabled, function(v) return Player(v).controls.mButtonFrameInteract == get_frame_num_next() end)
    if player ~= nil and player ~= gui_enabled_player then
        local player_data = Player(player)
        player_data.gui.mAlpha = -0.2
        gui_enabled_player = player
    end
    for i, player in ipairs(players_including_disabled) do
        local player_data = Player(player)
        if player_data.gui ~= nil then
            set_component_enabled(player_data.gui._id, player == gui_enabled_player)
        end
    end
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
local share_class = Class {
    shared_indexs = VariableAccessor("iota_multiplayer.shared_indexs", "value_string", "{}"),
}
local function Share(entity)
    return setmetatable({ id = entity }, share_class)
end
local hint_class = Class {
    index = VariableAccessor("iota_multiplayer.index", "value_int"),
}
local function Hint(entity)
    return setmetatable({ id = entity }, hint_class)
end
local function update_common()
    local players = get_players()
    local players_including_disabled = get_players_including_disabled()

    if mnee.mnin_bind("iota_multiplayer", "toggle_teleport", true, true) then
        local camera_center_player = get_player_at_index(mod.camera_center_index)
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

        local items = get_inventory_items(player)
        for i, item in ipairs(items) do
            add_script_throw(item)
        end

        if player_data.damage_model ~= nil then
            player_data.damage_model.wait_for_kill_flag_on_death = #players > 1
            if player_data.damage_model.hp < 0 then
                player_data:set_dead(true)
            end
        end

        local hints = EntityGetWithTag("iota_multiplayer.hint")
        local i, hint = table.find(hints, function(v) return Hint(v).index == player_data.index end)
        if hint == nil then
            hint = EntityCreateNew()
            EntityAddTag(hint, "iota_multiplayer.hint")
            EntityAddComponent2(hint, "VariableStorageComponent", { _tags = "iota_multiplayer.index,enabled_in_inventory" })
            local hint_data = Hint(hint)
            hint_data.index = player_data.index
            EntityAddComponent2(hint, "LuaComponent", { _tags = "enabled_in_inventory", script_item_picked_up = "mods/iota_multiplayer/files/scripts/items/corpse_pickup.lua" })
        end
        EntityRemoveFromParent(hint)
        local item = EntityGetFirstComponentIncludingDisabled(hint, "ItemComponent") or EntityAddComponent2(hint, "ItemComponent", {
            _tags = "enabled_in_inventory", play_pick_sound = false,
        })

        ComponentSetValue2(item, "item_name", "$iota_multiplayer.item_resurrect")
        ComponentSetValue2(item, "custom_pickup_string", "$iota_multiplayer.itempickup_use")

        local x, y = EntityGetTransform(player)
        local coop_respawn = EntityGetInRadiusWithTag(x, y, 100, "coop_respawn")[1]
        local coop_respawn_data = Share(coop_respawn)
        local shared_indexs
        if coop_respawn ~= nil then
            local to_x, to_y = EntityGetTransform(coop_respawn)
            local hint_x, hint_y = vec_normalize(vec_sub(to_x, to_y, x, y))
            hint_x, hint_y = vec_add(x, y, vec_mult(hint_x, hint_y, ComponentGetValue2(item, "item_pickup_radius")))
            EntitySetTransform(hint, hint_x, hint_y)

            shared_indexs = deserialize(coop_respawn_data.shared_indexs)
            local dead_players = table.filter(players_including_disabled, function(v) return Player(v).dead end)
            for i, dead_player in ipairs(dead_players) do
                local dead_player_data = Player(dead_player)
                if dead_player_data:mnin_bind("interact", true, true) then
                    if table.find(shared_indexs, function(v) return v == dead_player_data.index end) then goto continue end
                    table.insert(shared_indexs, dead_player_data.index)
                    coop_respawn_data.shared_indexs = serialize(shared_indexs)

                    dead_player_data:set_dead(false)
                    local from_x, from_y = EntityGetTransform(dead_player)
                    teleport(dead_player, from_x, from_y, to_x, to_y)
                end
                ::continue::
            end
        end
        set_component_enabled(item, coop_respawn ~= nil and #shared_indexs < #players_including_disabled)
    end

    for i, player in ipairs(players_including_disabled) do
        local player_data = Player(player)
        if player_data.dead then
            GamePlayAnimation(player, "intro_sleep", 0x7FFFFFFF)

            local hints = EntityGetWithTag("iota_multiplayer.hint")
            local i, hint = table.find(hints, function(v) return Hint(v).index == player_data.index end)
            if hint == nil then
                hint = EntityCreateNew()
                EntityAddTag(hint, "iota_multiplayer.hint")
                EntityAddComponent2(hint, "VariableStorageComponent", { _tags = "iota_multiplayer.index,enabled_in_inventory" })
                local hint_data = Hint(hint)
                hint_data.index = player_data.index
                EntityAddComponent2(hint, "LuaComponent", { _tags = "enabled_in_inventory", script_item_picked_up = "mods/iota_multiplayer/files/scripts/items/corpse_pickup.lua" })
            end
            EntityRemoveFromParent(hint)
            local item = EntityGetFirstComponentIncludingDisabled(hint, "ItemComponent") or EntityAddComponent2(hint, "ItemComponent", {
                _tags = "enabled_in_inventory", play_pick_sound = false,
            })

            ComponentSetValue2(item, "item_name", "$iota_multiplayer.item_corpse")
            ComponentSetValue2(item, "custom_pickup_string", "$itempickup_open")

            local x, y = EntityGetTransform(player)
            EntitySetTransform(hint, x, y)

            set_component_enabled(item, player_data.controls.mButtonFrameInventory == get_frame_num_next() == player_data:is_inventory_open() or InputIsKeyJustDown(Key_ESCAPE)) --need corpse sharing being completed
            --player_data.controls.mButtonFrameInventory == get_frame_num_next() ~= player_data:is_inventory_open() and not InputIsKeyJustDown(Key_ESCAPE)
        end
        local arm_r = player_data:get_arm_r()
        if arm_r ~= nil and player_data.sprite ~= nil then
            local intro = player_data.sprite.rect_animation == "intro_sleep" or player_data.sprite.rect_animation == "intro_stand_up"
            EntitySetName(arm_r, intro and "" or "arm_r")
            EntitySetComponentsWithTagEnabled(arm_r, "with_item", not intro)
        end
        if player_data.aiming_reticle ~= nil then
            local aim, aim_unbound, aim_emulated = player_data:mnin_stick("aim")
            player_data.aiming_reticle.visible = not aim_unbound and not player_data:is_inventory_open() and not player_data.dead
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
    local camera_center_player = get_player_at_index(mod.camera_center_index)
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
    if ModSettingGet("iota_multiplayer.camera_zoom_max") ~= ModSettingGet("iota_multiplayer.camera_zoom_min") then
        local electricity_receiver = EntityGetFirstComponent(mod.id, "ElectricityReceiverComponent")
        if electricity_receiver ~= nil then
            ComponentSetValue2(electricity_receiver, "mLastFrameElectrified", get_frame_num_next())
        end
    end
end

local function update_camera_post()
    if #get_players() < 1 then return end
    local camera_x, camera_y, internal_zoom = get_camera_info()
    GameSetCameraPos(camera_x, camera_y)
    GameSetCameraFree(true)
    GameSetPostFxParameter("internal_zoom", internal_zoom, internal_zoom, internal_zoom, internal_zoom)
end

local colors_bar_bg = ModImageMakeEditable("data/ui_gfx/hud/colors_bar_bg.png", nil, nil)
local border_color = ModImageGetPixel(colors_bar_bg, 1, 0)
local fill_color = ModImageGetPixel(colors_bar_bg, 1, 1)
local bar_bg = ModImageMakeEditable("mods/iota_multiplayer/files/ui_gfx/hud/bar_bg.png", 3, 3)
for i = 0, 2 do
    for j = 0, 2 do
        ModImageSetPixel(bar_bg, j, i, border_color)
    end
end
ModImageSetPixel(bar_bg, 1, 1, fill_color)
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
        local hitbox = EntityGetFirstComponent(player, "HitboxComponent")
        if hitbox ~= nil then
            local offset_x, offset_y = ComponentGetValue2(hitbox, "offset")
            player_y = player_y + ComponentGetValue2(hitbox, "aabb_max_y") + offset_y
        end

        local x, y = get_pos_on_screen(player_x, player_y, gui)
        table.insert(widgets, function()
            GuiOptionsAddForNextWidget(gui, GUI_OPTION.Align_HorizontalCenter)
            GuiText(gui, x, y, "P" .. player_data.index)
        end)

        local x = x + 6
        local y = y + 3
        local width = 4
        local height = 4
        table.insert(widgets, function()
            GuiImageNinePiece(gui, new_id("bar_bg" .. i), x, y, width, height, 1, "mods/iota_multiplayer/files/ui_gfx/hud/bar_bg.png")
        end)

        if player_data.damage_model ~= nil then
            local ratio = player_data.damage_model.hp / player_data.damage_model.max_hp
            table.insert(widgets, function()
                GuiImage(gui, new_id("health_bar" .. i), x, y, "data/ui_gfx/hud/colors_health_bar.png", 1, width / 2 * ratio, height / 2)
            end)
        end
        if player_data.character_data ~= nil and player_data.character_data.mFlyingTimeLeft < player_data.character_data.fly_time_max then
            local ratio = player_data.character_data.mFlyingTimeLeft / player_data.character_data.fly_time_max
            table.insert(widgets, function()
                GuiImage(gui, new_id("flying_bar" .. i), x, y + height * ratio, "data/ui_gfx/hud/colors_flying_bar.png", 1, width / 2, height / 2 * (1 - ratio))
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
        update_gui_mod()
    end
end
