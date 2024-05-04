dofile_once("mods/iota_multiplayer/lib.lua")

mneedata[get_id(MULTIPLAYER)] = {
    name = "$iota_multiplayer.bindings_common",
    desc = "$iota_multiplayer.bindingsdesc_common"
}

bindings[get_id(MULTIPLAYER)] = {
    switch_player = {
        order_id = "a",
        name = "$iota_multiplayer.binding_switch_player",
        desc = "$iota_multiplayer.bindingdesc_switch_player",
        keys = { ["g"] = 1 }
    },
    toggle_teleport = {
        order_id = "b",
        name = "$iota_multiplayer.binding_toggle_teleport",
        desc = "$iota_multiplayer.bindingdesc_toggle_teleport",
        keys = { ["t"] = 1 }
    }
}

function get_player_binding_description(param)
    return GameTextGet("$iota_multiplayer.bindingdesc_player", GameTextGet(param))
end

for i = 1, 8 do
    local id = i - 1
    function get_key(a, b)
        return id < 1 and a or b
    end

    mneedata[MULTIPLAYER .. i] = {
        name = "P" .. i,
        desc = function()
            return GameTextGet("$iota_multiplayer.bindingsdesc_player", tostring(i))
        end,
        is_hidden = function()
            set_dictionary_metatable()
            return max_user < i
        end
    }
    bindings[MULTIPLAYER .. i] = {
        up = {
            order_id = "a",
            name = "$controls_up",
            desc = function()
                return get_player_binding_description("$controls_up")
            end,
            keys = { [get_key("w", id .. "gpd_l2")] = 1 },
            keys_alt = { [get_key("space", "_")] = 1 }
        },
        down = {
            order_id = "b",
            name = "$controls_down",
            desc = function()
                return get_player_binding_description("$controls_down")
            end,
            keys = { [get_key("s", id .. "gpd_btn_lv_+")] = 1 }
        },
        left = {
            order_id = "c",
            name = "$controls_left",
            desc = function()
                return get_player_binding_description("$controls_left")
            end,
            keys = { [get_key("a", id .. "gpd_btn_lh_-")] = 1 }
        },
        right = {
            order_id = "d",
            name = "$controls_right",
            desc = function()
                return get_player_binding_description("$controls_right")
            end,
            keys = { [get_key("d", id .. "gpd_btn_lh_+")] = 1 }
        },
        aimv = {
            order_id = "e",
            name = "$iota_multiplayer.binding_aimv",
            desc = function()
                return GameTextGet("$iota_multiplayer.bindingdesc_aim", GameTextGet("$iota_multiplayer.binding_aimv"))
            end,
            keys = { "is_axis", get_key("_", id .. "gpd_axis_rv") }
        },
        aimh = {
            order_id = "f",
            name = "$iota_multiplayer.binding_aimh",
            desc = function()
                return GameTextGet("$iota_multiplayer.bindingdesc_aim", GameTextGet("$iota_multiplayer.binding_aimh"))
            end,
            keys = { "is_axis", get_key("_", id .. "gpd_axis_rh") }
        },
        usewand = {
            order_id = "g",
            name = "$controls_usewand",
            desc = function()
                return get_player_binding_description("$controls_usewand")
            end,
            keys = { [get_key("mouse_left", id .. "gpd_r2")] = 1 }
        },
        sprayflask = {
            order_id = "h",
            name = "$controls_sprayflask",
            desc = function()
                return get_player_binding_description("$controls_sprayflask")
            end,
            keys = { [get_key("mouse_left", id .. "gpd_r2")] = 1 }
        },
        throw = {
            order_id = "i",
            name = "$controls_throw",
            desc = function()
                return get_player_binding_description("$controls_throw")
            end,
            keys = { [get_key("mouse_right", id .. "gpd_y")] = 1 }
        },
        kick = {
            order_id = "j",
            name = "$controls_kick",
            desc = function()
                return get_player_binding_description("$controls_kick")
            end,
            keys = { [get_key("f", id .. "gpd_b")] = 1 },
            keys_alt = { [get_key("_", id .. "gpd_l3")] = 1 }
        },
        inventory = {
            order_id = "k",
            name = "$controls_inventory",
            desc = function()
                return get_player_binding_description("$controls_inventory")
            end,
            keys = { [get_key("i", id .. "gpd_select")] = 1 },
            keys_alt = { [get_key("tab", "_")] = 1 }
        },
        interact = {
            order_id = "l",
            name = "$controls_use",
            desc = function()
                return get_player_binding_description("$controls_use")
            end,
            keys = { [get_key("e", id .. "gpd_a")] = 1 }
        },
        itemnext = {
            order_id = "m",
            name = "$controls_itemnext",
            desc = function()
                return get_player_binding_description("$controls_itemnext")
            end,
            keys = { [get_key("mouse_wheel_down", id .. "gpd_r1")] = 1 }
        },
        itemprev = {
            order_id = "n",
            name = "$controls_itemprev",
            desc = function()
                return get_player_binding_description("$controls_itemprev")
            end,
            keys = { [get_key("mouse_wheel_up", id .. "gpd_l1")] = 1 }
        }
    }
end
