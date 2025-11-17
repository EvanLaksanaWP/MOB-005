#!/bin/bash

# Manual deployment script for debugging
ENVIRONMENT=dev
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="web-templates-${ENVIRONMENT}-${AWS_ACCOUNT_ID}"

echo "=== Uploading templates to S3 ==="
aws s3 cp templates/ s3://${BUCKET_NAME}/templates/ --recursive

echo "=== Validating main template ==="
aws cloudformation validate-template --template-body file://main.yaml

echo "=== Validating nested templates ==="
aws cloudformation validate-template --template-url https://${BUCKET_NAME}.s3.amazonaws.com/templates/network.yaml
aws cloudformation validate-template --template-url https://${BUCKET_NAME}.s3.amazonaws.com/templates/security.yaml
aws cloudformation validate-template --template-url https://${BUCKET_NAME}.s3.amazonaws.com/templates/alb.yaml
aws cloudformation validate-template --template-url https://${BUCKET_NAME}.s3.amazonaws.com/templates/ec2.yaml

echo "=== Deploying stack ==="
aws cloudformation deploy \
  --template-file main.yaml \
  --stack-name web-infrastructure-${ENVIRONMENT} \
  --parameter-overrides Environment=${ENVIRONMENT} \
  --capabilities CAPABILITY_IAM \
  --no-fail-on-empty-changeset

echo "=== Checking for errors ==="
aws cloudformation describe-stack-events \
  --stack-name web-infrastructure-${ENVIRONMENT} \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED` || ResourceStatus==`UPDATE_FAILED`].[LogicalResourceId,ResourceStatus,ResourceStatusReason]' \
  --output table