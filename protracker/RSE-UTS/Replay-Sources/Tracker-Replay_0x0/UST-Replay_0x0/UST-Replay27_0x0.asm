; Program: UST-Replay27_0x0.asm
; Author:  Dissident^Resistance
; Date:    2021-05-01
; Version: 2.0
; CPU:     68020+
; FASTMEM:  -
; Chipset: OCS/ECS/AGA
; OS:      1.2+

; ** Supported trackers **
; - Ultimate Soundtracker 1.21 (dst_timingcia=FALSE)
; - Ultimate Soundtracker 1.8  (dst_timingcia=TRUE)
; - Ultimate Soundtracker 2.0  (dst_timingcia=TRUE)

; ** Main characteristics **
; - 15 instruments
; - Sample repeat point in bytes
; - Sample length = repeat length
; - Effect commands with the numbers 1..2 are not compatible with subsequent
;   trackers¹
; - Raster dependent or independent replay

; ** Code **
; - Improved and optimized for 68020+ CPUs

; ** Play music trigger **
; - Label ust_PlayMusic: Called from CIA-B timer A or vblank interrupt
; - Equal ust_timingcia: TRUE = Activate sourcecode for CIA-B timer A as
;                        trigger for variable 1..240 BPM replay
;                        FALSE = Activate sourcecode for vblank as trigger
;                        for constant 125 BPM replay on PAL machines and
;                        for constant 150 BPM on NTSC machines

; ** DMA wait trigger **
; - Label ust_DMAWait: Called from CIA-B timer B interrupt triggered
;                      after 482.68 µs on PAL machines or 478.27 µs
;                      on NTSC machines

; ** Loop samples **
; - Check for repeat length > 1 word, instead of repeat point not NULL
; - Loop samples with repeat point = NULL now properly detected

; ** Supported effect commands (cmd format 0) **
; 0 - NOT USED
; 1 - Normal play or Arpeggiato¹
; 2 - Pitchbend¹
; 3 - NOT USED
; 4 - NOT USED
; 5 - NOT USED
; 6 - NOT USED
; 7 - NOT USED
; 8 - NOT USED
; 9 - NOT USED
; A - NOT USED
; B - NOT USED
; C - NOT USED
; D - NOT USED
; E - NOT USED
; F - NOT USED



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
ust_DMABITS              EQU DMAF_AUD0+DMAF_AUD1+DMAF_AUD2+DMAF_AUD3 ;Audio DMA for all channels off
ust_CIABCRABITS          EQU CIACRBF_LOAD ;CIA-B timer A continuous mode
ust_CIABCRBBITS          EQU CIACRBF_LOAD+CIACRBF_RUNMODE ;CIA-B timer B oneshot mode

; ** Timer values **
ust_120bpmtime           EQU 14640 ;= (240 - 120 BPM) * 122 (Karsten Obarski)
ust_dmawaittime          EQU 342 ;= 0.709379 MHz * [482.68 µs = Lowest note period C1 * 2 / PAL clock constant = 856*2/3546895 ticks per second]
                                 ;= 0.715909 MHz * [478.27 µs = Lowest note period C1 * 2 / NTSC clock constant = 856*2/3579545 ticks per second]
; ** Song equals **
ust_maxsongpos           EQU 128
ust_maxpattpos           EQU 64
ust_pattsize             EQU 1024
ust_samplesnum           EQU 15

; ** Speed/Tempo equals **
ust_defaultticks         EQU 6
ust_defaultbpm           EQU 120
ust_minbpm               EQU 0
ust_maxbpm               EQU 220
ust_bpmconst             EQU 240
ust_speedconst           EQU 122

; ** Effect command masks equals **
ust_cmdpermask           EQU $0fff
ust_cmdnummask           EQU $0f

; ** Effect commands equals **
ust_periodsnum           EQU 36

; ** Replay routine trigger **
ust_timingcia            EQU TRUE


                                  
; ************************* Variables offsets ***********************

; ** Relative offsets for variables **
; ------------------------------------
  RSRESET
ust_SongDataPtr	    RS.L 1
ust_Counter	    RS.W 1
ust_DMACONtemp	    RS.W 1
ust_PatternPosition RS.W 1
ust_SongPosition    RS.W 1
ust_SongLength      RS.B 1
ust_variables_SIZE  RS.B 0



