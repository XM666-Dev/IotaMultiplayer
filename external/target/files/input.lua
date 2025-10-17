local keycodes = {}
setfenv(loadfile("data/scripts/debug/keycodes.lua"), keycodes)()

---@return string? input
function get_any_input()
    for k, v in pairs(keycodes) do
        if k:find("^Mouse_") then
            if InputIsMouseButtonJustDown(v) then
                return k
            end
        elseif k:find("^Key_") then
            if InputIsKeyJustDown(v) then
                return k
            end
        elseif k:find("^JOY_BUTTON_") then
            for i = 0, 3 do
                if InputIsJoystickButtonJustDown(i, v) then
                    return k
                end
            end
        end
    end
end

---@param input string
function read_input(input)
    if input:find("^Mouse_") then
        return InputIsMouseButtonDown(keycodes[input])
    elseif input:find("^Key_") then
        return InputIsKeyDown(keycodes[input])
    elseif input:find("^JOY_BUTTON_") then
        for i = 0, 3 do
            if InputIsJoystickButtonDown(i, keycodes[input]) then
                return true
            end
        end
        return false
    end
end

---@param input string
function read_input_down(input)
    if input:find("^Mouse_") then
        return InputIsMouseButtonJustDown(keycodes[input])
    elseif input:find("^Key_") then
        return InputIsKeyJustDown(keycodes[input])
    elseif input:find("^JOY_BUTTON_") then
        for i = 0, 3 do
            if InputIsJoystickButtonJustDown(i, keycodes[input]) then
                return true
            end
        end
        return false
    end
end

---@param input string
function read_input_up(input)
    if input:find("^Mouse_") then
        return InputIsMouseButtonJustUp(keycodes[input])
    elseif input:find("^Key_") then
        return InputIsKeyJustUp(keycodes[input])
    elseif input:find("^JOY_BUTTON_") then
        for i = 0, 3 do
            if InputIsJoystickButtonDown(i, keycodes[input]) then
                return false
            end
        end
        return true
    end
end

