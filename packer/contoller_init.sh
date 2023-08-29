#! /usr/bin/env bash

sudo yum install -y bzip2 perl openssl-devel dbus-devel

# munge installation guide: https://github.com/dun/munge/wiki/Installation-Guide
MUNGE_VERSION="0.5.15"
mkdir munge-wkdir && cd munge-wkdir
curl -Lo munge-$MUNGE_VERSION.tar.xz https://github.com/dun/munge/releases/download/munge-$MUNGE_VERSION/munge-$MUNGE_VERSION.tar.xz
tar -xf munge-*.tar.xz
cd munge-$MUNGE_VERSION
./configure
make
sudo make install
cd ../..

sudo mkdir -p /usr/local/etc/munge/ /usr/local/var/log/munge /usr/local/var/run/munge
sudo chown -R munge:munge /usr/local/etc/munge/ /usr/local/var/log/munge /usr/local/var/run/munge
sudo -u munge /usr/local/sbin/mungekey --verbose
sudo systemctl enable munge.service
sudo systemctl start munge.service

# Create slurm user
sudo groupadd -g 1001 slurm
sudo useradd -u 1001 -g 1001 slurm

# Get a version here: https://www.schedmd.com/downloads.php
SLURM_VERSION="23.02.4"
mkdir -p slurm-wkdr && cd slurm-wkdr
curl -Lo "slurm-$SLURM_VERSION.tar.bz2" "https://download.schedmd.com/slurm/slurm-$SLURM_VERSION.tar.bz2"
tar --bzip -x -f slurm*tar.bz2
cd slurm-$SLURM_VERSION

# Install slurm: https://slurm.schedmd.com/quickstart_admin.html#build_install
./configure --with-systemdsystemunitdir="/usr/local/lib/systemd/system/"
sudo make install
export LD_LIBRARY_PATH="/usr/local/lib"
ldconfig -n /usr/local/lib
mkdir -p /usr/local/etc
cat << EOF | sudo tee -a /usr/local/etc/slurm.conf >/dev/null
#
# Sample /etc/slurm.conf for mcr.llnl.gov
#
ClusterName=cluster
SlurmctldHost=ip-10-0-91-121.ec2.internal
#
AuthType=auth/munge
Epilog=/usr/local/slurm/etc/epilog
JobCompLoc=/var/tmp/jette/slurm.job.log
JobCompType=jobcomp/filetxt
PluginDir=/usr/local/lib/slurm
Prolog=/usr/local/slurm/etc/prolog
SchedulerType=sched/backfill
SelectType=select/linear
SlurmUser=slurm
SlurmctldPort=7002
SlurmctldTimeout=300
SlurmdPort=7003
SlurmdSpoolDir=/var/spool/slurmd.spool
SlurmdTimeout=300
StateSaveLocation=/var/spool/slurm.state
SwitchType=switch/none
TreeWidth=50
#
# Node Configurations
#
NodeName=DEFAULT CPUs=2 RealMemory=500 TmpDisk=250 SocketsPerBoard=1 ThreadsPerCore=2 State=UNKNOWN
NodeName=ip-10-0-91-121.ec2.internal
#
# Partition Configurations
#
PartitionName=DEFAULT State=UP
PartitionName=pdebug Nodes=ip-10-0-91-121.ec2.internal MaxTime=30 MaxNodes=32 Default=YES
EOF

sudo mkdir -p \
        /usr/local/slurm/lib/slurm \
        /usr/local/slurm/etc/epilog \
        /usr/local/slurm/etc/prolog \
        /var/spool/slurm.state \
        /var/spool/slurmd.spool \
        /var/tmp/jette/
sudo chown slurm:slurm \
        /usr/local/slurm/lib/slurm \
        /usr/local/slurm/etc/epilog \
        /usr/local/slurm/etc/prolog \
        /var/spool/slurm.state \
        /var/spool/slurmd.spool \
        /var/tmp/jette/

sudo chmod -R go+w /usr/local/slurm/etc/prolog/ /usr/local/slurm/etc/epilog/

echo "LD_LIBRARY_PATH=/usr/local/lib" > /etc/default/slurmctld
echo "LD_LIBRARY_PATH=/usr/local/lib" > /etc/default/slurmd

sudo systemctl enable slurmctld.service
sudo systemctl start slurmctld.service

#sudo -u slurm LD_LIBRARY_PATH="/usr/local/lib" scontrol reconfigure
#sudo -u slurm LD_LIBRARY_PATH=/usr/local/lib scontrol update nodename=ip-10-0-91-121.ec2.internal state=resume