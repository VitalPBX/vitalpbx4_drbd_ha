#!/bin/bash
# This code is the property of VitalPBX LLC Company
# License: Proprietary
# Date: 8-Agu-2023
# VitalPBX Hight Availability with DRBD, Corosync, PCS, Pacemaker
#
set -e
function jumpto
{
    label=$start
    cmd=$(sed -n "/$label:/{:a;n;p;ba};" $0 | grep -v ':$')
    eval "$cmd"
    exit
}

echo -e "\n"
echo -e "************************************************************"
echo -e "*  Welcome to the VitalPBX high availability installation  *"
echo -e "*                All options are mandatory                 *"
echo -e "************************************************************"

filename="config.txt"
if [ -f $filename ]; then
	echo -e "config file"
	n=1
	while read line; do
		case $n in
			1)
				ip_master=$line
  			;;
			2)
				ip_standby=$line
  			;;
			3)
				ip_floating=$line
  			;;
			4)
				ip_floating_mask=$line
  			;;
			5)
				disk=$line
  			;;
			6)
				hapassword=$line
  			;;
		esac
		n=$((n+1))
	done < $filename
	echo -e "IP Server1............... > $ip_master"	
	echo -e "IP Server2............... > $ip_standby"
	echo -e "Floating IP.............. > $ip_floating "
	echo -e "Floating IP Mask (SIDR).. > $ip_floating_mask"
 	echo -e "Disk (sdax).............. > $disk"
	echo -e "hacluster password....... > $hapassword"
fi

while [[ $ip_master == '' ]]
do
    read -p "IP Server1............... > " ip_master 
done 

while [[ $ip_standby == '' ]]
do
    read -p "IP Server2............... > " ip_standby 
done

while [[ $ip_floating == '' ]]
do
    read -p "Floating IP.............. > " ip_floating 
done 

while [[ $ip_floating_mask == '' ]]
do
    read -p "Floating IP Mask (SIDR).. > " ip_floating_mask
done

while [[ $disk == '' ]]
do
    read -p "Disk (sdax).............. > " disk 
done 

while [[ $hapassword == '' ]]
do
    read -p "hacluster password....... > " hapassword 
done

echo -e "************************************************************"
echo -e "*                   Check Information                      *"
echo -e "*        Make sure you have internet on both servers       *"
echo -e "************************************************************"
while [[ $veryfy_info != yes && $veryfy_info != no ]]
do
    read -p "Are you sure you want to delete the Cluster?? (yes,no) > " veryfy_info 
done

if [ "$veryfy_info" = yes ] ;then
	echo -e "************************************************************"
	echo -e "*                Starting to run the scripts               *"
	echo -e "************************************************************"
else
    echo "Nothing to do, bye, bye"
    exit;
fi

echo -e "************************************************************"
echo -e "*            Get the hostname in Master and Standby         *"
echo -e "************************************************************"
host_master=`hostname`
host_standby=`ssh root@$ip_standby 'hostname'`
echo -e "$host_master"
echo -e "$host_standby"
echo -e "*** Done ***"

# Print a warning message destroy cluster message
echo -e "*****************************************************************"
echo -e "*  \e[41m WARNING-WARNING-WARNING-WARNING-WARNING-WARNING-WARNING  \e[0m   *"
echo -e "*  This process completely destroys the cluster on both servers *"
echo -e "*          then you can re-create it with the command           *"
echo -e "*                     ./vpbxha.sh rebuild                       *"
echo -e "*****************************************************************"
while [[ $veryfy_destroy != yes && $veryfy_destroy != no ]]
do
read -p "Are you sure you want to completely destroy the cluster? (yes, no) > " veryfy_destroy 
done
if [ "$veryfy_destroy" = yes ] ;then
    	echo -e "************************************************************"
	echo -e "*                   Destroy Cluster                        *"
	echo -e "************************************************************"  
  	pcs cluster stop
	pcs cluster destroy
	systemctl disable pcsd.service 
	systemctl disable corosync.service 
	systemctl disable pacemaker.service
	systemctl stop pcsd.service 
	systemctl stop corosync.service 
	systemctl stop pacemaker.service
  	ssh root@$ip_standby "pcs cluster stop --force"
      	ssh root@$ip_standby "pcs cluster destroy"
      	ssh root@$ip_standby "systemctl disable pcsd.service"
      	ssh root@$ip_standby "systemctl disable corosync.service"
      	ssh root@$ip_standby "systemctl disable pacemaker.service"
      	ssh root@$ip_standby "systemctl stop pcsd.service"
      	ssh root@$ip_standby "systemctl stop corosync.service"
      	ssh root@$ip_standby "systemctl stop pacemaker.service"
      	echo -e "************************************************************"
	echo -e "*                     DRBD Master Mount                    *"
	echo -e "************************************************************"
  	drbdadm up drbd0
      	drbdadm primary drbd0 --force
      	mount /dev/drbd0 /vpbx_data
	echo -e "************************************************************"
	echo -e "*            Creating Welcome message original             *"
	echo -e "************************************************************"
	wget https://raw.githubusercontent.com/VitalPBX/vitalpbx4_drbd_ha/main/welcome
    	yes | cp -fr welcome /etc/update-motd.d/20-vitalpbx
	chmod 755 /etc/update-motd.d/20-vitalpbx
	echo -e "*** Done ***"
	scp /etc/update-motd.d/20-vitalpbx root@$ip_standby:/etc/update-motd.d/20-vitalpbx
	ssh root@$ip_standby "chmod 755 /etc/update-motd.d/20-vitalpbx"
  	rm -rf /usr/local/bin/bascul		
	rm -rf /usr/local/bin/role
  	rm -rf /usr/local/bin/drbdsplit
	ssh root@$ip_standby "rm -rf /usr/local/bin/bascul"
	ssh root@$ip_standby "rm -rf /usr/local/bin/role"
  	ssh root@$ip_standby "rm -rf /usr/local/bin/drbdsplit"
	echo -e "************************************************************"
	echo -e "*                      Enable Services                     *"
	echo -e "************************************************************"   
    	systemctl enable asterisk
	systemctl restart asterisk
    	systemctl enable mariadb
    	systemctl restart mariadb
    	systemctl enable fail2ban
	systemctl restart fail2ban
      	systemctl enable vpbx-monitor
	systemctl restart vpbx-monitor
  	ssh root@$ip_standby "systemctl enable asterisk"
      	ssh root@$ip_standby "systemctl restart asterisk"
  	ssh root@$ip_standby "systemctl enable mariadb"
  	ssh root@$ip_standby "systemctl restart mariadb"
  	ssh root@$ip_standby "systemctl enable fail2ban"
  	ssh root@$ip_standby "systemctl enable vpbx-monitor"
	ssh root@$ip_standby "systemctl restart fail2ban"
  	ssh root@$ip_standby "systemctl restart vpbx-monitor"
    	echo -e "************************************************************"
	echo -e "*            Cluster destroyed successfully                *"
  	echo -e "*     Remember that because the disk partition where       *"
    	echo -e "*    the system is installed is much smaller than          *"
      	echo -e "*           the partition where the data is,               *"
	echo -e "*   	  it is not possible to remove the DRBD.            *"
	echo -e "************************************************************"
else
    	echo "Nothing to do, bye, bye"
fi
