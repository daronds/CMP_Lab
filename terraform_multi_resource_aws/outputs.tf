output "security_group_id" {
  value = aws_security_group.example.id
}

output "subnet_id" {
  value = aws_subnet.example.id
}

output "instance_id" {
  value = aws_instance.example.id
}
