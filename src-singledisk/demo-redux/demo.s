

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




                ; menu ptr list indexes
MENU_IDX_main_menu              EQU     $00     ; menu index/id = $00
MENU_IDX_disk_1_menu            EQU     $04     ; menu index/id = $04
MENU_IDX_disk_2_menu            EQU     $08     ; menu index/id = $08
MENU_IDX_disk_3_menu            EQU     $0c     ; menu index/id = $0c
MENU_IDX_credits_menu           EQU     $10     ; menu index/id = $10
MENU_IDX_greetings_1_menu       EQU     $14     ; menu index/id = $14
MENU_IDX_greetings_2_menu       EQU     $18     ; menu index/id = $18
MENU_IDX_addresses_1_menu       EQU     $1c     ; menu index/id = $1c
MENU_IDX_addresses_2_menu       EQU     $20     ; menu index/id = $20
MENU_IDX_addresses_3_menu       EQU     $24     ; menu index/id = $24
MENU_IDX_addresses_4_menu       EQU     $28     ; menu index/id = $28
MENU_IDX_addresses_5_menu       EQU     $2c     ; menu index/id = $2c
MENU_IDX_addresses_6_menu       EQU     $30     ; menu index/id = $30
MENU_IDX_pd_message_menu        EQU     $34     ; menu index/id = $34


FILE_TABLE_OFFSET       EQU $400        ; disk offset to file table (directly following the bootblock)
FILE_TABLE_LENGTH       EQU $1a0        ; length of file table in bytes





TEST_BUILD SET 1                                        ; Comment this to remove TEST_BUILD 


     
        ; Set 'Test Build' or 'Live Build' parameters 
        IFD TEST_BUILD
STACK_ADDRESS   EQU     start_demo                      ; test stack address (start of program)
MUSIC_BUFFER    EQU     buffer_low                      ; final depacked module for playing (also doubles as a 120kb buffer for initial zxo load area)
BUFFER_LOW      EQU     buffer_low
BUFFER_HIGH     EQU     buffer_high                     ; depacked module buffer (still delta encoded here)
MFM_BUFFER      EQU     mfm_track_buffer
        ELSE
                org     $2000                            
STACK_ADDRESS   EQU     $00001000                       ; original stack address
MUSIC_BUFFER    EQU     $00020000                       ; final depacked module for playing (also doubles as a 120kb buffer for initial zxo load area)
BUFFER_LOW      EQU     $00020000
BUFFER_HIGH     EQU     $00040000                       ; depacked module buffer (still delta encoded here)
MFM_BUFFER      EQU     $0007d140                       ; raw 4489 loader MFM buffer
        ENDC



        ; State machine states
        ; Can't decide whether to have one or two state machines at the moment.
        ; Either a separate menu & music player state machines or just combine into one.
        ; separation may give me more reusability for other projects down the line.
        ; Think I'll try two state machines and see how that goes.
STATE_MUSIC_INIT        EQU     $10
STATE_MUSIC_STOP        EQU     $20
STATE_MUSIC_PLAY        EQU     $30
STATE_MUSIC_START       EQU     $40



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
                ;
start_demo                      lea.l   STACK_ADDRESS,a7
                                bsr.w   init_system
                                bsr.w   init_display
                                bsr.w   do_fade_in_top_logo

                        IFD TEST_BUILD
                                jsr     _DEBUG_COLOURS                          ; if run in emulator then mouse button pause while disk is inserted
                        ENDC

                                bsr.w   load_file_table 
                                bsr.w   menu_statemachine_init

                                ; initialise mouse input
                                move.b  CUSTOM+JOY0DAT,mouse_y_value            ; mouse y initial value - $00dff00a,L00020882

                                bra.w   main_loop



            ; ------------------ load file table -------------------
            ; load file table/directory into file table buffer
load_file_table                 move.l  #FILE_TABLE_OFFSET,d0                   ; byte offset on disk
                                move.l  #FILE_TABLE_LENGTH,d1                   ; file table byte length on disk
                                moveq   #0,d2                                   ; select drive 0
                                lea.l   disk_file_table,a0                      ; file table load address
                                lea.l   MFM_BUFFER,a1                           ; raw disk mfm track buffer
                                bsr     loader_4489
                                rts



                ; ------------- Initialise System -----------------
                ; Set up Level 3 Interrupt and kill DMA
init_system                     LEA.L   CUSTOM,A6
                                MOVE.W  #$3fff,INTENA(A6)                       ; disable all interrupts
                                MOVE.W  #$7fff,D0
                                MOVE.W  D0,DMACON(A6)                           ; disable all DMA
                                MOVE.W  D0,INTREQ(A6)                           ; clear raised interrupt flags
                                lea     do_nothing_interrupt_handler(pc),a0
                                move.l  a0,$64.W
                                move.l  a0,$68.W
                                move.l  a0,$6c.W
                                move.l  a0,$70.W
                                move.l  a0,$74.W
                                move.l  a0,$78.W
                                move.l  a0,$7c.W            
                                LEA.L   level_3_interrupt_handler(PC),A0 
                                MOVE.L  A0,$6c.w                                ; level 3 interrupt autovector
                                MOVE.W  #$8020,INTENA(A6)                       ; enable VBL Interrupt
                                RTS 



                ; ------------ Initialise Display ----------------
init_display                    BSR.W   init_vectorlogo_bitplanes       
                                BSR.W   init_menu_typer_bitplanes       
                                BSR.W   init_top_logo_gfx               
                                BSR.W   init_scroller_text_display      
                                BSR.W   init_sprites                    
                                BSR.W   init_insert_disk_bitplanes      
                                LEA.L   copper_list(pc),a0
                                MOVE.L  A0,COP1LC(A6)
                                MOVE.W  #$87ef,DMACON(A6)                       ; BLTPRI,DMAEN,BPLEN,COPEN,BLTEN,SPREN,AUD0-3
                                RTS 


                ; ---------------- initialise insert disk bitplanes ------------------
                ; set a blank 'insert disk x' message at the bottom of the typer
init_insert_disk_bitplanes      MOVE.L  #insert_disk_blank_message,d0   
                                MOVE.W  D0,insertdisk_bplptl            
                                SWAP.W  D0
                                MOVE.W  D0,insertdisk_bplpth            
                                RTS 



                ; ------------------ initialise menu typer bitplanes ------------------
                ; set the copper bitplane ptrs for the menu screen typer text routine.
init_menu_typer_bitplanes       MOVE.L  #menu_typer_bitplane,d0         
                                MOVE.W  D0,menu_bplptl                  
                                SWAP.W  D0
                                MOVE.W  D0,menu_bpltpth                 
                                RTS 


                ; ----------------- initialise vector logo bitplanes -----------------
init_vectorlogo_bitplanes       MOVE.L  #vector_logo_buffer_1,D0
                                MOVE.W  D0,vector_bplptl                
                                SWAP.W  D0
                                MOVE.W  D0,vector_bplpth                
                                RTS 



                ; ------------------ initialise top logo gfx -------------------
                ; set copper bitplane ptrs for the top logo gfx
                ; bitplane size ($8e8 = 2280) 320x57
                ; 4 bitplanes / 16 colours
                ;
init_top_logo_gfx               MOVE.L  #top_logo_gfx,d0                 
                                MOVE.W  D0,toplogo_bpl1ptl              
                                SWAP.W  D0
                                MOVE.W  D0,toplogo_bpl1pth              
                                MOVE.L  #top_logo_gfx+(40*57),D0
                                MOVE.W  D0,toplogo_bpl2ptl              
                                SWAP.W  D0
                                MOVE.W  D0,toplogo_bpl2pth              
                                MOVE.L  #top_logo_gfx+(80*57),D0
                                MOVE.W  D0,toplogo_bpl3ptl              
                                SWAP.W  D0
                                MOVE.W  D0,toplogo_bpl3pth              
                                MOVE.L  #top_logo_gfx+(120*57),D0
                                MOVE.W  D0,toplogo_bpl4ptl              
                                SWAP.W  D0
                                MOVE.W  D0,toplogo_bpl4pth              
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
init_scroller_text_display      MOVE.L  #scroll_text_bpl_0_start+6,D0
                                MOVE.W  D0,scrolltext_bpl1ptl                   
                                SWAP.W  D0
                                MOVE.W  D0,scrolltext_bpl1pth                   
                                MOVE.L  #scroll_text_bpl_1_start+6,D0
                                MOVE.W  D0,scrolltext_bpl2ptl                   
                                SWAP.W  D0
                                MOVE.W  D0,scrolltext_bpl2pth                   
                                MOVE.L  #scroll_text_bpl_2_start+6,D0
                                MOVE.W  D0,scrolltext_bpl3ptl                   
                                SWAP.W  D0
                                MOVE.W  D0,scrolltext_bpl3pth                   
                                MOVE.L  #scroll_text_bpl_3_start+6,D0
                                MOVE.W  D0,scrolltext_bpl4ptl                   
                                SWAP.W  D0
                                MOVE.W  D0,scrolltext_bpl4pth                   
                                RTS 



                ; --------------- initialise sprites ------------------
                ; Initialise copper list sprite pointers.
                ; Sprites 0 & Sprite 1 - used for the menu option selector arrows.
                ; Sprites 2-7 - unused
                ;
