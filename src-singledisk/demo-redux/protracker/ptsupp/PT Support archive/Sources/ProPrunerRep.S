
; ProPruner example code, look below for more information.
; Maximum stack usage : ca. 108 bytes.

PPR_68020	=	1
PPR_NotePlayer	=	0

Go		move.l	4.w,a6
		jsr	-132(a6)		; _LVOForbid

		moveq.l	#0,d0
		lea.l	GfxName(pc),a1
		move.l	4.w,a6
		jsr	-552(a6)		; _LVOOpenLibrary

		tst.l	d0
		beq.w	Exit

		lea.l	GfxBase(pc),a0
		move.l	d0,(a0)

		bsr.w	GetVBR

		lea.l	PPR_MainData(pc),a0
		move.l	d0,PPRM_VBR(a0)

		lea.l	Module,a0
		bsr.w	PPR_Init		; Initialize replay

MainLoop	move.l	GfxBase(pc),a6
		jsr	-270(a6)		; _LVOWaitTOF

.BeamLoop	move.l	GfxBase(pc),a6
		jsr	-384(a6)		; _LVOVBeamPos

		move.w	#$000,$dff180

		and.l	#$c0,d0
		beq.s	.BeamLoop

		move.w	#$fff,$dff180
		bsr.w	PPR_Music		; Play some
		move.w	#$000,$dff180		; $78a

		btst	#6,$bfe001		; ...And loop
		bne.s	MainLoop

		bsr.w	PPR_End			; Disable all notes.

		move.l	4.w,a6
		jsr	-138(a6)		; _LVOPermit

		move.l	GfxBase(pc),a1
		move.l	4.w,a6
		jsr	-414(a6)		; _LVOCloseLibrary

Exit		moveq.l	#0,d0
		rts

;------------------------------------------------------------------------------
;Function:	VBR=GetVBR()
;Purpose:	Obtain vectorbaseregister independent of processor hardware.
;------------------------------------------------------------------------------

GetVBR		moveq.l	#0,d0
		move.l	4.w,a6
		btst.b	#0,297(a6)
		beq.w	.Not68010
		lea.l	VBR_Exec(pc),a5
		jsr	-30(a6)			; _LVOSupervisor

.Not68010	rts

;Code to execute if processor >= 68010.
;Since not all assemblers handle the movec vbr,(ea) instruction, the opcode is
;included.

VBR_Exec	;dc.l	$4e7a0801		; = MOVEC VBR,D0
		movec	vbr,d0
		rte

GfxBase		dc.l	0
GfxName		dc.b	"graphics.library",0
	even

;------------------------------------------------------------------------------
;==			NOTEPLAYER INTERFACE				     ==
;------------------------------------------------------------------------------
PPRN_InitReg	macro	; (Channel)
		lea.l	$dff0a0,a5
		endm

PPRN_KillSound	macro
		endm

PPRN_KillCh	macro
		endm

PPRN_TrigWave	macro	; (Wavestart, Wavelen)
		endm

PPRN_SetWave	macro	; (Wavestart, Wavelen)
		endm

PPRN_SetVolume	macro	; (Volume)
		endm

PPRN_SetRate	macro	; (Rate)
		endm

PPRN_SetMVolL	macro	; (MVolume)
		endm

PPRN_SetMVolR	macro	; (MVolume)
		endm

PPRN_Filter	macro	; (State)
		endm

; Do actual mixing and trig replay.
PPRN_MakeSound
		rts	; This is _NOT_ a macro!



