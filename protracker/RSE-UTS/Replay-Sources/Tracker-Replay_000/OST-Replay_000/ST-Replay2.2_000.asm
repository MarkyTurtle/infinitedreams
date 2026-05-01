; Program: ST-Replay2.2_000.asm
; Author:  Dissident^Resistance
; Date:    2021-05-01
; Version: 4.1
; CPU:     68000+
; FASTMEM:  -
; Chipset: OCS/ECS/AGA
; OS:      1.2+

; ** Supported trackers **
; - (old) Soundtracker 2.0
; - (old) Soundtracker 2.1
; - (old) Soundtracker 2.2

; ** Main characteristics **
; - 15 instruments
; - Sample repeat point in bytes
; - Sample length = repeat length
; - Raster dependent replay

; ** Code **
; - Improved and optimized for 68000+ CPUs

; ** Play Music trigger **
; - Label ost_PlayMusic: Called from vblank interrupt

; ** DMA Wait trigger **
; - Label ost_DMAWait: Called from CIA-B timer B interrupt triggered
;                      after 482.68 탎 on PAL machines or 478.27 탎
;                      on NTSC machines
; ** Loop samples **
; - Check for repeat length > 1 word, instead of repeat point not NULL
; - Loop samples with repeat point = NULL now properly detected

; ** Supported effect commands (cmd format 2) **
; 0 - Normal play or Arpeggio
; 1 - Portamento Up
; 2 - Portamento Down
; 3 - NOT USED
; 4 - NOT USED
; 5 - NOT USED
; 6 - NOT USED
; 7 - NOT USED
; 8 - NOT USED
; 9 - NOT USED
; A - NOT USED
; B - Position Jump
; C - Set Volume
; D - Pattern Break
; E - Set Filter
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
ost_DMABITS              EQU DMAF_AUD0+DMAF_AUD1+DMAF_AUD2+DMAF_AUD3 ;Audio DMA for all channels off
ost_CIABCRBBITS          EQU CIACRBF_LOAD+CIACRBF_RUNMODE ;CIA-B timer B oneshot mode

; ** Timer values **
ost_dmawaittime          EQU 342 ;= 0.709379 MHz * [482.68 탎 = Lowest note period C1 * 2 / PAL clock constant = 856*2/3546895 ticks per second]
                                 ;= 0.715909 MHz * [478.27 탎 = Lowest note period C1 * 2 / NTSC clock constant = 856*2/3579545 ticks per second]
; ** Song equals **
ost_maxsongpos           EQU 128
ost_maxpattpos           EQU 64
ost_pattsize             EQU 1024
ost_samplesnum           EQU 15

; ** Speed equals **
ost_defaultticks         EQU 6
ost_minticks             EQU 1
ost_maxticks             EQU 15

; ** Effect command masks equals **
ost_cmdpermask           EQU $0fff
ost_cmdnummask           EQU $0f

; ** Effect commands equals **
ost_periodsnum           EQU 36
ost_portminperiod        EQU 113 ;Note period "B-3"
ost_portmaxperiod        EQU 856 ;Note period "C-1"
ost_minvolume            EQU 0
ost_maxvolume            EQU 64


                                  
; ************************* Variables offsets ***********************

; ** Relative offsets for variables **
; ------------------------------------
  RSRESET
ost_SongDataPtr	    RS.L 1
ost_Counter	    RS.W 1
ost_CurrSpeed	    RS.W 1
ost_DMACONtemp	    RS.W 1
ost_PatternPosition RS.W 1
ost_SongPosition    RS.W 1
ost_PosJumpFlag	    RS.B 1
ost_SongLength      RS.B 1
ost_Variables_SIZE  RS.B 0


; ************************* Structures ***********************

; ** OST-Song-Structure **
; ------------------------

; ** OST SampleInfo structure **
  RSRESET
