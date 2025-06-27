require "ISUI/ISPanel"

ShortcutRecipeSlot = ISPanel:derive("ShortcutRecipeSlot")

ShortcutRecipeSlot.recipeCache = {}
ShortcutRecipeSlot.recipePropertiesCache = {}

-- ------------------------------------------------------ --
-- 槽位操作高级方法
-- ------------------------------------------------------ --
ShortcutRecipeSlot.updateSlotRecipe = function(slotIndex, recipe)
    if not slotIndex then return end
    
    if not recipe then
        ShortcutConfig.setRecipeSlotData(slotIndex, nil)
        
        if Shortcut.panel then
            Shortcut.panel:updateRecipeSlot(slotIndex)
        end
        return
    end
    
    local recipeName = recipe.name
    local moduleName = recipe.module
    
    if not recipeName then return end
    
    local recipeData = {
        name = recipeName,
        module = moduleName
    }
    
    local slotRecipes = ShortcutConfig.getAllRecipeSlots()
    for otherSlotKey, data in pairs(slotRecipes) do
        if data.name == recipeName and data.module == moduleName then
            local otherSlotIndex = tonumber(otherSlotKey)
            if otherSlotIndex and otherSlotIndex ~= slotIndex then
                ShortcutConfig.setRecipeSlotData(otherSlotIndex, nil)
                
                if Shortcut.panel then
                    Shortcut.panel:updateRecipeSlot(otherSlotIndex)
                end
            end
        end
    end
    
    ShortcutConfig.setRecipeSlotData(slotIndex, recipeData)
    
    if Shortcut.panel then
        Shortcut.panel:updateRecipeSlot(slotIndex)
    end
end

-- ------------------------------------------------------ --
-- 渲染方法
-- ------------------------------------------------------ --
function ShortcutRecipeSlot:prerender()
    ISPanel.prerender(self)
    local slotAlpha = Shortcut.getSlotAlpha()
    self:drawTextureScaled(self.SlotTexture_Background, 0, 0, self.width, self.height, slotAlpha, 0.73, 0.78, 0.83)
    self:drawTextureScaled(self.SlotTexture_Boarder, 0, 0, self.width, self.height, 0.8, 0.45, 0.7, 0.95)

    if self.isMouseOver and not self.isMouseDown then
        self:drawTextureScaled(self.SlotTexture_Hover, 0, 0, self.width, self.height, 0.3, 1, 1, 1)
    end
end

function ShortcutRecipeSlot:render()
    ISPanel.render(self)
    
    if self.recipeName then
        self:renderRecipe()
    end
end

