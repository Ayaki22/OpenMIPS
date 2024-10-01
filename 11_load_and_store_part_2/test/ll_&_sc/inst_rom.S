    .org 0x0
    .global _start
    .set noat
    .set noreorder
    .set nomacro

_start:
    ## without ll run sc ##
    ori $1, $0, 0x1234
    sw  $1, 0x0 ($0)

    ori $1, $0, 0x5678
    sc  $1, 0x0 ($0)

    lw  $1, 0x0 ($0)

    nop

    ## Read-Modify-Write ##
    ori $1, $0, 0x0
    ll  $1, 0x0 ($0)

    nop
    addi $1, $1, 0x1
    sc   $1, 0x0 ($0)

    lw   $1, 0x0 ($0)

_loop:
    j _loop
    nop