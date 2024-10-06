<center>
    <h1 align="center">OpenMIPS CPU</h1>
    <h4 align="center">Implement peripheral controller</strong> </h4>
    <p align="center">
        <strong>Last updated:</strong> 07 Oct 2024<br>
    </p> 
</center>

# Results
This part implements peripheral controller using a cross-connection method on a min SOPC. The master device issues an access request to a slave device. The arbiter checks whether the bus and the slave device are idle, and then decides whether to give the master device bus access rights.

The cross-connection mode allows multiple pairs of master devices and slave devices to communicate at the same time, which is different from the shared bus mode that only allows one pair of master and slave devices to communicate at the same time.


The source code of the following IP GPIO, UART, Flash, and SDRAM controllers can be downloaded [here](https://github.com/fabriziotappero/opencores-scraper).

# References
* [自己動手寫CPU](https://www.books.com.tw/products/0010676982)
* [opencores-scraper](https://github.com/fabriziotappero/opencores-scraper)