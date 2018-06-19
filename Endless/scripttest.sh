#!/bin/bash


# script to get server ( laptop ) information into a text file, 
# I will try a few techniques here to show you whats possible. 

#set color variables for coloring text
RT="$(tput setab 0;tput setaf 1;tput bold)"
WT="$(tput setab 0;tput setaf 7;tput bold)"
GT="$(tput setab 0;tput setaf 2;tput bold)"
YT="$(tput setab 0;tput setaf 3;tput bold )"
PT="$(tput setab 0;tput setaf 5;tput bold)"
OKT="$(tput setab 7;tput setaf 0;tput bold )"

FILENAME="$(hostname)_$(date +%F)_result.txt"
SP_LINE_SP="$(echo -e \n ========================================== \n )"

# below is a 'function' , this is called on line ~55, when option 1 is selected
#you can reuse functions in different places in the script, they are
#very powerful whenyou get functions passing info to each other,
#and sharing info. That is called a 'class'. 
all_info () {
	touch $FILENAME
	echo "$(df -h)" >> $FILENAME
	echo  "$SP_LINE_SP"
	echo "$(ps -ef)" >> $FILENAME
} 	

cat << EOF



            +======================================+
            I	     $OKT My awesome script $WT           I
            I                                      I
	    I	 $RT Contact: sdavey@redhat.com$WT       I	
	    I					   I
	    I   **only select the red options if   I
	    I    you are allowed to do so ( admin )I 
	    I	 they provide security sensitive   I
	    I	 information **                    I
            +======================================+
 

$RT 1) All Information$WT
 2) Diskspace
$GT 3) User Details$WT 
$PT 4) Processes$WT 
$YT q) Exit$WT

"Choose a number:"

EOF

##Take menu choice and run the selected script, or sends back to the beginning ( TODO(SALLOWEEZY) theres a better way to do this with
## 'case', google it, and try to update the below elif chain to be a 'case' function instead. Thanks.

read choice
case "$choice" in

	1) lscpu && sleep 4; clear;;
	2) df -h; sleep 4; clear;;
	3) whoami ; sleep 4; clear;;
	4) top -b -n 1 | head -n 15; sleep 4; clear;;
	q) echo "Bye"; sleep3; clear; exit;;
	*) echo "Unknown command, please choose a number 1-4 or q to quit";;

esac
./scripttest.sh

