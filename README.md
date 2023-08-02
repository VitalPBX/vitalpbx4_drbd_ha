# VitalPBX High Availability with DRBD (Version 4)
=====
High Availability with DRBD (Distributed Replicated Block Device) is a popular solution for achieving data redundancy and fault tolerance in a clustered environment. DRBD is a distributed storage system that synchronously replicates data between two or more nodes in real-time. It ensures that data is consistent across all nodes, providing continuous access to critical data even in the event of a node failure.

Make a high-availability cluster out of any pair of VitalPBX servers. VitalPBX can detect a range of failures on one VitalPBX server and automatically transfer control to the other server, resulting in a telephony environment with minimal down time.

### :warning:<strong>Important notes:</strong></span><br>
- If you are going to restore some Backup from another server that is not in HA, restore it first in the Master server before creating the HA. This should be done as the backup does not contain the firewall rules for HA to work.<br>
- The VitalPBX team does not provide support for systems in an HA environment because it is not possible to determine the environment where it has been installed.
- We recommend that Server 2 is completely clean if nothing is installed, otherwise the Script could give errors and the process would not be completed.

- ## Example:<br>


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
root@vitalpbx1:~# hostname vitalpbx1.local
</pre>

Change Ip Address, edit the following file with nano, /etc/network/interfaces
<pre>
root@vitalpbx1:~# nano /etc/network/interfaces

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
root@vitalpbx2:~# hostname vitalpbx2.local
</pre>

Change Ip Address, edit the following file with nano, /etc/network/interfaces
<pre>
root@vitalpbx2:~# nano /etc/network/interfaces

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

Configure the hostname of each server.
<pre>
root@vitalpbx-master:~# hostname vitalpbx-master.local
root@vitalpbx-slave:~# hostname vitalpbx-slave.local
</pre>

Configure the hostname of each server in the /etc/hosts file, so that both servers see each other with the hostname.
<pre>
root@vitalpbx-master-slave:~# nano /etc/hosts
192.168.10.31 vitalpbx-master.local
192.168.10.32 vitalpbx-salave.local
</pre>

## Bind Address
In the Master server go to SETTINGS/PJSIP Settings and configure the Floating IP that we are going to use in "Bind" and "TLS Bind".
Also do it in SETTINGS/SIP Settings Tab NETWORK fields "TCP Bind Address" and "TLS Bind Address".

## Install Dependencies
Install the necessary dependencies on both servers<br>
<pre>
root@vitalpbx-master:~# apt -y install drbd-utils corosync pacemaker pcs chrony xfsprogs
root@vitalpbx-slave:~# apt -y install drbd-utils corosync pacemaker pcs chrony xfsprogs
</pre>

## Create authorization key for the Access between the two servers without credentials

Create key in Server <strong>1</strong>
<pre>
root@vitalpbx<strong>1</strong>:~# ssh-keygen -f /root/.ssh/id_rsa -t rsa -N '' >/dev/null
root@vitalpbx<strong>1</strong>:~# ssh-copy-id root@<strong>192.168.10.62</strong>
Are you sure you want to continue connecting (yes/no/[fingerprint])? <strong>yes</strong>
root@192.168.10.62's password: <strong>(remote server root’s password)</strong>

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'root@192.168.10.62'"
and check to make sure that only the key(s) you wanted were added. 

root@vitalpbx<strong>1</strong>:~#
</pre>

Create key in Server <strong>2</strong>
<pre>
root@vitalpbx<strong>2</strong>:~# ssh-keygen -f /root/.ssh/id_rsa -t rsa -N '' >/dev/null
root@vitalpbx<strong>2</strong>:~# ssh-copy-id root@<strong>192.168.10.61</strong>
Are you sure you want to continue connecting (yes/no/[fingerprint])? <strong>yes</strong>
root@192.168.10.61's password: <strong>(remote server root’s password)</strong>

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'root@192.168.10.61'"
and check to make sure that only the key(s) you wanted were added. 

root@vitalpbx<strong>2</strong>:~#
</pre>

## Script
Now copy and run the following script<br>
<pre>
root@vitalpbx<strong>1</strong>:~# mkdir /usr/share/vitalpbx/ha
root@vitalpbx<strong>1</strong>:~# cd /usr/share/vitalpbx/ha
root@vitalpbx<strong>1</strong>:~# wget https://raw.githubusercontent.com/VitalPBX/vitalpbx_ha_v4/master/vpbxha.sh
root@vitalpbx<strong>1</strong>:~# chmod +x vpbxha.sh
root@vitalpbx<strong>1</strong>:~# ./vpbxha.sh
