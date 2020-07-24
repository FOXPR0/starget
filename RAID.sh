#!/bin/bash

function Create()
{
	raid_name=$(whiptail --title "Enter the name" --inputbox "Enter the name for raid" 10 60  3>&1 1>&2 2>&3)

	raid_level=$(whiptail --backtitle "bla bla bla" --title "Test Menu Dialog" --menu "Choose your option" 15 45 7 \
	"0" "Stripping" \
	"1" "Mirroring" \
	"4" "Dedicated parity disk" \
	"5" "Distributed parity" \
	"6" "Two Distributed Parity Blocks "  3>&1 1>&2 2>&3)
	 
	exitstatus=$?
	if [ ! $exitstatus = 0 ]; then
	   	exit
		./RAID.sh
	fi


	
	#get all raid made pvs
	fdisk -l | grep raid | awk '{print $1}' >/tmp/raiddisk.$$
	##if no raid made pvs found then quit or give create 


	#get all used raid pvs
	lsblk -lp | grep -B 1 -i raid | grep -vE 'raid|\-' | awk '{print $1}' >/tmp/useddisk.$$

	x=$(echo $(cat /tmp/useddisk.$$) | tr ' ' '|')


	if [ ! -z "$x" ]
	then
		device_list=$(cat /tmp/raiddisk.$$ | grep -vwE "$x")
	else
		device_list=$(cat /tmp/raiddisk.$$)
	fi

	while read line
	do
		echo $line $(lsblk -lp |grep -wE $line | awk '{print $4}') OFF >>/tmp/chklist.$$
	done <<<"${device_list}" 
	#above line read variable as a file and provide it to loop

	chk_lists=$(whiptail --title "Device Menu" --checklist "Select Devices to Add"  20 78 4 $(cat /tmp/chklist.$$) 3>&1 1>&2 2>&3)

	disk_count=`echo $chk_lists | sed 's/"//g' | wc -w`

	chk_lists=`echo $(echo $chk_lists | tr -s '"' ' ' )`
	####
	yes | mdadm --create $raid_name --level $raid_level --raid-devices $disk_count $chk_lists  &> /dev/null
	
	mdadm --detail --scan >> /etc/mdadm.conf
	
	

}

function Remove()
{
	raid_all=`cat /etc/mdadm.conf | awk '{print $2 " " $1}'`
    if [ -z "$raid_all" ]
			then
			whiptail --title "Error" --msgbox "No RAID Device Found" 10 60
	else
	
		raid_disk=$(whiptail --title "Select The Raid Device" --menu "Select the RAID device to remove" 25 78 16 $raid_all 3>&1 1>&2 2>&3)

		device_no=`mdadm --detail $raid_disk | grep "Total Devices" | awk '{print $4}'`
		disk_used=$(mdadm --detail $raid_disk | tail -$device_no | awk '{print $7}')
	


		mdadm --stop $raid_disk &> /dev/null
		mdadm --remove $raid_disk &> /dev/null
	
		#use this cmd to edit mdam mdadm --detail /dev/md/md6 | tail -2 | awk '{print $7}'
		mdadm --zero-superblock $disk_used
	
		pattern=`basename $raid_disk`
		sed -i /$pattern/d /etc/mdadm.conf ##$pattern not working
	fi


	####
	#try to use UUID to remove u.. you will get different UUID by mdadm and os... by os u ll get from blkid and /dev/disk/by-uuid/ and using mdadm u ll get from mdadm --detail and /et/mdadm.conf and find out more.

	#####

}
r_OPTION=$(whiptail --backtitle "bla bla bla" --title "Test Menu Dialog" --menu "Choose your option" 15 45 2 \
"Create" "RAID Disk Array" \
"Remove" "RAID Disk Array"  3>&1 1>&2 2>&3)
 
exitstatus=$?
if [ $exitstatus = 0 ]; then
    ${r_OPTION}
else
    . ./main.sh
fi
