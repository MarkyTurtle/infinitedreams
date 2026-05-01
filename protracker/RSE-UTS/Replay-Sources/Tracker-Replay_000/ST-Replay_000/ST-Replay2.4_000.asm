; Program: ST-Replay2.4_000.asm
; Author:  Dissident^Resistance
; Date:    2021-05-01
; Version: 4.1
; CPU:     68000+
; FASTMEM:  -
; Chipset: OCS/ECS/AGA
; OS:      1.2+

; ** Supported trackers **
; - Soundtracker 2.3
; - Soundtracker 2.4

; ** Main characteristics **
; - 31 instruments
; - Sample repeat point in bytes
; - Sample length = repeat length
; - Raster dependent replay

; ** Code **
; - Improved and optimized for 68000+ CPUs

; ** Play Music trigger **
; - Label st_PlayMusic: Called from vblank interrupt

; ** DMA Wait trigger **
; - Label st_DMAWait: Called from CIA-B timer B interrupt triggered
;                     after 482.68 탎 on PAL machines or 478.27 탎
;                     on NTSC machines

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
st_DMABITS               EQU DMAF_AUD0+DMAF_AUD1+DMAF_AUD2+DMAF_AUD3 ;Audio DMA for all channels off
st_CIABCRBBITS           EQU CIACRBF_LOAD+CIACRBF_RUNMODE ;CIA-B timer B oneshot mode

; ** Timer values **
st_dmawaittime           EQU 342 ;= 0.709379 MHz * [482.68 탎 = Lowest note period C1 * 2 / PAL clock constant = 856*2/3546895 ticks per second]
                                 ;= 0.715909 MHz * [478.27 탎 = Lowest note period C1 * 2 / NTSC clock constant = 856*2/3579545 ticks per second]

; ** Song equals **
st_maxsongpos            EQU 128
st_maxpattpos            EQU 64
st_pattsize              EQU 1024
st_samplesnum            EQU 31

; ** Speed equals **
st_defaultticks          EQU 6
st_minticks              EQU 1
st_maxticks              EQU 15

; ** Effect command masks equals **
st_cmdpermask            EQU $0fff
st_cmdnummask            EQU $0f

; ** Effect commands equals **
st_periodsnum            EQU 36
st_portminperiod         EQU 113 ;Note period "B-3"
st_portmaxperiod         EQU 856 ;Note period "C-1"
st_minvolume             EQU 0
st_maxvolume             EQU 64


                                  
; ************************* Variables offsets ***********************

; ** Relative offsets for variables **
; ------------------------------------
  RSRESET
st_SongDataPtr	   RS.L 1
st_Counter	   RS.W 1
st_CurrSpeed	   RS.W 1
st_DMACONtemp	   RS.W 1
st_PatternPosition RS.W 1
st_SongPosition	   RS.W 1
st_PosJumpFlag	   RS.B 1
st_SongLength      RS.B 1
st_variables_SIZE  RS.B 0



; ************************* Structures ***********************

; ** ST-Song-Structure **
; -----------------------

; ** ST SampleInfo structure **
  RSRESET
st_sampleinfo      RS.B 0
st_si_samplename   RS.B 22   ;Sample's name padded with null bytes
st_si_samplelength RS.W 1    ;Sample length in bytes or words
st_si_volume       RS.W 1    ;Bit 7 not used, bits 6-0 sample volume 0..64
st_si_repeatpoint  RS.W 1    ;Start of sample repeat offset in bytes
st_si_repeatlength RS.W 1    ;Length of sample repeat in words
st_sampleinfo_SIZE RS.B 0

; ** ST SongData structure **
  RSRESET
