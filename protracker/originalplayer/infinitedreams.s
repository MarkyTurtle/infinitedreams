

        ; *************************************************************************
        ; ***                           MUSIC PLAYER ROUTINES                   ***
        ; *************************************************************************
        ; This player does not use CIA Timing, it is intended to be called
        ; every frame.
        ;
        ; -------------------------- music start/stop --------------------------
        ; This routine appears to be called to both stop and initiailise the
        ; music - this may be an error.
        ; It's probably an initialisation routine (memory lost to time)
        ; I will find out when/if I get the time...
        ;
music_init        ; original address L00021B96
                                MOVEA.L #LOAD_BUFFER,A0         ; module load address = $40000
                                MOVE.L  A0,module_start_ptr     ; L00022CB8
                                MOVEA.L A0,A1

                        ; find highest byte value in memory range 952-1080 ($3b8-$438)
                        ; find highest pattern number used (from pattern list/table)
                        ; pattern table offset = $03b8 (952)
                        ; the table is 128 bytes
.find_highest_pattern_idx       ; original address L00021BA4
                                LEA.L   $03b8(A1),A1            ; a1 = offset 952
                                MOVE.L  #$0000007f,D0           ; d0 = 127+1 - loop counter
                                MOVE.L  #$00000000,D1
.update_highest_idx
                                MOVE.L  D1,D2
                                SUB.W   #$00000001,D0
.not_highest_idx
                                MOVE.B  (A1)+,D1                ; read byte from offset 952+
                                CMP.B   D2,D1                   ; if d1 > d2 then d2 = d1 (branch taken)
                                BGT.B   .update_highest_idx      
                                DBF.W   D0,.not_highest_idx     
                                ADD.B   #$00000001,D2           ; increment d2

                        ; d2 = highest patten index
                        ; calc start of sample data address
.fill_sample_ptr_table
                                LEA.L   sample_ptr_table(pc),a1         ; L00022C3C(PC),A1
                                ASL.L   #$00000008,D2           ; multiply index by 256
                                ASL.L   #$00000002,D2           ; multiply index y 1024 (max pattern index)
                                ADD.L   #$0000043c,D2           ; add start pattern offset
                                ADD.L   A0,D2                   ; d2 = start of sample data address

                        ; d2 = start of sample data address
                        ; step through each sample and get the sample
                        ; start address for each instrument.
                        ; records the start address in the sample_ptr_table
                                MOVEA.L D2,A2                   ; a2 = start of sample data
                                MOVE.L  #$0000001e,D0           ; samples = 30+1 (31 samples)
.next_sample_loop
                                CLR.L   (A2)                    ; zero first pair of sample bytes (remove pop/click?)
                                MOVE.L  A2,(A1)+                ; store sample ptr data
                                MOVE.L  #$00000000,D1
                                MOVE.W  $002a(A0),D1            ; d1 = module offset 42 (sample length offset - sample 1)
                                ASL.L   #$00000001,D1           ; convert sample length in words to sample length in bytes
                                ADDA.L  D1,A2                   ; a2 = next sample start address
                                ADDA.L  #$0000001e,A0           ; a0 = next sample length address ptr
                                DBF.W   D0,.next_sample_loop    ; loop for next sample

                        ; switch audio filter off
.audio_filteR_off
                                OR.B    #$02,$00bfe001          ; /LED (sound filter off)

                        ; initialise play counters/tracker vars
.init_counter_vars
                                MOVE.B  #$06,tempo_value        ; default play speed (6 frames per pattern row)
                                CLR.B   tempo_tick_value        ; L00022CBD
                                CLR.B   L00022CBE
                                CLR.W   L00022CC6




                ; ----------------------- switch music off ---------------------
                ; set all channel volume to 0, disable all channels DMA
                ;
music_off       ; original address L00021C0A
                                CLR.W   CUSTOM+AUD0VOL          ; $00dff0a8
                                CLR.W   CUSTOM+AUD1VOL          ; $00dff0b8
                                CLR.W   CUSTOM+AUD2VOL          ; $00dff0c8
                                CLR.W   CUSTOM+AUD3VOL          ; $00dff0d8
                                MOVE.W  #$000f,CUSTOM+DMACON    ; $00dff096
                                RTS 




                ; ------------------------- play music ------------------------
                ; Call this routine at regular intervals (i.e. every VBL) to
                ; continue to play the current module.
                ; This player does not use CIA Timing.
                ;
play_music      ; original address L00021C2C
L00021C2C                       MOVEM.L D0-D4/A0-A6,-(A7)
L00021C30                       ADD.B   #$00000001,tempo_tick_value     ; L00022CBD
L00021C36                       MOVE.B  tempo_tick_value(PC),D0
L00021C3A                       CMP.B   tempo_value(pc),d0              ; L00022CBC(PC),D0
L00021C3E                       BCS.B   L00021C54 
                ; process next pattern line
L00021C40                       CLR.B   tempo_tick_value                ; L00022CBD
L00021C46                       TST.B   L00022CC4
L00021C4C                       BEQ.B   L00021C92 
L00021C4E                       BSR.B   L00021C5A
L00021C50                       BRA.W   L00021EC8 

                ; process current pattern line 
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


L00021C92                       MOVEA.L module_start_ptr(pc),a0                 ; L00022CB8(PC),A0
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
L00021D1A                       LEA.L   sample_ptr_table(pc),a1                 ; L00022C3C(PC),A1
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
L00021F54                       MOVEA.L module_start_ptr(pc),a0                 ; L00022CB8(PC),A0
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
L00021FE4                       MOVE.B  tempo_tick_value(PC),D0
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

L00022046                       TST.B   tempo_tick_value                ; L00022CBD
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

