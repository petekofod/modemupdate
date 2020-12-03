#!/bin/bash

get_ssh_connect_status() {
  </dev/null sshpass -p ${MODEM_SSH_PASS} ssh -q -o StrictHostKeyChecking=no -o PasswordAuthentication=yes -o UserKnownHostsFile=/dev/null -p ${MODEM_SSH_PORT}  -o ConnectTimeout=3 -o ConnectionAttempts=1 ${MODEM_SSH_USER}@${MODEM_SSH_ADDR} "echo" 2>> log.txt
  return $?
}

sshpass -V > log.txt

update_modems=true
if [[ $@ == *"-no-update"* ]]; then
    update_modems=false
fi

t_now=`date +%Y%m%d.%H:%M:%S`
report_file_name=report_${t_now}.txt
report_not_updated=modems_not_updated_${t_now}.txt

echo "**********************************************************" > ${report_file_name}
if ${update_modems}
then
    echo "***************** UPDATING MODEMS REPORT *****************" >> ${report_file_name}
else
    echo "***************** CHECKING SW VERSIONS REPORT ************" >> ${report_file_name}
fi
echo "**********************************************************" >> ${report_file_name}

while read line; do

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
        msg="${MODEM_SSH_ADDR}/${MODEM_IP} : SSH connection broken."
        echo ${msg}
        echo ${msg} >> ${report_file_name}
	continue
fi

</dev/null sshpass -p ${MODEM_SSH_PASS} scp -q -o StrictHostKeyChecking=no -o PasswordAuthentication=yes -o UserKnownHostsFile=/dev/null -P ${MODEM_SSH_PORT} check_update_status.sh ${MODEM_SSH_USER}@${MODEM_SSH_ADDR}:/tmp/

update_failed=true

if ${update_modems}
then
    echo "Copy firmware ${FILE_NAME} and updater for modem ${MODEM_URL}"
    echo
    </dev/null sshpass -p ${MODEM_SSH_PASS} ssh -q -o StrictHostKeyChecking=no -o PasswordAuthentication=yes -o UserKnownHostsFile=/dev/null -p ${MODEM_SSH_PORT} ${MODEM_SSH_USER}@${MODEM_SSH_ADDR} "ls /tmp/${FILE_NAME}" 2>/dev/null
    if [[ $? -ne 0 ]]
    then
        </dev/null sshpass -p ${MODEM_SSH_PASS} scp -q -o StrictHostKeyChecking=no -o PasswordAuthentication=yes -o UserKnownHostsFile=/dev/null -P ${MODEM_SSH_PORT} ${FILE_NAME} ${MODEM_SSH_USER}@${MODEM_SSH_ADDR}:/tmp/
    fi
    </dev/null sshpass -p ${MODEM_SSH_PASS} scp -q -o StrictHostKeyChecking=no -o PasswordAuthentication=yes -o UserKnownHostsFile=/dev/null -P ${MODEM_SSH_PORT} update.sh ${MODEM_SSH_USER}@${MODEM_SSH_ADDR}:/tmp/
    echo "Copied"

    echo
    echo "Run update"
    </dev/null sshpass -p ${MODEM_SSH_PASS} ssh -q -o StrictHostKeyChecking=no -o PasswordAuthentication=yes -o UserKnownHostsFile=/dev/null -p ${MODEM_SSH_PORT} ${MODEM_SSH_USER}@${MODEM_SSH_ADDR} \
        "/tmp/update.sh ${MODEM_IP} ${MODEM_URL} ${MODEM_LOGIN} ${MODEM_PASSWORD} /tmp/${FILE_NAME} > /tmp/log.${MODEM_IP}.txt"

    if [[ $? -ne 0 ]]
    then
            echo
            echo
            msg="${MODEM_SSH_ADDR}/${MODEM_IP} : MODEM UPDATE FAILED"
            echo ${msg}
            echo ${msg} >> ${report_file_name}
            echo
        continue
    fi

    sleep 300

    i=0
    while [ $i -le 100 ]
    do
        get_ssh_connect_status
        if [[ $? -eq 0 ]]
        then
          echo
          echo "Check update status"
          </dev/null sshpass -p ${MODEM_SSH_PASS} ssh -q -o StrictHostKeyChecking=no -o PasswordAuthentication=yes -o UserKnownHostsFile=/dev/null -p ${MODEM_SSH_PORT} ${MODEM_SSH_USER}@${MODEM_SSH_ADDR} \
                  "/tmp/check_update_status.sh ${MODEM_IP} ${MODEM_URL} ${VERSION} >> /tmp/log.${MODEM_IP}.txt"

          if [[ $? -eq 0 ]]
          then
            update_failed=false
            echo
            echo
            msg="${MODEM_SSH_ADDR}/${MODEM_IP} : MODEM SUCCESSFULLY UPDATED"
            echo ${msg}
            echo ${msg} >> ${report_file_name}
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
        msg="${MODEM_SSH_ADDR}/${MODEM_IP} : MODEM UPDATE FAILED"
        echo ${msg}
        echo ${msg} >> ${report_file_name}
        echo
    fi
else
    echo
    echo "Check version"
    </dev/null sshpass -p ${MODEM_SSH_PASS} ssh -q -o StrictHostKeyChecking=no -o PasswordAuthentication=yes -o UserKnownHostsFile=/dev/null -p ${MODEM_SSH_PORT} ${MODEM_SSH_USER}@${MODEM_SSH_ADDR} \
      "/tmp/check_update_status.sh ${MODEM_IP} ${MODEM_URL} ${VERSION} >> /tmp/log.${MODEM_IP}.txt"

    if [[ $? -eq 0 ]]
    then
        msg="${MODEM_SSH_ADDR}/${MODEM_IP} : MODEM SUCCESSFULLY UPDATED"
    else
        </dev/null sshpass -p ${MODEM_SSH_PASS} scp -q -o StrictHostKeyChecking=no -o PasswordAuthentication=yes -o UserKnownHostsFile=/dev/null -P ${MODEM_SSH_PORT} ${MODEM_SSH_USER}@${MODEM_SSH_ADDR}:~/ver.${MODEM_IP}.txt ver.${MODEM_SSH_ADDR}_${MODEM_IP}.txt
        </dev/null sshpass -p ${MODEM_SSH_PASS} scp -q -o StrictHostKeyChecking=no -o PasswordAuthentication=yes -o UserKnownHostsFile=/dev/null -P ${MODEM_SSH_PORT} ${MODEM_SSH_USER}@${MODEM_SSH_ADDR}:~/lp.${MODEM_IP}.txt lp.${MODEM_SSH_ADDR}_${MODEM_IP}.txt
        MODEM_VERSION=$(cat ver.${MODEM_SSH_ADDR}_${MODEM_IP}.txt)
        [[ -z "${MODEM_VERSION}" ]] && MODEM_VERSION="NOT FOUND"
        msg="${MODEM_SSH_ADDR}/${MODEM_IP} : MODEM UPDATE FAILED : SW VERSION \"${MODEM_VERSION}\" DOES NOT MATCH \""${VERSION}"\""
        echo "${MODEM_SSH_ADDR}/${MODEM_IP} : ${MODEM_VERSION}" >> ${report_not_updated}
    fi

    echo
    echo
    echo ${msg}
    echo ${msg} >> ${report_file_name}
    echo
fi
done <list.txt

