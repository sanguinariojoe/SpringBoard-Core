SB.Include(Path.Join(SB_MODEL_DIR, "trigger_manager.lua"))

----------------------------------------------------------
-- Widget callback commands
----------------------------------------------------------
WidgetAddTriggerCommand = Command:extends{}

function WidgetAddTriggerCommand:init(id, value)
    self.className = "WidgetAddTriggerCommand"
    self.id = id
    self.value = value
end

function WidgetAddTriggerCommand:execute()
    SB.model.triggerManager:addTrigger(self.value)
end
----------------------------------------------------------
----------------------------------------------------------
WidgetRemoveTriggerCommand = Command:extends{}

function WidgetRemoveTriggerCommand:init(id)
    self.className = "WidgetRemoveTriggerCommand"
    self.id = id
end

function WidgetRemoveTriggerCommand:execute()
    SB.model.triggerManager:removeTrigger(self.id)
end
----------------------------------------------------------
----------------------------------------------------------
WidgetUpdateTriggerCommand = Command:extends{}

function WidgetUpdateTriggerCommand:init(trigger)
    self.className = "WidgetUpdateTriggerCommand"
    self.trigger = trigger
end

function WidgetUpdateTriggerCommand:execute()
    SB.model.triggerManager:setTrigger(self.trigger.id, self.trigger)
end
----------------------------------------------------------
-- END Widget callback commands
----------------------------------------------------------

----------------------------------------------------------
-- Widget callback listener
----------------------------------------------------------
if SB.SyncModel then

TriggerManagerListenerGadget = TriggerManagerListener:extends{}
SB.OnInitialize(function()
    SB.model.triggerManager:addListener(TriggerManagerListenerGadget())
end)

function TriggerManagerListenerGadget:onTriggerAdded(triggerID)
    local trigger = SB.model.triggerManager:getTrigger(triggerID)
    local cmd = WidgetAddTriggerCommand(triggerID, trigger)
    SB.commandManager:execute(cmd, true)
end

function TriggerManagerListenerGadget:onTriggerRemoved(triggerID)
    local cmd = WidgetRemoveTriggerCommand(triggerID)
    SB.commandManager:execute(cmd, true)
end

function TriggerManagerListenerGadget:onTriggerUpdated(triggerID)
    local trigger = SB.model.triggerManager:getTrigger(triggerID)
    local cmd = WidgetUpdateTriggerCommand(trigger)
    SB.commandManager:execute(cmd, true)
end

end
----------------------------------------------------------
-- END Widget callback listener
----------------------------------------------------------
