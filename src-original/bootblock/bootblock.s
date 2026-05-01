; ------------------------------------------------------------------------------------------------
; INFINITE DREAMS - 3 disk music disk
; (c)1992 - The Lunatics UK
;
;
;
; INFO & CONTEXT:
;   - This was the first (and last, for the time) track-loader based demo that I released for any demo group in the good old days.
;
;   - The demo was released on the A500 and the loader does not work on the A1200 which had disk drives that
;     don't signal the DSKRDY line, so this fails on an A1200 machine in an infinite loop waitng for DSKRDY.
;
;   - There's some dubious Action Replay protection stuff going on in the initialise_bootloader routine.
;
;   - I was 16/17 years old when I wrote this in the days before access to the web, using information gleened from
;     The harware reference manual and various disk magazines available at the time.
;
;
; DESCRIPTION:
;   - The loader only deals in loading and decoding whole tracks into memory.
;
;   - It does the following actions:
;       - init system & check for action replay cartridges
;       - loads & display the Title Screen into $20000 (tracks 0-9) - gfx starts at $20400
;       - loads & executes the main demo into $45000 (tracks)
;
;   - A couple of assumptions are made by the code including-
;       1) The disk heads start at track 0 when loading
;       2) The boot block is loaded into memory that won't be overwritten by other files loaded.
;       3) Assumes tracks/sectors all load correctly into memory (no checksum calcs)
;
;
; DISK LAYOUT:
;   - TITLE SCREEN
;       - Track 0-10 on disk 1
;       - 32 colour palette (64 bytes)
;         - starts - $20400
;         - ends   - $20440
;       - 5 bitplane PAL display.
;          bpl1 - $00020440 = $2800 bytes (10240) - 320x256
;          bpl2 - $00022C40 = $2800 bytes (10240) - 320x256
;          bpl3 - $00025440 = $2800 bytes (10240) - 320x256
;          bpl4 - $00027C40 = $2800 bytes (10240) - 320x256
;          bpl5 - $0002A440 = $2800 bytes (10240) - 320x256
;          - Starts - $20440
;          - Ends   - $2CC40
;
;   - DEMO MUSIC DISK
;       - Track 11-18 on disk 1
;       - Progam Details
;           - can't remember (TODO after disassembly)
;

                    section     bootloader,code_c
                    incdir      "include/"
                    include     "hw.i"



TESTBOOT SET 1                                              ; Comment this to remove 'testboot'

        IFD TESTBOOT 
                    jmp     start_boot
        ENDC 



TRACK_BUFFER_ADDR       EQU     $00075000                   ; mfm track buffer address ($1a00 length = 13312 bytes, or 13Kb)
TRACK_BUFFER_WORDS      EQU     $1a00
TRACK_BUFFER_BYTES      EQU     TRACK_BUFFER_WORDS*2        ; $3400

TITLE_SCREEN_ADDR       EQU     $00020000                   ; load addres of title screen (colours followed by raw gfx)
TITLE_SCREEN_COLOURS    EQU     $00020400                   ; address of the start of the title screen palette
TITLE_SCREEN_GFX        EQU     $00020440                   ; address of the start of the title screen bitplane gfx

MUSIC_DEMO_ADDR         EQU     $00045000                   ; executable code (cant remember if compressed)



            ; ------------- boot block header -------------
bootblock_header    dc.b    'DOS',0                     ; DiskType = 'DOS,0'
                    dc.l    $010C8415                   ; original checksum
                    dc.l    $00000001                   ; rootblock (normally 880 ($370) on a standard DOS Disk)




            ; ------------- code entry point ---------------
start_boot          BSR.W   initialise_bootloader 
                    BRA.W   do_load_demo 



            ; ------------- select drive 0 -----------------
select_drive0
                    OR.B    #$08,$00bfd100              ; deselect disk 0
                    AND.B   #$7f,$00bfd100              ; motor on
                    AND.B   #$f7,$00bfd100              ; select disk 0
.wait_rdy           BTST.B  #$0005,$00bfe001            ; **** wait for DSKRDY - fail on A1200 ****
                    BNE.B   .wait_rdy
                    RTS 



            ; -------------- deselect drive 0 -------------
