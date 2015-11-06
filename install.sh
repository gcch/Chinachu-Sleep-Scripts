#!/bin/bash

# ------------------------------------------------------- #
#
# Chinachu Sleep Scripts - Installer
#
# Copyright (c) 2015 tag
#
# ------------------------------------------------------- #


# ======================================================= #

# dir path (don't change!)
BIN_INST_PATH="/usr/local/bin"
CRON_DIR="/var/spool/cron"

# for getting the wake up time form sleep
TMP_SLEEP="/var/tmp/.chinachu-sleep"

# scripts
CHINACHU_API_PYTHON_SCRIPTS="chinachu-api-get-connected-count chinachu-api-get-next-time chinachu-api-is-recording"
SLEEP_SCRIPT_ORG="chinachu-sleep"
CHECK_STATUS_SCRIPT="chinachu-check-status"

# variables (sample)
CHINACHU_USER="chinachu"
CHINACHU_DIR="/home/${CHINACHU_USER}/chinachu"
CHINACHU_URL="http://localhost:20772"
PERIOD_CHECKING_STATUS_TO_SLEEP="15"
ROOM_BEFORE_REC="600"
PERIOD_NOT_GO_INTO_SLEEP_AFTER_BOOT="900"
PERIOD_NOT_GO_INTO_SLEEP_BEFORE_REC="3600"
UPDATE_EPG_SCHEDULE="0:00, 05:05, 23:59"

# ======================================================= #

function check-run-as-root() {
	echo "Checking this script is run as root..."
	if [ "$UID" -ne 0 ]; then
		echo "please run as root."
		exit 1
	fi
}

# ------------------------------------------------------- #

function check-command() {
	echo "Checking ${1} is installed..."
	if `type ${1} 1>/dev/null 2>/dev/null`; then
		:
	else
		echo "${CMD} is not found."
		exit 1
	fi
}

# ======================================================= #

function take-over-path() {
#	echo "Taking over PATH..."
	while [ "${1}" != "" ]; do
		sed -i -e "s|^\(PATH=\).*$|\1${PATH}|" ${1}
		shift
	done
}

# ------------------------------------------------------- #

function set-tmp-sleep-file-path() {
	while [ "${1}" != "" ]; do
		sed -i -e "s|^\(TMP_SLEEP=\).*$|\1${TMP_SLEEP}|" ${1}
		shift
	done
}

# ------------------------------------------------------- #

function select-sleep-manager() {
	echo "Select a power manager:"
	echo "[0] pm-utils"
	echo "[1] systemd"
	read USER_INPUT
	USER_INPUT=`echo ${USER_INPUT} | sed -e "s|\([0-9]*\).*#.*$|\1|"`

	case ${USER_INPUT} in
		0)
			echo "pm-utils is selected."
			SLEEP_SCRIPT="81chinachu-sleep"
			SLEEP_PATH="/etc/pm/sleep.d"
			SLEEP_CMD="/usr/sbin/pm-hibernate"
		;;
		1)
			echo "systemd is selected."
			SLEEP_SCRIPT="chinachu-sleep"
			SLEEP_PATH="/usr/lib/systemd/system-sleep/"
			SLEEP_CMD="/usr/bin/systemctl hibernate"
		;;
		*)
			echo "error: Unknown input."
			select-sleep-manager
		;;
	esac
}

# ======================================================= #

function get-chinachu-url() {
	echo "Chinachu URL (e.g., ${CHUNACHU_URL}):"
	read USER_INPUT
	CHINACHU_URL=`echo ${USER_INPUT} | sed -e "s|^\(http://.*:[0-9]*\).*#.*$|\1|"`
}

function apply-chinachu-url() {
	while [ "${1}" != "" ]; do
		sed -i -e "s|^\(CHINACHU_URL=\).*$|\1${CHINACHU_URL}|" ${1}
		shift
	done
}

# ------------------------------------------------------- #

function get-chinachu-user() {
	echo "Chinachu installation user (e.g., ${CHINACHU_USER}):"
	read USER_INPUT
	CHINACHU_USER=`echo ${USER_INPUT} | sed -e "s|^\(.*\) .*#.*$|\1|"`
}

# ------------------------------------------------------- #

function get-chinachu-dir() {
	CHINACHU_DIR="/home/${CHINACHU_USER}/chinachu"
	echo "Path of Chinachu installed directory (e.g., ${CHINACHU_DIR}):"
	read USER_INPUT
	CHINACHU_DIR=`echo ${USER_INPUT} | sed -e "s|^\(.*\) .*#.*$|\1|"`
}

# ------------------------------------------------------- #

function get-period-checking-status-to-sleep() {
	echo "Period of checking status to sleep (e.g., ${PERIOD_CHECKING_STATUS_TO_SLEEP} [min.])"
	read USER_INPUT
	PERIOD_CHECKING_STATUS_TO_SLEEP=`echo ${USER_INPUT} | sed -e "s|\([0-9]*\).*#.*$|\1|"`
}

# ------------------------------------------------------- #

