

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



        ; Disk Track Storage
        ;------------------------
        ; The music disk loader loads in an extra track (no of tracks + 1) 
        ; There is 5.5Kb loaded per track (5632 bytes per track)
        ;
        ; Disk 1        Title                   Start Track     No of Tracks    Last Track (inclusive)  Data loaded (bytes)
        ;               Loading Picture         $00 (00)        $09+1 (10)      $09 (09)                56,320 (raw gfx)
        ;               Demo Program            $0b (11)        $07+1 (8)       $12 (18)                45,056 (cruched executable)
        ;               Jarresque               $8e (142)       $11+1 (18)      $9f (159)               101,376
        ;               The Fly                 $5c (92)        $15+1 (22)      $71 (113)               123,904
        ;               Stratospheric City      $3b (59)        $1f+1 (32)      $5a (90)                180,224
        ;               Float                   $73 (115)       $19+1 (26)      $8c (140)               146,432
        ;               Flight-Sleepy Mix       $1b (27)        $1e+1 (31)      $39 (57)                174,592
        ;
        ; Disk 2        Title                   Start Track     No of Tracks    Last Track (inclusive)  Data loaded (bytes)
        ;               bootblock & gfx         $00 (00)        $00+1 (01)      $00 (00)                5,632
        ;               Shaft                   $8e (142)       $11+1 (18)      $9f (159)               101,376
        ;               Love Your Money         $7e (126)       $0e+1 (15)      $8c (140)               84,480
        ;               Cosmic How Much         $70 (112)       $0c+1 (13)      $7c (124)               73,216
        ;               This is not a Rave Song $0c (12)        $0d+1 (14)      $19 (25)                78,848
        ;               Eat the Ballbearing     $55 (85)        $19+1 (26)      $6e (110)               146,432
        ;               Sound of Silence        $40 (64)        $13+1 (20)      $54 (84)                112,640
        ;               Retouche                $1b (27)        $10+1 (17)      $2c (44)                95,744
        ;               Techwar                 $2d (45)        $11+1 (18)      $3e (62)                101,376
        ;               Bright                  $01 (01)        $09+1 (10)      $0a (10)                56,320
        ;
        ; Disk 3        Title                   Start Track     No of Track     Last Track (inclusive)  Data Loaded (bytes)
        ;               bootblock & gfx         $00 (00)        $00+1 (01)      $00 (00)                5,632
        ;               Mental Obstacle         $8d (141)       $12+1 (19)      $9f (159)               107,008
        ;               Blade Runner            $02 (02)        $11+1 (18)      $13 (19)                101,376
        ;               Natural Reality         $7d (125)       $0e+1 (15)      $8b (139)               84,480
        ;               Obiliteration Fin       $6f (111)       $0c+1 (13)      $7b (123)               73,216
        ;               Skyriders               $52 (82)        $1b+1 (28)      $6d (109)               157,696
        ;               Zero Gravity            $43 (67)        $0d+1 (14)      $50 (80)                78,848
        ;               Break THrough           $15 (21)        $0d+1 (14)      $22 (34)                78,848
        ;               Summer In Sweden        $35 (53)        $0c+1 (13)      $41 (65)                73,216
        ;               Never to Much           $24 (36)        $0f+1 (16)      $33 (51)                90,112
        ;

                    section     demo,code_c
                    incdir      "include/"
                    include     "hw.i"




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




TEST_BUILD SET 1                                        ; Comment this to remove 'testboot'



        ; Set 'Test Build' or 'Live Build' parameters 
        IFD TEST_BUILD
STACK_ADDRESS   EQU     start_demo                      ; test stack address (start of program)
LOAD_BUFFER     EQU     load_buffer                     ; file load buffer
MFM_BUFFER      EQU     mfm_track_buffer
        ELSE
STACK_ADDRESS   EQU     $00080000                       ; original stack address
LOAD_BUFFER     EQU     $00040000                       ; file load buffer
MFM_BUFFER      EQU     $00075000
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

loader_4489
                ;include "4489Loader/4489_byteloader.s"
                include "4489Loader/4489_byteloader_code.s"

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
                                MOVE.W  #$8022,INTENA(A6)                       ; enable COPER & DSKBLK


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

                        ; check if need to change music track
                                BTST.B  #LOAD_MODULE,loader_status_bits         
                                BEQ.B   .do_menu_processing                     

.do_change_music        ; stop existing track(if playing), then load selected track
                                BTST.B  #MUSIC_PLAYING,music_status_bits        ; is music playing?
                                BEQ.B   .load_music                             ;   if no, load music
                                                                                ;   if yes, stop music
.disable_music          ; stop music playing
                                BCLR.B  #MUSIC_PLAYING,music_status_bits
                                ;BSR.W   music_off                                               ; L00021C0A
                              
                                JSR     _mt_end

.load_music             ; load music
                                BSR.W   load_music                                              ; L00021814
                                BCLR.B  #LOAD_MODULE,loader_status_bits                                                 ; set running status

                                BCLR.B  #MENU_FADING,menu_selection_status_bits                 ; enable menu selection ; L000203A8
                                BCLR.B  #MENU_MOUSE_PTR_DISABLED,menu_selection_status_bits     ; L000203A8
                                BSET.B  #$0001,music_status_bits



.do_menu_processing     ; do menu processing
                                BTST.B  #MENU_FADING,menu_selection_status_bits                 ; L000203A8
                                BNE.B   .mouse_not_clicked                                      ; L00020362 
                        
.mouse_test             ; test mouse clicked
                                BTST.B  #$0006,$00bfe001
                                BNE.B   .mouse_not_clicked                                      ; L00020362 

.mouse_is_clicked       ; do menu item selected processing
                                BSET.B  #MENU_FADING,menu_selection_status_bits                 ; disable menu selection ; L000203A8
                                BSET.B  #MENU_MOUSE_PTR_DISABLED,menu_selection_status_bits     ; L000203A8
                                BSR.W   do_menu_action                                          ; L0002088E

.mouse_not_clicked      ; test draw new menu (if required)
                                BTST.B  #MENU_DISP_DRAW,menu_display_status_bits                ; L000203AA
                                BNE.B   .check_clear_menu                                       ; L00020370 
                                BSR.W   display_menu                                            ; L0002049C

                        ; test clear menu display (if required)
.check_clear_menu
                                BTST.B  #MENU_DISP_CLEAR,menu_display_status_bits               ; L000203AA
                                BEQ.B   .check_music_init                                       ; L0002037E 
                                BSR.W   clear_menu_display                                      ; L000207B6

                        ; test menu item selected/loading
.check_music_init
                                BTST.B  #$0001,music_status_bits
                                BEQ.B   .end_main_loop                                          ; L000203A4

                        ; do music initialisation
.initialise_music
                                ;BSR.W   music_init                                              ; L00021B96
                                JSR _mt_remove

                                lea     $0,a0
                                move.L  #$1,d0
                                JSR     _mt_install

                                lea     LOAD_BUFFER,a0
                                lea     $0,a1
                                move.l  #$0,d0
                                JSR     _mt_init

                                move.b  #$ff,_mt_Enable

                                BCLR.B  #$0001,music_status_bits
                                BSET.B  #$0000,music_status_bits

.end_main_loop
                                BRA.W   main_loop                                               ; L000202F6 



                ; menu_selection_status_bits
MENU_FADING             EQU     $0000           ; bit 0 (1 = menu is fading in/out)
MENU_MOUSE_PTR_DISABLED EQU     $0001           ; bit 1 (1 = menu pointer updates disabled)
menu_selection_status_bits      dc.b    $00     ; original address L000203A8



LOAD_MODULE             EQU     $0000           ; bit 0 (1 = loading protracker module)
loader_status_bits      ; original address L000203A9
                                dc.b    $00     ; bit 0 (1 = loading protrackermodule)


                ; menu_display_status_bits
MENU_DISP_FADE_IN               EQU     $0      ; bit 0 - 1 = Fade Menu In
MENU_DISP_FADE_OUT              EQU     $1      ; bit 1 - 1 = Fade Menu Out
MENU_DISP_CLEAR                 EQU     $6      ; bit 6 - 1 = Clear Menu Display
MENU_DISP_DRAW                  EQU     $7      ; bit 7 - 1 = Draw New Menu
menu_display_status_bits        dc.b    $00     ; original address L000203AA

MUSIC_PLAYING                   EQU     $0      ; bit 0 - 1 = music playing
music_status_bits               dc.b    $00     ; original address L000203AB 

menu_ptr_index  ; original address L000203AC -  ;  index to menu typer ptr list.
                                dc.w    $0000    ; index to the list of menu text pointers (multiple of 4 - longword list)






                ; ----------------------- Level 3 Interrupt Handler ----------------
                ; VBL and COPER interrupt handler routine, intended to be called
                ; ones per frame.
level_3_interrupt_handler ; original address L000203AE
                                MOVEM.L D0-D7/A0-A6,-(A7)
                                lea     $dff000,a6
                                MOVE.W  INTREQR(a6),d0
                                AND.W   #$0020,d0
                                BEQ.S   .exit_handler  


                                BSR.W   text_scroller                   ; Bottom screen text scroller - L0002152E
                                BSR.W   swap_vector_logo_buffers        ; L000212F8
                                BSR.W   clear_vector_logo_buffer        ; L000212D2
                                BSR.W   spin_logo                       ; L000213EE
                                BSR.W   calc_3d_perspective             ; L0002138E
                                BSR.W   draw_logo_outline               ; L00021352
                                BSR.W   calc_logo_lighting              ; L000213D8
                                BSR.W   fill_vector_logo                ; L00021290

                        ; do fade in menu display (if required)
.do_menu_fade_in                BTST.B  #MENU_DISP_FADE_IN,menu_display_status_bits             ; L000203AA
                                BEQ.B   .do_menu_fade_out 
                                BSR.W   fade_in_menu_display            ; L000205D4 - bit 0 = 1 - fade in menu display

                        ; do fade out menu display (if required)
.do_menu_fade_out               BTST.B  #MENU_DISP_FADE_OUT,menu_display_status_bits            ; L000203AA - bit 1 = 1 - fade out menu display
                                BEQ.B   .do_blended_fade                       
                                BSR.W   fade_out_menu_display                                   ; L00020672 - bit 1 = 1 - menu routine

                        ; blend typer colour where it overlaps with vector logo (alpha blend effect)
.do_blended_fade                BSR.W   blend_typer_colour_fade                                 ; L00020746



.do_menu_item_pointers  ; test menu disabled status bits
                                BTST.B  #MENU_MOUSE_PTR_DISABLED,menu_selection_status_bits     ; L000203A8
                                BNE.B   .do_music                                               ; L00020406 
                        ; update menu item selection pointer display
                                BSR.W   update_menu_selector_position                           ; L000207EA


.do_music                ; test music loaded & ready - original address L00020406
                                BTST.B  #MUSIC_PLAYING,music_status_bits
                                BEQ.B   .no_music                                               ; L00020420
                        ; play/update music
                                ;BSR.W   play_music                                              ; L00021C2C
                                move.b  #$ff,_mt_Enable
                                bra     .exit_handler 
.no_music
                                move.b  #$00,_mt_Enable

.exit_handler    ; original address L00020424
                                MOVE.W  #$0020,INTREQ(A6)
                                MOVEM.L (A7)+,D0-D7/A0-A6
                                RTE 




                ; ------------------------ display menu -------------------------
                ; Routine to display menu text on the screen. The menu is 
                ; displayed in a 1 bitplane screen, overlayed on a vector
                ; spinning logo.
                ; The text is displaed using the processor (which is odd for me)
                ; i'd normally use the blitter for gfx operations.
                ; The typer works in the main loop, while all blitter operations
                ; occur during the copper interrupt.
                ;
                ; The screen format is 45 characters wide by 17 text lines high.
                ;
display_menu    ; original address L0002049C
                                LEA.L   menu_typer_bitplane,a0
                                LEA.L   menu_font_gfx,a2   
                                LEA.L   menu_ptrs,a3
                                MOVE.W  menu_ptr_index,d0                       ; menu ptr index (multiple of 4)
                                LEA.L   $00(A3,D0.W),A3
                                MOVEA.L (A3),A3                                 ; a3 = menu text to display
                                MOVE.W  #$002c,D7                               ; 44+1 characters wide
                                MOVE.W  #$0010,D6                               ; 16+1 lines tall

                ; print character loop -L000204C2
.print_char_loop
                                MOVE.L  #$00000000,D0
                                MOVE.L  #$00000000,D1
                                MOVE.L  #$00000000,D2
                                MOVE.L  #$00000000,D3
                                MOVE.L  #$00000000,D4
                                MOVE.B  (A3)+,D0                        ; d0 = char to print
                                SUB.B   #$20,D0                         ; font starts at 'space' char (32 ascii)
                                LSL.B   #$00000001,D0                   ; d- = index to start of char gfx
                                LEA.L   $00(A2,D0.W),A4                 ; a4 = char gfx ptr
                                MOVE.W  character_x_pos,d1              
                                MOVE.W  D1,D3
                                LSR.W   #$00000003,D1                   ; d1 = byte offset
                                MOVE.W  D1,D4
                                LSL.W   #$00000003,D4                   ; d4 = rounded pixel offset
                                SUB.W   D4,D3                           ; d3 = shift vale
                                BTST.L  #$0000,D1                       ; check of odd bytes offset
                                BEQ.W   .is_even_byte_offset 
                                BCLR.L  #$0000,D1
                                MOVE.W  #$0008,D2
                                BRA.W   .do_shift_and_print
.is_even_byte_offset
                                MOVE.W  #$0000,D2
.do_shift_and_print
                                LEA.L   $00(A0,D1.W),A1                 ; a1 = dest ptr + x offset
                                MOVE.W  character_y_offset,D1
                                LEA.L   $00(A1,D1.W),A1                 ; a1 = dest ptr + y offset
                                MOVE.L  $0000(A4),D0                    ; char line 1
                                AND.L   #$ffff0000,D0
                                ROR.L   D2,D0
                                ROR.L   D3,D0
                                OR.L    D0,$0000(A1)
                                MOVE.L  $0076(A4),D0                    ; char line 2
                                AND.L   #$ffff0000,D0
                                ROR.L   D2,D0
                                ROR.L   D3,D0
                                OR.L    D0,$0028(A1)
                                MOVE.L  $00ec(A4),D0                    ; char line 3
                                AND.L   #$ffff0000,D0
                                ROR.L   D2,D0
                                ROR.L   D3,D0
                                OR.L    D0,$0050(A1)
                                MOVE.L  $0162(A4),D0                    ; char line 4
                                AND.L   #$ffff0000,D0
                                ROR.L   D2,D0
                                ROR.L   D3,D0
                                OR.L    D0,$0078(A1)
                                MOVE.L  $01d8(A4),D0                    ; char line 5
                                AND.L   #$ffff0000,D0
                                ROR.L   D2,D0
                                ROR.L   D3,D0
                                OR.L    D0,$00a0(A1)
                                MOVE.L  $024e(A4),D0                    ; char line 6
                                AND.L   #$ffff0000,D0
                                ROR.L   D2,D0
                                ROR.L   D3,D0
                                OR.L    D0,$00c8(A1)
                                MOVE.L  $02c4(A4),D0                    ; char line 7
                                AND.L   #$ffff0000,D0
                                ROR.L   D2,D0
                                ROR.L   D3,D0
                                OR.L    D0,$00f0(A1)

                                ADD.W   #$0007,character_x_pos          ; add character width to x position
                                DBF.W   D7,.print_char_loop

                                MOVE.W  #$0000,character_x_pos          ; reset x position (left hand side)
                                ADD.W   #$0140,character_y_offset       ; increment line offset (8 rasters = 320 bytes)
                                MOVE.W  #$002c,D7                       ; reset line loop counter (next 45 chars)
                                DBF.W   D6,.print_char_loop             ; do next line loop

                                BSET.B  #MENU_DISP_DRAW,menu_display_status_bits        ; bit 7 - 1 = menu typer completed
                                BSET.B  #MENU_DISP_FADE_IN,menu_display_status_bits     ; bit 0 - 1 = do fade in menu display
                                MOVE.W  #$0000,character_x_pos                          ; reset x position
                                MOVE.W  #$0000,character_y_offset                       ; reset y offset (line position)
                                RTS 

