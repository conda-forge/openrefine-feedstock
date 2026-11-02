@echo on
setlocal

pushd main\webapp
call npm ci --no-audit --no-fund
if errorlevel 1 exit 1
popd

call mvn -B versions:set -DnewVersion=%PKG_VERSION% -DgenerateBackupPoms=false
if errorlevel 1 exit 1
call mvn -B package -P linux -DskipTests
if errorlevel 1 exit 1

7za x packaging\target\openrefine-linux-%PKG_VERSION%.tar.gz
if errorlevel 1 exit 1
7za x openrefine-linux-%PKG_VERSION%.tar -o"%LIBRARY_PREFIX%\opt"
if errorlevel 1 exit 1
move "%LIBRARY_PREFIX%\opt\openrefine-%PKG_VERSION%" "%LIBRARY_PREFIX%\opt\openrefine"
if errorlevel 1 exit 1
copy refine.bat "%LIBRARY_PREFIX%\opt\openrefine\refine.bat"
if errorlevel 1 exit 1

mkdir "%LIBRARY_PREFIX%\bin"
> "%LIBRARY_PREFIX%\bin\refine.bat" echo @echo off
>> "%LIBRARY_PREFIX%\bin\refine.bat" echo call "%%~dp0..\opt\openrefine\refine.bat" /w webapp %%*
if errorlevel 1 exit 1
