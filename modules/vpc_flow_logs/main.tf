# Log group for VPC flow logs
resource "aws_cloudwatch_log_group" "vpc_fl" {
  name              = "/vpc/${lookup(var.tags, "Project", "proj")}/${lookup(var.tags, "Environment", "env")}/flow-logs"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# IAM role that VPC Flow Logs service will assume to write to CWL
resource "aws_iam_role" "flow_logs_role" {
  name = "${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-vpc-flowlogs-role"

  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [{
      Effect : "Allow",
      Principal : { Service : "vpc-flow-logs.amazonaws.com" },
      Action : "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

# Permissions to publish logs
resource "aws_iam_role_policy" "flow_logs_policy" {
  name = "${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-vpc-flowlogs-policy"
  role = aws_iam_role.flow_logs_role.id

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [{
      Effect   : "Allow",
      Action   : [
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      Resource : "${aws_cloudwatch_log_group.vpc_fl.arn}:*"
    }]
  })
}

# Enable VPC Flow Logs
resource "aws_flow_log" "vpc" {
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.vpc_fl.arn
  iam_role_arn         = aws_iam_role.flow_logs_role.arn
  traffic_type         = var.traffic_type
  vpc_id               = var.vpc_id

  # 10 min aggregation gives fewer events & lower cost (valid: 60 or 600)
  max_aggregation_interval = 600

  tags = merge(var.tags, {
    Name = "${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-vpc-flowlogs"
  })
}