init_sprites                    move.l  #menu_sprite_left,d0            
                                move.w  d0,sprite_0_ptl                 
                                swap.w  d0
                                move.w  d0,sprite_0_pth                 
                                move.l  #menu_sprite_right,d0           
                                move.w  d0,sprite_1_ptl                 
                                swap.w  d0
                                move.w  d0,sprite_1_pth 
                        ; set empty sprite in remaining sprite ptrs                
                                move.l  #null_sprite,d0
                                move.l  d0,d1
                                swap.w  d1
                                move.w  d1,sprite_2_pth                 
                                move.w  d0,sprite_2_ptl                 
                                move.w  d1,sprite_3_pth                 
                                move.w  d0,sprite_3_ptl                 
                                move.w  d1,sprite_4_pth                 
                                move.w  d0,sprite_4_ptl                 
                                move.w  d1,sprite_5_pth                 
                                move.w  d0,sprite_5_ptl                 
                                move.w  d1,sprite_6_pth                 
                                move.w  d0,sprite_6_ptl                 
                                move.w  d1,sprite_7_pth                 
                                move.w  d0,sprite_7_ptl                 
                                rts 

null_sprite:                    dc.l    $0




                ; ------------------------- Do Fade In Top Logo ------------------------
                ; fades in the logo at the top of the screen 'Lunatics Infinite Dreams'
                ; loops 20 times.
                ;
do_fade_in_top_logo     
.fade_loop 
.wait_raster  
                                CMP.B   #$f0,$0006(A6)
                                BNE.B   .wait_raster                    
                                CMP.W   #$0014,top_logo_fade_count      
                                BEQ.B   .exit
                                BSR.W   fade_in_top_logo                
                                ADD.W   #$0001,top_logo_fade_count      
                                BRA.W   .fade_loop                      
.exit                           RTS 


fade_in_top_logo        ; original address L00020268
                                LEA.L   copper_top_logo_colors,a0       
                                LEA.L   top_logo_colours,a1             
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
                                BEQ.W   .fade_green                      
                                ADD.W   #$0001,$00(A0,D6.W)
.fade_green
                                MOVE.W  D0,D1
                                MOVE.W  D2,D3
                                AND.W   #$00f0,D1
                                AND.W   #$00f0,D3
                                CMP.W   D1,D3
                                BEQ.W   .fade_red                       
                                ADD.W   #$0010,$00(A0,D6.W)
.fade_red
                                MOVE.W  D0,D1
                                MOVE.W  D2,D3
                                AND.W   #$0f00,D1
                                AND.W   #$0f00,D3
                                CMP.W   D1,D3
                                BEQ.W   .fade_next                       
                                ADD.W   #$0100,$00(A0,D6.W)
.fade_next
                                ADD.W   #$0004,D6
                                DBF.W   D7,.fade_loop                   
                                RTS 

top_logo_colours        
                                dc.w    $0000,$0dde,$0ccd,$0aad,$099c,$0779,$0557,$0445
                                dc.w    $0222,$08DA,$03A6,$0083,$0FFF,$0F0F,$0F00,$0779 
top_logo_fade_count     
                                dc.w    $0000





                ;-----------------------------------------------------------------
                ;                       MENU STATE MACHINE
                ;-----------------------------------------------------------------
STATE_MENU_NULL         EQU     $0                      ; null state - do nothing state
STATE_MENU_INIT         EQU     $1
STATE_MENU_FADE_OUT     EQU     $2
STATE_MENU_CREATE       EQU     $3
STATE_MENU_FADE_IN      EQU     $4
STATE_MENU_ACTIVE       EQU     $5


menu_mainloop_state_machine
                movem.l d0-d7/a0-a6,-(a7)

                lea.l   menu_mainloop_state,a0
                move.l  (a0),a0
                cmp.l   #0,a0
                beq.s   .exit
                jsr     (a0)

.exit           movem.l (a7)+,d0-d7/a0-a6
                rts

menu_interrupt_state_machine
                movem.l d0-d7/a0-a6,-(a7)

                lea.l   menu_interrupt_state,a0
                move.l  (a0),a0
                cmp.l   #0,a0
                beq.s   .exit
                jsr     (a0)

.exit           movem.l (a7)+,d0-d7/a0-a6
                rts

menu_statemachine_init
                move.w  #STATE_MENU_INIT,menu_current_state
                bsr     menu_set_state
                rts

menu_set_state
                lea.l   menu_state_table,a0
                move.w  menu_current_state,d0
                lsl.w   #3,d0                                           ; multiply state by 8 to get menu_state_table index
                move.l  (a0,d0.w),menu_mainloop_state                   ; set main line state handler routine
                move.l  4(a0,d0.w),menu_interrupt_state                 ; set interrups state handler routine
                rts


menu_current_state      dc.w    STATE_MENU_INIT                         ; current state id
menu_mainloop_state     dc.l    $0                                      ; function ptr to current state handler (called from main_loop)
menu_interrupt_state    dc.l    $0                                      ; function ptr to current state handler (called from interrupt handler)


menu_state_table        
                        ; do nothing state
                        dc.l    $0
                        dc.l    $0
                        ; menu init state
                        dc.l    menu_state_init_ml
                        dc.l    menu_state_init_int
                        ; menu fade out state
                        dc.l    menu_state_fadeout_ml
                        dc.l    menu_state_fadeout_int
                        ; menu create state
                        dc.l    menu_state_create_ml
                        dc.l    menu_state_create_int
                        ; menu fade in state
                        dc.l    menu_state_fadein_ml
                        dc.l    menu_state_fadein_int
                        ; menu active state
                        dc.l    menu_active_state_ml
                        dc.l    menu_active_state_int



                ; ------------------ state menu init -------------------
                ; The menu system initial state. 
                ; Sets up the menu system for action.
                ;
                ; - Set the initial menu for display
                ; - Transition to: MENU_CREATE
                ;
menu_state_init_ml      move.l  #main_menu_definition,menu_current_ptr                  ; set the first menu definition for display

                        ; transition to next state                      
                        move.w  #STATE_MENU_CREATE,menu_current_state                   ; change state to 'MENU_CREATE'
                        bsr     menu_set_state
                        rts
menu_state_init_int
                        rts


                ; ----------------- state menu fade out -----------------
                ; Fade out the current Menu Display in preparation for
                ; displaying the next.
                ;
                ; - Fade out the copper colours of the menu display
                ; - Transition to: MENU_CREATE
                ;
menu_state_fadeout_ml
                        rts
menu_state_fadeout_int   
                        BSR.W   blend_typer_colour_fade                              
                        BSR.W   fade_out_menu_display                                   ; fade out menu display
                        tst.l   d0
                        beq.s   .transition_state                                       ; if fade complete, change state
                        rts 

.transition_state       ; transition to next state
                        move.w  #STATE_MENU_CREATE,menu_current_state                   ; change state to MENU_CREATE
                        bsr     menu_set_state
                        rts                   


                ; ---------------------- state menu create ----------------------
                ; Create the menu display for the menu definition pointer:
                ;  - menu_current_ptr
                ;
                ; This pointer will have been set during a previouly executed
                ; menu action in a previous MENU_ACTIVE state, or set during
                ; MENU_INIT to the first menu for display.
                ;
                ; - Create the menu, initialise the menu selector
                ; - Transition To: MENU_FADE_IN
                ;
menu_state_create_ml    bsr.w   create_current_menu                                     ; create next menu from current menu definition

                        ; transition to next state
                        move.w  #STATE_MENU_FADE_IN,menu_current_state                   ; change state to MENU_FADE_IN
                        bsr     menu_set_state
                        rts

menu_state_create_int
                        rts


                ; ------------------ state menu fade in -----------------
                ; Fade in the Menu Display.
                ;
                ; - Fade in the copper colours of the menu display
                ; - Transition to: MENU_ACTIVE
                ;
menu_state_fadein_ml
                        rts           
menu_state_fadein_int
                        bsr.w   blend_typer_colour_fade
                        bsr.w   fade_in_menu_display
                        tst.l   d0
                        beq.s   .transition_state
                        rts 

.transition_state       ; transition to next state
                        move.w  #STATE_MENU_ACTIVE,menu_current_state
                        bsr     menu_set_state
                        rts


                ; ------------------ state menu active ----------------
                ; Do menu processing actions
menu_active_state_ml
                        btst.b  #$0006,$00bfe001
                        bne.b   .mouse_not_clicked             
                        bsr.w   execute_menu_action
.mouse_not_clicked 
                        rts
menu_active_state_int
                        bsr.w   update_menu_selector_position
                        bsr.w   set_menu_selector_sprite_positions
                        rts



                ;-----------------------------------------------------------------
                ;                       MENU STATE MACHINE
                ;-----------------------------------------------------------------




                ; ===============================================================================================
                ;  MENU MANAGEMENT
                ; ===============================================================================================
                ; ===============================================================================================


                        ; ------------------- Execute Menu Action -------------------
                        ; Using the position of the menu selector, find the and
                        ; execute the menu action.
                        ;
execute_menu_action
                                move.l  menu_current_ptr,a0
                                move.w  menu_selector_y,d0
                                add.w   #4,d0                   ; add the mid-point of the sprite arrow to the menu_selector_y co-ordinate
                                lsr.w   #3,d0                   ; find the text line at which the menu selector is positioned.

                                move.w  $4(a0),d1               ; the text line containing the first selectable option.
                                sub.w   d1,d0                   ; calc the index into the menu definition commands.

                                mulu    #12,d0                  ; calculate index into the menu definition commands (3 long words per entry - 12 bytes)
                                lea     $c(a0),a1               ; the start of the menu definition commands

                                move.l  (a1,d0.w),d1            ; get the option command code ($0 = display menu, $1 = execute function)
                                
                                cmp.l   #MNUCMD_MENU,d1
                                beq.s   .display_menu
                                cmp.l   #MNUCMD_FUNCTION,d1
                                beq.s   .execute_function
                                cmp.l   #MNUCMD_NOP,d1
                                beq.s   .no_operation
                                ; unexpected menu command
                                rts

                        ; set next menu for display
