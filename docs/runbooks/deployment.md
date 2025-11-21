# Deployment Runbook

## Prerequisites

### AWS CLI Configuration

Ensure AWS CLI is installed and configured with appropriate credentials:

```bash
aws --version
aws sts get-caller-identity
```

Required IAM permissions:
- CloudFormation: CreateStack, UpdateStack, DescribeStacks, DeleteStack
- S3: PutObject, GetObject (for template uploads)
- CodePipeline: GetPipelineState, StartPipelineExecution
- CodeBuild: BatchGetBuilds

### GitHub Access

Verify GitHub repository access and CodeConnections configuration:

```bash
aws codestar-connections list-connections --region ap-southeast-2
```

Connection status must be "AVAILABLE" for pipeline triggers to work.

### Environment Variables

Set target environment:

```bash
export ENVIRONMENT=dev  # or prod
export AWS_REGION=ap-southeast-2
```

## Deployment via Pipeline

### Step 1: Commit Changes

Push CloudFormation template changes to appropriate branch:

```bash
git add templates/*.yaml main.yaml
git commit -m "Update infrastructure templates"
git push origin dev  # for dev environment
# OR
git push origin main  # for prod environment
```

### Step 2: Monitor Pipeline Execution

Check pipeline status:

```bash
aws codepipeline get-pipeline-state \
  --name web-pipeline-${ENVIRONMENT} \
  --region ap-southeast-2
```

View pipeline execution in AWS Console:
- Navigate to CodePipeline service
- Select `web-pipeline-${ENVIRONMENT}`
- Monitor Source, Build, and Deploy stages

### Step 3: Monitor CodeBuild Execution

Get latest build ID:

```bash
aws codebuild list-builds-for-project \
  --project-name web-build-${ENVIRONMENT} \
  --region ap-southeast-2 \
  --max-items 1
```

View build logs:

```bash
aws codebuild batch-get-builds \
  --ids <build-id> \
  --region ap-southeast-2
```

### Step 4: Monitor CloudFormation Deployment

Check main stack status:

```bash
aws cloudformation describe-stacks \
  --stack-name web-infrastructure-${ENVIRONMENT} \
  --region ap-southeast-2 \
  --query 'Stacks[0].StackStatus'
```

Monitor stack events:

```bash
aws cloudformation describe-stack-events \
  --stack-name web-infrastructure-${ENVIRONMENT} \
  --region ap-southeast-2 \
  --max-items 20
```

Check nested stack status:

```bash
aws cloudformation describe-stacks \
  --region ap-southeast-2 \
  --query 'Stacks[?contains(StackName, `web-infrastructure-${ENVIRONMENT}`)].{Name:StackName,Status:StackStatus}'
```

## Validation Steps

### Verify Stack Outputs

Retrieve main stack outputs:

```bash
aws cloudformation describe-stacks \
  --stack-name web-infrastructure-${ENVIRONMENT} \
  --region ap-southeast-2 \
  --query 'Stacks[0].Outputs'
```

Expected outputs:
- VPCId
- ALBDNSName
- MonitoringSNSTopicArn
- DashboardName
- ALBLogGroupName
- EC2LogGroupName

### Verify ALB Health

Get ALB DNS name:

```bash
ALB_DNS=$(aws cloudformation describe-stacks \
  --stack-name web-infrastructure-${ENVIRONMENT} \
  --region ap-southeast-2 \
  --query 'Stacks[0].Outputs[?OutputKey==`ALBDNSName`].OutputValue' \
  --output text)
```

Test ALB endpoint:

```bash
curl -I http://${ALB_DNS}
```

Expected response: HTTP 200 OK

Check target health:

```bash
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn> \
  --region ap-southeast-2
```

All targets should show "healthy" state.

### Verify CloudWatch Dashboard

Access dashboard:

