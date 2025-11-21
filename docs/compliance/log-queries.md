# CloudWatch Logs Access and Sample Queries

## Log Groups Overview

### Configured Log Groups

**ALB Log Group**
- Name: `/aws/alb/{Environment}`
- Retention: 30 days
- Purpose: ALB access logs and request details

**EC2 Log Group**
- Name: `/aws/ec2/{Environment}`
- Retention: 30 days
- Purpose: EC2 system logs, Nginx access/error logs

**Region**: ap-southeast-2 (Sydney)

## Accessing Logs via AWS Console

### View Log Groups

1. Sign in to AWS Console
2. Navigate to CloudWatch service
3. Ensure region is set to **ap-southeast-2 (Sydney)**
4. Select **Logs** > **Log groups** from left navigation
5. Find log group by name (e.g., `/aws/alb/dev` or `/aws/ec2/dev`)

### View Log Streams

1. Click on log group name
2. View list of log streams (organized by date/time or resource)
3. Click on log stream to view entries

### Search Logs

1. Open log group
2. Click **Search log group** button
3. Enter search terms or use CloudWatch Logs Insights query
4. Select time range
5. Click **Run query**

## CloudWatch Logs Insights Queries

### ALB Log Queries

**Query 1: All 5xx Errors**
```
fields @timestamp, request, status, target_status_code, target_processing_time
| filter status >= 500
| sort @timestamp desc
| limit 100
```

**Query 2: Slow Requests (> 1 second)**
```
fields @timestamp, request, target_processing_time, status
| filter target_processing_time > 1.0
| sort target_processing_time desc
| limit 50
```

**Query 3: Error Rate by Time**
```
fields @timestamp, status
| filter status >= 400
| stats count() as error_count by bin(5m)
| sort @timestamp desc
```

**Query 4: Top Requested URLs**
```
fields request
| parse request /(?<method>\w+)\s+(?<url>\S+)\s+(?<protocol>\S+)/
| stats count() as request_count by url
| sort request_count desc
| limit 20
```

**Query 5: Requests by Status Code**
```
fields status
| stats count() as count by status
| sort count desc
```

**Query 6: Average Response Time by Endpoint**
```
fields request, target_processing_time
| parse request /(?<method>\w+)\s+(?<url>\S+)\s+(?<protocol>\S+)/
| stats avg(target_processing_time) as avg_response_time by url
| sort avg_response_time desc
| limit 20
```

### EC2 Log Queries

**Query 7: All Error Messages**
```
fields @timestamp, @message
| filter @message like /ERROR/ or @message like /error/ or @message like /Error/
| sort @timestamp desc
| limit 100
```

**Query 8: Nginx Access Log Analysis**
```
fields @timestamp, @message
| filter @message like /GET/ or @message like /POST/
| parse @message /(?<ip>\S+)\s+\S+\s+\S+\s+\[(?<timestamp>[^\]]+)\]\s+"(?<method>\w+)\s+(?<url>\S+)\s+\S+"\s+(?<status>\d+)/
| stats count() as request_count by status
| sort request_count desc
```

**Query 9: Nginx Error Log Analysis**
```
fields @timestamp, @message
| filter @message like /error/
| parse @message /\[(?<level>\w+)\]/
| stats count() as error_count by level
| sort error_count desc
```

**Query 10: High CPU Events**
```
fields @timestamp, @message
| filter @message like /CPU/ or @message like /cpu/
| sort @timestamp desc
| limit 50
```

**Query 11: Recent System Events**
```
fields @timestamp, @message
| filter @message like /systemd/ or @message like /kernel/
| sort @timestamp desc
| limit 100
```

**Query 12: Application Startup Events**
```
fields @timestamp, @message
| filter @message like /started/ or @message like /Starting/
| sort @timestamp desc
| limit 50
```

## Common Query Patterns

### Time-Based Filtering

**Last Hour**
```
fields @timestamp, @message
| filter @timestamp > ago(1h)
| sort @timestamp desc
```

**Specific Time Range**
```
fields @timestamp, @message
| filter @timestamp >= "2024-01-01T00:00:00" and @timestamp <= "2024-01-01T23:59:59"
| sort @timestamp desc
```

### Pattern Matching

**Contains Text**
```
fields @timestamp, @message
| filter @message like /pattern/
```

**Regex Pattern**
```
fields @timestamp, @message
| filter @message like /^ERROR:/
```

**Multiple Conditions**
```
fields @timestamp, @message
| filter (@message like /ERROR/ or @message like /WARN/) and @timestamp > ago(1h)
```

### Aggregations

**Count by Field**
```
fields field_name
| stats count() as total by field_name
| sort total desc
```

**Average Value**
```
fields numeric_field
| stats avg(numeric_field) as average
```

**Time-Based Aggregation**
```
fields @timestamp
| stats count() as events by bin(5m)
| sort @timestamp desc
```

## Accessing Logs via AWS CLI

### Tail Recent Logs

**ALB Logs**
```bash
aws logs tail /aws/alb/dev \
  --region ap-southeast-2 \
  --since 1h \
  --format short
```

