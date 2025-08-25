# SNS Topic for alerts
resource "aws_sns_topic" "alerts" {
  name = "${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-alerts"
  tags = var.tags
}

# Optional email subscription (must be confirmed by the recipient)
resource "aws_sns_topic_subscription" "email" {
  count     = length(var.alerts_email) > 0 ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alerts_email
}

# Alarm: ASG InService instances below 2 (threshold can be tuned)
resource "aws_cloudwatch_metric_alarm" "asg_inservice_low" {
  alarm_name          = "${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-asg-inservice-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  threshold           = 2
  metric_name         = "GroupInServiceInstances"
  namespace           = "AWS/AutoScaling"
  period              = 60
  statistic           = "Minimum"
  treat_missing_data  = "breaching"
  alarm_description   = "ASG in-service instances dropped below 2"

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# Alarm: Bastion EC2 status checks failing
resource "aws_cloudwatch_metric_alarm" "bastion_status_check_failed" {
  alarm_name          = "${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-bastion-statuscheck"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  treat_missing_data  = "notBreaching"
  alarm_description   = "Bastion instance status check failed"

  dimensions = {
    InstanceId = var.bastion_instance_id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# Alarm: Bastion CPU high (sustained)
resource "aws_cloudwatch_metric_alarm" "bastion_cpu_high" {
  alarm_name          = "${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-bastion-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  threshold           = 80
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  treat_missing_data  = "notBreaching"
  alarm_description   = "Bastion CPU > 80% for 3 minutes"

  dimensions = {
    InstanceId = var.bastion_instance_id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}
