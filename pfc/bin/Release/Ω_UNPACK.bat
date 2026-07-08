@echo off
::cd %~dp0
echo [!] Any old %~n1 mod folders will be overwitten.
echo Close the window to abort or press any key to continue...
echo.
pause >nul
if not exist "%~dp0unpak" mkdir "%~dp0unpak"
rd "unpak\%~n1" /s /q >nul
net10.0\u4pak.exe unpack %1
move Athena "unpak\%~n1" >nul
echo %~f1 unpacked to 'unpak\%~n1'
echo.
echo Press any key to quit.
pause >nul