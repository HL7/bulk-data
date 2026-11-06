@ECHO OFF
setlocal enabledelayedexpansion

SET "dlurl=https://github.com/HL7/fhir-ig-publisher/releases/latest/download/publisher.jar"
SET "publisher_jar=publisher.jar"
SET "input_cache_path=%CD%\input-cache\"
IF DEFINED FHIR_PUBLISHER_HOME (
    SET "publisher_home=%FHIR_PUBLISHER_HOME%"
) ELSE (
    SET "publisher_home=%USERPROFILE%\.fhir\tools\publisher"
)
SET "skipPrompts=false"
SET "upper_path=..\"
SET "scriptdlroot=https://raw.githubusercontent.com/HL7/ig-publisher-scripts/main"
SET "build_bat_url=%scriptdlroot%/_build.bat"
SET "build_sh_url=%scriptdlroot%/_build.sh"



:: Debugging statements to check jar file location
ECHO Checking for publisher.jar in %input_cache_path%
IF EXIST "%input_cache_path%%publisher_jar%" (
    SET "jar_location=%input_cache_path%%publisher_jar%"
    ECHO Found publisher.jar in input-cache
) ELSE (
    ECHO Checking for publisher.jar in %upper_path%
    IF EXIST "%upper_path%%publisher_jar%" (
        SET "jar_location=%upper_path%%publisher_jar%"
        ECHO Found publisher.jar in parent folder
    ) ELSE (
        ECHO Checking for publisher.jar in %publisher_home%
        IF EXIST "%publisher_home%\%publisher_jar%" (
            SET "jar_location=%publisher_home%\%publisher_jar%"
            ECHO Found publisher.jar in FHIR publisher home
        ) ELSE (
            SET "jar_location=not_found"
            SET "default_choice=1"
            SET "default_reason=publisher not found"
            ECHO publisher.jar not found in input-cache, parent folder, or FHIR publisher home
        )
    )
)


:: Handle command-line argument to bypass the menu
:: Known first arguments select a menu option; anything else is passed through to the publisher
SET "extraArgs="
IF "%~1"=="" GOTO showMenu
IF /I "%~1"=="update" SET "userChoice=1" & GOTO parseExtra
IF /I "%~1"=="build" SET "userChoice=2" & GOTO parseExtra
IF /I "%~1"=="nosushi" SET "userChoice=3" & GOTO parseExtra
IF /I "%~1"=="notx" SET "userChoice=4" & GOTO parseExtra
IF /I "%~1"=="jekyll" SET "userChoice=5" & GOTO parseExtra
IF /I "%~1"=="clean" SET "userChoice=6" & GOTO parseExtra
IF /I "%~1"=="exit" SET "userChoice=0" & GOTO parseExtra
:: Unknown first arg - default to build, pass all args through
SET "userChoice=2"
GOTO collectArgs
:parseExtra
SHIFT
:collectArgs
IF "%~1"=="" GOTO executeChoice
SET "extraArgs=!extraArgs! %1"
SHIFT
GOTO collectArgs
:showMenu

echo ---------------------------------------------------------------
ECHO Checking internet connection...
powershell -Command "try { $r=[System.Net.WebRequest]::Create('https://tx.fhir.org/r4/metadata'); $r.Timeout=4000; $r.GetResponse().Close(); exit 0 } catch { exit 1 }"
IF %ERRORLEVEL% EQU 0 (SET "online_status=true") ELSE (SET "online_status=false")

IF "%online_status%"=="true" (
    ECHO We are online and tx.fhir.org is available.
    FOR /F "tokens=2 delims=:" %%a IN ('curl -s https://api.github.com/repos/HL7/fhir-ig-publisher/releases/latest ^| findstr "tag_name"') DO SET "latest_version=%%a"
    SET "latest_version=!latest_version:"=!"
    SET "latest_version=!latest_version: =!"
    SET "latest_version=!latest_version:~0,-1!"
) ELSE (
    ECHO.
    ECHO *** WARNING: Working offline - this is not the normal mode.
    ECHO     Some features including terminology rendering will not work.
    ECHO.
    SET "txoption=-tx n/a"
    SET "latest_version=unknown"
    SET "default_choice=4"
    SET "default_reason=working offline"
)

echo ---------------------------------------------------------------


IF NOT "%jar_location%"=="not_found" (
    FOR /F "tokens=*" %%i IN ('java "-Dfile.encoding=UTF-8" -jar "%jar_location%" -v 2^>^&1') DO SET "publisher_version=%%i"
    SET "publisher_version=!publisher_version:"=!"
    ECHO Detected publisher version: !publisher_version!
) ELSE (
    SET "publisher_version=unknown"
    ECHO publisher.jar location is not found
)

