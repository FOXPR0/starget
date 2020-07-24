#!/bin/bash
## this fn fsmenu get mounted fs list
function fsmenu()
{
	#gather currently mounted partition list
	partlist=`grep ^/ /proc/mounts | awk '{print $1 " " $3}'`
	whiptail --title "Select Filesystem to apply quota" --menu "Choose Option" 25 78 16 $partlist 3>&1 1>&2 2>&3
}


### this fn get fs list from fstab
function fstab_menu()
{
	if [ $1 == "u" ]
	
	then
		##Search for usrquota options in fstab file
		fsinfstab=`grep -vE '^#| +#' /etc/fstab | grep -w usrquota | awk '{print $1 " " $2 }'` 
			
	else
	 	##Search for grpquota options in fstab file
		fsinfstab=`grep -vE '^#| +#' /etc/fstab | grep -w grpquota | awk '{print $1 " " $2}'`
	
	fi
	whiptail --title "Select Filesystem to Limits QUOTA for a specific user" --menu "Choose Option" 25 78 16 $fsinfstab 3>&1 1>&2 2>&3
}

# Apply is the fn which provide Quota to file system

Apply()
{

#### ISSUE WITH SED CMMND WIHILE SELECING GRPQUOTA
#### issue for duplicate entry if user quota alredy applied and the we are applying grp quota


flag=1


while [ $flag -eq 1 ]
do
	fschoice=`fsmenu`
	
	if [ $? -eq 1 ]
	then
		exit
	fi
	
	grep $fschoice /proc/mounts | awk '{print $3}' | grep ext &>/dev/null

	if [ ! $? -eq 0 ]
	then
		whiptail --msgbox "Quota Not Supported on Selected file system, This utility current supports only ext file systems" 8 78
		continue
	fi
	
	flag=0
done


whiptail --yes-button "User Quota" --no-button "Group Quota" --yesno "Select Quota Type to Apply" 7 60

if [ $? -eq 0 ]
then
	#User quota selected
	qtype="usrquota"
else
	#group quota selected
	qtype="grpquota"
fi


grep -vE '^#| +#' /etc/fstab | grep -w $fschoice &>/dev/null

if [ $? -eq 0 ]
then
	#file system entry exist
	#check if quota is already enabled
	grep -vE '^#| +#' /etc/fstab | grep -w $fschoice | grep $qtype &>/dev/null
	
	if [ ! $? -eq 0 ]
	then
		#qtype needs to be added
		odeventry=`grep -vE '^#| +#' /etc/fstab | grep -w $fschoice`
		linenum=`grep -vnE '^#| +#' /etc/fstab | grep -w $fschoice | cut -d':' -f1`
		
		sed -i "${linenum}s/.*/#&/" /etc/fstab
		
		echo "$odeventry" | awk -v "qtype=$qtype" '{print $1 " " $2 " " $3 " " $4","qtype " " $5 " " $6}' >>/etc/fstab
		
	fi	
	
else
	#create a file system entry in fstab
	#extract data from /etc/mtab
	
	#check current mounted with qtype in mtab
	grep -w $fschoice /etc/mtab | grep $qtype &>/dev/null
	
	if [ $? -eq 0 ]
	then
		grep -w $fschoice /etc/mtab >>/etc/fstab
	else
		grep -w $fschoice /etc/mtab | awk -v "qtype=$qtype" '{print $1 " " $2 " " $3 " " $4","qtype " " $5 " " $6}' >>/etc/fstab
	fi
	
fi


mount -o remount $fschoice

quotaoff -vug $fschoice &> /dev/null ## recheck please
quotacheck -mcvug $fschoice &> /dev/null

quotaon -vug $fschoice &>/dev/null

}

### Provide fn is use to provide quota limits to the users
Provide()
{

	if (whiptail --yes-button "User" --no-button "Group"  --yesno "On Which Quota you want to apply?" 7 70) then
		if (grep -v '^#| +#' /etc/fstab | grep 'usrquota' >> /dev/null)then
		user_group=u
		else
			whiptail --title "No File System available" --msgbox "Please Apply Quota to File System " 10 60
			 exit
		fi
	else
		if (grep -v '^#| +#' /etc/fstab | grep 'grpquota' >> /dev/null)then
		user_group=g
		else
			whiptail --title "No File System available" --msgbox "Please Apply Quota to File System " 10 60
			 exit
		fi
	fi
	
	q_path=`fstab_menu $user_group`
	
	#Confirm FS
	whiptail --title "Confirm" --msgbox "  $q_path selected  " 10 60
	
	#Select User
	q_user=$(whiptail --title "Apply Qouta To the User Or Group" --inputbox "Enter the Username" 7 50  3>&1 1>&2 2>&3)

	if (whiptail --yes-button "Block Limits" --no-button "File OR Inode Limits"  --yesno "Which Quota you want to apply?" 7 70) then
		q_choice=b
	else
		q_choice=i
	fi

	soft_limit=$(whiptail --inputbox "Enter the Soft Limit" 7 60  3>&1 1>&2 2>&3)
	hard_limit=$(whiptail --inputbox "Enter the Hard Limit" 7 60  3>&1 1>&2 2>&3)

	quotatool -$user_group $q_user -$q_choice -q $soft_limit -l $hard_limit $q_path
}

function Display()
{
whiptail --title "Logical Volumes" --msgbox "$(repquota -avug)" 40 78
}
	


### MAIN FN () #####
#######################
while true
do
q_OPTION=$(whiptail --backtitle "bla bla bla" --title "Test Menu Dialog" --menu "Choose your option" 15 45 4 \
"Apply" "Quota To File System " \
"Display" "All User and Group Quota " \
"Provide" "Quota Limits To User Or group "  3>&1 1>&2 2>&3)
 
exitstatus=$?
if [ $exitstatus = 0 ]; then
    ${q_OPTION}
else
	break
    exit
fi

done
