@echo off
rem Starts the CommonTongue companion: live machine translation for WoW chat.
rem Add options after the file name, for example:  --me Yourcharacter  --overlay  --target de
title CommonTongue companion
cd /d "%~dp0"
where py >nul 2>nul
if %errorlevel%==0 (
  py -3 "Companion\commontongue_companion.py" %*
) else (
  python "Companion\commontongue_companion.py" %*
)
echo.
echo The companion has stopped.
pause
