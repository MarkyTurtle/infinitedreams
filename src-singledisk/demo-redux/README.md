
# Single Disk Version
Single Disk Version has been completed. 
   - [infinitedreams.adf](../diskimages/infinitedreams.adf)

There is about 19KB left on the end of the disk, plenty of room to include the original title screen in future.

# Run in VSCode
To run this in VsCode, ensure that the following is uncommented in demo.s

TEST_BUILD SET 1                                        ; Comment this to remove TEST_BUILD 

Also, when the screen flashes, insert the InfiniteDreams.ADF in to DF0: before clicking the left mous button to continue. This pauses the demo so that the disk can be inserted in time to read the File Directory from the disk.

Te ADF can be found in the following folder of the code repository:-
 - \infinitedreams\src-singledisk\diskimages
 

# Single Disk File Table
The File table is now loacted on the disk directly following the boot-block. The demo reads in the file table and searches for the module to load based upon the 4 character file name selcted by the menu option in the demo.

Originally, the file table was all hard-coded into the demo-code. This was fine for 1992, but when trying to pack as much data as possible onto a single disk I needed a more flexible solution.

I used a modified version of h0ffman's ADF disk compiler software, for which I have created a repo with the included changes. I've converted it to work with .NET core as a command line tool and removed the built in compression features. It also need more work and tidying up a bit.

I've also used hoffman's protracker tools to reduce the module size a little, combined with a little manual sample manipulation. The largest space-saving gains were found using the zx0 compression by Salvador and also implementing a version of the 4bit delta sample de-compression for the 'deladaenc' tools repository.







