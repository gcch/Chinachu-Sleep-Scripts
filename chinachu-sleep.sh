#!/bin/bash

# ------------------------------------------------------- #
#
# chinachu-sleep.sh
#
# Copyright (c) 2015 tag
#
# ------------------------------------------------------- #


# ======================================================= #

# environment
PATH=${PATH}
DATE_FORMAT="%Y-%m-%d %T"

TMP_SLEEP="/var/tmp/.chinachu-sleep"
WAKEALARM="/sys/class/rtc/rtc0/wakealarm"
CMD_CHINACHU_API_GET_NEXT_TIME="/usr/local/bin/chinachu-api-get-next-time"

# variables
CHINACHU_URL="http://localhost:20772"
ROOM_BEFORE_REC="600"
UPDATE_EPG_SCHEDULE="0:00, 05:05, 23:59"

# ======================================================= #

function get-nearest-future-time() {
	# check the number of arguments
	if [ $# -le 0 ]; then
		echo "usage: $0 <time1> (<time2> ...)" 1>&2
		exit 1
	fi

	# get arguments
	while [ "$1" != "" ]; do
		_SCHEDULE="${_SCHEDULE} `echo $1 | grep -e "^[0-1]\{0,1\}[0-9]:[0-5]\{0,1\}[0-9]$" -e "^2[0-3]:[0-5]\{0,1\}[0-9]$"`"
		shift
	done
	_SCHEDULE=( ${_SCHEDULE} )
	#echo ${_SCHEDULE[@]} 1>&2

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
	# get the start time of the next reserved program
	NEXT_PROG_START_TIME=`${CMD_CHINACHU_API_GET_NEXT_TIME} ${CHINACHU_URL}`
	echo "NEXT_PROG_START_TIME: `date -d @${NEXT_PROG_START_TIME} +"${DATE_FORMAT}"` (${NEXT_PROG_START_TIME})" 1>&2
	# get the time of the periodic epg update
	UPDATE_EPG_TIME=`get-nearest-future-time ${UPDATE_EPG_SCHEDULE}`
	echo "UPDATE_EPG_TIME: `date -d @${UPDATE_EPG_TIME} +"${DATE_FORMAT}"` (${UPDATE_EPG_TIME})" 1>&2

	if [ -z "${NEXT_PROG_START_TIME}" ] && [ -z "${UPDATE_EPG_TIME}" ]; then
		echo "This system will be stop without scheduling next wakeup"
		exit 0
	fi

	if [ -n "${NEXT_PROG_START_TIME}" ]; then
		if [ ${NEXT_PROG_START_TIME} -lt ${UPDATE_EPG_TIME} ]; then
			WAKEUP_TIME=`expr ${NEXT_PROG_START_TIME} - ${ROOM_BEFORE_REC}`
		else
			WAKEUP_TIME=`expr ${UPDATE_EPG_TIME} - ${ROOM_BEFORE_REC}`
		fi
	else
		WAKEUP_TIME=`expr ${UPDATE_EPG_TIME} - ${ROOM_BEFORE_REC}`
	fi

	echo "try to set an wakeup alarm (${WAKEUP_TIME})" 1>&2
	echo 0 > ${WAKEALARM}
	if `echo ${WAKEUP_TIME} > ${WAKEALARM}`; then
		echo "[`date +"${DATE_FORMAT}"`] ${0}: set the next wake up time at `date -d @${WAKEUP_TIME} +"${DATE_FORMAT}"`" 1>&2
	else
		echo "[`date +"${DATE_FORMAT}"`] ${0}: failure to schedule" 1>&2
	fi
	echo "This system will be stopped soon."
}

# ------------------------------------------------------- #

function initialize-after-wakeup() {
	echo 0 > ${WAKEALARM}
	touch ${TMP_SLEEP}
	echo "This system is waking up from hibernate or suspend now."
}

# ------------------------------------------------------- #

# for pm-utils
case ${1} in
	hibernate|suspend)
		prepare-to-sleep
	;;
	thaw|resume)
		initialize-after-wakeup
	;;
esac

# for systemd
case ${1}/${2} in
	pre/*)
		prepare-to-sleep
	;;
	post/*)
		initialize-after-wakeup
	;;
esac

# for test
case ${1} in
        test1)
                prepare-to-sleep
        ;;
        test2)
                initialize-after-wakeup
 	;;
esac

exit 0
