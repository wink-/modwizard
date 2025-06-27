ShortcutConfig = {}
ShortcutConfig.configCache = nil

-- ------------------------------------------------------ --
-- 序列化与文件操作
-- ------------------------------------------------------ --
function ShortcutConfig.serializeTable(val, name, skipnewlines, depth)
    skipnewlines = skipnewlines or false
    depth = depth or 0

    local tmp = string.rep("    ", depth)

    if name then 
        if type(name) == "string" and string.match(name, "^[%a_][%w_]*$") then
            tmp = tmp .. name .. " = "
        else
            tmp = tmp .. "[" .. string.format("%q", tostring(name)) .. "] = "
        end
    end

    if type(val) == "table" then
        tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")

        for k, v in pairs(val) do
            tmp = tmp .. ShortcutConfig.serializeTable(v, k, skipnewlines, depth + 1) .. "," .. (not skipnewlines and "\n" or "")
        end

        tmp = tmp .. string.rep("    ", depth) .. "}"
    elseif type(val) == "number" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    elseif type(val) == "boolean" then
        tmp = tmp .. (val and "true" or "false")
    else
        tmp = tmp .. "\"[" .. type(val) .. "]\""
    end

    return tmp
end

function ShortcutConfig.saveConfig(config)
    local file = getFileWriter("ShortcutConfig.lua", true, false)
    if file == nil then return nil end

    local contents = "return " .. ShortcutConfig.serializeTable(config)
    file:write(contents)
    file:close()

    ShortcutConfig.configCache = config
end

function ShortcutConfig.loadConfig()
    if ShortcutConfig.configCache then
        return ShortcutConfig.configCache
    end
    
    local file = getFileReader("ShortcutConfig.lua", true)
    if file == nil then return nil end

    local content = ""
    local line = file:readLine()
    while line do
        content = content .. line .. "\n"
        line = file:readLine()
    end
    file:close()
    
    if content == "" then return nil end
    
    local fn, errorMsg = loadstring(content)
    if fn then
        local config = fn()
        ShortcutConfig.configCache = config
        return config
    else
        print("Shortcut: Error loading config - " .. tostring(errorMsg))
        return nil
    end
end

-- ------------------------------------------------------ --
-- 配置访问接口
-- ------------------------------------------------------ --
function ShortcutConfig.getDefaultConfig()
    return {
        Author = "Rocco",
        settings = {
            rowCount = 1,
            columnCount = 5,
            panelX = nil,
            panelY = nil,
            slotSize = "medium",
            titleBarPosition = "top",
            pageType = "items",
            panelVisible = true,
            locked = false, 
            backgroundAlpha = 0.9,
            slotAlpha = 0.4,
            hotkey = 15,
        },
        slotItems = {},
        recipeSlots = {},
        buildSlots = {},
    }
end

function ShortcutConfig.getConfig()
    local config = ShortcutConfig.loadConfig()
    
    if not config then
        config = ShortcutConfig.getDefaultConfig()
        ShortcutConfig.saveConfig(config)
        return config
    end

    local defaults = ShortcutConfig.getDefaultConfig()
    local needsSave = false
    
    -- 确保配置中有所有必要的部分
    if not config.settings then
        config.settings = defaults.settings
        needsSave = true
    else
        for key, defaultValue in pairs(defaults.settings) do
            if config.settings[key] == nil then
                config.settings[key] = defaultValue
                needsSave = true
            end
        end
    end
    
    if not config.slotItems then
        config.slotItems = defaults.slotItems
        needsSave = true
    end
    
    if not config.recipeSlots then
        config.recipeSlots = defaults.recipeSlots
        needsSave = true
    end
    
    if not config.buildSlots then
        config.buildSlots = defaults.buildSlots
        needsSave = true
    end
    
    if needsSave then
        ShortcutConfig.saveConfig(config)
    end
    
    return config
end

