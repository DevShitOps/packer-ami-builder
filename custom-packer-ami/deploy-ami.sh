#!/usr/bin/env bash

set -eou pipefail

export ENV="production"
export REGION="us-east-1"
export SUBNET_ID="subnet-xxxxxxxxxxx"
export VPC_ID="vpc-xxxxx"
export SSH_PRIVATE_KEY_FILE="~/.ssh/id_rsa"
export SSH_KEYPAIR_NAME="ec2-keypair"
export SECURITY_GROUP_ID="sg-xxxxxxxxxx"
export IAM_INSTANCE_PROFILE="ec2-iam-role"


TIMESTAMP="$(date +%d%m%Y-%H%M%S)"

export AMI_NAME="packer-patched-ami-x86_64-$TIMESTAMP"
export SOURCE_AMI_FILTER="amzn2-ami-kernel-*-x86_64-gp2"
export INSTANCE_TYPE="t2.micro"
packer build $HOME/packer-ami-builder/custome-packer-ami/packer-x86.json

export AMI_NAME="packer-patched-ami-arm64-$TIMESTAMP"
export SOURCE_AMI_FILTER="amzn2-ami-kernel-*-arm64-gp2"
export INSTANCE_TYPE="c6g.medium"
packer build $HOME/packer-ami-builder/custome-packer-ami/packer-arm64.json
