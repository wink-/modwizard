ShortcutItemAction = {}

-- ------------------------------------------------------ --
-- 主处理函数
-- ------------------------------------------------------ --
function ShortcutItemAction.handleDoubleClick(item)
    if not item then return false end
    
    -- 获取玩家对象
    local player = getSpecificPlayer(0)
    if not player then return false end
    
    -- 检查物品是否在玩家库存中
    if not (item:getContainer() and item:getContainer():isInCharacterInventory(player)) then
        return false
    end
    if ShortcutItemAction.isPlaceableMoveableItem(item) then
        return ShortcutItemAction.handleMoveable(player, item)
    elseif ShortcutItemAction.isWaterContainer(item) then
        return ShortcutItemAction.handleWaterContainer(player, item)
    elseif instanceof(item, "HandWeapon") then
        return ShortcutItemAction.handleWeapon(player, item)
    elseif ShortcutItemAction.isSmokeItem(item) then
        return ShortcutItemAction.handleSmoke(player, item)
    elseif instanceof(item, "Food") then
        return ShortcutItemAction.handleFood(player, item)
    elseif ShortcutItemAction.isMedical(item) then
        return ShortcutItemAction.handleMedical(player, item)
    elseif instanceof(item, "Clothing") then
        return ShortcutItemAction.handleClothing(player, item)
    elseif ShortcutItemAction.isBook(item) then
        return ShortcutItemAction.handleBook(player, item)
    end
    return false
end

-- ------------------------------------------------------ --
-- 配方检测与处理
-- ------------------------------------------------------ --

function ShortcutItemAction.handleRecipe(player, item)
    local containerList = ISInventoryPaneContextMenu.getContainers(player)
    local recipeList = CraftRecipeManager.getUniqueRecipeItems(item, player, containerList)

    if not recipeList or recipeList:size() == 0 then return false end
    
    -- 查找烹饪类型的配方
    for i = 0, recipeList:size() - 1 do
        local recipe = recipeList:get(i)
        
        -- 检查配方是否为烹饪类型
        if recipe:getCategory() == "Cooking"or"Miscellaneous" then
            local craftLogic = HandcraftLogic.new(player, nil, nil)
            craftLogic:setContainers(containerList)
            craftLogic:setRecipe(recipe)
            
            if craftLogic:canPerformCurrentRecipe() then
                ISTimedActionQueue.add(ISHandcraftAction.FromLogic(craftLogic))
                return true
            end
            break
        end
    end
    
    return false
end
-- ------------------------------------------------------ --
-- 武器处理函数
-- ------------------------------------------------------ --
function ShortcutItemAction.handleWeapon(player, item)
    if player:isHandItem(item) then
        -- 武器已装备，则卸下
        ISInventoryPaneContextMenu.unequipItem(item, 0)
    elseif item:getCondition() > 0 then
        -- 武器未装备，则装备
        ISInventoryPaneContextMenu.equipWeapon(item, true, item:isTwoHandWeapon(), 0)
    end
    
    return true
end

-- ------------------------------------------------------ --
-- 衣物处理函数
-- ------------------------------------------------------ --
function ShortcutItemAction.handleClothing(player, item)
    if player:isEquipped(item) then
        -- 衣物已装备，则脱下
        ISInventoryPaneContextMenu.onUnEquip({item}, player:getPlayerNum())
    else
        -- 衣物未装备，则穿上
        ISInventoryPaneContextMenu.onWearItems({item}, player:getPlayerNum())
    end
    
    return true
end

-- ------------------------------------------------------ --
-- 食品处理函数
-- ------------------------------------------------------ --
function ShortcutItemAction.handleFood(player, item)

    if not ShortcutItemAction.evalFoodItem(item) then
        return false
    end

    if item:getTooltip() == "Tooltip_item_CanOpener" then
        return ShortcutItemAction.handleRecipe(player, item)
    end

    if player:getMoodles():getMoodleLevel(MoodleType.FoodEaten) >= 3 then
        return false
    end

    local hunger = player:getStats():getHunger()
    local hungerChange = item:getHungerChange()
    local hungerReduction = math.abs(hungerChange)
    
    local eatRatio = 1

    if hungerReduction > 0 then
        eatRatio = hunger / hungerReduction
        if eatRatio > 1 then
            eatRatio = 1
        elseif eatRatio < 0.1 then
            eatRatio = 0.1
        end
    end

    ISInventoryPaneContextMenu.onEatItems({item}, eatRatio, 0)
    return true
