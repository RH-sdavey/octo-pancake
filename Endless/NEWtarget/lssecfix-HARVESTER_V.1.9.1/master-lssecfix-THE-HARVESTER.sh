#!/bin/bash
RT=`tput setab 0;tput setaf 1;tput bold`
GT=`tput setab 0;tput setaf 9;tput bold`
YT=`tput setab 9;tput setaf 3;tput bold`
XT=`tput setab 1;tput setaf 3;tput bold`
cd lssecfix-HARVESTER_V.1.9.1 2>/dev/null;
clear
cat << EOF
    ################################################
    #  Lssecfix data harvester for Deutsche Bank   #
    #      Author/Developer: Martin Stejskal       #
    #               Version: V_1.9.1               #
    #                                              #
    #     (C) Copyright IBM Corporation 2015       #
    #                                              #
    #     Contact: martin.stejskal@cz.ibm.com      #
    #                                              #
    ################################################


EOF
#Make env
echo "Initializing:"
echo
echo "Checking/making environment"
sleep 1
if [ -d OUT ]
   then echo "Directory OUT exist...OK"
else
   mkdir OUT
   echo "Directory OUT created...OK"
fi
if [ -d OUT/Linux ]
   then echo "Directory OUT/Linux exist...OK"
else
   mkdir OUT/Linux
   echo "Directory OUT/Linux created...OK"
fi
if [ -d OUT/AIX ]
   then echo "Directory OUT/AIX exist...OK"
else
   mkdir OUT/AIX
   echo "Directory OUT/AIX created...OK"
fi
if [ -d OUT/Solaris ]
   then echo "Directory OUT/Solaris exist...OK"
else
   mkdir OUT/Solaris
   echo "Directory OUT/Solaris created...OK"
fi

echo
echo
sleep 1
#Checking deps
echo "Checking dependencies"
if [ -f ALLLinux.department ]
   then echo "File ALLLinux.department available...OK"
else
   echo "File ALLLinux.department NOT availbale, please put it in to the work folder of the Harvester"
   echo "Press any key to exit"
read
exit
fi
if [ -f ALLAIX.department ]
   then echo "File ALLAIX.department available...OK"
else
   echo "File ALLAIX.department NOT availbale, please put it in to the work folder of the Harvester"
   echo "Press any key to exit"
read
exit
fi
if [ -f ALLSolaris.department ]
   then echo "File ALLSolaris.department available...OK"
else
   echo "File ALLSolaris.department NOT availbale, please put it in to the work folder of the Harvester"
   echo "Press any key to exit"
read
exit
fi
echo
echo
if [ -f secfixdbs.list ]
   then echo "File secfixdbs.list available...OK"
else
   echo "File secfixdbs.list NOT availbale, please put it in to the work folder of the Harvester"
   echo "Press any key to exit"
read
exit
fi
if [ -f filter1.flt ]
   then echo "File filter1.flt available...OK"
else
   echo "File filter1.flt NOT availbale, please put it in to the work folder of the Harvester"
   echo "Press any key to exit"
read
exit
fi
echo
echo
if [ -f plappl/appl_template.pl ]
   then echo "File with RCM automation template available...OK"
else
   echo "File with application perl template for RCM automation NOT availbale, please put it in to the work folder of the Harvester"
   echo "Press any key to exit"
read
exit
fi
if [ -d lib ]
   then echo "Directory with libraries available...OK"
else
   echo "Directory with libraries NOT availbale, please put it in to the work folder of the Harvester"
   echo "Press any key to exit"
read
exit
fi
sleep 2
clear
#Declare intiger for percentage division
typeset -i COUNTLIN=`cat ALLLinux.department|wc -w`
typeset -i COUNTAIX=`cat ALLAIX.department|wc -w`
typeset -i COUNTSOL=`cat ALLSolaris.department|wc -w`
typeset -i COUNTALL=`cat *.department|wc -w`
#typeset -i HUNDR='100'

