#!/bin/bash
# backup and replace current definitions with latest from repo
sudo cp $HOME/validators/validator_definitions.yml "$HOME/validators/validator_definitions_$(date +"%Y%m%d_%H%M%S")".yml
sudo cp $HOME/vouchvalidator_definitions.yml $HOME/validators/validator_definitions.yml

echo "Validator definitions Updated - existing file backed-up to $HOME/validators Directory"