#include "Body.h"
#include <stdint.h>
#include <raymath.h>

typedef struct Contact Contact;

struct Contact {
    Body *a, *b;
    Vector3 AintoB;
};

Contact MakeContact(Body *a, Body *b)
{
    Contact contact = {0};

    // cases:
    // a cylinder vs b cylinder
    // a cylinder vs b ray
    // a cylinder vs b polygon
    // a ray vs b cylinder
    // a ray vs b polygon
    // a polygon vs b cylinder
    // a polygon vs b ray

    // a's ray vs b's ray NOT SUPPORTED
    // a's polygon vs b's polygon NOT SUPPORTED

    return contact;
}