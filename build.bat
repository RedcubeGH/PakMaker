@echo off
:: author: Redcube
cd /d "%~dp0pfc"
dotnet build -c Release
pause