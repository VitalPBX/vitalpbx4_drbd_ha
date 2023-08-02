#!/bin/bash
# This code is the property of VitalPBX LLC Company
# License: Proprietary
# Date: 1-Agu-2023
# VitalPBX Hight Availability with MariaDB Replica, Corosync, PCS, Pacemaker and Lsync
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
				hapassword=$line
  			;;
		esac
		n=$((n+1))
	done < $filename
	echo -e "IP Server1............... > $ip_master"	
	echo -e "IP Server2............... > $ip_standby"
	echo -e "Floating IP.............. > $ip_floating "
	echo -e "Floating IP Mask (SIDR).. > $ip_floating_mask"
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
    read -p "Are you sure to continue with this settings? (yes,no) > " veryfy_info 
done

if [ "$veryfy_info" = yes ] ;then
	echo -e "************************************************************"
	echo -e "*                Starting to run the scripts               *"
	echo -e "************************************************************"
else
    	exit;
fi

cat > config.txt << EOF
$ip_master
$ip_standby
$ip_floating
$ip_floating_mask
$hapassword
EOF

echo -e "************************************************************"
echo -e "*            Get the hostname in Master and Standby         *"
echo -e "************************************************************"
host_master=`hostname -f`
host_standby=`ssh root@$ip_standby 'hostname -f'`
echo -e "$host_master"
echo -e "$host_standby"
echo -e "*** Done ***"

echo -e "Start in step: " $step

start="create_hostname"
case $step in
	1)
		start="create_hostname"
  	;;
	2)
		start="rename_tenant_id_in_server2"
  	;;
	3)
		start="configuring_firewall"
  	;;
	4)
		start="create_lsyncd_config_file"
  	;;
	5)
		start="create_mariadb_replica"
	;;
	6)
		start="create_hacluster_password"
  	;;
	7)
		start="starting_pcs"
  	;;
	8)
		start="auth_hacluster"
  	;;
	9)
		start="creating_cluster"
  	;;
	10)
		start="starting_cluster"
  	;;
	11)
		start="creating_floating_ip"
  	;;
	12)
		start="disable_services"
	;;
	13)
		start="create_asterisk_service"
	;;
	14)
		start="create_lsyncd_service"
	;;
	15)
		start="vitalpbx_create_bascul"
	;;
	16)
		start="vitalpbx_create_role"
	;;
	17)
		start="vitalpbx_create_mariadbfix"
	;;
	18)
		start="ceate_welcome_message"
	;;
esac
jumpto $start
echo -e "*** Done Step 1 ***"
echo -e "1"	> step.txt

create_hostname:
echo -e "************************************************************"
echo -e "*          Creating hosts name in Master/Standby           *"
echo -e "************************************************************"
echo -e "$ip_master \t$host_master" >> /etc/hosts
echo -e "$ip_standby \t$host_standby" >> /etc/hosts
ssh root@$ip_standby "echo -e '$ip_master \t$host_master' >> /etc/hosts"
ssh root@$ip_standby "echo -e '$ip_standby \t$host_standby' >> /etc/hosts"
echo -e "*** Done Step 2 ***"
echo -e "2"	> step.txt

rename_tenant_id_in_server2:
echo -e "************************************************************"
echo -e "*                Remove Tenant in Server 2                 *"
echo -e "************************************************************"
remote_tenant_id=`ssh root@$ip_standby "ls /var/lib/vitalpbx/static/"`
ssh root@$ip_standby "rm -rf /var/lib/vitalpbx/static/$remote_tenant_id"
scp /etc/vitalpbx/vitalpbx-maint.conf root@$ip_standby:/etc/vitalpbx/vitalpbx-maint.conf
echo -e "*** Done Step 3 ***"
echo -e "3"	> step.txt

configuring_firewall:
echo -e "************************************************************"
echo -e "*             Configuring Temporal Firewall                *"
echo -e "************************************************************"
#Create temporal Firewall Rules in Server 1 and 2
firewall-cmd --permanent --add-service=high-availability
firewall-cmd --reload
ssh root@$ip_standby "firewall-cmd --permanent --add-service=high-availability"
ssh root@$ip_standby "firewall-cmd --reload"

