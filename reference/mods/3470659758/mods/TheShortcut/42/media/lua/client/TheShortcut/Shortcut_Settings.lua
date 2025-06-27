require "ISUI/ISPanel"
require "ISUI/ISButton"
require "ISUI/ISLabel"

ShortcutSettingsPanel = ISPanel:derive("ShortcutSettingsPanel")

-- ------------------------------------------------------ --
-- 面板初始化
-- ------------------------------------------------------ --
function ShortcutSettingsPanel:new()
    local o = ISPanel:new(0, 0, 0, 0)
    setmetatable(o, self)
    self.__index = self
    
    o.backgroundColor = {r=0.1, g=0.1, b=0.1, a=0}
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=0}
    o.moveWithMouse = true
    o.rowCount = Shortcut.getRowCount() 
    o.columnCount = Shortcut.getColumnCount()
    o.slotSizeType = Shortcut.getSlotSizeType()
    o.controlWidgetPosition = Shortcut.getTitleBarPosition()
    o.backgroundAlpha = Shortcut.getBackgroundAlpha()
    o.slotAlpha = Shortcut.getSlotAlpha()
    
    o.fontHeight = getTextManager():getFontHeight(UIFont.Small)
    o.titleBarHeight = o.fontHeight * 1.2
    o.buttonSize = o.fontHeight
    
    o.gridColumns = 3
    o.settingItems = {}
    o.gridItems = {}
    o.itemWidth = o.fontHeight * 6
    o.itemHeight = o.fontHeight * 4
    o.itemMarginX = 15
    o.itemMarginY = 20
    o.panelMargin = 20
    
    o.buttonBgTexture = getTexture("media/ui/TheShortCut/TheShortCut_Settng_BackGround.png")
    o.buttonHoverTexture = getTexture("media/ui/TheShortCut/TheShortCut_Settng_Hover.png")
    o.buttonBorderTexture = getTexture("media/ui/TheShortCut/TheShortCut_Settng_Boarder.png")
    
    o.decreaseTexture = getTexture("media/ui/TheShortCut/Icon/icon_decrease.png")
    o.increaseTexture = getTexture("media/ui/TheShortCut/Icon/icon_increase.png")
    o.smallTexture = getTexture("media/ui/TheShortCut/Icon/icon_small.png")
    o.mediumTexture = getTexture("media/ui/TheShortCut/Icon/icon_medium.png")
    o.mediumlargeTexture = getTexture("media/ui/TheShortCut/Icon/icon_medium_large.png")
    o.largeTexture = getTexture("media/ui/TheShortCut/Icon/icon_large.png")
    
    -- 使用已有的四个方向图标
    o.topTexture = getTexture("media/ui/TheShortCut/Icon/icon_top.png")
    o.bottomTexture = getTexture("media/ui/TheShortCut/Icon/icon_bottom.png")
    o.leftTexture = getTexture("media/ui/TheShortCut/Icon/icon_left.png")
    o.rightTexture = getTexture("media/ui/TheShortCut/Icon/icon_right.png")
    
    o.closeTexture = getTexture("media/ui/TheShortCut/Icon/icon_close.png")
    o.resetTexture = getTexture("media/ui/TheShortCut/Icon/icon_Reset.png")
    o.lockTexture = getTexture("media/ui/TheShortCut/Icon/icon_lock.png")
    
    o.cellNineSliceTextures = {
        topLeft = getTexture("media/ui/TheShortCut/SettingPanel/TheShortCut_SetP_Cell_LT.png"),
        top = getTexture("media/ui/TheShortCut/SettingPanel/TheShortCut_SetP_Cell_T.png"),
        topRight = getTexture("media/ui/TheShortCut/SettingPanel/TheShortCut_SetP_Cell_RT.png"),
        left = getTexture("media/ui/TheShortCut/SettingPanel/TheShortCut_SetP_Cell_L.png"),
        middle = getTexture("media/ui/TheShortCut/SettingPanel/TheShortCut_SetP_Cell_M.png"),
        right = getTexture("media/ui/TheShortCut/SettingPanel/TheShortCut_SetP_Cell_R.png"),
        bottomLeft = getTexture("media/ui/TheShortCut/SettingPanel/TheShortCut_SetP_Cell_LB.png"),
        bottom = getTexture("media/ui/TheShortCut/SettingPanel/TheShortCut_SetP_Cell_B.png"),
        bottomRight = getTexture("media/ui/TheShortCut/SettingPanel/TheShortCut_SetP_Cell_RB.png")
    }

    o.panelContentNineSliceTextures = {
        topLeft = getTexture("media/ui/TheShortCut/SettingPanel/TheShortCut_SetP_BG_L.png"),
        top = getTexture("media/ui/TheShortCut/SettingPanel/TheShortCut_SetP_BG_M.png"),
        topRight = getTexture("media/ui/TheShortCut/SettingPanel/TheShortCut_SetP_BG_R.png"),
        left = getTexture("media/ui/TheShortCut/SettingPanel/TheShortCut_SetP_BG_L.png"),
        middle = getTexture("media/ui/TheShortCut/SettingPanel/TheShortCut_SetP_BG_M.png"),
        right = getTexture("media/ui/TheShortCut/SettingPanel/TheShortCut_SetP_BG_R.png"),
        bottomLeft = getTexture("media/ui/TheShortCut/SettingPanel/TheShortCut_SetP_BG_LB.png"),
        bottom = getTexture("media/ui/TheShortCut/SettingPanel/TheShortCut_SetP_BG_B.png"),
        bottomRight = getTexture("media/ui/TheShortCut/SettingPanel/TheShortCut_SetP_BG_RB.png")
    }

    o.titleBarThreeSliceTextures = {
        left = getTexture("media/ui/TheShortCut/SettingPanel/TheShortCut_SetP_TitleBar_L.png"),
        middle = getTexture("media/ui/TheShortCut/SettingPanel/TheShortCut_SetP_TitleBar_M.png"),
        right = getTexture("media/ui/TheShortCut/SettingPanel/TheShortCut_SetP_TitleBar_R.png")
    }

    o.hotkeyButtonBgTextures = {
        left = getTexture("media/ui/TheShortCut/SettingPanel/TheShortCut_SetP_Button_BG_L.png"),
        middle = getTexture("media/ui/TheShortCut/SettingPanel/TheShortCut_SetP_Button_BG_M.png"),
        right = getTexture("media/ui/TheShortCut/SettingPanel/TheShortCut_SetP_Button_BG_R.png")
    }
    
    o.hotkeyButtonBorderTextures = {
        left = getTexture("media/ui/TheShortCut/SettingPanel/TheShortCut_SetP_Button_Border_L.png"),
        middle = getTexture("media/ui/TheShortCut/SettingPanel/TheShortCut_SetP_Button_Border_M.png"),
        right = getTexture("media/ui/TheShortCut/SettingPanel/TheShortCut_SetP_Button_Border_R.png")
    }
    
    o.hotkeyButtonHoverTextures = {
        left = getTexture("media/ui/TheShortCut/SettingPanel/TheShortCut_SetP_ButtonHover_L.png"),
        middle = getTexture("media/ui/TheShortCut/SettingPanel/TheShortCut_SetP_ButtonHover_M.png"),
        right = getTexture("media/ui/TheShortCut/SettingPanel/TheShortCut_SetP_ButtonHover_R.png")
    }
    
    return o
