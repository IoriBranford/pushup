#ifndef _BODY_STRUCT_H
#define _BODY_STRUCT_H

#include "Body.h"
#include <inttypes.h>

struct Body {
    // shape
    Vector2 *points;
    int numPoints;
    float radius;
    float height;
    Vector3 ray;
    int shapesActive;

    // collision
    uint32_t teams;
    uint32_t hitsTeams;

    // dynamic state
    Vector3 force;
    Vector3 velocity;
    Vector3 position;
    float inverseMass;
    int paused;
    int live;
};

#endif