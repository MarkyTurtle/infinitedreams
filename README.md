# The Lunatics UK - Infinite Dreams - Music Disks

![InfiniteDreams](/images/InfiniteDreamsScreen.png)

A demo that I wrote in 1992, the last one I did for 'The Lunatics UK', just before I went off to University and stopped writting anymore demos. It's quite sad looking back that I didn't continue developing on the Amiga.
<br/>
I'll have to disassemble the code because the source has long gone into the great dustbin in the sky. (Which I've now done).
I've re-documented the code and added a TEST_BUILD flag to the code (which is enabled by default) so that the code can be build and executed from within VSCode. 
If you use the ADF images in the archive, you are able to load and listen to the original protracker tunes from the disks.
<br/><br/>
I've also ripped the files from the original disks and placed them in the archive under the  'ripfiles' folder.
<br/>

## Production Credits
Code: **Spongehead**<br/>
Graphics: **JOE, T.S.M**<br/>
Music: **Hollywood, Subculture(Subi), Phaser, Reeal**<br/>

Maybe I'll this will trigger me do develop something new after this project...

## Resources
I've been looking for better mod player routines for the Amiga, am listing them below:
- [Lightspeed Player](https://github.com/arnaud-carre/LSPlayer)
- [Various Packers and players](https://www.amiga-stuff.com/modpackers-download.html)
- [Protracker Support Archive](https://aminet.net/package/mus/edit/ptsupp)
- [Ultimate Tracker Support Package](https://aminet.net/package/mus/edit/RSE-UTS)

## Progress To Date
- **2025-06-14** - Have been trying to implement 4bit sample compression based on code used by h0ffman. Also created the 'modprocessor' c# command which can be used to compress the samples in place in the mod file. This enables much better compression. Modules are compressed to approx 25% of their original size.  At the moment the sound quality is too poor to use for the music disk.  I'll take a look at a implementing a better compression method next, using a 4 bit delta which will hopefully not quantise the data so severely into 16 discrete values as it is at the moment.
- **2025-05-28** - Have changed the protracker player routine to a CIA routine which is more accurate than the original player (which didn't sound great on some of the
- original tunes. Also, I've also tried converting the modules to P61 format (and created a seperate test repo), the modules dont play correctly in this compressed format. Finally, I've tried compressing the modules with zx0 compression, this would reduce the demo to 2 disks. I might investigate this avenue, I was hoping to get it compressed down to a single disk. Maybe theres still a compression format that I haven't found yet that will get me there. I'll keep investigating...
- **2025-05-25** - Mostly documented the disassembly of the demo code. Just the line draw routine and music player left to document. (I think the music player was supplied by someone else originally).  Think I might try to fit a new disk loader to this and see how much I can compress onto a single disk using modern compaction tools. I'll have a think...
- **2025-05-24** - Demo runs from VSCode, all components are working. Can load music from the original disks. I have just begun ripping the protracker modules from the original disks.
- **2025-05-12** - Demo is Disassembled and can be run inside VSCode. Not all working yet, The main logo and scroller is working. 
- **2025-05-07** - Completed Disassembly of the bootblock Disk 1
- **2025-05-06** - Started Disassembling the bootblock of Disk 1