-- ------------------------------------------------------ --
-- 物品槽位数据管理
-- ------------------------------------------------------ --
function ShortcutConfig.getSlotData(slotIndex)
    if not slotIndex then return nil end
    
    local slotKey = tostring(slotIndex)
    local slotItems = ShortcutConfig.getTable("slotItems", {})
    return slotItems[slotKey]
end

function ShortcutConfig.setSlotData(slotIndex, item)
    if not slotIndex then return end
    
    local slotKey = tostring(slotIndex)
    local slotItems = ShortcutConfig.getTable("slotItems", {})
    
    if item then
        if instanceof(item, "InventoryItem") then
            slotItems[slotKey] = {
                type = item:getFullType()
            }
        elseif type(item) == "table" and item.type then
            slotItems[slotKey] = {
                type = item.type
            }
        end
    else
        slotItems[slotKey] = nil
    end
    
    ShortcutConfig.setTable("slotItems", slotItems)
    return true
end

function ShortcutConfig.getAllSlots()
    return ShortcutConfig.getTable("slotItems", {})
end

function ShortcutConfig.clearAllSlots()
    ShortcutConfig.setTable("slotItems", {})
    return true
end

-- ------------------------------------------------------ --
-- 配方槽位数据管理
-- ------------------------------------------------------ --
function ShortcutConfig.getRecipeSlotData(slotIndex)
    if not slotIndex then return nil end
    
    local slotKey = tostring(slotIndex)
    local recipeSlots = ShortcutConfig.getTable("recipeSlots", {})
    return recipeSlots[slotKey]
end

function ShortcutConfig.setRecipeSlotData(slotIndex, data)
    if not slotIndex then return end
    
    local slotKey = tostring(slotIndex)
    local recipeSlots = ShortcutConfig.getTable("recipeSlots", {})
    
    if data then
        recipeSlots[slotKey] = data
    else
        recipeSlots[slotKey] = nil
    end
    
    ShortcutConfig.setTable("recipeSlots", recipeSlots)
    return true
end

function ShortcutConfig.getAllRecipeSlots()
    return ShortcutConfig.getTable("recipeSlots", {})
end

function ShortcutConfig.clearAllRecipeSlots()
    ShortcutConfig.setTable("recipeSlots", {})
    return true
end

-- ------------------------------------------------------ --
-- 建筑物槽位数据管理
-- ------------------------------------------------------ --
function ShortcutConfig.getBuildSlotData(slotIndex)
    if not slotIndex then return nil end
    
    local slotKey = tostring(slotIndex)
    local buildSlots = ShortcutConfig.getTable("buildSlots", {})
    return buildSlots[slotKey]
end

function ShortcutConfig.setBuildSlotData(slotIndex, data)
    if not slotIndex then return end
    
    local slotKey = tostring(slotIndex)
    local buildSlots = ShortcutConfig.getTable("buildSlots", {})
    
    if data then
        buildSlots[slotKey] = data
    else
        buildSlots[slotKey] = nil
    end
    
    ShortcutConfig.setTable("buildSlots", buildSlots)
    return true
end

function ShortcutConfig.getAllBuildSlots()
    return ShortcutConfig.getTable("buildSlots", {})
end

function ShortcutConfig.clearAllBuildSlots()
    ShortcutConfig.setTable("buildSlots", {})
    return true
end

-- ------------------------------------------------------ --
-- 通用配置访问接口
-- ------------------------------------------------------ --
function ShortcutConfig.getTable(tableName, defaultTable)
    local config = ShortcutConfig.getConfig()
    return config[tableName] or defaultTable or {}
end

function ShortcutConfig.setTable(tableName, tableData)
    local config = ShortcutConfig.getConfig()
    config[tableName] = tableData
    ShortcutConfig.saveConfig(config)
end

-- ------------------------------------------------------ --
-- 事件绑定
-- ------------------------------------------------------ --
Events.OnGameBoot.Add(ShortcutConfig.getConfig)

return ShortcutConfig