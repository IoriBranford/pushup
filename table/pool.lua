local pool = {}

function table.new()
    local t = pool[#pool] or {}
    pool[#pool] = nil
    return t
end

function table.pool(t)
    if type(t) ~= "table" then return end
    pool[#pool+1] = t
    for k in pairs(t) do
        t[k] = nil
    end
    setmetatable(t)
end