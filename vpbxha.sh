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

arg=$1
if [ "$arg" = 'destroy' ] ;then

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
		pcs cluster stop
		pcs cluster destroy
		systemctl disable pcsd.service 
		systemctl disable corosync.service 
		systemctl disable pacemaker.service
		systemctl stop pcsd.service 
		systemctl stop corosync.service 
		systemctl stop pacemaker.service

wget https://raw.githubusercontent.com/VitalPBX/vitalpbx_ha_v4/main/welcome
yes | cp -fr welcome /etc/update-motd.d/20-vitalpbx
chmod 755 /etc/update-motd.d/20-vitalpbx
scp /etc/update-motd.d/20-vitalpbx root@$ip_standby:/etc/update-motd.d/20-vitalpbx
ssh root@$ip_standby "chmod 755 /etc/update-motd.d/20-vitalpbx"
rm -rf /usr/local/bin/bascul		
rm -rf /usr/local/bin/role
ssh root@$ip_standby "rm -rf /usr/local/bin/bascul"
ssh root@$ip_standby "rm -rf /usr/local/bin/role"
echo -e "************************************************************"
echo -e "*         Remove Firewall Services/Rules in Mariadb        *"
echo -e "************************************************************"
service_id=$(mysql -uroot ombutel -e "select firewall_service_id from ombu_firewall_services where name = 'MariaDB Client'" | awk 'NR==2')
mysql -uroot ombutel -e "DELETE FROM ombu_firewall_rules WHERE firewall_service_id = $service_id"
service_id=$(mysql -uroot ombutel -e "select firewall_service_id from ombu_firewall_services where name = 'HA2224'" | awk 'NR==2')
mysql -uroot ombutel -e "DELETE FROM ombu_firewall_rules WHERE firewall_service_id = $service_id"
service_id=$(mysql -uroot ombutel -e "select firewall_service_id from ombu_firewall_services where name = 'HA3121'" | awk 'NR==2')
mysql -uroot ombutel -e "DELETE FROM ombu_firewall_rules WHERE firewall_service_id = $service_id"
service_id=$(mysql -uroot ombutel -e "select firewall_service_id from ombu_firewall_services where name = 'HA5403'" | awk 'NR==2')
mysql -uroot ombutel -e "DELETE FROM ombu_firewall_rules WHERE firewall_service_id = $service_id"
service_id=$(mysql -uroot ombutel -e "select firewall_service_id from ombu_firewall_services where name = 'HA5404-5405'" | awk 'NR==2')
mysql -uroot ombutel -e "DELETE FROM ombu_firewall_rules WHERE firewall_service_id = $service_id"
service_id=$(mysql -uroot ombutel -e "select firewall_service_id from ombu_firewall_services where name = 'HA21064'" | awk 'NR==2')
mysql -uroot ombutel -e "DELETE FROM ombu_firewall_rules WHERE firewall_service_id = $service_id"
service_id=$(mysql -uroot ombutel -e "select firewall_service_id from ombu_firewall_services where name = 'HA9929'" | awk 'NR==2')
mysql -uroot ombutel -e "DELETE FROM ombu_firewall_rules WHERE firewall_service_id = $service_id"
mysql -uroot ombutel -e "DELETE FROM ombu_firewall_whitelist WHERE description = 'Server 1 IP'"
mysql -uroot ombutel -e "DELETE FROM ombu_firewall_whitelist WHERE description = 'Server 2 IP'"
mysql -uroot ombutel -e "DELETE FROM ombu_firewall_services WHERE name = 'MariaDB Client'"
mysql -uroot ombutel -e "DELETE FROM ombu_firewall_services WHERE name = 'HA2224'"
mysql -uroot ombutel -e "DELETE FROM ombu_firewall_services WHERE name = 'HA3121'"
mysql -uroot ombutel -e "DELETE FROM ombu_firewall_services WHERE name = 'HA5403'"
mysql -uroot ombutel -e "DELETE FROM ombu_firewall_services WHERE name = 'HA5404-5405'"
mysql -uroot ombutel -e "DELETE FROM ombu_firewall_services WHERE name = 'HA21064'"
mysql -uroot ombutel -e "DELETE FROM ombu_firewall_services WHERE name = 'HA9929'"
cat > /etc/mysql/mariadb.conf.d/50-server.cnf << EOF
#
# These groups are read by MariaDB server.
# Use it for options that only the server (but not clients) should see

# this is read by the standalone daemon and embedded servers
[server]

# this is only for the mysqld standalone daemon
[mysqld]

#
# * Basic Settings
#

user                    = mysql
pid-file                = /run/mysqld/mysqld.pid
basedir                 = /usr
datadir                 = /var/lib/mysql
tmpdir                  = /tmp
lc-messages-dir         = /usr/share/mysql
lc-messages             = en_US
skip-external-locking

