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
        ENDC 



                ; ------------- boot block header -------------
bootblock_header    dc.b    'DOS',0                     ; DiskType = 'DOS,0'
                    dc.l    $010C8415                   ; bootblock checksum value
                    dc.l    $00000001                   ; rootblock (normally 880 ($370) on a standard DOS Disk)



                ; ------------- code entry point ---------------
start_boot              lea     CUSTOM,a6 
                        move.w  #$7fff,d0
                        move.w  #$3fff,INTENA(a6)
                        move.w  d0,INTREQ(a6)
                        move.w  d0,INTREQ(a6)
                        move.w  d0,DMACON(a6)
copy_bootloader:
                        lea     boot_loader(pc),a0
                        lea     BOOT_RELOCATE_ADDR,a1
                        move.w  #(bootblockend-boot_loader)/4,d7
.copy_loop              move.l  (a0)+,(a1)+
                        dbf     d7,.copy_loop
                        jmp     BOOT_RELOCATE_ADDR


                ; ------------- relocated boot loader $00001000 -----------
boot_loader             lea   STACK_ADDRESS,A7

set_vectors         ; set interrupt vectors
                        move.w  #$6,d7
                        lea     $64.w,a0
                        lea     do_nothing_handler(pc),a1
.set_vector_loop        move.l  a1,(a0)+
                        dbf     d7,.set_vector_loop

load_file_table     ; load the file table
                        move.l  #FILE_TABLE_OFFSET,d0
                        move.l  #FILE_TABLE_LENGTH,d1
                        moveq   #0,d2
                        lea.l   FILE_TABLE_ADDR,a0                 ; file table load address
                        lea.l   MFM_BUFFER,a1
                        bsr     byteloader
                
load_title_screen   ; load and display title picture
                        move.l  #'tpic',d0
                        lea     LOAD_ADDRESS,a0
                        lea     TPIC_START_ADDRESS,a1
                        bsr     load_file
q
                    ; set title screen parameters
                        lea     CUSTOM,a6
                        move.l  #$003800d0,DDFSTRT(a6)
                        move.l  #$2c812cc1,DIWSTRT(a6)
                        move.w  #$0000,BPLCON1(a6)
                        move.l  #$00000000,BPL1MOD(a6)

                    ; set copper colours
                        lea     TPIC_COPPER_ADDR,a0
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

                        move.l  d7,-(a7)
                        lea     TPIC_COPPER_ADDR,a0
                        bsr     fade_out_titlescreen
                        move.l  (a7)+,d7

                        dbf     d7,.raster_wait_2

                        jmp     DEMO_START_ADDRESS

raster_wait             lea     CUSTOM,a6    
                        cmp.b   #$f0,VHPOSR(A6)
                        bne.b   raster_wait
                        rts

do_nothing_handler:     rte


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
                    rol.w   #4,d4
                    rol.w   #4,d5
                    dbf.w   d6,.fade_component

.update_color       
                    move.w  d2,2(a1)            ; store faded colour
                    addq.l  #4,a1
                    dbf     d7,.fade_loop

                    rts     



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

                dcb.b   1024-(bootblockend-bootblock_header)