ost_sampleinfo      RS.B 0
ost_si_samplename   RS.B 22  ;Sample's name padded with null bytes
ost_si_samplelength RS.W 1   ;Sample length in words
ost_si_volume       RS.W 1   ;Bits 15-7 not used, bits 6-0 sample volume 0..64
ost_si_repeatpoint  RS.W 1   ;Start of sample repeat offset in bytes
ost_si_repeatlength RS.W 1   ;Length of sample repeat in words
ost_sampleinfo_SIZE RS.B 0

; ** OST SongData structure **
  RSRESET
ost_songdata       RS.B 0
ost_sd_songname    RS.B 20   ;Song's name padded with null bytes
ost_sd_sampleinfo  RS.B ost_sampleinfo_SIZE*ost_samplesnum ;Pointer to 1st sampleinfo, structure repeated for each sample 1-15
ost_sd_numofpatt   RS.B 1    ;Number of song positions 1..128
ost_sd_songspeed   RS.B 1    ;Default song speed 120 BPM is ignored
ost_sd_pattpos     RS.B 128  ;Pattern positions table 0..127
ost_sd_patterndata RS.B 0    ;Pointer to 1st pattern, structure repeated for each pattern 1..64 times
ost_songdata_SIZE  RS.B 0

; ** OST NoteInfo structure **
  RSRESET
ost_noteinfo      RS.B 0
ost_ni_note       RS.W 1     ;Bits 15-12 not used, bits 11-0 noteperiod
ost_ni_cmd        RS.B 1     ;Bits 7-4 sample number, bits 3-0 effect command number
ost_ni_cmdlo      RS.B 1     ;Bits 7-0 effect command data
ost_noteinfo_SIZE RS.B 0

; ** OST PatternPositionData structure **
  RSRESET
ost_pattposdata       RS.B 0
ost_ppd_chan1noteinfo RS.B ost_noteinfo_SIZE ;Note info for each audio channel 1..4 is stored successive
ost_ppd_chan2noteinfo RS.B ost_noteinfo_SIZE
ost_ppd_chan3noteinfo RS.B ost_noteinfo_SIZE
ost_ppd_chan4noteinfo RS.B ost_noteinfo_SIZE
ost_pattposdata_SIZE  RS.B 0

; ** OST PatternData structure **
  RSRESET
ost_patterndata      RS.B 0
ost_pd_data          RS.B ost_pattposdata_SIZE*ost_maxpattpos ;Repeated 64 times
ost_patterndata_SIZE RS.B 0

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
n_portperiod       RS.W 1
n_audchantemp_SIZE RS.B 0



  SECTION st_replay2.2,CODE

  MC68000

; ************************* Init music ***********************

; ** Do all audio inits **
; ------------------------
; Constant registers
; a3 ... Base of variables
; a4 ... Base of CIA-A
; a5 ... Base of CIA-B
; a6 ... Base of custom chips
  CNOP 0,4
ost_InitMusic
  lea     ost_Variables(pc),a3 ;Base of variables
  move.l  #_CIAB,a5          ;Base of CIA-B
  lea     _CIAA-_CIAB(a5),a4 ;Base of CIA-A
  move.l  #_CUSTOM,a6        ;Base of custom chips
  bsr.s   ost_InitTimer
  bsr.s   ost_InitRegisters
  bsr.s   ost_InitVariables
  bsr.s   ost_InitAudTempStrucs
  bra.s   ost_ExamineSongStruc

; ** Init wait dma timer **
  CNOP 0,4
ost_InitTimer
  moveq   #ost_dmawaittime&BYTEMASK,d0 ;DMA wait
  move.b  d0,CIATBLO(a5)     ;Set CIA-B timer B counter value low bits
  moveq   #ost_dmawaittime>>BYTESHIFTBITS,d0
  move.b  d0,CIATBHI(a5)     ;Set CIA-B timer B counter value high bits
  moveq   #ost_CIABCRBBITS,d0
  move.b  d0,CIACRB(a5)      ;Load oneshot timer B value
  rts

; ** Init main registers **
  CNOP 0,4