# Broken reverse DNS slows down connections considerably and name resolve is
# safe to skip if there are no "host by domain name" access grants
#skip-name-resolve

# Instead of skip-networking the default is now to listen only on
# localhost which is more compatible and is not less secure.
bind-address            = 127.0.0.1

#
# * Fine Tuning
#

#key_buffer_size        = 128M
#max_allowed_packet     = 1G
#thread_stack           = 192K
#thread_cache_size      = 8
# This replaces the startup script and checks MyISAM tables if needed
# the first time they are touched
#myisam_recover_options = BACKUP
#max_connections        = 100
#table_cache            = 64

#
# * Logging and Replication
#

# Both location gets rotated by the cronjob.
# Be aware that this log type is a performance killer.
# Recommend only changing this at runtime for short testing periods if needed!
#general_log_file       = /var/log/mysql/mysql.log
#general_log            = 1

# When running under systemd, error logging goes via stdout/stderr to journald
# and when running legacy init error logging goes to syslog due to
# /etc/mysql/conf.d/mariadb.conf.d/50-mysqld_safe.cnf
# Enable this if you want to have error logging into a separate file
#log_error = /var/log/mysql/error.log
# Enable the slow query log to see queries with especially long duration
#slow_query_log_file    = /var/log/mysql/mariadb-slow.log
#long_query_time        = 10
#log_slow_verbosity     = query_plan,explain
#log-queries-not-using-indexes
#min_examined_row_limit = 1000

# The following can be used as easy to replay backup logs or for replication.
# note: if you are setting up a replication slave, see README.Debian about
#       other settings you may need to change.
#server-id              = 1
#log_bin                = /var/log/mysql/mysql-bin.log
expire_logs_days        = 10
#max_binlog_size        = 100M

#
# * SSL/TLS
#

# For documentation, please read
# https://mariadb.com/kb/en/securing-connections-for-client-and-server/
#ssl-ca = /etc/mysql/cacert.pem
#ssl-cert = /etc/mysql/server-cert.pem
#ssl-key = /etc/mysql/server-key.pem
#require-secure-transport = on

#
# * Character sets
#

# MySQL/MariaDB default is Latin1, but in Debian we rather default to the full
# utf8 4-byte character set. See also client.cnf
character-set-server  = utf8mb4
collation-server      = utf8mb4_general_ci

#
# * InnoDB
#

# InnoDB is enabled by default with a 10MB datafile in /var/lib/mysql/.
# Read the manual for more InnoDB related options. There are many!
# Most important is to give InnoDB 80 % of the system RAM for buffer use:
# https://mariadb.com/kb/en/innodb-system-variables/#innodb_buffer_pool_size
#innodb_buffer_pool_size = 8G

# this is only for embedded server
[embedded]

# This group is only read by MariaDB servers, not by MySQL.
# If you use the same .cnf file for MySQL and MariaDB,
# you can put MariaDB-only options here
[mariadb]

# This group is only read by MariaDB-10.5 servers.
# If you use the same .cnf file for MariaDB of different versions,
# use this group for options that older servers don't understand
[mariadb-10.5]
EOF
scp /etc/mysql/mariadb.conf.d/50-server.cnf root@$ip_standby:/etc/mysql/mariadb.conf.d/50-server.cnf
mysql -uroot -e "STOP SLAVE;"
mysql -uroot -e "RESET SLAVE;"
systemctl restart mariadb
ssh root@$ip_standby 'mysql -uroot -e "STOP SLAVE;"'
ssh root@$ip_standby 'mysql -uroot -e "RESET SLAVE;"'
ssh root@$ip_standby "systemctl restart mariadb"

cat > /etc/lsyncd/lsyncd.conf.lua << EOF
----
-- User configuration file for lsyncd.
--
-- Simple example for default rsync.
--
EOF
scp /etc/lsyncd/lsyncd.conf.lua root@$ip_standby:/etc/lsyncd/lsyncd.conf.lua
cat > /tmp/remotecluster.sh << EOF
#!/bin/bash
pcs cluster destroy
systemctl disable pcsd.service 
systemctl disable corosync.service 
systemctl disable pacemaker.service
systemctl stop pcsd.service 
systemctl stop corosync.service 
systemctl stop pacemaker.service
EOF
scp /tmp/remotecluster.sh root@$ip_standby:/tmp/remotecluster.sh
ssh root@$ip_standby "chmod +x /tmp/remotecluster.sh"
ssh root@$ip_standby "/tmp/./remotecluster.sh"	
systemctl stop lsyncd
systemctl enable asterisk
systemctl restart asterisk
ssh root@$ip_standby "systemctl stop lsyncd"
ssh root@$ip_standby "systemctl enable asterisk"
ssh root@$ip_standby "systemctl restart asterisk"
echo -e "************************************************************"
echo -e "*  Remove memory Firewall Rules in Server 1 and 2 and App  *"
echo -e "************************************************************"
firewall-cmd --remove-service=high-availability
firewall-cmd --zone=public --remove-port=3306/tcp
firewall-cmd --runtime-to-permanent
firewall-cmd --reload
ssh root@$ip_standby "firewall-cmd --remove-service=high-availability"
ssh root@$ip_standby "firewall-cmd --zone=public --remove-port=3306/tcp"
ssh root@$ip_standby "firewall-cmd --runtime-to-permanent"
ssh root@$ip_standby "firewall-cmd --reload"
echo -e "************************************************************"
echo -e "*            Cluster destroyed successfully                *"
echo -e "************************************************************"
		
