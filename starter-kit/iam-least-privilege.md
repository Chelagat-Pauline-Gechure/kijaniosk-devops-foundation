# IAM Least Privilege Design

**Scenario:** We have a backend application service (e.g., an invoice generator or a data aggregator) running on an EC2 instance. It needs to read raw files from a specific S3 bucket and write logs to CloudWatch. It should *not* have access to customer databases or other S3 buckets.

**Application Task Role Policy:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowReadSpecificBucket",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::kijanikiosk-app-assets",
        "arn:aws:s3:::kijanikiosk-app-assets/*"
      ]
    },
    {
      "Sid": "AllowApplicationLogging",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:log-group:/application/kijanikiosk-backend:*"
    }
  ]
}