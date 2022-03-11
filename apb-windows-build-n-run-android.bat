:: =======================================================================================================================
:: AppBrahma script for building and running unimobile app on Windows
:: Author :Venkateswar Reddy Melachervu
:: History:
::		16-12-2021 - Creation
::      17-12-2021 - Added gracious error handling and recovery mechansim for already added android platform
::      26-12-2021 - Added error handling and android sdk path check
::      20-01-2022 - Created script for linux
::      29-01-2022 - Updated
::      27-02-2022 - Updated for streamlining exit error codes and re-organizing build code into a function for handling 
::                   dependency version incompatibilities
::		07-03-2022 - Updated for function exit codes, format and app display prefix
::		08-03-2022 - Updated for pre-req version validations
:: =======================================================================================================================

@echo off
Setlocal EnableDelayedExpansion
set "MOBILE_GENERATOR_NAME=UniBrahma"
set "MOBILE_GENERATOR_LINE_PREFIX=[%MOBILE_GENERATOR_NAME%]"
set "NODE_MAJOR_VERSION=16"
set "NPM_MAJOR_VERSION=6"
set "IONIC_CLI_MAJOR_VERSION=6"
set "IONIC_CLI_MINOR_VERSION=16"
set "JAVA_MIN_VERSION=11"
set "EXIT_ERROR_CODE=200"
set "EXIT_WINDOWS_VERSION_CHECK_COMMAND_ERROR_CODE=201"
set "EXIT_NODE_VERSION_CHECK_COMMAND_ERROR_CODE=202"
set "EXIT_NPM_VERSION_CHECK_COMMAND_ERROR_CODE=203"
set "EXIT_IONIC_CLI_VERSION_CHECK_COMMAND_ERROR_CODE=204"
set "EXIT_JAVA_VERSION_CHECK_COMMAND_ERROR_CODE=205"
set "EXIT_JDK_VERSION_CHECK_COMMAND_ERROR_CODE=206"
set "EXIT_NPM_INSTALL_COMMAND_ERROR_CODE=207"
set "EXIT_IONIC_BUILD_COMMAND_ERROR_CODE=208"
set "EXIT_IONIC_CAP_ADD_PLATFORM_COMMAND_ERROR_CODE=209"
set "EXIT_UNIMO_INSTALL_BUILD_ERROR_CODE=210"
set "EXIT_IONIC_RE_RUN_INSTALL_AND_BUILD=211"
set "EXIT_CORDOVA_RES_COMMAND_INSTALL_ERROR_CODE=212"
set "EXIT_CORDOVA_RES_COMMAND_ERROR_CODE=213"
set "EXIT_ADB_DEV_LIST_COMMAND_ERROR_CODE=214"
set "EXIT_IONIC_CAP_RUN_COMMAND_ERROR_CODE=215"
set "EXIT_ADB_REVERSE_COMMAND_ERROR_CODE=216"

:: clear the screen for better visibility
call cls

echo ==========================================================================================================================================
echo 					Welcome to %MOBILE_GENERATOR_NAME% Unimobile app build and run script
echo Sit back, relax, and sip a cup of coffee while the dependencies are download, project is built, and run. 
echo Unless the execution of this script stops, do not be bothered nor worried about any warnings or errors displayed during the execution ;-^)
echo ==========================================================================================================================================
echo.

:: windows os name and version
set "for_exec_result="
echo %MOBILE_GENERATOR_LINE_PREFIX% : Your Windows version details are :
for /F "tokens=*" %%G in ('systeminfo ^| findstr /B /C:"OS Name" /C:"OS Version"') do (			
	echo %%G
)	
:: nodejs version check
for /F "tokens=*" %%G in ('node --version') do (									
	set "for_exec_result=%%G"
)	
for /f "tokens=1,2,3 delims=." %%G in ("!for_exec_result!") do (	
	set "raw_major_ver=%%G"	
	for /f "tokens=1 delims=v" %%J in ("!raw_major_ver!") do (
		set "major_verion=%%J"
	)			
	if !major_verion! LSS %NODE_MAJOR_VERSION% (
		echo %MOBILE_GENERATOR_LINE_PREFIX% : You are running non-supported nodejs version "%%G.%%H.%%I"^^!
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Minimum required version is %NODE_MAJOR_VERSION%+. Please upgrade nodejs and retry this script.
    	echo %MOBILE_GENERATOR_LINE_PREFIX% : Aborting the build process^^!		
		exit /b %EXIT_NODE_VERSION_CHECK_COMMAND_ERROR_CODE%
	)
)
echo %MOBILE_GENERATOR_LINE_PREFIX% : Nodejs version requirement - !for_exec_result! - met, moving ahead with other checks...