fi
	echo -e "2"	> step.txt
	exit
fi

if [ "$arg" = 'rebuild' ] ;then
	step=4
else
	stepFile=step.txt
	if [ -f $stepFile ]; then
		step=`cat $stepFile`
	else
		step=0
	fi
fi

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
firewall-cmd --permanent --zone=public --add-port=3306/tcp
firewall-cmd --reload
ssh root@$ip_standby "firewall-cmd --permanent --add-service=high-availability"
ssh root@$ip_standby "firewall-cmd --permanent --zone=public --add-port=3306/tcp"
ssh root@$ip_standby "firewall-cmd --reload"

echo -e "************************************************************"
echo -e "*             Configuring Permanent Firewall               *"
echo -e "*   Creating Firewall Services in VitalPBX in Server 1     *"
echo -e "************************************************************"
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_services (name, protocol, port) VALUES ('MariaDB Client', 'tcp', '3306')"
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
service_id=$(mysql -uroot ombutel -e "select firewall_service_id from ombu_firewall_services where name = 'MariaDB Client'" | awk 'NR==2')
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_master', 'accept', $last_index)"
last_index=$last_index+1
mysql -uroot ombutel -e "INSERT INTO ombu_firewall_rules (firewall_service_id, source, action, \`index\`) VALUES ($service_id, '$ip_standby', 'accept', $last_index)"
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

create_lsyncd_config_file:
echo -e "************************************************************"
echo -e "*          Configure lsync in Server 1 and 2               *"
echo -e "************************************************************"
if [ ! -d "/var/spool/asterisk/monitor" ] ;then
	mkdir /var/spool/asterisk/monitor
fi
chown asterisk:asterisk /var/spool/asterisk/monitor

if [ ! -d "/usr/share/vitxi" ] ;then
	mkdir /usr/share/vitxi
	mkdir /usr/share/vitxi/backend
	mkdir /usr/share/vitxi/backend/storage
fi
chown -R www-data:www-data /usr/share/vitxi

if [ ! -d "/var/lib/vitxi" ] ;then
	mkdir /var/lib/vitxi
fi
chown -R www-data:www-data /var/lib/vitxi

ssh root@$ip_standby [[ ! -d /var/spool/asterisk/monitor ]] && ssh root@$ip_standby "mkdir /var/spool/asterisk/monitor" || echo "Path exist";
ssh root@$ip_standby "chown -R asterisk:asterisk /var/spool/asterisk/monitor"

ssh root@$ip_standby [[ ! -d /usr/share/vitxi ]] && ssh root@$ip_standby "mkdir /usr/share/vitxi" || echo "Path exist";
ssh root@$ip_standby "chown -R www-data:www-data /usr/share/vitxi"

ssh root@$ip_standby [[ ! -d /usr/share/vitxi/backend ]] && ssh root@$ip_standby "mkdir /usr/share/vitxi/backend" || echo "Path exist";
ssh root@$ip_standby "chown -R www-data:www-data /usr/share/vitxi/backend"

ssh root@$ip_standby [[ ! -d /usr/share/vitxi/backend/storage ]] && ssh root@$ip_standby "mkdir /usr/share/vitxi/backend/storage" || echo "Path exist";
ssh root@$ip_standby "chown -R www-data:www-data /usr/share/vitxi/backend/storage"

ssh root@$ip_standby [[ ! -d /var/lib/vitxi ]] && ssh root@$ip_standby "mkdir /var/lib/vitxi" || echo "Path exist";
ssh root@$ip_standby "chown -R www-data:www-data /var/lib/vitxi"

if [ ! -d "/etc/lsyncd" ] ;then
	mkdir /etc/lsyncd
fi
if [ ! -d "/var/log/lsyncd" ] ;then
	mkdir /var/log/lsyncd
	touch /var/log/lsyncd/lsyncd.{log,status}
fi

