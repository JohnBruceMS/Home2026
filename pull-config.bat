@echo off
REM Home Assistant Configuration Pull - Batch Wrapper
REM This batch file runs the PowerShell script with appropriate execution policy

echo Home Assistant Configuration Pull Script
echo.

REM Check if Z: drive is accessible
if not exist "Z:\" (
    echo ERROR: Drive Z: is not accessible or mapped
    echo Please ensure your Home Assistant system is properly mapped to drive Z:
    pause
    exit /b 1
)

REM Run PowerShell script with execution policy bypass
echo Running configuration pull script...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0pull-homeassistant-config.ps1" %*

echo.
echo Script completed. Check the output above for any errors.
pause