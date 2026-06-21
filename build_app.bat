@echo off
cd /d "%~dp0android"
call gradlew.bat assembleDebug --no-daemon --info > ../build_log.txt 2>&1
echo Build finished with error code: %ERRORLEVEL%
type ../build_log.txt | findstr /i "error failed exception"
pause
