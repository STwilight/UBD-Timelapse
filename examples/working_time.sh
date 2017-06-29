#!/bin/bash

startTime='00:30'; #07:30
endTime='00:31';   #21:00

curTime=$(date +'%H:%M');
curDate=$(date +'%Y-%m-%d');
curDateTime=$(date -d $curDate' '$curTime +'%Y-%m-%d %H:%M');
curTimestamp=$(date -d $curDate' '$curTime +'%s');

startDateTime=$(date -d $curDate' '$startTime +'%Y-%m-%d %H:%M');
startTimestamp=$(date -d $curDate' '$startTime +'%s');

endDateTime=$(date -d $curDate' '$endTime +'%Y-%m-%d %H:%M');
endTimestamp=$(date -d $curDate' '$endTime +'%s');

echo 'Current date and time is '$curDate', '$curTime', timestamp is: '$curTimestamp;
echo 'Start date and time is '$startDateTime', timestamp is: '$startTimestamp;
echo 'End date and time is '$endDateTime', timestamp is: '$endTimestamp;

if [ $curTimestamp -ge $startTimestamp ] && [ $endTimestamp -ge $curTimestamp ]
then
    echo 'WORKING: '$curDateTime' is bigger than or equal  '$startDateTime' and smaller than or equal '$endDateTime
else
    echo 'NOT WORKING: '$curDateTime' is smaller than '$startDateTime' or bigger than '$endDateTime
fi

exit 0