end

-- 食物评估函数
function ShortcutItemAction.evalFoodItem(item)
    -- 检查是否是需要先打开的罐头
    if item:getTooltip() == "Tooltip_item_CanOpener" then
        return true
    end
    
    -- 食品评估逻辑
    if not item:IsFood() then return false end
    local scriptItem = item:getScriptItem()
    if scriptItem:isCantEat() then return false end
    if item:getHungerChange() >= 0 then return false end
    -- if item:isAlcoholic() then return false end
    if item:isSpice() then return false end
    if item:isTainted() then return false end
    if item:isRotten() then return false end
    if item:isCookable() and item:isbDangerousUncooked() and not item:isCooked() then return false end
    if item:isFrozen() then return false end
    if item:isBurnt() then return false end
    if item:isPoison() or item:getPoisonPower() > 0 then return false end
    return true
end

-- ------------------------------------------------------ --
-- 医疗物品处理函数
-- ------------------------------------------------------ --
function ShortcutItemAction.isMedical(item)
    if item:hasTag("Pills") then
        return true
    end
    return false
end

-- 医疗物品处理函数
function ShortcutItemAction.handleMedical(player, item)
    ISInventoryPaneContextMenu.onPillsItems({item}, player:getPlayerNum())
end
-- ------------------------------------------------------ --
-- 抽烟处理
-- ------------------------------------------------------ --
function ShortcutItemAction.isSmokeItem(item)
    -- 小浣熊到底怎么处理嚼烟，answer me
    --if item:getFullType() == "Base.TobaccoChewing" then
    --    return true
    --end
    -- 添加对一盒烟的判断
    if item:getFullType() == "Base.CigarettePack" then
        return true
    end
    return item:getCustomMenuOption() and item:getCustomMenuOption() == getText("ContextMenu_Smoke")
end

-- 抽烟处理函数
function ShortcutItemAction.handleSmoke(player, item)
    -- 添加对一盒烟的特殊处理
    if item:getFullType() == "Base.CigarettePack" then
        return ShortcutItemAction.handleRecipe(player, item)
    end

    local hasSource = false
    if player:getVehicle() and player:getVehicle():canLightSmoke(player) then
        hasSource = true
    end
    if not hasSource then
        hasSource = ISInventoryPaneContextMenu.hasOpenFlame(player)
        if not hasSource then
            local inventory = player:getInventory()
            hasSource = inventory:containsTypeRecurse("Matches") or
                        inventory:containsTypeRecurse("Lighter") or
                        inventory:containsTypeRecurse("LighterDisposable") or
                        inventory:containsTypeRecurse("LighterBBQ") or
                        inventory:containsTagRecurse("StartFire")
        end
    end
    
    if not hasSource then
        return false
    end
    ISInventoryPaneContextMenu.onEatItems({item}, 1, player:getPlayerNum())
    return true
end

-- ------------------------------------------------------ --
-- 水容器处理
-- ------------------------------------------------------ --
function ShortcutItemAction.isWaterContainer(item)
    if not item:getFluidContainer() then return false end
    local fluidContainer = item:getFluidContainer()
    -- 密封饮料罐特殊处理
    if (item:hasTag("SealedBeverageCan") or item:hasTag("GlassBottle")) and not fluidContainer:canPlayerEmpty() then
        return true
    end
    -- 是普通水容器的检查条件
    if fluidContainer:isEmpty() then return false end
    if not fluidContainer:canPlayerEmpty() then return false end
    if fluidContainer:isPoisonous() then return false end
    if fluidContainer:getCapacity() > 3.0 then return false end
    if fluidContainer:getAmount() <= 0 then return false end
    return true
end

