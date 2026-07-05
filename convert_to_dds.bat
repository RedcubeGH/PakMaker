@echo off
:: author: Redcube
setlocal enabledelayedexpansion

set "PFC_EXE=%~dp0pfc\bin\Release\net8.0\pfc.exe"

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

if /i "!PIXFMT!"=="PF_DXT1" ( set "DXT=dxt1" & set "PFMT=bgr24" & goto :run )
if /i "!PIXFMT!"=="PF_DXT3" ( set "DXT=dxt3" & set "PFMT=bgra"  & goto :run )
if /i "!PIXFMT!"=="PF_DXT5" ( set "DXT=dxt5" & set "PFMT=bgra"  & goto :run )

echo !PIXFMT! is not a dxt format, pick one manually

:manual
echo.
echo 1 = dxt1
echo 3 = dxt3
echo 5 = dxt5
echo.

:ask
set "CHOICE="
set /p "CHOICE=format: "
if "!CHOICE!"=="1" ( set "DXT=dxt1" & set "PFMT=bgr24" & goto :run )
if "!CHOICE!"=="3" ( set "DXT=dxt3" & set "PFMT=bgra"  & goto :run )
if "!CHOICE!"=="5" ( set "DXT=dxt5" & set "PFMT=bgra"  & goto :run )
echo invalid
goto :ask

:run
echo running ffmpeg with %DXT%...
echo.

ffmpeg -y -i "%INPUT%" ^
    -vf "format=%PFMT%" ^
    -c:v dds ^
    -compression %DXT% ^
    -mipmaps 1 ^
    -big_endian 1 ^
    "%DDS_OUT%"

if errorlevel 1 (
    echo something went wrong
    pause
    exit /b 1
)

echo.
echo done -- %DDS_OUT%
echo.
pause