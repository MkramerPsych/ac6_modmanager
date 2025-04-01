@echo off
setlocal enabledelayedexpansion

:: URL Definitions()
set "URL_OPEN_SERVER=https://github.com/MkramerPsych/ac6_modmanager/raw/refs/heads/main/Open_Server.zip"
set "URL_BINC_PATCH=https://github.com/TreasuredLight/BINC-Patch/archive/refs/heads/main.zip"
set "URL_VUMSY_PATCH=https://github.com/MkramerPsych/ac6_modmanager/raw/refs/heads/main/ProjectVumsyPatch3.0.0.zip"
:: set "URL_AFTERMATH_PATCH=https://github.com/MkramerPsych/ac6_modmanager/raw/refs/heads/main/Aftermath.zip" CURRENTLY TOO LARGE TO WORK

title Armored Core 6 Mod Manager

:: Predefined Directories
set "USERPROFILE=%USERPROFILE%"
set "DOCUMENTS_DIR=%USERPROFILE%\Documents"
set "AC6_SAVE_BASE_DIR=%APPDATA%\ArmoredCore6"
:: Find the save directory dynamically
set "AC6_SAVE_DIR="
for /d %%D in ("%AC6_SAVE_BASE_DIR%\*") do (
    set "AC6_SAVE_DIR=%%D"
)
set "TEMP_DIR=%USERPROFILE%\Downloads\AC6_Mod_Temp"

:: Create log file
set "LOG_FILE=%DOCUMENTS_DIR%\AC6_Mod_Manager_Log.txt"
echo Logging started at %DATE% %TIME% > "%LOG_FILE%"

:: Main menu
:menu
cls
echo.
echo Armored Core 6 Mod Manager
echo =========================
echo.
echo 1. Install OpenServer/Launch a mod
echo 2. Remove mod files (CAUTION - WILL DELETE YOUR .PVP and .AFTERMATH SAVES)
echo 3. Update mod files (COMING SOON)
echo 4. Exit (You can also close the window)
echo.
set /p CHOICE="Please enter your choice (1-4): "

if "%CHOICE%"=="1" goto install_mod
if "%CHOICE%"=="2" goto cleanup_mod
if "%CHOICE%"=="3" goto update_mod_files
if "%CHOICE%"=="4" exit /b 0
echo Invalid choice. Please try again.
pause
goto menu

:: Function to install mods
:install_mod
echo. >> "%LOG_FILE%"
echo [%DATE% %TIME%] Starting Mod Installation >> "%LOG_FILE%"
echo.
echo Starting Armored Core 6 Mod installation...
echo.

:: Create a temporary directory to store modfiles before unpacking
echo Attempting to create temporary directory... >> "%LOG_FILE%"
if not exist "%TEMP_DIR%" (
    echo Trying to create "%TEMP_DIR%" >> "%LOG_FILE%"
    mkdir "%TEMP_DIR%"
    if errorlevel 1 (
        echo [ERROR] Failed to create primary temp directory >> "%LOG_FILE%"
        
        :: Alternative directory creation attempts
        set "TEMP_DIR=%TEMP%\AC6_Mod_Temp"
        echo Attempting alternative directory: !TEMP_DIR! >> "%LOG_FILE%"
        mkdir "!TEMP_DIR!"
        if errorlevel 1 (
            echo [CRITICAL ERROR] Cannot create any temporary directory >> "%LOG_FILE%"
            echo Error details: >> "%LOG_FILE%"
            echo Working Directory: %CD% >> "%LOG_FILE%"
            echo User Profile: %USERPROFILE% >> "%LOG_FILE%"
            echo Available Temp Directories: %TEMP%, %TMP% >> "%LOG_FILE%"
            
            echo Catastrophic failure creating temporary directory.
            echo Please check the log file at "%LOG_FILE%"
            pause
            goto menu
        )
    )
)

echo Temporary directory created successfully: !TEMP_DIR! >> "%LOG_FILE%"

:: Install Open Server if not installed
if not exist "%DOCUMENTS_DIR%\Open*Server*" (
    echo Open Server not present in Documents >> "%LOG_FILE%"
    echo Downloading Open Server zip file... >> "%LOG_FILE%"
    powershell -Command "& {Invoke-WebRequest -Uri '!URL_OPEN_SERVER!' -OutFile '!TEMP_DIR!\Open_Server.zip'}"
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Failed to download Open Server zip file >> "%LOG_FILE%"
        echo Error downloading file. Check internet connection and URL. >> "%LOG_FILE%"
        pause
        goto menu
    )
    echo Open Server zip downloaded successfully >> "%LOG_FILE%"
    echo Extracting Open Server files to Documents folder... >> "%LOG_FILE%"
    powershell -Command "& {Expand-Archive -Path '!TEMP_DIR!\Open_Server.zip' -DestinationPath '%DOCUMENTS_DIR%' -Force}"
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Failed to extract Open Server files >> "%LOG_FILE%"
        echo Extraction failed. Possible causes: corrupted zip, insufficient permissions >> "%LOG_FILE%"
        pause
        goto menu
    )
    echo Sucessfully extracted Open Server to %DOCUMENTS_DIR% >> "%LOG_FILE%"
) else (
    echo Open Server detected in %DOCUMENTS_DIR% >> "%LOG_FILE%"
)

