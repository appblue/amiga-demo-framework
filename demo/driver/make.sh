#!/bin/bash

vasmm68k_mot -m68000 -Fbin -pic -nocase -o driver -I../includes driver.asm
