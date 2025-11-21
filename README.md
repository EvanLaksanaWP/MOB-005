# CloudFormation CI/CD Pipeline

## Architecture Overview

This project implements a complete CI/CD pipeline for AWS 2-tier web infrastructure using CloudFormation, CodePipeline, and CodeBuild.

### Infrastructure Components
- **VPC**: Custom VPC with public/private subnets across 2 AZs
- **ALB**: Application Load Balancer for high availability
- **EC2**: Auto-configured web server with Nginx
- **Security Groups**: Proper network security controls
- **IAM**: Least privilege access roles

### Pipeline Architecture
- **Dev Pipeline**: Source → Test (CFN-Lint + TaskCat) → Deploy
- **Prod Pipeline**: Source → Deploy (with automatic rollback)

## File Structure

```
├── templates/
│   ├── network.yaml      # VPC, subnets, routing
│   ├── security.yaml     # Security groups
│   ├── alb.yaml         # Application Load Balancer
│   └── ec2.yaml         # EC2 instance with auto-registration
├── main.yaml            # Main orchestration template
├── pipeline-dev.yaml    # Dev environment pipeline
├── pipeline-prod.yaml   # Prod environment pipeline
├── buildspec.yml        # Deployment build specification
├── buildspec-test.yml   # Testing build specification
└── .taskcat.yml         # TaskCat testing configuration
```

## Deployment Instructions

### Prerequisites
1. AWS CLI configured with appropriate permissions
2. GitHub repository: `EvanLaksanaWP/cloudformation-cicd-mcr`
3. CodeConnections connection created (ARN in pipeline templates)

### Deploy Pipelines

#### 1. Deploy Dev Pipeline
```bash
aws cloudformation deploy \
  --template-file pipeline-dev.yaml \
  --stack-name web-pipeline-dev \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND
```

#### 2. Deploy Prod Pipeline
```bash
aws cloudformation deploy \
  --template-file pipeline-prod.yaml \
  --stack-name web-pipeline-prod \
  --capabilities CAPABILITY_IAM \
```

### Pipeline Triggers
- **Dev Environment**: Push to `dev` branch
- **Prod Environment**: Push to `main` branch

## Pipeline Features

### Dev Pipeline
1. **Source Stage**: GitHub webhook trigger
2. **Test Stage**: 
   - CFN-Lint validation (ignores warnings)
   - TaskCat deployment testing in us-west-2
   - Generates test reports as artifacts
3. **Deploy Stage**: Infrastructure deployment to ap-southeast-2

### Prod Pipeline
1. **Source Stage**: GitHub webhook trigger
2. **Deploy Stage**: 
   - Infrastructure deployment with automatic rollback on failure
   - Comprehensive error logging and stack event tracking

### Testing Strategy
- **CFN-Lint**: Template syntax and best practices validation
- **TaskCat**: Actual deployment testing in isolated region
- **Automatic Cleanup**: Test resources automatically deleted
- **Artifact Storage**: Test reports stored in S3 for review

### Rollback Strategy
- **Automatic Detection**: Monitors CloudFormation deployment status
- **Immediate Rollback**: Triggers on any deployment failure
- **Stack Recovery**: Handles both update and create failures
- **Event Logging**: Detailed failure analysis in build logs

## Monitoring & Troubleshooting

### Pipeline Status
- CodePipeline Console: Monitor pipeline execution
- CodeBuild Logs: Detailed build and deployment logs
- CloudFormation Events: Stack creation/update progress

### Key Outputs
- **ALB DNS Name**: Access point for deployed application
- **VPC ID**: For additional resource deployment
- **Environment**: Current deployment environment

### Common Issues
1. **CFN-Lint Failures**: Check template syntax and AWS resource properties
2. **TaskCat Failures**: Verify region availability and resource limits
3. **Deployment Failures**: Check IAM permissions and resource conflicts

## Security Features
- **Least Privilege IAM**: Minimal required permissions
- **Network Security**: Proper security group configurations
- **Resource Isolation**: Environment-specific naming and tagging
- **Secrets Management**: No hardcoded credentials

## Cost Optimization
- **t3.micro instances**: Cost-effective compute
- **Automatic cleanup**: Test resources don't accumulate
- **Regional isolation**: Testing in different region prevents conflicts
- **Efficient builds**: Fast pipeline execution reduces build time costs

## Contributing
1. Create feature branch from `dev`
2. Make changes and test locally with CFN-Lint
3. Push to feature branch
4. Create PR to `dev` branch
5. After testing, merge to `main` for production deployment