.display_menu                   move.l  4(a1,d0.w),menu_current_ptr                     ; set next menu definition for display
                                ; transition state
                                move.w  #STATE_MENU_FADE_OUT,menu_current_state         ; start transition to next menu display
                                bsr     menu_set_state
                                rts

                        ; execute function (parameters address in a1)
.execute_function               move.l  8(a1,d0.w),a0                                   ; function parameters
                                move.l  4(a1,d0.w),a1                                   ; function ptr
                                jsr     (a1)
                                rts

                        ; no operation (empty menu option)
.no_operation                   rts


                        ; ------------------- Create Current Menu --------------------
                        ; Initialse and Create a menu specfied by the menu definition
                        ; referenced by the 'menu_current_ptr'
                        ;
create_current_menu             bsr.w   init_menu_selector                      ; calculate menu selector limits, min/max y and selector x co-ords (not physical screen x,y positions)
                                bsr.w   set_menu_selector_sprite_positions      ; set initial x,y positions of menu selector sprites (physical screen x,y positions)
                                bsr.w   clear_menu_display                      ; clear the menu bitplane ram
                                bsr.w   display_current_menu_text               ; write menu text into bitplane ram
                                rts


                        ; -------------------- Display Menu Text --------------------
                        ; Using the currently menu selected menu, write the menu
                        ; text into the bitplane ram.
display_current_menu_text       move.l  menu_current_ptr,a1
                                move.l  (a1),a0
                                move.l  #45,d0                                  ; standard menu text display width (45 characters)
                                move.l  #17,d1                                  ; standard text display height (17 characters)
                                bsr.w   display_text_string                     ; write text into bitplane memory
                                rts


                        ; ---------------- Initialise Menu Selector -----------------
                        ; Using the currently selected menu, set the virtual x,y
                        ; selector position and limits.
                        ; This is virtual menu space where x=0, y=0 is the top left
                        ; pixel of the menu.
                        ; Each text line is 8 pixels high, 
                        ; Each character is 7 pixels wide,
                        ; Giving a screen of 45 characters by 17 lines high for the
                        ; combined text and menu options.
                        ;
init_menu_selector
                                ; initialise menu selector x,y positions from menu definition data.
                                ; not physical display co-ords, these are co-ords into the character display (0,0 = top left)
                                ; these have to translated into sprite co-ords (i.e. adding physical screen borders and window disply offsets when updating sprite co-ords)
                                move.l  menu_current_ptr,a0
                                move.w  $4(a0),d0               ; 1st selectable line
                                mulu    #8,d0                   ; pixel start of 1st line = 8 x line number
                                move.w  d0,menu_selector_y
                                move.w  d0,menu_selector_min_y

                                move.w  $6(a0),d1               ; number of selectable lines
                                sub.w   #1,d1
                                mulu    #8,d1
                                add.w   d0,d1                   ; pixel start of last line = 1stline + (8 x number of lines)
                                move.w  d1,menu_selector_max_y

                                ; left menu selector x pos (into character screen)
                                move.w  $8(a0),d0                               ; left character of menu selector
                                mulu    #7,d0                                   ; 8 pixels wide characters
                                sub.w   #2,d0                                   ; adjust x to make visually appealing
                                move.w  d0,menu_selector_left_x

                                ; right sprite x pos
                                move.w  $a(a0),d1                               ; menu option character width 
                                mulu    #7,d1                                   ; 8 pixels wide characters
                                add.w   #8,d1                                   ; add the width of the selector sprite 
                                add.w   d0,d1
                                add.w   #2,d1                                   ; adjust x to make visually appealing
                                move.w  d1,menu_selector_right_x

                                rts



                ; ================================================================================
                ;  MENU MANAGEMENT
                ; ================================================================================








                ; ********************************************************************************
                ;  MAIN LOOP             
                ; ********************************************************************************
                ; new main loop, created to clean-up the state-management
main_loop
                                bsr     menu_mainloop_state_machine
                                bra     main_loop

                ; ********************************************************************************
                ;  MAIN LOOP             
                ; ********************************************************************************





                ; ---------------------- Do Nothing Interrupt Handler -------------------
                ; Inserted into unused interrupt vectors incase I switch on an interrupt
                ; by mistake. Flashes the screen if it's called.
do_nothing_interrupt_handler
                                MOVEM.L D0-D7/A0-A6,-(A7)

                                lea     $dff000,a6
                                move.w  #$100,d7
color_loop                      move.w  VHPOSR(a6),COLOR00(a6)
                                dbf     d7,color_loop

                                MOVEM.L (A7)+,D0-D7/A0-A6
                                RTE                     



                ; ----------------------- Level 3 Interrupt Handler ----------------
                ; VBL and COPER interrupt handler routine, intended to be called
                ; ones per frame.
                ; new level 3 interrupt handler, rewritten for better state management
level_3_interrupt_handler
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


                                bsr     menu_interrupt_state_machine

.exit_handler    
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
                        ; IN:   a0.l - text to type ptr
                        ;
display_text_string             move.l  a0,a3
                                move.w  #0,character_x_pos
                                move.w  #0,character_y_offset
                                lea.l   menu_typer_bitplane,a0
                                lea.l   menu_font_gfx,a2

                        ; ------------------------- display text -------------------------
                        ; IN:   a0 - typer bitplane
                        ;       a2 - font_gfx
                        ;       a3 - display text
                        ;       d7 - type (x) characters wide
                        ;       d6 - type (x) characters tall 
display_text                    move.w  #$0000,character_x_pos                          ; reset x position
                                move.w  #$0000,character_y_offset                       ; reset y offset (line position)

.print_char_loop                moveq.l  #$00000000,d0
                                moveq.l  #$00000000,d1
                                moveq.l  #$00000000,d2
                                moveq.l  #$00000000,d3
                                moveq.l  #$00000000,d4

.process_ascii_char             ; process ascii character
                                move.b  (a3)+,d0                        ; get ascii char value
                                cmp.b   #$ff,d0                         ; text display terminator
                                beq     .exit_display_text
                                cmp.b   #$0a,d0                         ; line feed
                                beq     .line_feed
                                cmp.b   #$0d,d0                         ; carriage return
                                beq     .carriage_return
                                cmp.b   #$20,d0                         ; space character
                                beq     .space_character
                                bra.s   .print_char

.line_feed                      add.w   #$0140,character_y_offset       ; increase y offset by 1 whole text line (8x40 bytes)
                                bra.s   .process_ascii_char

.carriage_return                move.w  #$0000,character_x_pos          ; reset x position (left hand side)
                                bra.s   .process_ascii_char

.space_character                add.w   #7,character_x_pos
                                bra.s   .process_ascii_char

.print_char                     SUB.B   #$20,D0                         ; font starts at 'space' char (32 ascii)

                                LSL.B   #$00000001,D0                   ; d0 = index to start of char gfx
                                LEA.L   (A2,D0.W),A4                    ; a4 = char gfx ptr
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
                                BRA.W   .shift_and_print_char
.is_even_byte_offset
                                MOVE.W  #$0000,D2

.shift_and_print_char           LEA.L   (A0,D1.W),A1                    ; a1 = dest ptr + x offset
                                MOVE.W  character_y_offset,D1
                                LEA.L   (A1,D1.W),A1                    ; a1 = dest ptr + y offset
                                MOVE.L  $0000(A4),D0                    ; char line 1
                                AND.L   #$ffff0000,D0
                                ROR.L   D2,D0
                                ROR.L   D3,D0
                                OR.L    D0,$0000(A1)
                                MOVE.L  $0076(A4),D0                                    ; char line 2
                                AND.L   #$ffff0000,D0
                                ROR.L   D2,D0
                                ROR.L   D3,D0
                                OR.L    D0,$0028(A1)
                                MOVE.L  $00ec(A4),D0                                    ; char line 3
                                AND.L   #$ffff0000,D0
                                ROR.L   D2,D0
                                ROR.L   D3,D0
                                OR.L    D0,$0050(A1)
                                MOVE.L  $0162(A4),D0                                    ; char line 4
                                AND.L   #$ffff0000,D0
                                ROR.L   D2,D0
                                ROR.L   D3,D0
                                OR.L    D0,$0078(A1)
                                MOVE.L  $01d8(A4),D0                                    ; char line 5
                                AND.L   #$ffff0000,D0
                                ROR.L   D2,D0
                                ROR.L   D3,D0
                                OR.L    D0,$00a0(A1)
                                MOVE.L  $024e(A4),D0                                    ; char line 6
                                AND.L   #$ffff0000,D0
                                ROR.L   D2,D0
                                ROR.L   D3,D0
                                OR.L    D0,$00c8(A1)
                                MOVE.L  $02c4(A4),D0                                    ; char line 7
                                AND.L   #$ffff0000,D0
                                ROR.L   D2,D0
                                ROR.L   D3,D0
                                OR.L    D0,$00f0(A1)

                                ADD.W   #$0007,character_x_pos                          ; add character width to x position
                                bra.w   .print_char_loop

                                MOVE.W  #$0000,character_x_pos                          ; reset x position (left hand side)
                                ADD.W   #$0140,character_y_offset                       ; increment line offset (8 rasters = 320 bytes)
                                ;MOVE.W  #$002c,D7                                       ; reset line loop counter (next 45 chars)
                                bra.w   .print_char_loop                             ; do next line loop

.exit_display_text
                                MOVE.W  #$0000,character_x_pos                          ; reset x position
                                MOVE.W  #$0000,character_y_offset                       ; reset y offset (line position)
                                RTS 

