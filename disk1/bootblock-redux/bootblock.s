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


STACK_ADDRESS       EQU $1000
MFM_BUFFER          EQU $7d140      ; $80000-$2ec0 (required for 4489 loader)
LOAD_ADDRESS        EQU $73000      ; gives approx 40K compressed size for demo exe
DEMO_ADDRESS        EQU $2000       ; demo decrunch address

LOAD_LENGTH         EQU $4F24       ; size of compressed demo on disk
DEMO_OFFSET         EQU $d1fe4      ; start of file byte position on disk

        IFD TESTBOOT 
                    jmp     start_boot

test_mfm_buffer         dcb.w   $1760,$ffff
test_load_buffer        dcb.w   $a000,$1111
test_decrunch_buffer    dcb.w   $1c000,$2222
        ENDC 



            ; ------------- boot block header -------------
bootblock_header    dc.b    'DOS',0                     ; DiskType = 'DOS,0'
                    dc.l    $010C8415                   ; original checksum
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
                    lea     do_nothing_interrupt_handler(pc),a0
                    move.l  a0,$64.W
                    move.l  a0,$68.W
                    move.l  a0,$6c.W
                    move.l  a0,$70.W
                    move.l  a0,$74.W
                    move.l  a0,$78.W
                    move.l  a0,$7c.W 

load_compressed_demo
                    move.l  #$D1FE4,d0
                    move.l  #$4F18,d1
                    move.L  #0,d2
                    lea     $50000,a0
                    lea     MFM_BUFFER,a1
                    bsr     byteloader
                    tst.l   d0
                    bne.s   load_error

decrunch_demo
                    LEA     $50000,a0
                    LEA     $2000,a1
                    bsr     zx0_decompress
                    jmp     $2000

load_error
                    move.w  #$f00,$dff180
                    bra     load_error

do_nothing_interrupt_handler
                    RTE

wait_mouse
                    move.w  d0,$dff180
                    add.w   #1,d0
                    btst.b  #6,$bfe001
                    bne.s   wait_mouse
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
