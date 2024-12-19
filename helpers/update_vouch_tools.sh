#!/bin/bash

# update_vouch_tools


### stash and clone
cd $HOME/vouch-val-tools
git stash
git pull https://github.com/Vouchrun/vouch-val-tools.git


## Run the GUI menu
find "$HOME/vouch-val-tools" -type f -name "*.sh" -exec chmod +x {} \;
./vouch-menu.sh