character_x_pos                 dc.w    $0000                                           ; typer x - pixel position
character_y_offset              dc.w    $0000                                           ; typer - y - offset (multiple of bytes per raster)




                        ; --------------------- fade in menu display text ----------------------
                        ; Fades in the text colour of the menu text display. 
                        ; This routine sets the colour in the copper list for the value where
                        ; the text does not overlap the vector logo in the backround.
                        ; A separate routine is used to blend the vector colour with the text
                        ; colour when it fades in/out to give an alpha type effect.
                        ; This routine does set the colour used by the alpha routine in the
                        ; menu_text_fade_colour_copy variable.
                        ;
fade_in_menu_display            LEA.L   copper_menu_fade_colour,a0 
                                MOVE.W  $0002(A0),D0                                    ; get current colour from copper list
.calc_blue_component
                                MOVE.W  D0,D1
                                AND.W   #$000f,D1
                                CMP.W   #$000f,D1
                                BEQ.B   .calc_green_component 
                                ADD.W   #$0001,$0002(A0)                                ; update colour reg in copper list
.calc_green_component
                                MOVE.W  D0,D1
                                AND.W   #$00f0,D1
                                CMP.W   #$00f0,D1
                                BEQ.B   .calc_red_component  
                                ADD.W   #$0010,$0002(A0)                                ; update colour reg in copper list
.calc_red_component
                                MOVE.W  D0,D1
                                AND.W   #$0f00,D1
                                CMP.W   #$0f00,D1
                                BEQ.B   .set_blend_copy_colour  
                                ADD.W   #$0100,$0002(A0)                                ; update colour reg in copper list
.set_blend_copy_colour   ; set the copy of the colour for the blend fade routine
                                MOVE.W  menu_text_fade_colour_copy,d0 
                                CMP.W   #$0fff,D0
                                BEQ.B   .update_fade_count 
                                ADD.W   #$0111,menu_text_fade_colour_copy               ; increment current fade colour
.update_fade_count
                                ADD.B   #$01,fade_counter
                                CMP.B   #$10,fade_counter
                                BNE.B   .fade_in_not_complete

.set_fade_in_complete           MOVE.W  #$0000,fade_counter
                                moveq   #0,d0                                           ; z = 1 - Fade has completed
                                rts
                           
.fade_in_not_complete           moveq   #-1,d0                                          ; z = 0 - Fade has NOT completed
                                RTS 




                        ; --------------------- fade out menu display text ----------------------
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
                        ; OUT:
                        ;       d0 - Equals $0 for Fade Completed
                        ;
fade_out_menu_display           LEA.L   copper_menu_fade_colour,a0
                                MOVE.W  $0002(A0),D0                                    ; get current colour value from copper list
.calc_blue_component
                                MOVE.W  D0,D1
                                AND.W   #$000f,D1
                                CMP.W   #$0002,D1
                                BEQ.B   .calc_green_component
                                SUB.W   #$0001,$0002(A0)
.calc_green_component
                                MOVE.W  D0,D1
                                AND.W   #$00f0,D1
                                CMP.W   #$0000,D1
                                BEQ.B   .calc_red_component
                                SUB.W   #$0010,$0002(A0)
.calc_red_component
                                AND.W   #$0f00,D0
                                CMP.W   #$0000,D0
                                BEQ.B   .set_blend_copy_colour
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
                                MOVE.W  #$0000,fade_counter
                                move.l  #0,d0
                                rts

.fade_in_not_complete
                                move.l  #-1,d0
                                RTS 



fade_counter            ; original address L00020742 - used to measure if the fade is complete (after 16 fade levels)
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
clear_menu_display              LEA.L   menu_typer_bitplane,a0
                                MOVE.W  #$0009,D7                       ; loop counter 9+1
                                MOVE.W  #$0087,D6
                                MOVE.L  #$00000000,D0
.clear_loop                     MOVE.L  D0,(A0)+
                                DBF.W   D7,.clear_loop 
                                MOVE.W  #$0009,D7
                                DBF.W   D6,.clear_loop 
                                RTS 




                ; ----------------- Update Menu Selector Position -------------------
                ; Get mouse input and position the left/right arrows that are used
                ; to select the menu items from the on-screen menu selections.
                ;
                ; TODO: make this routiun just keep track of mouse delta movements
                ;       remove menu dependencies code.
                ;
update_menu_selector_position   ; original address L000207EA
                                MOVE.L  #$00000000,D0
                                MOVE.L  #$00000000,D1
                                MOVE.B  CUSTOM+JOY0DAT,D0                       ; read mouse y-axis counter 
                                MOVE.B  mouse_y_value,d1                        ; last read y-axis counter
                                MOVE.B  D0,mouse_y_value                        ; update last y-axis counter value
                                SUB.W   D0,D1                                   ; get difference between current counter and last read value,
                                CMP.W   #$ff80,D1                               ; compare -128
                                BLT.B   underflow_y_wrap                        ; the mouse counter value has wrapped (underflow)
                                CMP.W   #$007f,D1                               ; compare +127
                                BGT.B   overflow_y_wrap                         ; the mouse counter value has wrapped (overflow)
                                BRA.B   update_menu_selector_y

                        ; mouse counter overflow +ve
overflow_y_wrap         ; original address L00020810
                                SUB.W   #$0100,D1                               ; wrap mouse y value
                                BRA.B   update_menu_selector_y

                        ; mouse counter underflow -ve
underflow_y_wrap        ; original address L00020816
                                ADD.W   #$0100,D1                               ; wrap mouse y value

                        ;
                        ; ***** TODO: remove menu display dependency from this code
update_menu_selector_y  ; original address L0002081A
                                ASR.W   #$00000001,D1                           ; divide the amount by 2 (make movement less sensitive)
                                NEG.W   D1
                                ADD.W   D1,menu_selector_y                      ; update current menu selector_y
                                MOVE.W  menu_selector_y,D0
                                MOVE.W  menu_selector_min_y,D1
                                CMP.W   D1,D0
                                BLT.W   clamp_min_y
                                MOVE.W  menu_selector_max_y,D1
                                CMP.W   D1,D0
                                BGT.W   clamp_max_y 
                                rts

clamp_max_y             ; original address L00020844
                                MOVE.W  menu_selector_max_y,menu_selector_y     ; clamp mouse y limit
                                rts

clamp_min_y             ; original address L00020850
                                MOVE.W  menu_selector_min_y,menu_selector_y     ; clamp mouse y limit
                                rts

SPRITE_MENU_X_WINDOW_START       EQU     $80
SPRITE_MENU_Y_WINDOW_START       EQU     $71                                     ; $71 = 113 (start of typer bitplane raster start in view window/copper vertical wait $7101,$FFFE)

set_menu_selector_sprite_positions
                                LEA.L   menu_sprite_left,A0                     ; left sprite
                                LEA.L   menu_sprite_right,A1                    ; right sprite
                                MOVE.W  menu_selector_y,D0

                                ; set menu selector y-axis positions
                                ADD.W   #SPRITE_MENU_Y_WINDOW_START,D0          ; Add vertical window start position to the selector_y value
                                MOVE.B  D0,(A0)
                                MOVE.B  D0,(A1)
                                ADD.B   #$07,D0
                                MOVE.B  D0,$0002(A0)
                                MOVE.B  D0,$0002(A1)

                                ; set left selector x-axis position
                                move.w  menu_selector_left_x,d0
                                add.w   #SPRITE_MENU_X_WINDOW_START,d0          ; add left window x start
                                lsr.w   #1,d0                                   ; divide total by 2 (hpos1 holds sprite position to a resolution of 2 pixels per unit value)                       
                                move.b  d0,left_sprite_hpos1
                                move.b  #$01,left_sprite_hpos2                  ; hpos2 holds the LSB of sprite horizontal position (odd/even horizontal position - single pixel resolution) 

                                ; set right selector x-axis position
                                move.w  menu_selector_right_x,d0
                                add.w   #SPRITE_MENU_X_WINDOW_START,d0          ; add left window x start
                                lsr.w   #1,d0                                   ; divide total by 2 (hpos1 holds sprite position to a resolution of 2 pixels per unit value)                       
                                move.b  d0,right_sprite_hpos1
                                move.b  #$01,right_sprite_hpos2                  ; hpos2 holds the LSB of sprite horizontal position (odd/even horizontal position - single pixel resolution) 
                          
                                ; set menu selector x-axis positons
                                MOVE.B  left_sprite_hpos1,$0001(A0)
                                MOVE.B  left_sprite_hpos2,$0003(A0)
                                MOVE.B  right_sprite_hpos1,$0001(A1)
                                MOVE.B  right_sprite_hpos2,$0003(A1)

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
                                dc.w    $0000                   ; menu selector Y position into character view - 0 = top line (not physical display co-ords)
menu_selector_left_x            dc.w    $0000                   ; left menu selector X position into character view - 0 = left hand side (not physical displat co-ords)
menu_selector_right_x           dc.w    $0000                   ; right menu selector X position into character view - 0 = left hand side (not physical displat co-ords)


; sprite menu pointer control word values (used to set sprite control word values directly)
left_sprite_hpos1               dc.b    $6c     ; left sprite hvalue (bit 2-9 of hpos)
left_sprite_hpos2               dc.b    $01     ; left sprite hvalue (bit 1 of hpos)
right_sprite_hpos1              dc.b    $a9     ; right sprite hvalue (bit 2-9 of hpos)
right_sprite_hpos2              dc.b    $01     ; right sprite hvalue (bit 1 of hpos)








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



                ; ************************************************************************************
                ;  DISK / LOADER ROUTINES
                ; ************************************************************************************

                ; file table structure - definition
                ; Offset        Description
                ; 0             FileID	
                ; 4             Byte Offset to file start
                ; 8             PackedSize (unused $0)	
                ; C             File Size in Bytes
