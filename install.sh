#!/bin/bash

# ------------------------------------------------------- #
#
# Chinachu Sleep Scripts - Installer
#
# Copyright (c) 2015 tag
#
# ------------------------------------------------------- #

# check: run as root
if [ "$UID" -ne 0 ]; then
	echo "please run as root."
	exit 1
fi

# check: Python 3.x
if `type python3 1>/dev/null 2>/dev/null`; then
	:
else
	echo "please install python 3.x."
	exit 1
	
	# It falls into the below situation even though Python 3.x has already been installed,
	#
	#     $ sudo ./install.sh < settings
	#     please install python 3.x.
	#
	# try the below commands.
	#
	#     $ export PATH=$PATH
	#     $ sudo PATH=$PATH ./install.sh < settings
fi

# ------------------------------------------------------- #

# variables: scripts
BIN_PATH="/usr/local/bin"
PY_SCRIPTS="chinachu-get-next-time chinachu-is-recording"
SH_SCRIPTS="chinachu-check-status"

# variables: pm-utils
PM_SLEEP_PATH="/etc/pm/sleep.d"
PM_SLEEP_SCRIPT="81chinachu-sleep"
PM_SLEEP_CMD="/usr/sbin/pm-hibernate"

# variables: systemd
SYSTEMCTL_SLEEP_PATH="/usr/lib/systemd/system-sleep/"
SYSTEMCTL_SLEEP_SCRIPT="chinachu-sleep"
SYSTEMCTL_SLEEP_CMD="/usr/bin/systemctl hibernate"

# ------------------------------------------------------- #

# select power manager
echo "select the power manager:"
echo "[0] pm-utils"
echo "[1] systemd"
read USER_INPUT
if [ ${USER_INPUT} -eq 0 ];
	SLEEP_PATH="${PM_SLEEP_PATH}"
	SLEEP_SCRIPT="${PM_SLEEP_SCRIPT}"
	SLEEP_CMD="${PM_SLEEP_CMD}"
else
	SLEEP_PATH="${SYSTEMCTL_PATH}"
	SLEEP_SCRIPT="${SYSTEMCTL_SCRIPT}"
	SLEEP_CMD="${SYSTEMCTL_CMD}"
fi

# ------------------------------------------------------- #

# duplicate
cp ${SLEEP_SCRIPT}.sh ${SLEEP_SCRIPT}
cp ${SH_SCRIPTS}.sh ${SH_SCRIPTS}
for s in ${PY_SCRIPTS}; do
        cp ${s}.py ${s}
done

# take over the path
sed -i -e "s|^\(PATH=\).*$|\1${PATH}|"  ${SLEEP_SCRIPT} ${SH_SCRIPTS}

# get Chinachu URL
echo "input your Chinachu url (e.g., http://localhost:10772)"
read USER_INPUT
USER_INPUT=`echo ${USER_INPUT} | sed -e "s|^\(http://.*:[0-9]*\).*#.*$|\1|"`
sed -i -e "s|^\(CHINACHU_URL=\).*$|\1${USER_INPUT}|" ${SLEEP_SCRIPT} ${SH_SCRIPTS}

# get MARGIN_UPTIMERGIN_BOOT
echo "input MARGIN_BOOT (e.g., 600 [sec.])"
read USER_INPUT
USER_INPUT=`echo ${USER_INPUT} | sed -e "s|\([0-9]*\).*#.*$|\1|"`
sed -i -e "s/^\(MARGIN_BOOT=\).*$/\1${USER_INPUT}/" ${SLEEP_SCRIPT}

echo "input MARGIN_UPTIME (e.g., 600 [sec.])"
read USER_INPUT
USER_INPUT=`echo ${USER_INPUT} | sed -e "s|\([0-9]*\).*#.*$|\1|"`
sed -i -e "s/^\(MARGIN_UPTIME=\).*$/\1${USER_INPUT}/" ${SH_SCRIPTS}

# get MARGIN_SLEEP
echo "input MARGIN_SLEEP (e.g., 600 [sec.])"
read USER_INPUT
USER_INPUT=`echo ${USER_INPUT} | sed -e "s|\([0-9]*\).*#.*$|\1|"`
sed -i -e "s/^\(MARGIN_SLEEP=\).*$/\1${USER_INPUT}/" ${SH_SCRIPTS}

# chmod & move
chmod +x ${SLEEP_SCRIPT}
mv ${SLEEP_SCRIPT} ${SLEEP_PATH}

for s in ${PY_SCRIPTS}; do
	chmod +x ${s}
	mv ${s} ${BIN_PATH}
done

for s in ${SH_SCRIPTS}; do
	chmod +x ${s}
	mv ${s} ${BIN_PATH}
done

# ------------------------------------------------------- #

# variables: crond
CRON_FILE="/var/spool/cron/root"
CRON_LOG=""
#CRON_LOG="2>>/tmp/cron-err.log"
SLEEP_CMD="${SLEEP_CMD}"

# ------------------------------------------------------- #

# cron
echo "input the period of running cron (e.g., 15 [min.])"
read USER_INPUT
USER_INPUT=`echo ${USER_INPUT} | sed -e "s|\([0-9]*\).*#.*$|\1|"`
CRON_SCHEDULE="*/${USER_INPUT} * * * * "
CRON_JOB="${BIN_PATH}/${SH_SCRIPTS} ${CRON_LOG} && sleep 10 && ${SLEEP_CMD} ${CRON_LOG}"

if [ `grep "${CRON_JOB//\\/\\\\}" "${CRON_FILE}" | wc -l` -eq 0 ] ; then
	CRON_JOB="${CRON_SCHEDULE}${CRON_JOB}"
	echo "${CRON_JOB}" >> "${CRON_FILE}"
else
	sed -i -e "s|^.*\(${CRON_JOB}\)$|${CRON_SCHEDULE}\1|" ${CRON_FILE}
fi

#/etc/init.d/crond restart
systemctl restart crond

exit 0
