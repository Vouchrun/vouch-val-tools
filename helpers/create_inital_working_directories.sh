#!/bin/bash

# create_inital_working_directories


mkdir $HOME/vouch
echo "vouch directory created under $HOME/vouch"


echo "Script completed. Press Y to continue..."
read -p "Continue? (Y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    exit
else
    exit
fi





# REMOVE AFTER TESTING
# ## get Username 
# _user="$(id -u -n)"

# mkdir /blockchain
# mkdir /blockchain/vouch

# groupadd vouch
# usermod -aG vouch $_user

# chgrp -R vouch /blockchain
# sudo chmod -R 770 /blockchain/
