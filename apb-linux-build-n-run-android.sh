#!/bin/sh
# =======================================================================================================================
# appbrahma-build-and-run-android.sh
# AppBrahma Android Unimobile App building and running
# Created by Venkateswar Reddy Melachervu on 16-11-2021.
# Updates:
#      17-12-2021 - Added gracious error handling and recovery mechansim for already added android platform
#      26-12-2021 - Added error handling and android sdk path check
#      20-01-2022 - Created script for linux
#      29-01-2022 - Updated
#      27-02-2022 - Updated for streamlining exit error codes and re-organizing build code into a function for handling 
#                   dependency version incompatibilities
#      07-03-2022 - Updated for function exit codes, format and app display prefix
#      08-03-2022 - Synchronized with windows batch ejs file
# =======================================================================================================================

# Required version values
MOBILE_GENERATOR_NAME=UniBrahma
MOBILE_GENERATOR_LINE_PREFIX=\[$MOBILE_GENERATOR_NAME]
NODE_MAJOR_VERSION=16
NPM_MAJOR_VERSION=6
IONIC_CLI_MAJOR_VERSION=6
IONIC_CLI_MINOR_VERSION=16
JAVA_MIN_VERSION=11
EXIT_ERROR_CODE=200
EXIT_LINUX_VERSION_CHECK_COMMAND_ERROR_CODE=201
EXIT_NODE_VERSION_CHECK_COMMAND_ERROR_CODE=202
EXIT_NPM_VERSION_CHECK_COMMAND_ERROR_CODE=203
EXIT_IONIC_CLI_VERSION_CHECK_COMMAND_ERROR_CODE=204
EXIT_JAVA_VERSION_CHECK_COMMAND_ERROR_CODE=205
EXIT_JDK_VERSION_CHECK_COMMAND_ERROR_CODE=206
EXIT_NPM_INSTALL_COMMAND_ERROR_CODE=207
EXIT_IONIC_BUILD_COMMAND_ERROR_CODE=208
EXIT_IONIC_CAP_ADD_PLATFORM_COMMAND_ERROR_CODE=209
EXIT_UNIMO_INSTALL_BUILD_ERROR_CODE=210
EXIT_IONIC_RE_RUN_INSTALL_AND_BUILD=211
EXIT_CORDOVA_RES_COMMAND_INSTALL_ERROR_CODE=212
EXIT_CORDOVA_RES_COMMAND_ERROR_CODE=213
EXIT_ADB_DEV_LIST_COMMAND_ERROR_CODE=214
EXIT_IONIC_CAP_RUN_COMMAND_ERROR_CODE=215
EXIT_ADB_REVERSE_COMMAND_ERROR_CODE=216


