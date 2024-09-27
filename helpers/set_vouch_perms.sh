#!/bin/bash

## get Username 
_user="$(id -u -n)"

chown -R $_user:vouch "$HOME/vouch"
chmod -R 770 "$HOME/vouch"
chown -R $_user:vouch "$HOME/"
chmod -R 770 "$HOME/"
cd $HOME/vouch
chmod +x *.sh