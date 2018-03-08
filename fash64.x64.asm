title   fash64.x64.asm: fash64 for x64.

; 2018-03-08
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

; Registers r1, r2, r8, r9, r10, and r11 are clobbered. Register r0 is the
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

; The key to fash is multiplication by prime_11.

prime_11    equ     09A3298AFB5AC7173h ; 11111111111111111027
prime_8     equ     07B5BAD595E238E31h ;  8888888888888888881
prime_3     equ     02E426101834D5517h ;  3333333333333333271

;  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

fash64_state segment para write

product     qword   prime_8
sum         qword   prime_3

fash64_state ends

;  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

fash64_code segment para execute

fash64_begin:

; Register assignments:
;   r8  product
;   r9  sum

; product := prime_8
; sum := prime_3

    mov     r8,prime_8
    mov     r9,prime_3
    mov     product,r8
    mov     sum,r9
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
;   r11 prime_11

;   high; low := (word xor product) * prime_11
;   sum := high + sum
;   product := sum xor low

    mov     r0,product
    mov     r8,sum
    mov     r11,prime_11

    xor     r0,r1       ; r0 is mixed with the word
    mul     r11         ; r2;r0 is the unsigned product of r0 * prime_11
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
;   r9  block pointer
;   r10 block length
;   r11 prime_11

    mov     r0,product
    mov     r8,sum
    mov     r11,prime_11
    mov     r10,r2      ; r10 is block length
    mov     r9,r1       ; r9 is the block pointer

; Make sure the block is not empty.

    test    r10,r10     ; compare length with 0
    jz      return      ; done if the input is empty
    pad

each:

    xor     r0,[r9]     ; r0 is mixed with a word
    add     r9,8        ; point r9 to the next word
    mul     r11         ; r2;r0 is the unsigned product of r0 * prime_11
    add     r8,r2       ; r8 is the sum of the high halves
    xor     r0,r8       ; r0 is the mix of the low product and sum
    sub     r10,1       ; decrement the length
    jnz     each        ; repeat for each word

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
