output "redirector_public_ip" {
  description = "Public IP of the redirector"
  value       = aws_instance.redirector.public_ip
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = aws_instance.bastion_host.public_ip
}

output "c2_private_ip" {
  description = "Private IP of the C2 server"
  value       = aws_instance.c2_server.private_ip
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = [aws_subnet.bastion_subnet.id, aws_subnet.redirector_subnet.id]
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = [aws_subnet.c2_subnet.id]
}