cat > /etc/lsyncd/lsyncd.conf.lua << EOF
----
-- User configuration file for lsyncd.
--
-- Simple example for default rsync.
--
settings {
		logfile    = "/var/log/lsyncd/lsyncd.log",
		statusFile = "/var/log/lsyncd/lsyncd.status",
		statusInterval = 20,
		nodaemon   = false,
		insist = true,
}
sync {
		default.rsyncssh,
		source = "/var/spool/asterisk/monitor",
		host = "$ip_standby",
		targetdir = "/var/spool/asterisk/monitor",
		rsync = {
				owner = true,
				group = true
		}
}
sync {
		default.rsyncssh,
		source = "/var/lib/asterisk/",
		host = "$ip_standby",
		targetdir = "/var/lib/asterisk/",
		rsync = {
				binary = "/usr/bin/rsync",
				owner = true,
				group = true,
				archive = "true",
				_extra = {
						"--include=astdb.sqlite3",
						"--exclude=*"
						}
				}
}
sync {
		default.rsyncssh,
		source = "/usr/share/vitxi/backend/",
		host = "$ip_standby",
		targetdir = "/usr/share/vitxi/backend/",
		rsync = {
				binary = "/usr/bin/rsync",
				owner = true,
				group = true,
				archive = "true",
				_extra = {
						"--include=.env",
						"--exclude=*"
						}
				}
}
sync {
		default.rsyncssh,
		source = "/usr/share/vitxi/backend/storage/",
		host = "$ip_standby",
		targetdir = "/usr/share/vitxi/backend/storage/",
		rsync = {
				owner = true,
				group = true
		}
}
sync {
		default.rsyncssh,
		source = "/var/lib/vitxi/",
		host = "$ip_standby",
		targetdir = "/var/lib/vitxi/",
		rsync = {
				binary = "/usr/bin/rsync",
				owner = true,
				group = true,
				archive = "true",
				_extra = {
						"--include=wizard.conf",
						"--exclude=*"
						}
				}
}
sync {
		default.rsyncssh,
		source = "/var/lib/asterisk/agi-bin/",
		host = "$ip_standby",
		targetdir = "/var/lib/asterisk/agi-bin/",
		rsync = {
				owner = true,
				group = true
		}
}
sync {
		default.rsyncssh,
		source = "/var/lib/asterisk/priv-callerintros/",
		host = "$ip_standby",
		targetdir = "/var/lib/asterisk/priv-callerintros",
		rsync = {
				owner = true,
				group = true
		}
}
sync {
		default.rsyncssh,
		source = "/var/lib/asterisk/sounds/",
		host = "$ip_standby",
		targetdir = "/var/lib/asterisk/sounds/",
		rsync = {
				owner = true,
				group = true
		}
}
sync {
		default.rsyncssh,
		source = "/var/lib/vitalpbx",
		host = "$ip_standby",
		targetdir = "/var/lib/vitalpbx",
		rsync = {
				binary = "/usr/bin/rsync",
				owner = true,
				group = true,			
				archive = "true",
				_extra = {
						"--exclude=*.lic",
						"--exclude=*.dat",
						"--exclude=dbsetup-done",
						"--exclude=cache"
						}
				}
}
sync {
		default.rsyncssh,
		source = "/etc/asterisk",
		host = "$ip_standby",
		targetdir = "/etc/asterisk",
		rsync = {
				owner = true,
				group = true
		}
}
EOF

ssh root@$ip_standby [[ ! -d /etc/lsyncd ]] && ssh root@$ip_standby "mkdir /etc/lsyncd" || echo "Path exist";
ssh root@$ip_standby [[ ! -d /var/log/lsyncd ]] && ssh root@$ip_standby "mkdir /var/log/lsyncd" || echo "Path exist";
ssh root@$ip_standby "touch /var/log/lsyncd/lsyncd.{log,status}"

