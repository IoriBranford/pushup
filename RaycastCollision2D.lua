local RaycastCollision2D = {}

---@param raycast Raycast
function RaycastCollision2D:collide(raycast)
    if bit.band(self.bodyinlayers, raycast.hitslayers) == 0 then
        return
    end

    local Body = require "Body"
    local projx, projy, projdsq = Body.testCircleWithRaycast(self, raycast)
    if not projx then
        return
    end

    local canhitside = raycast.canhitside
    local selfx, selfy, selfr = self.x, self.y, self.bodyradius
    local rx, ry = raycast.x, raycast.y
    local rdx, rdy = raycast.dx, raycast.dy
    local rx2, ry2 = rx + rdx, ry + rdy

    local points = self.points
    if not points then
        -- hypot is circle center to intersection point
        -- one side is circle center to proj point
        -- other side is proj point to intersection point
        local rnx, rny = math.norm(rdx, rdy)
        local projtohitdist = math.sqrt(selfr*selfr - projdsq)
        if canhitside < 0 then
            -- hitx,hity is the far intersection
            -- hitwall is a tangent line
            raycast.hitx = projx + rnx * projtohitdist
            raycast.hity = projy + rny * projtohitdist
            raycast.hitside = -1
        else
            -- hitx,hity is the near intersection
            raycast.hitx = projx - rnx * projtohitdist
            raycast.hity = projy - rny * projtohitdist
            raycast.hitside = 1
        end
        if raycast.hitx == selfx and raycast.hity == selfy then
            raycast.hitnx, raycast.hitny = -rnx, -rny
        else
            raycast.hitnx, raycast.hitny = math.norm(raycast.hitx - selfx, raycast.hity - selfy)
        end
        raycast.hitz = raycast.z
        raycast.hitnz = 0
        raycast.hitdist = math.dist(rx, ry, raycast.hitx, raycast.hity)
        local d = math.det(selfx - rx, selfy - ry, rdx, rdy)
        raycast.hitwallx, raycast.hitwally = math.rot90(raycast.hitx - selfx, raycast.hity - selfy, d)
        raycast.hitwallx2, raycast.hitwally2 = math.rot90(raycast.hitx - selfx, raycast.hity - selfy, -d)
        raycast.hitwallx = raycast.hitwallx + raycast.hitx
        raycast.hitwally = raycast.hitwally + raycast.hity
        raycast.hitwallx2 = raycast.hitwallx2 + raycast.hitx
        raycast.hitwally2 = raycast.hitwally2 + raycast.hity
        return true
    end

    rx, ry = rx - selfx, ry - selfy
    rx2, ry2 = rx2 - selfx, ry2 - selfy
    local hitdsq = raycast.hitdist
    hitdsq = hitdsq and hitdsq*hitdsq or 0x10000000
    local hitx, hity, hitnx, hitny, hitwallx, hitwally, hitwallx2, hitwally2, hitside
    local ax, ay = points[#points-1], points[#points]
    for i = 2, #points, 2 do
        local bx, by = points[i-1], points[i]
        local walldir = math.det(rdx, rdy, bx-ax, by-ay)
        if walldir * canhitside >= 0 then
            local hx, hy, hx2, hy2 = math.intersectsegments(rx, ry, rx2, ry2, ax, ay, bx, by)
            if hx and hy then
                if hx2 and hy2 and math.dot(rdx, rdy, hx2, hy2) < math.dot(rdx, rdy, hx, hy) then
                    hx, hy = hx2, hy2
                end
                local dsq = math.distsq(rx, ry, hx, hy)
                if dsq < hitdsq then
                    hitdsq = dsq
                    hitx, hity = hx, hy
                    hitnx, hitny = math.norm(math.rot90(bx-ax, by-ay, walldir))
                    hitwallx, hitwally = ax, ay
                    hitwallx2, hitwally2 = bx, by
                    hitside = walldir
                end
            end
        end
        ax, ay = bx, by
    end

    if hitx then
        raycast.hitdist = math.sqrt(hitdsq)
        raycast.hitx = hitx + selfx
        raycast.hity = hity + selfy
        raycast.hitz = raycast.z
        raycast.hitnx = hitnx
        raycast.hitny = hitny
        raycast.hitnz = 0
        raycast.hitwallx = hitwallx + selfx
        raycast.hitwally = hitwally + selfy
        raycast.hitwallx2 = hitwallx2 + selfx
        raycast.hitwally2 = hitwally2 + selfy
        raycast.hitside = hitside
        return true
    end
end

return RaycastCollision2D