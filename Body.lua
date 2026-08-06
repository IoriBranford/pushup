local CollisionMask = require "CollisionMask"
local RaycastCollision3D = require "RaycastCollision3D"
local BodyLayers         = require "BodyLayers"

---@class Body
---@field x number
---@field y number
---@field z number
---@field floorz number
---@field floorbody Body
---@field penex number?
---@field peney number?
---@field penez number?
---@field hitvelx number?
---@field hitvely number?
---@field hitvelz number?
---@field velx number
---@field vely number
---@field velz number
---@field speed number
---@field bodyinlayers CollisionLayerMask
---@field bodyhitslayers CollisionLayerMask
---@field bodyheight number
---@field bodyradius number
---@field gravity number
---@field mass number
---@field paused boolean
---@field disappeared boolean
local Body = {}

function Body:initLayerMasks()
    if type(self.bodyinlayers) == "string" then
        self.bodyinlayers = CollisionMask.parse(self.bodyinlayers)
    end
    if type(self.bodyhitslayers) == "string" then
        self.bodyhitslayers = CollisionMask.parse(self.bodyhitslayers)
    end

    self.bodyinlayers = self.bodyinlayers or 0
    self.bodyhitslayers = self.bodyhitslayers or 0
    BodyLayers:add(self)
end

