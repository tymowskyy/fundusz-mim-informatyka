#include <stdio.h>
#include <stdint.h>

extern void add(int64_t x, int64_t* stack, int64_t* n);
extern int64_t pop(int64_t* stack, int64_t* n);

int main() {
    int64_t n = 0;
    int64_t stack[32];

    add(10, stack, &n);
    add(9, stack, &n);
    add(30, stack, &n);
    add(11, stack, &n);

    printf("%lu\n", pop(stack, &n));
    printf("%lu\n", pop(stack, &n));
    
    add(2, stack, &n);
    add(15, stack, &n);

    printf("%lu\n", pop(stack, &n));
    printf("%lu\n", pop(stack, &n));
    printf("%lu\n", pop(stack, &n));
    printf("%lu\n", pop(stack, &n));

    return 0;
}
