section .data
    orig_termios_buf times 64 db 0     ; buffer to save original termios
    termios_buf     times 64 db 0      ; buffer to modify termios
    input_char      db 0
    default_str    db '                    ', 10,  0
    cursor_col    dd 0            ; Column within that line
    show_cursor db 0x1B, '[?25h', 0  ;
    esc_sequence db 27, '[4A'
    up     db 27, '[A', 0         ; ESC [ A (move up)
    down   db 27, '[B', 0         ; ESC [ B (move down)
    right  db 27, '[C', 0         ; ESC [ C (move right)
    left   db 27, '[D', 0         ; ESC [ D (move left)
    
section .bss
    lines_buffer  resb 1024 * 22
    line_pointers resq 1024         ; Pointers to each line (64-bit)
    line_lengths  resd 1024         ; Lengths of each line
    num_lines     resd 1            ; Total lines
    current_line  resd 1            ; Which line cursor is on


section .text
    global _start

_start:
    mov rax, 1              ; sys_write
    mov rdi, 1              ; file descriptor: STDOUT
    mov rsi, show_cursor    ; pointer to the string
    mov rdx, 6              ; length of the ANSI code
    syscall


    mov dword [cursor_col], 0
    ; rsi = address of default_str
    lea rsi, [default_str]
    ; rdi = address of line_pointers
    lea rdi, [line_pointers]
    ; rbx = address of lines_buffer
    lea rbx, [lines_buffer]
    ; rcx = loop counter (number of lines)
    mov rcx, 1024


.copy_loop1:
    ; store pointer to current copy location in line_pointers
    mov [rdi], rbx

    ; copy 7 bytes from default_str to current buffer location
    mov rdx, 22
.copy_str:
    mov al, [rsi + rdx - 1]
    mov [rbx + rdx - 1], al
    dec rdx
    jnz .copy_str

    ; advance pointers
    add rdi, 8        ; move to next line_pointers entry
    add rbx, 22        ; move to next buffer slot
    loop .copy_loop1

    ; Get original terminal settings (TCGETS)
    mov rax, 16                      ; syscall: ioctl
    mov rdi, 0                       ; stdin (fd 0)
    mov rsi, 0x5401                  ; TCGETS
    lea rdx, [rel orig_termios_buf]
    syscall

    ; Copy original termios to termios_buf
    lea rsi, [rel orig_termios_buf]
    lea rdi, [rel termios_buf]
    mov rcx, 64
.copy_loop:
    mov al, [rsi]
    mov [rdi], al
    inc rsi
    inc rdi
    loop .copy_loop

    ; Modify termios: disable ICANON and ECHO (clear bits in c_lflag at offset 12)
    mov eax, dword [termios_buf + 12]
    and eax, ~0x00000002             ; ~ICANON
    and eax, ~0x00000008             ; ~ECHO
    mov [termios_buf + 12], eax

    ; Apply new termios (TCSETS)
    mov rax, 16
    mov rdi, 0
    mov rsi, 0x5402
    lea rdx, [rel termios_buf]
    syscall

.print_lines:

    mov r8, 0
.print_loop:
    mov rax, 1
    mov rdi, 1
    mov rsi, [line_pointers + 8*r8]
    mov rdx, 21
    syscall
    inc r8
    cmp r8, 4
    jl .print_loop

    mov rax, 1              ; syscall: write
    mov rdi, 1              ; file descriptor: stdout
    mov rsi, esc_sequence   ; pointer to string
    mov rdx, 4              ; length of string
    syscall

.loop_input:
    ; Read first byte
    mov rax, 0
    mov rdi, 0
    lea rsi, [rel input_char]
    mov rdx, 1
    syscall

    cmp byte [input_char], 0x1B     ; ESC
    jne .handle_char

    ; Read '['
    mov rax, 0
    mov rdi, 0
    lea rsi, [rel input_char]
    mov rdx, 1
    syscall
    cmp byte [input_char], '['
    jne .loop_input   ; Not an arrow key sequence

    ; Read final key
    mov rax, 0
    mov rdi, 0
    lea rsi, [rel input_char]
    mov rdx, 1
    syscall

    cmp byte [input_char], 'A'
    je .arrow_up
    cmp byte [input_char], 'B'
    je .arrow_down
    cmp byte [input_char], 'C'
    je .arrow_right
    cmp byte [input_char], 'D'
    je .arrow_left

    jmp .loop_input

.arrow_left:
    mov rax, 1
    mov rdi, 1
    mov rsi, left
    mov rdx, 3
    syscall

    cmp dword [cursor_col], 0
    je .loop_input
    dec dword [cursor_col]
    jmp .loop_input

.arrow_right:
    mov rax, 1
    mov rdi, 1
    mov rsi, right
    mov rdx, 3
    syscall

    inc dword [cursor_col]
    jmp .loop_input

.arrow_up:
    mov rax, 1
    mov rdi, 1
    mov rsi, up
    mov rdx, 3
    syscall

    cmp dword [current_line], 0
    je .loop_input
    dec dword [current_line]
    jmp .loop_input

.arrow_down:
    mov rax, 1
    mov rdi, 1
    mov rsi, down
    mov rdx, 3
    syscall

    inc dword [current_line]
    jmp .loop_input

.handle_char:
    ; Handle normal characters here (store to buffer, print, etc.)
    ; Example:
    mov rcx, [current_line]
    mov edx, [cursor_col]
    movzx rdi, byte [input_char]
    mov rax, [line_pointers + 8*rcx]
    mov byte [rax + rdx], dil
    inc dword [cursor_col]
    mov rax, 1                        ; sys_write syscall
    mov rdi, 1                        ; STDOUT (file descriptor 1)
    lea rsi, [input_char]             ; Address of the input character
    mov rdx, 1                        ; Length of the character (1 byte)
    syscall    

    jmp .loop_input


.restore_and_exit:
    ; Restore original terminal settings (TCSETS)
    mov rax, 16
    mov rdi, 0
    mov rsi, 0x5402
    lea rdx, [rel orig_termios_buf]
    syscall

    ; Exit
    mov rax, 60                      ; syscall: exit
    xor rdi, rdi
    syscall
