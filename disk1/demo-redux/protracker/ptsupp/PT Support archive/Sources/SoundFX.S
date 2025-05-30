
SFX__BuffSize	=	286			; Must be an even number!
SFX__FastMode	=	0
SFX__Debug	=	1
SFX__Mode	=	1

		jmp	Go

; Your samples. Locate in fast if possible!

	INCDIR	"!Sources:Productions/PTSupp/"

Sample1	INCBIN	SAMPLE1
	dcb.b	64,0
Sample1End

Sample2	INCBIN	SAMPLE2
	dcb.b	416,0
Sample2End

Go		move.w	#248,d0
		bsr.w	SFX_Init		; Initialize with fairly low
						; rate. (This makes us use
						; samples with low frequencies,
						; which again saves memory!)
		beq.s	.Quit

		moveq.l	#0,d0
		lea.l	Sample1,a0
		lea.l	Sample1End,a1
		bsr.w	SFX_StartSound		; Start sample 1

		moveq.l	#1,d0
		lea.l	Sample2,a0
		lea.l	Sample2End,a1
		bsr.w	SFX_StartSound		; Start sample 2

.a		cmp.b	#$ff,$dff006
		bne.s	.a
.b		cmp.b	#$ff,$dff006
		beq.s	.b

		btst	#6,$bfe001		; Wait for mouse
		bne.s	.a

.Quit		bsr.w	SFX_End			; End

		moveq.l	#0,d0			; Successful exit
		rts

