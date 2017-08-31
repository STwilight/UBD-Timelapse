#!/bin/bash

# Fetching script start time timestamp in seconds
startTimestamp=$(date +'%s');

# Fetching current directory
rootDir=$(dirname $(realpath $0));

# Setting up converter options
convSelect='';
convFFMPEG='ffmpeg';
cmdFFMPEG=$convFFMPEG;
convAVCONV='avconv';

# Setting up path to executable binary file of ffmpeg (for static builds only!)
toolsDir='tools';
ffmpegTool=$rootDir'/'$toolsDir'/'ffmpeg;

# Setting up log file options
logDir='log';
logDirPath=$rootDir'/'$logDir;
logFileName='proc-video';
logFileExt='log';
logFile=$logDirPath'/'$(date '+%Y-%m-%d')'_'$logFileName'.'$logFileExt;

# Setting up source video file options
videoStreamURL='';
sourceFileExt='mp4';
fetchingRetriesCount=3;
pauseBetweenRetries=5;
wgetRetriesCount=3;
wgetRetriesWaitTime=1;

# Fetching timestamp for naming of temporary video files and thumbnails
timestamp=$(date '+%Y-%m-%d_%H.%M');

# Setting up options of temporary video folder and temporary video file
tmpDir='tmp';
tmpDirPath=$rootDir'/'$tmpDir;
videoFileExt='mp4';
videoFilePath=$tmpDirPath'/'$timestamp'.'$videoFileExt;

# Fetching timestamp (only date) for naming of thumbnails directory
datestamp=$(date '+%Y-%m-%d');

# Setting up options of folder for thumbnails and file naming
thumbRootDir='scr';
thumbRootDirPath=$rootDir'/'$thumbRootDir;
thumbFileExt='jpg';
thumbDir=$thumbRootDirPath'/'$datestamp;
thumbFilePath=$thumbDir'/'$timestamp'_%02d.'$thumbFileExt;

# Setting up options of thumbnails for avconv tool
thumbPeriod='00:00:05';
thumbFPS='1/10';

# Checking an existence of log files folder and current log file and creating of them (if needed)
# Logging an event of script starting
if [ ! -d $logDirPath ]
then
	mkdir $logDirPath;
	if [ -d $logDirPath ]
	then
		echo $(date '+%Y-%m-%d %H:%M:%S')' - Info: processing started...' >> $logFile;
		echo $(date '+%Y-%m-%d %H:%M:%S')' - Warning: catalog '$logDirPath' is absent, creating...' >> $logFile;
	else
		exit 0;
	fi
else
	if [ ! -e $logfile ]
	then
		touch $logfile;
	fi
	echo $(date '+%Y-%m-%d %H:%M:%S')' - Info: processing started...' >> $logFile;
fi

# Checking an availability of passed argument (option 1) that must contain right URL of video stream
if [ "$#" -eq 0 ] || [ $1 == null ] || [ -z '$1' ] || [[ $1 != 'http://'* ]] && [[ $1 != 'https://'* ]] || [[ $1 != *'.'$sourceFileExt ]]
then
	echo $(date '+%Y-%m-%d %H:%M:%S')' - Error: video stream URL is incorrect!' >> $logFile;
	exit 0;
else
	videoStreamURL=$1;
fi

# Checking up selected converter (option 2)
if [ ! "$#" -gt 1 ] || [ $2 == null ] || [ -z '$2' ] || [[ $2 != $convAVCONV ]]
then
	convSelect=$convFFMPEG;
	# Checking for installed ffmpeg tool
	if [ "$($convFFMPEG -loglevel quiet -version)" == "" ]
	then
		# Checking an existence of tool directory
		if [ ! -d $rootDir'/'$toolsDir ]
		then
			echo $(date '+%Y-%m-%d %H:%M:%S')' - Error: catalog '$rootDir'/'$toolsDir' is absent!' >> $logFile;
			exit 0;
		else
			# Checking an existence of ffmpeg tool (in provided tool directory)
			if [ ! -e $ffmpegTool ]
			then
				echo $(date '+%Y-%m-%d %H:%M:%S')' - Error: ffmpeg tool is absent in catalog '$rootDir'/'$toolsDir'!' >> $logFile;
				exit 0;
			else
				cmdFFMPEG=$ffmpegTool;
			fi
		fi
	fi
else
	convSelect=$convAVCONV;
	# Checking for installed avconv tool
	if [ "$($convAVCONV -loglevel quiet -version)" == "" ]
	then
		echo $(date '+%Y-%m-%d %H:%M:%S')' - Error: avconv tool is not installed!' >> $logFile;
		exit 0;
	fi
fi

# Checking an existence of temporary video folder and creation of it (if needed)
if [ ! -d $tmpDirPath ]
then
	echo $(date '+%Y-%m-%d %H:%M:%S')' - Warning: catalog '$tmpDirPath' is absent, creating...' >> $logFile;
	mkdir $tmpDirPath;
	if [ ! -d $tmpDirPath ]
	then
		echo $(date '+%Y-%m-%d %H:%M:%S')' - Error: failed to create an absent catalog '$tmpDirPath'!' >> $logFile;
		exit 0;
	fi
fi

