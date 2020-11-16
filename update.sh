#!/bin/bash

MODEM_IP="$1"
MODEM_URL="$2"
MODEM_LOGIN="$3"
MODEM_PASSWORD="$4"
FILE_NAME="$5"

echo ${MODEM_IP}
echo ${MODEM_URL}
echo ${MODEM_LOGIN}
echo ${MODEM_PASSWORD}
echo ${FILE_NAME}

get_status() {
  local status=$(curl -s -b coo ${MODEM_URL}/admin/fw_status.cgi)

  echo ${status}
}
echo

resp=$(curl -s -c coo -q --data "<request xmlns=\"urn:ace-c manager\"><connect><login>${MODEM_LOGIN}</login><password>${MODEM_PASSWORD}</password></connect></request>" ${MODEM_URL}/xml/Connect.xml)

echo
echo ${resp} | grep "message='OK'"

if [[ $? -eq 0 ]]
then
	echo
	echo
	echo "MODEM SUCCESSFULLY CONNECTED"
	echo
else
	echo
        echo
        echo "CONNECTION BROKEN STEP: STOP UPDATING: ERROR"
        exit 7
fi

echo

statSetTask=$(curl -s -b coo \
  -F "11151=1" \
   ${MODEM_URL}/cgi-bin/Embedded_Ace_Set_Task.cgi)

echo
echo
echo Set Task Status: $statSetTask
echo
echo Initialization
echo

statUploadInit=$(curl -s -b coo \
  -F "var=1" \
   ${MODEM_URL}/admin/fw_upload_init.cgi)

echo  "$statUploadInit"
if [[ "$statUploadInit" == *"OK" ]]
then
    echo "Initialization. Continue..."
else
    echo "UPLOAD Initialization STEP: STOP UPDATING: ERROR"
    exit 1
fi
echo
i=0
while [ $i -le 17 ]
do
        status="$(get_status)"
        echo $status
        if [[ "$status" == *"ERR:"* ]]
        then
            echo "UPLOAD Initialization STEP: STOP UPDATING: ERROR"
            exit 2
        fi
        if [[ "$status" == *"DONE"* ]]
        then
            echo "Initialization done. Continue..."
            break
        fi
        (( i++ ))
done

echo
echo
echo Uploading
echo

upload=$(curl -s -b coo \
  -F "action=fw_upload" \
  -F "go=Update" \
  -F "image=@${FILE_NAME}" \
   ${MODEM_URL}/html/UpdateFirmware.html)

echo
echo

i=0
while [ $i -le 17 ]
do
        status="$(get_status)"
        echo $status
        if [[ "$status" == *"ERR:"* ]]
        then
            echo "Uploading STEP: STOP UPDATING: ERROR"
            exit 3
        fi
        if [[ "$status" == *"DONE"* ]]
        then
            echo "Uploading step done. Continue..."
            break
        fi
        (( i++ ))
done

echo
echo
echo Applying 
echo

update=$(curl -s -b coo \
  -F "action=rm_skip" \
  -F "go=Update" \
   ${MODEM_URL}/html/UpdateFirmware.html)

echo
echo

i=0
while [ $i -le 17 ]
do 
        status="$(get_status)"
        echo $status
        if [[ "$status" == *"DONE"* ]] || [[ "$status" == *"Rebooting"* ]] || [[ "$status" == *"TERM"* ]] || [[ "$status" == "" ]]
        then
	    echo
	    date
	    echo
	    echo
	    echo "Applying step done. Rebooting..."
	    echo
            exit 0
        fi
	(( i++ ))
done


echo
date
echo
echo
echo "Applying step STEP: STOP UPDATING: ERROR"
echo
exit 4
