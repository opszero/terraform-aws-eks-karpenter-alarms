###################################################################################################
# EC2 CPU Utilization Alarms — Dynamic (Karpenter-compatible)
#
# EventBridge fires on every EC2 state change. A Lambda creates a CloudWatch
# CPUUtilization alarm when an instance enters "running" and deletes it on "terminated".
###################################################################################################

resource "aws_iam_role" "ec2_cpu_lambda_role" {
  name = var.iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_cpu_lambda_basic" {
  role       = aws_iam_role.ec2_cpu_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "ec2_cpu_cloudwatch" {
  name = var.iam_policy_name
  role = aws_iam_role.ec2_cpu_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["cloudwatch:PutMetricAlarm", "cloudwatch:DeleteAlarms"]
      Resource = "*"
    }]
  })
}

data "archive_file" "alarm_manager_zip" {
  type        = "zip"
  source_file = "${path.module}/ec2_cpu_alarm_manager.py"
  output_path = "${path.module}/ec2_cpu_alarm_manager.zip"
}

resource "aws_lambda_function" "ec2_cpu_alarm_manager" {
  function_name    = var.lambda_function_name
  role             = aws_iam_role.ec2_cpu_lambda_role.arn
  handler          = "ec2_cpu_alarm_manager.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.alarm_manager_zip.output_path
  source_code_hash = data.archive_file.alarm_manager_zip.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      CPU_THRESHOLD = tostring(var.cpu_threshold)
    }
  }

  lifecycle {
    ignore_changes = [filename]
  }
}

resource "aws_cloudwatch_event_rule" "ec2_state_change" {
  name        = var.event_rule_name
  description = "Fires when any EC2 instance enters running or terminated state"

  event_pattern = jsonencode({
    source        = ["aws.ec2"]
    "detail-type" = ["EC2 Instance State-change Notification"]
    detail = {
      state = ["running", "terminated"]
    }
  })
}

resource "aws_cloudwatch_event_target" "ec2_state_to_lambda" {
  rule = aws_cloudwatch_event_rule.ec2_state_change.name
  arn  = aws_lambda_function.ec2_cpu_alarm_manager.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeEC2StateChange"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_cpu_alarm_manager.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ec2_state_change.arn
}

# Vanta: "Serverless function error rate monitored"
resource "aws_sns_topic" "lambda_errors" {
  name = var.sns_topic_name
}

resource "aws_cloudwatch_metric_alarm" "ec2_cpu_alarm_manager_lambda_errors" {
  alarm_name          = "lambda-errors-${aws_lambda_function.ec2_cpu_alarm_manager.function_name}"
  alarm_description   = "Lambda function errors > 0 in a 5-minute window"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.ec2_cpu_alarm_manager.function_name
  }

  alarm_actions = [aws_sns_topic.lambda_errors.arn]
  ok_actions    = [aws_sns_topic.lambda_errors.arn]
}
