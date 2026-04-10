local CollisionMask = {}

---@alias CollisionLayerIndex integer
---@alias CollisionLayerName string
---@alias CollisionLayerMask integer

---@type {[CollisionLayerIndex]: CollisionLayerName, [CollisionLayerName]: CollisionLayerMask}
local layermasks = {}

---@param names string space-separated
function CollisionMask.parse(names)
    local mask = 0
    for name in names:gmatch("%S+") do
        mask = bit.bor(mask, CollisionMask.get(name))
    end
    return mask
end

---@param name string
function CollisionMask.get(name)
    local mask = layermasks[name]
    if not mask then
        mask = bit.lshift(1, #layermasks)
        layermasks[#layermasks+1] = name
        layermasks[name] = mask
    end
    return mask
end

---@param ... CollisionLayerName|CollisionLayerIndex
function CollisionMask.merge(...)
    local mask = 0
    for i = 1, select("#", ...) do
        local layer = select(i, ...)
        local layermask = CollisionMask.get(layer)
        mask = bit.bor(mask, layermask)
    end
    return mask
end

---@param mask CollisionLayerMask
---@param ... CollisionLayerName|CollisionLayerIndex
function CollisionMask.testAll(mask, ...)
    for i = 1, select("#", ...) do
        local layer = select(i, ...)
        local layermask = CollisionMask.get(layer)
        mask = bit.band(mask, layermask)
    end
    return mask
end

---@param mask CollisionLayerMask
---@param ... CollisionLayerName|CollisionLayerIndex
function CollisionMask.testAny(mask, ...)
    local layersmask = 0
    for i = 1, select("#", ...) do
        local layer = select(i, ...)
        local layermask = CollisionMask.get(layer)
        layersmask = bit.bor(layersmask, layermask)
    end
    return bit.band(mask, layersmask)
end

local names = {}
function CollisionMask.debugPrint(mask)
    for _, name in ipairs(layermasks) do
        local b = layermasks[name]
        if bit.band(mask, b) ~= 0 then
            names[#names+1] = name
        end
    end
    print(table.unpack(names))
    for i = #names, 1, -1 do
        names[i] = nil
    end
end

return CollisionMask