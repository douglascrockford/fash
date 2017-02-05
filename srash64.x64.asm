title   srash64.x64.asm: srash64 for x64.

; 2017-01-30
; Public Domain

; No warranty expressed or implied. Use at your own risk. You have been warned.

; Fash256 is a fast secure random number generator function.

public srash64_seed;(seeds: uint64[8])

public srash64;()

public srash64_dump;(seeds: uint64[8])

; The key to srash64 is multiplication by a big prime number yielding a 128 bit
; product. The high part of the product is added to a sum that is xored with
; the low part of the product. CPUs know how to do a 128:=64*64 bit unsigned
; multiply, but most programming languages do not, which is why this is written
; in assembly language.

;  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

; Repair the register names. Over the long and twisted evolution of x86, the
; register names have picked up some weird, inconsistent conventions. We can
; simplify, naming them r0 thru r15. (We don't use rsp or rbp.)

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

;  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

; Constants:

a_prime     equ     09a3298afb5ac7173h ; 11111111111111111027
b_prime     equ     08AC7230489E7FFD9h ;  9999999999999999961
c_prime     equ     06BF037AE325F1C17h ;  7777777777777777687 
d_prime     equ     04D194C57DAD638CDh ;  5555555555555555533

;  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

srash64_state segment page write

a_product   qword   0
b_product   qword   0
c_product   qword   0
d_product   qword   0
a_sum       qword   0
b_sum       qword   0
c_sum       qword   0
d_sum       qword   0
save_r3     qword   0
save_r6     qword   0

srash64_state ends

;  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

srash64_code segment para execute

srash64_seed: function_with_one_parameter;(seeds: uint64[8])

    mov     r8,[r1]
    mov     r9,[r1+8]
    mov     r10,[r1+16]
    mov     r11,[r1+24]
    mov     a_product,r8
    mov     b_product,r9
    mov     c_product,r10
    mov     d_product,r11

    mov     r8,[r1+32]
    mov     r9,[r1+40]
    mov     r10,[r1+48]
    mov     r11,[r1+56]
    mov     a_sum,r8
    mov     b_sum,r9
    mov     c_sum,r10
    mov     d_sum,r11

    xor     r0,r0
    ret

    pad; -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

srash64:

; Register assignments:
;   r0  low
;   r1  sum
;   r2  high
;   r8  a_product
;   r9  b_product
;   r10 c_product
;   r11 d_product

    mov     r8,a_product
    mov     r9,b_product
    mov     r10,c_product
    mov     r11,d_product

;       high ; low := a_product * a_prime

    mov     r0,a_prime
    mul     r8

;       a_product := low

    mov     r8,r0

;       a_sum := a_sum + high

    mov     r1,a_sum
    add     r1,r2
    mov     a_sum,r1

;       high ; low := b_product * b_prime

    mov     r0,b_prime
    mul     r9

;       b_product := low xor a_sum

    xor     r0,r1
    mov     r9,r0

;       b_sum := b_sum + high

    mov     r1,b_sum
    add     r1,r2
    mov     b_sum,r1

;       high ; low := c_product * c_prime

    mov     r0,c_prime
    mul     r10

;       c_product := low xor b_sum

    xor     r0,r1
    mov     r10,r0

;       c_sum := c_sum + high

    mov     r1,c_sum
    add     r1,r2
    mov     c_sum,r1

;       high ; low := d_product * d_prime

    mov     r0,d_prime
    mul     r11

;       d_product := low xor c_sum

    xor     r0,r1
    mov     r11,r0

;       d_sum := d_sum + high

    mov     r1,d_sum
    add     r1,r2
    mov     d_sum,r1

;       a_product := a_product xor d_sum

    xor     r8,r1

    mov     a_product,r8
    mov     b_product,r9
    mov     c_product,r10
    mov     d_product,r11

;       r8 := a_product + c_product
;       r9 := b_product + d_product

    add     r8,r10
    add     r9,r11

;       return r8 xor r9

    mov     r0,r8
    xor     r0,r9
    ret

    pad; -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

srash64_dump: function_with_one_parameter;(block: uint64[], length: uint64)

    mov     r8,a_product
    mov     r9,b_product
    mov     r10,c_product
    mov     r11,d_product
    mov     [r1],r8
    mov     [r1+8],r9
    mov     [r1+16],r10
    mov     [r1+24],r11

    mov     r8,a_sum
    mov     r9,b_sum
    mov     r10,c_sum
    mov     r11,d_sum
    mov     [r1+32],r8
    mov     [r1+40],r9
    mov     [r1+48],r10
    mov     [r1+56],r11

    xor     r0,r0
    ret

srash64_code ends
    end
