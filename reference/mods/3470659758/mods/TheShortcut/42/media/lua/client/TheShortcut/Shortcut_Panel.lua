require "ISUI/ISPanel"

-- ------------------------------------------------------ --
-- 类定义
-- ------------------------------------------------------ --
ShortcutPanel = ISPanel:derive("ShortcutPanel")

ShortcutPanel.sharedCraftLogic = nil
ShortcutPanel.lastCraftLogicUpdateTime = 0
ShortcutPanel.craftLogicUpdateInterval = 1000

ShortcutPanel.sharedBuildLogic = nil
ShortcutPanel.lastBuildLogicUpdateTime = 0
ShortcutPanel.buildLogicUpdateInterval = 1000

-- ------------------------------------------------------ --
-- 静态方法 - 面板控制
-- ------------------------------------------------------ --
ShortcutPanel.create = function()
    if Shortcut.panel then return end
    
    Shortcut.panel = ShortcutPanel:new()
    Shortcut.panel:initialise()
    Shortcut.panel:addToUIManager()
    
    if Shortcut.panel.pageType == "items" then
        Shortcut.panel:updateAllSlotsData()
    end
    Shortcut.panel:adjustPositionToScreen()
    
    -- 控制组件已在initialise中创建，这里不需要额外操作
end

-- ------------------------------------------------------ --
-- 防止面板超出屏幕
-- ------------------------------------------------------ --
function ShortcutPanel:adjustPositionToScreen()
    local screenWidth = getCore():getScreenWidth()
    local screenHeight = getCore():getScreenHeight()
    
    -- 确保面板不会超出右侧或底部
    if self.x + self.width > screenWidth then
        self.x = screenWidth - self.width
    end
    if self.y + self.height > screenHeight then
        self.y = screenHeight - self.height
    end
    
    -- 确保面板不会完全超出左侧或顶部
    if self.x + self.width < 50 then
        self.x = 50 - self.width
    end
    if self.y + self.height < 50 then
        self.y = 50 - self.height
    end
end

-- ------------------------------------------------------ --
-- 实例初始化方法
-- ------------------------------------------------------ --
function ShortcutPanel:new(x, y, width, height)
    local rowCount = Shortcut.getRowCount()
    local columnCount = Shortcut.getColumnCount()
    
    local slotSize = Shortcut.getActualSlotSize()
    local slotMarginX = math.floor(slotSize / 4)
    local slotMarginY = math.floor(slotSize / 3)
    
    -- 计算面板尺寸，无需考虑标题栏和按钮
    local calculatedWidth = slotMarginX + (columnCount * (slotSize + slotMarginX))
    local calculatedHeight = slotMarginY + (rowCount * (slotSize + slotMarginY))
    
    local panelWidth = width or calculatedWidth
    local panelHeight = height or calculatedHeight
    
    local savedX, savedY = Shortcut.getPanelPosition()
    local screenWidth = getCore():getScreenWidth()
    local screenHeight = getCore():getScreenHeight()
    
    local panelX = x or savedX or (screenWidth - panelWidth) / 2
    local panelY = y or savedY or (screenHeight - panelHeight - 100)
    
    if panelX + panelWidth > screenWidth then
        panelX = screenWidth - panelWidth
    end
    if panelY + panelHeight > screenHeight then
        panelY = screenHeight - panelHeight
    end
    
    if panelX + panelWidth < 50 then
        panelX = 50 - panelWidth
    end
    if panelY + panelHeight < 50 then
        panelY = 50 - panelHeight
    end
    
    local o = ISPanel:new(panelX, panelY, panelWidth, panelHeight)
    setmetatable(o, self)
    self.__index = self
    
    o.width = panelWidth
    o.height = panelHeight
    o.moveWithMouse = true
    o.moving = false
    o.slots = {}
    o.controlWidget = nil -- 添加控件引用
    
    o.slotSize = slotSize
    o.slotMarginX = slotMarginX
    o.slotMarginY = slotMarginY
    o.rowCount = rowCount
    o.columnCount = columnCount
    o.draggingSlot = nil
    o.pageType = Shortcut.getPageType()
    o.recipeSlots = {}
    o.buildSlots = {}

    -- 使用单一的面板背景纹理
    o.panelBackgroundTextures = {
        topLeft = getTexture("media/ui/TheShortCut/MainPanel/TheShortCut_MainP_BG_LT.png"),
        top = getTexture("media/ui/TheShortCut/MainPanel/TheShortCut_MainP_BG_T.png"),
        topRight = getTexture("media/ui/TheShortCut/MainPanel/TheShortCut_MainP_BG_RT.png"),
        left = getTexture("media/ui/TheShortCut/MainPanel/TheShortCut_MainP_BG_L.png"),
        middle = getTexture("media/ui/TheShortCut/MainPanel/TheShortCut_MainP_BG_M.png"),
        right = getTexture("media/ui/TheShortCut/MainPanel/TheShortCut_MainP_BG_R.png"),
        bottomLeft = getTexture("media/ui/TheShortCut/MainPanel/TheShortCut_MainP_BG_LB.png"),
        bottom = getTexture("media/ui/TheShortCut/MainPanel/TheShortCut_MainP_BG_B.png"),
        bottomRight = getTexture("media/ui/TheShortCut/MainPanel/TheShortCut_MainP_BG_RB.png")
    }
    
    return o
