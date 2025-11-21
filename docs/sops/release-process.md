# Release Process Standard Operating Procedure

## Purpose

This SOP defines the release process for deploying infrastructure changes through dev and prod environments, ensuring consistent and safe production deployments.

## Scope

Applies to all infrastructure releases deployed via CodePipeline for dev and prod environments.

## Process Overview

```
Dev Branch → Dev Pipeline → Dev Deployment → Validation → Main Branch → Prod Pipeline → Prod Deployment → Verification
```

## 1. Branch Strategy

### 1.1 Branch Structure

**Development Branch: `dev`**
- Purpose: Development and testing environment
- Deployment target: web-infrastructure-dev stack
- Pipeline: web-pipeline-dev
- Region: ap-southeast-2
- Auto-deploy: Yes

**Production Branch: `main`**
- Purpose: Production environment
- Deployment target: web-infrastructure-prod stack
- Pipeline: web-pipeline-prod
- Region: ap-southeast-2
- Auto-deploy: Yes

**Feature Branches: `feature/*`**
- Purpose: Individual changes and features
- Deployment target: None (local validation only)
- Merge target: dev branch

**Hotfix Branches: `hotfix/*`**
- Purpose: Emergency production fixes
- Deployment target: None (local validation only)
- Merge target: main branch (with backport to dev)

### 1.2 Branch Protection Rules

**Dev Branch:**
- Require pull request before merging
- Require 1 approval
- Require status checks to pass (CFN-Lint)

**Main Branch:**
- Require pull request before merging
- Require 2 approvals
- Require status checks to pass (CFN-Lint)
- Require branches to be up to date before merging

### 1.3 Merge Flow

**Standard Release:**
```
feature/* → dev → main
```

**Emergency Hotfix:**
```
hotfix/* → main
main → dev (backport)
```

## 2. Pipeline Trigger Conditions

### 2.1 Dev Pipeline Triggers

**Automatic Triggers:**
- Push to `dev` branch
- Merge of pull request to `dev` branch

**Pipeline: web-pipeline-dev**

**Stages:**
1. Source: GitHub repository (dev branch)
2. Build: CFN-Lint validation via buildspec-test.yml
3. Deploy: CloudFormation deployment via buildspec.yml

**Execution:**
```bash
git push origin dev
```

Pipeline automatically triggers within 1 minute

### 2.2 Prod Pipeline Triggers

**Automatic Triggers:**
- Push to `main` branch
- Merge of pull request to `main` branch

**Pipeline: web-pipeline-prod**

**Stages:**
1. Source: GitHub repository (main branch)
2. Build: CFN-Lint validation via buildspec-test.yml
3. Deploy: CloudFormation deployment via buildspec.yml

**Execution:**
```bash
git push origin main
```

Pipeline automatically triggers within 1 minute

### 2.3 Manual Pipeline Execution

**Dev Pipeline:**
```bash
aws codepipeline start-pipeline-execution \
  --name web-pipeline-dev \
  --region ap-southeast-2
```

**Prod Pipeline:**
```bash
aws codepipeline start-pipeline-execution \
  --name web-pipeline-prod \
  --region ap-southeast-2
```

Use manual execution only for:
- Re-running failed deployments
- Testing pipeline changes
- Emergency redeployments

## 3. Pre-Deployment Validation Steps

### 3.1 Local Validation

**Template Syntax:**
```bash
cfn-lint templates/*.yaml main.yaml pipeline-*.yaml
```

Expected: No errors or warnings

**Template Validation:**
```bash
aws cloudformation validate-template \
  --template-body file://main.yaml \
  --region ap-southeast-2
```

Expected: Valid template response

### 3.2 Code Review Validation

**Review Checklist:**
- [ ] All CloudFormation templates pass CFN-Lint
- [ ] Changes follow AWS best practices
- [ ] Security groups follow least privilege
- [ ] Resources tagged with Environment parameter
- [ ] Outputs and exports properly defined
- [ ] Documentation updated
- [ ] Rollback plan documented

