    .org 0x0
    .global _start
    .set noat
    .set noreorder
    .set nomacro

_start:
    #因為低位址有異常處理常式，所以處理器啟動後，就立刻轉移到0x100
    ori $1, $0, 0x100
    jr  $1
nop

    #系統呼叫異常處理常式
    .org 0x40
    ori  $1, $0, 0x8000
    ori  $1, $0, 0x9000
    mfc0 $1, $14, 0x0
    addi $1, $1, 0x4
    mtc0 $1, $14, 0x0
    eret
    nop

    #main function， 呼叫syscall，從而引起系統呼叫異常
    .org 0x100
    ori $1, $0, 0x1000
    sw  $1, 0x0100 ($0)

    mthi $1
    
    syscall

    lw $1, 0x0100 ($0)

    mfhi $2

_loop:
    j _loop
    nop