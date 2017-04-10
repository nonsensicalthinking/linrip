#!/bin/bash
####################################################################################################################################################
## linrip.sh - Linux BluRay Video Groomer
## by nonsensicalthinking
## 
## This script relies on 
## 
## 	mkvpropedit - MKV Property editer
##
## 	mkvtoolnix - Matroska tools
##
## 	ffmpeg - Audio conversion tool
##
## 	rsync - File transfer and synchronization
##
## 	mkvdts2ac3.sh - Script for managing DTS TO AC3 Conversion process
##
##	HandBrakeCLI - Command line interface for HandBrake
##
## Features:
## 	- Converts DTS, DTS-ES tracks into AC3 so the audio can be normalized
## 	- Compresses and normalizes MKV Video and Audio
## 	- Maintains directory structures
##
##
###########################
##### Functions
###########################
preventMultipleInstances() {
	if [ -e "$LINRIP_PID_FILE" ];
	then
		echo "Another instance of $LINRIP_FILE_NAME is already running."
		exit 0
	else
		LINRIP_PID=$(ps -eo pid,command | grep -v grep | grep "/bin/bash $0" | head -1)
		echo $LINRIP_PID > $LINRIP_PID_FILE
	fi
}

timestamp() {
	date +"%y/%m/%d %H:%M ) $*"
}

queueNextFile() {
		NEXT_VIDEO_TO_PROCESS=$(find $VIDEO_INPUT_PATH -name $FILE_SEARCH_CRITERIA | head -1)
}

checkFileStructure() {

	#DTS folders
	if [ ! -d $VIDEO_INPUT_PATH ];
	then
		echo "Creating DTS Input folder... [$VIDEO_INPUT_PATH]"
		mkdir -p $VIDEO_INPUT_PATH
	fi

	if [ ! -d $VIDEO_INPUT_PROCESSED ];
	then
		echo "Creating DTS Raw input processed folder... [$VIDEO_INPUT_PROCESSED]"
		mkdir -p $VIDEO_INPUT_PROCESSED
	fi

	if [ ! -d $VIDEO_ERROR_PATH ];
	then
		echo "Creating DTS->AC3 Error output folder... [$VIDEO_ERROR_PATH]"
		mkdir -p $VIDEO_ERROR_PATH
	fi

	if [ ! -d $VIDEO_TEMP_PATH ];
	then
		echo "Creating DTS->AC3 Temp folder... [$VIDEO_TEMP_PATH]"
		mkdir -p $VIDEO_TEMP_PATH
	fi


	#HandBrake folders
	if [ ! -d $VIDEO_HANDBRAKE_INPUT_PATH ];
	then
		echo "Creating HandBrake input folder... [$VIDEO_HANDBRAKE_INPUT_PATH]"
		mkdir -p $VIDEO_HANDBRAKE_INPUT_PATH
	fi

	if [ ! -d $VIDEO_HANDBRAKE_FINISHED_PATH ];
	then
		echo "Creating HandBrake orig folder... [$VIDEO_HANDBRAKE_FINISHED_PATH]"
		mkdir -p $VIDEO_HANDBRAKE_FINISHED_PATH
	fi

	if [ ! -d $VIDEO_HANDBRAKE_ERROR_PATH ];
	then
		echo "Creating HandBrake Error output folder... [$VIDEO_HANDBRAKE_ERROR_PATH]"
		mkdir -p $VIDEO_HANDBRAKE_ERROR_PATH
	fi

	if [ ! -d $VIDEO_HANDBRAKE_OUTPUT_PATH ];
	then
		echo "Creating HandBrake output folder... [$VIDEO_HANDBRAKE_OUTPUT_PATH]"
		mkdir -p $VIDEO_HANDBRAKE_OUTPUT_PATH
	fi

	#Script folders
	if [ ! -d $VIDEO_OUTPUT_PATH ];
	then
		echo "Creating Final resting place of converted video... [$VIDEO_OUTPUT_PATH]"
		mkdir -p $VIDEO_OUTPUT_PATH
	fi

}

