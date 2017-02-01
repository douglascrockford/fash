title   rash64.x64.asm: rash64 for x64.

; 2017-01-26
; Public Domain

; No warranty expressed or implied. Use at your own risk. You have been warned.

; Rash64 is a fast random number generating function. 

public rash64;()

public rash64_seed;(a: uint64, b: uint64)

; The key to rash64 is multiplication by a big prime number yielding a 128 bit
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
; On Win64, the default three arguments are passed in r1, r2, and r8. On Unix,
; the default three arguments are passed in r7, r6, and r2. We try to hide that
; weirdness behind a macro. The two systems also have different conventions
; about which registers may be clobbered and which must be preserved. This
; code lives in the intersection.

; Registers r1, r2, r8, r9, r10, and r11 are clobbered. Register r0 is the
; return value. The other registers are not disturbed.

; This has not yet been tested on Unix.

UNIX    equ 0                   ; calling convention: 0 for Windows, 1 for Unix

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

; The key to rash is multiplication by big prime numbers.

a_prime     equ     07b5bad595e238e31h ;  8888888888888888881
b_prime     equ     08AC7230489E7FFD9h ;  9999999999999999961
a_default   equ     05555555555555555h ;  6148914691236517205
b_default   equ     01040426696698bb2h ;  1171008911493925810

;  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

rash64_state segment para write

a_product   qword   a_default
b_product   qword   b_default
a_sum       qword   1
b_sum       qword   1

rash64_state ends

;  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

rash64_code segment para execute

rash64_seed: function_with_two_parameters;(a: uint64, b: unit64)

; Register assignments:
;   r1  a
;   r2  b

; Store the arguments.

    mov     r0,1
    mov     a_product,r1
    mov     b_product,r2
    mov     a_sum,r0
    mov     b_sum,r0
    ret

    pad; -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

rash64: 
;   returns hash: uint64

; Register assignments:
;   r0  low
;   r1  prime
;   r2  high
;   r8  a_product
;   r9  b_product
;   r10 a_sum
;   r11 b_sum

    mov     r8,a_product
    mov     r9,b_product
    mov     r10,a_sum
    mov     r11,b_sum

;   a_high, a_low := a_product * a_prime

    mov     r1,a_prime
    mov     r0,r8
    mul     r1          ; r2,r0 is the unsigned product of a_product * a_prime
    mov     r8,r0

;   a_sum := a_sum + a_high

    add     r10,r2      

;   b_high, b_low := b_product * b_prime

    mov     r1,b_prime
    mov     r0,r9
    mul     r1          ; r2,r0 is the unsigned product of b_product * b_prime
    mov     r9,r0

;   b_sum := b_sum + b_high

    add     r11,r2

;   a_product := a_low xor b_sum
;   b_product := b_low xor a_sum

    xor     r8,r11
    xor     r9,r10

    mov     a_product,r8
    mov     b_product,r9
    mov     a_sum,r10
    mov     b_sum,r11

;   return a_product + b_product

    mov     r0,r8
    add     r0,r9
    ret

rash64_code ends
    end
