output "lambda_function_name" {
  value       = aws_lambda_function.ec2_cpu_alarm_manager.function_name
  description = "Name of the EC2 CPU alarm manager Lambda function."
}

output "sns_topic_arn" {
  value       = aws_sns_topic.lambda_errors.arn
  description = "ARN of the SNS topic used for Lambda error alerts."
}

output "event_rule_arn" {
  value       = aws_cloudwatch_event_rule.ec2_state_change.arn
  description = "ARN of the EventBridge rule watching EC2 state changes."
}
