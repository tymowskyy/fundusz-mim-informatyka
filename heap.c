#include <stdio.h>
#include <stdint.h>

extern void add(int64_t x, int64_t* heap);
extern int64_t pop(int64_t* heap);

int main() {
    int64_t n = 0;
    int64_t heap[32];
    heap[0] = 0;

    add(10, heap);
    add(9, heap);
    add(30, heap);
    add(11, heap);

    // int64_t a =  pop(heap);
    printf("%lu\n", pop(heap));
    printf("%lu\n", pop(heap));
    
    add(2, heap);
    add(15, heap);

    printf("%lu\n", pop(heap));
    printf("%lu\n", pop(heap));
    printf("%lu\n", pop(heap));
    printf("%lu\n", pop(heap));

    return 0;
}
