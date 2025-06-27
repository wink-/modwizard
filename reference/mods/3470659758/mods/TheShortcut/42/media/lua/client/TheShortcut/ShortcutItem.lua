ShortcutItem = {}
ShortcutItem.lastPlayerWeight = -1
ShortcutItem.itemsCache = nil
ShortcutItem.actionCompletedFlag = false

-- ------------------------------------------------------ --
--  检测并获取物品数据（只包含自身库存物品）
-- ------------------------------------------------------ --

-- 检测自身物品是否有变化
ShortcutItem.hasInventoryChanged = function()
    local player = getSpecificPlayer(0)
    if not player then return false end
    
    -- 获取当前玩家负重
    local currentWeight = player:getInventoryWeight()
    
    -- 检查负重是否与上次不同
    local hasChanged = (math.abs(currentWeight - ShortcutItem.lastPlayerWeight) > 0.0001)
    
    -- 检查是否有动作刚刚完成
    local actionCompleted = ShortcutItem.actionCompletedFlag
    if actionCompleted then
        -- 重置标记，避免多次触发
        ShortcutItem.actionCompletedFlag = false
    end
    
    -- 如果负重变化或有动作刚完成，都需要更新
    local needsUpdate = hasChanged or actionCompleted
    
    -- 更新记录的负重，并在需要更新时清除缓存
    if needsUpdate then
        ShortcutItem.lastPlayerWeight = currentWeight
        ShortcutItem.itemsCache = nil
    end
    
    return needsUpdate
end

local original_onCompleted = ISTimedActionQueue.onCompleted
ISTimedActionQueue.onCompleted = function(self, action)
    original_onCompleted(self, action)
    
    -- 设置动作完成标记
    ShortcutItem.actionCompletedFlag = true
end


-- 获取自身库存物品
ShortcutItem.getSelfItems = function()
    if ShortcutItem.itemsCache then
        return ShortcutItem.itemsCache
    end
    
    local player = getSpecificPlayer(0)
    if not player or player:isDead() then return nil end
    
    local allContainers = ArrayList.new()
    
    local playerInv = getPlayerInventory(player:getPlayerNum())
    if playerInv then
        allContainers = ISInventoryPaneContextMenu.getContainers(player)
    end
    
    -- 筛选出只属于玩家的容器
    local playerContainers = ArrayList.new()
    for i=0, allContainers:size()-1 do
        local container = allContainers:get(i)
        if container:isInCharacterInventory(player) then
            playerContainers:add(container)
        end
    end
    
    local allItems = ArrayList.new()
    allItems = CraftRecipeManager.getAllItemsFromContainers(playerContainers, allItems)
    print("Self items count: " .. allItems:size())
    ShortcutItem.itemsCache = allItems
    
    return allItems
end

-- ------------------------------------------------------ --
-- 物品数据获取方法
-- ------------------------------------------------------ --
ShortcutItem.getSelfItemData = function(itemType)
    if not itemType then return nil end
    
    -- 确保有物品缓存
    if not ShortcutItem.itemsCache then
        ShortcutItem.getSelfItems()
    end
    
    if not ShortcutItem.itemsCache then return nil end
    
    local count = 0
    local bestItem = nil
    local bestScore = -1  -- 分数越高越优先显示
    
    -- 从缓存中查找物品
    for i=0, ShortcutItem.itemsCache:size()-1 do
        local item = ShortcutItem.itemsCache:get(i)
        if item:getFullType() == itemType then
            count = count + 1
            
            -- 使用ShortcutItemState获取物品优先级分数
            local score = ShortcutItemState.getItemPriorityScore(item)
            
            -- 如果是第一个物品或者得分比之前找到的物品更高，则更新
            if not bestItem or score > bestScore then
                bestItem = item
                bestScore = score
            end
        end
    end
    
    if bestItem then
        return {
            item = bestItem,
            count = count
        }
    end
    
    -- 如果找不到真实物品，尝试创建虚拟物品
    local virtualItem = ShortcutItem.createVirtualItem(itemType)
    if virtualItem then
        return {
            item = virtualItem,
            count = 0
        }
    end
    
    return nil
end

-- ------------------------------------------------------ --
-- 创建物品的虚拟实例（用于显示）
-- ------------------------------------------------------ --
ShortcutItem.createVirtualItem = function(itemType)
    if not itemType then return nil end
    
    local itemScript = getScriptManager():getItem(itemType)
    if not itemScript then return nil end
    
    local virtualItem = itemScript:InstanceItem(nil)
    return virtualItem
end

return ShortcutItem