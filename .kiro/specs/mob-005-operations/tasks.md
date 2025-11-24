# Implementation Plan

- [x] 1. Create monitoring CloudFormation template
  - Create templates/monitoring.yaml with SNS topic, CloudWatch dashboard, alarms, and log groups
  - Define parameters for Environment, ALBFullName, TargetGroupFullName, EC2InstanceId
  - Configure SNS topic with two email subscriptions (evan.pratama@helios.id and yuwan.cornelius@helios.id)
  - Define CloudWatch dashboard with ALB and EC2 metric widgets
  - Create CloudWatch alarms for unhealthy targets, response time, 5xx errors, and CPU utilization
  - Define CloudWatch log groups with 30-day retention
  - Add outputs for SNS topic ARN, dashboard name, and log group names
  - _Requirements: 1.1, 2.1, 2.2, 2.3, 2.4, 3.1, 11.2, 11.3, 11.4, 11.5, 12.1_

- [x] 1.1 Write property test for dashboard metric coverage
  - **Property 1: Dashboard contains all required metrics**
  - **Validates: Requirements 1.3**

- [x] 1.2 Write property test for log retention configuration
  - **Property 2: All log groups have retention configured**
  - **Validates: Requirements 3.4**

- [x] 1.3 Write property test for alarm notification configuration
  - **Property 3: All alarms have SNS notification configured**
  - **Validates: Requirements 2.5, 2.6**

- [x] 2. Update main orchestration template
  - Update main.yaml to add MonitoringStack nested stack resource
  - Pass ALB and EC2 resource identifiers from existing stacks to monitoring stack
  - Configure MonitoringStack to depend on ALB and EC2 stacks
  - Add monitoring stack outputs to main.yaml exports
  - _Requirements: 11.1, 11.6_

- [x] 2.1 Write property test for monitoring stack integration
  - **Property 4: Monitoring stack integrates with main stack**
  - **Validates: Requirements 11.6**

- [x] 3. Update ALB template for logging
  - Update templates/alb.yaml to export ALB full name output
  - Add ALB full name to outputs section for monitoring stack reference
  - Document ALB access logging configuration (note: ALB logs to S3, not CloudWatch Logs directly)
  - _Requirements: 3.2_

- [x] 4. Update EC2 template for enhanced monitoring
  - Update templates/ec2.yaml to enable detailed monitoring (Monitoring: true)
  - Add CloudWatch agent installation commands to EC2 user data
  - Configure CloudWatch agent to stream Nginx logs to CloudWatch Logs
  - Export EC2 instance ID output for monitoring stack reference
  - _Requirements: 1.5, 3.3_

- [x] 5. Create deployment runbook
  - Create docs/runbooks/deployment.md
  - Document prerequisites including AWS CLI configuration and GitHub access
  - Provide step-by-step deployment instructions via pipeline
  - Include validation steps to verify successful deployment
  - Document CloudFormation stack status checks and output verification
  - Document automatic rollback behavior and manual intervention steps for failures
  - Include SNS email subscription confirmation requirement
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 12.5_

- [x] 6. Create incident response runbook
  - Create docs/runbooks/incident-response.md
  - Document procedures for responding to CloudWatch alarms
  - Provide investigation steps for unhealthy ALB targets
  - Provide investigation steps for high EC2 CPU utilization
  - Provide investigation steps for ALB 5xx errors
  - Include AWS CLI commands to check CloudWatch metrics, logs, and CloudFormation events
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [x] 7. Create rollback runbook
  - Create docs/runbooks/rollback.md
  - Document automatic rollback triggers in the pipeline
  - Provide steps to verify rollback completion
  - Document how to check CloudFormation stack events for rollback status
  - Include AWS CLI commands to describe stack status and review failed resource events
  - Document manual stack deletion and redeployment procedures for failed automatic rollback
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [ ] 7.1 Create manual rollback buildspec for production
  - Create buildspec-rollback.yml for manual production rollback capability
  - Add environment validation to ensure only production stacks can be rolled back
  - Implement S3 template version retrieval logic to get previous version
  - Add CloudFormation update-stack command with previous template version
  - Include stack update wait and status verification
  - Output rollback completion details and previous version identifier
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ] 7.2 Write property test for rollback buildspec production safety
  - **Property 6: Rollback buildspec targets production only**
  - **Validates: Requirements 7.5**

- [x] 8. Create change management SOP
  - Create docs/sops/change-management.md
  - Document process for proposing infrastructure changes via pull requests
  - Specify required reviews and approvals before merging
  - Document dev-to-prod promotion workflow
  - Specify testing requirements in dev environment before prod deployment
  - Document rollback decision criteria and approval process
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [x] 9. Create release process SOP
  - Create docs/sops/release-process.md
  - Document branch strategy for dev and prod environments
  - Specify pipeline trigger conditions for each environment
  - Document pre-deployment validation steps
  - Specify post-deployment verification procedures
  - Document communication requirements for production releases
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

- [x] 10. Create operations SOP
  - Create docs/sops/operations.md
  - Document daily health check procedures including dashboard review and alarm status verification
  - Specify weekly log review procedures for error patterns and anomalies
  - Document monthly cost review procedures using CloudWatch metrics
  - Specify procedures for monitoring pipeline execution status
  - Document procedures for reviewing CloudFormation stack drift
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [x] 10.1 Write property test for documentation completeness
  - **Property 5: All required documentation files exist**
  - **Validates: Requirements 4.1, 5.1, 6.1, 8.1, 9.1, 10.1, 13.3, 13.4**

- [x] 11. Update buildspec for monitoring stack deployment
  - Update buildspec.yml to upload monitoring template to S3
  - Ensure monitoring template is included in S3 sync command
  - Verify template bucket path matches main.yaml reference
  - _Requirements: 11.1_

- [x] 12. Update TaskCat configuration for monitoring
  - Update .taskcat.yml to include parameters for monitoring stack
  - Verify monitoring stack deploys successfully in test runs
  - _Requirements: 11.1_

- [ ] 13. Checkpoint - Verify monitoring infrastructure deployment
  - Ensure all tests pass, ask the user if questions arise

- [x] 14. Create compliance evidence package
  - Create docs/compliance/ directory for MOB-005 evidence
  - Document CloudFormation template locations
  - Create README explaining evidence artifacts
  - Document how to access CloudWatch dashboards and alarms
  - Provide instructions for capturing dashboard screenshots
  - Document log group locations and sample queries
  - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5_

- [ ] 15. Final checkpoint - Complete MOB-005 compliance verification
  - Ensure all tests pass, ask the user if questions arise