;------------------------------------------------------------------------------
;
;	$VER: ProPruner v1.21 Playroutine - by Håvard "Howard" Pedersen
;	© 1993-96 Mental Diseases
;	STRICTLY FOR PRIVATE USE!!!
;
;	Based on the ProPacker v2.1 playroutine by Estrup/Static Bytes and his
;	own improvement-ideas for ProPacker v3.0.
;
;	I cannot be held responsible for any damage caused directly or in-
;	directly by this code. Still, every released version is thouroughly
;	tested with Mungwall and Enforcer, official Commodore debugging tools.
;	These programs traps writes to unallocated ram and reads/writes to/from
;	non-ram memory areas, which should cover most bugs.
;
;	HISTORY:
;
;v0.4	Called ProCracker. Basically very similar to ProPacker v2.1.
;	* Added mastervolume possibilities through SetMasterVol().
;	* Added synchronization-byte sent trough effectcommand 8.
;	* Added restart-flag.
;
;v1.0	Renamed to ProPruner. First really useful version. This replay was
;	used in the "Hypnophone" musicdisk by Compact.
;	* Separate samplefile.
;	* Friendly DMA-wait using VHPOSR.
;	* Wrote ProPrunerStrip and ProPrunerSampler to simplify usage of
;	  separate samplefiles.
;	* Added PreDouble boolean to speed up replay.
;	* Speeded up replay in numerous ways.
;	* Possibility to turn off mastervolume with MasterVol boolean.
;	* Possibility to disable audio channels.
;	* Added delta processing.
;	* Added support for speed 0 to halt module.
;	* Speeded up mastervolume routines by using macros instead of sub-
;	  routines.
;	* Readded FineTune boolean. By some reason, it got deleted during the
;	  development of v0.4. (My finetune boolean will save space as well as
;	  rastertime!)
;	* Gave user possibility to fetch the VBR and pass to ProPruner.
;	* Added CIA possibilities. (You must add the interrupt yourself!)
;
;v1.1	Optimizations starts getting noticeable. Average speed on a normal A500
;	should be about 4-5 lines! Source-size is also increasing.
;	* DMAWait waited 224 ns instead of 280. It worked fine on my A1200, but
;	  could fuck up on a 80 mHz 68060 with FPU and 60 ns fastram. (Or
;	  something...)
;	* Small optimization on WaitDMA.
;	* To save further time when waiting for the DMA, WaitDMA is changed
;	  from a subroutine to a macro. Now my WaitDMA macro provides minimum
;	  overhead.
;	* PPR_Music() now trashes all registers except A7. This may optimize a
;	  bit if your interrupt-code saves all registers anyway. (Mine does!)
;	* Numerous optimizations.
;	* Added boolean for 68020+ optimizations.
;	* Fixed the way PPR_Init() and PPR_End() disabled/enabled playing to
;	  prevent audible bugs from occur when PPR_Music() was called while
;	  initializing variables.
;	* Added DMADelay constant for user-selectable delay when using DMAWait.
;	* Optimized the MasterVolume code particulary.
;	* Several locations in the source used the clear-command on hardware
;	  registers. This behaviour is discouraged by Commodore and is now
;	  fixed.
;	* Added (selectable) PPR_Pause() and PPR_Continue().
;	* Added (selectable) PPR_Forward() and PPR_Rewind().
;	* Enforcer checked and found reliable. =D
;	* Removed a rather nasty bug of mine, which caused some modules to be
;	  played without the fourth channel. (Not sure when it appeared, but I
;	  admit it's mine...) :(
;	* Optimized finetune a lot.
;	* Made PPR_Level6 default to FALSE, since it's shitty implemented
;	  concidering the lovely multitasking environment of the Amiga.
;
;v1.2	Things are getting somewhere. The need for a separate packer starts to
;	rise. Sourcesize is 69 Kb, more than three times the size of the
;	original ProPacker v2.1 replay!
;	* PPR_Init didn't reset the tempo when in CIA mode. Fixed.
;	* Halting the module with F00 didn't trig restartflag. Fixed.
;	* Set volume didn't work at all when PPR_MasterVol was set to true. 8(
;	* Finally added the PowerPattern structure I've been dreaming about.
;	  Finetune, toneportamento and arpeggio were drastically optimized due
;	  to this.
;	* Cleaned up the source a lot by making definitions of the voicedata-
;	  and maindata- variables and ensured the entire source used it.
;	* Optimized the voicedata- and maindata-variables to make longword
;	  accesses on longword boundaries.
;	* Toneportamento with finetune enabled would play crazy notes! Fixed.
;	* Indirext addressing is now used when accessing all variables,
;	  resulting in even better speed.
;	* The play-routine is now (finally!) completely PC-relative.
;	* A long-standing bug could have caused the sample-addresses to become
;	  totally fucked up. Fixed. (Another one bites the dust! 8)
;	* Numerous small optimizations. As always, I fucked up during
;	  optimizing and had to compare the source line by line to an older
;	  version to find the bug I inserted. ;(
;	* Playroutine now uses less space than earlier, since variables used by
;	  pause, mastervolume etc. is now included based on the switches.
;	* The demo-source of ProPruner now fetches the VBR correctly.
;	* Playroutine source now contains version information. :)
;	* Optimized recognition of effectcommands.
;	* The demo-source now uses graphics-library for VBL-waiting.
;	* ProPruner is now fixed to work on almost any assembler! (Some if's
;	  weren't standard in earlier versions...)
;	* Extended effectcommands are no longer called each frame no matter.
;	  This optimises a lot when these are in use. Pattern delay engine had
;	  to be altered due to this.
;	* Arpeggio no longer uses divx/mulx, but a counter. (Mo' speed!)
;	* Added NotePlayer interface to replay. This feature hasn't been tested
;	  at all. Please report any bugs.
;	* Disabling of channels turned out to be buggy. You wouldn't actually
;	  hear any sound on the disabled channels, but the replay would still
;	  (in some places) adjust volume and turn on and off DMA for disabled
;	  channels. Some people may not see why this was a serious bug, but the
;	  reason for implementing disabled channels at all was to make them
;	  free for sound-effects. (Games!)
;	* PPR_DMADelay removed. The DMAWait waited longer than it had to. The
;	  CPU obvously wasn't fast enough to keep up with the changes in
;	  VHPOSR. Uses I/O chips for timing.
;	* Added balance possibilities through left and right mastervolume. No
;	  extra overhead provided.
;
;v1.21	Small update.
;	* Renamed PPR_SetBPM to CIA_SetBPM to obtain compatibility with my
;	  ProTracker replay.
;	* DMAWait was buggy again. (Hrmph!) Another rewrite. Should be 100%
;	  now. I really apologize, but it's Commodore's fault, they didn't
;	  document the audio hardware thoroughly enough. :(
;
;	TODO: (Things to do, bugs to squash...)
;
;* Make it possible to disable all handling of sample-pointers by PPR_Init(),
;  to allow the user to set up samples himself. (For song-like structures!)
;* Attempt to optimize invert loop.
;* Make PPR_Init() return errorcodes upon failure.
;* Optimize filter effectcommand.
;* Optimize PPR_Init() and PPR_SetMasterVol()
;* Ensure correct delay in level6-interrupt.
;* Steal ideas from other replays. (The Player, ProRunner, Promizer...)
;* Write own packer (with own format).
;* Get VBR in a nice manner.
;* Make PPR_Level6 nicer to the OS.
;* Channels on/off during play. (Too much work...!) (Selectable)
;* Optimize mastervolume so that only one macro is necessary.
;* Glissando still uses a loop. 8(
;* Audio hardware pointers located in the voiceinfo-variables.
;* Use counter instead of division when doing retrig note. (The last divx/mulx
;  in the code!)
;* Convert pattern break parameters to hex.
;* Use more local labels.
;* Usecode system like The Player. (With finetune and predouble integrated!)
;* Optimize WaitDMA to only wait when needed.
;
;------------------------------------------------------------------------------
;
;	CONSTANTS:
;
;Constant:	PPR_Level6(BOOL)
;Purpose:	If set to TRUE, a level 6 interrupt will be used for timing
;		delays instead of DMAWait. This gives optimum results, but
;		should only be enabled if you have EXCLUSIVE access to system
;		resources! Defaults to FALSE. This require this interrupt to be
;		free for usage, i.e. it might interfere with CIA.
;
;Constant:	PPR_SampleFile(BOOL)
;Purpose:	If set to TRUE, the samples are given separate to the replayer
;		upon PPR_Init(). This enables sample sharing and the
;		possibility to have the songdata located in fast. Defaults to
;		FALSE.
;
;Constant:	PPR_PreDouble(BOOL)
;Purpose:	If set to TRUE, the module will be processed, resulting in a
;		faster performance. This might _NOT_ work on all modules,
;		especially on long ones. Defaults to TRUE. ProPruner will
;		handle already processed modules.
;
;Constant:	PPR_MasterVol(BOOL)
;Purpose:	If set to TRUE, mastervolume features will be enabled. This
;		will consume more rastertime than without, therefore it
;		defaults to FALSE.
;
;Constant:	PPR_Delta(BOOL)
;Purpose:	If set to TRUE, the playroutine will handle delta packed
;		samples. This needs PPR_SampleFile to be enabled. Defaults to
;		TRUE if PPR_SampleFile is enabled.
;
;Constant:	PPR_Finetune(BOOL)
;Purpose:	If set to TRUE, the playroutine will handle finetune. Defaults
;		to TRUE, since most people nowadays uses finetune.
;
;Constant:	PPR_CIA(BOOL)
;Purpose:	If set to TRUE, CIA_SetBPM will be called whenever the CIA
;		tempo needs to be changed. Defaults to FALSE, since using the
;		CIA timers in a system-friendly manner is hard. Please remember
;		that level 6 interrupts will not work with a playroutine called
;		from within an interrupt. CIA_SetBPM is called with BPM (byte)
;		in D0, and may only trash D0/D1/A1.
;
;Constant:	PPR_68020(BOOL)
;Purpose:	If set to true, ProPruner will assemble with special 68020+
;		optimizations. Defualts to FALSE to avoid unexpected crashes.
;
;Constant:	PPR_PauseFuncs(BOOL)
;Purpose:	If set to true, PPR_Pause() and PPR_Continue() will be
;		included. defaults to false.
;
;Constant:	PPR_WindFuncs(BOOL)
;Purpose:	If set to true, PPR_Forward() and PPR_Rewind() will be
;		included. defaults to false.
;
;Constant:	PPR_PowerPatt(BOOL)
;Purpose:	If enabled, will cause PPR_Init() to convert the patterndata to
;		a more suitable format before playing.
;
;Constant:	PPR_NotePlayer(BOOL)
;Purpose:	If enabled, external functions will be used instead of banging
;		on the Amiga hardware registers when sound is wanted.
;
;Constant:	PPR_Channels(0-4)
;Purpose:	Selects number of channels to play. Nice for games. 8) Defaults
;		to 4. Disabling channels saves a huge amount of raster time.
;		NB! Do note that ProPruner will not sense ANY effectcommands on
;		the disabled channels! (Speed or pattern break...)
;
;	FUNCTIONS:
;
;Function:	PPR_Continue()
;Purpose:	Continues the module after a stop caused by PPR_Pause().
;
;Function:	PPR_End()
;Purpose:	Stops any sound currently being played on any audio channel and
;		brings module to a halt. (In reverse order, that is. :)
;
;Function:	PPR_Forward()
;Purpose:	Skips one position forward. Will restart if at end of module.
;		!!! This call will miss position jumps !!!
;
;Function:	PPR_Init(Module,SampleFile)(A0,A1)
;Purpose:	Initalize everything. You must call this first. Samplefile is
;		only necessary if PPR_SampleFile is TRUE. Module-data must be
;		a ProPacker 2.1 module. Do not call while module is playing,
;		stop current module with PPR_End() first. This function may
;		also be used to restart the module.
;
;Function:	PPR_Music()
;Purpose:	Play the module. Call this with an even interval. (50 times per
;		second gives optimum result.) Do note that this function
;		trashes all registers.
;
;Function:	PPR_Pause()
;Purpose:	Pauses the module. (Silence)
;
;Function:	PPR_Rewind()
;Purpose:	Skips one position backwards. If at position 0, the module will
;		wrap to the end. !!! This call will miss position jumps !!!
;
;Function:	PPR_SetMasterVol(LeftVolume,RightVolume)(D0.w,D1.w)
;Purpose:	Adjust the mastervolume of the module. Range is 0-63. Only
;		callable if PPR_MasterVol is set to TRUE. A value of 64 is also
;		interpreted as full volume.
;
;	DATAFIELDS:
;
;Field:		PPRM_Msg(PPR_MainData).b
;Contents:	Communication byte, sent from module via effect-command 8.
;
;Field:		PPRM_SongPos(PPR_MainData).b
;Contents:	The position of the module currently being played.
;
;Field:		PPRM_HiPattern(PPR_MainData).b
;Contents:	The highest pattern used in the module.
;
;Field:		PPRM_RestFlag(PPR_MainData).b
;Contents	If TRUE, module has restarted.
;
;Field:		PPRF_Positions(Module).b
;Contents:	Total number of positions in module.
;
;Field:		PPR_VoiceData+CH*PPRV_sizeof.l
;Contents:	A copy of the pattern step being played for the moment. For the
;		format, consult PT-Format.txt. Handy for spectrum analyzers. CH
;		equals the requested channel. (0-3)
;
;Field:		PPR_VoiceData+CH*PPRV_sizeof+PPRV_Volume.b
;Contents:	Volume of the current note. CH equals the requested channel.
;
;Field:		PPRM_VBR(PPR_MainData).l
;Contents:	Vectorbaseregister. If you'd like to fetch the VBR, do so and
;		store it here. ProPruner will then use it.
;
;	NOTEPLAYER FUNCTIONS AND MACROS:
;
;Macro:		PPRN_InitReg (Channel)
;Purpose:	Initializes A5 to point to the data area needed by the note-
;		player to perform it's functions.
;
;Macro:		PPRN_KillSound
;Purpose:	Kill all sound on all channels. (Will not have register
;		initialized!)
;
;Macro:		PPRN_KillCh
;Purpose:	Kill all sound on active channel.
;
;Macro:		PPRN_TrigWave (Wavestart, Wavelen)
;Purpose:	Trigs (immediately) the desired wave.
;
;Macro:		PPRN_SetWave (Wavestart, Wavelen)
;Purpose:	Trigs the wave the next time the repeat needs refreshing.
;
;Macro:		PPRN_SetVolume (Volume)
;Purpose:	Sets the volume for the active channel.
;
;Macro:		PPRN_SetRate (Rate)
;Purpose:	Sets the samplerate for the active channel.
;
;Macro:		PPRN_SetMVolL (MVolume)
;Purpose:	Sets mastervolume for left audiochannels. (Will not have
;		register initialized!)
;
;Macro:		PPRN_SetMVolR (MVolume)
;Purpose:	Sets mastervolume for tight audiochannels. (Will not have
;		register initialized!)
;
;Macro:		PPRN_Filter (State)
;Purpose:	Attempts to change the state of a lo-pass filter if such
;		exists on the output device.
;
;Function:	PPRN_MakeSound ()
;Purpose:	Does everything necessary to actually create sound. Will be
;		called about one frame _AFTER_ the relevant macros has been
;		executed.
;
;------------------------------------------------------------------------------

; Set all undefined constants to default values. If you dont't like 'em, feel
; free to change, though you'll have to do it all over for each new version.

	ifnd PPR_Level6
PPR_Level6	=	0			; BOOL
	endc

	ifnd PPR_SampleFile
PPR_SampleFile	=	0			; BOOL
	endc

	ifnd PPR_PreDouble
PPR_PreDouble	=	1			; BOOL
	endc

	ifnd PPR_MasterVol
PPR_MasterVol	=	0			; BOOL
	endc

	ifnd PPR_PauseFuncs
PPR_PauseFuncs	=	0			; BOOL
	endc

	ifnd PPR_WindFuncs
PPR_WindFuncs	=	0			; BOOL
	endc

	ifnd PPR_Delta
PPR_Delta	=	PPR_SampleFile		; BOOL
	endc

	ifnd PPR_Finetune
PPR_Finetune	=	1			; BOOL
	endc

	ifnd PPR_CIA
PPR_CIA		=	0			; BOOL
	endc

	ifnd PPR_68020
PPR_68020	=	0			; BOOL
	endc

	ifnd PPR_PowerPatt
PPR_PowerPatt	=	1			; BOOL
	endc

	ifnd PPR_NotePlayer
PPR_NotePlayer	=	0			; BOOL
	endc

	ifnd PPR_Channels
PPR_Channels	=	4			; Range 0-4
	endc

; Module format definition

	RSRESET	; INSTUMENT INFO
PPRFI_Size	rs.w	1			; Number of words
PPRFI_Finetune	rs.b	1			; Only lower 4 bits
PPRFI_Volume	rs.b	1
PPRFI_Repeat	rs.w	1
PPRFI_RepLen	rs.w	1
PPRFI_sizeof	rs.b	0

	RSRESET	; MODULE STRUCTURE
PPRF_Instr	rs.b	PPRFI_sizeof*31
PPRF_Positions	rs.b	1
PPRF_Data	rs.b	1			; Set to $7f, see PT format
PPRF_PosTab1	rs.b	128
PPRF_PosTab2	rs.b	128
PPRF_PosTab3	rs.b	128
PPRF_PosTab4	rs.b	128
PPRF_Patterns	rs.b	0			; 128 bytes, offsets in notetab
PPRF_NoteTabL	rs.l	1			; Size of notetab
PPRF_NoteTab	rs.l	0			; Table of notes, as PT
PPRF_Samples	rs.w	0			; May be stripped

		; FLAG set in PPRF_Data
PPRF__Doubled	=	$80
;;
	RSRESET	; MAIN VARIABLES
PPRM_SamplePtrs	rs.l	31
PPRM_SongDatPtr	rs.l	1
PPRM_LwtPtr	rs.l	1
PPRM_OldIRQ	rs.l	1	; Only for level 6 mode
PPRM_VBR	rs.l	1	; This will always be around.
PPRM_PatternPos	rs.w	1
PPRM_DMAConTmp	rs.w	1
PPRM_Speed	rs.b	1
PPRM_Counter	rs.b	1
PPRM_SongPos	rs.b	1
PPRM_PBreakPos	rs.b	1
PPRM_PosJumpFl	rs.b	1
PPRM_PBreakFl	rs.b	1
PPRM_LowMask	rs.b	1
PPRM_PtDelTime	rs.b	1
PPRM_PtDelCount	rs.b	1
PPRM_HiPattern	rs.b	1
PPRM_Msg	rs.b	1
PPRM_RestFlag	rs.b	1
PPRM_PrePause	rs.b	1	; Only for pausefuncs
PPRM_pad	rs.b	3
PPRM_sizeof	rs.b	0	; Must be a multiple of 4!

	RSRESET	; VOICE VARIABLES
PPRV_PatternDat	rs.l	1	; Copied from the pattern
PPRV_SamplePtr	rs.l	1	; Pointer to sampledata
PPRV_LoopStart	rs.l	1	; Pointer to start of loop
PPRV_FunkPtr	rs.l	1	; Sample pointer for funkrepeat
PPRV_PlaySize	rs.w	1	; Number of words that are actually played.
PPRV_RepLen	rs.w	1	; Repeat length in words
PPRV_CurrPer	rs.w	1	; Period currently playing
PPRV_DMAMask	rs.w	1	; DMA Mask for channel
PPRV_TPDest	rs.w	1	; Toneportamento destination
PPRV_MasterVol	rs.w	1
PPRV_TPDir	rs.b	1	; Toneportamento direction
PPRV_TPPara	rs.b	1	; Current toneportamento parameter
PPRV_Finetune	rs.b	1	; Finetune and some flags
PPRV_Volume	rs.b	1	; Volume for channel
PPRV_VibPara	rs.b	1	; Current vibrato parameter
PPRV_VibCount	rs.b	1	; Vibrato count
PPRV_TremPara	rs.b	1	; Current tremolo parameter
PPRV_TremCount	rs.b	1	; Vibrato count
PPRV_Control1	rs.b	1	; Tremolo control / vibrato control
PPRV_Control2	rs.b	1	; Funkrepeat speed / glissando control
PPRV_ArpCount	rs.b	1	; Arpeggio count
PPRV_SOffsPara	rs.b	1	; Sample offset parameter
PPRV_PLoopPos	rs.b	1	; Pattern loop position
PPRV_PLoopCount	rs.b	1	; Pattern loop count
PPRV_FunkDuh	rs.b	1	; Some counter (waitcount for next funk?) for funkrepeat
PPRV_Pad	rs.b	3
PPRV_CurrNote	rs.b	1	; Notenumber currently playing (Only POWERPATT)
PPRV_pad	rs.b	1
PPRV_sizeof	rs.b	0	; Must be a multiple of 4!

;------------------------------------------------------------------------------
;==				INIT					     ==
;------------------------------------------------------------------------------

PPR_Init	lea.l	PPR_MainData(pc),a4
		move.l	a0,PPRM_SongDatPtr(a4)

	ifne PPR_SampleFile
		move.l	a1,a2
		lea.l	PPRM_SamplePtrs(a4),a3
		moveq.l	#31-1,d0
.Loop		move.l	(a2)+,d1
		add.l	a1,d1
		move.l	d1,(a3)+
		dbf	d0,.Loop

		ifne PPR_Delta
			move.l	124(a1),d0
			beq.s	.NoDelta

			clr.l	124(a1)		; Don't double-delta if called
						; several times.
			lea.l	128(a1),a1
			moveq.l	#0,d1
.DLoop			add.b	(a1),d1
			move.b	d1,(a1)+
			subq.l	#1,d0
			bne.s	.DLoop
.NoDelta
		endc
	endc

		lea.l	250(a0),a2
		move.w	#511,d0
		moveq.l	#0,d1
.FindPatt	move.l	d1,d2
		subq.w	#1,d0
.FindPatt2	move.b	(a2)+,d1
		cmp.w	d2,d1
		bgt.s	.FindPatt
		dbra	d0,.FindPatt2
		move.b	d2,PPRM_HiPattern(a4)
		addq	#1,d2			; Patterns stored

	ifne PPR_PreDouble
		move.b	PPRF_Data(a0),d3
		and.b	#PPRF__Doubled,d3
		bne.s	.WasDoubled

		move.l	d2,d3
		lsl.l	#6,d3			; *64 = bytes of patterns
		subq.l	#1,d3

		move.l	a0,a1
		lea.l	PPRF_Patterns(a1),a1

.DoubleLoop	move.w	(a1),d4
		add.w	d4,d4
		add.w	d4,d4
		move.w	d4,(a1)+
		dbf	d3,.DoubleLoop

		or.b	#PPRF__Doubled,PPRF_Data(a0)
.WasDoubled
	endc

;Pattern conversion

	ifne PPR_PowerPatt
		lea.l	PPRF_Patterns(a0),a1
		moveq.l	#0,d0
		move.b	PPRM_HiPattern(a4),d0
		addq.l	#1,d0
		lsl.l	#7,d0		; * 128
		add.l	d0,a1
		move.l	(a1)+,d7
		lsr.l	#2,d7
		subq.l	#1,d7

;D0- Temporary		A0- Modulepointer [!!!]
;D1- Temporary		A1- Notepointer
;D2- Temporary		A2- Periodtable
;D3-			A3- Temporary tab ptr
;D4- Loopcount		A4-
;D5- Sourcelong		A5-
;D6- Destlong		A6-
;D7- Loopcount		A7- [NA]

		lea.l	PPR_periodtable(pc),a2
.PowerLoop	move.l	(a1),d5			; Read source

		move.l	d5,d0
		and.l	#$fff,d0
		beq.s	.Skip
		nop
.Skip
		move.l	d5,d0			; Period
		swap	d0
		and.l	#$fff,d0
		tst.l	d0
		beq.s	.NoNote

.WasNote	move.l	a2,a3
		moveq.l	#36-1,d4
		moveq.l	#2,d1			; Start at offset 2!!!
.PerLoop	move.w	(a3)+,d2
		cmp.w	d0,d2
		beq.s	.FoundPer
		addq.l	#2,d1
		dbf	d4,.PerLoop
.NoNote		moveq.l	#0,d1
.FoundPer	move.b	d1,d6
		lsl.w	#8,d6

		move.l	d5,d0			; Instrument number
		and.l	#$f0000000,d0
		rol.l	#8,d0
		move.l	d5,d1
		and.l	#$0000f000,d1
		lsl.l	#4,d1
		swap	d1
		or.w	d0,d1
		move.b	d1,d6
		lsl.l	#8,d6
		lsl.l	#8,d6

		and.l	#$0fff,d5		; Effect command
		move.w	d5,d6
		move.l	d6,(a1)+

		dbf	d7,.PowerLoop
	endc

		moveq.l	#0,d2
		move.b	PPRM_HiPattern(a4),d2
		addq	#1,d2			; Patterns stored
		move.w	d2,d3
		lsl.l	#7,d3
		add.l	#766,d3
		add.l	PPRM_SongDatPtr(a4),d3
		move.l	d3,PPRM_LwtPtr(a4)

	ifeq PPR_SampleFile
		lea.l	PPRM_SamplePtrs(a4),a1
		moveq.l	#0,d2
		move.b	PPRM_HiPattern(a4),d2
		addq.l	#1,d2
		lsl.l	#7,d2
		add.l	#762,d2
		add.l	(a0,d2.l),d2
		add.l	PPRM_SongDatPtr(a4),d2
		addq.l	#4,d2
		move.l	d2,a2
		moveq.l	#31-1,d0
.SampleLoop	move.l	a2,(a1)+
		moveq.l	#0,d1
		move.w	(a0),d1
		add.l	d1,d1
		add.l	d1,a2
		lea.l	8(a0),a0
		dbra	d0,.SampleLoop
	endc

		or.b	#2,$bfe001		; Clear filter as default

		bsr.s	PPR_VoiceClear

	ifne PPR_CIA
		move.b	#125,d0
		bsr.s	CIA_SetBPM
	endc

	ifeq PPR_NotePlayer
		lea.l	PPR_VoiceData(pc),a6
		move.w	#1,(PPRV_sizeof*0)+PPRV_DMAMask(a6)
		move.w	#2,(PPRV_sizeof*1)+PPRV_DMAMask(a6)
		move.w	#4,(PPRV_sizeof*2)+PPRV_DMAMask(a6)
		move.w	#8,(PPRV_sizeof*3)+PPRV_DMAMask(a6)
	endc

		clr.b	PPRM_RestFlag(a4)
		clr.b	PPRM_SongPos(a4)
		clr.w	PPRM_PatternPos(a4)

	ifne PPR_MasterVol
		ifeq PPR_NotePlayer
			lea.l	PPR_VoiceData(pc),a6
			move.w	#64,(PPRV_sizeof*0)+PPRV_MasterVol(a6)
			move.w	#64,(PPRV_sizeof*1)+PPRV_MasterVol(a6)
			move.w	#64,(PPRV_sizeof*2)+PPRV_MasterVol(a6)
			move.w	#64,(PPRV_sizeof*3)+PPRV_MasterVol(a6)
		else
			PPRN_SetMVolL 64
			PPRN_SetMVolR 64
		endc
	endc

		move.b	#6,PPRM_Counter(a4)
		move.b	#6,PPRM_Speed(a4)	; Start playing

		rts

;------------------------------------------------------------------------------
;==				END					     ==
;------------------------------------------------------------------------------

PPR_End		lea.l	PPR_MainData(pc),a4
		move.b	#0,PPRM_Speed(a4)	; Stop playing

PPR_VoiceClear
	ifne PPR_NotePlayer
		ifge PPR_Channels-1
			PPRN_InitReg 0
			PPRN_SetVolume #0
		endc

		ifge PPR_Channels-2
			PPRN_InitReg 1
			PPRN_SetVolume #0
		endc

		ifge PPR_Channels-3
			PPRN_InitReg 2
			PPRN_SetVolume #0
		endc

		ifge PPR_Channels-4
			PPRN_InitReg 3
			PPRN_SetVolume #0
		endc
	else
		lea.l	$dff096,a0
		moveq.l	#0,d0
	ifge PPR_Channels-1
		move.w	#0,$12(a0)
		and.w	#$0001,d0
	endc
	ifge PPR_Channels-2
		move.w	#0,$22(a0)
		and.w	#$0002,d0
	endc
	ifge PPR_Channels-3
		move.w	#0,$32(a0)
		and.w	#$0004,d0
	endc
	ifge PPR_Channels-4
		move.w	#0,$42(a0)
		and.w	#$0008,d0
	endc
		move.w	d0,(a0)
	endc
		rts

;------------------------------------------------------------------------------
;==				SETMASTERVOL				     ==
;------------------------------------------------------------------------------
	ifne PPR_MasterVol
PPR_SetMasterVol
		ifne PPR_NotePlayer
			PPRN_SetMVolL d0
			PPRN_SetMVolR d1
		else
			lea.l	PPR_VoiceData(pc),a0
			move.w	d0,(PPRV_sizeof*0)+PPRV_MasterVol(a0)
			move.w	d1,(PPRV_sizeof*1)+PPRV_MasterVol(a0)
			move.w	d1,(PPRV_sizeof*2)+PPRV_MasterVol(a0)
			move.w	d0,(PPRV_sizeof*3)+PPRV_MasterVol(a0)

			moveq.l	#0,d0

		ifge PPR_Channels-1
			move.b	PPRV_Volume(a0),d0	; Voice 1
			mulu.w	PPRV_MasterVol(a0),d0
			lsr.w	#6,d0
			move.w	d0,$dff0a8
			lea.l	PPRV_sizeof(a0),a0
		endc

		ifge PPR_Channels-2
			move.b	PPRV_Volume(a0),d0	; Voice 2
			mulu.w	PPRV_MasterVol(a0),d0
			lsr.w	#6,d0
			move.w	d0,$dff0b8
			lea.l	PPRV_sizeof(a0),a0
		endc

		ifge PPR_Channels-3
			move.b	PPRV_Volume(a0),d0	; Voice 3
			mulu.w	PPRV_MasterVol(a0),d0
			lsr.w	#6,d0
			move.w	d0,$dff0c8
			lea.l	PPRV_sizeof(a0),a0
		endc

		ifge PPR_Channels-4
			move.b	PPRV_Volume(a0),d0	; Voice 4
			mulu.w	PPRV_MasterVol(a0),d0
			lsr.w	#6,d0
			move.w	d0,$dff0d8
			lea.l	PPRV_sizeof(a0),a0
		endc

			rts

PPR_CALCVOL	macro	;(Register)		; Inits audio volume while
		moveq.l	#0,\1			;  scaling it using the master-
		move.b	PPRV_Volume(a6),\1	;  volume. Free feature trashes
		mulu.w	PPRV_MasterVol(a6),\1	;  your favourite data-
		lsr.w	#6,\1			;  register!!! 8)
		move.b	\1,9(a5)
		endm

PPR_CALCVOL2	macro	;(Register)		; Scaling register using the
		mulu.w	PPRV_MasterVol(a6),\1	;  mastervolume.
		lsr.w	#6,\1
		endm

		endc
	endc

;------------------------------------------------------------------------------
;==				PAUSE					     ==
;------------------------------------------------------------------------------
	ifne PPR_PauseFuncs
PPR_Pause	lea.l	PPR_MainData(pc),a4
		move.b	PPRM_Speed(a4),PPRM_PrePause(a4)
		bra.s	PPR_End

PPR_Continue	lea.l	PPR_MainData(pc),a4

	ifne PPR_NotePlayer
		lea.l	PPR_VoiceData(pc),a0
		moveq.l	#0,d0

	ifge PPR_Channels-1
		PPRN_InitReg 0
		move.b	PPRV_Volume(a0),d0
		PPRN_SetVolume d0
	endc

	ifge PPR_Channels-2
		PPRN_InitReg 1
		move.b	PPRV_Volume(a0),d0
		PPRN_SetVolume d0
	endc

	ifge PPR_Channels-3
		PPRN_InitReg 2
		move.b	PPRV_Volume(a0),d0
		PPRN_SetVolume d0
	endc

	ifge PPR_Channels-4
		PPRN_InitReg 3
		move.b	PPRV_Volume(a0),d0
		PPRN_SetVolume d0
	endc

	else
			lea.l	PPR_VoiceData(pc),a6
			lea.l	$dff0a0,a1
			moveq.l	#0,d0

	ifge PPR_Channels-1
			move.b	PPRV_Volume(a6),d0
		ifne PPR_MasterVol
			PPR_CALCVOL2	d0
		endc
			move.w	d0,$08(a1)
			lea.l	PPRV_sizeof(a6),a6
	endc

	ifge PPR_Channels-2
			move.b	PPRV_Volume(a6),d0
		ifne PPR_MasterVol
			PPR_CALCVOL2	d0
		endc
			move.w	d0,$18(a1)
			lea.l	PPRV_sizeof(a6),a6
	endc

	ifge PPR_Channels-3
			move.b	PPRV_Volume(a6),d0
		ifne PPR_MasterVol
			PPR_CALCVOL2	d0
		endc
			move.w	d0,$28(a1)
			lea.l	PPRV_sizeof(a6),a6
	endc

	ifge PPR_Channels-4
			move.b	PPRV_Volume(a6),d0
		ifne PPR_MasterVol
			PPR_CALCVOL2	d0
		endc
			move.w	d0,$38(a1)
	endc
	endc

		move.b	PPRM_PrePause(a4),PPRM_Speed(a4)

		rts
	endc

;------------------------------------------------------------------------------
;==				FORWARD/REWIND				     ==
;------------------------------------------------------------------------------
	ifne PPR_WindFuncs
PPR_Forward	lea.l	PPR_MainData(pc),a4

		bsr.w	PPR_VoiceClear

		move.w	#256,PPRM_PatternPos(a4)
		move.b	PPRM_Speed(a4),PPRM_Counter(a4)

		moveq.l	#0,d0
		rts

PPR_Rewind	lea.l	PPR_MainData(pc),a4
		bsr.w	PPR_VoiceClear

		move.b	PPRM_SongPos(a4),d0
		tst.b	d0
		bne.s	.not0

		move.l	PPRM_SongDatPtr(a4),a0
		move.b	PPRF_Positions(a0),PPRM_SongPos(a4)
		sub.b	#2,PPRM_SongPos(a4)
		bra.s	.ok

.not0		cmp.b	#1,d0
		bne.s	.not1

		move.l	PPRM_SongDatPtr(a4),a0
		move.b	PPRF_Positions(a0),PPRM_SongPos(a4)
		sub.b	#1,PPRM_SongPos(a4)
		bra.s	.ok

.not1		sub.b	#2,PPRM_SongPos(a4)
.ok		move.w	#256,PPRM_PatternPos(a4)
		move.b	PPRM_Speed(a4),PPRM_Counter(a4)

		moveq.l	#0,d0
		rts
	endc

;------------------------------------------------------------------------------
;==				MUSIC					     ==
;;-----------------------------------------------------------------------------
;A0 - Pattern pointer. (...?)
;A1 -
;A2 -
;A3 -
;A4 - Pointer to main-variables
;A5 - Pointer to audio-hardware
;A6 - Pointer to voice-variables
;------------------------------------------------------------------------------
PPR_Music
	ifne PPR_NotePlayer
		bsr.w	PPRN_MakeSound
	endc

		lea.l	PPR_MainData(pc),a4
		addq.b	#1,PPRM_Counter(a4)
		move.b	PPRM_Speed(a4),d1	; Module halted?
		beq.w	PPR_return
		move.b	PPRM_Counter(a4),d0
		cmp.b	d1,d0
		blo.w	PPR_nonewnote
		clr.b	PPRM_Counter(a4)
		tst.b	PPRM_PtDelCount(a4)	; Pattern delayed?
		beq.w	PPR_getnewnote

		pea.l	PPR_dskip(pc)
		bra.w	PPR_nonewallchannels

PPR_WAIT	macro
		moveq.l	#\1-1,d0
		bsr.w	PPR_WaitLines
		endm

	ifeq PPR_Level6
PPR_WaitLines	lea.l	$dff006+1,a1
		move.b	(a1),d7
		and.b	#$f0,d7
.loop1		move.b	(a1),d6
		and.b	#$f0,d6
		cmp.b	d7,d6
		beq.s	.loop1
.loop2		move.b	(a1),d6
		and.b	#$f0,d6
		cmp.b	d7,d6
		bne.s	.loop2
		dbf	d0,.loop1
		rts
	endc

PPR_PERNOP	macro
	ifne PPR_NotePlayer
		PPRN_SetRate PPRV_CurrPer(a6)
	else
		move.w	PPRV_CurrPer(a6),6(a5)
	endc
		endm

PPR_nonewnote	pea.l	PPR_nonewposyet(pc)
		bra.w	PPR_nonewallchannels

PPR_nonewallchannels
		; Updates effects, and that's basically it.

	ifeq PPR_NotePlayer
			lea.l	$dff090,a5
			lea.l	PPR_VoiceData-PPRV_sizeof(pc),a6

		ifge PPR_Channels-1
			ifeq PPR_Channels-1
				bra.w	PPR_ChkEfxEvery
			else
				bsr.w	PPR_ChkEfxEvery
			endc
		endc

		ifge PPR_Channels-2
			ifeq PPR_Channels-2
				bra.w	PPR_ChkEfxEvery
			else
				bsr.w	PPR_ChkEfxEvery
			endc
		endc

		ifge PPR_Channels-3
			ifeq PPR_Channels-3
				bra.w	PPR_ChkEfxEvery
			else
				bsr.w	PPR_ChkEfxEvery
			endc
		endc

		ifge PPR_Channels-4
			ifeq PPR_Channels-4
				bra.w	PPR_ChkEfxEvery
			else
				bsr.w	PPR_ChkEfxEvery
			endc
		endc
	else
			lea.l	PPR_VoiceData-PPRV_sizeof(pc),a6

		ifge PPR_Channels-1
			PPRN_InitReg 0
			ifeq PPR_Channels-1
				bra.w	PPR_ChkEfxEvery
			else
				bsr.w	PPR_ChkEfxEvery
			endc
		endc

		ifge PPR_Channels-2
			PPRN_InitReg 1
			ifeq PPR_Channels-2
				bra.w	PPR_ChkEfxEvery
			else
				bsr.w	PPR_ChkEfxEvery
			endc
		endc

		ifge PPR_Channels-3
			PPRN_InitReg 2
			ifeq PPR_Channels-3
				bra.w	PPR_ChkEfxEvery
			else
				bsr.w	PPR_ChkEfxEvery
			endc
		endc

		ifge PPR_Channels-4
			PPRN_InitReg 3
			ifeq PPR_Channels-4
				bra.w	PPR_ChkEfxEvery
			else
				bsr.w	PPR_ChkEfxEvery
			endc
		endc
	endc

		rts

PPR_getnewnote	; Gets new notes for all channels.

		move.l	PPRM_SongDatPtr(a4),a0
		move.l	a0,a3
		lea.l	122(a0),a2	;pattpo
		lea.l	762(a0),a0	;patterndata
		clr.w	PPRM_DMAConTmp(a4)

		lea.l	PPR_VoiceData-PPRV_sizeof(pc),a6

	ifeq PPR_NotePlayer
		lea.l	$dff090,a5

		ifgt PPR_Channels-0
			bsr.s	PPR_dovoice
		endc

		ifgt PPR_Channels-1
			bsr.s	PPR_dovoice
		endc

		ifgt PPR_Channels-2
			bsr.s	PPR_dovoice
		endc

		ifgt PPR_Channels-3
			bsr.s	PPR_dovoice
		endc
	else
		ifgt PPR_Channels-0
			PPRN_InitReg 0
			bsr.s	PPR_dovoice
		endc

		ifgt PPR_Channels-1
			PPRN_InitReg 1
			bsr.s	PPR_dovoice
		endc

		ifgt PPR_Channels-2
			PPRN_InitReg 2
			bsr.s	PPR_dovoice
		endc

		ifgt PPR_Channels-3
			PPRN_InitReg 3
			bsr.s	PPR_dovoice
		endc
	endc

		bra.w	PPR_setdma

PPR_dovoice	; Fetches next step in pattern and processes it.

		moveq.l	#0,d0
		moveq.l	#0,d1
		move.b	PPRM_SongPos(a4),d0
		lea.l	128(a2),a2
		move.b	(a2,d0.w),d1
		move.w	PPRM_PatternPos(a4),d2
		lsl	#7,d1			; *128
		lsr.w	#1,d2
		add.w	d2,d1

	ifeq PPR_NotePlayer
		lea.l	$10(a5),a5		; Next audio register
	endc

		lea.l	PPRV_sizeof(a6),a6

		tst.l	PPRV_PatternDat(a6)
		bne.w	PPR_plvskip
		PPR_PERNOP

PPR_plvskip	move.w	(a0,d1.w),d1

		move.l	PPRM_LwtPtr(a4),a1

		; Fetches patterndata
	ifeq PPR_PreDouble
		ifeq PPR_68020
			add.w	d1,d1
			add.w	d1,d1
			move.l	(a1,d1.w),PPRV_PatternDat(a6)
		else
			move.l	(0,a1,d1.w*4),PPRV_PatternDat(a6)
		endc
	else
		move.l	(a1,d1.w),PPRV_PatternDat(a6); The step-info (as PT!)
	endc

	ifeq PPR_PowerPatt
		move.b	PPRV_PatternDat+2(a6),d2
		and.l	#$f0,d2
		lsr.b	#4,d2
		move.b	PPRV_PatternDat(a6),d0
		and.b	#$f0,d0
		or.b	d0,d2
	else
		moveq.l	#0,d2
		move.b	PPRV_PatternDat+1(a6),d2; Instrument number
	endc

		beq.b	PPR_setregs		; Retrig instrument?

		moveq.l	#0,d3
		lea.l	PPRM_SamplePtrs(a4),a1
		subq	#1,d2
		move	d2,d4

	ifne PPR_68020
		move.l	(0,a1,d2.l*4),(PPRV_SamplePtr,a6); Samplepointer
	else
		add	d2,d2
		add	d2,d2
		move.l	(a1,d2.l),PPRV_SamplePtr(a6)
	endc

		lsl.w	#3,d4
		move.w	PPRFI_Size(a3,d4.w),PPRV_PlaySize(a6)
		move.w	PPRFI_Finetune(a3,d4.w),PPRV_Finetune(a6)
		move.l	PPRV_SamplePtr(a6),d2		; get start
		move.w	PPRFI_Repeat(a3,d4.w),d3	; get repeat
		beq.s	PPR_noloop
		move.w	d3,d0				; get repeat
		add.w	d3,d3
		add.l	d3,d2				; add repeat
		add.w	PPRFI_RepLen(a3,d4.w),d0	; add replen
		move.w	d0,PPRV_PlaySize(a6)

PPR_noloop	move.l	d2,PPRV_LoopStart(a6)
		move.l	d2,PPRV_FunkPtr(a6)
		move.w	PPRFI_RepLen(a3,d4.w),PPRV_RepLen(a6)	; save replen

	ifeq PPR_NotePlayer
		ifne PPR_MasterVol
			PPR_CALCVOL	d0
		else
			move.b	PPRV_Volume(a6),9(a5)	; set volume
		endc
	else
		PPRN_SetVolume PPRV_Volume(a6)
	endc

PPR_setregs
	ifeq PPR_PowerPatt
		move.w	PPRV_PatternDat(a6),d0
		and.w	#$0fff,d0
	else
		move.b	PPRV_PatternDat(a6),d0
		and.w	#$00ff,d0
	endc

		beq.w	PPR_ChkEfxSometime	; if no note

		move.w	PPRV_PatternDat+2(a6),d0; Effectcommands to execute
						; before setting period for
						; new notes.

	ifne PPR_Finetune
		and.w	#$0ff0,d0
		cmp.w	#$0e50,d0
		beq.s	PPR_dosetfinetune
	endc

		and.w	#$0f00,d0
		cmp.w	#$0300,d0		; toneportamento
		beq.s	PPR_chktoneporta
		cmp.w	#$0500,d0
		beq.s	PPR_chktoneporta
		cmp.w	#$0900,d0		; sample offset
		bne.s	PPR_setperiod

		pea.l	PPR_setperiod(pc)
		bra.w	PPR_ChkEfxSometime

PPR_chktoneporta

		pea.l	PPR_ChkEfxSometime(pc)
		bra.w	PPR_settoneporta

	ifne PPR_Finetune
PPR_dosetfinetune
		bsr.w	PPR_setfinetune
	endc

PPR_setperiod	; Set period for channel.

;		movem.l	d1/a1,-(sp)

	ifeq PPR_PowerPatt
		move.w	PPRV_PatternDat(a6),d1
		and.w	#$0fff,d1

		ifeq PPR_Finetune
			move.w	d1,PPRV_CurrPer(a6)
		else

PPR_setperiod2
			lea.l	PPR_periodtable(pc),a1
			moveq.l	#36,d7
PPR_ftuloop		cmp.w	(a1)+,d1
			bhs.s	PPR_ftufound
			dbra	d7,PPR_ftuloop
PPR_ftufound
			moveq.l	#0,d1
			move.b	PPRV_Finetune(a6),d1
			lsl.l	#7,d1		; *64*2

			move.w	-2(a1,d1.w),PPRV_CurrPer(a6)
		endc
	else	; If powerpatterns were enabled...
		move.b	PPRV_PatternDat(a6),d1
		and.l	#$00ff,d1

		ifeq PPR_Finetune
			lea.l	PPR_periodtable-2(pc),a1
			move.w	(a1,d1.w),PPRV_CurrPer(a6)
			move.b	PPRV_PatternDat(a6),PPRV_CurrNote(a6)
		else

PPR_setperiod2		move.b	PPRV_PatternDat(a6),PPRV_CurrNote(a6)

			lea.l	PPR_periodtable-2(pc),a1
PPR_ftu			moveq.l	#0,d0
			move.b	PPRV_Finetune(a6),d0	; Finetune value
			lsl.l	#7,d0		; *64*2
			add.l	d0,a1

			move.w	(a1,d1.w),PPRV_CurrPer(a6)
		endc
	endc

;		movem.l	(sp)+,d1/a1

		move.w	PPRV_PatternDat+2(a6),d0; Effectcommands to execute
		and.w	#$0ff0,d0		; after periodsetting for new
		cmp.w	#$0ed0,d0		; notes. (notedelay)
		beq.w	PPR_ChkEfxSometime

	ifeq PPR_NotePlayer
		move.w	PPRV_DMAMask(a6),$dff096; Disable DMA for this channel
		PPR_WAIT 1
	endc

		btst	#2,PPRV_Control1(a6)
		bne.s	PPR_vibnoc

		clr.b	PPRV_VibCount(a6)

PPR_vibnoc	btst	#6,PPRV_Control1(a6)
		bne.s	PPR_trenoc
		clr.b	PPRV_TremCount(a6)

PPR_trenoc
	ifeq PPR_NotePlayer
		move.l	PPRV_SamplePtr(a6),(a5)		; set start
		move.w	PPRV_PlaySize(a6),4(a5)		; set length
		move.w	PPRV_CurrPer(a6),6(a5)		; set period
		move.w	PPRV_DMAMask(a6),d0
		or.w	d0,PPRM_DMAConTmp(a4)		; Order trig of note
	else
		PPRN_TrigWave PPRV_SamplePtr(a6),PPRV_PlaySize(a6)
		PPRN_SetRate PPRV_CurrPer(a6)
	endc
		bra.w	PPR_ChkEfxSometime

PPR_setdma	; Trig new samples with respect to DMA cycles.

	ifeq PPR_NotePlayer
			or.w	#$8000,PPRM_DMAConTmp(a4)

		ifne PPR_Level6 ;then
			lea.l	$bfd000,a3
			move.l	PPRM_VBR(a4),a1
			move.b	#$7f,$d00(a3)
			move.w	#$2000,$dff09c
			move.w	#$a000,$dff09a
			move.l	$78(a1),PPRM_OldIRQ(a4)
			lea.l	PPR_irq1(pc),a2
			move.l	a2,$78(a1)
			moveq.l	#0,d0
			move.b	d0,$e00(a3)
			move.b	#$a8,$400(a3)
			move.b	d0,$500(a3)
			move.b	#$11,$e00(a3)
			move.b	#$81,$d00(a3)
			bra.w	PPR_dskip
		else
			PPR_WAIT 4		; Wait for auddat to be fetched
		endc

		ifne PPR_Level6 ;then
PPR_irq1		movem.l	a0/a1/a4,-(sp)
			lea.l	PPR_MainData(pc),a4
			tst.b	$bfdd00
			move.w	PPRM_DMAConTmp(a4),$dff096; Reset Paula
			move.w	#$2000,$dff09c

			move.l	PPRM_VBR(a4),a0
			lea.l	PPR_irq2(pc),a1
			move.l	a1,$78(a0)
			movem.l	(sp)+,a0/a1/a4

			rte

		else
		move.w	PPRM_DMAConTmp(a4),$dff096; Reset Paula
			PPR_WAIT 1		; Wait for DMA to come on
		endc

		ifne PPR_Level6 ;then
PPR_irq2		tst.b	$bfdd00
			movem.l	a4-a6,-(a7)
			lea.l	PPR_MainData(pc),a4
		endc

		lea.l	$dff0a0,a5
		lea.l	PPR_VoiceData(pc),a6

	ifge PPR_Channels-1
		move.l	(PPRV_sizeof*0)+PPRV_LoopStart(a6),$00(a5)
		move.w	(PPRV_sizeof*0)+PPRV_RepLen(a6),$04(a5)
	endc
	ifge PPR_Channels-2
		move.l	(PPRV_sizeof*1)+PPRV_LoopStart(a6),$10(a5)
		move.w	(PPRV_sizeof*1)+PPRV_RepLen(a6),$14(a5)
	endc
	ifge PPR_Channels-3
		move.l	(PPRV_sizeof*2)+PPRV_LoopStart(a6),$20(a5)
		move.w	(PPRV_sizeof*2)+PPRV_RepLen(a6),$24(a5)
	endc
	ifge PPR_Channels-4
		move.l	(PPRV_sizeof*3)+PPRV_LoopStart(a6),$30(a5)
		move.w	(PPRV_sizeof*3)+PPRV_RepLen(a6),$34(a5)
	endc

		ifne PPR_Level6 ;then
			move.b	#0,$bfde00
			move.b	#$7f,$bfdd00
			move.l	PPRM_VBR(a4),a5
			move.l	PPRM_OldIRQ(a4),$78(a5)
			move.w	#$2000,$dff09c
			movem.l	(a7)+,a4-a6
			rte
		endc
	else
	ifge PPR_Channels-1
		lea.l	PPR_VoiceData(pc),a6
		PPRN_InitReg 0
		PPRN_SetWave PPRV_LoopStart(a6),PPRV_RepLen(a6)
	endc
	ifge PPR_Channels-2
		PPRN_InitReg 1
		PPRN_SetWave PPRV_LoopStart(a6),PPRV_RepLen(a6)
	endc
	ifge PPR_Channels-3
		PPRN_InitReg 2
		PPRN_SetWave PPRV_LoopStart(a6),PPRV_RepLen(a6)
	endc
	ifge PPR_Channels-4
		PPRN_InitReg 3
		PPRN_SetWave PPRV_LoopStart(a6),PPRV_RepLen(a6)
	endc
	endc

PPR_dskip	; Do things concerning the next patternstep.

		addq.w	#4,PPRM_PatternPos(a4)
		move.b	PPRM_PtDelTime(a4),d0
		beq.s	PPR_dskc		; No pending delay...

		move.b	d0,PPRM_PtDelCount(a4)
		clr.b	PPRM_PtDelTime(a4)

PPR_dskc	tst.b	PPRM_PtDelCount(a4)	; No delaycount...
		beq.s	PPR_dska

		subq.b	#1,PPRM_PtDelCount(a4)	; Sub counter...
		beq.s	PPR_dska		; Release pattern...

		subq.w	#4,PPRM_PatternPos(a4)

PPR_dska	tst.b	PPRM_PBreakFl(a4)
		beq.s	PPR_nnpysk

		sf	PPRM_PBreakFl(a4)
		moveq.l	#0,d0
		move.b	PPRM_PBreakPos(a4),d0
		clr.b	PPRM_PBreakPos(a4)
		add.w	d0,d0
		add.w	d0,d0
		move.w	d0,PPRM_PatternPos(a4)

PPR_nnpysk	cmp.w	#256,PPRM_PatternPos(a4)
		blo.s	PPR_nonewposyet

PPR_nextposition
		; Fetches the next position.

		moveq.l	#0,d0
		move.b	PPRM_PBreakPos(a4),d0
		add.w	d0,d0
		add.w	d0,d0
		move.w	d0,PPRM_PatternPos(a4)
		clr.b	PPRM_PBreakPos(a4)
		clr.b	PPRM_PosJumpFl(a4)
		addq.b	#1,PPRM_SongPos(a4)
		and.b	#$7f,PPRM_SongPos(a4)
		move.b	PPRM_SongPos(a4),d1
		move.l	PPRM_SongDatPtr(a4),a0
		cmp.b	PPRF_Positions(a0),d1
		blo.s	PPR_nonewposyet
		clr.b	PPRM_SongPos(a4)
		st.b	PPRM_RestFlag(a4)

PPR_nonewposyet	tst.b	PPRM_PosJumpFl(a4)
		bne.s	PPR_nextposition

PPR_return	rts

;------------------------------------------------------------------------------
;Effectcommands which needs to be called every frame.
;------------------------------------------------------------------------------

PPR_ChkEfxEvery
	ifeq PPR_NotePlayer
		lea.l	$10(a5),a5
	endc

		lea.l	PPRV_sizeof(a6),a6

		tst.b	PPRM_PtDelCount(a4)
		beq.s	.NoDelay

		tst.b	PPRM_Counter(a4)
		bne.s	.NoDelay

		; This has to be done in order to manually take care of the
		; steps when the pattern is delayed.

		bsr.s	PPR_ChkEfxSometime

.NoDelay	bsr.w	PPR_updatefunk

		move.w	PPRV_PatternDat+2(a6),d0
		bne.w	.WasEffect

		PPR_PERNOP
		rts

.WasEffect	lsr.w	#8-2,d0			; Get cmd-byte and *4.
		and.w	#$f<<2,d0
		lea.l	PPR_EfxEvery(pc),a1
		add.l	(a1,d0.w),a1
		jsr	(a1)

		rts

PPR_EfxEvery	dc.l	PPR_arpeggio-PPR_EfxEvery			; 0
		dc.l	PPR_portaup-PPR_EfxEvery			; 1
		dc.l	PPR_portadown-PPR_EfxEvery			; 2
		dc.l	PPR_toneportamento-PPR_EfxEvery			; 3
		dc.l	PPR_vibrato-PPR_EfxEvery			; 4
		dc.l	PPR_toneplusvolslide-PPR_EfxEvery		; 5
		dc.l	PPR_vibratoplusvolslide-PPR_EfxEvery		; 6
		dc.l	PPR_tremolo-PPR_EfxEvery			; 7
		dc.l	PPR_return-PPR_EfxEvery				; 8
		dc.l	PPR_return-PPR_EfxEvery				; 9
		dc.l	PPR_volumeslide-PPR_EfxEvery			; A
		dc.l	PPR_return-PPR_EfxEvery				; B
		dc.l	PPR_return-PPR_EfxEvery				; C
		dc.l	PPR_return-PPR_EfxEvery				; D
		dc.l	PPR_ChkExtEvery-PPR_EfxEvery			; Ex
		dc.l	PPR_return-PPR_EfxEvery				; F

;------------------------------------------------------------------------------
;Effectcommands which needs to be called every time a new note is started.
;------------------------------------------------------------------------------

PPR_ChkEfxSometime
		; Effectcommands to execute only the first frame...

		bsr.w	PPR_updatefunk		; Why here?!?

		move.b	PPRV_PatternDat+2(a6),d0
		and.w	#$f,d0
		lsl.w	#2,d0			; *4
		lea.l	PPR_EfxSometime(pc),a1
		add.l	(a1,d0.w),a1
		jsr	(a1)

		PPR_PERNOP			; Necessary?
		rts

PPR_EfxSometime	dc.l	PPR_arpinit-PPR_EfxSometime			; 0
		dc.l	PPR_return-PPR_EfxSometime			; 1
		dc.l	PPR_return-PPR_EfxSometime			; 2
		dc.l	PPR_return-PPR_EfxSometime			; 3
		dc.l	PPR_return-PPR_EfxSometime			; 4
		dc.l	PPR_return-PPR_EfxSometime			; 5
		dc.l	PPR_return-PPR_EfxSometime			; 6
		dc.l	PPR_return-PPR_EfxSometime			; 7
		dc.l	PPR_syncval-PPR_EfxSometime			; 8
		dc.l	PPR_sampleoffset-PPR_EfxSometime		; 9
		dc.l	PPR_return-PPR_EfxSometime			; A
		dc.l	PPR_positionjump-PPR_EfxSometime		; B
		dc.l	PPR_volumechange-PPR_EfxSometime		; C
		dc.l	PPR_patternbreak-PPR_EfxSometime		; D
		dc.l	PPR_ChkExtSometime-PPR_EfxSometime		; Ex
		dc.l	PPR_setspeed-PPR_EfxSometime			; F

;------------------------------------------------------------------------------
;Extended effectcommands called each frame.
;------------------------------------------------------------------------------

PPR_ChkExtEvery
		; Extended effectcommands called each frame...

		move.b	PPRV_PatternDat+3(a6),d0
		lsr.w	#4-2,d0			; *4
		and.w	#$f<<2,d0
		lea.l	PPR_ExtEvery(pc),a1
		add.l	(a1,d0.w),a1
		jsr	(a1)

		rts

PPR_ExtEvery	dc.l	PPR_return-PPR_ExtEvery				; 0
		dc.l	PPR_return-PPR_ExtEvery				; 1
		dc.l	PPR_return-PPR_ExtEvery				; 2
		dc.l	PPR_return-PPR_ExtEvery				; 3
		dc.l	PPR_return-PPR_ExtEvery				; 4
	ifne PPR_Finetune
		dc.l	PPR_setfinetune-PPR_ExtEvery			; 5
	else
		dc.l	PPR_return-PPR_ExtEvery				; 5
	endc
		dc.l	PPR_return-PPR_ExtEvery				; 6
		dc.l	PPR_return-PPR_ExtEvery				; 7
		dc.l	PPR_return-PPR_ExtEvery				; 8
		dc.l	PPR_retrignote-PPR_ExtEvery			; 9
		dc.l	PPR_return-PPR_ExtEvery				; A
		dc.l	PPR_return-PPR_ExtEvery				; B
		dc.l	PPR_notecut-PPR_ExtEvery			; C
		dc.l	PPR_notedelay-PPR_ExtEvery			; D
		dc.l	PPR_return-PPR_ExtEvery				; E
		dc.l	PPR_return-PPR_ExtEvery				; F

;------------------------------------------------------------------------------
;Extended effectcommands are called each frame.
;------------------------------------------------------------------------------

PPR_ChkExtSometime
		; Extended effectcommands called only the first frame...

		move.b	PPRV_PatternDat+3(a6),d0
		lsr.w	#4-2,d0			; *4
		and.w	#$f<<2,d0
		lea.l	PPR_ExtSometime(pc),a1
		add.l	(a1,d0.w),a1
		jsr	(a1)

		rts

PPR_ExtSometime	dc.l	PPR_filteronoff-PPR_ExtSometime			; 0
		dc.l	PPR_fineportaup-PPR_ExtSometime			; 1
		dc.l	PPR_fineportadown-PPR_ExtSometime		; 2
		dc.l	PPR_setglissctrl-PPR_ExtSometime		; 3
		dc.l	PPR_setvibratoctrl-PPR_ExtSometime		; 4
		dc.l	PPR_return-PPR_ExtSometime			; 5
		dc.l	PPR_PatternLoop-PPR_ExtSometime			; 6
		dc.l	PPR_settremoloctrl-PPR_ExtSometime		; 7
		dc.l	PPR_return-PPR_ExtSometime			; 8
		dc.l	PPR_return-PPR_ExtSometime			; 9
		dc.l	PPR_volumefineup-PPR_ExtSometime		; A
		dc.l	PPR_volumefinedown-PPR_ExtSometime		; B
		dc.l	PPR_return-PPR_ExtSometime			; C
		dc.l	PPR_return-PPR_ExtSometime			; D
		dc.l	PPR_patterndelay-PPR_ExtSometime		; E
		dc.l	PPR_funkit-PPR_ExtSometime			; F

;------------------------------------------------------------------------------
; 0  - ARPEGGIO
;------------------------------------------------------------------------------

PPR_arpinit	move.b	#0,PPRV_ArpCount(a6)	; Clear arpeggio count
		rts

PPR_arpeggio	moveq.l	#0,d0
		move.b	PPRV_ArpCount(a6),d0
		move.b	d0,d1
		add.b	#1,d1
		cmp.b	#3,d1
		bne.s	.OkCount

		moveq.l	#0,d1
.OkCount	move.b	d1,PPRV_ArpCount(a6)

		tst.w	d0
		beq.s	PPR_arpeggio0

		subq	#2,d0
		beq.s	PPR_arpeggio2

		moveq.l	#0,d0			; first value
		move.b	PPRV_PatternDat+3(a6),d0
		lsr.b	#4,d0
		bra.s	PPR_doarp

PPR_arpeggio0	move.w	PPRV_CurrPer(a6),6(a5)		; zero arpeggio
		rts

PPR_arpeggio2	move.b	PPRV_PatternDat+3(a6),d0; last value
		and.w	#$0f,d0

PPR_doarp	add.w	d0,d0

	ifeq PPR_PowerPatt
			lea.l	PPR_periodtable(pc),a1

		ifne PPR_Finetune
			moveq.l	#0,d1
			move.b	PPRV_Finetune(a6),d1
			lsl.l	#7,d1		; *64*2
			add.l	d1,a1
		endc

		move.w	PPRV_CurrPer(a6),d1
		moveq.l	#36,d7
PPR_arploop	cmp.w	(a1)+,d1		; <- This sucks!!!
		bhs.s	PPR_arpeggio4		; HIGHER or same?
		dbra	d7,PPR_arploop
		rts

PPR_arpeggio4
		ifeq PPR_NotePlayer
			move.w	-2(a1,d0.w),6(a5)	; Fetch arpvalue...
		else
			PPRN_SetRate -2(a1,d0.w)
		endc
	else		; If Powerpatterns were enabled
		lea.l	PPR_periodtable-2(pc),a1

		ifne PPR_Finetune
			moveq.l	#0,d1
			move.b	PPRV_Finetune(a6),d1
			lsl.l	#7,d1		; *64*2
			add.l	d1,a1
		endc

		moveq.l	#0,d1
		add.b	PPRV_CurrNote(a6),d0
PPR_arploop
		ifeq PPR_NotePlayer
			move.w	(a1,d0.w),6(a5)	; Fetch arpvalue...
		else
			PPRN_SetRate (a1,d0.w)
		endc
	endc
		rts

;------------------------------------------------------------------------------
; E1 - FINEPORTAMENTO UP
;------------------------------------------------------------------------------

PPR_fineportaup	move.b	#$0f,PPRM_LowMask(a4)	; Tell where argument is

;------------------------------------------------------------------------------
; 1  - PORTAMENTO UP
;------------------------------------------------------------------------------

PPR_portaup	moveq.l	#0,d0
		move.b	PPRV_PatternDat+3(a6),d0
		and.b	PPRM_LowMask(a4),d0
		move.b	#$ff,PPRM_LowMask(a4)
		sub.w	d0,PPRV_CurrPer(a6)
		move.w	PPRV_CurrPer(a6),d0
		and.w	#$0fff,d0
		cmp.w	#113,d0
		bpl.s	PPR_portauskip
		and.w	#$f000,PPRV_CurrPer(a6)
		or.w	#113,PPRV_CurrPer(a6)

PPR_portauskip	move.w	PPRV_CurrPer(a6),d0
		and.w	#$0fff,d0

	ifeq PPR_NotePlayer
		move.w	d0,6(a5)
	else
		PPRN_SetRate d0
	endc

		rts

;------------------------------------------------------------------------------
; E2 - FINEPORTAMENTO DOWN
;------------------------------------------------------------------------------

PPR_fineportadown
		move.b	#$0f,PPRM_LowMask(a4)

;------------------------------------------------------------------------------
; 2  - PORTAMENTO DOWN
;------------------------------------------------------------------------------

PPR_portadown	moveq.l	#0,d0
		move.b	PPRV_PatternDat+3(a6),d0
		and.b	PPRM_LowMask(a4),d0
		move.b	#$ff,PPRM_LowMask(a4)
		add.w	d0,PPRV_CurrPer(a6)
		move.w	PPRV_CurrPer(a6),d0
		and.w	#$0fff,d0
		cmp.w	#856,d0
		bmi.s	PPR_portadskip
		and.w	#$f000,PPRV_CurrPer(a6)
		or.w	#856,PPRV_CurrPer(a6)

PPR_portadskip	move.w	PPRV_CurrPer(a6),d0
		and.w	#$0fff,d0

	ifeq PPR_NotePlayer
		move.w	d0,6(a5)
	else
		PPRN_SetRate d0
	endc

		rts

;------------------------------------------------------------------------------
; 3  - TONEPORTAMENTO
;------------------------------------------------------------------------------

	ifeq PPR_PowerPatt
PPR_settoneporta
;		movem.l	a0,-(sp)
		move.w	PPRV_PatternDat(a6),d2
		and.w	#$0fff,d2
		lea.l	PPR_periodtable(pc),a1

		ifne PPR_Finetune
			moveq.l	#0,d0
			move.b	PPRV_Finetune(a6),d0
			lsl.l	#7,d0	; *64*2
			add.l	d0,a1
		endc

		moveq.l	#0,d0
PPR_stploop	cmp.w	(a1,d0.w),d2		; I hate these loops!
		bhs.s	PPR_stpfound
		addq	#2,d0
		cmp.w	#37*2,d0
		blo.s	PPR_stploop
		moveq.l	#35*2,d0

PPR_stpfound	btst	#3,PPRV_Finetune(a6)
		beq.s	PPR_stpgoss
		tst.w	d0
		beq.s	PPR_stpgoss
		subq	#2,d0
PPR_stpgoss	move.w	(a1,d0.w),d2
;		move.l	(sp)+,a0
		move.w	d2,PPRV_TPDest(a6)
		move.w	PPRV_CurrPer(a6),d0
		clr.b	PPRV_TPDir(a6)
		cmp.w	d0,d2
		beq.s	PPR_cleartoneporta
		bge.w	PPR_return
		move.b	#1,PPRV_TPDir(a6)
		rts

PPR_cleartoneporta
		clr.w	PPRV_TPDest(a6)
		rts

PPR_toneportamento
		move.b	PPRV_PatternDat+3(a6),d0
		beq.s	PPR_toneportnochange
		move.b	d0,PPRV_TPPara(a6)
		clr.b	PPRV_PatternDat+3(a6)
PPR_toneportnochange
		tst.w	PPRV_TPDest(a6)
		beq.w	PPR_return
		moveq.l	#0,d0
		move.b	PPRV_TPPara(a6),d0
		tst.b	PPRV_TPDir(a6)
		bne.s	PPR_toneportaup
PPR_toneportadown
		add.w	d0,PPRV_CurrPer(a6)
		move.w	PPRV_TPDest(a6),d0
		cmp.w	PPRV_CurrPer(a6),d0
		bgt.s	PPR_toneportasetper
		move.w	PPRV_TPDest(a6),PPRV_CurrPer(a6)
		clr.w	PPRV_TPDest(a6)
		bra.s	PPR_toneportasetper

PPR_toneportaup
		sub.w	d0,PPRV_CurrPer(a6)
		move.w	PPRV_TPDest(a6),d0
		cmp.w	PPRV_CurrPer(a6),d0
		blt.s	PPR_toneportasetper
		move.w	PPRV_TPDest(a6),PPRV_CurrPer(a6)
		clr.w	PPRV_TPDest(a6)

PPR_toneportasetper
		move.w	PPRV_CurrPer(a6),d2
		move.b	PPRV_Control2(a6),d0
		and.b	#$0f,d0
		beq.s	PPR_glissskip
		lea.l	PPR_periodtable(pc),a1

		ifne PPR_Finetune
			moveq.l	#0,d0
			move.b	PPRV_Finetune(a6),d0
			lsl.l	#7,d0
			add.l	d0,a1
		endc

		moveq.l	#0,d0
PPR_glissloop	cmp.w	(a1,d0.w),d2		; More loops!?!
		bhs.s	PPR_glissfound
		addq	#2,d0
		cmp.w	#36*2,d0
		blo.s	PPR_glissloop
		moveq.l	#35*2,d0
PPR_glissfound
		move.w	(a1,d0.w),d2
PPR_glissskip
		ifeq PPR_NotePlayer
			move.w	d2,6(a5) ; set period
		else
			PPRN_SetRate d2
		endc

		rts

	else	; If powerpatterns were enabled...
PPR_settoneporta
;		movem.l	a0,-(sp)
		move.b	PPRV_PatternDat(a6),d2
		and.w	#$00ff,d2
		lea.l	PPR_periodtable-2(pc),a1

		ifne PPR_Finetune
			moveq.l	#0,d0
			move.b	PPRV_Finetune(a6),d0
			lsl.l	#7,d0		; *64*2
			add.l	d0,a1
		endc

PPR_stp		move.w	(a1,d2.w),d2

		btst	#3,PPRV_Finetune(a6)
		beq.s	PPR_stpgoss
		tst.w	d0
		beq.s	PPR_stpgoss
		subq	#2,d0
PPR_stpgoss
;		move.l	(sp)+,a0
		move.w	d2,PPRV_TPDest(a6)
		move.w	PPRV_CurrPer(a6),d0
		clr.b	PPRV_TPDir(a6)
		cmp.w	d0,d2
		beq.s	PPR_cleartoneporta
		bge.w	PPR_return
		move.b	#1,PPRV_TPDir(a6)
		rts

PPR_cleartoneporta
		clr.w	PPRV_TPDest(a6)
		rts

PPR_toneportamento
		move.b	PPRV_PatternDat+3(a6),d0
		beq.s	PPR_toneportnochange
		move.b	d0,PPRV_TPPara(a6)
		clr.b	PPRV_PatternDat+3(a6)
PPR_toneportnochange
		tst.w	PPRV_TPDest(a6)
		beq.w	PPR_return
		moveq.l	#0,d0
		move.b	PPRV_TPPara(a6),d0
		tst.b	PPRV_TPDir(a6)
		bne.s	PPR_toneportaup
PPR_toneportadown
		add.w	d0,PPRV_CurrPer(a6)
		move.w	PPRV_TPDest(a6),d0
		cmp.w	PPRV_CurrPer(a6),d0
		bgt.s	PPR_toneportasetper
		move.w	PPRV_TPDest(a6),PPRV_CurrPer(a6)
		clr.w	PPRV_TPDest(a6)
		bra.s	PPR_toneportasetper

PPR_toneportaup
		sub.w	d0,PPRV_CurrPer(a6)
		move.w	PPRV_TPDest(a6),d0
		cmp.w	PPRV_CurrPer(a6),d0
		blt.s	PPR_toneportasetper
		move.w	PPRV_TPDest(a6),PPRV_CurrPer(a6)
		clr.w	PPRV_TPDest(a6)

PPR_toneportasetper
		move.w	PPRV_CurrPer(a6),d2
		move.b	PPRV_Control2(a6),d0
		and.b	#$0f,d0
		beq.s	PPR_glissskip

		lea.l	PPR_periodtable(pc),a1

		ifne PPR_Finetune
			moveq.l	#0,d0
			move.b	PPRV_Finetune(a6),d0
			lsl.l	#7,d0
			add.l	d0,a1
		endc

		moveq.l	#0,d0
PPR_glissloop	cmp.w	(a1,d0.w),d2		; I hate loops!
		bhs.s	PPR_glissfound
		addq.l	#2,d0
		cmp.w	#36*2,d0
		blo.s	PPR_glissloop
		moveq.l	#35*2,d0

PPR_glissfound	move.w	(a1,d0.w),d2

PPR_glissskip
		ifeq PPR_NotePlayer
			move.w	d2,6(a5) ; set period
		else
			PPRN_SetRate d2
		endc

		rts
	endc

;------------------------------------------------------------------------------
; 4  - VIBRATO
;------------------------------------------------------------------------------

PPR_vibrato	move.b	PPRV_PatternDat+3(a6),d0
		beq.s	PPR_vibrato2
		move.b	PPRV_VibPara(a6),d2
		and.b	#$0f,d0
		beq.s	PPR_vibskip
		and.b	#$f0,d2
		or.b	d0,d2
PPR_vibskip
		move.b	PPRV_PatternDat+3(a6),d0
		and.b	#$f0,d0
		beq.s	PPR_vibskip2
		and.b	#$0f,d2
		or.b	d0,d2
PPR_vibskip2
		move.b	d2,PPRV_VibPara(a6)
PPR_vibrato2
		move.b	PPRV_VibCount(a6),d0
		lea.l	PPR_vibratotable(pc),a1
		lsr.w	#2,d0
		and.w	#$001f,d0
		move.b	PPRV_Control1(a6),d2
		and.w	#$03,d2
		beq.s	PPR_vib_sine
		lsl.b	#3,d0
		cmp.b	#1,d2
		beq.s	PPR_vib_rampdown
	moveq.l	#127,d2
	or.b	#$80,d2
		bra.s	PPR_vib_set
PPR_vib_rampdown
		tst.b	PPRV_VibCount(a6)
		bpl.s	PPR_vib_rampdown2
	moveq.l	#127,d0
	or.b	#$80,d0
		sub.b	d0,d2
		bra.s	PPR_vib_set
PPR_vib_rampdown2
		move.b	d0,d2
		bra.s	PPR_vib_set
PPR_vib_sine
		move.b	0(a1,d0.w),d2
PPR_vib_set
		move.b	PPRV_VibPara(a6),d0
		and.w	#15,d0
		mulu	d0,d2
		lsr.w	#7,d2
		move.w	PPRV_CurrPer(a6),d0
		tst.b	PPRV_VibCount(a6)
		bmi.s	PPR_vibratoneg
		add.w	d2,d0
		bra.s	PPR_vibrato3
PPR_vibratoneg
		sub.w	d2,d0
PPR_vibrato3
	ifeq PPR_NotePlayer
		move.w	d0,6(a5)
	else
		PPRN_SetRate d0
	endc

		move.b	PPRV_VibPara(a6),d0
		lsr.w	#2,d0
		and.w	#$003c,d0
		add.b	d0,PPRV_VibCount(a6)
		rts

;------------------------------------------------------------------------------
; 5  - TONEPORTAMENTO + VOLUMESLIDE
;------------------------------------------------------------------------------

PPR_toneplusvolslide
		pea.l	PPR_volumeslide(pc)
		bra.w	PPR_toneportnochange

;------------------------------------------------------------------------------
; 6  - VIBRATO + VOLUMESLIDE
;------------------------------------------------------------------------------

PPR_vibratoplusvolslide
		pea.l	PPR_volumeslide(pc)
		bra.w	PPR_vibrato2

;------------------------------------------------------------------------------
; 7  - TREMOLO
;------------------------------------------------------------------------------

PPR_tremolo	move.b	PPRV_PatternDat+3(a6),d0
		beq.s	PPR_tremolo2
		move.b	PPRV_TremPara(a6),d2
		and.b	#$0f,d0
		beq.s	PPR_treskip
		and.b	#$f0,d2
		or.b	d0,d2
PPR_treskip
		move.b	PPRV_PatternDat+3(a6),d0
		and.b	#$f0,d0
		beq.s	PPR_treskip2
		and.b	#$0f,d2
		or.b	d0,d2
PPR_treskip2
		move.b	d2,PPRV_TremPara(a6)
PPR_tremolo2
		move.b	PPRV_TremCount(a6),d0
		lea.l	PPR_vibratotable(pc),a1
		lsr.w	#2,d0
		and.w	#$001f,d0
		moveq.l	#0,d2
		move.b	PPRV_Control1(a6),d2
		lsr.b	#4,d2
		and.b	#$03,d2
		beq.s	PPR_tre_sine
		lsl.b	#3,d0
		cmp.b	#1,d2
		beq.s	PPR_tre_rampdown
	moveq.l	#127,d2
	or.b	#$80,d2
		bra.s	PPR_tre_set
PPR_tre_rampdown
		tst.b	PPRV_VibCount(a6)
		bpl.s	PPR_tre_rampdown2
	moveq.l	#127,d2
	or.b	#$80,d2
		sub.b	d0,d2
		bra.s	PPR_tre_set
PPR_tre_rampdown2
		move.b	d0,d2
		bra.s	PPR_tre_set
PPR_tre_sine
		move.b	0(a1,d0.w),d2
PPR_tre_set
		move.b	PPRV_TremPara(a6),d0
		and.w	#15,d0
		mulu	d0,d2
		lsr.w	#6,d2
		moveq.l	#0,d0
		move.b	PPRV_Volume(a6),d0
		tst.b	PPRV_TremCount(a6)
		bmi.s	PPR_tremoloneg
		add.w	d2,d0
		bra.s	PPR_tremolo3
PPR_tremoloneg
		sub.w	d2,d0
PPR_tremolo3
		bpl.s	PPR_tremoloskip
		moveq.l	#0,d0
PPR_tremoloskip
		cmp.w	#$40,d0
		bls.s	PPR_tremolook
		moveq.l	#$40,d0
PPR_tremolook

	ifeq PPR_NotePlayer
		ifne PPR_MasterVol
			PPR_CALCVOL2	d0
		else
			move.w	d0,9(a5)
		endc
	else
		PPRN_SetVolume d0
	endc

		move.b	PPRV_TremPara(a6),d0
		lsr.w	#2,d0
		and.w	#$003c,d0
		add.b	d0,PPRV_TremCount(a6)
		rts

;------------------------------------------------------------------------------
; 8  - SYNC VALUE
;------------------------------------------------------------------------------

PPR_syncval	move.b	PPRV_PatternDat+3(a6),PPRM_Msg(a4)
		rts

;------------------------------------------------------------------------------
; 9  - SAMPLE OFFSET
;------------------------------------------------------------------------------

PPR_sampleoffset
		moveq.l	#0,d0
		move.b	PPRV_PatternDat+3(a6),d0
		beq.s	PPR_sononew
		move.b	d0,PPRV_SOffsPara(a6)

PPR_sononew	move.b	PPRV_SOffsPara(a6),d0
		lsl.w	#7,d0
		cmp.w	PPRV_PlaySize(a6),d0
		bge.s	PPR_sofskip
		sub.w	d0,PPRV_PlaySize(a6)
		add.w	d0,d0
		add.l	d0,PPRV_SamplePtr(a6)
		rts
PPR_sofskip
		move.w	#$0001,PPRV_PlaySize(a6)
		rts

;------------------------------------------------------------------------------
; A  - VOLUME SLIDE
;------------------------------------------------------------------------------

PPR_volumeslide	moveq.l	#0,d0
		move.b	PPRV_PatternDat+3(a6),d0
		lsr.b	#4,d0
		tst.b	d0
		beq.s	PPR_volslidedown
PPR_volslideup
		add.b	d0,PPRV_Volume(a6)
		cmp.b	#$40,PPRV_Volume(a6)
		bmi.s	PPR_vsuskip
		move.b	#$40,PPRV_Volume(a6)
PPR_vsuskip
	ifeq PPR_NotePlayer
		ifne PPR_MasterVol
			PPR_CALCVOL	d0
		else
			move.b	PPRV_Volume(a6),9(a5)
		endc
	else
		PPRN_SetVolume PPRV_Volume(a6)
	endc

		rts

PPR_volslidedown
		move.b	PPRV_PatternDat+3(a6),d0
		and.w	#$0f,d0
PPR_volslidedown2
		sub.b	d0,PPRV_Volume(a6)
		bpl.s	PPR_vsdskip
		clr.b	PPRV_Volume(a6)
PPR_vsdskip
	ifeq PPR_NotePlayer
		ifne PPR_MasterVol
			PPR_CALCVOL	d0
		else
			move.b	PPRV_Volume(a6),9(a5)
		endc
	else
		PPRN_SetVolume PPRV_Volume(a6)
	endc
		rts

;------------------------------------------------------------------------------
; B  - POSITION JUMP
;------------------------------------------------------------------------------

PPR_positionjump
		move.b	PPRV_PatternDat+3(a6),d0
		subq	#1,d0
		move.b	d0,PPRM_SongPos(a4)
		st.b	PPRM_RestFlag(a4)
PPR_pj2		clr.b	PPRM_PBreakPos(a4)
		st 	PPRM_PosJumpFl(a4)
		rts

;------------------------------------------------------------------------------
; C  - SET VOLUME
;------------------------------------------------------------------------------

PPR_volumechange
		move.b	PPRV_PatternDat+3(a6),d0
		cmp.b	#$40,d0
		bls.s	PPR_volumeok
		moveq.l	#$40,d0
PPR_volumeok
		move.b	d0,PPRV_Volume(a6)		; Store volume

	ifeq PPR_NotePlayer
		ifne PPR_MasterVol
			PPR_CALCVOL2	d0
		else
			move.b	d0,9(a5)
		endc
	else
		PPRN_SetVolume d0
	endc

		rts

;------------------------------------------------------------------------------
; D  - PATTERN BREAK
;------------------------------------------------------------------------------

PPR_patternbreak
		moveq.l	#0,d0
		move.b	PPRV_PatternDat+3(a6),d0
		move.w	d0,d2
		lsr.b	#4,d0
		add	d0,d0
		move	d0,d1
		add	d0,d0
		add	d0,d0
		add	d1,d0
		and.b	#$0f,d2
		add.b	d2,d0
		cmp.b	#63,d0
		bhi.s	PPR_pj2
		move.b	d0,PPRM_PBreakPos(a4)
		st	PPRM_PosJumpFl(a4)
		rts

;------------------------------------------------------------------------------
; F  - SET SPEED
;------------------------------------------------------------------------------

PPR_setspeed	move.b	PPRV_PatternDat+3(a6),d0
		bne.s	.NotHalt

		st.b	PPRM_RestFlag(a4)

.NotHalt	clr.b	PPRM_Counter(a4)
	ifne PPR_CIA
		cmp.b	#32,d0
		bhs.s	CIA_SetBPM

	endc
		move.b	d0,PPRM_Speed(a4)
		rts

;------------------------------------------------------------------------------
; E0 - SET FILTER
;------------------------------------------------------------------------------

PPR_filteronoff	move.b	PPRV_PatternDat+3(a6),d0

	ifeq PPR_NotePlayer
		and.b	#1,d0
		bne.s	.Set

.Clr		and.b	#~2,$bfe001
		rts

.Set		or.b	#2,$bfe001
	else
		PPRN_Filter d0
	endc

		rts

;------------------------------------------------------------------------------
; E3 - GLISSANDO CONTROL
;------------------------------------------------------------------------------

PPR_setglissctrl
		move.b	PPRV_PatternDat+3(a6),d0
		and.b	#$0f,d0
		and.b	#$f0,PPRV_Control2(a6)
		or.b	d0,PPRV_Control2(a6)
		rts

;------------------------------------------------------------------------------
; E4 - VIBRATO CONTROL
;------------------------------------------------------------------------------

PPR_setvibratoctrl
		move.b	PPRV_PatternDat+3(a6),d0
		and.b	#$0f,d0
		and.b	#$f0,PPRV_Control1(a6)
		or.b	d0,PPRV_Control1(a6)
		rts

;------------------------------------------------------------------------------
; E5 - SET FINETUNE
;------------------------------------------------------------------------------

	ifne PPR_Finetune
PPR_setfinetune	move.b	PPRV_PatternDat+3(a6),d0
		and.b	#$0f,d0
		move.b	d0,PPRV_Finetune(a6)
		rts
	endc

;------------------------------------------------------------------------------
; E6 - PATTERN LOOP
;------------------------------------------------------------------------------

PPR_PatternLoop	move.b	PPRV_PatternDat+3(a6),d0
		and.b	#$0f,d0
		beq.s	PPR_setloop

		tst.b	PPRV_PLoopCount(a6)
		beq.s	PPR_jumpcnt

		subq.b	#1,PPRV_PLoopCount(a6)
		beq.w	PPR_return

PPR_jmploop 	move.b	PPRV_PLoopPos(a6),PPRM_PBreakPos(a4)
		st	PPRM_PBreakFl(a4)
		rts

PPR_jumpcnt	move.b	d0,PPRV_PLoopCount(a6)
		bra.s	PPR_jmploop

PPR_setloop	move.w	PPRM_PatternPos(a4),d0	; Store loop position
		lsr.w	#2,d0			; /2 = number offset
		move.b	d0,PPRV_PLoopPos(a6)
		rts

;------------------------------------------------------------------------------
; E7 - TREMOLO CONTROL
;------------------------------------------------------------------------------

PPR_settremoloctrl
		move.b	PPRV_PatternDat+3(a6),d0
		and.b	#$0f,d0
		lsl.b	#4,d0
		and.b	#$0f,PPRV_Control1(a6)
		or.b	d0,PPRV_Control1(a6)
		rts

;------------------------------------------------------------------------------
; E9 - RETRIG NOTE
;------------------------------------------------------------------------------

PPR_retrignote
;		move.l	d1,-(sp)
		move.b	PPRV_PatternDat+3(a6),d0
		and.w	#$0f,d0
		beq.w	PPR_rtnend

		moveq.l	#0,d1
		move.b	PPRM_Counter(a4),d1
		bne.s	PPR_rtnskp		; If start of note...

	ifeq PPR_PowerPatt
		move.w	PPRV_PatternDat(a6),d1	; ...only trig if note set!
		and.w	#$0fff,d1
		bne.w	PPR_rtnend
	else
		move.b	PPRV_PatternDat(a6),d1
		bne.w	PPR_rtnend
	endc

		moveq.l	#0,d1
		move.b	PPRM_Counter(a4),d1

PPR_rtnskp	divu	d0,d1
		swap	d1
;		tst.w	d1
;		bne.s	PPR_rtnend
		dbra	d1,PPR_rtnend		; ...Not the time?

PPR_doretrig
	ifeq PPR_NotePlayer
		move.w	PPRV_DMAMask(a6),$dff096; Channel DMA off
		PPR_WAIT 1
		move.l	PPRV_SamplePtr(a6),(a5)	; Set sampledata pointer
		move.w	PPRV_PlaySize(a6),4(a5)	; Set length
		PPR_WAIT 4
		move.w	PPRV_DMAMask(a6),d0
		or.w	#2^15,d0		; BSET #15,d0
		move.w	d0,$dff096		; Channel DMA on
PPR_Dummy02	PPR_WAIT 1
		move.l	PPRV_LoopStart(a6),(a5)	; Write more data...
		move.l	PPRV_RepLen(a6),4(a5)
	else
		PPRN_TrigWave PPRV_SamplePtr(a6),PPRV_PlaySize(a6)
		PPRN_SetWave PPRV_LoopStart(a6),PPRV_RepLen(a6)
	endc

PPR_rtnend
;		move.l	(sp)+,d1
		rts

;------------------------------------------------------------------------------
; EA - VOLUME FINESLIDE UP
;------------------------------------------------------------------------------

PPR_volumefineup
		move.b	PPRV_PatternDat+3(a6),d0
		and.w	#$f,d0
		bra.w	PPR_volslideup

;------------------------------------------------------------------------------
; EB - VOLUME FINESLIDE DOWN
;------------------------------------------------------------------------------

PPR_volumefinedown
		move.b	PPRV_PatternDat+3(a6),d0
		and.w	#$0f,d0
		bra.w	PPR_volslidedown2

;------------------------------------------------------------------------------
; EB - NOTECUT
;------------------------------------------------------------------------------

PPR_notecut	move.b	PPRV_PatternDat+3(a6),d0
		and.w	#$0f,d0
		cmp.b	PPRM_Counter(a4),d0
		bne.w	PPR_return		; Has the time come?

		clr.b	PPRV_Volume(a6)

	ifeq PPR_NotePlayer
		move.w	#0,8(a5)
	else
		PPRN_SetVolume #0
	endc
		rts

;------------------------------------------------------------------------------
; ED - NOTEDELAY
;------------------------------------------------------------------------------

PPR_notedelay	move.b	PPRV_PatternDat+3(a6),d0
		and.w	#$0f,d0
		cmp.b	PPRM_Counter(a4),d0	; Has the time come?
		bne.w	PPR_return

		move.w	PPRV_PatternDat(a6),d0
		beq.w	PPR_return
;		move.l	d1,-(sp)
		bra.w	PPR_doretrig		; Trig note

;------------------------------------------------------------------------------
; EE - PATTERN DELAY
;------------------------------------------------------------------------------

PPR_patterndelay
		move.b	PPRV_PatternDat+3(a6),d0
		and.w	#$0f,d0
		tst.b	PPRM_PtDelTime(a4)
		bne.w	PPR_return		; We are already delaying...
		tst.b	PPRM_PtDelCount(a4)
		bne.w	PPR_return		; We are already delaying...
		addq.b	#1,d0
		move.b	d0,PPRM_PtDelTime(a4)	; Store delay count
		rts

;------------------------------------------------------------------------------
; EF - FUNKREPEAT
;------------------------------------------------------------------------------

PPR_funkit	move.b	PPRV_PatternDat+3(a6),d0
		and.b	#$0f,d0
		lsl.b	#4,d0
		and.b	#$0f,PPRV_Control2(a6)
		or.b	d0,PPRV_Control2(a6)	; Store speed
		tst.b	d0
		beq.w	PPR_return		; If no speed, return

PPR_updatefunk
;		movem.l	d1/a0,-(sp)
		moveq.l	#0,d0
		move.b	PPRV_Control2(a6),d0
		lsr.b	#4,d0			; Get speed
		beq.s	PPR_funkend		; No speed, no funk

		lea.l	PPR_funktable(pc),a1
		move.b	(a1,d0.w),d0
		add.b	d0,PPRV_FunkDuh(a6)

		btst	#7,PPRV_FunkDuh(a6)	; Y = 128?
		beq.s	PPR_funkend		; No...

		clr.b	PPRV_FunkDuh(a6)	; Y = 0

		move.l	PPRV_LoopStart(a6),d0
		moveq.l	#0,d1
		move.w	PPRV_RepLen(a6),d1
		add.l	d1,d0
		add.l	d1,d0
		move.l	PPRV_FunkPtr(a6),a0
		addq.l	#1,a1
		cmp.l	d0,a1
		blo.s	PPR_funkok
		move.l	PPRV_LoopStart(a6),a1	; Init pointer

PPR_funkok	move.l	a1,PPRV_FunkPtr(a6)
		neg.b	(a1)
		subq.b	#1,(a1)

PPR_funkend
;		movem.l	(sp)+,d1/a0
		rts

;------------------------------------------------------------------------------
;	Tables and miscellaneous stuff...
;------------------------------------------------------------------------------

PPR_funktable	dc.b   0,  5,  6,  7,  8, 10, 11, 13
		dc.b  16, 19, 22, 26, 32, 43, 64,128

PPR_vibratotable
		dc.b   0, 24, 49, 74, 97,120,141,161
		dc.b 180,197,212,224,235,244,250,253
		dc.b 255,253,250,244,235,224,212,197
		dc.b 180,161,141,120, 97, 74, 49, 24

		dc.w	0
PPR_periodtable
; tuning 0, normal
		dc.w	856,808,762,720,678,640,604,570,538,508,480,453
		dc.w	428,404,381,360,339,320,302,285,269,254,240,226
		dc.w	214,202,190,180,170,160,151,143,135,127,120,113
		dcb.w	64-36,0

	ifne PPR_Finetune
; tuning 1
		dc.w	850,802,757,715,674,637,601,567,535,505,477,450
		dc.w	425,401,379,357,337,318,300,284,268,253,239,225
		dc.w	213,201,189,179,169,159,150,142,134,126,119,113
		dcb.w	64-36,0
; tuning 2
		dc.w	844,796,752,709,670,632,597,563,532,502,474,447
		dc.w	422,398,376,355,335,316,298,282,266,251,237,224
		dc.w	211,199,188,177,167,158,149,141,133,125,118,112
		dcb.w	64-36,0
; tuning 3
		dc.w	838,791,746,704,665,628,592,559,528,498,470,444
		dc.w	419,395,373,352,332,314,296,280,264,249,235,222
		dc.w	209,198,187,176,166,157,148,140,132,125,118,111
		dcb.w	64-36,0
; tuning 4
		dc.w	832,785,741,699,660,623,588,555,524,495,467,441
		dc.w	416,392,370,350,330,312,294,278,262,247,233,220
		dc.w	208,196,185,175,165,156,147,139,131,124,117,110
		dcb.w	64-36,0
; tuning 5
		dc.w	826,779,736,694,655,619,584,551,520,491,463,437
		dc.w	413,390,368,347,328,309,292,276,260,245,232,219
		dc.w	206,195,184,174,164,155,146,138,130,123,116,109
		dcb.w	64-36,0
; tuning 6
		dc.w	820,774,730,689,651,614,580,547,516,487,460,434
		dc.w	410,387,365,345,325,307,290,274,258,244,230,217
		dc.w	205,193,183,172,163,154,145,137,129,122,115,109
		dcb.w	64-36,0
; tuning 7
		dc.w	814,768,725,684,646,610,575,543,513,484,457,431
		dc.w	407,384,363,342,323,305,288,272,256,242,228,216
		dc.w	204,192,181,171,161,152,144,136,128,121,114,108
		dcb.w	64-36,0
; tuning -8
		dc.w	907,856,808,762,720,678,640,604,570,538,508,480
		dc.w	453,428,404,381,360,339,320,302,285,269,254,240
		dc.w	226,214,202,190,180,170,160,151,143,135,127,120
		dcb.w	64-36,0
; tuning -7
		dc.w	900,850,802,757,715,675,636,601,567,535,505,477
		dc.w	450,425,401,379,357,337,318,300,284,268,253,238
		dc.w	225,212,200,189,179,169,159,150,142,134,126,119
		dcb.w	64-36,0
; tuning -6
		dc.w	894,844,796,752,709,670,632,597,563,532,502,474
		dc.w	447,422,398,376,355,335,316,298,282,266,251,237
		dc.w	223,211,199,188,177,167,158,149,141,133,125,118
		dcb.w	64-36,0
; tuning -5
		dc.w	887,838,791,746,704,665,628,592,559,528,498,470
		dc.w	444,419,395,373,352,332,314,296,280,264,249,235
		dc.w	222,209,198,187,176,166,157,148,140,132,125,118
		dcb.w	64-36,0
; tuning -4
		dc.w	881,832,785,741,699,660,623,588,555,524,494,467
		dc.w	441,416,392,370,350,330,312,294,278,262,247,233
		dc.w	220,208,196,185,175,165,156,147,139,131,123,117
		dcb.w	64-36,0
; tuning -3
		dc.w	875,826,779,736,694,655,619,584,551,520,491,463
		dc.w	437,413,390,368,347,328,309,292,276,260,245,232
		dc.w	219,206,195,184,174,164,155,146,138,130,123,116
		dcb.w	64-36,0
; tuning -2
		dc.w	868,820,774,730,689,651,614,580,547,516,487,460
		dc.w	434,410,387,365,345,325,307,290,274,258,244,230
		dc.w	217,205,193,183,172,163,154,145,137,129,122,115
		dcb.w	64-36,0
; tuning -1
		dc.w	862,814,768,725,684,646,610,575,543,513,484,457
		dc.w	431,407,384,363,342,323,305,288,272,256,242,228
		dc.w	216,203,192,181,171,161,152,144,136,128,121,114
		dcb.w	64-36,0
	endc
		dc.w	0

	CNOP	0,4

PPR_MainData	dcb.b	PPRM_sizeof,0

PPR_VoiceData	dcb.b	PPRV_sizeof*4,0


	SECTION Module,DATA_C

	INCDIR	"!SOURCES:PRODUCTIONS/PTSUPP/PROPRUNER/"

Module	INCBIN	"PPR.BLOB"
	;INCBIN	"PPR.PANIC UTEN ERROR..."
	;INCBIN	"PPR.CHIP_3"
	;INCBIN	"PPR.TETRIS THEME"
	;INCBIN	"PPR.NOW WHAT 3"
	;INCBIN "HD2:PPR.A"

