; ------------------------------------------------------------------------------------------------
; INFINITE DREAMS - 1 disked - music disk
; (c)1992-2025 - The Lunatics UK
;
; - Loads the disk file table.
; - Loads and displays the Title Picture from the disk.
; - Loads and executed the main program 'demo' from the disk.
;

                    section     bootloader,code_c
                    incdir      "include/"
                    include     "hw.i"


;TESTBOOT SET 1         ; Comment this to remove 'testboot' and build boot block for actual disk.


STACK_ADDRESS           EQU $1000       ; stack ptr address will grow down from start of boot block
BOOT_RELOCATE_ADDR      EQU $1000       ; absolute memory address to relocate the bootblock at.
MFM_BUFFER              EQU $7d140      ; $80000-$2ec0 RAW MFM Track Buffer (required for 4489 loader)
FILE_TABLE_ADDR         EQU $1500       ; absolute address for loading the disk file table at.
FILE_TABLE_OFFSET       EQU $400        ; disk offset to file table (directly following the bootblock)
FILE_TABLE_LENGTH       EQU $1a0        ; length of file table in bytes
LOAD_ADDRESS            EQU $50000      ; Address to load packed files into (loading screen/demo)
TPIC_START_ADDRESS      EQU $70000      ; title pic decrunch address.
DEMO_START_ADDRESS      EQU $2000       ; demo decrunch/execute address.
TPIC_COPPER_ADDR        EQU $3a000      ; absolute address of title picture copper list,
                                        ; stashed out of the way while loading and depacking demo $50000-$70000 and $2000-$1c000 
                                        ; so can continue to display image while loading and depacking demo.



        IFD TESTBOOT 
                    jmp     start_boot
        ENDC 




            ; ------------- boot block header -------------
bootblock_header    dc.b    'DOS',0                     ; DiskType = 'DOS,0'
                    dc.l    $00000000                   ; bootblock checksum value
                    dc.l    $00000001                   ; rootblock (normally 880 ($370) on a standard DOS Disk)
            ; ------------- boot block header -------------




            ; ------------------- code entry point --------------------
start_boot              lea     CUSTOM,a6 
                        move.w  #$7fff,d0
                        move.w  #$3fff,INTENA(a6)
                        move.w  d0,INTREQ(a6)
                        move.w  d0,INTREQ(a6)
                        move.w  d0,DMACON(a6)

                    ; move bootloader code to absolute address $1000 in memory.
relocate_bootloader:    lea     boot_loader(pc),a0
                        lea     BOOT_RELOCATE_ADDR,a1
                        move.w  #(bootblockend-boot_loader)/4,d7
.copy_loop              move.l  (a0)+,(a1)+
                        dbf     d7,.copy_loop
                        jmp     BOOT_RELOCATE_ADDR


            ; ---------------------------------------------------------
            ; ------------- relocated boot loader $00001000 -----------
            ;----------------------------------------------------------
boot_loader             lea     STACK_ADDRESS,A7
                        bsr     set_interrupt_vectors
                        bsr     load_file_table
                        bsr     load_title_picture
                        bsr     display_title_picture
                        bsr     fade_in_title_picture
                        bsr     load_demo
                        move.w  #250,d0
                        bsr     wait_frame_delay
                        bsr     fade_out_title_picture
                        jmp     DEMO_START_ADDRESS


            ; -------------- set interrupt vectors ----------------
set_interrupt_vectors   move.w  #$6,d7
                        lea     $64.w,a0
                        lea     do_nothing_handler(pc),a1
.set_vector_loop        move.l  a1,(a0)+
                        dbf     d7,.set_vector_loop
                        rts


            ; ------------------ load file table -------------------
load_file_table         move.l  #FILE_TABLE_OFFSET,d0               ; byte offset on disk
                        move.l  #FILE_TABLE_LENGTH,d1               ; file table byte length on disk
                        moveq   #0,d2                               ; select drive 0
                        lea.l   FILE_TABLE_ADDR,a0                  ; file table load address
                        lea.l   MFM_BUFFER,a1                       ; raw disk mfm track buffer
                        bsr     byteloader
                        rts


            ; ------------------- load title picture ------------------
