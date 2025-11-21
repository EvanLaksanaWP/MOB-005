# Operations Standard Operating Procedure

## Purpose

This SOP defines routine operational procedures for maintaining the AWS infrastructure, including daily health checks, log reviews, cost monitoring, pipeline oversight, and infrastructure drift detection.

## Daily Operations

### Health Check Procedures

**Frequency**: Daily (business days)

**Procedure**:

1. Access CloudWatch dashboard
   ```bash
   aws cloudwatch get-dashboard \
     --dashboard-name InfrastructureDashboard-${ENVIRONMENT} \
     --region ap-southeast-2
   ```

2. Review dashboard metrics
   - ALB request count trending
   - Target response time within acceptable range (<1s)
   - Healthy target count matches expected instances
   - EC2 CPU utilization within normal range (<80%)
   - Network traffic patterns normal

3. Verify alarm status
   ```bash
   aws cloudwatch describe-alarms \
     --state-value ALARM \
     --region ap-southeast-2
   ```

4. Check for active alarms
   - If no alarms: Operations normal
   - If alarms present: Follow incident response runbook

5. Document findings
   - Record dashboard review timestamp
   - Note any anomalies or trends
   - Log alarm states

**Expected Outcomes**:
- All metrics within normal ranges
- No active alarms
- Dashboard accessible and displaying current data

**Escalation**:
- Active alarms: Follow incident response runbook
- Dashboard unavailable: Check CloudFormation stack status
- Missing metrics: Verify resource health and CloudWatch agent status

## Weekly Operations

### Log Review Procedures

**Frequency**: Weekly (Monday mornings)

**Procedure**:

1. Review ALB access logs for error patterns
   ```bash
   aws logs filter-log-events \
     --log-group-name /aws/alb/web-server \
     --start-time $(date -d '7 days ago' +%s)000 \
     --filter-pattern '[... status=5*]' \
     --region ap-southeast-2
   ```

2. Analyze 5xx error patterns
   - Identify frequency and timing
   - Determine affected endpoints
   - Correlate with deployment events

3. Review EC2 application logs
   ```bash
   aws logs filter-log-events \
     --log-group-name /aws/ec2/web-server \
     --start-time $(date -d '7 days ago' +%s)000 \
     --filter-pattern 'ERROR' \
     --region ap-southeast-2
   ```

4. Check for application errors
   - Review error messages and stack traces
   - Identify recurring issues
   - Assess impact on service availability

5. Review CloudTrail for infrastructure changes
   ```bash
   aws cloudtrail lookup-events \
     --lookup-attributes AttributeKey=EventName,AttributeValue=UpdateStack \
     --start-time $(date -d '7 days ago' +%Y-%m-%d) \
     --region ap-southeast-2
   ```

6. Document findings
   - Summarize error patterns
   - Note anomalies requiring investigation
   - Create tickets for recurring issues

**Expected Outcomes**:
- Error rates within acceptable thresholds
- No unexpected error patterns
- Infrastructure changes properly documented

**Escalation**:
- Increasing error rates: Investigate root cause
- Unauthorized changes: Review change management compliance
- Critical errors: Follow incident response procedures

## Monthly Operations

### Cost Review Procedures

**Frequency**: Monthly (first business day)

**Procedure**:

1. Review CloudWatch metrics usage
   ```bash
   aws cloudwatch get-metric-statistics \
     --namespace AWS/Usage \
     --metric-name CallCount \
     --dimensions Name=Service,Value=CloudWatch \
     --start-time $(date -d '30 days ago' --iso-8601) \
     --end-time $(date --iso-8601) \
     --period 2592000 \
     --statistics Sum \
     --region ap-southeast-2
   ```

2. Analyze CloudWatch Logs ingestion
   ```bash
   aws logs describe-log-groups \
     --region ap-southeast-2 \
     --query 'logGroups[*].[logGroupName,storedBytes]' \
     --output table
   ```

