require "ISUI/ISPanel"

-- ------------------------------------------------------ --
-- 类定义
-- ------------------------------------------------------ --
ShortcutBuildSlot = ISPanel:derive("ShortcutBuildSlot")

ShortcutBuildSlot.buildCache = {}

-- ------------------------------------------------------ --
-- 槽位操作方法
-- ------------------------------------------------------ --
ShortcutBuildSlot.updateSlotBuild = function(slotIndex, building)
    if not slotIndex then return end
    
    if not building then
        ShortcutConfig.setBuildSlotData(slotIndex, nil)
        
        if Shortcut.panel then
            Shortcut.panel:updateBuildSlot(slotIndex)
        end
        return
    end
    
    local buildingName = building.name
    local moduleName = building.module
    
    if not buildingName then return end
    
    local buildingData = {
        name = buildingName,
        module = moduleName,
        isBuilding = true
    }
    
    local slotBuildings = ShortcutConfig.getAllBuildSlots()
    for otherSlotKey, data in pairs(slotBuildings) do
        if data.name == buildingName and data.module == moduleName then
            local otherSlotIndex = tonumber(otherSlotKey)
            if otherSlotIndex and otherSlotIndex ~= slotIndex then
                ShortcutConfig.setBuildSlotData(otherSlotIndex, nil)
                
                if Shortcut.panel then
                    Shortcut.panel:updateBuildSlot(otherSlotIndex)
                end
            end
        end
    end
    
    ShortcutConfig.setBuildSlotData(slotIndex, buildingData)
    
    if Shortcut.panel then
        Shortcut.panel:updateBuildSlot(slotIndex)
    end
end

ShortcutBuildSlot.findBuildingByName = function(buildingName, moduleName)
    if not buildingName then return nil end
    
    local fullName = moduleName.."."..buildingName
    
    if ShortcutBuildSlot.buildCache[fullName] ~= nil then
        return ShortcutBuildSlot.buildCache[fullName]
    end
    
    local building = nil
    
    if SpriteConfigManager and SpriteConfigManager.GetObjectInfo then
        local objInfo = SpriteConfigManager.GetObjectInfo(buildingName)

        if objInfo and objInfo:getRecipe() then
            building = objInfo:getRecipe():getCraftRecipe()
        end
    end
    ShortcutBuildSlot.buildCache[fullName] = building
    
    return building
end

-- ------------------------------------------------------ --
-- 渲染方法
-- ------------------------------------------------------ --
function ShortcutBuildSlot:prerender()
    ISPanel.prerender(self)
    local slotAlpha = Shortcut.getSlotAlpha()
    -- 绘制背景
    local isPreviewActive = self:checkPreviewActive()
    if isPreviewActive then
        self:drawTextureScaled(self.SlotTexture_Background, 0, 0, self.width, self.height, slotAlpha+0.2, 1.0, 0.55, 0.0)
    else
        self:drawTextureScaled(self.SlotTexture_Background, 0, 0, self.width, self.height, slotAlpha, 0.82, 0.80, 0.66)
    end

    -- 绘制边框
    self:drawTextureScaled(self.SlotTexture_Boarder, 0, 0, self.width, self.height, 0.8, 0.9, 0.6, 0.3)

    if self.isMouseOver and not self.isMouseDown then
        self:drawTextureScaled(self.SlotTexture_Hover, 0, 0, self.width, self.height, 0.3, 1, 1, 1)
    end
end

function ShortcutBuildSlot:render()
    ISPanel.render(self)
    
    if self.buildingName then
        self:renderBuilding()
    end
end

