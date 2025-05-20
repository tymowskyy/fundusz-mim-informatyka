#include <queue>
#include <iostream>
#include <vector>

int main() {
    std::ios_base::sync_with_stdio(false); std::cin.tie(NULL);

    std::priority_queue<int64_t, std::vector<int64_t>, std::greater<int64_t>> pq;

    int n;
    std::cin >> n;
    char c;
    int x;
    for (int i=0; i<n; ++i) {
        std::cin >> c;
        if (c=='a') {
            std::cin >> x;
            pq.push(static_cast<int64_t>(x));
        }
        else {
            std::cout << pq.top() << '\n';
            pq.pop();
        }
    }

    return 0;
}
