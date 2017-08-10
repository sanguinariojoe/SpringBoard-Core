RotateObjectState = AbstractState:extends{}

function RotateObjectState:init()
    AbstractState.init(self)

    self.ghostViews = {
        units = {},
        features = {},
        areas = {},
    }
    SB.SetMouseCursor("resize-x")
end

function RotateObjectState:GetRotatedObject(params, bridge)
    local objectID = params.objectID
    local angle = params.angle
    local avgX, avgZ = params.avgX, params.avgZ

    local objectX, objectY, objectZ = bridge.spGetObjectPosition(objectID)
    local dx = objectX - avgX
    local dz = objectZ - avgZ
    local angle2 = angle + math.atan2(dx, dz)
    local len = math.sqrt(dx * dx + dz * dz)

    local objectAngle = 0
    if bridge.spGetObjectDirection then
        local dirX, _, dirZ = bridge.spGetObjectDirection(objectID)
        objectAngle = math.atan2(dirX, dirZ) + angle
    end

    local object = {
        angle = objectAngle,
        pos = {
            x = objectX,
            y = objectY,
            z = objectZ,
        }
    }
    if len > 0 then
        local x, z = avgX + len * math.sin(angle2), avgZ + len * math.cos(angle2)
        if math.abs(objectY - Spring.GetGroundHeight(objectX, objectZ)) < 5 then -- on ground, stick to it
            objectY = Spring.GetGroundHeight(x, z)
        end
        object.pos = {
            x = x,
            y = objectY,
            z = z,
        }
    end
    return object
end

function RotateObjectState:MouseMove(x, y, dx, dy, button)
    local result, coords = Spring.TraceScreenRay(x, y, true)
    if result == "ground" then

        local selection = SB.view.selectionManager:GetSelection()
        local selCount = #selection.units + #selection.features + #selection.areas
        self.ghostViews = {
            units = {},
            features = {},
            areas = {},
        }

        local avgX, avgZ = 0, 0
        for _, objectID in pairs(selection.units) do
            local unitX, unitY, unitZ = Spring.GetUnitPosition(objectID)
            avgX = avgX + unitX
            avgZ = avgZ + unitZ
        end
        for _, objectID in pairs(selection.features) do
            local unitX, unitY, unitZ = Spring.GetFeaturePosition(objectID)
            avgX = avgX + unitX
            avgZ = avgZ + unitZ
        end
        for _, objectID in pairs(selection.areas) do
            local unitX, unitY, unitZ = AreaBridge.spGetObjectPosition(objectID)
            avgX = avgX + unitX
            avgZ = avgZ + unitZ
        end
        avgX = avgX / (selCount)
        avgZ = avgZ / (selCount)
        local dx, dz = coords[1] - avgX, coords[3] - avgZ
        local angle = math.atan2(dx, dz)
        if self.angle == nil then
            self.angle = angle
        end
        angle = angle - self.angle

        for _, objectID in pairs(selection.units) do
            local object = self:GetRotatedObject({
                objectID = objectID,
                angle = angle,
                avgX = avgX,
                avgZ = avgZ,
                }, unitBridge)
            self.ghostViews.units[objectID] = object
        end
        for _, objectID in pairs(selection.features) do
            local object = self:GetRotatedObject({
                objectID = objectID,
                angle = angle,
                avgX = avgX,
                avgZ = avgZ,
                }, featureBridge)
            self.ghostViews.features[objectID] = object
        end
        for _, objectID in pairs(selection.areas) do
            local object = self:GetRotatedObject({
                objectID = objectID,
                angle = angle,
                avgX = avgX,
                avgZ = avgZ,
                }, areaBridge)
            self.ghostViews.areas[objectID] = object
        end
    end
end

function RotateObjectState:MouseRelease(x, y, button)
    local commands = {}

    for objectID, object in pairs(self.ghostViews.units) do
        local modelID = SB.model.unitManager:getModelUnitID(objectID)
        local cmd = SetUnitParamCommand(modelID, {
            dir = { x = math.sin(object.angle), y = 0, z = math.cos(object.angle) },
            pos = object.pos
        })
        table.insert(commands, cmd)
    end
    for objectID, object in pairs(self.ghostViews.features) do
        local modelID = SB.model.featureManager:getModelFeatureID(objectID)
        local cmd = SetFeatureParamCommand(modelID, {
            dir = { x = math.sin(object.angle), y = 0, z = math.cos(object.angle) },
            pos = object.pos
        })
        table.insert(commands, cmd)
    end
    for objectID, object in pairs(self.ghostViews.areas) do
        local x1, z1, x2, z2 = unpack(SB.model.areaManager:getArea(objectID))
        local pos = object.pos
        local mx, _, mz = areaBridge.spGetObjectPosition(objectID)
        local dx, dz = pos.x - mx, pos.z - mz
        local cmd = MoveAreaCommand(objectID, x1 + dx, z1 + dz)
        table.insert(commands, cmd)
    end

    local compoundCommand = CompoundCommand(commands)
    SB.commandManager:execute(compoundCommand)

    SB.stateManager:SetState(DefaultState())
end

function RotateObjectState:DrawObject(objectID, object, bridge, shaderObj)
    local objectDefID  = bridge.spGetObjectDefID(objectID)
    local objectTeamID = bridge.spGetObjectTeam(objectID)
    gl.Uniform(shaderObj.teamColorID, Spring.GetTeamColor(objectTeamID))
    bridge.DrawObject({
        color           = { r = 0.4, g = 1, b = 0.4, a = 0.8 },
        objectDefID     = objectDefID,
        objectTeamID    = objectTeamID,
        pos             = object.pos,
        angle           = { x = 0, y = math.deg(object.angle), z = 0 },
    })
end

function RotateObjectState:DrawWorld()
    gl.DepthTest(GL.LEQUAL)
    gl.DepthMask(true)
    local shaderObj = SB.view.modelShaders:GetShader()
    gl.UseShader(shaderObj.shader)
    gl.Uniform(shaderObj.timeID, os.clock())
    for objectID, object in pairs(self.ghostViews.units) do
        self:DrawObject(objectID, object, unitBridge, shaderObj)
    end
    for objectID, object in pairs(self.ghostViews.features) do
        self:DrawObject(objectID, object, featureBridge, shaderObj)
    end
    gl.UseShader(0)
    for objectID, object in pairs(self.ghostViews.areas) do
        local x1, z1, x2, z2 = unpack(SB.model.areaManager:getArea(objectID))
        local mx, _, mz = areaBridge.spGetObjectPosition(objectID)
        local dx, dz = object.pos.x - mx, object.pos.z - mz
        local areaView = AreaView(objectID)
        areaView:_Draw(x1 + dx, z1 + dz, x2 + dx, z2 + dz)
    end
end
