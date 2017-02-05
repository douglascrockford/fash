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

a_prime     equ     09a3298afb5ac7173h ; 11111111111111111027
a_default   equ     02E426101834D5517h ;  3333333333333333271  

;  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

rash64_state segment para write

a_product   qword   a_default
a_sum       qword   1

rash64_state ends

;  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

rash64_code segment para execute

rash64_seed: function_with_one_parameter;(seed: uint64)

; Store the argument.

    mov     r0,1
    mov     a_product,r1
    mov     a_sum,1
    ret

    pad; -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

rash64:
;   returns hash: uint64

    mov     r0,a_product
    mov     r10,a_sum

;       a_high, a_low := a_product * a_prime

    mov     r1,a_prime
    mul     r1          ; r2,r0 is the unsigned product of a_product * a_prime
    mov     r8,r0

;       old_a_sum := a_sum
;       a_sum := a_sum + a_high

    mov     r11,r10
    add     r10,r2
    mov     a_sum,r10


;       a_product := a_low xor a_sum
;       return a_low + old_a_sum

    xor     r10,r0
    add     r0,r11
    mov     a_product,r10
    ret

rash64_code ends
    end
