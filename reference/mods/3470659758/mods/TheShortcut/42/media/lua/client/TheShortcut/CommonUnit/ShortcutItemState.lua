require "TSLiquidColors"

ShortcutItemState = {}
ShortcutItemState.lastItemStates = {}

ShortcutItemState.StatusBarTextures = {
    Fill_Left = getTexture("media/ui/TheShortCut/StatusBar_Fill_Left.png"),
    Fill_Middle = getTexture("media/ui/TheShortCut/StatusBar_Fill_Middle.png"),
    Fill_Right = getTexture("media/ui/TheShortCut/StatusBar_Fill_Right.png"),
    
    Background_Left = getTexture("media/ui/TheShortCut/StatusBar_BG_Left.png"),
    Background_Middle = getTexture("media/ui/TheShortCut/StatusBar_BG_Middle.png"),
    Background_Right = getTexture("media/ui/TheShortCut/StatusBar_BG_Right.png")
}

-- ----------------------------------------- --
-- 获取颜色根据比率
-- ----------------------------------------- --
function ShortcutItemState.getColorByRatio(ratio)
    -- 默认颜色
    local r, g, b, a = 0.2, 0.8, 0.2, 0.7
    
    -- 根据比率设置颜色
    if ratio > 2/3 then
        r, g, b, a = 0.4, 0.85, 0.4, 0.6  -- 明亮柔和绿，像抹茶
    elseif ratio > 1/3 then
        r, g, b, a = 1.0, 0.72, 0.2, 0.75  -- 鲜亮奶黄橘，像芒果奶昔
    else
        r, g, b, a = 0.95, 0.35, 0.35, 0.9  -- 鲜明但柔和的砖红，像草莓奶油
    end
    
    return r, g, b, a
end

-- ----------------------------------------- --
-- 获取物品状态信息
-- ----------------------------------------- --
function ShortcutItemState.getItemStateInfo(item)
    if not item then return 0, 0.2, 0.8, 0.2, 0.7 end
    
    local ratio = 0
    local r, g, b, a = 0.2, 0.8, 0.2, 0.7
    -- 武器
    if instanceof(item, "HandWeapon") then
        local condition = item:getCondition()
        local maxCondition = item:getConditionMax()

        if condition > 0 and maxCondition > 0 then
            ratio = condition / maxCondition
            r, g, b, a = ShortcutItemState.getColorByRatio(ratio)
        end
    elseif instanceof(item, "Clothing") then
        local condition = item:getCondition()
        local maxCondition = item:getConditionMax()
        
        if condition > 0 and maxCondition > 0 then
            ratio = condition / maxCondition
            r, g, b, a = ShortcutItemState.getColorByRatio(ratio)
        end
    -- 食品
    elseif instanceof(item, "Food") then
        local hungerChange = math.abs(item:getHungerChange())
        local maxHunger = math.abs(item:getBaseHunger())
        if maxHunger > 0 then
            ratio = math.min(hungerChange / maxHunger, 1)
            r, g, b, a = ShortcutItemState.getColorByRatio(ratio)
        end
    -- 可消耗物品
    elseif instanceof(item, "DrainableComboItem") then
        local currentUses = item:getCurrentUsesFloat()
        ratio = math.max(0, math.min(1, currentUses))
        r, g, b, a = ShortcutItemState.getColorByRatio(ratio)
    -- 液体容器
    elseif item.getFluidContainer and item:getFluidContainer() then
        local fluidContainer = item:getFluidContainer()
        
        local amount = fluidContainer:getAmount()
        local capacity = fluidContainer:getCapacity()
        
        if capacity > 0 then
            ratio = amount / capacity
            r, g, b, a = TSLiquidColors:getLiquidColor(fluidContainer)
        end
    end
    
    return ratio, r, g, b, a
end

