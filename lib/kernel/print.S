TI_GDT equ 0
RPL0 equ 0
SELECTOR_VIDEO equ (0x0003 << 3) + TI_GDT + RPL0

[bits 32]
section .data
put_int_buffer dq 0

section .text
;==============================================================
;put_str 通过put_char来打印以0字符结尾的字符串
;输入：栈中参数为打印的字符串
;输出：无
;=============================================================
global put_str
put_str:
    push ebx
    push ecx
    xor ecx, ecx
    mov ebx, [esp + 12] ;从栈中得到待打印字符串的地址
.goon:
    mov cl, [ebx]
    cmp cl, 0           ;如果处理到了字符串尾，跳到结束处返回
    jz .str_over
    push ecx            ;为put_char函数传递参数
    call put_char
    add esp, 4          ;回收参数所占的栈空间
    inc ebx             ;使ebx指向下一个字符
    jmp .goon
.str_over:
    pop ecx
    pop ebx
    ret





;===============================================================
;put_char : 把栈中的1个字符写入光标所在处
;================================================================
global put_char
put_char:
    pushad   ;备份32位寄存器环境

    ;需要保证gs中为正确的视频段选择子
    ;为保险起见，每次打印时都为gs赋值
    mov ax, SELECTOR_VIDEO ;不能直接把立即数送入段寄存器
    mov gs, ax

;-------------获取当前的光标位置-----------------------------------
    ;先获得高8位
    mov dx, 0x03d4  ;索引寄存器
    mov al, 0x0e    ;用于提供光标位置的高8位
    out dx, al      ;out 往端口输出数据
    mov dx, 0x03d5  ;通过读写数据端口0x3d5来获得或设置光标位置
    in al, dx      ;得到了光标位置的高8位
    mov ah,al

    ;再获取低8位
    mov dx, 0x03d4
    mov al, 0x0f
    out dx, al
    mov dx, 0x03d5
    in al, dx

    ;将光标存入bx
    mov bx, ax
    ;下面这行是在栈中获取待打印的字符
    mov ecx, [esp + 36]     ;pushad 压入4×8=32字节
                            ;加上主调函数4字节的返回地址，故esp +36字节
    cmp cl, 0xd             ;CR是0x0d,LF是0x0a
    jz .is_carriage_return
    cmp cl, 0xa
    jz .is_line_feed

    cmp cl, 0x8
    jz .is_backspace

    jmp .put_other

.is_backspace:
    dec bx
    shl bx, 1 ;光标左移1位等与乘2
              ;表示光标对应显存中的偏移字节

    mov byte [gs:bx], 0x20
    inc bx
    mov byte [gs:bx], 0x07
    shr bx, 1
    jmp .set_cursor

.put_other:
    shl bx, 1   ;光标位置用2字节表示，将光标值乘2
                ;表示对应显存中的偏移字节
    mov [gs:bx], cl ;ASCII字符本身
    inc bx
    mov byte [gs:bx], 0x07 ;字符属性
    shr bx, 1              ;恢复老的光标值
    inc bx                 ;下一个光标值
    cmp bx, 2000
    jl .set_cursor      ;若光标值小与2000,表示未写到
                        ;显存的最后，则去设置新的光标值
                        ;若超出屏幕字符数大小（2000)
                        ;则换行处理

.is_line_feed:          ;是换行符LF（\n）
.is_carriage_return:    ;是回车附CR（\r）
                        ;如果是CR(\r),只要把光标移到行首就行了
    xor dx, dx ;dx 是被除数的高16位，清0
    mov ax, bx ;ax 是被除数的低16位
    mov si, 80 ;
    div si
    sub bx, dx ;光标值减去除80的余数便是取整

.is_carriage_return_end: ;回车符CR处理结束
    add bx, 80
    cmp bx, 2000

.is_line_feed_end:       ;若是LF，将光标移+80便可
    jl .set_cursor

