local Body         = require "Body"
local CollisionMask= require "CollisionMask"
local findClosest  = require "findClosest"

---@module 'World'
local World = {}

local allbodies = {} ---@type Body[]
local bodygroups = {} ---@type table<string, Body[]>
local nextid

function World.init(nextid_)
    nextid = nextid_ or 1
    bodygroups.players = {}
    bodygroups.enemies = {}
    bodygroups.items = {}
    bodygroups.projectiles = {}
    bodygroups.container = {}
    bodygroups.solids = allbodies
    bodygroups.triggers = {}
end

function World.addGroup(name)
    if not bodygroups[name] then
        bodygroups[name] = {}
    end
end

function World.quit()
    for _, body in ipairs(allbodies) do
        Body.release(body)
    end
    allbodies = {}
    bodygroups = {}
end

function World.getGroup(group)
    return group == "all" and allbodies or bodygroups[group]
end

function World.addBody(body)
    -- local typ = object.type
    -- if typ then
    --     Database.fillBlanks(object, typ)
    -- end
    -- if not getmetatable(object) then
    --     TiledObject.from(object)
    -- end
    -- local ok, script = false, object.script
    -- if script then
    --     ok, script = pcall(require, script)
    -- end
    -- if not ok then
    --     script = Body
    -- end
    -- if not object.tile then
    --     local tileset, tile = object.tileset, object.tileid
    --     if type(tileset) == "string" then
    --         tile = Assets.getTile(tileset, tile)
    --         if tile then
    --             object:initTile(tile)
    --         end
    --     end
    -- end
    -- local body = script.cast(object) ---@type Body
    -- if not body.id then
    --     body.id = nextid
    --     nextid = nextid + 1
    -- end
    -- body:init()
    -- body:initAseprite()
    -- body.camera = camera
    -- body.solids = bodies
    -- if not body.opponents then
    --     if body.team == "players" then
    --         body.opponents = enemies
    --     else
    --         body.opponents = players
    --     end
    -- end
    -- if body.bodyinlayers ~= 0 then
    --     bodies[#bodies+1] = body
    -- end
    -- local team = groups[body.team]
    -- if team then
    --     team[#team+1] = body
    -- end
    -- if body.team == "triggers" then
    --     local ok, err = body:validateAction()
    --     if not ok then print(err) end
    -- end
    -- if body.initialai then
    --     StateMachine.start(body, body.initialai)
    -- end
    -- body:addToScene(scene)
    allbodies[#allbodies+1] = body
    return body
end
local spawn = World.addBody

function World.addBodies(bodies)
    if not bodies then return end
    for i = 1, #bodies do local body = bodies[i]
        if not body.spawnsmanually then
            spawn(body)
        end
    end
end

local Contacts = {}

function World.nextMove()
    for i = 1, #allbodies do local body = allbodies[i]
        body:updateBody()
    end

    for i = 1, #allbodies do local solid = allbodies[i]
        local hitvelx, hitvely, hitvelz = solid.hitvelx, solid.hitvely, solid.hitvelz
        if hitvelx then solid.velx = solid.velx - hitvelx end
        if hitvely then solid.vely = solid.vely - hitvely end
        if hitvelz then solid.velz = solid.velz - hitvelz end
    end

    for i = #Contacts, 1, -1 do
        Contacts[i]:_release()
        Contacts[i] = nil
    end

    -- for i = 1, #bodies do local body = bodies[i]
    --     if body:isAttacking() then
    --         for j = 1, #bodies do local opponent = bodies[j]
    --             Contacts[#Contacts+1] = Attacker.getAttackHit(body, opponent)
    --         end
    --     end
    -- end

    -- for _, hit in ipairs(Contacts) do
    --     hit.target:onHitByAttack(hit)
    --     Attacker.onAttackHit(hit.attacker, hit)
    -- end

    for i = 1, #allbodies do local body = allbodies[i]
        body.floorbody, body.floorz = World.getCylinderFloor(
            body.x, body.y, body.z,
            body.bodyradius, body.bodyheight, body.bodyhitslayers)
    end

    -- for i = 1, #bodies do local body = bodies[i]
    --     body:fixedupdate()
    -- end
end

function World.prepNextMove()
    for i = 1, #allbodies do local solid = allbodies[i]
        local hitvelx, hitvely, hitvelz,
            penex, peney, penez = Body.predictCollisionVelocity(solid)
        solid.hitvelx = hitvelx
        solid.hitvely = hitvely
        solid.hitvelz = hitvelz
        solid.velx = solid.velx + hitvelx
        solid.vely = solid.vely + hitvely
        solid.velz = solid.velz + hitvelz
        solid.penex, solid.peney, solid.penez = penex, peney, penez
    end
end

---@param bodies Body[]
---@param release boolean
local function pruneCharacters(bodies, release)
    local n = #bodies
    for i = n, 1, -1 do
        if bodies[i].disappeared then
            if release then
                bodies[i]:release()
            end
            bodies[i] = bodies[n]
            bodies[n] = nil
            n = n - 1
        end
    end
end

function World.pruneDisappeared()
    for _, bodygroup in pairs(bodygroups) do
        pruneCharacters(bodygroup, false)
    end
    pruneCharacters(allbodies, true)
end

---@param raycast Raycast
function World.castRay3(raycast, caster)
    raycast.hitdist = nil
    local hitsomething
    local rdx, rdy, rdz = raycast.dx, raycast.dy, raycast.dz
    for _, body in ipairs(allbodies) do
        if body ~= caster and Body.collideWithRaycast3(body, raycast) then
            raycast.dx = raycast.hitx - raycast.x
            raycast.dy = raycast.hity - raycast.y
            raycast.dz = raycast.hitz - raycast.z
            hitsomething = body
        end
    end
    raycast.dx = rdx
    raycast.dy = rdy
    raycast.dz = rdz
    raycast.hitbody = hitsomething
    return hitsomething
end

---@param eval fun(body: Body, i: integer?, bodies: Body[]?):any
function World.search(group, eval)
    local bodies = bodygroups[group] or allbodies
    for i = 1, #bodies do local body = bodies[i]
        local result = eval(body, i, bodies)
        if result then
            return result
        end
    end
end

function World.findClosest(group, x, y, z)
    local bodies = bodygroups[group] or allbodies
    return findClosest(bodies, x, y, z)
end

function World.keepCircleIn(x, y, r, solidlayersmask)
    local totalpenex, totalpeney, penex, peney
    for _, solid in ipairs(allbodies) do
        if bit.band(solid.bodyinlayers, solidlayersmask) ~= 0 then
            penex, peney = Body.getCirclePenetration(solid, x, y, r)
            if penex then
                x = x - penex
                totalpenex = (totalpenex or 0) + penex
            end
            if peney then
                y = y - peney
                totalpeney = (totalpeney or 0) + peney
            end
        end
    end
    return x, y, totalpenex, totalpeney
end

function World.keepCylinderIn(x, y, z, r, h, self, iterations)
    iterations = iterations or 3
    local solidlayersmask = self.bodyhitslayers
    if type(solidlayersmask) == "string" then
        solidlayersmask = CollisionMask.parse(self.bodyhitslayers)
    end
    local totalpenex, totalpeney, totalpenez, penex, peney, penez
    for i = 1, iterations do
        local anycollision = false
        for _, solid in ipairs(allbodies) do
            if solid ~= self
            and bit.band(solid.bodyinlayers, solidlayersmask) ~= 0
            then
                penex, peney, penez = Body.getCylinderPenetration(solid, x, y, z, r, h)
                if penex then
                    anycollision = true
                    x = x - penex
                    totalpenex = (totalpenex or 0) + penex
                end
                if peney then
                    anycollision = true
                    y = y - peney
                    totalpeney = (totalpeney or 0) + peney
                end
                if penez then
                    anycollision = true
                    z = z - penez
                    totalpenez = (totalpenez or 0) + penez
                end
            end
        end
        if not anycollision then
            break
        end
    end
    return x, y, z, totalpenex, totalpeney, totalpenez
end

function World.getCylinderFloor(x, y, z, r, h, solidlayersmask)
    local floorchar
    local floorz = -math.huge
    local floorpenelensq = -math.huge
    for _, solid in ipairs(allbodies) do
        if bit.band(solid.bodyinlayers, solidlayersmask) ~= 0 then
            local fz, penex, peney = Body.getCylinderFloorZ(solid, x, y, z, r, h)
            if fz and (penex ~= 0 or peney ~= 0) then
                local penelensq = penex and peney
                    and math.lensq(penex, peney) or -math.huge
                if fz > floorz
                or fz == floorz and floorpenelensq < penelensq then
                    floorchar = solid
                    floorz = fz
                    floorpenelensq = penelensq
                end
            end
        end
    end
    return floorchar, floorz
end

-- ---@param a Body
-- ---@param b Body
-- function World.isDrawnBefore(a, b)
--     local az = a.drawz or 0
--     local bz = b.drawz or 0
--     if az < bz then
--         return true
--     elseif az > bz then
--         return false
--     end

--     az = a.z or 0
--     bz = b.z or 0
--     local ay = a.y or 0
--     local by = b.y or 0
--     local ayz = ay+az
--     local byz = by+bz
--     if ayz < byz then
--         return true
--     elseif ayz > byz then
--         return false
--     end

--     local ax = a.x or 0
--     local bx = b.x or 0
--     if ax < bx then
--         return true
--     elseif ax > bx then
--         return false
--     end

--     return a.id < b.id
-- end

return World
