--IotaMultiplayer - Created by ImmortalDamned
--Github https://github.com/XM666-Dev/IotaMultiplayer

dofile_once("mods/iota_multiplayer/files/scripts/lib/utilities.lua")
local nxml = dofile_once("mods/iota_multiplayer/files/scripts/lib/nxml.lua")

ModLuaFileAppend("data/scripts/biomes/mountain/mountain_left_entrance.lua", "mods/iota_multiplayer/files/scripts/biomes/mountain/mountain_left_entrance_appends.lua")
ModLuaFileAppend("data/scripts/items/heart_fullhp_temple.lua", "mods/iota_multiplayer/files/scripts/items/share_appends.lua")
ModLuaFileAppend("data/scripts/items/spell_refresh.lua", "mods/iota_multiplayer/files/scripts/items/share_appends.lua")
for i, filename in ipairs{"data/entities/items/pickup/heart_fullhp_temple.xml", "data/entities/items/pickup/spell_refresh.xml"} do
    for xml in nxml.edit_file(filename) do
        xml:create_child("LuaComponent", {script_item_picked_up = "mods/iota_multiplayer/files/scripts/items/share_pickup.lua"})
    end
end
ModLuaFileAppend("data/scripts/biomes/temple_altar.lua", "mods/iota_multiplayer/files/scripts/biomes/temple_altar_appends.lua")
ModLuaFileAppend("data/scripts/perks/perk.lua", "mods/iota_multiplayer/files/scripts/perks/perk_appends.lua")
ModLuaFileAppend("data/scripts/newgame_plus.lua", "mods/iota_multiplayer/files/scripts/newgame_plus_appends.lua")
ModLuaFileAppend("mods/mnee/bindings.lua", "mods/iota_multiplayer/files/scripts/mnee.lua")
ModLuaFileAppend("mods/spell_lab_shugged/files/gui/get_player.lua", "mods/iota_multiplayer/files/scripts/get_player_appends.lua")
ModTextFileSetContent("mods/iota_multiplayer/files/scripts/get_player_appends.lua", 'dofile_once("mods/iota_multiplayer/files/scripts/lib/utilities.lua") function get_player() return get_player_at_index(mod.camera_center_index) end')

append_translations("mods/iota_multiplayer/files/translations.csv")

local gui = GuiCreate()

local magic_numbers = nxml.parse_file("data/magic_numbers.xml").attr
local magic_numbers_mod = {UI_COOP_QUICK_INVENTORY_HEIGHT = 0, UI_COOP_STAT_BARS_HEIGHT = 0}
if not validate(GameGetWorldStateEntity()) then
    ModSettingSet("iota_multiplayer.camera_zoom_max", ModSettingGetNextValue("iota_multiplayer.camera_zoom_max"))
end
if ModSettingGet("iota_multiplayer.camera_zoom_max") ~= 1 then
    magic_numbers_mod.VIRTUAL_RESOLUTION_X = tonumber(magic_numbers.VIRTUAL_RESOLUTION_X) * ModSettingGet("iota_multiplayer.camera_zoom_max")
    magic_numbers_mod.VIRTUAL_RESOLUTION_Y = tonumber(magic_numbers.VIRTUAL_RESOLUTION_Y) * ModSettingGet("iota_multiplayer.camera_zoom_max")
    ModTextFileSetContent("data/shaders/post_final.vert", ModTextFileGetContent("data/shaders/post_final.vert")
        :gsub(("90.0 * camera_inv_zoom_ratio"):raw(), ("90.0 * camera_inv_zoom_ratio * %f"):format(ModSettingGet("iota_multiplayer.camera_zoom_max")))
        :gsub("\n", "\nuniform vec4 camera_zoom;", 1)
        :gsub("gl_MultiTexCoord0", "gl_MultiTexCoord0 * camera_zoom - camera_zoom * 0.5 + 0.5")
        :gsub("gl_MultiTexCoord1", "gl_MultiTexCoord1 * camera_zoom - camera_zoom * 0.5 + 0.5")
    )
end
ModMagicNumbersFileAdd("mods/iota_multiplayer/files/magic_numbers.xml")
ModTextFileSetContent("mods/iota_multiplayer/files/magic_numbers.xml", tostring(nxml.new_element("MagicNumbers", magic_numbers_mod)))

local previous_frame
local previous_camera_zoom
local function get_camera_info()
    local positions = {}
    local camera_center_player = get_player_at_index(mod.camera_center_index)
    local camera_center_player_object = Player(camera_center_player)
    local center_x, center_y = camera_center_player_object:get_camera_pos()
    local min_resolution_x, min_resolution_y = tonumber(magic_numbers.VIRTUAL_RESOLUTION_X) * ModSettingGet("iota_multiplayer.camera_zoom_min"), tonumber(magic_numbers.VIRTUAL_RESOLUTION_Y) * ModSettingGet("iota_multiplayer.camera_zoom_min")
    local max_resolution_x, max_resolution_y = tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_X")), tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_Y"))
    local expand_width = max_resolution_x - min_resolution_x
    local expand_height = max_resolution_y - min_resolution_y
    local shrink_width = max_resolution_x - min_resolution_x * 0.5
    local shrink_height = max_resolution_y - min_resolution_y * 0.5
    local players = table.filter(get_players(), function(v) return Player(v).load_frame ~= GameGetFrameNum() end)
    for i, player in ipairs(players) do
        local player_object = Player(player)
        local x, y = player_object:get_camera_pos()
        local pos_x, pos_y = EntityGetTransform(player)
        local shrink_x = math.max(math.abs(pos_x - center_x) - shrink_width, 0)
        local shrink_y = math.max(math.abs(pos_y - center_y) - shrink_height, 0)
        shrink_x = shrink_x * tonumber(magic_numbers.VIRTUAL_RESOLUTION_Y)
        shrink_y = shrink_y * tonumber(magic_numbers.VIRTUAL_RESOLUTION_X)
        local shrink = math.max(shrink_x, shrink_y)
        shrink_x = shrink / tonumber(magic_numbers.VIRTUAL_RESOLUTION_Y)
        shrink_y = shrink / tonumber(magic_numbers.VIRTUAL_RESOLUTION_X)
        expand_width = math.max(expand_width - shrink_x, 0)
        expand_height = math.max(expand_height - shrink_y, 0)
        x = clamp(x, center_x - expand_width, center_x + expand_width)
        y = clamp(y, center_y - expand_height, center_y + expand_height)
        table.insert(positions, {x, y})
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
    local camera_x, camera_y = (min_x + max_x) * 0.5, (min_y + max_y) * 0.5
    local resolution_x, resolution_y = math.min(max_x - min_x + min_resolution_x, max_resolution_x), math.min(max_y - min_y + min_resolution_y, max_resolution_y)
    local camera_zoom = math.max(resolution_x / max_resolution_x, resolution_y / max_resolution_y)
    local frame = GameGetFrameNum()
    if previous_frame == nil or previous_frame < frame then
        previous_frame = frame
        if previous_camera_zoom ~= nil then
            previous_camera_zoom = lerp(previous_camera_zoom, camera_zoom, 0.0625)
        else
            previous_camera_zoom = camera_zoom
        end
    end
    return camera_x, camera_y, previous_camera_zoom
