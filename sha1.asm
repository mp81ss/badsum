include '%fasm%/INCLUDE/MACRO/STRUCT.INC'
include 'x86_64.inc'

X86_64_format

public sha1_init
public sha1_update
public sha1_final


struct sha1_ctx
    buffer db 64 dup(?)
    count dq ?
    state dd 5 dup(?)
ends


X86_64_section_TEXT align 16

sha1_transform:

    define a r8d
    define b r9d
    define c r10d
    define d r11d
    define e r12d

    mov rbp, rsp                        ; allocate (80 ints (320 bytes))
    sub rsp, 320
    and spl, 0xf0

    lea rax, [rcx + sha1_ctx.state]     ; load state variables
    mov a, [rax]
    mov b, [rax + 4]
    mov c, [rax + 8]
    mov d, [rax + 12]
    mov e, [rax + 16]

    rept 80 idx:0 {

        if idx < 16                     ; convert endian on first 16 ints
            mov eax, [rdx + idx*4]
            movbe [rsp + idx*4], eax
        else                            ; popolate remaining temp buffer
	        mov eax, [rsp + ((idx - 3) * 4)]
	        xor eax, [rsp + ((idx - 8) * 4)]
	        xor eax, [rsp + ((idx - 14) * 4)]
	        xor eax, [rsp + ((idx - 16) * 4)]
	        rol eax, 1
	        mov [rsp + idx*4], eax
        end if
    
        mov eax, a
        rol eax, 5
        add eax, e
        add eax, [rsp + idx*4]          ; eax = tmp

        if idx < 20
            mov esi, c
            mov ebx, b
            xor esi, d
            and ebx, esi
            xor ebx, d
            lea eax, [eax + ebx + 0x5A827999]
        else if idx < 40
            mov ebx, b
            xor ebx, c
            xor ebx, d
            lea eax, [eax + ebx + 0x6ED9EBA1]
        else if idx < 60
            mov ebx, b
            mov esi, b
            and ebx, c
            or esi, c
            mov edi, d
            and edi, esi
            or ebx, edi
            lea eax, [eax + ebx + 0x8F1BBCDC]
        else
            mov ebx, b
            xor ebx, c
            xor ebx, d
            lea eax, [eax + ebx + 0xCA62C1D6]
        end if

        mov e, d                        ; update state variables
        mov d, c 
        mov c, b
        rol c, 30
        mov b, a
        mov a, eax
    }
    
    lea rax, [rcx + sha1_ctx.state]     ; update state
    add [rax], a
    add [rax + 4], b
    add [rax + 8], c
    add [rax + 12], d
    add [rax + 16], e

    mov rsp, rbp
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

sha1_init:
    X86_64_prolog(1)
    mov rax, -1167088121787636991
    mov QWORD [rcx + sha1_ctx.count], 0
    mov rdx, 1167088121787636990
    mov QWORD [rcx + sha1_ctx.state], rax
    mov QWORD [rcx + 80], rdx
    mov DWORD [rcx + 88], -1009589776
    ret

sha1_update:
    X86_64_prolog(3), rbx, rsi, rdi, rbp, r12

    and r8d, r8d
    mov r9, [rcx + sha1_ctx.count]       ; load count
    add [rcx + sha1_ctx.count], r8       ; update new count
    and r9, 0x3f
    test r9d, r9d
    je short main_upd_loop

    mov r10d, r9d
    sub r9, 64
    neg r9
    cmp r8, r9
    cmovb r9d, r8d                      ; r9 is chunk, r11 is dest pointer
    lea r11, [rcx + sha1_ctx.buffer + r10]
    sub r8, r9                          ; update remaining
    add r10d, r9d                       ; r10 is buf_size + chunk
    memcpy r11, rdx, r9
    cmp r10l, 64
    jb short final_cpy
    push rdx r8
    lea rdx, [rcx + sha1_ctx.buffer]
    call sha1_transform
    pop r8 rdx

main_upd_loop:
    cmp r8d, 64
    jb short final_cpy
@@:
    push r8
    call sha1_transform
    pop r8
    add rdx, 64
    sub r8d, 64
    cmp r8d, 64
    jae short @b

final_cpy:
    lea rcx, [rcx + sha1_ctx.buffer]
    memcpy rcx, rdx, r8

    X86_64_epilog rbx, rsi, rdi, rbp, r12
    ret

sha1_final:
    X86_64_prolog(1), rbx, rsi, rdi, rbp, r12

    mov r8, [rcx + sha1_ctx.count]      ; save old count in r8

    mov edx, r8d
    and edx, 0x3f                       ; rdx is buffer_size
    mov r9d, 56
    lea rdi, [rcx + sha1_ctx.buffer + rdx]
    inc edx
    mov al, 0x80                        ; pad first byte with highest bit set
    inc [rcx + sha1_ctx.count]
    stosb

    cmp edx, r9d
    jbe short few_pad

    sub rdx, 64
    neg rdx                             ; calculate (64 - buf_size)

    add [rcx + sha1_ctx.count], rdx     ; update count for big padding
    mov r9d, edx                        ; Set padding len in r9d for do_pad
    call do_pad
    push r8
    lea rdx, [rcx + sha1_ctx.buffer]
    call sha1_transform
    pop r8
    mov r9d, 56                         ; restore r9 to 56
    xor edx, edx                        ; buf_size set to zero
    lea rdi, [rcx + sha1_ctx.buffer]    ; restore rdi for final pad

few_pad:
    sub r9d, edx                        ; calculate padding len
    add [rcx + sha1_ctx.count], r9
    call do_pad

    sal r8, 3                           ; store big-endian old bit count
    movbe qword [rcx + sha1_ctx.buffer + 56], r8

    lea rdx, [rcx + sha1_ctx.buffer]
    call sha1_transform                 ; last call to transform

    lea rax, [rcx + sha1_ctx.state]     ; convert hash to big-endian
    rept 5 idx:0 {
        mov edx, [rax + idx*4]
        movbe [rax + idx*4], edx
    }

    X86_64_epilog rbx, rsi, rdi, rbp, r12
    ret
