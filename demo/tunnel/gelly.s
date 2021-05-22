;*********************************************************
;*        STANDART BY DR.DF0  OF  ... ATD ...            *
;*             4 BITPLANY  I  SPRITE'Y                   *
;*********************************************************

Planesize=512*(2*64)

NCirc	= 70		;50
PPC	= 64
SIZE_1	= 4*PPC+2+2
STEPS	= 4

MAX_FRAMES = 1300

xadd	=	2*3
yadd	=	2*2


Wblit:	macro
	btst	#6,2(a6)
	bne.s	*-6
	endm


	section main, code_c

track_only = 1
sss:

	include	wrapper.s


Main:	move.l	a5,wptr
	bsr.w	init
	bsr.w	myRoutine
	rts

;dff180_col = $000
;	include	/common/cop_print.s

wptr:	dc.l	0


;*********************************************************
;*                        INIT                           *
;*********************************************************
NAPIS:	dc.b	"RE! TUNNEL",0
	even

;cop_data:
;	blk.b	end_cop_txt,0

init:

;	lea	cop_data(pc),a5
;	move.l	#Napis,cop_txt(a5)
;	move.l	#Cop_revo,cop_list(a5)
;	move.w	#$679,cop_col(a5)
;	move.w	#$2031,cop_xy(a5)
;	jsr	cop_print

	jsr	wymiana
	stop	#$2000
	move.l	#copper,$dff080
	move.l	wptr(pc),a0
	move.l	#Inter,w_vbi(a0)

	bsr.w	init_tab_xy
	bsr.w	init_code
	rts

init_tab_xy:
	lea	tabxy,a0
	move.l	a0,tabxy_ptr
	move.l	a0,tabx1y1_ptr
	move.w	#(NCirc+1)*STEPS+MAX_FRAMES-1,d7

	move.l	wptr(pc),a1
	move.l	w_sin(a1),a1	;lea	Sin(PC),a1
	moveq	#0,d5
	moveq	#0,d6

.ll:
	and.w	#2046,d5
	and.w	#2046,d6
	move.w	(a1,d5.w),d0
	move.w	(a1,d6.w),d1
	asr.w	#8,d0
	asr.w	#8,d1
;	asr.w	#2,d0
;	asr.w	#2,d1
	move.w	d0,(a0)+
	move.w	d1,(a0)+
	add.w	#xadd,d5
	add.w	#yadd,d6
	dbf	d7,.ll

	rts

init_code:
	lea	rs(pc),a1
	lea	c0(pc),a2
	move.l	wptr(pc),a3

.loop:
	move.l	w_sin(a3),a0
	move.l	a1,d0
	move.w	(a1)+,d6	;r
	sub.l	#rs,d0
	lsr.w	#1,d0
	and.w	#3,d0
	lsl.w	#3,d0
	add.w	d0,a0

	move.w	#PPC-1,d7
	moveq	#0,d5
.l:
	move.w	(a0),d0		;sin
	move.w	256*2(a0),d1	;cos
	add.w	#2048/64,a0	;next angle
	muls	d6,d0
	muls	d6,d1		;y=r*128*sin*32768
	swap	d0
	swap	d1
	asr.w	#6,d0
	addx.w	d5,d0
	asr.w	#6,d1
	addx.w	d5,d1

	move.w	d0,d2
	and.w	#7,d2
	move.w	d2,d3
	lsl.w	#8,d3
	add.w	d3,d3
	add.w	d3,d2
	add.w	#$1e8,d2
	move.w	d2,(a2)+
	asr.w	#3,d0
	lsl.w	#7,d1	;*64*2 -->y
	add.w	d0,d1
	move.w	d1,(a2)+

	dbf	d7,.l
	move.l	#$4e684ed0,(a2)+
	cmp.l	#end_rs,a1
	bne.s	.loop

	rts


;*********************************************************
;*                     INTERRUPTS                        *
;*********************************************************
Inter:
;	move.w	#$404,$dff180

	rts

;*********************************************************
;*                      PETLA GLOWNA                     *
;*********************************************************
fr:	dc.w	0


MyRoutine:

.wait:
	lea	$dff000,a6
	stop	#$2000
	jsr	ClsBlit



	moveq	#0,d0
	move.l	Vis_Ptr(pc),a0
	move.b	(a0),d0
	bpl.s	.abc
	move.w	#NCirc,d0
