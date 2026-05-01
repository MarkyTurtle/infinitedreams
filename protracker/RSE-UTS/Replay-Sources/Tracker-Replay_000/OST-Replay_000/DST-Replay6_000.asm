; Program: DST-Replay6_000.asm
; Author:  Dissident^Resistance
; Date:    2021-05-01
; Version: 1.1
; CPU:     68000+
; FASTMEM:  -
; Chipset: OCS/ECS/AGA
; OS:      1.2+

; ** Supported trackers **
; - (old) Soundtracker     1
; - (old) Soundtracker     2
; - (old) Soundtracker     3
; - (old) DOC Soundtracker 4
; - (old) DOC Soundtracker 5
; - (old) DOC Soundtracker 6

; ** Main characteristics **
; - 15 instruments
; - Sample repeat point in bytes
; - Sample length = repeat length
; - Effect commands with the numbers 3..B and D..E are not compatible with
;   subsequent trackers¹
; - Raster dependent replay

; ** Code **
; - Improved and optimized for 68000+ CPUs

; ** Play Music trigger **
; - Label dst_PlayMusic: Called from vblank interrupt

; ** DMA Wait trigger **
; - Label dst_DMAWait: Called from CIA-B timer B interrupt triggered
;                      after 482.68 µs on PAL machines or 478.27 µs
;                      on NTSC machines
; ** Loop samples **
; - Check for repeat length > 1 word, instead of repeat point not NULL
; - Loop samples with repeat point = NULL now properly detected

; ** Supported effect commands (cmd format 1) **
; 0 - Normal play or Arpeggio
; 1 - Portamento Up
; 2 - Portamento Down
; 3 - Modulate Volume of next higher voice + normal play or Arpeggio¹
; 4 - Modulate Period of next higher voice + normal play or Arpeggio¹
; 5 - Modulate Period + Volume of next higher voice + normal play or
;     Arpeggio¹
; 6 - Modulate Volume of next higher voice + Portamento Up¹
; 7 - Modulate Period of next higher voice + Portamento Up¹
; 8 - Modulate Period + Volume of next higher voice + Portamento Up¹
; 9 - Modulate Volume of next higher voice + Portamento Down¹
; A - Modulate Period of next higher voice + Portamento Down¹
; B - Modulate Period + Volume of next higher voice + Portamento Down¹
; C - Set Volume
; D - Volume Slide¹
; E - Set Auto Volume Slide¹
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
  INCLUDE "hardware/adkbits.i"
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
dst_DMABITS              EQU DMAF_AUD0+DMAF_AUD1+DMAF_AUD2+DMAF_AUD3 ;Audio DMA for all channels off
dst_CIABCRBBITS          EQU CIACRBF_LOAD+CIACRBF_RUNMODE ;CIA-B timer B oneshot mode

; ** Timer values **
dst_dmawaittime          EQU 342 ;= 0.709379 MHz * [482.68 µs = Lowest note period C1 * 2 / PAL clock constant = 856*2/3546895 ticks per second]
                                 ;= 0.715909 MHz * [478.27 µs = Lowest note period C1 * 2 / NTSC clock constant = 856*2/3579545 ticks per second]
; ** Song equals **
dst_maxsongpos           EQU 128
dst_maxpattpos           EQU 64
dst_pattsize             EQU 1024
dst_samplesnum           EQU 15

; ** Speed equals **
dst_defaultticks         EQU 6
dst_minticks             EQU 1
dst_maxticks             EQU 15

; ** Effect command masks equals **
dst_cmdpermask           EQU $0fff
dst_cmdnummask           EQU $0f

; ** Effect commands equals **
dst_periodsnum           EQU 36
dst_portminperiod        EQU 113 ;Note period "B-3"
dst_portmaxperiod        EQU 856 ;Note period "C-1"
dst_minvolume            EQU 0
dst_maxvolume            EQU 64


                                  
; ************************* Variables offsets ***********************

; ** Relative offsets for variables **
; ------------------------------------
  RSRESET
dst_SongDataPtr	    RS.L 1
dst_Counter	    RS.W 1
dst_CurrSpeed	    RS.W 1
dst_DMACONtemp	    RS.W 1
dst_PatternPosition RS.W 1
dst_SongPosition    RS.W 1
dst_SongLength      RS.B 1
dst_Variables_SIZE  RS.B 0


; ************************* Structures ***********************

; ** DST-Song-Structure **
; ------------------------

; ** DST SampleInfo structure **
  RSRESET
dst_sampleinfo      RS.B 0
dst_si_samplename   RS.B 22  ;Sample's name padded with null bytes
dst_si_samplelength RS.W 1   ;Sample length in words
dst_si_volume       RS.W 1   ;Bits 15-7 not used, bits 6-0 sample volume 0..64
dst_si_repeatpoint  RS.W 1   ;Start of sample repeat offset in bytes
dst_si_repeatlength RS.W 1   ;Length of sample repeat in words
dst_sampleinfo_SIZE RS.B 0

