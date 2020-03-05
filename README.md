# transit-gateway-bandwidth-test

### Transit Gateway Bandwidth Testing via iPerf3

Proof of Concept to showcase the inter-VPC network speeds achieved with Transit Gateway.

### About

AWS Transit Gateway is a service that enables customers to connect their Amazon Virtual Private Clouds (VPCs) and their on-premises networks to a single gateway. As you grow the number of workloads running on AWS, you need to be able to scale your networks across multiple accounts and Amazon VPCs to keep up with the growth.

[via ![AWS Transit Gateway](https://aws.amazon.com/transit-gateway/)]

Transit Gateway offers the following bandwidth performance:

**Maximum bandwidth (burst) per VPC, Direct Connect gateway, or peered Transit Gateway connection: 50 Gbps**

This GitHub Repository offers a cloudformation template to test this limit.

----

## Architecture

![Stack-Resources](https://github.com/CYarros10/transit-gateway-bandwidth-test/blob/master/images/architecture-design-pattern.png)

----

## Deploying Cloudformation

### Step 1A: Existing architecture

Deploys iPerf3 EC2 client-server pairs in existing VPCs/subnets.

- Download/Clone git repo
- Go to Cloudformation Console and deploy cloudformation/master-existing-network.yml
- Supply the cloudformation template with all of your existing network information (VPC IDs, Subnet IDs, etc.)
- Important Parameters:
  - **pCronExpression** determines the cron schedule that you want to run the iperf tests
    - leave this field blank if you don't want to run iperf tests on a schedule
    - leave this field blank if you'd like to use SSM Run Command instead
  - **pFullTest** determines how many EC2's you'd like to deploy.
    - pFullTest = false : good for cost-effective debugging
    - pFullTest = true : will ensure maximizing TGW bandwidth

### (Optional) Step 1B: New architecture

Deploys an entirely brand new networking infrastructure.

- Download/Clone git repo
- Go to Cloudformation Console and deploy cloudformation/master-new-network.yml
- Important Parameters:
  - **pCronExpression** determines the cron schedule that you want to run the iperf tests
    - leave this field blank if you don't want to run iperf tests on a schedule
    - leave this field blank if you'd like to use SSM Run Command instead
  - **pFullTest** determines how many EC2's you'd like to deploy.
    - pFullTest = false : good for cost-effective debugging
    - pFullTest = true : will ensure maximizing TGW bandwidth
- Click next, then create.

## Performing iPerf3 Tests

### Step 2A : Cron Task

- If you left pCronExpression blank, move on to Step 2B. Otherwise:
- The cron task will automatically execute based on the provided cron expression. There's nothing you need to do.
- Wait 3-5 minutes for data to start trickling in.

### (Optional) Step 2B : SSM Run Command

- If you'd like to run commands on demand, you can use SSM Run Command
- Example AWS CLI Commands:

            aws ssm send-command --instance-ids "<ec2-instance-id" --document-name "AWS-RunShellScript" --comment "iPerf Test" --parameters commands=/iperf/transit-gateway-bandwidth-test/scripts/iperf3-log-to-s3.sh

            aws ssm send-command \
            --targets "Key=tag:Name,Values=iperf-client-to-server-1, iperf-client-to-server-2" \
            --document-name "AWS-RunShellScript" \
            --parameters commands=/iperf/transit-gateway-bandwidth-test/scripts/iperf3-log-to-s3.sh

## Gaining Insights

### Step 3A : Setup Cloudwatch Dashboard

- Go to Cloudwatch console
- Select Metrics -> Transit Gateway -> Per Transit Gateway Metrics -> Transit Gateway ID (if you don't know, its in VPC console) -> BytesIn + BytesOut
- Select Graphed Metrics Tab
- Specify Statistic = Sum, Period = Second
- Configure the graph title, window range, and auto-refresh to your desired settings.
- If you'd like to add to a Cloudwatch Dashboard: Select Actions -> Add to Dashboard

### (Optional) Step 3B : Query EC2 iPerf3 Client data with Amazon Athena

Note: This will not be data from TGW. This will be data from iperf3 client EC2s.

- Go to Amazon Athena console
- run the following queries (each in their own Query Tab) and make sure to insert your own bucket:

      CREATE EXTERNAL TABLE networkbenchmark (
        `intervals` array<struct<
          `sum`:struct<`bits_per_second`:decimal(38,10)>
        >>,
        instanceType string,
        region string
      )
      PARTITIONED BY (d date)
      ROW FORMAT SERDE 'org.openx.data.jsonserde.JsonSerDe'
      LOCATION 's3://BUCKET_NAME/';

----

      MSCK REPAIR TABLE networkbenchmark;

----

      SELECT
        round(CAST(min(interval.sum.bits_per_second)/1000000000 AS real),4) AS min,
        round(CAST(max(interval.sum.bits_per_second)/1000000000 AS real),4) AS max,
        round(CAST(avg(interval.sum.bits_per_second)/1000000000 AS real),4) AS avg,
        round(CAST(approx_percentile(interval.sum.bits_per_second, 0.95)/1000000000 AS real),4) AS percentile95,
        d,
        region,
        instanceType
      FROM networkbenchmark CROSS JOIN UNNEST(intervals) WITH ORDINALITY AS t(interval, counter)
      GROUP BY region, instanceType, d
      ORDER BY region, instanceType;

## Conclusion

Based on the Cloudwatch metrics over time, you should see, on average, *around 15 GB/s of inter-TGW traffic*.  Network bandwidth will occasionally reach 50 GB/s.

----

## FAQs

- **What is iPerf3?**

A traffic testing package. Learn more here: https://iperf.fr/

- **What's happening during cloudformation deployment?**

The master-new-network cloudformation template deploys three VPCs, both with public subnets and route tables, and a transit gateway with both VPCs attached.  Because Transit Gateway has a limit of 50GB/s and  EC2s have bandwidth limits, it is necessary to deploy at least several EC2s in each VPC. Transit Gateway allows us to use the Private IP address of the iPerf3 server EC2s, ensuring that no traffic is publicly facing.

- **How does the EC2 instance send traffic?**

Upon creation, each EC2 instance will pull code from this github repository via the User Data.  The iperf3-log-to-s3.sh script does the iperf3 client to iperf3 server traffic command.  The results of the command are delivered into a json log file and uploaded to a specified S3 bucket for archived analysis.
