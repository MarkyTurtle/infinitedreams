# The Lunatics UK - Infinite Dreams - Music Disks

![InfiniteDreams](/images/InfiniteDreamsScreen.png)

A demo that I wrote in 1992, the last one I did for [**'The Lunatics UK'**](https://demozoo.org/groups/37655/), just before I went off to University and stopped writting anymore demos. It's quite sad looking back that I didn't continue developing on the Amiga. Some of the code looks rushed, particularly the code around the menu handling and loading parameters. I think I had a bit of 'copy & paste'-itis when I wrote this orginally. Maybe one-day I'll refactor it into a nicer data-driven menu system (or maybe not).
- I have had to disassemble the code because the source has long gone into the great dustbin in the sky. 
- I have re-documented the code and added a **TEST_BUILD** flag to the code (which is enabled by default) so that the code can be build and executed from within **VSCode** with the **Amiga Assembly** Plug in. 
- If you use the **DMS/ADF** images that are included in the archive, you will be able to load and listen to the original protracker tunes loaded from the original disks in an emulator, or in VSCode while debugging, etc.
- I have ripped the files from the original disks and placed them in the archive under the **[ripfiles](/ripfiles/)/** folder.

## Original Production Credits
Code: **Spongehead (AKA: me, MarkyTurtle)** <br/>
Graphics: **JOE, T.S.M**<br/>
Music: **Hollywood, Subculture(Subi), Phaser, Reeal**<br/>

- [original code folder](/src-original/)
- [original disk images](/src-original/diskimages/)

## Single Disk Version
I wanted to see if it would be possible to create a single-disk version of the original demo. So, using modern Compression Tools (zx0 and 4Bit Delta Sample Compression), a new loader, some optimisation tools and a little bit of additional programming, I've managed to fit all of the original content (apart from the original title screen - which should also be do-able with a bit more time). So in that regard I need to give a big shout-out to the following people and projects that made this possible.

- [single disk code folder](/src-singledisk/)
- [single disk image](/src-singledisk/diskimages/)

- **4498 Loader Project** - I've created a fork and dissasembled it in my repo (I want to replace the timing with TOD delays instead of Raster delays).
   - [4489 Byte Loader](https://github.com/4489/4489_byteloader)
- **deladaenc** - 4 bit Delta Sample Encoding/Decoding and module processing.
   - [deladaenc](https://github.com/Hemiyoda/deladaenc)
- **djH0ffman and the Twitch Elite**, for community, streaming and inspiration.
   - [Protacker Tools](https://github.com/djh0ffman/ProTrackerTools)
   - [TTE Disk Builder](https://github.com/djh0ffman/TTEDiskBuilder)
     

## Resources
I've been looking for better mod player routines for the Amiga, am listing them below:
- [Lightspeed Player](https://github.com/arnaud-carre/LSPlayer)
- [Various Packers and players](https://www.amiga-stuff.com/modpackers-download.html)
- [Protracker Support Archive](https://aminet.net/package/mus/edit/ptsupp)
- [Ultimate Tracker Support Package](https://aminet.net/package/mus/edit/RSE-UTS)

## Progress To Date
- **2025-10-23** - Reorganised the Folder structure. The original source can be found in the 'src-original' folder, along with the DMS images of the original demo.  The single disk source can be found in the folder 'src-singledisk' along with the ADF image of the new single disk version. The only thing missing from the original is the 'Title Screen' image that pops up on the original and the 'Disk X' image that loads when booting from the Disk2 or Disk3 of the original disks into the drive. The code is crying out for some refactoring, much of the menu structure and loading parameters was originally hard-coded into the demo in a 'copy & paste' approach to software development. My Excuse: I was only 17 and couldn't be bothered to implement a better, data-driven solution. Maybe i'll have a tinker in my spare time and improve the code a bit.
     - The visual effects are running from the Level 3 VBL interrupt.
     - The Menu and Disk Loader run in the main loop.
     - The Protracker Player has been changed to use a CIA player.
     - The MFM Disk Loader has been changed to use the 4489 Byte Loader (The original was my first MFM Disk Loader which loaded whole tracks only).
     - zx0 Decompression code has been added from the Salvador Repository as all modules are now compressed using the zx0 compression algorithm.
     - I've written a 4bit Delta Decompression routine in assembler to decompress the modules which have been encocded using the deladaenc library.
- **2025-10-22** - Finished compiling a single-disk version of the demo. Need to re-organise the repo-folders as they are currently a bit of a mess and tidy up some documentation.
- **2025-10-04** - This week I came across a 4 bit Delta Compression Utility [Deladaenc](https://github.com/MarkyTurtle/deladaenc) completely be chance which is able to compress Protracker Module Samples down to 4bit delta encoding. This in combination with the Salvidor zx0 compression, h0ffman's [Protracker Tools](https://github.com/MarkyTurtle/ProTrackerTools) Optimisation utility and some manual sample jiggery-pokery has enabled me to compress all of the modules down to approx 850,000 bytes.  This will easily now fit onto a single 880K disk.  All I need to do now is implement the delta decompression in 68K code and get the demo code to compress down into about 30K to fit on the disk.
- **2025-06-14** - Have been trying to implement 4bit sample compression based on code used by h0ffman. Also created the 'modprocessor' c# command which can be used to compress the samples in place in the mod file. This enables much better compression. Modules are compressed to approx 25% of their original size.  At the moment the sound quality is too poor to use for the music disk.  I'll take a look at a implementing a better compression method next, using a 4 bit delta which will hopefully not quantise the data so severely into 16 discrete values as it is at the moment.
- **2025-05-28** - Have changed the protracker player routine to a CIA routine which is more accurate than the original player (which didn't sound great on some of the
- original tunes. Also, I've also tried converting the modules to P61 format (and created a seperate test repo), the modules dont play correctly in this compressed format. Finally, I've tried compressing the modules with zx0 compression, this would reduce the demo to 2 disks. I might investigate this avenue, I was hoping to get it compressed down to a single disk. Maybe theres still a compression format that I haven't found yet that will get me there. I'll keep investigating...
- **2025-05-25** - Mostly documented the disassembly of the demo code. Just the line draw routine and music player left to document. (I think the music player was supplied by someone else originally).  Think I might try to fit a new disk loader to this and see how much I can compress onto a single disk using modern compaction tools. I'll have a think...
- **2025-05-24** - Demo runs from VSCode, all components are working. Can load music from the original disks. I have just begun ripping the protracker modules from the original disks.
- **2025-05-12** - Demo is Disassembled and can be run inside VSCode. Not all working yet, The main logo and scroller is working. 
- **2025-05-07** - Completed Disassembly of the bootblock Disk 1
- **2025-05-06** - Started Disassembling the bootblock of Disk 1
