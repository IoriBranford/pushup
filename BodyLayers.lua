local CollisionMask = require "CollisionMask"
local ihash         = require "ihash"

---@class BodyLayers
local BodyLayers = {} ---@type Body[][]

function BodyLayers:clear()
    for i = #self, 1, -1 do
        self[i] = nil
    end
end

function BodyLayers:eachLayer(mask, only)
    local i = 0
    local function iter()
        if mask == 0 then return end

        i = i + 1
        if i > #self then return end

        local bt = bit.band(mask, 1) ~= 0
        mask = bit.rshift(mask, 1)
        return i, self[i], bt
    end
    if only then
        return function()
            while i <= #self
            and bit.band(mask, 1) ~= only do
                mask = bit.rshift(mask, 1)
                i = i + 1
            end
            return iter()
        end
    end
    return iter
end

---@param solid Body
function BodyLayers:add(solid)
    local mask = solid.bodyinlayers
    if not mask or mask == 0 then return end

    local masks = CollisionMask.getKnownMasks()
    while #self < #masks do
        self[#self+1] = {}
    end

    for _, layer, bt in self:eachLayer(mask) do
        if bt then
            ihash.add(layer, solid)
        else
            ihash.remove(layer, solid)
        end
    end
end

function BodyLayers:prune(dead)
    for _, layer in ipairs(self) do
        ihash.prune(layer, dead)
    end
end

return BodyLayers