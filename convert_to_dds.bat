@echo off
:: author: Redcube
setlocal enabledelayedexpansion

set "PFC_EXE=%~dp0pfc\bin\Release\net10.0\pfc.exe"

if "%~1"=="" (
    echo drop a file onto this
    pause
    exit /b 1
)

set "INPUT=%~1"
set "BASENAME=%~n1"
set "OUTDIR=%~dp1"
set "DDS_OUT=%OUTDIR%%BASENAME%.dds"

cls
echo converting: %~nx1
echo input: %INPUT%
echo output: %DDS_OUT%
echo.

if not exist "%PFC_EXE%" (
    echo pfc.exe not found -- run build.bat first
    pause
    exit /b 1
)

echo checking pak for pixel format...
"%PFC_EXE%" "%BASENAME%" > "%TEMP%\pfc_out.txt" 2>nul
set /p PIXFMT= < "%TEMP%\pfc_out.txt"
del "%TEMP%\pfc_out.txt" 2>nul

if "!PIXFMT!"=="" goto :manual

echo pixel format: !PIXFMT!
echo.

if /i "!PIXFMT!"=="PF_DXT1" ( set "DXT=DXT1" & set "PFMT=bgr24" & goto :run )
if /i "!PIXFMT!"=="PF_DXT3" ( set "DXT=DXT3" & set "PFMT=bgra"  & goto :run )
if /i "!PIXFMT!"=="PF_DXT5" ( set "DXT=DXT5" & set "PFMT=bgra"  & goto :run )

echo Error !PIXFMT! not a valid input. Pls select manually

:manual
echo.
echo 1 = DXT1
echo 3 = DXT3
echo 5 = DXT5
echo.

:ask
set "CHOICE="
set /p "CHOICE=format: "
if "!CHOICE!"=="1" ( set "DXT=DXT1" & set "PFMT=bgr24" & goto :run )
if "!CHOICE!"=="3" ( set "DXT=DXT3" & set "PFMT=bgra"  & goto :run )
if "!CHOICE!"=="5" ( set "DXT=DXT5" & set "PFMT=bgra"  & goto :run )
echo invalid
goto :ask

:run
echo running ImageMagick with %DXT%...
echo.

magick "%INPUT%" -define dds:compression=%DXT% "%DDS_OUT%"

if errorlevel 1 (
    echo conversion failed
    pause
    exit /b 1
)

echo.
echo done -- %DDS_OUT%
echo file size: 
for %%A in ("%DDS_OUT%") do echo %%~zA bytes
echo.
pause