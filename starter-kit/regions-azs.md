# Region and Availability Zone Strategy

**Region Selection: `af-south-1` (Cape Town) or `eu-west-1` (Ireland)**
Assuming KijaniKiosk's primary customer base is in East Africa, we should deploy our infrastructure as close to the users as possible to minimize latency. `af-south-1` provides the best geographical proximity. If certain advanced cloud services are unavailable in that region, `eu-west-1` serves as the standard fallback due to its excellent connectivity and comprehensive service offerings.

**Reliability Thinking: Multi-AZ Architecture**
A Region consists of multiple isolated data centers known as Availability Zones (AZs). KijaniKiosk will utilize a **Multi-AZ architecture**.
* **Compute:** Our application servers will be deployed across at least two AZs behind a Load Balancer. If one data center experiences a power outage or network failure, traffic is automatically routed to the healthy AZ.
* **Data:** Our primary database will have a synchronous standby replica in a second AZ. This ensures zero data loss and minimal downtime during an unexpected failure.