deselect_drive0
                    OR.B    #$88,$00bfd100              ; motor off, deselect drive 0
                    AND.B   #$f7,$00bfd100              ; select drive 0 to latch
                    OR.B    #$08,$00bfd100              ; deselect drive 0
                    RTS 


            ; ------------- read raw track ---------------
            ; reads raw track from disk (mfm encoded)
            ; reads length $1a00 (6656 words)
            ;   6656 words = 13312 bytes
            ;   13312 bytes = 13Kb exactly
            ;
read_raw_track
                    MOVE.L  TRACK_BUFFER_ADDR,$0020(A6)
                    MOVE.W  #$7f00,ADKCON(A6)           ; clear bits
                    MOVE.W  #$9500,ADKCON(A6)           ; set bits
                    MOVE.W  #$8210,DMACON(A6)           ; enable disk DMA
                    MOVE.W  #$0000,DSKLEN(A6)           ; disable disk DMA, set 0 length
                    MOVE.W  #$9a00,DSKLEN(A6)           ; read $1a00 word (6656 x 2 = 13312)
                    MOVE.W  #$9a00,DSKLEN(A6)
.wait_dskblk        BTST.B  #$0001,INTREQR+1(A6)        ; wait DSKBLK intterrupt
                    BEQ.B   .wait_dskblk
                    MOVE.W  #$0000,DSKLEN(A6)           ; disable disk DMA, set 0 length
                    MOVE.W  #$0002,INTREQ(A6)           ; clear DSKBLK interrupt
                    MOVE.W  #$0010,DMACON(A6)           ; disable disk DMA
                    RTS 



            ; ---------------- initialise boot loader -----------------
            ; The usual disable DMA, Interrupts
            ; Fade screen from white to black
            ; Try to detect and kill loading with action replay
            ;
initialise_bootloader
                    LEA.L   CUSTOM,a6                       ; $00dff000,A6

                ; action replay fiddling 
.action_reply_chk1  MOVE.L  #$00000000,D0
                    MOVE.L  D0,$00000060                    ; Suprious Interrupt Vector
                    MOVE.L  D0,$0000007c                    ; Level 7 Interrupt Vector

                ; some h/w init
.init_hardware      MOVE.W  #$7fff,D0
                    MOVE.W  D0,DMACON(A6)                   ; all DMA off
                    MOVE.W  D0,INTREQ(A6)                   ; clear signaled interrupts
                    MOVE.W  #$3fff,INTENA(A6)               ; disable all interrupts        
                    MOVE.W  #$4489,DSKSYNC(A6)              ; set disk sync value to DOS sync mark $4489

                ; fade screen to black
.fade_screen_to_black
                    MOVE.W  #$0fff,D0                       ; white - initial background colour
.raster_wait_1      CMP.B   #$20,VHPOSR(A6)                 ; wait for raster line $20
                    BNE.B   .raster_wait_1
.raster_wait_2      CMP.B   #$30,VHPOSR(A6)                 ; wait for raster line $30
                    BNE.B   .raster_wait_2

.set_colour         SUB.W   #$0111,D0
                    MOVE.W  D0,COLOR00(A6)
                    BEQ.B   .action_reply_chk2
                    BRA.B   .raster_wait_1

                ; action replay check again
.action_reply_chk2
                    MOVE.L  #$00000001,COP2LCH(A6)          ; set odd address for copper list 2 (disable certain version of action replay when activated)
                    MOVE.L  #$00000000,$00000004            ; clear 68000 reset PC in ram (not sure this does anything useful)
                    CMP.L   #$c5f00006,$0000007c            ; check Level 7 interrupt vector
                    BNE.B   .no_action_reply_detected       ; no action replay detected
