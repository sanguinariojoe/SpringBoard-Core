UnitTypePanel = AbstractTypePanel:extends{}

function UnitTypePanel:init(...)
    self:super('init', 'unitType', ...)
end

function UnitTypePanel:MakePredefinedOpt()
    local stackUnitTypePanel = MakeComponentPanel(self.parent)
    self.cbPredefined = Checkbox:New {
        caption = "Predefined type: ",
        right = 100 + 10,
        x = 1,
        checked = false,
        parent = stackUnitTypePanel,
    }
    table.insert(self.radioGroup, self.cbPredefined)
    self.btnPredefined = Button:New {
        caption = '...',
        right = 1,
        width = 100,
        height = SCEN_EDIT.conf.B_HEIGHT,
        parent = stackUnitTypePanel,
        unitTypeId = nil,
    }
    self.btnPredefined.OnClick = {
        function()
            SCEN_EDIT.stateManager:SetState(SelectUnitTypeState(self.btnPredefined))
            --SCEN_EDIT.SelectType(self.btnPredefined)
        end
    }
    self.btnPredefined.OnSelectObjectType = {
        function(unitTypeId)
            self.btnPredefined.unitTypeId = unitTypeId
            local defName = unitBridge.ObjectDefs[unitTypeId].name
            self.btnPredefined.caption = "Id=" .. defName
            self.btnPredefined:Invalidate()
            if not self.cbPredefined.checked then
                self.cbPredefined:Toggle()
            end
        end
    }
end

function UnitTypePanel:UpdateModel(field)
    if self.cbPredefined and self.cbPredefined.checked and self.btnPredefined.unitTypeId ~= nil then
        field.type = "pred"
        field.id = self.btnPredefined.unitTypeId
        return true
    end
    return self:super('UpdateModel', field)
end

function UnitTypePanel:UpdatePanel(field)
    if field.type == "pred" then
        if not self.cbPredefined.checked then
            self.cbPredefined:Toggle()
        end
        self.btnPredefined.OnSelectObjectType[1](field.id)
        return true
    end
    return self:super('UpdatePanel', field)
end