### 3.3 Dev Environment Validation

**Prerequisites Before Prod Deployment:**
- [ ] Changes deployed successfully in dev
- [ ] Dev stack status: UPDATE_COMPLETE or CREATE_COMPLETE
- [ ] All CloudWatch alarms in OK state
- [ ] Application functionality verified
- [ ] Performance metrics within acceptable range
- [ ] Minimum 24 hours observation in dev
- [ ] No critical issues identified

**Verification Commands:**
```bash
aws cloudformation describe-stacks \
  --stack-name web-infrastructure-dev \
  --region ap-southeast-2 \
  --query 'Stacks[0].StackStatus'

aws cloudwatch describe-alarms \
  --alarm-name-prefix dev- \
  --region ap-southeast-2 \
  --query 'MetricAlarms[?StateValue!=`OK`].[AlarmName,StateValue]'
```

### 3.4 Change Approval

**Dev Deployment:**
- Pull request approval from 1 team member
- Automated CFN-Lint checks pass

**Prod Deployment:**
- Pull request approval from 2 team members
- Operations manager approval
- Dev environment validation complete
- Automated CFN-Lint checks pass

## 4. Post-Deployment Verification Procedures

### 4.1 Pipeline Execution Verification

**Monitor Pipeline Status:**
```bash
aws codepipeline get-pipeline-state \
  --name web-pipeline-prod \
  --region ap-southeast-2
```

**Check Stage Status:**
- Source: Succeeded
- Build: Succeeded
- Deploy: Succeeded

**Pipeline Execution Time:**
- Expected: 5-10 minutes
- Alert if: > 15 minutes

### 4.2 CloudFormation Stack Verification

**Stack Status:**
```bash
aws cloudformation describe-stacks \
  --stack-name web-infrastructure-prod \
  --region ap-southeast-2 \
  --query 'Stacks[0].[StackStatus,LastUpdatedTime]'
```

Expected: `UPDATE_COMPLETE` or `CREATE_COMPLETE`

**Stack Events:**
```bash
aws cloudformation describe-stack-events \
  --stack-name web-infrastructure-prod \
  --region ap-southeast-2 \
  --max-items 20
```

Review for any failed resources or warnings

**Stack Outputs:**
```bash
aws cloudformation describe-stacks \
  --stack-name web-infrastructure-prod \
  --region ap-southeast-2 \
  --query 'Stacks[0].Outputs'
```

Verify all expected outputs present

### 4.3 Infrastructure Health Verification

**ALB Target Health:**
```bash
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn> \
  --region ap-southeast-2 \
  --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State]'
```

Expected: All targets in `healthy` state

**EC2 Instance Status:**
```bash
aws ec2 describe-instance-status \
  --instance-ids <instance-id> \
  --region ap-southeast-2 \
  --query 'InstanceStatuses[*].[InstanceId,InstanceStatus.Status,SystemStatus.Status]'
```

Expected: Both checks `ok`

**Application Endpoint:**
```bash
curl -I http://<alb-dns-name>
```

Expected: HTTP 200 response

### 4.4 Monitoring Verification

**CloudWatch Dashboard:**
```bash
aws cloudwatch get-dashboard \
  --dashboard-name prod-infrastructure-dashboard \
  --region ap-southeast-2
```

Access dashboard in AWS Console and verify:
- All widgets displaying data
- Metrics updating in real-time
- No gaps in metric data

**CloudWatch Alarms:**
```bash
aws cloudwatch describe-alarms \
  --alarm-name-prefix prod- \
  --region ap-southeast-2 \
  --query 'MetricAlarms[*].[AlarmName,StateValue,StateReason]'
```

Expected: All alarms in `OK` state

**SNS Topic:**
```bash
aws sns list-subscriptions-by-topic \
  --topic-arn <sns-topic-arn> \
  --region ap-southeast-2 \
  --query 'Subscriptions[*].[Endpoint,SubscriptionArn]'
```

