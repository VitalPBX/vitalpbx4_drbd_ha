# VitalPBX High Availability with DRBD (Version 4)

High Availability with DRBD (Distributed Replicated Block Device) is a popular solution for achieving data redundancy and fault tolerance in a clustered environment. DRBD is a distributed storage system that synchronously replicates data between two or more nodes in real-time. It ensures that data is consistent across all nodes, providing continuous access to critical data even in the event of a node failure.

Make a high-availability cluster out of any pair of VitalPBX servers. VitalPBX can detect a range of failures on one VitalPBX server and automatically transfer control to the other server, resulting in a telephony environment with minimal down time.

### :warning:<strong>Important notes:</strong></span><br>
- At the time of installation leave the largest amount of space on the hard drive to store the variable data on both servers.
- If you are going to restore some Backup from another server that is not in HA, restore it first in the Master server before creating the HA. This should be done as the backup does not contain the firewall rules for HA to work.<br>
- The VitalPBX team does not provide support for systems in an HA environment because it is not possible to determine the environment where it has been installed.
- We recommend that Server 2 is completely clean if nothing is installed, otherwise the Script could give errors and the process would not be completed.

- ## Example:<br>
![VitalPBX HA](https://github.com/VitalPBX/vitalpbx4_drbd_ha/blob/main/VitalPBX4_HA_DRBD.png)

## Prerequisites
In order to install VitalPBX in high availability you need the following:<br>
a.- 3 IP addresses.<br>
b.- Install VitalPBX Version 4.0 in two servers with similar characteristics.<br>
c.- DRBD, Corosync, Pacemaker and PCS.<br>
d.- Root user is required for both servers to communicate.<br>
e.- Both servers will not be able to have a proxy since this affects the communication between them.

## Configurations
We will configure in each server the hosname and IP address. 

| Name          | Master                 | Standby               |
| ------------- | ---------------------- | --------------------- |
| Hostname      | vitalpbx-master.local  | vitalpbx-salve.local  |
| IP Address    | 192.168.10.31          | 192.168.10.32         |
| Netmask       | 255.255.255.0          | 255.255.255.0         |
| Gateway       | 192.168.10.1           | 192.168.10.1          |
| Primary DNS   | 8.8.8.8                | 8.8.8.8               |
| Secondary DNS | 8.8.4.4                | 8.8.4.4               |

### Server 1
Change Hostname
<pre>
root@vitalpbx:~# hostname vitalpbx-master.local
</pre>

Change Ip Address, edit the following file with nano, /etc/network/interfaces
<pre>
root@vitalpbx-<strong>master</strong>:~# nano /etc/network/interfaces

Change
#The primary network interface
allow-hotplug eth0
iface eth0 inet dchp

With the following
#The primary network interface
allow-hotplug eth0
iface eth0 inet static
address 192.168.10.31
netmask 255.255.255.0
gateway 192.168.10.1
</pre>

### Server 2
Change Hostname
<pre>
root@vitalpbx:~# hostname vitalpbx-slave.local
</pre>

Change Ip Address, edit the following file with nano, /etc/network/interfaces
<pre>
root@vitalpbx-<strong>slave</strong>:~# nano /etc/network/interfaces

Change
#The primary network interface
allow-hotplug eth0
iface eth0 inet dchp

With the following
#The primary network interface
allow-hotplug eth0
iface eth0 inet static
address 192.168.10.32
netmask 255.255.255.0
gateway 192.168.10.1
</pre>

## Hostname
Configure the hostname of each server in the /etc/hosts file, so that both servers see each other with the hostname.
<pre>
root@vitalpbx-<strong>master-slave</strong>:~# nano /etc/hosts
192.168.10.31 vitalpbx-master.local
192.168.10.32 vitalpbx-slave.local
</pre>

## Bind Address
In the Master server go to SETTINGS/PJSIP Settings and configure the Floating IP that we are going to use in "Bind" and "TLS Bind".
Also do it in SETTINGS/SIP Settings Tab NETWORK fields "TCP Bind Address" and "TLS Bind Address".

## Install Dependencies
Install the necessary dependencies on both servers<br>
<pre>
root@vitalpbx-<strong>master-slave</strong>:~# apt -y install drbd-utils corosync pacemaker pcs chrony xfsprogs
</pre>

## Create the partition on both servers
Initialize the partition to allocate the available space on the hard disk. Do these on both servers.
<pre>
root@vitalpbx-<strong>master-slave</strong>:~# fdisk /dev/sda
Command (m for help): <strong>n</strong>
Partition type:
  p   primary (3 primary, 0 extended, 1 free)
  e   extended
Select (default e): <strong>p</strong>
Selected partition 3 (take note of the assigned partition number as we will need it later)
First sector (35155968-266338303, default 35155968): <strong>[Enter]</strong>
Last sector, +sectors or +size{K,M,G} (35155968-266338303, default 266338303): <strong>[Enter]</strong>
Using default value 266338303
Partition 4 of type Linux and of size 110.2 GiB is set
Command (m for help): <strong>t</strong>
Partition number (1-4, default 4): <strong>3</strong>
Hex code (type L to list all codes): <strong>8e</strong>
Changed type of partition 'Linux' to 'Linux LVM'
Command (m for help): <strong>w</strong>
</pre>

Then, restart the servers so that the new table is available.
<pre>
root@vitalpbx-<strong>master-slave</strong>:~# reboot
</pre>

## Create authorization key for the Access between the two servers without credentials

Create key in Server <strong>Master</strong>
<pre>
root@vitalpbx-<strong>master</strong>:~# ssh-keygen -f /root/.ssh/id_rsa -t rsa -N '' >/dev/null
root@vitalpbx-<strong>master</strong>:~# ssh-copy-id root@<strong>192.168.10.32</strong>
Are you sure you want to continue connecting (yes/no/[fingerprint])? <strong>yes</strong>
root@192.168.10.62's password: <strong>(remote server root’s password)</strong>

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'root@192.168.10.32'"
and check to make sure that only the key(s) you wanted were added. 

root@vitalpbx-<strong>master</strong>:~#
</pre>

Create key in Server <strong>Slave</strong>
<pre>
root@vitalpbx-<strong>slave</strong>:~# ssh-keygen -f /root/.ssh/id_rsa -t rsa -N '' >/dev/null
root@vitalpbx-<strong>slave</strong>:~# ssh-copy-id root@<strong>192.168.10.31</strong>
Are you sure you want to continue connecting (yes/no/[fingerprint])? <strong>yes</strong>
root@192.168.10.61's password: <strong>(remote server root’s password)</strong>

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'root@192.168.10.31'"
and check to make sure that only the key(s) you wanted were added. 

root@vitalpbx-<strong>slave</strong>:~#
</pre>

## Script
Now copy and run the following script<br>
<pre>
root@vitalpbx-<strong>master</strong>:~# mkdir /usr/share/vitalpbx/ha
root@vitalpbx-<strong>master</strong>:~# cd /usr/share/vitalpbx/ha
root@vitalpbx-<strong>master</strong>:~# wget https://raw.githubusercontent.com/VitalPBX/vitalpbx4_drbd_ha/main/vpbxha.sh
root@vitalpbx-<strong>master</strong>:~# chmod +x vpbxha.sh
root@vitalpbx-<strong>master</strong>:~# ./vpbxha.sh
</pre>

<pre>
************************************************************
*  Welcome to the VitalPBX high availability installation  *
*                All options are mandatory                 *
************************************************************
IP Server1............... > <strong>192.168.10.31</strong>
IP Server2............... > <strong>192.168.10.32</strong>
Floating IP.............. > <strong>192.168.10.30</strong>
Floating IP Mask (SIDR).. > <strong>24</strong>
Disk (sdax).............. > <strong>sda3</strong>
hacluster password....... > <strong>MyPassword</strong>
************************************************************
*                   Check Information                      *
*        Make sure you have internet on both servers       *
************************************************************
Are you sure to continue with this settings? (yes,no) > <strong>yes</strong>
</pre>

## Change Servers Role

To execute the process of changing the role, we recommend using the following command:<br>

<pre>
root@vitalpbx-<strong>master</strong>:~# bascul
************************************************************
*     Change the roles of servers in high availability     *
* <strong>WARNING-WARNING-WARNING-WARNING-WARNING-WARNING-WARNING</strong>  *
*All calls in progress will be lost and the system will be *
*     be in an unavailable state for a few seconds.        *
************************************************************
Are you sure to switch from vitalpbx<strong>master</strong>.local to vitalpbx<strong>slave</strong>.local? (yes,no) >
</pre>

This action convert the vitalpbx<strong>master</strong>.local to Standby and vitalpbx<strong>slave</strong>.local to Master. If you want to return to default do the same again.<br>

Next we will show a short video how high availability works in VitalPBX<br>
<div align="center">
  <a href="https://www.youtube.com/watch?v=3yoa3KXKMy0"><img src="https://img.youtube.com/vi/3yoa3KXKMy0/0.jpg" alt="High Availability demo video on VitalPBX"></a>
</div>
</pre>
  
## Recommendations
If you have to turn off both servers at the same time, we recommend that you start by turning off the one in Standby and then the Master<br>
If the two servers stopped abruptly, always start first that you think you have the most up-to-date information and a few minutes later the other server<br>
If you want to update the version of VitalPBX we recommend you do it first on Server Master, then do a bascul and do it again on Server Slave<br>

## Update VitalPBX version

To update VitalPBX to the latest version just follow the following steps:<br>
1.- From your browser, go to ip <strong>192.168.10.30</strong><br>
2.- Update VitalPBX from the interface<br>
3.- Execute the following command in Master console<br>
<pre>
root@vitalpbx-<strong>master</strong>:~# bascul
</pre>
4.- From your browser, go to ip 192.168.10.30 again<br>
5.- Update VitalPBX from the interface<br>
6.- Execute the following command in Master console<br>
<pre>
root@vitalpbx-<strong>master</strong>:~# bascul
</pre>

## Some useful commands
• <strong>bascul</strong>, is used to change roles between high availability servers. If all is well, a confirmation question should appear if we wish to execute the action.<br>
• <strong>role</strong>, shows the status of the current server. If all is well you should return Masters or Slaves.<br>
• <strong>drbdsplit</strong>, solves DRBD split brain recovery.<br>
• <strong>pcs resource refresh --full</strong>, to poll all resources even if the status is unknown, enter the following command.<br>
• <strong>pcs cluster unstandby host</strong>, in some cases the bascul command does not finish tilting, which causes one of the servers to be in standby (stop), with this command the state is restored to normal.<br>
•	<strong>pcs resource delete</strong>, removes the resource so it can be created.<br>
•	<strong>pcs resource create</strong>, create the resource.<br>
•	<strong>drbdadm status</strong>, shows the integrity status of the disks that are being shared between both servers in high availability. If for some reason the status of Connecting or Standalone returns to us, wait a while and if the state remains it is because there are synchronization problems between both servers, and you should execute the drbdsplit command.<br>
•	<strong>cat /proc/drbd</strong>, the state of your device is kept in /proc/drbd.<br>
•	<strong>drbdadm role drbd0</strong>, another way to check the role of the block device.<br>
•	<strong>drbdadm primary drbd0</strong>, switch the DRBD block device to Primary using drbdadm.<br>
•	<strong>drbdadm secondary drbd0</strong>, switch the DRBD block device to Secondary using drbdadm.<br>

## More Information
If you want more information that will help you solve problems about High Availability in VitalPBX we invite you to see the following manual<br>
[High Availability Manual, step by step](https://github.com/VitalPBX/vitalpbx4_drbd_ha/blob/main/VitalPBXHighAvailabilityV4_DRBD_2023.pdf)

<strong>CONGRATULATIONS</strong>, you have installed and tested the high availability in <strong>VitalPBX 4</strong><br>
:+1:
