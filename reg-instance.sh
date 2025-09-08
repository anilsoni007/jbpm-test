#!/bin/bash

# Register instance with ALB target group
set -e

# Load configuration
source config.env

echo "Registering instance with target group..."

# Get target group ARN
TG_ARN=$(aws elbv2 describe-target-groups \
    --names jbpm-tg \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text \
    --region $REGION)

# Register instance
aws elbv2 register-targets \
    --target-group-arn $TG_ARN \
    --targets Id=$INSTANCE_ID,Port=8080 \
    --region $REGION

# Get ALB DNS
ALB_DNS=$(aws elbv2 describe-load-balancers \
    --names jbpm-alb \
    --query 'LoadBalancers[0].DNSName' \
    --output text \
    --region $REGION)

echo "Instance registered successfully!"
echo "Access jBPM at: http://$ALB_DNS/business-central"
echo ""
echo "Next: Run 3-remove-public-access.sh to secure your instance"
