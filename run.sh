#!/bin/bash

get_ssh_connect_status() {
  </dev/null sshpass -p ${MODEM_SSH_PASS} ssh -vvv -o StrictHostKeyChecking=no -p ${MODEM_SSH_PORT}  -o ConnectTimeout=3 -o ConnectionAttempts=1 ${MODEM_SSH_USER}@${MODEM_SSH_ADDR} "echo" 2>> log.txt
  return $?
}

sshpass -V > log.txt

echo "**********************************************************" > report.txt
echo "***************** UPDATING MODEMS REPORT *****************" >> report.txt
echo "**********************************************************" >> report.txt

while read line; do

update_failed=true

modem=( $line )

MODEM_SSH_ADDR=${modem[0]%\"}
MODEM_SSH_ADDR=${MODEM_SSH_ADDR#\"}

MODEM_SSH_PORT=${modem[1]%\"}
MODEM_SSH_PORT=${MODEM_SSH_PORT#\"}

MODEM_SSH_USER=${modem[2]%\"}
MODEM_SSH_USER=${MODEM_SSH_USER#\"}

MODEM_SSH_PASS=${modem[3]%\"}
MODEM_SSH_PASS=${MODEM_SSH_PASS#\"}

MODEM_IP=${modem[4]%\"}
MODEM_IP=${MODEM_IP#\"}

MODEM_URL=${modem[5]%\"}
MODEM_URL=${MODEM_URL#\"}

MODEM_LOGIN=${modem[6]%\"}
MODEM_LOGIN=${MODEM_LOGIN#\"}

MODEM_PASSWORD=${modem[7]%\"}
MODEM_PASSWORD=${MODEM_PASSWORD#\"}

FILE_NAME=${modem[8]%\"}
FILE_NAME=${FILE_NAME#\"}

VERSION=${modem[9]%\"}
VERSION=${VERSION#\"}
echo
echo "***********************************************************************************************************"
echo
echo MODEM_SSH_ADDR=${MODEM_SSH_ADDR}
echo MODEM_SSH_PORT=${MODEM_SSH_PORT}
echo MODEM_SSH_USER=${MODEM_SSH_USER}
echo MODEM_SSH_PASS=${MODEM_SSH_PASS}
echo
echo MODEM_IP=${MODEM_IP}
echo MODEM_URL=${MODEM_URL}
echo MODEM_LOGIN=${MODEM_LOGIN}
echo MODEM_PASSWORD=${MODEM_PASSWORD}
echo FILE_NAME=${FILE_NAME}
echo VERSION=${VERSION}
echo

#Try to connect to internal host
get_ssh_connect_status
if [[ $? -ne 0 ]]
then
        echo "${MODEM_SSH_ADDR}/${MODEM_IP} MODEM UPDATE FAILED. SSH connection broken."
        echo "${MODEM_SSH_ADDR}/${MODEM_IP} MODEM UPDATE FAILED. SSH connection broken." >> report.txt
	continue
fi

echo "Copy firmware ${FILE_NAME} and updater for modem ${MODEM_URL}"
echo
</dev/null sshpass -p ${MODEM_SSH_PASS} ssh -o StrictHostKeyChecking=no -p ${MODEM_SSH_PORT} ${MODEM_SSH_USER}@${MODEM_SSH_ADDR} "ls /tmp/${FILE_NAME}" 2>/dev/null
if [[ $? -ne 0 ]]
then
    </dev/null sshpass -p ${MODEM_SSH_PASS} scp -o StrictHostKeyChecking=no -P ${MODEM_SSH_PORT} ${FILE_NAME} ${MODEM_SSH_USER}@${MODEM_SSH_ADDR}:/tmp/
fi
</dev/null sshpass -p ${MODEM_SSH_PASS} scp -o StrictHostKeyChecking=no -P ${MODEM_SSH_PORT} update.sh ${MODEM_SSH_USER}@${MODEM_SSH_ADDR}:/tmp/
</dev/null sshpass -p ${MODEM_SSH_PASS} scp -o StrictHostKeyChecking=no -P ${MODEM_SSH_PORT} check_update_status.sh ${MODEM_SSH_USER}@${MODEM_SSH_ADDR}:/tmp/
echo "Copied"

echo
echo "Run update"
</dev/null sshpass -p ${MODEM_SSH_PASS} ssh -o StrictHostKeyChecking=no -p ${MODEM_SSH_PORT} ${MODEM_SSH_USER}@${MODEM_SSH_ADDR} \
	"/tmp/update.sh ${MODEM_IP} ${MODEM_URL} ${MODEM_LOGIN} ${MODEM_PASSWORD} /tmp/${FILE_NAME} > /tmp/log.${MODEM_IP}.txt"

if [[ $? -ne 0 ]]
then
        echo
        echo
        echo "${MODEM_SSH_ADDR}/${MODEM_IP} MODEM UPDATE FAILED"
        echo "${MODEM_SSH_ADDR}/${MODEM_IP} MODEM UPDATE FAILED" >> report.txt
        echo
	continue
fi

sleep 240

i=0
while [ $i -le 100 ]
do
    get_ssh_connect_status
    if [[ $? -eq 0 ]]
    then
	echo
	echo "Check update status"
	</dev/null sshpass -p ${MODEM_SSH_PASS} ssh -o StrictHostKeyChecking=no -p ${MODEM_SSH_PORT} ${MODEM_SSH_USER}@${MODEM_SSH_ADDR} \
        	"/tmp/check_update_status.sh ${MODEM_IP} ${MODEM_URL} ${VERSION} >> /tmp/log.${MODEM_IP}.txt"

	if [[ $? -eq 0 ]]
	then
		update_failed=false
		echo
		echo
		echo "${MODEM_SSH_ADDR}/${MODEM_IP} MODEM SUCCESSFULLY UPDATED"
                echo "${MODEM_SSH_ADDR}/${MODEM_IP} MODEM SUCCESSFULLY UPDATED" >> report.txt
		echo
	fi
        break
    fi

    (( i++ ))
done

if ${update_failed}
then
	echo
	echo
	echo "${MODEM_SSH_ADDR}/${MODEM_IP} MODEM UPDATE FAILED"
        echo "${MODEM_SSH_ADDR}/${MODEM_IP} MODEM UPDATE FAILED" >> report.txt
	echo
fi
done <list.txt
