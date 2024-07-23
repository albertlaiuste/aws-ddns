#!/bin/bash

source /etc/environment

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Fetch current IP address
IP=$(curl -s http://checkip.amazonaws.com/)

# Validate IP address
if [[ ! $IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
  log "Invalid IP address: $IP"
  exit 1
fi

# Get current Route 53 record value
CURRENT_IP=$(aws route53 list-resource-record-sets --hosted-zone-id "$AWS_HOSTED_ZONE_ID" | \
  jq -r '.ResourceRecordSets[] | select(.Name == "'"$AWS_RECORD_NAME"'.") | select(.Type == "'"A"'") | .ResourceRecords[0].Value')

log "Current IP from Route 53: $CURRENT_IP"

# Check if IP is different from Route 53
if [ "$IP" == "$CURRENT_IP" ]; then
  log "IP has not changed, exiting."
  exit 0
fi

log "IP has changed, updating records."

ROUTE53_PAYLOAD=$(cat << EOF
{
  "Comment": "Updated from DDNS shell script",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$AWS_RECORD_NAME",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "$IP"
          }
        ]
      }
    }
  ]
}
EOF
)

# Update records
aws route53 change-resource-record-sets --hosted-zone-id "$AWS_HOSTED_ZONE_ID" --change-batch "$ROUTE53_PAYLOAD" >> /dev/null

if [ $? -eq 0 ]; then
  log "DNS record updated successfully."
else
  log "Failed to update DNS record."
  exit 1
fi

