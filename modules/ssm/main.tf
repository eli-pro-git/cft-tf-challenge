# IAM role for EC2 to use SSM Session Manager
data "aws_iam_policy" "ssm_core" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role" "ssm_role" {
  name = "${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-ssm-role"

  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [{
      Effect : "Allow",
      Principal : { Service : "ec2.amazonaws.com" },
      Action : "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "attach_ssm_core" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = data.aws_iam_policy.ssm_core.arn
}

# Instance profile that EC2 instances/launch templates can attach
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-ssm-profile"
  role = aws_iam_role.ssm_role.name
}