function ShortcutRecipeSlot:renderRecipe()
    local texWH = math.min(self.height-2, Shortcut.getActualIconSize())
    local texOffsetY = (self.height-texWH)/2
    local texOffsetX = (self.width-texWH)/2
    
    local isCraftable = self.isCraftable
    
    -- 拖动时降低透明度
    local alpha = self.isDragging and 0.3 or 1.0
    
    -- 显示制作进度条
    local progress, isCrafting, remainingTime = self:getRecipeCraftingInfo()
    
    if isCrafting and progress > 0 then
        local fillHeight = math.floor(self.height * progress)
        
        self:setStencilRect(0, self.height - fillHeight, self.width, fillHeight)
        self:drawTextureScaled(self.SlotTexture_Background, 0, 0, self.width, self.height, 0.7, 0.3, 0.8, 0.3)
        self:clearStencilRect()
    end
    
    -- 绘制图标
    local icon = nil
    if self.recipe then
        icon = self.recipe:getIconTexture()
    end
    if not isCraftable then
        self:drawTextureScaledAspect(icon, texOffsetX, texOffsetY, texWH, texWH, 0.8, 1, 1, 1)
    else
        self:drawTextureScaledAspect(icon, texOffsetX, texOffsetY, texWH, texWH, alpha, 1, 1, 1)
    end
    
    -- 绘制可用图标
    if isCraftable then
        local craftableIconSize = math.floor(self.width / 4)

        local iconX = self.width / 16
        local iconY = self.height - craftableIconSize - self.height / 16
        
        if self.CraftableIcon then
            self:drawTextureScaled(self.CraftableIcon, iconX, iconY, craftableIconSize, craftableIconSize, 1.0, 1, 1, 1)
        end
        
        -- 显示最大可制作数量 (当数量大于1时)
        if self.maxCraftCount > 1 then

            local countText = tostring(self.maxCraftCount)
            local numberHeight = math.floor(self.height / 3)
            local _, textureHeight = ShortcutUIHelper.getTextureSize()
            local scale = numberHeight / textureHeight
            local textWidth = ShortcutUIHelper.measureTextWidth(countText, scale, true)
            local textX = self.width - textWidth - self.width/16
            local textY = self.height - numberHeight - self.height/16

            ShortcutUIHelper.renderText(self, countText, textX, textY, scale, alpha, 1, 1, 1, true)
        end
    end
    
    -- 显示制作时间
    if isCrafting and remainingTime > 0 then
        if not ShortcutUIHelper.isLoaded then
            ShortcutUIHelper.loadTextures()
        end

        local timeText = tostring(remainingTime)

        local numberHeight = math.floor(self.height / 3)
        local _, textureHeight = ShortcutUIHelper.getTextureSize()
        local scale = numberHeight / textureHeight

        local textX = self.width/16
        local textY = self.height/16

        ShortcutUIHelper.renderText(self, timeText, textX, textY, scale, alpha, 1, 1, 1, true)
    end
end

function ShortcutRecipeSlot:getRecipeIcon()
    if self.recipe then
        local recipeIcon = self.recipe:getIconTexture()
        if recipeIcon then
            return recipeIcon
        end
        
        local resultItem = self.recipe:getResult()
        if resultItem then
            local itemType = resultItem:getFullType()
            local texture = getTexture("Item_" .. itemType)
            if texture then
                return texture
            end
        end
    end
end

ShortcutRecipeSlot.findRecipeByName = function(recipeName, moduleName)
    if not recipeName then return nil end
    
    local moduleStr = moduleName or "Base"
    local fullName = moduleStr.."."..recipeName
    
    if ShortcutRecipeSlot.recipeCache[fullName] ~= nil then
        return ShortcutRecipeSlot.recipeCache[fullName]
    end
    
    local recipe = getScriptManager():getCraftRecipe(fullName)
    
    ShortcutRecipeSlot.recipeCache[fullName] = recipe
    
    return recipe
end

-- ------------------------------------------------------ --
-- 交互事件处理
-- ------------------------------------------------------ --
function ShortcutRecipeSlot:onMouseMove()
    self.isMouseOver = true
    
    local draggedRecipe = Shortcut.draggedRecipe
    if draggedRecipe and not self.parent.draggingSlot then
        self.isDropTarget = true
    else
        self.isDropTarget = false
    end
    
    -- tooltip处理 - 移动时不更新内容
    local player = getSpecificPlayer(0)
    if player and not player:isDead() and self.recipe and 
       not self.isDragging and 
       not self.parent.draggingSlot
    then
        if not (ISContextMenu.instance and ISContextMenu.instance.visibleCheck) then
            if not self.tooltipRender then
                self.tooltipRender = ShortcutRecipeTooltip:new(self.recipe)
                self.tooltipRender.owner = self
                self.tooltipRender:initialise()
                self.tooltipRender:addToUIManager()
                self.tooltipRender:setVisible(true)
            else
                if not self.tooltipRender:isVisible() then
                    self.tooltipRender:setRecipe(self.recipe)
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
            
            Shortcut.draggedRecipe = self.recipe
            
            local icon = self:getRecipeIcon()
            if icon then
                self.dragRenderer = ShortcutDragRenderer.getInstance()
                self.dragRenderer:startDragging({getTex = function() return icon end}, Shortcut.getActualIconSize())
            end
        end
    end
end