function Body:init()
    self.x = self.x or 0
    self.y = self.y or 0
    self.z = self.z or 0
    self.velx = self.velx or 0
    self.vely = self.vely or 0
    self.velz = self.velz or 0
    self.speed = self.speed or 1
    self.bodyheight = self.bodyheight or 1
    self.bodyradius = self.bodyradius or 1
    self.gravity = self.gravity or 0
    self.mass = self.mass or 1
    Body.initLayerMasks(self)

    -- if self.points then
    --     local _, rsq = math.farthestpoint(self.points, 0, 0)
    --     assert(#self.points >= 6, self.id)
    --     self.bodyradius = math.sqrt(rsq)
    --     self.points.outward = math.polysignedarea(self.points) < 0
    -- elseif self.tile then
    --     local shapes = self.tile.shapes
    --     if shapes then
    --         for _, shape in ipairs(shapes) do
    --             if shape.shape == "polygon" and shape.collidable then
    --                 Body.initPolygonBody(self, shape.points, shape.x, shape.y)
    --                 break
    --             end
    --         end
    --     end
    -- end
end

function Body:hasDisappeared()
    return self.disappeared
end

function Body:disappear()
    self.disappeared = true
end

function Body:release()
end

---@param points number[]
---@param dx number
---@param dy number
function Body:initPolygonBody(points, dx, dy)
    dx = dx or 0
    dy = dy or 0
    local _, rsq = math.farthestpoint(points, -dx, -dy)
    self.bodyradius = math.sqrt(rsq)
    self.points = {}
    self.points.outward = math.polysignedarea(points) < 0
    assert(#points >= 6, "Three or more 2D points required for a polygon shape")
    for i = 2, #points, 2 do
        local px, py = points[i-1], points[i]
        self.points[i-1] = px + dx
        self.points[i] = py + dy
    end
end

function Body:accelerate(ax, ay)
    self.velx = self.velx + ax
    self.vely = self.vely + ay
end

function Body:forceTowardsVelXY(targetvelx, targetvely, force)
    local velx, vely = self.velx, self.vely
    local forcex = (targetvelx - velx)
    local forcey = (targetvely - vely)
    force = force or math.huge
    if math.lensq(forcex, forcey) <= force*force then
        self.velx, self.vely = targetvelx, targetvely
    else
        forcex, forcey = math.norm(forcex, forcey)
        self.velx = velx + forcex * force
        self.vely = vely + forcey * force
    end
end

function Body:forceTowardsVel3(targetvelx, targetvely, targetvelz, force)
    local velx, vely, velz = self.velx, self.vely, self.velz
    local forcex = (targetvelx - velx)
    local forcey = (targetvely - vely)
    local forcez = (targetvelz - velz)
    force = force or math.huge
    if math.lensq(forcex, forcey, forcez) <= force*force then
        self.velx, self.vely, self.velz = targetvelx, targetvely, targetvelz
    else
        forcex, forcey, forcez = math.norm(forcex, forcey, forcez)
        self.velx = velx + forcex * force
        self.vely = vely + forcey * force
        self.velz = velz + forcez * force
    end
end

function Body:accelerateTowardsVelXY(targetvelx, targetvely, mass, e)
    mass = math.max(mass or self.mass or 1, 1)
    e = e or (1/65536)
    local velx, vely = self.velx, self.vely
    velx = velx + (targetvelx - velx) / mass
    vely = vely + (targetvely - vely) / mass
    if math.distsq(velx, vely, targetvelx, targetvely) < e then
        self.velx, self.vely = targetvelx, targetvely
    else
        self.velx, self.vely = velx, vely
    end
end

function Body:accelerateTowardsVel3(targetvelx, targetvely, targetvelz, mass, e)
    mass = math.max(mass or self.mass or 1, 1)
    e = e or (1/256)
    local velx, vely, velz = self.velx, self.vely, self.velz
    velx = velx + (targetvelx - velx) / mass
    vely = vely + (targetvely - vely) / mass
    velz = velz + (targetvelz - velz) / mass
    if math.distsq3(velx, vely, velz, targetvelx, targetvely, targetvelz) < e then
        self.velx, self.vely, self.velz = targetvelx, targetvely, targetvelz
    else
        self.velx, self.vely, self.velz = velx, vely, velz
    end
end

function Body:updateGravity()
    local gravity = self.gravity or 0
    if gravity == 0 then
        return
    end
    self.velz = self.velz - gravity
    local floorz = self.floorz or 0
    if floorz >= self.z + self.velz then
        self.z = floorz
        self.velz = 0
    end
end

function Body:updatePosition()
    self.x = self.x + self.velx
    self.y = self.y + self.vely
    self.z = self.z + self.velz
end

function Body:updateBody()
    if not self.paused then
        Body.updatePosition(self)
        Body.updateGravity(self)
    end
end

function Body:updateVelocityAfterCollision()
    -- TODO support restitution (bounce) as needed
    if (self.penex or 0) ~= 0 then self.velx = 0 end
    if (self.peney or 0) ~= 0 then self.vely = 0 end
    if (self.penez or 0) ~= 0 then self.velz = 0 end
end

function Body:getCollidedPosition()
    local x, y, z, r, h = self.x, self.y, self.z, self.bodyradius, self.bodyheight
    local World = require "World"
    local newx, newy, newz, penex, peney, penez = World.keepCylinderIn(x, y, z, r, h, self)
    return newx, newy, newz, penex, peney, penez
end

function Body:keepInBounds()
    local newx, newy, newz, penex, peney, penez = Body.getCollidedPosition(self)
    self.x, self.y, self.z = newx, newy, newz
    return penex, peney, penez
end

function Body:predictCollisionVelocity()
    local r, h = self.bodyradius, self.bodyheight
    local nextx = self.x + self.velx
    local nexty = self.y + self.vely
    local nextz = self.z + self.velz
    local World = require "World"
    local newx1, newy1, newz1, penex, peney, penez = World.keepCylinderIn(nextx, nexty, nextz, r, h, self)
    return newx1 - nextx, newy1 - nexty, newz1 - nextz, penex, peney, penez
end

function Body:getVelocityWithinBounds()
    local cvelx, cvely, cvelz, penex, peney, penez = Body.predictCollisionVelocity(self)
    return self.velx + cvelx, self.vely + cvely, self.velz + cvelz, penex, peney, penez
end

local function testBodyCollision_polygonAndCircle(polygon, circle)
    local points = polygon.points
    local otherx, othery = circle.x - polygon.x, circle.y - polygon.y
    if math.pointinpolygon(points, otherx, othery) then
        return true
    end
    local nearestx, nearesty = math.nearestpolygonpoint(points, otherx, othery)
    return nearestx and nearesty
        and math.distsq(otherx, othery, nearestx, nearesty) <= circle.bodyradius
end

function Body:predictBodyCollision(other)
    if self == other then
        return
    end
    if self.z + self.velz <= other.z + other.velz + other.bodyheight
        and other.z + other.velz <= self.z + self.velz + self.bodyheight
        and math.testcircles(self.x + self.velx, self.y + self.vely, self.bodyradius,
            other.x + other.velx, other.y + other.vely, other.bodyradius)
    then
        if self.points and not other.points then
            return testBodyCollision_polygonAndCircle(self, other)
        elseif other.points then
            return testBodyCollision_polygonAndCircle(other, self)
        end
        return true
    end
end

function Body:testBodyCollision(other)
    if self ~= other
        and self.z <= other.z + other.bodyheight
        and other.z <= self.z + self.bodyheight
        and math.testcircles(self.x, self.y, self.bodyradius, other.x, other.y, other.bodyradius)
    then
        if self.points and not other.points then
            return testBodyCollision_polygonAndCircle(self, other)
        elseif other.points then
            return testBodyCollision_polygonAndCircle(other, self)
        end
        return true
    end
end

function Body:getCirclePenetration(x, y, r)
    local distsq = math.testcircles(self.x, self.y, self.bodyradius, x, y, r)
    if not distsq then
        return
    end

    local points = self.points
    if not points then
        local radii = self.bodyradius + r
        if distsq <= 0 then
            return radii, 0
        end
        local dist = math.sqrt(distsq)
        local pene = radii - dist
        local dx, dy = self.x - x, self.y - y
        local nx, ny = dx/dist, dy/dist
        return nx*pene, ny*pene
    end

    -- get if point in polygon
    x, y = x - self.x, y - self.y
    local inside = math.pointinpolygon(points, x, y)
    if not points.outward then
        inside = not inside
    end
    -- get nearest point on polygon
    local nearestx, nearesty, nearesti, nearestj = math.nearestpolygonpoint(points, x, y)
    local nearestdsq = nearestx and nearesty and math.distsq(x, y, nearestx, nearesty)
    -- if not in polygon, and nearest point farther than radius, then no collision
    if not inside and (not nearestdsq or nearestdsq > r*r) then
        return
    end

    -- move circle out of polygon in direction of nearest point
    local dist = math.sqrt(nearestdsq)
    local nx, ny
    if dist == 0 then
        local x1, y1 = points[nearesti-1], points[nearesti]
        local x2, y2 = points[nearestj-1], points[nearestj]
        nx, ny = math.norm(math.rot90(x2-x1, y2-y1, 1))
    else
        nx, ny = (nearestx - x)/dist, (nearesty - y)/dist
    end
    local pene = (inside and -r or r) - dist
    return nx * pene, ny * pene

    -- TODO if needed, collision vs concave corners
end

local function getCylinderPenetration_outward(self, cylx, cyly, cylz, cylr, cylh)
    local selftop = self.z + self.bodyheight
    if cylz + cylh >= self.z and selftop >= cylz then
        local iz, iz2 = math.max(cylz, self.z), math.min(cylz+cylh, selftop)
        local penez = iz == cylz and iz - iz2 or iz2 - iz
        local penex, peney = Body.getCirclePenetration(self, cylx, cyly, cylr)
        if penex and peney and math.lensq(penex, peney) > penez*penez then
            return nil, nil, penez
        end
        return penex, peney
    end
end

local function getCylinderPenetration_inward(self, cylx, cyly, cylz, cylr, cylh)
    local penex, peney, penez
    if cylz <= self.z then
        penez = cylz - self.z
    elseif cylz + cylh >= self.z + self.bodyheight then
        penez = (cylz + cylh) - (self.z + self.bodyheight)
    end
    penex, peney = Body.getCirclePenetration(self, cylx, cyly, cylr)
    return penex, peney, penez
end

---@param cylx number
---@param cyly number
---@param cylz number
---@param cylr number
---@param cylh number
---@return number? penex x penetration. Non-0 = penetrating; 0 = touching; nil = no contact
---@return number? peney y penetration. Non-0 = penetrating; 0 = touching; nil = no contact
---@return number? penez z penetration. Non-0 = penetrating; 0 = touching; nil = no contact
function Body:getCylinderPenetration(cylx, cyly, cylz, cylr, cylh)
    if self.points and not self.points.outward then
        return getCylinderPenetration_inward(self, cylx, cyly, cylz, cylr, cylh)
    end
    return getCylinderPenetration_outward(self, cylx, cyly, cylz, cylr, cylh)
end

---@param other Body
function Body:collideWith(other)
    if 0 == bit.band(self.bodyhitslayers, other.bodyinlayers) then
        return
    end
    local penex, peney, penez = Body.getCylinderPenetration(other, self.x, self.y, self.z, self.bodyradius, self.bodyheight)
    self.x = self.x - (penex or 0)
    self.y = self.y - (peney or 0)
    self.z = self.z - (penez or 0)
    return penex, peney, penez
end

---@param raycast Raycast
---@return number? projx raycast point closest to the circle center 
---@return number? projy raycast point closest to the circle center
---@return number? projdsq square dist from proj point to circle center
function Body:testCircleWithRaycast(raycast)
    local x, y, r = self.x, self.y, self.bodyradius
    local rx, ry = raycast.x, raycast.y
    local rdx, rdy = raycast.dx, raycast.dy
    local rx2, ry2 = rx + rdx, ry + rdy

    local projx, projy = math.projpointsegment(x, y, rx, ry, rx2, ry2)
    local projdsq = math.distsq(projx, projy, x, y)
    if projdsq <= r*r then
        return projx, projy, projdsq
    end
end

Body.collideWithRaycast3 = RaycastCollision3D.collide

function Body:getCylinderFloorZ(x, y, z, r, h)
    local floorz = self.z
    local points = self.points
    local outward = not points or points.outward
    if outward then
        floorz = floorz + self.bodyheight
    end
    if z < floorz then
        -- underneath
        return
    end

    local penex, peney = Body.getCirclePenetration(self, x, y, r)
    if outward and not penex and not peney then
        return
    end
    return floorz, penex, peney
end

---@param them Body
---@param time number
function Body:isInTheirWay(them, time)
    if self.z + self.bodyheight < them.z
    or them.z + self.bodyheight < self.z then
        return false
    end
    time = time or 1
    local x, y = self.x, self.y
    local theirx, theiry = them.x, them.y
    local towardmex, towardmey = x - theirx, y - theiry
    local ourradii = self.bodyradius + them.bodyradius
    local theirvelx, theirvely = them.velx*time, them.vely*time
    local distxy = math.len(towardmex, towardmey)

    -- cos * speed * time * dist
    -- = speed toward me * time * dist
    -- = dist they will move toward me in time * dist from me
    local dot = math.dot(theirvelx, theirvely, towardmex, towardmey)
    if dot < distxy * (distxy - ourradii) then
        return false
    end
    return true
end

function Body:draw(fixedfrac)
    fixedfrac = fixedfrac or 0
    local x, y = self.x + self.velx * fixedfrac, self.y + self.vely * fixedfrac
    local z = self.z + self.velz * fixedfrac
    love.graphics.setColor(.5, .5, 1)
    local bodyradius, bodyheight = self.bodyradius, self.bodyheight
    local screeny = y - z
    love.graphics.circle("line", x, screeny, bodyradius)
    love.graphics.circle("line", x, screeny - bodyheight, bodyradius)
    love.graphics.line(x - bodyradius, screeny, x - bodyradius, screeny - bodyheight)
    love.graphics.line(x + bodyradius, screeny, x + bodyradius, screeny - bodyheight)
    local points = self.points
    if points then
        love.graphics.push()
        love.graphics.translate(0, -z)
        self:drawPolygon()
        love.graphics.translate(0, -bodyheight)
        self:drawPolygon()
        love.graphics.translate(self.x, self.y)
        for i = 2, #points, 2 do
            local px, py = points[i-1], points[i]
            love.graphics.line(px, py, px, py + bodyheight)
        end
        love.graphics.pop()
    end
end

function Body:drawPolygon()
end

return Body