.abc:	subq.w	#1,d0
	move.w	d0,doMyD7+2

	jsr	doMyRoutine

	jsr	Wymiana

;	move.w	#$234,$dff180


	add.w	#1,fr
	cmp.w	#MAX_FRAMES-1,fr
	beq.s	.end

.x:
	btst	#6,$bfe001
;	bne.w	.x
	bne.w	.wait
.end:

	rts

	stop	#$2000
;	lea	cop_data(pc),a5
;	move.l	#.nap,cop_txt(a5)
;	move.l	#Cop_revo,cop_list(a5)
;	move.w	#$99a,cop_col(a5)
;	move.w	#$4831,cop_xy(a5)
;	jsr	cop_print
	move.w	d0,$dff180
	addq.w	#1,d0
	btst	#6,$bfe001
	bne.w	.end

	rts

.nap:	dc.b	"ENDOLUTION!"
	even

;*********************************************************
;*                    MAIN ROUTINES                      *
;*********************************************************
doMyRoutine:
	move.w	#-1,Circs_count
doMyD7:
	move.w	#NCirc-1,d7
	bmi.w	gogo		;.noAnim

	moveq	#-1,d0
	move.l	DrawAdr(pc),a0
	add.l	#40*4,a0
	rept	10
	move.l	d0,(a0)+
	endr
	move.l	DrawAdr(pc),a0
	add.l	#(512/8-40)/2+20+256*2*64,a0
	move.l	a0,ScrAdr+2

	lea	c0(pc),a5
	add.w	addrs_offset(pc),a5

	move.l	tabx1y1_ptr,a3
	move.w	(a3)+,dx
	move.w	(a3)+,dy
	move.l	tabxy_ptr,a3
	lea	Circs_to_draw,a4

llla:
	move.w	(a3)+,d0
	move.w	(a3),d1
	add.w	#STEPS*4-2,a3
	sub.w	dx(pc),d0
	sub.w	dy(pc),d1
	asr.w	#2,d0
	asr.w	#2,d1

ScrAdr:	move.l	#0,a0
	move.w	d0,d2
	asr.w	#3,d0
	lsl.w	#7,d1			;muls	#2*64,d1
	add.w	d0,d1
	add.w	d1,a0

	and.w	#7,d2
	add.w	d2,d2
	add.w	d2,d2
	lea	do_tab3(pc),a6
	move.l	(a6,d2.w),a6		;one of do0..do7 selected


	move.w	d7,d0
	sub.w	doMyD7+2(pc),d0
	and.w	#7,d0
cmp:	cmp.w	#0,d0
	bne.s	.s1
	add.w	#64,a0		;red rings
.s1:

	move.l	a0,(a4)+
	move.l	a6,(a4)+
	move.l	a5,(a4)+	;pointer to code to draw one circ
	add.w	#1,Circs_count
	add.l	#size_1*STEPS,a5

	dbf	d7,llla

	add.l	#4,tabx1y1_ptr

	lea	addrs_offset(pc),a0
	move.w	(a0),d0
	add.w	#-1*SIZE_1,d0
	bpl.s	.rrr

	move.w	cmp+2(pc),d1
	add.w	#1,d1
	and.w	#7,d1
	move.w	d1,cmp+2

	move.w	#size_1*(steps-1),d0
	move.w	d0,(a0)
	add.l	#4*steps,tabxy_ptr
	move.l	tabxy_ptr,a0
	sub.w	#steps*4,a0
	move.l	a0,tabx1y1_ptr
	bra.s	gogo

.rrr:
	move.w	d0,(a0)

gogo:
;	rts

.www:	cmp.b	#$18,$dff006
	ble.s	.www


;	move.w	#$121,$dff180

	lea	Circs_to_draw,a4
	move.l	vis_ptr(pc),a1
	moveq	#0,d0
	move.b	(a1)+,d0		;discard
	bpl.s	.noAction
	ext.w	d0
	add.w	d0,Circs_count
	neg.w	d0
	mulu	#12,d0
	add.l	d0,a4
.noAction:

	moveq	#0,d6
	move.b	(a1)+,d6	;num_full!!!

	move.w	Circs_count(pc),d7
	bmi.w	.finito

	sub.w	d6,d7
	sub.b	(a1)+,d7
	ext.w	d7
	subq.w	#1,d6

	move.w	d7,-(a7)
	move.l	a1,-(a7)

	bsr.w	full_circs_d6

	move.l	(a7)+,a1
	move.w	(a7)+,d7
	bmi.s	.finito

