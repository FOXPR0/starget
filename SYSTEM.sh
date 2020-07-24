#!/bin/bash
function Basic()
{
	echo -e "\t\t\t\t Server Report"
	echo -e "\t\t\t\t--------------"
	date +"Date: %B %d, %Y %I:%M %p"
	echo -e "By:\t`whoami`"
	echo -e "\n\tBasic Server Information"
	echo -e "\t--------------------------"
	echo -e "\tIP : `hostname -I | cut -d' ' -f1`"
	echo -e "\tHostname: `hostname`"
	echo -e "\tOS\t:`uname -o |cut -d "/" -f2`"
	echo -e "\tKernel\t: `uname -r`"
	echo -e "\tArchitecture: `uname -m` Bit"
	echo -e "\n\n\n\tUp Time\t: `uptime -p | sed 's/up //'`"
	echo -e "\tCurrent Users\t: `w | sed 1,2d | awk '{print $1}' | sort -u | wc -l`"
	echo -e "\tCurrent Processes : `ps aux | sed 1d | wc -l`"
	echo -e "\tCPU Usage\t:`ps aux| sed 1d | awk '{sum+=$3}END{print sum}'`% (Threshold 85%, 90%)"
	echo -e "\tMemory Usage\t: `free -m | grep -i mem | tr -s " " | cut -d " " -f7` out of `free -m | grep -i mem | tr -s " " | cut -d " " -f2` (Threshold 90%, 95%)"
	echo -e "\tSystem Load\t:` uptime | rev | cut -d ":" -f1| rev| awk -F ',' '{printf("%s (1 min), %s (5 min), %s (15 min)",$1,$2,$3)}'`" 

}


function Users()
{
	echo -e "\n\t List of Users Currently Logged in(sorted by number of sessions)"
	echo -e "\t------------------------------------------------------------------------"
	for i in `w | sed 1,2d | cut -d " " -f1|sort -u`
	do
		echo -e "\t$i $(w | sed 1,2d | grep $i | wc -l )" >>/tmp/$(whoami).$$
	done
	sort -rk2,2 /tmp/$(whoami).$$ | awk '{print "\t" $1 " - " $2 "  Sessions"}'
}


function Process()
{
	echo -e "\n\n\tProcess Load (Processes taking higher resources)"
	echo -e "----------------------------------------------------"
	ps aux | head -1|awk '{print "\t"$1"\t"$2"\t"$3"\t"$4"\t"$11}' | column -t
	ps aux |sed 1d | sort -rk3,3 |awk '{print "\t"$1"\t"$2"\t"$3"\t"$4"\t"$11}'|column -t |head -10

}

function LVM()
{
	echo -e "\n\tLVM Information"
	echo -e "--------------------------"
	for i in `lvs | sed 1d | awk '{print $1}'`
	do
		mount | grep -E "^/dev/.*$i" >/dev/null
		if [ $? -eq 0 ]
		then
			mount | grep -E "^/dev/.*$i" | awk '{print $3}' >>/tmp/$(whoami).lvm1.$$
		else
			echo "[Not_Mounted]" >>/tmp/$(whoami).lvm1.$$
		fi
	done

	lvs | sed 1d | awk '{print  $1 " " $2 " " " " $4}' >/tmp/$(whoami).lvm2.$$

	paste /tmp/$(whoami).lvm2.$$ /tmp/$(whoami).lvm1.$$ | awk 'BEGIN{
	printf("%s %s %s %s\n","LV","VG","Size","Mount_Pont");
	printf("\t%s %s %s %s\n","---------------","------------","-------","---------------");
	}
	{
	printf("%s %s %s %s\n",$1,$2,$3,$4);
	}' | column -t

	rm -f /tmp/$(whoami).lvm2.$$ /tmp/$(whoami).lvm1.$$
	echo

	pvs | sed 1d | awk 'BEGIN{
		print  "PV VG SIZE";
		print "----- --------- -------";
	}
	{
		print $1 " " $2 " " $5;
	}' | column -t
}



#whiptail --title "Logical Volumes" --msgbox "$(serverinfo)" 40 78
s_OPTION=$(whiptail --backtitle "bla bla bla" --title "SYSTEM INFO" --menu "Choose your option" 15 45 4 \
"Basic" "Server Info" \
"Process" "Taking Making Load" \
"LVM" " Info" \
"Users" "Logged In"  3>&1 1>&2 2>&3)
 
exitstatus=$?
if [ $exitstatus = 0 ]; then
    whiptail --title "Logical Volumes" --msgbox "$($s_OPTION)" 40 78
else
	break
    exit
fi
