*********************************************************
*		PROCESS HUNKS
*
* a0 <= start addr
* a0 => decoded addr of first chunk (to jump into
*
*
HUNK_HEADER	= $3F3
HUNK_CODE	= $3E9
HUNK_BSS	= $3EB
HUNK_RELOC32	= $3EC
HUNK_END	= $3F2
HUNK_DATA	= $3EA

MAX_HUNKS	= 10

process_hunks:
	cmp.l	#HUNK_HEADER,(a0)+
	bne.w	error
	tst.l	(a0)+
	bne.w	error

	move.l	(a0)+,d7	;num hunks
	tst.l	(a0)+		;first
	bne.w	error
	addq.l	#4,a0		;last
	cmp.l	#MAX_HUNKS,d7
	bgt.w	error
	subq.w	#1,d7

	lea	hunks_ptrs(pc),a1
	move.w	d7,num_hunks-hunks_ptrs(a1)
.l1:	
	move.l	(a0),d0
	and.l	#$3fffffff,d0
	move.l	d0,4(a1)
	move.l	(a0)+,d0
	bsr		malloc
	move.l	d1,(a1)
	addq.l	#8,a1
	dbf	d7,.l1

	move.w	num_hunks(pc),d7
	lea	hunks_ptrs(pc),a1

.l_m:	
	move.l	(a0)+,d0
	cmp.w	#HUNK_END,d0
	beq.s	.el

	cmp.w	#HUNK_DATA,d0
	beq.s	.codedata
	cmp.w	#HUNK_CODE,d0
	bne.s	.c2

.codedata:
	move.l	(a1),a2	;ptr
	move.l	4(a1),d6	;size
	move.l	(a0)+,d6	;memcpy
	bsr.w	memcpy
	bra.s	.l_m


.c2:	cmp.w	#HUNK_RELOC32,d0
	bne.w	.c3

	bsr.w	manage_reloc

	bra.s	.l_m
.c3:	
	cmp.w	#HUNK_BSS,d0
	bne.w	error

	addq.l	#4,a0		;size of bss, already malloc'ed
	bra.s	.l_m
.el:	
	addq.l	#8,a1		;next hunk
	dbf	d7,.l_m
	move.l	hunks_ptrs(pc),a0
	rts

;a0=> ptr to reloc tab
;a1=> ptr to hunks_ptr (addr,size)
;we will apply to this hunk 
manage_reloc:
	move.l	(a1),a2		;addr of this hunk
	lea	hunks_ptrs(pc),a3

.l:	move.l	(a0)+,d0	;numoffs
	beq.s	.fin
	move.l	(a0)+,d1	;hunkptr
	lsl.l	#3,d1		;*8
	move.l	(a3,d1.l),d4	;hunk addr in real mem
	subq.w	#1,d0
.l2:	
	move.l	(a0)+,d2
	add.l	d4,(a2,d2.l)
	dbf	d0,.l2
	bra.s	.l
.fin:	
	rts

memcpy:
	move.l	(a0)+,(a2)+
	subq.l	#1,d6
	bne.s	memcpy
	rts

error:
        move.w  d0,$dff180
        addq.w  #1,d0
        bra.s   error

num_hunks:	dc.w	0
hunks_ptrs:	blk.l	MAX_HUNKS*2	;addr, size (in longs)
