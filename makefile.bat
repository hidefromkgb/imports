@echo off

if exist imports.obj del imports.obj
if exist imports.exe del imports.exe

ml.exe /c /coff imports.asm
if errorlevel 1 goto errasm

PoLink.exe /SUBSYSTEM:WINDOWS imports.obj
if errorlevel 1 goto errlink
dir imports.exe
goto TheEnd

:errlink
echo There has been an error while linking this project.
goto TheEnd

:errasm
echo There has been an error while assembling this project.
goto TheEnd

:TheEnd
if exist imports.obj del imports.obj

pause