end


function ShortcutPanel:initialise()
    ISPanel.initialise(self)
    self:createSlots()
    
    -- 创建控制组件
    self:createControlWidget()
    
    self:adjustPositionToScreen()
end

-- 添加新方法管理控制组件
function ShortcutPanel:createControlWidget()
    if not self.controlWidget then
        self.controlWidget = ShortcutControlWidget:new(self)
        self.controlWidget:initialise()
        self.controlWidget:updatePosition()
        self.controlWidget:updateVisibility()
    end
end

-- ------------------------------------------------------ --
-- UI组件创建
-- ------------------------------------------------------ --
function ShortcutPanel:createSlots()
    -- 设置槽位起始位置，直接从面板边缘开始
    local startX = self.slotMarginX
    local startY = self.slotMarginY
    
    self.slots = {}
    self.recipeSlots = {}
    self.buildSlots = {}
    
    if self.pageType == "items" then
        local slotIndex = 1
        for row = 1, self.rowCount do
            for col = 1, self.columnCount do
                local slotX = startX + (col-1) * (self.slotSize + self.slotMarginX)
                local slotY = startY + (row-1) * (self.slotSize + self.slotMarginY)
                
                local slot = ShortcutItemSlot:new(slotX, slotY, self.slotSize, self.slotSize, slotIndex)
                slot:initialise()
                self:addChild(slot)
                table.insert(self.slots, slot)
                slotIndex = slotIndex + 1
            end
        end
    elseif self.pageType == "recipes" then
        local slotIndex = 1
        for row = 1, self.rowCount do
            for col = 1, self.columnCount do
                local slotX = startX + (col-1) * (self.slotSize + self.slotMarginX)
                local slotY = startY + (row-1) * (self.slotSize + self.slotMarginY)
                
                local slot = ShortcutRecipeSlot:new(slotX, slotY, self.slotSize, self.slotSize, slotIndex)
                slot:initialise()
                self:addChild(slot)
                table.insert(self.recipeSlots, slot)
                slotIndex = slotIndex + 1
            end
        end
    else
        local slotIndex = 1
        for row = 1, self.rowCount do
            for col = 1, self.columnCount do
                local slotX = startX + (col-1) * (self.slotSize + self.slotMarginX)
                local slotY = startY + (row-1) * (self.slotSize + self.slotMarginY)
                
                local slot = ShortcutBuildSlot:new(slotX, slotY, self.slotSize, self.slotSize, slotIndex)
                slot:initialise()
                self:addChild(slot)
                table.insert(self.buildSlots, slot)
                slotIndex = slotIndex + 1
            end
        end
    end