```bash
DASHBOARD_NAME=$(aws cloudformation describe-stacks \
  --stack-name web-infrastructure-${ENVIRONMENT} \
  --region ap-southeast-2 \
  --query 'Stacks[0].Outputs[?OutputKey==`DashboardName`].OutputValue' \
  --output text)

echo "Dashboard URL: https://console.aws.amazon.com/cloudwatch/home?region=ap-southeast-2#dashboards:name=${DASHBOARD_NAME}"
```

Verify dashboard displays:
- ALB request count
- ALB target response time
- ALB healthy/unhealthy target count
- EC2 CPU utilization
- EC2 network traffic

### Verify CloudWatch Alarms

List alarms:

```bash
aws cloudwatch describe-alarms \
  --alarm-name-prefix ${ENVIRONMENT} \
  --region ap-southeast-2 \
  --query 'MetricAlarms[*].{Name:AlarmName,State:StateValue}'
```

Expected alarms in OK state:
- `${ENVIRONMENT}-alb-unhealthy-targets`
- `${ENVIRONMENT}-alb-response-time`
- `${ENVIRONMENT}-alb-5xx-errors`
- `${ENVIRONMENT}-ec2-high-cpu`

### Verify CloudWatch Logs

Check log groups exist:

```bash
aws logs describe-log-groups \
  --log-group-name-prefix /aws/web \
  --region ap-southeast-2
```

Expected log groups:
- `/aws/web/${ENVIRONMENT}/alb`
- `/aws/web/${ENVIRONMENT}/ec2`

Verify log retention:

```bash
aws logs describe-log-groups \
  --log-group-name-prefix /aws/web \
  --region ap-southeast-2 \
  --query 'logGroups[*].{Name:logGroupName,Retention:retentionInDays}'
```

All log groups should have 30-day retention.

### Verify SNS Subscriptions

Get SNS topic ARN:

```bash
SNS_TOPIC=$(aws cloudformation describe-stacks \
  --stack-name web-infrastructure-${ENVIRONMENT} \
  --region ap-southeast-2 \
  --query 'Stacks[0].Outputs[?OutputKey==`MonitoringSNSTopicArn`].OutputValue' \
  --output text)
```

List subscriptions:

```bash
aws sns list-subscriptions-by-topic \
  --topic-arn ${SNS_TOPIC} \
  --region ap-southeast-2
```

Expected subscriptions:
- evan.pratama@helios.id (status: Confirmed)
- yuwan.cornelius@helios.id (status: Confirmed)

**IMPORTANT**: If subscription status is "PendingConfirmation", check email inbox and confirm subscription by clicking confirmation link.

## Automatic Rollback Behavior

### CloudFormation Automatic Rollback

CloudFormation automatically rolls back stack updates when:
- Resource creation fails
- Resource update fails
- Stack enters UPDATE_ROLLBACK_IN_PROGRESS state

Monitor rollback:

```bash
aws cloudformation describe-stack-events \
  --stack-name web-infrastructure-${ENVIRONMENT} \
  --region ap-southeast-2 \
  --query 'StackEvents[?ResourceStatus==`UPDATE_ROLLBACK_IN_PROGRESS` || ResourceStatus==`UPDATE_ROLLBACK_COMPLETE`]'
```

### Pipeline Automatic Rollback

CodePipeline does NOT automatically roll back on deployment failure. Manual intervention required.

## Manual Intervention Steps

### Deployment Failure Investigation

Check failed resource:

```bash
aws cloudformation describe-stack-events \
  --stack-name web-infrastructure-${ENVIRONMENT} \
  --region ap-southeast-2 \
  --query 'StackEvents[?ResourceStatus==`CREATE_FAILED` || ResourceStatus==`UPDATE_FAILED`]'
```

Review resource status reason:

```bash
aws cloudformation describe-stack-resources \
  --stack-name web-infrastructure-${ENVIRONMENT} \
  --region ap-southeast-2 \
  --query 'StackResources[?ResourceStatus==`CREATE_FAILED` || ResourceStatus==`UPDATE_FAILED`].{Resource:LogicalResourceId,Status:ResourceStatus,Reason:ResourceStatusReason}'
```

