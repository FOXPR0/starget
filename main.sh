#!/bin/bash
while true
do
OPTION=$(whiptail --title "Test Menu Dialog" --menu "Choose your option" 15 45 6 \
"SYSTEM" "INFO" \
"RAID" " " \
"LVM" " " \
"BACKUP" " " \
"NAS" " " \
"QUOTA" " " \
"TROUBLESHOOT" " " 3>&1 1>&2 2>&3)
 
exitstatus=$?
if [ $exitstatus = 0 ]; then
    ./${OPTION}.sh
else
	break
    
fi

done
exit

