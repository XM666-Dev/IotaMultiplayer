--NoitaMultiplayer - Version Alpha 0.3
--Created by ImmortalDamned
--Github https://github.com/XM666-Dev/NoitaMultiplayer

dofile_once("data/scripts/perks/perk.lua")
dofile_once("mods/noita_multiplayer/files/scripts/lib/isutilities.lua")
dofile_once("mods/mnee/lib.lua")

ModLuaFileAppend("mods/mnee/bindings.lua", "mods/noita_multiplayer/mnee.lua")

MP = namespace("noita_multiplayer")

setmetatable(_G, create_dictionary_metatable({
    initial_player = tag_entry_entity(MP.initial_player),
    focus_player = {
        get = function()
            return tag_get_entity(MP.focus_player)
        end,
        set = function(v)
            if focus_player then
                local player = create_player_table(focus_player)
                if player.gui.mActive then
                    close_inventory(player)
                    return
                end
            end
            set_player_focused(focus_player, false)
            set_player_focused(v, true)
            tag_set_entity(MP.focus_player, v)
        end
    },
    previous_focus_player = tag_entry_entity(MP.previous_focus_player)
}))

function create_player_table(player)
    local gui_comp = EntityGetFirstComponentIncludingDisabled(player, "InventoryGuiComponent")
    local controls_comp = EntityGetFirstComponentIncludingDisabled(player, "ControlsComponent")
    local t = {
        gui = create_component_table(gui_comp),
        controls = create_component_table(controls_comp)
    }
    setmetatable(t, create_dictionary_metatable { user = var_entry(player, MP.user, Int) })
    return t
end

function add_player(player)
    EntityAddTag(player, MP.player)
    set_player_focused(player, false)
end

function get_players()
    return EntityGetWithTag(MP.player)
end

function set_player_focused(player, enabled)
    local gui_comp = EntityGetFirstComponentIncludingDisabled(player, "InventoryGuiComponent")
    if gui_comp then
        EntitySetComponentIsEnabled(player, gui_comp, enabled)
    end
    local listener_comp = EntityGetFirstComponentIncludingDisabled(player, "AudioListenerComponent")
    if listener_comp then
        EntitySetComponentIsEnabled(player, listener_comp, enabled)
    end
end

function load_player()
    local x, y = EntityGetTransform(focus_player)
    local player = EntityLoad("data/entities/player.xml", x, y)
    add_player(player)
    return player
end

function perk_spawn_with_data(x, y, perk_data, dont_remove_other_perks_)
    local dont_remove_other_perks = dont_remove_other_perks_ or false
    local entity_id = EntityCreateNew()
    EntitySetTransform(entity_id, x, y)
    EntityAddComponent(entity_id, "SpriteComponent", {
        image_file = perk_data.perk_icon or "data/items_gfx/perk.xml",
        offset_x = "8",
        offset_y = "8",
        update_transform = "1",
        update_transform_rotation = "0",
    })
    EntityAddComponent(entity_id, "UIInfoComponent", {
        name = perk_data.ui_name,
    })
    EntityAddComponent(entity_id, "ItemComponent", {
        item_name = perk_data.ui_name,
        ui_description = perk_data.ui_description,
        ui_display_description_on_pick_up_hint = "1",
        play_spinning_animation = "0",
        play_hover_animation = "0",
        play_pick_sound = "0",
    })
    EntityAddComponent(entity_id, "SpriteOffsetAnimatorComponent", {
        sprite_id = "-1",
        x_amount = "0",
        x_phase = "0",
        x_phase_offset = "0",
        x_speed = "0",
        y_amount = "2",
        y_speed = "3",
    })
    EntityAddComponent(entity_id, "VariableStorageComponent", {
        name = "perk_id",
        value_string = perk_data.id,
    })
    EntityAddComponent2(entity_id, "LuaComponent", {
        script_item_picked_up = "mods/noita_multiplayer/files/scripts/perks/perk_pickup.lua",
        execute_every_n_frame = -1
    })
    if dont_remove_other_perks then
        EntityAddComponent(entity_id, "VariableStorageComponent", {
            name = "perk_dont_remove_others",
            value_bool = "1",
        })
    end
    return entity_id
end

ok = false

function OnPlayerSpawned(iplayer)
    ok = true
    if has_flag_run_once(MP.player_initialized) then
        return
    end
    add_player(iplayer)
    initial_player = iplayer
    focus_player = iplayer
    local x, y = EntityGetTransform(iplayer)
    for i = 1, tonumber(ModSettingGet(MP.player_num)) do
        local player = i > 1 and load_player() or iplayer
        create_player_table(player).user = i
        perk_spawn_with_data(x, y, {
            id = "AUTOAIM",
            ui_name = "$action_autoaim",
            ui_description = "$actiondesc_autoaim",
            ui_icon = "data/ui_gfx/gun_actions/autoaim.png",
            perk_icon = "data/ui_gfx/gun_actions/autoaim.png",
            stackable = false
        })
    end
