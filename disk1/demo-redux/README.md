# Demo/Music Disk Program

I've disassembled the original demo code and have removed my old mfm-loader. At the moment I've replaced it with a copy of the 4489 loader (which I've also dissassembled in a separate file), and started to change little areas of the code to get my hand back into 68000 development.

## Aims
My aims for this demo are to:-

 - Crunch the audio and demo from 3 disks down to 1 disk.
   - This should be possible using modern compression (zx0 for instance) and implementing a 4 bit delta compression for the module samples (I'm currently looking at creating a c# command line utility to implement this).
 - Improve the 4489 loader delay routine. The current implementation waits for raster lines to avoid using the CIA timers and conflicting with user code. Due to the way the demo works, the loader runs while the visual effects are running under interrupt. This is causing the raster delay to take longer than it should, so things like stepping the drive heads are running far too slowly at the moment. Implementing a TOD timer wait should help to reduce the effects of this.
 - Improve the disk layout and file packing. The 4489 loader is a 'byte' loader that can address files by byte offset from the start of the disk. This allows disk files to be packed with no wasted space in sectors on the disk etc. I've implemented a command line utility based on h0ffman's TTEDiskBuilder, converted it to .net core and changed the disk config.json a little and got it to output the disk allocation as a text file.
 - I may update some of the GFX for fun, and some other internals like the menu system just for my own gratification. We'll see.

## Progress
2025-06-18 - Gone back to the drawing board with the 4bit delta compression, the utility works but the compression is not so good, so am looking at a different implementation at the moment. This means the build is not really working at the moment.  You can execute the demo but not really load any music.






