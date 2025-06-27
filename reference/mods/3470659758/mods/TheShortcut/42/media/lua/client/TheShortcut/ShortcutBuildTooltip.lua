require "ISUI/ISPanel"

ActiveBuildTooltip = nil
ShortcutBuildTooltip = ISPanel:derive("ShortcutBuildTooltip")

-- ------------------------------------------------------ --
-- 初始化方法
-- ------------------------------------------------------ --
function ShortcutBuildTooltip:initialise()
    ISPanel.initialise(self)
end

function ShortcutBuildTooltip:instantiate()
    ISPanel.instantiate(self)
    self.javaObject:setConsumeMouseEvents(false)
end

function ShortcutBuildTooltip:setBuilding(building) 
    if not building then return end
    
    local player = getSpecificPlayer(0)
    if not player then return end
    
    -- 解析建筑数据
    self:parseBuildingData(building, player)
    
    -- 计算布局
    self:calculateLayout(building)
end

function ShortcutBuildTooltip:parseBuildingData(building, player)
    -- 清空数据
    self.skills = {}
    self.materials = {}
    
    -- 技能要求
    if building:getRequiredSkillCount() > 0 then
        for i=0, building:getRequiredSkillCount()-1 do
            local requiredSkill = building:getRequiredSkill(i)
            local perk = requiredSkill:getPerk()
            local level = requiredSkill:getLevel()
            local hasSkill = player:getPerkLevel(perk) >= level
            
            local color = hasSkill and {r=0.3, g=1, b=0.3} or {r=1, g=0.3, b=0.3}
            local skillText = perk:getName() .. " " .. getText("IGUI_CraftingWindow_Level") .. " " .. level
            
            table.insert(self.skills, {
                label = skillText,
                color = color
            })
        end
    end
    
    -- 材料
    local inputs = building:getInputs()
    if inputs and inputs:size() > 0 then
        for i=0, inputs:size()-1 do
            local input = inputs:get(i)
            -- 跳过自动化专用材料
            if not input:isAutomationOnly() then
                local itemName = ""
                local amount = 0
                local icon = nil
                local itemObj = nil
                
                if input:getResourceType() == ResourceType.Item then
                    amount = input:getIntAmount()
                    local items = input:getPossibleInputItems()
                    if items and items:size() > 0 then
                        itemName = items:get(0):getDisplayName()
                        -- 获取第一个可能的物品作为代表
                        local itemFullType = items:get(0):getFullName()
                        local itemScript = getScriptManager():getItem(itemFullType)
                        if itemScript then
                            itemObj = itemScript:InstanceItem(nil)
                            if itemObj then
                                icon = itemObj:getTex()
                            end
                        end
                    else
                        itemName = input:getType() or "Unknown Item"
                    end
                elseif input:getResourceType() == ResourceType.Fluid then
                    amount = input:getAmount()
                    itemName = input:getType() or "Unknown Fluid"
                else
                    amount = input:getAmount()
                    itemName = input:getType() or "Unknown Resource"
                end

                table.insert(self.materials, {
                    name = itemName,
                    amount = amount,
                    icon = icon,
                    item = itemObj
                })
            end
        end
    end
end

-- 截断文本
function ShortcutBuildTooltip:truncateText(text, font, maxWidth)
    if not text then return "" end
    
    local fullWidth = getTextManager():MeasureStringX(font, text)
    if fullWidth <= maxWidth then return text end
    
    local truncated = ""
    local width = 0
    local ellipsis = "..."
    local ellipsisWidth = getTextManager():MeasureStringX(font, ellipsis)
    
    for i = 1, #text do
        local char = string.sub(text, i, i)
        local charWidth = getTextManager():MeasureStringX(font, char)
        
        if width + charWidth + ellipsisWidth > maxWidth then
            return truncated .. ellipsis
        end
        
        truncated = truncated .. char
        width = width + charWidth
    end
    
    return truncated
end

