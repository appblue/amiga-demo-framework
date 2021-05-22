
;	ifnd	track_only
TRACK           =       1

	include parts_map.i

max_pts         = 5000		;morph_points
SCR_WIDTH       = 40
planesize	= SCR_WIDTH*256

size_one_code_block     = 45000		;150kb!
size_one_127            = 2024

	section	demo,code_c

call_part:	macro
	lea	\1,a0
	bsr.w	part
	endm

start:
	; copper effect 
	lea		$dff180,a3
.lll
	move.w	d0,(a3)
	addq	#1,d0
	bra.s   .lll

	lea     mem_addr(pc),a1
	ifnd 	TRACK
	lea     memory(pc),a0
	endif
	move.l  a0,(a1)

	lea	bbegin(pc),a0
	move.l	a0,$80.w
	trap	#0
	move.l	#0,d0
	rts

;	include	../common/rnd.s

;*********************************************************
;*                   INICJALIZACJA                       *
;*********************************************************
bBegin:
	move.l	usp,a0
	lea	.uusp(pc),a5
	move.l	a0,(a5)

	lea	$dff000,a6
	move.w	$1c(a6),.wart1-.uusp(a5)
	move.w	$1e(a6),.wart2-.uusp(a5)
	move.w	$02(a6),.wart3-.uusp(a5)
	or.w	#$c000,.wart1-.uusp(a5)
	or.w	#$8000,.wart2-.uusp(a5)
	or.w	#$8000,.wart3-.uusp(a5)
.l	move.l	$dff004,d0
	and.l	#$1ff00,d0
	cmp.l	#303<<8,d0
	bne.s	.l
	move.w	#$7fff,$9a(a6)
	move.w	#$7fff,$9c(a6)
	move.w	#$7fff,$96(a6)
	move.l	$6c.w,.old-.uusp(a5)
	lea	demo_Copper(pc),a5
	move.l	a5,$80(a6)
;	tst.w	$88(a6)
	lea	.Inter(pc),a5
	move.l	a5,$6c.w
	move.w	#$c020,$9a(a6)
;	move.w	#%1000001111000000,$96(a6)
	move.w	#$83c0,$96(a6)

	lea w_sin_table(pc),a0
	lea	demo_ptrs(pc),a5
	move.l	a0,w_sin(a5)

;	lea	$dff000,a5
;	Move.w	#SyncWord,$7e(a5)	;DSKSYNC
;	Move.w	#AdkCon,$9e(a5)		;ADKCON
;;	Move.w	#$8200,$96(a5)
;	Move.b	#%01001100,$bfde00	;Stop, one-shot mode.

;	jsr	SelDF0MotOn
;	jsr	GoToTrack00
;	jsr	SelDF0MotOff




	movem.l	d0-d7/a0-a6,-(sp)


;	lea	$dff000,a5
;	Move.l	#600,d0			Start block, 0-1803.
;	Move.l	#300,d1			Number of blocks to read.
;	Lea	data2_tl,a0		Destination address.
;	jsr	Loader

;	lea	data1_tl,a1
;	lea	data2_tl,a0
;	jsr	doynaxdepack
;
;	lea	data1_tl,a0
;	jsr	process_hunks
;	lea     .ptrs(pc),a5
;	jsr	(a0)
;	lea	.ptrs(pc),a5
;	clr.l	w_VBI(a5)
;	jsr	mfree_all


	rem
        ; ######################C O M M E N T ##############################
	lea	$dff000,a5
	move.l	#600,d0			start block, 0-1803.
	move.l	#300,d1			number of blocks to read.
	lea	data2_tl,a0		destination address.
	jsr	loader

	lea	data1_tl,a1
	lea	data2_tl,a0
	jsr	doynaxdepack

	lea	data1_tl,a0
	jsr	process_hunks

	lea     demo_ptrs(pc),a5
	jsr	(a0)
	lea	demo_ptrs(pc),a5
	clr.l	w_vbi(a5)
	jsr	mfree_all
        ; ###############################################################
	erem




;	call_part	plane2(pc)
;	bsr.w	testsss
;	call_part	boxs(pc)
;	call_part	tunnel
;	call_part	boxs
;	call_part	tunnel
;	call_part	boxs
;	call_part	tunnel


.rts:
	movem.l	(sp)+,d0-d7/a0-a6

	bsr.w   .waitblitter

	move.w	#$7fff,$9a(a6)
	move.w	#$7fff,$9c(a6)
	move.w	#$7fff,$96(a6)
	move.l	.old,$6c.w
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

