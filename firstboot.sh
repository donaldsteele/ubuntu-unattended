#!/bin/bash

#exe() { "$@" 2>&1 >> /root/firstboot.log; }
logfile=firstboot.log
exec > $logfile 2>&1

apt-get update 
apt-get -y upgrade

apt-get -y install php-cli curl build-essential
cd /
mount /dev/cdrom /mnt
cd /mnt
./VBoxLinuxAdditions.run


/bin/cat /etc/crontab | /bin/grep -v firstboot > /etc/crontab.tmp
/bin/rm -f /etc/crontab
/bin/mv /etc/crontab.tmp /etc/crontab
#rm -f $0

shutdown -h now