end

local raw_game_get_camera_bounds = GameGetCameraBounds
function GameGetCameraBounds()
    local x, y, w, h = raw_game_get_camera_bounds()
    local camera_x, camera_y, camera_zoom = get_camera_info()
    local ratio = (1 - camera_zoom) * 0.5
    return x + w * ratio, y + h * ratio, w * camera_zoom, h * camera_zoom
end

local raw_get_resolution = get_resolution
function get_resolution(gui)
    local width, height = raw_get_resolution(gui)
    local camera_x, camera_y, camera_zoom = get_camera_info()
    return width * camera_zoom, height * camera_zoom
end

local receiver
function OnPlayerSpawned(player)
    local player_object = Player(player)
    player_object:add()
    player_object.index = 1
    local updator = EntityCreateNew("iota_multiplayer.updator")
    EntityAddComponent2(updator, "LuaComponent", {script_source_file = "mods/iota_multiplayer/files/scripts/magic/player_polymorph.lua"})
    EntityAddComponent2(updator, "LuaComponent", {script_source_file = "mods/iota_multiplayer/files/scripts/items/share_pickup.lua"})
    EntityAddComponent2(updator, "LuaComponent", {script_electricity_receiver_electrified = "mods/iota_multiplayer/files/scripts/magic/camera_update_pre.lua"})
    EntityAddComponent2(updator, "LuaComponent", {script_source_file = "mods/iota_multiplayer/files/scripts/magic/camera_update_post.lua"})
    receiver = EntityAddComponent2(updator, "ElectricityReceiverComponent", {electrified_msg_interval_frames = 1})
end

local function add_script_throw(item)
    if EntityGetComponentIncludingDisabled(item, "ItemComponent") ~= nil and EntityGetComponentIncludingDisabled(item, "LuaComponent", "iota_multiplayer.item_throw") == nil then
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

    if ModSettingGet("iota_multiplayer.share_money") then
        for i, player in ipairs(players) do
            local player_object = Player(player)
            if player_object.wallet ~= nil then
                mod.money = mod.money + player_object.wallet.money - player_object.previous_money
            end
        end
        for i, player in ipairs(players) do
            local player_object = Player(player)
            if player_object.wallet ~= nil then
                player_object.wallet.money = mod.money
                player_object.previous_money = mod.money
            end
        end
    end

    for i, player in ipairs(players) do
        local player_object = Player(player)
        if player_object:get_edit_count() > #get_children(player, "iota_multiplayer.share") then
            for i, sharer in ipairs(table.filter(players, function(v)
                local x, y = EntityGetTransform(v)
                return get_distance2(x, y, EntityGetTransform(player)) < 14.1 * 14.1
            end)) do
                for i = Player(sharer):get_edit_count(), #get_children(sharer, "iota_multiplayer.share") do
                    local effect, effect_entity = GetGameEffectLoadTo(sharer, "EDIT_WANDS_EVERYWHERE", true)
                    ComponentSetValue2(effect, "frames", 1)
                    EntityAddTag(effect_entity, "iota_multiplayer.share")
                end
            end
        end

        player_object.pickupper_.is_immune_to_kicks = not ModSettingGet("iota_multiplayer.friendly_fire_kick_drop")

        local items = get_inventory_items(player)
        for i, item in ipairs(items) do
            add_script_throw(item)
        end

        if player_object.damage_frame == GameGetFrameNum() then
            player_object.damage_model_.wait_for_kill_flag_on_death = false
            if player_object.damage_model_.hp < 0 then
                player_object:set_dead(true)
            end
        end
    end

    for i, player in ipairs(players_including_disabled) do
        local player_object = Player(player)
        if not player_object.damage_model_._enabled then
            GamePlayAnimation(player, "intro_sleep", 0x7FFFFFFF)
        end
        local arm_r = player_object:get_arm_r()
        if arm_r ~= nil and player_object.sprite ~= nil then
            local intro = player_object.sprite.rect_animation == "intro_sleep" or player_object.sprite.rect_animation == "intro_stand_up"
            EntitySetName(arm_r, intro and "" or "arm_r")
            EntitySetComponentsWithTagEnabled(arm_r, "with_item", not intro)
        end
        if player_object.aiming_reticle ~= nil then
            local aim, aim_unbound, aim_emulated = player_object:mnin_stick("aim")
            player_object.aiming_reticle.visible = not aim_unbound and not player_object:is_inventory_open() and player_object.damage_model_._enabled
        end
    end

    if #players < 1 then
        local damaged_players = table.copy(players_including_disabled)
        table.sort(damaged_players, function(a, b)
            return Player(a).damage_frame > Player(b).damage_frame
        end)
        for i, player in ipairs(damaged_players) do
            local player_object = Player(player)
            player_object.damage_model_._enabled = true
            player_object.damage_model_.wait_for_kill_flag_on_death = false
            player_object.damage_model_.hp = 0
            player_object.damage_model_.ui_report_damage = false
            local damage_message = player_object.damage_message
            if player_object.damage_responsible ~= "" then
                damage_message = GameTextGet("$menugameover_causeofdeath_killer_cause", GameTextGetTranslatedOrNot(player_object.damage_responsible), GameTextGetTranslatedOrNot(damage_message))
            end
            EntityInflictDamage(player, 0.04, "NONE", damage_message, "NO_RAGDOLL_FILE", 0, 0)
            player_object.damage_model_.kill_now = true
            player_object.damage_model_.wait_for_kill_flag_on_death = true
            player_object.damage_model_.ragdoll_fx_forced = "NO_RAGDOLL_FILE"
            player_object.log_.report_death = false
        end
    end

    for i, player in ipairs(players_including_disabled) do
        EntityRemoveFromParent(player)
    end
end

