# Incident Response Runbook

## Overview

This runbook provides procedures for responding to CloudWatch alarms and investigating infrastructure incidents. All alarms send notifications to the operations SNS topic with email delivery to evan.pratama@helios.id and yuwan.cornelius@helios.id.

## Prerequisites

### AWS CLI Configuration

```bash
aws --version
aws sts get-caller-identity
```

### Environment Variables

```bash
export ENVIRONMENT=dev  # or prod
export AWS_REGION=ap-southeast-2
```

## Alarm Response Procedures

### General Alarm Response Workflow

1. Receive SNS email notification with alarm details
2. Verify alarm state in CloudWatch console or CLI
3. Follow alarm-specific investigation steps below
4. Document findings and actions taken
5. Resolve underlying issue
6. Verify alarm returns to OK state
7. Update incident log

### Verify Alarm State

```bash
aws cloudwatch describe-alarms \
  --alarm-names ${ENVIRONMENT}-<alarm-name> \
  --region ap-southeast-2 \
  --query 'MetricAlarms[0].{Name:AlarmName,State:StateValue,Reason:StateReason,Time:StateUpdatedTimestamp}'
```

### View Alarm History

```bash
aws cloudwatch describe-alarm-history \
  --alarm-name ${ENVIRONMENT}-<alarm-name> \
  --region ap-southeast-2 \
  --max-records 10 \
  --history-item-type StateUpdate
```

## Unhealthy ALB Targets

### Alarm Details

- **Alarm Name**: `${ENVIRONMENT}-alb-unhealthy-targets`
- **Metric**: UnHealthyHostCount
- **Threshold**: > 0 for 2 consecutive periods
- **Impact**: Reduced capacity, potential service degradation

### Investigation Steps

#### Step 1: Check Target Health Status

```bash
aws elbv2 describe-target-groups \
  --region ap-southeast-2 \
  --query 'TargetGroups[?contains(TargetGroupName, `'${ENVIRONMENT}'`)].TargetGroupArn' \
  --output text | xargs -I {} aws elbv2 describe-target-health \
  --target-group-arn {} \
  --region ap-southeast-2
```

Expected output shows health status and reason for each target.

#### Step 2: Identify Unhealthy Targets

```bash
TG_ARN=$(aws elbv2 describe-target-groups \
  --region ap-southeast-2 \
  --query 'TargetGroups[?contains(TargetGroupName, `'${ENVIRONMENT}'`)].TargetGroupArn' \
  --output text)

aws elbv2 describe-target-health \
  --target-group-arn ${TG_ARN} \
  --region ap-southeast-2 \
  --query 'TargetHealthDescriptions[?TargetHealth.State!=`healthy`]'
```

Common unhealthy reasons:
- `Target.ResponseCodeMismatch`: Application returning wrong status code
- `Target.Timeout`: Health check timeout (application not responding)
- `Target.FailedHealthChecks`: Multiple consecutive health check failures

#### Step 3: Check EC2 Instance Status

```bash
INSTANCE_ID=$(aws elbv2 describe-target-health \
  --target-group-arn ${TG_ARN} \
  --region ap-southeast-2 \
  --query 'TargetHealthDescriptions[?TargetHealth.State!=`healthy`].Target.Id' \
  --output text)

aws ec2 describe-instance-status \
  --instance-ids ${INSTANCE_ID} \
  --region ap-southeast-2
```

Verify:
- Instance state is "running"
- System status checks passing
- Instance status checks passing

#### Step 4: Check Application Logs

```bash
aws logs tail /aws/web/${ENVIRONMENT}/ec2 \
  --follow \
  --filter-pattern "error" \
  --region ap-southeast-2
```

Look for:
- Application errors or crashes
- Port binding failures
- Configuration errors
- Resource exhaustion

#### Step 5: Check ALB Health Check Configuration