# Checking an existence of the root folder for thumbnails and creation of it (if needed)
if [ ! -d $thumbRootDirPath ]
then
	echo $(date '+%Y-%m-%d %H:%M:%S')' - Warning: catalog '$thumbRootDirPath' is absent, creating...' >> $logFile;
	mkdir $thumbRootDirPath;
	if [ ! -d $thumbRootDirPath ]
	then
		echo $(date '+%Y-%m-%d %H:%M:%S')' - Error: failed to create an absent catalog '$thumbRootDirPath'!' >> $logFile;
		exit 0;
	fi
fi

# Checking for file presence and getting it from remote server
for ((i=1; i<=fetchingRetriesCount; i++));
do
	if [ $(wget --spider -S $videoStreamURL 2>&1 | grep 'HTTP/' | awk '{print $2}') != 200 ]
	then
		echo $(date '+%Y-%m-%d %H:%M:%S')' - Warning: file fetching attempt №'$i' failed (file is unavailable), waiting for '$pauseBetweenRetries' seconds...' >> $logFile;
		sleep $pauseBetweenRetries;
	else
		# Checking availability of data about content length
		for ((j=1; j<=fetchingRetriesCount; j++));
		do
			fileSize=$(wget --spider -S $videoStreamURL 2>&1 | grep '^Length: ' | awk '{print $2}');
			if [ "$fileSize" != '' ]
			then
				# Checking file to zero-byte size
				if [ "$fileSize" == 0 ] || [ "$fileSize" == 'unspecified' ]
				then
					echo $(date '+%Y-%m-%d %H:%M:%S')' - Warning: file size check attempt №'$j' failed (size is 0 bytes), waiting for '$pauseBetweenRetries' seconds...' >> $logFile;
					sleep $pauseBetweenRetries;
				else
					echo $(date '+%Y-%m-%d %H:%M:%S')' - Info: fetching videofile...' >> $logFile;
					wget -q -t $wgetRetriesCount -w $wgetRetriesWaitTime -O $videoFilePath $videoStreamURL;
					break;
				fi
			else
				# Trying to download source video file from the specified URL
				echo $(date '+%Y-%m-%d %H:%M:%S')' - Warning: videofile size is unknown (server provides no information)!' >> $logFile;
				echo $(date '+%Y-%m-%d %H:%M:%S')' - Info: fetching videofile...' >> $logFile;
				wget -q -t $wgetRetriesCount -w $wgetRetriesWaitTime -O $videoFilePath $videoStreamURL;
				break;
			fi
		done
		break;
	fi
done

# Checking availability of requested video file
if [ -e $videoFilePath ]
then
	# Checking received video file for the null size
	if [ $(stat --printf="%s" $videoFilePath) != 0 ]
	then
		# Checking an existence of the date-tagged folder for thumbnails and creation of it (if needed)
		if [ ! -d $thumbDir ]
		then
			echo $(date '+%Y-%m-%d %H:%M:%S')' - Warning: catalog '$thumbDir' is absent, creating...' >> $logFile;
			mkdir $thumbDir;
			if [ ! -d $thumbDir ]
			then
				echo $(date '+%Y-%m-%d %H:%M:%S')' - Error: failed to create an absent catalog '$thumbDir'!' >> $logFile;
				exit 0;
			fi
		fi

		# Starting video file processing using avconv tool
		echo $(date '+%Y-%m-%d %H:%M:%S')' - Info: processing videofile...' >> $logFile;
		if [ $convSelect == $convAVCONV ]
		then
			avconv -loglevel quiet -ss $thumbPeriod -i $videoFilePath -r $thumbFPS -an -sn -y $thumbFilePath;
		else
			$cmdFFMPEG -loglevel quiet -ss $thumbPeriod -i $videoFilePath -r $thumbFPS -an -sn -y $thumbFilePath;
		fi
		if [ -e $videoFilePath ]
		then
			rm $videoFilePath;
		fi

		# Starting preparation of thumbnail files for the future usage
		echo $(date '+%Y-%m-%d %H:%M:%S')' - Info: processing thumbnails...' >> $logFile;
		numbers=([6]=55 [5]=45 [4]=35 [3]=25 [2]=15 [1]=05 [0]=00);
		for i in {7..1}
		do
			if [ -e $thumbDir'/'$timestamp'_0'$i'.'$thumbFileExt ]
			then
				mv $thumbDir'/'$timestamp'_0'$i'.'$thumbFileExt $thumbDir'/'$timestamp'_'${numbers[$i-1]}'.'$thumbFileExt;
			fi
		done
		if [ -e $thumbDir'/'$timestamp'_00.'$thumbFileExt ]
		then
			rm $thumbDir'/'$timestamp'_00.'$thumbFileExt;
		fi

		# Calculating and logging out script's execution time
		endTimestamp=$(date +'%s');
		let 'deltaSeconds=endTimestamp-startTimestamp';
		echo $(date '+%Y-%m-%d %H:%M:%S')' - Info: processing finished in '$deltaSeconds' seconds.' >> $logFile;
	else
		# Actions in case if received video file is a null size file
		echo $(date '+%Y-%m-%d %H:%M:%S')' - Error: source videofile size is 0 bytes!' >> $logFile;
		if [ -e $videoFilePath ]
		then
			rm $videoFilePath;
		fi
	fi
else
	# Actions in case if requested video file doesn't exist
	echo $(date '+%Y-%m-%d %H:%M:%S')' - Error: source videofile does not exist!' >> $logFile;
fi
