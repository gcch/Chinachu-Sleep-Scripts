#!/bin/bash

# ------------------------------------------------------- #
#
# chinachu-check-status.sh
#
# Copyright (c) 2015 tag
#
# ------------------------------------------------------- #

# environment
PATH=${PATH}
DATE_FORMAT="%Y-%m-%d %T"

# variables
CHINACHU_URL="http://localhost:10772"
MARGIN_UPTIME=600
MARGIN_SLEEP=1800

# ------------------------------------------------------- #

# check the status of Chinachu: connected count
if [ `chinachu-api-get-connected-count ${CHINACHU_URL}` -gt 0 ]; then
	echo "[`date +"${DATE_FORMAT}"`] ${0}: Someone is connecting to Chinachu WUI." 1>&2
	exit 1
fi

# ------------------------------------------------------- #

# check the status of Chinachu: is Chinachu recording
if `chinachu-api-is-recording ${CHINACHU_URL}`; then
	echo "[`date +"${DATE_FORMAT}"`] ${0}: Chinachu is recording now." 1>&2
	exit 1
fi

# ------------------------------------------------------- #

# check the status of Chinachu: is Chinachu waiting for the next recording
NOW=`date +%s`
NEXT=`chinachu-api-get-next-time ${CHINACHU_URL}`
BORDER=$((${NEXT} - ${MARGIN_SLEEP}))
if [ ${NOW} -gt ${BORDER} ]; then
	echo "[`date +"${DATE_FORMAT}"`] ${0}: Chinachu is waiting for the next recording. (next: `date -d @${NEXT} +"${DATE_FORMAT}"`)" 1>&2
	exit 1
fi

# ------------------------------------------------------- #

# check the uptime
NOW=`date +%s`
UPTIME=date -d "`uptime -s`" +%s
#UPTIME=$(ALARM_DATE=$(cat /proc/driver/rtc | egrep 'alrm_time|alrm_date' | echo $(sed -e "s/^alrm_time.* \([0-9]\+:[0-9]\+:[0-9]\+\)$/\1/" -e "s/^alrm_date.* \([0-9]\+-[0-9]\+-[0-9]\+\)$/\1/") UTC) ; date -d "${ALARM_DATE}" +%s)
BORDER=$((${UPTIME} + ${MARGIN_UPTIME}))
if [ ${NOW} -lt ${BORDER} ]; then
	echo "[`date +"${DATE_FORMAT}"`] ${0}: It has not elapsed only a few minutes from a boot. (uptime: `date -d @${UPTIME} +"${DATE_FORMAT}"`)" 1>&2
	exit 1
fi

# ------------------------------------------------------- #

# check whether someone is accessing this server via Samba (root only can execute normally)
if type smbstatus 1>/dev/null 2>&1; then
	SMB_USERS=`smbstatus -p | grep "^[0-9]" | wc -l`
	if [ ${SMB_USERS} -gt 0 ]; then
		echo "[`date +"${DATE_FORMAT}"`] ${0}: Someone is accessing this server via Samba." 1>&2
		exit 1
	fi
fi

# ------------------------------------------------------- #

# check whether someone is logging in to this server
USERS=`who -u | wc -l`
if [ ${USERS} -gt 0 ]; then
	echo "[`date +"${DATE_FORMAT}"`] ${0}: Someone is logging in to this server." 1>&2
	exit 1
fi

# ------------------------------------------------------- #

# normal end
exit 0
