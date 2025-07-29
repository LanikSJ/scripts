#!/bin/bash
sudo chmod 755 /etc/sudoers.d/
echo 'ierenstein ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/ierenstein
sudo chmod 750 /etc/sudoers.d/
sudo useradd -G adm,sudo -c "Ilan Erenstein" -d /home/ierenstein -s /bin/bash ierenstein
sudo mkdir -p /home/ierenstein/.ssh
cd /home/ierenstein/.ssh || exit
