#!/bin/bash

IPLIST=${1}
USERLIST=${2}

process() {
  for ip in `cat $IPLIST`
  do
    scp -o ConnectTimeout=10 -o StrictHostKeyChecking=no $USERLIST $ip:/tmp/ >> /dev/null
    if [[ $? -eq 0 ]] ; then
      echo "Successfull login on $ip"
      ssh -T -o ConnectTimeout=10 -o StrictHostKeyChecking=no $ip '/bin/bash' << 'EOF'
echo "**********************************"
cat /tmp/users | while read user
do
echo "Checking $user access on $(hostname -I)"
sudo cat /etc/passwd | grep $user >> /dev/null && echo "Found $user user entry in /etc/passwd" || echo "$user user entry in /etc/passwd not found"
sudo test -f /home/$user/.ssh/authorized_keys && echo "Found $user user authorized_keys in .ssh" || echo "$user user authorized_keys in .ssh not found"
sudo cat /etc/sudoers | grep $user >> /dev/null && echo "$user user had sudo access" || echo "$user user sudo access not found"
echo "**********************************"
done 
EOF
    else
      echo "Unsuccessfull login $ip"
    fi
    echo "####### Exiting $ip #######"
  done
}

validate() {
  if [ "$(basename $IPLIST)" != "ips" ] ; then
    echo "The file name containing ip's must be ips, please rename, exiting script"
    exit 1
  elif [ "$(basename $USERLIST)" != "users" ] ; then
    echo "The file name containing users list must be users, please rename, exiting script"
    exit 1
  else
    avoid_null
  fi
}

avoid_null() {
  [[ -s "$IPLIST" ]] || { echo "The ips file is empty, exiting script"; exit 1; }
  [[ -s "$USERLIST" ]] || { echo "The users file is empty, exiting script"; exit 1; }
  process
  exit
}

run_script() {
  if [ "$IPLIST" == "" ] ; then
    echo "Please provide ips file location to script as $0 ips users"
    exit 1
  elif [ "$USERLIST" = "" ] ; then
    echo "Please provide users file location to script as $0 ips users"
    exit 1
  else
    validate
  fi
}

run_script


