#!/bin/bash

# Create AWS credentials and config files
mkdir -p /root/.aws

cat << EOF > /root/.aws/config
[default]
region = ${AWS_REGION}
EOF

cat << EOF > /root/.aws/credentials
[default]
aws_access_key_id = ${AWS_ACCESS_KEY_ID}
aws_secret_access_key = ${AWS_SECRET_ACCESS_KEY}
EOF

chmod 600 /root/.aws/*

printenv | grep -E 'AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY|AWS_HOSTED_ZONE_ID|AWS_RECORD_NAME|AWS_REGION' >> /etc/environment

# Start cron service
crond -f