;------------------------------------------------------------------------------
;
;	$VER: SoundFX v1.2 sound replay - by Håvard "Howard" Pedersen
;	© 1994-96 Mental Diseases
;
;	A simple program for handling the replay of multiple soundeffects
;	through a single audio channel.
;
;	I cannot be held responsible for any damage caused directly or in-
;	directly by this code. Still, every released version is thouroughly
;	tested with Mungwall and Enforcer, official Commodore debugging tools.
;	These programs traps writes to unallocated ram and reads/writes to/from
;	non-ram memory areas, which should cover most bugs.
;
;	HISTORY:
;
;v1.0	Based on an article in AM/FM #11 by Teijo Kinuunen. Simple thing with
;	preset playback rate. Soundeffects length has to be a multiple of
;	SFX__BuffSize.
;
;v1.1	Upvamped version.
;	* Selectable playback rate. (No big deal)
;	* Mastervolume.
;
;v1.2	Threw the original mixing scheme out.
;	* Fixed a bug where the interrupt sometimes didn't fill the entire
;	  output-buffer. (Clicks and distorted sound could occur!)
;	* The end-of-sound detection was a bit buggy. Fixed.
;	* Earlier there was some problems with the sound not always appearing
;	  when running SoundFX for the first time. This _seems_ to be fixed.
;	* Included fast mode. (Max 246/248 in playback rate!)
;	* Added SFX_StopSound().
;	* Optimized mixing a lot.
;	* SoundFX did not stop when errors occured. Now errors are properly
;	  signalled.
;	* Did some alterations to make the source more portable. (Stopped using
;	  includes and my personal macros.)
;	* Uses Disable()/Enable() instead of some bogus macros to disable
;	  interrupts.
;	* Added non-interrupt mode, to make it possible to mix the channels
;	  within a vertical-blank interrupt.
;
;	TODO:
;
;* Expand to 2 channels/4 voices. (optional)
;
;------------------------------------------------------------------------------
;
;	CONSTANTS:
;
;Constant:	SFX__BuffSize(INTEGER)
;Purpose:	Specifies the size of SoundFXs output buffer. The number should
;		be even. A large value causes less overhead by the interrupt
;		code but uses more memory for the buffers.
;
;Constant:	SFX__FastMode(BOOL)
;Purpose:	If set to non-zero, the fastmode will be enabled. The fastmode
;		provides faster mixing but is only capable of playing samples
;		at half the normal rates. Please also note that the sounddata
;		does not need to be halved when using the fastmode. This mixing
;		mode may produce high-frequency tones which may both distort
;		the sound and destroy loudspeakers! To get rid of this extra-
;		feature, enable the audio filter. :)
;
;Constant:	SFX__Debug(BOOL)
;Purpose:	If set to true, colors will be used to display CPU usage for
;		mixing loop.
;
;Constant:	SFX__Mode(BOOL)
;Purpose:	Selects the mode for SoundFX to run in. Modes are:
;		0 - User vertical blank. SoundFX will be set up for vertical
;		    blank operation, but relies on the user to call
;		    SFX_VBLHandle() each vertical blank.
;		1 - OS AudioInterrupt. SoundFX installs the interrupt itself
;		    using the operating system.
;		Vertical blank modes needs you to carefully pick the buffersize
;		so that it's just about finished playing in one frame.
;
;	PUBLIC FUNCTIONS:
;
;Function:	SFX_Init(Rate)(D0)
;Purpose:	Initalize the routine and install audio-interrupt. Remember
;		that when the fastmode is enabled the actual sample playback
;		frequence will be half of what you state. Maximum values are
;		123 for PAL and 124 for NTSC. Remember to double these figures
;		when using the fastmode.
;
;Function:	SFX_End()
;Purpose:	Remove our audio interrupt and free any allocated resources.
;
;Function:	SFX_StartSound(Partition,Wave,Waveend)(D0,A0,A1)
;Purpose:	Start playing the selected sound. The sounddata should be
;		halved if the fastmode is disabled.
;
;Function:	SFX_StopSound(Partition)(D0)
;Purpose:	Stops the current sound.
;
;Function:	SFX_SetVolume(Volume.w (0-64))(D0)
;Purpose:	Alters the playback volume. Use for fading.
;
;	PRIVATE FUNCTIONS:
;
;Function:	SFX_VBLInit()
;Purpose:	Initializes SoundFX for use without using the audio interrupt.
;
;Function:	SFX_VBLEnd()
;Purpose:	Closes down SoundFX when audio interrupt hasn't been used.
;
;Function:	SFX_VBLHandle()
;		Does the actuall stuff when SoundFX is run in VBL-mode.
;
;Function:	SFX_AudIntInit()
;Purpose:	Initializes the audio interrupt handler.
;
;Function:	SFX_AudIntEnd()
;Purpose:	Closes down the audio interrupt handler.
;
;Function:	SFX_AudInt()
;Purpose:	This is the interrupt-handler for SoundFX when running in audio
;		interrupt mode.
;
;Function:	SFX_DoMix()
;Purpose:	Does actual mixing.
;
;------------------------------------------------------------------------------

; Set all undefined constants to default values. If you dont't like 'em, feel
; free to change, though you'll have to do it all over for each new version.

	ifnd SFX__BuffSize
SFX__BuffSize	=	1024			; 16-131072
	endc

	ifnd SFX__FastMode
SFX__FastMode	=	0			; BOOL
	endc

	ifnd SFX__Debug
SFX__Debug	=	0			; BOOL
	endc

	ifnd SFX__Mode
SFX__Mode	=	1			; BOOL
	endc

	rsreset	; Voice data
vd_StartPtr	rs.l	1			; Start of data, CHIP
vd_EndPtr	rs.l	1			; End of data, CHIP
vd_Active	rs.l	1
vd_sizeof	rs.b	0

SFX_WAITDMA	macro
		move.w	$dff006,d1
		moveq.l	#80-1,d0
.DMALoop1	cmp.w	$dff006,d1
		beq.s	.DMALoop1
		move.w	$dff006,d1
.DMALoop2	cmp.w	$dff006,d1
		beq.s	.DMALoop2
		move.w	$dff006,d1
   		dbf	d0,.DMALoop1
		endm