-- ----------------------------------------- --
-- 检测物品状态是否需要触发更新
-- ----------------------------------------- --
function ShortcutItemState.getItemKeyStates(item)
    if not item then return nil end
    
    local states = {
        -- 通用状态
        ratio = 0,           -- 物品一般状态比率(0-1)
        isBadState = false,  -- 是否处于"坏"状态
        
        -- 武器/衣物
        hasCondition = false,
        condition = 0,
        maxCondition = 0,
        conditionRatio = 0,
        isConditionZero = false,
        
        -- 液体容器
        isFluidContainer = false,
        fluidAmount = 0,
        fluidCapacity = 0,
        fluidRatio = 0,
        isFluidEmpty = false,
        
        -- 食品
        isFood = false,
        freshness = -1,
        isLowFreshness = false,
        isRotten = false,
        isFrozen = false,
        
        -- 消耗品
        isDrainable = false,
        currentUses = 0,
        isUsesEmpty = false
    }
    
    -- 获取通用状态比率
    states.ratio, _, _, _, _ = ShortcutItemState.getItemStateInfo(item)
    
    -- 武器
    if instanceof(item, "HandWeapon") then
        states.hasCondition = true
        states.condition = item:getCondition()
        states.maxCondition = item:getConditionMax()
        
        if states.maxCondition > 0 then
            states.conditionRatio = states.condition / states.maxCondition
        end
        
        states.isConditionZero = (states.condition <= 0)
        states.isBadState = states.isConditionZero
    end
    
    -- 衣物
    if instanceof(item, "Clothing") then
        states.hasCondition = true
        states.condition = item:getCondition()
        states.maxCondition = item:getConditionMax()
        
        if states.maxCondition > 0 then
            states.conditionRatio = states.condition / states.maxCondition
        end
        
        states.isConditionZero = (states.condition <= 0)
        states.isBadState = states.isConditionZero
    end
    
    -- 液体容器
    if item:getFluidContainer() then
        states.isFluidContainer = true
        local fluidContainer = item:getFluidContainer()
        states.fluidAmount = fluidContainer:getAmount()
        states.fluidCapacity = fluidContainer:getCapacity()
        
        if states.fluidCapacity > 0 then
            states.fluidRatio = states.fluidAmount / states.fluidCapacity
        end
        
        states.isFluidEmpty = (states.fluidAmount <= 0)
        states.isBadState = states.isBadState or states.isFluidEmpty
    end
    
    -- 食品
    if instanceof(item, "Food") then
        states.isFood = true
        states.freshness = ShortcutItemState.getFoodFreshness(item)
        states.isLowFreshness = (states.freshness > 0 and states.freshness <= 0.01)
        states.isRotten = item:isRotten()
        states.isFrozen = item:isFrozen()
        
        states.isBadState = states.isBadState or states.isLowFreshness or states.isRotten
    end
    
    -- 消耗品
    if instanceof(item, "DrainableComboItem") then
        states.isDrainable = true
        states.currentUses = item:getCurrentUsesFloat()
        states.isUsesEmpty = (states.currentUses <= 0.01)
        
        states.isBadState = states.isBadState or states.isUsesEmpty
    end
    
    return states
end

-- 检查所有已显示物品的状态变化
function ShortcutItemState.checkAllItemsState(slots)
    if not slots then return false end
    
    local needUpdate = false
    for _, slot in ipairs(slots) do
        if slot.item and slot.itemType and slot.itemCount > 0 then
            if ShortcutItemState.shouldUpdateItem(slot.item, slot.itemType) then
                needUpdate = true
                break
            end
        end
    end
    
    return needUpdate
end

-- ----------------------------------------- --
-- 获取物品优先级分数
-- ----------------------------------------- --
function ShortcutItemState.getItemPriorityScore(item)
    if not item then return -999 end
    
    local states = ShortcutItemState.getItemKeyStates(item)
    
    -- 默认分数，基于物品状态
    local score = 100 * (1 - states.ratio)  -- 状态越差，分数越高
    
    -- 武器/衣物的耐久度为0
    if (states.hasCondition and states.isConditionZero) then
        score = score - 200
    end
    
    -- 液体容器为空
    if (states.isFluidContainer and states.isFluidEmpty) then
        score = score - 200
    end
    
    -- 食品新鲜度低或腐烂
    if states.isFood then
        if states.isLowFreshness then
            score = score - 200
        end
        if states.isRotten then
            score = score - 300
        end
    end
    
    -- 消耗品用尽
    if (states.isDrainable and states.isUsesEmpty) then
        score = score - 200
    end
    
    return score
end