.kill_amiga         LEA.L   .rom_jump(PC),A0                ; call jump into ROM (maybe dodgy reset on 1.3 can't remember)
                    MOVE.L  A0,$00000080                    ; set TRAP #00 vector
                    TRAP    #$00000000                      ; call .rom_jump as supervisor.
                    RTS                                     ; exit and don't care if we get here.
.rom_jump           JMP     $00fc0002                       ; the computer either resets or crashes here...

                ; no action replay detected 
.no_action_reply_detected 
                    RTS 



            ; ---------------- timer wait -----------------
            ; sets the CIAB Timer A to run a one-shot
            ; timer value $2000 (8192) (0.11 of a second)
            ;    - CIAB timers tick at 709379 ticks per second (pal)
            ;       = (1/709379)*8192 = 0.11
            ;
            ; I'm a bit dubious as to whether this is doing
            ; what I think it is.
            ;
timer_wait          MOVE.B  #$00,$00bfde00          ; CIAB - CRA Control Register A (stop timer)
                    MOVE.B  #$7f,$00bfdd00          ; CIAB - ICR interrupt Control Register (clear all)
                    MOVE.B  #$00,$00bfd400          ; CIAB - TALO - Timer A low byte
                    MOVE.B  #$20,$00bfd500          ; CIAB - TAHI - Timer A high byte ($2000)
                    MOVE.B  #$09,$00bfde00          ; CIAB - CRA - Oneshot & Start
.wait_timer         BTST.B  #$0000,$00bfdd00        ; CIAB - ICR - Wait for TA (Timer A)
                    BEQ.B   .wait_timer 
                    RTS 



            ; -------------------- heads to track --------------------   
            ; Move heads to track number set in D0.
            ; Even tracks = lower disk head (0,2,4,6,8... etc)
            ;   
            ; IN:
            ;      d0.w = desired track number 
            ;
heads_to_track      MOVE.W  current_track(PC),D3
                    CMP.W   D3,D0                   ; check if already at desired track
                    BEQ.B   .completed_steps         ; yes, then skip to end

                ; get cylinder numbers from track numbers
.get_cylinder_no    MOVE.W  D0,D2
                    LSR.W   #$00000001,D2           ; d2 = required cylinder
                    LSR.W   #$00000001,D3           ; d3 = current cylinder

                ; select correct disk head (top/bottom)
                ; odd tracks are on the bottom head.
.set_disk_side      BTST.L  #$0000,D0               ; check if desired track is odd/even
                    BNE.B   .track_is_odd
                ; select bottom head
.track_is_even      OR.B    #$04,$00bfd100          ; select bottom head  /side = 1 
                    BRA.B   .step_to_cylinder
                ; select top head
.track_is_odd       AND.B   #$fb,$00bfd100          ; select top head /side = 0 

                ; step heads to correct cylinder
.step_to_cylinder   CMP.W   D3,D2                   ; compare current (d3) with required (d2)
                    BEQ.B   .completed_steps        ; if equal, finished stepping
                    BGT.B   .step_inwards           ; if required > current, step inwards
                                                    ; else step outwards
                ; step outwards (towards 0)
.step_outwards      MOVE.B  #$02,$00bfd100          ; /dir = 1 (outwards)
                    BSR.B   step_heads              
                    BSR.B   timer_wait 
                    SUB.W   #$00000001,D3           ; decrement current cylinder
                    BRA.B   .step_to_cylinder       ; step again

                ; step inwards (towards 80)
.step_inwards       AND.B   #$fd,$00bfd100          ; /dit = 0 (inwards)
                    BSR.B   step_heads
                    BSR.B   timer_wait
                    ADD.W   #$00000001,D3           ; increment current cylinder
                    BRA.B   .step_to_cylinder       ; step again

                ; reached destination
.completed_steps    LEA.L   current_track(PC),A0
                    MOVE.W  D0,(A0)                 ; update current track
                    RTS 


            ; -------------------- timer wait --------------------
            ; to step the heads then the /step bit of CIAB - PRA
            ; has to be pulsed. I'm missig a wait in the pulse
            ; so this may fail on fast machines.
step_heads          OR.B    #$01,$00bfd100          ; set /STEP 
                    AND.B   #$fe,$00bfd100          ; clear /STEP
                    OR.B    #$01,$00bfd100          ; set /STEP
                    RTS 



; Each Track contains 11 sectors on a normal DOS track.
;
; Each Track contains one track gap of varying length (less than one sector in size) 
; which can occur inbetween any sector on the track.
;
; Each Sector begins with a Sector Header of 2 words (mfm encoded) sync marks
;  - 0x4489, 0x4489
;
; The header is followed by the Admin Block of 56 bytes (mfm encoded), 28 bytes (decoded)
; Admin Block/Sector Header (28 bytes decoded)
; Offset        Data Field
; 0             dc.b   FormatId         - 
; 1             dc.b   TrackNumber      - current track number (even = bottom side, odd = top side)
; 2             dc.b   SectorNumber     - current sector number (0 - 10)
; 3             dc.b   SectorsToGap     - number of sectors until the track gap (1 - 11)
; $4  - 4       dc.l   0,0,0,0          - 16 admin bytes (normally 0 for DOS Disk) can be used to store info
; $14 - 20      dc.l   headerChecksum
; $18 - 24      dc.l   dataChecksum
;
; Next is the 1024 bytes of mfm encoded data, 512 bytes decoded
;  - The data is typically formatted as two blocks of 182 long words
;  - Can also be stored as Odd/Even interleaved long words
;

            ; -------------------- decode mfm --------------------
            ; IN:
            ;   A4 = ptr to decode buffer
decode_mfm
                    MOVEA.L #TRACK_BUFFER_ADDR,A0
                    MOVE.L  #$0000000a,D6

.skip_sync_1        MOVE.W  (A0)+,D5
                    CMP.W   #$4489,D5
                    BNE.B   .skip_sync_1
                    
.skip_sync_2        MOVE.W  (A0),D5
                    CMP.W   #$4489,D5
                    BNE.B   .decode_sector_header
                    ADDA.W  #$00000002,A0

.decode_sector_header
            ; decode first header longword 
                    MOVE.L  (A0)+,D5
                    MOVE.L  (A0)+,D4
                    AND.L   #$55555555,D5
                    AND.L   #$55555555,D4
                    LSL.L   #$00000001,D5
                    OR.L    D4,D5
                    AND.W   #$ff00,D5               ; d5 = sector number * 256
                    LSL.W   #$00000001,D5           ; d5 = sector number * 512 (index to dest buffer)
                    LEA.L   $00(A4,d5.w),A3         ; a3 = decoded sector destination address
                    LEA.L   $0030(A0),A0            ; skip rest of header (no checksums validated)
            ; decode sector data
.decode_sector_data MOVE.W  #$007f,D7               ; decode 127+1 mfm longwords (512 bytes)
.decode_sector_loop MOVE.L  $0200(A0),D4            ; d4 = even mfm encodd bits stored at 512 byte offset
                    MOVE.L  (A0)+,D5                ; d5 = odd mfm encoded bits
                    AND.L   #$55555555,D5           ; clear mfm clock bits
                    AND.L   #$55555555,D4           ; clear mfm clock bits
                    LSL.L   #$00000001,D5           ; shift odd bits
                    OR.L    D4,D5                   ; recombine odd/even bits
                    MOVE.L  D5,(A3)+                ; store decoded long in dest buffer
                    DBF.W   D7,.decode_sector_loop
                    DBF.W   D6,.skip_sync_1 
                    RTS 



            ; ------------------ do load demo --------------------
            ; this routine is the 'main' function that:-
            ; 1) loads the title screen gfx
            ; 2) fades in title screen
            ; 3) loads the main music demo code
            ; 4) fades out title screen
            ; 5) execute main music demo code
            ;
