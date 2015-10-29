#!/bin/bash

# ------------------------------------------------------- #
#
# get-nearest-future-time.sh
#
# Copyright (c) 2015 tag
#
# ------------------------------------------------------- #

# check the number of arguments
if [ $# -le 0 ]; then
	echo "usage: $0 <time1> (<time2> ...)"
	exit 1
fi

# get arguments
while [ "$1" != "" ]; do
	SCHEDULE="${SCHEDULE} `echo $1 | grep -e "^[0-1]\{0,1\}[0-9]:[0-5]\{0,1\}[0-9]$" -e "^2[0-3]:[0-5]\{0,1\}[0-9]$"`"
	shift
done
SCHEDULE=( ${SCHEDULE} )
#echo ${SCHEDULE[@]}

# current date
NOW=`date +%s`
#echo "now: ${NOW} (`date -d @${NOW}`)" 1>&2

# next scheduled time
FLG=1
TIME=`date -d +1day +%s`

# today
for ((I = 0; I < ${#SCHEDULE[@]}; I++)); do
	TMP=`date -d ${SCHEDULE[$I]} +%s`
	#echo "candidate: ${TMP} (`date -d @${TMP}`)" 1>&2
	if [ ${TMP} -gt ${NOW} -a ${TMP} -lt ${TIME} ]; then
		#echo "found" 1>&2
		TIME=${TMP}
		FLG=0
	fi
done

# found next boot time
if [ ${FLG} -eq 0 ]; then
	echo ${TIME}
	exit 0
fi

# tomorrow
for ((I = 0; I < ${#SCHEDULE[@]}; I++)); do
	TMP=`date -d ${SCHEDULE[$I]} +%s`
	TMP=`expr ${TMP} + 86400`	# 86400 sec. = 1 day
#	echo "candidate: ${TMP} (`date -d @${TMP}`)" 1>&2
	if [ ${TMP} -gt ${NOW} -a ${TMP} -lt ${TIME} ]; then
#		echo "found" 1>&2
		TIME=${TMP}
		FLG=0
	fi
done

echo ${TIME}
exit ${FLG}
