# AWS EC2 Provisioning Module

This Terraform module provisions an EC2 instance with an associated security group, SSH key, and subnet within an existing VPC. It is designed to be reusable and customizable for different environments and configurations.

## Features

- **Security Group**: Creates a security group in an existing VPC.
- **SSH Key Pair**: Generates an SSH key pair for EC2 instance access.
- **Subnet**: Adds a subnet to an existing VPC with a specified IP range.
- **EC2 Instance**: Provisions an EC2 instance using the created security group, SSH key, and subnet.

## Usage

To use this module in your Terraform environment, add the module to your configuration and specify the necessary variables:

```hcl
module "ec2_provisioning" {
  source = "path/to/module"

  region                = "us-west-2"
  vpc_id                = "vpc-123abcd"
  security_group_name   = "example-sg"
  ssh_port              = 22
  allowed_cidrs         = ["0.0.0.0/0"]
  key_name              = "ec2-keypair"
  public_key_path       = "path/to/public/key.pub"
  subnet_cidr           = "10.0.1.0/24"
  availability_zone     = "us-west-2a"
  map_public_ip_on_launch = true
  ami_id                = "ami-abc1234"
  instance_type         = "t2.micro"
  associate_public_ip   = true
  user_data             = "#!/bin/bash\necho Hello, World!"
}