-- 处理水容器双击
function ShortcutItemAction.handleWaterContainer(player, item)
    local fluidContainer = item:getFluidContainer()
    
    -- 检查是否是需要先打开的密封饮料罐
    if (item:hasTag("SealedBeverageCan") or item:hasTag("GlassBottle")) and not fluidContainer:canPlayerEmpty() then
        return ShortcutItemAction.handleRecipe(player, item)
    end
    
    -- 处理正常可饮用的水容器
    local thirst = player:getStats():getThirst()
    local amountThirst = math.abs(fluidContainer:getProperties():getThirstChange())
    local drinkRatio = 1 
    
    if amountThirst > 0 then
        local ratioForThirst = thirst/amountThirst
        if ratioForThirst < 1 then
            drinkRatio = ratioForThirst
        end
    end
    
    local baseThirst = fluidContainer:getAmount()/fluidContainer:getCapacity()
    if drinkRatio == 1 and baseThirst >= 0.5 then
        if thirst < 0.3 then
            drinkRatio = 0.5
        elseif thirst < 0.15 and baseThirst >= 0.25 then
            drinkRatio = 0.25
        end
    end
    
    ISInventoryPaneContextMenu.onDrinkFluid(item, drinkRatio, player)
    return true
end

-- ------------------------------------------------------ --
-- 书籍处理
-- ------------------------------------------------------ --
function ShortcutItemAction.isBook(item)
    -- 通过右键菜单选项判断
    local menuOption = item:getCustomMenuOption()
    if menuOption and (menuOption == getText("ContextMenu_Read") or 
                       menuOption == getText("ContextMenu_Read_Note") or
                       menuOption == getText("ContextMenu_Look_at_picture") or 
                       menuOption == getText("ContextMenu_Look_at_pictures")) then
        return true
    end
    
    -- 检查是否为地图或文学类物品
    if item:IsMap() or item:getCategory() == "Literature" then
        return true
    end
    
    return false
end

function ShortcutItemAction.handleBook(player, item)
    -- 检查玩家状态
    if player:isAsleep() then
        return false
    end
    
    -- 文盲检查
    if player:getTraits():isIlliterate() and not (item:hasTag("Picturebook") or item:hasTag("Picture")) then return false end
    -- 光照检查
    if player:tooDarkToRead() then return false end
    -- 检查是否无趣的物品
    if item:hasTag("Uninteresting") then return false end
    
    -- 对于技能书的等级检查
    if item:getLvlSkillTrained() ~= -1 and 
       SkillBook[item:getSkillTrained()] and 
       SkillBook[item:getSkillTrained()].perk and
       item:getLvlSkillTrained() > player:getPerkLevel(SkillBook[item:getSkillTrained()].perk) + 1 then
        return false
    end
    
    -- 如果是地图，使用查看地图功能
    if item:IsMap() then
        if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.onCheckMap then
            ISInventoryPaneContextMenu.onCheckMap(item, player:getPlayerNum())
            return true
        end
    end
    
    -- 使用现有的阅读功能
    if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.readItem then
        ISInventoryPaneContextMenu.readItem(item, player:getPlayerNum())
        return true
    end
    
    return true
end

-- ------------------------------------------------------ --
-- 可移动物品处理
-- ------------------------------------------------------ --
function ShortcutItemAction.isPlaceableMoveableItem(item)
    if not item then return false end
    
    -- 检查是否是可移动物品并且不能直接放在地面上
    return instanceof(item, "Moveable") and 
           item:getSpriteGrid() == nil and 
           not item:CanBeDroppedOnFloor()
end

function ShortcutItemAction.handleMoveable(player, item)
    if not ShortcutItemAction.isPlaceableMoveableItem(item) then
        return false
    end
    
    -- 如果物品不在玩家库存中，则无法放置
    if not (item:getContainer() and item:getContainer():isInCharacterInventory(player)) then
        return false
    end
    
    -- 创建可移动物品放置光标，与ISInventoryPane中的处理方式相同
    local mo = ISMoveableCursor:new(player)
    getCell():setDrag(mo, mo.player)
    mo:setMoveableMode("place")
    mo:tryInitialItem(item)
    
    return true
end

return ShortcutItemAction