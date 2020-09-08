#!/usr/bin/env nix-shell
#!nix-shell -i bash -p openssh

# Generate an ssh keypair with no passphrase
ssh-keygen -t rsa -f keys/node_system -N ""

# Set permissions on the private key
chmod 400 keys/node_system
