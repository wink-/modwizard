require "ISUI/ISPanel"

-- ------------------------------------------------------ --
-- 类定义
-- ------------------------------------------------------ --
ShortcutControlWidget = ISPanel:derive("ShortcutControlWidget")

-- ------------------------------------------------------ --
-- 创建和初始化
-- ------------------------------------------------------ --
function ShortcutControlWidget:new(panel)
    local slotSize = Shortcut.getActualSlotSize()
    local o = ISPanel:new(0, 0, 100, 100)
    setmetatable(o, self)
    self.__index = self
    
    o.backgroundColor = {r=0.2, g=0.2, b=0.2, a=0}
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=0}
    o.panel = panel
    o.buttonSize = math.floor(slotSize * 0.6) 
    o.visible = false
    o.position = Shortcut.getTitleBarPosition()
    
    -- 添加简单的渐变属性
    o.fadeAlpha = 0
    o.fadeSpeed = 0.8
    
    -- 水平背景贴图
    o.horizontalBackgroundTextures = {
        left = getTexture("media/ui/TheShortCut/MainPanel/TheShortCut_ControlWidget_L.png"),
        middle = getTexture("media/ui/TheShortCut/MainPanel/TheShortCut_ControlWidget_M.png"),
        right = getTexture("media/ui/TheShortCut/MainPanel/TheShortCut_ControlWidget_R.png")
    }
    
    -- 垂直背景贴图
    o.verticalBackgroundTextures = {
        top = getTexture("media/ui/TheShortCut/MainPanel/TheShortCut_ControlWidget_T.png"),
        middle = getTexture("media/ui/TheShortCut/MainPanel/TheShortCut_ControlWidget_VM.png"),
        bottom = getTexture("media/ui/TheShortCut/MainPanel/TheShortCut_ControlWidget_B.png")
    }
    
    -- 按钮贴图
    o.buttonTextures = {
        -- 圆形按钮贴图（用于页面类型按钮）
        background = getTexture("media/ui/TheShortCut/MainPanel/TheShortCut_Control_CircleBackground.png"),
        border = getTexture("media/ui/TheShortCut/MainPanel/TheShortCut_Control_CircleBoarder.png"),
        hover = getTexture("media/ui/TheShortCut/MainPanel/TheShortCut_Control_CircleHover.png"),
        
        -- 方形按钮贴图（用于设置按钮）
        squareBackground = getTexture("media/ui/TheShortCut/MainPanel/TheShortCut_Control_SquareBackground.png"),
        squareBorder = getTexture("media/ui/TheShortCut/MainPanel/TheShortCut_Control_SquareBoarder.png"),
        squareHover = getTexture("media/ui/TheShortCut/MainPanel/TheShortCut_Control_SquareHover.png"),
        
        -- 图标贴图
        settingsIcon = getTexture("media/ui/TheShortCut/Icon/Icon_Setting.png"),
        itemsIcon = getTexture("media/ui/TheShortCut/Icon/Icon_Items.png"),
        recipesIcon = getTexture("media/ui/TheShortCut/Icon/Icon_Recipe.png"),
        buildingsIcon = getTexture("media/ui/TheShortCut/Icon/Icon_Build.png")
    }
    
    o:updateDimensions()
    
    return o
end

function ShortcutControlWidget:initialise()
    ISPanel.initialise(self)
    self:createButtons()
    self:updatePosition()
    self:addToUIManager()
    self:setVisible(false)
end

-- 更新控件尺寸
function ShortcutControlWidget:updateDimensions()
    local slotSize = Shortcut.getActualSlotSize()
    local slotMarginX = math.floor(slotSize / 4)
    local slotMarginY = math.floor(slotSize / 3)
    
    -- 根据位置决定控件是水平还是垂直布局
    if self.position == "top" or self.position == "bottom" then
        -- 水平布局
        local height = math.floor(slotSize * 0.8)
        local width = slotSize + (2 * slotMarginX)
        self:setWidth(width)
        self:setHeight(height)
    else 
        -- 垂直布局
        local width = math.floor(slotSize * 0.8)
        local height = slotSize + (2 * slotMarginY)
        self:setWidth(width)
        self:setHeight(height)
    end
end

