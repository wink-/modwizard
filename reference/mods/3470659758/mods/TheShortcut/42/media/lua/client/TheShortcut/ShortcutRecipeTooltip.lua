require "ISUI/ISPanel"
ActiveRecipeTooltip = nil

ShortcutRecipeTooltip = ISPanel:derive("ShortcutRecipeTooltip")

-- ------------------------------------------------------ --
-- 初始化方法
-- ------------------------------------------------------ --
function ShortcutRecipeTooltip:initialise()
    ISPanel.initialise(self)
end

function ShortcutRecipeTooltip:instantiate()
    ISPanel.instantiate(self)
    self.javaObject:setConsumeMouseEvents(false)
end

function ShortcutRecipeTooltip:setRecipe(recipe, craftLogic)
    self.recipe = recipe
    
    if not recipe then return end
    
    local player = getSpecificPlayer(0)
    if not player then return end

    self:parseRecipeData(recipe, player)
    self:loadConditionIcons(recipe, player)
    self:calculateLayout()
end

function ShortcutRecipeTooltip:parseRecipeData(recipe, player)
    -- 清空数据
    self.conditions = {}
    self.skills = {}
    self.materials = {}
    self.tools = {}
    self.results = {}

    -- 获取可能使用的craftLogic
    local craftLogic = nil
    if Shortcut and Shortcut.panel then
        craftLogic = Shortcut.panel:getSharedCraftLogic()
        if craftLogic and craftLogic:getRecipe() ~= recipe then
            -- 确保使用正确的配方
            craftLogic:setRecipe(recipe)
        end
    end
    
    -- 技能要求
    if recipe:getRequiredSkillCount() > 0 then
        for i=0, recipe:getRequiredSkillCount()-1 do
            local requiredSkill = recipe:getRequiredSkill(i)
            local perk = requiredSkill:getPerk()
            local level = requiredSkill:getLevel()
            local hasSkill = player:getPerkLevel(perk) >= level
            
            local color = hasSkill and {r=0.3, g=1, b=0.3} or {r=1, g=0.3, b=0.3}
            local skillText = perk:getName() .. " " .. getText("IGUI_CraftingWindow_Level") .. " " .. level
            
            table.insert(self.skills, {
                label = skillText,
                value = "",
                color = color
            })
        end
    end
    
    -- 使用已有的sharedLogic
    if Shortcut and Shortcut.panel then
        sharedLogic = Shortcut.panel:getSharedCraftLogic()
        if sharedLogic then
            if sharedLogic:getRecipe() ~= recipe then
                sharedLogic:setRecipe(recipe)
            end
            -- 从sharedLogic获取所有物品
            allItems = sharedLogic:getAllItems()
        end
    end
    
    -- 材料
    local inputs = recipe:getInputs()
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
                    
                    -- 检查是否有满足的物品（使用craftLogic）
                    local satisfiedItems = nil
                    if craftLogic then
                        satisfiedItems = craftLogic:getSatisfiedInputInventoryItems(input)
                    end
                    
                    -- 如果有满足的物品，使用第一个
                    if satisfiedItems and satisfiedItems:size() > 0 then
                        local satisfiedItem = satisfiedItems:get(0)
                        itemName = satisfiedItem:getDisplayName()
                        icon = satisfiedItem:getTex()
                        itemObj = satisfiedItem
                    else
                        -- 没有满足的物品，使用可能物品中的第一个
                        local possibleItems = input:getPossibleInputItems()
                        if possibleItems and possibleItems:size() > 0 then
                            itemName = possibleItems:get(0):getDisplayName()
                            local itemFullType = possibleItems:get(0):getFullName()
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
    
    -- 产出
    local outputs = recipe:getOutputs()
    if outputs and outputs:size() > 0 then
        for i=0, outputs:size()-1 do
            local output = outputs:get(i)
            if not output:isAutomationOnly() then
                local itemName = ""
                local amount = 0
                local icon = nil
                local itemObj = nil
                
                if output:getResourceType() == ResourceType.Item then
                    amount = output:getIntAmount()
                    local items = output:getPossibleResultItems()
                    if items and items:size() > 0 then
                        itemName = items:get(0):getDisplayName()
                        -- 获取第一个物品的图标
                        local itemFullType = items:get(0):getFullName()
                        local itemScript = getScriptManager():getItem(itemFullType)
                        if itemScript then
                            itemObj = itemScript:InstanceItem(nil)
                            if itemObj then
                                icon = itemObj:getTex()
                            end
                        end
                    else
                        itemName = output:getType() or "Unknown Item"
                    end
                elseif output:getResourceType() == ResourceType.Fluid then
                    amount = output:getAmount()
                    itemName = output:getType() or "Unknown Fluid"
                else
                    amount = output:getAmount()
                    itemName = output:getType() or "Unknown Resource"
                end
                
                table.insert(self.results, {
                    name = itemName,
                    amount = amount,
                    icon = icon,
                    item = itemObj
                })
            end
        end
    end
