variable "cpu_threshold" {
  type        = number
  default     = 80
  description = "CPU utilization percentage threshold to trigger the alarm."
}

variable "iam_role_name" {
  type        = string
  description = "Name for the Lambda IAM role. Override per client to avoid conflicts."
  default     = "ec2-cpu-alarm-lambda-role"
}

variable "iam_policy_name" {
  type        = string
  description = "Name for the inline CloudWatch policy attached to the Lambda role. Override per client."
  default     = "ec2-cpu-alarm-cloudwatch"
}

variable "lambda_function_name" {
  type        = string
  description = "Name for the Lambda function. Override per client to avoid conflicts."
  default     = "ec2-cpu-alarm-manager"
}

variable "event_rule_name" {
  type        = string
  description = "Name for the EventBridge rule. Override per client to avoid conflicts."
  default     = "ec2-instance-state-change-for-cpu-alarms"
}

variable "sns_topic_name" {
  type        = string
  description = "Name for the SNS topic used for Lambda error alerts. Override per client."
  default     = "ec2-cpu-alarm-manager-lambda-errors"
}
