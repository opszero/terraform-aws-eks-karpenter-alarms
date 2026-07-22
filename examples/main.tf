provider "aws" {
  region = "us-east-1"
}

module "karpentar_ec2_cpu_alarm" {
  source = "./.."

  # Tune the CPU threshold (default: 80%)
  # cpu_threshold = 80

  iam_role_name        = "ec2-cpu-alarm-lambda-role-myclient"
  iam_policy_name      = "ec2-cpu-alarm-cloudwatch-myclient"
  lambda_function_name = "ec2-cpu-alarm-manager-myclient"
  event_rule_name      = "ec2-instance-state-change-for-cpu-alarms-myclient"
  sns_topic_name       = "ec2-cpu-alarm-manager-lambda-errors-myclient"
}