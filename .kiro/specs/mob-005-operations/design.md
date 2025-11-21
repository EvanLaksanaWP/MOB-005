# Design Document

## Overview

This design extends the existing REL-001 compliant CloudFormation infrastructure to achieve MOB-005 (Operations) compliance by adding comprehensive monitoring, alerting, logging, and operational documentation. The solution maintains the current nested stack architecture and adds a new monitoring stack alongside existing network, security, ALB, and EC2 stacks.

The design follows infrastructure-as-code principles, defining all monitoring resources in CloudFormation templates. Operational procedures are documented in runbooks and SOPs to provide clear guidance for deployment, incident response, change management, and daily operations.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        main.yaml                             │
│                   (Orchestration Stack)                      │
└─────────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┬──────────────┐
        │                   │                   │              │
        ▼                   ▼                   ▼              ▼
┌──────────────┐    ┌──────────────┐   ┌──────────────┐  ┌──────────────┐
│   Network    │    │   Security   │   │     ALB      │  │     EC2      │
│    Stack     │    │    Stack     │   │    Stack     │  │    Stack     │
│  (Existing)  │    │  (Existing)  │   │  (Existing)  │  │  (Existing)  │
└──────────────┘    └──────────────┘   └──────────────┘  └──────────────┘
                            │
                            ▼
                    ┌──────────────┐
                    │  Monitoring  │
                    │    Stack     │
                    │    (NEW)     │
                    └──────────────┘
                            │
        ┌───────────────────┼───────────────────┬──────────────┐
        │                   │                   │              │
        ▼                   ▼                   ▼              ▼
┌──────────────┐    ┌──────────────┐   ┌──────────────┐  ┌──────────────┐
│  CloudWatch  │    │  CloudWatch  │   │  CloudWatch  │  │     SNS      │
│  Dashboard   │    │    Alarms    │   │  Log Groups  │  │    Topic     │
└──────────────┘    └──────────────┘   └──────────────┘  └──────────────┘
```

### Monitoring Flow

```
┌──────────┐         ┌──────────────┐         ┌──────────────┐
│   ALB    │────────▶│  CloudWatch  │────────▶│  Dashboard   │
│          │ metrics │   Metrics    │ display │              │
└──────────┘         └──────────────┘         └──────────────┘
                            │
                            │ threshold
                            ▼
                     ┌──────────────┐         ┌──────────────┐
                     │  CloudWatch  │────────▶│     SNS      │
                     │    Alarms    │ notify  │    Topic     │
                     └──────────────┘         └──────────────┘
                                                      │
                                                      │ email
                                                      ▼
                                              ┌──────────────┐
                                              │  Operations  │
                                              │     Team     │
                                              └──────────────┘

┌──────────┐         ┌──────────────┐
│   EC2    │────────▶│  CloudWatch  │
│          │  logs   │     Logs     │
└──────────┘         └──────────────┘
```

## Components and Interfaces

### 1. Monitoring Stack (templates/monitoring.yaml)

**Purpose**: Defines all CloudWatch and SNS resources for operational monitoring.

**Resources**:
- `OperationsNotificationTopic` (AWS::SNS::Topic): Central notification topic for all alarms
- `OperationsEmailSubscription1` (AWS::SNS::Subscription): Email subscription for evan.pratama@helios.id
- `OperationsEmailSubscription2` (AWS::SNS::Subscription): Email subscription for yuwan.cornelius@helios.id
- `InfrastructureDashboard` (AWS::CloudWatch::Dashboard): Main operational dashboard
- `ALBUnhealthyTargetAlarm` (AWS::CloudWatch::Alarm): Monitors unhealthy target count
- `ALBResponseTimeAlarm` (AWS::CloudWatch::Alarm): Monitors target response time
- `ALB5xxErrorAlarm` (AWS::CloudWatch::Alarm): Monitors 5xx error rate
- `EC2CPUAlarm` (AWS::CloudWatch::Alarm): Monitors EC2 CPU utilization
- `ALBLogGroup` (AWS::Logs::LogGroup): Log group for ALB access logs
- `EC2LogGroup` (AWS::Logs::LogGroup): Log group for EC2 system logs

**Parameters**:
- `Environment`: Environment name (dev/prod)
- `ALBFullName`: ALB resource name for metrics
- `TargetGroupFullName`: Target group resource name for metrics
- `EC2InstanceId`: EC2 instance ID for metrics

**Outputs**:
- `SNSTopicArn`: ARN of operations notification topic
- `DashboardName`: Name of CloudWatch dashboard
- `ALBLogGroupName`: Name of ALB log group
- `EC2LogGroupName`: Name of EC2 log group

### 2. Updated Main Stack (main.yaml)

**Changes**:
- Add `MonitoringStack` resource referencing `templates/monitoring.yaml`
- Pass ALB and EC2 resource identifiers to monitoring stack
- Export monitoring outputs for reference

### 3. Updated ALB Stack (templates/alb.yaml)

**Changes**:
- Add `AccessLoggingPolicy` to ALB resource
- Configure S3 bucket for ALB access logs (alternative to CloudWatch Logs)
- Export ALB full name for monitoring stack

### 4. Updated EC2 Stack (templates/ec2.yaml)

**Changes**:
- Enable detailed monitoring (`Monitoring: true`)
- Add CloudWatch agent installation to user data
- Configure agent to stream logs to CloudWatch Logs
- Export instance ID for monitoring stack

### 5. Documentation Structure

```
docs/
├── runbooks/
│   ├── deployment.md          # Deployment procedures
│   ├── incident-response.md   # Incident handling procedures
│   └── rollback.md            # Rollback procedures
└── sops/
    ├── change-management.md   # Change control process
    ├── release-process.md     # Release procedures
    └── operations.md          # Daily operations procedures
