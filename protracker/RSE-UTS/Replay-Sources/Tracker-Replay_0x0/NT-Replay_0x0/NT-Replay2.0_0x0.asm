; Program: NT-Replay2.0_0x0.asm
; Author:  Dissident^Resistance
; Date:    2021-05-01
; Version: 4.1
; CPU:     68020+
; FASTMEM:  -
; Chipset: OCS/ECS/AGA
; OS:      1.2+

; ** Supported trackers **
; - Noisetracker 2.x
; - Startrekker  1.x

; ** Main characteristics **
; - 31 instruments
; - Sample repeat point in words
; - Global song restart position
; - Raster dependent replay

; ** Code **
; - Improved and optimized for 68020+ CPUs

; ** Play music trigger **
; - Label nt_PlayMusic: Called from vblank interrupt

; ** DMA wait trigger **
; - Label nt_DMAWait: Called from CIA-B timer B interrupt triggered
;                     after 482.68 탎 on PAL machines or 478.27 탎
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
; 7 - NOT USED
; 8 - NOT USED
; 9 - NOT USED
; A - Volume Slide
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
nt_DMABITS               EQU DMAF_AUD0+DMAF_AUD1+DMAF_AUD2+DMAF_AUD3 ;Audio DMA for all channels off
nt_CIABCRBBITS           EQU CIACRBF_LOAD+CIACRBF_RUNMODE ;CIA-B timer B oneshot mode

; ** Timer values **
nt_dmawaittime           EQU 342 ;= 0.709379 MHz * [482.68 탎 = Lowest note period C1 * 2 / PAL clock constant = 856*2/3546895 ticks per second]
                                 ;= 0.715909 MHz * [478.27 탎 = Lowest note period C1 * 2 / NTSC clock constant = 856*2/3579545 ticks per second]
; ** Song equals **
nt_maxsongpos            EQU 128
nt_maxpattpos            EQU 64
nt_pattsize              EQU 1024
nt_samplesnum            EQU 31

; ** Speed equals **
nt_defaultticks          EQU 6
nt_minticks              EQU 1
nt_maxticks              EQU 31

; ** Effect command masks equals **
nt_cmdpermask            EQU $0fff
nt_cmdnummask            EQU $0f

; ** Effect commands equals **
nt_arpdiv                EQU 3
nt_periodsnum            EQU 36
nt_portminperiod         EQU 113 ;Note period "B-3"
nt_portmaxperiod         EQU 856 ;Note period "C-1"
nt_finetunenum           EQU 16
nt_minvolume             EQU 0
nt_maxvolume             EQU 64


                                  
; ************************* Variables offsets ***********************

; ** Relative offsets for variables **
; ------------------------------------
  RSRESET
nt_SongDataPtr	           RS.L 1
nt_Counter	           RS.W 1
nt_CurrSpeed	           RS.W 1
nt_DMACONtemp	           RS.W 1
nt_PatternPosition         RS.W 1
nt_SongPosition	           RS.W 1
nt_PosJumpFlag	           RS.B 1
nt_SongLength              RS.B 1
nt_SongRestartPosition     RS.B 1
nt_SetAllChanDMAFlag       RS.B 1
nt_InitAllChanLoopDataFlag RS.B 1
nt_variables_SIZE          RS.B 0



; ************************* Structures ***********************

; ** NT-Song-Structure **
; -----------------------

; ** NT SampleInfo structure **
  RSRESET
nt_sampleinfo      RS.B 0
nt_si_samplename   RS.B 22   ;Sample's name padded with null bytes
nt_si_samplelength RS.W 1    ;Sample length in bytes or words
nt_si_volume       RS.W 1    ;Bit 7 not used, bits 6-0 sample volume 0..64
nt_si_repeatpoint  RS.W 1    ;Start of sample repeat offset in words
nt_si_repeatlength RS.W 1    ;Length of sample repeat in words
nt_sampleinfo_SIZE RS.B 0

; ** NT SongData structure **
  RSRESET
nt_songdata        RS.B 0
nt_sd_songname     RS.B 20   ;Song's name padded with null bytes
nt_sd_sampleinfo   RS.B nt_sampleinfo_SIZE*nt_samplesnum ;Pointer to 1st sampleinfo, structure repeated for each sample 1-31
nt_sd_numofpatt    RS.B 1    ;Number of song positions 1..128
nt_sd_restartpos   RS.B 1    ;Song restart position in pattern positions table 0..126
nt_sd_pattpos      RS.B 128  ;Pattern positions table 0..127
nt_sd_id           RS.B 4    ;"M.K." (4 channels, 31 samples, 64 patterns)
nt_sd_patterndata  RS.B 0    ;Pointer to 1st pattern, structure repeated for each pattern 1..64 times
nt_songdata_SIZE   RS.B 0

; ** NT NoteInfo structure **
  RSRESET
nt_noteinfo      RS.B 0
nt_ni_note       RS.W 1      ;Bits 15-12 upper nibble of sample number, bits 11-0 note period
nt_ni_cmd        RS.B 1      ;Bits 7-4 lower nibble of sample number, bits 3-0 effect command number
nt_ni_cmdlo      RS.B 1      ;Bits 7-0 effect command data / bits 7-4 effect e-command number, bits 3-0 effect e-command data
nt_noteinfo_SIZE RS.B 0

