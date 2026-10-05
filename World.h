#ifndef WORLD_H_
#define WORLD_H_

typedef struct Body Body;
typedef struct World World;

void InitWorld(World *world);
Body* WorldNewBody(World *world);
void WorldKillBody(World *world, Body *body);
void WorldMoveBodies(World *world);

#endif //WORLD_H_