end

function ShortcutPanel:createCustomButton(x, y, width, height, target, onclick, iconTexture)
    local button = ISButton:new(x, y, width, height, "", target, onclick)
    button:initialise()
    button.backgroundColor = {r=0.2, g=0.2, b=0.2, a=0}
    button.backgroundColorMouseOver = {r=0.3, g=0.3, b=0.3, a=0}
    button.borderColor = {r=0, g=0, b=0, a=0}
    
    button.bgTexture = self.buttonBgTexture
    button.hoverTexture = self.buttonHoverTexture
    button.iconTexture = iconTexture
    
    button.render = function(self)
        self:drawTextureScaled(self.bgTexture, 0, 0, self.width, self.height, 0.6, 0.6, 0.6, 0.6)
        
        if self.mouseOver then
            self:drawTextureScaled(self.hoverTexture, 0, 0, self.width, self.height, 0.4, 1, 1, 1)
        end
        
        if self.iconTexture then
            local iconSize = math.min(self.width, self.height) * 1
            local iconX = (self.width - iconSize) / 2
            local iconY = (self.height - iconSize) / 2
            self:drawTextureScaled(self.iconTexture, iconX, iconY, iconSize, iconSize, 1, 1, 1, 1)
        end
    end
    
    return button
end

-- ------------------------------------------------------ --
-- 绘制方法
-- ------------------------------------------------------ --
function ShortcutPanel:prerender()
    -- 获取当前背景透明度设置
    local backgroundAlpha = Shortcut.getBackgroundAlpha()
    
    ShortcutUIHelper.drawNineSlice(
        self, 0, 0, self.width, self.height,
        self.panelBackgroundTextures, backgroundAlpha, 0.2, 0.2, 0.2
    )
end

-- ------------------------------------------------------ --
-- 主单元更新
-- ------------------------------------------------------ --
function ShortcutPanel:update()
    ISPanel.update(self)
    
    if self.draggingSlot and not isMouseButtonDown(0) then
        if self.draggingSlot.dragRenderer then
            self.draggingSlot.dragRenderer:stopDragging()
            self.draggingSlot.dragRenderer = nil
        end
        
        Shortcut.draggedRecipe = nil
        Shortcut.draggedBuilding = nil
        
        self.draggingSlot = nil
    end
    
    if self.pageType == "items" then
        local inventoryChanged = ShortcutItem.hasInventoryChanged()
        local stateChanged = ShortcutItemState.checkAllItemsState(self.slots)
        if stateChanged then
            ShortcutItem.itemsCache = nil
        end
        if inventoryChanged or stateChanged then
            self:updateAllSlotsData()
        end
    elseif self.pageType == "recipes" then
        self:updateAllRecipeSlotsData()
    else
        self:updateAllBuildSlotsData()
    end
end
-- ------------------------------------------------------ --
-- ItemSlot更新
-- ------------------------------------------------------ --
function ShortcutPanel:updateAllSlotsData()
    for _, slot in ipairs(self.slots) do
        if slot.itemType then
            local data = ShortcutItem.getSelfItemData(slot.itemType)
            
            if data and data.item and data.count > 0 then
                slot.item = data.item
                slot.itemCount = data.count
            else
                if not slot.item then
                    slot.item = ShortcutItem.createVirtualItem(slot.itemType)
                    if slot.item then
                        slot.cachedTexture = slot.item:getTex()
                    end
                end
                slot.itemCount = 0
            end
        end
    end
end