st_songdata        RS.B 0
st_sd_songname     RS.B 20   ;Song's name padded with null bytes
st_sd_sampleinfo   RS.B st_sampleinfo_SIZE*st_samplesnum ;Pointer to 1st sampleinfo, structure repeated for each sample 1-31
st_sd_numofpatt    RS.B 1    ;Number of song positions 1..128
st_sd_songspeed    RS.B 1    ;Default songspeed 120 BPM is ignored
st_sd_pattpos      RS.B 128  ;Pattern positions table 0..127
st_sd_id           RS.B 4    ;"M.K." (4 channels, 31 samples, 64 patterns) 
st_sd_patterndata  RS.B 0    ;Pointer to 1st pattern, structure repeated for each pattern 1..64 times
st_songdata_SIZE   RS.B 0


; ** ST NoteInfo structure **
  RSRESET
st_noteinfo      RS.B 0
st_ni_note       RS.W 1      ;Bits 15-12 upper nibble of sample number, bits 11-0 note period
st_ni_cmd        RS.B 1      ;Bits 7-4 lower nibble of sample number, bits 3-0 effect command number
st_ni_cmdlo      RS.B 1      ;Bits 7-0 effect command data / bits 7-4 effect e-command number, bits 3-0 effect e-command data
st_noteinfo_SIZE RS.B 0

; ** ST PatternPositionData structure **
  RSRESET
st_pattposdata       RS.B 0
st_ppd_chan1noteinfo RS.B st_noteinfo_SIZE ;Note info for each audio channel 1..4 is stored successive
st_ppd_chan2noteinfo RS.B st_noteinfo_SIZE
st_ppd_chan3noteinfo RS.B st_noteinfo_SIZE
st_ppd_chan4noteinfo RS.B st_noteinfo_SIZE
st_pattposdata_SIZE  RS.B 0

; ** ST PatternData structure **
  RSRESET
st_patterndata      RS.B 0
st_pd_data          RS.B st_pattposdata_SIZE*st_maxpattpos ;Repeated 64 times (standard PT) or upto 100 times (PT 2.3a)
st_patterndata_SIZE RS.B 0

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



  SECTION st_replay2.4,CODE

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
st_InitMusic
  lea     st_Variables(pc),a3 ;Base of variables
  move.l  #_CIAB,a5          ;Base of CIA-B
  lea     _CIAA-_CIAB(a5),a4 ;Base of CIA-A
  move.l  #_CUSTOM,a6        ;Base of custom chips
  bsr.s   st_InitTimer
  bsr.s   st_InitRegisters
  bsr.s   st_InitVariables
  bsr.s   st_InitAudTempStrucs
  bra.s   st_ExamineSongStruc

; ** Init wait dma timer **
  CNOP 0,4
st_InitTimer
  moveq   #st_dmawaittime&BYTEMASK,d0 ;DMA wait
  move.b  d0,CIATBLO(a5)     ;Set CIA-B timer B counter value low bits
  moveq   #st_dmawaittime>>BYTESHIFTBITS,d0
  move.b  d0,CIATBHI(a5)     ;Set CIA-B timer B counter value high bits
  moveq   #st_CIABCRBBITS,d0
  move.b  d0,CIACRB(a5)      ;Load oneshot timer B value
  rts

; ** Init main registers **
  CNOP 0,4
st_InitRegisters
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
st_InitVariables
  lea     st_auddata,a0
  move.l  a0,st_SongDataPtr(a3)
  moveq   #TRUE,d0
  move.w  d0,st_Counter(a3)
  moveq   #st_defaultticks,d2
  move.w  d2,st_CurrSpeed(a3) ;Set as default 6 ticks
  move.w  d0,st_DMACONtemp(a3)
  move.w  d0,st_PatternPosition(a3)
  move.w  d0,st_SongPosition(a3)
  move.b  d0,st_PosJumpFlag(a3)
  rts

; ** Init temporary channel structures **
  CNOP 0,4
