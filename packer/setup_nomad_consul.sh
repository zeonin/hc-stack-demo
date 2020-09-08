#!/bin/sh
set -e

# Environment variables are set by packer
git clone --branch "${NOMAD_MODULE_VERSION}"  https://github.com/hashicorp/terraform-aws-nomad.git /tmp/terraform-aws-nomad
/tmp/terraform-aws-nomad/modules/install-nomad/install-nomad --version "${NOMAD_VERSION}"

git clone --branch "${CONSUL_MODULE_VERSION}"  https://github.com/hashicorp/terraform-aws-consul.git /tmp/terraform-aws-consul
/tmp/terraform-aws-consul/modules/install-consul/install-consul --version "${CONSUL_VERSION}"

echo '{"ports":{"grpc":8502},"connect":{"enabled":true}}' | sudo tee /opt/consul/config/enable-connect.json

# Set up CNI plugins
curl -L -o cni-plugins.tgz https://github.com/containernetworking/plugins/releases/download/v0.8.6/cni-plugins-linux-amd64-v0.8.6.tgz

sudo mkdir -p /opt/cni/bin

sudo tar -C /opt/cni/bin -xzf cni-plugins.tgz

# Setup routing
echo -e 'net.bridge.bridge-nf-call-arptables = 1\n
net.bridge.bridge-nf-call-ip6tables = 1\n
net.bridge.bridge-nf-call-iptables = 1\n' | sudo tee /etc/sysctl.d/99-setup-envoy-routing.conf


