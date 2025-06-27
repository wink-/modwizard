-- ----------------------------------------- --
-- 通用UI工具单元
-- ----------------------------------------- --

ShortcutUIHelper = {}

ShortcutUIHelper.textureCache = {}
ShortcutUIHelper.outlineTextureCache = {} -- 新增：描边数字贴图缓存
ShortcutUIHelper.isLoaded = false
ShortcutUIHelper.DEFAULT_SCALE_FACTOR = 1.0

-- ----------------------------------------- --
-- 初始化和资源加载
-- ----------------------------------------- --

function ShortcutUIHelper.loadTextures()
    if ShortcutUIHelper.isLoaded then return end
    
    -- 加载普通数字贴图 (0-9)
    for i = 0, 9 do
        ShortcutUIHelper.textureCache[tostring(i)] = getTexture("media/ui/TheShortCut/numbers/" .. i .. ".png")
    end

    -- ShortcutUIHelper.textureCache["S"] = getTexture("media/ui/TheShortCut/numbers/S.png")
    
    -- 加载描边数字贴图 (0-9)
    for i = 0, 9 do
        ShortcutUIHelper.outlineTextureCache[tostring(i)] = getTexture("media/ui/TheShortCut/numbers_outline/" .. i .. ".png")
    end

    -- ShortcutUIHelper.outlineTextureCache["S"] = getTexture("media/ui/TheShortCut/numbers_outline/S.png")
    
    
    ShortcutUIHelper.isLoaded = true
end

-- ----------------------------------------- --
-- 尺寸计算
-- ----------------------------------------- --

-- 获取贴图尺寸
function ShortcutUIHelper.getTextureSize()
    if not ShortcutUIHelper.isLoaded then
        ShortcutUIHelper.loadTextures()
    end
    if ShortcutUIHelper.textureCache["8"] then
        return ShortcutUIHelper.textureCache["8"]:getWidth(), ShortcutUIHelper.textureCache["8"]:getHeight()
    end
    
    return 32, 23
end

-- 计算文本宽度
function ShortcutUIHelper.measureTextWidth(text, scale, useOutline)
    if not ShortcutUIHelper.isLoaded then
        ShortcutUIHelper.loadTextures()
    end
    
    scale = (scale or 1.0) * ShortcutUIHelper.DEFAULT_SCALE_FACTOR
    local baseWidth, _ = ShortcutUIHelper.getTextureSize()
    local totalWidth = 0
    
    -- 选择使用的贴图缓存
    local cache = useOutline and ShortcutUIHelper.outlineTextureCache or ShortcutUIHelper.textureCache
    
    for i = 1, #text do
        local char = string.sub(text, i, i)
        
        if cache[char] then
            totalWidth = totalWidth + (baseWidth * scale)
        else
            totalWidth = totalWidth + getTextManager():MeasureStringX(UIFont.Small, char)
        end
    end
    
    return totalWidth
end

-- ----------------------------------------- --
-- 绘制函数
-- ----------------------------------------- --

-- 文本渲染函数
function ShortcutUIHelper.renderText(panel, text, x, y, scale, alpha, r, g, b, useOutline)
    if not ShortcutUIHelper.isLoaded then
        ShortcutUIHelper.loadTextures()
    end
    
    scale = (scale or 1.0) * ShortcutUIHelper.DEFAULT_SCALE_FACTOR
    alpha = alpha or 1.0
    r = r or 1.0
    g = g or 1.0
    b = b or 1.0
    useOutline = useOutline or false
    
    -- 选择使用的贴图缓存
    local cache = useOutline and ShortcutUIHelper.outlineTextureCache or ShortcutUIHelper.textureCache
    
    local baseWidth, baseHeight = ShortcutUIHelper.getTextureSize()
    local scaledWidth = baseWidth * scale
    local scaledHeight = baseHeight * scale
    local currentX = x
    
    for i = 1, #text do
        local char = string.sub(text, i, i)
        
        if cache[char] then
            panel:drawTextureScaled(
                cache[char], 
                currentX, 
                y, 
                scaledWidth, 
                scaledHeight, 
                alpha, r, g, b
            )
            currentX = currentX + scaledWidth
        end
    end
    
    return currentX - x
end

