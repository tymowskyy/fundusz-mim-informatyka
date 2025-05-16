global add, pop

section .text

; rdi rsi rdx

add: ; x-rdi stack-rsi n-rdx
    inc qword [rdx]
    mov rcx, [rdx]
    mov [rsi + 8*rcx], rdi
    ret

pop: ; stack-rdi n-rsi
    mov rcx, [rsi]
    mov rax, [rdi + 8*rcx]
    dec qword [rsi]
    ret