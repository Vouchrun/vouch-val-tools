#!/bin/bash

# create_inital_working_directories


mkdir $HOME/vouch-keys
echo "vouch-keys directory created at $HOME/vouch-keys"


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