character_x_pos ; original address L000205D0 - x - pixel position        
                                dc.w    $0000 
character_y_offset ; original address L000205D2 - y - offset (multiple of bytes per raster)
                                dc.w    $0000




                        ; --------------------- fade in menu display text ----------------------
                        ; Fades in the text colour of the menu text display. 
                        ; This routine sets the colour in the copper list for the value where
                        ; the text does not overlap the vector logo in the backround.
                        ; A separate routine is used to blend the vector colour with the text
                        ; colour when it fades in/out to give an alpha type effect.
                        ; This routine does set the colour used by the alpha routine in the
                        ; menu_text_fade_colour_copy variable.
                        ;
fade_in_menu_display    ; original address L000205D4
                                CMP.B   #$03,fade_speed_counter                         ; L00020743
                                BNE.W   .exit_fade_in                                   ; L00020668 
                                MOVE.B  #$00,fade_speed_counter                         ; L00020743
                                LEA.L   copper_menu_fade_colour,a0                      ; L00022DAE,A0
                                MOVE.W  $0002(A0),D0                                    ; get current colour from copper list
.calc_blue_component
                                MOVE.W  D0,D1
                                AND.W   #$000f,D1
                                CMP.W   #$000f,D1
                                BEQ.B   .calc_green_component                           ; L00020604 
                                ADD.W   #$0001,$0002(A0)                                ; update colour reg in copper list
.calc_green_component
                                MOVE.W  D0,D1
                                AND.W   #$00f0,D1
                                CMP.W   #$00f0,D1
                                BEQ.B   .calc_red_component                             ; L00020616 
                                ADD.W   #$0010,$0002(A0)                                ; update colour reg in copper list
.calc_red_component
                                MOVE.W  D0,D1
                                AND.W   #$0f00,D1
                                CMP.W   #$0f00,D1
                                BEQ.B   .set_blend_copy_colour                          ; L00020628 
                                ADD.W   #$0100,$0002(A0)                                ; update colour reg in copper list
.set_blend_copy_colour   ; set the copy of the colour for the blend fade routine
                                MOVE.W  menu_text_fade_colour_copy,d0                   ; L00020744,D0
                                CMP.W   #$0fff,D0
                                BEQ.B   .update_fade_count                              ; L0002063C 
                                ADD.W   #$0111,menu_text_fade_colour_copy               ; increment current fade colour - L00020744
.update_fade_count
                                ADD.B   #$01,fade_counter                               ; L00020742
                                CMP.B   #$10,fade_counter                               ; L00020742
                                BNE.B   .fade_in_not_complete                           ; L00020666 
.set_fade_in_complete
                                BCLR.B  #MENU_DISP_FADE_IN,menu_display_status_bits      ; set fade in completed (clear bit 0) - L000203AA
                                BCLR.B  #MENU_FADING,menu_selection_status_bits          ; L000203A8
                                MOVE.W  #$0000,fade_counter                              ; L00020742
.fade_in_not_complete
                                RTS 

.exit_fade_in
                                ADD.B   #$01,fade_speed_counter                 ; L00020743
                                RTS 




                        ; --------------------- fade in menu display text ----------------------
                        ; Fades out the text colour of the menu text display. 
                        ; This routine sets the colour in the copper list for the value where
                        ; the text does not overlap the vector logo in the backround.
                        ; A separate routine is used to blend the vector colour with the text
                        ; colour when it fades in/out to give an alpha type effect.
                        ; This routine does set the colour used by the alpha routine in the
                        ; menu_text_fade_colour_copy variable.
                        ; when the fade completes, then this routine sets the menu sprite
                        ; coords ready for the next menu (obviously I didn;t care or know
                        ; much about separation of concerns when I was 17)
                        ;
fade_out_menu_display   ; original address L00020672
                                CMP.B   #$03,fade_speed_counter                         ; L00020743
                                BNE.W   .exit_fade_out                                  ; L00020738 
                                MOVE.B  #$00,fade_speed_counter                         ; L00020743
                                LEA.L   copper_menu_fade_colour,a0                      ; L00022DAE,A0
                                MOVE.W  $0002(A0),D0
.calc_blue_component
                                MOVE.W  D0,D1
                                AND.W   #$000f,D1
                                CMP.W   #$0002,D1
                                BEQ.B   .calc_green_component                           ; L000206A2 
                                SUB.W   #$0001,$0002(A0)
.calc_green_component
                                MOVE.W  D0,D1
                                AND.W   #$00f0,D1
                                CMP.W   #$0000,D1
                                BEQ.B   .calc_red_component                             ; L000206B4 
                                SUB.W   #$0010,$0002(A0)
.calc_red_component
                                AND.W   #$0f00,D0
                                CMP.W   #$0000,D0
                                BEQ.B   .set_blend_copy_colour                          ; L000206C4 
                                SUB.W   #$0100,$0002(A0)
.set_blend_copy_colour   ; set the copy of the colour for the blend fade routine
                                MOVE.W  menu_text_fade_colour_copy,D0
                                CMP.W   #$0000,D0
                                BEQ.B   .update_fade_count                              ; L000206D8 
                                SUB.W   #$0111,menu_text_fade_colour_copy
.update_fade_count
                                ADD.B   #$01,fade_counter                               ; L00020742
                                CMP.B   #$10,fade_counter                               ; L00020742
                                BNE.B   .fade_in_not_complete                           ; L00020736 
.set_fade_out_complete
                                BCLR.B  #MENU_DISP_FADE_OUT,menu_display_status_bits            ; set fade out completed (clear bit 1) - L000203AA
                                BSET.B  #MENU_DISP_CLEAR,menu_display_status_bits               ; (set bit 6) - L000203AA
                                BCLR.B  #MENU_MOUSE_PTR_DISABLED,menu_selection_status_bits     ; L000203A8
                                MOVE.W  #$0000,fade_counter                                     ; L00020742
.set_menu_sprite_ptrs
                                LEA.L   menu_sprite_left,A0                                     ; L00035FB8,A0
                                MOVE.B  left_sprite_hpos1,$0001(A0)
                                MOVE.B  left_sprite_hpos2,$0003(A0)
                                LEA.L   menu_sprite_right,A0                                    ; L00035FDC,A0
                                MOVE.B  right_sprite_hpos1,$0001(A0)
                                MOVE.B  right_sprite_hpos2,$0003(A0)
.fade_in_not_complete
                                RTS 

.exit_fade_out
                                ADD.B   #$01,fade_speed_counter         ; L00020743
                                RTS 


fade_counter            ; original address L00020742 - used to measure if the fade is complete (after 16 fade levels)
                                dc.b $00
fade_speed_counter      ; original address L00020743
                                dc.b $00

                                even
menu_text_fade_colour_copy ; original address L00020744 - copy of the menu text colour (used by the colour blend routine below)
                                dc.w $0000




                ; ----------------------- blend typer colour fade ----------------------
                ; combines the current typer colour (which i've named alpha here) with
                ; the current vector logo colour behind it on the display.
                ; clamp the colour to the max value.
                ;
blend_typer_colour_fade ; original address L00020746
                                LEA.L   copper_vector_logo_colour,A0                    ; vector logo colour
                                LEA.L   copper_menu_fade_colour,A1      ; text menu copper colour
                                MOVE.L  #$00000000,D4
                                MOVE.W  (A0),D0                         ; get current vector logo colour value
                                MOVE.W  D0,D2
                                MOVE.W  menu_text_fade_colour_copy,d1       ; L00020744,D1
.calc_blue_component
                                MOVE.W  D1,D3
                                AND.W   #$000f,D2                       ; vector logo blue component
                                AND.W   #$000f,D3                       ; typer alpha value
                                ADD.W   D2,D3                           ; add together
                                CMP.W   #$000f,D3
                                BLE.W   .set_blue_component              ; L00020776 
                                MOVE.W  #$000f,D3                       ; clamp blue to max blue
.set_blue_component
                                OR.W    D3,D4                           ; set blue component
.calc_green_component
                                MOVE.W  D0,D2
                                MOVE.W  D1,D3
                                AND.W   #$00f0,D2                       ; vector logo green component
                                AND.W   #$00f0,D3                       ; typer green component
                                ADD.W   D2,D3                           ; add together
                                CMP.W   #$00f0,D3       
                                BLE.W   .set_green_component             ; L00020792 
                                MOVE.W  #$00f0,D3                       ; clamp to max green
.set_green_component
                                OR.W    D3,D4
.calc_red_component
                                MOVE.W  D0,D2
                                MOVE.W  D1,D3
                                AND.W   #$0f00,D2                       ; vector logo red component
                                AND.W   #$0f00,D3                       ; typer red component
                                ADD.W   D2,D3                           ; add together
                                CMP.W   #$0f00,D3
                                BLE.W   .set_red_component               ; L000207AE 
                                MOVE.W  #$0f00,D3                       ; clamp to max red
.set_red_component
                                OR.W    D3,D4
                                MOVE.W  D4,$0006(A1)                    ; set blended colour value in copper list
                                RTS 





                ; -------------------- clear menu display ---------------------
                ; uses the processor to clear the 1 bitplane 320x135 pixel
                ; menu display.
clear_menu_display      ; original address L000207B6
                                LEA.L   menu_typer_bitplane,a0          ; L00022E82,A0
                                MOVE.W  #$0009,D7                       ; loop counter 9+1
                                MOVE.W  #$0087,D6                       ; loop counter 135+1
                                MOVE.L  #$00000000,D0
.clear_loop                     MOVE.L  D0,(A0)+
                                DBF.W   D7,.clear_loop 
                                MOVE.W  #$0009,D7
                                DBF.W   D6,.clear_loop 
                                BCLR.B  #MENU_DISP_DRAW,menu_display_status_bits        ; L000203AA ; flag - menu cleared status bits
                                BCLR.B  #MENU_DISP_CLEAR,menu_display_status_bits       ; L000203AA ; flag - menu cleared status bits
                                RTS 




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


; sprite menu pointer control word values (used to set sprite control word values directly)
left_sprite_hpos1               dc.b    $6c     ; left sprite hvalue (bit 2-9 of hpos)
left_sprite_hpos2               dc.b    $01     ; left sprite hvalue (bit 1 of hpos)
right_sprite_hpos1              dc.b    $a9     ; right sprite hvalue (bit 2-9 of hpos)
right_sprite_hpos2              dc.b    $01     ; right sprite hvalue (bit 1 of hpos)






        ; *****************************************************************************
        ; ***                         MENU ACTION PROCESSING                        ***
        ; *****************************************************************************
        ; The menu action processing is hard-coded (I was only 17 at the time)
        ; It works as follows:-
        ;
        ; 1) Detect which menu is currently displayed and call the relevent handler
        ; 2) compare the vertical position of the sprite selection sprites
        ;       depending on the position, either:-
        ;              a) display a different menu, or
        ;              b) load a module to play
        ;


        ; -------------------------------- do menu action ------------------------------
        ; called from the main loop when the mouse button is clicked. 
        ; the routine checks the currently displayed menu and performs the necessary 
        ; actions for that menu.
        ;