function ShortcutBuildSlot:renderBuilding()
    local texWH = math.min(self.height-2, Shortcut.getActualIconSize())
    local texOffsetY = (self.height-texWH)/2
    local texOffsetX = (self.width-texWH)/2
    
    local alpha = self.isDragging and 0.3 or 1.0
    
    local icon = nil
    
    if self.building then
        icon = self.building:getIconTexture()
    end
    
    -- 获取建造进度信息和剩余时间
    local progress, isBuilding, remainingTime = self:getBuildingCraftingInfo()
    
    -- 显示进度条（如果正在建造）
    if isBuilding and progress > 0 then
        local fillHeight = math.floor(self.height * progress)
        
        self:setStencilRect(0, self.height - fillHeight, self.width, fillHeight)
        self:drawTextureScaled(self.SlotTexture_Background, 0, 0, self.width, self.height, 0.7, 0.3, 0.8, 0.3)
        self:clearStencilRect()
    end
    
    self:drawTextureScaledAspect(icon, texOffsetX, texOffsetY, texWH, texWH, alpha, 1, 1, 1)
    
    if self.isBuildable then
        local buildableIconSize = math.floor(self.width / 4)
        
        local iconX = self.width / 16
        local iconY = self.height - buildableIconSize - self.height / 16
        
        self:drawTextureScaled(self.BuildableIcon, iconX, iconY, buildableIconSize, buildableIconSize, 1.0, 1, 1, 1)
    end
    
    -- 显示剩余时间
    if isBuilding and remainingTime > 0 then  
        local timeText = tostring(remainingTime)
        
        local numberHeight = math.floor(self.height / 3)
        local _, textureHeight = ShortcutUIHelper.getTextureSize()
        local scale = numberHeight / textureHeight
        
        local textX = self.width/16
        local textY = self.height/16
        
        -- 绘制带描边的数字
        ShortcutUIHelper.renderText(self, timeText, textX, textY, scale, alpha, 1, 1, 1, true)
    end
end

function ShortcutBuildSlot:getBuildingIcon()
    if self.building then
        local buildingIcon = self.building:getIconTexture()
        if buildingIcon then
            return buildingIcon
        end
    end
    return nil
end

-- ------------------------------------------------------ --
-- 交互事件处理
-- ------------------------------------------------------ --
function ShortcutBuildSlot:onMouseMove()
    self.isMouseOver = true
    
    local draggedBuilding = Shortcut.draggedBuilding
    if draggedBuilding and not self.parent.draggingSlot then
        self.isDropTarget = true
    else
        self.isDropTarget = false
    end
    
    -- tooltip显示逻辑 - 移动时不更新内容
    local player = getSpecificPlayer(0)
    if player and not player:isDead() and self.building and
       not self.isDragging and
       not self.parent.draggingSlot
    then
        if not (ISContextMenu.instance and ISContextMenu.instance.visibleCheck) then
            if not self.tooltipRender then
                -- 首次创建时设置内容
                self.tooltipRender = ShortcutBuildTooltip:new(self.building)
                self.tooltipRender.owner = self
                self.tooltipRender:initialise()
                self.tooltipRender:addToUIManager()
                self.tooltipRender:setVisible(true)
            else
                if not self.tooltipRender:isVisible() then
                    self.tooltipRender:setBuilding(self.building)
                    self.tooltipRender:setVisible(true)
                    self.tooltipRender:addToUIManager()
                    -- 添加此行确保tooltip显示在顶层
                    self.tooltipRender:bringToTop()
                end
            end
        elseif self.tooltipRender and self.tooltipRender:isVisible() then
            self.tooltipRender:removeFromUIManager()
            self.tooltipRender:setVisible(false)
        end
    elseif self.tooltipRender and self.tooltipRender:isVisible() then
        self.tooltipRender:removeFromUIManager()
        self.tooltipRender:setVisible(false)
    end
    
    if self.parent.draggingSlot == self and not self.dragStarted then
        local x = self:getMouseX()
        local y = self:getMouseY()
        
        if math.abs(x - self.dragStartX) > 4 or math.abs(y - self.dragStartY) > 4 then
            self.dragStarted = true
            self.isDragging = true
            
            -- 拖动开始时隐藏tooltip
            if self.tooltipRender and self.tooltipRender:isVisible() then
                self.tooltipRender:removeFromUIManager()
                self.tooltipRender:setVisible(false)
            end
            
            Shortcut.draggedBuilding = self.building
            
            local icon = self:getBuildingIcon()
            if icon then
                self.dragRenderer = ShortcutDragRenderer.getInstance()
                self.dragRenderer:startDragging({getTex = function() return icon end}, Shortcut.getActualIconSize())
            elseif self.building then
                self.dragRenderer = ShortcutDragRenderer.getInstance()
                self.dragRenderer:startDragging(self.building, Shortcut.getActualIconSize())
            end
        end
    end
end

function ShortcutBuildSlot:onMouseMoveOutside()
    self.isMouseOver = false
    self.isDropTarget = false
    
    if self.tooltipRender and self.tooltipRender:isVisible() then
        self.tooltipRender:removeFromUIManager()
        self.tooltipRender:setVisible(false)
    end
end

function ShortcutBuildSlot:onMouseDown(x, y)
    self.isMouseDown = true
    
    -- 按下时隐藏tooltip
    if self.tooltipRender and self.tooltipRender:isVisible() then
        self.tooltipRender:removeFromUIManager()
        self.tooltipRender:setVisible(false)
    end
    
    if self.building then
        self.parent.draggingSlot = self
        
        self.dragStartX = x
        self.dragStartY = y
        self.dragStarted = false
    end
    
    return true