end

-- 加载条件图标
function ShortcutRecipeTooltip:loadConditionIcons(recipe, player)
    self.conditionIcons = {}
    
    -- 表面要求图标
    if recipe:isAnySurfaceCraft() then
        local iconTex = getTexture("media/ui/craftingMenus/BuildProperty_Surface.png")
        
        local inRange = false 

        local craftLogic = nil
        if Shortcut and Shortcut.panel then
            craftLogic = Shortcut.panel:getSharedCraftLogic()
        end
        
        if craftLogic then
            local oldRecipe = craftLogic:getRecipe()
            craftLogic:setRecipe(recipe)
            inRange = craftLogic:isCharacterInRangeOfWorkbench()

            if oldRecipe then
                craftLogic:setRecipe(oldRecipe)
            end
        end
        
        local color = inRange and {r=1, g=1, b=1} or {r=1, g=0, b=0}
        
        table.insert(self.conditionIcons, {
            texture = iconTex,
            color = color
        })
    end
    
    -- 光照要求图标
    if not recipe:canBeDoneInDark() then
        local iconTex = getTexture("media/ui/craftingMenus/BuildProperty_Light.png")
        local isDark = player:tooDarkToRead()
        
        local color = isDark and {r=1, g=0, b=0} or {r=1, g=1, b=1}
        
        table.insert(self.conditionIcons, {
            texture = iconTex,
            color = color
        })
    end
    
    -- 行走要求图标
    if recipe:isCanWalk() then
        local iconTex = getTexture("media/ui/craftingMenus/BuildProperty_Walking.png")
        local canWalk = not player:isPlayerMoving() and not player:hasAwkwardHands()
        
        local color = canWalk and {r=1, g=1, b=1} or {r=1, g=0, b=0}
        
        table.insert(self.conditionIcons, {
            texture = iconTex,
            color = color
        })
    end
    
    -- 学习要求图标
    if recipe:needToBeLearn() then
        local iconTex = getTexture("media/ui/craftingMenus/BuildProperty_Book.png")
        local learned = player:isRecipeKnown(recipe, true)
        
        local color = learned and {r=1, g=1, b=1} or {r=1, g=0, b=0}
        
        table.insert(self.conditionIcons, {
            texture = iconTex,
            color = color
        })
    end
end

