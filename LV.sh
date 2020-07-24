#!/bin/bash
#This is the script for recovering LV which is accidently deleted by someone

#This script asks user only for corrupted PV name and it will automatically recognize the VG name and again asks for LV name which user want to recover

###########################################################################################################

# ------------- system commands used by this script --------------------
ID=/usr/bin/id;

# make sure we're running as root
if (( `$ID -u` != 0 ));

 then { $ECHO "Sorry, must be root.  Exiting..."; exit; }

 fi

#ask user for entering PV name on which deleted LV is present
#echo "Enter corrupted PV name"
#read a
a=$(whiptail --inputbox "Enter Courrupted PV Name" 7 60  3>&1 1>&2 2>&3)
echo "====================================" >> /tmp/meta2.$$

#This is a procedure to find Volume Group name on the corrupted PV.
ls  /etc/lvm/backup/ > ~/file1
for b in $(cat ~/file1)
do
echo " In "$b > /dev/null
cat /etc/lvm/backup/$b | grep -i $a > /dev/null
if [[ $(echo $?) == 0  ]]
then
echo "Name of VG on $a is ==>  $b" >> /tmp/meta2.$$
fi
done

echo "====================================" >> /tmp/meta2.$$

#echo "Which lv you want to recover"
#read o
o=$(whiptail --inputbox "Which lv you want to recover" 7 60  3>&1 1>&2 2>&3)
echo "====================================" >> /tmp/meta2.$$

#Here you can go inside archive directory where the seperate VG metadata present and we need to take latest one
cd /etc/lvm/archive
e=`ls -ltr | grep $b | tail -1 | awk -F " " '{print $9}'`
#Here we get a recent vg metadata, this metadata is storing in variable e
cd


#Here we are restoring metadata of VG
vgcfgrestore $b --test -f /etc/lvm/archive/$e &> /dev/null

vgcfgrestore $b -f /etc/lvm/archive/$e &> /dev/null


lvchange -a y /dev/$b/$o

#lvscan command output will be on console and it will display all LV status ==(ACTIVE/INACTIVE)== 
lvscan >> /tmp/meta2.$$
echo "====================================" >> /tmp/meta2.$$
#Here we will check all the LV mounted properly or not: If there is problem in mouning that means it failed to recovel LV and it will show an error message.
mount -a &> /dev/null
if  [ $(echo $?) -eq 0 ]
then echo "$o recovered succesfully" >> /tmp/meta2.$$
else
echo "fail" >> /tmp/meta2.$$
fi


echo "====================================" >> /tmp/meta2.$$
whiptail --title "Logical Volumes" --msgbox "$(cat /tmp/meta2.$$)" 40 68

