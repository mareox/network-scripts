#!/bin/bash

# Disable Commercial Repo
sed -i "s/^deb/\#deb/" /etc/apt/sources.list.d/pve-enterprise.list

apt-get update -y && apt-get upgrade -y && apt-get update -y

# Add PVE Community Repo
echo "deb http://download.proxmox.com/debian/pve $(grep "VERSION=" /etc/os-release | sed -n 's/.*(\(.*\)).*/\1/p') pve-no-subscription" > /etc/apt-get/sources.list.d/pve-no-enterprise.list 

apt-get update -y

# Remove nag
echo "DPkg::Post-Invoke { \"dpkg -V proxmox-widget-toolkit | grep -q '/proxmoxlib\.js$'; if [ \$? -eq 1 ]; then { echo 'Removing subscription nag from UI...'; sed -i '/data.status/{s/\!//;s/Active/NoMoreNagging/}' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js; }; fi\"; };" > /etc/apt-get/apt-get.conf.d/no-nag-script

apt-get --reinstall install proxmox-widget-toolkit

# fstrim
# bash -c "$(wget -qLO - https://github.com/community-scripts/ProxmoxVE/raw/main/misc/fstrim.sh)"

# Update proxmox pve to newest available version
yes | apt-get dist-upgrade -y

# Alt update everything (has been warned against, I never had any issue so use at own risk)
yes | apt-get upgrade -y

# House cleaning
apt-get autoclean
yes | apt-get autoremove --purge 

### reboot
echo " Your system will reboot in 10 seconds, ctrl+c to cancel "
sleep 3
echo " Ignition in ..."
i=1

# Count down to reboot
for i in {9..1}; do
  echo "$i"
  sleep 1
done
  
sleep 1
echo " Here we goooooo! ................................ "
sleep 3
systemctl reboot

# Install Dark Theme for Proxmox GUI
# bash <(curl -s https://raw.githubusercontent.com/Weilbyte/PVEDiscordDark/master/PVEDiscordDark.sh ) install