end

function ShortcutBuildSlot:onRightMouseUp(x, y)
    if self.tooltipRender and self.tooltipRender:isVisible() then
        self.tooltipRender:removeFromUIManager()
        self.tooltipRender:setVisible(false)
    end

    if not self.building then return true end
    
    local player = getSpecificPlayer(0)
    if not player or player:isDead() then return true end
    
    -- 打开建造菜单
    ISEntityUI.OpenBuildWindow(player, nil)
    
    -- 获取当前窗口实例
    local craftingWindow = ISBuildWindow.instance
    if craftingWindow then
        -- 搜索配方
        local buildingName = self.building:getTranslationName() or self.building:getName()
--[[        
        if craftingWindow.recipesPanel and craftingWindow.recipesPanel.recipeFilterPanel.entryBox then
            craftingWindow.recipesPanel.recipeFilterPanel.entryBox:setText(buildingName)
            craftingWindow.recipesPanel.recipeFilterPanel.entryBox:onTextChange()
        end
--]]        
        -- 设置当前选中的配方
        craftingWindow.logic:setRecipe(self.building)
        
        -- 如果有列表面板，确保建筑物被选中
        if craftingWindow.recipesPanel and craftingWindow.recipesPanel.recipeListPanel.recipeListPanel then
            local recipeListPanel = craftingWindow.recipesPanel.recipeListPanel.recipeListPanel
            if recipeListPanel.items then
                for i, item in ipairs(recipeListPanel.items) do
                    if item.item == self.building then
                        recipeListPanel.selected = i
                        recipeListPanel:ensureVisible(i)
                        break
                    end
                end
            end
        end
        
    end
    
    return true
end

function ShortcutBuildSlot:onMouseUp(x, y)
    self.isMouseDown = false
    self.isDropTarget = false
    self.isDragging = false

    if self.parent.draggingSlot == self and not self.dragStarted then
        self.parent.draggingSlot = nil
        
        local currentTime = getTimestampMs()
        if currentTime - self.lastClickTime < 500 then
            self:onDoubleClick()
            self.lastClickTime = 0
        else
            self.lastClickTime = currentTime
        end
        
        -- 松开且未拖动时显示tooltip
        if self.isMouseOver and self.building then
            local player = getSpecificPlayer(0)
            if player and not player:isDead() and not (ISContextMenu.instance and ISContextMenu.instance.visibleCheck) then
                if not self.tooltipRender then
                    self.tooltipRender = ShortcutBuildTooltip:new(self.building)
                    self.tooltipRender.owner = self
                    self.tooltipRender:initialise()
                    self.tooltipRender:addToUIManager()
                    self.tooltipRender:setVisible(true)
                else
                    self.tooltipRender:setVisible(true)
                    self.tooltipRender:addToUIManager()
                    self.tooltipRender:bringToTop()
                end
            end
        end
        
        return true
    end

    -- 检查是否有物品被拖拽到这个建筑槽位上
    if ISMouseDrag.dragging then
        local draggedItems = ISInventoryPane.getActualItems(ISMouseDrag.dragging)
        if draggedItems and #draggedItems > 0 then
            local handled = self.parent:handleItemDraggedToSlot(draggedItems[1])
            if handled then
                ISMouseDrag.dragging = nil
                ISMouseDrag.dragView = nil
                return true
            end
        end
    end
    
    if self.parent.draggingSlot and self.parent.draggingSlot ~= self then
        self.parent:swapSlots(self, self.parent.draggingSlot)
    end
    
    if self.dragRenderer then
        self.dragRenderer:stopDragging()
        self.dragRenderer = nil
    end
    
    self.dragStarted = false
    if self.parent.draggingSlot then
        self.parent.draggingSlot.isDragging = false
    end
    self.parent.draggingSlot = nil
    
    self.lastClickTime = getTimestampMs()
    
    -- 松开时如果鼠标仍在槽位上，显示tooltip
    if self.isMouseOver and self.building then
        local player = getSpecificPlayer(0)
        if player and not player:isDead() and not (ISContextMenu.instance and ISContextMenu.instance.visibleCheck) then
            if not self.tooltipRender then
                self.tooltipRender = ShortcutBuildTooltip:new(self.building)
                self.tooltipRender.owner = self
                self.tooltipRender:initialise()
                self.tooltipRender:addToUIManager()
                self.tooltipRender:setVisible(true)
            else
                self.tooltipRender:setVisible(true)
                self.tooltipRender:addToUIManager()
                self.tooltipRender:bringToTop()
            end
        end
    end
    
    return true