set "OPEN_SERVER_DIR=%DOCUMENTS_DIR%\Open Server"
echo Open Server is located at %OPEN_SERVER_DIR% >> "%LOG_FILE%"

:: Create altsaves files if necessary

:: check if AC60000.sl2 exists at AC6_SAVE_DIR
echo Checking for existing save files... >> "%LOG_FILE%"
if not exist "%AC6_SAVE_DIR%\AC60000.sl2" (
    echo [ERROR] No Armored Core 6 save file found at "%AC6_SAVE_DIR%" >> "%LOG_FILE%"
    echo Setup failed. >> "%LOG_FILE%"
    pause
    goto menu
) else (
    :: create .pvp save [VumsyPatch, BINCPatch] if not present
    if not exist "%AC6_SAVE_DIR%\AC60000.pvp" ( 
        echo Creating AC60000.pvp file >> "%LOG_FILE%"
        copy "%AC6_SAVE_DIR%\AC60000.sl2" "%AC6_SAVE_DIR%\AC60000.pvp" >nul
        if %ERRORLEVEL% NEQ 0 (
            echo [WARNING] Failed to copy AC60000.sl2 to AC60000.pvp >> "%LOG_FILE%"
            echo You may need to manually copy this file later. >> "%LOG_FILE%"
        )
    ) else (
        echo Detected AC60000.pvp save file @ "%AC6_SAVE_DIR%" >> "%LOG_FILE%"
    )
    :: create .aftermath save [Aftermath] if not present
    if not exist "%AC6_SAVE_DIR%\AC60000.aftermath" (
        echo Creating AC60000.aftermath file >> "%LOG_FILE%"
        copy "%AC6_SAVE_DIR%\AC60000.sl2" "%AC6_SAVE_DIR%\AC60000.aftermath" >nul
        if %ERRORLEVEL% NEQ 0 (
            echo [WARNING] Failed to copy AC60000.sl2 to AC60000.aftermath >> "%LOG_FILE%"
            echo You may need to manually copy this file later. >> "%LOG_FILE%"
        )
        ) else (
        echo Detected AC60000.aftermath save file @ "%AC6_SAVE_DIR%" >> "%LOG_FILE%"
    )
    echo altsaves compatible files are present >> "%LOG_FILE%"
)

:: Ask the user which patch to install
echo.
set /p INSTALL_PATCH="Which patch would you like to install? (1) BINC (2) Vumsy (3) Aftermath (N) None: "

