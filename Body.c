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

void SetBodyCylinder(Body *body, float radius, float height)
{
    body->shapesActive = BODY_CYLINDER;
    body->radius = radius;
    body->height = height;
}

void AddBodyCylinder(Body *body, float radius, float height)
{
    body->shapesActive |= BODY_CYLINDER;
    body->radius = radius;
    body->height = height;
}

void RemoveBodyCylinder(Body *body)
{
    body->shapesActive &= ~BODY_CYLINDER;
}

void SetBodyRay(Body *body, Vector3 ray)
{
    body->shapesActive = BODY_RAY;
    body->ray = ray;
}

void AddBodyRay(Body *body, Vector3 ray)
{
    body->shapesActive &= BODY_RAY;
    body->ray = ray;
}

void RemoveBodyRay(Body *body)
{
    body->shapesActive &= ~BODY_RAY;
}

void SetBodyPoly(Body *body, int n, Vector2 *points, float height)
{
    body->shapesActive = BODY_POLY;
    body->numPoints = n;
    body->points = points;
    body->height = height;
}

void AddBodyPoly(Body *body, int n, Vector2 *points, float height)
{
    body->shapesActive &= BODY_POLY;
    body->numPoints = n;
    body->points = points;
    body->height = height;
}

void RemoveBodyPoly(Body *body)
{
    body->shapesActive &= ~BODY_POLY;
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