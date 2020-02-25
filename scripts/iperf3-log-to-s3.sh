#!/bin/sh

current_time=$(date "+%Y_%m_%d_%H_%M_%S")

echo "Log: Performing iPerf3 bandwidth test..."
/bin/iperf3 -c <insert-private-ip-here> -p 5201 -t 50 -f M --json &>> /iperf/client.json

echo "Log: Sending iPerf3 logfile to S3..."
/bin/aws s3 cp /iperf/client.json s3://<insert-s3-bucket-here>/client_$current_time.json

echo "Log: Removing temporary log file to maintain storage capacity..."
rm /iperf/client.json
