/* fash256.h

The fash256 header file. This is the companion to fash256.asm.


2017-01-15
Public Domain

No warranty.
*/

typedef long long int64;
typedef unsigned long long uint64;

extern void fash256_begin();
extern void fash256_word(uint64 word);
extern void fash256_block(uint64 *block, uint64 length);
extern void fash256_end(uint64 *result);