end

function update_focus_player()
    local players = get_players()
    if focus_player == nil and ok then
        focus_player = players[1]
    end
    if get_binding_pressed("noita_multiplayer", "switch_focus") then
        focus_player = table_iterate(players, function(a, b)
            return (b == nil or create_player_table(a).user < create_player_table(b).user) and
                create_player_table(a).user > create_player_table(focus_player).user
        end)
        if focus_player == nil then
            focus_player = table_iterate(players, function(a, b)
                return b == nil or create_player_table(a).user < create_player_table(b).user
            end)
        end
    end
    if get_binding_pressed(tostring(MP), "teleport") then
        for _, id in ipairs(players) do
            if id ~= focus_player then
                local from_x, from_y = EntityGetTransform(id)
                local to_x, to_y = EntityGetTransform(focus_player)
                teleport(id, from_x, from_y, to_x, to_y)
            end
        end
    end
    for _, id in ipairs(players) do
        if id ~= focus_player then
            set_player_focused(id, false)
        end
    end
end

function teleport(entity, from_x, from_y, to_x, to_y)
    EntitySetTransform(entity, to_x, to_y)
    EntityLoad("data/entities/particles/teleportation_source.xml", from_x, from_y)
    EntityLoad("data/entities/particles/teleportation_target.xml", to_x, to_y)
    GamePlaySound("data/audio/Desktop/misc.bank", "misc/teleport_use", to_x, to_y)
end

function close_inventory(player)
    if player.gui.mActive then
        player.controls.mButtonDownInventory = true
        player.controls.mButtonFrameInventory = GameGetFrameNum() + 1
    end
end

function open_inventory(player)
    if not player.gui.mActive then
        player.controls.mButtonDownInventory = true
        player.controls.mButtonFrameInventory = GameGetFrameNum() + 1
    end
end

