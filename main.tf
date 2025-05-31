resource "aws_instance" "redirector" {
  ami                                  = "ami-0cb91c7de36eed2cb"
  instance_type                        = "t2.micro"
  subnet_id                            = "subnet-0fc0eac71d712c09f"
  key_name                             = "redirector-key"
  vpc_security_group_ids               = ["sg-023e4f2beafa49b3b"]
  tags                                 = {
        "Name" = "Redirector"
    }
}

resource "aws_instance" "c2_server" {
  ami                                 = "ami-0cb91c7de36eed2cb"
  instance_type                       = "t2.micro"
  subnet_id                           = "subnet-0bc464702a0e1f783"
  key_name                            = "c2-key"
  vpc_security_group_ids              = ["sg-0f0cf32e4a8119c8a"]
  tags                                = {
        "Name" = "C2-Server"
    }
}

resource "aws_instance" "bastion_host" {
  ami                                 = "ami-0cb91c7de36eed2cb"
  instance_type                       = "t2.micro"
  subnet_id                           = "subnet-0fc0eac71d712c09f"
  key_name                            = "bastion-key"
  vpc_security_group_ids              = ["sg-001dbbdd4a6e8b737"]
  tags                                = {
        "Name" = "Bastion-Host"
    }
}

resource "aws_security_group" "redirector_sg" {
    description = "Allow HTTP(S) inbound from anywhere."
    egress      = [
        {
            cidr_blocks      = [
                "0.0.0.0/0",
            ]
            description      = ""
            from_port        = 0
            ipv6_cidr_blocks = [
                "::/0",
            ]
            prefix_list_ids  = []
            protocol         = "-1"
            security_groups  = []
            self             = false
            to_port          = 0
        },
    ]
    ingress     = [
        {
            cidr_blocks      = []
            description      = ""
            from_port        = 443
            ipv6_cidr_blocks = []
            prefix_list_ids  = []
            protocol         = "tcp"
            security_groups  = [
                "sg-0f0cf32e4a8119c8a",
            ]
            self             = false
            to_port          = 443
        },
        {
            cidr_blocks      = []
            description      = ""
            from_port        = 80
            ipv6_cidr_blocks = []
            prefix_list_ids  = []
            protocol         = "tcp"
            security_groups  = [
                "sg-0f0cf32e4a8119c8a",
            ]
            self             = false
            to_port          = 80
        },
        {
            cidr_blocks      = []
            description      = "C2 Traffic and payloads for SSL traffic"
            from_port        = 443
            ipv6_cidr_blocks = [
                "::/0",
            ]
            prefix_list_ids  = []
            protocol         = "tcp"
            security_groups  = []
            self             = false
            to_port          = 443
        },
        {
            cidr_blocks      = []
            description      = "SSH from Bastion"
            from_port        = 22
            ipv6_cidr_blocks = []
            prefix_list_ids  = []
            protocol         = "tcp"
            security_groups  = [
                "sg-001dbbdd4a6e8b737",
            ]
            self             = false
            to_port          = 22
        },
        {
            cidr_blocks      = []
            description      = "Used for phishing landing pages"
            from_port        = 80
            ipv6_cidr_blocks = [
                "::/0",
            ]
            prefix_list_ids  = []
            protocol         = "tcp"
            security_groups  = []
            self             = false
            to_port          = 80
        },
    ]
    name        = "Public-SG"
    tags        = {}
    tags_all    = {}
    vpc_id      = "vpc-02ec25b78157e3222"
}

resource "aws_security_group" "c2_server_sg" {
    description = "For C2, RedELK, Phishing, Payload Server"
    egress      = [
        {
            cidr_blocks      = [
                "0.0.0.0/0",
            ]
            description      = ""
            from_port        = 0
            ipv6_cidr_blocks = [
                "::/0",
            ]
            prefix_list_ids  = []
            protocol         = "-1"
            security_groups  = []
            self             = false
            to_port          = 0
        },
    ]
    ingress     = [
        {
            cidr_blocks      = []
            description      = "Allow Cobalt Strike client to connect through SSH tunnel"
            from_port        = 50050
            ipv6_cidr_blocks = []
            prefix_list_ids  = []
            protocol         = "tcp"
            security_groups  = [
                "sg-001dbbdd4a6e8b737",
            ]
            self             = false
            to_port          = 50050
        },
        {
            cidr_blocks      = []
            description      = "C2 Traffic from Redirector"
            from_port        = 443
            ipv6_cidr_blocks = []
            prefix_list_ids  = []
            protocol         = "tcp"
            security_groups  = [
                "sg-023e4f2beafa49b3b",
            ]
            self             = false
            to_port          = 443
        },
        {
            cidr_blocks      = []
            description      = "From Bastion-SG only"
            from_port        = 22
            ipv6_cidr_blocks = []
            prefix_list_ids  = []
            protocol         = "tcp"
            security_groups  = [
                "sg-001dbbdd4a6e8b737",
            ]
            self             = false
            to_port          = 22
        },
        {
            cidr_blocks      = []
            description      = "Internal traffic b/n servers"
            from_port        = 0
            ipv6_cidr_blocks = []
            prefix_list_ids  = []
            protocol         = "tcp"
            security_groups  = []
            self             = true
            to_port          = 65535
        },
    ]
    name        = "Private-SG"
    tags        = {}
    tags_all    = {}
    vpc_id      = "vpc-02ec25b78157e3222"
}