; ************************* Structures ***********************

; ** UST-Song-Structure **
; ------------------------

; ** UST SampleInfo structure **
  RSRESET
ust_sampleinfo      RS.B 0
ust_si_samplename   RS.B 22  ;Sample's name padded with null bytes
ust_si_samplelength RS.W 1   ;Sample length in words
ust_si_volume       RS.W 1   ;Bits 15-7 not used, bits 6-0 sample volume 0..64
ust_si_repeatpoint  RS.W 1   ;Start of sample repeat offset in bytes
ust_si_repeatlength RS.W 1   ;Length of sample repeat in words
ust_sampleinfo_SIZE RS.B 0

; ** UST SongData structure **
  RSRESET
ust_songdata       RS.B 0
ust_sd_songname    RS.B 20   ;Song's name padded with null bytes
ust_sd_sampleinfo  RS.B ust_sampleinfo_SIZE*ust_samplesnum ;Pointer to 1st sampleinfo, structure repeated for each sample 1-15
ust_sd_numofpatt   RS.B 1    ;Number of song positions 1..128
ust_sd_songspeed   RS.B 1    ;Song speed 0..220 BPM, default 120 BPM
ust_sd_pattpos     RS.B 128  ;Pattern positions table 0..127
ust_sd_patterndata RS.B 0    ;Pointer to 1st pattern, structure repeated for each pattern 1..64 times
ust_songdata_SIZE  RS.B 0

; ** UST NoteInfo structure **
  RSRESET
ust_noteinfo      RS.B 0
ust_ni_note       RS.W 1     ;Bits 15-12 not used, bits 11-0 noteperiod
ust_ni_cmd        RS.B 1     ;Bits 7-4 sample number, bits 3-0 effect command number
ust_ni_cmdlo      RS.B 1     ;Bits 7-0 effect command data
ust_noteinfo_SIZE RS.B 0

; ** UST PatternPositionData structure **
  RSRESET
ust_pattposdata       RS.B 0
ust_ppd_chan1noteinfo RS.B ust_noteinfo_SIZE ;Note info for each audio channel 1..4 is stored successive
ust_ppd_chan2noteinfo RS.B ust_noteinfo_SIZE
ust_ppd_chan3noteinfo RS.B ust_noteinfo_SIZE
ust_ppd_chan4noteinfo RS.B ust_noteinfo_SIZE
ust_pattposdata_SIZE  RS.B 0

; ** UST PatternData structure **
  RSRESET
ust_patterndata      RS.B 0
ust_pd_data          RS.B ust_pattposdata_SIZE*ust_maxpattpos ;Repeated 64 times
ust_patterndata_SIZE RS.B 0

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
n_volume           RS.W 1
n_dmabit           RS.W 1
n_audchantemp_SIZE RS.B 0



  SECTION ust_replay27,CODE

  MC68020

; ************************* Init music ***********************

; ** Do all audio inits **
; ------------------------
; Constant registers
; a3 ... Base of variables
; a4 ... Base of CIA-A
; a5 ... Base of CIA-B
; a6 ... Base of custom chips
  CNOP 0,4
ust_InitMusic
  lea     ust_Variables(pc),a3 ;Base of variables
  move.l  #_CIAB,a5          ;Base of CIA-B
  lea     _CIAA-_CIAB(a5),a4 ;Base of CIA-A
  move.l  #_CUSTOM,a6        ;Base of custom chips
  bsr.s   ust_InitTimers
  bsr.s   ust_InitRegisters
  bsr.s   ust_InitVariables
  bsr.s   ust_InitAudTempStrucs
  bra     ust_ExamineSongStruc

; ** Init all timers **
  CNOP 0,4
