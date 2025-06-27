
if not farming_vegetableconf.props then farming_vegetableconf.props = {} end

farming_vegetableconf.props["AppleTree"] = {
    icon = "Item_Apple",
    texture = "fe_appletree_7",
    waterLvl = 60,
    waterNeeded = 70,
    timeToGrow = 720, -- 30 дней
    minVeg = 3,
    maxVeg = 6,
    minVegAutorized = 4,
    maxVegAutorized = 8,
    vegetableName = "Base.Apple",
    seedName = "Base.Apple",
    seedTypes = {"Base.AppleTree"},
    
    -- Важные параметры для постоянного роста
    growBack = 4, -- Возвращается на 4 стадию после сбора урожая
    mature = 6,   -- Созревание на 5 стадии
    fullGrown = 7, -- Полное созревание на 6 стадии
    harvestLevel = 6, -- Можно собирать с 5 стадии
    
    -- Сезонные параметры
    sowMonth = { 3, 4, 5, 6, 7, 8, 9 },
    bestMonth = { 3, 4 },
    riskMonth = { 10, 11, 12, 1, 2 },
    seasonRecipe = "Apple Tree Growing Season",
    
    -- Позиция сбора
    harvestPosition = "High",
    
    -- Устойчивость
    coldHardy = true,
    badMonthHardy = true,
}

farming_vegetableconf.props["CherryTree"] = {
    icon = "Item_Cherry",
    texture = "fe_cherrytree_7",
    waterLvl = 60,
    waterNeeded = 70,
    timeToGrow = 720, -- 30 дней
    minVeg = 6,
    maxVeg = 9,
    minVegAutorized = 8,
    maxVegAutorized = 12,
    vegetableName = "Base.Cherry",
    seedName = "Base.Cherry",
    seedTypes = {"Base.CherryTree"},
    
    -- Важные параметры для постоянного роста
    growBack = 4, -- Возвращается на 4 стадию после сбора урожая
    mature = 6,   -- Созревание на 5 стадии
    fullGrown = 7, -- Полное созревание на 6 стадии
    harvestLevel = 6, -- Можно собирать с 5 стадии
    
    -- Сезонные параметры
    sowMonth = { 3, 4, 5, 6, 7, 8, 9 },
    bestMonth = { 3, 4 },
    riskMonth = { 10, 11, 12, 1, 2 },
    seasonRecipe = "Cherry Tree Growing Season",
    
    -- Позиция сбора
    harvestPosition = "High",
    
    -- Устойчивость
    coldHardy = true,
    badMonthHardy = true,
}

farming_vegetableconf.props["GrapeSeed"] = {
    icon = "Item_Grapes",
    texture = "fe_grapevines_7",
    waterLvl = 60,
    waterNeeded = 70,
    timeToGrow = 720, -- 30 дней
    minVeg = 3,
    maxVeg = 6,
    minVegAutorized = 4,
    maxVegAutorized = 8,
    vegetableName = "Base.Grapes",
    seedName = "Base.Grapes",
    seedTypes = {"Base.GrapeSeed"},
    
    -- Важные параметры для постоянного роста
    growBack = 4, -- Возвращается на 4 стадию после сбора урожая
    mature = 6,   -- Созревание на 5 стадии
    fullGrown = 7, -- Полное созревание на 6 стадии
    harvestLevel = 6, -- Можно собирать с 5 стадии
    
    -- Сезонные параметры
    sowMonth = { 3, 4, 5, 6, 7, 8, 9 },
    bestMonth = { 3, 4 },
    riskMonth = { 10, 11, 12, 1, 2 },
    seasonRecipe = "Grape Growing Season",
    
    -- Позиция сбора
    harvestPosition = "Low",
    
    -- Устойчивость
    coldHardy = true,
    badMonthHardy = true,
}

-- Спрайты для разных стадий
farming_vegetableconf.sprite = farming_vegetableconf.sprite or {}
farming_vegetableconf.sprite["AppleTree"] = {
    "fe_appletree_0",
    "fe_appletree_1",
    "fe_appletree_2",
    "fe_appletree_3",
    "fe_appletree_4",
    "fe_appletree_5",
    "fe_appletree_6",
    "fe_appletree_7"
    }
farming_vegetableconf.unhealthySprite["AppleTree"] = {
    "fe_appletree_8",
    "fe_appletree_9",
    "fe_appletree_10",
    "fe_appletree_11",
    "fe_appletree_12",
    "fe_appletree_13",
    "fe_appletree_14",
    "fe_appletree_15"
    }