function ShortcutRecipeSlot:onMouseMoveOutside()
    self.isMouseOver = false
    self.isDropTarget = false

    if self.tooltipRender and self.tooltipRender:isVisible() then
        self.tooltipRender:removeFromUIManager()
        self.tooltipRender:setVisible(false)
    end
end

function ShortcutRecipeSlot:onMouseDown(x, y)
    self.isMouseDown = true
    
    -- 按下时隐藏tooltip
    if self.tooltipRender and self.tooltipRender:isVisible() then
        self.tooltipRender:removeFromUIManager()
        self.tooltipRender:setVisible(false)
    end
    
    if self.recipe then
        self.parent.draggingSlot = self
        
        self.dragStartX = x
        self.dragStartY = y
        self.dragStarted = false
    end
    
    return true
end

function ShortcutRecipeSlot:onMouseUp(x, y)
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
        if self.isMouseOver and self.recipe then
            local player = getSpecificPlayer(0)
            if player and not player:isDead() and not (ISContextMenu.instance and ISContextMenu.instance.visibleCheck) then
                if not self.tooltipRender then
                    self.tooltipRender = ShortcutRecipeTooltip:new(self.recipe)
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

    -- 检查是否有物品被拖拽到这个配方槽位上
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
    if self.isMouseOver and self.recipe then
        local player = getSpecificPlayer(0)
        if player and not player:isDead() and not (ISContextMenu.instance and ISContextMenu.instance.visibleCheck) then
            if not self.tooltipRender then
                self.tooltipRender = ShortcutRecipeTooltip:new(self.recipe)
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

function ShortcutRecipeSlot:onDoubleClick()
    if not self.recipe then return end
    
    if self.isCraftable then
        self:performRecipe()
    end
end

function ShortcutRecipeSlot:onMouseUpOutside(x, y)
    self.isMouseDown = false
    self.isDragging = false
    self.dragStarted = false
    
    if self.dragRenderer then
        self.dragRenderer:stopDragging()
        self.dragRenderer = nil
    end
    
    Shortcut.draggedRecipe = nil
    
    return true
end

function ShortcutRecipeSlot:onRightMouseUp(x, y)
    if not self.recipe then return true end
    
    local player = getSpecificPlayer(0)
    if not player or player:isDead() then return true end
    
    -- 隐藏tooltip
    if self.tooltipRender and self.tooltipRender:isVisible() then
        self.tooltipRender:removeFromUIManager()
        self.tooltipRender:setVisible(false)
    end
    
    -- 打开制作面板
    ISEntityUI.OpenHandcraftWindow(player, nil)
    
    -- 获取制作面板的各个组件
    local handCraftPanel = ISEntityUI.players[0].windows["HandcraftWindow"].instance.handCraftPanel
    local recipeFilterPanel = handCraftPanel.recipesPanel.recipeFilterPanel
    local recipeListPanel = handCraftPanel.recipesPanel.recipeListPanel.recipeListPanel
    
    local translatedName = self.recipe:getTranslationName()
--[[    -- 让制作面板搜索配方
    handCraftPanel:setRecipeFilter(translatedName, "RecipeName")
    recipeFilterPanel.filterTypeCombo:selectData("RecipeName")
    recipeFilterPanel.entryBox:setText(translatedName)
    --]]
    -- 让制作面板选择配方
    local items = recipeListPanel.items
    if items and #items > 0 then
        for i, item in ipairs(items) do
            if item.text == translatedName then
                recipeListPanel.selected = i
                recipeListPanel:ensureVisible(i)
                if item.item then
                    handCraftPanel.logic:setRecipe(item.item)
                end
                break
            end
        end
    end
    
    return true
end

