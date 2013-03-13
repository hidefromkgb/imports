.386;
.model flat, stdcall;
option casemap:none;
assume fs:nothing;

include \masm32\include\windows.inc;


;const
  LoadLibraryExA         equ  DWORD PTR [prc + 000]; <-- compulsory!

  ; <-- kernel32.dll
  LoadResource           equ  DWORD PTR [prc + 004];
  FindResourceA          equ  DWORD PTR [prc + 008];
  GetLocalTime           equ  DWORD PTR [prc + 012];
  LockResource           equ  DWORD PTR [prc + 016];
  GetModuleHandleA       equ  DWORD PTR [prc + 020];
  SizeofResource         equ  DWORD PTR [prc + 024];

  ; <-- user32.dll
  SetWindowPos           equ  DWORD PTR [prc + 028];
  SendDlgItemMessageA    equ  DWORD PTR [prc + 032];
  GetCursorPos           equ  DWORD PTR [prc + 036];
  SetForegroundWindow    equ  DWORD PTR [prc + 040];
  PostMessageA           equ  DWORD PTR [prc + 044];
  IsWindowVisible        equ  DWORD PTR [prc + 048];
  EndDialog              equ  DWORD PTR [prc + 052];
  SetTimer               equ  DWORD PTR [prc + 056];
  PtInRect               equ  DWORD PTR [prc + 060];
  SetWindowLongA         equ  DWORD PTR [prc + 064];
  LoadIconA              equ  DWORD PTR [prc + 068];
  ShowWindow             equ  DWORD PTR [prc + 072];
  CreatePopupMenu        equ  DWORD PTR [prc + 076];
  KillTimer              equ  DWORD PTR [prc + 080];
  AppendMenuA            equ  DWORD PTR [prc + 084];
  SendMessageA           equ  DWORD PTR [prc + 088];
  DialogBoxParamA        equ  DWORD PTR [prc + 092];
  MessageBoxA            equ  DWORD PTR [prc + 096];
  DestroyMenu            equ  DWORD PTR [prc + 100];
  GetSystemMetrics       equ  DWORD PTR [prc + 104];
  ScreenToClient         equ  DWORD PTR [prc + 108];
  SetWindowRgn           equ  DWORD PTR [prc + 112];
  TrackPopupMenuEx       equ  DWORD PTR [prc + 116];

  ; <-- gdi32.dll
  CreateRectRgn          equ  DWORD PTR [prc + 120];
  OffsetRgn              equ  DWORD PTR [prc + 124];
  CreateSolidBrush       equ  DWORD PTR [prc + 128];
  CombineRgn             equ  DWORD PTR [prc + 132];
  GetRgnBox              equ  DWORD PTR [prc + 136];
  DeleteObject           equ  DWORD PTR [prc + 140];

  ; <-- comctl32.dll
  InitCommonControlsEx   equ  DWORD PTR [prc + 144];

  ; <-- shell32.dll
  Shell_NotifyIconA      equ  DWORD PTR [prc + 148];

  TBL_SIZE equ 48;            <-- API table length
  API_MULT equ 0FBC5h;        <-- API hash multiplier
  API_PLUS equ -1;            <-- API hash constant term


.data?
  prc DD TBL_SIZE DUP(?);     <-- API table


.code
  TBL DB (@F - $)/2;
      DW 0CD35h;
  @@:
      DB "kernel32.dll", 0, (@F - $)/2;
      DW 04504h, 04BE5h, 08F0Eh, 0C675h, 0EB2Bh, 0FD6Ah;
  @@:
      DB "user32.dll", 0, (@F - $)/2;
      DW 0011Ah, 0056Bh, 00D14h, 017DCh, 02DD4h, 031F3h;
      DW 04C0Eh, 050D9h, 05DA1h, 06987h, 07CE1h, 07E53h;
      DW 099CEh, 0A658h, 0BF8Bh, 0C5A8h, 0C808h, 0CDCCh;
      DW 0D934h, 0E6C0h, 0E808h, 0EE1Fh, 0FAC3h;
  @@:
      DB "gdi32.dll", 0, (@F - $)/2;
      DW 01304h, 03115h, 03223h, 05DEAh, 0C59Fh, 0F14Eh;
  @@:
      DB "comctl32.dll", 0, (@F - $)/2;
      DW 0458Eh;
  @@:
      DB "shell32.dll", 0, (@F - $)/2;
      DW 046E5h;
  @@:
      DB 0;