; ** NT PatternPositionData structure **
  RSRESET
nt_pattposdata       RS.B 0
nt_ppd_chan1noteinfo RS.B nt_noteinfo_SIZE ;Note info for each audio channel 1..4 is stored successive
nt_ppd_chan2noteinfo RS.B nt_noteinfo_SIZE
nt_ppd_chan3noteinfo RS.B nt_noteinfo_SIZE
nt_ppd_chan4noteinfo RS.B nt_noteinfo_SIZE
nt_pattposdata_SIZE  RS.B 0

; ** NT PatternData structure **
  RSRESET
nt_patterndata      RS.B 0
nt_pd_data          RS.B nt_pattposdata_SIZE*nt_maxpattpos ;Repeated 64 times (standard PT) or upto 100 times (PT 2.3a)
nt_patterndata_SIZE RS.B 0

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
n_toneportdirec    RS.B 1
n_toneportspeed    RS.B 1
n_wantedperiod     RS.W 1
n_vibratocmd       RS.B 1
n_vibratopos       RS.B 1
n_audchantemp_SIZE RS.B 0



  SECTION nt_replay2.0,CODE

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
nt_InitMusic
  lea     nt_Variables(pc),a3 ;Base of variables
  move.l  #_CIAB,a5          ;Base of CIA-B
  lea     _CIAA-_CIAB(a5),a4 ;Base of CIA-A
  move.l  #_CUSTOM,a6        ;Base of custom chips
  bsr.s   nt_InitTimer
  bsr.s   nt_InitRegisters
  bsr.s   nt_InitVariables
  bsr.s   nt_InitAudTempStrucs
  bra     nt_ExamineSongStruc

; ** Init wait dma timer **
  CNOP 0,4
nt_InitTimer
  moveq   #nt_dmawaittime&BYTEMASK,d0 ;DMA wait
  move.b  d0,CIATBLO(a5)     ;Set CIA-B timer B counter value low bits
  moveq   #nt_dmawaittime>>BYTESHIFTBITS,d0
  move.b  d0,CIATBHI(a5)     ;Set CIA-B timer B counter value high bits
  moveq   #nt_CIABCRBBITS,d0
  move.b  d0,CIACRB(a5)      ;Load oneshot timer B value
  rts

; ** Init main registers **
  CNOP 0,4
nt_InitRegisters
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
nt_InitVariables
  lea     nt_auddata,a0
  move.l  a0,nt_SongDataPtr(a3)
  moveq   #TRUE,d0
  move.w  d0,nt_Counter(a3)
  moveq   #nt_defaultticks,d2
  move.w  d2,nt_CurrSpeed(a3) ;Set as default 6 ticks
  move.w  d0,nt_DMACONtemp(a3)
  move.w  d0,nt_PatternPosition(a3)
  move.w  d0,nt_SongPosition(a3)
  move.b  d0,nt_PosJumpFlag(a3)
  moveq   #FALSE,d1
  move.b  d1,nt_SetAllChanDMAFlag(a3) ;Deactivate set routine
  move.b  d1,nt_InitAllChanLoopDataFlag(a3) ;Deactivate init routine
  rts

; ** Init temporary channel structures **
  CNOP 0,4
nt_InitAudTempStrucs
  moveq   #DMAF_AUD0,d0      ;DMA bit for channel1
  lea     nt_audchan1temp+n_dmabit(pc),a0
  move.w  d0,(a0)            ;Set DMA channel1 bit
  moveq   #DMAF_AUD1,d0      ;DMA bit for channel2
  lea     nt_audchan2temp+n_dmabit(pc),a0
  move.w  d0,(a0)            ;Set DMA channel2 bit
  moveq   #DMAF_AUD2,d0      ;DMA bit for channel3
  lea     nt_audchan3temp+n_dmabit(pc),a0
  move.w  d0,(a0)            ;Set DMA channel3 bit
  moveq   #DMAF_AUD3,d0      ;DMA bit for channel4
  lea     nt_audchan4temp+n_dmabit(pc),a0
  move.w  d0,(a0)            ;Set DMA channel4 bit
  rts

; ** Get highest pattern number and initialize sample pointers table **
  CNOP 0,4
nt_ExamineSongStruc
  move.l  nt_SongDataPtr(a3),a0 ;Pointer to song data
  moveq	  #TRUE,d0           ;First pattern number
  move.b  nt_sd_numofpatt(a0),nt_SongLength(a3) ;Get number of patterns
  moveq	  #TRUE,d1           ;Highest pattern number
  move.b  nt_sd_restartpos(a0),nt_SongRestartPosition(a3) ;Get song restart position
  lea	  nt_sd_pattpos(a0),a1 ;Pointer to table with pattern positions in song
  moveq   #nt_maxsongpos-1,d7 ;Maximum number of song positions
nt_InitLoop
  move.b  (a1)+,d0           ;Get pattern number out of song position table
  cmp.b	  d1,d0              ;Pattern number <= previous pattern number ?
  ble.s	  nt_InitSkip        ;Yes -> skip
  move.l  d0,d1              ;Save higher pattern number