-- 检查物品状态是否需要触发更新（修改后）
function ShortcutItemState.shouldUpdateItem(item, itemType)
    if not item or not itemType then return false end
    
    local states = ShortcutItemState.getItemKeyStates(item)
    
    -- 检查是否处于"坏"状态
    local currentBadState = states.isBadState
    
    -- 获取上次记录的状态
    local lastBadState = ShortcutItemState.lastItemStates[itemType]
    
    -- 如果没有上次记录，记录当前状态并返回false
    if lastBadState == nil then
        ShortcutItemState.lastItemStates[itemType] = currentBadState
        return false
    end
    
    -- 检查状态是否从好变坏
    local changed = (lastBadState == false and currentBadState == true)
    
    -- 更新记录的状态
    ShortcutItemState.lastItemStates[itemType] = currentBadState
    
    return changed
end

-- ----------------------------------------- --
-- 获取武器特殊状态
-- ----------------------------------------- --
function ShortcutItemState.hasWeaponSpecialState(item)
    if not item then return false end
    return item:hasHeadCondition() or item:hasSharpness()
end

-- 获取武器头部状态信息
function ShortcutItemState.getHeadConditionInfo(item)
    if not item:hasHeadCondition() then return 0, 0, 0, 0, 0 end
    
    local condition = item:getHeadCondition()
    local maxCondition = item:getConditionMax()
    
    if condition > 0 and maxCondition > 0 then
        local ratio = condition / maxCondition
        local r, g, b, a = 0.6, 0.4, 0.2, 0.8
        return ratio, r, g, b, a
    end
    
    return 0, 0, 0, 0, 0
end

-- 获取武器锋利度信息
function ShortcutItemState.getSharpnessInfo(item)
    if not item:hasSharpness() then return 0, 0 end
    
    local currentSharpness = item:getSharpness()
    local maxSharpness = item:getMaxSharpness()
    
    return currentSharpness, maxSharpness
end

-- ----------------------------------------- --
-- 获取食品特殊状态
-- ----------------------------------------- --
function ShortcutItemState.getFoodFreshness(item)
    if not item or not instanceof(item, "Food") then
        return -1
    end
    
    -- 检查是否为永不过期的食品
    local daysFresh = item:getScriptItem():getDaysFresh()
    local daysRotten = item:getScriptItem():getDaysTotallyRotten()
    
    -- 如果保质期超过10年(3650天),则认为是永不过期
    if daysFresh > 3650 or daysRotten > 3650 then
        return -1  -- 返回-1表示不显示新鲜度条
    end
    
    local age = item:getAge()
    local ageMax = daysFresh + daysRotten
    
    if ageMax <= 0 then return 1 end -- 如果物品没有腐烂时间，则返回1
    
    local freshness = 1 - (age / ageMax)
    return math.max(0, math.min(1, freshness))