;屏幕行范围是0～24,滚屏的原理是将屏幕的第1～24行搬运到第0～23行
;再将第24行用空格填充
.roll_screen:
    cld     ;用cld指令清除方向位，就是把dflags的DF位清零
    mov ecx, 960    ;2000-80=1920个字符要搬运，共1920*2=3840字节
                    ;一次搬4字节，共3840/4=960次
    mov esi, 0xc00b80a0     ;第1行行首
    mov edi, 0xc00b8000     ;第0行行首
    rep movsd

;------------------将最后一行填充为空白--------------------------
    mov ebx, 3840   ;最后一行首字符的第一个字节偏移=1920×2
    mov ecx, 80     ;一行是80字符（160字节），每次清空1字符
                    ;(2字节），一行需要移动80次

.cls:
    mov word [gs:ebx], 0x0720 ;0x0720是黑底白字的空格建
    add ebx, 2
    loop  .cls
    mov bx, 1920    ;将光标值重置为1920,最后一行的首字符

;------------------将光标设为bx值---------------------------------
.set_cursor:

    ;先设置高8位
    mov dx, 0x03d4      ;索引寄存器
    mov al, 0x0e        ;用于提供光标位置的高8位
    out dx, al
    mov dx, 0x03d5      ;通过读写数据端口0x3d5来获得或设置光标位置
    mov al, bh
    out dx, al

    ;再设置低8位
    mov dx, 0x03d4
    mov al, 0x0f
    out dx, al
    mov dx, 0x03d5
    mov al, bl
    out dx, al

.put_char_done:
    popad
    ret

;===================================================================
;将小端字节序的数字变成对应的ASCII后，倒置
;输入:栈中参数为待打印的数字
;输出:在屏幕上打印十六进制数字，并不会打印前缀0x
;====================================================================
global put_int
put_int:
    pushad
    mov ebp, esp
    mov eax, [ebp+4*9] ;call的返回地址占4字节+pushad的8个4字节
    mov edx, eax
    mov edi, 7  ;指定在put_int_buffer中初始的偏移量
    mov ecx, 8  ;32位数字中，十六进制数字的位数是8个
    mov ebx, put_int_buffer

;将32位数字按照十六进制的形式从低位到高位逐个处理
;共处理8个十六进制数字
.16based_4bits:
    and edx, 0x0000000f ;and与操作后，edx只有低4位有效

    cmp edx, 9          ;数字0～9和a~f需要分别处理成对应的字符
    jg .is_A2F
    add edx, '0'        ;ASCII码是8位大小，add求和操作后，edx低8位有效
    jmp .store

.is_A2F:
    sub edx, 10 ;A~F减去10所得到的差，再加上字符A的ASCII码
    add edx, 'A'

;将每一位数字转换成对应的字符后，按照类似“大端”的顺序
;存储到缓冲区put_int_buffer
;高位字符放在低地址，低位字符要放在高地址，这样和大端字节序类似
.store:
    mov [ebx+edi], dl ;把字符放在缓冲区相应的位置
    dec edi
    shr eax, 4
    mov edx, eax
    loop .16based_4bits

;现在put_int_buffer中已全是字符，打印之前，把高位连续的字符去掉
;比如把字符000123变成123
.ready_to_print:
    inc edi ;加1,使edx此时为0
.skip_prefix_0:
    cmp edi, 8  ;若已经比较第9个字符了,表示待打印的的字符串全为0
    je .full0

;找出连续的0字符，edi作为非0的最高位字符的偏移
.go_on_skip:
    mov cl, [put_int_buffer+edi]
    inc edi
    cmp cl, '0'
    je .skip_prefix_0 ;继续判断下一位字符是否为字符0（不是数字0）
    dec edi           ;edi在上面的inc操作中指向了下一个字符
                      ;若当前字符不为‘0’，要是edi减1恢复指向当前字符
    jmp .put_each_num

.full0
    mov cl, '0'       ;输入的数字为全0时，则只打印0

.put_each_num:
    push ecx          ;此时cl中为可打印的字符
    call put_char
    add esp, 4
    inc edi
    mov cl, [put_int_buffer+edi]
    cmp edi, 8
    jl .put_each_num
    popad
    ret
