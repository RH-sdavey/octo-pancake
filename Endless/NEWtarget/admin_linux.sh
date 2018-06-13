#!/bin/sh
clear
echo
echo $XT "Admin Info for Linux machines" $GT
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
mkdir ./results/information/admin_linux/$DATENUMBER
echo "Script: admin_linux	User: $name	Email: $FEMAIL	Folder: $DATENUMBER	MACHINES: $MACHINES	Date: $DATEFORLOG">> ./logfile.dat ;
echo "Script: admin_linux	User: $name	Email: $FEMAIL	Folder: $DATENUMBER	MACHINES: $MACHINES	Date: $DATEFORLOG">> ./requests/presession.dat ;
#connection loop for ssh connection through sobox server to target host, run all commands and save output to local results text file.
#for i in $MACHINES;do ssh -tA -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q -A ticket_id=9999@sls4root@10.224.64.69 --command sls -c root@$i "'logger -p auth.info "PHC MAINTENANCE - INFO GATHERING FOR CHANGE CREATION" && date&&echo&&echo&&hostname&&echo&&echo&&echo ********IFCONFIG*******&&ifconfig -a&&echo &&echo &&echo **************CONTENTS OF APPLICATIONS FOLDER************** &&echo &&echo &&ls -l /applications&&echo &&echo &&echo **********THIS IS THE UPTIME************ &&echo &&echo &&uptime &&echo &&echo &&echo ***************ALL PROCESSES RUNNING NOW******************* &&echo &&echo &&ps -ef &&echo &&echo &&echo &&echo &&echo *****************OPEN PORT CONNECTIONS************* &&echo &echo &&netstat -a &&echo &&echo &&echo *********CRONTAB INFO******** &&echo &&echo &&crontab -l &&echo  &&echo &&echo ****MOUNT INFO******** &&echo &&echo &&mount &&echo &&echo &&echo ***********SHELLS********** &&echo &&cat /etc/shells &&echo &&echo &&echo ******INSTALLED SERVICES******* &&echo &&cat /var/db/var/installed_x_services &&echo &&echo &&echo *******DISKSPACE DETAILS********* &&echo &&echo && df -h /boot /usr /var /tmp /home / &&echo &&echo &&echo ********OSLEVEL DETAILS*******  &&echo &&echo &&uname -a &&echo &&grep ML /var/db/var/installed_x_services|tail -1 ;cat /etc/*release &&echo &&echo &&echo ******ALL FUNCTIONS AND LEVEL********* &&echo&&w&&echo&&echo&&rpm -qa&&echo '""" > ./results/information/admin_linux/$DATENUMBER/admin_$i.txt ; done ;
clear
echo 
#menu system#
#cat << EOF
 #
 #$YT OK, request done, what would you like to do with the output?$GT
# 
#  1) $RT Grep for a function$GT , and display it on this screen **wont be emailed to you, or saved** ( only 1 at the moment --work in progress )
#  2) $RT Email the output$GT to $YT $FEMAIL $GT
#  3) $RT Start again$GT from the beginning
#
 #$RT "choose a number:" $GT
#EOF
#read outputchoice
#echo
#grep for a function from the output
#if [ $outputchoice == "1" ]
#then echo $RT "which function please? :" $GT
#read funct
#for q in $MACHINES; do for f in $funct;do echo; echo $YT $q $GT;grep -ih -e $funct ./results/information/admin_linux/$DATENUMBER/admin_$q.txt;echo;echo;done;read -p "$YT Press any key to continue... $GT " -n1 -s; done; ./main.sh;
#enter password for zip encryption, zip the contents of this request, and email the zip file to the email above
#elif [ $outputchoice == "2" ] 
#echo $YT " here you should twice type the encryption password for your output...( security ) " $GT
#then zip -e -m ./results/information/admin_linux/$DATENUMBER/OUT-$FEMAIL.zip ./results/information/admin_linux/$DATENUMBER/*.*
#echo
#mutt -a "./results/information/admin_linux/$DATENUMBER/OUT-$FEMAIL.zip" -s "Admin Info for Linux $MACHINES" < /dev/null -- $FEMAIL 2>/dev/null;
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
#back to the main menu
#elif [ $outputchoice == "3" ] 
#then ./main.sh
#else echo "you messed up, taking you back to the start of this menu"; ./admin_linux.sh;
#fi