function ShortcutControlWidget:createButtons()
    -- 清除之前的按钮
    if self.settingsButton then
        self:removeChild(self.settingsButton)
        self:removeChild(self.pageTypeButton)
    end
    
    -- 按钮数量
    local buttonCount = 2
    local buttonSize = self.buttonSize
    
    -- 根据位置决定按钮布局
    if self.position == "top" or self.position == "bottom" then
        local sectionWidth = self.width / buttonCount
        
        local firstButtonX = (sectionWidth - buttonSize) / 2
        local buttonY = (self.height - buttonSize) / 2
        
        -- 页面类型按钮（现在放在第一个位置）
        local pageType = Shortcut.getPageType()
        self.pageTypeButton = self:createButton(firstButtonX, buttonY, buttonSize, pageType, self.onPageTypeButtonClick)
        
        -- 设置按钮（现在放在第二个位置）
        local secondButtonX = sectionWidth + (sectionWidth - buttonSize) / 2
        self.settingsButton = self:createButton(secondButtonX, buttonY, buttonSize, "settings", self.onSettingsButtonClick)
    else
        local sectionHeight = self.height / buttonCount
        
        local buttonX = (self.width - buttonSize) / 2
        local firstButtonY = (sectionHeight - buttonSize) / 2
        
        -- 页面类型按钮（现在放在第一个位置）
        local pageType = Shortcut.getPageType()
        self.pageTypeButton = self:createButton(buttonX, firstButtonY, buttonSize, pageType, self.onPageTypeButtonClick)
        
        -- 设置按钮（现在放在第二个位置）
        local secondButtonY = sectionHeight + (sectionHeight - buttonSize) / 2
        self.settingsButton = self:createButton(buttonX, secondButtonY, buttonSize, "settings", self.onSettingsButtonClick)
    end
end

function ShortcutControlWidget:createButton(x, y, size, buttonType, clickHandler)
    local button = ISButton:new(x, y, size, size, "", self, clickHandler)
    button:initialise()
    button.backgroundColor.a = 0
    button.backgroundColorMouseOver.a = 0
    button.borderColor.a = 0
    
    button.buttonType = buttonType
    
    if buttonType == "settings" then
        -- 设置按钮使用方形贴图
        button.bgTexture = self.buttonTextures.squareBackground
        button.borderTexture = self.buttonTextures.squareBorder
        button.hoverTexture = self.buttonTextures.squareHover
        button.iconTexture = self.buttonTextures.settingsIcon
    else
        -- 使用圆形贴图
        button.bgTexture = self.buttonTextures.background
        button.borderTexture = self.buttonTextures.border
        button.hoverTexture = self.buttonTextures.hover
        
        if buttonType == "items" then
            button.iconTexture = self.buttonTextures.itemsIcon
        elseif buttonType == "recipes" then
            button.iconTexture = self.buttonTextures.recipesIcon
        elseif buttonType == "buildings" then
            button.iconTexture = self.buttonTextures.buildingsIcon
        end
    end
    
    -- 修改按钮渲染函数，使用面板透明度
    button.render = function(btn)
        -- 绘制背景
        btn:drawTextureScaled(btn.bgTexture, 0, 0, btn.width, btn.height, self.fadeAlpha * 0.4, 0.4, 0.4, 0.4)
        
        -- 绘制边框
        btn:drawTextureScaled(btn.borderTexture, 0, 0, btn.width, btn.height, self.fadeAlpha * 0.6, 0.6, 0.6, 0.6)
        
        -- 绘制悬停状态
        if btn.mouseOver then
            btn:drawTextureScaled(btn.hoverTexture, 0, 0, btn.width, btn.height, self.fadeAlpha * 0.6, 0.8, 0.8, 0.8)
        end

        btn:drawTextureScaled(btn.iconTexture, 0, 0, btn.width, btn.width, self.fadeAlpha, 1, 1, 1)
    end
    
    self:addChild(button)
    return button
end

-- ------------------------------------------------------ --
-- 按钮事件处理
-- ------------------------------------------------------ --
function ShortcutControlWidget:onSettingsButtonClick()
    Shortcut.openSettings()
end

function ShortcutControlWidget:onPageTypeButtonClick()
    if Shortcut.panel then
        Shortcut.panel:togglePageType()
        
        local newPageType = Shortcut.getPageType()
        if self.pageTypeButton then
            self.pageTypeButton.buttonType = newPageType
            
            -- 根据新页面类型设置图标
            if newPageType == "items" then
                self.pageTypeButton.iconTexture = self.buttonTextures.itemsIcon
            elseif newPageType == "recipes" then
                self.pageTypeButton.iconTexture = self.buttonTextures.recipesIcon
            elseif newPageType == "buildings" then
                self.pageTypeButton.iconTexture = self.buttonTextures.buildingsIcon
            end
        end
    end
