import random
seed = int(input())
random.seed(seed)

# N = 500000
START_N = 260000//2
N = 200000
MAX_K = 1000000
MIN_N = 10000
MAX_N= 520000
print(2*N)
cnt = 0
for i in range(START_N):
    cnt+=1
    print(f'a {random.randint(0, MAX_K)}')

for i in range(N):
    if (random.randint(0, 1) and cnt<MAX_N) or cnt >=  MIN_N:
        cnt +=1
        print(f'a {random.randint(0, MAX_K)}')
    else:
        print(f'p')
        cnt -= 1