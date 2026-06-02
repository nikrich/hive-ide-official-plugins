@echo off
setlocal enabledelayedexpansion

set "HERE=%~dp0"
if "%HERE:~-1%"=="\" set "HERE=%HERE:~0,-1%"
set "JDTLS_DIR=%HERE%\jdtls"

rem Pick the platform launcher jar (first match)
set "LAUNCHER="
for %%f in ("%JDTLS_DIR%\plugins\org.eclipse.equinox.launcher_*.jar") do (
  if not defined LAUNCHER set "LAUNCHER=%%f"
)
if not defined LAUNCHER (
  echo Hive IDE Java plugin: no equinox launcher jar found in %JDTLS_DIR%\plugins 1>&2
  exit /b 1
)

set "CONFIG=%JDTLS_DIR%\config_win"

rem Data dir — one per user; jdtls re-uses it across sessions.
set "DATA_DIR=%USERPROFILE%\.hive-ide\jdtls-data"
if not exist "%DATA_DIR%" mkdir "%DATA_DIR%"

rem Locate java
set "JAVA_BIN="
if defined JAVA_HOME (
  if exist "%JAVA_HOME%\bin\java.exe" set "JAVA_BIN=%JAVA_HOME%\bin\java.exe"
)
if not defined JAVA_BIN (
  for /f "delims=" %%j in ('where java 2^>nul') do (
    if not defined JAVA_BIN set "JAVA_BIN=%%j"
  )
)
if not defined JAVA_BIN (
  echo Hive IDE Java plugin: no 'java' binary found. Install JDK 21+ and ensure 'java' is on PATH or JAVA_HOME is set. 1>&2
  exit /b 1
)

"%JAVA_BIN%" ^
  -Declipse.application=org.eclipse.jdt.ls.core.id1 ^
  -Dosgi.bundles.defaultStartLevel=4 ^
  -Declipse.product=org.eclipse.jdt.ls.core.product ^
  -Dlog.level=ALL ^
  -Xmx1G ^
  --add-modules=ALL-SYSTEM ^
  --add-opens java.base/java.util=ALL-UNNAMED ^
  --add-opens java.base/java.lang=ALL-UNNAMED ^
  -jar "%LAUNCHER%" ^
  -configuration "%CONFIG%" ^
  -data "%DATA_DIR%"
