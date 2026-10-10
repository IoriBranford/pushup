#ifndef _BODY_H
#define _BODY_H

#include <raymath.h>

typedef struct Body Body;

typedef enum ActiveShapes {
    BODY_CYLINDER = 1,
    BODY_RAY = 2,
    BODY_POLY = 4
} ActiveShapes;

void InitBody(Body *body);

void SetBodyCylinder(Body *body, float radius, float height);
void AddBodyCylinder(Body *body, float radius, float height);
void RemoveBodyCylinder(Body *body);

void SetBodyRay(Body *body, Vector3 ray);
void AddBodyRay(Body *body, Vector3 ray);
void RemoveBodyRay(Body *body);

void SetBodyPoly(Body *body, int n, Vector2 *points, float height);
void AddBodyPoly(Body *body, int n, Vector2 *points, float height);
void RemoveBodyPoly(Body *body);

void UpdateBodyMovement(Body *body);

#endif