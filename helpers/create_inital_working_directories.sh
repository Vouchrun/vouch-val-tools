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

