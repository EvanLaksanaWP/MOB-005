# Technology Stack

## Infrastructure

- **IaC**: AWS CloudFormation (YAML templates)
- **CI/CD**: AWS CodePipeline, AWS CodeBuild
- **Compute**: EC2 (t3.micro), Application Load Balancer
- **Networking**: VPC, NAT Gateway, Internet Gateway
- **Monitoring**: CloudWatch (metrics, logs, dashboards, alarms)
- **Notifications**: Amazon SNS
- **Source Control**: GitHub with CodeConnections

## AWS Knowledge Integration

- **MCP Server**: AWS Knowledge MCP server configured for real-time documentation access
- Use MCP tools to verify service availability, check best practices, and troubleshoot issues
- Always consult AWS documentation via MCP before implementing new services or features

## Build Tools

- **Testing**: CFN-Lint, TaskCat
- **Runtime**: Python 3.9 (CodeBuild)
- **Build Image**: aws/codebuild/amazonlinux2-x86_64-standard:3.0

## Common Commands

### Deploy Pipelines

```bash
# Dev pipeline
aws cloudformation deploy \
  --template-file pipeline-dev.yaml \
  --stack-name web-pipeline-dev \
  --capabilities CAPABILITY_IAM \
  --region ap-southeast-2

# Prod pipeline
aws cloudformation deploy \
  --template-file pipeline-prod.yaml \
  --stack-name web-pipeline-prod \
  --capabilities CAPABILITY_IAM \
  --region ap-southeast-2
```

### Manual Stack Deployment

```bash
aws cloudformation deploy \
  --template-file main.yaml \
  --stack-name web-infrastructure-dev \
  --parameter-overrides Environment=dev \
  --capabilities CAPABILITY_IAM
```

### Testing

```bash
# Lint templates
cfn-lint templates/*.yaml main.yaml

# TaskCat test
taskcat test run
```

## Pipeline Triggers

- **Dev**: Push to `dev` branch
- **Prod**: Push to `main` branch

## Region Configuration

- **Primary**: ap-southeast-2 (Sydney)
- **Testing**: us-west-2 (Oregon) - TaskCat isolation