; ** DST SongData structure **
  RSRESET
dst_songdata       RS.B 0
dst_sd_songname    RS.B 20   ;Song's name padded with null bytes
dst_sd_sampleinfo  RS.B dst_sampleinfo_SIZE*dst_samplesnum ;Pointer to 1st sampleinfo, structure repeated for each sample 1-15
dst_sd_numofpatt   RS.B 1    ;Number of song positions 1..128
dst_sd_songspeed   RS.B 1    ;Default song speed 120 BPM is ignored
dst_sd_pattpos     RS.B 128  ;Pattern positions table 0..127
dst_sd_patterndata RS.B 0    ;Pointer to 1st pattern, structure repeated for each pattern 1..64 times
dst_songdata_SIZE  RS.B 0

; ** DST NoteInfo structure **
  RSRESET
dst_noteinfo      RS.B 0
dst_ni_note       RS.W 1     ;Bits 15-12 not used, bits 11-0 noteperiod
dst_ni_cmd        RS.B 1     ;Bits 7-4 sample number, bits 3-0 effect command number
dst_ni_cmdlo      RS.B 1     ;Bits 7-0 effect command data
dst_noteinfo_SIZE RS.B 0

; ** DST PatternPositionData structure **
  RSRESET
dst_pattposdata       RS.B 0
dst_ppd_chan1noteinfo RS.B dst_noteinfo_SIZE ;Note info for each audio channel 1..4 is stored successive
dst_ppd_chan2noteinfo RS.B dst_noteinfo_SIZE
dst_ppd_chan3noteinfo RS.B dst_noteinfo_SIZE
dst_ppd_chan4noteinfo RS.B dst_noteinfo_SIZE
dst_pattposdata_SIZE  RS.B 0

; ** DST PatternData structure **
  RSRESET
dst_patterndata      RS.B 0
dst_pd_data          RS.B dst_pattposdata_SIZE*dst_maxpattpos ;Repeated 64 times
dst_patterndata_SIZE RS.B 0

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
n_volslidecmd      RS.B 1
n_audchantemp_SIZE RS.B 0



  SECTION dst_replay6,CODE

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
dst_InitMusic
  lea     dst_Variables(pc),a3 ;Base of variables
  move.l  #_CIAB,a5          ;Base of CIA-B
  lea     _CIAA-_CIAB(a5),a4 ;Base of CIA-A
  move.l  #_CUSTOM,a6        ;Base of custom chips
  bsr.s   dst_InitTimer
  bsr.s   dst_InitRegisters
  bsr.s   dst_InitVariables
  bsr.s   dst_InitAudTempStrucs
  bra.s   dst_ExamineSongStruc

; ** Init wait dma timer **
  CNOP 0,4
dst_InitTimer
  moveq   #dst_dmawaittime&BYTEMASK,d0 ;DMA wait
  move.b  d0,CIATBLO(a5)     ;Set CIA-B timer B counter value low bits
  moveq   #dst_dmawaittime>>BYTESHIFTBITS,d0
  move.b  d0,CIATBHI(a5)     ;Set CIA-B timer B counter value high bits
  moveq   #dst_CIABCRBBITS,d0
  move.b  d0,CIACRB(a5)      ;Load oneshot timer B value
  rts

; ** Init main registers **
  CNOP 0,4
dst_InitRegisters
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
dst_InitVariables
  lea     dst_auddata,a0
  move.l  a0,dst_SongDataPtr(a3)
  moveq   #TRUE,d0
  move.w  d0,dst_Counter(a3)
  moveq   #dst_defaultticks,d2
  move.w  d2,dst_CurrSpeed(a3) ;Set as default 6 ticks
  move.w  d0,dst_DMACONtemp(a3)
  move.w  d0,dst_PatternPosition(a3)
  move.w  d0,dst_SongPosition(a3)
  rts

; ** Init temporary channel structures **
  CNOP 0,4
dst_InitAudTempStrucs
  moveq   #DMAF_AUD0,d0      ;DMA bit for channel1
  lea     dst_audchan1temp+n_dmabit(pc),a0
  move.w  d0,(a0)            ;Set DMA channel1 bit
  moveq   #DMAF_AUD1,d0      ;DMA bit for channel2
  lea     dst_audchan2temp+n_dmabit(pc),a0
  move.w  d0,(a0)            ;Set DMA channel2 bit
  moveq   #DMAF_AUD2,d0      ;DMA bit for channel3
  lea     dst_audchan3temp+n_dmabit(pc),a0
  move.w  d0,(a0)            ;Set DMA channel3 bit
  moveq   #DMAF_AUD3,d0      ;DMA bit for channel4
  lea     dst_audchan4temp+n_dmabit(pc),a0
  move.w  d0,(a0)            ;Set DMA channel4 bit
  rts