.ldr:
	moveq	#0,d6
	move.b	(a1)+,d6
	lsr.w	#6,d6
	subq.w	#1,d6
	bmi.s	.aaaa
	subq.l	#1,a1

.lax:
	moveq	#0,d0
	moveq	#0,d1
	move.b	(a1)+,d0
	and.w	#63,d0
	move.b	(a1)+,d1
	cmp.w	d0,d1
	bpl.s	.ssx		;normal operations ;-)
				;d0=30, d1=20 ==> (0,20),(30,64)
	addq.w	#1,d6		;==> one more
	move.b	#64,-(a1)
	move.b	d0,-(a1)
	moveq	#0,d0

.ssx:
	lsl.w	#2,d0
	lsl.w	#2,d1

	move.l	(a4),a0		;final dest
	move.l	4(a4),a3
	move.l	8(a4),a5

	add.w	d1,a5
	move.l	(a5),-(a7)
	move.l	a5,-(a7)
	move.l	#$4e684ed0,(a5)	;move.l	usp,a0  jmp (a0)
	move.l	8(a4),a5

	add.w	d0,a5

	move.l	a1,-(a7)
	move.l	a4,-(a7)
	move.w	d7,-(a7)
	move.w	d6,-(a7)
	move.l	a7,.save_a7+2
	move.l	#.ret_a,a1
	move.l	a1,usp
	move.l	a0,a1
	jmp	(a3)
.ret_a:

.save_a7:
	move.l	#0,a7

	move.w	(a7)+,d6
	move.w	(a7)+,d7
	move.l	(a7)+,a4
	move.l	(a7)+,a1

	move.l	(a7)+,a5
	move.l	(a7)+,(a5)

	dbf	d6,.lax
.aaaa:
	add.w	#12,a4


	dbf	d7,.ldr
.finito:
	move.l	a1,vis_ptr

	rts

full_circs_d6:
.lax:
	move.l	(a4)+,a0		;final dest
	move.l	(a4)+,a3
	move.l	(a4)+,a5

	move.l	a4,-(a7)
	move.w	d6,-(a7)
	move.l	a7,.save_a7+2
	move.l	#.ret_a,a1
	move.l	a1,usp
	move.l	a0,a1
	jmp	(a3)
.ret_a:

.save_a7:
	move.l	#0,a7

	move.w	(a7)+,d6
	move.l	(a7)+,a4

	dbf	d6,.lax

	rts

vis_ptr:
	dc.l	vis

dx:	dc.w	0
dy:	dc.w	0


addrs_offset:
	dc.w	size_1*(steps-1)

setupdx:macro
	moveq	#7,d\1
	moveq	#6,d\2
	moveq	#5,d\3
	moveq	#4,d\4
	moveq	#3,d\5
	moveq	#2,d\6
	moveq	#1,d\7
	moveq	#0,d\8
	endm

do_tab3:dc.l	do0,do1,do2,do3,do4,do5,do6,do7

do0:
	move.l	a5,.jmp_a+2-do0(a3)		;moved to only_one/only_two
	nop
	setupdx	0,1,2,3,4,5,6,7
	move.l	a1,a2
	move.l	a2,a3
	move.l	a3,a4
	move.l	a4,a5
	move.l	a5,a6
	move.l	a6,a7
.jmp_a:	jmp	1234
do1:
	move.l	a5,.jmp_a+2-do1(a3)
	setupdx	7,0,1,2,3,4,5,6
	move.l	a1,a2
	move.l	a2,a3
	move.l	a3,a4
	move.l	a4,a5
	move.l	a5,a6
	move.l	a6,a7
	addq.l	#1,a7
.jmp_a:	jmp	1234
do2:
	move.l	a5,.jmp_a+2-do2(a3)
	setupdx	6,7,0,1,2,3,4,5
	move.l	a1,a2
	move.l	a2,a3
	move.l	a3,a4
	move.l	a4,a5
	move.l	a5,a6
	addq.l	#1,a6
	move.l	a6,a7
.jmp_a:	jmp	1234
do3:
	move.l	a5,.jmp_a+2-do3(a3)
	setupdx	5,6,7,0,1,2,3,4
	move.l	a1,a2
	move.l	a2,a3
	move.l	a3,a4
	move.l	a4,a5
	addq.l	#1,a5
	move.l	a5,a6
	move.l	a6,a7
