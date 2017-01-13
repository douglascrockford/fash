title   fash64.x64.asm: fash64 for x64.

; 2017-01-12
; Public Domain

; No warranty expressed or implied. Use at your own risk. You have been warned.

; Fash64 is a fast hashing function. It can be used to implement hash data
; structures or as a block check.

public fash64_begin;()

public fash64_word;(word: uint64)

public fash64_block;(block: [uint64], length: uint64)

public fash64_end;()
;   returns hash: uint64

; To compute a fash64 value, first call fash64_begin to initialize the hash
; function state. Call fash64_word for each 64-bit word to be hashed. Call
; fash64_block for a block of words. After everything has been hashed, call
; fash64_end to obtain the result.

; The key to fash64 is multiplication by a big prime number yielding a 128 bit
; product. The high part of the product is added to a sum that is xored with
; the low part of the product. CPUs know how to do a 128:=64*64 bit unsigned
; multiply, but most programming languages do not, which is why this is written
; in assembly language.

;  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

; Repair the register names. Over the long and twisted evolution of x86, the
; register names have picked up some weird, inconsistent conventions. We can
; simplify, naming them r0 thru r15.

r0      equ rax
r1      equ rcx
r2      equ rdx
r3      equ rbx
r6      equ rsi
r7      equ rdi

; There is painfully inadequate standardization around x64 calling conventions.
; On Win64, the first three arguments are passed in r1, r2, and r8. On Unix,
; the first three arguments are passed in r7, r6, and r2. We try to hide that
; weirdness behind these macros. The two systems also have different
; conventions about which registers may be clobbered and which must be
; preserved. This code lives in the intersection.

; Registers r1, r2, r8, r9, r11, and r10 are clobbered. Register r0 is the
; return value. The other registers are not disturbed.

; This has not yet been tested on Unix.

UNIX    equ 0                   ; calling convention: 0 for Windows, 1 for Unix

function_with_one_parameter macro
    if UNIX
    mov     r1,r7               ;; UNIX
    endif
    endm

function_with_two_parameters macro
    if UNIX
    mov     r1,r7               ;; UNIX
    mov     r2,r6               ;; UNIX
    endif
    endm

; There may be a performance benefit in padding programs so that most jump
; destinations are aligned on 16 byte boundaries.

pad macro
    align   16
    endm

; The key to fash is multiplication by a big prime number.

prime       equ     04D19557A67F7BDD1h ;  5555565599556877777
product_1st equ     05555555555555555h ;  6148914691236517205
sum_1st     equ     01040426696698bb2h ;  1171008911493925810

;  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

fash64_state segment para write

product qword   product_1st
sum     qword   sum_1st

fash64_state ends

;  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

fash64_code segment para execute

fash64_begin:

; Register assignments:
;   r0  product
;   r8  sum

; product := product_1st
; sum := sum_1st

    mov     r0,product_1st
    mov     r8,sum_1st
    mov     product,r0
    mov     sum,r8
    xor     r0,r0
    ret

    pad; -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

fash64_word: function_with_one_parameter;(word: uint64)
;   returns hash: uint64

; Register assignments:
;   r0  product
;   r1  word
;   r2  high
;   r8  sum
;   r9  prime

;   high, low := (word xor product) * prime
;   sum := high + sum
;   product := sum xor low

    mov     r0,product
    mov     r8,sum
    mov     r9,prime

    xor     r0,r1       ; r0 is mixed with the word
    mul     r9          ; r2,r0 is the unsigned product of r0 * prime
    add     r8,r2       ; r8 is the sum of the high halves
    xor     r0,r8       ; r0 is the mix of the low product and sum

    mov     sum,r8
    mov     product,r0
    xor     r0,r0
    ret

    pad; -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

fash64_block: function_with_two_parameters;(block: uint64[], length: uint64)

; Register assignments:
;   r0  product
;   r2  high
;   r8  sum
;   r9  prime
;   r10 block length
;   r11 block pointer

    mov     r0,product
    mov     r8,sum
    mov     r9,prime
    mov     r10,r2      ; r10 is block length
    mov     r11,r1      ; r11 is the block pointer

; Make sure the block is not empty.

    test    r10,r10     ; compare length with 0
    jz      return      ; done if the input is empty
    pad

each:

    xor     r0,[r11]    ; r0 is mixed with a word
    add     r11,8       ; point r11 to the next word
    mul     r9          ; r2,r0 is the unsigned product of r0 * prime
    add     r8,r2       ; r8 is the sum of the high halves
    xor     r0,r8       ; r0 is the mix of the low product and sum
    sub     r10,1       ; decrement the length
    jnz     each        ; repeat for each thing

    mov     sum,r8
    mov     product,r0

return:

    xor     r0,r0
    ret

    pad; -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

fash64_end:
;   returns hash: uint64

; Register assignments:
;   r0  product

    mov     r0,product
    ret

fash64_code ends
    end
