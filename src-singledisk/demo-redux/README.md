
# Single Disk Version
Single Disk Version has been completed. 
   - [infinitedreams.adf](../diskimages/infinitedreams.adf)

There is about 19KB left on the end of the disk, plenty of room to include the original title screen in future.


# Single Disk File Table
The files have been layed out on the disk as follows below.
The new loader (4489 byte loader) is able to read files from a byte location on the disk. The table below shows the Disk Offsets and File Lengths for each file on the disk.
The demo is located at the end, as it has allowed me to re-create the disk and modify the 'demo' code without altering the positions of the module files on the disk.

|FileID|Description|Disk Offset|FileSize|
|------|-----------|-----------|--------|
|dsk#|Disk Number |00000001|00000001|
|boot|Boot Block  |00000000|000003FF|
|tble|File Table  |00000400|00000190|
|summ|PT Module   |00000590|0000480A|
|brig|PT Module   |00004D9A|00004842|
|cosm|PT Module   |000095DC|00006525|
|natu|PT Module   |0000FB01|0000661F|
|obli|PT Module   |00016120|00006731|
|ment|PT Module   |0001C851|00006AD1|
|neve|PT Module   |00023322|0000754F|
|brea|PT Module   |0002A871|00007B2A|
|zero|PT Module   |0003239B|00007BDC|
|this|PT Module   |00039F77|0000816D|
|jarr|PT Module   |000420E4|00008904|
|reto|PT Module   |0004A9E8|00008A5A|
|tech|PT Module   |00053442|00008C52|
|love|PT Module   |0005C094|00009010|
|blad|PT Module   |000650A4|000095EA|
|shaf|PT Module   |0006E68E|00009F2C|
|floa|PT Module   |000785BA|0000A5BA|
|eatt|PT Module   |00082B74|0000B1BB|
|thef|PT Module   |0008DD2F|0000B24A|
|soun|PT Module   |00098F79|0000B463|
|skyr|PT Module   |000A43DC|0000C447|
|flig|PT Module   |000B0823|0000EC59|
|stra|PT Module   |000BF47C|00012B68|
|demo|Demo Program|000D1FE4|0000517D|
|Free|Free Space  |000D7161|00004E9F|