cat > /tmp/lsyncd.conf.lua << EOF
----
-- User configuration file for lsyncd.
--
-- Simple example for default rsync.
--
settings {
		logfile = "/var/log/lsyncd/lsyncd.log",
		statusFile = "/var/log/lsyncd/lsyncd-status.log",
		statusInterval = 20,
		nodaemon = false,
		insist = true,
}
sync {
		default.rsyncssh,
		source = "/var/spool/asterisk/monitor",
		host = "$ip_master",
		targetdir = "/var/spool/asterisk/monitor",
		rsync = {
				owner = true,
				group = true
		}
}
sync {
		default.rsyncssh,
		source = "/var/lib/asterisk/",
		host = "$ip_master",
		targetdir = "/var/lib/asterisk/",
		rsync = {
				binary = "/usr/bin/rsync",
				owner = true,
				group = true,
				archive = "true",
				_extra = {
						"--include=astdb.sqlite3",
						"--exclude=*"
						}
				}
}
sync {
		default.rsyncssh,
		source = "/usr/share/vitxi/backend/",
		host = "$ip_master",
		targetdir = "/usr/share/vitxi/backend/",
		rsync = {
				binary = "/usr/bin/rsync",
				owner = true,
				group = true,
				archive = "true",
				_extra = {
						"--include=.env",
						"--exclude=*"
						}
				}
}
sync {
		default.rsyncssh,
		source = "/usr/share/vitxi/backend/storage/",
		host = "$ip_master",
		targetdir = "/usr/share/vitxi/backend/storage/",
		rsync = {
				owner = true,
				group = true
		}
}
sync {
		default.rsyncssh,
		source = "/var/lib/vitxi/",
		host = "$ip_master",
		targetdir = "/var/lib/vitxi/",
		rsync = {
				binary = "/usr/bin/rsync",
				owner = true,
				group = true,
				archive = "true",
				_extra = {
						"--include=wizard.conf",
						"--exclude=*"
						}
				}
}
sync {
		default.rsyncssh,
		source = "/var/lib/asterisk/agi-bin/",
		host = "$ip_master",
		targetdir = "/var/lib/asterisk/agi-bin/",
		rsync = {
				owner = true,
				group = true
		}
}
sync {
		default.rsyncssh,
		source = "/var/lib/asterisk/priv-callerintros/",
		host = "$ip_master",
		targetdir = "/var/lib/asterisk/priv-callerintros",
		rsync = {
				owner = true,
				group = true
		}
}
sync {
		default.rsyncssh,
		source = "/var/lib/asterisk/sounds/",
		host = "$ip_master",
		targetdir =  "/var/lib/asterisk/sounds/",
		rsync = {
				owner = true,
				group = true
		}
}
sync {
		default.rsyncssh,
		source = "/var/lib/vitalpbx",
		host = "$ip_master",
		targetdir = "/var/lib/vitalpbx",
		rsync = {
				binary = "/usr/bin/rsync",
				owner = true,
				group = true,
				archive = "true",
				_extra = {
						"--exclude=*.lic",
						"--exclude=*.dat",
						"--exclude=dbsetup-done",
						"--exclude=cache"
						}
				}
}
sync {
		default.rsyncssh,
		source = "/etc/asterisk",
		host = "$ip_master",
		targetdir = "/etc/asterisk",
		rsync = {
				owner = true,
				group = true
		}
}
EOF
scp /tmp/lsyncd.conf.lua root@$ip_standby:/etc/lsyncd/lsyncd.conf.lua
echo -e "*** Done Step 5 ***"
echo -e "5"	> step.txt

create_mariadb_replica:
echo -e "************************************************************"
echo -e "*                Create mariadb replica                    *"
echo -e "************************************************************"
#Enable chrony service
systemctl start chrony
systemctl enable chrony
ssh root@$ip_standby "systemctl start chrony"
ssh root@$ip_standby "systemctl enable chrony"
#Remove anonymous user from MySQL
mysql -uroot -e "DELETE FROM mysql.user WHERE User='';"
#Configuration of the First Master Server (Master-1)
cat > /etc/mysql/mariadb.conf.d/50-server.cnf << EOF
#
# These groups are read by MariaDB server.
# Use it for options that only the server (but not clients) should see

# this is read by the standalone daemon and embedded servers
[server]

# this is only for the mysqld standalone daemon
[mysqld]

#
# * Replica Settings
#

bind-address	= 0.0.0.0
server-id	= 1
report_host	= master1
log_bin		= /var/log/mysql/mariadb-bin
log_bin_index	= /var/log/mysql/mariadb-bin.index
relay_log	= /var/log/mysql/relay-bin
relay_log_index	= /var/log/mysql/relay-bin.index

#
# * Basic Settings
#

user                    = mysql
pid-file                = /run/mysqld/mysqld.pid
basedir                 = /usr
datadir                 = /var/lib/mysql
tmpdir                  = /tmp
lc-messages-dir         = /usr/share/mysql
lc-messages             = en_US
skip-external-locking

# Broken reverse DNS slows down connections considerably and name resolve is
# safe to skip if there are no "host by domain name" access grants
#skip-name-resolve

# Instead of skip-networking the default is now to listen only on
# localhost which is more compatible and is not less secure.
#bind-address            = 127.0.0.1

#
# * Fine Tuning
#

#key_buffer_size        = 128M
#max_allowed_packet     = 1G
#thread_stack           = 192K
#thread_cache_size      = 8
# This replaces the startup script and checks MyISAM tables if needed
# the first time they are touched
#myisam_recover_options = BACKUP
#max_connections        = 100
#table_cache            = 64

#
# * Logging and Replication
#

# Both location gets rotated by the cronjob.
# Be aware that this log type is a performance killer.
# Recommend only changing this at runtime for short testing periods if needed!
#general_log_file       = /var/log/mysql/mysql.log
#general_log            = 1

