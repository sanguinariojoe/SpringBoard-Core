LoadMapCommand = Command:extends{}
LoadMapCommand.className = "LoadMapCommand"

local floatSize = 4

function LoadMapCommand:init(deltaMap, x1, x2, z1, z2)
    self.className = "LoadMapCommand"
    self.deltaMap = deltaMap
    self.x1 = x1 or 0
    self.x2 = x2 or Game.mapSizeX
    self.z1 = z1 or 0
    self.z2 = z2 or Game.mapSizeZ
end

function LoadMapCommand:execute()
    Spring.RevertHeightMap(self.x1, self.z1, self.x2, self.z2, 1)
    Spring.SetHeightMapFunc(function()
        -- Log.Notice("HEIGHTMAP LOAD")
        if self.deltaMap == nil or #self.deltaMap == 0 then
            return
        end
        local data = VFS.UnpackF32(self.deltaMap, 1, #self.deltaMap / floatSize)
        local i = 1
        for x = self.x1, self.x2, Game.squareSize do
            for z = self.z1, self.z2, Game.squareSize do
                Spring.SetHeightMap(x, z, data[i])
                i = i + 1
            end
        end
        -- Log.Notice("HEIGHTMAP LOAD DONE")
    end)
end
