Model = LCS.class{}
SB_MODEL_DIR = Path.Join(SB_DIR, "model/")
SB.IncludeDir(SB_MODEL_DIR)
SB_MODEL_OBJECT_DIR = Path.Join(SB_MODEL_DIR, "object/")
SB.IncludeDir(SB_MODEL_OBJECT_DIR)

function Model:init()
    self._lua_rules_pre = "scen_edit"

    self.areaManager = AreaManager()
    self.variableManager = VariableManager()
    self.triggerManager = TriggerManager()
    self.teamManager = TeamManager()
    self.scenarioInfo = ScenarioInfo()
    self.terrainManager = TerrainManager()
    if Script.GetName() == "LuaUI" then
        self.textureManager = TextureManager()
        self.assetsManager = AssetsManager()
        self.brushManagers = BrushManagers()
        self.extensionsManager = ExtensionsManager()
    end

    self:LoadGameSettings()
end

--clears all units, areas, triggers, etc.
function Model:Clear()
    --self.areaManager:clear()
    self.variableManager:clear()
    self.triggerManager:clear()
    self.teamManager:clear()
    self.scenarioInfo:clear()

    -- "CLEAR MODEL"
    for _, objectS11N in pairs(s11n.s11nByName) do
        objectS11N:Clear()
    end

    for _, projectileID in pairs(Spring.GetProjectilesInRectangle(0, 0, Game.mapSizeX,  Game.mapSizeZ)) do
        Spring.SetProjectilePosition(projectileID, math.huge, math.huge, math.huge)
        Spring.SetProjectileCollision(projectileID)
    end

    if not Script.GetName() == "LuaUI" then
        SB.commandManager:execute(ClearUndoRedoCommand())
    end
end

function Model:Serialize()
    local mission = {}

    mission.meta = self:GetMetaData()
    for name, objectS11N in pairs(s11n.s11nByName) do
        mission[name] = objectS11N:Get()
    end
    return mission
end

function Model:Save(fileName)
    local mission = self:Serialize()
    table.save(mission, fileName)
end

function Model:Load(mission)
    -- TODO: some serialization should persist through save/load (and belongs to .meta)
    -- Right now everything will be reset each Start/Stop
    for name, objectS11N in pairs(s11n.s11nByName) do
        objectS11N:Add(mission[name])
    end

    self:SetMetaData(mission.meta)
end

--returns a table that holds triggers, areas and other non-engine content
function Model:GetMetaData()
    return {
        triggers = self.triggerManager:serialize(),
        variables = self.variableManager:serialize(),
        teams = self.teamManager:serialize(),
        info = self.scenarioInfo:serialize(),
    }
end

--sets triggers, areas, etc.
function Model:SetMetaData(meta)
    self.variableManager:load(meta.variables)
    if meta.teams then
        self.teamManager:load(meta.teams)
    end
    self.scenarioInfo:load(meta.info)
    self.triggerManager:load(meta.triggers)
end

function Model:LoadGameSettings()
    self.game = {}
    pcall(function()
        local _game = loadstring(VFS.LoadFile("sb_settings.lua"))
        setfenv(_game, getfenv())
        _game = _game()
        self.game = _game
    end)
    self.game.defaultAssetsFolder = self.game.defaultAssetsFolder or "core/"
end