nt_InitSkip
  dbf	  d7,nt_InitLoop
  addq.w  #1,d1              ;Decrease highest pattern number
  add.w   #nt_sd_sampleinfo+nt_si_samplelength,a0 ;First sample length
  lsl.w   #BYTESHIFTBITS,d1  ;*(nt_pattsize/8) = Offset points to end of last pattern
  moveq   #TRUE,d2           ;NULL to clear first word in sample data
  lea	  nt_sd_patterndata-nt_sd_id(a1,d1.w*8),a2 ;Skip MOD-ID and patterndata -> Pointer to first sample data in module
  lea	  nt_SampleStarts(pc),a1 ;Table for sample pointers
  moveq	  #nt_sampleinfo_SIZE,d1 ;Length of sample info structure in bytes
  moveq	  #nt_samplesnum-1,d7 ;Number of samples in module
nt_InitLoop2
  move.l  a2,(a1)+           ;Save pointer to sample data
  move.w  (a0),d0            ;Get sample length
  beq.s   nt_NoSample        ;If length = NULL -> skip
  add.w   d0,d0              ;*2 = Sample length in bytes
  move.w  d2,(a2)            ;Clear first word in sample data
  add.l	  d0,a2              ;Add sample length to get pointer to next sample data
nt_NoSample
  add.l	  d1,a0              ;Next sample info structure in module
  dbf	  d7,nt_InitLoop2
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
nt_PlayMusic
  movem.l d0-d7/a0-a6,-(a7)
  lea     nt_Variables(pc),a3 ;Base of variables
  move.l  #_CIAB,a5          ;Base of CIA-B
  lea     _CIAA-_CIAB(a5),a4 ;Base of CIA-A
  move.l  #_CUSTOM,a6        ;Base of custom chips
  moveq   #TRUE,d5           ;Constant: NULL longword for all delete operations
  addq.w  #1,nt_Counter(a3)  ;Increment ticks
  move.w  #nt_cmdpermask,d6  ;Constant: Mask out sample number
  move.w  nt_Counter(a3),d0  ;Get ticks
  add.w   #AUD0LCH,a6        ;Pointer to first audio channel address in CUSTOM CHIP space
  cmp.w	  nt_CurrSpeed(a3),d0 ;Ticks < speed ticks ?
  blo.s	  nt_NoNewNote       ;Yes -> skip
  move.w  d5,nt_Counter(a3)  ;If ticks >= speed ticks -> set back ticks counter = tick #1
  bra     nt_GetNewNote

; ** Check all audio channel for effect commands at ticks #2..#speed ticks **
  CNOP 0,4
nt_NoNewNote
  lea	  nt_audchan1temp(pc),a2 ;Pointer to first channel temporary structure (see above)
  bsr.s	  nt_CheckEffects
  addq.w  #8,a6              ;Calculate CUSTOM CHIP pointer to next audio channel
  lea	  nt_audchan2temp(pc),a2 ;Pointer to second channel temporary structure (see above)
  addq.w  #8,a6
  bsr.s	  nt_CheckEffects
  addq.w  #8,a6
  lea	  nt_audchan3temp(pc),a2 ;Pointer to third channel temporary structure (see above)
  addq.w  #8,a6
  bsr.s	  nt_CheckEffects
  addq.w  #8,a6
  lea	  nt_audchan4temp(pc),a2 ;Pointer to fourth channel temporary structure (see above)
  addq.w  #8,a6
  bsr.s   nt_CheckEffects
  bra     nt_NoNewPositionYet

; ** Check audio channel for effect commands **
  CNOP 0,4
nt_CheckEffects
  move.w  n_cmd(a2),d0       ;Get channel effect command
  and.w	  d6,d0              ;without lower nibble of sample number
  beq.s	  nt_ChkEfxPerNop    ;If no command -> skip
  lsr.w   #BYTESHIFTBITS,d0  ;0 "Arpeggio" ?
  beq.s	  nt_Arpeggio
  subq.b  #1,d0              ;1 "Portamento Up" ?
  beq.s	  nt_PortamentoUp
  subq.b  #1,d0              ;2 "Portamento Down" ?
  beq     nt_PortamentoDown
  subq.b  #1,d0              ;3 "Tone Portamento" ?
  beq     nt_TonePortamento
  subq.b  #1,d0              ;4 "Vibrato" ?
  beq     nt_Vibrato
  subq.b  #1,d0              ;5 "Tone Portamento + Volume Slide" ?
  beq	  nt_TonePortaPlusVolSlide
  subq.b  #1,d0              ;6 "Vibrato + Volume Slide" ?
  beq	  nt_VibratoPlusVolSlide
nt_SetBack
  move.w  n_period(a2),6(a6) ;AUDxPER Set back period
  subq.b  #4,d0              ;A "Volume Slide" ?
  beq	  nt_VolumeSlide
  rts
  CNOP 0,4
nt_ChkEfxPerNop
  move.w  n_period(a2),6(a6) ;AUDxPER Set back period
  rts

; ** Effect command 0xy "Normal play" or "Arpeggio" **
  CNOP 0,4
nt_Arpeggio
  move.w  nt_Counter(a3),d0  ;Get ticks
