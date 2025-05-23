section .data
    orig_termios_buf times 64 db 0     ; buffer to save original termios
    termios_buf     times 64 db 0      ; buffer to modify termios
    input_char      db 0
    default_str:
        times 128 db 'x', 10
        db 0
    ;default_str    db '                    ', 10,  0
    nl db 10, 0

    cursor_col    dd 0            ; Column within that line
    show_cursor db 0x1B, '[?25h', 0  ;
    up     db 27, '[A', 0         ; ESC [ A (move up)
    down   db 27, '[B', 0         ; ESC [ B (move down)
    right  db 27, '[C', 0         ; ESC [ C (move right)
    left   db 27, '[D', 0         ; ESC [ D (move left)
    clear db 27, '[2J', 27, '[H', 0
    home db 27, '[H', 0
    save_cursor db 27, '[s', 0
    restore_cursor db 27, '[u', 0
    clear_line db 27, '[2K', 0
    gray db 27, '[48', 59, '5', 59, '240m', 0
    reset_color db 27, '[0m', 0
    spaces:
        times 32 db 'a',
        db 10
    displayed_lines_num dd 8

    
section .bss
    lines_buffer  resb 1024 * 129
    line_pointers resq 1024         ; Pointers to each line (64-bit)
    line_lengths  resd 1024         ; Lengths of each line
    num_lines     resd 1            ; Total lines
    current_line  resd 1            ; Which line cursor is on
    arg_len resd 1
    arg_point resq 1
    top_line resd 1
    cursor_line resd 1


section .text
    global _start

_start:
    mov dword [num_lines], 1
    mov rbx, rsp              ; save stack pointer
    mov rdi, [rbx]            ; argc
    cmp rdi, 2                ; check if argc >= 2
    jl .no_arg
    mov rsi, [rbx + 16]       ; argv[1] is at [rsp + 8*2] = [rbx + 16]

    ; Get string length
    mov rdi, rsi              ; rdi = pointer to string
    mov [arg_point], rsi
    call strlen

    ; write(1, argv[1], len)
    mov dword [arg_len], eax

.no_arg:


    mov rax, 1              ; sys_write
    mov rdi, 1              ; file descriptor: STDOUT
    mov rsi, show_cursor    ; pointer to the string
    mov rdx, 6              ; length of the ANSI code
    syscall


    mov rax, 1              ; sys_write
    mov rdi, 1              ; file descriptor: STDOUT
    mov rsi, clear    ; pointer to the string
    mov rdx, 7              ; length of the ANSI code
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
    mov rdx, 129
.copy_str:
    mov al, [rsi + rdx - 1]
    mov [rbx + rdx - 1], al
    dec rdx
    jnz .copy_str

    ; advance pointers
    add rdi, 8        ; move to next line_pointers entry
    add rbx, 129        ; move to next buffer slot
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

    jmp .print_lines
.loop_input:
    ; Read first byte
    mov rax, 0
    mov rdi, 0
    lea rsi, [rel input_char]
    mov rdx, 1
    syscall

    cmp byte [input_char], '`'
    je .backspace
    cmp byte [input_char], 9
    je .restore_and_exit
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
    cmp dword [current_line], 0
    je .loop_input

    dec dword [current_line]
    cmp dword [cursor_line], 0
    je .scroll_up

    dec dword [cursor_line]

    mov rax, 1
    mov rdi, 1
    mov rsi, up
    mov rdx, 3
    syscall

    jmp .set_cursor_col
.scroll_up:
    dec dword [top_line]
    jmp .set_cursor_col


.arrow_down:
    inc dword [current_line]
    mov eax, [cursor_line]
    
    cmp eax, [num_lines]
    jl .not_new

    inc dword [num_lines]

.not_new:

    inc dword eax
    cmp eax, [displayed_lines_num]
    jge .scroll_down

    inc dword [cursor_line]
    mov rax, 1
    mov rdi, 1
    mov rsi, down
    mov rdx, 3
    syscall
    jmp .set_cursor_col

.scroll_down:
    inc dword [top_line]
    jmp .set_cursor_col



.set_cursor_col:
    mov edi, [current_line]
    mov r8d, [line_lengths + 4*rdi]
    .loop_cursor_move:
    cmp [cursor_col], r8d
    jle .print_lines
    dec dword [cursor_col]
    mov rax, 1
    mov rdi, 1
    mov rsi, left
    mov rdx, 3
    syscall
    jmp .loop_cursor_move

.backspace:
    mov ecx, [current_line]

    dec dword [line_lengths + 4*rcx]
    dec dword [cursor_col]
    mov edx, [cursor_col]
    mov edi, [line_lengths + 4*rcx]
    mov rax, [line_pointers + 8*rcx]


    cmp rdi, rdx
    jle .pushedleft
    .loop_pushleft:
    mov r8b, [rax + rdx + 1]
    mov byte [rax + rdx], r8b
    inc rdx
    cmp rdi, rdx
    jg .loop_pushleft
    .pushedleft:

    mov rax, 1                        ; sys_write syscall
    mov rdi, 1                        ; STDOUT (file descriptor 1)
    mov rsi, left             ; Address of the input character
    mov rdx, 3                        ; Length of the character (1 byte)
    syscall 
    jmp .print_lines

.handle_char:

    mov rax, 1                        ; sys_write syscall
    mov rdi, 1                        ; STDOUT (file descriptor 1)
    mov rsi, right             ; Address of the input character
    mov rdx, 3                        ; Length of the character (1 byte)
    syscall    
    ; Handle normal characters here (store to buffer, print, etc.)
    ; Example:
    mov ecx, [current_line]
    mov edx, [cursor_col]

    mov edi, [line_lengths + 4*rcx]
    mov rax, [line_pointers + 8*rcx]
    dec rdi

    cmp rdi, rdx
    jl .pushedright
.loop_pushright:
    mov r8b, [rax + rdi]
    mov byte [rax + rdi + 1], r8b
    dec rdi
    cmp rdi, rdx
    jge .loop_pushright
.pushedright:



    inc dword [line_lengths + 4*rcx]

    movzx rdi, byte [input_char]
    mov rax, [line_pointers + 8*rcx]
    mov byte [rax + rdx], dil
    inc dword [cursor_col]


.print_lines:
    mov rax, 1                        ; sys_write syscall
    mov rdi, 1                        ; STDOUT (file descriptor 1)
    mov rsi, save_cursor             ; Address of the inputf character
    mov rdx, 3                       ; Length of the character (1 byte)
    syscall    
    mov rax, 1              ; sys_write
    mov rdi, 1              ; file descriptor: STDOUT
    mov rsi, home    ; pointer to the string
    mov rdx, 3              ; length of the ANSI code
    syscall

    mov r8d, [top_line]
    mov r9, r8
    add r9d, [displayed_lines_num]
    
.print_loop:
    mov rax, 1                        ; sys_write syscall
    mov rdi, 1                        ; STDOUT (file descriptor 1)
    mov rsi, clear_line             ; Address of the input character
    mov rdx, 4                        ; Length of the character (1 byte)
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, [line_pointers + 8*r8]
    mov edx, [line_lengths + 4*r8]
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, nl
    mov rdx, 1
    syscall
    inc r8
    cmp r8, r9
    jl .print_loop


    mov rax, 1                        ; sys_write syscall
    mov rdi, 1                        ; STDOUT (file descriptor 1)
    mov rsi, gray             ; Address of the input character
    mov rdx, 12                        ; Length of the character (1 byte)
    syscall
    mov rax, 1                        ; sys_write syscall
    mov rdi, 1                        ; STDOUT (file descriptor 1)
    mov rsi, [arg_point]             ; Address of the input character
    mov edx, [arg_len]                       ; Length of the character (1 byte)
    syscall

    mov rax, 1                        ; sys_write syscall
    mov rdi, 1                        ; STDOUT (file descriptor 1)
    mov rsi, reset_color             ; Address of the input character
    mov rdx, 4                        ; Length of the character (1 byte)
    syscall

    mov rax, 1                        ; sys_write syscall
    mov rdi, 1                        ; STDOUT (file descriptor 1)
    mov rsi, restore_cursor             ; Address of the input character
    mov rdx, 3                        ; Length of the character (1 byte)
    syscall
    


    jmp .loop_input


.restore_and_exit:
    mov rax, 1              ; sys_write
    mov rdi, 1              ; file descriptor: STDOUT
    mov rsi, clear    ; pointer to the string
    mov rdx, 7              ; length of the ANSI code
    syscall
    ; Restore original terminal settings (TCSETS)
    mov rax, 16
    mov rdi, 0
    mov rsi, 0x5402
    lea rdx, [rel orig_termios_buf]
    syscall


    mov     rax, 2              ; sys_open
    mov     rdi, [arg_point]       ; filename
    mov     rsi, 0x241          ; O_WRONLY | O_CREAT | O_TRUNC = 0x1 | 0x40 | 0x200 = 0x241
    mov     rdx, 0o644          ; file permission
    syscall
    mov     r12, rax            ; save file descriptor

    mov r8, 0
.save_loop:

    mov rax, 1
    mov rdi, r12
    mov rsi, [line_pointers + 8*r8]
    mov edx, [line_lengths + 4*r8]
    syscall
    mov rax, 1
    mov rdi, r12
    mov rsi, nl
    mov rdx, 1
    syscall
    inc r8
    cmp r8d, [num_lines]
    jl .save_loop

    ; sys_close(fd)
    mov     rax, 3              ; sys_close
    mov     rdi, r12
    syscall

    ; sys_exit(0)
    mov     rax, 60             ; sys_exit
    xor     rdi, rdi            ; status = 0
    syscall


    ; Exit
    mov rax, 60                      ; syscall: exit
    xor rdi, rdi
    syscall


strlen:
    push rdi
    xor rcx, rcx
.next:
    cmp byte [rdi + rcx], 0
    je .done
    inc rcx
    jmp .next
.done:
    mov rax, rcx
    pop rdi
    ret