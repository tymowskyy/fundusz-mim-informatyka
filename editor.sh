nasm -f elf64 editor.asm -o factorial64_syscall.o
ld factorial64_syscall.o -o factorial64_syscall
./factorial64_syscall