;------------------------------------------------------------------------------
;==				INIT					     ==
;------------------------------------------------------------------------------
SFX_Init
	ifne SFX__FastMode
		lsr.l	#1,d0		; Double playback rate
	endc

		move.w	d0,SFX_PlayRate

		moveq.l	#0,d0
		bsr.w	SFX_StopSound		; Play no sound.

		moveq.l	#1,d0
		bsr.w	SFX_StopSound		; Play no sound.

		lea	SFX_AudioBuff,a0
		move.w	#SFX__BuffSize-1,d1
.ClrLoop	clr.w	(a0)+			; Clear track buffers
		dbf	d1,.ClrLoop

		clr.b	SFX_WhichBuffer		; Buffer flag

	ifeq SFX__Mode
		bsr.w	SFX_VBLInit
	endc
	ifeq SFX__Mode-1
		bsr.w	SFX_AudIntInit
	endc
		beq.s	.Err

		moveq.l	#1,d0
		rts

.Err		bsr.s	SFX_End
		moveq	#0,d0
		rts

;------------------------------------------------------------------------------
;==				END					     ==
;------------------------------------------------------------------------------
SFX_End
	ifeq SFX__Mode
		bsr.w	SFX_VBLEnd
	endc
	ifeq SFX__Mode-1
		bsr.w	SFX_AudIntEnd
	endc

		rts

;------------------------------------------------------------------------------
;==				SETVOLUME				     ==
;------------------------------------------------------------------------------
SFX_SetVolume	move.w	d0,$dff0d8
		move.w	d0,SFX_Volume
		rts

;------------------------------------------------------------------------------
;==				STARTSOUND				     ==
;------------------------------------------------------------------------------
SFX_StartSound	tst.l	d0
		beq.s	.Zero

		lea	SFX_PartitionB,a2
		move.l	a0,vd_StartPtr(a2)	; Init ptr
		move.l	a1,vd_EndPtr(a2)	; Init endptr
		move.l	#1,vd_Active(a2)

		rts

.Zero		lea	SFX_PartitionA,a2
		move.l	a0,vd_StartPtr(a2)	; Init ptr
		move.l	a1,vd_EndPtr(a2)	; Init endptr
		move.l	#1,vd_Active(a2)

		rts

;------------------------------------------------------------------------------
;==				STOPSOUND				     ==
;------------------------------------------------------------------------------
SFX_StopSound	tst.l	d0
		beq.s	.Zero

		lea	SFX_PartitionB,a2
		move.l	#SFX_ZeroData,vd_StartPtr(a2)	; Init startptr
		move.l	#SFX_ZeroData+SFX__BuffSize,vd_EndPtr(a2); Init endptr
		move.l	#0,vd_Active(a2)

		rts

.Zero		lea	SFX_PartitionA,a2
		move.l	#SFX_ZeroData,vd_StartPtr(a2)	; Init startptr
		move.l	#SFX_ZeroData+SFX__BuffSize,vd_EndPtr(a2); Init endptr
		move.l	#0,vd_Active(a2)

		rts

	ifeq SFX__Mode

;------------------------------------------------------------------------------
;==				VBL INIT				     ==
;------------------------------------------------------------------------------
SFX_VBLInit	lea	$dff000,a0

		move.w	#$0008,$96(a0)		; dmacon (disable audio)
		move.l	#$0400,$9a(a0)		; intena (disable audio)

		move.w	#SFX__BuffSize/2,aud3+ac_len(a0); Buffer size
		move.w	#65535,aud3+ac_per(a0)		; Period
		move.l	#SFX_AudioBuff,aud3+ac_ptr(a0)	; Pointer
		move.w	SFX_Volume,aud3+ac_vol(a0)	; Volume

		SFX_WAITDMA

		move.w	#$8008,$96(a0)		; dmacon (enable audio)

		moveq.l	#1,d0
		rts

;------------------------------------------------------------------------------
;==				VBL END					     ==
;------------------------------------------------------------------------------
SFX_VBLEnd	move.w	#$0008,$dff096
		rts

;------------------------------------------------------------------------------
;==			VBL FRAMEHANDLER				     ==
;------------------------------------------------------------------------------
SFX_VBLFrame	lea.l	SFX_AudioBuff,a1
		not.b	SFX_WhichBuffer		; Swap buffer
		beq.s	.SetBuff