function update_controls()
    local players = get_players()
    for _, player_id in ipairs(players) do
        local player = create_player_table(player_id)
        local player_x, player_y = EntityGetTransform(player_id)
        local frame = GameGetFrameNum() + 1
        local function is_player_binding_down(name)
            return is_binding_down(MP.p .. player.user, name)
        end
        local function is_player_binding_just_down(name)
            return get_binding_pressed(MP.p .. player.user, name)
        end
        local function update_inventory(down, pressed)
            if focus_player ~= player_id then
                player.controls.mButtonDownInventory = down
                if pressed then
                    if create_player_table(focus_player).gui.mActive then
                        close_inventory(create_player_table(focus_player))
                    else
                        previous_focus_player = previous_focus_player or focus_player
                        focus_player = player_id
                        open_inventory(player)
                    end
                end
            else
                player.controls.mButtonDownInventory = down
                if pressed then
                    player.controls.mButtonFrameInventory = frame
                    if player.gui.mActive then
                        focus_player = previous_focus_player or focus_player
                        previous_focus_player = nil
                    end
                end
            end
        end

        if player.user == 1 then
            if focus_player ~= player_id then
                if player.controls.mButtonFrameInventory == frame then
                    if create_player_table(focus_player).gui.mActive then
                        close_inventory(create_player_table(focus_player))
                    else
                        previous_focus_player = previous_focus_player or focus_player
                        focus_player = player_id
                        open_inventory(player)
                    end
                end
            else
                if player.controls.mButtonFrameInventory == frame then
                    if player.gui.mActive then
                        focus_player = previous_focus_player or focus_player
                        previous_focus_player = nil
                    end
                end
            end
            goto continue
        end

        player.controls.enabled = false

        player.controls.mButtonDownFire = is_player_binding_down("usewand")
        if is_player_binding_just_down("usewand") then
            player.controls.mButtonFrameFire = frame
        end
        if is_player_binding_down("usewand") then
            player.controls.mButtonLastFrameFire = frame
        end

        player.controls.mButtonDownFire2 = is_player_binding_down("sprayflask")
        if is_player_binding_just_down("sprayflask") then
            player.controls.mButtonFrameFire2 = frame
        end

        player.controls.mButtonDownThrow = is_player_binding_down("throw")
        if is_player_binding_just_down("throw") then
            player.controls.mButtonFrameThrow = frame
        end

        player.controls.mButtonDownInteract = is_player_binding_down("interact")
        if is_player_binding_just_down("interact") then
            player.controls.mButtonFrameInteract = frame
        end

        player.controls.mButtonDownLeft = is_player_binding_down("left")
        if is_player_binding_just_down("left") then
            player.controls.mButtonFrameLeft = frame
        end

        player.controls.mButtonDownRight = is_player_binding_down("right")
        if is_player_binding_just_down("right") then
            player.controls.mButtonFrameRight = frame
        end

        player.controls.mButtonDownUp = is_player_binding_down("up")
        if is_player_binding_just_down("up") then
            player.controls.mButtonFrameUp = frame
        end

        player.controls.mButtonDownDown = is_player_binding_down("down")
        if is_player_binding_just_down("down") then
            player.controls.mButtonFrameDown = frame
        end

        player.controls.mButtonDownFly = is_player_binding_down("up")
        if is_player_binding_just_down("up") then
            player.controls.mButtonFrameFly = frame
        end

        player.controls.mButtonDownChangeItemR = is_player_binding_down("itemnext")
        if is_player_binding_just_down("itemnext") then
            player.controls.mButtonFrameChangeItemR = frame
            player.controls.mButtonCountChangeItemR = 1
        else
            player.controls.mButtonCountChangeItemR = 0
        end

        player.controls.mButtonDownChangeItemL = is_player_binding_down("itemprev")
        if is_player_binding_just_down("itemprev") then
            player.controls.mButtonFrameChangeItemL = frame
            player.controls.mButtonCountChangeItemL = 1
        else
            player.controls.mButtonCountChangeItemL = 0
        end

        update_inventory(is_player_binding_down("inventory"), is_player_binding_just_down("inventory"))

        player.controls.mButtonDownKick = is_player_binding_down("kick")
        if is_player_binding_just_down("kick") then
            player.controls.mButtonFrameKick = frame
        end

        player.controls.mFlyingTargetY = player_y - 10

        local vec_x, vec_y = get_axis_state(MP.p .. player.user, "aimh"), get_axis_state(MP.p .. player.user, "aimv")
        local camera_x, camera_y = GameGetCameraBounds()
        if vec_x ~= 0 or vec_y ~= 0 then
            player.controls("mAimingVector").set(vec_x * 100, vec_y * 100)
        end
        player.controls("mAimingVectorNormalized").set(vec_x, vec_y)
        if vec_x ~= 0 or vec_y ~= 0 then
            player.controls("mAimingVectorNonZeroLatest").set(vec_x, vec_y)
        end
        player.controls("mGamepadAimingVectorRaw").set(vec_x, vec_y)

        local mouse_x, mouse_y = player_x + vec_x * 100, player_y + vec_y * 100
        player.controls("mMousePosition").set(mouse_x, mouse_y)
        player.controls("mMousePositionRaw").set(vec_mult(mouse_x - camera_x, mouse_y - camera_y, 3))

        ::continue::
    end
end

function update_camera()
    if focus_player == nil or initial_player == nil then
        return
    end
    local shooter_comp = EntityGetFirstComponent(focus_player, "PlatformShooterPlayerComponent")
    local desired_x, desired_y = ComponentGetValue2(shooter_comp, "mDesiredCameraPos")
    local initial_shooter_comp = EntityGetFirstComponent(initial_player, "PlatformShooterPlayerComponent")
    if initial_shooter_comp then
        ComponentSetValue2(initial_shooter_comp, "mDesiredCameraPos", desired_x, desired_y)
    end
end

function update_gui()
    mod_gui = mod_gui or GuiCreate()
    if focus_player == nil then
        return
    end
    GuiStartFrame(mod_gui)
    local fplayer = create_player_table(focus_player)
    GuiOptionsAdd(mod_gui, GUI_OPTION.Align_HorizontalCenter)
    GuiText(mod_gui, 10, 25, "P" .. fplayer.user)
    local camera_x, camera_y = GameGetCameraPos()
    local _, _, w, h = GameGetCameraBounds()
    camera_x = camera_x - w / 2
    camera_y = camera_y - h / 2
    local players = get_players()
    for _, id in ipairs(players) do
        local player = create_player_table(id)
        local player_x, player_y = EntityGetTransform(id)
        local x, y = (player_x - camera_x) * 1.5, (player_y - camera_y) * 1.5
        GuiOptionsAdd(mod_gui, GUI_OPTION.Align_HorizontalCenter)
        GuiText(mod_gui, x, y + 5, "P" .. player.user)
    end
end

function OnWorldPreUpdate()
    update_focus_player()
    update_camera()
    update_controls()
end

function OnWorldPostUpdate()
    update_gui()
end