:: npm version check
for /F "tokens=*" %%G in ('npm --version') do (									
	set "for_exec_result=%%G"
)	
for /f "tokens=1,2,3 delims=." %%G in ("!for_exec_result!") do (		
	if %%G LSS %NPM_MAJOR_VERSION% (
		echo %MOBILE_GENERATOR_LINE_PREFIX% : You are running non-supported "npm version %%G.%%H.%%I" for building and running AppBrahma generated Unimobile application project sources^^!
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Minimum required version is %NPM_MAJOR_VERSION%+. Please upgrade npm and retry this script.
    	echo %MOBILE_GENERATOR_LINE_PREFIX% : Aborting the build process^^!
		exit /b %EXIT_NPM_VERSION_CHECK_COMMAND_ERROR_CODE%
	)
)
echo %MOBILE_GENERATOR_LINE_PREFIX% : NPM version requirement - !for_exec_result! - met, moving ahead with other checks...
:: ionic cli version check
for /F "tokens=*" %%G in ('ionic --version') do (									
	set "for_exec_result=%%G"
)	
for /f "tokens=1,2,3 delims=." %%G in ("!for_exec_result!") do (		
	if %%G LSS %IONIC_CLI_MAJOR_VERSION% (
		echo %MOBILE_GENERATOR_LINE_PREFIX% : You are running non-supported "ionic version %%G.%%H.%%I" for building and running AppBrahma generated Unimobile application project sources^^!
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Minimum required version is %IONIC_CLI_MAJOR_VERSION%+. Please upgrade npm and retry this script.
    	echo %MOBILE_GENERATOR_LINE_PREFIX% : Aborting the build process^^!
		exit /b %EXIT_NPM_VERSION_CHECK_COMMAND_ERROR_CODE%
	) 
)
echo %MOBILE_GENERATOR_LINE_PREFIX% : Ionic CLI version requirement - !for_exec_result! - met, moving ahead with other checks...

:: Android sdk/adb check
set "expected_min_string=List of devices attached"
set "for_exec_result="
for /F "tokens=*" %%G in ('adb devices') do (									
	set "for_exec_result=%%G"
)
if "!substituted_string!" == "!for_exec_result!" (
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Android SDK and tools appear to be not installed or ANDROID_HOME/tools directory is NOT in PATH!    
    echo %MOBILE_GENERATOR_LINE_PREFIX% : Please install or update PATH for Android SDK with tools and retry running this script^^!
    exit /b %EXIT_ADB_DEV_LIST_COMMAND_ERROR_CODE%
)
echo %MOBILE_GENERATOR_LINE_PREFIX% : Android tools found in the path for running emulator - moving ahead with other checks...
:: java runtime version check
set "first_line_string="
set "first_line=1"
for /F "tokens=*" %%G in ('java -version  2^>^&1 1^> nul') do (	
	if !first_line! EQU 1 (
		set "first_line_string=%%G"
		set /a first_line=!first_line!+1
	)	
)
set "third_token="
::  percent~I on commandline or percent percent~I in batch file expands percent I removing any surrounding quotes	
for /F "tokens=1,2,3,4,5 delims= " %%G in ("!first_line_string!") do (	
	set third_token=%%~I	
)
set "java_major_version="
set "java_minor_version="
set "java_patch_version="
for /F "tokens=1,2,3 delims=." %%G in ("!third_token!") do (
	set java_major_version=%%G
	set java_minor_version=%%H
	set java_patch_version=%%I
)
if !java_major_version! LSS %JAVA_MIN_VERSION% (
	echo %MOBILE_GENERATOR_LINE_PREFIX% : You are running non-supported Java version !third_token! 
    echo %MOBILE_GENERATOR_LINE_PREFIX% : Minimum required major version is %JAVA_MIN_MAJOR_VERSION+%
    echo %MOBILE_GENERATOR_LINE_PREFIX% : Aborting the build process. Please install a stable and LTS java release of major version %JAVA_MIN_MAJOR_VERSION%+ and retry running this script.    
    exit /b %EXIT_JAVA_VERSION_CHECK_COMMAND_ERROR_CODE%
)
echo %MOBILE_GENERATOR_LINE_PREFIX% : Java runtime version requirement -!third_token!- met, moving ahead with other checks...