end
-- ----------------------------------------- --
-- 渲染特殊物品状态
-- ----------------------------------------- --
function ShortcutItemState.renderItemSpecialStates(panel, item, slotX, slotY, slotWidth, slotHeight)
    if not item then return end
    
    -- 状态条高度（槽位高度的1/6）
    local barHeight = math.floor(slotHeight / 6)
    local topMargin = slotHeight/24
    
    -- 状态条Y坐标
    local barY = slotY - topMargin - barHeight
    
    -- 武器特殊状态处理
    if instanceof(item, "HandWeapon") then
        -- 检查武器特殊状态
        local hasSharpness = item:hasSharpness()
        local hasHeadCondition = item:hasHeadCondition()
        
        -- 如果没有特殊状态，直接返回
        if not hasSharpness and not hasHeadCondition then return end
        
        -- 优先显示锋利度
        if hasSharpness then
            local currentSharpness, maxSharpness = ShortcutItemState.getSharpnessInfo(item)
            
            -- 绘制状态条背景 - 使用三段式贴图
            ShortcutUIHelper.drawThreeSlice(
                panel, 
                slotX, barY, slotWidth, barHeight,
                ShortcutItemState.StatusBarTextures.Background_Left,
                ShortcutItemState.StatusBarTextures.Background_Middle,
                ShortcutItemState.StatusBarTextures.Background_Right,
                0.8, 0.4, 0.4, 0.4
            )
            
            -- 绘制最大锋利度填充 - 使用三段式贴图
            local maxFillWidth = slotWidth * maxSharpness
            if maxFillWidth > 0 then
                ShortcutUIHelper.drawThreeSlice(
                    panel, 
                    slotX, barY, maxFillWidth, barHeight,
                    ShortcutItemState.StatusBarTextures.Fill_Left,
                    ShortcutItemState.StatusBarTextures.Fill_Middle,
                    ShortcutItemState.StatusBarTextures.Fill_Right,
                    0.4, 0.85, 0.2, 0.2
                )
            end
            
            -- 绘制当前锋利度填充 - 使用三段式贴图
            local currentFillWidth = slotWidth * currentSharpness
            if currentFillWidth > 0 then
                ShortcutUIHelper.drawThreeSlice(
                    panel, 
                    slotX, barY, currentFillWidth, barHeight,
                    ShortcutItemState.StatusBarTextures.Fill_Left,
                    ShortcutItemState.StatusBarTextures.Fill_Middle,
                    ShortcutItemState.StatusBarTextures.Fill_Right,
                    0.9, 0.8, 0.8, 0.8
                )
            end
        
        -- 如果没有锋利度，但有头部状态，则绘制头部状态条
        elseif hasHeadCondition then
            local ratio, r, g, b, a = ShortcutItemState.getHeadConditionInfo(item)
            
            -- 绘制状态条背景 - 使用三段式贴图
            ShortcutUIHelper.drawThreeSlice(
                panel, 
                slotX, barY, slotWidth, barHeight,
                ShortcutItemState.StatusBarTextures.Background_Left,
                ShortcutItemState.StatusBarTextures.Background_Middle,
                ShortcutItemState.StatusBarTextures.Background_Right,
                0.6, 0.4, 0.4, 0.4
            )
            
            -- 绘制状态条填充 - 使用三段式贴图
            local fillWidth = slotWidth * ratio
            if fillWidth > 0 then
                ShortcutUIHelper.drawThreeSlice(
                    panel, 
                    slotX, barY, fillWidth, barHeight,
                    ShortcutItemState.StatusBarTextures.Fill_Left,
                    ShortcutItemState.StatusBarTextures.Fill_Middle,
                    ShortcutItemState.StatusBarTextures.Fill_Right,
                    a, r, g, b
                )
            end
        end
    -- 食品新鲜度和冷冻状态处理
    elseif instanceof(item, "Food") then
        -- 获取食品新鲜度
        local freshness = ShortcutItemState.getFoodFreshness(item)
        
        -- 如果是永不过期的食品，不显示新鲜度条
        if freshness < 0 then return end
        
        -- 绘制状态条背景 - 使用三段式贴图
        ShortcutUIHelper.drawThreeSlice(
            panel, 
            slotX, barY, slotWidth, barHeight,
            ShortcutItemState.StatusBarTextures.Background_Left,
            ShortcutItemState.StatusBarTextures.Background_Middle,
            ShortcutItemState.StatusBarTextures.Background_Right,
            0.6, 0.4, 0.4, 0.4
        )
        
        -- 根据新鲜度和冷冻状态选择颜色
        local r, g, b, a
        
        if item:isFrozen() then
            -- 冷冻状态 - 蓝色
            r, g, b, a = 0.3, 0.7, 0.9, 0.7
        else
            -- 根据新鲜度设置颜色
            if freshness > 0.7 then
                -- 新鲜 - 绿色
                r, g, b, a = 0.3, 0.7, 0.3, 0.7
            elseif freshness > 0.3 then
                -- 中等新鲜度 - 黄色
                r, g, b, a = 0.9, 0.8, 0.3, 0.7
            else
                -- 接近腐烂 - 红色
                r, g, b, a = 0.8, 0.3, 0.3, 0.7
            end
        end
        
        -- 绘制新鲜度条填充 - 使用三段式贴图
        local fillWidth = slotWidth * freshness
        if fillWidth > 0 then
            ShortcutUIHelper.drawThreeSlice(
                panel, 
                slotX, barY, fillWidth, barHeight,
                ShortcutItemState.StatusBarTextures.Fill_Left,
                ShortcutItemState.StatusBarTextures.Fill_Middle,
                ShortcutItemState.StatusBarTextures.Fill_Right,
                a, r, g, b
            )
        end
    end
end


return ShortcutItemState