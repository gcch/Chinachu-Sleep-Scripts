#!/bin/bash

# ------------------------------------------------------- #
#
# /etc/pm/sleep.d/81chinachu-sleep
# /usr/lib/systemd/system-sleep/chinachu-sleep
#
# Copyright (c) 2015 tag
#
# ------------------------------------------------------- #

# environment
PATH=${PATH}
WAKEALARM=/sys/class/rtc/rtc0/wakealarm
DATE_FORMAT="%Y-%m-%d %T"
TMP_SLEEP="/var/tmp/.chinachu-sleep"
CMD_CHINACHU_API_GET_NEXT_TIME="/usr/local/bin/chinachu-api-get-next-time"
CMD_GET_NEAREST_FUTURE_TIME="/usr/local/bin/get-nearest-future-time"

# variables
CHINACHU_URL="http://localhost:10772"
MARGIN_BOOT=600
SCHEDULE_UPDATE_EPG="05:55"

# ------------------------------------------------------- #

function get-nearest-future-time() {
	# check the number of arguments
	if [ $# -le 0 ]; then
		echo "usage: $0 <time1> (<time2> ...)"
		exit 1
	fi

	# get arguments
	while [ "$1" != "" ]; do
		_SCHEDULE="${_SCHEDULE} `echo $1 | grep -e "^[0-1]\{0,1\}[0-9]:[0-5]\{0,1\}[0-9]$" -e "^2[0-3]:[0-5]\{0,1\}[0-9]$"`"
		shift
	done
	_SCHEDULE=( ${_SCHEDULE} )
	#echo ${_SCHEDULE[@]}

	# current date
	_NOW=`date +%s`
	#echo "now: ${_NOW} (`date -d @${_NOW}`)" 1>&2

	# next scheduled time
	_FLG=1
	_TIME=`date -d +1day +%s`

	# today
	for ((I = 0; I < ${#_SCHEDULE[@]}; I++)); do
		_TMP=`date -d ${_SCHEDULE[$I]} +%s`
		#echo "candidate: ${_TMP} (`date -d @${_TMP}`)" 1>&2
		if [ ${_TMP} -gt ${_NOW} -a ${_TMP} -lt ${_TIME} ]; then
			#echo "found" 1>&2
			_TIME=${_TMP}
			_FLG=0
		fi
	done

	# found next boot time
	if [ ${_FLG} -eq 0 ]; then
		echo ${_TIME}
		exit 0
	fi

	# tomorrow
	for ((I = 0; I < ${#_SCHEDULE[@]}; I++)); do
		_TMP=`date -d ${_SCHEDULE[$I]} +%s`
		_TMP=`expr ${_TMP} + 86400`	# 86400 sec. = 1 day
		#echo "candidate: ${_TMP} (`date -d @${_TMP}`)" 1>&2
		if [ ${_TMP} -gt ${_NOW} -a ${_TMP} -lt ${_TIME} ]; then
			#echo "found" 1>&2
			_TIME=${_TMP}
			_FLG=0
		fi
	done

	echo ${_TIME}
	exit ${_FLG}
}

# ------------------------------------------------------- #

function prepare-to-sleep() {
	NEXT_PROG_START_TIME=`${CMD_CHINACHU_API_GET_NEXT_TIME} ${CHINACHU_URL}`
	UPDATE_EPG_TIME=`get-nearest-future-time ${SCHEDULE_UPDATE_EPG}`
	WAKEUP_TIME=`expr ${NEXT_PROG_START_TIME} - ${MARGIN_BOOT}`
	if [ "${UPDATE_EPG_TIME}" -ne "" ]; then
		if [ ${NEXT_PROG_START_TIME} -gt ${UPDATE_EPG_TIME} ]; then
			WAKEUP_TIME=`expr ${UPDATE_EPG_TIME} - ${MARGIN_BOOT}`
		fi
	fi
	if `date -d @${WAKEUP_TIME} +%s > ${WAKEALARM}`; then
		echo "[`date +"${DATE_FORMAT}"`] ${0}: set the next wake up time at `date -d @${WAKEUP_TIME} "${DATE_FORMAT}"`" 1>&2
	else
		echo "[`date +"${DATE_FORMAT}"`] ${0}: failure to schedule" 1>&2
	fi
	echo "This system will be stop soon."
}

# ------------------------------------------------------- #

function initialize-after-wakeup() {
	echo 0 > ${WAKEALARM}
	touch ${TMP_SLEEP}
	echo "This system is waking up from hibernate or suspend now."
}

# ------------------------------------------------------- #

# for pm-utils
if [ $# -eq 1 ]; then
	case ${1} in
		hibernate|suspend)
			prepare-to-sleep
		;;
		thaw|resume)
			initialize-after-wakeup
		;;
	esac
fi

# for systemd
if [ $# -eq 2 ]; then
	case ${1}/${2} in
		pre/*)
			prepare-to-sleep
		;;
		post/*)
			initialize-after-wakeup
		;;
	esac
fi