st_InitAudTempStrucs
  moveq   #DMAF_AUD0,d0      ;DMA bit for channel1
  lea     st_audchan1temp+n_dmabit(pc),a0
  move.w  d0,(a0)            ;Set DMA channel1 bit
  moveq   #DMAF_AUD1,d0      ;DMA bit for channel2
  lea     st_audchan2temp+n_dmabit(pc),a0
  move.w  d0,(a0)            ;Set DMA channel2 bit
  moveq   #DMAF_AUD2,d0      ;DMA bit for channel3
  lea     st_audchan3temp+n_dmabit(pc),a0
  move.w  d0,(a0)            ;Set DMA channel3 bit
  moveq   #DMAF_AUD3,d0      ;DMA bit for channel4
  lea     st_audchan4temp+n_dmabit(pc),a0
  move.w  d0,(a0)            ;Set DMA channel4 bit
  rts

; ** Get highest pattern number and initialize sample pointers table **
  CNOP 0,4
st_ExamineSongStruc
  move.l  st_SongDataPtr(a3),a0 ;Pointer to song data
  moveq	  #TRUE,d0           ;First pattern number
  move.b  st_sd_numofpatt(a0),st_SongLength(a3) ;Get number of patterns
  moveq	  #TRUE,d1           ;Highest pattern number
  lea	  st_sd_pattpos(a0),a1 ;Pointer to table with pattern positions in song
  moveq   #st_maxsongpos-1,d7 ;Maximum number of song positions
st_InitLoop
  move.b  (a1)+,d0           ;Get pattern number out of song position table
  cmp.b	  d1,d0              ;Pattern number <= previous pattern number ?
  ble.s	  st_InitSkip        ;Yes -> skip
  move.l  d0,d1              ;Save higher pattern number
st_InitSkip
  dbf	  d7,st_InitLoop
  addq.w  #1,d1              ;Decrease highest pattern number
  lea     st_sd_sampleinfo+st_si_samplelength(a0),a0 ;First sample length
  swap    d1                 ;*st_pattsize
  lsr.l   #6,d1              ;Offset points to end of last pattern
  moveq   #TRUE,d2           ;NULL to clear first word in sample data
  lea	  st_sd_patterndata-st_sd_id(a1,d1.l),a2 ;Skip MOD-ID and patterndata -> Pointer to first sample data in module
  lea	  st_SampleStarts(pc),a1 ;Table for sample pointers
  moveq	  #st_sampleinfo_SIZE,d1 ;Length of sample info structure in bytes
  moveq	  #st_samplesnum-1,d7 ;Number of samples in module
st_InitLoop2
  move.l  a2,(a1)+           ;Save pointer to sample data
  move.w  (a0),d0            ;Get sample length
  beq.s   st_NoSample        ;If length = NULL -> skip
  add.w   d0,d0              ;*2 = Sample length in bytes
  move.w  d2,(a2)            ;Clear first word in sample data
  add.l	  d0,a2              ;Add sample length to get pointer to next sample data
st_NoSample
  add.l	  d1,a0              ;Next sample info structure in module
  dbf	  d7,st_InitLoop2
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
st_PlayMusic
  movem.l d0-d7/a0-a6,-(a7)
  lea     st_Variables(pc),a3 ;Base of variables
  move.l  #_CIAB,a5          ;Base of CIA-B
  lea     _CIAA-_CIAB(a5),a4 ;Base of CIA-A
  move.l  #_CUSTOM,a6        ;Base of custom chips
  moveq   #TRUE,d5           ;Constant: NULL longword for all delete operations
  addq.w  #1,st_Counter(a3)  ;Increment ticks
  move.w  #st_cmdpermask,d6  ;Constant: Mask out sample number
  move.w  st_Counter(a3),d0  ;Get ticks
  lea     AUD0LCH(a6),a6     ;Pointer to first audio channel address in CUSTOM CHIP space
  cmp.w	  st_CurrSpeed(a3),d0 ;Ticks < speed ticks ?
  bne.s	  st_NoNewNote       ;Yes -> skip
  move.w  d5,st_Counter(a3)  ;If ticks >= speed ticks -> set back ticks counter = tick #1
  bra     st_GetNewNote

; ** Check all audio channel for effect commands at ticks #2..#speed ticks **
  CNOP 0,4
