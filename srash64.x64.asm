title   srash64.x64.asm: srash64 for x64.

; 2017-07-24
; Public Domain

; No warranty expressed or implied. Use at your own risk. You have been warned.

; srash64 is a fast secure random number generator function.

public srash64_seed;(seeds: uint64[16])

public srash64;()

public srash64_dump;(seeds: uint64[16])

; The key to srash64 is multiplication by a big prime number yielding a 128 bit
; product. CPUs know how to do a 128:=64*64 bit unsigned multiply, but most
; programming languages do not, which is why this is written in assembly
; language.

; srash64 requires 1024 bits of seed. At least one of those bits must be a 1.

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
c_prime     equ     07B5BAD595E238E31H ;  8888888888888888881
d_prime     equ     06BF037AE325F1C81H ;  7777777777777777793
e_prime     equ     05C84C203069AAA7BH ;  6666666666666666619
f_prime     equ     04D194C57DAD638CDH ;  5555555555555555533
g_prime     equ     03DADD6ACAF11C6F9H ;  4444444444444444409
h_prime     equ     02E426101834D5517H ;  3333333333333333271

;  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

srash64_state segment page write

a_product   qword   0
a_sum       qword   0

b_product   qword   0
b_sum       qword   0

c_product   qword   0
c_sum       qword   0

d_product   qword   0
d_sum       qword   0

e_product   qword   0
e_sum       qword   0

f_product   qword   0
f_sum       qword   0

g_product   qword   0
g_sum       qword   0

h_product   qword   0
h_sum       qword   0

counter     qword   0

srash64_state ends

;  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

srash64_code segment para execute

srash64_seed: function_with_one_parameter;(seeds: uint64[16])

; Load the 1024 bit seed.

    mov     r8,[r1]
    mov     r9,[r1+8]
    mov     r10,[r1+16]
    mov     r11,[r1+24]
    mov     a_product,r8
    mov     a_sum,r9
    mov     b_product,r10
    mov     b_sum,r11

    mov     r8,[r1+32]
    mov     r9,[r1+40]
    mov     r10,[r1+48]
    mov     r11,[r1+56]
    mov     c_product,r8
    mov     c_sum,r9
    mov     d_product,r10
    mov     d_sum,r11

    mov     r8,[r1+64]
    mov     r9,[r1+72]
    mov     r10,[r1+80]
    mov     r11,[r1+88]
    mov     e_product,r8
    mov     e_sum,r9
    mov     f_product,r10
    mov     f_sum,r11

    mov     r8,[r1+96]
    mov     r9,[r1+104]
    mov     r10,[r1+112]
    mov     r11,[r1+120]
    mov     g_product,r8
    mov     g_sum,r9
    mov     h_product,r10
    mov     h_sum,r11

    xor     r0,r0
    mov     counter,r0
    ret

    pad; -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

srash64:

;   r0  low
;   r2  high


;       high ; low := (a_product xor counter) * a_prime

    mov     r8,a_product
    mov     r10,counter
    mov     r0,a_prime
    xor     r8,r10
    mov     r9,a_sum
    mul     r8

;       counter += 1

    add     r10,1
    mov     counter,r10

;       a_product := low

    mov     r8,r0           ; r8 is a_product

;       a_sum := a_sum + high

    add     r9,r2
    mov     a_sum,r9

;       high ; low := b_product * b_prime

    mov     r10,b_product
    mov     r0,b_prime
    mov     r11,b_sum
    mul     r10

;       b_product := low xor a_sum

    xor     r0,r9
    mov     r1,r0           ; r1 is b_product
    mov     b_product,r0

;       b_sum := b_sum + high

    add     r11,r2
    mov     b_sum,r11

;       high ; low := c_product * c_prime

    mov     r10,c_product
    mov     r0,c_prime
    mov     r9,c_sum
    mul     r10

;       c_product := low xor b_sum

    xor     r0,r11
    mov     c_product,r0

;       c_sum := c_sum + high

    add     r9,r2
    mov     c_sum,r9

;       high ; low := d_product * d_prime

    mov     r10,d_product
    mov     r0,d_prime
    mov     r11,d_sum
    mul     r10

;       d_product := low xor c_sum

    xor     r0,r9
    mov     d_product,r0

;       d_sum := d_sum + high

    add     r11,r2
    mov     d_sum,r11

;       high ; low := e_product * e_prime

    mov     r10,e_product
    mov     r0,e_prime
    mov     r9,e_sum
    mul     r10

;       e_product := low xor d_sum

    xor     r0,r11
    mov     e_product,r0

;       e_sum := e_sum + high

    add     r9,r2
    mov     e_sum,r9

;       high ; low := f_product * f_prime

    mov     r10,f_product
    mov     r0,f_prime
    mov     r11,f_sum
    mul     r10

;       f_product := low xor e_sum

    xor     r0,r9
    mov     f_product,r0

;       f_sum := f_sum + high

    add     r11,r2
    mov     f_sum,r11

;       high ; low := g_product * g_prime

    mov     r10,g_product
    mov     r0,g_prime
    mov     r9,g_sum
    mul     r10

;       g_product := low xor f_sum

    xor     r0,r11
    mov     g_product,r0

;       g_sum := g_sum + high

    add     r9,r2
    mov     g_sum,r9

;       high ; low := h_product * h_prime

    mov     r10,h_product
    mov     r0,h_prime
    mov     r11,h_sum
    mul     r10

;       h_product := low xor g_sum

    xor     r0,r9           ; r0 is h_product
    mov     h_product,r0

;       h_sum := h_sum + high

    add     r11,r2
    mov     h_sum,r11

;       a_product := a_product xor h_sum

    xor     r8,r11
    mov     a_product,r8

;       return ((a_product + e_product) xor (b_product + f_product)) +
;              ((c_product + g_product) xor (d_product + h_product))

    mov     r9,g_product    ; r9 is g
    add     r8,e_product    ; r8 is a + e
    add     r1,f_product    ; r1 is b + f
    add     r9,c_product    ; r9 is c + g
    add     r0,d_product    ; r0 is d + h
    xor     r1,r8           ; r1 is (a + e) xor (b + f)
    xor     r0,r9           ; r0 is (c + g) xor (d + h)
    add     r0,r1           ; r0 is ((a + e) xor (b + f)) + ((c + g) xor (d + h))
    ret

    pad; -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

srash64_dump: function_with_one_parameter;(block: uint64[], length: uint64)

    mov     r8,a_product
    mov     r9,a_sum
    mov     r10,b_product
    mov     r11,b_sum
    mov     [r1],r8
    mov     [r1+8],r9
    mov     [r1+16],r10
    mov     [r1+24],r11

    mov     r8,c_product
    mov     r9,c_sum
    mov     r10,d_product
    mov     r11,d_sum
    mov     [r1+32],r8
    mov     [r1+40],r9
    mov     [r1+48],r10
    mov     [r1+56],r11

    mov     r8,e_product
    mov     r9,e_sum
    mov     r10,f_product
    mov     r11,f_sum
    mov     [r1+64],r8
    mov     [r1+72],r9
    mov     [r1+80],r10
    mov     [r1+88],r11

    mov     r8,g_product
    mov     r9,g_sum
    mov     r10,h_product
    mov     r11,h_sum
    mov     [r1+96],r8
    mov     [r1+104],r9
    mov     [r1+112],r10
    mov     [r1+120],r11

    xor     r0,r0
    ret

srash64_code ends
    end
