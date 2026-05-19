#!/bin/bash
set -e

# Variables
AWS_REGION="eu-north-1"
ECR_REPOSITORY="starttech-backend"
ASG_NAME="starttech-asg"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
ROLLBACK_TAG=$1

if [ -z "$ROLLBACK_TAG" ]; then
  echo "Usage: ./rollback.sh <image-tag>"
  echo "Example: ./rollback.sh abc1234"
  exit 1
fi

IMAGE_URI="$ECR_REGISTRY/$ECR_REPOSITORY:$ROLLBACK_TAG"

# Check AWS credentials
echo "Checking AWS credentials..."
aws sts get-caller-identity >/dev/null 2>&1 || { echo "AWS credentials not configured."; exit 1; }
echo "AWS credentials verified"

# Confirm rollback
read -p "Rolling back to $IMAGE_URI. Are you sure? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
  echo "Rollback cancelled."
  exit 0
fi

echo "Rolling back to $IMAGE_URI..."

# Deploy previous image via SSM
aws ssm send-command \
  --targets "Key=tag:aws:autoscaling:groupName,Values=$ASG_NAME" \
  --document-name "AWS-RunShellScript" \
  --parameters commands=["docker pull $IMAGE_URI","docker stop starttech-backend || true","docker rm starttech-backend || true","docker run -d --name starttech-backend -p 8080:8080 $IMAGE_URI"] \
  --region $AWS_REGION

echo "Rollback to $ROLLBACK_TAG completed successfully!"

# Run health check
echo "Running health check..."
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --names starttech-alb \
  --query "LoadBalancers[0].DNSName" \
  --output text)

bash "$(dirname "$0")/health-check.sh" $ALB_DNS
