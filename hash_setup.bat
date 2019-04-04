@echo off
SETLOCAL ENABLEEXTENSIONS

for /F "eol=; tokens=1* delims==" %%i in (config.txt) do set %%i=%%j
set t=%date%_%time%
set d=%t:~10,4%%t:~7,2%%t:~4,2%_%t:~15,2%%t:~18,2%%t:~21,2%


"C:\Program Files\Microsoft SQL Server\110\Tools\Binn\sqlcmd.exe" -E -b -S %Server% -d %Database% -s, -W -i ".\SQLFiles\HashSetup.sql" -o ".\Log\SetupLog_Temp.txt"
if "%errorlevel%" == "1" goto err_handler
goto success

:success
echo setup completed successfully >> ".\Log\SetupLog_%d%.txt"
del ".\Log\SetupLog_Temp.txt"
SET /p delExit=Setup completed successfully. Press the ENTER key to exit...:
exit /b

:err_handler
echo Failed with error #%errorlevel% >> ".\Log\SetupError_%d%.txt"
SET /p delExit=Setup failed, review log files for more details. Press the ENTER key to exit...:
exit /b