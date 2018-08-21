#!/bin/bash


# script to get server ( laptop ) information into a text file,
# I will try a few techniques here to show you whats possible.

#set color variables for coloring text

FILENAME="$(hostname)_$(date +%F)_result.txt"
SP_LINE_SP="$(echo -e \n ========================================== \n )"

all_info () {
	touch $FILENAME
	printf "$(df -h)" >> $FILENAME
	printf  "$SP_LINE_SP"
	printf "$(ps -ef)" >> $FILENAME
}

function all_user_info () {
	new_line="========= \n"

	printf "who are you?\n: "&& whoami ; printf "$new_line"
	printf "id_info\n" && id ;printf "$new_line"
	printf "passwd details\n" && grep $(whoami) /etc/passwd ; printf "$new_line"
	printf "groups details\n" && groups $(whoami) ; printf "$new_line"
}

function query_pkg() {
	read -p "What package to query please?
	" pkg   #these two lines (29+30) are super hacky/shitty way to add a newline, not reccomended
	printf "\n Heres all the $pkg packages installed:\n"
	rpm -qa | grep $pkg  2>/dev/null
	printf "\n\n"
	read -p "Press ENTER to continue..."
	printf "\n\n And heres some info about that package ( if found ):\n"
	rpm -qi $pkg | more 2>/dev/null
}

function make_pass() {
	printf "\n\n Your generated passwords.... \n\n\n"
	for (( i = 0; i < 20; i++ )); do
		NUM=$(shuf -i1-100 -n1)
		WORDS=$(shuf -n 3 wordlist | tr '\n' '_')   #todo make this so it can be run from any dir, basedir?
		printf "$WORDS$NUM\n"
  done
}

function dmi_encode_func () {
cat << EOF
	Which hardware component do you want see detailed information about?
	1) memory
	2) system
	3) bios
	4) processor
	5) none, go back to main menu
EOF
read reply
case "$reply" in
	1) printf "\nmemory component information\n\n\n" ; sudo dmidecode -t memory ;;
	2) printf "\nsystem component information\n\n\n" ;sudo dmidecode -t system  ;;
	3) printf "\nbios component information\n\n\n" ;sudo dmidecode -t bios ;;
	2) printf "\nprocessor component information\n\n\n" ;sudo dmidecode -t processor ;;
	5) clear ; ./scripttest.sh ;;
esac
}

clear
printf "\n\n\n\n"
cat << EOF


███████╗███╗   ██╗██████╗ ██╗     ███████╗███████╗███████╗
██╔════╝████╗  ██║██╔══██╗██║     ██╔════╝██╔════╝██╔════╝
█████╗  ██╔██╗ ██║██║  ██║██║     █████╗  ███████╗███████╗
██╔══╝  ██║╚██╗██║██║  ██║██║     ██╔══╝  ╚════██║╚════██║
███████╗██║ ╚████║██████╔╝███████╗███████╗███████║███████║
╚══════╝╚═╝  ╚═══╝╚═════╝ ╚══════╝╚══════╝╚══════╝╚══════╝
                                                                                                      

EOF
cat << EOF
 1) All CPU Information
 2) Diskspace
 3) User Details
 4) Top 10 Processes
 5) Kernel details
 6) OS details
 7) Java details
 8) Query information on a package
 9) Mount points
 10) Network Interfaces
 11) Network and Wifi information (maybe you need sudo access)
 12) Block device information
 13) Detailed hardware component information (will need sudo access)
 s) Watch Star Wars  (ctrl + ] and then quit to quit!) .. will probably crash this script ¯\_(ツ)_/¯
 p) Password Generator
 q) Exit

"Choose a number:"

EOF

read choice
case "$choice" in

	1) clear ; printf "\n All your CPU information \n\n\n" ; lscpu ;  printf "\n\n" ; read -p "Press ENTER to go back to menu... (ctrl+c to quit)";;
	2) clear ; printf "\n All your free diskpace on different filesystems \n\n\n" ; df -h;  printf "\n\n" ;read -p "Press ENTER to go back to menu... (ctrl+c to quit)";;
	3) clear ; printf "\n All your user info for $(whoami) \n\n\n" ; all_user_info ; printf "\n\n" ;read -p "Press ENTER to go back to menu... (ctrl+c to quit)";;
	4) clear ; printf "\n Top 10 processes by cpu usage \n\n\n" ; top -b -n 1 | head -n 17 ; printf "\n\n" ; read -p "Press ENTER to go back to menu... (ctrl+c to quit)";;
	5) clear ; printf "\n Kernel version\n\n\n" ; uname -a ; printf "\n\n All kernel packages installed\n\n\n" ; rpm -qa | grep 'kernel' ; printf "\n\n" ; read -p "Press ENTER to go back to menu... (ctrl+c to quit)";;
	6) clear ; printf "\n OS details\n\n\n" ; cat /etc/*release* ; printf "\n\n" ; read -p "Press ENTER to go back to menu... (ctrl+c to quit)";;
	7) clear ; printf "\n Java Packages installed\n\n\n" ; rpm -qa | grep 'java' ; printf "\n\n Java version\n\n\n" ; java -version ; printf "\n\n" ; read -p "Press ENTER to go back to menu... (ctrl+c to quit)";;
	8) clear ; query_pkg ; printf "\n\n" ; read -p "Press ENTER to go back to menu... (ctrl+c to quit)";;
	9) clear ; printf "\nAll mount points\n\n\n" ; mount ;  printf "\n\n" ; read -p "Press ENTER to go back to menu... (ctrl+c to quit)";;
	10) clear ; printf "\nNetwork Interfaces\n\n\n" ; ifconfig ;  printf "\n\n" ; read -p "Press ENTER to go back to menu... (ctrl+c to quit)";;
	11) clear ; printf "\nNetwork / Wifi Info\n\n\n" ; nmcli device status  ; printf "\n==============\n" ; nmcli device wifi list ; printf "\n\n" ; read -p "Press ENTER to go back to menu... (ctrl+c to quit)";;
  12) clear ; printf "\nAll block device details\n\n\n" ; lsblk -a ;  printf "\n\n" ; read -p "Press ENTER to go back to menu... (ctrl+c to quit)";;
	s) clear ; telnet towel.blinkenlights.nl ;;
	13) clear ; dmi_encode_func ;  printf "\n\n" ; read -p "Press ENTER to go back to menu... (ctrl+c to quit)";;
	p) clear ; make_pass ; printf "\n\n" ; read -p "Press ENTER to go back to menu... (ctrl+c to quit)";;
	q) clear ; printf "\nBye\n" exit; exit 0;;
	*) printf "Unknown command, please choose a number 1-4 or q to quit";;

esac
clear ; ./scripttest.sh
