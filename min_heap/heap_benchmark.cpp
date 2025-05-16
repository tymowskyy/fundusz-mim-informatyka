#include <iostream>

extern "C" void add(int64_t x, int64_t* heap);
extern "C" int64_t pop(int64_t* heap);
int main() {
    std::ios_base::sync_with_stdio(false); std::cin.tie(NULL);

    int64_t heap[524288];
    heap[0] = 0;

    int n;
    std::cin >> n;
    char c;
    int x;
    for (int i=0; i<n; ++i) {
        std::cin >> c;
        if (c=='a') {
            std::cin >> x;
            add(static_cast<int64_t>(x), heap);
        }
        else {
            std::cout << pop(heap) << '\n';
        }
    }

    return 0;
}
