@echo off
setlocal

set "HERE=%~dp0"
if "%HERE:~-1%"=="\" set "HERE=%HERE:~0,-1%"

set "BIN=%HERE%\server\windows_amd64\OmniSharp.exe"
if not exist "%BIN%" (
  echo Hive IDE C# plugin: OmniSharp.exe not found at %BIN%. The setup download may have failed; toggle the plugin off and on to retry. 1>&2
  exit /b 1
)

where dotnet >nul 2>&1
if errorlevel 1 (
  echo Hive IDE C# plugin: 'dotnet' not found. Install the .NET 6+ runtime from https://dotnet.microsoft.com/download and ensure it is on PATH. 1>&2
  exit /b 1
)

"%BIN%" -lsp -s "%CD%"
