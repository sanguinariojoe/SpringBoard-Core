ConditionWindow = AbstractTriggerElementWindow:extends{}

function ConditionWindow:init(opts)
    opts.element = opts.condition
    self:super("init", opts)
end

function ConditionWindow:GetValidElementTypes()
    return SCEN_EDIT.metaModel.functionTypesByOutput["bool"]
end

function ConditionWindow:GetWindowCaption()
    if self.mode == 'add' then
        return "New condition for - " .. self.trigger.name
    elseif self.mode == 'edit' then
        return "Edit condition for trigger " .. self.trigger.name
    end
end

function ConditionWindow:GetElementTypeName()
    return self.element.conditionTypeName
end

function ConditionWindow:SetElementTypeName(elementTypeName)
    self.element.conditionTypeName = elementTypeName
end

function ConditionWindow:AddParent()
    table.insert(self.trigger.conditions, self.element)
end
