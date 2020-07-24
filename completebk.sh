#!/bin/bash
clear
SRCDIR=$(whiptail --title "Complete Backup" --inputbox "Please Enter the Path" 10 60 /home/ 3>&1 1>&2 2>&3)
TIME=`date +%b-%d-%y%s`          # This Command will add date in Backup File Name.
FILENAME=backup-$TIME.tar     # Here  we had define Backup file name format.
#read -p "Enter th path of requred backup dir : " SRCDIR
mkdir -p ./backup/complete$SRCDIR                   # Destination of backup file.
DESDIR=./backup/complete$SRCDIR
rm -rf $DESDIR/*
SNF=./backup/complete$SRCDIR/$FILENAME.snar          # Snapshot file name and location
tar -p -cvf $DESDIR/$FILENAME -P -g $SNF $SRCDIR  #Backup Command
#END 