FTAB_FILE_ID            EQU $0
FTAB_FILE_OFFSET        EQU $4
FTAB_FILE_PACKED        EQU $8
FTAB_FILE_SIZE          EQU $C

                even
                ; disk file table 4 long words per file entry
                ; Offset        Description
                ; 0             FileID	
                ; 4             Byte Offset to file start
                ; 8             PackedSize (unused $0)	
                ; C             File Size in Bytes
                ;       
disk_file_table
disk_1_file_table_packed_delta
                dcb.l   4*27                    ; disk file table 4 long words per file entry




                ; ---------------------- load music -----------------------
                ; mfm track loader.
                ; load a music file from disk, checks the disk number
                ; in the drive and waits for the correct disk.
                ;
                ; IN:
                ;       a0.l = ptr to file id
                ;
load_music                      movem.l d0-d7/a0-a6,-(a7)               ; save all registers

                                move.l  (a0),d0                         ; get file id to load from parameters ptr passed in
                                move.w  #27-1,d7                        ; size of file table (27 entries)
                                lea     disk_file_table,a3              ; disk file table, see infinitedreams.adf.filetable.txt

.find_file              ; find file id (d0) in file table
                                cmp.l   (a3),d0                         ; have we found the fileid?
                                beq     .load_file                      ; ...yes, then load it.
                                lea     $10(a3),a3                      ; try next file table entry
                                dbra    d7,.find_file                   ; check next table entry.

.load_error         ; load error
                                move.w  #$f00,$dff180                   ; turn screen red
                                bra.s   .load_error                     ; loop forever.

.load_file          ; load file from disk
                                move.l  FTAB_FILE_OFFSET(a3),d0         ; disk byte offset
                                move.l  FTAB_FILE_SIZE(a3),d1           ; disk file length
                                moveq   #$00000000,d2                   ; drive 0
                                lea     BUFFER_LOW,a0                   ; load address for module.zx0
                                lea     MFM_BUFFER,a1                   ; raw mfm track buffer
                                bsr     loader_4489
                                tst.l   d0                              ; test for load error
                                bne.s   .load_error                     ; some kinda disk error.

                                ; DECOMPRESS ZXO
                                lea     BUFFER_LOW,a0                   ; ptr to module.zx0
                                lea     BUFFER_HIGH,a1                  ; ptr to decompression buffer (delta4 module)
                                movem.l a0/a1,-(a7)
                                jsr     uncompress_zx0
                                movem.l (a7)+,a0/a1

                                ; DECOMPRESS DELTA 4
                                lea     BUFFER_HIGH,a0                  ; delta 4 compressed file start
                                lea     BUFFER_LOW,a1                   ; output buffer for decompressed module destination
                                jsr     depackdelta4

                                movem.l (a7)+,d0-d7/a0-a6
                                rts



load_error                      lea     $dff000,a6
.error                          move.w  VHPOSR(a6),$dff180
                                jmp     .error


depack_delta_4
                include "deltapacker/depackdelta4.s"


loader_4489
                include "4489Loader/4489_byteloader.s"
                ;include "4489Loader/4489_byteloader_code.s"

;  in:  a0 = start of compressed data
;       a1 = start of decompression buffer
;zx0_decompress:
uncompress_zx0
                        include "zx0/unzx0_68000.s"


                ; ************************************************************************************
                ;  DISK / LOADER ROUTINES
                ; ************************************************************************************






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








                ;---------------------------------------------------------------------------------------------------------------------
                ; DATA DRIVEN MENU SYSTEM
                ;---------------------------------------------------------------------------------------------------------------------

                        ; ------------------- load and play protracker module ---------------------
                        ; Command Function called by the menu configuration.
                        ; It receives it's function parameters as a pointer in a0.l
                        ; The Parameters are set in the Menu Configuration for
                        ; the selected option.
                        ;
                        ; IN: 
                        ;       a0.l = parameters from menu options (ptr to file id)
load_and_play_module
                                movem.l a0,-(a7)                ; save menu option parameter on the stack

                                lea     CUSTOM,a6               ; end any music currently playing.
                                jsr     _mt_end                               
                                
                                lea     CUSTOM,a6               ; remove the CIA player from the interrupt handler (maybe able to prevent this)
                                jsr     _mt_remove

                                movem.l (a7)+,a0                ; get saved menu option parameter from stack
                                jsr     load_music              ; load and depack module

                                lea     CUSTOM,a6               ; install CIA player's interrupt handler etc.
                                lea     $0,a0
                                move.L  #$1,d0
                                JSR     _mt_install

                                lea     CUSTOM,a6               ; initialise and start playing the loaded module.
                                lea     MUSIC_BUFFER,a0
                                lea     $0,a1
                                move.l  #$0,d0
                                JSR     _mt_init

                                move.b  #$ff,_mt_Enable         ; enable playing.
                                rts



MNUCMD_MENU     EQU     $0              ; selecting this option displays another menu.
MNUCMD_FUNCTION EQU     $1              ; execute function
MNUCMD_NOP      EQU     $2              ; no operation (blank menu option)

menu_current_ptr                dc.l    main_menu_definition                    ; ptr to current menu for/being displayed


                        ; -------------------------------------------------
                        ; -------------- MAIN MENU DEFINITION -------------
                        ;--------------------------------------------------
main_menu_definition            dc.l    main_menu_text
                                dc.w    5                                               ; 1st selectable line number (0 index)
                                dc.w    7                                               ; number of selectable options
                                dc.w    13,18                                           ; left selector char pos, options char width.
                                dc.l    MNUCMD_MENU,music_menu_1_definition,$0          ; option 1, display menu
                                dc.l    MNUCMD_MENU,music_menu_2_definition,$0          ; option 2, display menu
                                dc.l    MNUCMD_MENU,music_menu_3_definition,$0          ; option 3, display menu
                                dc.l    MNUCMD_MENU,credits_menu_definition,$0          ; option 4, display menu
                                dc.l    MNUCMD_MENU,greetings_menu_new_definition,$0    ; option 5, display menu
                                dc.l    MNUCMD_MENU,addresses_menu_1_definition,$0      ; option 6, display menu
                                dc.l    MNUCMD_MENU,pd_message_menu_definition,$0       ; option 7, display menu

                                ; menu format = 45 x 17 characters max
main_menu_text                  ;        123456789012345678901234567890123456789012345
                                dc.b    $0d,$0a
                                dc.b    '  - THE LUNATICS PRESENT INFINITE DREAMS -',$0d,$0a
                                dc.b    '            SINGLE DISK VERSION.',$0d,$0a  
                                dc.b    $0d,$0a
                                dc.b    $0d,$0a               
                                dc.b    '              MUSIC    HOLLYWOOD',$0d,$0a           
                                dc.b    '              MUSIC   SUBCULTURE',$0d,$0a
                                dc.b    '              MUSIC REEAL/PHASER',$0d,$0a
                                dc.b    '                 DEMO CREDITS',$0d,$0a
                                dc.b    '                OUR  GREETINGS',$0d,$0a
                                dc.b    '              CONTACT  ADDRESSES',$0d,$0a
                                dc.b    '                 P.D. MESSAGE',$0d,$0a             
                                dc.b    $0d,$0a
                                dc.b    '      USE MOUSE TO SELECT TUNE TO PLAY',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '                          *1992-2025 LUNATICS',$0d,$0a   
                                dc.b    '               HTTPS://GITHUB.COM/MARKYTURTLE',$ff
                                even


                        ; -------------------------------------------------
                        ; ------------ MUSIC MENU 1 DEFINITION ------------
                        ;--------------------------------------------------
music_menu_1_definition         dc.l    music_menu_1_text
                                dc.w    4                                                               ; 1st selectable line number (0 index)
                                dc.w    12                                                              ; number of selectable options
                                dc.w    6,31                                                            ; left selector char pos, options char width.
                                dc.l    MNUCMD_FUNCTION,load_and_play_module,params_jarresque           ; option 1, load music
                                dc.l    MNUCMD_FUNCTION,load_and_play_module,params_silence             ; option 2, load music
                                dc.l    MNUCMD_FUNCTION,load_and_play_module,params_retouche            ; option 3, load music
                                dc.l    MNUCMD_FUNCTION,load_and_play_module,params_techwar             ; option 4, load music
                                dc.l    MNUCMD_FUNCTION,load_and_play_module,params_bright              ; option 5, load music
                                dc.l    MNUCMD_FUNCTION,load_and_play_module,params_reality             ; option 6, load music
                                dc.l    MNUCMD_FUNCTION,load_and_play_module,params_obilteration        ; option 7, load music
                                dc.l    MNUCMD_FUNCTION,load_and_play_module,params_skyriders           ; option 8, load music
                                dc.l    MNUCMD_FUNCTION,load_and_play_module,params_gravity             ; option 9, load music
                                dc.l    MNUCMD_FUNCTION,load_and_play_module,params_breakthrough        ; option 10, load music
                                dc.l    MNUCMD_NOP,$0,$0                                                ; option 11, NOP
                                dc.l    MNUCMD_MENU,main_menu_definition,$0                             ; option 12, display menu
params_jarresque                dc.l    'jarr'
params_silence                  dc.l    'soun' 
params_retouche                 dc.l    'reto' 
params_techwar                  dc.l    'tech' 
params_bright                   dc.l    'brig'
params_reality                  dc.l    'natu'
params_obilteration             dc.l    'obli'
params_skyriders                dc.l    'skyr'
params_gravity                  dc.l    'zero'
params_breakthrough             dc.l    'brea'

