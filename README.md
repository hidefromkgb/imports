imports
=======

An example MASM32 program able to load APIs by 16-bit linear hash. Does not import anything via import sections. Acquires <i>KERNEL32.DLL</i> base address via <i>PEB_LDR_DATA</i> structure.
Implements API address retrieval by manual calculation based on data from libraries` <i>IMAGE_EXPORT_DIRECTORY</i> structure (namely, <i>AddressOfNameOrdinals</i> and <i>AddressOfFunctions</i> members).

The algorithm fills the table named <i>prc</i> with addresses of APIs. Addresses are gotten by reading through the export table (located in <i>AddressOfNames</i>) of a corresponding DLL. Each name (<i>AddressOfNames[N]</i>) is hashed and compared to hashes from the program`s hash table. If there is a match, the algorithm reads the actual position <i>P</i> from <i>AddressOfNameOrdinals[N]</i>, and retrieves the address of the needed API by reading <i>AddressOfFunctions[P]</i>.

<i>TBL_SIZE</i> constant defines the resulting address table length in DWORDs. May be greater (but not less!) than the hash table length.<br>
<i>API_MULT</i> is a linear hash multiplier. Has to be prime and 16-bit unsigned.<br>
<i>API_PLUS</i> is a linear hash constant term. Has to be 16-bit signed.

Hash table consists of several segments going one right after another.<br>
Segment structure (not including first segment which is discussed later) is as follows:

|____D____|__K__|__w1__|  …  __|____wK__|

 - D = null-terminated name of the DLL from which to load next K functions
 - K = number of functions to load from the corresponding DLL, 1 byte
 - w1-wK = hashes of target names (2 bytes each, sorted in ascending order)

D beginning from zero character is treated as ending mark. Technically, the name of any file unable to be loaded as DLL (or simply nonexistent) will behave similarly, but zero char is more convenient as I consider.

Each <i>L</i>-th address in resulting <i>prc</i> table corresponds to the function whose name is encoded with <i>L</i>-th hash in hash table.

The very first segment is presumed to contain hashes of functions to be loaded from <i>KERNEL32</i>, so this segment cannot have a <i>D</i> member, so it begins immediately with <i>K</i>.<br>
This segment MUST contain the hash for <i>LoadLibrary()</i>, and the resulting table must reserve a position for it, since it is necessary for further DLL loading. Even if no library except <i>KERNEL32</i> is used, it still has to be present. Alternatively, the call itself may wiped out from the algo; you decide.<br>
FIX: Windows 7 and upper do not load <i>KERNEL32</i> immediately after program start, thus making <i>LoadLibraryA()</i> unaccessible. Fortunately, <i>LoadLibraryExA()</i> is still available, so the algo now uses it instead.<br>
FIX: WINE does load <i>KERNEL32</i> into our address space, but places it at the end of the libraries list, so we now try to find <i>LoadLibraryExA()</i> in every library present in the list, not only the first. If none of the loaded libraries contains this API (which is generally nonsense, but nonetheless), the program will eventually segfault at a zero address.

<br>P.S.:<br>
Each possible initializing vector for a 16-bit linear hash, (API_MULT; API_PLUS), results in the hash having a number of collisions.<br>
The (0xFBC5; 0xFFFF) pair I used in this example has these:

GDI32:<br>
[ AEEC ]  GetKerningPairsW / SetBoundsRect

KERNEL32:<br>
[ 4ADC ]  GetFileBandwidthReservation / WaitForMultipleObjects<br>
[ 5AF0 ]  AllocateUserPhysicalPages / InitializeSListHead<br>
[ 5C6E ]  GetSystemFileCacheSize / UnregisterWaitEx<br>
[ 756F ]  LocalShrink / RegisterWaitForSingleObject<br>
[ 8E42 ]  CreateThreadpoolTimer / GetPrivateProfileStringW<br>
[ E1D2 ]  SetLocalPrimaryComputerNameW / _lclose<br>
[ F38C ]  Heap32Next / WakeConditionVariable<br>

OPENGL32:<br>
[ 4BC0 ]  glTexCoord1d / glTexCoord1sv

So, check your function set carefully!

<br>P.P.S.:<br>
The actual function set provided in this example does not bear a particular purpose, and is intended only for demonstration.

After I finally manage to get rid of the nasty access violation bug, I plan to post a program that facilitates hash table creation, based on the function set you provide.