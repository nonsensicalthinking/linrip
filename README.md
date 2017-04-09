# linrip
Linux BluRay Grooming Script. Convert DTS to AC3 for audio normalization in HandBrake. Process video file using HandBrakeCLI using HandBrake GUI Presets.

## Usage
Most BluRay videos these days are some form of DTS and many times they are annoyingly soft and suddenly loud.  This script was designed to take MKV files with DTS* audio and convert the MKV file's audio to AC3 so the audio hints are there.  This is the only way to utilize HandBrake's Dynamic Range Compression (DRC).  __This feature ONLY WORKS WITH AC3 AUDIO__.

### Prerequisites

* HandBrake
* HandBrakeCLI
* mkvdts2ac3.sh (my modified version is included in this project, original can be found here: https://github.com/JakeWharton/mkvdts2ac3)
* Plenty 'o disk space

Requirements for mkvdts2ac3.sh (see also: https://github.com/JakeWharton/mkvdts2ac3)
these can be obtained via apt in Ubuntu 16.

`sudo apt install mkvtoolnix ffmpeg rsync`

* mkvtoolnix
* ffmpeg
* rsync

### Configuration
1. Clone the project to a drive with lots of storage.  This will be your conversion working directory where files will be stored while they are moved through the conversion process. `git clone https://github.com/nonsensicalthinking/linrip.git`
1. Navigate to the linrip clone directory and run the command: `./linrip.sh -i "/path/to/video/base/directory"`
(NOTE: The video base directory specified by the -i flag should be on a drive which has lots of space, this will be the working directory for the script.)
1. Check the working directory's folder structure by running the command: `./linrip.sh -c`

### Usage

At this point the working directory should be defined in the rc file and the folders within the working directory should have been created.

Currently the script only supports two main modes of operation

1. Convert a DTS file to AC3 then Running the AC3 file through HandBrakeCLI
-OR-
2. Run an AC3 file through HandBrakeCLI

#### 1) DTS

If you're going to run DTS through the conversion process, simply drop your DTS files into the `/video/base/path/dts` folder. 

Run linrip with the following command: `linrip`

#### 2) AC3

If you're going to run AC3 through the conversion process, simply drop your AC3 files into the `/video/base/path/ac3` folder.

Run linrip with the following command: `linrip -u`


### Usage Options

#### One and done
You only want to run on one file, the first file found by the search criteria

    linrip.sh -1

#### Display Debug info and simulate process
This will feign the conversion processes and print debugging text to show what is happening. Empty files are created in place of where conversions would be produced when executing the script without this command.

    linrip.sh -d

#### HandBrake output's file resting location
This will override the rc file setting. This is the output folder. The handbrake conversion process will save the output to the handbrake_output folder but when the process is completed we will move that file (using mv) to this location.

    linrip.sh -o "/path/to/final/location"

#### Skip DTS to AC3 Conversion

    linrip.sh -u

#### Check working directory folder structure
This command will exit after running.
    
    linrip.sh -c

#### Help menu

    linrip.sh -h

#### Change script's folder search criteria
This will override the default search criteria.  This script uses find to locate the next file to process. The find command takes search criteria and this is where you specify that. Default search criteria is "*.mkv".

    linrip.sh -e "*.mkv"

#### Initialize linrip rc file
This command will exit after running.

    linrip.sh -i "/path/to/working/directory"

#### HandBrake: HandBrake GUI Preset Name
This is the name of the preset in the HandBrake GUI.  If there are no spaces in the name you can omit the quotations around the preset name, if there are spaces, you'll need them.

    linrip.sh -p "Preset Name"

#### HandBrake: Limit CPU of HandBrakeCLI process
Override the default CPU Limit setting. This is in percent of CPU usage.  Single core CPU -l 100 is max. Eight core CPU -l 800 is max. This command is available so you can continue to use the machine in the background while grooming your MKVs. Default is 500.

    linrip.sh -l 500


