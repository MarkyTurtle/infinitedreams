
Go		moveq.l	#0,d0
		move.l	#25000/50,d1		; 50Hz
		moveq.l	#1,d2
		lea.l	Module,a0
		lea.l	Timer,a1
		jsr	PTCalcTime

		moveq.l	#0,d0
		rts

Timer		dc.l	0,0,0,0			; Hours, Minutes,
						; Seconds, 1/100s

	INCDIR	"m:Bjørn A Lynne/"
Module	INCBIN	"mod.doin' the sushi"
	EVEN

;------------------------------------------------------------------------------
;
;	$VER: PTCalcTime v1.1 - by Håvard "Howard" Pedersen
;	© 1994-96 Mental Diseases
;
;	A program for calculating the playtime of ProTracker modules.
;
;	I cannot be held responsible for any damage caused directly or in-
;	directly by this code. Still, every released version is thouroughly
;	tested with Mungwall and Enforcer, official Commodore debugging tools.
;	These programs traps writes to unallocated ram and reads/writes to/from
;	non-ram memory areas, which should cover most bugs.
;
;	HISTORY:
;
;v1.0	Simple thingy with bugs and quirks. Did calculating using IRQ/second.
;
;v1.1	Bugfix version. Finally usable.
;	* Pattern loop wasn't sensed properly. By some reason I used effect
;	  command E5 for set loop! (?)
;	* Entire pattern loop code was broken. Recoded, does now work correctly
;	  with "mod.couldbe".
;	* Uses 1/25000th second between each interrupt for timing. Much more
;	  accurate in CIA mode.
;	* Small speedups here and there.
;
;------------------------------------------------------------------------------
;
;	PUBLIC FUNCTIONS:
;
;Function:	PTCalcTime(SongPos,delay,CIA(BOOL),Module,TimerStruct)
;		(D0,D1,D2,A0,A1)
;Purpose:	Calculates exact playtime of a ProTracker module.
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			PTCALCTIME
;------------------------------------------------------------------------------
; D0 - Local use
; D1 - 25000th of a second delay between each IRQ
; D2 - Local use
; D3 - Pattern delay count
; D4 - Local use
; D5 - 
; D6 - 
; D7 - Voiceloop count
; A0 - Module
; A1 - TimerStruct
; A2 - PatternPosition
; A3 - Local use
; A4 - 
; A5 - 
; A6 - 
PTCalcTime	move.l	#6,.Speed
		move.l	#0,.PattPos
		move.l	d0,.SongPos
		move.l	#0,.PattLoopPos
		move.l	#0,.PosJumpPos
		move.b	d2,.CIAFlag

.MainLoop	lea.l	952(a0),a2		; Get position
		add.l	.SongPos,a2
		moveq.l	#0,d0
		move.b	(a2),d0			; Get pattern at current pos
		lsl.l	#8,d0			; *1024
		lsl.l	#2,d0
		lea.l	1084(a0),a2
		add.l	d0,a2			; Address for pattern

.StepLoop	lea.l	952(a0),a2		; Get position
		add.l	.SongPos,a2
		moveq.l	#0,d0
		move.b	(a2),d0			; Get pattern at current pos
		lsl.l	#8,d0			; *1024
		lsl.l	#2,d0
		lea.l	1084(a0),a2
		add.l	d0,a2			; Address for pattern

		move.l	.PattPos,d0
		lsl.l	#4,d0
		add.l	d0,a2

		moveq.l	#4-1,d7			; Loop
.VoiceLoop	lea.l	.CmdsTab,a3
		move.l	(a2),d0			; Get stuff
		and.l	#$00000ff0,d0		; Get command

		move.l	d0,d2
		and.l	#$00000f00,d2
		cmp.l	#$00000e00,d2		; Misc cmds?
		beq.s	.TabLoop

		and.l	#$00000f00,d0

.TabLoop	cmp.l	#-1,(a3)
		beq.s	.NoneFound

		cmp.l	(a3),d0
		bne.s	.NoMatch

		move.l	4(a3),a3
		jsr	(a3)
		bra.s	.NoneFound

.NoMatch	addq.l	#8,a3
		bra.s	.TabLoop

.NoneFound	addq.l	#4,a2
		dbf	d7,.VoiceLoop

		bsr.w	.AddSpeed

		addq.l	#1,.PattPos

		tst.b	.BreakFlag
		bne.s	.NewPos

		cmp.l	#64,.PattPos
		bne.w	.StepLoop