ust_InitTimers
  IFEQ ust_timingcia
    moveq   #16,d0
    neg.b   d0                 ;240 = ust_bpmconst
    move.l  ust_SongDataPtr(a3),a0 ;Pointer to song data
    moveq   #TRUE,d1           ;NULL for word access
    move.b  ust_sd_songspeed(a0),d1 ;Get songsspeed in BPM
    sub.w   d1,d0              ;ust_bpmconst - songspeed
    mulu.w  #ust_speedconst,d0 ;(ust_bpmconst - songspeed) * 122
    move.b  d0,CIATALO(a5)     ;Set CIA-B timer A counter value low bits
    lsr.w   #BYTESHIFTBITS,d0  ;Get counter value high bits
    move.b  d0,CIATAHI(a5)     ;Set CIA-B timer A counter value high bits
    moveq   #ust_CIABCRABITS,d0
    move.b  d0,CIACRA(a5)      ;Load new timer continuous value
  ENDC

  moveq   #ust_dmawaittime&BYTEMASK,d0 ;DMA wait
  move.b  d0,CIATBLO(a5)     ;Set CIA-B timer B counter value low bits
  moveq   #ust_dmawaittime>>BYTESHIFTBITS,d0
  move.b  d0,CIATBHI(a5)     ;Set CIA-B timer B counter value high bits
  moveq   #ust_CIABCRBBITS,d0
  move.b  d0,CIACRB(a5)      ;Load new timer oneshot value
  rts

; ** Init main registers **
  CNOP 0,4
ust_InitRegisters
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
ust_InitVariables
  lea     ust_auddata,a0
  move.l  a0,ust_SongDataPtr(a3)
  moveq   #TRUE,d0
  move.w  d0,ust_Counter(a3)
  move.w  d0,ust_DMACONtemp(a3)
  move.w  d0,ust_PatternPosition(a3)
  move.w  d0,ust_SongPosition(a3)
  rts

; ** Init temporary channel structures **
  CNOP 0,4
ust_InitAudTempStrucs
  moveq   #DMAF_AUD0,d0      ;DMA bit for channel1
  lea     ust_audchan1temp+n_dmabit(pc),a0
  move.w  d0,(a0)            ;Set DMA channel1 bit
  moveq   #DMAF_AUD1,d0      ;DMA bit for channel2
  lea     ust_audchan2temp+n_dmabit(pc),a0
  move.w  d0,(a0)            ;Set DMA channel2 bit
  moveq   #DMAF_AUD2,d0      ;DMA bit for channel3
  lea     ust_audchan3temp+n_dmabit(pc),a0
  move.w  d0,(a0)            ;Set DMA channel3 bit
  moveq   #DMAF_AUD3,d0      ;DMA bit for channel4
  lea     ust_audchan4temp+n_dmabit(pc),a0
  move.w  d0,(a0)            ;Set DMA channel4 bit
  rts

; ** Get highest pattern number and initialize sample pointers table **
  CNOP 0,4
ust_ExamineSongStruc
  move.l  ust_SongDataPtr(a3),a0 ;Pointer to song data
  moveq	  #TRUE,d0           ;First pattern number
  move.b  ust_sd_numofpatt(a0),ust_SongLength(a3) ;Get number of patterns
  moveq	  #TRUE,d1           ;Highest pattern number
  lea	  ust_sd_pattpos(a0),a1 ;Pointer to table with pattern positions in song
  moveq   #ust_maxsongpos-1,d7 ;Maximum number of song positions
ust_InitLoop
  move.b  (a1)+,d0           ;Get pattern number out of song position table
  cmp.b	  d1,d0              ;Pattern number <= previous pattern number ?
  ble.s	  ust_InitSkip       ;Yes -> skip
  move.l  d0,d1              ;Save higher pattern number
ust_InitSkip
  dbf	  d7,ust_InitLoop
  addq.w  #1,d1              ;Decrease highest pattern number
  add.w   #ust_sd_sampleinfo+ust_si_samplelength,a0 ;First sample length
  lsl.w   #BYTESHIFTBITS,d1  ;*(ust_pattsize/8) = Offset points to end of last pattern
  moveq   #TRUE,d2           ;NULL to clear first word in sample data
  lea	  (a1,d1.w*8),a2     ;Skip patterndata -> Pointer to first sample data in module
  lea	  ust_SampleStarts(pc),a1 ;Table for sample pointers
  moveq	  #ust_sampleinfo_SIZE,d1 ;Length of sample info structure in bytes
  moveq	  #ust_samplesnum-1,d7 ;Number of samples in module
