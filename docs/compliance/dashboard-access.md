# CloudWatch Dashboard and Alarm Access Guide

## CloudWatch Dashboard Access

### Dashboard Overview

**Dashboard Name**: `{Environment}-infrastructure-dashboard`
- Dev environment: `dev-infrastructure-dashboard`
- Prod environment: `prod-infrastructure-dashboard`

**Region**: ap-southeast-2 (Sydney)

**Update Frequency**: Real-time (metrics refresh every 1-5 minutes)

### Accessing via AWS Console

1. Sign in to AWS Console
2. Navigate to CloudWatch service
3. Ensure region is set to **ap-southeast-2 (Sydney)**
4. Select **Dashboards** from left navigation menu
5. Click on dashboard name (e.g., `dev-infrastructure-dashboard`)

### Dashboard Widgets

**ALB Metrics Widget**
- RequestCount: Total requests per period
- TargetResponseTime: Average response time in seconds
- HealthyHostCount: Number of healthy targets
- UnHealthyHostCount: Number of unhealthy targets
- HTTPCode_Target_4XX_Count: 4xx errors from targets
- HTTPCode_Target_5XX_Count: 5xx errors from targets

**EC2 Metrics Widget**
- CPUUtilization: CPU usage percentage
- NetworkIn: Incoming network traffic in bytes
- NetworkOut: Outgoing network traffic in bytes
- StatusCheckFailed: Failed status checks

**Alarm Status Widget**
- Current state of all configured alarms
- Recent alarm state changes

### Dashboard Time Range

Default: Last 3 hours

To change time range:
1. Click time range selector in top right
2. Select predefined range (1h, 3h, 12h, 1d, 1w)
3. Or specify custom range

### Dashboard Refresh

- Auto-refresh: Enabled by default (1 minute interval)
- Manual refresh: Click refresh icon in top right

### Capturing Dashboard Screenshots

**For Compliance Evidence**:

1. Open dashboard in AWS Console
2. Set time range to show recent activity (last 3 hours recommended)
3. Wait for all widgets to load data
4. Use browser screenshot tool or:
   - Windows: Windows Key + Shift + S
   - Mac: Command + Shift + 4
   - Linux: Screenshot tool or Print Screen
5. Capture full page including all widgets
6. Save as `cloudwatch-dashboard-{environment}-{date}.png`

**Screenshot Checklist**:
- [ ] All widgets visible and loaded
- [ ] Time range clearly shown
- [ ] Dashboard name visible
- [ ] Region (ap-southeast-2) visible
- [ ] Recent data displayed (not "No data")

## CloudWatch Alarms Access

### Alarm Overview

**Configured Alarms**:

1. **ALB Unhealthy Targets**
   - Name: `{Environment}-alb-unhealthy-targets`
   - Metric: UnHealthyHostCount
   - Threshold: > 0 for 2 consecutive periods
   - Period: 60 seconds

2. **ALB Response Time**
   - Name: `{Environment}-alb-response-time`
   - Metric: TargetResponseTime
   - Threshold: > 1 second for 3 consecutive periods
   - Period: 60 seconds

3. **ALB 5xx Errors**
   - Name: `{Environment}-alb-5xx-errors`
   - Metric: HTTPCode_Target_5XX_Count
   - Threshold: > 5% error rate for 2 consecutive periods
   - Period: 60 seconds

4. **EC2 High CPU**
   - Name: `{Environment}-ec2-high-cpu`
   - Metric: CPUUtilization
   - Threshold: > 80% for 5 consecutive periods
   - Period: 60 seconds

### Accessing via AWS Console

1. Sign in to AWS Console
2. Navigate to CloudWatch service
3. Ensure region is set to **ap-southeast-2 (Sydney)**
4. Select **Alarms** > **All alarms** from left navigation
5. Filter by environment prefix (e.g., `dev-` or `prod-`)

### Alarm States

- **OK**: Metric is within threshold
- **ALARM**: Metric has breached threshold
- **INSUFFICIENT_DATA**: Not enough data to evaluate