```bash
aws elbv2 describe-target-groups \
  --target-group-arns ${TG_ARN} \
  --region ap-southeast-2 \
  --query 'TargetGroups[0].{Path:HealthCheckPath,Port:HealthCheckPort,Protocol:HealthCheckProtocol,Interval:HealthCheckIntervalSeconds,Timeout:HealthCheckTimeoutSeconds,Healthy:HealthyThresholdCount,Unhealthy:UnhealthyThresholdCount}'
```

Verify health check path is accessible and returns expected status code.

#### Step 6: Test Health Check Endpoint

```bash
INSTANCE_IP=$(aws ec2 describe-instances \
  --instance-ids ${INSTANCE_ID} \
  --region ap-southeast-2 \
  --query 'Reservations[0].Instances[0].PrivateIpAddress' \
  --output text)

# From bastion or instance with VPC access
curl -v http://${INSTANCE_IP}:80/
```

### Resolution Actions

**If application is not responding:**

```bash
# Connect to instance via Session Manager
aws ssm start-session \
  --target ${INSTANCE_ID} \
  --region ap-southeast-2

# Check Nginx status
sudo systemctl status nginx

# Restart Nginx if needed
sudo systemctl restart nginx
```

**If instance is unhealthy:**

```bash
# Reboot instance
aws ec2 reboot-instances \
  --instance-ids ${INSTANCE_ID} \
  --region ap-southeast-2

# Monitor instance recovery
aws ec2 describe-instance-status \
  --instance-ids ${INSTANCE_ID} \
  --region ap-southeast-2
```

**If issue persists:**

```bash
# Terminate instance (Auto Scaling will replace if configured)
aws ec2 terminate-instances \
  --instance-ids ${INSTANCE_ID} \
  --region ap-southeast-2
```

### Verification

```bash
# Wait 2-3 minutes for health checks
aws elbv2 describe-target-health \
  --target-group-arn ${TG_ARN} \
  --region ap-southeast-2 \
  --query 'TargetHealthDescriptions[*].{Target:Target.Id,State:TargetHealth.State}'
```

All targets should show "healthy" state.

## High EC2 CPU Utilization

### Alarm Details

- **Alarm Name**: `${ENVIRONMENT}-ec2-high-cpu`
- **Metric**: CPUUtilization
- **Threshold**: > 80% for 5 consecutive periods
- **Impact**: Performance degradation, potential service slowdown

### Investigation Steps

#### Step 1: Check Current CPU Utilization

```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=${INSTANCE_ID} \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average,Maximum \
  --region ap-southeast-2
```

#### Step 2: Identify Top Processes

```bash
# Connect to instance
aws ssm start-session \
  --target ${INSTANCE_ID} \
  --region ap-southeast-2

# Check top processes
top -b -n 1 | head -20

# Check process CPU usage
ps aux --sort=-%cpu | head -10
```

#### Step 3: Check Application Metrics

```bash
# Check Nginx connections
curl http://localhost/nginx_status

# Check system load
uptime

# Check memory usage
free -h
```

#### Step 4: Review Recent Traffic Patterns

```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name RequestCount \
  --dimensions Name=LoadBalancer,Value=<alb-full-name> \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum \
  --region ap-southeast-2
```

#### Step 5: Check for Runaway Processes

```bash
# On instance
ps aux | grep -E 'Z|defunct'

# Check for high I/O wait
iostat -x 5 3
```

### Resolution Actions

**If traffic spike is causing high CPU:**

```bash
# Scale horizontally (if Auto Scaling configured)
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name web-asg-${ENVIRONMENT} \
  --desired-capacity <new-capacity> \
  --region ap-southeast-2
```

**If runaway process identified:**

```bash
# Kill problematic process
sudo kill -9 <pid>

# Restart application
sudo systemctl restart nginx
```

**If sustained high load:**