do_load_demo        BSR.W   select_drive0 

                ; load title screen 
.load_titlescreen   MOVE.L  #$00000000,D0               ; start track 0
                    MOVE.L  #$00000009,D1               ; load 10 tracks (0-9)
                    LEA.L   TITLE_SCREEN_ADDR,A4
                    BSR.B   load_tracks

                ; set copper display for title screen
                    MOVE.W  #$8180,DMACON(A6)
                    LEA.L   copper_list(pc),a0 
                    MOVE.L  A0,COP1LC(A6)
                    MOVE.W  COPJMP1(A6),D0

                ; fade in title screen
                    MOVE.L  #$00000000,D7
.raster_wait_1      CMP.B   #$f0,VHPOSR(A6)
                    BNE.B   .raster_wait_1
                    BSR.B   fade_in_titlescreen
                    ADD.B   #$00000001,D7
                    CMP.B   #$14,D7
                    BNE.B   .raster_wait_1

                ; load music demo
.load_musicdemo     MOVE.L  #$0000000b,D0               ; start track 11
                    MOVE.L  #$00000007,D1               ; load 8 tracks (11-18)
                    LEA.L   MUSIC_DEMO_ADDR,A4
                    BSR.B   load_tracks

                ; fade out title screen
                    MOVE.L  #$00000000,D7
