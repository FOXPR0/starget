#!/bin/bash
clear
SRCDIR=$(whiptail --title "Complete Backup" --inputbox "Please Enter the Path" 10 60 /home/ 3>&1 1>&2 2>&3)
TIME=`date +%b-%d-%y%s`          # This Command will add date in Backup File Name.
FILENAME=backup-$TIME.tar     # Here  we had define Backup file name format.
#SRCDIR=/mydata                   # Location of Important Data Directory (Source of backup).
#read -p "Enter th path of requred backup dir : " SRCDIR
mkdir -p ./backup/differential$SRCDIR                   # Destination of backup file.
DESDIR=./backup/differential$SRCDIR
rm -rf $DESDIR/*
SNF=./backup/complete$SRCDIR/*.snar          # Snapshot file name and location

ls $SNF &> /dev/null
check=$?

if [ $check == 0 ]
then
	cp $SNF $SNF.bak
	tar -p -cvf $DESDIR/$FILENAME -P -g $SNF $SRCDIR  #Backup Command
	mv -f $SNF.bak $SNF
else
	echo "First Take Complete Backup"
fi




#END 
