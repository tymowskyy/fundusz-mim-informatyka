nasm -f elf64 heap.asm -o heap.o
gcc -no-pie -o heap heap.c heap.o
./heap 