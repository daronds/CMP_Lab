

resource "aws_security_group" "example" {
  name        = var.security_group_name
  description = "Security group for module example"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.ssh_port
    to_port     = var.ssh_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

resource "aws_subnet" "example" {
  vpc_id            = var.vpc_id
  cidr_block        = var.subnet_cidr
  availability_zone = var.availability_zone
  map_public_ip_on_launch = var.map_public_ip_on_launch
}

resource "aws_instance" "example" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = aws_key_pair.deployer.key_name

  subnet_id              = aws_subnet.example.id
  security_groups        = [aws_security_group.example.name]

  associate_public_ip_address = var.associate_public_ip
  user_data                   = var.user_data
}