:: jdk check
call javac --version  2>nul 1> nul
if !ERRORLEVEL! NEQ 0 (
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Java SDK appears to be not installed or NOT in PATH!    
    echo %MOBILE_GENERATOR_LINE_PREFIX% : Please install or update PATH for Java JDK and retry running this script^^!
    exit /b %EXIT_JDK_VERSION_CHECK_COMMAND_ERROR_CODE%
)
echo %MOBILE_GENERATOR_LINE_PREFIX% : Java JDK found in the path for building app and running emulator - moving ahead with other checks...

:: install deps and build unimobile app
call :unimo_install_ionic_deps_build_and_platform
if !ERRORLEVEL! NEQ 0 (  
	:: echo %MOBILE_GENERATOR_LINE_PREFIX% : Error returned by unimo_install_ionic_deps_build_and_platform is : !ERRORLEVEL!  
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Error in building the project and installing android platform^^! 
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Aborting %MOBILE_GENERATOR_NAME% unimobile app build and run script            
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Please retry running %MOBILE_GENERATOR_NAME% build and run script after deleting the node_modules, android, and www direcrtories in this project folder, if they exist.
	exit /b !ERRORLEVEL!
)

echo %MOBILE_GENERATOR_LINE_PREFIX% : Customizing Unimobile application icon and splash images...
call cordova-res android --skip-config --copy
if %ERRORLEVEL% NEQ 0 (
    echo %MOBILE_GENERATOR_LINE_PREFIX% : Error customizing the application icon and splash images^^!
    echo %MOBILE_GENERATOR_LINE_PREFIX% : Aborting %MOBILE_GENERATOR_NAME%  unimobile build and run script.
    echo %MOBILE_GENERATOR_LINE_PREFIX% : Please retry running %MOBILE_GENERATOR_NAME% build and run script after deleting the node_modules, android, and www direcrtories in this project folder, if they exist.
    exit /b !ERRORLEVEL!
)
echo %MOBILE_GENERATOR_LINE_PREFIX% : Starting Android simulator for running the Unimobile app...
call ionic cap run android
if %ERRORLEVEL% NEQ 0 (
    echo %MOBILE_GENERATOR_LINE_PREFIX% : Error running Android simulator and running your Unimobile application.    
    echo %MOBILE_GENERATOR_LINE_PREFIX% : Please retry running %MOBILE_GENERATOR_NAME% build and run script after deleting the node_modules, android, and www direcrtories in this project folder, if they exist.
    exit /b !ERRORLEVEL!
)

echo %MOBILE_GENERATOR_LINE_PREFIX% : Configuring Android simulator to access the Appbrahma server port on the network...
call adb reverse tcp:8091 tcp:8091 
if %ERRORLEVEL% NEQ 0 (
    echo %MOBILE_GENERATOR_LINE_PREFIX% : Error confuguring android simulator to access the server port on the netwoork^^!    
    echo %MOBILE_GENERATOR_LINE_PREFIX% : Please try exeucting the command - adb reverse tcp:8091 tcp:8091 - for establishing seamless connection between server and this app for REST calls.
    exit /b !ERRORLEVEL!
)
:: Display credentials for log in - for server integrated template
echo %MOBILE_GENERATOR_LINE_PREFIX% : Please use the below log in credentials to log into the appbrahma generated server from the Unimobile app after running the backend server in a seperate console window
echo Username: brahma
echo Password: brahma@appbrahma
endlocal
exit /b !ERRORLEVEL!
:: End of the main script - functions/sub-routines follow next

:: node dependencies install, ionic build, and add capacitor platform function
:unimo_install_ionic_deps_build_and_platform
	setlocal EnableDelayedExpansion			
	
	call :npm_install
	if !ERRORLEVEL! NEQ 0 ( 
		set "exit_code=!ERRORLEVEL!"
		exit /b !exit_code! 
	)			

	call :ionic_build	
	if !ERRORLEVEL! NEQ 0 ( 
		set "exit_code=!ERRORLEVEL!"
		exit /b !exit_code!		
	)	
	
	call :add_cap_platform	
	if !ERRORLEVEL! NEQ 0 ( 
		if !ERRORLEVEL! EQU %EXIT_IONIC_RE_RUN_INSTALL_AND_BUILD% (
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Preparing to re-install Android capacitor platform...											
			call :unimo_install_ionic_deps_build_and_platform
			if !ERRORLEVEL! NEQ 0 ( 
				set "exit_code=!ERRORLEVEL!"
				exit /b !exit_code!		
			) else (
				exit /b 0	
			)						
		) else (
			set "exit_code=!ERRORLEVEL!"
			exit /b !exit_code!			
		)		
	) else (
		exit /b 0
	)	
	set "exit_code=!ERRORLEVEL!"
	exit /b !exit_code!

