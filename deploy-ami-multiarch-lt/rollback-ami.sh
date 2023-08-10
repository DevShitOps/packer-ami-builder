#!/usr/bin/env bash

set -eou pipefail

REGION="us-east-1"
ASG="autoscaling_group_name"
LTNAME="launch_template_name-x86_64"
CHANNEL_NAME="slack_channel_name"
PACKER_GROUP="launch_template_tag"
PACKER_PATH="$HOME/packer-ami-builder/deploy-ami-multiarch-lt/"
S3_BACKEND_PATH="packer-ami/application_name"

AMI_ID_X86=$1
SNAPSHOT_ID_X86=$2

###############################################################################
###################### Deploying AMI in Launch Template #######################
###############################################################################

cd $PACKER_PATH/update-lt-tf-code-x86
aws sns publish --region $REGION --topic-arn "arn:aws:sns:$REGION:333333333333:sns2slack_$CHANNEL_NAME" --message "♻️  ♻️ Initializing Terraform and Planning Changes on $LTNAME in $REGION ♻️  ♻️ "
rm -rf .terraform*
terraform init -backend-config key="$S3_BACKEND_PATH/$PACKER_GROUP/$LTNAME.tfstate"
terraform plan -var ami_id="$AMI_ID" -var snapshot_id="$SNAPSHOT_ID" -var launch_template_name="$LTNAME" -var packer_group="$PACKER_GROUP"

if [[ "$?" -ne "0" ]]; then
	break
else
	aws sns publish --region $REGION --topic-arn "arn:aws:sns:$REGION:333333333333:sns2slack_$CHANNEL_NAME" --message "♻️  ♻️  Terraform is Applying Changes ♻️  ♻️ "
	message=$(terraform apply -var ami_id="$AMI_ID" -var snapshot_id="$SNAPSHOT_ID" -var launch_template_name="$LTNAME" -var packer_group="$PACKER_GROUP" -auto-approve | grep "Apply complete")
	aws sns publish --region $REGION --topic-arn "arn:aws:sns:$REGION:333333333333:sns2slack_$CHANNEL_NAME" --message "♻️  ♻️  $message ♻️  ♻️ "
fi


###############################################################################
############ Building arm64 AMI and Gathering AMI ID & Snapshot ID ############
###############################################################################

TIMESTAMP="$(date +%d%m%Y-%H%M%S)"

export AMI_NAME="application_name-arm64-$TIMESTAMP"
export SOURCE_AMI_FILTER="amzn2-ami-kernel-*-arm64-gp2"
export INSTANCE_TYPE="c6g.medium"

LTNAME="launch_template_name-arm64"
LTID="lt-0ec08a9ea7f8d7eef"

LT_LatestVersionNumber=$(aws ec2 describe-launch-template-versions --launch-template-id $LTID | awk -F ': ' '/VersionNumber/ {print $NF}' | head -1 | tr -d ',')
BackupAMIandSnapshotID=$(aws ec2 describe-launch-template-versions --launch-template-id $LTID --versions $LT_LatestVersionNumber | grep -E "ImageId|SnapshotId")
aws sns publish --region $REGION --topic-arn "arn:aws:sns:$REGION:333333333333:sns2slack_$CHANNEL_NAME" --message "⏩ ⏩ Backup AMI and Snapshot ID of $LTNAME = $BackupAMIandSnapshotID ⏪ ⏪"

packer build $PACKER_PATH/$PACKER_GROUP/packer_arm64.json

AMI_ID=$(aws ec2 describe-images --region $REGION --filters "Name=tag:Name,Values=$AMI_NAME" --query 'Images[*].[ImageId]' --output text)
SNAPSHOT_ID=$(aws ec2 describe-images --image-ids $AMI_ID --region $REGION --query 'Images[*].BlockDeviceMappings[*].[Ebs]'| grep SnapshotId | awk -F'"' '{print $4}')
aws sns publish --region $REGION --topic-arn "arn:aws:sns:$REGION:333333333333:sns2slack_$CHANNEL_NAME" --message "✳️  ✳️  $AMI_NAME in $REGION : $AMI_ID, $SNAPSHOT_ID ✳️  ✳️ "

###############################################################################
###################### Deploying AMI in Launch Template #######################
###############################################################################


cd $PACKER_PATH/update-lt-tf-code-arm64
aws sns publish --region $REGION --topic-arn "arn:aws:sns:$REGION:333333333333:sns2slack_$CHANNEL_NAME" --message "♻️  ♻️ Initializing Terraform and Planning Changes on $LTNAME in $REGION ♻️  ♻️ "
rm -rf .terraform*
terraform init -backend-config key="$S3_BACKEND_PATH/$PACKER_GROUP/$LTNAME.tfstate"
terraform plan -var ami_id="$AMI_ID" -var snapshot_id="$SNAPSHOT_ID" -var launch_template_name="$LTNAME" -var packer_group="$PACKER_GROUP"

if [[ "$?" -ne "0" ]]; then
        break
else
        aws sns publish --region $REGION --topic-arn "arn:aws:sns:$REGION:333333333333:sns2slack_$CHANNEL_NAME" --message "♻️  ♻️  Terraform is Applying Changes ♻️  ♻️ "
        message=$(terraform apply -var ami_id="$AMI_ID" -var snapshot_id="$SNAPSHOT_ID" -var launch_template_name="$LTNAME" -var packer_group="$PACKER_GROUP" -auto-approve | grep "Apply complete")
        aws sns publish --region $REGION --topic-arn "arn:aws:sns:$REGION:333333333333:sns2slack_$CHANNEL_NAME" --message "♻️  ♻️  $message ♻️  ♻️ "
fi

###############################################################################
########### Starting Instance Refresh and Sending a Notification ##############
###############################################################################

InstanceRefreshId=$(aws autoscaling start-instance-refresh --auto-scaling-group-name $ASG --region $REGION --preferences '{"MinHealthyPercentage":85}' | grep "InstanceRefreshId" | awk -F '"' '{print $4}')
aws sns publish --region $REGION --topic-arn "arn:aws:sns:$REGION:333333333333:sns2slack_$CHANNEL_NAME" --message "♻️  ♻️  Starting instance refresh on $ASG in $REGION, InstanceRefreshId is $InstanceRefreshId ♻️  ♻️ "