ONEPERLIN=$(echo "scale=2; 100/$COUNTLIN" | bc)
ONEPERAIX=$(echo "scale=2; 100/$COUNTAIX" | bc)
ONEPERSOL=$(echo "scale=2; 100/$COUNTSOL" | bc)
PERCENTAGE="0"
#Balashit support
if [ "$2" != "B" ]
 then BAL="ON [Balabit support is now by default on]"
      BALBYTICKT="ticket_id=9999@"
 else BAL="OFF"
      BALBYTICKT=""
fi
if [ "$3" == "IT" ]
 then DOMAIN=it.db.com
      DOMMENU="Harvester @.it.db.com [Italian domain]"
 else DOMAIN=rze.de.db.com
      DOMMENU="Harvester @.rze.de.db.com [German domain]"
fi
#Set var
PLATFORM=$1
if [ "$PLATFORM" != "" ]
 then echo
else 
cat << EOF


            +======================================+
            I         The Lssecfix Harvester       I
            I         Mini-version by Sean Davey   I
            +======================================+


 "Choose the option:"
 ===================
  1) Enter machines manually [ $RT Linux $GT]
  2) Enter machines manually [ $RT AIX $GT ]
  3) Enter machines manually [ $RT Solaris $GT ]

  c) Compress the output and $RT email results to me $GT
  q) $XT Quit $GT

 "Enter digit and press Enter:"
EOF
 read PLATFORM
echo
fi
if [ $PLATFORM == "1" ]
   then USER="secfixrep"
        OUTDIR="OUT/Linux"
        SEXDIR="/applications/lssecfixes"
	echo "ENTER$RT SERVER NAMES$GT : ( eg: dbkpsapsp1 dbkpbw1 dbkpsapsp3)   $RT**OR PRESS q TO RETURN TO MAIN MENU**$GT"
	read SERVERLIST
	if [ $SERVERLIST == "q" ]
	then ./master-lssecfix;THE-HARVESTER.sh;exit; fi;	
elif [ $PLATFORM == "2" ]
   then USER="secfixrp"
        OUTDIR="OUT/AIX"
        SEXDIR="/applications/secfixes"
	AixOPT="n"
        echo "ENTER$RT SERVER NAMES$GT : ( eg: dbkpsapsp1 dbkpbw1 dbkpsapsp3)   $RT**OR PRESS q TO RETURN TO MAIN MENU**$GT"
	read SERVERLIST
	if [ $SERVERLIST == "q" ]
	then ./master-lssecfix;THE-HARVESTER.sh;exit; fi;
elif [ $PLATFORM == "3" ]
   then USER="secfixrp"
        OUTDIR="OUT/Solaris"
        SEXDIR="/applications/secfixes"
        echo "ENTER$RT SERVER NAMES$GT : ( eg: dbkpsapsp1 dbkpbw1 dbkpsapsp3)   $RT**OR PRESS q TO RETURN TO MAIN MENU**$GT"
	read SERVERLIST
	if [ $SERVERLIST == "q" ]
	then ./master-lssecfix;THE-HARVESTER.sh;exit; fi;
elif [ $PLATFORM == "c" ]
	then rm ./OUT-*.zip	
	echo $YT " Here you should twice type the encryption password for your output...( security ) " $GT
   	zip -e -r "OUT-`date +%F`.zip" OUT
	rm -R ./OUT/
	echo
	echo "ENTER$RT YOUR NAME$GT  PLEASE ( eg: sean VIT jand janc )"
	read name
	FEMAIL=$(grep -i $name ../emails.dat | awk '{print $2}')
	echo
	echo "OK, I'm going to email the output to $YT $FEMAIL $GT now."
	echo
	echo $YT "                               work in progress....please be patient $GT "
	sleep 5
	echo
	mutt -a "OUT-`date +%F`.zip" -s "lssecfix output for $name " </dev/null -- $FEMAIL 2>/dev/null;
	echo $YT "                               the output is in your inbox. Taking you back to the menu... $GT "
	sleep 5
	echo
	./master-lssecfix-THE-HARVESTER.sh 
