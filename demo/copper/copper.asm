	rsreset

addp:	macro
	add.b	\1,\1
	bcc.s	.n\@
	move.w	d0,(a0)+
	move.w	d1,(a0)+
	addq.w	#1,d5
.n\@:
	addq.w	#1,d0
	endm

_start:
        lea     $dff180,a5
.l01:   move.w  d0,(a5)
        addq    #1,d0
        bra.s   .l01

        rept 8
        addp    d2
        endr


