#!/bin/bash

function mainmenu()
{
	local option
	option=$(whiptail --title "LVM Menu" --menu "Choose an Option" 25 78 16 "1" "List/Create PVs" "2" "List/Create VG's" "3" "List/Create LV's" "4" "Create Thin Pool" "5" "Create Thin LV's" 3>&1 1>&2 2>&3)
	
	if [ $? -eq 0 ]
	then
		echo $option
	else
		exit 2
	fi
}

function createpv()
{
	#echo "Create pv menu under construction"
	
	lsblk -Sp | sed 1d | grep -w disk | awk '{print $1}' >/tmp/lsdisk.$$
	
	while read line
	do
		fdisk -l | grep -wE "$line[0-9]+" &>/dev/null
		
		if [ ! $? -eq 0 ]
		then
			echo $line >>/tmp/lsdisk.new.$$
		fi
		
		fdisk -l | grep -wE "$line[0-9]+" | awk '{print $1}' >>/tmp/plist.$$
		
	done < /tmp/lsdisk.$$
	
	if [ -f /tmp/lsdisk.new.$$ ]
	then
		rm -f /tmp/lsdisk.$$
		mv /tmp/lsdisk.new.$$ /tmp/lsdisk.$$
	fi
	
	if [ -f /tmp/plist.$$ ]
	then
		cat /tmp/plist.$$ >>/tmp/lsdisk.$$
	fi
	
	while read line
	do
		mount | grep -w $line &>/dev/null
		
		if [ $? -eq 0 ]
		then
			continue
		fi
		
		pvs | grep -w $line &>/dev/null
		
		if [ $? -eq 0 ]
		then
			continue
		fi
		
		echo $line >>/tmp/lsdisk.new.$$
		
	done < /tmp/lsdisk.$$
	
	if [ -f /tmp/lsdisk.new.$$ ]
	then
		rm -f /tmp/lsdisk.$$
		mv /tmp/lsdisk.new.$$ /tmp/lsdisk.$$
	else
		>/tmp/lsdisk.$$
	fi
	
	if [ -z "$(cat /tmp/lsdisk.$$)" ]
	then
		whiptail --title "No Disk Found" --msgbox "No Unused Disk Found for creating LV. Manually scan For disk and or create partitions" 8 78
		rm -f /tmp/lsdisk.$$
	else
	
		while read line
		do
			echo $line $(lsblk $line | sed 1d | awk '{print $4}') OFF >>/tmp/lsdisk.new.$$
		done < /tmp/lsdisk.$$
		
		rm -f /tmp/lsdisk.$$
		
		mv /tmp/lsdisk.new.$$ /tmp/lsdisk.$$
		
		local pvlist
		pvlist=$(whiptail --title "Unused Disk/Partition List" --checklist \
		"Choose Disk/Partition to Mark as PV" 20 78 4 \
		$(echo $(cat /tmp/lsdisk.$$)) 3>&1 1>&2 2>&3)
		
		rm -f /tmp/*.$$
		
		pvlist=`echo $pvlist | sed 's/"//g'`
		echo "$pvlist"
		
		if [ ! -z "$pvlist" ]
		then
			pvcreate $pvlist
		fi
	fi
}

function listfreepv()
{
	vgs=`echo $(vgs | sed 1d | awk '{print $1}') | tr ' ' '|'`
	
	pvs | sed 1d | grep -vwE "$vgs" | awk '{print $1 " " $4}'
}

function vgmenu()
{
	#create vg
	#expand vg
	#reduce vg
	#delete vg
	
	local option
	
	option=$(whiptail --title "VG Menu" --menu "Choose an option" 25 78 16 \
	"1" "Create VG" \
	"2" "List VG" \
	"3" "Expand VG" 3>&1 1>&2 2>&3)
	
	if [ $option = 1 ]
	then
		freepvs=`listfreepv`
		
		if [ -z "$freepvs" ]
		then
			whiptail --title "No Free PV's" --msgbox "No Free PV found, goto PV Menu and create PV" 8 78
		else
			freepvs=`echo "$freepvs" | sed 's/$/ OFF/g'`
			
			local pvlist
			pvlist=$(whiptail --title "Free PV List" --checklist \
			"Choose PV to use in VG" 20 78 4 \
			$(echo $freepvs) 3>&1 1>&2 2>&3)
			
			if [ -z "$pvlist" ]
			then
				whiptail --title "No PV Selected" --msgbox "No PV selected, Aborting operation" 8 78
			else
				vgname=$(whiptail --inputbox "Enter the new VGName" 8 78 --title "Enter VG Name" 3>&1 1>&2 2>&3)
				
				if [ -z $vgname ]
				then
					whiptail --title "VG Name Empty" --msgbox "VG Name can not be emtpy, Aborting operation" 8 78
				else
					vgcreate $vgname $(echo $pvlist | sed 's/"//g')
				fi
			fi
			
		fi
	elif [ $option = 2 ]
	then
		vglist=`vgs | sed 1d | awk '{print $1 " " $6}'`
		
		if [ -z "$vglist" ]
		then
			whiptail --title "No VGs Found" --msgbox "No VG's Found, Nothing to display here" 8 78
		else
			whiptail --title "VG List" --msgbox "$vglist" 40 78
		fi
		
	elif [ $option = 3 ]
	then
		vglist=`vgs | sed 1d | awk '{print $1 " " $6}'`
		
		if [ -z "$vglist" ]
		then
			whiptail --title "No VGs Found" --msgbox "No VG's Found, Nothing to display here" 8 78
		else
			vgname=$(whiptail --title "Select VG" --menu "Choose VG Name" 25 78 16 $(echo $vglist) 3>&1 1>&2 2>&3)
			
			if [ $? -eq 0 ]
			then
				
				#find free pv list
				vgs=`echo $(vgs | sed 1d | awk '{print $1}') | tr ' ' '|'`
				
				freepvs=`pvs | sed 1d | grep -vwE "$vgs" | awk '{print $1 " " $4}'`
				
				if [ -z "$freepvs" ]
				then
					whiptail --title "No Free PV's" --msgbox "No Free PV's found, goto PV menu and create new PV" 8 78
				else
					freepvs=`echo "$freepvs" | sed 's/$/ OFF/g'`
					
					local pvlist
					pvlist=$(whiptail --title "Free PV List" --checklist \
					"Choose Free PVs to extend VG" 20 78 4 \
					$(echo $freepvs) 3>&1 1>&2 2>&3)
					
					if [ -z "$pvlist" ]
					then
						whiptail --title "No PV Selected" --msgbox "NO PV Selected for expanding, Aborting operation" 8 78
					else
					
						pvlist=`echo $pvlist | sed 's/"//g'`
						
						vgextend $vgname $pvlist
					fi
					
				fi
				
			fi
		fi
		
	fi
	
}

function pvmenu()
{
	echo "In pv menu"
	vgs=`echo $(vgs | sed 1d | awk '{print $1}') | tr ' ' '|'`
	freepvs=`pvs 2>/dev/null | sed 1d | grep -vE "$vgs" | awk '{print $1}'`
	pvs=`pvs 2>/dev/null | sed 1d | grep -E "$vgs" | awk '{print $1 " " $2}'`
	
	if [ ! -z "$freepvs" ]
	then
		freepvs=`echo "$freepvs" | sed 's/$/ FREE_PV/g'`
	fi
	
	local option
	option=$(whiptail --title "Pysical Volumes" --menu "Choose an Option" 25 78 16 \
	$pvs $freepvs "[ Create New ]" "PV" 3>&1 1>&2 2>&3)
	
	if [ $? -eq 0 ]
	then
		if [ "$option" = "[ Create New ]" ]
		then
			createpv
		fi
	fi
}

function lvmenu()
{
	local option
	
	option=$(whiptail --title "Logical Volumes" --menu "Choose an Option" 25 78 16 \
	"1" "Display LV's" \
	"2" "Create LV" 3>&1 1>&2 2>&3)
	
	if [ $? -eq 0 ]
	then
		if [ $option = 1 ]
		then
			lvs=`lvs | sed 1d | awk '{print "/dev/mapper/" $2 "-" $1 " " $4}'`
			
			if [ -z "$lvs" ]
			then
				whiptail --title "No LV Found" --msgbox "No Logical Volumes found, Nothing to display" 8 78
			else
				whiptail --title "Logical Volumes" --msgbox "$lvs" 40 78
			fi
		else
			vgs=`vgs | sed 1d | awk '{print $1 " " $6}'`
			
			if [ -z "$vgs" ]
			then
				msgbox --title "VG Not Found" --msgbox "No Volume groups found, Create Volume group from VG Menu" 8 78
			else
				vgname=$(whiptail --title "Volume Groups" --menu "Choose an Option" 25 78 16 \
				$vgs 3>&1 1>&2 2>&3)
				
				if [ $? -eq 0 ]
				then
					lvname=$(whiptail --title "Enter LV Name" --inputbox "Enter the name of logical volume" 8 78 3>&1 1>&2 2>&3)
					
					if [ -z "$lvname" ]
					then
						whiptail --title "LV Name Required" --msgbox "Logical Volume name is required, aborting operation" 8 78
					else
						lvsize=$(whiptail --title "Enter LV Size" --inputbox "Provide valid size with leading K for KB, M for MB, G for GB" 8 78 3>&1 1>&2 2>&3)
						
						if [ -z "$lvsize" ]
						then
							whiptail --title "Size Required" --msgbox "LV size is required, Aborting operation" 8 78
						else
							lvcreate -n $lvname -L $lvsize $vgname &>/tmp/lvcreate.$$
							whiptail --title "LV Create Result" --msgbox "$(cat /tmp/lvcreate.$$)" 40 78
						fi
					fi
					
				fi
			fi
			
		fi
	fi
}
function Thin_Pool()
{
	#display all available vgs
	vg_list=`vgs | sed 1d | awk '{print $1 " " "freesize:"$7}'`
	vg_select=$(whiptail --title "Select VG" --menu "Select VG in Which u want to creat Thin Pool" 25 78 16 $vg_list 3>&1 1>&2 2>&3)
	
	whiptail --title "Confirm" --msgbox "  $vg_select selected  " 10 60
	
	pool_name=$(whiptail --title "LV Create" --inputbox "Please Enter the Thin Pool  name" 10 60  3>&1 1>&2 2>&3)
	lv_poolsize=$(whiptail --title "Thin Pool" --inputbox "Please Enter the Thin LV Virtual Size" 10 60  3>&1 1>&2 2>&3)
	
	lvcreate -L $lv_poolsize -T $vg_select/$pool_name
}

###################################################

###################################################
function Thin_LV()
{

	#display all available thin pool 
	pool_list=`lvs | awk -F " " '{ print $3 " " $1 " " $2 }' | grep "^t" | awk '{print $3"/"$2 " " $2}'`
	pool_select=$(whiptail --title "Select The LV Pool i.e VG/LVPool" --menu "Choose LV Pool" 25 78 16 $pool_list 3>&1 1>&2 2>&3)
	
	whiptail --title "Confirm" --msgbox "  $pool_select selected  " 10 60
	
	thinlv_name=$(whiptail --title "LV Create" --inputbox "Please Enter the Thin LV  name" 10 60  3>&1 1>&2 2>&3)
	lv_virsize=$(whiptail --title "Thin Pool" --inputbox "Please Enter the Thin LV Virtual Size" 10 60  3>&1 1>&2 2>&3)

	lvcreate -V $lv_virsize -T $pool_select -n $thinlv_name

}

while true
do
		option=`mainmenu`
		
		if [ ! $? -eq 0 ]
		then
			break
		fi
		
		if [ $option = 1 ]
		then
			pvmenu
		elif [ $option = 2 ]
		then
			vgmenu
		elif [ $option = 4 ]
				then
			Thin_Pool
		elif [ $option = 5 ]
				then
			Thin_LV

		else
			lvmenu
		fi
done