echo -e "************************************************************"
echo -e "*             Configuring Permanent Firewall               *"
echo -e "*   Creating Firewall Services in VitalPBX in Server 1     *"
echo -e "************************************************************"
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_services (name, protocol, port) VALUES ('HA2224', 'tcp', '2224')"
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_services (name, protocol, port) VALUES ('HA3121', 'tcp', '3121')"
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_services (name, protocol, port) VALUES ('HA5403', 'tcp', '5403')"
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_services (name, protocol, port) VALUES ('HA5404-5405', 'udp', '5404-5405')"
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_services (name, protocol, port) VALUES ('HA21064', 'tcp', '21064')"
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_services (name, protocol, port) VALUES ('HA9929', 'both', '9929')"
echo -e "************************************************************"
echo -e "*             Configuring Permanent Firewall               *"
echo -e "*     Creating Firewall Rules in VitalPBX in Server 1      *"
echo -e "************************************************************"
last_index=$(mysql -uroot ombutel -e "SELECT MAX(\`index\`) AS Consecutive FROM ombu_firewall_rules"  | awk 'NR==2')
last_index=$last_index+1
service_id=$(mysql -uroot ombutel -e "select firewall_service_id from ombu_firewall_services where name = 'HA2224'" | awk 'NR==2')
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_master', 'accept', $last_index)"
last_index=$last_index+1
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_standby', 'accept', $last_index)"
last_index=$last_index+1
service_id=$(mysql -uroot ombutel -e "select firewall_service_id from ombu_firewall_services where name = 'HA3121'" | awk 'NR==2')
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_master', 'accept', $last_index)"
last_index=$last_index+1
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_standby', 'accept', $last_index)"
last_index=$last_index+1
service_id=$(mysql -uroot ombutel -e "select firewall_service_id from ombu_firewall_services where name = 'HA5403'" | awk 'NR==2')
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_master', 'accept', $last_index)"
last_index=$last_index+1
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_standby', 'accept', $last_index)"
last_index=$last_index+1
service_id=$(mysql -uroot ombutel -e "select firewall_service_id from ombu_firewall_services where name = 'HA5404-5405'" | awk 'NR==2')
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_master', 'accept', $last_index)"
last_index=$last_index+1
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_standby', 'accept', $last_index)"
last_index=$last_index+1
service_id=$(mysql -uroot ombutel -e "select firewall_service_id from ombu_firewall_services where name = 'HA21064'" | awk 'NR==2')
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_master', 'accept', $last_index)"
last_index=$last_index+1
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_arbitrator', 'accept', $last_index)"
last_index=$last_index+1
service_id=$(mysql -uroot ombutel -e "select firewall_service_id from ombu_firewall_services where name = 'HA9929'" | awk 'NR==2')
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_master', 'accept', $last_index)"
last_index=$last_index+1
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_standby', 'accept', $last_index)"
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_whitelist (host, description, \`default\`) VALUES ('$ip_master', 'Server 1 IP', 'no')"
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_whitelist (host, description, \`default\`) VALUES ('$ip_standby', 'Server 2 IP', 'no')"
echo -e "*** Done Step 4 ***"
echo -e "4"	> step.txt

create_hacluster_password:
echo -e "************************************************************"
echo -e "*     Create password for hacluster in Master/Standby      *"
echo -e "************************************************************"
echo hacluster:$hapassword | chpasswd
ssh root@$ip_standby "echo hacluster:$hapassword | chpasswd"
echo -e "*** Done Step 5 ***"
echo -e "5"	> step.txt

starting_pcs:
echo -e "************************************************************"
echo -e "*         Starting pcsd services in Master/Standby         *"
echo -e "************************************************************"
systemctl start pcsd
ssh root@$ip_standby "systemctl start pcsd"
systemctl enable pcsd.service 
systemctl enable corosync.service 
systemctl enable pacemaker.service
ssh root@$ip_standby "systemctl enable pcsd.service"
ssh root@$ip_standby "systemctl enable corosync.service"
ssh root@$ip_standby "systemctl enable pacemaker.service"
echo -e "*** Done Step 6 ***"
echo -e "6"	> step.txt

auth_hacluster:
echo -e "************************************************************"
echo -e "*            Server Authenticate in Master                 *"
echo -e "************************************************************"
pcs cluster destroy
pcs host auth $host_master $host_standby -u hacluster -p $hapassword
echo -e "*** Done Step 7 ***"
echo -e "7"	> step.txt

creating_cluster:
echo -e "************************************************************"
echo -e "*              Creating Cluster in Master                  *"
echo -e "************************************************************"
pcs cluster setup cluster_vitalpbx $host_master $host_standby --force
echo -e "*** Done Step 8 ***"
echo -e "8"	> step.txt

starting_cluster:
echo -e "************************************************************"
echo -e "*              Starting Cluster in Master                  *"
echo -e "************************************************************"
pcs cluster start --all
pcs cluster enable --all
pcs property set stonith-enabled=false
pcs property set no-quorum-policy=ignore
echo -e "*** Done Step 9 ***"
echo -e "9"	> step.txt

creating_floating_ip:
echo -e "************************************************************"
echo -e "*            Creating Floating IP in Master                *"
echo -e "************************************************************"
pcs resource create virtual_ip ocf:heartbeat:IPaddr2 ip=$ip_floating cidr_netmask=$ip_floating_mask op monitor interval=30s on-fail=restart
pcs cluster cib drbd_cfg
pcs cluster cib-push drbd_cfg
echo -e "*** Done Step 10 ***"
echo -e "10"	> step.txt

create_drbd_resource:
echo -e "************************************************************"
echo -e "*             Create drbd resource in Server 1             *"
echo -e "************************************************************"
pcs -f drbd_cfg resource create DrbdData ocf:linbit:drbd drbd_resource=drbd0 op monitor interval=60s
pcs -f drbd_cfg resource promotable DrbdData promoted-max=1 promoted-node-max=1 clone-max=2 clone-node-max=1 notify=true
pcs cluster cib-push drbd_cfg 
echo -e "*** Done Step 11 ***"
echo -e "11"	> step.txt

create_filesystem_resource:
echo -e "************************************************************"
echo -e "*         Create filesystem resource in Server 1           *"
echo -e "************************************************************"
pcs cluster cib fs_cfg
pcs -f fs_cfg resource create DrbdFS Filesystem device="/dev/drbd0" directory="/mnt" fstype="xfs" 
pcs -f fs_cfg constraint colocation add DrbdFS with DrbdData-clone INFINITY with-rsc-role=Master 
pcs -f fs_cfg constraint order promote DrbdData-clone then start DrbdFS
pcs -f fs_cfg constraint colocation add DrbdFS with virtual_ip INFINITY
pcs -f fs_cfg constraint order virtual_ip then DrbdFS
pcs cluster cib-push fs_cfg 
echo -e "*** Done Step 12 ***"
echo -e "12"	> step.txt

disable_services:
echo -e "************************************************************"
echo -e "*             Disable Services in Server 1 and 2           *"
echo -e "************************************************************"
systemctl stop mariadb
systemctl disable mariadb
systemctl stop fail2ban
systemctl disable fail2ban
systemctl disable asterisk
systemctl stop asterisk
systemctl stop vpbx-monitor
systemctl disable vpbx-monitor
ssh root@$ip_standby "systemctl disable mariadb"
ssh root@$ip_standby "systemctl stop mariadb"
ssh root@$ip_standby "systemctl disable fail2ban"
ssh root@$ip_standby "systemctl stop fail2ban"
ssh root@$ip_standby "systemctl disable asterisk"
ssh root@$ip_standby "systemctl stop asterisk"
ssh root@$ip_standby "systemctl disable vpbx-monitor"
ssh root@$ip_standby "systemctl stop vpbx-monitor"
echo -e "*** Done Step 13 ***"
echo -e "13"	> step.txt

create_mariadb_service:
echo -e "************************************************************"
echo -e "*          Create asterisk Service in Server 1             *"
echo -e "************************************************************"
mkdir /mnt/mysql
mkdir /mnt/mysql/data
chown mysql:mysql /mnt/mysql
chown mysql:mysql /mnt/mysql/data
cp -aR /var/lib/mysql/* /mnt/mysql/data
sed -i 's/var\/lib\/mysql/mnt\/mysql\/data/g' /etc/mysql/mariadb.conf.d/50-server.cnf
pcs resource create mysql ocf:heartbeat:mysql binary="/usr/bin/mysqld_safe" config="/etc/mysql/mariadb.conf.d/50-server.cnf" datadir="/mnt/mysql/data" pid="/var/lib/mysql/mysql.pid" socket="/var/lib/mysql/mysql.sock" additional_parameters="--bind-address=0.0.0.0" op start timeout=60s op stop timeout=60s op monitor interval=20s timeout=30s on-fail=standby 
pcs cluster cib fs_cfg
pcs cluster cib-push fs_cfg --config
pcs -f fs_cfg constraint colocation add mysql with virtual_ip INFINITY
pcs -f fs_cfg constraint order DrbdFS then mysql
pcs cluster cib-push fs_cfg --config
echo -e "*** Done Step 14 ***"
echo -e "14"	> step.txt

create_asterisk_service:
echo -e "************************************************************"
echo -e "*          Create asterisk Service in Server 1             *"
echo -e "************************************************************"
pcs resource create asterisk service:asterisk op monitor interval=30s
pcs cluster cib fs_cfg
pcs cluster cib-push fs_cfg --config
pcs -f fs_cfg constraint colocation add asterisk with virtual_ip INFINITY
pcs -f fs_cfg constraint order mysql then asterisk
pcs cluster cib-push fs_cfg --config
#Changing these values from 15s (default) to 120s is very important 
#since depending on the server and the number of extensions 
#the Asterisk can take more than 15s to start
pcs resource update asterisk op stop timeout=120s
pcs resource update asterisk op start timeout=120s
pcs resource update asterisk op restart timeout=120s
echo -e "*** Done Step 15 ***"
echo -e "15"	> step.txt

vitalpbx_create_bascul:
echo -e "************************************************************"
echo -e "*         Creating VitalPBX Cluster bascul Command         *"
echo -e "************************************************************"
wget https://raw.githubusercontent.com/VitalPBX/vitalpbx4_drbd_ha/main/bascul
yes | cp -fr bascul /usr/local/bin/bascul
chmod +x /usr/local/bin/bascul
scp /usr/local/bin/bascul root@$ip_standby:/usr/local/bin/bascul
ssh root@$ip_standby 'chmod +x /usr/local/bin/bascul'
echo -e "*** Done Step 16 ***"
echo -e "16"	> step.txt

vitalpbx_create_role:
echo -e "************************************************************"
echo -e "*         Creating VitalPBX Cluster role Command           *"
echo -e "************************************************************"
wget https://raw.githubusercontent.com/VitalPBX/vitalpbx4_drbd_ha/main/role
yes | cp -fr role /usr/local/bin/role
chmod +x /usr/local/bin/role
scp /usr/local/bin/role root@$ip_standby:/usr/local/bin/role
ssh root@$ip_standby 'chmod +x /usr/local/bin/role'
echo -e "*** Done Step 17 ***"
echo -e "17"	> step.txt

vitalpbx_create_mariadbfix:
echo -e "************************************************************"
echo -e "*           Creating VitalPBX mariadbfix Command           *"
echo -e "************************************************************"
wget https://raw.githubusercontent.com/VitalPBX/vitalpbx4_drbd_ha/main/drbdsplit
yes | cp -fr mariadbfix /usr/local/bin/drbdsplit
yes | cp -fr config.txt /usr/local/bin/config.txt
chmod +x /usr/local/bin/mariadbfix
echo -e "*** Done Step 18 ***"
echo -e "18"	> step.txt

ceate_welcome_message:
echo -e "************************************************************"
echo -e "*              Creating Welcome message                    *"
echo -e "************************************************************"
/bin/cp -rf /usr/local/bin/role /etc/update-motd.d/20-vitalpbx
chmod 755 /etc/update-motd.d/20-vitalpbx
echo -e "*** Done ***"
scp /etc/update-motd.d/20-vitalpbx root@$ip_standby:/etc/update-motd.d/20-vitalpbx
ssh root@$ip_standby "chmod 755 /etc/update-motd.d/20-vitalpbx"
echo -e "*** Done Step 19 END ***"
echo -e "19"	> step.txt

vitalpbx_cluster_ok:
echo -e "************************************************************"
echo -e "*                VitalPBX Cluster OK                       *"
echo -e "*    Don't worry if you still see the status in Stop       *"
echo -e "*  sometimes you have to wait about 30 seconds for it to   *"
echo -e "*                 restart completely                       *"
echo -e "*         after 30 seconds run the command: role           *"
echo -e "************************************************************"
sleep 20
role