local on_bound_frames = {}
local function update_camera()
    local camera_center_player = get_player_at_index(mod.camera_center_index)
    local camera_center_player_object = Player(camera_center_player)
    local players = get_players()
    if mnee.mnin_bind("iota_multiplayer", "switch_player", true) or camera_center_player == nil then
        local entities = camera_center_player ~= nil and table.filter(players, function(v)
            return Player(v).index > camera_center_player_object.index
        end) or {}
        entities = #entities > 0 and entities or players
        local next_camera_center_player = table.iterate(entities, function(a, b)
            return Player(a).index < Player(b).index
        end)
        if next_camera_center_player ~= nil then
            local next_camera_center_player_object = Player(next_camera_center_player)
            mod.camera_center_index = next_camera_center_player_object.index
            next_camera_center_player_object.shooter_.mSmoothedCameraPosition = camera_center_player_object.shooter_.mSmoothedCameraPosition
            next_camera_center_player_object.shooter_.mSmoothedAimingVector = camera_center_player_object.shooter_.mSmoothedAimingVector
            next_camera_center_player_object.shooter_.mDesiredCameraPos = camera_center_player_object.shooter_.mDesiredCameraPos
        end
    end
    local players_including_disabled = get_players_including_disabled()
    for i, player in ipairs(players_including_disabled) do
        local player_object = Player(player)
        player_object.listener_._enabled = player_object.index == mod.camera_center_index
    end

    camera_center_player = get_player_at_index(mod.camera_center_index)
    camera_center_player_object = Player(camera_center_player)
    if mnee.mnin_bind("iota_multiplayer", "toggle_teleport", true) then
        if mnee.mnin_key("left_shift") then
            for i, player in ipairs(players) do
                local player_object = Player(player)
                if player_object.index ~= mod.camera_center_index then
                    local from_x, from_y = EntityGetTransform(player)
                    teleport(player, from_x, from_y, EntityGetTransform(camera_center_player))
                end
            end
        else
            mod.auto_teleport = not mod.auto_teleport
            GamePrint(table.concat{GameTextGet("$action_teleportation"), " ", GameTextGet(mod.auto_teleport and "$option_on" or "$option_off")})
        end
    end
    if mod.auto_teleport and camera_center_player ~= nil then
        local center_x, center_y = camera_center_player_object:get_camera_pos()
        local min_resolution_x, min_resolution_y = tonumber(magic_numbers.VIRTUAL_RESOLUTION_X) * ModSettingGet("iota_multiplayer.camera_zoom_min"), tonumber(magic_numbers.VIRTUAL_RESOLUTION_Y) * ModSettingGet("iota_multiplayer.camera_zoom_min")
        local max_resolution_x, max_resolution_y = tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_X")), tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_Y"))
        local shrink_width = max_resolution_x - min_resolution_x * 0.5
        local shrink_height = max_resolution_y - min_resolution_y * 0.5
        local left = center_x - shrink_width
        local right = center_x + shrink_width
        local top = center_y - shrink_height
        local bottom = center_y + shrink_height
        for i, player in ipairs(players) do
            local player_object = Player(player)
            if player_object.index ~= mod.camera_center_index then
                local bound_left = left - (player_object.character_data_.collision_aabb_min_x or 0)
                local bound_right = right - (player_object.character_data_.collision_aabb_max_x or 0)
                local bound_top = top - (player_object.character_data_.collision_aabb_min_y or 0)
                local bound_bottom = bottom - (player_object.character_data_.collision_aabb_max_y or 0)
                local pos_x, pos_y = EntityGetTransform(player)
                local bound_x = clamp(pos_x, bound_left, bound_right) - pos_x
                local bound_y = clamp(pos_y, bound_top, bound_bottom) - pos_y
                if bound_x ~= 0 then
                    player_object.character_data_.mVelocity_[1] = bound_x * 60
                end
                if bound_y ~= 0 then
                    player_object.character_data_.mVelocity_[2] = bound_y * 60
                end
                bound_left = left - (player_object.character_data_.collision_aabb_max_x or 0)
                bound_right = right - (player_object.character_data_.collision_aabb_min_x or 0)
                bound_top = top - (player_object.character_data_.collision_aabb_max_y or 0)
                bound_bottom = bottom - (player_object.character_data_.collision_aabb_min_y or 0)
                local frame = GameGetFrameNum()
                if pos_x > bound_left and pos_x < bound_right and pos_y > bound_top and pos_y < bound_bottom or on_bound_frames[player_object.index] == nil then
                    on_bound_frames[player_object.index] = frame
                end
                if frame - on_bound_frames[player_object.index] > 60 and (camera_center_player_object.collision_.stuck_in_ground_counter or 0) < 1 then
                    on_bound_frames[player_object.index] = frame
                    local from_x, from_y = EntityGetTransform(player)
                    teleport(player, from_x, from_y, EntityGetTransform(camera_center_player))
                    player_object.character_data_.mVelocity = {0, 0}
                end
            end
        end
    end

    local first_player = get_player_at_index_including_disabled(1)
    if first_player ~= nil and #players > 0 then
        local first_player_object = Player(first_player)
        local camera_x, camera_y, camera_zoom = get_camera_info()
        if first_player_object.shooter == nil then
            EntityAddComponent2(first_player, "PlatformShooterPlayerComponent")
        end
        first_player_object.shooter.mDesiredCameraPos = {camera_x, camera_y}
        GameSetPostFxParameter("camera_zoom", camera_zoom, camera_zoom, camera_zoom, camera_zoom)
    end
    if receiver ~= nil then
        ComponentSetValue2(receiver, "mLastFrameElectrified", get_frame_num_next())
    end
end

local previous_aims = {}
local function mnin_stick_raw(mod_id, bind_id, pressed_mode, is_vip, inmode)
    local abort_tbl = {{0, 0}, false, {false, false}, 0}
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
    return {math.min(val_x, 1), math.min(val_y, 1)}, gone_x or gone_y, {buttoned_x, buttoned_y}, direction
end
local function is_pressed(a, b, emulated)
    return (a ~= b or not emulated) and b ~= 0
