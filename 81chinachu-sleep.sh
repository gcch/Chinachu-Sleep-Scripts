#!/bin/bash

# ------------------------------------------------------- #
#
# /etc/pm/sleep.d/81chinachu-sleep
#
# Copyright (c) 2015 tag
#
# ------------------------------------------------------- #

# environment
PATH=${PATH}
WAKEALARM=/sys/class/rtc/rtc0/wakealarm
DATE_FORMAT="%Y-%m-%d %T"

# variables
CHINACHU_URL="http://localhost:10772"
MARGIN_BOOT=600

case ${1} in
	hibernate|suspend)
		NEXT_PROG_START_TIME=`chinachu-api-get-next-time ${CHINACHU_URL}`
		WAKEUP_TIME=`expr ${NEXT_PROG_START_TIME} - ${MARGIN_BOOT}`
		if `date -d @${WAKEUP_TIME} +%s > ${WAKEALARM}`; then
			echo "[`date +"${DATE_FORMAT}"`] ${0}: set the next wake up time at `date -d @${WAKEUP_TIME} "${DATE_FORMAT}"`" 1>&2
		else
			echo "[`date +"${DATE_FORMAT}"`] ${0}: failure to schedule" 1>&2
		fi
		echo "This system will be stop soon."
	;;
	thaw|resume)
		echo 0 > ${WAKEALARM}
		echo "This system is waking up from hibernate or suspend now."
	;;
esac
