# terraform-aws-eks-karpenter-alarms

Terraform module that provisions dynamic CloudWatch CPU alarms for EC2 instances managed by Karpenter.

An EventBridge rule watches for EC2 state-change events. A Lambda function creates a `CPUUtilization` alarm when an instance enters `running` state and deletes it on `terminated` — so alarms always match the live set of Karpenter nodes without any manual intervention.

## Alarms created

| Alarm | Metric | Condition |
|---|---|---|
| EC2 CPU utilization (per instance) | CPUUtilization | avg > threshold% for 10 min |
| Lambda errors | Lambda Errors | > 0 in 5 min |

## Usage

```hcl
module "karpentar-ec2-cpu-alarm" {
  source = "git::git@github.com:opszero/terraform-aws-eks-karpenter-alarms.git"
}
```

With custom threshold:

```hcl
module "karpentar-ec2-cpu-alarm" {
  source        = "git::git@github.com:opszero/terraform-aws-eks-karpenter-alarms.git"
  cpu_threshold = 75
}
```

## Multi-client usage

Override the naming variables so multiple clients can share the same AWS account without resource name conflicts:

```hcl
module "karpentar-ec2-cpu-alarm" {
  source = "git::git@github.com:opszero/terraform-aws-eks-karpenter-alarms.git"

  cpu_threshold        = 80
  iam_role_name        = "ec2-cpu-alarm-lambda-role-acme"
  iam_policy_name      = "ec2-cpu-alarm-cloudwatch-acme"
  lambda_function_name = "ec2-cpu-alarm-manager-acme"
  event_rule_name      = "ec2-instance-state-change-for-cpu-alarms-acme"
  sns_topic_name       = "ec2-cpu-alarm-manager-lambda-errors-acme"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| cpu_threshold | CPU utilization percentage threshold to trigger the alarm | `number` | `80` | no |
| iam_role_name | Name for the Lambda IAM role. Override per client to avoid conflicts | `string` | `"ec2-cpu-alarm-lambda-role"` | no |
| iam_policy_name | Name for the inline CloudWatch policy attached to the Lambda role. Override per client | `string` | `"ec2-cpu-alarm-cloudwatch"` | no |
| lambda_function_name | Name for the Lambda function. Override per client to avoid conflicts | `string` | `"ec2-cpu-alarm-manager"` | no |
| event_rule_name | Name for the EventBridge rule. Override per client to avoid conflicts | `string` | `"ec2-instance-state-change-for-cpu-alarms"` | no |
| sns_topic_name | Name for the SNS topic used for Lambda error alerts. Override per client | `string` | `"ec2-cpu-alarm-manager-lambda-errors"` | no |

## Outputs

| Name | Description |
|---|---|
| lambda_function_name | Name of the EC2 CPU alarm manager Lambda function |
| sns_topic_arn | ARN of the SNS topic used for Lambda error alerts |
| event_rule_arn | ARN of the EventBridge rule watching EC2 state changes |

## Support

<a href="https://opszero.com"><img src="https://opszero.com/img/common/opsZero-Logo-Large.webp" width="300px"/></a>

[opsZero provides support](https://www.opszero.com/devops) for our modules including:

- Slack & Email support
- One on One Video Calls
- Implementation Guidance

## License

Apache 2 © [OpsZero](https://opszero.com)
