# Project Structure

## Root Files

- `main.yaml` - Main orchestration template, references nested stacks
- `pipeline-dev.yaml` - Dev environment CI/CD pipeline
- `pipeline-prod.yaml` - Prod environment CI/CD pipeline
- `buildspec.yml` - Deployment automation for CodeBuild
- `buildspec-test.yml` - Testing automation (CFN-Lint + TaskCat)
- `.taskcat.yml` - TaskCat testing configuration

## Templates Directory

Modular CloudFormation templates for infrastructure components:

- `templates/network.yaml` - VPC, subnets, IGW, NAT Gateway, route tables
- `templates/security.yaml` - Security groups for ALB and EC2
- `templates/alb.yaml` - Application Load Balancer and target groups
- `templates/ec2.yaml` - EC2 instances with Nginx, auto-registration to ALB

## Architecture Pattern

**Nested Stacks**: `main.yaml` orchestrates child stacks via S3-hosted templates

**Stack Dependencies**:
1. Network (VPC, subnets)
2. Security (security groups, depends on VPC)
3. ALB (depends on VPC and security groups)
4. EC2 (depends on security groups and ALB target group)

## Naming Conventions

- Stacks: `web-{component}-{environment}`
- Resources: `{component}-{resource-type}-{environment}`
- S3 Buckets: `web-{purpose}-{environment}-{account-id}`
- Parameters: PascalCase (e.g., `Environment`, `VPCId`)

## Environment Separation

- Dev and prod use separate pipelines, buckets, and stacks
- Environment parameter controls resource naming and configuration
- No shared resources between environments