music_menu_1_text               ;        123456789012345678901234567890123456789012345
                                dc.b    $0d,$0a             
                                dc.b    '             MUSIC BY HOLLYWOOD',$0d,$0a
                                dc.b    $0d,$0a              
                                dc.b    $0d,$0a
                                dc.b    '       JARRESQUE           - HOLLYWOOD',$0d,$0a
                                dc.b    '       SOUND OF SILENCE    - HOLLYWOOD',$0d,$0a
                                dc.b    '       RETOUCHE            - HOLLYWOOD',$0d,$0a 
                                dc.b    '       TECHWAR             - HOLLYWOOD',$0d,$0a
                                dc.b    '       BRIGHT              - HOLLYWOOD',$0d,$0a
                                dc.b    '       NATURAL REALITY     - HOLLYWOOD',$0d,$0a
                                dc.b    '       OBLITERATION FIN    - HOLLYWOOD',$0d,$0a 
                                dc.b    '       SKYRIDERS           - HOLLYWOOD',$0d,$0a
                                dc.b    '       ZERO GRAVITY        - HOLLYWOOD',$0d,$0a
                                dc.b    '       BREAK THROUGH       - HOLLYWOOD',$0d,$0a 
                                dc.b    $0d,$0a
                                dc.b    '             RETURN TO MAIN MENU',$ff

                                even


                        ; -------------------------------------------------
                        ; ------------ MUSIC MENU 2 DEFINITION ------------
                        ;--------------------------------------------------
music_menu_2_definition         dc.l    music_menu_2_text
                                dc.w    4                                                               ; 1st selectable line number (0 index)
                                dc.w    11                                                              ; number of selectable options
                                dc.w    4,35                                                            ; left selector char pos, options char width.
                                dc.l    MNUCMD_FUNCTION,load_and_play_module,params_shaft               ; option 1, load music
                                dc.l    MNUCMD_FUNCTION,load_and_play_module,params_lovemoney           ; option 2, load music
                                dc.l    MNUCMD_FUNCTION,load_and_play_module,params_cosmic              ; option 3, load music
                                dc.l    MNUCMD_FUNCTION,load_and_play_module,params_notrave             ; option 4, load music
                                dc.l    MNUCMD_FUNCTION,load_and_play_module,params_ballbearing         ; option 5, load music
                                dc.l    MNUCMD_FUNCTION,load_and_play_module,params_thefly              ; option 6, load music
                                dc.l    MNUCMD_FUNCTION,load_and_play_module,params_stratospheric       ; option 7, load music
                                dc.l    MNUCMD_FUNCTION,load_and_play_module,params_float               ; option 8, load music
                                dc.l    MNUCMD_FUNCTION,load_and_play_module,params_flight              ; option 9, load music
                                dc.l    MNUCMD_NOP,$0,$0                                                ; option 10, NOP
                                dc.l    MNUCMD_MENU,main_menu_definition,$0                             ; option 11, display menu
params_shaft                    dc.l    'shaf' 
params_lovemoney                dc.l    'love' 
params_cosmic                   dc.l    'cosm' 
params_notrave                  dc.l    'this' 
params_ballbearing              dc.l    'eatt' 
params_thefly                   dc.l    'thef'
params_stratospheric            dc.l    'stra'
params_float                    dc.l    'floa'
params_flight                   dc.l    'flig'

music_menu_2_text               ;        123456789012345678901234567890123456789012345
                                dc.b    $0d,$0a           
                                dc.b    '            MUSIC BY SUBCULTURE',$0d,$0a
                                dc.b    $0d,$0a               
                                dc.b    $0d,$0a
                                dc.b    '     SHAFT                  - SUBCULTURE',$0d,$0a              
                                dc.b    '     LOVE YOUR MONEY        - SUBCULTURE',$0d,$0a
                                dc.b    '     COSMIC HOW MUCH        - SUBCULTURE',$0d,$0a
                                dc.b    '     NOT A RAVE SONG        - SUBCULTURE',$0d,$0a 
                                dc.b    '     EAT THE BALLBEARING    - SUBCULTURE',$0d,$0a
                                dc.b    '     THE FLY                - SUBCULTURE',$0d,$0a
                                dc.b    '     STRATOSPHERIC CITY     - SUBCULTURE',$0d,$0a
                                dc.b    '     FLOAT                  - SUBCULTURE' ,$0d,$0a
                                dc.b    '     FLIGHT-SLEEPY MIX      - SUBCULTURE',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '            RETURN TO MAIN MENU',$ff
                                even


                        ; -------------------------------------------------
                        ; ------------ MUSIC MENU 3 DEFINITION ------------
                        ;--------------------------------------------------
music_menu_3_definition         dc.l    music_menu_3_text
                                dc.w    6                                                               ; 1st selectable line number (0 index)
                                dc.w    6                                                               ; number of selectable options
                                dc.w    4,35                                                            ; left selector char pos, options char width.
                                dc.l    MNUCMD_FUNCTION,load_and_play_module,params_mental              ; option 1, load music
                                dc.l    MNUCMD_FUNCTION,load_and_play_module,params_blade               ; option 2, load music
                                dc.l    MNUCMD_FUNCTION,load_and_play_module,params_sweden              ; option 3, load music
                                dc.l    MNUCMD_FUNCTION,load_and_play_module,params_toomuch             ; option 4, load music
                                dc.l    MNUCMD_NOP,$0,$0                                                ; option 5, NOP
                                dc.l    MNUCMD_MENU,main_menu_definition,$0                             ; option 6, display menu
params_mental                   dc.l    'ment'
params_blade                    dc.l    'blad'
params_sweden                   dc.l    'summ'
params_toomuch                  dc.l    'neve'

music_menu_3_text               ;        123456789012345678901234567890123456789012345
                                dc.b    $0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '           MUSIC BY REEAL/PHASER',$0d,$0a              
                                dc.b    $0d,$0a
                                dc.b    $0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '     MENTAL OBSTACLE            - REEAL',$0d,$0a              
                                dc.b    '     BLADE RUNNER               - REEAL',$0d,$0a
                                dc.b    '     SUMMER IN SWEDEN           - PHASER',$0d,$0a
                                dc.b    '     NEVER TOO MUCH             - PHASER',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '            RETURN TO MAIN MENU',$ff 
                                even


                        ; -------------------------------------------------
                        ; ------------ CREDITS MENU DEFINITION ------------
                        ;--------------------------------------------------
credits_menu_definition         dc.l    credits_menu_text
                                dc.w    15                                              ; 1st selectable line number (0 index)
                                dc.w    1                                               ; number of selectable options
                                dc.w    12,19                                           ; left selector char pos, options char width.
                                dc.l    MNUCMD_MENU,main_menu_definition,$0             ; option 1, display menu

credits_menu_text               ;        123456789012345678901234567890123456789012345
                                dc.b    $0d,$0a  
                                dc.b    '        CODING - SPONGEHEAD (MARKYTURTLE)',$0d,$0a   
                                dc.b    '           GFX - JOE',$0d,$0a 
                                dc.b    '                 T.S.M',$0d,$0a 
                                dc.b    '         MUSIC - HOLLYWOOD',$0d,$0a 
                                dc.b    '                 SUBCULTURE',$0d,$0a 
                                dc.b    '                 PHASER',$0d,$0a 
                                dc.b    '                 REEAL',$0d,$0a 
                                dc.b    $0d,$0a  
                                dc.b    '  SALVADOR                COMPRESSION TOOLS',$0d,$0a 
                                dc.b    '  HEMIYODA                DELTA COMPRESSION',$0d,$0a 
                                dc.b    '  H0FFMAN    DISK BUILDER, PT TOOLS, ADVICE',$0d,$0a 
                                dc.b    '  4489              REPLACEMENT DISK LOADER',$0d,$0a 
                                dc.b    '  PAUL RAINGEARD            VSCODE ASSEMBLY',$0d,$0a 
                                dc.b    $0d,$0a 
                                dc.b    '             RETURN TO MAIN MENU',$ff  
                                even


                        ; -------------------------------------------------
                        ; --------- GREETINGS MENU NEW DEFINITION ---------
                        ;--------------------------------------------------
greetings_menu_new_definition   dc.l    greetings_menu_new_text
                                dc.w    16                                              ; 1st selectable line number (0 index)
                                dc.w    1                                               ; number of selectable options
                                dc.w    28,11                                           ; left selector char pos, options char width.
                                dc.l    MNUCMD_MENU,greetings_menu_1_definition,$0      ; option 1, display menu

greetings_menu_new_text          ;        123456789012345678901234567890123456789012345
                                dc.b    '          ---   !    :               TTE!    ',$0d,$0a
                                dc.b    '       --!   !- !-   !--.-------      TTE!   ',$0d,$0a
                                dc.b    '       -/    /  T    /  !   /--/       TTE!  ',$0d,$0a
                                dc.b    '       +    /  -!- -/   !  --/----      TTE! ',$0d,$0a
                                dc.b    '----    +--------/------+--------/ .----     ',$0d,$0a
                                dc.b    '+  !---            --  ---         !  -/     ',$0d,$0a
                                dc.b    ' +    /  ----  ----+/- + !-- ------!- !---   ',$0d,$0a
                                dc.b    ' / --/- / --/-/-  !  !  ---/-   ----/  /  T  ',$0d,$0a
                                dc.b    '/  /  -!   --    -!  !  /   -! (---:  /   !- ',$0d,$0a
                                dc.b    '+      +---/+----+!--!-------+----/!-/    ++ ',$0d,$0a
                                dc.b    ' +------+          ---  ---        !NE7---// ',$0d,$0a
                                dc.b    '      -------- --  .\ /--\ !-- --------      ',$0d,$0a
                                dc.b    '     /  --   /  /--! 7 -- --/-   --   /      ',$0d,$0a
                                dc.b    '    /    /--/  /   !  !/  /   !   /--/       ',$0d,$0a
                                dc.b    '   / ---/--.  /   -! -/  /   -!  --/---      ',$0d,$0a
                                dc.b    '   +   /   !------+ +--------+--------/      ',$0d,$0a
                                dc.b    '    +------!      .  :       MORE GREETZ     ',$ff
                                even

                        ; -------------------------------------------------
                        ; ---------- GREETINGS MENU 1 DEFINITION ----------
                        ;--------------------------------------------------
