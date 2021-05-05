#!/bin/bash
sudo yum update -y
sudo yum install ruby -y
sudo yum install wget -y
sudo su
cd /home/ec2-user
sudo wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
sudo chmod +x ./install
sudo ./install auto
sudo service codedeploy-agent status
sudo service codedeploy-agent start
sudo service codedeploy-agent status
