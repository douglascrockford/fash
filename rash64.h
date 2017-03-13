/* rash64.h

The rash64 header file. This is the companion to rash64.asm.


2017-03-12
Public Domain

No warranty.
*/

typedef long long int64;
typedef unsigned long long uint64;

extern void rash64_seed(uint64 seed);
extern uint64 rash64();
extern uint64 rash64c();