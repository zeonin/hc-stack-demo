# Require tf>=0.12 and aws provider
terraform {
  required_version = ">= 0.12"
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# Set up AWS
provider "aws" {
  profile = "default"
  region  = var.region
}

# AMI used for development
variable "amis" {
  type = map(string)
  default = {
    "us-west-2" = "ami-0873c8e215c8c561d"
  }
}

resource "aws_key_pair" "demo" {
  key_name   = "demo"
  public_key = file("keys/node_system.pub")
}

module "nomad_cluster" {
  # Use version v0.6.5 of the nomad-cluster module.
  #
  # NOTE: This repo-root module is only intended for
  # dev/experimenting. It should use the modules/nomad-cluster module
  # for prod (possibly with a dedicated consul cluster)
  source = "github.com/hashicorp/terraform-aws-nomad?ref=v0.6.5"

  ami_id = var.ami == null ? var.amis[var.region] : var.ami

  num_servers = 1
  num_clients = 3

  ssh_key_name = aws_key_pair.demo.key_name

  cluster_name = "demo"
}

# Allow all clients to connect to each other on all ports
resource "aws_security_group_rule" "client_firewall_exception" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = module.nomad_cluster.security_group_id_clients
  security_group_id        = module.nomad_cluster.security_group_id_clients
}

# Allow all servers to connect to the clients on all ports
# NOTE: This may not be needed
resource "aws_security_group_rule" "server_firewall_exception" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = module.nomad_cluster.security_group_id_servers
  security_group_id        = module.nomad_cluster.security_group_id_clients
}

# Allow web traffic to the clients
resource "aws_security_group_rule" "client_firewall_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.nomad_cluster.security_group_id_clients
}