ost_InitRegisters
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
ost_InitVariables
  lea     ost_auddata,a0
  move.l  a0,ost_SongDataPtr(a3)
  moveq   #TRUE,d0
  move.w  d0,ost_Counter(a3)
  moveq   #ost_defaultticks,d2
  move.w  d2,ost_CurrSpeed(a3) ;Set as default 6 ticks
  move.w  d0,ost_DMACONtemp(a3)
  move.w  d0,ost_PatternPosition(a3)
  move.w  d0,ost_SongPosition(a3)
  move.b  d0,ost_PosJumpFlag(a3)
  rts

; ** Init temporary channel structures **
  CNOP 0,4
ost_InitAudTempStrucs
  moveq   #DMAF_AUD0,d0      ;DMA bit for channel1
  lea     ost_audchan1temp+n_dmabit(pc),a0
  move.w  d0,(a0)            ;Set DMA channel1 bit
  moveq   #DMAF_AUD1,d0      ;DMA bit for channel2
  lea     ost_audchan2temp+n_dmabit(pc),a0
  move.w  d0,(a0)            ;Set DMA channel2 bit
  moveq   #DMAF_AUD2,d0      ;DMA bit for channel3
  lea     ost_audchan3temp+n_dmabit(pc),a0
  move.w  d0,(a0)            ;Set DMA channel3 bit
  moveq   #DMAF_AUD3,d0      ;DMA bit for channel4
  lea     ost_audchan4temp+n_dmabit(pc),a0
  move.w  d0,(a0)            ;Set DMA channel4 bit
  rts

; ** Get highest pattern number and initialize sample pointers table **
  CNOP 0,4
ost_ExamineSongStruc
  move.l  ost_SongDataPtr(a3),a0 ;Pointer to song data
  moveq	  #TRUE,d0           ;First pattern number
  move.b  ost_sd_numofpatt(a0),ost_SongLength(a3) ;Get number of patterns
  moveq	  #TRUE,d1           ;Highest pattern number
  lea	  ost_sd_pattpos(a0),a1 ;Pointer to table with pattern positions in song
  moveq   #ost_maxsongpos-1,d7 ;Maximum number of song positions
ost_InitLoop
  move.b  (a1)+,d0           ;Get pattern number out of song position table
  cmp.b	  d1,d0              ;Pattern number <= previous pattern number ?
  ble.s	  ost_InitSkip       ;Yes -> skip
  move.l  d0,d1              ;Save higher pattern number
ost_InitSkip
  dbf	  d7,ost_InitLoop
  addq.w  #1,d1              ;Decrease highest pattern number
  lea     ost_sd_sampleinfo+ost_si_samplelength(a0),a0 ;First sample length
  swap    d1                 ;*ost_pattsize
  lsr.l   #6,d1              ;Offset points to end of last pattern
  moveq   #TRUE,d2           ;NULL to clear first word in sample data
  lea	  (a1,d1.l),a2       ;Skip patterndata -> Pointer to first sample data in module
  lea	  ost_SampleStarts(pc),a1 ;Table for sample pointers
  moveq	  #ost_sampleinfo_SIZE,d1 ;Length of sample info structure in bytes
  moveq	  #ost_samplesnum-1,d7 ;Number of samples in module
ost_InitLoop2
  move.l  a2,(a1)+           ;Save pointer to sample data
  move.w  (a0),d0            ;Get sample length
  beq.s   ost_NoSample       ;If length = NULL -> skip
  add.w   d0,d0              ;*2 = Sample length in bytes
  move.w  d2,(a2)            ;Clear first word in sample data
  add.l	  d0,a2              ;Add sample length to get pointer to next sample data
ost_NoSample
  add.l	  d1,a0              ;Next sample info structure in module
  dbf	  d7,ost_InitLoop2
  rts



; ************************* Play music ***********************

; ** PlayMusic called by vblank interrupt **
; ------------------------------------------
; Constant registers
; a3 ... Base of variables
; a4 ... Base of CIA-A
; a5 ... Base of CIA-B
; a6 ... Base of custom chips
; d5 ... NULL longword for all clear operations
; d6 ... Mask out sample number / FALSE.b
  CNOP 0,4
