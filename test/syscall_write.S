section .data
str_c_lib: db "c liibrary says: hello world!", 0xa ; 0xa 为LF ASCII码
str_c_lib_len equ $-str_c_lib

str_syscall: db " syscall says: helllo world!", 0xa
str_syscall_len equ $-str_syscall

section .text
global _start

;-----------方式一：模拟c语言中系统调用库函数write--------------------
_start:
    push str_c_lib_len  ;按照c调用约定压入参数
    push str_c_lib
    push 1

    call simu_write     ;调用下面定义的simu_write
    add esp, 12

;----------方式二：跨过库函数，直接进行系统调用-------------------------
    mov eax, 4    ;第4号子功能是write系统调用（不是c库函数write）
    mov ebx, 1
    mov ecx, str_syscall
    mov edx, str_syscall_len
    int 0x80      ;发起中断，通知linux完成请求的功能

;----------退出程序----------------------
    mov eax, 1    ;第1号子功能是exit
    int 0x80      ;发起中断，通知linux完成请求的功能

;---------下面自定义的simu_write用来模拟c库中系统调用函数write
;---------这里模拟他的实现原理-------------------------------
simu_write:
    push ebp    ;备份ebp
    mov ebp, esp
    mov eax, 4  ;第4号子功能是write系统调用（不是c库函数write）
    mov ebx, [ebp+8]
    mov ecx, [ebp+12]
    mov edx, [ebp+16]
    int 0x80
    pop ebp
    ret


