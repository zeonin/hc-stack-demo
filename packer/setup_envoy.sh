#!/bin/sh
set -e

# Environment variables are set by packer
curl -L https://getenvoy.io/cli | sudo bash -s -- -b /usr/local/bin

getenvoy run "standard:${ENVOY_VERSION}" -- --version

sudo cp "${HOME}/.getenvoy/builds/standard/${ENVOY_VERSION}/linux_glibc/bin/envoy" /usr/local/bin/