nt_ArpDivLoop
  subq.w  #nt_ArpDiv,d0      ;Substract divisor from dividend
  bge.s   nt_ArpDivLoop      ;until dividend < divisor
  addq.w  #nt_ArpDiv,d0      ;Adjust division remainder
  subq.w  #1,d0              ;Remainder = $0001 = Add first halftone at tick #2 ?
  beq.s	  nt_Arpeggio1       ;Yes -> skip
  subq.w  #1,d0              ;Remainder = $0002 = Add second halftone at tick #3 ?
  beq.s	  nt_Arpeggio2       ;Yes -> skip
; ** Effect command 000 "Normal Play" 1st note **
nt_Arpeggio0
  move.w  n_period(a2),d2    ;Play note period at tick #1
nt_ArpeggioSet
  move.w  d2,6(a6)           ;AUDxPER Set new note period
  rts
; ** Effect command 0x0 "Arpeggio" 2nd note **
  CNOP 0,4
nt_Arpeggio1
  move.b  n_cmdlo(a2),d0     
  lsr.b	  #NIBBLESHIFTBITS,d0 ;Get command data: x-first halftone
  bra.s	  nt_ArpeggioFind
; ** Effect command 00y "Arpeggio" 3rd note **
  CNOP 0,4
nt_Arpeggio2
  moveq   #NIBBLEMASKLO,d0
  and.b   n_cmdlo(a2),d0     ;Get command data: y-second halftone
nt_ArpeggioFind
  lea	  nt_PeriodTable(pc),a1 ;Pointer to period table
  move.w  n_period(a2),d2    ;Get note period
  moveq   #((nt_PeriodTableEnd-nt_PeriodTable)/2)-1,d7 ;Number of periods
nt_ArpLoop
  cmp.w	  (a1)+,d2           ;Note period >= table note period ?
  dbhs	  d7,nt_ArpLoop      ;If not -> loop until counter = FALSE
nt_ArpFound
  move.w  -2(a1,d0.w*2),d2   ;Get note period + first or second halftone addition
  bra.s	  nt_ArpeggioSet

; ** Effect command 1xx "Portamento Up" **
  CNOP 0,4
nt_PortamentoUp
  move.w  n_period(a2),d2    ;Get note period
  move.b  n_cmdlo(a2),d0     ;Get command data: xx-upspeed
  sub.w	  d0,d2              ;Note period - upspeed
  cmp.w	  #nt_portminperiod,d2 ;Note period >= highest note period "B-3" ?
  bpl.s	  nt_PortaUpSkip     ;Yes -> skip
  moveq   #nt_portminperiod,d2 ;Set highest note period "B-3"
nt_PortaUpSkip
  move.w  d2,n_period(a2)    ;Save new note period
  move.w  d2,6(a6)           ;AUDxPER Set new note period
nt_PortaUpEnd
  rts

; ** Effect command 2xx "Portamento Down" **
  CNOP 0,4
nt_PortamentoDown
  move.w  n_period(a2),d2    ;Get note period
  move.b  n_cmdlo(a2),d0     ;Get command data: xx-downspeed
  add.w	  d0,d2              ;Note period + downspeed
  cmp.w	  #nt_portmaxperiod,d2 ;Note period < lowest note period "C-1" ?
  bmi.s	  nt_PortaDownSkip   ;Yes -> skip
  move.w  #nt_portmaxperiod,d2 ;Set lowest note period "C-1"
nt_PortaDownSkip
  move.w  d2,n_period(a2)    ;Save new note period
  move.w  d2,6(a6)           ;AUDxPER Set new note period
nt_PortaDownEnd
  rts

; ** Effect command 3xx "Tone Portamento" **
  CNOP 0,4
nt_TonePortamento
  move.b  n_cmdlo(a2),d0     ;Get command data: xx-up/down speed
  beq.s	  nt_TonePortaNoChange ;If NULL -> skip
  move.b  d0,n_toneportspeed(a2) ;Save up/down speed
  move.b  d5,n_cmdlo(a2)     ;Clear command data
nt_TonePortaNoChange
  move.w  n_wantedperiod(a2),d2 ;Get wanted note period
  beq.s	  nt_TonePortaEnd    ;If NULL -> skip
  move.w  n_period(a2),d3    ;Get note period
  move.b  n_toneportspeed(a2),d0 ;Get up/down speed
  tst.b	  n_toneportdirec(a2) ;Check tone portamento direction
  bne.s	  nt_TonePortaUp     ;If not NULL -> up speed
nt_TonePortaDown
  add.w   d0,d3              ;Note period + down speed
  cmp.w   d3,d2              ;Wanted note period > note period ?
  bgt.s	  nt_TonePortaSetPer ;Yes -> skip
  move.w  d2,d3              ;Note period = wanted note period
  moveq   #TRUE,d2           ;Clear wanted note period
  bra.s	  nt_TonePortaSetPer
  CNOP 0,4
nt_TonePortaUp
  sub.w   d0,d3              ;Note period - up speed
  cmp.w	  d3,d2              ;Wanted note period < note period ?
  blt.s	  nt_TonePortaSetPer ;Yes -> skip
  move.w  d2,d3              ;Note period = wanted note period
  moveq   #TRUE,d2           ;Clear wanted note period
nt_TonePortaSetPer
  move.w  d2,n_wantedperiod(a2) ;Save new state
  move.w  d3,n_period(a2)    ;Save new note period
  move.w  d3,6(a6)           ;AUDxPER Set new period
