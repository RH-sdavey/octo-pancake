#!/bin/bash

clear
echo
echo "Fetching the latest requests and assigning command variables ..." ; 

sed '/^$/d' ./requests/presession.dat > ./requests/session.dat
SCRIPT=$(awk 'NR==1{print $2}' ./requests/session.dat)

if [ $SCRIPT = "coord_linux" ]
then 
   COMMAND1='grep ML /var/db/var/installed_x_services|tail -1'
   COMMAND2='rpm -qa | sort'
   COMMAND3='cat /etc/*release'
   COMMAND4='df -h /usr /var /tmp /home /dev /boot /'
   SCRIPTFOLDER='coord_linux'
fi
if [ $SCRIPT = "coord_aix" ]
then 
   COMMAND1='grep TL /var/db/var/installed_x_services|tail -1'
   COMMAND2='lslpp -L'
   COMMAND3='oslevel -s '
   COMMAND4='df -m /usr /var /tmp /home /dev /'
   SCRIPTFOLDER='coord_aix'
fi
if [ $SCRIPT = "coord_solaris" ]
then 
   COMMAND1='cat /var/db/var/installed_x_services|tail -1 '
   COMMAND2='pkginfo -l'
   COMMAND3='cat /etc/*release'
   COMMAND4='df -h /usr /var /tmp /home /dev /'
   SCRIPTFOLDER='coord_solaris'
fi

sleep 1 ; echo $YT "Done." $GT
sleep 1 ; echo "Assigning loop variables"


MACHINES=$(cat ./requests/session.dat | grep -o -P '(?<=MACHINES: ).*(?=Date:)' | head -1)
USER=$(awk 'NR==1{print $4}' ./requests/session.dat)
FEMAIL=$(awk 'NR==1{print $6}' ./requests/session.dat)
FOLDER=$(awk 'NR==1{print $8}' ./requests/session.dat)

for P in $MACHINES ; do touch ./results/information/$SCRIPTFOLDER/$FOLDER/$P.notepad ; done
sleep 1 ; echo $YT "Done." $GT
sleep 1 ; clear ; echo "Running connection loop.." ; sleep 1
#connection loop for ssh connection through sobox server to target host, run all commands and save output to local results text file.
for i in $MACHINES; do ssh -tA -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q -A ticket_id=9999@sls4root@10.224.64.69 --command sls -c root@$i "'logger -p auth.info "PHC MAINTENANCE - INFO GATHERING FOR CHANGE CREATION" &&date &&echo &&echo &&hostname &&echo &&echo &&echo **************CONTENTS OF APPLICATIONS FOLDER************** &&echo &&echo &&ls -l /applications&&echo &&echo &&echo *******UPTIME****** &&echo &&echo &&uptime &&echo &&echo &&echo ******INSTALLED SERVICES****** &&echo &&cat /var/db/var/installed_x_services &&echo &&echo &&echo *******DISKSPACE DETAILS********* &&echo &&echo && $COMMAND4 &&echo &&echo &&echo ********OSLEVEL DETAILS*******  &&echo &&echo &&uname -a &&echo && $COMMAND1 &&echo &&echo && $COMMAND3  &&echo &&echo &&echo ******ALL FUNCTIONS AND LEVEL********* &&echo&&echo&& $COMMAND2&&echo '""" > ./results/information/$SCRIPTFOLDER/$FOLDER/$i.notepad ; done ;

#enter password for zip encryption, zip the contents of this request, and email the zip file to the email above
echo $YT " here you should twice type the encryption password for your output..." $GT
zip -e -m ./results/information/$SCRIPTFOLDER/$FOLDER/OUT-$FEMAIL.zip ./results/information/$SCRIPTFOLDER/$FOLDER/*.notepad
echo
mutt -a "./results/information/$SCRIPTFOLDER/$FOLDER/OUT-$FEMAIL.zip" -s "$SCRIPT info for $MACHINES" < /dev/null -- $FEMAIL;
clear
printf "%s\n\n" "$(tail -n +2 ./requests/presession.dat)" > ./requests/presession.dat
echo
echo "The request to run $YT $SCRIPT $GT for $YT $MACHINES $GT has been sent directly to $YT $FEMAIL $GT . Would you like to run this again? $YT (y/n )" $GT
read ANSWERAGAIN
if [ $ANSWERAGAIN = "y" ]
then 
   ./request1.sh
elif [ $ANSWERAGAIN = "n" ]   
then 
   echo ; echo ; echo "Taking you to the prompt"... ; sleep 2 ; exit 0 ; 

else 
   exit 0
fi