do_menu_action                  ; original address L0002088E
                        ; main menu actions
                                CMP.W   #MENU_IDX_main_menu,menu_ptr_index              ; L000203AC
                                BEQ.W   do_main_menu_actions                            ; L00020938 
                        ; disk 1 menu actions
                                CMP.W   #MENU_IDX_disk_1_menu,menu_ptr_index            ; L000203AC
                                BEQ.W   do_disk_1_menu_actions                          ; L00020CFC
                        ; disk 2 menu actions
                                CMP.W   #MENU_IDX_disk_2_menu,menu_ptr_index            ; L000203AC
                                BEQ.W   do_disk_2_menu_actions                          ; L00020D3C 
                        ; disk 3 menu actions
                                CMP.W   #MENU_IDX_disk_3_menu,menu_ptr_index            ; L000203AC
                                BEQ.W   do_disk_3_menu_actions                          ; L00020DAC 
                        ; credits menu actions
                                CMP.W   #MENU_IDX_credits_menu,menu_ptr_index           ; L000203AC
                                BEQ.W   set_main_menu_params                            ; L0002124E
                        ; greetings 1 menu actions
                                CMP.W   #MENU_IDX_greetings_1_menu,menu_ptr_index       ; L000203AC
                                BEQ.W   do_greetings_1_menu_actions                     ; L00020E1C 
                        ; greetings 2 menu actions
                                CMP.W   #MENU_IDX_greetings_2_menu,menu_ptr_index       ; L000203AC
                                BEQ.W   set_main_menu_params                            ; L0002124E
                        ; addresses 1 menu actions
                                CMP.W   #MENU_IDX_addresses_1_menu,menu_ptr_index       ; L000203AC
                                BEQ.W   set_addresses_2_menu_params                     ; L00020B5E 
                        ; addresses 2 menu actions
                                CMP.W   #MENU_IDX_addresses_2_menu,menu_ptr_index       ; L000203AC
                                BEQ.W   set_addresses_3_menu_params                     ; L00020BA0 
                        ; addresses 3 menu actions
                                CMP.W   #MENU_IDX_addresses_3_menu,menu_ptr_index       ; L000203AC
                                BEQ.W   set_addresses_4_menu_params                     ; L00020BE2 
                        ; addresses 4 menu actions
                                CMP.W   #MENU_IDX_addresses_4_menu,menu_ptr_index       ; L000203AC
                                BEQ.W   set_addresses_5_menu_params                     ; L00020C24 
                        ; addresses 5 menu actions
                                CMP.W   #MENU_IDX_addresses_5_menu,menu_ptr_index       ; L000203AC
                                BEQ.W   set_addresses_6_menu_params                     ; L00020C66 
                        ; addresses 6 menu actions
                                CMP.W   #MENU_IDX_addresses_6_menu,menu_ptr_index       ; L000203AC
                                BEQ.W   set_main_menu_params                            ; L0002124E 
                        ; pd menu actions
                                CMP.W   #MENU_IDX_pd_message_menu,menu_ptr_index        ; L000203AC
                                BEQ.W   set_main_menu_params                            ; L0002124E
                        ; other - exit (shouldn't happen)
                                RTS 




                ; ------------------------ do main menu actions -------------------------
                ; called from main 'do_menu_action' when the main menu is displayed.
                ; From this menu, you can only navigate to other sub menus.
                ;
                ;                - Disk 1 Menu
                ;                - Disk 2 Menu
                ;                - Disk 3 Menu
                ;                - Credits 
                ;                - Greetings
                ;                - Addresses
                ;                - PD Message
                ;
do_main_menu_actions    ; original address L00020938
                                CMP.W   #$0024,menu_selector_y          
                                BLE.W   set_disk_1_menu_params           
                                CMP.W   #$002c,menu_selector_y          
                                BLE.W   set_disk_2_menu_params           
                                CMP.W   #$0034,menu_selector_y          
                                BLE.W   set_disk_3_menu_params           
                                CMP.W   #$003c,menu_selector_y          
                                BLE.W   set_credits_menu_params          
                                CMP.W   #$0044,menu_selector_y          
                                BLE.W   set_greetz_1_menu_params         
                                CMP.W   #$004c,menu_selector_y          
                                BLE.W   set_addresses_1_menu_params      
                                CMP.W   #$0054,menu_selector_y          
                                BLE.W   set_pd_message_menu_params       
                                BRA.W   enable_menu_selection            


enable_menu_selection
                                BCLR.B  #MENU_FADING,menu_selection_status_bits                 
                                BCLR.B  #MENU_MOUSE_PTR_DISABLED,menu_selection_status_bits     
                                RTS 



                ; ----------------------- do disk 1 menu actions ---------------------
                ; called from main 'do_menu_action' when the menu is displayed.
                ; From this menu, you can load music, or return to the main menu
                ;
                ;               Jarresque
                ;               The Fly
                ;               Stratospheric City
                ;               Float
                ;               FLight-Sleepy Mix
                ;               Return to Main Menu
                ;
do_disk_1_menu_actions ; original address L00020CFC
                                CMP.W   #$0034,menu_selector_y          
                                BLE.W   set_loader_jarresque             
                                CMP.W   #$003c,menu_selector_y          
                                BLE.W   set_loader_the_fly               
                                CMP.W   #$0044,menu_selector_y          
                                BLE.W   set_loader_stratospheric_city    
                                CMP.W   #$004c,menu_selector_y          
                                BLE.W   set_loader_float                 
                                CMP.W   #$0054,menu_selector_y          
                                BLE.W   set_loader_flight_sleepy_mix     
                                BRA.W   set_main_menu_params             



                ; ----------------------- do disk 2 menu actions ---------------------
                ; called from main 'do_menu_action' when the menu is displayed.
                ; From this menu, you can load music, or return to the main menu
                ;
                ;               Shaft
                ;               Love Your Money
                ;               Cosmic How Much
                ;               This Is Not A Love Song
                ;               Eat The Ballbearing
                ;               Sound Of Silence
                ;               Retouche
                ;               Techwar
                ;               Bright
                ;               Return to Main Menu
                ;
do_disk_2_menu_actions  ; original address L00020D3C
                                CMP.W   #$002c,menu_selector_y          
                                BLE.W   set_loader_shaft                 
                                CMP.W   #$0034,menu_selector_y          
                                BLE.W   set_loader_love_your_money       
                                CMP.W   #$003c,menu_selector_y          
                                BLE.W   set_loader_cosmic_how_much       
                                CMP.W   #$0044,menu_selector_y          
                                BLE.W   set_loader_not_a_love_song       
                                CMP.W   #$004c,menu_selector_y          
                                BLE.W   set_loader_eat_the_ballbearing   
                                CMP.W   #$0054,menu_selector_y          
                                BLE.W   set_loader_sound_of_silence      
                                CMP.W   #$005c,menu_selector_y          
                                BLE.W   set_loader_retouche              
                                CMP.W   #$0064,menu_selector_y          
                                BLE.W   set_loader_techwar               
                                CMP.W   #$006c,menu_selector_y          
                                BLE.W   set_loader_bright                
                                BRA.W   set_main_menu_params             



                ; ----------------------- do disk 3 menu actions ---------------------
                ; called from main 'do_menu_action' when the menu is displayed.
                ; From this menu, you can load music, or return to the main menu
                ;
                ;               Mental Obstacle
                ;               Blade Runner
                ;               Natural Reality
                ;               Obliteration Fin
                ;               Skyriders
                ;               Zero Gravity
                ;               Break Through
                ;               Summer In Sweden
                ;               Never To Much
                ;               Return to Main Menu
                ; 
do_disk_3_menu_actions
                                CMP.W   #$002c,menu_selector_y          
                                BLE.W   set_loader_mental_obstacle       
                                CMP.W   #$0034,menu_selector_y          
                                BLE.W   set_loader_blade_runner          
                                CMP.W   #$003c,menu_selector_y          
                                BLE.W   set_loader_natural_reality       
                                CMP.W   #$0044,menu_selector_y          
                                BLE.W   set_loader_obliteration_fin      
                                CMP.W   #$004c,menu_selector_y          
                                BLE.W   set_loader_skyriders             
                                CMP.W   #$0054,menu_selector_y          
                                BLE.W   set_loader_zero_gravity          
                                CMP.W   #$005c,menu_selector_y          
                                BLE.W   set_loader_break_through         
                                CMP.W   #$0064,menu_selector_y          
                                BLE.W   set_loader_summer_in_sweden      
                                CMP.W   #$006c,menu_selector_y          
                                BLE.W   set_loader_never_to_much         
                                BRA.W   set_main_menu_params             



                ; ----------------------- do greetings 1 menu actions ---------------------
                ; called from main 'do_menu_action' when the menu is displayed.
                ; From this menu, you can load music, or return to the main menu
                ;
                ;               More Greetz
                ;               Return to Main Menu
                ;
do_greetings_1_menu_actions     ; original address L00020E1C
                                CMP.W   #$006c,menu_selector_y    
                                BLE.W   set_greetz_2_menu_params   
                                BRA.W   set_main_menu_params       






                ; ---------------------- set main menu params ------------------------
                ; set the parameters necessary for the display of the 'main menu'
                ;
set_main_menu_params    ; original address L0002124E
                                BSET.B  #MENU_DISP_FADE_OUT,menu_display_status_bits    ; L000203AA
                                MOVE.W  #$0020,menu_selector_min_y                      ; L00020884
                                MOVE.W  #$0050,menu_selector_max_y                      ; L00020886
                                MOVE.W  #MENU_IDX_main_menu,menu_ptr_index              ; L000203AC
                                MOVE.B  #$6c,left_sprite_hpos1                          ; L0002088A
                                MOVE.B  #$01,left_sprite_hpos2                          ; L0002088B
                                MOVE.B  #$a9,right_sprite_hpos1                         ; L0002088C
                                MOVE.B  #$01,right_sprite_hpos2                         ; L0002088D
                                RTS 



                ; ---------------------- set disk 1 menu params ------------------------
                ; set the parameters necessary for the display of the 'disk 1 menu'
                ;
set_disk_1_menu_params    ; original address L00020990
                                BSET.B  #MENU_DISP_FADE_OUT,menu_display_status_bits    ; L000203AA
                                MOVE.W  #$0030,menu_selector_min_y                      ; L00020884
                                MOVE.W  #$0058,menu_selector_max_y                      ; L00020886
                                MOVE.W  #MENU_IDX_disk_1_menu,menu_ptr_index            ; L000203AC
                                MOVE.B  #$42,left_sprite_hpos1                          ; L0002088A
                                MOVE.B  #$01,left_sprite_hpos2                          ; L0002088B
                                MOVE.B  #$d6,right_sprite_hpos1                         ; L0002088C
                                MOVE.B  #$01,right_sprite_hpos2                         ; L0002088D
                                RTS 



                ; ---------------------- set disk 2 menu params ------------------------
                ; set the parameters necessary for the display of the 'disk 2 menu'
                ;
set_disk_2_menu_params   ; original address L000209D2
                                BSET.B  #MENU_DISP_FADE_OUT,menu_display_status_bits    ; L000203AA
                                MOVE.W  #$0028,menu_selector_min_y                      ; L00020884
                                MOVE.W  #$0070,menu_selector_max_y                      ; L00020886
                                MOVE.W  #MENU_IDX_disk_2_menu,menu_ptr_index            ; L000203AC
                                MOVE.B  #$42,left_sprite_hpos1                          ; L0002088A
                                MOVE.B  #$01,left_sprite_hpos2                          ; L0002088B
                                MOVE.B  #$d6,right_sprite_hpos1                         ; L0002088C
                                MOVE.B  #$01,right_sprite_hpos2                         ; L0002088D
                                RTS 



                ; ---------------------- set disk 3 menu params ------------------------
                ; set the parameters necessary for the display of the 'disk 3 menu'
                ;
set_disk_3_menu_params  ; original address L00020A14
                                BSET.B  #MENU_DISP_FADE_OUT,menu_display_status_bits    ; L000203AA
                                MOVE.W  #$0028,menu_selector_min_y                      ; L00020884
                                MOVE.W  #$0070,menu_selector_max_y                      ; L00020886
                                MOVE.W  #MENU_IDX_disk_3_menu,menu_ptr_index            ; L000203AC
                                MOVE.B  #$42,left_sprite_hpos1                          ; L0002088A
                                MOVE.B  #$01,left_sprite_hpos2                          ; L0002088B
                                MOVE.B  #$d6,right_sprite_hpos1                         ; L0002088C
                                MOVE.B  #$01,right_sprite_hpos2                         ; L0002088D
                                RTS 



                ; ---------------------- set credits menu params ------------------------
                ; set the parameters necessary for the display of the 'credits menu'
                ;
set_credits_menu_params ; original address L00020A56
                                BSET.B  #MENU_DISP_FADE_OUT,menu_display_status_bits    ; L000203AA
                                MOVE.W  #$0070,menu_selector_min_y                      ; L00020884
                                MOVE.W  #$0070,menu_selector_max_y                      ; L00020886
                                MOVE.W  #MENU_IDX_credits_menu,menu_ptr_index           ; L000203AC
                                MOVE.B  #$42,left_sprite_hpos1                          ; L0002088A
                                MOVE.B  #$01,left_sprite_hpos2                          ; L0002088B
                                MOVE.B  #$d6,right_sprite_hpos1                         ; L0002088C
                                MOVE.B  #$01,right_sprite_hpos2                         ; L0002088D
                                RTS 



                ; ---------------------- set greetings 1 menu params ------------------------
                ; set the parameters necessary for the display of the 'greetings 1 menu'
                ;
set_greetz_1_menu_params ; original address L00020A98
                                BSET.B  #MENU_DISP_FADE_OUT,menu_display_status_bits    ; L000203AA
                                MOVE.W  #$0068,menu_selector_min_y                      ; L00020884
                                MOVE.W  #$0070,menu_selector_max_y                      ; L00020886
                                MOVE.W  #MENU_IDX_greetings_1_menu,menu_ptr_index       ; L000203AC
                                MOVE.B  #$42,left_sprite_hpos1                          ; L0002088A
                                MOVE.B  #$01,left_sprite_hpos2                          ; L0002088B
                                MOVE.B  #$d6,right_sprite_hpos1                         ; L0002088C
                                MOVE.B  #$01,right_sprite_hpos2                         ; L0002088D
                                RTS 



                ; ---------------------- set greetings 2 menu params ------------------------
                ; set the parameters necessary for the display of the 'greetings 2 menu'
                ;
set_greetz_2_menu_params ; original address L00020ADA
                                BSET.B  #MENU_DISP_FADE_OUT,menu_display_status_bits    ; L000203AA
                                MOVE.W  #$0070,menu_selector_min_y                      ; L00020884
                                MOVE.W  #$0070,menu_selector_max_y                      ; L00020886
                                MOVE.W  #MENU_IDX_greetings_2_menu,menu_ptr_index       ; L000203AC
                                MOVE.B  #$42,left_sprite_hpos1                          ; L0002088A
                                MOVE.B  #$01,left_sprite_hpos2                          ; L0002088B
                                MOVE.B  #$d6,right_sprite_hpos1                         ; L0002088C
                                MOVE.B  #$01,right_sprite_hpos2                         ; L0002088D
                                RTS 



                ; ---------------------- set addresses 1 menu params ------------------------
                ; set the parameters necessary for the display of the 'addresses 1 menu'
                ;
set_addresses_1_menu_params ; original address L00020B1C
                                BSET.B  #MENU_DISP_FADE_OUT,menu_display_status_bits    ; L000203AA
                                MOVE.W  #$0070,menu_selector_min_y                      ; L00020884
                                MOVE.W  #$0070,menu_selector_max_y                      ; L00020886
                                MOVE.W  #MENU_IDX_addresses_1_menu,menu_ptr_index       ; L000203AC
                                MOVE.B  #$42,left_sprite_hpos1                          ; L0002088A
                                MOVE.B  #$01,left_sprite_hpos2                          ; L0002088B
                                MOVE.B  #$d6,right_sprite_hpos1                         ; L0002088C
                                MOVE.B  #$01,right_sprite_hpos2                         ; L0002088D
                                RTS 



                ; ---------------------- set addresses 2 menu params ------------------------
                ; set the parameters necessary for the display of the 'addresses 2 menu'
                ;
set_addresses_2_menu_params ; original address L00020B5E
                                BSET.B  #MENU_DISP_FADE_OUT,menu_display_status_bits    ; L000203AA
                                MOVE.W  #$0070,menu_selector_min_y                      ; L00020884
                                MOVE.W  #$0070,menu_selector_max_y                      ; L00020886
                                MOVE.W  #MENU_IDX_addresses_2_menu,menu_ptr_index       ; L000203AC
                                MOVE.B  #$42,left_sprite_hpos1                          ; L0002088A
                                MOVE.B  #$01,left_sprite_hpos2                          ; L0002088B
                                MOVE.B  #$d6,right_sprite_hpos1                         ; L0002088C
                                MOVE.B  #$01,right_sprite_hpos2                         ; L0002088D
                                RTS 



                ; ---------------------- set addresses 3 menu params ------------------------
                ; set the parameters necessary for the display of the 'addresses 3 menu'
                ;
set_addresses_3_menu_params ; original address L00020BA0
                                BSET.B  #MENU_DISP_FADE_OUT,menu_display_status_bits    ; L000203AA
                                MOVE.W  #$0070,menu_selector_min_y                      ; L00020884
                                MOVE.W  #$0070,menu_selector_max_y                      ; L00020886
                                MOVE.W  #MENU_IDX_addresses_3_menu,menu_ptr_index       ; L000203AC
                                MOVE.B  #$42,left_sprite_hpos1                          ; L0002088A
                                MOVE.B  #$01,left_sprite_hpos2                          ; L0002088B
                                MOVE.B  #$d6,right_sprite_hpos1                         ; L0002088C
                                MOVE.B  #$01,right_sprite_hpos2                         ; L0002088D
                                RTS 



                ; ---------------------- set addresses 4 menu params ------------------------
                ; set the parameters necessary for the display of the 'addresses 4 menu'
                ;
set_addresses_4_menu_params ; original address L00020BE2
                                BSET.B  #MENU_DISP_FADE_OUT,menu_display_status_bits    ; L000203AA
                                MOVE.W  #$0070,menu_selector_min_y                      ; L00020884
                                MOVE.W  #$0070,menu_selector_max_y                      ; L00020886
                                MOVE.W  #MENU_IDX_addresses_4_menu,menu_ptr_index       ; L000203AC
                                MOVE.B  #$42,left_sprite_hpos1                          ; L0002088A
                                MOVE.B  #$01,left_sprite_hpos2                          ; L0002088B
                                MOVE.B  #$d6,right_sprite_hpos1                         ; L0002088C
                                MOVE.B  #$01,right_sprite_hpos2                         ; L0002088D
                                RTS 



                ; ---------------------- set addresses 5 menu params ------------------------
                ; set the parameters necessary for the display of the 'addresses 5 menu'
                ;
set_addresses_5_menu_params ; original address L00020C24
                                BSET.B  #MENU_DISP_FADE_OUT,menu_display_status_bits    ; L000203AA
                                MOVE.W  #$0070,menu_selector_min_y                      ; L00020884
                                MOVE.W  #$0070,menu_selector_max_y                      ; L00020886
                                MOVE.W  #MENU_IDX_addresses_5_menu,menu_ptr_index       ; L000203AC
                                MOVE.B  #$42,left_sprite_hpos1                          ; L0002088A
                                MOVE.B  #$01,left_sprite_hpos2                          ; L0002088B
                                MOVE.B  #$d6,right_sprite_hpos1                         ; L0002088C
                                MOVE.B  #$01,right_sprite_hpos2                         ; L0002088D
                                RTS 



                ; ---------------------- set addresses 6 menu params ------------------------
                ; set the parameters necessary for the display of the 'addresses 6 menu'
                ;
set_addresses_6_menu_params ; original address L00020C66
                                BSET.B  #MENU_DISP_FADE_OUT,menu_display_status_bits    ; L000203AA
                                MOVE.W  #$0070,menu_selector_min_y                      ; L00020884
                                MOVE.W  #$0070,menu_selector_max_y                      ; L00020886
                                MOVE.W  #MENU_IDX_addresses_6_menu,menu_ptr_index       ; L000203AC
                                MOVE.B  #$42,left_sprite_hpos1                          ; L0002088A
                                MOVE.B  #$01,left_sprite_hpos2                          ; L0002088B
                                MOVE.B  #$d6,right_sprite_hpos1                         ; L0002088C
                                MOVE.B  #$01,right_sprite_hpos2                         ; L0002088D
                                RTS 



                ; ---------------------- set pd message menu params ------------------------
                ; set the parameters necessary for the display of the 'pd message menu'
                ;
set_pd_message_menu_params ; original address L00020CA8
                                BSET.B  #MENU_DISP_FADE_OUT,menu_display_status_bits    ; L000203AA
                                MOVE.W  #$0078,menu_selector_min_y                      ; L00020884
                                MOVE.W  #$0078,menu_selector_max_y                      ; L00020886
                                MOVE.W  #MENU_IDX_pd_message_menu,menu_ptr_index        ; L000203AC 
                                MOVE.B  #$42,left_sprite_hpos1                          ; L0002088A
                                MOVE.B  #$01,left_sprite_hpos2                          ; L0002088B
                                MOVE.B  #$d6,right_sprite_hpos1                         ; L0002088C
                                MOVE.B  #$01,right_sprite_hpos2                         ; L0002088D
                                RTS 





                ; -------------------- load music: jarresque -------------------
                ; disk number:  $01
                ; start track:  $8e
                ; no of tracks: $11
set_loader_jarresque    ; original address L00020E2C
                                BSET.B  #LOAD_MODULE,loader_status_bits         
                                MOVE.W  #$008e,loader_start_track               
                                MOVE.W  #$0011,loader_number_of_tracks          
                                MOVE.L  #LOAD_BUFFER,loader_dest_buffer          
                                MOVE.L  #$00000001,loader_disk_number
                                RTS 


                ; ------------------- load music: the fly --------------------
                ; disk number:  $01
                ; start track:  $5c
                ; no of tracks: $15
set_loader_the_fly      ; original address L00020E5A
                                BSET.B  #LOAD_MODULE,loader_status_bits         
                                MOVE.W  #$005c,loader_start_track               
                                MOVE.W  #$0015,loader_number_of_tracks          
                                MOVE.L  #LOAD_BUFFER,loader_dest_buffer         
                                MOVE.L  #$00000001,loader_disk_number           
                                RTS 


                ; ------------------- load music: stratospheric city --------------------
                ; disk number:  $01
                ; start track:  $3b
                ; no of tracks: $1f
set_loader_stratospheric_city; original address L00020E88
                                BSET.B  #LOAD_MODULE,loader_status_bits
                                MOVE.W  #$003b,loader_start_track      
                                MOVE.W  #$001f,loader_number_of_tracks 
                                MOVE.L  #LOAD_BUFFER,loader_dest_buffer
                                MOVE.L  #$00000001,loader_disk_number  
                                RTS 


                ; ------------------- load music: float --------------------
                ; disk number:  $01
                ; start track:  $73
                ; no of tracks: $19
set_loader_float        ; original address L00020EB6
                                BSET.B  #LOAD_MODULE,loader_status_bits 
                                MOVE.W  #$0073,loader_start_track       
                                MOVE.W  #$0019,loader_number_of_tracks  
                                MOVE.L  #LOAD_BUFFER,loader_dest_buffer 
                                MOVE.L  #$00000001,loader_disk_number   
                                RTS 


                ; ------------------- load music: flight-sleepy mix --------------------
                ; disk number:  $01
                ; start track:  $1b
                ; no of tracks: $1e
set_loader_flight_sleepy_mix ; original address L00020EE4
                                BSET.B  #LOAD_MODULE,loader_status_bits 
                                MOVE.W  #$001b,loader_start_track       
                                MOVE.W  #$001e,loader_number_of_tracks  
                                MOVE.L  #LOAD_BUFFER,loader_dest_buffer 
                                MOVE.L  #$00000001,loader_disk_number    
                                RTS 


                ; ------------------- load music: bright --------------------
                ; disk number:  $02
                ; start track:  $01
                ; no of tracks: $09
set_loader_bright       ; original address L00020F12
                                BSET.B  #LOAD_MODULE,loader_status_bits 
                                MOVE.W  #$0001,loader_start_track       
                                MOVE.W  #$0009,loader_number_of_tracks  
                                MOVE.L  #LOAD_BUFFER,loader_dest_buffer 
                                MOVE.L  #$00000002,loader_disk_number   
                                RTS 


                ; ------------------- load music: love your money --------------------
                ; disk number:  $02
                ; start track:  $7e
                ; no of tracks: $0e
set_loader_love_your_money      ; original address L00020F40
                                BSET.B  #LOAD_MODULE,loader_status_bits
                                MOVE.W  #$007e,loader_start_track      
                                MOVE.W  #$000e,loader_number_of_tracks 
                                MOVE.L  #LOAD_BUFFER,loader_dest_buffer
                                MOVE.L  #$00000002,loader_disk_number   
                                RTS 


                ; ------------------- load music: cosmic how much --------------------
                ; disk number:  $02
                ; start track:  $70
                ; no of tracks: $0c
set_loader_cosmic_how_much      ; original address L00020F6E
                                BSET.B  #LOAD_MODULE,loader_status_bits
                                MOVE.W  #$0070,loader_start_track      
                                MOVE.W  #$000c,loader_number_of_tracks 
                                MOVE.L  #LOAD_BUFFER,loader_dest_buffer
                                MOVE.L  #$00000002,loader_disk_number  
                                RTS 


                ; ------------------- load music: this is not a love song --------------------
                ; disk number:  $02
                ; start track:  $0c
                ; no of tracks: $0d
set_loader_not_a_love_song      ; original address L00020F9C
                                BSET.B  #LOAD_MODULE,loader_status_bits
                                MOVE.W  #$000c,loader_start_track      
                                MOVE.W  #$000d,loader_number_of_tracks 
                                MOVE.L  #LOAD_BUFFER,loader_dest_buffer
                                MOVE.L  #$00000002,loader_disk_number   
                                RTS 


                ; ------------------- load music: eat the ballbearing --------------------
                ; disk number:  $02
                ; start track:  $55
                ; no of tracks: $19
set_loader_eat_the_ballbearing ; original address L00020FCA
                                BSET.B  #LOAD_MODULE,loader_status_bits
                                MOVE.W  #$0055,loader_start_track      
                                MOVE.W  #$0019,loader_number_of_tracks 
                                MOVE.L  #LOAD_BUFFER,loader_dest_buffer
                                MOVE.L  #$00000002,loader_disk_number  
                                RTS 


                ; ------------------- load music: sound of silence --------------------
                ; disk number:  $02
                ; start track:  $40
                ; no of tracks: $13
set_loader_sound_of_silence ; orignal address L00020FF8
                                BSET.B  #LOAD_MODULE,loader_status_bits
                                MOVE.W  #$0040,loader_start_track      
                                MOVE.W  #$0013,loader_number_of_tracks 
                                MOVE.L  #LOAD_BUFFER,loader_dest_buffer
                                MOVE.L  #$00000002,loader_disk_number  
                                RTS 


                ; ------------------- load music: retouche --------------------
                ; disk number:  $02
                ; start track:  $1b
                ; no of tracks: $10
set_loader_retouche     ; original address L00021026
                                BSET.B  #LOAD_MODULE,loader_status_bits
                                MOVE.W  #$001b,loader_start_track      
                                MOVE.W  #$0010,loader_number_of_tracks 
                                MOVE.L  #LOAD_BUFFER,loader_dest_buffer
                                MOVE.L  #$00000002,loader_disk_number  
                                RTS 


                ; ------------------- load music: techwar --------------------
                ; disk number:  $02
                ; start track:  $2d
                ; no of tracks: $11
set_loader_techwar      ; original address L00021054
                                BSET.B  #LOAD_MODULE,loader_status_bits
                                MOVE.W  #$002d,loader_start_track      
                                MOVE.W  #$0011,loader_number_of_tracks 
                                MOVE.L  #LOAD_BUFFER,loader_dest_buffer
                                MOVE.L  #$00000002,loader_disk_number  
                                RTS 


                ; ------------------- load music: shaft --------------------
                ; disk number:  $02
                ; start track:  $8e
                ; no of tracks: $11
set_loader_shaft        ; original address L00021082
                                BSET.B  #LOAD_MODULE,loader_status_bits
                                MOVE.W  #$008e,loader_start_track      
                                MOVE.W  #$0011,loader_number_of_tracks 
                                MOVE.L  #LOAD_BUFFER,loader_dest_buffer
                                MOVE.L  #$00000002,loader_disk_number  
                                RTS 


                ; ------------------- load music: mental obstacle --------------------
                ; disk number:  $03
                ; start track:  $8d
                ; no of tracks: $12
set_loader_mental_obstacle      ; original address L000210B0
                                BSET.B  #LOAD_MODULE,loader_status_bits
                                MOVE.W  #$008d,loader_start_track      
                                MOVE.W  #$0012,loader_number_of_tracks 
                                MOVE.L  #LOAD_BUFFER,loader_dest_buffer
                                MOVE.L  #$00000003,loader_disk_number  
                                RTS 


                ; ------------------- load music: blade runner --------------------
                ; disk number:  $03
                ; start track:  $02
                ; no of tracks: $11
set_loader_blade_runner ; original address L000210DE
                                BSET.B  #LOAD_MODULE,loader_status_bits
                                MOVE.W  #$0002,loader_start_track      
                                MOVE.W  #$0011,loader_number_of_tracks 
                                MOVE.L  #LOAD_BUFFER,loader_dest_buffer
                                MOVE.L  #$00000003,loader_disk_number  
                                RTS 


                ; ------------------- load music: natural reality --------------------
                ; disk number:  $03
                ; start track:  $7d
                ; no of tracks: $0e
set_loader_natural_reality      ; original address L0002110C
                                BSET.B  #LOAD_MODULE,loader_status_bits
                                MOVE.W  #$007d,loader_start_track      
                                MOVE.W  #$000e,loader_number_of_tracks 
                                MOVE.L  #LOAD_BUFFER,loader_dest_buffer
                                MOVE.L  #$00000003,loader_disk_number  
                                RTS 


                ; ------------------- load music: obliteration fin --------------------
                ; disk number:  $03
                ; start track:  $6f
                ; no of tracks: $0c
set_loader_obliteration_fin ; original address L0002113A
                                BSET.B  #LOAD_MODULE,loader_status_bits
                                MOVE.W  #$006f,loader_start_track      
                                MOVE.W  #$000c,loader_number_of_tracks 
                                MOVE.L  #LOAD_BUFFER,loader_dest_buffer
                                MOVE.L  #$00000003,loader_disk_number  
                                RTS 


                ; ------------------- load music: obliteration fin --------------------
                ; disk number:  $03
                ; start track:  $52
                ; no of tracks: $1b
set_loader_skyriders    ; original address L00021168
                                BSET.B  #LOAD_MODULE,loader_status_bits
                                MOVE.W  #$0052,loader_start_track      
                                MOVE.W  #$001b,loader_number_of_tracks 
                                MOVE.L  #LOAD_BUFFER,loader_dest_buffer
                                MOVE.L  #$00000003,loader_disk_number  
                                RTS 


                ; ------------------- load music: zero gravity --------------------
                ; disk number:  $03
                ; start track:  $43
                ; no of tracks: $0d
set_loader_zero_gravity ; original address L00021196
                                BSET.B  #LOAD_MODULE,loader_status_bits
                                MOVE.W  #$0043,loader_start_track      
                                MOVE.W  #$000d,loader_number_of_tracks 
                                MOVE.L  #LOAD_BUFFER,loader_dest_buffer
                                MOVE.L  #$00000003,loader_disk_number  
                                RTS 


                ; ------------------- load music: break through --------------------
                ; disk number:  $03
                ; start track:  $15
                ; no of tracks: $0d
set_loader_break_through        ; original address L000211C4
                                BSET.B  #LOAD_MODULE,loader_status_bits
                                MOVE.W  #$0015,loader_start_track      
                                MOVE.W  #$000d,loader_number_of_tracks 
                                MOVE.L  #LOAD_BUFFER,loader_dest_buffer
                                MOVE.L  #$00000003,loader_disk_number  
                                RTS 


                ; ------------------- load music: summer in sweden --------------------
                ; disk number:  $03
                ; start track:  $35
                ; no of tracks: $0c
set_loader_summer_in_sweden     ; original address L000211F2
                                BSET.B  #LOAD_MODULE,loader_status_bits
                                MOVE.W  #$0035,loader_start_track      
                                MOVE.W  #$000c,loader_number_of_tracks 
                                MOVE.L  #LOAD_BUFFER,loader_dest_buffer
                                MOVE.L  #$00000003,loader_disk_number  
                                RTS 


                ; ------------------- load music: never to much --------------------
                ; disk number:  $03
                ; start track:  $24
                ; no of tracks: $0f
set_loader_never_to_much        ; original address L00021220
                                BSET.B  #LOAD_MODULE,loader_status_bits
                                MOVE.W  #$0024,loader_start_track      
                                MOVE.W  #$000f,loader_number_of_tracks 
                                MOVE.L  #LOAD_BUFFER,loader_dest_buffer
                                MOVE.L  #$00000003,loader_disk_number  
                                RTS 



        ; *****************************************************************************
        ; ***                    END OF MENU ACTION PROCESSING                      ***
        ; *****************************************************************************








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


draw_logo_outline       ; original address L00021352
                                MOVE.W  #$0028,D4
                                LEA.L   logo_line_table,A5
                                LEA.L   points_2d,a4
                                MOVE.W  number_of_lines,D7
                                LEA.L   vector_logo_buffer_ptr,a2
.do_line
                                MOVEM.W (A5)+,D5-D6                     ; 2d point indexes
                                LEA.L   $00(A4,D5.W),A3
                                MOVEM.W (A3)+,D0-D1                     ; x1,y1
                                LEA.L   $00(A4,D6.W),A3
                                MOVEM.W (A3)+,D2-D3                     ; x2,y2
                                MOVEA.L (A2),A0                         ; a0 = draw buffer
                                BSR.W   line_draw
                                DBF.W   D7,.do_line     
                                RTS 




                ; ------------------------ calculate 3d perspective ------------------------
                ; Takes in a list of 3d (x,y,z) co-ordinates and applied 3d perspective.
                ; Outputs a list of 2d (x,y) co-ordintates for later line drawing stage.
                ;
calc_3d_perspective     ; original address L0002138E
                                MOVE.W  number_of_vertices,d7                   ; L00039D1E,D7
                                LEA.L   rotated_vertices,a2                     ; L00039EBE,A2
                                LEA.L   points_2d,a1                            ; L0003A2A6,A1
                                MOVE.L  #$00000000,D3                           ; divide by zero check value
                                MOVE.W  #$00a0,D4                               ; 160 = x centre of screen pixel value (320 wide)
                                MOVE.W  #$0046,D5                               ; 70 = y - centre of screen pixel value (140 high)
                                MOVE.L  #$00000008,D6                           ; multiply values by 512 before dividing to gain better precision
.do_perspective_loop
                                MOVEM.W (A2)+,D0-D2                             ; d0,d1,d2 = x,y,z co-ord 
                                CMP.W   D3,D2                                   ; check for z = 0 (divide by zero)
                                BNE.B   .do_perspective_calc                    ; if z != 0, then do perspective calc
.do_is_divide_by_zero                                                           ; else set point to centre screen
                                MOVE.L  #$00000000,D0                           ;    x = 0
                                MOVE.L  #$00000000,D1                           ;    y = 0
                                MOVE.L  #$00000000,D2                           ;    z = 0
                                BRA.B   .add_centre_origin 
.do_perspective_calc
                                EXT.L   D1                                      ; x = sign extend to 32 bits
                                EXT.L   D2                                      ; y = sign extend to 32 bits
                                EXT.L   D0                                      ; z = sign extend to 32 bits
                                ASL.W   D6,D0                                   ; multiply x by 512
                                ASL.W   D6,D1                                   ; multiply y by 512
                                DIVS.W  D2,D0                                   ; divide x by z
                                DIVS.W  D2,D1                                   ; divide y by z
.add_centre_origin
                                ADD.W   D4,D0                                   ; add centre screen to x
                                ADD.W   D5,D1                                   ; add centre screen to y
                                MOVE.W  D0,(A1)+                                ; store 2d x value
                                MOVE.W  D1,(A1)+                                ; store 2d y value
                                DBF.W   D7,.do_perspective_loop                 
                                RTS 


                ; ------------------------ calculate logo lighting -------------------------
                ; use the angle of rotation (which is already an index to sin/cos tables)
                ; to look up the colour based on the rotation value.
                ; Sets the colour from the table into the copper list for display.
                ;
calc_logo_lighting    ; original address L000213D8
                                MOVE.W  angle_of_rotation_x2(PC),D0
                                LEA.L   spinning_logo_colour_table,a0
                                MOVE.W  $00(A0,D0.W),copper_vector_logo_colour
                                RTS 

angle_of_rotation_x2    ; original address L000213EC
                                dc.w    $0000           ; angle of rotation * 2 - word index




                ; ------------------------------ rotate logo y axis ----------------------------
                ; This code rotates the logo around the Y axis, using the following formulas
                ;       x = x * cos(angle) + z + sin(angle)
                ;       y = y
                ;       z = -x * sin(angle) + z * cos(angle) 
                ;               (i didn't do the negative x so it rotates in the opposite direction,
                ;                slightly faster calculation)
                ;
                ; The code uses sin and cosine tables precalculated to make things simple for
                ; m/c code (also faster)
                ;
                ; The sin and cosine tables are multipled by (x) to enable use with integer
                ; arithmetic.
                ;
spin_logo       ; original address L000213EE
                                ADD.W   #$00000004,angle_of_rotation_x2         ; rotation value * 2 (used directly as index to word lookup tables)
                                CMP.W   #$02ce,angle_of_rotation_x2             ; 718/2 = 359 (degrees)
                                BLE.B   .do_rotation  
                                MOVE.W  #$0000,angle_of_rotation_x2             ; reset angle of rotation to 0
.do_rotation
                                LEA.L   logo_vertices,A0
                                LEA.L   sin_table,A1
                                LEA.L   cosine_table,A2
                                LEA.L   rotated_vertices,a3
                                MOVE.W  number_of_vertices,d7
                                MOVE.W  angle_of_rotation_x2(pc),d6
                                MOVE.L  #$00000008,D3                           ; divide scaled values by 256
.rotate_vertex
                                MOVEM.W (A0)+,D0-D2                             ; logo vertex (x,y,z)
                        ; x = x * cos(angle) + z + sin(angle)
                                MOVE.W  D0,D4
                                MOVE.W  D2,D5
                                MULS.W  $00(A2,D6.W),D4                         ; d4 = cos(x)
                                MULS.W  $00(A1,D6.W),D5                         ; d5 = sin(z)
                                SUB.L   D5,D4                                   ; d4 = cos(x) - sin(z)
                                ASR.L   D3,D4                                   ; scale value by dividing by 256
.store_x
                                MOVE.W  D4,(A3)                                 ; store rotated x
                        ; z = -x * sin(angle) + z * cos(angle)
                                MOVE.W  D0,D4
                                MOVE.W  D2,D5
                                MULS.W  $00(A1,D6.W),D4                         ; d4 = sin(x)
                                MULS.W  $00(A2,D6.W),D5                         ; d5 = cos(z)
                                ADD.L   D5,D4                                   ; d4 = x * sin(angle) + z * cos(angle)
                                ASR.L   D3,D4                                   ; scale value by dividing by 256
.store_yz
                                MOVEM.W D1/D4,$0002(A3)                         ; store y & z
                        ; set z-value into the scene (not part of rotation)
.set_z_distance         ; just to set the logo back into the scene/view a little
                                ADD.W   #$01f8,$0004(A3)                        ; setting z value to set ddistance into the scene
.do_next_vertex        
                                ADDA.L  #$00000006,A3                           ; increment 
                                DBF.W   D7,.rotate_vertex 
                                RTS 




                ; -------------------------- line draw -----------------------------
                ; Line draw routine, suitable for blitter fill.
                ;
line_draw       ; original address L00021464
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




        ; ----------------------- text scroller ---------------------
        ; This is a 4 bitplane (16 colour), 32x31 font scroller.
        ; It uses the hardware scroll and a double buffered,
        ; horizontal buffer twice as wide as the screen.
        ; A trade off between memory usage and blitter usage.
        ; i It's quicker to do a harware scroll, but then you
        ; have to flip back to a copy once you've scrolled the
        ; width of the screen. So required twice the display memory.
        ;
        ; Source GFX = 40 bytes wide
        ; Each character is 31 pixels high
        ; each line starts at a byte offset of 1240 bytes
        ;
        ; Font Layout in source GFX
        ; 10 chars per line,
        ; 32 pixels wide = (320 pixels wide)
        ;
        ; ,-./012345    - 0
        ; 6789:;<=>?    - 1240
        ; @ABCDEFGHI    - 2480
        ; JKLMNOPQRS    - 3720
        ; TUVWXYZ       - 4960
        ;               - 6200 - per bitplane. ($1838)
        ; Each plane is actually 6400 bytes ($1900)
        ; Some Spare bytes at the bottom of each plane (200 bytes = 5 raster lines)
        ;

scroller_buffer_counter         ; original address L0002152A
                                dc.w    $0000                                   ; bitplane byte offset counter (scroll text display buffers)
scroller_character_counter      ; original address L0002152C
                                dc.w    $0000                                   ; character words scrolled counter (2 words = 32 pixels scrolled)


text_scroller   ; original address L0002152E
                                BSR.W   scroller_soft_scroll                    ; hardware scroll for 32 pixels          
                                BSR.W   scroller_next_character                 ; blit next char and do buffering
                                RTS 

scroller_soft_scroll            CMP.W   #$0000,copper_scroller_softscroll 
                                BEQ.B   scroller_coarse_scroll            
                                SUB.W   #$0022,copper_scroller_softscroll       ; 2 pixel hardware scroll
                                RTS 

scroller_coarse_scroll
                                CMP.W   #$002e,scroller_buffer_counter          ; compare 46 bytes scrolled.
                                BEQ.B   .reset_scroller_dbl_buffer              ; yes, then do double buffer swap etc
.do_increment_bitplane_ptrs     ; scroll using hardware                         ; no, just increment bitplane ptrs & reset hardware scroll value
                                ADD.W   #$0002,scrolltext_bpl1ptl               ;    increment bpl1 by 16 pixels (2 bytes)               
                                ADD.W   #$0002,scrolltext_bpl2ptl               ;    increment bpl2 by 16 pixels (2 bytes) 
                                ADD.W   #$0002,scrolltext_bpl3ptl               ;    increment bpl3 by 16 pixels (2 bytes) 
                                ADD.W   #$0002,scrolltext_bpl4ptl               ;    increment bpl4 by 16 pixels (2 bytes) 
                                MOVE.W  #$00ee,copper_scroller_softscroll       ; reset harware scroll value in copper 
                                ADD.W   #$0002,scroller_buffer_counter          ; increment double buffer byte counter
                                ADD.W   #$0001,scroller_character_counter       ; increment character word scroll counter (2 words per 32 pixel character)
                                RTS 

                ; flip double buffered horizontal display back to start
.reset_scroller_dbl_buffer      ; flip double buffered display - L00021590
                                ADD.W   #$0001,scroller_character_counter
                                MOVE.L  #scroll_text_bpl_0_start+6,d0
                                MOVE.W  D0,scrolltext_bpl1ptl
                                SWAP.W  D0
                                MOVE.W  D0,scrolltext_bpl1pth
                                MOVE.L  #scroll_text_bpl_1_start+6,d0 
                                MOVE.W  D0,scrolltext_bpl2ptl
                                SWAP.W  D0
                                MOVE.W  D0,scrolltext_bpl2pth 
                                MOVE.L  #scroll_text_bpl_2_start+6,d0
                                MOVE.W  D0,scrolltext_bpl3ptl 
                                SWAP.W  D0
                                MOVE.W  D0,scrolltext_bpl3pth  
                                MOVE.L  #scroll_text_bpl_3_start+6,d0  
                                MOVE.W  D0,scrolltext_bpl4ptl 
                                SWAP.W  D0
                                MOVE.W  D0,scrolltext_bpl4pth  
                                MOVE.W  #$00ee,copper_scroller_softscroll       ; reset soft scroll in copper 
                                MOVE.W  #$0000,scroller_buffer_counter          ; reset character hard scroll value (2 words per character) counter
                                RTS 


                        ; check if a new character has scrolled on to right of the display
scroller_next_character ; original address L000215FA
                                CMP.W   #$0002,scroller_character_counter       ; has a 32 pixel character scrolled by yet?
                                BEQ.S   .do_scroll_character                    ; exit_scroll_nexT_character              
                                RTS                                             ; no, no need to blit a character yet, so exit
.do_scroll_character
                                MOVE.L  #$00000000,D7
.blit_wait_1                    BTST.B  #14-8,DMACONR(A6)                       ; blit wait (hi byte test)
                                BNE.B   .blit_wait_1 
                                MOVE.L  #$ffffffff,BLTAFWM(A6)                  ; 1st and last word masks
                                MOVE.L  #$09f00000,BLTCON0(A6)
                                MOVE.W  #$0024,BLTAMOD(A6)                      ; 36 byte modulo (4 byte blit) 40 byte wide source gfx
                                MOVE.W  #$0054,BLTDMOD(A6)                      ; 84 byte modulo (4 byte blit) 88 byte scroll buffer
.get_scroll_character   ; get character from scroll text
                                MOVEA.L scroll_text_ptr,a0
                                MOVE.B  (A0)+,D7                        ; d7 = scroll character
                                MOVE.L  A0,scroll_text_ptr
.handle_scroll_char     ; check for special character (or map offset to source gfx)
                                CMP.B   #$ff,D7                         ; end of scroll
                                BEQ.B   .restart_scroll_text     
                                CMP.B   #$0a,D7                         ; carriage return = '-'
                                BEQ.B   .set_space_character             
                                CMP.B   #$20,D7                         ; space character
                                BEQ.B   .set_space_character             
                                CMP.B   #$54,D7                         ; 'T'
                                BPL.B   .add_gfx_offset_1                
                                CMP.B   #$4a,D7                         ; 'J'
                                BPL.B   .add_gfx_offset_2 
                                CMP.B   #$40,D7                         ; '@'
                                BPL.B   .add_gfx_offset_3       
                                CMP.B   #$36,D7                         ; '6'
                                BPL.W   .add_gfx_offset_4
                                BRA.W   .do_blit_character

                                ; Font Layout in source GFX
                                ; 10 chars per line,
                                ; 32 pixels wide = (320 pixels wide)
                                ;
                                ; ,-./012345
                                ; 6789:;<=>?
                                ; @ABCDEFGHI
                                ; JKLMNOPQRS
                                ; TUVWXYZ

                        ; restart scroll text
.restart_scroll_text            MOVE.L  #scroll_text,scroll_text_ptr    ; L00026D42
                                BRA.B   .get_scroll_character 

                        ; set space source gfx offset
.set_space_character            MOVE.B  #$2d,D7                         ; set '-' character (probably defined as an empty space)
                                BRA.B   .handle_scroll_char 

                        ; 5th line of text offset (source gfx)
.add_gfx_offset_1               ADD.W   #$04d8,D7                       ; add 1240 byte offset into gfx 
                                BRA.B   .do_blit_character 

                        ; 4th line of text offset (source gfx)
.add_gfx_offset_2               ADD.W   #$03a2,D7                       ; add 930 bytes offset into gfx 
                                BRA.B   .do_blit_character 

                        ; 3rd line of text offset (source gfx)
.add_gfx_offset_3               ADD.W   #$026c,D7                       ; add 620 bytes offset into gfx 
                                BRA.B   .do_blit_character 

                        ; 2nd line of text offset (source gfx)
.add_gfx_offset_4               ADD.W   #$0136,D7                       ; add 310 bytes offset into gfx (310*4 = 1240) - 31 pixel high font

                        ; 1st line of text - no offset (source gfx)
.do_blit_character              SUB.B   #$2c,D7                         ; subtract 44 from char offset (',' character)
                                MULU.W  #$0004,D7                       ; mutiply by 4 to get 32 pixel offset to character.

                        ; do bitplane 1 blits of character
                                LEA.L   scroll_font_gfx,A1
                                LEA.L   scroll_font_gfx,A3
                                ADDA.W  D7,A1                           ; character source gfx ptr
                                ADDA.W  D7,A3                           ; character source gfx ptr
                                LEA.L   scroll_text_bpl_0_start,a0              
                                LEA.L   scroll_text_bpl_0_start,a2   #
                                ; calc source ptr addresses           
                                MOVE.W  scroller_buffer_counter,D0      ; buffer offset in byte for next character
                                ADDA.W  D0,A0
                                ADD.W   #$0030,D0                       ; add 48 - doubd buffer offset
                                ADDA.W  D0,A2
                                ; blit 1st copy of char - bpl1
                                MOVE.L  A1,BLTAPT(A6)
                                MOVE.L  A0,BLTDPT(A6)
                                MOVE.W  #$07c2,BLTSIZE(A6)              ; 2 words wide by 31 pixels high
.blit_wait_2                    BTST.B  #14-8,DMACONR(A6)
                                BNE.B   .blit_wait_2
                                ; blit 2nd copy of char - bpl1 
                                MOVE.L  A3,BLTAPT(A6)
                                MOVE.L  A2,BLTDPT(A6)
                                MOVE.W  #$07c2,BLTSIZE(A6)              ; 2 words wide by 31 pixels high

                        ; do bitplane 2 blits of character
                                LEA.L   scroll_font_gfx,A1
                                LEA.L   scroll_font_gfx,A3
                                ADDA.W  D7,A1                           ; src ptr 1
                                ADDA.W  D7,A3                           ; src ptr 2
                                ADDA.W  #$1900,A1                       ; add bitplane offset (source gfx)
                                ADDA.W  #$1900,A3                       ; add bitplane offset (source gfx)
                                LEA.L   scroll_text_bpl_1_start,a0      ; dest ptr 1
                                LEA.L   scroll_text_bpl_1_start,a2      ; dest ptr 2
                                ; calc source ptr addresses 
                                MOVE.W  scroller_buffer_counter,D0      ; buffer scroll offset for character
                                ADDA.W  D0,A0                           
                                ADD.W   #$0030,D0
                                ADDA.W  D0,A2
                                ; blit 1st copy of char - bpl2
.blit_wait_3                    BTST.B  #14-8,DMACONR(A6)
                                BNE.B   .blit_wait_3 
                                MOVE.L  A1,BLTAPT(A6)
                                MOVE.L  A0,BLTDPT(A6)
                                MOVE.W  #$07c2,BLTSIZE(A6)              ; 2 words wide by 31 pixels high
.blit_wait_4                    BTST.B  #14-8,DMACONR(A6)
                                BNE.B   .blit_wait_4 
                                ; blit 2nd copy of char - bpl2
                                MOVE.L  A3,BLTAPT(A6)
                                MOVE.L  A2,BLTDPT(A6)
                                MOVE.W  #$07c2,BLTSIZE(A6)              ; 2 words wide by 31 pixels high

                        ; do bitplane 3 blits of character
                                LEA.L   scroll_font_gfx,A1
                                LEA.L   scroll_font_gfx,A3
                                ADDA.W  D7,A1
                                ADDA.W  D7,A3
                                ADDA.W  #$3200,A1
                                ADDA.W  #$3200,A3
                                LEA.L   scroll_text_bpl_2_start,a0      ; L0002D0B8,A0
                                LEA.L   scroll_text_bpl_2_start,a2      ; L0002D0B8,A2
                                MOVE.W  scroller_buffer_counter,D0
                                ADDA.W  D0,A0
                                ADD.W   #$0030,D0
                                ADDA.W  D0,A2
.blit_wait_5                    BTST.B  #14-8,DMACONR(A6)
                                BNE.B   .blit_wait_5 
                                MOVE.L  A1,BLTAPT(A6)
                                MOVE.L  A0,BLTDPT(A6)
                                MOVE.W  #$07c2,BLTSIZE(A6)              ; 2 words wide by 31 pixels high
.blit_wait_6                    BTST.B  #14-8,DMACONR(A6)
                                BNE.B   .blit_wait_6 
                                MOVE.L  A3,BLTAPT(A6)
                                MOVE.L  A2,BLTDPT(A6)
                                MOVE.W  #$07c2,BLTSIZE(A6)              ; 2 words wide by 31 pixels high

                        ; do bitplane 4 blits of character
                                LEA.L   scroll_font_gfx,A1
                                LEA.L   scroll_font_gfx,A3
                                ADDA.W  D7,A1
                                ADDA.W  D7,A3
                                ADDA.W  #$4b00,A1
                                ADDA.W  #$4b00,A3
                                LEA.L   scroll_text_bpl_3_start,a0      ; L0002E638,A0
                                LEA.L   scroll_text_bpl_3_start,a2      ; L0002E638,A2
                                MOVE.W  scroller_buffer_counter,D0
                                ADDA.W  D0,A0
                                ADD.W   #$0030,D0
                                ADDA.W  D0,A2
.blit_wait_7                    BTST.B  #$000e,DMACONR(A6)
                                BNE.B   .blit_wait_7 
                                MOVE.L  A1,BLTAPT(A6)
                                MOVE.L  A0,BLTDPT(A6)
                                MOVE.W  #$07c2,BLTSIZE(A6)              ; 2 words wide by 31 pixels high
.blit_wait_8                    BTST.B  #14-8,DMACONR(A6)
                                BNE.B   .blit_wait_8 
                                MOVE.L  A3,BLTAPT(A6)
                                MOVE.L  A2,BLTDPT(A6)
                                MOVE.W  #$07c2,BLTSIZE(A6)              ; 2 words wide by 31 pixels high

.blit_wait_9                    BTST.B  #14-8,DMACONR(A6)
                                BNE.B   .blit_wait_9 
                                MOVE.W  #$0000,scroller_character_counter
                                RTS 






                ; ---------------------- load music -----------------------
                ; mfm track loader.
                ; load a music file from disk, checks the disk number
                ; in the drive and waits for the correct disk.
                ;
        
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
load_music      ; original address L00021814
                                movem.l d0-d7/a0-a6,-(a7)
                                move.l  #$0000CCB0,d0
                                move.l  #$0002A56E,d1
                                move.l  #$00000000,d2
                                lea     LOAD_BUFFER,a0
                                lea     MFM_BUFFER,a1
                                jsr     loader_4489
                                tst.l   d0
                                bne     decode_error
                                movem.l (a7)+,d0-d7/a0-a6
                                rts

                                BSR.W   init_loader             ; L000218A4
                                BRA.W   load_file               ; L00021A3C 
                                RTS 



                ; --------------------- enable drive -----------------------
                ; select drive 0 and start disk motor.
                ;
enable_drive_0  ; original address L0002181E
                                OR.B    #$08,$00bfd100          ; select drive 0
                                AND.B   #$7f,$00bfd100          ; enable disk motor
                                AND.B   #$f7,$00bfd100          ; latch disk motor
wait_dskrdy
                                BTST.B  #$0005,$00bfe001        ; test DSKRDY disk ready signal
                                BNE.B   wait_dskrdy             ; wait for disk ready
                                RTS 



                ; --------------------- drive off -------------------------
                ; switch the drive motor off and deslect drive 0
                ;
drive_off       ; original address L00021842
                                OR.B    #$88,$00bfd100          ; deselect drive and motor
                                AND.B   #$f7,$00bfd100          ; reselect drive 0 - latch the motor off
                                OR.B    #$08,$00bfd100          ; deselect drive 0
                                RTS 



                ; --------------------- read raw track -------------------
                ; read in raw mfm track from the disk.
                ;
read_raw_track  ; original address L0002185C
                                MOVE.L  mfm_track_buffer_ptr,DSKPT(a6)          ; raw mfm disk buffer
                                MOVE.W  #$7f00,ADKCON(A6)                       ; clear disk settings bits
                                MOVE.W  #$9500,ADKCON(A6)                       ; set disk settings, MFM,FAST,WORDSYNC
                                MOVE.W  #$8210,DMACON(A6)                       ; Enable DMA, DMAEN, DISK
                                MOVE.W  #$0000,DSKLEN(A6)                       ; Disable disk DMA, Write, Length
                                MOVE.W  #$9a00,DSKLEN(A6)                       ; Enable disk, DMA, read $1a00 words
                                MOVE.W  #$9a00,DSKLEN(A6)                       ; $1a00 words = 6656 words, 13,312 bytes, 13Kb exactly
wait_DSKBLK                     BTST.B  #$0001,INTREQR+1(A6)                    ; test DSKBLK interrupt
                                BEQ.B   wait_DSKBLK                             ; wait for DSKBLK to complete read.
                                MOVE.W  #$0000,DSKLEN(A6)                       ; Disable disk DMA, Write, Length
                                MOVE.W  #$0002,INTREQ(A6)                       ; Clear DSKBLK interrupt flag
                                MOVE.W  #$0010,DMACON(A6)                       ; Disable Disk DMA
                                RTS 



                ; ------------------- initialise loader ------------------
                ; set interrupts and disk sync.
init_loader     ; original address L000218A4
                                LEA.L   $00dff000,A6
                                MOVE.W  #$7fff,INTREQ(A6)       ; clear raised interrupt bits
                                MOVE.W  #$3fff,INTENA(A6)       ; disable interrupts
                                MOVE.W  #$8020,INTENA(A6)       ; enable copper interrupt
                                MOVE.W  #$4489,$007e(A6)        ; set disk sync
                                RTS 



                ; --------------------- timer delay 2ms ---------------------
                ; create a 2 millisecond delay using the Timer A of CIAB
                ;
timer_delay_2ms ; original address L000218C4
                                MOVE.B  #$00,$00bfde00          ; stop timer A CIAB
                                MOVE.B  #$7f,$00bfdd00          ; clear CIAB ICR
                                MOVE.B  #$00,$00bfd400          ; set timerA Low byte
                                MOVE.B  #$20,$00bfd500          ; set timerA high byte
                                MOVE.B  #$09,$00bfde00          ; start timerA one-shot
wait_timer_a                    BTST.B  #$0000,$00bfdd00        ; test timeA underflow
                                BEQ.B   wait_timer_a            ; wait timerA underflow
                                RTS 



                ; --------------------- heads to track 0 ---------------------
                ; step the drive heads to track 0
heads_to_track_0 ; original address L000218F8
                                BTST.B  #$0004,$00bfe001        ; test track 0 bit
                                BEQ.W   at_track_0              ; L00021920 
                                OR.B    #$03,$00bfd100          ; select drive 0
                                AND.B   #$fe,$00bfd100          ; toggle step heads
                                OR.B    #$01,$00bfd100          ; toggle step heads
                                BSR.B   timer_delay_2ms         ; L000218C4               ; 
                                BRA.B   heads_to_track_0        ; L000218F8 
at_track_0
                                OR.B    #$04,$00bfd100          ; set disk side (lower head)
                                MOVE.W  #$0000,current_track    ; L00021B84
                                RTS 



                ; ---------------------- step heads to track ---------------------
                ; step the heads to the desired track number, selecting the
                ; top/bottom head as required.
                ;
                ; IN:-
                ;       d0.w = track to step to (0 - 160)
step_to_track   ; original address L00021932
                                TST.W   D0
                                BEQ.W   step_to_track_0
                                MOVE.W  current_track,D3
                        ; check already there
                                CMP.W   D3,D0
                                BEQ.W   exit_step_to_track
                        ; get cylinder values (current & desired)
                                MOVE.W  D0,D2
                                LSR.W   #$00000001,D2
                                LSR.W   #$00000001,D3                       
select_head             ; select top/bottom head (top = odd track, bottom = even track)
                                BTST.L  #$0000,D0
                                BNE.W   select_top_head 
select_lower_head
                                OR.B    #$04,$00bfd100                  ; set /SIDE = 1 - lower head (even tracks 0,2,4,6...)
                                BRA.B   step_the_heads_loop
select_top_head
                                AND.B   #$fb,$00bfd100                  ; set /SIDE = 0 - upper head (odd tracks 1,3,5,7...)
step_the_heads_loop
                                CMP.W   D3,D2
                                BEQ.B   exit_step_to_track 
                                BGT.B   step_inwards 
step_outwards
                                MOVE.B  #$02,$00bfd100                  ; set /DIR = 1 - towards track 0 - outwards
                                BSR.W   step_drive_heads
                                BSR.W   timer_delay_2ms 
                                SUB.W   #$0001,D3                       ; decrement current track number
                                BRA.W   step_the_heads_loop
step_inwards
                                AND.B   #$fd,$00bfd100                  ; set /DIR = 0 - towards centre - inwards
                                BSR.W   step_drive_heads
                                BSR.W   timer_delay_2ms
                                ADD.W   #$0001,D3                       ; increment current track number
                                BRA.W   step_the_heads_loop

exit_step_to_track      ; store current track number & exit
                                MOVE.W  D0,current_track
                                RTS 

step_to_track_0         ; short cut step to track 0
                                BSR.W   heads_to_track_0
                                BRA.B   exit_step_to_track



                ; ------------------- step drive heads ----------------------
                ; step the drive heads in the direction already selected.
                ; the /STEP bit must be pulsed to step the heads.
step_drive_heads        ; original address L000219A4
                                OR.B    #$01,$00bfd100                  ; toggle /STEP
                                AND.B   #$fe,$00bfd100                  ; toggle /STEP
                                OR.B    #$01,$00bfd100                  ; toggle /STEP
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

                ; --------------------- decode raw track ----------------------
                ; decodes a full mfm track buffer to the destination memory
                ; buffer passed in address register a4.
                ;
                ; IN:
                ;       a4.l    - dest buffer address
decode_raw_track        ; original address L000219BE
                                MOVEA.l mfm_track_buffer_ptr,a0             ; L00021B80,A0
                                MOVE.W  #$000a,D6
                        ; find sync marks
find_sync                       MOVE.W  (A0)+,D5
                                CMP.W   #$4489,D5
                                BNE.B   find_sync 
                        ; skip remaining sync marks (maybe 2 of them)
                                MOVE.W  (A0),D5
                                CMP.W   #$4489,D5
                                BNE.B   decode_header
                        ; skip second sync mark 
skip_sync                       ADDA.W  #$0002,A0
                        ; decode sector header (56 bytes encoded to 28 bytes decoded)
decode_header                   MOVE.L  (A0)+,D5
                                MOVE.L  (A0)+,D4
                                AND.L   #$55555555,D5
                                AND.L   #$55555555,D4
                                LSL.L   #$00000001,D5
                                OR.L    D4,D5
                                SWAP.W  D5
                                AND.W   #$ff00,D5                       ; mask out format id 
                                CMP.W   #$ff00,D5                       ; check format id = $ff
                                BNE.B   decode_error                             
                                SWAP.W  D5
                                AND.W   #$ff00,D5                       ; mask sector number
                                LSL.W   #$00000001,D5                   ; already multiplyied by 256, so multiply by 2 to get dest buffer index.
                                LEA.L   $00(A4,D5.W),A3                 ; a3 = decode buffer dest address for this sector
                                LEA.L   $0030(A0),A0                    ; skip remaining header bytes
                                MOVE.W  #$007f,D7                       ; decode 128 longs ()
decode_sector_loop              MOVE.L  $0200(A0),D4                    ; get even mfm encoded bits
                                MOVE.L  (A0)+,D5                        ; get edd mfm encoded bits
                                AND.L   #$55555555,D5                   ; remove clock bits
                                AND.L   #$55555555,D4                   ; remove clock bits
                                LSL.L   #$00000001,D5                   ; shift odd data bits
                                OR.L    D4,D5                           ; recombine decoded data bits
                                MOVE.L  D5,(A3)+                        ; store in dest decoded buffer
                                DBF.W   D7,decode_sector_loop
                                DBF.W   D6,find_sync                            ; loop for next sector 
                                RTS 

decode_error    ; original address L00021A30
                                MOVE.B  VHPOSR(A6),$00dff180                    ; change background colour
                                BRA.W   decode_error                            ; loop forever - L00021A30_error



                ; --------------------- load file ---------------------
load_file       ; original address L00021A3C
                                BSR.W   enable_drive_0          ; L0002181E
                                BSR.W   heads_to_track_0        ; L000218F8
try_load_file   ; check correct disk in drive by loading track 0 and testing
                ; disk number loaded in from track data
                                MOVE.W  #$0000,D0               ; track 0
                                MOVE.W  #$0000,D1               ; load 1 track
                                LEA.L   LOAD_BUFFER,A4          ; Load buffer address
                                BSR.W   read_raw_track          ; L0002185C
                                BSR.W   decode_raw_track        ; L000219BE
                                MOVE.L  loader_disk_number,d0          ; required disk number        
                                CMP.L   LOAD_BUFFER+8,D0        ; disk number from inserted disk
                                BEQ.W   correct_disk_in_drive 
                                CMP.L   #$00000001,D0
                                BEQ.W   insert_disk_1           ; display 'insert disk 1'
                                CMP.L   #$00000002,D0
                                BEQ.W   insert_disk_2           ; display 'insert disk 2'

                        ; display 'Insert Disk 3' and wait for disk swap
insert_disk_3           ; original address L00021A7E
                                MOVE.L  #insert_disk_3_message,d0       ; #L00036230,D0
                                MOVE.W  D0,insertdisk_bplptl            ; L00022DE0
                                SWAP.W  D0
                                MOVE.W  D0,insertdisk_bplpth            ; L00022DDC
                                BRA.W   detect_disk_change              ; L00021AC2 

                        ; display 'Insert Disk 2' and wait for disk swap
insert_disk_2           ; original address L00021A96
                                MOVE.L  #insert_disk_2_message,d0       ; #L00036118,D0
                                MOVE.W  D0,insertdisk_bplptl            ; L00022DE0
                                SWAP.W  D0
                                MOVE.W  D0,insertdisk_bplpth            ; L00022DDC
                                BRA.W   detect_disk_change              ; L00021AC2 

                        ; display 'Insert Disk 1' and wait for disk swap 
insert_disk_1           ; original address L00021AAE
                                MOVE.L  #insert_disk_1_message,d0       ; #L00036000,D0
                                MOVE.W  D0,insertdisk_bplptl            ; L00022DE0
                                SWAP.W  D0
                                MOVE.W  D0,insertdisk_bplpth            ; L00022DDC

detect_disk_change      ; original address L00021AC2
                                BTST.B  #$0002,$00bfe001                ; test /CHNG bit (disk changed)
                                BEQ.B   disk_change_loop                ; no, then wait until disk changed detected
                                BRA     try_load_file                   ; yes, retry load file ; was - detect_disk_change              ; L00021AC2 
 
                        ; step disk in one track and out one track to update disk changed bit
                        ; when heads change direction it requires a long wait - ive got 24 milliseconds
disk_change_loop
                                AND.B   #$fd,$00bfd100                  ; set DIR = 0 -  towards track 80 - inwards
                                BSR.W   step_heads_long_wait
                                OR.B    #$02,$00bfd100                  ; set /DIR = 1 - towards track 0 - outwards
                                BSR.W   step_heads_long_wait
                                BTST.B  #$0002,$00bfe001                ; test /CHNG bit (disk changed)
                                BEQ.B   disk_change_loop                ; disk not changed yet 
                                BRA.W   try_load_file                   ; disk changed, try load again 


correct_disk_in_drive   ; original address L00021AF4
                                MOVE.L  #insert_disk_blank_message,d0           ; #L00036348,D0
                                MOVE.W  D0,insertdisk_bplptl                    ; L00022DE0
                                SWAP.W  D0
                                MOVE.W  D0,insertdisk_bplpth                    ; L00022DDC

load_tracks                     ; get file to load parameters & load the file
                                LEA.L   loader_parameters,a0                    ; L00021B86,A0
                                MOVE.W  (A0)+,D0                                ; start track
                                MOVE.W  (A0)+,D1                                ; number of tracks + 1
                                MOVEA.L (A0)+,A4                                ; load address
                                MOVEA.L (A0)+,A5                                ; unused
load_tracks_loop                BSR.W   step_to_track                           ; L00021932
                                BSR.W   read_raw_track                          ; L0002185C
                                BSR.W   decode_raw_track                        ; L000219BE
                                ADDA.L  #$1600,A4
                                ADD.W   #$0001,D0
                                DBF.W   D1,load_tracks_loop 
                                BSR.W   drive_off                               ; L00021842
                                RTS 


                ; ------------------ step heads with long wait ---------------------
                ; when stepping heads and changing direction then a longer wait is 
                ; required between the next step.
                ; this routine is called when detecting a change of disk, this 
                ; requires the heads to be stepped in and out to update the disk
                ; changed bit.
step_heads_long_wait    ; original address L00021B36
                                OR.B    #$01,$00bfd100
                                AND.B   #$fe,$00bfd100
                                OR.B    #$01,$00bfd100
                                BSR.W   timer_delay_2ms                         ; L000218C4
                                BSR.W   timer_delay_2ms                         ; L000218C4
                                BSR.W   timer_delay_2ms                         ; L000218C4
                                BSR.W   timer_delay_2ms                         ; L000218C4
                                BSR.W   timer_delay_2ms                         ; L000218C4
                                BSR.W   timer_delay_2ms                         ; L000218C4
                                BSR.W   timer_delay_2ms                         ; L000218C4
                                BSR.W   timer_delay_2ms                         ; L000218C4
                                BSR.W   timer_delay_2ms                         ; L000218C4
                                BSR.W   timer_delay_2ms                         ; L000218C4
                                BSR.W   timer_delay_2ms                         ; L000218C4
                                BSR.W   timer_delay_2ms                         ; L000218C4
                                RTS 

mfm_track_buffer_ptr    ; original address L00021B80
                                dc.l    MFM_BUFFER              ; $00075000
current_track           ; original address L00021B84
                                dc.w    $0000

; load file paramters
loader_parameters       ; original address L00021B86
loader_start_track      ; original address L00021B86
                                dc.w    $0000
loader_number_of_tracks ; original addres L00021B88
                                dc.w    $0000
loader_dest_buffer      ; original address L00021B8A
                                dc.l    $00000000
loader_disk_number     ; original address L00021B92
                                dc.l    $0000






                ; ---------------------- copper list ------------------------
                ; copper list that controls the screen display,
                ; sectioned into the following horizontal areas
                ;       1) top logo
                ;       2) menu typer & vector logo (main screen area)
                ;       3) insert disk area (overlaps with bottom of vector logo)
                ;       4) main scroll text
                ;
