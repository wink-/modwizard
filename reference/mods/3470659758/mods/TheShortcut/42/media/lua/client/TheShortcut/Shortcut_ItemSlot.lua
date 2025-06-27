require "ISUI/ISPanel"

-- ------------------------------------------------------ --
-- 类定义
-- ------------------------------------------------------ --
ShortcutItemSlot = ISPanel:derive("ShortcutItemSlot")

-- ------------------------------------------------------ --
-- 槽位操作方法
-- ------------------------------------------------------ --
ShortcutItemSlot.updateSlotItem = function(slotIndex, item)
    if not slotIndex then return end
    
    if not item then
        ShortcutConfig.setSlotData(slotIndex, nil)
        
        if Shortcut.panel then
            Shortcut.panel:updateSlot(slotIndex)
        end
        return
    end
    
    -- 只获取物品类型
    local itemType = item:getFullType()
    
    -- 检查是否已存在相同物品，只比较类型
    local slotItems = ShortcutConfig.getAllSlots()
    for otherSlotKey, data in pairs(slotItems) do
        if data.type == itemType then
            local otherSlotIndex = tonumber(otherSlotKey)
            if otherSlotIndex and otherSlotIndex ~= slotIndex then
                ShortcutConfig.setSlotData(otherSlotIndex, nil)
                
                if Shortcut.panel then
                    Shortcut.panel:updateSlot(otherSlotIndex)
                end
            end
        end
    end
    
    -- 保存物品数据，只包含类型
    ShortcutConfig.setSlotData(slotIndex, {
        type = itemType
    })
    
    if Shortcut.panel then
        Shortcut.panel:updateSlot(slotIndex)
    end
end

-- ------------------------------------------------------ --
-- 渲染方法
-- ------------------------------------------------------ --
function ShortcutItemSlot:prerender()
    local slotAlpha = Shortcut.getSlotAlpha()
    self:drawTextureScaled(self.SlotTexture_Background, 0, 0, self.width, self.height, slotAlpha, 0.8, 0.8, 0.8)
    
    if self.isDropTarget then
        self:drawTextureScaled(self.SlotTexture_Boarder, 0, 0, self.width, self.height, 0.8, 0.3, 0.8, 0.3)
    else
        self:drawTextureScaled(self.SlotTexture_Boarder, 0, 0, self.width, self.height, 0.8, 0.5, 0.5, 0.5)
    end

    if self.item and self.item:isEquipped() then
        self:drawTextureScaled(self.Equip_Boarder, -1, -1, self.width+2, self.height+2, 0.8, 0.8, 0.8, 0.8)
    end
    
    if self.isMouseOver and not self.isMouseDown then
        self:drawTextureScaled(self.SlotTexture_Hover, 0, 0, self.width, self.height, 0.3, 1, 1, 1)
    end
end

function ShortcutItemSlot:render()
    
    if self.item then
        self:renderItem()
    end
end