; ** Get highest pattern number and initialize sample pointers table **
  CNOP 0,4
dst_ExamineSongStruc
  move.l  dst_SongDataPtr(a3),a0 ;Pointer to song data
  moveq	  #TRUE,d0           ;First pattern number
  move.b  dst_sd_numofpatt(a0),dst_SongLength(a3) ;Get number of patterns
  moveq	  #TRUE,d1           ;Highest pattern number
  lea	  dst_sd_pattpos(a0),a1 ;Pointer to table with pattern positions in song
  moveq   #dst_maxsongpos-1,d7 ;Maximum number of song positions
dst_InitLoop
  move.b  (a1)+,d0           ;Get pattern number out of song position table
  cmp.b	  d1,d0              ;Pattern number <= previous pattern number ?
  ble.s	  dst_InitSkip       ;Yes -> skip
  move.l  d0,d1              ;Save higher pattern number
dst_InitSkip
  dbf	  d7,dst_InitLoop
  addq.w  #1,d1              ;Decrease highest pattern number
  lea     dst_sd_sampleinfo+dst_si_samplelength(a0),a0 ;First sample length
  swap    d1                 ;*dst_pattsize
  lsr.l   #6,d1              ;Offset points to end of last pattern
  moveq   #TRUE,d2           ;NULL to clear first word in sample data
  lea	  (a1,d1.l),a2       ;Skip patterndata -> Pointer to first sample data in module
  lea	  dst_SampleStarts(pc),a1 ;Table for sample pointers
  moveq	  #dst_sampleinfo_SIZE,d1 ;Length of sample info structure in bytes
  moveq	  #dst_samplesnum-1,d7 ;Number of samples in module
dst_InitLoop2
  move.l  a2,(a1)+           ;Save pointer to sample data
  move.w  (a0),d0            ;Get sample length
  beq.s   dst_NoSample       ;If length = NULL -> skip
  add.w   d0,d0              ;*2 = Sample length in bytes
  move.w  d2,(a2)            ;Clear first word in sample data
  add.l	  d0,a2              ;Add sample length to get pointer to next sample data
dst_NoSample
  add.l	  d1,a0              ;Next sample info structure in module
  dbf	  d7,dst_InitLoop2
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
dst_PlayMusic
  movem.l d0-d7/a0-a6,-(a7)
  lea     dst_Variables(pc),a3 ;Base of variables
  move.l  #_CIAB,a5          ;Base of CIA-B
  lea     _CIAA-_CIAB(a5),a4 ;Base of CIA-A
  move.l  #_CUSTOM,a6        ;Base of custom chips
  moveq   #TRUE,d5           ;Constant: NULL longword for all delete operations
  addq.w  #1,dst_Counter(a3)  ;Increment ticks
  move.w  #dst_cmdpermask,d6 ;Constant: Mask out sample number
  move.w  dst_Counter(a3),d0 ;Get ticks
  lea     AUD0LCH(a6),a6     ;Pointer to first audio channel address in CUSTOM CHIP space
  cmp.w	  dst_CurrSpeed(a3),d0 ;Ticks < speed ticks ?
  bne.s	  dst_NoNewNote      ;Yes -> skip
  move.w  d5,dst_Counter(a3) ;If ticks >= speed ticks -> set back ticks counter = tick #1
  bra     dst_GetNewNote

; ** Check all audio channel for effect commands at ticks #2..#speed ticks **
  CNOP 0,4
dst_NoNewNote
  lea	  dst_audchan1temp(pc),a2 ;Pointer to first channel temporary structure (see above)
  bsr.s	  dst_CheckEffects
  lea	  dst_audchan2temp(pc),a2 ;Pointer to second channel temporary structure (see above)
  lea     16(a6),a6          ;Calculate CUSTOM CHIP pointer to next audio channel
  bsr.s	  dst_CheckEffects
  lea	  dst_audchan3temp(pc),a2 ;Pointer to third channel temporary structure (see above)
  lea     16(a6),a6 
  bsr.s	  dst_CheckEffects
  lea	  dst_audchan4temp(pc),a2 ;Pointer to fourth channel temporary structure (see above)
  lea     16(a6),a6 
  bsr.s   dst_CheckEffects
  bra     dst_NoNewPositionYet

; ** Check audio channel for effect commands **
  CNOP 0,4
dst_CheckEffects
  move.b  n_volslidecmd(a2),d0 ;Get volume slide command data: xy
  beq.s   dst_NoAutoVolSlide ;If NULL -> skip
  lsr.b	  #NIBBLESHIFTBITS,d0 ;Get volume slide command data: x-upspeed
  beq.s	  dst_AutoVolSlideDown ;If NULL -> skip
