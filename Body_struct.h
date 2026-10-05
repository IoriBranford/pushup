#ifndef _BODY_STRUCT_H
#define _BODY_STRUCT_H

#include <raymath.h>
#include <inttypes.h>
#include <stdbool.h>

struct Body {
    // shape
    Vector2 *points;
    int numPoints;
    float radius;
    float height;
    Vector3 ray;

    // collision
    uint32_t teams;
    uint32_t hitsTeams;

    // dynamic state
    Vector3 force;
    Vector3 velocity;
    Vector3 position;
    float inverseMass;
    bool paused;
    bool live;
};

#endif