st_NoNewNote
  lea	  st_audchan1temp(pc),a2 ;Pointer to first channel temporary structure (see above)
  bsr.s	  st_CheckEffects
  lea	  st_audchan2temp(pc),a2 ;Pointer to second channel temporary structure (see above)
  lea     16(a6),a6              ;Calculate CUSTOM CHIP pointer to next audio channel
  bsr.s	  st_CheckEffects
  lea	  st_audchan3temp(pc),a2 ;Pointer to third channel temporary structure (see above)
  lea     16(a6),a6              ;Calculate CUSTOM CHIP pointer to next audio channel
  bsr.s	  st_CheckEffects
  lea	  st_audchan4temp(pc),a2 ;Pointer to fourth channel temporary structure (see above)
  lea     16(a6),a6              ;Calculate CUSTOM CHIP pointer to next audio channel
  bsr.s   st_CheckEffects
  bra     st_NoNewPositionYet

; ** Check audio channel for effect commands **
  CNOP 0,4
st_CheckEffects
  move.w  n_cmd(a2),d0       ;Get channel effect command
  and.w	  d6,d0              ;without lower nibble of sample number
  beq.s	  st_ChkEfxEnd       ;If no command -> skip
  moveq   #st_cmdnummask,d0  ;Get channel effect command without lower nibble of sample number
  and.b   n_cmd(a2),d0       ;0 "Arpeggio" ?
  beq.s	  st_Arpeggio
  subq.b  #1,d0              ;1 "Portamento Up" ?
  beq.s	  st_PortamentoUp
  subq.b  #1,d0              ;2 "Portamento Down" ?
  beq.s   st_PortamentoDown
  subq.b  #8,d0              ;A "Volume Slide" ?
  beq     st_VolumeSlide
st_ChkEfxEnd
  rts

; ** Effect command 0xy "Normal play" or "Arpeggio" **
  CNOP 0,4
st_Arpeggio
  move.w  st_Counter(a3),d0  ;Get ticks
  subq.b  #1,d0              ;$01 = Add first halftone at tick #2 ?
  beq.s   st_Arpeggio1
  subq.b  #1,d0              ;$02 = Add second halftone at tick #3 ?
  beq.s   st_Arpeggio2
  subq.b  #1,d0              ;$03 = Play note period at tick #4
  beq.s   st_Arpeggio0
  subq.b  #1,d0              ;$04 = Add first halftone at tick #5 ?
  beq.s   st_Arpeggio1
  subq.b  #1,d0              ;$05 = Add second halftone at tick #6 ?
  beq.s   st_Arpeggio2
  rts
; ** Effect command 000 "Normal Play" 1st note **
  CNOP 0,4
st_Arpeggio0
  move.w  n_period(a2),d2    ;Play note period at tick #1
st_ArpeggioSet
  move.w  d2,6(a6)           ;AUDxPER Set new note period
  rts
; ** Effect command 0x0 "Arpeggio" 2nd note **
  CNOP 0,4
st_Arpeggio1
  move.b  n_cmdlo(a2),d0     
  lsr.b	  #NIBBLESHIFTBITS,d0 ;Get command data: x-first halftone
  bra.s	  st_ArpeggioFind
; ** Effect command 00y "Arpeggio" 3rd note **
  CNOP 0,4
st_Arpeggio2
  moveq   #NIBBLEMASKLO,d0
  and.b   n_cmdlo(a2),d0     ;Get command data: y-second halftone
st_ArpeggioFind
  lea	  st_PeriodTable(pc),a1 ;Pointer to period table
  add.w   d0,d0              ;Halftone *2
  move.w  n_period(a2),d2    ;Get note period
  moveq   #((st_PeriodTableEnd-st_PeriodTable)/2)-1,d7  ;Number of periods
st_ArpLoop
  cmp.w	  (a1)+,d2           ;period >= table note period ?
  dbeq	  d7,st_ArpLoop      ;If not -> loop until note period found or loop counter = FALSE
st_ArpFound
  move.w  -2(a1,d0.w),d2     ;Get note period + first or second halftone addition
  bra.s	  st_ArpeggioSet