ECHO Publisher version: !publisher_version!; Latest is !latest_version!

IF NOT "%online_status%"=="true" (
   ECHO We are offline.
) ELSE (
    IF NOT "!publisher_version!"=="!latest_version!" (
        ECHO An update is recommended.
        SET "default_choice=1"
        SET "default_reason=newer version available"
    ) ELSE (
        ECHO Publisher is up to date.
        SET "default_choice=2"
        SET "default_reason=publisher is up to date"
    )
)

echo ---------------------------------------------------------------
echo.

echo Please select an option:
echo 1. Download or update publisher
echo 2. Build IG
echo 3. Build IG - no sushi
echo 4. Build IG - force no TX server
echo 5. Jekyll build
echo 6. Clean up temp directories
echo 0. Exit
echo.

choice /C 12345670 /N /CS /D %default_choice% /T 5 /M "Choose an option number or wait 5 seconds for default (%default_choice% - %default_reason%):"
SET "userChoice=%ERRORLEVEL%"


:executeChoice
echo You selected: %userChoice%

IF "%userChoice%"=="1" GOTO downloadpublisher
IF "%userChoice%"=="2" GOTO publish_once
IF "%userChoice%"=="3" GOTO publish_nosushi
IF "%userChoice%"=="4" GOTO publish_notx
IF "%userChoice%"=="5" GOTO debugjekyll
IF "%userChoice%"=="6" GOTO clean
IF "%userChoice%"=="0" EXIT /B
GOTO endscript

:debugjekyll
    echo Running Jekyll build...
    jekyll build -s temp/pages -d output
GOTO endscript


:clean
    echo Cleaning up directories...
    if exist ".\input-cache\publisher.jar" (
        echo Preserving publisher.jar and removing other files in .\input-cache...
        move ".\input-cache\publisher.jar" ".\"
        rmdir /s /q ".\input-cache"
        mkdir ".\input-cache"
        move ".\publisher.jar" ".\input-cache"
    ) else (
        if exist ".\input-cache\" (
            rmdir /s /q ".\input-cache"
        )
    )
    if exist ".\temp\" (
        rmdir /s /q ".\temp"
        echo Removed: .\temp
    )
    if exist ".\output\" (
        rmdir /s /q ".\output"
        echo Removed: .\output
    )
    if exist ".\template\" (
        rmdir /s /q ".\template"
        echo Removed: .\template
    )

GOTO endscript


:downloadpublisher
ECHO Downloading Publisher...
:processflags
SET ARG=%1
IF DEFINED ARG (
	IF "%ARG%"=="-f" SET FORCE=true
	IF "%ARG%"=="--force" SET FORCE=true
	SHIFT
	GOTO processflags
)

ECHO.
IF EXIST "%input_cache_path%%publisher_jar%" (
	ECHO IG Publisher FOUND in input-cache
	SET "jarlocation=%input_cache_path%%publisher_jar%"
	SET "jarlocationname=Input Cache"
	GOTO upgrade
)
SET "jarlocation=%publisher_home%\%publisher_jar%"
SET "jarlocationname=FHIR Publisher Home"
IF EXIST "%publisher_home%\%publisher_jar%" (
	ECHO IG Publisher FOUND in FHIR publisher home
	GOTO upgrade
)
ECHO IG Publisher is not yet in input-cache or FHIR publisher home.
GOTO create

:create
IF DEFINED FORCE (
	MKDIR "%publisher_home%" 2> NUL
	GOTO download
)

IF "%skipPrompts%"=="true" (
	SET create=Y
) ELSE (
	SET /p create="Download? (Y/N) "
)
IF /I "%create%"=="Y" (
	ECHO Will place publisher jar here: %jarlocation%
	MKDIR "%publisher_home%" 2> NUL
	GOTO download
)
GOTO done

:upgrade
IF "%skipPrompts%"=="true" (
	SET overwrite=Y
) ELSE (
	SET /p overwrite="Overwrite %jarlocation%? (Y/N) "
)

IF /I "%overwrite%"=="Y" (
	GOTO download
)
GOTO done

:download
ECHO Downloading most recent publisher to %jarlocationname% - it's ~200 MB, so this may take a bit

FOR /f "tokens=4-5 delims=. " %%i IN ('ver') DO SET VERSION=%%i.%%j
IF "%version%" == "10.0" GOTO win10
IF "%version%" == "6.3" GOTO win8.1
IF "%version%" == "6.2" GOTO win8
IF "%version%" == "6.1" GOTO win7
IF "%version%" == "6.0" GOTO vista

ECHO Unrecognized version: %version%
GOTO done

