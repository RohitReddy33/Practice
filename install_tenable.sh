#!/bin/bash
# script TenableInstaller.sh, unattended installation of Tenable

set -xv

# script must be run as root
echo " Start installation "
echo " - check if script is start with root account ... "
if [ "`id | sed 's/uid=\([0-9]*\).*/\1/'`" -ne 0 ] ; then
    echo "Must be root to run."
    exit 1
fi


if [[ -z "${SSM_LINKING_KEY}" ]]; then
    SSM_LINKING_KEY="ef01d5dc8741f8641194f35458ec190f0dd22439b0b64b546ac4a4d1bd991d08"
fi
if [[ -z "${SSM_AGENT_NAME}" ]]; then
    SSM_AGENT_NAME="$(hostname)"
fi
if [[ -z "${SSM_AGENT_GROUP}" ]]; then
    SSM_AGENT_GROUP='OneCloud'
fi

startcmd="systemctl start nessusagent"
CONFIGURATION='{"link":{"host":"cloud.tenable.com","port":443,"key":'\""$SSM_LINKING_KEY"\"',"name":'\""$SSM_AGENT_NAME"\"',"groups":['\""$SSM_AGENT_GROUP"\"']}}'
SERVER='cloud.tenable.com:443'


is_64_bit=0
if [[ $(getconf LONG_BIT) -eq "64" ]]; then
  is_64_bit=1
fi


echo "Applying auto-configuration."
echo $CONFIGURATION >/opt/nessus_agent/var/nessus/config.json

echo "Starting Nessus Agent."
output=$($startcmd 2>&1)

echo "Waiting for Nessus Agent to start and link..."
EFFECTIVE_CF=/opt/nessus_agent/var/nessus/.autoconfigure.json
ACF_ERRORS=/opt/nessus_agent/var/nessus/.autoconfigure.error
NESSUSCLI=/opt/nessus_agent/sbin/nessuscli

retries=10
tries=0
COMPLETE=0
ERRORS=0
while [ "$tries" -lt "$retries" ]; do
    if [ -e "$EFFECTIVE_CF" ]; then
        echo
        echo "Auto-configuration complete."
        COMPLETE=1
        break
    fi

    echo -n "."
    tries=$(($tries + 1))
    sleep 10
done

if [ -e "$ACF_ERRORS" ]; then
    ERRORS=1
fi

$NESSUSCLI fix --secure --get ms_server_ip 2>&1 1>/dev/null
RC=$?

if [ "$RC" -eq "0" ]; then
    echo "The Nessus Agent is now linked to $SERVER"
	${NESSUSCLI} agent status
else
    echo "The Nessus Agent may have failed to link to $SERVER"
fi

if [ -e "$ACF_ERRORS" ]; then
    echo "There were errors during the autoconfiguration process: "
    cat $ACF_ERRORS
    echo
fi

# exit