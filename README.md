# hole-in-one

Das Programm liest die Beschleunigungsdaten in X-Richtung des ADXL202 aus und
gibt sie seriell im HEX-Format aus. Die Beschleunigungswerte in Y-Richtung
werden nicht ausgewertet, da sie beim verwendeten Sensor nicht korrekt sind.

## Project Structure and Code

doc/
Unter doc sind verschiedene nützliche pdfs zu finden (PIC Befehlssatz,
Datenblätter, Application Notes, ...).

src/
Unter src ist das PikLab-Projekt (protractor.piklab) und der eigentliche Code zu
finden. Dabei ist der Code in Header- (.inc) und Source-Dateien (.asm)
organisiert, um unter Anderem Variablennamen mehrfach verwenden zu können. Bis
auf die Startadresse bei 0 und die IRQ-Adresse bei 4 werden alle Adressen durch
den Linker bestimmt.

common.inc
  - defines für das allgemeine Hardware-Setup (Ports, Pins, ...)
  - macros, die den Code verkürzen (clear z.B. setzt n RAM-Adressen auf 0)
  - wird von jeder .asm Datei eingebunden
adxl.inc
  - export der in adxl.asm implementierten Funktionen
math.inc
  - export der in math.asm implementierten Funktionen
uart.inc
  - export der in uart.asm implementierten Funktionen
util.inc
  - export der in util.asm implementierten Funktionen

test.inc
  - export der in test.asm implementierten Funktionen

main.asm
  - isr, verschiedene strings und die Main Loop
adxl.asm
  - isr Teilroutine, Funktion zum Auslesen der Beschleunigung
math.asm
  - einfache mathematische Funktionen
uart.asm
  - Funktionen zum Lesen und Schreiben von Daten über uart
util.asm
  - Konvertierungs- und Delayfunktionen

test.asm
  - nicht essenziell für das Programm
  - verschiedene Funktionen um den Code zu testen

## TODOs and FIXMEs

Die Funktionen, die mit "TODO: test" versehen sind, müssen noch getestet weden.

util.inc und util.asm
util_delay_s und util_delay_us funktioniert noch nicht für eine beliebige Anzahl
von Sekunden bzw. Millisekunden.

udata_shr kann vielleicht für eine Variablen/Buffer verwendet werden um RAM zu
einsparen.

## Development Environment

Der Code sollte mit MPLAB X (http://www.microchip.com/en_US/family/mplabx/index.html)
und auch mit MPLAB 8 unter Windows übersetzen lassen. Auch wenn MPLAB X unter
Linux läuft, ist PikLab angenehmer/einfacher zu benutzen.

### WINDOWS

Als serielle Terminals für Windows eignen sich HyperTerminal und ab Windows
Vista Bray++ (https://sites.google.com/site/terminalbpp/).

### LINUX

Im Folgenden sind verschiedene Werkzeuge zur Entwicklung unter Linux (Ubuntu)
aufgelistet.

PikLab: IDE mit Simulator-Anbindung (GPSim)
http://piklab.sourceforge.net/
https://launchpad.net/~michael-gruz/+archive/elektronik
sudo add-apt-repository ppa:michael-gruz/elektronik
sudo apt-get update &&  sudo apt-get install piklab

GPSim: Pic-Simulator
http://gpsim.sourceforge.net/
sudo apt-get install gpsim

picp: Flash-Tool für PICSTART Plus rev. 0, ab einer späteren Revision kann auch
      direkt PikLab genutzt werden
http://home.pacbell.net/theposts/picmicro/
sudo apt-get install picp
Löschen: picp -c /dev/ttyUSB0 16f84a -ef
Flashen: picp -c /dev/ttyUSB0 16f84a -wp *.hex

PikLoops: Programm zum generieren von Schleifencode, aus PikLab heraus benutzbar
http://pikloops.sourceforge.net/
http://debs.slavino.sk/
echo "deb http://debs.slavino.sk stable main non-free" >> /etc/apt/sources.list
wget -q -O - http://debs.slavino.sk/repo.asc | sudo apt-key add -
sudo apt-get update && sudo apt-get install pikloops

CuteCom: Grafisches serielles Terminal
http://cutecom.sourceforge.net/
sudo apt-get install cutecom

minicom: Terminal für die Konsole
sudo apt-get install minicom
minicom --baudrate 9600 --device /dev/ttyUSB0 --noinit --wrap

cu: Terminal für die Konsole
sudo apt-get install cu
cu --line /dev/ttyUSB0 --speed 9600 --nostop

cat & echo: Zum Senden und Empfangen von Daten über die serielle Schnittstelle
            auch ohne spezielle Programme
stty -F /dev/ttyUSB0 9600
stty -F /dev/ttyUSB0 cs8 9600 ignbrk -brkint -imaxbel -opost -onlcr -isig -icanon -iexten -echo -echoe -echok -echoctl -echoke noflsh -ixon -crtscts
cat /dev/ttyUSB0
tail -f /dev/ttyUSB0
echo -n "A" > /dev/ttyUSB0

## Hinweise und Tips

Damit protractor funktioniert muss der CLOCK 4MHz sein.

Die serielle Kommunikation nutzt 9600/8-N-1 (http://en.wikipedia.org/wiki/8-N-1)
und das little endian Format.

Mit Hilfe der errorlevel Direktive können Warnungen des Assemblers unterdrückt
werden, z.B. "errorlevel -231" . Damit wird die Meldung "No memory has been
reserved by this instruction." unterdrückt.

Bei den Befehlen sublw bzw. addlw muss beachtet werden, dass sie nur für den
Bereich von -127 bis 127 das erwartete Ergebnis liefern. Meistens möchte man zur
Subtraktion anstelle von sublw addlw -N benutzten, da dann W = W - N gerechnet
wird. sublw N führt zu W = N - W.

Bei Funktionsaufrufen (jumps) muss beachtet werden, dass der Stack nur 8 Ebenen
hat.

## Analysis

cloc src/main.asm
       1 text file.
       1 unique file.
       0 files ignored.

http://cloc.sourceforge.net v 1.53  T=0.5 s (2.0 files/s, 406.0 lines/s)
-------------------------------------------------------------------------------
Language                     files          blank        comment           code
-------------------------------------------------------------------------------
Assembly                         1             29             40            134
-------------------------------------------------------------------------------

## Links

[ascii|ASCII-Tabelle]:http://www.ascii-code.com/
[psp|PicStart Plus]:http://www.warpedlogic.co.uk/node/9/
[picp|PICP]:http://home.pacbell.net/theposts/picmicro/PICPmanual.html
### Tutorials
* http://www.amqrp.org/elmer160/lessons/index.html
* http://www.winpicprog.co.uk/pic_tutorial.htm
* http://www.gooligum.com.au/tut_baseline.html
* http://www.hobbyprojects.com/microcontroller_tutorials.html
* http://www.mikroe.com/eng/products/view/11/book-pic-microcontrollers/
### Code Examples
* http://www.piclist.com/
* http://www.sprut.de/electronic/pic/
* http://www.gedanken.demon.co.uk/amb-pic-code/
### Math
http://www.sprut.de/electronic/pic/math/math.htm
http://www.piclist.com/techref/member/RF-AMY-K22a/mathsdefs_h.htm
### Delay
http://www.piclist.com/techref/microchip/delay/xus-mm.htm
