/* fash64.h

The fash64 header file. This is the companion to fash64.asm.


2016-12-28
Public Domain

No warranty.
*/

typedef long long int64;
typedef unsigned long long uint64;

extern void fash64_begin();
extern void fash64_word(uint64 word);
extern void fash64_block(uint64* block, uint64 length);
extern uint64 fash64_end();