L00022094                       TST.B   tempo_tick_value                ; L00022CBD
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
L000223F8                       CLR.B   tempo_tick_value        ; L00022CBD
L000223FE                       MOVE.B  D0,tempo_value          ; L00022CBC
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

L0002250C                       TST.B   tempo_tick_value                ; L00022CBD
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
L00022576                       MOVE.B  tempo_tick_value(PC),D1
L0002257A                       BNE.B   L0002258A 
L0002257C                       MOVE.W  (A6),D1
L0002257E                       AND.W   #$0fff,D1
L00022582                       BNE.B   L000225CC 
L00022584                       MOVE.L  #$00000000,D1
L00022586                       MOVE.B  tempo_tick_value(PC),D1
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

L000225D0                       TST.B   tempo_tick_value                ; L00022CBD
L000225D6                       BNE.W   L00021FD8 
L000225DA                       MOVE.L  #$00000000,D0
L000225DC                       MOVE.B  $0003(A6),D0
L000225E0                       AND.B   #$0f,D0
L000225E4                       BRA.W   L0002235C

L000225E8                       TST.B   tempo_tick_value                ; L00022CBD
L000225EE                       BNE.W   L00021FD8 
L000225F2                       MOVE.L  #$00000000,D0
L000225F4                       MOVE.B  $0003(A6),D0
L000225F8                       AND.B   #$0f,D0
L000225FC                       BRA.W   L00022382 

L00022600                       MOVE.L  #$00000000,D0
L00022602                       MOVE.B  $0003(A6),D0
L00022606                       AND.B   #$0f,D0
L0002260A                       CMP.B   tempo_tick_value(PC),D0
L0002260E                       BNE.W   L00021FD8 
L00022612                       CLR.B   $0013(A6)
L00022616                       MOVE.W  #$0000,$0008(A5)
L0002261C                       RTS 

L0002261E                       MOVE.L  #$00000000,D0
L00022620                       MOVE.B  $0003(A6),D0
L00022624                       AND.B   #$0f,D0
L00022628                       CMP.B   tempo_tick_value,D0
L0002262E                       BNE.W   L00021FD8 
L00022632                       MOVE.W  (A6),D0
L00022634                       BEQ.W   L00021FD8 
L00022638                       MOVE.L  D1,-(A7)
L0002263A                       BRA.W   L00022592 

L0002263E                       TST.B   tempo_tick_value
L00022644                       BNE.W   L00021FD8 
L00022648                       MOVE.L  #$00000000,D0
L0002264A                       MOVE.B  $0003(A6),D0
L0002264E                       AND.B   #$0f,D0
L00022652                       TST.B   L00022CC4
L00022658                       BNE.W   L00021FD8 
L0002265C                       ADD.B   #$00000001,D0
L0002265E                       MOVE.B  D0,L00022CC3
L00022664                       RTS 

L00022666                       TST.B   tempo_tick_value
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

L00022BB8                       dc.w    $0000,$0000

L00022BBC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
L00022BCC                       dc.w    $0002,$0000,$0000,$0000,$0000,$0000,$0000,$0000
L00022BDC                       dc.w    $0000,$0000,$0000,$0000

L00022BE4                       dc.w    $0000,$0000,$0000,$0000
L00022BEC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0004,$0000
L00022BFC                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
L00022C0C                       dc.w    $0000,$0000

L00022C10                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000 
L00022C1C                       dc.w    $0000,$0000,$0000,$0000,$0008,$0000,$0000,$0000
L00022C2C                       dc.w    $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000


sample_ptr_table        ; original address L00022C3C
L00022C3C                       dc.l    $00000000       ; sample 1
                                dc.l    $00000000
                                dc.l    $00000000
                                dc.l    $00000000
L00022C4C                       dc.l    $00000000
                                dc.l    $00000000
                                dc.l    $00000000
                                dc.l    $00000000       ; sample 8
L00022C5C                       dc.l    $00000000
                                dc.l    $00000000
                                dc.l    $00000000
                                dc.l    $00000000
L00022C6C                       dc.l    $00000000
                                dc.l    $00000000
                                dc.l    $00000000
                                dc.l    $00000000       ; sample 16
L00022C7C                       dc.l    $00000000
                                dc.l    $00000000
                                dc.l    $00000000
                                dc.l    $00000000
L00022C8C                       dc.l    $00000000
                                dc.l    $00000000
                                dc.l    $00000000
                                dc.l    $00000000       ; sample 24
L00022C9C                       dc.l    $00000000
                                dc.l    $00000000
                                dc.l    $00000000
                                dc.l    $00000000
L00022CAC                       dc.l    $00000000
                                dc.l    $00000000
                                dc.l    $00000000       ; sample 31


module_start_ptr        ; original address L00022CB8
L00022CB8                       dc.l   $00000000        ; module load address

tempo_value             ; original address L00022CBC
L00022CBC                       dc.b    $06             ; init music sets this to #$06 - default value

tempo_tick_value        ; original address L00022CBD (frame counter ticks towards tempo_value)
L00022CBD                       dc.b    $00             ; init music sets this to #$00 - default value
L00022CBE                       dc.b    $00             ; init music sets this to #$00

L00022CBF                       dc.b    $00

L00022CC0                       dc.b    $00
L00022CC1                       dc.b    $00
L00022CC2                       dc.b    $00
L00022CC3                       dc.b    $00

L00022CC4                       dc.w    $0000
L00022CC6                       dc.w    $0000           ; init music sets this to #$00
L00022CC8                       dc.w    $0000



        ; *************************************************************************
        ; ***                      END OF MUSIC PLAYER ROUTINES                 ***
        ; *************************************************************************