showHelp() {
	echo "=================================================="
	echo " linrip Haaaaalp!!"
	echo
	echo " Step 1: Configure linrip.sh vars to your liking"
	echo " Step 2: Exec: ./$LINRIP_FILE_NAME -c"
	echo " Step 3: Place MKV/DTS files into the dts folder"
	echo " and run linrip.sh again."
	echo 
	echo " Options..."
	echo "	1 - One and done."
	echo
	echo "	d - Display debug information and simulate the"
	echo "		entire conversion process."
	echo
	echo "	o - Use this folder for the final destination"
	echo "	    eg. -o /path/to/file/output/"
	echo
	echo "	u - Skip the DTS to AC3 conversion and only"
	echo "		process one file before exiting."
	echo
	echo "	c - Check file structure, create folders if"
	echo "	    missing and exit."
	echo
	echo "	h - This help menu."
	echo
	echo "	e - MKV/DTS & MKV/AC3 Folder search criteria"
	echo "	    eg. -e *.mkv"
	echo
	echo "	i - Initialize the .linriprc file."
	echo "		eg. -i \"/path/to/video_base_directory\""
	echo
	echo "	s - Silent. No logging, no echo."
	echo
	echo "	v - Set log file output to stdout instead of"
	echo "		the file on disk."
	echo
	echo " HandBrake Settings..."
	echo "	p - HandBrake GUI Preset Name "
	echo "	    eg. -p PresetName or -p Preset Name"
	echo
	echo "	l - Limit CPU of HandBrakeCLI "
	echo "	    eg. -l 500"
	echo "=================================================="
}

customExit() {
	rm $LINRIP_PID_FILE
	exit 0
}

initLinRip()	{
	touch $LINRIP_RC_PATH

	if [ -z "$INIT_HOME_PATH" ];
	then
		echo "VIDEO_BASE_PATH=\".\"" >> $LINRIP_RC_PATH
	else
		echo "VIDEO_BASE_PATH=\"$INIT_HOME_PATH\"" >> $LINRIP_RC_PATH
	fi

	echo "VIDEO_OUTPUT_PATH=\"\"" >> $LINRIP_RC_PATH
	echo "SAVE_HANDBRAKE_INPUT=1" >> $LINRIP_RC_PATH
	echo "SAVE_DTS_INPUT=1" >> $LINRIP_RC_PATH
	echo "SKIP_DTS=0" >> $LINRIP_RC_PATH
	ehco "SILENT_MODE=0" >> $LINRIP_RC_PATH
	echo "FILE_SEARCH_CRITERIA=\"\"" >> $LINRIP_RC_PATH
	echo >> $LINRIP_RC_PATH

	echo "#DTS FOLDERS" >> $LINRIP_RC_PATH
	echo "_DTS_FOLDER=\"dts/\"" >> $LINRIP_RC_PATH
	echo "_DTS_OUTPUT_FOLDER=\"dts_orig/\"" >> $LINRIP_RC_PATH
	echo "_DTS_ERROR_FOLDER=\"dts_error/\"" >> $LINRIP_RC_PATH
	echo "_DTS_TEMP_FOLDER=\"dts_temp/\"" >> $LINRIP_RC_PATH
	echo  >> $LINRIP_RC_PATH

	echo "#HANDBRAKE FOLDERS" >> $LINRIP_RC_PATH
	echo "_HANDBRAKE_INPUT_FOLDER=\"handbrake_input/\"" >> $LINRIP_RC_PATH
	echo "_HANDBRAKE_INPUT_ORIG_FOLDER=\"handbrake_input_orig/\"" >> $LINRIP_RC_PATH
	echo "_HANDBRAKE_OUTPUT_FOLDER=\"handbrake_output/\"" >> $LINRIP_RC_PATH
	echo "_HANDBRAKE_ERROR_FOLDER=\"handbrake_error/\"" >> $LINRIP_RC_PATH
	echo >> $LINRIP_RC_PATH

	echo "#HANDBRAKE SETTINGS"
	echo "LIMIT_CPU=1" >> $LINRIP_RC_PATH
	echo "HANDBRAKE_CPU_LIMIT=500" >> $LINRIP_RC_PATH
	echo "HANDBRAKE_PRESET_NAME=\"\"" >> $LINRIP_RC_PATH
}

