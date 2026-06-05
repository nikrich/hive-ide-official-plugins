@echo off
setlocal

set "GOPLS="
for /f "delims=" %%j in ('where gopls 2^>nul') do (
  if not defined GOPLS set "GOPLS=%%j"
)
if not defined GOPLS (
  if exist "%USERPROFILE%\go\bin\gopls.exe" set "GOPLS=%USERPROFILE%\go\bin\gopls.exe"
)
if not defined GOPLS (
  echo Hive IDE Go plugin: 'gopls' not found. Install Go from https://go.dev/dl/ then run: go install golang.org/x/tools/gopls@latest 1>&2
  exit /b 1
)

"%GOPLS%" serve
