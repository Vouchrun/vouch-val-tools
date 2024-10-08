#!/bin/bash

# run from $HOME/ using "sudo sh /home/$_user/vouch/setup_pulse-staking-deposit-cli"

# Download the command line tool for staking on an internet connected computer using git
cd $HOME
git clone https://github.com/Vouchrun/pulse-staking-deposit-cli.git

# STUCK HERE NEED TO WORK ON THIS PART SUDO CAUSING PATH ERRORS
# Install the staking tool on your clean computer
cd pulse-staking-deposit-cli
sudo -i add-apt-repository universe
sudo -i apt update
sudo -i apt install python3-pip
sudo -i pip3 install -r requirements.txt
sudo -i python3 setup.py install
# ./deposit.sh install
# apt install -y jq

echo "Staking tool now installed in $HOME/pulse-staking-deposit-cli"


echo "Script completed. Press Y to continue..."
read -p "Continue? (Y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    exit
else
    exit
fi