end
local function update_controls()
    local players = get_players_including_disabled()
    for i, player in ipairs(players) do
        local player_object = Player(player)
        player_object.controls_.enabled = false
        if player_object.controls == nil or not player_object.damage_model_._enabled or player_object.sprite_.rect_animation == "intro_stand_up" then
            goto continue
        end

        player_object.controls.mButtonDownFire = player_object:mnin_bind("usewand", false, false, "guied")
        if player_object:mnin_bind("usewand", true, false, "guied") then
            player_object.controls.mButtonFrameFire = get_frame_num_next()
        end
        if player_object.controls.mButtonDownFire then
            player_object.controls.mButtonLastFrameFire = get_frame_num_next()
        end
        if player_object.controls.polymorph_hax and player_object.controls.polymorph_next_attack_frame <= get_frame_num_next() and player_object.controls.mButtonFrameFire == get_frame_num_next() then
            local ai = EntityGetFirstComponentIncludingDisabled(player, "AnimalAIComponent")
            local attacks = EntityGetComponent(player, "AIAttackComponent") or {}
            local attack_info = get_attack_info(player, ai, attacks)
            local controls = EntityGetFirstComponent(player, "ControlsComponent")
            if controls ~= nil and attack_info.entity_file ~= nil then
                local x, y = get_attack_ranged_pos(player, attack_info)
                local aiming_vector_x, aiming_vector_y = ComponentGetValue2(controls, "mAimingVector")
                local projectile_entity = EntityLoad(attack_info.entity_file, x, y)
                GameShootProjectile(player, x, y, x + aiming_vector_x, y + aiming_vector_y, projectile_entity)
            end
            player_object.controls.polymorph_next_attack_frame = get_frame_num_next() + attack_info.frames_between
        end

        player_object.controls.mButtonDownFire2 = player_object:mnin_bind("sprayflask", false, false, "guied")
        if player_object:mnin_bind("sprayflask", true, false, "guied") then
            player_object.controls.mButtonFrameFire2 = get_frame_num_next()
        end

        local throw, throw_unbound, throw_jpad = player_object:mnin_bind("throw", false, false, "guied")
        player_object.controls.mButtonDownThrow = throw and not (throw_jpad and player_object:is_inventory_open())
        if player_object:mnin_bind("throw", true, false, "guied") and player_object.controls.mButtonDownThrow then
            player_object.controls.mButtonFrameThrow = get_frame_num_next()
        end

        local interact, interact_unbound, interact_jpad = player_object:mnin_bind("interact")
        interact = interact and not (interact_jpad and player_object:is_inventory_open())
        if interact and not player_object.controls.mButtonDownInteract then
            player_object.controls.mButtonFrameInteract = get_frame_num_next()
        end
        player_object.controls.mButtonDownInteract = interact

        local left, left_unbound, left_jpad = player_object:mnin_bind("left")
        player_object.controls.mButtonDownLeft = left and not (left_jpad and player_object:is_inventory_open())
        if player_object:mnin_bind("left", true) and player_object.controls.mButtonDownLeft then
            player_object.controls.mButtonFrameLeft = get_frame_num_next()
        end

        local right, right_unbound, right_jpad = player_object:mnin_bind("right")
        player_object.controls.mButtonDownRight = right and not (right_jpad and player_object:is_inventory_open())
        if player_object:mnin_bind("right", true) and player_object.controls.mButtonDownRight then
            player_object.controls.mButtonFrameRight = get_frame_num_next()
        end

        local up, up_unbound, up_jpad = player_object:mnin_bind("up")
        player_object.controls.mButtonDownUp = up and not (up_jpad and player_object:is_inventory_open())
        if player_object:mnin_bind("up", true) and player_object.controls.mButtonDownUp then
            player_object.controls.mButtonFrameUp = get_frame_num_next()
        end

        local down, down_unbound, down_jpad = player_object:mnin_bind("down")
        player_object.controls.mButtonDownDown = down and not (down_jpad and player_object:is_inventory_open())
        if player_object:mnin_bind("down", true) and player_object.controls.mButtonDownDown then
            player_object.controls.mButtonFrameDown = get_frame_num_next()
        end

        player_object.controls.mButtonDownFly = player_object:mnin_bind("up")
        if player_object:mnin_bind("up", true) then
            player_object.controls.mButtonFrameFly = get_frame_num_next()
        end

        local unscroll = ModTextFileGetContent("mods/spell_lab_shugged/scroll_box_hovered.txt") == "true"
			or tonumber( GlobalsGetValue( pen.GLOBAL_UNSCROLLER_SAFETY, "0" )) == GameGetFrameNum()
        player_object.controls.mButtonDownChangeItemR = player_object:mnin_bind("itemnext") and not(unscroll)
        if player_object:mnin_bind("itemnext", true) and player_object.controls.mButtonDownChangeItemR then
            player_object.controls.mButtonFrameChangeItemR = get_frame_num_next()
            player_object.controls.mButtonCountChangeItemR = 1
        else
            player_object.controls.mButtonCountChangeItemR = 0
        end

        player_object.controls.mButtonDownChangeItemL = player_object:mnin_bind("itemprev") and not(unscroll)
        if player_object:mnin_bind("itemprev", true) and player_object.controls.mButtonDownChangeItemL then
            player_object.controls.mButtonFrameChangeItemL = get_frame_num_next()
            player_object.controls.mButtonCountChangeItemL = 1
        else
            player_object.controls.mButtonCountChangeItemL = 0
        end

        player_object.controls.mButtonDownInventory = player_object:mnin_bind("inventory")
        if player_object:mnin_bind("inventory", true) then
            player_object.controls.mButtonFrameInventory = get_frame_num_next()
        end

        player_object.controls.mButtonDownDropItem = player_object:mnin_bind("dropitem") and player_object:is_inventory_open()
        if player_object:mnin_bind("dropitem", true) and player_object.controls.mButtonDownDropItem then
            player_object.controls.mButtonFrameDropItem = get_frame_num_next()
        end

        local kick, kick_unbound, kick_jpad = player_object:mnin_bind("kick")
        player_object.controls.mButtonDownKick = kick and not (kick_jpad and player_object:is_inventory_open())
        if player_object:mnin_bind("kick", true) and player_object.controls.mButtonDownKick then
            player_object.controls.mButtonFrameKick = get_frame_num_next()
        end

        player_object.controls.mButtonDownLeftClick = player_object.index == 1 and mnee.mnin_key("mouse_left", false, false, "guied")
        if mnee.mnin_key("mouse_left", true, false, "guied") and player_object.controls.mButtonDownLeftClick then
            player_object.controls.mButtonFrameLeftClick = get_frame_num_next()
        end

        player_object.controls.mButtonDownRightClick = player_object.index == 1 and mnee.mnin_key("mouse_right", false, false, "guied")
        if mnee.mnin_key("mouse_right", true, false, "guied") and player_object.controls.mButtonDownRightClick then
            player_object.controls.mButtonFrameRightClick = get_frame_num_next()
        end

        player_object.controls.mFlyingTargetY = select(2, EntityGetTransform(player)) - 10

        local aim, aim_unbound, aim_emulated = player_object:mnin_stick("aim")
        local CONTROLS_AIMING_VECTOR_FULL_LENGTH_PIXELS = tonumber(MagicNumbersGetValue("CONTROLS_AIMING_VECTOR_FULL_LENGTH_PIXELS"))
        if aim_unbound then
            local mouse_position_raw_x, mouse_position_raw_y = InputGetMousePosOnScreen()
            local mouse_position_x, mouse_position_y = get_pos_in_world(mouse_position_raw_x, mouse_position_raw_y)
            local center_x, center_y = EntityGetFirstHitboxCenter(player)
            local aiming_vector_x, aiming_vector_y = mouse_position_x - center_x, mouse_position_y - center_y
            local magnitude = math.max(math.sqrt(aiming_vector_x * aiming_vector_x + aiming_vector_y * aiming_vector_y), CONTROLS_AIMING_VECTOR_FULL_LENGTH_PIXELS)
            local aiming_vector_normalized_x, aiming_vector_normalized_y = aiming_vector_x / magnitude, aiming_vector_y / magnitude
            player_object.controls.mAimingVector = {aiming_vector_x, aiming_vector_y}
            player_object.controls.mAimingVectorNormalized = {aiming_vector_normalized_x, aiming_vector_normalized_y}
            local mouse_position_raw_prev = player_object.controls.mMousePositionRaw
            player_object.controls.mMousePosition = {mouse_position_x, mouse_position_y}
            player_object.controls.mMousePositionRaw = {mouse_position_raw_x, mouse_position_raw_y}
            player_object.controls.mMousePositionRawPrev = mouse_position_raw_prev
            player_object.controls.mMouseDelta = {mouse_position_raw_x - mouse_position_raw_prev[1], mouse_position_raw_y - mouse_position_raw_prev[2]}
            goto continue
        end
        local aim_raw = mnin_stick_raw("iota_multiplayer" .. player_object.index, "aim")
        if player_object:is_inventory_open() then
            aim = {0, 0}
            aim_raw = {0, 0}
        end
        local aiming_vector_non_zero_latest = player_object.controls.mAimingVectorNonZeroLatest
        if is_pressed((previous_aims[player_object.index] or {0, 0})[1], aim_raw[1], aim_emulated[1]) or is_pressed((previous_aims[player_object.index] or {0, 0})[2], aim_raw[2], aim_emulated[2]) then
            aiming_vector_non_zero_latest = aim
        end
        previous_aims[player_object.index] = aim_raw
        player_object.controls.mAimingVector = {aiming_vector_non_zero_latest[1] * CONTROLS_AIMING_VECTOR_FULL_LENGTH_PIXELS, aiming_vector_non_zero_latest[2] * CONTROLS_AIMING_VECTOR_FULL_LENGTH_PIXELS}
        player_object.controls.mAimingVectorNormalized = aim
        player_object.controls.mAimingVectorNonZeroLatest = aiming_vector_non_zero_latest
        player_object.controls.mGamepadAimingVectorRaw = aim
        local mouse_position = player_object.controls.mGamePadCursorInWorld
        local mouse_position_raw_x, mouse_position_raw_y = get_pos_on_screen(mouse_position())
        local mouse_position_raw_prev = player_object.controls.mMousePositionRaw
        player_object.controls.mMousePosition = mouse_position
        player_object.controls.mMousePositionRaw = {mouse_position_raw_x, mouse_position_raw_y}
        player_object.controls.mMousePositionRawPrev = mouse_position_raw_prev
        player_object.controls.mMouseDelta = {mouse_position_raw_x - mouse_position_raw_prev[1], mouse_position_raw_y - mouse_position_raw_prev[2]}
        ::continue::
    end
