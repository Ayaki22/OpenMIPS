    .org 0x0
    .global _start
    .set noat
    .set noreorder
    .set nomacro

_start:
    ori  $1, $0, 0xf
    mtc0 $1, $11, 0x0
    lui  $1, 0x1000
    ori  $1, $1, 0x401
    mtc0 $1, $12, 0x0
    mfc0 $2, $12, 0x0

_loop:
    j _loop
    nop