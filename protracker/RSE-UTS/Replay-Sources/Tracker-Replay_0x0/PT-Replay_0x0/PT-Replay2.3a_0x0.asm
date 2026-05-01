; Program: PT-Replay2.3a_0x0.asm
; Author:  Dissident^Resistance
; Date:    2021-05-01
; Version: 4.2
; CPU:     68020+
; FASTMEM:  -
; Chipset: OCS/ECS/AGA
; OS:      1.2+

; ** Supported trackers **
; - Soundtracker 2.5
; - Soundtracker 2.6
; - Noisetracker 1.x
; - Protracker   1.x
; - Protracker   2.x

; ** Main characteristics **
; - 31 instruments
; - Repeat point in words
; - Extended effect commands
; - Raster dependent or independant replay

; ** Code **
; - Improved and optimized for 68020+ CPUs

; ** Play music trigger **
; - Label pt_PlayMusic: Called from CIA-B timer A or vblank interrupt
; - Equal pt_timingcia: TRUE = Activate sourcecode for CIA-B timer A as
;                       trigger for variable 32..255 BPM replay with the
;                       same tempo on PAL and NTSC machines
;                       FALSE = Activate sourcecode for vblank as trigger
;                       for constant 125 BPM replay on PAL machines and
;                       for constant 150 BPM on NTSC machines

; ** DMA wait trigger **
; - Label pt_DMAWait: Called from CIA-B timer B interrupt triggered
;                     after 511.43 탎 on PAL machines or 506.76 탎
;                     on NTSC machines

; ** Loop samples **
; - Check for repeat length > 1 word, instead of repeat point not NULL
; - Loop samples with repeat point = NULL now properly detected

; ** Supported effect commands (cmd format 2) **
; 0 - Normal play or Arpeggio
; 1 - Portamento Up
; 2 - Portamento Down
; 3 - Tone Portamento
; 4 - Vibrato
; 5 - Tone Portamento + Volume Slide
; 6 - Vibrato + Volume Slide
; 7 - Tremolo
; 8 - NOT USED
; 9 - Set Sample Offset
; A - Volume Slide
; B - Position Jump
; C - Set Volume
; D - Pattern Break
; E - Extended commands
;   E0 - Set Filter
;   E1 - Fine Portamento Up
;   E2 - Fine Portamento Down
;   E3 - Set Glissando Control
;   E4 - Set Vibrato Waveform
;   E5 - Set Sample Finetune
;   E6 - Jump to Loop
;   E7 - Set Tremolo Waveform
;   E8 - Karplus Strong
;   E9 - Retrig Note
;   EA - Fine Volume Slide Up
;   EB - Fine Volume Slide Down
;   EC - Note Cut
;   ED - Note Delay
;   EE - Pattern Delay
;   EF - Invert Loop
; F - Set Speed



; ************************* Includes ***********************

; ** OS-library includes **
; -------------------------
  INCDIR "SYS:include/"
  INCLUDE "exec/exec.i"
  INCLUDE "exec/exec_lib.i"
  INCLUDE "graphics/GFXBase.i"
  INCLUDE "hardware/cia.i"
  INCLUDE "hardware/custom.i"
  INCLUDE "hardware/dmabits.i"
  INCLUDE "hardware/intbits.i"



; ************************* Equals ***********************

; ** General equals **
TRUE                     EQU 0
FALSE                    EQU -1
FALSEB                   EQU $ff
FALSEW                   EQU $ffff
FALSEL                   EQU $ffffffff
NIBBLESHIFTBITS          EQU 4
NIBBLESHIFT              EQU 16
NIBBLEMASKLO             EQU $0f
NIBBLEMASKHI             EQU $f0
NIBBLESIGNMASK           EQU $8
NIBBLESIGNBIT            EQU 3
BYTESHIFTBITS            EQU 8
BYTESHIFT                EQU 256
BYTEMASK                 EQU $ff
BYTESIGNMASK             EQU $80
BYTESIGNBIT              EQU 7
WORDSHIFT                EQU 65536
WORDMASK                 EQU $ffff
WORDSIGNMASK             EQU $8000
WORDSIGNBIT              EQU 15

; ** Base addresses **
Exec_Base                EQU $0004
_CUSTOM                  EQU $dff000
_CIAA                    EQU $bfe001
_CIAB                    EQU $bfd000

; ** Audio registers **
AUD0LCH                  EQU AUD0
AUD0LCL                  EQU AUD0+2
AUD0LEN                  EQU AUD0+4
AUD0PER                  EQU AUD0+6
AUD0VOL                  EQU AUD0+8
AUD1LCH                  EQU AUD1
AUD1LCL                  EQU AUD1+2
AUD1LEN                  EQU AUD1+4
AUD1PER                  EQU AUD1+6
AUD1VOL                  EQU AUD1+8
AUD2LCH                  EQU AUD2
AUD2LCL                  EQU AUD2+2
AUD2LEN                  EQU AUD2+4
AUD2PER                  EQU AUD2+6
AUD2VOL                  EQU AUD2+8
AUD3LCH                  EQU AUD3
AUD3LCL                  EQU AUD3+2
AUD3LEN                  EQU AUD3+4
AUD3PER                  EQU AUD3+6
AUD3VOL                  EQU AUD3+8

; ** Hardware register content bits **
pt_DMABITS               EQU DMAF_AUD0+DMAF_AUD1+DMAF_AUD2+DMAF_AUD3 ;Audio DMA for all channels off
pt_CIABCRABITS           EQU CIACRBF_LOAD ;CIA-B timer A continuous mode
pt_CIABCRBBITS           EQU CIACRBF_LOAD+CIACRBF_RUNMODE ;CIA-B timer B oneshot mode

; ** Timer values **
pt_50hzframepaltime      EQU 14187 ;= 0.709379 MHz * [20000 탎 = 50 Hz duration for one frame on a PAL machine]
pt_50hzframentsctime     EQU 14318 ;= 0.715909 MHz * [20000 탎 = 50 Hz duration for one frame on a NTSC machine]
pt_dmawaittime           EQU 362 ;= 0.709379 MHz * [511.43 탎 = Lowest note period C1 with Tuning=-8 * 2 / PAL clock constant = 907*2/3546895 ticks per second]
                                 ;= 0.715909 MHz * [506.76 탎 = Lowest note period C1 with Tuning=-8 * 2 / NTSC clock constant = 907*2/3579545 ticks per second]
; ** Song equals **
pt_maxsongpos            EQU 128
pt_maxpattpos            EQU 64
pt_pattsize              EQU 1024
pt_samplesnum            EQU 31

; ** Speed/Tempo equals **
pt_defaultticks          EQU 6
pt_minticks              EQU 0
pt_maxticks              EQU 31
pt_defaultbpm            EQU 125
pt_minbpm                EQU 32
pt_maxbpm                EQU 255
pt_pal125bpmrate         EQU 1773447 ;= 0,709379 MHz * [(20000 탎 * 125 BPM)]
pt_ntsc125bpmrate        EQU 1789773 ;= 0,715909 MHz * [(20000 탎 * 125 BPM)]

; ** Effect command masks equals **
pt_cmdpermask            EQU $0fff
pt_cmdnummask            EQU $0f
pt_ecmdnummask           EQU $0ff0

; ** Effect commands equals **
pt_arpdiv                EQU 3
pt_periodsnum            EQU 36
pt_portminperiod         EQU 113 ;Note period "B-3"
pt_portmaxperiod         EQU 856 ;Note period "C-1"
pt_finetunenum           EQU 16
pt_minvolume             EQU 0
pt_maxvolume             EQU 64
pt_wavetypemask          EQU $03
pt_wavesine              EQU 0
pt_waverampdown          EQU 1
pt_wavesquare            EQU 2
pt_wavenoretrig          EQU 4
pt_vibnoretrigbit        EQU 2
pt_trenoretrigbit        EQU 6

; ** Replay routine trigger **
pt_timingcia             EQU TRUE


                                  
; ************************* Variables offsets ***********************

; ** Relative offsets for variables **
; ------------------------------------
  RSRESET
pt_125bpmrate              RS.L 1
pt_SongDataPtr	           RS.L 1
pt_Counter	           RS.W 1
pt_CurrSpeed	           RS.W 1
pt_DMACONtemp	           RS.W 1
pt_PatternPtr	           RS.L 1
pt_PatternPosition         RS.W 1
pt_SongPosition	           RS.W 1
pt_RtnDMACONtemp           RS.W 1
pt_PBreakPosition          RS.B 1
pt_PosJumpFlag	           RS.B 1
pt_PBreakFlag	           RS.B 1
pt_LowMask	           RS.B 1
pt_PattDelayTime           RS.B 1
pt_PattDelayTime2          RS.B 1
pt_SongLength              RS.B 1
pt_SetAllChanDMAFlag       RS.B 1
pt_InitAllChanLoopDataFlag RS.B 1
pt_variables_SIZE          RS.B 0



; ************************* Structures ***********************

; ** PT-Song-Structure **
; -----------------------

; ** PT SampleInfo structure **
  RSRESET
pt_sampleinfo      RS.B 0
pt_si_samplename   RS.B 22   ;Sample's name padded with null bytes ,"#" at the beginning indicates a message
pt_si_samplelength RS.W 1    ;Sample length in words
pt_si_finetune     RS.B 1    ;Bits 7-4 not used, bits 3-0 finetune value as signed 4 bit number
pt_si_volume       RS.B 1    ;Bit 7 not used, bits 6-0 sample volume 0..64
pt_si_repeatpoint  RS.W 1    ;Start of sample repeat offset in words
pt_si_repeatlength RS.W 1    ;Length of sample repeat in words
pt_sampleinfo_SIZE RS.B 0

; ** PT SongData structure **
  RSRESET
pt_songdata        RS.B 0
pt_sd_songname     RS.B 20   ;Song's name padded with null bytes
pt_sd_sampleinfo   RS.B pt_sampleinfo_SIZE*pt_samplesnum ;Pointer to 1st sampleinfo, structure repeated for each sample 1-31
pt_sd_numofpatt    RS.B 1    ;Number of song positions 1..128
pt_sd_restartpos   RS.B 1    ;Restart position for Noisetracker and Startrekker not used by PT, set to 127
pt_sd_pattpos      RS.B 128  ;Pattern positions table 0..127
pt_sd_id           RS.B 4    ;"M.K." = (4 channels, 31 samples, 64 pattern positions) or "M!K!" (4 channels, 31 Samples, 100 patterns)
pt_sd_patterndata  RS.B 0    ;Pointer to 1st pattern, structure repeated for each pattern 1..64 times
pt_songdata_SIZE   RS.B 0

; ** PT NoteInfo structure **
  RSRESET
pt_noteinfo      RS.B 0
pt_ni_note       RS.W 1      ;Bits 15-12 upper nibble of sample number, bits 11-0 note period
pt_ni_cmd        RS.B 1      ;Bits 7-4 lower nibble of sample number, bits 3-0 effect command number
pt_ni_cmdlo      RS.B 1      ;Bits 7-0 effect command data / bits 7-4 effect e-command number, bits 3-0 effect e-command data
pt_noteinfo_SIZE RS.B 0

; ** PT PatternPositionData structure **
  RSRESET
pt_pattposdata       RS.B 0
pt_ppd_chan1noteinfo RS.B pt_noteinfo_SIZE ;Note info for each audio channel 1..4 is stored successive
pt_ppd_chan2noteinfo RS.B pt_noteinfo_SIZE
pt_ppd_chan3noteinfo RS.B pt_noteinfo_SIZE
pt_ppd_chan4noteinfo RS.B pt_noteinfo_SIZE
pt_pattposdata_SIZE  RS.B 0

; ** PT PatternData structure **
  RSRESET
pt_patterndata      RS.B 0
pt_pd_data          RS.B pt_pattposdata_SIZE*pt_maxpattpos ;Repeated 64 times (standard PT) or upto 100 times (PT 2.3a)
pt_patterndata_SIZE RS.B 0

; ** Temporary channel structure **
; ---------------------------------
  RSRESET
