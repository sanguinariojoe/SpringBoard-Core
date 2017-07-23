AbstractEditingState = AbstractState:extends{}

function AbstractEditingState:init(editorView)
	self.editorView = editorView
end

function AbstractEditingState:enterState()
	-- FIXME: self.editorView should always be available
	if self.editorView then
		self.editorView:_OnEnterState(self)
	end
end

function AbstractEditingState:leaveState()
	-- FIXME: self.editorView should always be available
	if self.editorView then
		self.editorView:_OnLeaveState(self)
	end
end

function AbstractEditingState:KeyPress(key, mods, isRepeat, label, unicode)
	if key == KEYSYMS.ESCAPE then
		SB.stateManager:SetState(DefaultState())
		return true
	end

    local _, _, button1, button2, button3 = Spring.GetMouseState()
    if button1 or button2 or button3 then
        return false
    end

	if self.keyListener then
		if self.keyListener(key, mods, isRepeat, label, unicode) then
			return true
		end
	end
	local editor = self.editorView or SB.currentEditor
	if editor then
		if editor:KeyPress(key, mods, isRepeat, label, unicode) then
			return true
		end
	end

	if key == KEYSYMS.TAB then
		if mods.ctrl then
			if mods.shift then
				SB.view.tabbedWindow:PreviousTab()
				return true
			else
				SB.view.tabbedWindow:NextTab()
				return true
			end
		end
	end
	-- TODO: make this configurable
    if key == KEYSYMS.Z and mods.ctrl then
        SB.commandManager:execute(UndoCommand())
    elseif key == KEYSYMS.Y and mods.ctrl then
		SB.commandManager:execute(RedoCommand())
    elseif key == KEYSYMS.S and mods.ctrl and not mods.shift then
        SaveAction():execute()
    elseif key == KEYSYMS.S and mods.ctrl and mods.shift then
        SaveAsAction():execute()
    elseif key == KEYSYMS.O and mods.ctrl then
        LoadAction():execute()
    elseif key == KEYSYMS.E and mods.ctrl then
        ExportAction():execute()
    elseif key == KEYSYMS.I and mods.ctrl then
        ImportAction():execute()
	elseif key == KEYSYMS.N and mods.ctrl then
		NewAction():execute()
    else
        return false
    end
    return true
end

function AbstractEditingState:SetGlobalKeyListener(keyListener)
	self.keyListener = keyListener
end