function ShortcutItemSlot:renderItem()
    if not self.item then return end
    
    local texWH = math.min(self.height-2, Shortcut.getActualIconSize())
    local texOffsetY = (self.height-texWH)/2
    local texOffsetX = (self.width-texWH)/2
    
    local baseAlpha = (self.itemCount and self.itemCount > 0) and 1.0 or 0.7
    local alpha = self.isDragging and (baseAlpha * 0.4) or baseAlpha
    
    local isVirtualItem = (self.itemCount == 0)
    
    if not isVirtualItem then
        local ratio, r, g, b, a = ShortcutItemState.getItemStateInfo(self.item)
        if ratio > 0 then
            local fillHeight = math.floor(self.height * ratio)
            
            self:setStencilRect(0, self.height - fillHeight, self.width, fillHeight)
            self:drawTextureScaled(self.SlotTexture_Background, 0, 0, self.width, self.height, a, r, g, b)
            self:clearStencilRect()
        end
        
        ShortcutItemState.renderItemSpecialStates(self, self.item, 0, 0, self.width, self.height)
    end
    
    if isVirtualItem and self.cachedTexture then
        self:drawTextureScaledAspect(self.cachedTexture, texOffsetX, texOffsetY, texWH, texWH, alpha, 1, 1, 1)
    else
        ISInventoryItem.renderItemIcon(self, self.item, texOffsetX, texOffsetY, alpha, texWH, texWH)
        
        if isVirtualItem and not self.cachedTexture then
            self.cachedTexture = self.item:getTex()
        end
    end
    -- 绘制虚拟物品图标
    if isVirtualItem then
        local iconSize = math.floor(self.width *0.4)
        local iconX = self.width - iconSize - self.width/24
        local iconY = self.height - iconSize - self.height/24
        self:drawTextureScaled(self.virtualItemIcon, iconX, iconY, iconSize, iconSize, 1, 1, 1, 1)
    end
    
    -- 绘制数量
    if self.itemCount and self.itemCount > 1 then
        local countText = tostring(self.itemCount)
        local numberHeight = math.floor(self.height / 3)
        local _, textureHeight = ShortcutUIHelper.getTextureSize()
        local scale = numberHeight / textureHeight
        local textWidth = ShortcutUIHelper.measureTextWidth(countText, scale, true)
        local textX = self.width - textWidth - self.width/16
        local textY = self.height - numberHeight - self.height/16

        ShortcutUIHelper.renderText(self, countText, textX, textY, scale, alpha, 1, 1, 1, true)
    end
end

-- ------------------------------------------------------ --
-- 交互事件处理
-- ------------------------------------------------------ --
function ShortcutItemSlot:onMouseMove()
    self.isMouseOver = true
    
    if player and not player:isDead() and contextMenu and contextMenu:isAnyVisible() then
        if self.tooltipRender and self.tooltipRender:isVisible() then
            self.tooltipRender:removeFromUIManager()
            self.tooltipRender:setVisible(false)
        end
        return
    end
    
    if self.item and self.itemCount > 0 and 
       not self.isDragging and
       not self.parent.draggingSlot
    then
        if not self.tooltipRender then
            self.tooltipRender = ISToolTipInv:new(self.item)
            self.tooltipRender:initialise()
            self.tooltipRender:addToUIManager()
            self.tooltipRender:setVisible(true)
            self.tooltipRender:setOwner(self)
            local playerObj = getSpecificPlayer(0)
            self.tooltipRender:setCharacter(playerObj)
            self.tooltipRender.followMouse = true
        else
            self.tooltipRender:setItem(self.item)
            self.tooltipRender:setVisible(true)
            self.tooltipRender:addToUIManager()
        end
    elseif self.tooltipRender and self.tooltipRender:isVisible() then
        self.tooltipRender:removeFromUIManager()
        self.tooltipRender:setVisible(false)
    end
    
    if ISMouseDrag.dragging and not self.parent.draggingSlot then
        self.isDropTarget = true
    else
        self.isDropTarget = false
    end
    
    if self.parent.draggingSlot == self and not self.dragStarted then
        local x = self:getMouseX()
        local y = self:getMouseY()
        
        if math.abs(x - self.dragStartX) > 4 or math.abs(y - self.dragStartY) > 4 then
            self.dragStarted = true
            self.isDragging = true
            
            self.dragRenderer = ShortcutDragRenderer:new()
            self.dragRenderer:instantiate()
            self.dragRenderer:addToUIManager()
            self.dragRenderer:startDragging(self.item, Shortcut.getActualIconSize())
        end
    end
end

function ShortcutItemSlot:onMouseMoveOutside()
    self.isMouseOver = false
    self.isDropTarget = false
    
    if self.tooltipRender and self.tooltipRender:isVisible() then
        self.tooltipRender:removeFromUIManager()
        self.tooltipRender:setVisible(false)
    end
end

function ShortcutItemSlot:onMouseDown(x, y)
    self.isMouseDown = true
    if self.item then
        self.parent.draggingSlot = self
        
        self.dragStartX = x
        self.dragStartY = y
        self.dragStarted = false
    end
    
    return true
end