end

local function pred_filename(...)
    local filenames = {...}
    return function(v)
        for i, filename in ipairs(filenames) do
            if filename == EntityGetFilename(v) then
                return true
            end
        end
    end
end
local function pred_tag(...)
    local tags = {...}
    return function(v)
        for i, tag in ipairs(tags) do
            if EntityHasTag(v, tag) then
                return true
            end
        end
    end
end
local Share = Entity{shared_indexs = SerializedField(VariableField("iota_multiplayer.shared_indexs", "value_string", "{}"))}
local item_list = {
    {
        pred = pred_filename("data/entities/items/pickup/heart_fullhp_temple.xml", "data/entities/items/pickup/spell_refresh.xml"),
        is_pickable = function(v, is_pickable, picker) return is_pickable and not table.find(Share(v).shared_indexs, Player(picker).index) end,
    },
    {
        pred = pred_tag("iota_multiplayer.player"),
        is_pickable = function(v, is_pickable)
            local object = Player(v)
            return is_pickable or not object.damage_model_._enabled and object.gui ~= nil and not object:is_inventory_open()
        end,
        ui_name = "$iota_multiplayer.item_corpse",
        custom_pickup_string = "$itempickup_open",
        func = function(v, pickupper)
            Player(v).controls_.mButtonFrameInventory = get_frame_num_next()
            mod.gui_owner_index = Player(pickupper).index
        end,
    },
    {
        pred = pred_tag("coop_respawn"),
        is_pickable = function(v, is_pickable)
            local shared_indexs = Share(v).shared_indexs
            local dead_players = table.filter(get_players_including_disabled(), function(v) return not Player(v).damage_model_._enabled end)
            for i, dead_player in ipairs(dead_players) do
                is_pickable = is_pickable or not table.find(shared_indexs, Player(dead_player).index)
            end
            return is_pickable
        end,
        item_pickup_radius = 100,
        ui_name = "$iota_multiplayer.item_resurrect",
        custom_pickup_string = "$iota_multiplayer.itempickup_use",
    },
}
local function get_item_data(v)
    for i, item_data in ipairs(item_list) do
        if item_data.pred(v) then
            return item_data
        end
    end
end
local function fetch(v, ...)
    if type(v) == "function" then return v(...) end
    return v, ...
end
local function get_picked(picker)
    return table.iterate(table.filter(EntityGetInRadius(0, 0, math.huge), function(v)
        local item = EntityGetFirstComponent(v, "ItemComponent")
        local is_pickable = item and ComponentGetValue2(item, "is_pickable") and not validate(EntityGetParent(v))
        local item_pickup_radius = item and math.min(ComponentGetValue2(item, "item_pickup_radius"), 14.1)

        local item_data = get_item_data(v)
        if item_data ~= nil then
            if item_data.is_pickable ~= nil then
                is_pickable = fetch(item_data.is_pickable, v, is_pickable, picker)
            elseif is_pickable == nil then
                is_pickable = true
            end
            if item_data.item_pickup_radius ~= nil then
                item_pickup_radius = fetch(item_data.item_pickup_radius)
            elseif item_pickup_radius == nil then
                item_pickup_radius = 14.1
            end
        end

        local x, y = EntityGetTransform(v)
        local distance2 = get_distance2(x, y, EntityGetTransform(picker))
        return is_pickable and distance2 <= item_pickup_radius * item_pickup_radius
    end), function(a, b)
        local ax, ay = EntityGetTransform(a)
        local a_distance2 = get_distance2(ax, ay, EntityGetTransform(picker))
        local bx, by = EntityGetTransform(b)
        local b_distance2 = get_distance2(bx, by, EntityGetTransform(picker))
        return a_distance2 < b_distance2
    end)
