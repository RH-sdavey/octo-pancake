#!/bin/bash


# script to get server ( laptop ) information into a text file, 
# I will try a few techniques here to show you whats possible. 

#set color variables for coloring text
RT="$(tput setab 0;tput setaf 1;tput bold) "
GT="$(tput setab 0;tput setaf 9;tput bold )"
YT="$(tput setab 9;tput setaf 3;tput bold )"
XT="$(tput setab 1;tput setaf 3;tput bold )"
OKT="$(tput setab 0;tput setaf 3;tput bold )"

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
            I	$YT   my awesome script  ITS ACTUALLY SHIITTT  $GT         I
            I    $RT contact: sdavey@redhat.com    I
	    I					   I	
	    I					   I
	    I   **only select the red options if   I
	    I    you are allowed to do so ( admin )I 
	    I	 they provide security sensitive   I
	    I	 information **                    I
            +======================================+
 
 $YT 1) ALL information
  2) Diskspace
  3) Print your user details to the screen. 

$RT  4) Smash your computer to pieces
  5) Format your hardrive
  6) Release a BIG virus $GT

  q) $XT Quit  $GT ( will restart this script, for real $XT Quit and CLOSE CONNECTION press CTRL+C ) $GT 

 "choose a number:"
EOF

##Take menu choice and run the selected script, or sends back to the beginning ( TODO(SALLOWEEZY) theres a better way to do this with
## 'case', google it, and try to update the below elif chain to be a 'case' function instead. Thanks.

read choice
echo
if [ $choice == "1" ]
	then all_info ; 
elif [ $choice == "2" ] 
	then echo clear ; "$(df -h)" ; echo $SP_LINE_SP ; ./script.sh 
elif [ $choice == "3" ] 
	then clear ; grep $(whoami) /etc/passwd ; echo; echo; grep  $(whoami) /etc/shadow ; echo ; echo $(who) ; echo ; echo etc etc
elif [ $choice == "4" ]
	then echo "I wont really dont worry" ; ./script.sh
elif [ $choice == "5" ]
	then  echo " formatting hard drive in 5 seconds ... " ; clear ; echo FORMATTING NOW ; sleep 2 ; echo "all done everything deleted"
elif [ $choice == "6" ]
	then echo 'find / -name "*.*"'
 # TODO(SALLOWEEZY) need to add an option here for "q" that will 'exit' when its called, look above for inspiration
else
   echo "Wrong option ! Choose from the menu above."
   echo
read -n1 -rsp 'choose an option'
   ./script.sh
fi

