# AWS Knowledge MCP Server Usage Guide

## Available MCP Tools

The workspace has access to AWS Knowledge MCP server with these capabilities:

1. **Search Documentation** - Find AWS service documentation and guides
2. **Read Documentation** - Get detailed content from AWS docs pages
3. **Get Recommendations** - Discover related AWS documentation
4. **Check Regional Availability** - Verify service/feature availability by region

## When to Use MCP Tools

### Planning Phase
- Search for service capabilities before designing solutions
- Check regional availability for all services in ap-southeast-2
- Review CloudFormation resource documentation
- Find architecture best practices

### Implementation Phase
- Look up CloudFormation resource properties and syntax
- Verify API parameters and return values
- Check service limits and quotas
- Find code examples and patterns

### Troubleshooting Phase
- Search for error messages and solutions
- Review service-specific troubleshooting guides
- Check for known issues or limitations
- Find debugging techniques

### Compliance Phase
- Search for security best practices
- Review compliance documentation (MOB-005)
- Check monitoring and logging requirements
- Verify operational excellence patterns

## MCP Query Patterns

### Service Research
```
"CloudWatch dashboard configuration"
"ALB target group health checks"
"EC2 instance monitoring metrics"
```

### Regional Verification
```
Check availability of CloudWatch features in ap-southeast-2
Verify SNS service availability in ap-southeast-2
```

### CloudFormation Syntax
```
"AWS::CloudWatch::Alarm properties"
"AWS::SNS::Topic CloudFormation"
"CloudFormation nested stack parameters"
```

### Best Practices
```
"CloudWatch alarm best practices"
"ALB monitoring recommendations"
"VPC security group design patterns"
```

## Integration with Workflow

### Before Creating Templates
1. Search AWS docs for service overview
2. Check regional availability
3. Review CloudFormation resource documentation
4. Find recommended configurations

### During Template Development
1. Look up resource properties as needed
2. Verify syntax and required fields
3. Check for service-specific requirements
4. Review examples and patterns

### After Implementation
1. Search for monitoring best practices
2. Review operational recommendations
3. Check for optimization opportunities
4. Verify compliance requirements

## Project-Specific MCP Usage

### For MOB-005 Compliance
- Search "AWS operational excellence monitoring"
- Look up "CloudWatch dashboard design patterns"
- Find "incident management with CloudWatch alarms"
- Review "SNS notification best practices"

### For Infrastructure Templates
- Verify CloudFormation resource availability in ap-southeast-2
- Check for new CloudFormation features
- Review service-specific CloudFormation examples
- Find troubleshooting guides for deployment issues

### For CI/CD Pipeline
- Search "CodePipeline best practices"
- Look up "CodeBuild optimization techniques"
- Review "CloudFormation deployment strategies"
- Find "automated testing patterns"