; ** Effect command 1xx "Portamento Up" **
  CNOP 0,4
st_PortamentoUp
  move.w  n_portperiod(a2),d2 ;Get note period
  move.b  n_cmdlo(a2),d0     ;Get command data: xx-upspeed
  sub.w	  d0,d2              ;Note period - upspeed
  cmp.w	  #st_portminperiod,d2 ;Note period >= highest note period "B-3" ?
  bpl.s	  st_PortaUpSkip     ;Yes -> skip
  moveq   #st_portminperiod,d2 ;Set highest note period "B-3"
st_PortaUpSkip
  move.w  d2,n_portperiod(a2) ;Save new note period
  move.w  d2,6(a6)           ;AUDxPER Set new note period
st_PortaUpEnd
  rts

; ** Effect command 2xx "Portamento Down" **
  CNOP 0,4
st_PortamentoDown
  move.w  n_portperiod(a2),d2 ;Get note period
  move.b  n_cmdlo(a2),d0     ;Get command data: xx-downspeed
  add.w	  d0,d2              ;Note period + downspeed
  cmp.w	  #st_portmaxperiod,d2 ;Note period < lowest note period "C-1" ?
  bmi.s	  st_PortaDownSkip   ;Yes -> skip
  move.w  #st_portmaxperiod,d2 ;Set lowest note period "C-1"
st_PortaDownSkip
  move.w  d2,n_portperiod(a2) ;Save new note period
  move.w  d2,6(a6)           ;AUDxPER Set new note period
st_PortaDownEnd
  rts

; ** Effect command Axy "Volume Slide"
  CNOP 0,4
st_VolumeSlide
  move.b  n_cmdlo(a2),d0     
  lsr.b	  #NIBBLESHIFTBITS,d0 ;Get command data: x-upspeed
  beq.s	  st_VolSlideDown    ;If NULL -> skip
; ** Effect command Ax0 "Volume Slide Up"
st_VolSlideUp
  move.w  n_volume(a2),d2    ;Get volume
  add.b	  d0,d2              ;Volume + upspeed
  cmp.b	  #st_maxvolume,d2   ;volume < maximum volume ?
  bls.s	  st_VsuSkip         ;Yes -> skip
  moveq   #st_maxvolume,d2   ;Set maximum volume
st_VsuSkip
  move.w  d2,n_volume(a2)    ;Save new volume
  move.w  d2,8(a6)           ;AUDxVOL Set new volume
st_VSUEnd
  rts
; ** Effect command A0y "Volume Slide Down"
  CNOP 0,4
st_VolSlideDown
  moveq   #NIBBLEMASKLO,d0
  and.b   n_cmdlo(a2),d0     ;Get command data: y-downspeed
  move.w  n_volume(a2),d2    ;Get volume
  sub.b	  d0,d2              ;Volume - downspeed
  bpl.s	  st_VsdSkip         ;If >= NULL -> skip
  moveq   #st_minvolume,d2   ;Set minimum volume
st_VsdSkip
  move.w  d2,n_volume(a2)    ;Save new volume
  move.w  d2,8(a6)           ;AUDxVOL Set new volume
st_VsdEnd
  rts

; ** Get new note and pattern position at tick #1 **
  CNOP 0,4
st_GetNewNote
  move.l  st_SongDataPtr(a3),a0 ;Pointer to module
  move.w  st_SongPosition(a3),d0 ;Get song position
  add.w   #st_sd_pattpos,d0  ;Offset pattern position table
  moveq	  #TRUE,d1           ;NULL needed for word access
  move.b  (a0,d0.w),d1       ;Get pattern number in song position table
  lsl.w   #BYTESHIFTBITS,d1  ;*(pt_pattsize/4) = Pattern offset
  add.w	  st_PatternPosition(a3),d1 ;Add pattern position
  move.w  d5,st_DMACONtemp(a3) ;Clear DMA bits
  lea	  st_audchan1temp(pc),a2 ;Pointer to audio channel temporary structure
  bsr.s   st_PlayVoice
  lea	  st_audchan2temp(pc),a2
  lea     16(a6),a6          ;Next audio channel CUSTOM address
  bsr.s   st_PlayVoice
  lea	  st_audchan3temp(pc),a2
  lea     16(a6),a6
  bsr.s   st_PlayVoice
  lea	  st_audchan4temp(pc),a2
  lea     16(a6),a6
  bsr.s   st_PlayVoice
  bra     st_SetDMA

