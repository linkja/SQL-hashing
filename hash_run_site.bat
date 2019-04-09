@echo off
SETLOCAL ENABLEDELAYEDEXPANSION
SETLOCAL ENABLEEXTENSIONS

set orgpath=%~dp0

for /F "eol=; tokens=1* delims==" %%i in (config.txt) do set %%i=%%j
set t=%date%_%time%
set d=%t:~10,4%%t:~4,2%%t:~7,2%_%t:~15,2%%t:~18,2%%t:~21,2%


echo decrypting encrypted salt file and retaining salts in memory
for /F "tokens=1,2,3,4,5 delims=," %%G in ('todecryptSaltFile.bat') do (
   set siteid=%%G
   set privateSalt=%%I
   set projectSalt=%%J
   set projectid=%%K
)

echo begin hashing %TIME%
:: HASHING BEGINS HERE	
"C:\Program Files\Microsoft SQL Server\110\Tools\Binn\sqlcmd.exe" -E -b -S %Server% -d %Database% -s, -W -i ".\SQLFiles\InsertintoHash.sql" -o ".\Log\InsertLog_Temp.txt"
if "%errorlevel%" == "1" goto err_handler
goto next1

:: PROCEED Hash and create csv
:next1
echo begin creating csv %TIME%
"C:\Program Files\Microsoft SQL Server\110\Tools\Binn\sqlcmd.exe" -E -b -S %Server% -d %Database%  -s, -W -i ".\SQLFiles\SelectHash.sql" | findstr /V /C:"-" /B > ".\Output\hashes_%siteid%_%projectid%_%d%.csv"
if "%errorlevel%" == "1" goto err_handler1
goto success

:: ERROR DURING HASHING, MOST LIKELY THE DATA DID NOT MEET REQUIREMENTS
:err_handler
echo Insert failed with error #%errorlevel% >> ".\Log\InsertError_%d%.txt"
SET /p delExit=Insert to sql table failed, review log files for more details. Press the ENTER key to exit...:
exit /b

:: ERROR DURING GENERATING hash and CSV
:err_handler1
echo Export failed with error #%errorlevel% >> ".\Log\SelectError_%d%.txt"
SET /p delExit=Export to csv failed, review log files for more details. Press the ENTER key to exit...:
exit /b

:: COMPLETE LOG
:success
for /F "tokens=*"  %%i in ('type ".\Log\InsertLog_Temp.txt" ^| findstr /i "record"') do (
>> ".\Log\InsertCSVLog_%d%.txt" echo %%i)
set count=0
for /f "tokens=*" %%r in ('type ".\Log\InsertLog_Temp.txt" ^| findstr /i "row affected"') do (
for /f "tokens=1 delims=^( " %%c in ("%%r") do set /a count=%%c
)
echo %count% records hashed, inserted into table, and exported to csv successfully >> ".\Log\InsertCSVLog_%d%.txt"
del ".\Log\InsertLog_Temp.txt"
SET /p delExit=Completed successfully, %TIME%. Press the ENTER key to exit...:
exit /b