-- 绘制三段式贴图
function ShortcutUIHelper.drawThreeSlice(panel, x, y, width, height, leftTexture, middleTexture, rightTexture, alpha, r, g, b)
    if not leftTexture or not middleTexture or not rightTexture then return end

    x = math.floor(x)
    y = math.floor(y)
    width = math.floor(width)
    height = math.floor(height)
    
    -- 设置默认颜色
    alpha = alpha or 1.0
    r = r or 1.0
    g = g or 1.0
    b = b or 1.0
    
    -- 获取左右两段的原始尺寸
    local leftOriginalWidth = leftTexture:getWidth()
    local leftOriginalHeight = leftTexture:getHeight()
    local rightOriginalWidth = rightTexture:getWidth()
    local rightOriginalHeight = rightTexture:getHeight()
    
    -- 计算左右两段的实际宽度（保持比例）
    local heightRatio = height / leftOriginalHeight
    local leftActualWidth = math.floor(leftOriginalWidth * heightRatio)
    
    heightRatio = height / rightOriginalHeight
    local rightActualWidth = math.floor(rightOriginalWidth * heightRatio)
    
    local minSidesWidth = leftActualWidth + rightActualWidth
    
    -- 如果总宽度小于最小宽度，按照CHB的方式处理
    if width <= minSidesWidth then
        local leftRatio = leftActualWidth / minSidesWidth
        leftActualWidth = math.floor(width * leftRatio)
        rightActualWidth = width - leftActualWidth
        
        panel:drawTextureScaled(leftTexture, x, y, leftActualWidth, height, alpha, r, g, b)
        panel:drawTextureScaled(rightTexture, x + leftActualWidth, y, rightActualWidth, height, alpha, r, g, b)
    else
        -- 计算中间段的宽度
        local middleWidth = width - leftActualWidth - rightActualWidth
        
        -- 绘制左段
        panel:drawTextureScaled(leftTexture, x, y, leftActualWidth, height, alpha, r, g, b)
        
        -- 绘制中段
        panel:drawTextureScaled(middleTexture, x + leftActualWidth, y, middleWidth, height, alpha, r, g, b)
        
        -- 绘制右段
        panel:drawTextureScaled(rightTexture, x + leftActualWidth + middleWidth, y, rightActualWidth, height, alpha, r, g, b)
    end
end

-- 绘制垂直三段式贴图
function ShortcutUIHelper.drawVerticalThreeSlice(panel, x, y, width, height, topTexture, middleTexture, bottomTexture, alpha, r, g, b)
    if not topTexture or not middleTexture or not bottomTexture then return end

    x = math.floor(x)
    y = math.floor(y)
    width = math.floor(width)
    height = math.floor(height)
    
    -- 设置默认颜色
    alpha = alpha or 1.0
    r = r or 1.0
    g = g or 1.0
    b = b or 1.0
    
    -- 获取上下两段的原始尺寸
    local topOriginalWidth = topTexture:getWidth()
    local topOriginalHeight = topTexture:getHeight()
    local bottomOriginalWidth = bottomTexture:getWidth()
    local bottomOriginalHeight = bottomTexture:getHeight()
    
    -- 计算上下两段的实际高度（保持比例）
    local widthRatio = width / topOriginalWidth
    local topActualHeight = math.floor(topOriginalHeight * widthRatio)
    
    widthRatio = width / bottomOriginalWidth
    local bottomActualHeight = math.floor(bottomOriginalHeight * widthRatio)
    
    local minSidesHeight = topActualHeight + bottomActualHeight
    
    -- 如果总高度小于最小高度，按比例调整上下两段
    if height <= minSidesHeight then
        local topRatio = topActualHeight / minSidesHeight
        topActualHeight = math.floor(height * topRatio)
        bottomActualHeight = height - topActualHeight
        
        panel:drawTextureScaled(topTexture, x, y, width, topActualHeight, alpha, r, g, b)
        panel:drawTextureScaled(bottomTexture, x, y + topActualHeight, width, bottomActualHeight, alpha, r, g, b)
    else
        -- 计算中间段的高度
        local middleHeight = height - topActualHeight - bottomActualHeight
        
        -- 绘制上段
        panel:drawTextureScaled(topTexture, x, y, width, topActualHeight, alpha, r, g, b)
        
        -- 绘制中段
        panel:drawTextureScaled(middleTexture, x, y + topActualHeight, width, middleHeight, alpha, r, g, b)
        
        -- 绘制下段
        panel:drawTextureScaled(bottomTexture, x, y + topActualHeight + middleHeight, width, bottomActualHeight, alpha, r, g, b)
    end
end

