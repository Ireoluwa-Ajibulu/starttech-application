#!/bin/bash
set -e

echo "Deploying backend to EC2..."

# Variables
AWS_REGION="eu-north-1"
ECR_REPOSITORY="starttech-backend"
ASG_NAME="starttech-asg"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
IMAGE_TAG="${1:-latest}"
IMAGE_URI="$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG"
BACKEND_DIR="$(dirname "$0")/../backend/MuchToDo"

# Check required tools
command -v aws >/dev/null 2>&1 || { echo "AWS CLI is required but not installed."; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "Docker is required but not installed."; exit 1; }

# Check AWS credentials
echo "Checking AWS credentials..."
aws sts get-caller-identity >/dev/null 2>&1 || { echo "AWS credentials not configured."; exit 1; }
echo "AWS credentials verified"

# Build Docker image
echo "Building Docker image..."
cd $BACKEND_DIR
docker build -t $IMAGE_URI .

# Login to ECR
echo "Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $ECR_REGISTRY

# Push image to ECR
echo "Pushing image to ECR..."
docker push $IMAGE_URI

# Deploy to EC2 via SSM
echo "Deploying to EC2 instances..."
aws ssm send-command \
  --targets "Key=tag:aws:autoscaling:groupName,Values=$ASG_NAME" \
  --document-name "AWS-RunShellScript" \
  --parameters commands=["docker pull $IMAGE_URI","docker stop starttech-backend || true","docker rm starttech-backend || true","docker run -d --name starttech-backend -p 8080:8080 $IMAGE_URI"] \
  --region $AWS_REGION

echo "Backend deployed successfully!"