### Viewing Alarm Details

1. Click on alarm name
2. View tabs:
   - **Details**: Configuration and current state
   - **History**: State change history
   - **Metrics**: Graph of monitored metric

### Alarm Notifications

All alarms send notifications to SNS topic: `{Environment}-operations-notifications`

**Email Recipients**:
- evan.pratama@helios.id
- yuwan.cornelius@helios.id

**Notification Triggers**:
- Alarm state changes to ALARM
- Alarm state changes to OK (recovery notification)

### Capturing Alarm Screenshots

**For Compliance Evidence**:

1. Navigate to CloudWatch > Alarms
2. Ensure all environment alarms are visible
3. Capture screenshot showing:
   - Alarm names
   - Current states
   - Metric names
   - Threshold values
4. Save as `cloudwatch-alarms-{environment}-{date}.png`

**For Alarm Details**:

1. Click on specific alarm
2. Capture screenshot of Details tab showing:
   - Alarm configuration
   - Threshold settings
   - SNS topic configuration
3. Save as `alarm-detail-{alarm-name}-{date}.png`

## AWS CLI Access

### View Dashboard Configuration

```bash
aws cloudwatch get-dashboard \
  --dashboard-name dev-infrastructure-dashboard \
  --region ap-southeast-2
```

### List All Alarms

```bash
aws cloudwatch describe-alarms \
  --region ap-southeast-2
```

### List Alarms by Environment

```bash
aws cloudwatch describe-alarms \
  --alarm-name-prefix dev- \
  --region ap-southeast-2
```

### Get Specific Alarm Details

```bash
aws cloudwatch describe-alarms \
  --alarm-names dev-alb-unhealthy-targets \
  --region ap-southeast-2
```

### View Alarm History

```bash
aws cloudwatch describe-alarm-history \
  --alarm-name dev-alb-unhealthy-targets \
  --region ap-southeast-2 \
  --max-records 10
```

### Get Alarm State

```bash
aws cloudwatch describe-alarms \
  --alarm-names dev-alb-unhealthy-targets \
  --region ap-southeast-2 \
  --query 'MetricAlarms[0].StateValue'
```

## Troubleshooting Access Issues

### Dashboard Not Visible

**Possible Causes**:
- Wrong region selected (must be ap-southeast-2)
- Dashboard not yet created (check CloudFormation stack status)
- Insufficient IAM permissions

**Resolution**:
1. Verify region is ap-southeast-2
2. Check CloudFormation stack deployed successfully
3. Verify IAM user has `cloudwatch:GetDashboard` permission

### Alarms Not Triggering

**Possible Causes**:
- SNS subscription not confirmed
- Insufficient metric data
- Alarm threshold not breached

**Resolution**:
1. Check SNS subscription status (must be "Confirmed")
2. Verify metrics are being published to CloudWatch
3. Review alarm history for evaluation results

### No Metric Data

**Possible Causes**:
- Resources not yet deployed
- Detailed monitoring not enabled
- CloudWatch agent not running (for EC2 logs)

**Resolution**:
1. Verify resources exist and are running
2. Check EC2 detailed monitoring enabled
3. Verify CloudWatch agent installed and running

## IAM Permissions Required

### Read-Only Access

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:GetDashboard",
        "cloudwatch:ListDashboards",
        "cloudwatch:DescribeAlarms",
        "cloudwatch:DescribeAlarmHistory",
        "cloudwatch:GetMetricData",
        "cloudwatch:GetMetricStatistics"
      ],
      "Resource": "*"
    }
  ]
}
```

### Full Access (for operations team)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:*"
      ],
      "Resource": "*"
    }
  ]
}
```

## Compliance Verification

**MOB-005 Evidence Requirements**:

- [ ] Dashboard accessible and displaying metrics
- [ ] All required metrics present in dashboard
- [ ] Alarms configured for critical thresholds
- [ ] SNS notifications configured and confirmed
- [ ] Screenshots captured showing dashboard and alarms
- [ ] Access procedures documented
- [ ] IAM permissions documented