```

## Data Models

### CloudWatch Dashboard Widget Configuration

```json
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/ApplicationELB", "RequestCount", {"stat": "Sum"}],
          [".", "TargetResponseTime", {"stat": "Average"}],
          [".", "HealthyHostCount", {"stat": "Average"}],
          [".", "UnHealthyHostCount", {"stat": "Average"}]
        ],
        "period": 300,
        "stat": "Average",
        "region": "ap-southeast-2",
        "title": "ALB Metrics"
      }
    },
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/EC2", "CPUUtilization", {"stat": "Average"}],
          [".", "NetworkIn", {"stat": "Sum"}],
          [".", "NetworkOut", {"stat": "Sum"}]
        ],
        "period": 300,
        "stat": "Average",
        "region": "ap-southeast-2",
        "title": "EC2 Metrics"
      }
    }
  ]
}
```

### CloudWatch Alarm Configuration

```yaml
Type: AWS::CloudWatch::Alarm
Properties:
  AlarmName: !Sub '${Environment}-alb-unhealthy-targets'
  MetricName: UnHealthyHostCount
  Namespace: AWS/ApplicationELB
  Statistic: Average
  Period: 60
  EvaluationPeriods: 2
  Threshold: 0
  ComparisonOperator: GreaterThanThreshold
  AlarmActions:
    - !Ref OperationsNotificationTopic
  OKActions:
    - !Ref OperationsNotificationTopic
```

### CloudWatch Agent Configuration

```json
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/nginx/access.log",
            "log_group_name": "/aws/ec2/web-server",
            "log_stream_name": "{instance_id}/nginx-access"
          },
          {
            "file_path": "/var/log/nginx/error.log",
            "log_group_name": "/aws/ec2/web-server",
            "log_stream_name": "{instance_id}/nginx-error"
          }
        ]
      }
    }
  }
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Dashboard contains all required metrics

*For any* CloudWatch dashboard configuration, the dashboard body SHALL contain widgets displaying ALB RequestCount, TargetResponseTime, HealthyHostCount, UnHealthyHostCount, EC2 CPUUtilization, NetworkIn, and NetworkOut metrics.

**Validates: Requirements 1.3**

### Property 2: All log groups have retention configured

*For any* CloudWatch log group resource in the monitoring template, the RetentionInDays property SHALL be set to 30.

**Validates: Requirements 3.4**

### Property 3: All alarms have SNS notification configured

*For any* CloudWatch alarm resource in the monitoring template, both AlarmActions and OKActions SHALL reference the operations SNS topic ARN.

**Validates: Requirements 2.5, 2.6**

### Property 4: Monitoring stack integrates with main stack

*For any* deployment of main.yaml, the template SHALL contain a MonitoringStack resource of type AWS::CloudFormation::Stack that references templates/monitoring.yaml.

**Validates: Requirements 10.6**

### Property 5: All required documentation files exist

*For any* compliance verification, the docs directory SHALL contain runbooks for deployment, incident-response, and rollback, and SHALL contain SOPs for change-management, release-process, and operations.

**Validates: Requirements 4.1, 5.1, 6.1, 7.1, 8.1, 9.1, 12.3, 12.4**

## Error Handling

### CloudFormation Deployment Errors

**Scenario**: Monitoring stack fails to deploy due to invalid resource configuration.

**Handling**:
- CloudFormation automatic rollback removes partially created resources
- Stack events logged to CloudWatch for debugging
- Pipeline buildspec captures and displays error details
- Deployment runbook documents troubleshooting steps

### SNS Subscription Confirmation

**Scenario**: Email subscription requires manual confirmation before notifications work.

