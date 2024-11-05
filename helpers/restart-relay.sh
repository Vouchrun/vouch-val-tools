#!/bin/bash


# this script can be modified to suit your requirements


sudo docker stop relay
sudo docker rm relay

sudo docker run --pull always  --name relay -it -e KEYSTORE_PASSWORD --restart unless-stopped -v "/blockchain/relay/":/keys ghcr.io/vouchrun/pls-lsd-relay:main start --base-path /keys