@main:
  XOR EAX, EAX;
  LEA ECX, [EAX + TBL_SIZE];
  MOV EDI, OFFSET prc;
  PUSH EBP;
  PUSH EDI;
  REP STOSD;
  MOV EDI, OFFSET TBL;

  MOV EAX, DWORD PTR FS:[EAX + 48];
  TEST EAX, EAX;
  JS @F;
    MOV EAX, DWORD PTR [EAX + 12];
    MOV ESI, DWORD PTR [EAX + 28];
  @flib:
    LODSD;
    PUSH EAX;
    MOV EAX, DWORD PTR [EAX + 8];
    JMP @flok;
  @@:
    MOV EAX, 0BFF70000h;
    PUSH EAX;

  @flok:
    MOV EDX, (IMAGE_DOS_HEADER PTR [EAX]).e_lfanew;
    MOV EDX, (IMAGE_NT_HEADERS PTR [EAX + EDX]).OptionalHeader.\
    DataDirectory[IMAGE_DIRECTORY_ENTRY_EXPORT].VirtualAddress;
    ADD EDX, EAX;
    MOV ECX, (IMAGE_EXPORT_DIRECTORY PTR [EDX]).NumberOfNames;
    MOV ESI, (IMAGE_EXPORT_DIRECTORY PTR [EDX]).AddressOfNames;
    MOV EBP, (IMAGE_EXPORT_DIRECTORY PTR [EDX]).AddressOfFunctions;
    MOV EBX, (IMAGE_EXPORT_DIRECTORY PTR [EDX]).AddressOfNameOrdinals;
    LEA EBX, [EBX + EAX - 2];
    LEA ESI, [ESI + EAX - 4];
    ADD EBP, EAX;
    SHL ECX, 8;
    PUSH EAX;
    PUSH ESI;
    JMP @load;

    @ldok:
      MOV ESI, DWORD PTR [EAX];
      ADD ESI, DWORD PTR [ESP];
      SHL ECX, 8;
      PUSH EAX;

      XOR EAX, EAX;
      JMP @hash;
      @@:
        IMUL EAX, EAX, API_MULT;
        LEA EAX, [EAX + EDX + API_PLUS];
        ADD ESI, 1;
      @hash:
        MOVZX EDX, BYTE PTR [ESI];
        TEST EDX, EDX;
      JNE @B;

      MOVZX EDX, BYTE PTR [EDI];
      LEA ESI, [EDI - 1];
      JMP @axlt;
      @@:
        SETC CL;
        CMP AX, WORD PTR [ESI + EDX*2];
        JE @axeq;
        JB @axlt;
        LEA ESI, [ESI + EDX*2];
      @axlt:
        ADD DL, CL;
        SHR EDX, 1;
      JNE @B;

      ADD ESI, 2;
      CMP AX, WORD PTR [ESI];
      JNE @load;

      @axeq:
      LEA ESI, [ESI + EDX*2 - 1];
      SUB ESI, EDI;

      MOVZX EAX, WORD PTR [EBX];
      MOV EAX, DWORD PTR [EBP + EAX*4];
      ADD EAX, DWORD PTR [ESP + 4];
      MOV EDX, DWORD PTR [ESP + 12];
      MOV DWORD PTR [EDX + ESI*2], EAX;

    @load:
      POP EAX;
      ADD EBX, 2;
      ADD EAX, 4;
      SHR ECX, 8;
      DEC ECX;
    JGE @ldok;

    POP ESI;
    POP ESI;
    MOV EBX, LoadLibraryExA;
    TEST EBX, EBX;
    JE @flib;

    POP EDX;
    MOVZX EAX, BYTE PTR [EDI];
    LEA EDX, [EDX + EAX*4];
    LEA EDI, [EDI + EAX*2 + 1];
    PUSH EDX;
    PUSH ESI;
    MOV ESI, EDI;
    XOR EAX, EAX;
    REPNE SCASB;

    PUSH EAX;
    PUSH EAX;
    PUSH ESI;
    CALL EBX;
    TEST EAX, EAX;
  JNE @flok;

  POP EBP;
  POP EBP;
  POP EBP;

  ; <-- main code starts from here...

  PUSH MB_OK or MB_ICONEXCLAMATION;
  PUSH EAX;
  PUSH OFFSET TBL + 3;
  PUSH EAX;
  CALL MessageBoxA;

  RET;

end @main;