n_audchantemp      RS.B 0
n_note             RS.W 1
n_cmd              RS.B 1
n_cmdlo            RS.B 1
n_start            RS.L 1
n_length           RS.W 1
n_period           RS.W 1
n_loopstart        RS.L 1
n_replen           RS.W 1
n_finetune         RS.B 1
n_volume           RS.B 1
n_dmabit           RS.W 1
n_toneportdirec    RS.B 1
n_toneportspeed    RS.B 1
n_wantedperiod     RS.W 1
n_vibratocmd       RS.B 1
n_vibratopos       RS.B 1
n_tremolocmd       RS.B 1
n_tremolopos       RS.B 1
n_wavecontrol      RS.B 1
n_glissinvert      RS.B 1
n_sampleoffset     RS.B 1
n_pattpos          RS.B 1
n_loopcount        RS.B 1
n_invertoffset     RS.B 1
n_wavestart	   RS.L 1
n_reallength       RS.W 1
n_trigger          RS.B 1
n_samplenum        RS.B 1
n_rtnsetchandma    RS.B 1
n_rtninitchandata  RS.B 1
n_audchantemp_SIZE RS.B 0



  SECTION pt_replay2.3a,CODE

  MC68020

; ************************* Init music ***********************

; ** Do all audio inits **
; ------------------------
; Constant registers
; a3 ... Base of variables
; a4 ... Base of CIA-A
; a5 ... Base of CIA-B
; a6 ... Base of custom chips / exec library
  CNOP 0,4
pt_InitMusic
  lea     pt_Variables(pc),a3 ;Base of variables
  move.l  Exec_Base.w,a6     ;Base of exec library
  bsr.s   pt_DetectSysFrequ
  move.l  #_CIAB,a5          ;Base of CIA-B
  lea     _CIAA-_CIAB(a5),a4 ;Base of CIA-A
  move.l  #_CUSTOM,a6        ;Base of custom chips
  bsr.s   pt_InitTimers
  bsr.s   pt_InitRegisters
  bsr     pt_InitVariables
  bsr     pt_InitAudTempStrucs
  bsr     pt_ExamineSongStruc
  bra     pt_InitFtuPeriodTableStarts

; ** Detect system frequency PAL/NTSC **
  CNOP 0,4
pt_DetectSysFrequ
  move.l  #pt_pal125bpmrate,d2 ;Set PAL 125 bpm rate as default
  lea     gfxname(pc),a1     ;Pointer to gfx library name
  moveq   #TRUE,d0           ;Any version
  jsr     _LVOOpenLibrary(a6) ;Open gfx library
  tst.l   d0                 ;Successful ?
  beq.s   pt_OpenGFXLibError ;No -> skip
  move.l  d0,a1              ;Pointer to gfx library base
  move.w  gb_DisplayFlags(a1),d0 ;Get Display flags
  btst    #REALLY_PALn,d0    ;Crystal frequency 50 Hz ? (OS3.0+)
  bne.s   pt_PalSysFreqDetected ;Yes -> skip
  btst    #PALn,d0           ;Frequency 50 Hz (OS1.2...OS2.04) ?
  bne.s   pt_PalSysFreqDetected ;Yes -> skip
pt_NtscSysFreqDetected
  move.l  #pt_ntsc125bpmrate,d2 ;Set NTSC 125 bpm rate
pt_PalSysFreqDetected
  jsr     _LVOCloseLibrary(a6) ;Close gfx library
  moveq   #TRUE,d0           ;Returncode = OK
pt_DetectSysFreqEnd
  move.l  d2,pt_125bpmrate(a3) ;Save 125 BPM rate
  rts
  CNOP 0,4
pt_OpenGFXLibError
  moveq   #FALSE,d0          ;Returncode = FALSE
  bra.s   pt_DetectSysFreqEnd

; ** Init all timers **
  CNOP 0,4
pt_InitTimers
  IFEQ pt_timingcia
    move.l  pt_125bpmrate(a3),d0 ;Get 125 bpm PAL/NTSC rate
    divu.w  #pt_defaultbpm,d0 ;/125 BPM = default to normal 50 Hz timer
    move.b  d0,CIATALO(a5)   ;Set CIA-B timer A counter value low bits
    lsr.w   #BYTESHIFTBITS,d0 ;Get counter value high bits
    move.b  d0,CIATAHI(a5)   ;Set CIA-B timer A counter value high bits
    moveq   #pt_CIABCRABITS,d0
    move.b  d0,CIACRA(a5)    ;Load continuous timer A value
  ENDC
  moveq   #pt_dmawaittime&BYTEMASK,d0 ;DMA wait
  move.b  d0,CIATBLO(a5)     ;Set CIA-B timer B counter value low bits
  moveq   #pt_dmawaittime>>BYTESHIFTBITS,d0
  move.b  d0,CIATBHI(a5)     ;Set CIA-B timer B counter value high bits
  moveq   #pt_CIABCRBBITS,d0
  move.b  d0,CIACRB(a5)      ;Load oneshot timer B value
  rts

; ** Init main registers **
  CNOP 0,4
pt_InitRegisters
  moveq   #TRUE,d0
  move.w  d0,AUD0VOL(a6)     ;Clear volume for all channels
  move.w  d0,AUD1VOL(a6)
  move.w  d0,AUD2VOL(a6)
  move.w  d0,AUD3VOL(a6)
  moveq   #CIAF_LED,d0
  or.b    d0,CIAPRA(a4)      ;Turn soundfilter off
  rts

; ** Init main variables **
  CNOP 0,4
pt_InitVariables
  lea     pt_auddata,a0      ;Pointer to module
  move.l  a0,pt_SongDataPtr(a3)
  moveq   #TRUE,d0
  move.w  d0,pt_Counter(a3)
  moveq   #pt_defaultticks,d2
  move.w  d2,pt_CurrSpeed(a3) ;Set as default 6 ticks
  move.w  d0,pt_DMACONtemp(a3)
  moveq   #DMAF_AUD0+DMAF_AUD1+DMAF_AUD2+DMAF_AUD3,d2
  move.l  d0,pt_PatternPtr(a3)
  move.w  d0,pt_PatternPosition(a3)
  move.w  d0,pt_SongPosition(a3)
  move.w  d0,pt_RtnDMACONtemp(a3)
  move.b  d0,pt_PBreakPosition(a3)
  move.b  d0,pt_PosJumpFlag(a3)
  move.b  d0,pt_PBreakFlag(a3)
  move.b  d0,pt_LowMask(a3)
  move.b  d0,pt_PattDelayTime(a3)
  move.b  d0,pt_PattDelayTime2(a3)
  moveq   #FALSE,d1
  move.b  d1,pt_SetAllChanDMAFlag(a3) ;Deactivate set routine
  move.b  d1,pt_InitAllChanLoopDataFlag(a3) ;Deactivate init routine
  rts

; ** Init temporary channel structures **
  CNOP 0,4
pt_InitAudTempStrucs
  moveq   #DMAF_AUD0,d0      ;DMA bit for channel1
  lea     pt_audchan1temp+n_dmabit(pc),a0
  move.w  d0,(a0)            ;Set DMA channel1 bit
  moveq   #FALSE,d1
  move.b  d1,n_rtnsetchandma-n_dmabit(a0) ;Deactivate channel1 set routine for "Retrig Note" or "Note Delay"
  moveq   #DMAF_AUD1,d0      ;DMA bit for channel2
  move.b  d1,n_rtninitchandata-n_dmabit(a0) ;Deactivate channel1 init routine for "Retrig Note" or "Note Delay"
  lea     pt_audchan2temp+n_dmabit(pc),a0
  move.w  d0,(a0)            ;Set DMA channel2 bit
  move.b  d1,n_rtnsetchandma-n_dmabit(a0) ;Deactivate channel2 set routine for "Retrig Note" or "Note Delay"
  moveq   #DMAF_AUD2,d0      ;DMA bit for channel3
  move.b  d1,n_rtninitchandata-n_dmabit(a0) ;Deactivate channel2 init routine for "Retrig Note" or "Note Delay"
  lea     pt_audchan3temp+n_dmabit(pc),a0
  move.w  d0,(a0)            ;Set DMA channel3 bit
  move.b  d1,n_rtnsetchandma-n_dmabit(a0) ;Deactivate channel3 set routine for "Retrig Note" or "Note Delay"
  moveq   #DMAF_AUD3,d0      ;DMA bit for channel4
  move.b  d1,n_rtninitchandata-n_dmabit(a0) ;Deactivate channel3 init routine for "Retrig Note" or "Note Delay"
  lea     pt_audchan4temp+n_dmabit(pc),a0
  move.w  d0,(a0)            ;Set DMA channel4 bit
  move.b  d1,n_rtnsetchandma-n_dmabit(a0) ;Deactivate channel4 set routine for "Retrig Note" or "Note Delay"
  move.b  d1,n_rtninitchandata-n_dmabit(a0) ;Deactivate channel4 init routine for "Retrig Note" or "Note Delay"
  rts

; ** Get highest pattern number and initialize sample pointers table **
  CNOP 0,4
pt_ExamineSongStruc
  move.l  pt_SongDataPtr(a3),a0 ;Pointer to song data
  moveq	  #TRUE,d0           ;First pattern number
  move.b  pt_sd_numofpatt(a0),pt_SongLength(a3) ;Get number of patterns
  moveq	  #TRUE,d1           ;Highest pattern number
  lea	  pt_sd_pattpos(a0),a1 ;Pointer to table with pattern positions in song
  moveq   #pt_maxsongpos-1,d7 ;Maximum number of song positions
pt_InitLoop
  move.b  (a1)+,d0           ;Get pattern number out of song position table
  cmp.b	  d1,d0              ;Pattern number <= previous pattern number ?
  ble.s	  pt_InitSkip        ;Yes -> skip
  move.l  d0,d1              ;Save higher pattern number
pt_InitSkip
  dbf	  d7,pt_InitLoop
  addq.w  #1,d1              ;Decrease highest pattern number
  add.w   #pt_sd_sampleinfo+pt_si_samplelength,a0 ;First sample length
  lsl.w   #BYTESHIFTBITS,d1  ;*(pt_pattsize/8) = Offset points to end of last pattern
  moveq   #TRUE,d2           ;NULL to clear first word in sample data
  lea	  pt_sd_patterndata-pt_sd_id(a1,d1.w*8),a2 ;Skip MOD-ID and patterndata -> Pointer to first sample data in module
  lea	  pt_SampleStarts(pc),a1 ;Table for sample pointers
  moveq	  #pt_sampleinfo_SIZE,d1 ;Length of sample info structure in bytes
  moveq	  #pt_samplesnum-1,d7 ;Number of samples in module
pt_InitLoop2
  move.l  a2,(a1)+           ;Save pointer to sample data
  move.w  (a0),d0            ;Get sample length
  beq.s   pt_NoSample        ;If length = NULL -> skip
  add.w   d0,d0               ;*2 = Sample length in bytes
  move.w  d2,(a2)            ;Clear first word in sample data
  add.l	  d0,a2              ;Add sample length to get pointer to next sample data
pt_NoSample
  add.l	  d1,a0              ;Next sample info structure in module
  dbf	  d7,pt_InitLoop2
  rts

; ** Init pointers to fine tuning period tables **
  CNOP 0,4
pt_InitFtuPeriodTableStarts
  lea     pt_PeriodTable(pc),a0 ;Period table pointer, finetune=0
  lea     pt_FtuPeriodTableStarts(pc),a1 ;Table for period table pointers
  moveq   #pt_PeriodTableEnd-pt_PeriodTable,d0 ;Period table length in bytes
  moveq   #pt_finetunenum-1,d7 ;Number of finetune values
pt_InitFtuPerTabStartsLoop
  move.l  a0,(a1)+           ;Save pointer
  add.l   d0,a0              ;Pointer to next period table, finetune+n
  dbf     d7,pt_InitFtuPerTabStartsLoop
  rts



; ************************* Play music ***********************

; ** PlayMusic called by CIA-B timer A / vblank interrupt **
; ----------------------------------------------------------
; Constant registers
; a3 ... Base of variables
; a4 ... Base of CIA-A
; a5 ... Base of CIA-B
; a6 ... Base of custom chips
; d5 ... NULL longword for all clear operations
; d6 ... Mask out sample number / FALSE.b
  CNOP 0,4