function ShortcutRecipeSlot:performRecipe()
    if not self.recipe then return end
    
    local player = getSpecificPlayer(0)
    if not player then return end
    
    local craftLogic = nil
    if Shortcut.panel then
        craftLogic = Shortcut.panel:getSharedCraftLogic()
    end
    
    if not craftLogic then
        local workbench = ISEntityUI.FindCraftSurface(player, 3)
        local containers = ISInventoryPaneContextMenu.getContainers(player)
        craftLogic = HandcraftLogic.new(player, nil, workbench)
        craftLogic:setContainers(containers)
    end
    
    craftLogic:setRecipe(self.recipe)
    craftLogic:autoPopulateInputs()
    
    local action = ISHandcraftAction.FromLogic(craftLogic)
    
    ISTimedActionQueue.add(action)
end

-- ------------------------------------------------------ --
-- 检测处理
-- ------------------------------------------------------ --

function ShortcutRecipeSlot:getRecipeCraftingInfo()
    if not self.recipe then return 0, false, 0 end
    
    local player = getSpecificPlayer(0)
    if not player then return 0, false, 0 end
    
    local queue = ISTimedActionQueue.queues[player]
    if not queue or not queue.queue or #queue.queue == 0 then return 0, false, 0 end
    
    for i=1, #queue.queue do
        local action = queue.queue[i]
        if action and action.Type == "ISHandcraftAction" and action.craftRecipe then
            if action.craftRecipe:getName() == self.recipe:getName() and
               action.craftRecipe:getModule():getName() == self.recipe:getModule():getName() then
                
                -- 定义默认值
                local delta = 0
                
                -- 直接从action获取delta (如果可用)
                if action and type(action) == "table" and type(action.getJobDelta) == "function" then
                    local success = true
                    -- 在调用前检查action是否有效
                    if not action.action then
                        success = false
                    end
                    
                    if success then
                        delta = action:getJobDelta()
                    end
                -- 从action.action获取delta (备选方案)
                elseif action and type(action) == "table" and action.action and 
                       type(action.action) == "table" and type(action.action.getJobDelta) == "function" then
                    delta = action.action:getJobDelta()
                end
                
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
-- 配方管理方法
-- ------------------------------------------------------ --
function ShortcutRecipeSlot:setRecipe(recipe)
    if not self.slotIndex then return end
    
    if instanceof(recipe, "Recipe") then
        local moduleName = recipe:getModule():getName()
        
        local recipeData = {
            name = recipe:getName(),
            module = moduleName
        }
        
        ShortcutRecipeSlot.updateSlotRecipe(self.slotIndex, recipeData)
        self.recipe = recipe
        self.recipeName = recipe:getName()
        self.moduleName = moduleName
    elseif type(recipe) == "table" and recipe.name then
        ShortcutRecipeSlot.updateSlotRecipe(self.slotIndex, recipe)
        self.recipeName = recipe.name
        self.moduleName = recipe.module
        self.recipe = ShortcutRecipeSlot.findRecipeByName(self.recipeName, self.moduleName)
    else
        self:clearRecipe()
    end
end

function ShortcutRecipeSlot:loadRecipeFromConfig()
    if not self.slotIndex then return end
    
    local data = ShortcutConfig.getRecipeSlotData(self.slotIndex)
    if data then
        self.recipeName = data.name
        self.moduleName = data.module
        self.recipe = ShortcutRecipeSlot.findRecipeByName(self.recipeName, self.moduleName)
    end
end

function ShortcutRecipeSlot:clearRecipe()
    if not self.slotIndex then return end
    
    ShortcutRecipeSlot.updateSlotRecipe(self.slotIndex, nil)
    
    self.recipe = nil
    self.recipeName = nil
    self.moduleName = nil
end

-- ------------------------------------------------------ --
-- 实例初始化方法
-- ------------------------------------------------------ --
function ShortcutRecipeSlot:initialise()
    ISPanel.initialise(self)
    self:loadRecipeFromConfig()
end

function ShortcutRecipeSlot:new(x, y, width, height, slotIndex)
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
    o.recipe = nil
    o.recipeName = nil
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

    o.CraftableIcon = getTexture("media/ui/TheShortCut/Icon/icon_Check.png")
    
    return o
end

return ShortcutRecipeSlot