copper_list     ; original address L00022CCA
                                ;dc.w    INTREQ,$8010            ; COPER Interrupt (level 3)
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
copper_vector_logo_colour
L00022DAC                       dc.w    $0000           ; vector logo colour
copper_menu_fade_colour
L00022DAE                       dc.w    $0184           ; text typer colour
                                dc.w    $0002
                                dc.w    $0186
                                dc.w    $0002           ; text typer colour where it overlaps vector logo
                                dc.w    $01A0           ; sprite ptr colour
                                dc.w    $00AA
                                dc.w    $01A2           ; sprite ptr colour
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




                ; -------------------- menu/text typer font -------------------
                ; 118 bytes wide (944 pixels), 7 rasters high
                ; total bytes = 117 x 7 = 944
menu_font_gfx   ; original address L000245F2
                                include "gfx/typerfont.s"



                ; ----------------------- top logo gfx ------------------------
                ; 'Lunatics Infinite Dreams' logo displayed at the top
                ; of the screen. Its a 320x57 - 4 bitplane logo.
                ;
top_logo_gfx    ; original address L000249A2
                incdir  "gfx/"
                include "toplogo.s"



                ; ---------------------- scroll text data ---------------------
                ; current scroll text pointer and scroll text data.
                ; the scroll text data is terminated with $ff,$00 causing it
                ; to wrap to the start.
                ;
