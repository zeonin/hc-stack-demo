#!/usr/bin/env bash
#
# PREREQUISITES: openssh, packer, nomad, terraform, 

# Generates an ssh keypair with no passphrase
function generate_ssh_key() {
    ssh-keygen -t rsa -f keys/node_system -N ""

    # Set permissions on the private key
    chmod 400 keys/node_system
}

# Builds an AMI suitable for a cluster demo base image
function build_ami() {
    packer build packer/nomad-consul-docker.json
}

# Sets up and deploys the cluster infrastructure using terraform
function tf_apply() {
    # Generate the ssh key to be used
    generate_ssh_key

    # Initialize terraform
    terraform init

    # Apply the configuration
    terraform apply $@
}

# $1: Local port to test
# Returns 0 (true) if something is listening on the specified port and
#   1 (false) otherwise
function test_port() {
    # Bash can natively open TCP connections
    exec 6<>/dev/tcp/127.0.0.1/445

    retval=$?

    exec 6>&- # close output connection
    exec 6<&- # close input connection

    return $retval
}

# Prereq: SSH tunnel to one of the nomad nodes. Assuming port 4646 if
# NOMAD_PORT is not provided.
function install_apps() {
    port=${NOMAD_PORT:-4646}

    test_port $NOMAD_PORT

    if [[ $? -ne 0 ]]; then
	echo 'Unable to connect to nomad' >&2
	echo "Try `ssh -i keys/node_system -L ${port}:127.0.0.1:${port} ubuntu@<NOMAD_CLIENT_IP>`" >&2
	exit 1
    fi

    echo "Deploying redis..."
    nomad run ./nomad/redis.nomad

    echo "Deploying voter app..."
    nomad run ./nomad/voter.nomad
}

case "$1" in
    sshkey)
        generate_ssh_key
        ;;
    ami)
        build_ami
        ;;
    terraform)
        shift
        tf_apply
        ;;
    install)
        install_apps
        ;;
    *)
        echo "Usage:"
        echo "  sshkey      - Generate an SSH keypair for use with the deployment"
        echo "  ami         - Build an AMI image using packer containing Nomad, Consul, and Envoy"
        echo "  terraform   - Apply the terraform configuration to spin up a 3 client, 1 server Nomad/Consul Cluster"
        echo "  install     - Install the redis and voter applications to Nomad"
esac

