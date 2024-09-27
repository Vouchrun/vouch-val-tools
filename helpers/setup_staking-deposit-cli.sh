#!/bin/bash

# run from $HOME/ using "sudo sh /home/$_user/vouch/setup_pulse-staking-deposit-cli"

# Download the command line tool for staking on an internet connected computer using git
cd $HOME
git clone https://github.com/Vouchrun/pulse-staking-deposit-cli.git


# Install the staking tool on your clean computer
cd pulse-staking-deposit-cli
add-apt-repository universe
apt update
apt install python3-pip
pip3 install -r requirements.txt
python3 setup.py install
# ./deposit.sh install
# apt install -y jq