scroll_text_ptr ; original address L00026D42
                                dc.l    scroll_text
scroll_text     ; original address L00026D46
                                include "data/scrolltext.s"
                                dc.b    $ff,$00                 ; scroll text terminator.



                ; --------------------- scroll text gfx buffers ----------------------
                ; 4 bitplane (16 colour) scoller at the bottom of the screen.
                ; is also double buffered (for some reason, probably to give a bit
                ; more time for the spinning logo etc)
                ;
                ; start of bitplane 0 for the bottom scroll text buffer 
                ; double buffered display $1508 (5504 bytes wide)
                ;
                ; I think the original allocated too much memoty per bitplane
                ; try 88*32 = 2816
                ;
                ; original address L0002A5B8
scroll_text_bpl_0_start         dcb.w   44*32,$0000
scroll_text_bpl_1_start         dcb.w   44*32,$0000
scroll_text_bpl_2_start         dcb.w   44*32,$0000
scroll_text_bpl_3_start         dcb.w   44*32,$0000



scroll_font_gfx ; original address scroll_font_gfx
                                include "gfx/scrollfontgfx.s"



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
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0000
                                dc.w    $0000,$01FA,$33EF,$DF3F,$00F9,$F9F6,$601E,$0000
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0063,$360C,$198C
                                dc.w    $00CC,$6306,$6006,$0000,$0000,$0000,$0000,$0000
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                                dc.w    $0000,$0063,$B60C,$198C,$00CC,$6306,$6006,$0000
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0063,$F3CF,$9F0C
                                dc.w    $00CC,$61E7,$C006,$0000,$0000,$0000,$0000,$0000
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                                dc.w    $0000,$0063,$706C,$198C,$00CC,$6036,$6006,$0000
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0063,$306C,$198C
                                dc.w    $00CC,$6036,$6006,$0000,$0000,$0000,$0000,$0000
                                dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
                                dc.w    $0000,$01FB,$17CF,$D98C,$00F9,$FBE6,$601F,$8000
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




                ; ------------------- sin table for 0-359 degrees ---------------------
                ; Sin table for 360 degrees. Values are multiplied by 128
                ; for integer maths. So values run from -128 to +128
