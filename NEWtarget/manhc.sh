#!/bin/bash
clear
echo
echo $XT "Admin Info for Solaris machines" $GT
echo
#take server name and save to variable or q to exit to main menu
echo "ENTER$RT SERVER NAMES$GT : ( eg: dbkpsapsp1 dbkpbw1 dbkpsapsp3)   $RT**OR PRESS q TO RETURN TO MAIN MENU**$GT"
read MACHINES
if [ $MACHINES == "q" ]
then ./main.sh;exit; fi;
echo
#enter name for logging and to lookup email adress from emails.dat
echo "ENTER$RT YOUR NAME$GT  PLEASE ( eg: sean VIT jand janc )     **$RT OR PRESS q TO RETURN TO MAIN MENU$GT **"
read name
if [ $name == "q" ]
then ./main.sh;exit; fi;
echo $YT "                      Please be patient...working on it..."$GT
echo
FEMAIL=$(grep -i $name emails.dat | awk '{print $2}')
DATENUMBER="$(date +%j%s)"
DATEFORLOG="$(date)"
mkdir ./results/information/admin_solaris/$DATENUMBER
echo "Script: man_hc	User: $name	Email: $FEMAIL	Folder: $DATENUMBER	MACHINES: $MACHINES	Date: $DATEFORLOG">> ./logfile.dat ;
echo "Script: man_hc	User: $name	Email: $FEMAIL	Folder: $DATENUMBER	MACHINES: $MACHINES	Date: $DATEFORLOG">> ./requests/presession.dat ;



#for i in $MACHINES;do echo ""[czz61975@oc2318074560 ~]$ ssh -tA -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q -A ticket_id=9999@sls4root@10.224.64.69 --command sls -c root@$i "'logger -p auth.info "PHC MAINTENANCE - MANUAL HEALTH CHECK" &&echo&&hostname&&echo&&date&&echo&&ls -ld /var/applications/srm&& echo&&ls -ld /applications/srm&&echo&&ls -lR /var/applications/srm |grep -v root|grep -v perfmgr|grep -v tivadm&&echo&&ls -lR /applications/srm |grep -v root|grep -v perfmgr|grep -v tivadm &&echo&&cat /etc/passwd|grep -i srmcoll&&echo&&cat /etc/passwd|grep -i srmmgr'""" > ./results/man_hc/$DATENUMBER/man_hc_$i.txt && ssh -tA -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q -A ticket_id=9999@sls4root@10.224.64.69 --command sls -c root@$i "'logger -p auth.info "PHC MAINTANENCE - MANUAL HEALTH CHECK"&&echo&&hostname&&echo&&date&&echo&&ls -ld /var/applications/srm&& echo&&ls -ld /applications/srm&&echo&&ls -lR /var/applications/srm |grep -v root|grep -v perfmgr|grep -v tivadm&&echo&&ls -lR /applications/srm |grep -v root|grep -v perfmgr|grep -v tivadm &&echo&&cat /etc/passwd|grep -i srmcoll&&echo&&cat /etc/passwd|grep -i srmmgr'" >> ./results/man_hc/$DATENUMBER/man_hc_$i.txt && echo "[czz61974@oc2318074560 ~]$ " >> ./results/man_hc/$DATENUMBER/man_hc_$i.txt && fold ./results/man_hc/$DATENUMBER/man_hc_$i.txt > ./results/man_hc/$DATENUMBER/man_hc_$i_new.txt | convert -font Helvetica -style Normal -background none -undercolor black -fill "#00FF00" -pointsize 16 -page 800x2400+0+0 -background black -flatten ./results/man_hc/$DATENUMBER/man_hc_$i_new.txt ./results/man_hc/$DATENUMBER/man_hc_$i.png; rm -fr ./results/man_hc/$DATENUMBER/man_hc_$i_new.txt; done
clear
echo 
#cat << EOF
# 
# $YT OK, request done, what would you like to do with the output?$GT
# 
#  1) $RT Email the output $GT to $YT SARM team / SECMon team / Jana Kyklosova  $GT
#  2) $RT Email the output$GT to $YT $FEMAIL $GT
#  3) $RT Start again$GT from the beginning
#
# $RT "choose a number:" $GT
#EOF
#read outputchoice
#echo
#if [ $outputchoice == "1" ]
#echo $YT " here you should twice type the encryption password for your output...( security ) " $GT
#then zip -e -m ./results/man_hc/$DATENUMBER/OUT-$FEMAIL.zip ./results/man_hc/$DATENUMBER/*.*
#echo
#mutt -a "./results/man_hc/$DATENUMBER/OUT-$FEMAIL.zip" -s "Manual Healthcheck for $i" < /dev/null -- jana_kyklosova@cz.ibm.com -c SECMON@de.ibm.com -c SRMIT5BRNO@cz.ibm.com -c sean_davey@cz.ibm.com 2>/dev/null;
#clear
#echo
#echo $YT "The output is in your inbox now, taking you back to the main menu..." $GT
#sleep 5
#./main.sh
#elif [ $outputchoice == "2" ] 
#echo $YT " here you should twice type the encryption password for your output...( security ) " $GT
#then zip -e -m ./results/man_hc/$DATENUMBER/OUT-$FEMAIL.zip ./results/man_hc/$DATENUMBER/man_hc_*
#echo
#mutt -a "./results/man_hc/$DATENUMBER/OUT-$FEMAIL.zip" -s "Manual Healthcheck for $i" < /dev/null -- $FEMAIL -c sean_davey@cz.ibm.com 2>/dev/null;
echo
echo $GT "The request has been sent to $RT Sean Davey $GT , he will send the results directly to $YT $FEMAIL $GT soon." $GT
echo 
sleep 1
echo $YT "Taking you back to the main menu now..." $GT
sleep 2
./main.sh
#clear
#echo
#echo $YT "The output is in your inbox now, taking you back to the main menu..." $GT
#sleep 5
#./main.sh
#elif [ $outputchoice == "3" ] 
#then ./main.sh
#else echo "you messed up, taking you back to the start of this menu";sleep 5; ./manhc.sh;
#fi



