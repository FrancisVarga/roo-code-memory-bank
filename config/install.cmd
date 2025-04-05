@echo off
setlocal

echo --- Starting Roo Code Memory Bank Config Setup ---

:: Define GitHub repository information
set "GITHUB_REPO=FrancisVarga/roo-code-memory-bank"
set "TEMP_DIR=%TEMP%\roo-temp"
set "ZIP_FILE=%TEMP_DIR%\roo-code-memory-bank.zip"

:: Check for curl
where curl >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: curl.exe is not found in your PATH.
    echo Please ensure curl is installed and accessible. Modern Windows 10/11 should include it.
    echo You might need to install it or add it to your system PATH.
    pause
    exit /b 1
) else (
    echo Found curl executable.
)

:: Create temporary directory
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

echo Downloading latest release...

:: Get the latest release URL
echo Fetching the latest release information...
curl -s -L -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/%GITHUB_REPO%/releases/latest" > "%TEMP_DIR%\release.json"

:: Parse the JSON to get browser_download_url for the zip file
:: Using findstr to extract the line containing the download URL for the zip file
findstr "browser_download_url.*\.zip" "%TEMP_DIR%\release.json" > "%TEMP_DIR%\download_url.txt"
set /p DOWNLOAD_URL=<"%TEMP_DIR%\download_url.txt"
:: Clean up the URL (remove quotes and other JSON formatting)
set DOWNLOAD_URL=%DOWNLOAD_URL:*browser_download_url": "=%
set DOWNLOAD_URL=%DOWNLOAD_URL:",%=%
set DOWNLOAD_URL=%DOWNLOAD_URL:"};=%
set DOWNLOAD_URL=%DOWNLOAD_URL:"=% 

if not defined DOWNLOAD_URL (
    echo Error: Could not determine download URL for the latest release.
    echo Please check your internet connection or repository settings.
    goto :DownloadFailed
)

echo Downloading from: %DOWNLOAD_URL%
curl -L -o "%ZIP_FILE%" "%DOWNLOAD_URL%"
if errorlevel 1 (
    echo ERROR: Failed to download release package. Check URL or network connection.
    goto :DownloadFailed
)

echo Extracting configuration files...

:: Use PowerShell to extract the ZIP file
powershell -command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%TEMP_DIR%\extracted' -Force"
if errorlevel 1 (
    echo ERROR: Failed to extract the ZIP file.
    goto :DownloadFailed
)

:: Copy configuration files to current directory
echo Copying configuration files to current directory...
xcopy /Y "%TEMP_DIR%\extracted\config\*" "."
if errorlevel 1 (
    echo ERROR: Failed to copy configuration files.
    goto :DownloadFailed
)

:: Clean up temporary files
echo Cleaning up temporary files...
rmdir /S /Q "%TEMP_DIR%"

echo All configuration files installed successfully.
echo --- Roo Code Memory Bank Config Setup Complete ---

:: Schedule self-deletion
echo Scheduling self-deletion of %~nx0...
start "" /b cmd /c "timeout /t 1 > nul && del /q /f "%~f0""
goto :EOF

:DownloadFailed
echo ERROR: Setup incomplete.
pause
exit /b 1

endlocal