# node dependencies install, ionic build, and add capacitor platform
unimo_install_ionic_deps_build_and_platform() {
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Installing nodejs dependencies..."
	NPM_INSTALL_DEPS=$(npm install --force 2>&1)
    if [ $? -gt 0 ]; then
        echo "$MOBILE_GENERATOR_LINE_PREFIX : Error installing node dependencies!"
        echo "$MOBILE_GENERATOR_LINE_PREFIX : Fixing the errors..."         
        rm -rf node_modules
        if [ $? -gt 0 ]; then
            echo "$MOBILE_GENERATOR_LINE_PREFIX : Error deleting the node_modules directory for fixing node dependency install errors!"
            echo "$MOBILE_GENERATOR_LINE_PREFIX : Error message is : $NPM_INSTALL_DEPS"
            echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting the build and run process. Please delete the node_modules directory manually and retry running this script."
            exit $EXIT_NPM_INSTALL_COMMAND_ERROR_CODE
        else 
            echo "$MOBILE_GENERATOR_LINE_PREFIX : Fixing nodejs dependencies installation errors."
        fi

        echo "$MOBILE_GENERATOR_LINE_PREFIX : Now re-installing nodejs dependencies..."         
        NPM_INSTALL_DEPS=$(npm install --force 2>&1)
        if [ $? -gt 0 ]; then
            echo "$MOBILE_GENERATOR_LINE_PREFIX : Re-attempt to install nodejs dependencies resulted in error!"
            echo "$MOBILE_GENERATOR_LINE_PREFIX : Error details reported by npm are shown beow."            
            echo "----------------------------------------------------------------------------------------------------------------------------------------------------------------------"
            echo $NPM_INSTALL_DEPS
            echo "----------------------------------------------------------------------------------------------------------------------------------------------------------------------"
            echo "$MOBILE_GENERATOR_LINE_PREFIX : Please retry running $MOBILE_GENERATOR_NAME build and run script after manually deleting the node_modules direcrtory in this project directory."
            exit $EXIT_NPM_INSTALL_COMMAND_ERROR_CODE
        fi        
    fi
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Installed nodejs dependencies."
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Now building the project using ionic build..."
    if !(ionic build); then
	    echo "$MOBILE_GENERATOR_LINE_PREFIX : Error building the project. Error details reported by ionic build are shown above."
	    echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting $MOBILE_GENERATOR_NAME unimobile build and run script." 
	    echo "$MOBILE_GENERATOR_LINE_PREFIX : Please retry running the script after fixing these reported errors."
	    exit $EXIT_IONIC_BUILD_COMMAND_ERROR_CODE
    fi
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Ionic build completed successfully."
	echo "$MOBILE_GENERATOR_LINE_PREFIX : Adding capacitor Android platform"
	ADD_CAPACITOR_ANDROID_PLATFORM=$(ionic cap add android 2>&1)
	# $? is the result of last command executed - 0 in case of success and greater than 0 in case of error
	# $ADD_CAPACITOR_ANDROID_PLATFORM will hold the command execution output inclusive of error
	if [ $? -gt 0 ]; then
	    # check for any capacitor cli version in-compatibility error. If so, delete node_modules and run a fresh build using the same script
	    CAP_CLI_ERROR='Error while getting Capacitor CLI version'    
	    PLATFORM_ALREADY_INSTALLED='android platform is already installed'
	    case $ADD_CAPACITOR_ANDROID_PLATFORM in 
	    	*"$CAP_CLI_ERROR"*)	    		
	                echo "$MOBILE_GENERATOR_LINE_PREFIX : Ionic capacitor version incompatibility found. Cleansing older dependencies, installing compatible dependencies for capacitor..."
	                rm -rf node_modules
	                rm -rf www
	                unimo_install_ionic_deps_build_and_platform
	                if [ $? -gt 0 ]; then
	                    echo "$MOBILE_GENERATOR_LINE_PREFIX : Error adding Android platform!"
	                    echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting $MOBILE_GENERATOR_NAME unimobile build and run script."
	                    echo "$MOBILE_GENERATOR_LINE_PREFIX : Please retry running this script after fixing above errors."
	                    exit $EXIT_IONIC_CAP_ADD_PLATFORM_COMMAND_ERROR_CODE
	                fi	
	    	;;
	    	*"$PLATFORM_ALREADY_INSTALLED"*)
	                echo "$MOBILE_GENERATOR_LINE_PREFIX : Android platform was already instaled. Removing and adding afresh for avoiding run time errors..."
	                rm -rf android
	                ADD_CAPACITOR_ANDROID_PLATFORM=$(ionic cap add android 2>&1)
	                if [ $? -gt 0 ]; then
	                    echo "$MOBILE_GENERATOR_LINE_PREFIX : Error adding Android platform!"
	                    echo "$MOBILE_GENERATOR_LINE_PREFIX : The error is:"     
	                    echo "----------------------------------------------------------------------------------------------------------------------------------------------------------------------"                                   
	                    echo $ADD_CAPACITOR_ANDROID_PLATFORM
	                    echo "----------------------------------------------------------------------------------------------------------------------------------------------------------------------"
	                    echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting $MOBILE_GENERATOR_NAME unimobile app build and run script!"
	                    echo "$MOBILE_GENERATOR_LINE_PREFIX : Please retry running this script after fixing above errors."
	                    exit $EXIT_IONIC_CAP_ADD_PLATFORM_COMMAND_ERROR_CODE
	                fi
            	;;
	    esac
	fi
}