ust_InitLoop2
  move.l  a2,(a1)+           ;Save pointer to sample data
  move.w  (a0),d0            ;Get sample length
  beq.s   ust_NoSample       ;If length = NULL -> skip
  add.w   d0,d0              ;*2 = Sample length in bytes
  move.w  d2,(a2)            ;Clear first word in sample data
  add.l	  d0,a2              ;Add sample length to get pointer to next sample data
ust_NoSample
  add.l	  d1,a0              ;Next sample info structure in module
  dbf	  d7,ust_InitLoop2
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
ust_PlayMusic
  movem.l d0-d7/a0-a6,-(a7)
  lea     ust_Variables(pc),a3 ;Base of variables
  move.l  #_CIAB,a5          ;Base of CIA-B
  lea     _CIAA-_CIAB(a5),a4 ;Base of CIA-A
  move.l  #_CUSTOM,a6        ;Base of custom chips
  moveq   #TRUE,d5           ;Constant: NULL longword for all delete operations
  addq.w  #1,ust_Counter(a3) ;Increment ticks
  move.w  #ust_cmdpermask,d6 ;Constant: Mask out sample number
  move.w  ust_Counter(a3),d0 ;Get ticks
  add.w   #AUD0LCH,a6        ;Pointer to first audio channel address in CUSTOM CHIP space
  cmp.w	  #ust_defaultticks,d0 ;Ticks < default speed ticks ?
  bne.s	  ust_NoNewNote      ;Yes -> skip
  move.w  d5,ust_Counter(a3) ;If ticks >= speed ticks -> set back ticks counter = tick #1
  bra     ust_GetNewNote

; ** Check all audio channel for effect commands at ticks #2...#speed ticks **
  CNOP 0,4
ust_NoNewNote
  lea	  ust_audchan1temp(pc),a2 ;Pointer to first channel temporary structure (see above)
  bsr.s	  ust_CheckEffects
  addq.w  #8,a6              ;Calculate CUSTOM CHIP pointer to next audio channel
  lea	  ust_audchan2temp(pc),a2 ;Pointer to second channel temporary structure (see above)
  addq.w  #8,a6
  bsr.s	  ust_CheckEffects
  addq.w  #8,a6
  lea	  ust_audchan3temp(pc),a2 ;Pointer to third channel temporary structure (see above)
  addq.w  #8,a6
  bsr.s	  ust_CheckEffects
  addq.w  #8,a6
  lea	  ust_audchan4temp(pc),a2 ;Pointer to fourth channel temporary structure (see above)
  addq.w  #8,a6
  bsr.s   ust_CheckEffects
  bra     ust_NoNewPositionYet

; ** Check audio channel for effect commands **
  CNOP 0,4
ust_CheckEffects
  move.w  n_cmd(a2),d0       ;Get channel effect command
  and.w	  d6,d0              ;without nibble of sample number
  beq.s   ust_ChkEfxEnd      ;If no command -> skip
  tst.b   d0                 ;Command data = NULL ?
  beq.s   ust_ChkEfxEnd      ;Yes -> skip
  lsr.w   #BYTESHIFTBITS,d0  ;Get effect command number
  subq.b  #1,d0              ;1 "Arpeggiato" ?
  beq.s	  ust_Arpeggiato
  subq.b  #1,d0              ;2 "Pitchbend" ?
  beq.s	  ust_Pitchbend
ust_ChkEfxEnd
  rts

; ** Effect command 1xy "Normal play" or "Arpeggiato" **
  CNOP 0,4
ust_Arpeggiato
  move.w  ust_Counter(a3),d0 ;Get ticks
  subq.b  #1,d0              ;$01 = Add first halftone at tick #2 ?
  beq.s   ust_Arpeggiato1
  subq.b  #1,d0              ;$02 = Add second halftone at tick #3 ?
  beq.s   ust_Arpeggiato2
  subq.b  #1,d0              ;$03 = Play note period at tick #4
  beq.s   ust_Arpeggiato0
  subq.b  #1,d0              ;$04 = Add first halftone at tick #5 ?
  beq.s   ust_Arpeggiato1
  subq.b  #1,d0              ;$05 = Add second halftone at tick #6 ?
  beq.s   ust_Arpeggiato2
  rts
; ** Effect command 100 "Normal Play" 1st note **
  CNOP 0,4
