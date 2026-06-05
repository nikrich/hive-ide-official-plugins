@echo off
setlocal

set "HERE=%~dp0"
if "%HERE:~-1%"=="\" set "HERE=%HERE:~0,-1%"

set "BIN=%HERE%\server\windows_amd64\clangd_22.1.0\bin\clangd.exe"
if not exist "%BIN%" (
  echo Hive IDE C/C++ plugin: clangd.exe not found at %BIN%. The setup download may have failed; toggle the plugin off and on to retry. 1>&2
  exit /b 1
)

"%BIN%" --background-index
