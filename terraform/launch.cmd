@echo off
setlocal

set "HERE=%~dp0"
if "%HERE:~-1%"=="\" set "HERE=%HERE:~0,-1%"

set "BIN=%HERE%\server\windows_amd64\terraform-ls.exe"

if not exist "%BIN%" (
  echo Hive IDE Terraform plugin: terraform-ls.exe not found at %BIN%. The setup download may have failed; toggle the plugin off and on to retry. 1>&2
  exit /b 1
)

"%BIN%" serve
