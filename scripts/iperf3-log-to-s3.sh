#!/bin/sh

current_time=$(date "+%s")
current_day=$(date "+%Y-%m-%d")

INSTANCE_TYPE=`curl http://169.254.169.254/latest/meta-data/instance-type`
EC2_AVAIL_ZONE=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
EC2_REGION="`echo \"$EC2_AVAIL_ZONE\" | sed 's/[a-z]$//'`"
echo "{\"instance-type\":\"${INSTANCE_TYPE}\", \"region\":\"${EC2_REGION}\"}" > /iperf/instance-data.json

echo "Log: Performing iPerf3 bandwidth test..."
/bin/iperf3 -c <insert-private-ip-here> -p 5201 -t 50 -f M --json &>> /iperf/client.json


echo "Log: appending instance-type and region..."
jq -s add client.json instance-data.json

echo "Log: Sending iPerf3 logfile to S3..."
# /bin/aws s3 cp /iperf/client.json s3://<insert-s3-bucket-here>/client_$current_time.json # Amazon Linux
/usr/local/bin/aws s3 cp /iperf/client.json s3://<insert-s3-bucket-here>/d=$current_day/$INSTANCE_TYPE-$current_time.json # RHEL

echo "Log: Removing temporary log file to maintain storage capacity..."
rm /iperf/client.json
