include '%fasm%/INCLUDE/MACRO/STRUCT.INC'
include 'x86_64.inc'

X86_64_format

public md5_init
public md5_update
public md5_final


struct md5_ctx
    buffer db 64 dup(?)
    state dd 4 dup(?)
    count dq ?
ends


X86_64_section_TEXT align 16

md5_transform:

    define a r8d
    define b r9d
    define c r10d
    define d r11d

    macro STEP_1 w*, x*, y*, z*, in*, k*, s* {
        mov esi, y
        mov edi, z
        mov eax, x
        mov ebx, x
        xor esi, edi
        and eax, esi
        xor eax, edi                    ; eax = f(x, y, z)
        add eax, [rdx + in*4]
        add eax, k
        add w, eax                      ; w += f(x, y, z) + buf[in] + k
        rol w, s
        add w, ebx
    }

    ; (z ^ (x & (y ^ z)))
    ; (y ^ (z & (x ^ y)))
    macro STEP_2 w*, x*, y*, z*, in*, k*, s* {
        mov eax, x
        mov esi, y
        mov edi, z
        mov ebx, x
        xor eax, esi
        and edi, eax
        xor esi, edi
        add esi, [rdx + in*4]
        add esi, k
        add w, esi                      ; w += f(x, y, z) + buf[in] + k
        rol w, s
        add w, ebx
    }

    macro STEP_3 w*, x*, y*, z*, in*, k*, s* {
        mov eax, x
        xor eax, y
        xor eax, z                      ; eax = f(x, y, z)
        add eax, [rdx + in*4]
        add eax, k
        add w, eax                      ; w += f(x, y, z) + buf[in] + k
        rol w, s
        add w, x
    }

    macro STEP_4 w*, x*, y*, z*, in*, k*, s* {
        mov eax, z
        not eax
        or eax, x
        xor eax, y                      ; eax = f(x, y, z)
        add eax, [rdx + in*4]
        add eax, k
        add w, eax                      ; w += f(x, y, z) + buf[in] + k
        rol w, s
        add w, x
    }

    movups xmm0, xword [rcx + md5_ctx.state]
    irps r, r8d r9d r10d {
        movd r, xmm0
        psrldq xmm0, 4
    }
    movd r11d, xmm0

    STEP_1 a, b, c, d, 0,  0xd76aa478, 7
    STEP_1 d, a, b, c, 1,  0xe8c7b756, 12
    STEP_1 c, d, a, b, 2,  0x242070db, 17
    STEP_1 b, c, d, a, 3,  0xc1bdceee, 22
    STEP_1 a, b, c, d, 4,  0xf57c0faf, 7
    STEP_1 d, a, b, c, 5,  0x4787c62a, 12
    STEP_1 c, d, a, b, 6,  0xa8304613, 17
    STEP_1 b, c, d, a, 7,  0xfd469501, 22
    STEP_1 a, b, c, d, 8,  0x698098d8, 7
    STEP_1 d, a, b, c, 9,  0x8b44f7af, 12
    STEP_1 c, d, a, b, 10, 0xffff5bb1, 17
    STEP_1 b, c, d, a, 11, 0x895cd7be, 22
    STEP_1 a, b, c, d, 12, 0x6b901122, 7
    STEP_1 d, a, b, c, 13, 0xfd987193, 12
    STEP_1 c, d, a, b, 14, 0xa679438e, 17
    STEP_1 b, c, d, a, 15, 0x49b40821, 22

    STEP_2 a, b, c, d,  1, 0xf61e2562,  5
    STEP_2 d, a, b, c,  6, 0xc040b340,  9
    STEP_2 c, d, a, b, 11, 0x265e5a51, 14
    STEP_2 b, c, d, a,  0, 0xe9b6c7aa, 20
    STEP_2 a, b, c, d,  5, 0xd62f105d,  5
    STEP_2 d, a, b, c, 10, 0x02441453,  9
    STEP_2 c, d, a, b, 15, 0xd8a1e681, 14
    STEP_2 b, c, d, a,  4, 0xe7d3fbc8, 20
    STEP_2 a, b, c, d,  9, 0x21e1cde6,  5
    STEP_2 d, a, b, c, 14, 0xc33707d6,  9
    STEP_2 c, d, a, b,  3, 0xf4d50d87, 14
    STEP_2 b, c, d, a,  8, 0x455a14ed, 20
    STEP_2 a, b, c, d, 13, 0xa9e3e905,  5
    STEP_2 d, a, b, c,  2, 0xfcefa3f8,  9
    STEP_2 c, d, a, b,  7, 0x676f02d9, 14
    STEP_2 b, c, d, a, 12, 0x8d2a4c8a, 20
    
    STEP_3 a, b, c, d, 5,  0xfffa3942, 4
    STEP_3 d, a, b, c, 8,  0x8771f681, 11
    STEP_3 c, d, a, b, 11, 0x6d9d6122, 16
    STEP_3 b, c, d, a, 14, 0xfde5380c, 23
    STEP_3 a, b, c, d, 1,  0xa4beea44, 4
    STEP_3 d, a, b, c, 4,  0x4bdecfa9, 11
    STEP_3 c, d, a, b, 7,  0xf6bb4b60, 16
    STEP_3 b, c, d, a, 10, 0xbebfbc70, 23
    STEP_3 a, b, c, d, 13, 0x289b7ec6, 4
    STEP_3 d, a, b, c, 0,  0xeaa127fa, 11
    STEP_3 c, d, a, b, 3,  0xd4ef3085, 16
    STEP_3 b, c, d, a, 6,  0x04881d05, 23
    STEP_3 a, b, c, d, 9,  0xd9d4d039, 4
    STEP_3 d, a, b, c, 12, 0xe6db99e5, 11
    STEP_3 c, d, a, b, 15, 0x1fa27cf8, 16
    STEP_3 b, c, d, a, 2,  0xc4ac5665, 23

    STEP_4 a, b, c, d, 0,  0xf4292244, 6
    STEP_4 d, a, b, c, 7,  0x432aff97, 10
    STEP_4 c, d, a, b, 14, 0xab9423a7, 15
    STEP_4 b, c, d, a, 5,  0xfc93a039, 21
    STEP_4 a, b, c, d, 12, 0x655b59c3, 6
    STEP_4 d, a, b, c, 3,  0x8f0ccc92, 10
    STEP_4 c, d, a, b, 10, 0xffeff47d, 15
    STEP_4 b, c, d, a, 1,  0x85845dd1, 21
    STEP_4 a, b, c, d, 8,  0x6fa87e4f, 6
    STEP_4 d, a, b, c, 15, 0xfe2ce6e0, 10
    STEP_4 c, d, a, b, 6,  0xa3014314, 15
    STEP_4 b, c, d, a, 13, 0x4e0811a1, 21
    STEP_4 a, b, c, d, 4,  0xf7537e82, 6
    STEP_4 d, a, b, c, 11, 0xbd3af235, 10
    STEP_4 c, d, a, b, 2,  0x2ad7d2bb, 15
    STEP_4 b, c, d, a, 9,  0xeb86d391, 21

    rept 4 idx:0, reg:8 { add [rcx + md5_ctx.state + idx*4], r#reg#d }

    ret

do_pad: ; expect pointer in rdi and len in r9
    test r9d, r9d
    je short no_pad
    
    mov edx, 8
    xor eax, eax

    cmp r9d, edx
    jb short p1lt8

p1pa:
    stosq
    sub r9d, edx
    cmp r9d, edx
    jae short p1pa

p1lt8:                                  ; pad remaining 0-7 bytes
    test r9d, r9d
    je short no_pad

p1lt8a:
    stosb
    dec r9d
    jne short p1lt8a

no_pad:
    ret

; src and dst must be 64bit regs, len must be a reg
macro memcpy dst*, src*, len*, small=al {
    local lt16, memcpy_end
    cmp len, 16
    jb short lt16
@@:
    movups xmm0, dqword [src]
    movups dqword [dst], xmm0
    sub len, 16
    add src, 16
    add dst, 16
    cmp len, 16
    jae short @b
lt16:
    test len, len
    je short memcpy_end
@@:
    mov small, [src]
    mov [dst], small
    inc src
    inc dst
    dec len
    jne short @b
memcpy_end:
}

md5_init:
    X86_64_prolog(1)
    mov rax, -1167088121787636991
    mov QWORD [rcx + md5_ctx.count], 0
    mov rdx, 1167088121787636990
    mov QWORD [rcx + md5_ctx.state], rax
    mov QWORD [rcx + md5_ctx.state + 8], rdx
    ret

md5_update:
    X86_64_prolog(3), rbx, rsi, rdi

    and r8d, r8d
    mov r9, [rcx + md5_ctx.count]       ; load count
    add [rcx + md5_ctx.count], r8       ; update new count
    and r9, 0x3f
    test r9d, r9d
    je short main_upd_loop

    mov r10d, r9d
    sub r9, 64
    neg r9
    cmp r8, r9
    cmovb r9d, r8d                      ; r9 is chunk, r11 is dest pointer
    lea r11, [rcx + md5_ctx.buffer + r10]
    sub r8, r9                          ; update remaining
    add r10d, r9d                       ; r10 is buf_size + chunk
    memcpy r11, rdx, r9
    cmp r10l, 64
    jb short final_cpy
    movq xmm1, rdx
    movd xmm2, r8d
    lea rdx, [rcx + md5_ctx.buffer]
    call md5_transform
    movd r8d, xmm2
    movq rdx, xmm1

main_upd_loop:
    cmp r8d, 64
    jb short final_cpy
@@:
    movd xmm1, r8d
    call md5_transform
    movd r8d, xmm1
    add rdx, 64
    sub r8d, 64
    cmp r8d, 64
    jae short @b

final_cpy:
    lea rcx, [rcx + md5_ctx.buffer]
    memcpy rcx, rdx, r8

    X86_64_epilog rbx, rsi, rdi
    ret

md5_final:
    X86_64_prolog(1), rbx, rsi, rdi

    mov r8, [rcx + md5_ctx.count]       ; save old count in r8

    mov edx, r8d
    and edx, 0x3f                       ; rdx is buffer_size
    mov r9d, 56
    lea rdi, [rcx + md5_ctx.buffer + rdx]
    inc edx
    mov al, 0x80                        ; pad first byte with highest bit set
    inc [rcx + md5_ctx.count]
    stosb

    cmp edx, r9d
    jbe short few_pad

    sub rdx, 64
    neg rdx                             ; calculate (64 - buf_size)

    add [rcx + md5_ctx.count], rdx      ; update count for big padding
    mov r9d, edx                        ; Set padding len in r9d for do_pad
    call do_pad
    push r8
    lea rdx, [rcx + md5_ctx.buffer]
    call md5_transform
    pop r8
    mov r9d, 56                         ; restore r9 to 56
    xor edx, edx                        ; buf_size set to zero
    lea rdi, [rcx + md5_ctx.buffer]     ; restore rdi for final pad

few_pad:
    sub r9d, edx                        ; calculate padding len
    je short @f
    add [rcx + md5_ctx.count], r9
    call do_pad
@@:
    sal r8, 3
    mov [rdi], r8                       ; store count in bits

    add qword [rcx + md5_ctx.count], 8  ; update count

    lea rdx, [rcx + md5_ctx.buffer]
    call md5_transform

    lea rax, [rcx + md5_ctx.state]

    X86_64_epilog rbx, rsi, rdi
    ret
