#!/bin/bash

MODEM_IP="$1"
MODEM_URL="$2"
VERSION="$3"

echo ${MODEM_IP}
echo ${MODEM_URL}
echo ${VERSION}

curl --connect-timeout 3 -k -s ${MODEM_URL} | grep -q $VERSION

if [[ $? -eq 0 ]]
then
  echo
  echo
  echo "SUCCESSFULLY UPDATED"
  echo "" >> log.${MODEM_IP}.txt
  echo "*******************************************************************************" >> log.${MODEM_IP}.txt
  echo "SUCCESSFULLY UPDATED" >> log.${MODEM_IP}.txt
  exit 0
fi

echo
echo
echo "UPDATE ERROR"
echo "" >> log.${MODEM_IP}.txt
echo "*******************************************************************************" >> log.${MODEM_IP}.txt
echo "UPDATE ERROR" >> log.${MODEM_IP}.txt
exit 5