3. Review EC2 instance utilization
   ```bash
   aws cloudwatch get-metric-statistics \
     --namespace AWS/EC2 \
     --metric-name CPUUtilization \
     --dimensions Name=InstanceId,Value=${INSTANCE_ID} \
     --start-time $(date -d '30 days ago' --iso-8601) \
     --end-time $(date --iso-8601) \
     --period 86400 \
     --statistics Average,Maximum \
     --region ap-southeast-2
   ```

4. Assess cost optimization opportunities
   - Underutilized instances (avg CPU <20%)
   - Excessive log retention
   - Unused alarms or dashboards
   - Over-provisioned resources

5. Review ALB request patterns
   ```bash
   aws cloudwatch get-metric-statistics \
     --namespace AWS/ApplicationELB \
     --metric-name RequestCount \
     --dimensions Name=LoadBalancer,Value=${ALB_NAME} \
     --start-time $(date -d '30 days ago' --iso-8601) \
     --end-time $(date --iso-8601) \
     --period 86400 \
     --statistics Sum \
     --region ap-southeast-2
   ```

6. Document cost analysis
   - Current monthly spend estimate
   - Cost trends compared to previous month
   - Optimization recommendations
   - Approved cost-saving actions

**Expected Outcomes**:
- Costs within budget
- Resource utilization appropriate for workload
- Optimization opportunities identified

**Escalation**:
- Costs exceeding budget: Review with management
- Significant cost increases: Investigate root cause
- Optimization opportunities: Submit change request

## Pipeline Monitoring

### Pipeline Execution Status

**Frequency**: After each deployment

**Procedure**:

1. Check dev pipeline status
   ```bash
   aws codepipeline get-pipeline-state \
     --name web-pipeline-dev \
     --region ap-southeast-2
   ```

2. Check prod pipeline status
   ```bash
   aws codepipeline get-pipeline-state \
     --name web-pipeline-prod \
     --region ap-southeast-2
   ```

3. Review pipeline execution history
   ```bash
   aws codepipeline list-pipeline-executions \
     --pipeline-name web-pipeline-${ENVIRONMENT} \
     --max-results 10 \
     --region ap-southeast-2
   ```

4. Verify successful stages
   - Source: GitHub connection active
   - Build: CodeBuild completed successfully
   - Deploy: CloudFormation stack updated

5. Check for failed executions
   ```bash
   aws codepipeline list-pipeline-executions \
     --pipeline-name web-pipeline-${ENVIRONMENT} \
     --region ap-southeast-2 \
     --query 'pipelineExecutionSummaries[?status==`Failed`]'
   ```

6. Review CodeBuild logs for failures
   ```bash
   aws codebuild batch-get-builds \
     --ids ${BUILD_ID} \
     --region ap-southeast-2
   ```

**Expected Outcomes**:
- Pipeline executions complete successfully
- All stages pass validation
- No stuck or failed executions

**Escalation**:
- Failed pipeline: Review build logs and follow rollback runbook
- Stuck pipeline: Check GitHub connection and IAM permissions
- Repeated failures: Investigate infrastructure or template issues

## Infrastructure Drift Detection

### Stack Drift Review

**Frequency**: Weekly (Friday afternoons)

**Procedure**:

1. Initiate drift detection for main stack
   ```bash
   aws cloudformation detect-stack-drift \
     --stack-name web-infrastructure-${ENVIRONMENT} \
     --region ap-southeast-2
   ```

2. Wait for drift detection to complete
   ```bash
   aws cloudformation describe-stack-drift-detection-status \
     --stack-drift-detection-id ${DRIFT_DETECTION_ID} \
     --region ap-southeast-2
   ```

3. Review drift detection results
   ```bash
   aws cloudformation describe-stack-resource-drifts \
     --stack-name web-infrastructure-${ENVIRONMENT} \
     --region ap-southeast-2
   ```