:win10
CALL POWERSHELL -command if ('System.Net.WebClient' -as [type]) {(new-object System.Net.WebClient).DownloadFile(\"%dlurl%\",\"%jarlocation%\") } else { Invoke-WebRequest -Uri "%dlurl%" -Outfile "%jarlocation%" }

GOTO done

:win7
rem this may be triggering the antivirus - bitsadmin.exe is a known threat
rem CALL bitsadmin /transfer GetPublisher /download /priority normal "%dlurl%" "%jarlocation%"

rem this didn't work in win 10
rem CALL Start-BitsTransfer /priority normal "%dlurl%" "%jarlocation%"

rem this should work - untested
call (New-Object Net.WebClient).DownloadFile('%dlurl%', '%jarlocation%')
GOTO done

:win8.1
:win8
:vista
GOTO done



:done




ECHO.
ECHO Updating scripts
IF "%skipPrompts%"=="true" (
	SET updateScripts=Y
) ELSE (
	SET /p updateScripts="Update scripts? (Y/N) "
)
IF /I "%updateScripts%"=="Y" (
	GOTO scripts
)
GOTO endscript


:scripts

REM Download all batch files (and this one with a new name)

SETLOCAL DisableDelayedExpansion



:dl_script_1
ECHO Updating _build.sh
call POWERSHELL -command if ('System.Net.WebClient' -as [type]) {(new-object System.Net.WebClient).DownloadFile(\"%build_sh_url%\",\"_build.new.sh\") } else { Invoke-WebRequest -Uri "%build_sh_url%" -Outfile "_build.new.sh" }
if %ERRORLEVEL% == 0 goto upd_script_1
echo "Errors encountered during download: %errorlevel%"
goto dl_script_2
:upd_script_1
start copy /y "_build.new.sh" "_build.sh" ^&^& del "_build.new.sh" ^&^& exit


:dl_script_2
ECHO Updating _build.bat
call POWERSHELL -command if ('System.Net.WebClient' -as [type]) {(new-object System.Net.WebClient).DownloadFile(\"%build_bat_url%\",\"_build.new.bat\") } else { Invoke-WebRequest -Uri "%build_bat_url%" -Outfile "_build.new.bat" }
if %ERRORLEVEL% == 0 goto upd_script_2
echo "Errors encountered during download: %errorlevel%"
goto endscript
:upd_script_2
start copy /y "_build.new.bat" "_build.bat" ^&^& del "_build.new.bat" ^&^& exit


GOTO endscript


:publish_once

SET JAVA_TOOL_OPTIONS=-Dfile.encoding=UTF-8

:: Debugging statements before running publisher
ECHO jar_location is: %jar_location%
IF NOT "%jar_location%"=="not_found" (
	ECHO IG Publisher FOUND, Publishing...
	java %JAVA_OPTS% -jar "%jar_location%" -ig . %txoption% %extraArgs%
) ELSE (
	ECHO IG Publisher NOT FOUND in input-cache, parent folder, or FHIR publisher home.  Please run the script and update the publisher.  Aborting...
)

GOTO endscript



:publish_nosushi

SET JAVA_TOOL_OPTIONS=-Dfile.encoding=UTF-8

:: Debugging statements before running publisher
ECHO jar_location is: %jar_location%
IF NOT "%jar_location%"=="not_found" (
	java %JAVA_OPTS% -jar "%jar_location%" -ig . %txoption% -no-sushi %extraArgs%
) ELSE (
	ECHO IG Publisher NOT FOUND in input-cache, parent folder, or FHIR publisher home. Please run the script and update the publisher.  Aborting...
)

GOTO endscript


:publish_notx
SET txoption=-tx n/a

SET JAVA_TOOL_OPTIONS=-Dfile.encoding=UTF-8

:: Debugging statements before running publisher
ECHO jar_location is: %jar_location%
IF NOT "%jar_location%"=="not_found" (
	java %JAVA_OPTS% -jar "%jar_location%" -ig . %txoption% %extraArgs%
) ELSE (
	ECHO IG Publisher NOT FOUND in input-cache, parent folder, or FHIR publisher home.  Please run the script and update the publisher.  Aborting...
)

GOTO endscript


:publish_continuous

SET JAVA_TOOL_OPTIONS=-Dfile.encoding=UTF-8

ECHO jar_location is: %jar_location%
IF NOT "%jar_location%"=="not_found" (
	java %JAVA_OPTS% -jar "%jar_location%" -ig . %txoption% -watch %extraArgs%
) ELSE (
	ECHO IG Publisher NOT FOUND in input-cache, parent folder, or FHIR publisher home.  Please run the script and update the publisher.  Aborting...
)

GOTO endscript


:endscript

:: Pausing at the end
IF NOT "%skipPrompts%"=="true" (
  PAUSE
)
