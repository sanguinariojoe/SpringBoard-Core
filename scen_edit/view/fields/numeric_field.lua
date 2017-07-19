SB.Include(SB_VIEW_FIELDS_DIR .. "string_field.lua")

NumericField = StringField:extends{}
function NumericField:Update(source)
    local v = string.format(self.format, self.value)
    if source ~= self.editBox and not self.editBox.state.focused then
        self.editBox:SetText(v)
    end
    if source ~= self.lblValue then
        self.lblValue:SetCaption(v)
    end
end

function NumericField:Validate(value)
    local valid, value = self:super("Validate", tonumber(value))
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
    self.__dragSensitivity = 3
    self.__shiftMultiplier = 0.1

    self:__SetDefault("decimals", 2)
    self:__SetDefault("value", 0)
    self:__SetDefault("allowNil", false)

    StringField.init(self, field)

    self.format = "%." .. tostring(self.decimals) .. "f"
    if self.step == nil then
        self.step = 1
        if self.minValue and self.maxValue then
            self.step = (self.maxValue - self.minValue) / 200
        end
    end
    local v = string.format(self.format, self.value)

    self.lblValue:SetCaption(v)
    self.editBox:SetText(v)
    self.button.OnMouseUp = {
        function(...)
            if self.__isDragging then
                self:__StopDragging()
            end
        end
    }
    self.button.OnMouseMove = {
        function(obj, _, _, dx, _, btn, ...)
            if btn ~= 1 then
                return
            end

            -- Save the initial state so it can be reverted back to
            local x, y = Spring.GetMouseState()
            if not self.__initX then
                self.__initX = x
                self.__initY = y
            end
            -- Determine whether we are dragging the mouse
            if not self.__isDragging and
                math.abs(x - self.__initX) > self.__dragSensitivity then
                -- Initialize the dragging state
                self:__StartDragging()
            end
            -- Update dragging
            if self.__isDragging then
                self:__UpdateDragging(dx)
            end
        end
    }
end

-- Overriden
function NumericField:__OnClick()
    if not self.__isDragging then
        StringField.__OnClick(self)
    end
end

function NumericField:__StartDragging()
    -- Set the internal state
    self.__isDragging = true

    -- Set the controls
    self.lblValue.font:SetColor(0.96,0.83,0.09, 1)
    self.lblTitle.font:SetColor(0.96,0.83,0.09, 1)
    self.lblTitle:Invalidate()

    -- Hide the mouse cursor
    SB.SetMouseCursor("empty")

    -- Notify editor that we have started dragging
    self.ev:_OnStartChange(self.name)
end

function NumericField:__StopDragging()
    -- Reset the controls
    self.lblValue.font:SetColor(1, 1, 1, 1)
    self.lblTitle.font:SetColor(1, 1, 1, 1)
    self.lblTitle:Invalidate()

    -- Reset the mouse cursor and position
    SB.SetMouseCursor()
    if self.__initX and self.__initY then
        Spring.WarpMouse(self.__initX, self.__initY)
    end

    -- Reset the internal state
    self.__initX, self.__initY = nil, nil
    self.__isDragging = false

    -- Notify editor that we have stopped dragging
    self.ev:_OnEndChange(self.name)
end

function NumericField:__UpdateDragging(delta)
    -- Apply the shift multiplier if it's pressed
    local _, _, _, shift = Spring.GetModKeyState()
    if shift then
        delta = delta * self.__shiftMultiplier
    end
    -- Set the new value
    local value = self.value + delta * self.step
    self:Set(value, self.button)

    -- Make the mouse fixed
    Spring.WarpMouse(self.__initX, self.__initY)
end
