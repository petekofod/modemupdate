#!/bin/bash

MODEM_URL="$1"
MODEM_LOGIN="$2"
MODEM_PASSWORD="$3"

echo ${MODEM_URL}
echo ${MODEM_LOGIN}
echo ${MODEM_PASSWORD}

lbl[4]="ALEOS Software Version"
lbl[7]="Device Model"
lbl[8]="Radio Firmware Version"
lbl[9]="Radio Module Type"
lbl[11220]="Radio Module Identifier"

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

#curl -k  -b coo  ${MODEM_URL}/admin/rm_switching_list.cgi

echo
echo
echo

for i in 7 4 11220 9 8
do
	val=$(curl -s -k -b coo -X POST -H "Content-Type: text/plain" -q --data ${i}\
   	${MODEM_URL}/cgi-bin/Embedded_Ace_Get_Task.cgi)
	val=${val#"${i}="}
	val=${val%"!"}
echo ${lbl[i]}: $val

done
echo
exit 0

