#!/bin/bash

list=$1
SSH_KEY=/home/railwaynet/.ssh/id_rsa_rwn

get_ssh_connect_status() {
  </dev/null ssh -q -i ${SSH_KEY}  ${MPLS_INTERFACE_SSH} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p ${MODEM_SSH_PORT}  -o ConnectTimeout=3 -o ConnectionAttempts=1 ${MODEM_SSH_USER}@${MODEM_SSH_ADDR} "echo" 2>> log.txt
  return $?
}

t_now=`date +%Y%m%d.%H:%M:%S`
report_file_name=report_${t_now}.txt
echo "$report_file_name"

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

  MODEM_LOGIN=${modem[4]%\"}
  MODEM_LOGIN=${MODEM_LOGIN#\"}

  MODEM_PASSWORD=${modem[5]%\"}
  MODEM_PASSWORD=${MODEM_PASSWORD#\"}

  MPLS_INTERFACE_SSH=""
  MPLS_INTERFACE_SCP=""
  MPLS_INTERFACE="Verizon"

  if [[ "${MODEM_SSH_ADDR}" == *".149."* ]]; then
      MPLS_INTERFACE_SSH=" -b 10.102.10.37 "
      MPLS_INTERFACE_SCP=" -o BindAddress=10.102.10.37 "
      MPLS_INTERFACE="ATT"
  fi


  echo
  echo "***********************************************************************************************************"
  echo
  echo MODEM_SSH_ADDR=${MODEM_SSH_ADDR}
  echo MODEM_SSH_PORT=${MODEM_SSH_PORT}
  echo MODEM_SSH_USER=${MODEM_SSH_USER}
  echo MODEM_SSH_PASS=${MODEM_SSH_PASS}
  echo
  echo MODEM_LOGIN=${MODEM_LOGIN}
  echo MODEM_PASSWORD=${MODEM_PASSWORD}
  echo
  echo SSH_INTERFACE=${MPLS_INTERFACE_SSH}
  echo SCP_INTERFACE=${MPLS_INTERFACE_SCP}

  #Try to connect to internal host
  get_ssh_connect_status
  if [[ $? -ne 0 ]]
  then
          msg="${MODEM_SSH_ADDR} : SSH connection broken."
          echo ${msg}
          echo ${msg} >> ${report_file_name}
          continue
  fi

  echo >> "${report_file_name}"
  echo >> "${report_file_name}"
  echo >> "${report_file_name}"

  </dev/null  scp -q -o StrictHostKeyChecking=no -i ${SSH_KEY} ${MPLS_INTERFACE_SCP} -o UserKnownHostsFile=/dev/null -P ${MODEM_SSH_PORT} modem_info.sh ${MODEM_SSH_USER}@${MODEM_SSH_ADDR}:/tmp/

  #for MODEM_IP in "192.168.13.31" "192.168.13.31"
  for MODEM_IP in "10.255.255.248" "10.255.255.249"
  do
      echo
      MODEM_URL="http://"${MODEM_IP}":9191"
      echo "${MODEM_SSH_ADDR}/${MODEM_IP}" >> "${report_file_name}"
      </dev/null ssh -q -o StrictHostKeyChecking=no -i ${SSH_KEY} ${MPLS_INTERFACE_SSH} -o UserKnownHostsFile=/dev/null -p ${MODEM_SSH_PORT} ${MODEM_SSH_USER}@${MODEM_SSH_ADDR} \
      "/tmp/modem_info.sh" ${MODEM_URL} ${MODEM_LOGIN} ${MODEM_PASSWORD} >> "${report_file_name}"
  done

done <"${list}"