ust_Arpeggiato0
  move.w  n_period(a2),d2    ;Play note period at tick #1
ust_ArpeggiatoSet
  move.w  d2,6(a6)           ;AUDxPER Set new note period
  rts
; ** Effect command 1x0 "Arpeggiato" 2nd note **
  CNOP 0,4
ust_Arpeggiato1
  move.b  n_cmdlo(a2),d0     
  lsr.b	  #NIBBLESHIFTBITS,d0 ;Get command data: x-first halftone
  bra.s	  ust_ArpeggiatoFind
; ** Effect command 10y "Arpeggiato" 3rd note **
  CNOP 0,4
ust_Arpeggiato2
  moveq   #NIBBLEMASKLO,d0
  and.b   n_cmdlo(a2),d0     ;Get command data: y-second halftone
ust_ArpeggiatoFind
  lea	  ust_PeriodTable(pc),a1 ;Pointer to period table
  move.w  n_period(a2),d2    ;Get note period
  moveq   #((ust_PeriodTableEnd-ust_PeriodTable)/2)-1,d7 ;Number of periods
ust_ArpLoop
  cmp.w	  (a1)+,d2           ;Note period >= table note period ?
  dbeq    d7,ust_ArpLoop     ;If not -> loop until note period found or loop counter = FALSE
ust_ArpFound
  move.w  -2(a1,d0.w*2),d2   ;Get note period + first or second halftone addition
  bra.s	  ust_ArpeggiatoSet

; ** Effect command 2xy "Pitchbend" **
  CNOP 0,4
ust_Pitchbend
  move.w  (a2),d2            ;Get note period
  move.b  n_cmdlo(a2),d0
  lsr.b	  #NIBBLESHIFTBITS,d0 ;Get command data: x-downspeed
  beq.s   ust_PitchbendUp    ;If NULL -> skip
; ** Effect command 2x0 "Pitchbend Down" **
ust_PitchbendDown
  add.w	  d0,d2              ;Note period + downspeed
  move.w  d2,(a2)            ;Save new note period
  move.w  d2,6(a6)           ;AUDxPER Set new note period
  rts
; ** Effect command 20y "Pitchbend Up" **
  CNOP 0,4
ust_PitchbendUp
  moveq	  #NIBBLEMASKLO,d0
  and.b   n_cmdlo(a2),d0     ;Get command data: y-upspeed
  beq.s   ust_PitchUpEnd     ;If NULL -> skip
  sub.w	  d0,d2              ;Note period - upspeed
  move.w  d2,(a2)            ;Save new note period
  move.w  d2,6(a6)           ;AUDxPER Set new note period
ust_PitchUpEnd
  rts

; ** Get new note and pattern position at tick #1 **
  CNOP 0,4
ust_GetNewNote
  move.l  ust_SongDataPtr(a3),a0 ;Pointer to module
  move.w  ust_SongPosition(a3),d0 ;Get song position
  moveq	  #TRUE,d1           ;NULL needed for word access
  move.b  (ust_sd_pattpos,a0,d0.w),d1 ;Get pattern number in song position table
  lsl.w   #BYTESHIFTBITS,d1  ;*(pt_pattsize/4) = Pattern offset
  add.w	  ust_PatternPosition(a3),d1 ;Add pattern position
  move.w  d5,ust_DMACONtemp(a3) ;Clear DMA bits
  lea	  ust_audchan1temp(pc),a2 ;Pointer to audio channel temporary structure
  bsr.s   ust_PlayVoice
  addq.w  #8,a6              ;Next audio channel CUSTOM address
  lea	  ust_audchan2temp(pc),a2
  addq.w  #8,a6
  bsr.s   ust_PlayVoice
  addq.w  #8,a6
  lea	  ust_audchan3temp(pc),a2
  addq.w  #8,a6
  bsr.s   ust_PlayVoice
  addq.w  #8,a6
  lea	  ust_audchan4temp(pc),a2
  addq.w  #8,a6
  bsr.s   ust_PlayVoice
  bra.s   ust_SetDMA

; ** Get new note data **
  CNOP 0,4
