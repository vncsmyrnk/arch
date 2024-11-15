#!/bin/bash

openssl enc -aes-256-cbc -d -in creds.json.enc -out creds.json -pbkdf2
pacman -S archinstall
archinstall --config config.json --creds creds.json
