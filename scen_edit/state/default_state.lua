DefaultState = AbstractState:extends{}

function DefaultState:init()
    SB.SetMouseCursor()
    self.__clickedObjectID = nil
    self.__clickedObjectBridge = nil
end

function DefaultState:MousePress(mx, my, button)
    self.__clickedObjectID = nil
    self.__clickedObjectBridge = nil

    if Spring.GetGameRulesParam("sb_gameMode") ~= "dev" or button ~= 1 then
        return
    end

    local selection = SB.view.selectionManager:GetSelection()
    local selCount = SB.view.selectionManager:GetSelectionCount()
    local _, ctrl, _, shift = Spring.GetModKeyState()
    if ctrl and selCount > 0 then
        -- TODO: There should be a cleaner way to disable some types of editing interactions during play
        if Spring.GetGameRulesParam("sb_gameMode") == "dev" then
            return true
        else
            return false
        end
    end

    local isDoubleClick = false

    local currentTime = os.clock()
    if self.__lastClick and currentTime - self.__lastClick < 0.2 then
        isDoubleClick = true
    end
    self.__lastClick = currentTime

    local result, objectID = SB.TraceScreenRay(mx, my)

    -- TODO: Instead of letting Spring handle it, maybe we should capture the
    -- event and draw the screen rectangle ourselves
    if result == "ground" or result == "sky" then
        SB.stateManager:SetState(RectangleSelectState(mx, my))
        return
    end

    if not SB.lockTeam and result == "unit" then
        local unitTeamID = Spring.GetUnitTeam(objectID)
        if Spring.GetMyTeamID() ~= unitTeamID or Spring.GetSpectatingState() then
            if SB.FunctionExists(Spring.AssignPlayerToTeam, "Player change") then
                local cmd = ChangePlayerTeamCommand(Spring.GetMyPlayerID(), unitTeamID)
                SB.commandManager:execute(cmd)
            end
        end
    end

    local bridge = ObjectBridge.GetObjectBridge(result)
    local objects = selection[result] or {}
    local _, coords = SB.TraceScreenRay(mx, my, {onlyCoords = true})
    local pos = bridge.s11n:Get(objectID, "pos")
    local x, y, z = pos.x, pos.y, pos.z
    -- it's possible that there is no ground behind (if object is near the map edge)
    if coords == nil then
        coords = { x, y, z }
    end
    self.dragDiffX, self.dragDiffZ =  x - coords[1], z - coords[3]

    self.__clickedObjectID = objectID
    self.__clickedObjectBridge = bridge
    self.__wasSelected = false
    for _, oldObjectID in pairs(objects) do
        if oldObjectID == objectID then
            if isDoubleClick then
                if bridge.OnDoubleClick then
                    local res = bridge.OnDoubleClick(objectID, coords[1], coords[2], coords[3])
                    if res ~= nil then
                        return res
                    end
                end
            elseif bridge.OnClick then
                local res = bridge.OnClick(objectID, coords[1], coords[2], coords[3])
                if res ~= nil then
                    return res
                end
            end
            self.__wasSelected = true
        end
    end
    return true
end

function DefaultState:MouseMove(x, y, dx, dy, button)
    local selection = SB.view.selectionManager:GetSelection()
    local selCount = SB.view.selectionManager:GetSelectionCount()
    if selCount == 0 then
        return
    end
    local _, ctrl, _, shift = Spring.GetModKeyState()
    if ctrl then
        if shift then
            local draggable = false
            for selType, selected in pairs(selection) do
                local bridge = ObjectBridge.GetObjectBridge(selType)
                if not bridge.NoHorizontalDrag and not bridge.NoDrag then
                    if next(selected) ~= nil then
                        draggable = true
                    end
                end
                if draggable then
                    break
                end
            end
            if draggable then
                SB.stateManager:SetState(DragHorizontalObjectState())
            end
        else
            SB.stateManager:SetState(RotateObjectState())
        end
    else
        if self.__clickedObjectID and self.__wasSelected then
            SB.stateManager:SetState(DragObjectState(
               self.__clickedObjectID, self.__clickedObjectBridge,
               self.dragDiffX, self.dragDiffZ)
            )
        end
    end
end

function DefaultState:MouseRelease(...)
    if self.__clickedObjectID then
        local objType = self.__clickedObjectBridge.name
        local _, ctrl, _, shift = Spring.GetModKeyState()
        if shift then
            local selection = SB.view.selectionManager:GetSelection()
            if Table.Contains(selection[objType], self.__clickedObjectID) then
                local indx = GetIndex(selection[objType], self.__clickedObjectID)
                table.remove(selection[objType], indx)
            else
                table.insert(selection[objType], self.__clickedObjectID)
            end
            SB.view.selectionManager:Select(selection)
        else
            SB.view.selectionManager:Select({ [objType] = {self.__clickedObjectID}})
        end
    end
end

function DefaultState:KeyPress(key, mods, isRepeat, label, unicode)
    if self:super("KeyPress", key, mods, isRepeat, label, unicode) then
        return true
    end

    if key == KEYSYMS.DELETE then
        local selCount = SB.view.selectionManager:GetSelectionCount()
        if selCount == 0 then
            return false
        end
        DeleteAction():execute()
    elseif key == KEYSYMS.C and mods.ctrl then
        local selCount = SB.view.selectionManager:GetSelectionCount()
        if selCount == 0 then
            return false
        end
        CopyAction():execute()
    elseif key == KEYSYMS.X and mods.ctrl then
        local selCount = SB.view.selectionManager:GetSelectionCount()
        if selCount == 0 then
            return false
        end
        CutAction():execute()
    elseif key == KEYSYMS.V and mods.ctrl then
        PasteAction():execute()
    elseif key == KEYSYMS.A and mods.ctrl then
        SelectAllAction():execute()
    elseif key == KEYSYMS.T and mods.ctrl and mods.shift then
        SelectSameTypeInViewAction():execute()
    elseif key == KEYSYMS.T and mods.ctrl then
        SelectSameTypeAction():execute()
    else
        return false
    end
    return true
end