elif [ $PLATFORM == "q" ]
   then cd ..  && . main.sh
else
   echo "Wrong option ! Choose from the menu above."
   echo
   read -n1 -rsp $'Press any key to return to main menu or Ctrl+C to exit...\n'
   ./master-lssecfix-THE-HARVESTER.sh
fi

#Connection loop
clear
for M in $SERVERLIST
 do echo 
 echo "PROGRESS:"
 echo
 echo $PERCENTAGE"% Completely done"
 echo
 echo $M "...Currently in progress"
 timeout 180 ssh -A -o Batchmode=yes -o ConnectTimeout=25 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $BALBYTICKT$USER@$M.$DOMAIN $SEXDIR/rcm_lssecfixes.sh -LAFa 2> $OUTDIR/$M.err > $OUTDIR/$M-LSSEC-OUT.txt
echo >> $OUTDIR/$M-LSSEC-OUT.txt
grep RCM_fixDB $OUTDIR/$M.err >> $OUTDIR/$M-LSSEC-OUT.txt
#Filtering section, do make the list in filter1.flt file
 sed -i 's/       H/  x    H/g' $OUTDIR/$M-LSSEC-OUT.txt; 
 sed -i 's/       M/  x    M/g' $OUTDIR/$M-LSSEC-OUT.txt; 
 sed -i 's/       L/  x    L/g' $OUTDIR/$M-LSSEC-OUT.txt; 
 sed -i 's/Free %Used/Free\t%Used/g' $OUTDIR/$M-LSSEC-OUT.txt; 
 sed -i 's/  \+/\t/g' $OUTDIR/$M-LSSEC-OUT.txt;
 sed -i 's/Iused %Iused Mounted on/Iused\t%Iused\tMounted on/g' $OUTDIR/$M-LSSEC-OUT.txt; 
 sed -i 's/% /%\t/g' $OUTDIR/$M-LSSEC-OUT.txt; 
 sed -i 's/Used Avail Use%/Used\tAvail\tUse%/g' $OUTDIR/$M-LSSEC-OUT.txt; 
 sed -i 's/M /M\t/g' $OUTDIR/$M-LSSEC-OUT.txt; 
 sed -i 's/IBM\t/IBM /g' $OUTDIR/$M-LSSEC-OUT.txt;
 sed -i 's/\(Date: [^0-9]*\) /\1 /g' $OUTDIR/$M-LSSEC-OUT.txt;
#Separated editable filtering section for new hostnames. Fill the list in filter1.flt file
for FILT in `sed ':a;N;$!ba;s/\n/ /g' filter1.flt`
 do sed -i -e s/$FILT/g $OUTDIR/$M-LSSEC-OUT.txt;
done
#End of filtering section
echo $M "...Done"
echo
echo
echo "Quick overview (high severity not patched):"
echo
echo
grep ADVISORY -A 20 $OUTDIR/$M-LSSEC-OUT.txt | grep "*" | cut -b 1-80 | sed -e 's/\t/ /g' | cut -b -80 | head -15
sleep 1
if [ $PLATFORM == "1" ]
 then PERCENTAGE=$(echo "scale=2; $PERCENTAGE+$ONEPERLIN" | bc | sed 's/^\./0./')
elif [ $PLATFORM == "2" ]
 then PERCENTAGE=$(echo "scale=2; $PERCENTAGE+$ONEPERAIX" | bc | sed 's/^\./0./')
elif [ $PLATFORM == "3" ]
 then PERCENTAGE=$(echo "scale=2; $PERCENTAGE+$ONEPERSOL" | bc | sed 's/^\./0./')
fi
echo
clear
done

echo
echo "DONE"
echo
echo "Results can be found in directory OUT"
echo
echo
../master-lssecfix-THE-HARVESTER.sh 2>/dev/null || ./master-lssecfix-THE-HARVESTER.sh 2>/dev/null