dst_AutoVolSlideUp
  bsr     dst_VolSlideUp
  bra.s   dst_NoAutoVolSlide
  CNOP 0,4
dst_AutoVolSlideDown
  move.b  n_volslidecmd(a2),d0 ;Get volume slide command data: y-downspeed
  bsr     dst_VsdPush
dst_NoAutoVolSlide
  move.w  n_cmd(a2),d0       ;Get channel effect command
  and.w	  d6,d0              ;without nibble of sample number
  beq.s	  dst_ChkEfxEnd      ;If no command -> skip
  moveq   #dst_cmdnummask,d0 ;Get channel effect command without nibble of sample number
  and.b   n_cmd(a2),d0       ;0 "Arpeggio" ?
  beq.s	  dst_Arpeggio
  subq.b  #1,d0              ;1 "Portamento Up" ?
  beq     dst_PortamentoUp
  subq.b  #1,d0              ;2 "Portamento Down" ?
  beq     dst_PortamentoDown
  subq.b  #1,d0              ;3 "Modulate Volume of next higher voice + normal play or Arpeggio" ?
  beq.s   dst_Arpeggio
  subq.b  #1,d0              ;4 "Modulate Period of next higher voice + normal play or Arpeggio" ?
  beq.s   dst_Arpeggio
  subq.b  #1,d0              ;5 "Modulate Period + Volume of next higher voice + normal play or Arpeggio" ?
  beq.s   dst_Arpeggio
  subq.b  #1,d0              ;6 "Modulate Volume of next higher voice + Portamento Up" ?
  beq.s	  dst_PortamentoUp
  subq.b  #1,d0              ;7 "Modulate Period of next higher voice + Modulate Period of next higher voice + Portamento Up" ?
  beq.s	  dst_PortamentoUp
  subq.b  #1,d0              ;8 "Modulate Period + Volume of next higher voice + Portamento Up" ?
  beq.s	  dst_PortamentoUp
  subq.b  #1,d0              ;9 "Modulate Volume of next higher voice + Portamento Down" ?
  beq.s   dst_PortamentoDown
  subq.b  #1,d0              ;A "Modulate Period of next higher voice + Portamento Down" ?
  beq.s   dst_PortamentoDown
  subq.b  #1,d0              ;B "Modulate Period + Volume of next higher voice + Portamento Down" ?
  beq.s   dst_PortamentoDown
  subq.b  #2,d0              ;D "Volume Slide" ?
  beq     dst_VolumeSlide
dst_ChkEfxEnd
  rts

; ** Effect command 0xy "Normal play" or "Arpeggio" **
  CNOP 0,4
dst_Arpeggio
  move.w  dst_Counter(a3),d0 ;Get ticks
  subq.b  #1,d0              ;$01 = Add first halftone at tick #2 ?
  beq.s   dst_Arpeggio1
  subq.b  #1,d0              ;$02 = Add second halftone at tick #3 ?
  beq.s   dst_Arpeggio2
  subq.b  #1,d0              ;$03 = Play note period at tick #4
  beq.s   dst_Arpeggio0
  subq.b  #1,d0              ;$04 = Add first halftone at tick #5 ?
  beq.s   dst_Arpeggio1
  subq.b  #1,d0              ;$05 = Add second halftone at tick #6 ?
  beq.s   dst_Arpeggio2
  rts
; ** Effect command 000 "Normal Play" 1st note **
  CNOP 0,4
dst_Arpeggio0
  move.w  n_period(a2),d2    ;Play note period at tick #1
dst_ArpeggioSet
  move.w  d2,6(a6)           ;AUDxPER Set new note period
  rts
; ** Effect command 0x0 "Arpeggio" 2nd note **
  CNOP 0,4
dst_Arpeggio1
  move.b  n_cmdlo(a2),d0     
  lsr.b	  #NIBBLESHIFTBITS,d0 ;Get command data: x-first halftone
  bra.s	  dst_ArpeggioFind
; ** Effect command 00y "Arpeggio" 3rd note **
  CNOP 0,4
dst_Arpeggio2
  moveq   #NIBBLEMASKLO,d0
  and.b   n_cmdlo(a2),d0     ;Get command data: y-second halftone
dst_ArpeggioFind
  lea	  dst_PeriodTable(pc),a1 ;Pointer to period table
  add.w   d0,d0              ;Halftone *2
  move.w  n_period(a2),d2    ;Get note period
  moveq   #((dst_PeriodTableEnd-dst_PeriodTable)/2)-1,d7 ;Number of periods
dst_ArpLoop
  cmp.w	  (a1)+,d2           ;Note >= table note period ?
  dbeq	  d7,dst_ArpLoop     ;If not -> loop until note period found or loop counter = FALSE
dst_ArpFound
  move.w  -2(a1,d0.w),d2     ;Get note period + first or second halftone addition
  bra.s	  dst_ArpeggioSet

