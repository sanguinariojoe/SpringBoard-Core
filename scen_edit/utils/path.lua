Path = Path or {}

function Path.ExtractFileName(path)
    path = path:gsub("\\", "/")
    local lastChar = path:sub(-1)
    if lastChar == "/" then
        path = path:sub(1, -2)
    end
    local pos, b, e, match, init, n = 1, 1, 1, 1, 0, 0
    repeat
        pos, init, n = b, init + 1, n + 1
        b, init, match = path:find("/", init, true)
    until not b
    if n == 1 then
        return path
    else
        return path:sub(pos + 1)
    end
end

function Path.ExtractDir(path)
    path = path:gsub("\\", "/")
    local lastChar = path:sub(-1)
    if lastChar == "/" then
        path = path:sub(1, -2)
    end
    local pos, b, e, match, init, n = 1, 1, 1, 1, 0, 0
    repeat
        pos, init, n = b, init + 1, n + 1
        b, init, match = path:find("/", init, true)
    until not b
    if n == 1 then
        return path
    else
        return path:sub(1, pos)
    end
end

function Path.GetParentDir(dir)
    dir = dir:gsub("\\", "/")
    local lastChar = dir:sub(-1)
    if lastChar == "/" then
        dir = dir:sub(1, -2)
    end
    local pos, b, e, match, init, n = 1, 1, 1, 1, 0, 0
    repeat
        pos, init, n = b, init + 1, n + 1
        b, init, match = dir:find("/", init, true)
    until not b
    if n == 1 then
        return ''
    else
        return dir:sub(1, pos)
    end
end

local function _Join(dir, path)
    dir = dir:gsub("\\", "/")
    path = path:gsub("\\", "/")

    local lastCharDir = dir:sub(-1)
    local firstCharPath = path:sub(1, 1)

    -- No slashes
    if lastCharDir ~= "/" and firstCharPath ~= "/" then
        return dir .. "/" .. path
    -- Two slashes
    elseif lastCharDir == "/" and firstCharPath == "/" then
        return dir .. "/" .. path:sub(2)
    -- One Slash
    else
        return dir .. path
    end
end

function Path.Join(dir, ...)
    local fullPath = dir
    for _, path in pairs({...}) do
        fullPath = _Join(fullPath, path)
    end
    return fullPath
end

function Path.GetExt(path)
    -- Find the last dot in the path
    local index = string.find(path, ".[^.]*$")
    if index then
        return path:sub(index)
    end
end

-- Tests
local lu = luaunit
if not lu then
    return
end

function testExtractFileName()
    lu.assertEquals(Path.ExtractFileName("abc.txt"), "abc.txt")
    lu.assertEquals(Path.ExtractFileName("xyz/abc.txt"), "abc.txt")
    lu.assertEquals(Path.ExtractFileName("xyz\\abc.txt"), "abc.txt")
    lu.assertEquals(Path.ExtractFileName("xyz/efg/abc.txt"), "abc.txt")
    lu.assertEquals(Path.ExtractFileName("xyz/efg\\abc.txt"), "abc.txt")
end

function testExtractDir()
    -- lu.assertEquals(Path.ExtractDir("xyz/abc.txt"), "xyz")
    -- lu.assertEquals(Path.ExtractDir("xyz"), "xyz")
    -- lu.assertEquals(Path.ExtractDir("xyz/"), "xyz")
    -- lu.assertEquals(Path.ExtractDir("xyz\\"), "xyz")
    -- lu.assertEquals(Path.ExtractDir("xyz\\abc.txt"), "xyz")
end

function testJoin()
    lu.assertEquals(Path.Join("folder", "file"), "folder/file")
    lu.assertEquals(Path.Join("folder/", "file"), "folder/file")
end

if lu then
    lu.LuaUnit.run()
end
