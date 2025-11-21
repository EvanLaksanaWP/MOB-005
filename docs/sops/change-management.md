# Change Management Standard Operating Procedure

## Purpose

This SOP defines the process for proposing, reviewing, approving, and deploying infrastructure changes to ensure controlled and safe modifications to the AWS environment.

## Scope

Applies to all CloudFormation template changes, pipeline modifications, and infrastructure configuration updates for both dev and prod environments.

## Process Overview

```
Propose Change → Review → Approve → Test in Dev → Deploy to Prod → Verify
```

## 1. Proposing Infrastructure Changes

### 1.1 Create Feature Branch

```bash
git checkout -b feature/description-of-change
```

### 1.2 Make Changes

Modify CloudFormation templates, pipeline configurations, or documentation as needed:
- `templates/*.yaml` - Infrastructure components
- `main.yaml` - Stack orchestration
- `pipeline-*.yaml` - CI/CD configuration
- `buildspec*.yml` - Build automation
- `docs/` - Documentation updates

### 1.3 Validate Changes Locally

```bash
cfn-lint templates/*.yaml main.yaml
```

### 1.4 Commit and Push

```bash
git add .
git commit -m "Description of change"
git push origin feature/description-of-change
```

### 1.5 Create Pull Request

Create PR in GitHub with:
- Clear description of changes
- Rationale for the change
- Impact assessment (resources affected, downtime expected)
- Rollback plan
- Testing approach

## 2. Review and Approval Requirements

### 2.1 Required Reviews

**All Changes:**
- Minimum 1 peer review from infrastructure team member
- Review for CloudFormation syntax and best practices
- Security review for IAM roles, security groups, network changes

**Production Changes:**
- Minimum 2 peer reviews
- Operations team approval
- Security team approval for security-related changes

### 2.2 Review Checklist

Reviewers must verify:
- [ ] CloudFormation templates pass CFN-Lint validation
- [ ] Changes follow AWS best practices
- [ ] Security groups follow least privilege principle
- [ ] Resources properly tagged with Environment
- [ ] Outputs and exports correctly defined
- [ ] Documentation updated (runbooks, SOPs)
- [ ] Rollback plan documented in PR description
- [ ] No hardcoded credentials or sensitive data

### 2.3 Approval Process

1. Submit PR for review
2. Address reviewer feedback
3. Obtain required approvals
4. Merge to `dev` branch for testing

## 3. Dev-to-Prod Promotion Workflow

### 3.1 Dev Environment Testing

**Automatic Deployment:**
```
Merge to dev branch → Dev pipeline triggers → Deploy to dev environment
```

**Verification Steps:**
1. Monitor pipeline execution in CodePipeline console
2. Verify CloudFormation stack deployment succeeds
3. Check CloudWatch dashboard for infrastructure health
4. Review CloudWatch Logs for errors
5. Verify alarm states are OK
6. Test application functionality

**Duration:** Allow minimum 24 hours in dev for observation

### 3.2 Production Promotion

**Prerequisites:**
- [ ] Changes successfully deployed in dev environment
- [ ] All testing requirements completed
- [ ] No critical alarms triggered in dev
- [ ] Application functionality verified
- [ ] Rollback plan confirmed
- [ ] Change window scheduled (if required)
- [ ] Stakeholders notified

**Promotion Process:**
1. Create PR from `dev` to `main` branch
2. Include dev testing results in PR description
3. Obtain production deployment approval
4. Merge to `main` branch
5. Monitor production pipeline execution
6. Execute post-deployment verification

## 4. Testing Requirements in Dev Environment

### 4.1 Infrastructure Testing

**CloudFormation Validation:**
```bash
aws cloudformation describe-stacks \
  --stack-name web-infrastructure-dev \
  --region ap-southeast-2 \
  --query 'Stacks[0].StackStatus'
```

Expected: `CREATE_COMPLETE` or `UPDATE_COMPLETE`

**Resource Verification:**
```bash
aws cloudformation describe-stack-resources \
  --stack-name web-infrastructure-dev \
  --region ap-southeast-2
```

Verify all resources in `CREATE_COMPLETE` or `UPDATE_COMPLETE` state

### 4.2 Monitoring Validation

**Dashboard Access:**
```bash
aws cloudwatch get-dashboard \
  --dashboard-name dev-infrastructure-dashboard \
  --region ap-southeast-2
```

**Alarm Status:**
```bash
aws cloudwatch describe-alarms \
  --alarm-name-prefix dev- \
  --region ap-southeast-2 \
  --query 'MetricAlarms[*].[AlarmName,StateValue]'
```

