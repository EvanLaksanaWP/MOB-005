# Rollback Runbook

## Overview

This runbook provides procedures for rolling back failed CloudFormation deployments in the web infrastructure. It covers automatic rollback triggers, verification steps, and manual intervention procedures.

## Automatic Rollback Triggers

### CloudFormation Automatic Rollback

CloudFormation automatically rolls back stack updates when:

- Resource creation or update fails
- Stack update timeout is exceeded
- Resource signal timeout occurs
- Dependency resolution fails

### Pipeline Rollback Behavior

The CodePipeline automatically triggers rollback when:

- CloudFormation deployment action fails
- Stack enters `UPDATE_ROLLBACK_IN_PROGRESS` state
- Stack enters `UPDATE_ROLLBACK_COMPLETE` state
- Stack enters `UPDATE_ROLLBACK_FAILED` state

## Verify Rollback Completion

### Check Stack Status

```bash
# Check main stack status
aws cloudformation describe-stacks \
  --stack-name web-infrastructure-dev \
  --region ap-southeast-2 \
  --query 'Stacks[0].StackStatus' \
  --output text

# Check all nested stacks
aws cloudformation list-stacks \
  --region ap-southeast-2 \
  --stack-status-filter UPDATE_ROLLBACK_COMPLETE UPDATE_ROLLBACK_FAILED \
  --query 'StackSummaries[?contains(StackName, `web-`)].{Name:StackName, Status:StackStatus}' \
  --output table
```

Expected status after successful rollback: `UPDATE_ROLLBACK_COMPLETE`

### Verify Resource State

```bash
# List all resources in stack
aws cloudformation list-stack-resources \
  --stack-name web-infrastructure-dev \
  --region ap-southeast-2 \
  --query 'StackResourceSummaries[*].{Resource:LogicalResourceId, Type:ResourceType, Status:ResourceStatus}' \
  --output table
```

All resources should show `UPDATE_ROLLBACK_COMPLETE` status.

### Check Pipeline Status

```bash
# Get pipeline execution status
aws codepipeline get-pipeline-state \
  --name web-pipeline-dev \
  --region ap-southeast-2 \
  --query 'stageStates[?stageName==`Deploy`].latestExecution.status' \
  --output text
```

## Check CloudFormation Stack Events

### View Recent Events

```bash
# View last 20 stack events
aws cloudformation describe-stack-events \
  --stack-name web-infrastructure-dev \
  --region ap-southeast-2 \
  --max-items 20 \
  --query 'StackEvents[*].{Time:Timestamp, Resource:LogicalResourceId, Status:ResourceStatus, Reason:ResourceStatusReason}' \
  --output table
```

### Filter Failed Events

```bash
# Show only failed resource events
aws cloudformation describe-stack-events \
  --stack-name web-infrastructure-dev \
  --region ap-southeast-2 \
  --query 'StackEvents[?contains(ResourceStatus, `FAILED`)].{Time:Timestamp, Resource:LogicalResourceId, Status:ResourceStatus, Reason:ResourceStatusReason}' \
  --output table
```

### View Nested Stack Events

```bash
# Get nested stack physical ID
NESTED_STACK_ID=$(aws cloudformation describe-stack-resource \
  --stack-name web-infrastructure-dev \
  --logical-resource-id MonitoringStack \
  --region ap-southeast-2 \
  --query 'StackResourceDetail.PhysicalResourceId' \
  --output text)

# View nested stack events
aws cloudformation describe-stack-events \
  --stack-name $NESTED_STACK_ID \
  --region ap-southeast-2 \
  --max-items 20 \
  --query 'StackEvents[*].{Time:Timestamp, Resource:LogicalResourceId, Status:ResourceStatus, Reason:ResourceStatusReason}' \
  --output table
```

## Review Failed Resource Events

### Identify Root Cause

```bash
# Find first failed resource
aws cloudformation describe-stack-events \
  --stack-name web-infrastructure-dev \
  --region ap-southeast-2 \
  --query 'StackEvents[?contains(ResourceStatus, `FAILED`)] | [0].{Resource:LogicalResourceId, Reason:ResourceStatusReason}' \
  --output table
```

### Common Failure Reasons

**Resource Creation Failures:**
- Insufficient IAM permissions
- Resource quota exceeded
- Invalid resource configuration
- Dependency resource not available

**Resource Update Failures:**
- Immutable property change requires replacement
- Resource in use by another service
- Invalid parameter value
- Service limit reached

### Check Resource Details

```bash
# Describe specific failed resource
aws cloudformation describe-stack-resource \
  --stack-name web-infrastructure-dev \
  --logical-resource-id <ResourceName> \
  --region ap-southeast-2 \
  --query 'StackResourceDetail.{Status:ResourceStatus, Reason:ResourceStatusReason, LastUpdated:LastUpdatedTimestamp}' \
  --output table
```