pt_PlayMusic
  movem.l d0-d7/a0-a6,-(a7)
  lea     pt_Variables(pc),a3 ;Base of variables
  move.l  #_CIAB,a5          ;Base of CIA-B
  lea     _CIAA-_CIAB(a5),a4 ;Base of CIA-A
  move.l  #_CUSTOM,a6        ;Base of custom chips
  moveq   #TRUE,d5           ;Constant: NULL longword for all clear operations
  addq.w  #1,pt_Counter(a3)  ;Increment ticks counter
  move.w  #pt_cmdpermask,d6  ;Constant: Mask out sample number / FALSE.b
  move.w  pt_Counter(a3),d0  ;Get ticks
  add.w   #AUD0LCH,a6        ;Pointer to first audio channel address in CUSTOM CHIP space
  cmp.w	  pt_CurrSpeed(a3),d0 ;Ticks < speed ticks ?
  blo.s	  pt_NoNewNote       ;Yes -> skip
  move.w  d5,pt_Counter(a3)  ;If ticks >= speed ticks -> set back ticks counter = tick #1
  tst.b	  pt_PattDelayTime2(a3) ;Any pattern delay time2 ?
  beq	  pt_GetNewNote      ;If NULL -> skip
  bsr.s	  pt_NoNewAllChannels
  bra	  pt_Dskip

; ** No new note **
  CNOP 0,4
pt_NoNewNote
  bsr.s	  pt_NoNewAllChannels
  bra	  pt_NoNewPositionYet

; ** Check all audio channel for effect commands at ticks #2..#speed ticks **
  CNOP 0,4
pt_NoNewAllChannels
  lea	  pt_audchan1temp(pc),a2 ;Pointer to first channel temporary structure (see above)
  bsr.s	  pt_CheckEffects
  addq.w  #8,a6              ;Calculate CUSTOM CHIP pointer to next audio channel
  lea	  pt_audchan2temp(pc),a2 ;Pointer to second channel temporary structure (see above)
  addq.w  #8,a6
  bsr.s	  pt_CheckEffects
  addq.w  #8,a6
  lea	  pt_audchan3temp(pc),a2 ;Pointer to third channel temporary structure (see above)
  addq.w  #8,a6
  bsr.s	  pt_CheckEffects
  addq.w  #8,a6
  lea	  pt_audchan4temp(pc),a2 ;Pointer to fourth channel temporary structure (see above)
  addq.w  #8,a6
  bsr.s	  pt_CheckEffects

; ** Check all audio channels for effect command "Retrig Note" **
pt_RtnChkAllChannels
  tst.w   pt_RtnDMACONtemp(a3) ;"Retrig Note" or "Note Delay" used by one of the channels ?
  beq.s   pt_NoRtnSetTimer   ;NULL -> skip
  moveq   #CIACRBF_START,d0
  or.b    d0,CIACRB(a5)      ;Start CIA-B timer B for DMA wait
pt_NoRtnSetTimer
  rts

; ** Check audio channel for effect commands **
  CNOP 0,4
pt_CheckEffects
  bsr	  pt_UpdateInvert
  move.w  n_cmd(a2),d0       ;Get channel effect command
  and.w	  d6,d0              ;without lower nibble of sample number
  beq.s	  pt_ChkEfxPerNop    ;If no command -> skip
  lsr.w   #BYTESHIFTBITS,d0  ;0 "Arpeggio" ?
  beq.s	  pt_Arpeggio
  subq.b  #1,d0              ;1 "Portamento Up" ?
  beq	  pt_PortamentoUp
  subq.b  #1,d0              ;2 "Portamento Down" ?
  beq	  pt_PortamentoDown
  subq.b  #1,d0              ;3 "Tone Portamento" ?
  beq	  pt_TonePortamento
  subq.b  #1,d0              ;4 "Vibrato" ?
  beq	  pt_Vibrato
  subq.b  #1,d0              ;5 "Tone Portamento + Volume Slide" ?
  beq	  pt_TonePortaPlusVolSlide
  subq.b  #1,d0              ;6 "Vibrato + Volume Slide" ?
  beq	  pt_VibratoPlusVolSlide
  subq.b  #8,d0              ;E "Extended commands" ?
  beq	  pt_ExtCommands
pt_SetBack
  move.w  n_period(a2),6(a6) ;AUDxPER Set back period
  addq.b  #7,d0              ;7 "Tremolo" ?
  beq	  pt_Tremolo
  subq.b  #3,d0              ;A "Volume Slide" ?
  beq	  pt_VolumeSlide
  rts
  CNOP 0,4
pt_ChkEfxPerNop
  move.w  n_period(a2),6(a6) ;AUDxPER Set back period
  rts

; ** Effect command 0xy "Normal play" or "Arpeggio" **
  CNOP 0,4
pt_Arpeggio
  move.w  pt_Counter(a3),d0  ;Get ticks
pt_ArpDivLoop
  subq.w  #pt_ArpDiv,d0      ;Substract divisor from dividend
  bge.s   pt_ArpDivLoop      ;until dividend < divisor
  addq.w  #pt_ArpDiv,d0      ;Adjust division remainder
  subq.w  #1,d0              ;Remainder = $0001 = Add first halftone at tick #2 ?
  beq.s	  pt_Arpeggio1       ;Yes -> skip
  subq.w  #1,d0              ;Remainder = $0002 = Add second halftone at tick #3 ?
  beq.s	  pt_Arpeggio2       ;Yes -> skip
; ** Effect command 000 "Normal Play" 1st note **
pt_Arpeggio0
  move.w  n_period(a2),d2    ;Play note period at tick #1
pt_ArpeggioSet
  move.w  d2,6(a6)           ;AUDxPER Set new note period
  rts
; ** Effect command 0x0 "Arpeggio" 2nd note **
  CNOP 0,4
pt_Arpeggio1
  move.b  n_cmdlo(a2),d0     
  lsr.b	  #NIBBLESHIFTBITS,d0 ;Get command data: x-first halftone
  bra.s	  pt_ArpeggioFind
; ** Effect command 00y "Arpeggio" 3rd note **
  CNOP 0,4
pt_Arpeggio2
  moveq   #NIBBLEMASKLO,d0
  and.b   n_cmdlo(a2),d0     ;Get command data: y-second halftone
pt_ArpeggioFind
  move.w  n_period(a2),d2    ;Get note period
  moveq	  #TRUE,d7           ;NULL needed for longword access
  move.b  n_finetune(a2),d7  ;Get finetune value
  lea	  pt_FtuPeriodTableStarts(pc),a1 ;Pointer to finetune period table pointers
  move.l  (a1,d7.w*4),a1     ;Get period table address for given finetune value
  moveq   #((pt_PeriodTableEnd-pt_PeriodTable)/2)-1,d7 ;Number of periods
pt_ArpLoop
  cmp.w	  (a1)+,d2           ;Note period >= table note period ?
  dbhs	  d7,pt_ArpLoop      ;If not -> loop until counter = FALSE
pt_ArpFound
  move.w  -2(a1,d0.w*2),d2   ;Get note period + first or second halftone addition
  bra.s	  pt_ArpeggioSet

; ** Effect command E1x "Fine Portamento Up" **
  CNOP 0,4
pt_FinePortamentoUp
  moveq   #NIBBLEMASKLO,d0
  move.b  d0,pt_LowMask(a3)  ;Only lower nibble of mask
; ** Effect command 1xx "Portamento Up" **
pt_PortamentoUp
  move.b  n_cmdlo(a2),d0     ;Get command data: xx-upspeed
  move.w  n_period(a2),d2    ;Get note period
  and.b	  pt_LowMask(a3),d0  ;Use 4 or 8 bits of upspeed
  sub.w	  d0,d2              ;Note period - upspeed
  move.b  d6,pt_LowMask(a3)  ;Set back low mask to $ff
  cmp.w	  #pt_portminperiod,d2 ;Note period >= note period "B-3" ?
  bpl.s	  pt_PortaUpSkip     ;Yes -> skip
  moveq   #pt_portminperiod,d2 ;Set note period "B-3"
pt_PortaUpSkip
  move.w  d2,n_period(a2)    ;Save new note period
  move.w  d2,6(a6)           ;AUDxPER Set new note period
pt_PortaUpEnd
  rts

; ** Effect command E2x "Fine Portamento Down" **
  CNOP 0,4
pt_FinePortamentoDown
  moveq   #NIBBLEMASKLO,d0
  move.b  d0,pt_LowMask(a3)  ;Only lower nibble of mask
; ** Effect command 2xx "Portamento Down" **
pt_PortamentoDown
  move.b  n_cmdlo(a2),d0     ;Get command data: xx-downspeed
  move.w  n_period(a2),d2    ;Get note period
  and.b	  pt_LowMask(a3),d0  ;Use 4 or 8 bits of downspeed
  add.w	  d0,d2              ;Note period + downspeed
  move.b  d6,pt_LowMask(a3)  ;Set back low mask to $ff
  cmp.w	  #pt_portmaxperiod,d2 ;Note period < note period "C-1" ?
  bmi.s	  pt_PortaDownSkip   ;Yes -> skip
  move.w  #pt_portmaxperiod,d2 ;Set note period "C-1"
pt_PortaDownSkip
  move.w  d2,n_period(a2)    ;Save new note period
  move.w  d2,6(a6)           ;AUDxPER Set new note period
pt_PortaDownEnd
  rts

; ** Effect command 5xy "Tone Portamento + Volume Slide" **
  CNOP 0,4
pt_TonePortaPlusVolSlide
  bsr.s	  pt_TonePortaNoChange
  bra     pt_VolumeSlide

; ** Effect command 3xx "Tone Portamento" **
  CNOP 0,4
pt_TonePortamento
  move.b  n_cmdlo(a2),d0     ;Get command data: xx-up/down speed
  beq.s	  pt_TonePortaNoChange ;If NULL -> skip
  move.b  d0,n_toneportspeed(a2) ;Save up/down speed
  move.b  d5,n_cmdlo(a2)     ;Clear command data
pt_TonePortaNoChange
  move.w  n_wantedperiod(a2),d2 ;Get wanted note period
  beq.s	  pt_TonePortaEnd    ;If NULL -> skip
  move.w  n_period(a2),d3    ;Get note period
  move.b  n_toneportspeed(a2),d0 ;Get up/down speed
  tst.b	  n_toneportdirec(a2) ;Check tone portamento direction
  bne.s	  pt_TonePortaUp     ;If not NULL -> up speed
pt_TonePortaDown
  add.w   d0,d3              ;Note period + down speed
  cmp.w   d3,d2              ;Wanted note period > note period ?
  bgt.s	  pt_TonePortaSetPer ;Yes -> skip
  move.w  d2,d3              ;Note period = wanted note period
  moveq   #TRUE,d2           ;Clear wanted note period
  bra.s	  pt_TonePortaSetPer
  CNOP 0,4
pt_TonePortaUp
  sub.w   d0,d3              ;Note period - up speed
  cmp.w	  d3,d2              ;Wanted note period < note period ?
  blt.s	  pt_TonePortaSetPer ;Yes -> skip
  move.w  d2,d3              ;Note period = wanted note period
  moveq   #TRUE,d2           ;Clear wanted note period
pt_TonePortaSetPer
  move.w  d2,n_wantedperiod(a2) ;Save new state
  moveq   #NIBBLEMASKLO,d0
  move.w  d3,n_period(a2)    ;Save new note period
  and.b   n_glissinvert(a2),d0 ;Get glissando state
  beq.s	  pt_GlissSkip       ;If NULL -> skip
  move.b  n_finetune(a2),d0  ;Get finetune value
  lea	  pt_FtuPeriodTableStarts(pc),a1 ;Pointer to finetune period table pointers
  move.l  (a1,d0.w*4),a1     ;Get period table address for given finetune value
  moveq   #((pt_PeriodTableEnd-pt_PeriodTable)/2)-1,d7 ;Number of periods
pt_GlissLoop
  cmp.w	  (a1)+,d3           ;Note period >= table note period ?
  dbhs	  d7,pt_GlissLoop    ;If not -> loop until counter = FALSE
pt_GlissFound
  move.w  -2(a1),d3          ;Get note period from period table
