#!/bin/bash

MACHINES=$(cat ./requests/session.dat | grep -o -P '(?<=MACHINES: ).*(?=Date:)' | head -1)
USER=$(awk 'NR==1{print $4}' ./requests/session.dat)
FEMAIL=$(awk 'NR==1{print $6}' ./requests/session.dat)
FOLDER=$(awk 'NR==1{print $8}' ./requests/session.dat)
DATENUMBER="$(date +%j%s)"
DATEFORLOG="$(date)"


for i in $MACHINES;do echo ""[czz61975@oc2318074560 ~]$ ssh -tA -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q -A ticket_id=9999@sls4root@10.224.64.69 --command sls -c root@$i "'logger -p auth.info "PHC MAINTENANCE - MANUAL HEALTH CHECK" &&echo&&hostname&&echo&&date&&echo&&ls -ld /var/applications/srm&& echo&&ls -ld /applications/srm&&echo&&ls -lR /var/applications/srm |grep -v root|grep -v perfmgr|grep -v tivadm&&echo&&ls -lR /applications/srm |grep -v root|grep -v perfmgr|grep -v tivadm &&echo&&cat /etc/passwd|grep -i srmcoll&&echo&&cat /etc/passwd|grep -i srmmgr'""" > ./results/man_hc/$DATENUMBER/man_hc_$i.txt && ssh -tA -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q -A ticket_id=9999@sls4root@10.224.64.69 --command sls -c root@$i "'logger -p auth.info "PHC MAINTANENCE - MANUAL HEALTH CHECK"&&echo&&hostname&&echo&&date&&echo&&ls -ld /var/applications/srm&& echo&&ls -ld /applications/srm&&echo&&ls -lR /var/applications/srm |grep -v root|grep -v perfmgr|grep -v tivadm&&echo&&ls -lR /applications/srm |grep -v root|grep -v perfmgr|grep -v tivadm &&echo&&cat /etc/passwd|grep -i srmcoll&&echo&&cat /etc/passwd|grep -i srmmgr'" >> ./results/man_hc/$DATENUMBER/man_hc_$i.txt && echo "[czz61974@oc2318074560 ~]$ " >> ./results/man_hc/$DATENUMBER/man_hc_$i.txt && fold ./results/man_hc/$DATENUMBER/man_hc_$i.txt > ./results/man_hc/$DATENUMBER/man_hc_$i_new.txt | convert -font Helvetica -style Normal -background none -undercolor black -fill "#00FF00" -pointsize 16 -page 800x2400+0+0 -background black -flatten ./results/man_hc/$DATENUMBER/man_hc_$i_new.txt ./results/man_hc/$DATENUMBER/man_hc_$i.png; rm -fr ./results/man_hc/$DATENUMBER/man_hc_$i_new.txt; done

echo $YT " here you should twice type the encryption password for your output...( security ) " $GT
then zip -e -m ./results/man_hc/$DATENUMBER/OUT-$FEMAIL.zip ./results/man_hc/$DATENUMBER/*.*
echo "The output will go directly to Jana Kysklosova, SARM team and Secmon team. Ping them to let them know its on the way."
sleep 2
echo
mutt -a "./results/man_hc/$DATENUMBER/OUT-$FEMAIL.zip" -s "Manual Healthcheck for $i" < /dev/null -- jana_kyklosova@cz.ibm.com -c SECMON@de.ibm.com -c SRMIT5BRNO@cz.ibm.com -c sean_davey@cz.ibm.com 2>/dev/null;
clear
echo
echo $YT "The output has been sent, taking you back to the main menu..." $GT
sleep 5
./main.sh
exit 0
