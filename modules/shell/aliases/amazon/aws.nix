{
  config,
  pkgs,
  lib,
  ...
}:

# ============================================================
# AWS (Amazon Web Services) Aliases
# ============================================================

{
  environment.shellAliases = {
    # AWS Identity & Configuration
    "aws-check" = "aws sts get-caller-identity";
    "aws-whoami" = "aws sts get-caller-identity";
    "aws-profile" = "aws s3 ls --profile";
    "aws-config" = "aws configure --profile";
    "aws-config-list" = "aws configure list";
    "aws-profiles" = "cat ~/.aws/credentials | grep '\\[' | tr -d '[]'";

    # AWS EC2
    "aws-ec2-list" =
      "aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType,PublicIpAddress,Tags[?Key==`Name`].Value|[0]]' --output table";
    "aws-ec2-running" =
      "aws ec2 describe-instances --filters 'Name=instance-state-name,Values=running' --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,PublicIpAddress,Tags[?Key==`Name`].Value|[0]]' --output table";
    "aws-ec2-stop" = "aws ec2 stop-instances --instance-ids";
    "aws-ec2-start" = "aws ec2 start-instances --instance-ids";
    "aws-ec2-terminate" = "aws ec2 terminate-instances --instance-ids";

    # AWS S3
    "aws-s3-buckets" = "aws s3 ls";
    "aws-s3-size" = "aws s3 ls --summarize --human-readable --recursive s3://";
    "aws-s3-sync-down" = "aws s3 sync s3://";
    "aws-s3-sync-up" = "aws s3 sync . s3://";

    # AWS Lambda
    "aws-lambda-list" =
      "aws lambda list-functions --query 'Functions[*].[FunctionName,Runtime,LastModified]' --output table";
    "aws-lambda-logs" = "aws logs tail /aws/lambda/";

    # AWS ECS
    "aws-ecs-clusters" = "aws ecs list-clusters --output table";
    "aws-ecs-services" = "aws ecs list-services --cluster";
    "aws-ecs-tasks" = "aws ecs list-tasks --cluster";

    # AWS RDS
    "aws-rds-list" =
      "aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,Engine,DBInstanceClass]' --output table";

    # AWS CloudWatch Logs
    "aws-logs-groups" =
      "aws logs describe-log-groups --query 'logGroups[*].logGroupName' --output table";
    "aws-logs-tail" = "aws logs tail --follow";

    # AWS Cost
    "aws-cost-today" =
      "aws ce get-cost-and-usage --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) --granularity MONTHLY --metrics BlendingCost";

    # AWS SSM (Session Manager)
    "aws-ssm-start" = "aws ssm start-session --target";
    "aws-ssm-list" =
      "aws ec2 describe-instances --query 'Reservations[*].Instances[?State.Name==`running`].[InstanceId,Tags[?Key==`Name`].Value|[0]]' --output table";
  };
}