```bash
# Vertical scaling: change instance type
# 1. Stop instance
aws ec2 stop-instances \
  --instance-ids ${INSTANCE_ID} \
  --region ap-southeast-2

# 2. Wait for stopped state
aws ec2 wait instance-stopped \
  --instance-ids ${INSTANCE_ID} \
  --region ap-southeast-2

# 3. Modify instance type
aws ec2 modify-instance-attribute \
  --instance-id ${INSTANCE_ID} \
  --instance-type t3.small \
  --region ap-southeast-2

# 4. Start instance
aws ec2 start-instances \
  --instance-ids ${INSTANCE_ID} \
  --region ap-southeast-2
```

### Verification

```bash
# Monitor CPU for 10 minutes
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=${INSTANCE_ID} \
  --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Average \
  --region ap-southeast-2
```

CPU should be below 80% threshold.

## ALB 5xx Errors

### Alarm Details

- **Alarm Name**: `${ENVIRONMENT}-alb-5xx-errors`
- **Metric**: HTTPCode_Target_5XX_Count
- **Threshold**: > 5% error rate for 2 consecutive periods
- **Impact**: Service errors, user-facing failures

### Investigation Steps

#### Step 1: Check Current Error Rate

```bash
ALB_FULL_NAME=$(aws elbv2 describe-load-balancers \
  --region ap-southeast-2 \
  --query 'LoadBalancers[?contains(LoadBalancerName, `'${ENVIRONMENT}'`)].LoadBalancerArn' \
  --output text | cut -d: -f6 | cut -d/ -f2-)

aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name HTTPCode_Target_5XX_Count \
  --dimensions Name=LoadBalancer,Value=${ALB_FULL_NAME} \
  --start-time $(date -u -d '30 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Sum \
  --region ap-southeast-2
```

#### Step 2: Check ALB Access Logs

```bash
aws logs tail /aws/web/${ENVIRONMENT}/alb \
  --follow \
  --filter-pattern "[... status=5* ...]" \
  --region ap-southeast-2
```

Look for:
- Specific URLs returning 5xx
- Error patterns or frequency
- Client IPs or user agents

#### Step 3: Check Application Error Logs

```bash
aws logs tail /aws/web/${ENVIRONMENT}/ec2 \
  --follow \
  --filter-pattern "?error ?ERROR ?exception ?Exception" \
  --region ap-southeast-2 \
  --since 30m
```

Common error patterns:
- Database connection failures
- Timeout errors
- Application exceptions
- Configuration errors

#### Step 4: Check Target Response Time

```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name TargetResponseTime \
  --dimensions Name=LoadBalancer,Value=${ALB_FULL_NAME} \
  --start-time $(date -u -d '30 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Average,Maximum \
  --region ap-southeast-2
```

High response times may indicate application performance issues.

#### Step 5: Check Backend Service Health

```bash
# Connect to instance
aws ssm start-session \
  --target ${INSTANCE_ID} \
  --region ap-southeast-2

# Check Nginx error log
sudo tail -100 /var/log/nginx/error.log

# Check application status
sudo systemctl status nginx

# Test local endpoint
curl -v http://localhost/
```

#### Step 6: Review Recent Deployments

```bash
aws cloudformation describe-stack-events \
  --stack-name web-infrastructure-${ENVIRONMENT} \
  --region ap-southeast-2 \
  --max-items 20 \
  --query 'StackEvents[?ResourceStatus==`UPDATE_COMPLETE`]'
```

Check if errors started after recent deployment.

### Resolution Actions

**If application error identified:**

```bash
# Review application logs for stack trace
aws logs filter-log-events \
  --log-group-name /aws/web/${ENVIRONMENT}/ec2 \
  --filter-pattern "?error ?ERROR" \
  --start-time $(date -u -d '1 hour ago' +%s)000 \
  --region ap-southeast-2

# Restart application if needed
aws ssm start-session --target ${INSTANCE_ID} --region ap-southeast-2
sudo systemctl restart nginx
```

**If configuration issue:**

```bash
# Rollback to previous working version
# See rollback.md runbook for detailed steps
```

**If resource exhaustion:**

```bash
# Check disk space
df -h

# Check memory
free -h

# Clear logs if needed
sudo journalctl --vacuum-time=1d
```