clear
echo "=========================================================================================================================================="
echo 			"Welcome to $MOBILE_GENERATOR_NAME Unimobile app build and run script"
echo "Sit back, relax, and sip a cuppa coffee while the dependencies are download, project is built, and run."
echo "Unless the execution of this script stops, do not be bothered nor worried about any warnings or errors displayed during the execution ;-)"
echo "=========================================================================================================================================="

# OS version validation
LINUX_VERSION_CMD=$(lsb_release -a 2>&1)
if [ $? -gt 0 ]; then
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Error in getting linux version. The error is:"
    echo "----------------------------------------------------------------------------------------------------------------------------------------------------------------------"
    echo $LINUX_VERSION_CMD
    echo "----------------------------------------------------------------------------------------------------------------------------------------------------------------------"
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting $MOBILE_GENERATOR_NAME unimobile app build and run script!"
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Please retry running this script after fixing above errors."
    exit $EXIT_LINUX_VERSION_CHECK_COMMAND_ERROR_CODE
fi

echo "$MOBILE_GENERATOR_LINE_PREFIX : You linux distribution name and version are:"
lsb_release -a

# Node validation
node_version=$(node --version | awk -F. '{ print $1 }')
# remove the first character
nodejs=${node_version#?}
if [ $nodejs -lt $NODE_MAJOR_VERSION ]; then
    echo "$MOBILE_GENERATOR_LINE_PREFIX : You are running non-supported nodejs major version $(node --version | awk -F. '{ print $1 }') for building and running $MOBILE_GENERATOR_NAME generated Unimobile application project sources!"
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Minimum required version is $NODE_MAJOR_VERSION+"
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting the build process. Please install a stable and LTS NodeJS release of major version $NODE_MAJOR_VERSION and retry running this script."    
    exit $EXIT_NODE_VERSION_CHECK_COMMAND_ERROR_CODE
else
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Node major version requirement - $NODE_MAJOR_VERSION - met, moving ahead with other checks..."
fi

# NPM validation
npm_version=$(npm --version | awk -F. '{ print $1 }')
if [ $npm_version -lt $NPM_MAJOR_VERSION ]; then
    echo "$MOBILE_GENERATOR_LINE_PREFIX : You are running non-supported NPM major version $(npm --version | awk -F. '{ print $1 }') for building and running $MOBILE_GENERATOR_NAME generated Unimobile application project sources!"
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Minimum required major NPM version is $NPM_MAJOR_VERSION+"
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting the build process. Please install a stable and LTS NPM release of major version $NPM_MAJOR_VERSION and retry running this script."
    exit $EXIT_NPM_VERSION_CHECK_COMMAND_ERROR_CODE
else
    echo "$MOBILE_GENERATOR_LINE_PREFIX : NPM major version requirement - $NPM_MAJOR_VERSION - met, moving ahead with other checks..."
fi

# ionic cli version validation
ionic_cli_version=$(ionic --version | awk -F. '{ print $1 }')
if [ $ionic_cli_version -lt $IONIC_CLI_MAJOR_VERSION ]; then
    echo "$MOBILE_GENERATOR_LINE_PREFIX : You are running non-supported Ionic CLI major version $ionic_cli_version for building and running $MOBILE_GENERATOR_NAME generated Unimobile application project sources!"
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Minimum required Ionic major version is $IONIC_CLI_MAJOR_VERSION+"
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting the build process. Please install a stable and LTS angular cli release of major version $IONIC_CLI_MAJOR_VERSION and retry running script."
    exit $EXIT_IONIC_CLI_VERSION_CHECK_COMMAND_ERROR_CODE
else
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Ionic CLI major version requirement - $IONIC_CLI_MAJOR_VERSION - met, moving ahead with other checks..."
fi

# check for java run time
java_version=$(java --version | awk 'NR==1 {print $2}'| awk -F. '{print $1}')
if [ $java_version -lt $JAVA_MIN_VERSION ]; then
    echo "$MOBILE_GENERATOR_LINE_PREFIX : You are running non-supported Java version $java_version for building and running $MOBILE_GENERATOR_NAME generated Unimobile application project sources!"
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Minimum required version is $JAVA_MIN_VERSION+"
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting the build process. Please install a stable and LTS java release of major version $JAVA_MIN_VERSION and retry running this script."
    exit $EXIT_JAVA_VERSION_CHECK_COMMAND_ERROR_CODE
else
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Java version requirement - $JAVA_MIN_VERSION - met, moving ahead with other checks..."
fi

#jdk check
# javac --help > /dev/null 2>&1
JAVAC_COMMAND=$(javac --help 2>&1)
if [ $? -gt 0 ]; then
    echo "$MOBILE_GENERATOR_LINE_PREFIX : It appears Java JDK is not installed. Please install Java JDK - $JAVA_MIN_MAJOR_VERSION.$JAVA_MIN_MINOR_VERSION and retry running this script."    
    exit $EXIT_JDK_VERSION_CHECK_COMMAND_ERROR_CODE
fi

echo "$MOBILE_GENERATOR_LINE_PREFIX : Build environment validation completed successfully. Moving ahead with building and running your unimobile ionic android application..."
unimo_install_ionic_deps_build_and_platform

# splash and app icon resources creation
echo "$MOBILE_GENERATOR_LINE_PREFIX : Customizing Unimobile application icon and splash images..."
CORDOVA_RES_GEN_ICON_SPLASH=$(cordova-res android --skip-config --copy 2>&1)
if [ $? -gt 0 ]; then
    # check for execution error and follow-up with any remedial actions
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Error customizing the application icon and splash images!"
    echo "$MOBILE_GENERATOR_LINE_PREFIX : The error is:"     
    echo "----------------------------------------------------------------------------------------------------------------------------------------------------------------------"
    echo $CORDOVA_RES_GEN_ICON_SPLASH
    echo "----------------------------------------------------------------------------------------------------------------------------------------------------------------------"
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Aborting $MOBILE_GENERATOR_NAME unimobile app build and run script!"
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Please retry running $MOBILE_GENERATOR_NAME build and run script after deleting the node_modules, android, and www direcrtories in this project folder, if they exist."      
    exit $EXIT_CORDOVA_RES_COMMAND_ERROR_CODE  
fi

# check android sdk and tools availability
# devices=$(adb devices 2>/dev/null)
ADB_DEVICES_COMMAND=$(adb devices 2>&1)
# $? is the result of last command executed - 0 in case of success and greater than 0 in case of error
if [ $? -gt 0 ]; then
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Android SDK and tools appear to be not installed or ANDROID_HOME and tools directory are NOT in PATH!"
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Please install the same, set the environment variabales and retry running this script!"
    exit $EXIT_ADB_DEV_LIST_COMMAND_ERROR_CODE
fi

# run android simulator
echo "$MOBILE_GENERATOR_LINE_PREFIX : Starting Android simulator for running the Unimobile app..."
if !(ionic cap run android); then
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Error running Android simulator and running your Unimobile application."
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Please retry running $MOBILE_GENERATOR_NAME build and run script after deleting the node_modules, android, and www direcrtories in this project folder, if they exist."    
    exit $EXIT_IONIC_CAP_RUN_COMMAND_ERROR_CODE
fi

# configure simulator to access the server port on the network
echo "$MOBILE_GENERATOR_LINE_PREFIX : Configuring Android simulator to access the Appbrahma server port on the network..."
ADB_REVERSE_TCP_COMMAND=$(adb reverse tcp:8091 tcp:8091 2>&1)
# $? is the result of last command executed - 0 in case of success and greater than 0 in case of error
if [ $? -gt 0 ]; then
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Error confuguring android simulator to access the server port on the netwoork."
    echo "$MOBILE_GENERATOR_LINE_PREFIX : Please try exeucting the command \"adb reverse tcp:8091 tcp:8091\" for establishing seamless connection between server and this app for REST calls."    
    exit $EXIT_ADB_REVERSE_COMMAND_ERROR_CODE
fi

# display credentials for log in - for server integrated template
echo "$MOBILE_GENERATOR_LINE_PREFIX : Please use the below log in credentials to log into the appbrahma generated server from front-end unimobile app after running the backend server in a seperate terminal/console"
echo "Username: brahma"
echo "Password: brahma@appbrahma"
