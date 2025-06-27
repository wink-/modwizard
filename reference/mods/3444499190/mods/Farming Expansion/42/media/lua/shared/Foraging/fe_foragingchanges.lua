require "Foraging/forageSystem"

Events.onAddForageDefs.Add(function()
    -- Определение для каменной соли
    local rockSaltDef = {
        type = "Base.RockSalt",              
        skill = 2,                           
        xp = 15,                            
        categories = { "Stones" },           -- Используем существующую категорию камней
        zones = {                           
            DeepForest = 10,
            Forest = 10,
            FarmLand = 10,
            Vegitation = 10,
            Farm = 10,
            OrganicForest = 10,
            PHForest = 10,
            PRForest = 10,
            ForagingNav = 10,
        },
        months = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12 },
        spawnFuncs = { doGenericItemSpawn },
        forceOutside = true,                
        itemSizeModifier = 1,               
        perks = { "PlantScavenging" },      
        minCount = 1,                        
        maxCount = 3                        
    }

    -- Добавляем определение в систему
    forageSystem.addItemDef(rockSaltDef);
end)