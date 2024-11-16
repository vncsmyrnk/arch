#!/bin/sh

CREDS_FILE=https://raw.githubusercontent.com/vncsmyrnk/arch/refs/heads/main/creds.json.enc
CONFIG_FILE=https://raw.githubusercontent.com/vncsmyrnk/arch/refs/heads/main/config.json

curl -L -O $CREDS_FILE
openssl enc -aes-256-cbc -d -in creds.json.enc -out creds.json -pbkdf2
pacman -S archinstall
archinstall --config $CONFIG_FILE --creds creds.json
