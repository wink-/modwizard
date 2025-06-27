require "Fluids/ISFluidTransferAction"

-- Переопределяем функцию start полностью
ISFluidTransferAction.start = function(self)
    self:setActionAnim(CharacterActionAnims.Pour)
    local itemA, itemB;
    if ISFluidUtil.validateContainer(self.source) and instanceof(self.source:getOwner(), "InventoryItem") then
        itemA = self.source:getOwner();
    end
    if ISFluidUtil.validateContainer(self.target) and instanceof(self.target:getOwner(), "InventoryItem") then
        itemB = self.target:getOwner();
        if itemB:getItemHeat() > 1.0 then
            itemB:setItemHeat(1.0);
        end
    end
    self:setOverrideHandModels(itemA, itemB);
    
    -- Проверяем тип контейнера и воспроизводим соответствующий звук
    if itemA and itemA:getType() == "Bochka" then
        self.sound = self.character:playSound("CustomPourSound")
    else
        self.sound = self.character:playSound("TransferLiquid")
    end
end