.raster_wait_2      CMP.B   #$f0,VHPOSR(A6)
                    BNE.B   .raster_wait_2
                    BSR.W   fade_out_titlescreen
                    ADD.B   #$00000001,D7
                    CMP.B   #$14,D7
                    BNE.B   .raster_wait_2

                ; clean-up & start demo
L0001026C           BSR.W   deselect_drive0             
L00010270           MOVE.W  #$7fff,$0096(A6)
L00010276           JMP     MUSIC_DEMO_ADDR             ; jump to main loader exe
                ; ******************************
                ; ******** NEVER RETURN ********
                ; ******************************



            ; ------------------------- load tracks ------------------------
            ; load tracks from disk into memory.
            ; IN:
            ;   D0.w = start track
            ;   D1.w = number of tracks-1 (one less than actually requied)
            ;   A4.l = load address
            ;
load_tracks
                    BSR.W   heads_to_track          ; initalise disk heads
                    BSR.W   read_raw_track          ; read trask
                    BSR.W   decode_mfm              ; decode track to memory
                    ADDA.L  #$00001600,A4           ; increment load address - 11 sectors = 5.5Kb (5632 bytes per track)
                    ADD.W   #$00000001,D0           ; increment start to next track
                    DBF.W   D1,load_tracks
                    RTS 



            ; ------------------------- fade in title screen ------------------------
fade_in_titlescreen LEA.L   TITLE_SCREEN_COLOURS,A0         ; gfx palette $20400
                    LEA.L   copper_colours(pc),a1 
                    MOVE.L  #$0000001f,D6                   ; 32 colour screen display
                    MOVE.W  #$0002,D5                       ; copper - index to colour value
                ; fade colour loop
.fade_loop          MOVE.W  (A0)+,D0                        ; d0 = palette colour value
                ; fade blue colour component
.fade_blue          MOVE.W  D0,D1       
                    MOVE.W  $00(A1,d5.w),D2                 ; d2 = current fade colour
                    MOVE.B  D2,D3
                    AND.B   #$0f,D1                         ; mask blue bits (src & dest)
                    AND.B   #$0f,D3
                    CMP.B   D1,D3
                    BEQ.B   .fade_green
                    ADD.B   #$00000001,$01(A1,d5.w)
                ; fade green colour component
.fade_green         MOVE.B  D0,D1
                    MOVE.B  D2,D3
                    AND.B   #$f0,D1
                    AND.B   #$f0,D3
                    CMP.B   D1,D3
                    BEQ.B   .fade_red
                    ADD.B   #$10,$01(A1,D5.W)
                ; fade red colour component
.fade_red           AND.W   #$0f00,D0
                    AND.W   #$0f00,D2
                    CMP.W   D0,D2
                    BEQ.B   .fade_next
                    ADD.B   #$00000001,$00(A1,D5.W)
                ; fade next colour - loop
.fade_next          ADD.W   #$00000004,D5                   ; increase copper index to next colour value index
                    DBF.W   D6,.fade_loop
                    RTS 



            ; ------------------------- fade out title screen ------------------------
fade_out_titlescreen
                    LEA.L   copper_colours(pc),a0 
                    MOVE.L  #$00000002,D5                   ; copper colour value index
                    MOVE.L  #$0000001f,D6                   ; 32 colour screen
                ; fade colour loop
.fade_loop          MOVE.W  $00(A0,D5.W),D0                 ; d0 = copper colour value
                ; fade blue colour component