ost_PlayMusic
  movem.l d0-d7/a0-a6,-(a7)
  lea     ost_Variables(pc),a3 ;Base of variables
  move.l  #_CIAB,a5          ;Base of CIA-B
  lea     _CIAA-_CIAB(a5),a4 ;Base of CIA-A
  move.l  #_CUSTOM,a6        ;Base of custom chips
  moveq   #TRUE,d5           ;Constant: NULL longword for all delete operations
  addq.w  #1,ost_Counter(a3)  ;Increment ticks
  move.w  #ost_cmdpermask,d6 ;Constant: Mask out sample number
  move.w  ost_Counter(a3),d0 ;Get ticks
  lea     AUD0LCH(a6),a6     ;Pointer to first audio channel address in CUSTOM CHIP space
  cmp.w	  ost_CurrSpeed(a3),d0 ;Ticks < speed ticks ?
  bne.s	  ost_NoNewNote      ;Yes -> skip
  move.w  d5,ost_Counter(a3) ;If ticks >= speed ticks -> set back ticks counter = tick #1
  bra     ost_GetNewNote

; ** Check all audio channel for effect commands at ticks #2..#speed ticks **
  CNOP 0,4
ost_NoNewNote
  lea	  ost_audchan1temp(pc),a2 ;Pointer to first channel temporary structure (see above)
  bsr.s	  ost_CheckEffects
  lea	  ost_audchan2temp(pc),a2 ;Pointer to second channel temporary structure (see above)
  lea     16(a6),a6          ;Calculate CUSTOM CHIP pointer to next audio channel
  bsr.s	  ost_CheckEffects
  lea	  ost_audchan3temp(pc),a2 ;Pointer to third channel temporary structure (see above)
  lea     16(a6),a6 
  bsr.s	  ost_CheckEffects
  lea	  ost_audchan4temp(pc),a2 ;Pointer to fourth channel temporary structure (see above)
  lea     16(a6),a6 
  bsr.s   ost_CheckEffects
  bra     ost_NoNewPositionYet

; ** Check audio channel for effect commands **
  CNOP 0,4
ost_CheckEffects
  move.w  n_cmd(a2),d0       ;Get channel effect command
  and.w	  d6,d0              ;without nibble of sample number
  beq.s	  ost_ChkEfxEnd      ;If no command -> skip
  moveq   #ost_cmdnummask,d0 ;Get channel effect command without nibble of sample number
  and.b   n_cmd(a2),d0       ;0 "Arpeggio" ?
  beq.s	  ost_Arpeggio
  subq.b  #1,d0              ;1 "Portamento Up" ?
  beq.s	  ost_PortamentoUp
  subq.b  #1,d0              ;2 "Portamento Down" ?
  beq.s   ost_PortamentoDown
ost_ChkEfxEnd
  rts

; ** Effect command 0xy "Normal play" or "Arpeggio" **
  CNOP 0,4
ost_Arpeggio
  move.w  ost_Counter(a3),d0 ;Get ticks
  subq.b  #1,d0              ;$01 = Add first halftone at tick #2 ?
  beq.s   ost_Arpeggio1
  subq.b  #1,d0              ;$02 = Add second halftone at tick #3 ?
  beq.s   ost_Arpeggio2
  subq.b  #1,d0              ;$03 = Play note period at tick #4
  beq.s   ost_Arpeggio0
  subq.b  #1,d0              ;$04 = Add first halftone at tick #5 ?
  beq.s   ost_Arpeggio1
  subq.b  #1,d0              ;$05 = Add second halftone at tick #6 ?
  beq.s   ost_Arpeggio2
  rts
; ** Effect command 000 "Normal Play" 1st note **
  CNOP 0,4
ost_Arpeggio0
  move.w  n_period(a2),d2    ;Play note period at tick #1
ost_ArpeggioSet
  move.w  d2,6(a6)           ;AUDxPER Set new note period
  rts
; ** Effect command 0x0 "Arpeggio" 2nd note **
  CNOP 0,4
ost_Arpeggio1
  move.b  n_cmdlo(a2),d0     
  lsr.b	  #NIBBLESHIFTBITS,d0 ;Get command data: x-first halftone
  bra.s	  ost_ArpeggioFind
