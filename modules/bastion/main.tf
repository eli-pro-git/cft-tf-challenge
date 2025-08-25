# Find a recent Amazon Linux 2 AMI (x86_64) maintained by AWS
data "aws_ami" "amazon_linux2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux2.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.sg_id]
  key_name               = var.key_name

  # Ensure it definitely gets a public IP in the public subnet
  associate_public_ip_address = true

  tags = merge(var.tags, {
    Name = "${lookup(var.tags, "Project", "proj")}-${lookup(var.tags, "Environment", "env")}-bastion"
    Role = "bastion"
  })
}
