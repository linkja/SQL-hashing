:: *START ENCRYPTION TOOL*
SETLOCAL ENABLEDELAYEDEXPANSION
SETLOCAL ENABLEEXTENSIONS

::read parameters
for /F "eol=; tokens=1* delims==" %%i in (config.txt) do set %%i=%%j 


::change path to where source code is located
::cd O:\CRU\Kruti\1 Ongoing Work Hold\foo\3CRU-PPRL-hashing-application-master\openssl-1.0.2j-fips-x86_64\OpenSSL\bin
cd %~dp0DecryptSourceCodes\bin

::decrypt
openssl rsautl -decrypt -in %encryptedSaltfile% -inkey %privateKeyfile% 

:: *END ENCRYPTION TOOL*