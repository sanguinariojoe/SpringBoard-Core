EditorView = LCS.class{}

function EditorView:init(opts)
    self.fields = {}
	self.fieldOrder = {}

	self.btnClose = Button:New {
        caption = 'Close',
        width = 100,
        right = 15,
        bottom = 1,
        height = SCEN_EDIT.conf.B_HEIGHT,
        OnClick = {
            function()
                self.window:Hide()
                SCEN_EDIT.stateManager:SetState(DefaultState())
            end 
        },
    }
	
    self.stackPanel = StackPanel:New {
        y = 0,
        x = 0,
		right = 0,
		
		centerItems = false,
		
		-- autosize = true, -- FIXME: autosize is not working. If enabled (and height disabled) it will cause controls not to render any changes.
		-- debug = true,
		resizeItems = true, -- FIXME: This is also temporarily enabled because of the bug above
		
        itemPadding = {0,10,0,0},
        padding = {0,0,0,0},
        margin = {0,0,0,0},
        itemMargin = {5,0,0,0},
    }
	self.stackPanel:DisableRealign()
end

-- Override
function EditorView:OnStartChange(name, value)
end
-- Override
function EditorView:OnEndChange(name, value)
end
-- Override 
function EditorView:OnFieldChange(name, value)
end
-- Override 
function EditorView:IsValidTest(state)
    return false
end

-- NOTICE: Invoke :Finalize at the end of init
function EditorView:Finalize(children)
	table.insert(children, self.btnClose)
	
	self.window = Control:New {
--         parent = screen0,
--         x = 10,
--         y = 100,
--         width = 550,
--         height = 800,
		x = 0,
		y = 0,
		bottom = 0,
		right = 0,
        caption = '',
        children = children,
    }
	
	self.stackPanel:EnableRealign()
	self:_MEGA_HACK()
	
	SCEN_EDIT.view:SetMainPanel(self.window)
end

function EditorView:_MEGA_HACK()
	-- FIXME: Mega hack to manually resize the stackPanel since autosize is broken
	SCEN_EDIT.delay(function()
	SCEN_EDIT.delay(function()
	self.stackPanel.resizeItems = false
	local h = 0
	for _, c in pairs(self.stackPanel.children) do
		if type(c) == "table" then
			c:UpdateLayout()
			h = h + c.height + self.stackPanel.itemPadding[2]
		end
	end
	self.stackPanel:Resize(nil, h)
	end)
	end)
end

-- Don't use this directly because ordering would be messed up.
function EditorView:_SetFieldVisible(name, visible)
	if not self.fields[name] then
		Spring.Log("Scened", LOG.ERROR, "Trying to set visibility on an invalid field: " .. tostring(name))
		return
	end
	
	if visible == nil then
		return
	end
	
	local ctrl = self.fields[name].ctrl
	-- HACK: use Add/Remove instead of Show/Hide to have proper ordering
	--if ctrl.visible ~= visible then
	if ctrl._visible ~= visible then
		if visible then
			self.stackPanel:AddChild(ctrl)
			ctrl._visible = true
			--ctrl:Show()
		else
			self.stackPanel:RemoveChild(ctrl)
			ctrl._visible = false
			--ctrl:Hide()
		end
	end
end

function EditorView:SetInvisibleFields(...)
	self.stackPanel:DisableRealign()
	
	local fields = {...}
	for i = #self.fieldOrder, 1, -1 do
		local name = self.fieldOrder[i]
		self:_SetFieldVisible(name, false)
	end
	
	self.stackPanel.resizeItems = true
	
	for i = 1, #self.fieldOrder do
		local name = self.fieldOrder[i]
		if not table.ifind(fields, name) then
			self:_SetFieldVisible(name, true)
		end
	end

	self.stackPanel:EnableRealign()
	self:_MEGA_HACK()
end

function EditorView:AddField(field)
    self.fields[field.name] = field
    field.ctrl = self:_AddControl(field.name, field.components)
    -- HACK (this is when we process ._hidden fields as we can't Hide fields before they've been added to the stack panel)
    for _, comp in pairs(field.components) do
        if comp._hidden then
            comp:Hide()
        end
    end
    field.ev = self
end

function EditorView:AddControl(name, children)
    self.fields[name] = {
        ctrl = self:_AddControl(name, children),
        name = name,
    }
    return self.fields[name]
end

function EditorView:_AddControl(name, children)
    local ctrl = Control:New {
        autosize = true,
        padding = {0, 0, 0, 0},
        children = children
    }
    self.stackPanel:AddChild(ctrl)
    table.insert(self.fieldOrder, name)
    return ctrl
end

function EditorView:Set(name, value)
    local field = self.fields[name]
    field:Set(value)
