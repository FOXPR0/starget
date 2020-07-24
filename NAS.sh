## check for packages in main script
## for rpc and idmap mountd also





## for server side
function Share()
{
#Enter the source dir
 
flag=1
while [ $flag -eq 1 ]
do
	src_nfsdir=$(whiptail --title "Source Directory" --inputbox "Please Enter Absolute Path OF Directory You Want To Share On Network" 10 60  3>&1 1>&2 2>&3)
	
	if [ $? -eq 0 ]
	then	

		if [ ! -d $src_nfsdir ]
		then
			whiptail --msgbox "Directory not found" 8 78
			continue
		fi
	
		src_nfsdir=`echo $src_nfsdir | sed 's|/$||g'`
		awk '{print $1}' /etc/exports |grep -wE "$src_nfsdir|$src_nfsdir/" &> /dev/null
		#grep "$src_nfsdir " /etc/exports 
		if [ $? -eq 0 ]
		then
			whiptail --msgbox "Duplicate entry" 8 78
			continue
		
		fi
	
	

	else
    		
    		. ./NAS.sh  
	fi
	flag=0
done


#select the export options
nfs_options=$(whiptail --title "Choose the Options" --checklist \
"Select the permissions" 15 60 3 \
"sync" "Sync" ON \
"rw" "Read & Write" OFF \
"no_root_squash" "remote root users are able to change any file on the shared file system" OFF 3>&1 1>&2 2>&3)
 
exitstatus=$?
if [ $exitstatus = 0 ]; then

	
	nfsops=`echo $(echo $nfs_options | tr '"' ' ' ) | tr ' ' ','`
	
	echo $nfsops | grep -w "rw" &>/dev/null
	
	if [ ! $? -eq 0 ]
	then
		if [ -z "$nfsops" ]
		then
			nfsops="ro"
		else
			nfsops="ro,"$nfsops
		fi
	fi
	
	#if nfsops has no rw then append ro    
else
    
	return 1 
fi


#get the network
flag=1
while [ $flag -eq 1 ]
do

	des_network=$(whiptail --title "Network Address" --inputbox "Please Enter IP Address Or FQDN Of network" 10 60  3>&1 1>&2 2>&3)
	echo $des_network | grep -owE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' &>/dev/null
	if [ $? -ne 0 ]
	then
		whiptail --msgbox "Invalid IP address" 8 78
		continue
	fi

	flag=0
done

whiptail --title "Confirm" --msgbox " Note: You had selected $src_nfsdir " 10 60



whiptail --yes-button "Share" --no-button "Cancel" --yesno "$src_nfsdir will be shared on $des_network" 7 60

if [ $? -eq 0 ]
then

	echo "$src_nfsdir $des_network($nfsops)" >> /etc/exports
	exportfs -avr &> /dev/null
else
	exit	
fi
}


##for client side
function Mount()
{

flag=1
while [ $flag -eq 1 ]
do

	src_network=$(whiptail --title "Network Address" --inputbox "Please Enter IP Address Or FQDN Of network" 10 60  3>&1 1>&2 2>&3)
	exitstatus=$?
	
		
	if [ $exitstatus = 0 ]
		then

		echo $src_network | grep -owE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' &>/dev/null
		ipstatus=$?
		if [ $ipstatus -ne 0 ]
		then
		whiptail --msgbox "Invalid IP address" 8 78
		continue
		fi
		ping -c 1 -t 10 "$src_network" &> /dev/null
		ipstatus=$?
		if [ $ipstatus -ne 0 ]
		then
		whiptail --msgbox "Host unreacheable " 8 78
		continue
		fi
	
	else
    	echo "You mm chose Cancel."
		return  #### go back to main menu
	fi

	flag=0
done


shared_dir=`showmount -e $src_network | sed 1d|awk '{print $1 " " $2}'`
select_dir=$(whiptail --title "Select Dir" --menu "Select Shared Directory from network" 25 78 16 $shared_dir 3>&1 1>&2 2>&3)

flag=1
while [ $flag -eq 1 ]
do
	des_nfsdir=$(whiptail --title "Destination Directory" --inputbox "Please Enter Absolute Path OF Directory You Want To mount" 10 60  3>&1 1>&2 2>&3)
	
	if [ $? -eq 0 ]
	then	

		if [ ! -d $des_nfsdir ]
		then
			whiptail --yes-button "Create" --no-button "Back" --yesno "Directory Not Found. Do You want to create new directory?" 7 60
			
			if [ $? -eq 0 ]
			then
				#Create new dir
				mkdir -p $des_nfsdir 	
			else
			continue
			fi
		fi
	
		des_nfsdir=`echo $des_nfsdir | sed 's|/$||g'`
		mount |grep -wE "$des_nfsdir|$des_nfsdir/" &> /dev/null
		#grep "$src_nfsdir " /etc/exports 
		if [ $? -eq 0 ]
		then
			whiptail --msgbox "Directory alredy in Use" 8 78
			continue
		
		fi
	
	

	else
    		echo "You mm chose Cancel."
		return  #### go back to main menu
	fi
	flag=0
done

whiptail --yes-button "Temperory mounting" --no-button "Permanent Mounting" --yesno "Select Mounting Type" 7 60

if [ $? -eq 0 ]
then
	#temp mounting
	mount $src_network:$select_dir $des_nfsdir 	
else
	#permanent mounting
	echo  $src_network:$select_dir $des_nfsdir nfs defaults,_netdev 0 0 >>/etc/fstab
	mount -a
fi

mount |grep -wE "$des_nfsdir|$des_nfsdir/" | grep $src_network:$select_dir&> /dev/null

if [ $? -eq 0 ]
then
# successfuly mounted 		
whiptail --title "Successfully" --msgbox "Successfully mounted $src_network:$select_dir $des_nfsdir " 10 60
fi

}
q_OPTION=$(whiptail --backtitle "bla bla bla" --title "Test Menu Dialog" --menu "Choose your option" 15 45 2 \
"Share" "a Dir  On Network" \
"Mount" "a Dir on Network "  3>&1 1>&2 2>&3)
 
exitstatus=$?
if [ $exitstatus = 0 ]; then
    ${q_OPTION}
else
    . ./main.sh
fi

firewall-cmd --add-service=mountd --permanent &> /dev/null
firewall-cmd --add-service=rpc-bind --permanent &> /dev/null
firewall-cmd --add-service=nfs --permanent &> /dev/null
firewall-cmd --reload &> /dev/null
#nfs-secure nfs-secure-server
for i in nfs-server  nfs-idmap rpcbind nfs-mountd
do
systemctl enable $i &> /dev/null
#systemctl start $i 
systemctl restart $i &> /dev/null
done
