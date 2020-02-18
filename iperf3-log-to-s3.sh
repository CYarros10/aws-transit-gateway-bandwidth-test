#!/bin/sh

current_time=$(date "+%Y_%m_%d_%H_%M_%S")
iperf3 -c <insert-private-ip-here> -p 5201 --json &>> /iperf/client.json
aws s3 cp /iperf/client.json s3://<insert-s3-bucket-here>/client_$current_time.json
rm /iperf/client.json