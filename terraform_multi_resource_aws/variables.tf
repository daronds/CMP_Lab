variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "The VPC ID where resources will be created"
  type        = string
  default     = "vpc-0b7d3c84f12cc1ce6"
}

variable "security_group_name" {
  description = "Name of the security group"
  type        = string
  default     = "Terraform Test oparlak"
}

variable "ssh_port" {
  description = "SSH port number"
  default     = 22
}

variable "allowed_cidrs" {
  description = "CIDR blocks allowed access to the instance"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "key_name" {
  description = "Name of the AWS key pair"
  type        = string
  default     = "id_rsa"
}

variable "public_key_path" {
  description = "Path to the public key to be used for the key pair"
  type        = string
  default     = "./id_rsa.pub"
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = string
  default     = "10.133.1.0/24"
}

variable "availability_zone" {
  description = "Availability Zone to create the subnet in"
  type        = string
  default     = "ust-east-1a"
}

variable "map_public_ip_on_launch" {
  description = "Whether to enable auto-assign public IP on subnet"
  default     = true
}

variable "ami_id" {
  description = "AMI ID of the EC2 instance"
  type        = string
  default     = "ami-0b72821e2f351e396"

}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "associate_public_ip" {
  description = "Whether to associate a public IP address with the instance"
  default     = true
}

variable "user_data" {
  description = "User data to initialize instance"
  type        = string
  default     = ""
}
