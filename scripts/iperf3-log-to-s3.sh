#!/bin/sh

# getting current time information for log purposes
current_time=$(date "+%s")
current_day=$(date "+%Y-%m-%d")

# getting current instance data
INSTANCE_TYPE=`curl http://169.254.169.254/latest/meta-data/instance-type`
EC2_AVAIL_ZONE=`curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone`
EC2_REGION="`echo \"$EC2_AVAIL_ZONE\" | sed 's/[a-z]$//'`"
echo "{\"instanceType\":\"${INSTANCE_TYPE}\", \"region\":\"${EC2_REGION}\"}" > /iperf/instance-data.json

# Performing iPerf3 bandwidth test
/bin/iperf3 -c <insert-private-ip-here> -p 5201 -P 10 -t 30 -f M --json &>> /iperf/client.json

# appending instance-type and region
/bin/jq -s add /iperf/client.json /iperf/instance-data.json > /iperf/iperf-log.json

# removing unnecessary data points
cat /iperf/iperf-log.json | /bin/jq '.intervals[] |= del(.streams, .sum.start, .sum.end, .sum.seconds, .sum.bytes, .sum.retransmits, .sum.omitted)' | jq 'del(.end, .start)' > /iperf/simplified.json

# flattening json for athena optimization
/bin/jq -c . /iperf/simplified.json > /iperf/optimized.json

# Sending iPerf3 logfile to S3
# /bin/aws s3 cp /iperf/client.json s3://<insert-s3-bucket-here>/client_$current_time.json # Amazon Linux
/usr/local/bin/aws s3 cp /iperf/optimized.json s3://<insert-s3-bucket-here>/d=$current_day/$INSTANCE_TYPE-$current_time.json # RHEL

# Removing temporary log files to maintain storage capacity
rm /iperf/client.json
rm /iperf/instance-data.json
rm /iperf/iperf-log.json
rm /iperf/simplified.json
rm /iperf/optimized.json
