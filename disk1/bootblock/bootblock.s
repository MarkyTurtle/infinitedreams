

L00010000   dc.l    $444F5300   ; DOS,0
L00010004   dc.l    $010C8415   ; checksum
L00010008   dc.l    $00000001   ; 


L0001000C           BSR.W   L0001009A
L00010010           BRA.W   L00010214

L00010014           OR.B    #$08,$00bfd100
L0001001C           AND.B   #$7f,$00bfd100
L00010024           AND.B   #$f7,$00bfd100
L0001002C           BTST.B  #$0005,$00bfe001
L00010034           BNE.B   L0001002C
L00010036           RTS 

L00010038           OR.B    #$88,$00bfd100
L00010040           AND.B   #$f7,$00bfd100
L00010048           OR.B    #$08,$00bfd100
L00010050           RTS 

L00010052           MOVE.L  #$00075000,$0020(A6)
L0001005A           MOVE.W  #$7f00,$009e(A6)
L00010060           MOVE.W  #$9500,$009e(A6)
L00010066           MOVE.W  #$8210,$0096(A6)
L0001006C           MOVE.W  #$0000,$0024(A6)
L00010072           MOVE.W  #$9a00,$0024(A6)
L00010078           MOVE.W  #$9a00,$0024(A6)
L0001007E_loop      BTST.B  #$0001,$001f(A6)
L00010084           BEQ.B   L0001007E_loop
L00010086           MOVE.W  #$0000,$0024(A6)
L0001008C           MOVE.W  #$0002,$009c(A6)
L00010092           MOVE.W  #$0010,$0096(A6)
L00010098           RTS 

L0001009A           LEA.L   $00dff000,A6
L000100A0           MOVE.L  #$00000000,D0
L000100A2           MOVE.L  D0,$00000060
L000100A6           MOVE.L  D0,$0000007c
L000100AA           MOVE.W  #$7fff,D0
L000100AE           MOVE.W  D0,$0096(A6)
L000100B2           MOVE.W  D0,$009c(A6)
L000100B6           MOVE.W  #$3fff,$009a(A6)
L000100BC           MOVE.W  #$4489,$007e(A6)
L000100C2           MOVE.W  #$0fff,D0
L000100C6           CMP.B   #$20,$0006(A6)
L000100CC           BNE.B   L000100C6
L000100CE_loop      CMP.B   #$30,$0006(A6)
L000100D4           BNE.B   L000100CE_loop
L000100D6           SUB.W   #$0111,D0
L000100DA           MOVE.W  D0,$0180(A6)
L000100DE           BEQ.B   L000100E2
L000100E0           BRA.B   L000100C6
L000100E2           MOVE.L  #$00000001,$0084(A6)
L000100EA           MOVE.L  #$00000000,$00000004
L000100F2           CMP.L   #$c5f00006,$0000007c
L000100FA           BNE.B   L0001010E
L000100FC           LEA.L   L00010108(PC),A0
L00010100           MOVE.L  A0,$00000080
L00010104           TRAP    #$00000000
L00010106           RTS 

L00010108           JMP     $00fc0002
L0001010E           RTS 

L00010110           MOVE.B  #$00,$00bfde00
L00010118           MOVE.B  #$7f,$00bfdd00
L00010120           MOVE.B  #$00,$00bfd400
L00010128           MOVE.B  #$20,$00bfd500
L00010130           MOVE.B  #$09,$00bfde00
L00010138           BTST.B  #$0000,$00bfdd00
L00010140           BEQ.B   L00010138
L00010142           RTS 

L00010144           MOVE.W  L0001032E(PC),D3
L00010148           CMP.W   D3,D0
L0001014A           BEQ.B   L00010190
L0001014C           MOVE.W  D0,D2
L0001014E           LSR.W   #$00000001,D2
L00010150           LSR.W   #$00000001,D3
L00010152           BTST.L  #$0000,D0
L00010156           BNE.B   L00010162
L00010158           OR.B    #$04,$00bfd100
L00010160           BRA.B   L0001016A

L00010162           AND.B   #$fb,$00bfd100

