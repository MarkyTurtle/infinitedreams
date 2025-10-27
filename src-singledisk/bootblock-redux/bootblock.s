; ------------------------------------------------------------------------------------------------
; INFINITE DREAMS - 1 disked - music disk
; (c)1992-2025 - The Lunatics UK
;
; Basic MFM Boot loader to load the Zx0 Compressed 'demo' file from the Disk.
; The executable demo is decompressd to $2000 to $1c000 in memory (with slack space for exe growth)
;


                    section     bootloader,code_c
                    incdir      "include/"
                    include     "hw.i"



;TESTBOOT SET 1                                              ; Comment this to remove 'testboot'


STACK_ADDRESS           EQU $1000       ; stack ptr address will grow down from start of boot block
BOOT_RELOCATE_ADDR      EQU $1000       ; absolute memory address to relocate the bootblock at.


MFM_BUFFER              EQU $7d140      ; $80000-$2ec0 RAW MFM Track Buffer (required for 4489 loader)

FILE_TABLE_ADDR         EQU $1400       ; absolute address for loading the disk file table at.
FILE_TABLE_OFFSET       EQU $400        ; disk offset to file table (directly following the bootblock)
FILE_TABLE_LENGTH       EQU $1a0        ; length of file table in bytes

LOAD_ADDRESS            EQU $50000      ; Address to load packed files into (loading screen/demo)
TPIC_START_ADDRESS      EQU $70000      ; title pic decrunch address.
DEMO_START_ADDRESS      EQU $2000       ; demo decrunch/execute address.

TPIC_COPPER_ADDR        EQU $3a000       ; absolute address of title pic copper list



        IFD TESTBOOT 
                    jmp     start_boot

test_mfm_buffer         dcb.w   $1760,$ffff
test_load_buffer        dcb.w   $a000,$1111
test_decrunch_buffer    dcb.w   $1c000,$2222
        ENDC 



                ; ------------- boot block header -------------
bootblock_header    dc.b    'DOS',0                     ; DiskType = 'DOS,0'
                    dc.l    $00000000                   ; bootblock checksum value
                    dc.l    $00000001                   ; rootblock (normally 880 ($370) on a standard DOS Disk)



                ; ------------- code entry point ---------------
start_boot              lea     CUSTOM,a6 
                        move.w  #$7fff,d0
                        move.w  #$3fff,INTENA(a6)
                        move.w  d0,INTREQ(a6)
                        move.w  d0,DMACON(a6)
copy_bootloader:
                        lea     boot_loader(pc),a0
                        lea     BOOT_RELOCATE_ADDR,a1
                        move.w  #(bootblockend-boot_loader)/4,d7
.copy_loop              move.w  (a0)+,(a1)+
                        dbf     d7,.copy_loop
                        jmp     $00001000



                ; ------------- relocated boot loader $00001000 -----------
boot_loader             lea   STACK_ADDRESS,A7

load_file_table     ; load the file table
                        move.l #FILE_TABLE_OFFSET,d0
                        move.l #FILE_TABLE_LENGTH,d1
                        lea    FILE_TABLE_ADDR,a0
                        lea    MFM_BUFFER,a1
                        bsr    byteloader
                
load_title_screen   ; load and display title picture
                        move.l  #'tpic',d0
                        lea     LOAD_ADDRESS,a0
                        lea     TPIC_START_ADDRESS,a1
                        bsr     load_file

                    ; set title screen parameters
                        lea     CUSTOM,a6
                        move.l  #$003800d0,DDFSTRT(a6)
                        move.l  #$2c812cc1,DIWSTRT(a6)
                        move.w  #$0000,BPLCON1(a6)
                        move.l  #$00000000,BPL1MOD(a6)

                    ; set copper colours
                        lea     LOAD_ADDRESS,a0
                        lea     TPIC_COPPER_ADDR,a1
                        move.w  #31,d7                          ; 32 colours
                        move.l  #$01800000,d0
.col_loop               move.l  d0,(a0)+
                        add.l   #$00020000,d0
                        dbf     d7,.col_loop

                    ; copper bitplane addresses
                        move.l  #TPIC_START_ADDRESS,d0
                        add.l   #$40,d0
                        move.w  #4,d7                           ; 5 bitplanes
                        move.w  #BPL1PTH,d1                     ; BPL1PTH
