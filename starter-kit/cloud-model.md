# Cloud Service Model Strategy

**Recommendation: Platform as a Service (PaaS) with strategic use of Infrastructure as a Service (IaaS)**

For the initial launch of KijaniKiosk, relying heavily on PaaS (like AWS Elastic Beanstalk, ECS/Fargate, or managed database services like Amazon RDS) is the most strategic choice.

**Reasoning:**
* **Undifferentiated Heavy Lifting:** As an early-stage platform, our engineering hours are better spent building core product features and data logic rather than patching operating systems, configuring network load balancers from scratch, or managing database backups.
* **Scalability:** PaaS solutions inherently handle auto-scaling and health checks.
* **Transition Path:** We will use IaaS (raw EC2 instances or custom VPC configurations) only for highly specialized workloads (like custom data processing models or specific legacy integrations) where PaaS does not offer the necessary granular control.