.jmp_a:	jmp	1234
do4:
	move.l	a5,.jmp_a+2-do4(a3)
	setupdx	4,5,6,7,0,1,2,3
	move.l	a1,a2
	move.l	a2,a3
	move.l	a3,a4
	addq.l	#1,a4
	move.l	a4,a5
	move.l	a5,a6
	move.l	a6,a7
.jmp_a:	jmp	1234
do5:
	move.l	a5,.jmp_a+2-do5(a3)
	setupdx	3,4,5,6,7,0,1,2
	move.l	a1,a2
	move.l	a2,a3
	addq.l	#1,a3
	move.l	a3,a4
	move.l	a4,a5
	move.l	a5,a6
	move.l	a6,a7
.jmp_a:	jmp	1234
do6:
	move.l	a5,.jmp_a+2-do6(a3)
	setupdx	2,3,4,5,6,7,0,1
	move.l	a1,a2
	addq.l	#1,a2
	move.l	a2,a3
	move.l	a3,a4
	move.l	a4,a5
	move.l	a5,a6
	move.l	a6,a7
.jmp_a:	jmp	1234
do7:
	move.l	a5,.jmp_a+2-do7(a3)
	setupdx	1,2,3,4,5,6,7,0
	addq.l	#1,a1
	move.l	a1,a2
	move.l	a2,a3
	move.l	a3,a4
	move.l	a4,a5
	move.l	a5,a6
	move.l	a6,a7
.jmp_a:	jmp	1234


;*********************************************************
;*                    WYMIANA EKRANOW                    *
;*********************************************************
ClsBlit:
	move.l	ClsAdr(pc),d0
	add.l	#(512/8-40)/2+128*2*64,d0
	lea	$dff000,a6
	wblit

	move.l	d0,$054(a6)
	move.l	#-1,$044(a6)
	move.l	#$01000000,$040(a6)
	move.w	#512/8-40,$066(a6)
	move.w	#2*256*64+20,$058(a6) 		;clear all 4 bitplanes

	rts
	
Wymiana:
	lea	PlaneAdre(pc),a1
	move.l	(a1)+,d1
	move.l	(a1)+,d2
	move.l	(a1)+,d3
	move.l	d2,-(a1)
	move.l	d1,-(a1)
	move.l	d3,-(a1)

	lea	Planes+2,a0
	add.l	#(512/8-40)/2+128*2*64,d3
	rept	2
	move.w	d3,4(a0)
	swap	d3
	move.w	d3,(a0)
	swap	d3
	add.l	#64,d3
	add.l	#8,a0
	endr
	rts

Copper:
	dc.w	$8e,$2c81,$90,$2cc1,$92,$38,$94,$d0
	dc.w	$100,%0010001000000000,$102,0,$104,0
	dc.w	$108,512/8-40+64,$10a,512/8-40+64
	

Planes:	dc.w	$e0,0,$e2,0,$e4,0,$e6,0

	dc.w	$0180,$0000
	dc.w	$0182,$0fff	;001
	dc.w	$0184,$0f00	;010	;RING
	dc.w	$0186,$0fff	;011


cop_revo:
;	blk.b	cop_print_size,0
;	cop_print_cop
cop_revo2:

	dc.w	$ffe1,$fffe
	dc.w	$3401,$fffe
	dc.w	$ffff,$fffe


;*********************************************************
;*                    ZMIENNE I STALE                    *
;*********************************************************
PlaneAdre:	dc.l	Screen1
ClsAdr:		dc.l	Screen1+PlaneSize
DrawAdr:	dc.l	Screen1+2*PlaneSize
Circs_count:	dc.w	0
tabX1Y1_ptr:	dc.l	tabXY
tabXY_ptr:	dc.l	tabXY

rs:		incbin	r.bin
end_rs:

C0:	blk.b	((end_rs-rs)/2)*SIZE_1	;we will generate code here
;	incbin	"circ.bin"		;used to use python generated code

vis:		incbin	vis2.bin
		even


	section buffs, bss_c
;*********************************************************
;*                        EKRAN                          *
;*********************************************************
Circs_to_draw:	ds.l	2*3*(NCirc+1)
tabXY:		ds.l	(NCirc+1)*STEPS+(MAX_FRAMES) ;.l = X,Y kolejnych kolek
Screen1:	ds.b	3*Planesize

