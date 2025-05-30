# Demo/Music Disk Program

Looking back at the code, and trying to keep reminding myself that I was only 17 at the time and inexperienced. I can see much code repetition and hard-coded/programmed actions which would normally be data driven actions.

From what I can remember, the team wanted to release quickly and a few features were not added, such as the ability to show tailored scroll texts/info per song. Also, I think the disks were complied in a hurry and so, with more planning I think I could have compacted much more data onto each floppy disk.

Maybe I'll recompile a disk and see how many tunes I can fit on a disk (3 disks definately too many).


## MFM Disk Loader
The disk loader was the first implementation of my own MFM Loader, any demo worth anything in the day had to be a
trackmo and have its own loader.
This was my first implementation, built by scraping and piecing together details from the h/w reference manual,
various disk-mag articles of the time, and what little use the 'Amiga Disk Drives Inside and Out' book was by
Abacus (horrible stuff).
The disk loader only works with whole disk tracks (not even sectors), this kept it simple for the time, but
obviously means it's far from optimal when minimising disk space wastage.
I think it also has a problem where it waits for the /DSKRDY signal from the drive which disappeared with the
A1200, so the loader fails on these machines also.


## Action Replay Protection
I added some action replay cartidge protection to the bootloader and the main program. I remember that one version of the cartridge could be disabled by setting an odd address in the second copper-list register.

Looks like another version can be detected by comparing the Level 7 AutoVector address value of #$c5f00006. 

I'll remove this code from the disassembly as it's a bit unsightly and there's also a dodgy ROM jump to a reset/crash routine.

**example code 1 - Level 7 Vector & odd copper-list addresses**
```
                        ;------------------------------------
                        ; action replay detection (not sure if works)
L00020006                       MOVE.L  #$00000000,$00000004
L0002000C                       MOVE.L  #$00000001,$00dff084
L00020016                       MOVE.L  #$00000000,$00000060
L0002001E                       MOVE.L  #$00000000,$0000007c
L00020026                       CMP.L   #$c5f00006,$0000007c
L0002002E                       BEQ.B   do_reset_crash_01
                        ; no action replay detected
                        ;------------------------------------
                                ... continue with demo
                                ...


                        ;------------------------------
                        ; action replay detected
do_reset_crash_01
L00020040                       LEA.L   reset_crash_01(PC),A0
L00020044                       MOVE.L  A0,$00000080
L00020048                       TRAP    #$00000000
L0002004A                       RTS 
                        ; action replay crash/reset action
reset_crash_01
L0002004C                       JMP     $00fc0002               
```

**example 2 - Test for TOD value not changing**
```
                ; action replay check - tod clock value
                ; if not changing then reset/crash the machine
L0002042A                       ADD.W   #$0001,L0002049A
L00020432                       CMP.W   #$0014,L0002049A
L0002043A                       BNE.W   L0002048E 
L0002043E                       MOVE.W  #$0000,L0002049A
L00020446                       MOVE.L  #$00000000,D7
L0002044C                       MOVE.B  $00bfea01,D7            ; TOD-HI
L00020452                       LSL.L   #$00000004,D7
L00020454                       LSL.L   #$00000004,D7
L00020456                       MOVE.B  $00bfe901,D7            ; TOD-MID
L0002045C                       LSL.L   #$00000004,D7
L0002045E                       LSL.L   #$00000004,D7
L00020460                       MOVE.B  $00bfe801,D7            ; TOD-LO
L00020466                       CMP.L   L00020496,D7
L0002046C                       BNE.W   L00020488 
L00020470                       MOVE.L  #$ffffffff,$00af0000
do_reset_crash_03
L0002047A                       LEA.L   reset_crash_03,a0               ;$00020490,A0
L00020480                       MOVE.L  A0,$00000080
L00020484                       TRAP    #$00000000
L00020486                       RTS 

L00020488                       MOVE.L D7,L00020496
L0002048E                       RTS 
```