ust_PlayVoice
  move.l  (ust_sd_patterndata,a0,d1.l*4),(a2) ;Get new note data from pattern
  moveq   #TRUE,d2           ;NULL needed for word access
  move.b  n_cmd(a2),d2       
  addq.w  #ust_noteinfo_SIZE/4,d1 ;Next channel data
  lsr.b	  #NIBBLESHIFTBITS,d2 ;Get nibble of sample number
  beq.s	  ust_SetRegisters   ;If NULL -> skip
  subq.w  #1,d2              ;x = sample number -1
  lea	  ust_SampleStarts(pc),a1 ;Pointer to sample pointers table
  move.w  d2,d3              ;Save x
  move.l  (a1,d2.w*4),a1     ;Get sample data pointer
  lsl.w   #NIBBLESHIFTBITS,d2 ;x*16
  sub.w   d3,d2              ;(x*16)-x = sample info structure length in words
  movem.w ust_sd_sampleinfo+ust_si_samplelength(a0,d2.w*2),d0/d2-d4 ;length, volume, repeat point, repeat length
  move.w  d2,n_volume(a2)    ;Save sample volume
  move.w  d2,8(a6)	     ;AUDxVOL Set new volume
  cmp.w   #1,d4              ;Repeat length = 1 word ?
  beq.s	  ust_NoLoopSample   ;Yes -> skip
ust_LoopSample
  move.w  d4,d0              ;Sample length = repeat length
  add.l	  d3,a1	             ;Add repeat point
ust_NoLoopSample
  move.w  d0,n_length(a2)    ;Save sample length
  move.w  d4,n_replen(a2)    ;Save repeat length
  move.l  a1,n_start(a2)     ;Save sample start
  move.l  a1,n_loopstart(a2) ;Save loop start

ust_SetRegisters
  move.w  (a2),d3            ;Get note period from pattern position
  beq.s   ust_NoNewNoteSet   ;If no note period -> skip

ust_SetPeriod
  move.w  d3,n_period(a2)    ;Save new note period
  move.w  n_dmabit(a2),d0    ;Get audio channel DMA bit
  or.w	  d0,ust_DMACONtemp(a3) ;Set audio channel DMA bit
  move.w  d0,_CUSTOM+DMACON  ;Audio channel DMA off
  move.l  n_start(a2),(a6)   ;AUDxLCH Set sample start
  move.l  n_length(a2),4(a6) ;AUDxLEN & AUDxPER Set length & new note period
ust_NoNewNoteSet
  rts

  CNOP 0,4
ust_SetDMA
  moveq   #CIACRBF_START,d0
  or.b    d0,CIACRB(a5)      ;CIA-B timer B Start timer for DMA wait

ust_Dskip
  addq.w  #ust_pattposdata_SIZE/4,ust_PatternPosition(a3) ;Next pattern position
  cmp.w	  #ust_pattsize/4,ust_PatternPosition(a3) ;End of pattern reached ?
  bne.s	  ust_NoNewPositionYet ;No -> skip
ust_NextPosition
  move.w  ust_SongPosition(a3),d1 ;Get song position
  move.w  d5,ust_PatternPosition(a3) ;Set back pattern position = NULL
  addq.w  #1,d1              ;Next song position
  move.w  d1,ust_SongPosition(a3) ;Save new song position
  cmp.b	  ust_SongLength(a3),d1 ;Last song position reached ?
  bne.s	  ust_NoNewPositionYet ;No -> skip
  move.w  d5,ust_SongPosition(a3) ;Set back song position = NULL
ust_NoNewPositionYet
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
ust_DMAWait
  movem.l d0-d7/a0-a6,-(a7)
  lea     ust_Variables(pc),a3 ;Base of variables
  move.l  #_CIAB,a5          ;Base of CIA-B
  move.l  #_CUSTOM,a6        ;Base of custom chips
  bsr.s   ust_CheckDMAWait
  movem.l (a7)+,d0-d7/a0-a6
  rts

; ** Check DMA wait routine to be executed **
  CNOP 0,4
ust_CheckDMAWait
  move.w  ust_DMACONtemp(a3),d0 ;Get channel DMA bits
  or.w	  #DMAF_SETCLR,d0    ;DMA on
  move.w  d0,DMACON(a6)      ;Set channel DMA bits

  moveq   #1,d0              ;Length = 1 word
  cmp.w   ust_audchan1temp+n_replen(pc),d0 ;Repeat length = 1 word ?
  bne.s   ust_Audchan0Loop   ;No -> Loop sample
  move.l  ust_audchan1temp+n_loopstart(pc),AUD0LCH(a6) ;Set loop start for channel 1
  move.w  d0,AUD0LEN(a6)     ;Set repeat length for channel 1
