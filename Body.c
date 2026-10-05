#include "Body.h"
#include "Body_struct.h"
#include <assert.h>
#include <string.h>

void InitBody(Body *body)
{
    memset(body, 0, sizeof(Body));
    body->live = 1;
    body->inverseMass = 1;
}

Vector3 GetBodyAccel(Body *body)
{
    return Vector3Scale(body->force, body->inverseMass);
}

void UpdateBodyMovement(Body *body)
{
    if (!body->live) return;
    Vector3 accel = GetBodyAccel(body);
    body->velocity = Vector3Add(body->velocity, accel);
    body->position = Vector3Add(body->position, body->velocity);
    body->force = Vector3Zero();
}