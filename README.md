# linrip
Linux BluRay Grooming Script. Convert DTS to AC3 for audio normalization in HandBrake. Process video file using HandBrakeCLI using HandBrake GUI Presets. The script maintains directory structures of the input directories (see more about this in the usage section). You can skip the DTS to AC3 conversion step using the `-u` flag.  Don't get trapped in the mindset! The HandBrakeCLI input file format doesn't need to be AC3!  This script will process files found in the designated input directory one by one in a fifo order until all files are processed, unless you specify the `-1` one and done option.

## Usage
Most BluRay videos these days are some form of DTS and many times they are annoyingly soft and suddenly loud.  This script was designed to take MKV files with DTS* audio and convert the MKV file's audio to AC3 so the audio hints are there.  This is the only way to utilize HandBrake's Dynamic Range Compression (DRC).  __This feature only works with AC3 audio__.

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
1. Clone the project to a drive with lots of free storage space.  This will be your conversion working directory where files will be stored while they are moved through the conversion process. `git clone https://github.com/nonsensicalthinking/linrip.git`
1. Navigate to the linrip clone/bin directory `/path/to/linrip/base/directory/bin` and run the command: `./linrip.sh -i "/path/to/linrip/base/directory"`
(NOTE: The video base directory specified by the -i flag should be on a drive which has lots of space, this will be the working directory for the script).
1. Check the working directory's folder structure by running the command: `./linrip.sh -c` This will automatically create any missing directories.
1. Edit the `~/.linrip.rc` file to your liking. See the config variables section below for more information on the rc file.

### Usage

At this point the working directory should be defined in the rc file and the folders within the working directory should have been created.

Currently the script only supports two main modes of operation

1. Convert a DTS file to AC3 then Running the AC3 file through HandBrakeCLI
-OR-
2. Run any video file (supported by HandBrake) through HandBrakeCLI

**IMPORTANT** It is important to note that the script will maintain the directory structure within the `/video/base/path/dts` directory or the `/video/base/path/ac3` directory so you could do something like `/video/base/path/dts/x_files/s1/s1e1.mkv` and the output directory will be `/handbrake/output/directory/x_files/s1/s1e1.mkv`

#### 1) DTS

If you're going to run DTS through the conversion process, simply drop your DTS files into the `/path/to/linrip/base/directory/dts` folder. 

Run linrip with the following command: `linrip`

#### 2) Other video types

If you're going to run another type of video file through the conversion process, simply drop your video files into the `/path/to/linrip/base/directory/handbrake_input` directory.

Run linrip with the following command: `linrip -u`

### Usage Options
#### One and done
You only want to process one file, the first file found by the search criteria

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

### Configuration Variables

    VIDEO_BASE_PATH="/home/user1/linrip"
    VIDEO_OUTPUT_PATH="/output/path"
    SAVE_HANDBRAKE_INPUT=1
    SAVE_DTS_INPUT=1


More coming soon.