## Manual Stack Deletion

### When to Delete Manually

Delete stack manually when:

- Automatic rollback fails (`UPDATE_ROLLBACK_FAILED` state)
- Stack is stuck in `UPDATE_IN_PROGRESS` state
- Resources cannot be rolled back automatically
- Stack corruption requires clean slate

### Delete Stack Procedure

```bash
# Delete main stack (cascades to nested stacks)
aws cloudformation delete-stack \
  --stack-name web-infrastructure-dev \
  --region ap-southeast-2

# Monitor deletion progress
aws cloudformation wait stack-delete-complete \
  --stack-name web-infrastructure-dev \
  --region ap-southeast-2
```

### Handle Deletion Failures

```bash
# Check deletion status
aws cloudformation describe-stacks \
  --stack-name web-infrastructure-dev \
  --region ap-southeast-2 \
  --query 'Stacks[0].StackStatus' \
  --output text
```

If status is `DELETE_FAILED`:

```bash
# Identify resources that failed to delete
aws cloudformation describe-stack-events \
  --stack-name web-infrastructure-dev \
  --region ap-southeast-2 \
  --query 'StackEvents[?contains(ResourceStatus, `DELETE_FAILED`)].{Resource:LogicalResourceId, Type:ResourceType, Reason:ResourceStatusReason}' \
  --output table
```

### Force Delete with Retain

```bash
# Skip deletion of problematic resources
aws cloudformation delete-stack \
  --stack-name web-infrastructure-dev \
  --region ap-southeast-2 \
  --retain-resources <ResourceLogicalId>
```

Manual cleanup of retained resources required after stack deletion.

## Manual Redeployment

### Prerequisites

- Previous stack fully deleted or rolled back
- Root cause of failure identified and fixed
- Template changes committed to repository
- S3 bucket for nested templates available

### Redeployment via Pipeline

```bash
# Trigger pipeline manually
aws codepipeline start-pipeline-execution \
  --name web-pipeline-dev \
  --region ap-southeast-2

# Monitor pipeline execution
aws codepipeline get-pipeline-state \
  --name web-pipeline-dev \
  --region ap-southeast-2 \
  --query 'stageStates[*].{Stage:stageName, Status:latestExecution.status}' \
  --output table
```

### Manual Stack Deployment

```bash
# Deploy main stack directly
aws cloudformation deploy \
  --template-file main.yaml \
  --stack-name web-infrastructure-dev \
  --parameter-overrides Environment=dev \
  --capabilities CAPABILITY_IAM \
  --region ap-southeast-2
```

### Verify Deployment

```bash
# Check stack status
aws cloudformation describe-stacks \
  --stack-name web-infrastructure-dev \
  --region ap-southeast-2 \
  --query 'Stacks[0].{Status:StackStatus, Outputs:Outputs}' \
  --output table

# Verify all nested stacks
aws cloudformation list-stacks \
  --region ap-southeast-2 \
  --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
  --query 'StackSummaries[?contains(StackName, `web-`)].{Name:StackName, Status:StackStatus}' \
  --output table
```

## Rollback Decision Tree

```
Deployment Failed
    |
    ├─ Automatic rollback triggered?
    |   ├─ Yes → Wait for rollback completion
    |   |         └─ Status: UPDATE_ROLLBACK_COMPLETE?
    |   |             ├─ Yes → Investigate failure, fix, redeploy
    |   |             └─ No → Status: UPDATE_ROLLBACK_FAILED?
    |   |                     └─ Yes → Manual deletion required
    |   └─ No → Stack stuck in UPDATE_IN_PROGRESS?
    |           └─ Yes → Wait 30 minutes, then manual deletion
    |
    └─ Manual deletion completed?
        └─ Yes → Fix root cause → Redeploy via pipeline
```

## Post-Rollback Actions

### Investigate Root Cause

1. Review CloudFormation events for failure reason
2. Check CloudWatch Logs for application errors
3. Verify IAM permissions for deployment role
4. Confirm resource quotas not exceeded
5. Validate template syntax with cfn-lint

### Fix and Redeploy

1. Update CloudFormation templates to fix issue
2. Commit changes to repository
3. Create pull request for review
4. Merge to trigger pipeline deployment
5. Monitor deployment progress
6. Verify successful deployment

### Document Incident

1. Record failure timestamp and stack name
2. Document root cause and resolution
3. Update runbook if new failure pattern discovered
4. Share lessons learned with team
5. Update monitoring to detect similar issues

## Emergency Contacts

**Operations Team:**
- evan.pratama@helios.id
- yuwan.cornelius@helios.id

**Escalation:**
- Review CloudFormation events
- Check AWS Service Health Dashboard
- Open AWS Support case if service issue suspected
