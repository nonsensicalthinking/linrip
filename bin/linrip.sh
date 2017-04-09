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
##	TODO
##	Rewrite so we have the option of going from either DTS, PCM or AC3 to HandBrake
##		currently we only go from AC3 to HandBrake.
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
	if [ ! -d $VIDEO_INPUT_PATH ];
	then
		echo "Creating DTS Input folder... [$VIDEO_INPUT_PATH]"
		mkdir -p $VIDEO_INPUT_PATH
	fi

	if [ ! -d $VIDEO_TEMP_PATH ];
	then
		echo "Creating DTS->AC3 Temp folder... [$VIDEO_TEMP_PATH]"
		mkdir -p $VIDEO_TEMP_PATH
	fi

	if [ ! -d $VIDEO_ERROR_PATH ];
	then
		echo "Creating DTS->AC3 Error output folder... [$VIDEO_ERROR_PATH]"
		mkdir -p $VIDEO_ERROR_PATH
	fi

	if [ ! -d $VIDEO_INPUT_PROCESSED ];
	then
		echo "Creating DTS Raw input processed folder... [$VIDEO_INPUT_PROCESSED]"
		mkdir -p $VIDEO_INPUT_PROCESSED
	fi

	if [ ! -d $VIDEO_AC3_PATH ];
	then
		echo "Creating AC3 folder... [$VIDEO_AC3_PATH]"
		mkdir -p $VIDEO_AC3_PATH
	fi

	if [ ! -d $VIDEO_AC3_FINISHED ];
	then
		echo "Creating MKV/AC3 Original folder storage... [$VIDEO_AC3_FINISHED]"
		mkdir -p $VIDEO_AC3_FINISHED
	fi

	if [ ! -d $VIDEO_NORMALIZED_PATH ];
	then
		echo "Creating HandBrake output folder... [$VIDEO_NORMALIZED_PATH]"
		mkdir -p $VIDEO_NORMALIZED_PATH
	fi

	if [ ! -d $VIDEO_OUTPUT_PATH ];
	then
		echo "Creating Final resting place of converted video... [$VIDEO_OUTPUT_PATH]"
		mkdir -p $VIDEO_OUTPUT_PATH
	fi

	if [ ! -d $VIDEO_ERROR_OUTPUT_PATH ];
	then
		echo "Creating HandBrake Error output folder... [$VIDEO_ERROR_OUTPUT_PATH]"
		mkdir -p $VIDEO_ERROR_OUTPUT_PATH
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
}

LINRIP_RC_PATH="$HOME/.linrip.rc"