greetings_menu_1_definition     dc.l    greetings_menu_1_text
                                dc.w    15                                              ; 1st selectable line number (0 index)
                                dc.w    2                                               ; number of selectable options
                                dc.w    11,19                                           ; left selector char pos, options char width.
                                dc.l    MNUCMD_MENU,greetings_menu_2_definition,$0      ; option 1, display menu
                                dc.l    MNUCMD_MENU,main_menu_definition,$0             ; option 2, display menu

greetings_menu_1_text           ;        123456789012345678901234567890123456789012345
                                dc.b    ' ADDONIC - AGILE - AGNOSTIC FRONT AND PANIC',$0d,$0a
                                dc.b    $0d,$0a  
                                dc.b    'ALCATRAZ - ALCHEMY - ALLIANCE - ALPHA FLIGHT',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    ' AMAZE - ANAL INTRUDERS - ANARCHY - ANTHROX',$0d,$0a
                                dc.b    $0d,$0a 
                                dc.b    'APOCALYPSE - ARCHAOS - ASSSASSINS - ATLANTIS',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '    AURORA - AWAKE - BLACK ROBES - CHROME',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '   COLLISION - COMPLEX - CRASHEAD - CRYSTAL',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    'CYTAX - DAMAGE INC - DAMONES - DECAY - DESIRE',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '                MORE GREETZ',$0d,$0a
                                dc.b    '            RETURN TO MAIN MENU',$ff  
                                even

      
                                even

                        ; -------------------------------------------------
                        ; ---------- GREETINGS MENU 2 DEFINITION ----------
                        ;--------------------------------------------------
greetings_menu_2_definition     dc.l    greetings_menu_2_text
                                dc.w    15                                              ; 1st selectable line number (0 index)
                                dc.w    2                                               ; number of selectable options
                                dc.w    11,19                                           ; left selector char pos, options char width.
                                dc.l    MNUCMD_MENU,greetings_menu_3_definition,$0      ; option 1, display menu
                                dc.l    MNUCMD_MENU,main_menu_definition,$0             ; option 2, display menu

greetings_menu_2_text           ;        123456789012345678901234567890123456789012345
                                dc.b    ' DEVILS - DIMENSION X - DISKNET - DUAL CREW',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '   DYNAMIK - ECLIPSE - END OF CENTURY 1999',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '   ENERGY - EQUINOX - FAIRLIGHT - FRANTIC',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '   FUSION - GHOST - GRACE - GUARDIAN ANGEL',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '       HARDLINE - HYSTERIA - INFINITY',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '    ITALIAN BAD BOYS - JESTERS - KEFRENS',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    'LA ROCCA - LEGEND - LIVE ACT - LOGIC SYSTEMS',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '                MORE GREETZ',$0d,$0a
                                dc.b    '            RETURN TO MAIN MENU',$ff       
                                even

                        ; -------------------------------------------------
                        ; ---------- GREETINGS MENU 3 DEFINITION ----------
                        ;--------------------------------------------------
greetings_menu_3_definition     dc.l    greetings_menu_3_text
                                dc.w    15                                              ; 1st selectable line number (0 index)
                                dc.w    2                                               ; number of selectable options
                                dc.w    11,19                                           ; left selector char pos, options char width.
                                dc.l    MNUCMD_MENU,greetings_menu_4_definition,$0      ; option 1, display menu
                                dc.l    MNUCMD_MENU,main_menu_definition,$0             ; option 2, display menu

greetings_menu_3_text           ;        123456789012345678901234567890123456789012345
                                dc.b    '       LSD - LYNX - MAGIC 12 - MIRAGE',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '     NEMISIS - NOXIOUS - ORIGIN - PALACE',$0d,$0a
                                dc.b    $0d,$0a 
                                dc.b    '  PARADISE - PARAGON - PHANTASM - PHANTASY',$0d,$0a
                                dc.b    $0d,$0a  
                                dc.b    'PHASE - PLASMA - POLARIS - PURE METAL CODERS',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '  QUARTEX - QUARTZ - RAM JAM - RAF - RAZOR',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '  REALITY - REBELS - REDNEX - RELAY - RICH',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '   RIP MASTERS - RUBBER RADISH - SCANDAL',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '                MORE GREETZ',$0d,$0a
                                dc.b    '            RETURN TO MAIN MENU',$ff  
                                even

                        ; -------------------------------------------------
                        ; ---------- GREETINGS MENU 4 DEFINITION ----------
                        ;--------------------------------------------------
greetings_menu_4_definition     dc.l    greetings_menu_4_text
                                dc.w    16                                              ; 1st selectable line number (0 index)
                                dc.w    1                                               ; number of selectable options
                                dc.w    11,19                                           ; left selector char pos, options char width.
                                dc.l    MNUCMD_MENU,main_menu_definition,$0             ; option 1, display menu

greetings_menu_4_text           ;        123456789012345678901234567890123456789012345
                                dc.b    '  SCOOPEX - SHINING - SHINING 8 - SILENTS',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    'SILICON LTD - SKID ROW - SLIPSTREAM - SONIC',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    'SPREADPOINT - STAX - SUPPLEX - TALENT - TECH',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    ' SUPRISE PRODUCTIONS - TRASH - TRIBE ',$0d,$0a
                                dc.b    $0d,$0a 
                                dc.b    'TRISTAR AND RED SECTOR INC - THE FLAME ARROWS',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    ' THE SPECIAL BROTHERS - VERMIN - VISION',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    ' VISION FACTORY - VOX DEI - VISUAL BYTES',$0d,$0a
                                dc.b    $0d,$0a  
                                dc.b    '      WIZZCAT - XENTEX - ZITE PRODUCTIONS',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '            RETURN TO MAIN MENU',$ff  
                                even

                        ; -------------------------------------------------
                        ; ---------- ADDRESSES MENU 1 DEFINITION ----------
                        ;--------------------------------------------------
addresses_menu_1_definition     dc.l    addresses_menu_1_text
                                dc.w    15                                              ; 1st selectable line number (0 index)
                                dc.w    1                                               ; number of selectable options
                                dc.w    13,14                                           ; left selector char pos, options char width.
                                dc.l    MNUCMD_MENU,addresses_menu_2_definition,$0      ; option 1, display menu

addresses_menu_1_text           ;        123456789012345678901234567890123456789012345
                                dc.b    '  THE LUNATICS "WERE" LOOKING FOR SOME MORE',$0d,$0a  
                                dc.b    '   MEMBERS AND COOOL DIVISIONS AROUND THE',$0d,$0a
                                dc.b    '  WORLD. TO SET UP A DIVISION WRITE TO THE',$0d,$0a
                                dc.b    '           FOLLOWING ADDRESS.....',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '               T.S.M',$0d,$0a
                                dc.b    '               ** ******* ****',$0d,$0a
                                dc.b    '               *******',$0d,$0a
                                dc.b    '               *** ****',$0d,$0a
                                dc.b    '               **** ***',$0d,$0a
                                dc.b    '               **',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '       TEL : *** ****** ****** (*****)',$0d,$0a
                                dc.b    '           ALSO -ELITE- SWAPPING!',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '              MORE ADDRESSES',$ff
                                even


                        ; -------------------------------------------------
                        ; ---------- ADDRESSES MENU 2 DEFINITION ----------
                        ;--------------------------------------------------
addresses_menu_2_definition     dc.l    addresses_menu_2_text
                                dc.w    15                                              ; 1st selectable line number (0 index)
                                dc.w    1                                               ; number of selectable options
                                dc.w    13,14                                           ; left selector char pos, options char width.
                                dc.l    MNUCMD_MENU,addresses_menu_3_definition,$0      ; option 1, display menu
                               
addresses_menu_2_text           ;        123456789012345678901234567890123456789012345
                                dc.b    '   TO JOIN THE UK DIVISION WRITE TO ONE OF',$0d,$0a  
                                dc.b    '           THE FOLLOWING ADDRESSES:-',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '    AZTEC               HOLLYWOOD',$0d,$0a
                                dc.b    '    ** ******** ***     ** ********* ***',$0d,$0a
                                dc.b    '    *******             **********',$0d,$0a
                                dc.b    '    *************       ******',$0d,$0a
                                dc.b    '    *** ***             *** ***',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '    ELITE SWAP ALSO     ELITE MUSIC SWAP',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    $0d,$0a
                                dc.b    $0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '              MORE ADDRESSES',$ff
                                even


                        ; -------------------------------------------------
                        ; ---------- ADDRESSES MENU 3 DEFINITION ----------
                        ;--------------------------------------------------
addresses_menu_3_definition     dc.l    addresses_menu_3_text
                                dc.w    15                                              ; 1st selectable line number (0 index)
                                dc.w    1                                               ; number of selectable options
                                dc.w    13,14                                            ; left selector char pos, options char width.
                                dc.l    MNUCMD_MENU,addresses_menu_4_definition,$0      ; option 1, display menu
                                                               
