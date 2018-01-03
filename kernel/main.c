#include "print.h"
#include "init.h"
#include "debug.h"
#include "thread.h"

void k_thread_a(void*);

int  main(void){
    put_str("I am kernel\n");
    init_all();

    thread_start("k_thread_a", 31, k_thread_a, "argA ");

    //void* addr = get_kernel_pages(3);
    //put_str("\n get_kernel_page start vaddr is ");
    //put_int((uint32_t)addr);
    //put_str("\n");

    //ASSERT(1==2);
    //asm volatile("sti");    //为演示中断处理，在此临时开中断
    while(1);
    return 0;
}

/* 在进程中运行的函数 */
void k_thread_a(void* arg){
    /* 有被调用函数来将输入参数强制转换类型*/
    char* para = arg;
    while(1){
        put_str(para);
    }
}