resource "aws_security_group" "bastion_sg" {
    description = "For SSH via Cloudflare"
    egress      = [
        {
            cidr_blocks      = [
                "0.0.0.0/0",
            ]
            description      = ""
            from_port        = 0
            ipv6_cidr_blocks = [
                "::/0",
            ]
            prefix_list_ids  = []
            protocol         = "-1"
            security_groups  = []
            self             = false
            to_port          = 0
        },
    ]
    ingress     = [
        {
            cidr_blocks      = []
            description      = "SSH from anywhere"
            from_port        = 22
            ipv6_cidr_blocks = [
                "::/0",
            ]
            prefix_list_ids  = []
            protocol         = "tcp"
            security_groups  = []
            self             = false
            to_port          = 22
        },
    ]
    name        = "Bastion-SG"
    tags        = {}
    tags_all    = {}
    vpc_id      = "vpc-02ec25b78157e3222"
}
resource "aws_vpc" "main" {
    assign_generated_ipv6_cidr_block     = true
    cidr_block                           = "10.0.0.0/16"
    enable_dns_hostnames                 = true
    enable_dns_support                   = true
    enable_network_address_usage_metrics = false
    instance_tenancy                     = "default"
    ipv6_cidr_block_network_border_group = "us-east-2"
    tags                                 = {
        "Name" = "TestVPC-vpc"
    }
    tags_all                             = {
        "Name" = "TestVPC-vpc"
    }
}

resource "aws_subnet" "redirector_subnet" {
    assign_ipv6_address_on_creation                = true
    availability_zone                              = "us-east-2a"
    cidr_block                                     = "10.0.0.0/20"
    enable_dns64                                   = false
    enable_resource_name_dns_a_record_on_launch    = false
    enable_resource_name_dns_aaaa_record_on_launch = false
    ipv6_cidr_block                                = "2600:1f16:610:4800::/56"
    ipv6_native                                    = false
    map_public_ip_on_launch                        = false
    private_dns_hostname_type_on_launch            = "ip-name"
    tags                                           = {
        "Name" = "TestVPC-subnet-public1-us-east-2a"
    }
    tags_all                                       = {
        "Name" = "TestVPC-subnet-public1-us-east-2a"
    }
    vpc_id                                         = "vpc-02ec25b78157e3222"
}
resource "aws_subnet" "c2_subnet" {
    availability_zone                              = "us-east-2a"
    cidr_block                                     = "10.0.128.0/20"
    enable_dns64                                   = false
    enable_resource_name_dns_a_record_on_launch    = false
    enable_resource_name_dns_aaaa_record_on_launch = false
    ipv6_native                                    = false
    map_public_ip_on_launch                        = true
    private_dns_hostname_type_on_launch            = "ip-name"
    tags                                           = {
        "Name" = "TestVPC-subnet-private1-us-east-2a"
    }
    tags_all                                       = {
        "Name" = "TestVPC-subnet-private1-us-east-2a"
    }
    vpc_id                                         = "vpc-02ec25b78157e3222"
}
resource "aws_subnet" "bastion_subnet" {
    assign_ipv6_address_on_creation                = true
    availability_zone                              = "us-east-2a"
    cidr_block                                     = "10.0.0.0/20"
    enable_dns64                                   = false
    enable_resource_name_dns_a_record_on_launch    = false
    enable_resource_name_dns_aaaa_record_on_launch = false
    ipv6_cidr_block                                = "2600:1f16:610:4800::/56"
    ipv6_native                                    = false
    map_public_ip_on_launch                        = false
    private_dns_hostname_type_on_launch            = "ip-name"
    tags                                           = {
        "Name" = "TestVPC-subnet-public1-us-east-2a"
    }
    tags_all                                       = {
        "Name" = "TestVPC-subnet-public1-us-east-2a"
    }
    vpc_id                                         = "vpc-02ec25b78157e3222"

}