:npm_install
	setlocal EnableDelayedExpansion
	set "for_exec_result="	
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Installing nodejs dependencies...			
	call npm install	
	if !ERRORLEVEL! NEQ 0 (
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Error installing nodejs dependencies^!
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Fixing the errors...
		for /F "tokens=*" %%G in ('rmdir /S /Q "node_modules" 2^>^&1 1^> nul') do (									
			set "for_exec_result=!for_exec_result! %%G"			
		)						
		if "!for_exec_result!" == "" (		
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Fixing nodejs dependencies installation errors.
			call :npm_reinstall								
			exit /b 0
		) else (
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Error deleting the node_modules directory for fixing node dependency install errors^^!	
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Error message is : "!for_exec_result!"
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Aborting the build and run process. Please delete the node_modules directory manually and retry running this script.
			exit /b %EXIT_NPM_INSTALL_COMMAND_ERROR_CODE%
		)	
	) else (
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Installed nodejs dependencies.
		exit /b 0
	)		

:npm_reinstall	
	setlocal EnableDelayedExpansion
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Now re-installing nodejs dependencies...
	call npm install
	if !ERRORLEVEL! NEQ 0 (
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Re-attempt to install nodejs dependencies resulted in error^!
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Error details reported by npm are shown above.
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Aborting Unimobile build and run process. 
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Please retry running appbrahma build and run script after manually deleting the node_modules direcrtory in this project directory.
		exit /b %EXIT_NPM_INSTALL_COMMAND_ERROR_CODE%		
	) else ( 
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Re-installed nodejs dependencies. 
		exit /b 0
	)
	exit /b !ERRORLEVEL!		

:ionic_build
	setlocal EnableDelayedExpansion
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Now building the project using ionic build...	
	call ionic build
	if !ERRORLEVEL! NEQ 0 (
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Error building the project. Error details reported by ionic build are shown above.
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Aborting appbrahma unimobile build and run script.	    
	        echo %MOBILE_GENERATOR_LINE_PREFIX% : Please retry running the script after fixing these reported errors.
        	exit /b %EXIT_IONIC_BUILD_COMMAND_ERROR_CODE%
	) else ( 
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Ionic build completed successfully.
		exit /b 0
	)
	exit /b !ERRORLEVEL!
	
:add_cap_platform
	setlocal EnableDelayedExpansion		
	set "for_exec_result="	
	echo %MOBILE_GENERATOR_LINE_PREFIX% : Now installing Android capacitor platform...    	
	call ionic capacitor add android			
	if !ERRORLEVEL! NEQ 0 (
		echo %MOBILE_GENERATOR_LINE_PREFIX% : It appears Android capacitor platform was already installed or installed nodejs dependencies are incomptabile^^!
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Resolving these issues...
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Removing android platform, installed nodejs dependencies, and web directories...		
		for /F "tokens=*" %%G in ('rmdir /S /Q "android" "www" "node_modules" 2^>^&1 1^> nul') do (									
			set "for_exec_result=!for_exec_result! %%G"			
		)
		if "!for_exec_result!" == ""  (
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Removed android platform, installed nodejs dependencies, and web directories.		
			exit /b %EXIT_IONIC_RE_RUN_INSTALL_AND_BUILD%			
		) else (
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Error removing node_modules, android, and www directories for re-installig Android platform^^!	
			echo %MOBILE_GENERATOR_LINE_PREFIX% : The error message is : "%for_exec_result%"
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Aborting the build and run process. 
			echo %MOBILE_GENERATOR_LINE_PREFIX% : Please retry running this script after fixing above errors.						
			exit /b %EXIT_IONIC_CAP_ADD_PLATFORM_COMMAND_ERROR_CODE%	
		)						
	) else (
		echo %MOBILE_GENERATOR_LINE_PREFIX% : Android capacitor platform installed successfully.	
		exit /b 0
	)
	set "exit_code=!ERRORLEVEL!"
	exit /b !exit_code!	

:: End of the script
