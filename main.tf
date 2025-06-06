resource "aws_instance" "redirector" {
  ami                             = var.ami_id
  instance_type                   = "t2.micro"
  subnet_id                       = aws_subnet.private_subnet.id
  key_name                        = aws_key_pair.internal_keypair.key_name
  vpc_security_group_ids          = [aws_security_group.public_sg.id]
  associate_public_ip_address     = false
# ipv6_address_count              = 1
  tags                            = {
    "Name" = "${var.project_name}-Redirector"
  }

provisioner "remote-exec" {
    inline = [
      "sudo adduser --disabled-password --gecos \"\" bastion",
      "sudo mkdir -p /home/bastion/.ssh",
      "echo '${tls_private_key.key_bastion.public_key_openssh}' | sudo tee /home/bastion/.ssh/authorized_keys",
      "sudo chown -R bastion:bastion /home/bastion/.ssh",
      "sudo chmod 700 /home/bastion/.ssh",
      "sudo chmod 600 /home/bastion/.ssh/authorized_keys"
    ]
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.key1_local_to_bastion.private_key_pem
    host        = self.ipv6_addresses[0]
  }
}

resource "aws_instance" "c2_server" {
  ami                             = var.ami_id
  instance_type                   = "t2.micro"
  subnet_id                       = aws_subnet.private_subnet.id
  key_name                        = aws_key_pair.internal_keypair.key_name
  vpc_security_group_ids          = [aws_security_group.private_sg.id]
  associate_public_ip_address     = false # disable IPv4 public IP
  ipv6_address_count              = 0#1
  tags                            = {
    "Name" = "${var.project_name}-C2-Server"
  }
}

resource "aws_instance" "bastion_host" {
  ami                             = var.ami_id
  instance_type                   = "t2.micro"
  subnet_id                       = aws_subnet.public_subnet.id
  key_name                        = aws_key_pair.bastion_keypair.key_name
  vpc_security_group_ids          = [aws_security_group.bastion_sg.id]
  associate_public_ip_address     = false # disable IPv4 public IP
  ipv6_address_count              = 1
  tags                            = {
    "Name" = "${var.project_name}-Bastion-Host"
  }
  user_data = <<-EOF
              #!/bin/bash
              mkdir -p /home/ubuntu/.ssh
              echo "${tls_private_key.key2_bastion_to_internal.private_key_pem}" > /home/ubuntu/.ssh/internal.pem
              chown ubuntu:ubuntu /home/ubuntu/.ssh/internal.pem
              chmod 400 /home/ubuntu/.ssh/internal.pem
              EOF

}

resource "aws_security_group" "public_sg" {
    description     = "SG for Public Subnet (Redirector and Basiton EC2)"
    name            = "${var.project_name}-Public-SG"
    tags            = {}
    tags_all        = {}
    vpc_id          = aws_vpc.main.id
}

resource "aws_security_group_rule" "public_sg_rules_egress" {
    type                  = "egress"
    security_group_id     = aws_security_group.public_sg.id
    cidr_blocks           = [
      "0.0.0.0/0",
            ]
    description           = ""
    from_port             = 0
    ipv6_cidr_blocks      = [
      "::/0",
    ]
    prefix_list_ids       = []
    protocol              = "-1"
    to_port               = 0
}

resource "aws_security_group_rule" "public_sg_rules_ingress_private_to_public_443" {
  type                        = "ingress"
  source_security_group_id    = aws_security_group.private_sg.id
  security_group_id           = aws_security_group.public_sg.id
  description                 = "Allow HTTPS inbound from private_sg to public_sg"
  from_port                   = 443
  prefix_list_ids             = []
  protocol                    = "tcp" 
  to_port                     = 443
}

resource "aws_security_group_rule" "public_sg_rules_ingress_private_to_public_80"{
  type                        = "ingress"
  source_security_group_id    = aws_security_group.private_sg.id
  security_group_id           = aws_security_group.public_sg.id
  description                 = "Allow HTTP inbound from private_sg to public_sg"
  from_port                   = 80
  prefix_list_ids             = []
  protocol                    = "tcp"
  to_port                     = 80
}

resource "aws_security_group_rule" "public_sg_rules_ingress_ipv6_to_public_443"{
  type                  = "ingress"
  security_group_id     = aws_security_group.public_sg.id            
  cidr_blocks           = []
  description           = "Allow 443 inbound from any IPv6 to public_sg"
  from_port             = 443
  ipv6_cidr_blocks      = [
    "::/0",
  ]
  prefix_list_ids       = []
  protocol              = "tcp"
  to_port               = 443
}

resource "aws_security_group_rule" "public_sg_rules_ingress_bastion_to_public_22"{
  type                        = "ingress"  
  source_security_group_id    = aws_security_group.bastion_sg.id
  security_group_id           = aws_security_group.public_sg.id   
  description                 = "Allow SSH from bastion_sg to public_sg"
  from_port                   = 22
  prefix_list_ids             = []
  protocol                    = "tcp"
  to_port                     = 22
}

resource "aws_security_group_rule" "public_sg_rules_ingress_ipv6_to_public_80"{
  type                = "ingress"
  security_group_id   = aws_security_group.public_sg.id            
  cidr_blocks         = []
  description         = "Allow 80 from any IPv6 to public_sg"
  from_port           = 80
  ipv6_cidr_blocks    = [
    "::/0",
  ]
  prefix_list_ids     = []
  protocol            = "tcp"
  to_port             = 80
}

resource "aws_security_group" "private_sg" {
  description = "SG for Private Subnet (C2)"
  name        = "${var.project_name}-Private-SG"
  tags        = {}
  tags_all    = {}
  vpc_id      = aws_vpc.main.id
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
    }
  ]
}