function ShortcutItemSlot:onMouseUp(x, y)
    self.isMouseDown = false
    self.isDropTarget = false
    self.isDragging = false

    if self.parent.draggingSlot == self and not self.dragStarted then
        self.parent.draggingSlot = nil
        
        -- 检查距离上次刷新的时间间隔
        local currentTime = getTimestampMs()
        local refreshInterval = currentTime - (self.lastRefreshTime or 0)
        
        -- 单击时就刷新缓存
        if refreshInterval > 500 then
            if self.itemType then
                ShortcutItem.itemsCache = nil
                local data = ShortcutItem.getSelfItemData(self.itemType)
                
                if data then
                    if data.item and data.count > 0 then
                        self.item = data.item
                        self.itemCount = data.count
                    else
                        if not self.item then
                            self.item = ShortcutItem.createVirtualItem(self.itemType)
                            if self.item then
                                self.cachedTexture = self.item:getTex()
                            end
                        end
                        self.itemCount = 0
                    end
                end
                
                -- 记录刷新时间
                self.lastRefreshTime = currentTime
            end
        end
        
        -- 检查是否是双击
        if currentTime - self.lastClickTime < 500 then
            self:onDoubleClick()
            self.lastClickTime = 0
        else
            self.lastClickTime = currentTime
        end
        
        -- 显示tooltip
        if self.isMouseOver and self.item then
            local player = getSpecificPlayer(0)
            if player and not player:isDead() and not (ISContextMenu.instance and ISContextMenu.instance.visibleCheck) then
                if not self.tooltipRender then
                    self.tooltipRender = ISToolTipInv:new(self.item)
                    self.tooltipRender:initialise()
                    self.tooltipRender:addToUIManager()
                    self.tooltipRender:setVisible(true)
                    self.tooltipRender:setOwner(self)
                    local playerObj = getSpecificPlayer(0)
                    self.tooltipRender:setCharacter(playerObj)
                    self.tooltipRender.followMouse = true
                else
                    self.tooltipRender:setItem(self.item)
                    self.tooltipRender:setVisible(true)
                    self.tooltipRender:addToUIManager()
                end
            end
        end
        
        return true
    end

    -- 其余代码保持不变
    if ISMouseDrag.dragging then
        local draggedItems = ISInventoryPane.getActualItems(ISMouseDrag.dragging)
        if draggedItems and #draggedItems > 0 then
            local item = draggedItems[1]
            
            local playerObj = getSpecificPlayer(0)
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

                self:setItem(item)
            else
                self:setItem(item)
            end
            
            ISMouseDrag.dragging = nil
            ISMouseDrag.dragView = nil
        end
    end
    
    if self.parent.draggingSlot and self.parent.draggingSlot ~= self then
        self.parent:swapSlots(self, self.parent.draggingSlot)
    end
    
    if self.dragRenderer then
        self.dragRenderer:removeFromUIManager()
        self.dragRenderer = nil
    end
    
    self.dragStarted = false
    if self.parent.draggingSlot then
        self.parent.draggingSlot.isDragging = false
    end
    self.parent.draggingSlot = nil
    self.lastClickTime = getTimestampMs()
    
    -- 松开时如果鼠标仍在槽位上，显示tooltip
    if self.isMouseOver and self.item then
        local player = getSpecificPlayer(0)
        if player and not player:isDead() and not (ISContextMenu.instance and ISContextMenu.instance.visibleCheck) then
            if not self.tooltipRender then
                self.tooltipRender = ISToolTipInv:new(self.item)
                self.tooltipRender:initialise()
                self.tooltipRender:addToUIManager()
                self.tooltipRender:setVisible(true)
                self.tooltipRender:setOwner(self)
                local playerObj = getSpecificPlayer(0)
                self.tooltipRender:setCharacter(playerObj)
                self.tooltipRender.followMouse = true
            else
                self.tooltipRender:setItem(self.item)
                self.tooltipRender:setVisible(true)
                self.tooltipRender:addToUIManager()
            end
        end
    end
    
    return true
end

function ShortcutItemSlot:onMouseUpOutside(x, y)
    self.isMouseDown = false
    self.isDragging = false
    self.dragStarted = false
    
    if self.dragRenderer then
        self.dragRenderer:removeFromUIManager()
        self.dragRenderer = nil
    end
    
    return true