# When running under systemd, error logging goes via stdout/stderr to journald
# and when running legacy init error logging goes to syslog due to
# /etc/mysql/conf.d/mariadb.conf.d/50-mysqld_safe.cnf
# Enable this if you want to have error logging into a separate file
#log_error = /var/log/mysql/error.log
# Enable the slow query log to see queries with especially long duration
#slow_query_log_file    = /var/log/mysql/mariadb-slow.log
#long_query_time        = 10
#log_slow_verbosity     = query_plan,explain
#log-queries-not-using-indexes
#min_examined_row_limit = 1000

# The following can be used as easy to replay backup logs or for replication.
# note: if you are setting up a replication slave, see README.Debian about
#       other settings you may need to change.
#server-id              = 1
#log_bin                = /var/log/mysql/mysql-bin.log
expire_logs_days        = 10
#max_binlog_size        = 100M

#
# * SSL/TLS
#

# For documentation, please read
# https://mariadb.com/kb/en/securing-connections-for-client-and-server/
#ssl-ca = /etc/mysql/cacert.pem
#ssl-cert = /etc/mysql/server-cert.pem
#ssl-key = /etc/mysql/server-key.pem
#require-secure-transport = on

#
# * Character sets
#

# MySQL/MariaDB default is Latin1, but in Debian we rather default to the full
# utf8 4-byte character set. See also client.cnf
character-set-server  = utf8mb4
collation-server      = utf8mb4_general_ci

#
# * InnoDB
#

# InnoDB is enabled by default with a 10MB datafile in /var/lib/mysql/.
# Read the manual for more InnoDB related options. There are many!
# Most important is to give InnoDB 80 % of the system RAM for buffer use:
# https://mariadb.com/kb/en/innodb-system-variables/#innodb_buffer_pool_size
#innodb_buffer_pool_size = 8G

# this is only for embedded server
[embedded]

# This group is only read by MariaDB servers, not by MySQL.
# If you use the same .cnf file for MySQL and MariaDB,
# you can put MariaDB-only options here
[mariadb]

# This group is only read by MariaDB-10.5 servers.
# If you use the same .cnf file for MariaDB of different versions,
# use this group for options that older servers don't understand
[mariadb-10.5]
EOF
systemctl restart mariadb
#Create a new user on the Master-1
mysql -uroot -e "GRANT REPLICATION SLAVE ON *.* to vitalpbx_replica@'%' IDENTIFIED BY 'vitalpbx_replica';"
mysql -uroot -e "FLUSH PRIVILEGES;"
mysql -uroot -e "FLUSH TABLES WITH READ LOCK;"
#Get bin_log on Master-1
file_server_1=`mysql -uroot -e "show master status" | awk 'NR==2 {print $1}'`
position_server_1=`mysql -uroot -e "show master status" | awk 'NR==2 {print $2}'`

#Now on the Master-1 server, do a dump of the database MySQL and import it to Master-2
mysqldump -u root --all-databases > all_databases.sql
scp all_databases.sql root@$ip_standby:/tmp/all_databases.sql
cat > /tmp/mysqldump.sh << EOF
#!/bin/bash
mysql mysql -u root <  /tmp/all_databases.sql 
EOF
scp /tmp/mysqldump.sh root@$ip_standby:/tmp/mysqldump.sh
ssh root@$ip_standby "chmod +x /tmp/mysqldump.sh"
ssh root@$ip_standby "/tmp/./mysqldump.sh"

#Configuration of the Second Master Server (Master-2)
cat > /tmp/50-server.cnf << EOF
#
# These groups are read by MariaDB server.
# Use it for options that only the server (but not clients) should see

# this is read by the standalone daemon and embedded servers
[server]
# this is only for the mysqld standalone daemon
[mysqld]

#
# * Replica Settings
#

bind-address	= 0.0.0.0
server-id	= 2
report_host	= master2
log_bin		= /var/log/mysql/mariadb-bin
log_bin_index	= /var/log/mysql/mariadb-bin.index
relay_log	= /var/log/mysql/relay-bin
relay_log_index	= /var/log/mysql/relay-bin.index

#
# * Basic Settings
#

user                    = mysql
pid-file                = /run/mysqld/mysqld.pid
basedir                 = /usr
datadir                 = /var/lib/mysql
tmpdir                  = /tmp
lc-messages-dir         = /usr/share/mysql
lc-messages             = en_US
skip-external-locking

# Broken reverse DNS slows down connections considerably and name resolve is
# safe to skip if there are no "host by domain name" access grants
#skip-name-resolve

# Instead of skip-networking the default is now to listen only on
# localhost which is more compatible and is not less secure.
#bind-address            = 127.0.0.1

#
# * Fine Tuning
#