nt_TonePortaEnd
  rts

; ** Effect command 5xy "Tone Portamento + Volume Slide" **
  CNOP 0,4
nt_TonePortaPlusVolSlide
  bsr.s	  nt_TonePortaNoChange
  bra.s   nt_VolumeSlide

; ** Effect command 4xy "Vibrato" **
  CNOP 0,4
nt_Vibrato
  move.b  n_cmdlo(a2),d0     ;Get command data: x-speed y-depth
  beq.s	  nt_Vibrato2        ;If NULL -> skip
  move.b  d0,n_vibratocmd(a2) ;Save new vibrato command data without NULL-check of new x-speed/y-depth -> all previous settings get lost (PT-replay does this check !)
nt_Vibrato2
  move.b  n_vibratopos(a2),d0 ;Get vibrato position
  lsr.b	  #2,d0              ;/4
  moveq   #TRUE,d2           ;NULL for word accsess
  and.w	  #$001f,d0          ;Mask out vibrato position overflow
  lea	  nt_VibSineTable(pc),a1 ;Pointer to vibrato modulation table
nt_VibSine
  move.b  (a1,d0.w),d2       ;Get sine amplitude
nt_VibSet
  moveq   #NIBBLEMASKLO,d0
  and.b   n_vibratocmd(a2),d0 ;Get depth
  mulu.w  d0,d2              ;depth * amplitude
  move.w  n_period(a2),d0    ;Get note period
  lsr.w	  #7,d2              ;Period amplitude = (depth * amplitude) / 128
  tst.b	  n_vibratopos(a2)   ;Vibrato position negative ?
  bmi.s	  nt_VibratoNeg      ;Yes -> skip
  add.w	  d2,d0              ;Note period + period amplitude
  bra.s	  nt_Vibrato3
  CNOP 0,4
nt_VibratoNeg
  sub.w	  d2,d0              ;Note period - period amplitude
nt_Vibrato3
  move.b  n_vibratocmd(a2),d2 ;Get vibrato command data
  lsr.b	  #2,d2              ;/4
  move.w  d0,6(a6)           ;AUDxPER Set new note period
  and.b	  #$3c,d2            ;Mask out vibrato position overflow
  add.b	  d2,n_vibratopos(a2) ;Next vibrato position
  rts

; ** Effect command 6xy "Vibrato + Volume Slide" **
  CNOP 0,4
nt_VibratoPlusVolSlide
  bsr.s	  nt_Vibrato2

; ** Effect command Axy "Volume Slide"
nt_VolumeSlide
  move.w  n_volume(a2),d2    ;Get volume
  move.b  n_cmdlo(a2),d0
  lsr.b	  #NIBBLESHIFTBITS,d0 ;Get command data: x-upspeed
  beq.s	  nt_VolSlideDown    ;If NULL -> skip
; ** Effect command Ax0 "Volume Slide Up"
nt_VolSlideUp
  add.b	  d0,d2              ;Volume + upspeed
  cmp.b	  #nt_maxvolume,d2   ;Volume < maximum volume ?
  bls.s	  nt_VsuSkip         ;Yes -> skip
  moveq   #nt_maxvolume,d2   ;Set maximum volume
nt_VsuSkip
  move.w  d2,n_volume(a2)    ;Save new volume
  move.w  d2,8(a6)           ;AUDxVOL Set new volume
nt_VSUEnd
  rts
; ** Effect command A0y "Volume Slide Down"
  CNOP 0,4
nt_VolSlideDown
  sub.b	  n_cmdlo(a2),d2     ;Volume - downspeed
  bpl.s	  nt_VsdSkip         ;If >= NULL -> skip
  moveq   #nt_minvolume,d2   ;Set minimum volume
nt_VsdSkip
  move.w  d2,n_volume(a2)    ;Save new volume
  move.w  d2,8(a6)           ;AUDxVOL Set new volume
nt_VsdEnd
  rts

; ** Get new note and pattern position at tick #1 **
  CNOP 0,4
nt_GetNewNote
  move.l  nt_SongDataPtr(a3),a0 ;Pointer to module
  move.w  nt_SongPosition(a3),d0 ;Get song position
  moveq	  #TRUE,d1           ;NULL needed for word access
  move.b  (nt_sd_pattpos,a0,d0.w),d1 ;Get pattern number in song position table
  lsl.w   #BYTESHIFTBITS,d1  ;*(pt_pattsize/4) = Pattern offset
  add.w	  nt_PatternPosition(a3),d1 ;Add pattern position
  move.w  d5,nt_DMACONtemp(a3) ;Clear DMA bits
  lea	  nt_audchan1temp(pc),a2 ;Pointer to audio channel temporary structure
  bsr.s   nt_PlayVoice
  addq.w  #8,a6              ;Next audio channel CUSTOM address
  lea	  nt_audchan2temp(pc),a2
  addq.w  #8,a6
  bsr.s   nt_PlayVoice
  addq.w  #8,a6
  lea	  nt_audchan3temp(pc),a2
  addq.w  #8,a6
  bsr.s   nt_PlayVoice
  addq.w  #8,a6
  lea	  nt_audchan4temp(pc),a2
  addq.w  #8,a6
  bsr.s   nt_PlayVoice
  bra     nt_SetDMA

