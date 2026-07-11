@echo off

:: Check for administrative privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo You need administrative privileges to run this script.
    echo Please right-click on this script and select "Run as administrator."
    pause
    exit /b
)

:: Modify OpenSSL environment variable
echo Modifying OpenSSL environment variable for newer Intel processors...
echo.

setx OPENSSL_ia32cap ~0x200000200000000 /M

:: Check if the modification was successful
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Failed to modify the OpenSSL environment variable.
    echo Please make sure you have the necessary permissions.
    echo.
    pause
    exit /b
)

:: Display success message
echo.
echo OpenSSL environment variable has been modified.
echo Please reboot your computer for the changes to take effect.
echo.

:: Pause for user acknowledgment
pause