; ** Effect command 00y "Arpeggio" 3rd note **
  CNOP 0,4
ost_Arpeggio2
  moveq   #NIBBLEMASKLO,d0
  and.b   n_cmdlo(a2),d0     ;Get command data: y-second halftone
ost_ArpeggioFind
  lea	  ost_PeriodTable(pc),a1 ;Pointer to period table
  add.w   d0,d0              ;Halftone *2
  move.w  n_period(a2),d2    ;Get note period
  moveq   #((ost_PeriodTableEnd-ost_PeriodTable)/2)-1,d7 ;Number of periods
ost_ArpLoop
  cmp.w	  (a1)+,d2           ;Note >= table note period ?
  dbeq	  d7,ost_ArpLoop     ;If not -> loop until note period found or loop counter = FALSE
ost_ArpFound
  move.w  -2(a1,d0.w),d2     ;Get note period + first or second halftone addition
  bra.s	  ost_ArpeggioSet

; ** Effect command 1xx "Portamento Up" **
  CNOP 0,4
ost_PortamentoUp
  move.w  n_portperiod(a2),d2 ;Get note period
  move.b  n_cmdlo(a2),d0     ;Get command data: xx-upspeed
  sub.w	  d0,d2              ;Note period - upspeed
  cmp.w	  #ost_portminperiod,d2 ;Note period >= highest note period "B-3" ?
  bpl.s	  ost_PortaUpSkip    ;Yes -> skip
  moveq   #ost_portminperiod,d2 ;Set highest note period "B-3"
ost_PortaUpSkip
  move.w  d2,n_portperiod(a2) ;Save new note period
  move.w  d2,6(a6)           ;AUDxPER Set new note period
ost_PortaUpEnd
  rts

; ** Effect command 2xx "Portamento Down" **
  CNOP 0,4
ost_PortamentoDown
  move.w  n_portperiod(a2),d2 ;Get note period
  move.b  n_cmdlo(a2),d0     ;Get command data: xx-downspeed
  add.w	  d0,d2              ;Note period + downspeed
  cmp.w	  #ost_portmaxperiod,d2 ;Note period < lowest note period "C-1" ?
  bmi.s	  ost_PortaDownSkip  ;Yes -> skip
  move.w  #ost_portmaxperiod,d2 ;Set lowest note period "C-1"
ost_PortaDownSkip
  move.w  d2,n_portperiod(a2) ;Save new note period
  move.w  d2,6(a6)           ;AUDxPER Set new note period
ost_PortaDownEnd
  rts

; ** Get new note and pattern position at tick #1 **
  CNOP 0,4
ost_GetNewNote
  move.l  ost_SongDataPtr(a3),a0 ;Pointer to module
  move.w  ost_SongPosition(a3),d0 ;Get song position
  add.w   #ost_sd_pattpos,d0 ;Offset pattern position table
  moveq	  #TRUE,d1           ;NULL needed for word access
  move.b  (a0,d0.w),d1       ;Get pattern number in song position table
  lsl.w   #BYTESHIFTBITS,d1  ;*(pt_pattsize/4) = Pattern offset
  add.w	  ost_PatternPosition(a3),d1 ;Add pattern position
  move.w  d5,ost_DMACONtemp(a3) ;Clear DMA bits
  lea	  ost_audchan1temp(pc),a2 ;Pointer to audio channel temporary structure
  bsr.s   ost_PlayVoice
  lea	  ost_audchan2temp(pc),a2
  lea     16(a6),a6              ;Next audio channel CUSTOM address
  bsr.s   ost_PlayVoice
  lea	  ost_audchan3temp(pc),a2
  lea     16(a6),a6
  bsr.s   ost_PlayVoice
  lea	  ost_audchan4temp(pc),a2
  lea     16(a6),a6
  bsr.s   ost_PlayVoice
  bra     ost_SetDMA

; ** Get new note data **
  CNOP 0,4
