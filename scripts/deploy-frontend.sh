#!/bin/bash
set -e

echo "Deploying frontend to S3..."

# Variables
AWS_REGION="eu-north-1"
S3_BUCKET="starttech-frontend-production"
FRONTEND_DIR="$(dirname "$0")/../frontend"

# Check required tools
command -v aws >/dev/null 2>&1 || { echo "AWS CLI is required but not installed."; exit 1; }
command -v npm >/dev/null 2>&1 || { echo "npm is required but not installed."; exit 1; }

# Check AWS credentials
echo "Checking AWS credentials..."
aws sts get-caller-identity >/dev/null 2>&1 || { echo "AWS credentials not configured."; exit 1; }
echo "AWS credentials verified"

# Install dependencies
echo "Installing dependencies..."
cd $FRONTEND_DIR
npm ci

# Build frontend
echo "Building frontend..."
npm run build

# Sync to S3
echo "Syncing to S3..."
aws s3 sync dist/ s3://$S3_BUCKET \
  --delete \
  --cache-control "public, max-age=31536000" \
  --exclude "index.html"

aws s3 cp dist/index.html s3://$S3_BUCKET/index.html \
  --cache-control "no-cache, no-store, must-revalidate"

# Invalidate CloudFront
echo "Invalidating CloudFront cache..."
DISTRIBUTION_ID=$(aws cloudfront list-distributions \
  --query "DistributionList.Items[?Origins.Items[?DomainName contains '$S3_BUCKET']].Id" \
  --output text)

aws cloudfront create-invalidation \
  --distribution-id $DISTRIBUTION_ID \
  --paths "/*"

echo "Frontend deployed successfully!"
