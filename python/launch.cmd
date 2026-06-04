@echo off
setlocal

set "HERE=%~dp0"
if "%HERE:~-1%"=="\" set "HERE=%HERE:~0,-1%"

rem Locate node.
set "NODE_BIN="
for /f "delims=" %%j in ('where node 2^>nul') do (
  if not defined NODE_BIN set "NODE_BIN=%%j"
)
if not defined NODE_BIN (
  echo Hive IDE Python plugin: no 'node' binary found. Pyright runs on Node.js - install Node 18+ and ensure 'node' is on PATH. 1>&2
  exit /b 1
)

set "SERVER=%HERE%\server\package\langserver.index.js"
if not exist "%SERVER%" (
  echo Hive IDE Python plugin: Pyright server not found at %SERVER%. The setup download may have failed; toggle the plugin off and on to retry. 1>&2
  exit /b 1
)

"%NODE_BIN%" "%SERVER%" --stdio