function ShortcutRecipeTooltip:renderMaterialsAndResults()
    local PADDING = self.layout.padding
    local LINE_HEIGHT = self.layout.lineHeight
    local currentY = self.layout.module3.y
    local iconSize = self.layout.itemIconSize
    local frameSize = self.layout.frameSize
    local iconSpacing = 8
    local maxIconsPerRow = self.layout.maxIconsPerRow
    local centerGap = 14
    
    -- 分隔线上方留出空间
    self:drawRect(PADDING, self.layout.divider2, self.width - PADDING * 2, 1, 0.8, 0.6, 0.6, 0.6)

    -- 材料标题（左侧）
    self:drawText(getText("IGUI_CraftingWindow_Requires"), PADDING, currentY, 1, 1, 1, 1, UIFont.Small)

    -- 产出标题（右侧）
    local outText = getText("IGUI_CraftingWindow_Creates")
    local leftAreaWidth = (self.width - centerGap) / 2 - PADDING
    local rightStartX = leftAreaWidth + PADDING + centerGap
    self:drawText(outText, rightStartX, currentY, 1, 1, 1, 1, UIFont.Small)

    currentY = currentY + LINE_HEIGHT + PADDING
    
    -- 计算左侧区域宽度（材料区）
    local leftAreaWidth = (self.width - centerGap) / 2 - PADDING
    
    -- 绘制材料图标（左侧）
    for i, material in ipairs(self.materials) do
        local row = math.floor((i-1) / maxIconsPerRow)
        local col = (i-1) % maxIconsPerRow
        
        -- 计算框的位置，确保不超过左区域宽度
        local availableWidth = leftAreaWidth - PADDING
        local itemWidth = frameSize + iconSpacing
        local adjustedSpacing = (availableWidth - (maxIconsPerRow * frameSize)) / (maxIconsPerRow - 1)
        adjustedSpacing = math.max(4, math.min(adjustedSpacing, iconSpacing))
        
        local frameX = PADDING + (col * (frameSize + adjustedSpacing))
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

    -- 绘制产出图标（右侧）
    local rightStartX = leftAreaWidth + PADDING + centerGap
    for i, result in ipairs(self.results) do
        local row = math.floor((i-1) / maxIconsPerRow)
        local col = (i-1) % maxIconsPerRow
        
        -- 计算右侧区域的可用宽度和间距调整
        local availableWidth = leftAreaWidth - PADDING
        local itemWidth = frameSize + iconSpacing
        local adjustedSpacing = (availableWidth - (maxIconsPerRow * frameSize)) / (maxIconsPerRow - 1)
        adjustedSpacing = math.max(4, math.min(adjustedSpacing, iconSpacing))
        
        -- 计算框的位置
        local frameX = rightStartX + (col * (frameSize + adjustedSpacing))
        local frameY = currentY + (row * (frameSize + PADDING))
        
        -- 计算图标的位置（在框内居中）
        local iconX = frameX + (frameSize - iconSize) / 2
        local iconY = frameY + (frameSize - iconSize) / 2
        
        -- 绘制框背景
        self:drawRect(frameX, frameY, frameSize, frameSize, 0.8, 0.15, 0.15, 0.15)
        self:drawRectBorder(frameX, frameY, frameSize, frameSize, 0.8, 0.3, 0.6, 0.3) 
        
        -- 绘制图标
        if result.icon then
            self:drawTextureScaledAspect(result.icon, iconX, iconY, iconSize, iconSize, 1, 1, 1, 1)
        elseif result.item then
            ISInventoryItem.renderItemIcon(self, result.item, iconX, iconY, 1, iconSize, iconSize)
        end
        
        -- 绘制数量
        local countText = tostring(result.amount)
        local textWidth = getTextManager():MeasureStringX(UIFont.Small, countText)
        local textX = frameX + frameSize - textWidth - 3
        local textY = frameY + frameSize - LINE_HEIGHT
        
        -- 绘制数量文本
        self:drawText(countText, textX, textY, 1, 1, 1, 1, UIFont.Small)
    end
end

-- 截断文本
function ShortcutRecipeTooltip:truncateText(text, font, maxWidth)
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