end
local function update_pickup()
    local players = get_players()
    local players_including_disabled = get_players_including_disabled()
    for i, player in ipairs(players) do
        local player_object = Player(player)
        local item = get_picked(player)
        player_object.pickupper_.only_pick_this_entity = -1
        if item ~= nil and EntityGetComponent(item, "ItemComponent") ~= nil then
            player_object.pickupper_.only_pick_this_entity = item
        end
        local item_data = get_item_data(item)
        if item_data ~= nil and player_object.controls_.mButtonFrameInteract == get_frame_num_next() then
            fetch(item_data.func, item, player)
        end

        if EntityHasTag(item, "coop_respawn") then
            local coop_respawn = item
            local coop_respawn_object = Share(coop_respawn)
            local shared_indexs = coop_respawn_object.shared_indexs
            local dead_players = table.filter(players_including_disabled, function(v) return not Player(v).damage_model_._enabled end)
            for i, dead_player in ipairs(dead_players) do
                local dead_player_object = Player(dead_player)
                if dead_player_object:mnin_bind("interact", true) and not table.find(shared_indexs, dead_player_object.index) then
                    table.insert(shared_indexs, dead_player_object.index)
                    coop_respawn_object.shared_indexs = shared_indexs

                    dead_player_object:set_dead(false)
                    local from_x, from_y = EntityGetTransform(dead_player)
                    local to_x, to_y = EntityGetTransform(coop_respawn)
                    teleport(dead_player, from_x, from_y, to_x, to_y)
                end
            end
        end
    end
end

local gui_uninitialized = true
local previous_gui_enabled_player
local function get_quick_slot(entity)
    local item = EntityGetFirstComponentIncludingDisabled(entity, "ItemComponent")
    local ability = EntityGetFirstComponentIncludingDisabled(entity, "AbilityComponent")
    return (item and ComponentGetValue2(item, "inventory_slot") or 0) + (ability and ComponentGetValue2(ability, "use_gun_script") and 0 or 4)
end
local function block_item_select(player)
    local quick_inventory = table.find(get_children(player), function(v) return EntityGetName(v) == "inventory_quick" end)
    local items = get_children(quick_inventory)
    for i, item in ipairs(items) do
        local item = EntityGetFirstComponentIncludingDisabled(item, "ItemComponent")
        if item ~= nil then
            ComponentSetValue2(item, "inventory_slot", -1, 0)
        end
    end
end
local function update_gui()
    local gui_enabled_player = get_player_gui_enabled()
    local gui_enabled_player_object = Player(gui_enabled_player)
    local next_gui_enabled_player = gui_enabled_player
    if gui_enabled_player == nil or not gui_enabled_player_object:is_inventory_open() then
        next_gui_enabled_player = get_player_at_index(mod.camera_center_index)
    end
    if previous_gui_enabled_player ~= nil then
        next_gui_enabled_player = previous_gui_enabled_player
        previous_gui_enabled_player = nil
    end
    local players_including_disabled = get_players_including_disabled()
    for i, player in ipairs(players_including_disabled) do
        local player_object = Player(player)
        if player_object.controls_.mButtonFrameInventory == get_frame_num_next() then
            if player_object.index == mod.gui_owner_index then
                gui_enabled_player_object.controls_.mButtonFrameInventory = get_frame_num_next()
            elseif player_object.gui ~= nil then
                next_gui_enabled_player = player
            end
        end
        if player_object.index == mod.gui_owner_index then
            gui_enabled_player_object.controls_.mButtonDownDropItem = player_object.controls_.mButtonDownDropItem
            if player_object.controls_.mButtonFrameDropItem == get_frame_num_next() then
                gui_enabled_player_object.controls_.mButtonFrameDropItem = get_frame_num_next()
            end
        end
    end

    if next_gui_enabled_player ~= gui_enabled_player then
        local next_gui_enabled_player_object = Player(next_gui_enabled_player)
        if gui_enabled_player_object.gui ~= nil then
            next_gui_enabled_player_object.gui_.wallet_money_target = gui_enabled_player_object.gui.wallet_money_target
            remove_component(gui_enabled_player_object.gui._id)
            EntityAddComponent2(gui_enabled_player, "InventoryGuiComponent")
        end
        if next_gui_enabled_player_object.damage_model_._enabled then
            mod.gui_owner_index = nil
        end
    end

    if gui_uninitialized then
        gui_uninitialized = false
        for i, player in ipairs(players_including_disabled) do
            local player_object = Player(player)
            if player_object.gui ~= nil then
                remove_component(player_object.gui._id)
                EntityAddComponent2(player, "InventoryGuiComponent")
            end
        end
    end

    local interactor = table.find(players_including_disabled, function(v)
        local object = Player(v)
        return object.controls_.mButtonFrameInteract == get_frame_num_next() and validate(object.pickupper_.only_pick_this_entity) and object.index ~= mod.gui_owner_index
    end)
    if interactor ~= nil then
        local interactor_object = Player(interactor)
        local next_gui_enabled_player_object = Player(next_gui_enabled_player)
        interactor_object.gui_.mBackgroundOverlayAlpha = (next_gui_enabled_player_object.gui_.mBackgroundOverlayAlpha or 0) * 1.1320754716981132 --1 / (1 - 7 / 60)
        interactor_object.gui_.wallet_money_target = next_gui_enabled_player_object.gui_.wallet_money_target
        previous_gui_enabled_player = next_gui_enabled_player
        next_gui_enabled_player = interactor
    end
    for i, player in ipairs(players_including_disabled) do
        local player_object = Player(player)
        player_object.gui_._enabled = player == next_gui_enabled_player
    end

    local players = get_players()
    for i, player in ipairs(players) do
        local player_object = Player(player)
        for i = 1, 8 do
            if player_object:mnin_bind("itemslot" .. i, true) then
                local quick_inventory = table.find(get_children(player), function(v) return EntityGetName(v) == "inventory_quick" end)
                local items = get_children(quick_inventory)
                local slots = {}
                for i, item in ipairs(items) do
                    local slot = get_quick_slot(item)
                    for k, v in pairs(slots) do
                        if v == slot then
                            slot = slot + 1
                        end
                    end
                    slots[item] = slot
                end
                table.sort(items, function(a, b)
                    return slots[a] < slots[b]
                end)
                for j, item in ipairs(items) do
                    if slots[item] == i - 1 and player_object.inventory_.mSavedActiveItemIndex ~= j - 1 then
                        player_object.inventory_.mSavedActiveItemIndex = j - 1
                        player_object.inventory_.mInitialized = false
                        player_object.inventory_.mForceRefresh = true
                        GamePlaySound("data/audio/Desktop/ui.bank", "ui/item_equipped", nil, nil)
                    end
                end
            end
        end
    end
    local next_gui_enabled_player_object = Player(next_gui_enabled_player)
    local diff = (next_gui_enabled_player_object.controls_.mButtonFrameInteract or 0) - GameGetFrameNum()
    if not next_gui_enabled_player_object:is_inventory_open() and (diff < 0 or diff > 1) then
        block_item_select(next_gui_enabled_player)
    end
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
local previous_picked = false
local function window_new(gui)
    return {gui = gui, ids = {}, id = 0xFFFFFFFFFFFF}
