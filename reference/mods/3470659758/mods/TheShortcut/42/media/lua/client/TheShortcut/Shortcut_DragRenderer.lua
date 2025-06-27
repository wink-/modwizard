require "ISUI/ISUIElement"

-- ------------------------------------------------------ --
-- 类定义
-- ------------------------------------------------------ --
ShortcutDragRenderer = ISUIElement:derive("ShortcutDragRenderer")

-- ------------------------------------------------------ --
-- 初始化方法
-- ------------------------------------------------------ --
function ShortcutDragRenderer:new()
    local o = ISUIElement:new(0, 0, 1, 1)
    setmetatable(o, self)
    self.__index = self
    
    o.item = nil
    o.iconSize = 32
    o.isRecipe = false
    o.iconTexture = nil
    return o
end

-- ------------------------------------------------------ --
-- 拖拽操作方法
-- ------------------------------------------------------ --
function ShortcutDragRenderer:startDragging(item, iconSize)
    self.item = item
    self.iconSize = iconSize or 32
    self.visible = true
    self:setAlwaysOnTop(true)
    
    if item and type(item) == "table" and type(item.getTex) == "function" then
        self.isRecipe = true
        self.iconTexture = item:getTex()
    elseif item and instanceof(item, "Texture") then
        self.isRecipe = true
        self.iconTexture = item
    else
        self.isRecipe = false
    end
end

function ShortcutDragRenderer:stopDragging()
    self.item = nil
    self.iconTexture = nil
    self.visible = false
    self.isRecipe = false
end

-- ------------------------------------------------------ --
-- 渲染方法
-- ------------------------------------------------------ --
function ShortcutDragRenderer:render()
    if not self.visible then return end
    
    local mx = getMouseX()
    local my = getMouseY()
    
    local iconX = mx - self.iconSize / 2
    local iconY = my - self.iconSize / 2
    
    if self.isRecipe then
        if self.iconTexture then
            self:drawTextureScaledAspect(self.iconTexture, iconX, iconY, self.iconSize, self.iconSize, 1, 1, 1, 1)
        end
    else
        if self.item and self.item:getTex() then
            ISInventoryItem.renderItemIcon(self, self.item, iconX, iconY, 1, self.iconSize, self.iconSize)
        end
    end
end

-- ------------------------------------------------------ --
-- 单例模式实例管理
-- ------------------------------------------------------ --
ShortcutDragRenderer.instance = nil
ShortcutDragRenderer.getInstance = function()
    if not ShortcutDragRenderer.instance then
        ShortcutDragRenderer.instance = ShortcutDragRenderer:new()
        ShortcutDragRenderer.instance:instantiate()
        ShortcutDragRenderer.instance:addToUIManager()
        ShortcutDragRenderer.instance.visible = false
    end
    return ShortcutDragRenderer.instance
end

return ShortcutDragRenderer