imports
=======

An example MASM32 program able to load APIs by 16-bit linear hash. Does not import anything via import sections. Acquires KERNEL32.DLL base address via PEB_LDR_DATA structure.<br>
Implements API address retrieval by manual calculation based on data from libraries` <i>IMAGE_EXPORT_DIRECTORY</i> structure (namely, <i>AddressOfNameOrdinals</i> and <i>AddressOfFunctions</i> members).

The algorithm fills the table named <i>prc</i> with addresses of APIs. Addresses are gotten by reading through the export table (located in <i>AddressOfNames</i>) of a corresponding DLL. Each name (<i>AddressOfNames[N]</i>) is hashed and compared to hashes from the program`s hash table. If there is a match, the algorithm reads the actual position P from <i>AddressOfNameOrdinals[N]</i>, and retrieves the address of the needed API by reading <i>AddressOfFunctions[P]</i>.

TBL_SIZE constant defines the resulting address table length in DWORDs. May be greater (but not less!) than the hash table length.<br>
API_MULT is a linear hash multiplier. Has to be prime and 16-bit unsigned.<br>
API_PLUS is a linear hash constant term. Has to be 16-bit signed.

Hash table consists of several segments going one right after another.<br>
Segment structure (not including first segment which is discussed later) is as follows:
 ____ ____ __ __ __  __ _     __ __  __
|____D____|__K__|__w1__|_  …  __|__wK__|

 - D = null-terminated name of the DLL from which to load next K functions
 - K = number of functions to load from the corresponding DLL, 1 byte
 - w1-wK = hashes of target names (2 bytes each, sorted in ascending order)

D beginning from zero character is treated as ending mark. Technically, the name of any file unable to be loaded as DLL (or simply nonexistemt) will behave similarly, but zero char is more convenient as I consider.

The very first segment is presumed to contain hashes of functions to be loaded from KERNEL32, so this segment cannot have a D member, so it begins immediately with K.<br>
This segment MUST contain the hash for <i>LoadLibrary()</i>, and the resulting table must reserve a position for it, since it is necessary for further DLL loading. Even if no library except KERNEL32 is used, it still has to be present. Alternatively, the call itself may wiped out from the algo; you decide.

<br>P.S.:<br>
Each possible initializing vector for a 16-bit linear hash, (API_MULT; API_PLUS), results in the hash having a number of collisions.<br>
The (0xFBC5; 0xFFFF) pair I used in this example has these:

GDI32:<br>
[ AEEC ]  GetKerningPairsW / SetBoundsRect

KERNEL32:<br>
[ 4ADC ]  GetFileBandwidthReservation / WaitForMultipleObjects
[ 5AF0 ]  AllocateUserPhysicalPages / InitializeSListHead
[ 5C6E ]  GetSystemFileCacheSize / UnregisterWaitEx
[ 756F ]  LocalShrink / RegisterWaitForSingleObject
[ 8E42 ]  CreateThreadpoolTimer / GetPrivateProfileStringW
[ E1D2 ]  SetLocalPrimaryComputerNameW / _lclose
[ F38C ]  Heap32Next / WakeConditionVariable

OPENGL32:<br>
[ 4BC0 ]  glTexCoord1d / glTexCoord1sv

So, check your function set carefully!

<br>P.P.S:<br>
After I finally manage to get rid of the nasty access violation bug, I plan to post a program that facilitates hash table creation, based on the function set you provide.