local names = {
    Mouse_left                   = "$input_mouseleft",
    Mouse_right                  = "$input_mouseright",
    Mouse_middle                 = "$input_mousemiddle",
    Mouse_wheel_up               = "$input_mousewheelup",
    Mouse_wheel_down             = "$input_mousewheeldown",
    Mouse_x1                     = "$input_mousebutton4",
    Mouse_x2                     = "$input_mousebutton5",
    Key_a                        = "A",
    Key_b                        = "B",
    Key_c                        = "C",
    Key_d                        = "D",
    Key_e                        = "E",
    Key_f                        = "F",
    Key_g                        = "G",
    Key_h                        = "H",
    Key_i                        = "I",
    Key_j                        = "J",
    Key_k                        = "K",
    Key_l                        = "L",
    Key_m                        = "M",
    Key_n                        = "N",
    Key_o                        = "O",
    Key_p                        = "P",
    Key_q                        = "Q",
    Key_r                        = "R",
    Key_s                        = "S",
    Key_t                        = "T",
    Key_u                        = "U",
    Key_v                        = "V",
    Key_w                        = "W",
    Key_x                        = "X",
    Key_y                        = "Y",
    Key_z                        = "Z",
    Key_1                        = "1",
    Key_2                        = "2",
    Key_3                        = "3",
    Key_4                        = "4",
    Key_5                        = "5",
    Key_6                        = "6",
    Key_7                        = "7",
    Key_8                        = "8",
    Key_9                        = "9",
    Key_0                        = "0",
    Key_RETURN                   = "Return",
    Key_ESCAPE                   = "Escape",
    Key_BACKSPACE                = "Backspace",
    Key_TAB                      = "$input_tab",
    Key_SPACE                    = "$input_space",
    Key_MINUS                    = "-",
    Key_EQUALS                   = "=",
    Key_LEFTBRACKET              = "[",
    Key_RIGHTBRACKET             = "]",
    Key_BACKSLASH                = "\\",
    Key_NONUSHASH                = "#",
    Key_SEMICOLON                = ";",
    Key_APOSTROPHE               = "'",
    Key_GRAVE                    = "`",
    Key_COMMA                    = "",
    Key_PERIOD                   = ".",
    Key_SLASH                    = "/",
    Key_CAPSLOCK                 = "CapsLock",
    Key_F1                       = "F1",
    Key_F2                       = "F2",
    Key_F3                       = "F3",
    Key_F4                       = "F4",
    Key_F5                       = "F5",
    Key_F6                       = "F6",
    Key_F7                       = "F7",
    Key_F8                       = "F8",
    Key_F9                       = "F9",
    Key_F10                      = "F10",
    Key_F11                      = "F11",
    Key_F12                      = "F12",
    Key_PRINTSCREEN              = "PrintScreen",
    Key_SCROLLLOCK               = "ScrollLock",
    Key_PAUSE                    = "Pause",
    Key_INSERT                   = "Insert",
    Key_HOME                     = "Home",
    Key_PAGEUP                   = "PageUp",
    Key_DELETE                   = "Delete",
    Key_END                      = "End",
    Key_PAGEDOWN                 = "PageDown",
    Key_RIGHT                    = "Right",
    Key_LEFT                     = "Left",
    Key_DOWN                     = "Down",
    Key_UP                       = "Up",
    Key_NUMLOCKCLEAR             = "Numlock",
    Key_KP_DIVIDE                = "Keypad /",
    Key_KP_MULTIPLY              = "Keypad *",
    Key_KP_MINUS                 = "Keypad -",
    Key_KP_PLUS                  = "Keypad +",
    Key_KP_ENTER                 = "Keypad Enter",
    Key_KP_1                     = "Keypad 1",
    Key_KP_2                     = "Keypad 2",
    Key_KP_3                     = "Keypad 3",
    Key_KP_4                     = "Keypad 4",
    Key_KP_5                     = "Keypad 5",
    Key_KP_6                     = "Keypad 6",
    Key_KP_7                     = "Keypad 7",
    Key_KP_8                     = "Keypad 8",
    Key_KP_9                     = "Keypad 9",
    Key_KP_0                     = "Keypad 0",
    Key_KP_PERIOD                = "Keypad .",
    Key_APPLICATION              = "Menu",
    Key_POWER                    = "Power",
    Key_KP_EQUALS                = "Keypad =",
    Key_F13                      = "F13",
    Key_F14                      = "F14",
    Key_F15                      = "F15",
    Key_F16                      = "F16",
    Key_F17                      = "F17",
    Key_F18                      = "F18",
    Key_F19                      = "F19",
    Key_F20                      = "F20",
    Key_F21                      = "F21",
    Key_F22                      = "F22",
    Key_F23                      = "F23",
    Key_F24                      = "F24",
    Key_EXECUTE                  = "Execute",
    Key_HELP                     = "Help",
    Key_MENU                     = "Menu",
    Key_SELECT                   = "Select",
    Key_STOP                     = "Stop",
    Key_AGAIN                    = "Again",
    Key_UNDO                     = "Undo",
    Key_CUT                      = "Cut",
    Key_COPY                     = "Copy",
    Key_PASTE                    = "Paste",
    Key_FIND                     = "Find",
    Key_MUTE                     = "Mute",
    Key_VOLUMEUP                 = "VolumeUp",
    Key_VOLUMEDOWN               = "VolumeDown",
    Key_KP_COMMA                 = "Keypad ,",
    Key_KP_EQUALSAS400           = "Keypad = (AS400)",
    Key_ALTERASE                 = "AltErase",
    Key_SYSREQ                   = "SysReq",
    Key_CANCEL                   = "Cancel",
    Key_CLEAR                    = "Clear",
    Key_PRIOR                    = "Prior",
    Key_RETURN2                  = "Return",
    Key_SEPARATOR                = "Separator",
    Key_OUT                      = "Out",
    Key_OPER                     = "Oper",
    Key_CLEARAGAIN               = "Clear / Again",
    Key_CRSEL                    = "CrSel",
    Key_EXSEL                    = "ExSel",
    Key_KP_00                    = "Keypad 00",
    Key_KP_000                   = "Keypad 000",
    Key_THOUSANDSSEPARATOR       = "ThousandsSeparator",
    Key_DECIMALSEPARATOR         = "DecimalSeparator",
    Key_CURRENCYUNIT             = "CurrencyUnit",
    Key_CURRENCYSUBUNIT          = "CurrencySubUnit",
    Key_KP_LEFTPAREN             = "Keypad (",
    Key_KP_RIGHTPAREN            = "Keypad )",
    Key_KP_LEFTBRACE             = "Keypad {",
    Key_KP_RIGHTBRACE            = "Keypad }",
    Key_KP_TAB                   = "Keypad Tab",
    Key_KP_BACKSPACE             = "Keypad Backspace",
    Key_KP_A                     = "Keypad A",
    Key_KP_B                     = "Keypad B",
    Key_KP_C                     = "Keypad C",
    Key_KP_D                     = "Keypad D",
    Key_KP_E                     = "Keypad E",
    Key_KP_F                     = "Keypad F",
    Key_KP_XOR                   = "Keypad XOR",
    Key_KP_POWER                 = "Keypad ^",
    Key_KP_PERCENT               = "Keypad %",
    Key_KP_LESS                  = "Keypad <",
    Key_KP_GREATER               = "Keypad >",
    Key_KP_AMPERSAND             = "Keypad &",
    Key_KP_DBLAMPERSAND          = "Keypad &&",
    Key_KP_VERTICALBAR           = "Keypad |",
    Key_KP_DBLVERTICALBAR        = "Keypad ||",
    Key_KP_COLON                 = "Keypad :",
    Key_KP_HASH                  = "Keypad #",
    Key_KP_SPACE                 = "Keypad Space",
    Key_KP_AT                    = "Keypad @",
    Key_KP_EXCLAM                = "Keypad !",
    Key_KP_MEMSTORE              = "Keypad MemStore",
    Key_KP_MEMRECALL             = "Keypad MemRecall",
    Key_KP_MEMCLEAR              = "Keypad MemClear",
    Key_KP_MEMADD                = "Keypad MemAdd",
    Key_KP_MEMSUBTRACT           = "Keypad MemSubtract",
    Key_KP_MEMMULTIPLY           = "Keypad MemMultiply",
    Key_KP_MEMDIVIDE             = "Keypad MemDivide",
    Key_KP_PLUSMINUS             = "Keypad +/-",
    Key_KP_CLEAR                 = "Keypad Clear",
    Key_KP_CLEARENTRY            = "Keypad ClearEntry",
    Key_KP_BINARY                = "Keypad Binary",
    Key_KP_OCTAL                 = "Keypad Octal",
    Key_KP_DECIMAL               = "Keypad Decimal",
    Key_KP_HEXADECIMAL           = "Keypad Hexadecimal",
    Key_LCTRL                    = "Left Ctrl",
    Key_LSHIFT                   = "$input_leftshift",
    Key_LALT                     = "Left Alt",
    Key_LGUI                     = "Left Windows",
    Key_RCTRL                    = "Right Ctrl",
    Key_RSHIFT                   = "$input_rightshift",
    Key_RALT                     = "Right Alt",
    Key_RGUI                     = "Right Windows",
    Key_MODE                     = "ModeSwitch",
    Key_AUDIONEXT                = "AudioNext",
    Key_AUDIOPREV                = "AudioPrev",
    Key_AUDIOSTOP                = "AudioStop",
    Key_AUDIOPLAY                = "AudioPlay",
    Key_AUDIOMUTE                = "AudioMute",
    Key_MEDIASELECT              = "MediaSelect",
    Key_WWW                      = "WWW",
    Key_MAIL                     = "Mail",
    Key_CALCULATOR               = "Calculator",
    Key_COMPUTER                 = "Computer",
    Key_AC_SEARCH                = "AC Search",
    Key_AC_HOME                  = "AC Home",
    Key_AC_BACK                  = "AC Back",
    Key_AC_FORWARD               = "AC Forward",
    Key_AC_STOP                  = "AC Stop",
    Key_AC_REFRESH               = "AC Refresh",
    Key_AC_BOOKMARKS             = "AC Bookmarks",
    Key_BRIGHTNESSDOWN           = "BrightnessDown",
    Key_BRIGHTNESSUP             = "BrightnessUp",
    Key_DISPLAYSWITCH            = "DisplaySwitch",
    Key_KBDILLUMTOGGLE           = "KBDIllumToggle",
    Key_KBDILLUMDOWN             = "KBDIllumDown",
    Key_KBDILLUMUP               = "KBDIllumUp",
    Key_EJECT                    = "Eject",
    Key_SLEEP                    = "Sleep",
    Key_APP1                     = "App1",
    Key_APP2                     = "App2",
    JOY_BUTTON_ANALOG_00_MOVED   = "$input_xboxbutton_analog_00",
    JOY_BUTTON_ANALOG_01_MOVED   = "$input_xboxbutton_analog_01",
    JOY_BUTTON_ANALOG_02_MOVED   = "$input_xboxbutton_analog_02",
    JOY_BUTTON_ANALOG_03_MOVED   = "$input_xboxbutton_analog_03",
    JOY_BUTTON_ANALOG_04_MOVED   = "$input_xboxbutton_analog_04",
    JOY_BUTTON_ANALOG_05_MOVED   = "$input_xboxbutton_analog_05",
    JOY_BUTTON_ANALOG_06_MOVED   = "$input_xboxbutton_analog_06",
    JOY_BUTTON_ANALOG_07_MOVED   = "$input_xboxbutton_analog_07",
    JOY_BUTTON_ANALOG_08_MOVED   = "$input_xboxbutton_analog_08",
    JOY_BUTTON_ANALOG_09_MOVED   = "$input_xboxbutton_analog_09",
    JOY_BUTTON_DPAD_UP           = "$input_xboxbutton_dpad_up",
    JOY_BUTTON_DPAD_DOWN         = "$input_xboxbutton_dpad_down",
    JOY_BUTTON_DPAD_LEFT         = "$input_xboxbutton_dpad_left",
    JOY_BUTTON_DPAD_RIGHT        = "$input_xboxbutton_dpad_right",
    JOY_BUTTON_START             = "$input_xboxbutton_start",
    JOY_BUTTON_BACK              = "$input_xboxbutton_back",
    JOY_BUTTON_LEFT_THUMB        = "$input_xboxbutton_left_thumb",
    JOY_BUTTON_RIGHT_THUMB       = "$input_xboxbutton_right_thumb",
    JOY_BUTTON_LEFT_SHOULDER     = "$input_xboxbutton_left_shoulder",
    JOY_BUTTON_RIGHT_SHOULDER    = "$input_xboxbutton_right_shoulder",
    JOY_BUTTON_LEFT_STICK_MOVED  = "$input_xboxbutton_left_stick_moved",
    JOY_BUTTON_RIGHT_STICK_MOVED = "$input_xboxbutton_right_stick_moved",
    JOY_BUTTON_0                 = "$input_xboxbutton_a",
    JOY_BUTTON_1                 = "$input_xboxbutton_b",
    JOY_BUTTON_2                 = "$input_xboxbutton_x",
    JOY_BUTTON_3                 = "$input_xboxbutton_y",
    JOY_BUTTON_4                 = "$input_xboxbutton_4",
    JOY_BUTTON_5                 = "$input_xboxbutton_5",
    JOY_BUTTON_6                 = "$input_xboxbutton_6",
    JOY_BUTTON_7                 = "$input_xboxbutton_7",
    JOY_BUTTON_8                 = "$input_xboxbutton_8",
    JOY_BUTTON_9                 = "$input_xboxbutton_9",
    JOY_BUTTON_10                = "$input_xboxbutton_10",
    JOY_BUTTON_11                = "$input_xboxbutton_11",
    JOY_BUTTON_12                = "$input_xboxbutton_12",
    JOY_BUTTON_13                = "$input_xboxbutton_13",
    JOY_BUTTON_14                = "$input_xboxbutton_14",
    JOY_BUTTON_15                = "$input_xboxbutton_15",
    JOY_BUTTON_LEFT_STICK_LEFT   = "$input_xboxbutton_left_stick_left",
    JOY_BUTTON_LEFT_STICK_RIGHT  = "$input_xboxbutton_left_stick_right",
    JOY_BUTTON_LEFT_STICK_UP     = "$input_xboxbutton_left_stick_up",
    JOY_BUTTON_LEFT_STICK_DOWN   = "$input_xboxbutton_left_stick_down",
    JOY_BUTTON_RIGHT_STICK_LEFT  = "$input_xboxbutton_right_stick_left",
    JOY_BUTTON_RIGHT_STICK_RIGHT = "$input_xboxbutton_right_stick_right",
    JOY_BUTTON_RIGHT_STICK_UP    = "$input_xboxbutton_right_stick_up",
    JOY_BUTTON_RIGHT_STICK_DOWN  = "$input_xboxbutton_right_stick_down",
    JOY_BUTTON_ANALOG_00_DOWN    = "$input_xboxbutton_analog_00",
    JOY_BUTTON_ANALOG_01_DOWN    = "$input_xboxbutton_analog_01",
    JOY_BUTTON_ANALOG_02_DOWN    = "$input_xboxbutton_analog_02",
    JOY_BUTTON_ANALOG_03_DOWN    = "$input_xboxbutton_analog_03",
    JOY_BUTTON_ANALOG_04_DOWN    = "$input_xboxbutton_analog_04",
    JOY_BUTTON_ANALOG_05_DOWN    = "$input_xboxbutton_analog_05",
    JOY_BUTTON_ANALOG_06_DOWN    = "$input_xboxbutton_analog_06",
    JOY_BUTTON_ANALOG_07_DOWN    = "$input_xboxbutton_analog_07",
    JOY_BUTTON_ANALOG_08_DOWN    = "$input_xboxbutton_analog_08",
    JOY_BUTTON_ANALOG_09_DOWN    = "$input_xboxbutton_analog_09",
}
---@param input string
---@return string
function get_input_name(input)
    local name = names[input]
    if name ~= nil then
        if name:find("^%$") then
            name = GameTextGet(name)
        end
        return name:upper()
    end
    return "$menuoptions_configurecontrols_keyname_unknown"
