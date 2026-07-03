-- Filesystem Operations Module
local FS = {}

function FS.exists(path)
    local f = io.open(path, "r")
    if f then
        f:close()
        return true
    end
    return false
end

function FS.open(path, mode)
    return io.open(path, mode or "r")
end

function FS.read(handle, size)
    if size then
        return handle:read(size)
    end
    return handle:read("*all")
end

function FS.write(handle, content)
    return handle:write(content)
end

function FS.close(handle)
    return handle:close()
end

function FS.writeFile(path, content)
    local f = io.open(path, "w")
    if not f then
        return false, "Cannot open file for writing"
    end
    local success, err = f:write(content)
    f:close()
    if not success then
        return false, err
    end
    return true
end

function FS.readFile(path)
    local f = io.open(path, "r")
    if not f then
        return nil, "Cannot open file for reading"
    end
    local content = f:read("*all")
    f:close()
    return content
end

function FS.appendFile(path, content)
    local f = io.open(path, "a")
    if not f then
        return false, "Cannot open file for appending"
    end
    f:write(content)
    f:close()
    return true
end

function FS.listdir(path)
    local files = {}
    local f = io.popen("ls -la " .. path .. " 2>/dev/null")
    if not f then
        return {}
    end
    for line in f:lines() do
        table.insert(files, line)
    end
    f:close()
    return files
end

function FS.mkdir(path)
    local f = io.popen("mkdir -p " .. path .. " 2>/dev/null")
    if f then
        f:close()
        return true
    end
    return false
end

function FS.rmdir(path)
    local f = io.popen("rm -rf " .. path .. " 2>/dev/null")
    if f then
        f:close()
        return true
    end
    return false
end

function FS.copy(src, dst)
    local f = io.popen("cp -r " .. src .. " " .. dst .. " 2>/dev/null")
    if f then
        f:close()
        return true
    end
    return false
end

function FS.move(src, dst)
    local f = io.popen("mv " .. src .. " " .. dst .. " 2>/dev/null")
    if f then
        f:close()
        return true
    end
    return false
end

function FS.size(path)
    local f = io.open(path, "r")
    if not f then
        return nil
    end
    local size = f:seek("end")
    f:close()
    return size
end

return FS
