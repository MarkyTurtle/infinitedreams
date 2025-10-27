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



TESTBOOT SET 1                                              ; Comment this to remove 'testboot'


STACK_ADDRESS           EQU $1000       ; stack ptr address will grow down from start of boot block
BOOT_RELOCATE_ADDR      EQU $1000       ; absolute memory address to relocate the bootblock at.

MFM_BUFFER              EQU $7d140      ; $80000-$2ec0 RAW MFM Track Buffer (required for 4489 loader)

FILE_TABLE_OFFSET       EQU $400        ; disk offset to file table (directly following the bootblock)
FILE_TABLE_LENGTH       EQU $1a0        ; length of file table in bytes

LOAD_ADDRESS            EQU $50000      ; Address to load packed files into (loading screen/demo)
TPIC_START_ADDRESS      EQU $70000      ; title pic decrunch address.
DEMO_START_ADDRESS      EQU $2000       ; demo decrunch/execute address.

TPIC_COPPER_ADDR        EQU $3a000       ; absolute address of title pic copper list


;LOAD_LENGTH         EQU $5181       ; size of compressed demo on disk
;DEMO_OFFSET         EQU $D4872     ; start of file byte position on disk

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
start_boot          LEA.L   CUSTOM,a6                       ; $00dff000,A6
                    MOVE.W  #$7fff,d0
                    MOVE.W  #$3fff,INTENA(a6)
                    MOVE.W  d0,INTREQ(a6)
                    MOVE.w  d0,INTREQ(a6)
                    MOVE.W  d0,DMACON(a6)
copy_bootloader:
                    LEA     boot_loader,a0
                    LEA     $00001000,a1
                    MOVE.L  #(bootblockend-boot_loader)/4,d7
.copy_loop          MOVE.L  (a0)+,(a1)+
                    DBF     d7,.copy_loop
                    JMP     $00001000

boot_loader         LEA.L   STACK_ADDRESS,A7


                ; load the file table
load_file_table
                move.l #FILE_TABLE_OFFSET,d0
                move.l #FILE_TABLE_LENGTH,d1
                lea    filetable,a0
                lea    MFM_BUFFER,a1
                bsr    byteloader

                ; load and display title picture
load_title_screen
                move.l  #'tpic',d0
                lea     LOAD_ADDRESS,a0
                bsr     load_file
decrunch_tpic
                lea     LOAD_ADDRESS,a0
                lea     TPIC_START_ADDRESS,a1
                bsr     zx0_decompress

                ; display title screen
                lea     TPIC_COPPER_ADDR,a0
                move.l  #$00920038,(a0)+
                move.l  #$009400d0,(a0)+
                move.l  #$008e2C81,(a0)+
                move.l  #$00902cc1,(a0)+
                move.l  #$01020000,(a0)+
                move.l  #$01080000,(a0)+
                move.l  #$010a0000,(a0)+

                ; copper colours
                lea     copper_colours(pc),a1
                move.l  a0,(a1)                         ; store start of copper list colour address
                move.w  #31,d7                          ; 32 colours
                move.l  #$01800000,d0
.col_loop       move.l  d0,(a0)+
                add.l   #$00020000,d0
                dbf     d7,.col_loop

                ; copper bitplane addresses
                move.l  #TPIC_START_ADDRESS,d0
                add.l   #$40,d0
                move.w  #4,d7                           ; 5 bitplanes
                move.w  #$00e0,d1                       ; BPL1PTH
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
                lea     CUSTOM,a6
                MOVE.W  #$8180,DMACON(A6)
                LEA.L   TPIC_COPPER_ADDR,a0 
                MOVE.L  A0,COP1LC(A6)
                MOVE.W  COPJMP1(A6),D0

                ; fade in title pic
                move.w  #16,D7
.raster_wait_1  lea     CUSTOM,a6    
                cmp.b   #$f0,VHPOSR(A6)
                bne.b   .raster_wait_1

                move.l  d7,-(a7)
                lea     TPIC_START_ADDRESS,a0 
                lea     copper_colours(pc),a1
                move.l  (a1),a1
                bsr     fade_in_titlescreen
                move.l  (a7)+,d7

                dbf     d7,.raster_wait_1



                ; load and execute demo
