local math3 = require "math123.math3"
local math2 = require "math123.math2"
local RaycastCollision3D = {}

local function collideCylinderSide(self, raycast, hitx, hity, hitside)
    local x, y, z, r, h = self.x, self.y, self.z, self.bodyradius, self.bodyheight
    local rx, ry, rz = raycast.x, raycast.y, raycast.z
    local rdx, rdy, rdz = raycast.dx, raycast.dy, raycast.dz
    local rx2, ry2, rz2 = rx + rdx, ry + rdy, rz + rdz

    local hitnx, hitny = math2.norm(hitx - x, hity - y)
    hitnx, hitny = hitnx*hitside, hitny*hitside
    local _, _, hitz = math3.intersectsegmentplane(
        rx, ry, rz, rx2, ry2, rz2,
        hitnx, hitny, 0, -math2.dot(hitx, hity, hitnx, hitny)
    )

    if hitz and z <= hitz and hitz <= z+h then
        raycast.hitx = hitx
        raycast.hity = hity
        raycast.hitz = hitz
        raycast.hitnx = hitnx
        raycast.hitny = hitny
        raycast.hitnz = 0
        raycast.hitdist = math3.dist(rx, ry, rz, hitx, hity, hitz)
        local d = math2.det(x - rx, x - ry, rdx, rdy)
        raycast.hitwallx, raycast.hitwally = math2.rot90(hitx - x, hity - y, d)
        raycast.hitwallx2, raycast.hitwally2 = math2.rot90(hitx - x, hity - y, -d)
        raycast.hitwallx = raycast.hitwallx + raycast.hitx
        raycast.hitwally = raycast.hitwally + raycast.hity
        raycast.hitwallx2 = raycast.hitwallx2 + raycast.hitx
        raycast.hitwally2 = raycast.hitwally2 + raycast.hity
        return true
    end
end

local function collideCylinderEnd(self, raycast, hitnz, hitd)
    local x, y, z, r, h = self.x, self.y, self.z, self.bodyradius, self.bodyheight
    local rx, ry, rz = raycast.x, raycast.y, raycast.z
    local rdx, rdy, rdz = raycast.dx, raycast.dy, raycast.dz
    local rx2, ry2, rz2 = rx + rdx, ry + rdy, rz + rdz

    local hitx, hity, hitz = math3.intersectsegmentplane(
        rx, ry, rz, rx2, ry2, rz2,
        0, 0, hitnz, hitd)

    if hitx and math2.distsq(hitx, hity, x, y) <= r*r then
        raycast.hitx = hitx
        raycast.hity = hity
        raycast.hitz = hitz
        raycast.hitnx = 0
        raycast.hitny = 0
        raycast.hitnz = hitnz
        raycast.hitdist = math3.dist(rx, ry, rz, hitx, hity, hitz)
        return true
    end
end

local function collideCylinder(self, raycast, projx, projy, projdsq)
    local z, r, h = self.z, self.bodyradius, self.bodyheight
    local rdx, rdy, rdz = raycast.dx, raycast.dy, raycast.dz
    local rlenxy = math2.len(rdx, rdy)
    local rnx, rny = rdx/rlenxy, rdy/rlenxy
    local projtohitdist = math.sqrt(r*r - projdsq)
    local canhitside = raycast.canhitside
    if canhitside < 0 then
        -- hitx,hity is the far intersection
        -- hitwall is a tangent line
        local hitx = projx + rnx * projtohitdist
        local hity = projy + rny * projtohitdist

        if collideCylinderSide(self, raycast, hitx, hity, -1) then
            return true
        end
        if rdz < 0
        and collideCylinderEnd(self, raycast, 1, -z) then
            return true
        end
        if rdz > 0
        and collideCylinderEnd(self, raycast, -1, z+h) then
            return true
        end
    else
        -- hitx,hity is the near intersection
        local hitx = projx - rnx * projtohitdist
        local hity = projy - rny * projtohitdist

        if rdz < 0
        and collideCylinderEnd(self, raycast, 1, -z-h) then
            return true
        end
        if rdz > 0
        and collideCylinderEnd(self, raycast, -1, z) then
            return true
        end
        if collideCylinderSide(self, raycast, hitx, hity, 1) then
            return true
        end
    end
end