Verify email subscriptions confirmed

### 4.5 Log Verification

**CloudWatch Logs:**
```bash
aws logs tail /aws/ec2/web-server \
  --follow \
  --region ap-southeast-2 \
  --since 5m
```

Review for:
- No error messages
- Normal application startup
- Expected traffic patterns

**ALB Access Logs:**
```bash
aws logs filter-log-events \
  --log-group-name /aws/elasticloadbalancing/app \
  --start-time $(date -u -d '5 minutes ago' +%s)000 \
  --region ap-southeast-2
```

Verify requests being logged

### 4.6 Performance Verification

**Monitor for 1 hour post-deployment:**

**ALB Metrics:**
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name TargetResponseTime \
  --dimensions Name=LoadBalancer,Value=<alb-name> \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average \
  --region ap-southeast-2
```

Expected: Average < 1 second

**EC2 CPU:**
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=<instance-id> \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average \
  --region ap-southeast-2
```

Expected: Average < 80%

**Error Rate:**
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name HTTPCode_Target_5XX_Count \
  --dimensions Name=LoadBalancer,Value=<alb-name> \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum \
  --region ap-southeast-2
```

Expected: < 5% of total requests

## 5. Communication Requirements for Production Releases

### 5.1 Pre-Release Communication

**Timing: 24 hours before deployment**

**Recipients:**
- Operations team
- Development team
- Management
- Stakeholders (if user-facing changes)

**Communication Channels:**
- Email to operations@helios.id
- Slack #infrastructure-prod channel
- Status page (if user-facing)

**Required Information:**
- Release date and time
- Changes being deployed
- Expected impact (downtime, performance)
- Rollback plan
- Contact information for release manager

**Email Template:**
```
Subject: Production Release - [Date] - [Brief Description]

Release Details:
- Date: [YYYY-MM-DD]
- Time: [HH:MM AEST]
- Duration: [Expected deployment time]
- Environment: Production (ap-southeast-2)

Changes:
- [List of changes from PR description]

Impact:
- Expected downtime: [None/X minutes]
- User-facing changes: [Yes/No - describe]
- Performance impact: [None/describe]

Validation:
- Dev deployment: [Date completed]
- Testing results: [Summary]
- Alarms status: [All OK]

Rollback Plan:
- [Brief description of rollback procedure]
- Estimated rollback time: [X minutes]

Contact:
- Release Manager: [Name] - [Email] - [Phone]
- On-call Engineer: [Name] - [Email] - [Phone]

Approval:
- Operations Manager: [Name] - [Date]
```

### 5.2 During Release Communication

**Deployment Start:**
```
Slack: #infrastructure-prod
"🚀 Production deployment started - [Brief description]
Pipeline: web-pipeline-prod
Monitoring: [CloudWatch dashboard link]"
```

**Deployment Progress:**
Update every 5 minutes or at stage completion:
```
"✅ Source stage complete"
"✅ Build stage complete"
"⏳ Deploy stage in progress"
```

**Deployment Complete:**
```
"✅ Production deployment complete - [Brief description]
Stack Status: UPDATE_COMPLETE
Verification: In progress
Dashboard: [Link]"
```

### 5.3 Post-Release Communication

**Successful Deployment:**
```
Email Subject: Production Release Complete - [Date] - [Brief Description]

The production release has been successfully completed.

Deployment Summary:
- Start Time: [HH:MM AEST]
- End Time: [HH:MM AEST]
- Duration: [X minutes]
- Stack Status: UPDATE_COMPLETE

Verification Results:
✅ All CloudFormation resources deployed
✅ All targets healthy
✅ All alarms in OK state
✅ Application responding normally
✅ Performance metrics within range

Post-Deployment Monitoring:
- 1-hour observation period in progress
- CloudWatch dashboard: [Link]
- On-call engineer monitoring: [Name]

