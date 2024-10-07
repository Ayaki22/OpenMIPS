<center>
    <h1 align="center">OpenMIPS CPU</h1>
    <p align="center">
        <strong>Last updated:</strong> 08 Oct 2024<br>
    </p> 
</center>

# About
I referred to this [book](https://www.books.com.tw/products/0010676982) as an exercise in OpenMIPS design. The FPGA I am currently using is [DE10-Lite](https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=234&No=1021#contents). This FPGA does not include a UART module, which means that additional peripheral devices such as [C232HM](https://ftdichip.com/products/c232hm-ddhsl-0-2/) need to be connected to the GPIO to implement this function (I am not sure if my idea is correct).

I stopped updating this repository and will continue updating it in the future when I can complete the content of the to-do list.
# To-do 
- [x] ~~Complete the waveform simulation chapter~~
- [ ] [Try assign GPIO](https://community.intel.com/t5/Intel-Quartus-Prime-Software/UART/m-p/1427188/highlight/true)
- [ ] Try to modify the CPU design to expand the switch input
- [ ] Complete the FPGA chapter

# References
* [自己動手寫CPU](https://www.books.com.tw/products/0010676982)
* [DE2-115 開發紀錄: 硬體認識](https://coldnew.github.io/7a67f04e/)
* [UART ref](https://github.com/hildebrandmw/de10lite-hdl/tree/master/components/uart)
* [其他參考](https://github.com/hildebrandmw/de10lite-hdl/blob/master/README.md)