ost_PlayVoice
  moveq   #127,d0            ;127
  add.w   d1,d0              ;Add pattern position
  add.l   d0,d0              ;*4
  add.l   d0,d0
  moveq   #TRUE,d2           ;NULL needed for word access
  move.l  ost_sd_patterndata-(127*4)(a0,d0.l),(a2) ;Get new note data from pattern
  addq.w  #ost_noteinfo_SIZE/4,d1 ;Next channel data
  move.b  n_cmd(a2),d2       
  lsr.b	  #NIBBLESHIFTBITS,d2 ;Get nibble of sample number
  beq.s	  ost_SetRegisters    ;If NULL -> skip
  subq.w  #1,d2              ;x = sample number -1
  lea	  ost_SampleStarts(pc),a1 ;Pointer to sample pointers table
  add.w   d2,d2              ;x*2
  move.w  d2,d3              ;Save x*2
  add.w   d2,d2              ;x*2
  move.l  (a1,d2.w),a1       ;Get sample data pointer
  lsl.w   #3,d2              ;x*8
  sub.w   d3,d2              ;(x*32)-(x*2) = sample info structure length in bytes
  movem.w ost_sd_sampleinfo+ost_si_samplelength(a0,d2.w),d0/d2-d4 ;length, volume, repeat point, repeat length
  move.w  d2,n_volume(a2)    ;Save sample volume
  move.w  d2,8(a6)	     ;AUDxVOL Set new volume
  cmp.w   #1,d4              ;Repeat length = 1 word ?
  beq.s	  ost_NoLoopSample   ;Yes -> skip
ost_LoopSample
  move.w  d4,d0              ;Sample length = repeat length
  add.l	  d3,a1	             ;Add repeat point
ost_NoLoopSample
  move.w  d0,n_length(a2)    ;Save sample length
  move.w  d4,n_replen(a2)    ;Save repeat length
  move.l  a1,n_start(a2)     ;Save sample start
  move.l  a1,n_loopstart(a2) ;Save loop start

ost_SetRegisters
  move.w  (a2),d3            ;Get note period from pattern position
  beq.s   ost_CheckMoreEffects ;If no note period -> skip

ost_SetPeriod
  move.w  d3,n_period(a2)    ;Save new note period
  move.w  d3,n_portperiod(a2) ;Save new note period for "Portamento Up/Down" effect command
  move.w  n_dmabit(a2),d0    ;Get audio channel DMA bit
  or.w	  d0,ost_DMACONtemp(a3) ;Set audio channel DMA bit
  move.w  d0,_CUSTOM+DMACON  ;Audio channel DMA off
  move.l  n_start(a2),(a6)   ;AUDxLCH Set sample start
  move.l  n_length(a2),4(a6) ;AUDxLEN & AUDxPER Set length & new note period

; ** Check audio channel for more effect commands at tick #1 **
ost_CheckMoreEffects
  moveq   #ost_cmdnummask,d0
  and.b   n_cmd(a2),d0       ;Get channel effect command number without nibble of sample number
  subq.b  #8,d0              ;0..8 ?
  ble.s   ost_ChkMoreEfxEnd  ;Yes -> skip
  subq.b  #3,d0              ;B "Position Jump" ?
  beq.s	  ost_PositionJump
  subq.b  #1,d0              ;C "Set Volume" ?
  beq.s	  ost_SetVolume
  subq.b  #1,d0              ;D "Pattern Break" ?
  beq.s	  ost_PatternBreak
  subq.b  #1,d0              ;E "Set Filter" ?
  beq.s	  ost_SetFilter
  subq.b  #1,d0              ;F "Set Speed" ?
  beq.s   ost_SetSpeed
ost_ChkMoreEfxEnd
  rts

; ** Effect command Bxx "Position Jump" **
  CNOP 0,4
ost_PositionJump
  move.b  n_cmdlo(a2),d0     ;Get command data: xx-song position
  subq.b  #1,d0              ;Decrement song position
  not.b   ost_PosJumpFlag(a3) ;Invert position jump flag
  move.w  d0,ost_SongPosition(a3) ;Save new song position
  rts

; ** Effect command Cxx "Set Volume" **
  CNOP 0,4