function ShortcutPanel:updateSlot(slotIndex)
    for _, slot in ipairs(self.slots) do
        if slot.slotIndex == slotIndex then
            local itemData = ShortcutConfig.getSlotData(slotIndex)
            
            if itemData and itemData.type then
                -- 如果物品类型变了，清除旧的物品和纹理缓存
                if slot.itemType ~= itemData.type then
                    slot.item = nil
                    slot.cachedTexture = nil
                end
                
                slot.itemType = itemData.type
                
                local data = ShortcutItem.getSelfItemData(slot.itemType)
                
                if data and data.item and data.count > 0 then
                    -- 有真实物品，使用真实物品
                    slot.item = data.item
                    slot.itemCount = data.count
                else
                    -- 无真实物品，创建虚拟物品
                    if not slot.item then
                        slot.item = ShortcutItem.createVirtualItem(slot.itemType)
                        if slot.item then
                            slot.cachedTexture = slot.item:getTex()
                        end
                    end
                    slot.itemCount = 0
                end
            else
                slot.item = nil
                slot.itemType = nil
                slot.itemCount = 0
                slot.cachedTexture = nil
            end
            
            return
        end
    end
end
-- ------------------------------------------------------ --
-- RecipeSlot更新
-- ------------------------------------------------------ --
function ShortcutPanel:getSharedCraftLogic()
    local currentTime = getTimestampMs()
    local player = getSpecificPlayer(0)
    
    if not player or player:isDead() then return nil end
    
    -- 检查是否需要更新
    local needsUpdate = false
    
    if not self.sharedCraftLogic then
        needsUpdate = true
    elseif (currentTime - self.lastCraftLogicUpdateTime) > self.craftLogicUpdateInterval then
        needsUpdate = true
    end
    
    if needsUpdate then
        -- 传递工作平面检测 -- 用于获取工作平面
        local workbench = ISEntityUI.FindCraftSurface(player, 3)
        -- 创建新HandcraftLogic
        local craftLogic = HandcraftLogic.new(player, nil, workbench)
        
        -- 获取所有容器
        local containers = ISInventoryPaneContextMenu.getContainers(player)
        craftLogic:setContainers(containers)
        
        -- 更新共享实例和时间戳
        self.sharedCraftLogic = craftLogic
        self.lastCraftLogicUpdateTime = currentTime
        print("Shortcut: HandcraftLogic updated.")
    end
    
    return self.sharedCraftLogic
end

function ShortcutPanel:checkRecipeCraftable(recipe, slot)
    if not recipe then return false end
    
    local player = getSpecificPlayer(0)
    if not player then return false end

    -- 作弊模式检测
    --if player:isBuildCheat() then
    --    if slot then slot.maxCraftCount = 999 end
    --    return true
    --end

    local craftLogic = self:getSharedCraftLogic()
    if not craftLogic then return false end
    
    -- 设置当前配方
    craftLogic:setRecipe(recipe)
    craftLogic:autoPopulateInputs()
    
    local canCraft = craftLogic:canPerformCurrentRecipe()
    
    -- 获取最大可制作次数
    if canCraft and slot then
        if recipe:isAllowBatchCraft() then
            slot.maxCraftCount = craftLogic:getPossibleCraftCount(false)
        else
            slot.maxCraftCount = 1  -- 如果配方不支持批量制作，则强制设为1
        end
    elseif slot then
        slot.maxCraftCount = 0
    end
    
    return canCraft
end

function ShortcutPanel:updateRecipeSlot(slotIndex)
    for _, slot in ipairs(self.recipeSlots) do
        if slot.slotIndex == slotIndex then
            local recipeData = ShortcutConfig.getRecipeSlotData(slotIndex)
            
            if recipeData and recipeData.name then
                slot.recipeName = recipeData.name
                slot.moduleName = recipeData.module
                
                slot.recipe = ShortcutRecipeSlot.findRecipeByName(slot.recipeName, slot.moduleName)
            else
                slot.recipe = nil
                slot.recipeName = nil
                slot.moduleName = nil
            end
            
            return
        end
    end
end

