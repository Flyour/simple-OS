#ifndef __USERPROG_SYSCALL_INIT_C
#define __USERPROG_SYSCALL_INIT_C
#include "stdint.h"
uint32_t sys_getpid(void);
void syscall_init(void);
uint32_t sys_write(char* str);
#endif