; ** Get new note data **
  CNOP 0,4
nt_PlayVoice
  moveq   #TRUE,d2           ;NULL needed for word access
  move.l  (nt_sd_patterndata,a0,d1.l*4),(a2) ;Get new note data from pattern
  moveq   #-(-NIBBLEMASKHI&BYTEMASK),d0 ;Mask for upper nibble of sample number
  move.b  n_cmd(a2),d2       
  lsr.b	  #NIBBLESHIFTBITS,d2 ;Get lower nibble of sample number
  and.b   (a2),d0            ;Get upper nibble of sample number
  addq.w  #nt_noteinfo_SIZE/4,d1 ;Next channel data
  or.b	  d0,d2              ;Get whole sample number
  beq.s	  nt_SetRegisters    ;If NULL -> skip
  subq.w  #1,d2              ;x = sample number -1
  lea	  nt_SampleStarts(pc),a1 ;Pointer to sample pointers table
  move.w  d2,d3              ;Save x
  move.l  (a1,d2.w*4),a1     ;Get sample data pointer
  lsl.w   #NIBBLESHIFTBITS,d2 ;x*16
  move.l  a1,n_start(a2)     ;Save sample start
  sub.w   d3,d2              ;(x*16)-x = sample info structure length in words
  movem.w nt_sd_sampleinfo+nt_si_samplelength(a0,d2.w*2),d0/d2-d4 ;length, volume, repeat point, repeat length
  move.w  d2,n_volume(a2)    ;Save sample volume
  move.w  d2,8(a6)	     ;AUDxVOL Set new volume
  cmp.w   #1,d4              ;Repeat length = 1 word ?
  beq.s	  nt_NoLoopSample    ;Yes -> skip
nt_LoopSample
  move.w  d3,d0              ;Save repeat point
  add.w   d3,d3              ;*2 = repeat point in bytes
  add.w	  d4,d0              ;Add repeat length
  add.l	  d3,a1	             ;Add repeat point
nt_NoLoopSample
  move.w  d0,n_length(a2)    ;Save length
  move.w  d4,n_replen(a2)    ;Save repeat length
  move.l  a1,n_loopstart(a2) ;Save loop start

nt_SetRegisters
  move.w  (a2),d3            ;Get note period
  and.w	  d6,d3              ;without higher nibble of sample number
  beq.s   nt_CheckMoreEffects ;If no note period -> skip
  tst.w   n_length(a2)       ;Length = NULL ?
  beq.s   nt_StopSound       ;Yes -> skip
  tst.b   n_volume(a2)       ;Upper byte of sample volume = NULL ?
  bne.s   nt_StopSound       ;No -> skip
  moveq   #nt_cmdnummask,d0  ;Get channel effect command number
  and.b   n_cmd(a2),d0       ;without lower nibble of sample number
  subq.b  #3,d0              ;3 "Tone Portamento" ?
  beq.s	  nt_ChkTonePorta
  subq.b  #2,d0              ;5 "Tone Portamento + Volume Slide" ?
  beq.s	  nt_ChkTonePorta

nt_SetPeriod
  move.w  d3,n_period(a2)    ;Save new note period
  move.w  n_dmabit(a2),d0    ;Get audio channel DMA bit
  or.w	  d0,nt_DMACONtemp(a3) ;Set audio channel DMA bit
  move.b  d5,n_vibratopos(a2) ;Clear vibrato position
  move.w  d0,_CUSTOM+DMACON  ;Audio channel DMA off
  move.l  n_start(a2),(a6)   ;AUDxLCH Set sample start
  move.l  n_length(a2),4(a6) ;AUDxLEN & AUDxPER Set length & new note period
  bra.s   nt_CheckMoreEffects

  CNOP 0,4
nt_StopSound
  move.w  n_dmabit(a2),_CUSTOM+DMACON ;Audio channel DMA off
  bra.s   nt_CheckMoreEffects

; ** Effect command 3 "Tone Portamento" or 5 "Tone Portamento + Volume Slide" used **
  CNOP 0,4
nt_ChkTonePorta
  bsr.s	  nt_SetTonePorta
  bra.s	  nt_CheckMoreEffects

  CNOP 0,4
nt_SetTonePorta
  move.b  d5,n_toneportdirec(a2) ;Clear tone port direction
  move.w  d3,n_wantedperiod(a2) ;Save wanted note period
  cmp.w	  n_period(a2),d3    ;Check wanted note period
  beq.s	  nt_ClearTonePorta  ;If wanted note period = note period -> stop tone portamento
  bgt.s   nt_StpEnd          ;If wanted note period > note period -> skip
  moveq   #1,d0
  move.b  d0,n_toneportdirec(a2) ;If wanted note period < note period -> Set tone portamento direction = 1
nt_StpEnd
  rts
  CNOP 0,4
nt_ClearTonePorta
  move.w  d5,n_wantedperiod(a2) ;Clear wanted note period
  addq.w  #4,a7              ;Skip CheckMoreEffects
  rts

; ** Check audio channel for more effect commands at tick #1 **
  CNOP 0,4
