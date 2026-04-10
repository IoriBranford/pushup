local select = select

local Table = {}

function Table.New()
    local t = Table[#Table] or {}
    Table[#Table] = nil
    return t
end

function Table.NewArray(...)
    local n = select("#", ...)
    local t = Table.New()
    for i = 1, n do
        t[i] = select(i, ...)
    end
    return t
end

function Table.NewHash(...)
    local t = Table.New()
    Table.PutKV(...)
    return t
end

function Table.PutKV(t, ...)
    local n = select("#", ...)
    for i = 2, n, 2 do
        local k = select(i-1, ...)
        if k ~= nil then
            t[k] = select(i, ...)
        end
    end
end

function Table.Clear(t)
    if not t then return end
    for k in pairs(t) do
        t[k] = nil
    end
end

function Table.Free(t)
    Table.Clear(t)
    Table[#Table+1] = t
end

return Table