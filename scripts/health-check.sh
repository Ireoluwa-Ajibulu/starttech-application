#!/bin/bash
set -e

# Variables
ALB_DNS=$1
MAX_RETRIES=5
RETRY_INTERVAL=10

if [ -z "$ALB_DNS" ]; then
  echo "Usage: ./health-check.sh <alb-dns-name>"
  exit 1
fi

echo "Running health check against $ALB_DNS..."

# Health check with retries
for i in $(seq 1 $MAX_RETRIES); do
  echo "Attempt $i of $MAX_RETRIES..."
  
  response=$(curl -s -o /dev/null -w "%{http_code}" http://$ALB_DNS/health)
  
  if [ "$response" -eq 200 ]; then
    echo "Health check passed with status $response"
    exit 0
  else
    echo "Health check failed with status $response"
    if [ $i -lt $MAX_RETRIES ]; then
      echo "Retrying in $RETRY_INTERVAL seconds..."
      sleep $RETRY_INTERVAL
    fi
  fi
done

echo "Health check failed after $MAX_RETRIES attempts"
exit 1