if "%INSTALL_PATCH%"=="1" (
    echo Installing BINC patch... >> "%LOG_FILE%"
    
    :: Create mod directory if it doesn't exist
    set "MOD_DIR=!OPEN_SERVER_DIR!\mod"
    echo MOD_DIR is: !MOD_DIR! >> "%LOG_FILE%"
    mkdir "!MOD_DIR!" 2>nul

    :: Clean up existing content in the mod directory (remove files and directories)
    echo Cleaning up existing mod files... >> "%LOG_FILE%"
    rd /s /q "!MOD_DIR!" 2>nul
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Failed to clean mod folder. >> "%LOG_FILE%"
    ) else (
        echo Existing mod files removed successfully. >> "%LOG_FILE%"
    )

    :: Re-create the mod directory after cleanup
    mkdir "!MOD_DIR!" 2>nul

    :: Download BINC patch (BINC-Patch-main.zip)
    echo Downloading BINC-Patch-main.zip... >> "%LOG_FILE%"
    powershell -Command "& {Invoke-WebRequest -Uri '!URL_BINC_PATCH!' -OutFile '!TEMP_DIR!\BINC-Patch-main.zip'}"
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Failed to download BINC-Patch-main.zip >> "%LOG_FILE%"
        echo BINC patch installation failed. >> "%LOG_FILE%"
    ) else (
        echo BINC patch downloaded successfully. Extracting files... >> "%LOG_FILE%"
        powershell -Command "& {Expand-Archive -Path '!TEMP_DIR!\BINC-Patch-main.zip' -DestinationPath '!MOD_DIR!' -Force; Move-Item '!MOD_DIR!\BINC-Patch-main\*' '!MOD_DIR!' -Force; Remove-Item '!MOD_DIR!\BINC-Patch-main' -Recurse -Force}"
        if %ERRORLEVEL% NEQ 0 (
            echo [ERROR] Failed to extract BINC-Patch-main.zip >> "%LOG_FILE%"
            echo Extraction failed. >> "%LOG_FILE%"
        ) else (
            echo BINC patch installed successfully! >> "%LOG_FILE%"
        )
    )
) else if "%INSTALL_PATCH%"=="2" (
    echo Installing Vumsy patch... >> "%LOG_FILE%"
    
    :: Create mod directory if it doesn't exist
    set "MOD_DIR=!OPEN_SERVER_DIR!\mod"
    echo MOD_DIR is: !MOD_DIR! >> "%LOG_FILE%"
    mkdir "!MOD_DIR!" 2>nul

    :: Clean up existing content in the mod directory (remove files and directories)
    echo Cleaning up existing mod files... >> "%LOG_FILE%"
    rd /s /q "!MOD_DIR!" 2>nul
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Failed to clean mod folder. >> "%LOG_FILE%"
    ) else (
        echo Existing mod files removed successfully. >> "%LOG_FILE%"
    )

    :: Re-create the mod directory after cleanup
    mkdir "!MOD_DIR!" 2>nul

    :: Download Vumsy patch (VumsyPatch3.0.0.zip)
    echo Downloading VumsyPatch3.0.0.zip... >> "%LOG_FILE%"
    powershell -Command "& {Invoke-WebRequest -Uri '!URL_VUMSY_PATCH!' -OutFile '!TEMP_DIR!\VumsyPatch3.0.0.zip'}"
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Failed to download VumsyPatch3.0.0.zip >> "%LOG_FILE%"
        echo Vumsy patch installation failed. >> "%LOG_FILE%"
    ) else (
        echo Vumsy patch downloaded successfully. Extracting files... >> "%LOG_FILE%"
        powershell -Command "& {Expand-Archive -Path '!TEMP_DIR!\VumsyPatch3.0.0.zip' -DestinationPath '!MOD_DIR!' -Force}"
        if %ERRORLEVEL% NEQ 0 (
            echo [ERROR] Failed to extract VumsyPatch3.0.0.zip >> "%LOG_FILE%"
            echo Extraction failed. >> "%LOG_FILE%"
        ) else (
            echo Vumsy patch installed successfully! >> "%LOG_FILE%"
        )
    )
) else if "%INSTALL_PATCH%"=="3" (
    echo Installing Aftermath patch... >> "%LOG_FILE%"
    
    :: Create mod directory if it doesn't exist
    set "MOD_DIR=!OPEN_SERVER_DIR!\mod"
    echo MOD_DIR is: !MOD_DIR! >> "%LOG_FILE%"
    mkdir "!MOD_DIR!" 2>nul

    :: Clean up existing content in the mod directory (remove files and directories)
    echo Cleaning up existing mod files... >> "%LOG_FILE%"
    rd /s /q "!MOD_DIR!" 2>nul
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Failed to clean mod folder. >> "%LOG_FILE%"
    ) else (
        echo Existing mod files removed successfully. >> "%LOG_FILE%"
    )

    :: Re-create the mod directory after cleanup
    mkdir "!MOD_DIR!" 2>nul

    :: Download Aftermath patch (Aftermath.zip)
    echo Downloading Aftermath.zip... >> "%LOG_FILE%"
    powershell -Command "& {Invoke-WebRequest -Uri '!URL_AFTERMATH_PATCH!' -OutFile '!TEMP_DIR!\Aftermath.zip'}"
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Failed to download Aftermath.zip >> "%LOG_FILE%"
        echo Aftermath patch installation failed. >> "%LOG_FILE%"
    ) else (
        echo Aftermath patch downloaded successfully. Extracting files... >> "%LOG_FILE%"
        powershell -Command "& {Expand-Archive -Path '!TEMP_DIR!\Aftermath.zip' -DestinationPath '!MOD_DIR!' -Force}"
        if %ERRORLEVEL% NEQ 0 (
            echo [ERROR] Failed to extract Aftermath.zip >> "%LOG_FILE%"
            echo Extraction failed. >> "%LOG_FILE%"
        ) else (
            echo Aftermath patch installed successfully! >> "%LOG_FILE%"
        )
    )
) else if /i "%INSTALL_PATCH%"=="N" (
    echo Skipping patch installation. >> "%LOG_FILE%"
) else (
    echo Invalid choice. Skipping patch installation. >> "%LOG_FILE%"
)


echo.
echo Setup completed successfully!
echo A log of this installation is available at "%LOG_FILE%"


