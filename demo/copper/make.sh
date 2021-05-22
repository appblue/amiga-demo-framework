#!/bin/bash

# make binary blob with assembled code
# vasmm68k_mot -m68000 -Fbin -o copper -I../includes copper.asm

# make amiga executable
vasmm68k_mot -m68000 -Fhunk -linedebug -no-opt -align -phxass -o copper.o copper.asm
vlink -bamigahunk -Bstatic -nostdlib copper.o -o copper