.UseBuff1	lea.l	SFX__BuffSize(a1),a1	; Get next buffer

.SetBuff	lea.l	$dff000,a0

		move.w	#$0008,$96(a0)		; dmacon (disable audio)

		move.w	#SFX__BuffSize/2,aud3+ac_len(a0); Buffer size
		move.w	SFX_PlayRate,aud3+ac_per(a0)	; Period
		move.l	a1,aud3+ac_ptr(a0)		; Pointer
		move.w	SFX_Volume,aud3+ac_vol(a0)	; Volume

		SFX_WAITDMA

		move.w	#$8008,$96(a0)		; dmacon (enable audio)

		bsr.s	SFX_DoMix

		rts

	endc

	ifeq SFX__Mode-1

;------------------------------------------------------------------------------
;==			AUDIOINTERRUPT INIT				     ==
;------------------------------------------------------------------------------
SFX_AudIntInit	moveq	#10,d0			; INTB_AUD3
		lea	SFX_AudIntReq,a1
		move.l	4.w,a6
		jsr	-162(a6)		; _LVOSetIntVector

		move.l	d0,SFX_PrevAudInt
		beq.w	.Err

		lea	$dff000,a0
		move.w	#SFX__BuffSize/2,$d4(a0); Buffer size
		move.w	#65535,$d6(a0)		; Period
		move.l	#SFX_AudioBuff,$d0(a0)	; Pointer
		move.w	SFX_Volume,$d8(a0)	; Volume

		lea	$dff000,a0
		move.w	#$4000,$9a(a0)

		move.l	4.w,a6
		jsr	-120(a6)		; _LVODisable

		lea	$dff000,a0
		move.w	#$0008,$96(a0)		; Audio DMA off
		move.w	#$8400,$9a(a0)		; Enable sound interrupt
		move.w	#$c000,$9a(a0)
		move.w	#$8008,$96(a0)		; DMA Audio channel 3 ON

		move.l	4.w,a6
		jsr	-126(a6)		; _LVOEnable

		moveq.l	#1,d0
		rts

.Err		moveq.l	#0,d0
		rts

;------------------------------------------------------------------------------
;==			AUDIOINTERRUPT END				     ==
;------------------------------------------------------------------------------
SFX_AudIntEnd	tst.b	SFX_IfPlay
		beq.s	.NoPlay

		move.w	#1<<10,$dff09a
		move.w	#$8,$dff096
		clr.b	SFX_IfPlay

.NoPlay		move.l	SFX_PrevAudInt,d0
		beq.s	.NoInt			; Any interrupt?

		move.l	#0,SFX_PrevAudInt	; Clear interrupt
		move.w	#1<<10,$dff09a		; intena
		move.l	d0,a1
		moveq	#10,d0
		move.l	4.w,a6
		jsr	-162(a6)		; _LVOSetIntVector

.NoInt		move.w	#$0008,$dff096		; Stop Audio DMA

		rts

;------------------------------------------------------------------------------
;==				INTHANDLER				     ==
;------------------------------------------------------------------------------
SFX_AudInt	movem.l	d2-a0/a2-a6,-(sp)

		not.b	SFX_WhichBuffer		; Swap buffer
		beq.s	.SetBuff

.UseBuff1	lea.l	SFX__BuffSize(a1),a1	; Get next buffer

.SetBuff	lea.l	$dff000,a0
		move.l	a1,$d0(a0)

 		move.w	#SFX__BuffSize/2,$d4(a0); Buffer size
		move.w	SFX_PlayRate,$d6(a0)	; Period
		move.w	SFX_Volume,$d8(a0)	; Volume

		move.w	#1<<10,$9c(a0)		; Clear intreq bit

		bsr.s	SFX_DoMix

		moveq.l	#0,d0

		movem.l	(sp)+,d2-a0/a2-a6
		rts

	endc

