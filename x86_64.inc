; LICENSE: public domain
; Author:  Michele Pes
;
; fasm [-d OS=LINUX] -> set linux/bsd, etc.
; none -> windows

match ,OS {
    display "'-d OS=' is not permitted"
    err
}

match any,OS {
    local ok
    define ok false

    match =OS,any \{
        define X86_64_format format MS64 COFF
        define X86_64_format32 format MS COFF
        define X86_64_section_DATA section '.data' data readable writeable
        define X86_64_section_CONST section '.const' data readable
        define X86_64_section_TEXT section '.text' code readable executable
        define X86_64_ARG_1 rcx
        define X86_64_ARG_2 rdx
        define X86_64_ARG_3 r8
        define X86_64_ARG_4 r9
        define X86_64_ARG_5 [rsp + 40]
        define X86_64_ARG_6 [rsp + 48]
        define ok true
        define X86_64_WINDOWS 1
    \}

    match =LINUX,any \{
        define X86_64_format format ELF64
        define X86_64_format32 format ELF
        define X86_64_section_DATA section '.data' writeable
        define X86_64_section_CONST section '.rodata'
        define X86_64_section_TEXT section '.text' executable
        define X86_64_ARG_1 rdi
        define X86_64_ARG_2 rsi
        define X86_64_ARG_3 rdx
        define X86_64_ARG_4 rcx
        define X86_64_ARG_5 r8
        define X86_64_ARG_6 r9
    	macro kernel service*, arg1, arg2, arg3, arg4, arg5, arg6
	    \\{
	        macro set_arg reg*, arg \\\{
	            if ~ arg eq
                    if ~ arg eq reg
	                    mov reg, arg
                    end if
	            end if
	        \\\}
	        set_arg r9,  arg6
	        set_arg r8,  arg5
	        set_arg r10, arg4
	        set_arg rdx, arg3
	        set_arg rsi, arg2
	        set_arg rdi, arg1
	        mov rax, service
	        syscall
	    \\}
        macro kernel32 service*, arg1, arg2, arg3, arg4, arg5, arg6
        \\{
            macro set_arg reg*, arg \\\{
	            if ~ arg eq
                    if ~ arg eq reg
	                    mov reg, arg
                    end if
	            end if
            \\\}
            set_arg ebp, arg6
            set_arg edi, arg5
            set_arg esi, arg4
            set_arg edx, arg3
            set_arg ecx, arg2
            set_arg ebx, arg1
            mov eax, service
            int $80
        \\}
        define ok true
        define X86_64_LINUX 1
        display "Generating Linux object code..."
    \}

    match =false,ok \{
        display "'-d OS=" # `any # "' is not permitted, set OS to LINUX or " \
                # "do not set at all for windows"
        err
    \}
}

macro ccall32 f*, [arg] {
    local n
    n = 0
    if ~ arg eq
        reverse
            push arg
            n = n + 4
    end if
    common
        call f
        if (n > 0)
            add esp, n
        end if
}

macro X86_64_save_rsi {
    match =OS,OS \{ push rsi \}
}

macro X86_64_save_rdi {
    match =OS,OS \{ push rdi \}
}

macro X86_64_save_rsdi {
    X86_64_save_rsi
    X86_64_save_rdi
}

macro X86_64_restore_rsi {
    match =OS,OS \{ pop rsi \}
}

macro X86_64_restore_rdi {
    match =OS,OS \{ pop rdi \}
}

macro X86_64_restore_rsdi {
    X86_64_restore_rdi
    X86_64_restore_rsi
}

; Uniform linux 64 ABI parameters on registers as windows
; Windows: rcx, rdx, r8,  r9,  others on stack in reverse order
; Linux:   rdi, rsi, rdx, rcx, r8,  r9, others on stack in reverse order
; P1       rcx, rsi, rdx, rdi, r8,  r9
; P2       rcx, rdx, rsi, rdi, r8,  r9
; P3       rcx, rdx, r8,  rdi, rsi, r9
; P4       rcx, rdx, r8,  r9,  rsi, rdi
macro X86_64_prolog n=0, [reg_to_save] {
    if (n > 0)
        common
        match =LINUX,OS \{ xchg rcx, rdi \}
        if (n > 1)
            match =LINUX,OS \{ xchg rdx, rsi \}
        end if
        if (n > 2)
            match =LINUX,OS \{ xchg r8,  rsi \}
        end if
        if (n > 3)
            match =LINUX,OS \{ xchg r9,  rdi \}
        end if
    end if
    if ~ reg_to_save eq
        forward
            if ~ reg_to_save in <RSI, RDI, rsi, rdi> | defined X86_64_WINDOWS
                push reg_to_save
            end if
    end if
}

macro X86_64_epilog [reg_to_restore] {
    if ~ reg_to_restore eq
        reverse
            if ~ reg_to_restore in <RSI, RDI, rsi, rdi> | defined X86_64_WINDOWS
                pop reg_to_restore
            end if
    end if
}

macro define_str name*, value*&
{
    name db value
    name#.sizeof = ($ - name)
}

define OFFSET
offset EQU OFFSET

macro JCOND o1*, cond*, o2*, label*
{
   cmp o1, o2
   j#cond label
}

macro JCONDS o1*, cond*, o2*, label*
{
   cmp o1, o2
   j#cond short label
}