; ** Get new note data **
  CNOP 0,4
st_PlayVoice
  moveq   #TRUE,d0           ;NULL for longword access
  not.b   d0                 ;255
  add.w   d1,d0              ;Add pattern position
  add.l   d0,d0              ;*4
  add.l   d0,d0
  moveq   #TRUE,d2           ;NULL needed for word access
  move.l  st_sd_patterndata-(255*4)(a0,d0.l),(a2) ;Get new note data from pattern
  moveq   #-(-NIBBLEMASKHI&BYTEMASK),d0 ;Mask for upper nibble of sample number
  move.b  n_cmd(a2),d2       
  lsr.b	  #NIBBLESHIFTBITS,d2 ;Get lower nibble of sample number
  and.b   (a2),d0            ;Get upper nibble of sample number
  addq.w  #st_noteinfo_SIZE/4,d1 ;Next channel data
  or.b	  d0,d2              ;Get whole sample number
  beq.s	  st_SetRegisters    ;If NULL -> skip
  subq.w  #1,d2              ;x = sample number -1
  lea	  st_SampleStarts(pc),a1 ;Pointer to sample pointers table
  add.w   d2,d2              ;x*2
  move.w  d2,d3              ;Save x*2
  add.w   d2,d2              ;x*2
  move.l  (a1,d2.w),a1       ;Get sample data pointer
  lsl.w   #3,d2              ;x*8
  sub.w   d3,d2              ;(x*32)-(x*2) = sample info structure length in bytes
  movem.w st_sd_sampleinfo+st_si_samplelength(a0,d2.w),d0/d2-d4 ;length, volume, repeat point, repeat length
  move.w  d2,n_volume(a2)    ;Save sample volume
  move.w  d2,8(a6)	     ;AUDxVOL Set new volume
  cmp.w   #1,d4              ;Repeat length = 1 word ?
  beq.s	  st_NoLoopSample    ;Yes -> skip
st_LoopSample
  move.w  d4,d0              ;Sample length = repeat length
  add.l	  d3,a1	             ;Add repeat point
st_NoLoopSample
  move.w  d0,n_length(a2)    ;Save sample length
  move.w  d4,n_replen(a2)    ;Save repeat length
  move.l  a1,n_start(a2)     ;Save sample start
  move.l  a1,n_loopstart(a2) ;Save loop start

st_SetRegisters
  move.w  (a2),d3            ;Get note period from pattern position
  and.w	  d6,d3              ;without higher nibble of sample number
  beq.s   st_CheckMoreEffects ;If no note period -> skip

st_SetPeriod
  move.w  d3,n_period(a2)    ;Save new note period
  move.w  d3,n_portperiod(a2) ;Save new note period for "Portamento Up/Down" effect command
  move.w  n_dmabit(a2),d0    ;Get audio channel DMA bit
  or.w	  d0,st_DMACONtemp(a3) ;Set audio channel DMA bit
  move.w  d0,_CUSTOM+DMACON  ;Audio channel DMA off
  move.l  n_start(a2),(a6)   ;AUDxLCH Set sample start
  move.l  n_length(a2),4(a6) ;AUDxLEN & AUDxPER Set length & new note period

