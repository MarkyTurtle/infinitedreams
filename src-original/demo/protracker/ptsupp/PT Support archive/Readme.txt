Short: ProTracker support archive
Description: Long awaited extras for ProTracker.
Uploader: Håvard Pedersen (havardp@mail.stud.ingok.hitos.no)
Author: Håvard Pedersen (havardp@mail.stud.ingok.hitos.no)
Replaces: mus/edit/ptsupp_1.lha
Type: mus/edit
Version: Release 3


The ProTracker support achive is an archive stuffed with extras for
ProTracker, the most popular music program ever on the Amiga. I've put it
together because there haven't been released any versions of ProTracker for
a while and I think the Amiga community deserves better support for PT.

The disclaimer in the AmigaGuide documentation still yields. =)

Please spread this archive to all of your friends and enemies. The scene
really deserves this stuff.

If you want to contact me for anything, please do. My address is found in
the AmigaGuide documentation.

Severe bugs has been fixed in the sources from the previous relese.

This archive contains:

  * Complete AmigaGuide documentation for ProTracker. The documentation has
    been polished since the last release and should be easier for
    beginners. In addition to all stuff present in earlier helpfiles it
    contains:
      - Replyaddress with people listening to you. =)
      - Actual description of what PT is for.
      - In-depth discussion and light explanation on how to actually
        make music using ProTracker.
      - Description of all new PT-features including the DYN-system and
        the new chord-editor.
      - Version history from V0.89 to V3.18.
      - A lot of background history for ProTracker!
      - Known bugs.
      - Frequently asked questions.
      - An updated description of the module-format. (Both the old and
        the planned IFF-format!)
      - Both technical and easy-to-understand DYN explanations.
      - Description on how to use all sources in the archive.
      - Also comes in text-version for guys without the AmigaGuide system
        installed or if you want to print it out.
      - A brief chapter describing how to obtain information from the
        AmigaGuide documentation. (NEW!)
      - A new chapter describing musical theory. (NEW!)
      - A built-in musical dictionary. (NEW!)
      - Example-samples for the sample effects. (NEW!)

  * ProTracker assembler replay with the following features:
      - Mastervolume.
      - Balance.
      - Signal user when module reached end.
      - Rewind/fast forward (skips one pattern at a time).
      - Optional 68020+ optimizations.
      - Complete NoiseTracker compatibility.
      - Faster than original ProTracker replay.
      - Totally bugfree. Works on all Amigas.
      - Plays selectable amount of channels (for games).
      - Completely PC-relative.

  * New modulepacker called ProPruner, based on ProPacker v2.1 by Christian
    Estrup. Contains features such as:
      - Very fast replay.
      - Supports all ProTracker effect commands.
      - Mastervolume.
      - Balance.
      - Possibility to sync programs with the module.
      - Restart flag tells you when the module has reached its end.
      - Separate samplefiles to save chipmem.
      - Selectable amounts of channel to play for games.
      - Delta processing for better samplepacking.
      - Handles VBR register correctly.
      - CIA timing possible.
      - Pause/continue functions.
      - Skip forward/backwards one position at a time.
      - Completely PC-relative.
      - Should work on all assemblers.
      - Macro-based noteplayer interface for fancy replay.
      - All fancy options are fully selectable at assembly time.

  * A soundeffect engine for playing two samples in one Amiga audio
    channel. Features include:
      - Vertical blank mode. Plays soundeffects on a vertical blank basis.
        Easy to use.
      - Audio interrupt. Utilises OS to play sound. Gives neat quality.
      - Fast mixing. (Test yourself!)

  * Several extra sources:
      - A source that calculates the playtime of both CIA and
        VBlank-based ProTracker modules fast!
      - CIA shells for both the ProTracker and the ProPruner replay. Comes
        in both system-friendly AND unfriendly versions! (NEW!)
      - Allocation and freeing of audio channels. (NEW!)
      - A description on how to customize the ProTracker replay to fit your
        needs! (NEW!)

  * The TrackerTool command that repairs damaged modules. Improved from
    previous release.

  * Several example modules that shows the possibilities of ProTracker and 
    effectcommands in use. (NEW!)

  * A fast, yet powerful moduleripper. (NEW!)
      - The only ripper that doesn't use a single byte chip memory if
        fastmemory is present.
      - The only ripper that also searches fastmemory and virtual memory,
        making it able to recover modules after a crash in ProTracker!
      - Sophisticated decrunch engine that allows you to load and decrunch
        files as well as allocate the memory used.
      - Supports redirectable IO, can be launched on a debug terminal.
      - Finds the following formats: Laxity Tracker, NoiseTracker v1.0-2.2,
        Phenomena Packer v1.0, ProPacker v2.0-v2.1, ProRunner v1.0-2.0,
        ProRunner v2.0 preprocessed, ProTracker v1.0-3.18 (also 100-pattern
        modules), QuadraComposer v1.3-2.1, SoundTracker v2.3-2.5,
        StarTrekker v1.0-1.3, UNIC Tracker and Wanton Packer.


-- Howard of Mental Diseases --