end

function ShortcutSettingsPanel:initialise()
    ISPanel.initialise(self)
    self:createChildren()
    
    self:calculatePanelSize()
    
    local screenWidth = getCore():getScreenWidth()
    local screenHeight = getCore():getScreenHeight()
    self:setX((screenWidth - self.width) / 2)
    self:setY((screenHeight - self.height) / 2)
end

function ShortcutSettingsPanel:calculatePanelSize()
    local totalRows = math.ceil(#self.settingItems / self.gridColumns)
    local contentHeight = self.titleBarHeight + self.panelMargin + 
                         (totalRows * (self.itemHeight + self.itemMarginY)) + self.panelMargin
    
    local contentWidth = (self.gridColumns * (self.itemWidth + self.itemMarginX)) + self.panelMargin
    
    self:setWidth(contentWidth)
    self:setHeight(contentHeight)
    
    if self.closeXButton then
        self.closeXButton:setX(self.width - self.buttonSize - 4)
    end
end

-- ------------------------------------------------------ --
-- 自定义设置项管理
-- ------------------------------------------------------ --

function ShortcutSettingsPanel:onLockButtonClick()
    local newLockState = not Shortcut.isPanelLocked()
    Shortcut.setPanelLocked(newLockState)
    self.lockButton.selected = newLockState
end

function ShortcutSettingsPanel:addSettingItem(id, title, createContentFunc)
    for _, item in ipairs(self.settingItems) do
        if item.id == id then
            return item
        end
    end
    
    local item = {
        id = id,
        title = title,
        createContent = createContentFunc,
        panel = nil
    }
    table.insert(self.settingItems, item)
    return item
end

function ShortcutSettingsPanel:layoutSettingItems()
    for _, item in ipairs(self.gridItems) do
        if item then
            self:removeChild(item)
        end
    end
    self.gridItems = {}
    
    local startY = self.titleBarHeight + self.panelMargin
    
    for i, itemData in ipairs(self.settingItems) do
        local col = (i - 1) % self.gridColumns
        local row = math.floor((i - 1) / self.gridColumns)
        local x = (self.itemWidth + self.itemMarginX) * col + self.panelMargin
        local y = startY + (self.itemHeight + self.itemMarginY) * row
        
        local panel = self:createSettingItemPanel(itemData.title, x, y, itemData.createContent)
        itemData.panel = panel
        table.insert(self.gridItems, panel)
    end
    
    self:calculatePanelSize()
    
    local screenWidth = getCore():getScreenWidth()
    local screenHeight = getCore():getScreenHeight()
    self:setX((screenWidth - self.width) / 2)
    self:setY((screenHeight - self.height) / 2)
end

function ShortcutSettingsPanel:createSettingItemPanel(title, x, y, contentCreator)
    local item = ISPanel:new(x, y, self.itemWidth, self.itemHeight)
    item:initialise()
    
    item.backgroundColor = {r=0, g=0, b=0, a=0}
    item.borderColor = {r=0, g=0, b=0, a=0}
    
    item.nineSliceTextures = self.cellNineSliceTextures
    
    local originalPrerender = item.prerender
    item.prerender = function(self)
        originalPrerender(self)
        
        ShortcutUIHelper.drawNineSlice(
            self, 0, 0, self.width, self.height, 
            self.nineSliceTextures, 0.8, 0.5, 0.5, 0.5
        )
    end
    
    self:addChild(item)
    
    -- 创建标题标签
    local titleLabel = ISLabel:new(0, self.fontHeight * 0.5, 20, title, 1, 1, 1, 1, UIFont.Small, true)
    item:addChild(titleLabel)
    
    -- 计算文本宽度和可用空间
    local textWidth = getTextManager():MeasureStringX(UIFont.Small, title)
    local availableWidth = item:getWidth() * 0.8
    
    -- 检查文本是否需要滚动
    if textWidth > availableWidth then
        local charWidth = textWidth / string.len(title)
        local maxChars = math.floor(availableWidth / charWidth)
        
        -- 初始化时显示文本开头
        local displayText = string.sub(title, 1, maxChars)
        titleLabel:setName(displayText)
        
        -- 初始时居中显示
        local displayWidth = getTextManager():MeasureStringX(UIFont.Small, displayText)
        titleLabel:setX((item:getWidth() - displayWidth) / 2)
        
        -- 添加滚动属性
        item.fullText = title
        item.displayText = displayText
        item.maxChars = maxChars
        item.scrollPos = 0
        item.scrollDirection = 1 
        item.pauseCounter = 5
        item.needsScroll = true
        item.titleLabel = titleLabel
        
        -- 更新显示的文本
        item.updateScrollText = function(self)
            if not self.needsScroll then return end
            
            if self.pauseCounter > 0 then
                self.pauseCounter = self.pauseCounter - 1
                return
            end
            
            local textLen = string.len(self.fullText)
            
            self.scrollPos = self.scrollPos + (self.scrollDirection * 1.25)
            
            self.scrollPos = math.floor(self.scrollPos + 0.5)
            
            -- 边界检查与方向切换
            if self.scrollDirection > 0 and self.scrollPos >= (textLen - self.maxChars) then
                self.scrollDirection = -1
                self.pauseCounter = 24
                self.scrollPos = textLen - self.maxChars
            elseif self.scrollDirection < 0 and self.scrollPos <= 0 then
                self.scrollDirection = 1
                self.pauseCounter = 24
                self.scrollPos = 0
            end
            
            if self.scrollPos + self.maxChars <= textLen then
                self.displayText = string.sub(self.fullText, self.scrollPos + 1, self.scrollPos + self.maxChars)
            else
                self.displayText = string.sub(self.fullText, self.scrollPos + 1)
            end
            
            self.titleLabel:setName(self.displayText)
            
            local currentWidth = getTextManager():MeasureStringX(UIFont.Small, self.displayText)
            self.titleLabel:setX((self:getWidth() - currentWidth) / 2)
        end
        
        -- 绑定更新函数
        local originalUpdate = item.update or function() end
        item.update = function(self)
            originalUpdate(self)
            self:updateScrollText()
        end
    else
        titleLabel:setX((item:getWidth() - titleLabel:getWidth()) / 2)
    end
    
    if contentCreator then
        contentCreator(item, self.fontHeight * 2)
    end
    
    return item
end

-- ------------------------------------------------------ --
-- 自定义UI组件创建
-- ------------------------------------------------------ --
function ShortcutSettingsPanel:createCustomButton(x, y, target, onclick, iconTexture, buttonSize)
    local size = buttonSize or self.buttonSize
    
    local button = ISButton:new(x, y, size, size, "", target, onclick)
    button:initialise()
    button.backgroundColor = {r=0.2, g=0.2, b=0.2, a=0}
    button.backgroundColorMouseOver = {r=0.3, g=0.3, b=0.3, a=0}
    button.borderColor = {r=0, g=0, b=0, a=0}
    
    button.bgTexture = self.buttonBgTexture
    button.hoverTexture = self.buttonHoverTexture
    button.borderTexture = self.buttonBorderTexture
    button.iconTexture = iconTexture
    button.selected = false
    
    button.render = function(self)
        local bgA, bgR, bgG, bgB = 0.8, 0.2, 0.2, 0.2
        
        if self.selected then
            bgA, bgR, bgG, bgB = 1, 0.95, 0.6, 0.2
        end
        
        self:drawTextureScaled(self.bgTexture, 0, 0, self.width, self.height, bgA, bgR, bgG, bgB)
        
        self:drawTextureScaled(self.borderTexture, 0, 0, self.width, self.height, 0.8, 0.5, 0.5, 0.5)
        
        if self.mouseOver then
            self:drawTextureScaled(self.hoverTexture, 0, 0, self.width, self.height, 0.4, 1, 1, 1)
        end
        
        if self.iconTexture then
            local iconSize = self.height
            local iconX = (self.width - iconSize) / 2
            local iconY = (self.height - iconSize) / 2
            self:drawTextureScaled(self.iconTexture, iconX, iconY, iconSize, iconSize, 1, 1, 1, 1)
        end
    end
    
    return button
end

-- ------------------------------------------------------ --
-- 通用设置项类型创建方法
-- ------------------------------------------------------ --
function ShortcutSettingsPanel:addNumberSetting(id, title, getValue, setValue, minValue, maxValue)
    return self:addSettingItem(id, title, function(item, startY)
        local currentValue = getValue()
        
        local buttonSpacing = 10
        
        local _, textureHeight = ShortcutUIHelper.getTextureSize()
        local scale = (self.buttonSize * 0.8) / textureHeight
        
        local valueText = tostring(currentValue)
        local textWidth = ShortcutUIHelper.measureTextWidth(valueText, scale)
        
        local totalWidth = self.buttonSize * 2 + textWidth + buttonSpacing * 2
        local startX = (item:getWidth() - totalWidth) / 2
        
        local textX = startX + self.buttonSize + buttonSpacing
        local valuePanel = ISPanel:new(textX, startY, textWidth, self.buttonSize)
        valuePanel:initialise()
        valuePanel:instantiate()
        valuePanel.backgroundColor = {r=0, g=0, b=0, a=0}
        valuePanel.borderColor = {r=0, g=0, b=0, a=0}
        valuePanel.currentValue = currentValue
        valuePanel.scale = scale
        
        valuePanel.render = function(self)
            if not ShortcutUIHelper.isLoaded then
                ShortcutUIHelper.loadTextures()
            end
            
            local scaledHeight = textureHeight * self.scale
            local textY = (self.height - scaledHeight) / 2
            
            local valueText = tostring(self.currentValue)
            ShortcutUIHelper.renderText(self, valueText, 0, textY, self.scale, 1, 1, 1, 1)
        end
        
        item:addChild(valuePanel)
        
        local decreaseButton = self:createCustomButton(startX, startY, self, function()
            if currentValue > minValue then
                currentValue = currentValue - 1
                valuePanel.currentValue = currentValue
                setValue(currentValue)
                
                local newText = tostring(currentValue)
                local newWidth = ShortcutUIHelper.measureTextWidth(newText, scale)
                valuePanel:setWidth(newWidth)
            end
        end, self.decreaseTexture)
        item:addChild(decreaseButton)
        
        local increaseX = textX + textWidth + buttonSpacing
        local increaseButton = self:createCustomButton(increaseX, startY, self, function()
            if currentValue < maxValue then
                currentValue = currentValue + 1
                valuePanel.currentValue = currentValue
                setValue(currentValue)
                
                local newText = tostring(currentValue)
                local newWidth = ShortcutUIHelper.measureTextWidth(newText, scale)
                valuePanel:setWidth(newWidth)
            end
        end, self.increaseTexture)
        item:addChild(increaseButton)
    end)
end

function ShortcutSettingsPanel:addButtonGroupSetting(id, title, getValue, setValue, options)
    return self:addSettingItem(id, title, function(item, startY)
        local currentValue = getValue()
        local buttons = {}
        
        local buttonSpacing = 10
        local totalWidth = (#options * self.buttonSize) + ((#options - 1) * buttonSpacing)
        local startX = (item:getWidth() - totalWidth) / 2
        
        item.buttons = {}
        
        for i, option in ipairs(options) do
            local x = startX + (i-1) * (self.buttonSize + buttonSpacing)
            
            local button = self:createCustomButton(x, startY, self, function()
                setValue(option.value)
                
                for _, btn in ipairs(item.buttons) do
                    btn.selected = (btn.optionValue == option.value)
                end
            end, option.icon)
            
            button.optionValue = option.value
            button.selected = (currentValue == option.value)
            
            item:addChild(button)
            table.insert(buttons, button)
            table.insert(item.buttons, button)
        end
    end)
end

-- 添加按键捕获函数
function ShortcutSettingsPanel:startHotkeyCapture(buttonUI)
    -- 修改面板状态
    self.waitingForKey = true
    
    -- 激活按键捕获模式
    self.capturingHotkey = true
    
    -- 存储旧的 onKeyPressed 回调
    Events.OnKeyPressed.Remove(Shortcut.onKeyPressed)
    
    -- 添加我们自己的回调
    Events.OnKeyPressed.Add(self.onCaptureKeyPressed)
end

-- 按键捕获回调
ShortcutSettingsPanel.onCaptureKeyPressed = function(keyCode)
    local self = Shortcut.settingsPanel
    if not self or not self.capturingHotkey then return end
    
    -- 取消捕获模式
    self.capturingHotkey = false
    self.waitingForKey = false
    
    -- 恢复原来的按键回调
    Events.OnKeyPressed.Remove(self.onCaptureKeyPressed)
    Events.OnKeyPressed.Add(Shortcut.onKeyPressed)
    
    -- 更新快捷键设置
    Shortcut.setHotkey(keyCode)
    
    -- 更新按钮显示
    local keyName = Keyboard.getKeyName(keyCode) or "[" .. tostring(keyCode) .. "]"
    self.currentHotkey = keyCode
    self.currentHotkeyName = keyName
end
-- ------------------------------------------------------ --
-- 重置面板设置
-- ------------------------------------------------------ --
function ShortcutSettingsPanel:resetAllSettings()
    -- 获取默认配置
    local defaultConfig = ShortcutConfig.getDefaultConfig()
    
    -- 保留当前窗口位置设置
    local currentConfig = ShortcutConfig.getConfig()
    if currentConfig and currentConfig.settings then
        defaultConfig.settings.panelX = currentConfig.settings.panelX
        defaultConfig.settings.panelY = currentConfig.settings.panelY
    end
    
    -- 保存默认配置
    ShortcutConfig.saveConfig(defaultConfig)
    
    -- 保存并刷新面板（这会关闭原有面板）
    Shortcut.refreshPanel()
    
    -- 记住当前设置面板的位置
    local currentX = self:getX()
    local currentY = self:getY()
    
    -- 关闭当前设置面板
    self:removeFromUIManager()
    Shortcut.settingsPanel = nil
    
    -- 创建新的设置面板
    Shortcut.settingsPanel = ShortcutSettingsPanel:new()
    Shortcut.settingsPanel:initialise()
    
    -- 设置到原来的位置
    Shortcut.settingsPanel:setX(currentX)
    Shortcut.settingsPanel:setY(currentY)
    
    -- 添加到UI管理器并置于顶层
    Shortcut.settingsPanel:addToUIManager()
    Shortcut.settingsPanel:bringToTop()
end
-- ------------------------------------------------------ --
-- UI组件创建
-- ------------------------------------------------------ --
function ShortcutSettingsPanel:createChildren()
    self.settingItems = {}
    
    local closeButtonY = (self.titleBarHeight - self.buttonSize) / 2
    
    if self.closeXButton then
        self.closeXButton:setX(self.width - self.buttonSize - 4)
        self.closeXButton:setY(closeButtonY)
    else
        self.closeXButton = self:createCustomButton(self.width - self.buttonSize - 4, closeButtonY, self, self.onCloseButtonClick, self.closeTexture)
        self:addChild(self.closeXButton)
    end
    
    -- 锁定按钮
    local lockButtonX = self.width - self.buttonSize * 2 - 8  -- 关闭按钮左边
    if self.lockButton then
        self.lockButton:setX(lockButtonX)
        self.lockButton:setY(closeButtonY)
        self.lockButton.selected = Shortcut.isPanelLocked()
    else
        self.lockButton = self:createCustomButton(lockButtonX, closeButtonY, self, self.onLockButtonClick, self.lockTexture)
        self.lockButton.selected = Shortcut.isPanelLocked()  -- 根据当前锁定状态设置选中状态
        self:addChild(self.lockButton)
    end
    
    local titleText = "The Shortcut"
    local titlePadding = 10
    local titleLabel = ISLabel:new(titlePadding, 0, 20, titleText, 1, 1, 1, 1, UIFont.Small, true)
    titleLabel:initialise()
    titleLabel:instantiate()
    
    local titleHeight = getTextManager():getFontHeight(UIFont.Small)
    titleLabel:setY((self.titleBarHeight- titleHeight) / 2)
    
    self:addChild(titleLabel)
    
    self:addNumberSetting(
        "rowCount", 
        getText("IGUI_Shortcut_RowCount"), 
        function() return self.rowCount end,
        function(value) 
            self.rowCount = value
            self:saveSettings()
        end,
        1, 16
    )
    
    self:addNumberSetting(
        "columnCount", 
        getText("IGUI_Shortcut_ColumnCount"), 
        function() return self.columnCount end,
        function(value) 
            self.columnCount = value
            self:saveSettings()
        end,
        1, 16
    )
    
    self:addButtonGroupSetting(
        "slotSize", 
        getText("IGUI_Shortcut_SlotSize"), 
        function() return self.slotSizeType end,
        function(value) 
            self.slotSizeType = value
            self:saveSettings()
        end,
        {
            {value = "small", icon = self.smallTexture},
            {value = "medium", icon = self.mediumTexture},
            {value = "medium-large", icon = self.mediumlargeTexture}, 
            {value = "large", icon = self.largeTexture}
        }
    )
    
    self:addButtonGroupSetting(
        "controlWidgetPosition", 
        getText("IGUI_Shortcut_ControlWidgetPosition"), 
        function() return self.controlWidgetPosition end,
        function(value) 
            self.controlWidgetPosition = value
            self:saveSettings()
        end,
        {
            {value = "top", icon = self.topTexture},
            {value = "bottom", icon = self.bottomTexture},
            {value = "left", icon = self.leftTexture},
            {value = "right", icon = self.rightTexture}
        }
    )

    self:addNumberSetting(
    "backgroundAlpha", 
    getText("IGUI_Shortcut_BackgroundAlpha"), 
    function() return math.floor(self.backgroundAlpha * 10) end,
    function(value) 
        self.backgroundAlpha = value / 10
        self:saveSettings()
    end,
    0, 10
    )

    self:addNumberSetting(
        "slotAlpha", 
        getText("IGUI_Shortcut_SlotAlpha"), 
        function() return math.floor(self.slotAlpha * 10) end,
        function(value) 
            self.slotAlpha = value / 10
            self:saveSettings()
        end,
        0, 10
    )

    self:addSettingItem(
        "hotkey",
        getText("IGUI_Shortcut_Hotkey"),
        function(item, startY)
            local hotkeyValue = Shortcut.getHotkey()
            local hotkeyName = Keyboard.getKeyName(hotkeyValue) or "[" .. tostring(hotkeyValue) .. "]"
            
            local buttonWidth = self.buttonSize * 4
            local buttonHeight = self.buttonSize * 1.2
            local buttonX = (item:getWidth() - buttonWidth) / 2
            local buttonY = startY + 5
            
            local hotkeyButton = ISButton:new(
                buttonX, buttonY, 
                buttonWidth, buttonHeight, 
                "", 
                self, 
                function() self:startHotkeyCapture(hotkeyButton) end
            )
            hotkeyButton:initialise()
            
            -- 在面板上存储状态
            self.currentHotkey = hotkeyValue
            self.currentHotkeyName = hotkeyName
            self.waitingForKey = false
            self.hotkeyButtonRef = hotkeyButton
            
            -- 设置按钮不显示原始背景
            hotkeyButton.displayBackground = false
            
            -- 自定义渲染函数
            hotkeyButton.render = function(button)
                -- 1. 绘制背景
                local bgA, bgR, bgG, bgB = 0.2, 0.2, 0.2, 0.2
                if self.waitingForKey then
                    bgA, bgR, bgG, bgB = 0.4, 0.95, 0.6, 0.2
                end
                
                ShortcutUIHelper.drawThreeSlice(
                    button, 0, 0, button.width, button.height,
                    self.hotkeyButtonBgTextures.left, 
                    self.hotkeyButtonBgTextures.middle, 
                    self.hotkeyButtonBgTextures.right,
                    bgA, bgR, bgG, bgB
                )
                
                -- 2. 绘制边框
                ShortcutUIHelper.drawThreeSlice(
                    button, 0, 0, button.width, button.height,
                    self.hotkeyButtonBorderTextures.left, 
                    self.hotkeyButtonBorderTextures.middle, 
                    self.hotkeyButtonBorderTextures.right,
                    0.8, 0.5, 0.5, 0.5
                )
                
                -- 3. 悬停贴图
                if button.mouseOver then
                    ShortcutUIHelper.drawThreeSlice(
                        button, 0, 0, button.width, button.height,
                        self.hotkeyButtonHoverTextures.left, 
                        self.hotkeyButtonHoverTextures.middle, 
                        self.hotkeyButtonHoverTextures.right,
                        0.6, 0.6, 0.6, 0.6
                    )
                end
                
                -- 4. 当前快捷键名称
                local textWidth = getTextManager():MeasureStringX(UIFont.Small, self.currentHotkeyName)
                local textX = (button.width - textWidth) / 2
                local textY = (button.height - getTextManager():getFontHeight(UIFont.Small)) / 2
                
                button:drawText(self.currentHotkeyName, textX, textY, 1, 1, 1, 1, UIFont.Small)
            end
            
            item:addChild(hotkeyButton)
        end
    )

    self:addSettingItem(
        "resetSettings",
        getText("IGUI_Shortcut_ResetSettings"),
        function(item, startY)
            local resetButton = self:createCustomButton(
                (item:getWidth() - self.buttonSize ) / 2,
                startY,
                self,
                function() 
                    self:resetAllSettings()
                end,
                self.resetTexture,
                self.buttonSize
            )
            item:addChild(resetButton)
        end
    )
    
    self:layoutSettingItems()
end

-- ------------------------------------------------------ --
-- 鼠标事件
-- ------------------------------------------------------ --
function ShortcutSettingsPanel:onMouseDown(x, y)
    if y <= self.titleBarHeight then
        if self.closeXButton and self.closeXButton:isMouseOver() then
            return
        end
        
        self.moving = true
        self.dragX = x
        self.dragY = y
        self:bringToTop()
    else
        self.moving = false
    end
end

-- ------------------------------------------------------ --
-- 设置保存与面板渲染
-- ------------------------------------------------------ --
function ShortcutSettingsPanel:saveSettings()
    Shortcut.setRowCount(self.rowCount)
    Shortcut.setColumnCount(self.columnCount)
    Shortcut.setSlotSizeType(self.slotSizeType)
    Shortcut.setTitleBarPosition(self.controlWidgetPosition)
    Shortcut.setBackgroundAlpha(self.backgroundAlpha)
    Shortcut.setSlotAlpha(self.slotAlpha) 
    
    Shortcut.refreshPanel()
end

function ShortcutSettingsPanel:onCloseButtonClick()
    self:removeFromUIManager()
    Shortcut.settingsPanel = nil
end

function ShortcutSettingsPanel:prerender()
    ISPanel.prerender(self)
    
    ShortcutUIHelper.drawThreeSlice(
        self, 0, 0, self.width, self.titleBarHeight,
        self.titleBarThreeSliceTextures.left,
        self.titleBarThreeSliceTextures.middle,
        self.titleBarThreeSliceTextures.right,
        1, 1, 1, 1
    )
    
    local contentX = 0
    local contentY = self.titleBarHeight
    local contentWidth = self.width
    local contentHeight = self.height - self.titleBarHeight
        
    ShortcutUIHelper.drawNineSlice(
        self, contentX, contentY, contentWidth, contentHeight,
        self.panelContentNineSliceTextures, 0.9, 1, 1, 1
    )
end

return ShortcutSettingsPanel