load_title_picture      move.l  #'tpic',d0                          ; file id
                        lea     LOAD_ADDRESS,a0                     ; load address
                        lea     TPIC_START_ADDRESS,a1               ; decompress address
                        bsr     load_file
                        rts


            ; ------------- load and decompress demo -----------------
load_demo               move.l  #'demo',d0                          ; file id
                        lea     LOAD_ADDRESS,a0                     ; load address
                        lea     DEMO_START_ADDRESS,a1               ; decompress address
                        bsr     load_file
                        rts


            ; --------------- display title picture -----------------
            ; set screen parameters and create copper list for
            ; refreshing colours and bitplane pointers.
            ; would normally dma fetch, window, modulo and bplcon in 
            ; the copper but keeping the bootblock below 1024 bytes
            ; mean't not possible, so values poked directly.
display_title_picture
                    ; set title screen display parameters
                        lea     CUSTOM,a6
                        move.l  #$003800d0,DDFSTRT(a6)
                        move.l  #$2c812cc1,DIWSTRT(a6)
                        move.w  #$0000,BPLCON1(a6)
                        move.l  #$00000000,BPL1MOD(a6)

                    ; programmatically create copper list
                    ; start by setting copper colours (32 colour screen)
                        lea     TPIC_COPPER_ADDR,a0
                        move.w  #31,d7                          ; 32 colours
                        move.l  #$01800000,d0                   ; colour command (COLOR00), black colour value
.col_loop               move.l  d0,(a0)+                        ; poke command into copper list
                        add.l   #$00020000,d0                   ; increment colour register value
                        dbf     d7,.col_loop

                    ; set copper bitplane addresses
                        move.l  #TPIC_START_ADDRESS,d0
                        add.l   #$40,d0
                        move.w  #4,d7                           ; 5 bitplanes
                        move.w  #BPL1PTH,d1
.bpl_loop
                        swap.w  d0
                        move.w  d1,(a0)+                ; set bpl(x)pth register value
                        move.w  d0,(a0)+                ; high word of bitplane address ptr
                        add.w   #2,d1                   ; increment bpl(x)pt register value
                        swap.w  d0
                        move.w  d1,(a0)+                ; set bpl(x)ptl register value
                        move.w  d0,(a0)+                ; low word of bitplane address ptr
                        add.w   #2,d1                   ; increment bpl(x)pt register value
                        add.l   #$2800,d0               ; next bitplane ptr
                        dbf     d7,.bpl_loop

                    ; set 5 bitplane screen
                        move.l  #$01005200,(a0)+        ; BPLCON0, 5 bitplane screen plus colour burst
                        move.l  #$fffffffe,(a0)+        ; copper end wait instruction

                    ; set copper display for title screen
                        lea     TPIC_COPPER_ADDR,a0     
                        move.l  A0,COP1LC(A6)
                        move.w  #$8180,DMACON(A6)       ; enable copper DMA
                        rts


            ; ------------------ fade out title picture ---------------------
            ; overwrite image palette with black colour value for
            ; 32 colour entries. Then fall through to the fade in function
fade_out_title_picture  move.w  #32-1,d7
                        lea     TPIC_START_ADDRESS,a0       ; set 32 colour palette to black 
.loop                   move.w  #$0000,(a0)+
                        dbf     d7,.loop

            ; ------------------- fade in title picture --------------------
            ; fade in copper list colours to 32 colour entries stored at
            ; the start of the title picture image data.
fade_in_title_picture   move.w  #16-1,D7                    ; fade in 16 steps (16 colour levels per r,g,b)
.do_fade                bsr     raster_wait                 ; one fade per frame
                        move.l  d7,-(a7)
                        lea     TPIC_START_ADDRESS,a0       ; target colour palette ptr
                        lea     TPIC_COPPER_ADDR,a1         ; copper colour registers ptr
                        bsr     fade_copper_colours         ; do fade
                        move.l  (a7)+,d7    
                        dbf     d7,.do_fade
                        rts


            ; --------------------- raster wait --------------------------
            ; in: d0.w  number of frames to wait
wait_frame_delay        sub.w  #1,d0
.wait_loop              bsr     raster_wait
                        dbf     d0,.wait_loop
                        rts


            ; --------------------- raster wait --------------------------
raster_wait             lea     CUSTOM,a6    
                        cmp.b   #250,VHPOSR(A6)
                        bne.b   raster_wait
