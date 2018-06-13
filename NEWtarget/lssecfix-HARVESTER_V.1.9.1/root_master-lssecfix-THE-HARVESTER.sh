#!/bin/bash
clear
echo
cat << EOF
    !!!!!!!!!!!!THE ROOT SLS VERSION OF:!!!!!!!!!!!!
    ################################################
    #  Lssecfix data harvester for Deutsche Bank   #
    #      Author/Developer: Martin Stejskal       #
    #               Vesrsion: V_1.9.0              #
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
if [ "$2" == "B" ]
 then BAL="ON [restart Harvester to disable the balabit support]"
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
            +======================================+


 "Choose the option:"
 ===================
  1) Harvest ALL Linux   ["$COUNTLIN" machines]
  2) Harvest ALL AIX     ["$COUNTAIX" machines]
  3) Harvest ALL Solaris ["$COUNTSOL" machines]
  4) Harvest ALL         ["$COUNTALL" machines]
  5) Enter machines manualy [Linux]
  6) Enter machines manualy [AIX]
  7) Enter machines manualy [Solaris]
  8) Download security databases
  9) Upload security databases to Jamaica
  c) Compress the output
  q) Quit

 "Enter digit and press Enter:"
EOF
 read PLATFORM
echo
fi
if [ $PLATFORM == "1" ]
   then USER="root"
	OUTDIR="OUT/Linux"
	SEXDIR="/applications/lssecfixes"
	SERVERLIST=`cat ALLLinux.department`
elif [ $PLATFORM == "2" ]
   then USER="root"
	OUTDIR="OUT/AIX"
	SEXDIR="/applications/secfixes"
	SERVERLIST=`cat ALLAIX.department`
	AixOPT=""
elif [ $PLATFORM == "3" ]
   then USER="root"
	OUTDIR="OUT/Solaris"
	SEXDIR="/applications/secfixes"
	SERVERLIST=`cat ALLSolaris.department`
elif [ $PLATFORM == "4" ]
   then gnome-terminal --command "./root_master-lssecfix-THE-HARVESTER.sh 1"
	gnome-terminal --command "./root_master-lssecfix-THE-HARVESTER.sh 2"
	gnome-terminal --command "./root_master-lssecfix-THE-HARVESTER.sh 3"
	./root_master-lssecfix-THE-HARVESTER.sh
elif [ $PLATFORM == "5" ]
   then USER="root"
        OUTDIR="OUT/Linux"
        SEXDIR="/applications/lssecfixes"
	echo "MACHINES:                        <in one line with spaces,for eg: dbkritcds60 dbkritcds01 dbkrmtb21 >"
	read SERVERLIST
elif [ $PLATFORM == "6" ]
   then USER="root"
        OUTDIR="OUT/AIX"
        SEXDIR="/applications/secfixes"
	AixOPT="n"
        echo "MACHINES:                        <in one line with spaces,for eg: dbkritcds60 dbkritcds01 dbkrmtb21 >"
        read SERVERLIST
elif [ $PLATFORM == "7" ]
   then USER="root"
        OUTDIR="OUT/Solaris"
        SEXDIR="/applications/secfixes"
        echo "MACHINES:                        <in one line with spaces,for eg: dbkritcds60 dbkritcds01 dbkrmtb21 >"
        read SERVERLIST
elif [ $PLATFORM == "8" ]
   then echo
	echo
	echo "Downloading security databases. Please wait..."
	rm -fr secfixdb.* 
	for DBDOWN in `sed ':a;N;$!ba;s/\n/ /g' secfixdbs.list`
        do for DBfle in `wget -qO- http://w3.opensource.ibm.com/frs/?group_id=1419 | grep "href=.*$DBDOWN" | sed "s/.*href=[\'\"]*\([^\'\">]*\)[\'\"]*>.*/\1/"`
		do
		wget http://w3.opensource.ibm.com$DBfle --progress=bar:force 2>&1 | grep -i -e "%" -e "sav"
		done
        done
    echo
    echo "All security databases were successfully downloaded"
    echo
    read -n1 -rsp $'Press any key to return to main menu or Ctrl+C to exit...\n'
    ./root_master-lssecfix-THE-HARVESTER.sh
elif [ $PLATFORM == "9" ]
   then echo
	echo
	echo "Uploading security databases to Jamaica. Please wait..."
	for DBUPL in `sed ':a;N;$!ba;s/\n/ /g' secfixdbs.list` 
        do if [ `echo $DBUPL|cut -c 10-12`  == "aix" ] || [ `echo $DBUPL|cut -c 10-12` == "sol" ]
		then RCMFUNCTION="secfixes"
		else RCMFUNCTION="lssecfixes"
	   fi
	perl plappl/appl_template.pl -d --mode insert --service Security --function $RCMFUNCTION --filename $DBUPL --fullname $DBUPL
	done
        echo
    echo "All security databases were successfully uploaded on Jamaica server"
    echo
    read -n1 -rsp $'Press any key to return to main menu or Ctrl+C to exit...\n'
    ./root_master-lssecfix-THE-HARVESTER.sh
#elif [ $PLATFORM == "b" ]
#  then ./root_master-lssecfix-THE-HARVESTER.sh "" B
#elif [ $PLATFORM == "d" ]
#  then ./root_master-lssecfix-THE-HARVESTER.sh "" "" IT
elif [ $PLATFORM == "c" ]
   then zip -r OUT-`date +%F`.zip OUT
	echo
	read -n1 -rsp $'Press any key to return to main menu or Ctrl+C to exit...\n'
	./root_master-lssecfix-THE-HARVESTER.sh 
elif [ $PLATFORM == "q" ]
   then exit
else
   echo "Wrong option ! Choose from the menu above."
   echo
   read -n1 -rsp $'Press any key to return to main menu or Ctrl+C to exit...\n'
   ./root_master-lssecfix-THE-HARVESTER.sh
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
timeout 180 ssh -A -o Batchmode=yes -o ConnectTimeout=90 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -q ticket_id=9999@sls4root@dbkpsobox04.rze.de.db.com sls -c $USER@$M "'$SEXDIR/rcm_lssecfixes.sh -LAFa'" 2> $OUTDIR/$M.err > $OUTDIR/$M-LSSEC-OUT.txt
echo >> $OUTDIR/$M-LSSEC-OUT.txt
grep '## File' $OUTDIR/$M-LSSEC-OUT.txt >>$OUTDIR/$M.err
grep RCM_fixDB $OUTDIR/$M-LSSEC-OUT.txt >>$OUTDIR/$M.err
grep Executing $OUTDIR/$M-LSSEC-OUT.txt >>$OUTDIR/$M.err
sed -i.bak '/RCM_fixDB/d' $OUTDIR/$M-LSSEC-OUT.txt
rm $OUTDIR/$M-LSSEC-OUT.txt.bak
sed -i.bak '/Executing/d' $OUTDIR/$M-LSSEC-OUT.txt
rm $OUTDIR/$M-LSSEC-OUT.txt.bak
sed -i.bak '/## File/d' $OUTDIR/$M-LSSEC-OUT.txt
rm $OUTDIR/$M-LSSEC-OUT.txt.bak
grep RCM_fixDB $OUTDIR/$M.err >>$OUTDIR/$M-LSSEC-OUT.txt
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