L0001016A           CMP.W   D3,D2
L0001016C           BEQ.B   L00010190
L0001016E           BGT.B   L00010180
L00010170           MOVE.B  #$02,$00bfd100
L00010178           BSR.B   L00010198
L0001017A           BSR.B   L00010110
L0001017C           SUB.W   #$00000001,D3
L0001017E           BRA.B   L0001016A
L00010180           AND.B   #$fd,$00bfd100
L00010188           BSR.B   L00010198
L0001018A           BSR.B   L00010110
L0001018C           ADD.W   #$00000001,D3
L0001018E           BRA.B   L0001016A

L00010190           LEA.L   L0001032E(PC),A0
L00010194           MOVE.W  D0,(A0)
L00010196           RTS 

L00010198           OR.B    #$01,$00bfd100
L000101A0           AND.B   #$fe,$00bfd100
L000101A8           OR.B    #$01,$00bfd100
L000101B0           RTS 

L000101B2           MOVEA.L #$00075000,A0
L000101B8           MOVE.L  #$0000000a,D6
L000101BA           MOVE.W  (A0)+,D5
L000101BC           CMP.W   #$4489,D5
L000101C0           BNE.B   L000101BA
L000101C2           MOVE.W  (A0),D5
L000101C4           CMP.W   #$4489,D5
L000101C8           BNE.B   L000101CC
L000101CA           ADDA.W  #$00000002,A0
L000101CC           MOVE.L  (A0)+,D5
L000101CE           MOVE.L  (A0)+,D4
L000101D0           AND.L   #$55555555,D5
L000101D6           AND.L   #$55555555,D4
L000101DC           LSL.L   #$00000001,D5
L000101DE           OR.L    D4,D5
L000101E0           AND.W   #$ff00,D5
L000101E4           LSL.W   #$00000001,D5
L000101E6           LEA.L   $00(A4,d5.w),A3
L000101EA           LEA.L   $0030(A0),A0
L000101EE           MOVE.W  #$007f,D7
L000101F2           MOVE.L  $0200(A0),D4
L000101F6           MOVE.L  (A0)+,D5
L000101F8           AND.L   #$55555555,D5
L000101FE           AND.L   #$55555555,D4
L00010204           LSL.L   #$00000001,D5
L00010206           OR.L    D4,D5
L00010208           MOVE.L  D5,(A3)+
L0001020A           DBF.W   D7,L000101F2
L0001020E           DBF.W   D6,L000101BA
L00010212           RTS 

L00010214           BSR.W   L00010014
L00010218           MOVE.L  #$00000000,D0
L0001021A           MOVE.L  #$00000009,D1
L0001021C           LEA.L   $00020000,A4
L00010222           BSR.B   L0001027C
L00010224           MOVE.W  #$8180,$0096(A6)
L0001022A           LEA.L   copper_list(pc),a0          ; L00010330(PC),A0
L0001022E           MOVE.L  A0,$0080(A6)
L00010232           MOVE.W  $0088(A6),D0
L00010236           MOVE.L  #$00000000,D7
L00010238           CMP.B   #$f0,$0006(A6)
L0001023E           BNE.B   L00010238
L00010240           BSR.B   L00010296
L00010242           ADD.B   #$00000001,D7
L00010244           CMP.B   #$14,D7
L00010248           BNE.B   L00010238
L0001024A           MOVE.L  #$0000000b,D0
L0001024C           MOVE.L  #$00000007,D1
L0001024E           LEA.L   $00045000,A4
L00010254           BSR.B   L0001027C
L00010256           MOVE.L  #$00000000,D7
L00010258           CMP.B   #$f0,$0006(A6)
L0001025E           BNE.B   L00010258
L00010260           BSR.W   L000102EE
L00010264           ADD.B   #$00000001,D7
L00010266           CMP.B   #$14,D7
L0001026A           BNE.B   L00010258
L0001026C           BSR.W   L00010038
L00010270           MOVE.W  #$7fff,$0096(A6)
L00010276           JMP     $00045000                   ; jump to main loader exe

L0001027C           BSR.W   L00010144
L00010280           BSR.W   L00010052
L00010284           BSR.W   L000101B2
L00010288           ADDA.L  #$00001600,A4
L0001028E           ADD.W   #$00000001,D0
L00010290           DBF.W   D1,L0001027C
L00010294           RTS 

