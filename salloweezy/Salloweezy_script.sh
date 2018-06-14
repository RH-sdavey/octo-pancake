#!/bin/bash
clear
echo "give me directory name"
read dir_var
echo "give me a fielname"
read file_var
mkdir -p /tmp/$dir_var
cd /tmp/$dir_var
pwd 
touch $file_var
ls -la
sleep 5
clear
echo "have a look at /tmp/tmp_contents"
ls -la /boot >> /tmp/tmp_contents
sleep 5
echo "have a look at /tmp/passwd"
cat /etc/passwd > /tmp/passwd
sleep 5
echo "have a look at /tmp/processes"
ps -ef | tail > /tmp/processes
exit