ust_Audchan0Loop
  cmp.w   ust_audchan2temp+n_replen(pc),d0 ;Repeat length = 1 word ?
  bne.s   ust_Audchan1Loop   ;No -> Loop sample
  move.l  ust_audchan2temp+n_loopstart(pc),AUD1LCH(a6) ;Set loop start for channel 2
  move.w  d0,AUD1LEN(a6)     ;Set repeat length for channel 2
ust_Audchan1Loop
  cmp.w   ust_audchan3temp+n_replen(pc),d0 ;Repeat length = 1 word ?
  bne.s   ust_Audchan2Loop   ;No -> Loop sample
  move.l  ust_audchan3temp+n_loopstart(pc),AUD2LCH(a6) ;Set loop start for channel 3
  move.w  d0,AUD2LEN(a6)     ;Set repeat length for channel 3
ust_Audchan2Loop
  cmp.w   ust_audchan4temp+n_replen(pc),d0 ;Repeat length = 1 word ?
  bne.s   ust_Audchan3Loop   ;No -> Loop sample
  move.l  ust_audchan4temp+n_loopstart(pc),AUD3LCH(a6) ;Set loop start for channel 4
  move.w  d0,AUD3LEN(a6)     ;Set repeat length for channel 4
ust_Audchan3Loop
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
ust_StopMusic
  lea     ust_Variables(pc),a3 ;Base of variables
  move.l  #_CIAB,a5          ;Base of CIA-B
  lea     _CIAA-_CIAB(a5),a4 ;Base of CIA-A
  move.l  #_CUSTOM,a6        ;Base of custom chips
  bsr.s   ust_StopTimers
  bra.s   ust_SetBackRegisters

; ** Stop all timers **
  CNOP 0,4
ust_StopTimers
  IFEQ ust_timingcia
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
ust_SetBackRegisters
  moveq   #TRUE,d0
  move.w  d0,AUD0VOL(a6)     ;Clear volume for all channels
  move.w  d0,AUD1VOL(a6)
  move.w  d0,AUD2VOL(a6)
  move.w  d0,AUD3VOL(a6)
  move.w  #ust_DMABITS,DMACON(a6) ;Turn audio DMA off
  moveq   #-(-(~CIAF_LED)&BYTEMASK),d0
  and.b   d0,CIAPRA(a4)      ;Turn soundfilter off
  rts



; ************************* Tables & variables ***********************

; ** Table for effect command **
; ------------------------------

; ** "Arpeggiato" **
  CNOP 0,2
ust_PeriodTable
; Note C   C#  D   D#  E   F   F#  G   G#  A   A#  B
  DC.W 856,808,762,720,678,640,604,570,538,508,480,453 ;Octave 1
  DC.W 428,404,381,360,339,320,302,285,269,254,240,226 ;Octave 2
  DC.W 214,202,190,180,170,160,151,143,135,127,120,113 ;Octave 3
  DC.W 000                                             ;Noop
ust_PeriodTableEnd

; ** Temporary channel structures **
; ----------------------------------
  CNOP 0,4
ust_audchan1temp
  DS.B n_audchantemp_SIZE

  CNOP 0,4
ust_audchan2temp
  DS.B n_audchantemp_SIZE

  CNOP 0,4
ust_audchan3temp
  DS.B n_audchantemp_SIZE

  CNOP 0,4
ust_audchan4temp
  DS.B n_audchantemp_SIZE

; ** Pointers to samples **
; -------------------------
  CNOP 0,4
ust_SampleStarts
  DS.L ust_samplesnum

; ** Variables **
; ---------------
ust_variables DS.B ust_variables_SIZE

; ** Names **
; -----------
gfxname DC.B "gfx.library",TRUE



; ************************* Module Data ***********************

; ** Module to be loaded as binary into CHIP memory **
; ----------------------------------------------------
ust_auddata SECTION audio,DATA_C

  INCBIN "MOD.example"

  END
