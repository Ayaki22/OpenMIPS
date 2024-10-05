<center>
    <h1 align="center">OpenMIPS CPU</h1>
    <h4 align="center">Implement coprocessor</strong> </h4>
    <p align="center">
        <strong>Last updated:</strong> 02 Oct 2024<br>
    </p> 
</center>

# Results
This part implements 2 CP0 operation instructions.

### Instruction

The following instructions are to be implemented
* mtc0、mfc0
```
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
```

### Waveform
* mtc0、mfc0

![waveform_1](img/waveform_1.jpg)
![waveform_2](img/waveform_2.jpg)
![waveform_3](img/waveform_3.jpg)

# References
* [自己動手寫CPU](https://www.books.com.tw/products/0010676982)