raster_wait_1           cmp.b   #251,VHPOSR(A6)
                        bne.b   raster_wait_1
                        rts


            ; ------------- do nothing interrupt handler -----------------
do_nothing_handler:     rte


            ; --------------- load and decompress file -------------------
            ; d0 = fileid
            ; a0 = load address ptr
            ; a1 = decompress address ptr
load_file               movem.l d0-d7/a0-a6,-(a7)               ; save all registers

                        move.w  #27-1,d7                        ; size of file table (26 entries)
                        lea     FILE_TABLE_ADDR,a3              ; disk file table, see infinitedreams.adf.filetable.txt

.find_file          ; find file id (d0) in file table
                        cmp.l   (a3),d0                         ; have we found the fileid?
                        beq     .load_file                      ; ...yes, then load it.
                        lea     $10(a3),a3                      ; try next file table entry
                        dbra    d7,.find_file                   ; check next table entry.

.load_error         ; load error
                        move.w  #$f00,$dff180                   ; turn screen red
                        bra.s   .load_error                     ; loop forever.

.load_file          ; load file from disk to address a0
                        move.l  $4(a3),d0                       ; disk byte offset
                        move.l  $c(a3),d1                       ; disk file length
                        moveq   #0,d2                           ; drive 0
                        lea     MFM_BUFFER,a1
                        bsr     byteloader
                        tst.l   d0                              ; test for load error
                        bne.s   .load_error                     ; some kinda disk error.

                        movem.l (a7),d0-d7/a0-a6                ; restore saved registers

                    ; decompress file to address a1
                    ; a0 = load address ptr
                    ; a1 = decompress address ptr
                        bsr     zx0_decompress                  ; decompress file

                        movem.l (a7)+,d0-d7/a0-a6               ; restore saved registers again...
                        rts


                ; ----------------------- fade copper colours ------------------------
                ; fade colours in copper list to a target list of colours
                ; in:   a0 = address of 32 colours (words)
                ;       a1 = address of copper colour registers set in copper list
fade_copper_colours
                    move.w  #32-1,d7
.fade_loop
                    move.w  (a0)+,d0                            ; palette colour to fade towards
                    move.w  2(a1),d2                            ; current colour from copper list
                    move.w  #$000f,d4                           ; initial r,g,b mask value
                    move.w  #$0001,d5                           ; initial r,g,b increment/decrement value 
                    move.w  #3-1,d6                             ; 3 colour components to fade in r,g,b
.fade_component
                    move.w  d0,d1                               ; d1 = working copy of palette colour
                    move.w  d2,d3                               ; d3 = working copy of current colour
                    and.w   d4,d1                               ; mask r,g, or b component
                    and.w   d4,d3                               ; mask r,g, ot b component
                    cmp.w   d1,d3                               ; is current colour component equal to, more than or less than the target colour
                    beq.s   .next_component                     ; is equal so no change required
                    bgt.s   .fade_down
.fade_up            ; make r,g, or b brighter
                    add.w   d5,d2                               ; fade colour component up (make r,g, or b brighter)
                    bra     .next_component
.fade_down          ; make r,g, or b darker
                    sub.w   d5,d2                               ; fade colour component down (make r,g, or b darker)
.next_component
                    rol.w   #4,d4                               ; rotate mask to next r,g,b component
                    rol.w   #4,d5                               ; rotate inecrement/decrement value to next r,g,b component
                    dbf.w   d6,.fade_component                  ; do next r,g or b component

.update_color       move.w  d2,2(a1)                            ; store faded colour back in copper list
                    addq.l  #4,a1                               ; update ptr to next copper instruction
                    dbf     d7,.fade_loop                       ; fade next colour in copper list

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
byteloader          include './4489Loader/4489_byteloader.s'


;  in:  a0 = start of compressed data
;       a1 = start of decompression buffer
;
;   call: zx0_decompress
zx0                 include './zx0/unzx0_68000.s'


; make pad bytes when assembling without TESTBOOT for real disk.
; Ensures the bootblock is 1024 bytes long. Will cause error if code
; exceeds 1024 bytes, which is a handy check.
bootblockend
        IFND TESTBOOT 
                ; ----------------------- pad bytes ------------------------
                ; pad bootblock file size to 1024 bytes
                dcb.b   1024-(bootblockend-bootblock_header)
        ENDC