**Handling**:
- CloudFormation creates subscription in pending state
- Deployment documentation notes manual confirmation requirement
- Operations runbook includes verification steps to check subscription status
- Post-deployment checklist includes SNS confirmation

### CloudWatch Agent Installation Failure

**Scenario**: EC2 user data fails to install or configure CloudWatch agent.

**Handling**:
- EC2 instance continues to run with basic CloudWatch metrics
- Incident response runbook documents how to check agent status
- Manual remediation steps provided to reinstall agent
- CloudFormation stack remains in healthy state

### Alarm False Positives

**Scenario**: Alarms trigger due to temporary spikes or expected behavior.

**Handling**:
- Evaluation periods configured to reduce false positives (2-5 periods)
- Incident response runbook documents how to investigate alarm context
- Operations SOP includes procedures for tuning alarm thresholds
- Alarm history available in CloudWatch for pattern analysis

### Log Group Quota Exceeded

**Scenario**: CloudWatch Logs reaches account quota for log groups.

**Handling**:
- CloudFormation deployment fails with quota error
- Error message indicates specific quota limit
- Operations runbook documents how to request quota increase
- Temporary workaround: delete unused log groups from other projects

## Testing Strategy

### Unit Testing

Unit tests verify specific CloudFormation template configurations and documentation structure:

1. **Template Syntax Validation**
   - CFN-Lint validates monitoring.yaml syntax
   - Verify all required resource types are present
   - Check parameter and output definitions

2. **Dashboard Configuration**
   - Parse dashboard body JSON
   - Verify all required metrics are present in widgets
   - Check widget configuration for correct namespaces and dimensions

3. **Alarm Configuration**
   - Verify each alarm has correct metric, threshold, and evaluation periods
   - Check AlarmActions and OKActions reference SNS topic
   - Validate comparison operators match requirements

4. **Documentation Structure**
   - Verify all required runbook files exist
   - Verify all required SOP files exist
   - Check file naming conventions

5. **Integration Points**
   - Verify main.yaml references monitoring stack
   - Check parameter passing between stacks
   - Validate output exports

### Property-Based Testing

Property-based tests verify universal properties across the monitoring infrastructure:

1. **Property 1: Dashboard Metric Coverage**
   - Generate variations of dashboard configurations
   - Verify all required metrics are always present
   - Test with different widget layouts and configurations

2. **Property 2: Log Retention Consistency**
   - Generate variations of log group configurations
   - Verify RetentionInDays is always 30
   - Test across different log group names and configurations

3. **Property 3: Alarm Notification Completeness**
   - Generate variations of alarm configurations
   - Verify all alarms have both AlarmActions and OKActions
   - Test with different metrics and thresholds

4. **Property 4: Stack Integration**
   - Parse main.yaml template
   - Verify MonitoringStack resource exists
   - Verify correct template URL and parameters

5. **Property 5: Documentation Completeness**
   - Scan docs directory structure
   - Verify all required files exist
   - Test with different directory configurations

### Integration Testing

Integration tests verify the complete monitoring solution works end-to-end:

1. **TaskCat Deployment Testing**
   - Deploy complete stack including monitoring in test region
   - Verify all resources created successfully
   - Check CloudWatch dashboard is accessible
   - Validate alarms are in OK state
   - Confirm SNS topic and subscription created

2. **Alarm Trigger Testing**
   - Simulate metric threshold breach
   - Verify alarm state changes to ALARM
   - Confirm SNS notification sent (manual verification)
   - Check alarm recovery when metric returns to normal

3. **Log Ingestion Testing**
   - Deploy EC2 instance with CloudWatch agent
   - Generate test log entries
   - Verify logs appear in CloudWatch Logs
   - Check log retention policy applied

4. **Dashboard Functionality**
   - Access CloudWatch dashboard via console
   - Verify all widgets display data
   - Check metric time ranges and statistics
   - Validate alarm status indicators

### Compliance Verification Testing

Tests to verify MOB-005 compliance evidence:

1. **Infrastructure-as-Code Verification**
   - Verify all monitoring resources defined in CloudFormation
   - Check no manual resource creation required
   - Validate version control of templates

2. **Documentation Completeness**
   - Verify all runbooks contain required sections
   - Check SOPs cover all operational procedures
   - Validate documentation references correct AWS resources

3. **Monitoring Coverage**
   - Verify dashboards cover all infrastructure components
   - Check alarms monitor critical metrics
   - Validate log collection from all sources

4. **Operational Procedures**
   - Verify runbooks provide actionable steps
   - Check SOPs define clear processes
   - Validate documentation includes AWS CLI commands

## Deployment Strategy

### Phase 1: Monitoring Infrastructure

