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
TMP_SLEEP="/var/tmp/.chinachu-sleep"
CMD_CHINACHU_API_GET_NEXT_TIME="/usr/local/bin/chinachu-api-get-next-time"
CMD_GET_NEAREST_FUTURE_TIME="/usr/local/bin/get-nearest-future-time"

# variables
CHINACHU_URL="http://localhost:10772"
MARGIN_BOOT=600
SCHEDULE_UPDATE_EPG=05:55

case ${1} in
	hibernate|suspend)
		NEXT_PROG_START_TIME=`${CMD_CHINACHU_API_GET_NEXT_TIME} ${CHINACHU_URL}`
		UPDATE_EPG_TIME=`${CMD_GET_NEAREST_FUTURE_TIME} ${SCHEDULE_UPDATE_EPG}`
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
	;;
	thaw|resume)
		echo 0 > ${WAKEALARM}
		touch ${TMP_SLEEP}
		echo "This system is waking up from hibernate or suspend now."
	;;
esac
