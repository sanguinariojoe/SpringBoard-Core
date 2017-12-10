LoadModelCommand = Command:extends{}
LoadModelCommand.className = "LoadModelCommand"

function LoadModelCommand:init(modelData)
    self.className = "LoadModelCommand"
    -- Since the introduction of data pack/unpack, is much more efficient to
    -- exchange directly the data LUA table. Also we are reducing the consumed
    -- memory in the synced side.
    self.modelData = modelData
end

function LoadModelCommand:execute()
    -- Depending on the size of the map, and the number of models, a lot of
    -- stuff can be simultaneously executed, with a subsequently large memory
    -- allocation peak. Adding a small delay will separate the commands
    -- execution in 3 different synced steps:
    -- * Heightmap load
    -- * Objects removal
    -- * Objects addition
    GG.Delay.DelayCall(function()
      SB.model:Clear()
    end, {}, 8)
    GG.Delay.DelayCall(function()
      self:Load()
    end, {}, 16)
end

function LoadModelCommand:Load()
    Log.Notice("Loading model...")
    SB.model:Load(self.modelData)
end
