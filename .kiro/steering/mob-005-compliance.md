# MOB-005 AWS Migration Services Competency Compliance

## Project Context

This workspace implements AWS infrastructure using CloudFormation templates with CI/CD pipelines to comply with AWS Migration Services Competency requirement MOB-005 (Operations).

## Compliance Requirements

### MOB-005: Operations
AWS Partner establishes operational models and helps customers develop operations integration approach to support target state design in cloud.

**Required Evidence:**
1. Runbooks or SOPs covering:
   - Deployment automation
   - Configuration process
   - Change and release process
   - Business continuity
   - Operation health
   - Event and incident management

2. Dashboard or reports for:
   - Events monitoring
   - Logs analysis
   - Metrics tracking
   - Distributed tracing (if applicable)

### Current REL-001 Compliance
The workspace already implements REL-001 (Automate Development and leverage infrastructure-as-code):
- CloudFormation templates for all infrastructure
- CI/CD pipeline using CodePipeline and CodeBuild
- Automated deployment without AWS Console
- Multi-environment support (dev/prod)

## Code Generation Standards

### Strict Rules
- NO comments explaining code functionality
- NO placeholder comments like "this code for..."
- Bare minimum implementation only
- Focus on MOB-005 compliance requirements

### Infrastructure Components
**Existing (REL-001 compliant):**
- `templates/network.yaml` - VPC, subnets, routing
- `templates/security.yaml` - Security groups
- `templates/alb.yaml` - Application Load Balancer
- `templates/ec2.yaml` - EC2 instances
- `main.yaml` - Main orchestration template
- `pipeline-dev.yaml` - Dev pipeline
- `pipeline-prod.yaml` - Prod pipeline
- `buildspec.yml` - Deployment automation
- `buildspec-test.yml` - Testing automation

**Required for MOB-005:**
- CloudWatch dashboards for monitoring
- CloudWatch alarms for incident detection
- CloudWatch Logs configuration
- SNS topics for alerting
- Runbook documentation
- SOP documentation

## Implementation Guidelines

### When Adding Monitoring
- Use CloudWatch for metrics, logs, and dashboards
- Configure alarms for critical infrastructure components
- Set up SNS for notifications
- Enable X-Ray if distributed tracing needed

### When Creating Runbooks
Document step-by-step procedures for:
1. Deployment process (already automated via pipeline)
2. Configuration changes
3. Release management
4. Incident response
5. Health checks and validation
6. Rollback procedures

### When Creating SOPs
Cover operational procedures for:
- Daily operations
- Change management
- Release process
- Business continuity
- Monitoring and alerting
- Incident management

### File Organization
```
├── templates/
│   ├── monitoring.yaml       # CloudWatch dashboards, alarms
│   └── [existing templates]
├── docs/
│   ├── runbooks/
│   │   ├── deployment.md
│   │   ├── incident-response.md
│   │   └── rollback.md
│   └── sops/
│       ├── change-management.md
│       ├── release-process.md
│       └── operations.md
└── [existing files]
```

## Validation Criteria

### Passing Criteria
- Written deployment and change management process description
- CloudFormation templates for monitoring infrastructure
- Architecture diagrams showing monitoring flow
- Dashboard screenshots or configuration
- Reports from monitoring tools
- Step-by-step runbooks
- Operational SOPs

### Unacceptable Responses
- Generic descriptions without specifics
- Lack of concrete evidence
- Missing monitoring dashboards
- No operational procedures
- Responding "N/A" or "customer responsibility"

## AWS Services to Use

### Monitoring & Observability
- AWS CloudWatch (metrics, logs, dashboards, alarms)
- AWS X-Ray (distributed tracing if needed)
- AWS CloudTrail (audit logging)
- Amazon SNS (notifications)

### Deployment & Automation
- AWS CloudFormation (infrastructure-as-code)
- AWS CodePipeline (CI/CD orchestration)
- AWS CodeBuild (build and deployment)
- AWS CodeDeploy (deployment automation)

## Using AWS Knowledge MCP Server

### Before Implementation
- **Verify regional availability**: Use MCP to check if services/features are available in ap-southeast-2
- **Check CloudFormation support**: Verify resource types and properties are supported
- **Review best practices**: Search AWS documentation for service-specific guidance

### During Implementation
- **Troubleshoot errors**: Look up CloudFormation error messages in AWS docs
- **Validate configurations**: Check recommended settings for monitoring and alarms
- **Verify compliance**: Search for AWS Well-Architected Framework guidance

### Example MCP Queries
- "CloudWatch dashboard best practices"
- "CloudFormation alarm configuration for ALB"
- "SNS topic setup for operational alerts"
- "Regional availability for CloudWatch features in ap-southeast-2"

## Reference Architecture

### Current Pipeline Flow
1. Developer commits CloudFormation template to GitHub
2. Pipeline triggers on branch push (dev/main)
3. CodePipeline clones repository
4. CodeBuild executes buildspec
5. CloudFormation deploys infrastructure
6. Validation through CloudWatch dashboard

### Required Monitoring Flow
1. Infrastructure emits metrics to CloudWatch
2. CloudWatch Logs aggregates application logs
3. CloudWatch Alarms monitor thresholds
4. SNS sends notifications on alarm state
5. Dashboard displays real-time health status
6. X-Ray traces requests (if applicable)

## Key Principles

1. **Automation First**: All operations must be automated via CloudFormation
2. **Infrastructure as Code**: No manual AWS Console changes
3. **Monitoring Built-in**: Every resource must have monitoring
4. **Documentation Required**: Runbooks and SOPs are mandatory
5. **Bare Minimum**: Only implement what's required for compliance
6. **No Code Comments**: Code must be self-explanatory
