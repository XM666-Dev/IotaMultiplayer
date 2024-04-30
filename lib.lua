dofile_once("mods/iota_multiplayer/files/scripts/lib/isutilities.lua")
dofile_once("mods/mnee/lib.lua")

MP = Namespace("iota_multiplayer")

function set_dictionary_metatable()
    setmetatable(_G, DictionaryMT {
        spawned_player = TagEntityEntry(MP.spawned_player),
        focused_player = {
            get = function()
                return tag_get_entity(MP.focused_player)
            end,
            set = function(v)
                if focused_player then
                    local focused_player_data = PlayerData(focused_player)
                    if focused_player_data.gui.mActive then
                        close_inventory(focused_player_data)
                        return
                    end
                end
                set_player_focused(v, true)
                tag_set_entity(MP.focused_player, v)
            end
        },
        previous_focused_player = TagEntityEntry(MP.previous_focused_player),
        max_user = StateVariableEntry(MP.max_user, Int)
    })
end

function PlayerData(player)
    local gui_comp = EntityGetFirstComponentIncludingDisabled(player, "InventoryGuiComponent")
    local controls_comp = EntityGetFirstComponentIncludingDisabled(player, "ControlsComponent")
    local t = {
        gui = ComponentData(gui_comp),
        controls = ComponentData(controls_comp)
    }
    setmetatable(t, DictionaryMT { user = EntityVariableEntry(player, MP.user, Int) })
    return t
end

function add_player(player)
    EntityAddTag(player, MP.player)
end

function get_players()
    return EntityGetWithTag(MP.player)
end

function load_player()
    local x, y = EntityGetTransform(focused_player)
    local player = EntityLoad("data/entities/player.xml", x, y)
    add_player(player)
    max_user = max_user + 1
    PlayerData(player).user = max_user
    return player
end

function set_player_focused(player, enabled)
    local gui_comp = EntityGetFirstComponentIncludingDisabled(player, "InventoryGuiComponent")
    local listener_comp = EntityGetFirstComponentIncludingDisabled(player, "AudioListenerComponent")
    if gui_comp then
        EntitySetComponentIsEnabled(player, gui_comp, enabled)
    end
    if listener_comp then
        EntitySetComponentIsEnabled(player, listener_comp, enabled)
    end
end

function perk_spawn_with_data(x, y, perk_data)
    local entity = EntityLoad("data/entities/items/pickup/perk.xml", x, y)
    EntityAddComponent2(entity, "SpriteComponent", {
        image_file = perk_data.perk_icon or "data/items_gfx/perk.xml",
        offset_x = 8,
        offset_y = 8,
        update_transform = true,
        update_transform_rotation = false
    })
    EntityAddComponent2(entity, "UIInfoComponent", {
        name = perk_data.ui_name
    })
    EntityAddComponent2(entity, "ItemComponent", {
        item_name = perk_data.ui_name,
        ui_description = perk_data.ui_description,
        ui_display_description_on_pick_up_hint = true,
        play_spinning_animation = false,
        play_hover_animation = false,
        play_pick_sound = true
    })
    EntityAddComponent2(entity, "SpriteOffsetAnimatorComponent", {
        sprite_id = -1,
        x_amount = 0,
        x_phase = 0,
        x_phase_offset = 0,
        x_speed = 0,
        y_amount = 2,
        y_speed = 3
    })
    EntityAddComponent2(entity, "LuaComponent", {
        script_item_picked_up = "mods/iota_multiplayer/files/scripts/perks/autoaim_pickup.lua",
        execute_every_n_frame = -1
    })
    return entity
end

function teleport(entity, from_x, from_y, to_x, to_y)
    EntitySetTransform(entity, to_x, to_y)
    EntityLoad("data/entities/particles/teleportation_source.xml", from_x, from_y)
    EntityLoad("data/entities/particles/teleportation_target.xml", to_x, to_y)
    GamePlaySound("data/audio/Desktop/misc.bank", "misc/teleport_use", to_x, to_y)
end

function open_inventory(player)
    if not player.gui.mActive then
        player.controls.mButtonDownInventory = true
        player.controls.mButtonFrameInventory = GameGetFrameNum() + 1
    end
end

function close_inventory(player)
    if player.gui.mActive then
        player.controls.mButtonDownInventory = true
        player.controls.mButtonFrameInventory = GameGetFrameNum() + 1
    end
end