No action required.
```

**Failed Deployment:**
```
Email Subject: Production Release Failed - [Date] - [Brief Description]

The production release has failed and automatic rollback initiated.

Failure Summary:
- Start Time: [HH:MM AEST]
- Failure Time: [HH:MM AEST]
- Stack Status: ROLLBACK_COMPLETE
- Failure Reason: [Brief description]

Current Status:
- Application: [Operational/Degraded/Down]
- Rollback: [Complete/In Progress]
- Impact: [Description]

Next Steps:
- Root cause analysis in progress
- Incident ticket: [Link]
- Post-mortem scheduled: [Date/Time]

Contact:
- Incident Commander: [Name] - [Email] - [Phone]
```

### 5.4 Stakeholder Updates

**For User-Facing Changes:**

**Status Page Update:**
- Pre-deployment: "Scheduled maintenance [Date] [Time]"
- During deployment: "Maintenance in progress"
- Post-deployment: "Maintenance complete"

**Customer Communication:**
- Email to customers if downtime expected
- In-app notification if applicable
- Social media update if significant changes

### 5.5 Documentation Updates

**Post-Release:**
- Update release notes in repository
- Document any issues encountered
- Update runbooks if procedures changed
- Record lessons learned

**Release Record:**
Maintain in `docs/releases/YYYY-MM-DD-release-notes.md`:
```markdown
# Release Notes - YYYY-MM-DD

## Changes Deployed
- [List of changes]

## Deployment Timeline
- Start: HH:MM AEST
- Complete: HH:MM AEST
- Duration: X minutes

## Verification Results
- [Summary of verification]

## Issues Encountered
- [Any issues and resolutions]

## Rollback Actions
- [None or description]

## Lessons Learned
- [Key takeaways]
```

## 6. Release Schedule

### 6.1 Standard Release Windows

**Dev Environment:**
- Anytime during business hours (9 AM - 5 PM AEST)
- No approval required for off-hours

**Prod Environment:**
- Preferred: Tuesday-Thursday, 10 AM - 2 PM AEST
- Avoid: Monday (start of week), Friday (end of week)
- Avoid: Outside business hours unless emergency

### 6.2 Change Freeze Periods

**No Production Releases During:**
- Major holidays
- End of quarter (last 3 days)
- Known high-traffic periods
- Active incidents

**Exception:** Emergency hotfixes approved by operations manager

### 6.3 Release Cadence

**Target Frequency:**
- Dev: As needed (multiple per day acceptable)
- Prod: Weekly or bi-weekly
- Emergency: As required

## 7. Rollback Procedures

### 7.1 Automatic Rollback

CloudFormation automatically rolls back on deployment failure.

**Monitor Rollback:**
```bash
aws cloudformation describe-stack-events \
  --stack-name web-infrastructure-prod \
  --region ap-southeast-2 \
  --query 'StackEvents[?ResourceStatus==`ROLLBACK_IN_PROGRESS`]'
```

### 7.2 Manual Rollback

If issues detected post-deployment, follow rollback runbook:
- Reference: `docs/runbooks/rollback.md`
- Decision criteria in Change Management SOP
- Approval required for prod rollback

## 8. Emergency Release Process

### 8.1 Emergency Criteria

- Security vulnerability requiring immediate patch
- Production outage requiring urgent fix
- Critical bug affecting all users
- Data integrity issue

### 8.2 Expedited Process

1. Create hotfix branch from main
2. Implement minimal fix
3. Deploy to prod with single approval
4. Backport to dev
5. Complete full review post-deployment

### 8.3 Communication

- Immediate Slack notification
- Email within 1 hour
- Post-mortem within 24 hours

## References

- Deployment Runbook: `docs/runbooks/deployment.md`
- Rollback Runbook: `docs/runbooks/rollback.md`
- Incident Response Runbook: `docs/runbooks/incident-response.md`
- Change Management SOP: `docs/sops/change-management.md`
- Operations SOP: `docs/sops/operations.md`
