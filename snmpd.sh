#!/bin/bash

# Install SNMP daemon
apt-get install -y snmpd

# Backup original configuration file
mv /etc/snmp/snmpd.conf /etc/snmp/snmpd.conf.bak

# Create a new configuration file
cat << EOF > /etc/snmp/snmpd.conf
# This file will create a read-only community called "MYSNMP"
# and restricts access to address 10.10.10.1
rocommunity mareoxlan.local 192.168.30.180
syslocation "Manteca, Tocino"
syscontact "MareoX Doe"
agentAddress udp:161
agentuser root
dontLogTCPWrappersConnects yes
realStorageUnits 0
EOF

# Restart SNMP service
service snmpd restart

# Enable SNMP to start automatically at boot
update-rc.d snmpd enable

# Check if SNMP service is running
if ! systemctl is-active --quiet snmpd; then
    echo "Error: SNMP service is not running."
    exit 1
fi

echo "SNMP configuration completed!"
