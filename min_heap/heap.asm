global add, pop

section .text

; rdi rsi rdx

add: ; x-rdi heap-rsi
    inc qword [rsi]
    mov rcx, [rsi]
    mov [rsi + 8*rcx], rdi

.heapup:

    mov rax, rcx
    shr rcx, 1

    cmp rcx, 0
    jle .done

    mov     rdx, [rsi + 8*rcx]
    mov     r8,  [rsi + 8*rax]

    cmp r8, rdx
    jge .done

    mov     [rsi + 8*rcx], r8
    mov     [rsi + 8*rax], rdx

    jmp .heapup

.done:
    ret


pop: ; heap-rdi

    mov rcx, [rdi]
    mov rax, [rdi + 8]

    lea rbx, [rdi + 8*rcx]
    mov rbx, [rbx]
    mov [rdi + 8], rbx
    ; mov [rdi + 8], [rdi + 8*rcx]

    dec qword [rdi]
  
    mov rdx, 1

.heapdown:
    mov r8, rdx
    shl r8, 1

    cmp r8, rcx
    jge .done

    mov r9, r8
    inc r9

    cmp r9, rcx
    jge .heapleft

    lea rbx, [rdi + 8*r9]
    mov rbx, [rbx]
    cmp [rdi + 8*r8], rbx

    jle .heapleft

    mov r8, r9


.heapleft:
    mov r9, [rdi + 8*r8]
    mov r10, [rdi + 8*rdx]

    cmp r9, r10
    jge .done

    ;swap
    mov [rdi + 8*r8], r10
    mov [rdi + 8*rdx], r9
    mov rdx, r8
    jmp .heapdown

.done:
    ret
