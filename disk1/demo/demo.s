
        ; Display Memory Buffers
        ; ----------------------
        ; Top Logo Display      = 320 x 57          - 40 x 57  = 2280 (bytes per bitplane) - 4 bitplanes = 9120
        ; Text Typer Display    = 320 x 136 pixels  - 40 x 135 = 5440 (bytes per bitplane) - 1 bitplane  = 5440
        ; Insert Disk Display   = 320 x 7           - 40 x 7   = 280  (bytes per bitplane) - 1 bitplane  = 280
        ; Vector Logo Display 1 = 320 x 150 pixels  - 40 x 150 = 6000 (bytes per bitplane) - 1 bitplane  = 6000
        ; Vector Logo Display 2 = 320 x 150 pixels  - 40 x 150 = 6000 (bytes per bitplane) - 1 bitplane  = 6000        
        ; Scroller Display      = 704 x 32  pixels  - 88 x 32  = 2816 (bytes per bitplane) - 4 bitplanes = 11264
        ; Typer Font            =
        ; Scroller Font         =
        ;

                    section     demo,code_c
                    incdir      "include/"
                    include     "hw.i"


                ; menu_display_status_bits
MENU_DISP_FADE_IN               EQU     $0      ; bit 0 - 1 = Fade Menu In
MENU_DISP_FADE_OUT              EQU     $1      ; bit 1 - 1 = Fade Menu Out
MENU_DISP_CLEAR                 EQU     $6      ; bit 6 - 1 = Clear Menu Display
MENU_DISP_DRAW                  EQU     $7      ; bit 7 - 1 = Draw New Menu

                ; menu ptr list indexes
MENU_IDX_main_menu              EQU     $00     ; L0003A7E4 - index = $00
MENU_IDX_disk_1_menu            EQU     $04     ; L0003AAE1 - index = $04
MENU_IDX_disk_2_menu            EQU     $08     ; L0003AE0B - index = $08
MENU_IDX_disk_3_menu            EQU     $0c     ; L0003B108 - index = $0c
MENU_IDX_credits_menu           EQU     $10     ; L0003B405 - index = $10
MENU_IDX_greetings_1_menu       EQU     $14     ; L0003B702 - index = $14
MENU_IDX_greetings_2_menu       EQU     $18     ; L0003B9FF - index = $18
MENU_IDX_addresses_1_menu       EQU     $1c     ; L0003BCFC - index = $1c
MENU_IDX_addresses_2_menu       EQU     $20     ; L0003BFF9 - index = $20
MENU_IDX_addresses_3_menu       EQU     $24     ; L0003C2F6 - index = $24
MENU_IDX_addresses_4_menu       EQU     $28     ; L0003C5F3 - index = $28
MENU_IDX_addresses_5_menu       EQU     $2c     ; L0003C8F0 - index = $2c
MENU_IDX_addresses_6_menu       EQU     $30     ; L0003CBED - index = $30
MENU_IDX_pd_message_menu        EQU     $34     ; L0003CEEA - index = $34


TEST_BUILD SET 1                                              ; Comment this to remove 'testboot'


        IFD TEST_BUILD
STACK_ADDRESS   EQU     start_demo                      ; test stack address (start of program)
LOAD_BUFFER     EQU     load_buffer                     ; file load buffer
        ELSE
STACK_ADDRESS   EQU     $00080000                       ; original stack address
LOAD_BUFFER     EQU     $00040000                       ; file load buffer
        ENDC



                ; *********** Test build - disable interrupts & dma ***********
        IFD TEST_BUILD 
                                lea     CUSTOM,a6
                                move.w  #$3fff,INTENA(a6)
                                move.w  #$7fff,INTREQ(a6)
                                move.w  #$7fff,INTREQ(a6)
                                move.w  #$7fff,DMACON(a6)
                                jmp     start_demo
        ENDC 
                ; *********** Test build - disable interrupts & dma ***********



                ; ---------------- Start Demo/Music Disk -----------------
                ; Set stack to top of memory, try to detest aciton replay
                ; cartidges and eithe disable the freeze of reset/crash
                ; the computer.
                ;
start_demo      ; original address L00020000
                                LEA.L   STACK_ADDRESS,A7
                                BSR.W   init_system             ; L00020052
                                BSR.W   init_display            ; L00020080
                                BSR.W   do_fade_in_top_logo     ; L00020244
                                BRA.W   main_loop               ; L000202F6


                ; ------------- Initialise System -----------------
                ; Set up Level 3 Interrupt and kill DMA
init_system     ; original address L00020052
                                LEA.L   CUSTOM,A6
                                MOVE.W  #$7fff,D0
                                MOVE.W  D0,DMACON(A6)                           ; disable all DMA
                                MOVE.W  D0,INTREQ(A6)                           ; clear raised interrupt flags
                                MOVE.W  #$3fff,INTENA(A6)                       ; disable all interrupts
                                LEA.L   level_3_interrupt_handler(PC),A0 
                                MOVE.L  A0,$0000006c                            ; level 3 interrupt autovector
                                MOVE.W  #$8012,INTENA(A6)                       ; enable COPER & DSKBLK
                                RTS 



                ; ------------ Initialise Display ----------------
init_display    ; original address L00020080
                                BSR.W   init_vectorlogo_bitplanes       ; L00020100
                                BSR.W   init_menu_typer_bitplanes       ; L000200EA
                                BSR.W   init_top_logo_gfx               ; L00020116
                                BSR.W   init_scroller_text_display      ; L00020168
                                BSR.W   init_sprites                    ; L000201BA
                                BSR.W   init_insert_disk_bitplanes      ; L000200D4
                                LEA.L   copper_list(pc),a0              ; L00022CCA(PC),A0
                                MOVE.L  A0,COP1LC(A6)
                                MOVE.W  $00000088,D0                    ; mistake? Trap #02 vector? probably meant $dff088 (copjmp1 strobe)
                                MOVE.W  #$87ef,DMACON(A6)               ; BLTPRI,DMAEN,BPLEN,COPEN,BLTEN,SPREN,AUD0-3
                                MOVE.B  CUSTOM+JOY0DAT,mouse_y_value    ; mouse y initial value - $00dff00a,L00020882
                                RTS 


                ; ---------------- initialise insert disk bitplanes ------------------
                ; set a blank 'insert disk x' message at the bottom of the typer
init_insert_disk_bitplanes      ; original address L000200D4
                                MOVE.L  #insert_disk_blank_message,d0   ; #L00036348,D0
                                MOVE.W  D0,insertdisk_bplptl            ; L00022DE0
                                SWAP.W  D0
                                MOVE.W  D0,insertdisk_bplpth            ; L00022DDC
                                RTS 



                ; ------------------ initialise menu typer bitplanes ------------------
                ; set the copper bitplane ptrs for the menu screen typer text routine.
init_menu_typer_bitplanes       ; original address L000200EA
                                MOVE.L  #menu_typer_bitplane,d0         ; #L00022E82,D0
                                MOVE.W  D0,menu_bplptl                  ; L00022DD0
                                SWAP.W  D0
                                MOVE.W  D0,menu_bpltpth                 ; L00022DCC
                                RTS 


                ; ----------------- initialise vector logo bitplanes -----------------
init_vectorlogo_bitplanes       ; original address L00020100
                                MOVE.L  #vector_logo_buffer_1,D0
                                MOVE.W  D0,vector_bplptl                ; L00022DC8
                                SWAP.W  D0
                                MOVE.W  D0,vector_bplpth                ; L00022DC4
                                RTS 



                ; ------------------ initialise top logo gfx -------------------
                ; set copper bitplane ptrs for the top logo gfx
                ; bitplane size ($8e8 = 2280) 320x57
                ; 4 bitplanes / 16 colours
                ;
init_top_logo_gfx       ; original address L00020116
                                MOVE.L  #top_logo_gfx,d0                ; #L000249A2,D0 
                                MOVE.W  D0,toplogo_bpl1ptl              ; L00022D7C
                                SWAP.W  D0
                                MOVE.W  D0,toplogo_bpl1pth              ; L00022D78
                                MOVE.L  #top_logo_gfx+(40*57),D0
                                MOVE.W  D0,toplogo_bpl2ptl              ; L00022D84
                                SWAP.W  D0
                                MOVE.W  D0,toplogo_bpl2pth              ; L00022D80
                                MOVE.L  #top_logo_gfx+(80*57),D0
                                MOVE.W  D0,toplogo_bpl3ptl              ; L00022D8C
                                SWAP.W  D0
                                MOVE.W  D0,toplogo_bpl3pth              ; L00022D88
                                MOVE.L  #top_logo_gfx+(120*57),D0
                                MOVE.W  D0,toplogo_bpl4ptl              ; L00022D94
                                SWAP.W  D0
                                MOVE.W  D0,toplogo_bpl4pth              ; L00022D90
                                RTS 



                ; ---------------- initialise scroller text display ---------------
                ; Set the copper bitplanes for the display of the text scroller
                ; along the bottom of the screen display.
                ; The scroller is double buffered, so uses a strip of memory twice
                ; as wide as the display.
                ; The display is 44 bytes wide (the left most 32 pixels hidden behind
                ; the border to allow characters to scroll off the screen smoothly)
                ; The total buffer is 88 bytes wide and the font is 32 pixels high.
                ; Each plane = 88 x 32 = 2816 bytes.
                ; NB: the original code allocated way too much memory per bitplane,
                ; almost twice as much. This has now been fixed here.
                ;
init_scroller_text_display ; original address L00020168
                                MOVE.L  #scroll_text_bpl_0_start+6,D0
                                MOVE.W  D0,scrolltext_bpl1ptl                   ; L00022E5C
                                SWAP.W  D0
                                MOVE.W  D0,scrolltext_bpl1pth                   ; L00022E58
                                MOVE.L  #scroll_text_bpl_1_start+6,D0
                                MOVE.W  D0,scrolltext_bpl2ptl                   ; L00022E64
                                SWAP.W  D0
                                MOVE.W  D0,scrolltext_bpl2pth                   ; L00022E60
                                MOVE.L  #scroll_text_bpl_2_start+6,D0
                                MOVE.W  D0,scrolltext_bpl3ptl                   ; L00022E6C
                                SWAP.W  D0
                                MOVE.W  D0,scrolltext_bpl3pth                   ; L00022E68
                                MOVE.L  #scroll_text_bpl_3_start+6,D0
                                MOVE.W  D0,scrolltext_bpl4ptl                   ; L00022E74
                                SWAP.W  D0
                                MOVE.W  D0,scrolltext_bpl4pth                   ; L00022E70
                                RTS 



                ; --------------- initialise sprites ------------------
                ; Initialise copper list sprite pointers.
                ; Sprites 0 & Sprite 1 - used for the menu option selector arrows.
                ; Sprites 2-7 - unused
                ;
init_sprites    ; original address L000201BA
                                MOVE.L  #menu_sprite_left,D0            ; L00035FB8,D0
                                MOVE.W  D0,sprite_0_ptl                 ; L00022CF8
                                SWAP.W  D0
                                MOVE.W  D0,sprite_0_pth                 ; L00022CF4
                                MOVE.L  #menu_sprite_right,D0           ; L00035FDC,D0
                                MOVE.W  D0,sprite_1_ptl                 ; L00022D00
                                SWAP.W  D0
                                MOVE.W  D0,sprite_1_pth                 ; L00022CFC
                                MOVE.L  #$00000000,D0
                                MOVE.W  D0,sprite_2_pth                 ; L00022D08 - clear unused sprite ptrs.
                                MOVE.W  D0,sprite_2_ptl                 ; L00022D04
                                MOVE.W  D0,sprite_3_pth                 ; L00022D10
                                MOVE.W  D0,sprite_3_ptl                 ; L00022D0C
                                MOVE.W  D0,sprite_4_pth                 ; L00022D18
                                MOVE.W  D0,sprite_4_ptl                 ; L00022D14
                                MOVE.W  D0,sprite_5_pth                 ; L00022D20
                                MOVE.W  D0,sprite_5_ptl                 ; L00022D1C
                                MOVE.W  D0,sprite_6_pth                 ; L00022D28
                                MOVE.W  D0,sprite_6_ptl                 ; L00022D24
                                MOVE.W  D0,sprite_7_pth                 ; L00022D30
                                MOVE.W  D0,sprite_7_ptl                 ; L00022D2C
                                RTS 





                ; ------------------------- Do Fade In Top Logo ------------------------
                ; fades in the logo at the top of the screen 'Lunatics Infinite Dreams'
                ; loops 20 times.
                ;
do_fade_in_top_logo     ; original address L00020244
.fade_loop              ; original address L00020244
.wait_raster            ; original address L00020244
                                CMP.B   #$f0,$0006(A6)
                                BNE.B   .wait_raster                    ; L00020244
                                CMP.W   #$0014,top_logo_fade_count      ; L000202F4
                                BEQ.B   .exit
                                BSR.W   fade_in_top_logo                ; L00020268
                                ADD.W   #$0001,top_logo_fade_count      ; L000202F4
                                BRA.W   .fade_loop                      ; L00020244
.exit                           RTS 


fade_in_top_logo        ; original address L00020268
                                LEA.L   copper_top_logo_colors,a0       ; L00022D32,A0
                                LEA.L   top_logo_colours,a1             ; L000202D4,A1
                                MOVE.W  #$0002,D6
                                MOVE.W  #$000f,D7
.fade_loop
                                MOVE.W  $00(A0,D6.W),D0
                                MOVE.W  (A1)+,D2
                                MOVE.W  D0,D1
                                MOVE.W  D2,D3
.fade_blue
                                AND.W   #$000f,D1
                                AND.W   #$000f,D3
                                CMP.W   D1,D3
                                BEQ.W   .fade_green                     ; L0002029A 
                                ADD.W   #$0001,$00(A0,D6.W)
.fade_green
                                MOVE.W  D0,D1
                                MOVE.W  D2,D3
                                AND.W   #$00f0,D1
                                AND.W   #$00f0,D3
                                CMP.W   D1,D3
                                BEQ.W   .fade_red                       ; L000202B2 
                                ADD.W   #$0010,$00(A0,D6.W)
.fade_red
                                MOVE.W  D0,D1
                                MOVE.W  D2,D3
                                AND.W   #$0f00,D1
                                AND.W   #$0f00,D3
                                CMP.W   D1,D3
                                BEQ.W   .fade_next                      ; L000202CA 
                                ADD.W   #$0100,$00(A0,D6.W)
.fade_next
                                ADD.W   #$0004,D6
                                DBF.W   D7,.fade_loop                   ; L0002027C_loop
                                RTS 

top_logo_colours        ; original address L000202D4
                                dc.w    $0000,$0dde,$0ccd,$0aad,$099c,$0779,$0557,$0445
                                dc.w    $0222,$08DA,$03A6,$0083,$0FFF,$0F0F,$0F00,$0779 
top_logo_fade_count     ; original address L000202F4
                                dc.w    $0000   ; $0014




                ; ****************************************************************
                ; ***********                 MAIN LOOP                 **********
                ; ****************************************************************
main_loop       ; original address L000202F6
L000202F6                       BTST.B  #$0000,L000203A9
L000202FE                       BEQ.B   L0002033A
L00020300                       BTST.B  #$0000,L000203AB
L00020308                       BEQ.B   L00020316 
L0002030A                       BCLR.B  #$0000,L000203AB
L00020312                       BSR.W   music_off                               ; L00021C0A
L00020316                       BSR.W   L00021814
L0002031A                       BCLR.B  #$0000,L000203A9
L00020322                       BCLR.B  #$0000,menu_selection_status_bits       ; L000203A8
L0002032A                       BCLR.B  #$0001,menu_selection_status_bits       ; L000203A8
L00020332                       BSET.B  #$0001,L000203AB
L0002033A                       BTST.B  #$0000,menu_selection_status_bits       ; L000203A8
L00020342                       BNE.B   L00020362 
                        
.mouse_test             ; test mouse clicked
L00020344                       BTST.B  #$0006,$00bfe001
L0002034C                       BNE.B   L00020362 

.mouse_is_clicked       ; do menu item selected processing
L0002034E                       BSET.B  #$0000,menu_selection_status_bits               ; L000203A8
L00020356                       BSET.B  #$0001,menu_selection_status_bits               ; L000203A8
L0002035E                       BSR.W   do_menu_action                                  ; L0002088E

.mouse_not_clicked      ; test draw new menu (if required)
L00020362                       BTST.B  #MENU_DISP_DRAW,menu_display_status_bits        ; L000203AA
L0002036A                       BNE.B   L00020370 
L0002036C                       BSR.W   display_menu                                    ; L0002049C

                        ; test clear menu display (if required)
L00020370                       BTST.B  #MENU_DISP_CLEAR,menu_display_status_bits       ; L000203AA
L00020378                       BEQ.B   L0002037E 
L0002037A                       BSR.W   clear_menu_display                              ; L000207B6

                        ; test menu item selected/loading
L0002037E                       BTST.B  #$0001,L000203AB
L00020386                       BEQ.B   L000203A4

                        ; do menu item selected processing
L00020388                       BSR.W   L00021B96
L0002038C                       BSR.W   music_off                       ; L00021C0A
L00020390                       BSR.W   L00021B96
L00020394                       BCLR.B  #$0001,L000203AB
L0002039C                       BSET.B  #$0000,L000203AB
L000203A4                       BRA.W   main_loop                       ; L000202F6 


; state flags
menu_selection_status_bits      ; original address L000203A8
L000203A8                       dc.b    $00


L000203A9                       dc.b    $00
menu_display_status_bits        ; original address L000203AA
L000203AA                       dc.b    $00                     ; menu status bits 
                                                                ; bit - value - description
                                                                ;  0      1     do fade in menu display
                                                                ;  1      1     do fade out menu display
                                                                ;  6      1     clear menu display  
                                                                ;  7      1     menu display draw complete
L000203AB                       dc.b    $00
menu_ptr_index  ; original address L000203AC
L000203AC                       dc.b    $00                     ; index to the list of menu text pointers (multiple of 4 - longword list)
L000203AD                       dc.b    $00 





                ; ----------------------- Level 3 Interrupt Handler ----------------
                ; VBL and COPER interrupt handler routine, intended to be called
                ; ones per frame.
level_3_interrupt_handler
L000203AE                       MOVEM.L D0-D7/A0-A6,-(A7)
L000203B2                       MOVE.W  #$0010,$009c(A6)

L000203B8                       BSR.W   text_scroller                   ; Bottom screen text scroller - L0002152E
L000203BC                       BSR.W   swap_vector_logo_buffers        ; L000212F8
L000203C0                       BSR.W   clear_vector_logo_buffer        ; L000212D2
L000203C4                       BSR.W   spin_logo                       ; L000213EE
L000203C8                       BSR.W   calc_3d_perspective             ; L0002138E
L000203CC                       BSR.W   draw_logo_outline               ; L00021352
L000203D0                       BSR.W   calc_logo_lighting              ; L000213D8
L000203D4                       BSR.W   fill_vector_logo                ; L00021290

                        ; do fade in menu display (if required)
L000203D8                       BTST.B  #MENU_DISP_FADE_IN,menu_display_status_bits         ; L000203AA
L000203E0                       BEQ.B   L000203E6 
L000203E2                       BSR.W   fade_in_menu_display            ; L000205D4 - bit 0 = 1 - fade in menu display
                        ; do fade out menu display (if required)
L000203E6                       BTST.B  #MENU_DISP_FADE_OUT,menu_display_status_bits         ; L000203AA - bit 1 = 1 - fade out menu display
L000203EE                       BEQ.B   L000203F4                       
L000203F0                       BSR.W   fade_out_menu_display                                   ; L00020672 - bit 1 = 1 - menu routine

L000203F4                       BSR.W   L00020746

L000203F8                       BTST.B  #$0001,menu_selection_status_bits                       ; L000203A8
L00020400                       BNE.B   L00020406 

L00020402                       BSR.W   update_menu_selector_position                           ; L000207EA

L00020406                       BTST.B  #$0000,L000203AB
L0002040E                       BEQ.B   L00020420 
L00020410                       BSR.W   L00021C2C

L00020420                       ;BSR.W   L0002042A    
                                NOP
L00020424                       MOVEM.L (A7)+,D0-D7/A0-A6
L00020428                       RTE 

;L0002042a                       add.w   #$0001,L0002049a
;L00020432                       cmp.w   #$0014,L0002049a
;L0002043a                       bne.w   L0002048e
;L0002043e                       move.w  #$0000,L0002049a
;L00020446                       move.l  #$00000000,d7
;L0002044c                       move.b  $00bfea01,d7
;L00020452                       lsl.l   #$04,d7
;L00020454                       lsl.l   #$04,d7
;L00020456                       move.b  $00bfe901,d7
;L0002045c                       lsl.l   #$04,d7
;L0002045e                       lsl.l   #$04,d7
;L00020460                       move.b  $00bfe801,d7
;L00020466                       cmp.l   L00020496,d7
;L0002046c                       bne.w   L00020488 
;L00020470                       move.l  #$ffffffff,$00af0000
;L0002047a                       lea.l   L00020490,a0
;L00020480                       move.l  a0,$0080
;L00020484                       trap    #$00
;L00020486                       rts  
;L00020488                       move.l  d7,L00020496
;L0002048e                       rts 
;L00020490                       jmp $00fc0002

;00020496 0000 031b                or.b #$1b,d0
;0002049a 000e                     illegal


                ; ------------------------ display menu -------------------------
                ; Routine to display menu text on the screen. The menu is 
                ; displayed in a 1 bitplane screen, overlayed on a vector
                ; spinning logo.
                ; The text is displaed using the processor (which is odd for me)
                ; i'd normally use the blitter for gfx operations.
display_menu    ; original address L0002049C
L0002049C                       LEA.L   menu_typer_bitplane,a0
L000204A2                       LEA.L   menu_font_gfx,a2                        ; L000245F2      
L000204A8                       LEA.L   menu_ptrs,a3
L000204AE                       MOVE.W  menu_ptr_index,d0                       ; L000203AC,D0 ; menu ptr index (multiple of 4)
L000204B4                       LEA.L   $00(A3,D0.W),A3
L000204B8                       MOVEA.L (A3),A3
L000204BA                       MOVE.W  #$002c,D7
L000204BE                       MOVE.W  #$0010,D6

L000204C2_loop                          MOVE.L  #$00000000,D0
L000204C4                               MOVE.L  #$00000000,D1
L000204C6                               MOVE.L  #$00000000,D2
L000204C8                               MOVE.L  #$00000000,D3
L000204CA                               MOVE.L  #$00000000,D4
L000204CC                               MOVE.B  (A3)+,D0
L000204CE                               SUB.B   #$20,D0                         ; space char
L000204D2                               LSL.B   #$00000001,D0
L000204D4                               LEA.L   $00(A2,D0.W),A4                 ; a4 = char gfx ptr
L000204D8                               MOVE.W  L000205D0,D1
L000204DE                               MOVE.W  D1,D3
L000204E0                               LSR.W   #$00000003,D1
L000204E2                               MOVE.W  D1,D4
L000204E4                               LSL.W   #$00000003,D4
L000204E6                               SUB.W   D4,D3
L000204E8                               BTST.L  #$0000,D1
L000204EC                               BEQ.W   L000204FC 
L000204F0                               BCLR.L  #$0000,D1
L000204F4                               MOVE.W  #$0008,D2
L000204F8                               BRA.W   L00020500 
L000204FC                               MOVE.W  #$0000,D2
L00020500                               LEA.L   $00(A0,D1.W),A1
L00020504                               MOVE.W  L000205D2,D1
L0002050A                               LEA.L   $00(A1,D1.W),A1
L0002050E                               MOVE.L  $0000(A4),D0                    ; char line 1
L00020512                               AND.L   #$ffff0000,D0
L00020518                               ROR.L   D2,D0
L0002051A                               ROR.L   D3,D0
L0002051C                               OR.L    D0,$0000(A1)
L00020520                               MOVE.L  $0076(A4),D0                    ; char line 2
L00020524                               AND.L   #$ffff0000,D0
L0002052A                               ROR.L   D2,D0
L0002052C                               ROR.L   D3,D0
L0002052E                               OR.L    D0,$0028(A1)
L00020532                               MOVE.L  $00ec(A4),D0                    ; char line 3
L00020536                               AND.L   #$ffff0000,D0
L0002053C                               ROR.L   D2,D0
L0002053E                               ROR.L   D3,D0
L00020540                               OR.L    D0,$0050(A1)
L00020544                               MOVE.L  $0162(A4),D0                    ; char line 4
L00020548                               AND.L   #$ffff0000,D0
L0002054E                               ROR.L   D2,D0
L00020550                               ROR.L   D3,D0
L00020552                               OR.L    D0,$0078(A1)
L00020556                               MOVE.L  $01d8(A4),D0                    ; char line 5
L0002055A                               AND.L   #$ffff0000,D0
L00020560                               ROR.L   D2,D0
L00020562                               ROR.L   D3,D0
L00020564                               OR.L    D0,$00a0(A1)
L00020568                               MOVE.L  $024e(A4),D0                    ; char line 6
L0002056C                               AND.L   #$ffff0000,D0
L00020572                               ROR.L   D2,D0
L00020574                               ROR.L   D3,D0
L00020576                               OR.L    D0,$00c8(A1)
L0002057A                               MOVE.L  $02c4(A4),D0                    ; char line 7
L0002057E                               AND.L   #$ffff0000,D0
L00020584                               ROR.L   D2,D0
L00020586                               ROR.L   D3,D0
L00020588                               OR.L    D0,$00f0(A1)

L0002058C                               ADD.W   #$00000007,L000205D0
L00020592                               DBF.W   D7,L000204C2_loop

L00020596                       MOVE.W  #$0000,L000205D0
L0002059E                       ADD.W   #$0140,L000205D2
L000205A6                       MOVE.W  #$002c,D7
L000205AA                       DBF.W   D6,L000204C2_loop

L000205AE                       BSET.B  #MENU_DISP_DRAW,menu_display_status_bits                ; L000203AA ; bit 7 - 1 = menu typer completed
L000205B6                       BSET.B  #MENU_DISP_FADE_IN,menu_display_status_bits             ; L000203AA ; bit 0 - 1 = do fade in menu display
L000205BE                       MOVE.W  #$0000,L000205D0
L000205C6                       MOVE.W  #$0000,L000205D2
L000205CE                       RTS 

L000205D0                       dc.w    $0000 
L000205D2                       dc.w    $0000


fade_in_menu_display    ; original address L000205D4
L000205D4                       CMP.B   #$03,fade_speed_counter         ; L00020743
L000205DC                       BNE.W   L00020668 
L000205E0                       MOVE.B  #$00,fade_speed_counter         ; L00020743
L000205E8                       LEA.L   L00022DAE,A0
L000205EE                       MOVE.W  $0002(A0),D0
L000205F2                       MOVE.W  D0,D1
L000205F4                       AND.W   #$000f,D1
L000205F8                       CMP.W   #$000f,D1
L000205FC                       BEQ.B   L00020604 
L000205FE                       ADD.W   #$0001,$0002(A0)
L00020604                       MOVE.W  D0,D1
L00020606                       AND.W   #$00f0,D1
L0002060A                       CMP.W   #$00f0,D1
L0002060E                       BEQ.B   L00020616 
L00020610                       ADD.W   #$0010,$0002(A0)
L00020616                       MOVE.W  D0,D1
L00020618                       AND.W   #$0f00,D1
L0002061C                       CMP.W   #$0f00,D1
L00020620                       BEQ.B   L00020628 
L00020622                       ADD.W   #$0100,$0002(A0)
L00020628                       MOVE.W  L00020744,D0
L0002062E                       CMP.W   #$0fff,D0
L00020632                       BEQ.B   L0002063C 
L00020634                       ADD.W   #$0111,L00020744
L0002063C                       ADD.B   #$01,L00020742
L00020644                       CMP.B   #$10,L00020742
L0002064C                       BNE.B   L00020666 
L0002064E                       BCLR.B  #MENU_DISP_FADE_IN,menu_display_status_bits             ; set fade in completed (clear bit 0) - L000203AA
L00020656                       BCLR.B  #$0000,menu_selection_status_bits                       ; L000203A8
L0002065E                       MOVE.W  #$0000,L00020742
L00020666                       RTS 

L00020668                       ADD.B   #$01,fade_speed_counter                 ; L00020743
L00020670                       RTS 


fade_out_menu_display   ; original address L00020672
L00020672                       CMP.B   #$03,fade_speed_counter                 ; L00020743
L0002067A                       BNE.W   L00020738 
L0002067E                       MOVE.B  #$00,fade_speed_counter                 ; L00020743
L00020686                       LEA.L   L00022DAE,A0
L0002068C                       MOVE.W  $0002(A0),D0
L00020690                       MOVE.W  D0,D1
L00020692                       AND.W   #$000f,D1
L00020696                       CMP.W   #$0002,D1
L0002069A                       BEQ.B   L000206A2 
L0002069C                       SUB.W   #$0001,$0002(A0)
L000206A2                       MOVE.W  D0,D1
L000206A4                       AND.W   #$00f0,D1
L000206A8                       CMP.W   #$0000,D1
L000206AC                       BEQ.B   L000206B4 
L000206AE                       SUB.W   #$0010,$0002(A0)
L000206B4                       AND.W   #$0f00,D0
L000206B8                       CMP.W   #$0000,D0
L000206BC                       BEQ.B   L000206C4 
L000206BE                       SUB.W   #$0100,$0002(A0)
L000206C4                       MOVE.W  L00020744,D0
L000206CA                       CMP.W   #$0000,D0
L000206CE                       BEQ.B   L000206D8 
L000206D0                       SUB.W   #$0111,L00020744
L000206D8                       ADD.B   #$01,L00020742
L000206E0                       CMP.B   #$10,L00020742
L000206E8                       BNE.B   L00020736 

L000206EA                       BCLR.B  #MENU_DISP_FADE_OUT,menu_display_status_bits            ; set fade out completed (clear bit 1) - L000203AA
L000206F2                       BSET.B  #MENU_DISP_CLEAR,menu_display_status_bits               ; (set bit 6) - L000203AA
L000206FA                       BCLR.B  #$0001,menu_selection_status_bits                       ; L000203A8
L00020702                       MOVE.W  #$0000,L00020742
L0002070A                       LEA.L   menu_sprite_left,A0             ; L00035FB8,A0
L00020710                       MOVE.B  L0002088A,$0001(A0)
L00020718                       MOVE.B  L0002088B,$0003(A0)
L00020720                       LEA.L   menu_sprite_right,A0            ; L00035FDC,A0
L00020726                       MOVE.B  L0002088C,$0001(A0)
L0002072E                       MOVE.B  L0002088D,$0003(A0)
L00020736                       RTS 

L00020738                       ADD.B   #$01,fade_speed_counter         ; L00020743
L00020740                       RTS 


L00020742                       dc.b $00
fade_speed_counter      ; original address L00020743
L00020743                       dc.b $00 
L00020744                       dc.b $00,$00


L00020746                       LEA.L   L00022DAC,A0
L0002074C                       LEA.L   L00022DAE,A1
L00020752                       MOVE.L  #$00000000,D4
L00020754                       MOVE.W  (A0),D0
L00020756                       MOVE.W  D0,D2
L00020758                       MOVE.W  L00020744,D1
L0002075E                       MOVE.W  D1,D3
L00020760                       AND.W   #$000f,D2
L00020764                       AND.W   #$000f,D3
L00020768                       ADD.W   D2,D3
L0002076A                       CMP.W   #$000f,D3
L0002076E                       BLE.W   L00020776 
L00020772                       MOVE.W  #$000f,D3
L00020776                       OR.W    D3,D4
L00020778                       MOVE.W  D0,D2
L0002077A                       MOVE.W  D1,D3
L0002077C                       AND.W   #$00f0,D2
L00020780                       AND.W   #$00f0,D3
L00020784                       ADD.W   D2,D3
L00020786                       CMP.W   #$00f0,D3
L0002078A                       BLE.W   L00020792 
L0002078E                       MOVE.W  #$00f0,D3
L00020792                       OR.W    D3,D4
L00020794                       MOVE.W  D0,D2
L00020796                       MOVE.W  D1,D3
L00020798                       AND.W   #$0f00,D2
L0002079C                       AND.W   #$0f00,D3
L000207A0                       ADD.W   D2,D3
L000207A2                       CMP.W   #$0f00,D3
L000207A6                       BLE.W   L000207AE 
L000207AA                       MOVE.W  #$0f00,D3
L000207AE                       OR.W    D3,D4
L000207B0                       MOVE.W  D4,$0006(A1)
L000207B4                       RTS 


                ; -------------------- clear menu display ---------------------
                ; uses the processor to clear the 1 bitplane 320x135 pixel
                ; menu display.
clear_menu_display      ; original address L000207B6
L000207B6                       LEA.L   menu_typer_bitplane,a0          ; L00022E82,A0
L000207BC                       MOVE.W  #$0009,D7                       ; loop counter 9+1
L000207C0                       MOVE.W  #$0087,D6                       ; loop counter 135+1
L000207C4                       MOVE.L  #$00000000,D0
L000207CA_loop                  MOVE.L  D0,(A0)+
L000207CC                       DBF.W   D7,L000207CA_loop
L000207D0                       MOVE.W  #$0009,D7
L000207D4                       DBF.W   D6,L000207CA_loop
L000207D8                       BCLR.B  #MENU_DISP_DRAW,menu_display_status_bits        ; L000203AA ; flag - menu cleared status bits
L000207E0                       BCLR.B  #MENU_DISP_CLEAR,menu_display_status_bits       ; L000203AA ; flag - menu cleared status bits
L000207E8                       RTS 




                ; ----------------- Update Menu Selector Position -------------------
                ; Get mouse input and position the left/right arrows that are used
                ; to select the menu items from the on-screen menu selections.
update_menu_selector_position   ; original address L000207EA
                                MOVE.L  #$00000000,D0
                                MOVE.L  #$00000000,D1
                                MOVE.B  CUSTOM+JOY0DAT,D0                       ; $00dff00a,D0
                                MOVE.B  mouse_y_value,d1                        ; L00020882,D1
                                MOVE.B  D0,mouse_y_value                        ; L00020882
                                SUB.W   D0,D1
                                CMP.W   #$ff80,D1                               ; compare -128
                                BLT.B   underflow_y_wrap                        ; L00020816 
                                CMP.W   #$007f,D1                               ; compare +127
                                BGT.B   overflow_y_wrap                         ; L00020810 
                                BRA.B   update_menu_selector_y                  ; L0002081A 

                        ; mouse counter overflow +ve
overflow_y_wrap         ; original address L00020810
                                SUB.W   #$0100,D1                               ; wrap mouse y value
                                BRA.B   update_menu_selector_y                  ; L0002081A 

                        ; mouse counter underflow -ve
underflow_y_wrap        ; original address L00020816
                                ADD.W   #$0100,D1                               ; wrap mouse y value

update_menu_selector_y  ; original address L0002081A
                                ASR.W   #$00000001,D1
                                NEG.W   D1
                                ADD.W   D1,menu_selector_y                      ; L00020888
                                MOVE.W  menu_selector_y,D0                      ; L00020888,D0
                                MOVE.W  menu_selector_min_y,D1                  ; L00020884,D1
                                CMP.W   D1,D0
                                BLT.W   clamp_min_y                             ; L00020850 
                                MOVE.W  menu_selector_max_y,D1                  ; L00020886,D1
                                CMP.W   D1,D0
                                BGT.W   clamp_max_y                             ; L00020844 
                                BRA.B   set_menu_selector_sprite_y              ; L0002085A 

clamp_max_y             ; original address L00020844
                                MOVE.W  menu_selector_max_y,menu_selector_y     ; clamp mouse y limit
                                BRA.B   set_menu_selector_sprite_y              ; L0002085A 

clamp_min_y             ; original address L00020850
                                MOVE.W  menu_selector_min_y,menu_selector_y     ; clamp mouse y limit

set_menu_selector_sprite_y ; original address L0002085A
                                LEA.L   menu_sprite_left,A0                     ; left sprite
                                LEA.L   menu_sprite_right,A1                    ; right sprite
                                MOVE.W  menu_selector_y,D0                      ; L00020888,D0
                                ADD.W   #$0079,D0                               ; sprite y offset to 1st menu item
                                MOVE.B  D0,(A0)
                                MOVE.B  D0,(A1)
                                ADD.B   #$07,D0
                                MOVE.B  D0,$0002(A0)
                                MOVE.B  D0,$0002(A1)
                                RTS 

                                even
mouse_y_value           ; original address L00020882
                                dc.b    $00
                                even
menu_selector_min_y     ; original address L00020884
                                dc.w    $0020 
menu_selector_max_y     ; original address L00020886
                                dc.w    $0050
menu_selector_y         ; original address L00020888
                                dc.w    $0000


L0002088A                       dc.b    $6c
L0002088B                       dc.b    $01
L0002088C                       dc.b    $a9
L0002088D                       dc.b    $01 



do_menu_action                  ; original address L0002088E
L0002088E                       CMP.W   #MENU_IDX_main_menu,menu_ptr_index              ; L000203AC
L00020896                       BEQ.W   do_main_menu_actions                            ; L00020938 

L0002089A                       CMP.W   #MENU_IDX_disk_1_menu,menu_ptr_index            ; L000203AC
L000208A2                       BEQ.W   do_disk_1_menu_actions                          ; L00020CFC

L000208A6                       CMP.W   #MENU_IDX_disk_2_menu,menu_ptr_index            ; L000203AC
L000208AE                       BEQ.W   do_disk_2_menu_actions                          ; L00020D3C 

L000208B2                       CMP.W   #MENU_IDX_disk_3_menu,menu_ptr_index            ; L000203AC
L000208BA                       BEQ.W   do_disk_3_menu_actions                          ; L00020DAC 

L000208BE                       CMP.W   #MENU_IDX_credits_menu,menu_ptr_index           ; L000203AC
L000208C6                       BEQ.W   display_menu_menu                               ; L0002124E

L000208CA                       CMP.W   #MENU_IDX_greetings_1_menu,menu_ptr_index       ; L000203AC
L000208D2                       BEQ.W   do_greetings_1_menu_actions                     ; L00020E1C 

L000208D6                       CMP.W   #MENU_IDX_greetings_2_menu,menu_ptr_index       ; L000203AC
L000208DE                       BEQ.W   display_menu_menu                               ; L0002124E
 
L000208E2                       CMP.W   #MENU_IDX_addresses_1_menu,menu_ptr_index       ; L000203AC
L000208EA                       BEQ.W   display_address_2_menu                          ; L00020B5E 

L000208EE                       CMP.W   #MENU_IDX_addresses_2_menu,menu_ptr_index       ; L000203AC
L000208F6                       BEQ.W   display_address_3_menu                          ; L00020BA0 

L000208FA                       CMP.W   #MENU_IDX_addresses_3_menu,menu_ptr_index       ; L000203AC
L00020902                       BEQ.W   display_address_4_menu                          ; L00020BE2 

L00020906                       CMP.W   #MENU_IDX_addresses_4_menu,menu_ptr_index       ; L000203AC
L0002090E                       BEQ.W   display_address_5_menu                          ; L00020C24 

L00020912                       CMP.W   #MENU_IDX_addresses_5_menu,menu_ptr_index       ; L000203AC
L0002091A                       BEQ.W   display_address_6_menu                          ; L00020C66 

L0002091E                       CMP.W   #MENU_IDX_addresses_6_menu,menu_ptr_index       ; L000203AC
L00020926                       BEQ.W   display_menu_menu                               ; L0002124E 

L0002092A                       CMP.W   #MENU_IDX_pd_message_menu,menu_ptr_index        ; L000203AC
L00020932                       BEQ.W   display_menu_menu                               ; L0002124E

L00020936                       RTS 



do_main_menu_actions
L00020938                       CMP.W   #$0024,menu_selector_y          ; L00020888
L00020940                       BLE.W   L00020990 
L00020944                       CMP.W   #$002c,menu_selector_y          ; L00020888
L0002094C                       BLE.W   L000209D2 
L00020950                       CMP.W   #$0034,menu_selector_y          ; L00020888
L00020958                       BLE.W   L00020A14 
L0002095C                       CMP.W   #$003c,menu_selector_y          ; L00020888
L00020964                       BLE.W   L00020A56 
L00020968                       CMP.W   #$0044,menu_selector_y          ; L00020888
L00020970                       BLE.W   L00020A98 
L00020974                       CMP.W   #$004c,menu_selector_y          ; L00020888
L0002097C                       BLE.W   L00020B1C 
L00020980                       CMP.W   #$0054,menu_selector_y          ; L00020888
L00020988                       BLE.W   L00020CA8 
L0002098C                       BRA.W   L00020CEA 


L00020990                       BSET.B  #MENU_DISP_FADE_OUT,menu_display_status_bits    ; L000203AA
L00020998                       MOVE.W  #$0030,menu_selector_min_y                      ; L00020884
L000209A0                       MOVE.W  #$0058,menu_selector_max_y                      ; L00020886
L000209A8                       MOVE.W  #MENU_IDX_disk_1_menu,menu_ptr_index            ; L000203AC
L000209B0                       MOVE.B  #$42,L0002088A
L000209B8                       MOVE.B  #$01,L0002088B
L000209C0                       MOVE.B  #$d6,L0002088C
L000209C8                       MOVE.B  #$01,L0002088D
L000209D0                       RTS 

L000209D2                       BSET.B  #MENU_DISP_FADE_OUT,menu_display_status_bits    ; L000203AA
L000209DA                       MOVE.W  #$0028,menu_selector_min_y                      ; L00020884
L000209E2                       MOVE.W  #$0070,menu_selector_max_y                      ; L00020886
L000209EA                       MOVE.W  #MENU_IDX_disk_2_menu,menu_ptr_index            ; L000203AC
L000209F2                       MOVE.B  #$42,L0002088A
L000209FA                       MOVE.B  #$01,L0002088B
L00020A02                       MOVE.B  #$d6,L0002088C
L00020A0A                       MOVE.B  #$01,L0002088D
L00020A12                       RTS 

L00020A14                       BSET.B  #MENU_DISP_FADE_OUT,menu_display_status_bits    ; L000203AA
L00020A1C                       MOVE.W  #$0028,menu_selector_min_y                      ; L00020884
L00020A24                       MOVE.W  #$0070,menu_selector_max_y                      ; L00020886
L00020A2C                       MOVE.W  #MENU_IDX_disk_3_menu,menu_ptr_index            ; L000203AC
L00020A34                       MOVE.B  #$42,L0002088A
L00020A3C                       MOVE.B  #$01,L0002088B
L00020A44                       MOVE.B  #$d6,L0002088C
L00020A4C                       MOVE.B  #$01,L0002088D
L00020A54                       RTS 

L00020A56                       BSET.B  #MENU_DISP_FADE_OUT,menu_display_status_bits    ; L000203AA
L00020A5E                       MOVE.W  #$0070,menu_selector_min_y                      ; L00020884
L00020A66                       MOVE.W  #$0070,menu_selector_max_y                      ; L00020886
L00020A6E                       MOVE.W  #MENU_IDX_credits_menu,menu_ptr_index           ; L000203AC
L00020A76                       MOVE.B  #$42,L0002088A
L00020A7E                       MOVE.B  #$01,L0002088B
L00020A86                       MOVE.B  #$d6,L0002088C
L00020A8E                       MOVE.B  #$01,L0002088D
L00020A96                       RTS 

L00020A98                       BSET.B  #MENU_DISP_FADE_OUT,menu_display_status_bits    ; L000203AA
L00020AA0                       MOVE.W  #$0068,menu_selector_min_y                      ; L00020884
L00020AA8                       MOVE.W  #$0070,menu_selector_max_y                      ; L00020886
L00020AB0                       MOVE.W  #MENU_IDX_greetings_1_menu,menu_ptr_index       ; L000203AC
L00020AB8                       MOVE.B  #$42,L0002088A
L00020AC0                       MOVE.B  #$01,L0002088B
L00020AC8                       MOVE.B  #$d6,L0002088C
L00020AD0                       MOVE.B  #$01,L0002088D
L00020AD8                       RTS 

L00020ADA                       BSET.B  #MENU_DISP_FADE_OUT,menu_display_status_bits    ; L000203AA
L00020AE2                       MOVE.W  #$0070,menu_selector_min_y                      ; L00020884
L00020AEA                       MOVE.W  #$0070,menu_selector_max_y                      ; L00020886
L00020AF2                       MOVE.W  #MENU_IDX_greetings_2_menu,menu_ptr_index       ; L000203AC
L00020AFA                       MOVE.B  #$42,L0002088A
L00020B02                       MOVE.B  #$01,L0002088B
L00020B0A                       MOVE.B  #$d6,L0002088C
L00020B12                       MOVE.B  #$01,L0002088D
L00020B1A                       RTS 

L00020B1C                       BSET.B  #MENU_DISP_FADE_OUT,menu_display_status_bits    ; L000203AA
L00020B24                       MOVE.W  #$0070,menu_selector_min_y                      ; L00020884
L00020B2C                       MOVE.W  #$0070,menu_selector_max_y                      ; L00020886
L00020B34                       MOVE.W  #MENU_IDX_addresses_1_menu,menu_ptr_index       ; L000203AC
L00020B3C                       MOVE.B  #$42,L0002088A
L00020B44                       MOVE.B  #$01,L0002088B
L00020B4C                       MOVE.B  #$d6,L0002088C
L00020B54                       MOVE.B  #$01,L0002088D
L00020B5C                       RTS 

display_address_2_menu
L00020B5E                       BSET.B  #MENU_DISP_FADE_OUT,menu_display_status_bits    ; L000203AA
L00020B66                       MOVE.W  #$0070,menu_selector_min_y                      ; L00020884
L00020B6E                       MOVE.W  #$0070,menu_selector_max_y                      ; L00020886
L00020B76                       MOVE.W  #MENU_IDX_addresses_2_menu,menu_ptr_index       ; L000203AC
L00020B7E                       MOVE.B  #$42,L0002088A
L00020B86                       MOVE.B  #$01,L0002088B
L00020B8E                       MOVE.B  #$d6,L0002088C
L00020B96                       MOVE.B  #$01,L0002088D
L00020B9E                       RTS 

display_address_3_menu
L00020BA0                       BSET.B  #MENU_DISP_FADE_OUT,menu_display_status_bits    ; L000203AA
L00020BA8                       MOVE.W  #$0070,menu_selector_min_y                      ; L00020884
L00020BB0                       MOVE.W  #$0070,menu_selector_max_y                      ; L00020886
L00020BB8                       MOVE.W  #MENU_IDX_addresses_3_menu,menu_ptr_index       ; L000203AC
L00020BC0                       MOVE.B  #$42,L0002088A
L00020BC8                       MOVE.B  #$01,L0002088B
L00020BD0                       MOVE.B  #$d6,L0002088C
L00020BD8                       MOVE.B  #$01,L0002088D
L00020BE0                       RTS 

display_address_4_menu
L00020BE2                       BSET.B  #MENU_DISP_FADE_OUT,menu_display_status_bits    ; L000203AA
L00020BEA                       MOVE.W  #$0070,menu_selector_min_y                      ; L00020884
L00020BF2                       MOVE.W  #$0070,menu_selector_max_y                      ; L00020886
L00020BFA                       MOVE.W  #MENU_IDX_addresses_4_menu,menu_ptr_index       ; L000203AC
L00020C02                       MOVE.B  #$42,L0002088A
L00020C0A                       MOVE.B  #$01,L0002088B
L00020C12                       MOVE.B  #$d6,L0002088C
L00020C1A                       MOVE.B  #$01,L0002088D
L00020C22                       RTS 

display_address_5_menu
L00020C24                       BSET.B  #MENU_DISP_FADE_OUT,menu_display_status_bits    ; L000203AA
L00020C2C                       MOVE.W  #$0070,menu_selector_min_y                      ; L00020884
L00020C34                       MOVE.W  #$0070,menu_selector_max_y                      ; L00020886
L00020C3C                       MOVE.W  #MENU_IDX_addresses_5_menu,menu_ptr_index       ; L000203AC
L00020C44                       MOVE.B  #$42,L0002088A
L00020C4C                       MOVE.B  #$01,L0002088B
L00020C54                       MOVE.B  #$d6,L0002088C
L00020C5C                       MOVE.B  #$01,L0002088D
L00020C64                       RTS 

display_address_6_menu
L00020C66                       BSET.B  #MENU_DISP_FADE_OUT,menu_display_status_bits    ; L000203AA
L00020C6E                       MOVE.W  #$0070,menu_selector_min_y                      ; L00020884
L00020C76                       MOVE.W  #$0070,menu_selector_max_y                      ; L00020886
L00020C7E                       MOVE.W  #MENU_IDX_addresses_6_menu,menu_ptr_index       ; L000203AC
L00020C86                       MOVE.B  #$42,L0002088A
L00020C8E                       MOVE.B  #$01,L0002088B
L00020C96                       MOVE.B  #$d6,L0002088C
L00020C9E                       MOVE.B  #$01,L0002088D
L00020CA6                       RTS 

L00020CA8                       BSET.B  #MENU_DISP_FADE_OUT,menu_display_status_bits    ; L000203AA
L00020CB0                       MOVE.W  #$0078,menu_selector_min_y                      ; L00020884
L00020CB8                       MOVE.W  #$0078,menu_selector_max_y                      ; L00020886
L00020CC0                       MOVE.W  #MENU_IDX_pd_message_menu,menu_ptr_index        ; L000203AC 
L00020CC8                       MOVE.B  #$42,L0002088A
L00020CD0                       MOVE.B  #$01,L0002088B
L00020CD8                       MOVE.B  #$d6,L0002088C
L00020CE0                       MOVE.B  #$01,L0002088D
L00020CE8                       RTS 

L00020CEA                       BCLR.B  #$0000,menu_selection_status_bits               ; L000203A8
L00020CF2                       BCLR.B  #$0001,menu_selection_status_bits               ; L000203A8
L00020CFA                       RTS 

do_disk_1_menu_actions
L00020CFC                       CMP.W   #$0034,menu_selector_y          ; L00020888
L00020D04                       BLE.W   L00020E2C 
L00020D08                       CMP.W   #$003c,menu_selector_y          ; L00020888
L00020D10                       BLE.W   L00020E5A 
L00020D14                       CMP.W   #$0044,menu_selector_y          ; L00020888
L00020D1C                       BLE.W   L00020E88 
L00020D20                       CMP.W   #$004c,menu_selector_y          ; L00020888
L00020D28                       BLE.W   L00020EB6 
L00020D2C                       CMP.W   #$0054,menu_selector_y          ; L00020888
L00020D34                       BLE.W   L00020EE4 
L00020D38                       BRA.W   display_menu_menu               ; L0002124E 

do_disk_2_menu_actions
L00020D3C                       CMP.W   #$002c,menu_selector_y          ; L00020888
L00020D44                       BLE.W   L00021082 
L00020D48                       CMP.W   #$0034,menu_selector_y          ; L00020888
L00020D50                       BLE.W   L00020F40 
L00020D54                       CMP.W   #$003c,menu_selector_y          ; L00020888
L00020D5C                       BLE.W   L00020F6E 
L00020D60                       CMP.W   #$0044,menu_selector_y          ; L00020888
L00020D68                       BLE.W   L00020F9C 
L00020D6C                       CMP.W   #$004c,menu_selector_y          ; L00020888
L00020D74                       BLE.W   L00020FCA 
L00020D78                       CMP.W   #$0054,menu_selector_y          ; L00020888
L00020D80                       BLE.W   L00020FF8 
L00020D84                       CMP.W   #$005c,menu_selector_y          ; L00020888
L00020D8C                       BLE.W   L00021026 
L00020D90                       CMP.W   #$0064,menu_selector_y          ; L00020888
L00020D98                       BLE.W   L00021054 
L00020D9C                       CMP.W   #$006c,menu_selector_y          ; L00020888
L00020DA4                       BLE.W   L00020F12 
L00020DA8                       BRA.W   display_menu_menu               ; L0002124E 

do_disk_3_menu_actions
L00020DAC                       CMP.W   #$002c,menu_selector_y          ; L00020888
L00020DB4                       BLE.W   L000210B0 
L00020DB8                       CMP.W   #$0034,menu_selector_y          ; L00020888
L00020DC0                       BLE.W   L000210DE 
L00020DC4                       CMP.W   #$003c,menu_selector_y          ; L00020888
L00020DCC                       BLE.W   L0002110C 
L00020DD0                       CMP.W   #$0044,menu_selector_y          ; L00020888
L00020DD8                       BLE.W   L0002113A 
L00020DDC                       CMP.W   #$004c,menu_selector_y          ; L00020888
L00020DE4                       BLE.W   L00021168 
L00020DE8                       CMP.W   #$0054,menu_selector_y          ; L00020888
L00020DF0                       BLE.W   L00021196 
L00020DF4                       CMP.W   #$005c,menu_selector_y          ; L00020888
L00020DFC                       BLE.W   L000211C4 
L00020E00                       CMP.W   #$0064,menu_selector_y          ; L00020888
L00020E08                       BLE.W   L000211F2 
L00020E0C                       CMP.W   #$006c,menu_selector_y          ; L00020888
L00020E14                       BLE.W   L00021220 
L00020E18                       BRA.W   display_menu_menu               ; L0002124E 

do_greetings_1_menu_actions
L00020E1C                       CMP.W   #$006c,menu_selector_y          ; L00020888
L00020E24                       BLE.W   L00020ADA 
L00020E28                       BRA.W   display_menu_menu               ; L0002124E 

L00020E2C                       BSET.B  #$0000,L000203A9
L00020E34                       MOVE.W  #$008e,L00021B86
L00020E3C                       MOVE.W  #$0011,L00021B88
L00020E44                       MOVE.L  #LOAD_BUFFER,L00021B8A            ; address?
L00020E4E                       MOVE.L  #$00000001,disk_number          ; L00021B92             ; disk number
L00020E58                       RTS 

L00020E5A                       BSET.B  #$0000,L000203A9
L00020E62                       MOVE.W  #$005c,L00021B86
L00020E6A                       MOVE.W  #$0015,L00021B88
L00020E72                       MOVE.L  #LOAD_BUFFER,L00021B8A
L00020E7C                       MOVE.L  #$00000001,disk_number          ; L00021B92            ; disk number
L00020E86                       RTS 

L00020E88                       BSET.B  #$0000,L000203A9
L00020E90                       MOVE.W  #$003b,L00021B86
L00020E98                       MOVE.W  #$001f,L00021B88
L00020EA0                       MOVE.L  #LOAD_BUFFER,L00021B8A
L00020EAA                       MOVE.L  #$00000001,disk_number          ; L00021B92            ; disk number
L00020EB4                       RTS 

L00020EB6                       BSET.B  #$0000,L000203A9
L00020EBE                       MOVE.W  #$0073,L00021B86
L00020EC6                       MOVE.W  #$0019,L00021B88
L00020ECE                       MOVE.L  #LOAD_BUFFER,L00021B8A
L00020ED8                       MOVE.L  #$00000001,disk_number          ; L00021B92            ; disk number
L00020EE2                       RTS 

L00020EE4                       BSET.B  #$0000,L000203A9
L00020EEC                       MOVE.W  #$001b,L00021B86
L00020EF4                       MOVE.W  #$001e,L00021B88
L00020EFC                       MOVE.L  #LOAD_BUFFER,L00021B8A
L00020F06                       MOVE.L  #$00000001,disk_number          ; L00021B92            ; disk number
L00020F10                       RTS 

L00020F12                       BSET.B  #$0000,L000203A9
L00020F1A                       MOVE.W  #$0001,L00021B86
L00020F22                       MOVE.W  #$0009,L00021B88
L00020F2A                       MOVE.L  #LOAD_BUFFER,L00021B8A
L00020F34                       MOVE.L  #$00000002,disk_number          ; L00021B92            ; disk number
L00020F3E                       RTS 

L00020F40                       BSET.B  #$0000,L000203A9
L00020F48                       MOVE.W  #$007e,L00021B86
L00020F50                       MOVE.W  #$000e,L00021B88
L00020F58                       MOVE.L  #LOAD_BUFFER,L00021B8A
L00020F62                       MOVE.L  #$00000002,disk_number          ; L00021B92            ; disk number 
L00020F6C                       RTS 

L00020F6E                       BSET.B  #$0000,L000203A9
L00020F76                       MOVE.W  #$0070,L00021B86
L00020F7E                       MOVE.W  #$000c,L00021B88
L00020F86                       MOVE.L  #LOAD_BUFFER,L00021B8A
L00020F90                       MOVE.L  #$00000002,disk_number          ; L00021B92            ; disk number
L00020F9A                       RTS 

L00020F9C                       BSET.B  #$0000,L000203A9
L00020FA4                       MOVE.W  #$000c,L00021B86
L00020FAC                       MOVE.W  #$000d,L00021B88
L00020FB4                       MOVE.L  #LOAD_BUFFER,L00021B8A
L00020FBE                       MOVE.L  #$00000002,disk_number          ; L00021B92            ; disk number
L00020FC8                       RTS 

L00020FCA                       BSET.B  #$0000,L000203A9
L00020FD2                       MOVE.W  #$0055,L00021B86
L00020FDA                       MOVE.W  #$0019,L00021B88
L00020FE2                       MOVE.L  #LOAD_BUFFER,L00021B8A
L00020FEC                       MOVE.L  #$00000002,disk_number          ; L00021B92            ; disk number
L00020FF6                       RTS 

L00020FF8                       BSET.B  #$0000,L000203A9
L00021000                       MOVE.W  #$0040,L00021B86
L00021008                       MOVE.W  #$0013,L00021B88
L00021010                       MOVE.L  #LOAD_BUFFER,L00021B8A
L0002101A                       MOVE.L  #$00000002,disk_number          ; L00021B92            ; disk number
L00021024                       RTS 

L00021026                       BSET.B  #$0000,L000203A9
L0002102E                       MOVE.W  #$001b,L00021B86
L00021036                       MOVE.W  #$0010,L00021B88
L0002103E                       MOVE.L  #LOAD_BUFFER,L00021B8A
L00021048                       MOVE.L  #$00000002,disk_number          ; L00021B92            ; disk number
L00021052                       RTS 

L00021054                       BSET.B  #$0000,L000203A9
L0002105C                       MOVE.W  #$002d,L00021B86
L00021064                       MOVE.W  #$0011,L00021B88
L0002106C                       MOVE.L  #LOAD_BUFFER,L00021B8A
L00021076                       MOVE.L  #$00000002,disk_number          ; L00021B92            ; disk number
L00021080                       RTS 

L00021082                       BSET.B  #$0000,L000203A9
L0002108A                       MOVE.W  #$008e,L00021B86
L00021092                       MOVE.W  #$0011,L00021B88
L0002109A                       MOVE.L  #LOAD_BUFFER,L00021B8A
L000210A4                       MOVE.L  #$00000002,disk_number          ; L00021B92            ; disk number
L000210AE                       RTS 

L000210B0                       BSET.B  #$0000,L000203A9
L000210B8                       MOVE.W  #$008d,L00021B86
L000210C0                       MOVE.W  #$0012,L00021B88
L000210C8                       MOVE.L  #LOAD_BUFFER,L00021B8A
L000210D2                       MOVE.L  #$00000003,disk_number          ; L00021B92            ; disk number
L000210DC                       RTS 

L000210DE                       BSET.B  #$0000,L000203A9
L000210E6                       MOVE.W  #$0002,L00021B86
L000210EE                       MOVE.W  #$0011,L00021B88
L000210F6                       MOVE.L  #LOAD_BUFFER,L00021B8A
L00021100                       MOVE.L  #$00000003,disk_number          ; L00021B92            ; disk number
L0002110A                       RTS 

L0002110C                       BSET.B  #$0000,L000203A9
L00021114                       MOVE.W  #$007d,L00021B86
L0002111C                       MOVE.W  #$000e,L00021B88
L00021124                       MOVE.L  #LOAD_BUFFER,L00021B8A
L0002112E                       MOVE.L  #$00000003,disk_number          ; L00021B92            ; disk number
L00021138                       RTS 

L0002113A                       BSET.B  #$0000,L000203A9
L00021142                       MOVE.W  #$006f,L00021B86
L0002114A                       MOVE.W  #$000c,L00021B88
L00021152                       MOVE.L  #LOAD_BUFFER,L00021B8A
L0002115C                       MOVE.L  #$00000003,disk_number          ; L00021B92            ; disk number
L00021166                       RTS 

L00021168                       BSET.B  #$0000,L000203A9
L00021170                       MOVE.W  #$0052,L00021B86
L00021178                       MOVE.W  #$001b,L00021B88
L00021180                       MOVE.L  #LOAD_BUFFER,L00021B8A
L0002118A                       MOVE.L  #$00000003,disk_number          ; L00021B92            ; disk number
L00021194                       RTS 

L00021196                       BSET.B  #$0000,L000203A9
L0002119E                       MOVE.W  #$0043,L00021B86
L000211A6                       MOVE.W  #$000d,L00021B88
L000211AE                       MOVE.L  #LOAD_BUFFER,L00021B8A
L000211B8                       MOVE.L  #$00000003,disk_number          ; L00021B92            ; disk number
L000211C2                       RTS 

L000211C4                       BSET.B  #$0000,L000203A9
L000211CC                       MOVE.W  #$0015,L00021B86
L000211D4                       MOVE.W  #$000d,L00021B88
L000211DC                       MOVE.L  #LOAD_BUFFER,L00021B8A
L000211E6                       MOVE.L  #$00000003,disk_number          ; L00021B92            ; disk number
L000211F0                       RTS 

L000211F2                       BSET.B  #$0000,L000203A9
L000211FA                       MOVE.W  #$0035,L00021B86
L00021202                       MOVE.W  #$000c,L00021B88
L0002120A                       MOVE.L  #LOAD_BUFFER,L00021B8A
L00021214                       MOVE.L  #$00000003,disk_number          ; L00021B92            ; disk number
L0002121E                       RTS 

L00021220                       BSET.B  #$0000,L000203A9
L00021228                       MOVE.W  #$0024,L00021B86
L00021230                       MOVE.W  #$000f,L00021B88
L00021238                       MOVE.L  #LOAD_BUFFER,L00021B8A
L00021242                       MOVE.L  #$00000003,disk_number          ; L00021B92            ; disk number
L0002124C                       RTS 


display_menu_menu
L0002124E                       BSET.B  #MENU_DISP_FADE_OUT,menu_display_status_bits    ; L000203AA
L00021256                       MOVE.W  #$0020,menu_selector_min_y                      ; L00020884
L0002125E                       MOVE.W  #$0050,menu_selector_max_y                      ; L00020886
L00021266                       MOVE.W  #MENU_IDX_main_menu,menu_ptr_index              ; L000203AC
L0002126E                       MOVE.B  #$6c,L0002088A
L00021276                       MOVE.B  #$01,L0002088B
L0002127E                       MOVE.B  #$a9,L0002088C
L00021286                       MOVE.B  #$01,L0002088D
L0002128E                       RTS 


                                ; --------------------- fill vector logo --------------------
                                ; IN:
                                ;       A6 = $dff000 - custom base
fill_vector_logo        ; original address L00021290
                                BTST.B  #$6,DMACONR(A6)                 ; blitter busy (bit 14) - should be bit 6 (testing hi-byte)
                                BNE.B   fill_vector_logo                ; L00021290 
                                MOVE.L  #$ffffffff,BLTAFWM(A6)         ; first & last word masks
                                MOVE.W  #$09f0,BLTCON0(A6)              ; channels A & D, $f0 = logic function
                                MOVE.W  #$000a,BLTCON1(A6)              ; DESC Mode, Inclusive Fill Mode
                                MOVE.W  #$0000,BLTDMOD(A6)
                                MOVE.W  #$0000,BLTAMOD(A6)
                                MOVE.L  vector_logo_buffer_ptr,d0 
                                ADD.W   #$12c0,D0                       ; add 4800 (120 raster lines)
                                MOVE.L  D0,BLTAPT(A6)                   ; set A channel src gfx
                                MOVE.L  D0,BLTDPT(A6)                   ; set D channel dest gfx
                                MOVE.W  #$1b14,BLTSIZE(A6)              ; start blit bits 0-5 = width (20 words), bits 6-15 = height (108 lines high)
                                RTS 


clear_vector_logo_buffer        ; original address L000212D2
                                BTST.B  #6,DMACONR(A6)                          ; blit wait (bit 14) - bit 6 of hi-byte (14-8)
                                BNE.B   clear_vector_logo_buffer        
                                MOVE.L  #$01000000,BLTCON0(A6)                  ; enable channel D, no minterms
                                MOVE.L  vector_logo_buffer_ptr,BLTDPT(A6)
                                MOVE.W  #$0000,BLTDMOD(A6)
                                MOVE.W  #$1e54,BLTSIZE(A6)                      ; 20 words wide (bits 0-5), height = 121 (bits 6-15)
                                RTS 



                ; ----------------- swap vector logo buffers ---------------------
                ; The spinning vector logo in the background is double buffered.
                ; This routine swaps the buffers, so the logo can be redrawn
                ; in the background and then swapped for display.
swap_vector_logo_buffers        ; original address L000212F8
                                CMP.W   #$0000,vector_logo_swap_flag
                                BNE.B   _display_vector_buffer_2         
_display_vector_buffer_1        ; original address L00021302
                                MOVE.L  #vector_logo_buffer_1,D0
                                MOVE.W  D0,vector_bplptl
                                SWAP.W  D0
                                MOVE.W  D0,vector_bplpth
                                MOVE.W  #$0001,vector_logo_swap_flag
                                MOVE.L  #vector_logo_buffer_2,vector_logo_buffer_ptr
                                RTS 
_display_vector_buffer_2        ; original address L0002132A
                                MOVE.L  #vector_logo_buffer_2,D0
                                MOVE.W  D0,vector_bplptl
                                SWAP.W  D0
                                MOVE.W  D0,vector_bplpth
                                MOVE.W  #$0000,vector_logo_swap_flag
                                MOVE.L  #vector_logo_buffer_1,vector_logo_buffer_ptr
                                RTS 


draw_logo_outline
L00021352                       MOVE.W  #$0028,D4
L00021356                       LEA.L   L0003A690,A5
L0002135C                       LEA.L   L0003A2A6,A4
L00021362                       MOVE.W  L0003A68E,D7
L00021368                       LEA.L   vector_logo_buffer_ptr,a2       ; L000365CA,A2
L0002136E                       MOVEM.W (A5)+,D5-D6
L00021372                       LEA.L   $00(A4,D5.W),A3
L00021376                       MOVEM.W (A3)+,D0-D1
L0002137A                       LEA.L   $00(A4,D6.W),A3
L0002137E                       MOVEM.W (A3)+,D2-D3
L00021382                       MOVEA.L (A2),A0
L00021384                       BSR.W   L00021464
L00021388                       DBF.W   D7,L0002136E 
L0002138C                       RTS 


calc_3d_perspective     ; original address L0002138E
L0002138E                       MOVE.W  L00039D1E,D7
L00021394                       LEA.L   L00039EBE,A2
L0002139A                       LEA.L   L0003A2A6,A1
L000213A0                       MOVE.L  #$00000000,D3
L000213A2                       MOVE.W  #$00a0,D4
L000213A6                       MOVE.W  #$0046,D5
L000213AA                       MOVE.L  #$00000008,D6
L000213AC                       MOVEM.W (A2)+,D0-D2
L000213B0                       CMP.W   D3,D2
L000213B2                       BNE.B   L000213BC 
L000213B4                       MOVE.L  #$00000000,D0
L000213B6                       MOVE.L  #$00000000,D1
L000213B8                       MOVE.L  #$00000000,D2
L000213BA                       BRA.B   L000213CA 
L000213BC                       EXT.L   D1
L000213BE                       EXT.L   D2
L000213C0                       EXT.L   D0
L000213C2                       ASL.W   D6,D0
L000213C4                       ASL.W   D6,D1
L000213C6                       DIVS.W  D2,D0
L000213C8                       DIVS.W  D2,D1
L000213CA                       ADD.W   D4,D0
L000213CC                       ADD.W   D5,D1
L000213CE                       MOVE.W  D0,(A1)+
L000213D0                       MOVE.W  D1,(A1)+
L000213D2                       DBF.W   D7,L000213AC 
L000213D6                       RTS 


calc_logo_lighting    ; original address L000213D8
L000213D8                       MOVE.W  L000213EC(PC),D0
L000213DC                       LEA.L   L00039A4E,A0
L000213E2                       MOVE.W  $00(A0,D0.W),L00022DAC
L000213EA                       RTS 

L000213EC                       dc.w    $0000 



spin_logo       ; original address L000213EE
L000213EE                       ADD.W   #$00000004,L000213EC            ; rotation value?
L000213F4                       CMP.W   #$02ce,L000213EC                ; 718/2 = 359 (degrees)
L000213FC                       BLE.B   L00021406 
L000213FE                       MOVE.W  #$0000,L000213EC
L00021406                       LEA.L   L00039D20,A0
L0002140C                       LEA.L   L000394AE,A1
L00021412                       LEA.L   L0003977E,A2
L00021418                       LEA.L   L00039EBE,A3
L0002141E                       MOVE.W  L00039D1E,D7
L00021424                       MOVE.W  L000213EC(PC),D6
L00021428                       MOVE.L  #$00000008,D3
L0002142A                       MOVEM.W (A0)+,D0-D2
L0002142E                       MOVE.W  D0,D4
L00021430                       MOVE.W  D2,D5
L00021432                       MULS.W  $00(A2,D6.W),D4
L00021436                       MULS.W  $00(A1,D6.W),D5
L0002143A                       SUB.L   D5,D4
L0002143C                       ASR.L   D3,D4
L0002143E                       MOVE.W  D4,(A3)
L00021440                       MOVE.W  D0,D4
L00021442                       MOVE.W  D2,D5
L00021444                       MULS.W  $00(A1,D6.W),D4
L00021448                       MULS.W  $00(A2,D6.W),D5
L0002144C                       ADD.L   D5,D4
L0002144E                       ASR.L   D3,D4
L00021450                       MOVEM.W D1/D4,$0002(A3)
L00021456                       ADD.W   #$01f8,$0004(A3)
L0002145C                       ADDA.L  #$00000006,A3
L0002145E                       DBF.W   D7,L0002142A 
L00021462                       RTS 


; line draw routine?
L00021464                       CMP.W   D1,D3
L00021466                       BEQ.W   L00021528 
L0002146A                       BGT.B   L00021470 
L0002146C                       EXG.L   D0,D2
L0002146E                       EXG.L   D1,D3
L00021470                       ADD.W   #$00000001,D1
L00021472                       SUB.W   D0,D2
L00021474                       BMI.B   L00021498 
L00021476                       SUB.W   D1,D3
L00021478                       BMI.B   L00021488 
L0002147A                       CMP.W   D3,D2
L0002147C                       BMI.B   L00021482 
L0002147E                       MOVE.L  #$00000013,D5
L00021480                       BRA.B   L000214BA 

L00021482                       EXG.L   D2,D3
L00021484                       MOVE.L  #$00000003,D5
L00021486                       BRA.B   L000214BA 

L00021488                       NOT.W   D3
L0002148A                       CMP.W   D3,D2
L0002148C                       BMI.B   L00021492 
L0002148E                       MOVE.L  #$0000001b,D5
L00021490                       BRA.B   L000214BA 

L00021492                       EXG.L   D2,D3
L00021494                       MOVE.L  #$00000007,D5
L00021496                       BRA.B   L000214BA 

L00021498                       NOT.W   D2
L0002149A                       SUB.W   D1,D3
L0002149C                       BMI.B   L000214AC 
L0002149E                       CMP.W   D3,D2
L000214A0                       BMI.B   L000214A6 
L000214A2                       MOVE.L  #$00000017,D5
L000214A4                       BRA.B   L000214BA 

L000214A6                       EXG.L   D2,D3
L000214A8                       MOVE.L  #$0000000b,D5
L000214AA                       BRA.B   L000214BA 

L000214AC                       NOT.W   D3
L000214AE                       CMP.W   D3,D2
L000214B0                       BMI.B   L000214D6 
L000214B2                       MOVE.L  #$0000001f,D5
L000214B4                       BRA.B   L000214BA 

L000214B6                       EXG.L   D2,D3
L000214B8                       MOVE.L  #$0000000f,D5
L000214BA                       MULU.W  D4,D1
L000214BC                       ROR.L   #$00000004,D0
L000214BE                       ADD.W   D0,D0
L000214C0                       ADDA.L  D1,A0
L000214C2                       ADDA.W  D0,A0
L000214C4                       SWAP.W  D0
L000214C6                       OR.W    #$0b4a,D0
L000214CA                       LSL.W   #$00000002,D3
L000214CC                       ADD.W   D2,D2
L000214CE                       MOVE.W  D2,D1
L000214D0                       LSL.W   #$00000005,D1
L000214D2                       ADD.W   #$0042,D1
L000214D6                       BTST.B  #$000e,$0002(A6)
L000214DC                       BTST.B  #$000e,$0002(A6)
L000214E2                       BNE.B   L000214DC 
L000214E4                       MOVE.W  D3,$0062(A6)
L000214E8                       SUB.W   D2,D3
L000214EA                       EXT.L   D3
L000214EC                       MOVE.L  D3,$0050(A6)
L000214F0                       BPL.B   L000214F6 
L000214F2                       OR.W    #$0040,D5
L000214F6                       MOVE.W  D0,$0040(A6)
L000214FA                       MOVE.W  D5,$0042(A6)
L000214FE                       MOVE.L  #$ffffffff,D0
L00021500                       MOVE.L  D0,$0044(A6)
L00021504                       MOVE.L  A0,$0048(A6)
L00021508                       MOVE.W  D4,$0060(A6)
L0002150C                       MOVE.W  D4,$0066(A6)
L00021510                       SUB.W   D2,D3
L00021512                       MOVE.W  D3,$0064(A6)
L00021516                       MOVE.W  #$8000,$0074(A6)
L0002151C                       MOVE.W  D0,$0072(A6)
L00021520                       MOVE.L  A0,$0054(A6)
L00021524                       MOVE.W  D1,$0058(A6)
L00021528                       RTS 

L0002152A                       dc.w    $0000
L0002152C                       dc.w    $0000


text_scroller   ; original address L0002152E
L0002152E                       BSR.W   scroller_soft_scroll                    ; L00021538
L00021532                       BSR.W   scroller_next_character                 ; L000215FA
L00021536                       RTS 

scroller_soft_scroll
L00021538                       CMP.W   #$0000,copper_scroller_softscroll       ; L00022E7C
L00021540                       BEQ.B   scroller_coarse_scroll                  ; L0002154C
L00021542                       SUB.W   #$0022,copper_scroller_softscroll       ; L00022E7C
L0002154A                       RTS 

scroller_coarse_scroll
L0002154C                       CMP.W   #$002e,L0002152A
L00021554                       BEQ.B   reset_scroller_dbl_buffer               ; L00021590 
L00021556                       ADD.W   #$0002,scrolltext_bpl1ptl               ; L00022E5C
L0002155E                       ADD.W   #$0002,scrolltext_bpl2ptl               ; L00022E64
L00021566                       ADD.W   #$0002,scrolltext_bpl3ptl               ; L00022E6C
L0002156E                       ADD.W   #$0002,scrolltext_bpl4ptl               ; L00022E74
L00021576                       MOVE.W  #$00ee,copper_scroller_softscroll       ; L00022E7C
L0002157E                       ADD.W   #$0002,L0002152A
L00021586                       ADD.W   #$0001,L0002152C
L0002158E                       RTS 

reset_scroller_dbl_buffer
L00021590                       ADD.W   #$0001,L0002152C
L00021598                       MOVE.L  #scroll_text_bpl_0_start+6,d0           ; #L0002A5BE,D0
L0002159E                       MOVE.W  D0,scrolltext_bpl1ptl                   ; L00022E5C
L000215A4                       SWAP.W  D0
L000215A6                       MOVE.W  D0,scrolltext_bpl1pth                   ; L00022E58
L000215AC                       MOVE.L  #scroll_text_bpl_1_start+6,d0           ; #L0002BB3E,D0
L000215B2                       MOVE.W  D0,scrolltext_bpl2ptl                   ; L00022E64
L000215B8                       SWAP.W  D0
L000215BA                       MOVE.W  D0,scrolltext_bpl2pth                   ; L00022E60
L000215C0                       MOVE.L  #scroll_text_bpl_2_start+6,d0            ; #L0002D0BE,D0
L000215C6                       MOVE.W  D0,scrolltext_bpl3ptl                   ; L00022E6C
L000215CC                       SWAP.W  D0
L000215CE                       MOVE.W  D0,scrolltext_bpl3pth                   ; L00022E68
L000215D4                       MOVE.L  #scroll_text_bpl_3_start+6,d0           ;#L0002E63E,D0
L000215DA                       MOVE.W  D0,scrolltext_bpl4ptl                   ; L00022E74
L000215E0                       SWAP.W  D0
L000215E2                       MOVE.W  D0,scrolltext_bpl4pth                   ; L00022E70
L000215E8                       MOVE.W  #$00ee,copper_scroller_softscroll       ; L00022E7C
L000215F0                       MOVE.W  #$0000,L0002152A
L000215F8                       RTS 


scroller_next_character ; original address L000215FA
L000215FA                       CMP.W   #$0002,L0002152C
L00021602                       BNE.W   L00021812 
L00021606                       MOVE.L  #$00000000,D7
L00021608                       BTST.B  #$000e,$0002(A6)
L0002160E                       BNE.B   L00021608 
L00021610                       MOVE.L  #$ffffffff,$0044(A6)
L00021618                       MOVE.L  #$09f00000,$0040(A6)
L00021620                       MOVE.W  #$0024,$0064(A6)
L00021626                       MOVE.W  #$0054,$0066(A6)
L0002162C                       MOVEA.L scroll_text_ptr,a0              ; L00026D42,A0
L00021632                       MOVE.B  (A0)+,D7
L00021634                       MOVE.L  A0,scroll_text_ptr              ; L00026D42
L0002163A                       CMP.B   #$ff,D7
L0002163E                       BEQ.B   L0002166A 
L00021640                       CMP.B   #$0a,D7
L00021644                       BEQ.B   L00021676 
L00021646                       CMP.B   #$20,D7
L0002164A                       BEQ.B   L00021676 
L0002164C                       CMP.B   #$54,D7
L00021650                       BPL.B   L0002167C 
L00021652                       CMP.B   #$4a,D7
L00021656                       BPL.B   L00021682 
L00021658                       CMP.B   #$40,D7
L0002165C                       BPL.B   L00021688 
L0002165E                       CMP.B   #$36,D7
L00021662                       BPL.W   L0002168E
L00021666                       BRA.W   L00021692

                        ; restart scroll text
L0002166A                       MOVE.L  #scroll_text,scroll_text_ptr    ; L00026D42
L00021674                       BRA.B   L0002162C 

L00021676                       MOVE.B  #$2d,D7
L0002167A                       BRA.B   L0002163A 

L0002167C                       ADD.W   #$04d8,D7
L00021680                       BRA.B   L00021692 

L00021682                       ADD.W   #$03a2,D7
L00021686                       BRA.B   L00021692 

L00021688                       ADD.W   #$026c,D7
L0002168C                       BRA.B   L00021692 

L0002168E                       ADD.W   #$0136,D7
L00021692                       SUB.B   #$2c,D7
L00021696                       MULU.W  #$0004,D7
L0002169A                       LEA.L   L0002FBB8,A1
L000216A0                       LEA.L   L0002FBB8,A3
L000216A6                       ADDA.W  D7,A1
L000216A8                       ADDA.W  D7,A3
L000216AA                       LEA.L   scroll_text_bpl_0_start,a0              ; L0002A5B8,A0
L000216B0                       LEA.L   scroll_text_bpl_0_start,a2              ; L0002A5B8,A2
L000216B6                       MOVE.W  L0002152A,D0
L000216BC                       ADDA.W  D0,A0
L000216BE                       ADD.W   #$0030,D0
L000216C2                       ADDA.W  D0,A2
L000216C4                       MOVE.L  A1,$0050(A6)
L000216C8                       MOVE.L  A0,$0054(A6)
L000216CC                       MOVE.W  #$0802,$0058(A6)
L000216D2                       BTST.B  #$000e,$0002(A6)
L000216D8                       BNE.B   L000216D2 
L000216DA                       MOVE.L  A3,$0050(A6)
L000216DE                       MOVE.L  A2,$0054(A6)
L000216E2                       MOVE.W  #$0802,$0058(A6)

L000216E8                       LEA.L   L0002FBB8,A1
L000216EE                       LEA.L   L0002FBB8,A3
L000216F4                       ADDA.W  D7,A1
L000216F6                       ADDA.W  D7,A3
L000216F8                       ADDA.W  #$1900,A1
L000216FC                       ADDA.W  #$1900,A3
L00021700                       LEA.L   scroll_text_bpl_1_start,a0      ; L0002BB38,A0
L00021706                       LEA.L   scroll_text_bpl_1_start,a2      ; L0002BB38,A2
L0002170C                       MOVE.W  L0002152A,D0
L00021712                       ADDA.W  D0,A0
L00021714                       ADD.W   #$0030,D0
L00021718                       ADDA.W  D0,A2
L0002171A                       BTST.B  #$000e,$0002(A6)
L00021720                       BNE.B   L0002171A 
L00021722                       MOVE.L  A1,$0050(A6)
L00021726                       MOVE.L  A0,$0054(A6)
L0002172A                       MOVE.W  #$0802,$0058(A6)
L00021730                       BTST.B  #$000e,$0002(A6)
L00021736                       BNE.B   L00021730 
L00021738                       MOVE.L  A3,$0050(A6)
L0002173C                       MOVE.L  A2,$0054(A6)
L00021740                       MOVE.W  #$0802,$0058(A6)

L00021746                       LEA.L   L0002FBB8,A1
L0002174C                       LEA.L   L0002FBB8,A3
L00021752                       ADDA.W  D7,A1
L00021754                       ADDA.W  D7,A3
L00021756                       ADDA.W  #$3200,A1
L0002175A                       ADDA.W  #$3200,A3

L0002175E                       LEA.L   scroll_text_bpl_2_start,a0      ; L0002D0B8,A0
L00021764                       LEA.L   scroll_text_bpl_2_start,a2      ; L0002D0B8,A2
L0002176A                       MOVE.W  L0002152A,D0
L00021770                       ADDA.W  D0,A0
L00021772                       ADD.W   #$0030,D0
L00021776                       ADDA.W  D0,A2
L00021778                       BTST.B  #$000e,$0002(A6)
L0002177E                       BNE.B   L00021778 
L00021780                       MOVE.L  A1,$0050(A6)
L00021784                       MOVE.L  A0,$0054(A6)
L00021788                       MOVE.W  #$0802,$0058(A6)
L0002178E                       BTST.B  #$000e,$0002(A6)
L00021794                       BNE.B   L0002178E 
L00021796                       MOVE.L  A3,$0050(A6)
L0002179A                       MOVE.L  A2,$0054(A6)
L0002179E                       MOVE.W  #$0802,$0058(A6)

L000217A4                       LEA.L   L0002FBB8,A1
L000217AA                       LEA.L   L0002FBB8,A3
L000217B0                       ADDA.W  D7,A1
L000217B2                       ADDA.W  D7,A3
L000217B4                       ADDA.W  #$4b00,A1
L000217B8                       ADDA.W  #$4b00,A3
L000217BC                       LEA.L   scroll_text_bpl_3_start,a0      ; L0002E638,A0
L000217C2                       LEA.L   scroll_text_bpl_3_start,a2      ; L0002E638,A2
L000217C8                       MOVE.W  L0002152A,D0
L000217CE                       ADDA.W  D0,A0
L000217D0                       ADD.W   #$0030,D0
L000217D4                       ADDA.W  D0,A2
L000217D6                       BTST.B  #$000e,$0002(A6)
L000217DC                       BNE.B   L000217D6 
L000217DE                       MOVE.L  A1,$0050(A6)
L000217E2                       MOVE.L  A0,$0054(A6)
L000217E6                       MOVE.W  #$0802,$0058(A6)
L000217EC                       BTST.B  #$000e,$0002(A6)
L000217F2                       BNE.B   L000217EC 
L000217F4                       MOVE.L  A3,$0050(A6)
L000217F8                       MOVE.L  A2,$0054(A6)
L000217FC                       MOVE.W  #$0802,$0058(A6)
L00021802                       BTST.B  #$000e,$0002(A6)
L00021808                       BNE.B   L00021802 
L0002180A                       MOVE.W  #$0000,L0002152C
L00021812                       RTS 




L00021814                       BSR.W   L000218A4
L00021818                       BRA.W   L00021A3C 
L0002181C                       RTS 


L0002181E                       OR.B    #$08,$00bfd100
L00021826                       AND.B   #$7f,$00bfd100
L0002182E                       AND.B   #$f7,$00bfd100
L00021836                       BTST.B  #$0005,$00bfe001
L0002183E                       BNE.B   L00021836 
L00021840                       RTS 

L00021842                       OR.B    #$88,$00bfd100
L0002184A                       AND.B   #$f7,$00bfd100
L00021852                       OR.B    #$08,$00bfd100
L0002185A                       RTS 

L0002185C                       MOVE.L  L00021B80,$0020(A6)
L00021864                       MOVE.W  #$7f00,$009e(A6)
L0002186A                       MOVE.W  #$9500,$009e(A6)
L00021870                       MOVE.W  #$8210,$0096(A6)
L00021876                       MOVE.W  #$0000,$0024(A6)
L0002187C                       MOVE.W  #$9a00,$0024(A6)
L00021882                       MOVE.W  #$9a00,$0024(A6)
L00021888                       BTST.B  #$0001,$001f(A6)
L0002188E                       BEQ.B   L00021888 
L00021890                       MOVE.W  #$0000,$0024(A6)
L00021896                       MOVE.W  #$0002,$009c(A6)
L0002189C                       MOVE.W  #$0010,$0096(A6)
L000218A2                       RTS 

L000218A4                       LEA.L   $00dff000,A6
L000218AA                       MOVE.W  #$7fff,$009c(A6)
L000218B0                       MOVE.W  #$3fff,$009a(A6)
L000218B6                       MOVE.W  #$8010,$009a(A6)
L000218BC                       MOVE.W  #$4489,$007e(A6)
L000218C2                       RTS 

L000218C4                       MOVE.B  #$00,$00bfde00
L000218CC                       MOVE.B  #$7f,$00bfdd00
L000218D4                       MOVE.B  #$00,$00bfd400
L000218DC                       MOVE.B  #$20,$00bfd500
L000218E4                       MOVE.B  #$09,$00bfde00
L000218EC                       BTST.B  #$0000,$00bfdd00
L000218F4                       BEQ.B   L000218EC 
L000218F6                       RTS 


L000218F8                       BTST.B  #$0004,$00bfe001
L00021900                       BEQ.W   L00021920 
L00021904                       OR.B    #$03,$00bfd100
L0002190C                       AND.B   #$fe,$00bfd100
L00021914                       OR.B    #$01,$00bfd100
L0002191C                       BSR.B   L000218C4
L0002191E                       BRA.B   L000218F8 
L00021920                       OR.B    #$04,$00bfd100
L00021928                       MOVE.W  #$0000,L00021B84
L00021930                       RTS 


L00021932                       TST.W   D0
L00021934                       BEQ.W   L0002199E 
L00021938                       MOVE.W  L00021B84,D3
L0002193E                       CMP.W   D3,D0
L00021940                       BEQ.W   L00021996 
L00021944                       MOVE.W  D0,D2
L00021946                       LSR.W   #$00000001,D2
L00021948                       LSR.W   #$00000001,D3
L0002194A                       BTST.L  #$0000,D0
L0002194E                       BNE.W   L0002195C 
L00021952                       OR.B    #$04,$00bfd100
L0002195A                       BRA.B   L00021964 
L0002195C                       AND.B   #$fb,$00bfd100
L00021964                       CMP.W   D3,D2
L00021966                       BEQ.B   L00021996 
L00021968                       BGT.B   L00021980 
L0002196A                       MOVE.B  #$02,$00bfd100
L00021972                       BSR.W   L000219A4
L00021976                       BSR.W   L000218C4
L0002197A                       SUB.W   #$00000001,D3
L0002197C                       BRA.W   L00021964 
L00021980                       AND.B   #$fd,$00bfd100
L00021988                       BSR.W   L000219A4
L0002198C                       BSR.W   L000218C4
L00021990                       ADD.W   #$00000001,D3
L00021992                       BRA.W   L00021964 
L00021996                       MOVE.W  D0,L00021B84
L0002199C                       RTS 


L0002199E                       BSR.W   L000218F8
L000219A2                       BRA.B   L00021996 
L000219A4                       OR.B    #$01,$00bfd100
L000219AC                       AND.B   #$fe,$00bfd100
L000219B4                       OR.B    #$01,$00bfd100
L000219BC                       RTS 


L000219BE                       MOVEA.l L00021B80,A0
L000219C4                       MOVE.W  #$000a,D6
L000219C8                       MOVE.W  (A0)+,D5
L000219CA                       CMP.W   #$4489,D5
L000219CE                       BNE.B   L000219C8 
L000219D0                       MOVE.W  (A0),D5
L000219D2                       CMP.W   #$4489,D5
L000219D6                       BNE.B   L000219DA 
L000219D8                       ADDA.W  #$00000002,A0
L000219DA                       MOVE.L  (A0)+,D5
L000219DC                       MOVE.L  (A0)+,D4
L000219DE                       AND.L   #$55555555,D5
L000219E4                       AND.L   #$55555555,D4
L000219EA                       LSL.L   #$00000001,D5
L000219EC                       OR.L    D4,D5
L000219EE                       SWAP.W  D5
L000219F0                       AND.W   #$ff00,D5
L000219F4                       CMP.W   #$ff00,D5
L000219F8                       BNE.B   L00021A30 
L000219FA                       SWAP.W  D5
L000219FC                       AND.W   #$ff00,D5
L00021A00                       LSL.W   #$00000001,D5
L00021A02                       LEA.L   $00(A4,D5.W),A3
L00021A06                       LEA.L   $0030(A0),A0
L00021A0A                       MOVE.W  #$007f,D7
L00021A0E                       MOVE.L  $0200(A0),D4
L00021A12                       MOVE.L  (A0)+,D5
L00021A14                       AND.L   #$55555555,D5
L00021A1A                       AND.L   #$55555555,D4
L00021A20                       LSL.L   #$00000001,D5
L00021A22                       OR.L    D4,D5
L00021A24                       MOVE.L  D5,(A3)+
L00021A26                       DBF.W   D7,L00021A0E 
L00021A2A                       DBF.W   D6,L000219C8 
L00021A2E                       RTS 


L00021A30                       MOVE.B  $0006(A6),$00dff180
L00021A38                       BRA.W   L00021A30 


L00021A3C                       BSR.W   L0002181E
L00021A40                       BSR.W   L000218F8
L00021A44                       MOVE.W  #$0000,D0
L00021A48                       MOVE.W  #$0000,D1
L00021A4C                       LEA.L   LOAD_BUFFER,A4            ; Load buffer address
L00021A52                       BSR.W   L0002185C
L00021A56                       BSR.W   L000219BE
L00021A5A                       MOVE.L  disk_number,d0          ; required disk number        
L00021A60                       CMP.L   $00040008,D0            ; disk number from inserted disk
L00021A66                       BEQ.W   correct_disk_in_drive 
L00021A6A                       CMP.L   #$00000001,D0
L00021A70                       BEQ.W   insert_disk_1           ; display 'insert disk 1'
L00021A74                       CMP.L   #$00000002,D0
L00021A7A                       BEQ.W   insert_disk_2           ; display 'insert disk 2'

insert_disk_3           ; original address L00021A7E
L00021A7E                       MOVE.L  #insert_disk_3_message,d0       ; #L00036230,D0
L00021A84                       MOVE.W  D0,insertdisk_bplptl            ; L00022DE0
L00021A8A                       SWAP.W  D0
L00021A8C                       MOVE.W  D0,insertdisk_bplpth            ; L00022DDC
L00021A92                       BRA.W   detect_disk_change              ; L00021AC2 

insert_disk_2           ; original address L00021A96
L00021A96                       MOVE.L  #insert_disk_2_message,d0       ; #L00036118,D0
L00021A9C                       MOVE.W  D0,insertdisk_bplptl            ; L00022DE0
L00021AA2                       SWAP.W  D0
L00021AA4                       MOVE.W  D0,insertdisk_bplpth            ; L00022DDC
L00021AAA                       BRA.W   detect_disk_change              ; L00021AC2 

insert_disk_1           ; original address L00021AAE
L00021AAE                       MOVE.L  #insert_disk_1_message,d0       ; #L00036000,D0
L00021AB4                       MOVE.W  D0,insertdisk_bplptl            ; L00022DE0
L00021ABA                       SWAP.W  D0
L00021ABC                       MOVE.W  D0,insertdisk_bplpth            ; L00022DDC

detect_disk_change      ; original address L00021AC2
L00021AC2                       BTST.B  #$0002,$00bfe001
L00021ACA                       BEQ.B   L00021ACE 
L00021ACC                       BRA.B   detect_disk_change              ; L00021AC2 

L00021ACE                       AND.B   #$fd,$00bfd100
L00021AD6                       BSR.W   L00021B36
L00021ADA                       OR.B    #$02,$00bfd100
L00021AE2                       BSR.W   L00021B36
L00021AE6                       BTST.B  #$0002,$00bfe001
L00021AEE                       BEQ.B   L00021ACE 
L00021AF0                       BRA.W   L00021A44 

correct_disk_in_drive   ; original address L00021AF4
L00021AF4                       MOVE.L  #insert_disk_blank_message,d0           ; #L00036348,D0
L00021AFA                       MOVE.W  D0,insertdisk_bplptl                    ; L00022DE0
L00021B00                       SWAP.W  D0
L00021B02                       MOVE.W  D0,insertdisk_bplpth                    ; L00022DDC

L00021B08                       LEA.L   L00021B86,A0
L00021B0E                       MOVE.W  (A0)+,D0
L00021B10                       MOVE.W  (A0)+,D1
L00021B12                       MOVEA.L (A0)+,A4
L00021B14                       MOVEA.L (A0)+,A5
L00021B16                       BSR.W   L00021932
L00021B1A                       BSR.W   L0002185C
L00021B1E                       BSR.W   L000219BE
L00021B22                       ADDA.L  #$00001600,A4
L00021B28                       ADD.W   #$0001,D0
L00021B2C                       DBF.W   D1,L00021B16 
L00021B30                       BSR.W   L00021842
L00021B34                       RTS 

L00021B36                       OR.B    #$01,$00bfd100
L00021B3E                       AND.B   #$fe,$00bfd100
L00021B46                       OR.B    #$01,$00bfd100
L00021B4E                       BSR.W   L000218C4
L00021B52                       BSR.W   L000218C4
L00021B56                       BSR.W   L000218C4
L00021B5A                       BSR.W   L000218C4
L00021B5E                       BSR.W   L000218C4
L00021B62                       BSR.W   L000218C4
L00021B66                       BSR.W   L000218C4
L00021B6A                       BSR.W   L000218C4
L00021B6E                       BSR.W   L000218C4
L00021B72                       BSR.W   L000218C4
L00021B76                       BSR.W   L000218C4
L00021B7A                       BSR.W   L000218C4
L00021B7E                       RTS 

L00021B80                       dc.w    $0007,$5000
L00021B84                       dc.w    $0000
L00021B86                       dc.w    $0000
L00021B88                       dc.w    $0000
L00021B8A                       dc.w    $0000
L00021B8C                       dc.w    $0000,$0000
L00021B90                       dc.w    $0000
disk_number     ; original address L00021B92
                                dc.w    $0000
L00021B94                       dc.w    $0000



L00021B96                       MOVEA.L #LOAD_BUFFER,A0           ; external address
L00021B9C                       MOVE.L  A0,L00022CB8
L00021BA2                       MOVEA.L A0,A1
L00021BA4                       LEA.L   $03b8(A1),A1
L00021BA8                       MOVE.L  #$0000007f,D0
L00021BAA                       MOVE.L  #$00000000,D1
L00021BAC                       MOVE.L  D1,D2
L00021BAE                       SUB.W   #$00000001,D0
L00021BB0                       MOVE.B  (A1)+,D1
L00021BB2                       CMP.B   D2,D1
L00021BB4                       BGT.B   L00021BAC 
L00021BB6                       DBF.W   D0,L00021BB0 
L00021BBA                       ADD.B   #$00000001,D2

L00021BBC                       LEA.L   L00022C3C(PC),A1
L00021BC0                       ASL.L   #$00000008,D2
L00021BC2                       ASL.L   #$00000002,D2
L00021BC4                       ADD.L   #$0000043c,D2
L00021BCA                       ADD.L   A0,D2
L00021BCC                       MOVEA.L D2,A2
L00021BCE                       MOVE.L  #$0000001e,D0
L00021BD0                       CLR.L   (A2)
L00021BD2                       MOVE.L  A2,(A1)+
L00021BD4                       MOVE.L  #$00000000,D1
L00021BD6                       MOVE.W  $002a(A0),D1
L00021BDA                       ASL.L   #$00000001,D1
L00021BDC                       ADDA.L  D1,A2
L00021BDE                       ADDA.L  #$0000001e,A0
L00021BE4                       DBF.W   D0,L00021BD0 
L00021BE8                       OR.B    #$02,$00bfe001          ; /LED (sound filter off)
L00021BF0                       MOVE.B  #$06,L00022CBC
L00021BF8                       CLR.B   L00022CBD
L00021BFE                       CLR.B   L00022CBE
L00021C04                       CLR.W   L00022CC6

music_off       ; original address L00021C0A
                                CLR.W   CUSTOM+AUD0VOL          ; $00dff0a8
                                CLR.W   CUSTOM+AUD1VOL          ; $00dff0b8
                                CLR.W   CUSTOM+AUD2VOL          ; $00dff0c8
                                CLR.W   CUSTOM+AUD3VOL          ; $00dff0d8
                                MOVE.W  #$000f,CUSTOM+DMACON    ; $00dff096
                                RTS 


L00021C2C                       MOVEM.L D0-D4/A0-A6,-(A7)
L00021C30                       ADD.B   #$00000001,L00022CBD
L00021C36                       MOVE.B  L00022CBD(PC),D0
L00021C3A                       CMP.B   L00022CBC(PC),D0
L00021C3E                       BCS.B   L00021C54 
L00021C40                       CLR.B   L00022CBD
L00021C46                       TST.B   L00022CC4
L00021C4C                       BEQ.B   L00021C92 
L00021C4E                       BSR.B   L00021C5A
L00021C50                       BRA.W   L00021EC8 

L00021C54                       BSR.B   L00021C5A
L00021C56                       BRA.W   L00021F64 

L00021C5A                       LEA.L   $00dff0a0,A5
L00021C60                       LEA.L   L00022B8C(PC),A6
L00021C64                       BSR.W   L00021F72
L00021C68                       LEA.L   $00dff0b0,A5
L00021C6E                       LEA.L   L00022B8C(PC),A6
L00021C72                       BSR.W   L00021F72
L00021C76                       LEA.L   $00dff0c0,A5
L00021C7C                       LEA.L   L00022BE4(PC),A6
L00021C80                       BSR.W   L00021F72
L00021C84                       LEA.L   $00dff0d0,A5
L00021C8A                       LEA.L   L00022C10(PC),A6
L00021C8E                       BRA.W   L00021F72 


L00021C92                       MOVEA.L L00022CB8(PC),A0
L00021C96                       LEA.L   $000c(A0),A3
L00021C9A                       LEA.L   $03b8(A0),A2
L00021C9E                       LEA.L   $043c(A0),A0
L00021CA2                       MOVE.L  #$00000000,D0
L00021CA4                       MOVE.L  #$00000000,D1
L00021CA6                       MOVE.B  L00022CBE(PC),D0
L00021CAA                       MOVE.B  $00(A2,D0.W),D1
L00021CAE                       ASL.L   #$00000008,D1
L00021CB0                       ASL.L   #$00000002,D1
L00021CB2                       ADD.W   L00022CC6(PC),D1
L00021CB6                       CLR.W   L00022CC8
L00021CBC                       LEA.L   $00dff0a0,A5
L00021CC2                       LEA.L   L00022B8C(PC),A6
L00021CC6                       BSR.B   L00021CF0
L00021CC8                       LEA.L   $00dff0b0,A5
L00021CCE                       LEA.L   L00022BB8(PC),A6
L00021CD2                       BSR.B   L00021CF0
L00021CD4                       LEA.L   $00dff0c0,A5
L00021CDA                       LEA.L   L00022BE4(PC),A6
L00021CDE                       BSR.B   L00021CF0
L00021CE0                       LEA.L   $00dff0d0,A5
L00021CE6                       LEA.L   L00022C10(PC),A6
L00021CEA                       BSR.B   L00021CF0
L00021CEC                       BRA.W   L00021E64 


L00021CF0                       TST.L   (A6)
L00021CF2                       BNE.B   L00021CF8 
L00021CF4                       BSR.W   L00021FDA
L00021CF8                       MOVE.L  $00(A0,D1.L),(A6)
L00021CFC                       ADD.L   #$00000004,D1
L00021CFE                       MOVE.L  #$00000000,D2
L00021D00                       MOVE.B  $0002(A6),D2
L00021D04                       AND.B   #$f0,D2
L00021D08                       LSR.B   #$00000004,D2
L00021D0A                       MOVE.B  (A6),D0
L00021D0C                       AND.B   #$f0,D0
L00021D10                       OR.B    D0,D2
L00021D12                       TST.B   D2
L00021D14                       BEQ.W   L00021D9A 
L00021D18                       MOVE.L  #$00000000,D3
L00021D1A                       LEA.L   L00022C3C(PC),A1
L00021D1E                       MOVE.W  D2,D4
L00021D20                       SUB.L   #$00000001,D2
L00021D22                       ASL.L   #$00000002,D2
L00021D24                       MULU.W  #$001e,D4
L00021D28                       MOVE.L  $00(A1,D2.L),$0004(A6)
L00021D2E                       MOVE.W  $00(A3,D4.L),$0008(A6)
L00021D34                       MOVE.W  $00(A3,D4.L),$0028(A6)
L00021D3A                       MOVE.B  $02(A3,D4.L),$0012(A6)
L00021D40                       MOVE.B  $03(A3,D4.L),$0013(A6)
L00021D46                       MOVE.W  $04(A3,D4.L),D3
L00021D4A                       TST.W   D3
L00021D4C                       BEQ.B   L00021D7C 
L00021D4E                       MOVE.L  $0004(A6),D2
L00021D52                       ASL.W   #$00000001,D3
L00021D54                       ADD.L   D3,D2
L00021D56                       MOVE.L  D2,$000a(A6)
L00021D5A                       MOVE.L  D2,$0024(A6)
L00021D5E                       MOVE.W  $04(A3,D4.L),D0
L00021D62                       ADD.W   $06(A3,D4.L),D0
L00021D66                       MOVE.W  D0,$0008(A6)
L00021D6A                       MOVE.W  $06(A3,D4.L),$000e(A6)
L00021D70                       MOVE.L  #$00000000,D0
L00021D72                       MOVE.B  $0013(A6),D0
L00021D76                       MOVE.W  D0,$0008(A5)
L00021D7A                       BRA.B   L00021D9A 


L00021D7C                       MOVE.L  $0004(A6),D2
L00021D80                       ADD.L   D3,D2
L00021D82                       MOVE.L  D2,$000a(A6)
L00021D86                       MOVE.L  D2,$0024(A6)
L00021D8A                       MOVE.W  $06(A3,D4.l),$000e(A6)
L00021D90                       MOVE.L  #$00000000,D0
L00021D92                       MOVE.B  $0013(A6),D0
L00021D96                       MOVE.W  D0,$0008(A5)
L00021D9A                       MOVE.W  (A6),D0
L00021D9C                       AND.W   #$0fff,D0
L00021DA0                       BEQ.W   L00022406 
L00021DA4                       MOVE.W  $0002(A6),D0
L00021DA8                       AND.W   #$0ff0,D0
L00021DAC                       CMP.W   #$0e50,D0
L00021DB0                       BEQ.B   L00021DD2 
L00021DB2                       MOVE.B  $0002(A6),D0
L00021DB6                       AND.B   #$0f,D0
L00021DBA                       CMP.B   #$03,D0
L00021DBE                       BEQ.B   L00021DD8 
L00021DC0                       CMP.B   #$05,D0
L00021DC4                       BEQ.B   L00021DD8 
L00021DC6                       CMP.B   #$09,D0
L00021DCA                       BNE.B   L00021DE0 
L00021DCC                       BSR.W   L00022406
L00021DD0                       BRA.B   L00021DE0 

L00021DD2                       BSR.W   L000224FE
L00021DD6                       BRA.B   L00021DE0 

L00021DD8                       BSR.W   L000220E4
L00021DDC                       BRA.W   L00022406 

L00021DE0                       MOVEM.L D0-D1/A0-A1,-(A7)
L00021DE4                       MOVE.W  (A6),D1
L00021DE6                       AND.W   #$0fff,D1
L00021DEA                       LEA.L   L0002270C(PC),A1
L00021DEE                       MOVE.L  #$00000000,D0
L00021DF0                       MOVE.L  #$00000024,D7
L00021DF2                       CMP.W   $00(A1,D0.W),D1
L00021DF6                       BCC.B   L00021DFE 
L00021DF8                       ADD.L   #$00000002,D0
L00021DFA                       DBF.W   D7,L00021DF2 
L00021DFE                       MOVE.L  #$00000000,D1
L00021E00                       MOVE.B  $0012(A6),D1
L00021E04                       MULU.W  #$0048,D1
L00021E08                       ADDA.L  D1,A1
L00021E0A                       MOVE.W  $00(A1,D0.W),$0010(A6)
L00021E10                       MOVEM.L (A7)+,D0-D1/A0-A1
L00021E14                       MOVE.W  $0002(A6),D0
L00021E18                       AND.W   #$0ff0,D0
L00021E1C                       CMP.W   #$0ed0,D0
L00021E20                       BEQ.W   L00022406 
L00021E24                       MOVE.W  $0014(A6),$00dff096
L00021E2C                       BTST.B  #$0002,$001e(A6)
L00021E32                       BNE.B   L00021E38 
L00021E34                       CLR.B   $001b(A6)
L00021E38                       BTST.B  #$0006,$001e(A6)
L00021E3E                       BNE.B   L00021E44 
L00021E40                       CLR.B   $001d(A6)
L00021E44                       MOVE.L  $0004(A6),(A5)
L00021E48                       MOVE.W  $0008(A6),$0004(A5)
L00021E4E                       MOVE.W  $0010(A6),D0
L00021E52                       MOVE.W  D0,$0006(A5)
L00021E56                       MOVE.W  $0014(A6),D0
L00021E5A                       OR.W    D0,L00022CC8
L00021E60                       BRA.W   L00022406 

L00021E64                       MOVE.W  #$012c,D0
L00021E68                       DBF.W   D0,L00021E68 
L00021E6C                       MOVE.W  L00022CC8(PC),D0
L00021E70                       OR.W    #$8000,D0
L00021E74                       MOVE.W  D0,$00dff096
L00021E7A                       MOVE.W  #$012c,D0
L00021E7E                       DBF.W   D0,L00021E7E 
L00021E82                       LEA.L   $00dff000,A5
L00021E88                       LEA.L   L00022C10(PC),A6
L00021E8C                       MOVE.L  $000a(A6),$00d0(A5)
L00021E92                       MOVE.W  $000e(A6),$00d4(A5)
L00021E98                       LEA.L   L00022BE4(PC),A6
L00021E9C                       MOVE.L  $000a(A6),$00c0(A5)
L00021EA2                       MOVE.W  $000e(A6),$00c4(A5)
L00021EA8                       LEA.L   L00022BB8(PC),A6
L00021EAC                       MOVE.L  $000a(A6),$00b0(A5)
L00021EB2                       MOVE.W  $000e(A6),$00b4(A5)
L00021EB8                       LEA.L   L00022B8C(PC),A6
L00021EBC                       MOVE.L  $000a(A6),$00a0(A5)
L00021EC2                       MOVE.W  $000e(A6),$00a4(A5)
L00021EC8                       ADD.W   #$0010,L00022CC6
L00021ED0                       MOVE.B  L00022CC3,D0
L00021ED6                       BEQ.B   L00021EE4 
L00021ED8                       MOVE.B  D0,L00022CC4
L00021EDE                       CLR.B   L00022CC3
L00021EE4                       TST.B   L00022CC4
L00021EEA                       BEQ.B   L00021EFC 
L00021EEC                       SUB.B   #$00000001,L00022CC4
L00021EF2                       BEQ.B   L00021EFC 
L00021EF4                       SUB.W   #$0010,L00022CC6
L00021EFC                       TST.B   L00022CC1
L00021F02                       BEQ.B   L00021F1E 
L00021F04                       SF.B    L00022CC1 
L00021F0A                       MOVE.L  #$00000000,D0
L00021F0C                       MOVE.B  L00022CBF(PC),D0
L00021F10                       CLR.B   L00022CBF
L00021F16                       LSL.W   #$00000004,D0
L00021F18                       MOVE.W  D0,L00022CC6
L00021F1E                       CMP.W   #$0400,L00022CC6
L00021F26                       BCS.B   L00021F64 
L00021F28                       MOVE.L  #$00000000,D0
L00021F2A                       MOVE.B  L00022CBF(PC),D0
L00021F2E                       LSL.W   #$00000004,D0
L00021F30                       MOVE.W  D0,L00022CC6
L00021F36                       CLR.B   L00022CBF
L00021F3C                       CLR.B   L00022CC0
L00021F42                       ADD.B   #$00000001,L00022CBE
L00021F48                       AND.B   #$7f,L00022CBE
L00021F50                       MOVE.B  L00022CBE(PC),D1
L00021F54                       MOVEA.L L00022CB8(PC),A0
L00021F58                       CMP.B   $03b6(A0),D1
L00021F5C                       BCS.B   L00021F64 
L00021F5E                       CLR.B   L00022CBE
L00021F64                       TST.B   L00022CC0
L00021F6A                       BNE.B   L00021F28 
L00021F6C                       MOVEM.L (A7)+,D0-D4/A0-A6
L00021F70                       RTS 

L00021F72                       BSR.W   L0002268A
L00021F76                       MOVE.W  $0002(A6),D0
L00021F7A                       AND.W   #$0fff,D0
L00021F7E                       BEQ.B   L00021FDA 
L00021F80                       MOVE.B  $0002(A6),D0
L00021F84                       AND.B   #$0f,D0
L00021F88                       BEQ.B   L00021FE2 
L00021F8A                       CMP.B   #$01,D0
L00021F8E                       BEQ.W   L00022056 
L00021F92                       CMP.B   #$02,D0
L00021F96                       BEQ.W   L000220A6 
L00021F9A                       CMP.B   #$03,D0
L00021F9E                       BEQ.W   L00022146 
L00021FA2                       CMP.B   #$04,D0
L00021FA6                       BEQ.W   L000221D4 
L00021FAA                       CMP.B   #$05,D0
L00021FAE                       BEQ.W   L0002226C 
L00021FB2                       CMP.B   #$06,D0
L00021FB6                       BEQ.W   L00022274 
L00021FBA                       CMP.B   #$0e,D0
L00021FBE                       BEQ.W   L00022440 
L00021FC2                       MOVE.W  $0010(A6),$0006(A5)
L00021FC8                       CMP.B   #$07,D0
L00021FCC                       BEQ.W   L0002227A 
L00021FD0                       CMP.B   #$0a,D0
L00021FD4                       BEQ.W   L00022350 
L00021FD8                       RTS 

L00021FDA                       MOVE.W $0010(A6),$0006(A5)
L00021FE0                       RTS 

L00021FE2                       MOVE.L  #$00000000,D0
L00021FE4                       MOVE.B  L00022CBD(PC),D0
L00021FE8                       DIVS.W  #$0003,D0
L00021FEC                       SWAP.W  D0
L00021FEE                       CMP.W   #$0000,D0
L00021FF2                       BEQ.B   L00022010 
L00021FF4                       CMP.W   #$0002,D0
L00021FF8                       BEQ.B   L00022004 
L00021FFA                       MOVE.L  #$00000000,D0
L00021FFC                       MOVE.B  $0003(A6),D0
L00022000                       LSR.B   #$00000004,D0
L00022002                       BRA.B   L00022016 
L00022004                       MOVE.L  #$00000000,D0
L00022006                       MOVE.B  $0003(A6),D0
L0002200A                       AND.B   #$0f,D0
L0002200E                       BRA.B   L00022016 
L00022010                       MOVE.W  $0010(A6),D2
L00022014                       BRA.B   L00022040 
L00022016                       ASL.W   #$00000001,D0
L00022018                       MOVE.L  #$00000000,D1
L0002201A                       MOVE.B  $0012(A6),D1
L0002201E                       MULU.W  #$0048,D1
L00022022                       LEA.L   L0002270C(PC),A0
L00022026                       ADDA.L  D1,A0
L00022028                       MOVE.L  #$00000000,D1
L0002202A                       MOVE.W  $0010(A6),D1
L0002202E                       MOVE.L  #$00000024,D7
L00022030                       MOVE.W  $00(A0,D0.W),D2
L00022034                       CMP.W   (A0),D1
L00022036                       BCC.B   L00022040 
L00022038                       ADDA.L  #$00000002,A0
L0002203A                       DBF.W   D7,L00022030 
L0002203E                       RTS 

L00022040                       MOVE.W  D2,$0006(A5)
L00022044                       RTS 

L00022046                       TST.B   L00022CBD
L0002204C                       BNE.B   L00021FD8 
L0002204E                       MOVE.B  #$0f,L00022CC2
L00022056                       MOVE.L  #$00000000,D0
L00022058                       MOVE.B  $0003(A6),D0
L0002205C                       AND.B   L00022CC2(PC),D0
L00022060                       MOVE.B  #$ff,L00022CC2
L00022068                       SUB.W   D0,$0010(A6)
L0002206C                       MOVE.W  $0010(A6),D0
L00022070                       AND.W   #$0fff,D0
L00022074                       CMP.W   #$0071,D0
L00022078                       BPL.B   L00022086 
L0002207A                       AND.W   #$f000,$0010(A6)
L00022080                       OR.W    #$0071,$0010(A6)
L00022086                       MOVE.W  $0010(A6),D0
L0002208A                       AND.W   #$0fff,D0
L0002208E                       MOVE.W  D0,$0006(A5)
L00022092                       RTS 

L00022094                       TST.B   L00022CBD
L0002209A                       BNE.W   L00021FD8 
L0002209E                       MOVE.B  #$0f,L00022CC2
L000220A6                       CLR.W   D0
L000220A8                       MOVE.B  $0003(A6),D0
L000220AC                       AND.B   L00022CC2(PC),D0
L000220B0                       MOVE.B  #$ff,L00022CC2
L000220B8                       ADD.W   D0,$0010(A6)
L000220BC                       MOVE.W  $0010(A6),D0
L000220C0                       AND.W   #$0fff,D0
L000220C4                       CMP.W   #$0358,D0
L000220C8                       BMI.B   L000220D6 
L000220CA                       AND.W   #$f000,$0010(A6)
L000220D0                       OR.W    #$0358,$0010(A6)
L000220D6                       MOVE.W  $0010(A6),D0
L000220DA                       AND.W   #$0fff,D0
L000220DE                       MOVE.W  D0,$0006(A5)
L000220E2                       RTS 

L000220E4                       MOVE.L  A0,-(A7)
L000220E6                       MOVE.W  (A6),D2
L000220E8                       AND.W   #$0fff,D2
L000220EC                       MOVE.L  #$00000000,D0
L000220EE                       MOVE.B  $0012(A6),D0
L000220F2                       MULU.W  #$004a,D0
L000220F6                       LEA.L   L0002270C(PC),A0
L000220FA                       ADDA.L  D0,A0
L000220FC                       MOVE.L  #$00000000,D0
L000220FE                       CMP.W   $00(A0,D0.W),D2
L00022102                       BCC.B   L0002210E 
L00022104                       ADD.W   #$00000002,D0
L00022106                       CMP.W   #$004a,D0
L0002210A                       BCS.B   L000220FE 
L0002210C                       MOVE.L  #$00000046,D0
L0002210E                       MOVE.B  $0012(A6),D2
L00022112                       AND.B   #$08,D2
L00022116                       BEQ.B   L0002211E 
L00022118                       TST.W   D0
L0002211A                       BEQ.B   L0002211E 
L0002211C                       SUB.W   #$00000002,D0
L0002211E                       MOVE.W  $00(A0,D0.W),D2
L00022122                       MOVEA.L (A7)+,A0
L00022124                       MOVE.W  D2,$0018(A6)
L00022128                       MOVE.W  $0010(A6),D0
L0002212C                       CLR.B   $0016(A6)
L00022130                       CMP.W   D0,D2
L00022132                       BEQ.B   L00022140 
L00022134                       BGE.W   L00021FD8 
L00022138                       MOVE.B  #$01,$0016(A6)
L0002213E                       RTS 

L00022140                       CLR.W   $0018(A6)
L00022144                       RTS 

L00022146                       MOVE.B  $0003(A6),D0
L0002214A                       BEQ.B   L00022154 
L0002214C                       MOVE.B  D0,$0017(A6)
L00022150                       CLR.B   $0003(A6)
L00022154                       TST.W   $0018(A6)
L00022158                       BEQ.W   L00021FD8 
L0002215C                       MOVE.L  #$00000000,D0
L0002215E                       MOVE.B  $0017(A6),D0
L00022162                       TST.B   $0016(A6)
L00022166                       BNE.B   L00022182 
L00022168                       ADD.W   D0,$0010(A6)
L0002216C                       MOVE.W  $0018(A6),D0
L00022170                       CMP.W   $0010(A6),D0
L00022174                       BGT.B   L0002219A 
L00022176                       MOVE.W  $0018(A6),$0010(A6)
L0002217C                       CLR.W   $0018(A6)
L00022180                       BRA.B   L0002219A 
L00022182                       SUB.W   D0,$0010(A6)
L00022186                       MOVE.W  $0018(A6),D0
L0002218A                       CMP.W   $0010(A6),D0
L0002218E                       BLT.B   L0002219A 
L00022190                       MOVE.W  $0018(A6),$0010(A6)
L00022196                       CLR.W   $0018(A6)
L0002219A                       MOVE.W  $0010(A6),D2
L0002219E                       MOVE.B  $001f(A6),D0
L000221A2                       AND.B   #$0f,D0
L000221A6                       BEQ.B   L000221CE 
L000221A8                       MOVE.L  #$00000000,D0
L000221AA                       MOVE.B  $0012(A6),D0
L000221AE                       MULU.W  #$0048,D0
L000221B2                       LEA.L   L0002270C(PC),A0
L000221B6                       ADDA.L  D0,A0
L000221B8                       MOVE.L  #$00000000,D0
L000221BA                       CMP.W   $00(A0,D0.W),D2
L000221BE                       BCC.B   L000221CA 
L000221C0                       ADD.W   #$00000002,D0
L000221C2                       CMP.W   #$0048,D0
L000221C6                       BCS.B   L000221BA 
L000221C8                       MOVE.L  #$00000046,D0
L000221CA                       MOVE.W  $00(A0,D0.W),D2
L000221CE                       MOVE.W  D2,$0006(A5)
L000221D2                       RTS 

L000221D4                       MOVE.B  $0003(A6),D0
L000221D8                       BEQ.B   L000221FE 
L000221DA                       MOVE.B  $001a(A6),D2
L000221DE                       AND.B   #$0f,D0
L000221E2                       BEQ.B   L000221EA 
L000221E4                       AND.B   #$f0,D2
L000221E8                       OR.B    D0,D2
L000221EA                       MOVE.B  $0003(A6),D0
L000221EE                       AND.B   #$f0,D0
L000221F2                       BEQ.B   L000221FA 
L000221F4                       AND.B   #$0f,D2
L000221F8                       OR.B    D0,D2
L000221FA                       MOVE.B  D2,$001a(A6)
L000221FE                       MOVE.B  $001b(A6),D0
L00022202                       LEA.L   L000226EC(PC),A4
L00022206                       LSR.W   #$00000002,D0
L00022208                       AND.W   #$001f,D0
L0002220C                       MOVE.L  #$00000000,D2
L0002220E                       MOVE.B  $001e(A6),D2
L00022212                       AND.B   #$03,D2
L00022216                       BEQ.B   L00022238 
L00022218                       LSL.B   #$00000003,D0
L0002221A                       CMP.B   #$01,D2
L0002221E                       BEQ.B   L00022226 
L00022220                       MOVE.B  #$ff,D2
L00022224                       BRA.B   L0002223C 
L00022226                       TST.B   $001b(A6)
L0002222A                       BPL.B   L00022234 
L0002222C                       MOVE.B  #$ff,D2
L00022230                       SUB.B   D0,D2
L00022232                       BRA.B   L0002223C 
L00022234                       MOVE.B  D0,D2
L00022236                       BRA.B   L0002223C 
L00022238                       MOVE.B  $00(A4,D0.W),D2
L0002223C                       MOVE.B  $001a(A6),D0
L00022240                       AND.W   #$000f,D0
L00022244                       MULU.W  D0,D2
L00022246                       LSR.W   #$00000007,D2
L00022248                       MOVE.W  $0010(A6),D0
L0002224C                       TST.B   $001b(A6)
L00022250                       BMI.B   L00022256 
L00022252                       ADD.W   D2,D0
L00022254                       BRA.B   L00022258 

L00022256                       SUB.W   D2,D0
L00022258                       MOVE.W  D0,$0006(A5)
L0002225C                       MOVE.B  $001a(A6),D0
L00022260                       LSR.W   #$00000002,D0
L00022262                       AND.W   #$003c,D0
L00022266                       ADD.B   D0,$001b(A6)
L0002226A                       RTS 

L0002226C                       BSR.W   L00022154
L00022270                       BRA.W   L00022350 

L00022274                       BSR.B   L000221FE
L00022276                       BRA.W   L00022350 

L0002227A                       MOVE.B  $0003(A6),D0
L0002227E                       BEQ.B   L000222A4 
L00022280                       MOVE.B  $001c(A6),D2
L00022284                       AND.B   #$0f,D0
L00022288                       BEQ.B   L00022290 
L0002228A                       AND.B   #$f0,D2
L0002228E                       OR.B    D0,D2
L00022290                       MOVE.B  $0003(A6),D0
L00022294                       AND.B   #$f0,D0
L00022298                       BEQ.B   L000222A0 
L0002229A                       AND.B   #$0f,D2
L0002229E                       OR.B    D0,D2
L000222A0                       MOVE.B  D2,$001c(A6)
L000222A4                       MOVE.B  $001d(A6),D0
L000222A8                       LEA.L   L000226EC(PC),A4
L000222AC                       LSR.W   #$00000002,D0
L000222AE                       AND.W   #$001f,D0
L000222B2                       MOVE.L  #$00000000,D2
L000222B4                       MOVE.B  $001e(A6),D2
L000222B8                       LSR.B   #$00000004,D2
L000222BA                       AND.B   #$03,D2
L000222BE                       BEQ.B   L000222E0 
L000222C0                       LSL.B   #$00000003,D0
L000222C2                       CMP.B   #$01,D2
L000222C6                       BEQ.B   L000222CE 
L000222C8                       MOVE.B  #$ff,D2
L000222CC                       BRA.B   L000222E4 

L000222CE                       TST.B   $001b(A6)
L000222D2                       BPL.B   L000222DC 
L000222D4                       MOVE.B  #$ff,D2
L000222D8                       SUB.B   D0,D2
L000222DA                       BRA.B   L000222E4 
L000222DC                       MOVE.B  D0,D2
L000222DE                       BRA.B   L000222E4 
L000222E0                       MOVE.B  $00(A4,D0.W),D2
L000222E4                       MOVE.B  $001c(A6),D0
L000222E8                       AND.W   #$000f,D0
L000222EC                       MULU.W  D0,D2
L000222EE                       LSR.W   #$00000006,D2
L000222F0                       MOVE.L  #$00000000,D0
L000222F2                       MOVE.B  $0013(A6),D0
L000222F6                       TST.B   $001d(A6)
L000222FA                       BMI.B   L00022300 
L000222FC                       ADD.W   D2,D0
L000222FE                       BRA.B   L00022302 

L00022300                       SUB.W   D2,D0
L00022302                       BPL.B   L00022306 
L00022304                       CLR.W   D0
L00022306                       CMP.W   #$0040,D0
L0002230A                       BLS.B   L00022310 
L0002230C                       MOVE.W  #$0040,D0
L00022310                       MOVE.W  D0,$0008(A5)
L00022314                       MOVE.B  $001c(A6),D0
L00022318                       LSR.W   #$00000002,D0
L0002231A                       AND.W   #$003c,D0
L0002231E                       ADD.B   D0,$001d(A6)
L00022322                       RTS 

L00022324                       MOVE.L  #$00000000,D0
L00022326                       MOVE.B  $0003(A6),D0
L0002232A                       BEQ.B   L00022330 
L0002232C                       MOVE.B  D0,$0020(A6)
L00022330                       MOVE.B  $0020(A6),D0
L00022334                       LSL.W   #$00000007,D0
L00022336                       CMP.W   $0008(A6),D0
L0002233A                       BGE.B   L00022348 
L0002233C                       SUB.W   D0,$0008(A6)
L00022340                       LSL.W   #$00000001,D0
L00022342                       ADD.L   D0,$0004(A6)
L00022346                       RTS 

L00022348                       MOVE.W  #$0001,$0008(A6)
L0002234E                       RTS 

L00022350                       MOVE.L  #$00000000,D0
L00022352                       MOVE.B  $0003(A6),D0
L00022356                       LSR.B   #$00000004,D0
L00022358                       TST.B   D0
L0002235A                       BEQ.B   L00022378 
L0002235C                       ADD.B   D0,$0013(A6)
L00022360                       CMP.B   #$40,$0013(A6)
L00022366                       BMI.B   L0002236E 
L00022368                       MOVE.B  #$40,$0013(A6)
L0002236E                       MOVE.B  $0013(A6),D0
L00022372                       MOVE.W  D0,$0008(A5)
L00022376                       RTS 

L00022378                       MOVE.L  #$00000000,D0
L0002237A                       MOVE.B  $0003(A6),D0
L0002237E                       AND.B   #$0f,D0
L00022382                       SUB.B   D0,$0013(A6)

L00022386                       BPL.B   L0002238C
L00022388                       CLR.B   $0013(A6)
L0002238C                       MOVE.B  $0013(A6),D0
L00022390                       MOVE.W  D0,$0008(A5)
L00022394                       RTS 

L00022396                       MOVE.B  $0003(A6),D0
L0002239A                       SUB.B   #$00000001,D0
L0002239C                       MOVE.B  D0,L00022CBE
L000223A2                       CLR.B   L00022CBF
L000223A8                       ST.B    L00022CC0 
L000223AE                       RTS 

L000223B0                       MOVE.L  #$00000000,D0
L000223B2                       MOVE.B  $0003(A6),D0
L000223B6                       CMP.B   #$40,D0
L000223BA                       BLS.B   L000223BE 
L000223BC                       MOVE.L  #$00000040,D0
L000223BE                       MOVE.B  D0,$0013(A6)
L000223C2                       MOVE.W  D0,$0008(A5)
L000223C6                       RTS 

L000223C8                       MOVE.L  #$00000000,D0
L000223CA                       MOVE.B  $0003(A6),D0
L000223CE                       MOVE.L  D0,D2
L000223D0                       LSR.B   #$00000004,D0
L000223D2                       MULU.W  #$000a,D0
L000223D6                       AND.B   #$0f,D2
L000223DA                       ADD.B   D2,D0
L000223DC                       CMP.B   #$3f,D0
L000223E0                       BHI.B   L000223A2 
L000223E2                       MOVE.B  D0,L00022CBF
L000223E8                       ST.B    L00022CC0 
L000223EE                       RTS 

L000223F0                       MOVE.B  $0003(A6),D0
L000223F4                       BEQ.W   L00021FD8 
L000223F8                       CLR.B   L00022CBD
L000223FE                       MOVE.B  D0,L00022CBC
L00022404                       RTS 

L00022406                       BSR.W   L0002268A
L0002240A                       MOVE.B  $0002(A6),D0
L0002240E                       AND.B   #$0f,D0
L00022412                       CMP.B   #$09,D0
L00022416                       BEQ.W   L00022324 
L0002241A                       CMP.B   #$0b,D0
L0002241E                       BEQ.W   L00022396 
L00022422                       CMP.B   #$0d,D0
L00022426                       BEQ.B   L000223C8 
L00022428                       CMP.B   #$0e,D0
L0002242C                       BEQ.B   L00022440 
L0002242E                       CMP.B   #$0f,D0
L00022432                       BEQ.B   L000223F0 
L00022434                       CMP.B   #$0c,D0
L00022438                       BEQ.W   L000223B0 
L0002243C                       BRA.W   L00021FDA 

L00022440                       MOVE.B  $0003(A6),D0
L00022444                       AND.B   #$f0,D0
L00022448                       LSR.B   #$00000004,D0
L0002244A                       BEQ.B   L000224BC 
L0002244C                       CMP.B   #$01,D0
L00022450                       BEQ.W   L00022046 
L00022454                       CMP.B   #$02,D0
L00022458                       BEQ.W   L00022094 
L0002245C                       CMP.B   #$03,D0
L00022460                       BEQ.B   L000224D6 
L00022462                       CMP.B   #$04,D0
L00022466                       BEQ.W   L000224EA
L0002246A                       CMP.B   #$05,D0
L0002246E                       BEQ.W   L000224FE 
L00022472                       CMP.B   #$06,D0
L00022476                       BEQ.W   L0002250C 
L0002247A                       CMP.B   #$07,D0
L0002247E                       BEQ.W   L00022550 
L00022482                       CMP.B   #$09,D0
L00022486                       BEQ.W   L00022566 
L0002248A                       CMP.B   #$0a,D0
L0002248E                       BEQ.W   L000225D0 
L00022492                       CMP.B   #$0b,D0
L00022496                       BEQ.W   L000225E8 
L0002249A                       CMP.B   #$0c,D0
L0002249E                       BEQ.W   L00022600 
L000224A2                       CMP.B   #$0d,D0
L000224A6                       BEQ.W   L0002261E 
L000224AA                       CMP.B   #$0e,D0
L000224AE                       BEQ.W   L0002263E 
L000224B2                       CMP.B   #$0f,D0
L000224B6                       BEQ.W   L00022666 
L000224BA                       RTS 

L000224BC                       MOVE.B  $0003(A6),D0            ; sound command e00/e01 ?
L000224C0                       AND.B   #$01,D0
L000224C4                       ASL.B   #$00000001,D0
L000224C6                       AND.B   #$fd,$00bfe001          ; /LED - filter off
L000224CE                       OR.B    D0,$00bfe001            ; set filter on/off
L000224D4                       RTS 

L000224D6                       MOVE.B  $0003(A6),D0
L000224DA                       AND.B   #$0f,D0
L000224DE                       AND.B   #$f0,$001f(A6)
L000224E4                       OR.B    D0,$001f(A6)
L000224E8                       RTS 

L000224EA                       MOVE.B  $0003(A6),D0
L000224EE                       AND.B   #$0f,D0
L000224F2                       AND.B   #$f0,$001e(A6)
L000224F8                       OR.B    D0,$001e(A6)
L000224FC                       RTS 

L000224FE                       MOVE.B  $0003(A6),D0
L00022502                       AND.B   #$0f,D0
L00022506                       MOVE.B  D0,$0012(A6)
L0002250A                       RTS 

L0002250C                       TST.B   L00022CBD
L00022512                       BNE.W   L00021FD8 
L00022516                       MOVE.B  $0003(A6),D0
L0002251A                       AND.B   #$0f,D0
L0002251E                       BEQ.B   L00022544 
L00022520                       TST.B   $0022(A6)
L00022524                       BEQ.B   L0002253E
L00022526                       SUB.B   #$00000001,$0022(A6)
L0002252A                       BEQ.W   L00021FD8 
L0002252E                       MOVE.B  $0021(A6),$00022CBF
L00022536                       ST.B    L00022CC1 
L0002253C                       RTS 

L0002253E                       MOVE.B  D0,$0022(A6)
L00022542                       BRA.B   L0002252E 
L00022544                       MOVE.W  L00022CC6(PC),D0
L00022548                       LSR.W   #$00000004,D0
L0002254A                       MOVE.B  D0,$0021(A6)
L0002254E                       RTS 

L00022550                       MOVE.B  $0003(A6),D0
L00022554                       AND.B   #$0f,D0
L00022558                       LSL.B   #$00000004,D0
L0002255A                       AND.B   #$0f,$001e(A6)
L00022560                       OR.B    D0,$001e(A6)
L00022564                       RTS 

L00022566                       MOVE.L  D1,-(A7)
L00022568                       MOVE.L  #$00000000,D0
L0002256A                       MOVE.B  $0003(A6),D0
L0002256E                       AND.B   #$0f,D0
L00022572                       BEQ.B   L000225CC 
L00022574                       MOVE.L  #$00000000,D1
L00022576                       MOVE.B  L00022CBD(PC),D1
L0002257A                       BNE.B   L0002258A 
L0002257C                       MOVE.W  (A6),D1
L0002257E                       AND.W   #$0fff,D1
L00022582                       BNE.B   L000225CC 
L00022584                       MOVE.L  #$00000000,D1
L00022586                       MOVE.B  L00022CBD(PC),D1
L0002258A                       DIVU.W  D0,D1
L0002258C                       SWAP.W  D1
L0002258E                       TST.W   D1
L00022590                       BNE.B   L000225CC
L00022592                       MOVE.W  $0014(A6),$00dff096
L0002259A                       MOVE.L  $0004(A6),(A5)
L0002259E                       MOVE.W  $0008(A6),$0004(A5)
L000225A4                       MOVE.W  #$012c,D0
L000225A8                       DBF.W   D0,L000225A8 
L000225AC                       MOVE.W  $0014(A6),D0
L000225B0                       BSET.L  #$000f,D0
L000225B4                       MOVE.W  D0,$00dff096
L000225BA                       MOVE.W  #$012c,D0
L000225BE                       DBF.W   D0,L000225BE 
L000225C2                       MOVE.L  $000a(A6),(A5)
L000225C6                       MOVE.L  $000e(A6),$0004(A5)
L000225CC                       MOVE.L  (A7)+,D1
L000225CE                       RTS 

L000225D0                       TST.B   L00022CBD
L000225D6                       BNE.W   L00021FD8 
L000225DA                       MOVE.L  #$00000000,D0
L000225DC                       MOVE.B  $0003(A6),D0
L000225E0                       AND.B   #$0f,D0
L000225E4                       BRA.W   L0002235C

L000225E8                       TST.B   L00022CBD
L000225EE                       BNE.W   L00021FD8 
L000225F2                       MOVE.L  #$00000000,D0
L000225F4                       MOVE.B  $0003(A6),D0
L000225F8                       AND.B   #$0f,D0
L000225FC                       BRA.W   L00022382 

L00022600                       MOVE.L  #$00000000,D0
L00022602                       MOVE.B  $0003(A6),D0
L00022606                       AND.B   #$0f,D0
L0002260A                       CMP.B   L00022CBD(PC),D0
L0002260E                       BNE.W   L00021FD8 
L00022612                       CLR.B   $0013(A6)
L00022616                       MOVE.W  #$0000,$0008(A5)
L0002261C                       RTS 

L0002261E                       MOVE.L  #$00000000,D0
L00022620                       MOVE.B  $0003(A6),D0
L00022624                       AND.B   #$0f,D0
L00022628                       CMP.B   L00022CBD,D0
L0002262E                       BNE.W   L00021FD8 
L00022632                       MOVE.W  (A6),D0
L00022634                       BEQ.W   L00021FD8 
L00022638                       MOVE.L  D1,-(A7)
L0002263A                       BRA.W   L00022592 

L0002263E                       TST.B   L00022CBD
L00022644                       BNE.W   L00021FD8 
L00022648                       MOVE.L  #$00000000,D0
L0002264A                       MOVE.B  $0003(A6),D0
L0002264E                       AND.B   #$0f,D0
L00022652                       TST.B   L00022CC4
L00022658                       BNE.W   L00021FD8 
L0002265C                       ADD.B   #$00000001,D0
L0002265E                       MOVE.B  D0,L00022CC3
L00022664                       RTS 

L00022666                       TST.B   L00022CBD
L0002266C                       BNE.W   L00021FD8 
L00022670                       MOVE.B  $0003(A6),D0
L00022674                       AND.B   #$0f,D0
L00022678                       LSL.B   #$00000004,D0
L0002267A                       AND.B   #$0f,$001f(A6)
L00022680                       OR.B    D0,$001f(A6)
L00022684                       TST.B   D0
L00022686                       BEQ.W   L00021FD8 
L0002268A                       MOVEM.L D1/A0,-(A7)
L0002268E                       MOVE.L  #$00000000,D0
L00022690                       MOVE.B  $001f(A6),D0
L00022694                       LSR.B   #$00000004,D0
L00022696                       BEQ.B   L000226D6 
L00022698                       LEA.L   L000226DC(PC),A0
L0002269C                       MOVE.B  $00(A0,D0.W),D0
L000226A0                       ADD.B   D0,$0023(A6)
L000226A4                       BTST.B  #$0007,$0023(A6)
L000226AA                       BEQ.B   L000226D6 
L000226AC                       CLR.B   $0023(A6)
L000226B0                       MOVE.L  $000a(A6),D0
L000226B4                       MOVE.L  #$00000000,D1
L000226B6                       MOVE.W  $000e(A6),D1
L000226BA                       ADD.L   D1,D0
L000226BC                       ADD.L   D1,D0
L000226BE                       MOVEA.L $0024(A6),A0
L000226C2                       ADDA.L  #$00000001,A0
L000226C4                       CMPA.L  D0,A0
L000226C6                       BCS.B   L000226CC
L000226C8                       MOVEA.L $000a(A6),A0
L000226CC                       MOVE.L  A0,$0024(A6)
L000226D0                       MOVE.L  #$ffffffff,D0
L000226D2                       SUB.B   (A0),D0
L000226D4                       MOVE.B  D0,(A0)
L000226D6                       MOVEM.L (A7)+,D1/A0
L000226DA                       RTS 



L000226DC                       dc.w    $0005,$0607,$080A,$0B0D,$1013,$161A,$202B,$4080         ;............ +@.
L000226EC                       dc.w    $0018,$314A,$6178,$8DA1,$B4C5,$D4E0,$EBF4,$FAFD         ;..1Jax..........
L000226FC                       dc.w    $FFFD,$FAF4,$EBE0,$D4C5,$B4A1,$8D78,$614A,$3118         ;...........xaJ1.
L0002270C                       dc.w    $0358,$0328,$02FA,$02D0,$02A6,$0280,$025C,$023A         ;.X.(.........\.:
L0002271C                       dc.w    $021A,$01FC,$01E0,$01C5,$01AC,$0194,$017D,$0168         ;.............}.h
L0002272C                       dc.w    $0153,$0140,$012E,$011D,$010D,$00FE,$00F0,$00E2         ;.S.@............
L0002273C                       dc.w    $00D6,$00CA,$00BE,$00B4,$00AA,$00A0,$0097,$008F         ;................
L0002274C                       dc.w    $0087,$007F,$0078,$0071,$0352,$0322,$02F5,$02CB         ;.....x.q.R."....
L0002275C                       dc.w    $02A2,$027D,$0259,$0237,$0217,$01F9,$01DD,$01C2         ;...}.Y.7........
L0002276C                       dc.w    $01A9,$0191,$017B,$0165,$0151,$013E,$012C,$011C         ;.....{.e.Q.>.,..
L0002277C                       dc.w    $010C,$00FD,$00EF,$00E1,$00D5,$00C9,$00BD,$00B3         ;................
L0002278C                       dc.w    $00A9,$009F,$0096,$008E,$0086,$007E,$0077,$0071         ;...........~.w.q
L0002279C                       dc.w    $034C,$031C,$02F0,$02C5,$029E,$0278,$0255,$0233         ;.L.........x.U.3
L000227AC                       dc.w    $0214,$01F6,$01DA,$01BF,$01A6,$018E,$0178,$0163         ;.............x.c
L000227BC                       dc.w    $014F,$013C,$012A,$011A,$010A,$00FB,$00ED,$00E0         ;.O.<.*..........
L000227CC                       dc.w    $00D3,$00C7,$00BC,$00B1,$00A7,$009E,$0095,$008D         ;................
L000227DC                       dc.w    $0085,$007D,$0076,$0070,$0346,$0317,$02EA,$02C0         ;...}.v.p.F......
L000227EC                       dc.w    $0299,$0274,$0250,$022F,$0210,$01F2,$01D6,$01BC         ;...t.P./........
L000227FC                       dc.w    $01A3,$018B,$0175,$0160,$014C,$013A,$0128,$0118         ;.....u.`.L.:.(..
L0002280C                       dc.w    $0108,$00F9,$00EB,$00DE,$00D1,$00C6,$00BB,$00B0         ;................
L0002281C                       dc.w    $00A6,$009D,$0094,$008C,$0084,$007D,$0076,$006F         ;...........}.v.o
L0002282C                       dc.w    $0340,$0311,$02E5,$02BB,$0294,$026F,$024C,$022B         ;.@.........o.L.+
L0002283C                       dc.w    $020C,$01EF,$01D3,$01B9,$01A0,$0188,$0172,$015E         ;.............r.^
L0002284C                       dc.w    $014A,$0138,$0126,$0116,$0106,$00F7,$00E9,$00DC         ;.J.8.&..........
L0002285C                       dc.w    $00D0,$00C4,$00B9,$00AF,$00A5,$009C,$0093,$008B         ;................
L0002286C                       dc.w    $0083,$007C,$0075,$006E,$033A,$030B,$02E0,$02B6         ;...|.u.n.:......
L0002287C                       dc.w    $028F,$026B,$0248,$0227,$0208,$01EB,$01CF,$01B5         ;...k.H.'........
L0002288C                       dc.w    $019D,$0186,$0170,$015B,$0148,$0135,$0124,$0114         ;.....p.[.H.5.$..
L0002289C                       dc.w    $0104,$00F5,$00E8,$00DB,$00CE,$00C3,$00B8,$00AE         ;................
L000228AC                       dc.w    $00A4,$009B,$0092,$008A,$0082,$007B,$0074,$006D         ;...........{.t.m
L000228BC                       dc.w    $0334,$0306,$02DA,$02B1,$028B,$0266,$0244,$0223         ;.4.........f.D.#
L000228CC                       dc.w    $0204,$01E7,$01CC,$01B2,$019A,$0183,$016D,$0159         ;.............m.Y
L000228DC                       dc.w    $0145,$0133,$0122,$0112,$0102,$00F4,$00E6,$00D9         ;.E.3."..........
L000228EC                       dc.w    $00CD,$00C1,$00B7,$00AC,$00A3,$009A,$0091,$0089         ;................
L000228FC                       dc.w    $0081,$007A,$0073,$006D,$032E,$0300,$02D5,$02AC         ;...z.s.m........
L0002290C                       dc.w    $0286,$0262,$023F,$021F,$0201,$01E4,$01C9,$01AF         ;...b.?..........
L0002291C                       dc.w    $0197,$0180,$016B,$0156,$0143,$0131,$0120,$0110         ;.....k.V.C.1. ..
L0002292C                       dc.w    $0100,$00F2,$00E4,$00D8,$00CC,$00C0,$00B5,$00AB         ;................
L0002293C                       dc.w    $00A1,$0098,$0090,$0088,$0080,$0079,$0072,$006C         ;...........y.r.l
L0002294C                       dc.w    $038B,$0358,$0328,$02FA,$02D0,$02A6,$0280,$025C         ;...X.(.........\
L0002295C                       dc.w    $023A,$021A,$01FC,$01E0,$01C5,$01AC,$0194,$017D         ;.:.............}
L0002296C                       dc.w    $0168,$0153,$0140,$012E,$011D,$010D,$00FE,$00F0         ;.h.S.@..........
L0002297C                       dc.w    $00E2,$00D6,$00CA,$00BE,$00B4,$00AA,$00A0,$0097         ;................
L0002298C                       dc.w    $008F,$0087,$007F,$0078,$0384,$0352,$0322,$02F5         ;.......x...R."..
L0002299C                       dc.w    $02CB,$02A3,$027C,$0259,$0237,$0217,$01F9,$01DD         ;.....|.Y.7......
L000229AC                       dc.w    $01C2,$01A9,$0191,$017B,$0165,$0151,$013E,$012C         ;.......{.e.Q.>.,
L000229BC                       dc.w    $011C,$010C,$00FD,$00EE,$00E1,$00D4,$00C8,$00BD         ;................
L000229CC                       dc.w    $00B3,$00A9,$009F,$0096,$008E,$0086,$007E,$0077         ;.............~.w
L000229DC                       dc.w    $037E,$034C,$031C,$02F0,$02C5,$029E,$0278,$0255         ;.~.L.........x.U
L000229EC                       dc.w    $0233,$0214,$01F6,$01DA,$01BF,$01A6,$018E,$0178         ;.3.............x
L000229FC                       dc.w    $0163,$014F,$013C,$012A,$011A,$010A,$00FB,$00ED         ;.c.O.<.*........
L00022A0C                       dc.w    $00DF,$00D3,$00C7,$00BC,$00B1,$00A7,$009E,$0095         ;................
L00022A1C                       dc.w    $008D,$0085,$007D,$0076,$0377,$0346,$0317,$02EA         ;.....}.v.w.F....
L00022A2C                       dc.w    $02C0,$0299,$0274,$0250,$022F,$0210,$01F2,$01D6         ;.....t.P./......
L00022A3C                       dc.w    $01BC,$01A3,$018B,$0175,$0160,$014C,$013A,$0128         ;.......u.`.L.:.(
L00022A4C                       dc.w    $0118,$0108,$00F9,$00EB,$00DE,$00D1,$00C6,$00BB         ;................
L00022A5C                       dc.w    $00B0,$00A6,$009D,$0094,$008C,$0084,$007D,$0076         ;.............}.v
L00022A6C                       dc.w    $0371,$0340,$0311,$02E5,$02BB,$0294,$026F,$024C         ;.q.@.........o.L
L00022A7C                       dc.w    $022B,$020C,$01EE,$01D3,$01B9,$01A0,$0188,$0172         ;.+.............r
L00022A8C                       dc.w    $015E,$014A,$0138,$0126,$0116,$0106,$00F7,$00E9         ;.^.J.8.&........
L00022A9C                       dc.w    $00DC,$00D0,$00C4,$00B9,$00AF,$00A5,$009C,$0093         ;................
L00022AAC                       dc.w    $008B,$0083,$007B,$0075,$036B,$033A,$030B,$02E0         ;.....{.u.k.:....
L00022ABC                       dc.w    $02B6,$028F,$026B,$0248,$0227,$0208,$01EB,$01CF         ;.....k.H.'......
L00022ACC                       dc.w    $01B5,$019D,$0186,$0170,$015B,$0148,$0135,$0124         ;.......p.[.H.5.$
L00022ADC                       dc.w    $0114,$0104,$00F5,$00E8,$00DB,$00CE,$00C3,$00B8         ;................
L00022AEC                       dc.w    $00AE,$00A4,$009B,$0092,$008A,$0082,$007B,$0074         ;.............{.t
L00022AFC                       dc.w    $0364,$0334,$0306,$02DA,$02B1,$028B,$0266,$0244         ;.d.4.........f.D
L00022B0C                       dc.w    $0223,$0204,$01E7,$01CC,$01B2,$019A,$0183,$016D         ;.#.............m
L00022B1C                       dc.w    $0159,$0145,$0133,$0122,$0112,$0102,$00F4,$00E6         ;.Y.E.3."........
L00022B2C                       dc.w    $00D9,$00CD,$00C1,$00B7,$00AC,$00A3,$009A,$0091         ;................
L00022B3C                       dc.w    $0089,$0081,$007A,$0073,$035E,$032E,$0300,$02D5         ;.....z.s.^......
L00022B4C                       dc.w    $02AC,$0286,$0262,$023F,$021F,$0201,$01E4,$01C9         ;.....b.?........
L00022B5C                       dc.w    $01AF,$0197,$0180,$016B,$0156,$0143,$0131,$0120         ;.......k.V.C.1. 
L00022B6C                       dc.w    $0110,$0100,$00F2,$00E4,$00D8,$00CB,$00C0,$00B5         ;................
L00022B7C                       dc.w    $00AB,$00A1,$0098,$0090,$0088,$0080,$0079,$0072         ;.............y.r
L00022B8C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00022B9C                       dc.w    $0000,$0000,$0001,$0000,$0000,$0000,$0000,$0000         ;................
L00022BAC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000

L00022BB8                       dc.w    $0000,$0000         ;................

L00022BBC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00022BCC                       dc.w    $0002,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00022BDC                       dc.w    $0000,$0000,$0000,$0000

L00022BE4                       dc.w    $0000,$0000,$0000,$0000         ;................
L00022BEC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0004,$0000         ;................
L00022BFC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00022C0C                       dc.w    $0000,$0000

L00022C10                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000         ;................
L00022C1C                       dc.w    $0000,$0000,$0000,$0000,$0008,$0000,$0000,$0000         ;................
L00022C2C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00022C3C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00022C4C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00022C5C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00022C6C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00022C7C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00022C8C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00022C9C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00022CAC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000

L00022CB8                       dc.w    $0000
L00022CBA                       dc.w    $0000         ;................

L00022CBC                       dc.b    $06
L00022CBD                       dc.b    $00

L00022CBE                       dc.b    $00
L00022CBF                       dc.b    $00

L00022CC0                       dc.b    $00
L00022CC1                       dc.b    $00
L00022CC2                       dc.b    $00
L00022CC3                       dc.b    $00

L00022CC4                       dc.w    $0000
L00022CC6                       dc.w    $0000
L00022CC8                       dc.w    $0000



                ; ---------------------- copper list ------------------------
                ; copper list that controls the screen display,
                ; sectioned into the following horizontal areas
                ;       1) top logo
                ;       2) menu typer & vector logo (main screen area)
                ;       3) insert disk area (overlaps with bottom of vector logo)
                ;       4) main scroll text
                ;
copper_list     ; original address L00022CCA
                                dc.w    INTREQ,$8010            ; COPER Interrupt (level 3)
                                dc.w    DDFSTRT,$0038
                                dc.w    DDFSTOP,$00D0
                                dc.w    DIWSTRT,$2C81
                                dc.w    DIWSTOP,$2CC1
                                dc.w    BPL1MOD,$0000
                                dc.w    BPL2MOD,$0000
                                dc.w    BPLCON0,$0000
                                dc.w    BPLCON1,$0000
                                dc.w    DMACON,$8020            ; enable sprite DMA
                                dc.w    SPR0PTH         ; $120
sprite_0_pth                    dc.w    $0000           ; original address L00022CF4
                                dc.w    SPR0PTL         ; $0122
sprite_0_ptl                    dc.w    $0000           ; original address L00022CF8
                                dc.w    SPR1PTH         ; $0124
sprite_1_pth                    dc.w    $0000           ; original address L00022CFC
                                dc.w    SPR1PTL         ; $0126
sprite_1_ptl                    dc.w    $0000           ; original address L00022D00
                                dc.w    SPR2PTH         ; $0128
sprite_2_pth                    dc.w    $0000           ; original address L00022D04
                                dc.w    SPR2PTL         ; $012A
sprite_2_ptl                    dc.w    $0000           ; original address L00022D08
                                dc.w    SPR3PTH         ; $012C
sprite_3_pth                    dc.w    $0000           ; original address L00022D0C
                                dc.w    SPR3PTL         ; $012E
sprite_3_ptl                    dc.w    $0000           ; original address L00022D10
                                dc.w    SPR4PTH         ; $0130
sprite_4_pth                    dc.w    $0000           ; original address L00022D14
                                dc.w    SPR4PTL         ; $0132
sprite_4_ptl                    dc.w    $0000           ; original address L00022D18
                                dc.w    SPR5PTH         ; $0134
sprite_5_pth                    dc.w    $0000           ; original address L00022D1C
                                dc.w    SPR5PTL         ; $0136
sprite_5_ptl                    dc.w    $0000           ; original address L00022D20
                                dc.w    SPR6PTH         ; $0138
sprite_6_pth                    dc.w    $0000           ; original address L00022D24
                                dc.w    SPR6PTL         ; $013A
sprite_6_ptl                    dc.w    $0000           ; original address L00022D28
                                dc.w    SPR7PTH         ; $013C
sprite_7_pth                    dc.w    $0000           ; original address L00022D2C
                                dc.w    SPR7PTL         ; $013E
sprite_7_ptl                    dc.w    $0000           ; original address L00022D30

                ; Top Logo Section
copper_top_logo_colors          dc.w    $0180,$0000     ; original address L00022D32
                                dc.w    $0182,$0000
                                dc.w    $0184,$0000
                                dc.w    $0186,$0000
                                dc.w    $0188,$0000
                                dc.w    $018A,$0000
                                dc.w    $018C,$0000
                                dc.w    $018E,$0000
                                dc.w    $0190,$0000
                                dc.w    $0192,$0000
                                dc.w    $0194,$0000
                                dc.w    $0196,$0000
                                dc.w    $0198,$0000
                                dc.w    $019A,$0000
                                dc.w    $019C,$0000
                                dc.w    $019E,$0000
                                dc.w    $2C01,$FFFE     ; start display line 
                                dc.w    BPL1PTH         ; $00E0
toplogo_bpl1pth                 dc.w    $0000           ; original address L00022D78
                                dc.w    BPL1PTL         ; $00E2
toplogo_bpl1ptl                 dc.w    $0000           ; original address L00022D7C
                                dc.w    BPL2PTH         ; $00E4
toplogo_bpl2pth                 dc.w    $0000           ; original address L00022D80
                                dc.w    BPL2PTL         ; $00E6
toplogo_bpl2ptl                 dc.w    $0000           ; original address L00022D84
                                dc.w    BPL3PTH         ; $00E8
toplogo_bpl3pth                 dc.w    $0000           ; original address L00022D88
                                dc.w    BPL3PTL         ; $00EA
toplogo_bpl3ptl                 dc.w    $0000           ; original address L00022D8C
                                dc.w    BPL4PTH         ; $00EC
toplogo_bpl4pth                 dc.w    $0000           ; original address L00022D90
                                dc.w    BPL4PTL         ; $00EE
toplogo_bpl4ptl                 dc.w    $0000           ; original addressw L00022D94
                                dc.w    BPLCON0,$4200   ; 4 bitplanes (320x57) 2280 bytes per plane
                                dc.w    $6501,$FFFE     ; end display line
                                dc.w    BPLCON0,$0000   ; 0 bitplanes

                ; Menu Typer and Vector Logo Section
                                dc.w    $7001,$FFFE
                                dc.w    $0180
                                dc.w    $0002
                                dc.w    $0182
L00022DAC                       dc.w    $0000
L00022DAE                       dc.w    $0184
                                dc.w    $0002
                                dc.w    $0186
                                dc.w    $0002
                                dc.w    $01A0
                                dc.w    $00AA
                                dc.w    $01A2
                                dc.w    $00AA

                        ; start of menu & vector logo display
                        ; 136 rasters high
                                dc.w    $7101,$FFFE
                                dc.w    BPL1PTH         ; $00E0
vector_bplpth                   dc.w    $0000           ; original address L00022DC4
                                dc.w    BPL1PTL         ; $00E2
vector_bplptl                   dc.w    $0000           ; original address L00022DC8
                                dc.w    BPL2PTH         ; $00E4
menu_bpltpth                    dc.w    $0000           ; original address L00022DCC
                                dc.w    BPL2PTL         ; $00E6
menu_bplptl                     dc.w    $0000           ; original address L00022DD0
                                dc.w    BPLCON0         ; $0100
                                dc.w    $2200           ; 2 bitplane screen (spinning logo & menu)
                        ; end of menu typer display

                ; 'insert disk x' message section - rasters high
                                dc.w    $F901,$FFFE
                                dc.w    BPL2PTH         ; $00E4
insertdisk_bplpth               dc.w    $0000           ; original address L00022DDC
                                dc.w    BPL2PTL         ; $00E6
insertdisk_bplptl               dc.w    $0000           ; original address L00022DE0
                                dc.w    BPLCON0         ; $0100
                                dc.w    $2200           ; 2 bitplane screen (spinning logo continues behind)
                                dc.w    $FF01,$FFFE

                                dc.w    $FFDD,$FFFE     ; end of NTSC Wait (allow contination in PAL area below)
                                dc.w    $0180,$0000
                                dc.w    $0182,$0FFF
                                ; switch off bitplanes
                                dc.w    BPLCON0         ; $0100
                                dc.w    $0000           ; 0 bitplanes screen (bitplanes off)
                                ; switch off sprite DMA
                                dc.w    DMACON          ; $0096
                                dc.w    $0020           ; sprite DMA off
                        ; end of menu & vector logo display


                ; Scroll Text Display Section                            
                                dc.w    $0001,$FFFE
                                dc.w    DDFSTRT,$0028           ; start 32 pixels to left of boarder (char = 32 pixels wide) (display = 44 bytes wide * 2)
                                dc.w    DDFSTOP,$00D0
                                dc.w    $0108,$002C
                                dc.w    $010A,$002C
                                dc.w    $0180,$0000
                                dc.w    $0182,$0BBB
                                dc.w    $0184,$0FC6
                                dc.w    $0186,$0FD8
                                dc.w    $0188,$0FDB
                                dc.w    $018A,$0FED
                                dc.w    $018C,$0DDD
                                dc.w    $018E,$0DA4
                                dc.w    $0190,$0C82
                                dc.w    $0192,$0A61
                                dc.w    $0194,$0940
                                dc.w    $0196,$0730
                                dc.w    $0198,$0420
                                dc.w    $019A,$0444
                                dc.w    $019C,$0777
                                dc.w    $019E,$0FFF
                                dc.w    $0101,$FFFE             ; start of scroll display
                                dc.w    BPL1PTH                 ; $00E0
scrolltext_bpl1pth              dc.w    $0000                   ; original address L00022E58
                                dc.w    BPL1PTL                 ;  $00E2 
scrolltext_bpl1ptl              dc.w    $0000                   ; original address L00022E5C
                                dc.w    BPL2PTH                 ; $00E4
scrolltext_bpl2pth              dc.w    $0000                   ; original address L00022E60
                                dc.w    BPL2PTL                 ; $00E6
scrolltext_bpl2ptl              dc.w    $0000                   ; original address L00022E64
                                dc.w    BPL3PTH                 ; $00E8
scrolltext_bpl3pth              dc.w    $0000                   ; original address L00022E68
                                dc.w    BPL3PTL                 ; $00EA 
scrolltext_bpl3ptl              dc.w    $0000                   ; original address L00022E6C
                                dc.w    BPL4PTH                 ; $00EC
scrolltext_bpl4pth              dc.w    $0000                   ; original address L00022E70
                                dc.w    BPL4PTL                 ; $00EE
scrolltext_bpl4ptl              dc.w    $0000                   ; original address L00022E74
                                dc.w    BPLCON0,$4200           ; 4 bitplanes scroller
                                dc.w    BPLCON1
copper_scroller_softscroll      dc.w    $00EE                   ; soft scroll value ; original address L00022E7C

                                dc.w    $1f01,$fffe
                                dc.w    COLOR00,$0008
                                dc.w    BPL1MOD,-(132)           ; modulo for mirror effect
                                dc.w    BPL2MOD,-(132)           ; modulo for mirror effect 
                                dc.w    COLOR00,$0000
                                dc.w    COLOR01,$0555
                                dc.w    COLOR02,$0853
                                dc.w    COLOR03,$0864
                                dc.w    COLOR04,$0865
                                dc.w    COLOR05,$0856
                                dc.w    COLOR06,$0777
                                dc.w    COLOR07,$0752
                                dc.w    COLOR08,$0641
                                dc.w    COLOR09,$0530
                                dc.w    COLOR10,$0420
                                dc.w    COLOR11,$0221
                                dc.w    COLOR12,$0210
                                dc.w    COLOR13,$0222
                                dc.w    COLOR14,$0333
                                dc.w    COLOR15,$0888
                                dc.w    $FFFF,$FFFE




                ; -------------------------- menu display memory buffer --------------------------
                ; typer display: 320 x 136 = 5440 bytes ($1540)
menu_typer_bitplane             ; original address L00022E82
                                dcb.b   40*136,$00



                                ; unused buffer memory?
L000243C2                       dc.w    $0000,$0000,$0000,$0000,$0000 
L000243CC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L000243DC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L000243EC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L000243FC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0002440C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0002441C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0002442C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0002443C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0002444C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0002445C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0002446C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0002447C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0002448C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0002449C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L000244AC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L000244BC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L000244CC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L000244DC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L000244EC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L000244FC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0002450C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0002451C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0002452C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0002453C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0002454C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0002455C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0002456C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0002457C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0002458C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0002459C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L000245AC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L000245BC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L000245CC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L000245DC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L000245EC                       dc.w    $0000,$0000,$0000



                ; 118 bytes wide (944 pixels), 7 rasters high
                ; total bytes = 117 x 7 = 944
menu_font_gfx   ; original address L000245F2
                                include "gfx/typerfont.s"



                ; --------------------- top logo gfx ----------------------
                ; 'Lunatics Infinite Dreams' logo displayed at the top
                ; of the screen. Its a 320x57 - 4 bitplane logo.
                ;
top_logo_gfx    ; original address L000249A2
                incdir  "gfx/"
                include "toplogo.s"




scroll_text_ptr ; original address L00026D42
L00026D42                       dc.l    scroll_text
scroll_text     ; original address L00026D46
L00026D46                       dc.b    "   HELLO AND WELCOME TO A BRAND NEW PRODUCTION BY THE <LUNATICS>, CALLED ..INFINITE DREAMS.. [IN CASE "
L00026DAC                       dc.b    "YOU HADN@T NOTICED=] THIS PRODUCT WAS RELEASED IN THE GLORIOUS YEAR OF OUR LORD 1992, AND CONTAINS SOME OF THE T"
L00026E1C                       dc.b    "UNES COMPOSED BY ME [HOLLYWOOD], SUBCULTURE, AND REEAL IN THE LAST YEAR OR SO. HOPE YOU ENJOY OUR HARD WORK=    "
L00026E8C                       dc.b    " FOR THE TERMINALLY STUPID, YOU CAN SELECT SONGS IN THE PANEL ABOVE, AND THERE SHOULD ALSO BE SOME INFO ABOUT TH"
L00026EFC                       dc.b    "E COMPOSER, LENGTH ETC. SOMEWHERE= IF YOU@D LIKE TO READ THE RAVINGS OF MADMEN, I DIRECT YOU TO LATER ON IN THIS"
L00026F6C                       dc.b    " SCROLLER, WHERE SUBCULTURE AND I SHOULD BE DISPENSING RESPECT @N HANDSHAKES TO THE ELITE= WELL, I GUESS IT@S TI"
L00026FDC                       dc.b    "ME TO GIVE SOME CREDITS TO THIS HUNK OF DATA, AND THESE WILL WING THEIR WAY OUT TO.... CODE: SPONGE HEAD     GRA"
L0002704C                       dc.b    "PHICS: JOE,  TSM,   MUSIC: SUBCULTURE, HOLLYWOOD, REEAL, PHASER.......  NOW THE OFFICIAL STUFF IS OVER, IT@S TIM"
L000270BC                       dc.b    "E FOR ME TO TELL YOU A BIT ABOUT THE SONGS ON THIS DISC, AND THE BIG DIFFERENCES IN STYLE BETWEEN MUSICIANS. I J"
L0002712C                       dc.b    "UST HAVE TO SAY THAT ALL THESE TUNES [EXCEPT THE ONE WHICH STARTS THE DISC OFF] ARE VERY OLD, AND THEREFORE OUR "
L0002719C                       dc.b    "STYLES HAVE IMPROVED A LOT SINCE THESE MODULES WERE COMPOSED. WE STILL FELT THE TUNES WERE GOOD ENOUGH TO RELEAS"
L0002720C                       dc.b    "E, THOUGH= SO, WHILST LISTENING TO ALL THE MODULES ON THIS DISC, YOU MAY NOTICE A BIG DIFFERENCE IN STYLES- I [H"
L0002727C                       dc.b    "OLLYWOOD] THINK OF MY TUNES AS NORMAL SYNTH MUSIC IN MOST CASES- I TRY TO PROVIDE SLIGHTLY DIFFERENT TWISTS ON N"
L000272EC                       dc.b    "ORMAL STYLES, BUT  IT@S VERY DIFFICULT.... HOWEVER, SUBCULTURE@S TUNES ARE VERY MUCH DANCE/RAVE IN STYLE- DOESN@"
L0002735C                       dc.b    "T THIS MAKE FOR AN @UNEVEN@ MUSIC DISC? WELL, I DON@T THINK SO, AS THIS SET-UP PROVIDES A SONG FOR EVERYONE-SO, "
L000273CC                       dc.b    "DANCE DEMONS, I DIRECT YOU TO SUBCULTURE@S TUNES, WHEREAS SYNTH SATYRS HAD BETTER LISTEN TO HOLLYWOOD@S TUNES FI"
L0002743C                       dc.b    "RST. OF COURSE, IF YOU@RE CULTURED, INTELLIGENT ETC., YOU@LL LOVE ALL THE SONGS ON THE DISCS= PERHAPS IT@S NOW T"
L000274AC                       dc.b    "IME FOR ME TO SAY SOMETHING ABOUT EACH OF MY [HOLLYWOOD@S=] TUNES ON THE DISC- JARRESQUE, WHICH SHOULD START THE"
L0002751C                       dc.b    " THING OFF, IS THE ONLY NEW TUNE OF MINE ON THIS DISC- THE GUYS IN FREESTYLE HOLLAND WERE MEANT TO BE USING IT A"
L0002758C                       dc.b    "LSO, BUT I COULDN@T RESIST PUTTING IT IN HERE [SORRY MAGICIAN LORD=] SKYRIDERS IS A NORMAL-ISH SYNTH TUNE WITH Q"
L000275FC                       dc.b    "UITE A MELODIC BEGINNING- IT ORIGINALLY HAD A MASSIVE [250K] SAMPLE FROM THE MUPPETS ON IT, BUT I TOOK IT OFF [B"
L0002766C                       dc.b    "AD QUALITY=] ZERO GRAVITY IS A KIND OF ORGAN-FUNK, WITH A VERY ENIGMA STYLE SNAREDRUM, AND SOME O.K PIANO-BASS. "
L000276DC                       dc.b    "CHECK OUT A NICE @BRIDGE@ SECTION ABOUT 2 AND A HALF MINUTES INTO THE TUNE= SOUND OF SILENCE IS A QUITE SPOOKY B"
L0002774C                       dc.b    "ALLAD WITH VERY LITTLE DRUMS AND SOME NICE VIBRAPHONE SOLOS, WITH A DIDGERIDOO SAMPLE FROM ROXETTE [=??=] BRIGHT"
L000277BC                       dc.b    " IS EXACTLY WHAT IT SAYS- A BRIGHT PIECE WITH SURREAL ECHO-EFFECTS AND SOME VERY WEIRD KEY-CHANGES [C TO C SHARP"
L0002782C                       dc.b    " TO D TO C=] TECHWAR WAS MY FIRST PIECE WHEN I REALISED YOU MUST MAKE A MELODY, THEN BASS AND CHORDS [NOT THE OT"
L0002789C                       dc.b    "HER WAY ROUND=], NATURAL REALITY IS A VERY STRANGE AMBIENTSONG- I DON@T LIKE IT ANYMORE, BUT MAYBE YOU DO= KINDA"
L0002790C                       dc.b    " SPOOKY= FINALLY RETOUCHE IS REALLY QUITE A NEW TUNE, AND SOUNDS A  LITTLE ORDINARY, MAYBE- IT@S STILL CATCHY, I"
L0002797C                       dc.b    " HOPE= THAT FINISHES MY TUNES, AND MY SCROLLER FOR THE MOMENT, BUT I@LL BE BACK WITH A CAUTIONARY TALE LATER- NO"
L000279EC                       dc.b    "W SOME WORDS FROM SUBCULTURE.....     HELLO ALL YOU MUSHIC LOVERSH OUT THERE...          SUBCULTURE THE UNFAZEAB"
L00027A5C                       dc.b    "LE IS BACK ONCE MORE ON YOUR SCREENS...          I@M IN PERFECT CONDITION FOR SCROLLWRITING, IE: I@VE JUST GOT B"
L00027ACC                       dc.b    "ACK FROM THE PUB AFTER DOWNING A PINT OR TEN OF YE OLDE EXTREME NAPALM GUT BREW.  NICELY DRUNK IN OTHER WORDS, S"
L00027B3C                       dc.b    "O LET@S COMMENCE WITH THE TEXT...          FIRST OFF, GO OUT AND BUY @DIGERIDOO@ BY THE APHEX TWIN=  ABSOLUTELY "
L00027BAC                       dc.b    "ESSENTIAL FOR TRIPPING YOUR BRAIN OFF TO=          SECONDLY, MEMBERS OF THE SUBCULTURE FAN CLUB MAY RECOGNISE MO"
L00027C1C                       dc.b    "RE THAN ONE OF MY TUNES ON THIS DISK[S?].  THIS IS BECAUSE I WANTED TO USE THE OPPOTUNITY THIS PRODUCTION GAVE M"
L00027C8C                       dc.b    "E TO USE UP SOME OF THE TUNES I WROTE BEFORE AND DURING MY TIME IN END OF CENTURY 1999.  VIRTUALLY NONE OF MY MORE AMBISHUS [SIC"
L00027D0C                       dc.b    "] [IE: OVER 90K] TUNES WERE EVER USED=  THE OLDEST TUNE HERE WAS WRITTEN OVER A YEAR AGO=== [IN JANUARY 1991=]          ANYWAY, "
L00027D8C                       dc.b    "THAT@S WHY THEY SOUND DIFFERENT TO MY NEWER STUFF, BECAUSE THE SAMPLES ARE OLDER AND MY STYLE HAS CHANGED SINCE I WROTE THEM=  I"
L00027E0C                       dc.b    " THINK THERE ARE A FEW RECENT ONES ON THOUGH...  I CAN@T REMEMBER EXACTLY WHICH TUNES I@VE GOT ON HERE=  ALSO, SOME NEW TUNES FR"
L00027E8C                       dc.b    "OM ME SHOULD BE RELEASED IN THE NEAR FUTURE, POSSIBLY THIS SUMMER, IF THE RAVE MUSIC DISK I WANT TO DO CAN GO AHEAD=          SO"
L00027F0C                       dc.b    ", ON TO MORE IMPORTANT THINGS...          I MAY AS WELL GREET A FEW PEOPLE, SO LISTEN UP...          AZTEC, HOLLYWOOD - LUNATICS"
L00027F8C                       dc.b    "...  MR KIPP - GOLDFIRE...  SIMON - EOC1999...  OHIO - CRUSADERS...  OH ****, I CAN@T REMEMBER ANYONE ELSE, IF I@VE FORGOTTEN YO"
L0002800C                       dc.b    "U I@M SORREEE...  [IT PROBABLY MEANS YOU HAVEN@T WRITTEN IN A WHILE=]          IF YOU TOO WISH TO HAVE YOUR NAME FORGOTTEN IN A "
L0002808C                       dc.b    "SCROLLER BY ME YOU CAN WRITE TO ME AT...          SAM BROWN [WRITE THIS],          *** ****** ****,          ***** **********,  "
L0002810C                       dc.b    "        *****,          ******.,          *******,          ********          BUT PLEASE WRITE BEFORE 30/6/92=  I SHALL BE GOING"
L0002818C                       dc.b    " HOME FOR THE SUMMER HOLIDAYS=  OR YOU CAN E-MAIL THIS NUMBER ON JANET...          *****-**.**.*****.****          RIGHT, I NEED"
L0002820C                       dc.b    " ANOTHER DRINK SO I@M OFF ROUND SOMEONE ELSE@S ROOM [LIFE AT UNI IS ONE LONG PAAAAAAAAAAAAAAARTY ISN@T IT GUYS?  YEAH=], SO I@LL"
L0002828C                       dc.b    " SAY NIGHTY-NIGHT DEAR READER AND PASS YOU OVER TO THE NEXT WRITER WHO IS...  AZTEC     HELLO ALL YOU LUCKY PEOPLE THIS IS AZTEC"
L0002830C                       dc.b    " HERE... JUST THOUGHT I WOULD SAY A FEW WORDS.  I AM RAVE MAD   RAVING MAD  A RAVING LUNATIC  YES THATS WHAT I AM CALLED...  I A"
L0002838C                       dc.b    "M INTO ANY SORT OF MUSIC DISK ON THE AMIGA BUT I PREFER TEKNO AND RAVE HARDCORE THAT SORT OF THING AND I WANT THEM SO SEND THEM "
L0002840C                       dc.b    "TO ME OR YOU CAN JUST WRITE TO ME IF YOU WANT TO GIVE ME A LARGE AMOUNT OF DOSH FOR BEING STUPID OR SIMPLY FOR SOME COOL SWAPS A"
L0002848C                       dc.b    "T THIS ADDRESS.... ** ******** ******      *******      *****      ****-****      ENGLAND OR PHONE ME AT  \**-[*]***-******   PLE"
L0002850C                       dc.b    "ASE NO TIME WASTERS OR LAMERS OR I WILL BE FORSED TO  TO  TO GET NASTY...  NOW A LITTLE MESSAGE OUT THERE TO A FEW PEOPLE WHO MA"
L0002858C                       dc.b    "DE MY LIFE ON THE SCENE THE PAST 3 MONTHS HELL.  A CERTAIN 2 PEOPLE NOT MENTIONING ANY NAMES FORCED A MINITURE WAR BETWEEN ME AN"
L0002860C                       dc.b    "D EOC 1999 THESE PEOPLE WERE STIRING SHIT BETWEEN ME AND EOC 1999 WHICH WAS NOT I REPEAT WAS NOT NOT NOT NOT TRUE ANYWAY NOW IT "
L0002868C                       dc.b    "IS ALL SORTED OUT AND EOC 1999 AND I HAVE SORTED OUT OUR DIFFERENCES THANK GOD FOR THAT..... WELL I AM GOING OF TO WATCH THE 199"
L0002870C                       dc.b    "2 25TH OLYMPICS SO I WILL LEAVE YOU WITH WHOEVER TAKES CONTROL OF THE SPACE CRUSADE... WHAT AM I ON ABOUT I MEAN THE KEYBOARD  L"
L0002878C                       dc.b    "ATERS MAN ............          HI= THIS IS HOLLYWOOD AGAIN, TYPING AWAY AT MY TRUSTY AMIGA. HOPE YOU HAVE ENJOYED THIS NICE MUS"
L0002880C                       dc.b    "IC-DISC SO FAR, AND NOW, I THINK IT IS TIME FOR A LITTLE STORY......         ONCE UPON A TIME THERE WAS A SAD DEMO CREW, AND THE"
L0002888C                       dc.b    "Y LIVED IN THE MIDDLE OF A  BEAUTIFUL ENCHANTED WOOD, AND WHILE NOT PASSING THE TIME LOOKING FOR THEIR BRAINS, THEY DECIDED TO C"
L0002890C                       dc.b    "ODE A LITTLE DEMO. AND THEY BEGAN TO THINK UP IDEAS. THEY WERE RATHER BRAINLESS, SO NATURALLY THIS TOOK A VERY LONG TIME. ANYWAY"
L0002898C                       dc.b    ", AFTER SEVERAL YEARS ONE OF THEM HAD AN AMAZING IDEA. HE HAD THOUGHT TO MAKE THE MOST INNOVATIVE, NEW INTRO EVER, AND HE TOLD A"
L00028A0C                       dc.b    "LL HIS LITTLE PIXIE FRIENDS ABOUT IT. IT WOULD HAVE SOLID VECTORS, A SINE SCROLLER, A LOOONG TITLE SEQUENCE, AND A SCROLLTEXT WH"
L00028A8C                       dc.b    "ICH BOASTED ABOUT HOW THEY WERE..  THE ****** BEST IN THE WORLD. HE THOUGHT THIS QUITE WONDERFUL, AND WENT AWAY TO DO IT AT ONCE"
L00028B0C                       dc.b    "..    MUCH, MUCH LATER, HE RELEASED THIS AMAZING DEMO, AND HE WAS PLEASED, AND HE GOT LOTS OF LETTERS FROM OTHER GROUPS, AND DO "
L00028B8C                       dc.b    "YOU KNOW WHAT? ALL THE OTHER GROUPS SEEMED TO LIVE IN THE MIDDLE OF WOODS AS WELL, AND THEY ALL HAD EXACTLY THE SAME IDEAS AS HI"
L00028C0C                       dc.b    "M==  SO WHAT IS THE MORAL OF THIS STORY?   WELL, I HAVE THIS TO SAY- GET OUT OF THE FOREST AND FACE REALITY, [SOME] DEMO CREWS= "
L00028C8C                       dc.b    "YOU ARE STUCK WITH THE SAME OLD IDEAS, AND PEOPLE ARE GETTING BORED OF THEM= SURE, THIS DEMO ISN@T PERFECT, BUT WE@RE GOING TO T"
L00028D0C                       dc.b    "RY SOMETHING DIFFERENT= MAYBE BUDBRAIN HAD THE RIGHT IDEA, AFTER ALL. SURE, THEY HAVE BEEN OVER-RATED, BUT THEIR STUFF WAS INTER"
L00028D8C                       dc.b    "ESTING==== SO UNLESS YOU GUYS GET OUT OF THE WOODS AND START PRODUCING SOME GOOD STUFF, SOMEONE WILL COME ROUND AND CHOP THE FOR"
L00028E0C                       dc.b    "EST DOWN, AND YOU WITH IT== THEN AT LEAST WE CAN START AGAIN.  ALRIGHT, AFTER THAT LITTLE CAUTIONARY TALE, HERE [FINALLY] ARE MY"
L00028E8C                       dc.b    " PERSONAL GREETS, WHICH WING THEIR WAY TO: AZTEC [HIYA DUDE=], SUBCULTURE [RAVE RULES?=], REEAL [HI=], T.S.M [YOU@RE MAD==], SAN"
L00028F0C                       dc.b    "E, WOODY, AND ALL OTHER LUNATICS MEMBERS WORLDWIDE, JUKEBOX OF TALENT [HOPE YOU LIKE THIS=], WAL OF DUAL CREW, TSAR OF DECAY, WO"
L00028F8C                       dc.b    "JTEK IN POLAND [HELLO??], MERCURE, PETS BAND, AND BRUCE @N LOG OF END OF CENTURY 1999 FRANCE [COOL GUYS=], HYDLIDE OF QUARTZ, TW"
L0002900C                       dc.b    "ILIGHT OF GHOST, AARDVARK P.D [IT@S FINALLY FINISHED==], BUSHBABY OF DAMAGE INC. , AND ALL OTHER ELITE GUYS I KNOW WORLDWIDE== I"
L0002908C                       dc.b    "F YOU WANT TO CONTACT ME FOR ANY REASON [SAMPLE, MODULE, DEMO SWAP??] THEN WRITE TO HOLLYWOOD, ** ********* ******, **********, "
L0002910C                       dc.b    "****** *** ***, ENGLAND. FOR SLOW WRITERS, I@LL DO IT AGAIN-- ** ********* ******, **********, ****** *** ***, ********  WELL, I"
L0002918C                       dc.b    " SHOULD THINK YOU@VE HAD QUITE ENOUGH OF ME BY NOW, BUT I KNOW IT@S IMPORTANT TO HAVE A LOOONG SCROLL ON A MUSIC DISC,  I@LL CAR"
L0002920C                       dc.b    "RY ON FOR A WHILE. WELL, I THINK AN IMPORTANT THING TO TALK ABOUT IS THE SCENE BACKLASH THAT IS  HAPPENING AT THE MOMENT, WITH P"
L0002928C                       dc.b    "EOPLE LIKE MANTRONIX AND TIP AND MAHONEY AND KAKTUS TELLING US ALL THEY@VE FOUND REAL LIFE. MAHONEY AND KAKTUS SEEM TO THINK @TH"
L0002930C                       dc.b    "E BEST PART OF LIFE ISN@T ELECTRIC@- AND I AGREE- UP TO A POINT= I THINK THE POINT IS THAT I COMPOSE MUSIC ON MY AMIGA- I ENJOY "
L0002938C                       dc.b    "IT, AND IT@S CERTAINLY MORE CONSTRUCTIVE THAN GOING OUT EVERY NIGHT AND GETTING DRUNK [HIC=] THAT DOESN@T MEAN I DON@T HAVE A LI"
L0002940C                       dc.b    "FE OUTSIDE MY LITTLE FRONT ROOM WITH THE COMPUTER IN IT, THOUGH= AFTER ALL, IF YOU@RE HAPPY IT DOESN@T MATTER ABOUT ANYTHING ELS"
L0002948C                       dc.b    "E= RIGHT, NEXT THING I@LL DO IS TALK A BIT ABOUT LIFE. AFTER ALL, WHY ARE WE ALL HERE? WHAT IS THE MEANING OF IT ALL? ARE WE ALO"
L0002950C                       dc.b    "NE? WELL, I@M A BIG STAR TREK FAN, AND ALTHOUGH I DON@T ENVISAGE THE FUTURE GOING NECESSARILY LIKE THAT, I THINK WE WILL COLONIS"
L0002958C                       dc.b    "E SPACE IN THE NEXT MILLENIUM. AND IF THERE IS A MEANING TO LIFE, A HELL OF A LOT OF PEOPLE SEEM TO HAVE MISSED IT= SUBJECT CLOS"
L0002960C                       dc.b    "ED= ACTUALLY, I@M TYPING THIS ON A COOL FRIDAY NIGHT IN JUNE, MOST OF MY EXAMS ARE OVER, AND I REALLY CAN@T THINK OF ANYTHING TO"
L0002968C                       dc.b    " WRITE ABOUT. SO I GUESS IT@S TIME TO TALK ABOUT SOMETHING I DID RECENTLY. WELL, A MONTH OR SO AGO I WENT UP TO LONDON, TO THE T"
L0002970C                       dc.b    "ROCADERO IN PICADILLY CIRCUS, ND PLAYED A BRILIANT GAME CALLD QUASAR. I@LL XPLAIN IT TO THSE WHO HAVE MISED OUT ON THE EX"
L0002978C                       dc.b    "PERIENCE. BASICALLY, YOU WEAR A SENSOR JACKET AND GET AN INFRA-RED GUN, AND YOU GET SPLIT UP INTO TWO TEAMS, AND RUN AROUND A MU"
L0002980C                       dc.b    "LTI-LEVEL PLAY AREA SHOOTING AT EACH OTHER. THE OBJECT IS REALLY TO GET TO THE OTHER TEAM@S BASE, BUT I HAD SO MUCH FUN SHOOTING"
L0002988C                       dc.b    " AT ALL THE OTHER GUYS RUNNING AROUND I ONLY GOT THERE ONCE. WHEN YOU GET HIT, YOUR JACKET VIBRATES AND A VOICE FROM YOUR GUN TE"
L0002990C                       dc.b    "LLS YOU YOU@VE BEEN HIT, AND AFTER THREE HITS YOU NEED TO RECHARGE AT THE BOTTOM LEVEL. THE GAME LASTS ABOUT 20 MINUTES, AND IT@"
L0002998C                       dc.b    "S PLAYED WITH REALLY LOUD MUSIC AND FLASHING LIGHTS, WITH ABOUT 20 PEOPLE IN EACH TEAM.  IN THE GAME I PLAYED IN, I GOT THE SECO"
L00029A0C                       dc.b    "ND BEST HIT RATIO IN MY TEAM [50 PERCENT OF MY SHOTS WERE ON TARGET], BUT A NOT SO GOOD POINTS SCORE. WHAT WAS REALLY EMBARRASSI"
L00029A8C                       dc.b    "NG WAS THAT I MANAGED TO HIT MY FRIEND MIKE LOTS [AND LOTS=] OF TIMES, AND HE WAS ON MY TEAM [I ONLY SAW HIM ONCE DURING THE WHO"
L00029B0C                       dc.b    "LE GAME, BUT HE STILL HASN@T FORGIVEN ME= SNIFT=] BUT STILL, THE GAME IS JUST COOL [IF YOU GET AN ESPECIALLY GOOD HIT DOWN THE B"
L00029B8C                       dc.b    "ARREL OF AN OPPONENT@S GUN [LIKE I DID ONCE] YOU GET A VOICE SAYING @GOOD SHOT@] YOU GET ALL YOUR STATISTICS AT THE END OF THE G"
L00029C0C                       dc.b    "AME, ESPECIALLY PRINTED OUT, SO YOU CAN LAUGH AT HOW MANY TIMES YOU HIT PLAYER 9 ON THE OPPOSITE TEAM ETC. SO, IF YOU EVER GET A"
L00029C8C                       dc.b    " CHANCE TO PLAY QUASAR TAKE IT, BUT MAKE SURE THE SIZE OF THE PLAYING AREA IS LARGE ENOUGH [THERE IS A QUASAR CLOSER TO ME, BUT "
L00029D0C                       dc.b    "THE PLAYING AREA IS MUCH TOO SMALL, ADN ONLY ON ONE LEVEL=]......  SO, I HOPE YOU@RE HAVING FUN LISTENING TO OUR MUSIC NOW, PLEA"
L00029D8C                       dc.b    "SE REMEMBER A LOT OF THE TUNES ARE REALLY QUITE OLD [WE@VE GOT BETTER SINCE THEN=] CHANGING THE SUBJECT COMPLETELY AGAIN, LUNATI"
L00029E0C                       dc.b    "CS ARE LOOKING FOR A BBS IN THE U.K, CONTACT ANY OF US FOR MORE DETAILS ON JOINING [WE ALWAYS SEEK ELITE MEMBERS=] THE LUNATICS "
L00029E8C                       dc.b    "ARE EXPANDING A LOT NOW, WITH MEMBERS IN AT LEAST 5 COUNTRIES, AND WE@RE ALWAYS LOOKING FOR MORE FOREIGN MEMBERS AND DIVISIONS, SO, AGAIN, GIVE "
L00029F1C                       dc.b    "US A CALL. NEXT, I REALLY MUST SAY THE CALVIN AND HOBBES REALLY ARE THE FUNNIEST CARTOONS IN THE WORLD, AND IF YOU HAVEN@T EVER "
L00029F9C                       dc.b    "SEEN THE ANTICS OF SPACEMAN SPIFF I SUGGEST YOU CHECK OUT YOUR NEWSPAPER, OR JUST GET NICE PRODUCTS LIKE CRUSADERS BASS-O-MATICS"
L0002A01C                       dc.b    ", OR PLAYBYTE ISSUE 0 [BY SHINING.] ANYWAY, CALVIN AND HOBBES ARE A WHOLE LOT FUNNIER THAN ANY OTHER CARTOONS, IN FACT THEY ARE "
L0002A09C                       dc.b    "JUST BRILLIANT=   PERHAPS IT IS TIME FOR ME TO STOP FOR THE MOMENT NOW, I MIGHT BE BACK, I MIGHT NOT, YOU@LL JUST HAVE TO PRAY F"
L0002A11C                       dc.b    "OR THE RETURN OF THE HOLLYWOOD CREATURE=== BYEEEEE= THIS IS AZTEC ON THE KEYS AND I WOULD JUST LIKE TO SEND OUT A FEW PERSONELL "
L0002A19C                       dc.b    "GREETS AND MESSAGES TO... SANE OF LUNATICS HEY MY GOOD DONT WORRY EVERYTHINK WILL SORT ITS SELF OUT. JOE OF LUNATICS NICE GRAPHI"
L0002A21C                       dc.b    "CS MATE KEEP UP THE COOL ART. SUBCULTURE OF LUNATICS GET ME A RAVE TUNE COMPOSED NOW AND FINISH ALL THOSE UNFINISHED TUNES. HOLL"
L0002A29C                       dc.b    "YWOOD OF LUNATICS HEY LITTLE BOY NICE DOWN TO EARTH TUNES MORE MORE MORE [MUPPETS]. WOODY LUNATICS KEEP UP THE NICE SENDS AND I "
L0002A31C                       dc.b    "HOPE YO FIND THE RIGHT GIRL ONE DAY...   NOW A FEW GREETS TO IN NO ORDER.....     ALL LUNATICS WORLDWIDE EAGLE . REAPER OF DEICI"
L0002A39C                       dc.b    "DE . BRUTUS OF EOC 1999 . GEMINI OF DIMENSION-X . RAZORBLADE OF ALLIANCE . FRAP OF SUPPLEX . MCGRIEVES OF FAKING DUNNO? . ULTIMA"
L0002A41C                       dc.b    "TE WARRIOR AND LEEBOLD OF DUAL CREW . D-MAN OF SKID ROW . JOKER OF PHANTASM . SHORTIE OF SONIC . STEINER OF ALCHEMY . BADCAT OF "
L0002A49C                       dc.b    "IBB . DR.VENOM OF CORIZE . PAULY . AND LASTLY A BIG KISS TO MY GIRLFRIEND KATY WHO I MISS VERY MUCH.........        NOW A FEW GR"
L0002A51C                       dc.b    "EETS FROM JOE OF LUNATICS HOLLAND TO... ALL MEMBERS OF LUNATICS . DESIRE . JETSET . ARIE . THE SPERMBIRD ........               "
L0002A59C                       dc.b    "TEXT RESTARTS ............",$ff,$00



; start of bitplane 0 for the bottom scroll text buffer 
; double buffered display $1508 (5504 bytes wide)

; I think the original allocated too much memoty per bitplane
; try 88*32 = 2816

scroll_text_bpl_0_start         ; original address L0002A5B8
                                dcb.w   44*32,$0000

scroll_text_bpl_1_start
                                dcb.w   44*32,$0000

scroll_text_bpl_2_start
                                dcb.w   44*32,$0000

scroll_text_bpl_3_start
                                dcb.w   44*32,$0000

;
L0002FBB8                       dc.w    $0000,$0000         ;................
L0002FBBC                       dc.w    $0000,$0000,$0000,$0000,$F03D,$E000,$17FF,$FFE8         ;.........=......
L0002FBCC                       dc.w    $00FF,$F400,$17FF,$FFE8,$17FF,$FFE8,$7FFE,$3FFE         ;..............?.
L0002FBDC                       dc.w    $7FFF,$FFE8,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0002FBEC                       dc.w    $0007,$0000,$3C00,$003C,$0080,$1E00,$1C00,$003C         ;....<..<.......<
L0002FBFC                       dc.w    $3C00,$003C,$4002,$2002,$4000,$003C,$0000,$0000         ;<..<@. .@..<....
L0002FC0C                       dc.w    $0000,$0000,$0000,$0000,$F03F,$E000,$7FFF,$FFFE         ;.........?......
L0002FC1C                       dc.w    $00FF,$FF00,$7FFF,$FFFE,$7FFF,$FFFE,$7FFE,$3FFE         ;..............?.
L0002FC2C                       dc.w    $7FFF,$FFFE,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0002FC3C                       dc.w    $F03F,$E000,$3FFF,$FFFC,$00FF,$FE00,$3FFF,$FFFC         ;.?..?.......?...
L0002FC4C                       dc.w    $3FFF,$FFFC,$7FFE,$3FFE,$7FFF,$FFFC,$0000,$0000         ;?.....?.........
L0002FC5C                       dc.w    $0000,$0000,$0000,$0000,$F83F,$E000,$7FFE,$3FFE         ;.........?....?.
L0002FC6C                       dc.w    $001F,$FF00,$7FFE,$3FFE,$7FFE,$3FFE,$7FFE,$3FFE         ;......?...?...?.
L0002FC7C                       dc.w    $7FFE,$3FFE,$0000,$0000,$0000,$0000,$0000,$0000         ;..?.............
L0002FC8C                       dc.w    $F03F,$E000,$7FFE,$3FFE,$001F,$FF00,$7FFE,$3FFE         ;.?....?.......?.
L0002FC9C                       dc.w    $7FFE,$3FFE,$7FFE,$3FFE,$7FFE,$3FFE,$0000,$0000         ;..?...?...?.....
L0002FCAC                       dc.w    $0000,$0000,$0000,$0000,$F7BD,$E000,$7FFE,$3FFE         ;..............?.
L0002FCBC                       dc.w    $001F,$FF00,$7FFE,$3FFE,$7FFE,$3FFE,$7FFE,$3FFE         ;......?...?...?.
L0002FCCC                       dc.w    $7FFE,$3FFE,$0000,$0000,$0000,$0000,$0000,$0000         ;..?.............
L0002FCDC                       dc.w    $F7BD,$E000,$7FFE,$3FFE,$001F,$FF00,$7FFE,$3FFE         ;......?.......?.
L0002FCEC                       dc.w    $7FFE,$3FFE,$7FFE,$3FFE,$7FFE,$3FFE,$0000,$0000         ;..?...?...?.....
L0002FCFC                       dc.w    $0000,$0000,$0000,$0000,$7F3D,$E000,$7FFE,$3FFE         ;.........=....?.
L0002FD0C                       dc.w    $001F,$FF00,$7FFE,$3FFE,$7FFE,$3FFE,$7FFE,$3FFE         ;......?...?...?.
L0002FD1C                       dc.w    $7FFE,$3FFE,$0000,$0000,$0000,$0000,$0000,$0000         ;..?.............
L0002FD2C                       dc.w    $0000,$0000,$7FFE,$3FFE,$001F,$FF00,$7FFE,$3FFE         ;......?.......?.
L0002FD3C                       dc.w    $7FFE,$3FFE,$7FFE,$3FFE,$7FFE,$3FFE,$0000,$0000         ;..?...?...?.....
L0002FD4C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$7FFE,$3FFE         ;..............?.
L0002FD5C                       dc.w    $001F,$FF00,$7FFE,$3FFE,$7FFE,$3FFE,$7FFE,$3FFE         ;......?...?...?.
L0002FD6C                       dc.w    $7FFE,$3FFE,$0000,$0000,$0000,$0000,$0000,$0000         ;..?.............
L0002FD7C                       dc.w    $0000,$0000,$7FFE,$3FFA,$001F,$FF00,$7FFE,$3FFE         ;......?.......?.
L0002FD8C                       dc.w    $7FFE,$3FFA,$7FFE,$3FFE,$7FFE,$3FFE,$0000,$0000         ;..?...?...?.....
L0002FD9C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$7FFE,$3FF2         ;..............?.
L0002FDAC                       dc.w    $001F,$FF00,$0000,$3FFE,$0000,$201C,$7FFE,$3FFE         ;......?... ...?.
L0002FDBC                       dc.w    $7FFE,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0002FDCC                       dc.w    $0000,$0000,$7FFE,$3FE2,$001F,$FF00,$17FF,$FFFC         ;......?.........
L0002FDDC                       dc.w    $0003,$E02E,$3FFF,$FFF2,$7FFF,$FFE8,$0000,$0000         ;....?...........
L0002FDEC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$401E,$3F82         ;............@.?.
L0002FDFC                       dc.w    $001F,$FF00,$391F,$FFFE,$0002,$003C,$7FFF,$FFC2         ;....9......<....
L0002FE0C                       dc.w    $7FF8,$009C,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0002FE1C                       dc.w    $0000,$0000,$4006,$3E02,$001F,$FF00,$7407,$FFFC         ;....@.>.....t...
L0002FE2C                       dc.w    $0002,$003C,$3FFF,$FE02,$7FC0,$002E,$0000,$0000         ;...<?...........
L0002FE3C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$4002,$3002         ;............@.0.
L0002FE4C                       dc.w    $001F,$8100,$2003,$FFE8,$0003,$E02E,$17FF,$E002         ;.... ...........
L0002FE5C                       dc.w    $7FFF,$E004,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0002FE6C                       dc.w    $0000,$0000,$4002,$2002,$0018,$0100,$5002,$0000         ;....@. .....P...
L0002FE7C                       dc.w    $0000,$2004,$0000,$2002,$0000,$200A,$0000,$0000         ;.. ... ... .....
L0002FE8C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$4002,$2002         ;............@. .
L0002FE9C                       dc.w    $0010,$0100,$4002,$3FFE,$7FFE,$200A,$0000,$2002         ;....@.?... ... .
L0002FEAC                       dc.w    $7FFE,$2002,$0000,$0000,$0000,$0000,$0000,$0000         ;.. .............
L0002FEBC                       dc.w    $0000,$0000,$7FFE,$3FFE,$001F,$FF00,$7FFE,$3FFE         ;......?.......?.
L0002FECC                       dc.w    $7FFE,$3FFA,$0000,$3FFE,$7FFE,$3FFE,$0000,$0000         ;..?...?...?.....
L0002FEDC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$4002,$2002         ;............@. .
L0002FEEC                       dc.w    $0010,$0100,$4002,$2002,$4002,$2002,$0000,$2002         ;....@. .@. ... .
L0002FEFC                       dc.w    $4002,$2002,$0000,$0000,$0000,$0000,$0000,$0000         ;@. .............
L0002FF0C                       dc.w    $0000,$0000,$7FFE,$3FFE,$001F,$FF00,$7FFE,$3FFE         ;......?.......?.
L0002FF1C                       dc.w    $7FFE,$3FFE,$0000,$3FFE,$7FFE,$3FFE,$07F8,$0000         ;..?...?...?.....
L0002FF2C                       dc.w    $0000,$0000,$07F8,$0000,$0000,$0000,$4002,$2002         ;............@. .
L0002FF3C                       dc.w    $0010,$0100,$4002,$2002,$4002,$2002,$0000,$2002         ;....@. .@. ... .
L0002FF4C                       dc.w    $4002,$2002,$07F8,$0000,$0000,$0000,$07F8,$0000         ;@. .............
L0002FF5C                       dc.w    $0000,$0000,$7FFE,$3FFE,$001F,$FF00,$7FFE,$3FFE         ;......?.......?.
L0002FF6C                       dc.w    $7FFE,$3FFE,$0000,$3FFE,$7FFE,$3FFE,$0408,$0000         ;..?...?...?.....
L0002FF7C                       dc.w    $0000,$0000,$0408,$0000,$0000,$0000,$4002,$2002         ;............@. .
L0002FF8C                       dc.w    $0010,$0100,$4002,$2002,$4002,$2002,$0000,$2002         ;....@. .@. ... .
L0002FF9C                       dc.w    $4002,$2002,$07F8,$0000,$0000,$0000,$07F8,$0000         ;@. .............
L0002FFAC                       dc.w    $0000,$0000,$7FFE,$3FFE,$001F,$FF00,$7FFE,$3FFE         ;......?.......?.
L0002FFBC                       dc.w    $7FFE,$3FFE,$0000,$3FFE,$7FFE,$3FFE,$0408,$0000         ;..?...?...?.....
L0002FFCC                       dc.w    $0000,$0000,$0408,$0000,$0000,$0000,$2003,$E004         ;............ ...
L0002FFDC                       dc.w    $0010,$0100,$4003,$E002,$2003,$E004,$0000,$2002         ;....@... ..... .
L0002FFEC                       dc.w    $2003,$E004,$07F8,$0000,$0000,$0000,$07F8,$0000         ; ...............
L0002FFFC                       dc.w    $0000,$0000,$7FFF,$FFFE,$001F,$FF00,$7FFF,$FFFE         ;................
L0003000C                       dc.w    $7FFF,$FFFE,$0000,$3FFE,$7FFF,$FFFE,$0078,$0000         ;......?......x..
L0003001C                       dc.w    $0000,$0000,$07F8,$0000,$0000,$0000,$3FFF,$FFFC         ;............?...
L0003002C                       dc.w    $001F,$FF00,$7FFF,$FFFE,$3FFF,$FFFC,$0000,$3FFE         ;........?.....?.
L0003003C                       dc.w    $3FFF,$FFFC,$0078,$0000,$0000,$0000,$07F8,$0000         ;?....x..........
L0003004C                       dc.w    $0000,$0000,$17FF,$FFE8,$001F,$FF00,$7FFF,$FFFE         ;................
L0003005C                       dc.w    $17FF,$FFE8,$0000,$3FFE,$17FF,$FFE8,$0000,$0000         ;......?.........
L0003006C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003007C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003008C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003009C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L000300AC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$2FFF,$FFD0         ;............/...
L000300BC                       dc.w    $2FFF,$FFD0,$2FFF,$FFD0,$2FFF,$FFD0,$0000,$0000         ;/.../.../.......
L000300CC                       dc.w    $01FE,$7F80,$0000,$0000,$001F,$E000,$0000,$0000         ;................
L000300DC                       dc.w    $17FF,$FFE8,$3800,$0078,$7800,$0078,$7800,$0078         ;....8..xx..xx..x
L000300EC                       dc.w    $7800,$0078,$0000,$0000,$0102,$4080,$0001,$0000         ;x..x......@.....
L000300FC                       dc.w    $0010,$2000,$0002,$0000,$1C00,$0038,$FFFF,$FFFC         ;.. ........8....
L0003010C                       dc.w    $FFFF,$FFFC,$FFFF,$FFFC,$FFFF,$FFFC,$0000,$0000         ;................
L0003011C                       dc.w    $01FE,$7F80,$0001,$8000,$001F,$E000,$0006,$0000         ;................
L0003012C                       dc.w    $7FFF,$FFFE,$7FFF,$FFF8,$7FFF,$FFF8,$7FFF,$FFF8         ;................
L0003013C                       dc.w    $7FFF,$FFF8,$0000,$0000,$01FE,$7F80,$0001,$C000         ;................
L0003014C                       dc.w    $001F,$E000,$000E,$0000,$3FFF,$FFFC,$FFFC,$7FFC         ;........?.......
L0003015C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFF8,$FFFC,$003F,$C000         ;.............?..
L0003016C                       dc.w    $01FE,$7F80,$0001,$E000,$001F,$E000,$001E,$0000         ;................
L0003017C                       dc.w    $7FFE,$3FFE,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;..?.............
L0003018C                       dc.w    $FFF8,$FFFC,$003F,$C000,$01FE,$7F80,$0001,$F000         ;.....?..........
L0003019C                       dc.w    $001F,$E000,$003E,$0000,$7FFE,$3FFE,$FFFC,$7FFC         ;.....>....?.....
L000301AC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFF8,$FFFC,$003F,$C000         ;.............?..
L000301BC                       dc.w    $001E,$0780,$0001,$F800,$001F,$E000,$007E,$0000         ;.............~..
L000301CC                       dc.w    $7FFE,$3FFE,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;..?.............
L000301DC                       dc.w    $FFF8,$FFFC,$003F,$C000,$001E,$0780,$0001,$FC00         ;.....?..........
L000301EC                       dc.w    $001F,$E000,$00FE,$0000,$7FFE,$3FFE,$FFFC,$7FFC         ;..........?.....
L000301FC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFF8,$FFFC,$003F,$C000         ;.............?..
L0003020C                       dc.w    $0000,$0000,$0001,$FE00,$001F,$E000,$01FE,$0000         ;................
L0003021C                       dc.w    $7FFE,$3FFE,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;..?.............
L0003022C                       dc.w    $FFF8,$FFFC,$003F,$C000,$0000,$0000,$FFFF,$FF00         ;.....?..........
L0003023C                       dc.w    $001F,$E000,$03FF,$FFFC,$7FFE,$3FFE,$FFFC,$7FFC         ;..........?.....
L0003024C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFF8,$FFFC,$003F,$C000         ;.............?..
L0003025C                       dc.w    $0000,$0000,$FFFF,$FF80,$001F,$E000,$07FF,$FFFC         ;................
L0003026C                       dc.w    $7FFE,$3FFE,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FF4         ;..?.............
L0003027C                       dc.w    $FFF8,$FFFC,$003F,$C000,$0000,$0000,$FFFF,$FFC0         ;.....?..........
L0003028C                       dc.w    $001F,$E000,$0FFF,$FFF4,$7FFE,$3FFE,$FFFC,$0000         ;..........?.....
L0003029C                       dc.w    $0000,$7FFC,$7FFC,$4038,$FFF8,$FFFC,$0000,$0000         ;......@8........
L000302AC                       dc.w    $0000,$0000,$FFFF,$FFE0,$001F,$E000,$1FFF,$FFE4         ;................
L000302BC                       dc.w    $0000,$3FFE,$FFFF,$FFD0,$0007,$FFE4,$FFFF,$C05C         ;..?............\
L000302CC                       dc.w    $7FFF,$FFE4,$0000,$0000,$0000,$0000,$FFFF,$FFF0         ;................
L000302DC                       dc.w    $001F,$E000,$3FFF,$FFC4,$0005,$FFFC,$803F,$FFB8         ;....?........?..
L000302EC                       dc.w    $0007,$FF84,$7FF0,$0078,$FFFF,$FF84,$0000,$0000         ;.......x........
L000302FC                       dc.w    $0000,$0000,$9FFF,$FF88,$001F,$E000,$403F,$FF04         ;............@?..
L0003030C                       dc.w    $0007,$FFFE,$800F,$FC5C,$0007,$FC04,$7F80,$0078         ;.......\.......x
L0003031C                       dc.w    $7FFF,$FC04,$0000,$0000,$0000,$0000,$81FF,$FC18         ;................
L0003032C                       dc.w    $0017,$E000,$600F,$FC04,$001F,$FFF8,$8007,$C008         ;....`...........
L0003033C                       dc.w    $0007,$C004,$FE07,$C05C,$2FFF,$8004,$0000,$0000         ;.......\/.......
L0003034C                       dc.w    $0000,$0000,$807F,$0030,$0011,$E000,$3003,$E004         ;.......0....0...
L0003035C                       dc.w    $0009,$FFE8,$8004,$4014,$0000,$4004,$6004,$4008         ;......@...@.`.@.
L0003036C                       dc.w    $0000,$8004,$003F,$C000,$0000,$0000,$8010,$0060         ;.....?.........`
L0003037C                       dc.w    $0010,$2000,$1800,$0004,$0014,$2000,$8004,$400C         ;.. ....... ...@.
L0003038C                       dc.w    $0000,$4004,$A004,$4014,$FFF8,$8004,$003F,$C000         ;..@...@......?..
L0003039C                       dc.w    $0000,$0000,$8000,$00C0,$0010,$2000,$0C00,$0004         ;.......... .....
L000303AC                       dc.w    $0018,$2000,$FFFC,$7FF4,$0000,$7FFC,$FFFC,$7FF4         ;.. .............
L000303BC                       dc.w    $FFF8,$FFFC,$0020,$4000,$0000,$0000,$FFFF,$FE80         ;..... @.........
L000303CC                       dc.w    $001F,$E000,$05FF,$FFFC,$001F,$E000,$8004,$4004         ;..............@.
L000303DC                       dc.w    $0000,$4004,$8004,$4004,$8008,$8004,$003F,$C000         ;..@...@......?..
L000303EC                       dc.w    $0000,$0000,$FFFF,$0300,$0010,$2000,$0303,$FFFC         ;.......... .....
L000303FC                       dc.w    $0010,$2000,$FFFC,$7FFC,$0000,$7FFC,$FFFC,$7FFC         ;.. .............
L0003040C                       dc.w    $FFF8,$FFFC,$0020,$4000,$0000,$0000,$0001,$FA00         ;..... @.........
L0003041C                       dc.w    $001F,$E000,$017E,$0000,$001F,$E000,$8004,$4004         ;.....~........@.
L0003042C                       dc.w    $0000,$4004,$8004,$4004,$8008,$8004,$003F,$C000         ;..@...@......?..
L0003043C                       dc.w    $0000,$0000,$0001,$0C00,$0010,$2000,$00C2,$0000         ;.......... .....
L0003044C                       dc.w    $0010,$2000,$FFFC,$7FFC,$0000,$7FFC,$FFFC,$7FFC         ;.. .............
L0003045C                       dc.w    $FFF8,$FFFC,$0020,$4000,$0000,$0000,$0001,$E800         ;..... @.........
L0003046C                       dc.w    $001F,$E000,$005E,$0000,$001F,$E000,$8004,$4004         ;.....^........@.
L0003047C                       dc.w    $0000,$4004,$8004,$4004,$8008,$8004,$003F,$C000         ;..@...@......?..
L0003048C                       dc.w    $0000,$0000,$0001,$3000,$001F,$E000,$0032,$0000         ;......0......2..
L0003049C                       dc.w    $001F,$E000,$FFFC,$7FFC,$0000,$7FFC,$FFFC,$7FFC         ;................
L000304AC                       dc.w    $FFF8,$FFFC,$0000,$0000,$0000,$0000,$0001,$E000         ;................
L000304BC                       dc.w    $0000,$0000,$001E,$0000,$0000,$0000,$4007,$C008         ;............@...
L000304CC                       dc.w    $0000,$4004,$4007,$C008,$400F,$8008,$0000,$0000         ;..@.@...@.......
L000304DC                       dc.w    $0000,$0000,$0001,$4000,$001F,$E000,$000A,$0000         ;......@.........
L000304EC                       dc.w    $001F,$E000,$FFFF,$FFFC,$0000,$7FFC,$FFFF,$FFFC         ;................
L000304FC                       dc.w    $FFFF,$FFFC,$0000,$0000,$0000,$0000,$0001,$8000         ;................
L0003050C                       dc.w    $001F,$E000,$0006,$0000,$001F,$E000,$7FFF,$FFF8         ;................
L0003051C                       dc.w    $0000,$7FFC,$7FFF,$FFF8,$7FFF,$FFF8,$0000,$0000         ;................
L0003052C                       dc.w    $0000,$0000,$0001,$0000,$001F,$E000,$0002,$0000         ;................
L0003053C                       dc.w    $001F,$E000,$2FFF,$FFD0,$0000,$7FFC,$2FFF,$FFD0         ;..../......./...
L0003054C                       dc.w    $2FFF,$FFD0,$0000,$0000,$0000,$0000,$0000,$0000         ;/...............
L0003055C                       dc.w    $001F,$E000,$0000,$0000,$001F,$E000,$0000,$0000         ;................
L0003056C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003057C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003058C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003059C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L000305AC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0FF0,$0000         ;................
L000305BC                       dc.w    $2FFF,$FFD0,$FFFF,$FFD0,$2FFF,$FFD0,$FFFF,$FFD0         ;/......./.......
L000305CC                       dc.w    $2FFF,$FFD0,$2FFF,$FFD0,$2FFF,$FFD0,$FFFC,$7FFC         ;/.../.../.......
L000305DC                       dc.w    $07FF,$FFC0,$0810,$0000,$3800,$0070,$8000,$0070         ;........8..p...p
L000305EC                       dc.w    $3800,$0070,$8000,$0070,$3800,$0070,$3800,$0070         ;8..p...p8..p8..p
L000305FC                       dc.w    $3800,$0070,$8004,$4004,$0400,$0040,$0FF0,$0000         ;8..p..@....@....
L0003060C                       dc.w    $FFFF,$FFFC,$FFFF,$FFFC,$FFFF,$FFFC,$FFFF,$FFFC         ;................
L0003061C                       dc.w    $FFFF,$FFFC,$FFFF,$FFFC,$FFFF,$FFFC,$FFFC,$7FFC         ;................
L0003062C                       dc.w    $07FF,$FFC0,$0FF0,$0000,$7FFF,$FFF8,$FFFF,$FFF8         ;................
L0003063C                       dc.w    $7FFF,$FFF8,$FFFF,$FFF8,$7FFF,$FFF8,$7FFF,$FFF8         ;................
L0003064C                       dc.w    $7FFF,$FFF8,$FFFC,$7FFC,$07FF,$FFC0,$0FF0,$0000         ;................
L0003065C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003066C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003067C                       dc.w    $007F,$FC00,$0FF0,$0000,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003068C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003069C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$007F,$FC00,$00F0,$0000         ;................
L000306AC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L000306BC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L000306CC                       dc.w    $007F,$FC00,$00F0,$0000,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L000306DC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L000306EC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$007F,$FC00,$0000,$0000         ;................
L000306FC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003070C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003071C                       dc.w    $007F,$FC00,$0000,$0000,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003072C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003073C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$007F,$FC00,$0000,$0000         ;................
L0003074C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003075C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003076C                       dc.w    $007F,$FC00,$0000,$0000,$FFFC,$7FFC,$FFFC,$7FF4         ;................
L0003077C                       dc.w    $FFFC,$7FFC,$FFFC,$7FF4,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003078C                       dc.w    $FFFC,$7FFC,$FFFC,$7FF4,$007F,$FC00,$0000,$0000         ;................
L0003079C                       dc.w    $FFFC,$7FFC,$FFFC,$4038,$FFFC,$0000,$FFFC,$7FE4         ;......@8........
L000307AC                       dc.w    $FFFC,$0000,$FFFC,$0000,$FFFC,$0004,$FFFC,$7FE4         ;................
L000307BC                       dc.w    $007F,$FC00,$0000,$0000,$FFFF,$FFE4,$FFFF,$C05C         ;...............\
L000307CC                       dc.w    $FFFC,$0000,$FFFC,$7FC4,$FFFF,$C000,$FFFF,$C000         ;................
L000307DC                       dc.w    $FFFD,$FFFC,$FFFF,$FFC4,$007F,$FC00,$0000,$0000         ;................
L000307EC                       dc.w    $9FFF,$FF84,$FFF0,$0078,$9FFC,$0000,$803C,$7F04         ;.......x.....<..
L000307FC                       dc.w    $9FFF,$C000,$FFF0,$4000,$9FFD,$FF84,$803F,$FF04         ;......@......?..
L0003080C                       dc.w    $007F,$FC00,$0000,$0000,$81FF,$FC04,$FF80,$0078         ;...............x
L0003081C                       dc.w    $81FC,$0000,$800C,$7C04,$81FF,$C000,$FF80,$4000         ;......|.......@.
L0003082C                       dc.w    $81FD,$FC04,$800F,$FC04,$004F,$FC00,$0000,$0000         ;.........O......
L0003083C                       dc.w    $807F,$C004,$FE07,$C05C,$807C,$0000,$8004,$6004         ;.......\.|....`.
L0003084C                       dc.w    $807F,$C000,$FE07,$C000,$807D,$C004,$8007,$E004         ;.........}......
L0003085C                       dc.w    $0043,$E400,$0000,$0000,$8014,$4004,$C004,$4008         ;.C........@...@.
L0003086C                       dc.w    $8014,$0000,$8004,$4004,$8014,$0000,$C004,$0000         ;......@.........
L0003087C                       dc.w    $8014,$4004,$8004,$4004,$0040,$0400,$0000,$0000         ;..@...@..@......
L0003088C                       dc.w    $8004,$4004,$8004,$4014,$8004,$7FFC,$8004,$4004         ;..@...@.......@.
L0003089C                       dc.w    $8004,$7FFC,$8004,$0000,$8004,$4004,$8004,$4004         ;..........@...@.
L000308AC                       dc.w    $0040,$0400,$0000,$0000,$FFFC,$7FFC,$FFFC,$7FF4         ;.@..............
L000308BC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$0000         ;................
L000308CC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$007F,$FC00,$0000,$0000         ;................
L000308DC                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L000308EC                       dc.w    $8004,$4004,$8004,$0000,$8004,$4004,$8004,$4004         ;..@.......@...@.
L000308FC                       dc.w    $0040,$0400,$0000,$0000,$FFFC,$7FFC,$FFFC,$7FFC         ;.@..............
L0003090C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$0000         ;................
L0003091C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$007F,$FC00,$0000,$0000         ;................
L0003092C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L0003093C                       dc.w    $8004,$4004,$8004,$0000,$8004,$4004,$8004,$4004         ;..@.......@...@.
L0003094C                       dc.w    $0040,$0400,$0000,$0000,$FFFC,$7FFC,$FFFC,$7FFC         ;.@..............
L0003095C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$0000         ;................
L0003096C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$007F,$FC00,$0000,$0000         ;................
L0003097C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L0003098C                       dc.w    $8004,$4004,$8004,$0000,$8004,$4004,$8004,$4004         ;..@.......@...@.
L0003099C                       dc.w    $0040,$0400,$0000,$0000,$FFFC,$7FFC,$FFFC,$7FFC         ;.@..............
L000309AC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$0000         ;................
L000309BC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$007F,$FC00,$0000,$0000         ;................
L000309CC                       dc.w    $8004,$4004,$8007,$C008,$4007,$C008,$8007,$C008         ;..@.....@.......
L000309DC                       dc.w    $4007,$C008,$8004,$0000,$4007,$C004,$8004,$4004         ;@.......@.....@.
L000309EC                       dc.w    $07C0,$07C0,$0000,$0000,$FFFC,$7FFC,$FFFF,$FFFC         ;................
L000309FC                       dc.w    $FFFF,$FFFC,$FFFF,$FFFC,$FFFF,$FFFC,$FFFC,$0000         ;................
L00030A0C                       dc.w    $FFFF,$FFFC,$FFFC,$7FFC,$07FF,$FFC0,$0000,$0000         ;................
L00030A1C                       dc.w    $FFFC,$7FFC,$FFFF,$FFF8,$7FFF,$FFF8,$FFFF,$FFF8         ;................
L00030A2C                       dc.w    $7FFF,$FFF8,$FFFC,$0000,$7FFF,$FFFC,$FFFC,$7FFC         ;................
L00030A3C                       dc.w    $07FF,$FFC0,$0000,$0000,$FFFC,$7FFC,$FFFF,$FFD0         ;................
L00030A4C                       dc.w    $2FFF,$FFD0,$FFFF,$FFD0,$2FFF,$FFD0,$FFFC,$0000         ;/......./.......
L00030A5C                       dc.w    $2FFF,$FFFC,$FFFC,$7FFC,$07FF,$FFC0,$0000,$0000         ;/...............
L00030A6C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00030A7C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00030A8C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00030A9C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00030AAC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0007,$FFFC         ;................
L00030ABC                       dc.w    $FFFC,$7FFC,$FFFC,$0000,$FFF8,$3FFC,$FFFF,$FFD0         ;..........?.....
L00030ACC                       dc.w    $2FFF,$FFD0,$FFFF,$FFD0,$2FFF,$FFD0,$FFFF,$FFD0         ;/......./.......
L00030ADC                       dc.w    $2FFF,$FFD0,$0004,$0004,$8004,$4004,$8004,$0000         ;/.........@.....
L00030AEC                       dc.w    $800C,$6004,$8000,$0070,$7800,$0078,$8000,$0070         ;..`....px..x...p
L00030AFC                       dc.w    $3800,$0070,$8000,$0070,$3800,$0070,$0007,$FFFC         ;8..p...p8..p....
L00030B0C                       dc.w    $FFFC,$7FFC,$FFFC,$0000,$FFFE,$FFFC,$FFFF,$FFFC         ;................
L00030B1C                       dc.w    $FFFF,$FFFC,$FFFF,$FFFC,$FFFF,$FFFC,$FFFF,$FFFC         ;................
L00030B2C                       dc.w    $FFFF,$FFFC,$0007,$FFFC,$FFFC,$7FFC,$FFFC,$0000         ;................
L00030B3C                       dc.w    $FFFF,$FFFC,$FFFF,$FFF8,$7FFF,$FFF8,$FFFF,$FFF8         ;................
L00030B4C                       dc.w    $7FFF,$FFF8,$FFFF,$FFF8,$7FFF,$FFF8,$0000,$7FFC         ;................
L00030B5C                       dc.w    $FFFC,$7FFC,$FFFC,$0000,$FFFF,$FFFC,$FFFC,$7FFC         ;................
L00030B6C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L00030B7C                       dc.w    $FFFC,$7FFC,$0000,$7FFC,$FFFC,$7FFC,$FFFC,$0000         ;................
L00030B8C                       dc.w    $FFFF,$FFFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L00030B9C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$0000,$7FFC         ;................
L00030BAC                       dc.w    $FFFC,$7FFC,$FFFC,$0000,$FFFF,$FFFC,$FFFC,$7FFC         ;................
L00030BBC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L00030BCC                       dc.w    $FFFC,$7FFC,$0000,$7FFC,$FFFC,$7FFC,$FFFC,$0000         ;................
L00030BDC                       dc.w    $FFFF,$FFFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L00030BEC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$0000,$7FFC         ;................
L00030BFC                       dc.w    $FFFC,$7FFC,$FFFC,$0000,$FFFD,$7FFC,$FFFC,$7FFC         ;................
L00030C0C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L00030C1C                       dc.w    $FFFC,$7FFC,$0000,$7FFC,$FFFC,$7FFC,$FFFC,$0000         ;................
L00030C2C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L00030C3C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$0000,$7FFC         ;................
L00030C4C                       dc.w    $FFFC,$7FFC,$FFFC,$0000,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L00030C5C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L00030C6C                       dc.w    $FFFC,$7FFC,$0000,$7FFC,$FFFC,$7FF4,$FFFC,$0000         ;................
L00030C7C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L00030C8C                       dc.w    $FFFC,$7FF4,$FFFC,$7FFC,$FFFC,$7FFC,$0000,$7FFC         ;................
L00030C9C                       dc.w    $FFFC,$4038,$FFFC,$0000,$FFFC,$7FFC,$FFFC,$403C         ;..@8..........@<
L00030CAC                       dc.w    $FFFC,$403C,$FFFC,$7FFC,$FFFC,$7FE4,$FFFC,$7FF8         ;..@<............
L00030CBC                       dc.w    $FFFC,$0000,$0000,$7FE4,$FFFF,$C05C,$FFFC,$0000         ;...........\....
L00030CCC                       dc.w    $FFFC,$7FE4,$FFFC,$400C,$FFFC,$400C,$FFFF,$FFF8         ;......@...@.....
L00030CDC                       dc.w    $FFFC,$7FC4,$FFFF,$FFFC,$7FFF,$FFD0,$0000,$7F84         ;................
L00030CEC                       dc.w    $FFF0,$0078,$803C,$0000,$9FFC,$7F84,$FFF4,$4004         ;...x.<........@.
L00030CFC                       dc.w    $FFF4,$4004,$9FFF,$FFFC,$803C,$7F04,$9FFF,$FFF8         ;..@......<......
L00030D0C                       dc.w    $FFFF,$FFB0,$0000,$7C04,$FF80,$0078,$800C,$0000         ;......|....x....
L00030D1C                       dc.w    $81FC,$7C04,$FF84,$4004,$FF84,$4004,$81FF,$FFF0         ;..|...@...@.....
L00030D2C                       dc.w    $800C,$7C04,$81FF,$FC38,$3FFF,$FC5C,$0000,$4004         ;..|....8?..\..@.
L00030D3C                       dc.w    $FE07,$C05C,$8004,$0000,$807C,$4004,$FE04,$4004         ;...\.....|@...@.
L00030D4C                       dc.w    $FE04,$4004,$807F,$FFD0,$8004,$6004,$807F,$C05C         ;..@.......`....\
L00030D5C                       dc.w    $2FFF,$C008,$0000,$4004,$C004,$4008,$8004,$0000         ;/.....@...@.....
L00030D6C                       dc.w    $8014,$4004,$C004,$4004,$C004,$4004,$8014,$0000         ;..@...@...@.....
L00030D7C                       dc.w    $8004,$4004,$8014,$4008,$0000,$4014,$FFFC,$4004         ;..@...@...@...@.
L00030D8C                       dc.w    $8004,$4014,$8004,$7FFC,$8004,$4004,$8004,$4004         ;..@.......@...@.
L00030D9C                       dc.w    $8004,$4004,$8004,$0000,$8004,$4004,$8004,$4014         ;..@.......@...@.
L00030DAC                       dc.w    $FFFC,$400C,$FFFC,$7FFC,$FFFC,$7FF4,$FFFC,$7FFC         ;..@.............
L00030DBC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$0000         ;................
L00030DCC                       dc.w    $FFFC,$7FFC,$FFFC,$7FF4,$FFFC,$7FF4,$8004,$4004         ;..............@.
L00030DDC                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L00030DEC                       dc.w    $8004,$4004,$8004,$0000,$8004,$4004,$8004,$4004         ;..@.......@...@.
L00030DFC                       dc.w    $8004,$4004,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;..@.............
L00030E0C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$0000         ;................
L00030E1C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$8004,$4004         ;..............@.
L00030E2C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L00030E3C                       dc.w    $8004,$4004,$8004,$0000,$8004,$4004,$8004,$4004         ;..@.......@...@.
L00030E4C                       dc.w    $8004,$4004,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;..@.............
L00030E5C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$0000         ;................
L00030E6C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$8004,$4004         ;..............@.
L00030E7C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L00030E8C                       dc.w    $8004,$4004,$8004,$0000,$8004,$4004,$8004,$4004         ;..@.......@...@.
L00030E9C                       dc.w    $8004,$4004,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;..@.............
L00030EAC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$0000         ;................
L00030EBC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$4007,$C008         ;............@...
L00030ECC                       dc.w    $8004,$4004,$4007,$C008,$8004,$4004,$8004,$4004         ;..@.@.....@...@.
L00030EDC                       dc.w    $4007,$C008,$8004,$0000,$4007,$C004,$8004,$4004         ;@.......@.....@.
L00030EEC                       dc.w    $4007,$C008,$FFFF,$FFFC,$FFFC,$7FFC,$FFFF,$FFFC         ;@...............
L00030EFC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFF,$FFFC,$FFFC,$0000         ;................
L00030F0C                       dc.w    $FFFF,$FFFC,$FFFC,$7FFC,$FFFF,$FFFC,$7FFF,$FFF8         ;................
L00030F1C                       dc.w    $FFFC,$7FFC,$7FFF,$FFF8,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L00030F2C                       dc.w    $7FFF,$FFF8,$FFFC,$0000,$7FFF,$FFFC,$FFFC,$7FFC         ;................
L00030F3C                       dc.w    $7FFF,$FFF8,$2FFF,$FFD0,$FFFC,$7FFC,$2FFF,$FFD0         ;..../......./...
L00030F4C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$2FFF,$FFD0,$FFFC,$0000         ;......../.......
L00030F5C                       dc.w    $2FFF,$FFFC,$FFFC,$7FFC,$2FFF,$FFD0,$0000,$0000         ;/......./.......
L00030F6C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00030F7C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00030F8C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00030F9C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00030FAC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$FFFC,$0000         ;................
L00030FBC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFF8,$FFFC,$FFFC,$7FFC         ;................
L00030FCC                       dc.w    $FFFC,$7FFC,$2FFF,$FFFC,$005F,$FF00,$0000,$0000         ;..../...._......
L00030FDC                       dc.w    $00FF,$FA00,$8004,$0000,$8004,$4004,$8004,$4004         ;..........@...@.
L00030FEC                       dc.w    $8008,$8004,$8004,$4004,$8004,$4004,$7800,$0004         ;......@...@.x...
L00030FFC                       dc.w    $00F0,$0100,$0000,$0000,$0080,$0F00,$FFFC,$0000         ;................
L0003100C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFF8,$FFFC,$FFFC,$7FFC         ;................
L0003101C                       dc.w    $FFFC,$7FFC,$FFFF,$FFFC,$01FF,$FF00,$0000,$0000         ;................
L0003102C                       dc.w    $00FF,$FF80,$FFFC,$0000,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003103C                       dc.w    $FFF8,$FFFC,$FFFC,$7FFC,$FFFC,$7FFC,$7FFF,$FFFC         ;................
L0003104C                       dc.w    $00FF,$FF00,$00FF,$FC00,$00FF,$FF00,$FFFC,$0000         ;................
L0003105C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFF8,$FFFC,$FFFC,$7FFC         ;................
L0003106C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$01FF,$F000,$00FF,$FC00         ;................
L0003107C                       dc.w    $000F,$FF80,$FFFC,$0000,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003108C                       dc.w    $FFF8,$FFFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003109C                       dc.w    $01FF,$F000,$00FF,$FC00,$000F,$FF80,$FFFC,$0000         ;................
L000310AC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFF8,$FFFC,$FFFC,$7FFC         ;................
L000310BC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$01FF,$F000,$00FF,$FC00         ;................
L000310CC                       dc.w    $000F,$FF80,$FFFC,$0000,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L000310DC                       dc.w    $FFF8,$FFFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L000310EC                       dc.w    $01FF,$F000,$00FF,$FC00,$000F,$FF80,$FFFC,$0000         ;................
L000310FC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFF8,$FFFC,$FFFC,$7FFC         ;................
L0003110C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$01FF,$F000,$00FF,$FC00         ;................
L0003111C                       dc.w    $000F,$FF80,$FFFC,$0000,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003112C                       dc.w    $FFF8,$FFFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003113C                       dc.w    $01FF,$F000,$00FF,$FC00,$000F,$FF80,$FFFC,$0000         ;................
L0003114C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFF8,$FFFC,$FFFC,$7FFC         ;................
L0003115C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$01FF,$F000,$00FF,$FC00         ;................
L0003116C                       dc.w    $000F,$FF80,$FFFC,$0000,$FFFC,$7FF4,$FFFC,$7FFC         ;................
L0003117C                       dc.w    $FFF8,$FFF4,$FFFC,$7FF4,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003118C                       dc.w    $01FF,$F000,$00FF,$FC00,$000F,$FF80,$FFFC,$0000         ;................
L0003119C                       dc.w    $FFFC,$7FE4,$FFFC,$7FFC,$FFF8,$FFE4,$7FFC,$4038         ;..............@8
L000311AC                       dc.w    $FFFC,$7FFC,$0000,$7FFC,$01FF,$F000,$00FF,$8400         ;................
L000311BC                       dc.w    $000F,$FF80,$FFFF,$C000,$FFFC,$7FC4,$FFFC,$7FE4         ;................
L000311CC                       dc.w    $FFF8,$FFC4,$FFFF,$C05C,$7FFF,$FFE4,$2FFF,$FFF8         ;.......\..../...
L000311DC                       dc.w    $01FF,$F000,$0FFC,$07C0,$000F,$FF80,$FFF0,$4000         ;..............@.
L000311EC                       dc.w    $803C,$7F04,$9FFC,$7F84,$8038,$FF04,$7FF0,$0078         ;.<.......8.....x
L000311FC                       dc.w    $FFFF,$FF84,$723F,$FFFC,$011F,$F000,$0FF0,$0040         ;....r?.........@
L0003120C                       dc.w    $000F,$FF80,$FF80,$4000,$800C,$7C04,$81FC,$7C04         ;......@...|...|.
L0003121C                       dc.w    $8008,$FC04,$7F80,$0078,$7FFF,$FC04,$E80F,$FFF8         ;.......x........
L0003122C                       dc.w    $0107,$F000,$0F80,$0040,$000F,$F880,$FE07,$C000         ;.......@........
L0003123C                       dc.w    $8004,$6004,$807C,$4004,$8008,$E004,$FE07,$C05C         ;..`..|@........\
L0003124C                       dc.w    $2FFF,$C004,$4007,$FFD0,$0101,$F000,$0F80,$07C0         ;/...@...........
L0003125C                       dc.w    $000E,$0080,$C004,$0000,$8004,$4004,$8014,$4004         ;..........@...@.
L0003126C                       dc.w    $8008,$8004,$6004,$4008,$0000,$4004,$A004,$0000         ;....`.@...@.....
L0003127C                       dc.w    $0100,$1000,$0080,$0400,$0008,$0080,$8004,$7FFC         ;................
L0003128C                       dc.w    $8004,$4004,$8004,$4004,$8008,$8004,$A004,$4014         ;..@...@.......@.
L0003129C                       dc.w    $FFFC,$4004,$8004,$7FFC,$0100,$1000,$0080,$0400         ;..@.............
L000312AC                       dc.w    $0008,$0080,$FFFC,$7FFC,$FFFC,$7FFC,$BFFC,$7FF4         ;................
L000312BC                       dc.w    $FFFA,$FFFC,$FFFC,$7FF4,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L000312CC                       dc.w    $01FF,$F000,$00FF,$FC00,$000F,$FF80,$8004,$4004         ;..............@.
L000312DC                       dc.w    $8004,$4004,$6004,$4018,$800D,$8004,$8004,$4004         ;..@.`.@.......@.
L000312EC                       dc.w    $8004,$4004,$8004,$4004,$0100,$1000,$0080,$0400         ;..@...@.........
L000312FC                       dc.w    $0008,$0080,$FFFC,$7FFC,$FFFC,$7FFC,$2FFC,$7FD0         ;............/...
L0003130C                       dc.w    $FFFF,$FFFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003131C                       dc.w    $01FF,$F000,$00FF,$FC00,$000F,$FF80,$8004,$4004         ;..............@.
L0003132C                       dc.w    $8004,$4004,$1004,$4020,$8000,$0004,$8004,$4004         ;..@...@ ......@.
L0003133C                       dc.w    $8004,$4004,$8004,$4004,$0100,$1000,$0080,$0400         ;..@...@.........
L0003134C                       dc.w    $0008,$0080,$FFFC,$7FFC,$FFFC,$7FFC,$0FFC,$7FC0         ;................
L0003135C                       dc.w    $FFFF,$FFFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003136C                       dc.w    $01FF,$F000,$00FF,$FC00,$000F,$FF80,$8004,$4004         ;..............@.
L0003137C                       dc.w    $8004,$4004,$0404,$4080,$8000,$0004,$8004,$4004         ;..@...@.......@.
L0003138C                       dc.w    $8004,$4004,$8004,$4004,$0100,$1000,$0080,$0400         ;..@...@.........
L0003139C                       dc.w    $0008,$0080,$FFFC,$7FFC,$FFFC,$7FFC,$03FC,$7F00         ;................
L000313AC                       dc.w    $FFFF,$FFFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L000313BC                       dc.w    $01FF,$F000,$00FF,$FC00,$000F,$FF80,$4007,$C008         ;............@...
L000313CC                       dc.w    $4007,$C008,$0107,$C200,$4005,$0008,$8004,$4004         ;@.......@.....@.
L000313DC                       dc.w    $4007,$C008,$8007,$C008,$0080,$1F00,$00FF,$FC00         ;@...............
L000313EC                       dc.w    $00F8,$0100,$FFFF,$FFFC,$FFFF,$FFFC,$00FF,$FC00         ;................
L000313FC                       dc.w    $FFFF,$FFFC,$FFFC,$7FFC,$FFFF,$FFFC,$FFFF,$FFFC         ;................
L0003140C                       dc.w    $01FF,$FF00,$0000,$0000,$00FF,$FF80,$7FFF,$FFF8         ;................
L0003141C                       dc.w    $7FFF,$FFF8,$007F,$F800,$7FFD,$FFF8,$FFFC,$7FFC         ;................
L0003142C                       dc.w    $7FFF,$FFF8,$FFFF,$FFF8,$00FF,$FF00,$0000,$0000         ;................
L0003143C                       dc.w    $00FF,$FF00,$2FFF,$FFD0,$2FFF,$FFD0,$003F,$F000         ;..../.../....?..
L0003144C                       dc.w    $2FE8,$BFD0,$FFFC,$7FFC,$2FFF,$FFD0,$FFFF,$FFD0         ;/......./.......
L0003145C                       dc.w    $005F,$FF00,$0000,$0000,$00FF,$FA00,$0000,$0000         ;._..............
L0003146C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003147C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003148C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003149C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L000314AC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L000314BC                       dc.w    $0000,$0000,$0000,$0000,$F03D,$E000,$0BFF,$FFD0         ;.........=......
L000314CC                       dc.w    $00FF,$E800,$0BFF,$FFD0,$0BFF,$FFD0,$7FFE,$3FFE         ;..............?.
L000314DC                       dc.w    $7FFF,$FFD0,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L000314EC                       dc.w    $0007,$0000,$0800,$0010,$0080,$0800,$0800,$0010         ;................
L000314FC                       dc.w    $0800,$0010,$4002,$2002,$4000,$0010,$0000,$0000         ;....@. .@.......
L0003150C                       dc.w    $0000,$0000,$0000,$0000,$0002,$0000,$1000,$0008         ;................
L0003151C                       dc.w    $0080,$0400,$1000,$0008,$1000,$0008,$4002,$2002         ;............@. .
L0003152C                       dc.w    $4000,$0008,$0000,$0000,$0000,$0000,$0000,$0000         ;@...............
L0003153C                       dc.w    $0000,$0000,$6003,$E006,$00F0,$0300,$6003,$E006         ;....`.......`...
L0003154C                       dc.w    $6003,$E006,$4002,$2002,$4003,$E006,$0000,$0000         ;`...@. .@.......
L0003155C                       dc.w    $0000,$0000,$0000,$0000,$0002,$0000,$0002,$2000         ;.............. .
L0003156C                       dc.w    $0010,$0000,$0002,$2000,$0002,$2000,$4002,$2002         ;...... ... .@. .
L0003157C                       dc.w    $4002,$2000,$0000,$0000,$0000,$0000,$0000,$0000         ;@. .............
L0003158C                       dc.w    $0002,$0000,$4002,$2002,$0010,$0100,$4002,$2002         ;....@. .....@. .
L0003159C                       dc.w    $4002,$2002,$4002,$2002,$4002,$2002,$0000,$0000         ;@. .@. .@. .....
L000315AC                       dc.w    $0000,$0000,$0000,$0000,$8080,$0000,$4002,$2002         ;............@. .
L000315BC                       dc.w    $0010,$0100,$4002,$2002,$4002,$2002,$4002,$2002         ;....@. .@. .@. .
L000315CC                       dc.w    $4002,$2002,$0000,$0000,$0000,$0000,$0000,$0000         ;@. .............
L000315DC                       dc.w    $8080,$0000,$4002,$2002,$0010,$0100,$4002,$2002         ;....@. .....@. .
L000315EC                       dc.w    $4002,$2002,$4002,$2002,$4002,$2002,$0000,$0000         ;@. .@. .@. .....
L000315FC                       dc.w    $0000,$0000,$0000,$0000,$6300,$0000,$4002,$2002         ;........c...@. .
L0003160C                       dc.w    $0010,$0100,$4002,$2002,$4002,$2002,$4002,$2002         ;....@. .@. .@. .
L0003161C                       dc.w    $4002,$2002,$0000,$0000,$0000,$0000,$0000,$0000         ;@. .............
L0003162C                       dc.w    $0000,$0000,$4002,$2002,$0010,$0100,$4002,$2002         ;....@. .....@. .
L0003163C                       dc.w    $4002,$2002,$4002,$2002,$4002,$2002,$0000,$0000         ;@. .@. .@. .....
L0003164C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$4002,$2006         ;............@. .
L0003165C                       dc.w    $0010,$0100,$4002,$2002,$4002,$2002,$4002,$2002         ;....@. .@. .@. .
L0003166C                       dc.w    $4002,$2002,$0000,$0000,$0000,$0000,$0000,$0000         ;@. .............
L0003167C                       dc.w    $0000,$0000,$4002,$2006,$0010,$0100,$7FFE,$2002         ;....@. ....... .
L0003168C                       dc.w    $7FFE,$2004,$4002,$2002,$4002,$3FFE,$0000,$0000         ;.. .@. .@.?.....
L0003169C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$4002,$200E         ;............@. .
L000316AC                       dc.w    $0010,$0100,$0000,$2000,$0000,$28A6,$0002,$2006         ;...... ...(... .
L000316BC                       dc.w    $4002,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;@...............
L000316CC                       dc.w    $0000,$0000,$4002,$2032,$0010,$0100,$0BFF,$E006         ;....@. 2........
L000316DC                       dc.w    $0003,$E018,$6003,$E00A,$4003,$FFD0,$0000,$0000         ;....`...@.......
L000316EC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$68B2,$2052         ;............h. R
L000316FC                       dc.w    $0010,$0100,$0EB0,$0008,$0003,$0010,$1000,$006A         ;...............j
L0003170C                       dc.w    $400D,$0070,$0000,$0000,$0000,$0000,$0000,$0000         ;@..p............
L0003171C                       dc.w    $0000,$0000,$602E,$2342,$0010,$0300,$182C,$0010         ;....`.#B.....,..
L0003172C                       dc.w    $0002,$0010,$0800,$0342,$4068,$0018,$0000,$0000         ;.......B@h......
L0003173C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$400A,$3A02         ;............@.:.
L0003174C                       dc.w    $0010,$D100,$700B,$FFD0,$0003,$E018,$0BFF,$F002         ;....p...........
L0003175C                       dc.w    $7FFF,$E00E,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003176C                       dc.w    $0000,$0000,$4002,$2002,$001D,$0100,$2002,$0000         ;....@. ..... ...
L0003177C                       dc.w    $0000,$200E,$0000,$2002,$0000,$2004,$0000,$0000         ;.. ... ... .....
L0003178C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$4002,$2002         ;............@. .
L0003179C                       dc.w    $0010,$0100,$6002,$3FFE,$7FFE,$2004,$0000,$2002         ;....`.?... ... .
L000317AC                       dc.w    $7FFE,$2006,$0000,$0000,$0000,$0000,$0000,$0000         ;.. .............
L000317BC                       dc.w    $0000,$0000,$7FFE,$3FFE,$001F,$FF00,$5FFE,$3FFE         ;......?....._.?.
L000317CC                       dc.w    $7FFE,$3FFE,$0000,$3FFE,$7FFE,$3FFA,$0000,$0000         ;..?...?...?.....
L000317DC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$7FFE,$3FFE         ;..............?.
L000317EC                       dc.w    $001F,$FF00,$7FFE,$3FFE,$7FFE,$3FFE,$0000,$3FFE         ;......?...?...?.
L000317FC                       dc.w    $7FFE,$3FFE,$0000,$0000,$0000,$0000,$0000,$0000         ;..?.............
L0003180C                       dc.w    $0000,$0000,$4002,$2002,$0010,$0100,$4002,$2002         ;....@. .....@. .
L0003181C                       dc.w    $4002,$2002,$0000,$2002,$4002,$2002,$07F8,$0000         ;@. ... .@. .....
L0003182C                       dc.w    $0000,$0000,$07F8,$0000,$0000,$0000,$4002,$2002         ;............@. .
L0003183C                       dc.w    $0010,$0100,$4002,$2002,$4002,$2002,$0000,$2002         ;....@. .@. ... .
L0003184C                       dc.w    $4002,$2002,$07F8,$0000,$0000,$0000,$07F8,$0000         ;@. .............
L0003185C                       dc.w    $0000,$0000,$7FFE,$3FFE,$001F,$FF00,$7FFE,$3FFE         ;......?.......?.
L0003186C                       dc.w    $7FFE,$3FFE,$0000,$3FFE,$7FFE,$3FFE,$07F8,$0000         ;..?...?...?.....
L0003187C                       dc.w    $0000,$0000,$07F8,$0000,$0000,$0000,$7FFE,$3FFE         ;..............?.
L0003188C                       dc.w    $001F,$FF00,$7FFE,$3FFE,$7FFE,$3FFE,$0000,$3FFE         ;......?...?...?.
L0003189C                       dc.w    $7FFE,$3FFE,$07F8,$0000,$0000,$0000,$07F8,$0000         ;..?.............
L000318AC                       dc.w    $0000,$0000,$3FFE,$3FFC,$001F,$FF00,$7FFE,$3FFE         ;....?.?.......?.
L000318BC                       dc.w    $3FFE,$3FFC,$0000,$3FFE,$3FFE,$3FFC,$0408,$0000         ;?.?...?.?.?.....
L000318CC                       dc.w    $0000,$0000,$0408,$0000,$0000,$0000,$6003,$E006         ;............`...
L000318DC                       dc.w    $0010,$0100,$4003,$E002,$6003,$E006,$0000,$2002         ;....@...`..... .
L000318EC                       dc.w    $6003,$E006,$07C8,$0000,$0000,$0000,$0408,$0000         ;`...............
L000318FC                       dc.w    $0000,$0000,$1000,$0008,$0010,$0100,$4000,$0002         ;............@...
L0003190C                       dc.w    $1000,$0008,$0000,$2002,$1000,$0008,$0078,$0000         ;...... ......x..
L0003191C                       dc.w    $0000,$0000,$07F8,$0000,$0000,$0000,$0FFF,$FFF0         ;................
L0003192C                       dc.w    $001F,$FF00,$7FFF,$FFFE,$0FFF,$FFF0,$0000,$3FFE         ;..............?.
L0003193C                       dc.w    $0FFF,$FFF0,$0078,$0000,$0000,$0000,$07F8,$0000         ;.....x..........
L0003194C                       dc.w    $0000,$0000,$0BFF,$FFD0,$001F,$FF00,$7FFF,$FFFE         ;................
L0003195C                       dc.w    $0BFF,$FFD0,$0000,$3FFE,$0BFF,$FFD0,$0000,$0000         ;......?.........
L0003196C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003197C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003198C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003199C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L000319AC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$17FF,$FFA0         ;................
L000319BC                       dc.w    $17FF,$FFA0,$17FF,$FFA0,$17FF,$FFA0,$0000,$0000         ;................
L000319CC                       dc.w    $01FE,$7F80,$0001,$0000,$001F,$E000,$0002,$0000         ;................
L000319DC                       dc.w    $0BFF,$FFD0,$1000,$0020,$1000,$0020,$1000,$0020         ;....... ... ... 
L000319EC                       dc.w    $1000,$0020,$0000,$0000,$0102,$4080,$0001,$8000         ;... ......@.....
L000319FC                       dc.w    $0010,$2000,$0006,$0000,$0800,$0010,$2000,$0010         ;.. ......... ...
L00031A0C                       dc.w    $2000,$0010,$2000,$0010,$2000,$0010,$0000,$0000         ; ... ... .......
L00031A1C                       dc.w    $0102,$4080,$0001,$C000,$0010,$2000,$000E,$0000         ;..@....... .....
L00031A2C                       dc.w    $1000,$0008,$C007,$C00C,$C007,$C00C,$C007,$C00C         ;................
L00031A3C                       dc.w    $C00F,$800C,$0000,$0000,$0102,$4080,$0001,$6000         ;..........@...`.
L00031A4C                       dc.w    $0010,$2000,$001A,$0000,$6003,$E006,$0004,$4000         ;.. .....`.....@.
L00031A5C                       dc.w    $0004,$4000,$0004,$4000,$0008,$8000,$003F,$C000         ;..@...@......?..
L00031A6C                       dc.w    $0102,$4080,$0001,$3000,$0010,$2000,$0032,$0000         ;..@...0... ..2..
L00031A7C                       dc.w    $0002,$2000,$8004,$4004,$8004,$4004,$8004,$4004         ;.. ...@...@...@.
L00031A8C                       dc.w    $8008,$8004,$0020,$4000,$01F2,$7C80,$0001,$1800         ;..... @...|.....
L00031A9C                       dc.w    $0010,$2000,$0062,$0000,$4002,$2002,$8004,$4004         ;.. ..b..@. ...@.
L00031AAC                       dc.w    $8004,$4004,$8004,$4004,$8008,$8004,$0020,$4000         ;..@...@...... @.
L00031ABC                       dc.w    $0012,$0480,$0001,$0C00,$0010,$2000,$00C2,$0000         ;.......... .....
L00031ACC                       dc.w    $4002,$2002,$8004,$4004,$8004,$4004,$8004,$4004         ;@. ...@...@...@.
L00031ADC                       dc.w    $8008,$8004,$0020,$4000,$001E,$0780,$0001,$0600         ;..... @.........
L00031AEC                       dc.w    $0010,$2000,$0182,$0000,$4002,$2002,$8004,$4004         ;.. .....@. ...@.
L00031AFC                       dc.w    $8004,$4004,$8004,$4004,$8008,$8004,$0020,$4000         ;..@...@...... @.
L00031B0C                       dc.w    $0000,$0000,$0001,$0300,$0010,$2000,$0302,$0000         ;.......... .....
L00031B1C                       dc.w    $4002,$2002,$8004,$4004,$8004,$4004,$8004,$4004         ;@. ...@...@...@.
L00031B2C                       dc.w    $8008,$8004,$0020,$4000,$0000,$0000,$FFFF,$0180         ;..... @.........
L00031B3C                       dc.w    $0010,$2000,$0603,$FFFC,$4002,$2002,$8004,$400C         ;.. .....@. ...@.
L00031B4C                       dc.w    $8004,$4004,$8004,$4004,$8008,$8004,$0020,$4000         ;..@...@...... @.
L00031B5C                       dc.w    $0000,$0000,$8000,$00C0,$0010,$2000,$0C00,$000C         ;.......... .....
L00031B6C                       dc.w    $4002,$2002,$8004,$7FFC,$FFFC,$4004,$0004,$4008         ;@. .......@...@.
L00031B7C                       dc.w    $8008,$8004,$003F,$C000,$0000,$0000,$8000,$0060         ;.....?.........`
L00031B8C                       dc.w    $0010,$2000,$1800,$000C,$7FFE,$2002,$8004,$0000         ;.. ....... .....
L00031B9C                       dc.w    $0000,$400C,$C004,$514C,$0008,$800C,$0000,$0000         ;..@...QL........
L00031BAC                       dc.w    $0000,$0000,$8000,$0030,$0010,$2000,$3000,$001C         ;.......0.. .0...
L00031BBC                       dc.w    $0000,$2000,$8007,$FFA0,$0007,$C014,$2007,$C030         ;.. ......... ..0
L00031BCC                       dc.w    $C00F,$8014,$0000,$0000,$0000,$0000,$C000,$0018         ;................
L00031BDC                       dc.w    $0010,$2000,$6000,$0064,$0002,$E006,$D160,$0060         ;.. .`..d.....`.`
L00031BEC                       dc.w    $0004,$00D4,$101A,$0020,$2000,$00D4,$0000,$0000         ;.......  .......
L00031BFC                       dc.w    $0000,$0000,$B000,$00CC,$0010,$2000,$D160,$00A4         ;.......... ..`..
L00031C0C                       dc.w    $0002,$0008,$C058,$06B0,$0004,$0684,$10D0,$0020         ;.....X......... 
L00031C1C                       dc.w    $1000,$0684,$0000,$0000,$0000,$0000,$8A00,$069C         ;................
L00031C2C                       dc.w    $001C,$2000,$E058,$0684,$0004,$0010,$8017,$E01C         ;.. ..X..........
L00031C3C                       dc.w    $0007,$E004,$2347,$C030,$17FF,$A004,$0000,$0000         ;....#G.0........
L00031C4C                       dc.w    $0000,$0000,$8281,$A038,$001B,$2000,$7016,$3404         ;.......8.. .p.4.
L00031C5C                       dc.w    $001B,$3FD0,$8004,$4008,$0000,$4004,$C804,$401C         ;..?...@...@...@.
L00031C6C                       dc.w    $0000,$8004,$003F,$C000,$0000,$0000,$80BA,$0070         ;.....?.........p
L00031C7C                       dc.w    $0012,$2000,$3804,$4004,$000E,$2000,$8004,$400C         ;.. .8.@... ...@.
L00031C8C                       dc.w    $0000,$4004,$6004,$4008,$FFF8,$8004,$003F,$C000         ;..@.`.@......?..
L00031C9C                       dc.w    $0000,$0000,$8000,$00E0,$0010,$2000,$1C00,$0004         ;.......... .....
L00031CAC                       dc.w    $0018,$2000,$FFFC,$7FFC,$0000,$7FFC,$FFFC,$7FFC         ;.. .............
L00031CBC                       dc.w    $FFF8,$FFFC,$003F,$C000,$0000,$0000,$FFFF,$FFC0         ;.....?..........
L00031CCC                       dc.w    $001F,$E000,$0FFF,$FFFC,$001F,$E000,$FFFC,$7FFC         ;................
L00031CDC                       dc.w    $0000,$7FFC,$FFFC,$7FFC,$FFF8,$FFFC,$0020,$4000         ;............. @.
L00031CEC                       dc.w    $0000,$0000,$FFFF,$FD80,$001F,$E000,$06FF,$FFFC         ;................
L00031CFC                       dc.w    $001F,$E000,$8004,$4004,$0000,$4004,$8004,$4004         ;......@...@...@.
L00031D0C                       dc.w    $8008,$8004,$0020,$4000,$0000,$0000,$0001,$0300         ;..... @.........
L00031D1C                       dc.w    $0010,$2000,$0302,$0000,$0010,$2000,$8004,$4004         ;.. ....... ...@.
L00031D2C                       dc.w    $0000,$4004,$8004,$4004,$8008,$8004,$003F,$C000         ;..@...@......?..
L00031D3C                       dc.w    $0000,$0000,$0001,$0E00,$0010,$2000,$01C2,$0000         ;.......... .....
L00031D4C                       dc.w    $0010,$2000,$FFFC,$7FFC,$0000,$7FFC,$FFFC,$7FFC         ;.. .............
L00031D5C                       dc.w    $FFF8,$FFFC,$003F,$C000,$0000,$0000,$0001,$FC00         ;.....?..........
L00031D6C                       dc.w    $001F,$E000,$00FE,$0000,$001F,$E000,$FFFC,$7FFC         ;................
L00031D7C                       dc.w    $0000,$7FFC,$FFFC,$7FFC,$FFF8,$FFFC,$003F,$C000         ;.............?..
L00031D8C                       dc.w    $0000,$0000,$0001,$F800,$001F,$E000,$007E,$0000         ;.............~..
L00031D9C                       dc.w    $001F,$E000,$7FFC,$7FF8,$0000,$7FFC,$7FFC,$7FF8         ;................
L00031DAC                       dc.w    $7FF8,$FFF8,$0000,$0000,$0000,$0000,$0001,$F000         ;................
L00031DBC                       dc.w    $0000,$0000,$003E,$0000,$0000,$0000,$C007,$C00C         ;.....>..........
L00031DCC                       dc.w    $0000,$4004,$C007,$C00C,$C00F,$800C,$0000,$0000         ;..@.............
L00031DDC                       dc.w    $0000,$0000,$0001,$6000,$001F,$E000,$001A,$0000         ;......`.........
L00031DEC                       dc.w    $001F,$E000,$2000,$0010,$0000,$4004,$2000,$0010         ;.... .....@. ...
L00031DFC                       dc.w    $2000,$0010,$0000,$0000,$0000,$0000,$0001,$C000         ; ...............
L00031E0C                       dc.w    $0010,$2000,$000E,$0000,$0010,$2000,$1FFF,$FFE0         ;.. ....... .....
L00031E1C                       dc.w    $0000,$7FFC,$1FFF,$FFE0,$1FFF,$FFE0,$0000,$0000         ;................
L00031E2C                       dc.w    $0000,$0000,$0001,$8000,$001F,$E000,$0006,$0000         ;................
L00031E3C                       dc.w    $001F,$E000,$17FF,$FFA0,$0000,$7FFC,$17FF,$FFA0         ;................
L00031E4C                       dc.w    $17FF,$FFA0,$0000,$0000,$0000,$0000,$0001,$0000         ;................
L00031E5C                       dc.w    $001F,$E000,$0002,$0000,$001F,$E000,$0000,$0000         ;................
L00031E6C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00031E7C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00031E8C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00031E9C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00031EAC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0FF0,$0000         ;................
L00031EBC                       dc.w    $17FF,$FFA0,$FFFF,$FFA0,$17FF,$FFA0,$FFFF,$FFA0         ;................
L00031ECC                       dc.w    $17FF,$FFA0,$17FF,$FFA0,$17FF,$FFA0,$FFFC,$7FFC         ;................
L00031EDC                       dc.w    $07FF,$FFC0,$0810,$0000,$1000,$0020,$8000,$0020         ;........... ... 
L00031EEC                       dc.w    $1000,$0020,$8000,$0020,$1000,$0020,$1000,$0020         ;... ... ... ... 
L00031EFC                       dc.w    $1000,$0020,$8004,$4004,$0400,$0040,$0810,$0000         ;... ..@....@....
L00031F0C                       dc.w    $2000,$0010,$8000,$0010,$2000,$0010,$8000,$0010         ; ....... .......
L00031F1C                       dc.w    $2000,$0010,$2000,$0010,$2000,$0010,$8004,$4004         ; ... ... .....@.
L00031F2C                       dc.w    $0400,$0040,$0810,$0000,$C007,$C00C,$8007,$C00C         ;...@............
L00031F3C                       dc.w    $C007,$C00C,$8007,$C00C,$C007,$C00C,$C007,$C00C         ;................
L00031F4C                       dc.w    $C007,$C00C,$8004,$4004,$07C0,$07C0,$0810,$0000         ;......@.........
L00031F5C                       dc.w    $0004,$4000,$8004,$4000,$0004,$4000,$8004,$4000         ;..@...@...@...@.
L00031F6C                       dc.w    $0004,$4000,$0004,$4000,$0004,$4000,$8004,$4004         ;..@...@...@...@.
L00031F7C                       dc.w    $0040,$0400,$0F90,$0000,$8004,$4004,$8004,$4004         ;.@........@...@.
L00031F8C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L00031F9C                       dc.w    $8004,$4004,$8004,$4004,$0040,$0400,$0090,$0000         ;..@...@..@......
L00031FAC                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L00031FBC                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L00031FCC                       dc.w    $0040,$0400,$00F0,$0000,$8004,$4004,$8004,$4004         ;.@........@...@.
L00031FDC                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L00031FEC                       dc.w    $8004,$4004,$8004,$4004,$0040,$0400,$0000,$0000         ;..@...@..@......
L00031FFC                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L0003200C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L0003201C                       dc.w    $0040,$0400,$0000,$0000,$8004,$4004,$8004,$4004         ;.@........@...@.
L0003202C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L0003203C                       dc.w    $8004,$4004,$8004,$4004,$0040,$0400,$0000,$0000         ;..@...@..@......
L0003204C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$400C         ;..@...@...@...@.
L0003205C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$400C         ;..@...@...@...@.
L0003206C                       dc.w    $0040,$0400,$0000,$0000,$8004,$4004,$8004,$4008         ;.@........@...@.
L0003207C                       dc.w    $8004,$7FFC,$8004,$400C,$8004,$7FFC,$8004,$7FFC         ;......@.........
L0003208C                       dc.w    $8004,$7FFC,$8004,$400C,$0040,$0400,$0000,$0000         ;......@..@......
L0003209C                       dc.w    $8004,$400C,$8004,$514C,$8004,$0000,$8004,$401C         ;..@...QL......@.
L000320AC                       dc.w    $8004,$0000,$8004,$0000,$8004,$0004,$8004,$401C         ;..............@.
L000320BC                       dc.w    $0040,$0400,$0000,$0000,$C007,$C014,$8007,$C030         ;.@.............0
L000320CC                       dc.w    $C004,$0000,$8004,$4064,$C007,$C000,$8007,$C000         ;......@d........
L000320DC                       dc.w    $C005,$FFFC,$8007,$C064,$0040,$0400,$0000,$0000         ;.......d.@......
L000320EC                       dc.w    $B000,$00D4,$801A,$0020,$B004,$0000,$D164,$40A4         ;....... .....d@.
L000320FC                       dc.w    $B000,$4000,$801A,$4000,$B005,$00D4,$D160,$00A4         ;..@...@......`..
L0003210C                       dc.w    $0060,$0400,$0000,$0000,$8A00,$0684,$80D0,$0020         ;.`............. 
L0003211C                       dc.w    $8A04,$0000,$C05C,$4684,$8A00,$4000,$80D0,$4000         ;.....\F...@...@.
L0003212C                       dc.w    $8A05,$0684,$C058,$0684,$0058,$0400,$0000,$0000         ;.....X...X......
L0003213C                       dc.w    $8287,$E004,$8347,$C030,$8284,$0000,$8014,$7404         ;.....G.0......t.
L0003214C                       dc.w    $8287,$C000,$8347,$C000,$8285,$E004,$8017,$F404         ;.....G..........
L0003215C                       dc.w    $0056,$3400,$0000,$0000,$80BC,$4004,$E804,$401C         ;.V4.......@...@.
L0003216C                       dc.w    $80BC,$0000,$8004,$4004,$80BC,$0000,$E804,$0000         ;......@.........
L0003217C                       dc.w    $80BC,$4004,$8004,$4004,$0044,$4400,$0000,$0000         ;..@...@..DD.....
L0003218C                       dc.w    $8004,$4004,$8004,$4008,$8004,$7FFC,$8004,$4004         ;..@...@.......@.
L0003219C                       dc.w    $8004,$7FFC,$8004,$0000,$8004,$4004,$8004,$4004         ;..........@...@.
L000321AC                       dc.w    $0040,$0400,$0000,$0000,$FFFC,$7FFC,$FFFC,$7FFC         ;.@..............
L000321BC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$0000         ;................
L000321CC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$007F,$FC00,$0000,$0000         ;................
L000321DC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L000321EC                       dc.w    $FFFC,$7FFC,$FFFC,$0000,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L000321FC                       dc.w    $007F,$FC00,$0000,$0000,$8004,$4004,$8004,$4004         ;..........@...@.
L0003220C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$0000         ;..@...@...@.....
L0003221C                       dc.w    $8004,$4004,$8004,$4004,$0040,$0400,$0000,$0000         ;..@...@..@......
L0003222C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L0003223C                       dc.w    $8004,$4004,$8004,$0000,$8004,$4004,$8004,$4004         ;..@.......@...@.
L0003224C                       dc.w    $0040,$0400,$0000,$0000,$FFFC,$7FFC,$FFFC,$7FFC         ;.@..............
L0003225C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$0000         ;................
L0003226C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$007F,$FC00,$0000,$0000         ;................
L0003227C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003228C                       dc.w    $FFFC,$7FFC,$FFFC,$0000,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003229C                       dc.w    $007F,$FC00,$0000,$0000,$FFFC,$7FFC,$FFFC,$7FF8         ;................
L000322AC                       dc.w    $7FFC,$7FF8,$FFFC,$7FF8,$7FFC,$7FF8,$FFFC,$0000         ;................
L000322BC                       dc.w    $7FFC,$7FFC,$FFFC,$7FFC,$007F,$FC00,$0000,$0000         ;................
L000322CC                       dc.w    $8004,$4004,$8007,$C00C,$C007,$C00C,$8007,$C00C         ;..@.............
L000322DC                       dc.w    $C007,$C00C,$8004,$0000,$C007,$C004,$8004,$4004         ;..............@.
L000322EC                       dc.w    $07C0,$07C0,$0000,$0000,$8004,$4004,$8000,$0010         ;..........@.....
L000322FC                       dc.w    $2000,$0010,$8000,$0010,$2000,$0010,$8004,$0000         ; ....... .......
L0003230C                       dc.w    $2000,$0004,$8004,$4004,$0400,$0040,$0000,$0000         ; .....@....@....
L0003231C                       dc.w    $FFFC,$7FFC,$FFFF,$FFE0,$1FFF,$FFE0,$FFFF,$FFE0         ;................
L0003232C                       dc.w    $1FFF,$FFE0,$FFFC,$0000,$1FFF,$FFFC,$FFFC,$7FFC         ;................
L0003233C                       dc.w    $07FF,$FFC0,$0000,$0000,$FFFC,$7FFC,$FFFF,$FFA0         ;................
L0003234C                       dc.w    $17FF,$FFA0,$FFFF,$FFA0,$17FF,$FFA0,$FFFC,$0000         ;................
L0003235C                       dc.w    $17FF,$FFFC,$FFFC,$7FFC,$07FF,$FFC0,$0000,$0000         ;................
L0003236C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003237C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003238C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003239C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L000323AC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0007,$FFFC         ;................
L000323BC                       dc.w    $FFFC,$7FFC,$FFFC,$0000,$FFFC,$7FFC,$FFFF,$FFA0         ;................
L000323CC                       dc.w    $17FF,$FFA0,$FFFF,$FFA0,$17FF,$FFA0,$FFFF,$FFA0         ;................
L000323DC                       dc.w    $17FF,$FFA0,$0004,$0004,$8004,$4004,$8004,$0000         ;..........@.....
L000323EC                       dc.w    $8006,$C004,$8000,$0020,$1000,$0020,$8000,$0020         ;....... ... ... 
L000323FC                       dc.w    $1000,$0020,$8000,$0020,$1000,$0020,$0004,$0004         ;... ... ... ....
L0003240C                       dc.w    $8004,$4004,$8004,$0000,$8003,$8004,$8000,$0010         ;..@.............
L0003241C                       dc.w    $2000,$0010,$8000,$0010,$2000,$0010,$8000,$0010         ; ....... .......
L0003242C                       dc.w    $2000,$0010,$0007,$C004,$8004,$4004,$8004,$0000         ; .........@.....
L0003243C                       dc.w    $8001,$0004,$8007,$C00C,$C007,$C00C,$8007,$C00C         ;................
L0003244C                       dc.w    $C007,$C00C,$8007,$C00C,$C007,$C00C,$0000,$4004         ;..............@.
L0003245C                       dc.w    $8004,$4004,$8004,$0000,$8000,$0004,$8004,$4000         ;..@...........@.
L0003246C                       dc.w    $0004,$4000,$8004,$4000,$0004,$4000,$8004,$4000         ;..@...@...@...@.
L0003247C                       dc.w    $0004,$4000,$0000,$4004,$8004,$4004,$8004,$0000         ;..@...@...@.....
L0003248C                       dc.w    $8000,$0004,$8004,$4004,$8004,$4004,$8004,$4004         ;......@...@...@.
L0003249C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$0000,$4004         ;..@...@...@...@.
L000324AC                       dc.w    $8004,$4004,$8004,$0000,$8004,$4004,$8004,$4004         ;..@.......@...@.
L000324BC                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L000324CC                       dc.w    $8004,$4004,$0000,$4004,$8004,$4004,$8004,$0000         ;..@...@...@.....
L000324DC                       dc.w    $8006,$C004,$8004,$4004,$8004,$4004,$8004,$4004         ;......@...@...@.
L000324EC                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$0000,$4004         ;..@...@...@...@.
L000324FC                       dc.w    $8004,$4004,$8004,$0000,$8007,$C004,$8004,$4004         ;..@...........@.
L0003250C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L0003251C                       dc.w    $8004,$4004,$0000,$4004,$8004,$4004,$8004,$0000         ;..@...@...@.....
L0003252C                       dc.w    $8005,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L0003253C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$0000,$4004         ;..@...@...@...@.
L0003254C                       dc.w    $8004,$4004,$8004,$0000,$8004,$4004,$8004,$4004         ;..@.......@...@.
L0003255C                       dc.w    $8004,$4004,$8004,$4004,$8004,$400C,$8004,$4004         ;..@...@...@...@.
L0003256C                       dc.w    $8004,$4004,$0000,$4004,$8004,$4008,$8004,$0000         ;..@...@...@.....
L0003257C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L0003258C                       dc.w    $8004,$400C,$8004,$4000,$8004,$7FFC,$0000,$400C         ;..@...@.......@.
L0003259C                       dc.w    $8004,$514C,$8004,$0000,$8004,$400C,$8004,$5144         ;..QL......@...QD
L000325AC                       dc.w    $8004,$5144,$8004,$4000,$8004,$401C,$8004,$400C         ;..QD..@...@...@.
L000325BC                       dc.w    $0004,$0000,$0000,$4014,$8007,$C030,$8004,$0000         ;......@....0....
L000325CC                       dc.w    $C004,$4014,$8004,$4054,$8004,$4054,$C007,$C00C         ;..@...@T..@T....
L000325DC                       dc.w    $8004,$4064,$C007,$C010,$C007,$FFA0,$0000,$40D4         ;..@d..........@.
L000325EC                       dc.w    $801A,$0020,$D164,$0000,$B004,$40D4,$801C,$402C         ;... .d....@...@,
L000325FC                       dc.w    $801C,$402C,$B000,$0010,$D164,$40A4,$B000,$0020         ;..@,.....d@.... 
L0003260C                       dc.w    $2000,$0060,$0000,$4684,$80D0,$0020,$C05C,$0000         ; ..`..F.... .\..
L0003261C                       dc.w    $8A04,$4684,$80D4,$400C,$80D4,$400C,$8A00,$0020         ;..F...@...@.... 
L0003262C                       dc.w    $C05C,$4684,$8A00,$06E0,$1000,$06B0,$0000,$6004         ;.\F...........`.
L0003263C                       dc.w    $8347,$C030,$8014,$0000,$8284,$6004,$8344,$4004         ;.G.0......`..D@.
L0003264C                       dc.w    $8344,$4004,$8287,$FFA0,$8014,$7404,$8287,$E030         ;.D@.......t....0
L0003265C                       dc.w    $17FF,$E01C,$0000,$4004,$E804,$401C,$8004,$0000         ;......@...@.....
L0003266C                       dc.w    $80BC,$4004,$E804,$4004,$E804,$4004,$80BC,$0000         ;..@...@...@.....
L0003267C                       dc.w    $8004,$4004,$80BC,$401C,$0000,$4008,$FFFC,$4004         ;..@...@...@...@.
L0003268C                       dc.w    $8004,$4008,$8004,$7FFC,$8004,$4004,$8004,$4004         ;..@.......@...@.
L0003269C                       dc.w    $8004,$4004,$8004,$0000,$8004,$4004,$8004,$4018         ;..@.......@...@.
L000326AC                       dc.w    $FFFC,$400C,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;..@.............
L000326BC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$0000         ;................
L000326CC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L000326DC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L000326EC                       dc.w    $FFFC,$7FFC,$FFFC,$0000,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L000326FC                       dc.w    $FFFC,$7FFC,$8004,$4004,$8004,$4004,$8004,$4004         ;......@...@...@.
L0003270C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$0000         ;..@...@...@.....
L0003271C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L0003272C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L0003273C                       dc.w    $8004,$4004,$8004,$0000,$8004,$4004,$8004,$4004         ;..@.......@...@.
L0003274C                       dc.w    $8004,$4004,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;..@.............
L0003275C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$0000         ;................
L0003276C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003277C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003278C                       dc.w    $FFFC,$7FFC,$FFFC,$0000,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003279C                       dc.w    $FFFC,$7FFC,$7FFC,$7FF8,$FFFC,$7FFC,$7FFC,$7FF8         ;................
L000327AC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$7FFC,$7FF8,$FFFC,$0000         ;................
L000327BC                       dc.w    $7FFC,$7FFC,$FFFC,$7FFC,$7FFC,$7FF8,$C007,$C00C         ;................
L000327CC                       dc.w    $8004,$4004,$C007,$C00C,$8004,$4004,$8004,$4004         ;..@.......@...@.
L000327DC                       dc.w    $C007,$C00C,$8004,$0000,$C007,$C004,$8004,$4004         ;..............@.
L000327EC                       dc.w    $C007,$C00C,$2000,$0010,$8004,$4004,$2000,$0010         ;.... .....@. ...
L000327FC                       dc.w    $8004,$4004,$8004,$4004,$2000,$0010,$8004,$0000         ;..@...@. .......
L0003280C                       dc.w    $2000,$0004,$8004,$4004,$2000,$0010,$1FFF,$FFE0         ; .....@. .......
L0003281C                       dc.w    $FFFC,$7FFC,$1FFF,$FFE0,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003282C                       dc.w    $1FFF,$FFE0,$FFFC,$0000,$1FFF,$FFFC,$FFFC,$7FFC         ;................
L0003283C                       dc.w    $1FFF,$FFE0,$17FF,$FFA0,$FFFC,$7FFC,$17FF,$FFA0         ;................
L0003284C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$17FF,$FFA0,$FFFC,$0000         ;................
L0003285C                       dc.w    $17FF,$FFFC,$FFFC,$7FFC,$17FF,$FFA0,$0000,$0000         ;................
L0003286C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003287C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003288C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003289C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L000328AC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$FFFC,$0000         ;................
L000328BC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFF8,$FFFC,$FFFC,$7FFC         ;................
L000328CC                       dc.w    $FFFC,$7FFC,$17FF,$FFFC,$002F,$FF00,$0000,$0000         ;........./......
L000328DC                       dc.w    $00FF,$F400,$8004,$0000,$8004,$4004,$8004,$4004         ;..........@...@.
L000328EC                       dc.w    $8008,$8004,$8004,$4004,$8004,$4004,$1000,$0004         ;......@...@.....
L000328FC                       dc.w    $0020,$0100,$0000,$0000,$0080,$0400,$8004,$0000         ;. ..............
L0003290C                       dc.w    $8004,$4004,$8004,$4004,$8008,$8004,$8004,$4004         ;..@...@.......@.
L0003291C                       dc.w    $8004,$4004,$2000,$0004,$0040,$0100,$0000,$0000         ;..@. ....@......
L0003292C                       dc.w    $0080,$0200,$8004,$0000,$8004,$4004,$8004,$4004         ;..........@...@.
L0003293C                       dc.w    $8008,$8004,$8004,$4004,$8004,$4004,$C007,$C004         ;......@...@.....
L0003294C                       dc.w    $0180,$1F00,$00FF,$FC00,$00F8,$0180,$8004,$0000         ;................
L0003295C                       dc.w    $8004,$4004,$8004,$4004,$8008,$8004,$8004,$4004         ;..@...@.......@.
L0003296C                       dc.w    $8004,$4004,$0004,$4004,$0000,$1000,$0080,$0400         ;..@...@.........
L0003297C                       dc.w    $0008,$0000,$8004,$0000,$8004,$4004,$8004,$4004         ;..........@...@.
L0003298C                       dc.w    $8008,$8004,$8004,$4004,$8004,$4004,$8004,$4004         ;......@...@...@.
L0003299C                       dc.w    $0100,$1000,$0080,$0400,$0008,$0080,$8004,$0000         ;................
L000329AC                       dc.w    $8004,$4004,$8004,$4004,$8008,$8004,$8004,$4004         ;..@...@.......@.
L000329BC                       dc.w    $8004,$4004,$8004,$4004,$0100,$1000,$0080,$0400         ;..@...@.........
L000329CC                       dc.w    $0008,$0080,$8004,$0000,$8004,$4004,$8004,$4004         ;..........@...@.
L000329DC                       dc.w    $8008,$8004,$8004,$4004,$8004,$4004,$8004,$4004         ;......@...@...@.
L000329EC                       dc.w    $0100,$1000,$0080,$0400,$0008,$0080,$8004,$0000         ;................
L000329FC                       dc.w    $8004,$4004,$8004,$4004,$8008,$8004,$8004,$4004         ;..@...@.......@.
L00032A0C                       dc.w    $8004,$4004,$8004,$4004,$0100,$1000,$0080,$0400         ;..@...@.........
L00032A1C                       dc.w    $0008,$0080,$8004,$0000,$8004,$4004,$8004,$4004         ;..........@...@.
L00032A2C                       dc.w    $8008,$8004,$8004,$4004,$8004,$4004,$8004,$4004         ;......@...@...@.
L00032A3C                       dc.w    $0100,$1000,$0080,$0400,$0008,$0080,$8004,$0000         ;................
L00032A4C                       dc.w    $8004,$400C,$8004,$4004,$8008,$800C,$8004,$4004         ;..@...@.......@.
L00032A5C                       dc.w    $8004,$4004,$8004,$4004,$0100,$1000,$0080,$0400         ;..@...@.........
L00032A6C                       dc.w    $0008,$0080,$8004,$0000,$8004,$400C,$8004,$4004         ;..........@...@.
L00032A7C                       dc.w    $8008,$800C,$0004,$4008,$8004,$4004,$FFFC,$4004         ;......@...@...@.
L00032A8C                       dc.w    $0100,$1000,$0080,$0400,$0008,$0080,$8004,$0000         ;................
L00032A9C                       dc.w    $8004,$401C,$8004,$400C,$8008,$801C,$C004,$514C         ;..@...@.......QL
L00032AAC                       dc.w    $0004,$400C,$0000,$4000,$0100,$1000,$0080,$D400         ;..@...@.........
L00032ABC                       dc.w    $0008,$0080,$8007,$C000,$8004,$4064,$C004,$4014         ;..........@d..@.
L00032ACC                       dc.w    $8008,$8064,$2007,$C030,$C007,$C014,$17FF,$C00C         ;...d ..0........
L00032ADC                       dc.w    $0100,$1000,$0F86,$87C0,$0008,$0080,$801A,$4000         ;..............@.
L00032AEC                       dc.w    $D164,$40A4,$B004,$40D4,$D168,$80A4,$101A,$0020         ;.d@...@..h..... 
L00032AFC                       dc.w    $2000,$00D4,$1D60,$0010,$01B0,$1000,$081A,$0040         ; ....`.........@
L00032B0C                       dc.w    $0008,$0180,$80D0,$4000,$C05C,$4684,$8A04,$4684         ;......@..\F...F.
L00032B1C                       dc.w    $C058,$8684,$10D0,$0020,$1000,$0684,$3058,$0020         ;.X..... ....0X. 
L00032B2C                       dc.w    $012C,$1000,$08D0,$0040,$0008,$0D80,$8347,$C000         ;.,.....@.....G..
L00032B3C                       dc.w    $8014,$7404,$8284,$6004,$8018,$B404,$2347,$C030         ;..t...`.....#G.0
L00032B4C                       dc.w    $17FF,$E004,$E017,$FFA0,$010B,$1000,$0FC0,$07C0         ;................
L00032B5C                       dc.w    $000B,$4080,$E804,$0000,$8004,$4004,$80BC,$4004         ;..@.......@...@.
L00032B6C                       dc.w    $8008,$C004,$C804,$401C,$0000,$4004,$4004,$0000         ;......@...@.@...
L00032B7C                       dc.w    $0102,$3000,$0080,$0400,$000C,$0080,$8004,$7FFC         ;..0.............
L00032B8C                       dc.w    $8004,$4004,$8004,$4004,$800A,$8004,$6004,$4008         ;..@...@.....`.@.
L00032B9C                       dc.w    $FFFC,$4004,$C004,$7FFC,$0100,$1000,$0080,$0400         ;..@.............
L00032BAC                       dc.w    $0008,$0080,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L00032BBC                       dc.w    $FFFF,$FFFC,$FFFC,$7FFC,$FFFC,$7FFC,$BFFC,$7FFC         ;................
L00032BCC                       dc.w    $01FF,$F000,$00FF,$FC00,$000F,$FF80,$FFFC,$7FFC         ;................
L00032BDC                       dc.w    $FFFC,$7FFC,$DFFC,$7FEC,$FFF7,$7FFC,$FFFC,$7FFC         ;................
L00032BEC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$01FF,$F000,$00FF,$FC00         ;................
L00032BFC                       dc.w    $000F,$FF80,$8004,$4004,$8004,$4004,$6004,$4018         ;......@...@.`.@.
L00032C0C                       dc.w    $8000,$0004,$8004,$4004,$8004,$4004,$8004,$4004         ;......@...@...@.
L00032C1C                       dc.w    $0100,$1000,$0080,$0400,$0008,$0080,$8004,$4004         ;..............@.
L00032C2C                       dc.w    $8004,$4004,$3004,$4030,$8000,$0004,$8004,$4004         ;..@.0.@0......@.
L00032C3C                       dc.w    $8004,$4004,$8004,$4004,$0100,$1000,$0080,$0400         ;..@...@.........
L00032C4C                       dc.w    $0008,$0080,$FFFC,$7FFC,$FFFC,$7FFC,$1FFC,$7FE0         ;................
L00032C5C                       dc.w    $FFFF,$FFFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L00032C6C                       dc.w    $01FF,$F000,$00FF,$FC00,$000F,$FF80,$FFFC,$7FFC         ;................
L00032C7C                       dc.w    $FFFC,$7FFC,$0FFC,$7FC0,$FFFF,$FFFC,$FFFC,$7FFC         ;................
L00032C8C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$01FF,$F000,$00FF,$FC00         ;................
L00032C9C                       dc.w    $000F,$FF80,$7FFC,$7FF8,$7FFC,$7FF8,$07FC,$7F80         ;................
L00032CAC                       dc.w    $7FFD,$FFF8,$FFFC,$7FFC,$7FFC,$7FF8,$FFFC,$7FF8         ;................
L00032CBC                       dc.w    $00FF,$F000,$00FF,$FC00,$000F,$FF00,$C007,$C00C         ;................
L00032CCC                       dc.w    $C007,$C00C,$0307,$C300,$C007,$000C,$8004,$4004         ;..............@.
L00032CDC                       dc.w    $C007,$C00C,$8007,$C00C,$0180,$1F00,$00FF,$FC00         ;................
L00032CEC                       dc.w    $00F8,$0180,$2000,$0010,$2000,$0010,$0180,$0600         ;.... ... .......
L00032CFC                       dc.w    $2008,$8010,$8004,$4004,$2000,$0010,$8000,$0010         ; .....@. .......
L00032D0C                       dc.w    $0040,$0100,$0000,$0000,$0080,$0200,$1FFF,$FFE0         ;.@..............
L00032D1C                       dc.w    $1FFF,$FFE0,$00FF,$FC00,$1FF0,$7FE0,$FFFC,$7FFC         ;................
L00032D2C                       dc.w    $1FFF,$FFE0,$FFFF,$FFE0,$003F,$FF00,$0000,$0000         ;.........?......
L00032D3C                       dc.w    $00FF,$FC00,$17FF,$FFA0,$17FF,$FFA0,$007F,$F800         ;................
L00032D4C                       dc.w    $17D0,$5FA0,$FFFC,$7FFC,$17FF,$FFA0,$FFFF,$FFA0         ;.._.............
L00032D5C                       dc.w    $002F,$FF00,$0000,$0000,$00FF,$F400,$0000,$0000         ;./..............
L00032D6C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00032D7C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00032D8C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00032D9C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00032DAC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00032DBC                       dc.w    $0000,$0000,$0000,$0000,$000A,$8000,$1BFF,$FFD8         ;................
L00032DCC                       dc.w    $00FF,$EC00,$1BFF,$FFD8,$1BFF,$FFD8,$7FFE,$3FFE         ;..............?.
L00032DDC                       dc.w    $7FFF,$FFD8,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00032DEC                       dc.w    $F03D,$E000,$2FFF,$FFF4,$00FF,$FA00,$0FFF,$FFF4         ;.=../...........
L00032DFC                       dc.w    $2FFF,$FFF4,$7FFE,$3FFE,$7FFF,$FFF4,$0000,$0000         ;/.....?.........
L00032E0C                       dc.w    $0000,$0000,$0000,$0000,$F03F,$E000,$5FFF,$FFFA         ;.........?.._...
L00032E1C                       dc.w    $00FF,$FD00,$5FFF,$FFFA,$5FFF,$FFFA,$7FFE,$3FFE         ;...._..._.....?.
L00032E2C                       dc.w    $7FFF,$FFFA,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00032E3C                       dc.w    $F03F,$E000,$7FFF,$FFFE,$00FF,$FF00,$7FFF,$FFFE         ;.?..............
L00032E4C                       dc.w    $7FFF,$FFFE,$7FFE,$3FFE,$7FFF,$FFFE,$0000,$0000         ;......?.........
L00032E5C                       dc.w    $0000,$0000,$0000,$0000,$F83F,$E000,$3FFE,$3FFC         ;.........?..?.?.
L00032E6C                       dc.w    $001F,$FE00,$3FFE,$3FFC,$3FFE,$3FFC,$7FFE,$3FFE         ;....?.?.?.?...?.
L00032E7C                       dc.w    $7FFE,$3FFC,$0000,$0000,$0000,$0000,$0000,$0000         ;..?.............
L00032E8C                       dc.w    $F03D,$E000,$7FFE,$3FFE,$001F,$FF00,$7FFE,$3FFE         ;.=....?.......?.
L00032E9C                       dc.w    $7FFE,$3FFE,$7FFE,$3FFE,$7FFE,$3FFE,$0000,$0000         ;..?...?...?.....
L00032EAC                       dc.w    $0000,$0000,$0000,$0000,$773D,$E000,$7FFE,$3FFE         ;........w=....?.
L00032EBC                       dc.w    $001F,$FF00,$7FFE,$3FFE,$7FFE,$3FFE,$7FFE,$3FFE         ;......?...?...?.
L00032ECC                       dc.w    $7FFE,$3FFE,$0000,$0000,$0000,$0000,$0000,$0000         ;..?.............
L00032EDC                       dc.w    $F7BD,$E000,$7FFE,$3FFE,$001F,$FF00,$7FFE,$3FFE         ;......?.......?.
L00032EEC                       dc.w    $7FFE,$3FFE,$7FFE,$3FFE,$7FFE,$3FFE,$0000,$0000         ;..?...?...?.....
L00032EFC                       dc.w    $0000,$0000,$0000,$0000,$DDBD,$E000,$7FFE,$3FFE         ;..............?.
L00032F0C                       dc.w    $001F,$FF00,$7FFE,$3FFE,$7FFE,$3FFE,$7FFE,$3FFE         ;......?...?...?.
L00032F1C                       dc.w    $7FFE,$3FFE,$0000,$0000,$0000,$0000,$0000,$0000         ;..?.............
L00032F2C                       dc.w    $0000,$0000,$7FFE,$3FFE,$001F,$FF00,$7FFE,$3FFE         ;......?.......?.
L00032F3C                       dc.w    $7FFE,$3FFE,$7FFE,$3FFE,$7FFE,$3FFE,$0000,$0000         ;..?...?...?.....
L00032F4C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$7FFE,$3FFA         ;..............?.
L00032F5C                       dc.w    $001F,$FF00,$7FFE,$3FFE,$7FFE,$3FFE,$7FFE,$3FFE         ;......?...?...?.
L00032F6C                       dc.w    $7FFE,$3FFE,$0000,$0000,$0000,$0000,$0000,$0000         ;..?.............
L00032F7C                       dc.w    $0000,$0000,$7FFE,$3FFA,$001F,$FF00,$7FFE,$3FFE         ;......?.......?.
L00032F8C                       dc.w    $7FFE,$3FFC,$7FFE,$3FFE,$7FFE,$3FFE,$0000,$0000         ;..?...?...?.....
L00032F9C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$7FFE,$3FF2         ;..............?.
L00032FAC                       dc.w    $001F,$FF00,$0000,$3FFC,$0000,$271E,$3FFE,$3FFA         ;......?...'.?.?.
L00032FBC                       dc.w    $7FFE,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00032FCC                       dc.w    $0000,$0000,$7FFE,$3FC6,$001F,$FF00,$1BFF,$FFFE         ;......?.........
L00032FDC                       dc.w    $0003,$FFFA,$7FFF,$FFF2,$7FFF,$FFD8,$0000,$0000         ;................
L00032FEC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$470E,$3F8E         ;............G.?.
L00032FFC                       dc.w    $001F,$FF00,$2F0F,$FFFA,$0002,$FFF4,$5FFF,$FF86         ;..../......._...
L0003300C                       dc.w    $7FF0,$FFF4,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003301C                       dc.w    $0000,$0000,$5FC2,$3C3E,$001F,$FD00,$5FC3,$FFF4         ;...._.<>...._...
L0003302C                       dc.w    $0003,$FFF4,$2FFF,$FC3E,$7F87,$FFFA,$0000,$0000         ;..../..>........
L0003303C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$7FF2,$21FE         ;..............!.
L0003304C                       dc.w    $001F,$0F00,$7FF3,$FFD8,$0003,$FFFA,$1BFF,$EFFE         ;................
L0003305C                       dc.w    $7FFF,$FFFE,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003306C                       dc.w    $0000,$0000,$7FFE,$3FFE,$0010,$FF00,$3FFE,$0000         ;......?.....?...
L0003307C                       dc.w    $0000,$3FFE,$0000,$3FFE,$0000,$3FFC,$0000,$0000         ;..?...?...?.....
L0003308C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$7FFE,$3FFE         ;..............?.
L0003309C                       dc.w    $001F,$FF00,$7FFE,$3FFE,$7FFE,$3FFC,$0000,$3FFE         ;......?...?...?.
L000330AC                       dc.w    $7FFE,$3FFE,$0000,$0000,$0000,$0000,$0000,$0000         ;..?.............
L000330BC                       dc.w    $0000,$0000,$4002,$2002,$0010,$0100,$6002,$2002         ;....@. .....`. .
L000330CC                       dc.w    $4002,$2002,$0000,$2002,$4002,$2006,$0000,$0000         ;@. ... .@. .....
L000330DC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$4002,$2002         ;............@. .
L000330EC                       dc.w    $0010,$0100,$4002,$2002,$4002,$2002,$0000,$2002         ;....@. .@. ... .
L000330FC                       dc.w    $4002,$2002,$0000,$0000,$0000,$0000,$0000,$0000         ;@. .............
L0003310C                       dc.w    $0000,$0000,$4002,$2002,$0010,$0100,$4002,$2002         ;....@. .....@. .
L0003311C                       dc.w    $4002,$2002,$0000,$2002,$4002,$2002,$07F8,$0000         ;@. ... .@. .....
L0003312C                       dc.w    $0000,$0000,$07F8,$0000,$0000,$0000,$4002,$2002         ;............@. .
L0003313C                       dc.w    $0010,$0100,$4002,$2002,$4002,$2002,$0000,$2002         ;....@. .@. ... .
L0003314C                       dc.w    $4002,$2002,$07F8,$0000,$0000,$0000,$07F8,$0000         ;@. .............
L0003315C                       dc.w    $0000,$0000,$7FFE,$3FFE,$001F,$FF00,$7FFE,$3FFE         ;......?.......?.
L0003316C                       dc.w    $7FFE,$3FFE,$0000,$3FFE,$7FFE,$3FFE,$0408,$0000         ;..?...?...?.....
L0003317C                       dc.w    $0000,$0000,$0408,$0000,$0000,$0000,$4002,$2002         ;............@. .
L0003318C                       dc.w    $0010,$0100,$4002,$2002,$4002,$2002,$0000,$2002         ;....@. .@. ... .
L0003319C                       dc.w    $4002,$2002,$0408,$0000,$0000,$0000,$0408,$0000         ;@. .............
L000331AC                       dc.w    $0000,$0000,$0002,$2000,$0010,$0100,$4002,$2002         ;...... .....@. .
L000331BC                       dc.w    $0002,$2000,$0000,$2002,$0002,$2000,$07F8,$0000         ;.. ... ... .....
L000331CC                       dc.w    $0000,$0000,$07F8,$0000,$0000,$0000,$7FFF,$FFFE         ;................
L000331DC                       dc.w    $001F,$FF00,$7FFF,$FFFE,$7FFF,$FFFE,$0000,$3FFE         ;..............?.
L000331EC                       dc.w    $7FFF,$FFFE,$07F8,$0000,$0000,$0000,$07F8,$0000         ;................
L000331FC                       dc.w    $0000,$0000,$5FFF,$FFFA,$001F,$FF00,$7FFF,$FFFE         ;...._...........
L0003320C                       dc.w    $5FFF,$FFFA,$0000,$3FFE,$5FFF,$FFFA,$0078,$0000         ;_.....?._....x..
L0003321C                       dc.w    $0000,$0000,$07F8,$0000,$0000,$0000,$2FFF,$FFF4         ;............/...
L0003322C                       dc.w    $001F,$FF00,$7FFF,$FFFE,$2FFF,$FFF4,$0000,$3FFE         ;......../.....?.
L0003323C                       dc.w    $2FFF,$FFF4,$0078,$0000,$0000,$0000,$07F8,$0000         ;/....x..........
L0003324C                       dc.w    $0000,$0000,$1BFF,$FFD8,$001F,$FF00,$7FFF,$FFFE         ;................
L0003325C                       dc.w    $1BFF,$FFD8,$0000,$3FFE,$1BFF,$FFD8,$0000,$0000         ;......?.........
L0003326C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003327C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003328C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003329C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L000332AC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$37FF,$FFB0         ;............7...
L000332BC                       dc.w    $37FF,$FFB0,$37FF,$FFB0,$37FF,$FFB0,$0000,$0000         ;7...7...7.......
L000332CC                       dc.w    $01FE,$7F80,$0001,$0000,$001F,$E000,$0002,$0000         ;................
L000332DC                       dc.w    $1BFF,$FFD8,$1FFF,$FFE8,$5FFF,$FFE8,$5FFF,$FFE8         ;........_..._...
L000332EC                       dc.w    $5FFF,$FFE8,$0000,$0000,$01FE,$7F80,$0001,$8000         ;_...............
L000332FC                       dc.w    $001F,$E000,$0006,$0000,$0FFF,$FFF0,$BFFF,$FFF4         ;................
L0003330C                       dc.w    $BFFF,$FFF4,$BFFF,$FFF4,$BFFF,$FFF4,$0000,$0000         ;................
L0003331C                       dc.w    $01FE,$7F80,$0001,$C000,$001F,$E000,$000E,$0000         ;................
L0003332C                       dc.w    $5FFF,$FFFA,$FFFF,$FFFC,$FFFF,$FFFC,$FFFF,$FFFC         ;_...............
L0003333C                       dc.w    $FFFF,$FFFC,$0000,$0000,$01FE,$7F80,$0001,$E000         ;................
L0003334C                       dc.w    $001F,$E000,$001E,$0000,$7FFF,$FFFE,$7FFC,$7FF8         ;................
L0003335C                       dc.w    $7FFC,$7FF8,$7FFC,$7FF8,$7FF8,$FFF8,$003F,$C000         ;.............?..
L0003336C                       dc.w    $01FE,$7F80,$0001,$F000,$001F,$E000,$003E,$0000         ;.............>..
L0003337C                       dc.w    $3FFE,$3FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;?.?.............
L0003338C                       dc.w    $FFF8,$FFFC,$003F,$C000,$01FE,$7F80,$0001,$F800         ;.....?..........
L0003339C                       dc.w    $001F,$E000,$007E,$0000,$7FFE,$3FFE,$FFFC,$7FFC         ;.....~....?.....
L000333AC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFF8,$FFFC,$003F,$C000         ;.............?..
L000333BC                       dc.w    $001E,$0780,$0001,$FC00,$001F,$E000,$00FE,$0000         ;................
L000333CC                       dc.w    $7FFE,$3FFE,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;..?.............
L000333DC                       dc.w    $FFF8,$FFFC,$003F,$C000,$001E,$0780,$0001,$FE00         ;.....?..........
L000333EC                       dc.w    $001F,$E000,$01FE,$0000,$7FFE,$3FFE,$FFFC,$7FFC         ;..........?.....
L000333FC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFF8,$FFFC,$003F,$C000         ;.............?..
L0003340C                       dc.w    $0000,$0000,$0001,$FF00,$001F,$E000,$03FE,$0000         ;................
L0003341C                       dc.w    $7FFE,$3FFE,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;..?.............
L0003342C                       dc.w    $FFF8,$FFFC,$003F,$C000,$0000,$0000,$FFFF,$FF80         ;.....?..........
L0003343C                       dc.w    $001F,$E000,$07FF,$FFFC,$7FFE,$3FFE,$FFFC,$7FF4         ;..........?.....
L0003344C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFF8,$FFFC,$003F,$C000         ;.............?..
L0003345C                       dc.w    $0000,$0000,$FFFF,$FFC0,$001F,$E000,$0FFF,$FFF4         ;................
L0003346C                       dc.w    $7FFE,$3FFE,$FFFC,$7FFC,$FFFC,$7FFC,$7FFC,$7FF8         ;..?.............
L0003347C                       dc.w    $FFF8,$FFFC,$003F,$C000,$0000,$0000,$FFFF,$FFE0         ;.....?..........
L0003348C                       dc.w    $001F,$E000,$1FFF,$FFF4,$7FFE,$3FFE,$FFFC,$0000         ;..........?.....
L0003349C                       dc.w    $0000,$7FF4,$FFFC,$4E3C,$7FF8,$FFF4,$0000,$0000         ;......N<........
L000334AC                       dc.w    $0000,$0000,$FFFF,$FFF0,$001F,$E000,$3FFF,$FFE4         ;............?...
L000334BC                       dc.w    $0000,$3FFC,$FFFF,$FFB0,$0007,$FFE4,$BFFF,$FFF4         ;..?.............
L000334CC                       dc.w    $FFFF,$FFE4,$0000,$0000,$0000,$0000,$BFFF,$FFF8         ;................
L000334DC                       dc.w    $001F,$E000,$7FFF,$FF8C,$0006,$FFFE,$8E1F,$FFE8         ;................
L000334EC                       dc.w    $0007,$FF0C,$5FE1,$FFE8,$BFFF,$FF0C,$0000,$0000         ;...._...........
L000334FC                       dc.w    $0000,$0000,$8FFF,$FF0C,$001F,$E000,$CE1F,$FF1C         ;................
L0003350C                       dc.w    $0003,$FFFA,$BF87,$F874,$0007,$F87C,$5F0F,$FFE8         ;.......t...|_...
L0003351C                       dc.w    $5FFF,$F87C,$0000,$0000,$0000,$0000,$F1FF,$F86C         ;_..|...........l
L0003352C                       dc.w    $0013,$E000,$DF87,$F87C,$0017,$FFF0,$FFE7,$DFFC         ;.......|........
L0003353C                       dc.w    $0007,$DFFC,$BC3F,$FFF4,$37FF,$9FFC,$0000,$0000         ;.....?..7.......
L0003354C                       dc.w    $0000,$0000,$FC7E,$1FD8,$0010,$E000,$6FE1,$C3FC         ;.....~......o...
L0003355C                       dc.w    $0018,$FFD8,$FFFC,$7FF8,$0000,$7FFC,$E7FC,$7FFC         ;................
L0003356C                       dc.w    $0000,$FFFC,$003F,$C000,$0000,$0000,$FF01,$FFB0         ;.....?..........
L0003357C                       dc.w    $001C,$2000,$37F8,$3FFC,$0008,$2000,$FFFC,$7FF4         ;.. .7.?... .....
L0003358C                       dc.w    $0000,$7FFC,$5FFC,$7FF8,$FFF8,$FFFC,$0020,$4000         ;...._........ @.
L0003359C                       dc.w    $0000,$0000,$FFFF,$FF60,$001F,$E000,$1BFF,$FFFC         ;.......`........
L000335AC                       dc.w    $0017,$E000,$8004,$4004,$0000,$4004,$8004,$4004         ;......@...@...@.
L000335BC                       dc.w    $8008,$8004,$0020,$4000,$0000,$0000,$8000,$00C0         ;..... @.........
L000335CC                       dc.w    $0010,$2000,$0C00,$0004,$0010,$2000,$8004,$4004         ;.. ....... ...@.
L000335DC                       dc.w    $0000,$4004,$8004,$4004,$8008,$8004,$0020,$4000         ;..@...@...... @.
L000335EC                       dc.w    $0000,$0000,$FFFF,$0180,$0010,$2000,$0603,$FFFC         ;.......... .....
L000335FC                       dc.w    $0010,$2000,$8004,$4004,$0000,$4004,$8004,$4004         ;.. ...@...@...@.
L0003360C                       dc.w    $8008,$8004,$0020,$4000,$0000,$0000,$0001,$0300         ;..... @.........
L0003361C                       dc.w    $0010,$2000,$0302,$0000,$0010,$2000,$8004,$4004         ;.. ....... ...@.
L0003362C                       dc.w    $0000,$4004,$8004,$4004,$8008,$8004,$003F,$C000         ;..@...@......?..
L0003363C                       dc.w    $0000,$0000,$0001,$0E00,$0010,$2000,$01C2,$0000         ;.......... .....
L0003364C                       dc.w    $0010,$2000,$FFFC,$7FFC,$0000,$7FFC,$FFFC,$7FFC         ;.. .............
L0003365C                       dc.w    $FFF8,$FFFC,$0020,$4000,$0000,$0000,$0001,$EC00         ;..... @.........
L0003366C                       dc.w    $001F,$E000,$00DE,$0000,$001F,$E000,$8004,$4004         ;..............@.
L0003367C                       dc.w    $0000,$4004,$8004,$4004,$8008,$8004,$003F,$C000         ;..@...@......?..
L0003368C                       dc.w    $0000,$0000,$0001,$1800,$001F,$E000,$0062,$0000         ;.............b..
L0003369C                       dc.w    $001F,$E000,$0004,$4000,$0000,$4004,$0004,$4000         ;......@...@...@.
L000336AC                       dc.w    $0008,$8000,$0000,$0000,$0000,$0000,$0001,$3000         ;..............0.
L000336BC                       dc.w    $0000,$0000,$0032,$0000,$0000,$0000,$FFFF,$FFFC         ;.....2..........
L000336CC                       dc.w    $0000,$7FFC,$FFFF,$FFFC,$FFFF,$FFFC,$0000,$0000         ;................
L000336DC                       dc.w    $0000,$0000,$0001,$E000,$001F,$E000,$001E,$0000         ;................
L000336EC                       dc.w    $001F,$E000,$BFFF,$FFF4,$0000,$7FFC,$BFFF,$FFF4         ;................
L000336FC                       dc.w    $BFFF,$FFF4,$0000,$0000,$0000,$0000,$0001,$C000         ;................
L0003370C                       dc.w    $001F,$E000,$000E,$0000,$001F,$E000,$5FFF,$FFE8         ;............_...
L0003371C                       dc.w    $0000,$7FFC,$5FFF,$FFE8,$5FFF,$FFE8,$0000,$0000         ;...._..._.......
L0003372C                       dc.w    $0000,$0000,$0001,$8000,$001F,$E000,$0006,$0000         ;................
L0003373C                       dc.w    $001F,$E000,$37FF,$FFB0,$0000,$7FFC,$37FF,$FFB0         ;....7.......7...
L0003374C                       dc.w    $37FF,$FFB0,$0000,$0000,$0000,$0000,$0001,$0000         ;7...............
L0003375C                       dc.w    $001F,$E000,$0002,$0000,$001F,$E000,$0000,$0000         ;................
L0003376C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003377C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003378C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003379C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L000337AC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0FF0,$0000         ;................
L000337BC                       dc.w    $37FF,$FFB0,$FFFF,$FFB0,$37FF,$FFB0,$FFFF,$FFB0         ;7.......7.......
L000337CC                       dc.w    $37FF,$FFB0,$37FF,$FFB0,$37FF,$FFB0,$FFFC,$7FFC         ;7...7...7.......
L000337DC                       dc.w    $07FF,$FFC0,$0FF0,$0000,$1FFF,$FFE0,$FFFF,$FFE0         ;................
L000337EC                       dc.w    $1FFF,$FFE0,$FFFF,$FFE0,$1FFF,$FFE0,$1FFF,$FFE0         ;................
L000337FC                       dc.w    $1FFF,$FFE0,$FFFC,$7FFC,$07FF,$FFC0,$0FF0,$0000         ;................
L0003380C                       dc.w    $BFFF,$FFF4,$FFFF,$FFF4,$BFFF,$FFF4,$FFFF,$FFF4         ;................
L0003381C                       dc.w    $BFFF,$FFF4,$BFFF,$FFF4,$BFFF,$FFF4,$FFFC,$7FFC         ;................
L0003382C                       dc.w    $07FF,$FFC0,$0FF0,$0000,$FFFF,$FFFC,$FFFF,$FFFC         ;................
L0003383C                       dc.w    $FFFF,$FFFC,$FFFF,$FFFC,$FFFF,$FFFC,$FFFF,$FFFC         ;................
L0003384C                       dc.w    $FFFF,$FFFC,$FFFC,$7FFC,$07FF,$FFC0,$0FF0,$0000         ;................
L0003385C                       dc.w    $7FFC,$7FF8,$FFFC,$7FF8,$7FFC,$7FF8,$FFFC,$7FF8         ;................
L0003386C                       dc.w    $7FFC,$7FF8,$7FFC,$7FF8,$7FFC,$7FF8,$FFFC,$7FFC         ;................
L0003387C                       dc.w    $007F,$FC00,$0FF0,$0000,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003388C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003389C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$007F,$FC00,$00F0,$0000         ;................
L000338AC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L000338BC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L000338CC                       dc.w    $007F,$FC00,$00F0,$0000,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L000338DC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L000338EC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$007F,$FC00,$0000,$0000         ;................
L000338FC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003390C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003391C                       dc.w    $007F,$FC00,$0000,$0000,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003392C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003393C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$007F,$FC00,$0000,$0000         ;................
L0003394C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FF4         ;................
L0003395C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FF4         ;................
L0003396C                       dc.w    $007F,$FC00,$0000,$0000,$FFFC,$7FFC,$FFFC,$7FF8         ;................
L0003397C                       dc.w    $FFFC,$7FFC,$FFFC,$7FF4,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003398C                       dc.w    $FFFC,$7FFC,$FFFC,$7FF4,$007F,$FC00,$0000,$0000         ;................
L0003399C                       dc.w    $FFFC,$7FF4,$FFFC,$4E3C,$FFFC,$0000,$FFFC,$7FE4         ;......N<........
L000339AC                       dc.w    $FFFC,$0000,$FFFC,$0000,$FFFC,$0004,$FFFC,$7FE4         ;................
L000339BC                       dc.w    $007F,$FC00,$0000,$0000,$BFFF,$FFE4,$FFFF,$FFF4         ;................
L000339CC                       dc.w    $BFFC,$0000,$FFFC,$7F8C,$BFFF,$C000,$FFFF,$C000         ;................
L000339DC                       dc.w    $BFFD,$FFFC,$FFFF,$FF8C,$007F,$FC00,$0000,$0000         ;................
L000339EC                       dc.w    $8FFF,$FF0C,$FFE1,$FFE8,$8FFC,$0000,$8E1C,$7F1C         ;................
L000339FC                       dc.w    $8FFF,$C000,$FFE1,$C000,$8FFD,$FF0C,$8E1F,$FF1C         ;................
L00033A0C                       dc.w    $005F,$FC00,$0000,$0000,$F1FF,$F87C,$FF0F,$FFE8         ;._.........|....
L00033A1C                       dc.w    $F1FC,$0000,$BF84,$787C,$F1FF,$C000,$FF0F,$C000         ;......x|........
L00033A2C                       dc.w    $F1FD,$F87C,$BF87,$F87C,$0047,$FC00,$0000,$0000         ;...|...|.G......
L00033A3C                       dc.w    $FC7F,$DFFC,$FC3F,$FFF4,$FC7C,$0000,$FFE4,$43FC         ;.....?...|....C.
L00033A4C                       dc.w    $FC7F,$C000,$FC3F,$C000,$FC7D,$DFFC,$FFE7,$C3FC         ;.....?...}......
L00033A5C                       dc.w    $0061,$C400,$0000,$0000,$FF04,$7FFC,$87FC,$7FFC         ;.a..............
L00033A6C                       dc.w    $FF04,$0000,$FFFC,$7FFC,$FF04,$0000,$87FC,$0000         ;................
L00033A7C                       dc.w    $FF04,$7FFC,$FFFC,$7FFC,$0078,$3C00,$0000,$0000         ;.........x<.....
L00033A8C                       dc.w    $FFFC,$7FFC,$FFFC,$7FF8,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L00033A9C                       dc.w    $FFFC,$7FFC,$FFFC,$0000,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L00033AAC                       dc.w    $007F,$FC00,$0000,$0000,$8004,$4004,$8004,$4004         ;..........@...@.
L00033ABC                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$0000         ;..@...@...@.....
L00033ACC                       dc.w    $8004,$4004,$8004,$4004,$0040,$0400,$0000,$0000         ;..@...@..@......
L00033ADC                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L00033AEC                       dc.w    $8004,$4004,$8004,$0000,$8004,$4004,$8004,$4004         ;..@.......@...@.
L00033AFC                       dc.w    $0040,$0400,$0000,$0000,$8004,$4004,$8004,$4004         ;.@........@...@.
L00033B0C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$0000         ;..@...@...@.....
L00033B1C                       dc.w    $8004,$4004,$8004,$4004,$0040,$0400,$0000,$0000         ;..@...@..@......
L00033B2C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L00033B3C                       dc.w    $8004,$4004,$8004,$0000,$8004,$4004,$8004,$4004         ;..@.......@...@.
L00033B4C                       dc.w    $0040,$0400,$0000,$0000,$FFFC,$7FFC,$FFFC,$7FFC         ;.@..............
L00033B5C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$0000         ;................
L00033B6C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$007F,$FC00,$0000,$0000         ;................
L00033B7C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L00033B8C                       dc.w    $8004,$4004,$8004,$0000,$8004,$4004,$8004,$4004         ;..@.......@...@.
L00033B9C                       dc.w    $0040,$0400,$0000,$0000,$8004,$4004,$8004,$4000         ;.@........@...@.
L00033BAC                       dc.w    $0004,$4000,$8004,$4000,$0004,$4000,$8004,$0000         ;..@...@...@.....
L00033BBC                       dc.w    $0004,$4004,$8004,$4004,$0040,$0400,$0000,$0000         ;..@...@..@......
L00033BCC                       dc.w    $FFFC,$7FFC,$FFFF,$FFFC,$FFFF,$FFFC,$FFFF,$FFFC         ;................
L00033BDC                       dc.w    $FFFF,$FFFC,$FFFC,$0000,$FFFF,$FFFC,$FFFC,$7FFC         ;................
L00033BEC                       dc.w    $07FF,$FFC0,$0000,$0000,$FFFC,$7FFC,$FFFF,$FFF4         ;................
L00033BFC                       dc.w    $BFFF,$FFF4,$FFFF,$FFF4,$BFFF,$FFF4,$FFFC,$0000         ;................
L00033C0C                       dc.w    $BFFF,$FFFC,$FFFC,$7FFC,$07FF,$FFC0,$0000,$0000         ;................
L00033C1C                       dc.w    $FFFC,$7FFC,$FFFF,$FFE8,$5FFF,$FFE8,$FFFF,$FFE8         ;........_.......
L00033C2C                       dc.w    $5FFF,$FFE8,$FFFC,$0000,$5FFF,$FFFC,$FFFC,$7FFC         ;_......._.......
L00033C3C                       dc.w    $07FF,$FFC0,$0000,$0000,$FFFC,$7FFC,$FFFF,$FFB0         ;................
L00033C4C                       dc.w    $37FF,$FFB0,$FFFF,$FFB0,$37FF,$FFB0,$FFFC,$0000         ;7.......7.......
L00033C5C                       dc.w    $37FF,$FFFC,$FFFC,$7FFC,$07FF,$FFC0,$0000,$0000         ;7...............
L00033C6C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00033C7C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00033C8C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00033C9C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00033CAC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0007,$FFFC         ;................
L00033CBC                       dc.w    $FFFC,$7FFC,$FFFC,$0000,$FFFC,$7FFC,$FFFF,$FFB0         ;................
L00033CCC                       dc.w    $37FF,$FFB0,$FFFF,$FFB0,$37FF,$FFB0,$FFFF,$FFB0         ;7.......7.......
L00033CDC                       dc.w    $37FF,$FFB0,$0007,$FFFC,$FFFC,$7FFC,$FFFC,$0000         ;7...............
L00033CEC                       dc.w    $FFFE,$FFFC,$FFFF,$FFE0,$5FFF,$FFE8,$FFFF,$FFE0         ;........_.......
L00033CFC                       dc.w    $1FFF,$FFE0,$FFFF,$FFE0,$1FFF,$FFE0,$0007,$FFFC         ;................
L00033D0C                       dc.w    $FFFC,$7FFC,$FFFC,$0000,$FFFF,$FFFC,$FFFF,$FFF4         ;................
L00033D1C                       dc.w    $BFFF,$FFF4,$FFFF,$FFF4,$BFFF,$FFF4,$FFFF,$FFF4         ;................
L00033D2C                       dc.w    $BFFF,$FFF4,$0007,$FFFC,$FFFC,$7FFC,$FFFC,$0000         ;................
L00033D3C                       dc.w    $FFFF,$FFFC,$FFFF,$FFFC,$FFFF,$FFFC,$FFFF,$FFFC         ;................
L00033D4C                       dc.w    $FFFF,$FFFC,$FFFF,$FFFC,$FFFF,$FFFC,$0000,$7FFC         ;................
L00033D5C                       dc.w    $FFFC,$7FFC,$FFFC,$0000,$FFFF,$FFFC,$FFFC,$7FF8         ;................
L00033D6C                       dc.w    $7FFC,$7FF8,$FFFC,$7FF8,$7FFC,$7FF8,$FFFC,$7FF8         ;................
L00033D7C                       dc.w    $7FFC,$7FF8,$0000,$7FFC,$FFFC,$7FFC,$FFFC,$0000         ;................
L00033D8C                       dc.w    $FFFF,$FFFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L00033D9C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$0000,$7FFC         ;................
L00033DAC                       dc.w    $FFFC,$7FFC,$FFFC,$0000,$FFFF,$FFFC,$FFFC,$7FFC         ;................
L00033DBC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L00033DCC                       dc.w    $FFFC,$7FFC,$0000,$7FFC,$FFFC,$7FFC,$FFFC,$0000         ;................
L00033DDC                       dc.w    $FFFF,$FFFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L00033DEC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$0000,$7FFC         ;................
L00033DFC                       dc.w    $FFFC,$7FFC,$FFFC,$0000,$FFFF,$FFFC,$FFFC,$7FFC         ;................
L00033E0C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L00033E1C                       dc.w    $FFFC,$7FFC,$0000,$7FFC,$FFFC,$7FFC,$FFFC,$0000         ;................
L00033E2C                       dc.w    $FFFD,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L00033E3C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$0000,$7FFC         ;................
L00033E4C                       dc.w    $FFFC,$7FFC,$FFFC,$0000,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L00033E5C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FF4,$FFFC,$7FFC         ;................
L00033E6C                       dc.w    $FFFC,$7FFC,$0000,$7FFC,$FFFC,$7FF8,$FFFC,$0000         ;................
L00033E7C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L00033E8C                       dc.w    $FFFC,$7FF4,$FFFC,$7FF8,$FFFC,$7FFC,$0000,$7FF4         ;................
L00033E9C                       dc.w    $FFFC,$4E3C,$FFFC,$0000,$FFFC,$7FF4,$FFFC,$4E3C         ;..N<..........N<
L00033EAC                       dc.w    $FFFC,$4E3C,$FFFC,$7FF8,$FFFC,$7FE4,$FFFC,$7FFC         ;..N<............
L00033EBC                       dc.w    $7FFC,$0000,$0000,$7FE4,$FFFF,$FFF4,$FFFC,$0000         ;................
L00033ECC                       dc.w    $BFFC,$7FE4,$FFFC,$7F8C,$FFFC,$7F8C,$BFFF,$FFFC         ;................
L00033EDC                       dc.w    $FFFC,$7F8C,$BFFF,$FFF4,$FFFF,$FFB0,$0000,$7F0C         ;................
L00033EEC                       dc.w    $FFE1,$FFE8,$8E1C,$0000,$8FFC,$7F0C,$FFE4,$7FC4         ;................
L00033EFC                       dc.w    $FFE4,$7FC4,$8FFF,$FFF4,$8E1C,$7F1C,$8FFF,$FFE8         ;................
L00033F0C                       dc.w    $BFFF,$FFE0,$0000,$787C,$FF0F,$FFE8,$BF84,$0000         ;......x|........
L00033F1C                       dc.w    $F1FC,$787C,$FF0C,$7FF4,$FF0C,$7FF4,$F1FF,$FFE0         ;..x|............
L00033F2C                       dc.w    $BF84,$787C,$F1FF,$F868,$1FFF,$F874,$0000,$5FFC         ;..x|...h...t.._.
L00033F3C                       dc.w    $FC3F,$FFF4,$FFE4,$0000,$FC7C,$5FFC,$FC3C,$7FFC         ;.?.......|_..<..
L00033F4C                       dc.w    $FC3C,$7FFC,$FC7F,$FFB0,$FFE4,$43FC,$FC7F,$DFF4         ;.<........C.....
L00033F5C                       dc.w    $37FF,$DFFC,$0000,$7FFC,$87FC,$7FFC,$FFFC,$0000         ;7...............
L00033F6C                       dc.w    $FF04,$7FFC,$87FC,$7FFC,$87FC,$7FFC,$FF04,$0000         ;................
L00033F7C                       dc.w    $FFFC,$7FFC,$FF04,$7FFC,$0000,$7FF8,$FFFC,$7FFC         ;................
L00033F8C                       dc.w    $FFFC,$7FF8,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L00033F9C                       dc.w    $FFFC,$7FFC,$FFFC,$0000,$FFFC,$7FFC,$FFFC,$7FE8         ;................
L00033FAC                       dc.w    $FFFC,$7FF4,$8004,$4004,$8004,$4004,$8004,$4004         ;......@...@...@.
L00033FBC                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$0000         ;..@...@...@.....
L00033FCC                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L00033FDC                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L00033FEC                       dc.w    $8004,$4004,$8004,$0000,$8004,$4004,$8004,$4004         ;..@.......@...@.
L00033FFC                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L0003400C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$0000         ;..@...@...@.....
L0003401C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L0003402C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L0003403C                       dc.w    $8004,$4004,$8004,$0000,$8004,$4004,$8004,$4004         ;..@.......@...@.
L0003404C                       dc.w    $8004,$4004,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;..@.............
L0003405C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$0000         ;................
L0003406C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$8004,$4004         ;..............@.
L0003407C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L0003408C                       dc.w    $8004,$4004,$8004,$0000,$8004,$4004,$8004,$4004         ;..@.......@...@.
L0003409C                       dc.w    $8004,$4004,$0004,$4000,$8004,$4004,$0004,$4000         ;..@...@...@...@.
L000340AC                       dc.w    $8004,$4004,$8004,$4004,$0004,$4000,$8004,$0000         ;..@...@...@.....
L000340BC                       dc.w    $0004,$4004,$8004,$4004,$0004,$4000,$FFFF,$FFFC         ;..@...@...@.....
L000340CC                       dc.w    $FFFC,$7FFC,$FFFF,$FFFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L000340DC                       dc.w    $FFFF,$FFFC,$FFFC,$0000,$FFFF,$FFFC,$FFFC,$7FFC         ;................
L000340EC                       dc.w    $FFFF,$FFFC,$BFFF,$FFF4,$FFFC,$7FFC,$BFFF,$FFF4         ;................
L000340FC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$BFFF,$FFF4,$FFFC,$0000         ;................
L0003410C                       dc.w    $BFFF,$FFFC,$FFFC,$7FFC,$BFFF,$FFF4,$5FFF,$FFE8         ;............_...
L0003411C                       dc.w    $FFFC,$7FFC,$5FFF,$FFE8,$FFFC,$7FFC,$FFFC,$7FFC         ;...._...........
L0003412C                       dc.w    $5FFF,$FFE8,$FFFC,$0000,$5FFF,$FFFC,$FFFC,$7FFC         ;_......._.......
L0003413C                       dc.w    $5FFF,$FFE8,$37FF,$FFB0,$FFFC,$7FFC,$37FF,$FFB0         ;_...7.......7...
L0003414C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$37FF,$FFB0,$FFFC,$0000         ;........7.......
L0003415C                       dc.w    $37FF,$FFFC,$FFFC,$7FFC,$37FF,$FFB0,$0000,$0000         ;7.......7.......
L0003416C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003417C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003418C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003419C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L000341AC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$FFFC,$0000         ;................
L000341BC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFF8,$FFFC,$FFFC,$7FFC         ;................
L000341CC                       dc.w    $FFFC,$7FFC,$37FF,$FFFC,$006F,$FF00,$0000,$0000         ;....7....o......
L000341DC                       dc.w    $00FF,$F600,$FFFC,$0000,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L000341EC                       dc.w    $FFF8,$FFFC,$FFFC,$7FFC,$FFFC,$7FFC,$5FFF,$FFFC         ;............_...
L000341FC                       dc.w    $00BF,$FF00,$0000,$0000,$00FF,$FD00,$FFFC,$0000         ;................
L0003420C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFF8,$FFFC,$FFFC,$7FFC         ;................
L0003421C                       dc.w    $FFFC,$7FFC,$BFFF,$FFFC,$017F,$FF00,$0000,$0000         ;................
L0003422C                       dc.w    $00FF,$FE80,$FFFC,$0000,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003423C                       dc.w    $FFF8,$FFFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFF,$FFFC         ;................
L0003424C                       dc.w    $01FF,$FF00,$00FF,$FC00,$00FF,$FF80,$FFFC,$0000         ;................
L0003425C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFF8,$FFFC,$FFFC,$7FFC         ;................
L0003426C                       dc.w    $FFFC,$7FFC,$7FFC,$7FFC,$00FF,$F000,$00FF,$FC00         ;................
L0003427C                       dc.w    $000F,$FF00,$FFFC,$0000,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003428C                       dc.w    $FFF8,$FFFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003429C                       dc.w    $01FF,$F000,$00FF,$FC00,$000F,$FF80,$FFFC,$0000         ;................
L000342AC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFF8,$FFFC,$FFFC,$7FFC         ;................
L000342BC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$01FF,$F000,$00FF,$FC00         ;................
L000342CC                       dc.w    $000F,$FF80,$FFFC,$0000,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L000342DC                       dc.w    $FFF8,$FFFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L000342EC                       dc.w    $01FF,$F000,$00FF,$FC00,$000F,$FF80,$FFFC,$0000         ;................
L000342FC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFF8,$FFFC,$FFFC,$7FFC         ;................
L0003430C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$01FF,$F000,$00FF,$FC00         ;................
L0003431C                       dc.w    $000F,$FF80,$FFFC,$0000,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003432C                       dc.w    $FFF8,$FFFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003433C                       dc.w    $01FF,$F000,$00FF,$FC00,$000F,$FF80,$FFFC,$0000         ;................
L0003434C                       dc.w    $FFFC,$7FF4,$FFFC,$7FFC,$FFF8,$FFF4,$FFFC,$7FFC         ;................
L0003435C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$01FF,$F000,$00FF,$FC00         ;................
L0003436C                       dc.w    $000F,$FF80,$FFFC,$0000,$FFFC,$7FF4,$FFFC,$7FFC         ;................
L0003437C                       dc.w    $FFF8,$FFF4,$7FFC,$7FF8,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003438C                       dc.w    $01FF,$F000,$00FF,$FC00,$000F,$FF80,$FFFC,$0000         ;................
L0003439C                       dc.w    $FFFC,$7FE4,$FFFC,$7FF4,$FFF8,$FFE4,$FFFC,$4E3C         ;..............N<
L000343AC                       dc.w    $7FFC,$7FF4,$0000,$7FF8,$01FF,$F000,$00FF,$0C00         ;................
L000343BC                       dc.w    $000F,$FF80,$FFFF,$C000,$FFFC,$7F8C,$BFFC,$7FE4         ;................
L000343CC                       dc.w    $FFF8,$FF8C,$BFFF,$FFF4,$FFFF,$FFE4,$37FF,$FFFC         ;............7...
L000343DC                       dc.w    $01FF,$F000,$0FF8,$7FC0,$000F,$FF80,$FFE1,$C000         ;................
L000343EC                       dc.w    $8E1C,$7F1C,$8FFC,$7F0C,$8E18,$FF1C,$5FE1,$FFE8         ;............_...
L000343FC                       dc.w    $BFFF,$FF0C,$5E1F,$FFF4,$010F,$F000,$0FE1,$FFC0         ;....^...........
L0003440C                       dc.w    $000F,$FE80,$FF0F,$C000,$BF84,$787C,$F1FC,$787C         ;..........x|..x|
L0003441C                       dc.w    $BF88,$F87C,$5F0F,$FFE8,$5FFF,$F87C,$BF87,$FFE8         ;...|_..._..|....
L0003442C                       dc.w    $01C3,$F000,$0F0F,$FFC0,$000F,$F080,$FC3F,$C000         ;.............?..
L0003443C                       dc.w    $FFE4,$43FC,$FC7C,$5FFC,$FFE8,$C3FC,$BC3F,$FFF4         ;..C..|_......?..
L0003444C                       dc.w    $37FF,$DFFC,$FFE7,$FFB0,$01F0,$F000,$0FBF,$FFC0         ;7...............
L0003445C                       dc.w    $000C,$3F80,$87FC,$0000,$FFFC,$7FFC,$FF04,$7FFC         ;..?.............
L0003446C                       dc.w    $FFF8,$BFFC,$E7FC,$7FFC,$0000,$7FFC,$7FFC,$0000         ;................
L0003447C                       dc.w    $01FC,$1000,$00FF,$FC00,$000B,$FF80,$FFFC,$7FFC         ;................
L0003448C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFA,$FFFC,$5FFC,$7FF8         ;............_...
L0003449C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$01FF,$F000,$00FF,$FC00         ;................
L000344AC                       dc.w    $000F,$FF80,$8004,$4004,$8004,$4004,$8004,$4004         ;......@...@...@.
L000344BC                       dc.w    $800F,$8004,$8004,$4004,$8004,$4004,$C004,$4004         ;......@...@...@.
L000344CC                       dc.w    $0100,$1000,$0080,$0400,$0008,$0080,$8004,$4004         ;..............@.
L000344DC                       dc.w    $8004,$4004,$C004,$400C,$8007,$0004,$8004,$4004         ;..@...@.......@.
L000344EC                       dc.w    $8004,$4004,$8004,$4004,$0100,$1000,$0080,$0400         ;..@...@.........
L000344FC                       dc.w    $0008,$0080,$8004,$4004,$8004,$4004,$6004,$4018         ;......@...@.`.@.
L0003450C                       dc.w    $8000,$0004,$8004,$4004,$8004,$4004,$8004,$4004         ;......@...@...@.
L0003451C                       dc.w    $0100,$1000,$0080,$0400,$0008,$0080,$8004,$4004         ;..............@.
L0003452C                       dc.w    $8004,$4004,$3004,$4030,$8000,$0004,$8004,$4004         ;..@.0.@0......@.
L0003453C                       dc.w    $8004,$4004,$8004,$4004,$0100,$1000,$0080,$0400         ;..@...@.........
L0003454C                       dc.w    $0008,$0080,$FFFC,$7FFC,$FFFC,$7FFC,$1FFC,$7FE0         ;................
L0003455C                       dc.w    $FFFF,$FFFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003456C                       dc.w    $01FF,$F000,$00FF,$FC00,$000F,$FF80,$8004,$4004         ;..............@.
L0003457C                       dc.w    $8004,$4004,$0C04,$40C0,$8000,$0004,$8004,$4004         ;..@...@.......@.
L0003458C                       dc.w    $8004,$4004,$8004,$4004,$0100,$1000,$0080,$0400         ;..@...@.........
L0003459C                       dc.w    $0008,$0080,$0004,$4000,$0004,$4000,$0604,$4180         ;......@...@...A.
L000345AC                       dc.w    $0000,$0000,$8004,$4004,$0004,$4000,$8004,$4000         ;......@...@...@.
L000345BC                       dc.w    $0000,$1000,$0080,$0400,$0008,$0000,$FFFF,$FFFC         ;................
L000345CC                       dc.w    $FFFF,$FFFC,$03FF,$FF00,$FFFF,$FFFC,$FFFC,$7FFC         ;................
L000345DC                       dc.w    $FFFF,$FFFC,$FFFF,$FFFC,$01FF,$FF00,$00FF,$FC00         ;................
L000345EC                       dc.w    $00FF,$FF80,$BFFF,$FFF4,$BFFF,$FFF4,$01FF,$FE00         ;................
L000345FC                       dc.w    $BFFA,$FFF4,$FFFC,$7FFC,$BFFF,$FFF4,$FFFF,$FFF4         ;................
L0003460C                       dc.w    $017F,$FF00,$0000,$0000,$00FF,$FE80,$5FFF,$FFE8         ;............_...
L0003461C                       dc.w    $5FFF,$FFE8,$00FF,$FC00,$5FF5,$7FE8,$FFFC,$7FFC         ;_......._.......
L0003462C                       dc.w    $5FFF,$FFE8,$FFFF,$FFE8,$00BF,$FF00,$0000,$0000         ;_...............
L0003463C                       dc.w    $00FF,$FD00,$37FF,$FFB0,$37FF,$FFB0,$007F,$F800         ;....7...7.......
L0003464C                       dc.w    $37D8,$DFB0,$FFFC,$7FFC,$37FF,$FFB0,$FFFF,$FFB0         ;7.......7.......
L0003465C                       dc.w    $006F,$FF00,$0000,$0000,$00FF,$F600,$0000,$0000         ;.o..............
L0003466C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003467C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003468C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003469C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L000346AC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L000346BC                       dc.w    $0000,$0000,$0000,$0000,$0007,$0000,$1BFF,$FFD8         ;................
L000346CC                       dc.w    $00FF,$EC00,$1BFF,$FFD8,$1BFF,$FFD8,$7FFE,$3FFE         ;..............?.
L000346DC                       dc.w    $7FFF,$FFD8,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L000346EC                       dc.w    $0002,$0000,$2800,$0014,$0080,$0A00,$0800,$0014         ;....(...........
L000346FC                       dc.w    $2800,$0014,$4002,$2002,$4000,$0014,$0000,$0000         ;(...@. .@.......
L0003470C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$5000,$000A         ;............P...
L0003471C                       dc.w    $0080,$0500,$5000,$000A,$5000,$000A,$4002,$2002         ;....P...P...@. .
L0003472C                       dc.w    $4000,$000A,$0000,$0000,$0000,$0000,$0000,$0000         ;@...............
L0003473C                       dc.w    $0000,$0000,$6003,$E006,$00F0,$0300,$6003,$E006         ;....`.......`...
L0003474C                       dc.w    $6003,$E006,$4002,$2002,$4003,$E006,$0000,$0000         ;`...@. .@.......
L0003475C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0002,$2000         ;.............. .
L0003476C                       dc.w    $0010,$0000,$0002,$2000,$0002,$2000,$4002,$2002         ;...... ... .@. .
L0003477C                       dc.w    $4002,$2000,$0000,$0000,$0000,$0000,$0000,$0000         ;@. .............
L0003478C                       dc.w    $0002,$0000,$4002,$2002,$0010,$0100,$4002,$2002         ;....@. .....@. .
L0003479C                       dc.w    $4002,$2002,$4002,$2002,$4002,$2002,$0000,$0000         ;@. .@. .@. .....
L000347AC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$4002,$2002         ;............@. .
L000347BC                       dc.w    $0010,$0100,$4002,$2002,$4002,$2002,$4002,$2002         ;....@. .@. .@. .
L000347CC                       dc.w    $4002,$2002,$0000,$0000,$0000,$0000,$0000,$0000         ;@. .............
L000347DC                       dc.w    $0000,$0000,$4002,$2002,$0010,$0100,$4002,$2002         ;....@. .....@. .
L000347EC                       dc.w    $4002,$2002,$4002,$2002,$4002,$2002,$0000,$0000         ;@. .@. .@. .....
L000347FC                       dc.w    $0000,$0000,$0000,$0000,$8080,$0000,$4002,$2002         ;............@. .
L0003480C                       dc.w    $0010,$0100,$4002,$2002,$4002,$2002,$4002,$2002         ;....@. .@. .@. .
L0003481C                       dc.w    $4002,$2002,$0000,$0000,$0000,$0000,$0000,$0000         ;@. .............
L0003482C                       dc.w    $0000,$0000,$4002,$2002,$0010,$0100,$4002,$2002         ;....@. .....@. .
L0003483C                       dc.w    $4002,$2002,$4002,$2002,$4002,$2002,$0000,$0000         ;@. .@. .@. .....
L0003484C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$4002,$2002         ;............@. .
L0003485C                       dc.w    $0010,$0100,$4002,$2002,$4002,$2002,$4002,$2002         ;....@. .@. .@. .
L0003486C                       dc.w    $4002,$2002,$0000,$0000,$0000,$0000,$0000,$0000         ;@. .............
L0003487C                       dc.w    $0000,$0000,$4002,$2002,$0010,$0100,$7FFE,$2002         ;....@. ....... .
L0003488C                       dc.w    $7FFE,$2000,$4002,$2002,$4002,$3FFE,$0000,$0000         ;.. .@. .@.?.....
L0003489C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$4002,$2006         ;............@. .
L000348AC                       dc.w    $0010,$0100,$0000,$2000,$0000,$3FC6,$0002,$2002         ;...... ...?... .
L000348BC                       dc.w    $4002,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;@...............
L000348CC                       dc.w    $0000,$0000,$4002,$200E,$0010,$0100,$1BFF,$E006         ;....@. .........
L000348DC                       dc.w    $0003,$FFFA,$6003,$E006,$4003,$FFD8,$0000,$0000         ;....`...@.......
L000348EC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$5FC2,$203E         ;............_. >
L000348FC                       dc.w    $0010,$0100,$2BC0,$000A,$0003,$FFF4,$5000,$001E         ;....+.......P...
L0003490C                       dc.w    $4003,$FFD4,$0000,$0000,$0000,$0000,$0000,$0000         ;@...............
L0003491C                       dc.w    $0000,$0000,$7FF2,$20FE,$0010,$0100,$5FF0,$0014         ;...... ....._...
L0003492C                       dc.w    $0003,$FFF4,$2800,$00FE,$401F,$FFFA,$0000,$0000         ;....(...@.......
L0003493C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$7FFE,$27FE         ;..............'.
L0003494C                       dc.w    $0010,$3F00,$7FFF,$FFD8,$0003,$FFFA,$1BFF,$FFFE         ;..?.............
L0003495C                       dc.w    $7FFF,$FFFE,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003496C                       dc.w    $0000,$0000,$7FFE,$3FFE,$0013,$FF00,$1FFE,$0000         ;......?.........
L0003497C                       dc.w    $0000,$3FFE,$0000,$3FFE,$0000,$3FF8,$0000,$0000         ;..?...?...?.....
L0003498C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$7FFE,$3FFE         ;..............?.
L0003499C                       dc.w    $001F,$FF00,$7FFE,$3FFE,$7FFE,$3FF8,$0000,$3FFE         ;......?...?...?.
L000349AC                       dc.w    $7FFE,$3FFE,$0000,$0000,$0000,$0000,$0000,$0000         ;..?.............
L000349BC                       dc.w    $0000,$0000,$7FFE,$3FFE,$001F,$FF00,$7FFE,$3FFE         ;......?.......?.
L000349CC                       dc.w    $7FFE,$3FFE,$0000,$3FFE,$7FFE,$3FFE,$0000,$0000         ;..?...?...?.....
L000349DC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$7FFE,$3FFE         ;..............?.
L000349EC                       dc.w    $001F,$FF00,$7FFE,$3FFE,$7FFE,$3FFE,$0000,$3FFE         ;......?...?...?.
L000349FC                       dc.w    $7FFE,$3FFE,$0000,$0000,$0000,$0000,$0000,$0000         ;..?.............
L00034A0C                       dc.w    $0000,$0000,$7FFE,$3FFE,$001F,$FF00,$7FFE,$3FFE         ;......?.......?.
L00034A1C                       dc.w    $7FFE,$3FFE,$0000,$3FFE,$7FFE,$3FFE,$07F8,$0000         ;..?...?...?.....
L00034A2C                       dc.w    $0000,$0000,$07F8,$0000,$0000,$0000,$7FFE,$3FFE         ;..............?.
L00034A3C                       dc.w    $001F,$FF00,$7FFE,$3FFE,$7FFE,$3FFE,$0000,$3FFE         ;......?...?...?.
L00034A4C                       dc.w    $7FFE,$3FFE,$0408,$0000,$0000,$0000,$0408,$0000         ;..?.............
L00034A5C                       dc.w    $0000,$0000,$4002,$2002,$0010,$0100,$4002,$2002         ;....@. .....@. .
L00034A6C                       dc.w    $4002,$2002,$0000,$2002,$4002,$2002,$0408,$0000         ;@. ... .@. .....
L00034A7C                       dc.w    $0000,$0000,$0408,$0000,$0000,$0000,$4002,$2002         ;............@. .
L00034A8C                       dc.w    $0010,$0100,$4002,$2002,$4002,$2002,$0000,$2002         ;....@. .@. ... .
L00034A9C                       dc.w    $4002,$2002,$0408,$0000,$0000,$0000,$0408,$0000         ;@. .............
L00034AAC                       dc.w    $0000,$0000,$0002,$2000,$0010,$0100,$4002,$2002         ;...... .....@. .
L00034ABC                       dc.w    $0002,$2000,$0000,$2002,$0002,$2000,$0408,$0000         ;.. ... ... .....
L00034ACC                       dc.w    $0000,$0000,$0408,$0000,$0000,$0000,$6003,$E006         ;............`...
L00034ADC                       dc.w    $0010,$0100,$4003,$E002,$6003,$E006,$0000,$2002         ;....@...`..... .
L00034AEC                       dc.w    $6003,$E006,$07C8,$0000,$0000,$0000,$0408,$0000         ;`...............
L00034AFC                       dc.w    $0000,$0000,$5000,$000A,$0010,$0100,$4000,$0002         ;....P.......@...
L00034B0C                       dc.w    $5000,$000A,$0000,$2002,$5000,$000A,$0078,$0000         ;P..... .P....x..
L00034B1C                       dc.w    $0000,$0000,$07F8,$0000,$0000,$0000,$2FFF,$FFF4         ;............/...
L00034B2C                       dc.w    $001F,$FF00,$7FFF,$FFFE,$2FFF,$FFF4,$0000,$3FFE         ;......../.....?.
L00034B3C                       dc.w    $2FFF,$FFF4,$0078,$0000,$0000,$0000,$07F8,$0000         ;/....x..........
L00034B4C                       dc.w    $0000,$0000,$1BFF,$FFD8,$001F,$FF00,$7FFF,$FFFE         ;................
L00034B5C                       dc.w    $1BFF,$FFD8,$0000,$3FFE,$1BFF,$FFD8,$0000,$0000         ;......?.........
L00034B6C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00034B7C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00034B8C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00034B9C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00034BAC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$37FF,$FFB0         ;............7...
L00034BBC                       dc.w    $37FF,$FFB0,$37FF,$FFB0,$37FF,$FFB0,$0000,$0000         ;7...7...7.......
L00034BCC                       dc.w    $01FE,$7F80,$0001,$0000,$001F,$E000,$0002,$0000         ;................
L00034BDC                       dc.w    $1BFF,$FFD8,$1000,$0028,$5000,$0028,$5000,$0028         ;.......(P..(P..(
L00034BEC                       dc.w    $5000,$0028,$0000,$0000,$0102,$4080,$0001,$8000         ;P..(......@.....
L00034BFC                       dc.w    $0010,$2000,$0006,$0000,$0800,$0010,$A000,$0014         ;.. .............
L00034C0C                       dc.w    $A000,$0014,$A000,$0014,$A000,$0014,$0000,$0000         ;................
L00034C1C                       dc.w    $0102,$4080,$0001,$C000,$0010,$2000,$000E,$0000         ;..@....... .....
L00034C2C                       dc.w    $5000,$000A,$C007,$C00C,$C007,$C00C,$C007,$C00C         ;P...............
L00034C3C                       dc.w    $C00F,$800C,$0000,$0000,$0102,$4080,$0001,$6000         ;..........@...`.
L00034C4C                       dc.w    $0010,$2000,$001A,$0000,$6003,$E006,$0004,$4000         ;.. .....`.....@.
L00034C5C                       dc.w    $0004,$4000,$0004,$4000,$0008,$8000,$003F,$C000         ;..@...@......?..
L00034C6C                       dc.w    $0102,$4080,$0001,$3000,$0010,$2000,$0032,$0000         ;..@...0... ..2..
L00034C7C                       dc.w    $0002,$2000,$8004,$4004,$8004,$4004,$8004,$4004         ;.. ...@...@...@.
L00034C8C                       dc.w    $8008,$8004,$0020,$4000,$01F2,$7C80,$0001,$1800         ;..... @...|.....
L00034C9C                       dc.w    $0010,$2000,$0062,$0000,$4002,$2002,$8004,$4004         ;.. ..b..@. ...@.
L00034CAC                       dc.w    $8004,$4004,$8004,$4004,$8008,$8004,$0020,$4000         ;..@...@...... @.
L00034CBC                       dc.w    $0012,$0480,$0001,$0C00,$0010,$2000,$00C2,$0000         ;.......... .....
L00034CCC                       dc.w    $4002,$2002,$8004,$4004,$8004,$4004,$8004,$4004         ;@. ...@...@...@.
L00034CDC                       dc.w    $8008,$8004,$0020,$4000,$001E,$0780,$0001,$0600         ;..... @.........
L00034CEC                       dc.w    $0010,$2000,$0182,$0000,$4002,$2002,$8004,$4004         ;.. .....@. ...@.
L00034CFC                       dc.w    $8004,$4004,$8004,$4004,$8008,$8004,$0020,$4000         ;..@...@...... @.
L00034D0C                       dc.w    $0000,$0000,$0001,$0300,$0010,$2000,$0302,$0000         ;.......... .....
L00034D1C                       dc.w    $4002,$2002,$8004,$4004,$8004,$4004,$8004,$4004         ;@. ...@...@...@.
L00034D2C                       dc.w    $8008,$8004,$0020,$4000,$0000,$0000,$FFFF,$0180         ;..... @.........
L00034D3C                       dc.w    $0010,$2000,$0603,$FFFC,$4002,$2002,$8004,$4004         ;.. .....@. ...@.
L00034D4C                       dc.w    $8004,$4004,$8004,$4004,$8008,$8004,$0020,$4000         ;..@...@...... @.
L00034D5C                       dc.w    $0000,$0000,$8000,$00C0,$0010,$2000,$0C00,$0004         ;.......... .....
L00034D6C                       dc.w    $4002,$2002,$8004,$7FFC,$FFFC,$4004,$0004,$4000         ;@. .......@...@.
L00034D7C                       dc.w    $8008,$8004,$003F,$C000,$0000,$0000,$8000,$0060         ;.....?.........`
L00034D8C                       dc.w    $0010,$2000,$1800,$0004,$7FFE,$2002,$8004,$0000         ;.. ....... .....
L00034D9C                       dc.w    $0000,$4004,$C004,$7F8C,$0008,$8004,$0000,$0000         ;..@.............
L00034DAC                       dc.w    $0000,$0000,$8000,$0030,$0010,$2000,$3000,$000C         ;.......0.. .0...
L00034DBC                       dc.w    $0000,$2000,$8007,$FFB0,$0007,$C00C,$A007,$FFF4         ;.. .............
L00034DCC                       dc.w    $C00F,$800C,$0000,$0000,$0000,$0000,$8000,$0018         ;................
L00034DDC                       dc.w    $0010,$2000,$6000,$001C,$0006,$E006,$BF80,$0028         ;.. .`..........(
L00034DEC                       dc.w    $0004,$003C,$5007,$FFE8,$A000,$003C,$0000,$0000         ;...<P......<....
L00034DFC                       dc.w    $0000,$0000,$C000,$003C,$0010,$2000,$FF80,$007C         ;.......<.. ....|
L00034E0C                       dc.w    $0002,$000A,$FFE0,$01F4,$0004,$01FC,$503F,$FFE8         ;............P?..
L00034E1C                       dc.w    $5000,$01FC,$0000,$0000,$0000,$0000,$FC00,$01FC         ;P...............
L00034E2C                       dc.w    $0010,$2000,$FFE0,$01FC,$0014,$0010,$FFFF,$FFFC         ;.. .............
L00034E3C                       dc.w    $0007,$FFFC,$A0FF,$FFF4,$37FF,$FFFC,$0000,$0000         ;........7.......
L00034E4C                       dc.w    $0000,$0000,$FF00,$7FF8,$001C,$2000,$7FF8,$0FFC         ;.......... .....
L00034E5C                       dc.w    $001C,$3FD8,$FFFC,$7FF0,$0000,$7FFC,$DFFC,$7FFC         ;..?.............
L00034E6C                       dc.w    $0000,$FFFC,$003F,$C000,$0000,$0000,$FFC7,$FFF0         ;.....?..........
L00034E7C                       dc.w    $001F,$E000,$3FFF,$FFFC,$0007,$E000,$FFFC,$7FFC         ;....?...........
L00034E8C                       dc.w    $0000,$7FFC,$3FFC,$7FF0,$FFF8,$FFFC,$003F,$C000         ;....?........?..
L00034E9C                       dc.w    $0000,$0000,$FFFF,$FFE0,$001F,$E000,$1FFF,$FFFC         ;................
L00034EAC                       dc.w    $001F,$E000,$FFFC,$7FFC,$0000,$7FFC,$FFFC,$7FFC         ;................
L00034EBC                       dc.w    $FFF8,$FFFC,$003F,$C000,$0000,$0000,$FFFF,$FFC0         ;.....?..........
L00034ECC                       dc.w    $001F,$E000,$0FFF,$FFFC,$001F,$E000,$FFFC,$7FFC         ;................
L00034EDC                       dc.w    $0000,$7FFC,$FFFC,$7FFC,$FFF8,$FFFC,$003F,$C000         ;.............?..
L00034EEC                       dc.w    $0000,$0000,$FFFF,$FF80,$001F,$E000,$07FF,$FFFC         ;................
L00034EFC                       dc.w    $001F,$E000,$FFFC,$7FFC,$0000,$7FFC,$FFFC,$7FFC         ;................
L00034F0C                       dc.w    $FFF8,$FFFC,$003F,$C000,$0000,$0000,$0001,$FF00         ;.....?..........
L00034F1C                       dc.w    $001F,$E000,$03FE,$0000,$001F,$E000,$FFFC,$7FFC         ;................
L00034F2C                       dc.w    $0000,$7FFC,$FFFC,$7FFC,$FFF8,$FFFC,$0020,$4000         ;............. @.
L00034F3C                       dc.w    $0000,$0000,$0001,$F600,$001F,$E000,$01BE,$0000         ;................
L00034F4C                       dc.w    $001F,$E000,$8004,$4004,$0000,$4004,$8004,$4004         ;......@...@...@.
L00034F5C                       dc.w    $8008,$8004,$0020,$4000,$0000,$0000,$0001,$0C00         ;..... @.........
L00034F6C                       dc.w    $0010,$2000,$00C2,$0000,$0010,$2000,$8004,$4004         ;.. ....... ...@.
L00034F7C                       dc.w    $0000,$4004,$8004,$4004,$8008,$8004,$003F,$C000         ;..@...@......?..
L00034F8C                       dc.w    $0000,$0000,$0001,$1800,$001F,$E000,$0062,$0000         ;.............b..
L00034F9C                       dc.w    $001F,$E000,$0004,$4000,$0000,$4004,$0004,$4000         ;......@...@...@.
L00034FAC                       dc.w    $0008,$8000,$0000,$0000,$0000,$0000,$0001,$3000         ;..............0.
L00034FBC                       dc.w    $0000,$0000,$0032,$0000,$0000,$0000,$C007,$C00C         ;.....2..........
L00034FCC                       dc.w    $0000,$4004,$C007,$C00C,$C00F,$800C,$0000,$0000         ;..@.............
L00034FDC                       dc.w    $0000,$0000,$0001,$6000,$001F,$E000,$001A,$0000         ;......`.........
L00034FEC                       dc.w    $001F,$E000,$A000,$0014,$0000,$4004,$A000,$0014         ;..........@.....
L00034FFC                       dc.w    $A000,$0014,$0000,$0000,$0000,$0000,$0001,$C000         ;................
L0003500C                       dc.w    $0010,$2000,$000E,$0000,$0010,$2000,$5FFF,$FFE8         ;.. ....... ._...
L0003501C                       dc.w    $0000,$7FFC,$5FFF,$FFE8,$5FFF,$FFE8,$0000,$0000         ;...._..._.......
L0003502C                       dc.w    $0000,$0000,$0001,$8000,$001F,$E000,$0006,$0000         ;................
L0003503C                       dc.w    $001F,$E000,$37FF,$FFB0,$0000,$7FFC,$37FF,$FFB0         ;....7.......7...
L0003504C                       dc.w    $37FF,$FFB0,$0000,$0000,$0000,$0000,$0001,$0000         ;7...............
L0003505C                       dc.w    $001F,$E000,$0002,$0000,$001F,$E000,$0000,$0000         ;................
L0003506C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003507C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003508C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003509C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L000350AC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0FF0,$0000         ;................
L000350BC                       dc.w    $37FF,$FFB0,$FFFF,$FFB0,$37FF,$FFB0,$FFFF,$FFB0         ;7.......7.......
L000350CC                       dc.w    $37FF,$FFB0,$37FF,$FFB0,$37FF,$FFB0,$FFFC,$7FFC         ;7...7...7.......
L000350DC                       dc.w    $07FF,$FFC0,$0810,$0000,$1000,$0020,$8000,$0020         ;........... ... 
L000350EC                       dc.w    $1000,$0020,$8000,$0020,$1000,$0020,$1000,$0020         ;... ... ... ... 
L000350FC                       dc.w    $1000,$0020,$8004,$4004,$0400,$0040,$0810,$0000         ;... ..@....@....
L0003510C                       dc.w    $A000,$0014,$8000,$0014,$A000,$0014,$8000,$0014         ;................
L0003511C                       dc.w    $A000,$0014,$A000,$0014,$A000,$0014,$8004,$4004         ;..............@.
L0003512C                       dc.w    $0400,$0040,$0810,$0000,$C007,$C00C,$8007,$C00C         ;...@............
L0003513C                       dc.w    $C007,$C00C,$8007,$C00C,$C007,$C00C,$C007,$C00C         ;................
L0003514C                       dc.w    $C007,$C00C,$8004,$4004,$07C0,$07C0,$0810,$0000         ;......@.........
L0003515C                       dc.w    $0004,$4000,$8004,$4000,$0004,$4000,$8004,$4000         ;..@...@...@...@.
L0003516C                       dc.w    $0004,$4000,$0004,$4000,$0004,$4000,$8004,$4004         ;..@...@...@...@.
L0003517C                       dc.w    $0040,$0400,$0F90,$0000,$8004,$4004,$8004,$4004         ;.@........@...@.
L0003518C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L0003519C                       dc.w    $8004,$4004,$8004,$4004,$0040,$0400,$0090,$0000         ;..@...@..@......
L000351AC                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L000351BC                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L000351CC                       dc.w    $0040,$0400,$00F0,$0000,$8004,$4004,$8004,$4004         ;.@........@...@.
L000351DC                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L000351EC                       dc.w    $8004,$4004,$8004,$4004,$0040,$0400,$0000,$0000         ;..@...@..@......
L000351FC                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L0003520C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L0003521C                       dc.w    $0040,$0400,$0000,$0000,$8004,$4004,$8004,$4004         ;.@........@...@.
L0003522C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L0003523C                       dc.w    $8004,$4004,$8004,$4004,$0040,$0400,$0000,$0000         ;..@...@..@......
L0003524C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L0003525C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L0003526C                       dc.w    $0040,$0400,$0000,$0000,$8004,$4004,$8004,$4000         ;.@........@...@.
L0003527C                       dc.w    $8004,$7FFC,$8004,$4004,$8004,$7FFC,$8004,$7FFC         ;......@.........
L0003528C                       dc.w    $8004,$7FFC,$8004,$4004,$0040,$0400,$0000,$0000         ;......@..@......
L0003529C                       dc.w    $8004,$4004,$8004,$7F8C,$8004,$0000,$8004,$400C         ;..@...........@.
L000352AC                       dc.w    $8004,$0000,$8004,$0000,$8004,$0004,$8004,$400C         ;..............@.
L000352BC                       dc.w    $0040,$0400,$0000,$0000,$8007,$C00C,$8007,$FFF4         ;.@..............
L000352CC                       dc.w    $8004,$0000,$8004,$401C,$8007,$C000,$8007,$C000         ;......@.........
L000352DC                       dc.w    $8005,$FFFC,$8007,$C01C,$0040,$0400,$0000,$0000         ;.........@......
L000352EC                       dc.w    $C000,$003C,$8007,$FFE8,$C004,$0000,$BF84,$407C         ;...<..........@|
L000352FC                       dc.w    $C000,$4000,$8007,$C000,$C005,$003C,$BF80,$007C         ;..@........<...|
L0003530C                       dc.w    $0040,$0400,$0000,$0000,$FC00,$01FC,$803F,$FFE8         ;.@...........?..
L0003531C                       dc.w    $FC04,$0000,$FFE4,$41FC,$FC00,$4000,$803F,$C000         ;......A...@..?..
L0003532C                       dc.w    $FC05,$01FC,$FFE0,$01FC,$0060,$0400,$0000,$0000         ;.........`......
L0003533C                       dc.w    $FF07,$FFFC,$80FF,$FFF4,$FF04,$0000,$FFFC,$4FFC         ;..............O.
L0003534C                       dc.w    $FF07,$C000,$80FF,$C000,$FF05,$FFFC,$FFFF,$CFFC         ;................
L0003535C                       dc.w    $0078,$0C00,$0000,$0000,$FFC4,$7FFC,$9FFC,$7FFC         ;.x..............
L0003536C                       dc.w    $FFC4,$0000,$FFFC,$7FFC,$FFC4,$0000,$9FFC,$0000         ;................
L0003537C                       dc.w    $FFC4,$7FFC,$FFFC,$7FFC,$007F,$FC00,$0000,$0000         ;................
L0003538C                       dc.w    $FFFC,$7FFC,$FFFC,$7FF0,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003539C                       dc.w    $FFFC,$7FFC,$FFFC,$0000,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L000353AC                       dc.w    $007F,$FC00,$0000,$0000,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L000353BC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$0000         ;................
L000353CC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$007F,$FC00,$0000,$0000         ;................
L000353DC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L000353EC                       dc.w    $FFFC,$7FFC,$FFFC,$0000,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L000353FC                       dc.w    $007F,$FC00,$0000,$0000,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003540C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$0000         ;................
L0003541C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$007F,$FC00,$0000,$0000         ;................
L0003542C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003543C                       dc.w    $FFFC,$7FFC,$FFFC,$0000,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003544C                       dc.w    $007F,$FC00,$0000,$0000,$8004,$4004,$8004,$4004         ;..........@...@.
L0003545C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$0000         ;..@...@...@.....
L0003546C                       dc.w    $8004,$4004,$8004,$4004,$0040,$0400,$0000,$0000         ;..@...@..@......
L0003547C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L0003548C                       dc.w    $8004,$4004,$8004,$0000,$8004,$4004,$8004,$4004         ;..@.......@...@.
L0003549C                       dc.w    $0040,$0400,$0000,$0000,$8004,$4004,$8004,$4000         ;.@........@...@.
L000354AC                       dc.w    $0004,$4000,$8004,$4000,$0004,$4000,$8004,$0000         ;..@...@...@.....
L000354BC                       dc.w    $0004,$4004,$8004,$4004,$0040,$0400,$0000,$0000         ;..@...@..@......
L000354CC                       dc.w    $8004,$4004,$8007,$C00C,$C007,$C00C,$8007,$C00C         ;..@.............
L000354DC                       dc.w    $C007,$C00C,$8004,$0000,$C007,$C004,$8004,$4004         ;..............@.
L000354EC                       dc.w    $07C0,$07C0,$0000,$0000,$8004,$4004,$8000,$0014         ;..........@.....
L000354FC                       dc.w    $A000,$0014,$8000,$0014,$A000,$0014,$8004,$0000         ;................
L0003550C                       dc.w    $A000,$0004,$8004,$4004,$0400,$0040,$0000,$0000         ;......@....@....
L0003551C                       dc.w    $FFFC,$7FFC,$FFFF,$FFE8,$5FFF,$FFE8,$FFFF,$FFE8         ;........_.......
L0003552C                       dc.w    $5FFF,$FFE8,$FFFC,$0000,$5FFF,$FFFC,$FFFC,$7FFC         ;_......._.......
L0003553C                       dc.w    $07FF,$FFC0,$0000,$0000,$FFFC,$7FFC,$FFFF,$FFB0         ;................
L0003554C                       dc.w    $37FF,$FFB0,$FFFF,$FFB0,$37FF,$FFB0,$FFFC,$0000         ;7.......7.......
L0003555C                       dc.w    $37FF,$FFFC,$FFFC,$7FFC,$07FF,$FFC0,$0000,$0000         ;7...............
L0003556C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003557C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003558C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003559C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L000355AC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0007,$FFFC         ;................
L000355BC                       dc.w    $FFFC,$7FFC,$FFFC,$0000,$FFFC,$7FFC,$FFFF,$FFB0         ;................
L000355CC                       dc.w    $37FF,$FFB0,$FFFF,$FFB0,$37FF,$FFB0,$FFFF,$FFB0         ;7.......7.......
L000355DC                       dc.w    $37FF,$FFB0,$0004,$0004,$8004,$4004,$8004,$0000         ;7.........@.....
L000355EC                       dc.w    $8006,$C004,$8000,$0020,$5000,$0028,$8000,$0020         ;....... P..(... 
L000355FC                       dc.w    $1000,$0020,$8000,$0020,$1000,$0020,$0004,$0004         ;... ... ... ....
L0003560C                       dc.w    $8004,$4004,$8004,$0000,$8003,$8004,$8000,$0014         ;..@.............
L0003561C                       dc.w    $A000,$0014,$8000,$0014,$A000,$0014,$8000,$0014         ;................
L0003562C                       dc.w    $A000,$0014,$0007,$C004,$8004,$4004,$8004,$0000         ;..........@.....
L0003563C                       dc.w    $8001,$0004,$8007,$C00C,$C007,$C00C,$8007,$C00C         ;................
L0003564C                       dc.w    $C007,$C00C,$8007,$C00C,$C007,$C00C,$0000,$4004         ;..............@.
L0003565C                       dc.w    $8004,$4004,$8004,$0000,$8000,$0004,$8004,$4000         ;..@...........@.
L0003566C                       dc.w    $0004,$4000,$8004,$4000,$0004,$4000,$8004,$4000         ;..@...@...@...@.
L0003567C                       dc.w    $0004,$4000,$0000,$4004,$8004,$4004,$8004,$0000         ;..@...@...@.....
L0003568C                       dc.w    $8000,$0004,$8004,$4004,$8004,$4004,$8004,$4004         ;......@...@...@.
L0003569C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$0000,$4004         ;..@...@...@...@.
L000356AC                       dc.w    $8004,$4004,$8004,$0000,$8004,$4004,$8004,$4004         ;..@.......@...@.
L000356BC                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L000356CC                       dc.w    $8004,$4004,$0000,$4004,$8004,$4004,$8004,$0000         ;..@...@...@.....
L000356DC                       dc.w    $8006,$C004,$8004,$4004,$8004,$4004,$8004,$4004         ;......@...@...@.
L000356EC                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$0000,$4004         ;..@...@...@...@.
L000356FC                       dc.w    $8004,$4004,$8004,$0000,$8007,$C004,$8004,$4004         ;..@...........@.
L0003570C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L0003571C                       dc.w    $8004,$4004,$0000,$4004,$8004,$4004,$8004,$0000         ;..@...@...@.....
L0003572C                       dc.w    $8005,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L0003573C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$0000,$4004         ;..@...@...@...@.
L0003574C                       dc.w    $8004,$4004,$8004,$0000,$8004,$4004,$8004,$4004         ;..@.......@...@.
L0003575C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L0003576C                       dc.w    $8004,$4004,$0000,$4004,$8004,$4000,$8004,$0000         ;..@...@...@.....
L0003577C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L0003578C                       dc.w    $8004,$4004,$8004,$4000,$8004,$7FFC,$0000,$4004         ;..@...@.......@.
L0003579C                       dc.w    $8004,$7F8C,$8004,$0000,$8004,$4004,$8004,$7F84         ;..........@.....
L000357AC                       dc.w    $8004,$7F84,$8004,$4000,$8004,$400C,$8004,$400C         ;......@...@...@.
L000357BC                       dc.w    $0004,$0000,$0000,$400C,$8007,$FFF4,$8004,$0000         ;......@.........
L000357CC                       dc.w    $8004,$400C,$8004,$7FE4,$8004,$7FE4,$8007,$C00C         ;..@.............
L000357DC                       dc.w    $8004,$401C,$8007,$C014,$C007,$FFB0,$0000,$403C         ;..@...........@<
L000357EC                       dc.w    $8007,$FFE8,$BF84,$0000,$C004,$403C,$8004,$7FF4         ;..........@<....
L000357FC                       dc.w    $8004,$7FF4,$C000,$0014,$BF84,$407C,$C000,$0028         ;..........@|...(
L0003580C                       dc.w    $A000,$0020,$0000,$41FC,$803F,$FFE8,$FFE4,$0000         ;... ..A..?......
L0003581C                       dc.w    $FC04,$41FC,$803C,$7FFC,$803C,$7FFC,$FC00,$0020         ;..A..<...<..... 
L0003582C                       dc.w    $FFE4,$41FC,$FC00,$01E8,$1000,$01F4,$0000,$7FFC         ;..A.............
L0003583C                       dc.w    $80FF,$FFF4,$FFFC,$0000,$FF04,$7FFC,$80FC,$7FFC         ;................
L0003584C                       dc.w    $80FC,$7FFC,$FF07,$FFB0,$FFFC,$4FFC,$FF07,$FFF4         ;..........O.....
L0003585C                       dc.w    $37FF,$FFFC,$0000,$7FFC,$9FFC,$7FFC,$FFFC,$0000         ;7...............
L0003586C                       dc.w    $FFC4,$7FFC,$9FFC,$7FFC,$9FFC,$7FFC,$FFC4,$0000         ;................
L0003587C                       dc.w    $FFFC,$7FFC,$FFC4,$7FFC,$0000,$7FF0,$FFFC,$7FFC         ;................
L0003588C                       dc.w    $FFFC,$7FF0,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003589C                       dc.w    $FFFC,$7FFC,$FFFC,$0000,$FFFC,$7FFC,$FFFC,$7FF0         ;................
L000358AC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L000358BC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$0000         ;................
L000358CC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L000358DC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L000358EC                       dc.w    $FFFC,$7FFC,$FFFC,$0000,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L000358FC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003590C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$0000         ;................
L0003591C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003592C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003593C                       dc.w    $FFFC,$7FFC,$FFFC,$0000,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L0003594C                       dc.w    $FFFC,$7FFC,$8004,$4004,$8004,$4004,$8004,$4004         ;......@...@...@.
L0003595C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$0000         ;..@...@...@.....
L0003596C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L0003597C                       dc.w    $8004,$4004,$8004,$4004,$8004,$4004,$8004,$4004         ;..@...@...@...@.
L0003598C                       dc.w    $8004,$4004,$8004,$0000,$8004,$4004,$8004,$4004         ;..@.......@...@.
L0003599C                       dc.w    $8004,$4004,$0004,$4000,$8004,$4004,$0004,$4000         ;..@...@...@...@.
L000359AC                       dc.w    $8004,$4004,$8004,$4004,$0004,$4000,$8004,$0000         ;..@...@...@.....
L000359BC                       dc.w    $0004,$4004,$8004,$4004,$0004,$4000,$C007,$C00C         ;..@...@...@.....
L000359CC                       dc.w    $8004,$4004,$C007,$C00C,$8004,$4004,$8004,$4004         ;..@.......@...@.
L000359DC                       dc.w    $C007,$C00C,$8004,$0000,$C007,$C004,$8004,$4004         ;..............@.
L000359EC                       dc.w    $C007,$C00C,$A000,$0014,$8004,$4004,$A000,$0014         ;..........@.....
L000359FC                       dc.w    $8004,$4004,$8004,$4004,$A000,$0014,$8004,$0000         ;..@...@.........
L00035A0C                       dc.w    $A000,$0004,$8004,$4004,$A000,$0014,$5FFF,$FFE8         ;......@....._...
L00035A1C                       dc.w    $FFFC,$7FFC,$5FFF,$FFE8,$FFFC,$7FFC,$FFFC,$7FFC         ;...._...........
L00035A2C                       dc.w    $5FFF,$FFE8,$FFFC,$0000,$5FFF,$FFFC,$FFFC,$7FFC         ;_......._.......
L00035A3C                       dc.w    $5FFF,$FFE8,$37FF,$FFB0,$FFFC,$7FFC,$37FF,$FFB0         ;_...7.......7...
L00035A4C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$37FF,$FFB0,$FFFC,$0000         ;........7.......
L00035A5C                       dc.w    $37FF,$FFFC,$FFFC,$7FFC,$37FF,$FFB0,$0000,$0000         ;7.......7.......
L00035A6C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00035A7C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00035A8C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00035A9C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00035AAC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$FFFC,$0000         ;................
L00035ABC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFF8,$FFFC,$FFFC,$7FFC         ;................
L00035ACC                       dc.w    $FFFC,$7FFC,$37FF,$FFFC,$006F,$FF00,$0000,$0000         ;....7....o......
L00035ADC                       dc.w    $00FF,$F600,$8004,$0000,$8004,$4004,$8004,$4004         ;..........@...@.
L00035AEC                       dc.w    $8008,$8004,$8004,$4004,$8004,$4004,$5000,$0004         ;......@...@.P...
L00035AFC                       dc.w    $00A0,$0100,$0000,$0000,$0080,$0500,$8004,$0000         ;................
L00035B0C                       dc.w    $8004,$4004,$8004,$4004,$8008,$8004,$8004,$4004         ;..@...@.......@.
L00035B1C                       dc.w    $8004,$4004,$A000,$0004,$0140,$0100,$0000,$0000         ;..@......@......
L00035B2C                       dc.w    $0080,$0280,$8004,$0000,$8004,$4004,$8004,$4004         ;..........@...@.
L00035B3C                       dc.w    $8008,$8004,$8004,$4004,$8004,$4004,$C007,$C004         ;......@...@.....
L00035B4C                       dc.w    $0180,$1F00,$00FF,$FC00,$00F8,$0180,$8004,$0000         ;................
L00035B5C                       dc.w    $8004,$4004,$8004,$4004,$8008,$8004,$8004,$4004         ;..@...@.......@.
L00035B6C                       dc.w    $8004,$4004,$0004,$4004,$0000,$1000,$0080,$0400         ;..@...@.........
L00035B7C                       dc.w    $0008,$0000,$8004,$0000,$8004,$4004,$8004,$4004         ;..........@...@.
L00035B8C                       dc.w    $8008,$8004,$8004,$4004,$8004,$4004,$8004,$4004         ;......@...@...@.
L00035B9C                       dc.w    $0100,$1000,$0080,$0400,$0008,$0080,$8004,$0000         ;................
L00035BAC                       dc.w    $8004,$4004,$8004,$4004,$8008,$8004,$8004,$4004         ;..@...@.......@.
L00035BBC                       dc.w    $8004,$4004,$8004,$4004,$0100,$1000,$0080,$0400         ;..@...@.........
L00035BCC                       dc.w    $0008,$0080,$8004,$0000,$8004,$4004,$8004,$4004         ;..........@...@.
L00035BDC                       dc.w    $8008,$8004,$8004,$4004,$8004,$4004,$8004,$4004         ;......@...@...@.
L00035BEC                       dc.w    $0100,$1000,$0080,$0400,$0008,$0080,$8004,$0000         ;................
L00035BFC                       dc.w    $8004,$4004,$8004,$4004,$8008,$8004,$8004,$4004         ;..@...@.......@.
L00035C0C                       dc.w    $8004,$4004,$8004,$4004,$0100,$1000,$0080,$0400         ;..@...@.........
L00035C1C                       dc.w    $0008,$0080,$8004,$0000,$8004,$4004,$8004,$4004         ;..........@...@.
L00035C2C                       dc.w    $8008,$8004,$8004,$4004,$8004,$4004,$8004,$4004         ;......@...@...@.
L00035C3C                       dc.w    $0100,$1000,$0080,$0400,$0008,$0080,$8004,$0000         ;................
L00035C4C                       dc.w    $8004,$4004,$8004,$4004,$8008,$8004,$8004,$4004         ;..@...@.......@.
L00035C5C                       dc.w    $8004,$4004,$8004,$4004,$0100,$1000,$0080,$0400         ;..@...@.........
L00035C6C                       dc.w    $0008,$0080,$8004,$0000,$8004,$4004,$8004,$4004         ;..........@...@.
L00035C7C                       dc.w    $8008,$8004,$0004,$4000,$8004,$4004,$FFFC,$4004         ;......@...@...@.
L00035C8C                       dc.w    $0100,$1000,$0080,$0400,$0008,$0080,$8004,$0000         ;................
L00035C9C                       dc.w    $8004,$400C,$8004,$4004,$8008,$800C,$C004,$7F8C         ;..@...@.........
L00035CAC                       dc.w    $0004,$4004,$0000,$4000,$0100,$1000,$0080,$3C00         ;..@...@.......<.
L00035CBC                       dc.w    $0008,$0080,$8007,$C000,$8004,$401C,$8004,$400C         ;..........@...@.
L00035CCC                       dc.w    $8008,$801C,$A007,$FFF4,$C007,$C00C,$37FF,$C00C         ;............7...
L00035CDC                       dc.w    $0100,$1000,$0F81,$FFC0,$0008,$0080,$8007,$C000         ;................
L00035CEC                       dc.w    $BF84,$407C,$C004,$403C,$BF88,$807C,$5007,$FFE8         ;..@|..@<...|P...
L00035CFC                       dc.w    $A000,$003C,$5780,$0014,$01C0,$1000,$0807,$FFC0         ;...<W...........
L00035D0C                       dc.w    $0008,$0080,$803F,$C000,$FFE4,$41FC,$FC04,$41FC         ;.....?....A...A.
L00035D1C                       dc.w    $FFE8,$81FC,$503F,$FFE8,$5000,$01FC,$BFE0,$0028         ;....P?..P......(
L00035D2C                       dc.w    $01F0,$1000,$083F,$FFC0,$0008,$0380,$80FF,$C000         ;.....?..........
L00035D3C                       dc.w    $FFFC,$4FFC,$FF04,$7FFC,$FFF8,$8FFC,$A0FF,$FFF4         ;..O.............
L00035D4C                       dc.w    $37FF,$FFFC,$FFFF,$FFB0,$01FC,$1000,$0FFF,$FFC0         ;7...............
L00035D5C                       dc.w    $0008,$FF80,$9FFC,$0000,$FFFC,$7FFC,$FFC4,$7FFC         ;................
L00035D6C                       dc.w    $FFF8,$FFFC,$DFFC,$7FFC,$0000,$7FFC,$3FFC,$0000         ;............?...
L00035D7C                       dc.w    $01FF,$F000,$00FF,$FC00,$000F,$FF80,$FFFC,$7FFC         ;................
L00035D8C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFFA,$FFFC,$3FFC,$7FF0         ;............?...
L00035D9C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$01FF,$F000,$00FF,$FC00         ;................
L00035DAC                       dc.w    $000F,$FF80,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L00035DBC                       dc.w    $FFFF,$FFFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L00035DCC                       dc.w    $01FF,$F000,$00FF,$FC00,$000F,$FF80,$FFFC,$7FFC         ;................
L00035DDC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$FFF7,$7FFC,$FFFC,$7FFC         ;................
L00035DEC                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$01FF,$F000,$00FF,$FC00         ;................
L00035DFC                       dc.w    $000F,$FF80,$FFFC,$7FFC,$FFFC,$7FFC,$7FFC,$7FF8         ;................
L00035E0C                       dc.w    $FFFF,$FFFC,$FFFC,$7FFC,$FFFC,$7FFC,$FFFC,$7FFC         ;................
L00035E1C                       dc.w    $01FF,$F000,$00FF,$FC00,$000F,$FF80,$FFFC,$7FFC         ;................
L00035E2C                       dc.w    $FFFC,$7FFC,$3FFC,$7FF0,$FFFF,$FFFC,$FFFC,$7FFC         ;....?...........
L00035E3C                       dc.w    $FFFC,$7FFC,$FFFC,$7FFC,$01FF,$F000,$00FF,$FC00         ;................
L00035E4C                       dc.w    $000F,$FF80,$8004,$4004,$8004,$4004,$1804,$4060         ;......@...@...@`
L00035E5C                       dc.w    $8000,$0004,$8004,$4004,$8004,$4004,$8004,$4004         ;......@...@...@.
L00035E6C                       dc.w    $0100,$1000,$0080,$0400,$0008,$0080,$8004,$4004         ;..............@.
L00035E7C                       dc.w    $8004,$4004,$0C04,$40C0,$8000,$0004,$8004,$4004         ;..@...@.......@.
L00035E8C                       dc.w    $8004,$4004,$8004,$4004,$0100,$1000,$0080,$0400         ;..@...@.........
L00035E9C                       dc.w    $0008,$0080,$0004,$4000,$0004,$4000,$0604,$4180         ;......@...@...A.
L00035EAC                       dc.w    $0000,$0000,$8004,$4004,$0004,$4000,$8004,$4000         ;......@...@...@.
L00035EBC                       dc.w    $0000,$1000,$0080,$0400,$0008,$0000,$C007,$C00C         ;................
L00035ECC                       dc.w    $C007,$C00C,$0307,$C300,$C007,$000C,$8004,$4004         ;..............@.
L00035EDC                       dc.w    $C007,$C00C,$8007,$C00C,$0180,$1F00,$00FF,$FC00         ;................
L00035EEC                       dc.w    $00F8,$0180,$A000,$0014,$A000,$0014,$0180,$0600         ;................
L00035EFC                       dc.w    $A00A,$8014,$8004,$4004,$A000,$0014,$8000,$0014         ;......@.........
L00035F0C                       dc.w    $0140,$0100,$0000,$0000,$0080,$0280,$5FFF,$FFE8         ;.@.........._...
L00035F1C                       dc.w    $5FFF,$FFE8,$00FF,$FC00,$5FF5,$7FE8,$FFFC,$7FFC         ;_......._.......
L00035F2C                       dc.w    $5FFF,$FFE8,$FFFF,$FFE8,$00BF,$FF00,$0000,$0000         ;_...............
L00035F3C                       dc.w    $00FF,$FD00,$37FF,$FFB0,$37FF,$FFB0,$007F,$F800         ;....7...7.......
L00035F4C                       dc.w    $37D8,$DFB0,$FFFC,$7FFC,$37FF,$FFB0,$FFFF,$FFB0         ;7.......7.......
L00035F5C                       dc.w    $006F,$FF00,$0000,$0000,$00FF,$F600,$0000,$0000         ;.o..............
L00035F6C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00035F7C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00035F8C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00035F9C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00035FAC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000


menu_sprite_left        ; original address L00035FB8 ; 16x7 pixels
                                dc.w    $796C,$8001     ; control words (sprpos(y,x),sprctl)
                                dc.w    $3000,$0000     ; 0011000000000000,0000000000000000
                                dc.w    $3800,$0000     ; 0011100000000000,0000000000000000
                                dc.w    $FC00,$0000     ; 1111110000000000,0000000000000000
                                dc.w    $FE00,$0000     ; 1111111000000000,0000000000000000
                                dc.w    $FC00,$0000     ; 1111110000000000,0000000000000000
                                dc.w    $3800,$0000     ; 0011100000000000,0000000000000000
                                dc.w    $3000,$0000     ; 0011000000000000,0000000000000000
                                dc.w    $0000,$0000     ; end of sprite

menu_sprite_right       ; original address L00035FDC ; 16x7 pixels
                                dc.w    $79A9,$8001     ; control words (sprpos(y,x),sprctl)
                                dc.w    $1800,$0000     ; 0001100000000000,0000000000000000
                                dc.w    $3800,$0000     ; 0011100000000000,0000000000000000
                                dc.w    $7E00,$0000     ; 0111111000000000,0000000000000000
                                dc.w    $FE00,$0000     ; 1111111000000000,0000000000000000
                                dc.w    $7E00,$0000     ; 0111111000000000,0000000000000000
                                dc.w    $3800,$0000     ; 0011100000000000,0000000000000000
                                dc.w    $1800,$0000     ; 0001100000000000,0000000000000000
                                dc.w    $0000,$0000     ; end of sprite



                ; ---------------------- insert disk 1 message -------------------------
                ; bitplane display for 'insert disk 1' 
insert_disk_1_message   ; original address L00036000
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0000         ;................
                                dc.w    $0000,$01FA,$33EF,$DF3F,$00F9,$F9F6,$601E,$0000         ;....3..?....`...
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0063,$360C,$198C         ;...........c6...
                                dc.w    $00CC,$6306,$6006,$0000,$0000,$0000,$0000,$0000         ;..c.`...........
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
                                dc.w    $0000,$0063,$B60C,$198C,$00CC,$6306,$6006,$0000         ;...c......c.`...
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0063,$F3CF,$9F0C         ;...........c....
                                dc.w    $00CC,$61E7,$C006,$0000,$0000,$0000,$0000,$0000         ;..a.............
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
                                dc.w    $0000,$0063,$706C,$198C,$00CC,$6036,$6006,$0000         ;...cpl....`6`...
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0063,$306C,$198C         ;...........c0l..
                                dc.w    $00CC,$6036,$6006,$0000,$0000,$0000,$0000,$0000         ;..`6`...........
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
                                dc.w    $0000,$01FB,$17CF,$D98C,$00F9,$FBE6,$601F,$8000         ;............`...
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0000



                ; ---------------------- insert disk 2 message -------------------------
                ; bitplane display for 'insert disk 2' 
insert_disk_2_message   ; original address L00036118
                                dc.w    $0000,$0000 
                                dc.w    $0000,$0000,$0000,$0000,$0000,$01FA,$33EF,$DF3F 
                                dc.w    $00F9,$F9F6,$601F,$0000,$0000,$0000,$0000,$0000 
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 
                                dc.w    $0000,$0063,$360C,$198C,$00CC,$6306,$6001,$8000 
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0063,$B60C,$198C 
                                dc.w    $00CC,$6306,$6001,$8000,$0000,$0000,$0000,$0000 
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 
                                dc.w    $0000,$0063,$F3CF,$9F0C,$00CC,$61E7,$C00F,$0000 
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0063,$706C,$198C 
                                dc.w    $00CC,$6036,$6018,$0000,$0000,$0000,$0000,$0000 
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 
                                dc.w    $0000,$0063,$306C,$198C,$00CC,$6036,$6018,$0000 
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 
                                dc.w    $0000,$0000,$0000,$0000,$0000,$01FB,$17CF,$D98C 
                                dc.w    $00F9,$FBE6,$601F,$8000,$0000,$0000,$0000,$0000 
                                dc.w    $0000,$0000



                ; ---------------------- insert disk 3 message -------------------------
                ; bitplane display for 'insert disk 3' 
insert_disk_3_message   ; original address L00036230
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0000
                                dc.w    $0000,$01FA,$33EF,$DF3F,$00F9,$F9F6,$601F,$0000
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0063,$360C,$198C
                                dc.w    $00CC,$6306,$6001,$8000,$0000,$0000,$0000,$0000
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                                dc.w    $0000,$0063,$B60C,$198C,$00CC,$6306,$6001,$8000
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0063,$F3CF,$9F0C
                                dc.w    $00CC,$61E7,$C007,$0000,$0000,$0000,$0000,$0000
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                                dc.w    $0000,$0063,$706C,$198C,$00CC,$6036,$6001,$8000
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0063,$306C,$198C
                                dc.w    $00CC,$6036,$6001,$8000,$0000,$0000,$0000,$0000
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                                dc.w    $0000,$01FB,$17CF,$D98C,$00F9,$FBE6,$601F,$0000
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0000



                ; ----------------------- insert disk blank -----------------------
                ; this is an empty message to clear the display message for
                ; inserting the correct disk
insert_disk_blank_message       ; original address L00036348
                                dcb.b   40*7,$00



vector_logo_swap_flag   ; original address L000365C8
                                dc.w    $0000           ; value alternates between 0 and 1 - used by double buffer swap routine

vector_logo_buffer_ptr  ; original address L000365CA
                                dc.l    vector_logo_buffer_1                    ; $000365CE

                        ; 320 x 150 pixels buffer (1 bitplane)
vector_logo_buffer_1    ; original address L000365CE
                                dcb.b   40*146,$00

                        ; 320 x 150 pixels buffer (1 bitplane)
vector_logo_buffer_2    ; original address L00037D3E
                                dcb.b    40*146,$00


L000394AE                       dc.w    $0000,$0002,$0004,$0006,$0008,$000B,$000D               ;................
L000394BC                       dc.w    $000F,$0011,$0013,$0016,$0018,$001A,$001C,$001E         ;................
L000394CC                       dc.w    $0020,$0023,$0025,$0027,$0029,$002B,$002D,$002F         ;. .#.%.'.).+.-./
L000394DC                       dc.w    $0031,$0033,$0035,$0037,$0039,$003B,$003D,$003F         ;.1.3.5.7.9.;.=.?
L000394EC                       dc.w    $0041,$0043,$0045,$0047,$0049,$004A,$004C,$004E         ;.A.C.E.G.I.J.L.N
L000394FC                       dc.w    $0050,$0051,$0053,$0055,$0056,$0058,$005A,$005B         ;.P.Q.S.U.V.X.Z.[
L0003950C                       dc.w    $005D,$005E,$0060,$0061,$0063,$0064,$0065,$0067         ;.].^.`.a.c.d.e.g
L0003951C                       dc.w    $0068,$0069,$006A,$006C,$006D,$006E,$006F,$0070         ;.h.i.j.l.m.n.o.p
L0003952C                       dc.w    $0071,$0072,$0073,$0074,$0075,$0076,$0077,$0077         ;.q.r.s.t.u.v.w.w
L0003953C                       dc.w    $0078,$0079,$0079,$007A,$007B,$007B,$007C,$007C         ;.x.y.y.z.{.{.|.|
L0003954C                       dc.w    $007D,$007D,$007D,$007E,$007E,$007E,$007F,$007F         ;.}.}.}.~.~.~....
L0003955C                       dc.w    $007F,$007F,$007F,$007F,$007F,$007F,$007F,$007F         ;................
L0003956C                       dc.w    $007F,$007E,$007E,$007E,$007D,$007D,$007D,$007C         ;...~.~.~.}.}.}.|
L0003957C                       dc.w    $007C,$007B,$007B,$007A,$0079,$0079,$0078,$0077         ;.|.{.{.z.y.y.x.w
L0003958C                       dc.w    $0077,$0076,$0075,$0074,$0073,$0072,$0071,$0070         ;.w.v.u.t.s.r.q.p
L0003959C                       dc.w    $006F,$006E,$006D,$006C,$006A,$0069,$0068,$0067         ;.o.n.m.l.j.i.h.g
L000395AC                       dc.w    $0065,$0064,$0063,$0061,$0060,$005E,$005D,$005B         ;.e.d.c.a.`.^.].[
L000395BC                       dc.w    $005A,$0058,$0056,$0055,$0053,$0051,$0050,$004E         ;.Z.X.V.U.S.Q.P.N
L000395CC                       dc.w    $004C,$004A,$0049,$0047,$0045,$0043,$0041,$003F         ;.L.J.I.G.E.C.A.?
L000395DC                       dc.w    $003D,$003B,$0039,$0037,$0035,$0033,$0031,$002F         ;.=.;.9.7.5.3.1./
L000395EC                       dc.w    $002D,$002B,$0029,$0027,$0025,$0023,$0020,$001E         ;.-.+.).'.%.#. ..
L000395FC                       dc.w    $001C,$001A,$0018,$0016,$0013,$0011,$000F,$000D         ;................
L0003960C                       dc.w    $000B,$0008,$0006,$0004,$0002,$0000,$FFFD,$FFFB         ;................
L0003961C                       dc.w    $FFF9,$FFF7,$FFF4,$FFF2,$FFF0,$FFEE,$FFEC,$FFE9         ;................
L0003962C                       dc.w    $FFE7,$FFE5,$FFE3,$FFE1,$FFDF,$FFDC,$FFDA,$FFD8         ;................
L0003963C                       dc.w    $FFD6,$FFD4,$FFD2,$FFD0,$FFCE,$FFCC,$FFCA,$FFC8         ;................
L0003964C                       dc.w    $FFC6,$FFC4,$FFC2,$FFC0,$FFBE,$FFBC,$FFBA,$FFB8         ;................
L0003965C                       dc.w    $FFB6,$FFB5,$FFB3,$FFB1,$FFAF,$FFAE,$FFAC,$FFAA         ;................
L0003966C                       dc.w    $FFA9,$FFA7,$FFA5,$FFA4,$FFA2,$FFA1,$FF9F,$FF9E         ;................
L0003967C                       dc.w    $FF9C,$FF9B,$FF9A,$FF98,$FF97,$FF96,$FF95,$FF93         ;................
L0003968C                       dc.w    $FF92,$FF91,$FF90,$FF8F,$FF8E,$FF8D,$FF8C,$FF8B         ;................
L0003969C                       dc.w    $FF8A,$FF89,$FF88,$FF88,$FF87,$FF86,$FF86,$FF85         ;................
L000396AC                       dc.w    $FF84,$FF84,$FF83,$FF83,$FF82,$FF82,$FF82,$FF81         ;................
L000396BC                       dc.w    $FF81,$FF81,$FF80,$FF80,$FF80,$FF80,$FF80,$FF80         ;................
L000396CC                       dc.w    $FF80,$FF80,$FF80,$FF80,$FF80,$FF81,$FF81,$FF81         ;................
L000396DC                       dc.w    $FF82,$FF82,$FF82,$FF83,$FF83,$FF84,$FF84,$FF85         ;................
L000396EC                       dc.w    $FF86,$FF86,$FF87,$FF88,$FF88,$FF89,$FF8A,$FF8B         ;................
L000396FC                       dc.w    $FF8C,$FF8D,$FF8E,$FF8F,$FF90,$FF91,$FF92,$FF93         ;................
L0003970C                       dc.w    $FF95,$FF96,$FF97,$FF98,$FF9A,$FF9B,$FF9C,$FF9E         ;................
L0003971C                       dc.w    $FF9F,$FFA1,$FFA2,$FFA4,$FFA5,$FFA7,$FFA9,$FFAA         ;................
L0003972C                       dc.w    $FFAC,$FFAE,$FFAF,$FFB1,$FFB3,$FFB5,$FFB6,$FFB8         ;................
L0003973C                       dc.w    $FFBA,$FFBC,$FFBE,$FFC0,$FFC2,$FFC4,$FFC6,$FFC8         ;................
L0003974C                       dc.w    $FFCA,$FFCC,$FFCE,$FFD0,$FFD2,$FFD4,$FFD6,$FFD8         ;................
L0003975C                       dc.w    $FFDA,$FFDC,$FFDF,$FFE1,$FFE3,$FFE5,$FFE7,$FFE9         ;................
L0003976C                       dc.w    $FFEC,$FFEE,$FFF0,$FFF2,$FFF4,$FFF7,$FFF9,$FFFB         ;................
L0003977C                       dc.w    $FFFD

L0003977E                       dc.w    $007F,$007F,$007F,$007F,$007F,$007F,$007E               ;...............~
L0003978C                       dc.w    $007E,$007E,$007D,$007D,$007D,$007C,$007C,$007B         ;.~.~.}.}.}.|.|.{
L0003979C                       dc.w    $007B,$007A,$0079,$0079,$0078,$0077,$0077,$0076         ;.{.z.y.y.x.w.w.v
L000397AC                       dc.w    $0075,$0074,$0073,$0072,$0071,$0070,$006F,$006E         ;.u.t.s.r.q.p.o.n
L000397BC                       dc.w    $006D,$006C,$006A,$0069,$0068,$0067,$0065,$0064         ;.m.l.j.i.h.g.e.d
L000397CC                       dc.w    $0063,$0061,$0060,$005E,$005D,$005B,$005A,$0058         ;.c.a.`.^.].[.Z.X
L000397DC                       dc.w    $0056,$0055,$0053,$0051,$0050,$004E,$004C,$004A         ;.V.U.S.Q.P.N.L.J
L000397EC                       dc.w    $0049,$0047,$0045,$0043,$0041,$003F,$003D,$003B         ;.I.G.E.C.A.?.=.;
L000397FC                       dc.w    $0039,$0037,$0035,$0033,$0031,$002F,$002D,$002B         ;.9.7.5.3.1./.-.+
L0003980C                       dc.w    $0029,$0027,$0025,$0023,$0020,$001E,$001C,$001A         ;.).'.%.#. ......
L0003981C                       dc.w    $0018,$0016,$0013,$0011,$000F,$000D,$000B,$0008         ;................
L0003982C                       dc.w    $0006,$0004,$0002,$0000,$FFFD,$FFFB,$FFF9,$FFF7         ;................
L0003983C                       dc.w    $FFF4,$FFF2,$FFF0,$FFEE,$FFEC,$FFE9,$FFE7,$FFE5         ;................
L0003984C                       dc.w    $FFE3,$FFE1,$FFDF,$FFDC,$FFDA,$FFD8,$FFD6,$FFD4         ;................
L0003985C                       dc.w    $FFD2,$FFD0,$FFCE,$FFCC,$FFCA,$FFC8,$FFC6,$FFC4         ;................
L0003986C                       dc.w    $FFC2,$FFC0,$FFBE,$FFBC,$FFBA,$FFB8,$FFB6,$FFB5         ;................
L0003987C                       dc.w    $FFB3,$FFB1,$FFAF,$FFAE,$FFAC,$FFAA,$FFA9,$FFA7         ;................
L0003988C                       dc.w    $FFA5,$FFA4,$FFA2,$FFA1,$FF9F,$FF9E,$FF9C,$FF9B         ;................
L0003989C                       dc.w    $FF9A,$FF98,$FF97,$FF96,$FF95,$FF93,$FF92,$FF91         ;................
L000398AC                       dc.w    $FF90,$FF8F,$FF8E,$FF8D,$FF8C,$FF8B,$FF8A,$FF89         ;................
L000398BC                       dc.w    $FF88,$FF88,$FF87,$FF86,$FF86,$FF85,$FF84,$FF84         ;................
L000398CC                       dc.w    $FF83,$FF83,$FF82,$FF82,$FF82,$FF81,$FF81,$FF81         ;................
L000398DC                       dc.w    $FF80,$FF80,$FF80,$FF80,$FF80,$FF80,$FF80,$FF80         ;................
L000398EC                       dc.w    $FF80,$FF80,$FF80,$FF81,$FF81,$FF81,$FF82,$FF82         ;................
L000398FC                       dc.w    $FF82,$FF83,$FF83,$FF84,$FF84,$FF85,$FF86,$FF86         ;................
L0003990C                       dc.w    $FF87,$FF88,$FF88,$FF89,$FF8A,$FF8B,$FF8C,$FF8D         ;................
L0003991C                       dc.w    $FF8E,$FF8F,$FF90,$FF91,$FF92,$FF93,$FF95,$FF96         ;................
L0003992C                       dc.w    $FF97,$FF98,$FF9A,$FF9B,$FF9C,$FF9E,$FF9F,$FFA1         ;................
L0003993C                       dc.w    $FFA2,$FFA4,$FFA5,$FFA7,$FFA9,$FFAA,$FFAC,$FFAE         ;................
L0003994C                       dc.w    $FFAF,$FFB1,$FFB3,$FFB5,$FFB6,$FFB8,$FFBA,$FFBC         ;................
L0003995C                       dc.w    $FFBE,$FFC0,$FFC2,$FFC4,$FFC6,$FFC8,$FFCA,$FFCC         ;................
L0003996C                       dc.w    $FFCE,$FFD0,$FFD2,$FFD4,$FFD6,$FFD8,$FFDA,$FFDC         ;................
L0003997C                       dc.w    $FFDF,$FFE1,$FFE3,$FFE5,$FFE7,$FFE9,$FFEC,$FFEE         ;................
L0003998C                       dc.w    $FFF0,$FFF2,$FFF4,$FFF7,$FFF9,$FFFB,$FFFD,$0000         ;................
L0003999C                       dc.w    $0002,$0004,$0006,$0008,$000B,$000D,$000F,$0011         ;................
L000399AC                       dc.w    $0013,$0016,$0018,$001A,$001C,$001E,$0020,$0023         ;............. .#
L000399BC                       dc.w    $0025,$0027,$0029,$002B,$002D,$002F,$0031,$0033         ;.%.'.).+.-./.1.3
L000399CC                       dc.w    $0035,$0037,$0039,$003B,$003D,$003F,$0041,$0043         ;.5.7.9.;.=.?.A.C
L000399DC                       dc.w    $0045,$0047,$0049,$004A,$004C,$004E,$0050,$0051         ;.E.G.I.J.L.N.P.Q
L000399EC                       dc.w    $0053,$0055,$0056,$0058,$005A,$005B,$005D,$005E         ;.S.U.V.X.Z.[.].^
L000399FC                       dc.w    $0060,$0061,$0063,$0064,$0065,$0067,$0068,$0069         ;.`.a.c.d.e.g.h.i
L00039A0C                       dc.w    $006A,$006C,$006D,$006E,$006F,$0070,$0071,$0072         ;.j.l.m.n.o.p.q.r
L00039A1C                       dc.w    $0073,$0074,$0075,$0076,$0077,$0077,$0078,$0079         ;.s.t.u.v.w.w.x.y
L00039A2C                       dc.w    $0079,$007A,$007B,$007B,$007C,$007C,$007D,$007D         ;.y.z.{.{.|.|.}.}
L00039A3C                       dc.w    $007D,$007E,$007E,$007E,$007F,$007F,$007F,$007F         ;.}.~.~.~........
L00039A4C                       dc.w    $007F

L00039A4E                       dc.w    $00FF,$00FF,$00FF,$00FF,$00FF,$00FF,$00EE         ;................
L00039A5C                       dc.w    $00EE,$00EE,$00EE,$00EE,$00EE,$00DD,$00DD,$00DD         ;................
L00039A6C                       dc.w    $00DD,$00DD,$00DD,$00CC,$00CC,$00CC,$00CC,$00CC         ;................
L00039A7C                       dc.w    $00CC,$00BB,$00BB,$00BB,$00BB,$00BB,$00BB,$00AA         ;................
L00039A8C                       dc.w    $00AA,$00AA,$00AA,$00AA,$00AA,$0099,$0099,$0099         ;................
L00039A9C                       dc.w    $0099,$0099,$0099,$0088,$0088,$0088,$0088,$0088         ;................
L00039AAC                       dc.w    $0088,$0077,$0077,$0077,$0077,$0077,$0077,$0066         ;...w.w.w.w.w.w.f
L00039ABC                       dc.w    $0066,$0066,$0066,$0066,$0066,$0055,$0055,$0055         ;.f.f.f.f.f.U.U.U
L00039ACC                       dc.w    $0055,$0055,$0055,$0044,$0044,$0044,$0044,$0044         ;.U.U.U.D.D.D.D.D
L00039ADC                       dc.w    $0044,$0033,$0033,$0033,$0033,$0033,$0033,$0022         ;.D.3.3.3.3.3.3."
L00039AEC                       dc.w    $0022,$0022,$0022,$0022,$0022,$0011,$0011,$0011         ;."."."."."......
L00039AFC                       dc.w    $0011,$0000,$0000,$0000,$0000,$0100,$0100,$0100         ;................
L00039B0C                       dc.w    $0100,$0200,$0200,$0200,$0200,$0200,$0200,$0300         ;................
L00039B1C                       dc.w    $0300,$0300,$0300,$0300,$0300,$0400,$0400,$0400         ;................
L00039B2C                       dc.w    $0400,$0400,$0400,$0500,$0500,$0500,$0500,$0500         ;................
L00039B3C                       dc.w    $0500,$0600,$0600,$0600,$0600,$0600,$0600,$0700         ;................
L00039B4C                       dc.w    $0700,$0700,$0700,$0700,$0700,$0800,$0800,$0800         ;................
L00039B5C                       dc.w    $0800,$0800,$0800,$0900,$0900,$0900,$0900,$0900         ;................
L00039B6C                       dc.w    $0900,$0A00,$0A00,$0A00,$0A00,$0A00,$0A00,$0B00         ;................
L00039B7C                       dc.w    $0B00,$0B00,$0B00,$0B00,$0B00,$0C00,$0C00,$0C00         ;................
L00039B8C                       dc.w    $0C00,$0C00,$0C00,$0D00,$0D00,$0D00,$0D00,$0D00         ;................
L00039B9C                       dc.w    $0D00,$0E00,$0E00,$0E00,$0E00,$0E00,$0E00,$0F00         ;................
L00039BAC                       dc.w    $0F00,$0F00,$0F00,$0F00,$0F00,$0F00,$0F00,$0F00         ;................
L00039BBC                       dc.w    $0F00,$0F00,$0F00,$0E00,$0E00,$0E00,$0E00,$0E00         ;................
L00039BCC                       dc.w    $0E00,$0D00,$0D00,$0D00,$0D00,$0D00,$0D00,$0C00         ;................
L00039BDC                       dc.w    $0C00,$0C00,$0C00,$0C00,$0C00,$0B00,$0B00,$0B00         ;................
L00039BEC                       dc.w    $0B00,$0B00,$0B00,$0A00,$0A00,$0A00,$0A00,$0A00         ;................
L00039BFC                       dc.w    $0A00,$0900,$0900,$0900,$0900,$0900,$0900,$0800         ;................
L00039C0C                       dc.w    $0800,$0800,$0800,$0800,$0800,$0700,$0700,$0700         ;................
L00039C1C                       dc.w    $0700,$0700,$0700,$0600,$0600,$0600,$0600,$0600         ;................
L00039C2C                       dc.w    $0600,$0500,$0500,$0500,$0500,$0500,$0500,$0400         ;................
L00039C3C                       dc.w    $0400,$0400,$0400,$0400,$0400,$0300,$0300,$0300         ;................
L00039C4C                       dc.w    $0300,$0300,$0300,$0200,$0200,$0200,$0200,$0200         ;................
L00039C5C                       dc.w    $0200,$0000,$0000,$0100,$0100,$0100,$0100,$0000         ;................
L00039C6C                       dc.w    $0000,$0011,$0011,$0011,$0011,$0022,$0022,$0022         ;..........."."."
L00039C7C                       dc.w    $0022,$0022,$0022,$0033,$0033,$0033,$0033,$0033         ;.".".".3.3.3.3.3
L00039C8C                       dc.w    $0033,$0044,$0044,$0044,$0044,$0044,$0044,$0055         ;.3.D.D.D.D.D.D.U
L00039C9C                       dc.w    $0055,$0055,$0055,$0055,$0055,$0066,$0066,$0066         ;.U.U.U.U.U.f.f.f
L00039CAC                       dc.w    $0066,$0066,$0066,$0077,$0077,$0077,$0077,$0077         ;.f.f.f.w.w.w.w.w
L00039CBC                       dc.w    $0077,$0088,$0088,$0088,$0088,$0088,$0088,$0099         ;.w..............
L00039CCC                       dc.w    $0099,$0099,$0099,$0099,$0099,$00AA,$00AA,$00AA         ;................
L00039CDC                       dc.w    $00AA,$00AA,$00AA,$00BB,$00BB,$00BB,$00BB,$00BB         ;................
L00039CEC                       dc.w    $00BB,$00CC,$00CC,$00CC,$00CC,$00CC,$00CC,$00DD         ;................
L00039CFC                       dc.w    $00DD,$00DD,$00DD,$00DD,$00DD,$00EE,$00EE,$00EE         ;................
L00039D0C                       dc.w    $00EE,$00EE,$00EE,$00FF,$00FF,$00FF,$00FF,$00FF         ;................
L00039D1C                       dc.w    $00FF
L00039D1E                       dc.w    $0044

L00039D20                       dc.w    $FE0C,$0032,$0000,$FE0C,$FFF6,$0000
L00039D2C                       dc.w    $FE98,$FFB0,$0000,$FEC0,$FFC4,$0000,$FE48,$0001         ;.............H..
L00039D3C                       dc.w    $0000,$FE48,$000A,$0000,$FEC0,$000A,$0000,$FEC0         ;...H............
L00039D4C                       dc.w    $0032,$0000,$FEF2,$0032,$0000,$FECA,$001E,$0000         ;.2.....2........
L00039D5C                       dc.w    $FECA,$FFF6,$0000,$FEF2,$FFF6,$0000,$FEF2,$001E         ;................
L00039D6C                       dc.w    $0000,$FF1A,$001E,$0000,$FF1A,$FFF6,$0000,$FF42         ;...............B
L00039D7C                       dc.w    $FFF6,$0000,$FF42,$0032,$0000,$FF4C,$0032,$0000         ;.....B.2...L.2..
L00039D8C                       dc.w    $FF4C,$FFF6,$0000,$FF9C,$FFF6,$0000,$FFC4,$000A         ;.L..............
L00039D9C                       dc.w    $0000,$FFC4,$0032,$0000,$FF9C,$0032,$0000,$FF9C         ;.....2.....2....
L00039DAC                       dc.w    $000A,$0000,$FF74,$000A,$0000,$FF74,$0032,$0000         ;.....t.....t.2..
L00039DBC                       dc.w    $FFCE,$001E,$0000,$FFCE,$000A,$0000,$FFF6,$FFF6         ;................
L00039DCC                       dc.w    $0000,$0032,$FFF6,$0000,$0032,$0032,$0000,$FFF6         ;...2.....2.2....
L00039DDC                       dc.w    $0032,$0000,$FFF6,$001E,$0000,$0014,$001E,$0000         ;.2..............
L00039DEC                       dc.w    $0014,$000A,$0000,$FFF6,$000A,$0000,$003C,$FFF6         ;.............<..
L00039DFC                       dc.w    $0000,$0096,$FFF6,$0000,$0096,$0032,$0000,$006E         ;...........2...n
L00039E0C                       dc.w    $0032,$0000,$006E,$000A,$0000,$003C,$000A,$0000         ;.2...n.....<....
L00039E1C                       dc.w    $00A0,$FFF6,$0000,$00C8,$FFF6,$0000,$00C8,$0032         ;...............2
L00039E2C                       dc.w    $0000,$00A0,$0032,$0000,$00D2,$0032,$0000,$0136         ;.....2.....2...6
L00039E3C                       dc.w    $0032,$0000,$0136,$001E,$0000,$00FA,$001E,$0000         ;.2...6..........
L00039E4C                       dc.w    $00FA,$000A,$0000,$0136,$000A,$0000,$0136,$FFF6         ;.......6.....6..
L00039E5C                       dc.w    $0000,$00FA,$FFF6,$0000,$00D2,$000A,$0000,$0140         ;...............@
L00039E6C                       dc.w    $0032,$0000,$0186,$0032,$0000,$01AE,$001E,$0000         ;.2.....2........
L00039E7C                       dc.w    $01AE,$000F,$0000,$0168,$000F,$0000,$0168,$000A         ;.......h.....h..
L00039E8C                       dc.w    $0000,$01AE,$000A,$0000,$01AE,$FFF6,$0000,$0168         ;...............h
L00039E9C                       dc.w    $FFF6,$0000,$0140,$000A,$0000,$0140,$0019,$0000         ;.....@.....@....
L00039EAC                       dc.w    $0186,$0019,$0000,$0186,$001E,$0000,$0140,$001E         ;.............@..
L00039EBC                       dc.w    $0000

L00039EBE                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00039ECC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00039EDC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00039EEC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00039EFC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00039F0C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00039F1C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00039F2C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00039F3C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00039F4C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00039F5C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00039F6C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00039F7C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00039F8C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00039F9C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00039FAC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00039FBC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00039FCC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00039FDC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00039FEC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L00039FFC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A00C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A01C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A02C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A03C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A04C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A05C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A06C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A07C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A08C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A09C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A0AC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A0BC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A0CC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A0DC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A0EC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A0FC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A10C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A11C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A12C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A13C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A14C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A15C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A16C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A17C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A18C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A19C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A1AC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A1BC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A1CC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A1DC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A1EC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A1FC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A20C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A21C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A22C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A23C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A24C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A25C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A26C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A27C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A28C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A29C                       dc.w    $0000,$0000,$0000,$0000,$0000

L0003A2A6                       dc.w    $0000,$0000,$0000
L0003A2AC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A2BC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A2CC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A2DC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A2EC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A2FC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A30C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A31C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A32C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A33C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A34C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A35C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A36C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A37C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A38C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A39C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A3AC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A3BC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A3CC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A3DC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A3EC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A3FC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A40C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A41C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A42C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A43C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A44C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A45C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A46C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A47C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A48C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A49C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A4AC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A4BC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A4CC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A4DC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A4EC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A4FC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A50C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A51C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A52C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A53C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A54C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A55C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A56C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A57C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A58C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A59C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A5AC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A5BC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A5CC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A5DC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A5EC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A5FC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A60C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A61C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A62C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A63C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A64C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A65C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A66C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A67C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000         ;................
L0003A68C                       dc.w    $0000

L0003A68E                       dc.w    $0044

L0003A690                       dc.w    $0000,$0004,$0004,$0008,$0008,$000C                     ;...D............
L0003A69C                       dc.w    $000C,$0010,$0010,$0014,$0014,$0018,$0018,$001C         ;................
L0003A6AC                       dc.w    $001C,$0000,$0020,$0024,$0024,$0028,$0028,$002C         ;..... .$.$.(.(.,
L0003A6BC                       dc.w    $002C,$0030,$0030,$0034,$0034,$0038,$0038,$003C         ;.,.0.0.4.4.8.8.<
L0003A6CC                       dc.w    $003C,$0040,$0040,$0020,$0044,$0048,$0048,$004C         ;.<.@.@. .D.H.H.L
L0003A6DC                       dc.w    $004C,$0050,$0050,$0054,$0054,$0058,$0058,$005C         ;.L.P.P.T.T.X.X.\
L0003A6EC                       dc.w    $005C,$0060,$0060,$0064,$0064,$0044,$0068,$006C         ;.\.`.`.d.d.D.h.l
L0003A6FC                       dc.w    $006C,$0070,$0070,$0074,$0074,$0078,$0078,$007C         ;.l.p.p.t.t.x.x.|
L0003A70C                       dc.w    $007C,$0068,$0080,$0084,$0084,$0088,$0088,$008C         ;.|.h............
L0003A71C                       dc.w    $008C,$0080,$0090,$0094,$0094,$0098,$0098,$009C         ;................
L0003A72C                       dc.w    $009C,$00A0,$00A0,$00A4,$00A4,$0090,$00A8,$00AC         ;................
L0003A73C                       dc.w    $00AC,$00B0,$00B0,$00B4,$00B4,$00A8,$00B8,$00BC         ;................
L0003A74C                       dc.w    $00BC,$00C0,$00C0,$00C4,$00C4,$00C8,$00C8,$00CC         ;................
L0003A75C                       dc.w    $00CC,$00D0,$00D0,$00D4,$00D4,$00D8,$00D8,$00B8         ;................
L0003A76C                       dc.w    $00DC,$00E0,$00E0,$00E4,$00E4,$00E8,$00E8,$00EC         ;................
L0003A77C                       dc.w    $00EC,$00F0,$00F0,$00F4,$00F4,$00F8,$00F8,$00FC         ;................
L0003A78C                       dc.w    $00FC,$0100,$0100,$0104,$0104,$0108,$0108,$010C         ;................
L0003A79C                       dc.w    $010C,$0110,$0110,$00DC,$0000,$0000,$0000,$0000         ;................

                ; ------------------------ menu screen pointer list ---------------------
                ; a list of memory pointers to the text for each menu in the music disk
menu_ptrs       ; original address L0003A7AC
                                dc.l    main_menu               ; L0003A7E4 - index = $00
                                dc.l    disk_1_menu             ; L0003AAE1 - index = $04
                                dc.l    disk_2_menu             ; L0003AE0B - index = $08
                                dc.l    disk_3_menu             ; L0003B108 - index = $0c
                                dc.l    credits_menu            ; L0003B405 - index = $10
                                dc.l    greetings_1_menu        ; L0003B702 - index = $14
                                dc.l    greetings_2_menu        ; L0003B9FF - index = $18
                                dc.l    addresses_1_menu        ; L0003BCFC - index = $1c
                                dc.l    addresses_2_menu        ; L0003BFF9 - index = $20
                                dc.l    addresses_3_menu        ; L0003C2F6 - index = $24
                                dc.l    addresses_4_menu        ; L0003C5F3 - index = $28
                                dc.l    addresses_5_menu        ; L0003C8F0 - index = $2c
                                dc.l    addresses_6_menu        ; L0003CBED - index = $30
                                dc.l    pd_message_menu         ; L0003CEEA - index = $34

                                ; menu format = 45 x 17
main_menu       ; original address L0003A7E4
                                ;        123456789012345678901234567890123456789012345
                                dc.b    '    THE LUNATICS PRESENT INFINITE DREAMS     '
                                dc.b    '    ------------------------------------     '
                                dc.b    '                                             '   
                                dc.b    '                                             '
                                dc.b    '                                             '               
                                dc.b    '              DISK1.......MENU               '           
                                dc.b    '              DISK2.......MENU               '
                                dc.b    '              DISK3.......MENU               '
                                dc.b    '              ....CREDITS.....               '
                                dc.b    '              ...GREETINGS....               '
                                dc.b    '              ...ADDRESSES....               '
                                dc.b    '              ..P.D. MESSAGE..               '             
                                dc.b    '                                             '
                                dc.b    '      USE MOUSE TO SELECT TUNE TO PLAY       '
                                dc.b    '                                             '
                                dc.b    '                               *1992 LUNATICS'   
                                dc.b    '                                             '

disk_1_menu      ; original address L0003AAE1
                                ;        123456789012345678901234567890123456789012345
                                dc.b    '              -----------------              '
                                dc.b    '              -INFINITE DREAMS-              '
                                dc.b    '              -----------------              '              
                                dc.b    '                                             '
                                dc.b    '                 DISK 1 MENU                 '
                                dc.b    '                 -----------                 '               
                                dc.b    '                                             '
                                dc.b    '  JARRESQUE.......................HOLLYWOOD  '              
                                dc.b    '  THE.FLY........................SUBCULTURE  '
                                dc.b    '  STRATOSPHERIC.CITY.............SUBCULTURE  '
                                dc.b    '  FLOAT..........................SUBCULTURE  ' 
                                dc.b    '  FLIGHT-SLEEPY MIX..............SUBCULTURE  '
                                dc.b    '  ...........RETURN TO MAIN MENU..........   ' 
                                dc.b    '                                             '
                                dc.b    '                                             '
                                dc.b    '                                             '
                                dc.b    '                                             '

disk_2_menu         
                                 ;        123456789012345678901234567890123456789012345
                                dc.b    '              -----------------              '
                                dc.b    '              -INFINITE DREAMS-              '
                                dc.b    '              -----------------              '              
                                dc.b    '                 DISK 2 MENU                 '
                                dc.b    '                 -----------                 '               
                                dc.b    '                                             '
                                dc.b    '  SHAFT..........................SUBCULTURE  '              
                                dc.b    '  LOVE.YOUR.MONEY................SUBCULTURE  '
                                dc.b    '  COSMIC.HOW.MUCH................SUBCULTURE  '
                                dc.b    '  THIS IS NOT A RAVE SONG........SUBCULTURE  ' 
                                dc.b    '  EAT THE BALLBEARING............SUBCULTURE  '
                                dc.b    '  SOUND OF SILENCE................HOLLYWOOD  '
                                dc.b    '  RETOUCHE........................HOLLYWOOD  ' 
                                dc.b    '  TECHWAR.........................HOLLYWOOD  '
                                dc.b    '  BRIGHT..........................HOLLYWOOD  '
                                dc.b    '  ...........RETURN TO MAIN MENU..........   ' 
                                dc.b    '                                             '

disk_3_menu         
                                 ;        123456789012345678901234567890123456789012345
                                dc.b    '              -----------------              '
                                dc.b    '              -INFINITE DREAMS-              '
                                dc.b    '              -----------------              '              
                                dc.b    '                 DISK 3 MENU                 '
                                dc.b    '                 -----------                 '               
                                dc.b    '                                             '
                                dc.b    '  MENTAL OBSTACLE.....................REEAL  '              
                                dc.b    '  BLADE RUNNER........................REEAL  '
                                dc.b    '  NATURAL REALITY.................HOLLYWOOD  '
                                dc.b    '  OBLITERATION FIN................HOLLYWOOD  ' 
                                dc.b    '  SKYRIDERS.......................HOLLYWOOD  '
                                dc.b    '  ZERO GRAVITY....................HOLLYWOOD  '
                                dc.b    '  BREAK THROUGH...................HOLLYWOOD  ' 
                                dc.b    '  SUMMER IN SWEDEN...................PHASER  '
                                dc.b    '  NEVER TO MUCH.....................PHASER   '
                                dc.b    '  ...........RETURN TO MAIN MENU..........   ' 
                                dc.b    '                                             '
                              
credits_menu    ; original address L0003B405
                                ;        123456789012345678901234567890123456789012345
                                dc.b    '                                             '  
                                dc.b    '               ...CREDITS...                 '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '       ALL CODING.........SPONGE HEAD        '  
                                dc.b    '       GFX........................JOE        '  
                                dc.b    '                                T.S.M        '  
                                dc.b    '       MUSIC................HOLLYWOOD        '  
                                dc.b    '                           SUBCULTURE        '  
                                dc.b    '                               PHASER        '  
                                dc.b    '                                REEAL        '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '  ...........RETURN TO MAIN MENU...........  '  
                                dc.b    '                                             '  
                                   
greetings_1_menu       ; original address L0003B702
                                 ;        123456789012345678901234567890123456789012345
                                dc.b    '   ADDONIC-AGILE-AGNOSTIC FRONT AND PANIC    '  
                                dc.b    '   ALCATRAZ-ALCHEMY-ALLIANCE-ALPHA FLIGHT    '  
                                dc.b    '    AMAZE-ANAL INTRUDERS-ANARCHY-ANTHROX     '  
                                dc.b    '   APOCALYPSE-ARCHAOS-ASSSASSINS-ATLANTIS    '  
                                dc.b    '   AURORA-AWAKE-BLACK ROBES-BRUTAL-CHROME    '  
                                dc.b    '  COLLISION-COMPLEX-CRASHEAD-CRYSTAL-CYTAX   '  
                                dc.b    '   DAMAGE INC-DAMONES-DECAY-DESIRE-DEVILS    '  
                                dc.b    '   DIMENSION X-DISKNET-DUAL CREW-DYNAMIK     '  
                                dc.b    '     ECLIPSE-END OF CENTURY 1999-ENERGY      '  
                                dc.b    '   EQUINOX-FAIRLIGHT-FRANTIC-FUSION-GHOST    '  
                                dc.b    '   GRACE-GUARDIAN ANGEL-HARDLINE-HYSTERIA    '  
                                dc.b    '    INFINITY-ITALIAN BAD BOYS-JESTERS        '  
                                dc.b    '     KEFRENS-LA ROCCA-LEGEND-LIVE ACT        '  
                                dc.b    '   LOGIC SYSTEMS-LSD-LYNX-MAGIC 12-MIRAGE    '  
                                dc.b    '  ..............MORE GREETZ................  '  
                                dc.b    '  ...........RETURN TO MAIN MENU...........  '  
                                dc.b    '                                             '       

greetings_2_menu       ; original address L0003B9FF
                                 ;        123456789012345678901234567890123456789012345
                                ;        123456789012345678901234567890123456789012345
                                dc.b    '   NEMISIS-NOXIOUS-ORIGIN-PALACE-PARADISE    '  
                                dc.b    '   PARAGON-PHANTASM-PHANTASY-PHASE-PLASMA    '  
                                dc.b    '  POLARIS-PURE METAL CODERS-QUARTEX-QUARTZ   '  
                                dc.b    '     RAM JAM-RAF-RAZOR-REALLITY-REBELS       '  
                                dc.b    '       REDNEX-RELAY-RICH-RIP MASTERS         '  
                                dc.b    '   RUBBER RADISH-SCANDAL-SCOOPEX-SHINING     '  
                                dc.b    '   SHINING 8-SILENTS-SILICON LTD-SKID ROW    '  
                                dc.b    '      SLIPSTREAM-SONIC-SPREADPOINT-STAX      '  
                                dc.b    '   SUPPLEX-SUPRISE PRODUCTIONS-TALENT-TECH   '  
                                dc.b    '    TRASH-TRIBE-TRISTAR AND RED SECTOR INC   '  
                                dc.b    '    THE FLAME ARROWS-THE SPECIAL BROTHERS    '  
                                dc.b    '         VERMIN-VISION-VISION FACTORY        '  
                                dc.b    '            VISUAL BYTES-VOX DEI             '  
                                dc.b    '       WIZZCAT-XENTEX-ZITE PRODUCTIONS       '  
                                dc.b    '                                             '  
                                dc.b    '  ...........RETURN TO MAIN MENU...........  '  
                                dc.b    '                                             ' 

addresses_1_menu        ; original address L0003BCFC
                                ;        123456789012345678901234567890123456789012345
                                dc.b    '   THE LUNATICS ARE LOOKING FOR SOME MORE    '  
                                dc.b    '   MEMBERS AND COOOL DIVISIONS AROUND THE    '  
                                dc.b    '  WORLD. TO SET UP A DIVISION WRITE TO THE   '  
                                dc.b    '           FOLLOWING ADDRESS.....            '  
                                dc.b    '                                             '  
                                dc.b    '               T.S.M                         '  
                                dc.b    '               ** ******* ****               '  
                                dc.b    '               *******                       '  
                                dc.b    '               *** ****                      '  
                                dc.b    '               **** ***                      '  
                                dc.b    '               **                            '  
                                dc.b    '                                             '  
                                dc.b    '       TEL : *** ****** ****** (*****)       '  
                                dc.b    '           ALSO -ELITE- SWAPPING!            '  
                                dc.b    '                                             '  
                                dc.b    '  .............MORE ADDRESSES..............  '  
                                dc.b    '                                             ' 

addresses_2_menu        ; original address L0003BFF9
                                ;        123456789012345678901234567890123456789012345
                                dc.b    '   TO JOIN THE UK DIVISION WRITE TO ONE OF   '  
                                dc.b    '           THE FOLLOWING ADDRESSES:-         ' 
                                dc.b    '                                             '   
                                dc.b    '                                             '  
                                dc.b    '    AZTEC               HOLLYWOOD            '  
                                dc.b    '    ** ******** ***     ** ********* ***     '  
                                dc.b    '    *******             **********           '  
                                dc.b    '    *************       ******               '  
                                dc.b    '    *** ***             *** ***              '  
                                dc.b    '                                             '  
                                dc.b    '    ELITE SWAP ALSO     ELITE MUSIC SWAP     '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '  .............MORE ADDRESSES..............  '  
                                dc.b    '                                             ' 
             
addresses_3_menu        ; original address L0003C2F6
                                ;        123456789012345678901234567890123456789012345 
                                dc.b    '    TO JOIN THE AUSTRIAN DIVISION WRITE TO   '  
                                dc.b    '       ONE OF THE FOLLOWING ADDRESSES:-      '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '   RIP               NUKE                    '  
                                dc.b    '   ** *** **         ** *** **               '  
                                dc.b    '   **** *******      ****** *******          '  
                                dc.b    '   *******           *******                 '  
                                dc.b    '                                             '  
                                dc.b    '                     ALSO ELITE SWAP         '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '  .............MORE ADDRESSES..............  '    
                                dc.b    '                                             '                                 

addresses_4_menu        ; original address L0003C5F3
                                ;        123456789012345678901234567890123456789012345
                                dc.b    '     TO JOIN THE DUTCH DIVISION WRITE TO     '  
                                dc.b    '          THE FOLLOWING ADDRESS:-            '  
                                dc.b    '                                             '  
                                dc.b    '           SANE                              '  
                                dc.b    '           *************** **                '  
                                dc.b    '           **** ** *********                 '  
                                dc.b    '           *******                           '  
                                dc.b    '                                             '  
                                dc.b    '           TEL : *** ******* *****           '  
                                dc.b    '                                             '  
                                dc.b    '           ALSO ELITE SWAP                   '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '  .............MORE ADDRESSES..............  ' 
                                dc.b    '                                             ' 

addresses_5_menu        ; original address L0003C8F0
                                ;        123456789012345678901234567890123456789012345
                                dc.b    '  TO JOIN THE AUSTRALIAN DIVISION WRITE TO   '  
                                dc.b    '           THE FOLLOWING ADDRESS:-           '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '           WOODY                             '  
                                dc.b    '           * ***** *****                     '  
                                dc.b    '           ********                          '  
                                dc.b    '           ******** ****                     '  
                                dc.b    '           **********                        '  
                                dc.b    '                                             '  
                                dc.b    '           ALSO -ELITE- SWAP                 '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '  .............MORE ADDRESSES..............  ' 
                                dc.b    '                                             ' 

                                ;        123456789012345678901234567890123456789012345
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             ' 

addresses_6_menu        ; original address L0003CBED          
                                ;        123456789012345678901234567890123456789012345
                                dc.b    '    TO JOIN THE SWEDISH DIVISION WRITE TO    '  
                                dc.b    '          THE FOLLOWING ADDRESS:-            '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '           PHASER                            '  
                                dc.b    '           ********* **                      '  
                                dc.b    '           *** ** *********                  '  
                                dc.b    '           ******                            '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '  ..........RETURN TO MAIN MENU ...........  '   
                                dc.b    '                                             ' 

pd_message_menu        ; original address L0003CEEA 
                                ;        123456789012345678901234567890123456789012345
                                dc.b    '                                             ' 
                                dc.b    '  THIS PAGE ORIGINALLY CONTAINED A MESSAGE   '  
                                dc.b    '  TO P.D. COMPANIES AKSING THEM TO RESPECT   '  
                                dc.b    '  THE AUTHORS COPYRIGHT.....                 '  
                                dc.b    '                                             '  
                                dc.b    '  ....I THINK YOU WILL AGREE THAT THIS WAS   '  
                                dc.b    '  A BIT RICH COMING FROM A GROUP THAT HAD    '  
                                dc.b    '  MEMBERS SWAPPING WAREZ AROUND THE WORLD.   '  
                                dc.b    '                                             '  
                                dc.b    '  WE WERE YOUNG AND NAIVE.......             '  
                                dc.b    '                                             '  
                                dc.b    '           .....WISH I STILL WAS.....        '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '  ..........RETURN TO MAIN MENU ...........  '  
 

                                ; spare screen template for text typer/menu 45 x 17 characters
                                ;        123456789012345678901234567890123456789012345
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             '  
                                dc.b    '                                             ' 


        IFD TEST_BUILD
load_buffer             dcb.b   1024*200,$00
        ENDC



_DEBUG_COLOUR_RED
            move.w  #$f00,$dff180
            rts

_DEBUG_COLOUR_GREEN
            move.w  #$0f0,$dff180
            rts

_DEBUG_COLOUR_BLUE
            move.w  #$00f,$dff180
            rts                    

_DEBUG_COLOURS
            move.w  d0,$dff180
            add.w   #$1,d0
            btst    #6,$bfe001
            bne.s   _DEBUG_COLOURS
            rts
            
_DEBUG_RED_PAUSE
                    move.w  #$f00,$dff180
                    btst    #6,$bfe001
                    bne.s   _DEBUG_RED_PAUSE
                    rts

_MOUSE_WAIT
            btst    #6,$bfe001
            bne.s   _MOUSE_WAIT
            rts

