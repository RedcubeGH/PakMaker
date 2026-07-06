@echo off
:: author: Redcube
setlocal enabledelayedexpansion

set "PFC_EXE=%~dp0net10.0\pfc.exe"
set "U4PAK_EXE=%~dp0net10.0\u4pak.exe"
set "STAGING=%~dp0mod_staging"
set "PAKDIR=%~dp0pak"
set "PAKNAME=%~n1"
set "PAKROOT="
set "CFG=%~dp0net10.0\Path.cfg"

if "%~1"=="" (
    echo drop your image files onto this
    pause
    exit /b 1
)

if not exist "%PFC_EXE%" (
    echo pfc.exe not found -- run build.bat first
    pause
    exit /b 1
)

if not exist "%U4PAK_EXE%" (
    echo u4pak.exe not found at %U4PAK_EXE%
    pause
    exit /b 1
)

if exist "%STAGING%" rd "%STAGING%" /s /q

if not exist "%CFG%" (
    type nul > "%CFG%"
)

set /p PAKSPATH=<"%CFG%"

if not defined PAKSPATH goto ASK
if not exist "%PAKSPATH%" goto ASK

for %%I in ("%PAKSPATH%") do (
    if /I not "%%~nxI"=="Paks" goto ASK
)

goto CONTINUE

:ASK
cls
echo.
echo Enter the FULL path to your Sea of Thieves Paks folder
echo Example:
echo C:\Program Files (x86)\Steam\steamapps\common\Sea of Thieves\Athena\Content\Paks
echo.

:ASKLOOP
set "PAKSPATH="
set /p "PAKSPATH=> "

if not exist "%PAKSPATH%" (
    echo.
    echo That folder doesn't exist.
    echo.
    goto ASKLOOP
)

for %%I in ("%PAKSPATH%") do (
    if /I not "%%~nxI"=="Paks" (
        echo.
        echo The selected folder must end in a folder named Paks.
        echo.
        goto ASKLOOP
    )
)

> "%CFG%" echo %PAKSPATH%

echo.
echo Path saved to Path.cfg.
timeout /t 1 >nul

:CONTINUE

cls

echo [^^!] Any old %PAKNAME%.pak will be overwritten.
echo Close the window to abort or press any key to continue...
pause >nul

for %%F in (%*) do call :process "%%~F"

if "%PAKROOT%"=="" (
    echo nothing got staged, no pak to build
    pause
    exit /b 1
)

echo  -----------------
echo   u4pak
echo  -----------------

if not exist "%PAKDIR%" mkdir "%PAKDIR%"

cd /d "%STAGING%"
"%U4PAK_EXE%" pack "%PAKDIR%\%PAKNAME%.pak" %PAKROOT%
cd /d "%~dp0"

rd "%STAGING%" /s /q

for %%F in (%*) do del "%%~dpF%%~nF.uasset" 2>nul

echo.
"%U4PAK_EXE%" list "%PAKDIR%\%PAKNAME%.pak"
echo.
"%U4PAK_EXE%" info "%PAKDIR%\%PAKNAME%.pak"

echo.
echo -^> %PAKDIR%\%PAKNAME%.pak
echo.
pause
exit /b 0

:process
set "INPUT=%~1"
set "BASENAME=%~n1"
set "OUTDIR=%~dp1"
set "DDS_OUT=%OUTDIR%%BASENAME%.dds"
set "UASSET=%OUTDIR%%BASENAME%.uasset"

echo ============================================
echo converting: %~nx1
echo input: %INPUT%
echo.

echo checking pak for pixel format...
"%PFC_EXE%" "%BASENAME%" > "%TEMP%\pfc_out.txt" 2>nul
set /p PIXFMT= < "%TEMP%\pfc_out.txt"

if "!PIXFMT!"=="" goto :manual

echo pixel format: !PIXFMT!
echo.

if /i "!PIXFMT!"=="PF_DXT1" ( set "DXT=DXT1" & set "PFMT=bgr24" & goto :run )
if /i "!PIXFMT!"=="PF_DXT3" ( set "DXT=DXT3" & set "PFMT=bgra"  & goto :run )
if /i "!PIXFMT!"=="PF_BC5" ( set "DXT=DXT5" & set "PFMT=bgra"  & goto :run )

echo Error !PIXFMT! not a valid input. pls select manually

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
    goto :eof
)

echo.
echo done -- %DDS_OUT%
echo.

echo exporting uasset and injecting...
echo.

"%PFC_EXE%" inject "%BASENAME%" "%DDS_OUT%" "%UASSET%"

if errorlevel 1 (
    echo inject failed
    goto :eof
)

del "%DDS_OUT%"

echo.
echo done -- %UASSET%
echo.

echo looking up in-game path...
"%PFC_EXE%" path "%BASENAME%" > "%TEMP%\pfc_path.txt" 2>nul
set /p ASSETPATH= < "%TEMP%\pfc_path.txt"

if "!ASSETPATH!"=="" (
    echo could not resolve in-game path, skipping staging for this file
    goto :eof
)

set "RELPATH=!ASSETPATH:/=\!"
set "STAGEDEST=%STAGING%\!RELPATH!"
set "STAGEDESTDIR=!STAGEDEST!\.."

if not exist "!STAGEDESTDIR!" mkdir "!STAGEDESTDIR!"
copy /y "%UASSET%" "!STAGEDEST!" > nul

if "%PAKROOT%"=="" (
    for /f "delims=\" %%R in ("!RELPATH!") do set "PAKROOT=%%R"
)

echo staged -^> !RELPATH!
echo.
goto :eof