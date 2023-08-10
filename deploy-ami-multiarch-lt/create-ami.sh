#!/usr/bin/env bash

set -eou pipefail

export ENV="production"
export REGION="us-east-1"
export SUBNET_ID="subnet-xxxxxxxxxxxxx"
export VPC_ID="vpc-xxxxxxxxxxxxx"
export SSH_PRIVATE_KEY_FILE="~/.ssh/id_rsa"
export SSH_KEYPAIR_NAME="ec2-keypair"
export SECURITY_GROUP_ID="sg-xxxxxxxxxxxxx"
export IAM_INSTANCE_PROFILE="ec2-iam-role"

TIMESTAMP="$(date +%d%m%Y-%H%M%S)"

export AMI_NAME="application_name-x86_64-$TIMESTAMP"
export SOURCE_AMI_FILTER="amzn2-ami-kernel-*-x86_64-gp2"
export INSTANCE_TYPE="t2.micro"

CHANNEL_NAME="slack_channel_name"
PACKER_GROUP="launch_template_tag"
PACKER_PATH="$HOME/packer-ami-builder/deploy-ami-multiarch-lt/"

###############################################################################
############# Building x86 AMI and Gathering AMI ID & Snapshot ID #############
###############################################################################

packer build $PACKER_PATH/$PACKER_GROUP/packer_x86.json
AMI_ID=$(aws ec2 describe-images --region $REGION --filters "Name=tag:Name,Values=$AMI_NAME" --query 'Images[*].[ImageId]' --output text)
SNAPSHOT_ID=$(aws ec2 describe-images --image-ids $AMI_ID --region $REGION --query 'Images[*].BlockDeviceMappings[*].[Ebs]'| grep SnapshotId | awk -F'"' '{print $4}')
aws sns publish --region $REGION --topic-arn "arn:aws:sns:$REGION:333333333333:sns2slack_$CHANNEL_NAME" --message "$AMI_NAME : $AMI_ID, $SNAPSHOT_ID"
###############################################################################
############ Building arm64 AMI and Gathering AMI ID & Snapshot ID ############
###############################################################################


TIMESTAMP="$(date +%d%m%Y-%H%M%S)"

export AMI_NAME="application_name-arm64-$TIMESTAMP"
export SOURCE_AMI_FILTER="amzn2-ami-kernel-*-arm64-gp2"
export INSTANCE_TYPE="c6g.medium"

packer build $PACKER_PATH/$PACKER_GROUP/packer_arm64.json
AMI_ID=$(aws ec2 describe-images --region $REGION --filters "Name=tag:Name,Values=$AMI_NAME" --query 'Images[*].[ImageId]' --output text)
SNAPSHOT_ID=$(aws ec2 describe-images --image-ids $AMI_ID --region $REGION --query 'Images[*].BlockDeviceMappings[*].[Ebs]'| grep SnapshotId | awk -F'"' '{print $4}')
aws sns publish --region $REGION --topic-arn "arn:aws:sns:$REGION:333333333333:sns2slack_$CHANNEL_NAME" --message "$AMI_NAME : $AMI_ID, $SNAPSHOT_ID"
