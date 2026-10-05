#include <assert.h>
#include <stdbool.h>
#include <inttypes.h>
#include <raymath.h>
#include <string.h>

typedef struct Body Body;

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
    bool dead;
};

void InitBody(Body *body)
{
    memset(body, 0, sizeof(Body));
    body->inverseMass = 1;
}

Vector3 GetBodyAccel(Body *body)
{
    return Vector3Scale(body->force, body->inverseMass);
}

void UpdateBody(Body *body)
{
    Vector3 accel = GetBodyAccel(body);
    body->velocity = Vector3Add(body->velocity, accel);
    body->position = Vector3Add(body->position, body->velocity);
    body->force = Vector3Zero();
}