.fade_blue          MOVE.B  D0,D1
                    AND.B   #$0f,D1                         ; mask blue component
                    TST.B   D1
                    BEQ.B   .fade_green
                    SUB.B   #$00000001,$01(A0,D5.W)
                ; fade green colour component
.fade_green         MOVE.B  D0,D1
                    AND.B   #$f0,D1
                    TST.B   D1
                    BEQ.B   .fade_red
                    SUB.B   #$10,$01(A0,D5.w)
                ; fade red colour component
.fade_red           AND.W   #$0f00,D0
                    TST.W   D0
                    BEQ.B   .fade_next
                    SUB.W   #$0100,$00(A0,D5.W)
                ; fade next colour - loop
.fade_next          ADD.W   #$00000004,D5
                    DBF.W   D6,.fade_loop
                    RTS 


current_track       dc.w    $0000               ; floppy head's current track number


            ; ------------------- copper list ----------------------
            ; 5 bitplane PAL display.
            ;   bpl1 - $00020440 = $2800 bytes (10240) - 320x256
            ;   bpl2 - $00022C40 = $2800 bytes (10240) - 320x256
            ;   bpl3 - $00025440 = $2800 bytes (10240) - 320x256
            ;   bpl4 - $00027C40 = $2800 bytes (10240) - 320x256
            ;   bpl5 - $0002A440 = $2800 bytes (10240) - 320x256
copper_list         dc.w    DDFSTRT,$0038         ; PAL DMA Fetch 
                    dc.w    DDFSTOP,$00D0
                    dc.w    DIWSTRT,$2C81         ; PAL Window size
                    dc.w    DIWSTOP,$2CC1
                    dc.w    BPLCON1,$0000
                    dc.w    BPL1MOD,$0000
                    dc.w    BPL2MOD,$0000
                ; set colour palette
copper_colours      dc.w    COLOR00,$0000
                    dc.w    COLOR01,$0000
                    dc.w    COLOR02,$0000
                    dc.w    COLOR03,$0000
                    dc.w    COLOR04,$0000
                    dc.w    COLOR05,$0000
                    dc.w    COLOR06,$0000
                    dc.w    COLOR07,$0000
                    dc.w    COLOR08,$0000
                    dc.w    COLOR09,$0000
                    dc.w    COLOR10,$0000
                    dc.w    COLOR11,$0000
                    dc.w    COLOR12,$0000
                    dc.w    COLOR13,$0000
                    dc.w    COLOR14,$0000
                    dc.w    COLOR15,$0000
                    dc.w    COLOR16,$0000
                    dc.w    COLOR17,$0000
                    dc.w    COLOR18,$0000
                    dc.w    COLOR19,$0000
                    dc.w    COLOR20,$0000
                    dc.w    COLOR21,$0000
                    dc.w    COLOR22,$0000
                    dc.w    COLOR23,$0000
                    dc.w    COLOR24,$0000
                    dc.w    COLOR25,$0000
                    dc.w    COLOR26,$0000
                    dc.w    COLOR27,$0000
                    dc.w    COLOR28,$0000
                    dc.w    COLOR29,$0000
                    dc.w    COLOR30,$0000
                    dc.w    COLOR31,$0000
                    dc.w    $2C01,$FFFE
                    dc.w    BPL1PTH,$0002         ; bpl1 - $00020440
                    dc.w    BPL1PTL,$0440
                    dc.w    BPL2PTH,$0002         ; bpl2 - $00022C40
                    dc.w    BPL2PTL,$2C40
                    dc.w    BPL3PTH,$0002         ; bpl3 - $00025440
                    dc.w    BPL3PTL,$5440
                    dc.w    BPL4PTH,$0002         ; bpl4 - $00027C40
                    dc.w    BPL4PTL,$7C40
                    dc.w    BPL5PTH,$0002         ; bpl5 - $0002A440
                    dc.w    BPL5PTL,$A440
                    dc.w    BPLCON0,$5200       ; 5 bitplanes, COLOR = ON
                    dc.w    $FFFF,$FFFE