end
function EditorView:Update(name)
    local field = self.fields[name]

    field:Update()

    -- update listeners and current state
    self:OnFieldChange(field.name, field.value)
    local currentState = SCEN_EDIT.stateManager:GetCurrentState()
    if self:IsValidTest(currentState) then
        currentState[field.name] = field.value
    end
end

function EditorView:_OnStartChange(name, value)
    if not self._startedChanging then
        self._startedChanging = true
        self:OnStartChange(name, value)
    end
end

function EditorView:_OnEndChange(name, value)
    if self._startedChanging then
        self._startedChanging = false
        self:OnEndChange(name, value)
    end
end

Field = LCS.class{}
function Field:init(field)
    self.VALUE_POS = 180
    for k, v in pairs(field) do
        self[k] = v
    end
end
-- Override
function Field:Validate(value)
    if value ~= nil and value ~= self.value then
        return true, value
    end
    return nil
end
function Field:Set(value, source)
    if self.inUpdate then
        return
    end
    self.inUpdate = true
    local valid, value = self:Validate(value)
    if valid then
        self.value = value
        -- invoke editor view's update
        self.ev:Update(self.name, source)
    end
    self.inUpdate = nil
end

ChoiceField = Field:extends{}
function ChoiceField:Update(source)
    -- HACK
    if source ~= self.comboBox then
        for i, id in pairs(self.comboBox.ids) do
            if id == self.value then
                self.comboBox:Select(i)
                break
            end
        end
    end
end

function ChoiceField:init(field)
    self:super('init', field)
    self.label = Label:New {
        caption = self.title,
        x = 1,
        y = 10,
        autosize = true,
    }
    local ids, captions = self.items, self.captions
    if captions == nil then
        captions = self.items
    end
    self.comboBox = ComboBox:New {
        x = self.VALUE_POS - 5,
        y = 0,
        width = 150,
        height = 30,
        items = captions,
        ids = ids,
    }
    self.comboBox.OnSelect = {
        function(obj, indx)
            local value = self.comboBox.ids[indx]
            self:Set(value, self.comboBox)
        end
    }
    self.value = self.items[1]

    self.components = {
        self.label,
        self.comboBox,
    }
end

BooleanField = Field:extends{}
function BooleanField:Update(source)
    if source ~= self.checkBox then
        if self.checkBox.checked ~= self.value then
            self.checkBox:Toggle()
        end
        self.checkBox:Invalidate()
    end
end

function BooleanField:AddBooleanProperty(field)
    self:super('init', field)
    self.checkBox = Checkbox:New {
        caption = self.title,
        x = 1,
        y = 0,
        width = self.VALUE_POS + 10,
        height = 20,
        checked = self.value,
    }
    self.checkBox.OnChange = {
        function(obj, checked)
            self:Set(checked, self.checkBox)
        end
    }

    self.components = {
        self.checkBox,
    }
end

function ParseKey(editBox, key, mods, ...)
    if key == Spring.GetKeyCode("enter") or 
        key == Spring.GetKeyCode("numpad_enter") then
        screen0:FocusControl(nil)
        return true
    end
end