pt_GlissSkip
  move.w  d3,6(a6)           ;AUDxPER Set new period
pt_TonePortaEnd
  rts

; ** Effect command 4xy "Vibrato" **
  CNOP 0,4
pt_Vibrato
  move.b  n_cmdlo(a2),d0     ;Get command data: x-speed y-depth
  beq.s	  pt_Vibrato2        ;If NULL -> skip
  move.b  n_vibratocmd(a2),d2 ;Get vibrato command data
  and.b	  #NIBBLEMASKLO,d0   ;Get command data: y-depth
  beq.s	  pt_VibSkip         ;If NULL -> skip
  and.b	  #NIBBLEMASKHI,d2   ;Clear old depth
  or.b	  d0,d2              ;Set new depth in vibrato command data
pt_VibSkip
  moveq   #-(-NIBBLEMASKHI&BYTEMASK),d0
  and.b   n_cmdlo(a2),d0     ;Get command data: x-speed
  beq.s	  pt_VibSkip2        ;If NULL -> skip
  and.b	  #NIBBLEMASKLO,d2   ;Clear old speed
  or.b	  d0,d2              ;Set new speed in vibrato command data
pt_VibSkip2
  move.b  d2,n_vibratocmd(a2) ;Save new vibrato command data
pt_Vibrato2
  lea	  pt_VibTreSineTable(pc),a1 ;Pointer to vibrato modulation table
  move.b  n_vibratopos(a2),d0 ;Get vibrato position
  lsr.b	  #2,d0              ;/4
  moveq   #pt_wavetypemask,d2
  and.w	  #$001f,d0          ;Mask out vibrato position overflow
  and.b	  n_wavecontrol(a2),d2 ;Get vibrato waveform type
  beq.s	  pt_VibSine         ;If NULL -> vibrato waveform 0-sine
  lsl.b   #3,d0              ;*8
  subq.b  #1,d2              ;Vibrato waveform 1-ramp down ?
  beq.s	  pt_VibRampdown     ;Yes -> skip
pt_VibSquare
  moveq   #TRUE,d2           ;NULL for word access
  not.b   d2                 ;255 = Square amplitude
  bra.s	  pt_VibSet
  CNOP 0,4
pt_VibRampdown
  tst.b	  n_vibratopos(a2)   ;Vibrato position positive ?
  bpl.s	  pt_VibRampdown2    ;Yes -> skip
  moveq   #TRUE,d2           ;NULL for word access
  not.b   d2                 ;255 = Rampdown amplitude
  sub.b	  d0,d2              ;Reduce rampdown amplitude
  bra.s	  pt_VibSet
  CNOP 0,4
pt_VibRampdown2
  move.b  d0,d2              ;Rampdown amplitude
  bra.s	  pt_VibSet
  CNOP 0,4
pt_VibSine
  move.b  (a1,d0.w),d2       ;Get sine amplitude
pt_VibSet
  moveq   #NIBBLEMASKLO,d0
  and.b   n_vibratocmd(a2),d0 ;Get depth
  mulu.w  d0,d2              ;depth * amplitude
  move.w  n_period(a2),d0    ;Get note period
  lsr.w	  #7,d2              ;Period amplitude = (depth * amplitude) / 128
  tst.b	  n_vibratopos(a2)   ;Vibrato position negative ?
  bmi.s	  pt_VibratoNeg      ;Yes -> skip
  add.w	  d2,d0              ;Note period + period amplitude
  bra.s	  pt_Vibrato3
  CNOP 0,4
pt_VibratoNeg
  sub.w	  d2,d0              ;Note period - period amplitude
pt_Vibrato3
  move.b  n_vibratocmd(a2),d2 ;Get vibrato command data
  lsr.b	  #2,d2              ;/4
  move.w  d0,6(a6)           ;AUDxPER Set new note period
  and.b	  #$3c,d2            ;Mask out vibrato position overflow
  add.b	  d2,n_vibratopos(a2) ;Next vibrato position
  rts

; ** Effect command 6xy "Vibrato + Volume Slide" **
  CNOP 0,4
pt_VibratoPlusVolSlide
  bsr.s	  pt_Vibrato2
  bra  	  pt_VolumeSlide

; ** Check channel for effect commands Exy "Extended commands" **
  CNOP 0,4
pt_ExtCommands
  move.b  n_cmdlo(a2),d0     ;Get channel extended effect command number
  lsr.b	  #NIBBLESHIFTBITS,d0
  subq.b  #8,d0              ;0-8 ?
  ble.s   pt_ExtCommandsEnd
  subq.b  #1,d0              ;9 "Retrig Note" ?
  beq	  pt_RetrigNote
  subq.b  #3,d0              ;C "Note Cut" ?
  beq	  pt_NoteCut
  subq.b  #1,d0              ;D "Note Delay" ?
  beq	  pt_NoteDelay
pt_ExtCommandsEnd
  rts

; ** Effect command 7xy "Tremolo" **
  CNOP 0,4
pt_Tremolo
  move.b  n_cmdlo(a2),d0     ;Get command data: x-speed y-depth
  beq.s	  pt_Tremolo2        ;If NULL -> skip
  move.b  n_tremolocmd(a2),d2 ;Get tremolo command data
  and.b	  #NIBBLEMASKLO,d0   ;Get command data: y-depth
  beq.s	  pt_TreSkip         ;If NULL -> skip
  and.b	  #NIBBLEMASKHI,d2   ;Clear old depth
  or.b	  d0,d2              ;Set new depth in tremolo command data
pt_TreSkip
  moveq   #-(-NIBBLEMASKHI&BYTEMASK),d0
  and.b   n_cmdlo(a2),d0     ;Get command data: x-speed
  beq.s	  pt_TreSkip2        ;If NULL -> skip
  and.b	  #NIBBLEMASKLO,d2   ;Clear old speed
  or.b	  d0,d2              ;Set new speed in tremolo command data
pt_TreSkip2
  move.b  d2,n_tremolocmd(a2) ;Save new tremolo command data
pt_Tremolo2
  lea	  pt_VibTreSineTable(pc),a1 ;Pointer to tremolo modulation table
  move.b  n_tremolopos(a2),d0 ;Get tremolo position
  lsr.b	  #2,d0              ;/4
  move.b  n_wavecontrol(a2),d2 ;Get tremolo waveform
  lsr.b	  #NIBBLESHIFTBITS,d2 ;Move upper nibble to lower position
  and.w	  #$001f,d0          ;Mask out tremolo position overflow
  and.w	  #pt_wavetypemask,d2 ;Get tremolo waveform type
  beq.s	  pt_TreSine         ;If tremolo waveform 0-sine -> skip
  lsl.b   #3,d0              ;*8
  subq.b  #1,d2              ;Tremolo waveform 1-ramp down ?
  beq.s	  pt_TreRampdown     ;Yes -> skip
pt_TreSquare
  moveq   #TRUE,d2           ;NULL for word access
  not.b   d2                 ;255 = Square amplitude
  bra.s	  pt_TreSet
  CNOP 0,4
pt_TreRampdown
  tst.b	  n_tremolopos(a2)   ;Tremolo position positiv ?
  bpl.s	  pt_TreRampdown2    ;Yes -> skip
  moveq   #TRUE,d2           ;NULL for word access
  not.b   d2                 ;255 = Rampdown amplitude
  sub.b	  d0,d2              ;Reduce rampdown amplitude
  bra.s	  pt_TreSet
  CNOP 0,4
pt_TreRampdown2
  move.b  d0,d2              ;Rampdown amplitude
  bra.s	  pt_TreSet
  CNOP 0,4
pt_TreSine
  move.b  (a1,d0.w),d2       ;Get sine amplitude
pt_TreSet
  moveq   #NIBBLEMASKLO,d0
  and.b   n_tremolocmd(a2),d0 ;Get depth
  mulu.w  d0,d2              ;depth * amplitude
  move.b  n_volume(a2),d0    ;Get volume
  lsr.w	  #6,d2              ;Volume amplitude = (depth * amplitude) / 64
  tst.b	  n_tremolopos(a2)   ;Tremolo position negative ?
  bmi.s	  pt_TremoloNeg      ;Yes -> skip
  add.w	  d2,d0              ;Volume + volume amplitude
  bra.s	  pt_Tremolo3
  CNOP 0,4
pt_TremoloNeg
  sub.w	  d2,d0              ;Volume - volume amplitude
pt_Tremolo3
  bpl.s	  pt_TremoloSkip     ;If new volume >= NULL -> skip
  moveq   #pt_minvolume,d0   ;Set minimum volume
pt_TremoloSkip
  cmp.w	  #pt_maxvolume,d0   ;New volume <= maximum volume ?
  bls.s	  pt_TremoloOk       ;Yes -> skip
  moveq   #pt_maxvolume,d0   ;Set maximum volume
pt_TremoloOk
  move.b  n_tremolocmd(a2),d2 ;Get tremolo command data
  lsr.b	  #2,d2              ;/4
  move.w  d0,8(a6)           ;AUDxVOL Set new volume
  and.b	  #$3c,d2            ;Mask out tremolo position overflow
  add.b	  d2,n_tremolopos(a2) ;Next tremolo position
  rts

; ** Effect command EAx "Fine Volume Slide Up" **
  CNOP 0,4
pt_FineVolumeSlideUp
  moveq   #NIBBLEMASKLO,d0
  and.b   n_cmdlo(a2),d0     ;Get command data: y-downspeed
  bra.s   pt_VolSlideUp
; ** Effect command Axy "Volume Slide"
  CNOP 0,4
pt_VolumeSlide
  move.b  n_cmdlo(a2),d0     
  lsr.b	  #NIBBLESHIFTBITS,d0 ;Get command data: x-upspeed
  beq.s	  pt_VolSlideDown    ;If NULL -> skip
; ** Effect command Ax0 "Volume Slide Up"
pt_VolSlideUp
  moveq	  #TRUE,d2           ;NULL needed for word access
  move.b  n_volume(a2),d2    ;Get volume
  add.b	  d0,d2              ;Volume + upspeed
  cmp.b	  #pt_maxvolume,d2   ;volume < maximum volume ?
  bls.s   pt_VsuSkip         ;Yes -> skip
  moveq   #pt_maxvolume,d2   ;Set maximum volume
pt_VsuSkip
  move.b  d2,n_volume(a2)    ;Save new volume
  move.w  d2,8(a6)           ;AUDxVOL Set new volume
pt_VSUEnd
  rts
; ** Effect command EBy "Fine Volume Slide Down" **
  CNOP 0,4
pt_FineVolumeSlideDown
; ** Effect command A0y "Volume Slide Down"
pt_VolSlideDown
  moveq   #NIBBLEMASKLO,d0
  and.b   n_cmdlo(a2),d0     ;Get command data: y-downspeed
  moveq	  #TRUE,d2           ;NULL needed for word access
  move.b  n_volume(a2),d2    ;Get volume
  sub.b	  d0,d2              ;Volume - downspeed
  bpl.s	  pt_VsdSkip         ;If >= NULL -> skip
  moveq   #pt_minvolume,d2   ;Set minimum volume
pt_VsdSkip
  move.b  d2,n_volume(a2)    ;Save new volume
  move.w  d2,8(a6)           ;AUDxVOL Set new volume
pt_VsdEnd
  rts

; ** Get new note and pattern position at tick #1 **
  CNOP 0,4
pt_GetNewNote
  move.l  pt_SongDataPtr(a3),a0 ;Pointer to module
  move.w  pt_SongPosition(a3),d0 ;Get song position
  moveq	  #TRUE,d1           ;NULL needed for word access
  move.b  (pt_sd_pattpos,a0,d0.w),d1 ;Get pattern number in song position table
  lsl.w   #BYTESHIFTBITS,d1  ;*pt_pattsize/4 = Pattern offset
  add.w	  pt_PatternPosition(a3),d1 ;Add pattern position
  move.w  d5,pt_DMACONtemp(a3) ;Clear DMA bits
  lea	  pt_audchan1temp(pc),a2 ;Pointer to audio channel temporary structure
  bsr.s   pt_PlayVoice
  addq.w  #8,a6              ;Next audio channel CUSTOM address
  lea	  pt_audchan2temp(pc),a2
  addq.w  #8,a6
  bsr.s   pt_PlayVoice
  addq.w  #8,a6
  lea	  pt_audchan3temp(pc),a2
  addq.w  #8,a6
  bsr.s   pt_PlayVoice
  addq.w  #8,a6
  lea	  pt_audchan4temp(pc),a2
  addq.w  #8,a6
  bsr.s   pt_PlayVoice
  bra     pt_SetDMA

