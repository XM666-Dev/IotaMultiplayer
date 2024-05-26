local function create_script(f)
    local t = setmetatable({}, { __index = _G })
    setfenv(f, t)()
    return t
end

return create_script(function()
    Script = create_script

    function import(self)
        for k, v in pairs(self) do
            _G[k] = v
        end
    end

    dofile_once("data/scripts/lib/utilities.lua")

    --#region

    function AccessorMetatable(list)
        return {
            __index = function(t, k)
                local access = list[k]
                if access then
                    return access.get()
                end
            end,
            __newindex = function(t, k, v)
                local access = list[k]
                if access then
                    return access.set(v)
                end
                rawset(t, k, v)
            end
        }
    end

    function ComponentValueAccess(component, field)
        return {
            get = function()
                return ComponentGetValue2(component, field)
            end,
            set = function(...)
                ComponentSetValue2(component, field, ...)
            end
        }
    end

    function EntityVariableAccess(entity, name, field, value)
        local component = get_variable_storage_component_or_add(entity, name, field, value)
        return ComponentValueAccess(component, field)
    end

    function TagEntityAccess(tag)
        return {
            get = function()
                return get_tag_entity(tag)
            end,
            set = function(v)
                set_tag_entity(tag, v)
            end
        }
    end

    function ComponentData(component)
        if not is_vaild(component) then
            return
        end
        local t = { id = component }
        setmetatable(t, {
            __index = function(t, k)
                return ComponentGetValue2(component, k)
            end,
            __newindex = function(t, k, v)
                ComponentSetValue2(component, k, v)
            end,
            __call = function(t, ...)
                return ComponentValueAccess(component, ...)
            end
        })
        return t
    end

    function ModData(mod)
        local t = { id = mod }
        setmetatable(t, {
            __index = function(t, k)
                return mod .. "." .. k
            end,
            __concat = function(t1, t2)
                return mod .. t2
            end
        })
        return t
    end

    STRING = "value_string"
    INT = "value_int"
    BOOL = "value_bool"
    FLOAT = "value_float"

    function get_variable_storage_component_or_add(entity, name, field, value)
        return get_variable_storage_component(entity, name) or EntityAddComponent2(entity, "VariableStorageComponent", { name = name, [field] = value })
    end

    function get_tag_entity(tag)
        return EntityGetWithTag(tag)[1]
    end

    function set_tag_entity(tag, entity)
        for _, tagged_entity in ipairs(EntityGetWithTag(tag)) do
            EntityRemoveTag(tagged_entity, tag)
        end
        EntityAddTag(entity, tag)
    end

    function is_vaild(id)
        return id and id > 0
    end

    function get_id(t)
        return rawget(t, "id")
    end

    --#endregion

    function append_translations(filename)
        local common = "data/translations/common.csv"
        ModTextFileSetContent(common, ModTextFileGetContent(common) .. ModTextFileGetContent(filename))
    end

    function has_globals_value_or_set(key)
        return GlobalsGetValue(key) ~= "" or GlobalsSetValue(key, "yes")
    end

    function get_camera_corner()
        local camera_x, camera_y = GameGetCameraPos()
        local _, _, w, h = GameGetCameraBounds()
        return camera_x - w / 2, camera_y - h / 2
    end

    function get_camera_zoom(gui)
        local _, _, camera_w, camera_h = GameGetCameraBounds()
        local screen_w, screen_h = GuiGetScreenDimensions(gui)
        return screen_w / camera_w, screen_h / camera_h
    end

    function get_pos_from_world(gui, x, y)
        local camera_x, camera_y = get_camera_corner()
        local zoom_x, zoom_y = get_camera_zoom(gui)
        return (x - camera_x) * zoom_x, (y - camera_y) * zoom_y
    end

    function get_frame_num_next()
        return GameGetFrameNum() + 1
    end

    function get_children(entity)
        return EntityGetAllChildren(entity) or {}
    end

    function sult_print(t)
        local s = ""
        for _, v in ipairs(t) do
            s = s .. tostring(v)
        end
        print(s)
        GamePrint(s)
    end

    function table.find(list, pred)
        for i, v in ipairs(list) do
            if pred(v) then
                return i
            end
        end
    end

    function table.filter(list, pred)
        local result = {}
        for _, v in ipairs(list) do
            if pred(v) then
                table.insert(result, v)
            end
        end
        return result
    end

    function table.iterate(list, comp, value)
        for _, v in ipairs(list) do
            if comp(v, value) then
                value = v
            end
        end
        return value
    end

    --#region

    NUMERIC_CHARACTERS = "0123456789"

    function Setting(setting, getters)
        return setmetatable(setting, {
            __index = function(t, k)
                local getter = getters[k]
                return getter and getter()
            end
        })
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

    --#endregion
end)
