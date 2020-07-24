#!/bin/bash
#This is the script for Physical Volume metadata recovery when accidently corrupted your PV metadata or someone deleted metadata using dd command manually.

#This script asks user only for corrupted PV name and it will automatically recognize the VG name and all LV names which are present on that VG.

#After displaying all the LV's, this script automatically active all the LV's and try to recover data.

###########################################################################################################

# ------------- system commands used by this script --------------------
ID=/usr/bin/id;

# make sure we're running as root
if (( `$ID -u` != 0 ));

 then { $ECHO "Sorry, must be root.  Exiting..."; exit; }

 fi

#ask user for entering Corrupted PV name
#echo "Enter corrupted PV name"
#read a
a=$(whiptail --inputbox "Enter Courrupted PV Name" 7 60  3>&1 1>&2 2>&3)

echo "===================================" >> /tmp/meta1.$$

#This is a procedure to find Volume Group name on the corrupted PV.
ls  /etc/lvm/backup/ > ~/file1
for b in $(cat ~/file1)
do
echo " In "$b > /dev/null
cat /etc/lvm/backup/$b | grep -i $a > /dev/null
if [[ $(echo $?) == 0  ]]
then
echo "Name of VG on $a is ==>  $b" >> /tmp/meta1.$$
fi
done
echo "====================================" >> /tmp/meta1.$$
#This is the procedure to find 
echo "No of LV present on Volume group $b is"
z=`sed -n /logical_volume/,//p /etc/lvm/backup/vg0 | grep -B1 id  | grep "{" | awk -F " " '{print $1}' > ~/file2`
#echo $z
cat ~/file2 >> /tmp/meta1.$$
#We are storing all the available LV names in variable z
echo "=====================================" >> /tmp/meta1.$$
#using this command we will go inside the perticulat metadata backup and copies the ID of corrupted PV
d=`grep -B 1 $a /etc/lvm/backup/$b | grep id | awk -F "=" '{print $2}'`
# we are storing corrupted PV UUID in d veriable

#Here you can go inside archive directory where the seperate VG metadata present and we need to take latest one
cd /etc/lvm/archive
e=`ls -ltr | grep $b | tail -1 | awk -F " " '{print $9}'`
#Here we get a recent vg metadata, this metadata is storing in variable e
cd

#Here we are creating a Physical Volume using a same UUID.
echo "pvcreate --uuid $d --restorefile /etc/lvm/archive/$e $a" >  ~/file.sh
bash ~/file.sh &> /dev/null
if [ $(echo $?) -ne 0 ]
 then
      echo "continue"
fi

#Here we are restoring metadata of VG
vgcfgrestore /dev/$b > /dev/null

#Here we take one-by-one output from file2(where all LV names stored)....and activating these all Lv usin for loop.
for k in $(cat ~/file2)
do
lvchange -ay /dev/$b/$k
done
echo "======================================" >> /tmp/meta1.$$
#lvscan command output will be on console and it will display all LV status ==(ACTIVE/INACTIVE)==  
lvscan >> /tmp/meta1.$$
echo "======================================" >> /tmp/meta1.$$
#Here we will check all the LV mounted properly or not: If there is problem in mouning that means it failed to recovel LV and it will show an error message.
mount -a &> /dev/null
if  [ $(echo $?) -eq 0 ] 
then echo "Metadata is recovered successfully" >> /tmp/meta1.$$
else echo "fail" >> /tmp/meta1.$$
fi
echo "======================================="  >> /tmp/meta1.$$
whiptail --title "Logical Volumes" --msgbox "$(cat /tmp/meta1.$$)" 40 68
#cat /tmp/meta1.$$
rm -rf /tmp/meta1.$$

