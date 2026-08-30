local World = require "World"
local fixedupdate = require "fixedupdate"
local Body        = require "Body"
local GX = love.graphics
local KB = love.keyboard

local player, platform

function love.load()
    require "lldebugger".start()
    local gw, gh = GX.getDimensions()

    ---@type Body
    player = Body.from {
        x = gw/2, y = gh/2, z = 100,
        gravity = 0.5,
        bodyradius = 50,
        bodyheight = 100,
        bodyinlayers = "Player",
        bodyhitslayers = "Platform"
    }

    ---@type Body
    platform = Body.from {
        x = gw/2, y = gh/2, z = -10,
        bodyradius = 300,
        bodyheight = 10,
        bodyinlayers = "Platform",
    }

    World.addBody(player)
    World.addBody(platform)
end

function love.keypressed(k)
    if k == "space" then
        if player.floorz and math.abs(player.floorz - player.z) < 1 then
            player.velz = 20
        end
    end
end

local lerp = 0
function love.update(dt)
    lerp = fixedupdate(60, lerp, dt, function()
        local r = KB.isDown("right") and 1 or 0
        local l = KB.isDown("left") and 1 or 0
        local u = KB.isDown("up") and 1 or 0
        local d = KB.isDown("down") and 1 or 0
        local s = 5
        Body.accelerateTowardsVelXY(player, (r - l)*s, (d - u)*s)

        World.moveBodies()
        World.updateContacts()
        World.updateFloors()
        World.predictCollision()
    end)
end

function love.draw()
    love.graphics.setColor(.5, .5, 1)
    GX.circle("fill", player.x, player.y, player.bodyradius)
    Body.draw(platform, lerp)
    Body.draw(player, lerp)
end