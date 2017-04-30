title   fash256.x64.asm: fash256 for x64.

; 2017-04-29
; Public Domain

; No warranty expressed or implied. Use at your own risk. You have been warned.

; Fash256 is a fast hashing function. It takes zero or more 64-bit words and
; produces a 256-bit hash. It might be a cryptographic hash function, but this
; has not been proven yet.

public fash256_begin;()

public fash256_word;(word: uint64)

public fash256_block;(block: uint64[length], length: uint64)

public fash256_end;(result: uint64[4])

; All of the fash256 functions take a pointer to a fash256 data structure as
; the first argument. To compute a fash256 value, first call fash256_begin to
; initialize the hash function state. Call fash256_word for each 64-bit word
; to be hashed. Call fash256_block with a block of words. After everything has
; been hashed, call fash256_end to obtain the result. None of these functions
; return a value.

; The key to fash256 is multiplication by a big prime number yielding a 128 bit
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

a_prime         equ     09a3298afb5ac7173h ; 11111111111111111027
b_prime         equ     08AC7230489E7FFD9h ;  9999999999999999961
c_prime         equ     06BF037AE325F1C17h ;  7777777777777777687
d_prime         equ     04D194C57DAD638CDh ;  5555555555555555533

a_1st_result    equ     07B5BAD595E238E31h ;  8888888888888888881
b_1st_result    equ     05C84C203069AAA7Bh ;  6666666666666666619
c_1st_result    equ     03DADD6ACAF11C6F9h ;  4444444444444444409
d_1st_result    equ     01ED6EB565788E361h ;  2222222222222222177

a_1st_sum       equ     06BF037AE325F1C17h ;  7777777777777777687
b_1st_sum       equ     04D194C57DAD638CDh ;  5555555555555555533
c_1st_sum       equ     02E426101834D5517h ;  3333333333333333271
d_1st_sum       equ     00F6B75AB2BC4717Dh ;  1111111111111111037

;  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

fash256_state segment page write

a_result        qword   0
b_result        qword   0
c_result        qword   0
d_result        qword   0
a_sum           qword   0
b_sum           qword   0
c_sum           qword   0
d_sum           qword   0
save_r3         qword   0
save_r6         qword   0

fash256_state ends

;  -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

fash256_code segment para execute

fash256_begin:

; Initialize the products and sums.

; a_result := a_1st_result
; b_result := b_1st_result
; c_result := c_1st_result
; d_result := d_1st_result

    mov     r8,a_1st_result
    mov     r9,b_1st_result
    mov     r10,c_1st_result
    mov     r11,d_1st_result
    mov     a_result,r8
    mov     b_result,r9
    mov     c_result,r10
    mov     d_result,r11

; a_sum := a_1st_sum
; b_sum := b_1st_sum
; c_sum := c_1st_sum
; d_sum := d_1st_sum

    mov     r8,a_1st_sum
    mov     r9,b_1st_sum
    mov     r10,c_1st_sum
    mov     r11,d_1st_sum
    mov     a_sum,r8
    mov     b_sum,r9
    mov     c_sum,r10
    mov     d_sum,r11

    xor     r0,r0
    ret

    pad; -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

fash256_word: function_with_one_parameter;(word: uint64)

; For each of the four components:
;   Mix the word with the product.
;   Multiply the mixed product with the component's prime.
;   Add the high part to the sum.
;   Mix the sum into the next product