readRc()	{
	if [ -e "$LINRIP_RC_PATH" ];
	then
		source $LINRIP_RC_PATH
		echo "RC VIDEO_BASE_PATH: $VIDEO_BASE_PATH"
	else
		timestamp "WARNING: No rc file found! Run linrip with -i <path to base directory>" >> $LOG_FILE
	fi
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
#VIDEO_BASE_PATH="."														#USE THE RC FILE TO SPECIFY THIS DIRECTORY!
##
LINRIP_PID_FILE="$VIDEO_BASE_PATH/linrip.pid"								#SAFTEY TO PREVENT MULTIPLE INSTANCES FROM RUNNING
##
FILE_SEARCH_CRITERIA="*.mkv"												#PATTERN TO USE FOR SCANNING MKV/DTS & MKV/AC3 FOLDERS
##
VIDEO_INPUT_PATH="$VIDEO_BASE_PATH/dts/"									#LOCATION OF ORIGINAL MKV/DTS FILES
VIDEO_INPUT_PROCESSED="$VIDEO_BASE_PATH/dts_orig/"							#LOCATION OF ORIGINAL MKV/DTS FILES AFTER COPY MADE MKV/AC3
VIDEO_ERROR_PATH="$VIDEO_BASE_PATH/dts_error/"								#LOCATION OF ORIGINAL MKV/DTS FILES IF THERE WAS AN ERROR
VIDEO_TEMP_PATH="$VIDEO_BASE_PATH/dts_temp/"								#TEMPORARY STORAGE PATH FOR CONVERTING DTS TO AC3
##
VIDEO_AC3_PATH="$VIDEO_BASE_PATH/handbrake_input/"							#LOCATION OF MKV/AC3 FILES TO BE COMPRESSED AND NORMALIZED
VIDEO_AC3_FINISHED_PATH="$VIDEO_BASE_PATH/handbrake_input_orig/"			#LOCATION OF MKV/AC3 "ORIGINAL"
VIDEO_ERROR_OUTPUT_PATH="$VIDEO_BASE_PATH/handbrake_error/"					#LOCATION OF MKV/AC3 "ORIGINAL" IF THERE WAS AN ERROR
VIDEO_NORMALIZED_PATH="$VIDEO_BASE_PATH/handbrake_output/"					#LOCATION OF COMPRESSED & NORMALIZED MKV/AC3
##
#VIDEO_OUTPUT_PATH=""	#FINAL RESTING LOCATION OF MKV/AC3 COMPRESSED & NORMALIZED
##
## Handbrake - these can also be set as command line arguments!
HANDBRAKE_CPU_LIMIT=500														#HANDBRAKE CPU LIMIT IN PERCENT
HANDBRAKE_PRESET_NAME="HPDRC2"												#HANDBRAKE GUI PRESET NAME
##
#####################################################
## Maybe you shouldn't edit these, or should you?
#####################################################
ONE_AND_DONE=0
SKIP_STEP_1_AND_DONE=0
## Logging
LOG_FILE="$VIDEO_BASE_PATH/conversion.log"
#LOG_FILE="/dev/stdout"
##
DEBUG=0
##
EXIT_ARG_ERROR=0
EXIT_ARG_NO_ERROR=0

while getopts "uhdco:p:l:e:b:i:" o; do
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
		echo "*OVERRIDE* VIDEO_OUTPUT_PATH: $OPTARG [old: $VIDEO_OUTPUT_PATH]"
		VIDEO_OUTPUT_PATH=$OPTARG
		;;
	    p)	
		echo "*OVERRIDE* HANDBRAKE_PRESET_NAME: $OPTARG [old: $HANDBRAKE_PRESET_NAME]"
		HANDBRAKE_PRESET_NAME=$OPTARG
		;;
	    l)	
		echo "*OVERRIDE* HANDBRAKE_CPU_LIMIT: $OPTARG [old: $HANDBRAKE_CPU_LIMIT]"
		HANDBRAKE_CPU_LIMIT=$OPTARG
		;;
	    e)	
		echo "*OVERRIDE* FILE_SEARCH_CRITERIA: $OPTARG [old: $FILE_SEARCH_CRITERIA]"
		FILE_SEARCH_CRITERIA=$OPTARG
		;;
		u)
		echo "Skipping DTS to AC3 Conversion step and processing only 1 file"
		SKIP_DTS=1
		;;
		1)
		echo "Processing only 1 file before exiting."
		ONE_AND_DONE=1
		;;
		b)
		echo "*OVERRIDE* VIDEO_BASE_PATH: $OPTARG [old: $VIDEO_BASE_PATH]"
		VIDEO_BASE_PATH=$OPTARG
		;;
		i)
		echo "Initializing linrip using directory: $OPTARG"
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