addresses_menu_3_text           ;        123456789012345678901234567890123456789012345 
                                dc.b    '    TO JOIN THE AUSTRIAN DIVISION WRITE TO',$0d,$0a  
                                dc.b    '       ONE OF THE FOLLOWING ADDRESSES:-',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '   RIP               NUKE',$0d,$0a
                                dc.b    '   ** *** **         ** *** **',$0d,$0a
                                dc.b    '   **** *******      ****** *******',$0d,$0a
                                dc.b    '   *******           *******',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '                     ALSO ELITE SWAP',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    $0d,$0a
                                dc.b    $0d,$0a
                                dc.b    $0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '              MORE ADDRESSES',$ff                             
                                even


  
                        ; -------------------------------------------------
                        ; ---------- ADDRESSES MENU 4 DEFINITION ----------
                        ;--------------------------------------------------
addresses_menu_4_definition     dc.l    addresses_menu_4_text
                                dc.w    15                                              ; 1st selectable line number (0 index)
                                dc.w    1                                               ; number of selectable options
                                dc.w    13,14                                           ; left selector char pos, options char width.
                                dc.l    MNUCMD_MENU,addresses_menu_5_definition,$0      ; option 1, display menu
                                                              
addresses_menu_4_text           ;        123456789012345678901234567890123456789012345
                                dc.b    '     TO JOIN THE DUTCH DIVISION WRITE TO',$0d,$0a 
                                dc.b    '          THE FOLLOWING ADDRESS:-',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '           SANE',$0d,$0a
                                dc.b    '           *************** **',$0d,$0a
                                dc.b    '           **** ** *********',$0d,$0a
                                dc.b    '           *******',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '           TEL : *** ******* *****',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '           ALSO ELITE SWAP',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    $0d,$0a
                                dc.b    $0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '              MORE ADDRESSES',$ff
                                even


                        ; -------------------------------------------------
                        ; ---------- ADDRESSES MENU 5 DEFINITION ----------
                        ;--------------------------------------------------
addresses_menu_5_definition     dc.l    addresses_menu_5_text
                                dc.w    15                                              ; 1st selectable line number (0 index)
                                dc.w    1                                               ; number of selectable options
                                dc.w    13,14                                           ; left selector char pos, options char width.
                                dc.l    MNUCMD_MENU,addresses_menu_6_definition,$0      ; option 1, display menu
                                 
addresses_menu_5_text           ;        123456789012345678901234567890123456789012345
                                dc.b    '  TO JOIN THE AUSTRALIAN DIVISION WRITE TO',$0d,$0a  
                                dc.b    '           THE FOLLOWING ADDRESS:-',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '           WOODY',$0d,$0a
                                dc.b    '           * ***** *****',$0d,$0a
                                dc.b    '           ********',$0d,$0a
                                dc.b    '           ******** ****',$0d,$0a
                                dc.b    '           **********',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '           ALSO -ELITE- SWAP',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    $0d,$0a
                                dc.b    $0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '              MORE ADDRESSES',$ff 
                                even


                        ; -------------------------------------------------
                        ; ---------- ADDRESSES MENU 6 DEFINITION ----------
                        ;--------------------------------------------------
addresses_menu_6_definition     dc.l    addresses_menu_6_text
                                dc.w    15                                              ; 1st selectable line number (0 index)
                                dc.w    1                                               ; number of selectable options
                                dc.w    11,19                                           ; left selector char pos, options char width.
                                dc.l    MNUCMD_MENU,main_menu_definition,$0             ; option 1, display menu

addresses_menu_6_text           ;        123456789012345678901234567890123456789012345
                                dc.b    '    TO JOIN THE SWEDISH DIVISION WRITE TO',$0d,$0a  
                                dc.b    '          THE FOLLOWING ADDRESS:-',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    $0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '           PHASER',$0d,$0a
                                dc.b    '           ********* **',$0d,$0a
                                dc.b    '           *** ** *********',$0d,$0a
                                dc.b    '           ******',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    $0d,$0a
                                dc.b    $0d,$0a
                                dc.b    $0d,$0a
                                dc.b    $0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '            RETURN TO MAIN MENU',$ff
                                even


                        ; -------------------------------------------------
                        ; ---------- PD MESSAGE MENU DEFINITION -----------
                        ;--------------------------------------------------
pd_message_menu_definition      dc.l    pd_message_menu_text
                                dc.w    15                                              ; 1st selectable line number (0 index)
                                dc.w    1                                               ; number of selectable options
                                dc.w    11,19                                           ; left selector char pos, options char width.
                                dc.l    MNUCMD_MENU,main_menu_definition,$0             ; option 1, display menu
                              
pd_message_menu_text            ;        123456789012345678901234567890123456789012345
                                dc.b    $0d,$0a
                                dc.b    '  THIS PAGE ORIGINALLY CONTAINED A MESSAGE',$0d,$0a
                                dc.b    '  TO P.D. COMPANIES AKSING THEM TO RESPECT',$0d,$0a
                                dc.b    '  THE AUTHORS COPYRIGHT.....',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '  A BIT RICH COMING FROM A GROUP THAT HAD',$0d,$0a
                                dc.b    '  MEMBERS SWAPPING WAREZ AROUND THE WORLD.',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '  WE WERE YOUNG AND NAIVE.......',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '           .....WISH I STILL WAS.....',$0d,$0a
                                dc.b    $0d,$0a
                                dc.b    $0d,$0a                          
                                dc.b    $0d,$0a
                                dc.b    $0d,$0a
                                dc.b    '            RETURN TO MAIN MENU',$ff
                                even


                                ; spare screen template for text typer/menu 45 x 17 characters
                                ;        123456789012345678901234567890123456789012345
                                dc.b    '                                             ',$0d,$0a 
                                dc.b    '                                             ',$0d,$0a
                                dc.b    '                                             ',$0d,$0a
                                dc.b    '                                             ',$0d,$0a
                                dc.b    '                                             ',$0d,$0a
                                dc.b    '                                             ',$0d,$0a
                                dc.b    '                                             ',$0d,$0a
                                dc.b    '                                             ',$0d,$0a
                                dc.b    '                                             ',$0d,$0a
                                dc.b    '                                             ',$0d,$0a
                                dc.b    '                                             ',$0d,$0a
                                dc.b    '                                             ',$0d,$0a
                                dc.b    '                                             ',$0d,$0a
                                dc.b    '                                             ',$0d,$0a
                                dc.b    '                                             ',$0d,$0a
                                dc.b    '                                             ',$0d,$0a
                                dc.b    '                                             ',$ff

                                ; spare screen template for text typer/menu 45 x 17 characters
                                ;        123456789012345678901234567890123456789012345
                                dc.b    '                                             ',$0d,$0a 
                                dc.b    '                                             ',$0d,$0a
                                dc.b    '                                             ',$0d,$0a
                                dc.b    '                                             ',$0d,$0a
                                dc.b    '                                             ',$0d,$0a
                                dc.b    '                                             ',$0d,$0a
                                dc.b    '                                             ',$0d,$0a
                                dc.b    '                                             ',$0d,$0a
                                dc.b    '                                             ',$0d,$0a
                                dc.b    '                                             ',$0d,$0a
                                dc.b    '                                             ',$0d,$0a
                                dc.b    '                                             ',$0d,$0a
                                dc.b    '                                             ',$0d,$0a
                                dc.b    '                                             ',$0d,$0a
                                dc.b    '                                             ',$0d,$0a
                                dc.b    '                                             ',$0d,$0a
                                dc.b    '                                             ',$ff




                                ;        123456789012345678901234567890123456789012345
                                dc.b    '          ___   |    :                       ',$0d,$0a
                                dc.b    '       __ \  |_ |_   |__.________            ',$0d,$0a
                                dc.b    '       _/   Z/  T    /  T  Z/__/             ',$0d,$0a
                                dc.b    '       \    /  _|_ _/   |  __/____           ',$0d,$0a
                                dc.b    '______  \________/_X____\________/  ._____   ',$0d,$0a
                                dc.b    '\_   |__            __  ___         |  _/    ',$0d,$0a
                                dc.b    '  \    /  ____  ____\/_ \ |__ ______|_ |___  ',$0d,$0a
                                dc.b    ' / ___/_ / __/-/_  |  |  ___/_   ____/  /  T ',$0d,$0a
                                dc.b    '/  /   _|   __    _|  |  /   _| (___:  /   |_',$0d,$0a
                                dc.b    '\       \___7)____\|__|_______\____/|_/    \\',$0d,$0a
                                dc.b    ' \_______\          ___  ___        !NE7___//',$0d,$0a
                                dc.b    '      ________ __  .\ /__\ |__ ________      ',$0d,$0a
                                dc.b    '     /  __   /  /__! /7__ __/_   __   /      ',$0d,$0a
                                dc.b    '    /    /__/  /   |  |/  /   |  Z/__/       ',$0d,$0a
                                dc.b    '   / ___/__.  /   _| _/  /   _|  __/___      ',$0d,$0a
                                dc.b    '   \   Z/   |______\ \________\_______/      ',$0d,$0a
                                dc.b    '    \_______|      .  :      MORE GREETZ     ',$0d,$0a

        IFD TEST_BUILD
        even
buffer_low             dcb.b   1024*120,$00     ; initial load buffer zx0 (75kb largest packed file) / final module buffer (largest module 170kb)
        even
buffer_high            dcb.b   1024*120,$00    ; zxo depacked buffer (delta4 depack buffer)

        even
mfm_track_buffer        dcb.w   $1A00           ; 13Kb raw mfm track buffer for testing
        ENDC


                even
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


