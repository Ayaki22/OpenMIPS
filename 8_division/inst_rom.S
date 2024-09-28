    .org 0x0
    .global _start
    .set noat

_start:
    ori $2, $0, 0xffff
    sll $2, $2, 16
    ori $2, $2, 0xfff1
    ori $3, $0, 0x11

    div $zero, $2, $3

    divu $zero, $2, $3

    div $zero, $3, $2