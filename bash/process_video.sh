#!/bin/bash

videoSvcSrv='http://vs8.videoprobki.com.ua/tvukrbud';
videoSvcFile='cam3.mp4';
videoSvcStream=$videoSvcSrv'/'$videoSvcFile;

videoDir='/home/ubdm/tmp';
videoFileExt='mp4';

timestamp=$(date '+%Y-%m-%d_%H.%M');
videoFilePath=$videoDir'/'$timestamp'.'$videoFileExt;

datestamp=$(date '+%Y-%m-%d');
thumbRootDir='/home/ubdm/scr';
thumbDir=$thumbRootDir'/'$datestamp;
thumbFileExt='jpg';
thumbFilePath=$thumbDir'/'$timestamp'_%02d.'$thumbFileExt;

thumbPeriod='00:00:05';
thumbFPS='1/10';

if [ ! -d $videoDir ]
then
    mkdir $videoDir
fi

if [ ! -d $thumbRootDir ]
then
    mkdir $thumbRootDir
fi

if [ ! -d $thumbDir ]
then
    mkdir $thumbDir
fi

for i in {1..3}
do
    if [ $(wget --spider -S $videoSvcStream 2>&1 | grep 'HTTP/' | awk '{print $2}') != 200 ]
    then
        echo $(date '+%Y-%m-%d %H.%M.%S')' Warning: '$i' videofile fetching attempt failed, waiting for 5 seconds...'
        sleep 5s
    else
        wget -t 3 -w 3 -O $videoFilePath $videoSvcStream
        break
    fi
done

if [ -e $videoFilePath ]
then
    if [ $(stat --printf="%s" $videoFilePath) != 0 ]
    then
        avconv -i $videoFilePath -ss $thumbPeriod -vsync 1 -r $thumbFPS -an -y $thumbFilePath
        rm $videoFilePath

        numbers=([6]=55 [5]=45 [4]=35 [3]=25 [2]=15 [1]=05 [0]=00);

        for i in {7..1}
        do
            if [ -e $thumbDir'/'$timestamp'_0'$i'.'$thumbFileExt ]
            then
                mv $thumbDir'/'$timestamp'_0'$i'.'$thumbFileExt $thumbDir'/'$timestamp'_'${numbers[$i-1]}'.'$thumbFileExt
            fi
        done

        if [ -e $thumbDir'/'$timestamp'_00.'$thumbFileExt ]
        then
            rm $thumbDir'/'$timestamp'_00.'$thumbFileExt
        fi
    else
        rm $videoFilePath
        echo $(date '+%Y-%m-%d %H.%M.%S')' Error: source videofile size is 0!'
    fi
else
    echo $(date '+%Y-%m-%d %H.%M.%S')' Error: source videofile does not exist!'
fi
