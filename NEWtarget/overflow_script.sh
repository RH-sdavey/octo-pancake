#!/bin/sh
trap 'echo "# $BASH_COMMAND"' DEBUG

read MACHINES
read EMAIL
for i in $MACHINES;do ssh -tA -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q -A ticket_id=9999@sls4root@10.224.64.69 --command sls -c root@$i "'logger -p auth.info "PHC MAINTENANCE - MANUAL HEALTH CHECK"; find / -perm -2 ! -type f'" > ./results/overflow/overflow_$i.txt; echo "Overflow info for $i" | mutt -a "./results/overflow/overflow_$i.txt" -s "overflow report for $i" -- $EMAIL; done






#mutt -s "info about $i" $EMAIL < /home/seankdavey/Desktop/targets/overflow_$i.txt;  done