function ShortcutPanel:updateAllRecipeSlotsData()
    for _, slot in ipairs(self.recipeSlots) do
        if slot.recipeName then
            if not slot.recipe or not instanceof(slot.recipe, "Recipe") then
                slot.recipe = ShortcutRecipeSlot.findRecipeByName(slot.recipeName, slot.moduleName)
            end
            
            if slot.recipe then
                slot.isCraftable = self:checkRecipeCraftable(slot.recipe, slot)
            else
                slot.isCraftable = false
                slot.maxCraftCount = 0
            end
        end
    end
end
-- ------------------------------------------------------ --
-- BuildSlot更新
-- ------------------------------------------------------ --
function ShortcutPanel:getSharedBuildLogic()
    local currentTime = getTimestampMs()
    local player = getSpecificPlayer(0)
    
    if not player or player:isDead() then return nil end
    
    -- 检查是否需要更新
    local needsUpdate = false
    
    if not self.sharedBuildLogic then
        needsUpdate = true
    elseif (currentTime - self.lastBuildLogicUpdateTime) > self.buildLogicUpdateInterval then
        needsUpdate = true
    end
    
    -- 如果需要更新，创建新的BuildLogic实例
    if needsUpdate then
        -- 创建新BuildLogic
        local buildLogic = BuildLogic.new(player, nil, nil)
        
        -- 获取所有容器
        local containers = ISInventoryPaneContextMenu.getContainers(player)
        buildLogic:setContainers(containers)
        
        -- 更新共享实例和时间戳
        self.sharedBuildLogic = buildLogic
        self.lastBuildLogicUpdateTime = currentTime
        print("Shortcut: BuildLogic updated.")
    end
    
    return self.sharedBuildLogic
end

function ShortcutPanel:checkBuildingBuildable(building)
    if not building then return false end
    
    local player = getSpecificPlayer(0)
    if not player then return false end
    
    -- 检查作弊模式
    if player:isBuildCheat() then
        return true
    end

    local buildLogic = self:getSharedBuildLogic()
    if not buildLogic then return false end

    local oldRecipe = buildLogic:getRecipe()
    buildLogic:setRecipe(building)
    local canBuild = buildLogic:canPerformCurrentRecipe()

    if oldRecipe then
        buildLogic:setRecipe(oldRecipe)
    end
    
    return canBuild
end

function ShortcutPanel:updateBuildSlot(slotIndex)
    for _, slot in ipairs(self.buildSlots) do
        if slot.slotIndex == slotIndex then
            local buildData = ShortcutConfig.getBuildSlotData(slotIndex)
            
            if buildData and buildData.name then
                slot.buildingName = buildData.name
                slot.moduleName = buildData.module
                
                slot.building = ShortcutBuildSlot.findBuildingByName(slot.buildingName, slot.moduleName)
            else
                slot.building = nil
                slot.buildingName = nil
                slot.moduleName = nil
            end
            
            return
        end
    end
end

function ShortcutPanel:updateAllBuildSlotsData()
    local buildLogic = self:getSharedBuildLogic()
    if not buildLogic then return end

    for _, slot in ipairs(self.buildSlots) do
        if slot.buildingName and not slot.building then
            slot.building = ShortcutBuildSlot.findBuildingByName(slot.buildingName, slot.moduleName)
        end
    end

    for _, slot in ipairs(self.buildSlots) do
        if slot.building then
            slot.isBuildable = self:checkBuildingBuildable(slot.building)
        else
            slot.isBuildable = false
        end
    end
end