;------------------------------------------------------------------------------
;==				DOMIX					     ==
;------------------------------------------------------------------------------
SFX_DoMix
	ifne SFX__Debug
		move.w	#$fff,$dff180
	endc

		lea.l	SFX_PartitionA,a3

		tst.l	vd_Active(a3)		; Addvalue
		beq.s	.AOk

	ifeq SFX__FastMode
		add.l	#SFX__BuffSize,vd_StartPtr(a3)	; Next chunk
		move.l	(a3),d7			; Fetch ptr
		add.l	#SFX__BuffSize,d7
		cmp.l	vd_EndPtr(a3),d7	; Will we break?
		bls.s	.AOk
	else
		add.l	#SFX__BuffSize/2,vd_StartPtr(a3); Next chunk
		move.l	(a3),d7			; Fetch ptr
		add.l	#SFX__BuffSize/2,d7
		cmp.l	vd_EndPtr(a3),d7	; Will we break?
		bls.s	.AOk
	endc

		clr.l	vd_Active(a3)		; Stop sound
		move.l	#SFX_ZeroData,vd_StartPtr(a3)
		move.l	#SFX_ZeroData+SFX__BuffSize,vd_EndPtr(a3)

.AOk		lea.l	SFX_PartitionB,a4

		tst.l	vd_Active(a4)		; Addvalue
		beq.s	.BOk

	ifeq SFX__FastMode
		add.l	#SFX__BuffSize,vd_StartPtr(a4)	; Next chunk
		move.l	(a4),d7			; Fetch ptr
		add.l	#SFX__BuffSize,d7
		cmp.l	vd_EndPtr(a4),d7	; Will we break?
		bls.s	.BOk
	else
		add.l	#SFX__BuffSize/2,vd_StartPtr(a4)	; Next chunk
		move.l	(a4),d7			; Fetch ptr
		add.l	#SFX__BuffSize/2,d7
		cmp.l	vd_EndPtr(a4),d7	; Will we break?
		bls.s	.BOk
	endc

		clr.l	vd_Active(a4)		; Stop sound
		move.l	#SFX_ZeroData,vd_StartPtr(a4)
		move.l	#SFX_ZeroData+SFX__BuffSize,vd_EndPtr(a4)

.BOk		move.l	vd_StartPtr(a3),a3	; Get startaddress A
		move.l	vd_StartPtr(a4),a4	; Get startaddress B

	ifeq SFX__FastMode
		move.l	#SFX__BuffSize-1,d5
	else
		move.l	#(SFX__BuffSize/2)-1,d5
	endc
.MixLoop

	ifeq SFX__FastMode
		move.b	(a3)+,d4		; Get sample 1
		add.b	(a4)+,d4		; Add sample 2
		move.b	d4,(a1)+		; Store value in buffer.
	else
		move.b	(a3)+,(a1)+		; Get sample 1
		move.b	(a4)+,(a1)+		; Get sample 2
	endc

		dbf	d5,.MixLoop

	ifne SFX__Debug
		move.w	#0,$dff180
	endc
		rts

;------------------------------------------------------------------------------

SFX_ZeroData	dcb.b	SFX__BuffSize,0
	EVEN

SFX_PartitionA	dcb.b	vd_sizeof,0
SFX_PartitionB	dcb.b	vd_sizeof,0

	ifeq SFX__Mode-1

SFX_AudIntReq	dc.l	0,0			; SUCC, PRED
		dc.b	2			; NT_INTERRUPT
		dc.b	0
		dc.l	.IntName

		dc.l	SFX_AudioBuff
		dc.l	SFX_AudInt,0
.IntName	dc.b	"SoundFX audioint",0
	EVEN
SFX_PrevAudInt	dc.l	0

	endc

SFX_PlayRate	dc.w	0
SFX_Volume	dc.w	64
SFX_IfPlay	dc.b	0
SFX_WhichBuffer	dc.b	0

SFX_AudioBuff	ds.b	SFX__BuffSize*2		; Two buffers

