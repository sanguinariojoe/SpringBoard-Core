BrushManagers = LCS.class{}

function BrushManagers:init()
    self.brushNameMapping = {}
end

function BrushManagers:GetBrushManager(brushName)
    if not self.brushNameMapping[brushName] then
        self.brushNameMapping[brushName] = BrushManager()
    end
    return self.brushNameMapping[brushName]
end

function BrushManagers:GetBrushManagers()
    return self.brushNameMapping
end


BrushManager = Observable:extends{}

function BrushManager:init()
    self:super('init')

    self:Clear()
end

function BrushManager:Clear()
    if self.savedBrushes then
        for brushID, _ in pairs(self.savedBrushes) do
            self:RemoveBrush(brushID)
        end
    end

    self.__brushIDCounter = 1
    self.savedBrushes = {}
    self.savedBrushesOrder = {}
end

function BrushManager:AddBrush(brush)
    self.__brushIDCounter = self.__brushIDCounter + 1
    brush.brushID = self.__brushIDCounter
    self.savedBrushes[brush.brushID] = brush
    table.insert(self.savedBrushesOrder, brush.brushID)

    self:callListeners("OnBrushAdded", brush)

    return brush.brushID
end

function BrushManager:RemoveBrush(removeBrushID)
    local brush = self.savedBrushes[removeBrushID]
    self.savedBrushes[removeBrushID] = nil
    for i, brushID in pairs(self.savedBrushesOrder) do
        if removeBrushID == brushID then
            table.remove(self.savedBrushesOrder, i)
            break
        end
    end

    self:callListeners("OnBrushRemoved", brush)
end

function BrushManager:UpdateBrush(brushID, key, value)
    local brush = self.savedBrushes[brushID]
    brush.opts[key] = value

    self:callListeners("OnBrushUpdated", brush, key, value)
end

function BrushManager:UpdateBrushImage(brushID, image)
    local brush = self.savedBrushes[brushID]
    brush.image = image

    self:callListeners("OnBrushImageUpdated", brush, image)
end

function BrushManager:GetBrush(brushID)
    return self.savedBrushes[brushID]
end

function BrushManager:GetBrushes()
    return self.savedBrushesOrder
end

function BrushManager:Serialize()
    local brushes = {}
    for _, brush in pairs(self.savedBrushes) do
        local brushCopy = SB.deepcopy(brush)
        brushCopy.image = nil
        brushes[brush.brushID] = brushCopy
    end
    return {
        brushes = brushes,
        order = self.savedBrushesOrder,
    }
end

function BrushManager:Load(data)
    self:Clear()

    for _, brushID in pairs(data.order) do
        local brushData = data.brushes[brushID]
        self:AddBrush(brushData)
    end
end


------------------------------------------------
-- Listener definition
------------------------------------------------
BrushManagerListener = LCS.class.abstract{}

function BrushManagerListener:OnBrushAdded(brush)
end

function BrushManagerListener:OnBrushRemoved(brush)
end

function BrushManagerListener:OnBrushUpdated(brush, key, value)
end

function BrushManagerListener:OnBrushImageUpdated(brush, image)
end
------------------------------------------------
-- End listener definition
------------------------------------------------
