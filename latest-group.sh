#!/bin/bash

file=$1
group=dev

check_grp() {
    echo "Checking group $group"
    getent group $group
    if [[ $? -eq 0 ]]
    then
        echo "Found group $group" && add_user
    else
        echo "$group group not found, creating" && groupadd $group && echo "$group group created" && add_user || { echo "failed to create group $group"; exit 1; }
    fi
}

add_user() {
    while IFS= read -r user; do
        echo "trying to check and add $user to $group group"
        [[ -d /home/$user/ ]] && usermod -g $group $user && echo "$user added to $group group successfully" ||  { echo "$user not found on server"; }
    done < $file
    chmod 640 /etc/sudoers
    cat /etc/sudoers | grep "%$group ALL=(river:river) NOPASSWD: ALL"
    if [[ $? -eq 0 ]]
    then
        echo "sudoers entry already found for $group group"
    else
        echo "%$group ALL=(river:river) NOPASSWD: ALL" >> /etc/sudoers && echo "ädded entry of $group group in sudoers"
    fi
    cat /etc/pam.d/su | grep "auth sufficient pam_succeed_if.so use_uid user ingroup $group"
    if [[ $? -eq 0 ]]
    then
        echo "$group entry already found in /etc/pam.d/su"
    else
        echo "auth sufficient pam_succeed_if.so use_uid user ingroup $group" >> /etc/pam.d/su && echo "ädded entry of $group group in /etc/pam.d/su"
    fi
    echo "Users added into $group group, exiting script"
}

permissions() {
    if [[ "$EUID" -ne 0 ]] ; then
        echo 'run script with SUDO permissions'
        exit 1
    fi
}

run_script() {
    if [ "$file" == "" ] ; then
        echo "Please provide users file to script as $0 users.txt"
    else
        permissions
        check_grp

        exit
    fi
}

run_script