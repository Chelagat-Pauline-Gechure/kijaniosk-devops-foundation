# KijaniKiosk Deployment: Week 7 vs Week 8

## Summary

KijaniKiosk's payment service has been running in two different deployment models over the
past two weeks. The Week 7 model deployed the application directly onto a virtual server and
used a traffic-switching script to move between versions. The Week 8 model packages the
application into a self-contained image, stores it in a versioned private registry, and runs it
on a cluster that manages the application's health automatically.

The difference that matters most for the board is this: in the Week 7 model, a server failure
requires a human to respond, provision a replacement, and restore the service manually. In
the Week 8 model, the cluster detected a failed instance and replaced it in 60 seconds,
without any human action, while the second instance continued serving traffic throughout.
The service never went down.

The application image was reduced from approximately 200MB in a naive single-stage build
to 127MB using a two-stage build process that strips out all development tooling before
the final image is produced. The application code itself adds less than 8KB to the base
runtime — the multi-stage approach ensures nothing unnecessary enters production.

## Comparison

| Concern | Week 7 Approach | Week 8 Approach |
|---|---|---|
| Deployment mechanism | A packaged application was transferred to a virtual server, unpacked, and started as a background service. Switching versions required updating a traffic-routing configuration file and reloading it manually. | The application is packaged into a versioned image stored in a private registry. Deployment is a single declarative file stating the desired state. Applying it causes the cluster to pull the image and start the correct number of instances automatically. |
| Rollback mechanism | A rollback script switched the traffic-routing configuration back to the previous version in 18 seconds. The previous version had to be running in a standby environment, which required pre-provisioning a second server. | Rollback is a one-field change in the deployment file — updating the image version reference — followed by reapplying it. No standby environment needs to be pre-provisioned. The cluster performs the swap using the same process as a forward deployment. |
| Failure recovery | A server failure took the application offline until an engineer provisioned a replacement, configured it, deployed the application, and updated the traffic router. No automation handled unplanned failures. | When one instance was deleted in today's measurement, a replacement was running in 60 seconds. The second instance served all traffic during this window. No human action was required at any point in the recovery. |
| Scaling | Adding capacity required provisioning a new virtual server, running the configuration management process against it, deploying the application, and updating the traffic router to include it. | Changing one number in the deployment file and reapplying it causes the cluster to schedule the additional instance, pull the image, and begin routing traffic to it automatically in under 30 seconds. |

## What This Week's Approach Does Not Yet Solve

The current deployment hardcodes environment-specific values directly in the deployment
file, including the runtime mode and port. This means the same file cannot be used for both
staging and a future production environment without manual editing. A payment service in
production also requires credentials such as database connection details and third-party
keys, which cannot safely be stored in a deployment file committed to version control. The
next stage of work introduces a mechanism for separating configuration from the deployment
definition entirely, so the deployment file stays identical across environments and only the
configuration values change per environment. Until that work is complete, this deployment
is not production-ready in the configuration management sense.