; Register assignments:
;   r0  low
;   r1  word
;   r2  high
;   r8  _result
;   r9  _sum
;   r10 previous sum
;   r11 a_result

    mov     r11,a_result    ; r11 := a_result
    mov     r9,a_sum        ; r9 := a_sum
    mov     r0,a_prime      ; ro := a_prime
    xor     r11,r1          ; r11 := r11 xor word
    mul     r11             ; r2, r0 := r11 * r0
    mov     r8,b_result     ; r8 := b_result
    add     r2,r9           ; r2 := r2 + r9
    mov     r9,b_sum        ; r9 := b_sum
    mov     r10,r2          ; r10 := r2
    mov     r11,r0          ; r11 := r0
    mov     a_sum,r2        ; a_sum := r2

    xor     r8,r1           ; r8 := r8 xor word
    mov     r0,b_prime      ; r0 := b_prime
    mul     r8              ; r2, r0 := r8 * r0
    mov     r8,c_result     ; r8 := c_result
    xor     r0,r10          ; r0 := r0 xor r10
    add     r2,r9           ; r2 := r2 + b_sum
    mov     r9,c_sum        ; r9 := c_sum
    mov     r10,r2          ; r10 := r2
    mov     b_result,r0     ; b_result := r0
    mov     b_sum,r2        ; b_sum := r2

    xor     r8,r1           ; r8 := r8 xor word
    mov     r0,c_prime      ; r0 := c_prime
    mul     r8              ; r2, r0 := r8 * r0
    mov     r8,d_result     ; r8 := d_result
    xor     r0,r10          ; r0 := r0 xor r10
    add     r2,r9           ; r2 := r2 + c_sum
    mov     r9,d_sum        ; r9 := d_sum
    mov     r10,r2          ; r10 := r2
    mov     c_result,r0     ; c_result := r0
    mov     c_sum,r2        ; c_sum := r2

    xor     r8,r1           ; r8 := r8 xor word
    mov     r0,d_prime      ; r0 := d_prime
    mul     r8              ; r2, r0 := r8 * r0
    add     r2,r9           ; r2 := r2 + r9
    xor     r0,r10          ; r0 := r0 xor r10
    xor     r11,r2          ; r11 := r11 xor r2
    mov     d_result,r0     ; d_result := r0
    mov     d_sum,r2        ; d_sum := r2
    mov     a_result,r11    ; a_result := r11

    xor     r0,r0
    ret

    pad; -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

fash256_block: function_with_two_parameters;(block: uint64[], length: uint64)

; Register assignments:
;   r0  low
;   r1  block length
;   r2  high
;   r3  word
;   r6  block pointer
;   r8  a_result
;   r9  b_result
;   r10 c_result
;   r11 d_result
;   r12 a_sum
;   r13 b_sum
;   r14 c_sum
;   r15 d_sum

; Make sure the block of words is not empty.

    test    r2,r2       ; compare length with 0
    jz      return      ; done if the input is empty

; Save preserved registers

    mov     save_r3,r3
    mov     save_r6,r6

; Parameters

    mov     r6,r1       ; r6 is the block pointer
    mov     r1,r2       ; r1 is the block length

; Load the registers

    mov     r8,a_result
    mov     r9,b_result
    mov     r10,c_result
    mov     r11,d_result

    xchg    r12,a_sum
    xchg    r13,b_sum
    xchg    r14,c_sum
    xchg    r15,d_sum

    pad

each:

    mov     r3,[r6]     ; r3 is the next word
    add     r6,8        ; advance the block pointer

    xor     r8,r3       ; r8 is a_result xor word
    mov     r0,a_prime
    mul     r8
    add     r12,r2      ; r12 is high + a_sum
    mov     r8,r0       ; r8 is low

    xor     r9,r3       ; r9 is b_result xor word
    mov     r0,b_prime
    mul     r9
    add     r13,r2      ; r13 is high + b_sum
    mov     r9,r0       ; r9 is low

    xor     r10,r3      ; r10 is c_result xor word
    mov     r0,c_prime
    mul     r10
    add     r14,r2      ; r14 is high + c_sum
    mov     r10,r0      ; r10 is low

    xor     r11,r3      ; r0 is d_result xor word
    mov     r0,d_prime
    mul     r11
    add     r15,r2      ; r15 is high + d_sum
    mov     r11,r0      ; r11 is low

    xor     r8,r15      ; mix d_sum into a_result
    xor     r9,r12      ; mix a_sum into b_result
    xor     r10,r13     ; mix b_sum into c_result
    xor     r11,r14     ; mix c_sum into d_result

    sub     r1,1        ; decrement the length
    jnz     each        ; repeat until done

; Save the registers

    mov     a_result,r8
    mov     b_result,r9
    mov     c_result,r10
    mov     d_result,r11

    xchg    r12,a_sum
    xchg    r13,b_sum
    xchg    r14,c_sum
    xchg    r15,d_sum

; Restore registers

    mov     r3,save_r3
    mov     r6,save_r6

return:

    xor     r0,r0
    ret

    pad; -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

fash256_end: function_with_one_parameter;(result: uint64[4])

; Register assignments:
;   r1  result

; Load the registers

    mov     r8,a_result
    mov     r9,b_result
    mov     r10,c_result
    mov     r11,d_result

    mov     [r1],r8
    mov     [r1+8],r9
    mov     [r1+16],r10
    mov     [r1+24],r11

    xor     r0,r0
    ret

fash256_code ends
    end