-- 绘制九段式贴图
function ShortcutUIHelper.drawNineSlice(panel, x, y, width, height, textures, alpha, r, g, b)
    if not (textures.topLeft and textures.top and textures.topRight and 
            textures.left and textures.middle and textures.right and 
            textures.bottomLeft and textures.bottom and textures.bottomRight) then
        return
    end
    
    x = math.floor(x)
    y = math.floor(y)
    width = math.floor(width)
    height = math.floor(height)
    
    -- 设置默认颜色
    alpha = alpha or 1.0
    r = r or 1.0
    g = g or 1.0
    b = b or 1.0
    
    -- 获取四个角的原始尺寸
    local cornerTopLeftWidth = textures.topLeft:getWidth()
    local cornerTopLeftHeight = textures.topLeft:getHeight()
    local cornerTopRightWidth = textures.topRight:getWidth()
    local cornerTopRightHeight = textures.topRight:getHeight()
    local cornerBottomLeftWidth = textures.bottomLeft:getWidth()
    local cornerBottomLeftHeight = textures.bottomLeft:getHeight()
    local cornerBottomRightWidth = textures.bottomRight:getWidth()
    local cornerBottomRightHeight = textures.bottomRight:getHeight()
    
    -- 计算最小宽度和高度
    local minWidth = cornerTopLeftWidth + cornerTopRightWidth
    local minHeight = cornerTopLeftHeight + cornerBottomLeftHeight
    
    -- 计算统一的缩放比例（取较小值确保等比缩放）
    local scale = 1.0
    if width < minWidth then
        scale = width / minWidth
    end
    if height < minHeight and (height / minHeight) < scale then
        scale = height / minHeight
    end
    
    -- 使用统一比例缩放四个角的尺寸
    local actualCornerTopLeftWidth = math.floor(cornerTopLeftWidth * scale)
    local actualCornerTopLeftHeight = math.floor(cornerTopLeftHeight * scale)
    local actualCornerTopRightWidth = math.floor(cornerTopRightWidth * scale)
    local actualCornerTopRightHeight = math.floor(cornerTopRightHeight * scale)
    local actualCornerBottomLeftWidth = math.floor(cornerBottomLeftWidth * scale)
    local actualCornerBottomLeftHeight = math.floor(cornerBottomLeftHeight * scale)
    local actualCornerBottomRightWidth = math.floor(cornerBottomRightWidth * scale)
    local actualCornerBottomRightHeight = math.floor(cornerBottomRightHeight * scale)
    
    -- 计算边缘和中间部分的尺寸
    local middleWidth = width - actualCornerTopLeftWidth - actualCornerTopRightWidth
    local middleHeight = height - actualCornerTopLeftHeight - actualCornerBottomLeftHeight
    
    -- 如果空间不足，进行特殊处理
    if middleWidth < 0 then
        -- 根据宽度比例调整角落宽度
        local totalCornerWidth = actualCornerTopLeftWidth + actualCornerTopRightWidth
        actualCornerTopLeftWidth = math.floor(width * (actualCornerTopLeftWidth / totalCornerWidth))
        actualCornerTopRightWidth = width - actualCornerTopLeftWidth
        actualCornerBottomLeftWidth = actualCornerTopLeftWidth
        actualCornerBottomRightWidth = actualCornerTopRightWidth
        middleWidth = 0
    end
    
    if middleHeight < 0 then
        -- 根据高度比例调整角落高度
        local totalCornerHeight = actualCornerTopLeftHeight + actualCornerBottomLeftHeight
        actualCornerTopLeftHeight = math.floor(height * (actualCornerTopLeftHeight / totalCornerHeight))
        actualCornerBottomLeftHeight = height - actualCornerTopLeftHeight
        actualCornerTopRightHeight = actualCornerTopLeftHeight
        actualCornerBottomRightHeight = actualCornerBottomLeftHeight
        middleHeight = 0
    end
    
    -- 绘制四个角
    panel:drawTextureScaled(textures.topLeft, x, y, 
                           actualCornerTopLeftWidth, actualCornerTopLeftHeight, 
                           alpha, r, g, b)
    
    panel:drawTextureScaled(textures.topRight, 
                           x + width - actualCornerTopRightWidth, y, 
                           actualCornerTopRightWidth, actualCornerTopRightHeight, 
                           alpha, r, g, b)
    
    panel:drawTextureScaled(textures.bottomLeft, 
                           x, y + height - actualCornerBottomLeftHeight, 
                           actualCornerBottomLeftWidth, actualCornerBottomLeftHeight, 
                           alpha, r, g, b)
    
    panel:drawTextureScaled(textures.bottomRight, 
                           x + width - actualCornerBottomRightWidth, y + height - actualCornerBottomRightHeight, 
                           actualCornerBottomRightWidth, actualCornerBottomRightHeight, 
                           alpha, r, g, b)
    
    -- 绘制边缘
    if middleWidth > 0 then
        -- 上边缘
        panel:drawTextureScaled(textures.top, 
                               x + actualCornerTopLeftWidth, y, 
                               middleWidth, actualCornerTopLeftHeight, 
                               alpha, r, g, b)
        
        -- 下边缘
        panel:drawTextureScaled(textures.bottom, 
                               x + actualCornerBottomLeftWidth, y + height - actualCornerBottomLeftHeight, 
                               middleWidth, actualCornerBottomLeftHeight, 
                               alpha, r, g, b)
    end
    
    if middleHeight > 0 then
        -- 左边缘
        panel:drawTextureScaled(textures.left, 
                               x, y + actualCornerTopLeftHeight, 
                               actualCornerTopLeftWidth, middleHeight, 
                               alpha, r, g, b)
        
        -- 右边缘
        panel:drawTextureScaled(textures.right, 
                               x + width - actualCornerTopRightWidth, y + actualCornerTopRightHeight, 
                               actualCornerTopRightWidth, middleHeight, 
                               alpha, r, g, b)
    end
    
    -- 绘制中间部分
    if middleWidth > 0 and middleHeight > 0 then
        panel:drawTextureScaled(textures.middle, 
                               x + actualCornerTopLeftWidth, y + actualCornerTopLeftHeight, 
                               middleWidth, middleHeight, 
                               alpha, r, g, b)
    end
end

return ShortcutUIHelper