function get-room-before-recording() {
	echo "Room between the next wake up and the next recording (e.g., ${ROOM_BEFORE_REC} [sec.]):"
	read USER_INPUT
	ROOM_BEFORE_REC=`echo ${USER_INPUT} | sed -e "s|\([0-9]*\).*#.*$|\1|"`
}

function apply-room-before-recording() {
	while [ "${1}" != "" ]; do
		sed -i -e "s/^\(ROOM_BEFORE_REC=\).*$/\1${ROOM_BEFORE_REC}/" ${1}
		shift
	done
}

# ------------------------------------------------------- #

function get-period-not-go-into-sleep-after-boot() {
	echo "Period to not go into sleep after starting up (e.g., ${PERIOD_NOT_GO_INTO_SLEEP_AFTER_BOOT} [sec.]):"
	read USER_INPUT
	PERIOD_NOT_GO_INTO_SLEEP_AFTER_BOOT=`echo ${USER_INPUT} | sed -e "s|\([0-9]*\).*#.*$|\1|"`
}

function apply-period-not-go-into-sleep-after-boot() {
	while [ "${1}" != "" ]; do
		sed -i -e "s/^\(PERIOD_NOT_GO_INTO_SLEEP_AFTER_BOOT=\).*$/\1${PERIOD_NOT_GO_INTO_SLEEP_AFTER_BOOT}/" ${1}
		shift
	done
}

# ------------------------------------------------------- #

function get-period-not-go-into-sleep-before-recording() {
	echo "Period to not go into sleep before the next recording (e.g., ${PERIOD_NOT_GO_INTO_SLEEP_BEFORE_REC} [sec.]):"
	read USER_INPUT
	PERIOD_NOT_GO_INTO_SLEEP_BEFORE_REC=`echo ${USER_INPUT} | sed -e "s|\([0-9]*\).*#.*$|\1|"`
}

function apply-period-not-go-into-sleep-before-recording() {
	while [ "${1}" != "" ]; do
		sed -i -e "s/^\(PERIOD_NOT_GO_INTO_SLEEP_BEFORE_REC=\).*$/\1${PERIOD_NOT_GO_INTO_SLEEP_BEFORE_REC}/" ${1}
		shift
	done
}

# ------------------------------------------------------- #

