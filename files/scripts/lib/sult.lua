dofile_once("data/scripts/lib/utilities.lua")

--#region

local ModTextFileSetContent = ModTextFileSetContent

NUMERIC_CHARACTERS = "0123456789"

function append_translations(filename)
    local common = "data/translations/common.csv"
    ModTextFileSetContent(common, ModTextFileGetContent(common) .. ModTextFileGetContent(filename):gsub("(.-\n)", "", 1))
end

function has_flag_run_or_add(flag)
    return GameHasFlagRun(flag) or GameAddFlagRun(flag)
end

function validate(id)
    return id and id > 0 and id or nil
end

function set_component_enabled(component, enabled)
    EntitySetComponentIsEnabled(ComponentGetEntity(component), component, enabled)
end

function get_children(entity, ...)
    return EntityGetAllChildren(entity, ...) or {}
end

function get_inventory_items(entity)
    return GameGetAllInventoryItems(entity) or {}
end

function get_game_effect(entity, name)
    local effect = GameGetGameEffect(entity, name)
    return validate(effect), validate(ComponentGetEntity(effect))
end

function get_frame_num_next()
    return GameGetFrameNum() + 1
end

function get_camera_corner()
    local camera_x, camera_y = GameGetCameraPos()
    local x, y, w, h = GameGetCameraBounds()
    return camera_x - w / 2, camera_y - h / 2
end

function get_camera_zoom(gui)
    local camera_x, camera_y, camera_w, camera_h = GameGetCameraBounds()
    local screen_w, screen_h = GuiGetScreenDimensions(gui)
    return screen_w / camera_w, screen_h / camera_h
end

function get_pos_on_screen(gui, x, y)
    local camera_x, camera_y = get_camera_corner()
    local zoom_x, zoom_y = get_camera_zoom(gui)
    return (x - camera_x) * zoom_x, (y - camera_y) * zoom_y
end

function get_attack_index(attacks)
    local index = 0
    for i, v in ipairs(attacks) do
        if ComponentGetIsEnabled(v) then
            index = i
        end
    end
    return index
end

function get_attack_table(ai, attack)
    local animation = "attack_ranged"
    local frames_between
    local action_frame
    local entity_file
    local entity_count_min
    local entity_count_max
    local offset_x
    local offset_y
    if ai ~= nil then
        frames_between = ComponentGetValue2(ai, "attack_ranged_frames_between")
        action_frame = ComponentGetValue2(ai, "attack_ranged_action_frame")
        entity_file = ComponentGetValue2(ai, "attack_ranged_entity_file")
        entity_count_min = ComponentGetValue2(ai, "attack_ranged_entity_count_min")
        entity_count_max = ComponentGetValue2(ai, "attack_ranged_entity_count_max")
        offset_x = ComponentGetValue2(ai, "attack_ranged_offset_x")
        offset_y = ComponentGetValue2(ai, "attack_ranged_offset_y")
    end
    if attack ~= nil then
        animation = ComponentGetValue2(attack, "animation_name")
        frames_between = ComponentGetValue2(attack, "frames_between")
        action_frame = ComponentGetValue2(attack, "attack_ranged_action_frame")
        entity_file = ComponentGetValue2(attack, "attack_ranged_entity_file")
        entity_count_min = ComponentGetValue2(attack, "attack_ranged_entity_count_min")
        entity_count_max = ComponentGetValue2(attack, "attack_ranged_entity_count_max")
        offset_x = ComponentGetValue2(attack, "attack_ranged_offset_x")
        offset_y = ComponentGetValue2(attack, "attack_ranged_offset_y")
    end
    return {
        animation = animation,
        frames_between = frames_between,
        action_frame = action_frame,
        entity_file = entity_file,
        entity_count_min = entity_count_min,
        entity_count_max = entity_count_max,
        offset_x = offset_x,
        offset_y = offset_y,
    }
end

