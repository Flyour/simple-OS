char * str = "hello, world\n";
int count = 0;
int main(){
    asm (   "pusha; \
            movl $4, %eax; \
            movl $1, %ebx; \
            mov str, %ecx; \
            movl $12, %edx; \
            int $0x80; \
            mov %eax, count; \
            popa    \
            ");
}