@echo off
:: author: Redcube
setlocal enabledelayedexpansion

set "PFC_EXE=%~dp0net10.0\pfc.exe"
set "U4PAK_EXE=%~dp0net10.0\u4pak.exe"
set "TEXCONV_EXE=%~dp0net10.0\texconv.exe"
set "STAGING=%~dp0mod_staging"
set "PAKDIR=%~dp0pak"
set "PAKNAME=%~n1"
set "SUFFIX=_p1000"
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

if not exist "%TEXCONV_EXE%" (
    echo ERROR: texconv.exe not found at %TEXCONV_EXE%
    echo get it from Microsoft's DirectXTex releases and drop it into net10.0\
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

echo [^^!] Any old %PAKNAME%%SUFFIX%.pak will be overwritten.
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

if exist "%PAKDIR%\%PAKNAME%.pak" (
    move /y "%PAKDIR%\%PAKNAME%.pak" "%PAKDIR%\%PAKNAME%%SUFFIX%.pak" >nul
)

echo.
"%U4PAK_EXE%" list "%PAKDIR%\%PAKNAME%%SUFFIX%.pak"
echo.
"%U4PAK_EXE%" info "%PAKDIR%\%PAKNAME%%SUFFIX%.pak"

echo.
echo -^> %PAKDIR%\%PAKNAME%%SUFFIX%.pak
echo.
pause
exit /b 0

:process
set "INPUT=%~1"
set "BASENAME=%~n1"
set "OUTDIR=%~dp1"
set "DDS_OUT=%OUTDIR%%BASENAME%.dds"
set "UASSET=%OUTDIR%%BASENAME%.uasset"
set "PIXFMT="
set "TEXSIZE="
set "TCFMT="

echo ============================================
echo converting: %~nx1
echo input: %INPUT%
echo.

echo checking pak for pixel format / size / texconv format...
"%PFC_EXE%" info "%BASENAME%" > "%TEMP%\pfc_info.txt" 2>"%TEMP%\pfc_info_err.txt"
set "INFOLINE="
set /p INFOLINE= < "%TEMP%\pfc_info.txt"

if not "!INFOLINE!"=="" (
    for /f "tokens=1,2,3 delims=|" %%A in ("!INFOLINE!") do (
        set "PIXFMT=%%A"
        set "TEXSIZE=%%B"
        set "TCFMT=%%C"
    )
)

if not "!TCFMT!"=="" goto :run

if "!PIXFMT!"=="" (
    echo could not look up %BASENAME% in your paks, pls select manually
) else (
    echo %PIXFMT% has no texconv mapping yet, pls select manually
    type "%TEMP%\pfc_info_err.txt" 2>nul
)

echo.
echo 1 = BC1_UNORM
echo 2 = BC2_UNORM
echo 3 = BC3_UNORM
echo 4 = BC4_UNORM
echo 5 = BC5_UNORM
echo 6 = BC6H_UF16
echo 7 = BC7_UNORM
echo.

:ask
set "CHOICE="
set /p "CHOICE=format: "
if "!CHOICE!"=="1" ( set "TCFMT=BC1_UNORM" & goto :run )
if "!CHOICE!"=="2" ( set "TCFMT=BC2_UNORM" & goto :run )
if "!CHOICE!"=="3" ( set "TCFMT=BC3_UNORM" & goto :run )
if "!CHOICE!"=="4" ( set "TCFMT=BC4_UNORM" & goto :run )
if "!CHOICE!"=="5" ( set "TCFMT=BC5_UNORM" & goto :run )
if "!CHOICE!"=="6" ( set "TCFMT=BC6H_UF16" & goto :run )
if "!CHOICE!"=="7" ( set "TCFMT=BC7_UNORM" & goto :run )
echo invalid
goto :ask

:run
echo using texconv format: !TCFMT!
if not "!TEXSIZE!"=="" echo forcing size: !TEXSIZE!x!TEXSIZE!
echo running texconv...
echo.

set "OUTDIR_ARG=%OUTDIR%"
if "!OUTDIR_ARG:~-1!"=="\" set "OUTDIR_ARG=!OUTDIR_ARG:~0,-1!"

if "!TEXSIZE!"=="" (
    "%TEXCONV_EXE%" -f !TCFMT! -m 0 -y -o "!OUTDIR_ARG!" "%INPUT%"
) else (
    "%TEXCONV_EXE%" -f !TCFMT! -m 0 -y -w !TEXSIZE! -h !TEXSIZE! -o "!OUTDIR_ARG!" "%INPUT%"
)

if errorlevel 1 (
    echo ERROR: texconv conversion failed for %BASENAME%
    goto :eof
)

if not exist "%DDS_OUT%" (
    echo ERROR: expected output file was not created -- %DDS_OUT%
    goto :eof
)

echo.
echo done -- %DDS_OUT%
echo.

echo exporting uasset and injecting...
echo.

"%PFC_EXE%" inject "%BASENAME%" "%DDS_OUT%" "%UASSET%"

if errorlevel 1 (
    echo ERROR: pfc inject failed for %BASENAME%
    goto :eof
)

if not exist "%UASSET%" (
    echo ERROR: expected output file was not created -- %UASSET%
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
    echo ERROR: could not resolve in-game path, skipping staging for this file
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