resource "aws_security_group_rule" "private_sg_rules_ingress_bastion_to_private_50050" {
  source_security_group_id  = aws_security_group.bastion_sg.id            
  security_group_id         = aws_security_group.private_sg.id            
  type                      = "ingress"
  description               = "Allow 50050 inbound from bastion_sg to private_sg (C2 client connecting to C2 server through SSH tunnel set up through Bastion Host"
  from_port                 = 50050
  prefix_list_ids           = []
  protocol                  = "tcp"
  to_port                   = 50050
}

resource "aws_security_group_rule" "private_sg_rules_ingress_public_to_private_443" {
  type                        = "ingress"
  source_security_group_id    = aws_security_group.public_sg.id            
  security_group_id           = aws_security_group.private_sg.id            
  description                 = "Allow 443 inbound from public_sg to private_sg (C2 Traffic from Redirector)"
  from_port                   = 443
  prefix_list_ids             = []
  protocol                    = "tcp"
  to_port                     = 443
}

resource "aws_security_group_rule" "private_sg_rules_ingress_bastion_to_private_22" {
  type                        = "ingress"
  source_security_group_id    = aws_security_group.bastion_sg.id            
  security_group_id           = aws_security_group.private_sg.id            
  description                 = "Allow SSH from bastion_sg to private_sg"
  from_port                   = 22
  prefix_list_ids             = []
  protocol                    = "tcp"
  to_port                     = 22
}

resource "aws_security_group_rule" "private_sg_rules_ingress_private_to_private_allports" {
  security_group_id   = aws_security_group.private_sg.id            
  type                = "ingress"
  description         = "Allow all ports from private_sg to private_sg (Internal traffic w/n Private Subnet"
  from_port           = 0
  prefix_list_ids     = []
  protocol            = "tcp"
  self                = true
  to_port             = 65535
}

resource "aws_security_group" "bastion_sg" {
    description = "For SSH"
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
    name        = "${var.project_name}-Bastion-SG"
    tags        = {}
    tags_all    = {}
    vpc_id      = aws_vpc.main.id 
}

resource "aws_vpc" "main" {
    assign_generated_ipv6_cidr_block     = true
    cidr_block                           = "10.0.0.0/16"
    enable_dns_hostnames                 = true
    enable_dns_support                   = true
    enable_network_address_usage_metrics = false
    instance_tenancy                     = "default"
    ipv6_cidr_block_network_border_group = var.region
    tags                                 = {
        "Name" = "${var.project_name}-vpc"
    }
    tags_all                             = {
        "Name" = "${var.project_name}-vpc"
    }
}

resource "aws_subnet" "public_subnet" {
  assign_ipv6_address_on_creation                 = true
  map_public_ip_on_launch                         = false
  availability_zone                               = var.availability_zone
  cidr_block                                      = "10.0.0.0/20"
  enable_dns64                                    = false
  enable_resource_name_dns_a_record_on_launch     = false
  enable_resource_name_dns_aaaa_record_on_launch  = true
  ipv6_native                                     = false
  private_dns_hostname_type_on_launch             = "ip-name"
  ipv6_cidr_block                                 = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, 0)
  tags                                            = {
    "Name" = "${var.project_name}-public1-${var.region}"
  }
  tags_all                                        = {
    "Name" = "${var.project_name}-public1-${var.region}"
    }
    vpc_id                                        = aws_vpc.main.id 
}

resource "aws_subnet" "private_subnet" {
  availability_zone                               = var.availability_zone
  map_public_ip_on_launch                         = false
  # ipv6_cidr_block                                 = cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, 1)
  assign_ipv6_address_on_creation                 = false
  cidr_block                                      = "10.0.128.0/20"
  enable_dns64                                    = false
  enable_resource_name_dns_a_record_on_launch     = true
  enable_resource_name_dns_aaaa_record_on_launch  = false
  ipv6_native                                     = false
  private_dns_hostname_type_on_launch             = "ip-name"
  tags                                            = {
        "Name" = "${var.project_name}-private1-${var.region}"
    }
    tags_all                                      = {
        "Name" = "${var.project_name}-private1-${var.region}"
    }
    vpc_id                                        = aws_vpc.main.id 
}

resource "tls_private_key" "key1_local_to_bastion" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "bastion_keypair" {
  key_name   = "${var.project_name}-bastion-key"
  public_key = tls_private_key.key1_local_to_bastion.public_key_openssh
}

resource "local_file" "bastion_private_key" {
  content          = tls_private_key.key1_local_to_bastion.private_key_pem
  filename         = "${path.module}/${var.project_name}-bastion.pem"
  file_permission  = "0400"
}

resource "tls_private_key" "key2_bastion_to_internal" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "internal_keypair" {
  key_name   = "${var.project_name}-internal-key"
  public_key = tls_private_key.key2_bastion_to_internal.public_key_openssh
}

resource "local_file" "internal_private_key" {
  content          = tls_private_key.key2_bastion_to_internal.private_key_pem
  filename         = "${path.module}/${var.project_name}-internal.pem"
  file_permission  = "0400"
}
resource "aws_route_table" "public_ipv6_only" {
  vpc_id = aws_vpc.main.id
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.project_name}-public-ipv6-only-route-table"
  }
}

resource "aws_route_table_association" "public_ipv6_only_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_ipv6_only.id
}

resource "aws_route_table" "private_ipv4_only" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-private-ipv4-only-route-table"
  }
}

resource "aws_route_table_association" "private_ipv4_only_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_ipv4_only.id
}
resource "aws_internet_gateway" "gw" {
  vpc_id  = aws_vpc.main.id
  tags    = {
    Name  = "${var.project_name}-main-igw"
  }
}


