g++ -no-pie -o heap_std heap_benchmark_std.cpp -O3
nasm -f elf64 heap.asm -o heap.o
g++ -no-pie -o heap_my heap_benchmark.cpp heap.o
echo 1 > seed
python3 gen_test.py < seed > test
echo my
time ./heap_my < test > out_my
echo std
time ./heap_std < test > out_std
echo diff
diff out_my out_std