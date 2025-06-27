Shortcut = {}
Shortcut.panel = nil
Shortcut.isInitialized = false
Shortcut.controlWidget = nil
Shortcut.settingsPanel = nil

Shortcut.getDefaultSettings = function()
    return ShortcutConfig.getDefaultConfig().settings
end

-- ------------------------------------------------------ --
-- 模组初始化和生命周期管理
-- ------------------------------------------------------ --
Shortcut.onKeyPressed = function(key)
    local configuredHotkey = Shortcut.getHotkey()
    if key == configuredHotkey then
        Shortcut.togglePanel()
    end
end

Shortcut.closeOnDeath = function()
    if Shortcut.panel then
        -- 保存当前位置
        if Shortcut.panel.x and Shortcut.panel.y then
            Shortcut.setPanelPosition(Shortcut.panel.x, Shortcut.panel.y)
        end
        
        if Shortcut.panel.controlWidget then
            Shortcut.panel.controlWidget:removeFromUIManager()
            Shortcut.panel.controlWidget = nil
        end
        
        Shortcut.panel:removeFromUIManager()
        Shortcut.panel = nil
    end
end

-- 死亡事件处理函数
Shortcut.onPlayerDeath = function(player)
    if player:getPlayerNum() == 0 then
        if Shortcut.panel then
            print("Player died, temporarily closing Shortcut panel")
            Shortcut.closeOnDeath()
        end
    end
end

Shortcut.onCreatePlayer = function(playerIndex, player)
    if playerIndex == 0 and not player:isDead() and Shortcut.isPanelVisible() then
        ShortcutPanel.create()
    end
end

-- ------------------------------------------------------ --
-- 设置管理功能
-- ------------------------------------------------------ --
-- 面板可见性设置
Shortcut.isPanelVisible = function()
    local settings = ShortcutConfig.getTable("settings")
    if settings.panelVisible ~= nil then
        return settings.panelVisible
    else
        return Shortcut.getDefaultSettings().panelVisible
    end
end
Shortcut.setPanelVisible = function(visible)
    local settings = ShortcutConfig.getTable("settings")
    settings.panelVisible = visible
    ShortcutConfig.setTable("settings", settings)
end
-- -------------------------------------------------------- --
-- 行数设置
Shortcut.getRowCount = function()
    local settings = ShortcutConfig.getTable("settings")
    return settings.rowCount or Shortcut.getDefaultSettings().rowCount
end
Shortcut.setRowCount = function(count)
    local settings = ShortcutConfig.getTable("settings")
    settings.rowCount = count
    ShortcutConfig.setTable("settings", settings)
end
-- -------------------------------------------------------- --
-- 列数设置
Shortcut.getColumnCount = function()
    local settings = ShortcutConfig.getTable("settings")
    return settings.columnCount or Shortcut.getDefaultSettings().columnCount
end
Shortcut.setColumnCount = function(count)
    local settings = ShortcutConfig.getTable("settings")
    settings.columnCount = count
    ShortcutConfig.setTable("settings", settings)
end
-- -------------------------------------------------------- --
-- 面板位置设置
Shortcut.getPanelPosition = function()
    local settings = ShortcutConfig.getTable("settings")
    return settings.panelX, settings.panelY
end
Shortcut.setPanelPosition = function(x, y)
    local settings = ShortcutConfig.getTable("settings")
    settings.panelX = x
    settings.panelY = y
    ShortcutConfig.setTable("settings", settings)
end
-- -------------------------------------------------------- --
-- 槽位大小设置
Shortcut.getSlotSizeType = function()
    local settings = ShortcutConfig.getTable("settings")
    return settings.slotSize or Shortcut.getDefaultSettings().slotSize
end
Shortcut.setSlotSizeType = function(sizeType)
    local settings = ShortcutConfig.getTable("settings")
    settings.slotSize = sizeType
    ShortcutConfig.setTable("settings", settings)
end

Shortcut.getActualSlotSize = function()
    local sizeType = Shortcut.getSlotSizeType()
    if sizeType == "small" then
        return 42  -- 42 * 2/3 = 28
    elseif sizeType == "medium-large" then
        return 54  -- 54 * 2/3 = 36 
    elseif sizeType == "large" then
        return 63  -- 63 * 2/3 = 42 
    else
        return 48  -- 48 * 2/3 = 32 
    end
