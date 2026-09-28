#include <stdbool.h>
#include <inttypes.h>
#include <raymath.h>

typedef struct ShapeBase ShapeBase;
typedef struct Cylinder Cylinder;
typedef struct Polyland Polyland; // polyline/polygon extruded along the z axis
typedef union Shape Shape;
typedef struct BodySpec BodySpec;
typedef struct Body Body;

typedef enum {
    CYLINDER,
    RAY,
    POLYLAND
} ShapeType;

struct Body {
    Vector3 position;
    Vector3 velocity;

    uint32_t teams;
    uint32_t hitsTeams;

    ShapeType shape;
    union {
        struct {
            float radius;
            float height;
        } cylinder;
        struct {
            Vector3 direction;
            float length;
        } ray;
        struct {
            float radius;
            float height;
            int numPoints;
            Vector2 *points;
        } polyland;
    };

    bool paused;
    bool dead;
};