.NewPos		move.b	#0,.BreakFlag

		move.l	.PattBreakPos,.PattPos
		move.l	#0,.PattBreakPos	; Default pattern break pos

		tst.l	.PosJumpPos
		beq.s	.NoPosJump

		move.l	.PosJumpPos,.SongPos
		move.l	#0,.PosJumpPos
		bra.s	.EndIt

.NoPosJump	add.l	#1,.SongPos
		move.l	.SongPos,d0
		lea.l	950(a0),a3
		cmp.b	(a3),d0
		blo.w	.MainLoop

.EndIt		move.l	12(a1),d0
		divu.w	#250,d0
		and.l	#$ffff,d0
		move.l	d0,12(a1)		; Convert to 100/s.

		rts

.AddSpeed	move.l	.Speed,d0
		subq.l	#1,d0
.SpeedLoop	add.l	d1,12(a1)
		dbf	d0,.SpeedLoop
.AddSpeedLoop	cmp.l	#25000,12(a1)
		blo.s	.OkIRQs
		sub.l	#25000,12(a1)
		add.l	#1,8(a1)
.OkIRQs		cmp.l	#60,8(a1)
		blo.s	.OkSecs
		sub.l	#60,8(a1)
		add.l	#1,4(a1)
.OkSecs		cmp.l	#60,4(a1)
		blo.s	.OkMins
		sub.l	#60,4(a1)
		add.l	#1,(a1)
.OkMins		rts

.CmdsTab	dc.l	$00000b00,._PosJump
		dc.l	$00000d00,._PattBreak
		dc.l	$00000f00,._SetSpeed
		dc.l	$00000e60,._PatLoop
		dc.l	$00000ee0,._PatDelay
		dc.l	-1,-1

._PosJump	move.l	(a2),d0			; Get stuff
		and.l	#$ff,d0
		move.l	d0,.PosJumpPos
		move.b	#-1,.BreakFlag
		rts

._PattBreak	move.l	(a2),d0			; Get stuff
		and.l	#$ff,d0
		move.l	d0,.PattBreakPos
		move.b	#-1,.BreakFlag
		rts

._SetSpeed	move.l	(a2),d0			; Get stuff
		and.l	#$ff,d0
		beq.s	.Halt

		tst.b	.CIAFlag
		beq.s	.VBL

		cmp.b	#$20,d0
		blo.s	.VBL

		; Do some CIA->Hz converting!
		move.l	#62500,d1
		divu.w	d0,d1
		and.l	#$ffff,d1

		rts

.VBL		move.l	d0,.Speed
		rts

.Halt		move.l	#-1,.PosJumpPos		; Halt module
		move.b	#-1,.BreakFlag
		rts

._PatLoop	move.l	(a2),d0			; Get stuff
		and.l	#$f,d0
		tst.l	d0
		beq.s	.SetLoop

		tst.l	.PattLoopCnt
		beq.s	.SetLoopCnt

		subq.l	#1,.PattLoopCnt
		bne.s	.DoLoop

		rts

.SetLoop	move.l	.PattPos,.PattLoopPos
		rts

.SetLoopCnt	move.l	d0,.PattLoopCnt

.DoLoop		move.l	.PattLoopPos,.PattBreakPos; Force loop
		sub.l	#1,.SongPos
		move.b	#-1,.BreakFlag

		rts

.PattLoopIt	subq.l	#1,.PattLoopCnt
		tst.l	.PattLoopCnt
		beq.s	.Return

		move.l	.PattLoopPos,.PattPos
.Return		rts

._PatDelay	move.l	(a2),d0			; Get stuff
		and.l	#$f,d0
		tst.l	d0
		beq.s	.PatDelNo
		subq.l	#1,d0
		move.l	d0,d3
.PatDelLoop	bsr.w	.AddSpeed
		dbf	d3,.PatDelLoop
.PatDelNo	rts

.BreakFlag	dc.b	0
.CIAFlag	dc.b	0
	EVEN
.Speed		dc.l	0
.PattPos	dc.l	0
.SongPos	dc.l	0
.PattLoopPos	dc.l	0
.PattLoopCnt	dc.l	0
.PosJumpPos	dc.l	0
.PattBreakPos	dc.l	0

