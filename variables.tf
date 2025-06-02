variable "project_name" {
  description = "Prefix for all named AWS resources"
  type        = string
}

variable "region" {
  description = "AWS region for deployment"
  type        = string
}

variable "availability_zone" {
  description = "Specific availability zone for subnets and instances"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH key name for EC2 access"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.10.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "10.10.2.0/24"
}

variable "ipv6_border_group" {
  description = "IPv6 network border group (usually matches region)"
  type        = string
}
variable "profile" {
  description = "AWS CLI profile to use"
  type        = string
}