LINRIP_RC_PATH="$HOME/.linrip.rc"

readRc()	{
	if [ -e "$LINRIP_RC_PATH" ];
	then
		source $LINRIP_RC_PATH
	else
		timestamp "ERROR: No rc file found! Run linrip with -i <path to base directory>" >> /dev/stdout
		timestamp "ERROR: No rc file found! Run linrip with -i <path to base directory>" >> /dev/stdout
		exit 0
	fi
}

checkForHandBrakePid() {
	sleep 1 #Give screen enough time to start up the processes
	HANDBRAKE_PID=$(pgrep -n -f HandBrakeCLI)
}

############################################################################################################
############ BEGIN PROCESS
############################################################################################################

readRc

###########################
##### VARS
###########################
##Script settings
##
LINRIP_PID_FILE="$VIDEO_BASE_PATH/linrip.pid"												#SAFTEY TO PREVENT MULTIPLE INSTANCES FROM RUNNING
##
LINRIP_BIN_PATH="$VIDEO_BASE_PATH/bin"														#PATH TO LINRIP SCRIPTS
##
VIDEO_INPUT_PATH="$VIDEO_BASE_PATH/$_DTS_FOLDER"											#LOCATION OF ORIGINAL MKV/DTS FILES
VIDEO_INPUT_PROCESSED="$VIDEO_BASE_PATH/$_DTS_OUTPUT_FOLDER"								#LOCATION OF ORIGINAL MKV/DTS FILES AFTER COPY MADE MKV/AC3
VIDEO_ERROR_PATH="$VIDEO_BASE_PATH/$_DTS_ERROR_FOLDER"										#LOCATION OF ORIGINAL MKV/DTS FILES IF THERE WAS AN ERROR
VIDEO_TEMP_PATH="$VIDEO_BASE_PATH/$_DTS_TEMP_FOLDER"										#TEMPORARY STORAGE PATH FOR CONVERTING DTS TO AC3
##
VIDEO_HANDBRAKE_INPUT_PATH="$VIDEO_BASE_PATH/$_HANDBRAKE_INPUT_FOLDER"						#LOCATION OF MKV/AC3 FILES TO BE COMPRESSED AND NORMALIZED
VIDEO_HANDBRAKE_FINISHED_PATH="$VIDEO_BASE_PATH/$_HANDBRAKE_INPUT_ORIG_FOLDER"				#LOCATION OF MKV/AC3 "ORIGINAL"
VIDEO_HANDBRAKE_ERROR_PATH="$VIDEO_BASE_PATH/$_HANDBRAKE_ERROR_FOLDER"						#LOCATION OF MKV/AC3 "ORIGINAL" IF THERE WAS AN ERROR
VIDEO_HANDBRAKE_OUTPUT_PATH="$VIDEO_BASE_PATH/$_HANDBRAKE_OUTPUT_FOLDER"					#LOCATION OF COMPRESSED & NORMALIZED MKV/AC3
##
#####################################################
## Maybe you shouldn't edit these, or should you?
#####################################################
ONE_AND_DONE=0
## Logging
LOG_FILE="$VIDEO_BASE_PATH/conversion.log"
#LOG_FILE="/dev/stdout"
##
DEBUG=0
##
EXIT_ARG_ERROR=0
EXIT_ARG_NO_ERROR=0