function ShortcutRecipeTooltip:calculateLayout()
    if not self.recipe then 
        self:setWidth(200)
        self:setHeight(100)
        return 
    end
    
    local PADDING = 5
    local TEXT_INDENT = 15
    local DIVIDER_HEIGHT = 1
    local LINE_HEIGHT = getTextManager():getFontHeight(UIFont.Small)
    local TITLE_HEIGHT = getTextManager():getFontHeight(UIFont.Medium)
    
    -- 设置图标大小和框大小
    self.conditionIconSize = LINE_HEIGHT
    self.itemIconSize = 32
    self.frameSize = 48
    
    -- 模块1高度: 图标/名称/时间
    local iconSize = TITLE_HEIGHT * 2
    local module1Height = PADDING + math.max(iconSize, TITLE_HEIGHT + LINE_HEIGHT + 2) + PADDING
    
    -- 计算最大宽度
    local requiredWidth = 320
    
    -- 计算名称宽度
    local maxNameWidth = 220
    local truncatedName = self:truncateText(self.recipeName, UIFont.Medium, maxNameWidth)
    local nameWidth = getTextManager():MeasureStringX(UIFont.Medium, truncatedName) + iconSize + PADDING * 3
    requiredWidth = math.max(requiredWidth, nameWidth)
    
    -- 技能文本宽度
    for _, skill in ipairs(self.skills) do
        local textWidth = getTextManager():MeasureStringX(UIFont.Small, "- " .. skill.label .. " (" .. skill.value .. ")") + PADDING * 3
        requiredWidth = math.max(requiredWidth, textWidth)
    end
    
    local currentY = module1Height + DIVIDER_HEIGHT
    
    local module2Height = 0
    
    -- 技能标题和列表
    if #self.skills > 0 then
        module2Height = module2Height + (#self.skills * LINE_HEIGHT)
    end
    
    currentY = currentY + module2Height + DIVIDER_HEIGHT
    
    -- 模块3高度: 新的材料和产出布局
    local module3Height = 0
    
    -- 计算材料和产出显示需要的行数
    local maxItemsPerColumn = math.max(#self.materials, #self.results)
    local maxIconsPerRow = 3
    local rowsNeeded = math.ceil(maxItemsPerColumn / maxIconsPerRow)
    
    -- 材料和产出标题
    module3Height = module3Height + LINE_HEIGHT
    
    -- 物品图标区域 - 现在使用框的高度
    local rowHeight = self.frameSize + PADDING
    module3Height = module3Height + (rowsNeeded * rowHeight) + PADDING
    
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
-- 位置调整相关方法
-- ------------------------------------------------------ --
-- 检测两个矩形是否重叠
function ShortcutRecipeTooltip:overlaps(r1, r2)
    return r1.x + r1.width > r2.x and r1.x < r2.x + r2.width and
           r1.y + r1.height > r2.y and r1.y < r2.y + r2.height
end

-- 将提示框放在目标左侧
function ShortcutRecipeTooltip:placeLeft(r1, r2)
    local r = {}
    for k,v in pairs(r1) do r[k] = v end
    r.x = math.max(0, r2.x - r.width - 8)
    return r
end

-- 将提示框放在目标右侧
function ShortcutRecipeTooltip:placeRight(r1, r2)
    local r = {}
    for k,v in pairs(r1) do r[k] = v end
    r.x = r2.x + r2.width + 8
    r.x = math.min(r.x, getCore():getScreenWidth() - r.width)
    return r
end

-- 将提示框放在目标上方
function ShortcutRecipeTooltip:placeAbove(r1, r2)
    local r = {}
    for k,v in pairs(r1) do r[k] = v end
    r.y = r2.y - r.height - 8
    r.y = math.max(0, r.y)
    return r
end

-- ------------------------------------------------------ --
-- 渲染方法
-- ------------------------------------------------------ --
function ShortcutRecipeTooltip:prerender()
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



function ShortcutRecipeTooltip:render()
    if not self.owner or not self.owner.recipe or not self.layout then return end
    
    local recipe = self.owner.recipe
    local canCraft = self.owner.isCraftable

    local player = getSpecificPlayer(0)
    if player then
        self:loadConditionIcons(recipe, player)
    end
    
    -- 绘制边框和背景
    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)

    -- 获取布局参数
    local PADDING = self.layout.padding
    local LINE_HEIGHT = self.layout.lineHeight
    local TITLE_HEIGHT = self.layout.titleHeight
    local INDENT = self.layout.indentation
    
    -- ========== 模块1: 图标、名称和时间 ==========
    -- 绘制图标
    local iconSize = TITLE_HEIGHT * 2
    local iconY = PADDING
    local iconX = PADDING
    
    local iconTexture = self.owner:getRecipeIcon() or self.iconTexture
    if iconTexture then
        self:drawTextureScaledAspect(iconTexture, iconX, iconY, iconSize, iconSize, 1, 1, 1, 1)
    end
    
    -- 绘制名称
    local nameX = iconX + iconSize + PADDING
    local nameY = iconY
    local maxNameWidth = 220
    local recipeName = (recipe and recipe:getTranslationName()) or self.recipeName or self.owner.recipeName
    local displayName = self:truncateText(recipeName, UIFont.Medium, maxNameWidth)
    
    -- 根据是否可制作设置颜色
    local textColor = canCraft and {r=1, g=1, b=1} or {r=1, g=0.5, b=0.5}
    self:drawText(displayName, nameX, nameY, textColor.r, textColor.g, textColor.b, 1, UIFont.Medium)
    
    -- 计算条件图标和时间图标的位置
    local iconSpacing = 5
    local timeY = nameY + TITLE_HEIGHT + 2
    local clockIcon = getTexture("media/ui/craftingMenus/BuildProperty_Clock.png")
    local clockSize = LINE_HEIGHT
    
    local conditionX = nameX
    
    -- 绘制条件图标
    for i = 1, #self.conditionIcons do
        local icon = self.conditionIcons[i]
        if icon.texture then
            -- 绘制图标
            self:drawTextureScaledAspect(icon.texture, conditionX, timeY, self.conditionIconSize, self.conditionIconSize, 
                                        1,icon.color.r, icon.color.g, icon.color.b)
            
            conditionX = conditionX + self.conditionIconSize + iconSpacing
        end
    end
    
    -- 绘制时钟图标
    if clockIcon then
        self:drawTextureScaledAspect(clockIcon, conditionX, timeY, clockSize, clockSize, 1, 1, 1, 1)

        local gameTime = recipe:getTime(player)
        local realTimeSeconds = gameTime / 10 -- 游戏时间到真实秒数的转换
        
        -- 如果大于60秒，显示为分:秒
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
        
        self:drawText(timeText, conditionX + clockSize + 5, timeY, 0.8, 0.8, 0.8, 1, UIFont.Small)
    end
    
    
    -- ========== 模块2: 只保留技能列表 ==========
    local currentY = self.layout.module2.y
    
    -- 技能列表
    if #self.skills > 0 then
        for _, skill in ipairs(self.skills) do
            local text = "- " .. skill.label
            self:drawText(text, PADDING + INDENT, currentY, skill.color.r, skill.color.g, skill.color.b, 1, UIFont.Small)
            currentY = currentY + LINE_HEIGHT
        end
    end
    
    -- 绘制模块2分隔线
    self:drawRect(PADDING, self.layout.divider2, self.width - PADDING * 2, 1, 0.8, 0.6, 0.6, 0.6)
    
    -- ========== 模块3: 材料和产出 ==========
    self:renderMaterialsAndResults()
end

-- ------------------------------------------------------ --
-- 构造函数
-- ------------------------------------------------------ --
function ShortcutRecipeTooltip:new(recipe, craftLogic)
    local o = ISPanel:new(0, 0, 1, 1)
    setmetatable(o, self)
    self.__index = self
    
    -- 更新全局引用
    if ActiveRecipeTooltip and ActiveRecipeTooltip:isVisible() then
        ActiveRecipeTooltip:removeFromUIManager()
    end
    ActiveRecipeTooltip = o
    
    o.backgroundColor = {r=0.0, g=0.0, b=0.0, a=0.3}
    o.borderColor = {r=0.4, g=0.4, b=0.4, a=0.7}
    o.followMouse = true
    
    -- 初始化数据结构
    o.conditions = {}
    o.skills = {}
    o.materials = {}
    o.tools = {}
    o.results = {}
    o.conditionIcons = {}
    
    if recipe then
        o:setRecipe(recipe) 
    end
    
    return o
end

return ShortcutRecipeTooltip