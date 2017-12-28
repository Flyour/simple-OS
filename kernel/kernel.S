[bits 32]
%define ERROR_CODE nop  ;若在相关的异常中cpu已经自动压入了错误码，
                        ;为保持栈中格式统一，这里不做操作

%define ZERO push 0     ;若在相关的异常中cpu没有压入错误码，为了统一栈中
                        ;格式，就手工压入一个0
extern put_str  ;生命外部函数

section .data
intr_str db "interrupt occur", 0xa, 0

;这里定义了一个数组，并用global语句导出为全局字符
global intr_entry_table
intr_entry_table:   ;这个字符的内容在哪里？在这里没有对内容做定义
                    ;编译后，下面宏的定义消失，只剩下对宏的调用
                    ;每次调用中的.data节，都会被整合在第一个 .data节处
                    ;也就是这里,所以这里会形成一个数组


%macro VECTOR 2 ;定义了一个名为VECTOR的宏，接受2个参数
section .text   ;用做代码范围的起始定义
intr%1entry:            ;每个中断处理程序都要压入中断向量号
                        ;所以一个中断类型一个中断处理程序
                        ;利用宏，使中断程序的标号中带有对应的中断向量号
    %2
    push intr_str
    call put_str
    add esp, 4  ;调用函数后，处理栈中的参数

    ;如果是从片上进入的中断，除了往从片上发送EOI外，还要往主片上发送EOI
    mov al, 0x20        ;中断结束命令EOI
    out 0xa0, al        ;向从片发送
    out 0x20, al        ;向主片发送,告诉8259A芯片，中断已经处理完

    add esp, 4          ;跨过error_code
    iret                ;从中断返回，32位下等同指令iretd

section .data
    dd intr%1entry      ;存储各个中断入口程序的地址
                        ;形成intr_entry_table数组
%endmacro

VECTOR 0x00, ZERO
VECTOR 0x01, ZERO
VECTOR 0X02, ZERO
VECTOR 0X03, ZERO
VECTOR 0X04, ZERO
VECTOR 0X05, ZERO
VECTOR 0X06, ZERO
VECTOR 0X07, ZERO
VECTOR 0X08, ZERO
VECTOR 0X09, ZERO
VECTOR 0X0a, ZERO
VECTOR 0X0b, ZERO
VECTOR 0X0c, ZERO
VECTOR 0X0d, ZERO
VECTOR 0X0e, ZERO
VECTOR 0X0f, ZERO
VECTOR 0X10, ZERO
VECTOR 0X11, ZERO
VECTOR 0X12, ZERO
VECTOR 0X13, ZERO
VECTOR 0X14, ZERO
VECTOR 0X15, ZERO
VECTOR 0X16, ZERO
VECTOR 0X17, ZERO
VECTOR 0X18, ZERO
VECTOR 0X19, ZERO
VECTOR 0X1a, ZERO
VECTOR 0X1b, ZERO
VECTOR 0X1c, ZERO
VECTOR 0X1d, ZERO
VECTOR 0X1e, ERROR_CODE
VECTOR 0X1f, ZERO
VECTOR 0X20, ZERO