while getopts "sv1uhdco:p:l:e:b:i:" o; do
    case "${o}" in
	    h)
		showHelp
		exit 0
		;;
	    d)
		DEBUG=1
		;;
		c)
		checkFileStructure
		exit 0
		;;
	    o)	
		timestamp "*OVERRIDE* VIDEO_OUTPUT_PATH: $OPTARG [old: $VIDEO_OUTPUT_PATH]" >> $LOG_FILE
		VIDEO_OUTPUT_PATH=$OPTARG
		;;
	    p)	
		timestamp "*OVERRIDE* HANDBRAKE_PRESET_NAME: $OPTARG [old: $HANDBRAKE_PRESET_NAME]" >> $LOG_FILE
		HANDBRAKE_PRESET_NAME=$OPTARG
		;;
	    l)	
		timestamp "*OVERRIDE* HANDBRAKE_CPU_LIMIT: $OPTARG [old: $HANDBRAKE_CPU_LIMIT]" >> $LOG_FILE
		HANDBRAKE_CPU_LIMIT=$OPTARG
		;;
	    e)	
		timestamp "*OVERRIDE* FILE_SEARCH_CRITERIA: $OPTARG [old: $FILE_SEARCH_CRITERIA]" >> $LOG_FILE
		FILE_SEARCH_CRITERIA=$OPTARG
		;;
		u)
		timestamp "Skipping DTS to AC3 Conversion step." >> $LOG_FILE
		SKIP_DTS=1
		;;
		1)
		timestamp "Processing only 1 file before exiting." >> $LOG_FILE
		ONE_AND_DONE=1
		;;
		s)
		LOG_FILE="/dev/null"
		SILENT_MODE=1
		;;
		v)
		LOG_FILE="/dev/stdout"
		timestamp "Logging all output to stdout" >> $LOG_FILE
		;;
		b)
		timestamp "*OVERRIDE* VIDEO_BASE_PATH: $OPTARG [old: $VIDEO_BASE_PATH]" >> $LOG_FILE
		VIDEO_BASE_PATH=$OPTARG
		;;
		i)
		timestamp "Initializing linrip using directory: $OPTARG" >> $LOG_FILE
		INIT_HOME_PATH=$OPTARG
		initLinRip
		exit 0
		;;
	    *)
		EXIT_ARG_ERROR=1
		;;
    esac
done

shift $((OPTIND-1))

if [ $EXIT_ARG_ERROR -eq 1 ];
then
	showHelp
	exit 0
fi

if [ $EXIT_ARG_NO_ERROR -eq 1 ];
then
	exit 0
fi

preventMultipleInstances

queueNextFile

STOP_LOOPING=0

if [ -z "$NEXT_VIDEO_TO_PROCESS" ] && [ $SKIP_DTS -eq 0 ];
then
	STOP_LOOPING=1
fi