.bpl_loop
                        swap.w   d0
                        move.w  d1,(a0)+
                        move.w  d0,(a0)+                ; high word
                        add.w   #2,d1
                        swap.w  d0
                        move.w  d1,(a0)+
                        move.w  d0,(a0)+                ; low word
                        add.w   #2,d1
                        add.l   #$2800,d0               ; next bitplane ptr
                        dbf     d7,.bpl_loop

                        move.l  #$01005200,(a0)+        ; 5 bitplane screen
                        move.l  #$fffffffe,(a0)+        ; copper end wait

                    ; set copper display for title screen
                        ;lea     CUSTOM,a6
                        move.w  #$8180,DMACON(A6)
                        lea     TPIC_COPPER_ADDR,a0 
                        move.l  A0,COP1LC(A6)
                        ;move.w  COPJMP1(A6),D0

fade_in_title_pic   ; fade in title pic
                        move.w  #16,D7
.raster_wait_1          bsr     raster_wait

                        move.l  d7,-(a7)
                        lea     TPIC_START_ADDRESS,a0 
                        lea     TPIC_COPPER_ADDR,a1
                        bsr     fade_in_titlescreen
                        move.l  (a7)+,d7

                        dbf     d7,.raster_wait_1



                    ; load and execute demo
load_compressed_demo
                        move.l  #'demo',d0
                        lea     LOAD_ADDRESS,a0
                        lea     DEMO_START_ADDRESS,a1
                        bsr     load_file


                    ; fade out title pic
                        move.w  #16,D7
.raster_wait_2          bsr     raster_wait
                        lea     TPIC_COPPER_ADDR,a0
                        bsr     fade_out_titlescreen
                        dbf     d7,.raster_wait_2


                        jmp     DEMO_START_ADDRESS


raster_wait             lea     CUSTOM,a6    
                        cmp.b   #$f0,VHPOSR(A6)
                        bne.b   raster_wait
                        rts



; d0 = fileid
; a0 = load address
; a1 = decomparess address
load_file               movem.l d0-d7/a0-a6,-(a7)
                        move.w  #27-1,d7                        ; size of file table (26 entries)
                        lea     FILE_TABLE_ADDR,a3

.find_file          ; find file id (d0) in file table
                        cmp.l   (a3),d0
                        beq     .load_file
                        lea     $10(a3),a3
                        dbra    d7,.find_file

.load_error         ; load error
                        move.w  #$f00,$dff180
                        bra.s   .load_error

.load_file          ; load file from disk to (a0)
                        move.l  $4(a3),d0                       ; disk byte offset
                        move.l  $c(a3),d1                       ; disk file length
                        moveq   #0,d2                           ; drive 0
                        lea     MFM_BUFFER,a1
                        bsr     byteloader
                        tst.l   d0
                        bne.s   .load_error                     ; some kinda disk error.
                        movem.l (a7)+,d0-d7/a0-a6

                    ; decompress file to (a1)
                        bsr     zx0_decompress

                        rts




                ; in:   a0 = address of 32 colours (words)
                ;       a1 = address of copper colour registers set in copper list
                ; ------------------------- fade in title screen ------------------------
fade_in_titlescreen
                    move.w  #32-1,d7
.fade_loop
                    move.w  (a0)+,d0
                    move.w  2(a1),d2            ; current colour
                    move.w  #$000f,d4
                    move.w  #$0001,d5
                    move.w  #$0002,d6           ; 3 colour components to fade in
.fade_component
                    move.w  d0,d1
                    move.w  d2,d3
                    and.w   d4,d1
                    and.w   d4,d3
                    cmp.w   d1,d3
                    beq.s   .next_component
                    add.w   d5,d2               ; fade colour component
.next_component
                    ror.w   #4,d4
                    ror.w   #4,d5
                    dbf.w   d6,.fade_component

.update_color       
                    move.w  d2,2(a1)            ; store faded colour
                    addq.l  #4,a1
                    dbf     d7,.fade_loop

                    rts     