; ** Check audio channel for more effect commands at tick #1 **
st_CheckMoreEffects
  moveq   #st_cmdnummask,d0
  and.b   n_cmd(a2),d0       ;Get channel effect command number without lower nibble of sample number
  subq.b  #8,d0              ;0..8 ?
  ble.s   st_ChkMoreEfxEnd   ;Yes -> skip
  subq.b  #3,d0              ;B "Position Jump" ?
  beq.s	  st_PositionJump
  subq.b  #1,d0              ;C "Set Volume" ?
  beq.s	  st_SetVolume
  subq.b  #1,d0              ;D "Pattern Break" ?
  beq.s	  st_PatternBreak
  subq.b  #1,d0              ;E "Set Filter" ?
  beq.s	  st_SetFilter
  subq.b  #1,d0              ;F "Set Speed" ?
  beq.s   st_SetSpeed
st_ChkMoreEfxEnd
  rts

; ** Effect command Bxx "Position Jump" **
  CNOP 0,4
st_PositionJump
  move.b  n_cmdlo(a2),d0     ;Get command data: xx-song position
  not.b   st_PosJumpFlag(a3) ;Invert position jump flag
  subq.b  #1,d0              ;Decrement song position
  move.w  d0,st_SongPosition(a3) ;Save new song position
  rts

; ** Effect command Cxx "Set Volume" **
  CNOP 0,4
st_SetVolume
  move.b  n_cmdlo(a2),d0     ;Get command data: xx-volume
  move.w  d0,8(a6)           ;AUDxVOL Set new volume
  rts

; ** Effect command D00 "Pattern Break" **
  CNOP 0,4
st_PatternBreak
  not.b   st_PosJumpFlag(a3) ;Invert position jump flag
  rts

; ** Effect command E0x "Set Filter" **
  CNOP 0,4
st_SetFilter
  moveq   #1,d0
  and.b   n_cmdlo(a2),d0     ;Get command data: 0-filter on 1-filter off
  bne.s   st_FilterOff       ;If 1-filter off -> skip
st_FilterOn
  moveq   #-(-~CIAF_LED&BYTEMASK),d0
  and.b   d0,(a4)            ;Turn filter on
  rts
  CNOP 0,4
st_FilterOff
  moveq   #CIAF_LED,d0
  or.b    d0,(a4)            ;Turn filter off
  rts

; ** Effect command Fxx "Set Speed" **
  CNOP 0,4
st_SetSpeed
  moveq   #st_maxticks,d0    ;Mask for maximum ticks
  and.b   n_cmdlo(a2),d0     ;Get command data: xx-speed ($00-$0f ticks)
  beq.s   st_SetSpdEnd       ;If speed = NULL -> skip
  move.w  d5,st_Counter(a3)  ;Set back ticks counter = tick #1
  move.w  d0,st_CurrSpeed(a3) ;Set new speed ticks
st_SetSpdEnd
  rts

  CNOP 0,4
st_SetDMA
  moveq   #CIACRBF_START,d0
  or.b    d0,CIACRB(a5)      ;CIA-B timer B Start timer for DMA wait

st_Dskip
  addq.w  #st_pattposdata_SIZE/4,st_PatternPosition(a3) ;Next pattern position
  cmp.w	  #st_pattsize/4,st_PatternPosition(a3) ;End of pattern reached ?
  bne.s	  st_NoNewPositionYet ;No -> skip
st_NextPosition
  move.b  d5,st_PosJumpFlag(a3) ;Clear position jump flag
  move.w  st_SongPosition(a3),d1 ;Get song position
  move.w  d5,st_PatternPosition(a3) ;Set back pattern position = NULL
  addq.w  #1,d1              ;Next song position
  move.w  d1,st_SongPosition(a3) ;Save new song position
  cmp.b	  st_SongLength(a3),d1 ;Last song position reached ?
  bne.s	  st_NoNewPositionYet ;No -> skip
  move.w  d5,st_SongPosition(a3) ;Set back song position = NULL
st_NoNewPositionYet
  tst.b	  st_PosJumpFlag(a3) ;Position jump flag set ?
  bne.s	  st_NextPosition    ;Yes -> skip
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
  lea     st_Variables(pc),a3 ;Base of variables
  move.l  #_CIAB,a5          ;Base of CIA-B
  move.l  #_CUSTOM,a6        ;Base of custom chips
  bsr.s   st_CheckDMAWait
  movem.l (a7)+,d0-d7/a0-a6
  rts

