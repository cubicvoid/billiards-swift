// A default libbsd install doesn't work as a swift module because of
// issues in the header file. We only need the random functions, so we
// include their prototypes in this custom header so we can access them without
// messing with the system-level bsd.h.

#ifndef LIBBSD_RANDOM_WRAPPER_H
#define LIBBSD_RANDOM_WRAPPER_H

unsigned int arc4random(void);
void arc4random_stir(void);
void arc4random_addrandom(unsigned char *dat, int datlen);
unsigned int arc4random_uniform(unsigned int upper_bound);

#endif