-- ------------------------------------------------------ --
-- 槽位逻辑
-- ------------------------------------------------------ --
function ShortcutPanel:swapSlots(slotA, slotB)
    if not slotA or not slotB or slotA == slotB then return false end
    
    local slotAIndex = slotA.slotIndex
    local slotBIndex = slotB.slotIndex
    
    if self.pageType == "items" then
        local slotAData = ShortcutConfig.getSlotData(slotAIndex)
        local slotBData = ShortcutConfig.getSlotData(slotBIndex)
        
        ShortcutConfig.setSlotData(slotAIndex, nil)
        ShortcutConfig.setSlotData(slotBIndex, nil)
        
        if slotBData then
            ShortcutConfig.setSlotData(slotAIndex, slotBData)
        end
        
        if slotAData then
            ShortcutConfig.setSlotData(slotBIndex, slotAData)
        end
        
        self:updateSlot(slotAIndex)
        self:updateSlot(slotBIndex)
    elseif self.pageType == "recipes" then
        local slotAData = ShortcutConfig.getRecipeSlotData(slotAIndex)
        local slotBData = ShortcutConfig.getRecipeSlotData(slotBIndex)
        
        ShortcutConfig.setRecipeSlotData(slotAIndex, nil)
        ShortcutConfig.setRecipeSlotData(slotBIndex, nil)
        
        if slotBData then
            ShortcutConfig.setRecipeSlotData(slotAIndex, slotBData)
        end
        
        if slotAData then
            ShortcutConfig.setRecipeSlotData(slotBIndex, slotAData)
        end
        
        self:updateRecipeSlot(slotAIndex)
        self:updateRecipeSlot(slotBIndex)
    else
        local slotAData = ShortcutConfig.getBuildSlotData(slotAIndex)
        local slotBData = ShortcutConfig.getBuildSlotData(slotBIndex)
        
        ShortcutConfig.setBuildSlotData(slotAIndex, nil)
        ShortcutConfig.setBuildSlotData(slotBIndex, nil)
        
        if slotBData then
            ShortcutConfig.setBuildSlotData(slotAIndex, slotBData)
        end
        
        if slotAData then
            ShortcutConfig.setBuildSlotData(slotBIndex, slotAData)
        end
        
        self:updateBuildSlot(slotAIndex)
        self:updateBuildSlot(slotBIndex)
    end
    
    slotA.isDragging = false
    slotB.isDragging = false
    
    return true
end

function ShortcutPanel:clearSlot(slot)
    if not slot then return false end
    
    if self.pageType == "items" then
        slot:clearItem()
    elseif self.pageType == "recipes" then
        slot:clearRecipe()
    else
        slot:clearBuilding()
    end
    slot.isDragging = false
    
    return true
end

-- ------------------------------------------------------ --
-- 交互处理
-- ------------------------------------------------------ --

-- 处理鼠标滚轮事件
function ShortcutPanel:onMouseWheel(del)
    -- 根据滚轮方向切换页面
    
    local currentPageType = self.pageType
    local newPageType = currentPageType
    
    if del > 0 then
        -- 向下滚动，顺序为: items -> recipes -> buildings -> items
        if currentPageType == "items" then
            newPageType = "recipes"
        elseif currentPageType == "recipes" then
            newPageType = "buildings"
        elseif currentPageType == "buildings" then
            newPageType = "items"
        end
    else
        -- 向上滚动，顺序为: items <- recipes <- buildings <- items
        if currentPageType == "items" then
            newPageType = "buildings"
        elseif currentPageType == "recipes" then
            newPageType = "items"
        elseif currentPageType == "buildings" then
            newPageType = "recipes"
        end
    end
    
    if newPageType ~= currentPageType then
        Shortcut.setPageType(newPageType)
        Shortcut.updatePanelContent()
    end
    
    return true
end


function ShortcutPanel:onMouseDown(x, y)
    if Shortcut.isPanelLocked() then
        return
    end

    self.moving = true
    self.dragX = x
    self.dragY = y
    self:bringToTop()
end


function ShortcutPanel:onMouseMove(dx, dy)
    if self.moving and not Shortcut.isPanelLocked() then
        self:setX(self.x + dx)
        self:setY(self.y + dy)
        
        -- 更新控制组件位置
        if self.controlWidget then
            self.controlWidget:updatePosition()
            if not self.controlWidget.visible then
                self.controlWidget:setVisible(true)
                self.controlWidget.visible = true
            end
        end
    end
