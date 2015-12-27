SelectionManager = Observable:extends{}

local AreaListener = AreaManagerListener:extends{}
function SelectionManager:init()
    self:super("init")
    self.selectedUnits = {}
    self.selectedFeatures = {}
    self.selectedAreas = {}
    self.areaListener = AreaListener(self)
    SCEN_EDIT.model.areaManager:addListener(self.areaListener)
end

function SelectionManager:GetSelection()
    local selection = {
        units = self.selectedUnits,
        features = self.selectedFeatures,
        areas = self.selectedAreas,
    }
    return selection
end

function SelectionManager:ClearSelection()
    self.selectedUnits = {}
    Spring.SelectUnitArray({}, false)

    for _, areaId in pairs(self.selectedAreas) do
        SCEN_EDIT.view.areaViews[areaId].selected = false
    end
    self.selectedAreas = {}

    self.selectedFeatures = {}
end

function SelectionManager:SelectUnits(unitIds)
    assert(type(unitIds) == "table" and #unitIds > 0)
    self:ClearSelection()

    self.selectedUnits = unitIds
    Spring.SelectUnitArray(self.selectedUnits)
end

function SelectionManager:SelectFeatures(featureIds)
    assert(type(featureIds) == "table" and #featureIds > 0)
    self:ClearSelection()

    self.selectedFeatures = featureIds
end

function SelectionManager:SelectAreas(areaIds)
    assert(type(areaIds) == "table" and #areaIds > 0)
    self:ClearSelection()

    self.selectedAreas = areaIds
    for _, areaId in pairs(self.selectedAreas) do
        SCEN_EDIT.view.areaViews[areaId].selected = true
    end
end

function SelectionManager:Select(selection)
    self:ClearSelection()

    self.selectedUnits = selection.units or {}
    Spring.SelectUnitArray(self.selectedUnits)
    self.selectedFeatures = selection.features or {}
    self.selectedAreas = selection.areas or {}
    for _, areaId in pairs(self.selectedAreas) do
        SCEN_EDIT.view.areaViews[areaId].selected = true
    end

    self:callListeners("OnSelectionChanged", self:GetSelection())
end

function SelectionManager:Update()
    --update unit selection
    local unitIds = Spring.GetSelectedUnits()
    self.selectedUnits = unitIds
    Spring.SelectUnitArray(self.selectedUnits)

    local newSelectedFeatures = {}
    for _, featureId in pairs(self.selectedFeatures) do
        if Spring.ValidFeatureID(featureId) then
            table.insert(newSelectedFeatures, featureId)
        end
    end
    self.selectedFeatures = newSelectedFeatures
    --[[
    if #unitIds ~= #self.selectedUnits then
        self:ClearSelection()
        if #unitIds > 0 then
            self:SelectUnits(unitIds)
        end
    elseif #unitIds > 0 then
    end--]]
end

function SelectionManager:DrawWorldPreUnit()
    local selection = self:GetSelection()
    for _, featureId in pairs(selection.features) do
        if Spring.ValidFeatureID(featureId) then
            local bx, _, bz = Spring.GetFeaturePosition(featureId)
            local featureDef = FeatureDefs[Spring.GetFeatureDefID(featureId)]
            local minx, maxx = featureDef.minx or -10, featureDef.maxx or 10
            local minz, maxz = featureDef.minz or -10, featureDef.maxz or 10
            local x1, z1 = bx + minx - 5, bz + minz + 5
            local x2, z2 = bx + maxx - 5, bz + maxz + 5
            gl.BeginEnd(GL.LINE_STRIP, function()
                gl.Color(0, 1, 0, 1)
                gl.Vertex(x1, Spring.GetGroundHeight(x1, z1), z1)
                gl.Vertex(x2, Spring.GetGroundHeight(x2, z1), z1)
                gl.Vertex(x2, Spring.GetGroundHeight(x2, z2), z2)
                gl.Vertex(x1, Spring.GetGroundHeight(x1, z2), z2)
                gl.Vertex(x1, Spring.GetGroundHeight(x1, z1), z1)
            end)
        end
    end
end

function AreaListener:init(selectionManager)
    self.selectionManager = selectionManager
end

function AreaListener:onAreaRemoved(areaId)
    if #self.selectionManager.selectedAreas ~= 0 then
        for i, selAreaId in pairs(self.selectionManager.selectedAreas) do
            if selAreaId == areaId then
                table.remove(self.selectionManager.selectedAreas, i)
            end
        end
    end
end

