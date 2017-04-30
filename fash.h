/* fash.h

The fash header file. 

2017-04-25
Public Domain
*/

#include "uint64.h"

extern void fash64_begin();
extern void fash64_word(uint64 word);
extern void fash64_block(uint64* block, uint64 length);
extern uint64 fash64_end();

extern void fash256_begin();
extern void fash256_word(uint64 word);
extern void fash256_block(uint64 *block, uint64 length);
extern void fash256_end(uint64 *result);

extern void rash64_seed(uint64 seed);
extern uint64 rash64();
extern uint64 rash64c();

extern void srash64_seed(uint64 *seeds);
extern uint64 srash64();
extern void srash64_dump(uint64 *seeds);
