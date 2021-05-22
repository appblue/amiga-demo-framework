#!/bin/bash

# make amiga executable
vasmm68k_mot -m68000 -Fhunk -no-opt -nocase -align -phxass -I../includes -o gelly.o gelly.s
vlink -bamigahunk -Bstatic -nostdlib gelly.o -o tunnel
../../tools/doynamite68k/lz.exe -o tunnel.d tunnel
