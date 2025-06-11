;---------------------------------------------------------------------------------------
; -> d0.l  offset       (0-$dc000)
; -> d1.l  length       (0-$dc000)
; -> d2.l  drive        (0-3)
; -> a0.l  dst address  (anywhere)
; -> a1.l  mfm address  ($1760 words - sufficient as we snoop load)
;
; <- d0.l  == 0         (success)
; <- d0.l  != 0         (error)
;
; <- assume all other registers are trashed
;---------------------------------------------------------------------------------------
L000101aa               lea.l   $00bfd100,a4            ; a4 = CIAB PRB (Disk Control)
L000101b0               lea.l   L0001032e(pc),a5        ; a5 = status word?
L000101b4               lea.l   $00(a0,d1.L),a6         ; a6 = end of load address

L000101b8               moveq   #$78,d3                 ; d3 = Deselect All Drives
L000101ba               bsr.b   select_drive

L000101bc               and.b   #$7f,(a4)               ; Select /MTR (Drive Motor ON = 0)
                ; select drive 0-3
L000101c0               move.l  #$f7,d3                  
L000101c2               rol.b   d2,d3                   ; d3 = Select Drive Bit
L000101c4               and.b   d3,(a4)                 ; Select Drive

                ; calc start track and offset
L000101c6               divu.w  #$1600,d0               ; d0 = start track (offset / track size 5632 bytes)
L000101ca               move.w  d0,d1                   ; d1 low word = start track

L000101cc               move.w  #$7600,d0               ; d0.high = $76 = 118 (retry count)
L000101d0               swap.w  d0                      ; d0.low = start sector byte offset

                ; wait for disk ready or 28*300 raster lines
retry_read
L000101d2               moveq   #$1b,d7                 ; d7 = 27 + 1 (loop counter)
L000101d4               bsr.b   wait_300_rasters 
L000101d6               btst.b  #$0005,$0f01(a4)        ; Test bit 5 (/RDY) of $bfe001
L000101dc               dbeq.w  d7,L000101d4

L000101e0               cmpa.l  a0,a6                   ; has all data been loaded?
L000101e2               beq.b   loader_finished
L000101e4               moveq   #$06,d4                 ; select bottom head, step outwards
L000101e6               or.b    (a4),d4

L000101e8               move.w  (a5),d2                 ; d2 = current track
L000101ea               bpl.b   start_read              ; read track (d2 = current track)
                ; reset heads to track 0
                ; do read retry
L000101ec               add.l   #$01000000,d0           ; retry count
L000101f2               bmi.b   loader_finished         ; retry count exceeded
L000101f4               moveq   #$00,d2                 ; 
L000101f6               moveq   #$55,d7                 ; d7 = 85
L000101f8_loop          btst.b  #$0004,$0f01(a4)        ; test track 0
L000101fe               beq.b   start_read
L00010200               bsr.b   step_heads
L00010202               dbf.w   d7,L000101f8_loop

loader_finished            ; loader finished
                        suba.l  a0,a6
                        move.l  a6,d0               ; if all data loaded then d0 = 0 (success return code)
                        move.l #$f8,d3              ; deselect all drives
            ; select/deselect drives
            ; a4 = CIAB PRB (Disk Control)
            ; d3 = Drive DeSelect Bits?
select_drive
                        or.b    #$f9,(a4)           ; Deselect /MTR /SEL3 /SEL2 /SEL1 /SEL0 /STEP
                        and.b   #$87,(a4)           ; Select /SEL3 /SEL2/ SEL1 /SEL0 
                        or.b    d3,(a4)             ; Deselect Drives Specified in d3
                        rts



                ; step heads to desired track
                ; do disk read.
                ;
                ; d1 = desired track
                ; d2 = current track
                ; d4 = disk select bits
start_read
                        st.b    (a5)                ; (a5) = 11111111 $ff
                        move.w  d1,d3               ; d3 = start track
                        lsr.w   #$01,d2             ; d2 = current track  
                        lsr.w   #$01,d3             ; d3 = start cylinder
                        bcc.b   L00010224_bottom
                        subq.b  #$04,d4             ; /SIDE = 0 (TOP head)
L00010224_bottom        sub.w   d2,d3               ; d3 = cylinders to step
                        beq.b   read_track_set_side ; read track & set disk side
                        bmi.b   L0001022e_loop
                        subq.b  #$02,d4             ; /DIR = inwards
                        neg.w   d3
                ; head step loop
L0001022e_loop          bsr.b   step_heads
                        addq.w  #$01,d3             ; update current cylinder
                        bne.b   L0001022e_loop
                        bra.b   read_track          ; L0001026a


                ; toggle /STEP bit