; ** Get new note data **
  CNOP 0,4
pt_PlayVoice
  tst.l	  (a2)               ;Get last note data
  bne.s	  pt_PlvSkip         ;If note period/effect command -> skip
  move.w  n_period(a2),6(a6) ;AUDxPER Set note period
pt_PlvSkip
  moveq   #TRUE,d2           ;NULL needed for word access
  move.l  (pt_sd_patterndata,a0,d1.l*4),(a2) ;Get new note data from pattern
  moveq   #-(-NIBBLEMASKHI&BYTEMASK),d0 ;Mask for upper nibble of sample number
  move.b  n_cmd(a2),d2       
  lsr.b	  #NIBBLESHIFTBITS,d2 ;Get lower nibble of sample number
  and.b   (a2),d0            ;Get upper nibble of sample number
  addq.w  #pt_noteinfo_SIZE/4,d1 ;Next channel data
  or.b	  d0,d2              ;Get whole sample number
  beq.s	  pt_SetRegisters    ;If NULL -> skip
  subq.w  #1,d2              ;x = sample number -1
  lea	  pt_SampleStarts(pc),a1 ;Pointer to sample pointers table
  move.w  d2,d3              ;Save x
  move.l  (a1,d2.w*4),a1     ;Get sample data pointer
  lsl.w   #NIBBLESHIFTBITS,d2 ;x*16
  move.l  a1,n_start(a2)     ;Save sample start
  sub.w   d3,d2              ;(x*16)-x = sample info structure length in words
  movem.w pt_sd_sampleinfo+pt_si_samplelength(a0,d2.w*2),d0/d2-d4 ;length, finetune, volume, repeat point, repeat length
  move.w  d0,n_reallength(a2) ;Save real sample length
  move.w  d2,n_finetune(a2)  ;Save finetune and sample volume
  ext.w   d2                 ;Extend lower byte to word
  move.w  d2,8(a6)	     ;AUDxVOL Set new volume
  cmp.w   #1,d4              ;Repeat length = 1 word ?
  beq.s	  pt_NoLoopSample    ;Yes -> skip
pt_LoopSample
  move.w  d3,d0              ;Save repeat point
  add.w   d3,d3              ;*2 = repeat point in bytes
  add.w	  d4,d0              ;Add repeat length
  add.l	  d3,a1	             ;Add repeat point
pt_NoLoopSample
  move.w  d0,n_length(a2)    ;Save length
  move.w  d4,n_replen(a2)    ;Save repeat length
  move.l  a1,n_loopstart(a2) ;Save loop start
  move.l  a1,n_wavestart(a2) ;Save wave start

pt_SetRegisters
  move.w  (a2),d3            ;Get note period from pattern position
  and.w	  d6,d3              ;without higher nibble of sample number
  beq	  pt_CheckMoreEffects ;If no note period -> skip
  move.w  n_cmd(a2),d4       ;Get effect command
  and.w	  #pt_ecmdnummask,d4 ;without lower nibble of sample number and command data
  beq.s   pt_SetPeriod       ;If no effect command -> skip
  cmp.w	  #$0e50,d4          ;E5 "Set finetune" ?
  beq.s	  pt_DoSetSampleFinetune
  moveq   #NIBBLEMASKLO,d0
  and.b   n_cmd(a2),d0       ;Get channel effect command number without lower nibble of sample nu<mber
  subq.b  #3,d0              ;3 "Tone Portamento" ?
  beq.s	  pt_ChkTonePorta
  subq.b  #2,d0              ;5 "Tone Portamento + Volume Slide" ?
  beq.s	  pt_ChkTonePorta
  subq.b  #4,d0              ;9 "Set Sample Offset" ?
  bne.s	  pt_SetPeriod
  bsr     pt_SetSampleOffset

pt_SetPeriod
  moveq   #TRUE,d0           ;NULL needed for word access
  move.b  n_finetune(a2),d0  ;Get finetune
  beq.s   pt_NoFinetune      ;If NULL -> skip
  lea	  pt_PeriodTable(pc),a1 ;Pointer to periods table
  moveq   #((pt_PeriodTableEnd-pt_PeriodTable)/2)-1,d7 ;Number of periods
pt_FtuLoop
  cmp.w	  (a1)+,d3           ;Note period >= table note period ?
  dbhs	  d7,pt_FtuLoop      ;If not -> loop until counter = FALSE
pt_FtuFound
  lea	  pt_FtuPeriodTableStarts(pc),a1 ;Pointer to finetune period table pointers
  move.l  (a1,d0.w*4),a1     ;Get period table address for given finetune value
  moveq   #((pt_PeriodTableEnd-pt_PeriodTable)/2)-1,d0
  sub.w   d7,d0              ;Number of periods - loop counter = offset in periods table
  move.w  (a1,d0.w*2),d3     ;Get new note period from table
pt_NoFinetune
  move.w  d3,n_period(a2)    ;Save new note period
  cmp.w   #$0ed0,d4          ;ED "Note Delay" ?
  beq	  pt_CheckMoreEffects
  
  move.w  n_dmabit(a2),d0    ;Get audio channel DMA bit
  or.w	  d0,pt_DMACONtemp(a3) ;Set audio channel DMA bit
  move.w  d0,_CUSTOM+DMACON  ;Audio channel DMA off
  btst	  #pt_vibnoretrigbit,n_wavecontrol(a2) ;Vibrato type 4-no retrig waveform ?
  bne.s	  pt_VibNoC          ;Yes -> skip
  move.b  d5,n_vibratopos(a2) ;Clear vibrato position
pt_VibNoC
  btst	  #pt_trenoretrigbit,n_wavecontrol(a2) ;Tremolo type 4-no retrig waveform ?
  bne.s	  pt_TreNoC          ;Yes -> skip
  move.b  d5,n_tremolopos(a2) ;Clear tremolo position
pt_TreNoC
  move.l  n_start(a2),(a6)   ;AUDxLCH Set sample start
  move.l  n_length(a2),4(a6) ;AUDxLEN Set length & new note period
  bra.s	  pt_CheckMoreEffects

; ** Effect command E5x "Set Sample Finetune" used **
  CNOP 0,4
pt_DoSetSampleFinetune
  bsr     pt_SetSampleFinetune
  bra.s   pt_SetPeriod

; ** Effect command 3 "Tone Portamento" or 5 "Tone Portamento + Volume Slide" used **
  CNOP 0,4
pt_ChkTonePorta
  bsr.s	  pt_SetTonePorta
  bra.s	  pt_CheckMoreEffects

  CNOP 0,4
pt_SetTonePorta
  move.b  n_finetune(a2),d0  ;Get finetune value
  beq.s   pt_StpNoFinetune   ;If NULL -> skip
  lea	  pt_FtuPeriodTableStarts(pc),a1 ;Pointer to finetune offset periods table
  move.l  (a1,d0.w*4),a1     ;Get period table address
  move.l  a1,d2              ;Save period table address
  moveq   #((pt_PeriodTableEnd-pt_PeriodTable)/2)-1,d7 ;Number of periods
pt_StpLoop
  cmp.w	  (a1)+,d3           ;Note period >= table note period ?
  dbhs	  d7,pt_StpLoop      ;If not -> loop until counter = FALSE
  bhs.s   pt_StpFound        ;If found -> skip
  moveq	  #TRUE,d7           ;Last note period in table
pt_StpFound
  moveq   #((pt_PeriodTableEnd-pt_PeriodTable)/2)-1,d0 ;Number of periods
  sub.w   d7,d0              ;Offset in period table
  move.l  d2,a1              ;Get period table address
  moveq   #NIBBLESIGNMASK,d2 ;Mask for sign bit in nibble
  and.b   n_finetune(a2),d2  ;Sign bit for negative nibble value set ?
  beq.s	  pt_StpGoss         ;If NULL -> skip
  tst.w	  d0                 ;Counter = NULL ?
  beq.s	  pt_StpGoss         ;Yes -> skip
  subq.w  #1,d0              ;Increment counter
pt_StpGoss
  move.w  (a1,d0.w*2),d3     ;Get table note period
pt_StpNoFinetune
  move.w  d3,n_wantedperiod(a2) ;and save as wanted note period
  move.b  d5,n_toneportdirec(a2) ;Clear tone port direction
  cmp.w	  n_period(a2),d3    ;Check wanted note period
  beq.s	  pt_ClearTonePorta  ;If wanted note period = note period -> stop tone portamento
  bgt.s   pt_StpEnd          ;If wanted note period > note period -> skip
  moveq   #1,d0
  move.b  d0,n_toneportdirec(a2) ;If wanted note period < note period -> Set tone portamento direction = 1
pt_StpEnd
  rts
  CNOP 0,4
pt_ClearTonePorta
  move.w  d5,n_wantedperiod(a2) ;Clear wanted note period
  rts

; ** Check audio channel for more effect commands at tick #1 **
  CNOP 0,4
pt_CheckMoreEffects
  bsr	  pt_UpdateInvert
  moveq   #pt_cmdnummask,d0
  and.b   n_cmd(a2),d0       ;Get channel effect command number without lower nibble of sample nu<mber
  subq.b  #8,d0              ;0..8 ?
  ble.s   pt_ChkMoreEfxPerNop ;Yes -> skip
  subq.b  #1,d0              ;9 "Set Sample Offset" ?
  beq.s	  pt_SetSampleOffset
  subq.b  #2,d0              ;B "Position Jump" ?
  beq.s	  pt_PositionJump
  subq.b  #1,d0              ;C "Set Volume" ?
  beq.s	  pt_SetVolume
  subq.b  #1,d0              ;D "Pattern Break" ?
  beq.s	  pt_PatternBreak
  subq.b  #1,d0              ;E "Extended commands" ?
  beq	  pt_MoreExtCommands
  subq.b  #1,d0              ;F "Set Speed" ?
  beq	  pt_SetSpeed
pt_ChkMoreEfxPerNop
  move.w  n_period(a2),6(a6) ;AUDxPER Set note period
  rts

; ** Effect command 9xx "Set Sample Offset" **
  CNOP 0,4
pt_SetSampleOffset
  move.b  n_cmdlo(a2),d0     ;Get command data: xx-sample offset
  beq.s	  pt_SetSoNoNew      ;If NULL -> skip
  move.b  d0,n_sampleoffset(a2) ;Save new sample offset
pt_SetSoNoNew
  move.b  n_sampleoffset(a2),d0 ;Get sample offset
  lsl.w   #7,d0              ;offset * 128
  cmp.w	  n_length(a2),d0    ;offset * 128 >= length ?
  bge.s	  pt_SetSoSkip       ;Yes -> skip
  sub.w	  d0,n_length(a2)    ;length - offset
  add.w   d0,d0              ;*2 = offset in bytes
  move.l  n_start(a2),a1     ;Get sample start
  add.l   d0,a1              ;sample start + offset
  move.l  a1,n_start(a2)     ;Save new sample start
  move.w  d5,(a1)            ;Clear first word in sample data
  rts
  CNOP 0,4
pt_SetSoSkip
  moveq   #1,d0
  move.w  d0,n_length(a2)    ;Set length = 1 Word
  rts

; ** Effect command Bxx "Position Jump" **
  CNOP 0,4
pt_PositionJump
  move.b  n_cmdlo(a2),d0     ;Get command data: xx-song position
  subq.b  #1,d0              ;Decrement song position
  move.w  d0,pt_SongPosition(a3) ;Save new song position
pt_PJ2
  move.b  d5,pt_PBreakPosition(a3) ;Clear pattern break position
  move.b  d6,pt_PosJumpFlag(a3) ;Position jump flag = FALSE
  rts

; ** Effect command Cxx "Set Volume" **
  CNOP 0,4