:: Prompt to run the launcher (TODO: ADJUST TO ENSURE IT CAN FIND AND LAUNCH MODENGINE2 CORRECTLY)
echo.
set /p RUN_LAUNCHER="Would you like to run the Armored Core 6 mod launcher now? (Y/N): "
if /i "%RUN_LAUNCHER%"=="Y" (
    echo Launching Armored Core 6 mod... >> "%LOG_FILE%"
    
    :: Set the full path to the modengine2_launcher.exe and config file
    echo OPEN_SERVER_DIR is: %OPEN_SERVER_DIR%>> "%LOG_FILE%"
    set "MODENGINE_PATH=!OPEN_SERVER_DIR!\modengine2_launcher.exe"
    set "CONFIG_PATH=!OPEN_SERVER_DIR!\config_armoredcore6.toml"
    
    :: Debugging: Print the paths to make sure they are correct
    echo MODENGINE_PATH: "!MODENGINE_PATH!"
    echo CONFIG_PATH: "!CONFIG_PATH!"

    :: Check if the launcher exists before trying to run it
    if not exist "!MODENGINE_PATH!" (
        echo Error: modengine2_launcher.exe not found at "!MODENGINE_PATH!".
        exit /b 1
    )

    :: Change code page for Unicode support
    chcp 65001
    
    :: Run modengine2_launcher.exe with the full paths, making sure to quote the paths
    echo Running command: "!MODENGINE_PATH!" -t ac6 -c "!CONFIG_PATH!"
    "!MODENGINE_PATH!" -t ac6 -c "!CONFIG_PATH!"
) else (
    echo.
    echo To run the mod later, execute:
    echo "%DOCUMENTS_DIR%\!OPEN_SERVER_DIR!\launchmod_armoredcore6.bat"
)

pause
goto menu

:cleanup_mod
echo.
set /p CONFIRMATION="WARNING: This will delete OpenServer and ALL MODDED SAVES (not ending in .sl2). Do you wish to continue (Y/N): "
if "%CONFRIMATION%"=="Y" (
    echo Starting cleanup to remove mod changes...
    echo.

    :: Get the Open Server directory name
    if exist "%TEMP_DIR%\server_dir_name.txt" (
    set /p OPEN_SERVER_DIR=<"%TEMP_DIR%\server_dir_name.txt"
    ) else (
    :: If file doesn't exist, try to find the directory
    for /d %%i in ("%DOCUMENTS_DIR%\Open*Server*") do (
        set "OPEN_SERVER_DIR=%%~nxi"
        goto found_dir_cleanup
    )
    echo Could not find the Open Server directory to remove.
    echo Please manually check your Documents folder for any "Open Server" directories.
    pause
    goto menu
    )

    :found_dir_cleanup
    :: Remove PVP save file
    echo Removing AC60000.pvp file...
    if exist "%AC6_SAVE_DIR%\AC60000.pvp" (
    del "%AC6_SAVE_DIR%\AC60000.pvp"
    echo - Removed PVP save file
    ) else (
    echo - PVP save file not found
    )

    :: Robust directory removal with error handling
    echo Removing Open Server directory...
    if exist "%DOCUMENTS_DIR%\%OPEN_SERVER_DIR%" (
    :: Use multiple methods to ensure directory removal
    rd /s /q "%DOCUMENTS_DIR%\%OPEN_SERVER_DIR%" 2>nul
    if exist "%DOCUMENTS_DIR%\%OPEN_SERVER_DIR%" (
        :: If rd fails, use alternative removal method
        rmdir /s /q "%DOCUMENTS_DIR%\%OPEN_SERVER_DIR%" 2>nul
    )

    :: Final check and manual deletion of stubborn files
    if exist "%DOCUMENTS_DIR%\%OPEN_SERVER_DIR%" (
        echo - Attempting forced removal of files...
        del /f /s /q "%DOCUMENTS_DIR%\%OPEN_SERVER_DIR%\*.*" 2>nul
        rd /s /q "%DOCUMENTS_DIR%\%OPEN_SERVER_DIR%" 2>nul
    )

    if not exist "%DOCUMENTS_DIR%\%OPEN_SERVER_DIR%" (
        echo - Removed Open Server directory successfully
    ) else (
        echo - WARNING: Could not completely remove the directory
        echo   You may need to manually delete "%DOCUMENTS_DIR%\%OPEN_SERVER_DIR%"
    )
    ) else (
    echo - Open Server directory not found
    )

    :: Clean up temp files
    echo Cleaning up temporary files...
    if exist "%TEMP_DIR%" (
    rd /s /q "%TEMP_DIR%" 2>nul
    echo - Removed temporary files
    )

    echo.
    echo Cleanup completed!
    echo Check above for any warnings about directory removal.
) else (
    echo.
    echo No problem, won't delete anything.
    echo.
)

pause
goto menu

:: Update files
:update_mod_files
echo.
echo Coming very soon, I promise. Please continue to bear with me and the modmakers as we set up our infrastructure.
echo.
pause
goto menu