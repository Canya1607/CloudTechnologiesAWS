#!/usr/bin/env bash

KEYPAIR_NAME=alexpair
VPC_NAME=alex-vpc
IGW_NAME=alex-igw
SUBNET_NAME=alex-snet
RT_NAME=alex-routes
SGROUP_NAME=alex-sgroup
IMAGE_ID=ami-09558250a3419e7d0
INSTANCE_TYPE=t2.micro
REGION=us-east-2

aws configure set default.region $REGION

#
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --output json | grep "VpcId" | cut -f4 -d \" )
aws ec2 create-tags --resources $VPC_ID --tags Key=Name,Value="$VPC_NAME"
aws ec2 wait vpc-available --vpc-ids $VPC_ID

IGW_ID=$(aws ec2 create-internet-gateway | grep "igw-" | cut -f4 -d \" )
aws ec2 attach-internet-gateway --vpc-id $VPC_ID --internet-gateway-id $IGW_ID
aws ec2 create-tags --resources $IGW_ID --tags Key=Name,Value="$IGW_NAME"

SUBNET_ID=$(aws ec2 create-subnet --cidr-block 10.0.1.0/24 --vpc-id $VPC_ID | grep SubnetId | cut -f4 -d \" )
aws ec2 modify-subnet-attribute --subnet-id $SUBNET_ID --map-public-ip-on-launch
aws ec2 create-tags --resources $SUBNET_ID --tags Key=Name,Value="$SUBNET_NAME"

RT_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID | grep "rtb-" | cut -f4 -d \" )
aws ec2 create-tags --resources $RT_ID --tags Key=Name,Value="$RT_NAME"

aws ec2 create-route --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID --route-table-id $RT_ID
aws ec2 associate-route-table --route-table-id $RT_ID --subnet-id $SUBNET_ID

echo "Wait..."
aws ec2 wait vpc-available --vpc-ids $VPC_ID
echo "Magic!\n"
echo -e "VPC_ID: $VPC_ID\nIGW_ID: $IGW_ID\n$SUBNET_ID: SUBNET_ID\nRT_ID: $RT_ID\n" 
echo "Creating new key pair..."

if ! -f "$KEYPAIR_NAME.pem"; then
  aws ec2 create-key-pair --key-name $KEYPAIR_NAME --query 'KeyMaterial' --output text > $KEYPAIR_NAME.pem
  chmod 400 "$KEYPAIR_NAME.pem"
  aws ec2 wait key-pair-exists --key-names $KEYPAIR_NAME
  KEYPAIR_ID=$(aws ec2 describe-key-pairs --key-names $KEYPAIR_NAME | grep KeyPairId | cut -f4 -d \" )
  echo "KEYPAIR_NAME: $KEYPAIR_NAME" 
else
  echo "$KEYPAIR_NAME already exists"
  KEYPAIR_ID=$(aws ec2 describe-key-pairs --key-names $KEYPAIR_NAME | grep KeyPairId | cut -f4 -d \" )
fi

# Create a secur
aws ec2 create-security-group --group-name $SGROUP_NAME --description "$SGROUP_NAME security group for SSH access" --vpc-id $VPC_ID
SGROUP_ID=$(aws ec2 describe-security-groups --filters Name=description,Values="$SGROUP_NAME security group for SSH access" | grep GroupId | cut -f4 -d \" )
aws ec2 authorize-security-group-ingress --group-id $SGROUP_ID --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SGROUP_ID --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 wait security-group-exists --group-ids $SGROUP_ID
echo "Security group: $SGROUP_NAME $SGROUP_ID created"

INSTANCE_ID=$(aws ec2 run-instances --image-id $IMAGE_ID  --count 1 --instance-type $INSTANCE_TYPE --key-name $KEYPAIR_NAME --security-group-ids $SGROUP_ID --subnet-id $SUBNET_ID  | grep InstanceId | cut -f4 -d \" )
aws ec2 create-tags --resources $INSTANCE_ID --tags Key=Role,Value="Web-Server"
echo "Creating instance"
echo "This could take a few moments..."
aws ec2 wait instance-exists --instance-ids $INSTANCE_ID
PUB_IPADDRESS=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID | grep PublicIpAddress | cut -f4 -d \" )
echo -e "\nSuccess!"
echo "Instance $INSTANCE_ID created with public IP address: $PUB_IPADDRESS"

