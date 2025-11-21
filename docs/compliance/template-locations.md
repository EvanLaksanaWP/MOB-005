# CloudFormation Template Locations

## Repository Structure

All CloudFormation templates are version-controlled in the GitHub repository and deployed via CI/CD pipeline.

## Main Templates

### main.yaml
**Location**: Root directory
**Purpose**: Main orchestration template that deploys nested stacks
**Resources**:
- NetworkStack (references templates/network.yaml)
- SecurityStack (references templates/security.yaml)
- ALBStack (references templates/alb.yaml)
- EC2Stack (references templates/ec2.yaml)
- MonitoringStack (references templates/monitoring.yaml)

**Deployment**: Deployed by CodePipeline via buildspec.yml

### pipeline-dev.yaml
**Location**: Root directory
**Purpose**: CI/CD pipeline for dev environment
**Trigger**: Push to `dev` branch
**Region**: ap-southeast-2

### pipeline-prod.yaml
**Location**: Root directory
**Purpose**: CI/CD pipeline for prod environment
**Trigger**: Push to `main` branch
**Region**: ap-southeast-2

## Nested Stack Templates

### templates/network.yaml
**Purpose**: VPC and networking infrastructure
**Resources**:
- VPC with CIDR 10.0.0.0/16
- Public subnets in 2 availability zones
- Private subnets in 2 availability zones
- Internet Gateway
- NAT Gateway
- Route tables and associations

**Outputs**: VPC ID, subnet IDs, route table IDs

### templates/security.yaml
**Purpose**: Security groups for infrastructure components
**Resources**:
- ALB security group (allows HTTP/HTTPS from internet)
- EC2 security group (allows traffic from ALB)

**Outputs**: Security group IDs

### templates/alb.yaml
**Purpose**: Application Load Balancer configuration
**Resources**:
- Application Load Balancer
- Target group with health checks
- HTTP listener (port 80)

**Outputs**: ALB DNS name, ALB full name, target group ARN, target group full name

### templates/ec2.yaml
**Purpose**: EC2 instances with Nginx web server
**Resources**:
- EC2 instance with t3.micro instance type
- Detailed monitoring enabled
- CloudWatch agent installation via user data
- Automatic target group registration

**Outputs**: EC2 instance ID, private IP address

### templates/monitoring.yaml
**Purpose**: Monitoring and alerting infrastructure
**Resources**:
- SNS topic for operational notifications
- Email subscriptions (evan.pratama@helios.id, yuwan.cornelius@helios.id)
- CloudWatch dashboard with ALB and EC2 metrics
- CloudWatch alarms:
  - ALB unhealthy targets
  - ALB response time
  - ALB 5xx errors
  - EC2 high CPU
- CloudWatch log groups:
  - /aws/alb/{Environment}
  - /aws/ec2/{Environment}

**Outputs**: SNS topic ARN, dashboard name, log group names

## Build Specifications

### buildspec.yml
**Location**: Root directory
**Purpose**: Deployment automation for CodeBuild
**Phases**:
1. Install: Install AWS CLI and dependencies
2. Pre-build: Validate templates with CFN-Lint
3. Build: Upload templates to S3
4. Deploy: Execute CloudFormation deployment

### buildspec-test.yml
**Location**: Root directory
**Purpose**: Testing automation for CodeBuild
**Phases**:
1. Install: Install CFN-Lint and TaskCat
2. Build: Run CFN-Lint validation
3. Post-build: Execute TaskCat deployment tests

## S3 Template Storage

During deployment, templates are uploaded to S3 for nested stack references:

**Bucket Pattern**: `web-templates-{environment}-{account-id}`
**Region**: ap-southeast-2
**Template Path**: `templates/{template-name}.yaml`

Example:
- s3://web-templates-dev-123456789012/templates/network.yaml
- s3://web-templates-dev-123456789012/templates/monitoring.yaml

## Template Access

### Via GitHub Repository
All templates are accessible in the repository:
- Repository: [Your GitHub repository URL]
- Branch: `dev` for development, `main` for production

### Via AWS Console
Deployed templates can be viewed in CloudFormation:
1. Navigate to CloudFormation service in ap-southeast-2
2. Select stack (e.g., `web-infrastructure-dev`)
3. Click "Template" tab to view deployed template

### Via AWS CLI
```bash
# View main stack template
aws cloudformation get-template \
  --stack-name web-infrastructure-dev \
  --region ap-southeast-2

# View nested stack template
aws cloudformation get-template \
  --stack-name web-infrastructure-dev-MonitoringStack \
  --region ap-southeast-2
```

## Template Validation

All templates are validated before deployment:

**CFN-Lint**: Validates CloudFormation syntax and best practices
```bash
cfn-lint templates/*.yaml main.yaml
```

**TaskCat**: Tests actual deployment in isolated environment
```bash
taskcat test run
```

## Version Control

All templates are version-controlled in Git:
- Commit history tracks all changes
- Pull requests required for changes
- Code review before merging
- Separate branches for dev and prod

## Compliance Mapping

**MOB-005 Requirements**:
- Infrastructure-as-code: All resources defined in CloudFormation
- Version control: Templates stored in Git repository
- Automated deployment: CI/CD pipeline deploys templates
- Monitoring infrastructure: Dedicated monitoring.yaml template
- Operational procedures: Documented in docs/runbooks and docs/sops