function ShortcutBuildTooltip:calculateLayout(building)
    building = building or (self.owner and self.owner.building)
    if not building then 
        self:setWidth(200)
        self:setHeight(100)
        return 
    end
    
    local buildingName = (self.owner and self.owner.buildingName) or building:getTranslationName() or building:getName()
    
    local PADDING = 5
    local TEXT_INDENT = 15
    local DIVIDER_HEIGHT = 1
    local LINE_HEIGHT = getTextManager():getFontHeight(UIFont.Small)
    local TITLE_HEIGHT = getTextManager():getFontHeight(UIFont.Medium)
    
    -- 设置图标大小和框大小
    self.itemIconSize = 32
    self.frameSize = 42
    
    -- 模块1高度: 图标/名称
    local iconSize = TITLE_HEIGHT * 2
    local module1Height = PADDING + math.max(iconSize, TITLE_HEIGHT + LINE_HEIGHT + 2) + PADDING
    
    -- 计算最大宽度
    local requiredWidth = 320
    
    -- 计算名称宽度
    local maxNameWidth = 220
    local truncatedName = self:truncateText(buildingName, UIFont.Medium, maxNameWidth)
    local nameWidth = getTextManager():MeasureStringX(UIFont.Medium, truncatedName) + iconSize + PADDING * 3
    requiredWidth = math.max(requiredWidth, nameWidth)
    
    -- 技能文本宽度
    for _, skill in ipairs(self.skills) do
        local textWidth = getTextManager():MeasureStringX(UIFont.Small, "- " .. skill.label) + PADDING * 3
        requiredWidth = math.max(requiredWidth, textWidth)
    end
    
    local currentY = module1Height + DIVIDER_HEIGHT
    
    -- 模块2高度: 技能列表
    local module2Height = 0
    if #self.skills > 0 then
        module2Height = module2Height + (#self.skills * LINE_HEIGHT)
    end
    
    currentY = currentY + module2Height + DIVIDER_HEIGHT
    
    -- 模块3高度: 材料布局
    local module3Height = 0
    
    -- 如果有材料，添加一个"材料"标题
    if #self.materials > 0 then
        module3Height = module3Height + LINE_HEIGHT + PADDING
    end
    
    -- 物品图标区域
    local iconSpacing = 8 
    local availableWidth = requiredWidth - (PADDING * 2)
    local maxIconsPerRow = math.floor((availableWidth + iconSpacing) / (self.frameSize + iconSpacing))
    maxIconsPerRow = math.max(1, maxIconsPerRow)  -- 确保至少放一个
    local rowsNeeded = math.ceil(#self.materials / maxIconsPerRow)
    local rowHeight = self.frameSize + PADDING
    module3Height = module3Height + (rowsNeeded * rowHeight)
    
    currentY = currentY + module3Height
    
    -- 总高度
    local totalHeight = currentY + PADDING
    
    -- 保存模块位置信息
    self.layout = {
        padding = PADDING,
        lineHeight = LINE_HEIGHT,
        titleHeight = TITLE_HEIGHT,
        indentation = TEXT_INDENT,
        itemIconSize = self.itemIconSize,
        frameSize = self.frameSize,
        maxIconsPerRow = maxIconsPerRow,
        
        module1 = {
            y = PADDING,
            height = module1Height - PADDING
        },
        
        divider1 = module1Height,
        
        module2 = {
            y = module1Height + DIVIDER_HEIGHT,
            height = module2Height
        },
        
        divider2 = module1Height + DIVIDER_HEIGHT + module2Height,
        
        module3 = {
            y = module1Height + DIVIDER_HEIGHT + module2Height + DIVIDER_HEIGHT,
            height = module3Height
        },
    }
    
    self:setWidth(requiredWidth)
    self:setHeight(totalHeight)
end

-- ------------------------------------------------------ --
-- 渲染材料
-- ------------------------------------------------------ --
function ShortcutBuildTooltip:renderMaterials()
    if #self.materials == 0 then return end
    
    local PADDING = self.layout.padding
    local LINE_HEIGHT = self.layout.lineHeight
    local currentY = self.layout.module3.y
    local iconSize = self.layout.itemIconSize
    local frameSize = self.layout.frameSize
    local maxIconsPerRow = self.layout.maxIconsPerRow
    
    -- 分隔线
    self:drawRect(PADDING, self.layout.divider2, self.width - PADDING * 2, 1, 0.8, 0.6, 0.6, 0.6)
    
    -- 材料标题
    self:drawText(getText("IGUI_CraftingWindow_Requires"), PADDING, currentY, 1, 1, 1, 1, UIFont.Small)
    currentY = currentY + LINE_HEIGHT + PADDING
    
    -- 绘制材料图标
    local iconSpacing = 8
    
    -- 计算每行可放置的最大图标数
    local maxIconsPerRow = self.layout.maxIconsPerRow
    
    for i, material in ipairs(self.materials) do
        local row = math.floor((i-1) / maxIconsPerRow)
        local col = (i-1) % maxIconsPerRow
        
        local frameX = PADDING + (col * (frameSize + iconSpacing))
        local frameY = currentY + (row * (frameSize + PADDING))
        
        -- 计算图标的位置（在框内居中）
        local iconX = frameX + (frameSize - iconSize) / 2
        local iconY = frameY + (frameSize - iconSize) / 2
        
        -- 绘制框背景
        self:drawRect(frameX, frameY, frameSize, frameSize, 0.8, 0.15, 0.15, 0.15)
        self:drawRectBorder(frameX, frameY, frameSize, frameSize, 0.8, 0.3, 0.3, 0.3)
        
        -- 绘制图标
        if material.icon then
            self:drawTextureScaledAspect(material.icon, iconX, iconY, iconSize, iconSize, 1, 1, 1, 1)
        elseif material.item then
            ISInventoryItem.renderItemIcon(self, material.item, iconX, iconY, 1, iconSize, iconSize)
        end
        
        -- 绘制数量
        local countText = tostring(material.amount)
        local textWidth = getTextManager():MeasureStringX(UIFont.Small, countText)
        local textX = frameX + frameSize - textWidth - 3
        local textY = frameY + frameSize - LINE_HEIGHT
        
        -- 绘制数量文本
        self:drawText(countText, textX, textY, 1, 1, 1, 1, UIFont.Small)
    end
end

-- ------------------------------------------------------ --
-- 位置调整相关方法
-- ------------------------------------------------------ --
-- 检测两个矩形是否重叠
function ShortcutBuildTooltip:overlaps(r1, r2)
    return r1.x + r1.width > r2.x and r1.x < r2.x + r2.width and
           r1.y + r1.height > r2.y and r1.y < r2.y + r2.height
end

-- 将提示框放在目标左侧
function ShortcutBuildTooltip:placeLeft(r1, r2)
    local r = {}
    for k,v in pairs(r1) do r[k] = v end
    r.x = math.max(0, r2.x - r.width - 8)
    return r
end

-- 将提示框放在目标右侧
function ShortcutBuildTooltip:placeRight(r1, r2)
    local r = {}
    for k,v in pairs(r1) do r[k] = v end
    r.x = r2.x + r2.width + 8
    r.x = math.min(r.x, getCore():getScreenWidth() - r.width)
    return r
end

-- 将提示框放在目标上方
function ShortcutBuildTooltip:placeAbove(r1, r2)
    local r = {}
    for k,v in pairs(r1) do r[k] = v end
    r.y = r2.y - r.height - 8
    r.y = math.max(0, r.y)
    return r
end

-- ------------------------------------------------------ --
-- 渲染方法
-- ------------------------------------------------------ --
function ShortcutBuildTooltip:prerender()
    if self.owner and not self.owner:isReallyVisible() then
        self:removeFromUIManager()
        self:setVisible(false)
        return
    end
    
    -- 计算智能位置
    local mouseX = getMouseX()
    local mouseY = getMouseY()
    local mouseSize = 32
    
    -- 设置初始位置
    local mx = mouseX + 32
    local my = mouseY + 10
    
    if not self.followMouse then
        mx = self:getX()
        my = self:getY()
    end
    if self.desiredX and self.desiredY then
        mx = self.desiredX
        my = self.desiredY
    end
    
    self:setX(mx)
    self:setY(my)
    
    local myRect = { x = self:getX(), y = self:getY(), width = self:getWidth(), height = self:getHeight() }
    
    -- 定义鼠标所指向的区域
    local avoidRect = { 
        x = mouseX - mouseSize/2, 
        y = mouseY - mouseSize/2, 
        width = mouseSize, 
        height = mouseSize 
    }
    
    -- 检查是否需要调整位置
    if self:overlaps(myRect, avoidRect) then
        local r = self:placeRight(myRect, avoidRect)

        if self:overlaps(r, avoidRect) then
            r = self:placeAbove(myRect, avoidRect)

            if self:overlaps(r, avoidRect) then
                r = self:placeLeft(myRect, avoidRect)
            end
        end
        
        -- 应用调整后的位置
        self:setX(r.x)
        self:setY(r.y)
    end
    
    local maxX = getCore():getScreenWidth()
    local maxY = getCore():getScreenHeight()
    
    if self:getX() + self:getWidth() > maxX then
        self:setX(maxX - self:getWidth())
    end
    
    if self:getY() + self:getHeight() > maxY then
        self:setY(maxY - self:getHeight())
    end
    
    -- 绘制背景
    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
end

function ShortcutBuildTooltip:render()
    -- 检查必要的条件
    if not self.owner or not self.owner.building or not self.layout then return end
    
    local building = self.owner.building
    local canBuild = self.owner.isBuildable
    local buildingName = building:getTranslationName() or self.owner.buildingName
    local iconTexture = self.owner.iconTexture or building:getIconTexture()
    
    -- 绘制边框和背景
    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)

    -- 获取布局参数
    local PADDING = self.layout.padding
    local LINE_HEIGHT = self.layout.lineHeight
    local TITLE_HEIGHT = self.layout.titleHeight
    local INDENT = self.layout.indentation
    
    -- ========== 模块1: 图标和名称 ==========
    local iconSize = TITLE_HEIGHT * 2
    local iconY = PADDING
    local iconX = PADDING
    
    -- 绘制图标
    if iconTexture then
        self:drawTextureScaledAspect(iconTexture, iconX, iconY, iconSize, iconSize, 1, 1, 1, 1)
    end
    
    -- 绘制名称
    local nameX = iconX + iconSize + PADDING
    local nameY = iconY
    local maxNameWidth = 220
    local displayName = self:truncateText(buildingName, UIFont.Medium, maxNameWidth)
    
    -- 根据是否可建造设置颜色
    local textColor = canBuild and {r=1, g=1, b=1} or {r=1, g=0.5, b=0.5}
    self:drawText(displayName, nameX, nameY, textColor.r, textColor.g, textColor.b, 1, UIFont.Medium)
    
    -- 绘制建造时间
    local buildTime = building:getTime()
    if buildTime then
        local timeY = nameY + TITLE_HEIGHT + 2
        local clockIcon = getTexture("media/ui/craftingMenus/BuildProperty_Clock.png")
        local clockSize = LINE_HEIGHT
        
        if clockIcon then
            self:drawTextureScaledAspect(clockIcon, nameX, timeY, clockSize, clockSize, 1, 1, 1, 1)
            
            -- 转换时间格式
            local gameTime = buildTime
            local realTimeSeconds = gameTime / 10
            
            -- 格式化显示时间
            local timeText = ""
            if realTimeSeconds >= 60 then
                local minutes = math.floor(realTimeSeconds / 60)
                local seconds = math.floor(realTimeSeconds % 60)
                timeText = minutes .. ":" .. string.format("%02d", seconds)
            else
                if realTimeSeconds < 1 then
                    timeText = "<1s"
                else
                    timeText = math.floor(realTimeSeconds) .. "s"
                end
            end
            
            self:drawText(timeText, nameX + clockSize + 5, timeY, 0.8, 0.8, 0.8, 1, UIFont.Small)
        end
    end
    
    -- ========== 模块2: 技能列表 ==========
    local currentY = self.layout.module2.y
    
    -- 技能列表
    if #self.skills > 0 then
        for _, skill in ipairs(self.skills) do
            local text = "- " .. skill.label
            self:drawText(text, PADDING + INDENT, currentY, skill.color.r, skill.color.g, skill.color.b, 1, UIFont.Small)
            currentY = currentY + LINE_HEIGHT
        end
    end
    
    -- ========== 模块3: 材料 ==========
    if #self.materials > 0 then
        self:renderMaterials()
    end
end

-- ------------------------------------------------------ --
-- 构造函数
-- ------------------------------------------------------ --
function ShortcutBuildTooltip:new(building)
    local o = ISPanel:new(0, 0, 1, 1)
    setmetatable(o, self)
    self.__index = self
    
    -- 更新全局引用
    if ActiveBuildTooltip and ActiveBuildTooltip:isVisible() then
        ActiveBuildTooltip:removeFromUIManager()
    end
    ActiveBuildTooltip = o
    
    o.backgroundColor = {r=0.0, g=0.0, b=0.0, a=0.3}
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=0.7}
    o.followMouse = true
    
    -- 初始化数据结构
    o.skills = {}
    o.materials = {}
    
    if building then
        o:setBuilding(building)
    end
    
    return o
end

return ShortcutBuildTooltip