1. Create `templates/monitoring.yaml` with all CloudWatch and SNS resources
2. Update `main.yaml` to add MonitoringStack nested stack
3. Deploy to dev environment via pipeline
4. Manually confirm SNS email subscriptions
5. Verify dashboard and alarms in CloudWatch console

### Phase 2: Enhanced Logging

1. Update `templates/alb.yaml` to enable access logging
2. Update `templates/ec2.yaml` to enable detailed monitoring
3. Add CloudWatch agent installation to EC2 user data
4. Deploy updates to dev environment
5. Verify logs flowing to CloudWatch Logs
6. Test log retention policies

### Phase 3: Documentation

1. Create `docs/runbooks/` directory structure
2. Write deployment runbook with step-by-step procedures
3. Write incident response runbook with troubleshooting steps
4. Write rollback runbook with recovery procedures
5. Create `docs/sops/` directory structure
6. Write change management SOP
7. Write release process SOP
8. Write operations SOP

### Phase 4: Production Deployment

1. Test complete solution in dev environment
2. Verify all alarms, dashboards, and logs working
3. Review documentation with operations team
4. Merge to main branch for prod deployment
5. Confirm SNS subscription in prod
6. Conduct operational readiness review

### Phase 5: Compliance Evidence

1. Capture CloudWatch dashboard screenshots
2. Export alarm configurations
3. Collect sample log entries
4. Package CloudFormation templates
5. Compile documentation set
6. Prepare MOB-005 compliance submission

## Monitoring and Observability

### CloudWatch Dashboard

The infrastructure dashboard provides real-time visibility into system health:

**ALB Section**:
- Request count (requests/minute)
- Target response time (milliseconds)
- Healthy target count
- Unhealthy target count
- 4xx error count
- 5xx error count

**EC2 Section**:
- CPU utilization (percentage)
- Network in (bytes)
- Network out (bytes)
- Status check failed (count)

**Alarm Section**:
- Current alarm states
- Recent alarm state changes
- Alarm history

### CloudWatch Alarms

Critical alarms with SNS notifications:

1. **ALB Unhealthy Targets**: Triggers when any target is unhealthy for 2 minutes
2. **ALB Response Time**: Triggers when response time exceeds 1 second for 3 minutes
3. **ALB 5xx Errors**: Triggers when 5xx error rate exceeds 5% for 2 minutes
4. **EC2 High CPU**: Triggers when CPU exceeds 80% for 5 minutes

### CloudWatch Logs

Centralized logging for troubleshooting:

1. **ALB Access Logs**: HTTP request details, response codes, latency
2. **EC2 Nginx Access Logs**: Web server request logs
3. **EC2 Nginx Error Logs**: Web server error logs
4. **EC2 System Logs**: Operating system events

### Operational Metrics

Key metrics for daily operations:

- **Availability**: Percentage of time with healthy targets
- **Performance**: Average response time and 95th percentile
- **Error Rate**: Percentage of requests resulting in errors
- **Traffic**: Requests per minute and data transfer
- **Resource Utilization**: CPU, memory, network usage

## Security Considerations

### IAM Permissions

Monitoring stack requires minimal additional permissions:

- CloudWatch: PutMetricData, PutLogEvents, CreateLogGroup
- SNS: Publish (for alarm notifications)
- EC2: DescribeInstances (for CloudWatch agent)

### Data Encryption

- CloudWatch Logs encrypted at rest with AWS managed keys
- SNS messages encrypted in transit with TLS
- CloudWatch metrics encrypted by default

### Access Control

- CloudWatch dashboards accessible via IAM permissions
- SNS topic access controlled via resource policy
- Log groups have resource-based policies for access control

### Compliance

- All monitoring resources tagged with Environment
- CloudFormation templates version-controlled in Git
- Audit trail via CloudTrail for all API calls
- Log retention meets compliance requirements (30 days)

## Cost Considerations

### CloudWatch Costs

- **Metrics**: First 10 custom metrics free, $0.30/metric/month after
- **Alarms**: First 10 alarms free, $0.10/alarm/month after
- **Dashboards**: First 3 dashboards free, $3/dashboard/month after
- **Logs**: $0.50/GB ingested, $0.03/GB stored

### Estimated Monthly Costs (per environment)

- CloudWatch Metrics: ~$0 (using AWS service metrics)
- CloudWatch Alarms: ~$0 (4 alarms, within free tier)
- CloudWatch Dashboard: ~$0 (1 dashboard, within free tier)
- CloudWatch Logs: ~$5-10 (estimated 10GB/month ingestion)
- SNS: ~$0 (low message volume)

**Total**: ~$5-10/month per environment

### Cost Optimization

- 30-day log retention reduces storage costs
- Single dashboard consolidates all metrics
- Alarm evaluation periods tuned to reduce false positives
- Detailed monitoring only on critical EC2 instances