load_compressed_demo
                move.l  #'demo',d0
                lea     LOAD_ADDRESS,a0
                bsr     load_file
decrunch_demo
                lea     LOAD_ADDRESS,a0
                lea     DEMO_START_ADDRESS,a1
                bsr     zx0_decompress


                ; fade out title pic
                move.w  #16,D7
.raster_wait_2  lea     CUSTOM,a6    
                cmp.b   #$f0,VHPOSR(A6)
                bne.b   .raster_wait_2

                bsr     fade_out_titlescreen

                dbf     d7,.raster_wait_2

                jmp     DEMO_START_ADDRESS





; d0 = fileid
; a0 = load address
load_file
                movem.l d0-d7/a0-a6,-(a7)
                move.w  #27-1,d7                        ; size of file table (26 entries)
                lea     filetable,a3
.find_file
                cmp.l   (a3),d0
                beq     .load
                lea     $10(a3),a3
                dbra    d7,.find_file
                bra.s   .load_error                     ; can't find file to load

.load
                move.l  $4(a3),d0
                move.l  $c(a3),d1
                move.L  #0,d2
                lea     MFM_BUFFER,a1
                bsr     byteloader
                tst.l   d0
                bne.s   .load_error                     ; some kinda disk error.
                movem.l (a7)+,d0-d7/a0-a6
                rts

                ; load error occurred
.load_error
                move.w  #$f00,$dff180
                bra.s   .load_error


                ; in:   a0 = address of 32 colours (words)
                ;       a1 = address of copper colour registers set in copper list
                ; ------------------------- fade in title screen ------------------------
fade_in_titlescreen move.w  #$001f,D6                           ; 32 colour screen display
                    add.l   #2,a1

                ; fade colour loop
.fade_loop          move.w  (A0)+,D0                            ; d0 = palette colour value
                ; fade blue colour component
.fade_blue          MOVE.W  D0,D1       
                    MOVE.W  (A1),D2                             ; d2 = current fade colour
                    MOVE.B  D2,D3
                    AND.B   #$0f,D1                             ; mask blue bits (src & dest)
                    AND.B   #$0f,D3
                    CMP.B   D1,D3
                    BEQ.B   .fade_green
                    ADD.B   #$01,$01(A1)
                ; fade green colour component
.fade_green         MOVE.B  D0,D1
                    MOVE.B  D2,D3
                    AND.B   #$f0,D1
                    AND.B   #$f0,D3
                    CMP.B   D1,D3
                    BEQ.B   .fade_red
                    ADD.B   #$10,$01(A1)
                ; fade red colour component
.fade_red           AND.W   #$0f00,D0
                    AND.W   #$0f00,D2
                    CMP.W   D0,D2
                    BEQ.B   .fade_next
                    ADD.B   #$01,$00(A1)
                ; fade next colour - loop
.fade_next          add.l   #$0000004,a1                   ; increase copper index to next colour value index
                    dbf.w   D6,.fade_loop
                    RTS 



            ; ------------------------- fade out title screen ------------------------
            ; in: a0 = copper colours address
fade_out_titlescreen
                lea     copper_colours(pc),a0
                move.l  (a0),a0
                    moveq  #$00000002,D5                   ; copper colour value index
                    moveq  #$0000001f,D6                   ; 32 colour screen
                ; fade colour loop
.fade_loop          move.w  (A0,D5.W),D0                ; d0 = copper colour value
                ; fade blue colour component
.fade_blue          MOVE.B  D0,D1
                    AND.B   #$0f,D1                         ; mask blue component
                    TST.B   D1
                    BEQ.B   .fade_green
                    SUB.B   #$01,$01(A0,D5.W)
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
.fade_next          ADD.W   #$0004,D5
                    DBF.W   D6,.fade_loop
                    RTS 


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
