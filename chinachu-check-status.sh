#!/bin/bash

# ------------------------------------------------------- #
#
# chinachu-check-status.sh
#
# Copyright (c) 2015 tag
#
# ------------------------------------------------------- #


# ======================================================= #

# environment
PATH=${PATH}
DATE_FORMAT="%Y-%m-%d %T"

TMP_SLEEP="/var/tmp/.chinachu-sleep"

# variables
CHINACHU_URL="http://localhost:20772"
PERIOD_NOT_GO_INTO_SLEEP_AFTER_BOOT="900"
PERIOD_NOT_GO_INTO_SLEEP_BEFORE_REC="3600"

# ======================================================= #

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
BORDER=$((${NEXT} - ${PERIOD_NOT_GO_INTO_SLEEP_BEFORE_REC}))
if [ ${NOW} -gt ${BORDER} ]; then
	echo "[`date +"${DATE_FORMAT}"`] ${0}: Chinachu is waiting for the next recording. (next: `date -d @${NEXT} +"${DATE_FORMAT}"`)" 1>&2
	exit 1
fi

# ------------------------------------------------------- #

# check the uptime
NOW=`date +%s`
UPTIME=`uptime -s | date -f - +%s`
BORDER=$((${UPTIME} + ${PERIOD_NOT_GO_INTO_SLEEP_AFTER_BOOT}))
if [ ${NOW} -lt ${BORDER} ]; then
	echo "[`date +"${DATE_FORMAT}"`] ${0}: It has not elapsed only a few minutes from a boot. (uptime: `date -d @${UPTIME} +"${DATE_FORMAT}"`)" 1>&2
	exit 1
fi

# ------------------------------------------------------- #

# check the time from waking up from sleep
if [ -f ${TMP_SLEEP} ]; then
	NOW=`date +%s`
	WAKEUPTIME=`stat -c %y ${TMP_SLEEP} | date -f - +%s`
	BORDER=$((${WAKEUPTIME} + ${PERIOD_NOT_GO_INTO_SLEEP_AFTER_BOOT}))
	if [ ${NOW} -lt ${BORDER} ]; then
		echo "[`date +"${DATE_FORMAT}"`] ${0}: It has not elapsed only a few minutes from waking up from sleep. (wakeuptime: `date -d @${WAKEUPTIME} +"${DATE_FORMAT}"`)" 1>&2
		exit 1
	fi
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
