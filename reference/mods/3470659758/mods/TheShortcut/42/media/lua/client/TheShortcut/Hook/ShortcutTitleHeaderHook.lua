-- ------------------------------------------------------ --
-- 保存原始函数引用
-- ------------------------------------------------------ --
local original_createChildren = ISWidgetTitleHeader.createChildren
local original_calculateLayout = ISWidgetTitleHeader.calculateLayout

-- ------------------------------------------------------ --
-- UI 组件创建
-- ------------------------------------------------------ --
function ISWidgetTitleHeader:createChildren()
    original_createChildren(self)
    
    if self.recipe then
        local buttonTexture = getTexture("media/ui/TheShortCut/Icon/Icon_Add.png")
        
        self.shortcutButton = ISButton:new(0, 0, 20, 20, "", self, ISWidgetTitleHeader.onShortcutButtonClick)
        self.shortcutButton.borderColor = {r=0.4, g=0.4, b=0.4, a=0}
        self.shortcutButton.backgroundColor = {r=0.2, g=0.2, b=0.2, a=0}
        self.shortcutButton.backgroundColorMouseOver = {r=0.3, g=0.3, b=0.3, a=0}
        
        self.shortcutButton.buttonTexture = buttonTexture
        self.shortcutButton.recipeRef = self.recipe
        
        self.shortcutButton:initialise()
        self.shortcutButton:instantiate()
        self:addChild(self.shortcutButton)
        
        self.shortcutButton.render = function(button)
            local alpha = button.mouseOver and 1.0 or 0.8
            button:drawTextureScaled(button.buttonTexture, 0, 0, button:getWidth(), button:getHeight(), alpha, 1, 0.5, 0)
        end
    end
end

-- ------------------------------------------------------ --
-- 布局计算
-- ------------------------------------------------------ --
function ISWidgetTitleHeader:calculateLayout(_preferredWidth, _preferredHeight)
    original_calculateLayout(self, _preferredWidth, _preferredHeight)
    
    if self.shortcutButton then
        if self.icon then
            local iconX = self.icon:getX()
            local iconY = self.icon:getY()
            local iconWidth = self.icon:getWidth()
            local iconHeight = self.icon:getHeight()
            
            self.shortcutButton:setX(iconX + iconWidth - self.shortcutButton:getWidth()/2 - iconWidth/32)
            self.shortcutButton:setY(iconY + iconHeight - self.shortcutButton:getHeight()/2 - iconWidth/32)
        end
    end
end

-- ------------------------------------------------------ --
-- 事件处理
-- ------------------------------------------------------ --
function ISWidgetTitleHeader:onShortcutButtonClick()
    local recipe = self.recipe
    if not recipe then return end
    
    local isBuildingRecipe = false
    
    if SpriteConfigManager and SpriteConfigManager.GetObjectInfo then
        local objInfo = SpriteConfigManager.GetObjectInfo(tostring(recipe:getName()))
        if objInfo then
            isBuildingRecipe = true
        end
    end
    
    local recipeData = {
        name = recipe:getName(),
        module = recipe:getModule():getName()
    }
    
    local success = false
    
    if isBuildingRecipe then
        success = Shortcut.addBuildingToSlot(recipeData)
    else
        success = Shortcut.addRecipeToSlot(recipeData)
    end
    
    if success and not Shortcut.panel then
        Shortcut.createPanel()
    end
end


local function enableNCShortcutButton()
    if NC_RecipeInfoPanel then
        -- 重写点击事件
        function NC_RecipeInfoPanel:onShortcutButtonClick()
            local recipe = self.shortcutButton.recipe
            if not recipe then return end

            local isBuildingRecipe = false
            if SpriteConfigManager and SpriteConfigManager.GetObjectInfo then
                local objInfo = SpriteConfigManager.GetObjectInfo(tostring(recipe:getName()))
                if objInfo then
                    isBuildingRecipe = true
                end
            end
            
            local recipeData = {
                name = recipe:getName(),
                module = recipe:getModule():getName()
            }
            
            local success = false
            if isBuildingRecipe then
                success = Shortcut.addBuildingToSlot(recipeData)
            else
                success = Shortcut.addRecipeToSlot(recipeData)
            end
            
            if success and not Shortcut.panel then
                Shortcut.createPanel()
            end
        end
        
        -- Hook createChildren来启用按钮
        local original_createChildren = NC_RecipeInfoPanel.createChildren
        function NC_RecipeInfoPanel:createChildren()
            original_createChildren(self)
            if self.hasShortcutButton then
                self:enableShortcutButton()
            end
        end
    end
end

Events.OnGameStart.Add(enableNCShortcutButton)