end

Shortcut.getActualIconSize = function()
    local slotSize = Shortcut.getActualSlotSize()
    return math.floor(slotSize * 2/3)
end
-- -------------------------------------------------------- --
-- 标题栏位置设置
Shortcut.getTitleBarPosition = function()
    local settings = ShortcutConfig.getTable("settings")
    return settings.titleBarPosition or Shortcut.getDefaultSettings().titleBarPosition
end
Shortcut.setTitleBarPosition = function(position)
    local settings = ShortcutConfig.getTable("settings")
    settings.titleBarPosition = position
    ShortcutConfig.setTable("settings", settings)
end
-- -------------------------------------------------------- --
-- 页面类型设置
Shortcut.getPageType = function()
    local settings = ShortcutConfig.getTable("settings")
    return settings.pageType or "items"
end

Shortcut.setPageType = function(pageType)
    local settings = ShortcutConfig.getTable("settings")
    settings.pageType = pageType
    ShortcutConfig.setTable("settings", settings)
end

Shortcut.addRecipeToSlot = function(recipeData)
    if not recipeData or not recipeData.name then 
        return false 
    end
    
    if Shortcut.getPageType() ~= "recipes" then
        Shortcut.setPageType("recipes")
        Shortcut.refreshPanel()
    end
    
    local slotCount = Shortcut.getRowCount() * Shortcut.getColumnCount()
    for i = 1, slotCount do
        if not ShortcutConfig.getRecipeSlotData(i) then
            ShortcutRecipeSlot.updateSlotRecipe(i, recipeData)
            
            if Shortcut.panel then
                Shortcut.panel:updateRecipeSlot(i)
            end
            return true
        end
    end
    return false
end

Shortcut.addBuildingToSlot = function(buildingData)
    if not buildingData or not buildingData.name then 
        return false 
    end
    
    buildingData.isBuilding = true
    
    if Shortcut.getPageType() ~= "buildings" then
        Shortcut.setPageType("buildings")
        Shortcut.refreshPanel()
    end
    
    local slotCount = Shortcut.getRowCount() * Shortcut.getColumnCount()
    for i = 1, slotCount do
        if not ShortcutConfig.getBuildSlotData(i) then
            ShortcutBuildSlot.updateSlotBuild(i, buildingData)
            
            if Shortcut.panel then
                Shortcut.panel:updateBuildSlot(i)
            end
            return true
        end
    end
    return false
end
-- -------------------------------------------------------- --
-- 面板锁定状态设置
Shortcut.isPanelLocked = function()
    local settings = ShortcutConfig.getTable("settings")
    return settings.locked or false
end

Shortcut.setPanelLocked = function(locked)
    local settings = ShortcutConfig.getTable("settings")
    settings.locked = locked
    ShortcutConfig.setTable("settings", settings)
end

-- -------------------------------------------------------- --
-- 背景透明度设置
Shortcut.getBackgroundAlpha = function()
    local settings = ShortcutConfig.getTable("settings")
    return settings.backgroundAlpha or Shortcut.getDefaultSettings().backgroundAlpha
end
Shortcut.setBackgroundAlpha = function(alpha)
    local settings = ShortcutConfig.getTable("settings")
    settings.backgroundAlpha = alpha
    ShortcutConfig.setTable("settings", settings)
end

-- -------------------------------------------------------- --
-- 槽位透明度设置
Shortcut.getSlotAlpha = function()
    local settings = ShortcutConfig.getTable("settings")
    return settings.slotAlpha or Shortcut.getDefaultSettings().slotAlpha
end
Shortcut.setSlotAlpha = function(alpha)
    local settings = ShortcutConfig.getTable("settings")
    settings.slotAlpha = alpha
    ShortcutConfig.setTable("settings", settings)
end

-- -------------------------------------------------------- --
-- 快捷键设置
Shortcut.getHotkey = function()
    local settings = ShortcutConfig.getTable("settings")
    return settings.hotkey or Shortcut.getDefaultSettings().hotkey
end