; ** Effect command 1xx "Portamento Up" **
  CNOP 0,4
dst_PortamentoUp
  move.w  n_portperiod(a2),d2 ;Get note period
  move.b  n_cmdlo(a2),d0     ;Get command data: xx-upspeed
  sub.w	  d0,d2              ;Note period - upspeed
  cmp.w	  #dst_portminperiod,d2 ;Note period >= highest note period "B-3" ?
  bpl.s	  dst_PortaUpSkip    ;Yes -> skip
  moveq   #dst_portminperiod,d2 ;Set highest note period "B-3"
dst_PortaUpSkip
  move.w  d2,n_portperiod(a2) ;Save new note period
  move.w  d2,6(a6)           ;AUDxPER Set new note period
dst_PortaUpEnd
  rts

; ** Effect command 2xx "Portamento Down" **
  CNOP 0,4
dst_PortamentoDown
  move.w  n_portperiod(a2),d2 ;Get note period
  move.b  n_cmdlo(a2),d0     ;Get command data: xx-downspeed
  add.w	  d0,d2              ;Note period + downspeed
  cmp.w	  #dst_portmaxperiod,d2 ;Note period < lowest note period "C-1" ?
  bmi.s	  dst_PortaDownSkip  ;Yes -> skip
  move.w  #dst_portmaxperiod,d2 ;Set lowest note period "C-1"
dst_PortaDownSkip
  move.w  d2,n_portperiod(a2) ;Save new note period
  move.w  d2,6(a6)           ;AUDxPER Set new note period
dst_PortaDownEnd
  rts

; ** Effect command Dxy "Volume Slide"
  CNOP 0,4
dst_VolumeSlide
  move.b  n_cmdlo(a2),d0     
  lsr.b	  #NIBBLESHIFTBITS,d0 ;Get command data: x-upspeed
  beq.s	  dst_VolSlideDown   ;If NULL -> skip
; ** Effect command Dx0 "Volume Slide Up"
dst_VolSlideUp
  move.w  n_volume(a2),d2    ;Get volume
  add.b	  d0,d2              ;Volume + upspeed
  cmp.b	  #dst_maxvolume,d2  ;Volume < maximum volume ?
  bls.s	  dst_VsuSkip        ;Yes -> skip
  moveq   #dst_maxvolume,d2  ;Set maximum volume
dst_VsuSkip
  move.w  d2,n_volume(a2)    ;Save new volume
  move.w  d2,8(a6)           ;AUDxVOL Set new volume
dst_VsuEnd
  rts
; ** Effect command D0y "Volume Slide Down"
  CNOP 0,4
dst_VolSlideDown
  move.b  n_cmdlo(a2),d0     ;Get command data: y-downspeed
dst_VsdPush
  move.w  n_volume(a2),d2    ;Get volume
  sub.b	  d0,d2              ;Volume - downspeed
  bpl.s	  dst_VsdSkip        ;If >= NULL -> skip
  moveq   #dst_minvolume,d2  ;Set minimum volume
dst_VsdSkip
  move.w  d2,n_volume(a2)    ;Save new volume
  move.w  d2,8(a6)           ;AUDxVOL Set new volume
dst_VsdEnd
  rts

; ** Get new note and pattern position at tick #1 **
  CNOP 0,4
dst_GetNewNote
  move.l  dst_SongDataPtr(a3),a0 ;Pointer to module
  move.w  dst_SongPosition(a3),d0 ;Get song position
  add.w   #dst_sd_pattpos,d0 ;Offset pattern position table
  moveq	  #TRUE,d1           ;NULL needed for word access
  move.b  (a0,d0.w),d1       ;Get pattern number in song position table
  lsl.w   #BYTESHIFTBITS,d1  ;*(pt_pattsize/4) = Pattern offset
  add.w	  dst_PatternPosition(a3),d1 ;Add pattern position
  move.w  d5,dst_DMACONtemp(a3) ;Clear DMA bits
  lea	  dst_audchan1temp(pc),a2 ;Pointer to audio channel temporary structure
  bsr.s   dst_PlayVoice
  lea	  dst_audchan2temp(pc),a2
  lea     16(a6),a6              ;Next audio channel CUSTOM address
  bsr.s   dst_PlayVoice
  lea	  dst_audchan3temp(pc),a2
  lea     16(a6),a6
  bsr.s   dst_PlayVoice
  lea	  dst_audchan4temp(pc),a2
  lea     16(a6),a6
  bsr.s   dst_PlayVoice
  bra     dst_SetDMA

; ** Get new note data **
  CNOP 0,4