pt_SetVolume
  move.b  n_cmdlo(a2),d0     ;Get command data: xx-volume
  cmp.b	  #pt_maxvolume,d0   ;volume <= maximum volume ?
  bls.s	  pt_MaxVolOk        ;Yes -> skip
  moveq	  #pt_maxvolume,d0   ;Set maximum volume
pt_MaxVolOk
  move.b  d0,n_volume(a2)    ;Save new volume
  move.w  d0,8(a6)           ;AUDxVOL Set new volume
  rts

; ** Effect command Dxx "Pattern Break" **
  CNOP 0,4
pt_PatternBreak
  move.b  n_cmdlo(a2),d0     ;Get command data: xx-break position (decimal)
  moveq   #NIBBLEMASKLO,d2
  and.b   d0,d2              ;Only lower nibble digits = 0..9
  lsr.b	  #NIBBLESHIFTBITS,d0 ;Move upper nibble to lower position
  move.b  d0,d7              ;Upper nibble *10 = digits 10..60
  lsl.b   #3,d0
  add.b   d7,d7
  add.b   d7,d0
  add.b	  d2,d0              ;Get decimal number
  cmp.b	  #pt_maxpattpos-1,d0 ;Break position > last position in pattern ?
  bhi.s	  pt_PJ2             ;Yes -> no pattern break
  move.b  d0,pt_PBreakPosition(a3) ;Save new pattern break position
  move.b  d6,pt_PosJumpFlag(a3) ;Position jump flag = FALSE
  rts

; ** Check channel for effect commands Exy "Extended commands" **
  CNOP 0,4
pt_MoreExtCommands
  move.b  n_cmdlo(a2),d0     ;Get channel extended effect command number
  lsr.b	  #NIBBLESHIFTBITS,d0 ;0 "Set Filter" ?
  beq.s	  pt_SetFilter
  subq.b  #1,d0              ;1 "Fine Portamento Up" ?
  beq	  pt_FinePortamentoUp
  subq.b  #1,d0              ;2 "Fine Portamento Down" ?
  beq	  pt_FinePortamentoDown
  subq.b  #1,d0              ;3 "Set Glissando Control" ?
  beq.s	  pt_SetGlissandoControl
  subq.b  #1,d0              ;4 "Set Vibrato Waveform" ?
  beq.s	  pt_SetVibratoWaveform
  subq.b  #1,d0              ;5 "Set Sample Finetune" ?
  beq.s	  pt_SetSampleFinetune
  subq.b  #1,d0              ;6 "Jump to Loop" ?
  beq	  pt_JumpToLoop
  subq.b  #1,d0              ;7 "Set Temolo Control" ?
  beq	  pt_SetTremoloWaveform
  subq.b  #2,d0              ;9 "Retrig Note" ?
  beq	  pt_RetrigNote
  subq.b  #1,d0              ;A "Fine Volume Slide Up" ?
  beq	  pt_FineVolumeSlideUp
  subq.b  #1,d0              ;B "Fine Volume Slide Down" ?
  beq	  pt_FineVolumeSlideDown
  subq.b  #1,d0              ;C "Note Cut" ?
  beq	  pt_NoteCut
  subq.b  #1,d0              ;D "Note Delay" ?
  beq	  pt_NoteDelay
  subq.b  #1,d0              ;E "Pattern Delay" ?
  beq	  pt_PatternDelay
  subq.b  #1,d0              ;F "Invert Loop" ?
  beq	  pt_InvertLoop
  rts

; ** Effect command E0x "Set Filter" **
  CNOP 0,4
pt_SetFilter
  moveq   #1,d0
  and.b   n_cmdlo(a2),d0     ;Get command data: 0-filter on 1-filter off
  bne.s   pt_FilterOff       ;If 1-filter off -> skip
pt_FilterOn
  moveq   #-(-~CIAF_LED&BYTEMASK),d0
  and.b   d0,(a4)            ;Turn filter on
  rts
  CNOP 0,4
pt_FilterOff
  moveq   #CIAF_LED,d0
  or.b    d0,(a4)            ;Turn filter off
  rts

; ** Effect command E3x "Set Glissando Control" **
  CNOP 0,4
pt_SetGlissandoControl
  moveq   #-(-NIBBLEMASKHI&BYTEMASK),d2
  and.b   n_glissinvert(a2),d2 ;Clear old glissando state lower nibble
  moveq   #NIBBLEMASKLO,d0
  and.b   n_cmdlo(a2),d0     ;Get command data: glissando state 0-off 1-on
  or.b    d0,d2              ;Set new glissando state
  move.b  d2,n_glissinvert(a2) ;Save new glissando state
  rts

; ** Effect command E4x "Set Vibrato Waveform" **
; * Vibrato waveform type values *
; 0 - sine (default)
; 4  (without retrigger)
; 1 - ramp down
; 5  (without retrigger)
; 2 - square
; 6  (without retrigger)
  CNOP 0,4
pt_SetVibratoWaveform
  moveq   #-(-NIBBLEMASKHI&BYTEMASK),d2
  and.b   n_wavecontrol(a2),d2 ;Clear old vibrato waveform
  moveq   #NIBBLEMASKLO,d0
  and.b   n_cmdlo(a2),d0     ;Get command data: vibrato waveform 0-sine 1-ramp down 2-square
  or.b    d0,d2              ;Set new vibrato waveform
  move.b  d2,n_wavecontrol(a2) ;Save new vibrato waveform
  rts

; ** Effect command E5x "Set Sample Finetune" **
  CNOP 0,4
pt_SetSampleFinetune
  moveq   #NIBBLEMASKLO,d0
  and.b   n_cmdlo(a2),d0     ;Get command data: new finetune value
  move.b  d0,n_finetune(a2)  ;Set new finetune value
  rts

; ** Effect command E6x "Jump to Loop" **
  CNOP 0,4
pt_JumpToLoop
  moveq   #NIBBLEMASKLO,d0
  and.b   n_cmdlo(a2),d0     ;Get command data: x-times
  beq.s	  pt_SetLoop         ;If NULL -> set loop
  tst.b	  n_loopcount(a2)    ;Get loop counter
  beq.s	  pt_JmpLoopCnt      ;If NULL -> set counter
  subq.b  #1,n_loopcount(a2) ;Decrease loop counter
  beq.s	  pt_JmpLoopEnd      ;If NULL -> skip
pt_JmpLoop
  move.b  n_pattpos(a2),pt_PBreakPosition(a3) ;Save pattern break position
  move.b  d6,pt_PBreakFlag(a3) ;pattern break flag = FALSE
pt_JmpLoopEnd
  rts
  CNOP 0,4
pt_JmpLoopCnt
  move.b  d0,n_loopcount(a2) ;Save times in loop counter
  bra.s	  pt_JmpLoop
  CNOP 0,4
pt_SetLoop
  move.w  pt_PatternPosition(a3),d0 ;Get pattern position
  lsr.w   #2,d0              ;/(pt_pattposdata_SIZE/4)
  move.b  d0,n_pattpos(a2)   ;Save pattern position
  rts

; ** Effect command E7x "Set Tremolo Waveform" **
; * Tremolo waveform type values *
; 0 - sine (default)
; 4  (without retrigger)
; 1 - ramp down
; 5  (without retrigger)
; 2 - square
; 6  (without retrigger)
  CNOP 0,4
pt_SetTremoloWaveform
  move.b  n_cmdlo(a2),d0     ;Get command data: tremolo waveform 0-sine 1-ramp down 2-square
  moveq   #NIBBLEMASKLO,d2
  and.b   n_wavecontrol(a2),d2 ;Clear old tremolo waveform
  lsl.b   #NIBBLESHIFTBITS,d0 ;Move tremolo waveform to upper nibble
  or.b    d0,d2              ;Set new tremolo waveform
  move.b  d2,n_wavecontrol(a2) ;Save new tremolo waveform
  rts

; ** Effect command E9x "Retrig Note" **
  CNOP 0,4
pt_RetrigNote
  moveq   #NIBBLEMASKLO,d0
  and.b   n_cmdlo(a2),d0     ;Get command data: x-blanks
  beq.s	  pt_RtnEnd          ;If NULL -> skip
  move.w  pt_Counter(a3),d2  ;Get ticks
  bne.s	  pt_RtnSkip         ;If not tick #1 -> skip
  move.w  (a2),d7            ;Get note period from pattern position
  and.w	  d6,d7              ;Only 12 bits note period
  bne.s	  pt_RtnEnd          ;If note period -> skip
pt_RtnSkip
  sub.w   d0,d2              ;Substract divisor from dividend
  bge.s   pt_RtnSkip         ;until dividend < divisor
  add.w   d0,d2              ;Adjust division remainder
  bne.s	  pt_RtnEnd          ;If blanks not ticks -> skip
pt_DoRetrig
  move.w  n_dmabit(a2),d0    ;Get audio channel DMA bit
  or.w    d0,pt_RtnDMACONtemp(a3) ;Set effect "Retrig Note" or "Note Delay" for audio channel
  move.b  d5,n_rtnsetchandma(a2) ;Activate interrupt set routine
  move.w  d0,_CUSTOM+DMACON  ;Audio channel DMA off
  move.l  n_start(a2),(a6)   ;AUDxLCH Set sample start
  move.w  n_length(a2),4(a6) ;AUDxLEN Set length
pt_RtnEnd
  rts

; ** Effect command ECx "Note Cut" **
  CNOP 0,4
pt_NoteCut
  moveq   #NIBBLEMASKLO,d0
  and.b   n_cmdlo(a2),d0     ;Get command data: x-blanks
  cmp.w	  pt_Counter(a3),d0  ;blanks = ticks ?
  bne.s	  pt_NoteCutEnd      ;No -> skip
  move.b  d5,n_volume(a2)    ;Clear volume
  move.w  d5,8(a6)           ;AUDxVOL Clear volume
pt_NoteCutEnd
  rts

; ** Effect command EDx "Note Delay" **
  CNOP 0,4
pt_NoteDelay
  moveq   #NIBBLEMASKLO,d0
  and.b   n_cmdlo(a2),d0     ;Get command data: x-blanks
  cmp.w	  pt_Counter(a3),d0  ;blanks = ticks ?
  bne.s	  pt_NoteDelayEnd    ;No -> skip
  move.w  (a2),d0            ;Get note period from pattern position
  and.w   d6,d0              ;Only 12 bits note period
  bne.s	  pt_DoRetrig        ;If note period -> skip
pt_NoteDelayEnd
  rts

; ** Effect command EEx "Pattern Delay" **
  CNOP 0,4
pt_PatternDelay
  moveq   #NIBBLEMASKLO,d0
  and.b   n_cmdlo(a2),d0     ;Get command data: x-notes
  tst.b	  pt_PattDelayTime2(a3) ;Pattern delay time not NULL ?
  bne.s	  pt_PattDelayEnd    ;Yes -> skip
  addq.b  #1,d0              ;Decrement notes
  move.b  d0,pt_PattDelayTime(a3) ;Save new pattern delay time
pt_PattDelayEnd
  rts

; ** Effect command EFx "Invert Loop" **
  CNOP 0,4
pt_InvertLoop
  move.b  n_cmdlo(a2),d0     ;Get command data: x-speed
  moveq   #NIBBLEMASKLO,d2
  and.b   n_glissinvert(a2),d2 ;Clear old speed
  lsl.b   #NIBBLESHIFTBITS,d0 ;Move speed to upper nibble
  or.b    d0,d2              ;Set new speed
  move.b  d2,n_glissinvert(a2) ;Save new speed
  tst.b   d0                 ;speed = NULL ?
  beq.s   pt_InvertEnd       ;Yes -> skip
pt_UpdateInvert
  moveq   #TRUE,d0           ;NULL needed for word access
  move.b  n_glissinvert(a2),d0
  lsr.b   #NIBBLESHIFTBITS,d0 ;Get speed
  beq.s   pt_InvertEnd       ;If NULL -> skip
  lea     pt_InvertTable(pc),a1 ;Pointer to invert table
  move.b  (a1,d0.w),d0       ;Get invert value
  add.b   d0,n_invertoffset(a2) ;Decrease invert offset by invert value
  bpl.s   pt_InvertEnd       ;If >= NULL -> skip
  move.l  n_wavestart(a2),a1 ;Get wavestart
  move.w  n_replen(a2),d0    ;Get repeat length
  add.w   d0,d0               ;*2 = length in bytes
  add.l   n_loopstart(a2),d0 ;Add loop start = repeat point
  addq.w  #1,a1              ;Next word in sample data
  move.b  d5,n_invertoffset(a2) ;Clear invert-offset
  cmp.l   d0,a1              ;Wavestart < repeat point ?
  blo.s   pt_InvertOk        ;Yes -> Skip
  move.l  n_loopstart(a2),a1 ;Get loop start