**If database or backend service issue:**

```bash
# Check connectivity to backend services
# Verify security group rules
aws ec2 describe-security-groups \
  --group-ids <security-group-id> \
  --region ap-southeast-2

# Test connectivity
telnet <backend-host> <port>
```

### Verification

```bash
# Monitor error rate for 10 minutes
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name HTTPCode_Target_5XX_Count \
  --dimensions Name=LoadBalancer,Value=${ALB_FULL_NAME} \
  --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Sum \
  --region ap-southeast-2

# Check success rate
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name HTTPCode_Target_2XX_Count \
  --dimensions Name=LoadBalancer,Value=${ALB_FULL_NAME} \
  --start-time $(date -u -d '10 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 60 \
  --statistics Sum \
  --region ap-southeast-2
```

5xx error rate should be below 5% threshold.

## CloudFormation Stack Issues

### Check Stack Status

```bash
aws cloudformation describe-stacks \
  --stack-name web-infrastructure-${ENVIRONMENT} \
  --region ap-southeast-2 \
  --query 'Stacks[0].{Status:StackStatus,Reason:StackStatusReason}'
```

### Check Stack Events

```bash
aws cloudformation describe-stack-events \
  --stack-name web-infrastructure-${ENVIRONMENT} \
  --region ap-southeast-2 \
  --max-items 50 \
  --query 'StackEvents[?contains(ResourceStatus, `FAILED`)]'
```

### Check Nested Stack Issues

```bash
aws cloudformation describe-stacks \
  --region ap-southeast-2 \
  --query 'Stacks[?contains(StackName, `web-infrastructure-'${ENVIRONMENT}'`)].{Name:StackName,Status:StackStatus,Reason:StackStatusReason}'
```

## Incident Documentation

### Incident Log Template

```
Incident ID: INC-YYYY-MM-DD-NNN
Date/Time: YYYY-MM-DD HH:MM UTC
Environment: dev/prod
Severity: Critical/High/Medium/Low

Alarm Triggered:
- Alarm Name:
- Metric:
- Threshold Breached:

Investigation Summary:
- Root Cause:
- Affected Resources:
- Impact:

Resolution Actions:
- Actions Taken:
- Time to Resolution:

Verification:
- Alarm State: OK
- Service Status: Normal

Follow-up Actions:
- Preventive Measures:
- Documentation Updates:
```

### Save Incident Log

```bash
# Create incident log file
cat > incident-$(date +%Y%m%d-%H%M).md << 'EOF'
[Paste incident log template and fill in details]
EOF
```

## Escalation Procedures

### Severity Levels

**Critical (P1)**:
- Complete service outage
- All targets unhealthy
- Data loss risk
- Escalate immediately

**High (P2)**:
- Partial service degradation
- High error rates (>10%)
- Performance severely impacted
- Escalate within 15 minutes

**Medium (P3)**:
- Minor service degradation
- Intermittent errors
- Performance slightly impacted
- Escalate within 1 hour

**Low (P4)**:
- No user impact
- Monitoring alerts only
- Document and resolve during business hours

### Escalation Contacts

- Operations Team: evan.pratama@helios.id, yuwan.cornelius@helios.id
- AWS Support: Open case via AWS Console (for infrastructure issues)

### When to Escalate

- Unable to identify root cause within 30 minutes
- Resolution actions not effective
- Issue requires infrastructure changes
- Multiple alarms triggered simultaneously
- Security incident suspected

## Post-Incident Review

After incident resolution:

1. Document incident details in incident log
2. Update runbooks with lessons learned
3. Identify preventive measures
4. Schedule post-incident review meeting
5. Update monitoring thresholds if needed
6. Implement automation for common issues

## Related Documentation

- [Deployment Runbook](deployment.md)
- [Rollback Runbook](rollback.md)
- [Operations SOP](../sops/operations.md)
- [Change Management SOP](../sops/change-management.md)
