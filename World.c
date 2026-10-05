#include "Body.h"
#include "Body_struct.h"
#include <string.h>

typedef struct World World;

struct World
{
    Body *bodies;
    int numBodies;
};

void InitWorld(World *world)
{
    memset(world, 0, sizeof(World));
}

Body* WorldNewBody(World *world)
{
    Body *body = world->bodies;
    for (int i = 0; i < world->numBodies; ++i) {
        if (!body->live) {
            InitBody(body);
            return body;
        }
        body++;
    }
    return NULL;
}

void WorldKillBody(World *world, Body *body)
{
    body->live = 0;
}

void WorldMoveBodies(World *world)
{
    Body *body = world->bodies;
    for (int i = 0; i < world->numBodies; ++i) {
        UpdateBodyMovement(body++);
    }
}