farming_vegetableconf.dyingSprite["AppleTree"] = {
    "fe_appletree_16",
    "fe_appletree_17",
    "fe_appletree_18",
    "fe_appletree_19",
    "fe_appletree_20",
    "fe_appletree_21",
    "fe_appletree_22",
    "fe_appletree_23"
    }
farming_vegetableconf.deadSprite["AppleTree"] = {
    "fe_appletree_24",
    "fe_appletree_25",
    "fe_appletree_26",
    "fe_appletree_27",
    "fe_appletree_28",
    "fe_appletree_29",
    "fe_appletree_30",
    "fe_appletree_31"
    }
farming_vegetableconf.trampledSprite["AppleTree"] = {
    "fe_appletree_32",
    "fe_appletree_33",
    "fe_appletree_34",
    "fe_appletree_35",
    "fe_appletree_36",
    "fe_appletree_37",
    "fe_appletree_38",
    "fe_appletree_39"
    }

farming_vegetableconf.sprite["GrapeSeed"] = {
    "fe_grapevines_0",
    "fe_grapevines_1",
    "fe_grapevines_2",
    "fe_grapevines_3",
    "fe_grapevines_4",
    "fe_grapevines_5",
    "fe_grapevines_6",
    "fe_grapevines_7"
}

farming_vegetableconf.unhealthySprite["GrapeSeed"] = {
    "fe_grapevines_8",
    "fe_grapevines_9",
    "fe_grapevines_10",
    "fe_grapevines_11",
    "fe_grapevines_12",
    "fe_grapevines_13",
    "fe_grapevines_14",
    "fe_grapevines_15"
}

farming_vegetableconf.dyingSprite["GrapeSeed"] = {
    "fe_grapevines_16",
    "fe_grapevines_17",
    "fe_grapevines_18",
    "fe_grapevines_19",
    "fe_grapevines_20",
    "fe_grapevines_21",
    "fe_grapevines_22",
    "fe_grapevines_23"
}

farming_vegetableconf.deadSprite["GrapeSeed"] = {
    "fe_grapevines_24",
    "fe_grapevines_25",
    "fe_grapevines_26",
    "fe_grapevines_27",
    "fe_grapevines_28",
    "fe_grapevines_29",
    "fe_grapevines_30",
    "fe_grapevines_31"
}

farming_vegetableconf.trampledSprite["GrapeSeed"] = {
    "fe_grapevines_32",
    "fe_grapevines_33",
    "fe_grapevines_34",
    "fe_grapevines_35",
    "fe_grapevines_36",
    "fe_grapevines_37",
    "fe_grapevines_38",
    "fe_grapevines_39"
}

farming_vegetableconf.sprite["CherryTree"] = {
    "fe_cherrytree_0",
    "fe_cherrytree_1",
    "fe_cherrytree_2",
    "fe_cherrytree_3",
    "fe_cherrytree_4",
    "fe_cherrytree_5",
    "fe_cherrytree_6",
    "fe_cherrytree_7"
}

farming_vegetableconf.unhealthySprite["CherryTree"] = {
    "fe_cherrytree_8",
    "fe_cherrytree_9",
    "fe_cherrytree_10",
    "fe_cherrytree_11",
    "fe_cherrytree_12",
    "fe_cherrytree_13",
    "fe_cherrytree_14",
    "fe_cherrytree_15"
}

farming_vegetableconf.dyingSprite["CherryTree"] = {
    "fe_cherrytree_16",
    "fe_cherrytree_17",
    "fe_cherrytree_18",
    "fe_cherrytree_19",
    "fe_cherrytree_20",
    "fe_cherrytree_21",
    "fe_cherrytree_22",
    "fe_cherrytree_23"
}

farming_vegetableconf.deadSprite["CherryTree"] = {
    "fe_cherrytree_24",
    "fe_cherrytree_25",
    "fe_cherrytree_26",
    "fe_cherrytree_27",
    "fe_cherrytree_28",
    "fe_cherrytree_29",
    "fe_cherrytree_30",
    "fe_cherrytree_31"
}

farming_vegetableconf.trampledSprite["CherryTree"] = {
    "fe_cherrytree_32",
    "fe_cherrytree_33",
    "fe_cherrytree_34",
    "fe_cherrytree_35",
    "fe_cherrytree_36",
    "fe_cherrytree_37",
    "fe_cherrytree_38",
    "fe_cherrytree_39"
}