.waitblitter:				;wait until blitter is finished
	tst.w (a6)			;for compatibility with a1000
.loop:	btst #6,2(a6)
	bne.s .loop
	rts
 
;*********************************************************
;*                     przerwania                        *
;*********************************************************
.inter:
	movem.l	d0-d7/a0-a6,-(sp)
	move.l	w_vbi+demo_ptrs(pc),d0
	beq.s	.no
	move.l	d0,a0
	jsr	(a0)
.no:
	lea	$dff000,a6
	and.w	#$20,$1e(a6)
	beq.s	.out
	move.w	#$20,$9c(a6)

.out:
	movem.l	(sp)+,d0-d7/a0-a6
	rte

;*********************************************************
;*                    zmienne i stale                    *
;*********************************************************

.name:		dc.b	'graphics.library',0
                even

.wart1:		dc.w	0
.wart2:		dc.w	0
.wart3:		dc.w	0
.old:		dc.l	0
.uusp:		dc.l	0

;*********************************************************
;*                    PROGRAM COPPERA                    *
;*********************************************************
demo_copper:
	dc.w	$8e,$2c81,$90,$2cc1,$92,$38,$94,$d0
	dc.w	$100,%0000001000000000,$102,0,$104,0
;	dc.w	$108,0,$10a,0
	
;.planes:	dc.w	$e0,0,$e2,0,$e4,0,$e6,0
;	dc.w	$e8,0,$ea,0,$ec,0,$ee,0

	dc.w	$0180,$0000
;	dc.w	$0182,$0fff	;001

	dc.w	$ffe1,$fffe
	dc.w	$3401,$fffe
	dc.w	$ffff,$fffe

demo_ptrs:  rsreset

w_vbi:    rs.l    1
        dc.l	0   ;interrupt ptr
w_sin:    rs.l   1
        dc.l     0

w_sin_table:
		;incbin  ../common/sin.1024.bin

;	else
;w_VBI:	rs.l	1
;w_sin:	rs.l	1
;	endif

tmp:	dc.l	0


*****************************************************
*
*	TESTS

; testsss:
; 	bsr.w	ClrScr
; 	bsr.w	Wymiana
; 	bsr.w	ClrScr
; 	move.l	#copper,$dff080


; 	lea	txt1(pc),a0
; 	lea	1,a0
; 	lea	txt2(pc),a1
; 	bsr.w	prepare_morph

; 	bsr.w	do_morph

;	lea	txt2(pc),a0
;	lea	txt1(pc),a1
;	bsr.w	prepare_morph
;
;	bsr.w	do_morph


	rts


; Wymiana:
; 	move.l	DrawAddr(pc),d0
; 	move.l	ShowAddr(pc),DrawAddr
; 	move.l	d0,ShowAddr
; 	move.w	d0,Planes+6
; 	swap	d0
; 	move.w	d0,Planes+2
; 	rts

; ClrScr:	move.l	DrawAddr(pc),a0
; 	add.l	#40*256,a0
; 	moveq	#0,d0
; 	moveq	#0,d1
; 	moveq	#0,d2
; 	moveq	#0,d3
; 	move.l	#40*256/(4*4)-1,d7
; .l:	movem.l	d0-d3,-(a0)
; 	dbf	d7,.l
; 	rts

;drawAddr:	dc.l	Screen
;ShowAddr:	dc.l	Screen+planesize

copper:
	dc.w	$8e,$2c81,$90,$2cc1,$92,$38,$94,$d0
	dc.w	$100,%0001001000000000,$102,0,$104,0
	dc.w	$108,0,$10a,0
	
planes:	dc.w	$e0,0,$e2,0

	dc.w	$0180,$0000
	dc.w	$0182,$0fff	;001

	dc.w	$ffe1,$fffe
	dc.w	$3401,$fffe
	dc.w	$ffff,$fffe

*****************************************************
*
* a0 => part addr (asmone wo hunk file format)
; *	movem.l (a7)+,a0-a1

; part:	jsr	process_hunks
; 	lea     demo_ptrs(pc),a5
; 	move.l	a0,tmp
; 	jsr	(a0)
; ;	bra.s	clean


; clean:
; 	move.l	#demo_Copper,$dff080
; 	clr.l	demo_ptrs+w_VBI
; 	jsr	mfree_all
; 	rts

************************************************************************

************************************************************************

MEM_SIZE = 1000000

	 include memory.s
	 include process_hunks.s
         ; include incl/doynax.S
	 include trackloader.s

        ifnd TRACK
memory: ds.b   MEM_SIZE
        endif

screen:	ds.b	planesize*2

	END