#key_buffer_size        = 128M
#max_allowed_packet     = 1G
#thread_stack           = 192K
#thread_cache_size      = 8
# This replaces the startup script and checks MyISAM tables if needed
# the first time they are touched
#myisam_recover_options = BACKUP
#max_connections        = 100
#table_cache            = 64

#
# * Logging and Replication
#

# Both location gets rotated by the cronjob.
# Be aware that this log type is a performance killer.
# Recommend only changing this at runtime for short testing periods if needed!
#general_log_file       = /var/log/mysql/mysql.log
#general_log            = 1

# When running under systemd, error logging goes via stdout/stderr to journald
# and when running legacy init error logging goes to syslog due to
# /etc/mysql/conf.d/mariadb.conf.d/50-mysqld_safe.cnf
# Enable this if you want to have error logging into a separate file
#log_error = /var/log/mysql/error.log
# Enable the slow query log to see queries with especially long duration
#slow_query_log_file    = /var/log/mysql/mariadb-slow.log
#long_query_time        = 10
#log_slow_verbosity     = query_plan,explain
#log-queries-not-using-indexes
#min_examined_row_limit = 1000

# The following can be used as easy to replay backup logs or for replication.
# note: if you are setting up a replication slave, see README.Debian about
#       other settings you may need to change.
#server-id              = 1
#log_bin                = /var/log/mysql/mysql-bin.log
expire_logs_days        = 10
#max_binlog_size        = 100M

#
# * SSL/TLS
#

# For documentation, please read
# https://mariadb.com/kb/en/securing-connections-for-client-and-server/
#ssl-ca = /etc/mysql/cacert.pem
#ssl-cert = /etc/mysql/server-cert.pem
#ssl-key = /etc/mysql/server-key.pem
#require-secure-transport = on

#
# * Character sets
#

# MySQL/MariaDB default is Latin1, but in Debian we rather default to the full
# utf8 4-byte character set. See also client.cnf
character-set-server  = utf8mb4
collation-server      = utf8mb4_general_ci

#
# * InnoDB
#

# InnoDB is enabled by default with a 10MB datafile in /var/lib/mysql/.
# Read the manual for more InnoDB related options. There are many!
# Most important is to give InnoDB 80 % of the system RAM for buffer use:
# https://mariadb.com/kb/en/innodb-system-variables/#innodb_buffer_pool_size
#innodb_buffer_pool_size = 8G

# this is only for embedded server
[embedded]

# This group is only read by MariaDB servers, not by MySQL.
# If you use the same .cnf file for MySQL and MariaDB,
# you can put MariaDB-only options here
[mariadb]

# This group is only read by MariaDB-10.5 servers.
# If you use the same .cnf file for MariaDB of different versions,
# use this group for options that older servers don't understand
[mariadb-10.5]
EOF
scp /tmp/50-server.cnf root@$ip_standby:/etc/mysql/mariadb.conf.d/50-server.cnf
ssh root@$ip_standby "systemctl restart mariadb"
#Create a new user on the Master-2
cat > /tmp/grand.sh << EOF
#!/bin/bash
mysql -uroot -e "GRANT REPLICATION SLAVE ON *.* to vitalpbx_replica@'%' IDENTIFIED BY 'vitalpbx_replica';"
mysql -uroot -e "FLUSH PRIVILEGES;"
mysql -uroot -e "FLUSH TABLES WITH READ LOCK;"
EOF
scp /tmp/grand.sh root@$ip_standby:/tmp/grand.sh
ssh root@$ip_standby "chmod +x /tmp/grand.sh"
ssh root@$ip_standby "/tmp/./grand.sh"
#Get bin_log on Master-2
file_server_2=`ssh root@$ip_standby 'mysql -uroot -e "show master status;"' | awk 'NR==2 {print $1}'`
position_server_2=`ssh root@$ip_standby 'mysql -uroot -e "show master status;"' | awk 'NR==2 {print $2}'`
#Stop the slave, add Master-1 to the Master-2 and start slave
cat > /tmp/change.sh << EOF
#!/bin/bash
mysql -uroot -e "STOP SLAVE;"
mysql -uroot -e "CHANGE MASTER TO MASTER_HOST='$ip_master', MASTER_USER='vitalpbx_replica', MASTER_PASSWORD='vitalpbx_replica', MASTER_LOG_FILE='$file_server_1', MASTER_LOG_POS=$position_server_1;"
mysql -uroot -e "START SLAVE;"
EOF
scp /tmp/change.sh root@$ip_standby:/tmp/change.sh
ssh root@$ip_standby "chmod +x /tmp/change.sh"
ssh root@$ip_standby "/tmp/./change.sh"

#Connect to Master-1 and follow the same steps
mysql -uroot -e "STOP SLAVE;"
mysql -uroot -e "CHANGE MASTER TO MASTER_HOST='$ip_standby', MASTER_USER='vitalpbx_replica', MASTER_PASSWORD='vitalpbx_replica', MASTER_LOG_FILE='$file_server_2', MASTER_LOG_POS=$position_server_2;"
mysql -uroot -e "START SLAVE;"