pt_InvertOk
  move.l  a1,n_wavestart(a2) ;Save new wavestart
  not.b   (a1)               ;Invert sample data byte bits
pt_InvertEnd
  rts

  IFEQ pt_timingcia
; ** Effect command Fxx "Set Speed" **
    CNOP 0,4
pt_SetSpeed
    move.b  n_cmdlo(a2),d0     ;Get command data: xx-speed ($00-$1f ticks) / xx-tempo ($20-$ff BPM)
    beq.s   pt_StopReplay      ;If speed = NULL -> skip
    cmp.b   #pt_maxticks,d0    ;Speed > maximum ticks ?
    bhi.s   pt_SetTempo        ;Yes -> set tempo
    move.w  d0,pt_CurrSpeed(a3) ;Set new speed ticks
    move.w  d5,pt_Counter(a3)  ;Set back ticks counter = tick #1
    rts
    CNOP 0,4
pt_SetTempo
    move.l  pt_125bpmrate(a3),d2 ;Get 125 BPM PAL/NTSC rate
    divu.w  d0,d2              ;/tempo = counter value
    move.b  d2,CIATALO(a5)     ;Set CIA-B timer A counter value low bits
    lsr.w   #BYTESHIFTBITS,d2  ;Get counter value high bits
    move.b  d2,CIATAHI(a5)     ;Set CIA-B timer A counter value high bits
    rts
    CNOP 0,4
pt_StopReplay
    move.w  #INTF_EXTER,_CUSTOM+INTENA ;Stop replay routine by turning off level-6 interrupt
    rts
  ENDC

  IFNE pt_timingcia
; ** Effect command Fxx "Set Speed" **
    CNOP 0,4
pt_SetSpeed
    move.b  n_cmdlo(a2),d0     ;Get command data: xx-speed ($00-$1f ticks)
    beq.s   pt_StopReplay      ;If speed = NULL -> skip
    cmp.b   #pt_maxticks,d0    ;Speed > maximum ticks ?
    bhi.s   pt_SetSpdEnd       ;Yes  -> skip
    move.w  d0,pt_CurrSpeed(a3) ;Set new speed ticks
    move.w  d5,pt_Counter(a3)  ;Set back ticks counter = tick #1
pt_SetSpdEnd
    rts
    CNOP 0,4
pt_StopReplay
    move.w  #INTF_VERTB,_CUSTOM+INTENA ;Stop replay routine by turning off vertical blank interrupt
    rts
  ENDC

  CNOP 0,4
pt_SetDMA
  move.b  d5,pt_SetAllChanDMAFlag(a3) ;TRUE = Activate Set DMA-interrupt routine
  moveq   #CIACRBF_START,d0
  or.b    d0,CIACRB(a5)      ;Start CIA-B timer B for DMA wait

pt_Dskip
  addq.w  #pt_pattposdata_SIZE/4,pt_PatternPosition(a3) ;Next pattern position
  move.b  pt_PattDelayTime(a3),d0 ;Get pattern delay time
  beq.s	  pt_DskipC          ;If NULL -> skip
  move.b  d0,pt_PattDelayTime2(a3) ;Save pattern delay time2
  move.b  d5,pt_PattDelayTime(a3) ;Clear pattern delay time
pt_DskipC
  tst.b	  pt_PattDelayTime2(a3) ;Get pattern delay time2
  beq.s	  pt_DskipA          ;If NULL -> skip
  subq.b  #1,pt_PattDelayTime2(a3) ;Decrement pattern delay time2
  beq.s	  pt_DskipA          ;If NULL -> skip
  subq.w  #pt_pattposdata_SIZE/4,pt_PatternPosition(a3) ;Previous pattern position
pt_DskipA
  tst.b	  pt_PBreakFlag(a3)  ;Pattern break flag set ?
  beq.s	  pt_Nnpysk          ;If NULL -> skip
  move.b  d5,pt_PBreakFlag(a3) ;Clear pattern break flag
  moveq	  #TRUE,d0           ;NULL needed for word access
  move.b  pt_PBreakPosition(a3),d0 ;Get pattern break position
  add.w   d0,d0              ;*(pt_pattposdata_SIZE/4)
  move.b  d5,pt_PBreakPosition(a3) ;Clear pattern break position
  add.w   d0,d0             
  move.w  d0,pt_PatternPosition(a3) ;Set new pattern position
pt_Nnpysk
  cmp.w	  #pt_pattsize/4,pt_PatternPosition(a3) ;End of pattern reached ?
  blo.s	  pt_NoNewPositionYet ;No -> skip
pt_NextPosition
  move.b  d5,pt_PosJumpFlag(a3) ;Clear position jump flag
  moveq	  #TRUE,d0           ;NULL needed for word access
  move.b  pt_PBreakPosition(a3),d0 ;Get Pattern Break Position
  add.w   d0,d0              ;*(pt_pattposdata_SIZE/4)
  move.w  pt_SongPosition(a3),d1 ;Get song position
  add.w   d0,d0
  move.w  d0,pt_PatternPosition(a3) ;Save new pattern position
  addq.w  #1,d1              ;Next song position
  move.b  d5,pt_PBreakPosition(a3) ;Set back pattern break position = NULL
  and.w	  #pt_maxsongpos-1,d1 ;If maximum song position reached -> restart at song position NULL
  move.w  d1,pt_SongPosition(a3) ;Save new song position
  cmp.b	  pt_SongLength(a3),d1 ;Last song position reached ?
  blo.s	  pt_NoNewPositionYet ;No -> skip
  move.w  d5,pt_SongPosition(a3) ;Set back song position = NULL
pt_NoNewPositionYet
  tst.b	  pt_PosJumpFlag(a3) ;Position jump flag set ?
  bne.s	  pt_NextPosition    ;Yes -> skip
  movem.l (a7)+,d0-d7/a0-a6
  rts



; ************************* Wait music ***********************

; ** DMAWait called by CIA-B timer B interrupt **
; -----------------------------------------------
; Constant registers
; a3 ... Base of variables
; a5 ... Base of CIA-B
; a6 ... Base of custom chips
  CNOP 0,4
pt_DMAWait
  movem.l d0-d7/a0-a6,-(a7)
  lea     pt_Variables(pc),a3 ;Base of variables
  move.l  #_CIAB,a5          ;Base of CIA-B
  move.l  #_CUSTOM,a6        ;Base of custom chips
  bsr.s   pt_CheckDMAWait
  movem.l (a7)+,d0-d7/a0-a6
  rts

; ** Check DMA wait routine to be executed **
  CNOP 0,4
pt_CheckDMAWait
  tst.w   pt_RtnDMACONtemp(a3) ;Effect command "Retrig Note" or "Note Delay" for any audio channel used ?
  beq.s   pt_NoRtnChannels   ;If not -> skip
  move.w  pt_audchan1temp+n_rtnsetchandma(pc),d0 ;Get init + set state for channel 1
  bpl     pt_RtnSetChan1DMA  ;If set state = TRUE -> skip
  tst.b   d0                 ;Init state = TRUE ?
  beq     pt_RtnInitChan1Data ;Yes -> skip
  move.w  pt_audchan2temp+n_rtnsetchandma(pc),d0 ;Get init + set state for channel 2
  bpl     pt_RtnSetChan2DMA  ;If set state = TRUE -> skip
  tst.b   d0                 ;Init state = TRUE ?
  beq     pt_RtnInitChan2Data ;Yes -> skip
  move.w  pt_audchan3temp+n_rtnsetchandma(pc),d0 ;Get init + set state for channel 3
  bpl     pt_RtnSetChan3DMA  ;If set state = TRUE -> skip
  tst.b   d0                 ;Init state = TRUE ?
  beq     pt_RtnInitChan3Data ;Yes -> skip
  move.w  pt_audchan4temp+n_rtnsetchandma(pc),d0 ;Get init + set state for channel 4
  bpl     pt_RtnSetChan4DMA  ;If set state = TRUE -> skip
  tst.b   d0                 ;Init state = TRUE ?
  beq     pt_RtnInitChan4Data ;Yes -> skip
pt_NoRtnChannels
  tst.b   pt_SetAllChanDMAFlag(a3) ;Set flag = TRUE ?
  beq.s   pt_SetAllChanDMA   ;Yes -> skip

; ** Init all audio channels loop data **
pt_InitAllChanLoopData
  move.l  pt_audchan1temp+n_loopstart(pc),AUD0LCH(a6) ;Set loop start for channel 1
  moveq   #FALSE,d0
  move.b  d0,pt_InitAllChanLoopDataFlag(a3) ;Deactivate this routine
  move.w  pt_audchan1temp+n_replen(pc),AUD0LEN(a6) ;Set repeat length for channel 1
  move.l  pt_audchan2temp+n_loopstart(pc),AUD1LCH(a6) ;Set loop start for channel 2
  move.w  pt_audchan2temp+n_replen(pc),AUD1LEN(a6) ;Set repeat length for channel 2
  move.l  pt_audchan3temp+n_loopstart(pc),AUD2LCH(a6) ;Set loop start for channel 3
  move.w  pt_audchan3temp+n_replen(pc),AUD2LEN(a6) ;Set repeat length for channel 3
  move.l  pt_audchan4temp+n_loopstart(pc),AUD3LCH(a6) ;Set loop start for channel 4
  move.w  pt_audchan4temp+n_replen(pc),AUD3LEN(a6) ;Set repeat length for channel 4
  rts

; ** Set all audio channels DMA **
  CNOP 0,4
pt_SetAllChanDMA
  move.w  pt_DMACONtemp(a3),d0 ;Get channel DMA bits
  or.w	  #DMAF_SETCLR,d0    ;DMA on
  move.w  d0,DMACON(a6)      ;Set channel DMA bits
  moveq   #FALSE,d0          ;Deactivate this routine
  addq.b  #CIACRBF_START,CIACRB(a5) ;Start CIA-B timer B for DMA wait
  clr.b   d0                 ;Activate init routine
  move.w  d0,pt_SetAllChanDMAFlag(a3) ;Save new routine states
  rts

; ** Set audio channel1 DMA if "Retrig Note" or "Note Delay" command used **
  CNOP 0,4
pt_RtnSetChan1DMA
  lea     pt_audchan1temp+n_rtnsetchandma(pc),a0 ;Pointer to set + init state
  move.w  #DMAF_AUD0+DMAF_SETCLR,DMACON(a6) ;Set audio channel DMA
  moveq   #FALSE,d0          ;Deactivate this routine
  addq.b  #CIACRBF_START,CIACRB(a5) ;Start CIA-B timer B for DMA wait
  clr.b   d0                 ;Activate init routine
  move.w  d0,(a0)            ;Save new routine states
  rts

; ** Init audio channel1 data if "Retrig Note" or "Note Delay" command used **
  CNOP 0,4
pt_RtnInitChan1Data
  lea     pt_audchan1temp+n_period(pc),a0 ;Pointer to note period
  move.w  (a0)+,AUD0PER(a6) ;Set note period
  moveq   #FALSE,d0
  move.b  d0,n_rtninitchandata-n_loopstart(a0) ;Deactivate this routine
  move.l  (a0)+,AUD0LCH(a6) ;Set loop start
  move.w  (a0),AUD0LEN(a6) ;Set repeat length
  and.w   #DMAF_AUD1+DMAF_AUD2+DMAF_AUD3,pt_RtnDMACONtemp(a3) ;Mask out channel1 DMA bit
  beq.s   pt_RtnNoRestartTimer1 ;If no other channel DMA bits are set -> skip
  addq.b  #CIACRBF_START,CIACRB(a5) ;Start CIA-B timer B for DMA wait
pt_RtnNoRestartTimer1
  rts

