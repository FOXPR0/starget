#!/bin/bash

Complete()
{
	./completebk.sh	
 
}

Incremental()
{
	./increment.sh
}

Differential()
{
	./differential.sh
}


Choice=$(whiptail --title "Test Menu Dialog" --menu "Choose your option" 15 45 3 \
"Complete" " " \
"Incremental" " " \
"Differential" " " 3>&1 1>&2 2>&3)
 
exitstatus=$?
if [ $exitstatus = 0 ]; then
    echo "Your chosen option:" $Choice
    $Choice
else
    . ./main.sh
fi

