dofile_once("data/scripts/lib/mod_settings.lua")

local index_table_metatable = {
    __call = function(t, indexes)
        t[1] = indexes
        return t
    end,
    __index = function(t, k)
        local index = t[1][k]
        if index ~= nil then return index(t, k) end
    end,
}
local function IndexTable(t)
    return setmetatable(t, index_table_metatable)
end
---@param str string
local function parse_csv(str)
    local cellDatas = {}
    local rowHeads = {}
    local cellArrangement = {}
    local result
    local tempKey = nil
    ---设置指定行列单元格的值
    ---* 使用行列号(从1开始的数字)来作为索引
    ---* 不存在的单元格会自动新建
    ---@param row number
    ---@param column number
    local set = function(row, column, value)
        if column == 1 then
            cellDatas[value] = {}
            table.insert(cellArrangement, value)
            tempKey = value
        end
        table.insert(cellDatas[tempKey], value)
        if row == 1 then rowHeads[value] = column end
    end
    result = {
        rowHeads = rowHeads,
        cellDatas = cellDatas,
        cellArrangement = cellArrangement,
        ---获取key对应值
        ---@param row string
        ---@param column string
        ---@return string|nil
        get = function(row, column)
            -- 尝试转为数字索引
            column = rowHeads[column]
            row = cellDatas[row]
            if column and row then
                local result = row[column]                                                              -- 34为"符号
                if string.byte(result, 1, 1) == 34 and string.byte(result, #result, #result) == 34 then --删除开头和结尾的" 因为实际游戏中也不存在
                    return string.sub(result, 2, string.len(result) - 1)
                end
                return result
            else
                return nil
            end
        end,
        tostring = function()
            local cache = {}
            local newRowHeads = {}
            for v, k in pairs(rowHeads) do
                newRowHeads[k] = v
            end
            local rowHeadSize = #newRowHeads

            for i = 1, rowHeadSize do
                if newRowHeads[i] ~= "" then
                    table.insert(cache, newRowHeads[i])
                end
                if i ~= rowHeadSize then
                    table.insert(cache, ",")
                end
            end
            local cellSize = #cellArrangement
            for i = 1, cellSize do
                local key = cellArrangement[i]
                local value = cellDatas[key]
                local size = #value
                for v_i, vstr in pairs(value) do  --解析数组
                    if vstr ~= "" then
                        table.insert(cache, vstr) --插入字符串
                    end
                    if v_i ~= size then           --防止最后一个插入,
                        table.insert(cache, ",")
                    end
                end
                if i ~= cellSize then         --防止最后一个插入\n
                    table.insert(cache, "\n") --插入换行符
                end
            end
            return table.concat(cache)
        end,
    }
    local state_quotationMark = false -- 双引号状态机
    local usub = string.sub
    local codepoint = string.byte
    local StartPos = 1 --用于记录一个需要被剪切的字符串的起始位
    local charNum = 0
    local posRow = 1
    local posColumn = 1
    for i = 1, #str do
        charNum = codepoint(str, i, i)
        if state_quotationMark then               -- 处于双引号包裹中
            state_quotationMark = (charNum ~= 34) --减少分支优化
            if charNum == 92 then                 --转义符考虑
                i = i + 1                         --当前字符是转义符，下一个字符也应该跳过，所以加1，下一次循环再加1
            end
        else
            if charNum == 34 then                                  -- 34为"符号
                state_quotationMark = true                         -- 进入双引号包裹
            elseif charNum == 44 then                              -- 分隔符为en逗号 44为,
                set(posRow, posColumn, usub(str, StartPos, i - 1)) --i-1是为了不要把,加进去
                StartPos = i + 1                                   --重设起始位
                posColumn = posColumn + 1
            elseif charNum == 10 then                              --10为\n
                -- 对连续换行(空行)和"\n"(Windows换行符)特殊处理
                if (codepoint(str, i - 1, i - 1) ~= 10) then
                    set(posRow, posColumn, usub(str, StartPos, i - 1))
                    StartPos = i + 1
                    posRow = posRow + 1
                    posColumn = 1
                end
            end
        end
    end
    set(posRow, posColumn, usub(str, StartPos, #str - 1))
    return result
end
local translations = parse_csv([[
,en,ru,pt-br,es-es,de,fr-fr,it,pl,zh-cn,jp,ko,
iota_multiplayer.bindings_common,mp common,,,,,,,,联机常用,,,
iota_multiplayer.bindingsdesc_common,mp common bindings.,,,,,,,,联机常用的按键绑定。,,,
iota_multiplayer.binding_switch_camera,switch camera,,,,,,,,切换摄像机,,,
iota_multiplayer.bindingdesc_switch_camera,switch camera&gui target between players.,,,,,,,,在玩家之间切换摄像机和图形界面目标。,,,
iota_multiplayer.binding_toggle_teleport,toggle teleport,,,,,,,,开关传送,,,
iota_multiplayer.bindingdesc_toggle_teleport,enable/disable auto teleport.,,,,,,,,启用/禁用自动传送。,,,
iota_multiplayer.bindings_player,player $0,,,,,,,,玩家$0,,,
iota_multiplayer.bindingsdesc_player,player $0 bindings.,,,,,,,,玩家$0的按键绑定。,,,
iota_multiplayer.bindingdesc_player,control player $0 $1.,,,,,,,,控制玩家$0$1。,,,
iota_multiplayer.bindingdesc_aim,"control player $0 $1, unbind to use mouse aiming.",,,,,,,,控制玩家$0$1，解绑以使用鼠标瞄准。,,,
iota_multiplayer.setting_share,SHARE,,,,,,,,共享,,,
iota_multiplayer.settingdesc_share,About resource sharing,,,,,,,,资源共享相关,,,
iota_multiplayer.setting_share_money,Money,,,,,,,,金钱,,,
iota_multiplayer.settingdesc_share_money,Are money sharing for players?,,,,,,,,是否为玩家共享金钱？,,,
iota_multiplayer.setting_share_temple_heart,Temple heart,,,,,,,,圣山红心,,,
iota_multiplayer.settingdesc_share_temple_heart,Do temple hearts spawn for others when picked up?,,,,,,,,圣山红心被捡起时是否为其他玩家生成？,,,
iota_multiplayer.setting_share_temple_refresh,Temple refresh,,,,,,,,圣山刷新器,,,
iota_multiplayer.settingdesc_share_temple_refresh,Do temple refreshs spawn for others when picked up?,,,,,,,,圣山刷新器被捡起时是否为其他玩家生成？,,,
iota_multiplayer.setting_share_temple_perk,Temple perk,,,,,,,,圣山天赋,,,
iota_multiplayer.settingdesc_share_temple_perk,Do temple perks respawn for others when picked up?,,,,,,,,圣山天赋被捡起时是否为其他玩家重新生成？,,,
iota_multiplayer.setting_friendly_fire,FRIENDLY FIRE,,,,,,,,友伤,,,
iota_multiplayer.settingdesc_friendly_fire,About friendly fire,,,,,,,,友军误伤相关,,,
iota_multiplayer.setting_friendly_fire_percent,Percent,,,,,,,,百分比,,,
iota_multiplayer.settingdesc_friendly_fire_percent,The percent of friendly fire between players.,,,,,,,,玩家之间的友伤百分比。,,,
iota_multiplayer.setting_friendly_fire_kick,Kick,,,,,,,,踢击,,,
iota_multiplayer.settingdesc_friendly_fire_kick,Do players received friendly fire when kicked?,,,,,,,,玩家被踢击时是否受到友伤？,,,
iota_multiplayer.setting_friendly_fire_kick_drop,Kick drop,,,,,,,,踢击掉落,,,
iota_multiplayer.settingdesc_friendly_fire_kick_drop,Do players drop items when kicked?,,,,,,,,玩家被踢击时是否掉落物品？,,,
iota_multiplayer.setting_friendly_fire_force,Force,,,,,,,,强制,,,
iota_multiplayer.settingdesc_friendly_fire_force,Do players force friendly fire?,,,,,,,,玩家之间是否强制友伤？,,,
iota_multiplayer.setting_camera,CAMERA,,,,,,,,摄像机,,,
iota_multiplayer.settingdesc_camera,About camera tweaks,,,,,,,,摄像机调整相关,,,
iota_multiplayer.setting_camera_zoom_min,Min zoom,,,,,,,,最小缩放,,,
iota_multiplayer.settingdesc_camera_zoom_min,Camera minimum zoom multiplier.,,,,,,,,摄像机的最小缩放倍数。,,,
iota_multiplayer.setting_camera_zoom_max,Max zoom,,,,,,,,最大缩放,,,
iota_multiplayer.settingdesc_camera_zoom_max,Camera maximum zoom multiplier.,,,,,,,,摄像机的最大缩放倍数。,,,
iota_multiplayer.setting_camera_centered_only,Camera centered only,,,,,,,,摄像机始终居中,,,
iota_multiplayer.settingdesc_camera_centered_only,Does camera only center at the current player?,,,,,,,,摄像机是否仅居中于当前玩家？,,,
iota_multiplayer.setting_player,PLAYER,,,,,,,,玩家,,,
iota_multiplayer.settingdesc_player,About player settings,,,,,,,,玩家设置相关,,,
iota_multiplayer.setting_player_num,Num,,,,,,,,数量,,,
iota_multiplayer.settingdesc_player_num,The number of players in the current world.,,,,,,,,当前世界中的玩家数量。,,,
iota_multiplayer.setting_player_color,Player %s color,,,,,,,,玩家%s颜色,,,
iota_multiplayer.settingdesc_player_color,The color used by player %s.,,,,,,,,玩家%s所使用的颜色。,,,
iota_multiplayer.setting_player_autoaim,Player %s autoaim,,,,,,,,玩家%s自动瞄准,,,
iota_multiplayer.settingdesc_player_autoaim,Whether to use autoaim for player %s?,,,,,,,,是否为玩家%s使用自动瞄准？,,,
iota_multiplayer.itempickup_use,Press $0 to use '$1',,,,,,,,按 $0 使用“$1”,,,
iota_multiplayer.item_resurrect,Resurrect,,,,,,,,复活,,,
iota_multiplayer.item_corpse,Corpse,,,,,,,,尸体,,,
]])
local function get_language()
    return ({
        ["English"] = "en",
        ["русский"] = "ru",
        ["Português (Brasil)"] = "pt-br",
        ["Español"] = "es-es",
        ["Deutsch"] = "de",
        ["Français"] = "fr-fr",
        ["Italiano"] = "it",
        ["Polska"] = "pl",
        ["简体中文"] = "zh-cn",
        ["日本語"] = "jp",
        ["한국어"] = "ko",
    })[GameTextGet("$current_language")]
end
local function get_text(key)
    local text = translations.get(key, get_language())
    return text ~= "" and text or translations.get(key, "en")
end
local function mod_setting_text_integer(mod_id, gui, in_main_menu, im_id, setting)
    local value = ModSettingGetNextValue(mod_setting_get_id(mod_id, setting))

    GuiLayoutBeginHorizontal(gui, 0, 0)
    GuiText(gui, mod_setting_group_x_offset, 0, setting.ui_name)
    local value_new = GuiTextInput(gui, im_id, 0, 0, setting.text or value, 100, setting.text_max_length or 25, setting.allowed_characters or "")
    local clicked, right_clicked, hovered = GuiGetPreviousWidgetInfo(gui)
    if right_clicked then
        value_new = setting.value_default
    end
    if hovered then
        setting.text = value_new
    else
        setting.text = nil
    end
    value_new = tonumber(value_new) or value
    GuiLayoutEnd(gui)
    if value ~= value_new then
        ModSettingSetNextValue(mod_setting_get_id(mod_id, setting), math.floor(value_new + 0.5), false)
        mod_setting_handle_change_callback(mod_id, gui, in_main_menu, setting, value, value_new)
    end

    mod_setting_tooltip(mod_id, gui, in_main_menu, setting)
end
local function mod_setting_text_color(mod_id, gui, in_main_menu, im_id, setting)
    local value = ModSettingGetNextValue(mod_setting_get_id(mod_id, setting))

    GuiLayoutBeginHorizontal(gui, 0, 0)
    GuiText(gui, mod_setting_group_x_offset, 0, setting.ui_name)
    local value_new = GuiTextInput(gui, im_id, 0, 0, setting.text or ("%x"):format(value), 100, setting.text_max_length or 25, setting.allowed_characters or "")
    local clicked, right_clicked, hovered = GuiGetPreviousWidgetInfo(gui)
    if right_clicked then
        value_new = ("%x"):format(setting.value_default)
    end
    if hovered then
        setting.text = value_new
    else
        setting.text = nil
    end
    value_new = tonumber("0x" .. value_new) or value
    GuiLayoutEnd(gui)
    if value ~= value_new then
        ModSettingSetNextValue(mod_setting_get_id(mod_id, setting), value_new, false)
        mod_setting_handle_change_callback(mod_id, gui, in_main_menu, setting, value, value_new)
    end

    mod_setting_tooltip(mod_id, gui, in_main_menu, setting)
end

local mod_id = "iota_multiplayer"
mod_settings_version = 1
mod_settings = {
    IndexTable{
        category_id = "share",
        settings = {
            IndexTable{
                id = "share_money",
                value_default = true,
                scope = MOD_SETTING_SCOPE_RUNTIME,
            }{
                    ui_name = function() return get_text("iota_multiplayer.setting_share_money") end,
                    ui_description = function() return get_text("iota_multiplayer.settingdesc_share_money") end,
                },
            IndexTable{
                id = "share_temple_heart",
                value_default = true,
                scope = MOD_SETTING_SCOPE_RUNTIME,
            }{
                    ui_name = function() return get_text("iota_multiplayer.setting_share_temple_heart") end,
                    ui_description = function() return get_text("iota_multiplayer.settingdesc_share_temple_heart") end,
                },
            IndexTable{
                id = "share_temple_refresh",
                value_default = true,
                scope = MOD_SETTING_SCOPE_RUNTIME,
            }{
                    ui_name = function() return get_text("iota_multiplayer.setting_share_temple_refresh") end,
                    ui_description = function() return get_text("iota_multiplayer.settingdesc_share_temple_refresh") end,
                },
            IndexTable{
                id = "share_temple_perk",
                value_default = true,
                scope = MOD_SETTING_SCOPE_RUNTIME,
            }{
                    ui_name = function() return get_text("iota_multiplayer.setting_share_temple_perk") end,
                    ui_description = function() return get_text("iota_multiplayer.settingdesc_share_temple_perk") end,
                },
        },
    }{
            ui_name = function() return get_text("iota_multiplayer.setting_share") end,
            ui_description = function() return get_text("iota_multiplayer.settingdesc_share") end,
        },
    IndexTable{
        category_id = "friendly_fire",
        settings = {
            IndexTable{
                id = "friendly_fire_percent",
                value_default = 0.5,
                value_min = 0,
                value_max = 1,
                value_display_multiplier = 100,
                value_display_formatting = " $0 %",
                scope = MOD_SETTING_SCOPE_RUNTIME,
            }{
                    ui_name = function() return get_text("iota_multiplayer.setting_friendly_fire_percent") end,
                    ui_description = function() return get_text("iota_multiplayer.settingdesc_friendly_fire_percent") end,
                },
            IndexTable{
                id = "friendly_fire_kick",
                value_default = false,
                scope = MOD_SETTING_SCOPE_RUNTIME,
            }{
                    ui_name = function() return get_text("iota_multiplayer.setting_friendly_fire_kick") end,
                    ui_description = function() return get_text("iota_multiplayer.settingdesc_friendly_fire_kick") end,
                },
            IndexTable{
                id = "friendly_fire_kick_drop",
                value_default = false,
                scope = MOD_SETTING_SCOPE_RUNTIME,
            }{
                    ui_name = function() return get_text("iota_multiplayer.setting_friendly_fire_kick_drop") end,
                    ui_description = function() return get_text("iota_multiplayer.settingdesc_friendly_fire_kick_drop") end,
                },
            IndexTable{
                id = "friendly_fire_force",
                value_default = false,
                scope = MOD_SETTING_SCOPE_RUNTIME,
            }{
                    ui_name = function() return get_text("iota_multiplayer.setting_friendly_fire_force") end,
                    ui_description = function() return get_text("iota_multiplayer.settingdesc_friendly_fire_force") end,
                },
        },
    }{
            ui_name = function() return get_text("iota_multiplayer.setting_friendly_fire") end,
            ui_description = function() return get_text("iota_multiplayer.settingdesc_friendly_fire") end,
        },
    IndexTable{
        category_id = "camera",
        settings = {
            IndexTable{
                id = "camera_zoom_min",
                value_default = 1,
                value_min = 0.5,
                value_display_multiplier = 100,
                value_display_formatting = " $0 %",
                scope = MOD_SETTING_SCOPE_RUNTIME,
            }{
                    ui_name = function() return get_text("iota_multiplayer.setting_camera_zoom_min") end,
                    ui_description = function() return get_text("iota_multiplayer.settingdesc_camera_zoom_min") end,
                    value_max = function() return ModSettingGetNextValue("iota_multiplayer.camera_zoom_max") end,
                },
            IndexTable{
                id = "camera_zoom_max",
                value_default = 1,
                value_min = 0.5,
                value_max = 2,
                value_display_multiplier = 100,
                value_display_formatting = " $0 %",
                scope = nil,
                change_fn = function(mod_id, gui, in_main_menu, setting, old_value, new_value)
                    ModSettingSetNextValue("iota_multiplayer.camera_zoom_min", math.min(ModSettingGetNextValue("iota_multiplayer.camera_zoom_min"), new_value), false)
                end,
            }{
                    ui_name = function() return get_text("iota_multiplayer.setting_camera_zoom_max") end,
                    ui_description = function() return get_text("iota_multiplayer.settingdesc_camera_zoom_max") end,
                },
            IndexTable{
                id = "camera_centered_only",
                value_default = false,
                scope = MOD_SETTING_SCOPE_RUNTIME,
            }{
                    ui_name = function() return get_text("iota_multiplayer.setting_camera_centered_only") end,
                    ui_description = function() return get_text("iota_multiplayer.settingdesc_camera_centered_only") end,
                },
            IndexTable{
                id = "camera_disable_filter",
                value_default = true,
                scope = MOD_SETTING_SCOPE_RESTART,
            }{
                    ui_name = function() return get_text("iota_multiplayer.setting_camera_disable_filter") end,
                    ui_description = function() return get_text("iota_multiplayer.settingdesc_camera_disable_filter") end,
                },
        },
    }{
            ui_name = function() return get_text("iota_multiplayer.setting_camera") end,
            ui_description = function() return get_text("iota_multiplayer.settingdesc_camera") end,
        },
    IndexTable{
        category_id = "player",
        settings = {
            IndexTable{
                id = "player_num",
                value_default = 1,
                allowed_characters = NUMERIC_CHARACTERS,
                scope = nil,
                ui_fn = function(...)
                    local raw_mod_setting_get_next_value = ModSettingGetNextValue
                    local raw_mod_setting_set_next_value = ModSettingSetNextValue

                    if GameGetWorldStateEntity() == 0 then
                        ModSettingGetNextValue = function() return 0 end
                        ModSettingSetNextValue = function() end
                    else
                        dofile_once("mods/iota_multiplayer/files/scripts/lib/utilities.lua")
                        ModSettingGetNextValue = function()
                            if mod.player_num_target == -1 then return #get_players_including_disabled() end

                            return mod.player_num_target
                        end
                        ModSettingSetNextValue = function(id, value)
                            mod.player_num_target = value
                        end
                    end

                    mod_setting_text_integer(...)
                    ModSettingGetNextValue = raw_mod_setting_get_next_value
                    ModSettingSetNextValue = raw_mod_setting_set_next_value
                end,
            }{
                    ui_name = function() return get_text("iota_multiplayer.setting_player_num") end,
                    ui_description = function() return get_text("iota_multiplayer.settingdesc_player_num") end,
                },
        },
    }{
            ui_name = function() return get_text("iota_multiplayer.setting_player") end,
            ui_description = function() return get_text("iota_multiplayer.settingdesc_player") end,
        },
}

function table.find(list, pred)
    if type(pred) == "function" then
        for i, v in ipairs(list) do
            if pred(v) then
                return v, i
            end
        end
    else
        for i, v in ipairs(list) do
            if v == pred then
                return v, i
            end
        end
    end
end

local player_category = table.find(mod_settings, function(t)
    return t.category_id == "player"
end)
for i = 1, 8 do
    table.insert(player_category.settings,
        IndexTable{
            id = "player_color",
            value_default = 0xffffff,
            scope = nil,
            ui_fn = function(...)
                local raw_mod_setting_get_next_value = ModSettingGetNextValue
                local raw_mod_setting_set_next_value = ModSettingSetNextValue

                if GameGetWorldStateEntity() == 0 then
                    ModSettingGetNextValue = function() return 0xffffff end
                    ModSettingSetNextValue = function() end
                else
                    dofile_once("mods/iota_multiplayer/files/scripts/lib/utilities.lua")
                    ModSettingGetNextValue = function()
                        local player = get_player_at_index_including_disabled(i)
                        local player_object = Player(player)
                        return player_object:get_color()
                    end
                    ModSettingSetNextValue = function(id, value)
                        local player = get_player_at_index_including_disabled(i)
                        local player_object = Player(player)
                        player_object:set_color(value)
                    end
                end

                mod_setting_text_color(...)
                ModSettingGetNextValue = raw_mod_setting_get_next_value
                ModSettingSetNextValue = raw_mod_setting_set_next_value
            end,
        }{
            ui_name = function() return get_text("iota_multiplayer.setting_player_color"):format(i) end,
            ui_description = function() return get_text("iota_multiplayer.settingdesc_player_color"):format(i) end,
        })
    table.insert(player_category.settings,
        IndexTable{
            id = "player_autoaim",
            value_default = false,
            scope = nil,
            ui_fn = function(...)
                local raw_mod_setting_get_next_value = ModSettingGetNextValue
                local raw_mod_setting_set_next_value = ModSettingSetNextValue

                if GameGetWorldStateEntity() == 0 then
                    ModSettingGetNextValue = function() return false end
                    ModSettingSetNextValue = function() end
                else
                    dofile_once("mods/iota_multiplayer/files/scripts/lib/utilities.lua")
                    ModSettingGetNextValue = function()
                        local player = get_player_at_index_including_disabled(i)
                        local player_object = Player(player)
                        return player_object.autoaim_._enabled
                    end
                    ModSettingSetNextValue = function(id, value)
                        local player = get_player_at_index_including_disabled(i)
                        local player_object = Player(player)
                        player_object.autoaim_._enabled = value
                    end
                end

                mod_setting_bool(...)
                ModSettingGetNextValue = raw_mod_setting_get_next_value
                ModSettingSetNextValue = raw_mod_setting_set_next_value
            end,
        }{
            ui_name = function() return get_text("iota_multiplayer.setting_player_autoaim"):format(i) end,
            ui_description = function() return get_text("iota_multiplayer.settingdesc_player_autoaim"):format(i) end,
        })
end

function ModSettingsUpdate(init_scope)
    mod_settings_update(mod_id, mod_settings, init_scope)
end

function ModSettingsGuiCount()
    return mod_settings_gui_count(mod_id, mod_settings)
end

function ModSettingsGui(gui, in_main_menu)
    mod_settings_gui(mod_id, mod_settings, gui, in_main_menu)
end