function get-update-epg-schedule() {
	echo "Updating epg sechedule (e.g., ${UPDATE_EPG_SCHEDULE}):"
	read USER_INPUT
	USER_INPUT=( `echo ${USER_INPUT} | tr -s "," " "` )
	for (( I = 0; I < ${#USER_INPUT[@]}; I++)); do
		TMP="`echo ${USER_INPUT[$I]} | grep -e "^[0-1]\{0,1\}[0-9]:[0-5]\{0,1\}[0-9]$" -e "^2[0-3]:[0-5]\{0,1\}[0-9]$"` ${TMP}"
	done
	TMP=( `echo ${TMP} | sed -e "s/  */ /g"` )
	UPDATE_EPG_SCHEDULE="${TMP}"
}

function apply-update-epg-schedule() {
	while [ "${1}" != "" ]; do
		sed -i -e "s/^\(UPDATE_EPG_SCHEDULE=\).*$/\1\"${UPDATE_EPG_SCHEDULE}\"/" ${1}
		shift
	done
}

# ------------------------------------------------------- #

# get variables
function get-variables() {
	select-sleep-manager
	get-chinachu-user
	get-chinachu-dir
	get-chinachu-url
	get-period-checking-status-to-sleep
	get-room-before-recording
	get-period-not-go-into-sleep-after-boot
	get-period-not-go-into-sleep-before-recording
	get-update-epg-schedule
}

# ======================================================= #

function install-chinachu-api-scripts() {
	echo "Installing Chinachu API scripts..."
	for S in ${CHINACHU_API_PYTHON_SCRIPTS}; do
		cp ${S}.py ${S}
		chmod +x ${S}
		mv ${S} ${BIN_INST_PATH}
	done
}

# ------------------------------------------------------- #

function install-sleep-script() {
	echo "Installing sleep-script..."

#	echo "Duplicating..."
	cp ${SLEEP_SCRIPT_ORG}.sh ${SLEEP_SCRIPT}

#	echo "Applying user variables..."
	TARGET="${SLEEP_SCRIPT}"
	take-over-path ${TARGET}
	set-tmp-sleep-file-path ${TARGET}
	apply-chinachu-url ${TARGET}
	apply-room-before-recording ${TARGET}
#	apply-period-not-go-into-sleep-after-boot ${TARGET}
#	apply-period-not-go-into-sleep-before-recording ${TARGET}
	apply-update-epg-schedule ${TARGET}

#	echo "Changing authority..."
	chmod +x ${SLEEP_SCRIPT}

#	echo "Moving file..."
	mv ${SLEEP_SCRIPT} ${SLEEP_PATH}
}

# ------------------------------------------------------- #

function install-check-chinachu-status() {
	echo "Installing chinachu-check-status..."

#	echo "Duplicating..."
	cp ${CHECK_STATUS_SCRIPT}.sh ${CHECK_STATUS_SCRIPT}

#	echo "Applying user variables..."
	TARGET="${CHECK_STATUS_SCRIPT}"
	take-over-path ${TARGET}
	set-tmp-sleep-file-path ${TARGET}
	apply-chinachu-url ${TARGET}
#	apply-room-before-recording ${TARGET}
	apply-period-not-go-into-sleep-after-boot ${TARGET}
	apply-period-not-go-into-sleep-before-recording ${TARGET}
#	apply-update-epg-schedule ${TARGET}

#	echo "Changing authority..."
	chmod +x ${CHECK_STATUS_SCRIPT}

#	echo "Moving file..."
	mv ${CHECK_STATUS_SCRIPT} ${BIN_INST_PATH}
}

# ======================================================= #

function setup-cron-for-sleep() {
	echo "Setting up cron for sleep..."

	# cron file
	CRON_FILE="${CRON_DIR}/root"

	# schedule & job
	CRON_SCHEDULE="*/${PERIOD_CHECKING_STATUS_TO_SLEEP} * * * * "
	CRON_JOB="${CRON_SCHEDULE}${BIN_INST_PATH}/${CHECK_STATUS_SCRIPT} && sleep 10 && ${SLEEP_CMD}"

	if [ `grep "${BIN_INST_PATH//\\/\\\\}/${CHECK_STATUS_SCRIPT//\\/\\\\}" "${CRON_FILE}" | wc -l` -eq 0 ]; then
		:
	else
		sed -i -e "s|^.*${BIN_INST_PATH}/${CHECK_STATUS_SCRIPT}.*$||g" "${CRON_FILE}"
		sed -i '/^\s*$/d' "${CRON_FILE}"
	fi

	echo "${CRON_JOB}" >> "${CRON_FILE}"
}

# ------------------------------------------------------- #

function setup-cron-for-updating-epg() {
	echo "Setting up cron for updating EPG..."

	# cron file
	CRON_FILE="${CRON_DIR}/${CHINACHU_USER}"

	# schedule & job
	CRON_SCHEDULE=( ${UPDATE_EPG_SCHEDULE} )
	CRON_JOB="${CHINACHU_DIR}/chinachu update -f"

	# take over path
	if [ `grep "${CRON_JOB//\\/\\\\}" "${CRON_FILE}" | wc -l` -eq 0 ]; then
		echo "PATH=${PATH}" >> "${CRON_FILE}"
	else
		sed -i -e "s|^\(PATH=\).*$|\1${PATH}|" ${CRON_FILE}
	fi

	# setup cron for updating epg: delete old entries
	if [ `grep "${CRON_JOB//\\/\\\\}" "${CRON_FILE}" | wc -l` -eq 0 ]; then
		:
	else
		sed -i -e "s|^.*${CRON_JOB}.*$||g" "${CRON_FILE}"
		sed -i '/^\s*$/d' "${CRON_FILE}"
	fi

	# setup cron for updating epg: create new entries
	for (( I = 0; I < ${#CRON_SCHEDULE[@]}; I++)); do
		HOUR=`date -d ${CRON_SCHEDULE[$I]} +%H`
		MIN=`date -d ${CRON_SCHEDULE[$I]} +%M`
		CRON_ENTRY="$((10#${MIN})) $((10#${HOUR})) * * * ${CRON_JOB}"
		echo "${CRON_ENTRY}" >> "${CRON_FILE}"
	done
}

# ------------------------------------------------------- #

function restart-cron() {
	echo "Restart cron daemon..."

	if [ -f /etc/init.d/crond ]; then
		/etc/init.d/crond restart
	elif [ `cat /etc/os-release | grep "^VERSION=" | sed -e "s/^VERSION=.*\([0-9]\).*$/\1/"` -eq 6 ]; then
		# for RHEL / CentOS Linux 6.x
		service crond restart
	elif [ `cat /etc/os-release | grep "^VERSION=" | sed -e "s/^VERSION=.*\([0-9]\).*$/\1/"` -eq 7 ]; then
		# for RHEL / CentOS Linux 7.x
		systemctl restart crond.service
	else
		echo "please restart crond by yourself."
	fi
}

# ======================================================= #


# ======================================================= #

echo
echo "# ------------------------------------------------------- #"
echo "#                                                         #"
echo "#          Chinachu Sleep Scripts - Installer             #"
echo "#                                                         #"
echo "#                             Copyright (c) 2015 tag      #"
echo "#                                                         #"
echo "# ------------------------------------------------------- #"
echo

# check evironment
check-run-as-root
check-command python3

echo
echo "# ------------------------------------------------------- #"
echo

# get user input
get-variables

echo
echo "# ------------------------------------------------------- #"
echo

# install
echo "Setup scripts:"
echo
install-chinachu-api-scripts
install-sleep-script
install-check-chinachu-status

echo
echo "# ------------------------------------------------------- #"
echo

# setup cron
echo "Setup cron:"
echo
setup-cron-for-sleep
setup-cron-for-updating-epg
restart-cron

echo
echo "# ------------------------------------------------------- #"
echo
echo "Installation is completed!"
exit 0

# ======================================================= #
