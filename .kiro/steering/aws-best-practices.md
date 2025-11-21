# AWS Best Practices & MCP Integration

## AWS Knowledge MCP Server

This workspace has access to the AWS Knowledge MCP server for real-time AWS documentation and best practices.

### When to Use MCP Tools

**Before implementing new AWS resources:**
- Search AWS documentation for service-specific best practices
- Check regional availability for services and features
- Review CloudFormation resource documentation
- Verify API compatibility and limitations

**For troubleshooting:**
- Look up error messages in AWS documentation
- Find recommended solutions for common issues
- Check service quotas and limits

**For compliance and security:**
- Verify security best practices for services
- Check compliance requirements (MOB-005, REL-001)
- Review IAM permission requirements

## CloudFormation Best Practices

### Template Structure
- Use nested stacks for modularity (already implemented)
- Export outputs for cross-stack references
- Use `!Sub` for dynamic resource naming with environment
- Always include `DependsOn` for explicit dependencies

### Resource Naming
- Pattern: `{service}-{resource-type}-{environment}`
- Use `!Sub` with Environment parameter
- Tag all resources with Name and Environment

### Parameters
- Limit to environment-specific values
- Use `AllowedValues` for validation
- Provide clear descriptions

### Outputs
- Export critical resource IDs (VPC, subnets, security groups)
- Use consistent export naming: `${AWS::StackName}-{Resource}-{Property}`
- Document all outputs with descriptions

## Security Best Practices

### IAM Roles
- Least privilege principle
- Service-specific roles (CodeBuild, CodePipeline, EC2)
- No inline policies for production
- Use managed policies where possible

### Network Security
- Security groups over NACLs for stateful filtering
- Separate security groups per tier (ALB, EC2)
- No 0.0.0.0/0 ingress except for ALB on 80/443
- Private subnets for application tier

### Secrets Management
- No hardcoded credentials
- Use AWS Secrets Manager or Parameter Store
- Reference secrets via dynamic references in CloudFormation

## Monitoring & Operations (MOB-005)

### CloudWatch Integration
- Enable detailed monitoring for critical resources
- Create custom metrics for application health
- Set up log groups with retention policies
- Use metric filters for error detection

### Alarms
- CPU/Memory thresholds for EC2
- Target response time for ALB
- Unhealthy target count for ALB
- 4xx/5xx error rates

### Dashboards
- Infrastructure health overview
- Application performance metrics
- Cost and usage tracking
- Alarm status summary

## Regional Considerations

### Primary Region: ap-southeast-2 (Sydney)
- All production and dev infrastructure
- Pipeline execution region
- Monitoring and logging region

### Testing Region: us-west-2 (Oregon)
- TaskCat isolated testing
- Prevents resource conflicts
- Automatic cleanup after tests

### Service Availability
- Always verify service availability in target regions using MCP tools
- Check for regional feature differences
- Consider data residency requirements

## Cost Optimization

### Instance Sizing
- t3.micro for dev/test workloads
- Right-size based on CloudWatch metrics
- Use Auto Scaling for variable loads

### Storage
- S3 lifecycle policies for artifacts
- Delete old CloudFormation stacks
- Clean up test resources automatically

### Networking
- Single NAT Gateway per environment (not per AZ)
- VPC endpoints for AWS services to avoid NAT costs
- CloudFront for static content delivery

## Deployment Strategy

### Environment Progression
1. Dev: Automated testing + deployment on `dev` branch
2. Prod: Deployment only on `main` branch
3. No manual console changes

### Rollback Strategy
- Automatic rollback on CloudFormation failures
- Stack event logging for debugging
- Preserve previous stack state

### Testing
- CFN-Lint for syntax validation
- TaskCat for deployment testing
- Separate test region to avoid conflicts
