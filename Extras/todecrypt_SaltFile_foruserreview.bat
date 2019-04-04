@echo off
:: *START ENCRYPTION TOOL*
SETLOCAL ENABLEDELAYEDEXPANSION
SETLOCAL ENABLEEXTENSIONS

echo To review contents of RSA encrypted Salt file 
echo.
set /P encryptedSaltfile=Enter file path and name for the encrypted Salt file: 
echo.
set /P privateKeyfile=Enter file path and name for the private key to decrypt salt file:

echo. 

::decrypt
"%~dp0..\DecryptSourceCodes\bin\openssl.exe" rsautl -decrypt -in %encryptedSaltfile% -inkey %privateKeyfile% 

echo. 
echo.
set /p delExit=After reviewing site ID, site name and project ID, press the ENTER key to exit...:
:: *END ENCRYPTION TOOL*