ost_SetVolume
  move.b  n_cmdlo(a2),d0     ;Get command data: xx-volume
  move.w  d0,8(a6)           ;AUDxVOL Set new volume
  rts

; ** Effect command D00 "Pattern Break" **
  CNOP 0,4
ost_PatternBreak
  not.b   ost_PosJumpFlag(a3) ;Invert position jump flag
  rts

; ** Effect command E0x "Set Filter" **
  CNOP 0,4
ost_SetFilter
  moveq   #1,d0
  and.b   n_cmdlo(a2),d0     ;Get command data: 0-filter on 1-filter off
  bne.s   ost_FilterOff      ;If 1-filter off -> skip
ost_FilterOn
  moveq   #-(-~CIAF_LED&BYTEMASK),d0
  and.b   d0,(a4)            ;Turn filter on
  rts
  CNOP 0,4
ost_FilterOff
  moveq   #CIAF_LED,d0
  or.b    d0,(a4)            ;Turn filter off
  rts

; ** Effect command Fxx "Set Speed" **
  CNOP 0,4
ost_SetSpeed
  moveq   #ost_maxticks,d0   ;Mask for maximum ticks
  and.b   n_cmdlo(a2),d0     ;Get command data: xx-speed ($00-$0f ticks)
  beq.s   ost_SetSpdEnd      ;If speed = NULL -> skip
  move.w  d5,ost_Counter(a3) ;Set back ticks counter = tick #1
  move.w  d0,ost_CurrSpeed(a3) ;Set new speed ticks
ost_SetSpdEnd
  rts

  CNOP 0,4
ost_SetDMA
  moveq   #CIACRBF_START,d0
  or.b    d0,CIACRB(a5)      ;CIA-B timer B Start timer for DMA wait

ost_Dskip
  addq.w  #ost_pattposdata_SIZE/4,ost_PatternPosition(a3) ;Next pattern position
  cmp.w	  #ost_pattsize/4,ost_PatternPosition(a3) ;End of pattern reached ?
  bne.s	  ost_NoNewPositionYet ;No -> skip
ost_NextPosition
  move.b  d5,ost_PosJumpFlag(a3) ;Clear position jump flag
  move.w  ost_SongPosition(a3),d1 ;Get song position
  move.w  d5,ost_PatternPosition(a3) ;Set back pattern position = NULL
  addq.w  #1,d1              ;Next song position
  move.w  d1,ost_SongPosition(a3) ;Save new song position
  cmp.b	  ost_SongLength(a3),d1 ;Last song position reached ?
  bne.s	  ost_NoNewPositionYet ;No -> skip
  move.w  d5,ost_SongPosition(a3) ;Set back song position = NULL
ost_NoNewPositionYet
  tst.b	  ost_PosJumpFlag(a3) ;Position jump flag set ?
  bne.s	  ost_NextPosition   ;Yes -> skip
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
st_DMAWait
  movem.l d0-d7/a0-a6,-(a7)
  lea     ost_Variables(pc),a3 ;Base of variables
  move.l  #_CIAB,a5          ;Base of CIA-B
  move.l  #_CUSTOM,a6        ;Base of custom chips
  bsr.s   ost_CheckDMAWait
  movem.l (a7)+,d0-d7/a0-a6
  rts

; ** Check DMA wait routine to be executed **
  CNOP 0,4
ost_CheckDMAWait
  move.w  ost_DMACONtemp(a3),d0 ;Get channel DMA bits
  or.w	  #DMAF_SETCLR,d0    ;DMA on
  move.w  d0,DMACON(a6)      ;Set channel DMA bits

  moveq   #1,d0              ;Length = 1 word
  cmp.w   ost_audchan1temp+n_replen(pc),d0 ;Repeat length = 1 word ?
  bne.s   ost_Audchan0Loop    ;No -> Loop sample
  move.l  ost_audchan1temp+n_loopstart(pc),AUD0LCH(a6) ;Set loop start for channel 1
  move.w  d0,AUD0LEN(a6)   ;Set repeat length for channel 1