; ** Set audio channel2 DMA if "Retrig Note" or "Note Delay" command used **
  CNOP 0,4
pt_RtnSetChan2DMA
  lea     pt_audchan2temp+n_rtnsetchandma(pc),a0
  move.w  #DMAF_AUD1+DMAF_SETCLR,DMACON(a6) ;Set audio channel DMA
  moveq   #FALSE,d0          ;Deactivate this routine
  addq.b  #CIACRBF_START,CIACRB(a5) ;Start CIA-B timer B for DMA wait
  clr.b   d0                 ;Activate init routine
  move.w  d0,(a0)            ;Save new routine states
  rts

; ** Init audio channel2 data if "Retrig Note" or "Note Delay" command used **
  CNOP 0,4
pt_RtnInitChan2Data
  lea     pt_audchan2temp+n_period(pc),a0 ;Pointer to note period
  move.w  (a0)+,AUD1PER(a6) ;Set note period
  moveq   #FALSE,d0
  move.b  d0,n_rtninitchandata-n_loopstart(a0) ;Deactivate this routine
  move.l  (a0)+,AUD1LCH(a6) ;Set loop start
  move.w  (a0),AUD1LEN(a6) ;Set repeat length
  and.w   #DMAF_AUD2+DMAF_AUD3,pt_RtnDMACONtemp(a3) ;Mask out channel1+2 DMA bit
  beq.s   pt_RtnNoRestartTimer2 ;If no other channel DMA bits are set -> skip
  addq.b  #CIACRBF_START,CIACRB(a5) ;Start CIA-B timer B for DMA wait
pt_RtnNoRestartTimer2
  rts

; ** Set audio channel3 DMA if "Retrig Note" or "Note Delay" command used **
  CNOP 0,4
pt_RtnSetChan3DMA
  lea     pt_audchan3temp+n_rtnsetchandma(pc),a0
  move.w  #DMAF_AUD2+DMAF_SETCLR,DMACON(a6) ;Set audio channel DMA
  moveq   #FALSE,d0          ;Deactivate this routine
  addq.b  #CIACRBF_START,CIACRB(a5) ;Start CIA-B timer B for DMA wait
  clr.b   d0                 ;Activate init routine
  move.w  d0,(a0)            ;Save new routine states
  rts

; ** Init audio channel3 data if "Retrig Note" or "Note Delay" command used **
  CNOP 0,4
pt_RtnInitChan3Data
  lea     pt_audchan3temp+n_period(pc),a0 ;Pointer to note period
  move.w  (a0)+,AUD2PER(a6) ;Note period
  moveq   #FALSE,d0
  move.b  d0,n_rtninitchandata-n_loopstart(a0) ;Deactivate this routine
  move.l  (a0)+,AUD2LCH(a6) ;Set loop start
  move.w  (a0),AUD2LEN(a6) ;Set repeat length
  and.w   #DMAF_AUD3,pt_RtnDMACONtemp(a3) ;Mask out channel1+2+3 DMA bit
  beq.s   pt_RtnNoRestartTimer3 ;If no other channel DMA bits are set -> skip
  addq.b  #CIACRBF_START,CIACRB(a5) ;Start CIA-B timer B for DMA wait
pt_RtnNoRestartTimer3
  rts

; ** Set audio channel4 DMA if "Retrig Note" or "Note Delay" command used **
  CNOP 0,4
pt_RtnSetChan4DMA
  lea     pt_audchan4temp+n_rtnsetchandma(pc),a0
  move.w  #DMAF_AUD3+DMAF_SETCLR,DMACON(a6) ;Set audio channel DMA
  moveq   #FALSE,d0          ;Deactivate this routine
  addq.b  #CIACRBF_START,CIACRB(a5) ;Start CIA-B timer B for DMA wait
  clr.b   d0                 ;Activate init routine
  move.w  d0,(a0)            ;Save new routine states
  rts

; ** Init audio channel4 data if "Retrig Note" or "Note Delay" command used **
  CNOP 0,4
pt_RtnInitChan4Data
  subq.w  #DMAF_AUD3,pt_RtnDMACONtemp(a3) ;Clear channel 4 DMA bit
  lea     pt_audchan4temp+n_period(pc),a0 ;Pointer to note period
  move.w  (a0)+,AUD3PER(a6)  ;Note period
  moveq   #FALSE,d0
  move.b  d0,n_rtninitchandata-n_loopstart(a0) ;Deactivate this routine
  move.l  (a0)+,AUD3LCH(a6)  ;Set loop start
  move.w  (a0),AUD3LEN(a6)   ;Set repeat length
  rts



; ************************* Stop music ***********************

; ** Stop all audio activity **
; -----------------------------
; Constant registers
; a3 ... Base of variables
; a4 ... Base of CIA-A
; a5 ... Base of CIA-B
; a6 ... Base of custom chips / exec library
  CNOP 0,4
pt_StopMusic
  lea     pt_Variables(pc),a3 ;Base of variables
  move.l  #_CIAB,a5          ;Base of CIA-B
  lea     _CIAA-_CIAB(a5),a4 ;Base of CIA-A
  move.l  #_CUSTOM,a6        ;Base of custom chips
  bsr.s   pt_StopTimers
  bra.s   pt_SetBackRegisters

; ** Stop all timers **
  CNOP 0,4
pt_StopTimers
  IFEQ pt_timingcia
    move.b  CIACRA(a5),d0
    and.b   #~(CIACRAF_START),d0 ;Stop CIA-B continuous timer A
    move.b  d0,CIACRA(a5)
  ENDC
  move.b  CIACRB(a5),d0
  and.b   #~(CIACRBF_START),d0 ;Stop CIA-B oneshot timer B
  move.b  d0,CIACRB(a5)
  rts

; ** Stop all audio and restore soundfilter **
  CNOP 0,4
pt_SetBackRegisters
  moveq   #TRUE,d0
  move.w  d0,AUD0VOL(a6)     ;Clear volume for all channels
  move.w  d0,AUD1VOL(a6)
  move.w  d0,AUD2VOL(a6)
  move.w  d0,AUD3VOL(a6)
  move.w  #pt_DMABITS,DMACON(a6) ;Turn audio DMA off
  moveq   #-(-(~CIAF_LED)&BYTEMASK),d0
  and.b   d0,CIAPRA(a4)      ;Turn soundfilter off
  rts



; ************************* Tables & variables ***********************

; ** Tables for effect commands **
; --------------------------------

; ** "Invert Loop" **
pt_InvertTable
  DC.B 0,5,6,7,8,10,11,13,16,19,22,26,32,43,64,128

; ** "Vibrato/Tremolo" **
pt_VibTreSineTable
  DC.B 0,24,49,74,97,120,141,161
  DC.B 180,197,212,224,235,244,250,253
  DC.B 255,253,250,244,235,224,212,197
  DC.B 180,161,141,120,97,74,49,24

; ** "Arpeggio/Tone Portamento" **
  CNOP 0,2
pt_PeriodTable
  ; -> Tuning 0
; Note C   C#  D   D#  E   F   F#  G   G#  A   A#  B
  DC.W 856,808,762,720,678,640,604,570,538,508,480,453 ;Octave 1
  DC.W 428,404,381,360,339,320,302,285,269,254,240,226 ;Octave 2
  DC.W 214,202,190,180,170,160,151,143,135,127,120,113 ;Octave 3
pt_PeriodTableEnd
  ; -> Tuning 1
  DC.W 850,802,757,715,674,637,601,567,535,505,477,450
  DC.W 425,401,379,357,337,318,300,284,268,253,239,225
  DC.W 213,201,189,179,169,159,150,142,134,126,119,113
  ; -> Tuning 2
  DC.W 844,796,752,709,670,632,597,563,532,502,474,447
  DC.W 422,398,376,355,335,316,298,282,266,251,237,224
  DC.W 211,199,188,177,167,158,149,141,133,125,118,112
  ; -> Tuning 3
  DC.W 838,791,746,704,665,628,592,559,528,498,470,444
  DC.W 419,395,373,352,332,314,296,280,264,249,235,222
  DC.W 209,198,187,176,166,157,148,140,132,125,118,111
  ; -> Tuning 4
  DC.W 832,785,741,699,660,623,588,555,524,495,467,441
  DC.W 416,392,370,350,330,312,294,278,262,247,233,220
  DC.W 208,196,185,175,165,156,147,139,131,124,117,110
  ; -> Tuning 5
  DC.W 826,779,736,694,655,619,584,551,520,491,463,437
  DC.W 413,390,368,347,328,309,292,276,260,245,232,219
  DC.W 206,195,184,174,164,155,146,138,130,123,116,109
  ; -> Tuning 6
  DC.W 820,774,730,689,651,614,580,547,516,487,460,434
  DC.W 410,387,365,345,325,307,290,274,258,244,230,217
  DC.W 205,193,183,172,163,154,145,137,129,122,115,109
  ; -> Tuning 7
  DC.W 814,768,725,684,646,610,575,543,513,484,457,431
  DC.W 407,384,363,342,323,305,288,272,256,242,228,216
  DC.W 204,192,181,171,161,152,144,136,128,121,114,108
  ; -> Tuning -8
  DC.W 907,856,808,762,720,678,640,604,570,538,508,480
  DC.W 453,428,404,381,360,339,320,302,285,269,254,240
  DC.W 226,214,202,190,180,170,160,151,143,135,127,120
  ; -> Tuning -7
  DC.W 900,850,802,757,715,675,636,601,567,535,505,477
  DC.W 450,425,401,379,357,337,318,300,284,268,253,238
  DC.W 225,212,200,189,179,169,159,150,142,134,126,119
  ; -> Tuning -6
  DC.W 894,844,796,752,709,670,632,597,563,532,502,474
  DC.W 447,422,398,376,355,335,316,298,282,266,251,237
  DC.W 223,211,199,188,177,167,158,149,141,133,125,118
  ; -> Tuning -5
  DC.W 887,838,791,746,704,665,628,592,559,528,498,470
  DC.W 444,419,395,373,352,332,314,296,280,264,249,235
  DC.W 222,209,198,187,176,166,157,148,140,132,125,118
  ; -> Tuning -4
  DC.W 881,832,785,741,699,660,623,588,555,524,494,467
  DC.W 441,416,392,370,350,330,312,294,278,262,247,233
  DC.W 220,208,196,185,175,165,156,147,139,131,123,117
  ; -> Tuning -3
  DC.W 875,826,779,736,694,655,619,584,551,520,491,463
  DC.W 437,413,390,368,347,328,309,292,276,260,245,232
  DC.W 219,206,195,184,174,164,155,146,138,130,123,116
  ; -> Tuning -2
  DC.W 868,820,774,730,689,651,614,580,547,516,487,460
  DC.W 434,410,387,365,345,325,307,290,274,258,244,230
  DC.W 217,205,193,183,172,163,154,145,137,129,122,115
  ; -> Tuning -1
  DC.W 862,814,768,725,684,646,610,575,543,513,484,457
  DC.W 431,407,384,363,342,323,305,288,272,256,242,228
  DC.W 216,203,192,181,171,161,152,144,136,128,121,114

; ** Temporary channel structures **
; ----------------------------------
  CNOP 0,4
pt_audchan1temp
  DS.B n_audchantemp_SIZE

  CNOP 0,4
pt_audchan2temp
  DS.B n_audchantemp_SIZE

  CNOP 0,4
pt_audchan3temp
  DS.B n_audchantemp_SIZE

  CNOP 0,4
pt_audchan4temp
  DS.B n_audchantemp_SIZE

; ** Pointers to samples **
; -------------------------
  CNOP 0,4
pt_SampleStarts
  DS.L pt_samplesnum

; ** Pointers to period tables for different finetunes **
; -------------------------------------------------------
pt_FtuPeriodTableStarts
  DS.L pt_finetunenum

; ** Variables **
; ---------------
pt_variables DS.B pt_variables_SIZE

; ** Names **
; -----------
gfxname DC.B "gfx.library",TRUE



; ************************* Module Data ***********************

; ** Module to be loaded as binary into CHIP memory **
; ----------------------------------------------------
pt_auddata SECTION audio,DATA_C

  INCBIN "MOD.example"

  END
