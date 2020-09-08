terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

variable "region" {
  default = "us-west-2"
}

variable "node_size" {
  default = "t2.micro"
}

variable "node_count" {
  default = 1
}

variable "nomad_server_count" {
  default = 1
}

variable "consul_server_count" {
  default = 1
}

variable "subnet" {
  default = "172.31.0.0/20"
}

variable "amis" {
  type = map(string)
  default = {
    "us-east-1" = "ami-03c69f0428e980939"
    "us-east-2" = "ami-0cfc8da67f8bd8679"
    "us-west-1" = "ami-0e5647d579a703dfb"
    "us-west-2" = "ami-0b7d73678141a8bb7"
  }
}

provider "aws" {
  profile = "default"
  region  = var.region
}

# resource "aws_iam_instance_profile" "consul" {
#   role = aws_iam_role.consul.name
# }

# data "aws_iam_policy_document" "consul" {
#   statement {
#     effect = "Allow"

#     actions = [
#       "ec2:DescribeInstances",
#       "ec2:DescribeTags",
#     ]

#     resources = ["*"]
#   }
# }

# resource "aws_iam_role_policy" "consul" {
#   policy = data.aws_iam_policy_document.consul.json
# }

data "template_file" "consul_client" {
  template = file("scripts/consul-client.cloud-init.yaml")
  vars = {
    subnet = var.subnet
  }
}

data "template_file" "consul_server" {
  template = file("scripts/consul-server.cloud-init.yaml")
  vars = {
    consul_server_count = var.consul_server_count
  }
}

data "template_file" "nomad_server" {
  template = file("scripts/nomad-server.cloud-init.yaml")
  vars = {
    nomad_server_count = var.nomad_server_count
  }
}

data "template_cloudinit_config" "node" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "docker.cfg"
    content_type = "text/cloud-config"
    content      = file("scripts/docker.cloud-init.yaml")
  }

  part {
    filename     = "hashicorp.cfg"
    content_type = "text/cloud-config"
    content      = file("scripts/hashicorp.cloud-init.yaml")
  }

  part {
    filename     = "consul-client.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.consul_client.rendered
  }

  part {
    filename     = "nomad-client.cfg"
    content_type = "text/cloud-config"
    content      = file("scripts/nomad-client.cloud-init.yaml")
  }
}

data "template_cloudinit_config" "consul_server" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "hashicorp.cfg"
    content_type = "text/cloud-config"
    content      = file("scripts/hashicorp.cloud-init.yaml")
  }

  part {
    filename     = "consul-server.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.consul_server.rendered
  }
}

data "template_cloudinit_config" "nomad_server" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "hashicorp.cfg"
    content_type = "text/cloud-config"
    content      = file("scripts/hashicorp.cloud-init.yaml")
  }

  part {
    filename     = "nomad-server.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.nomad_server.rendered
  }

  part {
    filename     = "consul-client.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.consul_client.rendered
  }
}

# resource "aws_vpc" "demo" {
#   cidr_block           = "10.0.0.0/16"
#   enable_dns_hostnames = true
#   tags = {
#     Name = "Demo"
#   }
# }

# resource "aws_internet_gateway" "demo" {
#   vpc_id = aws_vpc.demo.id

#   tags = {
#     Name = "Demo"
#   }
# }

# resource "aws_security_group" "demo" {
#   vpc_id = aws_vpc.demo.id

#   ingress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "Demo"
#   }
# }

# resource "aws_subnet" "demo" {
#   vpc_id                  = aws_vpc.demo.id
#   cidr_block              = var.subnet
#   map_public_ip_on_launch = true

#   tags = {
#     Name = "Demo"
#   }
# }

resource "aws_key_pair" "demo" {
  key_name   = "demo"
  public_key = file("keys/node_system.pub")
}

resource "aws_instance" "node" {
  count         = var.node_count
  ami           = var.amis[var.region]
  instance_type = var.node_size

  key_name = aws_key_pair.demo.key_name

  # subnet_id        = aws_subnet.demo.id
  user_data_base64 = data.template_cloudinit_config.node.rendered

  # vpc_security_group_ids = [aws_security_group.demo.id]

  tags = {
    Name          = "Node ${count.index}"
    compute       = true
    consul_client = true
    nomad_client  = true
  }
}

resource "aws_instance" "nomad_server" {
  count         = var.nomad_server_count
  ami           = var.amis[var.region]
  instance_type = var.node_size

  key_name = aws_key_pair.demo.key_name

  # subnet_id        = aws_subnet.demo.id
  user_data_base64 = data.template_cloudinit_config.nomad_server.rendered

  # vpc_security_group_ids = [aws_security_group.demo.id]

  tags = {
    Name          = "Nomad ${count.index}"
    compute       = false
    consul_client = true
    nomad_server  = true
  }
}

resource "aws_instance" "consul_server" {
  count         = var.consul_server_count
  ami           = var.amis[var.region]
  instance_type = var.node_size

  key_name = aws_key_pair.demo.key_name

  # subnet_id        = aws_subnet.demo.id
  user_data_base64 = data.template_cloudinit_config.consul_server.rendered

  # vpc_security_group_ids = [aws_security_group.demo.id]

  tags = {
    Name          = "Consul ${count.index}"
    compute       = false
    consul_server = true
  }
}
