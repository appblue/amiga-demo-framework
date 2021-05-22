**********************************************************
*		MEMORY ALLOCATIONS
*
* d0 <= mem size (in longwords), upper two bits => memory type
*       00 => whatever, 10 => fast or fail, 01 => chip or fail
* d1 => mem addr
malloc:
	movem.l a0-a1,-(a7)
	lea		mem_free(pc),a0
	lea		mem_addr(pc),a1
	and.l	#$3fffffff,d0	;ignore mem_type as for now
	cmp.l	(a0),d0
	bgt.s	.error
	sub.l	d0,(a0)
	add.l	d0,d0
	add.l	d0,d0
	move.l	(a1),d1
	add.l	d0,(a1)
	movem.l (a7)+,a0-a1
	rts

.error:	
	moveq	#0,d1
	movem.l (a7)+,a0-a1
	rts

;mfree_all:
;	move.l	#MEM_SIZE/4,mem_free
;	move.l	#mem_pool,mem_addr
;	rts

;* MEM_SIZE in bytes
;MEM_SIZE = 1000000

	ifne	MEM_SIZE-(MEM_SIZE/4)*4
	MEM_SIZE needs to be dividable by 4
	endif

mem_addr:	dc.l	0 ;mem_pool
mem_free:	dc.l	MEM_SIZE/4	;in longs

;	section	mem,bss_c
;mem_pool:
;	ds.b	MEM_SIZE
