---@class Raycast
local Raycast = class()

function Raycast:_init(x, y, z, dx, dy, dz, canhitside, radius, height)
    self.x = x or 0 ---@type number
    self.y = y or 0 ---@type number
    self.z = z or 0 ---@type number
    self.dx = dx or 1 ---@type number
    self.dy = dy or 0 ---@type number
    self.dz = dz or 0 ---@type number
    self.canhitside = canhitside or 0 ---@type number negative = only outsides, positive = only insides, 0 = both sides
    self.hitslayers = 0 ---@type CollisionLayerMask
    self.radius = radius or 0 ---@type number
    self.height = height or 0 ---@type number
    self.hitx = nil ---@type number?
    self.hity = nil ---@type number?
    self.hitz = nil ---@type number?
    self.hitnx = nil ---@type number?
    self.hitny = nil ---@type number?
    self.hitnz = nil ---@type number?
    self.hitdist = nil ---@type number?
    self.hitside = nil ---@type number? negative = from outside, other = from inside
    self.hitbody = nil ---@type Body?
    self.hitwallx = nil ---@type number?
    self.hitwally = nil ---@type number?
    self.hitwallz = nil ---@type number?
    self.hitwallx2 = nil ---@type number?
    self.hitwally2 = nil ---@type number?
    self.hitwallz2 = nil ---@type number?

    self.id = 0
    self.drawz = 0x1000
    self.visible = true
end

function Raycast:draw()
    local x, y = self.x, self.y - self.z
    local x2, y2 = x + self.dx, y + self.dy - self.dz
    if self.hitx and self.hity and self.hitz then
        love.graphics.setColor(1,1,1,.5)
        love.graphics.line(x, y, x2, y2)
        x2, y2 = self.hitx, self.hity - self.hitz
        love.graphics.setColor(1,.5,.5,1)
        love.graphics.line(x, y, x2, y2)
        love.graphics.circle("line", x2, y2, 4)
    else
        love.graphics.setColor(1,1,1,1)
        love.graphics.line(x, y, x2, y2)
    end
end

return Raycast