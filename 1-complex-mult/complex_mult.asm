; Function prototype in C++:
; void complex_mul(float a, float b, float c, float d, float* real_out, float* imag_out);

section .text
    global complex_mul

complex_mul:
    ; xmm0 = a xmm1=b xmm2=c xmm3=d
    ; o1 = a * c - (b*d)
    ; o2 = a * d + b * c

    movss xmm5, xmm0
    movss xmm6, xmm1

    mulss xmm5, xmm2
    mulss xmm6, xmm3
    subss xmm5, xmm6
    movss [rdi], xmm5

    movss xmm5, xmm0
    movss xmm6, xmm1

    mulss xmm5, xmm3
    mulss xmm6, xmm2
    addss xmm5, xmm6
    movss [rsi], xmm5

    ret