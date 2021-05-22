
	ifnd	track_only

Start:
	move.l	#.begin,$80.w
	trap	#0
	move.l	#0,d0
	rts

;*********************************************************
;*                   INICJALIZACJA                       *
;*********************************************************
.Begin:
	move.l	usp,a0
	move.l	a0,.uusp
	lea	$dff000,a6
	move.w	$1c(a6),.wart1
	move.w	$1e(a6),.wart2
	move.w	$02(a6),.wart3
	or.w	#$c000,.wart1
	or.w	#$8000,.wart2
	or.w	#$8000,.wart3
.l	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	bne.s	.l
	move.w	#$7fff,$9a(a6)
	move.w	#$7fff,$9c(a6)
	move.w	#$7fff,$96(a6)
	move.l	#.Copper,$80(a6)
	tst.w	$88(a6)
	move.l	$6c.w,.old
	move.l	#.Inter,$6c.w
	move.w	#$c020,$9a(a6)
;	move.w	#%1000001111000000,$96(a6)
	move.w	#$83c0,$96(a6)

	movem.l	d0-d7/a0-a6,-(sp)
    lea     .ptrs(pc),a5
	Bsr.w	Main
	movem.l	(sp)+,d0-d7/a0-a6

	bsr.w   .WaitBlitter

	move.w	#$7fff,$9a(a6)
	move.w	#$7fff,$9c(a6)
	move.w	#$7fff,$96(a6)
	move.l	.Old,$6c.w
	move.l	4.w,a6
	move.l	#.name,a1
	clr.l	d0
	jsr	-408(a6)
	lea	$dff000,a6
	move.l	d0,a5
	move.l	38(a5),$80(a6)
	tst.w	$88(a6)
	move.w	.wart1,$9a(a6)
	move.w	.wart2,$9c(a6)
	move.w	.wart3,$96(a6)
	move.l	.uusp,a0
	move.l	a0,usp
	rte

.WaitBlitter:				;wait until blitter is finished
	tst.w (a6)			;for compatibility with A1000
.loop:	btst #6,2(a6)
	bne.s .loop
	rts
 
;*********************************************************
;*                     PRZERWANIA                        *
;*********************************************************
.Inter:
	movem.l	d0-d7/a0-a6,-(sp)
	move.l	w_VBI+.ptrs(pc),d0
	beq.s	.no
	move.l	d0,a0
	jsr	(a0)
.no:
	lea	$dff000,a6
	and.w	#$20,$1e(a6)
	beq.s	.out
	move.w	#$20,$9c(a6)

.Out:
	movem.l	(sp)+,d0-d7/a0-a6
	rte

;*********************************************************
;*                    ZMIENNE I STALE                    *
;*********************************************************

.Name:		dc.b	'graphics.library',0
	even
.Wart1:		dc.w	0
.Wart2:		dc.w	0
.Wart3:		dc.w	0
.Old:		dc.l	0
.uusp:		dc.l	0

;*********************************************************
;*                    PROGRAM COPPERA                    *
;*********************************************************
.Copper:
	dc.w	$8e,$2c81,$90,$2cc1,$92,$38,$94,$d0
	dc.w	$100,%0000001000000000,$102,0,$104,0
;	dc.w	$108,0,$10a,0
	
;.Planes:	dc.w	$e0,0,$e2,0,$e4,0,$e6,0
;	dc.w	$e8,0,$ea,0,$ec,0,$ee,0

	dc.w	$0180,$0000
;	dc.w	$0182,$0fff	;001

	dc.w	$ffe1,$fffe
	dc.w	$3401,$fffe
	dc.w	$ffff,$fffe

.ptrs:  rsreset

w_VBI:    rs.l    1
        dc.l	0   ;interrupt ptr
w_sin:    rs.l   1
        dc.l     w_sin_table

w_sin_table:
		incbin  sources:common/sin.1024.bin

	else
w_VBI:	rs.l	1
w_sin:	rs.l	1
	endif
