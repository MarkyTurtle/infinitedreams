;------------------------------------------------------------------------------
;
;	$VER: AudioAlloc v1.0 - by Håvard "Howard" Pedersen
;	© 1995-96 Mental Diseases
;
;	A simple program for handling allocation of audio channels from the OS.
;
;	I cannot be held responsible for any damage caused directly or in-
;	directly by this code. Still, every released version is thouroughly
;	tested with Mungwall and Enforcer, official Commodore debugging tools.
;	These programs traps writes to unallocated ram and reads/writes to/from
;	non-ram memory areas, which should cover most bugs.
;
;	HISTORY:
;
;v1.0	Based on a source by Teijo Kinnunen. Should work fine.
;
;------------------------------------------------------------------------------
;
;	FUNCTIONS:
;
;Function:	AA_Alloc()
;Purpose:	Allocates four audiochannels. Returns 0 in D0 upon failure.
;
;Function:	AA_Free()
;Purpose:	Frees allocated audio channels.
;
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			A L L O C
;------------------------------------------------------------------------------
AA_Alloc	lea.l	AA_DB(pc),a4
		move.l	4.w,a6		
		moveq.l	#-1,d0			; Any bit will do fine
		jsr	-$14a(a6)		; _LVOAllocSignal()

		tst.b	d0
		bmi.w	.Error			; -1 => failure

		move.b	d0,AA_SigBitNum-AA_DB(a4)
		lea.l	AA_AllocPort-AA_DB(a4),a1; Get port address
		move.b	d0,15(a1)		; Set mp_SigBit
		move.l	a1,-(sp)
		sub.l	a1,a1
		jsr	-$126(a6)		; _LVOFindTask

		move.l	(sp)+,a1
		move.l	d0,16(a1)		; Set mp_SigTask
		lea.l	AA_ReqList-AA_DB(a4),a0
		move.l	a0,8(a0)
		addq.l	#4,a0
		clr.l	(a0)
		move.l	a0,-(a0)
		lea.l	AA_AllocReq-AA_DB(a4),a1
		lea.l	AA_AudioName-AA_DB(a4),a0
		moveq.l	#0,d0
		moveq.l	#0,d1
		jsr	-$1bc(a6)		; _LVOOpenDevice()

		tst.b	d0
		beq.s	.NoError

		bsr.s	AA_Free
		bra.s	.Error

.NoError	st	AA_AudioOpen-AA_DB(a4)
		moveq	#1,d0
		bra.s	.Exit

.Error		moveq	#0,d0
.Exit		rts

;------------------------------------------------------------------------------
;			F R E E
;------------------------------------------------------------------------------
AA_Free		lea.l	AA_DB,a5		; Again, the DataBase pointer
		move.l	4.w,a6
		tst.b	AA_AudioOpen-AA_DB(a5)
		beq.s	.NoDevAlloc

		lea.l	AA_AllocReq-AA_DB(a5),a1
		jsr	-$1c2(a6)		; _LVOCloseDevice()

		clr.b	AA_AudioOpen-AA_DB(a5)
.NoDevAlloc	moveq	#0,d0
		move.b	AA_SigBitNum-AA_DB(a5),d0
		bmi.s	.NoSigBit

		jsr	-$150(a6)		; _LVOFreeSignal()

		st	AA_SigBitNum-AA_DB(a5)	; clear (= set) AA_SigBitNum
.NoSigBit	rts

;------------------------------------------------------------------------------
;			D A T A
;------------------------------------------------------------------------------

AA_DB		;data base pointer
AA_SigBitNum	dc.b	$ff
AA_AudioOpen	dc.b	0
AA_AllocMask	dc.b	$0f
AA_AudioName	dc.b	'audio.device',0
	even

AA_AllocPort	dc.l	0,0			; succ, pred
		dc.b	4,0			; NT_MSGPORT
		dc.l	0			; name
		dc.b	0,0			; flags = PA_SIGNAL
		dc.l	0			; task
AA_ReqList	dc.l	0,0,0			; list head, tail and tailpred
		dc.b	5,0
AA_AllocReq	dc.l	0,0
		dc.b	5,127			; type, pri
		dc.l	0,AA_AllocPort		; name, replyport
		dc.w	68			; length
		dc.l	0			; io_Device
		dc.l	0			; io_Unit
		dc.w	0			; io_Command
		dc.b	0,0			; io_Flags, io_Error
		dc.w	0			; ioa_AllocKey
		dc.l	AA_AllocMask		; ioa_Data
		dc.l	1			; ioa_Length
		dc.w	0,0,0			; ioa_Period, Volume, Cycles
		dc.w	0,0,0,0,0,0,0,0,0,0	; ioa_WriteMsg