end

function ShortcutItemSlot:onRightMouseUp(x, y)
    if self.tooltipRender and self.tooltipRender:isVisible() then
        self.tooltipRender:removeFromUIManager()
        self.tooltipRender:setVisible(false)
    end
    
    if not self.item or not self.itemCount or self.itemCount <= 0 then return true end
    
    local playerObj = getSpecificPlayer(0)
    if not playerObj then return true end
    
    local isInPlayerInventory = self.item:getContainer() and self.item:getContainer():isInCharacterInventory(playerObj)
    
    local contextX = self:getAbsoluteX() + x
    local contextY = self:getAbsoluteY() + y
    
    local contextItems = {self.item}
    
    local menu = ISInventoryPaneContextMenu.createMenu(0, isInPlayerInventory, contextItems, contextX, contextY)
    
    if menu and menu.numOptions > 1 and JoypadState.players[1] then
        menu.mouseOver = 1
        setJoypadFocus(0, menu)
    end
    
    if getPlayerInventory(0).inventoryPane.toolRender then
        getPlayerInventory(0).inventoryPane.toolRender:setVisible(false)
    end
    
    return true
end

function ShortcutItemSlot:onDoubleClick()
    if not self.item or self.itemCount <= 0 then return end

    ShortcutItemAction.handleDoubleClick(self.item)
end

-- ------------------------------------------------------ --
-- 物品管理方法
-- ------------------------------------------------------ --
function ShortcutItemSlot:setItem(item)
    if not self.slotIndex or not item then 
        self:clearItem()
        return 
    end
    
    ShortcutItemSlot.updateSlotItem(self.slotIndex, item)
    self.item = item
    self.itemType = item:getFullType()
    self.cachedTexture = item:getTex()
    local data = ShortcutItem.getSelfItemData(self.itemType)
    self.itemCount = data and data.count or 1
end

function ShortcutItemSlot:clearItem()
    if not self.slotIndex then return end
    ShortcutItemSlot.updateSlotItem(self.slotIndex, nil)
    self.item = nil
    self.itemType = nil
    self.itemCount = 0
    self.cachedTexture = nil
end

function ShortcutItemSlot:loadItemFromConfig()
    if not self.slotIndex then return end
    
    local data = ShortcutConfig.getSlotData(self.slotIndex)
    if data then
        self.itemType = data.type
        self.item = nil
        self.itemCount = 0
    end
end

-- ------------------------------------------------------ --
-- 实例初始化方法
-- ------------------------------------------------------ --
function ShortcutItemSlot:initialise()
    ISPanel.initialise(self)
    self:loadItemFromConfig()
end


function ShortcutItemSlot:new(x, y, width, height, slotIndex)
    local slotSize = Shortcut.getActualSlotSize()
    
    local o = ISPanel:new(x, y, slotSize, slotSize)
    setmetatable(o, self)
    self.__index = self
    
    o.width = slotSize
    o.height = slotSize
    o.isMouseOver = false
    o.isMouseDown = false
    o.item = nil
    o.itemType = nil
    o.slotIndex = slotIndex
    o.itemCount = 0
    o.isDragging = false
    o.cachedTexture = nil
    o.lastClickTime = 0
    o.dragStartX = 0
    o.dragStartY = 0
    o.dragStarted = false
    o.isDropTarget = false
    
    o.SlotTexture_Boarder = getTexture("media/ui/TheShortCut/TheShortCut_Slot_Boarder.png")
    o.SlotTexture_Background = getTexture("media/ui/TheShortCut/TheShortCut_Slot_Background.png")
    o.SlotTexture_Hover = getTexture("media/ui/TheShortCut/TheShortCut_Slot_Background.png")
    o.SlotTexture_Durability = getTexture("media/ui/TheShortCut/TheShortCut_Slot_Durability.png")

    o.virtualItemIcon = getTexture("media/ui/TheShortCut/Icon/Icon_Virtual.png")

    o.Equip_Boarder = getTexture("media/ui/TheShortCut/TheShortCut_Slot_Equipboarder.png")
    
    return o
end

return ShortcutItemSlot