#!/bin/bash
clear
echo
echo $XT "LSSecFix / Harvester output" $GT
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
echo "Script: lssecfix	User: $name	Email: $FEMAIL	Folder: $DATENUMBER	MACHINES: $MACHINES	Date: $DATEFORLOG">> ./logfile.dat ;
echo "Script: lssecfix	User: $name	Email: $FEMAIL	Folder: $DATENUMBER	MACHINES: $MACHINES	Date: $DATEFORLOG">> ./requests/presession.dat ;
clear
echo 
echo
echo $GT "The request has been sent to $RT Sean Davey $GT , he will send the results directly to $YT $FEMAIL $GT soon." $GT
echo 
sleep 1
echo $YT "Taking you back to the main menu now..." $GT
sleep 2
./main.sh

