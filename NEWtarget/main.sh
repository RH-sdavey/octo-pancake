#!/bin/bash

#set color variables for coloring text
RT=`tput setab 0;tput setaf 1;tput bold`
GT=`tput setab 0;tput setaf 9;tput bold`
YT=`tput setab 9;tput setaf 3;tput bold`
XT=`tput setab 1;tput setaf 3;tput bold`
OKT=`tput setab 0;tput setaf 3;tput bold`

#checks if results folders exist & creates them
clear
echo
echo "$GT Initializing:"
echo
echo "Checking/making environment"
sleep 1
if [ -d results ]
   then echo "Directory results exists... $OKT OK $GT"
else
   mkdir results
   echo "Directory results created... $OKT OK $GT"
fi
if [ -d results/overflow ]
   then echo "Directory results/overflow exists... $OKT OK $GT"
else
   mkdir results/overflow
   echo "Directory results/overflow created... $OKT OK $GT"
fi
if [ -d results/man_hc ]
   then echo "Directory results/man_hc exists... $OKT OK $GT"
else
   mkdir results/man_hc
   echo "Directory results/man_hc created... $OKT OK $GT"
fi
if [ -d results/information ]
   then echo "Directory results/information exists... $OKT OK $GT"
else
   mkdir results/information
   echo "Directory results/information created... $OKT OK $GT"
fi
if [ -d results/information/coord_linux ]
   then echo "Directory results/information/coord_linux exists... $OKT OK $GT"
else
   mkdir results/information/coord_linux
   echo "Directory results/information/coord_linux created... $OKT OK $GT"
fi
if [ -d results/information/coord_aix ]
   then echo "Directory results/information/coord_aix exists... $OKT OK $GT"
else
   mkdir results/information/coord_aix
   echo "Directory results/information/coord_aix created... $OKT OK $GT"
fi
if [ -d results/information/coord_solaris ]
   then echo "Directory results/information/coord_solaris exists... $OKT OK $GT"
else
   mkdir results/information/coord_solaris
   echo "Directory results/information/coord_solaris created... $OKT OK $GT"
fi
if [ -d results/information/admin_solaris ]
   then echo "Directory results/information/admin_solaris exists... $OKT OK $GT"
else
   mkdir results/information/admin_solaris
   echo "Directory results/information/admin_solaris created... $OKT OK $GT"
fi
if [ -d results/information/admin_linux ]
   then echo "Directory results/information/admin_linux exists... $OKT OK $GT"
else
   mkdir results/information/admin_linux
   echo "Directory results/information/admin_linux created... $OKT OK $GT"
fi
if [ -d results/information/admin_aix ]
   then echo "Directory results/information/admin_aix exists... $OKT OK $GT"
else
   mkdir results/information/admin_aix
   echo "Directory results/information/admin_aix created... $OKT OK $GT"
fi
if [ -d requests ]
   then echo "Directory requests exists... $OKT OK $GT"
else
   mkdir requests
   echo "Directory requests created... $OKT OK $GT"
fi
if [ -f requests/thissession.txt ]
   then rm ./requests/thissession.txt ; touch ./requests/thissession.txt
else 
   touch ./requests/thissession.txt
fi
echo
echo
echo $YT "Loading script now... " $GT
sleep 2

######Menu system

echo
cat << EOF
            +======================================+
            I	$YT	    SD-SCRIPT  $GT            I
            I    $RT contact: sean_davey@cz.ibm.com $GT  I
	    I					   I	
	    I					   I
	    I   **only select the red options if   I
	    I    you are allowed to do so ( admin )I 
	    I	 they provide security sensitive   I
	    I	 information **                    I
            +======================================+
 
 $YT 1) Coordinator  AIX
  2) Coordinator  Linux
  3) Coordinator  Solaris $RT

$RT  4) Admin AIX 
  5) Admin Linux
  6) Admin Solaris $GT

  q) $XT Quit  $GT ( will restart this script, for real $XT Quit and CLOSE CONNECTION press CTRL+C ) $GT 

 "choose a number:"
EOF

##Take menu choice and run the selected script, or sends back to the beginning
read choice
echo
if [ $choice == "1" ]
	then . coordinator_AIX.sh
elif [ $choice == "2" ] 
	then . coordinator_linux.sh
elif [ $choice == "3" ] 
	then . coordinator_solaris.sh
elif [ $choice == "4" ]
	then . admin_AIX.sh
elif [ $choice == "5" ]
	then  . admin_linux.sh
elif [ $choice == "6" ]
	then . admin_solaris.sh
elif [ $choice == "c" ]
   then . cleanup_SD.sh
else
   echo "Wrong option ! Choose from the menu above."
   echo
read -n1 -rsp $'choose the correct option'
   ./main.sh
fi