end

-- ------------------------------------------------------ --
-- 渲染方法
-- ------------------------------------------------------ --
function ShortcutControlWidget:prerender()
    if self.position == "top" or self.position == "bottom" then
        ShortcutUIHelper.drawThreeSlice(
            self, 0, 0, self.width, self.height,
            self.horizontalBackgroundTextures.left,
            self.horizontalBackgroundTextures.middle,
            self.horizontalBackgroundTextures.right,
            self.fadeAlpha, 0.3, 0.3, 0.3
        )
    else
        ShortcutUIHelper.drawVerticalThreeSlice(
            self, 0, 0, self.width, self.height,
            self.verticalBackgroundTextures.top,
            self.verticalBackgroundTextures.middle,
            self.verticalBackgroundTextures.bottom,
            self.fadeAlpha, 0.3, 0.3, 0.3
        )
    end
end

-- ------------------------------------------------------ --
-- 显示控制和位置更新
-- ------------------------------------------------------ --
function ShortcutControlWidget:updatePosition()
    if not Shortcut.panel then return end
    
    self:updateDimensions()

    local slotSize = Shortcut.getActualSlotSize()
    local distance = math.floor(slotSize / 16)

    self.position = Shortcut.getTitleBarPosition() or "top"

    if self.position == "top" then
        -- 上方
        self:setX(Shortcut.panel.x)
        self:setY(Shortcut.panel.y - self.height - distance)
    elseif self.position == "bottom" then
        -- 下方
        self:setX(Shortcut.panel.x)
        self:setY(Shortcut.panel.y + Shortcut.panel.height + distance)
    elseif self.position == "left" then
        -- 左侧
        self:setX(Shortcut.panel.x - self.width - distance)
        self:setY(Shortcut.panel.y)
    elseif self.position == "right" then
        -- 右侧
        self:setX(Shortcut.panel.x + Shortcut.panel.width + distance)
        self:setY(Shortcut.panel.y)
    end

    self:createButtons()
    
    self.panel = Shortcut.panel
end

function ShortcutControlWidget:show()
    if not self.visible then
        self:setVisible(true)
        self.fadeAlpha = 0.01 
    end
    self.visible = true
end

function ShortcutControlWidget:hide()

    self.visible = false
end

function ShortcutControlWidget:update()
    local currentPosition = Shortcut.getTitleBarPosition() or "top"
    if self.position ~= currentPosition then
        self.position = currentPosition
        self:updatePosition()
    end
    
    if self.panel then
        self:updateVisibility()
    else
        self:hide()
    end
    
    -- 处理透明度变化逻辑
    if self.visible then
        -- 增加透明度
        self.fadeAlpha = math.min(1.0, self.fadeAlpha + self.fadeSpeed)
    else
        -- 减少透明度
        self.fadeAlpha = math.max(0, self.fadeAlpha - self.fadeSpeed)
        
        -- 当透明度为0时，完全隐藏控件以减少渲染开销
        if self.fadeAlpha <= 0 and self:isVisible() then
            self:setVisible(false)
        end
    end
end

-- ------------------------------------------------------ --
-- 事件处理
-- ------------------------------------------------------ --
function ShortcutControlWidget:updateVisibility()
    if not self.panel then
        self:hide()
        return
    end
    
    local mouseX = getMouseX()
    local mouseY = getMouseY()
    
    -- 检查鼠标是否在面板上
    local isOverPanel = mouseX >= self.panel:getAbsoluteX() and mouseX < self.panel:getAbsoluteX() + self.panel.width and
                         mouseY >= self.panel:getAbsoluteY() and mouseY < self.panel:getAbsoluteY() + self.panel.height

    local isOverControl = mouseX >= self:getAbsoluteX() and mouseX < self:getAbsoluteX() + self.width and
                           mouseY >= self:getAbsoluteY() and mouseY < self:getAbsoluteY() + self.height
    
    -- 设置可见性标志
    if isOverPanel or isOverControl then
        self:show()
    else
        self:hide()
    end
end

return ShortcutControlWidget