dst_PlayVoice
  moveq   #127,d0            ;127
  add.w   d1,d0              ;Add pattern position
  add.l   d0,d0              ;*4
  add.l   d0,d0
  moveq   #TRUE,d2           ;NULL needed for word access
  move.l  dst_sd_patterndata-(127*4)(a0,d0.l),(a2) ;Get new note data from pattern
  addq.w  #dst_noteinfo_SIZE/4,d1 ;Next channel data
  move.b  n_cmd(a2),d2       
  lsr.b	  #NIBBLESHIFTBITS,d2 ;Get nibble of sample number
  beq.s	  dst_SetRegisters    ;If NULL -> skip
  subq.w  #1,d2              ;x = sample number -1
  lea	  dst_SampleStarts(pc),a1 ;Pointer to sample pointers table
  add.w   d2,d2              ;x*2
  move.w  d2,d3              ;Save x*2
  add.w   d2,d2              ;x*2
  move.l  (a1,d2.w),a1       ;Get sample data pointer
  lsl.w   #3,d2              ;x*8
  sub.w   d3,d2              ;(x*32)-(x*2) = sample info structure length in bytes
  movem.w dst_sd_sampleinfo+dst_si_samplelength(a0,d2.w),d0/d2-d4 ;length, volume, repeat point, repeat length
  move.w  d2,n_volume(a2)    ;Save sample volume
  move.w  d2,8(a6)	     ;AUDxVOL Set new volume
  cmp.w   #1,d4              ;Repeat length = 1 word ?
  beq.s	  dst_NoLoopSample   ;Yes -> skip
dst_LoopSample
  move.w  d4,d0              ;Sample length = repeat length
  add.l	  d3,a1	             ;Add repeat point
dst_NoLoopSample
  move.w  d0,n_length(a2)    ;Save sample length
  move.w  d4,n_replen(a2)    ;Save repeat length
  move.l  a1,n_start(a2)     ;Save sample start
  move.l  a1,n_loopstart(a2) ;Save loop start

dst_SetRegisters
  move.w  (a2),d3            ;Get note period from pattern position
  beq.s   dst_CheckMoreEffects ;If no note period -> skip

dst_SetPeriod
  move.w  d3,n_period(a2)    ;Save new note period
  move.w  d3,n_portperiod(a2) ;Save new note period for "Portamento Up/Down" effect command
  move.w  n_dmabit(a2),d0    ;Get audio channel DMA bit
  or.w	  d0,dst_DMACONtemp(a3) ;Set audio channel DMA bit
  move.w  d0,_CUSTOM+DMACON  ;Audio channel DMA off
  move.l  n_start(a2),(a6)   ;AUDxLCH Set sample start
  move.l  n_length(a2),4(a6) ;AUDxLEN & AUDxPER Set length & new note period

; ** Check audio channel for more effect commands at tick #1 **
dst_CheckMoreEffects
  move.w  n_dmabit(a2),d0    ;Get channel modulation bit
  move.b  d0,d2              ;Save channel modulation bit
  lsl.b   #NIBBLESHIFTBITS,d2 ;Shift channel period modulation bit to upper nibble
  or.b    d2,d0              ;Set channel volume modulation bit
  move.w  d0,_CUSTOM+ADKCON  ;Clear channel modulation bits
  tst.b   n_cmdlo(a2)        ;Command data = NULL ?
  bne.s   dst_ContAutoVolSlide ;No -> skip
  move.b  d5,n_volslidecmd(a2) ;Clear volume slide command data = Stop auto volume slide
dst_ContAutoVolSlide
  moveq   #dst_cmdnummask,d0
  and.b   n_cmd(a2),d0       ;Get channel effect command number without nibble of sample number
  beq.s   dst_ChkMoreEfxEnd  ;If NULL -> skip
  subq.b  #8,d0              ;8 "Modulate Period + Volume of next higher voice + Portamento Up" ?
  beq.s   dst_ModulateVolPlusPer
  subq.b  #4,d0              ;C "Set Volume" ?
  beq.s	  dst_SetVolume
  subq.b  #2,d0              ;E "Set Auto Volume Slide" ?
  beq.s	  dst_SetAutoVolumeSlide
  subq.b  #1,d0              ;F "Set Speed" ?
  beq.s   dst_SetSpeed
  addq.b  #4,d0              ;B "Modulate Period + Volume of next higher voice + Portamento Down" ?
  beq.s   dst_ModulateVolPlusPer
  addq.b  #1,d0              ;A "Modulate Period of next higher voice + Portamento Down" ?
  beq.s   dst_ModulatePeriod
  addq.b  #1,d0              ;9 "Modulate Volume of next higher voice + Portamento Down" ?
  beq.s   dst_ModulateVolume
  addq.b  #1,d0              ;7 "Modulate Period of next higher voice + Modulate Period of next higher voice + Portamento Up" ?
  beq.s   dst_ModulatePeriod
  addq.b  #1,d0              ;6 "Modulate Volume of next higher voice + Portamento Up" ?
  beq.s   dst_ModulateVolume
  addq.b  #1,d0              ;5 "Modulate Period + Volume of next higher voice + normal play or Arpeggio" ?
  beq.s   dst_ModulateVolPlusPer
  addq.b  #1,d0              ;4 "Modulate Period of next higher voice + normal play or Arpeggio" ?
  beq.s   dst_ModulatePeriod
  addq.b  #1,d0              ;3 "Modulate Volume of next higher voice + normal play or Arpeggio" ?
  beq.s   dst_ModulateVolume