nt_CheckMoreEffects
  moveq   #nt_cmdnummask,d0
  and.b   n_cmd(a2),d0       ;Get channel effect command number without lower nibble of sample number
  subq.b  #8,d0              ;0-8 ?
  ble.s   nt_ChkMoreEfxEnd   ;Yes -> skip
  subq.b  #3,d0              ;B "Position Jump" ?
  beq.s	  nt_PositionJump
  subq.b  #1,d0              ;C "Set Volume" ?
  beq.s	  nt_SetVolume
  subq.b  #1,d0              ;D "Pattern Break" ?
  beq.s	  nt_PatternBreak
  subq.b  #1,d0              ;E "Set Filter" ?
  beq.s	  nt_SetFilter
  subq.b  #1,d0              ;F "Set Speed" ?
  beq.s   nt_SetSpeed
nt_ChkMoreEfxEnd
  rts

; ** Effect command Bxx "Position Jump" **
  CNOP 0,4
nt_PositionJump
  move.b  n_cmdlo(a2),d0     ;Get command data: xx-songposition
  not.b   nt_PosJumpFlag(a3) ;Invert position jump flag
  subq.b  #1,d0              ;Decrement sonposition
  move.w  d0,nt_SongPosition(a3) ;Save new song position
  rts

; ** Effect command Cxx "Set Volume" **
  CNOP 0,4
nt_SetVolume
  move.b  n_cmdlo(a2),d0     ;Get command data: xx-volume
  cmp.b	  #nt_maxvolume,d0   ;volume <= maximum volume ?
  bls.s	  nt_MaxVolOk        ;Yes -> skip
  moveq	  #nt_maxvolume,d0   ;Set maximum volume
nt_MaxVolOk
  move.w  d0,n_volume(a2)    ;Save new volume
  move.w  d0,8(a6)           ;AUDxVOL Set new volume
  rts

; ** Effect command D00 "Pattern Break" **
  CNOP 0,4
nt_PatternBreak
  not.b   nt_PosJumpFlag(a3) ;Invert position jump flag
  rts

; ** Effect command E0x "Set Filter" **
  CNOP 0,4
nt_SetFilter
  moveq   #1,d0
  and.b   n_cmdlo(a2),d0     ;Get command data: 0-filter on 1-filter off
  bne.s   nt_FilterOff       ;If 1-filter off -> skip
nt_FilterOn
  moveq   #-(-~CIAF_LED&BYTEMASK),d0
  and.b   d0,(a4)            ;Turn filter on
  rts
  CNOP 0,4
nt_FilterOff
  moveq   #CIAF_LED,d0
  or.b    d0,(a4)            ;Turn filter off
  rts

; ** Effect command Fxx "Set Speed" **
  CNOP 0,4
nt_SetSpeed
  move.b  n_cmdlo(a2),d0     ;Get command data: xx-speed ($00-$1f ticks)
  bne.s   nt_ChkSpeedMax     ;If speed not NULL -> skip
  moveq   #nt_minticks,d0    ;Else set minimum ticks
  bra.s   nt_SetCurrSpeed
  CNOP 0,4
nt_ChkSpeedMax
  cmp.b   #nt_maxticks,d0    ;Speed <= maximum ticks
  bls.s   nt_SetCurrSpeed    ;Yes -> skip
  moveq   #nt_maxticks,d0    ;Else set maximum ticks
nt_SetCurrSpeed
  move.w  d0,nt_CurrSpeed(a3) ;Set new speed ticks
  rts

  CNOP 0,4
nt_SetDMA
  move.b  d5,nt_SetAllChanDMAFlag(a3) ;TRUE = Activate Set DMA-interrupt routine
  moveq   #CIACRBF_START,d0
  or.b    d0,CIACRB(a5)      ;CIA-B timer B Start timer for DMA wait

nt_Dskip
  addq.w  #nt_pattposdata_SIZE/4,nt_PatternPosition(a3) ;Next pattern position
  cmp.w	  #nt_pattsize/4,nt_PatternPosition(a3) ;End of pattern reached ?
  blo.s	  nt_NoNewPositionYet ;No -> skip
nt_NextPosition
  move.b  d5,nt_PosJumpFlag(a3) ;Clear position jump flag
  move.w  nt_SongPosition(a3),d1 ;Get song position
  addq.w  #1,d1              ;Next song position
  move.w  d5,nt_PatternPosition(a3) ;Set back pattern position = NULL
  and.w	  #nt_maxsongpos-1,d1 ;If maximum song position reached -> restart at song position NULL
  move.w  d1,nt_SongPosition(a3) ;Save new song position
  cmp.b	  nt_SongLength(a3),d1 ;Last song position reached ?
  blo.s	  nt_NoNewPositionYet ;No -> skip
  move.b  nt_SongRestartPosition(a3),d1 ;Get restart position in pattern table
  move.w  d1,nt_SongPosition(a3) ;Set song restart position
nt_NoNewPositionYet
  tst.b	  nt_PosJumpFlag(a3) ;Position jump flag set ?
  bne.s	  nt_NextPosition    ;Yes -> skip
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
nt_DMAWait
  movem.l d0-d7/a0-a6,-(a7)
  lea     nt_Variables(pc),a3 ;Base of variables
  move.l  #_CIAB,a5          ;Base of CIA-B
  move.l  #_CUSTOM,a6        ;Base of custom chips
  bsr.s   nt_CheckDMAWait
  movem.l (a7)+,d0-d7/a0-a6
  rts

