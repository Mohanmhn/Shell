#!/bin/sh
log_location="/home/river/services/logs"
cd $log_location
for zipfile in `ls *log_2*`
do
gzip $zipfile
wait $!
done