end

function ShortcutBuildSlot:onDoubleClick()
    if not self.building then return end
    
    local player = getSpecificPlayer(0)
    if not player or player:isDead() then return end
    
    local buildLogic = nil
    if Shortcut and Shortcut.panel then
        buildLogic = Shortcut.panel:getSharedBuildLogic()
    end

    if not buildLogic then
        local containers = ISInventoryPaneContextMenu.getContainers(player)
        buildLogic = BuildLogic.new(player, nil, nil)
        buildLogic:setContainers(containers)
    end
    
    buildLogic:setRecipe(self.building)
    local containers = ISInventoryPaneContextMenu.getContainers(player)
    local buildInfo = SpriteConfigManager.GetObjectInfo(tostring(self.building:getName()))
    if not buildInfo then return end

    local buildEntity = ISBuildIsoEntity:new(player, buildInfo, 1, containers, buildLogic)

    local inventory = player:getInventory()
    if self.building:getToolBoth() then
        buildEntity.equipBothHandItem = self:getTool(self.building:getToolBoth(), inventory)
    end
    if self.building:getToolRight() then
        buildEntity.firstItem = self:getTool(self.building:getToolRight(), inventory)
    end
    if self.building:getToolLeft() then
        buildEntity.secondItem = self:getTool(self.building:getToolLeft(), inventory)
    end

    -- 允许连续建造
    buildEntity.dragNilAfterPlace = false
    buildEntity.blockAfterPlace = false
    
    -- 初始检查是否可建造
    if not self.isBuildable then
        buildEntity.blockBuild = true
    end

    getCell():setDrag(buildEntity, player:getPlayerNum())
    
    -- 添加拖动更新事件
    local function updateBuildStatus()
        -- 确保面板和拖动对象仍然存在
        if not Shortcut or not Shortcut.panel or not getCell():getDrag(player:getPlayerNum()) then
            Events.OnTick.Remove(updateBuildStatus)
            return
        end
        
        -- 检测拖动模式，并更新建筑状态
        local dragItem = getCell():getDrag(player:getPlayerNum())
        if dragItem and dragItem == buildEntity then
            local canBuild = Shortcut.panel:checkBuildingBuildable(buildEntity.craftRecipe)
            buildEntity.blockBuild = not canBuild
            Shortcut.panel:updateAllBuildSlotsData()
        else
            -- 退出拖动时，移除事件
            Events.OnTick.Remove(updateBuildStatus)
        end
    end
    
    -- 添加到游戏循环中
    Events.OnTick.Add(updateBuildStatus)
end

-- 添加工具获取函数
function ShortcutBuildSlot:getTool(info, inventory)
    if not info then return nil end
    
    local inputScript = info
    local entryItems = inputScript:getPossibleInputItems()
    
    local item = nil
    for m=0, entryItems:size()-1 do
        local itemType = entryItems:get(m):getFullName()
        local result = inventory:getAllTypeEvalRecurse(itemType, ISBuildIsoEntity.predicateMaterial)
        if result:size() > 0 then
            item = result:get(0):getFullType()
            break
        end
    end
    
    if item then
        return item
    else
        return nil
    end
end

function ShortcutBuildSlot:onMouseUpOutside(x, y)
    self.isMouseDown = false
    self.isDragging = false
    self.dragStarted = false
    
    if self.dragRenderer then
        self.dragRenderer:stopDragging()
        self.dragRenderer = nil
    end
    
    Shortcut.draggedBuilding = nil
    
    return true
end
-- ------------------------------------------------------ --
-- 建筑物检测方法
-- ------------------------------------------------------ --
-- 检查是否处于预览状态
function ShortcutBuildSlot:checkPreviewActive()
    local player = getSpecificPlayer(0)
    if not player or not self.building then return false end
    
    local cellDrag = getCell():getDrag(player:getPlayerNum())
    if not cellDrag then return false end

    if cellDrag.objectInfo and cellDrag.objectInfo:getRecipe() and self.building then
        local previewRecipe = cellDrag.objectInfo:getRecipe():getCraftRecipe()
        if previewRecipe then
            local slotRecipeName = self.building:getName()
            local previewRecipeName = previewRecipe:getName()
            
            if slotRecipeName == previewRecipeName then
                return true
            end
        end
    end
    
    return false
end

