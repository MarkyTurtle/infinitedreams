;------------------------------------------------------------------------------
;
;	$VER: CIA Shell OS v1.0 - by Håvard "Howard" Pedersen
;	© 1995-96 Mental Diseases
;
;	An OS-aware CIA-shell
;
;	I cannot be held responsible for any damage caused directly or in-
;	directly by this code. Still, every released version is thouroughly
;	tested with Mungwall and Enforcer, official Commodore debugging tools.
;	These programs traps writes to unallocated ram and reads/writes to/from
;	non-ram memory areas, which should cover most bugs.
;
;	HISTORY:
;
;v1.0	Initial release. Should work OK.
;
;------------------------------------------------------------------------------
;
;	PUBLIC FUNCTIONS:
;
;Function:	CIA_AddCIAInt()
;Purpose:	Attaches our interrupt to the CIA chip, trying both timers.
;		Returns 0 in D0 if something went wrong.
;
;Function:	CIA_RemCIAInt()
;Purpose:	Removes our CIA-interrupt.
;
;Function:	CIA_SetBPM(BPM)(D0.B)
;Purpose:	Adjusts the tempo of the current module.
;
;
;	EXTERNAL FUNCTIONS:
;
;Function:	CIA_CIAInt()
;Purpose:	Does any thingies that are necessary to perform within a CIA
;		interrupt. May trash only D0/D1/A0/A1.
;
;------------------------------------------------------------------------------

; Constants. Feel free to change if you know what you're doing.

; CIA interrupt definitions.

ciatalo = $400
ciatahi = $500
ciatblo = $600
ciatbhi = $700
ciacra  = $E00
ciacrb  = $F00

;------------------------------------------------------------------------------
;			C I A _ A D D C I A I N T
;------------------------------------------------------------------------------
CIA_AddCIAInt	moveq.l	#2,d6
		lea.l	$bfd000,a5
		move.b	#'b',CIA_CIAName+3
.SetCIALoop
		moveq.l	#0,d0
		lea.l	CIA_CIAName(pc),a1
		move.l	4.w,a6
		jsr	-498(a6)		; _LVOOpenResource

		move.l	d0,CIA_CIABase
		beq.w	.FatalError

		lea.l	CIA_GfxName(pc),a1
		moveq.l	#0,d0
		jsr	-552(a6)		; _LVOOpenLibrary()

		tst.l	d0
		beq.s	CIA_RemCIAInt

		move.l	d0,a1
		move.w	206(a1),d0		; Displayflags
		btst	#2,d0			; PAL?
		beq.s	.WasNTSC

		move.l	#1773447,d7 		; PAL
		bra.s	.GotTimer

.WasNTSC	move.l	#1789773,d7 		; NTSC
.GotTimer	move.l	d7,CIA_TimerValue
		divu	#125,d7 		; Default to normal 50 hz timer
		jsr	-414(a6)		; _LVOCloseLibrary()

		move.l	CIA_CIABase(pc),a6
		cmp.w	#2,d6
		beq.s	.TimerA

.TimerB		lea.l	CIA_MusIntServer(pc),a1
		moveq.l	#1,d0			; Bit 1: timer b
		jsr	-6(a6)			; _LVOAddICRVector()

		move.l	#1,CIA_TimerFlag
		tst.l	d0
		bne.s	.CIAError

		move.l	a5,CIA_CIAPtr
		move.b	d7,ciatblo(a5)
		lsr.w	#8,d7
		move.b	d7,ciatbhi(a5)
		bset	#0,ciacrb(a5)
		moveq.l	#1,d0
		rts

.TimerA		lea.l	CIA_MusIntServer(pc),a1
		moveq.l	#0,d0			; Bit 0: timer a
		jsr	-6(a6)			; _LVOAddICRVector()

		clr.l	CIA_TimerFlag
		tst.l	d0
		bne.s	.CIAError

		move.l	a5,CIA_CIAPtr
		move.b	d7,ciatalo(a5)
		lsr.w	#8,d7
		move.b	d7,ciatahi(a5)
		bset	#0,ciacra(a5)
		moveq.l	#1,d0
		rts

.CIAError	move.b	#'a',CIA_CIAName+3
		lea.l	$bfe001,a5
		subq.w	#1,d6
		bne.s	.SetCIALoop

		clr.l	CIA_CIABase
.FatalError	move.l	#0,d0
		rts

;------------------------------------------------------------------------------
;			C I A _ R E M C I A I N T
;------------------------------------------------------------------------------
CIA_RemCIAInt	move.l	CIA_CIABase(pc),d0
		beq.s	.Exit

		clr.l	CIA_CIABase
		move.l	d0,a6
		move.l	CIA_CIAPtr(pc),a5
		tst.l	CIA_TimerFlag
		beq.s	.TimerA

		bclr	#0,ciacrb(a5)
		moveq.l	#1,d0
		bra.s	.RemInt

.TimerA		bclr	#0,ciacra(a5)
		moveq.l	#0,d0
.RemInt		lea.l	CIA_MusIntServer(pc),a1
		moveq.l	#0,d0
		jsr	-12(a6)			; _LVORemICRVector()

.Exit		rts

;------------------------------------------------------------------------------
;			C I A _ S E T B P M
;------------------------------------------------------------------------------
CIA_SetBPM	move.l	CIA_CIABase(pc),d1
		beq.s	.Exit

		move.l	CIA_TimerValue(pc),d1
		divu	d0,d1
		move.l	CIA_CIAPtr(pc),a1
		move.l	CIA_TimerFlag(pc),d0
		beq.s	.TimerA

.TimerB		move.b	d1,ciatblo(a1)
		lsr.w	#8,d1
		move.b	d1,ciatbhi(a1)
		rts

.TimerA		move.b	d1,ciatalo(a1)
		lsr.w	#8,d1
		move.b	d1,ciatahi(a1)

.Exit		rts

;------------------------------------------------------------------------------
;			D A T A
;------------------------------------------------------------------------------

CIA_MusIntServer
		dc.l	0,0
		dc.b	2,5			; Type, Priority
		dc.l	.IntName
		dc.l	0,CIA_CIAInt

.IntName	dc.b	"CIA Music interrupt",0
CIA_CIAName	dc.b	"ciaa.resource",0
CIA_GfxName	dc.b	"graphics.library",0
	even
CIA_CIAPtr	dc.l	0
CIA_CIABase	dc.l	0
CIA_TimerFlag	dc.l	0
CIA_TimerValue	dc.l	0