dst_ChkMoreEfxEnd
  rts

; ** Effect command 3xy "Modulate Volume of next higher voice + normal play or Arpeggio" **
; ** Effect command 6xx "Modulate Volume of next higher voice + Portamento Up" **
; ** Effect command 9xx "Effect command Fxx "Modulate Volume of next higher voice + Portamento Down" **
  CNOP 0,4
dst_ModulateVolume
  move.w  n_dmabit(a2),d0    ;Get channel volume modulation bit
  bra.s   dst_SetModulation

; ** Effect command 4xy "Modulate Period of next higher voice + normal play or Arpeggio" **
; ** Effect command 7xx "Modulate Period of next higher voice + Portamento Up" **
; ** Effect command Axx "Modulate Period of next higher voice + Portamento Down" **
  CNOP 0,4
dst_ModulatePeriod
  move.w  n_dmabit(a2),d0    ;Get channel modulation bit
  lsl.b   #NIBBLESHIFTBITS,d0 ;Shift channel period modulation bit to upper nibble
  bra.s   dst_SetModulation

; ** Effect command 5xy "Modulate Period + Volume of next higher voice + normal play or Arpeggio" **
; ** Effect command 8xx "Modulate Period + Volume of next higher voice + Portamento Up" **
; ** Effect command Bxx "Modulate Period + Volume of next higher voice + Portamento Down" **
  CNOP 0,4
dst_ModulateVolPlusPer
  move.w  n_dmabit(a2),d0    ;Get channel modulation bit
  move.b  d0,d2              ;Save channel modulation bit
  lsl.b   #NIBBLESHIFTBITS,d2 ;Shift channel period modulation bit to upper nibble
  or.b    d2,d0              ;Set channel volume modulation bit in lower nibble
dst_SetModulation
  or.w	  #ADKF_SETCLR,d0    ;Set bits
  move.w  d0,_CUSTOM+ADKCON  ;Set channel modulation bits
  rts

; ** Effect command Cxx "Set Volume" **
  CNOP 0,4
dst_SetVolume
  move.b  n_cmdlo(a2),d0     ;Get command data: xx-volume
  move.w  d0,8(a6)           ;AUDxVOL Set new volume
  rts

; ** Effect command Exy "Set Auto Volume Slide" **
  CNOP 0,4
dst_SetAutoVolumeSlide
  move.b  n_cmdlo(a2),n_volslidecmd(a2) ;Copy volume slide command data
  rts

; ** Effect command Fxx "Set Speed" **
  CNOP 0,4
dst_SetSpeed
  moveq   #dst_maxticks,d0   ;Mask for maximum ticks
  and.b   n_cmdlo(a2),d0     ;Get command data: xx-speed ($00-$0f ticks)
  beq.s   dst_SetSpdEnd      ;If speed = NULL -> skip
  move.w  d5,dst_Counter(a3) ;Set back ticks counter = tick #1
  move.w  d0,dst_CurrSpeed(a3) ;Set new speed ticks
dst_SetSpdEnd
  rts

  CNOP 0,4
dst_SetDMA
  moveq   #CIACRBF_START,d0
  or.b    d0,CIACRB(a5)      ;CIA-B timer B Start timer for DMA wait

dst_Dskip
  addq.w  #dst_pattposdata_SIZE/4,dst_PatternPosition(a3) ;Next pattern position
  cmp.w	  #dst_pattsize/4,dst_PatternPosition(a3) ;End of pattern reached ?
  bne.s	  dst_NoNewPositionYet ;No -> skip
dst_NextPosition
  move.w  dst_SongPosition(a3),d1 ;Get song position
  move.w  d5,dst_PatternPosition(a3) ;Set back pattern position = NULL
  addq.w  #1,d1              ;Next song position
  move.w  d1,dst_SongPosition(a3) ;Save new song position
  cmp.b	  dst_SongLength(a3),d1 ;Last song position reached ?
  bne.s	  dst_NoNewPositionYet ;No -> skip
  move.w  d5,dst_SongPosition(a3) ;Set back song position = NULL
dst_NoNewPositionYet
  move.l  (a7)+,a6
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
  lea     dst_Variables(pc),a3 ;Base of variables
  move.l  #_CIAB,a5          ;Base of CIA-B
  move.l  #_CUSTOM,a6        ;Base of custom chips
  bsr.s   dst_CheckDMAWait
  movem.l (a7)+,d0-d7/a0-a6
  rts