function ShortcutBuildSlot:getBuildingCraftingInfo()
    if not self.building then return 0, false, 0 end
    
    local player = getSpecificPlayer(0)
    if not player then return 0, false, 0 end
    
    local queue = ISTimedActionQueue.queues[player]
    if not queue or not queue.queue or #queue.queue == 0 then return 0, false, 0 end
    
    for i=1, #queue.queue do
        local action = queue.queue[i]
        if action and action.Type == "ISBuildAction" and action.started then
            if action.item and action.item.name == self.building:getName() then
                local delta = action:getJobDelta()
                local remainingTimeInTicks = action.maxTime * (1 - delta)
                local remainingTimeInSeconds = math.ceil(remainingTimeInTicks / 30)
                
                if remainingTimeInSeconds <= 0 and delta < 1 then
                    remainingTimeInSeconds = 1
                end
                
                return delta, true, remainingTimeInSeconds
            end
        end
    end
    
    return 0, false, 0
end

-- ------------------------------------------------------ --
-- 建筑物管理方法
-- ------------------------------------------------------ --
function ShortcutBuildSlot:setBuilding(building)
    if not self.slotIndex then return end
    
    if instanceof(building, "Recipe") then
        local isBuildingRecipe = false
        if SpriteConfigManager and SpriteConfigManager.GetObjectInfo then
            local objInfo = SpriteConfigManager.GetObjectInfo(tostring(building:getName()))
            if objInfo then
                isBuildingRecipe = true
            end
        end
        
        if not isBuildingRecipe then
            return
        end
        
        local moduleName = building:getModule():getName()
        
        local buildingData = {
            name = building:getName(),
            module = moduleName,
            isBuilding = true
        }
        
        ShortcutBuildSlot.updateSlotBuild(self.slotIndex, buildingData)
        self.building = building
        self.buildingName = building:getName()
        self.moduleName = moduleName
    elseif type(building) == "table" and building.name then
        ShortcutBuildSlot.updateSlotBuild(self.slotIndex, building)
        self.buildingName = building.name
        self.moduleName = building.module
        self.building = ShortcutBuildSlot.findBuildingByName(self.buildingName, self.moduleName)
    else
        self:clearBuilding()
    end
end

function ShortcutBuildSlot:loadBuildingFromConfig()
    if not self.slotIndex then return end
    
    local data = ShortcutConfig.getBuildSlotData(self.slotIndex)
    if data then
        self.buildingName = data.name
        self.moduleName = data.module
        self.building = ShortcutBuildSlot.findBuildingByName(self.buildingName, self.moduleName)
        print("Loading building from config: ", self.buildingName, self.moduleName, self.building)
    end
end

function ShortcutBuildSlot:clearBuilding()
    if not self.slotIndex then return end
    
    ShortcutBuildSlot.updateSlotBuild(self.slotIndex, nil)
    
    self.building = nil
    self.buildingName = nil
    self.moduleName = nil
end

-- ------------------------------------------------------ --
-- 实例初始化方法
-- ------------------------------------------------------ --
function ShortcutBuildSlot:initialise()
    ISPanel.initialise(self)
    self:loadBuildingFromConfig()
end

function ShortcutBuildSlot:new(x, y, width, height, slotIndex)
    local slotSize = Shortcut.getActualSlotSize()
    
    local o = ISPanel:new(x, y, slotSize, slotSize)
    setmetatable(o, self)
    self.__index = self
    
    o.width = slotSize
    o.height = slotSize
    o.backgroundColor.a = 0
    o.borderColor.a = 0
    o.isMouseOver = false
    o.isMouseDown = false
    o.building = nil
    o.buildingName = nil
    o.slotIndex = slotIndex
    o.isDragging = false
    
    o.dragStartX = 0
    o.dragStartY = 0
    o.dragStarted = false
    o.isDropTarget = false
    o.lastClickTime = 0
    
    o.SlotTexture_Boarder = getTexture("media/ui/TheShortCut/TheShortCut_Slot_Boarder.png")
    o.SlotTexture_Background = getTexture("media/ui/TheShortCut/TheShortCut_Slot_Background.png")
    o.SlotTexture_Hover = getTexture("media/ui/TheShortCut/TheShortCut_Slot_Background.png")

    o.BuildableIcon = getTexture("media/ui/TheShortCut/Icon/icon_Check.png")
    o.Crafting_Boarder = getTexture("media/ui/TheShortCut/TheShortCut_Slot_Equipboarder.png")
    
    return o
end

return ShortcutBuildSlot