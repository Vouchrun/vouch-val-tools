#!/bin/bash

# this script can be modified to suit your requirements
# runs docker container in interactive mode 
# use Ctrl+P followed by Ctrl+Q to detach from docker container and leave it running


sudo docker stop ejector
sudo docker rm ejector

sudo docker run --pull always  --name ejector -it -e KEYSTORE_PASSWORD --restart unless-stopped -v "/blockchain/validator_keys":/keys ghcr.io/vouchrun/pls-lsd-ejector:main start \
--consensus_endpoint https://rpc-pulsechain.g4mm4.io/beacon-api \
--execution_endpoint https://rpc-pulsechain.g4mm4.io \
--keys_dir /keys \
--withdraw_address '0x1F082785Ca889388Ce523BF3de6781E40b99B060'