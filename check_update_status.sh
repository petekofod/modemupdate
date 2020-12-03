#!/bin/bash

MODEM_IP="$1"
MODEM_URL="$2"
VERSION="$3"

echo ${MODEM_IP}
echo ${MODEM_URL}
echo ${VERSION}

curl -k ${MODEM_URL} > lp.${MODEM_IP}.txt
MODEM_VERSION=$(grep 'Version.* | Copyright' lp.${MODEM_IP}.txt | sed 's/.*Version //; s/ | Copyright.*//')
echo ${MODEM_VERSION} | grep -q $VERSION

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
echo ${MODEM_VERSION} > ver.${MODEM_IP}.txt
exit 5
