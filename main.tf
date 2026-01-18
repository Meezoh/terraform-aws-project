# ---------------------------------------------
# NETWORKING: VPC
# ---------------------------------------------
resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}

# ---------------------------------------------
# NETWORKING: Subnet
# ---------------------------------------------
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidr

  tags = {
    Name = "Main"
  }
}

# ---------------------------------------------
# NETWORKING: Internet Gateway
# ---------------------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

# ---------------------------------------------
# NETWORKING: Route Table
# ---------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

# Route: anywhere on the internet -> Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

# ---------------------------------------------
# NETWORKING: Route Table Association (Attach the route table to the subnet)
# ---------------------------------------------
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ------------------------------------------------------------
# NETWORKING: Security Group (EC2 SSH only)
# ------------------------------------------------------------
# Security Group shell
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Allow SSH from bastion server only"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "ec2-sg"
  }
}

# ------------------------------------------------------------
# NETWORKING: Security Group Ingress (SSH from your Linux server public IP)
# ------------------------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "ssh_from_my_server" {
  security_group_id = aws_security_group.ec2_sg.id

  description = "SSH from server"
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"

  # Server's public IP
  cidr_ipv4 = "18.223.126.35/32"
}

# ------------------------------------------------------------
# NETWORKING: Security Group Egress (Allow all outbound traffic)
# ------------------------------------------------------------
resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.ec2_sg.id

  description = "Allow all outbound traffic"
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

# ------------------------------------------------------------
# COMPUTE: EC2 Instance (Public, SSH enabled)
# ------------------------------------------------------------
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "tf-server"
  }
}