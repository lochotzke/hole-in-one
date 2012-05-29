# hole-in-one

The program uses a hall effect sensor to calculate when a metal ball needs to be released by a magnet to drop through a hole in a spinning disk.
It was was written for a PIC16F84A with an external clock of 4MHz.

## C Data Types

Type                | Size (bits) | Arithmetic Type
--------------------|:-----------:|-----------------
bit                 | 1           | Unsigned integer
signed char         | 8           | Signed integer
unsigned char       | 8           | Unsigned integer
signed short        | 16          | Signed integer
unsigned short      | 16          | Unsigned integer
signed int          | 16          | Signed integer
unsigned int        | 16          | Unsigned integer
signed short long   | 24          | Signed integer
unsigned short long | 24          | Unsigned integer
signed long         | 32          | Signed integer
unsigned long       | 32          | Unsigned integer

Information taken from "HI-TECH C® for PIC10/12/16 User's Guide" page 54.

## Development Environment

PikLab
http://piklab.sourceforge.net/
https://launchpad.net/~michael-gruz/+archive/elektronik
sudo add-apt-repository ppa:michael-gruz/elektronik
sudo apt-get update &&  sudo apt-get install piklab

GPUtils
http://gputils.sourceforge.net/
sudo apt-get install gputils

HI-TECH C® Compiler for PIC10/12/16 MCUs (PICC Compiler)
http://www.htsoft.com/

GPSim
http://gpsim.sourceforge.net/
sudo apt-get install gpsim

picp (only necessary for PICSTART Plus rev. 0)
http://home.pacbell.net/theposts/picmicro/ (down)
sudo apt-get install picp
Erase: picp -c /dev/ttyUSB0 16f84a -ef
Write: picp -c /dev/ttyUSB0 16f84a -wp *.hex

## Links
* [Using PicStart Plus under Linux](http://www.warpedlogic.co.uk/node/9/)
* [PICP](http://home.pacbell.net/theposts/picmicro/PICPmanual.html) (down)
### Tutorials
* http://www.amqrp.org/elmer160/lessons/index.html
* http://www.winpicprog.co.uk/pic_tutorial.htm
* http://www.gooligum.com.au/tut_baseline.html
* http://www.hobbyprojects.com/microcontroller_tutorials.html
* http://www.mikroe.com/eng/products/view/11/book-pic-microcontrollers/
### Code Examples
* http://pic-projects.net/
* http://www.piclist.com/
* http://www.sprut.de/electronic/pic/
* http://www.gedanken.demon.co.uk/amb-pic-code/