NumericField = Field:extends{}
function NumericField:Update(source)
    -- HACK
    local v = tostring(self.value)
    v = v:sub(1, math.min(#v, 6))
    if source ~= self.editBox then
        self.editBox:SetText(v)
    end
--     if source ~= self.trackbar then
--         self.trackbar:SetValue(self.value)
--     end
    if source ~= self.lblValue then
        self.lblValue:SetCaption(v)
    end
end

function NumericField:Validate(value)
    local valid, value = self:super("Validate", value)
    if value then
        value = tonumber(value)
    end
    if value then
        if self.maxValue then
            value = math.min(self.maxValue, value)
        end
        if self.minValue then
            value = math.max(self.minValue, value)
        end
        return true, value
    end
    return nil
end

function NumericField:init(field)
    self:super('init', field)
    if self.step == nil then
        self.step = 1
    end
    local v = tostring(self.value)
    v = v:sub(1, math.min(#v, 6))

    self.editBox = EditBox:New {
        text = v,
        x = 1,
        y = 1,
        width = 200,
        height = 20,
        _hidden = true,
        KeyPress = function(...)
            if not ParseKey(...) then
                return Chili.EditBox.KeyPress(...)
            end
            return true
        end,
        OnTextInput = {
            function() 
                self:Set(self.editBox.text, self.editBox)
            end
        },
        OnKeyPress = {
            function()
                self:Set(self.editBox.text, self.editBox)
            end
        },
        OnFocusUpdate = {
            function(...)
                if not self.editBox.state.focused then
                    self.button:Show()
                    self.editBox:Hide()
                    self.ev.stackPanel:Invalidate()
                    self.ev:_OnEndChange(name, value)
                end
            end
        },
    }
    self.lblValue = Label:New {
        caption = v,
        width = "100%",
        right = 5,
        y = 5,
--                 padding = { 0, 0, 0, 0 },
        align = "right",
    }
    self.button = Button:New {
        caption = "",
        x = 1,
        y = 1,
        width = 200,
        height = 30,
        padding = {0, 0, 0, 0,},
        OnClick = {
            function()
                if not self.notClick then
                    self.button:Hide()
                    self.editBox:Show()
                    self.editBox.cursor = #self.editBox.text + 1
                    screen0:FocusControl(self.editBox)
                    self.ev:_OnStartChange(self.name, value)
                end
            end
        },
        OnMouseUp = {
            function()
                SCEN_EDIT.SetMouseCursor()
                self.startX = nil
                self.notClick = false
                self.ev:_OnEndChange(self.name, value)
            end
        },
        OnMouseMove = {
            function(obj, x, y, _, _, btn, ...)
                if btn then
                    local _, _, _, shift = Spring.GetModKeyState()
                    if not self.startX then
                        self.startX = x
                        self.currentX = x
                    end
                    local dx = x - self.currentX
                    self.currentX = x
                    if math.abs(x - self.startX) > 4 then
                        self.notClick = true
                        self.ev:_OnStartChange(self.name, value)
                    end
                    if self.notClick then
                        if shift then
                            dx = dx * 0.1
                        end
                        local value = self.value + dx * self.step
                        self:Set(value, obj)
                    end
                    SCEN_EDIT.SetMouseCursor("resize-x")
                end
            end
        },
        children = { 
            self.lblValue,
            Label:New {
                caption = self.title,
                x = 10,
                y = 5,
--                 padding = { 0, 0, 0, 0 },
                autosize = true,
                tooltip = self.tooltip,
            },
        },
    }
--     self.trackbar = Trackbar:New {
--         x = self.VALUE_POS + 130,
--         y = 1,
--         value = self.value,
--         min = self.minValue,
--         max = self.maxValue,
--         step = self.step or 0.01,
--         width = 95,
--         height = 20,
--     }
--     self.trackbar.OnChange = {
--         function(obj, value)
--             self:SetNumericField(self.name, value, obj)
--         end
--     }
--     self.trackbar.OnMouseUp = {
--         function(obj, value)
--             if self._startedChanging then
--                 self._startedChanging = false
--                 self:OnEndChange(self.name, value)
--             end
--         end
--     }
--     self.trackbar.OnMouseDown = {
--         function(obj, value)
--             if not self._startedChanging then
--                 self._startedChanging = true
--                 self:OnStartChange(self.name, value)
--             end
--         end
--     }

    self.components = {
-- 		self.label,
 		self.editBox,
-- 		self.trackbar,
        self.button,
	}
end

StringField = Field:extends{}
function StringField:Update(source)
    -- HACK
    if source ~= self.editBox then
        self.editBox:SetText(self.value)
    end
end

function StringField:init(field)
    self:super('init', field)
    self.label = Label:New {
        caption = self.title,
        x = 1,
        y = 1,
        autosize = true,
        tooltip = self.tooltip,
    }
    self.editBox = EditBox:New {
        text = self.value,
        x = self.VALUE_POS,
        y = 1,
        width = 100,
        height = 20,
        KeyPress = function(...)
            if not ParseKey(...) then
                return Chili.EditBox.KeyPress(...)
            end
            return true
        end,
        OnTextInput = {
            function()
                self:Set(self.editBox.text, self.editBox)
            end
        },
        OnKeyPress = {
            function()
                self:Set(self.editBox.text, self.editBox)
            end
        },
        OnFocusUpdate = {
            function(...)
                if not self.editBox.state.focused then
                    self.ev:_OnEndChange(name, value)
                else
                    self.ev:_OnStartChange(name, value)
                end
            end
        },
    }

    self.components = {
        self.label,
        self.editBox,
    }
end

ColorbarsField = Field:extends{}
function ColorbarsField:Update(source)
    if source ~= self.colorbars then
        self.colorbars:SetColor(self.value)
    end
end

function ColorbarsField:init(field)
    self:super('init', field)
    self.label = Label:New {
        caption = self.title,
        x = 1,
        y = 1,
        tooltip = self.tooltip,
    }
    self.colorbars = Colorbars:New {
        color = self.value,
        x = self.VALUE_POS,
        y = 1,
        width = 225,
        height = 60,
        OnChange = {
            function(obj, value)
                self:Set(value, obj)
            end
        },
    }
    self.components = {
        self.label,
        self.colorbars,
    }
    return field
end