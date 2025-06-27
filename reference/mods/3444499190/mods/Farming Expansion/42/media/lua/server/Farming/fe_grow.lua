-- Сначала убедимся, что оригинальная таблица farming_vegetableconf существует
if not farming_vegetableconf then farming_vegetableconf = {} end

-- Переопределяем функцию grow
local originalGrowFunction = farming_vegetableconf.grow

farming_vegetableconf.grow = function(planting, nextGrowing, updateNbOfGrow)
    if not planting then return end
    
    local nbOfGrow = planting.nbOfGrow
    local water = farming_vegetableconf.calcWater(planting.waterNeeded, planting.waterLvl)
    local waterMax = farming_vegetableconf.calcWater(planting.waterLvl, planting.waterNeededMax)
    local diseaseLvl = farming_vegetableconf.calcDisease(planting.mildewLvl)
    local prop = farming_vegetableconf.props[planting.typeOfSeed]
    local name = farming_vegetableconf.getObjectName(planting)

    if planting.fertilizer >= 1 then
        planting.fertilizer = planting.fertilizer - 1
    end
    planting.compost = false
    local cheat = getCore():getDebug() and getDebugOptions():getBoolean("Cheat.Farming.FastGrow")

    if planting.typeOfSeed == "AppleTree" or planting.typeOfSeed == "GrapeSeed" or planting.typeOfSeed == "CherryTree" then
        local season = getClimateManager():getSeasonName()
        if season == "Winter" then
            planting.nextGrowing = calcNextGrowing(nextGrowing, 24) -- Задержка на 24 часа
            -- Если зима, не прогрессируем в стадии роста, не меняем текстуру и не изменяем nbOfGrow
            return planting
        end
    end

    if (nbOfGrow > prop.fullGrown) then -- rotten
        planting:rottenThis()
    elseif (nbOfGrow == prop.fullGrown) then -- mature with seed
		if(water >= 0 and waterMax >= 0 and diseaseLvl >= 0) then
		    local rotTime = prop.rotTime or math.floor(prop.timeToGrow/2)
			planting.nextGrowing = calcNextGrowing(nextGrowing, rotTime);
			planting:setObjectName(name)
-- 			planting.hasVegetable = true;
			planting.hasSeed = true;
		else
			badPlant(water, waterMax, diseaseLvl, planting, nextGrowing, updateNbOfGrow);
		end
    elseif (nbOfGrow == prop.mature) then -- mature
        if water >= 0 and waterMax >= 0 and diseaseLvl >= 0 then
            if cheat then
                planting.nextGrowing = calcNextGrowing(nextGrowing, 1)
            else
                planting.nextGrowing = calcNextGrowing(nextGrowing, prop.timeToGrow + water + waterMax + diseaseLvl)
            end
        else
            badPlant(water, waterMax, diseaseLvl, planting, nextGrowing, updateNbOfGrow)
        end
    elseif (nbOfGrow > 0) then -- young
        if water >= 0 and waterMax >= 0 and diseaseLvl >= 0 then
            if cheat then
                planting = growNext(planting, farming_vegetableconf.getObjectName(planting), nextGrowing, 1)
            else
                planting = growNext(planting, farming_vegetableconf.getObjectName(planting), nextGrowing, prop.timeToGrow + water + waterMax + diseaseLvl)
            end
            planting.waterNeeded = prop.waterLvl
            if prop.waterLvlMax then
                planting.waterNeededMax = prop.waterLvlMax
            end
        else
            badPlant(water, waterMax, diseaseLvl, planting, nextGrowing, updateNbOfGrow)
        end
    elseif nbOfGrow == 0 then -- young
        if cheat then
            planting = growNext(planting, farming_vegetableconf.getObjectName(planting), nextGrowing, 1)
        else
            planting = growNext(planting, farming_vegetableconf.getObjectName(planting), nextGrowing, prop.timeToGrow + water + waterMax + diseaseLvl)
        end
        planting.waterNeeded = prop.waterNeeded
    end
    if planting:isAlive() then
        if (prop.harvestLevel and nbOfGrow >= prop.harvestLevel)
         or (not prop.harvestLevel and nbOfGrow >= prop.harvestLeve) then
            planting:setObjectName(name)
            planting.hasVegetable = true
        end
    end
    return planting
end

local originalGrowPlantFunction = SFarmingSystem.growPlant

SFarmingSystem.growPlant = function(self, luaObject, nextGrowing, updateNbOfGrow)
    if luaObject.state == "seeded" then
        luaObject = farming_vegetableconf.grow(luaObject, nextGrowing, updateNbOfGrow)
        -- maybe this plant gonna be disease
        if luaObject.nbOfGrow > 0 then
            self:diseaseThis(luaObject)
        end
        -- Проверка на тип растения и сезон
        if luaObject.typeOfSeed == "AppleTree" then
            local season = getClimateManager():getSeasonName()
            if season ~= "Winter" and luaObject.nbOfGrow ~= 7 then
                luaObject.nbOfGrow = luaObject.nbOfGrow + 1
            elseif season == "Winter" and luaObject.nbOfGrow == 0 then
                luaObject.nbOfGrow = luaObject.nbOfGrow + 1           
            end
        elseif luaObject.typeOfSeed == "GrapeSeed" then
            local season = getClimateManager():getSeasonName()
            if season ~= "Winter" and luaObject.nbOfGrow ~= 7 then
                luaObject.nbOfGrow = luaObject.nbOfGrow + 1
            elseif season == "Winter" and luaObject.nbOfGrow == 0 then
                luaObject.nbOfGrow = luaObject.nbOfGrow + 1           
            end
        elseif luaObject.typeOfSeed == "CherryTree" then
            local season = getClimateManager():getSeasonName()
            if season ~= "Winter" and luaObject.nbOfGrow ~= 7 then
                luaObject.nbOfGrow = luaObject.nbOfGrow + 1
            elseif season == "Winter" and luaObject.nbOfGrow == 0 then
                luaObject.nbOfGrow = luaObject.nbOfGrow + 1           
            end
        else
            luaObject.nbOfGrow = luaObject.nbOfGrow + 1
        end
    end
end

-- Используем событие OnGameStart для загрузки мода
Events.OnGameStart.Add(function()
    print("Farming Expansion loaded")
end)