4. Analyze drifted resources
   - Identify modified resources
   - Determine drift type (MODIFIED, DELETED)
   - Review property differences

5. Check nested stacks for drift
   ```bash
   aws cloudformation describe-stacks \
     --stack-name web-infrastructure-${ENVIRONMENT} \
     --region ap-southeast-2 \
     --query 'Stacks[0].Outputs[?OutputKey==`NetworkStackId`].OutputValue' \
     --output text | xargs -I {} aws cloudformation detect-stack-drift --stack-name {}
   ```

6. Document drift findings
   - List drifted resources
   - Identify source of manual changes
   - Assess impact on infrastructure

7. Remediate drift
   - For approved changes: Update CloudFormation templates
   - For unauthorized changes: Revert via stack update
   - For critical drift: Follow change management SOP

**Expected Outcomes**:
- No drift detected (IN_SYNC status)
- All resources match template definitions
- Infrastructure fully managed by CloudFormation

**Escalation**:
- Drift detected: Investigate source of manual changes
- Critical resource drift: Assess security and compliance impact
- Repeated drift: Review access controls and change management

## Monitoring Stack Health

### CloudFormation Stack Status

**Frequency**: Daily (with health checks)

**Procedure**:

1. Check main stack status
   ```bash
   aws cloudformation describe-stacks \
     --stack-name web-infrastructure-${ENVIRONMENT} \
     --region ap-southeast-2 \
     --query 'Stacks[0].StackStatus'
   ```

2. Verify nested stack status
   ```bash
   aws cloudformation list-stack-resources \
     --stack-name web-infrastructure-${ENVIRONMENT} \
     --region ap-southeast-2 \
     --query 'StackResourceSummaries[?ResourceType==`AWS::CloudFormation::Stack`]'
   ```

3. Check for stack events
   ```bash
   aws cloudformation describe-stack-events \
     --stack-name web-infrastructure-${ENVIRONMENT} \
     --max-items 20 \
     --region ap-southeast-2
   ```

4. Review monitoring stack specifically
   ```bash
   aws cloudformation describe-stack-resources \
     --stack-name web-infrastructure-${ENVIRONMENT} \
     --logical-resource-id MonitoringStack \
     --region ap-southeast-2
   ```

**Expected Outcomes**:
- All stacks in CREATE_COMPLETE or UPDATE_COMPLETE status
- No failed resources
- Recent events show successful operations

**Escalation**:
- Stack in failed state: Review stack events and follow rollback runbook
- Resources in failed state: Investigate resource-specific errors
- Update in progress: Monitor for completion or failure

## Documentation and Reporting

### Operations Log

Maintain operations log with:
- Date and time of checks
- Operator name
- Findings summary
- Actions taken
- Escalations initiated

### Monthly Operations Report

Prepare monthly report including:
- Availability metrics
- Alarm history
- Error rate trends
- Cost analysis
- Optimization recommendations
- Incident summary
- Change history

### Compliance Evidence

Maintain evidence for MOB-005 compliance:
- Dashboard screenshots
- Alarm notification examples
- Log query results
- Cost reports
- Drift detection results
- Pipeline execution history

## Roles and Responsibilities

**Operations Engineer**:
- Execute daily health checks
- Perform weekly log reviews
- Monitor pipeline executions
- Respond to alarms

**Operations Manager**:
- Review monthly cost reports
- Approve optimization changes
- Oversee compliance evidence
- Manage escalations

**Infrastructure Team**:
- Remediate infrastructure drift
- Update CloudFormation templates
- Implement cost optimizations
- Maintain documentation

## References

- Deployment Runbook: `docs/runbooks/deployment.md`
- Incident Response Runbook: `docs/runbooks/incident-response.md`
- Rollback Runbook: `docs/runbooks/rollback.md`
- Change Management SOP: `docs/sops/change-management.md`
- Release Process SOP: `docs/sops/release-process.md`