sin_table       ; original address L000394AE
                                dc.w    $0000,$0002,$0004,$0006,$0008,$000B,$000D
                                dc.w    $000F,$0011,$0013,$0016,$0018,$001A,$001C,$001E
                                dc.w    $0020,$0023,$0025,$0027,$0029,$002B,$002D,$002F
                                dc.w    $0031,$0033,$0035,$0037,$0039,$003B,$003D,$003F
                                dc.w    $0041,$0043,$0045,$0047,$0049,$004A,$004C,$004E
                                dc.w    $0050,$0051,$0053,$0055,$0056,$0058,$005A,$005B
                                dc.w    $005D,$005E,$0060,$0061,$0063,$0064,$0065,$0067
                                dc.w    $0068,$0069,$006A,$006C,$006D,$006E,$006F,$0070
                                dc.w    $0071,$0072,$0073,$0074,$0075,$0076,$0077,$0077
                                dc.w    $0078,$0079,$0079,$007A,$007B,$007B,$007C,$007C
                                dc.w    $007D,$007D,$007D,$007E,$007E,$007E,$007F,$007F
                                dc.w    $007F,$007F,$007F,$007F,$007F,$007F,$007F,$007F
                                dc.w    $007F,$007E,$007E,$007E,$007D,$007D,$007D,$007C
                                dc.w    $007C,$007B,$007B,$007A,$0079,$0079,$0078,$0077
                                dc.w    $0077,$0076,$0075,$0074,$0073,$0072,$0071,$0070
                                dc.w    $006F,$006E,$006D,$006C,$006A,$0069,$0068,$0067
                                dc.w    $0065,$0064,$0063,$0061,$0060,$005E,$005D,$005B
                                dc.w    $005A,$0058,$0056,$0055,$0053,$0051,$0050,$004E
                                dc.w    $004C,$004A,$0049,$0047,$0045,$0043,$0041,$003F
                                dc.w    $003D,$003B,$0039,$0037,$0035,$0033,$0031,$002F
                                dc.w    $002D,$002B,$0029,$0027,$0025,$0023,$0020,$001E
                                dc.w    $001C,$001A,$0018,$0016,$0013,$0011,$000F,$000D
                                dc.w    $000B,$0008,$0006,$0004,$0002,$0000,$FFFD,$FFFB
                                dc.w    $FFF9,$FFF7,$FFF4,$FFF2,$FFF0,$FFEE,$FFEC,$FFE9
                                dc.w    $FFE7,$FFE5,$FFE3,$FFE1,$FFDF,$FFDC,$FFDA,$FFD8
                                dc.w    $FFD6,$FFD4,$FFD2,$FFD0,$FFCE,$FFCC,$FFCA,$FFC8
                                dc.w    $FFC6,$FFC4,$FFC2,$FFC0,$FFBE,$FFBC,$FFBA,$FFB8
                                dc.w    $FFB6,$FFB5,$FFB3,$FFB1,$FFAF,$FFAE,$FFAC,$FFAA
                                dc.w    $FFA9,$FFA7,$FFA5,$FFA4,$FFA2,$FFA1,$FF9F,$FF9E
                                dc.w    $FF9C,$FF9B,$FF9A,$FF98,$FF97,$FF96,$FF95,$FF93
                                dc.w    $FF92,$FF91,$FF90,$FF8F,$FF8E,$FF8D,$FF8C,$FF8B
                                dc.w    $FF8A,$FF89,$FF88,$FF88,$FF87,$FF86,$FF86,$FF85
                                dc.w    $FF84,$FF84,$FF83,$FF83,$FF82,$FF82,$FF82,$FF81
                                dc.w    $FF81,$FF81,$FF80,$FF80,$FF80,$FF80,$FF80,$FF80
                                dc.w    $FF80,$FF80,$FF80,$FF80,$FF80,$FF81,$FF81,$FF81
                                dc.w    $FF82,$FF82,$FF82,$FF83,$FF83,$FF84,$FF84,$FF85
                                dc.w    $FF86,$FF86,$FF87,$FF88,$FF88,$FF89,$FF8A,$FF8B
                                dc.w    $FF8C,$FF8D,$FF8E,$FF8F,$FF90,$FF91,$FF92,$FF93
                                dc.w    $FF95,$FF96,$FF97,$FF98,$FF9A,$FF9B,$FF9C,$FF9E
                                dc.w    $FF9F,$FFA1,$FFA2,$FFA4,$FFA5,$FFA7,$FFA9,$FFAA
                                dc.w    $FFAC,$FFAE,$FFAF,$FFB1,$FFB3,$FFB5,$FFB6,$FFB8
                                dc.w    $FFBA,$FFBC,$FFBE,$FFC0,$FFC2,$FFC4,$FFC6,$FFC8
                                dc.w    $FFCA,$FFCC,$FFCE,$FFD0,$FFD2,$FFD4,$FFD6,$FFD8
                                dc.w    $FFDA,$FFDC,$FFDF,$FFE1,$FFE3,$FFE5,$FFE7,$FFE9
                                dc.w    $FFEC,$FFEE,$FFF0,$FFF2,$FFF4,$FFF7,$FFF9,$FFFB
                                dc.w    $FFFD



                ; ------------------- cosine table for 0-359 degrees ---------------------
                ; Cosine table for 360 degrees. Values are multiplied by 128
                ; for integer maths. So values run from -128 to +128
                ; 
