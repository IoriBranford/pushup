local Body         = require "pushup.Body"
local CollisionMask= require "pushup.CollisionMask"
local findClosest  = require "findClosest"
local ihash        = require "ihash"
local BodyLayers   = require "pushup.BodyLayers"
local math2 = require "math123.math2"

---@module 'World'
local World = {}

local allbodies = {} ---@type ihash<Body>
local allbodiesbyid = {} ---@type table<integer,Body>
local bodygroups = {} ---@type table<string, ihash<Body>>
local nextid

function World.init(nextid_)
    nextid = nextid_ or 1
    bodygroups = {
        players = {},
        enemies = {},
        items = {},
        projectiles = {},
        container = {},
        solids = {},
        triggers = {},
    }
end

function World.quit()
    for _, body in ipairs(allbodies) do
        Body.release(body)
    end
    allbodies = {}
    bodygroups = {}
    nextid = 1
    allbodiesbyid = {}
    BodyLayers:clear()
end

function World.getBodyById(id)
    return type(id) == "table" and allbodiesbyid[id.id]
        or type(id) == "number" and allbodiesbyid[id]
end

function World.addGroup(name)
    if not bodygroups[name] then
        bodygroups[name] = {}
    end
end

function World.getGroup(group)
    return group == "all" and allbodies or bodygroups[group]
end

function World.addToGroup(g, c)
    g = World.getGroup(g)
    if g then
        ihash.add(g, c)
    end
end

function World.removeFromGroup(g, c)
    g = World.getGroup(g)
    if g then
        ihash.remove(g, c)
    end
end

function World.addBody(body)
    -- local tobj = type(object)
    -- local id = tobj == "table" and object.id
    -- local character = id and activebyid[id]
    -- if character then return character end

    -- if tobj == "string" then
    --     object = {type = object}
    -- end

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
    -- if not id then
    --     id = nextid
    --     body.id = id
    --     nextid = nextid + 1
    -- end
    -- body:init()
    -- body:initAseprite()
    -- body.camera = camera
    -- body.solids = solids
    -- if not body.opponents then
    --     if body.team == "players" then
    --         body.opponents = enemies
    --     else
    --         body.opponents = players
    --     end
    -- end
    -- if body.bodyinlayers ~= 0 then
    --     World.addToGroup("solids", body)
    -- end
    -- World.addToGroup(body.team, body)
    -- if body.team == "triggers" then
    --     local ok, err = body:validateAction()
    --     if not ok then print(err) end
    -- end
    -- if body.initialai then
    --     StateMachine.start(body, body.initialai)
    -- end
    -- body:addToScene(scene)
    -- World.addToGroup("all", body)
    -- activebyid[id] = body
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

local Contacts = {} ---@type Contact[]

function World.moveBodies()
    for i = 1, #allbodies do local body = allbodies[i]
        body:updateBody()
    end

    for i = 1, #allbodies do local solid = allbodies[i]
        local hitvelx, hitvely, hitvelz = solid.hitvelx, solid.hitvely, solid.hitvelz
        if hitvelx then solid.velx = solid.velx - hitvelx end
        if hitvely then solid.vely = solid.vely - hitvely end
        if hitvelz then solid.velz = solid.velz - hitvelz end
    end
end

function World.updateContacts()
    for i = #Contacts, 1, -1 do
        Contacts[i]:_release()
        Contacts[i] = nil
    end

    -- local solids = bodygroups.solids
    -- for i = 1, #solids do local body = solids[i]
    --     if body:isAttacking() then
    --         local mask = body.attack.hitslayers or 0
    --         for _, layer in BodyLayers:eachLayer(mask, 1) do
    --             for _, opponent in ipairs(layer) do
    --                 Contacts[#Contacts+1] = Attacker.getAttackHit(body, opponent)
    --             end
    --         end
    --     end
    -- end

    -- for _, hit in ipairs(Contacts) do
    --     hit.target:onHitByAttack(hit)
    --     Attacker.onAttackHit(hit.attacker, hit)
    -- end
end

function World.updateFloors()
    for i = 1, #allbodies do local body = allbodies[i]
        body.floorbody, body.floorz = World.getCylinderFloor(
            body.x, body.y, body.z,
            body.bodyradius, body.bodyheight, body.bodyhitslayers)
    end
end

function World.predictCollision()
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

function World.pruneDisappeared()
    for _, g in pairs(bodygroups) do
        ihash.prune(g, Body.hasDisappeared)
    end
    BodyLayers:prune(Body.hasDisappeared)
    ihash.prune(allbodies, Body.hasDisappeared, function(b)
        b:release()
        -- allbodiesbyid[b.id] = nil
    end)
end

---@param raycast Raycast
function World.castRay3(raycast, caster)
    raycast.hitdist = nil
    local hitsomething
    local rdx, rdy, rdz = raycast.dx, raycast.dy, raycast.dz
    for _, layer in BodyLayers:eachLayer(raycast.hitslayers, 1) do
        for _, body in ipairs(layer) do
            if body ~= caster and Body.collideWithRaycast3(body, raycast) then
                raycast.dx = raycast.hitx - raycast.x
                raycast.dy = raycast.hity - raycast.y
                raycast.dz = raycast.hitz - raycast.z
                hitsomething = body
            end
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
    for _, layer in BodyLayers:eachLayer(solidlayersmask, 1) do
        for _, solid in ipairs(layer) do
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
    local hitsmask = self.bodyhitslayers
    if type(hitsmask) == "string" then
        hitsmask = CollisionMask.parse(self.bodyhitslayers)
    end
    local totalpenex, totalpeney, totalpenez, penex, peney, penez
    local function collide(solid)
        if solid == self then return false end
        local mask = solid.bodyinlayers
        if bit.band(mask, hitsmask) == 0 then
            return false
        end

        local any = false
        penex, peney, penez = Body.getCylinderPenetration(
                                    solid, x, y, z, r, h)
        if penex then
            any = true
            x = x - penex
            totalpenex = (totalpenex or 0) + penex
        end
        if peney then
            any = true
            y = y - peney
            totalpeney = (totalpeney or 0) + peney
        end
        if penez then
            any = true
            z = z - penez
            totalpenez = (totalpenez or 0) + penez
        end
        return any
    end
    for i = 1, iterations do
        local any = false
        for _, layer in BodyLayers:eachLayer(hitsmask, 1) do
            for _, solid in ipairs(layer) do
                any = collide(solid)
            end
        end
        if not any then
            break
        end
    end
    return x, y, z, totalpenex, totalpeney, totalpenez
end

function World.getCylinderFloor(x, y, z, r, h, hitsmask)
    local floorchar
    local floorz = -math.huge
    local floorpenelensq = -math.huge

    local function testFloor(solid)
        local mask = solid.bodyinlayers
        if bit.band(mask, hitsmask) == 0 then
            return
        end

        local fz, penex, peney = Body.getCylinderFloorZ(
                        solid, x, y, z, r, h)
        if not fz then return end
        if not (penex ~= 0 or peney ~= 0) then return end
        local penelensq = penex and peney
            and math2.lensq(penex, peney) or -math.huge
        if fz > floorz
        or fz == floorz and floorpenelensq < penelensq then
            floorchar = solid
            floorz = fz
            floorpenelensq = penelensq
        end
    end

    for _, layer in BodyLayers:eachLayer(hitsmask, 1) do
        for _, solid in ipairs(layer) do
            testFloor(solid)
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
