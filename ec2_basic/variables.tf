variable "owner" {
  type = string
  default = "newuser"
}

variable "group" {
  type = string
  default = "IT"
}

variable "ami_id" {
  type = string
  default = "ami-08a0d1e16fc3f61ea"
}

variable "instance_type" {
  type = string
  default = "t3.micro"
}

variable "ec2_name" {
  type = string
  default = "ec2-tst-001"
}

variable "subnet_id" {
  type = string
  default = "subnet-0f74c2154f72de224"
}

variable "associate_public_ip_address" {
  type = bool
  default = false
}

variable "security_group_id" {
  type    = string
  default = "sg-0cfdbee0872e762ab"
}
