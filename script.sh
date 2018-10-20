#! /bin/bash
bison -dyv sintactico.y
flex lexico.l
gcc lex.yy.c y.tab.c -o compilador.bin
./compilador.bin prueba.txt
rm compilador.bin lex.yy.c y.tab.c y.tab.h y.output