function get_attack_ranged_pos(entity)
    local ai = EntityGetFirstComponentIncludingDisabled(entity, "AnimalAIComponent")
    local attacks = EntityGetComponent(entity, "AIAttackComponent") or {}
    local attack_table = get_attack_table(ai, attacks[#attacks])
    local x, y, rotation, scale_x, scale_y = EntityGetTransform(entity)
    return transform_mult(x, y, rotation, scale_x, scale_y, attack_table.offset_x, attack_table.offset_y, 0, 1, 1)
end

function entity_shoot(shooter)
    local ai = EntityGetFirstComponentIncludingDisabled(shooter, "AnimalAIComponent")
    local attacks = EntityGetComponent(shooter, "AIAttackComponent") or {}
    local attack_table = get_attack_table(ai, attacks[#attacks])
    local controls = EntityGetFirstComponent(shooter, "ControlsComponent")
    if controls ~= nil then
        local x, y = get_attack_ranged_pos(shooter)
        local aiming_vector_x, aiming_vector_y = ComponentGetValue2(controls, "mAimingVector")
        local projectile_entity = EntityLoad(attack_table.entity_file, x, y)
        GameShootProjectile(shooter, x, y, x + aiming_vector_x, y + aiming_vector_y, projectile_entity)
    end
end

local ids = {}
local max_id = 0x7FFFFFFF
function new_id(s)
    local id = ids[s]
    if id == nil then
        id = max_id
        ids[s] = id
        max_id = id - 1
    end
    return id
end

function serialize(value)
    local value_type = type(value)
    if value_type == "number" then
        return ("%.16a"):format(value)
    elseif value_type == "string" then
        return ("%q"):format(value)
    elseif value_type == "table" then
        local t = {}
        for k, v in pairs(value) do
            table.insert(t, ("[%s]=%s,"):format(serialize(k), serialize(v)))
        end
        return ("{%s}"):format(table.concat(t))
    end
    return tostring(value)
end

function deserialize(s)
    ModTextFileSetContent("data/scripts/empty.lua", "return " .. s)
    local f, err = loadfile("data/scripts/empty.lua")
    if f == nil then return f, err end
    return f()
end

function get_language()
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

function debug_print(...)
    local t = { ... }
    for i, v in ipairs(t) do
        t[i] = string.from(v)
    end
    local s = table.concat(t, ",")
    print(s)
    GamePrint(s)
end

--#endregion

--#region

function string.from(value)
    if type(value) == "table" then
        local t = {}
        for k, v in pairs(value) do
            table.insert(t, ("%s=%s"):format(string.from(k), string.from(v)))
        end
        return ("{%s}"):format(table.concat(t, ","))
    end
    return tostring(value)
end

function string.asub(s, repl)
    return s:gsub('(%g+)%s*=%s*"(.-)"', repl)
end

function table.find(list, pred)
    for i, v in ipairs(list) do
        if pred(v) then
            return i, v
        end
    end
end

function table.filter(list, pred)
    local result = {}
    for i, v in ipairs(list) do
        if pred(v) then
            table.insert(result, v)
        end
    end
    return result
end

function table.iterate(list, comp, value)
    for i, v in ipairs(list) do
        if comp(v, value) then
            value = v
        end
    end
    return value
end

function table.copy(t)
    local result = {}
    for k, v in pairs(t) do
        result[k] = v
    end
    return result
end

function math.round(x)
    return math.floor(x + 0.5)
end

function lerp(from, to, weight)
    return from + (to - from) * weight
end

function lerp_clamped(from, to, weight)
    return lerp(from, to, clamp(weight, 0, 1))
end

function warp(value, from, to)
    return (value - from) % (to - from) + from
end

function point_in_rectangle(x, y, left, up, right, down)
    return x >= left and x <= right and y >= up and y <= down
end

function Matrix(x, y, rotation, scale_x, scale_y)
    local cos_r = math.cos(rotation)
    local sin_r = math.sin(rotation)
    return {
        { scale_x * cos_r, -scale_y * sin_r, x },
        { scale_x * sin_r, scale_y * cos_r,  y },
        { 0,               0,                1 },
    }
end

function matrix_mult(m1, m2)
    local result = {}
    for i = 1, 3 do
        result[i] = {}
        for j = 1, 3 do
            result[i][j] = m1[i][1] * m2[1][j] + m1[i][2] * m2[2][j] + m1[i][3] * m2[3][j]
        end
    end
    return result
end

function matrix_to_transform(matrix)
    local scale_x = math.sqrt(matrix[1][1] ^ 2 + matrix[2][1] ^ 2)
    local scale_y = math.sqrt(matrix[1][2] ^ 2 + matrix[2][2] ^ 2)
    local rotation = math.atan2(matrix[2][1], matrix[1][1])
    local x = matrix[1][3]
    local y = matrix[2][3]
    return x, y, rotation, scale_x, scale_y
end

function transform_mult(x1, y1, rotation1, scale_x1, scale_y1, x2, y2, rotation2, scale_x2, scale_y2)
    local matrix1 = Matrix(x1, y1, rotation1, scale_x1, scale_y1)
    local matrix2 = Matrix(x2, y2, rotation2, scale_x2, scale_y2)
    local matrix3 = matrix_mult(matrix1, matrix2)
    return matrix_to_transform(matrix3)
end

--#endregion

function Metatable(accessors)
    local getters = {}
    for k, accessor in pairs(accessors) do
        getters[k] = accessor.get
    end
    local setters = {}
    for k, accessor in pairs(accessors) do
        setters[k] = accessor.set
    end
    return {
        __index = function(t, k)
            return (getters[k] or rawget)(t, k)
        end,
        __newindex = function(t, k, v)
            (setters[k] or rawset)(t, k, v)
        end,
    }
end

function Class(accessors)
    local getters = {}
    for k, accessor in pairs(accessors) do
        getters[k] = accessor.get
    end
    local setters = {}
    for k, accessor in pairs(accessors) do
        setters[k] = accessor.set
    end
    return {
        __index = function(t, k)
            return getters[k](t, k)
        end,
        __newindex = function(t, k, v)
            setters[k](t, k, v)
        end,
    }
end

function Table(t, getters, setters)
    return setmetatable(t, {
        __index = function(t, k)
            return (getters[k] or rawget)(t, k)
        end,
        __newindex = function(t, k, v)
            (setters[k] or rawset)(t, k, v)
        end,
    })
end

function EntityAccessor(tag, pred)
    return {
        get = function(t, k)
            local entity = EntityGetWithTag(tag)[1]
            return (pred == nil or pred(entity)) and entity or nil
        end,
        set = function(t, k, v)
            for i, entity in ipairs(EntityGetWithTag(tag)) do
                EntityRemoveTag(entity, tag)
            end
            EntityAddTag(v, tag)
        end,
    }
end

local metatable = {
    __index = function(t, k)
        return { ComponentGetValue2(t._id, k) }
    end,
    __newindex = function(t, k, v)
        ComponentSetValue2(t._id, k, unpack(v))
    end,
}
local component_metatable = {
    __index = function(t, k)
        return ComponentGetValue2(t._id, k)
    end,
    __newindex = function(t, k, v)
        ComponentSetValue2(t._id, k, v)
    end,
    __call = function(t, ...)
        return setmetatable(t, metatable)
    end,
}
function ComponentAccessor(f, ...)
    local args = { ... }
    local self = {}
    self.get = function(t, k)
        local cached = t[self]
        if cached == nil then
            local entity = t.id
            local component = f(entity, unpack(args))
            if component == nil then
                return nil
            end
            cached = { _id = component }
            t[self] = cached
        end
        return setmetatable(cached, component_metatable)
    end
    return self
end

function VariableAccessor(tag, field, default)
    local self = {}
    self.get = function(t, k)
        local component = t[self]
        if component == nil then
            local entity = t.id
            component = EntityGetFirstComponent(entity, "VariableStorageComponent", tag) or EntityAddComponent2(entity, "VariableStorageComponent", { _tags = tag, [field] = default })
            t[self] = component
        end
        return ComponentGetValue2(component, field)
    end
    self.set = function(t, k, v)
        local component = t[self]
        if component == nil then
            local entity = t.id
            component = EntityGetFirstComponent(entity, "VariableStorageComponent", tag) or EntityAddComponent2(entity, "VariableStorageComponent", { _tags = tag, [field] = default })
            t[self] = component
        end
        ComponentSetValue2(component, field, v)
    end
    return self
end

function ConstantAccessor(value)
    return { get = function() return value end }
end

function SerializedAccessor(accessor, filename, value_date_filename, file_date_filename)
    if not ModDoesFileExist(value_date_filename) then
        ModTextFileSetContent(value_date_filename, "1")
    end
    if not ModDoesFileExist(file_date_filename) then
        ModTextFileSetContent(file_date_filename, "0")
    end
    local function get_value_date()
        return tonumber(ModTextFileGetContent(value_date_filename))
    end
    local function set_value_date(n)
        ModTextFileSetContent(value_date_filename, tostring(n))
    end
    local function get_file_date()
        return tonumber(ModTextFileGetContent(file_date_filename))
    end
    local function set_file_date(n)
        ModTextFileSetContent(file_date_filename, tostring(n))
    end
    local cache
    local cache_date = 0
    return {
        get = function(t, k)
            if cache_date < get_value_date() then
                if get_file_date() < get_value_date() then
                    ModTextFileSetContent(filename, "return " .. accessor.get(t, k))
                    set_file_date(get_value_date())
                end
                cache = loadfile(filename)()
                cache_date = get_value_date()
            end
            return cache
        end,
        set = function(t, k, v)
            accessor.set(t, k, serialize(v))
            set_value_date(get_value_date() + 1)
            cache = v
            cache_date = get_value_date()
        end,
    }
end
