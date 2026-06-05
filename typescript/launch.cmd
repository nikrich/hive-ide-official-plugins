@echo off
setlocal

set "HERE=%~dp0"
if "%HERE:~-1%"=="\" set "HERE=%HERE:~0,-1%"

set "NODE_BIN="
for /f "delims=" %%j in ('where node 2^>nul') do (
  if not defined NODE_BIN set "NODE_BIN=%%j"
)
if not defined NODE_BIN (
  echo Hive IDE TypeScript plugin: no 'node' binary found. Install Node 20+ and ensure 'node' is on PATH. 1>&2
  exit /b 1
)

set "CLI=%HERE%\server\tls\package\lib\cli.mjs"
if not exist "%CLI%" (
  echo Hive IDE TypeScript plugin: server not found at %CLI%. The setup download may have failed; toggle the plugin off and on to retry. 1>&2
  exit /b 1
)

if not exist "%HERE%\server\ts\typescript" (
  mklink /J "%HERE%\server\ts\typescript" "%HERE%\server\ts\package" >nul 2>&1
)

set "NODE_PATH=%HERE%\server\ts"
"%NODE_BIN%" "%CLI%" --stdio
