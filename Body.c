#include <stdbool.h>
#include <inttypes.h>
#include <raymath.h>

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
    Body *parent;
    Vector3 position;
    Vector3 velocity;
    bool paused;
    bool dead;
};