All alarms should be in `OK` state

### 4.3 Application Testing

**ALB Health Check:**
```bash
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn> \
  --region ap-southeast-2
```

All targets should show `healthy` state

**Application Endpoint:**
```bash
curl -I http://<alb-dns-name>
```

Expected: HTTP 200 response

### 4.4 Log Verification

```bash
aws logs tail /aws/ec2/web-server --follow --region ap-southeast-2
```

Review logs for errors or warnings

### 4.5 Performance Testing

Monitor for 24 hours:
- ALB response time < 1 second
- EC2 CPU utilization < 80%
- No 5xx errors
- All targets healthy

## 5. Rollback Decision Criteria and Approval

### 5.1 Rollback Triggers

**Automatic Rollback:**
- CloudFormation stack deployment fails
- Stack enters `ROLLBACK_IN_PROGRESS` state

**Manual Rollback Required When:**
- Critical alarms triggered post-deployment
- Application functionality broken
- Performance degradation > 20%
- Security vulnerability introduced
- Data integrity issues detected

### 5.2 Rollback Decision Process

**Severity Assessment:**

**Critical (Immediate Rollback):**
- Production outage
- Security breach
- Data loss or corruption
- All targets unhealthy

**High (Rollback within 1 hour):**
- Partial service degradation
- Performance issues affecting users
- Multiple alarms triggered

**Medium (Evaluate and decide):**
- Minor performance degradation
- Single alarm triggered
- Non-critical functionality affected

**Low (Monitor and fix forward):**
- Cosmetic issues
- Non-user-facing problems
- Documentation errors

### 5.3 Rollback Approval

**Dev Environment:**
- Infrastructure team member can initiate rollback
- No additional approval required

**Production Environment:**

**Critical/High Severity:**
- On-call engineer can initiate immediate rollback
- Notify operations manager within 15 minutes
- Post-incident review required

**Medium Severity:**
- Operations manager approval required
- Evaluate fix-forward vs rollback options
- Document decision rationale

### 5.4 Rollback Execution

**Automatic Rollback:**
Monitor CloudFormation events:
```bash
aws cloudformation describe-stack-events \
  --stack-name web-infrastructure-prod \
  --region ap-southeast-2 \
  --max-items 20
```

**Manual Rollback:**
1. Identify last known good commit
2. Create hotfix branch from last good commit
3. Create emergency PR to main branch
4. Obtain expedited approval
5. Merge and deploy
6. Verify rollback success

**Verification:**
```bash
aws cloudformation describe-stacks \
  --stack-name web-infrastructure-prod \
  --region ap-southeast-2 \
  --query 'Stacks[0].[StackStatus,LastUpdatedTime]'
```

### 5.5 Post-Rollback Actions

1. Document rollback reason and timeline
2. Analyze root cause of failure
3. Update change proposal with lessons learned
4. Schedule post-mortem meeting
5. Update testing procedures if needed
6. Plan corrective deployment

## 6. Emergency Changes

### 6.1 Emergency Change Criteria

- Security vulnerability requiring immediate patch
- Production outage requiring urgent fix
- Critical bug affecting all users

### 6.2 Expedited Process

1. Create hotfix branch
2. Implement minimal fix
3. Single peer review (can be concurrent with deployment)
4. Deploy directly to prod if necessary
5. Backport to dev environment
6. Complete full review post-deployment
7. Document as emergency change in post-mortem

### 6.3 Emergency Approval

- Operations manager or on-call engineer
- Verbal approval acceptable (document in writing within 24 hours)
- Full change review conducted post-deployment

## 7. Change Documentation

### 7.1 Change Record

Maintain in PR description:
- Change ID (PR number)
- Date and time
- Environments affected
- Resources modified
- Approvers
- Deployment outcome
- Rollback actions (if any)

### 7.2 Communication

**Dev Deployments:**
- Slack notification to #infrastructure-dev channel

**Prod Deployments:**
- Email to operations team 24 hours before deployment
- Slack notification to #infrastructure-prod channel
- Update status page if user-facing changes

## 8. Compliance and Audit

### 8.1 Audit Trail

All changes tracked via:
- Git commit history
- GitHub PR records
- CloudFormation stack events
- CloudTrail API logs

### 8.2 Periodic Review

- Monthly review of change success rate
- Quarterly review of rollback frequency
- Annual SOP review and update

## References

- Deployment Runbook: `docs/runbooks/deployment.md`
- Rollback Runbook: `docs/runbooks/rollback.md`
- Incident Response Runbook: `docs/runbooks/incident-response.md`
- Release Process SOP: `docs/sops/release-process.md`
