#!/bin/sh

#### Log Location variables ####
Tomcat_Location="/var/log/tomcat7/"
Tomcat8_Location="/var/log/tomcat8/"
app_location="/home/river/services/logs"
temp_backup_location="$app_location/log_backup/"
noofdays=1
bkp_svr="172.16.0.132"
archive_folder_details=river@$bkp_svr:/home/river/logs

#################################

#### Create temp backup folder if not present ####
if [ ! -d $temp_backup_location/$(hostname)/tomcat7 ]; then
    mkdir -p $temp_backup_location/$(hostname)/tomcat7
fi
if [ ! -d $temp_backup_location/$(hostname)/tomcat8 ]; then
    mkdir -p $temp_backup_location/$(hostname)/tomcat8
fi
if [ ! -d $temp_backup_location/$(hostname)/app ]; then
    mkdir -p $temp_backup_location/$(hostname)/app
fi
###################################################

#### Check log location and move files if found ####
if [ -d $Tomcat_Location ]; then
    cd $Tomcat_Location
    for tomcatfile in `find $Tomcat_Location -maxdepth 1 -mtime $noofdays -type f \( -name "catalina*" -o -name "localhost_access_log*" \)`; do
        mv "$tomcatfile" "$temp_backup_location/$(hostname)/tomcat7/"
    done
    cd "$temp_backup_location/$(hostname)/tomcat7/"
    for zipfile in `ls -I "*.gz"`; do
        gzip $zipfile
    done
fi
####################################################

#### Check log location and move files if found ####
if [ -d $Tomcat8_Location ]; then
    cd $Tomcat8_Location
    for tomcat8file in `find $Tomcat8_Location -maxdepth 1 -mtime $noofdays -type f \( -name "catalina*" -o -name "localhost_access_log*" \)`; do
        mv "$tomcat8file" "$temp_backup_location/$(hostname)/tomcat8/"
    done
    cd "$temp_backup_location/$(hostname)/tomcat8/"
    for zipfile in `ls -I "*.gz"`; do
        gzip $zipfile
    done
fi
####################################################

#### Check log location and move files if found ####
if [ -d $app_location ]; then
    cd $app_location
    for appfile in `find $app_location -maxdepth 1 -mtime $noofdays -type f \( -name "*log_*" -o -name "*log-*" -o -name "*log.*" -o -name "backup_2*" \)`; do
        mv "$appfile" "$temp_backup_location/$(hostname)/app"
    done
    cd "$temp_backup_location/$(hostname)/app/"
    for zipfile in `ls -I "*.gz"`; do
        gzip $zipfile
    done
fi
####################################################

##### Copy log files from server to Archive location ####
cd $temp_backup_location

sshpass -p "Rpl@Stage123" ssh -q "-oStrictHostKeyChecking=no" river@$bkp_svr "mkdir -p ~/logs/$(hostname)"
sshpass -p "Rpl@Stage123" scp -r "-oStrictHostKeyChecking=no" "$(hostname)" "$archive_folder_details"
if [ $? -eq 0 ]; then
    cd $temp_backup_location/$(hostname)/
    rm -r *
fi
##########################################################