; ** Check DMA wait routine to be executed **
  CNOP 0,4
st_CheckDMAWait
  move.w  st_DMACONtemp(a3),d0 ;Get channel DMA bits
  or.w	  #DMAF_SETCLR,d0    ;DMA on
  move.w  d0,DMACON(a6)      ;Set channel DMA bits

  moveq   #1,d0              ;Length = 1 word
  cmp.w   st_audchan1temp+n_replen(pc),d0 ;Repeat length = 1 word ?
  bne.s   st_Audchan0Loop    ;No -> Loop sample
  move.l  st_audchan1temp+n_loopstart(pc),AUD0LCH(a6) ;Set loop start for channel 1
  move.w  d0,AUD0LEN(a6)     ;Set repeat length for channel 1
st_Audchan0Loop
  cmp.w   st_audchan2temp+n_replen(pc),d0 ;Repeat length = 1 word ?
  bne.s   st_Audchan1Loop    ;No -> Loop sample
  move.l  st_audchan2temp+n_loopstart(pc),AUD1LCH(a6) ;Set loop start for channel 2
  move.w  d0,AUD1LEN(a6)     ;Set repeat length for channel 2
st_Audchan1Loop
  cmp.w   st_audchan3temp+n_replen(pc),d0 ;Repeat length = 1 word ?
  bne.s   st_Audchan2Loop    ;No -> Loop sample
  move.l  st_audchan3temp+n_loopstart(pc),AUD2LCH(a6) ;Set loop start for channel 3
  move.w  d0,AUD2LEN(a6)     ;Set repeat length for channel 3
st_Audchan2Loop
  cmp.w   st_audchan4temp+n_replen(pc),d0 ;Repeat length = 1 word ?
  bne.s   st_Audchan3Loop    ;No -> Loop sample
  move.l  st_audchan4temp+n_loopstart(pc),AUD3LCH(a6) ;Set loop start for channel 4
  move.w  d0,AUD3LEN(a6)     ;Set repeat length for channel 4
st_Audchan3Loop
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
  lea     st_Variables(pc),a3 ;Base of variables
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
  move.w  #st_DMABITS,DMACON(a6) ;Turn audio DMA off
  moveq   #-(-(~CIAF_LED)&BYTEMASK),d0
  and.b   d0,CIAPRA(a4)      ;Turn soundfilter off
  rts



; ************************* Tables & variables ***********************

; ** Tables for effect commands **
; --------------------------------

; ** "Arpeggio/Tone Portamento" **
  CNOP 0,2
st_PeriodTable
; Note C   C#  D   D#  E   F   F#  G   G#  A   A#  B
  DC.W 856,808,762,720,678,640,604,570,538,508,480,453 ;Octave 1
  DC.W 428,404,381,360,339,320,302,285,269,254,240,226 ;Octave 2
  DC.W 214,202,190,180,170,160,151,143,135,127,120,113 ;Octave 3
  DC.W 000                                             ;Noop
st_PeriodTableEnd

; ** Temporary channel structures **
; ----------------------------------
  CNOP 0,4
st_audchan1temp
  DS.B n_audchantemp_SIZE

  CNOP 0,4
st_audchan2temp
  DS.B n_audchantemp_SIZE

  CNOP 0,4
st_audchan3temp
  DS.B n_audchantemp_SIZE

  CNOP 0,4
st_audchan4temp
  DS.B n_audchantemp_SIZE

; ** Pointers to samples **
; -------------------------
  CNOP 0,4
st_SampleStarts
  DS.L st_samplesnum

; ** Variables **
; ---------------
st_variables DS.B st_variables_SIZE

; ** Names **
; -----------
gfxname DC.B "gfx.library",TRUE



; ************************* Module Data ***********************

; ** Module to be loaded as binary into CHIP memory **
; ----------------------------------------------------
st_auddata SECTION audio,DATA_C

  INCBIN "MOD.example"

  END