; ** Check DMA wait routine to be executed **
  CNOP 0,4
nt_CheckDMAWait
  tst.b   nt_SetAllChanDMAFlag(a3) ;Set flag = TRUE ?
  beq.s   nt_SetAllChanDMA   ;Yes -> skip

; ** Init all audio channels data **
nt_InitAllChanLoopData
  move.l  nt_audchan1temp+n_loopstart(pc),AUD0LCH(a6) ;Set loop start for channel 1
  moveq   #FALSE,d0
  move.b  d0,nt_InitAllChanLoopDataFlag(a3) ;Deactivate this routine
  move.w  nt_audchan1temp+n_replen(pc),AUD0LEN(a6) ;Set repeat length for channel 1
  move.l  nt_audchan2temp+n_loopstart(pc),AUD1LCH(a6) ;Set loop start for channel 2
  move.w  nt_audchan2temp+n_replen(pc),AUD1LEN(a6) ;Set repeat length for channel 2
  move.l  nt_audchan3temp+n_loopstart(pc),AUD2LCH(a6) ;Set loop start for channel 3
  move.w  nt_audchan3temp+n_replen(pc),AUD2LEN(a6) ;Set repeat length for channel 3
  move.l  nt_audchan4temp+n_loopstart(pc),AUD3LCH(a6) ;Set loop start for channel 4
  move.w  nt_audchan4temp+n_replen(pc),AUD3LEN(a6) ;Set repeat length for channel 4
  rts

; ** Set all audio channels DMA **
  CNOP 0,4
nt_SetAllChanDMA
  move.w  nt_DMACONtemp(a3),d0 ;Get channel DMA bits
  or.w	  #DMAF_SETCLR,d0    ;DMA on
  move.w  d0,DMACON(a6)      ;Set channel DMA bits
  moveq   #FALSE,d0          ;Deactivate this routine
  addq.b  #CIACRBF_START,CIACRB(a5) ;CIA-B timer B Start timer for DMA wait
  clr.b   d0                 ;Activate init routine
  move.w  d0,nt_SetAllChanDMAFlag(a3) ;Save new routine states
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
nt_StopMusic
  lea     nt_Variables(pc),a3 ;Base of variables
  move.l  #_CIAB,a5          ;Base of CIA-B
  lea     _CIAA-_CIAB(a5),a4 ;Base of CIA-A
  move.l  #_CUSTOM,a6        ;Base of custom chips
  bsr.s   nt_StopTimer
  bra.s   nt_SetBackRegisters

; ** Stop all timers **
  CNOP 0,4
nt_StopTimer
  move.b  CIACRB(a5),d0
  and.b   #~(CIACRBF_START),d0 ;Stop CIA-B oneshot timer B
  move.b  d0,CIACRB(a5)
  rts

; ** Stop all audio and restore soundfilter **
  CNOP 0,4
nt_SetBackRegisters
  moveq   #TRUE,d0
  move.w  d0,AUD0VOL(a6)     ;Clear volume for all channels
  move.w  d0,AUD1VOL(a6)
  move.w  d0,AUD2VOL(a6)
  move.w  d0,AUD3VOL(a6)
  move.w  #nt_DMABITS,DMACON(a6) ;Turn audio DMA off
  moveq   #-(-(~CIAF_LED)&BYTEMASK),d0
  and.b   d0,CIAPRA(a4)      ;Turn soundfilter off
  rts



; ************************* Tables & variables ***********************

; ** Tables for effect commands **
; --------------------------------

; ** "Vibrato" **
nt_VibSineTable
  DC.B 0,24,49,74,97,120,141,161
  DC.B 180,197,212,224,235,244,250,253
  DC.B 255,253,250,244,235,224,212,197
  DC.B 180,161,141,120,97,74,49,24

; ** "Arpeggio/Tone Portamento" **
  CNOP 0,2
nt_PeriodTable
; Note C   C#  D   D#  E   F   F#  G   G#  A   A#  B
  DC.W 856,808,762,720,678,640,604,570,538,508,480,453 ;Octave 1
  DC.W 428,404,381,360,339,320,302,285,269,254,240,226 ;Octave 2
  DC.W 214,202,190,180,170,160,151,143,135,127,120,113 ;Octave 3
  DC.W 000                                             ;Noop
nt_PeriodTableEnd

; ** Temporary channel structures **
; ----------------------------------
  CNOP 0,4
nt_audchan1temp
  DS.B n_audchantemp_SIZE

  CNOP 0,4
nt_audchan2temp
  DS.B n_audchantemp_SIZE

  CNOP 0,4
nt_audchan3temp
  DS.B n_audchantemp_SIZE

  CNOP 0,4
nt_audchan4temp
  DS.B n_audchantemp_SIZE

; ** Pointers to samples **
; -------------------------
  CNOP 0,4
nt_SampleStarts
  DS.L nt_samplesnum

; ** Variables **
; ---------------
nt_variables DS.B nt_variables_SIZE

; ** Names **
; -----------
gfxname DC.B "gfx.library",TRUE



; ************************* Module Data ***********************

; ** Module to be loaded as binary into CHIP memory **
; ----------------------------------------------------
nt_auddata SECTION audio,DATA_C

  INCBIN "MOD.example"

  END
