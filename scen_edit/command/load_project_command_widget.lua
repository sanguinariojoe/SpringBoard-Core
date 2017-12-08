LoadProjectCommandWidget = Command:extends{}
LoadProjectCommandWidget.className = "LoadProjectCommandWidget"

local maxinteger = 16777215
local floatSize = 4

function LoadProjectCommandWidget:init(path, isZip)
    self.className = "LoadProjectCommandWidget"
    self.path = path
    self.isZip = isZip
end

-- function LoadProjectCommandWidget:__ReloadInto(game, mapName)
-- 	local scriptTxt = StartScript.GenerateScriptTxt({
--         game = game,
--         mapName = mapName,
--     })
-- 	Spring.Echo(scriptTxt)
-- 	Spring.Reload(scriptTxt)
-- end

function LoadProjectCommandWidget:execute()
    if not self.isZip then
        SB.projectDir = self.path
        Log.Notice("set widget project dir:", SB.projectDir)
        SB.commandManager:execute(WidgetSetProjectDirCommand(SB.projectDir), true)
    end

    -- Check if archive exists
    if not self:__CheckExists() then
        return
    end

    -- Check if we're using the correct editor and map
    if not self:__CheckCorrectEditorAndMap() then
        return
    end

    local texturePath
    if self.isZip then
        Log.Notice("Loading archive: " .. self.path .. " ...")
        self:__LoadArchive(self.path)
        texturePath = "texturemap/"
    else
        Log.Notice("Loading project: " .. self.path .. " ...")
        texturePath = Path.Join(self.path, "texturemap/")
    end

    local modelData = self:__LoadFile("model.lua")
    local heightmapData = self:__LoadFile("heightmap.data")
    Log.Notice("#heightmapData = " .. #heightmapData)
    local guiState = self:__LoadFile("sb_gui.lua")

    -- Start loading the heightmap. The heightmap data can be quite large,
    -- exceding the message size we can safely handle.
    -- e.g. A 32x32 map has 2049x2049 = 4198401 floats, which means
    -- 16793604 bytes, greater than the 16777215 bytes we can pack/unpack.
    -- Therefore, we are spliting the heightmap in pieces
    local pieces = self:__SplitHeightmapData(heightmapData)
    local i, piece
    for i, piece in ipairs(pieces) do
        Log.Notice("piece = " .. i .. " (" .. piece.x1 .. " - " .. piece.x2 .. ")")
        SB.commandManager:execute(LoadMapCommand(piece.heightmapData,
                                                 piece.x1, piece.x2,
                                                 piece.z1, piece.z2))
    end
    if not hasScenarioFile and Spring.GetGameRulesParam("sb_gameMode") == "play" then
        SB.commandManager:execute(StartCommand())
    end
    SB.commandManager:execute(LoadModelCommand(modelData))
    SB.commandManager:execute(LoadTextureCommand(texturePath), true)
    SB.commandManager:execute(LoadGUIStateCommand(guiState), true)

    -- Try to make room for the commands execution
    collectgarbage()
    Log.Notice("Load complete.")
end

function LoadProjectCommandWidget:__CheckExists()
    if self.isZip then
        if not VFS.FileExists(self.path, VFS.RAW) then
            Log.Error("Archive doesn't exist: " .. self.path)
            return false
        end
    else
        if not SB.DirExists(self.path, VFS.RAW) then
            Log.Error("Project doesn't exist: " .. self.path)
            return false
        end
    end
    return true
end

function LoadProjectCommandWidget:__CheckCorrectEditorAndMap()
    if self.isZip then
        self:__LoadArchive(self.path)
    end

    local sbInfo = self:__LoadFile("sb_info.lua")
    local sbInfo = loadstring(sbInfo)()
    local game, mapName = sbInfo.game, sbInfo.mapName
    if game.name ~= Game.gameName or mapName ~= Game.mapName then
        Log.Notice("Different game (" .. game.name .. " " .. game.version ..
            ") or map (" .. mapName .. "). Reloading into project...")

        local scriptTxt = self:__LoadFile("script-dev.txt")
        Spring.Reload(scriptTxt)

        return false
    end
    return true
end

function LoadProjectCommandWidget:__LoadFile(fname)
    if self.isZip then
        return VFS.LoadFile(fname, VFS.ZIP)
    else
        return VFS.LoadFile(Path.Join(self.path, fname), VFS.RAW)
    end
end

function LoadProjectCommandWidget:__LoadArchive(path)
    if SB.loadedArchive ~= path then
        if VFS.UnmapArchive then
            VFS.UnmapArchive(SB.loadedArchive)
        end
        VFS.MapArchive(path)
        SB.loadedArchive = path
    end
end

function LoadProjectCommandWidget:__SplitHeightmapData(heightmapData)
    local overhead = 128
    local nx = Game.mapSizeX / Game.squareSize
    local nz = Game.mapSizeZ / Game.squareSize
    local len = (nx + 1) * (nz + 1) * floatSize
    local n_pieces = 1
    while len + overhead >= maxinteger do
        n_pieces = n_pieces * 2
        nx = nx / 2
        len = (nx + 1) * (nz + 1) * floatSize
    end
    local pieces = {}
    for i=1,n_pieces do
        local x1 = Game.mapSizeX / n_pieces * (i - 1)
        local x2 = Game.mapSizeX / n_pieces * i
        pieces[#pieces + 1] = {
            heightmapData = heightmapData:sub(
                nx * (nz + 1) * floatSize * (i - 1) + 1, len * i),
            x1 = x1,
            x2 = x2,
            z1 = 0,
            z2 = Game.mapSizeZ
        }
    end

    return pieces
end