ost_Audchan0Loop
  cmp.w   ost_audchan2temp+n_replen(pc),d0 ;Repeat length = 1 word ?
  bne.s   ost_Audchan1Loop    ;No -> Loop sample
  move.l  ost_audchan2temp+n_loopstart(pc),AUD1LCH(a6) ;Set loop start for channel 2
  move.w  d0,AUD1LEN(a6)   ;Set repeat length for channel 2
ost_Audchan1Loop
  cmp.w   ost_audchan3temp+n_replen(pc),d0 ;Repeat length = 1 word ?
  bne.s   ost_Audchan2Loop    ;No -> Loop sample
  move.l  ost_audchan3temp+n_loopstart(pc),AUD2LCH(a6) ;Set loop start for channel 3
  move.w  d0,AUD2LEN(a6)   ;Set repeat length for channel 3
ost_Audchan2Loop
  cmp.w   ost_audchan4temp+n_replen(pc),d0 ;Repeat length = 1 word ?
  bne.s   ost_Audchan3Loop    ;No -> Loop sample
  move.l  ost_audchan4temp+n_loopstart(pc),AUD3LCH(a6) ;Set loop start for channel 4
  move.w  d0,AUD3LEN(a6)   ;Set repeat length for channel 4
ost_Audchan3Loop
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
st_StopMusic
  lea     ost_Variables(pc),a3 ;Base of variables
  move.l  #_CIAB,a5          ;Base of CIA-B
  lea     _CIAA-_CIAB(a5),a4 ;Base of CIA-A
  move.l  #_CUSTOM,a6        ;Base of custom chips
  bsr.s   st_StopTimer
  bra.s   st_SetBackRegisters

; ** Stop all timers **
  CNOP 0,4
st_StopTimer
  move.b  CIACRB(a5),d0
  and.b   #~(CIACRBF_START),d0 ;Stop CIA-B oneshot timer B
  move.b  d0,CIACRB(a5)
  rts

; ** Stop all audio and restore soundfilter **
  CNOP 0,4
st_SetBackRegisters
  moveq   #TRUE,d0
  move.w  d0,AUD0VOL(a6)     ;Clear volume for all channels
  move.w  d0,AUD1VOL(a6)
  move.w  d0,AUD2VOL(a6)
  move.w  d0,AUD3VOL(a6)
  move.w  #ost_DMABITS,DMACON(a6) ;Turn audio DMA off
  moveq   #-(-(~CIAF_LED)&BYTEMASK),d0
  and.b   d0,CIAPRA(a4)      ;Turn soundfilter off
  rts



; ************************* Tables & variables ***********************

; ** Tables for effect command **
; -------------------------------

; ** "Arpeggio" **
  CNOP 0,2
ost_PeriodTable
; Note C   C#  D   D#  E   F   F#  G   G#  A   A#  B
  DC.W 856,808,762,720,678,640,604,570,538,508,480,453 ;Octave 1
  DC.W 428,404,381,360,339,320,302,285,269,254,240,226 ;Octave 2
  DC.W 214,202,190,180,170,160,151,143,135,127,120,113 ;Octave 3
  DC.W 000                                             ;Noop
ost_PeriodTableEnd

; ** Temporary channel structures **
; ----------------------------------
  CNOP 0,4
ost_audchan1temp
  DS.B n_audchantemp_SIZE

  CNOP 0,4
ost_audchan2temp
  DS.B n_audchantemp_SIZE

  CNOP 0,4
ost_audchan3temp
  DS.B n_audchantemp_SIZE

  CNOP 0,4
ost_audchan4temp
  DS.B n_audchantemp_SIZE

; ** Pointers to samples **
; -------------------------
  CNOP 0,4
ost_SampleStarts
  DS.L ost_samplesnum

; ** Variables **
; ---------------
ost_variables DS.B ost_variables_SIZE

; ** Names **
; -----------
gfxname DC.B "gfx.library",TRUE



; ************************* Module Data ***********************

; ** Module to be loaded as binary into CHIP memory **
; ----------------------------------------------------
ost_auddata SECTION audio,DATA_C

  INCBIN "MOD.example"

  END
