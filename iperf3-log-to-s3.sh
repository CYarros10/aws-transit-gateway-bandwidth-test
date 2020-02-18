#!/bin/sh

current_time=$(date "+%Y_%m_%d_%H_%M_%S")
/bin/iperf3 -c <insert-private-ip-here> -p 5201 -f M --json &>> /iperf/client.json
/bin/aws s3 cp /iperf/client.json s3://<insert-s3-bucket-here>/client_$current_time.json
rm /iperf/client.json