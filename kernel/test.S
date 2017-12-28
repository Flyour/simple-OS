%line 1+1 kernel.S
[bits 32]





[extern put_str]

[section .data]
intr_str db "interrupt occur", 0xa, 0"

[global intr_entry_table]
intr_entry_table:

%line 37+1 kernel.S

[section .text]
%line 38+0 kernel.S
intr0x00entry:


 push 0
 push intr_str
 call put_str
 add esp, 4


 mov al, 0x20
 out 0xa0, al
 out 0x20, al

 add esp, 4
 iret

[section .data]
 dd intr0x00entry

%line 39+1 kernel.S
[section .text]
%line 39+0 kernel.S
intr0x01entry:


 push 0
 push intr_str
 call put_str
 add esp, 4


 mov al, 0x20
 out 0xa0, al
 out 0x20, al

 add esp, 4
 iret

[section .data]
 dd intr0x01entry

%line 40+1 kernel.S
[section .text]
%line 40+0 kernel.S
intr0X02entry:


 push 0
 push intr_str
 call put_str
 add esp, 4


 mov al, 0x20
 out 0xa0, al
 out 0x20, al

 add esp, 4
 iret

[section .data]
 dd intr0X02entry

%line 41+1 kernel.S

