# MOB-005 Operations Compliance Evidence Package

## Overview

This directory contains evidence artifacts demonstrating compliance with AWS Migration Services Competency requirement MOB-005 (Operations). The evidence shows operational models, monitoring infrastructure, and documented procedures for managing AWS infrastructure.

## Evidence Artifacts

### 1. Infrastructure-as-Code Templates

**Location**: Root directory and `templates/` folder

CloudFormation templates defining all infrastructure and monitoring resources:

- `main.yaml` - Main orchestration template with nested stack architecture
- `templates/network.yaml` - VPC, subnets, routing, and network infrastructure
- `templates/security.yaml` - Security groups and network access controls
- `templates/alb.yaml` - Application Load Balancer configuration
- `templates/ec2.yaml` - EC2 instances with detailed monitoring enabled
- `templates/monitoring.yaml` - CloudWatch dashboards, alarms, log groups, and SNS topics

**Compliance Mapping**: Demonstrates infrastructure-as-code approach with version-controlled, automated deployment.

### 2. Monitoring Infrastructure

**CloudWatch Dashboards**

Dashboard Name: `{Environment}-infrastructure-dashboard`

Access via AWS Console:
1. Navigate to CloudWatch service in ap-southeast-2 region
2. Select "Dashboards" from left navigation
3. Open dashboard named `dev-infrastructure-dashboard` or `prod-infrastructure-dashboard`

Dashboard displays:
- ALB request count, response time, healthy/unhealthy targets
- ALB 4xx and 5xx error rates
- EC2 CPU utilization, network traffic, status checks
- Current alarm states

**CloudWatch Alarms**

Alarm Names:
- `{Environment}-alb-unhealthy-targets` - Monitors unhealthy target count
- `{Environment}-alb-response-time` - Monitors target response time
- `{Environment}-alb-5xx-errors` - Monitors 5xx error rate
- `{Environment}-ec2-high-cpu` - Monitors EC2 CPU utilization

Access via AWS Console:
1. Navigate to CloudWatch service in ap-southeast-2 region
2. Select "Alarms" from left navigation
3. View alarm status, history, and configuration

**SNS Notifications**

Topic Name: `{Environment}-operations-notifications`

Email subscriptions configured for:
- evan.pratama@helios.id
- yuwan.cornelius@helios.id

Access via AWS Console:
1. Navigate to SNS service in ap-southeast-2 region
2. Select "Topics" from left navigation
3. Open topic named `dev-operations-notifications` or `prod-operations-notifications`
4. View subscriptions and delivery status

### 3. Logging Infrastructure

**CloudWatch Log Groups**

Log Group Names:
- `/aws/alb/{Environment}` - ALB access logs
- `/aws/ec2/{Environment}` - EC2 system and application logs

Access via AWS Console:
1. Navigate to CloudWatch service in ap-southeast-2 region
2. Select "Log groups" from left navigation
3. Open log group to view log streams

Retention: 30 days for all log groups

**Sample Log Queries**

Query 5xx errors in ALB logs:
```
fields @timestamp, request, status, target_status_code
| filter status >= 500
| sort @timestamp desc
| limit 100
```

Query high CPU events in EC2 logs:
```
fields @timestamp, @message
| filter @message like /CPU/
| sort @timestamp desc
| limit 50
```

Query error patterns:
```
fields @timestamp, @message
| filter @message like /ERROR/ or @message like /error/
| stats count() by bin(5m)
```

### 4. Operational Documentation

**Runbooks** (`docs/runbooks/`)

- `deployment.md` - Step-by-step deployment procedures via CI/CD pipeline
- `incident-response.md` - Procedures for responding to CloudWatch alarms and incidents
- `rollback.md` - Rollback procedures for failed deployments

**Standard Operating Procedures** (`docs/sops/`)

- `change-management.md` - Process for proposing and approving infrastructure changes
- `release-process.md` - Release procedures for dev and prod environments
- `operations.md` - Daily, weekly, and monthly operational procedures

**Compliance Mapping**: Demonstrates documented operational procedures covering deployment, incident management, change control, and routine operations.

### 5. CI/CD Pipeline

**Pipeline Stacks**

- `pipeline-dev.yaml` - Dev environment pipeline (triggered by `dev` branch)
- `pipeline-prod.yaml` - Prod environment pipeline (triggered by `main` branch)

**Build Specifications**

- `buildspec.yml` - Deployment automation for CodeBuild
- `buildspec-test.yml` - Testing automation (CFN-Lint + TaskCat)

**Pipeline Execution**

Access via AWS Console:
1. Navigate to CodePipeline service in ap-southeast-2 region
2. Select pipeline: `web-pipeline-dev` or `web-pipeline-prod`
3. View execution history, stage status, and deployment logs

**Compliance Mapping**: Demonstrates automated deployment process with testing and validation.

