#!/bin/bash

MODEM_URL="$1"
MODEM_LOGIN="$2"
MODEM_PASSWORD="$3"

echo ${MODEM_URL}
echo ${MODEM_LOGIN}
echo ${MODEM_PASSWORD}

get_status() {
  local status=$(curl -b coo -k \
                -F "var=1" \
                ${MODEM_URL}/admin/fw_status.cgi)

  echo ${status}
}
echo

curl -c coo -k --data "<request xmlns=\"urn:ace-c manager\"><connect><login>${MODEM_LOGIN}</login><password>${MODEM_PASSWORD}</password></connect></request>" ${MODEM_URL}/xml/Connect.xml

echo
echo '**************************************************************************'
echo

#FILE_NAME=MC7354_05.05.58.00_ATT_005.026_000.iso
FILE_NAME=MC7354_05.05.58.05_VZW_005.032_000.iso

curl -s -k -b coo \
  -F "action=rmswi_install" \
  -F "go=Update" \
  -F "image=@${FILE_NAME}" \
   ${MODEM_URL}/html/UpdateRmFw.html

echo $?
