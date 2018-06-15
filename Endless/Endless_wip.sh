#!/bin/bash

#make everything clean before we begin
clear
rm results.txt
touch results.txt

# fixed variables here
line="=============================================================="

function draw_line_to_result {
echo -e "\n $line \n" >> results.txt
}
FILENAME="$(hostname)_$(date +%F)_$(whoami).txt"
touch $FILENAME
exit


# code begins here
    # Print message in center of terminal
    cols=$( tput cols )
    rows=$( tput lines )
    message=$@
    input_length=${#message}
    half_input_length=$(( $input_length / 2 ))
    middle_row=$(( $rows / 2 ))
    middle_col=$(( ($cols / 2) - $half_input_length - 60 ))

function prog_bar {

    tput cup $middle_row $middle_col
    tput bold
echo "starting to gather info now"
    tput cup $middle_row $middle_col
    tput bold
echo -ne '[################                                                            (20%)\r]'
sleep 1
    tput cup $middle_row $middle_col
    tput bold
echo -ne '[###########################                                                 (40%)\r]'
sleep 1
    tput cup $middle_row $middle_col
    tput bold
echo -ne '[#####################################                                       (60%)\r]'
ps -ef >> result.txt
    tput cup $middle_row $middle_col
    tput bold
echo -ne '[#####################################################                       (70%)\r]'
sleep 1
    tput cup $middle_row $middle_col
    tput bold
echo -ne '[################################################################            (80%)\r]'
sleep 1
    tput cup $middle_row $middle_col
    tput bold
echo -ne '[###########################################################################(100%)\r]'
    tput sgr0
    tput cup $( tput lines ) 0
}


  draw_line_to_result
  tput cup $middle_row ; echo "gathering diskspace details" ; df -h >> $FILENAME ; draw_line_to_result ;  tput cup $middle_row $middle_col; tput bold ; prog_bar ; echo ;
  tput cup $middle_row ; echo "gathering user details" ;grep $(whoami) /etc/passwd >> $FILENAME ; finger $(whoami) >> $FILENaME ;  draw_line_to_result ;tput cup $middle_row $middle_col;  tput bold ; prog_bar ; echo ; 
  tput cup $middle_row ; echo "gathering iostat details" ; iostat --human  >> $FILENAME ; draw_line_to_result ;tput cup $middle_row $middle_col;  tput bold ; prog_bar ; echo ; 

cat $FILENAME