## Capturing Evidence Screenshots

### CloudWatch Dashboard

1. Open AWS Console and navigate to CloudWatch in ap-southeast-2
2. Select "Dashboards" and open the infrastructure dashboard
3. Ensure time range shows recent data (last 1 hour or 3 hours)
4. Capture full-page screenshot showing all widgets
5. Save as `cloudwatch-dashboard-{environment}.png`

### CloudWatch Alarms

1. Navigate to CloudWatch > Alarms
2. Filter by environment prefix (dev- or prod-)
3. Capture screenshot showing all alarms with current state
4. Save as `cloudwatch-alarms-{environment}.png`

### CloudWatch Logs

1. Navigate to CloudWatch > Log groups
2. Open a log group and select a recent log stream
3. Capture screenshot showing log entries
4. Save as `cloudwatch-logs-{environment}.png`

### SNS Topic Configuration

1. Navigate to SNS > Topics
2. Open operations notification topic
3. Capture screenshot showing subscriptions and configuration
4. Save as `sns-topic-{environment}.png`

### Pipeline Execution

1. Navigate to CodePipeline
2. Open pipeline and view recent execution
3. Capture screenshot showing successful deployment stages
4. Save as `pipeline-execution-{environment}.png`

## Verification Checklist

Use this checklist to verify MOB-005 compliance evidence is complete:

- [ ] CloudFormation templates for all infrastructure components
- [ ] CloudFormation template for monitoring infrastructure (monitoring.yaml)
- [ ] CloudWatch dashboard configured and accessible
- [ ] CloudWatch alarms configured for critical metrics
- [ ] SNS topic with email subscriptions configured
- [ ] CloudWatch log groups with 30-day retention
- [ ] Deployment runbook with step-by-step procedures
- [ ] Incident response runbook with troubleshooting steps
- [ ] Rollback runbook with recovery procedures
- [ ] Change management SOP documented
- [ ] Release process SOP documented
- [ ] Operations SOP with daily/weekly/monthly procedures
- [ ] CI/CD pipeline with automated deployment
- [ ] Dashboard screenshots captured
- [ ] Alarm configuration screenshots captured
- [ ] Log query examples documented

## AWS CLI Commands for Evidence Collection

### Export CloudFormation Templates

```bash
# Export main stack template
aws cloudformation get-template \
  --stack-name web-infrastructure-dev \
  --region ap-southeast-2 \
  --query 'TemplateBody' > main-stack-export.yaml

# Export monitoring stack template
aws cloudformation get-template \
  --stack-name web-infrastructure-dev-MonitoringStack \
  --region ap-southeast-2 \
  --query 'TemplateBody' > monitoring-stack-export.yaml
```

### Export Dashboard Configuration

```bash
aws cloudwatch get-dashboard \
  --dashboard-name dev-infrastructure-dashboard \
  --region ap-southeast-2 > dashboard-config.json
```

### Export Alarm Configurations

```bash
aws cloudwatch describe-alarms \
  --alarm-name-prefix dev- \
  --region ap-southeast-2 > alarms-config.json
```

### Export Log Group Configuration

```bash
aws logs describe-log-groups \
  --log-group-name-prefix /aws/ \
  --region ap-southeast-2 > log-groups-config.json
```

### Query Recent Logs

```bash
# Get recent ALB logs
aws logs tail /aws/alb/dev \
  --region ap-southeast-2 \
  --since 1h \
  --format short > alb-logs-sample.txt

# Get recent EC2 logs
aws logs tail /aws/ec2/dev \
  --region ap-southeast-2 \
  --since 1h \
  --format short > ec2-logs-sample.txt
```

### Export SNS Topic Configuration

```bash
aws sns get-topic-attributes \
  --topic-arn arn:aws:sns:ap-southeast-2:ACCOUNT_ID:dev-operations-notifications \
  --region ap-southeast-2 > sns-topic-config.json

aws sns list-subscriptions-by-topic \
  --topic-arn arn:aws:sns:ap-southeast-2:ACCOUNT_ID:dev-operations-notifications \
  --region ap-southeast-2 > sns-subscriptions.json
```

## Compliance Statement

This evidence package demonstrates compliance with AWS Migration Services Competency requirement MOB-005 (Operations) through:

1. **Operational Models**: Documented runbooks and SOPs covering all operational aspects
2. **Monitoring Infrastructure**: CloudWatch dashboards, alarms, and logs for comprehensive observability
3. **Incident Management**: Automated alerting via SNS with documented response procedures
4. **Change Management**: Documented change control and release processes
5. **Infrastructure-as-Code**: All resources defined in version-controlled CloudFormation templates
6. **Automated Deployment**: CI/CD pipeline with automated testing and deployment

All infrastructure is deployed in AWS region ap-southeast-2 (Sydney) with separate dev and prod environments.