until [ $STOP_LOOPING -eq 1 ]; do
	
	timestamp "==================================================" >> $LOG_FILE
	if [ $SKIP_DTS -eq 1 ];
	then
		timestamp "Skipping Step 1: DTS* -> AC3" >> $LOG_FILE
	else
		# =================================================================================== #
		NEXT_FILE_PATH_TRIMMED=$(echo $NEXT_VIDEO_TO_PROCESS | sed "s@$VIDEO_INPUT_PATH@@")
		NEXT_FILE=${NEXT_FILE_PATH_TRIMMED##*/}
		NEXT_PATH=$(echo $NEXT_FILE_PATH_TRIMMED | sed "s@$NEXT_FILE@@")
		OUTPUT_LOCATION="$TARGET_DIR$NEXT_PATH"
		# =================================================================================== #

		timestamp "[VAR] NEXT_VIDEO_TO_PROCESS: $NEXT_VIDEO_TO_PROCESS" >> $LOG_FILE
		timestamp "[VAR] NEXT_FILE_PATH_TRIMMED: $NEXT_FILE_PATH_TRIMMED" >> $LOG_FILE
		timestamp "[VAR] NEXT_PATH: $NEXT_PATH" >> $LOG_FILE
		timestamp "[VAR] NEXT_FILE: $NEXT_FILE" >> $LOG_FILE
		timestamp "[VAR] OUTPUT_LOCATION: $OUTPUT_LOCATION" >> $LOG_FILE

		######################################
		############ STEP 1 - DTS* -> AC3
		######################################
		if [ -z "$NEXT_FILE" ];
		then
			timestamp "No MKV files to convert audio tracks for. Moving to Compress & Normalize with Handbrake..." >> $LOG_FILE
		else
			#Get format of the next video
			NXTFMT=$(mediainfo $NEXT_VIDEO_TO_PROCESS --Inform="Audio;%Format%")

			timestamp "Next video to process: $NEXT_VIDEO_TO_PROCESS" >> $LOG_FILE
			timestamp "Next video format: $NXTFMT" >> $LOG_FILE

			#What do we do with the video based on its format...
			if [ "$NXTFMT" == "DTS" ];
			then
				timestamp "Converting to AC3..." >> $LOG_FILE

				mkdir -p $VIDEO_HANDBRAKE_INPUT_PATH$NEXT_PATH

				AC3_FULL_OUTPUT_PATH=$VIDEO_HANDBRAKE_INPUT_PATH$NEXT_PATH${NEXT_FILE%.*}"-ac3.mkv"

				#Convert DTS track to AC3
				if [ $DEBUG -eq 1 ];
				then
					timestamp "Creating simulation file: $AC3_FULL_OUTPUT_PATH" >> $LOG_FILE
					touch $AC3_FULL_OUTPUT_PATH
					AC3_EXIT_STATUS=0
				else
					MKVDTS2AC3_COMMAND="$LINRIP_BIN_PATH/mkvdts2ac3.sh -n --wd $VIDEO_TEMP_PATH --new -nf $VIDEO_HANDBRAKE_INPUT_PATH$NEXT_PATH $NEXT_VIDEO_TO_PROCESS"

					timestamp "MKVDTS2AC3_COMMAND: $MKVDTS2AC3_COMMAND" >> $LOG_FILE

					if [ $SILENT_MODE -eq 1 ];
					then
						$MKVDTS2AC3_COMMAND >> /dev/null
					else
						$MKVDTS2AC3_COMMAND
					fi

					AC3_EXIT_STATUS=$?
				fi

				timestamp "Exit status of AC3 Conversion: $AC3_EXIT_STATUS" >> $LOG_FILE

				if [ $AC3_EXIT_STATUS -eq 1 ];
				then
					AC3_ERROR_OUTPUT_PATH=$VIDEO_HANDBRAKE_ERROR_PATH$NEXT_PATH
					mkdir -p $AC3_ERROR_OUTPUT_PATH

					mv $NEXT_VIDEO_TO_PROCESS $AC3_ERROR_OUTPUT_PATH$NEXT_FILE
					timestamp "Moved $NEXT_VIDEO_TO_PROCESS to $AC3_ERROR_OUTPUT_PATH$NEXT_FILE" >> $LOG_FILE
					queueNextFile
					continue	#move to next file...
				fi

				if [ ! $DEBUG -eq 1 ];
				then
					#brand the mkv title with the current format so we can check formatting of files at a later date
					CURRENT_TITLE=$(mediainfo $AC3_FULL_OUTPUT_PATH --Inform="General;%Title%")
			
					timestamp "CURRENT_TITLE: $CURRENT_TITLE" >> $LOG_FILE

					mkvpropedit $AC3_FULL_OUTPUT_PATH --edit info --set "title=$CURRENT_TITLE.AC3"
				fi
			elif [ "$NXTFMT" == "AC-3" ];
			then
				timestamp "File is already AC3." >> $LOG_FILE
				mkdir -p $VIDEO_HANDBRAKE_INPUT_PATH$NEXT_PATH
				mv $NEXT_VIDEO_TO_PROCESS $VIDEO_HANDBRAKE_INPUT_PATH$NEXT_PATH$NEXT_FILE
				timestamp "Copied $NEXT_VIDEO_TO_PROCESS to $VIDEO_HANDBRAKE_INPUT_PATH$NEXT_PATH$NEXT_FILE" >> $LOG_FILE
			else
				timestamp "No routine defined for audio format: $NXTFMT" >> $LOG_FILE
				mkdir -p $VIDEO_ERROR_PATH$NEXT_PATH
				mv $NEXT_VIDEO_TO_PROCESS $VIDEO_ERROR_PATH$NEXT_PATH$NEXT_FILE
			fi

			if [ $SAVE_DTS_INPUT -eq 1 ];
			then
				timestamp "Moving file to processed folder..." >> $LOG_FILE
				mkdir -p $VIDEO_INPUT_PROCESSED$NEXT_PATH
				mv $NEXT_VIDEO_TO_PROCESS $VIDEO_INPUT_PROCESSED$NEXT_PATH$NEXT_FILE
				timestamp "Moved $NEXT_VIDEO_TO_PROCESS to $VIDEO_INPUT_PROCESSED$NEXT_PATH$NEXT_FILE" >> $LOG_FILE
			else
				timestamp "Deleting DTS input file: $NEXT_VIDEO_TO_PROCESS"
				rm $NEXT_VIDEO_TO_PROCESS
			fi
		fi
	fi
	######################################
	############ STEP 2 - Handbrake
	######################################

	AC3_TO_PROCESS=$(find $VIDEO_HANDBRAKE_INPUT_PATH -name $FILE_SEARCH_CRITERIA | head -1)

	if [ -z "$AC3_TO_PROCESS" ]
	then
		timestamp "No AC3 files found for compression/normalization." >> $LOG_FILE
		customExit
	else
	      # =================================================================================== #
		#TO MAINTAIN DIRECTORY STRUCTURE, WE NEED TO UPDATE NEXT_PATH VARIABLE
		NEXT_FILE_PATH_TRIMMED=$(echo $AC3_TO_PROCESS | sed "s@$VIDEO_HANDBRAKE_INPUT_PATH@@")
		NEXT_FILE=${NEXT_FILE_PATH_TRIMMED##*/}
		NEXT_PATH=$(echo $NEXT_FILE_PATH_TRIMMED | sed "s@$NEXT_FILE@@")
	      # =================================================================================== #

		timestamp "AC3_TO_PROCESS: $AC3_TO_PROCESS" >> $LOG_FILE

		#Make sure the handbrake output path exists
		mkdir -p "$VIDEO_HANDBRAKE_OUTPUT_PATH$NEXT_PATH"

	      # =================================================================================== #
		#Configure HandBrake options
		HANDBRAKE_INPUT="$AC3_TO_PROCESS"
		HANDBRAKE_OUTPUT="$VIDEO_HANDBRAKE_OUTPUT_PATH$NEXT_PATH$NEXT_FILE"
		HANDBRAKE_PRESET="--preset-import-gui -Z $HANDBRAKE_PRESET_NAME"	#Use GUI Presets
	      # =================================================================================== #

		timestamp "[VAR] HANDBRAKE_CPU_LIMIT: $HANDBRAKE_CPU_LIMIT" >> $LOG_FILE
		timestamp "[VAR] HANDBRAKE_PRESET_NAME: $HANDBRAKE_PRESET_NAME" >> $LOG_FILE
		timestamp "[VAR] HANDBRAKE_INPUT: $HANDBRAKE_INPUT" >> $LOG_FILE
		timestamp "[VAR] HANDBRAKE_OUTPUT: $HANDBRAKE_OUTPUT" >> $LOG_FILE
		timestamp "[VAR] HANDBRAKE_PRESET: $HANDBRAKE_PRESET" >> $LOG_FILE

	      # =================================================================================== #
		#Configure Handbrake command
		HANDBRAKE_CLI_COMMAND="HandBrakeCLI -i \"$HANDBRAKE_INPUT\" -o \"$HANDBRAKE_OUTPUT\" $HANDBRAKE_PRESET"
	      # =================================================================================== #

		timestamp "Processing: $NEXT_FILE ($AC3_TO_PROCESS)" >> $LOG_FILE
		timestamp "Executing: $HANDBRAKE_CLI_COMMAND" >> $LOG_FILE

		if [ $DEBUG -eq 1 ];
		then
			#Simulate the event
			echo "Creating file: $HANDBRAKE_OUTPUT"
			touch $HANDBRAKE_OUTPUT
		else
			#Check if we have another handbrake session running currently...
			checkForHandBrakePid

			if [ -z "$HANDBRAKE_PID" ];
			then
				#Execute Handbrake command

				if [ $LIMIT_CPU -eq 1 ];
				then
					screen -d -m sh -c "$HANDBRAKE_CLI_COMMAND"
					
					checkForHandBrakePid

					if [ -z "$HANDBRAKE_PID" ];
					then
						timestamp "Error: No HandBrake PID found. Please check if HandBrakeCLI is running." >> $LOG_FILE
					else
						timestamp "Handbrake PID: $HANDBRAKE_PID" >> $LOG_FILE

						#Limit Handbrake's CPU usage so other tasks can continue to run, this is a long running process...
						cpulimit -p $HANDBRAKE_PID -l $HANDBRAKE_CPU_LIMIT
					fi
				else
					$HANDBRAKE_CLI_COMMAND
				fi

				#Update the file info to indicate it has been modified
				CURRENT_TITLE=$(mediainfo $HANDBRAKE_OUTPUT --Inform="General;%Title%")
				mkvpropedit $HANDBRAKE_OUTPUT --edit info --set "title=$CURRENT_TITLE.NORM"
			else
				timestamp "HandBrake is already running, PID: $HANDBRAKE_PID" >> $LOG_FILE
				customExit
			fi
		fi


		#Move the original file to the processed location
		if [ $SAVE_HANDBRAKE_INPUT -eq 1 ];
		then
			#cpulimit has exited which means HandBrakeCLI process has terminated
			timestamp "Moving HandBrake input file in this location: $VIDEO_HANDBRAKE_FINISHED_PATH$NEXT_PATH$NEXT_FILE" >> $LOG_FILE
			mkdir -p $VIDEO_HANDBRAKE_FINISHED_PATH$NEXT_PATH
			mv $HANDBRAKE_INPUT $VIDEO_HANDBRAKE_FINISHED_PATH$NEXT_PATH$NEXT_FILE
		else
			timestamp "Deleting HandBrake input file: $HANDBRAKE_INPUT" >> $LOG_FILE
			rm $HANDBRAKE_INPUT
		fi

		if [ -n "$VIDEO_OUTPUT_PATH" ];
		then
			#Move the compressed/normalized file to its final destination
			timestamp "Moving the finished product to the $VIDEO_OUTPUT_PATH$NEXT_PATH_$NEXT_FILE" >> $LOG_FILE
			mkdir -p $VIDEO_OUTPUT_PATH$NEXT_PATH
			mv $HANDBRAKE_OUTPUT $VIDEO_OUTPUT_PATH$NEXT_PATH_$NEXT_FILE
		fi

		timestamp "Finished processing." >> $LOG_FILE
	fi

	if [ $ONE_AND_DONE -eq 1 ];
	then
		timestamp "ONE_AND_DONE was set, exiting..." >> $LOG_FILE
		break
	fi

	#queue the next video to process
	if [ $SKIP_DTS -eq 0 ];
	then
		queueNextFile
		if [ -z "$NEXT_VIDEO_TO_PROCESS" ];
		then
			customExit
		fi
	else
		#Check if there is a reason for another loop
		AC3_TO_PROCESS=$(find $VIDEO_HANDBRAKE_INPUT_PATH -name $FILE_SEARCH_CRITERIA | head -1)
		if [ -z "$AC3_TO_PROCESS" ];
		then
			customExit
		fi
	fi
done

customExit
