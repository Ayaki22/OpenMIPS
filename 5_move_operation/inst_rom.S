    .org 0x0
    .global _start
    .set noat

_start:
    lui $1, 0x0000
    lui $2, 0xffff
    lui $3, 0x0505
    lui $4, 0x0000

    movz $4, $2, $1
    movn $4, $3, $1
    movn $4, $3, $2
    movz $4, $2, $3

    mthi $0
    mthi $2
    mthi $3
    
    mfhi $4

    mtlo $3
    mtlo $2
    mtlo $1

    mflo $4