cosine_table    ; original address L0003977E
                                dc.w    $007F,$007F,$007F,$007F,$007F,$007F,$007E
                                dc.w    $007E,$007E,$007D,$007D,$007D,$007C,$007C,$007B
                                dc.w    $007B,$007A,$0079,$0079,$0078,$0077,$0077,$0076
                                dc.w    $0075,$0074,$0073,$0072,$0071,$0070,$006F,$006E
                                dc.w    $006D,$006C,$006A,$0069,$0068,$0067,$0065,$0064
                                dc.w    $0063,$0061,$0060,$005E,$005D,$005B,$005A,$0058
                                dc.w    $0056,$0055,$0053,$0051,$0050,$004E,$004C,$004A
                                dc.w    $0049,$0047,$0045,$0043,$0041,$003F,$003D,$003B
                                dc.w    $0039,$0037,$0035,$0033,$0031,$002F,$002D,$002B
                                dc.w    $0029,$0027,$0025,$0023,$0020,$001E,$001C,$001A
                                dc.w    $0018,$0016,$0013,$0011,$000F,$000D,$000B,$0008
                                dc.w    $0006,$0004,$0002,$0000,$FFFD,$FFFB,$FFF9,$FFF7
                                dc.w    $FFF4,$FFF2,$FFF0,$FFEE,$FFEC,$FFE9,$FFE7,$FFE5
                                dc.w    $FFE3,$FFE1,$FFDF,$FFDC,$FFDA,$FFD8,$FFD6,$FFD4
                                dc.w    $FFD2,$FFD0,$FFCE,$FFCC,$FFCA,$FFC8,$FFC6,$FFC4
                                dc.w    $FFC2,$FFC0,$FFBE,$FFBC,$FFBA,$FFB8,$FFB6,$FFB5
                                dc.w    $FFB3,$FFB1,$FFAF,$FFAE,$FFAC,$FFAA,$FFA9,$FFA7
                                dc.w    $FFA5,$FFA4,$FFA2,$FFA1,$FF9F,$FF9E,$FF9C,$FF9B
                                dc.w    $FF9A,$FF98,$FF97,$FF96,$FF95,$FF93,$FF92,$FF91
                                dc.w    $FF90,$FF8F,$FF8E,$FF8D,$FF8C,$FF8B,$FF8A,$FF89
                                dc.w    $FF88,$FF88,$FF87,$FF86,$FF86,$FF85,$FF84,$FF84
                                dc.w    $FF83,$FF83,$FF82,$FF82,$FF82,$FF81,$FF81,$FF81
                                dc.w    $FF80,$FF80,$FF80,$FF80,$FF80,$FF80,$FF80,$FF80
                                dc.w    $FF80,$FF80,$FF80,$FF81,$FF81,$FF81,$FF82,$FF82
                                dc.w    $FF82,$FF83,$FF83,$FF84,$FF84,$FF85,$FF86,$FF86
                                dc.w    $FF87,$FF88,$FF88,$FF89,$FF8A,$FF8B,$FF8C,$FF8D
                                dc.w    $FF8E,$FF8F,$FF90,$FF91,$FF92,$FF93,$FF95,$FF96
                                dc.w    $FF97,$FF98,$FF9A,$FF9B,$FF9C,$FF9E,$FF9F,$FFA1
                                dc.w    $FFA2,$FFA4,$FFA5,$FFA7,$FFA9,$FFAA,$FFAC,$FFAE
                                dc.w    $FFAF,$FFB1,$FFB3,$FFB5,$FFB6,$FFB8,$FFBA,$FFBC
                                dc.w    $FFBE,$FFC0,$FFC2,$FFC4,$FFC6,$FFC8,$FFCA,$FFCC
                                dc.w    $FFCE,$FFD0,$FFD2,$FFD4,$FFD6,$FFD8,$FFDA,$FFDC
                                dc.w    $FFDF,$FFE1,$FFE3,$FFE5,$FFE7,$FFE9,$FFEC,$FFEE
                                dc.w    $FFF0,$FFF2,$FFF4,$FFF7,$FFF9,$FFFB,$FFFD,$0000
                                dc.w    $0002,$0004,$0006,$0008,$000B,$000D,$000F,$0011
                                dc.w    $0013,$0016,$0018,$001A,$001C,$001E,$0020,$0023
                                dc.w    $0025,$0027,$0029,$002B,$002D,$002F,$0031,$0033
                                dc.w    $0035,$0037,$0039,$003B,$003D,$003F,$0041,$0043
                                dc.w    $0045,$0047,$0049,$004A,$004C,$004E,$0050,$0051
                                dc.w    $0053,$0055,$0056,$0058,$005A,$005B,$005D,$005E
                                dc.w    $0060,$0061,$0063,$0064,$0065,$0067,$0068,$0069
                                dc.w    $006A,$006C,$006D,$006E,$006F,$0070,$0071,$0072
                                dc.w    $0073,$0074,$0075,$0076,$0077,$0077,$0078,$0079
                                dc.w    $0079,$007A,$007B,$007B,$007C,$007C,$007D,$007D
                                dc.w    $007D,$007E,$007E,$007E,$007F,$007F,$007F,$007F
                                dc.w    $007F



                ; ------------------- spinning logo colour table --------------------
                ; 359 - colour entries for each angle of rotation.
                ; The spinning logo colour is looked up from this table
                ; using the rotation angle as an index.
                ;