echo -e "*** Done Step 6 ***"
echo -e "6"	> step.txt

create_hacluster_password:
echo -e "************************************************************"
echo -e "*     Create password for hacluster in Master/Standby      *"
echo -e "************************************************************"
echo hacluster:$hapassword | chpasswd
ssh root@$ip_standby "echo hacluster:$hapassword | chpasswd"
echo -e "*** Done Step 7 ***"
echo -e "7"	> step.txt

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
echo -e "*** Done Step 8 ***"
echo -e "8"	> step.txt

auth_hacluster:
echo -e "************************************************************"
echo -e "*            Server Authenticate in Master                 *"
echo -e "************************************************************"
pcs cluster destroy
pcs host auth $host_master $host_standby -u hacluster -p $hapassword
echo -e "*** Done Step 9 ***"
echo -e "9"	> step.txt

creating_cluster:
echo -e "************************************************************"
echo -e "*              Creating Cluster in Master                  *"
echo -e "************************************************************"
pcs cluster setup cluster_vitalpbx $host_master $host_standby --force
echo -e "*** Done Step 10 ***"
echo -e "10"	> step.txt

starting_cluster:
echo -e "************************************************************"
echo -e "*              Starting Cluster in Master                  *"
echo -e "************************************************************"
pcs cluster start --all
pcs cluster enable --all
pcs property set stonith-enabled=false
pcs property set no-quorum-policy=ignore
echo -e "*** Done Step 11 ***"
echo -e "11"	> step.txt

creating_floating_ip:
echo -e "************************************************************"
echo -e "*            Creating Floating IP in Master                *"
echo -e "************************************************************"
pcs resource create virtual_ip ocf:heartbeat:IPaddr2 ip=$ip_floating cidr_netmask=$ip_floating_mask op monitor interval=30s on-fail=restart
pcs cluster cib drbd_cfg
pcs cluster cib-push drbd_cfg
echo -e "*** Done Step 12 ***"
echo -e "12"	> step.txt

disable_services:
echo -e "************************************************************"
echo -e "*             Disable Services in Server 1 and 2           *"
echo -e "************************************************************"
systemctl disable asterisk
systemctl stop asterisk
systemctl disable lsyncd
systemctl stop lsyncd
ssh root@$ip_standby "systemctl disable asterisk"
ssh root@$ip_standby "systemctl stop asterisk"
ssh root@$ip_standby "systemctl disable lsyncd"
ssh root@$ip_standby "systemctl stop lsyncd"
echo -e "*** Done Step 13 ***"
echo -e "13"	> step.txt

create_asterisk_service:
echo -e "************************************************************"
echo -e "*          Create asterisk Service in Server 1             *"
echo -e "************************************************************"
pcs resource create asterisk service:asterisk op monitor interval=30s
pcs cluster cib fs_cfg
pcs cluster cib-push fs_cfg --config
pcs -f fs_cfg constraint colocation add asterisk with virtual_ip INFINITY
pcs -f fs_cfg constraint order virtual_ip then asterisk
pcs cluster cib-push fs_cfg --config
#Changing these values from 15s (default) to 120s is very important 
#since depending on the server and the number of extensions 
#the Asterisk can take more than 15s to start
pcs resource update asterisk op stop timeout=120s
pcs resource update asterisk op start timeout=120s
pcs resource update asterisk op restart timeout=120s
echo -e "*** Done Step 14 ***"
echo -e "14"	> step.txt

create_lsyncd_service:
echo -e "************************************************************"
echo -e "*             Create lsyncd Service in Server 1            *"
echo -e "************************************************************"
pcs resource create lsyncd service:lsyncd.service op monitor interval=30s
pcs cluster cib fs_cfg
pcs cluster cib-push fs_cfg --config
pcs -f fs_cfg constraint colocation add lsyncd with virtual_ip INFINITY
pcs -f fs_cfg constraint order asterisk then lsyncd
pcs cluster cib-push fs_cfg --config
echo -e "*** Done Step 15 ***"
echo -e "15"	> step.txt

vitalpbx_create_bascul:
echo -e "************************************************************"
echo -e "*         Creating VitalPBX Cluster bascul Command         *"
echo -e "************************************************************"
wget https://raw.githubusercontent.com/VitalPBX/vitalpbx_ha_v4/main/bascul
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
wget https://raw.githubusercontent.com/VitalPBX/vitalpbx_ha_v4/main/role
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
wget https://raw.githubusercontent.com/VitalPBX/vitalpbx_ha_v4/master/mariadbfix
yes | cp -fr mariadbfix /usr/local/bin/mariadbfix
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
