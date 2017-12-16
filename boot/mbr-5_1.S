%include "boot.inc"

;我们的mbr程序要放在0x7c00的内存处，这里告诉编译器把起始地址编译为0x7c00
SECTION MBR vstart=0x7c00

    ; 把各个段寄存器调整到现在的位置
    mov ax,cs ;此时cs为0,因为bios通过jmp 0:0x7c00跳转到MBR
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov fs,ax

    mov sp,0x7c00 ; 初始化栈指针,注意程序向上执行，栈向下扩展

    mov ax,0xb800
    mov gs,ax

    ;选择INT 0X10 0x06号功能，作用是上卷窗口达到清屏的作用
    ;AH  功能号=0x06
    ;AL  上卷的行数（如果为0,表示全部）
    mov ax,0x600
    mov bx,0x700
    mov cx,0
    mov dx,0x184f
    int 0x10

    ; 往显存空间放入字符
    mov byte [gs:0x00],'1'
    mov byte [gs:0x01],0xA4
    mov byte [gs:0x02],' '
    mov byte [gs:0x03],0xA4
    mov byte [gs:0x04],'M'
    mov byte [gs:0x05],0xA4
    mov byte [gs:0x06],'B'
    mov byte [gs:0x07],0xA4
    mov byte [gs:0x08],'R'
    mov byte [gs:0x09],0xA4

    mov eax,LOADER_START_SECTOR ;LOADER_START_SECTOR 0X2,loader在硬盘中起始扇区lba地址
    mov bx,LOADER_BASE_ADDR ; LOADER_BASE_ADDR = 0X900, loader程序在内存中的位置
    mov cx,8 ;表示要从硬盘读取几个扇区的数据作为loader
    call rd_disk_m_16  ;调用程序从硬盘读取数据

    jmp LOADER_BASE_ADDR + 0x300
;------------------------------------
;功能：读取硬盘n个扇区
;------------------------------------
rd_disk_m_16:

    mov esi,eax
    mov di,cx
    mov dx,0x1f2
    mov al,cl
    out dx,al ;写入要读取的扇区数

    mov eax,esi ;恢复ax

    mov dx,0x1f3
    out dx,al ;lba地址7~0位写入端口0x1f3

    mov cl,8
    shr eax,cl
    mov dx,0x1f4
    out dx,al ;lba地址15~8位写入端口0x1f4


    shr eax,cl
    mov dx,0x1f5
    out dx,al ;lba地址23～16位写入端口0x1f5

    shr eax,cl
    and al,0x0f ;lba第24～27位
    or al,0xe0  ;设置7～4位为1110,表示lba模式
    mov dx,0x1f6
    out dx,al

    mov dx,0x1f7
    mov al,0x20
    out dx,al ;向0x1f7端口写入读命令

; 检测硬盘状态
.not_ready:
    nop
    in al,dx ;同一端口，写时表示写入命令字，读时表示读入硬盘状态
    and al,0x88 ;第4位为1表示硬盘控制器已准备好数据传输
    cmp al,0x08
    jnz .not_ready ;若未准备好，继续等

;从0x1f0端口读数据
    mov ax,di
    mov dx,256
    mul dx
    mov cx,ax
    ;di 为要读取的扇区数，一个扇区有512字节，每次读入一个字，
    ;共需要di*512/2次，所以di*256

    mov dx,0x1f0

.go_on_read:
    in ax,dx
    mov [bx],ax
    add bx,2
    loop .go_on_read
    ret

    times 510-($-$$) db 0
    db 0x55,0xaa