L00010296           LEA.L   $00020400,A0
L0001029C           LEA.L   copper_colours(pc),a0       ; L0001034C(PC),A1
L000102A0           MOVE.L  #$0000001f,D6
L000102A2           MOVE.W  #$0002,D5
L000102A6           MOVE.W  (A0)+,D0
L000102A8           MOVE.W  D0,D1
L000102AA           MOVE.W  $00(A1,d5.w),D2
L000102AE           MOVE.B  D2,D3
L000102B0           AND.B   #$0f,D1
L000102B4           AND.B   #$0f,D3
L000102B8           CMP.B   D1,D3
L000102BA           BEQ.B   L000102C0
L000102BC           ADD.B   #$00000001,$01(A1,d5.w)
L000102C0           MOVE.B  D0,D1
L000102C2           MOVE.B  D2,D3
L000102C4           AND.B   #$f0,D1
L000102C8           AND.B   #$f0,D3
L000102CC           CMP.B   D1,D3
L000102CE           BEQ.B   L000102D6
L000102D0           ADD.B   #$10,$01(A1,D5.W)
L000102D6           AND.W   #$0f00,D0
L000102DA           AND.W   #$0f00,D2
L000102DE           CMP.W   D0,D2
L000102E0           BEQ.B   L000102E6
L000102E2           ADD.B   #$00000001,$00(A1,D5.W)
L000102E6           ADD.W   #$00000004,D5
L000102E8           DBF.W   D6,L000102A6
L000102EC           RTS 

L000102EE           LEA.L   copper_colours(pc),a0       ; L0001034C(PC),A0
L000102F2           MOVE.L  #$00000002,D5
L000102F4           MOVE.L  #$0000001f,D6
L000102F6           MOVE.W  $00(A0,D5.W),D0
L000102FA           MOVE.B  D0,D1
L000102FC           AND.B   #$0f,D1
L00010300           TST.B   D1
L00010302           BEQ.B   L00010308
L00010304           SUB.B   #$00000001,$01(A0,D5.W)
L00010308           MOVE.B  D0,D1
L0001030A           AND.B   #$f0,D1
L0001030E           TST.B   D1
L00010310           BEQ.B   L00010318
L00010312           SUB.B   #$10,$01(A0,D5.w)
L00010318           AND.W   #$0f00,D0
L0001031C           TST.W   D0
L0001031E           BEQ.B   L00010326
L00010320           SUB.W   #$0100,$00(A0,D5.W)
L00010326           ADD.W   #$00000004,D5
L00010328           DBF.W   D6,L000102F6
L0001032C           RTS 

L0001032E           dc.w    $0000

copper_list
L00010330           dc.w    $0092,$0038
                    dc.w    $0094,$00D0
                    dc.w    $008E,$2C81
                    dc.w    $0090,$2CC1
                    dc.w    $0102,$0000
                    dc.w    $0108,$0000
                    dc.w    $010A,$0000
copper_colours
L0001034C           dc.w    $0180,$0000
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
                    dc.w    $01A0,$0000
                    dc.w    $01A2,$0000
                    dc.w    $01A4,$0000
                    dc.w    $01A6,$0000
                    dc.w    $01A8,$0000
                    dc.w    $01AA,$0000
                    dc.w    $01AC,$0000
                    dc.w    $01AE,$0000
                    dc.w    $01B0,$0000
                    dc.w    $01B2,$0000
                    dc.w    $01B4,$0000
                    dc.w    $01B6,$0000
                    dc.w    $01B8,$0000
                    dc.w    $01BA,$0000
                    dc.w    $01BC,$0000
                    dc.w    $01BE,$0000
                    dc.w    $2C01,$FFFE
                    dc.w    $00E0,$0002
                    dc.w    $00E2,$0440
                    dc.w    $00E4,$0002
                    dc.w    $00E6,$2C40
                    dc.w    $00E8,$0002
                    dc.w    $00EA,$5440
                    dc.w    $00EC,$0002
                    dc.w    $00EE,$7C40
                    dc.w    $00F0,$0002
                    dc.w    $00F2,$A440
                    dc.w    $0100,$5200
                    dc.w    $FFFF,$FFFE
L00010400


