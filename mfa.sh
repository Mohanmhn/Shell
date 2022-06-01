#!/bin/bash

while IFS= read -r user; do
    sudo su -c 'google-authenticator -t -f -d --window-size=17 --rate-limit=3 --rate-time=30' $user
    echo "$user $(head -1 /home/$user/.google_authenticator)" >> mfa_list
done < $1