; ** Check DMA wait routine to be executed **
  CNOP 0,4
dst_CheckDMAWait
  move.w  dst_DMACONtemp(a3),d0 ;Get channel DMA bits
  or.w	  #DMAF_SETCLR,d0    ;DMA on
  move.w  d0,DMACON(a6)      ;Set channel DMA bits

  moveq   #1,d0              ;Length = 1 word
  cmp.w   dst_audchan1temp+n_replen(pc),d0 ;Repeat length = 1 word ?
  bne.s   dst_Audchan0Loop    ;No -> Loop sample
  move.l  dst_audchan1temp+n_loopstart(pc),AUD0LCH(a6) ;Set loop start for channel 1
  move.w  d0,AUD0LEN(a6)   ;Set repeat length for channel 1
dst_Audchan0Loop
  cmp.w   dst_audchan2temp+n_replen(pc),d0 ;Repeat length = 1 word ?
  bne.s   dst_Audchan1Loop    ;No -> Loop sample
  move.l  dst_audchan2temp+n_loopstart(pc),AUD1LCH(a6) ;Set loop start for channel 2
  move.w  d0,AUD1LEN(a6)   ;Set repeat length for channel 2
dst_Audchan1Loop
  cmp.w   dst_audchan3temp+n_replen(pc),d0 ;Repeat length = 1 word ?
  bne.s   dst_Audchan2Loop    ;No -> Loop sample
  move.l  dst_audchan3temp+n_loopstart(pc),AUD2LCH(a6) ;Set loop start for channel 3
  move.w  d0,AUD2LEN(a6)   ;Set repeat length for channel 3
dst_Audchan2Loop
  cmp.w   dst_audchan4temp+n_replen(pc),d0 ;Repeat length = 1 word ?
  bne.s   dst_Audchan3Loop    ;No -> Loop sample
  move.l  dst_audchan4temp+n_loopstart(pc),AUD3LCH(a6) ;Set loop start for channel 4
  move.w  d0,AUD3LEN(a6)   ;Set repeat length for channel 4
dst_Audchan3Loop
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
  lea     dst_Variables(pc),a3 ;Base of variables
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
  move.w  #dst_DMABITS,DMACON(a6) ;Turn audio DMA off
  moveq   #-(-(~CIAF_LED)&BYTEMASK),d0
  and.b   d0,CIAPRA(a4)      ;Turn soundfilter off
  rts



; ************************* Tables & variables ***********************

; ** Tables for effect command **
; -------------------------------

; ** "Arpeggio" **
  CNOP 0,2
dst_PeriodTable
; Note C   C#  D   D#  E   F   F#  G   G#  A   A#  B
  DC.W 856,808,762,720,678,640,604,570,538,508,480,453 ;Octave 1
  DC.W 428,404,381,360,339,320,302,285,269,254,240,226 ;Octave 2
  DC.W 214,202,190,180,170,160,151,143,135,127,120,113 ;Octave 3
  DC.W 000                                             ;Noop
dst_PeriodTableEnd

; ** "Modulate" **
dst_ModulateTable
  DC.W $0c39,$0039,$00bf,$ec01,$6630,$0839,$0007,$00bf
  DC.W $e001,$6626,$2c79,$0000,$0004,$43fa,$0020,$4eae
  DC.W $fe68,$2c40,$4280,$41fa,$0026,$223c,$0000,$0032
  DC.W $4eae,$ffa6,$60ee,$0000,$0000,$4e75,$696e,$7475
  DC.W $6974,$696f,$6e2e,$6c69,$6272,$6172,$7900,$0104
  DC.W $1753,$6f75,$6e64,$5472,$6163,$6b65,$7220,$5632
  DC.W $0063,$00f0,$20a9,$2054,$6865,$204a,$756e,$676c
  DC.W $6520,$436f,$6d6d,$616e,$6400,$0000

; ** Temporary channel structures **
; ----------------------------------
  CNOP 0,4
dst_audchan1temp
  DS.B n_audchantemp_SIZE

  CNOP 0,4
dst_audchan2temp
  DS.B n_audchantemp_SIZE

  CNOP 0,4
dst_audchan3temp
  DS.B n_audchantemp_SIZE

  CNOP 0,4
dst_audchan4temp
  DS.B n_audchantemp_SIZE

; ** Pointers to samples **
; -------------------------
  CNOP 0,4
dst_SampleStarts
  DS.L dst_samplesnum

; ** Variables **
; ---------------
dst_variables DS.B dst_variables_SIZE

; ** Names **
; -----------
gfxname DC.B "gfx.library",TRUE



; ************************* Module Data ***********************

; ** Module to be loaded as binary into CHIP memory **
; ----------------------------------------------------
dst_auddata SECTION audio,DATA_C

  INCBIN "MOD.example"

  END