end

local detect_key = false
local disable_button = false
function mod_setting_input(mod_id, gui, in_main_menu, im_id, setting)
    GuiOptionsAddForNextWidget(gui, GUI_OPTION.Layout_NextSameLine)
    GuiColorSetForNextWidget(gui, 0x6e / 0xff, 0x6e / 0xff, 0x6e / 0xff, 1)
    GuiText(gui, mod_setting_group_x_offset, 0, setting.ui_name)

    local text
    if detect_key then
        text = "$menuoptions_configurecontrols_pressakey"
        local input = get_any_input()
        if input ~= nil then
            detect_key = false
            if input == "Mouse_left" or input == "Mouse_right" or input == "JOY_BUTTON_0" or input == "JOY_BUTTON_1" then
                disable_button = true
            end
            ModSettingSetNextValue(mod_setting_get_id(mod_id, setting), input, false)
        end
    else
        text = get_input_name(ModSettingGetNextValue(mod_setting_get_id(mod_id, setting)))
    end
    if disable_button and (read_input_up("Mouse_left") or read_input_down("Mouse_right") or read_input_down("JOY_BUTTON_0") or read_input_down("JOY_BUTTON_1")) then
        disable_button = false
        GuiOptionsAddForNextWidget(gui, GUI_OPTION.NonInteractive)
        GuiOptionsAddForNextWidget(gui, GUI_OPTION.ForceFocusable)
    end
    local clicked, right_clicked = GuiButton(gui, im_id, mod_setting_group_x_offset + GuiGetTextDimensions(gui, setting.ui_name) + 10, 0, text)
    if clicked then
        detect_key = true
    elseif right_clicked then
        ModSettingSetNextValue(mod_setting_get_id(mod_id, setting), setting.value_default, false)
    end

    mod_setting_tooltip(mod_id, gui, in_main_menu, setting)
end
