# transit-gateway-bandwidth-test

### Transit Gateway Bandwidth Testing via iPerf3

Proof of Concept to showcase the inter-VPC network speeds achieved with Transit Gateway.

### About

AWS Transit Gateway is a service that enables customers to connect their Amazon Virtual Private Clouds (VPCs) and their on-premises networks to a single gateway. As you grow the number of workloads running on AWS, you need to be able to scale your networks across multiple accounts and Amazon VPCs to keep up with the growth.

With AWS Transit Gateway, you only have to create and manage a single connection from the central gateway in to each Amazon VPC, on-premises data center, or remote office across your network. Transit Gateway acts as a hub that controls how traffic is routed among all the connected networks which act like spokes. This hub and spoke model significantly simplifies management and reduces operational costs because each network only has to connect to the Transit Gateway and not to every other network. Any new VPC is simply connected to the Transit Gateway and is then automatically available to every other network that is connected to the Transit Gateway. This ease of connectivity makes it easy to scale your network as you grow.

via ![AWS Transit Gateway](https://aws.amazon.com/transit-gateway/)

Transit Gateway offers the following Performance and Limits:
**Maximum bandwidth (burst) per VPC, Direct Connect gateway, or peered Transit Gateway connection: 50 Gbps**

This GitHub Repository offers a cloudformation template to test this limit.

----

## Architecture

![Stack-Resources](https://github.com/CYarros10/aws-elasticsearch-sentiment/blob/master/images/architecture-design-pattern.png)

----

