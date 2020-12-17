#!/bin/bash

IP=$(aws ec2 describe-instances | grep  "PublicIp" | grep -E '[0-9]{1,4}' | tr -d '",' | tr -d '[a-z,:,A-Z]' | tr -d ' ' | tail -1)
USER=ubuntu
# terraform apply --auto-approve

ssh -i ~/Desktop/s3-alex-terraform/lab4keys.pem $USER@$IP

ssh -i lab4keys.pem ubuntu@http://web-elb-604670751.us-east-2.elb.amazonaws.com/