;fade_in_titlescreen move.w  #$001f,D6                           ; 32 colour screen display
;                    add.l   #2,a1
;
;                ; fade colour loop
;.fade_loop          move.w  (A0)+,D0                            ; d0 = palette colour value
;                ; fade blue colour component
;.fade_blue          MOVE.W  D0,D1       
;                    MOVE.W  (A1),D2                             ; d2 = current fade colour
;                    MOVE.B  D2,D3
;                    AND.B   #$0f,D1                             ; mask blue bits (src & dest)
;                    AND.B   #$0f,D3
;                    CMP.B   D1,D3
;                    BEQ.B   .fade_green
;                    ADD.B   #$01,$01(A1)
;                ; fade green colour component
;.fade_green         MOVE.B  D0,D1
;                    MOVE.B  D2,D3
;                    AND.B   #$f0,D1
;                    AND.B   #$f0,D3
;                    CMP.B   D1,D3
;                    BEQ.B   .fade_red
;                    ADD.B   #$10,$01(A1)
;                ; fade red colour component
;.fade_red           AND.W   #$0f00,D0
;                    AND.W   #$0f00,D2
;                    CMP.W   D0,D2
;                    BEQ.B   .fade_next
;                    ADD.B   #$01,$00(A1)
;                ; fade next colour - loop
;.fade_next          add.l   #$0000004,a1                   ; increase copper index to next colour value index
;                    dbf.w   D6,.fade_loop
;                    RTS 



                ; in:   in: a0 = copper colours address
                ; ------------------------- fade in title screen ------------------------
fade_out_titlescreen
                    move.w  #32-1,d7
.fade_loop
                    move.w  2(a0),d0             ; current colour from copper list
                    move.w  #$000f,d4
                    move.w  #$0001,d5
                    move.w  #$0002,d6           ; 3 colour components to fade in
.fade_component
                    move.w  d0,d1
                    and.w   d4,d1
                    tst.w   d1
                    beq.s   .next_component
                    sub.w   d5,d0               ; fade colour component
.next_component
                    rol.w   #4,d4
                    rol.w   #4,d5
                    dbf.w   d6,.fade_component

.update_color       
                    move.w  d0,2(a0)
                    addq.l  #4,a0
                    dbf     d7,.fade_loop

                    rts    


            ; ------------------------- fade out title screen ------------------------
            ; in: a0 = copper colours address
;fade_out_titlescreen
;                lea     copper_colours(pc),a0
;                move.l  (a0),a0
;                    moveq  #$00000002,D5                   ; copper colour value index
;                    moveq  #$0000001f,D6                   ; 32 colour screen
;                ; fade colour loop
;.fade_loop          move.w  (A0,D5.W),D0                ; d0 = copper colour value
;                ; fade blue colour component
;.fade_blue          MOVE.B  D0,D1
;                    AND.B   #$0f,D1                         ; mask blue component
;                    TST.B   D1
;                    BEQ.B   .fade_green
;                    SUB.B   #$01,$01(A0,D5.W)
;                ; fade green colour component
;.fade_green         MOVE.B  D0,D1
;                    AND.B   #$f0,D1
;                    TST.B   D1
;                    BEQ.B   .fade_red
;                    SUB.B   #$10,$01(A0,D5.w)
;                ; fade red colour component
;.fade_red           AND.W   #$0f00,D0
;                    TST.W   D0
;                    BEQ.B   .fade_next
;                    SUB.W   #$0100,$00(A0,D5.W)
;                ; fade next colour - loop
;.fade_next          ADD.W   #$0004,D5
;                    DBF.W   D6,.fade_loop
;                    RTS 


copper_colours      dc.l    0

; -> d0.l  offset       (0-$dc000)
; -> d1.l  length       (0-$dc000)
; -> d2.l  drive        (0-3)
; -> a0.l  dst address  (anywhere)
; -> a1.l  mfm address  ($1760 words - sufficient as we snoop load)
;
; <- d0.l  == 0         (success)
; <- d0.l  != 0         (error)
;
;   call: byteloader
byteloader
                    include './4489Loader/4489_byteloader.s'

;  in:  a0 = start of compressed data
;       a1 = start of decompression buffer

;   call: zx0_decompress
zx0
                    include './zx0/unzx0_68000.s'

bootblockend

                   ;; dcb.b   1024-(bootblockend-bootblock_header)


; file table
; 0x400-0x5a0 = 0x1a0 (416 bytes)
filetable