Shortcut.setHotkey = function(keyCode)
    local settings = ShortcutConfig.getTable("settings")
    settings.hotkey = keyCode
    ShortcutConfig.setTable("settings", settings)
end
-- ------------------------------------------------------ --
-- 面板控制接口
-- ------------------------------------------------------ --
Shortcut.createPanel = function()
    if not Shortcut.panel then
        ShortcutPanel.create()
        Shortcut.setPanelVisible(true)
        if Shortcut.getPageType() == "items" then
            ShortcutItem.itemsCache = nil
            ShortcutItem.lastPlayerWeight = -1
        end

    end
end

Shortcut.closePanel = function()
    if Shortcut.panel then
        -- 先清理控制组件
        if Shortcut.panel.controlWidget then
            Shortcut.panel.controlWidget:removeFromUIManager()
            Shortcut.panel.controlWidget = nil
        end
        
        Shortcut.panel:removeFromUIManager()
        Shortcut.panel = nil
        Shortcut.setPanelVisible(false)
    end
end

Shortcut.togglePanel = function()
    if Shortcut.panel then
        Shortcut.closePanel()
    else
        Shortcut.createPanel()
    end
end

Shortcut.refreshPanel = function()
    local wasVisible = (Shortcut.panel ~= nil)
    
    if Shortcut.panel then
        if Shortcut.panel.x and Shortcut.panel.y then
            Shortcut.setPanelPosition(Shortcut.panel.x, Shortcut.panel.y)
        end
        
        Shortcut.closePanel()
    end
    
    if wasVisible then
        Shortcut.createPanel()

    end
end

Shortcut.updatePanelContent = function()
    if not Shortcut.panel then return end
    
    local panel = Shortcut.panel
    local previousPageType = panel.pageType
    local newPageType = Shortcut.getPageType()
    
    if previousPageType == newPageType then return end
    
    -- 移除旧的槽位
    if previousPageType == "items" then
        for _, slot in ipairs(panel.slots) do
            panel:removeChild(slot)
        end
        panel.slots = {}
    elseif previousPageType == "recipes" then
        for _, slot in ipairs(panel.recipeSlots) do
            panel:removeChild(slot)
        end
        panel.recipeSlots = {}
    elseif previousPageType == "buildings" then
        for _, slot in ipairs(panel.buildSlots) do
            panel:removeChild(slot)
        end
        panel.buildSlots = {}
    end
    
    -- 更新面板的页面类型
    panel.pageType = newPageType
    
    -- 创建新的槽位
    panel:createSlots()

    -- 更新控制组件上的按钮图标
    if panel.controlWidget and panel.controlWidget.pageTypeButton then
        local button = panel.controlWidget.pageTypeButton
        button.buttonType = newPageType
        
        if newPageType == "items" then
            button.iconTexture = panel.controlWidget.buttonTextures.itemsIcon
            panel:updateAllSlotsData()
            ShortcutItem.itemsCache = nil
            ShortcutItem.lastPlayerWeight = -1
        elseif newPageType == "recipes" then
            button.iconTexture = panel.controlWidget.buttonTextures.recipesIcon
            panel:updateAllRecipeSlotsData()
        elseif newPageType == "buildings" then
            button.iconTexture = panel.controlWidget.buttonTextures.buildingsIcon
            panel:updateAllBuildSlotsData()
        end
    end
end

Shortcut.openSettings = function()
    if Shortcut.settingsPanel and Shortcut.settingsPanel:isVisible() then
        Shortcut.settingsPanel:bringToTop()
    else
        -- 清理可能存在的旧实例
        if Shortcut.settingsPanel then
            Shortcut.settingsPanel:removeFromUIManager()
            Shortcut.settingsPanel = nil
        end
        
        -- 创建新的设置面板
        Shortcut.settingsPanel = ShortcutSettingsPanel:new()
        Shortcut.settingsPanel:initialise()
        Shortcut.settingsPanel:addToUIManager()
    end
end

-- ------------------------------------------------------ --
-- 模组入口点
-- ------------------------------------------------------ --
Events.OnKeyPressed.Add(Shortcut.onKeyPressed)
Events.OnPlayerDeath.Add(Shortcut.onPlayerDeath)
Events.OnCreatePlayer.Add(Shortcut.onCreatePlayer)

return Shortcut
