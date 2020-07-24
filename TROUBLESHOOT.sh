#!/bin/bash
OPTION=$(whiptail --title "Test Menu Dialog" --menu "Choose your option" 15 45 6 \
"PV" "METADATA RECOVERY " \
"LV" "RECOVERY " 3>&1 1>&2 2>&3)
 
exitstatus=$?
if [ $exitstatus = 0 ]; then
    ./${OPTION}.sh
else
	break
    
fi