end


function ShortcutPanel:onMouseMoveOutside(dx, dy)
    if not isMouseButtonDown(0) then
        if self.moving then
            Shortcut.setPanelPosition(self.x, self.y)
            
            if self.controlWidget then
                self.controlWidget:updatePosition()
            end
        end
        self.moving = false
    else
        if self.moving and not Shortcut.isPanelLocked() then
            self:setX(self.x + dx)
            self:setY(self.y + dy)
            
            if self.controlWidget then
                self.controlWidget:updatePosition()
                self.controlWidget:show()
            end
        end
    end
end


function ShortcutPanel:onMouseUp(x, y)
    if self.moving and not Shortcut.isPanelLocked() then
        Shortcut.setPanelPosition(self.x, self.y)
        
        if self.controlWidget and self.controlWidget.visible then
            self.controlWidget:updatePosition()
        end
    end
    self.moving = false
end

function ShortcutPanel:onMouseUpOutside(x, y)
    if self.moving and not Shortcut.isPanelLocked() then
        Shortcut.setPanelPosition(self.x, self.y)
    end
    self.moving = false

    if self.draggingSlot then
        -- 只有当鼠标不在任何UI上时才清理槽位
        if not UIManager.isForceCursorVisible() then
            self:clearSlot(self.draggingSlot)
        end
        
        if self.draggingSlot.dragRenderer then
            self.draggingSlot.dragRenderer:stopDragging()
            self.draggingSlot.dragRenderer = nil
        end
        
        -- 清除全局拖拽引用
        Shortcut.draggedRecipe = nil
        Shortcut.draggedBuilding = nil
        
        self.draggingSlot = nil
    end
end

function ShortcutPanel:close()
    if self.controlWidget then
        self.controlWidget:removeFromUIManager()
        self.controlWidget = nil
    end
    
    Shortcut.closePanel()
end
-- ------------------------------------------------------ --
-- 其他功能方法
-- ------------------------------------------------------ --
function ShortcutPanel:togglePageType()
    local currentPageType = self.pageType
    local newPageType = "items"
    
    if currentPageType == "items" then
        newPageType = "recipes"
    elseif currentPageType == "recipes" then
        newPageType = "buildings"
    else
        newPageType = "items"
    end
    
    Shortcut.setPageType(newPageType)
    Shortcut.updatePanelContent()
    
    return true
end

function ShortcutPanel:handleItemDraggedToSlot(item)
    if not item then return false end
    
    local playerObj = getSpecificPlayer(0)
    if not playerObj then return false end
    
    -- 检测物品是否为玩家库存物品
    local isInPlayerInventory = item:getContainer() and item:getContainer():isInCharacterInventory(playerObj)
    if not isInPlayerInventory then
        -- 获取玩家所有容器
        local containers = ISInventoryPaneContextMenu.getContainers(playerObj)
        local targetContainer = nil
        
        -- 寻找最合适的容器（非主背包优先）
        for i=0,containers:size()-1 do
            local container = containers:get(i)
            if container:isInCharacterInventory(playerObj) and 
               container:hasRoomFor(playerObj, item) and
               container ~= playerObj:getInventory() then
                targetContainer = container
                break
            end
        end

        if not targetContainer then
            targetContainer = playerObj:getInventory()
        end
        
        -- 转移物品
        ISInventoryPaneContextMenu.transferItems({item}, targetContainer, 0)
    end
    
    local wasAlreadyItemsPage = (self.pageType == "items")
    if not wasAlreadyItemsPage then
        Shortcut.setPageType("items")
        Shortcut.updatePanelContent()
    end
    
    -- 找到一个空槽位并添加物品
    local emptySlotFound = false
    for _, slot in ipairs(self.slots) do
        if not slot.item and not slot.itemType then
            slot:setItem(item)
            emptySlotFound = true
            break
        end
    end
    
    return true
end

return ShortcutPanel