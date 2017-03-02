/* srash64.h

The srash64 header file. This is the companion to srash64.asm.


2017-03-02
Public Domain

No warranty.
*/

typedef long long int64;
typedef unsigned long long uint64;

extern void srash64_seed(uint64 *seeds);
extern uint64 srash64();
extern void srash64_dump(uint64 *seeds);