until [ -z "$NEXT_VIDEO_TO_PROCESS" ]; do
	
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

		timestamp "] NEXT_VIDEO_TO_PROCESS: $NEXT_VIDEO_TO_PROCESS" >> $LOG_FILE
		timestamp "] NEXT_FILE_PATH_TRIMMED: $NEXT_FILE_PATH_TRIMMED" >> $LOG_FILE
		timestamp "] NEXT_PATH: $NEXT_PATH" >> $LOG_FILE
		timestamp "] NEXT_FILE: $NEXT_FILE" >> $LOG_FILE
		timestamp "] OUTPUT_LOCATION: $OUTPUT_LOCATION" >> $LOG_FILE

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

				mkdir -p $VIDEO_AC3_PATH$NEXT_PATH

				AC3_FULL_OUTPUT_PATH=$VIDEO_AC3_PATH$NEXT_PATH${NEXT_FILE%.*}"_ac3.mkv"

				#Convert DTS track to AC3
				if [ $DEBUG -eq 1 ];
				then
					timestamp "Creating simulation file: $AC3_FULL_OUTPUT_PATH" >> $LOG_FILE
					touch $AC3_FULL_OUTPUT_PATH
					AC3_EXIT_STATUS=0
				else
					mkvdts2ac3.sh -n --wd $VIDEO_TEMP_PATH --new -nf "$VIDEO_AC3_PATH$NEXT_PATH" $NEXT_VIDEO_TO_PROCESS
					AC3_EXIT_STATUS=$?
				fi

				timestamp "Exit status of AC3 Conversion: $AC3_EXIT_STATUS" >> $LOG_FILE

				if [ $AC3_EXIT_STATUS -eq 1 ];
				then
					AC3_ERROR_OUTPUT_PATH=$VIDEO_ERROR_OUTPUT_PATH$NEXT_PATH
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
				mkdir -p $VIDEO_AC3_PATH$NEXT_PATH
				mv $NEXT_VIDEO_TO_PROCESS $VIDEO_AC3_PATH$NEXT_PATH$NEXT_FILE
				timestamp "Copied $NEXT_VIDEO_TO_PROCESS to $VIDEO_AC3_PATH$NEXT_PATH$NEXT_FILE" >> $LOG_FILE
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
			fi
		fi
	fi
	######################################
	############ STEP 2 - Handbrake
	######################################

	AC3_TO_PROCESS=$(find $VIDEO_AC3_PATH -name $FILE_SEARCH_CRITERIA | head -1)

	if [ -z "$AC3_TO_PROCESS" ]
	then
		timestamp "No AC3 files found for compression/normalization." >> $LOG_FILE
	else
	      # =================================================================================== #
		#TO MAINTAIN DIRECTORY STRUCTURE, WE NEED TO UPDATE NEXT_PATH VARIABLE
		NEXT_FILE_PATH_TRIMMED=$(echo $AC3_TO_PROCESS | sed "s@$VIDEO_AC3_PATH@@")
		NEXT_FILE=${NEXT_FILE_PATH_TRIMMED##*/}
		NEXT_PATH=$(echo $NEXT_FILE_PATH_TRIMMED | sed "s@$NEXT_FILE@@")
	      # =================================================================================== #

		timestamp "AC3_TO_PROCESS: $AC3_TO_PROCESS" >> $LOG_FILE

		#Make sure the handbrake output path exists
		mkdir -p "$VIDEO_NORMALIZED_PATH$NEXT_PATH"

	      # =================================================================================== #
		#Configure HandBrake options
		HANDBRAKE_INPUT="$AC3_TO_PROCESS"
		HANDBRAKE_OUTPUT="$VIDEO_NORMALIZED_PATH$NEXT_PATH$NEXT_FILE"
		HANDBRAKE_PRESET="--preset-import-gui -Z $HANDBRAKE_PRESET_NAME"	#Use GUI Presets
	      # =================================================================================== #

		timestamp "] HANDBRAKE_CPU_LIMIT: $HANDBRAKE_CPU_LIMIT" >> $LOG_FILE
		timestamp "] HANDBRAKE_PRESET_NAME: $HANDBRAKE_PRESET_NAME" >> $LOG_FILE
		timestamp "] HANDBRAKE_INPUT: $HANDBRAKE_INPUT" >> $LOG_FILE
		timestamp "] HANDBRAKE_OUTPUT: $HANDBRAKE_OUTPUT" >> $LOG_FILE
		timestamp "] HANDBRAKE_PRESET: $HANDBRAKE_PRESET" >> $LOG_FILE

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
			HANDBRAKE_PID=$(ps -eo pid,command | grep -v "SCREEN -d -m sh -c HandBrakeCLI" | grep -v "sh -c HandBrakeCLI" | grep "HandBrakeCLI" | grep -v grep | awk '{print $1}')
			
			if [ -z "$HANDBRAKE_PID" ];
			then
				#Execute Handbrake command
				screen -d -m sh -c "$HANDBRAKE_CLI_COMMAND"
				
				HANDBRAKE_PID=$(ps -eo pid,command | grep -v "SCREEN -d -m sh -c HandBrakeCLI" | grep -v "sh -c HandBrakeCLI" | grep "HandBrakeCLI" | grep -v grep | awk '{print $1}')

				timestamp "Handbrake PID: $HANDBRAKE_PID" >> $LOG_FILE

				#Limit Handbrake's CPU usage so other tasks can continue to run, this is a long running process...
				cpulimit -p $HANDBRAKE_PID -l $HANDBRAKE_CPU_LIMIT

				#Update the file info to indicate it has been modified
				CURRENT_TITLE=$(mediainfo $HANDBRAKE_OUTPUT --Inform="General;%Title%")
				mkvpropedit $HANDBRAKE_OUTPUT --edit info --set "title=$CURRENT_TITLE.NORM"
			else
				timestamp "HandBrake is already running, PID: $HANDBRAKE_PID" >> $LOG_FILE
				customExit
			fi
		fi

		#cpulimit has exited which means HandBrakeCLI process has terminated
		timestamp "Moving AC3 file to final folder..." >> $LOG_FILE

		#Move the original file to the processed location
		if [ $SAVE_HANDBRAKE_INPUT -eq 1 ];
		then
			timestamp "Moving HandBrake input file in this location: $VIDEO_AC3_FINISHED_PATH$NEXT_PATH$NEXT_FILE" >> $LOG_FILE
			mkdir -p $VIDEO_AC3_FINISHED_PATH$NEXT_PATH
			mv $HANDBRAKE_INPUT $VIDEO_AC3_FINISHED_PATH$NEXT_PATH$NEXT_FILE
		else
			timestamp "Deleting HandBrake input file: $HANDBRAKE_INPUT"
			rm $HANDBRAKE_INPUT
		fi

		if [ -z "$VIDEO_OUTPUT_PATH" ];
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
	queueNextFile
done

customExit