spinning_logo_colour_table      ;original address L00039A4E
                                dc.w    $00FF,$00FF,$00FF,$00FF,$00FF,$00FF,$00EE               
                                dc.w    $00EE,$00EE,$00EE,$00EE,$00EE,$00DD,$00DD,$00DD
                                dc.w    $00DD,$00DD,$00DD,$00CC,$00CC,$00CC,$00CC,$00CC
                                dc.w    $00CC,$00BB,$00BB,$00BB,$00BB,$00BB,$00BB,$00AA
                                dc.w    $00AA,$00AA,$00AA,$00AA,$00AA,$0099,$0099,$0099
                                dc.w    $0099,$0099,$0099,$0088,$0088,$0088,$0088,$0088
                                dc.w    $0088,$0077,$0077,$0077,$0077,$0077,$0077,$0066
                                dc.w    $0066,$0066,$0066,$0066,$0066,$0055,$0055,$0055
                                dc.w    $0055,$0055,$0055,$0044,$0044,$0044,$0044,$0044
                                dc.w    $0044,$0033,$0033,$0033,$0033,$0033,$0033,$0022
                                dc.w    $0022,$0022,$0022,$0022,$0022,$0011,$0011,$0011
                                dc.w    $0011,$0000,$0000,$0000,$0000,$0100,$0100,$0100
                                dc.w    $0100,$0200,$0200,$0200,$0200,$0200,$0200,$0300
                                dc.w    $0300,$0300,$0300,$0300,$0300,$0400,$0400,$0400
                                dc.w    $0400,$0400,$0400,$0500,$0500,$0500,$0500,$0500
                                dc.w    $0500,$0600,$0600,$0600,$0600,$0600,$0600,$0700
                                dc.w    $0700,$0700,$0700,$0700,$0700,$0800,$0800,$0800
                                dc.w    $0800,$0800,$0800,$0900,$0900,$0900,$0900,$0900
                                dc.w    $0900,$0A00,$0A00,$0A00,$0A00,$0A00,$0A00,$0B00
                                dc.w    $0B00,$0B00,$0B00,$0B00,$0B00,$0C00,$0C00,$0C00
                                dc.w    $0C00,$0C00,$0C00,$0D00,$0D00,$0D00,$0D00,$0D00
                                dc.w    $0D00,$0E00,$0E00,$0E00,$0E00,$0E00,$0E00,$0F00
                                dc.w    $0F00,$0F00,$0F00,$0F00,$0F00,$0F00,$0F00,$0F00
                                dc.w    $0F00,$0F00,$0F00,$0E00,$0E00,$0E00,$0E00,$0E00
                                dc.w    $0E00,$0D00,$0D00,$0D00,$0D00,$0D00,$0D00,$0C00
                                dc.w    $0C00,$0C00,$0C00,$0C00,$0C00,$0B00,$0B00,$0B00
                                dc.w    $0B00,$0B00,$0B00,$0A00,$0A00,$0A00,$0A00,$0A00
                                dc.w    $0A00,$0900,$0900,$0900,$0900,$0900,$0900,$0800
                                dc.w    $0800,$0800,$0800,$0800,$0800,$0700,$0700,$0700
                                dc.w    $0700,$0700,$0700,$0600,$0600,$0600,$0600,$0600
                                dc.w    $0600,$0500,$0500,$0500,$0500,$0500,$0500,$0400
                                dc.w    $0400,$0400,$0400,$0400,$0400,$0300,$0300,$0300
                                dc.w    $0300,$0300,$0300,$0200,$0200,$0200,$0200,$0200
                                dc.w    $0200,$0000,$0000,$0100,$0100,$0100,$0100,$0000
                                dc.w    $0000,$0011,$0011,$0011,$0011,$0022,$0022,$0022
                                dc.w    $0022,$0022,$0022,$0033,$0033,$0033,$0033,$0033
                                dc.w    $0033,$0044,$0044,$0044,$0044,$0044,$0044,$0055
                                dc.w    $0055,$0055,$0055,$0055,$0055,$0066,$0066,$0066
                                dc.w    $0066,$0066,$0066,$0077,$0077,$0077,$0077,$0077
                                dc.w    $0077,$0088,$0088,$0088,$0088,$0088,$0088,$0099
                                dc.w    $0099,$0099,$0099,$0099,$0099,$00AA,$00AA,$00AA
                                dc.w    $00AA,$00AA,$00AA,$00BB,$00BB,$00BB,$00BB,$00BB
                                dc.w    $00BB,$00CC,$00CC,$00CC,$00CC,$00CC,$00CC,$00DD
                                dc.w    $00DD,$00DD,$00DD,$00DD,$00DD,$00EE,$00EE,$00EE
                                dc.w    $00EE,$00EE,$00EE,$00FF,$00FF,$00FF,$00FF,$00FF
                                dc.w    $00FF

number_of_vertices      ; original address L00039D1E
                                dc.w    $0044   ; 68+1 (69) vertices in the spinning logo ; original address L00039D1E



        ; -------------------------- logo vertices ----------------------
        ; 'Lunatics' spinning logo vertices. I remember plotting this out
        ; on graph paper and creating this table 30 years later.
        ;
        ; unmodified logo vertices (x,y,z) stored as 3 words per vertex
        ; used as the source to the rotate_logo routine.
        ;
logo_vertices   ; 68+1 vertices - original address L00039D20
                                dc.w    $FE0C,$0032,$0000       ; 1
                                dc.w    $FE0C,$FFF6,$0000
                                dc.w    $FE98,$FFB0,$0000
                                dc.w    $FEC0,$FFC4,$0000
                                dc.w    $FE48,$0001,$0000
                                dc.w    $FE48,$000A,$0000
                                dc.w    $FEC0,$000A,$0000
                                dc.w    $FEC0,$0032,$0000
                                dc.w    $FEF2,$0032,$0000
                                dc.w    $FECA,$001E,$0000       ; 10 
                                dc.w    $FECA,$FFF6,$0000
                                dc.w    $FEF2,$FFF6,$0000
                                dc.w    $FEF2,$001E,$0000
                                dc.w    $FF1A,$001E,$0000
                                dc.w    $FF1A,$FFF6,$0000
                                dc.w    $FF42,$FFF6,$0000
                                dc.w    $FF42,$0032,$0000
                                dc.w    $FF4C,$0032,$0000 
                                dc.w    $FF4C,$FFF6,$0000
                                dc.w    $FF9C,$FFF6,$0000       ; 20
                                dc.w    $FFC4,$000A,$0000
                                dc.w    $FFC4,$0032,$0000
                                dc.w    $FF9C,$0032,$0000
                                dc.w    $FF9C,$000A,$0000
                                dc.w    $FF74,$000A,$0000
                                dc.w    $FF74,$0032,$0000 
                                dc.w    $FFCE,$001E,$0000
                                dc.w    $FFCE,$000A,$0000
                                dc.w    $FFF6,$FFF6,$0000
                                dc.w    $0032,$FFF6,$0000       ; 30
                                dc.w    $0032,$0032,$0000
                                dc.w    $FFF6,$0032,$0000
                                dc.w    $FFF6,$001E,$0000
                                dc.w    $0014,$001E,$0000 
                                dc.w    $0014,$000A,$0000
                                dc.w    $FFF6,$000A,$0000
                                dc.w    $003C,$FFF6,$0000
                                dc.w    $0096,$FFF6,$0000
                                dc.w    $0096,$0032,$0000
                                dc.w    $006E,$0032,$0000       ; 40
                                dc.w    $006E,$000A,$0000
                                dc.w    $003C,$000A,$0000 
                                dc.w    $00A0,$FFF6,$0000
                                dc.w    $00C8,$FFF6,$0000
                                dc.w    $00C8,$0032,$0000
                                dc.w    $00A0,$0032,$0000
                                dc.w    $00D2,$0032,$0000
                                dc.w    $0136,$0032,$0000
                                dc.w    $0136,$001E,$0000
                                dc.w    $00FA,$001E,$0000       ; 50 
                                dc.w    $00FA,$000A,$0000
                                dc.w    $0136,$000A,$0000
                                dc.w    $0136,$FFF6,$0000
                                dc.w    $00FA,$FFF6,$0000
                                dc.w    $00D2,$000A,$0000
                                dc.w    $0140,$0032,$0000
                                dc.w    $0186,$0032,$0000
                                dc.w    $01AE,$001E,$0000 
                                dc.w    $01AE,$000F,$0000
                                dc.w    $0168,$000F,$0000       ; 60
                                dc.w    $0168,$000A,$0000
                                dc.w    $01AE,$000A,$0000
                                dc.w    $01AE,$FFF6,$0000
                                dc.w    $0168,$FFF6,$0000
                                dc.w    $0140,$000A,$0000
                                dc.w    $0140,$0019,$0000 
                                dc.w    $0186,$0019,$0000
                                dc.w    $0186,$001E,$0000
                                dc.w    $0140,$001E,$0000       ; 69


rotated_vertices        ; 68+1 sets of x,y,z word values - original address L00039EBE
                                dcb.b   6*69,$0000


        ; list of 2d points for spinning logo.  These points are used by the line draw routine
        ; to draw the outline of the spinning logo to the screen before being filled by the blitter
points_2d       ; original address L0003A2A6
                                dcb.b   4*69,$0000


number_of_lines ; original address L0003A68E
L0003A68E                       dc.w    $0044



                ; -------------------- logo line table ------------------------
                ; table of line indexes, used to draw the outline of the
                ; 'Lunatics' spinning logo.
                ; each entry consists of 2 indexes into the points_2d
                ; table above.
                ; the indexes into the points_2d table provide to two
                ; endpoints of each line (x1,y1) and (x2,y2)
                ;
                ;       dc.w    <index1>,<index2>
                ;
logo_line_table ; original address L0003A690
                                dc.w    $0000,$0004     ; 1
                                dc.w    $0004,$0008
                                dc.w    $0008,$000C
                                dc.w    $000C,$0010
                                dc.w    $0010,$0014
                                dc.w    $0014,$0018
                                dc.w    $0018,$001C
                                dc.w    $001C,$0000
                                dc.w    $0020,$0024
                                dc.w    $0024,$0028     ; 10
                                dc.w    $0028,$002C
                                dc.w    $002C,$0030
                                dc.w    $0030,$0034
                                dc.w    $0034,$0038
                                dc.w    $0038,$003C
                                dc.w    $003C,$0040
                                dc.w    $0040,$0020
                                dc.w    $0044,$0048
                                dc.w    $0048,$004C
                                dc.w    $004C,$0050     ; 20
                                dc.w    $0050,$0054
                                dc.w    $0054,$0058
                                dc.w    $0058,$005C
                                dc.w    $005C,$0060
                                dc.w    $0060,$0064
                                dc.w    $0064,$0044
                                dc.w    $0068,$006C
                                dc.w    $006C,$0070
                                dc.w    $0070,$0074
                                dc.w    $0074,$0078     ; 30
                                dc.w    $0078,$007C
                                dc.w    $007C,$0068
                                dc.w    $0080,$0084
                                dc.w    $0084,$0088
                                dc.w    $0088,$008C
                                dc.w    $008C,$0080
                                dc.w    $0090,$0094
                                dc.w    $0094,$0098
                                dc.w    $0098,$009C
                                dc.w    $009C,$00A0     ; 40
                                dc.w    $00A0,$00A4
                                dc.w    $00A4,$0090
                                dc.w    $00A8,$00AC
                                dc.w    $00AC,$00B0
                                dc.w    $00B0,$00B4
                                dc.w    $00B4,$00A8
                                dc.w    $00B8,$00BC
                                dc.w    $00BC,$00C0
                                dc.w    $00C0,$00C4
                                dc.w    $00C4,$00C8     ; 50
                                dc.w    $00C8,$00CC
                                dc.w    $00CC,$00D0
                                dc.w    $00D0,$00D4
                                dc.w    $00D4,$00D8
                                dc.w    $00D8,$00B8
                                dc.w    $00DC,$00E0
                                dc.w    $00E0,$00E4
                                dc.w    $00E4,$00E8
                                dc.w    $00E8,$00EC
                                dc.w    $00EC,$00F0     ; 60
                                dc.w    $00F0,$00F4
                                dc.w    $00F4,$00F8
                                dc.w    $00F8,$00FC
                                dc.w    $00FC,$0100
                                dc.w    $0100,$0104
                                dc.w    $0104,$0108
                                dc.w    $0108,$010C
                                dc.w    $010C,$0110
                                dc.w    $0110,$00DC     ; 69



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


                ; menu format = 45 x 17 characters
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
        even
mfm_track_buffer        dcb.w   $1A00            ; 13Kb raw mfm track buffer for testing
        ENDC

        IFD TEST_BUILD
        even
load_buffer             dcb.b   1024*200,$00    ; 200Kb Soundtrack module buffer for testing
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





                include "protracker/ptplayer/ptplayer.asm"


