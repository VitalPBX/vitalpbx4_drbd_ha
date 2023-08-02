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

## Format the partition 
Now, we will proceed to format the new partition in both servers with the following command: 
<pre>
root@vitalpbx-<strong>master-slave</strong>:~# mke2fs -j /dev/sda3
root@vitalpbx-<strong>master-slave</strong>:~# dd if=/dev/zero bs=1M count=500 of=/dev/sda3; sync
</pre>

## Configuring DRBD
Load the module and enable the service on both nodes, using the follow command:
<pre>
root@vitalpbx-<strong>master-slave</strong>:~# modprobe drbd
root@vitalpbx-<strong>master-slave</strong>:~# systemctl enable drbd.service
</pre>

Create a new global_common.conf file on both nodes with the following contents:
<pre>
root@vitalpbx-<strong>master-slave</strong>:~# mv /etc/drbd.d/global_common.conf /etc/drbd.d/global_common.conf.orig
root@vitalpbx-<strong>master-slave</strong>:~# nano /etc/drbd.d/global_common.conf
global {
  usage-count yes;
}
  common {
net {
  protocol C;
  }
}
</pre>

Next, we will need to create a new configuration file called /etc/drbd.d/drbd0.res for the new resource named drbd0, with the following contents:
<pre>
root@vitalpbx-<strong>master-slave</strong>:~# nano /etc/drbd.d/drbd0.res
resource drbd0 {
     on vitalpbx-master.local {
          device /dev/drbd0;
          disk /dev/sda3;
          address <strong>192.168.10.31</strong>:7789;
          meta-disk internal;
     }
     on vitalpbx-slave.local {
          device /dev/drbd0;
          disk /dev/sda3;
          address <strong>192.168.10.32</strong>:7789;
          meta-disk internal;
     }
handlers {
     split-brain "/usr/lib/drbd/notify-split-brain.sh root";
     }
net  {
     after-sb-0pri discard-zero-changes;
     after-sb-1pri discard-secondary;
     after-sb-2pri disconnect;
     }
}
</pre>

Initialize the meta data storage on each nodes by executing the following command on both nodes
<pre>
root@vitalpbx-<strong>master-slave</strong>:~# drbdadm create-md drbd0
Writing meta data...
New drbd meta data block successfully created.
</pre>

Let’s define the DRBD Primary node as first node “vitalpbx-master”
<pre>
root@vitalpbx-<strong>master</strong>:~# drbdadm up drbd0
root@vitalpbx-<strong>master</strong>:~# drbdadm primary drbd0 --force
</pre>

On the Secondary node “vitalpbx-slave” run the following command to start the drbd0
<pre>
root@vitalpbx-<strong>slave</strong>:~#  drbdadm up drbd0
</pre>

You can check the current status of the synchronization while it’s being performed. The cat /proc/drbd command displays the creation and synchronization progress of the resource.
<pre>
root@vitalpbx-<strong>master-slave</strong>:~#  cat /proc/drbd 
</pre>

## Formatting DRBD Disk
In order to test the DRBD functionality we need to Create a file system, mount the volume and write some data on primary node “vitalpbx-master” and finally switch the primary node to “vitalpbx-slave”

Run the following command on the primary node to create an xfs filesystem on /dev/drbd0 and mount it to the mnt directory, using the following commands
<pre>
root@vitalpbx-<strong>master</strong>:~# mkfs.xfs /dev/drbd0
root@vitalpbx-<strong>master</strong>:~# mount /dev/drbd0 /mnt
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

## Change Servers Role

To execute the process of changing the role, we recommend using the following command:<br>

<pre>
[root@vitalpbx-master /]# bascul
************************************************************
*     Change the roles of servers in high availability     *
* <strong>WARNING-WARNING-WARNING-WARNING-WARNING-WARNING-WARNING</strong>  *
*All calls in progress will be lost and the system will be *
*     be in an unavailable state for a few seconds.        *
************************************************************
Are you sure to switch from vitalpbx<strong>1</strong>.local to vitalpbx<strong>2</strong>.local? (yes,no) >
</pre>

This action convert the vitalpbx<strong>1</strong>.local to Standby and vitalpbx<strong>2</strong>.local to Master. If you want to return to default do the same again.<br>

Next we will show a short video how high availability works in VitalPBX<br>
<div align="center">
  <a href="https://www.youtube.com/watch?v=3yoa3KXKMy0"><img src="https://img.youtube.com/vi/3yoa3KXKMy0/0.jpg" alt="High Availability demo video on VitalPBX"></a>
</div>

## Recommendations
If you have to turn off both servers at the same time, we recommend that you start by turning off the one in Standby and then the Master<br>
If the two servers stopped abruptly, always start first that you think you have the most up-to-date information and a few minutes later the other server<br>
If you want to update the version of VitalPBX we recommend you do it first on Server 1, then do a bascul and do it again on Server 2<br>

## Update VitalPBX version

To update VitalPBX to the latest version just follow the following steps:<br>
1.- From your browser, go to ip 192.168.10.30<br>
2.- Update VitalPBX from the interface<br>
3.- Execute the following command in Master console<br>
<pre>
[root@vitalpbx1 /]# bascul
</pre>
4.- From your browser, go to ip 192.168.10.30 again<br>
5.- Update VitalPBX from the interface<br>
6.- Execute the following command in Master console<br>
<pre>
[root@vitalpbx1 /]# bascul
</pre>

## Some useful commands
• <strong>bascul</strong>, is used to change roles between high availability servers. If all is well, a confirmation question should appear if we wish to execute the action.<br>
• <strong>role</strong>, shows the status of the current server. If all is well you should return Masters or Slaves.<br>
• <strong>•	drbdsplit</strong>, solves DRBD split brain recovery.<br>
• <strong>pcs resource refresh --full</strong>, to poll all resources even if the status is unknown, enter the following command.<br>
• <strong>pcs cluster unstandby host</strong>, in some cases the bascul command does not finish tilting, which causes one of the servers to be in standby (stop), with this command the state is restored to normal.<br>

## More Information
If you want more information that will help you solve problems about High Availability in VitalPBX we invite you to see the following manual<br>
[High Availability Manual, step by step](https://downloads.vitalpbx.com/vitalpbx/manuals/VitalPBXHighAvailabilityV4.pdf)

<strong>CONGRATULATIONS</strong>, you have installed and tested the high availability in <strong>VitalPBX 4</strong><br>
:+1:
