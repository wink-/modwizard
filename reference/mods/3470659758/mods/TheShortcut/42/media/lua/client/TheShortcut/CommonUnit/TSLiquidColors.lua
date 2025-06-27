TSLiquidColors = {}

TSLiquidColors.Colors = {
    ["Water"] = {0.4, 0.7, 1.0, 0.6},                -- 清亮淡蓝
    ["TaintedWater"] = {0.6, 0.5, 0.3, 0.6},         -- 淡褐
    ["CarbonatedWater"] = {0.7, 0.9, 1.0, 0.6},      -- 清浅蓝

    -- 牛奶系列
    ["CowMilk"] = {1.0, 1.0, 1.0, 0.6},              -- 纯白
    ["MilkChocolate"] = {0.75, 0.55, 0.35, 0.7},     -- 柔棕
    ["SpiffoMilk"] = {1.0, 1.0, 0.7, 0.6},           -- 奶黄

    -- 酒精系列
    ["Alcohol"] = {0.9, 0.9, 0.95, 0.6},             -- 微蓝白
    ["Beer"] = {0.95, 0.8, 0.4, 0.6},                -- 金黄
    ["Wine"] = {0.75, 0.2, 0.3, 0.7},                -- 柔红
    ["Whiskey"] = {0.8, 0.5, 0.2, 0.7},              -- 琥珀
    ["Vodka"] = {0.95, 0.95, 0.95, 0.4},             -- 清白
    ["Rum"] = {0.7, 0.4, 0.2, 0.6},                  -- 淡棕

    -- 果汁系列
    ["JuiceLemon"] = {1.0, 1.0, 0.4, 0.7},           -- 明黄
    ["JuiceOrange"] = {1.0, 0.7, 0.2, 0.7},          -- 橙黄
    ["JuiceFruitpunch"] = {1.0, 0.4, 0.6, 0.7},      -- 粉红
    ["JuiceTomato"] = {0.9, 0.3, 0.2, 0.7},          -- 番茄红
    ["JuiceApple"] = {1.0, 1.0, 0.7, 0.6},           -- 淡黄
    ["JuiceGrape"] = {0.7, 0.3, 0.7, 0.7},           -- 柔紫

    -- 碳酸饮料系列
    ["Cola"] = {0.4, 0.2, 0.1, 0.6},                 -- 柔棕
    ["SodaPop"] = {0.5, 0.9, 1.0, 0.7},              -- 天蓝

    -- 热饮系列
    ["Coffee"] = {0.4, 0.3, 0.2, 0.7},               -- 深棕
    ["Tea"] = {0.7, 0.5, 0.3, 0.6},                  -- 淡茶棕

    -- 化学液体
    ["Petrol"] = {1.0, 0.85, 0.2, 0.7},              -- 明黄
    ["Bleach"] = {0.95, 0.95, 1.0, 0.6},             -- 微蓝白

    -- 其他特殊液体
    ["Blood"] = {0.8, 0.1, 0.1, 0.8},                -- 红
}

-- 获取液体颜色
function TSLiquidColors:getLiquidColor(fluidContainer)
    if not fluidContainer then 
        return 0.2, 0.5, 0.9, 0.7 
    end
    
    local fluid = fluidContainer:getPrimaryFluid()
    if not fluid then 
        return 0.2, 0.5, 0.9, 0.7
    end

    local fluidType = fluid:getFluidType()
    local fluidTypeString = tostring(fluidType)

    local typeName = fluidTypeString:match("FluidType%.(.+)")
    if typeName and self.Colors[typeName] then
        local color = self.Colors[typeName]
        return color[1], color[2], color[3], color[4]
    end

    local fluidName = fluid:getFluidTypeString()
    if fluidName and self.Colors[fluidName] then
        local color = self.Colors[fluidName]
        return color[1], color[2], color[3], color[4]
    end

    return 0.2, 0.5, 0.9, 0.7
end

return TSLiquidColors