### Manual Rollback

If automatic rollback fails or stack is in UPDATE_ROLLBACK_FAILED state:

```bash
aws cloudformation continue-update-rollback \
  --stack-name web-infrastructure-${ENVIRONMENT} \
  --region ap-southeast-2
```

### Stack Deletion and Redeployment

If rollback cannot complete, delete and redeploy:

```bash
# Delete failed stack
aws cloudformation delete-stack \
  --stack-name web-infrastructure-${ENVIRONMENT} \
  --region ap-southeast-2

# Wait for deletion
aws cloudformation wait stack-delete-complete \
  --stack-name web-infrastructure-${ENVIRONMENT} \
  --region ap-southeast-2

# Trigger pipeline for redeployment
aws codepipeline start-pipeline-execution \
  --name web-pipeline-${ENVIRONMENT} \
  --region ap-southeast-2
```

### Common Failure Scenarios

**Scenario 1: Insufficient IAM Permissions**

Error: "User is not authorized to perform X on resource Y"

Resolution:
- Review IAM role policies for CodeBuild and CloudFormation
- Add missing permissions to service roles
- Redeploy via pipeline

**Scenario 2: Resource Limit Exceeded**

Error: "LimitExceeded: Cannot create more than X resources"

Resolution:
- Request service quota increase via AWS Support
- Delete unused resources in account
- Retry deployment after quota increase

**Scenario 3: Resource Already Exists**

Error: "Resource X already exists"

Resolution:
- Check for orphaned resources from previous failed deployments
- Delete conflicting resource manually
- Retry deployment

**Scenario 4: Nested Stack Failure**

Error: "Nested stack X failed to create/update"

Resolution:
- Check nested stack events for specific failure
- Fix template issue in nested stack
- Commit fix and trigger pipeline

**Scenario 5: SNS Subscription Not Confirmed**

Warning: SNS subscription in "PendingConfirmation" state

Resolution:
- Check email inbox for confirmation message
- Click confirmation link in email
- Verify subscription status changes to "Confirmed"
- No redeployment needed

## Post-Deployment Checklist

- [ ] All CloudFormation stacks show CREATE_COMPLETE or UPDATE_COMPLETE status
- [ ] ALB endpoint responds with HTTP 200
- [ ] All ALB targets show healthy status
- [ ] CloudWatch dashboard displays metrics
- [ ] All CloudWatch alarms in OK state
- [ ] CloudWatch log groups created with 30-day retention
- [ ] SNS subscriptions confirmed for both email addresses
- [ ] Pipeline execution completed successfully

## Troubleshooting

### Pipeline Not Triggering

Check CodeConnections status:

```bash
aws codestar-connections list-connections --region ap-southeast-2
```

If status is not "AVAILABLE", reconnect GitHub integration in AWS Console.

### Build Failing

View CodeBuild logs:

```bash
aws codebuild batch-get-builds \
  --ids <build-id> \
  --region ap-southeast-2 \
  --query 'builds[0].logs.deepLink'
```

Common build failures:
- CFN-Lint validation errors: Fix template syntax
- S3 upload failures: Check S3 bucket permissions
- Template not found: Verify S3 bucket path in main.yaml

### Stack Update Blocked

If stack shows UPDATE_IN_PROGRESS for extended period:

```bash
aws cloudformation cancel-update-stack \
  --stack-name web-infrastructure-${ENVIRONMENT} \
  --region ap-southeast-2
```

Wait for cancellation to complete, then retry deployment.

## Emergency Contacts

For deployment issues requiring escalation:
- Operations Team: evan.pratama@helios.id, yuwan.cornelius@helios.id
- AWS Support: Open case via AWS Console

## Related Documentation

- [Incident Response Runbook](incident-response.md)
- [Rollback Runbook](rollback.md)
- [Change Management SOP](../sops/change-management.md)
- [Release Process SOP](../sops/release-process.md)
