#!/bin/bash

# Setup ALB for jBPM using existing VPC and subnets
set -e

# Load configuration
source config.env

echo "Setting up ALB for jBPM using existing VPC..."

# Create security group for ALB
SG_ID=$(aws ec2 create-security-group \
    --group-name jbpm-alb-sg \
    --description "jBPM ALB Security Group" \
    --vpc-id $VPC_ID \
    --region $REGION \
    --query 'GroupId' \
    --output text)

# Allow HTTP traffic
aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0 \
    --region $REGION

# Create ALB
ALB_ARN=$(aws elbv2 create-load-balancer \
    --name jbpm-alb \
    --subnets $SUBNET1_ID $SUBNET2_ID \
    --security-groups $SG_ID \
    --region $REGION \
    --query 'LoadBalancers[0].LoadBalancerArn' \
    --output text)

# Create target group
TG_ARN=$(aws elbv2 create-target-group \
    --name jbpm-tg \
    --protocol HTTP \
    --port 8080 \
    --vpc-id $VPC_ID \
    --target-type instance \
    --health-check-path /business-central \
    --region $REGION \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)

# Create listener
aws elbv2 create-listener \
    --load-balancer-arn $ALB_ARN \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn=$TG_ARN \
    --region $REGION

# Get ALB DNS
ALB_DNS=$(aws elbv2 describe-load-balancers \
    --load-balancer-arns $ALB_ARN \
    --query 'LoadBalancers[0].DNSName' \
    --output text \
    --region $REGION)

echo "ALB created successfully!"
echo "ALB DNS: $ALB_DNS"
echo ""
echo "Next: Run 2-register-instance.sh"