local function collidePolyWalls(self, raycast)
    local points = self.points
    local x, y, z, r, h = self.x, self.y, self.z, self.bodyradius, self.bodyheight
    local rx, ry, rz = raycast.x, raycast.y, raycast.z
    local rdx, rdy, rdz = raycast.dx, raycast.dy, raycast.dz
    local rx2, ry2, rz2 = rx + rdx, ry + rdy, rz + rdz

    local rlenxy = math2.len(rdx, rdy)
    local rnx, rny = rdx/rlenxy, rdy/rlenxy
    local canhitside = raycast.canhitside

    rx, ry = rx - x, ry - y
    rx2, ry2 = rx2 - x, ry2 - y
    local hitdsq = raycast.hitdist
    hitdsq = hitdsq and hitdsq*hitdsq or 0x10000000
    local hitx, hity, hitz
    local hitnx, hitny, hitnz
    local hitwallx, hitwally, hitwallx2, hitwally2, hitside
    local ax, ay = points[#points-1], points[#points]
    for i = 2, #points, 2 do
        local bx, by = points[i-1], points[i]
        local walldx, walldy = bx-ax, by-ay
        local walldir = math2.det(rdx, rdy, walldx, walldy)
        if walldir * canhitside >= 0 then
            local wallnx, wallny = math2.norm(math2.rot90(walldx, walldy, walldir))
            local hx, hy, hz, hx2, hy2 = math3.intersectsegmentplane(
                rx, ry, rz,
                rx2, ry2, rz2,
                wallnx, wallny, 0,
                -math2.dot(ax, ay, wallnx, wallny))

            if hz and z <= hz and hz <= z+h then
                local hitdotwall = math2.dot(hx - ax, hy - ay, walldx, walldy)
                if 0 <= hitdotwall and hitdotwall <= math2.lensq(walldx, walldy) then
                    if hx2 and hy2 then
                        if math2.dot(rnx, rny, wallnx, wallny) < 0 then
                            hx, hy = bx, by
                        else
                            hx, hy = ax, ay
                        end
                    end
                    local dsq = math3.distsq(rx, ry, rz, hx, hy, hz)
                    if dsq < hitdsq then
                        hitdsq = dsq
                        hitx, hity, hitz = hx, hy, hz
                        hitnx, hitny, hitnz = wallnx, wallny, 0
                        hitwallx, hitwally = ax, ay
                        hitwallx2, hitwally2 = bx, by
                        hitside = walldir
                    end
                end
            end
        end
        ax, ay = bx, by
    end

    if hitx then
        raycast.hitdist = math.sqrt(hitdsq)
        raycast.hitx = hitx + x
        raycast.hity = hity + y
        raycast.hitz = hitz
        raycast.hitnx = hitnx
        raycast.hitny = hitny
        raycast.hitnz = hitnz
        raycast.hitwallx = hitwallx + x
        raycast.hitwally = hitwally + y
        raycast.hitwallx2 = hitwallx2 + x
        raycast.hitwally2 = hitwally2 + y
        raycast.hitside = hitside
        return true
    end
end

local function collidePolyFloor(self, raycast, hitnz, hitd)
    local rx, ry, rz = raycast.x, raycast.y, raycast.z
    local rdx, rdy, rdz = raycast.dx, raycast.dy, raycast.dz
    local rx2, ry2, rz2 = rx + rdx, ry + rdy, rz + rdz
    local hitx, hity, hitz = math3.intersectsegmentplane(rx, ry, rz, rx2, ry2, rz2, 0, 0, hitnz, hitd)
    if not hitx then
        return
    end
    local hitdist = raycast.hitdist
    local lasthitdsq = hitdist and (hitdist*hitdist) or 0x10000000
    local hitdsq = math3.distsq(rx, ry, rz, hitx, hity, hitz)
    if hitdsq >= lasthitdsq then
        return
    end
    if math2.pointinpolygon(self.points, hitx - self.x, hity - self.y) then
        raycast.hitdist = math.sqrt(hitdsq)
        raycast.hitx = hitx
        raycast.hity = hity
        raycast.hitz = hitz
        raycast.hitnx = 0
        raycast.hitny = 0
        raycast.hitnz = hitnz
        return true
    end
end

local function collidePoly(self, raycast)
    local z, h = self.z, self.bodyheight
    local rdz = raycast.dz
    local canhitside = raycast.canhitside
    local floorz, floornz
    if rdz < 0 then
        floornz = 1
        floorz = canhitside < 0 and -z or (-z-h)
    elseif rdz > 0 then
        floornz = -1
        floorz = canhitside < 0 and (z+h) or z
    end

    local collided = collidePolyWalls(self, raycast)
    collided = floornz
        and collidePolyFloor(self, raycast, floornz, floorz)
        or collided
    return collided
end

---@param raycast Raycast
function RaycastCollision3D:collide(raycast)
    if bit.band(self.bodyinlayers, raycast.hitslayers) == 0 then
        return
    end

    local Body = require "Body"
    local projx, projy, projdsq = Body.testCircleWithRaycast(self, raycast)
    if not projx then
        return
    end

    local points = self.points
    if points then
        return collidePoly(self, raycast)
    end
    return collideCylinder(self, raycast, projx, projy, projdsq)
end

return RaycastCollision3D