end
local function widget_list_begin(window, z)
    GuiStartFrame(window.gui)
    return {window = window, z = z, widgets = {}, counts = {}}
end
local function widget_list_insert(widget_list, ...)
    table.insert(widget_list.widgets, {...})
end
local function widget_list_end(widget_list)
    for i, widget in ipairs(widget_list.widgets) do
        if widget_list.z ~= nil then
            GuiZSetForNextWidget(widget_list.window.gui, #widget_list.widgets - i + widget_list.z)
        end
        widget[1](widget_list.window.gui, unpack(widget, 2))
    end
end
local function widget_list_id(widget_list, f)
    local line = jit.util.funcinfo(f).currentline

    local count = widget_list.counts[line]
    if count == nil then
        count = 0
    else
        count = count + 1
    end
    widget_list.counts[line] = count

    local k = bit.bor(line, bit.lshift(count, 16))

    local id = widget_list.window.ids[k]
    if id == nil then
        id = widget_list.window.id
        widget_list.window.id = id - 1
        widget_list.window.ids[k] = id
    end

    return id
end
local window = window_new(gui)
local function update_window()
    local players_including_disabled = get_players_including_disabled()
    if #players_including_disabled < 2 then return end
    local widget_list = widget_list_begin(window, 1001)

    local players = get_players()
    for i, player in ipairs(players) do
        local player_object = Player(player)
        local player_x, player_y = EntityGetTransform(player)
        player_y = player_y + (player_object.hitbox_.aabb_max_y or 0)

        local x, y = get_pos_on_screen(player_x, player_y, gui)
        widget_list_insert(widget_list, function(gui, x, y)
            GuiOptionsAddForNextWidget(gui, GUI_OPTION.Align_HorizontalCenter)
            GuiText(gui, x, y, "P" .. player_object.index)
        end, x, y)

        x = x + 6
        y = y + 3
        local width = 4
        local height = 4
        widget_list_insert(widget_list, GuiImageNinePiece, widget_list_id(widget_list, function() end), x, y, width, height, 1, "mods/iota_multiplayer/files/ui_gfx/hud/bar_bg.png")

        if player_object.damage_model ~= nil then
            local ratio = player_object.damage_model.hp / player_object.damage_model.max_hp
            widget_list_insert(widget_list, GuiImage, widget_list_id(widget_list, function() end), x, y, "data/ui_gfx/hud/colors_health_bar.png", 1, width * 0.5 * ratio, height * 0.5)
        end
        if player_object.character_data ~= nil and player_object.character_data.mFlyingTimeLeft < player_object.character_data.fly_time_max then
            local ratio = player_object.character_data.mFlyingTimeLeft / player_object.character_data.fly_time_max
            widget_list_insert(widget_list, GuiImage, widget_list_id(widget_list, function() end), x, y + height * ratio, "data/ui_gfx/hud/colors_flying_bar.png", 1, width * 0.5, height * 0.5 * (1 - ratio))
        end

        local camera_x, camera_y = GameGetCameraPos()
        local camera_zoom = select(3, get_camera_info())
        local resolution_x, resolution_y = tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_X")) * camera_zoom * 0.5, tonumber(MagicNumbersGetValue("VIRTUAL_RESOLUTION_Y")) * camera_zoom * 0.5
        local left = camera_x - resolution_x
        local right = camera_x + resolution_x
        local up = camera_y - resolution_y
        local down = camera_y + resolution_y
        left, up = get_pos_on_screen(left, up, gui)
        right, down = get_pos_on_screen(right, down, gui)
        local cursor_x, cursor_y = get_pos_on_screen(player_x, player_y, gui)
        local cursor_width, cursor_height = GuiGetImageDimensions(gui, "mods/iota_multiplayer/files/ui_gfx/cursor.png")
        local cursor_x_clamped, cursor_y_clamped = clamp(cursor_x, left + cursor_height * 0.5, right - cursor_height * 0.5), clamp(cursor_y, up + cursor_height * 0.5, down - cursor_height * 0.5)
        if cursor_x_clamped ~= cursor_x or cursor_y_clamped ~= cursor_y then
            local rotation = math.atan2(cursor_y - cursor_y_clamped, cursor_x - cursor_x_clamped)
            x, y = vec_sub(cursor_x_clamped, cursor_y_clamped, vec_rotate(cursor_width, cursor_height * 0.5, rotation))
            widget_list_insert(widget_list, GuiImage, widget_list_id(widget_list, function() end), x, y, "mods/iota_multiplayer/files/ui_gfx/cursor.png", 1, 1, 1, rotation)

            local mouse_x, mouse_y = InputGetMousePosOnScreen()
            mouse_x, mouse_y = vec_mult(mouse_x, mouse_y, 0.5)
            if get_distance2(mouse_x, mouse_y, cursor_x_clamped, cursor_y_clamped) < 256 then
                x, y = vec_sub(cursor_x, cursor_y, cursor_x_clamped, cursor_y_clamped)
                x, y = vec_sub(cursor_x_clamped, cursor_y_clamped, vec_mult(x, y, 16 / vec_length(x, y)))
                y = y - select(2, GuiGetTextDimensions(gui, "P" .. player_object.index)) * 0.5
                widget_list_insert(widget_list, function(gui, x, y)
                    GuiOptionsAddForNextWidget(gui, GUI_OPTION.Align_HorizontalCenter)
                    GuiText(gui, x, y, "P" .. player_object.index)
                end, x, y)
            end
        end
    end

    local x, y = tonumber(MagicNumbersGetValue("UI_BARS_POS_X")) - 1, tonumber(MagicNumbersGetValue("UI_BARS_POS_Y"))
    local box_width, box_height = GuiGetImageDimensions(gui, "data/ui_gfx/inventory/quick_inventory_box.png")
    GuiImage(gui, 1, 0, 0, "data/ui_gfx/inventory/highlight.xml")
    local highlight_width, highlight_height = select(6, GuiGetPreviousWidgetInfo(gui))
    local gui_enabled_player = get_player_gui_enabled()
    table.sort(players, function(a, b)
        local a_object = Player(a)
        local b_object = Player(b)
        return a_object.index < b_object.index or a == gui_enabled_player
    end)
    for i, player in ipairs(players) do
        if player == gui_enabled_player or not GameIsInventoryOpen() then
            local text = "P" .. Player(player).index
            local x, y = x - box_width * 0.5, y + box_height * 0.5
            y = y - select(2, GuiGetTextDimensions(gui, text)) * 0.5
            widget_list_insert(widget_list, function(gui, x, y)
                GuiOptionsAddForNextWidget(gui, GUI_OPTION.Align_HorizontalCenter)
                GuiText(gui, x, y, text)
            end, x, y)
        end
        if player ~= gui_enabled_player and not GameIsInventoryOpen() then
            local player_object = Player(player)
            local quick_inventory = table.find(get_children(player), function(v) return EntityGetName(v) == "inventory_quick" end)
            local items = get_children(quick_inventory)
            local slots = {}
            for i, item in ipairs(items) do
                local slot = get_quick_slot(item)
                for k, v in pairs(slots) do
                    if v == slot then
                        slot = slot + 1
                    end
                end
                slots[item] = slot
            end
            do
                local x = x
                for i = 0, 7 do
                    widget_list_insert(widget_list, function(gui, x, y)
                        GuiOptionsAddForNextWidget(gui, GUI_OPTION.NonInteractive)
                        GuiImage(gui, widget_list_id(widget_list, function() end), x, y, "data/ui_gfx/inventory/quick_inventory_box.png", 1, 1)
                    end, x, y)
                    if i == slots[player_object.inventory_.mActiveItem] then
                        local x, y = x + (highlight_width + 1) * 0.5, y + (highlight_height + 1) * 0.5
                        widget_list_insert(widget_list, function(gui, x, y)
                            GuiOptionsAddForNextWidget(gui, GUI_OPTION.NonInteractive)
                            GuiImage(gui, widget_list_id(widget_list, function() end), x, y, "data/ui_gfx/inventory/highlight.xml", 1, 1, 0, 0, GUI_RECT_ANIMATION_PLAYBACK.Loop)
                        end, x, y)
                    end
                    x = x + box_width
                    if i == 3 then
                        x = x + 1
                    end
                end
            end
            for i, item in ipairs(items) do
                local slot = slots[item]
                local x, y = x + slot * box_width, y
                x, y = vec_add(x, y, vec_mult(box_width, box_height, 0.5))
                if slot > 3 then
                    x = x + 1
                end
                local item_component = EntityGetFirstComponentIncludingDisabled(item, "ItemComponent")
                local ability_component = EntityGetFirstComponentIncludingDisabled(item, "AbilityComponent")
                local sprite_filename = item_component and ComponentGetValue2(item_component, "ui_sprite") or ""
                if sprite_filename == "" and ability_component ~= nil then
                    sprite_filename = ComponentGetValue2(ability_component, "sprite_file")
                end
                if sprite_filename ~= "" then
                    if not sprite_filename:find(".xml$") then
                        local width, height = GuiGetImageDimensions(gui, sprite_filename)
                        x, y = vec_sub(x, y, vec_mult(width, height, 0.5))
                    end
                    widget_list_insert(widget_list, function(gui, x, y)
                        GuiOptionsAddForNextWidget(gui, GUI_OPTION.NonInteractive)
                        local material_inventory = EntityGetFirstComponentIncludingDisabled(item, "MaterialInventoryComponent")
                        if material_inventory ~= nil then
                            local color = GameGetPotionColorUint(item)
                            local red = bit.band(color, 0xFF) / 0xFF
                            local green = bit.band(bit.rshift(color, 8), 0xFF) / 0xFF
                            local blue = bit.band(bit.rshift(color, 16), 0xFF) / 0xFF
                            local alpha = bit.rshift(color, 24) / 0xFF
                            GuiColorSetForNextWidget(gui, red, green, blue, alpha)
                        end
                        GuiImage(gui, widget_list_id(widget_list, function() end), x, y, sprite_filename, 1, 1, 0, 0, GUI_RECT_ANIMATION_PLAYBACK.Loop)
                    end, x, y)
                end
            end
        end
        y = y + 24
    end

    local picked = false
    local screen_width, screen_height = GuiGetScreenDimensions(gui)
    local x, y = screen_width * 0.5, screen_height - 40
    for i, player in ipairs(players) do
        local item = get_picked(player)
        if item ~= nil then
            picked = true
            if EntityGetComponent(item, "ItemComponent") == nil then
                widget_list_insert(widget_list, GuiAnimateBegin)
                widget_list_insert(widget_list, GuiAnimateAlphaFadeIn, 3458923234, 0.1, 0, not previous_picked)
                widget_list_insert(widget_list, GuiOptionsAddForNextWidget, GUI_OPTION.Align_HorizontalCenter)
                local item_component = EntityGetFirstComponent(item, "ItemComponent")
                local ui_name = item_component and ComponentGetValue2(item_component, "item_name") or ""
                local custom_pickup_string = item_component and ComponentGetValue2(item_component, "custom_pickup_string") or ""
                if custom_pickup_string == "" then
                    custom_pickup_string = "$itempickup_pick"
                end
                local item_data = get_item_data(item)
                if item_data ~= nil then
                    if item_data.ui_name ~= nil then
                        ui_name = fetch(item_data.ui_name)
                    end
                    if item_data.custom_pickup_string ~= nil then
                        custom_pickup_string = fetch(item_data.custom_pickup_string)
                    end
                end
                widget_list_insert(widget_list, GuiText, x, y, GameTextGet(custom_pickup_string, "[E]", GameTextGetTranslatedOrNot(ui_name)))
                widget_list_insert(widget_list, GuiAnimateEnd)
            end
        end
    end
    previous_picked = picked

    widget_list_end(widget_list)
end

function OnWorldPreUpdate()
    update_common()
    update_camera()
    update_controls()
    update_pickup()
    update_gui()
end

function OnWorldPostUpdate()
    update_window()
end