step_heads
                        subq.b  #$01,d4
                        move.b  d4,(a4)
                        nop
                        addq.b  #$01,d4

set_disk_bits
                        move.b  d4,(a4)             ; used to set disk /SIDE during load or part of step heads above.

                ; wait for 300 raster lines as a delay
wait_300_rasters
                        move.w  #$012c,d6           ; d6 = 300 (loop counter + 1)
                        lea.l   $00dff024,a3
L0001024a_outer         move.b  -$001e(a3),d5       ; d5 = raster position
L0001024e_loop          cmp.b   -$001e(a3),d5       ; has raster changed?
                        beq.b   L0001024e_loop           ; wait for 1 raster line
                        dbf.w   d6,L0001024a_outer        ; loop for 300 raster lines
                        rts

reset_disk_dma
                        move.w  #$4000,(a3)             ; DISK DMA OFF
                        move.l  #$10027f00,$0078(a3)    ; INTREQ & ADKCON (Clear DSKSYNC & DSKBLK)
                        rts


                ; do read track
                ; a1 = mfm buffer
read_track_set_side
L00010268               bsr.b   set_disk_bits           ; set disk side - L0001023e

read_track
L0001026a               clr.l   $0010(a1)               ; clear long at offset 16-19 (mfm buffer)
L0001026e               move.w  #$8210,$0072(a3)        ; DMACON, enable DISK DMA
L00010274               bsr.b   reset_disk_dma          ; L0001025a
L00010276               move.w  #$9500,$007a(a3)        ; ADKCON
L0001027c               move.w  #$4489,$005a(a3)        ; DSKSYNC
L00010282               move.l  a1,-$0004(a3)           ; DSKPT (a1 = mfm buffer)
L00010286               move.w  #$9760,(a3)             ; read $1760 (5984 word) = $2ec0 (11968 bytes)
L0001028a               move.w  #$9760,(a3)
                ; wait for disk read
L0001028e               moveq   #$37,d7
L00010290               bsr.b   wait_300_rasters 
L00010292               tst.l   $0010(a1)
L00010296               dbne.w  d7,L00010290

L0001029a               beq.b   read_error              ; L00010306

L0001029c               movea.l a1,a2
L0001029e               bsr.b   L0001030a
L000102a0               swap.w  d3
L000102a2               cmp.b   d1,d3
L000102a4               bne.b   read_error              ; L00010306
L000102a6               rol.l   #$08,d3
L000102a8               tst.b   d3
L000102aa               bne.b   read_track                  ; L0001026a
L000102ac               moveq   #$37,d7
L000102ae               bsr.b   wait_300_rasters
L000102b0               btst.b  #$0001,-$0005(a3)
L000102b6               dbne.w  d7,L000102ae
L000102ba               beq.b   read_error              ; L00010306
L000102bc               bsr.b   reset_disk_dma              ; L0001025a
L000102be               move.w  #$0010,$0072(a3)
L000102c4               movea.l a1,a2
L000102c6               movea.l a1,a3
L000102c8               moveq   #$0a,d7
L000102ca               bsr.b   L0001030a
L000102cc               lea.l   $0028(a2),a2
L000102d0               bsr.b   L0001031c
L000102d2               move.l  d3,d5
L000102d4               moveq   #$7f,d6
L000102d6               move.l  $0200(a2),d4
L000102da               move.l  (a2)+,d3
L000102dc               bsr.b   L00010320
L000102de               move.l  d3,(a3)+
L000102e0               dbf.w   d6,L000102d6
L000102e4               tst.l   d5
L000102e6               bne.b   read_error              ; L00010306
L000102e8               lea.l   $0200(a2),a2
L000102ec               dbf.w   d7,L000102ca
L000102f0               move.w  d1,(a5)
L000102f2               addq.w  #$01,d1
L000102f4               lea.l   $00(a1,d0.W),a2
L000102f8               sub.w   #$1600,d0
L000102fc               cmpa.l  a6,a0
L000102fe               beq.b   read_error              ; L00010306
L00010300               move.b  (a2)+,(a0)+
L00010302               addq.w  #$01,d0
L00010304               bne.b   L000102fc

read_error
L00010306               bra.w   retry_read                  ; L000101d2

L0001030a               cmp.w   #$4489,(a2)+
L0001030e               bne.b   L0001030a
L00010310               cmp.w   #$4489,(a2)
L00010314               beq.b   L0001030a
L00010316               move.l  #$55555555,d2
L0001031c               movem.l (a2)+,d3-d4
L00010320               and.l   d2,d3
L00010322               and.l   d2,d4
L00010324               eor.l   d3,d5
L00010326               eor.l   d4,d5
L00010328               add.l   d3,d3
L0001032a               or.l    d4,d3
L0001032c               rts

L0001032e               dc.w    $ffff