**EC2 Logs**
```bash
aws logs tail /aws/ec2/dev \
  --region ap-southeast-2 \
  --since 1h \
  --format short
```

### List Log Streams

```bash
aws logs describe-log-streams \
  --log-group-name /aws/alb/dev \
  --region ap-southeast-2 \
  --order-by LastEventTime \
  --descending \
  --max-items 10
```

### Get Log Events

```bash
aws logs get-log-events \
  --log-group-name /aws/alb/dev \
  --log-stream-name {stream-name} \
  --region ap-southeast-2 \
  --limit 100
```

### Filter Log Events

```bash
aws logs filter-log-events \
  --log-group-name /aws/alb/dev \
  --region ap-southeast-2 \
  --filter-pattern "ERROR" \
  --start-time $(date -d '1 hour ago' +%s)000
```

### Run Insights Query

```bash
aws logs start-query \
  --log-group-name /aws/alb/dev \
  --region ap-southeast-2 \
  --start-time $(date -d '1 hour ago' +%s) \
  --end-time $(date +%s) \
  --query-string 'fields @timestamp, status | filter status >= 500 | sort @timestamp desc'
```

### Get Query Results

```bash
# First, start query and get query ID
QUERY_ID=$(aws logs start-query \
  --log-group-name /aws/alb/dev \
  --region ap-southeast-2 \
  --start-time $(date -d '1 hour ago' +%s) \
  --end-time $(date +%s) \
  --query-string 'fields @timestamp | stats count()' \
  --query 'queryId' \
  --output text)

# Then get results
aws logs get-query-results \
  --query-id $QUERY_ID \
  --region ap-southeast-2
```

## Exporting Logs

### Export to S3

1. Navigate to CloudWatch > Log groups
2. Select log group
3. Click **Actions** > **Export data to Amazon S3**
4. Specify S3 bucket, prefix, and time range
5. Click **Export**

### Export via CLI

```bash
aws logs create-export-task \
  --log-group-name /aws/alb/dev \
  --from $(date -d '1 day ago' +%s)000 \
  --to $(date +%s)000 \
  --destination s3-bucket-name \
  --destination-prefix alb-logs/ \
  --region ap-southeast-2
```

## Log Retention Configuration

### View Retention Settings

```bash
aws logs describe-log-groups \
  --log-group-name-prefix /aws/ \
  --region ap-southeast-2 \
  --query 'logGroups[*].[logGroupName,retentionInDays]'
```

### Verify 30-Day Retention

All log groups should have `retentionInDays: 30` configured via CloudFormation template.

## Capturing Log Evidence

### For Compliance Screenshots

1. Navigate to CloudWatch > Log groups
2. Open log group (e.g., `/aws/alb/dev`)
3. Select recent log stream
4. Capture screenshot showing:
   - Log group name
   - Log stream name
   - Recent log entries
   - Timestamp range
5. Save as `cloudwatch-logs-{log-group}-{date}.png`

### For Query Results

1. Run CloudWatch Logs Insights query
2. Wait for results to load
3. Capture screenshot showing:
   - Query text
   - Time range
   - Results table
   - Record count
4. Save as `log-query-{query-name}-{date}.png`

### Sample Log Exports

Export sample logs for compliance evidence:

```bash
# Export last hour of ALB logs
aws logs tail /aws/alb/dev \
  --region ap-southeast-2 \
  --since 1h \
  --format short > alb-logs-sample.txt

# Export last hour of EC2 logs
aws logs tail /aws/ec2/dev \
  --region ap-southeast-2 \
  --since 1h \
  --format short > ec2-logs-sample.txt
```

## Troubleshooting Log Issues

### No Logs Appearing

**Possible Causes**:
- Log group not created (check CloudFormation)
- CloudWatch agent not running (EC2 logs)
- ALB logging not enabled
- IAM permissions missing

**Resolution**:
1. Verify log group exists in CloudWatch
2. Check CloudWatch agent status on EC2: `sudo systemctl status amazon-cloudwatch-agent`
3. Verify ALB logging configuration
4. Check IAM role has `logs:PutLogEvents` permission

### Log Streams Empty

**Possible Causes**:
- No traffic to ALB
- EC2 instance not generating logs
- CloudWatch agent misconfigured

**Resolution**:
1. Generate test traffic to ALB
2. Check application is running and generating logs
3. Review CloudWatch agent configuration

### Query Timeout

**Possible Causes**:
- Query too broad (large time range)
- Complex query pattern
- High log volume

**Resolution**:
1. Reduce time range
2. Simplify query
3. Add more specific filters

## IAM Permissions Required

### Read-Only Access

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:GetLogEvents",
        "logs:FilterLogEvents",
        "logs:StartQuery",
        "logs:GetQueryResults"
      ],
      "Resource": "*"
    }
  ]
}
```

## Compliance Verification

**MOB-005 Evidence Requirements**:

- [ ] Log groups created with 30-day retention
- [ ] ALB logs flowing to CloudWatch
- [ ] EC2 logs flowing to CloudWatch
- [ ] Sample queries documented
- [ ] Log access procedures documented
- [ ] Sample log exports captured
- [ ] Screenshots of log entries captured
- [ ] Query results captured for evidence
